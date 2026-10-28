param(
    [string]$PostgreSqlBin = 'C:\Program Files\PostgreSQL\18\bin',
    [string]$DatabaseHost = 'localhost',
    [int]$Port = 5432,
    [string]$Database = 'adding_dimensions',
    [string]$Username = 'adding_dimensions'
)

$ErrorActionPreference = 'Stop'
$psql = Join-Path $PostgreSqlBin 'psql.exe'
if (-not (Test-Path -LiteralPath $psql)) { throw "psql.exe not found: $psql" }
# psql prompts for a password if needed; alternatively configure PGPASSWORD or pgpass.
# One transaction covers all scripts. No SQL is embedded in this runner.
$arguments = @('-X', '-h', $DatabaseHost, '-p', "$Port", '-U', $Username,
    '-d', $Database, '-v', 'ON_ERROR_STOP=1', '--single-transaction')
foreach ($folder in @('Table Creations', 'Stored Procedures')) {
    foreach ($script in (Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $folder) -Filter '*.sql' | Sort-Object Name)) {
        $arguments += @('-f', $script.FullName)
    }
}
& $psql @arguments
if ($LASTEXITCODE -ne 0) { throw 'Database deployment failed; the transaction was rolled back.' }
Write-Host 'Tables and stored procedures deployed successfully.'
