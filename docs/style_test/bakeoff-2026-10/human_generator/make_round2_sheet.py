"""Round 2's sheets (#547): each a row of labelled cells, the same man in Blender and in the game.
A cell is LABEL=PATH[@crop], crop "face" (the face shot's middle) or "half" (the half figure's), any
other image whole; a row is its cells joined by '|', rows by ';'. Renders only (the men's files stay
in the private Studio). Blender renders: the Studio's store/humgen/out/renders/ (hg_render.py).

    python3 docs/style_test/bakeoff-2026-10/human_generator/make_round2_sheet.py --out=PATH.jpg \
        --rows="Blender=R/hg_real_rancher_portrait.png|before, saloon=S/a.png@face;..." [--h=360]
"""
import os
import sys
from PIL import Image, ImageDraw

CROPS = {"face": (390, 60, 890, 685), "half": (340, 0, 940, 720)}


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 8 + 6 * len(text), 15), fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return im


def cell(spec, h):
    name, path = spec.split("=", 1)
    crop = None
    if "@" in path:
        path, crop = path.rsplit("@", 1)
    im = Image.open(os.path.expanduser(path)).convert("RGB")
    if crop:
        im = im.crop(CROPS[crop])
    w = round(im.width * h / im.height)
    return label(im.resize((w, h), Image.LANCZOS), name)


def main():
    h = int(opt("h", 360))
    rows = [[cell(c, h) for c in r.split("|")] for r in opt("rows").split(";")]
    width = max(sum(c.width for c in r) for r in rows)
    sheet = Image.new("RGB", (width, h * len(rows)), (20, 20, 20))
    for y, r in enumerate(rows):
        x = 0
        for c in r:
            sheet.paste(c, (x, y * h))
            x += c.width
    sheet.save(opt("out"), quality=88)
    print("wrote", opt("out"), sheet.size)


if __name__ == "__main__":
    main()
