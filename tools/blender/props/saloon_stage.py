"""Saloon B's stage and dressing room props (#903): the parts of the dressing mirror, the costume pegs,
the travelling trunk, the dressing screen and the footlight that aren't library wood, modelled here in
each kit file's space from tools/props/saloon_stage.py's numbers and baked the gun way (metal.py):
satin, velvet, felt, a plume, painted canvas, oak slats, tin, brass, leather, greasepaint. The
screen's cretonne is printed (Pillow) on a sheet of its own. The coat and the pegs are the doctor's
(doctor_d3.py's `_coat` and peg), the reflector lamp's tin and chimney the footlight's.

    ~/bpyenv/bin/python tools/blender/props/build.py --only=saloon_stage    (~1 min a model)
    ~/bpyenv/bin/python tools/blender/props/saloon_stage.py --only=mirror,trunk

Then `godot --headless --import` and commit the .glb and .png files with their .import files.
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
import doctor  # noqa: E402  (tools/props/doctor.py: the pegs' numbers)
import metal  # noqa: E402
import saloon_stage as ss  # noqa: E402  (tools/props/saloon_stage.py: the numbers)
from common import Part, blob, box, lathe, moved, slab, tube  # noqa: E402
from doctor_d3 import _coat  # noqa: E402

# This batch's finishes (metal.py's recipe: a coat over what's under it, worn at the edges), with
# what each is.
metal.FINISHES.update({
    # Satin gone dull (a variety actress's second-best dress): faded crimson, the sheen still on the
    # folds' crowns, rubbed pale at the edges.
    "satin_red": {"kind": "coat", "color": (0.34, 0.05, 0.06), "under": (0.55, 0.30, 0.26), "rust": 0.0,
                  "rough": 0.45, "metal": 0.0, "wear": 0.45, "mottle": 0.4},
    # Black cotton lace (a flounce), matte.
    "lace_black": {"kind": "coat", "color": (0.03, 0.028, 0.03), "under": (0.18, 0.16, 0.15), "rust": 0.0,
                   "rough": 0.9, "metal": 0.0, "wear": 0.3, "mottle": 0.3},
    # Plum cotton velvet (a showman's coat), the nap worn brown at the cuffs and edges.
    "velvet_plum": {"kind": "coat", "color": (0.13, 0.035, 0.08), "under": (0.28, 0.20, 0.14), "rust": 0.0,
                    "rough": 0.93, "metal": 0.0, "wear": 0.55, "mottle": 0.45},
    # Dyed felt (her hat): a dusty bottle green.
    "felt_green": {"kind": "coat", "color": (0.05, 0.10, 0.06), "under": (0.22, 0.20, 0.15), "rust": 0.0,
                   "rough": 0.95, "metal": 0.0, "wear": 0.35, "mottle": 0.35},
    # An ostrich plume, dyed cream long ago, yellowed.
    "plume": {"kind": "coat", "color": (0.80, 0.72, 0.55), "under": (0.55, 0.46, 0.32), "rust": 0.0,
              "rough": 0.98, "metal": 0.0, "wear": 0.2, "mottle": 0.6},
    # A trunk's canvas cover, painted (dark green-brown) and gone dull, worn through at the edges to the
    # tan canvas.
    "trunk_canvas": {"kind": "coat", "color": (0.10, 0.11, 0.07), "under": (0.42, 0.34, 0.22), "rust": 0.0,
                     "rough": 0.85, "metal": 0.0, "wear": 0.85, "mottle": 0.55},
    # Oak slats, varnished long ago, scuffed.
    "trunk_slat": {"kind": "coat", "color": (0.30, 0.19, 0.10), "under": (0.50, 0.38, 0.24), "rust": 0.0,
                   "rough": 0.7, "metal": 0.0, "wear": 0.75, "mottle": 0.6},
    # A trunk's inside paper (a cheap printed lining), and white muslin, folded.
    "muslin": {"kind": "coat", "color": (0.78, 0.75, 0.66), "under": (0.62, 0.58, 0.48), "rust": 0.0,
               "rough": 0.92, "metal": 0.0, "wear": 0.2, "mottle": 0.4},
    # Spangles (sequins) on a bodice: tarnished brass, catching the light.
    "spangles": {"kind": "plate", "color": (0.55, 0.42, 0.18), "under": (0.30, 0.20, 0.10), "rust": 0.0,
                 "rough": 0.35, "metal": 0.8, "wear": 0.2, "tarnish": 0.5, "mottle": 0.8},
    # Greasepaint: sticks and a tin of flesh colour ("No. 2"), carmine, black.
    "greasepaint": {"kind": "coat", "color": (0.78, 0.58, 0.46), "under": (0.60, 0.42, 0.32), "rust": 0.0,
                    "rough": 0.6, "metal": 0.0, "wear": 0.4, "mottle": 0.5},
    # A hare's foot (for the rouge): soft grey-brown fur.
    "hare_fur": {"kind": "coat", "color": (0.42, 0.36, 0.28), "under": (0.60, 0.55, 0.46), "rust": 0.0,
                 "rough": 1.0, "metal": 0.0, "wear": 0.3, "mottle": 0.7},
    # A candle's tallow.
    "tallow": {"kind": "coat", "color": (0.82, 0.78, 0.64), "under": (0.70, 0.64, 0.50), "rust": 0.0,
               "rough": 0.6, "metal": 0.0, "wear": 0.1, "mottle": 0.3},
    # A frame's old walnut-stained moulding.
    "frame_walnut": {"kind": "coat", "color": (0.15, 0.085, 0.045), "under": (0.32, 0.21, 0.12), "rust": 0.0,
                     "rough": 0.55, "metal": 0.0, "wear": 0.6, "mottle": 0.4},
})


def merged(name, parts, smooth=True):
    out = Part(name, smooth)
    for p in parts:
        out.merge(p)
    return out


def lying(part, at, yaw=0.0, name=None):
    """A part made standing on the origin laid down on a surface at `at`, turned `yaw` about y."""
    return moved(part, yaw, (0, 1, 0), at, name=name)


# --- The dressing mirror --------------------------------------------------------------------------

def mirror():
    m = ss.MIRROR
    y0, y1 = ss.mirror_glass_y()
    gw = m["glass"][0]
    sw, sh, sd = m["standard"]
    sz = m["std_z"]
    lx = m["leg_x"]
    between = (lx - sw * 0.5) * 2
    gz = sz - sd * 0.5 + m["glass"][2] + 0.004
    fz0, fz1 = gz, gz + 0.016  # the moulding over the glass's edge, in front of it
    # The moulding: a rounded bead round the glass, its sides between the standards.
    frame = []
    fw = (between - gw) * 0.5 + 0.015
    frame.append(box("s", (fw, y1 - y0, fz1 - fz0), (-between * 0.5 + fw * 0.5, (y0 + y1) * 0.5, (fz0 + fz1) * 0.5), bevel=0.006))
    frame.append(box("s", (fw, y1 - y0, fz1 - fz0), (between * 0.5 - fw * 0.5, (y0 + y1) * 0.5, (fz0 + fz1) * 0.5), bevel=0.006))
    hy0 = sh - m["head"]
    frame.append(box("t", (between, hy0 - y1 + 0.02, fz1 - fz0), (0, (y1 - 0.02 + hy0) * 0.5, (fz0 + fz1) * 0.5), bevel=0.006))
    # The crest over the head rail: a low scrolled board, cut.
    crest = [(-0.36, 0.0), (0.36, 0.0), (0.36, 0.035), (0.30, 0.05), (0.2, 0.06), (0.1, 0.085), (0.03, 0.11), (0.0, 0.115),
             (-0.03, 0.11), (-0.1, 0.085), (-0.2, 0.06), (-0.30, 0.05), (-0.36, 0.035)]
    frame.append(moved(slab("c", crest, -0.01, 0.01, bevel=0.003), 0, (0, 1, 0), (0, sh, sz)))
    # Turned finials on the standards' tops.
    for s in (-1, 1):
        frame.append(lathe("f", [(0.018, 0.0), (0.022, 0.006), (0.012, 0.02), (0.016, 0.035), (0.021, 0.05), (0.015, 0.065), (0.004, 0.08), (0.0, 0.082)],
                           12, at=(s * lx, sh, sz)))
    # Under the table's top, the standards' braces to it (iron straps, painted with them).
    parts = [(merged("Frame", frame), "frame_walnut")]
    # The shelf's paints: greasepaint sticks in a cigar-box lid, a round tin of flesh paint, a rouge
    # pot, a powder box, a hare's foot.
    shy = m["rail_y"] + m["rail"][0] + m["shelf"][0]
    zc = sz - sd * 0.5 + m["shelf"][1] * 0.5 + 0.01
    paints = []
    tins = []
    for i, x in enumerate((-0.3, -0.17, 0.12, 0.27)):
        r_ = 0.03 if i % 2 == 0 else 0.022
        tins.append(lathe("t", [(r_, 0.0), (r_, 0.018), (r_ - 0.002, 0.02), (0.0, 0.02)], 18, at=(x, shy, zc + (0.01 if i % 2 else -0.005))))
    paints.append((merged("Tins", tins), "tin"))
    sticks = []
    for k in range(6):
        a = math.radians(70 + k * 9)
        sticks.append(tube("k", [(-0.06 + k * 0.016, shy + 0.005, zc + 0.02), (-0.06 + k * 0.016 + 0.01, shy + 0.006, zc - 0.03)], 0.006, sides=6))
    paints.append((merged("Sticks", sticks), "greasepaint"))
    paints.append((lathe("Rouge", [(0.018, 0.0), (0.02, 0.01), (0.019, 0.035), (0.014, 0.038), (0.014, 0.045), (0.0, 0.045)], 14, at=(0.04, shy, zc)), "clay_red"))
    paints.append((lathe("Powder", [(0.045, 0.0), (0.046, 0.03), (0.044, 0.034), (0.03, 0.04), (0.0, 0.042)], 20, at=(0.2, shy, zc - 0.005)), "china"))
    paints.append((blob("HareFoot", (-0.235, shy + 0.012, zc + 0.02), (0.045, 0.012, 0.016), rings=5, sides=8, noise=0.15, seed=3), "hare_fur"))
    # The table's top: a tin candlestick with a stub of candle, a comb, a hand glass face down.
    top_y = m["table"][1]
    stick = lathe("c", [(0.06, 0.0), (0.062, 0.004), (0.058, 0.01), (0.012, 0.014), (0.009, 0.05), (0.016, 0.055), (0.016, 0.058), (0.0, 0.058)], 18,
                  at=(-0.33, top_y, 0.06))
    ring = tube("h", [(-0.33 + 0.06, top_y + 0.008, 0.06), (-0.33 + 0.085, top_y + 0.012, 0.06), (-0.33 + 0.085, top_y + 0.03, 0.06),
                      (-0.33 + 0.065, top_y + 0.032, 0.06)], 0.004, sides=6)
    candle = lathe("Candle", [(0.0105, 0.055), (0.0105, 0.12), (0.006, 0.124), (0.0, 0.125)], 12, at=(-0.33, top_y, 0.06))
    comb = box("Comb", (0.15, 0.006, 0.035), (0.12, top_y + 0.003, 0.11), bevel=0.002)
    glass_back = lathe("g", [(0.07, 0.0), (0.073, 0.006), (0.07, 0.014), (0.0, 0.016)], 24, at=(0.3, top_y, 0.02))
    handle = tube("hd", [(0.3 - 0.07, top_y + 0.008, 0.02), (0.3 - 0.19, top_y + 0.009, 0.05)], (0.014, 0.008), sides=8)
    parts += [(merged("TopThings", [stick, ring]), "tin"), (candle, "tallow"), (merged("HandGlass", [glass_back, handle, comb]), "ebony")]
    parts += paints
    metal.export_baked("dressing_mirror", parts, size=1024)


# --- The costume pegs -------------------------------------------------------------------------------

def _gown(cx, t):
    """A variety actress's dress hung by its loops on the peg at (cx, 0): a fitted bodice with short
    puffed sleeves from the dropped shoulders, the waist drawn in, the skirt flaring in deep folds to
    a black lace flounce, its back to the wall (a bustle's fullness behind, flattened against it)."""
    dw, dh, dd = ss.PEGS["dress"]["size"]
    z_wall = t + 0.014
    rng = random.Random(7)
    # (y, half width, half depth, folds)
    secs = [(0.006, 0.05, 0.025, 0.0), (-0.02, 0.10, 0.04, 0.0), (-0.06, 0.15, 0.055, 0.0), (-0.12, 0.16, 0.065, 0.01),
            (-0.22, 0.14, 0.062, 0.01), (-0.33, 0.115, 0.055, 0.015), (-0.40, 0.12, 0.058, 0.03), (-0.48, 0.17, 0.075, 0.07),
            (-0.62, 0.21, 0.09, 0.11), (-0.80, 0.24, 0.10, 0.15), (-1.0, 0.27, 0.105, 0.18), (-1.18, 0.29, 0.11, 0.2), (-dh + 0.02, 0.30, 0.11, 0.2)]
    n = 60
    ph = [rng.uniform(0, 6.28) for _ in range(3)]
    verts, faces = [], []
    for y, a, b, fold in secs:
        for k in range(n):
            th = 2 * math.pi * k / n
            c, s = math.cos(th), math.sin(th)
            front = max(0.0, s)
            wob = fold * (0.5 * math.sin(9 * th + ph[0]) + 0.3 * math.sin(13 * th + ph[1]) + 0.2 * math.sin(4 * th + ph[2]))
            rr = 1.0 + wob * (0.5 + 0.5 * front)
            x, z = a * c * rr, b * s * rr
            if s < 0:
                z *= 0.45
            hem = 0.025 * fold / 0.2 * math.sin(6 * th + ph[1]) * max(0.0, (-y - 0.7) / 0.6)
            sway = -0.02 * max(0.0, -y / dh) ** 1.5
            verts.append((cx + x + sway, y + hem, z_wall + b * 0.45 + z))
    for i in range(len(secs) - 1):
        for k in range(n):
            a_ = i * n + k
            b_ = i * n + (k + 1) % n
            faces.append([a_, b_, b_ + n, a_ + n])
    verts.append((cx, secs[0][0] + 0.004, z_wall + 0.02))
    c_ = len(verts) - 1
    faces += [[c_, (k + 1) % n, k] for k in range(n)]
    base = (len(secs) - 1) * n
    verts.append((cx, secs[-1][0] + 0.06, z_wall + 0.05))
    c_ = len(verts) - 1
    faces += [[c_, base + k, base + (k + 1) % n] for k in range(n)]
    body = Part("b", smooth=True).add(verts, faces)
    parts = [body]
    zc = z_wall + 0.03
    for sx in (-1, 1):
        # A short puffed sleeve from each shoulder, hanging limp.
        pts = [(cx + sx * 0.13, -0.05, zc), (cx + sx * 0.18, -0.08, zc + 0.01), (cx + sx * 0.2, -0.14, zc + 0.012), (cx + sx * 0.19, -0.19, zc + 0.01)]
        parts.append(tube("s", pts, [(0.03, 0.03), (0.055, 0.05), (0.05, 0.045), (0.035, 0.03)], sides=12, noise=0.12, seed=5 + sx))
    gown = merged("Dress", parts)
    # The black lace flounce round the hem and a band at the waist; a bow at the neck.
    hy = -dh + 0.02
    lace = []
    for yy, rx, rz, w in ((hy + 0.05, 0.31, 0.12, 0.05), (-0.35, 0.125, 0.06, 0.018)):
        pts, rad = [], []
        for k in range(49):
            th = 2 * math.pi * k / 48
            s = math.sin(th)
            pz = rz * s * (0.45 if s < 0 else 1.0)
            pts.append((cx + rx * math.cos(th) * 1.02, yy + 0.008 * math.sin(11 * th), z_wall + rz * 0.45 + pz * 1.03))
            rad.append((w * 0.5, 0.006))
        lace.append(tube("l", pts, rad, sides=6, caps=(False, False), up_hint=(0, 1, 0)))
    lace.append(blob("bow", (cx, -0.03, z_wall + 0.07), (0.04, 0.02, 0.015), rings=4, sides=8))
    return gown, merged("DressLace", lace)


def _plumed_hat(hx, t):
    """Her hat on its peg: a low-crowned green felt with a wide brim turned up at one side, a ribbon
    band, an ostrich plume curling from the band over the brim; hung by its crown, tipped forward."""
    h = ss.PEGS["hat"]
    R, r, ch = h["brim"], h["crown"], h["crown_h"]
    felt = lathe("f", [(r - 0.004, -0.003), (R * 0.7, -0.002), (R - 0.006, 0.004), (R, 0.012), (R - 0.004, 0.016), (R * 0.72, 0.003),
                       (r + 0.003, 0.003), (r, 0.012), (r - 0.002, ch * 0.7), (r * 0.85, ch * 0.95), (0.0, ch)], 32, caps=(False, False))
    fv = []
    for x, y, z in felt.verts:
        rad = math.hypot(x, z)
        if rad > r + 0.01:
            k = (rad - r) / (R - r)
            y += k * k * 0.05 * max(0.0, x / rad)  # turned up at her left
        fv.append((x, y, z))
    felt.verts = fv
    band = lathe("b", [(r + 0.0035, 0.004), (r + 0.003, 0.028), (r + 0.0005, 0.029)], 32, caps=(False, False))
    # The plume: a long feather from the band's right, arching over the crown and curling down past
    # the brim; its vane wide and ragged, thin through.
    L = h["plume"]
    pts, rad = [], []
    for i in range(13):
        u = i / 12
        a = math.pi * 0.95 * u
        pts.append((-0.02 + math.cos(a) * L * 0.42 * (1 - 0.2 * u) * -1 + 0.06, 0.02 + math.sin(a) * L * 0.35, r * 0.9 - u * 0.03))
        rad.append((0.004 + 0.045 * math.sin(math.pi * min(1.0, u * 1.15)) + 0.004, 0.006))
    plume = tube("p", pts, rad, sides=10, noise=0.25, seed=11, up_hint=(0, 0, 1))
    at = (hx, -(r - 0.012), t + 0.03)
    return (moved(felt, 97, (1, 0, 0), at, name="Hat"), moved(band, 97, (1, 0, 0), at, name="HatBand"),
            moved(plume, 97, (1, 0, 0), at, name="Plume"))


def pegs():
    d = doctor.PEGS
    t, r, ln = d["thick"], d["peg_r"], d["peg_len"]
    parts = []
    xs = ss.costume_peg_xs()
    for k, x in enumerate(xs):
        # The doctor's turned peg (doctor_d3.pegs).
        peg = lathe("Peg%d" % k, [(r * 0.86, -0.004), (r * 0.86, 0.004), (r * 0.74, ln * 0.45), (r * 0.80, ln * 0.66), (r * 1.25, ln * 0.82),
                                  (r * 1.42, ln * 0.92), (r * 1.2, ln * 0.985), (0.0, ln)], 14, axis="z", at=(x, 0, t))
        parts.append((peg, "turned_wood"))
    gown, lace = _gown(xs[ss.PEGS["dress"]["peg"]], t)
    parts += [(gown, "satin_red"), (lace, "lace_black")]
    coat, buttons = _coat(xs[ss.PEGS["coat"]["peg"]], t)
    parts += [(coat, "velvet_plum"), (buttons, "brass_old")]
    hat, band, plume = _plumed_hat(xs[ss.PEGS["hat"]["peg"]], t)
    parts += [(hat, "felt_green"), (band, "lace_black"), (plume, "plume")]
    metal.export_baked("costume_pegs", parts, size=1024)


# --- The travelling trunk -----------------------------------------------------------------------------

def trunk():
    c = ss.TRUNK
    L, D, bh, lh, t, bt = c["length"], c["depth"], c["body_h"], c["lid_h"], c["board"], c["bottom"]
    hx, hz = L * 0.5, D * 0.5
    sl_w, sl_t = 0.045, 0.012  # an oak slat's width and thickness, proud of the canvas
    parts = []
    # The box's faces, each a member's: the canvas over its boards (their edges rounded).
    parts.append((box("Bottom", (L, bt, D), (0, bt * 0.5, 0), bevel=0.004), "trunk_canvas"))
    parts.append((box("Front", (L, bh - bt, t), (0, bt + (bh - bt) * 0.5, hz - t * 0.5), bevel=0.004), "trunk_canvas"))
    parts.append((box("Back", (L, bh - bt, t), (0, bt + (bh - bt) * 0.5, -hz + t * 0.5), bevel=0.004), "trunk_canvas"))
    parts.append((box("EndL", (t, bh - bt, D - 2 * t), (-hx + t * 0.5, bt + (bh - bt) * 0.5, 0), bevel=0.003), "trunk_canvas"))
    parts.append((box("EndR", (t, bh - bt, D - 2 * t), (hx - t * 0.5, bt + (bh - bt) * 0.5, 0), bevel=0.003), "trunk_canvas"))
    # The lid: a shallow box, its top and four sides, open below (its inside lined dark).
    lid = merged("Lid", [box("t", (L, 0.014, D), (0, bh + lh - 0.007, 0), bevel=0.004),
                         box("f", (L, lh, 0.012), (0, bh + lh * 0.5, hz - 0.006), bevel=0.003),
                         box("k", (L, lh, 0.012), (0, bh + lh * 0.5, -hz + 0.006), bevel=0.003),
                         box("l", (0.012, lh, D - 0.024), (-hx + 0.006, bh + lh * 0.5, 0), bevel=0.003),
                         box("r", (0.012, lh, D - 0.024), (hx - 0.006, bh + lh * 0.5, 0), bevel=0.003)], smooth=False)
    parts.append((lid, "trunk_canvas"))
    # Two skids under it.
    parts.append((merged("Skids", [box("s", (0.05, 0.016, D - 0.02), (s * (hx - 0.12), 0.008, 0), bevel=0.004) for s in (-1, 1)], smooth=False), "trunk_slat"))
    # The oak slats: two upright on each face (front, back, ends), a band round the body near its top
    # and foot, and three across the lid with one round its edge.
    def slats_front(z, name):
        s_ = 1 if z > 0 else -1
        zz = z + s_ * sl_t * 0.5
        bs = [box("u", (sl_w, bh - bt - 0.03, sl_t), (x, bt + (bh - bt) * 0.5, zz), bevel=0.003) for x in (-hx * 0.45, hx * 0.45)]
        bs += [box("h", (L - 0.06, sl_w * 0.8, sl_t * 0.8), (0, y, zz), bevel=0.003) for y in (0.06, bh - 0.06)]
        return merged(name, bs, smooth=False)
    parts.append((slats_front(hz, "FrontSlats"), "trunk_slat"))
    parts.append((slats_front(-hz, "BackSlats"), "trunk_slat"))

    def slats_end(x, name):
        s_ = 1 if x > 0 else -1
        xx = x + s_ * sl_t * 0.5
        bs = [box("u", (sl_t, bh - bt - 0.03, sl_w), (xx, bt + (bh - bt) * 0.5, z), bevel=0.003) for z in (-hz * 0.45, hz * 0.45)]
        bs += [box("h", (sl_t * 0.8, sl_w * 0.8, D - 0.06), (xx, y, 0), bevel=0.003) for y in (0.06, bh - 0.06)]
        return merged(name, bs, smooth=False)
    parts.append((slats_end(-hx, "EndLSlats"), "trunk_slat"))
    parts.append((slats_end(hx, "EndRSlats"), "trunk_slat"))
    ly = bh + lh
    lid_sl = [box("x", (sl_w, sl_t, D - 0.02), (x, ly + sl_t * 0.5, 0), bevel=0.003) for x in (-hx * 0.62, 0.0, hx * 0.62)]
    lid_sl += [box("e", (L - 0.04, sl_t, sl_w * 0.8), (0, ly + sl_t * 0.5, s * (hz - 0.03)), bevel=0.003) for s in (-1, 1)]
    lid_sl += [box("f", (L - 0.06, sl_w * 0.7, sl_t * 0.8), (0, bh + lh * 0.5, hz + sl_t * 0.4), bevel=0.003)]
    parts.append((merged("LidSlats", lid_sl, smooth=False), "trunk_slat"))

    # Tin corner clamps: an angle over each of the box's eight corners, its arms along three faces.
    def corner(x, y, z, a=0.07, th=0.0025):
        sx, sy, sz = (1 if x > 0 else -1), (1 if y > bh * 0.5 else -1), (1 if z > 0 else -1)
        return [box("c", (a, a, th), (x - sx * a * 0.5, y - sy * a * 0.5, z + sz * th * 0.5), bevel=0.001),
                box("c", (th, a, a), (x + sx * th * 0.5, y - sy * a * 0.5, z - sz * a * 0.5), bevel=0.001),
                box("c", (a, th, a), (x - sx * a * 0.5, y + sy * th * 0.5, z - sz * a * 0.5), bevel=0.001)]
    front_tin, back_tin, l_tin, r_tin, lid_tin = [], [], [], [], []
    for sx in (-1, 1):
        for sz in (-1, 1):
            low = corner(sx * hx, 0.0, sz * hz)
            (front_tin if sz > 0 else back_tin).extend(low[:1])
            (r_tin if sx > 0 else l_tin).extend(low[1:])
            top = corner(sx * hx, bh + lh, sz * hz)
            lid_tin.extend(top)
    parts += [(merged("FrontTin", front_tin, smooth=False), "tin"), (merged("BackTin", back_tin, smooth=False), "tin"),
              (merged("EndLTin", l_tin, smooth=False), "tin"), (merged("EndRTin", r_tin, smooth=False), "tin"),
              (merged("LidTin", lid_tin, smooth=False), "tin")]
    # The brass lock on the front under the lid, the hasp on the lid's front over it.
    parts.append((merged("Lock", [box("p", (0.075, 0.06, 0.006), (0, bh - 0.035, hz + 0.003), bevel=0.002),
                                  box("k", (0.012, 0.018, 0.004), (0, bh - 0.04, hz + 0.007), bevel=0.001)], smooth=False), "brass_old"))
    parts.append((box("Hasp", (0.04, 0.075, 0.005), (0, bh + 0.01, hz + 0.0075), bevel=0.0015), "brass_old"))
    # Leather handles on the ends in their iron loops, hanging slack.
    for sx, name in ((-1, "HandleL"), (1, "HandleR")):
        x = sx * (hx + 0.012)
        pts = [(x, bh - 0.09, -0.09), (x + sx * 0.02, bh - 0.12, -0.05), (x + sx * 0.024, bh - 0.13, 0.0), (x + sx * 0.02, bh - 0.12, 0.05), (x, bh - 0.09, 0.09)]
        strap = tube("h", pts, [(0.004, 0.016)] * 5, sides=6, up_hint=(1, 0, 0))
        loops = [box("l", (0.012, 0.03, 0.02), (x, bh - 0.09, s * 0.09), bevel=0.003) for s in (-1, 1)]
        parts.append((merged(name, [strap] + loops), "leather"))
    # What's in it: costumes folded in (red satin, white muslin, a black spangled bodice), not neat.
    cw, ch, cd = c["costumes"]
    rng = random.Random(1883)
    piles = {"Costumes": [], "CostumesWhite": [], "CostumesDark": []}
    y = bt
    order = ["CostumesWhite", "Costumes", "CostumesDark", "CostumesWhite", "Costumes", "CostumesDark", "Costumes"]
    for i, name in enumerate(order):
        th_ = ch / len(order)
        w = cw * rng.uniform(0.7, 0.98)
        d = cd * rng.uniform(0.7, 0.98)
        x = rng.uniform(-(cw - w) * 0.5, (cw - w) * 0.5)
        z = rng.uniform(-(cd - d) * 0.5, (cd - d) * 0.5)
        piles[name].append(blob("f", (x, y + th_ * 0.5, z), (w * 0.5, th_ * 0.6, d * 0.5), rings=5, sides=14, noise=0.06, seed=i))
        y += th_
    parts.append((merged("Costumes", piles["Costumes"]), "satin_red"))
    parts.append((merged("CostumesWhite", piles["CostumesWhite"]), "muslin"))
    parts.append((merged("CostumesDark", piles["CostumesDark"]), "velvet_plum"))
    sp = [blob("s", (rng.uniform(-0.25, 0.25), bt + ch - 0.01 + rng.uniform(0, 0.01), rng.uniform(-0.12, 0.12)), (0.006, 0.002, 0.006), rings=3, sides=6)
          for _ in range(40)]
    parts.append((merged("Spangles", sp), "spangles"))
    metal.export_baked("travelling_trunk", parts, size=1024)


# --- The dressing screen ------------------------------------------------------------------------------

CLOTH_PX = (512, 1792)  # a leaf's panel on the sheet (0.42 x 1.48 m: ~1200 px a metre)


def screen_cloth():
    """screen_cloth_albedo.png: three leaves' panels side by side, a faded cretonne: a cream ground,
    dull red-brown stripes, sprigs of roses and leaves between, sun-faded toward the top, stained and
    dirtier toward the foot, the tacks' line of rust at its edges."""
    from PIL import Image, ImageDraw, ImageFilter

    W, H = CLOTH_PX[0] * 3, CLOTH_PX[1]
    img = Image.new("RGB", (W, H), (196, 178, 140))
    d = ImageDraw.Draw(img)
    rng = random.Random(1879)
    px_m = CLOTH_PX[0] / ss.SCREEN["leaf"]
    pitch = int(0.11 * px_m)
    for leaf in range(3):
        x0 = leaf * CLOTH_PX[0]
        # The print repeats across all three leaves (one bolt), offset where each was cut.
        off = leaf * 37
        for x in range(x0 - pitch, x0 + CLOTH_PX[0] + pitch, pitch):
            sx = x + off % pitch
            d.rectangle([sx, 0, sx + int(0.012 * px_m), H], fill=(128, 62, 44))
            d.rectangle([sx + int(0.018 * px_m), 0, sx + int(0.022 * px_m), H], fill=(150, 96, 60))
            # Sprigs between the stripes: a rose (three rings), two leaves, every so far down.
            for y in range(int(rng.uniform(0, 0.12) * px_m), H, int(0.13 * px_m)):
                cx = sx + pitch // 2 + int(rng.uniform(-6, 6))
                cy = y + int(rng.uniform(-5, 5))
                for rr, col in ((16, (150, 70, 66)), (11, (176, 92, 82)), (5, (120, 50, 46))):
                    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
                for sgn in (-1, 1):
                    d.ellipse([cx + sgn * 14 - 9, cy + 10, cx + sgn * 14 + 9, cy + 20], fill=(92, 104, 66))
        d.line([x0, 0, x0, H], fill=(70, 56, 40), width=6)
    img = img.filter(ImageFilter.GaussianBlur(1.2))
    a = np.asarray(img).astype(np.float32) / 255.0
    yy = np.linspace(0.0, 1.0, H)[:, None, None]
    # Sun-faded at the top (toward the cream), grimier at the foot.
    cream = np.array([0.80, 0.74, 0.60])
    a = a * (1 - 0.35 * (1 - yy)) + cream * 0.35 * (1 - yy)
    a *= (1.0 - 0.28 * yy ** 3)
    nrng = np.random.default_rng(1879)
    noise = nrng.normal(0, 1, (H // 16 + 1, W // 16 + 1))
    noise = np.kron(noise, np.ones((16, 16)))[:H, :W][:, :, None]
    a *= 0.9 + 0.05 * noise
    # Water stains: a few tide-marked rings.
    for _ in range(6):
        cx, cy, rr = nrng.uniform(0, W), nrng.uniform(H * 0.4, H), nrng.uniform(60, 180)
        Y, X = np.ogrid[:H, :W]
        dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
        a[dist < rr] *= 0.93
        a[(dist > rr - 5) & (dist < rr)] *= 0.85
    out = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
    path = os.path.join(common.MODELS, "screen_cloth_albedo.png")
    out.save(path)
    Image.new("RGB", (64, 64), (255, int(0.9 * 255), 0)).save(os.path.join(common.MODELS, "screen_cloth_orm.png"))
    print("screen cloth ->", os.path.relpath(path, common.ROOT))


def _panel(i, cx, cz, yaw):
    """A leaf's cloth: a thin sheet tacked in its frame, a little slack (it bellies and puckers), its
    two faces mapped on the sheet's i-th column."""
    s = ss.SCREEN
    sw = s["stile"][0]
    inner = s["leaf"] - 2 * sw
    p0, p1 = s["rail_y"] + s["rail"], s["height"] - s["rail"]
    nx, ny = 8, 24
    th = s["panel"] * 0.5
    verts, uvs, faces = [], [], []
    rng = np.random.default_rng(20 + i)
    bump = rng.normal(0, 1, (ny + 1, nx + 1)) * 0.0015
    for side in (1, -1):
        base = len(verts)
        for j in range(ny + 1):
            for k in range(nx + 1):
                u, v = k / nx, j / ny
                lx = -inner * 0.5 + inner * u
                belly = 0.006 * math.sin(math.pi * u) * math.sin(math.pi * v) + bump[j, k] * math.sin(math.pi * u)
                lz = side * th + belly
                x, z = ss.screen_local(cx, cz, yaw, lx, lz)
                verts.append((x, p0 + (p1 - p0) * v, z))
                uvs.append(((i + (u if side > 0 else 1 - u)) / 3.0, v))
        for j in range(ny):
            for k in range(nx):
                a = base + j * (nx + 1) + k
                q = [a, a + 1, a + nx + 2, a + nx + 1]
                faces.append(q if side > 0 else list(reversed(q)))
    part = Part("Panel%d" % i, smooth=True).add(verts, faces)
    part.uvs = uvs
    return part


def screen():
    screen_cloth()
    s = ss.SCREEN
    parts = []
    leaves = ss.screen_leaves()
    for i, (name, cx, cz, yaw) in enumerate(leaves):
        parts.append((_panel(i, cx, cz, yaw), None))
    # Brass hinges: three at each joint, on the middle leaf's stiles' edges.
    for side, sx in (("A", -1), ("B", 1)):
        hx = sx * (s["leaf"] * 0.5 + s["gap"] * 0.5)
        hs = []
        for y in (0.25, s["height"] * 0.5, s["height"] - 0.25):
            hs.append(lathe("k", [(0.004, -0.04), (0.005, -0.038), (0.005, 0.038), (0.004, 0.04)], 8, at=(hx, y, 0.0)))
            hs.append(box("l", (0.03, 0.07, 0.002), (hx - sx * 0.012, y, s["stile"][1] * 0.5 + 0.001), bevel=0.0008))
        parts.append((merged("Hinges" + side, hs), "brass_old"))
    metal.export_baked("dressing_screen", parts, size=512)


# --- The footlight -------------------------------------------------------------------------------------

def footlight():
    f = ss.FOOT
    fr, fh = f["font_r"], f["font_h"]
    pw, pt, pd = f["plate"]
    plate = box("Plate", (pw, pt, pd), (0, pt * 0.5, 0), bevel=0.0012)
    font = lathe("Font", [(fr * 0.9, pt), (fr, pt + 0.006), (fr, fh * 0.75), (fr * 0.8, fh), (0.02, fh + 0.006), (0.019, fh + 0.01)], 24)
    by = f["burner_y"]
    burner = merged("Burner", [lathe("b", [(0.019, fh + 0.01), (0.022, fh + 0.014), (0.022, by), (0.028, by + 0.005), (0.025, by + 0.01)], 16),
                               *[tube("g", [(math.cos(a_) * 0.025, by + 0.006, math.sin(a_) * 0.025), (math.cos(a_) * 0.031, by + 0.02, math.sin(a_) * 0.031)],
                                      0.002, sides=5) for a_ in (0.3, 2.4, 4.5)],
                               box("w", (0.014, 0.008, 0.008), (0.034, by - 0.005, 0.0), bevel=0.0025)])
    c0, c1, cr = f["chimney"]
    chimney = lathe("Chimney", [(cr, by + 0.008), (cr + 0.006, by + 0.02), (cr + 0.008, by + 0.04), (cr + 0.002, by + 0.07), (cr - 0.004, c1)], 20,
                    caps=(False, False))
    # The hood: a curved tin reflector, a half-cylinder's arc standing on the plate's front edge (the
    # house's side, +z), concave toward the flame, its top turned back over it as a lip; braced to
    # the plate.
    h = f["hood"]
    W, Hh, hz, dish = h["width"], h["height"], h["z"], h["dish"]
    nx, ny = 12, 6
    verts, faces = [], []
    for j in range(ny + 1):
        v = j / ny
        for k in range(nx + 1):
            u = k / nx
            x = -W * 0.5 + W * u
            bow = dish * (1 - (2 * u - 1) ** 2)  # bowed toward +z at its middle
            lip = 0.04 * max(0.0, (v - 0.8) / 0.2) ** 2
            verts.append((x, pt + Hh * v, hz + bow - lip))
    for j in range(ny):
        for k in range(nx):
            a = j * (nx + 1) + k
            faces.append([a, a + nx + 1, a + nx + 2, a + 1])
    sheet = Part("s", smooth=True).add(verts, faces)
    back = Part("s2", smooth=True).add([(x, y, z + 0.0012) for x, y, z in verts], [list(reversed(fc)) for fc in faces])
    rim = tube("r", [(x, y + 0.002, z) for x, y, z in verts[ny * (nx + 1):]], 0.0025, sides=5)
    brace = [box("b", (0.006, 0.004, hz - 0.02), (s * W * 0.35, pt + 0.002, hz * 0.5 + 0.01), bevel=0.001) for s in (-1, 1)]
    hood = merged("Hood", [sheet, back, rim] + brace)
    metal.export_baked("footlight", [(plate, "japanned"), (font, "tin"), (burner, "brass"), (chimney, "glass"), (hood, "tin")], size=512)


STEPS = {"mirror": mirror, "pegs": pegs, "trunk": trunk, "screen": screen, "footlight": footlight}


def build():
    for f in STEPS.values():
        f()


if __name__ == "__main__":
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for name, f in STEPS.items():
        if only is None or name in only:
            f()
