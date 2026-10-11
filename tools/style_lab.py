#!/usr/bin/env python3
"""The style lab's boards (docs/briefs/style-lab.md) from tools/style_lab.sh's renders.

    python3 tools/style_lab.py boards [--from=build/style_lab] [--out=docs/screenshots/style_lab]

One board a scene, a row a candidate (A today, B painted squares under smooth light, C restrained
realism), the same crops in each row: characters (the two men, whole, in daylight, lamplight and
golden hour), heads, props, the saloon corner, the façade, the Kid in the street, the camera path.
Each is written twice: named (<scene>.jpg) and blind (blind/<scene>.jpg: the rows in a seeded
shuffle, named X, Y, Z, the same order on every board; the key in build/style_lab/blind_key.json,
not beside the boards, so a critic given only blind/ can't read it).
"""
import json
import os
import random
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import judge  # noqa: E402  (its font)

NAMES = {"a": "A: today", "b": "B: painted squares, smooth light", "c": "C: restrained realism"}
BG = (22, 22, 22)
ROW_H = 300


def trim(img, pad=6):
    """Cropped round what isn't the background (the top-left pixel's colour)."""
    a = img.convert("RGB")
    bg = a.getpixel((2, 2))
    mask = Image.eval(a.convert("L"), lambda v: 0)
    px = a.load()
    w, h = a.size
    m = mask.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            p = px[x, y]
            if abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) > 24:
                m[x, y] = 255
    box = mask.getbbox() or (0, 0, w, h)
    return a.crop((max(box[0] - pad, 0), max(box[1] - pad, 0), min(box[2] + pad, w), min(box[3] + pad, h)))


def fit_h(img, h):
    return img.resize((max(int(img.width * h / img.height), 1), h), Image.LANCZOS)


def label(img, words, size=16):
    out = Image.new("RGB", (img.width, img.height + size + 8), BG)
    out.paste(img, (0, size + 8))
    ImageDraw.Draw(out).text((4, 2), words, fill=(235, 225, 205), font=judge._font(size))
    return out


def row(images, gap=6):
    images = [i for i in images if i is not None]
    if not images:
        return Image.new("RGB", (1, 1), BG)
    out = Image.new("RGB", (sum(i.width for i in images) + gap * (len(images) - 1), max(i.height for i in images)), BG)
    x = 0
    for i in images:
        out.paste(i, (x, 0))
        x += i.width + gap
    return out


def column(images, gap=12):
    images = [i for i in images if i is not None and i.width > 1]
    out = Image.new("RGB", (max(i.width for i in images), sum(i.height for i in images) + gap * (len(images) - 1)), BG)
    y = 0
    for i in images:
        out.paste(i, (0, y))
        y += i.height + gap
    return out


def load(d, *parts):
    p = os.path.join(d, *parts)
    return Image.open(p).convert("RGB") if os.path.exists(p) else None


def crop2x(img, box):
    if img is None:
        return None
    img = img.resize((1280, 720), Image.LANCZOS) if img.size != (1280, 720) else img
    c = img.crop(box)
    return c.resize((c.width * 2, c.height * 2), Image.NEAREST)


def scene_rows(d):
    """Each scene's images for one candidate's folder, in board order."""
    s = {}
    s["characters"] = [fit_h(trim(i), ROW_H) for i in (
        load(d, "lineup_day", "stand_front.png"), load(d, "lineup_day", "stand_three_quarter_back.png"),
        load(d, "lineup_lamp", "stand_three_quarter.png"), load(d, "lineup_golden", "stand_side.png")) if i]
    s["heads"] = [fit_h(i.crop((0, 40, i.width, 440)), ROW_H) for i in (
        load(d, "lineup_day", "head_stand_front.png"), load(d, "lineup_lamp", "head_stand_three_quarter.png"),
        load(d, "lineup_golden", "head_stand_three_quarter.png"), load(d, "lineup_day", "head_stand_back.png")) if i]
    s["props"] = [fit_h(i, ROW_H) for i in (load(d, "props", "props.png"), load(d, "props", "props_close.png")) if i]
    saloon = load(d, "views", "shot_match_saloon.png")
    s["saloon"] = [fit_h(saloon, ROW_H) if saloon else None, crop2x(saloon, (470, 200, 750, 520)),
                   crop2x(saloon, (760, 330, 1080, 600)), crop2x(saloon, (60, 120, 300, 420))]
    s["saloon"] = [fit_h(i, ROW_H) for i in s["saloon"] if i]
    street = load(d, "views", "shot_match_street.png")
    s["facade"] = [fit_h(i, ROW_H) for i in (
        street, crop2x(street, (60, 200, 380, 560)), load(d, "views", "saloon_front_dusk.png"),
        load(d, "views", "wall_closeup_noon.png")) if i]
    s["kid_street"] = [fit_h(i, ROW_H) for i in (load(d, "views", "kid_street.png"), load(d, "views", "kid_close.png")) if i]
    walk = sorted(f for f in os.listdir(os.path.join(d, "walk")) if f.endswith(".png")) if os.path.isdir(os.path.join(d, "walk")) else []
    picks = [walk[int(i * (len(walk) - 1) / 4)] for i in range(5)] if len(walk) >= 5 else walk
    s["walk"] = [fit_h(load(d, "walk", f), 220) for f in picks]
    return s


def main():
    opt = {a.split("=")[0]: a.split("=", 1)[1] for a in sys.argv[1:] if "=" in a}
    src = os.path.join(ROOT, opt.get("--from", "build/style_lab"))
    out = os.path.join(ROOT, opt.get("--out", "docs/screenshots/style_lab"))
    os.makedirs(os.path.join(out, "blind"), exist_ok=True)
    cands = [c for c in ("a", "b", "c") if os.path.isdir(os.path.join(src, c))]
    rows = {c: scene_rows(os.path.join(src, c)) for c in cands}
    order = cands[:]
    random.Random(1882).shuffle(order)
    key = {"XYZ"[i]: c for i, c in enumerate(order)}
    json.dump(key, open(os.path.join(src, "blind_key.json"), "w"), indent=1)
    for scene in rows[cands[0]]:
        named = column([label(row(rows[c][scene]), NAMES[c]) for c in cands])
        named.save(os.path.join(out, scene + ".jpg"), quality=88)
        blind = column([label(row(rows[c][scene]), "candidate " + x) for x, c in key.items()])
        blind.save(os.path.join(out, "blind", scene + ".jpg"), quality=88)
        print("wrote", scene, named.size)
    print("blind key in", os.path.relpath(os.path.join(src, "blind_key.json"), ROOT))


if __name__ == "__main__" and "boards" in sys.argv:
    main()
elif __name__ == "__main__":
    print(__doc__)
