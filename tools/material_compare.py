#!/usr/bin/env python3
"""The material lab's comparison sheets (art, 2026-10-14): A the master painting's crop, B the
production woods, C the lab's (tools/textures/paint_woods.py), from the same views.

    python3 tools/material_compare.py --prod=build/mat_b --lab=build/mat_c \\
        --lab-prod=build/lab_prod --lab-lab=build/lab_lab --out=docs/screenshots/material_lab

Inputs: tools/facade_lab.gd's renders (the street's saloon at the painting's hour; `near` is framed
as the painter stood) with and without --lab, and tools/material_lab.gd's (the lab set in three
lights, its views and a walk). Writes:
  abc_near.png       A | B | C, the saloon's front as the painting has it
  closeups.png       the same three, each wood's square-by-square close-up (nearest, 3x)
  lights.png         B | C on the lab set: noon, golden hour, lamplit night
  pan_strip.png      the walk past the fronts, six frames (C); pan.gif all of them (in build/)
"""
import glob
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAINTING = os.path.join(ROOT, "docs", "concept", "street-golden-hour.png")
# The painting's saloon as facade_lab's `near` view frames it (pixels of the 1672-wide picture).
NEAR_CROP = (0, 150, 800, 600)
# Close-ups: [name, the painting's box, the render's box (facade_lab `near`, 1280x720)], the same
# shape, each where that wood is nearest and lit alike.
CLOSE = [
    ["red siding", (300, 330, 370, 400), (180, 170, 250, 240)],
    ["timber post", (425, 380, 475, 450), (575, 280, 625, 350)],
    ["boardwalk", (250, 620, 350, 690), (400, 560, 500, 630)],
]


def label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=(0, 0, 0))
    d.text((4, 2), text, fill=(255, 255, 255))
    return img


def fit(img, w):
    return img.resize((w, round(img.height * w / img.width)), Image.LANCZOS)


def row(images, gap=8, bg=(24, 24, 24)):
    h = max(i.height for i in images)
    out = Image.new("RGB", (sum(i.width for i in images) + gap * (len(images) - 1), h), bg)
    x = 0
    for i in images:
        out.paste(i, (x, 0))
        x += i.width + gap
    return out


def column(images, gap=8, bg=(24, 24, 24)):
    w = max(i.width for i in images)
    out = Image.new("RGB", (w, sum(i.height for i in images) + gap * (len(images) - 1)), bg)
    y = 0
    for i in images:
        out.paste(i, (0, y))
        y += i.height + gap
    return out


def main():
    a = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    out = a.get("out", os.path.join(ROOT, "docs", "screenshots", "material_lab"))
    os.makedirs(out, exist_ok=True)
    painting = Image.open(PAINTING).convert("RGB")
    b = Image.open(os.path.join(a["prod"], "facade_near.png")).convert("RGB")
    c = Image.open(os.path.join(a["lab"], "facade_near.png")).convert("RGB")
    w = 620
    sheet = row([label(fit(painting.crop(NEAR_CROP), w), "A  the master painting"),
                 label(fit(b, w), "B  production woods (today)"),
                 label(fit(c, w), "C  lab woods (new)")])
    sheet.save(os.path.join(out, "abc_near.png"))
    # Close-ups, nearest-neighbour: each wood's squares as drawn.
    rows = []
    for name, pbox, rbox in CLOSE:
        z = 3
        pc = painting.crop(pbox)
        pc = pc.resize((pc.width * z * 2, pc.height * z * 2), Image.NEAREST)
        size = pc.size
        bc = b.crop(rbox).resize(size, Image.NEAREST)
        cc = c.crop(rbox).resize(size, Image.NEAREST)
        rows.append(row([label(pc, "A " + name), label(bc, "B"), label(cc, "C")]))
    column(rows).save(os.path.join(out, "closeups.png"))
    # The lab set in three lights, B | C.
    if "lab-prod" in a:
        lrows = []
        for light in ("noon", "golden", "night"):
            for v in ("close", "post", "walk_detail"):
                pb = os.path.join(a["lab-prod"], "%s_%s.png" % (light, v))
                pl = os.path.join(a["lab-lab"], "%s_%s.png" % (light, v))
                if os.path.exists(pb) and os.path.exists(pl):
                    lrows.append(row([label(fit(Image.open(pb).convert("RGB"), 560), "B %s %s" % (light, v)),
                                      label(fit(Image.open(pl).convert("RGB"), 560), "C")]))
        column(lrows).save(os.path.join(out, "lights.png"))
        frames = sorted(glob.glob(os.path.join(a["lab-lab"], "pan_golden_*.png")))
        if frames:
            pick = frames[:: max(1, len(frames) // 6)][:6]
            row([fit(Image.open(f).convert("RGB"), 420) for f in pick], gap=4).save(os.path.join(out, "pan_strip.png"))
            ims = [fit(Image.open(f).convert("RGB"), 640) for f in frames]
            gif = os.path.join(ROOT, "build", "material_lab_pan.gif")
            ims[0].save(gif, save_all=True, append_images=ims[1:] + ims[-2:0:-1], duration=180, loop=0)
            print("gif", gif)
    print("sheets in", out)


if __name__ == "__main__":
    main()
