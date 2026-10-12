[CmdletBinding()]
param([ValidatePattern('^[A-Za-z0-9_-]+$')][string]$RuntimeName = 'platform-ready-check')
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$runtime = Join-Path $repoRoot "build\ui-learning\$RuntimeName"
$exe = Join-Path $runtime 'iw3mp.exe'
$log = Join-Path $runtime 'mods\pmflex\games_mp.log'
$console = Join-Path $runtime 'mods\pmflex\console_mp.log'
if (Get-Process iw3mp -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }) { throw 'Close this validation runtime first.' }
& (Join-Path $PSScriptRoot 'prepare-economy.ps1') -RuntimePath $runtime
foreach ($path in @($log, $console)) { if (Test-Path -LiteralPath $path) { Set-Content -LiteralPath $path -Value '' } }
$process = Start-Process -FilePath $exe -WorkingDirectory $runtime -WindowStyle Hidden -PassThru -ArgumentList @(
    '+set','dedicated','1','+set','net_noudp','1','+set','net_noipx','1',
    '+set','fs_basepath',('"' + $runtime + '"'),'+set','fs_homepath',('"' + $runtime + '"'),
    '+set','sv_punkbuster','0','+set','cl_punkbuster','0','+set','fs_game','mods/pmflex',
    '+exec','ui_lab.cfg','+set','cp_ready_smoke','1','+map','mp_crash')
try {
    $deadline = (Get-Date).AddSeconds(35)
    do {
        Start-Sleep -Seconds 1
        $text = if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Raw } else { '' }
        $output = if (Test-Path -LiteralPath $console) { Get-Content -LiteralPath $console -Raw } else { '' }
        if ($text -match 'SMOKE_FAILED' -or $output -match 'script compile error|script runtime error') { throw 'Platform ready check failed.' }
        if ($text -match 'CP_READY;SMOKE_PASSED') { break }
        if ($process.HasExited -or (Get-Date) -ge $deadline) { throw 'Ready check did not complete.' }
    } while ($true)
    $udp = @(& netstat -ano -p UDP | Where-Object { $_ -match ('^\s*UDP\s+.*\s' + $process.Id + '\s*$') }).Count
    if ($udp) { throw 'Offline check opened a UDP endpoint.' }
    $evidence = Join-Path $repoRoot 'docs\evidence\2026-10-09-platform-ready-runtime.log'
    $text | Set-Content -LiteralPath $evidence -Encoding UTF8
    Write-Output 'Passed: roster presence, outsiders, unready players, lost identity, missing roster, countdown cancellation/restart and 10-minute boundary. Zero UDP endpoints.'
} finally { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force } }
