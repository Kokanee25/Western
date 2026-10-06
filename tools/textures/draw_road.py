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

from draw_boards import palette, pixels, smooth_noise

ROOT = Path(__file__).resolve().parents[2]
PAINTING = ROOT / "docs/concept/street-golden-hour.png"
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_road.png"

SPEC = {"boxes": [[380, 700, 1000, 930]], "keep": "wood", "albedo": [0.68, 0.53, 0.39], "contrast": 1.1, "grey": 0.15}
TEXELS = 16  # a metre
# The wheel tracks, in texels from the road's centre line (+ toward the far side of the street):
# a wagon's two grooves 1.5 m apart, and a second, fainter pair where other wagons ran.
GROOVES = [(-12, 1.0), (12, 1.0), (-19, 0.55), (5, 0.55)]


def dust(w: int, h: int, pal: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    """Squares of dust: clumps of close tones from the palette's middle, wandering slowly."""
    n = len(pal)
    ys, xs = np.mgrid[0:h, 0:w]
    clump = np.zeros((h, w))
    for cell, amp in ((16, 1.4), (8, 0.9), (4, 0.5)):
        g = rng.random((h // cell + 1, w // cell + 1))
        gy, gx = ys / cell, xs / cell
        y0, x0 = np.floor(gy).astype(int), np.floor(gx).astype(int)
        ty, tx = gy - y0, gx - x0
        a = g[y0 % (h // cell), x0 % (w // cell)]
        b = g[y0 % (h // cell), (x0 + 1) % (w // cell)]
        c = g[(y0 + 1) % (h // cell), x0 % (w // cell)]
        d = g[(y0 + 1) % (h // cell), (x0 + 1) % (w // cell)]
        clump += ((a * (1 - tx) + b * tx) * (1 - ty) + (c * (1 - tx) + d * tx) * ty - 0.5) * amp
    idx = n / 2 - 0.5 + 0.6 + clump * 2.0 + rng.normal(0, 0.8, (h, w))
    return idx


def stones(idx: np.ndarray, count: int, rng: np.random.Generator) -> None:
    h, w = idx.shape
    for _ in range(count):
        y, x = int(rng.integers(0, h)), int(rng.integers(0, w))
        size = 2 if rng.random() < 0.3 else 1
        for dy in range(size):
            for dx in range(size):
                idx[(y + dy) % h, (x + dx) % w] -= 3.2
        idx[(y - 1) % h, x % w] += 1.5  # its lit top (rows run down the picture: -1 is "up")


def grooves(idx: np.ndarray, rng: np.random.Generator) -> None:
    h, w = idx.shape
    centre = h // 2
    for off, depth in GROOVES:
        wobble = (smooth_noise(w, 32, rng) - 0.5) * 3.0
        for x in range(w):
            y = centre + off + int(round(wobble[x]))
            idx[y % h, x] -= 4.2 * depth
            idx[(y + 1) % h, x] -= 2.6 * depth
            idx[(y - 1) % h, x] += 1.4 * depth  # the ridge thrown up beside the groove
            idx[(y + 2) % h, x] += 0.9 * depth
    # Hoof-churn down the middle between the tracks: darker squares in a loose band.
    for _ in range(w // 2):
        x = int(rng.integers(0, w))
        y = centre + int(rng.normal(0, 4))
        idx[y % h, x] -= 1.4


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    img = np.asarray(Image.open(PAINTING).convert("RGB"))
    pal = palette(pixels(img, SPEC), SPEC, k=10)
    n = len(pal)
    OUT.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(3301)
    wide = dust(128, 128, pal, rng)
    stones(wide, 70, rng)
    grooves(wide, rng)
    small = dust(32, 32, pal, rng)
    stones(small, 2, rng)
    made = {}
    for name, idx in (("road_wide", wide), ("road", small)):
        i = np.clip(np.round(idx), 0, n - 1).astype(int)
        data = np.clip(pal[i] * 255.0, 0, 255).astype(np.uint8)
        Image.fromarray(data).save(OUT / f"{name}.png")
        made[name] = data
        print(f"{name}: {data.shape[1]}x{data.shape[0]} -> assets/textures/drawn/{name}.png")
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
