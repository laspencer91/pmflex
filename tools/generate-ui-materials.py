"""Generate reproducible four-corner RGBA gradients and a CoD4 asset table."""

import argparse
import json
from pathlib import Path
import struct
import shutil
import subprocess
import math


def write_gradient(path, corners, size=256):
    # Uncompressed 32-bit TGA, top-left origin, eight alpha bits.
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, size, size, 32, 40)
    pixels = bytearray()
    tl, tr, bl, br = corners
    for y in range(size):
        v = y / (size - 1)
        for x in range(size):
            u = x / (size - 1)
            rgba = [round((1-u)*(1-v)*tl[c] + u*(1-v)*tr[c] +
                          (1-u)*v*bl[c] + u*v*br[c]) for c in range(4)]
            pixels.extend((rgba[2], rgba[1], rgba[0], rgba[3]))
    path.write_bytes(header + pixels)


def write_corner_frame(path, width, height, thickness, corner_x, corner_y):
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 40)
    pixels = bytearray()
    for y in range(height):
        for x in range(width):
            dx, dy = min(x, width - 1 - x), min(y, height - 1 - y)
            bold = (dy < thickness and dx < corner_x) or (dx < thickness and dy < corner_y)
            alpha = 235 if bold else (42 if dx == 0 or dy == 0 else 0)
            pixels.extend((255, 255, 255, alpha))
    path.write_bytes(header + pixels)


def write_glow_frame(path, width, height, thickness, corner_x, corner_y):
    # Padded power-of-two texture; its crisp frame is drawn separately.
    out_w, out_h = width * 2, 1 << ((height * 2 - 1).bit_length())
    ox, oy = (out_w - width) / 2, (out_h - height) / 2
    segments = []
    for left in (ox, ox + width - corner_x):
        for top in (oy, oy + height - thickness):
            segments.append((left, top, left + corner_x - 1, top + thickness - 1))
    for left in (ox, ox + width - thickness):
        for top in (oy, oy + height - corner_y):
            segments.append((left, top, left + thickness - 1, top + corner_y - 1))
    header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, out_w, out_h, 32, 40)
    pixels = bytearray()
    for y in range(out_h):
        for x in range(out_w):
            distance2 = min(max(a - x, 0, x - c)**2 + max(b - y, 0, y - d)**2
                            for a, b, c, d in segments)
            corner = 145 * math.exp(-distance2 / 72)
            dx, dy = min(abs(x-ox), abs(x-(ox+width-1))), min(abs(y-oy), abs(y-(oy+height-1)))
            edge_distance = min(dx, dy) if ox <= x < ox+width and oy <= y < oy+height else math.hypot(max(ox-x, 0, x-(ox+width-1)), max(oy-y, 0, y-(oy+height-1)))
            edge = 45 * math.exp(-(edge_distance**2) / 50)
            pixels.extend((255, 255, 255, round(max(corner, edge))))
    path.write_bytes(header + pixels)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--tools-root', type=Path, required=True)
    parser.add_argument('--convert', action='store_true')
    parser.add_argument('--output-root', type=Path)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    palettes = json.loads((repo / 'assets/ui-lab/palettes.json').read_text())
    textures = args.tools_root / 'texture_assets/ui_lab'
    textures.mkdir(parents=True, exist_ok=True)
    source_data = args.tools_root / 'source_data'
    source_data.mkdir(exist_ok=True)
    entries = []
    names = list(palettes)
    for name, palette in palettes.items():
        write_gradient(textures / (name + '.tga'), palette['corners'])
    for name, spec in {'lab_corner_panel': (256, 128, 2, 22, 14),
                       'lab_corner_button': (512, 80, 4, 32, 14)}.items():
        write_corner_frame(textures / (name + '.tga'), *spec)
        names.append(name)
        glow_name = name.replace('corner', 'glow')
        write_glow_frame(textures / (glow_name + '.tga'), *spec)
        names.append(glow_name)
    for name, filename in {'ui_penetration_ammo': 'penetration-ammo', 'ui_wall_impact': 'wall-impact'}.items():
        shutil.copyfile(repo / 'assets/ui-icons' / (filename + '.tga'), textures / (name + '.tga'))
        names.append(name)
    for name in names:
        entries.append(f'''    "{name}" ( "material.gdf" )
    {{
        "materialType" "2d"
        "colorMap" "texture_assets/ui_lab/{name}.tga"
        "blendFunc" "Blend"
        "surfaceType" "<none>"
        "tileColor" "no tile"
        "filterColor" "nomip bilinear"
        "formatColor" "Uncompressed"
        "nopicmipColor" "1"
        "depthTest" "Disable"
        "depthWrite" "Off"
        "cullFace" "None"
    }}''')
    (source_data / 'ui_lab.gdt').write_text('{\n' + '\n'.join(entries) + '\n}\n')
    print(f'Generated {len(entries)} UI textures and source_data/ui_lab.gdt', flush=True)
    if args.convert:
        if args.output_root is None:
            parser.error('--convert requires --output-root')
        images = args.output_root / 'style-assets/images'
        images.mkdir(parents=True, exist_ok=True)
        for name in names:
            command = [str(args.tools_root / 'bin/converter.exe'), '-single', 'material',
                       name, '-y', '-nospam', '-nopause', '-verbose']
            try:
                result = subprocess.run(command, cwd=args.tools_root / 'bin', capture_output=True,
                                        timeout=10, creationflags=subprocess.CREATE_NO_WINDOW)
            except subprocess.TimeoutExpired as error:
                log = (error.stdout or b'') + (error.stderr or b'')
                (args.output_root / (name + '-convert.log')).write_bytes(log)
                raise RuntimeError(f'Converter did not exit for {name}: {log.decode(errors="replace")}') from error
            log = result.stdout + result.stderr
            (args.output_root / (name + '-convert.log')).write_bytes(log)
            if result.returncode != 0 or b'ERROR' in log:
                raise RuntimeError(f'Material conversion failed for {name}: {log.decode(errors="replace")}')
            candidates = list((args.tools_root / 'raw/images').glob('*' + name + '.iwi'))
            if not candidates:
                raise RuntimeError(f'No converted image found for {name}')
            for image in candidates:
                shutil.copyfile(image, images / image.name)
            print(f'Converted {name}: ' + ', '.join(image.name for image in candidates))


if __name__ == '__main__':
    main()
