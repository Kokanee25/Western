"""The quantise-once trial's comparison picture (docs/screenshots/quantise_once/compare.png): for
each shot, the painting, the render as now and the render quantised once, each with close crops
at 3x.

    python3 tools/quantise_compare.py --out=docs/screenshots/quantise_once \\
        "as now=DIR_NOW" "quantise once=DIR_Q1" ["pre-blocking off, mosaic as now=DIR"]

Each DIR holds shot_match_saloon.png and/or shot_match_street.png (1280x720).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = {
    "shot_match_saloon": ("docs/concept/saloon-night.png", {
        "face": (400, 160, 600, 300),
        "lamp": (850, 300, 990, 600),
        "far bar": (900, 150, 1280, 400),
    }),
    "shot_match_street": ("docs/concept/street-golden-hour.png", {
        "saloon front": (0, 0, 400, 300),
        "horse and rail": (420, 330, 700, 540),
        "far street": (700, 250, 1000, 450),
    }),
}
SCALE = 3


def font(size):
    for f in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def row_of(label, im, crops, nearest):
    tiles = []
    for name, box in crops.items():
        c = im.crop(box)
        tiles.append((name, c.resize((c.width * SCALE, c.height * SCALE), Image.NEAREST if nearest else Image.LANCZOS)))
    return label, im, tiles


def main():
    out = os.path.join(ROOT, "docs", "screenshots", "quantise_once")
    renders = []
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = a.split("=", 1)[1]
        elif "=" in a:
            label, path = a.split("=", 1)
            renders.append((label, path))
    os.makedirs(out, exist_ok=True)
    f = font(22)
    rows = []
    for shot, (painting_path, crops) in SHOTS.items():
        painting = Image.open(os.path.join(ROOT, painting_path)).convert("RGB").resize((1280, 720), Image.LANCZOS)
        rows.append(row_of("%s: the painting" % shot, painting, crops, False))
        for label, d in renders:
            p = os.path.join(d, shot + ".png")
            if os.path.exists(p):
                rows.append(row_of("%s: %s" % (shot, label), Image.open(p).convert("RGB"), crops, True))
    gap = 12
    crop_w = max(sum(t.width for _n, t in r[2]) + gap * (len(r[2]) - 1) for r in rows)
    row_h = 720 + 36
    W = 1280 + gap + crop_w + gap * 2
    H = row_h * len(rows) + gap
    sheet = Image.new("RGB", (W, H), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    for r, (label, im, tiles) in enumerate(rows):
        y = gap + r * row_h
        d.text((gap, y), label, fill=(240, 230, 210), font=f)
        sheet.paste(im, (gap, y + 30))
        x = gap + 1280 + gap
        for name, t in tiles:
            d.text((x, y), "%s x%d" % (name, SCALE), fill=(200, 200, 200), font=f)
            t = t.crop((0, 0, t.width, min(t.height, 720)))
            sheet.paste(t, (x, y + 30))
            x += t.width + gap
    sheet.save(os.path.join(out, "compare.png"))
    print("wrote", os.path.join(out, "compare.png"), sheet.size)


if __name__ == "__main__":
    main()
