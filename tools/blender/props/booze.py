"""The game's booze (#1222, docs/briefs/booze.md): every bottle shape of tools/props/booze.py modelled into
glb:booze_bottles (glass drawn by the game, the kit's `glass:` looks; cork and contents baked the gun way,
metal.py), and every label of the 53 brands printed on ONE sheet (booze_labels_albedo.png and its ORM,
Pillow), so all of them are one material and batch: the bottles' labels, the stoneware ginger beers' whole
glazed skins, the champagne's foil and the stencilled barrel and keg heads.

    ~/.venvs/bpy/bin/python tools/blender/props/booze.py [--only=labels,bottles]     (~1 min)
    ~/.venvs/bpy/bin/python tools/blender/props/build.py --only=booze

Then `godot --headless --import` and commit the .glb and .png files with their .import files (the pngs'
.import as the doctor's: VRAM compressed, mipmaps).

The look (booze.md sections 1 and 4): plain paper printed letterpress in black and one colour for the
rotgut, the saloon's and the dumb ones, framed by a printer's border with a stock engraved cut; the fine
goods and the bitters by chromolithograph, coloured grounds and gold (gold is metal on the ORM). Type: the
workspace's Liberation and FreeSerif faces (SIL OFL / GPL with font exception, CREDITS.md), set heavy
for the period's Clarendons and fat faces, italic for its scripts, saved as a picture (no font in the game).
Aged: tide marks, foxing, the shoulders scuffed, a corner torn off the rotgut. The dumb ones are set
exactly as the straight ones: the joke is the words.
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import booze  # noqa: E402  (tools/props/booze.py: brands, shapes, heads)
import common  # noqa: E402
import metal  # noqa: E402
from common import Part, lathe  # noqa: E402
from doctor_d2 import loft, section_at, section_point  # noqa: E402  (the druggist's bottles' skins)

SHEET = 2048        # the sheet's width
SHEET_H = 1024      # and height (one row of shelves fewer than square: everything fits in 1024)
LABEL_PX = 1500.0   # a label's pixels a metre: its name ~25 px high, the slogan ~8 (legible at 1 m)
HEAD_PX = 640.0     # a cask head's (read at 2-3 m)
FONTS = {
    "bold": "/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf",
    "regular": "/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf",
    "italic": "/usr/share/fonts/truetype/liberation/LiberationSerif-Italic.ttf",
    "bolditalic": "/usr/share/fonts/truetype/freefont/FreeSerifBoldItalic.ttf",
    "sans": "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
}


# === Where everything sits on the sheet ==============================================================

def label_size(shape):
    """A shape's label: its width (the arc at mid height) and height, metres."""
    s = booze.SHAPES[shape]
    y0, y1, half = s["label"]
    sec = section_at(s["sections"], (y0 + y1) * 0.5)
    pts = [section_point(sec, math.pi * 0.5 + half - 2 * half * i / 60) for i in range(61)]
    return sum(math.dist(p, q) for p, q in zip(pts, pts[1:])), y1 - y0


def layout():
    """Every cell on the sheet: ("label", shape, n) / ("head", name) / ("foil",) -> (x0, y0, x1, y1)
    pixels, y down; packed in shelves, tallest first."""
    cells = []
    for shape in booze.SHAPES:
        w, h = label_size(shape)
        px = (int(round(w * LABEL_PX)), int(round(h * LABEL_PX)))
        if booze.SHAPES[shape].get("stone"):
            px = (int(round(w * LABEL_PX * 0.75)), int(round(h * LABEL_PX * 0.75)))
        for n, _ in enumerate(booze.brands_of(shape)):
            cells.append((("label", shape, n), px))
    for head in booze.HEADS:
        _, _, radius, _ = booze.head_boards(head)
        d = int(round(2 * radius * HEAD_PX))
        cells.append((("head", head), (d, d)))
    cells.append((("foil",), (96, 96)))
    cells.sort(key=lambda c: -c[1][1])
    out, x, y, row_h, gap = {}, 4, 4, 0, 6
    for key, (w, h) in cells:
        if x + w + gap > SHEET:
            x, y, row_h = 4, y + row_h + gap, 0
        out[key] = (x, y, x + w, y + h)
        x += w + gap
        row_h = max(row_h, h)
    assert y + row_h < SHEET_H, "the booze label sheet is full (%d)" % (y + row_h)
    return out


CELLS = None


def cell(key):
    global CELLS
    if CELLS is None:
        CELLS = layout()
    return CELLS[key]


def uv(px, py):
    return (px / SHEET, 1.0 - py / SHEET_H)


# === The model ======================================================================================

def label_patch(name, sections, y0, y1, half, rect, nu=16, nv=6, lift=0.0006, turn=0.0):
    """A paper label on the bottle between y0..y1, round the front (+z) from angle pi/2 + half (the
    viewer's left) to pi/2 - half, `lift` off the glass, its UVs the sheet's rectangle `rect`."""
    verts, uvs, faces = [], [], []
    x0, py0, x1, py1 = rect
    for j in range(nv + 1):
        y = y0 + (y1 - y0) * j / nv
        sec = section_at(sections, y)
        for i in range(nu + 1):
            th = math.pi * 0.5 + turn + half - 2 * half * i / nu
            x, z = section_point(sec, th)
            rr = max(1e-6, math.hypot(x, z))
            verts.append((x + x / rr * lift, y, z + z / rr * lift))
            uvs.append(uv(x0 + (x1 - x0) * i / nu, py1 + (py0 - py1) * j / nv))
    for j in range(nv):
        for i in range(nu):
            a = j * (nu + 1) + i
            faces.append([a, a + 1, a + nu + 2, a + nu + 1])
    p = Part(name, smooth=True).add(verts, faces)
    p.uvs = uvs
    return p


def flat_patch(name, rect, corner, du, dv, n=12, clip=None, lift=(0, 0, 0)):
    """A flat patch (a cask head's stencil): points corner + du*s + dv*t (s, t in 0..1), its UVs `rect`;
    `clip(point)` keeps a quad only if all its corners pass (the head's circle and its board)."""
    verts, uvs, faces, idx = [], [], [], {}
    x0, py0, x1, py1 = rect
    for j in range(n + 1):
        for i in range(n + 1):
            s, t = i / n, j / n
            p = tuple(corner[k] + du[k] * s + dv[k] * t + lift[k] for k in range(3))
            idx[(i, j)] = len(verts)
            verts.append(p)
            uvs.append(uv(x0 + (x1 - x0) * s, py0 + (py1 - py0) * t))
    for j in range(n):
        for i in range(n):
            q = [idx[(i, j)], idx[(i + 1, j)], idx[(i + 1, j + 1)], idx[(i, j + 1)]]
            if clip is None or all(clip(verts[v]) for v in q):
                faces.append(q)
    p = Part(name, smooth=False).add(verts, faces)
    p.uvs = uvs
    return p


def bottles():
    parts, done = [], set()
    for shape, s in booze.SHAPES.items():
        k, lk = booze.part(shape)
        secs = s["sections"]
        if k not in done:
            done.add(k)
            if s.get("stone"):
                parts.append((Part("Base" + k).add([(math.cos(a) * 0.033, 0.0, math.sin(a) * 0.033) for a in
                                                     [2 * math.pi * i / 24 for i in range(24)]], [list(range(23, -1, -1))]), "stoneware"))
            else:
                parts.append((loft("Glass" + k, secs), None))
                level = s["liquid"]
                inside = [sec for sec in secs if sec[0] < level] + [section_at(secs, level)]
                inside = [(max(sec[0], 0.006), *sec[1:]) for sec in inside]
                parts.append((loft("Liquid" + k, inside, shrink=0.0035, top_cap=True), s["finish"]))
            rad, sy0, sy1 = s["stopper"]
            parts.append((lathe("Cork" + k, [(rad * 0.86, sy0), (rad, sy0 + 0.004), (rad * 1.04, sy1 - 0.003), (rad * 0.96, sy1), (0.0, sy1)], 14), "cork"))
            if s.get("foil"):
                # Gilt foil over the cork and the neck's top (the champagne's), on the sheet's gold patch.
                fsec = [(y, a + 0.0009, b + 0.0009, p_, sd) for (y, a, b, p_, sd) in secs if y >= 0.235]
                fsec.append((sy1 + 0.001, rad * 1.1, rad * 1.1, 2, 0))
                foil = label_patch("Foil" + k, fsec, 0.236, sy1 + 0.001, math.pi, cell(("foil",)), nu=20, nv=6, lift=0.0)
                parts.append((foil, None))
        y0, y1, half = s["label"]
        jr = random.Random(sum(map(ord, shape)) + 7)   # (not hash(): Python salts it per run)
        for n, _ in enumerate(booze.brands_of(shape)):
            lift = 0.0 if s.get("stone") else 0.0006
            nu, nv = (32, 10) if s.get("stone") else (16, 6)
            # Pasted on by hand: each a little higher or lower and off centre (round 1: every label at one
            # height, dead centre). Not the stoneware's: its skin is the bottle.
            dy = 0.0 if s.get("stone") else jr.uniform(-0.008, 0.008)
            turn = 0.0 if s.get("stone") else jr.uniform(-0.12, 0.12)
            p = label_patch("Label%s%d" % (lk, n), secs, y0 + dy, y1 + dy, half, cell(("label", shape, n)), nu=nu, nv=nv, lift=lift, turn=turn)
            parts.append((p, None))
    parts += heads()
    metal.export_baked("booze_bottles", parts, size=256)


def heads():
    """The stencilled heads: each board's share of a disc laid on the cask's head."""
    out = []
    for head, h in booze.HEADS.items():
        spans, centre, radius, _ = booze.head_boards(head)
        rect = cell(("head", head))
        cx, cy, cz = centre
        name = "Head%s" % head.title().replace("_", "")
        for i, (_, a0, a1) in enumerate(spans):
            if h["face"] == "up":
                # Read from the cask's front (+z): the sheet's top toward -z.
                clip = (lambda a0, a1: lambda p: p[0] * p[0] + p[2] * p[2] <= radius * radius * 1.0001 and a0 - 1e-6 <= p[0] <= a1 + 1e-6)(a0, a1)
                out.append((flat_patch("%s%d" % (name, i), rect, (cx - radius, cy, cz - radius), (2 * radius, 0, 0), (0, 0, 2 * radius),
                                       n=24, clip=clip, lift=(0, 0.0015, 0)), None))
            else:
                clip = lambda p: p[0] * p[0] + (p[1] - cy) ** 2 <= radius * radius * 1.0001
                out.append((flat_patch("%s%d" % (name, i), rect, (cx - radius, cy + radius, cz), (2 * radius, 0, 0), (0, -2 * radius, 0),
                                       n=24, clip=clip, lift=(0, 0, 0.0015)), None))
    # Clip by quads leaves the disc's edge stepped: fine at a cask's 24 steps (its chime hides it).
    return out


# === The labels ======================================================================================

def font(style, size):
    from PIL import ImageFont
    return ImageFont.truetype(FONTS[style], max(5, int(size)))


def fit(d, text, style, size, width):
    size = int(size)
    while size > 5:
        f = font(style, size)
        if d.textlength(text, font=f) <= width:
            return f
        size -= 1
    return font(style, 5)


def centred(d, text, cx, y, f, fill, shadow=None):
    w = d.textlength(text, font=f)
    if shadow:
        d.text((cx - w * 0.5 + 1, y + 1), text, font=f, fill=shadow)
    d.text((cx - w * 0.5, y), text, font=f, fill=fill)


def wrap(d, text, style, size, width, lines_max=3):
    """`text` broken into lines that fit `width` at `size` (smaller till it fits in lines_max)."""
    while size > 5:
        f = font(style, size)
        words, lines, cur = text.split(), [], ""
        for w in words:
            t = (cur + " " + w).strip()
            if d.textlength(t, font=f) <= width or not cur:
                cur = t
            else:
                lines.append(cur)
                cur = w
        lines.append(cur)
        if len(lines) <= lines_max and all(d.textlength(l, font=f) <= width for l in lines):
            return f, lines
        size -= 1
    return font(style, 5), [text]


# --- The engraved cuts (stock vignettes: each a silhouette, hatched as an engraving) -------------------

def _poly(pts, cx, cy, s):
    return [(cx + x * s, cy + y * s) for x, y in pts]


def vignette(name, cx, cy, s):
    """The cut's shapes for `name` about (cx, cy), `s` its half size, as a list of ("poly"|"ellipse"|
    "line", points or box, width): unit coordinates scaled by s (x right, y down)."""
    P, E, L = "poly", "ellipse", "line"
    bust = [(-0.55, 0.9), (-0.5, 0.45), (-0.25, 0.3), (-0.2, 0.1), (-0.3, -0.05), (-0.28, -0.35), (-0.1, -0.6), (0.15, -0.6),
            (0.3, -0.4), (0.38, -0.2), (0.3, -0.12), (0.32, 0.05), (0.22, 0.15), (0.22, 0.3), (0.5, 0.45), (0.55, 0.9)]
    shapes = {
        "distillery": [(P, [(-0.9, 0.7), (-0.9, -0.1), (-0.5, -0.4), (-0.1, -0.1), (-0.1, 0.7)]), (P, [(-0.1, 0.7), (-0.1, 0.0), (0.8, 0.0), (0.8, 0.7)]),
                       (P, [(0.45, 0.0), (0.45, -0.85), (0.6, -0.85), (0.6, 0.0)]), (L, [(-0.95, 0.72), (0.95, 0.72)], 2)],
        "colonel": [(P, bust), (P, [(-0.55, -0.55), (0.55, -0.55), (0.3, -0.62), (0.28, -0.95), (-0.25, -0.95), (-0.3, -0.62)]),
                    (P, [(-0.05, 0.05), (0.25, 0.05), (0.15, 0.45), (0.0, 0.45)])],
        "judge": [(P, bust), (P, [(-0.42, -0.5), (-0.6, 0.3), (-0.35, 0.3), (-0.25, -0.3)]), (P, [(0.4, -0.5), (0.55, 0.1), (0.35, 0.1), (0.3, -0.3)])],
        "belle": [(P, bust), (E, (-0.45, -0.75, 0.15, -0.2)), (P, [(-0.6, 0.9), (0.0, 0.5), (0.6, 0.9)])],
        "lady": [(P, bust), (E, (-0.5, -0.8, 0.2, -0.25)), (P, [(-0.2, -0.65), (0.5, -0.75), (0.2, -0.5)])],
        "amazon": [(P, bust), (L, [(0.6, -0.9), (0.6, 0.9)], 3), (P, [(0.48, -0.9), (0.6, -1.0), (0.72, -0.9)]), (E, (-0.7, 0.0, -0.1, 0.6))],
        "mountain": [(P, [(-1, 0.6), (-0.4, -0.5), (-0.1, -0.1), (0.25, -0.7), (1, 0.6)]), (L, [(-1, 0.62), (1, 0.62)], 2)],
        "wagon": [(P, [(-0.8, 0.2), (-0.7, -0.5), (0.7, -0.5), (0.8, 0.2)]), (E, (-0.7, 0.05, -0.2, 0.55)), (E, (0.25, 0.05, 0.75, 0.55))],
        "horse": [(P, [(-0.8, 0.0), (-0.6, -0.3), (0.3, -0.3), (0.55, -0.7), (0.8, -0.6), (0.6, -0.2), (0.5, 0.05), (0.55, 0.7), (0.4, 0.7), (0.35, 0.15),
                       (-0.4, 0.15), (-0.45, 0.7), (-0.6, 0.7), (-0.6, 0.1)])],
        "harp": [(P, [(-0.5, 0.8), (-0.6, -0.6), (-0.3, -0.8), (0.6, -0.3), (0.5, 0.8)]), (L, [(-0.3, -0.5), (-0.3, 0.7)], 1), (L, [(0.0, -0.4), (0.0, 0.7)], 1),
                 (L, [(0.3, -0.25), (0.3, 0.7)], 1)],
        "stag": [(P, [(-0.3, 0.9), (-0.25, 0.0), (-0.45, -0.3), (0.0, -0.45), (0.45, -0.3), (0.25, 0.0), (0.3, 0.9)]),
                 (L, [(-0.2, -0.4), (-0.6, -0.95)], 3), (L, [(0.2, -0.4), (0.6, -0.95)], 3), (L, [(-0.45, -0.7), (-0.8, -0.6)], 2), (L, [(0.45, -0.7), (0.8, -0.6)], 2)],
        "barley": [(L, [(0.0, 0.9), (0.0, -0.4)], 2)] + [(E, (sx * 0.18 - 0.12, -0.8 + i * 0.22, sx * 0.18 + 0.12, -0.6 + i * 0.22)) for i in range(5) for sx in (-1, 1)],
        "spring": [(P, [(-0.9, 0.7), (-0.6, -0.2), (-0.2, -0.5), (0.3, -0.4), (0.9, 0.7)]), (P, [(-0.2, 0.7), (-0.05, 0.1), (0.1, 0.1), (0.3, 0.7)])],
        "hops": [(E, (-0.35, -0.6, 0.35, 0.6)), (L, [(0.0, -0.6), (0.0, -0.95)], 2), (P, [(0.1, -0.85), (0.7, -0.95), (0.5, -0.55)])],
        "eagle": [(P, [(-1, -0.5), (-0.3, -0.2), (-0.15, -0.5), (0.15, -0.5), (0.3, -0.2), (1, -0.5), (0.5, 0.2), (0.2, 0.15), (0.15, 0.8), (-0.15, 0.8),
                       (-0.2, 0.15), (-0.5, 0.2)])],
        "ship": [(P, [(-0.9, 0.3), (0.9, 0.3), (0.6, 0.7), (-0.6, 0.7)]), (P, [(-0.1, 0.25), (-0.1, -0.9), (-0.7, 0.2)]), (P, [(0.05, 0.25), (0.05, -0.8), (0.6, 0.2)]),
                 (L, [(-1, 0.85), (1, 0.85)], 2)],
        "herbs": [(L, [(0.0, 0.9), (0.0, -0.8)], 2), (E, (-0.6, -0.5, 0.0, -0.2)), (E, (0.0, -0.2, 0.6, 0.1)), (E, (-0.6, 0.1, 0.0, 0.4)), (E, (0.0, -0.8, 0.5, -0.5))],
        "tent": [(P, [(-0.9, 0.7), (0.0, -0.7), (0.9, 0.7)]), (L, [(0.0, -0.7), (0.0, -0.95)], 2), (P, [(0.0, -0.95), (0.4, -0.85), (0.0, -0.75)])],
        "church": [(P, [(-0.7, 0.8), (-0.7, -0.1), (0.0, -0.5), (0.7, -0.1), (0.7, 0.8)]), (P, [(-0.15, -0.3), (-0.15, -0.95), (0.15, -0.95), (0.15, -0.3)])],
        "cabin": [(P, [(-0.8, 0.7), (-0.8, -0.1), (0.8, -0.1), (0.8, 0.7)]), (P, [(-0.95, -0.05), (0.0, -0.7), (0.95, -0.05)]),
                  (P, [(0.4, -0.4), (0.4, -0.85), (0.6, -0.85), (0.6, -0.25)])],
        "palm": [(L, [(0.0, 0.9), (0.1, -0.5)], 3), (P, [(0.1, -0.5), (-0.8, -0.2), (-0.3, -0.7)]), (P, [(0.1, -0.5), (0.9, -0.2), (0.4, -0.8)])],
        "windmill": [(P, [(-0.3, 0.9), (-0.2, -0.3), (0.2, -0.3), (0.3, 0.9)]), (L, [(-0.7, -0.9), (0.7, 0.3)], 3), (L, [(0.7, -0.9), (-0.7, 0.3)], 3)],
        "cat": [(E, (-0.5, -0.2, 0.5, 0.9)), (E, (-0.35, -0.75, 0.35, -0.1)), (P, [(-0.35, -0.5), (-0.3, -0.95), (-0.1, -0.7)]), (P, [(0.35, -0.5), (0.3, -0.95), (0.1, -0.7)]),
                (L, [(0.5, 0.7), (0.9, 0.2)], 3)],
        "grapes": [(E, (x - 0.17, y - 0.17, x + 0.17, y + 0.17)) for x, y in [(-0.3, -0.3), (0.0, -0.3), (0.3, -0.3), (-0.15, 0.0), (0.15, 0.0), (0.0, 0.3)]]
                  + [(P, [(0.0, -0.5), (0.6, -0.9), (0.3, -0.5)])],
        "crest": [(P, [(-0.6, -0.8), (0.6, -0.8), (0.6, 0.1), (0.0, 0.9), (-0.6, 0.1)]), (L, [(-0.6, -0.2), (0.6, -0.2)], 2)],
        "berries": [(E, (x - 0.2, y - 0.2, x + 0.2, y + 0.2)) for x, y in [(-0.3, 0.2), (0.25, 0.3), (0.0, -0.1)]] + [(P, [(0.0, -0.3), (-0.7, -0.8), (-0.1, -0.6)])],
        "chateau": [(P, [(-0.9, 0.8), (-0.9, -0.2), (0.9, -0.2), (0.9, 0.8)]), (P, [(-0.9, -0.2), (-0.7, -0.8), (-0.5, -0.2)]), (P, [(0.5, -0.2), (0.7, -0.8), (0.9, -0.2)])],
        "root": [(P, [(-0.2, -0.9), (0.2, -0.9), (0.15, 0.0), (0.5, 0.8), (0.0, 0.3), (-0.4, 0.8), (-0.15, 0.0)])],
        "rifles": [(L, [(-0.9, 0.8), (0.9, -0.8)], 3), (L, [(0.9, 0.8), (-0.9, -0.8)], 3), (E, (-0.25, -0.25, 0.25, 0.25))],
        "cougar": [(P, [(-0.9, 0.1), (-0.5, -0.2), (0.4, -0.2), (0.6, -0.45), (0.85, -0.35), (0.7, 0.0), (0.6, 0.55), (0.45, 0.55), (0.35, 0.1), (-0.4, 0.1),
                        (-0.5, 0.55), (-0.65, 0.55), (-0.65, 0.05)]), (L, [(-0.9, 0.1), (-1.0, 0.6)], 2)],
        "still": [(E, (-0.7, -0.3, 0.3, 0.8)), (P, [(-0.3, -0.25), (-0.1, -0.75), (0.1, -0.75)]), (L, [(0.0, -0.7), (0.8, -0.2)], 2), (P, [(0.6, -0.2), (0.95, -0.2), (0.95, 0.8), (0.6, 0.8)])],
        "leaf": [(P, [(0.0, -0.9), (0.5, -0.3), (0.3, 0.5), (0.0, 0.9), (-0.3, 0.5), (-0.5, -0.3)]), (L, [(0.0, -0.9), (0.0, 0.9)], 1)],
        "planet": [(E, (-0.5, -0.5, 0.5, 0.5)), (L, [(-0.95, 0.25), (0.95, -0.25)], 3)],
        "buttes": [(P, [(-1, 0.7), (-0.8, -0.3), (-0.3, -0.3), (-0.15, 0.7)]), (P, [(0.15, 0.7), (0.3, -0.3), (0.8, -0.3), (1, 0.7)]), (L, [(-1, 0.72), (1, 0.72)], 2)],
        "door": [(P, [(-0.55, 0.9), (-0.55, -0.3), (0.0, -0.85), (0.55, -0.3), (0.55, 0.9)])],
        "bird": [(E, (-0.5, -0.3, 0.4, 0.4)), (E, (0.15, -0.6, 0.55, -0.2)), (P, [(0.5, -0.45), (0.95, -0.3), (0.5, -0.3)]), (P, [(-0.45, 0.0), (-0.95, -0.2), (-0.9, 0.2)])],
        "rooster": [(E, (-0.5, -0.2, 0.4, 0.6)), (E, (0.1, -0.75, 0.5, -0.3)), (P, [(0.2, -0.75), (0.3, -0.95), (0.45, -0.75)]), (P, [(-0.45, 0.1), (-0.95, -0.6), (-0.7, 0.3)]),
                    (L, [(-0.1, 0.6), (-0.1, 0.9)], 2), (L, [(0.15, 0.6), (0.15, 0.9)], 2)],
        "rhubarb": [(L, [(-0.1, 0.9), (0.0, -0.1)], 3), (L, [(0.2, 0.9), (0.1, -0.1)], 3), (E, (-0.8, -0.9, 0.8, 0.0))],
        "wind": [(E, (-0.9, -0.5, -0.3, 0.1)), (P, [(-0.35, -0.3), (0.95, -0.6), (0.95, 0.4), (-0.35, -0.1)])],
        "anchor": [(L, [(0.0, -0.8), (0.0, 0.8)], 3), (L, [(-0.4, -0.5), (0.4, -0.5)], 3), (P, [(-0.7, 0.3), (0.0, 0.9), (0.7, 0.3), (0.0, 0.7)]), (E, (-0.15, -0.95, 0.15, -0.7))],
        "clock": [(E, (-0.7, -0.7, 0.7, 0.7)), (L, [(0.0, 0.0), (0.0, -0.5)], 2), (L, [(0.0, 0.0), (0.35, 0.0)], 2)],
        "barrel": [(E, (-0.6, -0.8, 0.6, 0.8)), (L, [(-0.62, -0.4), (0.62, -0.4)], 2), (L, [(-0.62, 0.4), (0.62, 0.4)], 2)],
    }
    out = []
    for item in shapes.get(name, shapes["barrel"]):
        kind, data = item[0], item[1]
        if kind == "poly":
            out.append(("poly", _poly(data, cx, cy, s), 0))
        elif kind == "ellipse":
            x0, y0, x1, y1 = data
            out.append(("ellipse", (cx + x0 * s, cy + y0 * s, cx + x1 * s, cy + y1 * s), 0))
        else:
            out.append(("line", _poly(data, cx, cy, s), max(1, int(item[2] * s / 12))))
    return out


def engrave(img, shapes, box, ink, fill=None, hatch=2):
    """The cut drawn as an engraving: the shapes' silhouette hatched in fine lines (every `hatch` px),
    their outline solid; a chromolithograph's `fill` colour laid under the hatching."""
    from PIL import Image, ImageDraw
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = max(1, x1 - x0), max(1, y1 - y0)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    for kind, data, width in shapes:
        pts = [(x - x0, y - y0) for x, y in data] if kind != "ellipse" else None
        if kind == "poly":
            md.polygon(pts, fill=255)
        elif kind == "ellipse":
            md.ellipse([data[0] - x0, data[1] - y0, data[2] - x0, data[3] - y0], fill=255)
        else:
            md.line(pts, fill=255, width=width + 1)
    d = ImageDraw.Draw(img)
    m = mask.load()
    for yy in range(h):
        for xx in range(w):
            if m[xx, yy]:
                edge = any(not m[min(w - 1, max(0, xx + a)), min(h - 1, max(0, yy + b))] for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if edge or (yy + xx // 7) % hatch == 0:
                    d.point((x0 + xx, y0 + yy), fill=ink)
                elif fill is not None:
                    d.point((x0 + xx, y0 + yy), fill=fill)


# --- One label ---------------------------------------------------------------------------------------

def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def label(b, w, h, rng, metal_mask, front=1.0):
    """Brand `b`'s label, w x h pixels (RGB), drawing gold into `metal_mask` (an "L" image the same size)."""
    from PIL import Image, ImageDraw
    chromo = b["style"] == "chromo"
    paper, ink, ink2 = b["paper"], b["ink"], b["ink2"] or b["ink"]
    # Paper gone yellow-brown with age and the bar's smoke, each label its own (round 1: a row of identical
    # bright cream squares, the brightest thing on the back bar).
    if sum(paper) > 450:
        k = rng.uniform(0.72, 0.86)
        paper = (int(paper[0] * k), int(paper[1] * k * 0.95), int(paper[2] * k * 0.82))
    img = Image.new("RGB", (w, h), paper)
    d = ImageDraw.Draw(img)
    md = ImageDraw.Draw(metal_mask)
    gold = booze.GOLD
    m = max(3, int(min(w, h) * 0.04))
    # The border: letterpress a heavy rule and a hair rule (the jobbing printer's stock border), corner
    # ornaments; chromo a broad gilt frame with a dark keyline and a coloured panel inside.
    if chromo:
        d.rectangle([0, 0, w - 1, h - 1], outline=gold, width=m + 1)
        md.rectangle([0, 0, w - 1, h - 1], outline=255, width=m + 1)
        d.rectangle([m + 1, m + 1, w - m - 2, h - m - 2], outline=mix(ink, paper, 0.3), width=1)
        for k in range(0, w, max(4, m)):
            d.point((k, m // 2), fill=mix(gold, (255, 240, 200), 0.6))
            d.point((k, h - 1 - m // 2), fill=mix(gold, (255, 240, 200), 0.6))
    else:
        d.rectangle([m // 2, m // 2, w - 1 - m // 2, h - 1 - m // 2], outline=ink2, width=max(2, m // 2))
        d.rectangle([m + 2, m + 2, w - m - 3, h - m - 3], outline=ink, width=1)
        for (cx_, cy_) in ((m + 2, m + 2), (w - m - 3, m + 2), (m + 2, h - m - 3), (w - m - 3, h - m - 3)):
            d.rectangle([cx_ - 2, cy_ - 2, cx_ + 2, cy_ + 2], fill=ink2)
    inner = w - 2 * (m + 5)
    cx = w * 0.5
    y = m + 4
    # Light text on a dark chromo ground uses the ink (gold or cream); it's laid as it reads.
    text_ink = ink
    sh = mix(paper, (0, 0, 0), 0.6) if chromo else None
    if b["top"]:
        f = fit(d, b["top"].upper(), "regular", h * 0.055, inner)
        centred(d, b["top"].upper(), cx, y, f, ink2 if not chromo else text_ink)
        y += h * 0.065
    # The cut: an oval cartouche with the engraving in it.
    small_list = b["small"] and len(b["small"]) > 4
    vh = h * (0.17 if small_list else 0.24)
    vw = min(inner * 0.8, vh * 1.5)
    box = (cx - vw * 0.5, y, cx + vw * 0.5, y + vh)
    if chromo:
        d.ellipse(box, fill=mix(paper, (250, 244, 220), 0.7), outline=gold, width=2)
        md.ellipse(box, outline=255, width=2)
        engrave(img, vignette(b["vignette"], cx, y + vh * 0.5, vh * 0.36), box, mix(ink, (0, 0, 0), 0.2) if sum(ink) < 500 else (40, 30, 24),
                fill=mix(ink2 if sum(ink2) < 600 else (150, 60, 40), paper, 0.35))
    else:
        d.ellipse(box, outline=ink, width=1)
        engrave(img, vignette(b["vignette"], cx, y + vh * 0.5, vh * 0.36), box, ink)
    y += vh + h * 0.015
    # The name: as big as the label takes, two lines if it won't go in one at a readable size.
    name = b["name"]
    fs = h * 0.15
    # A round bottle turns its label's ends away from the eye: the name kept to the front's share (round 1's
    # critic: "BELLE OF LAR.." ran off), set heavy so the pixels don't break it up ("VAN DORST").
    inner_name = inner * front
    f = fit(d, name, "bold", fs, inner_name)
    lines = [name]
    if f.size < h * 0.095 and " " in name:
        words = name.split()
        best = min(range(1, len(words)), key=lambda i: abs(len(" ".join(words[:i])) - len(" ".join(words[i:]))))
        lines = [" ".join(words[:best]), " ".join(words[best:])]
        f = min((fit(d, l, "bold", h * 0.12, inner_name) for l in lines), key=lambda ff: ff.size)
    for line in lines:
        col = text_ink if chromo else ink2 if b["ink2"] and b["grade"] != "R" else ink
        if sh:
            centred(d, line, cx + 1, y + 1, f, sh)
        tw = d.textlength(line, font=f)
        d.text((cx - tw * 0.5, y), line, font=f, fill=col, stroke_width=1 if f.size >= 22 else 0, stroke_fill=col)
        y += f.size * 1.05
    # The kind, in italic (the period's script line).
    f = fit(d, b["kind"], "bolditalic" if chromo else "italic", h * 0.075, inner_name)
    centred(d, b["kind"], cx, y, f, text_ink)
    y += f.size * 1.15
    d.line([(cx - inner * 0.3, y), (cx + inner * 0.3, y)], fill=ink2 if not chromo else gold, width=1)
    y += h * 0.015
    bottom = h - m - 4 - h * 0.11
    if b["small"]:
        # The small print: Quill's whole list set as one block, run on with commas (the period's
        # testimonial columns), small; Haskett's two lines.
        text = b["small"][0] + " " + ", ".join(b["small"][1:-1]) + (", " if len(b["small"]) > 2 else "") + b["small"][-1] if len(b["small"]) > 2 else " ".join(b["small"])
        avail = bottom - y - (h * 0.1 if b["slogan"] else 0)
        size = h * 0.045
        while size > 5:
            f, lines = wrap(d, text, "regular", size, inner, lines_max=40)
            if len(lines) * f.size * 1.02 <= avail:
                break
            size -= 0.5
        for line in lines:
            centred(d, line, cx, y, f, text_ink)
            y += f.size * 1.02
    if b["slogan"] and y < bottom:
        f, lines = wrap(d, b["slogan"], "italic", h * 0.05, inner, lines_max=3)
        if y + len(lines) * f.size * 1.05 > bottom:
            f, lines = wrap(d, b["slogan"], "italic", max(5, (bottom - y) / max(1, 3 * 1.05)), inner, lines_max=3)
        for line in lines:
            centred(d, line, cx, y, f, text_ink)
            y += f.size * 1.05
    # The maker's line and his place, at the foot.
    fy = h - m - 4 - h * 0.105
    f = fit(d, b["maker"], "regular", h * 0.048, inner)
    centred(d, b["maker"], cx, fy, f, text_ink)
    f = fit(d, b["place"].upper(), "bold", h * 0.045, inner)
    centred(d, b["place"].upper(), cx, fy + h * 0.052, f, ink2 if not chromo else text_ink)
    if b["year"]:
        f = fit(d, b["year"], "italic", h * 0.04, inner * 0.4)
        d.text((m + 5, fy - h * 0.05), b["year"], font=f, fill=text_ink)
    return img


def age(img, rng, grade, chromo):
    """Old paper: a tide mark from below, foxing, the top and bottom edges scuffed; the rotgut's corner
    torn off (the glass shows: painted the bottle's dark)."""
    from PIL import ImageFilter
    w, h = img.size
    px = img.load()
    tide = rng.uniform(0.0, 0.6 if grade in ("R", "S", "M") else 0.25)
    tide_y = rng.uniform(0.6, 0.85)
    spots = [(rng.uniform(0, w), rng.uniform(0, h), rng.uniform(1, 3.5)) for _ in range(int(w * h / 900 * (1.5 if grade == "R" else 0.6)))]
    for yy in range(h):
        v = yy / h
        for xx in range(w):
            r_, g_, b_ = px[xx, yy]
            k = 1.0 - 0.05 * rng.random()
            if v > tide_y:
                k *= 1.0 - tide * 0.35 * min(1.0, (v - tide_y) / 0.12)
            if abs(v - tide_y) < 0.01:
                k *= 1.0 - tide * 0.3
            if (v < 0.04 or v > 0.96) and rng.random() < 0.35:
                k *= 1.12  # scuffed through the ink to the paper's fibre
            px[xx, yy] = (min(255, int(r_ * k)), min(255, int(g_ * k * 0.985)), min(255, int(b_ * k * 0.95)))
    for sx, sy, sr in spots:
        for yy in range(max(0, int(sy - sr)), min(h, int(sy + sr) + 1)):
            for xx in range(max(0, int(sx - sr)), min(w, int(sx + sr) + 1)):
                if (xx - sx) ** 2 + (yy - sy) ** 2 <= sr * sr:
                    r_, g_, b_ = px[xx, yy]
                    px[xx, yy] = (int(r_ * 0.86), int(g_ * 0.8), int(b_ * 0.68))
    if grade == "R":
        c = int(min(w, h) * rng.uniform(0.12, 0.2))
        corner = rng.choice([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
        for yy in range(c):
            for xx in range(c - yy + int(rng.uniform(-2, 2))):
                x_ = corner[0] + (xx if corner[0] == 0 else -xx)
                y_ = corner[1] + (yy if corner[1] == 0 else -yy)
                if 0 <= x_ < w and 0 <= y_ < h:
                    px[x_, y_] = (58, 32, 12)
    return img.filter(ImageFilter.GaussianBlur(0.35))


def stone(b, w, h, rng):
    """A stone ginger beer's whole skin, unrolled (its front, +z, at the middle): cream salt glaze below,
    tan dipped above with its run line, the maker's oval stamp on the front, the return line under it."""
    from PIL import Image, ImageDraw
    cream, tan = (222, 210, 178), (150, 104, 58)
    img = Image.new("RGB", (w, h), cream)
    d = ImageDraw.Draw(img)
    dip = int(h * (1.0 - 0.128 / 0.191))
    for xx in range(w):
        run = dip + int(3 * math.sin(xx * 0.09) + rng.uniform(-1, 2))
        d.line([(xx, 0), (xx, run)], fill=tan)
    px = img.load()
    for yy in range(h):
        for xx in range(w):
            r_, g_, b_ = px[xx, yy]
            k = 1.0 + 0.05 * (rng.random() - 0.5) + 0.04 * math.sin(yy * 0.7)  # the glaze's orange peel, throwing rings
            px[xx, yy] = (min(255, int(r_ * k)), min(255, int(g_ * k)), min(255, int(b_ * k)))
    ink = b["ink"]
    cx, top = w * 0.5, dip + h * 0.06
    ow, oh = w * 0.2, h * 0.36
    d.ellipse([cx - ow, top, cx + ow, top + oh], outline=ink, width=2)
    lines = [b["name"], "STONE", "GINGER BEER", b["place"].upper()]
    y = top + oh * 0.12
    for i, line in enumerate(lines):
        f = fit(d, line, "sans" if i != 0 else "bold", oh * (0.2 if i == 0 else 0.14), ow * 1.6 * (0.85 if i in (0, 3) else 1.0))
        centred(d, line, cx, y, f, ink)
        y += f.size * 1.12
    f, ls = wrap(d, b["slogan"], "italic", h * 0.05, ow * 2.6, lines_max=2)
    y = top + oh + h * 0.03
    for line in ls:
        centred(d, line, cx, y, f, ink)
        y += f.size * 1.05
    return img


def head_art(head, size, rng):
    """A cask head: oak boards across (three on a barrel, one on a keg), the maker's name stencilled or
    burned in, the gauger's marks round the foot."""
    from PIL import Image, ImageDraw, ImageFilter
    h = booze.HEADS[head]
    img = Image.new("RGB", (size, size), (120, 84, 52))
    d = ImageDraw.Draw(img)
    # Oak: its grain along the boards (the head's boards run along z: down the picture).
    px = img.load()
    for xx in range(size):
        streak = 0.85 + 0.15 * math.sin(xx * 0.31 + math.sin(xx * 0.05) * 3) + 0.05 * rng.random()
        for yy in range(size):
            k = streak * (0.95 + 0.05 * math.sin(yy * 0.02 + xx * 0.003))
            r_, g_, b_ = (122, 86, 54)
            px[xx, yy] = (int(r_ * k), int(g_ * k), int(b_ * k))
    spans, _, radius, _ = booze.head_boards(head)
    if h["face"] == "up":
        for _, a0, a1 in spans[1:]:
            xx = int((a0 + radius) / (2 * radius) * size)
            d.line([(xx, 0), (xx, size)], fill=(52, 34, 20), width=2)
    ink = h["ink"]
    layer = Image.new("L", (size, size), 0)
    ld = ImageDraw.Draw(layer)
    lines = h["lines"]
    sizes = [0.075, 0.11, 0.17, 0.085, 0.075]
    total = sum(s * 1.12 for s in sizes[:len(lines)]) * size * 0.9
    y = size * 0.5 - total * 0.5
    for i, line in enumerate(lines):
        width = size * (0.62 if i in (0, len(lines) - 1) else 0.78)
        f = fit(ld, line, "sans", size * sizes[i], width)
        w_ = ld.textlength(line, font=f)
        ld.text((size * 0.5 - w_ * 0.5, y), line, font=f, fill=255)
        if not h.get("burned"):
            # The stencil's bridges: gaps across each letter's bowls (a cut stencil holds its middles).
            for k in range(int(size * 0.5 - w_ * 0.5), int(size * 0.5 + w_ * 0.5), max(3, f.size // 2)):
                ld.line([(k, y + f.size * 0.25), (k, y + f.size * 0.75)], fill=0, width=1)
        y += f.size * 1.12
    if h.get("gauge"):
        f = fit(ld, h["gauge"], "sans", size * 0.045, size * 0.62)
        w_ = ld.textlength(h["gauge"], font=f)
        ld.text((size * 0.5 - w_ * 0.5, size * 0.84), h["gauge"], font=f, fill=255)
    if h.get("burned"):
        layer = layer.filter(ImageFilter.GaussianBlur(1.2))
    else:
        layer = layer.filter(ImageFilter.GaussianBlur(0.6))
    lp = layer.load()
    for yy in range(size):
        for xx in range(size):
            a = lp[xx, yy] / 255.0 * (0.85 + 0.15 * rng.random())
            if a > 0.02:
                r_, g_, b_ = px[xx, yy]
                px[xx, yy] = (int(r_ + (ink[0] - r_) * a), int(g_ + (ink[1] - g_) * a), int(b_ + (ink[2] - b_) * a))
    return img


def labels():
    from PIL import Image
    sheet = Image.new("RGB", (SHEET, SHEET_H), (70, 50, 34))
    rough = Image.new("L", (SHEET, SHEET_H), 205)   # paper: dull
    metalm = Image.new("L", (SHEET, SHEET_H), 0)
    rng = random.Random(1222)
    for shape in booze.SHAPES:
        for n, bid in enumerate(booze.brands_of(shape)):
            b = booze.BY_ID[bid]
            x0, y0, x1, y1 = cell(("label", shape, n))
            w, h = x1 - x0, y1 - y0
            if booze.SHAPES[shape].get("stone"):
                img = stone(b, w, h, rng)
                rough.paste(110, (x0, y0, x1, y1))
            else:
                mm = Image.new("L", (w, h), 0)
                sec = booze.SHAPES[shape]["sections"]
                flat = sec[2][3] >= 4   # a square or panel bottle's front is flat: all of it faces you
                img = age(label(b, w, h, rng, mm, front=1.0 if flat else 0.72), rng, b["grade"], b["style"] == "chromo")
                metalm.paste(mm, (x0, y0))
                rough.paste(Image.eval(mm, lambda v: 205 - int(v * 0.5)), (x0, y0))
            sheet.paste(img, (x0, y0))
    for head in booze.HEADS:
        x0, y0, x1, y1 = cell(("head", head))
        sheet.paste(head_art(head, x1 - x0, rng), (x0, y0))
        rough.paste(225, (x0, y0, x1, y1))
    # The foil: gilt paper crumpled round the neck.
    x0, y0, x1, y1 = cell(("foil",))
    foil = Image.new("RGB", (x1 - x0, y1 - y0))
    fp = foil.load()
    for yy in range(y1 - y0):
        for xx in range(x1 - x0):
            k = 0.75 + 0.25 * math.sin(xx * 0.8 + math.sin(yy * 0.5) * 2) + 0.1 * rng.random()
            fp[xx, yy] = (int(min(255, 200 * k)), int(min(255, 160 * k)), int(min(255, 74 * k)))
    sheet.paste(foil, (x0, y0))
    metalm.paste(220, (x0, y0, x1, y1))
    rough.paste(90, (x0, y0, x1, y1))
    out = os.path.join(common.MODELS, "booze_labels_albedo.png")
    sheet.save(out, optimize=True)
    ao = Image.new("L", (SHEET, SHEET_H), 255)
    Image.merge("RGB", (ao, rough, metalm)).save(os.path.join(common.MODELS, "booze_labels_orm.png"), optimize=True)
    print("labels ->", os.path.relpath(out, common.ROOT))


def build():
    labels()
    bottles()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for f in (labels, bottles):
        if only is None or f.__name__ in only:
            f()
