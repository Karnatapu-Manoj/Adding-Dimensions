$ErrorActionPreference='Stop'
$trackingFile=Join-Path $PSScriptRoot '.local\processes.json'
if(-not (Test-Path -LiteralPath $trackingFile)){Write-Host 'No tracked local project processes.';exit}
$processes=Get-Content -LiteralPath $trackingFile -Raw | ConvertFrom-Json
foreach($tracked in $processes){
    $process=Get-CimInstance Win32_Process -Filter "ProcessId = $($tracked.id)" -ErrorAction SilentlyContinue
    if($process -and ($process.CommandLine -like '*TeachersAPI.dll*' -or $process.CommandLine -like '*OcelotGateWay.dll*' -or $process.CommandLine -like '*TeacherTraining*' -or $process.CommandLine -like '*Front-End CodeBase*\vite\bin\vite.js*')){
        Stop-Process -Id $tracked.id -Force -ErrorAction SilentlyContinue
        Write-Host "Stopped $($tracked.name)."
    }
}
