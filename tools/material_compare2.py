#!/usr/bin/env python3
"""The timber pass's comparison sheets (art, 2026-10-14; docs/briefs/material-lab-timber.md): A
today's woods and geometry, B the lab2 woods on today's geometry (ends flagged), C the lab2 woods
and LabGeometry's reshaping, rendered by tools/material_lab.gd from the same cameras and lights.

    python3 tools/material_compare2.py [--a=build/abc_A --b=build/abc_B --c=build/abc_C]
        [--out=docs/screenshots/material_lab/timber]

Writes views_<light>.png (each view a row: A | B | C), closeups.png (the plank ends, a post and
the siding, nearest-neighbour, 3x), and the walk past the fronts: pan_strip.png (six frames, C)
and build/material_lab_timber_pan.gif (A | B | C side by side, every frame).
"""
import glob
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIEWS = ["deck_end_on", "deck_corner", "deck_top", "post_close", "post_bracket", "close", "gameplay", "front"]
# [name, view, box in the 1280x720 render]
CLOSE = [["plank ends", "deck_end_on", (380, 170, 620, 290)],
         ["deck corner", "deck_corner", (760, 380, 1000, 500)],
         ["post", "post_close", (560, 260, 800, 380)],
         ["siding", "close", (520, 120, 760, 240)]]


def label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return img


def row(images, gap=6, bg=(24, 24, 24)):
    h = max(i.height for i in images)
    out = Image.new("RGB", (sum(i.width for i in images) + gap * (len(images) - 1), h), bg)
    x = 0
    for i in images:
        out.paste(i, (x, 0))
        x += i.width + gap
    return out


def column(images, gap=6, bg=(24, 24, 24)):
    w = max(i.width for i in images)
    out = Image.new("RGB", (w, sum(i.height for i in images) + gap * (len(images) - 1)), bg)
    y = 0
    for i in images:
        out.paste(i, (0, y))
        y += i.height + gap
    return out


def main():
    a = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    runs = {"A": a.get("a", "build/abc_A"), "B": a.get("b", "build/abc_B"), "C": a.get("c", "build/abc_C")}
    names = {"A": "A today", "B": "B new woods", "C": "C new woods + geometry"}
    out = a.get("out", os.path.join(ROOT, "docs", "screenshots", "material_lab", "timber"))
    os.makedirs(out, exist_ok=True)
    load = lambda r, light, v: Image.open(os.path.join(runs[r], "%s_%s.png" % (light, v))).convert("RGB")
    for light in ("noon", "golden", "night"):
        rows = []
        for v in VIEWS:
            if not os.path.exists(os.path.join(runs["A"], "%s_%s.png" % (light, v))):
                continue
            rows.append(row([label(load(r, light, v).resize((480, 270), Image.LANCZOS), "%s · %s" % (names[r], v))
                             for r in "ABC"]))
        column(rows).save(os.path.join(out, "views_%s.jpg" % light), quality=88)
    crows = []
    for light in ("noon", "golden", "night"):
        for name, v, box in CLOSE:
            cells = []
            for r in "ABC":
                c = load(r, light, v).crop(box)
                cells.append(label(c.resize((c.width * 2, c.height * 2), Image.NEAREST), "%s %s %s" % (r, name, light)))
            crows.append(row(cells))
    column(crows).save(os.path.join(out, "closeups.jpg"), quality=90)
    frames = {r: sorted(glob.glob(os.path.join(runs[r], "pan_golden_*.png"))) for r in "ABC"}
    if all(frames.values()):
        n = min(len(f) for f in frames.values())
        pick = frames["C"][:: max(1, n // 6)][:6]
        row([Image.open(f).convert("RGB").resize((420, 236), Image.LANCZOS) for f in pick], gap=4).save(
            os.path.join(out, "pan_strip.jpg"), quality=88)
        ims = [row([label(Image.open(frames[r][k]).convert("RGB").resize((420, 236), Image.LANCZOS), names[r])
                    for r in "ABC"], gap=4) for k in range(n)]
        gif = os.path.join(ROOT, "build", "material_lab_timber_pan.gif")
        ims[0].save(gif, save_all=True, append_images=ims[1:] + ims[-2:0:-1], duration=200, loop=0)
        print("gif", gif)
    print("sheets in", out)


if __name__ == "__main__":
    main()
