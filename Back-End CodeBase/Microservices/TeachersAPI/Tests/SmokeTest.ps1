param(
    [string]$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('adding-dimensions-smoke-' + [Guid]::NewGuid().ToString('N'))
$dataPath = Join-Path $testRoot 'postgres'
$processes = @()
$pgStarted = $false
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromSeconds(15)
$savedEnvironment = @{}
$checks = 0

function Set-TestEnvironment([string]$Name, [string]$Value) {
    if (-not $savedEnvironment.ContainsKey($Name)) {
        $savedEnvironment[$Name] = [Environment]::GetEnvironmentVariable($Name, 'Process')
    }
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Get-FreePort {
    $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $port = $listener.LocalEndpoint.Port
    $listener.Stop()
    return $port
}

function Start-Hidden([string]$Executable, [string[]]$Arguments, [string]$Directory, [string]$LogName) {
    $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -WorkingDirectory $Directory `
        -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $testRoot "$LogName.out.log") `
        -RedirectStandardError (Join-Path $testRoot "$LogName.err.log")
    # Retain a process handle so Windows PowerShell can read ExitCode after WaitForExit.
    $null = $process.Handle
    return $process
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    $script:checks++
}

function Send-Request([string]$Method, [string]$Path, [int]$Expected,
    $Body = $null, [string]$Token = '', [string]$Base = $script:gatewayUrl, [switch]$Plain) {
    $request = New-Object System.Net.Http.HttpRequestMessage
    $request.Method = New-Object System.Net.Http.HttpMethod($Method)
    $request.RequestUri = [Uri]("$Base$Path")
    if ($Token) {
        $request.Headers.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $Token)
    }
    if ($null -ne $Body) {
        $json = ConvertTo-Json -InputObject $Body -Depth 10 -Compress
        if (-not $Plain) {
            $json = $json | & dotnet $script:cryptoDll encrypt
            if ($LASTEXITCODE -ne 0) { throw 'Client encryption failed.' }
        }
        $request.Content = New-Object System.Net.Http.StringContent($json, [Text.Encoding]::UTF8, 'application/json')
    }
    $response = $null
    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if ([int]$response.StatusCode -ne $Expected) {
            throw "$Method $Path expected $Expected, received $([int]$response.StatusCode): $content"
        }
        $script:checks++
        if ($content -and $response.Content.Headers.ContentType.MediaType -match 'json') {
            $envelope = ConvertFrom-Json $content
            if ($envelope.encryptedData) {
                Assert-True ($null -eq $envelope.data -and $null -eq $envelope.jwtToken) 'Plaintext data/token leaked in envelope.'
                $decrypted = $content | & dotnet $script:cryptoDll decrypt
                if ($LASTEXITCODE -ne 0) { throw 'Reference-compatible response decryption failed.' }
                $message = ConvertFrom-Json $decrypted
                Assert-True ($message.statusCode -eq $Expected -and $envelope.statusCode -eq $Expected) 'Inconsistent response status.'
                Assert-True ($message.isSuccess -eq ($Expected -lt 400)) 'Inconsistent response success flag.'
                return $message
            }
            return $envelope
        }
    }
    finally {
        if ($response) { $response.Dispose() }
        $request.Dispose()
    }
}

function Wait-ForApp([string]$Url, $Process) {
    for ($i = 0; $i -lt 80; $i++) {
        if ($Process.HasExited) { throw "Application exited with code $($Process.ExitCode)." }
        try {
            $response = $client.GetAsync("$Url/api/Health").GetAwaiter().GetResult()
            $ready = $response.IsSuccessStatusCode
            $response.Dispose()
            if ($ready) { return }
        }
        catch { }
        Start-Sleep -Milliseconds 250
    }
    throw "Application did not become ready: $Url"
}

try {
    foreach ($binary in 'initdb.exe', 'pg_ctl.exe', 'psql.exe') {
        if (-not (Test-Path -LiteralPath (Join-Path $PostgreSqlBin $binary))) {
            throw "Missing PostgreSQL binary: $binary. Supply -PostgreSqlBin."
        }
    }
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    Push-Location $workspace
    try {
        & dotnet build AddingDimensions.sln -c Release --nologo
        if ($LASTEXITCODE -ne 0) { throw 'Build failed.' }
    }
    finally { Pop-Location }

    & (Join-Path $PostgreSqlBin 'initdb.exe') -D $dataPath -U dimensions_test -A trust --no-locale -E UTF8 `
        *> (Join-Path $testRoot 'initdb.log')
    if ($LASTEXITCODE -ne 0) { throw 'Temporary PostgreSQL initialization failed.' }
    $pgPort = Get-FreePort
    $apiPort = Get-FreePort
    $gatewayPort = Get-FreePort
    $pg = Start-Hidden (Join-Path $PostgreSqlBin 'pg_ctl.exe') @(
        '-D', ('"' + $dataPath + '"'), '-l', ('"' + (Join-Path $testRoot 'postgres.log') + '"'),
        '-o', ('"-p ' + $pgPort + ' -h 127.0.0.1 -F"'), '-w', 'start'
    ) $workspace 'pg-start'
    $pgStarted = $true
    $pg.WaitForExit()
    if ($pg.ExitCode -ne 0) { throw 'Temporary PostgreSQL server failed to start.' }
    Set-TestEnvironment 'ConnectionStrings__DBConnection' "Host=127.0.0.1;Port=$pgPort;Database=postgres;Username=dimensions_test"
    Set-TestEnvironment 'Jwt__SecurityKey' ([Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N'))
    Set-TestEnvironment 'ASPNETCORE_ENVIRONMENT' 'Development'
    Set-TestEnvironment 'AESPassword' ([Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N'))
    Set-TestEnvironment 'BootstrapAdmin__Email' 'admin@example.com'
    Set-TestEnvironment 'BootstrapAdmin__Password' 'SmokeTest-Admin-Password-123!'
    $apiDirectory = Join-Path $workspace 'Microservices\TeachersAPI'
    $apiDll = Join-Path $apiDirectory 'bin\Release\net10.0\TeachersAPI.dll'
    $gatewayDirectory = Join-Path $workspace 'OcelotGateWay'
    $gatewayDll = Join-Path $gatewayDirectory 'bin\Release\net10.0\OcelotGateWay.dll'
    $deployScript = Join-Path $workspace 'DB Scripts\DeployDatabase.ps1'
    & $deployScript -PostgreSqlBin $PostgreSqlBin -DatabaseHost '127.0.0.1' -Port $pgPort -Database postgres -Username dimensions_test
    & $deployScript -PostgreSqlBin $PostgreSqlBin -DatabaseHost '127.0.0.1' -Port $pgPort -Database postgres -Username dimensions_test
    $initialize = Start-Hidden 'dotnet' @(('"' + $apiDll + '"'), '--seed-admin') $apiDirectory 'initialize'
    $initialize.WaitForExit()
    Assert-True ($initialize.ExitCode -eq 0) 'Administrator bootstrap failed.'

    $cryptoDirectory = Join-Path $testRoot 'client'
    New-Item -ItemType Directory -Path $cryptoDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'EncryptionTestClient.cs') -Destination (Join-Path $cryptoDirectory 'Program.cs')
    $cryptoProject = Join-Path $cryptoDirectory 'EncryptionTestClient.csproj'
    '<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><OutputType>Exe</OutputType><TargetFramework>net10.0</TargetFramework><ImplicitUsings>enable</ImplicitUsings><Nullable>enable</Nullable><NoWarn>SYSLIB0060</NoWarn></PropertyGroup></Project>' | Set-Content -LiteralPath $cryptoProject
    & dotnet build $cryptoProject -c Release --nologo
    if ($LASTEXITCODE -ne 0) { throw 'Reference encryption client build failed.' }
    $script:cryptoDll = Join-Path $cryptoDirectory 'bin\Release\net10.0\EncryptionTestClient.dll'
    Set-TestEnvironment 'ASPNETCORE_URLS' "http://127.0.0.1:$apiPort"
    $api = Start-Hidden 'dotnet' @(('"' + $apiDll + '"')) $apiDirectory 'teachers'
    $processes += $api
    $apiUrl = "http://127.0.0.1:$apiPort"
    Wait-ForApp $apiUrl $api
    Set-TestEnvironment 'ASPNETCORE_URLS' "http://127.0.0.1:$gatewayPort"
    for ($i = 0; $i -lt (Get-Content (Join-Path $gatewayDirectory 'ocelot.json') -Raw | ConvertFrom-Json).Routes.Count; $i++) {
        Set-TestEnvironment "Routes__${i}__DownstreamHostAndPorts__0__Port" "$apiPort"
    }
    $gateway = Start-Hidden 'dotnet' @(('"' + $gatewayDll + '"')) $gatewayDirectory 'gateway'
    $processes += $gateway
    $script:gatewayUrl = "http://127.0.0.1:$gatewayPort"
    Wait-ForApp $gatewayUrl $gateway

    $null = Send-Request GET '/api/Health/ready' 200
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{}
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Base $apiUrl
    $swagger = Send-Request GET '/swagger/v1/swagger.json' 200 -Base $apiUrl
    Assert-True ($null -ne $swagger.paths.'/api/Teachers/GetTeacherById') 'Swagger does not expose teacher actions.'
    $profile = @{
        firstName = 'Test'; lastName = 'Teacher'; email = 'teacher@example.com';
        password = 'SmokeTest-Teacher-Password-123!'; subject = 'Math'; phoneNumber = '1234567890';
        role = 'Admin'; requestCode = 'registration-check'
    }
    $registration = Send-Request POST '/api/Login/Register' 201 -Body $profile
    $teacherId = $registration.data.id
    Assert-True ($registration.responseCode -eq 'registration-check') 'Request correlation code was lost.'
    Assert-True ($registration.data.role -eq 'Teacher') 'Public registration elevated privileges.'
    Assert-True ($null -eq $registration.data.passwordHash) 'Password hash leaked in decrypted response.'
    $profile.email = 'TEACHER@EXAMPLE.COM'
    $null = Send-Request POST '/api/Login/Register' 409 -Body $profile
    $null = Send-Request POST '/api/Login/Login' 400 -Body @{ userName = 'invalid'; password = 'bad' }
    $null = Send-Request POST '/api/Login/Login' 401 -Body @{ userName = 'teacher@example.com'; password = 'wrong' }
    $loginBody = @{ userName = 'teacher@example.com'; password = $profile.password }
    $login1 = Send-Request POST '/api/Login/Login' 200 -Body $loginBody
    $token1 = $login1.data.jwtToken
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 200 -Body @{} -Token $token1
    $login2 = Send-Request POST '/api/Login/Login' 200 -Body $loginBody
    $token2 = $login2.data.jwtToken
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Token $token1
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Token $token1 -Base $apiUrl
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Token ($token2 + 'tampered')
    $null = Send-Request POST '/api/Teachers/GetTeachersList' 403 -Body @{} -Token $token2
    $null = Send-Request POST '/api/Teachers/GetTeacherById' 403 -Body @{teacherId=1} -Token $token2
    $null = Send-Request POST '/api/Teachers/DeleteTeacher' 403 -Body @{teacherId=$teacherId} -Token $token2
    $profile.subject = 'Physics'
    $profile.teacherId = $teacherId
    $updated = Send-Request POST '/api/Teachers/UpdateTeacher' 200 -Body $profile -Token $token2
    Assert-True ($updated.data.subject -eq 'Physics') 'Teacher profile update did not persist.'

    # Reject missing envelopes, malformed ciphertext, bad tags/nonces/salts, and decrypted invalid input.
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 400 -Body @{} -Token $token2 -Plain
    $validEnvelope = '{}' | & dotnet $cryptoDll encrypt | ConvertFrom-Json
    $validEnvelope.tag = [Convert]::ToBase64String((New-Object byte[] 16))
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 400 -Body $validEnvelope -Token $token2 -Plain
    $validEnvelope.salt = [Convert]::ToBase64String((New-Object byte[] 8))
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 400 -Body $validEnvelope -Token $token2 -Plain
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 400 -Body @{ data='not-base64'; salt='x'; nonce='x'; tag='x' } -Token $token2 -Plain
    $null = Send-Request POST '/api/Teachers/GetTeacherById' 400 -Body @{teacherId=0} -Token $token2
    $null = Send-Request POST '/api/Login/Logout' 200 -Body @{} -Token $token2
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Token $token2

    $admin = Send-Request POST '/api/Login/Login' 200 -Body @{
        userName = 'admin@example.com'; password = 'SmokeTest-Admin-Password-123!'
    }
    $adminToken = $admin.data.jwtToken
    $list = Send-Request POST '/api/Teachers/GetTeachersList' 200 -Body @{pageNumber=1; pageSize=1} -Token $adminToken
    Assert-True ($list.dataList.Count -eq 1) 'Teacher pagination failed.'
    $null = Send-Request POST '/api/Teachers/GetTeachersList' 400 -Body @{pageSize=101} -Token $adminToken
    $empty = Send-Request POST '/api/Teachers/GetTeachersList' 200 -Body @{pageNumber=1000} -Token $adminToken
    Assert-True ($empty.dataList.Count -eq 0 -and $empty.isSuccess) 'Empty result should be an explicit successful empty list.'
    $null = Send-Request POST '/api/Teachers/GetTeacherById' 404 -Body @{teacherId=9999999} -Token $adminToken
    $profile.email = 'another@example.com'
    $created = Send-Request POST '/api/Teachers/SaveTeacher' 201 -Body $profile -Token $adminToken
    $anotherId = $created.data.id
    $anotherLogin = Send-Request POST '/api/Login/Login' 200 -Body @{
        userName = $profile.email; password = $profile.password
    }
    $profile.teacherId = $anotherId
    $profile.email = 'teacher@example.com'
    $null = Send-Request POST '/api/Teachers/UpdateTeacher' 409 -Body $profile -Token $adminToken
    $null = Send-Request POST '/api/Teachers/GetTeacherById' 200 -Body @{teacherId=$anotherId} -Token $adminToken
    $null = Send-Request POST '/api/Teachers/DeleteTeacher' 200 -Body @{teacherId=$anotherId} -Token $adminToken
    $null = Send-Request POST '/api/Teachers/GetMyProfile' 401 -Body @{} -Token $anotherLogin.data.jwtToken
    $null = Send-Request POST '/api/Teachers/GetTeacherById' 404 -Body @{teacherId=$anotherId} -Token $adminToken
    $null = Send-Request POST '/api/Teachers/DeleteTeacher' 404 -Body @{teacherId=$anotherId} -Token $adminToken

    $inlineSql = Get-ChildItem -LiteralPath (Join-Path $workspace 'Microservices'), (Join-Path $workspace 'JwtAuthenticationManager') -Recurse -Filter '*.cs' |
        Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' } |
        Select-String -Pattern '(?i)(SELECT\s+.+\s+FROM|INSERT\s+INTO|DELETE\s+FROM|UPDATE\s+\w+\s+SET|CommandType\.Text)'
    Assert-True ($null -eq $inlineSql) 'Inline SQL found in C# source.'
    Write-Host "PASS: $checks checks: stored procedures, reference-compatible AES-GCM, TeachersAPI, and OcelotGateway."
}
catch {
    Write-Host ($_ | Format-List * -Force | Out-String)
    if (Test-Path -LiteralPath $testRoot) {
        Get-ChildItem -LiteralPath $testRoot -Filter '*.log' | ForEach-Object {
            Write-Host "Log: $($_.Name)"
            Get-Content -LiteralPath $_.FullName -Tail 12 | Write-Host
        }
    }
    throw
}
finally {
    foreach ($process in $processes) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
    }
    if ($pgStarted) {
        $stop = Start-Hidden (Join-Path $PostgreSqlBin 'pg_ctl.exe') @(
            '-D', ('"' + $dataPath + '"'), '-m', 'immediate', '-w', 'stop'
        ) $workspace 'pg-stop'
        $stop.WaitForExit()
    }
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
    $client.Dispose()
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTest = (Resolve-Path -LiteralPath $testRoot).Path
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if ($resolvedTest.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
            (Split-Path $resolvedTest -Leaf) -match '^adding-dimensions-smoke-[a-f0-9]{32}$') {
            Remove-Item -LiteralPath $resolvedTest -Recurse -Force -ErrorAction Continue
        }
    }
}
