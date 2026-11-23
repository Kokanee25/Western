"""The church and cemetery's props (#1142; the prop lab's recipe, docs/briefs/prop-factory.md): kit files
for the pew, the pulpit, the altar rail, the hymn stand, a wooden grave cross, a headboard and a stone
marker, written from the numbers here (a change is one number and a re-run).

    python3 tools/props/church.py     # writes assets/props/kit/<id>.json

Made of boxes (members) in the material library's woods: pews in oak, the pulpit and rail in the church's
white-painted pine, the graves' wood weathered silver-grey. Few members each (the valley is near Jolt's
limit, #865). References: the sheet's nave and pulpit views (experiments/building_lab/church/sheet/).
"""
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
KIT = os.path.join(ROOT, "assets", "props", "kit")
OAK = "lib:furniture_oak/few"
OAK_TOP = OAK + "/top"
WHITE = "lib:furniture_painted_pine/few"
WHITE_TOP = WHITE + "/top"


def r(v):
    return [round(x, 4) for x in v]


def m(id, kind, size, at, look=None, wood=None, rot=None):
    d = {"id": id, "kind": kind, "size": r(size), "at": r(at)}
    if wood:
        d["wood"] = wood
    if look:
        d["look"] = look
    if rot:
        d["rot"] = r(rot)
    return d


def arc(cx, cy, r, a0, a1, n):
    """Points on a circle's arc (degrees, counter-clockwise from +a)."""
    import math
    return [[round(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)), 4), round(cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n)), 4)] for i in range(n + 1)]


def pew():
    # 2.5 m long, a period pew (#1170; Sean 2026-11-23: "the pews don't look right"), facing +Z (people sit facing
    # the pulpit): two end boards cut to shape (the arm scrolled round at the front, rising in a curve to a rounded
    # top at the back, a notch between the feet), a seat of two boards with a gap, a panelled back sloping back
    # 10 degrees under a rounded cap rail, and a book rail on its back for the pew behind. Painted (the inside's
    # cream), not the orange oak of the slab pews. References: Upjohn's "Rural Architecture" (1852) pews; the sheet's nave.
    L = 2.5
    H, D = 0.95, 0.6
    end = ([[0.27, -0.475], [0.27, 0.12]] + arc(0.235, 0.17, 0.05, -30.0, 200.0, 8)
           + [[0.14, 0.2], [0.04, 0.22], [-0.06, 0.28], [-0.15, 0.37]] + arc(-0.24, 0.395, 0.08, 20.0, 180.0, 6)
           + [[-0.33, -0.475], [-0.2, -0.475], [-0.17, -0.43], [0.13, -0.43], [0.16, -0.475]])
    ends = []
    for side, x in (("l", -L / 2 + 0.025), ("r", L / 2 - 0.025)):
        e = m("end_" + side, "post", (0.05, H, D + 0.06), (x, H / 2, -0.03), WHITE)
        e["draw"] = {"shape": "cut", "plane": "zy", "outline": end}
        ends.append(e)
    a = -10.0
    import math
    back_h = 0.46
    bz = -0.2 - back_h * 0.5 * math.sin(math.radians(-a))
    back = m("back", "furniture_frame", (L - 0.1, back_h, 0.025), (0.0, 0.47 + back_h * 0.5, bz), WHITE, rot=(a, 0.0, 0.0))
    back["draw"] = {"shape": "panel", "out": "z", "bevel": 0.03}
    top_z = -0.2 - back_h * math.sin(math.radians(-a))
    cap = m("cap", "furniture_frame", (L - 0.1, 0.035, 0.06), (0.0, 0.47 + back_h + 0.01, top_z), WHITE, rot=(a, 0.0, 0.0))
    cap["draw"] = {"shape": "profile", "profile": "rounded", "along": "x", "up": "y", "args": [0.012]}
    mem = ends + [m("seat", "furniture_top", (L - 0.1, 0.03, 0.2), (0.0, 0.445, 0.115), WHITE_TOP),
                  m("seat_b", "furniture_top", (L - 0.1, 0.03, 0.19), (0.0, 0.445, -0.09), WHITE_TOP),
                  m("rail", "furniture_frame", (L - 0.1, 0.06, 0.03), (0.0, 0.4, 0.2), WHITE),
                  back, cap,
                  m("book_rail", "furniture_frame", (L - 0.1, 0.02, 0.1), (0.0, 0.8, top_z - 0.02), WHITE),
                  m("book_lip", "furniture_frame", (L - 0.1, 0.05, 0.015), (0.0, 0.825, top_z - 0.065), WHITE)]
    return {"_doc": "A period pew, 2.5 m long (seats five): scrolled end boards, a two-board seat, a panelled back sloping back under a cap rail, a book rail behind; painted cream; faces +Z.",
            "id": "pew", "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "seat": {"member": "seat", "at": [0.0, 0.46, 0.04], "share": 0.8, "hold": 0.05, "sway": 0.03},
            "members": mem, "factory": "tools/props/church.py"}


def pulpit():
    # A white box pulpit (#1170, the sheet's pulpit view): a panelled front and sides on a plinth, a moulded cap round
    # its top, a sloped reading desk on it; faces +Z (the nave).
    W_, D_, H_ = 0.95, 0.62, 1.08
    front = m("front", "post", (W_, H_ - 0.1, 0.04), (0.0, 0.1 + (H_ - 0.1) / 2, D_ / 2 - 0.02), WHITE)
    front["draw"] = {"shape": "panel", "out": "z", "bevel": 0.04}
    mem = [m("plinth", "post", (W_ + 0.06, 0.1, D_ + 0.06), (0.0, 0.05, 0.0), WHITE), front]
    for side, x in (("l", -W_ / 2 + 0.02), ("r", W_ / 2 - 0.02)):
        sd = m("side_" + side, "post", (0.04, H_ - 0.1, D_ - 0.04), (x, 0.1 + (H_ - 0.1) / 2, -0.02), WHITE)
        sd["draw"] = {"shape": "panel", "out": "x", "bevel": 0.04}
        mem.append(sd)
    cap = m("cap", "furniture_frame", (W_ + 0.05, 0.05, 0.07), (0.0, H_ + 0.025, D_ / 2 - 0.01), WHITE)
    cap["draw"] = {"shape": "profile", "profile": "ogee", "along": "x", "up": "y", "across": "z"}
    mem += [cap, m("desk", "furniture_top", (W_ - 0.05, 0.035, 0.45), (0.0, H_ + 0.08, 0.06), WHITE_TOP, rot=(-14.0, 0.0, 0.0)),
            m("lip", "furniture_frame", (W_ - 0.05, 0.04, 0.025), (0.0, H_ + 0.07, 0.3), WHITE)]
    return {"_doc": "The church's pulpit: a white-painted box, panelled front and sides on a plinth, a moulded cap, a sloped reading desk.", "id": "pulpit",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def altar_rail():
    # A plain rail (#1170: the sheet's "one plain wooden rail", not balusters): two square posts, a moulded top rail
    # and a low rail between; two stand either side of the chancel's step with the way between.
    L = 1.5
    top = m("top", "furniture_frame", (L, 0.07, 0.11), (0.0, 0.855, 0.0), WHITE)
    top["draw"] = {"shape": "profile", "profile": "handrail", "along": "x", "up": "y"}
    mem = [top, m("low", "furniture_frame", (L - 0.14, 0.06, 0.04), (0.0, 0.2, 0.0), WHITE)]
    for i, x in enumerate((-L / 2 + 0.05, L / 2 - 0.05)):
        mem.append(m("post%d" % i, "post", (0.08, 0.82, 0.08), (x, 0.41, 0.0), WHITE))
    return {"_doc": "Half of the church's plain altar rail (1.5 m): two posts, a moulded top rail, a low rail; two stand with the way between.",
            "id": "altar_rail", "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def hymn_stand():
    # The hymn board on its stand (#1170: big enough to read across the nave): a framed board with three rows of
    # number cards slid into it, on two legs and a foot.
    mem = [m("leg_l", "post", (0.045, 1.8, 0.045), (-0.31, 0.9, -0.04), WHITE),
           m("leg_r", "post", (0.045, 1.8, 0.045), (0.31, 0.9, -0.04), WHITE),
           m("foot", "furniture_frame", (0.7, 0.04, 0.32), (0.0, 0.02, 0.0), WHITE),
           m("board", "furniture_top", (0.575, 0.78, 0.03), (0.0, 1.35, -0.02), "lib:furniture_oak/old/top"),
           m("ledge", "furniture_frame", (0.575, 0.03, 0.08), (0.0, 0.945, 0.02), WHITE)]
    for i in range(3):
        mem.append(m("card%d" % i, "furniture_frame", (0.42, 0.13, 0.008), (0.0, 1.6 - i * 0.22, 0.0), "prop:ivory"))
    return {"_doc": "The hymn board (three numbers slid into its slots) on a plain white stand.", "id": "hymn_stand", "kind": "members",
            "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5, "blow_wood_share": 0.5, "members": mem,
            "factory": "tools/props/church.py"}


def stove_pipe():
    # The church stove's pipe on up from the box stove's last joint (3.22 m) through the ceiling (#1170): one more
    # joint, iron, as long as the nave's ceiling is high over it (church_spec.py's PLATE 5.3 less the floor's 0.95).
    L = 5.3 - 0.95 - 3.22 + 0.06
    p = m("pipe", "post", (0.15, L, 0.15), (0.0, L / 2, 0.0), look="prop:iron", wood="iron")
    p["draw"] = {"shape": "lathe", "profile": [[0.0, 0.0], [0.075, 0.0], [0.075, L], [0.0, L]], "segments": 14}
    return {"_doc": "The church stove's pipe up through the ceiling (one joint over the box stove's own).", "id": "church_stove_pipe",
            "kind": "members", "fixture": True, "in_game": True, "wood": "iron", "splits_below": 0.5, "blow_wood_share": 0.5,
            "members": [p], "factory": "tools/props/church.py"}


def wood_cross():
    # Heavier (#1170: the critic's "thick weathered crosses carrying name boards"): a 4 in upright and arm, a name
    # board nailed over the crossing.
    mem = [m("upright", "post", (0.1, 1.2, 0.09), (0.0, 0.6, 0.0), wood="weathered_pine"),
           m("arm", "furniture_frame", (0.62, 0.1, 0.08), (0.0, 0.88, 0.0), wood="weathered_pine"),
           m("name", "furniture_frame", (0.3, 0.14, 0.02), (0.0, 0.88, 0.05), wood="weathered_pine")]
    return {"_doc": "A weathered wooden grave cross, 1.2 m, 4 in timbers, a name board over the crossing (the lettering weathered off).", "id": "wood_cross",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def headboard():
    board = m("board", "furniture_frame", (0.62, 0.5, 0.035), (0.0, 0.62, 0.0), wood="weathered_pine")
    board["draw"] = {"shape": "cut", "plane": "xy", "outline": [[-0.31, -0.25], [0.31, -0.25], [0.31, 0.12]] + arc(0.0, 0.12, 0.31, 0.0, 180.0, 10)[1:]}
    mem = [m("post_l", "post", (0.06, 0.6, 0.06), (-0.27, 0.3, -0.05), wood="weathered_pine"),
           m("post_r", "post", (0.06, 0.6, 0.06), (0.27, 0.3, -0.05), wood="weathered_pine"), board]
    return {"_doc": "A grave's headboard: a board with a round top on two posts, the name painted and weathered off.", "id": "headboard",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def grave_marker():
    mem = [m("stone", "post", (0.45, 0.7, 0.1), (0.0, 0.35, 0.0), wood="stone")]
    return {"_doc": "A small stone marker, a squared grey slab.", "id": "grave_marker", "kind": "members", "fixture": True,
            "in_game": True, "wood": "stone", "splits_below": 0.5, "blow_wood_share": 0.5, "members": mem,
            "factory": "tools/props/church.py"}


def headstone_arched():
    # An arched headstone (#1170; the sheet's graveyard): a slab with a round head on a base stone, the town's grey
    # stone (cut from the box: its collision stays the slab's box).
    st = m("stone", "post", (0.5, 0.82, 0.11), (0.0, 0.12 + 0.41, 0.0), wood="stone")
    st["draw"] = {"shape": "cut", "plane": "xy", "outline": [[-0.25, -0.41], [0.25, -0.41], [0.25, 0.16]] + arc(0.0, 0.16, 0.25, 0.0, 180.0, 12)[1:]}
    mem = [m("base", "post", (0.64, 0.12, 0.26), (0.0, 0.06, 0.0), wood="stone"), st]
    return {"_doc": "An arched headstone on a base stone, grey.", "id": "headstone_arched", "kind": "members", "fixture": True,
            "in_game": True, "wood": "stone", "splits_below": 0.5, "blow_wood_share": 0.5, "members": mem,
            "factory": "tools/props/church.py"}


def church_bell():
    # The cast bell (about 150 kg, 0.76 m across the lip) on a plain four-post stand of timber: the belfry's
    # floor under it, its top and bottom rails, the bell standing on four posts at its corners (a box drawn as
    # a bell by a lathe; `solid` is the share of its box that is bronze).
    prof = [[0.38, 1.56], [0.37, 1.61], [0.33, 1.71], [0.27, 1.89], [0.2, 2.11], [0.15, 2.29], [0.1, 2.37], [0.0, 2.39]]
    mem = []
    for i, (sx, sz) in enumerate([(-0.3, -0.3), (0.3, -0.3), (-0.3, 0.3), (0.3, 0.3)]):
        mem.append(m("post%d" % i, "post", (0.12, 1.55, 0.12), (sx, 0.775, sz), wood="framing"))
    b = m("bell", "furniture_top", (0.76, 0.83, 0.76), (0.0, 1.97, 0.0), look="prop:brass", wood="iron")
    b["draw"] = {"shape": "lathe", "profile": prof, "segments": 28}
    b["solid"] = 0.035
    mem.append(b)
    return {"_doc": "The church's bell: cast bronze, 0.76 m across the lip, on a four-post timber stand in the belfry.", "id": "church_bell",
            "kind": "members", "fixture": True, "in_game": True, "wood": "framing", "splits_below": 0.5, "blow_wood_share": 0.5,
            "members": mem, "factory": "tools/props/church.py"}


if __name__ == "__main__":
    for f in (church_bell, pew, pulpit, altar_rail, hymn_stand, stove_pipe, wood_cross, headboard, grave_marker, headstone_arched):
        d = f()
        with open(os.path.join(KIT, d["id"] + ".json"), "w") as fh:
            json.dump(d, fh, indent=2)
        print("wrote", d["id"], len(d["members"]), "members")
