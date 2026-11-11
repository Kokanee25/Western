"""The doctor's office, batch D1 (#788; docs/briefs/prop-factory.md "The doctor's office batch"):
the parts of the examining table, the iron cot, the wash set, the instrument tray and the reflector
lamp that aren't library wood, modelled here in the kit's space from tools/props/doctor.py's numbers
and baked the gun way (metal.py): japanned iron, nickel and steel, brass and tin, white ironstone,
oilcloth, ticking and wool.

    ~/bpyenv/bin/python tools/blender/props/build.py --only=doctor_d1    (~1 min a model)

Then `godot --headless --import` and commit the .glb and .png files with their .import files.
"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import common  # noqa: E402
import doctor  # noqa: E402  (tools/props/doctor.py: the numbers)
import metal  # noqa: E402
from common import Part, box, lathe, moved, tube  # noqa: E402


def merged(name, parts, smooth=True):
    out = Part(name, smooth)
    for p in parts:
        out.merge(p)
    return out


def soft_box(name, size, at, e=0.3, rings=14, segs=28, flat_bottom=True, finish_bulge=0.0):
    """A soft, rounded box (a superellipsoid: a sphere's directions pushed out by |u|^e; e 0.15 boxy,
    1 round): a straw tick, a pillow, a folded cloth. `flat_bottom` sits it on its foot;
    `finish_bulge` swells its top in the middle (a stuffed pillow)."""
    a, b, c = (float(v) * 0.5 for v in size)
    f = lambda u: math.copysign(abs(u) ** e, u)
    verts = [(0.0, -b, 0.0)]
    for i in range(1, rings):
        phi = math.pi * i / rings - math.pi * 0.5
        for k in range(segs):
            th = 2 * math.pi * k / segs
            ux, uy, uz = math.cos(phi) * math.cos(th), math.sin(phi), math.cos(phi) * math.sin(th)
            x, y, z = a * f(ux), b * f(uy), c * f(uz)
            if finish_bulge and y > 0:
                y += finish_bulge * (1 - (x / a) ** 2) * (1 - (z / c) ** 2)
            verts.append((x, y, z))
    verts.append((0.0, b, 0.0))
    faces = []
    for k in range(segs):
        faces.append([0, 1 + k, 1 + (k + 1) % segs])
    for i in range(rings - 2):
        for k in range(segs):
            p0 = 1 + i * segs + k
            p1 = 1 + i * segs + (k + 1) % segs
            faces.append([p0, p0 + segs, p1 + segs, p1])
    top = len(verts) - 1
    base = 1 + (rings - 2) * segs
    for k in range(segs):
        faces.append([top, base + (k + 1) % segs, base + k])
    if flat_bottom:
        verts = [(x, max(y, -b * 0.92), z) for x, y, z in verts]
    ax, ay, az = at
    return Part(name, smooth=True).add([(x + ax, y + ay, z + az) for x, y, z in verts], faces)


def drape(name, half_w, top_fn, z0, z1, hang=0.2, r=0.05, thick=0.008, nz=24, folds=0.012, seed=1):
    """A blanket laid over a bed: across x its section rises from a hem `hang` below the top at
    -half_w, rounds over the edge (radius r), lies on the top (`top_fn(x, z)`), and falls the same
    the other side; along z from z0 to z1; soft folds in what hangs. A thin solid (two skins)."""
    import random
    rng = random.Random(seed)
    phase = [rng.uniform(0, 6.28) for _ in range(4)]
    section = []
    for k in range(6):
        section.append((-half_w, -hang + (hang - r) * k / 5))
    for k in range(1, 7):
        t = math.pi * 0.5 * k / 6
        section.append((-half_w + r - r * math.cos(t), -r + r * math.sin(t)))
    n_top = 8
    for k in range(1, n_top):
        section.append((-half_w + r + (2 * (half_w - r)) * k / n_top, 0.0))
    for k in range(0, 6):
        t = math.pi * 0.5 * k / 6
        section.append((half_w - r + r * math.sin(t), -r + r * math.cos(t)))
    for k in range(6):
        section.append((half_w, -r - (hang - r) * k / 5))
    ns = len(section)
    outer, inner = [], []
    for j in range(nz + 1):
        z = z0 + (z1 - z0) * j / nz
        for sx, sy in section:
            hang_share = min(1.0, max(0.0, -sy - r) / max(1e-6, hang - r))
            wob = folds * hang_share * (math.sin(z * 23 + phase[0] + sx) + 0.6 * math.sin(z * 41 + phase[1]))
            x = sx + math.copysign(wob, sx)
            y = top_fn(max(-half_w + r, min(half_w - r, sx)), z) + sy
            outer.append((x, y, z))
            nxs = -1.0 if sx < -half_w + r * 0.5 else (1.0 if sx > half_w - r * 0.5 else 0.0)
            inner.append((x - nxs * thick, y - (thick if nxs == 0.0 else 0.0), z))
    verts = outer + inner
    off = len(outer)
    faces = []
    for j in range(nz):
        for i in range(ns - 1):
            a = j * ns + i
            faces.append([a, a + 1, a + ns + 1, a + ns])
            faces.append([off + a, off + a + ns, off + a + ns + 1, off + a + 1])
    for i in range(ns - 1):  # the ends
        faces.append([i + 1, i, off + i, off + i + 1])
        a = nz * ns + i
        faces.append([a, a + 1, off + a + 1, off + a])
    for j in range(nz):  # the hems
        a = j * ns
        faces.append([a + ns, a, off + a, off + a + ns])
        a = j * ns + ns - 1
        faces.append([a, a + ns, off + a + ns, off + a])
    return Part(name, smooth=True).add(verts, faces)


# --- The examining table's pads -------------------------------------------------------------------

def cushion(name, x0, x1, z0, z1, y0, h0, h1, button=0.14, roll=0.022, dimple=0.02, n=3):
    """A buttoned cushion on the box x0..x1, z0..z1 from y0, its top h0 high at x0 and h1 at x1 (a
    wedge if they differ): a grid top drawn in at each button of a diamond pattern, its edges rolled
    over, sides down to y0, a flat bottom; the buttons themselves little discs."""
    nx = max(2, int(round((x1 - x0) / button * n)))
    nz = max(2, int(round((z1 - z0) / button * n)))
    rows = [z0 + button * 0.5 + k * button * 0.5 for k in range(int((z1 - z0 - button) / (button * 0.5)) + 2)]
    rows = [z for z in rows if z < z1 - button * 0.35]
    buttons = []
    for k, z in enumerate(rows):
        off = button * 0.5 if k % 2 else 0.0
        x = x0 + button * 0.5 + off
        while x < x1 - button * 0.35:
            buttons.append((x, z))
            x += button

    def top(x, z):
        h = h0 + (h1 - h0) * (x - x0) / max(1e-6, x1 - x0)
        d = 0.0
        for bx, bz in buttons:
            r2 = ((x - bx) ** 2 + (z - bz) ** 2) / (0.028 ** 2)
            if r2 < 9.0:
                d = max(d, math.exp(-r2))
        e = min(x - x0, x1 - x, z - z0, z1 - z)
        edge = (1.0 - min(1.0, e / roll)) ** 2 * roll * 0.9
        return y0 + h - dimple * d - edge

    verts, faces = [], []
    for j in range(nz + 1):
        for i in range(nx + 1):
            x = x0 + (x1 - x0) * i / nx
            z = z0 + (z1 - z0) * j / nz
            verts.append((x, top(x, z), z))
    idx = lambda i, j: j * (nx + 1) + i
    for j in range(nz):
        for i in range(nx):
            faces.append([idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j)])
    # The boundary, anticlockwise seen from above, and its foot at y0.
    ring = [idx(i, 0) for i in range(nx)] + [idx(nx, j) for j in range(nz)] + [idx(i, nz) for i in range(nx, 0, -1)] + [idx(0, j) for j in range(nz, 0, -1)]
    base = len(verts)
    for k in ring:
        vx, _, vz = verts[k]
        verts.append((vx, y0, vz))
    m = len(ring)
    for k in range(m):
        a, b = ring[k], ring[(k + 1) % m]
        faces.append([a, b, base + (k + 1) % m, base + k])
    verts.append((0.5 * (x0 + x1), y0, 0.5 * (z0 + z1)))
    c = len(verts) - 1
    faces += [[c, base + (k + 1) % m, base + k] for k in range(m)]
    part = Part(name, smooth=True).add(verts, faces)
    for bx, bz in buttons:
        part.merge(lathe("b", [(0.008, -0.002), (0.009, 0.001), (0.006, 0.004), (0.0, 0.005)], 8, at=(bx, top(bx, bz) - 0.003, bz)))
    return part


def table():
    t = doctor.TABLE
    H = t["top"]
    p = t["pad"]
    pad = cushion("Pad", p["x"] - p["length"] * 0.5, p["x"] + p["length"] * 0.5, -p["width"] * 0.5, p["width"] * 0.5, H,
                  p["height"], p["height"], button=p["button"])
    h = t["head"]
    w = h["width"] * 0.5
    head = cushion("HeadPad", h["x"] - h["length"] * 0.5, h["x"] + h["length"] * 0.5, -w, w, H, h["low"] + 0.02, h["high"],
                   button=p["button"])
    parts = [(pad, "leather"), (head, "leather")]
    # The drawers' knobs: turned brass, one a drawer.
    for c, r_, (dw, dh), (x, y, zf) in doctor.table_drawers():
        z = zf + t["drawer_t"] * 0.5
        parts.append((lathe("Knob_%d_%d" % (c, r_), [(0.009, 0.0), (0.011, 0.008), (0.006, 0.014), (0.014, 0.022), (0.012, 0.028), (0.0, 0.03)],
                            12, axis="z", at=(x, y, z)), "brass"))
    metal.export_baked("examining_table", parts, size=1024)


# --- The iron cot ---------------------------------------------------------------------------------

def cot():
    c = doctor.COT
    L, W = c["length"], c["width"]
    px, pz = W * 0.5 - c["post"] * 0.5, L * 0.5 - c["post"] * 0.5
    parts = []
    r = c["post"] * 0.5
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        h = c["head_h"] if sz < 0 else c["foot_h"]
        x, z = sx * px, sz * pz
        post = tube("p", [(x, 0.0, z), (x, h - 0.03, z)], r, sides=10)
        cup = lathe("c", [(r * 1.25, 0.0), (r * 1.35, 0.012), (r * 1.1, 0.03)], 10, at=(x, 0, z))
        knob = lathe("k", [(r * 1.1, h - 0.035), (r * 1.6, h - 0.02), (r * 1.7, h - 0.005), (r * 1.35, h + 0.012), (0.004, h + 0.02)], 10, at=(x, 0, z))
        parts.append((merged("Post%d" % i, [post, cup, knob]), "japanned"))
    rr = c["rail"] * 0.5
    inner = px - r
    for end, sz, ys in (("Head", -1, c["head_rails"]), ("Foot", 1, c["foot_rails"])):
        z = sz * pz
        for k, y in enumerate(ys):
            parts.append((tube("%sRail%d" % (end, k), [(-inner - 0.004, y, z), (inner + 0.004, y, z)], rr, sides=8), "japanned"))
        rods = []
        n = c["fillers"]
        for k in range(n):
            x = -inner + (k + 1) * (inner * 2) / (n + 1)
            rods.append(tube("f", [(x, ys[0], z), (x, ys[1], z)], 0.005, sides=6, caps=(False, False)))
        parts.append((merged("%sFill" % end, rods), "japanned"))
    # The angle-iron side rails: an L, its flat leg under the spring's edge.
    inner_z = pz - r
    y = c["spring_y"]
    for s, name in ((-1, "L"), (1, "R")):
        x = s * (px - 0.004)
        up = box("u", (0.004, c["side"], inner_z * 2), (x + s * 0.008, y - c["side"] * 0.5, 0), bevel=0.0015)
        flat = box("f", (c["side"], 0.004, inner_z * 2), (x - s * 0.01, y - 0.002, 0), bevel=0.0015)
        parts.append((merged("Side" + name, [up, flat], smooth=False), "japanned"))
    # The woven wire spring: wires both ways in a frame between the side rails.
    wires = []
    sx = px - 0.03
    sz = inner_z - 0.01
    for k in range(int(sx * 2 / 0.09) + 1):
        x = -sx + k * 0.09
        wires.append(box("w", (0.003, 0.003, sz * 2), (x, y - 0.006, 0)))
    for k in range(int(sz * 2 / 0.1) + 1):
        z = -sz + k * 0.1
        wires.append(box("w", (sx * 2, 0.003, 0.003), (0, y - 0.004, z)))
    parts.append((merged("Spring", wires, smooth=False), "japanned"))
    # The straw tick, soft and sagging where he lies; the blanket laid over its foot two-thirds,
    # rounding over its edges and hanging down both sides in soft folds, turned down at its head;
    # the pillow stuffed, in a white case (the 1864-65 wards' beds: grey wool, white pillows).
    tx, ty, tz = c["tick"]
    sag = lambda vx, vz: 0.035 * max(0.0, 1 - (2 * vz / tz) ** 2) * max(0.0, 1 - (2 * vx / tx) ** 2)
    # A tufted straw tick (ticks were tied through at a handspan's spacing): the table pad's buttoned
    # cushion, its tufts wide apart, its edges rolled well over, sagging where he lies.
    tick = cushion("Tick", -tx * 0.5, tx * 0.5, -tz * 0.5, tz * 0.5, y, ty, ty, button=0.32, roll=0.05, dimple=0.016, n=5)
    tick.verts = [(vx, vy - (sag(vx, vz) if vy > y + 0.02 else 0.0), vz) for vx, vy, vz in tick.verts]
    parts.append((tick, "ticking"))
    bx, by, bz = c["blanket"]
    top = y + ty
    bz0 = tz * 0.5 - bz
    # Its top a little clear of the tick, rumpled (two slow waves and a finer one across it).
    top_fn = lambda x, z: top + 0.014 - sag(x, z) + 0.008 * math.sin(z * 7.0 + x * 3.0) * math.sin(x * 9.0 + 1.3) + 0.004 * math.sin(z * 19.0 - x * 11.0)
    blanket = drape("Blanket", tx * 0.5 + 0.02, top_fn, bz0, tz * 0.5 + 0.015, hang=0.2, r=0.055, folds=0.022, nz=14)
    turn = drape("d", tx * 0.5 + 0.03, lambda x, z: top_fn(x, z) + 0.012, bz0 - 0.02, bz0 + 0.17, hang=0.08, r=0.05, nz=6, seed=3)
    blanket.merge(turn)
    parts.append((blanket, "wool"))
    qx, qy, qz = c["pillow"]
    pillow = soft_box("Pillow", (qx, qy * 0.8, qz), (0, top - sag(0.0, -tz * 0.5 + qz * 0.5) + qy * 0.4, -tz * 0.5 + qz * 0.5 + 0.03), e=0.45, finish_bulge=0.02)
    parts.append((pillow, "linen"))
    metal.export_baked("iron_cot", parts, size=1024)


# --- The wash set (basin and pitcher, white ironstone with a cobalt line; the washstand's knob and
# its towel) -------------------------------------------------------------------------------------

def torus_ring(name, radius, y, tube_r, segs=40, sides=6):
    pts = [(math.cos(2 * math.pi * k / segs) * radius, y, math.sin(2 * math.pi * k / segs) * radius) for k in range(segs + 1)]
    return tube(name, pts, tube_r, sides=sides, caps=(False, False))


def washset():
    b = doctor.BASIN
    R, H = b["radius"], b["height"]
    basin = lathe("Basin", [(b["foot"], 0.0), (b["foot"] + 0.004, 0.008), (R * 0.62, 0.025), (R * 0.88, 0.06), (R, H - 0.006),
                            (R + 0.006, H), (R - 0.004, H + 0.002), (R - 0.012, H - 0.008), (R * 0.85, 0.06),
                            (R * 0.58, 0.028), (b["foot"] - 0.004, 0.014), (0.0, 0.014)], 36, caps=(True, False))
    basin_band = torus_ring("BasinBand", R + 0.0035, H - 0.009, 0.0022)
    p = doctor.PITCHER
    PR, PH = p["radius"], p["height"]
    body = lathe("Pitcher", [(p["foot"], 0.0), (p["foot"] + 0.004, 0.01), (PR * 0.95, 0.06), (PR, 0.11), (PR * 0.88, 0.17),
                             (PR * 0.66, 0.235), (PR * 0.70, 0.27), (PR * 0.82, PH - 0.005), (PR * 0.84, PH),
                             (PR * 0.78, PH), (PR * 0.64, 0.25), (PR * 0.60, 0.22), (PR * 0.82, 0.15), (PR * 0.86, 0.07),
                             (0.0, 0.012)], 36, caps=(True, False))
    # The lip: the rim's +x side drawn out and up into a spout.
    verts = []
    for vx, vy, vz in body.verts:
        if vy > 0.24 and vx > 0.0:
            k = (vx / max(1e-6, math.hypot(vx, vz))) ** 6 * min(1.0, (vy - 0.24) / (PH - 0.24))
            vx += 0.05 * k
            vy += 0.012 * k
        verts.append((vx, vy, vz))
    body.verts = verts
    # The handle: a smooth loop from under the rim to the belly, flattened.
    hp = []
    for k in range(10):
        t = k / 9.0
        ang = math.pi * (0.1 + 0.8 * t)
        hp.append((-PR * 0.72 - 0.065 * math.sin(ang) - 0.01 * t, 0.275 - 0.185 * t, 0.0))
    handle = tube("h", hp, [(0.0075, 0.012)] * len(hp), sides=12, up_hint=(0, 0, 1))
    pitcher = merged("Pitcher", [body, handle])
    pitcher_band = torus_ring("PitcherBand", PR * 0.835, PH - 0.012, 0.002)
    w = doctor.WASH
    under = w["top"] - w["board"]
    lz = w["depth"] * 0.5 - w["inset"] - w["leg"] * 0.5
    zf = lz + w["leg"] * 0.5 + 0.001
    knob = lathe("Knob", [(0.012, 0.0), (0.016, 0.006), (0.015, 0.016), (0.008, 0.02), (0.0, 0.022)], 12, axis="z",
                 at=(0, under - w["apron_h"] * 0.5, zf))
    metal.export_baked("washset", [(basin, "china"), (basin_band, "cobalt"), (pitcher, "china"), (pitcher_band, "cobalt"), (knob, "brass")], size=1024)


# --- The instrument tray --------------------------------------------------------------------------

def tray():
    sx, sy, sz = doctor.TRAY["size"]
    fy = 0.004
    tray_parts = [box("floor", (sx - 0.04, 0.003, sz - 0.04), (0, 0.0015, 0), bevel=0.001)]
    # The flared walls and the rolled rim.
    for s in (-1, 1):
        tray_parts.append(moved(box("w", (sx - 0.02, 0.028, 0.003), (0, 0.014, 0)), s * 25, (1, 0, 0), (0, 0, s * (sz * 0.5 - 0.016))))
        tray_parts.append(moved(box("w", (0.003, 0.028, sz - 0.02), (0, 0.014, 0)), -s * 25, (0, 0, 1), (s * (sx * 0.5 - 0.016), 0, 0)))
    rim = [(-sx * 0.5, 0.026, -sz * 0.5), (sx * 0.5, 0.026, -sz * 0.5), (sx * 0.5, 0.026, sz * 0.5), (-sx * 0.5, 0.026, sz * 0.5), (-sx * 0.5, 0.026, -sz * 0.5)]
    tray_parts.append(tube("r", rim, 0.003, sides=6, caps=(False, False)))
    parts = [(merged("Tray", tray_parts, smooth=False), "japanned")]
    # A folded linen cloth in it, the instruments laid out on it (the target sheet's table).
    # (a white napkin folded on the black tray: the instruments read on it, as the target's on linen)
    parts.append((soft_box("Cloth", (sx - 0.03, 0.01, sz - 0.03), (0, fy + 0.003, 0), e=0.12, rings=6, segs=20), "linen"))
    cy = fy + 0.008
    # The amputation saw (a capital saw): a deep blade, its teeth along the lower edge, the back's
    # spine, an ebony handle.
    teeth = [(0.13, -0.025)]
    x = 0.13
    while x > -0.10:
        teeth += [(x - 0.002, -0.029), (x - 0.004, -0.025)]
        x -= 0.004
    outline = [(-0.10, 0.012), (-0.10, -0.025)] + sorted(teeth, key=lambda t: t[0]) + [(0.13, 0.012)]
    blade = moved(common.slab("b", outline, -0.0007, 0.0007), -90, (1, 0, 0), (0.035, cy + 0.003, -0.055))
    spine = box("k", (0.23, 0.005, 0.008), (0.05, cy + 0.004, -0.067), bevel=0.0015)
    parts.append((merged("SawBlade", [blade, spine], smooth=False), "steel"))
    # Its handle: a pistol grip in ebony, flat, its heel swept down (as the Weiss and Teufel sets' saws).
    grip = common.slab("g", [(-0.155, -0.035), (-0.12, -0.04), (-0.095, -0.012), (-0.085, 0.014), (-0.10, 0.018), (-0.14, 0.012), (-0.16, -0.008)], -0.009, 0.009, bevel=0.003)
    parts.append((moved(grip, -90, (1, 0, 0), (0.035, cy + 0.009, -0.055), name="SawHandle"), "ebony"))
    # The bullet forceps: two long jaws crossing at a joint, finger rings.
    fz = 0.012
    jaws = [moved(box("j", (0.19, 0.005, 0.007), (0, 0, 0), bevel=0.0018), a_, (0, 1, 0), (0.01, cy + 0.0035, fz)) for a_ in (3.5, -3.5)]
    rings = [moved(torus_ring("o", 0.013, 0.0, 0.0022, segs=16, sides=6), 0, (0, 1, 0), (-0.1, cy + 0.003, fz + s_ * 0.014)) for s_ in (-1, 1)]
    parts.append((merged("Forceps", jaws + rings), "nickel"))
    # Nelaton's probe: a long slender rod, its tip a bead of unglazed porcelain.
    parts.append((tube("Probe", [(-0.13, cy + 0.003, 0.055), (0.125, cy + 0.003, 0.064)], 0.0025, sides=8), "nickel"))
    parts.append((common.blob("ProbeTip", (0.128, cy + 0.004, 0.0642), (0.005, 0.005, 0.005), rings=5, sides=8), "china"))
    # A scalpel: a bellied blade and an octagonal ebony handle.
    sb = common.slab("s", [(0.0, 0.0), (0.04, 0.0), (0.03, 0.009), (0.0, 0.007)], -0.0006, 0.0006)
    parts.append((moved(sb, -90, (1, 0, 0), (0.055, cy + 0.002, 0.092), name="ScalpelBlade"), "steel"))
    parts.append((tube("ScalpelHandle", [(-0.045, cy + 0.007, 0.095), (0.055, cy + 0.007, 0.095)], (0.008, 0.006), sides=8), "ebony"))
    metal.export_baked("instrument_tray", parts, size=1024)


# --- The reflector lamp: a wall bracket lamp (the references: a tin reflector disc on the wall
# behind the chimney, the fount in a ring on the bracket) --------------------------------------

def lamp():
    wz = -doctor.LAMP["wall"]  # the wall's face behind it (the lamp's axis at the origin)
    # The fount: a tin font in the bracket's ring, the brass collar and burner on it.
    font = lathe("Font", [(0.035, 0.05), (0.052, 0.06), (0.058, 0.09), (0.055, 0.13), (0.04, 0.155), (0.026, 0.165), (0.024, 0.17)], 24)
    burner = merged("Burner", [lathe("b", [(0.024, 0.17), (0.028, 0.176), (0.028, 0.19), (0.034, 0.196), (0.031, 0.203)], 16),
                               *[tube("g", [(math.cos(a_) * 0.031, 0.198, math.sin(a_) * 0.031), (math.cos(a_) * 0.039, 0.214, math.sin(a_) * 0.039)], 0.0025, sides=5)
                                 for a_ in (0.3, 2.4, 4.5)],
                               box("w", (0.016, 0.01, 0.01), (0.042, 0.184, 0.0), bevel=0.003)])
    # A bulged ("globe") chimney, as the wall lamp's.
    chimney = lathe("Chimney", [(0.031, 0.198), (0.036, 0.215), (0.046, 0.245), (0.05, 0.27), (0.044, 0.3), (0.03, 0.33), (0.024, 0.37), (0.023, 0.43)], 24,
                    caps=(False, False))
    # The reflector: a dished tin disc 22 cm across on the wall behind the chimney, rolled at its
    # edge; a hanging tab with the nail's hole over it.
    dish = lathe("d", [(0.0, -0.014), (0.035, -0.011), (0.062, -0.002), (0.074, 0.009), (0.076, 0.012), (0.073, 0.011), (0.06, 0.002), (0.035, -0.007), (0.0, -0.010)],
                 32, axis="z", at=(0, 0.28, wz + 0.016), caps=(False, False))
    tab = box("t", (0.03, 0.05, 0.004), (0, 0.375, wz + 0.004), bevel=0.0012)
    reflector = merged("Reflector", [dish, tab])
    # The bracket: a strap from the disc's foot out to a ring round the fount, a brace under it.
    strap = tube("s", [(0, 0.16, wz + 0.006), (0, 0.075, wz + 0.01), (0, 0.06, -0.06), (0, 0.06, -0.045)], [(0.004, 0.009)] * 4, sides=6, up_hint=(1, 0, 0))
    ring = torus_ring("r", 0.06, 0.07, 0.004, segs=24, sides=6)
    brace = tube("e", [(0, 0.11, wz + 0.008), (0, 0.065, -0.055)], 0.003, sides=5)
    bracket = merged("Bracket", [strap, ring, brace])
    metal.export_baked("reflector_lamp", [(font, "tin"), (burner, "brass"), (chimney, "glass"), (reflector, "tin"), (bracket, "japanned")], size=1024)


def build():
    table()
    cot()
    washset()
    tray()
    lamp()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for f in (table, cot, washset, tray, lamp):
        if only is None or f.__name__ in only:
            f()
