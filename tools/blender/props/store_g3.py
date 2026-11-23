"""The general store's batch G3 (#1182; numbers in tools/props/store_g3.py): the post office's mail and sign, the
ledger and day-book, the ink, the till's cash, a stack of parcels (all on one printed sheet, `store_post`, as G2's
goods), and the goods hung from the ceiling (`hung_pails`, `hung_ham`, `hung_lantern`, baked the gun way).

    ~/.venvs/studio/bin/python tools/blender/props/build.py --only=store_g3
    ~/.venvs/studio/bin/python tools/blender/props/store_g3.py --only=post,hung

Models (assets/props/models/<id>.glb and its _albedo/_orm sheets):
  store_post  Sign (the lettered board), MailA..MailD (a row of pigeonholes each: letters on edge, bundles, parcels,
              a card at each cell), Ledger, DayBook, Ink, Cash, Parcels: every face's UVs on one printed sheet
  hung_pails, hung_ham, hung_lantern  (Pails, Hams, Lantern and their Cords; the lantern's Globe is glass: the game's)
"""
import importlib.util
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import common  # noqa: E402
import metal  # noqa: E402
from common import Part, blob, box, lathe, tube  # noqa: E402

# The numbers: tools/props/store_g3.py (loaded by path: build.py already holds this file under that name).
_num = importlib.util.spec_from_file_location("store_g3_numbers", os.path.join(HERE, "..", "..", "props", "store_g3.py"))
N = importlib.util.module_from_spec(_num)
_num.loader.exec_module(N)

# G2's helpers (the Mesh that carries its own UVs, the label sheet's packer, its fonts and Pillow bits).
_spec = importlib.util.spec_from_file_location("blender_store_g2", os.path.join(HERE, "store_g2.py"))
G2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G2)
Mesh, Packer, SHEET = G2.Mesh, G2.Packer, G2.SHEET
shifted, merged = G2.shifted, G2.merged

CREAM, INK_C, MAROON, PRUSSIAN, VERMILION, EMERALD = (236, 222, 184), (30, 24, 20), (120, 30, 36), (34, 52, 112), (196, 48, 30), (36, 112, 58)
RECTS = {}


def _uv(rect, u, v):
    x0, y0, x1, y1 = rect
    return ((x0 + (x1 - x0) * u) / SHEET, 1.0 - (y1 + (y0 - y1) * v) / SHEET)


def _flat(rect):
    return [_uv(rect, 0.5, 0.5)] * 4


# === The printed sheet ===========================================================================================
def _scribble(d, rng, x0, y0, x1, y1, ink, lines, height=14, gap=22, fill=0.9):
    """A clerk's hand: rows of wobbling strokes where the words are (not letters: nothing to read at a metre)."""
    y = y0
    for _ in range(lines):
        x = x0 + rng.randint(0, 12)
        end = x0 + (x1 - x0) * rng.uniform(0.55, fill)
        while x < end:
            w = rng.randint(10, 46)
            pts = [(x + i * w / 6.0, y + math.sin(i * 1.7 + rng.random()) * height * 0.28 + rng.uniform(-2, 2)) for i in range(7)]
            d.line(pts, fill=ink, width=2)
            x += w + rng.randint(8, 16)
        y += gap
        if y > y1:
            break


def sheet():
    from PIL import Image, ImageDraw, ImageFilter
    rng = random.Random(1182)
    img = Image.new("RGB", (SHEET, SHEET), (120, 100, 80))
    orm = Image.new("RGB", (SHEET, SHEET), (255, 220, 0))
    d, o = ImageDraw.Draw(img), ImageDraw.Draw(orm)
    pk = Packer()

    def take(name, w, h, rough=0.88, metal_=0.0):
        r = pk.take(w, h)
        RECTS[name] = r
        o.rectangle(r, fill=(255, int(rough * 255), int(metal_ * 255)))
        return r

    def patch(name, w, h, color, rough=0.88, metal_=0.0, noise=14):
        r = take(name, w, h, rough, metal_)
        for yy in range(r[1], r[3]):
            for xx in range(r[0], r[2]):
                n = rng.randint(-noise, noise)
                img.putpixel((xx, yy), tuple(max(0, min(255, c + n)) for c in color))
        return r

    patch("paper_edge", 96, 64, (222, 210, 172), 0.9, 0.0, 10)
    for y in range(RECTS["paper_edge"][1] + 3, RECTS["paper_edge"][3], 4):
        d.line((RECTS["paper_edge"][0], y, RECTS["paper_edge"][2], y), fill=(190, 176, 140), width=1)
    patch("kraft", 96, 96, (156, 116, 72), 0.9, 0.0, 22)
    patch("leather", 96, 96, (60, 38, 24), 0.55, 0.0, 14)
    patch("tin", 64, 64, (170, 168, 160), 0.3, 0.8, 18)
    patch("silver", 48, 48, (196, 196, 188), 0.3, 0.9, 12)
    patch("copper", 48, 48, (150, 84, 48), 0.4, 0.9, 12)
    patch("ink_glass", 64, 64, (20, 22, 40), 0.08, 0.0, 6)
    patch("pen_wood", 32, 32, (60, 30, 20), 0.5, 0.0, 6)
    patch("steel", 32, 32, (150, 150, 152), 0.25, 0.9, 8)
    patch("tag", 48, 48, (214, 200, 150), 0.85, 0.0, 10)

    # Envelopes: cream, buff, blue-grey, manila: the front with a stamp and the address in a clerk's hand.
    for k, col in enumerate([(236, 224, 190), (206, 178, 124), (160, 172, 186), (196, 162, 100)]):
        r = take("env%d" % k, 160, 100)
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=col)
        d.polygon([(x0, y0), (x1, y0), ((x0 + x1) // 2, y0 + 46)], outline=tuple(max(0, c - 40) for c in col))
        d.rectangle((x1 - 34, y0 + 8, x1 - 10, y0 + 34), fill=VERMILION if k % 2 == 0 else EMERALD)
        _scribble(d, rng, x0 + 22, y0 + 54, x1 - 14, y1 - 6, INK_C, 3, height=14, gap=14, fill=0.8)
    # A parcel's wrapping: brown paper tied with string crossways, a tag.
    r = take("parcel", 192, 128)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(150, 110, 68))
    for _ in range(40):
        yy = rng.randint(y0, y1)
        d.line((x0, yy, x1, yy + rng.randint(-2, 2)), fill=(138, 100, 60), width=1)
    d.line(((x0 + x1) // 2, y0, (x0 + x1) // 2, y1), fill=(222, 206, 160), width=3)
    d.line((x0, (y0 + y1) // 2, x1, (y0 + y1) // 2), fill=(222, 206, 160), width=3)
    d.rectangle(((x0 + x1) // 2 + 6, y0 + 8, (x0 + x1) // 2 + 44, y0 + 36), fill=(226, 214, 170))
    _scribble(d, rng, (x0 + x1) // 2 + 9, y0 + 14, (x0 + x1) // 2 + 42, y0 + 34, INK_C, 2, height=6, gap=9)
    # A card at each cell: the surname's group in ink on cream.
    for k, text in enumerate(N.LABELS):
        r = take("lab%d" % k, 160, 56)
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=(232, 220, 182))
        d.rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), outline=(150, 120, 80), width=2)
        G2._centred(d, text, (y0 + y1) * 0.5, G2._fit(d, text, "bold", 40, 140), (x0 + x1) * 0.5, INK_C)
    # The lettered board: gilt on dark green.
    r = take("sign", 1536, 300, 0.45)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(24, 54, 38))
    d.rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), outline=(196, 160, 70), width=6)
    G2._centred(d, "POST OFFICE", y0 + 118, G2._fit(d, "POST OFFICE", "bold", 150, 1100), (x0 + x1) * 0.5, (214, 176, 80))
    G2._centred(d, "SALT CREEK  ·  COLORADO", y0 + 238, G2._fit(d, "SALT CREEK  ·  COLORADO", "sans", 54, 1000), (x0 + x1) * 0.5, (214, 176, 80))
    # The ledger's cover: marbled paper, leather spine and corners, a label.
    r = take("ledger_top", 256, 352, 0.7)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(70, 40, 40))
    for _ in range(120):
        cx, cy = rng.randint(x0, x1), rng.randint(y0, y1)
        rr = rng.randint(6, 24)
        d.ellipse((cx - rr, cy - rr // 2, cx + rr, cy + rr // 2), outline=rng.choice([(110, 60, 50), (50, 56, 90), (150, 120, 80), (40, 70, 60)]), width=2)
    d.rectangle((x0, y0, x0 + 30, y1), fill=(48, 30, 20))
    for cx, cy in ((x1 - 44, y0), (x1 - 44, y1 - 44)):
        d.rectangle((cx, cy, x1, cy + 44), fill=(48, 30, 20))
    d.rectangle((x0 + 80, y0 + 110, x1 - 70, y0 + 200), fill=(226, 212, 170), outline=(30, 20, 14), width=3)
    G2._centred(d, "LEDGER", y0 + 156, G2._fit(d, "LEDGER", "bold", 48, 100), (x0 + 80 + x1 - 70) * 0.5, INK_C)
    # The day-book's two pages: ruled, columned, written down the left page.
    for name, written in (("db_left", True), ("db_right", False)):
        r = take(name, 230, 300, 0.9)
        x0, y0, x1, y1 = r
        d.rectangle(r, fill=(226, 214, 176))
        for yy in range(y0 + 40, y1 - 8, 15):
            d.line((x0 + 6, yy, x1 - 6, yy), fill=(150, 160, 190), width=1)
        for xx in (x0 + 34, x0 + 150, x0 + 186):
            d.line((xx, y0 + 6, xx, y1 - 6), fill=(190, 120, 110), width=1)
        d.line((x0 + 6, y0 + 28, x1 - 6, y0 + 28), fill=(40, 40, 50), width=2)
        if written:
            _scribble(d, rng, x0 + 8, y0 + 46, x1 - 8, y1 - 60, (28, 26, 60), 14, height=9, gap=15, fill=0.95)
        else:
            _scribble(d, rng, x0 + 8, y0 + 46, x1 - 8, y0 + 100, (28, 26, 60), 3, height=9, gap=15, fill=0.8)
    # A bundle of notes: the face of a one-dollar greenback (a plain green panel with a border and a number, no portrait).
    r = take("note", 160, 70, 0.8)
    x0, y0, x1, y1 = r
    d.rectangle(r, fill=(150, 176, 130))
    d.rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), outline=(40, 80, 50), width=3)
    G2._centred(d, "ONE", (y0 + y1) * 0.5, G2._fit(d, "ONE", "bold", 36, 60), (x0 + x1) * 0.5, (40, 80, 50))
    img = img.filter(ImageFilter.GaussianBlur(0.5))
    os.makedirs(common.MODELS, exist_ok=True)
    img.save(os.path.join(common.MODELS, "store_post_albedo.png"))
    orm.save(os.path.join(common.MODELS, "store_post_orm.png"))


# === Shapes on the sheet ============================================================================================
def bx(m, size, at, turn, front, side=None, top=None, ends=None, top_uv=True):
    """A box standing on its foot at `at`, turned `turn` degrees about y; rects for the front (+z), the sides
    (the ends along x take `ends`, else `side`) and the top, whose UVs run across it (u along x, v back from +z)."""
    w, h, dd = size
    side = side or front
    ends = ends or side
    top = top or side
    c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))

    def P(x, y, z):
        return (at[0] + x * c + z * s, at[1] + y, at[2] - x * s + z * c)
    x0, x1, z0, z1 = -w * 0.5, w * 0.5, -dd * 0.5, dd * 0.5
    full = [(0, 0), (1, 0), (1, 1), (0, 1)]

    def face(pts, rect, uv=True):
        m.quad([P(*p) for p in pts], [_uv(rect, a, b) for a, b in full] if uv else _flat(rect))
    face([(x0, 0, z1), (x1, 0, z1), (x1, h, z1), (x0, h, z1)], front)
    face([(x1, 0, z0), (x0, 0, z0), (x0, h, z0), (x1, h, z0)], side, False)
    face([(x1, 0, z1), (x1, 0, z0), (x1, h, z0), (x1, h, z1)], ends, False)
    face([(x0, 0, z0), (x0, 0, z1), (x0, h, z1), (x0, h, z0)], ends, False)
    face([(x0, h, z1), (x1, h, z1), (x1, h, z0), (x0, h, z0)], top, top_uv)


def cyl(m, r, h, at, rect, n=10, rect_top=None):
    top_r = rect_top or rect
    for k in range(n):
        a0, a1 = 2 * math.pi * k / n, 2 * math.pi * (k + 1) / n
        p = lambda a, y: (at[0] + math.sin(a) * r, at[1] + y, at[2] + math.cos(a) * r)
        m.quad([p(a0, 0), p(a1, 0), p(a1, h), p(a0, h)], _flat(rect))
        m.quad([(at[0], at[1] + h, at[2]), p(a1, h), p(a0, h)], [_uv(top_r, 0.5, 0.5)] * 3)


# --- The mail ----------------------------------------------------------------------------------------------------
def mail_part(k):
    rng = random.Random("mail%d" % k)
    m = Mesh("Mail" + "ABCD"[k])
    p = N.cell_pitch()
    cols = N.CASE["cols"]
    L = N.CASE["L"] - 0.06
    mail = N.MAIL
    z_front = mail["z"] + mail["depth"] * 0.5     # the row's member's front: its cards 1 cm in front of the mail
    for i in range(cols):
        cx = -L * 0.5 + p * i + (p - N.CASE["divider"]) * 0.5
        what = rng.random()
        env = lambda: RECTS["env%d" % rng.randrange(4)]
        if what < 0.2:
            pass   # an empty cell
        elif what < 0.7:
            # letters on edge: two bundles, the back one taller, each a few degrees from the other
            for j, (hh, dz) in enumerate(((0.145, -0.06), (0.1, 0.0))):
                if rng.random() < 0.8 or j == 0:
                    bx(m, (0.125, hh, 0.035 + rng.random() * 0.025), (cx + rng.uniform(-0.02, 0.02), 0.0, mail["z"] + dz), rng.uniform(-6, 6),
                       env(), RECTS["paper_edge"], RECTS["paper_edge"])
        elif what < 0.85:
            bx(m, (0.15, 0.11, 0.12), (cx, 0.0, mail["z"] - 0.02), rng.uniform(-5, 5), RECTS["parcel"], RECTS["kraft"], RECTS["parcel"])
        else:
            # a flat bundle tied with string, a card standing on it
            bx(m, (0.15, 0.035, 0.1), (cx, 0.0, mail["z"]), rng.uniform(-4, 4), RECTS["paper_edge"], RECTS["paper_edge"], env(), top_uv=True)
            bx(m, (0.11, 0.06, 0.03), (cx, 0.035, mail["z"] + 0.03), rng.uniform(-8, 8), env(), RECTS["paper_edge"], RECTS["paper_edge"])
        # the card on the board's lip: it stands on the board in front of the cell
        lab = k * cols + i
        bx(m, (0.08, 0.03, 0.004), (cx, 0.0, z_front - 0.004), 0, RECTS["lab%d" % lab], RECTS["paper_edge"], RECTS["paper_edge"])
    return m.part


def sign_part():
    m = Mesh("Sign")
    c = N.CASE
    top = c["y0"] + c["rows"] * c["row_pitch"] + c["board"] * 0.5
    y0 = top + 0.08
    bx(m, (c["L"] - 0.2, c["sign_h"], 0.03), (c["d"] * 0.5 - 0.02, y0, 0.0), 90, RECTS["sign"], RECTS["leather"], RECTS["leather"], top_uv=False)
    return m.part


# --- The books -----------------------------------------------------------------------------------------------------
def ledger_part():
    b = N.BOOK
    m = Mesh("Ledger")
    bx(m, (b["w"], b["h"], b["d"]), (0, 0, 0), 0, RECTS["paper_edge"], RECTS["leather"], RECTS["ledger_top"], ends=RECTS["paper_edge"])
    return m.part


def daybook_part():
    b = N.DAYBOOK
    m = Mesh("DayBook")
    bx(m, (b["w"] + 0.012, 0.008, b["d"] + 0.012), (0, 0, 0), 0, RECTS["leather"], RECTS["leather"], RECTS["leather"], top_uv=False)
    hw = b["w"] * 0.5
    bx(m, (hw - 0.002, b["h"] - 0.008, b["d"]), (-hw * 0.5 - 0.001, 0.008, 0), 0, RECTS["paper_edge"], RECTS["paper_edge"], RECTS["db_left"])
    bx(m, (hw - 0.002, b["h"] - 0.008, b["d"]), (hw * 0.5 + 0.001, 0.008, 0), 0, RECTS["paper_edge"], RECTS["paper_edge"], RECTS["db_right"])
    return m.part


def ink_part():
    b = N.INK
    m = Mesh("Ink")
    cyl(m, 0.03, 0.04, (-0.02, 0.0, 0.02), RECTS["ink_glass"])
    cyl(m, 0.016, 0.01, (-0.02, 0.04, 0.02), RECTS["tin"])
    bx(m, (0.007, 0.007, 0.17), (0.03, 0.0, 0.0), 8, RECTS["pen_wood"], RECTS["pen_wood"], RECTS["pen_wood"])
    bx(m, (0.003, 0.003, 0.03), (0.03 + 0.0, 0.0, 0.1), 8, RECTS["steel"], RECTS["steel"], RECTS["steel"])
    return m.part


def cash_part():
    b = N.CASH
    m = Mesh("Cash")
    bx(m, (b["w"], 0.012, b["d"]), (0, 0, 0), 0, RECTS["tin"], RECTS["tin"], RECTS["tin"], top_uv=False)
    rng = random.Random(1182)
    for i, (x, z, n, rect) in enumerate(((-0.08, -0.03, 6, "silver"), (-0.055, 0.0, 4, "silver"), (-0.08, 0.03, 3, "copper"),
                                         (-0.05, 0.04, 5, "silver"), (-0.025, -0.03, 4, "copper"))):
        cyl(m, 0.013, 0.0024 * n, (x, 0.012, z), RECTS[rect], 10)
    for k in range(5):   # loose coin
        cyl(m, 0.012, 0.0022, (0.0 + rng.uniform(-0.01, 0.03), 0.012, rng.uniform(-0.04, 0.04)), RECTS["silver" if k % 2 else "copper"], 9)
    bx(m, (0.09, 0.018, 0.05), (0.07, 0.012, 0.0), 5, RECTS["paper_edge"], RECTS["paper_edge"], RECTS["note"])
    return m.part


def parcels_part():
    m = Mesh("Parcels")
    for size, y, turn, dx in (((0.3, 0.07, 0.2), 0.0, 0, 0.0), ((0.24, 0.06, 0.17), 0.07, 12, 0.02), ((0.16, 0.05, 0.12), 0.13, -9, -0.03)):
        bx(m, size, (dx, y, 0.0), turn, RECTS["parcel"], RECTS["kraft"], RECTS["parcel"])
    bx(m, (0.05, 0.004, 0.035), (-0.03, 0.18, 0.0), -9, RECTS["tag"], RECTS["tag"], RECTS["tag"])
    return m.part


def post():
    import doctor_d3  # (its export_plain: parts carrying their own UVs on a printed sheet)
    sheet()
    parts = [mail_part(k) for k in range(4)] + [sign_part(), ledger_part(), daybook_part(), ink_part(), cash_part(), parcels_part()]
    doctor_d3.export_plain("store_post", parts)


# === The hung goods (store_hung, baked) =============================================================================
def hung():
    D = N.HUNG
    # Pails on a cross-cord: three of G2's pail, their bails' tops hung from the cord by a loop each.
    drop = D["hung_pails"]["drop"]
    bar_y = drop - 0.12
    pails, cords = [], [tube("c", [(0.0, drop, 0.0), (0.0, bar_y, 0.0)], 0.004, sides=5),
                        tube("b", [(-0.22, bar_y, 0.0), (0.22, bar_y, 0.0)], 0.004, sides=5)]
    for x, z, foot in ((-0.22, -0.05, 0.33), (0.0, 0.07, 0.25), (0.22, -0.05, 0.37)):
        pails.append(shifted(G2.pail(), (x, foot, z)))
        cords.append(tube("l", [(x, bar_y, 0.0), (x, foot + 0.365, z)], 0.0035, sides=5))
    ring = lathe("r", [(0.013, drop - 0.006), (0.016, drop), (0.013, drop + 0.006)], 10, caps=(False, False))
    # Hams in muslin: the big end up, a cord round the hock, each on a cord from a ring.
    dh = D["hung_ham"]["drop"]
    hams, hcords = [], []
    for x, y, r in ((-0.1, 0.40, 0.085), (0.1, 0.22, 0.075)):
        hams.append(blob("h", (x, y, 0.0), (r, r * 1.5, r * 0.9), rings=7, sides=14, noise=0.06, seed=int(abs(x) * 100)))
        hcords.append(tube("c", [(0.0, dh - 0.02, 0.0), (x * 0.5, dh - 0.12, 0.0), (x, y + r * 1.5, 0.0)], 0.004, sides=5))
    hcords.append(tube("c", [(0.0, dh, 0.0), (0.0, dh - 0.03, 0.0)], 0.005, sides=5))
    # The lantern: a tin cage on a base, a cone cap with a vent, the bail up to the hook; its glass globe inside.
    dl = D["hung_lantern"]["drop"]
    base = lathe("b", [(0.0, 0.02), (0.058, 0.02), (0.065, 0.03), (0.06, 0.045), (0.0, 0.045)], 14)
    cage = [tube("w", [(math.sin(a) * 0.052, 0.045, math.cos(a) * 0.052), (math.sin(a) * 0.052, 0.235, math.cos(a) * 0.052)], 0.0022, sides=4)
            for a in (0.0, math.pi * 0.5, math.pi, math.pi * 1.5)]
    cap = lathe("c", [(0.062, 0.235), (0.066, 0.245), (0.03, 0.28), (0.018, 0.29), (0.02, 0.31), (0.0, 0.32)], 14)
    bail = tube("l", [(-0.06, 0.255, 0.0), (-0.04, 0.4, 0.0), (0.0, dl, 0.0), (0.04, 0.4, 0.0), (0.06, 0.255, 0.0)], 0.0028, sides=5)
    lantern = merged("Lantern", [base, *cage, cap, bail])
    globe = lathe("Globe", [(0.0, 0.05), (0.03, 0.05), (0.046, 0.09), (0.05, 0.15), (0.044, 0.205), (0.04, 0.23), (0.037, 0.23), (0.041, 0.205),
                            (0.047, 0.15), (0.043, 0.09), (0.027, 0.055), (0.0, 0.055)], 16, caps=(False, False))
    metal.export_baked("hung_pails", [(merged("Pails", pails + [ring]), "tin"), (merged("Cords", cords), "hemp")], size=512)
    metal.export_baked("hung_ham", [(merged("Hams", hams), "cured_ham"), (merged("Cords", hcords), "hemp")], size=512)
    metal.export_baked("hung_lantern", [(lantern, "tin"), (globe, "glass")], size=512)


STEPS = {"post": post, "hung": hung}


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
