"""The doctor's office props (docs/briefs/prop-factory.md, "The doctor's office batch", #788): the
kit files of an 1882 country doctor's furniture, written from the numbers here, so a change is one
number and a re-run. The Blender half (tools/blender/props/doctor_*.py) reads the same numbers.

    python3 tools/props/doctor.py [--batch=D2]   # writes assets/props/kit/<id>.json for batches D1 and D2

Woods from the material library (`lib:<entry>/<age>`, #721: only ages the materials judge passed:
F2 `fine_walnut_tg` new and a few years, the doctor's own floor's), metal and cloth baked the gun way
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

WALNUT = "lib:fine_walnut_tg/few"
WALNUT_TOP = "lib:fine_walnut_tg/few/top"


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
# A walnut table at the height a doctor works standing (29 in), 6 ft by 2 ft, three drawers in its
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
        ms.append(member("leg%d" % i, "post", [t["leg"], under, t["leg"]], [sx * lx, under * 0.5, sz * lz], look=WALNUT))
    inner_x = lx - hl
    inner_z = lz - hl
    ay = under - t["apron_h"] * 0.5
    for s in (-1, 1):
        ms.append(member("apron_long_%s" % ("b" if s < 0 else "f"), "furniture_frame", [inner_x * 2, t["apron_h"], t["apron_t"]],
                         [0, ay, s * (lz + hl - t["apron_t"] * 0.5)], look=WALNUT))
        ms.append(member("apron_end_%s" % ("foot" if s < 0 else "head"), "furniture_frame", [t["apron_t"], t["apron_h"], inner_z * 2],
                         [s * (lx + hl - t["apron_t"] * 0.5), ay, 0], look=WALNUT))
        sw, sh = t["stretcher"]
        ms.append(member("stretcher_%s" % ("b" if s < 0 else "f"), "furniture_frame", [inner_x * 2, sw, sh],
                         [0, t["stretcher_y"], s * lz], look=WALNUT))
    # The top: its boards along it, edge to edge (worn where he leans and works: the library's top).
    bw = W / t["boards"]
    for k in range(t["boards"]):
        ms.append(member("top%d" % k, "furniture_top", [L, t["board"], bw], [0, H - t["board"] * 0.5, -W * 0.5 + bw * (k + 0.5)], look=WALNUT_TOP))
    # The bottom: boards laid across from stretcher to stretcher, edge to edge between the legs.
    sw, sh = t["stretcher"]
    span = (lz + sh * 0.5) * 2
    sbw = inner_x * 2 / t["shelf_boards"]
    bottom_top = t["stretcher_y"] + sw * 0.5 + t["shelf_t"]
    for k in range(t["shelf_boards"]):
        ms.append(member("shelf%d" % k, "furniture_top", [sbw, t["shelf_t"], span],
                         [-inner_x + sbw * (k + 0.5), bottom_top - t["shelf_t"] * 0.5, 0], look=WALNUT))
    # On the doctor's side (+z) a row of drawers in the deep apron under the top (the period's tables
    # carry drawers: the 1880 Stohlmann catalogue's, the Remick museum's), each with its brass knob;
    # the legs and the low shelf open below, as the doctor's target sheet's table.
    for c, r_, (dw, dh), (x, y, zf) in table_drawers():
        if True:
            m = member("drawer_%d_%d" % (c, r_), "trim", [dw, dh, t["drawer_t"]], [x, y, zf], look=WALNUT)
            m["dress"] = [{"look": "pbr:examining_table", "draw": mesh("examining_table", "Knob_%d_%d" % (c, r_))}]
            ms.append(m)
    p = t["pad"]
    ms.append(member("pad", "trim", [p["length"], p["height"], p["width"]], [p["x"], H + p["height"] * 0.5, 0],
                     wood="hay", look="pbr:examining_table", draw=mesh("examining_table", "Pad")))
    h = t["head"]
    ms.append(member("head", "trim", [h["length"], h["high"], h["width"]], [h["x"], H + h["high"] * 0.5, 0],
                     wood="straw", look="pbr:examining_table", draw=mesh("examining_table", "HeadPad")))
    return {
        "_doc": "An 1880s country doctor's examining table (#788; refs experiments/prop_lab/refs/doctor/): a walnut table 6 ft by 2 ft at a standing doctor's working height (29 in), three drawers in its deep apron on his side (+z) with brass knobs (the 1880 Stohlmann catalogue's and the Remick museum's tables carry drawers), a shelf low down for the basin and dressings, a buttoned horsehair pad in brown leather along it and a raised head of the same at its +x end. Walnut from the material library (F2 a few years, the doctor's own floor: the top worn where he leans); the pads baked the gun way (tools/blender/props/doctor_d1.py). Heavy stock: a .45 ball through a 65 mm leg (the carve leaves ~0.4 of it) holes it and it stands (`splits_below` 0.3). ~55 kg. The patient lies on it: his weight on the pad (`seat`, all of it). Written by tools/props/doctor.py.",
        "id": "examining_table", "kind": "members", "fixture": True, "wood": "walnut",
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
# A plain walnut washstand: a top with a low splashback, a drawer in the front apron (its brass knob),
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
        ms.append(member("leg%d" % i, "post", [w["leg"], under, w["leg"]], [sx * lx, under * 0.5, sz * lz], look=WALNUT))
    ay = under - w["apron_h"] * 0.5
    for s in (-1, 1):
        a = member("apron_%s" % ("back" if s < 0 else "front"), "furniture_frame", [(lx - hl) * 2, w["apron_h"], w["apron_t"]],
                   [0, ay, s * (lz + hl - w["apron_t"] * 0.5)], look=WALNUT)
        if s > 0:
            a["dress"] = [{"look": "pbr:washset", "draw": mesh("washset", "Knob")}]
        ms.append(a)
        ms.append(member("apron_%s" % ("l" if s < 0 else "r"), "furniture_frame", [w["apron_t"], w["apron_h"], (lz - hl) * 2],
                         [s * (lx + hl - w["apron_t"] * 0.5), ay, 0], look=WALNUT))
        ms.append(member("stretcher_%s" % ("l" if s < 0 else "r"), "furniture_frame", [0.03, 0.03, (lz - hl) * 2],
                         [s * lx, w["shelf_y"], 0], look=WALNUT))
    # The top in two boards, the shelf in two boards across the side stretchers.
    for k in range(2):
        ms.append(member("top%d" % k, "furniture_top", [W, w["board"], D * 0.5], [0, H - w["board"] * 0.5, -D * 0.25 + D * 0.5 * k], look=WALNUT_TOP))
    # (between the legs front to back, from stretcher to stretcher across)
    sd = (lz - hl) * 2
    for k in range(2):
        ms.append(member("shelf%d" % k, "furniture_top", [lx * 2, 0.016, sd * 0.5], [0, w["shelf_y"] + 0.015 + 0.008, -sd * 0.25 + sd * 0.5 * k], look=WALNUT))
    sh, st = w["splash"]
    ms.append(member("splashback", "trim", [W, sh, st], [0, H + sh * 0.5, -D * 0.5 + st * 0.5], look=WALNUT))
    # A towel bar on two brackets off the +x legs (the hand towel, cloth, hangs over it).
    bx, by, bz = wash_towel_bar()
    for k, sz in enumerate((-1, 1)):
        ms.append(member("towel_bracket%d" % k, "cripple", [bx - (lx + hl), 0.03, 0.03], [(lx + hl + bx) * 0.5, by, sz * lz], look=WALNUT))
    ms.append(member("towel_bar", "trim", [0.022, 0.022, lz * 2 + 0.03], [bx, by + 0.026, 0], look=WALNUT))
    return {
        "_doc": "A plain walnut washstand (#788; refs experiments/prop_lab/refs/doctor/): a two-board top with a low splashback, a drawer in the front apron with its brass knob, a towel bar off its side (its towel the hand_towel kit file, cloth), a shelf low down; the wash basin and pitcher (white ironstone china, their own kit files) stand on it. Walnut from the material library (F2 a few years, as the examining table). ~22 kg. Written by tools/props/doctor.py.",
        "id": "washstand", "kind": "members", "fixture": True, "wood": "walnut",
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
# beam on a knife edge, two small brass pans hung low on stirrups): a walnut base with the drawer for the
# weights (brass knob), four corner posts, glass on its sides, front and top in a walnut frame; inside, a
# turned brass pillar, the beam with its pointer down to a scale, the pans. Its front (the drawer) toward
# +z. The brass members' boxes are the metal's own section (as the cot's iron), drawn full size from
# glb:scales; the panes are glass members (a ball breaks them, as a window's).
SCALES = {"base": (0.46, 0.075, 0.25), "drawer": (0.30, 0.042), "case_h": 0.38, "post": 0.022, "pane": 0.004,
          "pillar": (0.012, 0.31), "beam": (0.24, 0.008, 0.006), "pan": {"radius": 0.045, "y": 0.105, "wire": 0.004},
          "beam_y": 0.385}


def scales():
    c = SCALES
    bx, by, bz = c["base"]
    ms = [member("base", "post", [bx, by, bz], [0, by * 0.5, 0], look=WALNUT_TOP)]
    dw, dh = c["drawer"]
    d = member("drawer", "trim", [dw, dh, 0.012], [0, by * 0.5, bz * 0.5 + 0.006], look=WALNUT)
    d["dress"] = [{"look": "pbr:scales", "draw": mesh("scales", "Knob")}]
    ms.append(d)
    # The case: corner posts on the base, the top's rails on them, glass between.
    ch, ps, pn = c["case_h"], c["post"], c["pane"]
    cx, cz = bx * 0.5 - 0.015 - ps * 0.5, bz * 0.5 - 0.015 - ps * 0.5
    top_y = by + ch
    for i, (sx, sz) in enumerate([(-1, -1), (1, -1), (-1, 1), (1, 1)]):
        ms.append(member("post%d" % i, "stud", [ps, ch - ps, ps], [sx * cx, by + (ch - ps) * 0.5, sz * cz], look=WALNUT))
    for s_, name in ((-1, "b"), (1, "f")):
        ms.append(member("rail_" + name, "cripple", [cx * 2 + ps, ps, ps], [0, top_y - ps * 0.5, s_ * cz], look=WALNUT))
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("rail_" + name, "cripple", [ps, ps, cz * 2 - ps], [s_ * cx, top_y - ps * 0.5, 0], look=WALNUT))
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
        "_doc": "A druggist's prescription balance in its case (#805; ref experiments/prop_lab/refs/doctor/scales_cased_balance_1860_1880_wellcome.jpg): a walnut base with a drawer for the weights (its brass knob), a glazed walnut case on it (corner posts, a top frame; glass sides, front and top: glass members, a ball breaks a pane as a window's), and inside a turned brass pillar, a brass beam on its knife edge with a pointer down to its scale, two small brass pans hung low on stirrups. Walnut from the material library (F2 a few years, the doctor's; the period's cases were mahogany or walnut); the brass baked the gun way (tools/blender/props/doctor_d2.py; brass's members are the metal's own section, wood `iron` for its weight: brass is ~8.5 t/m3 to iron's 7.6). ~10 kg. Stands on the dispensary's counter; the pillar shot out drops the beam and pans. Written by tools/props/doctor.py.",
        "id": "scales", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- His desk: a walnut roll-top --------------------------------------------------------------------
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
            ms.append(member("ped_%s_side%d" % (name, k), "post", [t, under, D - 0.02], [x, under * 0.5, -0.01], look=WALNUT))
        ms.append(member("ped_%s_back" % name, "furniture_frame", [pw - t * 2, under - 0.02, t], [cx, under * 0.5 + 0.01, zb + t * 0.5], look=WALNUT))
        ms.append(member("ped_%s_plinth" % name, "furniture_frame", [pw - t * 2, d["plinth"], t], [cx, d["plinth"] * 0.5, D * 0.5 - 0.02 - t * 0.5], look=WALNUT))
    for did, (w, h), (x, y, z) in desk_drawers():
        m = member(did, "trim", [w, h, 0.02], [x, y, z], look=WALNUT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Pull_" + did)}]
        ms.append(m)
    # The writing bed, its boards front to back, worn where his arms rest.
    nb = 3
    bw = D / nb
    for k in range(nb):
        bed = member("bed%d" % k, "furniture_top", [W, d["board"], bw], [0, d["bed"] - d["board"] * 0.5, -D * 0.5 + bw * (k + 0.5)], look=WALNUT_TOP)
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
        ms.append(member("case_side_" + name, "trim", [t, y1 - y0, z1 - z0], [s_ * (W * 0.5 - t * 0.5), cy, cz], look=WALNUT,
                         draw={"shape": "cut", "outline": [list(p) for p in outline], "plane": "zy"}))
    ms.append(member("case_back", "trim", [W - t * 2, y1 - y0, t], [0, cy, zb + t * 0.5], look=WALNUT))
    top_d = d["case_depth"] + 0.02
    ms.append(member("case_top", "trim", [W, d["board"], top_d], [0, d["top"] - d["board"] * 0.5, zb + top_d * 0.5 - 0.005], look=WALNUT_TOP))
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
        ms.append(member("drawer_case_%d" % k, "trim", [0.010, lo, pd], [x, d["bed"] + lo * 0.5, pz], look=WALNUT))
    shelf = member("pigeon_shelf", "trim", [inner, sh, pd], [0, py0 - sh * 0.5, pz], look=WALNUT)
    # His papers in the pigeonholes: letters, bills, a ledger (drawn on the shelf; they burn with it).
    shelf["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Papers")}]
    ms.append(shelf)
    for k in range(d["pigeons"] + 1):
        x = -inner * 0.5 + 0.006 + (inner - 0.012) * k / d["pigeons"]
        if k in (0, d["pigeons"]):
            continue
        ms.append(member("pigeon_%d" % k, "trim", [0.010, py1 - py0, pd], [x, (py0 + py1) * 0.5, pz], look=WALNUT))
    ms.append(member("pigeon_top", "trim", [inner, sh, pd], [0, py1 + sh * 0.5, pz], look=WALNUT))
    for did, (w, h), (x, y, z) in desk_small_drawers():
        m = member(did, "trim", [w, h, 0.012], [x, y, z], look=WALNUT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Pull_" + did)}]
        ms.append(m)
    return {
        "_doc": "His desk (#805; refs experiments/prop_lab/refs/doctor/): a walnut roll-top of the 1880s (the doctor's spec gives him one), 1.4 m wide, 0.8 deep: two pedestals of four drawers either side of the knee hole (a shallow drawer over it), a writing bed of three boards across them, and on its back the roll-top's case: S-curved sides (library boards cut to the curve, PropKit.lib_cut_mesh), a back, a top, the tambour rolled up out of sight under its top, eight pigeonholes over a row of six small drawers. Brass pulls baked the gun way (tools/blender/props/doctor_d2.py). Walnut from the material library (F2 a few years: the bed and top worn where his arms go). ~85 kg. Its front, where he sits, toward +z. A ball through a pedestal's side holes it and it stands. Written by tools/props/doctor.py.",
        "id": "roll_top_desk", "kind": "members", "fixture": True, "in_game": False, "wood": "walnut",
        "splits_below": 0.3, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The dispensary's counter and shelves: the kit's own, in his walnut ----------------------------
# The kit's counter and shelves (assets/props/kit/counter.json, shelves.json) `like`d in the material
# library's walnut, the shelves with seven boards (a druggist's shelving runs to the ceiling, its
# boards a bottle's height apart: 0.35 m).
SHELVES = {"depth": 0.30, "height": 2.62, "length": 2.0, "boards": [0.12, 0.42, 0.72, 1.02, 1.32, 1.62, 1.92, 2.22, 2.52], "board": 0.025}


def dispensary_shelves():
    c = SHELVES
    L = c["length"]
    ms = []
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("upright_" + name, "post", [c["depth"], c["height"], 0.03], [0, c["height"] * 0.5, s_ * (L * 0.5 - 0.015)], look=WALNUT))
    for k, y in enumerate(c["boards"]):
        ms.append(member("shelf%d" % k, "furniture_top", [c["depth"], c["board"], L - 0.06], [0, y, 0], look=WALNUT_TOP))
    # A cornice over the front (round 2's critic: a plain bookcase): a deep board on the uprights.
    ms.append(member("cornice", "trim", [c["depth"] + 0.05, 0.09, L + 0.06], [0.025, c["height"] + 0.045, 0], look=WALNUT))
    # A back of boards behind them (the shelving's own: the bottles stand against it, not the wall's).
    ms.append(member("back", "furniture_frame", [0.012, c["height"] - 0.1, L - 0.06], [-c["depth"] * 0.5 + 0.006, c["height"] * 0.5, 0], look=WALNUT))
    return {
        "_doc": "The dispensary's shelving (#805): the kit's shelves (`like` shelves.json) in the doctor's walnut from the material library (F2 a few years, the boards' tops worn), 2.7 m high with nine boards 0.3 m apart (a druggist's shelving runs up the wall, its boards a bottle's height apart), a cornice and a boarded back. Fitted along its wall as the kit's shelves are (PropKit.spawn_fitted: length along Z, depth along X); what stands on a board (the bottles) comes down when it goes. Written by tools/props/doctor.py.",
        "id": "dispensary_shelves", "like": "shelves", "fixture": True, "in_game": False, "wood": "walnut",
        "look": WALNUT, "members": ms,
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
    ms = [member("front", "post", [L, under, t], [0, under * 0.5, zf - t * 0.5], look=WALNUT)]
    for s_, name in ((-1, "l"), (1, "r")):
        ms.append(member("end_" + name, "post", [t, under, D - 0.075 - t], [s_ * (L * 0.5 - t * 0.5), under * 0.5, (zf + D * 0.5) * 0.5], look=WALNUT))
    ms.append(member("plinth", "furniture_frame", [L - t * 2, c["plinth"], 0.02], [0, c["plinth"] * 0.5, zf - t - 0.01], look=WALNUT))
    for did, (w, h), (x, y, z) in counter_drawers():
        m = member(did, "trim", [w, h, 0.018], [x, y, z], look=WALNUT)
        m["dress"] = [{"look": "pbr:desk_brass", "draw": mesh("desk_brass", "Knob_" + did)}]
        ms.append(m)
    ms.append(member("top", "furniture_top", [L, c["top"], D], [0, H - c["top"] * 0.5, 0], look=WALNUT_TOP))
    return {
        "_doc": "The dispensary's counter (#805): the kit's counter (`like` counter.json: a front and two ends under a top overhanging the front) at 2.3 m, its front faced with three rows of eight small drawers for roots and powders, each with a turned brass knob (the period's dispensing counters, the target panel's dispensary; round 1's critic called the plain one a blank box). In the doctor's walnut from the material library (F2 a few years, the top worn where he works); the knobs baked the gun way (glb:desk_brass). Along the west wall at his make_up place, the scales and mortar on it. Its front (the drawers) toward -z. Written by tools/props/doctor.py.",
        "id": "dispensary_counter", "like": "counter", "fixture": True, "in_game": False, "wood": "walnut",
        "look": WALNUT, "members": ms,
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


BATCH_D2 = [medicine_bottle, medicine_bottle_round, poison_bottle, drug_jar, mortar, scales, roll_top_desk, dispensary_shelves,
            dispensary_counter, bentwood_chair]


BATCH_D1 = [examining_table, iron_cot, washstand, wash_basin, wash_pitcher, instrument_tray, reflector_lamp, hand_towel]


def main():
    batches = {"D1": BATCH_D1, "D2": BATCH_D2}
    which = [a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--batch=")] or ["D1", "D2"]
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
