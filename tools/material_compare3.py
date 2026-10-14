#!/usr/bin/env python3
"""The timber pass's finish, A/B (art, 2026-10-14; Sean's notes on the timber pass): A the timber
pass's chosen baseline (lab2's woods, LabGeometry `reshape`: 45 mm planks, 30 mm overhang), B the
finish (lab3's woods, LabGeometry `build`: the walk built as lumber, the lowest siding splashed),
both rendered by tools/material_lab.gd from the same cameras and lights.

    python3 tools/material_compare3.py [--a=build/fin_A --b=build/fin_B]
        [--out=docs/screenshots/material_lab/finish]

Writes views_<light>.jpg (each view a row, A | B), closeups_<light>.jpg (the plank ends, a post,
its foot and the siding, nearest-neighbour 2x), and the walk past the fronts (A | B):
build/material_lab_finish_pan.gif.
"""
import glob
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from material_compare2 import column, label, row  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIEWS = ["deck_ends", "deck_end_on", "deck_corner", "steps", "post_close", "post_base", "close", "gameplay", "front"]
# [name, view, box in the 1280x720 render]
CLOSE = [["plank ends", "deck_ends", (320, 200, 960, 520)],
         ["post", "post_close", (480, 140, 800, 460)],
         ["post foot", "post_base", (440, 300, 840, 600)],
         ["siding", "close", (440, 100, 840, 400)]]
NAMES = {"A": "A timber pass", "B": "B finish"}


def main():
    a = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    runs = {"A": a.get("a", "build/fin_A"), "B": a.get("b", "build/fin_B")}
    out = a.get("out", os.path.join(ROOT, "docs", "screenshots", "material_lab", "finish"))
    os.makedirs(out, exist_ok=True)
    load = lambda r, light, v: Image.open(os.path.join(runs[r], "%s_%s.png" % (light, v))).convert("RGB")
    for light in ("noon", "golden", "night"):
        rows = []
        for v in VIEWS:
            if not all(os.path.exists(os.path.join(runs[r], "%s_%s.png" % (light, v))) for r in "AB"):
                continue
            rows.append(row([label(load(r, light, v).resize((640, 360), Image.LANCZOS), "%s · %s" % (NAMES[r], v))
                             for r in "AB"]))
        if rows:
            column(rows).save(os.path.join(out, "views_%s.jpg" % light), quality=88)
        crows = []
        for name, v, box in CLOSE:
            if not all(os.path.exists(os.path.join(runs[r], "%s_%s.png" % (light, v))) for r in "AB"):
                continue
            cells = []
            for r in "AB":
                c = load(r, light, v).crop(box)
                c = c.resize((c.width * 640 // c.width, c.height * 640 // c.width), Image.NEAREST)
                cells.append(label(c, "%s · %s · %s" % (r, name, light)))
            crows.append(row(cells))
        if crows:
            column(crows).save(os.path.join(out, "closeups_%s.jpg" % light), quality=90)
    frames = {r: sorted(glob.glob(os.path.join(runs[r], "pan_golden_*.png"))) for r in "AB"}
    if all(frames.values()):
        n = min(len(f) for f in frames.values())
        ims = [row([label(Image.open(frames[r][k]).convert("RGB").resize((560, 315), Image.LANCZOS), NAMES[r])
                    for r in "AB"], gap=4) for k in range(n)]
        gif = os.path.join(ROOT, "build", "material_lab_finish_pan.gif")
        ims[0].save(gif, save_all=True, append_images=ims[1:] + ims[-2:0:-1], duration=200, loop=0)
        print("gif", gif)
    print("sheets in", out)


if __name__ == "__main__":
    main()
