"""The general store's stock, batch G2 (#1172): the shelves filled (rows of labelled tins and boxes, cases on
the shelving's top), boots and hats, hardware (nail kegs, a keg of tools, rope, lamp oil), tinware, a glass
showcase and the coffee mill for the counters, hanging lamps; and the baked metal G1 left bare (the scales
with hung pans and a pointer, the brass and iron swatches the pulls, yardstick and ladder rail are drawn in).

    python3 tools/props/store_g2.py                                    # assets/props/kit/<id>.json
    ~/.venvs/studio/bin/python tools/blender/props/build.py --only=store_g2   # the models it draws from

The numbers here are the Blender script's too (tools/blender/props/store_g2.py imports this file), so a
kit member's box and the mesh drawn in it can't drift. The placement (`dressing_g2()`) is read by
experiments/building_lab/store/gen_spec.py into config/buildings/store.json's `dressing`, batch G2.
Refs: experiments/prop_lab/refs/store/ (four dated interiors, 1895-1900: every board packed label-out
two or three high, cases stacked on the shelving's top, the coffee mill and a showcase on the counters,
the scales' pans hung from the beam, a lamp hung from the ceiling). Plan and judging:
experiments/prop_lab/store/README.md.

Spec space as store_g1's: x from the alley (east) wall, z in from Main Street, y over the shop floor; a
prop faces +Z at facing 0 (90 turns +Z to +X, 270 to -X).
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import store_g1  # noqa: E402
from store_g1 import COUNTER_H, KIT, OAK, OAK_FRONT, OAK_TOP, SH, SH_W, SHELF_YS, SHELF_TOP, e, member  # noqa: E402

FACTORY = "tools/props/store_g2.py"

# --- Shelf stock: a row is one kit prop of two members, each a block of goods drawn from one baked model ---
# A row's own space: its length along x (0.6 m, two members of 0.3), its depth along z with the labels to
# +z (the board's front edge at +0.18: the bay's board is 0.36 deep and the row stands on its middle).
ROW_LEN = 0.6
BOARD_TOP = [round(y + 0.0125, 4) for y in SHELF_YS]   # each open board's top (0.025 thick)
WORK_TOP = SHELF_TOP                                    # the cupboards' top, the working shelf
CASE_TOP = 3.2                                          # the cornice's top (store_g1's shelving, 3.1 + 0.1)
CLEAR = 0.325                                           # between one board's top and the next one's underside

# kind -> its goods, the block a member is (size [x, y, z] and its middle's y, z), the wood it breaks as. Tins are
# `paper` too: a block of cans weighs what its food does (~700 kg/m3); as `iron` the kit's floor (a hollow member
# weighs at least a fifth of its box's metal) made a row 44 kg.
# Every block's goods are laid out in tools/blender/props/store_g2.py from `item` and `grid`.
GOODS = {
    # Tall tins (a 2 lb can: 3 in across, 4 1/2 high): tomatoes, peaches, corn, condensed milk.
    "tins": {"item": [0.074, 0.11, 0.074], "grid": [4, 2, 2], "wood": "paper", "solid": 1.0,
             "labels": "tins"},
    # Squat tins (oysters, salmon, sardines, deviled ham: 1 lb flat cans), three high.
    "tins_flat": {"item": [0.088, 0.062, 0.088], "grid": [3, 3, 2], "wood": "paper", "solid": 1.0,
                  "labels": "tins_flat"},
    # Cartons standing (soap, starch, baking powder, crackers by the pound, tea), two high.
    "boxes": {"item": [0.094, 0.13, 0.07], "grid": [3, 2, 2], "wood": "paper", "solid": 0.4,
              "labels": "boxes"},
    # Flat boxes in stacks (cartridges, matches, collars, thread): four high, two stacks deep.
    "boxes_flat": {"item": [0.135, 0.05, 0.11], "grid": [2, 4, 2], "wood": "paper", "solid": 0.4,
                   "labels": "boxes_flat"},
    # Packing cases on the shelving's top (the refs' "stacked to the ceiling"): one stencilled case and a
    # carton on it a member.
    "cases": {"item": [0.28, 0.22, 0.3], "grid": [1, 1, 1], "wood": "weathered_pine", "solid": 0.3,
              "labels": "cases", "top": [0.2, 0.1, 0.16]},
}
ROW_KITS = {"tin_row": "tins", "tin_row_flat": "tins_flat", "box_row": "boxes", "box_row_flat": "boxes_flat",
            "case_row": "cases"}


def goods_block(kind):
    """A member's block of goods: size and middle (its own x 0), from the item and grid."""
    g = GOODS[kind]
    ix, iy, iz = g["item"]
    nx, ny, nz = g["grid"]
    h = iy * ny + (g["top"][1] if "top" in g else 0.0)
    d = iz * nz + 0.01 * (nz - 1)
    zf = 0.155   # the front's labels 2.5 cm in from the board's edge
    return [0.3, round(h, 4), round(d, 4)], [0.0, round(h * 0.5, 4), round(zf - d * 0.5, 4)]


def part_name(kind, i):
    return "%s%d" % ("".join(w.capitalize() for w in kind.split("_")), i)


def row_kit(kit, kind, half=False):
    size, mid = goods_block(kind)
    g = GOODS[kind]
    ms = []
    for i, x in enumerate((-0.15, 0.15)):
        if half and i == 1:
            break
        ms.append(member("goods%d" % i, "post", size, [x, mid[1], mid[2]], "pbr:store_goods", wood=g["wood"], solid=g["solid"],
                         draw={"shape": "mesh", "model": "store_goods", "part": part_name(kind, i)}))
    return {
        "_doc": "A row of %s on a store shelf (#1172, G2; refs experiments/prop_lab/refs/store/: every board packed label-out two or three high): %s, each member a block of them (a ball through it, the block comes down; the row comes down with its shelf). Drawn from glb:store_goods, every label printed on one sheet (tools/blender/props/store_g2.py: Pillow; period grocers' lines, no maker's names). Written by tools/props/store_g2.py." % (
            kind.replace("_", " "), "one block (half a row: the end of a board)" if half else "two blocks of 0.3 m"),
        "id": kit + ("_half" if half else ""), "kind": "members", "fixture": True, "in_game": False, "wood": g["wood"],
        "look": "pbr:store_goods", "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY, "members": ms,
    }


# --- Boots and hats --------------------------------------------------------------------------------------
# A pair of stovepipe boots (Ward's 1875: "men's calf boots, 16 in leg"), cut to 0.33 to stand on the working
# shelf under the first board (0.36 clear); the second pair russet. Toes to +z.
BOOT = {"h": 0.33, "foot": 0.27, "w": 0.09, "heel": 0.035, "pair_gap": 0.11}
HAT = {"brim": [0.36, 0.32], "crown": [0.17, 0.15], "crown_h": 0.12, "nest": 0.022}


def boot_row():
    ms = []
    for i, (x, finish) in enumerate(((-0.13, "black"), (0.13, "russet"))):
        ms.append(member("pair%d" % i, "post", [0.22, BOOT["h"], BOOT["foot"]], [x, BOOT["h"] * 0.5, 0.0], "pbr:store_dry", wood="leather",
                         solid=0.15, draw={"shape": "mesh", "model": "store_dry", "part": "Boots%d" % i}))
    return {"_doc": "Two pairs of men's boots for sale (#1172, G2; Ward's 1875 catalogue's calf boots), standing on the working shelf toes out: a blacked pair and a russet pair, 33 cm (a stovepipe boot's 16 in leg cut down to the shelf's clearance). Each pair a member (leather: ~2.5 kg). Modelled and baked in tools/blender/props/store_g2.py (code-built stand-ins: Rodin's quoted on #1175). Written by tools/props/store_g2.py.",
            "id": "boot_row", "kind": "members", "fixture": True, "in_game": False, "wood": "leather", "look": "pbr:store_dry",
            "splits_below": 0.3, "blow_wood_share": 0.4, "factory": FACTORY, "members": ms}


def hat_stack(single=False):
    n = 1 if single else 3
    h = HAT["crown_h"] + 0.01 + HAT["nest"] * (n - 1)
    parts = ["HatSingle"] if single else ["HatBlack", "HatBrown", "HatBuff"]
    m = member("hats", "post", [HAT["brim"][0], round(h, 4), HAT["brim"][1]], [0.0, round(h * 0.5, 4), 0.0], "pbr:store_dry", wood="canvas",
               solid=0.2, draw={"shape": "mesh", "model": "store_dry", "part": parts[0]})
    if len(parts) > 1:
        m["dress"] = [{"look": "pbr:store_dry", "draw": {"shape": "mesh", "model": "store_dry", "part": p}} for p in parts[1:]]
    return {"_doc": ("A wide-brimmed felt hat (#1172, G2), the pale buff the catalogues called silver belly, set down on its brim." if single else
                     "Three wide-brimmed felt hats nested one over another on a shelf (#1172, G2: the refs' and Ward's 1875 \"plainsman\" hats in black, brown and buff), 36 cm across the brim.") +
            " One member (felt: canvas's rules). Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": "hat_single" if single else "hat_stack", "kind": "members", "fixture": True, "in_game": False, "wood": "canvas",
            "look": "pbr:store_dry", "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY, "members": [m]}


def rope_coil():
    return {"_doc": "A coil of manila rope for sale (#1172, G2), 3/4 in, about 30 m laid in turns. One member (canvas's rules: it burns, a ball goes through). Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": "rope_coil", "kind": "members", "fixture": True, "in_game": False, "wood": "canvas", "look": "pbr:store_dry",
            "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY,
            "members": [member("coil", "post", [0.36, 0.1, 0.36], [0.0, 0.05, 0.0], "pbr:store_dry", wood="canvas", solid=1.0,
                               draw={"shape": "mesh", "model": "store_dry", "part": "Rope"})]}


# --- Hardware and tinware ----------------------------------------------------------------------------------
KEG = {"r": 0.155, "bulge": 0.17, "h": 0.42, "body_h": 0.36}


def _hw(id_, doc, ms, wood="iron"):
    return {"_doc": doc + " Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": id_, "kind": "members", "fixture": True, "in_game": False, "wood": wood, "look": "pbr:store_hardware",
            "splits_below": 0.3, "blow_wood_share": 0.4, "factory": FACTORY, "members": ms}


def _draw(part, *dress):
    d = {"draw": {"shape": "mesh", "model": "store_hardware", "part": part}}
    if dress:
        d["dress"] = [{"look": "pbr:store_hardware", "draw": {"shape": "mesh", "model": "store_hardware", "part": p}} for p in dress]
    return d


def _keg_members():
    b = KEG["bulge"] * 2
    return [member("keg", "post", [b, KEG["body_h"], b], [0, KEG["body_h"] * 0.5, 0], "pbr:store_hardware", wood="weathered_pine", solid=0.25,
                   **_draw("KegStaves", "KegHoops"))]


def nail_keg():
    ms = _keg_members()
    ms.append(member("nails", "post", [0.27, 0.04, 0.27], [0, KEG["body_h"] + 0.02, 0], "pbr:store_hardware", wood="iron", solid=0.5, **_draw("Nails")))
    return _hw("nail_keg", "A keg of cut nails, its head knocked out (#1172, G2): a 100 lb keg (11 in across, 16 high), the nails heaped in it to be weighed out by the pound.", ms, "weathered_pine")


def tool_keg():
    ms = _keg_members()
    ms.append(member("tools", "post", [0.24, 0.66, 0.24], [0, KEG["body_h"] + 0.33, 0], "pbr:store_hardware", wood="oak", solid=0.12,
                     **_draw("ToolHandles", "ToolHeads")))
    return _hw("tool_keg", "A keg of tools for sale handles up (#1172, G2; the hardware corner of the refs): an axe, a long-handled shovel and a hoe stood in an empty nail keg.", ms, "weathered_pine")


def _loose(id_, part, doc, size, mass, shape="cylinder", spills=0.3):
    """Tinware as the kit's tin cup is (LooseProp: one rigid body, dents, holes, never breaks), drawn from its
    Blender part (`glb:store_hardware`), at its own weight (a member's box would weigh a fifth of its iron)."""
    return {"_doc": doc + " A loose rigid prop (LooseProp, as the tin cup): knocked off, it rolls; a ball holes it through both sides; a fall or a kick dents it. Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": id_, "kind": "loose", "fixture": True, "in_game": False, "model": "glb:store_hardware", "looks": {part: "pbr:store_hardware"},
            "shape": shape, "size": size, "mass": mass, "wall": 0.0005, "hole_radius": 0.006, "breaks_at": 1000.0, "shatters_kpa": 1000000000.0,
            "spills_below": spills, "dent": {"radius": 0.03, "shot": 0.004, "kick": 0.008, "fall": 0.003}, "factory": FACTORY}


def oil_can():
    return _loose("oil_can", "OilCan", "A five-gallon can of kerosene, full (#1172, G2): square tinplate with a screw cap and a wire handle, the way lamp oil came by rail from the 1870s.",
                  [0.24, 0.36, 0.24], 16.0, "box", 0.0)


def tin_pail():
    return _loose("tin_pail", "Pail", "A tin pail (#1172, G2): tinplate, 10 qt, a wire bail.", [0.28, 0.25, 0.28], 0.8)


def coffeepot():
    return _loose("coffeepot", "Coffeepot", "A tin coffeepot (#1172, G2): tapering tinplate, a spout and a strap handle, a knobbed lid.", [0.16, 0.24, 0.16], 0.5)


def tea_kettle():
    return _loose("tea_kettle", "Kettle", "A tin tea kettle (#1172, G2): squat, a spout and a wire bail.", [0.24, 0.18, 0.24], 0.7)


# --- The coffee mill and the showcase ------------------------------------------------------------------------
MILL = {"wheel_r": 0.25, "axle_y": 0.31, "body_w": 0.22, "wheel_x": 0.14, "h": 0.6}


def coffee_mill():
    m = MILL
    wy = m["axle_y"] + m["wheel_r"]

    def d(part):
        return {"draw": {"shape": "mesh", "model": "coffee_mill", "part": part}}
    ms = [member("body", "post", [m["body_w"], m["h"], 0.2], [0, m["h"] * 0.5, 0], "pbr:coffee_mill", wood="iron", solid=0.0, **d("Body")),
          # (each wheel's box down to the counter: a kit member is held by what's under its own bottom; the wheel
          # drawn clear of it)
          member("wheel_l", "post", [0.04, wy, m["wheel_r"] * 2], [-m["wheel_x"], wy * 0.5, 0], "pbr:coffee_mill", wood="iron", solid=0.0, **d("WheelL")),
          member("wheel_r", "post", [0.04, wy, m["wheel_r"] * 2], [m["wheel_x"], wy * 0.5, 0], "pbr:coffee_mill", wood="iron", solid=0.0, **d("WheelR"))]
    ms[0]["dress"] = [{"look": "pbr:coffee_mill", "draw": {"shape": "mesh", "model": "coffee_mill", "part": "Hopper"}}]
    return {"_doc": "The store's coffee mill (#1172, G2; refs/store/grocery_left_hand_view_1895: the two-wheel counter mill of the 1870s-90s): cast iron enamelled red, a brass hopper with an eagle-less lid, two spoked flywheels 50 cm across turned by a handle, the grounds' drawer under. Stands on the counter. ~75 kg of iron (the big two-wheel kind: an Enterprise No. 12 was 160 lb). Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": "coffee_mill", "kind": "members", "fixture": True, "in_game": False, "wood": "iron", "look": "pbr:coffee_mill",
            "splits_below": 0.3, "blow_wood_share": 0.3, "factory": FACTORY, "members": ms}


SHOWCASE = {"L": 1.2, "D": 0.45, "H": 0.42, "base": 0.08, "post": 0.03}


def showcase():
    """On the doctor's glass-cased scales' pattern (scales.json): the base a post, the corner posts studs, the top's
    rails cripples on them, the panes `glass` members."""
    c = SHOWCASE
    L, D, H, b, p = c["L"], c["D"], c["H"], c["base"], c["post"]
    gh = H - b - p
    ms = [member("base", "post", [L, b, D], [0, b * 0.5, 0], OAK_TOP, wood="oak")]
    xs, zs = L * 0.5 - p * 0.5, D * 0.5 - p * 0.5
    for i, (sx, sz) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        ms.append(member("post%d" % i, "stud", [p, gh, p], [sx * xs, b + gh * 0.5, sz * zs], OAK, wood="oak"))
    yr = b + gh + p * 0.5
    for n, size, at in (("rail_f", [L, p, p], [0, yr, -zs]), ("rail_b", [L, p, p], [0, yr, zs]),
                        ("rail_l", [p, p, D - 2 * p], [-xs, yr, 0]), ("rail_r", [p, p, D - 2 * p], [xs, yr, 0])):
        ms.append(member(n, "cripple", size, at, OAK, wood="oak"))
    for n, size, at in (("pane_front", [L - 2 * p, gh, 0.004], [0, b + gh * 0.5, -zs]), ("pane_back", [L - 2 * p, gh, 0.004], [0, b + gh * 0.5, zs]),
                        ("pane_l", [0.004, gh, D - 2 * p], [-xs, b + gh * 0.5, 0]), ("pane_r", [0.004, gh, D - 2 * p], [xs, b + gh * 0.5, 0]),
                        ("pane_top", [L - 2 * p, 0.004, D - 2 * p], [0, yr, 0])):
        ms.append(member(n, "glass", size, at, "glass:clear", wood="glass"))
    ms.append(member("goods", "post", [L - 0.12, 0.05, D - 0.12], [0, b + 0.025, 0], "pbr:store_dry", wood="paper", solid=0.3,
                     draw={"shape": "mesh", "model": "store_dry", "part": "CaseGoods"},
                     dress=[{"look": "pbr:store_dry", "draw": {"shape": "mesh", "model": "store_dry", "part": p}} for p in ("CaseKnives", "CasePipes")]))
    return {"_doc": "A counter showcase (#1172, G2; refs/store/grocery_left_hand_view_1895: glass cases on the counters; built as the doctor's glass-cased scales are): an oak base, corner posts and a frame of rails on top, glass on four sides and the top, the small goods laid in it (spools of thread, pocket knives on their card, pipes, combs). 1.2 m by 0.45, 0.42 high. The glass the game's clear (`glass:`); the goods baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py.",
            "id": "showcase", "kind": "members", "fixture": True, "in_game": False, "wood": "oak", "look": OAK,
            "splits_below": 0.3, "blow_wood_share": 0.4, "factory": FACTORY, "members": ms}


# --- The baked metal G1 left bare ---------------------------------------------------------------------------
# G1's scales rebuilt as the refs' (Georgia, 1899) even balance: a japanned base and pillar, a brass beam
# with its pointer over a scale plate, two brass pans hung from its ends on three wires each. The pans' boxes
# rest on the base's ends (a kit member is held by what's under it); their wires up to the beam are drawn.
SCALES = {"base": [0.36, 0.05, 0.2], "pillar_h": 0.36, "beam_y": 0.43, "beam_len": 0.54, "pan_r": 0.1, "pan_y": 0.15}


def store_scales():
    c = SCALES
    bx, by, bz = c["base"]
    x = c["beam_len"] * 0.5 - 0.02

    def d(part):
        return {"draw": {"shape": "mesh", "model": "store_scales", "part": part}}
    pan_h = c["beam_y"] - 0.015 - by
    # (the pans' members are thin rods from the base's ends up to the beam, as the doctor's scales' are: a member
    # is held by what's under it, and a full-size box would weigh a fifth of its iron; the hung pans are drawn)
    ms = [member("base", "post", [bx, by, bz], [0, by * 0.5, 0], "pbr:store_scales", wood="iron", solid=0.02, **d("Base")),
          member("pillar", "furniture_frame", [0.05, c["pillar_h"], 0.05], [0, by + c["pillar_h"] * 0.5 - 0.005, 0], "pbr:store_scales", wood="iron", solid=0.1, **d("Pillar")),
          member("beam", "trim", [c["beam_len"], 0.03, 0.03], [0, c["beam_y"], 0], "pbr:store_scales", wood="iron", solid=0.4, **d("Beam")),
          member("pan_l", "trim", [0.004, pan_h, 0.004], [-x + 0.08, by + pan_h * 0.5, 0], "pbr:store_scales", wood="iron", **d("PanL")),
          member("pan_r", "trim", [0.004, pan_h, 0.004], [x - 0.08, by + pan_h * 0.5, 0], "pbr:store_scales", wood="iron", **d("PanR"))]
    return {
        "_doc": "A grocer's even-balance counter scale (#1139 G1, rebuilt baked in G2 #1172; refs/store/grocery_interior_georgia_1899: the pans hung from the beam): a black-japanned cast base and pillar, a brass beam on its knife edge with a pointer down to a scale plate, two brass pans hung from the beam's ends on three wires each. ~6 kg. Stands on the counter; the pillar shot out drops the beam. Modelled and baked in tools/blender/props/store_g2.py. Written by tools/props/store_g2.py (in place of G1's bare boxes).",
        "id": "store_scales", "kind": "members", "fixture": True, "in_game": False, "wood": "iron", "look": "pbr:store_scales",
        "splits_below": 0.3, "blow_wood_share": 0.3, "factory": FACTORY, "members": ms,
    }


# The swatches: G1's yardstick, pulls, ladder rail and hooks are boxes fitted along a counter or a bay, so
# they can't be one Blender mesh (a mesh is in the prop's space and doesn't stretch with a fit): they take a
# baked metal's look as a tiling material instead (`pbr:store_brass`, `pbr:store_iron`: one flat plate filling
# its atlas, tools/blender/props/store_g2.py).
SWAP_LOOKS = {"prop:brass": "pbr:store_brass", "prop:iron": "pbr:store_iron"}


def baked_metal(d):
    for m in d.get("members", []):
        if m.get("look") in SWAP_LOOKS:
            m["look"] = SWAP_LOOKS[m["look"]]
    d["_doc"] = d["_doc"].replace("bare `prop:brass` until the baked metal (G2)", "brass baked (G2, #1172: `pbr:store_brass`)")
    return d


BATCH_G2 = [lambda: row_kit("tin_row", "tins"), lambda: row_kit("tin_row_flat", "tins_flat"), lambda: row_kit("box_row", "boxes"),
            lambda: row_kit("box_row_flat", "boxes_flat"), lambda: row_kit("case_row", "cases"),
            lambda: row_kit("tin_row", "tins", True), lambda: row_kit("tin_row_flat", "tins_flat", True), lambda: row_kit("box_row", "boxes", True),
            lambda: row_kit("box_row_flat", "boxes_flat", True), lambda: row_kit("case_row", "cases", True),
            boot_row, hat_stack, lambda: hat_stack(True), rope_coil, nail_keg, tool_keg, oil_can, tin_pail, coffeepot, tea_kettle,
            coffee_mill, showcase, store_scales]
# G1's kit files G2 bakes (the swatches swapped in): written again here, after store_g1 writes them.
BAKED_G1 = [store_g1.store_counter, store_g1.store_shelving, store_g1.rolling_ladder]


# === Where each goes: the store's `dressing`, batch G2 ===========================================================
BAYS = {  # id -> (x of its boards' middle, z of its middle, length, the goods' facing: label-out to the room)
    "east_shelves_a": (SH, 5.8, 1.9, 90), "east_shelves_b": (SH, 7.75, 1.9, 90), "east_shelves_c": (SH, 9.65, 1.8, 90),
    "west_shelves_a": (SH_W, 2.5, 1.3, 270), "west_shelves_b": (SH_W, 4.65, 2.0, 270), "west_shelves_c": (SH_W, 6.675, 2.05, 270),
    "west_shelves_d": (SH_W, 9.15, 1.7, 270),
}
# What's on each board (index: "work" the cupboards' top, 0-4 the open boards, "top" the cornice), by bay. The
# grocery's east wall all tins and boxes; the dry goods' west wall boots, bolts (G1's), notions, hats.
STOCK = {
    "east_shelves_a": {"work": "box_row", 0: "tin_row_flat", 1: "tin_row", 2: "box_row_flat", 3: "tin_row", "top": "case_row"},
    "east_shelves_b": {"work": "box_row", 0: "tin_row_flat", 1: "tin_row", 2: "box_row_flat", 3: "tin_row", "top": "case_row"},
    "east_shelves_c": {"work": "box_row_flat", 0: "tin_row", 1: "tin_row_flat", 2: "box_row", 3: "tin_row", 4: "tin_row_flat", "top": "case_row"},
    "west_shelves_a": {"work": "box_row", 0: "box_row_flat", 1: "tin_row", 2: "box_row", 3: "box_row_flat", 4: "tin_row_flat", "top": "case_row"},
    "west_shelves_b": {"work": "boot_row", 0: "box_row_flat", 3: "box_row", 4: "hats", "top": "case_row"},
    "west_shelves_c": {"work": "boot_row", 0: "box_row", 3: "box_row_flat", 4: "hats", "top": "case_row"},
    "west_shelves_d": {"top": "case_row"},
}


def _wobble(id_, amount):
    h = int(hashlib.md5(id_.encode()).hexdigest()[:8], 16)
    return ((h % 1000) / 500.0 - 1.0) * amount, (((h // 1000) % 1000) / 500.0 - 1.0)


def _turn(facing, lx):
    """Where a prop's own +x lands along z (the bays run along z): facing 90 turns +x to -z, 270 to +z."""
    return -lx if facing == 90 else lx


def board_y(k):
    return WORK_TOP if k == "work" else CASE_TOP if k == "top" else BOARD_TOP[k]


def fill_board(out, bay, k, kit):
    x, zc, L, facing = BAYS[bay]
    room = L - 0.08
    y = board_y(k)
    tag = "%s_%s" % (bay.replace("_shelves", ""), k)
    if kit == "hats":
        n = int(room // 0.4)
        for i in range(n):
            z = zc - room * 0.5 + (i + 0.5) * room / n
            dz, t = _wobble(tag + str(i), 0.03)
            out.append(e("hats_%s_%d" % (tag, i), "hat_stack" if i % 2 == 0 else "hat_single", [x, y, z + dz], facing + 8 * t))
        return
    if kit == "boot_row":
        n = int(room // 0.55)
        for i in range(n):
            z = zc - room * 0.5 + (i + 0.5) * room / n
            out.append(e("boots_%s_%d" % (tag, i), "boot_row", [x + 0.03, y, z], facing + 4 * _wobble(tag + str(i), 1)[1]))
        return
    n = int(room // ROW_LEN)
    half = room - n * ROW_LEN >= 0.3
    used = n * ROW_LEN + (0.3 if half else 0.0)
    z0 = zc - used * 0.5
    for i in range(n):
        dz, t = _wobble(tag + str(i), 0.012)
        out.append(e("%s_%s_%d" % (kit, tag, i), kit, [x, y, z0 + (i + 0.5) * ROW_LEN + dz], facing + 2.5 * t))
    if half:
        # (its one member is at its own x -0.15: the prop's place moved so the block falls at the board's end)
        zm = z0 + n * ROW_LEN + 0.15
        out.append(e("%s_%s_end" % (kit, tag), kit + "_half", [x, y, zm - _turn(facing, -0.15)], facing))


def dressing_g2():
    out = []
    for bay, boards in STOCK.items():
        for k, kit in boards.items():
            fill_board(out, bay, k, kit)
    # The counters (at their top's y: `on` names an entry of the same batch only, and the counters are G1's):
    # the coffee mill at the grocery counter's back end, a showcase of small goods on the dry
    # goods counter, hats and rope there; tinware on the back counter either side of the till.
    out.append(e("coffee_mill", "coffee_mill", [2.3, COUNTER_H, 8.15], 270))
    out.append(e("showcase_west", "showcase", [14.6, COUNTER_H, 4.95], 90))
    out.append(e("hats_counter", "hat_stack", [14.62, COUNTER_H, 2.6], 95))
    out.append(e("rope_counter", "rope_coil", [14.6, COUNTER_H, 5.9], 20))
    out.append(e("coffeepot_back", "coffeepot", [12.25, COUNTER_H, 8.65], 200))
    out.append(e("kettle_back", "tea_kettle", [12.7, COUNTER_H, 8.7], 160))
    out.append(e("pail_back", "tin_pail", [14.3, COUNTER_H, 8.68], 0))
    # The hardware's corner on the floor, by the dry goods counter's back end (clear of buy_2 at 13.5/3.2 and
    # the stove's chairs and barrels round 10-12/7.5-9): nail kegs, the keg of tools, a pail; lamp oil by the
    # back wall (the stove's at 10.2: the cans 0.9 m off it, as a careless clerk would set them).
    out.append(e("nail_keg_a", "nail_keg", [13.25, 0.0, 6.75], 0))
    out.append(e("nail_keg_b", "nail_keg", [13.72, 0.0, 7.2], 35))
    out.append(e("tool_keg", "tool_keg", [12.8, 0.0, 6.6], 70))
    out.append(e("pail_floor", "tin_pail", [13.2, 0.0, 7.35], 0))
    out.append(e("oil_can_a", "oil_can", [11.05, 0.0, 10.42], 5))
    out.append(e("oil_can_b", "oil_can", [11.35, 0.0, 10.4], 352))
    # Hung from the ceiling (the refs: a lamp over the counter, the aisle): the kit's hanging lamp, its foot 1.0
    # under its hook, the beaded ceiling 3.56 over the floor; lit by the clock, no shadows (the wall's
    # reflector lamps cast them).
    for i, (x, z) in enumerate([(4.6, 4.2), (8.4, 6.2), (12.2, 4.2)]):
        out.append(e("hanging_lamp_%d" % i, "hanging_lamp", [x, 3.56 - 1.0, z], 0, light=0.33, shadows=False, energy=1.0))
    return out


def main():
    store_g1.main()  # G1's files first (store_g1's numbers), then G2 swaps its metal in
    for make in BATCH_G2 + BAKED_G1:
        d = make()
        if make in BAKED_G1:
            d = baked_metal(d)
            d["_doc"] += " Its brass and iron baked by tools/props/store_g2.py (G2, #1172)."
        d.setdefault("factory", "tools/props/store_g1.py" if make in BAKED_G1 else FACTORY)
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, store_g1.ROOT), "(%d members)" % len(d.get("members", [])))
    print("dressing G2: %d entries" % len(dressing_g2()))


if __name__ == "__main__":
    main()
