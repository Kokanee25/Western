#!/usr/bin/env python3
"""The texture factory, step 2: turn each image-model painting (assets/textures/raw/<id>.jpg,
tools/textures/paint_textures.py) into the game's tiles.

    python3 tools/textures/reduce.py [--only=floor,road] [--sheet=docs/screenshots/textures/x.png]

For each material in tools/textures/materials.json with a raw painting:
  1. crop to the material's shape (metres along x across), take out the painting's own lighting
     (a broad blur of its brightness divided out: the game lights it again);
  2. tile kinds: board joints the model drew anyway are wiped (a member is one board), then it's
     made seamless: blended with a copy rolled half a turn, behind a wavy edge, so the seam
     disappears into the mosaic (ground both ways, boards both ways too: members take random
     offsets across);
  3. a median over half a texel (the model's fine noise) and an area average down to 64 texels a
     metre (tools/textures/materials.json `texels_per_metre`): each texel the colour under it;
  4. the mosaic: each texel's difference from its neighbours pushed up a little (`MOSAIC`), as
     the painting's squares differ shade to shade; then the material's `lightness` and `chroma`
     (scales on L* and on a*/b*, set from what tools/judge.py measures against the paintings);
  5. its own palette (k-means in Lab, `colours`), every texel snapped to it.
Writes assets/textures/<id>.png (one texel a tile, read nearest by PixelArt.material(); its
.import is written too: lossless, mipmaps, never VRAM-compressed) and assets/textures/textures.json
(size, metres, palette per material; a sign's width follows the board the model painted). Then a
contact sheet: the painting, the tiles (x6, tile kinds repeated 2x2 to show the joins).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy.cluster.vq import kmeans2
from scipy.ndimage import gaussian_filter, gaussian_filter1d, median_filter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPEC = os.path.join(ROOT, "tools", "textures", "materials.json")
RAW = os.path.join(ROOT, "assets", "textures", "raw")
OUT = os.path.join(ROOT, "assets", "textures")
# How much of the painting's own light is taken out (1 = all of it; the game lights it again).
FLATTEN = 0.85
# How far each texel's difference from its neighbours is pushed (the painting's mosaic).
MOSAIC = 2.0
IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=0
mipmaps/generate=true
detect_3d/compress_to=0
"""


# --- colour (as tools/judge.py) --------------------------------------------------------------

def to_lab(rgb):
    a = rgb.astype(np.float64) / 255.0
    a = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0, 500.0 * (f[..., 0] - f[..., 1]), 200.0 * (f[..., 1] - f[..., 2])], -1)


def lab_to_rgb(lab):
    fy = (lab[..., 0] + 16.0) / 116.0
    f = np.stack([fy + lab[..., 1] / 500.0, fy, fy - lab[..., 2] / 200.0], -1)
    xyz = np.where(f > 0.206893, f ** 3, (f - 16.0 / 116.0) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    a = np.clip(xyz @ m.T, 0.0, 1.0)
    a = np.where(a <= 0.0031308, 12.92 * a, 1.055 * a ** (1 / 2.4) - 0.055)
    return np.clip(a * 255.0 + 0.5, 0, 255).astype(np.uint8)


# --- steps -----------------------------------------------------------------------------------

def crop_to(img, aspect):
    w, h = img.size
    if w / h > aspect:
        nw = round(h * aspect)
        return img.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    nh = round(w / aspect)
    return img.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))


def flatten(a, amount=FLATTEN):
    """Divide out the painting's broad light (vignette, a lit side) so the surface is even."""
    lum = a.mean(-1)
    broad = gaussian_filter(lum, max(a.shape[:2]) / 6.0, mode="wrap")
    gain = (lum.mean() / np.maximum(broad, 1e-3)) ** amount
    return np.clip(a * gain[..., None], 0.0, 1.0)


def wipe_joints(a):
    """Boards' joints the model drew anyway (a member is one board): rows where most of the width
    is a thin line darker than the rows a little above and below it (the gap between two boards,
    with its lit bevel beside it) are filled from either side; then a median along the grain takes
    out the short butt joints across it (the grain itself runs along it and survives)."""
    lum = a.mean(-1)
    h, w = lum.shape
    # Look past the gap itself (a few px wide) to the boards either side.
    k = max(3, h // 100)
    up = np.roll(lum, k, axis=0)
    down = np.roll(lum, -k, axis=0)
    # Darker than both by a share of the wood's own brightness (a gap in dark wood is dark too).
    drop = 0.12 * np.median(lum) + 0.01
    line = ((lum < up - drop) & (lum < down - drop)).mean(1)
    seams = [y for y in range(h) if line[y] > 0.4 and line[y] == line[max(0, y - k):y + k + 1].max()]
    band = np.zeros(h, bool)
    for y in seams:
        # the gap and the lit bevel beside it
        band[max(0, y - k):min(h, y + k + 1)] = True
    out = a.copy()
    good = np.flatnonzero(~band)
    if band.any() and len(good) > 2:
        for y in np.flatnonzero(band):
            above = good[good < y]
            below = good[good > y]
            ya = above[-1] if len(above) else below[0]
            yb = below[0] if len(below) else above[-1]
            t = 0.5 if ya == yb else (y - ya) / (yb - ya)
            out[y] = a[ya] * (1 - t) + a[yb] * t
    out = median_filter(out, size=(1, max(3, w // 60), 1), mode="wrap")
    return out, int(band.sum() * 100 / h)


def wavy_mask(n, m, rng, axis):
    """1 in the middle, 0 near both ends along `axis`, the edge between wandering along the other."""
    other = m
    t = np.arange(n) / n
    edge = np.minimum(t, 1.0 - t)  # 0 at the ends, 0.5 in the middle
    wobble = gaussian_filter1d(rng.standard_normal(other), max(other / 24.0, 1.0), mode="wrap")
    wobble = wobble / (np.abs(wobble).max() + 1e-6)
    start = 0.14 + 0.05 * wobble  # where each line along `axis` turns from the rolled copy to the original
    mask = np.clip((edge[None, :] - start[:, None]) / 0.03, 0.0, 1.0)  # (other, n)
    return mask if axis == 1 else mask.T


def seamless(a, rng):
    h, w = a.shape[:2]
    b = np.roll(a, w // 2, axis=1)
    m = wavy_mask(w, h, rng, 1)[..., None]
    a = a * m + b * (1 - m)
    b = np.roll(a, h // 2, axis=0)
    m = wavy_mask(h, w, rng, 0)[..., None]
    return a * m + b * (1 - m)


def to_texels(a, size):
    """Median over half a texel, then the area average of each texel's patch."""
    k = max(1, int(a.shape[1] / size[0] / 2))
    if k > 1:
        a = median_filter(a, size=(k, k, 1), mode="wrap")
    img = Image.fromarray((a * 255 + 0.5).astype(np.uint8))
    return np.asarray(img.resize(size, Image.BOX)).astype(np.float64) / 255.0


def mosaic(lab, amount=MOSAIC, wrap=True):
    near = np.stack([gaussian_filter(lab[..., c], 1.0, mode="wrap" if wrap else "nearest") for c in range(3)], -1)
    out = near + (lab - near) * amount
    out[..., 0] = np.clip(out[..., 0], 0, 100)
    return out


def palette_snap(lab, k, seed):
    flat = lab.reshape(-1, 3)
    k = min(k, len(np.unique(np.round(flat, 1), axis=0)))
    centres, _ = kmeans2(flat, k, minit="++", seed=seed, iter=30)
    d = ((flat[:, None, :] - centres[None]) ** 2).sum(-1)
    label = d.argmin(1)
    used = np.unique(label)
    centres = centres[used]
    d = ((flat[:, None, :] - centres[None]) ** 2).sum(-1)
    return centres[d.argmin(1)].reshape(lab.shape), centres[np.argsort(centres[:, 0])]


# --- running ---------------------------------------------------------------------------------

def reduce(mid, spec, tpm):
    raw = Image.open(os.path.join(RAW, mid + ".jpg")).convert("RGB")
    kind = spec["kind"]
    metres = list(spec["metres"])
    rng = np.random.default_rng(sum(map(ord, mid)))
    if kind == "sign":
        # The board as the model painted it: its height in metres, its width from its shape.
        metres[0] = round(metres[1] * raw.width / raw.height, 3)
    else:
        raw = crop_to(raw, metres[0] / metres[1])
    a = np.asarray(raw).astype(np.float64) / 255.0
    a = flatten(a, FLATTEN if kind != "sign" else 0.5)
    joints = 0
    if spec.get("boards", False):
        a, joints = wipe_joints(a)
    if kind != "sign":
        a = seamless(a, rng)
    size = (max(1, round(metres[0] * tpm)), max(1, round(metres[1] * tpm)))
    t = to_texels(a, size)
    lab = mosaic(to_lab((t * 255).astype(np.uint8)), MOSAIC, kind != "sign")
    # The judge's corrections per material: how light, how strongly coloured.
    lab[..., 0] *= spec.get("lightness", 1.0)
    lab[..., 1:] *= spec.get("chroma", 1.0)
    lab, pal = palette_snap(lab, spec["colours"], sum(map(ord, mid)))
    rgb = lab_to_rgb(lab)
    Image.fromarray(rgb).save(os.path.join(OUT, mid + ".png"))
    imp = os.path.join(OUT, mid + ".png.import")
    if not os.path.exists(imp):
        with open(imp, "w") as f:
            f.write(IMPORT)
    print("%-20s %3dx%-3d texels  %d colours%s" % (mid, size[0], size[1], len(pal),
          ("  (%d%% of rows were board joints)" % joints) if joints else ""))
    return {"kind": kind, "metres": metres, "texels": list(size),
            "palette": ["#%02x%02x%02x" % tuple(c) for c in lab_to_rgb(pal)]}, raw, rgb


def sheet(rows, path):
    th = 192
    cells = []
    for mid, raw, rgb, kind in rows:
        r = raw.copy()
        r.thumbnail((th * 3, th))
        t = Image.fromarray(rgb)
        if kind != "sign":
            big = Image.new("RGB", (t.width * 2, t.height * 2))
            for x in (0, t.width):
                for y in (0, t.height):
                    big.paste(t, (x, y))
            t = big
        s = th / t.height
        t = t.resize((max(1, round(t.width * s)), th), Image.NEAREST)
        cells.append((mid, r, t))
    width = max(c[1].width + c[2].width for c in cells) + 30
    img = Image.new("RGB", (width, len(cells) * (th + 24) + 8), (18, 14, 11))
    d = ImageDraw.Draw(img)
    y = 4
    for mid, r, t in cells:
        d.text((6, y), mid, fill=(235, 215, 180))
        img.paste(r, (6, y + 16))
        img.paste(t, (16 + r.width, y + 16))
        y += th + 24
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(path)


def main():
    only = None
    sheet_path = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all"):
            only = a.split("=", 1)[1].split(",")
        elif a.startswith("--sheet="):
            sheet_path = a.split("=", 1)[1]
    spec = json.load(open(SPEC))
    tpm = spec["texels_per_metre"]
    index_path = os.path.join(OUT, "textures.json")
    index = json.load(open(index_path)) if os.path.exists(index_path) else {}
    rows = []
    for mid, m in spec["materials"].items():
        if only and mid not in only:
            continue
        if not os.path.exists(os.path.join(RAW, mid + ".jpg")):
            continue
        index[mid], raw, rgb = reduce(mid, m, tpm)
        rows.append((mid, raw, rgb, m["kind"]))
    with open(index_path, "w") as f:
        json.dump(dict(sorted(index.items())), f, indent=1)
    if rows and sheet_path:
        sheet(rows, sheet_path)


if __name__ == "__main__":
    main()
