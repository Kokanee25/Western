#!/usr/bin/env python3
"""The Studio men's sheet: the style reference every material is painted to (roadmap 1.4a, Sean
2026-10-21: "the Studio's men (bold_cowboy_s0, old_rancher_s1, young_drifter_s1) are the style
reference for every material"). Their source pictures aren't in the repo, so the sheet is made of
the men themselves: the three standing in the game's noon light (cut out of the material lab's
`men` view by its masks, on a plain ground), and below them patches of their own painted cloth
from their textures (vest, trousers, shirt), at the textures' resolution.

    python3 tools/textures/men_reference.py --lab=LABDIR/<material> [--out=docs/concept/targets/9_studio_men.png]

LABDIR is tools/material_lab.gd's output (its noon_men.png and masks). paint_woods.py and
paint_textures.py --style=man send this sheet as their second picture.
"""
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "docs", "concept", "targets", "9_studio_men.png")
MEN = ["bold_cowboy_s0", "old_rancher_s1", "young_drifter_s1"]
# Patches of each man's painted cloth in his 2048 texture (picked by eye clear of the atlas's
# padding): the bold cowboy's brocade vest and trousers, the rancher's leather vest and blue shirt,
# the drifter's pinstripe trousers and brown vest.
CLOTH = {
    "bold_cowboy_s0": [(600, 60, 1060, 420), (700, 620, 1160, 1180)],
    "old_rancher_s1": [(720, 900, 1120, 1250), (1460, 190, 1760, 420)],
    "young_drifter_s1": [(260, 620, 640, 1080), (1090, 700, 1420, 1000)],
}
GROUND = (128, 122, 114)


def men_row(lab, height=760):
    """The three men in the noon men view, each cut out by his mask onto a plain ground."""
    img = np.asarray(Image.open(os.path.join(lab, "noon_men.png")).convert("RGB"))
    cuts = []
    for i in range(3):
        m = np.asarray(Image.open(os.path.join(lab, "men_mask%d.png" % i)).convert("L")) > 127
        ys, xs = np.nonzero(m)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        piece = np.where(m[y0:y1, x0:x1, None], img[y0:y1, x0:x1], np.array(GROUND, np.uint8))
        p = Image.fromarray(piece.astype(np.uint8))
        s = height / p.height
        cuts.append(p.resize((max(1, round(p.width * s)), height), Image.LANCZOS))
    w = sum(c.width for c in cuts) + 40 * (len(cuts) + 1)
    row = Image.new("RGB", (w, height + 40), GROUND)
    x = 40
    for c in cuts:
        row.paste(c, (x, 20))
        x += c.width + 40
    return row


def cloth_row(size=340):
    patches = []
    for m in MEN:
        im = Image.open(os.path.join(ROOT, "assets", "people", "%s_skin.png" % m)).convert("RGB")
        for box in CLOTH[m]:
            p = im.crop(box)
            p.thumbnail((size, size), Image.LANCZOS)
            patches.append(p)
    row = Image.new("RGB", (sum(p.width for p in patches) + 20 * (len(patches) + 1), size + 40), GROUND)
    x = 20
    for p in patches:
        row.paste(p, (x, 20))
        x += p.width + 20
    return row


def main():
    opt = {a.split("=", 1)[0][2:]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    if "lab" not in opt:
        print(__doc__)
        return
    top, bottom = men_row(opt["lab"]), cloth_row()
    w = max(top.width, bottom.width)
    bottom = bottom.resize((w, round(bottom.height * w / bottom.width)), Image.LANCZOS)
    sheet = Image.new("RGB", (w, top.height + bottom.height), GROUND)
    sheet.paste(top, ((w - top.width) // 2, 0))
    sheet.paste(bottom, (0, top.height))
    out = opt.get("out", OUT)
    sheet.save(out)
    print("saved", out, sheet.size)


if __name__ == "__main__":
    main()
