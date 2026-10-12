[CmdletBinding()]
param([Parameter(Mandatory)][string]$RuntimePath)
$ErrorActionPreference = 'Stop'
$workspace = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\build')).Path
$runtime = (Resolve-Path -LiteralPath $RuntimePath).Path
if (-not $runtime.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Local session settings must stay inside this repository build directory.'
}
$players = Join-Path $runtime 'players'
if (Test-Path -LiteralPath $players) {
    foreach ($profile in Get-ChildItem -LiteralPath $players -Recurse -File -Filter 'config_mp.cfg') {
        $text = Get-Content -LiteralPath $profile.FullName -Raw
        foreach ($setting in @(@('net_noudp','1'), @('net_noipx','1'), @('cl_punkbuster','0'), @('sv_punkbuster','0'))) {
            $pattern = '(?m)^\s*seta?\s+' + $setting[0] + '\s+[^\r\n]*'
            $line = 'seta ' + $setting[0] + ' "' + $setting[1] + '"'
            if ($text -match $pattern) { $text = [regex]::Replace($text, $pattern, $line) }
            else { $text += "`r`n" + $line + "`r`n" }
        }
        Set-Content -LiteralPath $profile.FullName -Value $text -Encoding ASCII
    }
}
