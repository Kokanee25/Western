"""Boards drawn square by square, the way the street painting draws its wood.

Up close the painting's wood (docs/concept/street-golden-hour.png: the store's front, the
saloon's posts, the livery, the boardwalk) is four things together: a dark line between every
board, squares stretched two or three long along the grain, each board its own tone (one greyer,
one warmer) with the squares wandering gently within it, and pale weathered grey-tan wood whose
warmth is the sun's. This draws a set of boards per wood from those rules, one board a strip
(assets/textures/drawn/<wood>_b<k>.png: x along the grain, seamless; y across the board), with the
colours taken from the painting (k-means of a region, the light taken out round a plain albedo,
as from_painting.py does). WoodMaterials hands every member one strip by its ID, so no two
neighbours match; the dark line between boards is the grid shader's (edge_shade, a texel wide at
the member's long edges), so the strips carry none. PixelArt lays drawn wood at DRAWN_TEXELS (32
a metre) whatever the look's own density: a board a hand wide needs six squares across for its
line and grain to show (under the bold look's 16 a board was three squares, two of them line).

    python3 tools/textures/draw_boards.py [--only=timber,floor] [--sheet]
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PAINTING = ROOT / "docs/concept/street-golden-hour.png"
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_boards.png"

# wood: where its colours come from in the painting (pixels of the 1672-wide picture) and which
# pixels count, the albedo they're laid round and how much of the painting's spread is kept, the
# board's squares across (texels at 32 a metre: a 0.2 m lap board is 6), how many boards, how far
# a board's tone wanders from the next (`board_spread`, a fraction of L), and how much greyer than
# the painting's lit colours (`grey`, toward each colour's own luminance).
WOODS = {
    # The saloon's posts, frames and the sign's frame (FacadeArt): weathered grey-brown (the
    # painting's posts average a warm mid brown, lit gold where the sun catches them).
    "timber": {"boxes": [[12, 200, 62, 560], [255, 290, 290, 560]], "keep": "wood", "albedo": [0.56, 0.47, 0.37],
               "contrast": 1.0, "rows": 8, "count": 12, "board_spread": 0.1, "grey": 0.45, "lean": 0.4,
               "patch": 2, "patch_jitter": 1.6},
    # The general store's front and the plain fronts' boards: pale grey.
    "store_boards": {"boxes": [[640, 110, 800, 400]], "keep": "pale", "albedo": [0.68, 0.64, 0.56],
                     "contrast": 1.0, "rows": 6, "count": 12, "board_spread": 0.2, "grey": 0.3},
    # The saloon's red boards.
    # `worn`: that share of the board's squares, in clumps, is the paint worn through to grey wood
    # (the painting's red boards are faded brick red with pale patches, not an even red).
    "saloon_red": {"boxes": [[0, 150, 470, 560]], "keep": "red", "albedo": [0.4, 0.16, 0.11],
                   "contrast": 0.8, "rows": 6, "count": 10, "board_spread": 0.12, "grey": 0.3,
                   "worn": 0.16, "worn_from": "store_boards", "patch": 2, "patch_jitter": 1.2},
    # Bare weathered boards (side walls, the livery, sheds): the livery's front.
    "weathered_pine": {"boxes": [[1440, 150, 1600, 420]], "keep": "pale", "albedo": [0.6, 0.55, 0.47],
                       "contrast": 1.0, "rows": 6, "count": 12, "board_spread": 0.2, "grey": 0.3},
    # The boardwalks' planks (and the floors under the bold look): the saloon's boardwalk, warmer.
    "floor": {"boxes": [[130, 540, 420, 640]], "keep": "wood", "albedo": [0.64, 0.53, 0.41],
              "contrast": 0.9, "rows": 5, "count": 12, "board_spread": 0.12, "grey": 0.2},
    # The jail's whitewash: pale grey-white boards gone grey and tan where it's worn (the painting's
    # JAIL front and its side wall, lit low and gold).
    "jail_boards": {"boxes": [[1300, 340, 1395, 420], [1200, 430, 1255, 500]], "keep": "pale",
                    "albedo": [0.82, 0.8, 0.75], "contrast": 1.0, "rows": 6, "count": 12, "board_spread": 0.12,
                    "grey": 0.55, "patch": 2, "patch_jitter": 1.4},
}
LENGTH = 64  # texels along the grain: 2 m at 32 a metre


def pixels(img: np.ndarray, spec: dict) -> np.ndarray:
    parts = [img[y0:y1, x0:x1].reshape(-1, 3) for x0, y0, x1, y1 in spec["boxes"]]
    px = np.concatenate(parts).astype(np.float32)
    r, g, b = px[:, 0], px[:, 1], px[:, 2]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    keep = spec["keep"]
    if keep == "red":
        # Not the lamps' glow on it (bright orange).
        mask = (r > g * 1.75) & (r > 70) & (b < g * 1.2) & (lum < 105)
    elif keep == "pale":
        # Not the sky's grey-blue showing between boards.
        mask = (lum > 110) & (b < g * 0.92) & (r < g * 1.6) & (r > b * 1.25)
    else:
        mask = (r < g * 2.0) & (b < g) & (lum > 40) & (lum < 235)
    return px[mask]


def palette(px: np.ndarray, spec: dict, k: int = 8, seed: int = 7) -> np.ndarray:
    """The painting's colours as albedo: k-means, sorted dark to light, each a ratio to the region's
    mean laid round the wood's albedo, greyed part way."""
    rng = np.random.default_rng(seed)
    centres = px[rng.choice(len(px), k, replace=False)]
    for _ in range(30):
        lab = ((px[:, None, :] - centres[None]) ** 2).sum(-1).argmin(1)
        for i in range(k):
            sel = px[lab == i]
            if len(sel):
                centres[i] = sel.mean(0)
    counts = np.bincount(lab, minlength=k).astype(float)
    w = np.array([0.3, 0.59, 0.11])
    order = np.argsort(centres @ w)
    centres, counts = centres[order], counts[order]
    mean = (centres * counts[:, None]).sum(0) / counts.sum()
    lum = (centres @ w) / (mean @ w)
    hue = centres / np.maximum(centres.sum(1, keepdims=True), 1) * mean.sum() / np.maximum(mean, 1)
    hue = 1.0 + (hue - 1.0) * (1.0 - spec["grey"])
    tone = 1.0 + spec["contrast"] * (lum - 1.0)
    return np.array(spec["albedo"])[None] * tone[:, None] * hue


def smooth_noise(n: int, cell: int, rng: np.random.Generator) -> np.ndarray:
    """1-D value noise along the grain, seamless over n."""
    pts = rng.random(n // cell)
    x = np.arange(n) / cell
    i = np.floor(x).astype(int)
    t = x - i
    t = t * t * (3 - 2 * t)
    return pts[i % len(pts)] * (1 - t) + pts[(i + 1) % len(pts)] * t


def board(spec: dict, pal: np.ndarray, rng: np.random.Generator, worn: np.ndarray | None = None) -> np.ndarray:
    rows = spec["rows"]
    n = len(pal)
    # The board's own tone: a place in the palette (its middle colour, a little either way) and a
    # brightness of its own.
    # `lean`: how far toward the palette's light end a wood's boards sit (the painting's posts and
    # frames are mostly pale cream with grey-brown patches, not mid-brown).
    base = n / 2 - 0.5 + spec.get("lean", 0.0) * n / 4 + rng.normal(0, 0.6 + spec["board_spread"] * 3.0)
    bright = 1.0 + rng.normal(0, spec["board_spread"])
    idx = np.zeros((rows, LENGTH))
    # `patch`: squares this many rows tall and runs this much longer (the painting's posts are
    # bold patches, two squares across and three to six long, not fine speckle).
    patch = spec.get("patch", 1)
    runs = [2, 2, 3, 3, 4] if patch == 1 else [3, 4, 4, 5, 6]
    for y0 in range(0, rows, patch):
        # Each row of squares follows a slow wander along the grain (the grain's own light and
        # dark), so rows drift together and the board reads as one piece of wood.
        wander = (smooth_noise(LENGTH, 16, rng) - 0.5) * 2.2 + (smooth_noise(LENGTH, 6, rng) - 0.5) * 1.2
        x = int(rng.integers(0, 3))
        while x < LENGTH + 3:
            run = int(rng.choice(runs))  # squares two to four long along the grain
            jitter = rng.normal(0, 0.55 * spec.get("patch_jitter", 1.0))
            for k in range(run):
                for y in range(y0, min(y0 + patch, rows)):
                    idx[y, (x + k) % LENGTH] = base + wander[(x + k) % LENGTH] + jitter
            x += run
    # A streak or two: a long darker run down the grain (a crack, the weather in a seam).
    for _ in range(int(rng.integers(1, 3))):
        y = int(rng.integers(0, rows))
        x0 = int(rng.integers(0, LENGTH))
        for k in range(int(rng.integers(6, 18))):
            idx[y, (x0 + k) % LENGTH] -= 1.6
    # Now and then a knot: a dark square with a lighter one either side along the grain.
    if rng.random() < 0.45 and rows >= 5:
        y = int(rng.integers(1, rows - 1))
        x0 = int(rng.integers(0, LENGTH))
        idx[y, x0 % LENGTH] -= 3.0
        idx[y, (x0 + 1) % LENGTH] -= 2.0
        idx[y, (x0 - 1) % LENGTH] += 0.8
        idx[y, (x0 + 2) % LENGTH] += 0.8
    i = np.clip(np.round(idx), 0, n - 1).astype(int)
    img = pal[i] * bright
    if worn is not None:
        # Worn through: clumps of squares (two rows, three to six long) showing the bare wood.
        share = spec["worn"]
        wn = len(worn)
        bare = np.zeros((rows, LENGTH), bool)
        while bare.mean() < share:
            y0 = int(rng.integers(0, rows - 1))
            x0 = int(rng.integers(0, LENGTH))
            run = int(rng.integers(3, 7))
            for y in range(y0, min(y0 + int(rng.integers(1, 3)), rows)):
                for k in range(run + int(rng.integers(-1, 2))):
                    bare[y, (x0 + k) % LENGTH] = True
        tone = np.clip(np.round(wn / 2 + rng.normal(0, 1.0, (rows, LENGTH))), 0, wn - 1).astype(int)
        # faded: the bare wood still carries some of the paint's red
        img[bare] = worn[tone[bare]] * 0.5 + img[bare] * 0.45
    return np.clip(img * 255.0, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="")
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    only = [s for s in args.only.split(",") if s]
    img = np.asarray(Image.open(PAINTING).convert("RGB"))
    OUT.mkdir(parents=True, exist_ok=True)
    index = {}
    sheets = []
    for wi, (wood, spec) in enumerate(WOODS.items()):
        if only and wood not in only:
            continue
        pal = palette(pixels(img, spec), spec)
        worn = None
        if "worn_from" in spec:
            other = WOODS[spec["worn_from"]]
            worn = palette(pixels(img, other), other)
        rng = np.random.default_rng(2207 + wi)
        boards = []
        for k in range(spec["count"]):
            data = board(spec, pal, rng, worn)
            Image.fromarray(data).save(OUT / f"{wood}_b{k}.png")
            boards.append(data)
        # The tile (no strip number) for anything that asks for the wood without one: the boards
        # stacked.
        Image.fromarray(np.concatenate(boards[:4], 0)).save(OUT / f"{wood}.png")
        index[wood] = {"boards": spec["count"], "rows": spec["rows"], "length": LENGTH,
                       "palette": ["#%02x%02x%02x" % tuple(int(min(255, c * 255)) for c in p) for p in pal]}
        sheets.append((wood, boards))
        print(f"{wood}: {spec['count']} boards, {spec['rows']}x{LENGTH} -> assets/textures/drawn/")
    if not only:
        (OUT / "drawn.json").write_text(json.dumps(index, indent=1) + "\n")
    if args.sheet:
        scale = 8
        tiles = []
        for wood, boards in sheets:
            stack = np.concatenate([np.pad(b, ((0, 1), (0, 0), (0, 0))) for b in boards[:8]], 0)
            tiles.append(Image.fromarray(stack).resize((stack.shape[1] * scale, stack.shape[0] * scale), Image.NEAREST))
        sheet = Image.new("RGB", (max(t.width for t in tiles), sum(t.height + 12 for t in tiles)), (20, 20, 20))
        y = 0
        for t in tiles:
            sheet.paste(t, (0, y))
            y += t.height + 12
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)
        print(SHEET)


if __name__ == "__main__":
    main()
