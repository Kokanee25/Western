"""Textures for the saloon's front made from the street painting's own squares.

The street painting (docs/concept/street-golden-hour.png) draws weathered wood as a checker of
clearly different squares: cream, tan and grey-brown side by side, a little longer along the grain
than across, in clumps. A tile cut straight from the painting carries its perspective and its
light, so instead each material takes the painting's colours from a region of it (k-means, with
how often each appears) and lays them out again as squares on a flat tile: one texel a square,
runs of one to three texels along the grain, light and dark clumped by a coarse noise so a board
reads as worn rather than as static.

    python3 tools/textures/from_painting.py            # every material below
    python3 tools/textures/from_painting.py --sheet    # and docs/screenshots/textures/from_painting.png

Writes assets/textures/<id>.png (the grid material lays one texel at PixelArt.texels_per_meter:
32 a metre by default, the painting's near post is ~25). The colours are the painting's as lit at
golden hour; the game lights them again, so each is eased toward its mean (`flatten`) first.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAINTING = ROOT / "docs/concept/street-golden-hour.png"
OUT = ROOT / "assets/textures"
SHEET = ROOT / "docs/screenshots/textures/from_painting.png"

# id: where in the painting (pixels, 1672 wide), which pixels count, the tile (texels along the
# grain x across), the longest run along the grain, how many colours, how strongly a square keeps
# to its clump's tone, and the albedo the colours are laid round with their contrast (`contrast`
# times the painting's own spread about its mean): the painting's colours are lit, gold at golden
# hour, and the game lights the texture again, so each colour is taken as a ratio to the region's
# mean and laid round a plain albedo (the light taken out, the squares' differences kept).
MATERIALS = {
    # The saloon's posts, frames and the sign's frame: pale weathered grey-tan timber.
    "timber": {"boxes": [[12, 200, 62, 560], [255, 290, 290, 560]], "keep": "wood",
               "size": [64, 16], "run": 3, "colours": 10, "clump": 0.55,
               "albedo": [0.62, 0.55, 0.45], "contrast": 0.9},
    # The sign board: cream boards with grey-tan squares (the red lettering left out).
    "sign_board": {"boxes": [[60, 20, 420, 150]], "keep": "pale",
                   "size": [64, 16], "run": 3, "colours": 8, "clump": 0.45,
                   "albedo": [0.8, 0.72, 0.58], "contrast": 3.0},
    # The general store's front: pale grey weathered boards (its letters left out).
    "store_boards": {"boxes": [[640, 110, 800, 400]], "keep": "pale",
                     "size": [64, 16], "run": 3, "colours": 8, "clump": 0.5,
                     "albedo": [0.66, 0.61, 0.53], "contrast": 1.6},
    # The front's boards behind the porch and over it: a deep weathered red.
    "saloon_red": {"boxes": [[0, 150, 470, 560]], "keep": "red",
                   "size": [64, 16], "run": 3, "colours": 8, "clump": 0.5,
                   "albedo": [0.46, 0.14, 0.1], "contrast": 1.2},
}


def pixels(img: np.ndarray, spec: dict) -> np.ndarray:
    parts = []
    for x0, y0, x1, y1 in spec["boxes"]:
        parts.append(img[y0:y1, x0:x1].reshape(-1, 3))
    px = np.concatenate(parts).astype(np.float32)
    r, g, b = px[:, 0], px[:, 1], px[:, 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    keep = spec["keep"]
    if keep == "red":
        mask = (r > g * 1.75) & (r > 70) & (b < g * 1.2)
    elif keep == "pale":  # not the sky (blue over green) nor the red lettering
        mask = (lum > 110) & (b < g) & (r < g * 1.6)
    else:  # wood, lit gold: not the red paint, the sky or the deepest shade
        mask = (r < g * 2.0) & (b < g) & (lum > 40) & (lum < 235)
    return px[mask]


def kmeans(px: np.ndarray, k: int, seed: int = 7) -> tuple[np.ndarray, np.ndarray]:
    rng = np.random.default_rng(seed)
    centres = px[rng.choice(len(px), k, replace=False)]
    for _ in range(30):
        d = ((px[:, None, :] - centres[None, :, :]) ** 2).sum(-1)
        lab = d.argmin(1)
        for i in range(k):
            sel = px[lab == i]
            if len(sel):
                centres[i] = sel.mean(0)
    counts = np.bincount(lab, minlength=k).astype(np.float64)
    order = np.argsort(centres @ np.array([0.3, 0.59, 0.11]))
    return centres[order], counts[order] / counts.sum()


def noise(w: int, h: int, cell: int, rng: np.random.Generator) -> np.ndarray:
    """Coarse value noise, tiling, upsampled from a (w/cell) x (h/cell) grid."""
    gw, gh = max(w // cell, 1), max(h // cell, 1)
    g = rng.random((gh, gw))
    ys, xs = np.mgrid[0:h, 0:w]
    fx, fy = xs / cell, ys / cell
    x0, y0 = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - x0, fy - y0
    tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a = g[y0 % gh, x0 % gw]
    b = g[y0 % gh, (x0 + 1) % gw]
    c = g[(y0 + 1) % gh, x0 % gw]
    d = g[(y0 + 1) % gh, (x0 + 1) % gw]
    return (a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty


def tile(spec: dict, palette: np.ndarray, weights: np.ndarray, seed: int) -> np.ndarray:
    w, h = spec["size"]
    rng = np.random.default_rng(seed)
    clump = noise(w, h, 8, rng) * 0.6 + noise(w, h, 4, rng) * 0.4
    out = np.zeros((h, w), dtype=int)
    cdf = np.cumsum(weights)
    for y in range(h):
        x = 0
        while x < w:
            run = int(rng.integers(1, spec["run"] + 1))
            # A square's tone: drawn by how often the painting uses it, pulled toward the
            # clump's light or dark so neighbours agree a little.
            q = rng.random() * (1 - spec["clump"]) + clump[y, x] * spec["clump"]
            i = int(np.searchsorted(cdf, q))
            out[y, x:x + run] = min(i, len(palette) - 1)
            x += run
    mean = (palette * weights[:, None]).sum(0)
    lum = palette @ np.array([0.3, 0.59, 0.11]) / (mean @ np.array([0.3, 0.59, 0.11]))
    hue = palette / np.maximum(palette.sum(1, keepdims=True), 1.0) * mean.sum() / np.maximum(mean, 1.0)
    tone = 1.0 + spec["contrast"] * (lum - 1.0)
    cols = np.array(spec["albedo"])[None, :] * 255.0 * tone[:, None] * (1.0 + 0.5 * (hue - 1.0))
    # x along the grain: the image's columns run along u.
    return np.clip(cols[out], 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    img = np.asarray(Image.open(PAINTING).convert("RGB"))
    made = []
    report = {}
    for i, (key, spec) in enumerate(MATERIALS.items()):
        px = pixels(img, spec)
        palette, weights = kmeans(px, spec["colours"])
        data = tile(spec, palette, weights, 1873 + i)
        Image.fromarray(data).save(OUT / f"{key}.png")
        made.append((key, data))
        report[key] = {"pixels": int(len(px)), "palette": ["#%02x%02x%02x" % tuple(int(c) for c in p) for p in palette],
                       "weights": [round(float(x), 3) for x in weights]}
        print(f"{key}: {len(px)} pixels, {len(palette)} colours -> assets/textures/{key}.png")
    if args.sheet:
        scale = 8
        tiles = [Image.fromarray(d).resize((d.shape[1] * scale, d.shape[0] * scale), Image.NEAREST) for _, d in made]
        sheet = Image.new("RGB", (max(t.width for t in tiles), sum(t.height + 8 for t in tiles)), (20, 20, 20))
        y = 0
        for t in tiles:
            sheet.paste(t, (0, y))
            y += t.height + 8
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)
        print(SHEET)
    # The batwings' louvres: slats across the leaf (the grain, u, runs up a leaf taller than it's
    # wide), two squares of wood and a dark gap, in the timber's colours a shade darker.
    timber = np.asarray(Image.open(OUT / "timber.png").convert("RGB")).astype(float)
    slats = np.zeros((8, 12, 3))
    for x in range(12):
        k = x % 3
        slats[:, x] = timber[:8, x] * (0.78 if k == 0 else 0.62 if k == 1 else 0.22)
    Image.fromarray(np.clip(slats, 0, 255).astype(np.uint8)).save(OUT / "batwing_slats.png")
    print("batwing_slats -> assets/textures/batwing_slats.png")
    (OUT / "from_painting.json").write_text(json.dumps(report, indent=1) + "\n")


if __name__ == "__main__":
    main()
