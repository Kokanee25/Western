"""Harlan's arms on the guns (#890): the sheet for Sean from `gun_arms`'s frames.

    python3 experiments/gun_lab/arms_sheet.py DAY_DIR NIGHT_DIR OUT_DIR [--before=PLAIN_OLD --after=PLAIN_NEW]

One sheet a gun (`arms_<gun>.jpg`): idle, aimed, cocked or the lever thrown, reloading; by day (16:00
on Main Street) above, by lamplight (21:30 on the saloon's porch) below. With --before/--after (the
lab's plain views, `views.gd --arms=painted` and without), `arms_before_after.jpg`: the painted hand
above, his below, on the Colt and the Winchester from their right.
"""
import os
import sys

from PIL import Image, ImageDraw

STATES = [("idle", "idle"), ("aimed", "aimed"), ("cocked", "cocked / lever thrown"), ("reloading", "reloading")]
W = 640


def _label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 8 + 7 * len(text), 18], fill=(0, 0, 0))
    d.text((4, 3), text, fill=(255, 255, 255))
    return im


def _cell(path, text):
    im = Image.open(path).convert("RGB")
    im = im.resize((W, int(im.height * W / im.width)), Image.LANCZOS)
    return _label(im, text)


def gun_sheet(day, night, out, gun):
    rows = []
    for d, when in ((day, "day 16:00"), (night, "lamplight 21:30")):
        rows.append([_cell(os.path.join(d, "arms_%s_%s.png" % (gun, s)), "%s, %s" % (t, when)) for s, t in STATES])
    h = rows[0][0].height
    sheet = Image.new("RGB", (W * 4, h * 2))
    for r, row in enumerate(rows):
        for c, im in enumerate(row):
            sheet.paste(im, (c * W, r * h))
    p = os.path.join(out, "arms_%s.jpg" % gun)
    sheet.save(p, quality=85)
    return p


def before_after(old, new, out):
    names = [("revolver_detail_right", "Colt, from its right"), ("revolver_detail_left", "Colt, from its left"),
             ("winchester_detail_right", "Winchester, from its right"), ("winchester_aim", "Winchester, aimed")]
    cells = [[_cell(os.path.join(d, n + ".png"), "%s: %s" % (who, t)) for n, t in names]
             for d, who in ((old, "painted (before)"), (new, "MetaHuman (now)"))]
    h = cells[0][0].height
    sheet = Image.new("RGB", (W * 4, h * 2))
    for r, row in enumerate(cells):
        for c, im in enumerate(row):
            sheet.paste(im, (c * W, r * h))
    p = os.path.join(out, "arms_before_after.jpg")
    sheet.save(p, quality=85)
    return p


def main():
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    opt = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--"))
    day, night, out = a
    os.makedirs(out, exist_ok=True)
    for gun in ("revolver", "winchester"):
        print(gun_sheet(day, night, out, gun))
    if "before" in opt and "after" in opt:
        print(before_after(opt["before"], opt["after"], out))


if __name__ == "__main__":
    main()
