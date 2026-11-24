"""The general store's stock and fittings, batch G1 (#1139): the counters, wall shelving and its rolling
ladder, the stove and its chairs, the barrels, the sacks, the counter scales, bolts of cloth. Written from the
numbers here, so a change is one number and a re-run:

    python3 tools/props/store_g2.py     # writes G1's and G2's assets/props/kit/<id>.json (G2 bakes G1's metal)

The placement (`dressing_g1()`, `dressing_windows()`) is read by experiments/building_lab/store/gen_spec.py
into config/buildings/store.json's `dressing` (PropDressing, #844). What an 1882 Colorado general store held,
where, and the refs: experiments/prop_lab/store/README.md.

Spec space (the store's): x from the alley (east) wall, z in from Main Street; a prop faces +Z at facing 0,
facing 90 turns +Z to +X (away from the alley), 270 to -X. Woods are the library's
(`lib:furniture_painted_pine/few` for the body of a counter or shelving, `lib:furniture_oak/few/top` for what's
worked on, #825); a ladder rail or a brass strip is a bare `prop:` metal look (no Blender here: the baked metal
is G2's, README "Left for G2").
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import booze  # noqa: E402  (the game's own brands, #1222)

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
KIT = os.path.join(ROOT, "assets", "props", "kit")

PINE = "lib:furniture_painted_pine/few"
PINE_TOP = PINE + "/top"
PINE_FRONT = PINE + "/front"
OAK = "lib:furniture_oak/few"
OAK_TOP = OAK + "/top"
OAK_FRONT = OAK + "/front"

COUNTER_H = 0.94     # a store counter's top: 37 in, the clerk's elbow
COUNTER_D = 0.62
SHELF_DEPTH = 0.36
SHELF_H = 3.1        # under the beaded ceiling (3.56 over the floor), the cornice's top 3.19
SHELF_YS = [1.3, 1.65, 2.0, 2.35, 2.7]   # open boards over the cupboards (0.35 m apart: a tin's height and a hand)
SHELF_TOP = 0.93     # the cupboards' top, the working shelf
LADDER_RAIL_Y = 2.9


def r(v, n=4):
    return [round(float(c), n) for c in v] if isinstance(v, (list, tuple)) else round(float(v), n)


def member(mid, kind, size, at, look=None, wood=None, **kw):
    m = {"id": mid, "kind": kind, "size": r(size), "at": r(at)}
    if wood:
        m["wood"] = wood
    if look:
        m["look"] = look
    m.update(kw)
    return m


# --- The store counter ---------------------------------------------------------------------------------
# A long panelled counter (the kit's counter: a front, two ends, a top overhanging the front, `like`
# counter.json): stiles and rails on the customers' side (-z), a brass yardstick let into the top's edge (the
# dry goods counters had one: the customer's check on the clerk's measure), a bank of drawers on the clerk's
# side (+z) with brass pulls, the top oak. Refs: experiments/prop_lab/refs/store/README.md.
def store_counter():
    L, H, D, t = 3.0, COUNTER_H, COUNTER_D, 0.03
    under = H - 0.04
    zf = -D * 0.5 + 0.075
    ms = [member("front", "post", [L, under, t], [0, under * 0.5, zf - t * 0.5], OAK)]
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("end_" + n, "post", [t, under, D - 0.075 - t], [s * (L * 0.5 - t * 0.5), under * 0.5, (zf + D * 0.5) * 0.5], OAK))
    ms.append(member("back", "post", [L - 2 * t, under, t], [0, under * 0.5, D * 0.5 - t * 0.5], OAK))
    ms.append(member("plinth", "furniture_frame", [L - t * 2, 0.08, 0.02], [0, 0.04, zf - t - 0.01], OAK))
    # Panels: a stile every metre and a rail top and bottom, proud of the front by 12 mm.
    n = max(2, round(L / 1.0))
    zs = zf - t - 0.006
    for i in range(n + 1):
        x = -L * 0.5 + t + 0.035 + i * (L - 2 * t - 0.07) / n
        ms.append(member("stile%d" % i, "trim", [0.07, under - 0.2, 0.012], [x, 0.1 + (under - 0.2) * 0.5 + 0.0, zs], OAK_FRONT))
    for nm, y in (("rail_top", under - 0.05), ("rail_bottom", 0.1)):
        ms.append(member(nm, "trim", [L - 2 * t, 0.1, 0.012], [0, y, zs], OAK_FRONT))
    # The clerk's side: drawers (one a metre) with brass pulls.
    nd = max(2, round(L / 0.9))
    w = (L - 2 * t - 0.02 * (nd + 1)) / nd
    zb = D * 0.5 + 0.009
    for i in range(nd):
        x = -L * 0.5 + t + 0.02 + w * 0.5 + i * (w + 0.02)
        ms.append(member("drawer%d" % i, "furniture_frame", [w, 0.26, 0.018], [x, 0.62, zb], OAK_FRONT))
        ms.append(member("pull%d" % i, "trim", [0.08, 0.02, 0.025], [x, 0.66, zb + 0.02], "prop:brass", wood="iron"))
    ms.append(member("top", "furniture_top", [L, 0.04, D], [0, H - 0.02, 0], OAK_TOP))
    # The yardstick: a 36 in brass strip let into the top along its customer edge, tacks at the inches.
    ms.append(member("yardstick", "trim", [0.914, 0.004, 0.022], [-L * 0.5 + 0.45 + 0.457, H + 0.002, -D * 0.5 + 0.05], "prop:brass", wood="iron"))
    return {
        "_doc": "A general store's counter (#1139, G1): the kit's counter (`like` counter.json: a front, two ends and a top overhanging the customers' side, -z) 3 m long and 0.94 high, its front in stiles and rails, a brass yardstick let into its top's edge, a bank of drawers with brass pulls on the clerk's side (+z), body and top oak from the material library (a few years; the top worn where he works). Fitted to the length each counter wants (PropKit.spawn_fitted). The yardstick and pulls are bare `prop:brass` until the baked metal (G2). Written by tools/props/store_g1.py.",
        "id": "store_counter", "like": "counter", "fixture": True, "in_game": False, "wood": "oak",
        "look": OAK, "members": ms,
    }


# --- The wall shelving ---------------------------------------------------------------------------------
# Shelving to the ceiling (the clue "a rolling ladder on the shelves"): cupboards below with panelled doors,
# a working shelf over them, five open boards over that, a cornice, and a ladder rail of iron on two brackets
# along the front at 2.9 m. Depth along X (back at -x), length along Z, like the kit's shelves.
def store_shelving():
    L, d, H = 1.95, SHELF_DEPTH, SHELF_H
    ms = []
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("upright_" + n, "post", [d, H, 0.03], [0, H * 0.5, s * (L * 0.5 - 0.015)], PINE))
    ms.append(member("cupboard_top", "furniture_top", [d + 0.1, 0.03, L - 0.06], [0.05, SHELF_TOP - 0.015, 0], PINE_TOP))
    ms.append(member("kick", "furniture_frame", [0.02, 0.1, L - 0.06], [d * 0.5 - 0.01, 0.05, 0], PINE))
    for i, y in enumerate(SHELF_YS):
        ms.append(member("shelf%d" % i, "furniture_top", [d, 0.025, L - 0.06], [0, y, 0], PINE_TOP))
    # Two panelled doors on the cupboards, each a board with its pull.
    w = (L - 0.06) * 0.5 - 0.004
    for i, s in enumerate((-1, 1)):
        z = s * (w * 0.5 + 0.002)
        ms.append(member("door%d" % i, "furniture_frame", [0.016, SHELF_TOP - 0.2, w], [d * 0.5 + 0.008, 0.1 + (SHELF_TOP - 0.2) * 0.5, z], PINE_FRONT))
        ms.append(member("pull%d" % i, "trim", [0.03, 0.06, 0.02], [d * 0.5 + 0.03, SHELF_TOP - 0.3, s * 0.05], "prop:iron", wood="iron"))
    ms.append(member("cornice", "trim", [d + 0.06, 0.1, L + 0.04], [0.03, H + 0.05, 0], PINE))
    ms.append(member("back", "furniture_frame", [0.012, H - 0.1, L - 0.06], [-d * 0.5 + 0.006, H * 0.5, 0], PINE))
    # The ladder rail: a rod on two bracket arms under the top board's front.
    for s, n in ((-1, "a"), (1, "b")):
        ms.append(member("rail_arm_" + n, "trim", [0.09, 0.02, 0.02], [d * 0.5 + 0.04, SHELF_YS[-1], s * (L * 0.5 - 0.12)], "prop:iron", wood="iron"))
    ms.append(member("ladder_rail", "trim", [0.025, 0.025, L - 0.1], [d * 0.5 + 0.0825, SHELF_YS[-1] + 0.0225, 0], "prop:iron", wood="iron"))
    return {
        "_doc": "A general store's wall shelving (#1139, G1; `like` shelves.json, the dispensary's): 3.1 m of painted pine from the material library along its wall, 0.36 deep, cupboards below under panelled doors and a working shelf over them, five open boards 0.35 m apart over that for the tins and bolts, a cornice and a ladder rail of iron on two arms along the front at 2.7 m for the rolling ladder. Fitted along its wall (PropKit.spawn_fitted: length along Z, depth along X; back at -x); what stands on a board comes down when it goes. Written by tools/props/store_g1.py.",
        "id": "store_shelving", "like": "shelves", "fixture": True, "in_game": False, "wood": "weathered_pine",
        "look": PINE, "members": ms,
    }


# --- The rolling ladder --------------------------------------------------------------------------------
def rolling_ladder():
    H, W = 2.75, 0.42
    ms = []
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("rail_" + n, "post", [0.04, H, 0.04], [0, H * 0.5, s * W * 0.5], OAK))
    for i in range(9):
        y = 0.3 + i * 0.29
        ms.append(member("rung%d" % i, "furniture_frame", [0.03, 0.03, W - 0.04], [0.0, y, 0], OAK))
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("hook_" + n, "trim", [0.09, 0.04, 0.03], [-0.045, 2.7225, s * W * 0.5], "prop:iron", wood="iron"))
    return {
        "_doc": "A rolling ladder (#1139, G1): two oak rails and nine rungs, 2.75 m, an iron hook at the top of each rail that hangs it on the shelving's rail (the store's clue). Built upright (a kit prop is held by what's under its own bottom): it stands against the shelves' front, its hooks over the rail, the way it is when the clerk's done. Its rungs face +x. Written by tools/props/store_g1.py.",
        "id": "rolling_ladder", "kind": "members", "in_game": False, "wood": "oak", "look": OAK,
        "splits_below": 0.4, "blow_wood_share": 0.5, "members": ms,
    }


# --- The stove with a pipe to the ceiling ----------------------------------------------------------------
def store_stove():
    base = json.load(open(os.path.join(KIT, "box_stove.json")))
    ms = base["members"]
    top = [m for m in ms if m["id"] == "pipe3"][0]
    # The shop's ceiling is 3.56 over its floor (the saloon's flue is higher): one more length, cut to 0.3.
    ms = ms + [dict(top, id="pipe4", size=[0.152, 0.30, 0.152], at=[-0.27, round(top["at"][1] + 0.31 + 0.15, 4), 0.0],
                    draw={"shape": "mesh", "model": "box_stove", "part": "Pipe3"})]
    d = dict(base)
    d.update({"id": "store_stove", "members": ms, "factory": "tools/props/store_g1.py"})
    d["_doc"] = "The shop's stove (#1139, G1): the saloon's box stove (box_stove.json) with a fifth length of pipe cut to run up under the shop's beaded ceiling (3.56 m over its floor), the sand box, the draught and the coals as the saloon's. The chairs and the barrels by it are the clue of the store (\"barrels of crackers and pickles by the stove\"). Written by tools/props/store_g1.py."
    d.pop("like", None)
    return d


# --- Barrels, open and shut ------------------------------------------------------------------------------
def _open_barrel(id_, goods, goods_look, doc, y=0.80):
    base = json.load(open(os.path.join(KIT, "barrel.json")))
    ms = [m for m in base["members"] if not m["id"].startswith("head_top")]
    ms.append(member("goods", "furniture_top", [0.40, 0.05, 0.40], [0.0, y, 0.0], goods_look, wood="grain_sack"))
    d = {k: v for k, v in base.items() if k not in ("members", "replaces", "in_game", "holds", "id", "_doc")}
    d.update({"id": id_, "members": ms, "factory": "tools/props/store_g1.py", "in_game": False,
              "_doc": doc + " Open at the top (the barrel's top head left out, a heap of its goods in its place): the barrel's staves and bottom, `prop:staves`. Written by tools/props/store_g1.py."})
    return d


def cracker_barrel():
    return _open_barrel("cracker_barrel", "crackers", "prop:straw",
                        "A cracker barrel (#1139, G1): the store's one by the stove, open, its crackers heaped to the top (a customer helps himself while the talk goes round the stove).")


def flour_barrel():
    return _open_barrel("flour_barrel", "flour", "prop:ivory",
                        "A flour barrel (#1139, G1): open, flour heaped in it under a cloth-sack scoop's reach.", y=0.78)


def sugar_barrel():
    return _open_barrel("sugar_barrel", "sugar", "prop:ivory", "A sugar barrel (#1139, G1): open, brown sugar heaped to the top.", y=0.78)


def pickle_barrel():
    d = _open_barrel("pickle_barrel", "pickles", "prop:felt", "A pickle barrel (#1139, G1): open, its pickles in their brine, a fork on the lid.", y=0.74)
    return d


# --- Sacks ---------------------------------------------------------------------------------------------------
def coffee_sack():
    return {"like": "feed_sack", "id": "coffee_sack", "factory": "tools/props/store_g1.py", "look": "prop:burlap",
            "_doc": "A sack of green coffee (#1139, G1): the feed sack's burlap, stood by the counter (a 60 kg sack of Arbuckle's green beans came to the railhead in them). Written by tools/props/store_g1.py."}


def flour_sack():
    return {"like": "feed_sack", "id": "flour_sack", "factory": "tools/props/store_g1.py", "look": "prop:canvas",
            "_doc": "A sack of flour (#1139, G1): the feed sack's shape in white canvas, a 50 lb sack. Written by tools/props/store_g1.py."}


# --- The counter scales: G2's since #1172 (tools/props/store_g2.py store_scales, baked with hung pans) ----------


# --- Bolts of cloth ----------------------------------------------------------------------------------------
def _bolt(id_, look, doc):
    # 0.30 tall: under the board over it (the boards are 0.325 apart clear; G1's 0.36 ran 3.5 cm into it, #1172).
    ms = [member("board", "post", [0.085, 0.30, 0.035], [0, 0.15, 0], "prop:dark_wood"),
          member("cloth", "trim", [0.11, 0.285, 0.085], [0, 0.15, 0], look, wood="canvas")]
    return {"_doc": doc, "id": id_, "kind": "members", "fixture": True, "in_game": False, "wood": "canvas", "look": look,
            "splits_below": 0.3, "blow_wood_share": 0.5, "members": ms, "factory": "tools/props/store_g1.py"}


def bolt_calico():
    return _bolt("bolt_calico", "prop:canvas", "A bolt of calico (#1139, G1): cloth wound on a flat board, 12 in tall, standing on its end. Written by tools/props/store_g1.py.")


def bolt_felt():
    return _bolt("bolt_felt", "prop:felt", "A bolt of green wool (#1139, G1): flannel on its board, standing. Written by tools/props/store_g1.py.")


def bolt_plaid():
    return _bolt("bolt_plaid", "pbr:folded_blankets", "A bolt of plaid wool (#1139, G1): a bolt of blanket cloth. Written by tools/props/store_g1.py.")


BATCH_G1 = [store_counter, store_shelving, rolling_ladder, store_stove, cracker_barrel, flour_barrel, sugar_barrel, pickle_barrel,
            coffee_sack, flour_sack, bolt_calico, bolt_felt, bolt_plaid]


# === Where each goes: the store's `dressing` ====================================================================
# The shop: the east counter in two lengths with the clerk's gap between (the flap the hinge lifts), shelving along
# the east wall between its windows (z 2.3, 4.2: sill 0.9, 1.5 high) and the hardware wall between its lamps (z 3.4, 8.0).
SH = 0.1 + SHELF_DEPTH * 0.5 + 0.004    # the shelving's centre against the east (alley) wall
SH_W = 16.66 - SHELF_DEPTH * 0.5 - 0.004  # and the west one
FRONT_COUNTER = [("east_counter_a", 2.3, 3.65, 3.3), ("east_counter_b", 2.3, 7.4, 2.4)]


def e(id_, kit, at, facing=0, **kw):
    d = {"id": id_, "kit": kit, "at": [round(v, 3) for v in at], "facing": facing}
    d.update(kw)
    return d


def shelving_box():
    """The shelving's members' own box (x: back -0.18 to the cupboard top's and rail's front 0.28; y: to
    the cornice's top 3.2): a bay is fitted to it across and up and only stretched along its wall. G1
    fitted it to [0.36, 3.1] and squashed it (#1172: the boards came out 4 to 9 cm under SHELF_YS, every
    shelf good floating over its board or dropped onto it, the bolts through the board over them)."""
    lo, hi = [1e9] * 3, [-1e9] * 3
    for m in store_shelving()["members"]:
        for a in range(3):
            lo[a] = min(lo[a], m["at"][a] - m["size"][a] * 0.5)
            hi[a] = max(hi[a], m["at"][a] + m["size"][a] * 0.5)
    return round(hi[0] - lo[0], 4), round(hi[1] - lo[1], 4)


def bay(id_, x, z, length, facing):
    bx, by = shelving_box()
    return e(id_, "store_shelving", [x, 0.0, z], facing, fit=[bx, by, round(length, 3)])


def dressing_g1():
    out = []
    # Counters (a customer's side toward the middle of the room): fit [length, height, depth].
    for id_, x, z, L in FRONT_COUNTER:
        out.append(e(id_, "store_counter", [x, 0.0, z], 270, fit=[L, COUNTER_H, COUNTER_D]))
    out.append(e("west_counter", "store_counter", [14.6, 0.0, 4.15], 90, fit=[4.0, COUNTER_H, COUNTER_D]))
    out.append(e("back_counter", "store_counter", [13.3, 0.0, 8.7], 0, fit=[3.0, COUNTER_H, COUNTER_D]))
    # Shelving: the east wall's three bays, the west wall's four.
    for id_, z, L in (("east_shelves_a", 5.8, 1.9), ("east_shelves_b", 7.75, 1.9), ("east_shelves_c", 9.65, 1.8)):
        out.append(bay(id_, SH, z, L, 0))
    for id_, z, L in (("west_shelves_a", 2.5, 1.3), ("west_shelves_b", 4.65, 2.0), ("west_shelves_c", 6.675, 2.05), ("west_shelves_d", 9.15, 1.7)):
        out.append(bay(id_, SH_W, z, L, 180))
    # The rolling ladders hang on the rail of a bay each (their hooks 4.5 cm over it).
    out.append(e("ladder_east", "rolling_ladder", [SH + SHELF_DEPTH * 0.5 + 0.0825 + 0.045, 0.0, 9.65], 0))
    out.append(e("ladder_west", "rolling_ladder", [SH_W - SHELF_DEPTH * 0.5 - 0.0825 - 0.045, 0.0, 4.65], 180))
    # On the counters: the scales, the clerk's jars of candy.
    out.append(e("scales_east", "store_scales", [2.3, 0.0, 3.1], 270, on="east_counter_a"))
    out.append(e("scales_west", "store_scales", [14.6, 0.0, 3.6], 90, on="west_counter"))
    out.append(e("candy_jars", "drug_jar", [2.3, 0.0, 4.4], 270, on="east_counter_a",
                 row={"kits": ["drug_jar"], "count": 3, "step": [0, 0, 0.16], "jitter": [0.01, 0.01, 30]}))
    out.append(e("till", "till_drawer", [13.3, 0.0, 8.75], 0, on="back_counter"))  # (#1172: at 9.0 its middle was over the top's back edge and it dropped 0.19 m)
    # The stove, its chairs, the barrels about it. The stove's door to the room (facing 90), its pipe behind.
    out.append(e("stove", "store_stove", [10.2, 0.0, 9.0], 90, use="the shop's stove (the use point 'stove' stands 1.4 m in front of it)"))
    out.append(e("stove_chair_a", "chair", [9.0, 0.0, 8.9], 90))
    out.append(e("stove_chair_b", "chair", [11.4, 0.0, 8.9], 270))
    out.append(e("stove_chair_c", "chair", [9.4, 0.0, 7.85], 140))
    out.append(e("stove_spittoon", "spittoon", [10.9, 0.0, 7.95], 0))
    out.append(e("cracker_barrel", "cracker_barrel", [11.5, 0.0, 7.55], 20))
    out.append(e("pickle_barrel", "pickle_barrel", [12.1, 0.0, 7.45], 0))
    # The grocery's staples along the back wall either side of its door (x 8.28, 1.1 wide): flour, sugar, coffee.
    out.append(e("flour_barrel_a", "flour_barrel", [6.4, 0.0, 10.35], 0))
    out.append(e("flour_barrel_b", "flour_barrel", [7.0, 0.0, 10.4], 40))
    out.append(e("sugar_barrel", "sugar_barrel", [10.0, 0.0, 10.4], 0))
    out.append(e("coffee_sacks", "coffee_sack", [5.6, 0.0, 10.4], 15, row={"kits": ["coffee_sack", "flour_sack"], "count": 3, "step": [-0.45, 0, 0], "jitter": [0.02, 0.02, 20]}))
    # Stock on the shelves (round 1's critic: bare grids). Boards are `SHELF_YS`; a prop stands on its board's top
    # (an explicit y, not `on`: `on` is a fitted fixture's top, 3.1 m). West (dry goods): bolts of cloth on four
    # boards of the two long bays, notions' jars on the third; east (grocery): jars, patent-medicine bottles,
    # tin cups and lamps along the boards. The cupboards' working shelf carries crockery.
    def row(id_, kits, x, y, z0, n, step, facing, jit=(0.004, 0.004, 6), variants=None):
        out.append({"id": id_, "kit": kits[0], "at": [x, y, z0], "facing": facing,
                    "row": dict({"kits": kits, "count": n, "step": [0, 0, step], "jitter": list(jit)}, **({"variants": variants} if variants else {}))})
    bolts = ["bolt_calico", "bolt_felt", "bolt_plaid", "bolt_calico", "bolt_plaid"]
    # G2 (#1172) fills the rest of the boards with rows of tins and boxes, boots and hats
    # (tools/props/store_g2.py STOCK): G1 keeps the bolts on the dry goods' boards 1 and 2, the post office
    # bay's jars, and on the grocery's top boards the patent medicines and the lamps for sale.
    for bid, z0 in (("b", 3.75), ("c", 5.8)):
        for k in (1, 2):
            row("bolts_%s_%d" % (bid, k), bolts, SH_W - 0.02, SHELF_YS[k] + 0.0125, z0, 9, 0.215, 180)
    row("jars_west_d", ["drug_jar", "medicine_bottle"], SH_W - 0.05, SHELF_YS[1] + 0.0125, 8.4, 7, 0.22, 180, (0.01, 0.01, 20))
    # The grocery's top board: the patent medicines and bitters a store sold by the bottle, and the cheap
    # goods (#1222, docs/briefs/booze.md: the dumb ones are the store's and the Railroad Saloon's).
    stock = [("square", "bottoms"), ("cabin", "hearthstone"), ("panel", "tolliver"), ("square", "aunt_fanny"), ("panel", "windham"),
             ("quart", "ball"), ("panel", "boner"), ("square", "pruett"), ("panel", "pemberly"), ("stone", "bumstead"),
             ("panel", "dingle"), ("square", "amazon"), ("beer", "twin_buttes")]
    row("east_bottles_a", [booze.kit_of(sh) for sh, _ in stock], SH + 0.0, SHELF_YS[4] + 0.0125, 4.95, len(stock), 0.145, 0, (0.008, 0.01, 20),
        variants=[booze.variant_of(sh, b) for sh, b in stock])
    row("east_lamps_b", ["oil_lamp"], SH + 0.0, SHELF_YS[4] + 0.0125, 7.2, 3, 0.6, 0, (0.01, 0.02, 30))
    # The middle of the floor, a dense one (the critic: a dance hall): two display tables of dry goods and a
    # stack of crates and sacks on the grocery side, clear of the use points (browse 8.4/2.6 and 8.4/7.4, wait 6.6/4.4).
    out.append(e("table_dry", "table", [11.2, 0.0, 4.9], 0, fit=[1.8, 0.8, 0.9], use="a display table of dry goods, off the browse and buy points"))
    out.append({"id": "table_dry_bolts", "kit": "bolt_calico", "at": [10.6, 0.0, 4.75], "facing": 170, "on": "table_dry",
                "row": {"kits": bolts, "count": 5, "step": [0.2, 0, 0], "jitter": [0.005, 0.01, 8]}})
    out.append(e("table_dry_blankets", "folded_blankets", [11.5, 0.0, 5.1], 10, on="table_dry"))
    out.append(e("table_dry_bolt_stack", "folded_blanket", [11.95, 0.0, 4.7], 355, on="table_dry"))
    out.append(e("crates_a", "crate", [6.0, 0.0, 6.4], 10))
    out.append(e("crates_b", "crate", [6.65, 0.0, 6.45], 350))
    out.append(e("crates_c", "crate", [6.35, 0.0, 7.05], 30))
    out.append(e("grain_sacks_a", "grain_sacks", [4.9, 0.0, 6.5], 80))
    return out


EAST_X = 5.0   # filled by gen_spec (its SHOW_X); only used when called from there


def dressing_windows(east_x, west_x, dz):
    """The show windows: what the stand-ins (#1074) become: the east window dry goods and groceries, the west
    hardware (its lamps, basin and pitcher, saw and cups are the store's own stock; the strongbox and chamber pot
    were not)."""
    return [
        e("east_stand", "table", [east_x + 0.5, 0.0, dz], 0, fit=[2.3, 0.6, 0.7], use="the east window's display platform (the glass's foot is 0.61 over the floor)"),
        e("east_barrel", "cracker_barrel", [east_x - 1.15, 0.0, dz], 30, use="a cracker barrel, its top half over the bulkhead"),
        e("east_blankets", "folded_blankets", [east_x - 0.35, 0.0, dz + 0.05], 186, on="east_stand"),
        {"id": "east_bolts", "kit": "bolt_calico", "on": "east_stand", "at": [east_x + 0.0, 0.0, dz - 0.18], "facing": 180,
         "row": {"kits": ["bolt_calico", "bolt_plaid", "bolt_felt", "bolt_calico", "bolt_plaid"], "count": 5, "step": [0.2, 0, 0], "jitter": [0.005, 0.01, 8]}},
        e("east_scales", "store_scales", [east_x + 1.0, 0.0, dz - 0.05], 180, on="east_stand"),
        e("east_sack_a", "coffee_sack", [east_x + 1.4, 0.0, dz + 0.12], 200, on="east_stand"),
        e("east_sack_b", "flour_sack", [east_x + 0.75, 0.0, dz + 0.15], 160, on="east_stand"),
        e("west_stand", "table", [west_x, 0.0, dz], 0, fit=[3.0, 0.6, 0.7], use="the west window's display platform"),
        e("west_lamp", "oil_lamp", [west_x - 0.7, 0.0, dz - 0.05], 180, on="west_stand"),
        e("west_basin", "wash_basin", [west_x - 0.2, 0.0, dz + 0.08], 0, on="west_stand"),
        e("west_pitcher", "wash_pitcher", [west_x - 0.2, 0.0, dz + 0.1], 200, on="west_basin", lift=0.014),
        e("west_flour", "flour_barrel", [west_x + 0.35, 0.0, dz + 0.05], 0, on="west_stand"),
        e("west_saw", "handsaw", [west_x + 0.15, 0.0, dz - 0.24], 184, on="west_stand"),
        {"id": "west_cups", "kit": "tin_cup", "on": "west_stand", "at": [west_x + 0.85, 0.0, dz - 0.15], "facing": 180,
         "row": {"kits": ["tin_cup"], "count": 4, "step": [0.15, 0, 0.0], "jitter": [0.015, 0.03, 40]}},
        e("west_trunk_lamp", "oil_lamp", [west_x + 1.25, 0.0, dz + 0.15], 180, on="west_stand"),
    ]


def main():
    for make in BATCH_G1:
        d = make()
        d.setdefault("factory", "tools/props/store_g1.py")
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, ROOT), "(%d members)" % len(d.get("members", [])))
    print("dressing: %d entries" % len(dressing_g1()))


if __name__ == "__main__":
    main()
