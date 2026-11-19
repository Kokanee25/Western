"""The wall clock's modelled parts (#789, #1030), from tools/props/wall_clock.py's numbers: the painted dial
(printed with Pillow on its own sheet, wall_clock_dial_albedo.png: a 12 in dial aged to cream, Roman
hours with the clockmaker's IIII, a minute track, a seconds bit over the middle, one winding hole, the
maker's name; black spandrels with gilt scrolls in its corners), the brass bezel round it, the blued steel
spade hands, the pendulum (a dark rod, a brass-faced lenticular bob, its rating nut), REGULATOR and a
rule in gilt on the back of the lower glass, the maker's paper label on the case's back behind the
pendulum, the door's latch. Baked the gun way (metal.py); the dial and label not baked (their own sheet).

References: Seth Thomas's Regulator No. 2 (made from the 1860s; 36 in, a 12 in dial, a seconds bit,
"REGULATOR" in gold leaf on the lower glass) and the Ansonia and Waterbury regulators in their 1880s
catalogues. The maker's name is invented.

    ~/.venvs/bpy/bin/python tools/blender/props/wall_clock.py
"""
import math
import os
import random
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import common  # noqa: E402
import metal  # noqa: E402
import wall_clock as wc  # noqa: E402  (tools/props/wall_clock.py: the numbers)
from common import Part, box, lathe, moved  # noqa: E402

FONT_DIR = "/usr/share/fonts/truetype/liberation/"
SHEET_PX = 2048
DIAL_PX = 1536                   # the dial's square on the sheet (top left)
LABEL_BOX = (0, 1536, 1024, 2048)  # the label's on the sheet (x0, y0, x1, y1)
LABEL = (0.16, 0.08, 0.37)       # its width, height and middle's y on the case's back

metal.FINISHES.update({
    # Blued steel (clock hands were heat-blued: a deep blue-black that catches blue at its edges).
    "blued": {"kind": "plate", "color": (0.035, 0.045, 0.085), "under": (0.20, 0.22, 0.30), "rust": 0.0,
              "rough": 0.22, "metal": 0.8, "wear": 0.25},
    # Gold leaf laid on the back of glass (a regulator's lettering), bright and even, a little lost at
    # its edges with age.
    "gilt_leaf": {"kind": "plate", "color": (0.80, 0.58, 0.24), "under": (0.50, 0.36, 0.16), "rust": 0.0,
                  "rough": 0.18, "metal": 0.8, "wear": 0.2},
    # Lacquered brass gone mellow (a bezel, a bob's face): warmer and smoother than the lamps' brass.
    "clock_brass": {"kind": "plate", "color": (0.66, 0.48, 0.22), "under": (0.82, 0.66, 0.36), "rust": 0.0,
                    "rough": 0.24, "metal": 0.8, "wear": 0.35, "tarnish": 0.4},
})


# --- Flat parts from outlines ---------------------------------------------------------------------

def _ear_clip(pts):
    """Triangles over a simple polygon (anticlockwise), by ear clipping."""
    idx = list(range(len(pts)))
    tris = []
    p = np.asarray(pts, float)

    def area2(a, b, c):
        return (p[b][0] - p[a][0]) * (p[c][1] - p[a][1]) - (p[c][0] - p[a][0]) * (p[b][1] - p[a][1])

    def inside(a, b, c, q):
        return area2(a, b, q) >= 0 and area2(b, c, q) >= 0 and area2(c, a, q) >= 0

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        for k in range(len(idx)):
            a, b, c = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            if area2(a, b, c) <= 1e-12:
                continue
            if any(inside(a, b, c, q) for q in idx if q not in (a, b, c)):
                continue
            tris.append((a, b, c))
            idx.pop(k)
            break
        else:
            break
    if len(idx) == 3:
        tris.append(tuple(idx))
    return tris


def plate(name, outline, z0, z1, at=(0, 0), smooth=False):
    """A flat plate cut to `outline` (x, y anticlockwise from the front), from z0 to z1, moved by `at`."""
    o = [(x + at[0], y + at[1]) for x, y in outline]
    n = len(o)
    verts = [(x, y, z0) for x, y in o] + [(x, y, z1) for x, y in o]
    faces = []
    for a, b, c in _ear_clip(outline):
        faces.append([n + a, n + b, n + c])
        faces.append([c, b, a])
    for k in range(n):
        a, b = k, (k + 1) % n
        faces.append([a, b, n + b, n + a])
    return Part(name, smooth).add(verts, faces)


def disc(name, r, z0, z1, at=(0, 0), sides=20):
    return plate(name, [(math.cos(2 * math.pi * k / sides) * r, math.sin(2 * math.pi * k / sides) * r)
                        for k in range(sides)], z0, z1, at)


def spade_hand(length, tail, shaft, spade_at, spade_w, spade_l):
    """A spade hand pointing up from the arbor (0, 0): a counterpoise tail, a tapering shaft, the
    spade's bulb and its point."""
    s0 = spade_at
    right = [(shaft * 0.9, -tail * 0.6), (shaft * 0.5, s0 * 0.5), (shaft * 0.38, s0),
             (spade_w * 0.30, s0 + spade_l * 0.18), (spade_w * 0.5, s0 + spade_l * 0.42),
             (spade_w * 0.44, s0 + spade_l * 0.64), (spade_w * 0.18, s0 + spade_l * 0.86),
             (shaft * 0.3, s0 + spade_l), (0.0006, length - 0.002)]
    # Anticlockwise from the front: up the right side, over the point, down the left.
    pts = [(0.0, -tail)] + right + [(0.0, length)] + [(-x, y) for x, y in reversed(right)]
    return pts


def hands():
    cx, cy = wc.DIAL_C
    out = []
    hour = plate("Hour", spade_hand(wc.HOUR_L, 0.022, 0.0045, 0.040, 0.020, 0.032),
                 wc.HAND_Z["Hour"] - 0.0006, wc.HAND_Z["Hour"] + 0.0006, (cx, cy))
    hour.merge(disc("h", 0.0075, wc.HAND_Z["Hour"] - 0.0006, wc.HAND_Z["Hour"] + 0.0006, (cx, cy)))
    minute = plate("Minute", spade_hand(wc.MINUTE_L, 0.030, 0.0035, 0.085, 0.012, 0.022),
                   wc.HAND_Z["Minute"] - 0.0006, wc.HAND_Z["Minute"] + 0.0006, (cx, cy))
    minute.merge(disc("m", 0.006, wc.HAND_Z["Minute"] - 0.0006, wc.HAND_Z["Minute"] + 0.0006, (cx, cy)))
    # The collet (a small domed brass nut) holds the minute hand: it turns with it.
    collet = lathe("Collet", [(0.0035, 0.0), (0.0034, 0.0015), (0.0022, 0.0028), (0.0, 0.0032)], sides=12, axis="z",
                   at=(cx, cy, wc.HAND_Z["Minute"] + 0.0006))
    sx, sy = wc.SECONDS_C
    seconds = plate("Seconds", [(0.0, -0.006), (0.0009, -0.004), (0.0006, wc.SECOND_L), (-0.0006, wc.SECOND_L), (-0.0009, -0.004)],
                    wc.HAND_Z["Seconds"] - 0.0004, wc.HAND_Z["Seconds"] + 0.0004, (sx, sy))
    seconds.merge(disc("s", 0.0025, wc.HAND_Z["Seconds"] - 0.0004, wc.HAND_Z["Seconds"] + 0.0004, (sx, sy), 12))
    out += [(hour, "blued"), (minute, "blued"), (collet, "clock_brass"), (seconds, "blued")]
    return out


def bezel():
    cx, cy = wc.DIAL_C
    r = wc.DIAL_R
    prof = [(r - 0.004, 0.0), (r - 0.004, 0.003), (r - 0.002, 0.008), (r + 0.003, 0.011), (r + 0.008, 0.0095),
            (r + 0.011, 0.005), (r + 0.012, 0.0)]
    return lathe("Bezel", prof, sides=64, axis="z", at=(cx, cy, wc.DIAL_Z), caps=(False, False))


def works():
    """What shows of the movement: the winding arbor's square in its brass bushing."""
    wx, wy = wc.WIND
    bush = lathe("Works", [(0.0065, 0.0), (0.0065, 0.0015), (0.0045, 0.0022), (0.0040, 0.0)], sides=16, axis="z",
                 at=(wx, wy, wc.DIAL_Z))
    square = box("sq", (0.0042, 0.0042, 0.006), (wx, wy, wc.DIAL_Z + 0.001))
    return [(bush.merge(square), "clock_brass")]


def pendulum():
    px, py, pz = wc.PIVOT
    bx, by = wc.BOB_C
    rod_top = py - 0.03
    rod = box("Pendulum", (0.007, rod_top - (by - 0.03), 0.004), (px, (rod_top + by - 0.03) * 0.5, pz))
    # The suspension spring and its block (steel), the crutch's pin.
    spring = box("spring", (0.009, 0.03, 0.0008), (px, py - 0.015, pz))
    block = box("block", (0.016, 0.008, 0.006), (px, py, pz))
    # The bob: a brass-faced lens (a lathe about z), the rating nut under it on the rod's thread.
    r = wc.BOB_R
    prof = [(0.0, -0.011), (r * 0.35, -0.0105), (r * 0.7, -0.008), (r * 0.92, -0.004), (r, 0.0),
            (r * 0.92, 0.004), (r * 0.7, 0.008), (r * 0.35, 0.0105), (0.0, 0.011)]
    bob = lathe("bob", prof, sides=40, axis="z", at=(bx, by, pz))
    nut = lathe("nut", [(0.006, 0.0), (0.006, 0.008), (0.0, 0.008)], sides=10, axis="y",
                at=(bx, by - r - 0.012, pz))
    thread = box("thread", (0.003, 0.016, 0.003), (bx, by - r - 0.006, pz))
    return [(rod, "ebony"), (spring.merge(block), "steel"), (bob, "clock_brass"), (nut.merge(thread), "clock_brass")]


def latch():
    x = wc.W * 0.5 - wc.STILE * 0.5
    knob = lathe("Latch", [(0.004, 0.0), (0.004, 0.006), (0.007, 0.010), (0.006, 0.014), (0.0, 0.015)], sides=14,
                 axis="z", at=(x, wc.DIAL_C[1] - 0.17, wc.D + wc.DOOR_T))
    return [(knob, "clock_brass")]


def lettering():
    """REGULATOR in gold leaf on the back of the lower glass, in a ruled border (made from a font's
    outlines by Blender, flat)."""
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    font = bpy.data.fonts.load(os.path.join(FONT_DIR, "LiberationSerif-Bold.ttf"))
    cu = bpy.data.curves.new("t", type="FONT")
    cu.body = "REGULATOR"
    cu.font = font
    cu.align_x = "CENTER"
    cu.align_y = "CENTER"
    cu.size = 1.0
    cu.space_character = 1.12
    ob = bpy.data.objects.new("t", cu)
    bpy.context.scene.collection.objects.link(ob)
    dg = bpy.context.evaluated_depsgraph_get()
    me = ob.evaluated_get(dg).to_mesh()
    v = np.array([(p.co.x, p.co.y) for p in me.vertices])
    faces = [list(poly.vertices) for poly in me.polygons]
    ob.to_mesh_clear()
    lo, hi = v.min(axis=0), v.max(axis=0)
    width = 2 * wc.OPEN_X - 0.07
    k = width / (hi[0] - lo[0])
    k = min(k, 0.030 / (hi[1] - lo[1]))
    y_mid = wc.RAIL_LOW[1] + 0.038
    z = wc.GLASS_Z - 0.0017
    v = (v - (lo + hi) * 0.5) * k + np.array([0.0, y_mid])
    letters = Part("Lettering", False).add([(x, y, z) for x, y in v], faces)
    # The ruled border just inside the opening, and a hair rule inside it.
    a0, a1 = wc.RAIL_LOW[1], wc.RAIL_MID[0]
    for inset, w in ((0.010, 0.0028), (0.016, 0.0008)):
        x0, x1 = -wc.OPEN_X + inset, wc.OPEN_X - inset
        y0, y1 = a0 + inset, a1 - inset
        for (ax, ay, bx_, by_) in ((x0, y0, x1, y0 + w), (x0, y1 - w, x1, y1), (x0, y0, x0 + w, y1), (x1 - w, y0, x1, y1)):
            letters.add([(ax, ay, z), (bx_, ay, z), (bx_, by_, z), (ax, by_, z)], [[0, 1, 2, 3]])
    return [(letters, "gilt_leaf")]


# --- The dial and label sheet ---------------------------------------------------------------------

def _font(style, size):
    from PIL import ImageFont
    name = {"bold": "LiberationSerif-Bold.ttf", "italic": "LiberationSerif-Italic.ttf",
            "regular": "LiberationSerif-Regular.ttf"}[style]
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


ROMAN = ["XII", "I", "II", "III", "IIII", "V", "VI", "VII", "VIII", "IX", "X", "XI"]


def sheet():
    """The dial (top left square) and the maker's label, aged, on one sheet; and its ORM."""
    from PIL import Image, ImageDraw, ImageFilter
    rng = random.Random(789)
    img = Image.new("RGB", (SHEET_PX, SHEET_PX), (40, 34, 28))
    s = DIAL_PX / (2 * wc.SHEET)                 # pixels a metre on the dial
    c = (DIAL_PX * 0.5, DIAL_PX * 0.5)

    def at(x, y):  # dial space (metres from its middle, y up) -> pixels
        return (c[0] + x * s, c[1] - y * s)

    dial = Image.new("RGB", (DIAL_PX, DIAL_PX), (14, 12, 11))
    d = ImageDraw.Draw(dial)
    # The spandrels: black japan; in each corner a gilt scroll (two C-scrolls back to back along the
    # corner's diagonal, leaves on their backs), and a gilt ring round the dial.
    gold, gold_dk = (176, 134, 60), (120, 86, 38)
    lw = max(2, int(s * 0.0011))
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        diag = math.atan2(sy, sx)
        base = wc.SHEET * 1.16   # out along the diagonal, in the corner beyond the dial
        for side in (-1, 1):
            ang0 = diag + side * 0.55
            # A C-scroll: a spiral turning in from the corner toward the dial.
            pts = []
            for k in range(40):
                t = k / 39.0
                rr = 0.020 * (1.0 - 0.65 * t)
                a = ang0 + side * (t * 4.2)
                ox = base * math.cos(diag) + 0.016 * math.cos(diag + side * 1.1)
                oy = base * math.sin(diag) + 0.016 * math.sin(diag + side * 1.1)
                pts.append(at(ox + rr * math.cos(a), oy + rr * math.sin(a)))
            d.line(pts, fill=gold, width=lw, joint="curve")
            for k in range(4, 30, 6):
                x_, y_ = pts[k]
                q = s * 0.0028
                d.ellipse([x_ - q, y_ - q * 0.6, x_ + q, y_ + q * 0.6], fill=gold_dk)
        cx_, cy_ = at(base * math.cos(diag) * 1.02, base * math.sin(diag) * 1.02)
        q = s * 0.0045
        d.ellipse([cx_ - q, cy_ - q, cx_ + q, cy_ + q], fill=gold)
    gr = (wc.DIAL_R + 0.004) * s
    d.ellipse([c[0] - gr, c[1] - gr, c[0] + gr, c[1] + gr], outline=gold, width=max(3, int(s * 0.0022)))
    # The painted dial: cream gone to old ivory, darker toward its rim (a century's smoke in a bar is
    # less: forty years of lamps), a fine crazing.
    R = wc.DIAL_R * s
    face = Image.new("RGB", (DIAL_PX, DIAL_PX), (226, 216, 186))
    fd = ImageDraw.Draw(face)
    for k in range(60, 0, -1):
        t = k / 60.0
        g = int(18 * t ** 3)
        fd.ellipse([c[0] - R * t, c[1] - R * t, c[0] + R * t, c[1] + R * t], fill=(230 - g, 220 - g, 190 - int(g * 1.3)))
    for _ in range(900):
        x0, y0 = rng.uniform(c[0] - R, c[0] + R), rng.uniform(c[1] - R, c[1] + R)
        ang = rng.uniform(0, math.pi)
        l = rng.uniform(4, 22)
        fd.line([(x0, y0), (x0 + math.cos(ang) * l, y0 + math.sin(ang) * l)], fill=(200, 188, 156), width=1)
    for _ in range(140):  # fly specks
        x0, y0 = rng.uniform(c[0] - R, c[0] + R), rng.uniform(c[1] - R, c[1] + R)
        q = rng.uniform(1.0, 2.6)
        fd.ellipse([x0 - q, y0 - q, x0 + q, y0 + q], fill=(92, 76, 58))
    mask = Image.new("L", (DIAL_PX, DIAL_PX), 0)
    ImageDraw.Draw(mask).ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=255)
    dial.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(dial)
    ink = (22, 18, 16)
    # The minute track: two rings, a tick a minute, heavier at the fives.
    r1, r2 = 0.141 * s, 0.131 * s
    for rr in (r1, r2):
        d.ellipse([c[0] - rr, c[1] - rr, c[0] + rr, c[1] + rr], outline=ink, width=max(2, int(s * 0.0009)))
    for m in range(60):
        a = math.radians(m * 6)
        inner = r2 - (0.004 * s if m % 5 == 0 else 0)
        w = int(s * (0.0016 if m % 5 == 0 else 0.0009))
        d.line([(c[0] + math.sin(a) * inner, c[1] - math.cos(a) * inner), (c[0] + math.sin(a) * r1, c[1] - math.cos(a) * r1)],
               fill=ink, width=max(2, w))
    # The hours, Roman, each standing on the centre (the period's way: their feet toward it).
    fh = _font("regular", int(0.026 * s))
    for h, numeral in enumerate(ROMAN):
        tw = int(fh.getlength(numeral)) + 8
        th = int(0.032 * s)
        tile = Image.new("L", (tw, th), 0)
        ImageDraw.Draw(tile).text((tw * 0.5, th * 0.5), numeral, font=fh, fill=255, anchor="mm")
        # Squeezed a little (a dial's numerals are tall and narrow).
        tile = tile.resize((int(tw * 0.86), th))
        a = h * 30.0
        rot = tile.rotate(-a, expand=True, resample=Image.BICUBIC)
        rc = 0.112 * s
        px = c[0] + math.sin(math.radians(a)) * rc
        py = c[1] - math.cos(math.radians(a)) * rc
        dial.paste(Image.new("RGB", rot.size, ink), (int(px - rot.size[0] * 0.5), int(py - rot.size[1] * 0.5)), rot)
    # The seconds bit, over the middle.
    sc = at(wc.SECONDS_C[0] - wc.DIAL_C[0], wc.SECONDS_C[1] - wc.DIAL_C[1])
    sr = wc.SECONDS_R * s
    d.ellipse([sc[0] - sr, sc[1] - sr, sc[0] + sr, sc[1] + sr], outline=ink, width=max(2, int(s * 0.0007)))
    for m in range(60):
        a = math.radians(m * 6)
        inner = sr - (0.004 if m % 5 == 0 else 0.0022) * s
        d.line([(sc[0] + math.sin(a) * inner, sc[1] - math.cos(a) * inner), (sc[0] + math.sin(a) * sr, sc[1] - math.cos(a) * sr)],
               fill=ink, width=max(1, int(s * 0.0006)))
    fs = _font("regular", int(0.0055 * s))
    for k in range(1, 7):
        a = math.radians(k * 60)
        rr = sr - 0.0085 * s
        d.text((sc[0] + math.sin(a) * rr, sc[1] - math.cos(a) * rr), str(k * 10), font=fs, fill=ink, anchor="mm")
    # The maker's name under the middle, and REGULATOR's place in a small italic.
    f1 = _font("bold", int(0.0105 * s))
    f2 = _font("regular", int(0.0072 * s))
    d.text(at(0, -0.040), "H. ASHBY & SONS", font=f1, fill=ink, anchor="mm")
    d.text(at(0, -0.054), "BRISTOL, CONN.  U.S.A.", font=f2, fill=ink, anchor="mm")
    # The winding hole (its brass bushing is modelled) and the centre's hole.
    wx, wy = wc.WIND[0] - wc.DIAL_C[0], wc.WIND[1] - wc.DIAL_C[1]
    for hx, hy, hr in ((wx, wy, 0.0072), (0.0, 0.0, 0.004)):
        p = at(hx, hy)
        d.ellipse([p[0] - hr * s, p[1] - hr * s, p[0] + hr * s, p[1] + hr * s], fill=(10, 8, 7))
    # Grime from the key round the winding hole (a thumb's smudge, years of winding).
    smudge = Image.new("L", (DIAL_PX, DIAL_PX), 0)
    p = at(wx, wy)
    ImageDraw.Draw(smudge).ellipse([p[0] - 0.02 * s, p[1] - 0.016 * s, p[0] + 0.02 * s, p[1] + 0.02 * s], fill=70)
    smudge = smudge.filter(ImageFilter.GaussianBlur(0.008 * s))
    dial.paste(Image.new("RGB", dial.size, (96, 80, 58)), (0, 0), smudge)
    img.paste(dial, (0, 0))
    # The maker's label (on the case's back, seen through the lower glass behind the bob): foxed paper.
    x0, y0, x1, y1 = LABEL_BOX
    lw, lh = x1 - x0, y1 - y0
    lab = Image.new("RGB", (lw, lh), (214, 198, 160))
    ld = ImageDraw.Draw(lab)
    # Foxing: a few small rust-brown spots, a tide line of damp at the bottom.
    for _ in range(45):
        q = rng.uniform(1.5, 6)
        xx, yy = rng.uniform(0, lw), rng.uniform(0, lh)
        ld.ellipse([xx - q, yy - q, xx + q, yy + q], fill=(rng.randint(176, 190), rng.randint(146, 158), rng.randint(104, 114)))
    ld.rectangle([0, lh * 0.86, lw, lh], fill=(196, 178, 138))
    lab = lab.filter(ImageFilter.GaussianBlur(2))
    ld = ImageDraw.Draw(lab)
    li = (40, 30, 24)
    ld.rectangle([12, 12, lw - 13, lh - 13], outline=li, width=5)
    ld.rectangle([24, 24, lw - 25, lh - 25], outline=li, width=1)
    lines = [("REGULATOR CLOCKS,", "bold", 52), ("MANUFACTURED BY", "regular", 26), ("H. ASHBY & SONS,", "bold", 60),
             ("BRISTOL, CONN.", "regular", 34), ("Directions. \u2014 Hang the clock plumb, so that the beat is even. To make", "italic", 20),
             ("it go faster, turn the nut under the ball up; slower, down. Wind once a week.", "italic", 20)]
    y = 46
    for text, style, size in lines:
        f = _font(style, size)
        ld.text((lw * 0.5, y), text, font=f, fill=li, anchor="ma")
        y += int(size * 1.28) + 6
    img.paste(lab, (x0, y0))
    path = os.path.join(common.MODELS, "wall_clock_dial_albedo.png")
    img.save(path)
    # ORM: occlusion 1, painted zinc / paper a satin-to-dull roughness, no metal; the gilt corners a
    # little shinier and metal.
    orm = Image.new("RGB", (SHEET_PX, SHEET_PX), (255, 150, 0))
    od = ImageDraw.Draw(orm)
    od.ellipse([c[0] - R, c[1] - R, c[0] + R, c[1] + R], fill=(255, 120, 0))
    od.rectangle(LABEL_BOX, fill=(255, 235, 0))
    orm.save(os.path.join(common.MODELS, "wall_clock_dial_orm.png"))
    print("wall_clock_dial: sheet %d px" % SHEET_PX)


def _sheet_part(name, x0, y0, x1, y1, z, box_px):
    """A flat rectangle (x0..x1, y0..y1 at z, facing +z) on the sheet's `box_px` (x0, y0, x1, y1)."""
    bx0, by0, bx1, by1 = box_px
    part = Part(name, False).add([(x0, y0, z), (x1, y0, z), (x1, y1, z), (x0, y1, z)], [[0, 1, 2, 3]])
    u = lambda px: px / SHEET_PX
    v = lambda py: 1.0 - py / SHEET_PX
    part.uvs = [(u(bx0), v(by1)), (u(bx1), v(by1)), (u(bx1), v(by0)), (u(bx0), v(by0))]
    return part


def build():
    sheet()
    letters = lettering()
    cx, cy = wc.DIAL_C
    h = wc.SHEET
    dial = _sheet_part("Dial", cx - h, cy - h, cx + h, cy + h, wc.DIAL_Z, (0, 0, DIAL_PX, DIAL_PX))
    lw, lh, ly = LABEL
    label = _sheet_part("Label", -lw * 0.5, ly - lh * 0.5, lw * 0.5, ly + lh * 0.5, 0.0125, LABEL_BOX)
    parts = hands() + [(bezel(), "clock_brass")] + works() + pendulum() + latch() + letters
    # The hands and the pendulum's pieces as WallClock reads them: one object each.
    named = []
    for p, f in parts:
        if p.name in ("Pendulum", "spring", "bob", "nut"):
            continue
        named.append((p, f))
    # The pendulum's pieces, one object a finish (WallClock swings every "Pendulum*" part).
    for p, f in parts:
        if p.name in ("Pendulum", "spring", "bob", "nut"):
            p.name = {"Pendulum": "PendulumRod", "spring": "PendulumSpring", "bob": "PendulumBob", "nut": "PendulumNut"}[p.name]
            named.append((p, f))
    metal.export_baked("wall_clock", named + [(dial, None), (label, None)], size=1024)


if __name__ == "__main__":
    build()
