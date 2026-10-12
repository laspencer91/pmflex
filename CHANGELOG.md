# Changelog

## Unreleased

## v0.1.0 - 2026-10-12

### 2026-10-12

- Released the standalone mod source and installable package with standard and economy configurations.
- Ordinary servers can run without an account or extension. The public match-stat interface is a no-op; optional stat tracking and managed admission require a separately installed server extension. A version contract detects incompatible overrides.
- Added `promod_buy_seconds` to configure the economy buy phase from 10 to 60 seconds, with a default of 30. Changes apply at the next buy phase.
- Increased the sniper armor penetration upgrade from $100 to $150 and Frag grenades from $50 to $100. Armor remains $50 per charge.
- Adjusted car explosion damage to 225 at the centre and 10 at the edge, with a radius of approximately 7.8 metres for sedans and 6.2 metres for other cars.
- Reduced redundant economy menu updates to fix `EXE_SERVERCOMMANDOVERFLOW` disconnects. Closed menus and test clients no longer receive continuous full refreshes.

### 2026-10-11

- Added `promod_mode flex_snd12` for Search and Destroy (`g_gametype sd`): MR12, first to 13, with one MR3 overtime at 12-12. A 15-15 result ends without a winner. Includes ready-up, six-second strat times, team timeouts and economy resets at half changes and overtime.
- Accepted CoD4x's standard IWD files to prevent false extra-file warnings in match mode.
- Added wall-penetration and distance fields to the optional match-stat hooks. Managed servers need a compatible statistics extension and service.
- Fixed round-start spawning in platform-managed S&D matches and errors caused by unset ready-up or knife-round flags.
- Improved world-texture readability and map grading on Backlot, Crash, Vacant, Citystreets, Strike and Crossfire. Player models, weapons, HUD art and vehicles retain their original textures.
- Increased the default economy buy phase from 20 to 30 seconds.
- Added `promod_reduced_frag 1`, which reduces Frag grenade damage to 65%. C4 and other explosives are unaffected.

### 2026-10-10

- Disabled the ready-up demo reminder when a CoD4x server records demos automatically.
- Removed false PunkBuster and modified-IWD warnings for supported PromodFlex and CoD4x files.
- Updated the About panel to identify PromodFlex and its Promod LIVE V2.20 base.
- Added a rebindable Buy Menu entry under Multiplayer Controls. Buy-phase hints display the player's assigned key.
- Added an armor icon and remaining-charge count to the HUD, cleared when joining a server without economy mode.
- Updated the loadout menu with clearer buy-open and buy-closed banners, class capacity, attachment labels, grenade controls, an armor column, hover descriptions and an AUTO-REBUY toggle.
- Added distinct purchase and refusal sounds.
- Attachments now belong to a loadout slot and follow compatible weapon changes. During buying, newly purchased items that are removed or become incompatible are refunded. Right-click refunds Frag grenades, armor charges, the sniper upgrade and equipped attachments; carried-over Frags and Demolitions are not refundable.
- Platform-managed servers restart the current map when a match ends; ordinary public servers retain map rotation.

### 2026-10-09

- Established PromodFlex v0.1 from Promod LIVE V2.20 and standardized the install folder and main archive as `mods/pmflex` and `pmflex.iwd`.
- Added `promod_mode flex_hq2v2` for Headquarters (`g_gametype koth`): two ten-minute halves, a side switch, no score cap, 60-second HQ lifetime, ten-second capture and five-second destruction. The holding team waits to respawn until its HQ is gone. Teams have two Assault and two Spec Ops slots, with no Demolitions or Sniper.
- Added standard and economy profiles through `promod_economy`, plus optional free supported red dots through `promod_standard_red_dots`. Switching profiles clears economy purchases and cash.
- Added a server-owned S&D economy: $100 income per round, $50 per enemy kill, $25 per eligible assist, $50 team rewards for a successful plant or defuse, $50 teammate gifts and a $300 Demolitions slot. Cash and ownership reset at halftime.
- Added purchasable Frags, red dots, suppressors and up to two armor charges. Unused Frags carry over when the owner survives; attachments expire each round. Armor reduces penetrating body-hit damage to 25%, consuming one charge per hit. Headshots, direct bullets, explosives and melee do not consume armor.
- Added a per-round sniper penetration upgrade for M40A3 and R700. Penetrating torso hits bypass armor while normal wall damage loss still applies; limb hits retain armor reduction.
- Added a single-page loadout menu with class capacity, weapon and attachment selection, tactical grenades, camo, teammate equipment, donations, cash and buy countdowns. Purchases require a living, spawned player during the buy phase; free loadout changes made later apply on the next spawn.
- Added optional automatic repeat purchases, with partial-budget handling and feedback when an item cannot be bought. Fixed stale donation targets and invalid attachment selections.
- Added optional managed-match admission, roster ready-up and statistics hooks while retaining ordinary offline server behavior. Managed ready-up cancels its countdown on disconnect or unready and has a ten-minute deadline.
- Added configurable UI palettes, HUD cards and a UI preview lab.
- Initially reduced car explosions to a six-metre radius with damage from 150 at the centre to zero at the edge; revised on October 12.
