"""The general store's batch G3 (#1182): the post office's pigeonholes (west_shelves_d's bay), the postmaster's
desk and stool, the ledger and day-book with pen and inkwell, the till's cash, and goods hung from the beaded
ceiling (pails, hams, lanterns) so the room reads from the door.

    python3 tools/props/store_g2.py        # writes G1's, G2's and G3's assets/props/kit/<id>.json
    ~/.venvs/studio/bin/python tools/blender/props/build.py --only=store_g3   # the models it draws from

The numbers here are the Blender script's too (tools/blender/props/store_g3.py imports this file). The
placement (`dressing_g3()`) is read by experiments/building_lab/store/gen_spec.py into config/buildings/
store.json's `dressing`, batch G3; the case replaces G1's shelving in the post office's bay (`BAY_D`), which
gen_spec drops from G1. Period: a fourth-class post office kept in a store (the postmaster was the
storekeeper): a case of pigeonholes lettered by surname in alphabetical groups, general delivery and
registered, letters standing in them on edge, parcels in brown paper and string below. Refs:
experiments/prop_lab/refs/store/ and the README's G3 section.

Spec space as store_g1's: x from the alley wall, z in from Main Street, y over the floor; a prop faces +Z at
facing 0 (90 turns +Z to +X, 270 to -X; the west wall's goods face 270).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import store_g1  # noqa: E402
from store_g1 import COUNTER_H, KIT, OAK, OAK_TOP, OAK_FRONT, SH_W, SHELF_TOP, e, member  # noqa: E402
PINE, PINE_TOP, PINE_FRONT = OAK, OAK_TOP, OAK_FRONT   # (G1's round 1: the painted pine read teal and dark in the room; the oak is the counters')

FACTORY = "tools/props/store_g3.py"
HAS = "pbr:store_post"

# --- The case --------------------------------------------------------------------------------------------
# Local space as the shelving's: the back at -x, the room at +x, its length along z. Fitted to nothing (placed at
# its own size, so no squash: G1's trap).
CASE = {"L": 1.7, "d": 0.30, "H": 2.45, "cols": 8, "rows": 4, "row_pitch": 0.2, "y0": 1.25, "board": 0.015,
        "divider": 0.012, "sign_h": 0.3}
BAY_D = ("west_shelves_d", SH_W, 9.15, 1.7)   # id, x, z, length: G1's bay this case takes over
LABELS = ["A", "B", "C", "D", "E", "F", "G", "H", "I-J", "K", "L", "M", "Mc", "N", "O", "P", "Q-R", "S", "T", "U-V", "W", "Y-Z",
          "GENERAL DELIVERY", "REGISTERED", "STAMPS", "UNCALLED FOR", "DRAWER 1", "DRAWER 2", "FORWARD", "RETURN", "NEWSPAPERS", "DEAD LETTERS"]


def cell_pitch():
    c = CASE
    return (c["L"] - 0.06 - c["divider"] * (c["cols"] - 1)) / c["cols"] + c["divider"]


def board_top(k):
    """Top of the k'th board (0 is the pigeonholes' floor, 4 their roof's underside)."""
    c = CASE
    return round(c["y0"] + k * c["row_pitch"] + c["board"] * 0.5, 4)


def post_case():
    c = CASE
    L, d, H = c["L"], c["d"], c["H"]
    ms = []
    for s, n in ((-1, "l"), (1, "r")):
        ms.append(member("upright_" + n, "post", [d, H, 0.03], [0, H * 0.5, s * (L * 0.5 - 0.015)], PINE))
    ms.append(member("cupboard_top", "furniture_top", [d + 0.1, 0.03, L - 0.06], [0.05, SHELF_TOP - 0.015, 0], PINE_TOP))
    ms.append(member("kick", "furniture_frame", [0.02, 0.1, L - 0.06], [d * 0.5 - 0.01, 0.05, 0], PINE))
    w = (L - 0.06) * 0.5 - 0.004
    for i, s in enumerate((-1, 1)):
        ms.append(member("door%d" % i, "furniture_frame", [0.016, SHELF_TOP - 0.2, w], [d * 0.5 + 0.008, 0.1 + (SHELF_TOP - 0.2) * 0.5, s * (w * 0.5 + 0.002)], PINE_FRONT))
        ms.append(member("pull%d" % i, "trim", [0.03, 0.06, 0.02], [d * 0.5 + 0.03, SHELF_TOP - 0.3, s * 0.05], "pbr:store_iron", wood="iron"))
    ms.append(member("back", "furniture_frame", [0.012, H - 0.05, L - 0.06], [-d * 0.5 + 0.006, H * 0.5, 0], PINE))
    for k in range(c["rows"] + 1):
        ms.append(member("board%d" % k, "furniture_top", [d - 0.02, c["board"], L - 0.06], [0, round(c["y0"] + k * c["row_pitch"], 4), 0], PINE_TOP))
    top = c["y0"] + c["rows"] * c["row_pitch"] + c["board"] * 0.5
    p = cell_pitch()
    for i in range(c["cols"] - 1):
        z = -(L - 0.06) * 0.5 + p * (i + 1) - c["divider"] * 0.5
        ms.append(member("divider%d" % i, "furniture_frame", [d - 0.02, c["rows"] * c["row_pitch"] - c["board"], c["divider"]],
                         [0, round(c["y0"] + c["rows"] * c["row_pitch"] * 0.5, 4), round(z, 4)], PINE))
    ms.append(member("cornice", "trim", [d + 0.04, 0.08, L + 0.04], [0.02, round(top + 0.04, 4), 0], PINE))
    sh = c["sign_h"]
    ms.append(member("sign", "post", [0.03, sh, L - 0.2], [d * 0.5 - 0.02, round(top + 0.08 + sh * 0.5, 4), 0], HAS, wood="weathered_pine",
                     draw={"shape": "mesh", "model": "store_post", "part": "Sign"}))
    return {
        "_doc": "The post office's case of pigeonholes (#1182, G3; the west wall's last bay, west_shelves_d, where G1's shelving stood): 1.7 m of painted pine from the material library, cupboards below (the working shelf over them), 8 columns by 4 rows of cells 19 cm wide and 18 cm clear lettered by surname, a cornice and a lettered board (POST OFFICE, SALT CREEK) over it, 2.45 m. Placed at its own size (not fitted: G1's shelving squashed when fitted smaller than its box). Mail stands in the cells (`mail_row_a` to `_d`, one per row, placed on each board). Written by tools/props/store_g3.py.",
        "id": "post_case", "fixture": True, "in_game": False, "kind": "members", "wood": "oak", "look": PINE,
        "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY, "members": ms,
    }


# --- What's in the cells ---------------------------------------------------------------------------------
MAIL = {"len": 1.6, "h": 0.165, "depth": 0.2, "z": 0.02}   # a row's one member: the four rows' mail, the front 2 cm in from the lip


def mail_row(k):
    m = MAIL
    part = "Mail" + "ABCD"[k]
    return {
        "_doc": "One row of the post office's pigeonholes with its mail (#1182, G3): letters on edge in the cells (cream, buff and blue envelopes addressed in a clerk's hand, the red stamp), bundles tied with string, a brown-paper parcel here and there, a lettered card on the board's lip at each cell (A to Z in groups, general delivery, registered, dead letters). One member (paper: ~2 kg of letters; a ball through it, the mail comes down; it comes down with its board). Drawn from glb:store_post (tools/blender/props/store_g3.py: Pillow). Written by tools/props/store_g3.py.",
        "id": "mail_row_" + "abcd"[k], "kind": "members", "fixture": True, "in_game": False, "wood": "paper", "look": HAS,
        "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY,
        "members": [member("mail", "post", [m["len"], m["h"], m["depth"]], [0, m["h"] * 0.5, m["z"]], HAS, wood="paper", solid=0.3,
                           draw={"shape": "mesh", "model": "store_post", "part": part})],
    }


# --- The books, the ink, the cash, parcels -------------------------------------------------------------------
BOOK = {"w": 0.26, "h": 0.05, "d": 0.36}          # the ledger, closed: a folio
DAYBOOK = {"w": 0.46, "h": 0.022, "d": 0.3}       # the day-book, open (two pages)
INK = {"w": 0.1, "h": 0.05, "d": 0.2}             # the inkwell and the pen beside it
CASH = {"w": 0.22, "h": 0.05, "d": 0.14}          # a tin tray of coin, a bundle of notes


def _one(id_, doc, size, part, wood="paper", solid=1.0):
    return {"_doc": doc + " One member. Drawn from glb:store_post (tools/blender/props/store_g3.py). Written by tools/props/store_g3.py.",
            "id": id_, "kind": "members", "fixture": True, "in_game": False, "wood": wood, "look": HAS,
            "splits_below": 0.3, "blow_wood_share": 0.5, "factory": FACTORY,
            "members": [member("body", "post", size, [0, size[1] * 0.5, 0], HAS, wood=wood, solid=solid,
                               draw={"shape": "mesh", "model": "store_post", "part": part})]}


def ledger_book():
    b = BOOK
    return _one("ledger_book", "The storekeeper's ledger (#1182, G3): a folio account book laid on the counter, 26 by 36 cm and 5 cm thick, a marbled-paper cover with leather corners and spine, LEDGER on its label, the page edges cream.",
                [b["w"], b["h"], b["d"]], "Ledger", solid=0.9)


def day_book():
    b = DAYBOOK
    return _one("day_book", "The day-book (#1182, G3): the counter's daily record of sales, open at today's page, ruled in columns (date, article, quantity, price, cash or credit) and written down in a clerk's hand to the foot of the left page. 46 cm open.",
                [b["w"], b["h"], b["d"]], "DayBook", solid=0.9)


def ink_set():
    b = INK
    return _one("ink_set", "A glass inkwell and a steel pen in its holder, laid beside (#1182, G3): the postmaster's and storekeeper's writing things.",
                [b["w"], b["h"], b["d"]], "Ink", wood="glass", solid=0.2)


def till_cash():
    b = CASH
    return _one("till_cash", "The till's cash (#1182, G3): a tin tray of silver and copper coin in stacks and a bundle of greenbacks under a paper band, set on the counter by the till.",
                [b["w"], b["h"], b["d"]], "Cash", wood="iron", solid=0.15)


def parcel_stack():
    return _one("parcel_stack", "Three parcels in brown paper and string waiting to go out on the stage (#1182, G3), one on another, a tag on the top.",
                [0.34, 0.2, 0.24], "Parcels", wood="paper", solid=0.6)


# --- Hung from the ceiling ------------------------------------------------------------------------------------
# The kit's hook (`hangs.hook`: what's over it, the ceiling's board, is what it hangs from: it swings when pushed and
# falls whole with its ceiling). The lamps' pattern (tools/props/saloon.py `_hanging`): no glass except a lantern's.
HUNG = {"hung_pails": {"drop": 1.15, "w": 1.3, "d": 0.6, "goods_h": 0.85, "mass": 7.0,
                       "what": "a string of seven tin pails, 10 qt, hung by their bails from a bar on two cords (four close under the bar, three on long cords behind: a hardware shop's cheapest sign)"},
        "hung_ham": {"drop": 1.2, "w": 1.3, "d": 0.4, "goods_h": 0.6, "mass": 24.0,
                     "what": "six cured hams in muslin on tarred cord from a rail, hung at two lengths"},
        "hung_lantern": {"drop": 1.05, "w": 0.95, "d": 0.3, "goods_h": 0.45, "mass": 5.0,
                         "what": "four tin barn lanterns with their globes on a bar, at two heights (for sale: the oil unfilled)"},
        "hung_boots": {"drop": 1.1, "w": 1.1, "d": 0.4, "goods_h": 0.7, "mass": 6.0,
                       "what": "four pairs of pull-on boots tied by their straps along a bar, hung at two heights"}}


def hung(kit):
    h = HUNG[kit]
    drop, w, d, gh = h["drop"], h["w"], h["d"], h["goods_h"]
    glass = ["Globe"] if kit == "hung_lantern" else []
    parts = {"hung_pails": ["Pails", "Cords"], "hung_ham": ["Hams", "Cords"], "hung_lantern": ["Lantern", "Globe"],
             "hung_boots": ["Boots", "Cords"]}[kit]
    looks = {p: ("glass:flint" if p == "Globe" else "pbr:" + kit) for p in parts}
    return {
        "_doc": "Goods hung from the store's beaded ceiling (#1182 G3, bolder in #1192 G4): %s. A prop that hangs by a hook (GlassProp, as the hanging lamp: it swings when pushed, and falls whole if the board it hangs from goes; its parts never shatter%s). Baked the gun way (tools/blender/props/store_g3.py: model %s). Written by tools/props/store_g3.py." % (
            h["what"], ", but the globes do" if glass else "", kit),
        "id": kit, "kind": "shatters", "fixture": True, "in_game": False, "replaces": "",
        "model": "glb:" + kit, "looks": looks,
        "size": store_g1.r([w, drop, d]), "mass": h["mass"], "wall": 0.0015,
        "hangs": {"hook": store_g1.r([0.0, drop, 0.0])},
        "hit": {"at": store_g1.r([0.0, gh * 0.5, 0.0]), "size": store_g1.r([w * 0.9, gh, d * 0.9])},
        "swing": {"pivot": store_g1.r([0.0, drop, 0.0]), "length": round(drop * 0.7, 3), "damping": 0.4},
        "glass": glass, "whole": [[p for p in parts if p not in glass]], "piece_mass": round(h["mass"] * 0.8, 2), "shards": 8,
        "breaks_at": 1.5 if glass else 1000.0, "shatters_kpa": 15 if glass else 1000000000.0, "heat_seconds": 30, "cut_area": 0.04,
        "factory": FACTORY,
    }


BATCH_G3 = [post_case, lambda: mail_row(0), lambda: mail_row(1), lambda: mail_row(2), lambda: mail_row(3), ledger_book, day_book, ink_set,
            till_cash, parcel_stack, lambda: hung("hung_pails"), lambda: hung("hung_ham"), lambda: hung("hung_lantern"), lambda: hung("hung_boots")]


# === Where each goes: the store's `dressing`, batch G3 =============================================================
def dressing_g3():
    out = []
    # The case in its bay, facing the room as G1's shelving did (180), and a row of mail on each board.
    bid, x, z, L = BAY_D
    out.append(e("post_case", "post_case", [x, 0.0, z], 180))
    for k in range(CASE["rows"]):
        out.append(e("mail_%d" % k, "mail_row_" + "abcd"[k], [x, board_top(k), z], 270))
    # The back counter (x 11.8 to 14.8, z 8.4 to 9.0, top COUNTER_H): the clerk's side is +z. The ledger and the
    # day-book where he stands (the use point `ledger` at 13.3/9.5), the ink beside, the cash by the till (13.3/8.75).
    # (G2's tinware moved to the counter's ends to make the room: store_g2.dressing_g2.)
    out.append(e("day_book", "day_book", [12.8, COUNTER_H, 8.7], 4))
    out.append(e("till_cash", "till_cash", [13.78, COUNTER_H, 8.58], 8))
    out.append(e("ink_back", "ink_set", [14.04, COUNTER_H, 8.74], 0))
    out.append(e("ledger_book", "ledger_book", [14.3, COUNTER_H, 8.7], 355))
    # The postmaster's high desk against the back wall (the use point `post_office` 15.5/9.15 stays clear, 0.7 m off its
    # front) with his stool, his ink and a parcel for the stage.
    out.append(e("post_desk", "owner_desk", [15.6, 0.0, 10.28], 180))
    out.append(e("post_stool", "bar_stool", [14.78, 0.0, 10.05], 0))
    out.append(e("ink_post", "ink_set", [15.25, 0.76, 10.2], 190))
    out.append(e("parcels_post", "parcel_stack", [15.95, 0.76, 10.3], 15))
    # Hung from the beaded ceiling (3.56 over the floor), each its drop under its hook (#1192, G4: bigger clusters, the lowest goods
    # 2.36 to 2.5 m up, clear of a man's 1.8 m head). Over the aisle between the two counters (x 5.6 to 11.2, the free posts'
    # line), staggered about the centre line x 8.4 so the door's view down the room stays open between them.
    ceil = 3.56
    for id_, kit, x, z, turn in (("hung_ham_a", "hung_ham", 7.0, 4.7, 0), ("hung_ham_b", "hung_ham", 9.9, 7.9, 0),
                                 ("hung_pails_a", "hung_pails", 9.9, 4.3, 0), ("hung_pails_b", "hung_pails", 6.9, 8.3, 0),
                                 ("hung_boots_a", "hung_boots", 7.0, 2.7, 0),
                                 ("hung_lantern_a", "hung_lantern", 9.9, 2.6, 0), ("hung_lantern_b", "hung_lantern", 7.4, 6.3, 0)):
        out.append(e(id_, kit, [x, round(ceil - HUNG[kit]["drop"], 3), z], turn))
    return out


def main():
    for make in BATCH_G3:
        d = make()
        path = os.path.join(KIT, d["id"] + ".json")
        with open(path, "w") as f:
            json.dump(d, f, indent=2)
            f.write("\n")
        print("wrote", os.path.relpath(path, store_g1.ROOT), "(%d members)" % len(d.get("members", [])))
    print("dressing G3: %d entries" % len(dressing_g3()))


if __name__ == "__main__":
    main()
