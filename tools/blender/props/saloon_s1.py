"""Saloon B's props, batch S1 (#866; docs/briefs/saloon-design.md "The props B needs"): the parts of the
hanging lamps, the bar glasses, the work board, the box stove, the faro table, the piano stool, the
wheel of fortune, the till, the cards and chips and the bar's rails that aren't library wood, modelled
here in each kit file's space from tools/props/saloon.py's numbers and baked the gun way (metal.py):
brass, tin, zinc, cast and sheet iron, glass, plush, clay. The faro layout and the wheel's face are
printed (Pillow) on sheets of their own.

    ~/bpyenv/bin/python tools/blender/props/build.py --only=saloon_s1    (~1 min a model)
    ~/bpyenv/bin/python tools/blender/props/saloon_s1.py --only=lamps,glasses

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
import metal  # noqa: E402
import saloon  # noqa: E402  (tools/props/saloon.py: the numbers)
from common import Part, box, lathe, moved, slab, tube  # noqa: E402


def merged(name, parts, smooth=True):
    out = Part(name, smooth)
    for p in parts:
        out.merge(p)
    return out


def flipped(part, name=None):
    """The part with its faces wound the other way (a shell's inside)."""
    out = Part(name or part.name, part.smooth)
    return out.add(part.verts, [list(reversed(f)) for f in part.faces])


def ring(name, radius, y, tube_r, segs=32, sides=6, at=(0.0, 0.0, 0.0)):
    pts = [(at[0] + math.cos(2 * math.pi * k / segs) * radius, y, at[2] + math.sin(2 * math.pi * k / segs) * radius) for k in range(segs + 1)]
    return tube(name, pts, tube_r, sides=sides, caps=(False, False))


def slab_part(name, x0, x1, y0, y1, z0, z1, bevel=0.0):
    return box(name, (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) * 0.5, (y0 + y1) * 0.5, (z0 + z1) * 0.5), bevel=bevel)


def open_box(name, size, at, t):
    """A box open at the top (a sink, a crate): its bottom and four sides, `t` thick."""
    sx, sy, sz = size
    x, y, z = at
    return merged(name, [box("b", (sx, t, sz), (x, y - sy * 0.5 + t * 0.5, z)),
                         box("f", (sx, sy, t), (x, y, z + sz * 0.5 - t * 0.5)), box("k", (sx, sy, t), (x, y, z - sz * 0.5 + t * 0.5)),
                         box("l", (t, sy, sz - 2 * t), (x - sx * 0.5 + t * 0.5, y, z)), box("r", (t, sy, sz - 2 * t), (x + sx * 0.5 - t * 0.5, y, z))],
                  smooth=False)


# --- The hanging lamps ----------------------------------------------------------------------------

def _chain(name, top, bottom, pitch=0.028, wire=0.0024, width=0.011, x=0.0, z=0.0):
    links = []
    n = max(1, int((top - bottom) / (pitch * 0.82)))
    for k in range(n):
        yc = top - (k + 0.5) * (top - bottom) / n
        pts = []
        for i in range(9):
            a = 2 * math.pi * i / 8
            pts.append((x + math.cos(a) * width * 0.5, yc + math.sin(a) * pitch * 0.5, z))
        link = tube("l", pts, wire, sides=4, caps=(False, False))
        if k % 2:
            link = moved(link, 90.0, (0, 1, 0), (0, 0, 0))
        links.append(link)
    return merged(name, links)


def _lamp(model, shaded):
    h = saloon.HANG
    top = h["drop"]
    plate = lathe("p", [(0.034, top - 0.007), (0.036, top - 0.004), (0.034, top), (0.0, top)], 20)
    eye = moved(ring("e", 0.009, 0.0, 0.0028, segs=14, sides=5), 90.0, (1, 0, 0), (0, top - 0.02, 0))
    hook = merged("Hook", [plate, lathe("s", [(0.004, top - 0.01), (0.004, top - 0.007)], 8), eye])
    bell_y, br = h["bell_y"], h["bell_r"]
    chain = _chain("Chain", top - 0.03, bell_y + 0.068)
    bell = lathe("Bell", [(br, bell_y), (br * 0.98, bell_y + 0.006), (br * 0.88, bell_y + 0.025), (br * 0.62, bell_y + 0.045),
                          (br * 0.3, bell_y + 0.057), (0.012, bell_y + 0.062), (0.012, bell_y + 0.07), (0.006, bell_y + 0.07),
                          (0.006, bell_y + 0.056), (br * 0.28, bell_y + 0.051), (br * 0.58, bell_y + 0.04), (br * 0.84, bell_y + 0.021),
                          (br * 0.95, bell_y + 0.004), (br - 0.004, bell_y), (br, bell_y)], 24, caps=(False, False))
    ry, rr = h["ring_y"], h["ring_r"]
    arms = []
    for k in range(3):
        a = 2 * math.pi * k / 3 + math.pi / 6
        ca, sa = math.cos(a), math.sin(a)
        pts = [(ca * rad, y, sa * rad) for rad, y in ((br * 0.92, bell_y + 0.004), (br * 1.2, bell_y - 0.06), (rr * 1.25, ry + 0.16),
                                                      (rr * 1.18, ry + 0.06), (rr, ry))]
        arms.append(tube("a", pts, 0.0034, sides=6))
    frame_parts = [ring("r", rr, ry, 0.0045, segs=36, sides=6), *arms]
    if shaded:
        s = h["shade"]
        # Three wires from the ring up and out to the shade's lip (its holder).
        for k in range(3):
            a = 2 * math.pi * k / 3 + math.pi / 2
            ca, sa = math.cos(a), math.sin(a)
            frame_parts.append(tube("w", [(ca * rr, ry, sa * rr), (ca * s["r"] * 0.7, s["y0"] + 0.03, sa * s["r"] * 0.7)], 0.0025, sides=5))
    frame = merged("Frame", frame_parts)
    fr, f0, f1 = h["font"]
    font = lathe("Font", [(0.0, f0 - 0.035), (0.007, f0 - 0.033), (0.011, f0 - 0.02), (0.009, f0 - 0.008), (0.03, f0 + 0.004),
                          (0.06, f0 + 0.025), (fr - 0.002, f0 + 0.055), (fr, f0 + 0.07), (fr - 0.004, f0 + 0.085), (0.06, f0 + 0.102),
                          (0.036, f0 + 0.115), (0.03, f1), (0.0, f1)], 28)
    c0, c1, cr = h["chimney"]
    burner = merged("Burner", [lathe("b", [(0.03, f1), (0.034, f1 + 0.005), (0.034, c0 - 0.004), (0.037, c0), (0.031, c0 + 0.006), (0.0, c0 + 0.006)], 20),
                               *[tube("g", [(math.cos(a_) * 0.033, c0 - 0.002, math.sin(a_) * 0.033), (math.cos(a_) * 0.04, c0 + 0.014, math.sin(a_) * 0.04)], 0.0024, sides=5)
                                 for a_ in (0.3, 2.4, 4.5)],
                               lathe("k", [(0.0, -0.004), (0.008, -0.004), (0.008, 0.004), (0.0, 0.004)], 10, axis="z", at=(0.0, f1 + 0.012, 0.045))])
    chimney = lathe("Chimney", [(cr, c0), (cr + 0.004, c0 + 0.012), (cr + 0.014, c0 + 0.04), (cr + 0.018, c0 + 0.067), (cr + 0.013, c0 + 0.092),
                                (cr - 0.002, c0 + 0.122), (cr - 0.008, c0 + 0.152), (cr - 0.009, c1)], 24, caps=(False, False))
    parts = [(hook, "japanned"), (chain, "brass_old"), (bell, "brass_old"), (frame, "brass_old"), (font, "brass_old"), (burner, "brass_old"), (chimney, "glass")]
    if shaded:
        s = h["shade"]
        R, y0, y1, tr = s["r"], s["y0"], s["y1"], s["top_r"] + 0.02
        prof = [(R, y0), (R * 0.97, y0 + 0.022), (R * 0.8, y0 + 0.07), (R * 0.56, y0 + 0.12), (tr * 1.15, y1 - 0.01), (tr, y1)]
        outer = lathe("Shade", prof, 36, caps=(False, False))
        inner = flipped(lathe("i", [(rr_ - 0.002, yy - 0.002) for rr_, yy in prof], 36, caps=(False, False)), "ShadeInner")
        lip = ring("ShadeLip", R - 0.001, y0, 0.0032, segs=48, sides=6)
        parts += [(merged("Shade", [outer, lip]), "shade_green"), (inner, "enamel_dull")]
    metal.export_baked(model, parts, size=1024)


def lamps():
    _lamp("hanging_lamp", False)
    _lamp("hanging_lamp_shaded", True)


# --- The bar glasses ------------------------------------------------------------------------------

def _inner_r(g, y):
    (r0, y0), (r1, y1) = g["inner"]
    return r0 + (r1 - r0) * (y - y0) / (y1 - y0)


def _liquid(name, g, y0, y1, shrink=0.0006):
    if g["inner"]:
        prof = [(0.0, y0), (_inner_r(g, y0 + 0.002) - shrink, y0), (_inner_r(g, y1) - shrink, y1), (0.0, y1)]
    else:
        # A bottle's inside: its outside less its glass, to its level.
        prof_out = [p for p in g["profile"] if p[0] > 0.0]
        pts = [(rr - 0.004, yy) for rr, yy in prof_out if y0 < yy < y1]
        rr_end = np.interp(y1, [p[1] for p in prof_out], [p[0] for p in prof_out]) - 0.004
        prof = [(0.0, y0), (prof_out[0][0] - 0.006, y0)] + pts + [(float(rr_end), y1), (0.0, y1)]
    return lathe(name, prof, 20)


def glasses():
    for kit, g in saloon.GLASSES.items():
        smooth = kit != "decanter"
        sides = 10 if kit == "decanter" else 22
        glass = lathe("Glass", g["profile"], sides, smooth=smooth)
        floor = g.get("floor", 0.008)
        parts = [(glass, None), (_liquid("Liquid", g, floor + 0.0005, g["level"]), g["liquid"])]
        if g.get("foam"):
            foam = lathe("Foam", [(0.0, g["level"]), (_inner_r(g, g["level"]) - 0.0006, g["level"]), (_inner_r(g, g["foam"]) - 0.0004, g["foam"] - 0.004),
                                  (_inner_r(g, g["foam"]) * 0.7, g["foam"]), (0.0, g["foam"] + 0.001)], 20)
            parts.append((foam, "foam"))
        if g.get("stopper"):
            rad, sy0, sy1 = g["stopper"]
            # A mushroom stopper: its plug in the neck, a wide flat cap.
            parts.append((lathe("Stopper", [(0.012, sy0 - 0.012), (0.0135, sy0 + 0.004), (0.008, sy0 + 0.009), (0.014, sy0 + 0.014),
                                            (rad, sy0 + 0.024), (rad * 0.98, sy0 + 0.034), (rad * 0.6, sy1 - 0.004), (0.0, sy1)], 10, smooth=False), None))
        metal.export_baked("bar_glasses_" + kit, parts, size=256)


# --- The work board -------------------------------------------------------------------------------

def _schooner_shell(name, at, upside_down=True):
    g = saloon.GLASSES["schooner"]
    top = 0.17
    prof = [(rr, (top - yy) if upside_down else yy) for rr, yy in g["profile"]]
    if upside_down:
        prof = list(reversed(prof))
    part = lathe(name, prof, 14)
    return moved(part, 0.0, (0, 1, 0), at)


def work_board():
    w = saloon.WORK
    L, D, H, zt = w["length"], w["depth"], w["top"], w["zinc"]
    x0 = w["ice_x"][0]
    hx = -L * 0.5
    sw, sd = w["sink"]
    holes = [(cx - wd * 0.5, cx + wd * 0.5) for cx, wd in w["sinks"]]
    zf, zb = sd * 0.5, -sd * 0.5
    # The zinc: a sheet over the top round the sinks' openings, turned down over its front edge.
    sheet = [slab_part("s", hx, x0, H, H + zt, zf, D * 0.5), slab_part("s", hx, x0, H, H + zt, -D * 0.5, zb)]
    xs = [hx] + [v for hole in holes for v in hole] + [x0]
    for k in range(0, len(xs), 2):
        if xs[k + 1] > xs[k]:
            sheet.append(slab_part("s", xs[k], xs[k + 1], H, H + zt, zb, zf))
    sheet.append(slab_part("lip", hx, x0, H - 0.03, H + zt, D * 0.5, D * 0.5 + zt))
    zinc = merged("Zinc", sheet, smooth=False)
    sinks = merged("Sinks", [open_box("k", (x1 - x0_ + 0.004, sw, sd + 0.004), ((x0_ + x1) * 0.5, H - sw * 0.5 + zt, 0.0), 0.004)
                             for x0_, x1 in holes] +
                   [lathe("d", [(0.0, H - sw + 0.0045), (0.018, H - sw + 0.0045), (0.018, H - sw + 0.0065), (0.0, H - sw + 0.0065)], 12,
                          at=((x0_ + x1) * 0.5, 0, 0.0)) for x0_, x1 in holes], smooth=False)
    d0, d1 = w["drip"]
    ribs = [slab_part("r", d0, d1, H + zt, H + zt + 0.005, z - 0.004, z + 0.004, bevel=0.0015) for z in np.arange(-0.22, 0.23, 0.028)]
    ribs.append(slab_part("e", d0 - 0.01, d0, H + zt, H + zt + 0.012, -0.25, 0.25))
    ribs.append(slab_part("e", d1, d1 + 0.01, H + zt, H + zt + 0.012, -0.25, 0.25))
    drip = merged("Drip", ribs, smooth=False)
    rng = random.Random(866)
    glasses_ = []
    for k in range(6):
        gx = d0 + 0.07 + (k % 3) * 0.15 + rng.uniform(-0.01, 0.01)
        gz = -0.12 + (k // 3) * 0.2 + rng.uniform(-0.015, 0.015)
        glasses_.append(_schooner_shell("g", (gx, H + zt + 0.005, gz)))
    drip_glasses = merged("DripGlasses", glasses_)
    # Two beer pumps (beer engines: the period's way to draw beer up from the cellar or the ice box):
    # a brass body on a flanged base, a swan-neck spout toward the bartender, a tall turned handle.
    tx, tz = w["taps_x"], -0.12
    taps, handles = [], []
    y = H + zt
    for s_ in (-1, 1):
        x = tx + s_ * 0.05
        taps.append(lathe("b", [(0.0, y), (0.032, y), (0.033, y + 0.008), (0.024, y + 0.014), (0.02, y + 0.03), (0.024, y + 0.1),
                                (0.026, y + 0.13), (0.018, y + 0.15), (0.012, y + 0.16), (0.0, y + 0.16)], 14, at=(x, 0, tz)))
        taps.append(tube("s", [(x, y + 0.12, tz), (x, y + 0.14, tz + 0.03), (x, y + 0.12, tz + 0.055), (x, y + 0.085, tz + 0.058)],
                         [(0.008, 0.008), (0.007, 0.007), (0.006, 0.006), (0.0055, 0.0055)], sides=8))
        handles.append(lathe("h", [(0.007, y + 0.16), (0.012, y + 0.18), (0.016, y + 0.26), (0.014, y + 0.32), (0.018, y + 0.37),
                                   (0.012, y + 0.4), (0.0, y + 0.41)], 12, at=(x, 0, tz + 0.01)))
    taps_part = merged("Taps", taps)
    handle_part = merged("TapHandles", handles)
    # The ice box's lid: two strap hinges at its back, a brass lifting ring at its front.
    x1 = w["ice_x"][1]
    lid = merged("IceLid", [slab_part("h", x0 + 0.12, x0 + 0.2, H, H + 0.004, -D * 0.5 + 0.005, -D * 0.5 + 0.12),
                            slab_part("h", x1 - 0.2, x1 - 0.12, H, H + 0.004, -D * 0.5 + 0.005, -D * 0.5 + 0.12),
                            ring("r", 0.02, H + 0.004, 0.003, segs=16, sides=5, at=((x0 + x1) * 0.5, 0, D * 0.5 - 0.06))], smooth=False)
    # The shelf's stock: a packing case of bottles, folded bar towels, a tin bucket.
    sy = w["shelf_y"] + 0.022
    crate = open_box("Stock_c", (0.46, 0.22, 0.32), (hx + 0.32, sy + 0.11, 0.0), 0.015)
    bottles = []
    for i in range(3):
        for j in range(2):
            bx_, bz_ = hx + 0.19 + i * 0.13, -0.075 + j * 0.15
            bottles.append(lathe("b", [(0.0, sy + 0.016), (0.036, sy + 0.016), (0.037, sy + 0.2), (0.03, sy + 0.23), (0.013, sy + 0.255),
                                       (0.012, sy + 0.3), (0.0145, sy + 0.305), (0.0, sy + 0.305)], 12, at=(bx_, 0, bz_)))
    towels = [box("t", (0.3, 0.032, 0.22), (hx + 0.78 + k * 0.006, sy + 0.016 + k * 0.033, 0.02 - k * 0.008), bevel=0.012) for k in range(3)]
    bucket = merged("b", [lathe("u", [(0.0, sy), (0.11, sy), (0.112, sy + 0.004), (0.13, sy + 0.24), (0.134, sy + 0.243), (0.127, sy + 0.243),
                                      (0.107, sy + 0.008), (0.0, sy + 0.008)], 22, at=(x0 - 0.2, 0, 0.0)),
                          tube("h", [(x0 - 0.2 - 0.13, sy + 0.23, 0.0), (x0 - 0.2, sy + 0.37, 0.0), (x0 - 0.2 + 0.13, sy + 0.23, 0.0)], 0.003, sides=5)])
    parts = [(zinc, "zinc"), (sinks, "zinc"), (drip, "zinc"), (taps_part, "brass_old"), (handle_part, "turned_wood"), (lid, "brass_old"),
             (merged("Stock", [crate]), "box_pine"), (merged("StockTowels", towels), "linen"), (merged("StockBucket", [bucket]), "tin"),
             (drip_glasses, None), (merged("StockGlass", bottles), None)]
    metal.export_baked("work_board", parts, size=1024)


# --- The box stove --------------------------------------------------------------------------------

def stove():
    s = saloon.STOVE
    sx, sy, sz = s["sand"]
    rim = s["rim"]
    rng = np.random.default_rng(866)
    sand = box("Sand", (sx - rim * 2 - 0.002, sy, sz - rim * 2 - 0.002), (0, sy * 0.5, 0))
    # A little heaped and trodden: its top's points lifted a few mm by chance.
    sand.verts = [(x, y + (float(rng.uniform(0.0, 0.006)) if y > sy * 0.4 else 0.0), z) for x, y, z in sand.verts]
    bx, by, bz = s["body"]
    lh = s["leg_h"]
    y0 = sy + lh
    legs = []
    for i, (fx, fz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        x, z = fx * (bx * 0.5 - 0.06), fz * (bz * 0.5 - 0.05)
        pts = [(x + fx * 0.012, sy + 0.006, z + fz * 0.01), (x + fx * 0.004, sy + 0.05, z + fz * 0.004), (x - fx * 0.004, sy + 0.12, z - fz * 0.002),
               (x, y0 + 0.005, z)]
        foot = lathe("f", [(0.0, sy), (0.028, sy), (0.03, sy + 0.008), (0.018, sy + 0.016), (0.0, sy + 0.016)], 10, at=(x + fx * 0.012, 0, z + fz * 0.01))
        legs.append(merged("Leg%d" % i, [tube("l", pts, [(0.022, 0.022), (0.016, 0.016), (0.019, 0.019), (0.026, 0.026)], sides=8), foot]))
    # The firebox: a cast box with its edges rounded, a raised panel on each side, end flanges, a
    # moulded band round its foot.
    body = [box("b", (bx, by, bz), (0, y0 + by * 0.5, 0), bevel=0.012)]
    for s_ in (-1, 1):
        body.append(box("p", (bx - 0.16, by - 0.12, 0.012), (0, y0 + by * 0.5, s_ * (bz * 0.5 + 0.004)), bevel=0.004))
        body.append(box("e", (0.025, by + 0.02, bz + 0.03), (s_ * (bx * 0.5 - 0.0125), y0 + by * 0.5, 0), bevel=0.006))
    body.append(box("f", (bx + 0.02, 0.03, bz + 0.02), (0, y0 + 0.015, 0), bevel=0.008))
    body_part = merged("Body", body, smooth=False)
    dx, dy, dz = s["door"]
    door = merged("Door", [box("d", (dx, dy, dz), (bx * 0.5 + dx * 0.5, y0 + by * 0.5, 0), bevel=0.008),
                           box("r", (0.01, dy - 0.06, dz - 0.06), (bx * 0.5 + dx + 0.004, y0 + by * 0.5, 0), bevel=0.003),
                           lathe("v", [(0.0, -0.006), (0.04, -0.006), (0.04, 0.006), (0.0, 0.006)], 16, axis="x", at=(bx * 0.5 + dx + 0.012, y0 + by * 0.35, 0)),
                           tube("h", [(bx * 0.5 + dx, y0 + by * 0.62, dz * 0.32), (bx * 0.5 + dx + 0.035, y0 + by * 0.62, dz * 0.32),
                                      (bx * 0.5 + dx + 0.035, y0 + by * 0.62, dz * 0.42)], 0.006, sides=6)] +
                   [lathe("k", [(0.012, -0.03), (0.012, 0.03)], 10, at=(bx * 0.5 + dx * 0.5, y0 + by * 0.5 + o, -dz * 0.5 - 0.006)) for o in (-0.1, 0.1)],
                   smooth=False)
    pt = s["plate"]
    py = y0 + by
    pr = s["pipe_r"]
    top = [box("t", (bx + 0.04, pt, bz + 0.04), (0, py + pt * 0.5, 0), bevel=0.008),
           lathe("c", [(pr + 0.012, py + pt), (pr + 0.012, py + pt + 0.04), (pr + 0.006, py + pt + 0.05), (pr + 0.004, py + pt + 0.05)], 24,
                 at=(s["pipe_x"], 0, 0), caps=(False, False)),
           lathe("l", [(0.0, py + pt), (0.11, py + pt), (0.11, py + pt + 0.012), (0.0, py + pt + 0.012)], 24, at=(0.17, 0, 0)),
           box("n", (0.05, 0.012, 0.014), (0.17, py + pt + 0.018, 0), bevel=0.003)]
    top_part = merged("Top", top, smooth=False)
    pipes = []
    y = py + pt
    for k, ln in enumerate(s["pipe"]):
        prof = [(pr, y), (pr, y + ln - 0.05), (pr - 0.004, y + ln - 0.04), (pr - 0.004, y + ln), (0.0, y + ln)]
        if k == 0:
            prof = [(0.0, y)] + prof
        parts_ = [lathe("p", prof, 18, at=(s["pipe_x"], 0, 0), caps=(False, False))]
        if k == 0:
            # The damper's handle through the first length.
            parts_.append(tube("d", [(s["pipe_x"], y + 0.3, -pr - 0.06), (s["pipe_x"], y + 0.3, pr + 0.01)], 0.004, sides=5))
            parts_.append(box("w", (0.016, 0.03, 0.05), (s["pipe_x"], y + 0.3, -pr - 0.07), bevel=0.004))
        pipes.append(merged("Pipe%d" % k, parts_))
        y += ln
    parts = [(sand, "sand"), *[(lg, "cast_iron") for lg in legs], (body_part, "cast_iron"), (door, "cast_iron"), (top_part, "cast_iron"),
             *[(p, "sheet_iron") for p in pipes]]
    metal.export_baked("box_stove", parts, size=1024)


# --- The faro table and its printed layout --------------------------------------------------------
SHEET = 2048
FARO_SHEET_H = 1366  # the cloth's top in the sheet's upper part (its 1.37 x 0.91 m at 1500 px/m)
CARD = (0.064, 0.089)
RANKS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]


def faro_card_places():
    """Each spade's (rank, x, z of its middle on the table): ace to six along the dealer's row (-z,
    from his left), king to eight along the far row (the king over the ace), the seven at the end."""
    gap = 0.012
    pitch = CARD[0] + gap
    x0 = -2.5 * pitch - 0.08
    out = []
    for i in range(6):
        out.append((RANKS[i], x0 + i * pitch, -0.03))
        out.append((RANKS[12 - i], x0 + i * pitch, 0.085))
    out.append(("7", x0 + 6 * pitch + 0.02, 0.0275))
    return out


def _uv(x, z):
    f = saloon.FARO
    L, W = f["length"], f["width"]
    u = (x + L * 0.5) / L
    v = 1.0 - ((z + W * 0.5) / W) * (FARO_SHEET_H / SHEET)  # z toward the players: down the sheet
    return (u, v)


def faro_layout():
    """faro_layout_albedo.png: green baize with the suit of spades enamelled on it and the high-card bar."""
    from PIL import Image, ImageDraw, ImageFilter

    f = saloon.FARO
    L, W = f["length"], f["width"]
    rng = random.Random(866)
    img = Image.new("RGB", (SHEET, SHEET), (34, 70, 40))
    px = img.load()
    noise = np.random.default_rng(866).normal(0, 1, (SHEET // 4, SHEET // 4))
    for y in range(SHEET):
        for x in range(0, SHEET):
            n = noise[y // 4, x // 4]
            # Worn and soiled toward the dealer's place and the players' edge; a felt's nap.
            k = 1.0 + 0.05 * n
            px[x, y] = (int(34 * k), int(70 * k), int(40 * k))
    d = ImageDraw.Draw(img)
    ppm = SHEET / L

    def tp(x, z):
        u, v = _uv(x, z)
        return (u * SHEET, (1.0 - v) * SHEET)

    # The high-card bar: a white enamelled strip along the players' edge.
    a, b = tp(-0.42, 0.25), tp(0.42, 0.272)
    d.rectangle([a, b], fill=(214, 206, 182))
    for rank, x, z in faro_card_places():
        a = tp(x - CARD[0] * 0.5, z - CARD[1] * 0.5)
        b = tp(x + CARD[0] * 0.5, z + CARD[1] * 0.5)
        d.rectangle([a, b], fill=(222, 214, 190), outline=(60, 50, 40), width=2)
        cw, ch = b[0] - a[0], b[1] - a[1]
        if rank in ("J", "Q", "K"):
            # A court card: its figure in a frame (red, blue, yellow), the rank in the corner.
            d.rectangle([a[0] + cw * 0.14, a[1] + ch * 0.12, b[0] - cw * 0.14, b[1] - ch * 0.12], fill=(168, 44, 36), outline=(30, 40, 90), width=3)
            d.rectangle([a[0] + cw * 0.3, a[1] + ch * 0.22, b[0] - cw * 0.3, a[1] + ch * 0.48], fill=(214, 170, 70))
            d.rectangle([a[0] + cw * 0.3, b[1] - ch * 0.48, b[0] - cw * 0.3, b[1] - ch * 0.22], fill=(40, 52, 120))
        pips = {"A": 1, "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10}.get(rank, 1)
        rows = [(0.5, 0.5)] if pips == 1 else []
        if pips > 1:
            cols = [0.3, 0.7] if pips >= 4 else [0.5]
            per = math.ceil(pips / len(cols))
            for c in cols:
                for k in range(per):
                    if len(rows) < pips:
                        rows.append((c, 0.2 + 0.6 * (k / max(1, per - 1) if per > 1 else 0.5)))
        size = cw * (0.26 if pips == 1 else 0.13)
        if rank not in ("J", "Q", "K"):
            for c, rr in rows:
                cx, cy = a[0] + cw * c, a[1] + ch * rr
                d.polygon([(cx, cy - size), (cx + size * 0.9, cy + size * 0.2), (cx + size * 0.4, cy + size * 0.6), (cx, cy + size * 0.35),
                           (cx - size * 0.4, cy + size * 0.6), (cx - size * 0.9, cy + size * 0.2)], fill=(20, 18, 16))
                d.polygon([(cx, cy + size * 0.2), (cx + size * 0.25, cy + size), (cx - size * 0.25, cy + size)], fill=(20, 18, 16))
        # Wear: the enamel rubbed where the bets are laid (a few pale scratches).
        for k in range(6):
            sx_, sy_ = a[0] + rng.uniform(0, cw), a[1] + rng.uniform(0, ch)
            d.line([(sx_, sy_), (sx_ + rng.uniform(-8, 8), sy_ + rng.uniform(-8, 8))], fill=(180, 170, 150), width=1)
    # The cloth's edges (its sides, turned down): the sheet's bottom strip.
    d.rectangle([0, FARO_SHEET_H + 8, SHEET, SHEET], fill=(30, 60, 34))
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    out = os.path.join(common.MODELS, "faro_layout_albedo.png")
    img.save(out)
    Image.new("RGB", (64, 64), (255, int(0.92 * 255), 0)).save(os.path.join(common.MODELS, "faro_layout_orm.png"))
    print("faro layout ->", os.path.relpath(out, common.ROOT))
    del ppm


def _cloth():
    """The baize on the top (round the dealer's cut), 3 mm thick, its top on the printed sheet."""
    f = saloon.FARO
    L, W, H = f["length"], f["width"], f["top"]
    cw, cd = f["cut"]
    y0, y1 = H, H + 0.003
    # The top's outline as rectangles (x0, x1, z0, z1): the dealer's cut out of its -z edge.
    rects = [(-L * 0.5, -cw * 0.5, -W * 0.5, W * 0.5), (cw * 0.5, L * 0.5, -W * 0.5, W * 0.5), (-cw * 0.5, cw * 0.5, -W * 0.5 + cd, W * 0.5)]
    verts, uvs, faces = [], [], []

    def quad(ps, uv):
        base = len(verts)
        verts.extend(ps)
        uvs.extend(uv)
        faces.append([base, base + 1, base + 2, base + 3])

    edge_uv = [(0.5, 0.05), (0.52, 0.05), (0.52, 0.06), (0.5, 0.06)]
    for x0, x1, z0, z1 in rects:
        ps = [(x0, y1, z0), (x0, y1, z1), (x1, y1, z1), (x1, y1, z0)]
        quad(ps, [_uv(x, z) for x, _, z in ps])
    # The sides along the outline (outer edges only).
    edges = [((-L * 0.5, -W * 0.5), (-L * 0.5, W * 0.5)), ((-L * 0.5, W * 0.5), (L * 0.5, W * 0.5)), ((L * 0.5, W * 0.5), (L * 0.5, -W * 0.5)),
             ((L * 0.5, -W * 0.5), (cw * 0.5, -W * 0.5)), ((cw * 0.5, -W * 0.5), (cw * 0.5, -W * 0.5 + cd)),
             ((cw * 0.5, -W * 0.5 + cd), (-cw * 0.5, -W * 0.5 + cd)), ((-cw * 0.5, -W * 0.5 + cd), (-cw * 0.5, -W * 0.5)),
             ((-cw * 0.5, -W * 0.5), (-L * 0.5, -W * 0.5))]
    for (ax, az), (bx_, bz) in edges:
        quad([(ax, y0, az), (ax, y1, az), (bx_, y1, bz), (bx_, y0, bz)], edge_uv)
    part = Part("Cloth", smooth=False).add(verts, faces)
    part.uvs = uvs
    return part


def faro():
    faro_layout()
    f = saloon.FARO
    L, W, H = f["length"], f["width"], f["top"]
    cw, cd = f["cut"]
    y = H + 0.003
    # The padded rim: a leather roll round the top's outer edge, broken at the dealer's cut.
    rr = 0.016
    yr = y + rr * 0.6
    path = [(-cw * 0.5 - 0.01, yr, -W * 0.5 + rr), (-L * 0.5 + rr, yr, -W * 0.5 + rr), (-L * 0.5 + rr, yr, W * 0.5 - rr), (L * 0.5 - rr, yr, W * 0.5 - rr),
            (L * 0.5 - rr, yr, -W * 0.5 + rr), (cw * 0.5 + 0.01, yr, -W * 0.5 + rr)]
    rim = tube("Rim", path, rr, sides=8)
    # The dealing box (German silver, open at the top, a slot at its side) at the dealer's place.
    bz = -W * 0.5 + cd + 0.1
    dbox = merged("DealingBox", [open_box("b", (0.078, 0.032, 0.104), (0.0, y + 0.016, bz), 0.004),
                                 box("s", (0.06, 0.002, 0.08), (0.0, y + 0.024, bz), bevel=0.0)], smooth=False)
    # The case-keeper: a walnut frame of thirteen wires, its beads (ivory) pushed along as cards fall.
    kx, kz = 0.32, -W * 0.5 + 0.17
    frame = [box("f", (0.2, 0.025, 0.012), (kx, y + 0.0125, kz - 0.06)), box("f", (0.2, 0.025, 0.012), (kx, y + 0.0125, kz + 0.06)),
             box("f", (0.012, 0.025, 0.132), (kx - 0.1, y + 0.0125, kz)), box("f", (0.012, 0.025, 0.132), (kx + 0.1, y + 0.0125, kz))]
    beads = []
    rng = random.Random(13)
    for k in range(13):
        x = kx - 0.09 + k * 0.015
        frame.append(tube("w", [(x, y + 0.018, kz - 0.055), (x, y + 0.018, kz + 0.055)], 0.0012, sides=4))
        n_left = rng.randint(0, 4)
        for b in range(4):
            bzp = kz - 0.045 + b * 0.012 if b < n_left else kz + 0.045 - (3 - b) * 0.012
            beads.append(lathe("b", [(0.0, -0.005), (0.0055, -0.0035), (0.0055, 0.0035), (0.0, 0.005)], 8, axis="z", at=(x, y + 0.018, bzp)))
    keeper = merged("CaseKeeper", frame, smooth=False)
    bead_part = merged("CaseBeads", beads)
    # A few stacks of chips on the cards (white and red).
    places = faro_card_places()
    cw_, cr_ = [], []
    rng = random.Random(866)
    for i, (rank, x, z) in enumerate(places):
        if rank not in ("5", "K", "2", "9", "7"):
            continue
        n = rng.randint(2, 6)
        stack = [lathe("c", [(0.0, y + k * 0.0034), (0.0195, y + k * 0.0034), (0.0195, y + (k + 1) * 0.0034 - 0.0004), (0.0, y + (k + 1) * 0.0034 - 0.0004)], 10,
                       at=(x + rng.uniform(-0.01, 0.01), 0, z + rng.uniform(-0.015, 0.015))) for k in range(n)]
        (cw_ if i % 2 else cr_).extend(stack)
    parts = [(rim, "leather"), (dbox, "nickel"), (keeper, "turned_wood"), (bead_part, "ivory"), (merged("ChipsW", cw_), "clay_white"),
             (merged("ChipsR", cr_), "clay_red"), (_cloth(), None)]
    metal.export_baked("faro_table", parts, size=1024)


# --- The piano stool ------------------------------------------------------------------------------

def piano_stool():
    c = saloon.PIANO_STOOL
    sy, R, st = c["seat_y"], c["seat_r"], c["seat_t"]
    seat = lathe("Seat", [(0.0, sy - 0.012), (R - 0.012, sy - 0.012), (R - 0.004, sy - 0.006), (R - 0.006, sy + 0.004), (R * 0.75, sy + 0.012),
                          (0.0, sy + 0.016)], 32)
    rim = lathe("SeatRim", [(0.03, sy - st), (R - 0.004, sy - st), (R, sy - st + 0.008), (R, sy - 0.014), (R - 0.006, sy - 0.01), (0.0, sy - 0.01)], 32)
    lt = c["legs_top"]
    cw, ch = c["column"]
    column = lathe("Column", [(0.05, lt - 0.03), (0.055, lt - 0.01), (0.045, lt + 0.01), (0.03, lt + 0.04), (0.022, lt + 0.08), (0.03, lt + 0.12),
                              (0.03, lt + 0.14), (0.018, lt + 0.16), (0.012, lt + 0.17), (0.012, sy - st), (0.0, sy - st)], 20)
    legs, claws, balls = [], [], []
    ft = c["foot"]
    for i in range(4):
        a = math.radians(45 + 90 * i)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(ca * rad, y, sa * rad) for rad, y in ((0.035, lt), (0.09, lt - 0.05), (0.16, lt - 0.13), (ft - 0.012, 0.06), (ft, 0.045))]
        legs.append(tube("Leg%d" % i, pts, [(0.022, 0.022), (0.018, 0.018), (0.015, 0.015), (0.013, 0.013), (0.012, 0.012)], sides=8))
        bx_, bz_ = ca * ft, sa * ft
        balls.append(lathe("b", [(0.0, 0.0), (0.016, 0.004), (0.022, 0.015), (0.022, 0.026), (0.016, 0.037), (0.0, 0.041)], 12, at=(bx_, 0, bz_)))
        for k in range(3):
            t = a + (k - 1) * 1.2
            claws.append(tube("c", [(bx_, 0.05, bz_), (bx_ + math.cos(t) * 0.02, 0.035, bz_ + math.sin(t) * 0.02),
                                    (bx_ + math.cos(t) * 0.024, 0.018, bz_ + math.sin(t) * 0.024)], [(0.006, 0.006), (0.005, 0.005), (0.003, 0.003)], sides=5))
    parts = [(seat, "plush"), (rim, "ebony"), (column, "ebony"), *[(lg, "ebony") for lg in legs], (merged("Claws", claws), "brass_old"),
             (merged("Balls", balls), None)]
    metal.export_baked("piano_stool", parts, size=1024)


# --- The wheel of fortune -------------------------------------------------------------------------

def annulus(name, r0, r1, z0, z1, segs=64, smooth=False):
    """A flat ring about the z axis (a wheel's rim or band) from radius r0 to r1, z0 to z1, closed."""
    verts, faces = [], []
    for k in range(segs):
        a = 2 * math.pi * k / segs
        c, s_ = math.cos(a), math.sin(a)
        verts += [(c * r0, s_ * r0, z0), (c * r1, s_ * r1, z0), (c * r1, s_ * r1, z1), (c * r0, s_ * r0, z1)]
    for k in range(segs):
        a, b = 4 * k, 4 * ((k + 1) % segs)
        for i in range(4):
            j = (i + 1) % 4
            faces.append([a + i, b + i, b + j, a + j])
    return Part(name, smooth).add(verts, faces)


def star(name, r_out, r_in, z0, z1, points=8, turn=0.0, at=(0.0, 0.0)):
    pts = []
    for k in range(points * 2):
        a = math.pi * k / points + turn
        rr = r_out if k % 2 == 0 else r_in
        pts.append((at[0] + math.cos(a) * rr, at[1] + math.sin(a) * rr))
    return slab(name, pts, z0, z1, bevel=min(0.004, (z1 - z0) * 0.4))


def wheel_face():
    """wheel_face_albedo.png: the band of the Evans-style dice wheel: 30 panels, faded blue, three dice
    each, between gilt lines; worn and smoked. The sheet's radius 0.98 of its half is the band's outside."""
    from PIL import Image, ImageDraw, ImageFilter

    w = saloon.WHEEL
    S = 1024
    c = S * 0.5
    r1 = c * 0.98
    r0 = r1 * w["band"][0] / w["band"][1]
    img = Image.new("RGB", (S, S), (40, 30, 26))
    d = ImageDraw.Draw(img)
    n = w["segments"]
    gilt = (196, 156, 72)
    d.ellipse([c - r1, c - r1, c + r1, c + r1], fill=(72, 112, 178))
    d.ellipse([c - r0, c - r0, c + r0, c + r0], fill=(40, 30, 26))
    rng = random.Random(1882)
    for k in range(n):
        a = 2 * math.pi * k / n
        d.line([(c + math.cos(a) * r0, c + math.sin(a) * r0), (c + math.cos(a) * r1, c + math.sin(a) * r1)], fill=gilt, width=5)
        am = 2 * math.pi * (k + 0.5) / n
        rows = 3
        for j in range(rows):
            rad = r0 + (r1 - r0) * (j + 0.5) / rows
            side = (r1 - r0) / rows * 0.74
            die = Image.new("RGBA", (int(side) + 4, int(side) + 4), (0, 0, 0, 0))
            dd = ImageDraw.Draw(die)
            dd.rounded_rectangle([2, 2, side + 1, side + 1], radius=side * 0.16, fill=(226, 218, 196), outline=(30, 26, 24), width=2)
            v = rng.randint(1, 6)
            q = side / 4.0
            spots = {1: [(2, 2)], 2: [(1, 1), (3, 3)], 3: [(1, 1), (2, 2), (3, 3)], 4: [(1, 1), (3, 1), (1, 3), (3, 3)],
                     5: [(1, 1), (3, 1), (2, 2), (1, 3), (3, 3)], 6: [(1, 1), (3, 1), (1, 2), (3, 2), (1, 3), (3, 3)]}[v]
            for sx, sy in spots:
                px, py = 2 + sx * q, 2 + sy * q
                dd.ellipse([px - q * 0.32, py - q * 0.32, px + q * 0.32, py + q * 0.32], fill=(26, 22, 20) if v != 1 else (150, 30, 24))
            die = die.rotate(-math.degrees(am), expand=True, resample=Image.BICUBIC)
            x, y = c + math.cos(am) * rad, c + math.sin(am) * rad
            img.paste(die, (int(x - die.width * 0.5), int(y - die.height * 0.5)), die)
    for rr, wd in ((r1 - 3, 7), (r0 + 3, 7), (r1 - 14, 2), (r0 + 14, 2)):
        d.ellipse([c - rr, c - rr, c + rr, c + rr], outline=gilt, width=wd)
    # Age: smoke and hands, darker toward the rim's bottom where the flapper's hand reaches.
    rng2 = np.random.default_rng(1882)
    noise = rng2.normal(0, 1, (S // 16, S // 16))
    big = np.kron(noise, np.ones((16, 16)))
    arr = np.asarray(img).astype(np.float32)
    k = (0.88 + 0.06 * big)[..., None] * np.array([1.0, 0.97, 0.9])
    arr = np.clip(arr * k, 0, 255).astype(np.uint8)
    img = Image.fromarray(arr).filter(ImageFilter.GaussianBlur(0.6))
    out = os.path.join(common.MODELS, "wheel_face_albedo.png")
    img.save(out)
    Image.new("RGB", (64, 64), (255, int(0.62 * 255), 0)).save(os.path.join(common.MODELS, "wheel_face_orm.png"))
    print("wheel face ->", os.path.relpath(out, common.ROOT))


def wheel():
    wheel_face()
    w = saloon.WHEEL
    bx, by, bt = w["board"]
    R, th = w["radius"], w["thick"]
    b0, b1 = w["band"]
    cy = w["axle_y"]
    z0 = bt + w["stand_off"]
    z1 = z0 + th
    zm = (z0 + z1) * 0.5
    seg = 96
    # The band: its front at z1 - 4 mm (inside the rim's lips), printed; its back the same, unprinted.
    zf = z1 - 0.004
    verts, uvs, faces = [], [], []
    for k in range(seg):
        a = 2 * math.pi * k / seg
        for rr in (b0, b1):
            verts.append((math.cos(a) * rr, cy + math.sin(a) * rr, zf))
            uvs.append((0.5 + math.cos(a) * 0.49 * rr / b1, 0.5 + math.sin(a) * 0.49 * rr / b1))
    for k in range(seg):
        a, b = 2 * k, 2 * ((k + 1) % seg)
        faces.append([a, b, b + 1, a + 1])
    nf = len(verts)
    for k in range(seg):
        a = 2 * math.pi * k / seg
        for rr in (b0, b1):
            verts.append((math.cos(a) * rr, cy + math.sin(a) * rr, z0 + 0.006))
            uvs.append((0.5 + math.cos(a) * 0.49 * 0.5 * (b0 + b1) / b1, 0.5 + math.sin(a) * 0.49 * 0.5 * (b0 + b1) / b1))
    for k in range(seg):
        a, b = nf + 2 * k, nf + 2 * ((k + 1) % seg)
        faces.append([a + 1, b + 1, b, a])
    face = Part("Face", smooth=False).add(verts, faces)
    face.uvs = uvs
    # The rim (its lips stand proud of the band), the band's inner ring, a brass bead round the rim's
    # face, and a brass peg out of the rim's edge between each panel.
    rim = [annulus("o", b1 - 0.004, R, z0, z1 + 0.006, segs=seg), annulus("i", b0 - 0.022, b0 + 0.004, z0, z1 + 0.004, segs=seg)]
    rim = [moved(p, 0.0, (0, 0, 1), (0, cy, 0)) for p in rim]
    n = w["segments"]
    pegs = []
    for k in range(n):
        a = 2 * math.pi * k / n
        peg = lathe("p", [(0.0, R - 0.01), (0.0045, R - 0.01), (0.0042, R + w["peg"] - 0.008), (0.0065, R + w["peg"] - 0.005),
                          (0.004, R + w["peg"]), (0.0, R + w["peg"] + 0.001)], 8)
        pegs.append(moved(peg, math.degrees(a) - 90.0, (0, 0, 1), (0, cy, zm)))
    bead = [moved(ring("b", R - 0.006, 0.0, 0.0045, segs=seg, sides=6), 90.0, (1, 0, 0), (0, cy, z1 + 0.006))]
    # The spokes, from the hub to the band's inner ring, in the wheel's middle plane.
    spokes = []
    for k in range(w["spokes"]):
        a = 2 * math.pi * (k + 0.5) / w["spokes"]
        pts = [(math.cos(a) * rr, cy + math.sin(a) * rr, zm) for rr in (0.05, 0.2, b0 - 0.01)]
        spokes.append(tube("s", pts, [(0.013, 0.013), (0.011, 0.011), (0.009, 0.009)], sides=6))
    spokes.append(star("r", w["star"] * 1.06, w["star"] * 0.4, zm - 0.004, zm + 0.008, turn=math.pi / 8, at=(0, cy)))
    # The hub: a gilt eight-pointed star over the spokes, a boss and the axle's nut.
    hub = [star("g", w["star"], w["star"] * 0.36, zm + 0.008, zm + 0.02, at=(0, cy)),
           star("g2", w["star"] * 0.55, w["star"] * 0.25, zm + 0.02, zm + 0.028, turn=math.pi / 8, at=(0, cy)),
           lathe("h", [(0.0, zm), (0.055, zm), (0.055, zm + 0.03), (0.04, zm + 0.04), (0.025, zm + 0.05), (0.012, zm + 0.065), (0.0, zm + 0.068)],
                 20, axis="z", at=(0, cy, 0.0))]
    # The flapper: an oak block on the plank's top over the wheel, a leather flap hanging into the pegs.
    cyp = w["clapper_y"]
    block = merged("Clapper", [box("b", (0.1, 0.1, zm + 0.02 - bt), (0, cyp + 0.03, (bt + zm + 0.02) * 0.5), bevel=0.008),
                               box("p", (0.05, 0.03, 0.03), (0, cyp - 0.03, zm), bevel=0.004)], smooth=False)
    flap = merged("Flap", [box("f", (0.042, cyp - 0.04 - (R + 0.012), 0.006), (0, (cyp - 0.04 + R + 0.012) * 0.5, zm), bevel=0.002)], smooth=False)
    parts = [(merged("Rim", rim + pegs + bead), "brass_old"), (merged("Spokes", spokes), "turned_wood"), (merged("Hub", hub), "brass_old"),
             (block, "turned_wood"), (flap, "leather"), (face, None)]
    metal.export_baked("wheel_of_fortune", parts, size=1024)


# --- The till, the cards and chips, the bar's rails -----------------------------------------------

def till():
    sx, sy, sz = saloon.TILL["size"]
    dw, dh = saloon.TILL["drawer"]
    zf = sz * 0.5 + 0.016
    pull = merged("Pull", [box("p", (0.08, 0.012, 0.004), (0, 0.012 + dh * 0.5, zf + 0.002), bevel=0.0015),
                           tube("h", [(-0.03, 0.012 + dh * 0.5 - 0.004, zf + 0.004), (-0.03, 0.012 + dh * 0.5 - 0.012, zf + 0.018),
                                      (0.03, 0.012 + dh * 0.5 - 0.012, zf + 0.018), (0.03, 0.012 + dh * 0.5 - 0.004, zf + 0.004)], 0.0035, sides=6)], smooth=False)
    bell = lathe("Bell", [(0.0, sy), (0.03, sy), (0.032, sy + 0.004), (0.026, sy + 0.022), (0.012, sy + 0.032), (0.004, sy + 0.036),
                          (0.004, sy + 0.044), (0.0, sy + 0.046)], 18, at=(sx * 0.5 - 0.05, 0, -sz * 0.5 + 0.05))
    metal.export_baked("till_drawer", [(pull, "brass_old"), (bell, "brass_old")], size=256)


def cards_chips():
    deck = box("Deck", (0.064, 0.0155, 0.089), (0, 0.00775, 0), bevel=0.0012)
    back = box("DeckBack", (0.0625, 0.0006, 0.0875), (0, 0.0158, 0))
    stacks = []
    for name, x, z, n, finish in (("ChipsW", -0.042, -0.01, 11, "clay_white"), ("ChipsR", 0.0, 0.012, 9, "clay_red"), ("ChipsB", 0.042, -0.006, 6, "clay_blue")):
        rng = random.Random(name)
        chips = [lathe("c", [(0.0, k * 0.0034), (0.0195, k * 0.0034), (0.0195, (k + 1) * 0.0034 - 0.0004), (0.0, (k + 1) * 0.0034 - 0.0004)], 10,
                       at=(x + rng.uniform(-0.0012, 0.0012), 0, z + rng.uniform(-0.0012, 0.0012))) for k in range(n)]
        stacks.append((merged(name, chips), finish))
    metal.export_baked("cards_chips", [(deck, "paper"), (back, "card_back"), *stacks], size=256)


def bar_rails():
    """The bar_arm_rail kit's rail, about its own bottom middle (its kit prop sits on the bar's top)."""
    c = saloon.BAR
    rr = c["rail_r"]
    yr = c["saddle"] + rr
    half = c["rail_len"] * 0.5
    parts = [tube("a", [(-half, yr, 0.0), (half, yr, 0.0)], rr, sides=16, caps=(True, True))]
    for x in c["saddles"]:
        parts.append(box("s", (0.03, c["saddle"] + rr * 0.5, 0.05), (x, (c["saddle"] + rr * 0.5) * 0.5, 0.0), bevel=0.004))
        parts.append(box("b", (0.05, 0.004, 0.07), (x, 0.002, 0.0), bevel=0.0015))
    metal.export_baked("bar_rails", [(merged("ArmRail", parts), "brass_old")], size=512)


def slat_mat():
    c = saloon.SLAT_MAT
    L, W = c["length"], c["width"]
    rw, rh = c["runner"]
    sw, sh = c["slat"]
    n = int((L + c["gap"]) / (sw + c["gap"]))
    pitch = (L - sw) / (n - 1)
    rng = random.Random(1882)
    slats = [box("s", (sw, sh, W - rng.uniform(0.0, 0.01)), (-L * 0.5 + sw * 0.5 + k * pitch, rh + sh * 0.5 - rng.uniform(0.0, 0.002), rng.uniform(-0.004, 0.004)),
                 bevel=0.004) for k in range(n)]
    metal.export_baked("slat_mat", [(merged("Slats", slats, smooth=False), "slat_wood")], size=512)


STEPS = {"lamps": lamps, "glasses": glasses, "work_board": work_board, "stove": stove, "faro": faro, "piano_stool": piano_stool,
         "wheel": wheel, "till": till, "cards_chips": cards_chips, "bar_rails": bar_rails,
         "slat_mat": slat_mat}


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
