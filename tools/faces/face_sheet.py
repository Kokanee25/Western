#!/usr/bin/env python3
"""His expression sheet from the face lab's renders (tools/faces/face_lab.gd, the game's materials).

    python3 tools/faces/face_sheet.py --out=bold_cowboy_talking --lab=build/faces/lab \
        [--game2=build/faces/lab_g2 --game5=build/faces/lab_g5]
→ docs/style_test/<out>_expressions.jpg: each expression front and three-quarter, then (if given)
a row at the game's own size (1920x1080, 75° view, 2 m and 5 m), each screen pixel shown 3x.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CELL = 260
F = lambda n, b=True: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""), n)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    out, lab = a.get("--out", "bold_cowboy_talking"), a.get("--lab", "build/faces/lab")
    names = ["rest", "jaw_open", "aa", "ee", "oo", "fv", "mbp", "blink_l", "blink_r", "squint",
             "brows_up", "brows_down", "scowl", "smile", "smile_l", "smile_r"]
    names = [n for n in names if os.path.exists(os.path.join(lab, n + "_0.png"))]
    cols = 4
    rows = (len(names) + cols - 1) // cols
    game = [(d, k) for d, k in ((a.get("--game2"), 2), (a.get("--game5"), 5)) if d]
    gh = sum(6 * (40 if k == 2 else 20) + 30 for _, k in game) + 20
    sheet = Image.new("RGB", (cols * 2 * CELL + 20, 60 + rows * (CELL + 30) + gh), (236, 232, 224))
    dr = ImageDraw.Draw(sheet)
    dr.text((12, 10), "%s: his expressions as the game draws him (front, three-quarter; plain light)" % out,
            fill=(20, 20, 20), font=F(22))
    dr.text((12, 38), "MakeHuman's face pose units (CC0) on his Rodin head, his paint kept. Each at full strength.",
            fill=(70, 70, 70), font=F(15, False))
    for i, e in enumerate(names):
        x, y = 10 + (i % cols) * 2 * CELL, 60 + (i // cols) * (CELL + 30)
        for j, t in enumerate((0, -40)):
            p = os.path.join(lab, "%s_%d.png" % (e, t))
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                s = im.width
                sheet.paste(im.crop((s * 0.06, 0, s * 0.94, s * 0.88)).resize((CELL, CELL), Image.LANCZOS),
                            (x + j * CELL, y))
        dr.text((x + 6, y + CELL + 4), e, fill=(20, 20, 20), font=F(17))
    y = 60 + rows * (CELL + 30) + 8
    for d, dist in game:
        dr.text((12, y), "At game size, %d m (1080p, 75°): each screen pixel shown 3x" % dist, fill=(20, 20, 20), font=F(16))
        y += 24
        x = 10
        half = 40 if dist == 2 else 20
        cell = 6 * half
        for e in ("rest", "jaw_open", "ee", "oo", "blink_l", "brows_up", "scowl", "smile"):
            p = os.path.join(d, e + "_0.png")
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGB")
            c = (960, 530 if dist == 2 else 535)
            box = (c[0] - half, c[1] - half, c[0] + half, c[1] + half)
            sheet.paste(im.crop(box).resize((cell, cell), Image.NEAREST), (x, y))
            dr.text((x + 4, y + 2), e, fill=(255, 255, 255), font=F(13))
            x += cell + 8
        y += cell + 4
    path = os.path.join(ROOT, "docs", "style_test", out + "_expressions.jpg")
    sheet.save(path, quality=90)
    sheet.resize((sheet.width // 2, sheet.height // 2), Image.LANCZOS).save(os.path.join(lab, "sheet_small.jpg"), quality=85)
    print("face_sheet: wrote", path)


if __name__ == "__main__":
    main()
