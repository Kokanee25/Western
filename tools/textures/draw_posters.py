"""Wanted posters for the fronts, lettered square by square.

A poster is yellowed paper a little over half a metre tall: WANTED across the top in black block
letters three squares wide and five tall, a man's head drawn in a few browns under it, a line of
small print, a dollar figure, more small print, the paper's corners curled darker and a nail at
the top. Drawn in squares as the street painting's signs are (the letters a clean step at every
edge), one texel a square: assets/textures/drawn/poster_<k>.png. FacadeArt pins them beside the
saloon's door.

    python3 tools/textures/draw_posters.py [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_posters.png"

W, H = 29, 37
# Block letters, 3 wide and 5 tall: 1 = ink.
GLYPHS = {
    "W": ["10001", "10001", "10101", "10101", "01010"], "A": ["010", "101", "111", "101", "101"],
    "N": ["1001", "1101", "1011", "1001", "1001"], "T": ["111", "010", "010", "010", "010"],
    "E": ["111", "100", "110", "100", "111"], "D": ["110", "101", "101", "101", "110"],
    "R": ["110", "101", "110", "101", "101"], "$": ["011", "110", "010", "011", "110"],
    "0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
    "2": ["110", "001", "010", "100", "111"], "5": ["111", "100", "110", "001", "110"],
    " ": ["000", "000", "000", "000", "000"],
}
PAPER = np.array([[222, 204, 158], [212, 192, 146], [228, 214, 170], [202, 182, 138]], float)
INK = np.array([40, 30, 24], float)
POSTERS = [
    {"title": "WANTED", "reward": "$500", "skin": (176, 128, 92), "hair": (64, 44, 30), "hat": True},
    {"title": "REWARD", "reward": "$200", "skin": (168, 120, 86), "hair": (40, 30, 24), "hat": False},
]


def text(img: np.ndarray, s: str, y: int, colour: np.ndarray) -> None:
    width = sum(len(GLYPHS[ch][0]) + 1 for ch in s) - 1
    x = (W - width) // 2
    for ch in s:
        for r, row in enumerate(GLYPHS[ch]):
            for c, bit in enumerate(row):
                if bit == "1":
                    img[y + r, x + c] = colour
        x += len(GLYPHS[ch][0]) + 1


def poster(spec: dict, rng: np.random.Generator) -> np.ndarray:
    img = PAPER[rng.choice(len(PAPER), size=(H, W), p=[0.4, 0.25, 0.2, 0.15])]
    # Darker toward the edges and corners: old paper, sun and dust.
    ys, xs = np.mgrid[0:H, 0:W]
    edge = np.minimum(np.minimum(xs, W - 1 - xs), np.minimum(ys, H - 1 - ys))
    img *= (0.82 + 0.18 * np.clip(edge / 3.0, 0, 1))[..., None]
    text(img, spec["title"], 1, INK)
    # The face: an oval of skin with hair, eyes, a moustache, and a hat when he wears one.
    cx, cy = W // 2, 15
    skin, hair = np.array(spec["skin"], float), np.array(spec["hair"], float)
    for y in range(9, 22):
        for x in range(cx - 5, cx + 6):
            if ((x - cx) / 4.6) ** 2 + ((y - cy) / 5.6) ** 2 <= 1.0:
                img[y, x] = skin * (0.85 + 0.15 * rng.random())
    for x in range(cx - 4, cx + 5):
        img[10, x] = hair
    if spec["hat"]:
        for x in range(cx - 7, cx + 8):
            img[9, x] = INK * 1.3
        for y in range(7, 9):
            for x in range(cx - 4, cx + 5):
                img[y, x] = INK * 1.3
    img[14, cx - 2] = INK
    img[14, cx + 2] = INK
    for x in range(cx - 3, cx + 4):
        img[17, x] = hair
    img[18, cx - 3] = hair
    img[18, cx + 3] = hair
    # His shoulders.
    for y in range(21, 24):
        for x in range(cx - 7 + (23 - y), cx + 8 - (23 - y)):
            img[y, x] = INK * 1.6
    # Small print: rows of short dark dashes.
    for y in (25, 33):
        x = 3
        while x < W - 3:
            n = int(rng.integers(2, 5))
            for k in range(n):
                if x + k < W - 3:
                    img[y, x + k] = INK * 1.8
            x += n + 1
    text(img, spec["reward"], 27, INK)
    img[1, W // 2] = np.array([90, 80, 70], float)  # the nail
    return np.clip(img, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    rng = np.random.default_rng(1882)
    made = []
    for k, spec in enumerate(POSTERS):
        data = poster(spec, rng)
        Image.fromarray(data).save(OUT / f"poster_{k}.png")
        made.append(data)
        print(f"poster_{k}: {W}x{H} -> assets/textures/drawn/poster_{k}.png")
    if args.sheet:
        tiles = [Image.fromarray(d).resize((W * 10, H * 10), Image.NEAREST) for d in made]
        sheet = Image.new("RGB", (sum(t.width + 10 for t in tiles), H * 10), (20, 20, 20))
        x = 0
        for t in tiles:
            sheet.paste(t, (x, 0))
            x += t.width + 10
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)


if __name__ == "__main__":
    main()
