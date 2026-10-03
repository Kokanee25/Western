"""The voxel trial's comparison picture (docs/screenshots/voxel_trial/compare.png): each render
next to the concept painting, with close crops of the hat brim, the mug and his eyes at 3x.

    python3 tools/voxel_compare.py --out=docs/screenshots/voxel_trial \\
        base=DIR/shot_match_saloon.png "A props+hat 128"=DIR2/... ...

Each argument is label=path. The painting's face box and ours are fixed (the shot match's framing).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAINTING = os.path.join(ROOT, "docs", "concept", "saloon-night.png")
# Crops of our 1280x720 render: (box, label); the painting's matching boxes in its 1672x941.
CROPS = {
    "hat brim": ((360, 70, 660, 230), (444, 170, 836, 379)),
    "eyes": ((420, 180, 580, 290), (522, 287, 731, 431)),
    "mug": ((540, 460, 660, 580), (731, 614, 862, 745)),
    "lamp": ((850, 300, 990, 600), (1097, 431, 1293, 851)),
}
SCALE = 3


def font(size):
    for f in ["/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/dejavu/DejaVuSans.ttf"]:
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def main():
    out = os.path.join(ROOT, "docs", "screenshots", "voxel_trial")
    renders = []
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = a.split("=", 1)[1]
        elif "=" in a:
            label, path = a.split("=", 1)
            renders.append((label, path))
    os.makedirs(out, exist_ok=True)
    painting = Image.open(PAINTING).convert("RGB")
    pw, ph = painting.size
    small = painting.resize((1280, 720), Image.LANCZOS)
    f = font(22)
    rows = []
    # Row 0: the painting with its crops.
    rows.append(("the painting", small, [painting.crop(b[1]).resize(((b[0][2] - b[0][0]) * SCALE, (b[0][3] - b[0][1]) * SCALE), Image.LANCZOS) for b in CROPS.values()]))
    for label, path in renders:
        im = Image.open(path).convert("RGB")
        crops = [im.crop(b[0]).resize(((b[0][2] - b[0][0]) * SCALE, (b[0][3] - b[0][1]) * SCALE), Image.NEAREST) for b in CROPS.values()]
        rows.append((label, im, crops))
    gap = 12
    crop_w = sum(c.width for c in rows[0][2]) + gap * (len(CROPS) - 1)
    row_h = max(720, max(c.height for c in rows[0][2])) + 36
    W = 1280 + gap + crop_w + gap * 2
    H = row_h * len(rows) + gap
    sheet = Image.new("RGB", (W, H), (24, 24, 24))
    d = ImageDraw.Draw(sheet)
    for r, (label, im, crops) in enumerate(rows):
        y = gap + r * row_h
        d.text((gap, y), label, fill=(240, 230, 210), font=f)
        sheet.paste(im, (gap, y + 30))
        x = gap + 1280 + gap
        for (name, _b), c in zip(CROPS.items(), crops):
            d.text((x, y), name + " x%d" % SCALE, fill=(200, 200, 200), font=f)
            sheet.paste(c, (x, y + 30))
            x += c.width + gap
    sheet.save(os.path.join(out, "compare.png"))
    print("wrote", os.path.join(out, "compare.png"), sheet.size)


if __name__ == "__main__":
    main()
