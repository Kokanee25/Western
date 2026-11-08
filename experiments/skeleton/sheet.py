"""The fuller skeleton's sheet (issue #696): before | after stills of MetaHuman Sean from sk_film's
frames, beside his MetaHuman thumbnail and a real capture of a surrender (CMU 79_74, the Character
Studio's plot of it).

    python3 experiments/skeleton/sheet.py FRAMES_DIR OUT.jpg [--thumb=PNG] [--capture=JPG]

Rows: his shoulders at rest (front, three-quarter, side); his hands up (front, side,
three-quarter: the last frame); aim and reach (the last frame); the wrist turned each way and his
hand on the revolver. Each cell is before (left) then after (right).
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

CELL = 300
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def opt(name, default=None):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def frame(src, shot, which, k=-1):
    d = os.path.join(src, "%s_%s" % (shot, which))
    names = sorted(os.listdir(d))
    return Image.open(os.path.join(d, names[k])).convert("RGB")


def label(im, text):
    dr = ImageDraw.Draw(im)
    f = ImageFont.truetype(FONT, 15)
    w = dr.textlength(text, font=f)
    dr.rectangle([0, 0, w + 10, 22], fill=(0, 0, 0))
    dr.text((5, 3), text, fill=(255, 255, 255), font=f)
    return im


def cell(im, text):
    return label(im.resize((CELL, CELL)), text)


def main():
    src, out = sys.argv[1], sys.argv[2]
    rows = []
    thumb = opt("thumb")
    rest = []
    if thumb:
        rest.append(cell(Image.open(thumb).convert("RGB"), "MetaHuman thumbnail"))
    for v in ("front", "three", "side"):
        for which, t in (("old", "before"), ("new", "after")):
            rest.append(cell(frame(src, "rest_" + v, which), "at rest, %s: %s" % (v, t)))
    rows.append(rest)
    hu = []
    for v in ("front", "side", "three"):
        for which, t in (("old", "before"), ("new", "after")):
            hu.append(cell(frame(src, "handsup_" + v, which), "hands up, %s: %s" % (v, t)))
    rows.append(hu)
    cap = opt("capture")
    more = []
    if cap:
        c = Image.open(cap).convert("RGB")
        # The Studio sheet's right quarter: CMU 79_74, the capture (front and side).
        w, h = c.size
        more.append(cell(c.crop((w * 3 // 4, 0, w, h)), "real capture: CMU 79_74"))
    for shot, k, text in (("aim_front", -1, "aim, front"), ("aim_three", -1, "aim, three-quarter"),
                          ("reach_three", -1, "reach, three-quarter")):
        for which, t in (("old", "before"), ("new", "after")):
            more.append(cell(frame(src, shot, which, k), "%s: %s" % (text, t)))
    rows.append(more)
    last = []
    for shot, k, text in (("reach_side", -1, "reach, side"), ("wrist", 42, "hand rolled +80"),
                          ("wrist", 117, "hand rolled -80"), ("grip", -1, "the revolver")):
        for which, t in (("old", "before"), ("new", "after")):
            last.append(cell(frame(src, shot, which, k), "%s: %s" % (text, t)))
    rows.append(last)
    width = max(len(r) for r in rows) * CELL
    sheet = Image.new("RGB", (width, CELL * len(rows)), (24, 24, 24))
    for y, r in enumerate(rows):
        for x, im in enumerate(r):
            sheet.paste(im, (x * CELL, y * CELL))
    sheet.save(out, quality=88)
    print(out, sheet.size)


if __name__ == "__main__":
    main()
