[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $repoRoot 'build\ui-learning\game-economy-local-server'
& (Join-Path $PSScriptRoot 'prepare-economy.ps1') -RuntimePath $runtime
& python (Join-Path $PSScriptRoot 'local-economy-server.py') --runtime $runtime --check
if ($LASTEXITCODE -ne 0) { throw 'Local test failed. See the local server runtime logs.' }
