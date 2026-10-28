param([switch]$SkipBuild,[switch]$OpenChrome)
$ErrorActionPreference='Stop'
$backend=$PSScriptRoot
$frontend=Join-Path (Split-Path $backend -Parent) 'Front-End CodeBase'
$local=Join-Path $backend '.local'
New-Item -ItemType Directory -Path $local -Force | Out-Null
$configPath=Join-Path $backend 'Microservices\TeachersAPI\appsettings.Local.json'
if(-not (Test-Path -LiteralPath $configPath)){throw 'Local database and encryption configuration is missing. Run DB Scripts\ConfigureLocalDatabase.py first.'}
$localConfig=Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$envPath=Join-Path $frontend '.env.local'
$envLines=if(Test-Path -LiteralPath $envPath){@(Get-Content -LiteralPath $envPath | Where-Object {$_ -notmatch '^VITE_(API_BASE_URL|AES_PASSWORD|BUSINESS_TIME_ZONE)='})}else{@()}
$envLines+=@('VITE_API_BASE_URL=http://localhost:5100',('VITE_AES_PASSWORD='+$localConfig.AESPassword),'VITE_BUSINESS_TIME_ZONE=Asia/Kolkata')
[IO.File]::WriteAllLines($envPath,[string[]]$envLines,(New-Object Text.UTF8Encoding($false)))
if(-not (Test-Path -LiteralPath (Join-Path $frontend 'node_modules\vite\bin\vite.js'))){throw 'Frontend packages are missing. Run npm ci inside Front-End CodeBase first.'}
$dotnet=(Get-Command dotnet).Source
$node=(Get-Command node.exe).Source
if(-not $SkipBuild){
    Push-Location $backend
    try { & $dotnet build AddingDimensions.sln -c Release --nologo; if($LASTEXITCODE -ne 0){throw 'Backend build failed.'} }
    finally { Pop-Location }
}
foreach($port in 5101,5100,5173){
    if(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue){throw "Port $port is already in use. Use Stop-Local.ps1 for this project's tracked processes before restarting."}
}
function Start-LocalProcess([string]$File,[string[]]$Arguments,[string]$Directory,[string]$Name){
    $process=Start-Process -FilePath $File -ArgumentList $Arguments -WorkingDirectory $Directory -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $local "$Name.out.log") -RedirectStandardError (Join-Path $local "$Name.err.log")
    $null=$process.Handle
    return @{name=$Name;id=$process.Id}
}
$processes=@()
$previousEnvironment=$env:ASPNETCORE_ENVIRONMENT
$previousUrls=$env:ASPNETCORE_URLS
try {
    $env:ASPNETCORE_ENVIRONMENT='Development'
    $env:ASPNETCORE_URLS='http://localhost:5101'
    $apiDll=Join-Path $backend 'Microservices\TeachersAPI\bin\Release\net10.0\TeachersAPI.dll'
    $processes+=Start-LocalProcess $dotnet @(('"'+$apiDll+'"')) (Join-Path $backend 'Microservices\TeachersAPI') 'teachers-api'
    $env:ASPNETCORE_URLS='http://localhost:5100'
    $gatewayDll=Join-Path $backend 'OcelotGateWay\bin\Release\net10.0\OcelotGateWay.dll'
    $processes+=Start-LocalProcess $dotnet @(('"'+$gatewayDll+'"')) (Join-Path $backend 'OcelotGateWay') 'gateway'
    $vite=Join-Path $frontend 'node_modules\vite\bin\vite.js'
    $processes+=Start-LocalProcess $node @(('"'+$vite+'"'),'--host','localhost','--port','5173','--strictPort') $frontend 'frontend'
    $processes | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $local 'processes.json')
    foreach($url in @('http://localhost:5101/api/Health/ready','http://localhost:5100/api/Health/ready','http://localhost:5173/TeacherTraining/login')){
        $ready=$false
        for($attempt=0;$attempt -lt 40;$attempt++){
            try { $response=Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2; if($response.StatusCode -eq 200){$ready=$true;break} } catch {}
            Start-Sleep -Milliseconds 250
        }
        if(-not $ready){throw "Service did not become ready: $url. See .local log files."}
    }
    Write-Host 'Ready: http://localhost:5173/TeacherTraining/login'
    Write-Host 'Gateway: http://localhost:5100 | API: http://localhost:5101/swagger'
    if($OpenChrome){
        $chrome='C:\Program Files\Google\Chrome\Application\chrome.exe'
        Start-Process -FilePath $chrome -ArgumentList 'http://localhost:5173/TeacherTraining/login' | Out-Null
    }
}
catch {
    foreach($process in $processes){Stop-Process -Id $process.id -Force -ErrorAction SilentlyContinue}
    throw
}
finally {
    $env:ASPNETCORE_ENVIRONMENT=$previousEnvironment
    $env:ASPNETCORE_URLS=$previousUrls
}
