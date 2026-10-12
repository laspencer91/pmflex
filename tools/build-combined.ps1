[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'game-combined-v5',
    [string]$RuntimeFilesPath = '',
    [string]$GamePath = 'C:\Program Files (x86)\Steam\steamapps\common\Call of Duty 4',
    [string]$ToolsPath = '',
    [switch]$UseStockAudio
)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if ($RuntimeFilesPath -eq '') {
    $verifiedRuntime = Join-Path $repoRoot 'build\ui-learning\game-combined-v3'
    if (Test-Path -LiteralPath (Join-Path $verifiedRuntime 'iw3mp.exe')) { $RuntimeFilesPath = $verifiedRuntime }
}
& (Join-Path $PSScriptRoot 'build-ui-lab.ps1') -RuntimeName $RuntimeName -RuntimeFilesPath $RuntimeFilesPath -GamePath $GamePath -ToolsPath $ToolsPath
$runtime = Join-Path $repoRoot ('build\ui-learning\' + $RuntimeName)
if ($UseStockAudio) {
    $audioToolsPath = $ToolsPath
    if ($audioToolsPath -eq '') { $audioToolsPath = Join-Path $PSScriptRoot '..\..\cod4-mod-tools' }
    Copy-Item -LiteralPath (Join-Path $audioToolsPath 'bin\mss32.dll') -Destination (Join-Path $runtime 'mss32.dll') -Force
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'combined.cfg') -Destination (Join-Path $runtime 'mods\pmflex\combined.cfg') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'standard.cfg') -Destination (Join-Path $runtime 'mods\pmflex\standard.cfg') -Force
& (Join-Path $PSScriptRoot 'prepare-local-session.ps1') -RuntimePath $runtime
$files = @('promod\repeat_buy.gsc', 'promod\repeat_buy_smoke.gsc', 'tools\standard.cfg', 'ui_mp\cac_ingame.inc', 'promod\profile_smoke.gsc', 'mod.csv', 'maps\mp\gametypes\_menus.gsc', 'maps\mp\gametypes\_promod.gsc',
    'maps\mp\gametypes\_class.gsc', 'maps\mp\gametypes\_globallogic.gsc', 'promod\economy.gsc',
    'promod\economy_items.gsc', 'promod\economy_armor.gsc', 'promod\flat_loadout.gsc',
    'ui_mp\scriptmenus\flat_loadout.menu', 'ui_mp\flat_loadout_widgets.inc', 'tools\combined.cfg',
    'promod\economy_penetration.gsc', 'tools\generate-ui-materials.py',
    'assets\ui-icons\penetration-ammo.tga', 'assets\ui-icons\wall-impact.tga')
$hashes = foreach ($file in $files) {
    [ordered]@{ path = $file; sha256 = (Get-FileHash -LiteralPath (Join-Path $repoRoot $file)).Hash }
}
[ordered]@{ builtAt = (Get-Date).ToString('o'); baseRevision = (& git -C $repoRoot rev-parse HEAD).Trim();
    runtime = $runtime; runtimeFilesPath = $RuntimeFilesPath; useStockAudio = [bool]$UseStockAudio; executableSha256 = (Get-FileHash -LiteralPath (Join-Path $runtime 'iw3mp.exe')).Hash;
    audioLibrarySha256 = (Get-FileHash -LiteralPath (Join-Path $runtime 'mss32.dll')).Hash; source = @($hashes); fastfileSha256 = (Get-FileHash -LiteralPath (Join-Path $runtime 'mods\pmflex\mod.ff')).Hash } |
    ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runtime 'combined-build.json') -Encoding UTF8
Write-Output "Combined runtime installed at $runtime"
