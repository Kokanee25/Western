"""The doctor's office props (docs/briefs/prop-factory.md, "The doctor's office batch", #788): the
kit files of an 1882 country doctor's furniture, written from the numbers here, so a change is one
number and a re-run. The Blender half (tools/blender/props/doctor_*.py) reads the same numbers.

    python3 tools/props/doctor.py [--batch=D3]   # writes assets/props/kit/<id>.json for batches D1 to D3

Woods from the material library (`lib:<entry>/<age>`, #721, #825: `furniture_oak` and
`furniture_painted_pine`, never his floor's `floor_fir_worn`), metal and cloth baked the gun way
(`pbr:<model>`, tools/blender/props/metal.py). Masses from the materials (TimberTuning: walnut, iron,
straw, hay, canvas); every member's kind on the support ladder (docs/briefs/prop-factory.md "Kinds").
Each prop's period reference: experiments/prop_lab/refs/doctor/README.md.
"""
import json
import math
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KIT = os.path.join(ROOT, "assets", "props", "kit")

# Furniture is never the floor's wood (Sean's picks 2 and 5 on #821; docs/briefs/prop-factory.md point 1):
# office pieces in the library's furniture oak, plain pieces (shelving, counters, a washstand, a peg rail)
# in its painted pine; `/top` a top's wear, `/front` a drawer front's (hands round the pull). The walnut
# (`furniture_walnut`) is parked: the room's good piece, his desk, takes oak until it passes.
OAK = "lib:furniture_oak/few"
OAK_TOP = OAK + "/top"
OAK_FRONT = OAK + "/front"
PINE = "lib:furniture_painted_pine/few"
PINE_TOP = PINE + "/top"
PINE_FRONT = PINE + "/front"


def r(v, n=4):
    return [round(float(c), n) for c in v] if isinstance(v, (list, tuple)) else round(float(v), n)


def member(mid, kind, size, at, wood=None, look=None, **kw):
    m = {"id": mid, "kind": kind, "size": r(size), "at": r(at)}
    if wood:
        m["wood"] = wood
    if look:
        m["look"] = look
    m.update(kw)
    return m


def mesh(model, part):
    return {"shape": "mesh", "model": model, "part": part}


# --- The examining table --------------------------------------------------------------------------
# A oak table at the height a doctor works standing (29 in), 6 ft by 2 ft, three drawers in its
# apron on his side (+z), a low shelf, a buttoned horsehair pad in leather along it and a raised head (a wedge of
# the same: the head end, +x). Refs: the 1880 Stohlmann catalogue, the Remick museum's table. Legs set in from the corners, aprons flush with their outer faces.
TABLE = {
    "length": 1.83, "width": 0.61, "top": 0.74, "board": 0.026, "boards": 3,
    "leg": 0.065, "inset": 0.06, "apron_h": 0.17, "apron_t": 0.022,
    "stretcher": (0.05, 0.035), "stretcher_y": 0.14, "shelf_t": 0.018, "shelf_boards": 6,
    "drawers": (3, 1), "drawer_t": 0.022,
    "pad": {"length": 1.19, "height": 0.075, "width": 0.56, "x": -0.21, "button": 0.14},
    "head": {"length": 0.5, "low": 0.05, "high": 0.22, "width": 0.56, "x": 0.635},
}


def table_drawers():
    """The examining table's drawer fronts: [(column, row, (width, height), (x, y, z of its middle))]."""
    t = TABLE
    H, L, W = t["top"], t["length"], t["width"]
    under = H - t["board"]
    lx, lz, hl = L * 0.5 - t["inset"], W * 0.5 - t["inset"] + 0.01, t["leg"] * 0.5
    inner_x = lx - hl
    bottom_top = under - t["apron_h"]  # the drawers fill the front apron's face
    cols, rows = t["drawers"]
    gap = 0.006
    dw = (inner_x * 2 - gap * (cols + 1)) / cols
    dh = (under - bottom_top - gap * (rows + 1)) / rows
    zf = lz + hl + t["drawer_t"] * 0.5
    return [(c, r_, (dw, dh), (-inner_x + gap + dw * 0.5 + c * (dw + gap), bottom_top + gap + dh * 0.5 + r_ * (dh + gap), zf))
            for c in range(cols) for r_ in range(rows)]


def examining_table():
    t = TABLE
    L, W, H = t["length"], t["width"], t["top"]
    under = H - t["board"]  # the legs' and aprons' tops
    lx = L * 0.5 - t["inset"]
    lz = W * 0.5 - t["inset"] + 0.01
    hl = t["leg"] * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [t["leg"], under, t["leg"]], [sx * lx, under * 0.5, sz * lz], look=OAK))
    inner_x = lx - hl
    inner_z = lz - hl
    ay = under - t["apron_h"] * 0.5
    for s in (-1, 1):
        ms.append(member("apron_long_%s" % ("b" if s < 0 else "f"), "furniture_frame", [inner_x * 2, t["apron_h"], t["apron_t"]],
                         [0, ay, s * (lz + hl - t["apron_t"] * 0.5)], look=OAK))
        ms.append(member("apron_end_%s" % ("foot" if s < 0 else "head"), "furniture_frame", [t["apron_t"], t["apron_h"], inner_z * 2],
                         [s * (lx + hl - t["apron_t"] * 0.5), ay, 0], look=OAK))
        sw, sh = t["stretcher"]
        ms.append(member("stretcher_%s" % ("b" if s < 0 else "f"), "furniture_frame", [inner_x * 2, sw, sh],
                         [0, t["stretcher_y"], s * lz], look=OAK))
    # The top: its boards along it, edge to edge (worn where he leans and works: the library's top).
    bw = W / t["boards"]
    for k in range(t["boards"]):
        ms.append(member("top%d" % k, "furniture_top", [L, t["board"], bw], [0, H - t["board"] * 0.5, -W * 0.5 + bw * (k + 0.5)], look=OAK_TOP))
    # The bottom: boards laid across from stretcher to stretcher, edge to edge between the legs.
    sw, sh = t["stretcher"]
    span = (lz + sh * 0.5) * 2
    sbw = inner_x * 2 / t["shelf_boards"]
    bottom_top = t["stretcher_y"] + sw * 0.5 + t["shelf_t"]
    for k in range(t["shelf_boards"]):
        ms.append(member("shelf%d" % k, "furniture_top", [sbw, t["shelf_t"], span],
                         [-inner_x + sbw * (k + 0.5), bottom_top - t["shelf_t"] * 0.5, 0], look=OAK))
    # On the doctor's side (+z) a row of drawers in the deep apron under the top (the period's tables
    # carry drawers: the 1880 Stohlmann catalogue's, the Remick museum's), each with its brass knob;
    # the legs and the low shelf open below, as the doctor's target sheet's table.
    for c, r_, (dw, dh), (x, y, zf) in table_drawers():
        if True:
            m = member("drawer_%d_%d" % (c, r_), "trim", [dw, dh, t["drawer_t"]], [x, y, zf], look=OAK_FRONT)
            m["dress"] = [{"look": "pbr:examining_table", "draw": mesh("examining_table", "Knob_%d_%d" % (c, r_))}]
            ms.append(m)
    p = t["pad"]
    ms.append(member("pad", "trim", [p["length"], p["height"], p["width"]], [p["x"], H + p["height"] * 0.5, 0],
                     wood="hay", look="pbr:examining_table", draw=mesh("examining_table", "Pad")))
    h = t["head"]
    ms.append(member("head", "trim", [h["length"], h["high"], h["width"]], [h["x"], H + h["high"] * 0.5, 0],
                     wood="straw", look="pbr:examining_table", draw=mesh("examining_table", "HeadPad")))
    return {
        "_doc": "An 1880s country doctor's examining table (#788; refs experiments/prop_lab/refs/doctor/): an oak table 6 ft by 2 ft at a standing doctor's working height (29 in), three drawers in its deep apron on his side (+z) with brass knobs (the 1880 Stohlmann catalogue's and the Remick museum's tables carry drawers), a shelf low down for the basin and dressings, a buttoned horsehair pad in brown leather along it and a raised head of the same at its +x end. Oak from the material library (a few years, the doctor's own floor: the top worn where he leans); the pads baked the gun way (tools/blender/props/doctor_d1.py). Heavy stock: a .45 ball through a 65 mm leg (the carve leaves ~0.4 of it) holes it and it stands (`splits_below` 0.3). ~55 kg. The patient lies on it: his weight on the pad (`seat`, all of it). Written by tools/props/doctor.py.",
        "id": "examining_table", "kind": "members", "fixture": True, "wood": "oak",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "seat": {"member": "pad", "at": [-0.15, H + p["height"], 0.0], "share": 1.0, "hold": 0.1, "sway": 0.0},
        "members": ms,
    }


# --- The patient's iron cot -----------------------------------------------------------------------
# A single japanned iron cot (the hospitals' and doctors' sick rooms' of the 1870s-80s): tube posts
# with ball finials, a higher head end, rails and filler rods, angle-iron side rails carrying a woven
# wire spring, a straw tick in blue-and-white ticking, a grey wool blanket and a pillow. Its iron
# members' boxes are the metal's own cross-section (a 28 mm tube's 2 mm wall is a 13 mm square of
# iron), so it weighs what it did (~18 kg of iron); the tubes are drawn full size. The head at -z.
COT = {
    "length": 1.93, "width": 0.86, "head_h": 1.05, "foot_h": 0.86, "post": 0.028, "post_box": 0.013,
    "rail": 0.022, "rail_box": 0.011, "side": 0.04, "side_box": 0.019, "spring_y": 0.42,
    "head_rails": (0.42, 0.99), "foot_rails": (0.42, 0.80), "fillers": 7,
    "tick": (0.82, 0.13, 1.86), "blanket": (0.86, 0.02, 1.30), "pillow": (0.56, 0.11, 0.32),
}


def iron_cot():
    c = COT
    L, W = c["length"], c["width"]
    px, pz = W * 0.5 - c["post"] * 0.5, L * 0.5 - c["post"] * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        h = c["head_h"] if sz < 0 else c["foot_h"]
        ms.append(member("post%d" % i, "post", [c["post_box"]] * 1 + [h] + [c["post_box"]], [sx * px, h * 0.5, sz * pz],
                         draw=mesh("iron_cot", "Post%d" % i)))
    inner = px - c["post_box"] * 0.5
    for end, sz, ys in (("head", -1, c["head_rails"]), ("foot", 1, c["foot_rails"])):
        for k, y in enumerate(ys):
            m = member("%s_rail%d" % (end, k), "furniture_frame", [inner * 2, c["rail_box"], c["rail_box"]], [0, y, sz * pz],
                       draw=mesh("iron_cot", "%sRail%d" % (end.capitalize(), k)))
            if k == 0:
                # The filler rods between the rails, drawn on the low rail (they carry nothing).
                m["dress"] = [{"look": "pbr:iron_cot", "draw": mesh("iron_cot", "%sFill" % end.capitalize())}]
            ms.append(m)
    inner_z = pz - c["post_box"] * 0.5
    y = c["spring_y"] - c["side_box"] * 0.5
    for s, name in ((-1, "l"), (1, "r")):
        m = member("side_%s" % name, "furniture_frame", [c["side_box"], c["side_box"], inner_z * 2], [s * (px - 0.004), y, 0],
                   draw=mesh("iron_cot", "Side%s" % name.upper()))
        if name == "l":
            # The woven wire spring between the side rails, drawn on one (the tick lies on the rails).
            m["dress"] = [{"look": "pbr:iron_cot", "draw": mesh("iron_cot", "Spring")}]
        ms.append(m)
    tx, ty, tz = c["tick"]
    top = c["spring_y"]
    ms.append(member("tick", "trim", [tx, ty, tz], [0, top + ty * 0.5, 0.0], wood="straw", draw=mesh("iron_cot", "Tick")))
    bx, by, bz = c["blanket"]
    ms.append(member("blanket", "trim", [bx - 0.04, by, bz], [0, top + ty + by * 0.5, tz * 0.5 - bz * 0.5], wood="canvas",
                     draw=mesh("iron_cot", "Blanket")))
    qx, qy, qz = c["pillow"]
    ms.append(member("pillow", "trim", [qx, qy, qz], [0, top + ty + qy * 0.5, -tz * 0.5 + qz * 0.5 + 0.03], wood="straw",
                     draw=mesh("iron_cot", "Pillow")))
    return {
        "_doc": "The patient's cot (#788; refs experiments/prop_lab/refs/doctor/): a single japanned iron cot of the 1870s-80s, tube posts with ball finials, the head end higher, filler rods between its rails, angle-iron side rails carrying a woven wire spring; a straw tick in blue-and-white ticking, a grey wool blanket with a dark band at its ends, a pillow. Its iron members' boxes are the metal's own section (a 28 mm tube's wall is a 13 mm square of iron) so it weighs ~18 kg of iron; drawn full size, baked the gun way (tools/blender/props/doctor_d1.py; japanned, worn to the iron at its edges). The tick, blanket and pillow burn; the iron doesn't. The head at -z: a man lies looking +z. Written by tools/props/doctor.py.",
        "id": "iron_cot", "kind": "members", "fixture": True, "wood": "iron", "look": "pbr:iron_cot",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "tick", "at": [0.0, top + ty, 0.1], "share": 1.0, "hold": 0.1, "sway": 0.0},
        "members": ms,
    }


# --- The washstand --------------------------------------------------------------------------------
# A plain painted pine washstand: a top with a low splashback, a drawer in the front apron (its brass knob),
# a shelf low down for the slop jar; the basin and pitcher stand on it (their own kit files: china).
WASH = {"width": 0.76, "depth": 0.42, "top": 0.76, "board": 0.022, "leg": 0.045, "inset": 0.02,
        "apron_h": 0.12, "apron_t": 0.02, "shelf_y": 0.14, "splash": (0.14, 0.018)}


def wash_towel_bar():
    """The washstand's towel bar's middle (x, y, z) in its space: off its +x side, under the top."""
    w = WASH
    return (w["width"] * 0.5 + 0.05, w["top"] - 0.13, 0.0)


def washstand():
    w = WASH
    W, D, H = w["width"], w["depth"], w["top"]
    under = H - w["board"]
    lx, lz = W * 0.5 - w["inset"] - w["leg"] * 0.5, D * 0.5 - w["inset"] - w["leg"] * 0.5
    hl = w["leg"] * 0.5
    ms = []
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("leg%d" % i, "post", [w["leg"], under, w["leg"]], [sx * lx, under * 0.5, sz * lz], look=PINE))
    ay = under - w["apron_h"] * 0.5
    for s in (-1, 1):
        a = member("apron_%s" % ("back" if s < 0 else "front"), "furniture_frame", [(lx - hl) * 2, w["apron_h"], w["apron_t"]],
                   [0, ay, s * (lz + hl - w["apron_t"] * 0.5)], look=PINE)
        if s > 0:
            a["dress"] = [{"look": "pbr:washset", "draw": mesh("washset", "Knob")}]
        ms.append(a)
        ms.append(member("apron_%s" % ("l" if s < 0 else "r"), "furniture_frame", [w["apron_t"], w["apron_h"], (lz - hl) * 2],
                         [s * (lx + hl - w["apron_t"] * 0.5), ay, 0], look=PINE))
        ms.append(member("stretcher_%s" % ("l" if s < 0 else "r"), "furniture_frame", [0.03, 0.03, (lz - hl) * 2],
                         [s * lx, w["shelf_y"], 0], look=PINE))
    # The top in two boards, the shelf in two boards across the side stretchers.
    for k in range(2):
        ms.append(member("top%d" % k, "furniture_top", [W, w["board"], D * 0.5], [0, H - w["board"] * 0.5, -D * 0.25 + D * 0.5 * k], look=PINE_TOP))
    # (between the legs front to back, from stretcher to stretcher across)
    sd = (lz - hl) * 2
    for k in range(2):
        ms.append(member("shelf%d" % k, "furniture_top", [lx * 2, 0.016, sd * 0.5], [0, w["shelf_y"] + 0.015 + 0.008, -sd * 0.25 + sd * 0.5 * k], look=PINE))
    sh, st = w["splash"]
    ms.append(member("splashback", "trim", [W, sh, st], [0, H + sh * 0.5, -D * 0.5 + st * 0.5], look=PINE))
    # A towel bar on two brackets off the +x legs (the hand towel, cloth, hangs over it).
    bx, by, bz = wash_towel_bar()
    for k, sz in enumerate((-1, 1)):
        ms.append(member("towel_bracket%d" % k, "cripple", [bx - (lx + hl), 0.03, 0.03], [(lx + hl + bx) * 0.5, by, sz * lz], look=PINE))
    ms.append(member("towel_bar", "trim", [0.022, 0.022, lz * 2 + 0.03], [bx, by + 0.026, 0], look=PINE))
    return {
        "_doc": "A plain painted pine washstand (#788; refs experiments/prop_lab/refs/doctor/): a two-board top with a low splashback, a drawer in the front apron with its brass knob, a towel bar off its side (its towel the hand_towel kit file, cloth), a shelf low down; the wash basin and pitcher (white ironstone china, their own kit files) stand on it. Painted pine from the material library (a few years, as the examining table). ~22 kg. Written by tools/props/doctor.py.",
        "id": "washstand", "kind": "members", "fixture": True, "wood": "weathered_pine",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The china: wash basin and pitcher (white ironstone) -------------------------------------------
BASIN = {"radius": 0.19, "height": 0.095, "foot": 0.075}
PITCHER = {"radius": 0.105, "height": 0.31, "foot": 0.075}


def wash_basin():
    return {
        "_doc": "A white ironstone wash basin with a cobalt line under its rim (the common washstand china of the 1860s-80s; #788, refs experiments/prop_lab/refs/doctor/), 38 cm across: a prop that shatters (GlassProp). ~5 mm of fired clay under its glaze: it breaks dropped from a table's height or kicked (2.5 m/s) and at ~25 kPa; a ball breaks it. Baked the gun way (tools/blender/props/doctor_d1.py). Holds a litre of water. Written by tools/props/doctor.py.",
        "id": "wash_basin", "kind": "shatters", "fixture": True,
        "model": "glb:washset", "looks": {"Basin": "pbr:washset", "BasinBand": "pbr:washset"},
        "size": r([BASIN["radius"] * 2, BASIN["height"], BASIN["radius"] * 2]),
        "mass": 1.6, "wall": 0.005, "glass": ["Basin", "BasinBand"], "whole": [], "shards": 9, "piece_mass": 0.2,
        "breaks_at": 2.5, "shatters_kpa": 25, "heat_seconds": 1e9, "cut_area": 0.03,
        "contents": {"liquid": "water", "litres": 1.0},
    }


def wash_pitcher():
    return {
        "_doc": "A white ironstone pitcher (ewer) to the basin (#788), 31 cm high with its handle and lip, standing in the basin: a prop that shatters (GlassProp), as the basin. Holds 2.5 l of water. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "wash_pitcher", "kind": "shatters", "fixture": True,
        "model": "glb:washset", "looks": {"Pitcher": "pbr:washset", "PitcherBand": "pbr:washset"},
        "size": r([PITCHER["radius"] * 2, PITCHER["height"], PITCHER["radius"] * 2]),
        "mass": 1.4, "wall": 0.005, "glass": ["Pitcher", "PitcherBand"], "whole": [], "shards": 9, "piece_mass": 0.2,
        "breaks_at": 2.5, "shatters_kpa": 25, "heat_seconds": 1e9, "cut_area": 0.03,
        "contents": {"liquid": "water", "litres": 2.5},
    }


# --- The instrument tray --------------------------------------------------------------------------
# A white enamelled iron tray, and on it what he'd lay out for a gunshot wound in 1882: a bone saw, a
# bullet forceps, Nélaton's probe (the porcelain-tipped probe for finding a ball, 1862) and a scalpel,
# nickel-plated, the saw and scalpel ebony-handled.
TRAY = {"size": (0.36, 0.045, 0.24)}


def instrument_tray():
    return {
        "_doc": "An instrument tray (#788; refs experiments/prop_lab/refs/doctor/): a japanned tin tray 36 x 24 cm with a white linen napkin in it, with a bone saw, a bullet forceps, Nelaton's porcelain-tipped probe and a scalpel on it (nickel-plated; the saw and scalpel ebony-handled). A loose rigid prop (LooseProp): a ball holes its thin iron and knocks it, a boot sends it, a hard landing dents it; it doesn't burn. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "instrument_tray", "kind": "loose", "fixture": True,
        "model": "glb:instrument_tray",
        "looks": {k: "pbr:instrument_tray" for k in ("Tray", "Cloth", "SawBlade", "SawHandle", "Forceps", "Probe", "ProbeTip",
                                                     "ScalpelBlade", "ScalpelHandle")},
        "shape": "box", "size": r(TRAY["size"]),
        "mass": 1.3, "wall": 0.0008, "hole_radius": 0.005, "breaks_at": 4.0, "shatters_kpa": 1e9,
        "spills_below": 0.0,
        "dent": {"radius": 0.03, "shot": 0.004, "kick": 0.008, "fall": 0.004},
    }


# --- The lamp with a reflector --------------------------------------------------------------------
# A wall bracket lamp (both references hang on the wall: a dished tin reflector behind the chimney,
# the fount in a ring on the bracket), hung on a nail as the sconce is; the doctor takes it down and
# holds it over the table at night (DESIGN.md's showcase). Its axis at the origin, the wall `wall`
# behind it.
LAMP = {"size": (0.24, 0.44, 0.26), "wall": 0.125}


def reflector_lamp():
    return {
        "_doc": "A wall bracket lamp with a reflector (#788; refs experiments/prop_lab/refs/doctor/: both period lamps hang on the wall): a tin fount in a ring on a japanned bracket, a brass burner and a globe chimney, and a dished tinplate reflector 22 cm across on the wall behind, throwing its light forward (+z) into the room. Hung on one nail through the reflector's tab, as the sconce: its wall board shot out or burnt, it falls and smashes. A prop that shatters (GlassProp, `like` the oil lamp: its oil, its chimney's breaking): the chimney breaks, the tin and brass come through whole. The surgery's lamp; at night the doctor holds it over the table. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "reflector_lamp", "like": "oil_lamp", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:reflector_lamp",
        "looks": {"Chimney": "prop:chimney_glass", "Font": "pbr:reflector_lamp", "Burner": "pbr:reflector_lamp",
                  "Reflector": "pbr:reflector_lamp", "Bracket": "pbr:reflector_lamp"},
        "size": r(LAMP["size"]), "mass": 1.0,
        "hangs": {"nails": [[0.0, 0.395, -LAMP["wall"] + 0.004]]},
        "glass": ["Chimney"], "whole": [["Font", "Burner", "Reflector", "Bracket"]],
    }


# --- The hand towel -------------------------------------------------------------------------------
# A linen huckaback hand towel (the washstand's; Sean, #788: "like the barkeep's towel, can be used to
# wipe up blood"): the bar rag's cloth (`like` bar_cloth), larger, white with a red woven border.
def hand_towel():
    return {
        "_doc": "A linen huckaback hand towel, 75 x 45 cm, white with red woven borders (the washstand's; Sean, #788: like the barkeep's rag, and it wipes up blood). A prop that's cloth (ClothProp, `like` the bar rag): it drapes over the washstand's bar by its own physics, is picked up, dropped, knocked off, burns. Linen huckaback ~250 g/m2: ~85 g dry. Pressed on a wound it takes up blood as a pad (`soaks`); held and drawn over a table's top or the floor it wipes up what's there (ClothProp.wipe_at: blood marks and pools, spilt water and drink), up to ~250 ml (linen takes up about three times its weight). Written by tools/props/doctor.py.",
        "id": "hand_towel", "like": "bar_cloth", "fixture": True,
        "size": [0.75, 0.45], "points": [12, 8], "mass": 0.085,
        "colour": [0.86, 0.84, 0.79], "stains": [0.62, 0.56, 0.47],
        "stripe": [0.55, 0.12, 0.1], "stripe_at": [0.1, 0.9], "stripe_width": 0.015,
        "holds_ml": 250.0, "wipe_rate": 1.2, "flame_radius": 0.18,
    }


# === Batch D2: the dispensary and the front office (#805) ===========================================

# --- The medicine bottles ---------------------------------------------------------------------------
# A druggist's shelf of the 1870s-80s (refs experiments/prop_lab/refs/doctor/ README, "D2"): four kinds,
# each its own kit file drawn from one Blender model (glb:medicine_bottles), each with four paper
# labels (the kit's `variants`: the Nth of a kind made wears label N mod 4).
#   panel: the prescription "panel" bottle, aqua (the commonest druggist's bottle of the period),
#          4 oz, a flat front for the label, a cork;
#   round: a round amber bottle (tinctures and fluid extracts kept from the light), 8 oz, a cork;
#   poison: a small cobalt-blue hexagonal poison bottle, 2 oz, ribbed edges to be known by touch,
#           a red POISON label (state pharmacy laws of the 1870s-80s asked for one);
#   jar: a clear glass "shop round" with a ground glass stopper, 1 pint, for powders (the shelf's
#        big bottles; its label under the varnish, black with gilt).
# Sections bottom up: (y, half width x, half depth z, squareness (2 round, 6 a rounded box), sides:
# 0 smooth, 6 a hexagon). The neck and lip round. `label`: (y0, y1, the arc's half angle about +z,
# in radians); `liquid`: its top's height and finish; `stopper`: cork or glass.
BOTTLES = {
    "panel": {
        "kit": "medicine_bottle", "glass": "aqua", "litres": 0.118, "mass": 0.21,
        "sections": [(0.0, 0.025, 0.0140, 6, 0), (0.004, 0.026, 0.0150, 6, 0), (0.100, 0.026, 0.0150, 6, 0),
                     (0.112, 0.020, 0.0130, 4, 0), (0.120, 0.0105, 0.0100, 2, 0), (0.128, 0.0095, 0.0095, 2, 0),
                     (0.129, 0.0118, 0.0118, 2, 0), (0.136, 0.0118, 0.0118, 2, 0), (0.137, 0.0090, 0.0090, 2, 0)],
        "label": (0.030, 0.088, 0.95), "liquid": (0.096, "tincture"), "stopper": ("cork", 0.0088, 0.122, 0.146),
        "liquid_name": "tincture", "colour": [0.42, 0.16, 0.06],
        "labels": [("TINCT. OPII", "LAUDANUM", "Dose: 10 to 20 drops"), ("TINCT. ARNICAE", "for bruises & sprains", "Not to be taken"),
                   ("SYR. IPECAC.", "EMETIC", "Dose: one teaspoonful"), ("TINCT. FERRI CHLOR.", "IRON", "Dose: 15 drops in water")],
    },
    "round": {
        "kit": "medicine_bottle_round", "glass": "amber", "litres": 0.236, "mass": 0.40,
        "sections": [(0.0, 0.0285, 0.0285, 2, 0), (0.005, 0.030, 0.030, 2, 0), (0.115, 0.030, 0.030, 2, 0),
                     (0.130, 0.025, 0.025, 2, 0), (0.142, 0.013, 0.013, 2, 0), (0.157, 0.0115, 0.0115, 2, 0),
                     (0.158, 0.0138, 0.0138, 2, 0), (0.166, 0.0138, 0.0138, 2, 0), (0.167, 0.0105, 0.0105, 2, 0)],
        "label": (0.032, 0.098, 1.25), "liquid": (0.12, "syrup"), "stopper": ("cork", 0.0102, 0.150, 0.176),
        "liquid_name": "tincture", "colour": [0.35, 0.12, 0.04],
        "labels": [("SPT. AMMON. AROM.", "SAL VOLATILE", "Dose: half a teaspoonful"), ("TINCT. CINCHONAE CO.", "BARK", "Dose: one teaspoonful"),
                   ("EXT. ERGOTAE FL.", "", "Dose: as directed"), ("VIN. COLCHICI", "for the gout", "Dose: 20 drops")],
    },
    "poison": {
        "kit": "poison_bottle", "glass": "cobalt", "litres": 0.059, "mass": 0.13,
        "sections": [(0.0, 0.0185, 0.0185, 2, 6), (0.004, 0.0195, 0.0195, 2, 6), (0.072, 0.0195, 0.0195, 2, 6),
                     (0.082, 0.015, 0.015, 2, 6), (0.090, 0.0085, 0.0085, 2, 0), (0.099, 0.0078, 0.0078, 2, 0),
                     (0.100, 0.0098, 0.0098, 2, 0), (0.106, 0.0098, 0.0098, 2, 0), (0.107, 0.0072, 0.0072, 2, 0)],
        "label": (0.022, 0.060, 0.50), "liquid": (0.075, "tincture"), "stopper": ("cork", 0.0072, 0.094, 0.113),
        "liquid_name": "poison", "colour": [0.3, 0.2, 0.1],
        "labels": [("POISON", "LAUDANUM", ""), ("POISON", "TR. ACONITI", ""), ("POISON", "STRYCHNIA", ""), ("POISON", "ACID. CARBOLIC.", "")],
    },
    "jar": {
        "kit": "drug_jar", "glass": "clear", "litres": 0.473, "mass": 0.80,
        "sections": [(0.0, 0.043, 0.043, 2, 0), (0.006, 0.045, 0.045, 2, 0), (0.150, 0.045, 0.045, 2, 0),
                     (0.168, 0.038, 0.038, 2, 0), (0.180, 0.024, 0.024, 2, 0), (0.190, 0.022, 0.022, 2, 0),
                     (0.191, 0.0265, 0.0265, 2, 0), (0.198, 0.0265, 0.0265, 2, 0), (0.199, 0.0200, 0.0200, 2, 0)],
        "label": (0.050, 0.118, 0.85), "liquid": (0.11, "powder"), "stopper": ("glass", 0.019, 0.184, 0.226),
        "liquid_name": "powder", "colour": [0.85, 0.83, 0.78],
        "labels": [("PULV. RHEI", "", ""), ("QUIN. SULPH.", "", ""), ("POT. BROMID.", "", ""), ("MAG. SULPH.", "", "")],
        # What's in each, by its label: rhubarb root's yellow-brown powder, the rest white.
        "fills": ["rhubarb", "powder", "crystals", "crystals"],
    },
}
# Each kind's thin glass: a 4 oz prescription bottle's wall ~2 mm (the whiskey bottle's 4): it breaks
# off a shelf onto boards (a 0.6 m fall, 3.4 m/s) and at a lower overpressure; the jar's heavier glass
# takes a little more.
BOTTLE_BREAKS = {"panel": (3.2, 40), "round": (3.4, 45), "poison": (3.4, 45), "jar": (3.8, 50)}


def bottle_size(kind):
    b = BOTTLES[kind]
    w = max(max(s[1], s[2]) for s in b["sections"]) * 2
    return [w, b["stopper"][3], w]


def bottle(kind):
    b = BOTTLES[kind]
    k = kind.capitalize()
    breaks, kpa = BOTTLE_BREAKS[kind]
    liquid = ("Liquid%s%%d" % k) if b.get("fills") else "Liquid" + k
    looks = {"Glass" + k: "glass:" + b["glass"], liquid: "pbr:medicine_bottles", "Label%s%%d" % k: "pbr:medicine_labels"}
    if b["stopper"][0] == "cork":
        looks["Cork" + k] = "pbr:medicine_bottles"
    else:
        looks["Stopper" + k] = "glass:" + b["glass"]
    what = {"panel": "an aqua glass prescription panel bottle (4 oz), a flat front with its paper label, a cork",
            "round": "a round amber glass bottle (8 oz, tinctures kept from the light), its paper label round the front, a cork",
            "poison": "a cobalt-blue hexagonal poison bottle (2 oz), its ribbed edges known by touch in the dark, a red POISON label, a cork",
            "jar": "a clear glass shop round (1 pint) with a ground glass stopper, its paper label, a powder or crystals in it"}[kind]
    names = ", ".join(l[0] for l in b["labels"])
    return {
        "_doc": "A druggist's bottle (#805; refs experiments/prop_lab/refs/doctor/): %s. A prop that shatters (GlassProp): thin glass, so a ball, a fall off a shelf (%.1f m/s) or %d kPa breaks it and what's in it goes on the floor. Four labels in the period's style (%s): the Nth made wears label N mod 4 (`variants`). Drawn from glb:medicine_bottles (tools/blender/props/doctor_d2.py): the glass the kit's `glass:` look, the labels printed (pbr:medicine_labels), the cork and contents baked the gun way. Written by tools/props/doctor.py." % (what, breaks, kpa, names),
        "id": b["kit"], "kind": "shatters", "fixture": True, "in_game": False,
        "model": "glb:medicine_bottles", "looks": looks, "variants": len(b["labels"]),
        "size": r(bottle_size(kind)), "mass": b["mass"], "wall": 0.0025,
        "glass": ["Glass" + k, "Liquid" + k, "Label" + k] + (["Stopper" + k] if b["stopper"][0] == "glass" else []),
        "whole": [["Cork" + k]] if b["stopper"][0] == "cork" else [],
        "shards": 8 if kind != "jar" else 12, "piece_mass": 0.01, "breaks_at": breaks, "shatters_kpa": kpa,
        "heat_seconds": 20, "cut_area": 0.02 if kind != "jar" else 0.04,
        "contents": {"liquid": b["liquid_name"], "litres": round(b["litres"] * (0.6 if kind == "jar" else 0.8), 3), "colour": b["colour"]},
    }


def medicine_bottle():
    return bottle("panel")


def medicine_bottle_round():
    return bottle("round")


def poison_bottle():
    return bottle("poison")


def drug_jar():
    return bottle("jar")


# --- The mortar and pestle -------------------------------------------------------------------------
# A Wedgwood-ware mortar and pestle (the druggist's prescription mortar of the 19th century: a hard,
# unglazed white stoneware bowl on a foot with a pouring lip; the pestle's head the same stoneware on
# a turned wooden handle), about a pint: 15 cm across. Its axis at the origin; the lip toward +x.
# The Met's Wedgwood mortar (refs mortar_wedgwood_stoneware_met.jpg): twice as wide as it's tall, a thick
# rounded rim, no foot to speak of, a long dark wooden pestle handle.
MORTAR = {"radius": 0.092, "height": 0.084, "foot": 0.066, "bowl": 0.074, "bowl_depth": 0.064,
          "pestle": {"head": 0.024, "length": 0.21, "tilt": 32.0}}


def mortar():
    m = MORTAR
    return {
        "_doc": "A Wedgwood-ware mortar and pestle (#805; refs experiments/prop_lab/refs/doctor/): the druggist's prescription mortar, a quart, 18 cm across, of hard unglazed white stoneware on a foot with a pouring lip, its bowl greyed by what's been ground in it; the pestle's head the same stoneware on a turned hardwood handle, leaning in it. A prop that shatters (GlassProp): stoneware ~1 cm thick, so it takes a fall off the counter (6 m/s) and a blast past 150 kPa, but a ball breaks it; the pestle comes through whole. ~2.2 kg. Baked the gun way (tools/blender/props/doctor_d2.py). Written by tools/props/doctor.py.",
        "id": "mortar", "kind": "shatters", "fixture": True, "in_game": False,
        "model": "glb:mortar", "looks": {"Mortar": "pbr:mortar", "Pestle": "pbr:mortar", "PestleHandle": "pbr:mortar"},
        "size": r([m["radius"] * 2, m["height"], m["radius"] * 2]),
        "mass": 2.2, "wall": 0.012, "glass": ["Mortar"], "whole": [["Pestle", "PestleHandle"]], "shards": 10, "piece_mass": 0.25,
        "breaks_at": 6.0, "shatters_kpa": 150, "heat_seconds": 1e9, "cut_area": 0.02,
    }


# --- The druggist's scales -------------------------------------------------------------------------
# A druggist's prescription balance in its case (refs scales_cased_balance_1860_1880_wellcome.jpg, a
# balance of 1860-80: a glazed wooden case on a base with a drawer, its brass pillar in the middle, the
# beam on a knife edge, two small brass pans hung low on stirrups): an oak base with the drawer for the
# weights (brass knob), four corner posts, glass on its sides, front and top in an oak frame; inside, a
# turned brass pillar, the beam with its pointer down to a scale, the pans. Its front (the drawer) toward
# +z. The brass members' boxes are the metal's own section (as the cot's iron), drawn full size from
# glb:scales; the panes are glass members (a ball breaks them, as a window's).
SCALES = {"base": (0.46, 0.075, 0.25), "drawer": (0.30, 0.042), "case_h": 0.38, "post": 0.022, "pane": 0.004,
          "pillar": (0.012, 0.31), "beam": (0.24, 0.008, 0.006), "pan": {"radius": 0.045, "y": 0.105, "wire": 0.004},
          "beam_y": 0.385}


def scales():
    c = SCALES
    bx, by, bz = c["base"]
    ms = [member("base", "post", [bx, by, bz], [0, by * 0.5, 0], look=OAK_TOP)]
    dw, dh = c["drawer"]
    d = member("drawer", "trim", [dw, dh, 0.012], [0, by * 0.5, bz * 0.5 + 0.006], look=OAK_FRONT)
    d["dress"] = [{"look": "pbr:scales", "draw": mesh("scales", "Knob")}]
    ms.append(d)
    # The case: corner posts on the base, the top's rails on them, glass between.
    ch, ps, pn = c["case_h"], c["post"], c["pane"]
    cx, cz = bx * 0.5 - 0.015 - ps * 0.5, bz * 0.5 - 0.015 - ps * 0.5
    top_y = by + ch
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("post%d" % i, "stud", [ps, ch - ps, ps], [sx * cx, by + (ch - ps) * 0.5, sz * cz], look=OAK))
    for s_, name in ((-1, "b"), (1, "f")):
        ms.append(member("rail_" + name, "cripple", [cx * 2 + ps, ps, ps], [0, top_y - ps * 0.5, s_ * cz], look=OAK))
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("rail_" + name, "cripple", [ps, ps, cz * 2 - ps], [s_ * cx, top_y - ps * 0.5, 0], look=OAK))
    glass = "glass:clear"
    ph = ch - ps
    for s_, name in ((-1, "back"), (1, "front")):
        ms.append(member("pane_" + name, "glass", [cx * 2 - ps, ph, pn], [0, by + ph * 0.5, s_ * cz], wood="glass", look=glass))
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("pane_" + name, "glass", [pn, ph, cz * 2 - ps], [s_ * cx, by + ph * 0.5, 0], wood="glass", look=glass))
    ms.append(member("pane_top", "glass", [cx * 2 - ps, pn, cz * 2 - ps], [0, top_y - ps * 0.5, 0], wood="glass", look=glass))
    pw, ph2 = c["pillar"]
    ms.append(member("pillar", "stud", [pw, ph2, pw], [0, by + ph2 * 0.5, -0.02], wood="iron", look="pbr:scales", draw=mesh("scales", "Pillar")))
    lx, ly, lz = c["beam"]
    ms.append(member("beam", "cripple", [lx, ly, lz], [0, c["beam_y"], -0.02], wood="iron", look="pbr:scales", draw=mesh("scales", "Beam")))
    p = c["pan"]
    hang = c["beam_y"] - p["y"]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("pan_" + name, "trim", [p["wire"], hang, p["wire"]], [s_ * lx * 0.5, p["y"] + hang * 0.5, -0.02], wood="iron",
                         look="pbr:scales", draw=mesh("scales", "Pan" + name.upper())))
    return {
        "_doc": "A druggist's prescription balance in its case (#805; ref experiments/prop_lab/refs/doctor/scales_cased_balance_1860_1880_wellcome.jpg): an oak base with a drawer for the weights (its brass knob), a glazed oak case on it (corner posts, a top frame; glass sides, front and top: glass members, a ball breaks a pane as a window's), and inside a turned brass pillar, a brass beam on its knife edge with a pointer down to its scale, two small brass pans hung low on stirrups. Oak from the material library (a few years, the doctor's; the period's cases were mahogany or oak); the brass baked the gun way (tools/blender/props/doctor_d2.py; brass's members are the metal's own section, wood `iron` for its weight: brass is ~8.5 t/m3 to iron's 7.6). ~10 kg. Stands on the dispensary's counter; the pillar shot out drops the beam and pans. Written by tools/props/doctor.py.",
        "id": "scales", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- His desk: an oak roll-top --------------------------------------------------------------------
# A roll-top desk of the 1880s (the patent roll-tops of Cutler and others: the room's spec gives him
# one): two pedestals of four drawers either side of the knee hole, a writing bed across them, and
# over its back the roll-top's case: S-curved sides (library boards cut to the curve), a back, a top,
# the tambour rolled up out of sight under its top, pigeonholes over a row of small drawers inside.
# Its front (where he sits) toward +z; ~1.4 m wide, 0.8 deep, 1.2 high.
DESK = {"width": 1.40, "depth": 0.80, "bed": 0.76, "top": 1.20, "panel": 0.019, "board": 0.025,
        "pedestal": 0.40, "drawers": 4, "plinth": 0.07, "case_depth": 0.44, "pigeon_depth": 0.26,
        "pigeon_y": (0.89, 1.15), "pigeons": 8, "small_drawers": 6}


def desk_curve(n=10):
    """The roll-top's side, (z, y) bottom front round to the top: a short rise, then a quarter ellipse
    back to the top's front edge (the S of the patent roll-tops, its tambour running in a groove)."""
    d = DESK
    zf = d["depth"] * 0.5 - 0.035
    zt = d["depth"] * 0.5 - d["case_depth"] - 0.0
    y0, y1 = d["bed"], d["top"] - d["board"]
    rise = 0.03
    pts = [(zf, y0), (zf, y0 + rise)]
    for k in range(1, n + 1):
        t = math.pi * 0.5 * k / n
        pts.append((zt + (zf - zt) * math.cos(t), y0 + rise + (y1 - y0 - rise) * math.sin(t)))
    return pts


def desk_drawers():
    """The pedestals' drawer fronts: [(id, (w, h), (x, y, z))]."""
    d = DESK
    out = []
    pw = d["pedestal"]
    h_all = d["bed"] - d["board"] - d["plinth"]
    gap = 0.006
    dh = (h_all - gap * (d["drawers"] + 1)) / d["drawers"]
    zf = d["depth"] * 0.5 - 0.01
    for s_, name in ((-1, "l"), (1, "r")):
        cx = s_ * (d["width"] * 0.5 - pw * 0.5)
        for k in range(d["drawers"]):
            y = d["plinth"] + gap + dh * 0.5 + k * (dh + gap)
            out.append(("drawer_%s%d" % (name, k), (pw - d["panel"] * 2 - gap * 2, dh), (cx, y, zf)))
    # The knee hole's shallow drawer under the bed.
    kw = d["width"] - pw * 2 - gap * 2
    out.append(("drawer_middle", (kw, 0.075), (0.0, d["bed"] - d["board"] - 0.0375 - 0.004, zf)))
    return out


def desk_small_drawers():
    """The small drawers inside the case, under the pigeonholes: [(id, (w, h), (x, y, z))]."""
    d = DESK
    inner = d["width"] - d["panel"] * 2
    n = d["small_drawers"]
    gap = 0.005
    w = (inner - gap * (n + 1)) / n
    y0 = d["bed"]
    h = d["pigeon_y"][0] - y0 - 0.016 - gap * 2
    z = -d["depth"] * 0.5 + d["panel"] + d["pigeon_depth"] + 0.006
    return [("small_%d" % k, (w, h), (-inner * 0.5 + gap + w * 0.5 + k * (w + gap), y0 + gap + h * 0.5, z)) for k in range(n)]


def roll_top_desk():
    d = DESK
    W, D = d["width"], d["depth"]
    pw, t = d["pedestal"], d["panel"]
    under = d["bed"] - d["board"]
    ms = []
    zb = -D * 0.5
    # The pedestals: two sides, a back, a plinth front, the drawer fronts with brass pulls.
    for s_, name in ((-1, "l"), (1, "r")):
        cx = s_ * (W * 0.5 - pw * 0.5)
        for k, sx in enumerate((-1, 1)):
            x = cx + sx * (pw * 0.5 - t * 0.5)
            ms.append(member("ped_%s_side%d" % (name, k), "post", [t, under, D - 0.02], [x, under * 0.5, -0.01], look=OAK))
        ms.append(member("ped_%s_back" % name, "furniture_frame", [pw - t * 2, under - 0.02, t], [cx, under * 0.5 + 0.01, zb + t * 0.5], look=OAK))
        ms.append(member("ped_%s_plinth" % name, "furniture_frame", [pw - t * 2, d["plinth"], t], [cx, d["plinth"] * 0.5, D * 0.5 - 0.02 - t * 0.5], look=OAK))
    for did, (w, h), (x, y, z) in desk_drawers():
        m = member(did, "trim", [w, h, 0.02], [x, y, z], look=OAK_FRONT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Pull_" + did)}]
        ms.append(m)
    # The writing bed, its boards front to back, worn where his arms rest.
    nb = 3
    bw = D / nb
    for k in range(nb):
        bed = member("bed%d" % k, "furniture_top", [W, d["board"], bw], [0, d["bed"] - d["board"] * 0.5, -D * 0.5 + bw * (k + 0.5)], look=OAK_TOP)
        if k == 1:
            # His blotter and inkstand on it (drawn on the bed: they go where it goes).
            bed["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", n)} for n in ("Blotter", "Inkstand", "Inkwells")]
        ms.append(bed)
    # The case over the bed's back: S-curved sides (library boards cut to the curve), the back, the top.
    curve = desk_curve()
    zs = [p[0] for p in curve]
    z0, z1 = zb, max(zs)
    y0, y1 = d["bed"], d["top"] - d["board"]
    cz, cy = (z0 + z1) * 0.5, (y0 + y1) * 0.5
    outline = [(z0 - cz, y0 - cy)] + [(z - cz, y - cy) for z, y in curve] + [(z0 - cz, y1 - cy)]
    outline = [(round(a, 4), round(b, 4)) for a, b in reversed(outline)]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("case_side_" + name, "trim", [t, y1 - y0, z1 - z0], [s_ * (W * 0.5 - t * 0.5), cy, cz], look=OAK,
                         draw={"shape": "cut", "outline": [list(p) for p in outline], "plane": "zy"}))
    ms.append(member("case_back", "trim", [W - t * 2, y1 - y0, t], [0, cy, zb + t * 0.5], look=OAK))
    top_d = d["case_depth"] + 0.02
    ms.append(member("case_top", "trim", [W, d["board"], top_d], [0, d["top"] - d["board"] * 0.5, zb + top_d * 0.5 - 0.005], look=OAK_TOP))
    # (The tambour is rolled up out of sight behind the case's front, under its top.)
    # Inside: the pigeonholes' shelf and partitions over a row of small drawers.
    inner = W - t * 2
    pd = d["pigeon_depth"]
    pz = zb + t + pd * 0.5
    py0, py1 = d["pigeon_y"]
    # Under the shelf, three upright boards carrying it, the small drawers between them.
    sh = 0.016  # (thicker than the support graph's contact reach, 12 mm: a thinner board stacked on its own kind isn't "on" it)
    lo = py0 - sh - d["bed"]
    for k, x in enumerate((-inner * 0.5 + 0.005, 0.0, inner * 0.5 - 0.005)):
        ms.append(member("drawer_case_%d" % k, "trim", [0.010, lo, pd], [x, d["bed"] + lo * 0.5, pz], look=OAK_FRONT))
    shelf = member("pigeon_shelf", "trim", [inner, sh, pd], [0, py0 - sh * 0.5, pz], look=OAK)
    # His papers in the pigeonholes: letters, bills, a ledger (drawn on the shelf; they burn with it).
    shelf["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Papers")}]
    ms.append(shelf)
    for k in range(d["pigeons"] + 1):
        x = -inner * 0.5 + 0.006 + (inner - 0.012) * k / d["pigeons"]
        if k in (0, d["pigeons"]):
            continue
        ms.append(member("pigeon_%d" % k, "trim", [0.010, py1 - py0, pd], [x, (py0 + py1) * 0.5, pz], look=OAK))
    ms.append(member("pigeon_top", "trim", [inner, sh, pd], [0, py1 + sh * 0.5, pz], look=OAK))
    for did, (w, h), (x, y, z) in desk_small_drawers():
        m = member(did, "trim", [w, h, 0.012], [x, y, z], look=OAK_FRONT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Pull_" + did)}]
        ms.append(m)
    return {
        "_doc": "His desk (#805; refs experiments/prop_lab/refs/doctor/): an oak roll-top of the 1880s (the doctor's spec gives him one), 1.4 m wide, 0.8 deep: two pedestals of four drawers either side of the knee hole (a shallow drawer over it), a writing bed of three boards across them, and on its back the roll-top's case: S-curved sides (library boards cut to the curve, PropKit.lib_cut_mesh), a back, a top, the tambour rolled up out of sight under its top, eight pigeonholes over a row of six small drawers. Brass pulls baked the gun way (tools/blender/props/doctor_d2.py). Oak from the material library (a few years: the bed and top worn where his arms go). ~85 kg. Its front, where he sits, toward +z. The room's good piece: it wants walnut once the library's `furniture_walnut` passes. A ball through a pedestal's side holes it and it stands. Written by tools/props/doctor.py.",
        "id": "roll_top_desk", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The dispensary's counter and shelves: the kit's own, in his painted pine ----------------------------
# The kit's counter and shelves (assets/props/kit/counter.json, shelves.json) `like`d in the material
# library's painted pine, the shelves with seven boards (a druggist's shelving runs to the ceiling, its
# boards a bottle's height apart: 0.35 m).
SHELVES = {"depth": 0.30, "height": 2.62, "length": 2.0, "boards": [0.12, 0.42, 0.72, 1.02, 1.32, 1.62, 1.92, 2.22, 2.52], "board": 0.025}


def dispensary_shelves():
    c = SHELVES
    L = c["length"]
    ms = []
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("upright_" + name, "post", [c["depth"], c["height"], 0.03], [0, c["height"] * 0.5, s_ * (L * 0.5 - 0.015)], look=PINE))
    for k, y in enumerate(c["boards"]):
        ms.append(member("shelf%d" % k, "furniture_top", [c["depth"], c["board"], L - 0.06], [0, y, 0], look=PINE_TOP))
    # A cornice over the front (round 2's critic: a plain bookcase): a deep board on the uprights.
    ms.append(member("cornice", "trim", [c["depth"] + 0.05, 0.09, L + 0.06], [0.025, c["height"] + 0.045, 0], look=PINE))
    # A back of boards behind them (the shelving's own: the bottles stand against it, not the wall's).
    ms.append(member("back", "furniture_frame", [0.012, c["height"] - 0.1, L - 0.06], [-c["depth"] * 0.5 + 0.006, c["height"] * 0.5, 0], look=PINE))
    return {
        "_doc": "The dispensary's shelving (#805): the kit's shelves (`like` shelves.json) in the doctor's painted pine from the material library (a few years, the boards' tops worn), 2.7 m high with nine boards 0.3 m apart (a druggist's shelving runs up the wall, its boards a bottle's height apart), a cornice and a boarded back. Fitted along its wall as the kit's shelves are (PropKit.spawn_fitted: length along Z, depth along X); what stands on a board (the bottles) comes down when it goes. Written by tools/props/doctor.py.",
        "id": "dispensary_shelves", "like": "shelves", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "look": PINE, "members": ms,
    }


# A druggist's counter of drawers (round 1's critic: the kit's counter here was "a blank box"): the
# period's dispensing counters carried banks of small drawers for roots and powders (the target panel's
# dispensary). The kit's counter's frame (front, two ends, the top overhanging) at 2.3 m, its front
# faced with two rows of drawers, each with a turned brass knob. Its front toward -z, as the counter's.
COUNTER = {"length": 2.3, "height": 0.92, "depth": 0.6, "panel": 0.03, "top": 0.04, "plinth": 0.08, "drawers": (8, 3)}


def counter_drawers():
    """The counter's drawer fronts: [(id, (w, h), (x, y, z))] on its front (-z)."""
    c = COUNTER
    cols, rows = c["drawers"]
    gap = 0.006
    inner = c["length"] - c["panel"] * 2
    h_all = c["height"] - c["top"] - c["plinth"]
    w = (inner - gap * (cols + 1)) / cols
    h = (h_all - gap * (rows + 1)) / rows
    z = -c["depth"] * 0.5 + 0.075 - c["panel"] - 0.009
    return [("drawer_%d_%d" % (i, k), (w, h), (-inner * 0.5 + gap + w * 0.5 + i * (w + gap), c["plinth"] + gap + h * 0.5 + k * (h + gap), z))
            for i in range(cols) for k in range(rows)]


def dispensary_counter():
    c = COUNTER
    L, H, D, t = c["length"], c["height"], c["depth"], c["panel"]
    under = H - c["top"]
    zf = -D * 0.5 + 0.075  # the front's inside face sits under the top's overhang
    ms = [member("front", "post", [L, under, t], [0, under * 0.5, zf - t * 0.5], look=PINE)]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("end_" + name, "post", [t, under, D - 0.075 - t], [s_ * (L * 0.5 - t * 0.5), under * 0.5, (zf + D * 0.5) * 0.5], look=PINE))
    ms.append(member("plinth", "furniture_frame", [L - t * 2, c["plinth"], 0.02], [0, c["plinth"] * 0.5, zf - t - 0.01], look=PINE))
    for did, (w, h), (x, y, z) in counter_drawers():
        m = member(did, "trim", [w, h, 0.018], [x, y, z], look=PINE_FRONT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Knob_" + did)}]
        ms.append(m)
    ms.append(member("top", "furniture_top", [L, c["top"], D], [0, H - c["top"] * 0.5, 0], look=PINE_TOP))
    return {
        "_doc": "The dispensary's counter (#805): the kit's counter (`like` counter.json: a front and two ends under a top overhanging the front) at 2.3 m, its front faced with three rows of eight small drawers for roots and powders, each with a turned brass knob (the period's dispensing counters, the target panel's dispensary; round 1's critic called the plain one a blank box). In the doctor's painted pine from the material library (a few years, the top worn where he works); the knobs baked the gun way (glb:desk_brass). Along the west wall at his make_up place, the scales and mortar on it. Its front (the drawers) toward -z. Written by tools/props/doctor.py.",
        "id": "dispensary_counter", "like": "counter", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "look": PINE, "members": ms,
    }


# --- His chair: a bentwood --------------------------------------------------------------------------
# Thonet's No. 14 (refs chair_thonet_no14_mak.jpg: designed 1859, sold by the million from the 1860s, the
# common office and cafe chair of the 1880s): steam-bent beech stained walnut, the back legs running up
# into the hoop of the back with a smaller loop inside it, a round caned seat on a bent ring, the four
# legs splayed and braced by a ring under the seat. Its members' boxes are the bent wood's own section
# (a 3 cm rod), drawn full size from glb:bentwood_chair. Facing +Z (you sit looking +Z), as the kit's chair.
BENTWOOD = {"seat_y": 0.46, "seat_r": 0.205, "back_top": 0.89, "leg": 0.03, "ring_y": 0.21}


def bentwood_chair():
    c = BENTWOOD
    sy, lg = c["seat_y"], c["leg"]
    ms = []
    look = "pbr:bentwood_chair"
    for name, x, z, part in (("leg_front_l", -0.17, 0.13, "LegFL"), ("leg_front_r", 0.17, 0.13, "LegFR"),
                             ("leg_back_l", -0.15, -0.16, "LegBL"), ("leg_back_r", 0.15, -0.16, "LegBR")):
        ms.append(member(name, "post", [lg, sy - 0.01, lg], [x, (sy - 0.01) * 0.5, z], look=look, draw=mesh("bentwood_chair", part)))
    ms.append(member("leg_ring", "furniture_frame", [0.34, 0.01, 0.30], [0, c["ring_y"], -0.015], look=look, draw=mesh("bentwood_chair", "LegRing")))
    seat = member("seat", "furniture_top", [c["seat_r"] * 2, 0.012, c["seat_r"] * 2], [0, sy, 0], look=look, draw=mesh("bentwood_chair", "Seat"))
    seat["dress"] = [{"look": look, "draw": mesh("bentwood_chair", "SeatRing")}]
    ms.append(seat)
    ms.append(member("back", "trim", [0.30, c["back_top"] - sy - 0.01, 0.014], [0, (c["back_top"] + sy + 0.01) * 0.5, -0.19], look=look,
                     draw=mesh("bentwood_chair", "Back")))
    return {
        "_doc": "His chair (#805): a bentwood, Thonet's No. 14 (ref experiments/prop_lab/refs/doctor/chair_thonet_no14_mak.jpg: designed 1859, the common office and cafe chair of the 1870s-80s): steam-bent beech stained walnut, the back legs running up into the hoop of the back with a smaller loop inside it, a round caned seat on its bent ring, four splayed legs braced by a ring under the seat. The kit's spindle-back `chair` was tried beside his desk first (round 1's critic: square posts and slats, a Mission chair of 1905), so this is its own. Its members' boxes are the bent rods' section (wood oak for the beech's weight: ~3 kg); drawn and baked the gun way from glb:bentwood_chair (tools/blender/props/doctor_d2.py: a bent beech's stain, the cane woven). A man sits on it as on the kit's chair (`seat`). Facing +Z. Written by tools/props/doctor.py.",
        "id": "bentwood_chair", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "seat": {"member": "seat", "at": [0.0, sy + 0.01, 0.0], "share": 0.75, "hold": 0.05, "sway": 0.03},
        "members": ms,
    }


# === Batch D3: his books, the hall's pegs, the sick room's pot and blankets (#819) =================

# --- His books --------------------------------------------------------------------------------------
# A country doctor's shelf in 1882 (refs experiments/prop_lab/refs/doctor/ README, "D3"): the standard
# American texts of the 1860s-70s, most in "law sheep" (medical and law books' usual trade binding
# through the 1880s: tan sheepskin, a red and a black leather label lettered in gilt), some in the
# publishers' dark cloth stamped in gilt, a few in calf. Each: (title lines, author, binding,
# height, thickness, depth) in metres (an octavo ~24 x 16 cm, a royal octavo ~26 x 18, the army's
# quarto 30 x 24). One Blender model (glb:medical_books), every face printed on its own sheet
# (tools/blender/props/doctor_d3.py), a book a member: it burns (wood `paper`), a ball goes through.
BOOKS = [
    (["GRAY'S", "ANATOMY"], "GRAY", "sheep", 0.262, 0.062, 0.180),
    (["PRACTICE", "OF", "MEDICINE"], "FLINT", "sheep", 0.245, 0.060, 0.165),
    (["SYSTEM", "OF", "SURGERY", "VOL. I"], "GROSS", "sheep", 0.255, 0.066, 0.175),
    (["SYSTEM", "OF", "SURGERY", "VOL. II"], "GROSS", "sheep", 0.255, 0.066, 0.175),
    (["UNITED STATES", "DISPENSATORY"], "WOOD & BACHE", "sheep", 0.250, 0.078, 0.170),
    (["DISEASES", "OF", "WOMEN"], "THOMAS", "cloth_green", 0.238, 0.048, 0.160),
    (["HUMAN", "PHYSIOLOGY"], "DALTON", "sheep", 0.240, 0.052, 0.162),
    (["FRACTURES", "AND", "DISLOCATIONS"], "HAMILTON", "cloth_brown", 0.240, 0.055, 0.162),
    (["MEDICAL", "DICTIONARY"], "DUNGLISON", "sheep", 0.250, 0.072, 0.170),
    (["MIDWIFERY"], "PLAYFAIR", "cloth_plum", 0.232, 0.045, 0.155),
    (["THERAPEUTICS", "& MATERIA", "MEDICA"], "H. C. WOOD", "sheep", 0.240, 0.050, 0.160),
    (["GUNSHOT", "WOUNDS"], "LONGMORE", "cloth_black", 0.225, 0.040, 0.150),
    (["DISEASES", "OF", "CHILDREN"], "MEIGS & PEPPER", "sheep", 0.242, 0.060, 0.162),
    (["OPERATIVE", "SURGERY"], "S. SMITH", "cloth_green", 0.236, 0.050, 0.158),
    (["MEDICAL", "JURISPRUDENCE"], "TAYLOR", "calf", 0.235, 0.054, 0.156),
    (["NATIONAL", "DISPENSATORY"], "STILLE & MAISCH", "sheep", 0.252, 0.080, 0.172),
    (["MANUAL", "OF", "CHEMISTRY"], "FOWNES", "cloth_brown", 0.205, 0.046, 0.135),
    (["MEDICAL &", "SURGICAL", "HISTORY", "OF THE WAR"], "SURG. GENL.", "cloth_green", 0.300, 0.070, 0.240),
    (["PATHOLOGICAL", "ANATOMY"], "DELAFIELD", "calf", 0.240, 0.044, 0.160),
    (["TRANSACTIONS", "AM. MED.", "ASSOC.", "1879"], "", "cloth_black", 0.232, 0.042, 0.155),
    (["PHYSICIAN'S", "VISITING", "LIST"], "", "calf", 0.170, 0.022, 0.105),
    (["THE", "PHYSICIAN", "HIMSELF"], "CATHELL", "cloth_plum", 0.195, 0.030, 0.130),
    # A run of his journal bound by the year (the American Journal of the Medical Sciences, Philadelphia,
    # quarterly since 1827: a country doctor's one subscription), two spines turn about along the run.
    (["AMERICAN", "JOURNAL", "MEDICAL", "SCIENCES"], "1879", "calf", 0.236, 0.047, 0.158),
    (["AMERICAN", "JOURNAL", "MEDICAL", "SCIENCES"], "1881", "calf", 0.236, 0.049, 0.158),
]
# Which book is where: two shelf rows standing spine out (+z), and a pile lying (bottom up).
BOOK_ROWS = {"book_row_a": [0, 2, 3, 1, 8, 6, 5, 12, 11], "book_row_b": [4, 15, 10, 14, 7, 13, 18, 9, 19, 16],
             "book_row_c": [22, 23, 22, 23, 23, 22, 23, 22, 22, 23, 22]}
BOOK_STACK = [17, 21, 20]
BOOK_GAP = 0.0015


def book_places(kit):
    """[(book, (size x, y, z), (at x, y, z), lying)] of a book kit, in its space: a row stands on its
    shelf spine out (+z), the spines in a line 1 cm proud of nothing (a reader's shelf: not flush),
    its middle at x = 0; the pile lies, each on the one under it, spines to +z."""
    out = []
    if kit == "book_stack":
        y = 0.0
        for n, k in enumerate(BOOK_STACK):
            _t, _a, _b, h, w, d = BOOKS[k]
            out.append((k, (h, w, d), ((0.012, -0.008, 0.0)[n % 3], y + w * 0.5, (0.0, 0.01, -0.006)[n % 3]), True))
            y += w
        return out
    ks = BOOK_ROWS[kit]
    total = sum(BOOKS[k][4] for k in ks) + BOOK_GAP * (len(ks) - 1)
    x = -total * 0.5
    front = 0.09
    for n, k in enumerate(ks):
        _t, _a, _b, h, w, d = BOOKS[k]
        # (pushed in by hand: a few millimetres each way)
        z = front - d * 0.5 - (0.0, 0.006, 0.002, 0.009, 0.004)[n % 5]
        out.append((k, (w, h, d), (x + w * 0.5, h * 0.5, z), False))
        x += w + BOOK_GAP
    return out


def book_kit(kit):
    ms = []
    places = book_places(kit)
    kinds = ["post", "furniture_top", "trim"]
    for n, (k, size, at, lying) in enumerate(places):
        # (a run's volumes are the same two books over again: named by their place)
        mid, part = ("vol%d" % n, "Vol%d" % n) if kit == "book_row_c" else ("book%d" % k, "Book%d" % k)
        ms.append(member(mid, kinds[min(n, 2)] if lying else "post", size, at, wood="paper", look="pbr:medical_books",
                         draw=mesh("medical_books", part)))
    titles = "; ".join(dict.fromkeys("%s (%s)" % (" ".join(BOOKS[k][0]).title(), BOOKS[k][1].title() or "a year's volume") for k, *_ in places))
    what = ("a pile of three lying on a table or a desk's top, the army's big quarto under his visiting list"
            if kit == "book_stack" else "a shelf's row standing spine out (+z), %d cm of them" % round(sum(p[1][0] for p in places) * 100))
    return {
        "_doc": "His medical books (#819; refs experiments/prop_lab/refs/doctor/): %s. The standard American texts a country doctor of 1882 owned: %s. Most in law sheep (tan sheepskin with a red and a black label lettered in gilt, the trade binding of medical books into the 1880s), some in publishers' cloth, a few in calf. Each book a member (wood `paper`: ~1.5 kg an octavo): it burns, a ball goes through it, the row comes down with its shelf. Drawn from glb:medical_books, every face printed on its own sheet (tools/blender/props/doctor_d3.py: Pillow, as the bottles' labels). Written by tools/props/doctor.py." % (what, titles),
        "id": kit, "kind": "members", "fixture": True, "in_game": False, "wood": "paper", "look": "pbr:medical_books",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


def book_row_a():
    return book_kit("book_row_a")


def book_row_b():
    return book_kit("book_row_b")


def book_row_c():
    return book_kit("book_row_c")


def book_stack():
    return book_kit("book_stack")


# --- His bookcase -----------------------------------------------------------------------------------
# A plain open oak bookcase, chest high (the country office's: Cathell 1882 wants the doctor's
# books "in sight"): two sides, four shelves, a boarded back, a top overhanging, a plinth. The shelves'
# tops (for what stands on them) in `shelf_tops()`. Its front toward +z.
BOOKCASE = {"width": 0.64, "depth": 0.27, "height": 1.47, "side": 0.022, "board": 0.02, "top": 0.024,
            "shelves": [0.09, 0.44, 0.76, 1.07], "plinth": 0.08}


def shelf_tops():
    return [round(y + BOOKCASE["board"] * 0.5, 4) for y in BOOKCASE["shelves"]]


def bookcase():
    c = BOOKCASE
    W, D, H, t = c["width"], c["depth"], c["height"], c["side"]
    under = H - c["top"]
    ms = []
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("side_" + name, "post", [t, under, D], [s_ * (W * 0.5 - t * 0.5), under * 0.5, 0], look=OAK))
    for k, y in enumerate(c["shelves"]):
        ms.append(member("shelf%d" % k, "furniture_top", [W - t * 2, c["board"], D - 0.014], [0, y, 0.007], look=OAK_TOP))
    ms.append(member("back", "furniture_frame", [W - t * 2, under - 0.04, 0.012], [0, under * 0.5 + 0.02, -D * 0.5 + 0.006], look=OAK))
    ms.append(member("plinth", "furniture_frame", [W - t * 2, c["plinth"], 0.018], [0, c["plinth"] * 0.5, D * 0.5 - 0.02], look=OAK))
    # A frieze under the top and a cornice round it, a base moulding on the plinth (round 1's critic: "a
    # modern flat-pack shelf: no cornice, no moulding").
    ms.append(member("frieze", "furniture_frame", [W - t * 2, 0.075, 0.018], [0, under - 0.0375, D * 0.5 - 0.009], look=OAK))
    ms.append(member("cornice", "trim", [W + 0.05, 0.03, D + 0.03], [0, under - 0.015, 0.01], look=OAK))
    ms.append(member("base_mould", "trim", [W + 0.03, 0.03, 0.02], [0, c["plinth"] + 0.015, D * 0.5 + 0.004], look=OAK))
    ms.append(member("top", "trim", [W + 0.09, c["top"], D + 0.05], [0, H - c["top"] * 0.5, 0.012], look=OAK_TOP))
    return {
        "_doc": "His bookcase (#819): a plain open oak bookcase, chest high (1.47 m), 0.64 m wide: two sides, four shelves (the lowest the tallest, for the quartos), a boarded back, a frieze and cornice under an overhanging top, a moulded plinth. Oak from the material library (a few years: the shelves' and top's faces worn). ~28 kg empty. His books stand on it as their own props (book_row_a, book_row_b, book_row_c; shelf tops at %s m): a shelf shot out or burnt, its row comes down. Its front toward +z. Written by tools/props/doctor.py." % ", ".join("%.2f" % y for y in shelf_tops()),
        "id": "bookcase", "kind": "members", "fixture": True, "in_game": False, "wood": "oak",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The hall's pegs, his coat and hat --------------------------------------------------------------
# A peg rail (the spec's hall: "his bag and coat on pegs"): a painted pine board nailed to the wall at
# 1.65 m with five turned pegs, his black frock coat hung by its loop on one and his hat on another.
# The wall's face at z = 0, the pegs toward +z; the origin at the rail's middle. The coat's member is
# what hangs under its own peg (19 cm: the drawn coat's shoulders lie over the pegs either side, and
# don't hang on them).
PEGS = {"length": 0.98, "height": 0.115, "thick": 0.022, "pegs": 5, "peg_len": 0.09, "peg_r": 0.0115,
        "coat": {"peg": 1, "size": (0.19, 1.04, 0.15)}, "hat": {"peg": 3, "brim": 0.165, "crown": 0.092, "crown_h": 0.115}}


def peg_xs():
    p = PEGS
    step = (p["length"] - 0.16) / (p["pegs"] - 1)
    return [-(p["length"] - 0.16) * 0.5 + step * k for k in range(p["pegs"])]


def coat_pegs():
    p = PEGS
    t = p["thick"]
    ms = [member("rail", "post", [p["length"], p["height"], t], [0, 0, t * 0.5], look=PINE)]
    xs = peg_xs()
    look = "pbr:coat_pegs"
    for k, x in enumerate(xs):
        ms.append(member("peg%d" % k, "furniture_frame", [p["peg_r"] * 2, p["peg_r"] * 2, p["peg_len"]], [x, 0, t + p["peg_len"] * 0.5],
                         wood="oak", look=look, draw=mesh("coat_pegs", "Peg%d" % k)))
    cw, ch, cd = p["coat"]["size"]
    cx = xs[p["coat"]["peg"]]
    coat = member("coat", "trim", [cw, ch, cd], [cx, 0.012 - ch * 0.5, t + 0.03 + cd * 0.5], wood="canvas", look=look, draw=mesh("coat_pegs", "Coat"))
    coat["dress"] = [{"look": look, "draw": mesh("coat_pegs", "CoatButtons")}]
    ms.append(coat)
    h = p["hat"]
    hx = xs[h["peg"]]
    hat = member("hat", "trim", [h["brim"] * 2, h["brim"] * 2, 0.11], [hx, -0.045, t + 0.03 + 0.055], wood="canvas", look=look, draw=mesh("coat_pegs", "Hat"))
    hat["dress"] = [{"look": look, "draw": mesh("coat_pegs", "HatBand")}]
    ms.append(hat)
    return {
        "_doc": "The hall's pegs (#819; the doctor's spec: 'his bag and coat on pegs'; refs experiments/prop_lab/refs/doctor/): a painted pine rail 0.98 m long nailed to the wall through two nails, five turned hardwood pegs in it, his black broadcloth frock coat hung by its loop on the second and his black felt hat on the fourth. Hung (KitProp `hangs`): it holds while a nail's still in the wall and falls when its board goes; a peg shot off drops what's on it; the coat and hat burn (wood `canvas`). The rail from the material library (a few years); the pegs, coat and hat baked the gun way (tools/blender/props/doctor_d3.py). The wall's face at z = 0, the pegs toward +z, the rail's middle the origin (hang it at ~1.65 m). Written by tools/props/doctor.py.",
        "id": "coat_pegs", "kind": "members", "fixture": True, "in_game": False, "wood": "weathered_pine", "drawn_bounds": True,
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "hangs": {"nails": [r([-p["length"] * 0.5 + 0.06, 0.0, 0.004]), r([p["length"] * 0.5 - 0.06, 0.0, 0.004])]},
        "members": ms,
    }


# --- The chamber pot --------------------------------------------------------------------------------
# White ironstone, as the wash set (the same potteries sold them as one toilet set): a round pot
# 23 cm across with a rolled rim and a loop handle, its lid with a knob, a cobalt line under the rim.
# Its axis at the origin, the handle toward -x.
CHAMBER = {"radius": 0.115, "height": 0.135, "foot": 0.066, "lid_h": 0.04, "knob": 0.03}


def chamber_pot():
    c = CHAMBER
    return {
        "_doc": "A white ironstone chamber pot with its lid (#819; refs experiments/prop_lab/refs/doctor/): 23 cm across, a rolled rim, a loop handle, a cobalt line under the rim as the wash set's (the potteries sold basin, pitcher and pot as one toilet set), under a cot in the sick room. A prop that shatters (GlassProp), as the basin: ~5 mm of fired clay, it breaks kicked hard or dropped (2.5 m/s) and at ~25 kPa; a ball breaks it. Empty. Baked the gun way (tools/blender/props/doctor_d3.py). Written by tools/props/doctor.py.",
        "id": "chamber_pot", "kind": "shatters", "fixture": True, "in_game": False,
        "model": "glb:chamber_pot", "looks": {"Pot": "pbr:chamber_pot", "PotBand": "pbr:chamber_pot", "Lid": "pbr:chamber_pot"},
        "size": r([c["radius"] * 2 + 0.05, c["height"] + c["lid_h"] + c["knob"], c["radius"] * 2]),
        "mass": 1.9, "wall": 0.005, "glass": ["Pot", "PotBand", "Lid"], "whole": [], "shards": 10, "piece_mass": 0.2,
        "breaks_at": 2.5, "shatters_kpa": 25, "heat_seconds": 1e9, "cut_area": 0.03,
    }


# --- His bag ------------------------------------------------------------------------------------------
# By Rodin (Sean's "A" on #823): tools/blender/props/doctors_bag_rodin.py turns the Studio's model into
# glb:doctors_bag (parts `body`, `handle`) with its own paint (look model:doctors_bag); the boxes below
# are the ones that script prints.
BAG = {"body": ([0.0, 0.1144, 0.0], [0.3998, 0.2296, 0.2]), "handle": ([0.0, 0.2532, 0.0], [0.1245, 0.0597, 0.0195])}


def doctors_bag():
    look = "model:doctors_bag"
    (bc, bs), (hc, hs) = BAG["body"], BAG["handle"]
    ms = [member("body", "post", bs, bc, wood="hay", look=look, draw=mesh("doctors_bag", "body")),
          member("handle", "trim", hs, hc, wood="leather", look=look, draw=mesh("doctors_bag", "handle"))]
    return {
        "_doc": "His bag (#819; Sean's A on #823; ref experiments/prop_lab/refs/doctor/bag_doctors_leather_1890_1930_wellcome.jpg): an 1880s physician's Gladstone bag, 40 cm long, dark brown cross-grained cowhide scuffed pale at its corners, a hinged brass frame with a lock plate, a strap and buckle near each end, a rolled leather handle. Made by Rodin from three realistic pictures (the Character Studio's prop-pictures and prop3d, card cards/props/doctors_bag.yaml; tools/blender/props/doctors_bag_rodin.py: cut to 5,000 triangles, its own painted texture, look model:doctors_bag). Two members: the body (a leather shell with his instruments in it, not solid: wood `hay` gives the box the bag's ~3 kg; it burns; a ball goes through) and the handle on it. Stands on the hall's floor under his coat. Its instruments aren't props yet: nothing comes out of it. Written by tools/props/doctor.py.",
        "id": "doctors_bag", "kind": "members", "fixture": True, "in_game": False, "wood": "leather", "look": look,
        "drawn_bounds": True, "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- Folded blankets --------------------------------------------------------------------------------
# Spare blankets folded (the wards' issue: grey wool with a dark band, a white one with blue bands,
# a brown one): each folded in four along its length and laid in a pile, the folds' bights to +x.
# A blanket a member (it burns; pulled from under, the ones over it come down).
BLANKET = {"size": (0.48, 0.105, 0.37), "layers": 3, "finishes": ["wool_fold", "wool_white", "wool_brown"]}


def _blankets(kit, n, what):
    bx, by, bz = BLANKET["size"]
    kinds = ["post", "furniture_top", "trim"]
    ms = [member("blanket%d" % k, kinds[k], [bx, by, bz], [0, by * (k + 0.5), 0], wood="canvas", look="pbr:folded_blankets",
                 draw=mesh("folded_blankets", "Blanket%d" % k)) for k in range(n)]
    return {
        "_doc": "%s (#819; refs experiments/prop_lab/refs/doctor/): wool blankets folded in three and laid flat, 48 x 37 cm, the folds' bights to +x, the wards' issue of the 1860s-80s (grey with a dark band at each end; white with blue bands; brown). A blanket a member (wood `canvas`): it burns, and the pile comes down with what it lies on. A member drawn soft, not cloth (ClothProp): nobody unfolds one yet. Baked the gun way (tools/blender/props/doctor_d3.py). Written by tools/props/doctor.py." % what,
        "id": kit, "kind": "members", "fixture": True, "in_game": False, "wood": "canvas", "look": "pbr:folded_blankets",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


def folded_blankets():
    return _blankets("folded_blankets", 3, "A pile of three folded blankets")


def folded_blanket():
    return _blankets("folded_blanket", 1, "A folded grey blanket")


BATCH_D3 = [book_row_a, book_row_b, book_row_c, book_stack, bookcase, coat_pegs, chamber_pot, folded_blankets, folded_blanket, doctors_bag]


BATCH_D2 = [medicine_bottle, medicine_bottle_round, poison_bottle, drug_jar, mortar, scales, roll_top_desk, dispensary_shelves,
            dispensary_counter, bentwood_chair]


BATCH_D1 = [examining_table, iron_cot, washstand, wash_basin, wash_pitcher, instrument_tray, reflector_lamp, hand_towel]


def main():
    batches = {"D1": BATCH_D1, "D2": BATCH_D2, "D3": BATCH_D3}
    which = [a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--batch=")] or ["D1", "D2", "D3"]
    for make in [f for b in which for f in batches[b]]:
        d = make()
        d["factory"] = "tools/props/doctor.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
