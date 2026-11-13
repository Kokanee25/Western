"""The doctor's office, batch D3 (#819; docs/briefs/prop-factory.md "The doctor's office batch"): his
medical books, the hall's pegs with his coat and hat, the sick room's chamber pot and folded blankets,
modelled here in the kit's space from tools/props/doctor.py's numbers.

The books are printed, not baked: every face of every book on one sheet (medical_books_albedo.png and
its ORM, Pillow, as D2's bottle labels): spines in the period's trade bindings (law sheep with a red
and a black label, publishers' cloth, calf), lettered in gilt with the titles a country doctor of 1882
owned; boards; page edges. The rest is baked the gun way (metal.py): turned pegs, black broadcloth,
felt, white ironstone, wool.

    ~/bpyenv/bin/python tools/blender/props/build.py --only=doctor_d3
    ~/bpyenv/bin/python tools/blender/props/doctor_d3.py --only=books,pegs,pot,blankets

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
import doctor  # noqa: E402  (tools/props/doctor.py: the numbers)
import metal  # noqa: E402
from common import Part, lathe, moved, tube  # noqa: E402
from doctor_d2 import _centred, _font, merged, torus_ring  # noqa: E402

# --- The books' sheet -------------------------------------------------------------------------------
# 2048 px square: two rows of spines at SPINE_PX a metre (a title's small capitals legible from a
# step away), two rows of boards at COVER_PX, one tile of page edges.
SHEET = 2048
SPINE_PX = 1900.0
COVER_PX = 690.0
CELL = 170
SPINE_ROW = 590
COVER_Y = SPINE_ROW * 2 + 10
COVER_ROW = 240
PAGES = (8, COVER_Y + COVER_ROW * 2 + 20, 264, COVER_Y + COVER_ROW * 2 + 276)

# Each binding: (leather or cloth colour, its roughness, the labels' colours or None, raised bands).
GILT = (205, 166, 88)
BINDINGS = {
    "sheep": {"color": (172, 124, 74), "rough": 0.58, "labels": ((112, 28, 24), (24, 20, 18)), "bands": 0, "mottle": 0.11},
    "calf": {"color": (78, 44, 26), "rough": 0.5, "labels": ((96, 24, 22), None), "bands": 5, "mottle": 0.3},
    "cloth_green": {"color": (34, 54, 42), "rough": 0.9, "labels": None, "bands": 0, "mottle": 0.08},
    "cloth_brown": {"color": (72, 48, 34), "rough": 0.9, "labels": None, "bands": 0, "mottle": 0.08},
    "cloth_plum": {"color": (74, 32, 42), "rough": 0.9, "labels": None, "bands": 0, "mottle": 0.08},
    "cloth_black": {"color": (32, 30, 30), "rough": 0.9, "labels": None, "bands": 0, "mottle": 0.06},
}


def spine_rect(k):
    """Book k's spine on the sheet (pixels, y down)."""
    _t, _a, _b, h, w, _d = doctor.BOOKS[k]
    pw, ph = int(round(w * SPINE_PX)), int(round(h * SPINE_PX))
    row, col = divmod(k, 12)
    x0 = col * CELL + (CELL - pw) // 2
    y0 = row * SPINE_ROW + (SPINE_ROW - ph) // 2
    return (x0, y0, x0 + pw, y0 + ph)


def cover_rect(k):
    _t, _a, _b, h, _w, d = doctor.BOOKS[k]
    pw, ph = int(round(d * COVER_PX)), int(round(h * COVER_PX))
    row, col = divmod(k, 12)
    x0 = col * CELL + (CELL - pw) // 2
    y0 = COVER_Y + row * COVER_ROW + (COVER_ROW - ph) // 2
    return (x0, y0, x0 + pw, y0 + ph)


def _mottled(size, color, amount, rng, grain=6):
    """A patch of `color`, mottled (soft blotches and a fine grain) by `amount`."""
    from PIL import Image
    import numpy as np
    w, h = size
    nrng = np.random.default_rng(rng.randrange(1 << 30))

    def layer(cell):
        small = nrng.random((max(2, h // cell + 2), max(2, w // cell + 2))).astype("float32")
        return np.asarray(Image.fromarray((small * 255).astype("uint8")).resize((w, h), Image.BICUBIC), dtype="float32") / 255.0

    n = layer(40) * 0.55 + layer(12) * 0.3 + nrng.random((h, w)).astype("float32") * 0.15 * (grain / 6.0)
    k = 1.0 + (n - 0.5) * 2.0 * amount
    arr = np.clip(np.asarray(color, dtype="float32")[None, None, :] * k[:, :, None], 0, 255).astype("uint8")
    return Image.fromarray(arr, "RGB")


def _lines(d, lines, style, top, bottom, cx, width, fill, max_size):
    """`lines` set centred between top and bottom, the size the widest line allows (to max_size)."""
    size = max_size
    while size > 7 and (any(d.textlength(l, font=_font(style, size)) > width for l in lines) or size * 1.12 * len(lines) > bottom - top):
        size -= 1
    f = _font(style, size)
    pitch = size * 1.12
    y = (top + bottom) * 0.5 - pitch * len(lines) * 0.5
    for l in lines:
        _centred(d, l, y, f, cx, fill)
        y += pitch
    return size


def sheet():
    """The books' albedo and ORM sheets."""
    from PIL import Image, ImageDraw, ImageFilter
    rng = random.Random(819)
    img = Image.new("RGB", (SHEET, SHEET), (60, 46, 34))
    orm = Image.new("RGB", (SHEET, SHEET), (255, 200, 0))
    for k, (title, author, binding, h, w, d) in enumerate(doctor.BOOKS):
        b = BINDINGS[binding]
        # (each book's own shade: sheep ages from straw to chestnut, cloth fades)
        shade = rng.uniform(0.82, 1.12)
        color = tuple(min(255, int(c * shade)) for c in b["color"])
        rough = int(b["rough"] * 255)
        # --- the spine
        x0, y0, x1, y1 = spine_rect(k)
        pw, ph = x1 - x0, y1 - y0
        sp = _mottled((pw, ph), color, b["mottle"], rng)
        so = Image.new("RGB", (pw, ph), (255, rough, 0))
        dr, do = ImageDraw.Draw(sp), ImageDraw.Draw(so)
        dark = tuple(int(c * 0.55) for c in color)
        lite = tuple(min(255, int(c * 1.25)) for c in color)
        m = max(3, int(pw * 0.07))
        cx = pw * 0.5
        gilt_o = (255, 105, 0)

        def rule(y, gilt=True, wide=1):
            dr.line([(m, y), (pw - m, y)], fill=GILT if gilt else dark, width=wide)
            if gilt:
                do.line([(m, y), (pw - m, y)], fill=gilt_o, width=wide)

        if b["bands"]:
            # Raised bands (calf over cords): a lit ridge and its shadow, a gilt rule each side.
            for i in range(b["bands"]):
                y = int(ph * (0.1 + 0.8 * i / (b["bands"] - 1)))
                dr.rectangle([0, y - 4, pw, y - 1], fill=lite)
                dr.rectangle([0, y, pw, y + 4], fill=dark)
                rule(y - 8)
                rule(y + 8)
            panels = [(ph * 0.12, ph * 0.28), (ph * 0.32, ph * 0.48)]
        elif b["labels"]:
            # Law sheep: blind rules across where the cords would be, the two labels between.
            for f in (0.06, 0.2, 0.37, 0.4, 0.57, 0.8, 0.94):
                rule(int(ph * f), gilt=False, wide=2)
            panels = [(ph * 0.21, ph * 0.365), (ph * 0.41, ph * 0.565)]
        else:
            # Publisher's cloth: gilt rules head and tail, a blind frame, the title stamped in gilt.
            for f in (0.045, 0.06, 0.94, 0.955):
                rule(int(ph * f))
            panels = [(ph * 0.1, ph * 0.42), (ph * 0.48, ph * 0.6)]
        labels = b["labels"] or (None, None)
        for n, (text, (top, bottom)) in enumerate(((title, panels[0]), ([author] if author else [], panels[1]))):
            lab = labels[n] if n < len(labels) else None
            if lab and (text or n == 0):
                dr.rectangle([m - 1, top, pw - m, bottom], fill=lab)
                dr.rectangle([m + 1, top + 3, pw - m - 2, bottom - 3], outline=GILT, width=1)
                do.rectangle([m - 1, top, pw - m, bottom], fill=(255, int(0.45 * 255), 0))
            if text:
                inner = pw - m * 2 - 8
                pad = (bottom - top) * 0.08
                size = _lines(dr, text, "bold", top + pad, bottom - pad, cx, inner, GILT, int(pw * (0.22 if n == 0 else 0.17)))
                _lines(do, text, "bold", top + pad, bottom - pad, cx, inner, gilt_o, size)
        if not b["labels"]:
            # The publisher at the foot (Philadelphia and New York were the medical houses).
            pub = ("LEA", "WOOD", "LINDSAY &", "APPLETON")[k % 4]
            f = _font("regular", max(8, int(pw * 0.11)))
            _centred(dr, pub, ph * 0.89, f, cx, GILT)
            _centred(do, pub, ph * 0.89, f, cx, gilt_o)
        # Wear: the head and tail rubbed pale, the joints darker, the lettering a touch soft.
        px = sp.load()
        wear = rng.uniform(0.25, 0.8)
        for yy in range(ph):
            e = max(0.0, 1.0 - min(yy, ph - 1 - yy) / (ph * 0.035))
            for xx in range(pw):
                j = max(0.0, 1.0 - min(xx, pw - 1 - xx) / (pw * 0.12))
                r_, g_, b_ = px[xx, yy]
                k_ = 1.0 - 0.3 * j
                t = e * wear * (0.5 + 0.5 * rng.random())
                px[xx, yy] = (int(r_ * k_ + (190 - r_) * t * 0.5), int(g_ * k_ + (160 - g_) * t * 0.5), int(b_ * k_ + (120 - b_) * t * 0.5))
        sp = sp.filter(ImageFilter.GaussianBlur(0.5))
        img.paste(sp, (x0, y0))
        orm.paste(so, (x0, y0))
        # --- the boards: the same skin or cloth, rubbed at the corners and edges; cloth with a blind
        # stamped frame.
        x0, y0, x1, y1 = cover_rect(k)
        cw, ch = x1 - x0, y1 - y0
        cv = _mottled((cw, ch), color, b["mottle"] * 1.2, rng)
        dc = ImageDraw.Draw(cv)
        if not b["labels"]:
            dc.rectangle([6, 6, cw - 7, ch - 7], outline=dark, width=2)
            dc.rectangle([11, 11, cw - 12, ch - 12], outline=dark, width=1)
        px = cv.load()
        for yy in range(ch):
            for xx in range(cw):
                e = min(xx, cw - 1 - xx, yy, ch - 1 - yy)
                if e < 5 and rng.random() < wear * (1.0 - e / 5.0):
                    r_, g_, b_ = px[xx, yy]
                    px[xx, yy] = ((r_ + 190) // 2, (g_ + 165) // 2, (b_ + 125) // 2)
        img.paste(cv, (x0, y0))
        orm.paste(Image.new("RGB", (cw, ch), (255, rough, 0)), (x0, y0))
    # --- the page edges: cream gone tan at the edge, the leaves' lines along the tile's y.
    x0, y0, x1, y1 = PAGES
    pg = Image.new("RGB", (x1 - x0, y1 - y0))
    px = pg.load()
    for xx in range(x1 - x0):
        line = rng.uniform(0.86, 1.0) * (0.9 if xx % 9 == 0 else 1.0)
        for yy in range(y1 - y0):
            k_ = line * (0.97 + 0.03 * rng.random())
            px[xx, yy] = (int(214 * k_), int(198 * k_), int(160 * k_))
    img.paste(pg, (x0, y0))
    orm.paste(Image.new("RGB", (x1 - x0, y1 - y0), (255, 235, 0)), (x0, y0))
    out = os.path.join(common.MODELS, "medical_books_albedo.png")
    img.save(out)
    orm.save(os.path.join(common.MODELS, "medical_books_orm.png"))
    print("books' sheet ->", os.path.relpath(out, common.ROOT))


# --- The books' shape -------------------------------------------------------------------------------

def _uv(rect, u, v):
    """(u, v) in 0..1 across a sheet rectangle (v up it) -> the sheet's UV."""
    x0, y0, x1, y1 = rect
    return ((x0 + (x1 - x0) * u) / SHEET, 1.0 - (y1 + (y0 - y1) * v) / SHEET)


def book(k, lying=False, at=(0.0, 0.0, 0.0), name=None):
    """Book k standing at the origin (its thickness along x, its foot at y = 0... its middle at
    `at`'s x and z, spine to +z), or lying (its height along x, its lower board down): boards, the
    block of leaves set in from them, a rounded spine; every face's UVs on the books' sheet."""
    _t, _a, _b, h, w, d = doctor.BOOKS[k]
    verts, uvs, faces = [], [], []
    srect, crect = spine_rect(k), cover_rect(k)

    def quad(pts, rect, st):
        base = len(verts)
        verts.extend(pts)
        uvs.extend(_uv(rect, s, t) for s, t in st)
        faces.append([base, base + 1, base + 2, base + 3])

    tb, sq, bulge = 0.003, 0.003, 0.0075  # (round 1: "flat spines")
    zs, zb = d * 0.5 - bulge, -d * 0.5
    flat = [(0.5, 0.5)] * 4

    def slab(xa, xb, ya, yb, za, zc, rect, outer):
        """A box; `outer` (+1 or -1): which x face carries the rect (the rest its middle)."""
        # +x and -x faces
        quad([(xb, ya, zc), (xb, ya, za), (xb, yb, za), (xb, yb, zc)], rect, [(0, 0), (1, 0), (1, 1), (0, 1)] if outer > 0 else flat)
        quad([(xa, ya, za), (xa, ya, zc), (xa, yb, zc), (xa, yb, za)], rect, [(1, 0), (0, 0), (0, 1), (1, 1)] if outer < 0 else flat)
        quad([(xa, yb, zc), (xb, yb, zc), (xb, yb, za), (xa, yb, za)], rect, flat)  # top
        quad([(xa, ya, za), (xb, ya, za), (xb, ya, zc), (xa, ya, zc)], rect, flat)  # bottom
        quad([(xb, ya, za), (xa, ya, za), (xa, yb, za), (xb, yb, za)], rect, flat)  # -z
        quad([(xa, ya, zc), (xb, ya, zc), (xb, yb, zc), (xa, yb, zc)], rect, flat)  # +z

    slab(w * 0.5 - tb, w * 0.5, 0.0, h, zb, zs, crect, 1)
    slab(-w * 0.5, -w * 0.5 + tb, 0.0, h, zb, zs, crect, -1)
    # The leaves: top, bottom and fore-edge (the tile's lines run with the leaves: u across x).
    xa, xb, ya, yb, za = -w * 0.5 + tb, w * 0.5 - tb, sq, h - sq, zb + sq
    u0, u1 = 0.5 - min(0.5, w * 4.0), 0.5 + min(0.5, w * 4.0)
    quad([(xa, yb, zs), (xb, yb, zs), (xb, yb, za), (xa, yb, za)], PAGES, [(u0, 0), (u1, 0), (u1, 1), (u0, 1)])
    quad([(xa, ya, za), (xb, ya, za), (xb, ya, zs), (xa, ya, zs)], PAGES, [(u0, 0), (u1, 0), (u1, 1), (u0, 1)])
    quad([(xb, ya, za), (xa, ya, za), (xa, yb, za), (xb, yb, za)], PAGES, [(u1, 0), (u0, 0), (u0, 1), (u1, 1)])
    # The spine: an arc from board to board, its head and tail closed.
    n = 8
    arc = [(-w * 0.5 + w * j / n, zs + bulge * math.sin(math.pi * j / n) ** 0.55) for j in range(n + 1)]
    base = len(verts)
    for y, t in ((0.0, 0.0), (h, 1.0)):
        for j, (x, z) in enumerate(arc):
            verts.append((x, y, z))
            uvs.append(_uv(srect, j / n, t))
    for j in range(n):
        faces.append([base + j, base + j + 1, base + n + 2 + j, base + n + 1 + j])
    for y, flip in ((h, False), (0.0, True)):
        base = len(verts)
        for x, z in arc:
            verts.append((x, y, z))
            uvs.append(_uv(crect, 0.5, 0.5))
        fan = list(range(base, base + n + 1))
        faces.append(fan if not flip else fan[::-1])
    ax, ay, az = at
    if lying:
        verts = [(y - h * 0.5 + ax, -x + ay, z + az) for x, y, z in verts]
    else:
        verts = [(x + ax, y + ay - h * 0.5, z + az) for x, y, z in verts]
    part = Part(name or "Book%d" % k, smooth=True).add(verts, faces)
    part.uvs = uvs
    return part


def export_plain(prop_id, parts):
    """assets/props/models/<prop_id>.glb of parts that carry their own UVs (a printed sheet)."""
    import bpy

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for part in parts:
        mesh = bpy.data.meshes.new(part.name)
        mesh.from_pydata([(x, -z, y) for x, y, z in part.verts], [], part.faces)
        lay = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li, vi in zip(poly.loop_indices, poly.vertices):
                lay.data[li].uv = part.uvs[vi]
        for poly in mesh.polygons:
            poly.use_smooth = part.smooth
        scene.collection.objects.link(bpy.data.objects.new(part.name, mesh))
    path = os.path.join(common.MODELS, prop_id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)
    tris = sum(len(f) - 2 for p in parts for f in p.faces)
    print("%s: %d parts, %d triangles -> %s" % (prop_id, len(parts), tris, os.path.relpath(path, common.ROOT)))


def books():
    sheet()
    parts = []
    for kit in list(doctor.BOOK_ROWS) + ["book_stack"]:
        places = doctor.book_places(kit)
        for n, (k, size, at, lying) in enumerate(places):
            part = book(k, lying, at, name="Vol%d" % n if kit == "book_row_c" else None)
            uvs = part.uvs
            if lying:
                # A pile set down by hand: each book a few degrees round from the one under it.
                turn = (4.0, -7.0, 9.0)[n % 3]
                part = moved(moved(part, 0, (0, 1, 0), (-at[0], 0, -at[2])), turn, (0, 1, 0), (at[0], 0, at[2]))
            elif kit == "book_row_a" and n == len(places) - 1:
                # The row's last book leans on its neighbour (round 1: "all bolt upright").
                lean = 7.0
                x0, y0 = at[0] - size[0] * 0.5, at[1] - size[1] * 0.5
                shift = size[1] * math.sin(math.radians(lean))
                part = moved(moved(part, 0, (0, 0, 1), (-x0, -y0, 0)), lean, (0, 0, 1), (x0 + shift, y0, 0))
            part.uvs = uvs
            parts.append(part)
    export_plain("medical_books", parts)


# --- The hall's pegs, his coat and hat ----------------------------------------------------------------

def _coat(cx, t):
    """His frock coat hung by its loop on the peg at (cx, 0): the collar bunched over the peg, the
    shoulders dropping from it, the skirts hanging to the knee in folds, the sleeves down its sides."""
    p = doctor.PEGS
    cw, ch, cd = p["coat"]["size"]
    z_wall = t + 0.014
    rng = random.Random(4)
    # (y, half width, half depth, how much the folds stand, how far the front's lap opens)
    # (round 1's critic: "a cardboard cut-out: square spiked shoulders, a ruler-straight hem, no waist
    # or skirt": the shoulders round off and drop, the waist draws in, the skirt flares in deep folds)
    secs = [(0.008, 0.048, 0.030, 0.0, 0.0), (-0.012, 0.074, 0.040, 0.0, 0.0), (-0.04, 0.112, 0.050, 0.01, 0.2),
            (-0.075, 0.150, 0.058, 0.02, 0.4), (-0.12, 0.180, 0.064, 0.03, 0.7), (-0.19, 0.196, 0.068, 0.04, 0.9),
            (-0.30, 0.186, 0.066, 0.05, 1.0), (-0.44, 0.160, 0.060, 0.07, 1.0), (-0.54, 0.172, 0.064, 0.11, 1.0),
            (-0.68, 0.205, 0.072, 0.15, 1.0), (-0.82, 0.232, 0.080, 0.18, 1.0), (-0.94, 0.248, 0.084, 0.20, 1.0),
            (-ch + 0.014, 0.254, 0.086, 0.21, 1.0)]
    n = 56
    ph = [rng.uniform(0, 6.28) for _ in range(3)]
    verts, faces = [], []
    for y, a, b, fold, lap in secs:
        for k in range(n):
            th = 2 * math.pi * k / n
            c, s = math.cos(th), math.sin(th)
            # Folds: mostly on the skirts' back and sides, the fronts flatter; against the wall, flat.
            front = max(0.0, s)
            wob = fold * (0.55 * math.sin(7 * th + ph[0]) + 0.3 * math.sin(11 * th + ph[1]) + 0.15 * math.sin(3 * th + ph[2]))
            rr = 1.0 + wob * (0.6 + 0.4 * front)
            x, z = a * c * rr, b * s * rr
            if s < 0:
                z *= 0.45  # (its back lies to the wall)
            # The fronts lap left over right: a step down the middle of the front.
            if front > 0.6 and lap:
                z += 0.006 * lap * (1.0 if c < 0.02 else 0.0) * min(1.0, (front - 0.6) / 0.2)
            # It hangs a little to one side (one shoulder lower), and its hem dips and lifts with the folds.
            drop = -0.022 * c * min(1.0, max(0.0, (0.008 - y) / 0.12)) * max(0.0, 1.0 - max(0.0, -y - 0.2) / 0.3)
            hem = 0.022 * fold / 0.21 * math.sin(5 * th + ph[1]) * max(0.0, (-y - 0.6) / 0.42)
            sway = 0.035 * max(0.0, -y / ch) ** 1.5
            verts.append((cx + x + sway, y + drop + hem, z_wall + b * 0.45 + z))
    for i in range(len(secs) - 1):
        for k in range(n):
            a_ = i * n + k
            b_ = i * n + (k + 1) % n
            faces.append([a_, b_, b_ + n, a_ + n])
    # Closed above; the hem turned up inside (dark within).
    verts.append((cx, secs[0][0] + 0.004, z_wall + 0.03))
    c_ = len(verts) - 1
    faces += [[c_, (k + 1) % n, k] for k in range(n)]
    base = (len(secs) - 1) * n
    verts.append((cx, secs[-1][0] + 0.05, z_wall + 0.05))
    c_ = len(verts) - 1
    faces += [[c_, base + k, base + (k + 1) % n] for k in range(n)]
    body = Part("b", smooth=True).add(verts, faces)
    parts = [body]
    # The sleeves: hanging from the dropped shoulders, a little forward, creased at the elbow.
    zc = z_wall + 0.066 * 0.45
    for sx in (-1, 1):
        ln = 0.66 if sx < 0 else 0.69   # (one sleeve hangs a little lower, its cuff turned in)
        # (the sleeve's head is sunk in the shoulder: its cap stood up as a spike, round 1)
        pts = [(cx + sx * 0.120, -0.135, zc + 0.016), (cx + sx * 0.176, -0.17 - 0.02 * (sx < 0), zc + 0.022),
               (cx + sx * 0.214, -0.30, zc + 0.034), (cx + sx * 0.212, -0.44, zc + 0.052),
               (cx + sx * 0.196 + 0.02, -0.57, zc + 0.058), (cx + sx * 0.184 + 0.03, -ln, zc + 0.05)]
        radii = [(0.030, 0.034), (0.050, 0.046), (0.050, 0.046), (0.047, 0.042), (0.043, 0.04), (0.040, 0.038)]
        parts.append(tube("s", pts, radii, sides=14, caps=(True, True), noise=0.09, seed=3 + sx))
    # The collar turned down round the neck, the lapels rolling from it down to the top button.
    zf = z_wall + 0.066 * 0.45
    ring = [(cx + math.cos(2 * math.pi * k / 20) * 0.078, -0.004 - 0.012 * abs(math.cos(2 * math.pi * k / 20)), zf + math.sin(2 * math.pi * k / 20) * 0.036)
            for k in range(21)]
    parts.append(tube("c", ring, [(0.016, 0.012)] * 21, sides=8, caps=(False, False)))
    for sx in (-1, 1):
        pts = [(cx + sx * 0.070, -0.02, zf + 0.026), (cx + sx * 0.074, -0.10, zf + 0.060), (cx + sx * 0.058, -0.20, zf + 0.070),
               (cx + sx * 0.030, -0.30, zf + 0.070), (cx + sx * 0.006, -0.37, zf + 0.068)]
        parts.append(tube("l", pts, [(0.030, 0.007), (0.046, 0.008), (0.042, 0.008), (0.028, 0.007), (0.008, 0.005)], sides=8,
                          up_hint=(0, 0, 1)))
    coat = merged("Coat", parts)
    # Its buttons: four down the front's edge, a pair at the back's waist out of sight.
    zb = zf + 0.066 + 0.004
    buttons = [lathe("u", [(0.0, 0.0), (0.011, 0.0), (0.0115, 0.003), (0.006, 0.005), (0.0, 0.0045)], 12, axis="z",
                     at=(cx + 0.022, -0.40 - 0.085 * i, zb + 0.0025 * i)) for i in range(4)]
    return coat, merged("CoatButtons", buttons)


def _hat(hx, t):
    """His hat on its peg: a black felt with a low round crown and a curled brim, the peg up inside
    the crown, its brim against the wall, hanging a little nose down."""
    h = doctor.PEGS["hat"]
    R, r, ch = h["brim"], h["crown"], h["crown_h"]
    felt = lathe("f", [(r - 0.004, -0.003), (R * 0.7, -0.002), (R - 0.006, 0.006), (R, 0.016), (R - 0.004, 0.019), (R * 0.72, 0.004),
                       (r + 0.003, 0.003), (r, 0.012), (r - 0.002, ch * 0.62), (r * 0.9, ch * 0.86), (r * 0.62, ch * 0.985),
                       (0.0, ch)], 32, caps=(False, False))
    # (round 1: "a perfectly symmetric disc and dome": the crown's centre crease, the brim rolled up
    # at its sides and dipped front and back)
    fv = []
    for x, y, z in felt.verts:
        rad = math.hypot(x, z)
        if y > ch * 0.55:
            y -= 0.022 * math.exp(-(z / 0.028) ** 2) * min(1.0, (y - ch * 0.55) / (ch * 0.3))
        if rad > r + 0.01:
            k = (rad - r) / (R - r)
            y += k * k * (0.016 * (z * z - x * x) / (rad * rad))
        fv.append((x, y, z))
    felt.verts = fv
    band = lathe("b", [(r + 0.0035, 0.004), (r + 0.0025, 0.03), (r + 0.0005, 0.031)], 32, caps=(False, False))
    at = (hx, -(r - 0.012), t + 0.03)
    return moved(felt, 97, (1, 0, 0), at, name="Hat"), moved(band, 97, (1, 0, 0), at, name="HatBand")


def pegs():
    p = doctor.PEGS
    t, r, ln = p["thick"], p["peg_r"], p["peg_len"]
    parts = []
    xs = doctor.peg_xs()
    for k, x in enumerate(xs):
        # A turned peg: a plain shank swelling to a mushroom head (the Shaker rail's, and every hall's).
        peg = lathe("Peg%d" % k, [(r * 0.86, -0.004), (r * 0.86, 0.004), (r * 0.74, ln * 0.45), (r * 0.80, ln * 0.66), (r * 1.25, ln * 0.82),
                                  (r * 1.42, ln * 0.92), (r * 1.2, ln * 0.985), (0.0, ln)], 14, axis="z", at=(x, 0, t))
        parts.append((peg, "turned_wood"))
    coat, buttons = _coat(xs[p["coat"]["peg"]], t)
    parts += [(coat, "broadcloth"), (buttons, "horn")]
    hat, band = _hat(xs[p["hat"]["peg"]], t)
    parts += [(hat, "felt"), (band, "ribbon")]
    metal.export_baked("coat_pegs", parts, size=1024)


# --- The chamber pot ----------------------------------------------------------------------------------

def pot():
    c = doctor.CHAMBER
    R, H, F = c["radius"], c["height"], c["foot"]
    body = lathe("Pot", [(F, 0.0), (F + 0.003, 0.006), (F + 0.001, 0.01), (R * 0.80, 0.022), (R * 0.97, 0.05), (R, 0.078),
                         (R * 0.95, 0.108), (R * 0.90, H - 0.01), (R * 0.93, H - 0.004), (R + 0.011, H), (R + 0.012, H + 0.004),
                         (R + 0.006, H + 0.006), (R * 0.87, H + 0.001), (R * 0.85, 0.108), (R * 0.91, 0.078), (R * 0.88, 0.048),
                         (R * 0.6, 0.02), (0.0, 0.015)], 40, caps=(True, False))
    # The handle: a loop from under the rim out and back to the belly (-x), flattened.
    hp = []
    for k in range(10):
        a = math.pi * (0.06 + 0.88 * k / 9.0)
        hp.append((-R * 0.90 - 0.050 * math.sin(a), 0.115 - 0.072 * k / 9.0, 0.0))
    handle = tube("h", hp, [(0.007, 0.012)] * len(hp), sides=12, up_hint=(0, 0, 1))
    band = torus_ring("PotBand", R * 0.912, H - 0.02, 0.002)
    lh, kn = c["lid_h"], c["knob"]
    lid = lathe("Lid", [(R * 0.80, H - 0.004), (R * 0.86, H + 0.003), (R * 0.88, H + 0.007), (R * 0.80, H + 0.013), (R * 0.5, H + lh * 0.72),
                        (R * 0.2, H + lh * 0.95), (0.012, H + lh), (0.010, H + lh + kn * 0.3), (0.020, H + lh + kn * 0.7),
                        (0.016, H + lh + kn * 0.95), (0.0, H + lh + kn)], 40, caps=(True, False))
    metal.export_baked("chamber_pot", [(merged("Pot", [body, handle]), "china"), (band, "cobalt"), (lid, "china")], size=512)


# --- Folded blankets ----------------------------------------------------------------------------------

def folded(name, size, layers, seed, at=(0.0, 0.0, 0.0), turn=0.0):
    """A blanket folded back and forth on itself into `layers` and laid flat: its section a ribbon
    winding up from the bottom layer, a rounded bight at each turn (+x, -x, +x ...), drawn along z;
    soft: each layer a little out of line with the one under it, the edges drooping, the top rumpled."""
    w, hgt, d = size
    rng = random.Random(seed)
    pitch = hgt / layers
    ht = pitch * 0.495  # (the layers lie on each other: round 0's pile read as loose sheets with gaps)
    rb = pitch * 0.5
    path = []
    for i in range(layers):
        y = pitch * (i + 0.5)
        out = i % 2 == 0  # this layer runs toward +x
        inset = rng.uniform(0.0, 0.012)
        xa, xb = -w * 0.5 + rb + inset, w * 0.5 - rb - rng.uniform(0.0, 0.012)
        run = [xa + (xb - xa) * k / 10 for k in range(11)]
        if not out:
            run.reverse()
        if i == 0:
            run[0] = -w * 0.5 + 0.004
        if i == layers - 1:
            run[-1] = (w * 0.5 - 0.02) if out else (-w * 0.5 + 0.02)
        path += [(x, y) for x in run]
        if i < layers - 1:
            xc = run[-1]
            sgn = 1.0 if out else -1.0
            for k in range(1, 6):
                a = -math.pi * 0.5 + math.pi * k / 6
                path.append((xc + sgn * rb * math.cos(a), y + rb + rb * math.sin(a)))
    ns = len(path)
    nz = 14
    phz = [rng.uniform(0, 6.28) for _ in range(3)]
    outer, inner = [], []
    for j in range(nz + 1):
        fz = j / nz
        z = -d * 0.5 + d * fz
        edge = abs(2 * fz - 1) ** 6
        for i, (x, y) in enumerate(path):
            x0, y0 = path[max(0, i - 1)]
            x1, y1 = path[min(ns - 1, i + 1)]
            tx, ty = x1 - x0, y1 - y0
            ln = math.hypot(tx, ty) or 1.0
            nx, ny = -ty / ln, tx / ln
            up = y / hgt
            # The edges of the upper layers droop and draw in; a slow wave over the top.
            dy = -0.016 * edge * up + 0.006 * up * math.sin(x * 14 + z * 9 + phz[0]) + 0.004 * up * math.sin(x * 31 - z * 17 + phz[2])
            dz = -math.copysign(0.006 * up * abs(math.sin(i * 0.7 + phz[1])), 2 * fz - 1) * (1.0 if j in (0, nz) else 0.0)
            k_ = 1.0 - 0.12 * edge
            outer.append((x + nx * ht * k_, y + dy + ny * ht * k_, z + dz))
            inner.append((x - nx * ht * k_, y + dy - ny * ht * k_, z + dz))
    verts = outer + inner
    off = len(outer)
    faces = []
    for j in range(nz):
        for i in range(ns - 1):
            a = j * ns + i
            faces.append([a, a + ns, a + ns + 1, a + 1])
            faces.append([off + a, off + a + 1, off + a + ns + 1, off + a + ns])
    for i in range(ns - 1):  # the two ends (the blanket's edges, layer on layer)
        faces.append([i, i + 1, off + i + 1, off + i])
        a = nz * ns + i
        faces.append([a + 1, a, off + a, off + a + 1])
    for j in range(nz):  # the ribbon's own two ends
        a = j * ns
        faces.append([a, off + a, off + a + ns, a + ns])
        a = j * ns + ns - 1
        faces.append([a + ns, off + a + ns, off + a, a])
    # (the path winds bottom up with its left normal: where a layer runs back, the skins swap; both
    # are closed, so only the winding matters: Blender's normals are made consistent at export)
    part = Part(name, smooth=True).add(verts, faces)
    return moved(part, turn, (0, 1, 0), at, name=name)


def blankets():
    b = doctor.BLANKET
    bx, by, bz = b["size"]
    parts = []
    for k, finish in enumerate(b["finishes"]):
        size = (bx - 0.012 * k, by, bz - 0.008 * k)
        parts.append((folded("Blanket%d" % k, size, b["layers"], 20 + k, at=((0.0, 0.006, -0.004)[k], by * k, (0.0, -0.005, 0.006)[k]),
                             turn=(0.0, 3.0, -2.0)[k]), finish))
    metal.export_baked("folded_blankets", parts, size=1024, recalc_normals=True)


def build():
    books()
    pegs()
    pot()
    blankets()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for f in (books, pegs, pot, blankets):
        if only is None or f.__name__ in only:
            f()
