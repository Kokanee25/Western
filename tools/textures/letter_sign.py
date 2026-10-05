"""Sign boards lettered square by square, as the street painting's are.

The painting's SALOON board is cream planks in big squares (a plank is four or five squares
high), each square a slightly different cream or grey-tan, with deep red letters about eighteen
squares tall and three or four wide in the stroke, slab serifs, a thin red line round the board a
couple of squares in, and a small flourish in each corner. The texture factory's signs are an image
model's lettering cut down to the world's texels, which blurs them; here the letters are set in a
bold serif at the board's own size in squares and each square is coloured from the painting's
cream and red (tools/textures/from_painting.py's palettes), so every letter's edge is a clean step.

    python3 tools/textures/letter_sign.py [--sheet]

Writes assets/textures/<id>.png, one texel a square; FacadeArt lays it once across its board
(SignArt.board_at: the texture's width over the board's width sets the squares' size).
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures"
SHEET = ROOT / "docs/screenshots/textures/letter_sign.png"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"

# id: text, squares across x down, letter height in squares, letters' width stretch, the plank
# height in squares.
SIGNS = {
    "sign_saloon_drawn": {"text": "SALOON", "size": [100, 34], "cap": 23, "stretch": 1.0, "plank": 5, "track": 0.1},
}

CREAM = [(214, 196, 158), (205, 186, 148), (222, 206, 170), (196, 178, 140), (186, 168, 132), (228, 212, 178)]
CREAM_W = [0.26, 0.22, 0.16, 0.16, 0.1, 0.1]
SEAM = (150, 132, 100)
RED = [(132, 34, 28), (118, 28, 24), (146, 42, 32), (104, 24, 22)]
RED_W = [0.4, 0.25, 0.2, 0.15]
LINE = (150, 52, 40)


def letters(spec: dict) -> np.ndarray:
    """A mask of the text, `cap` squares tall, centred on the board."""
    w, h = spec["size"]
    big = 8
    font = ImageFont.truetype(FONT, 400)
    # Set letter by letter with room between them (sign painters spaced their letters wide).
    track = int(400 * spec.get("track", 0.14))
    img = Image.new("L", (400 * (len(spec["text"]) + 2), 700), 0)
    d = ImageDraw.Draw(img)
    x = 40
    for ch in spec["text"]:
        d.text((x, 100), ch, font=font, fill=255)
        x += int(font.getlength(ch)) + track
    img = img.crop(img.getbbox())
    cap = spec["cap"]
    tw = int(round(img.width * cap / img.height * spec["stretch"]))
    tw = min(tw, w - 16)
    # Down to the squares in two steps (a box filter, then a threshold): each square is in the
    # letter when most of it is.
    small = img.resize((tw * big, cap * big), Image.LANCZOS).resize((tw, cap), Image.BOX)
    m = np.asarray(small) > 72
    out = np.zeros((h, w), bool)
    x0 = (w - tw) // 2
    y0 = (h - cap) // 2
    out[y0:y0 + cap, x0:x0 + tw] = m
    return out


def board(spec: dict, rng: np.random.Generator) -> np.ndarray:
    w, h = spec["size"]
    pick = rng.choice(len(CREAM), size=(h, w), p=CREAM_W)
    # Runs along the grain: a square often takes the colour of the one before it.
    for y in range(h):
        for x in range(1, w):
            if rng.random() < 0.35:
                pick[y, x] = pick[y, x - 1]
    img = np.array(CREAM, float)[pick]
    # Each plank its own shade; a dark seam row between planks.
    plank = spec["plank"]
    for y0 in range(0, h, plank):
        img[y0:y0 + plank] *= 0.94 + 0.1 * rng.random()
        if y0 > 0:
            img[y0] = img[y0] * 0.55 + np.array(SEAM) * 0.45
    return img


def draw(spec: dict, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    img = board(spec, rng)
    w, h = spec["size"]
    # The red line round the board, two squares in.
    for x in range(2, w - 2):
        for y in (2, h - 3):
            img[y, x] = LINE
    for y in range(2, h - 2):
        for x in (2, w - 3):
            img[y, x] = LINE
    # A flourish in each corner: a small stepped hook of red squares.
    hook = [(0, 0), (1, 0), (0, 1), (2, 1), (1, 2), (2, 2)]
    for cx, cy, sx, sy in ((4, 4, 1, 1), (w - 5, 4, -1, 1), (4, h - 5, 1, -1), (w - 5, h - 5, -1, -1)):
        for dx, dy in hook:
            img[cy + dy * sy, cx + dx * sx] = LINE
    mask = letters(spec)
    reds = np.array(RED, float)[rng.choice(len(RED), size=(h, w), p=RED_W)]
    img[mask] = reds[mask]
    return np.clip(img, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    made = []
    index_path = OUT / "drawn_signs.json"
    index = {}
    for i, (key, spec) in enumerate(SIGNS.items()):
        data = draw(spec, 4171 + i)
        Image.fromarray(data).save(OUT / f"{key}.png")
        index[key] = {"text": spec["text"], "squares": spec["size"]}
        made.append(data)
        print(f"{key}: {spec['size'][0]}x{spec['size'][1]} squares -> assets/textures/{key}.png")
    index_path.write_text(json.dumps(index, indent=1) + "\n")
    if args.sheet:
        tiles = [Image.fromarray(d).resize((d.shape[1] * 10, d.shape[0] * 10), Image.NEAREST) for d in made]
        sheet = Image.new("RGB", (max(t.width for t in tiles), sum(t.height + 8 for t in tiles)), (20, 20, 20))
        y = 0
        for t in tiles:
            sheet.paste(t, (0, y))
            y += t.height + 8
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(SHEET)


if __name__ == "__main__":
    main()
