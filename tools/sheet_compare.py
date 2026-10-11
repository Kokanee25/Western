#!/usr/bin/env python3
"""The character-sheet trial's comparison sheets (docs/screenshots/review/2026-10-11_sheet_style_*.png):
the sheet | ours in the same views, crops at 2x (nearest).

    python3 tools/sheet_compare.py [--from=build/sheet_style] [--ours=fine2] [--today=base2]

Reads tools/people_lineup.gd's renders (DIR/<ours>/stand_<view>.png and head_stand_<view>.png,
--sheet-style; DIR/<today>/..., the man as he's made now, in the same light) and
tools/screenshots.gd's (DIR/shots_today, shots_sheet32, shots_sheet16: shot_match_saloon.png and
shot_match_street.png). Writes <name>_man.png and <name>_world.png.
"""
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import judge  # noqa: E402  (its font)

SHEET = os.path.join(ROOT, "docs", "concept", "style_candidates", "character_sheet.png")
OUT = os.path.join(ROOT, "docs", "screenshots", "review", "2026-10-11_sheet_style")
TURN = {"front": (470, 0, 680, 420), "three_quarter": (690, 0, 890, 420), "side": (890, 0, 1095, 420),
        "back": (1095, 0, 1310, 420), "three_quarter_back": (1310, 0, 1536, 420)}
HEADS = {"three_quarter": (455, 452, 800, 732), "side": (803, 452, 1166, 732), "back": (1169, 452, 1536, 732)}
# Crops at the same real size: the sheet's head close-up (~0.8 mm a pixel) against the lineup's
# --head front (0.84), the sheet's big figure (~2.0 mm a pixel) against the lineup's front view
# (2.55: its crop is scaled up to match before the 2x).
HERO = {"face": ("head_stand_front", (565, 525, 765, 725), (165, 175, 365, 375)),
        "vest": ("stand_front", (140, 230, 330, 420), (113, 250, 262, 399)),
        "boot": ("stand_front", (60, 800, 250, 990), (90, 745, 239, 894))}
BG = (22, 22, 22)


def label(img: Image.Image, words: str, size: int = 18) -> Image.Image:
    out = Image.new("RGB", (img.width, img.height + size + 10), BG)
    out.paste(img, (0, size + 10))
    ImageDraw.Draw(out).text((4, 3), words, fill=(240, 230, 210), font=judge._font(size))
    return out


def row(images: list, gap: int = 8) -> Image.Image:
    w = sum(i.width for i in images) + gap * (len(images) - 1)
    out = Image.new("RGB", (w, max(i.height for i in images)), BG)
    x = 0
    for i in images:
        out.paste(i, (x, 0))
        x += i.width + gap
    return out


def column(images: list, gap: int = 14) -> Image.Image:
    w = max(i.width for i in images)
    out = Image.new("RGB", (w, sum(i.height for i in images) + gap * (len(images) - 1)), BG)
    y = 0
    for i in images:
        out.paste(i, (0, y))
        y += i.height + gap
    return out


def fit_h(img: Image.Image, h: int) -> Image.Image:
    return img.resize((max(int(img.width * h / img.height), 1), h), Image.LANCZOS)


def trim(img: Image.Image, pad: int = 6) -> Image.Image:
    """Cropped round the man (anything off the background's colour)."""
    a = img.convert("RGB")
    bg = a.getpixel((2, 2))
    diff = Image.eval(Image.merge("RGB", [c.point(lambda v, b=b: 255 if abs(v - b) > 10 else 0)
                                          for c, b in zip(a.split(), bg)]).convert("L"), lambda v: 255 if v else 0)
    box = diff.getbbox() or (0, 0, a.width, a.height)
    return a.crop((max(box[0] - pad, 0), max(box[1] - pad, 0), min(box[2] + pad, a.width), min(box[3] + pad, a.height)))


def man(d: str, ours: str, today: str) -> Image.Image:
    sheet = Image.open(SHEET).convert("RGB")
    h = 380
    turn_s = row([fit_h(trim(sheet.crop(b)), h) for b in TURN.values()])
    turn_o = row([fit_h(trim(Image.open(os.path.join(d, ours, "stand_%s.png" % v))), h) for v in TURN])
    turn_t = row([fit_h(trim(Image.open(os.path.join(d, today, "stand_%s.png" % v))), h)
                  for v in TURN if os.path.exists(os.path.join(d, today, "stand_%s.png" % v))])
    hh = 300
    heads_s = row([fit_h(sheet.crop(b), hh) for b in HEADS.values()])
    heads_o = row([fit_h(Image.open(os.path.join(d, ours, "head_stand_%s.png" % v)).crop((0, 40, 500, 420)), hh) for v in HEADS])
    crops = []
    for k, (render, sb, ob) in HERO.items():
        s = sheet.crop(sb)
        o = Image.open(os.path.join(d, ours, render + ".png")).convert("RGB").crop(ob)
        if o.size != s.size:
            o = o.resize(s.size, Image.LANCZOS)
        crops.append(label(s.resize((s.width * 2, s.height * 2), Image.NEAREST), "sheet: %s, 2x" % k, 15))
        crops.append(label(o.resize((o.width * 2, o.height * 2), Image.NEAREST), "ours: %s, 2x" % k, 15))
    return column([
        label(turn_s, "the sheet's turnaround"),
        label(turn_o, "ours: Rodin's texture in squares (3/6/7 mm), nearest, smooth normals"),
        label(turn_t, "today: the style repaint, body_skin, same light"),
        label(heads_s, "the sheet's heads"),
        label(heads_o, "ours (the lineup's --head)"),
        row(crops[:2]), row(crops[2:4]), row(crops[4:]),
    ])


def world(d: str) -> Image.Image:
    parts = []
    for view in ("shot_match_saloon", "shot_match_street"):
        imgs = []
        for sub, words in (("shots_today", "today"), ("shots_sheet32", "sheet style, 32 texels/m"),
                           ("shots_sheet16", "sheet style, 16 texels/m")):
            p = os.path.join(d, sub, view + ".png")
            if os.path.exists(p):
                imgs.append((Image.open(p).convert("RGB").resize((1280, 720), Image.LANCZOS), words))
        if not imgs:
            continue
        parts.append(row([label(i.resize((640, 360), Image.LANCZOS), "%s: %s" % (view, w)) for i, w in imgs]))
        # 2x crops: the seated man / the near front.
        box = (440, 180, 760, 540) if view == "shot_match_saloon" else (60, 200, 380, 560)
        parts.append(row([label(i.crop(box).resize(((box[2] - box[0]) * 2, (box[3] - box[1]) * 2), Image.NEAREST),
                                "%s, 2x" % w, 15) for i, w in imgs]))
    return column(parts)


def main() -> None:
    opt = {a.split("=")[0]: a.split("=", 1)[1] for a in sys.argv[1:] if "=" in a}
    d = opt.get("--from", os.path.join(ROOT, "build", "sheet_style"))
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    m = man(d, opt.get("--ours", "fine2"), opt.get("--today", "base2"))
    m.save(OUT + "_man.png")
    print("wrote", OUT + "_man.png", m.size)
    if os.path.isdir(os.path.join(d, "shots_today")):
        w = world(d)
        w.save(OUT + "_world.png")
        print("wrote", OUT + "_world.png", w.size)


if __name__ == "__main__":
    main()
