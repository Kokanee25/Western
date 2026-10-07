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

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures"
SHEET = ROOT / "docs/screenshots/textures/letter_sign.png"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"

# id: text, squares across x down, letter height in squares, letters' width stretch, the plank
# height in squares, the boards' colours (`ground`), the letters' (`ink`), and whether a line runs
# round the board. The saloon's is a cream board in red; the rest are lettered straight onto a
# front's grey boards in near-black, as the painting's GENERAL STORE is.
SIGNS = {
    "sign_saloon_drawn": {"text": "SALOON", "size": [100, 34], "cap": 22, "stretch": 1.0, "plank": 5, "track": 0.1,
                          "ground": "cream", "ink": "red", "line": True, "font": "pixel", "track_squares": 1},
    "sign_general_store_drawn": {"text": "GENERAL STORE", "size": [150, 26], "cap": 15, "stretch": 0.8, "plank": 6,
                                 "track": 0.08, "ground": "grey", "ink": "black", "line": False, "font": "pixel", "decal": (38, 32, 30), "track_squares": 2},
    "sign_barber_drawn": {"text": "BARBER", "size": [84, 22], "cap": 13, "stretch": 0.9, "plank": 6, "track": 0.1,
                          "ground": "grey", "ink": "black", "line": True, "font": "pixel", "decal": (38, 32, 30), "track_squares": 2},
    "sign_hotel_drawn": {"text": "HOTEL", "size": [80, 24], "cap": 15, "stretch": 0.95, "plank": 6, "track": 0.14,
                         "ground": "grey", "ink": "black", "line": True, "font": "pixel", "decal": (38, 32, 30), "track_squares": 2},
    # The jail's: big dark letters straight on its whitewashed boards, no line round them (the painting's).
    # `decal`: also written as the ink alone (<id>_ink.png, alpha where there's no letter), one flat
    # dark tone, so FacadeArt paints it straight onto the front's own boards: no board of its own
    # standing out as a patch, the letters' edges a clean step against the wall.
    "sign_jail_drawn": {"text": "JAIL", "size": [60, 22], "cap": 16, "stretch": 1.0, "plank": 6, "track": 0.16,
                        "ground": "whitewash", "ink": "black", "line": False, "decal": (38, 32, 30),
                        "font": "pixel", "track_squares": 4},
    "sign_telegraph_drawn": {"text": "TELEGRAPH", "size": [100, 22], "cap": 13, "stretch": 1.0, "plank": 6, "track": 0.1,
                             "ground": "grey", "ink": "black", "line": False, "font": "pixel", "decal": (38, 32, 30),
                             "track_squares": 2},
    "sign_doctor_drawn": {"text": "DOCTOR", "size": [80, 22], "cap": 14, "stretch": 1.0, "plank": 6, "track": 0.1,
                          "ground": "grey", "ink": "black", "line": True, "font": "pixel", "decal": (38, 32, 30),
                          "track_squares": 2},
    "sign_bank_drawn": {"text": "BANK", "size": [60, 24], "cap": 17, "stretch": 1.0, "plank": 6, "track": 0.1,
                        "ground": "grey", "ink": "black", "line": False, "font": "pixel", "decal": (236, 224, 196),
                        "track_squares": 3},
    "sign_assay_office_drawn": {"text": "ASSAY OFFICE", "size": [120, 22], "cap": 12, "stretch": 0.8, "plank": 6,
                                "track": 0.08, "ground": "grey", "ink": "black", "line": False, "font": "pixel", "decal": (38, 32, 30), "track_squares": 2},
}

GROUNDS = {
    "cream": [(214, 196, 158), (205, 186, 148), (222, 206, 170), (196, 178, 140), (186, 168, 132), (228, 212, 178)],
    "grey": [(178, 168, 150), (166, 156, 138), (190, 180, 160), (152, 142, 126), (138, 128, 114), (202, 192, 172)],
    # The jail's whitewash (draw_boards.py's jail_boards palette).
    "whitewash": [(212, 204, 185), (224, 215, 180), (191, 186, 176), (232, 223, 195), (164, 161, 175), (241, 241, 216)],
}
GROUND_W = [0.26, 0.22, 0.16, 0.16, 0.1, 0.1]
SEAMS = {"cream": (150, 132, 100), "grey": (112, 104, 92), "whitewash": (150, 146, 140)}
INKS = {
    "red": [(132, 34, 28), (118, 28, 24), (146, 42, 32), (104, 24, 22)],
    "black": [(52, 40, 32), (44, 34, 28), (62, 48, 38), (36, 28, 22)],
}
INK_W = [0.82, 0.1, 0.08, 0.0]  # nearly one flat ink: speckled letters read soft
LINES = {"red": (150, 52, 40), "black": (70, 56, 44)}


def letters(spec: dict) -> np.ndarray:
    """A mask of the text, `cap` squares tall, centred on the board. `"font": "pixel"`: set in the
    town's hand-drawn alphabet (tools/textures/pixel_font.py, its own height), not a computer font
    shrunk to the squares."""
    w, h = spec["size"]
    if spec.get("font") == "pixel":
        import pixel_font
        m = pixel_font.text_mask(spec["text"], spec.get("track_squares", 3), spec["cap"])
        out = np.zeros((h, w), bool)
        x0 = (w - m.shape[1]) // 2
        y0 = (h - m.shape[0]) // 2
        out[y0:y0 + m.shape[0], x0:x0 + m.shape[1]] = m
        return out
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
    tw = min(tw, w - (16 if spec["line"] else 8))
    # Down to the squares in two steps (a box filter, then a threshold): each square is in the
    # letter when most of it is.
    small = img.resize((tw * big, cap * big), Image.LANCZOS).resize((tw, cap), Image.BOX)
    m = np.asarray(small) > 72
    out = np.zeros((h, w), bool)
    x0 = (w - tw) // 2
    y0 = (h - cap) // 2
    out[y0:y0 + cap, x0:x0 + tw] = m
    return out


def fit(spec: dict) -> dict:
    """The board widened, if need be, to hold the text set in the town's alphabet at its height."""
    if spec.get("font") != "pixel":
        return spec
    import pixel_font
    m = pixel_font.text_mask(spec["text"], spec.get("track_squares", 3), spec["cap"])
    w, h = spec["size"]
    need = m.shape[1] + (16 if spec["line"] else 8)
    return dict(spec, size=[max(w, need), max(h, m.shape[0] + (10 if spec["line"] else 6))])


def board(spec: dict, rng: np.random.Generator) -> np.ndarray:
    w, h = spec["size"]
    ground = GROUNDS[spec["ground"]]
    pick = rng.choice(len(ground), size=(h, w), p=GROUND_W)
    # Runs along the grain: a square often takes the colour of the one before it.
    for y in range(h):
        for x in range(1, w):
            if rng.random() < 0.35:
                pick[y, x] = pick[y, x - 1]
    img = np.array(ground, float)[pick]
    # Each plank its own shade; a dark seam row between planks.
    plank = spec["plank"]
    for y0 in range(0, h, plank):
        img[y0:y0 + plank] *= 0.94 + 0.1 * rng.random()
        if y0 > 0:
            img[y0] = img[y0] * 0.55 + np.array(SEAMS[spec["ground"]]) * 0.45
    return img


def draw(spec: dict, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    img = board(spec, rng)
    w, h = spec["size"]
    line = LINES[spec["ink"]]
    if spec["line"]:
        # A line round the board, two squares in, and a small stepped hook in each corner.
        for x in range(2, w - 2):
            for y in (2, h - 3):
                img[y, x] = line
        for y in range(2, h - 2):
            for x in (2, w - 3):
                img[y, x] = line
        hook = [(0, 0), (1, 0), (0, 1), (2, 1), (1, 2), (2, 2)]
        for cx, cy, sx, sy in ((4, 4, 1, 1), (w - 5, 4, -1, 1), (4, h - 5, 1, -1), (w - 5, h - 5, -1, -1)):
            for dx, dy in hook:
                img[cy + dy * sy, cx + dx * sx] = line
    mask = letters(spec)
    ink = INKS[spec["ink"]]
    inks = np.array(ink, float)[rng.choice(len(ink), size=(h, w), p=INK_W)]
    img[mask] = inks[mask]
    return np.clip(img, 0, 255).astype(np.uint8)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    made = []
    index_path = OUT / "drawn_signs.json"
    index = {}
    for i, (key, spec) in enumerate(SIGNS.items()):
        spec = fit(spec)
        data = draw(spec, 4171 + i)
        Image.fromarray(data).save(OUT / f"{key}.png")
        index[key] = {"text": spec["text"], "squares": spec["size"]}
        if "decal" in spec:
            mask = letters(spec)
            if spec["line"]:
                w, h = spec["size"]
                mask[2, 2:w - 2] = mask[h - 3, 2:w - 2] = True
                mask[2:h - 2, 2] = mask[2:h - 2, w - 3] = True
            ink = np.zeros(mask.shape + (4,), np.uint8)
            ink[mask] = list(spec["decal"]) + [255]
            Image.fromarray(ink, "RGBA").save(OUT / f"{key}_ink.png")
            index[key]["ink"] = f"{key}_ink"
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
