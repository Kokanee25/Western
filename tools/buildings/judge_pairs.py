#!/usr/bin/env python3
"""The building lab's step 5: each of the target sheet's views beside the game's render of it (the
doctor's: experiments/building_lab/doctor/render_valley.gd), for the blind critic and Sean. Writes
OUT/pair_<view>.jpg (the target left, the render right, each 900 px wide) and OUT/pairs.jpg (all of
them down one sheet, the views' titles over them).

    python3 tools/buildings/judge_pairs.py experiments/building_lab/doctor/sheet build/doctor_renders OUT
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

W = 900


def font(size):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "DejaVuSans-Bold.ttf"):
        try:
            return ImageFont.truetype(f, size)
        except OSError:
            pass
    return ImageFont.load_default()


def fit(im, w=W):
    return im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)


def main(sheet_dir, renders, out):
    os.makedirs(out, exist_ok=True)
    req = json.load(open(os.path.join(sheet_dir, "request.json")))
    rows = []
    for v in req["views"]:
        target = os.path.join(sheet_dir, "panels", v["id"] + ".jpg")
        render = os.path.join(renders, v["id"] + ".png")
        if not (os.path.exists(target) and os.path.exists(render)):
            continue
        a, b = fit(Image.open(target).convert("RGB")), fit(Image.open(render).convert("RGB"))
        h = max(a.height, b.height)
        pair = Image.new("RGB", (W * 2 + 10, h), (20, 20, 20))
        pair.paste(a, (0, 0))
        pair.paste(b, (W + 10, 0))
        pair.save(os.path.join(out, "pair_%s.jpg" % v["id"]), quality=88)
        rows.append((v.get("title", v["id"]), pair))
    if not rows:
        sys.exit("no pairs")
    head = 40
    H = sum(p.height + head for _, p in rows)
    sheet = Image.new("RGB", (W * 2 + 10, H), (236, 232, 222))
    d = ImageDraw.Draw(sheet)
    y = 0
    for title, p in rows:
        d.text((8, y + 8), "%s: the target (left), the game (right)" % title, fill=(25, 20, 15), font=font(22))
        sheet.paste(p, (0, y + head))
        y += p.height + head
    sheet.save(os.path.join(out, "pairs.jpg"), quality=86)
    print(os.path.join(out, "pairs.jpg"), len(rows), "pairs")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
