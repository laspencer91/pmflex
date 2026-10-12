[CmdletBinding()]
param([ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'game', [switch]$Offline)
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $repoRoot 'build\ui-learning'
$runtime = Join-Path $buildRoot $RuntimeName
$modRoot = Join-Path $runtime 'mods\pmflex'
if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $runtime 'iw3mp.exe') }) {
    throw 'Close this workspace CoD4 session before running its runtime check.'
}
foreach ($name in @('console_mp.log', 'games_mp.log')) {
    $path = Join-Path $modRoot $name
    if (Test-Path -LiteralPath $path) { Set-Content -LiteralPath $path -Value '' }
}
$arguments = @('+set', 'dedicated', '1', '+set', 'net_ip', '127.0.0.1',
    '+set', 'net_port', '28971', '+set', 'fs_basepath', ('"' + $runtime + '"'),
    '+set', 'fs_homepath', ('"' + $runtime + '"'), '+set', 'fs_game', 'mods/pmflex',
    '+set', 'ui_lab_smoke', '1', '+exec', 'ui_lab.cfg', '+map', 'mp_crash')
if ($Offline) {
    $arguments = @('+set', 'net_noudp', '1', '+set', 'net_noipx', '1',
        '+set', 'cl_punkbuster', '0', '+set', 'sv_punkbuster', '0') + $arguments
}
$process = Start-Process -FilePath (Join-Path $runtime 'iw3mp.exe') -WorkingDirectory $runtime `
    -ArgumentList $arguments -WindowStyle Hidden -PassThru
$passed = $false
$udpEndpointCount = $null
try {
    $deadline = (Get-Date).AddSeconds(35)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 1
        $consolePath = Join-Path $modRoot 'console_mp.log'
        $gameLogPath = Join-Path $modRoot 'games_mp.log'
        if (Test-Path -LiteralPath $consolePath) {
            $console = Get-Content -LiteralPath $consolePath -Raw
            if ($console -match 'script compile error|script runtime error') { throw 'CoD4 reported a script error.' }
        }
        if (Test-Path -LiteralPath $gameLogPath) {
            $gameLog = Get-Content -LiteralPath $gameLogPath -Raw
            if ($gameLog -match 'UI_LAB;SMOKE_FAILED') { throw 'The in-game UI smoke check failed.' }
            if ($gameLog -match 'UI_LAB;SMOKE_PASSED') {
                if ($Offline) {
                    $udpEndpointCount = @(& netstat -ano -p UDP |
                        Where-Object { $_ -match ('^\s*UDP\s+.*\s' + $process.Id + '\s*$') }).Count
                    if ($udpEndpointCount -ne 0) { throw 'The offline runtime opened a UDP endpoint.' }
                }
                $passed = $true
                break
            }
        }
        if ($process.HasExited) { throw 'CoD4 exited before the runtime check completed.' }
    }
    if (-not $passed) { throw 'Timed out waiting for the in-game UI smoke check.' }
} finally {
    if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
    foreach ($name in @('console_mp.log', 'games_mp.log')) {
        $source = Join-Path $modRoot $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $buildRoot ('smoke-' + $name)) -Force
        }
    }
    [ordered]@{ checkedAt = (Get-Date).ToString('o'); passed = $passed;
        scope = 'Dedicated server, test clients, GSC HUD allocation and menu events. No visual verification.';
        udpDisabled = [bool]$Offline; udpEndpointCount = $udpEndpointCount } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $buildRoot 'smoke-result.json') -Encoding UTF8
}
Write-Output 'Passed: cards, icons, parent links, menu events, fill, spacing, anchors, visibility, spawn, bar alignment, empty/full bars, percentage margin, three styles, opacity and reveal completion.'
if ($gameLog -match 'FLAT_LOADOUT;SMOKE_PASSED') {
    Write-Output 'Passed: single-page class/loadout responses, two-player class capacity, own-slot editing, slot release/reclaim, weapon validation, attachments, grenades, camo and Deploy.'
}
