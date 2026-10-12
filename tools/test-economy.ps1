[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $repoRoot 'build\economy'
& (Join-Path $PSScriptRoot 'prepare-economy.ps1')
Write-Output 'Running dedicated-server checks without a game window...'
& python (Join-Path $PSScriptRoot 'economy-runtime.py') test --root $buildRoot
if ($LASTEXITCODE -ne 0) { throw "Economy validation failed. See $buildRoot\test-result.json and the runtime logs." }
Write-Output 'Passed: server-owned cash, round income, Demolition purchase and lock, death reassignment, persistence and halftime reset.'
