#!/usr/bin/env python3
"""A concept's floor plans drawn from its data (the saloon concepts, #765/#660): cellar, ground and
upper floor side by side on one sheet, with the lot's streets, the posts, the girders and joists, the
stairs, doors, windows, the bar, and the missions' places numbered. Free (no paid call). The sheet goes
in as the target sheet's `plans` panel, so the painted views are given it to agree with.

    python3 tools/buildings/concept_plans.py experiments/building_lab/saloon_a/concept.json

Units are feet: x east from the lot's west line (the North-South Street), y north (back) from the
building's front line on Main Street; the boardwalk is y -8..0. Plans are drawn with north up and Main
Street at the bottom. A concept.json:

    {"title", "floors": {"cellar"|"ground"|"upper": {
        "outline": [[x, y], ...],            # the floor's outer walls (a polygon)
        "rooms": [{"name", "x", "y", "w", "d", "kind"}  or  {"name", "poly": [[x, y], ...], "kind"}],
        "doors": [{"x", "y", "w", "o": "h"|"v"}],   # a gap of width w along x (h) or y (v)
        "windows": [{"x", "y", "w", "o"}],
        "stairs": [{"x", "y", "w", "d", "up": "N"|"S"|"E"|"W", "label"}],
        "items": [{"type": "bar"|"backbar"|"table"|"piano"|"stove"|"post"|"trap"|"hatch"|"stage"|"billiard"|"platform"|"counter"|"kegs",
                   "x", "y", "w", "d", "r", "label"}],
        "lines": [{"type": "girder"|"joists"|"cut", "x0", "y0", "x1", "y1", "n", "label"}],
        "balcony": [{"x", "y", "w", "d"}] or "poly",
        "marks": [{"n", "x", "y"}]}},
     "walk": {"main": [x0, x1], "side": [y0, y1]},   # boardwalks drawn on the ground plan
     "legend": {"1": "No Law: the card table", ...}}
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

S = 8.0          # pixels a foot
PAD = 70         # around each plan
INK = (34, 28, 22)
PAPER = (244, 239, 228)
WASH = {"bar": (234, 214, 180), "dance": (240, 228, 170), "room": (226, 226, 220), "office": (214, 226, 210),
        "store": (220, 210, 196), "cellar": (204, 200, 192), "games": (228, 206, 190), "hall": (236, 232, 222),
        "theatre": (232, 210, 214), "stage": (214, 190, 170), "kitchen": (222, 218, 204), "yard": (232, 228, 214)}
RED = (178, 40, 30)


def font(size, bold=False):
    names = ("DejaVuSans-Bold.ttf", "DejaVuSans.ttf") if bold else ("DejaVuSans.ttf",)
    for n in names:
        for d in ("/usr/share/fonts/truetype/dejavu/", ""):
            try:
                return ImageFont.truetype(d + n, size)
            except OSError:
                pass
    return ImageFont.load_default()


class Plan:
    def __init__(self, dr, ox, oy, depth):
        self.dr, self.ox, self.oy, self.depth = dr, ox, oy, depth

    def p(self, x, y):
        # north up: y (back) grows upward on the page
        return (self.ox + x * S, self.oy + (self.depth - y) * S)

    def rect(self, x, y, w, d):
        a, b = self.p(x, y + d), self.p(x + w, y)
        return [a[0], a[1], b[0], b[1]]


def text_c(dr, xy, s, f, fill=INK):
    lines = s.split("\n")
    hs = [dr.textbbox((0, 0), ln, font=f) for ln in lines]
    tot = sum(h[3] - h[1] + 3 for h in hs)
    y = xy[1] - tot / 2
    for ln, h in zip(lines, hs):
        w = h[2] - h[0]
        dr.text((xy[0] - w / 2, y), ln, font=f, fill=fill)
        y += h[3] - h[1] + 3


def wrap(s, width_px, f, dr):
    words, lines, cur = s.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if dr.textbbox((0, 0), t, font=f)[2] > width_px and cur:
            lines.append(cur)
            cur = w
        else:
            cur = t
    lines.append(cur)
    return "\n".join(lines)


def draw_floor(dr, pl, fl, title, walk, is_ground):
    f_room, f_small, f_title = font(15, True), font(12), font(24, True)
    # streets and walk
    if walk and is_ground:
        if "main" in walk:
            x0, x1 = walk["main"]
            dr.rectangle(pl.rect(x0, -8, x1 - x0, 8), fill=(222, 214, 196), outline=(150, 140, 120))
            for i in range(int(x0), int(x1), 2):
                a, b = pl.p(i, -8), pl.p(i, 0)
                dr.line([a, b], fill=(196, 186, 166))
            text_c(dr, pl.p((x0 + x1) / 2, -4), "BOARDWALK", f_small)
        if "side" in walk:
            y0, y1 = walk["side"]
            dr.rectangle(pl.rect(-8, y0, 8, y1 - y0), fill=(222, 214, 196), outline=(150, 140, 120))
    for r in fl.get("rooms", []):
        fill = WASH.get(r.get("kind", "room"), WASH["room"])
        if "poly" in r:
            pts = [pl.p(*q) for q in r["poly"]]
            dr.polygon(pts, fill=fill, outline=INK)
            dr.line(pts + [pts[0]], fill=INK, width=3)
            cx = sum(q[0] for q in r["poly"]) / len(r["poly"])
            cy = sum(q[1] for q in r["poly"]) / len(r["poly"])
            cx, cy = r.get("lx", cx), r.get("ly", cy)
            wpx = 120
        else:
            dr.rectangle(pl.rect(r["x"], r["y"], r["w"], r["d"]), fill=fill)
            dr.rectangle(pl.rect(r["x"], r["y"], r["w"], r["d"]), outline=INK, width=3)
            cx, cy = r["x"] + r["w"] / 2, r["y"] + r["d"] / 2
            cx, cy = r.get("lx", cx), r.get("ly", cy)
            wpx = max(60, r["w"] * S - 10)
    for b in fl.get("balcony", []):
        if "poly" in b:
            pts = [pl.p(*q) for q in b["poly"]]
        else:
            x, y, w, d = b["x"], b["y"], b["w"], b["d"]
            pts = [pl.p(x, y), pl.p(x + w, y), pl.p(x + w, y + d), pl.p(x, y + d)]
        dr.polygon(pts, fill=(236, 226, 206))
        dr.line(pts + [pts[0]], fill=INK, width=2)
        # railing: a thin double line just inside the outer edge
        xs = [q[0] for q in pts]
        ys = [q[1] for q in pts]
        for k in range(int(min(xs)), int(max(xs)), 6):
            dr.line([(k, min(ys)), (k + 3, max(ys))], fill=(200, 188, 166))
        if b.get("label"):
            c = (sum(xs) / len(xs), sum(ys) / len(ys))
            text_c(dr, (b.get("lx") and pl.p(b["lx"], b["ly"])[0] or c[0], b.get("ly") is not None and pl.p(b["lx"], b["ly"])[1] or c[1]), b["label"], f_small)
    # outline
    if fl.get("outline"):
        pts = [pl.p(*q) for q in fl["outline"]]
        dr.line(pts + [pts[0]], fill=INK, width=8, joint="curve")
    # lines (girders, joists, the cut)
    for ln in fl.get("lines", []):
        a, b = pl.p(ln["x0"], ln["y0"]), pl.p(ln["x1"], ln["y1"])
        if ln["type"] == "girder":
            dash(dr, a, b, (90, 60, 30), 4, 14, 6)
        elif ln["type"] == "joists":
            # n thin lines parallel to (x0,y0)-(x1,y1), spread across `spread` feet perpendicular
            n, sp = ln.get("n", 8), ln.get("spread", 20)
            dx, dy = ln["x1"] - ln["x0"], ln["y1"] - ln["y0"]
            L = math.hypot(dx, dy) or 1
            nx, ny = -dy / L, dx / L
            for i in range(n):
                t = sp * i / max(1, n - 1)
                aa = pl.p(ln["x0"] + nx * t, ln["y0"] + ny * t)
                bb = pl.p(ln["x1"] + nx * t, ln["y1"] + ny * t)
                dash(dr, aa, bb, (150, 120, 80), 1, 6, 6)
        elif ln["type"] == "cut":
            dr.line([a, b], fill=RED, width=4)
        if ln.get("label"):
            m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 10)
            text_c(dr, m, ln["label"], f_small, (90, 60, 30) if ln["type"] != "cut" else RED)
    for it in fl.get("items", []):
        draw_item(dr, pl, it, f_small)
    for s in fl.get("stairs", []):
        draw_stair(dr, pl, s, f_small)
    for o in fl.get("doors", []):
        opening(dr, pl, o, door=True)
    for o in fl.get("windows", []):
        opening(dr, pl, o, door=False)
    # room labels last, over everything
    for r in fl.get("rooms", []):
        if r.get("nolabel"):
            continue
        if "poly" in r:
            cx = r.get("lx", sum(q[0] for q in r["poly"]) / len(r["poly"]))
            cy = r.get("ly", sum(q[1] for q in r["poly"]) / len(r["poly"]))
            wpx = r.get("lw", 20) * S
        else:
            cx, cy = r.get("lx", r["x"] + r["w"] / 2), r.get("ly", r["y"] + r["d"] / 2)
            wpx = max(50, r["w"] * S - 8)
        name = wrap(r["name"].upper(), wpx, f_room, dr)
        size = r.get("size") or ("%d x %d ft" % (r["w"], r["d"]) if "w" in r else "")
        text_c(dr, pl.p(cx, cy), name + ("\n" + size if size else ""), f_room)
    for m in fl.get("marks", []):
        c = pl.p(m["x"], m["y"])
        dr.ellipse([c[0] - 13, c[1] - 13, c[0] + 13, c[1] + 13], fill=RED, outline=(255, 255, 255), width=2)
        text_c(dr, c, str(m["n"]), font(15, True), (255, 255, 255))
    # title over the plan
    top = pl.p(0, pl.depth)
    dr.text((top[0], top[1] - 52), title, font=f_title, fill=INK)


def dash(dr, a, b, fill, width, on, off):
    L = math.hypot(b[0] - a[0], b[1] - a[1])
    if L == 0:
        return
    ux, uy = (b[0] - a[0]) / L, (b[1] - a[1]) / L
    t = 0
    while t < L:
        e = min(L, t + on)
        dr.line([(a[0] + ux * t, a[1] + uy * t), (a[0] + ux * e, a[1] + uy * e)], fill=fill, width=width)
        t = e + off


def opening(dr, pl, o, door):
    x, y, w = o["x"], o["y"], o["w"]
    if o.get("o") == "d":
        # a diagonal opening (the corner door): from (x, y) to (x + w, y - w)
        a, b = pl.p(x, y), pl.p(x + w, y - w)
        dr.line([a, b], fill=PAPER, width=12)
        for q in (a, b):
            dr.ellipse([q[0] - 3, q[1] - 3, q[0] + 3, q[1] + 3], fill=INK)
        return
    if o.get("arch"):
        door = False
        if o.get("o", "h") == "h":
            a, b = pl.p(x, y), pl.p(x + w, y)
        else:
            a, b = pl.p(x, y), pl.p(x, y + w)
        dr.line([a, b], fill=PAPER, width=10)
        for q in (a, b):
            dr.rectangle([q[0] - 3, q[1] - 3, q[0] + 3, q[1] + 3], fill=INK)
        return
    if o.get("o", "h") == "h":
        a, b = pl.p(x, y), pl.p(x + w, y)
        dr.line([a, b], fill=PAPER, width=10)
        if door:
            sgn = -1 if o.get("swing", "in") == "in" else 1
            r = w * S
            # a leaf drawn open at 90 degrees and its arc
            hinge = a
            dr.line([hinge, (hinge[0], hinge[1] + sgn * r)], fill=INK, width=2)
            bb = [hinge[0] - r, hinge[1] - r, hinge[0] + r, hinge[1] + r]
            dr.arc(bb, 270 if sgn < 0 else 0, 360 if sgn < 0 else 90, fill=(120, 110, 100), width=1)
        else:
            for k in (-3, 0, 3):
                dr.line([(a[0], a[1] + k), (b[0], b[1] + k)], fill=INK, width=1)
    else:
        a, b = pl.p(x, y), pl.p(x, y + w)
        dr.line([a, b], fill=PAPER, width=10)
        if door:
            r = w * S
            sgn = 1 if o.get("swing", "in") == "in" else -1
            hinge = a
            dr.line([hinge, (hinge[0] + sgn * r, hinge[1])], fill=INK, width=2)
            bb = [hinge[0] - r, hinge[1] - r, hinge[0] + r, hinge[1] + r]
            dr.arc(bb, 270 if sgn > 0 else 180, 360 if sgn > 0 else 270, fill=(120, 110, 100), width=1)
        else:
            for k in (-3, 0, 3):
                dr.line([(a[0] + k, a[1]), (b[0] + k, b[1])], fill=INK, width=1)


def draw_stair(dr, pl, s, f):
    x, y, w, d = s["x"], s["y"], s["w"], s["d"]
    dr.rectangle(pl.rect(x, y, w, d), fill=(250, 248, 240), outline=INK, width=2)
    up = s.get("up", "N")
    if up in "NS":
        n = int(d / 0.85)
        for i in range(1, n):
            a, b = pl.p(x, y + i * d / n), pl.p(x + w, y + i * d / n)
            dr.line([a, b], fill=(110, 100, 90), width=1)
        a = pl.p(x + w / 2, y + (0.15 * d if up == "N" else 0.85 * d))
        b = pl.p(x + w / 2, y + (0.85 * d if up == "N" else 0.15 * d))
    else:
        n = int(w / 0.85)
        for i in range(1, n):
            a, b = pl.p(x + i * w / n, y), pl.p(x + i * w / n, y + d)
            dr.line([a, b], fill=(110, 100, 90), width=1)
        a = pl.p(x + (0.15 * w if up == "E" else 0.85 * w), y + d / 2)
        b = pl.p(x + (0.85 * w if up == "E" else 0.15 * w), y + d / 2)
    dr.line([a, b], fill=INK, width=2)
    ang = math.atan2(b[1] - a[1], b[0] - a[0])
    for da in (2.6, -2.6):
        dr.line([b, (b[0] + 10 * math.cos(ang + da), b[1] + 10 * math.sin(ang + da))], fill=INK, width=2)
    if s.get("label"):
        c = pl.p(x + w / 2, y + d / 2)
        lx = c[0] + (w * S / 2 + 6 if s.get("label_side", "E") == "E" else -w * S / 2 - 6)
        bb = dr.textbbox((0, 0), s["label"], font=f)
        tx = lx if s.get("label_side", "E") == "E" else lx - (bb[2] - bb[0])
        dr.text((tx, c[1] - 7), s["label"], font=f, fill=INK)


def draw_item(dr, pl, it, f):
    t = it["type"]
    if t in ("table", "faro"):
        c, r = pl.p(it["x"], it["y"]), it.get("r", 2.0) * S
        fill = RED if it.get("key") else (190, 160, 120)
        dr.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=fill, outline=INK, width=1)
        for k in range(it.get("chairs", 4)):
            a = 2 * math.pi * k / it.get("chairs", 4) + 0.4
            q = (c[0] + (r + 7) * math.cos(a), c[1] + (r + 7) * math.sin(a))
            dr.rectangle([q[0] - 4, q[1] - 4, q[0] + 4, q[1] + 4], outline=INK, fill=(230, 220, 200))
        return
    if t == "post":
        c = pl.p(it["x"], it["y"])
        dr.rectangle([c[0] - 5, c[1] - 5, c[0] + 5, c[1] + 5], fill=INK)
        return
    if t == "stove":
        c = pl.p(it["x"], it["y"])
        dr.rectangle([c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9], fill=(40, 40, 40))
        dr.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=(150, 150, 150))
        return
    box = pl.rect(it["x"], it["y"], it.get("w", 2), it.get("d", 2))
    fills = {"bar": (110, 70, 40), "backbar": (140, 96, 60), "piano": (60, 40, 30), "trap": (250, 248, 240),
             "hatch": (250, 248, 240), "stage": (200, 170, 140), "billiard": (70, 120, 70),
             "platform": (210, 186, 150), "counter": (150, 110, 70), "kegs": (170, 130, 90), "bed": (235, 235, 235),
             "desk": (150, 110, 70), "boxes": (238, 220, 222), "privy": (210, 200, 180)}
    dr.rectangle(box, fill=fills.get(t, (200, 200, 200)), outline=INK, width=2)
    if t in ("trap", "hatch"):
        dr.line([(box[0], box[1]), (box[2], box[3])], fill=INK, width=1)
        dr.line([(box[0], box[3]), (box[2], box[1])], fill=INK, width=1)
    if t == "kegs":
        cx, cy = (box[0] + box[2]) / 2, (box[1] + box[3]) / 2
        for i in range(int((box[2] - box[0]) // 18)):
            for j in range(int((box[3] - box[1]) // 18)):
                q = (box[0] + 9 + i * 18, box[1] + 9 + j * 18)
                dr.ellipse([q[0] - 7, q[1] - 7, q[0] + 7, q[1] + 7], outline=INK, fill=(196, 160, 116))
    if it.get("label"):
        c = ((box[0] + box[2]) / 2, (box[1] + box[3]) / 2)
        light = t in ("bar", "piano", "billiard", "backbar")
        lab = it["label"]
        if box[3] - box[1] > box[2] - box[0] * 1.0 and (box[3] - box[1]) > 3 * (box[2] - box[0]):
            # a tall thin item: the label rotated
            im = Image.new("RGBA", (int(box[3] - box[1]), 18), (0, 0, 0, 0))
            d2 = ImageDraw.Draw(im)
            bb = d2.textbbox((0, 0), lab, font=f)
            d2.text(((im.width - (bb[2] - bb[0])) / 2, 1), lab, font=f, fill=(255, 255, 255) if light else INK)
            im = im.rotate(90, expand=True)
            dr._image.paste(im, (int(c[0] - im.width / 2), int(c[1] - im.height / 2)), im)
        else:
            text_c(dr, c, lab, f, (255, 255, 255) if light else INK)


def plans(path):
    con = json.load(open(path))
    floors = [k for k in ("cellar", "ground", "upper") if k in con["floors"]]
    xs, ys = [], []
    for k in floors:
        fl = con["floors"][k]
        for q in fl.get("outline", []):
            xs.append(q[0]); ys.append(q[1])
        for r in fl.get("rooms", []):
            if "poly" in r:
                for q in r["poly"]:
                    xs.append(q[0]); ys.append(q[1])
            else:
                xs += [r["x"], r["x"] + r["w"]]; ys += [r["y"], r["y"] + r["d"]]
    xmin, xmax = min(xs + [-10]), max(xs + [62])
    ymin, ymax = -10, max(ys) + 2
    depth = ymax
    col_w = (xmax - xmin) * S + 2 * PAD
    H = int((ymax - ymin) * S + 2 * PAD + 120 + 40 * (1 + len(con.get("legend", {})) // 2))
    W = int(col_w * len(floors))
    img = Image.new("RGB", (W, H), PAPER)
    dr = ImageDraw.Draw(img)
    titles = {"cellar": "CELLAR", "ground": "GROUND FLOOR", "upper": "UPPER FLOOR"}
    for i, k in enumerate(floors):
        ox = i * col_w + PAD - xmin * S
        oy = PAD + 60
        pl = Plan(dr, ox, oy, depth)
        fl = con["floors"][k]
        ghost = con["floors"].get("ground", {}).get("outline")
        if k != "ground" and ghost:
            pts = [pl.p(*q) for q in ghost]
            for a, b in zip(pts, pts[1:] + pts[:1]):
                dash(dr, a, b, (170, 160, 145), 2, 8, 6)
        draw_floor(dr, pl, fl, titles[k], con.get("walk"), k == "ground")
        # street names
        f = font(14, True)
        text_c(dr, pl.p((xmin + xmax) / 2, -9.5 if k != "ground" else -10.5), "MAIN STREET (south)", f)
        im = Image.new("RGBA", (260, 20), (0, 0, 0, 0))
        ImageDraw.Draw(im).text((0, 0), "NORTH-SOUTH STREET", font=f, fill=INK)
        im = im.rotate(90, expand=True)
        q = pl.p(xmin + 0.5, depth * 0.5)
        img.paste(im, (int(q[0]), int(q[1] - 130)), im)
        if xmax > 56:
            text_c(dr, pl.p(min(xmax - 3, 60), depth * 0.5), "YARD", f, (120, 110, 90))
    # scale bar and north arrow, bottom left
    y0 = H - 40 * (1 + len(con.get("legend", {})) // 2) - 50
    x0 = 30
    for k in range(4):
        dr.rectangle([x0 + k * 10 * S, y0, x0 + (k + 1) * 10 * S, y0 + 8], fill=INK if k % 2 == 0 else PAPER, outline=INK)
        dr.text((x0 + k * 10 * S - 4, y0 + 12), str(k * 10), font=font(13), fill=INK)
    dr.text((x0 + 40 * S + 6, y0 + 12), "40 ft", font=font(13), fill=INK)
    ax = x0 + 40 * S + 90
    dr.polygon([(ax, y0 - 22), (ax - 9, y0 + 8), (ax + 9, y0 + 8)], fill=INK)
    dr.text((ax - 5, y0 + 12), "N", font=font(14, True), fill=INK)
    dr.text((ax + 40, y0 - 4), con.get("title", ""), font=font(20, True), fill=INK)
    # legend
    f = font(15)
    items = sorted(con.get("legend", {}).items(), key=lambda kv: int(kv[0]))
    ly = y0 + 40
    colw = W // 2
    for i, (n, s) in enumerate(items):
        cx = 40 + (i % 2) * colw
        cy = ly + (i // 2) * 34
        dr.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=RED)
        text_c(dr, (cx, cy), n, font(14, True), (255, 255, 255))
        dr.text((cx + 20, cy - 9), s, font=f, fill=INK)
    out_dir = os.path.join(os.path.dirname(path), "sheet", "panels")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "plans.jpg")
    img.save(out, quality=92)
    print("%s: %dx%d" % (out, W, H))
    return out


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for p in sys.argv[1:]:
        plans(p)
