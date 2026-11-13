"""Saloon B's props, batch S2 (#879; docs/briefs/saloon-design.md "The new props in order"): the parts of
the handsaw, the fiddle and its bow and the cookstove that aren't library wood or the barrel's staves,
modelled here in each kit file's space from tools/props/saloon_s2.py's numbers and baked the gun way
(metal.py): saw steel, apple wood, fiddle varnish, ebony, gut, cast iron, nickel, zinc.

    ~/bpyenv/bin/python tools/blender/props/saloon_s2.py [--only=handsaw,fiddle,cookstove]   (~1 min a model)

Then `godot --headless --import` and commit the .glb and .png files with their .import files.
"""
import math
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "props"))

import metal  # noqa: E402
import saloon_s2  # noqa: E402  (tools/props/saloon_s2.py: the numbers)
from common import Part, box, lathe, moved, slab, tube  # noqa: E402
from saloon_s1 import merged  # noqa: E402


def flat(name, outline, y0, y1, bevel=0.0):
    """A slab cut to `outline` [(x, z)] lying flat, from y0 up to y1 (slab's own is in x, y through z)."""
    # slab: (x, y) outline, z0..z1. Turned +90 about x: y -> -z... so give it (x, -z) and z from -y1 to -y0,
    # then (x, y, z) -> (x, -z, y): the outline's -z back to +z... worked through: rotate -90 about x maps
    # (x, Y, Z) to (x, Z, -Y); an outline (x, -z) and Z in [y0, y1] lands at (x, y in [y0, y1], z).
    pts = [(x, -z) for x, z in outline]
    if _area(pts) < 0:
        pts = pts[::-1]
    return moved(slab(name, pts, y0, y1, bevel=bevel), -90.0, (1, 0, 0), (0, 0, 0), name=name)


def _area(pts):
    return 0.5 * sum(x0 * y1 - x1 * y0 for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]))


# --- The handsaw ----------------------------------------------------------------------------------

def handsaw():
    s = saloon_s2.SAW
    L, heel, toe, t = s["blade"], s["heel"], s["toe"], s["thick"]
    hl, hh, ht = s["handle"]
    x0 = -(L + hl - 0.02) * 0.5 + hl - 0.02  # the blade's heel (the handle overlaps it 2 cm)
    x1 = x0 + L
    zt = (heel + 0.05) * 0.5 - 0.024  # the teeth's line (the box has room over the back for the handle's horn)
    yb = ht * 0.5  # the blade's middle plane, at the handle's middle
    # The blade: straight teeth, its back breasted (a little convex) from the heel's width to the toe's.
    back = []
    n = 24
    for i in range(n + 1):
        u = i / n
        w = heel + (toe - heel) * u + 0.012 * math.sin(math.pi * u)
        back.append((x0 + L * u, zt - w))
    outline = [(x0, zt - 0.003), (x1, zt - 0.003)] + back[::-1]
    blade = [flat("b", outline, yb - t * 0.5, yb + t * 0.5)]
    # The teeth: 7 to the inch, a row of points along the edge (each a flat triangle, both faces).
    pitch = 0.0254 / 7
    verts, faces = [], []
    k = 0
    x = x0 + 0.01
    while x + pitch < x1:
        for yy in (yb - t * 0.5, yb + t * 0.5):
            base = len(verts)
            verts += [(x, yy, zt - 0.003), (x + pitch, yy, zt - 0.003), (x + pitch * 0.35, yy, zt + 0.0016)]
            faces.append([base, base + 1, base + 2] if yy > yb else [base, base + 2, base + 1])
        x += pitch
        k += 1
    blade.append(Part("t", False).add(verts, faces))
    # The handle: a closed grip round the hand's hole, its cheek over the blade's heel, the horn at its top.
    hx0 = x0 - hl + 0.02
    loop = []
    cx, cz = hx0 + hl * 0.48, zt - heel * 0.52
    for i in range(16):
        a = 2 * math.pi * i / 16
        loop.append((cx + math.cos(a) * 0.055, yb, cz + math.sin(a) * 0.033))
    loop.append(loop[0])
    grip = tube("g", loop, [(0.013, 0.011)] * len(loop), sides=8, caps=(False, False), up_hint=(0, 1, 0))
    cheek = flat("c", [(x0 - 0.035, zt - 0.006), (x0 + 0.02, zt - 0.004), (x0 + 0.02, zt - heel + 0.002), (x0 - 0.01, zt - heel - 0.012),
                       (x0 - 0.05, zt - heel * 0.75), (x0 - 0.05, zt - 0.03)], yb - ht * 0.5, yb + ht * 0.5, bevel=0.004)
    horn = flat("h", [(x0 - 0.045, zt - heel - 0.005), (x0 - 0.005, zt - heel - 0.018), (x0 - 0.03, zt - heel - 0.035), (x0 - 0.07, zt - heel - 0.02)],
                yb - ht * 0.45, yb + ht * 0.45, bevel=0.004)
    handle = merged("Handle", [grip, cheek, horn])
    nuts = []
    for i in range(s["nuts"]):
        px, pz = x0 - 0.02 + (i % 2) * 0.03, zt - 0.03 - (i // 2) * 0.06 - (i % 2) * 0.02
        nuts.append(lathe("n", [(0.0, yb - ht * 0.5 - 0.002), (0.007, yb - ht * 0.5 - 0.002), (0.007, yb + ht * 0.5 + 0.002), (0.0, yb + ht * 0.5 + 0.002)], 10,
                          at=(px, 0, pz)))
    metal.export_baked("handsaw", [(merged("Blade", blade, smooth=False), "saw_steel"), (handle, "apple_wood"), (merged("Nuts", nuts), "brass_old")],
                       size=512)


# --- The fiddle and its bow -----------------------------------------------------------------------

def _fiddle_halfwidth(x):
    """The body's half-width at x (its middle at 0, the lower bout toward -x): the lower bout, the waist
    (the C-bouts) and the upper bout, round at the ends."""
    f = saloon_s2.FIDDLE
    hb = f["body"] * 0.5
    ctrl = [(-hb, 0.0), (-hb + 0.004, 0.032), (-hb + 0.014, 0.062), (-0.13, 0.092), (-0.085, f["lower"] * 0.5), (-0.045, 0.094),
            (-0.012, 0.068), (0.015, f["waist"] * 0.5), (0.045, 0.062), (0.075, 0.077), (0.105, f["upper"] * 0.5), (0.135, 0.078),
            (hb - 0.016, 0.055), (hb - 0.005, 0.028), (hb, 0.0)]
    xs, ws = zip(*ctrl)
    return float(np.interp(x, xs, ws))


def fiddle():
    f = saloon_s2.FIDDLE
    hb = f["body"] * 0.5
    rib, arch = f["rib"], f["arch"]
    n = 60
    xs = [-hb * math.cos(math.pi * i / n) for i in range(n + 1)]
    upper = [(x, _fiddle_halfwidth(x)) for x in xs]
    outline = upper + [(x, -w) for x, w in reversed(upper[1:-1])]
    # The body: its back a little arched, the ribs, its top arched (the slab's middle raised to a dome).
    body = flat("Body", outline, 0.004, rib + 0.004, bevel=0.004)
    top_y = rib + 0.004
    # (the slab's own two middle points, the top's and the back's: the top's raised into its arch)
    vs = [list(v) for v in body.verts]
    cx = sum(x for x, _ in outline) / len(outline)
    for v in vs:
        if abs(v[1] - top_y) < 1e-6 and abs(v[0] - cx) < 1e-6 and abs(v[2]) < 1e-6:
            v[1] = top_y + arch
        elif abs(v[1] - 0.004) < 1e-6 and abs(v[0] - cx) < 1e-6 and abs(v[2]) < 1e-6:
            v[1] = 0.0
    body = Part("Body", True).add([tuple(v) for v in vs], body.faces)
    ytop = top_y + arch * 0.6
    # The neck, its heel on the upper bout, the pegbox and the scroll.
    nx0, nx1 = hb - 0.01, hb + f["neck"]
    neck = [box("n", (nx1 - nx0, 0.02, 0.026), ((nx0 + nx1) * 0.5, ytop - 0.002, 0), bevel=0.004),
            box("h", (0.018, top_y - 0.002, 0.03), (hb - 0.004, (top_y - 0.002) * 0.5 + 0.002, 0), bevel=0.004),
            box("p", (0.07, 0.03, 0.022), (nx1 + 0.035, ytop - 0.004, 0), bevel=0.004),
            lathe("s", [(0.0, -0.013), (0.018, -0.013), (0.022, -0.006), (0.022, 0.006), (0.018, 0.013), (0.0, 0.013)], 14, axis="z",
                  at=(nx1 + 0.083, ytop + 0.006, 0)),
            lathe("s2", [(0.0, -0.015), (0.009, -0.015), (0.011, 0.0), (0.009, 0.015), (0.0, 0.015)], 10, axis="z", at=(nx1 + 0.083, ytop + 0.006, 0))]
    # Ebony: the fingerboard (tapering, over the body), the nut, the pegs, the tailpiece, the end button.
    bl, bw1, bw0 = f["board"]
    bx1 = nx1
    bx0 = bx1 - bl
    fb_y = ytop + 0.009
    fittings = [flat("f", [(bx0, -bw1 * 0.5), (bx1, -bw0 * 0.5), (bx1, bw0 * 0.5), (bx0, bw1 * 0.5)], fb_y, fb_y + 0.007, bevel=0.002)]
    for i in range(4):
        px = nx1 + 0.012 + (i // 2) * 0.026 + (i % 2) * 0.012
        side = -1 if i % 2 == 0 else 1
        fittings.append(lathe("g", [(0.0, -0.03), (0.0035, -0.03), (0.0035, 0.012), (0.009, 0.016), (0.009, 0.03), (0.0, 0.032)], 8, axis="z",
                              at=(px, ytop + 0.004, 0)) if side > 0 else
                        moved(lathe("g", [(0.0, -0.03), (0.0035, -0.03), (0.0035, 0.012), (0.009, 0.016), (0.009, 0.03), (0.0, 0.032)], 8, axis="z"),
                              180.0, (0, 1, 0), (px, ytop + 0.004, 0)))
    tx0, tx1 = -hb + 0.02, -hb + 0.13
    fittings.append(flat("t", [(tx0, -0.012), (tx1, -0.021), (tx1, 0.021), (tx0, 0.012)], top_y + 0.006, top_y + 0.014, bevel=0.002))
    # The end button at the lower bout's end (axis x: the profile's height runs along x).
    fittings.append(lathe("e", [(0.0, -hb - 0.008), (0.006, -hb - 0.008), (0.006, -hb + 0.002), (0.0, -hb + 0.002)], 10, axis="x",
                          at=(0, rib * 0.5 + 0.004, 0)))
    fittings.append(box("nut", (0.006, 0.004, bw0), (bx1 - 0.002, fb_y + 0.009, 0)))
    # The bridge (maple) and the four strings from the tailpiece over it to the nut (gut).
    bridge_x = -0.02
    by = top_y + arch * 0.85
    bridge = flat("br", [(bridge_x - 0.002, -0.021), (bridge_x + 0.002, -0.021), (bridge_x + 0.002, 0.021), (bridge_x - 0.002, 0.021)], by, by + 0.031)
    strings = [bridge]
    for i in range(4):
        zz = -0.0075 + i * 0.005
        pts = [(tx1, top_y + 0.015, zz * 2.4), (bridge_x, by + 0.032, zz * 2.0), (bx1 - 0.002, fb_y + 0.012, zz)]
        strings.append(tube("s", pts, 0.0007, sides=3, caps=(False, False)))
    # The bow (its own prop, `fiddle_bow`, in its own space: the frog at the origin, the tip at +x).
    b = saloon_s2.BOW
    fw, fh, ft = b["frog"]
    L = b["length"]
    ys = fh + 0.004
    stick_pts = [(L * u, ys - 0.006 * math.sin(math.pi * u) * (u > 0.05), 0.0) for u in np.linspace(0.0, 1.0, 14)]
    stick_r = [(b["stick_r"] - 0.0016 * u, b["stick_r"] - 0.0016 * u) for u in np.linspace(0.0, 1.0, 14)]
    bow = [tube("st", stick_pts, stick_r, sides=8),
           box("fr", (fw, fh, ft), (0.04, fh * 0.5 + 0.001, 0), bevel=0.003),
           box("hd", (0.012, 0.022, 0.009), (L - 0.006, ys - 0.011, 0), bevel=0.002)]
    hair = [box("hr", (L - 0.07, 0.0015, b["hair"]), ((0.065 + L - 0.004) * 0.5, 0.004, 0))]
    parts = [(body, "fiddle_varnish"), (merged("Neck", neck), "fiddle_varnish"), (merged("Fittings", fittings, smooth=False), "ebony"),
             (merged("Strings", strings, smooth=False), "gut"), (merged("Bow", bow), "turned_wood"), (merged("BowHair", hair, smooth=False), "gut")]
    metal.export_baked("fiddle", parts, size=512)


# --- The cookstove --------------------------------------------------------------------------------

def cookstove():
    c = saloon_s2.COOK
    bw, bh, bd = c["board"]
    board = [box("b", (bw, bh, bd), (0, bh * 0.5, 0.06), bevel=0.004)]
    bx, by, bz = c["body"]
    lh = c["leg_h"]
    y0 = bh + lh
    legs = []
    for i, (fx, fz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        x, z = fx * (bx * 0.5 - 0.05), fz * (bz * 0.5 - 0.05)
        # A cabriole: out at the knee, in at the ankle, a pad foot.
        pts = [(x + fx * 0.02, bh + 0.008, z + fz * 0.02), (x + fx * 0.006, bh + 0.05, z + fz * 0.006), (x - fx * 0.006, bh + 0.11, z - fz * 0.004),
               (x + fx * 0.004, bh + 0.17, z + fz * 0.008), (x, y0 + 0.01, z)]
        foot = lathe("f", [(0.0, bh), (0.028, bh), (0.03, bh + 0.008), (0.016, bh + 0.018), (0.0, bh + 0.018)], 10, at=(x + fx * 0.02, 0, z + fz * 0.02))
        legs.append(merged("Leg%d" % i, [tube("l", pts, [(0.02, 0.02), (0.014, 0.014), (0.017, 0.017), (0.024, 0.024), (0.03, 0.03)], sides=8), foot]))
    # The body: a cast box, a moulded plinth, raised panels on its ends and its oven's front, the
    # hearth lip under the firebox's door, the oven's side flue panel.
    zf = bz * 0.5
    body = [box("b", (bx, by, bz), (0, y0 + by * 0.5, 0), bevel=0.01),
            box("pl", (bx + 0.02, 0.035, bz + 0.02), (0, y0 + 0.0175, 0), bevel=0.008),
            box("hl", (0.3, 0.025, 0.09), (c["firebox_x"], y0 + by - 0.06 - c["fire_door"][1] - 0.02, zf + 0.04), bevel=0.006)]
    for s_ in (-1, 1):
        body.append(box("ep", (0.012, by - 0.12, bz - 0.14), (s_ * (bx * 0.5 + 0.004), y0 + by * 0.5 + 0.01, 0), bevel=0.004))
        body.append(box("er", (0.02, 0.03, bz - 0.06), (s_ * (bx * 0.5 + 0.006), y0 + by - 0.03, 0), bevel=0.006))
    body.append(box("fp", (0.24, 0.08, 0.012), (c["firebox_x"], y0 + 0.1, zf + 0.004), bevel=0.004))  # the ash-pit's panel
    body_part = merged("Body", body, smooth=False)
    # Nickel: the towel rail along the front on two brackets, the bands round the top's edge plate.
    ry = y0 + by - 0.02
    nickel = [tube("r", [(-bx * 0.5 + 0.02, ry, zf + 0.09), (bx * 0.5 - 0.02, ry, zf + 0.09)], 0.009, sides=8),
              box("rb0", (0.02, 0.02, 0.1), (-bx * 0.5 + 0.03, ry, zf + 0.045), bevel=0.004),
              box("rb1", (0.02, 0.02, 0.1), (bx * 0.5 - 0.03, ry, zf + 0.045), bevel=0.004),
              box("band", (bx + 0.07, 0.018, 0.01), (0, y0 + by + c["plate"] - 0.009, zf + c["top_over"] + 0.005), bevel=0.003)]
    # The firebox's door with its draught slide; the oven's door, its nickel bands and latch.
    fx, fy, fz = c["fire_door"]
    fyc = y0 + by - 0.06 - fy * 0.5
    fire_door = merged("FireDoor", [box("d", (fx, fy, fz), (c["firebox_x"], fyc, zf + fz * 0.5), bevel=0.006),
                                    box("p", (fx - 0.05, fy - 0.05, 0.008), (c["firebox_x"], fyc, zf + fz + 0.004), bevel=0.003),
                                    box("s", (0.1, 0.03, 0.008), (c["firebox_x"], fyc - 0.03, zf + fz + 0.01), bevel=0.003),
                                    tube("h", [(c["firebox_x"] + fx * 0.3, fyc + 0.04, zf + fz), (c["firebox_x"] + fx * 0.3, fyc + 0.04, zf + fz + 0.03),
                                               (c["firebox_x"] + fx * 0.45, fyc + 0.04, zf + fz + 0.03)], 0.006, sides=6)], smooth=False)
    ox, oy, oz = c["oven_door"]
    oyc = y0 + 0.05 + oy * 0.5
    oven = merged("OvenDoor", [box("d", (ox, oy, oz), (c["oven_x"], oyc, zf + oz * 0.5), bevel=0.008),
                               box("p", (ox - 0.08, oy - 0.08, 0.01), (c["oven_x"], oyc, zf + oz + 0.005), bevel=0.004),
                               lathe("m", [(0.0, -0.004), (0.045, -0.004), (0.045, 0.004), (0.0, 0.004)], 18, axis="z", at=(c["oven_x"], oyc, zf + oz + 0.012))],
                  smooth=False)
    nickel += [box("ob", (ox + 0.01, 0.012, 0.008), (c["oven_x"], oyc + oy * 0.5 - 0.012, zf + oz + 0.004), bevel=0.003),
               box("ob2", (ox + 0.01, 0.012, 0.008), (c["oven_x"], oyc - oy * 0.5 + 0.012, zf + oz + 0.004), bevel=0.003),
               tube("lt", [(c["oven_x"] + ox * 0.36, oyc + 0.05, zf + oz), (c["oven_x"] + ox * 0.36, oyc + 0.05, zf + oz + 0.025),
                           (c["oven_x"] + ox * 0.36, oyc - 0.05, zf + oz + 0.025), (c["oven_x"] + ox * 0.36, oyc - 0.05, zf + oz)], 0.006, sides=6)]
    # The top: the plate with its moulded edge, four lids with their lifter's notch, the lid lifter
    # lying on it, the pipe's collar at the back over the firebox.
    pt, ov = c["plate"], c["top_over"]
    py = y0 + by
    px, pz = c["pipe_at"]
    pr = c["pipe_r"]
    top = [box("t", (bx + ov * 2, pt, bz + ov * 2), (0, py + pt * 0.5, 0), bevel=0.008),
           box("lip", (bx + ov * 2 + 0.01, 0.012, bz + ov * 2 + 0.01), (0, py + pt - 0.006, 0), bevel=0.004)]
    lr = c["lid_r"]
    for lx, lz in c["lids"]:
        top.append(lathe("l", [(0.0, py + pt), (lr, py + pt), (lr, py + pt + 0.006), (lr - 0.01, py + pt + 0.01), (0.0, py + pt + 0.01)], 24, at=(lx, 0, lz)))
        top.append(box("n", (0.035, 0.008, 0.012), (lx, py + pt + 0.013, lz), bevel=0.002))
    top.append(tube("lift", [(0.2, py + pt + 0.015, 0.2), (0.36, py + pt + 0.015, 0.19), (0.38, py + pt + 0.03, 0.188)], 0.006, sides=5))
    top.append(lathe("c", [(pr + 0.012, py + pt), (pr + 0.012, py + pt + 0.05), (pr + 0.006, py + pt + 0.06), (pr + 0.004, py + pt + 0.06)], 24,
                     at=(px, 0, pz), caps=(False, False)))
    pipes = []
    y = py + pt
    for k, ln in enumerate(c["pipe"]):
        prof = [(pr, y), (pr, y + ln - 0.05), (pr - 0.004, y + ln - 0.04), (pr - 0.004, y + ln), (0.0, y + ln)]
        if k == 0:
            prof = [(0.0, y)] + prof
        parts_ = [lathe("p", prof, 18, at=(px, 0, pz), caps=(False, False))]
        if k == 0:
            parts_.append(tube("d", [(px - pr - 0.06, y + 0.3, pz), (px + pr + 0.01, y + 0.3, pz)], 0.004, sides=5))
            parts_.append(box("w", (0.05, 0.03, 0.016), (px - pr - 0.07, y + 0.3, pz), bevel=0.004))
        pipes.append(merged("Pipe%d" % k, parts_))
        y += ln
    parts = [(merged("Board", board, smooth=False), "zinc"), *[(lg, "cast_iron") for lg in legs], (body_part, "cast_iron"),
             (merged("Nickel", nickel), "nickel"), (fire_door, "cast_iron"), (oven, "cast_iron"), (merged("Top", top, smooth=False), "cast_iron"),
             *[(p, "sheet_iron") for p in pipes]]
    metal.export_baked("cookstove", parts, size=1024)


STEPS = {"handsaw": handsaw, "fiddle": fiddle, "cookstove": cookstove}


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
