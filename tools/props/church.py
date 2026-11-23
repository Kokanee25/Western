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


def pew():
    # 2.5 m long, 0.85 m deep: a plain home-made pew facing +Z (people sit facing the pulpit), its two
    # end panels, a plank seat, a raked back board and a book ledge on the back of the pew in front.
    L = 2.5
    mem = [m("end_l", "post", (0.045, 0.9, 0.5), (-L / 2 + 0.0225, 0.45, 0.0), OAK),
           m("end_r", "post", (0.045, 0.9, 0.5), (L / 2 - 0.0225, 0.45, 0.0), OAK),
           m("seat", "furniture_top", (L - 0.09, 0.035, 0.4), (0.0, 0.44, 0.04), OAK_TOP),
           m("back", "furniture_frame", (L - 0.09, 0.4, 0.03), (0.0, 0.7, -0.21), OAK),
           m("ledge", "furniture_frame", (L - 0.09, 0.03, 0.14), (0.0, 0.915, -0.19), OAK)]
    return {"_doc": "A plain home-made pew, 2.5 m long (seats five), oak boards, its end panels, a plank seat and a back board; faces +Z.",
            "id": "pew", "kind": "members", "fixture": True, "in_game": True, "wood": "oak", "splits_below": 0.5,
            "blow_wood_share": 0.5, "seat": {"member": "seat", "at": [0.0, 0.46, 0.04], "share": 0.8, "hold": 0.05, "sway": 0.03},
            "members": mem, "factory": "tools/props/church.py"}


def pulpit():
    # A plain white lectern: a box base, a sloped reading desk on top, a ledge; faces +Z (the nave).
    mem = [m("body", "post", (0.62, 1.0, 0.5), (0.0, 0.5, 0.0), WHITE),
           m("desk", "furniture_top", (0.7, 0.04, 0.5), (0.0, 1.03, 0.02), WHITE_TOP, rot=(-12.0, 0.0, 0.0)),
           m("lip", "furniture_frame", (0.7, 0.05, 0.03), (0.0, 1.0, 0.27), WHITE)]
    return {"_doc": "The church's pulpit, a plain white-painted lectern with a sloped reading desk.", "id": "pulpit",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def altar_rail():
    # 3 m of rail on turned-looking balusters, white with a plain oak top rail; the rail's open at its middle
    # (the gate) in the dressing by placing two.
    L = 1.5
    mem = [m("top", "furniture_frame", (L, 0.07, 0.1), (0.0, 0.855, 0.0), OAK),
           m("base", "furniture_frame", (L, 0.08, 0.06), (0.0, 0.12, 0.0), WHITE)]
    for i in range(6):
        x = -L / 2 + 0.06 + i * (L - 0.12) / 5
        mem.append(m("bal%d" % i, "post", (0.05, 0.82, 0.05), (x, 0.41, 0.0), WHITE))
    return {"_doc": "Half of the church's altar rail (1.5 m): six balusters under an oak rail; two stand side by side with a gap for the gate.",
            "id": "altar_rail", "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def hymn_stand():
    # The hymn board on its easel stand: two slanted legs and a board with its ledge.
    mem = [m("leg_l", "post", (0.04, 1.5, 0.04), (-0.27, 0.75, -0.04), OAK),
           m("leg_r", "post", (0.04, 1.5, 0.04), (0.27, 0.75, -0.04), OAK),
           m("foot", "furniture_frame", (0.62, 0.04, 0.3), (0.0, 0.02, 0.0), OAK),
           m("board", "furniture_top", (0.5, 0.62, 0.035), (0.0, 1.2, -0.03), "lib:furniture_oak/old/top"),
           m("ledge", "furniture_frame", (0.5, 0.03, 0.08), (0.0, 0.885, 0.02), OAK)]
    return {"_doc": "The hymn board (numbers slid into its slots) on a plain stand.", "id": "hymn_stand", "kind": "members",
            "fixture": True, "in_game": True, "wood": "oak", "splits_below": 0.5, "blow_wood_share": 0.5, "members": mem,
            "factory": "tools/props/church.py"}


def wood_cross():
    mem = [m("upright", "post", (0.08, 1.1, 0.04), (0.0, 0.55, 0.0), wood="weathered_pine"),
           m("arm", "furniture_frame", (0.5, 0.07, 0.035), (0.0, 0.85, 0.0), wood="weathered_pine")]
    return {"_doc": "A weathered wooden grave cross, 1.1 m, hand-lettered (the lettering unreadable).", "id": "wood_cross",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def headboard():
    mem = [m("post_l", "post", (0.05, 0.85, 0.05), (-0.27, 0.425, 0.0), wood="weathered_pine"),
           m("post_r", "post", (0.05, 0.85, 0.05), (0.27, 0.425, 0.0), wood="weathered_pine"),
           m("board", "furniture_frame", (0.59, 0.34, 0.03), (0.0, 0.63, 0.0), wood="weathered_pine")]
    return {"_doc": "A grave's headboard: a board between two posts, the name painted and weathered off.", "id": "headboard",
            "kind": "members", "fixture": True, "in_game": True, "wood": "weathered_pine", "splits_below": 0.5,
            "blow_wood_share": 0.5, "members": mem, "factory": "tools/props/church.py"}


def grave_marker():
    mem = [m("stone", "post", (0.45, 0.7, 0.1), (0.0, 0.35, 0.0), wood="stone")]
    return {"_doc": "A small stone marker, a squared grey slab.", "id": "grave_marker", "kind": "members", "fixture": True,
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
    for f in (church_bell, pew, pulpit, altar_rail, hymn_stand, wood_cross, headboard, grave_marker):
        d = f()
        with open(os.path.join(KIT, d["id"] + ".json"), "w") as fh:
            json.dump(d, fh, indent=2)
        print("wrote", d["id"], len(d["members"]), "members")
