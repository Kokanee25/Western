"""The UV portrait's painted-face sheet (Sean's checkpoint 3): what was painted and how he looks.

    python3 tools/characters/uv_sheet.py --man=bold_cowboy --take=r1_b --out=JPG \\
        --game=PNG[,PNG...]   # rodin_sheet.py's game sheets (smooth, faceted), stacked under it

Top: his bold portrait | the take's face painting | the face patch squared (the texture as it
goes on him) | the other takes' face paintings, small. Then each game sheet as given.
"""
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BG = (22, 20, 18)
INK = (235, 225, 205)
H = 700


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=BG)
    d.text((4, 2), text, fill=INK)
    return im


def at_height(im, h):
    return im.resize((max(1, int(im.width * h / im.height)), h), Image.LANCZOS)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man, take = a.get("--man", "bold_cowboy"), a["--take"]
    paint = os.path.join(ROOT, "docs", "style_test", "uv", man, "paint")
    work = os.path.join(ROOT, "build", "uv_head")
    import json
    rect = json.load(open(os.path.join(work, man + "_layout.json")))["rects"]["face"]
    x, y, w, h = rect
    tex = Image.open(os.path.join(work, "%s_%s_tex.png" % (man, take))).convert("RGB").crop((x, y, x + w, y + h))
    top = [label(at_height(Image.open(os.path.join(ROOT, "docs", "concept", "style", "portrait-cowboy-front.png")).convert("RGB"), H), "bold portrait"),
           label(at_height(Image.open(os.path.join(paint, take + "_face.png")).convert("RGB"), H), "take %s: the face painting" % take),
           label(tex.resize((int(w * H / h), H), Image.NEAREST), "the face patch squared (8 mm)")]
    others = sorted(f[:-9] for f in os.listdir(paint) if f.endswith("_face.png") and not f.startswith(take + "_"))
    small = [label(at_height(Image.open(os.path.join(paint, o + "_face.png")).convert("RGB"), H // 2), "take " + o) for o in others]
    rows = [top]
    if small:
        rows.append(small)
    for g in (a.get("--game") or "").split(","):
        if g:
            rows.append([Image.open(g).convert("RGB")])
    W = max(sum(c.width for c in r) + 10 * len(r) for r in rows)
    Ht = sum(max(c.height for c in r) + 10 for r in rows)
    sheet = Image.new("RGB", (W, Ht), BG)
    yy = 0
    for r in rows:
        xx = 0
        for c in r:
            sheet.paste(c, (xx, yy))
            xx += c.width + 10
        yy += max(c.height for c in r) + 10
    sheet.save(a["--out"], quality=88)
    print("wrote", a["--out"], sheet.size)


if __name__ == "__main__":
    main()
