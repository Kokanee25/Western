"""The card table's top drawn square by square: `--style=painted` (the default since light pass round
5) as the painted saloon draws it, `--style=blocks` as the bold one did.

The painted saloon (docs/concept/saloon-painted.png, the judge's and the critic's target since round
1 of the light pass) paints its table smooth: amber planks about 12 cm wide, long flowing grain in
soft streaks, a fine dark line between the planks and a glossy pool of lamplight. The blocks style
drew every square its own step off its band, which up close at a low angle read as static (the
critic, round 4: "coarse, noisy red-orange squares"); the painted one keeps each plank's grain as
long streaks, a tone a run of squares, with the planks a touch apart in tone.

The blocks style:

Up close the painting's table (docs/concept/saloon-blocks.png, the foreground) is fine squares,
about 5 render pixels at 1280 wide where 32 a metre gave 20: rows of squares stretched two or
three long along the grain, the grain in bold bands that swing from amber to dark brown and bend
round the figure of the wood, and a dark line between the planks. This draws that tile (one metre
square, planks along x) in the painting's colours, laid round the factory tile's brightness so the
room's light on it is unchanged (the shot's tint still darkens it under its lamp):

    assets/textures/drawn/shot_table.png   TEXELS a metre (PixelArt.DRAWN_DENSITY), seamless

    python3 tools/textures/draw_table.py [--style=painted|blocks] [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

from draw_road import field

ROOT = Path(__file__).resolve().parents[2]
PAINTING = ROOT / "docs/concept/saloon-blocks.png"
FACTORY = ROOT / "assets/textures/shot_table.png"
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_table.png"

TEXELS = 128  # a metre: the painting's table squares
# Where its colours come from (the 1672-wide picture): the table top above the near cup.
BOX = (770, 700, 1100, 840)
K = 10  # tones
PLANK = 14  # texels across a plank (0.11 m)
# How far the grain swings (texels) and how long its bends are, the bands' spacing across the plank.
SWING, BEND, BAND = 1.6, 96.0, 3.4
JITTER = 0.95  # each square's own step off its band, in tones
SPREAD = 1.25
HUE_SHARE = 0.5  # how much of each tone's own hue against the mean's it keeps
GREY = 0.3  # how far its mean colour is greyed from the painting's lit hue  # the tones' spread round their mean against the painting's (the lamp takes some back)


def palette(img: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """The table's tones: k-means of its wood pixels (orange-brown, not the cups' grey or the
    lamp's yellow), sorted dark to light, laid round the factory tile's mean. Returns the albedo
    palette and how often the painting uses each tone."""
    x0, y0, x1, y1 = BOX
    px = img[y0:y1, x0:x1].reshape(-1, 3).astype(np.float64)
    r, g, b = px.T
    px = px[(r > g * 1.3) & (b < g * 0.75) & (r > 25)]
    rng = np.random.default_rng(5)
    c = px[rng.choice(len(px), K, replace=False)].copy()
    for _ in range(40):
        lab = ((px[:, None] - c[None]) ** 2).sum(-1).argmin(1)
        for i in range(K):
            if (lab == i).any():
                c[i] = px[lab == i].mean(0)
    counts = np.bincount(lab, minlength=K).astype(float)
    o = np.argsort(c @ [0.3, 0.59, 0.11])
    c, counts = c[o], counts[o]
    mean = (c * counts[:, None]).sum(0) / counts.sum()
    # The factory tile's brightness, the painting's hue greyed part way (the room's lamps add the
    # rest of its warmth; the factory's own hue drew the table red).
    w = np.array([0.3, 0.59, 0.11])
    factory = np.asarray(Image.open(FACTORY).convert("RGB")).reshape(-1, 3).mean(0) / 255.0
    hue = mean / 255.0 * (factory @ w) / (mean / 255.0 @ w)
    target = hue + (np.full(3, factory @ w) - hue) * GREY
    # Each tone's brightness against the mean, spread by SPREAD; its hue against the mean's,
    # halved (a cluster's own hue pushed further turned grey-violet).
    lum = (c @ w) / (mean @ w)
    hue_r = (c / (c @ w)[:, None]) / (mean / (mean @ w))
    tone = 1.0 + (lum - 1.0) * SPREAD
    return np.clip(target[None] * tone[:, None] * (1.0 + (hue_r - 1.0) * HUE_SHARE), 0.0, 1.0), counts / counts.sum()


def draw(n: int, share: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    size = TEXELS
    ys, xs = np.mgrid[0:size, 0:size].astype(float)
    figure = field(size, size, ((32, 1.0), (16, 0.5)), rng)
    idx = np.zeros((size, size))
    for p0 in range(0, size, PLANK):
        rows = slice(p0, min(p0 + PLANK, size))
        y, x = ys[rows], xs[rows]
        ph = rng.random(3) * 2 * np.pi
        # The grain: bands across the plank whose line swings along it (sines with whole periods
        # over the tile, so it stays seamless), bent further by the wood's figure.
        bend = SWING * (np.sin(2 * np.pi * x / size * round(size / BEND) + ph[0])
                        + 0.5 * np.sin(2 * np.pi * x / size * round(size / BEND * 2.3) + ph[1]))
        v = np.sin((y - p0 + bend + figure[rows] * 3.0) / BAND * np.pi + ph[2])
        v = v + 0.35 * figure[rows] + rng.normal(0, 0.18)
        idx[rows] = v
    # Ranked into the painting's shares, then each square jittered along its row in runs of 2-3
    # (the painting's squares are stretched along the grain, about twice as long as tall).
    cuts = np.quantile(idx, np.cumsum(share)[:-1])
    idx = np.searchsorted(cuts, idx).astype(float)
    for y in range(size):
        x = int(rng.integers(0, 3))
        while x < size + 3:
            run = int(rng.choice([1, 2, 2, 2, 3]))
            j = rng.normal(0, JITTER)
            for k in range(run):
                idx[y, (x + k) % size] += j
            x += run
    # The dark line between planks, and a lighter worn edge beside it now and then.
    for p0 in range(0, size, PLANK):
        idx[p0] = rng.choice([0, 0, 1], size)
        idx[(p0 + 1) % size] += (rng.random(size) < 0.3) * 1.0
    # A knot or two: a dark eye with rings.
    for _ in range(1):
        cy, cx = rng.integers(0, size, 2)
        d = np.hypot((ys - cy) * 1.8, (xs - cx) * 0.6)
        idx = np.where(d < 1.2, 1.0, np.where(d < 4.0, idx - np.cos(d * 1.6) * 1.0, idx))
    return np.clip(np.round(idx), 0, n - 1).astype(int)


# The painted style: where its colours come from (the 1672-wide painted saloon: the table right of
# the lamp, short of the bottle), the planks' width, the grain's bands across a plank, how far each
# plank's tone is off the others', and how much a square may step off its streak.
PAINTED = ROOT / "docs/concept/saloon-painted.png"
PAINTED_BOX = (1150, 720, 1440, 860)
PAINTED_PLANK = 16  # 0.125 m
PAINTED_BAND = 5.5
PAINTED_PLANK_TONE = 0.35
PAINTED_JITTER = 0.22


def draw_painted(n: int, share: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    size = TEXELS
    ys, xs = np.mgrid[0:size, 0:size].astype(float)
    figure = field(size, size, ((64, 1.0), (32, 0.5)), rng)
    along = field(size, size, ((64, 1.0),), rng)
    idx = np.zeros((size, size))
    for p0 in range(0, size, PAINTED_PLANK):
        rows = slice(p0, min(p0 + PAINTED_PLANK, size))
        y, x = ys[rows], xs[rows]
        ph = rng.random(3) * 2 * np.pi
        # Long streaks: bands across the plank, their line swinging slowly along it (whole periods
        # over the tile: seamless), bent by the wood's broad figure; each plank its own tone.
        bend = SWING * 0.8 * (np.sin(2 * np.pi * x / size * 1 + ph[0])
                              + 0.4 * np.sin(2 * np.pi * x / size * 2 + ph[1]))
        v = 0.7 * np.sin((y - p0 + bend + figure[rows] * 3.0) / PAINTED_BAND * np.pi + ph[2])
        idx[rows] = v + 0.6 * along[rows] + rng.normal(0, PAINTED_PLANK_TONE)
    cuts = np.quantile(idx, np.cumsum(share)[:-1])
    idx = np.searchsorted(cuts, idx).astype(float)
    # A square now and then a step off its streak, in runs along the grain (4-8 long).
    for y in range(size):
        x = int(rng.integers(0, 8))
        while x < size + 8:
            run = int(rng.integers(4, 9))
            j = rng.normal(0, PAINTED_JITTER)
            for k in range(run):
                idx[y, (x + k) % size] += j
            x += run
    # The fine dark line between planks.
    for p0 in range(0, size, PAINTED_PLANK):
        idx[p0] = np.minimum(idx[p0], rng.choice([0, 0, 1], size))
    return np.clip(np.round(idx), 0, n - 1).astype(int)


def main() -> None:
    global BOX, SPREAD, HUE_SHARE
    ap = argparse.ArgumentParser()
    ap.add_argument("--style", choices=["painted", "blocks"], default="painted")
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    if args.style == "painted":
        # Every tone the mean's hue (the painting's own tones, laid round a greyed mean, turned mauve);
        # the tones closer than the painting's (at its spread the grain read as noise up close).
        BOX, SPREAD, HUE_SHARE = PAINTED_BOX, 0.7, 0.0
        pal, share = palette(np.asarray(Image.open(PAINTED).convert("RGB")))
        rng = np.random.default_rng(4410)
        data = (pal[draw_painted(len(pal), share, rng)] * 255.0 + 0.5).astype(np.uint8)
    else:
        pal, share = palette(np.asarray(Image.open(PAINTING).convert("RGB")))
        rng = np.random.default_rng(4410)
        data = (pal[draw(len(pal), share, rng)] * 255.0 + 0.5).astype(np.uint8)
    OUT.mkdir(parents=True, exist_ok=True)
    Image.fromarray(data).save(OUT / "shot_table.png")
    print(f"shot_table: {TEXELS}x{TEXELS} -> assets/textures/drawn/shot_table.png")
    print("palette", " ".join("#%02x%02x%02x" % tuple(int(round(c * 255)) for c in p) for p in pal))
    if args.sheet:
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(np.tile(data, (1, 2, 1))).resize((TEXELS * 8, TEXELS * 4), Image.NEAREST).save(SHEET)


if __name__ == "__main__":
    main()
