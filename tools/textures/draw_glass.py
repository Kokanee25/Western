"""The saloon's window glass drawn square by square, as the street painting draws it.

The painting's windows (docs/concept/street-golden-hour.png, the saloon's front right of the door)
are dark panes between their bars: each pane a dark brown low down going to the sky's grey-blue
reflected along its top, a pale streak of sheen across it on the slant, and in two of them the
room's lamps behind the glass, a few warm orange squares; here and there a single bright square
where a corner catches the light. This draws one window, the whole opening (1.1 by 1.35 m, two
panes across and three up, FacadeArt._windows' bars), at 32 squares a metre:

    assets/textures/drawn/window_glass.png       its colours (rows top to bottom)
    assets/textures/drawn/window_glass_glow.png  what shines of its own: the lamps and the glints

FacadeArt lays it on a quad in the opening, just behind the bars.

    python3 tools/textures/draw_glass.py [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_glass.png"

W, H = 36, 44  # 1.1 x 1.35 m at 32 a metre
COLS, ROWS = 2, 3
DARK = np.array([22, 16, 13], float)       # the room's dark seen through the glass
SKY = np.array([78, 86, 96], float)       # the sky's grey-blue along a pane's top
SHEEN = np.array([150, 146, 136], float)
LAMP = [np.array([236, 150, 60], float), np.array([196, 104, 40], float), np.array([255, 206, 120], float)]
GLINT = np.array([255, 236, 190], float)
# Panes with the room's lamps behind them: (column, row from the top), where in the pane.
LAMPS = [((1, 1), (0.3, 0.55)), ((0, 2), (0.65, 0.35))]


def pane_box(c: int, r: int) -> tuple[int, int, int, int]:
    return (round(c * W / COLS), round(r * H / ROWS), round((c + 1) * W / COLS), round((r + 1) * H / ROWS))


def window(rng: np.random.Generator) -> tuple[np.ndarray, np.ndarray]:
    img = np.zeros((H, W, 3))
    glow = np.zeros((H, W, 3))
    for c in range(COLS):
        for r in range(ROWS):
            x0, y0, x1, y1 = pane_box(c, r)
            pw, ph = x1 - x0, y1 - y0
            for y in range(y0, y1):
                # The sky's reflection along the top fading to the room's dark, in a few steps.
                t = np.clip(1.0 - (y - y0) / (ph * 0.4), 0.0, 1.0)
                t = np.floor(t * 4.0) / 4.0
                for x in range(x0, x1):
                    col = DARK + (SKY - DARK) * t * (0.55 + 0.2 * r / ROWS)
                    col *= 0.9 + 0.2 * rng.random()
                    img[y, x] = col
            # The sheen: a slanting band two squares wide across the pane, broken.
            s = rng.uniform(0.15, 0.6) * pw
            for y in range(y0, y1):
                for dx in range(2):
                    x = int(x0 + s + (y - y0) * 0.6) + dx
                    if x0 <= x < x1 and rng.random() < 0.6:
                        img[y, x] = img[y, x] * 0.6 + SHEEN * 0.4 * (0.8 if dx else 1.0)
            # A glint on some panes' top corner, by the frame.
            if (c + r) % 2 == 0:
                gx = x0 + 1 if c == 0 else x1 - 2
                img[y0 + 1, gx] = GLINT
                glow[y0 + 1, gx] = GLINT * 0.6
    for (c, r), (fx, fy) in LAMPS:
        x0, y0, x1, y1 = pane_box(c, r)
        cx, cy = int(x0 + fx * (x1 - x0)), int(y0 + fy * (y1 - y0))
        # A lamp's glow: a small warm block, its middle bright, its edges ragged.
        for dy in range(-2, 3):
            for dx in range(-1, 3):
                edge = dy in (-2, 2) or dx in (-1, 2)
                if edge and rng.random() < 0.35:
                    continue
                y, x = cy + dy, cx + dx
                if not (x0 <= x < x1 and y0 <= y < y1):
                    continue
                core = dx in (0, 1) and dy in (-1, 0)
                col = LAMP[2] if core and dy == 0 else LAMP[0] if not edge else LAMP[1]
                img[y, x] = col
                glow[y, x] = col * (1.0 if core else 0.5)
    return np.clip(img, 0, 255).astype(np.uint8), np.clip(glow, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    img, glow = window(np.random.default_rng(1879))
    Image.fromarray(img).save(OUT / "window_glass.png")
    Image.fromarray(glow).save(OUT / "window_glass_glow.png")
    print(f"window_glass: {W}x{H} -> assets/textures/drawn/window_glass.png, _glow.png")
    if args.sheet:
        a = Image.fromarray(img).resize((W * 10, H * 10), Image.NEAREST)
        b = Image.fromarray(glow).resize((W * 10, H * 10), Image.NEAREST)
        sheet = Image.new("RGB", (W * 20 + 10, H * 10), (20, 20, 20))
        sheet.paste(a, (0, 0))
        sheet.paste(b, (W * 10 + 10, 0))
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)


if __name__ == "__main__":
    main()
