param([switch]$SkipWait)
$ErrorActionPreference='Stop'
$backend=Split-Path $PSScriptRoot -Parent
Push-Location $backend
try {
    $suites=@('PortalIntegration.cjs','PortalOtp.cjs','PortalFlows.cjs','PortalBrowser.cjs','PortalDashboard.cjs')
    for($index=0;$index -lt $suites.Count;$index++){
        if($index -gt 0 -and -not $SkipWait){
            Write-Host 'Waiting 60 seconds for the next login rate-limit window.'
            Start-Sleep -Seconds 60
        }
        & node (Join-Path $PSScriptRoot $suites[$index])
        if($LASTEXITCODE -ne 0){throw "Integration suite failed: $($suites[$index])"}
    }
    & python Tools/RunLocalSql.py 'DB Scripts/CleanupIntegrationFixtures.sql'
    if($LASTEXITCODE -ne 0){throw 'Test fixture cleanup failed.'}
    Write-Host 'PASS: all local API, OTP and Google Chrome integration suites.'
}
finally { Pop-Location }
