# Map readability pass: lower-contrast world textures, greener foliage and per-map film grades.
#   python tools/map-visuals/map_visuals.py textures   writes images/*.iwi (packed into pmflex.iwd)
#   python tools/map-visuals/map_visuals.py visions    writes vision/pmflex_<map>.vision and promod/map_visuals.gsc
# Maps, strengths and overrides live in config.json. Stock data is only read: the map fastfiles and
# main/iw_*.iwd from the game, and raw/materials, raw/xmodel and raw/vision from the Mod Tools.
import argparse, json, os, re, zipfile, zlib, io
import numpy as np
from PIL import Image
import iwi

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(HERE, '..', '..'))
STR = re.compile(rb'[a-z0-9_/~\-\.@&$]{3,}')

def tokens(path):
    return [t.decode('latin1') for t in re.findall(rb'[\x20-\x7e]{3,}', open(path, 'rb').read())]

def map_color_images(game, tools, mapname, cfg):
    """colorMap image -> materials for world and prop surfaces in a map's fastfile."""
    ff = open(os.path.join(game, 'zone', 'english', mapname + '.ff'), 'rb').read()
    assert ff[:8] == b'IWffu100', mapname + '.ff is not an IW3 fastfile'
    names = {re.sub(r'^(mc|wc)/', '', m.decode()) for m in STR.findall(zlib.decompress(ff[12:]))}
    mdir, xdir = os.path.join(tools, 'raw', 'materials'), os.path.join(tools, 'raw', 'xmodel')
    mats = {n for n in names if os.path.isfile(os.path.join(mdir, n))}
    # Player bodies, heads, view hands and weapons keep their stock look so players stay distinct.
    character = set()
    for x in names:
        if re.match(cfg['character_model'], x) and os.path.isfile(os.path.join(xdir, x)):
            character |= {t for t in tokens(os.path.join(xdir, x)) if t in mats}
    images, skip = {}, set(character)
    for m in sorted(mats):
        toks = tokens(os.path.join(mdir, m))
        at = toks.index(m) if m in toks else 0
        techset = re.sub(r'^\W+', '', toks[at - 1]) if at > 0 else ''   # the technique set precedes the material name
        for i, t in enumerate(toks):
            if t == 'colorMap' and i > 0:
                images.setdefault(toks[i - 1], set()).add(m)
                if re.search(cfg['skip_techset'], techset): skip.add(m)
    # An image shared with an unlit, effect or character material keeps its stock pixels everywhere.
    keep = cfg['skip_image'] + '|' + cfg['keep_stock']
    return {img: ms for img, ms in images.items() if not (ms & skip) and not re.search(keep, img)}

def iwd_index(game):
    index = {}
    for path in sorted(p for p in os.listdir(os.path.join(game, 'main')) if re.match(r'iw_\d+\.iwd$', p)):
        with zipfile.ZipFile(os.path.join(game, 'main', path)) as z:
            for n in z.namelist():
                if n.startswith('images/') and n.endswith('.iwi'): index[n[7:-4]] = path   # later archives win
    return index

def rgb_to_hsv(a):
    mx, mn = a.max(-1), a.min(-1); d = mx - mn
    r, g, b = a[..., 0], a[..., 1], a[..., 2]; dd = np.maximum(d, 1e-6)
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) / 6
    return np.where(d > 0, h, 0), np.where(mx > 0, d / np.maximum(mx, 1e-6), 0), mx

def hsv_to_rgb(h, s, v):
    i = np.floor(h * 6) % 6; f = h * 6 - np.floor(h * 6)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    sel = [i == k for k in range(6)]
    return np.stack([np.select(sel, [v, q, p, p, t, v]), np.select(sel, [t, v, v, q, p, p]), np.select(sel, [p, p, t, v, v, q])], -1)

def process(name, im, cfg):
    a = np.asarray(im).astype(np.float32) / 255.0
    o = cfg['overrides'].get(name, {})
    if 'normal' in o:   # DXT5nm: X in alpha, Y in RGB; scale the slope
        x, y = (a[..., 3] * 2 - 1) * o['normal'], (a[..., 1] * 2 - 1) * o['normal']
        a[..., :3] = (y * 0.5 + 0.5)[..., None]; a[..., 3] = x * 0.5 + 0.5
        return a
    rgb, al = a[..., :3], a[..., 3]
    w = (al > 0.5).astype(np.float32)
    if w.sum() < 1: w = np.ones_like(al)
    mean = (rgb * w[..., None]).sum((0, 1)) / w.sum()
    rgb = mean + (rgb - mean) * o.get('contrast', cfg['contrast'])
    f = cfg['foliage']
    if re.search(f['pattern'], name):
        h, s, v = rgb_to_hsv(np.clip(rgb, 0, 1))
        dh = ((f['hue'] / 360.0 - h + 0.5) % 1.0) - 0.5
        # Atlases that also hold bark or stone only shift texels that are already yellow-green.
        m = np.ones_like(h) if re.search(f['full_mask_pattern'], name) else np.clip(1 - np.abs(((h - 0.22 + 0.5) % 1.0) - 0.5) / 0.08, 0, 1)
        rgb = hsv_to_rgb((h + dh * f['hue_mix'] * m) % 1.0, np.clip(s * (1 + (f['saturation'] - 1) * m), 0, 1), v)
    return np.dstack([np.clip(rgb, 0, 1), al])

def textures(args, cfg):
    out = os.path.join(REPO, 'images')
    manifest_path = os.path.join(HERE, 'manifest.json')
    old = json.load(open(manifest_path))['images'] if os.path.exists(manifest_path) else {}
    for n in old:   # drop the previous run's output so removed maps or images do not linger
        p = os.path.join(out, n + '.iwi')
        if os.path.exists(p): os.remove(p)
    wanted = {}
    for mapname in cfg['maps']:
        for img in map_color_images(args.game, args.tools, mapname, cfg): wanted.setdefault(img, set()).add(mapname)
    for img in cfg['overrides']: wanted.setdefault(img, set()).add('override')
    index, manifest, skipped = iwd_index(args.game), {}, []
    archives = {}
    for name in sorted(wanted):
        src = index.get(name)
        if not src: skipped.append(name + ' (not in iwd)'); continue
        if src not in archives: archives[src] = zipfile.ZipFile(os.path.join(args.game, 'main', src))
        data = archives[src].read('images/' + name + '.iwi')
        if data[:4] != b'IWi\x06' or data[4] not in iwi.FMT or data[5] & 0x06:   # odd formats, no-mip or cube images
            skipped.append(name + ' (format)'); continue
        if os.path.exists(os.path.join(out, name + '.iwi')): skipped.append(name + ' (hand-made image already in images/)'); continue
        im, fmt, flags = iwi.read(io.BytesIO(data))
        a = process(name, im, cfg)
        iwi.write(os.path.join(out, name + '.iwi'), Image.fromarray((a * 255).astype(np.uint8), 'RGBA'), fmt, flags)
        manifest[name] = {'maps': sorted(wanted[name]), 'source': src}
    json.dump({'config': cfg, 'images': manifest}, open(manifest_path, 'w'), indent=1, sort_keys=True)
    size = sum(os.path.getsize(os.path.join(out, n + '.iwi')) for n in manifest)
    print(f'wrote {len(manifest)} images ({size / 1e6:.1f} MB) for {cfg["maps"]}; skipped {len(skipped)}')
    for s in skipped: print('  skip', s)

def auto_grade(stock):
    """Starting grade for an untuned map: only a warm (tan/orange) highlight tint is pulled 40% toward neutral.
    Contrast, brightness and the shadow tint stay stock; neutralizing cool shadows warmed and muddied Crash."""
    t = np.array([float(v) for v in stock['r_filmLightTint'].split()])
    if t[0] - t[2] > 0.15: t = t.mean() + (t - t.mean()) * 0.6
    return {'r_filmDesaturation': f'{min(float(stock["r_filmDesaturation"]), 0.15):.3g}',
            'r_filmLightTint': ' '.join(f'{v:.3g}' for v in t)}

def visions(args, cfg):
    os.makedirs(os.path.join(REPO, 'vision'), exist_ok=True)
    for mapname, values in sorted(cfg['visions'].items()):
        stock = open(os.path.join(args.tools, 'raw', 'vision', mapname + '.vision'), newline='').read()
        lines, newline = stock.splitlines(), '\r\n' if '\r\n' in stock else '\n'
        if values == 'auto': values = auto_grade(dict(re.findall(r'^\s*(r_film\w+)\s+"([^"]*)"', stock, re.M)))
        for i, line in enumerate(lines):
            key = line.split()[0] if line.split() else ''
            if key in values: lines[i] = f'{key:<26}"{values[key]}"'
        open(os.path.join(REPO, 'vision', f'pmflex_{mapname}.vision'), 'w', newline='').write(newline.join(lines))
    cases = ''.join(f'\t\tcase "{m}":\n' for m in sorted(cfg['visions']))
    gsc = ('// Generated by tools/map-visuals/map_visuals.py visions. Do not edit.\n\n'
           '// Vision file for the current map: the PromodFlex grade when one exists, otherwise the stock vision.\n'
           'visionName()\n{\n\tmapname = getDvar( "mapname" );\n\n\tswitch ( mapname )\n\t{\n'
           f'{cases}\t\t\treturn "pmflex_" + mapname;\n\t\tdefault:\n\t\t\treturn mapname;\n\t}}\n}}\n')
    open(os.path.join(REPO, 'promod', 'map_visuals.gsc'), 'w', newline='\n').write(gsc)
    # mod.csv carries one rawfile row per generated vision, right after the helper script's row.
    csv_path = os.path.join(REPO, 'mod.csv')
    rows = [r for r in open(csv_path, newline='').read().splitlines(keepends=True) if not r.startswith('rawfile,vision/pmflex_')]
    helper = 'rawfile,promod/map_visuals.gsc\r\n'
    if helper not in rows: rows.insert(rows.index('rawfile,promod/platform.gsc\r\n'), helper)
    at = rows.index(helper) + 1
    rows[at:at] = [f'rawfile,vision/pmflex_{m}.vision\r\n' for m in sorted(cfg['visions'])]
    open(csv_path, 'w', newline='').write(''.join(rows))
    print('visions:',', '.join(f'vision/pmflex_{m}.vision' for m in sorted(cfg['visions'])))

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('step', choices=['textures', 'visions'])
    ap.add_argument('--game', default=r'D:\Games\Steam\steamapps\common\Call of Duty 4')
    ap.add_argument('--tools', default=os.path.join(REPO, '..', 'cod4-mod-tools'))
    args = ap.parse_args()
    cfg = json.load(open(os.path.join(HERE, 'config.json')))
    {'textures': textures, 'visions': visions}[args.step](args, cfg)
