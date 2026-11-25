#!/usr/bin/env python3
"""The line shack's mission plan (#1091, step 2), drawn from config/buildings/line_shack.json alone: the
walls, the door and its fall, the window, the lean-to, the furniture's footprints (each kit's `fit` or a
small box), the kept-clear areas, the cabin's points (Kett's corner, Joe's stands) and Joe's walk from
the door to Kett. North up, east right, the shack's own space in metres.

    python3 experiments/building_lab/line_shack/plan.py [OUT.png]
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
S, M = 110, 70


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/" + name, size)
    except OSError:
        return ImageFont.load_default()


def main(out):
    sp = json.load(open(os.path.join(ROOT, "config", "buildings", "line_shack.json")))
    W, D = sp["lot"]["width"], sp["lot"]["depth"]
    lt = [o for o in sp["outbuildings"] if o["id"] == "lean_to"][0]
    st = [o for o in sp["outbuildings"] if o["id"] == "store"][0]["rect"]
    x0, x1, z0, z1 = -0.6, lt["rect"][2] + 0.4, -1.2, st[3] + 0.5
    img = Image.new("RGB", (int((x1 - x0) * S) + 2 * M, int((z1 - z0) * S) + 2 * M + 150), (248, 245, 236))
    d = ImageDraw.Draw(img)
    P = lambda x, z: (M + (x - x0) * S, M + (z - z0) * S)
    R = lambda r: [P(r[0], r[1]), P(r[2], r[3])]
    f, fb, fs = font(15), font(18, True), font(12)
    # Kept clear (under everything)
    for k in sp["kept_clear"]:
        col = {"kett_corner": (250, 214, 205), "west_lane": (214, 236, 214), "door_fall": (252, 236, 190)}[k["id"]]
        d.rectangle(R(k["rect"]), fill=col)
    # The lean-to
    r = lt["rect"]
    d.rectangle(R(r), outline=(120, 100, 70), width=2)
    for p in lt["posts"]:
        cx, cy = P(*p)
        d.rectangle([cx - 6, cy - 6, cx + 6, cy + 6], fill=(90, 70, 40))
    d.text(P(r[0] + 0.15, r[1] + 0.1), "lean-to (open, dirt)", font=fs, fill=(90, 70, 40))
    # Walls
    t = 0.1
    for rr in ([0, 0, W, t], [0, D - t, W, D], [0, 0, t, D], [W - t, 0, W, D]):
        d.rectangle(R(rr), fill=(60, 55, 50))
    for rr in ([0, st[3] - t, W, st[3]], [0, st[1], t, st[3]], [W - t, st[1], W, st[3]]):
        d.rectangle(R(rr), fill=(90, 80, 70))
    bd = sp["walls"][1]["openings"][0]
    bx0, bx1 = bd["at"] - bd["width"] / 2, bd["at"] + bd["width"] / 2
    d.rectangle(R([bx0, D - t - 0.02, bx1, D + 0.02]), fill=(248, 245, 236))
    d.line([P(bx0, D), P(bx0, D + bd["width"])], fill=(60, 55, 50), width=3)
    d.text(P(2.15, st[1] + 0.62), "STOREROOM (no window)", font=fs, fill=(60, 50, 40))
    door = sp["walls"][0]["openings"][0]
    dx0, dx1 = door["at"] - door["width"] / 2, door["at"] + door["width"] / 2
    d.rectangle(R([dx0, -0.02, dx1, t + 0.02]), fill=(248, 245, 236))
    d.arc([P(dx0 - door["width"], -door["width"]), P(dx0 + door["width"], door["width"])], 0, 90, fill=(60, 55, 50), width=2)
    d.line([P(dx0, 0.05), P(dx0, door["width"])], fill=(60, 55, 50), width=3)
    win = sp["walls"][3]["openings"][0]
    d.rectangle(R([W - t - 0.02, win["at"] - 0.3, W + 0.02, win["at"] + 0.3]), fill=(160, 200, 230))
    ds = sp["doorstep"]
    d.rectangle(R([ds["at"][0] - ds["size"][0] / 2, ds["at"][1] - ds["size"][1] / 2, ds["at"][0] + ds["size"][0] / 2, ds["at"][1] + ds["size"][1] / 2]),
                fill=(205, 170, 140), outline=(120, 90, 60))
    d.text(P(ds["at"][0] + 0.6, -0.4), "doorstep 0.16 + 0.16", font=fs, fill=(90, 60, 40))
    # Furniture
    for b in sp["dressing"]["batches"].values():
        for it in b:
            if it.get("on") or it["at"][1] > 0.5:
                continue
            fx, fy, fz = it.get("fit", [0.35, 0.3, 0.35])
            if it.get("facing", 0) in (90, 270):
                fx, fz = fz, fx
            cx, cz = it["at"][0], it["at"][2]
            d.rectangle(R([cx - fx / 2, cz - fz / 2, cx + fx / 2, cz + fz / 2]), fill=(196, 176, 146), outline=(110, 90, 60))
            d.text(P(cx - fx / 2 + 0.03, cz - 0.08), it["id"], font=fs, fill=(50, 40, 30))
    # The walk
    w = sp["walk"]["joe_to_kett"]
    d.line([P(*p) for p in w], fill=(40, 90, 180), width=5)
    for p in w:
        cx, cy = P(*p)
        d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(40, 90, 180))
    for u in sp["use_points"]:
        if u["who"] not in ("kett", "joe"):
            continue
        cx, cy = P(u["at"][0], u["at"][2])
        col = (190, 40, 30) if u["who"] == "kett" else (40, 90, 180)
        d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], outline=col, width=3)
        d.text((cx + 13, cy - 8), u["id"], font=f, fill=col)
    cx, cy = P(3.3, 1.5)
    d.line([cx - 8, cy - 8, cx + 8, cy + 8], fill=(150, 150, 150), width=2)
    d.line([cx - 8, cy + 8, cx + 8, cy - 8], fill=(150, 150, 150), width=2)
    d.text((cx + 10, cy + 2), "old joe_in", font=fs, fill=(130, 130, 130))
    # Scale and north
    sx, sy = P(x0 + 0.1, z1 - 0.2)
    d.line([sx, sy, sx + S, sy], fill=(0, 0, 0), width=3)
    d.text((sx, sy + 4), "1 m", font=fs, fill=(0, 0, 0))
    d.text(P(x1 - 0.4, z0 + 0.05), "N ^", font=fb, fill=(0, 0, 0))
    d.text((M, 18), "The line shack (#1091): plan, Kett's hiding place, Joe's walk", font=fb, fill=(0, 0, 0))
    y = img.size[1] - 140
    for line in ["4.2 x 5.0 m (the stand-in's) + a 1.5 m storeroom south; door north (x 2.1), floor 0.32 m,",
                 "one window east, an open lean-to east. Red: the storeroom's west half, Kett's hiding place,",
                 "kept bare (Sean, 2026-11-25). Green: the lane, 0.9 m, nothing stands in it. Yellow: where",
                 "the kicked-in door falls (flat 25 mm planks only). Blue: Joe's walk, door -> joe_in -> the",
                 "lane -> the storeroom's door -> Kett. Grey x: the old joe_in (now behind table and bunk)."]:
        d.text((M, y), line, font=f, fill=(40, 40, 40))
        y += 24
    img.save(out)
    print(out, img.size)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "experiments", "building_lab", "line_shack", "plan.png"))
