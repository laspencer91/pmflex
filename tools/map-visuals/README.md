# Map visuals

Readability pass for stock maps, shipped through the mod (no new map files):

- **Textures**: every world and prop color map a map uses gets half its contrast around its own mean color, and grass and foliage are pushed toward green (`config.json` `contrast`, `foliage`). Player bodies, heads, view hands, weapons, HUD art and unlit, effect, decal-multiply and sky materials keep their stock images, and so do vehicles (`keep_stock`): their grit reads fine as cover, and leaving them out saves about 16 MB. The images go to `images/` and so into `pmflex.iwd`; a same-named image there replaces the stock one on every map that uses it.
- **Grades**: `vision/pmflex_<map>.vision` is the map's stock vision with the film values from `config.json` `visions`. `promod/map_visuals.gsc` (generated) returns that vision name for those maps, and the mod applies it at game start and at each round start in place of the stock one.

```
python tools/map-visuals/map_visuals.py textures   # images/*.iwi and manifest.json
python tools/map-visuals/map_visuals.py visions    # vision/, promod/map_visuals.gsc and the mod.csv rows
```

Then build as usual (`compile.bat` or the `tools/build-*.ps1` scripts, which now copy `vision/`).

## Adding a map

Add it to `maps` (textures) and to `visions` as `"auto"` or with explicit values, then run both steps. `"auto"` keeps the stock contrast, brightness and shadow tint and only pulls a warm highlight tint 40% toward neutral: lowering the lift or neutralizing a cool shadow tint made Crash muddier and Citystreets darker. Backlot's values were tuned by eye.

Promod forces `r_desaturation 0` on clients (`promod/client.gsc`), so a vision's `r_filmDesaturation` has no effect in the mod. Players who turn on Promod's film tweak (`r_filmUseTweaks`) see their own tweak values instead of any vision.

## Notes

- Inputs are read only: the map fastfiles and `main/iw_*.iwd` from the game (`--game`), and `raw/materials`, `raw/xmodel` and `raw/vision` from the Mod Tools (`--tools`).
- Images are global. A texture shared by several maps is processed once, the same way for all of them.
- `manifest.json` lists every generated image, the maps that use it and its source archive; the next `textures` run deletes those files before writing, so removing a map removes its images. Images in `images/` that are not in the manifest are never overwritten.
- Size: six maps add about 45 MB to `pmflex.iwd`, which the launcher installs with the client patch.
