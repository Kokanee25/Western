"""Flames drawn square by square, the way the fire painting draws them.

docs/concept/livery-fire.png draws its fire as shapes, not glows: tall licking tongues in clear
bands of solid colour, a near-white yellow core low down, orange through the body, deep red at
the tips and edges, and the top edge ragged, lifting away into separate licks. This draws a
flipbook of such tongues (docs/briefs/fire-look.md step 1): SHAPES tongue shapes down the sheet,
FRAMES frames of each across, a cell CELL_W x CELL_H squares, alpha 0 or 1. flame.gdshader picks
a shape per particle and steps through its frames; FireFX's flame particles carry it.

The colours are the painting's (k-means of its fire, the box over the burning livery), from the
deep red of the edges to the core's pale yellow. No image model: every frame is clean.

    python3 tools/textures/draw_flames.py [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/drawn/flames.png"
SHEET = ROOT / "docs/screenshots/textures/flames.png"

CELL_W, CELL_H = 12, 20
FRAMES, SHAPES = 6, 3

# The painting's fire, edge to core (sRGB): deep red, red, red-orange, orange, orange-yellow,
# yellow, the near-white core.
TONES = np.array([
    [150, 38, 8], [178, 52, 10], [226, 69, 9], [247, 109, 22], [250, 162, 47], [252, 212, 101],
    [255, 242, 186]], dtype=np.uint8)

# Each shape: its height in the cell, its width at the base, how far it sways and how quickly
# (waves up its length), and whether a lick breaks off its tip.
SHAPE = [
    {"height": 0.95, "base": 0.78, "sway": 0.16, "waves": 1.1, "lick": True},
    {"height": 0.8, "base": 0.9, "sway": 0.1, "waves": 0.8, "lick": False},
    {"height": 0.98, "base": 0.62, "sway": 0.22, "waves": 1.4, "lick": True},
]


def tongue(shape: dict, frame: int, phase: float, rng: np.random.Generator) -> np.ndarray:
    """One cell: an index into TONES per square, -1 for empty. Row 0 is the top. `phase` is the
    shape's own (the same through its frames, so they loop); `rng` rolls this frame's jags."""
    cell = np.full((CELL_H, CELL_W), -1, dtype=int)
    t = frame / FRAMES
    # The ragged edge: a few squares in or out per row, changing a little each frame.
    jag = rng.integers(-1, 2, size=CELL_H)
    for row in range(CELL_H):
        y = 1.0 - (row + 0.5) / CELL_H  # 0 at the bottom, 1 at the top
        top = shape["height"] - 0.06 * np.sin(2 * np.pi * t + phase)
        if y > top:
            continue
        u = y / top  # 0 at the base, 1 at the tip
        # A tongue: full width low down, narrowing to a point, the waist pinched a little.
        half = 0.5 * shape["base"] * (1.0 - u ** 1.6) * (1.0 - 0.15 * np.sin(np.pi * u))
        half = max(half * CELL_W + 0.5 * jag[row] * (u > 0.2), 0.0)
        centre = 0.5 * CELL_W + shape["sway"] * CELL_W * u * np.sin(
            2 * np.pi * (shape["waves"] * u - t) + phase)
        for col in range(CELL_W):
            d = abs(col + 0.5 - centre)
            if d > half:
                continue
            # Inner distance: 0 at the middle, 1 at the edge; the bands run by it and by height.
            inner = d / max(half, 0.5)
            heat = (1.0 - u) * 0.95 - inner * 0.9 + 0.32
            band = int(np.clip(np.floor(heat * 6.0), 0, 6))
            # Edges are always a red; a square's tone wanders one step either way now and then.
            if inner > 0.82 or half - d < 1.0:
                band = min(band, 1)
            band = int(np.clip(band + rng.choice([-1, 0, 0, 0, 0, 1]), 0, 6))
            cell[row, col] = band
    # A lick lifting off the tip: a few squares of red-orange over the tongue, climbing with t.
    if shape["lick"]:
        lift = (t * 1.6) % 1.0
        r0 = int(round((1.0 - shape["height"]) * CELL_H - 1 - lift * 4))
        c0 = int(round(0.5 * CELL_W + shape["sway"] * CELL_W * np.sin(phase - 2 * np.pi * t)))
        for dr, dc, tone in ((0, 0, 2), (-1, 0, 1), (0, 1, 1), (1, 0, 2)):
            r, c = r0 + dr, c0 + dc
            if 0 <= r < CELL_H and 0 <= c < CELL_W and lift < 0.8:
                cell[r, c] = tone
    return cell


def draw() -> Image.Image:
    rgba = np.zeros((CELL_H * SHAPES, CELL_W * FRAMES, 4), dtype=np.uint8)
    for s, shape in enumerate(SHAPE):
        for f in range(FRAMES):
            phase = np.random.default_rng(77 + s).uniform(0, 2 * np.pi)
            cell = tongue(shape, f, phase, np.random.default_rng(1000 * s + f))
            y0, x0 = s * CELL_H, f * CELL_W
            filled = cell >= 0
            rgba[y0:y0 + CELL_H, x0:x0 + CELL_W][filled, :3] = TONES[cell[filled]]
            rgba[y0:y0 + CELL_H, x0:x0 + CELL_W][filled, 3] = 255
    return Image.fromarray(rgba, "RGBA")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true", help="also write a large view to docs/screenshots")
    a = ap.parse_args()
    img = draw()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print("flames:", OUT.relative_to(ROOT), img.size)
    if a.sheet:
        big = Image.new("RGBA", img.size, (40, 30, 45, 255))
        big.alpha_composite(img)
        big = big.resize((img.width * 10, img.height * 10), Image.NEAREST)
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        big.convert("RGB").save(SHEET)
        print("sheet:", SHEET.relative_to(ROOT))


if __name__ == "__main__":
    main()
