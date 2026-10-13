"""The street's dirt drawn square by square, the way the street painting draws its road.

The painting's road (docs/concept/street-golden-hour.png, the foreground) is pale dust in big
squares that differ gently from one to the next, with two wheel tracks running down the middle of
the street (each groove a darker line with a lighter ridge beside it), and dark stones scattered
on it, each a square or two with a lit top. This draws the bold look's road tiles from those rules,
in the painting's colours with the light taken out (as draw_boards.py does):

    assets/textures/drawn/road_wide.png  the 8 m tile laid along the street (ground.gdshader), its
                                         middle row on the road's centre line, x along the street
    assets/textures/drawn/road.png       the 2 m tile shown through it in broad patches: dust and
                                         stones, no tracks

Both at 16 texels a metre (the bold look's: PixelArt.BOLD_TEXELS), seamless.

    python3 tools/textures/draw_road.py [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

from draw_boards import smooth_noise

ROOT = Path(__file__).resolve().parents[2]
PAINTING = ROOT / "docs/concept/street-golden-hour.png"
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_road.png"

# The albedo the road's colours are laid round, how much of the painting's spread is kept and how
# much greyer than its lit colours (draw_boards.palette). The spread is pushed past the painting's:
# the game's low sun and haze take some back (at 1.0 the rendered road's squares were half as
# contrasted as the painting's).
SPEC = {"albedo": [0.68, 0.53, 0.39], "contrast": 1.0, "grey": 0.1}
# Where the painting's road squares are read (x0, y0, x1, y1 in the 1672-wide picture, the square's
# size there): the near road either side of the gun, and the road a few metres on.
SQUARES = [(420, 780, 800, 940, 14), (880, 780, 1180, 940, 14), (560, 650, 1000, 780, 9)]
# The palette's size: the painting's near road is about ten tones, 5 L* or so apart in its light
# half, wider in its darks (scuffs, stones, the ruts' bottoms).
PAL_STEPS = range(10)
# The dark share: the palette's tones below this share of the painting's squares are scattered as
# dark squares; the rest is the dust. JITTER: the dust's square-to-square spread against its clumps'.
DARK = 0.16
JITTER = 0.2
# The share of a groove's squares filled with dust.
GAPS = 0.35
TEXELS = 16  # a metre
# The wheel tracks, in texels from the road's centre line (+ toward the saloon's side, z up): (where,
# how worn). The most used pair runs 2.2 m toward the saloon's side, under the street shot's feet
# (StreetMatch.FEET is 2.4 m off the centre line), so its grooves run out of the bottom of the frame
# toward the far end as the painting's do; a second pair on the centre line, a faint third beyond.
# A wagon's wheels are 1.5 m apart (24 texels).
GROOVES = [(23, 1.0), (47, 1.0), (-12, 0.7), (12, 0.7), (-50, 0.4), (-26, 0.4)]


def painting_squares(img: np.ndarray) -> np.ndarray:
    """The painting's road as squares: the median of the middle of each square it drew (about 14 px
    across in the 1672-wide picture near the bottom, 9 px further up), so the palette and its
    shares are its squares', not its pixels' (the median keeps a square's own colour where a box
    off the square grid would average two)."""
    out = []
    for x0, y0, x1, y1, p in SQUARES:
        for y in range(y0, y1 - p, p):
            for x in range(x0, x1 - p, p):
                c = img[y + p // 4:y + 3 * p // 4, x + p // 4:x + 3 * p // 4].reshape(-1, 3)
                out.append(np.median(c, 0))
    return np.array(out, np.float32)


def shares(sq: np.ndarray, pal_lit: np.ndarray) -> np.ndarray:
    """How often the painting uses each palette colour (pal_lit: the palette before the light is
    taken out, dark to light, as palette() sorts it)."""
    w = np.array([0.3, 0.59, 0.11])
    lum = sq @ w
    edges = np.convolve(np.sort(pal_lit @ w), [0.5, 0.5], "valid")
    return np.bincount(np.searchsorted(edges, lum), minlength=len(pal_lit)) / len(sq)


def field(w: int, h: int, cells: tuple, rng: np.random.Generator) -> np.ndarray:
    """Seamless value noise, the sum of octaves (cell size in texels, amplitude), about -0.5..0.5."""
    ys, xs = np.mgrid[0:h, 0:w]
    out = np.zeros((h, w))
    for cell, amp in cells:
        gh, gw = max(1, h // cell), max(1, w // cell)
        g = rng.random((gh, gw))
        gy, gx = ys / cell, xs / cell
        y0, x0 = np.floor(gy).astype(int), np.floor(gx).astype(int)
        ty, tx = gy - y0, gx - x0
        ty, tx = ty * ty * (3 - 2 * ty), tx * tx * (3 - 2 * tx)
        a = g[y0 % gh, x0 % gw]
        b = g[y0 % gh, (x0 + 1) % gw]
        c = g[(y0 + 1) % gh, x0 % gw]
        d = g[(y0 + 1) % gh, (x0 + 1) % gw]
        out += ((a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty - 0.5) * amp
    return out


def dust(w: int, h: int, share: np.ndarray, rng: np.random.Generator, ruts=None) -> np.ndarray:
    """Palette indices square by square. The painting's road is two things: pale dust whose squares
    each step a tone or so from the next, in slow clumps, and dark squares scattered across it on
    their own or two or three together across the street (scuffs, small stones, the ruts' bottoms),
    so the dark share of its palette (the tones below DARK of the way up) is placed as scattered
    squares and the light share matched to the dust's values (each colour as often as the painting
    uses it). `ruts`: a value per square pushed down where the wheels ran (grooves())."""
    n = len(share)
    dark_n = int(np.searchsorted(np.cumsum(share), DARK)) + 1
    clump = field(w, h, ((16, 1.0), (8, 0.6)), rng)
    v = clump * 0.9 + rng.normal(0, JITTER, (h, w))
    if ruts is not None:
        v = v + ruts * v.std()
    idx = match(v, share[dark_n:] / share[dark_n:].sum()) + dark_n
    # The dark squares: more in some patches than others (and down the ruts), runs of one to three
    # across the street (y).
    want = share[:dark_n].sum()
    p = want * (1.0 + 1.6 * field(w, h, ((8, 1.0),), rng))
    if ruts is not None:
        p = p + np.clip(-ruts, 0.0, None) * 0.35
    seeds = rng.random((h, w)) < p / 1.7
    tone = rng.choice(dark_n, size=(h, w), p=share[:dark_n] / want)
    for y, x in zip(*np.nonzero(seeds)):
        run = 1 + int(rng.random() < 0.45) + int(rng.random() < 0.2)
        for k in range(run):
            idx[(y + k) % h, x] = min(dark_n - 1, tone[y, x] + int(rng.integers(0, 2)) * (k > 0))
    if ruts is not None:
        # The ruts in the dark tones (deeper, darker). No lit ridge beside them: a ridge every
        # groove drew ruled light lines down the street, a grid (the blind critic, 2026-10-13).
        deep = ruts < -0.9
        idx[deep] = np.clip(dark_n - np.round(-ruts[deep] * 0.9), 0, dark_n - 1)
    return idx


def match(v: np.ndarray, share: np.ndarray) -> np.ndarray:
    """Palette indices with the given shares: the values ranked and cut at the cumulative shares
    (histogram matching)."""
    cuts = np.quantile(v, np.cumsum(share)[:-1])
    return np.searchsorted(cuts, v).astype(float)


def stones(idx: np.ndarray, count: int, rng: np.random.Generator) -> None:
    h, w = idx.shape
    for _ in range(count):
        y, x = int(rng.integers(0, h)), int(rng.integers(0, w))
        size = 2 if rng.random() < 0.3 else 1
        for dy in range(size):
            for dx in range(size):
                idx[(y + dy) % h, (x + dx) % w] = rng.integers(0, 2)
        idx[(y - 1) % h, x % w] = len(PAL_STEPS) - 1  # its lit top (rows run down the picture: -1 is "up")


def grooves(h: int, w: int, rng: np.random.Generator) -> np.ndarray:
    """The wheel tracks as a value per square (in the dust's spreads, negative = darker): each
    groove two squares of dark bottom with a lit ridge either side, and beside it a fainter second
    groove a few squares off where other wagons ran, drifting nearer and further; hoof churn in
    loose bands between the tracks."""
    v = np.zeros((h, w))
    centre = h // 2
    for off, depth in GROOVES:
        wobble = (smooth_noise(w, 64, rng) - 0.5) * 2.0 + (smooth_noise(w, 16, rng) - 0.5) * 2.0
        twin = 2.5 + smooth_noise(w, 32, rng) * 2.5
        side = 1 if rng.random() < 0.5 else -1
        for x in range(w):
            if rng.random() < GAPS:
                continue  # dust blown into it: the painting's ruts are broken runs of dark squares
            y = centre + off + int(round(wobble[x]))
            v[y % h, x] -= 2.6 * depth
            v[(y + 1) % h, x] -= 1.2 * depth * (rng.random() < 0.6)
            v[(y - 1) % h, x] += 0.7 * depth  # the ridge thrown up beside the groove
            t = y + side * int(round(twin[x]))
            if (x // 5) % 4 != 3:  # broken where the second wheel bit less
                v[t % h, x] -= 1.0 * depth * (rng.random() < 0.6)
    for mid in (35, 0):
        for _ in range(w // 2):
            x = int(rng.integers(0, w))
            y = centre + mid + int(rng.normal(0, 5))
            v[y % h, x] -= 1.0
    return v


def road_palette(sq: np.ndarray, k: int, seed: int = 7) -> tuple[np.ndarray, np.ndarray]:
    """The painting's road squares' colours as albedo (as draw_boards.palette: k-means, sorted dark
    to light, each a ratio to the mean laid round SPEC's albedo, greyed part way) and how often it
    uses each."""
    rng = np.random.default_rng(seed)
    centres = sq[rng.choice(len(sq), k, replace=False)].copy()
    for _ in range(40):
        lab = ((sq[:, None, :] - centres[None]) ** 2).sum(-1).argmin(1)
        for i in range(k):
            sel = sq[lab == i]
            if len(sel):
                centres[i] = sel.mean(0)
    counts = np.bincount(lab, minlength=k).astype(float)
    w = np.array([0.3, 0.59, 0.11])
    order = np.argsort(centres @ w)
    centres, counts = centres[order], counts[order]
    mean = (centres * counts[:, None]).sum(0) / counts.sum()
    lum = (centres @ w) / (mean @ w)
    hue = centres / np.maximum(centres.sum(1, keepdims=True), 1) * mean.sum() / np.maximum(mean, 1)
    hue = 1.0 + (hue - 1.0) * (1.0 - SPEC["grey"])
    tone = 1.0 + SPEC["contrast"] * (lum - 1.0)
    return np.array(SPEC["albedo"])[None] * tone[:, None] * hue, counts / counts.sum()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    img = np.asarray(Image.open(PAINTING).convert("RGB"))
    pal, share = road_palette(painting_squares(img), len(PAL_STEPS))
    n = len(pal)
    OUT.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(3301)
    wide = dust(128, 128, share, rng, grooves(128, 128, rng))
    stones(wide, 60, rng)
    small = dust(32, 32, share, rng)
    stones(small, 2, rng)
    made = {}
    for name, idx in (("road_wide", wide), ("road", small)):
        i = np.clip(np.round(idx), 0, n - 1).astype(int)
        data = np.clip(pal[i] * 255.0, 0, 255).astype(np.uint8)
        Image.fromarray(data).save(OUT / f"{name}.png")
        made[name] = data
        print(f"{name}: {data.shape[1]}x{data.shape[0]} -> assets/textures/drawn/{name}.png")
    print("palette", " ".join("#%02x%02x%02x" % tuple(int(min(255, round(c * 255))) for c in p) for p in pal))
    print("shares ", " ".join("%.2f" % x for x in share))
    if args.sheet:
        a = Image.fromarray(made["road_wide"]).resize((512, 512), Image.NEAREST)
        b = Image.fromarray(np.tile(made["road"], (4, 4, 1))).resize((512, 512), Image.NEAREST)
        sheet = Image.new("RGB", (1032, 512), (20, 20, 20))
        sheet.paste(a, (0, 0))
        sheet.paste(b, (520, 0))
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)


if __name__ == "__main__":
    main()
