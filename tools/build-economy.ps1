[CmdletBinding()]
param(
    [string]$SourcePath = '',
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Call of Duty 4',
    [string]$ToolsPath = '',
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$BuildName = 'economy'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $repoRoot ('build\' + $BuildName)
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
if ($ToolsPath -eq '') { $ToolsPath = Join-Path $repoRoot '..\cod4-mod-tools' }
$stockRoot = (Resolve-Path -LiteralPath $ToolsPath).Path
$gameRoot = (Resolve-Path -LiteralPath $GamePath).Path
if ($SourcePath -eq '') {
    $revision = (& git -C $repoRoot rev-parse HEAD).Trim()
    $SourcePath = Join-Path $buildRoot ('source-' + $revision)
    $archivePath = Join-Path $buildRoot ('source-' + $revision + '.zip')
    & git -C $repoRoot archive --format=zip --output=$archivePath HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Source export failed.' }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $SourcePath -Force
}
$sourceRoot = (Resolve-Path -LiteralPath $SourcePath).Path
$toolRoot = Join-Path $buildRoot 'tools'
$runtimeRoot = Join-Path $buildRoot 'game'
$modRoot = Join-Path $runtimeRoot 'mods\pmflex'
foreach ($folder in @('bin', 'raw', 'zone_source\english\assetlist', 'zone_source\english\assetinfo', 'zone\english')) {
    New-Item -ItemType Directory -Force -Path (Join-Path $toolRoot $folder) | Out-Null
}
$overlays = @('maps', 'mp', 'promod', 'shock', 'sound', 'soundaliases', 'ui_mp', 'xmodel', 'images', 'vision', 'english')
Copy-Item -Path (Join-Path $stockRoot 'bin\*') -Destination (Join-Path $toolRoot 'bin') -Force
foreach ($folder in (Get-ChildItem -LiteralPath (Join-Path $stockRoot 'raw') -Directory)) {
    $destination = Join-Path $toolRoot ('raw\' + $folder.Name)
    if ($overlays -contains $folder.Name) {
        if (-not (Test-Path -LiteralPath $destination)) {
            Copy-Item -LiteralPath $folder.FullName -Destination (Join-Path $toolRoot 'raw') -Recurse
        }
    } elseif (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Junction -Path $destination -Target $folder.FullName | Out-Null
    }
}
foreach ($name in $overlays) {
    $path = Join-Path $sourceRoot $name
    if ($name -ne 'english' -and (Test-Path -LiteralPath $path)) {
        Copy-Item -LiteralPath $path -Destination (Join-Path $toolRoot 'raw') -Recurse -Force
    }
}
Copy-Item -LiteralPath (Join-Path $sourceRoot 'localizedstrings') -Destination (Join-Path $toolRoot 'raw\english') -Recurse -Force
Copy-Item -LiteralPath (Join-Path $sourceRoot 'mod.csv') -Destination (Join-Path $toolRoot 'zone_source\mod.csv') -Force
if (-not (Test-Path -LiteralPath (Join-Path $toolRoot 'main'))) {
    New-Item -ItemType Junction -Path (Join-Path $toolRoot 'main') -Target (Join-Path $gameRoot 'main') | Out-Null
}
$linkerLog = Join-Path $buildRoot 'linker.log'
$linkerErrorLog = Join-Path $buildRoot 'linker-errors.log'
& python (Join-Path $PSScriptRoot 'economy-runtime.py') link --root $buildRoot
$exitCode = $LASTEXITCODE
$output = @(Get-Content -LiteralPath $linkerLog) + @(Get-Content -LiteralPath $linkerErrorLog)
if ($exitCode -ne 0 -or ($output -match 'ERROR:') -or -not ($output -match 'There were no errors or warnings')) {
    throw "Linker failed. See $buildRoot\linker.log"
}
New-Item -ItemType Directory -Force -Path $modRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $toolRoot 'zone\english\mod.ff') -Destination (Join-Path $modRoot 'mod.ff') -Force
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Write-Archive([string]$Name, [string[]]$Folders) {
    $path = Join-Path $modRoot $Name
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::Create)
    $zip = New-Object System.IO.Compression.ZipArchive($stream, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($folder in $Folders) {
            foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $sourceRoot $folder) -Recurse -File)) {
                $entry = $file.FullName.Substring($sourceRoot.Length + 1).Replace('\', '/')
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $entry) | Out-Null
            }
        }
    } finally { $zip.Dispose(); $stream.Dispose() }
}
Write-Archive 'pmflex.iwd' @('weapons', 'images', 'sound')
Write-Archive 'z_c_r.iwd' @('promod_ruleset')
Copy-Item -LiteralPath (Join-Path $sourceRoot 'tools\economy.cfg') -Destination (Join-Path $modRoot 'economy.cfg') -Force
Copy-Item -LiteralPath (Join-Path $gameRoot 'iw3mp.exe') -Destination $runtimeRoot -Force
Copy-Item -Path (Join-Path $gameRoot '*.dll') -Destination $runtimeRoot -Force
foreach ($folder in @('main', 'zone', 'miles')) {
    $destination = Join-Path $runtimeRoot $folder
    if (-not (Test-Path -LiteralPath $destination)) {
        New-Item -ItemType Junction -Path $destination -Target (Join-Path $gameRoot $folder) | Out-Null
    }
}
foreach ($name in @('localization.txt', 'cod4.ico', 'cod.bmp', 'codlogo.bmp')) {
    $path = Join-Path $gameRoot $name
    if (Test-Path -LiteralPath $path) { Copy-Item -LiteralPath $path -Destination $runtimeRoot -Force }
}
$playersRoot = Join-Path $runtimeRoot 'players'
if (-not (Test-Path -LiteralPath $playersRoot) -and (Test-Path -LiteralPath (Join-Path $gameRoot 'players'))) {
    Copy-Item -LiteralPath (Join-Path $gameRoot 'players') -Destination $playersRoot -Recurse
}
[ordered]@{ builtAt = (Get-Date).ToString('o'); sourcePath = $sourceRoot; runtimePath = $runtimeRoot;
    fastfileSha256 = (Get-FileHash -LiteralPath (Join-Path $modRoot 'mod.ff')).Hash } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $buildRoot 'build-result.json') -Encoding UTF8
Write-Output "Built isolated economy runtime: $runtimeRoot"
