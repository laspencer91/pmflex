[CmdletBinding()]
param([ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'game-combined-v5')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $repoRoot ('build\ui-learning\' + $RuntimeName)
if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $runtime 'iw3mp.exe') }) {
    throw 'Close this combined runtime before testing it.'
}
$marker = Join-Path $runtime '__iw3mp'
if (Test-Path -LiteralPath $marker) {
    Move-Item -LiteralPath $marker -Destination (Join-Path $runtime ('startup-marker-' + [guid]::NewGuid().ToString('N') + '.bin'))
}
$resultRoot = Join-Path $repoRoot 'build\standard-validation'
New-Item -ItemType Directory -Force -Path $resultRoot | Out-Null
& python (Join-Path $PSScriptRoot 'economy-runtime.py') test --root $resultRoot --runtime $runtime --mod pmflex --standard --offline
if ($LASTEXITCODE -ne 0) { throw "Standard/profile validation failed. See $resultRoot and the runtime logs." }
