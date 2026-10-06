"""The room seen through the saloon's door, drawn square by square as the street painting draws it.

Past the painting's batwings (docs/concept/street-golden-hour.png, the saloon's door) the room is
warm gloom, not black: a back wall of upright boards, two ceiling beams lit along their undersides,
a lamp hung from the far beam with its glow on the wall round it, and a man in a hat standing
dark against it. The street fronts aren't built inside, so FacadeArt hangs this on a quad behind
the doorway (2.6 by 3.1 m, the door's 1.4 by 2.3 m in its middle and its foot 0.1 m up), drawn
unshaded:

    assets/textures/drawn/doorway_room.png   16 squares a metre, rows top to bottom

    python3 tools/textures/draw_doorway.py [--sheet]
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/drawn"
SHEET = ROOT / "docs/screenshots/textures/drawn_doorway.png"

W, H = 42, 50  # 2.6 x 3.1 m at 16 a metre
WALL = [np.array(c, float) for c in ([46, 28, 17], [54, 33, 20], [40, 24, 15], [60, 37, 22])]
SEAM = np.array([24, 14, 9], float)
BEAM = np.array([92, 58, 32], float)
BEAM_LIT = np.array([150, 98, 52], float)
FLOOR = np.array([30, 19, 12], float)
MAN = np.array([20, 13, 9], float)
RIM = np.array([92, 52, 26], float)
LAMP = [np.array([255, 214, 130], float), np.array([238, 156, 64], float), np.array([120, 70, 30], float)]
# Where things are, in squares from the top-left (the door spans columns 10-31, rows 11-47).
BEAMS = [5, 12]
LAMP_AT = (18, 16)
FLOOR_ROW = 48  # the room's floor, level with the street front's (the quad's foot is 0.1 m lower)
MAN_AT = 26  # his middle column


def room(rng: np.random.Generator) -> np.ndarray:
    img = np.zeros((H, W, 3))
    # The back wall: upright boards three squares wide, each its own tone, a dark seam between.
    for x in range(W):
        board = WALL[(x // 3 + (x // 3) * 7 // 5) % len(WALL)]
        for y in range(H):
            img[y, x] = board * (0.92 + 0.16 * rng.random())
        if x % 3 == 0:
            img[:, x] = SEAM * (0.9 + 0.2 * rng.random())
    # The floor and the dark under the ceiling.
    img[FLOOR_ROW - 1:] = FLOOR * (0.9 + 0.2 * rng.random((H - FLOOR_ROW + 1, W, 1)))
    img[:4] *= 0.6
    # Ceiling beams: two squares deep, the lower row lit by the lamp below.
    for by in BEAMS:
        for x in range(W):
            img[by, x] = BEAM * (0.85 + 0.25 * rng.random())
            img[by + 1, x] = BEAM_LIT * (0.8 + 0.3 * rng.random())
    # The lamp's glow on everything round it, falling off in steps.
    ly, lx = LAMP_AT
    ys, xs = np.mgrid[0:H, 0:W]
    d = np.hypot((ys - ly) * 0.9, xs - lx)
    gain = 1.0 + 1.1 * np.clip(1.0 - d / 14.0, 0.0, 1.0) ** 1.5
    gain = np.floor(gain * 6.0) / 6.0
    img *= gain[..., None]
    # The lamp: a chain from the beam, a small lit chimney.
    for y in range(BEAMS[1] + 2, ly - 1):
        img[y, lx] = np.array([70, 44, 24], float)
    for dy in range(-1, 2):
        for dx in range(-1, 1):
            img[ly + dy, lx + dx] = LAMP[0] if dy == 0 else LAMP[1]
    img[ly + 2, lx - 1:lx + 1] = LAMP[2]
    # A man in a hat, dark against the lamplit wall, a warm rim down his side toward the lamp.
    # Half widths row by row from his hat down (16 squares a metre: 1.8 m tall, his feet on the
    # floor).
    shape = [3, 1, 1, 1, 1, 1, 0, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]
    top = FLOOR_ROW - 1 - len(shape)
    for k, half in enumerate(shape):
        y = top + k
        for x in range(MAN_AT - half, MAN_AT + half + 1):
            img[y, x] = MAN * (0.9 + 0.2 * rng.random())
        if k >= 7:  # his coat's edge, not his head
            img[y, MAN_AT - half] = RIM * (0.8 + 0.3 * rng.random())
    return np.clip(img, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    img = room(np.random.default_rng(1881))
    Image.fromarray(img).save(OUT / "doorway_room.png")
    print(f"doorway_room: {W}x{H} -> assets/textures/drawn/doorway_room.png")
    if args.sheet:
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(img).resize((W * 10, H * 10), Image.NEAREST).save(SHEET)


if __name__ == "__main__":
    main()
