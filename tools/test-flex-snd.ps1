# PromodFlex S&D ruleset fixture: promod_mode flex_snd12 with promod/flex_snd_smoke.gsc driving real round ends.
[CmdletBinding()]
param([ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'game-stats-v1')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $repoRoot "build\ui-learning\$RuntimeName"
$exe = Join-Path $runtime 'iw3mp.exe'
if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { throw 'Validation runtime is running.' }
& (Join-Path $PSScriptRoot 'prepare-economy.ps1') -RuntimePath $runtime
$log = Join-Path $runtime 'mods\pmflex\games_mp.log'
$console = Join-Path $runtime 'mods\pmflex\console_mp.log'
foreach ($path in @($log, $console)) { Set-Content -LiteralPath $path -Value '' }
$arguments = @(
    '+set','dedicated','1','+set','net_noudp','1','+set','net_noipx','1',
    '+set','fs_basepath',('"' + $runtime + '"'),'+set','fs_homepath',('"' + $runtime + '"'),
    '+set','fs_game','mods/pmflex','+exec','ui_lab.cfg','+set','promod_mode','flex_snd12','+set','promod_economy','0',
    '+set','promod_red_dots','0','+set','cp_flexsnd_smoke','1','+set','cp_flexsnd_stage','0','+set','cp_flexsnd_failed','0','+map','mp_crash')
$process = Start-Process -FilePath $exe -WorkingDirectory $runtime -WindowStyle Hidden -PassThru -ArgumentList $arguments
try {
    # Three matches with ready-ups, strat time and round-end delays take about two and a half minutes.
    $deadline = (Get-Date).AddSeconds(300)
    do {
        Start-Sleep -Seconds 2
        $text = Get-Content -LiteralPath $log -Raw
        $output = Get-Content -LiteralPath $console -Raw
        if ($text -match 'CP_FLEXSND;SMOKE_FAILED' -or $output -match 'script compile error|script runtime error') { throw "Flex S&D ruleset check failed. See $log" }
        if ($text -match 'CP_FLEXSND;SMOKE_PASSED') { break }
        if ($process.HasExited -or (Get-Date) -ge $deadline) { throw "Flex S&D ruleset check timed out. See $log" }
    } while ($true)
    $udp = @(& netstat -ano -p UDP | Where-Object { $_ -match ('^\s*UDP\s+.*\s' + $process.Id + '\s*$') }).Count
    if ($udp) { throw 'Offline check opened UDP.' }
    ($text -split "`n" | Where-Object { $_ -match 'CP_FLEXSND;' }) -join "`n" | Set-Content -LiteralPath (Join-Path $repoRoot 'docs\evidence\2026-10-11-flex-snd-runtime.log') -Encoding UTF8
    Write-Output 'Passed the PromodFlex S&D ruleset fixture (flex_snd12): MR12 limits, strat time each round, halftime, overtime at 12-12 without a ready-up, its halftime, and match ends at 15-15, 16-13 and 13-8; zero UDP endpoints.'
} finally { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } }
