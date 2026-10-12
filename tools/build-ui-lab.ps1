[CmdletBinding()]
param(
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Call of Duty 4',
    [string]$ToolsPath = '',
    [string]$RuntimeFilesPath = '',
    [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'game'
)

$ErrorActionPreference = 'Stop'
if ($ToolsPath -eq '') { $ToolsPath = Join-Path $PSScriptRoot '..\..\cod4-mod-tools' }
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$toolsRoot = (Resolve-Path -LiteralPath $ToolsPath).Path
$gameRoot = (Resolve-Path -LiteralPath $GamePath).Path
$runtimeFilesRoot = $gameRoot
if ($RuntimeFilesPath -ne '') { $runtimeFilesRoot = (Resolve-Path -LiteralPath $RuntimeFilesPath).Path }
$buildRoot = Join-Path $repoRoot 'build\ui-learning'
$runtimeRoot = Join-Path $buildRoot $RuntimeName
$modRoot = Join-Path $runtimeRoot 'mods\pmflex'
if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $runtimeRoot 'iw3mp.exe') }) {
    throw 'Close this runtime before rebuilding it.'
}
$linker = Join-Path $toolsRoot 'bin\linker_pc.exe'
if (-not (Test-Path -LiteralPath $linker)) { throw "Missing linker: $linker" }
if (-not (Test-Path -LiteralPath (Join-Path $runtimeFilesRoot 'iw3mp.exe'))) { throw 'Missing CoD4 multiplayer executable.' }
New-Item -ItemType Directory -Force -Path $modRoot | Out-Null
& python (Join-Path $PSScriptRoot 'generate-ui-materials.py') --tools-root $toolsRoot --convert --output-root $buildRoot
if ($LASTEXITCODE -ne 0) { throw 'UI material conversion failed.' }

function Copy-ChangedFile([string]$Source, [string]$Destination) {
    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash -eq
            (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash) { return }
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

# The linker reads stock images from the installed game archives.
$toolMain = Join-Path $toolsRoot 'main'
if (-not (Test-Path -LiteralPath $toolMain)) {
    New-Item -ItemType Junction -Path $toolMain -Target (Join-Path $gameRoot 'main') | Out-Null
}

foreach ($name in @('maps', 'mp', 'promod', 'shock', 'sound', 'soundaliases', 'ui_mp', 'xmodel', 'images', 'vision', 'weapons')) {
    Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination (Join-Path $toolsRoot 'raw') -Recurse -Force
}
Copy-Item -LiteralPath (Join-Path $repoRoot 'localizedstrings') -Destination (Join-Path $toolsRoot 'raw\english') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'mod.csv') -Destination (Join-Path $toolsRoot 'zone_source\mod.csv') -Force

Push-Location (Join-Path $toolsRoot 'bin')
try {
    $linkOutput = & $linker -language english -compress -cleanup mod -verbose 2>&1
    $linkExitCode = $LASTEXITCODE
} finally { Pop-Location }
$linkOutput | Set-Content -LiteralPath (Join-Path $buildRoot 'linker.log') -Encoding UTF8
$linkOutput | Select-Object -Last 8 | ForEach-Object { Write-Output $_ }
# This linker can return zero even when its summary contains errors.
if ($linkExitCode -ne 0 -or ($linkOutput -match 'ERROR:') -or
    -not ($linkOutput -match 'There were no errors or warnings')) {
    throw "Linker did not finish cleanly. See $buildRoot\linker.log"
}
Copy-ChangedFile (Join-Path $toolsRoot 'zone\english\mod.ff') (Join-Path $modRoot 'mod.ff')

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Write-ModArchive([string]$Destination, [string[]]$Folders, [string]$ArchiveRoot = $repoRoot) {
    $stream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create)
    $archive = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($folder in $Folders) {
            foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $ArchiveRoot $folder) -Recurse -File)) {
                $entry = $file.FullName.Substring($ArchiveRoot.Length + 1).Replace('\', '/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry,
                    [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
            }
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
}
Write-ModArchive (Join-Path $buildRoot 'pmflex.iwd') @('weapons', 'images', 'sound')
Write-ModArchive (Join-Path $buildRoot 'z_c_r.iwd') @('promod_ruleset')
Write-ModArchive (Join-Path $buildRoot 'ui_style.iwd') @('images') (Join-Path $buildRoot 'style-assets')
Copy-ChangedFile (Join-Path $buildRoot 'pmflex.iwd') (Join-Path $modRoot 'pmflex.iwd')
Copy-ChangedFile (Join-Path $buildRoot 'z_c_r.iwd') (Join-Path $modRoot 'z_c_r.iwd')
Copy-ChangedFile (Join-Path $buildRoot 'ui_style.iwd') (Join-Path $modRoot 'ui_style.iwd')
Copy-ChangedFile (Join-Path $repoRoot 'tools\ui_lab.cfg') (Join-Path $modRoot 'ui_lab.cfg')

# Keep executable, configuration, profiles and logs in the workspace.
Copy-ChangedFile (Join-Path $runtimeFilesRoot 'iw3mp.exe') (Join-Path $runtimeRoot 'iw3mp.exe')
foreach ($file in (Get-ChildItem -LiteralPath $runtimeFilesRoot -Filter '*.dll' -File)) {
    Copy-ChangedFile $file.FullName (Join-Path $runtimeRoot $file.Name)
}
foreach ($folder in @('main', 'zone', 'miles')) {
    $destination = Join-Path $runtimeRoot $folder
    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Junction -Path $destination -Target (Join-Path $gameRoot $folder) | Out-Null
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $runtimeRoot 'players'))) {
    Copy-Item -LiteralPath (Join-Path $gameRoot 'players') -Destination $runtimeRoot -Recurse
}
foreach ($name in @('localization.txt', 'cod4.ico', 'cod.bmp', 'codlogo.bmp')) {
    $source = Join-Path $gameRoot $name
    if (Test-Path -LiteralPath $source) { Copy-ChangedFile $source (Join-Path $runtimeRoot $name) }
}

$contractSource = Get-Content -LiteralPath (Join-Path $repoRoot 'promod\match_stats_contract.gsc') -Raw
$contractVersion = [regex]::Match($contractSource, 'version\(\)\s*\{\s*return\s+(\d+)\s*;')
if (-not $contractVersion.Success) { throw 'Missing match statistics contract version.' }
$modFfHash = (Get-FileHash -LiteralPath (Join-Path $modRoot 'mod.ff') -Algorithm SHA256).Hash
[ordered]@{
    version = [int]$contractVersion.Groups[1].Value
    modFfSha256 = $modFfHash.ToLowerInvariant()
    publicStubSha256 = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'promod\match_stats.gsc') -Algorithm SHA256).Hash.ToLowerInvariant()
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $modRoot 'match-stats-contract.json') -Encoding UTF8

$manifest = [ordered]@{
    builtAt = (Get-Date).ToString('o')
    upstreamPromodRevision = 'd22de10be2625674f252be29448530220db48228'
    toolsRevision = (& git -C $toolsRoot rev-parse HEAD)
    gamePath = $gameRoot
    runtimeFilesPath = $runtimeFilesRoot
    runtimePath = $runtimeRoot
    files = @()
}
foreach ($name in @('mod.ff', 'pmflex.iwd', 'z_c_r.iwd', 'ui_style.iwd', 'ui_lab.cfg')) {
    $path = Join-Path $modRoot $name
    $hash = if ($name -eq 'mod.ff') { $modFfHash } else { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
    $manifest.files += [ordered]@{ name = $name; bytes = (Get-Item -LiteralPath $path).Length;
        sha256 = $hash }
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $buildRoot 'build-manifest.json') -Encoding UTF8
Write-Output "Installed UI learning mod: $modRoot"
if ($RuntimeName -eq 'game') { Write-Output "UI lab runtime installed at $runtimeRoot" }
else { Write-Output 'This is a separate validation runtime.' }
