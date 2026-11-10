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


# --- The examining table's pads -------------------------------------------------------------------

def cushion(name, x0, x1, z0, z1, y0, h0, h1, button=0.14, roll=0.02, dimple=0.012, n=3):
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
    for k in range(int(sx * 2 / 0.06) + 1):
        x = -sx + k * 0.06
        wires.append(box("w", (0.003, 0.003, sz * 2), (x, y - 0.006, 0)))
    for k in range(int(sz * 2 / 0.07) + 1):
        z = -sz + k * 0.07
        wires.append(box("w", (sx * 2, 0.003, 0.003), (0, y - 0.004, z)))
    parts.append((merged("Spring", wires, smooth=False), "japanned"))
    # The straw tick, sagging a little in the middle; the blanket over its foot two-thirds,
    # hanging at the sides; the pillow at the head.
    tx, ty, tz = c["tick"]
    tick = box("Tick", (tx, ty, tz), (0, y + ty * 0.5, 0), smooth=True, bevel=0.045)
    tv = []
    for vx, vy, vz in tick.verts:
        sag = 0.018 * (1 - (2 * vz / tz) ** 2) * (1 - (2 * vx / tx) ** 2) if vy > y + ty * 0.5 else 0.0
        tv.append((vx, vy - sag, vz))
    tick.verts = tv
    parts.append((tick, "ticking"))
    bx, by, bz = c["blanket"]
    top = y + ty
    bz0 = tz * 0.5 - bz
    blanket = merged("Blanket", [
        box("t", (bx + 0.02, by, bz), (0, top + by * 0.5 - 0.012, bz0 + bz * 0.5), bevel=0.006),
        box("s", (0.012, 0.16, bz), (-(bx + 0.02) * 0.5, top - 0.07, bz0 + bz * 0.5), bevel=0.004),
        box("s", (0.012, 0.16, bz), ((bx + 0.02) * 0.5, top - 0.07, bz0 + bz * 0.5), bevel=0.004),
        box("e", (bx + 0.02, 0.14, 0.012), (0, top - 0.06, tz * 0.5 + 0.006), bevel=0.004),
        # The turn-down at its head edge.
        box("d", (bx + 0.02, 0.012, 0.16), (0, top + by + 0.002 - 0.012, bz0 + 0.08), bevel=0.004),
    ], smooth=True)
    parts.append((blanket, "wool"))
    qx, qy, qz = c["pillow"]
    pillow = box("Pillow", (qx, qy, qz), (0, top + qy * 0.5 - 0.01, -tz * 0.5 + qz * 0.5 + 0.03), smooth=True, bevel=0.045)
    parts.append((pillow, "ticking"))
    metal.export_baked("iron_cot", parts, size=1024)


# --- The wash set (basin and pitcher, white ironstone; the washstand's drawer knob) ----------------

def washset():
    b = doctor.BASIN
    R, H = b["radius"], b["height"]
    basin = lathe("Basin", [(b["foot"], 0.0), (b["foot"] + 0.004, 0.008), (R * 0.62, 0.025), (R * 0.88, 0.06), (R, H - 0.006),
                            (R + 0.006, H), (R - 0.004, H + 0.002), (R - 0.012, H - 0.008), (R * 0.85, 0.06),
                            (R * 0.58, 0.028), (b["foot"] - 0.004, 0.014), (0.0, 0.014)], 28, caps=(True, False))
    p = doctor.PITCHER
    PR, PH = p["radius"], p["height"]
    body = lathe("Pitcher", [(p["foot"], 0.0), (p["foot"] + 0.004, 0.01), (PR * 0.95, 0.06), (PR, 0.11), (PR * 0.88, 0.17),
                             (PR * 0.66, 0.235), (PR * 0.70, 0.27), (PR * 0.82, PH - 0.005), (PR * 0.84, PH),
                             (PR * 0.78, PH), (PR * 0.64, 0.25), (PR * 0.60, 0.22), (PR * 0.82, 0.15), (PR * 0.86, 0.07),
                             (0.0, 0.012)], 28, caps=(True, False))
    # The lip: the rim's +x side drawn out and up into a spout.
    verts = []
    for vx, vy, vz in body.verts:
        if vy > 0.24 and vx > 0.0:
            k = (vx / max(1e-6, math.hypot(vx, vz))) ** 6 * min(1.0, (vy - 0.24) / (PH - 0.24))
            vx += 0.05 * k
            vy += 0.012 * k
        verts.append((vx, vy, vz))
    body.verts = verts
    handle = tube("h", [(-PR * 0.74, 0.275, 0), (-PR - 0.04, 0.26, 0), (-PR - 0.055, 0.19, 0), (-PR - 0.03, 0.12, 0), (-PR * 0.95, 0.09, 0)],
                  [(0.008, 0.012)] * 5, sides=8, up_hint=(0, 0, 1))
    pitcher = merged("Pitcher", [body, handle])
    w = doctor.WASH
    under = w["top"] - w["board"]
    lz = w["depth"] * 0.5 - w["inset"] - w["leg"] * 0.5
    zf = lz + w["leg"] * 0.5 + 0.001
    knob = lathe("Knob", [(0.012, 0.0), (0.016, 0.006), (0.015, 0.016), (0.008, 0.02), (0.0, 0.022)], 12, axis="z",
                 at=(0, under - w["apron_h"] * 0.5, zf))
    metal.export_baked("washset", [(basin, "china"), (pitcher, "china"), (knob, "brass")], size=1024)


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
    parts = [(merged("Tray", tray_parts, smooth=False), "enamel")]
    # The bone saw: a stiff-backed blade and an ebony handle, laid along the tray.
    parts.append((merged("SawBlade", [box("b", (0.2, 0.0012, 0.04), (0.02, fy + 0.002, -0.06), bevel=0.0004),
                                      box("k", (0.2, 0.004, 0.007), (0.02, fy + 0.004, -0.08), bevel=0.001)], smooth=False), "steel"))
    parts.append((box("SawHandle", (0.095, 0.022, 0.034), (-0.125, fy + 0.012, -0.068), bevel=0.008, smooth=True), "ebony"))
    # The bullet forceps: two long jaws crossing at a joint, ring handles.
    fz = 0.0
    jaws = [moved(box("j", (0.17, 0.004, 0.006), (0, 0, 0), bevel=0.0015), a, (0, 1, 0), (0.0, fy + 0.004, fz)) for a in (3.0, -3.0)]
    rings = [lathe("o", [(0.011, -0.002), (0.013, 0.0), (0.011, 0.002)], 10, at=(-0.1, fy + 0.004, fz + s * 0.012), caps=(False, False)) for s in (-1, 1)]
    parts.append((merged("Forceps", jaws + rings), "nickel"))
    # Nelaton's probe: a long slender rod, its tip a bead of unglazed porcelain (a ball leaves a lead mark on it).
    parts.append((tube("Probe", [(-0.13, fy + 0.0025, 0.05), (0.12, fy + 0.0025, 0.062)], 0.0018, sides=6), "nickel"))
    parts.append((common.blob("ProbeTip", (0.123, fy + 0.0035, 0.0622), (0.0035, 0.0035, 0.0035), rings=4, sides=6), "china"))
    # A scalpel: a bellied blade and an ebony handle.
    parts.append((box("ScalpelBlade", (0.04, 0.001, 0.011), (0.075, fy + 0.002, 0.09), bevel=0.0003), "steel"))
    parts.append((box("ScalpelHandle", (0.085, 0.008, 0.012), (0.012, fy + 0.004, 0.09), bevel=0.003, smooth=True), "ebony"))
    metal.export_baked("instrument_tray", parts, size=512)


# --- The reflector lamp ---------------------------------------------------------------------------

def lamp():
    foot = lathe("Foot", [(0.07, 0.0), (0.072, 0.006), (0.06, 0.016), (0.03, 0.035), (0.018, 0.06), (0.02, 0.075), (0.03, 0.082)], 20)
    font = lathe("Font", [(0.03, 0.082), (0.055, 0.1), (0.064, 0.13), (0.055, 0.16), (0.03, 0.175), (0.024, 0.18)], 20)
    burner = merged("Burner", [lathe("b", [(0.024, 0.18), (0.028, 0.188), (0.028, 0.2), (0.033, 0.205), (0.031, 0.212)], 16),
                               *[tube("g", [(math.cos(a) * 0.03, 0.205, math.sin(a) * 0.03), (math.cos(a) * 0.038, 0.222, math.sin(a) * 0.038)], 0.0025, sides=5)
                                 for a in (0.3, 2.4, 4.5)],
                               box("w", (0.014, 0.01, 0.01), (0.04, 0.196, 0.0), bevel=0.003)])  # the wick's key
    chimney = lathe("Chimney", [(0.03, 0.205), (0.044, 0.23), (0.05, 0.26), (0.046, 0.295), (0.032, 0.335), (0.023, 0.375), (0.022, 0.435)], 20,
                    caps=(False, False))
    # The reflector: a dished tin disc 20 cm across behind the chimney, facing +z, on a wire arm
    # from the burner's collar.
    dish = lathe("d", [(0.0, -0.012), (0.04, -0.008), (0.08, 0.004), (0.1, 0.016), (0.102, 0.018), (0.098, 0.017), (0.078, 0.007), (0.04, -0.004), (0.0, -0.008)],
                 24, axis="z", at=(0, 0.29, -0.085), caps=(False, False))
    arm = tube("a", [(0, 0.2, -0.031), (0, 0.205, -0.07), (0, 0.24, -0.094), (0, 0.27, -0.096)], 0.0025, sides=6)
    reflector = merged("Reflector", [dish, arm])
    metal.export_baked("reflector_lamp", [(foot, "brass"), (font, "brass"), (burner, "brass"), (chimney, "glass"), (reflector, "tin")], size=512)


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
