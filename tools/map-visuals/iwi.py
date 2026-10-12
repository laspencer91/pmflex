# Minimal CoD4 IWI v6 reader/writer for DXT1 (0x0B) / DXT3 (0x0C) / DXT5 (0x0D) 2D textures.
# Mips are stored smallest first; header fileSizeForPicmip[i] = file size with the i largest mips dropped.
import io, struct
from PIL import Image

FMT = {0x0B: ('DXT1', 8), 0x0C: ('DXT3', 16), 0x0D: ('DXT5', 16)}

def _dds(fourcc, w, h, data):
    hdr = struct.pack('<4sIIIIIII44xII4sIIIIIIIIII', b'DDS ', 124, 0x81007, h, w, len(data), 0, 1,
                      32, 4, fourcc.encode(), 0, 0, 0, 0, 0, 0x1000, 0, 0, 0, 0)
    return hdr + data

def _mip_size(w, h, bs):
    return max(1, (w + 3) // 4) * max(1, (h + 3) // 4) * bs

def read(src):
    """src: a path or a file-like object."""
    d = src.read() if hasattr(src, 'read') else open(src, 'rb').read()
    assert d[:3] == b'IWi' and d[3] == 6, 'not an IWI v6'
    fmt, flags = d[4], d[5]
    w, h, _ = struct.unpack('<3H', d[6:12])
    name, bs = FMT[fmt]
    top = d[len(d) - _mip_size(w, h, bs):]
    return Image.open(io.BytesIO(_dds(name, w, h, top))).convert('RGBA'), fmt, flags

def write(path, im, fmt, flags=0):
    name, bs = FMT[fmt]
    im = im.convert('RGBA'); w, h = im.size
    mips = []
    while True:
        buf = io.BytesIO(); im.resize((w, h), Image.LANCZOS).save(buf, 'DDS', pixel_format=name)
        mips.append(buf.getvalue()[128:128 + _mip_size(w, h, bs)])
        if w == 1 and h == 1: break
        w, h = max(1, w // 2), max(1, h // 2)
    body = b''.join(reversed(mips))
    total = 28 + len(body)
    sizes = [total - sum(len(m) for m in mips[:i]) for i in range(4)]
    W, H = im.size
    open(path, 'wb').write(b'IWi' + bytes([6, fmt, flags]) + struct.pack('<3H4I', W, H, 1, *sizes) + body)
