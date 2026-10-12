# Penetration icons

Prepared on 2026-10-09 from user-provided PNGs using the built-in imagegen tool. Original inputs are in `source/`; edited masters are in `master/`. Final `penetration-ammo.png` and `wall-impact.png` are 64x64 RGBA textures. Matching TGA files feed the native CoD4 material converter. `asset-manifest.json` records alpha ranges, dimensions and hashes.

`ui_penetration_ammo` is the purchase icon in the column beside the sniper primary. `ui_wall_impact` is the owned-upgrade marker in the loadout panel. The button calls the existing server-owned $100 sniper penetration purchase.

The imagegen prompt used for each edit was:

> Use case: background-extraction. Edit target: the supplied game UI icon of a [subject below]. This is only an asset preparation edit: preserve the existing artwork, exact shape, orientation, proportions, colors, texture and dark outline. Remove only excessive empty surrounding margins and stray nearly transparent background noise. Center the complete icon on a genuinely transparent square canvas, with about 4% transparent safety padding around its tight bounding box; make the longest dimension fill about 92% of the canvas. Keep alpha transparency and transparent holes. Do not redesign, redraw, add text, add objects or shadows. Output a clean cropped game icon ready for downsampling to a 64x64 CoD4 HUD texture.

Subjects:

- Wall impact: gold horizontal bullet passing through a silver vertical wall with three silver impact wedges.
- Penetration ammo: diagonal brass cartridge with a black pointed tip and red ring.

FFmpeg then downsampled each edited master with `scale=64:64:flags=lanczos` and converted the resulting PNG to BGRA TGA. Inspection found transparent and opaque pixels in both PNGs; the linked IWI headers report 64x64x1. This does not establish in-game visual appearance.
