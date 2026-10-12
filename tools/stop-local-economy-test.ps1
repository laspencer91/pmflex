[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $repoRoot 'build\ui-learning\game-economy-local-server'
$executable = Join-Path $runtime 'iw3mp.exe'
$running = @(Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $executable })
foreach ($process in $running) { Stop-Process -Id $process.Id }
Write-Output 'Local test server stopped.'
