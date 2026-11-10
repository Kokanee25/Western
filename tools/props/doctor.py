"""The doctor's office props (docs/briefs/prop-factory.md, "The doctor's office batch", #788): the
kit files of an 1882 country doctor's furniture, written from the numbers here, so a change is one
number and a re-run. The Blender half (tools/blender/props/doctor_*.py) reads the same numbers.

    python3 tools/props/doctor.py            # writes assets/props/kit/<id>.json for batch D1

Woods from the material library (`lib:<entry>/<age>`, #721: only ages the materials judge passed:
F2 `fine_walnut_tg` new and a few years, the doctor's own floor's), metal and cloth baked the gun way
(`pbr:<model>`, tools/blender/props/metal.py). Masses from the materials (TimberTuning: walnut, iron,
straw, hay, canvas); every member's kind on the support ladder (docs/briefs/prop-factory.md "Kinds").
Each prop's period reference: experiments/prop_lab/refs/doctor/README.md.
"""
import json
import os

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
    return {
        "_doc": "A plain walnut washstand (#788; refs experiments/prop_lab/refs/doctor/): a two-board top with a low splashback, a drawer in the front apron with its brass knob, a shelf low down; the wash basin and pitcher (white ironstone china, their own kit files) stand on it. Walnut from the material library (F2 a few years, as the examining table). ~22 kg. Written by tools/props/doctor.py.",
        "id": "washstand", "kind": "members", "fixture": True, "wood": "walnut",
        "splits_below": 0.5, "blow_wood_share": 0.5,
        "members": ms,
    }


# --- The china: wash basin and pitcher (white ironstone) -------------------------------------------
BASIN = {"radius": 0.19, "height": 0.095, "foot": 0.075}
PITCHER = {"radius": 0.105, "height": 0.31, "foot": 0.075}


def wash_basin():
    return {
        "_doc": "A white ironstone wash basin (the common washstand china of the 1860s-80s; #788, refs experiments/prop_lab/refs/doctor/), 38 cm across: a prop that shatters (GlassProp). ~5 mm of fired clay under its glaze: it breaks dropped from a table's height or kicked (2.5 m/s) and at ~25 kPa; a ball breaks it. Baked the gun way (tools/blender/props/doctor_d1.py). Holds a litre of water. Written by tools/props/doctor.py.",
        "id": "wash_basin", "kind": "shatters", "fixture": True,
        "model": "glb:washset", "looks": {"Basin": "pbr:washset"},
        "size": r([BASIN["radius"] * 2, BASIN["height"], BASIN["radius"] * 2]),
        "mass": 1.6, "wall": 0.005, "glass": ["Basin"], "whole": [], "shards": 9, "piece_mass": 0.2,
        "breaks_at": 2.5, "shatters_kpa": 25, "heat_seconds": 1e9, "cut_area": 0.03,
        "contents": {"liquid": "water", "litres": 1.0},
    }


def wash_pitcher():
    return {
        "_doc": "A white ironstone pitcher (ewer) to the basin (#788), 31 cm high with its handle and lip, standing in the basin: a prop that shatters (GlassProp), as the basin. Holds 2.5 l of water. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "wash_pitcher", "kind": "shatters", "fixture": True,
        "model": "glb:washset", "looks": {"Pitcher": "pbr:washset"},
        "size": r([PITCHER["radius"] * 2, PITCHER["height"], PITCHER["radius"] * 2]),
        "mass": 1.4, "wall": 0.005, "glass": ["Pitcher"], "whole": [], "shards": 9, "piece_mass": 0.2,
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
        "_doc": "An instrument tray (#788; refs experiments/prop_lab/refs/doctor/): a white enamelled iron tray 36 x 24 cm, chipped at its rim, with a bone saw, a bullet forceps, Nelaton's porcelain-tipped probe and a scalpel on it (nickel-plated; the saw and scalpel ebony-handled). A loose rigid prop (LooseProp): a ball holes its thin iron and knocks it, a boot sends it, a hard landing dents it; it doesn't burn. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "instrument_tray", "kind": "loose", "fixture": True,
        "model": "glb:instrument_tray",
        "looks": {k: "pbr:instrument_tray" for k in ("Tray", "SawBlade", "SawHandle", "Forceps", "Probe", "ProbeTip",
                                                     "ScalpelBlade", "ScalpelHandle")},
        "shape": "box", "size": r(TRAY["size"]),
        "mass": 1.3, "wall": 0.0008, "hole_radius": 0.005, "breaks_at": 4.0, "shatters_kpa": 1e9,
        "spills_below": 0.0,
        "dent": {"radius": 0.03, "shot": 0.004, "kick": 0.008, "fall": 0.004},
    }


# --- The lamp with a reflector --------------------------------------------------------------------
# The oil lamp (its kit file) on a stand with a tin reflector behind its chimney, to throw its light
# onto the table: the surgery's lamp at night, held over the table (DESIGN.md's showcase).
LAMP = {"size": (0.2, 0.44, 0.2)}


def reflector_lamp():
    return {
        "_doc": "A kerosene lamp with a reflector (#788; refs experiments/prop_lab/refs/doctor/): the oil lamp's (`like`) brass foot and font, burner and glass chimney, with a dished tinplate reflector on an arm behind the chimney to throw its light forward (+z) onto the table, the surgery's lamp at night. A prop that shatters (GlassProp): the chimney breaks, the brass and tin come through whole. Baked the gun way (tools/blender/props/doctor_d1.py). Written by tools/props/doctor.py.",
        "id": "reflector_lamp", "like": "oil_lamp", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:reflector_lamp",
        "looks": {"Chimney": "prop:chimney_glass", "Foot": "pbr:reflector_lamp", "Font": "pbr:reflector_lamp",
                  "Burner": "pbr:reflector_lamp", "Reflector": "pbr:reflector_lamp"},
        "size": r(LAMP["size"]), "mass": 1.1,
        "glass": ["Chimney"], "whole": [["Foot", "Font", "Burner", "Reflector"]],
    }


BATCH_D1 = [examining_table, iron_cot, washstand, wash_basin, wash_pitcher, instrument_tray, reflector_lamp]


def main():
    for make in BATCH_D1:
        d = make()
        d["factory"] = "tools/props/doctor.py"
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))


if __name__ == "__main__":
    main()
