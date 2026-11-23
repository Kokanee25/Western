"""The general store's stock, batch G2 (#1172; numbers in tools/props/store_g2.py, refs
experiments/prop_lab/refs/store/): modelled here in the kit's space and baked the gun way (metal.py).

    ~/.venvs/studio/bin/python tools/blender/props/build.py --only=store_g2       (~5 min)
    ~/.venvs/studio/bin/python tools/blender/props/store_g2.py --only=goods,dry,hardware,mill,scales,swatches

Models (assets/props/models/<id>.glb and its _albedo/_orm sheets):
  store_goods     the shelves' rows: tins, cartons, flat boxes, packing cases; every label printed here
                  on one sheet (Pillow: period grocers' lines in the trade's lettering, no maker's names),
                  each face's UVs on it (as the doctor's books, doctor_d3.py)
  store_dry       boots, hats, the rope, the showcase's small goods (baked)
  store_hardware  the nail keg, the keg of tools, the oil can, the pail, the coffeepot, the kettle (baked)
  coffee_mill     the two-wheel counter mill (baked)
  store_scales    the even balance with hung pans and a pointer (baked)
  store_brass, store_iron   one flat plate each filling its atlas: the metal a fitted box (a yardstick, a
                  pull, a ladder rail) takes as a tiling look, since a mesh doesn't stretch with a fit

Then `godot --headless --import` and commit the .glb and .png files with their .import files.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import common  # noqa: E402
import metal  # noqa: E402
import store_g2 as N  # noqa: E402  (tools/props/store_g2.py: the numbers)
from common import Part, blob, box, lathe, moved, tube  # noqa: E402

FONT_DIR = "/usr/share/fonts/truetype/liberation/"
SHEET = 2048


def merged(name, parts, smooth=True):
    out = Part(name, smooth)
    for p in parts:
        out.merge(p)
    return out


def scaled(part, sx=1.0, sy=1.0, sz=1.0, name=None):
    out = Part(name or part.name, part.smooth)
    out.add([(x * sx, y * sy, z * sz) for x, y, z in part.verts], part.faces)
    return out


def shifted(part, d, name=None):
    out = Part(name or part.name, part.smooth)
    out.add([(x + d[0], y + d[1], z + d[2]) for x, y, z in part.verts], part.faces)
    return out


def turned_y(part, deg, about=(0.0, 0.0), name=None):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    ax, az = about
    out = Part(name or part.name, part.smooth)
    out.add([(ax + (x - ax) * c + (z - az) * s, y, az - (x - ax) * s + (z - az) * c) for x, y, z in part.verts], part.faces)
    return out


# === The labels' sheet ===========================================================================================
# Period colours (the chromolithographed can labels of the 1870s-80s: vermilion, chrome yellow, emerald,
# Prussian blue on cream; the cartons' paper printed one or two colours), and what each line sold.
VERMILION, CHROME, EMERALD, PRUSSIAN, CREAM, INK, BUFF, MAROON = (
    (196, 48, 30), (226, 170, 36), (36, 112, 58), (34, 52, 112), (236, 222, 184), (22, 18, 16), (204, 176, 120), (120, 30, 36))
LABELS = {
    "tins": [("TOMATOES", "CHOICE", VERMILION, CREAM, (200, 40, 30)), ("PEACHES", "CALIFORNIA", CHROME, MAROON, (230, 130, 50)),
             ("SUGAR CORN", "FANCY", EMERALD, CREAM, (230, 200, 60)), ("CONDENSED MILK", "EAGLE", PRUSSIAN, CREAM, (240, 236, 220)),
             ("PEARS", "BARTLETT", CREAM, EMERALD, (200, 190, 80)), ("STRING BEANS", "EXTRA", EMERALD, CHROME, (90, 140, 50)),
             ("BAKED BEANS", "BOSTON", MAROON, CREAM, (140, 70, 40)), ("PLUMS", "GREEN GAGE", PRUSSIAN, CHROME, (120, 60, 110))],
    "tins_flat": [("COVE OYSTERS", "BALTIMORE", PRUSSIAN, CREAM), ("SALMON", "COLUMBIA RIVER", VERMILION, CREAM),
                  ("SARDINES", "IN OIL", CHROME, INK), ("DEVILED HAM", "", MAROON, CHROME), ("LOBSTER", "", EMERALD, CREAM),
                  ("CLAMS", "LITTLE NECK", CREAM, PRUSSIAN)],
    "boxes": [("LAUNDRY SOAP", "10 BARS", CHROME, INK), ("CORN STARCH", "1 LB", PRUSSIAN, CREAM), ("BAKING POWDER", "ABSOLUTELY PURE", VERMILION, CREAM),
              ("SODA CRACKERS", "", CREAM, VERMILION), ("OOLONG TEA", "1/2 LB", EMERALD, CHROME), ("SALERATUS", "", BUFF, INK),
              ("MUSTARD", "ENGLISH", CHROME, MAROON), ("WASHING BLUE", "", PRUSSIAN, CHROME)],
    "boxes_flat": [(".44 CARTRIDGES", "50 CENTRE FIRE", (60, 110, 60), CREAM), ("PARLOR MATCHES", "", VERMILION, CHROME), ("PAPER COLLARS", "1 DOZ", CREAM, PRUSSIAN),
                   ("SPOOL COTTON", "200 YDS", PRUSSIAN, CREAM), ("CARPET TACKS", "", BUFF, INK), ("FISH HOOKS", "", EMERALD, CREAM),
                   ("PLUG TOBACCO", "NAVY", MAROON, CHROME), ("PERCUSSION CAPS", "", INK, CHROME)],
    "cases": [("CANNED GOODS", "2 DOZ  THIS SIDE UP"), ("SOAP", "100 BARS"), ("STARCH", "40 LBS"), ("TOMATOES", "2 DOZ 3 LB"),
              ("LAMP CHIMNEYS", "GLASS  WITH CARE"), ("DRY GOODS", "S. CREEK COL."), ("SODA CRACKERS", "BY THE POUND"), ("COFFEE", "ARBUCKLE BROS. N.Y.")],
    "cartons": [("SOAP", INK), ("STARCH", PRUSSIAN), ("MATCHES", VERMILION), ("TEA", EMERALD), ("SPICES", MAROON)],
}
# (The last case is stencilled with Arbuckle's: the roaster whose packaged coffee came west in such cases from
# 1873; a shipping mark, not a brand's label.)


def _font(style, size):
    from PIL import ImageFont
    name = {"bold": "LiberationSerif-Bold.ttf", "sans": "LiberationSans-Bold.ttf", "regular": "LiberationSerif-Regular.ttf"}[style]
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)


def _fit(draw, text, style, size, width):
    while size > 6:
        f = _font(style, size)
        if draw.textlength(text, font=f) <= width:
            return f
        size -= 1
    return _font(style, 6)


def _centred(draw, text, cy, f, cx, fill):
    l, t, r, b = draw.textbbox((0, 0), text, font=f)
    draw.text((cx - (r - l) * 0.5 - l, cy - (b - t) * 0.5 - t), text, font=f, fill=fill)


class Packer:
    """Rectangles laid in rows on the sheet."""

    def __init__(self):
        self.x, self.y, self.row = 4, 4, 0

    def take(self, w, h):
        if self.x + w > SHEET - 4:
            self.x, self.y, self.row = 4, self.y + self.row + 4, 0
        r = (self.x, self.y, self.x + w, self.y + h)
        self.x += w + 4
        self.row = max(self.row, h)
        assert self.y + h < SHEET, "the label sheet is full"
        return r


def _uv(rect, u, v):
    x0, y0, x1, y1 = rect
    return ((x0 + (x1 - x0) * u) / SHEET, 1.0 - (y1 + (y0 - y1) * v) / SHEET)


RECTS = {}   # name -> rect on the sheet


def sheet():
    """Every label, and the patches the plain faces take (tin plate, kraft, pine), on one albedo and ORM."""
    from PIL import Image, ImageDraw, ImageFilter
    rng = random.Random(1172)
    img = Image.new("RGB", (SHEET, SHEET), (120, 100, 80))
    orm = Image.new("RGB", (SHEET, SHEET), (255, 210, 0))
    d, o = ImageDraw.Draw(img), ImageDraw.Draw(orm)
    pk = Packer()

    def patch(name, w, h, color, rough, metal_, noise=14):
        r = pk.take(w, h)
        RECTS[name] = r
        for yy in range(r[1], r[3]):
            for xx in range(r[0], r[2], 2):
                n = rng.randint(-noise, noise)
                img.putpixel((xx, yy), tuple(max(0, min(255, c + n)) for c in color))
                if xx + 1 < r[2]:
                    img.putpixel((xx + 1, yy), tuple(max(0, min(255, c + n)) for c in color))
        o.rectangle(r, fill=(255, int(rough * 255), int(metal_ * 255)))
        return r

    patch("tinplate", 64, 64, (170, 168, 160), 0.3, 0.8, 18)
    patch("kraft", 64, 64, (150, 112, 70), 0.85, 0.0)
    patch("pine", 96, 96, (156, 116, 72), 0.88, 0.0, 22)
    for i, c in enumerate([VERMILION, CHROME, EMERALD, PRUSSIAN, CREAM, BUFF, MAROON, INK]):
        patch("paper%d" % i, 32, 32, c, 0.8, 0.0, 8)
    # Tall tins: a wrap-around label, its front (u 0.25 to 0.75: the half toward +z) the lettering; an oval
    # vignette of the fruit's colour; the back the same ground with a recipe's small print.
    for k, (name, sub, ground, letter, fruit) in enumerate(LABELS["tins"]):
        r = pk.take(320, 120)
        RECTS["tins%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=ground)
        d.rectangle((x0, y0 + 6, x1, y0 + 10), fill=letter)
        d.rectangle((x0, y1 - 10, x1, y1 - 6), fill=letter)
        cx = (x0 + x1) * 0.5
        d.ellipse((cx - 40, y0 + 18, cx + 40, y1 - 40), fill=CREAM if ground != CREAM else BUFF, outline=letter, width=3)
        d.ellipse((cx - 22, y0 + 28, cx + 22, y1 - 50), fill=fruit)
        _centred(d, name, y1 - 25, _fit(d, name, "bold", 24, 118), cx, letter)
        if sub:
            _centred(d, sub, y0 + 22, _fit(d, sub, "sans", 11, 70), cx - 105, letter)
            _centred(d, sub, y0 + 22, _fit(d, sub, "sans", 11, 70), cx + 105, letter)
        for j in range(5):
            d.line((x0 + 14, y0 + 40 + j * 9, x0 + 70, y0 + 40 + j * 9), fill=letter, width=2)
            d.line((x1 - 70, y0 + 40 + j * 9, x1 - 14, y0 + 40 + j * 9), fill=letter, width=2)
        o.rectangle(r, fill=(255, 200, 0))
    for k, (name, sub, ground, letter) in enumerate(LABELS["tins_flat"]):
        r = pk.take(360, 64)
        RECTS["tins_flat%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=ground)
        d.rectangle((x0, y0 + 3, x1, y0 + 6), fill=letter)
        d.rectangle((x0, y1 - 6, x1, y1 - 3), fill=letter)
        cx = (x0 + x1) * 0.5
        _centred(d, name, (y0 + y1) * 0.5 - (6 if sub else 0), _fit(d, name, "bold", 26, 170), cx, letter)
        if sub:
            _centred(d, sub, y1 - 15, _fit(d, sub, "sans", 11, 150), cx, letter)
        o.rectangle(r, fill=(255, 200, 0))
    # Cartons: a front (the lettering) and a side (the ground, a band).
    for k, (name, sub, ground, letter) in enumerate(LABELS["boxes"]):
        r = pk.take(120, 166)
        RECTS["boxes%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=ground)
        d.rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), outline=letter, width=3)
        words = name.split(" ")
        f = _fit(d, max(words, key=len), "bold", 30, 100)
        for j, w in enumerate(words):
            _centred(d, w, y0 + 52 + j * 34 - (len(words) - 1) * 8, f, (x0 + x1) * 0.5, letter)
        if sub:
            _centred(d, sub, y1 - 22, _fit(d, sub, "sans", 12, 96), (x0 + x1) * 0.5, letter)
        s = pk.take(90, 166)
        RECTS["boxes%d_side" % k] = s
        d.rectangle(s, fill=ground)
        d.rectangle((s[0], s[1] + 60, s[2], s[1] + 100), fill=letter)
        o.rectangle(r, fill=(255, 205, 0))
        o.rectangle(s, fill=(255, 205, 0))
    for k, (name, sub, ground, letter) in enumerate(LABELS["boxes_flat"]):
        r = pk.take(170, 64)
        RECTS["boxes_flat%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=ground)
        d.rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), outline=letter, width=2)
        _centred(d, name, (y0 + y1) * 0.5 - (7 if sub else 0), _fit(d, name, "bold", 24, 150), (x0 + x1) * 0.5, letter)
        if sub:
            _centred(d, sub, y1 - 14, _fit(d, sub, "sans", 10, 140), (x0 + x1) * 0.5, letter)
        o.rectangle(r, fill=(255, 205, 0))
    # Packing cases: pine, the end stencilled in black (the shipper's mark), nail heads at its corners.
    for k, (name, sub) in enumerate(LABELS["cases"]):
        r = pk.take(300, 236)
        RECTS["cases%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=(158 + rng.randint(-12, 12), 118 + rng.randint(-10, 10), 72))
        for j in range(1, 3):
            d.line((x0, y0 + j * 236 // 3, x1, y0 + j * 236 // 3), fill=(110, 80, 48), width=2)
        ink = (34, 28, 24)
        _centred(d, name, y0 + 92, _fit(d, name, "sans", 40, 260), (x0 + x1) * 0.5, ink)
        _centred(d, sub, y0 + 150, _fit(d, sub, "sans", 20, 250), (x0 + x1) * 0.5, ink)
        for nx, ny in ((x0 + 10, y0 + 10), (x1 - 10, y0 + 10), (x0 + 10, y1 - 10), (x1 - 10, y1 - 10)):
            d.ellipse((nx - 3, ny - 3, nx + 3, ny + 3), fill=(60, 55, 50))
        o.rectangle(r, fill=(255, 225, 0))
    for k, (name, letter) in enumerate(LABELS["cartons"]):
        r = pk.take(200, 100)
        RECTS["cartons%d" % k] = r
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=(150, 112, 70))
        _centred(d, name, (y0 + y1) * 0.5, _fit(d, name, "sans", 40, 170), (x0 + x1) * 0.5, letter)
        o.rectangle(r, fill=(255, 215, 0))
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    os.makedirs(common.MODELS, exist_ok=True)
    img.save(os.path.join(common.MODELS, "store_goods_albedo.png"))
    orm.save(os.path.join(common.MODELS, "store_goods_orm.png"))


# === The goods' shapes, their faces' UVs on the sheet ===============================================================
class Mesh:
    """A part whose every face carries its own UVs (vertices unshared: a vertex's UV is one face's)."""

    def __init__(self, name):
        self.part = Part(name, smooth=False)
        self.part.uvs = []

    def quad(self, pts, uvs):
        base = len(self.part.verts)
        self.part.verts.extend([tuple(float(c) for c in p) for p in pts])
        self.part.uvs.extend(uvs)
        self.part.faces.append([base + i for i in range(len(pts))])


def _flat_uv(rect):
    return [_uv(rect, 0.5, 0.5)] * 4


def add_box(m, size, at, turn, rects):
    """A box at `at` (its foot's middle), turned `turn` degrees about y; rects: front (+z), side, top."""
    w, h, dd = size
    c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))

    def P(x, y, z):
        return (at[0] + x * c + z * s, at[1] + y, at[2] - x * s + z * c)
    x0, x1, z0, z1 = -w * 0.5, w * 0.5, -dd * 0.5, dd * 0.5
    front, side, top = rects
    full = [(0, 0), (1, 0), (1, 1), (0, 1)]

    def face(pts, rect, st):
        m.quad([P(*p) for p in pts], [_uv(rect, a, b) for a, b in st] if st else _flat_uv(rect))
    face([(x0, 0, z1), (x1, 0, z1), (x1, h, z1), (x0, h, z1)], front, full)
    face([(x1, 0, z0), (x0, 0, z0), (x0, h, z0), (x1, h, z0)], side, full)
    face([(x1, 0, z1), (x1, 0, z0), (x1, h, z0), (x1, h, z1)], side, full)
    face([(x0, 0, z0), (x0, 0, z1), (x0, h, z1), (x0, h, z0)], side, full)
    face([(x0, h, z1), (x1, h, z1), (x1, h, z0), (x0, h, z0)], top, None)


def add_tin(m, r, h, at, turn, label):
    """A can: its side wrapped in `label` between rims of tin plate, its top tin plate; the label's
    front half to +z (`turn` turns it)."""
    n = 14
    tin = RECTS["tinplate"]
    rim = min(0.008, h * 0.12)
    rings = [(0.0, None), (rim, None), (h - rim, None), (h, None)]
    for k in range(n):
        a0 = 2 * math.pi * k / n + math.radians(turn)
        a1 = 2 * math.pi * (k + 1) / n + math.radians(turn)
        # u round the can: 0.5 at +z (sin(a) = 0 ... the angle measured from +z)
        u0, u1 = (k / n + 0.5) % 1.0, ((k + 1) / n + 0.5) % 1.0 or 1.0
        if u1 < u0:
            u1 = 1.0
        p = lambda a, y: (at[0] + math.sin(a) * r, at[1] + y, at[2] + math.cos(a) * r)
        for (ya, _), (yb, _) in zip(rings[:-1], rings[1:]):
            if ya == rim and yb == h - rim:
                m.quad([p(a0, ya), p(a1, ya), p(a1, yb), p(a0, yb)],
                       [_uv(label, u0, 0), _uv(label, u1, 0), _uv(label, u1, 1), _uv(label, u0, 1)])
            else:
                m.quad([p(a0, ya), p(a1, ya), p(a1, yb), p(a0, yb)], _flat_uv(tin))
        m.quad([(at[0], at[1] + h, at[2]), p(a1, h), p(a0, h)], [_uv(tin, 0.5, 0.5)] * 3)


def goods_part(kind, i):
    g = N.GOODS[kind]
    rng = random.Random("%s%d" % (kind, i))
    m = Mesh(N.part_name(kind, i))
    ix, iy, iz = g["item"]
    nx, ny, nz = g["grid"]
    xo = -0.15 if i == 0 else 0.15
    pitch = 0.3 / nx
    labels = LABELS[g["labels"]]
    for col in range(nx):
        lab = rng.randrange(len(labels))   # a column one line of goods, as a clerk stocks a facing
        for j in range(nz):
            zc = 0.155 - iz * 0.5 - j * (iz + 0.01)
            for lvl in range(ny):
                if lvl == ny - 1 and ny > 1 and rng.random() < 0.12:
                    continue  # (sold)
                x = xo - 0.15 + (col + 0.5) * pitch + rng.uniform(-0.003, 0.003)
                z = zc + rng.uniform(-0.004, 0.004)
                y = lvl * iy
                if kind in ("tins", "tins_flat"):
                    add_tin(m, ix * 0.5 - 0.001, iy - 0.001, (x, y, z), rng.uniform(-14, 14), RECTS["%s%d" % (kind, lab)])
                elif kind == "boxes":
                    add_box(m, (ix - 0.004, iy - 0.002, iz), (x, y, z), rng.uniform(-3, 3),
                            (RECTS["boxes%d" % lab], RECTS["boxes%d_side" % lab], RECTS["boxes%d_side" % lab]))
                elif kind == "boxes_flat":
                    lab2 = lab if rng.random() < 0.8 else rng.randrange(len(labels))
                    paper = RECTS["paper%d" % (lab2 % 8)]
                    add_box(m, (ix - 0.006, iy - 0.002, iz), (x, y, z), rng.uniform(-4, 4), (RECTS["boxes_flat%d" % lab2], paper, paper))
                elif kind == "cases":
                    k = (i * 3 + rng.randrange(len(LABELS["cases"]))) % len(LABELS["cases"])
                    add_box(m, (ix, iy, iz), (x, y, z), rng.uniform(-3, 3), (RECTS["cases%d" % k], RECTS["pine"], RECTS["pine"]))
                    tw, th, td = g["top"]
                    c = rng.randrange(len(LABELS["cartons"]))
                    add_box(m, (tw, th, td), (x + rng.uniform(-0.03, 0.03), y + iy, z + 0.05), rng.uniform(-10, 10),
                            (RECTS["cartons%d" % c], RECTS["kraft"], RECTS["kraft"]))
    return m.part


def goods():
    import doctor_d3  # (its export_plain: parts carrying their own UVs on a printed sheet)
    sheet()
    parts = [goods_part(kind, i) for kind in N.GOODS for i in (0, 1)]
    doctor_d3.export_plain("store_goods", parts)


# === Boots, hats, rope, the showcase's goods (store_dry, baked) =========================================================
def boot(x, toe_out):
    b = N.BOOT
    ank = 0.10
    shaft = tube("s", [(0, ank, -0.035), (0, 0.2, -0.04), (0, b["h"] - 0.004, -0.042)],
                 [(0.043, 0.052), (0.046, 0.056), (0.05, 0.06)], sides=14, caps=(False, True))
    foot = blob("f", (0.0, 0.052, 0.025), (0.046, 0.054, 0.125), rings=8, sides=14, squash_bottom=0.012)
    heel = box("h", (0.066, 0.034, 0.07), (0.0, 0.017, -0.085), bevel=0.006)
    sole = box("o", (0.084, 0.012, 0.25), (0.0, 0.006, 0.01), bevel=0.004)
    straps = [tube("p", [(sx * 0.045, b["h"] - 0.03, -0.042), (sx * 0.058, b["h"] + 0.01, -0.042), (sx * 0.05, b["h"] + 0.02, -0.042),
                         (sx * 0.04, b["h"] - 0.01, -0.042)], 0.004, sides=4) for sx in (-1, 1)]
    one = merged("b", [shaft, foot, heel, sole, *straps])
    return shifted(turned_y(one, toe_out), (x, 0, 0))


def boots():
    parts = []
    for i, x in enumerate((-0.13, 0.13)):
        g = N.BOOT["pair_gap"] * 0.5
        parts.append(merged("Boots%d" % i, [boot(x - g, -6), boot(x + g, 6)]))
    return parts


def hat(k, part_name):
    hh = N.HAT
    s = 1.0 + 0.035 * k
    top = hh["crown_h"]
    crown = lathe("c", [(0.0, top - 0.012), (0.03, top - 0.004), (0.058, top), (0.072, top - 0.012), (0.078, 0.06), (0.08, 0.012),
                        (0.074, 0.012), (0.072, 0.06), (0.066, top - 0.016), (0.052, top - 0.008), (0.0, top - 0.02)], 24, caps=(False, False))
    brim = lathe("r", [(0.08, 0.012), (0.12, 0.009), (0.16, 0.012), (0.17, 0.02), (0.167, 0.024), (0.156, 0.017), (0.118, 0.016),
                       (0.08, 0.019), (0.08, 0.012)], 28, caps=(False, False))
    band = lathe("b", [(0.0805, 0.019), (0.0815, 0.04), (0.08, 0.04)], 24, caps=(False, False))
    one = merged(part_name, [crown, brim, band])
    one = scaled(one, 1.06 * s, s, 0.95 * s, part_name)
    return shifted(one, (0, k * hh["nest"], 0), part_name)


def rope():
    pts = []
    turns, per = 4.5, 36
    for j in range(int(turns * per) + 1):
        a = 2 * math.pi * j / per
        layer = j / per
        rr = 0.155 - 0.022 * (layer % 1.5)
        pts.append((math.cos(a) * rr, 0.011 + 0.018 * min(layer, 3.5) / 3.5 * 3.2 * 0.5, math.sin(a) * rr))
    coil = tube("Rope", pts, 0.0105, sides=7, noise=0.08, seed=3)
    end = tube("e", [pts[-1], (pts[-1][0] + 0.06, 0.012, pts[-1][2] + 0.12), (pts[-1][0] + 0.02, 0.011, pts[-1][2] + 0.2)], 0.0105, sides=7)
    return merged("Rope", [coil, end])


def case_goods():
    c = N.SHOWCASE
    b = c["base"]
    rng = random.Random(1173)
    spools, knives, pipes = [], [], []
    for k in range(9):  # spools of thread in a block
        x = -0.42 + (k % 3) * 0.05
        z = -0.06 + (k // 3) * 0.05
        spools.append(lathe("s", [(0.0, b), (0.02, b), (0.02, b + 0.004), (0.016, b + 0.006), (0.016, b + 0.04), (0.02, b + 0.042),
                                  (0.02, b + 0.046), (0.0, b + 0.046)], 10, at=(x, 0, z)))
    for k in range(4):  # pocket knives laid on a card
        x = -0.15 + k * 0.07
        knives.append(box("k", (0.022, 0.012, 0.095), (x, b + 0.006, rng.uniform(-0.05, 0.02)), bevel=0.003))
    card = box("c", (0.3, 0.004, 0.16), (-0.045, b + 0.002, -0.02))
    for k in range(3):  # clay and briar pipes
        x = 0.16 + k * 0.08
        bowl = lathe("p", [(0.0, b), (0.014, b), (0.016, b + 0.03), (0.012, b + 0.032), (0.0, b + 0.012)], 10, at=(x, 0, 0.0))
        stem = tube("t", [(x, b + 0.01, 0.0), (x, b + 0.006, -0.11)], 0.004, sides=5)
        pipes += [bowl, stem]
    combs = [box("m", (0.12, 0.004, 0.035), (0.4, b + 0.002 + k * 0.005, -0.04 + k * 0.03), bevel=0.001) for k in range(3)]
    return (merged("CaseGoods", spools + [card]), merged("CaseKnives", knives), merged("CasePipes", pipes + combs))


def dry():
    parts = [(p, f) for p, f in zip(boots(), ("boot_leather", "russet_leather"))]
    parts += [(hat(0, "HatBlack"), "felt"), (hat(1, "HatBrown"), "felt_brown"), (hat(2, "HatBuff"), "felt_buff"),
              (hat(0, "HatSingle"), "felt_buff")]  # (the single one: the buff hat set down on its own brim)
    parts.append((rope(), "hemp"))
    g, k, p = case_goods()
    parts += [(g, "linen"), (k, "steel"), (p, "apple_wood")]
    metal.export_baked("store_dry", parts, size=1024)


# === Hardware and tinware (store_hardware, baked) =====================================================================
def keg():
    k = N.KEG
    r, bul, h = k["r"], k["bulge"], k["h"]
    prof = [(0.0, 0.012), (r - 0.004, 0.012), (r, 0.0)]
    for j in range(1, 8):
        t = j / 8
        prof.append((r + (bul - r) * math.sin(math.pi * t), h * t))
    prof += [(r, h), (r - 0.012, h), (r - 0.014, h - 0.02), (r + (bul - r) * 0.9 - 0.014, h * 0.5), (r - 0.016, 0.06), (0.0, 0.06)]
    staves = lathe("KegStaves", prof, 22, caps=(False, False))
    hoops = []
    for y in (0.03, 0.1, h - 0.1, h - 0.03):
        t = y / h
        rr = r + (bul - r) * math.sin(math.pi * t) + 0.002
        hoops.append(lathe("o", [(rr, y - 0.012), (rr + 0.003, y - 0.01), (rr + 0.003, y + 0.01), (rr, y + 0.012)], 22, caps=(False, False)))
    return staves, merged("KegHoops", hoops)


def nails():
    k = N.KEG
    return blob("Nails", (0.0, k["body_h"] - 0.005, 0.0), (0.13, 0.05, 0.13), rings=6, sides=16, squash_bottom=k["body_h"] - 0.03, noise=0.22, seed=11)


def tools():
    k = N.KEG
    y0 = 0.08
    handles, heads = [], []
    for ang, lean, length, kind in ((20, 9, 0.92, "axe"), (150, 7, 1.05, "shovel"), (270, 11, 0.98, "hoe")):
        a = math.radians(ang)
        dx, dz = math.cos(a), math.sin(a)
        foot = (dx * 0.04, y0, dz * 0.04)
        tl = math.radians(lean)
        top = (foot[0] + dx * math.sin(tl) * length, y0 + math.cos(tl) * length, foot[2] + dz * math.sin(tl) * length)
        handles.append(tube("h", [foot, top], (0.016, 0.014) if kind == "axe" else 0.017, sides=8))
        if kind == "axe":
            heads.append(shifted(turned_y(box("a", (0.17, 0.075, 0.022), (0.04, -0.01, 0.0), bevel=0.004), -ang), top))
        elif kind == "shovel":
            blade = box("s", (0.22, 0.27, 0.006), (0.0, 0.135, 0.0), bevel=0.002)
            heads.append(shifted(turned_y(blade, 90 - ang), (top[0], top[1] - 0.02, top[2])))
        else:
            heads.append(shifted(turned_y(box("o", (0.16, 0.1, 0.005), (0.0, 0.02, 0.03), bevel=0.002), 90 - ang), top))
    return merged("ToolHandles", handles), merged("ToolHeads", heads)


def oil_can():
    body = box("c", (0.235, 0.33, 0.235), (0.0, 0.165, 0.0), bevel=0.006)
    seam = box("s", (0.24, 0.008, 0.24), (0.0, 0.33, 0.0), bevel=0.002)
    cap = lathe("p", [(0.0, 0.33), (0.022, 0.33), (0.022, 0.352), (0.016, 0.356), (0.0, 0.356)], 10, at=(0.06, 0, 0.06))
    bail = tube("b", [(-0.09, 0.334, 0.0), (-0.07, 0.37, 0.0), (0.0, 0.385, 0.0), (0.07, 0.37, 0.0), (0.09, 0.334, 0.0)], 0.003, sides=5)
    return merged("OilCan", [body, seam, cap, bail], smooth=False)


def pail():
    body = lathe("p", [(0.0, 0.0), (0.105, 0.0), (0.108, 0.006), (0.137, 0.24), (0.142, 0.245), (0.138, 0.25), (0.133, 0.243), (0.104, 0.012), (0.0, 0.012)],
                 24, caps=(False, False))
    bands = [lathe("r", [(0.115 + 0.022 * t, 0.06 + 0.18 * t - 0.004), (0.118 + 0.022 * t, 0.06 + 0.18 * t), (0.115 + 0.022 * t, 0.06 + 0.18 * t + 0.004)], 24,
                   caps=(False, False)) for t in (0.0, 0.66)]
    bail = tube("b", [(-0.14, 0.22, 0.0)] + [(-0.14 * math.cos(math.pi * t), 0.22 + 0.13 * math.sin(math.pi * t), 0.0) for t in (0.2, 0.4, 0.6, 0.8)]
                + [(0.14, 0.22, 0.0)], 0.0025, sides=5)
    return merged("Pail", [body, *bands, bail])


def coffeepot():
    body = lathe("b", [(0.0, 0.0), (0.075, 0.0), (0.077, 0.006), (0.052, 0.2), (0.056, 0.203), (0.0, 0.203)], 22)
    lid = lathe("l", [(0.0, 0.2), (0.055, 0.2), (0.05, 0.215), (0.03, 0.222), (0.01, 0.224), (0.008, 0.236), (0.0, 0.238)], 18)
    spout = tube("s", [(0.06, 0.04, 0.0), (0.09, 0.1, 0.0), (0.105, 0.17, 0.0)], [(0.016, 0.016), (0.011, 0.011), (0.008, 0.008)], sides=8, caps=(False, False))
    handle = tube("h", [(-0.07, 0.04, 0.0), (-0.105, 0.07, 0.0), (-0.1, 0.15, 0.0), (-0.06, 0.18, 0.0)], [(0.004, 0.012)] * 4, sides=6, up_hint=(0, 0, 1))
    return merged("Coffeepot", [body, lid, spout, handle])


def kettle():
    body = lathe("b", [(0.0, 0.0), (0.1, 0.0), (0.112, 0.03), (0.11, 0.09), (0.08, 0.135), (0.058, 0.142), (0.058, 0.15), (0.0, 0.15)], 22)
    lid = lathe("l", [(0.0, 0.15), (0.06, 0.15), (0.04, 0.162), (0.01, 0.165), (0.008, 0.176), (0.0, 0.178)], 16)
    spout = tube("s", [(0.0, 0.04, 0.1), (0.0, 0.08, 0.135), (0.0, 0.12, 0.155)], [(0.015, 0.015), (0.01, 0.01), (0.007, 0.007)], sides=8, caps=(False, False))
    bail = tube("a", [(-0.07, 0.13, 0.0), (-0.06, 0.2, 0.0), (0.0, 0.22, 0.0), (0.06, 0.2, 0.0), (0.07, 0.13, 0.0)], 0.004, sides=6)
    return merged("Kettle", [body, lid, spout, bail])


def hardware():
    staves, hoops = keg()
    th, tk = tools()
    parts = [(staves, "box_pine"), (hoops, "sheet_iron"), (nails(), "cast_iron"), (th, "turned_wood"), (tk, "saw_steel"),
             (oil_can(), "tin"), (pail(), "tin"), (coffeepot(), "tin_bright"), (kettle(), "tin")]
    metal.export_baked("store_hardware", parts, size=1024)


# === The coffee mill (baked) ===============================================================================================
def mill():
    m = N.MILL
    ay, wx, R = m["axle_y"], m["wheel_x"], m["wheel_r"]
    base = box("a", (0.22, 0.035, 0.2), (0.0, 0.0175, 0.0), bevel=0.006)
    drawer = box("d", (0.15, 0.1, 0.15), (0.0, 0.09, 0.0), bevel=0.004)
    column = lathe("c", [(0.06, 0.14), (0.05, 0.16), (0.045, ay - 0.08), (0.075, ay - 0.04), (0.085, ay), (0.075, ay + 0.04), (0.05, ay + 0.08),
                         (0.04, m["h"] - 0.08), (0.05, m["h"] - 0.07), (0.0, m["h"] - 0.07)], 20)
    axle = tube("x", [(-wx, ay, 0.0), (wx, ay, 0.0)], 0.014, sides=10)
    body = merged("Body", [base, drawer, column, axle])
    hopper = lathe("Hopper", [(0.03, m["h"] - 0.075), (0.05, m["h"] - 0.06), (0.1, m["h"] + 0.02), (0.104, m["h"] + 0.03), (0.096, m["h"] + 0.03),
                              (0.046, m["h"] - 0.05), (0.0, m["h"] - 0.05)], 24, caps=(False, False))
    wheels = []
    for s_, name in ((-1, "WheelL"), (1, "WheelR")):
        x = s_ * wx
        rim = tube("r", [(x, ay + math.sin(2 * math.pi * k / 40) * R, math.cos(2 * math.pi * k / 40) * R) for k in range(41)], [(0.012, 0.018)] * 41, sides=6, caps=(False, False))
        hub = lathe("h", [(0.0, -0.025), (0.035, -0.02), (0.035, 0.02), (0.0, 0.025)], 12, axis="x", at=(x, ay, 0.0))
        spokes = []
        for k in range(6):
            a = 2 * math.pi * k / 6
            a2 = a + 0.25
            spokes.append(tube("s", [(x, ay + math.sin(a) * 0.03, math.cos(a) * 0.03), (x, ay + math.sin(a + 0.12) * R * 0.55, math.cos(a + 0.12) * R * 0.55),
                                     (x, ay + math.sin(a2) * (R - 0.01), math.cos(a2) * (R - 0.01))], [(0.008, 0.012)] * 3, sides=6))
        parts = [rim, hub, *spokes]
        if s_ > 0:  # the handle on the right wheel's rim
            parts.append(lathe("k", [(0.0, 0.0), (0.012, 0.005), (0.014, 0.09), (0.0, 0.095)], 8, axis="x", at=(x + 0.005, ay + R * 0.85, 0.0)))
        wheels.append(merged(name, parts))
    metal.export_baked("coffee_mill", [(body, "mill_red"), (hopper, "brass_old"), (wheels[0], "mill_red"), (wheels[1], "mill_red")], size=1024)


# === The scales (baked) ======================================================================================================
def scales():
    c = N.SCALES
    bx, by, bz = c["base"]
    base = merged("Base", [box("b", (bx, by - 0.012, bz), (0.0, 0.012 + (by - 0.012) * 0.5, 0.0), bevel=0.008)]
                  + [box("f", (0.04, 0.012, 0.04), (sx * (bx * 0.5 - 0.03), 0.006, sz * (bz * 0.5 - 0.03)), bevel=0.003) for sx in (-1, 1) for sz in (-1, 1)])
    top = c["beam_y"]
    pillar = lathe("Pillar", [(0.035, by), (0.028, by + 0.012), (0.016, by + 0.03), (0.013, top - 0.07), (0.018, top - 0.06), (0.018, top - 0.04),
                              (0.012, top - 0.03), (0.012, top - 0.01), (0.0, top - 0.01)], 18)
    plate = box("p", (0.08, 0.05, 0.004), (0.0, by + 0.09, 0.018), bevel=0.001)
    lx = c["beam_len"]
    beam = tube("b", [(-lx * 0.5, top, 0.0), (0.0, top, 0.0), (lx * 0.5, top, 0.0)], [(0.004, 0.005), (0.007, 0.011), (0.004, 0.005)], sides=8, up_hint=(0, 1, 0))
    hub = lathe("h", [(0.0, -0.009), (0.013, -0.008), (0.013, 0.008), (0.0, 0.009)], 16, axis="z", at=(0.0, top, 0.0))
    pointer = tube("n", [(0.0, top - 0.01, 0.022), (0.0, by + 0.075, 0.022)], [(0.002, 0.002), (0.001, 0.001)], sides=5)
    ends = [lathe("k", [(0.0, -0.006), (0.006, -0.005), (0.006, 0.006), (0.0, 0.007)], 8, at=(s_ * (lx * 0.5 - 0.02), top - 0.004, 0.0)) for s_ in (-1, 1)]
    beam_part = merged("Beam", [beam, hub, pointer, plate, *ends])
    pans = []
    R, py = c["pan_r"], c["pan_y"]
    for s_, name in ((-1, "PanL"), (1, "PanR")):
        x = s_ * (lx * 0.5 - 0.02)
        dish = lathe("d", [(0.0, py - 0.003), (R * 0.6, py - 0.002), (R * 0.92, py + 0.016), (R, py + 0.024), (R - 0.003, py + 0.025), (R * 0.9, py + 0.017),
                           (R * 0.58, py + 0.002), (0.0, py + 0.001)], 28, at=(x, 0, 0.0), caps=(False, False))
        wires = []
        for k in range(3):
            a = 2 * math.pi * k / 3 + math.pi * 0.5
            wires.append(tube("w", [(x + math.cos(a) * (R - 0.006), py + 0.024, math.sin(a) * (R - 0.006)), (x, top - 0.012, 0.0)], 0.0012, sides=5))
        ring = lathe("r", [(0.007, top - 0.016), (0.009, top - 0.012), (0.007, top - 0.008)], 10, at=(x, 0, 0.0), caps=(False, False))
        pans.append(merged(name, [dish, ring, *wires]))
    metal.export_baked("store_scales", [(base, "japanned"), (merged("Pillar", [pillar]), "japanned"), (beam_part, "brass_old"),
                                         (pans[0], "brass_old"), (pans[1], "brass_old")], size=512)


# === The swatches ============================================================================================================
def swatches():
    for model, finish in (("store_brass", "brass_old"), ("store_iron", "cast_iron")):
        plate = Part("Plate", smooth=False).add([(-0.5, 0.0, -0.5), (0.5, 0.0, -0.5), (0.5, 0.0, 0.5), (-0.5, 0.0, 0.5)], [[0, 3, 2, 1]])
        metal.export_baked(model, [(plate, finish)], size=256)


STEPS = {"goods": goods, "dry": dry, "hardware": hardware, "mill": mill, "scales": scales, "swatches": swatches}


def build(only=None):
    for name, step in STEPS.items():
        if only and name not in only:
            continue
        step()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    build(only)
