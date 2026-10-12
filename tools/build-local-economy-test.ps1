[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $repoRoot 'build\ui-learning'
$server = Join-Path $buildRoot 'game-economy-local-server'
$client = Join-Path $buildRoot 'game-economy-local-client'
foreach ($runtime in @($server, $client)) {
    if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $runtime 'iw3mp.exe') }) {
        throw "Close the local test before rebuilding: $runtime"
    }
}
& (Join-Path $PSScriptRoot 'build-combined.ps1') -RuntimeName 'game-economy-local-server'
New-Item -ItemType Directory -Force -Path $client | Out-Null
foreach ($folder in @('main', 'miles', 'zone')) {
    $source = Get-Item -LiteralPath (Join-Path $server $folder)
    $destination = Join-Path $client $folder
    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Junction -Path $destination -Target $source.Target[0] | Out-Null
    }
}
foreach ($name in @('iw3mp.exe', 'binkw32.dll', 'd3dx9_34.dll', 'mss32.dll', 'localization.txt', 'cod.bmp', 'codlogo.bmp', 'cod4.ico')) {
    Copy-Item -LiteralPath (Join-Path $server $name) -Destination (Join-Path $client $name) -Force
}
$clientMod = Join-Path $client 'mods\pmflex'
New-Item -ItemType Directory -Force -Path $clientMod | Out-Null
foreach ($asset in Get-ChildItem -LiteralPath (Join-Path $server 'mods\pmflex') -File) {
    if ($asset.Extension -in @('.ff', '.iwd', '.cfg')) {
        Copy-Item -LiteralPath $asset.FullName -Destination $clientMod -Force
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $client 'players'))) {
    Copy-Item -LiteralPath (Join-Path $server 'players') -Destination $client -Recurse
}
foreach ($runtime in @($server, $client)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'local-economy-test.cfg') -Destination (Join-Path $runtime 'mods\pmflex\local-economy-test.cfg') -Force
    foreach ($profile in Get-ChildItem -LiteralPath (Join-Path $runtime 'players') -Recurse -File -Filter 'config_mp.cfg') {
        $text = Get-Content -LiteralPath $profile.FullName -Raw
        foreach ($setting in @(@('net_noudp','0'), @('net_noipx','1'), @('net_ip','127.0.0.1'), @('cl_punkbuster','0'), @('sv_punkbuster','0'))) {
            $pattern = '(?m)^\s*seta?\s+' + $setting[0] + '\s+[^\r\n]*'
            $line = 'seta ' + $setting[0] + ' "' + $setting[1] + '"'
            if ($text -match $pattern) { $text = [regex]::Replace($text, $pattern, $line) }
            else { $text += "`r`n" + $line + "`r`n" }
        }
        Set-Content -LiteralPath $profile.FullName -Value $text -Encoding ASCII
    }
}
Write-Output 'Built local server and client test runtimes.'
