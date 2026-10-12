# pmflex (PromodFlex)

`pmflex` is an independently maintained Call of Duty 4 Promod derivative. It builds one mod for the adjusted standard and economy profiles and installs under `mods/pmflex`. It is based on [Promod LIVE V2.20](https://github.com/promod/promod4) revision `d22de10be2625674f252be29448530220db48228`. It is not affiliated with or endorsed by the Promod team or Activision.

This repository contains the mod source. The mod works on ordinary servers without an account, plugin, or hosted service. The optional stat-tracking extension and hosted match service are separate software.

## License and credits

The mod assets are available under the **Promod Modder Ethical Public License 1.0 (PModEPL)** in [LICENSE.md](LICENSE.md). Keep the original copyright notices, disclaimers and license terms when redistributing or changing them. Record the date of changes, provide the mod assets in a form others can modify, and announce the same license. Changes to this derivative are dated in [CHANGELOG.md](CHANGELOG.md). The original `readme.txt` and Call of Duty 4 Mod Tools EULA are retained.

Promod credits: Andreas Göransson, Indrek Ardel, Ingram and FragNet. Activision does not make or support this mod. Call of Duty 4 and its Mod Tools are prerequisites; this repository does not provide the game or the Mod Tools.

The PModEPL applies to the Promod-derived mod assets in this repository. The independently developed server extension and hosted service are not included in this mod source distribution.

## Build

On Windows, install Call of Duty 4 and the [CoD4 Mod Tools](https://github.com/promod/CoD4-Mod-Tools). Use PowerShell 5.1 or later and Python 3. The builder expects `linker_pc.exe` in the Mod Tools `bin` directory. By default it looks for the tools in a sibling `cod4-mod-tools` directory; pass `-ToolsPath` when yours is elsewhere.

```powershell
.\tools\build-combined.ps1 `
  -GamePath 'C:\path\to\Call of Duty 4' `
  -ToolsPath 'C:\path\to\CoD4-Mod-Tools' `
  -UseStockAudio `
  -RuntimeName game-combined-v5
```

The output is `build/ui-learning/game-combined-v5/mods/pmflex/`. It contains `mod.ff`, `pmflex.iwd`, `z_c_r.iwd`, `ui_style.iwd`, and profile/test configuration files. `build/` is ignored by Git and is not part of the source release. The complete runtime also contains local game files, player profiles and logs; distribute only the built `mods/pmflex` contents when packaging the mod. The builder reads assets from the installed game and Mod Tools and writes its runtime into this repository's `build/` directory. `-UseStockAudio` uses the Mod Tools audio library for the local validation runtime; it is useful when the installed game has a CoD4x loader as `mss32.dll`. The legacy `compile.bat` uses a separately installed `7za` command; the PowerShell builder does not need it.

To install the public mod, copy the **contents** of that built `mods/pmflex` directory to the game's or server's `mods/pmflex` directory, replacing the corresponding files, then start with `fs_game mods/pmflex`. A client and a pure server need matching `mod.ff` and IWD bytes. Do not copy this repository's source folders directly into the game directory.

## Launch

From the Call of Duty 4 installation directory, after installing the built mod, start a local/LAN dedicated server with either profile:

```powershell
# Adjusted standard
.\iw3mp.exe +set dedicated 1 +set net_port 28979 +set fs_game mods/pmflex +set cp_platform_enabled 0 +exec standard.cfg +map mp_crash

# Economy
.\iw3mp.exe +set dedicated 1 +set net_port 28979 +set fs_game mods/pmflex +set cp_platform_enabled 0 +exec combined.cfg +map mp_crash
```

Run one server command at a time. The build places `standard.cfg` and `combined.cfg` in `mods/pmflex`; `+exec` loads the selected profile before the map. To join that local server from a separate game client with the same mod files installed:

```powershell
.\iw3mp.exe +set fs_game mods/pmflex +connect 127.0.0.1:28979
```

These commands use the standalone mod. Server operators who add an independent CoD4x extension configure and launch that extension separately.

## Profiles and local checks

Both profiles use the same mod package:

| Profile | Server configuration | Behavior |
| --- | --- | --- |
| Adjusted standard | `standard.cfg`; `promod_economy 0` | Original class/loadout flow with PromodFlex adjustments. |
| Economy | `combined.cfg`; `promod_economy 1` | Server-owned cash, buying, flat loadout and optional repeat purchases. |

The build installs both configurations. Apply one before starting a map. `tools/test-standard.ps1` checks the standard profile and switching; `tools/test-combined.ps1` checks economy behavior against a local dedicated runtime. Those checks use local game files and test clients. They do not establish a public release or human match verification.

The public `promod/match_stats.gsc` is a no-op interface for ordinary servers. `promod/platform.gsc` keeps managed admission disabled unless a compatible server extension is installed. `promod/match_stats_contract.gsc` provides the version used to check that extension. A server operator can add independent stat tracking through server-only CoD4x files; those files live outside `mods/pmflex` and do not replace the public mod package.

## Source layout

| Path | Purpose |
| --- | --- |
| `maps/`, `promod/`, `promod_ruleset/` | Gameplay scripts, modes and rules. |
| `ui_mp/`, `localizedstrings/`, `assets/`, `images/`, `vision/`, `weapons/`, `sound/` | Menu, text and game asset sources. |
| `mod.csv` | Fastfile input list. |
| `tools/` | Build helpers, configurations and local checks. |
| `CHANGELOG.md` | Dated derivative changes and verification notes. |

When contributing, keep original notices in affected files and add a dated change note to the changelog. Keep generated `build/` outputs and installed game files out of commits.
