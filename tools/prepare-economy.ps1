[CmdletBinding()]
param([string]$RuntimePath = '')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$workspaceBuild = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'build')).Path
if ($RuntimePath -eq '') { $RuntimePath = Join-Path $workspaceBuild 'economy\game' }
$runtimeRoot = (Resolve-Path -LiteralPath $RuntimePath).Path
if (-not $runtimeRoot.StartsWith($workspaceBuild + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Startup recovery must stay inside this repository build directory.'
}
$buildRoot = Split-Path -Parent $runtimeRoot
$executable = Join-Path $runtimeRoot 'iw3mp.exe'
$running = @(Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $executable })
if ($running.Count) {
    throw "Close the economy game before continuing. Running process ID: $($running.Id -join ', ')."
}
$marker = Join-Path $runtimeRoot '__iw3mp'
if (Test-Path -LiteralPath $marker) {
    $backup = Join-Path $buildRoot ('startup-marker-' + [guid]::NewGuid().ToString('N') + '.bin')
    Move-Item -LiteralPath $marker -Destination $backup
    Write-Output 'Archived the leftover economy startup marker.'
}
