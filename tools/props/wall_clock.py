"""The town's wall clock (#789, #1030): a regulator in the pattern Connecticut makers sold to banks, depots,
stores and saloons through the 1870s-80s (Seth Thomas's Regulator No. 2, Ansonia's and Waterbury's
long-drop regulators): a walnut case hung on the wall, about 36 in high, a 12 in painted dial behind the
upper glass of a full-length door, the brass-faced bob swinging behind the lower glass with REGULATOR in
gilt on it, a moulded cornice and a sawn crest on top, a moulded base and a scrolled drop under it.
Time only, eight-day, one winding hole. The maker's name on the dial and the label is invented (no real
trade mark): "H. ASHBY & SONS, BRISTOL, CONN.".

Writes assets/props/kit/wall_clock.json. The case is the material library's walnut, members as the
back bar's woodwork is (its grain, wear and arrises, profiles cut in it); the dial, bezel, hands,
pendulum and the glass's gilt letters are modelled and baked in tools/blender/props/wall_clock.py from
the numbers here. The hands and the pendulum are WallClock's (src/props/wall_clock.gd): they show
DayCycle's time and swing by sums each frame, only when it's seen or near.

    python3 tools/props/wall_clock.py
    ~/.venvs/bpy/bin/python tools/blender/props/wall_clock.py     (then godot --headless --import)

Prop space: the wall's face z = 0, the clock toward +z, the origin the bottom of its drop at its middle.
Hang it with its dial's middle about 1.9 m up (its origin ~1.2 m).
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets/props/kit/wall_clock.json")

WOOD = "lib:furniture_walnut/few"
# The case (metres, inches in the comments: Seth Thomas No. 2 is 36 x 16.5 x 4.75 in).
W = 0.43            # the body's width over its sides (17 in)
D = 0.115           # the body's depth, back to the door's back
T = 0.016           # its boards
BODY = (0.12, 0.88)  # the body's bottom and top (y)
DOOR_T = 0.022       # the door's frame
DOOR_Z = D + DOOR_T * 0.5
STILE = 0.045
RAIL_LOW = (0.12, 0.17)
RAIL_MID = (0.46, 0.50)
RAIL_TOP = (0.84, 0.88)
OPEN_X = W * 0.5 - STILE   # each opening's half width (0.17)
GLASS_Z = D + 0.004        # the glass in the door's rebate, behind its face
# The dial (a 12 in painted zinc dial, a square sheet with its spandrels behind the upper glass).
DIAL_C = (0.0, 0.67)
DIAL_R = 0.152             # the dial's painted circle (12 in across)
DIAL_Z = 0.090             # the dial's face
SHEET = OPEN_X + 0.008     # the dial sheet's half width (it runs under the door's frame)
SECONDS_C = (0.0, DIAL_C[1] + 0.068)   # the seconds bit, over the middle
SECONDS_R = 0.024
WIND = (0.0, DIAL_C[1] - 0.079)        # the one winding hole (time only), under the maker's name
# The hands (spade, blued steel), each pointing at 12 in the model; WallClock turns them about the
# dial's middle (the seconds about the bit's).
HOUR_L, MINUTE_L, SECOND_L = 0.083, 0.122, 0.021
HAND_Z = {"Hour": DIAL_Z + 0.004, "Minute": DIAL_Z + 0.007, "Seconds": DIAL_Z + 0.003}
# The pendulum: hung behind the dial from the movement's suspension, a wood rod to a brass-faced
# lenticular bob seen through the lower glass.
PIVOT = (0.0, 0.79, 0.045)
BOB_C = (0.0, 0.29)
BOB_R = 0.058
SWING_DEG = 3.2            # its arc each way (a regulator's few degrees)
# A pendulum's period from its length to the bob's middle (2 pi sqrt(L/g)): ~1.42 s, a beat (a tick)
# each 0.71 s, 85 a minute, as a regulator's short drop beats.
LENGTH = PIVOT[1] - BOB_C[1]
PERIOD = 2.0 * math.pi * math.sqrt(LENGTH / 9.81)


def r(v):
    return [round(float(x), 4) for x in v]


def member(id_, kind, size, at, look=WOOD, **kw):
    d = {"id": id_, "kind": kind, "size": r(size), "at": r(at), "look": look}
    d.update(kw)
    return d


def prof(name, along, across, up, *args):
    d = {"shape": "profile", "profile": name, "along": along, "across": across, "up": up}
    if args:
        d["args"] = list(args)
    return d


def mesh(part, look="pbr:wall_clock"):
    return {"look": look, "draw": {"shape": "mesh", "model": "wall_clock", "part": part}}


def crest_outline():
    """The sawn crest: a low pediment with a scroll each end and a rounded peak (in its own x, y,
    from its bottom middle)."""
    pts = [(-0.17, 0.0), (0.17, 0.0), (0.17, 0.018)]
    # The right half's top, out from the middle: a rounded peak, a dip, a scroll at the end.
    right = []
    for k in range(13):
        x = 0.17 * k / 12.0
        y = 0.075 - 0.05 * (x / 0.17) ** 1.4 + 0.012 * math.sin(math.pi * min(1.0, x / 0.05)) * (1 if x < 0.05 else 0)
        if x > 0.12:
            y += 0.012 * math.sin(math.pi * (x - 0.12) / 0.05)
        right.append((x, max(0.018, y)))
    pts += list(reversed(right))[:-1]
    pts += [(-x, y) for x, y in right]
    pts.append((-0.17, 0.018))
    return [[round(x, 4), round(y, 4)] for x, y in pts]


def drop_outline():
    """The scrolled drop under the base: a shallow ogee each side to a round boss at the middle."""
    pts = []
    for k in range(17):
        x = -0.15 + 0.3 * k / 16.0
        t = abs(x) / 0.15
        y = 0.065 - 0.045 * (1.0 - math.cos(math.pi * t)) * 0.5 - 0.02 * t ** 3
        pts.append((x, max(0.0, y)))
    out = [(0.15, 0.07), (-0.15, 0.07)]
    # Bottom edge, left to right (anticlockwise seen from the front: top right -> top left -> down the
    # left -> along the bottom -> up the right).
    bottom = [(x, 0.07 - y) for x, y in pts]
    return [[round(x, 4), round(y, 4)] for x, y in out + bottom]


def build():
    yb, yt = BODY
    h = yt - yb
    members = [
        member("back", "board", [W - 2 * T, h, 0.012], [0, yb + h * 0.5, 0.006],
               dress=[mesh("Label", "pbr:wall_clock_dial")]),
        member("side_l", "board", [T, h, D - 0.012], [-(W - T) * 0.5, yb + h * 0.5, 0.012 + (D - 0.012) * 0.5]),
        member("side_r", "board", [T, h, D - 0.012], [(W - T) * 0.5, yb + h * 0.5, 0.012 + (D - 0.012) * 0.5]),
        # The dial on its board, the movement behind it (the works: a ball through here stops it).
        member("dial_board", "board", [W - 2 * T, RAIL_TOP[0] - RAIL_MID[1], 0.012],
               [0, (RAIL_MID[1] + RAIL_TOP[0]) * 0.5, DIAL_Z - 0.0075],
               dress=[mesh("Dial", "pbr:wall_clock_dial"), mesh("Bezel"), mesh("Works")]),
        # The door: two stiles and three rails, chamfered inside, glazed above and below.
        member("stile_l", "stud", [STILE, h, DOOR_T], [-(W * 0.5 - STILE * 0.5), yb + h * 0.5, DOOR_Z],
               draw=prof("chamfered", "y", "x", "z", 0.005)),
        member("stile_r", "stud", [STILE, h, DOOR_T], [W * 0.5 - STILE * 0.5, yb + h * 0.5, DOOR_Z],
               look=WOOD + "/grip", draw=prof("chamfered", "y", "x", "z", 0.005),
               dress=[mesh("Latch")]),
    ]
    for name, (a, b) in (("rail_low", RAIL_LOW), ("rail_mid", RAIL_MID), ("rail_top", RAIL_TOP)):
        members.append(member(name, "furniture_frame", [W - 2 * STILE, b - a, DOOR_T], [0, (a + b) * 0.5, DOOR_Z],
                              draw=prof("chamfered", "x", "y", "z", 0.005)))
    members += [
        member("glass_top", "glass", [OPEN_X * 2 + 0.01, RAIL_TOP[0] - RAIL_MID[1] + 0.01, 0.003],
               [0, (RAIL_MID[1] + RAIL_TOP[0]) * 0.5, GLASS_Z], look="glass:pane", wood="glass"),
        member("glass_low", "glass", [OPEN_X * 2 + 0.01, RAIL_MID[0] - RAIL_LOW[1] + 0.01, 0.003],
               [0, (RAIL_LOW[1] + RAIL_MID[0]) * 0.5, GLASS_Z], look="glass:pane", wood="glass",
               dress=[mesh("Lettering")]),
        # The cornice over the top (an ogee, its cap a rounded board) and the crest sawn on it.
        member("cornice", "furniture_frame", [W + 0.05, 0.05, D + DOOR_T + 0.03],
               [0, yt + 0.025, (D + DOOR_T + 0.03) * 0.5], draw=prof("ogee", "x", "z", "y")),
        member("cap", "furniture_frame", [W + 0.07, 0.016, D + DOOR_T + 0.045],
               [0, yt + 0.058, (D + DOOR_T + 0.045) * 0.5], draw=prof("rounded", "x", "z", "y", 0.006, [0, 1])),
        member("crest", "trim", [0.34, 0.08, 0.018], [0, yt + 0.066 + 0.04, D * 0.55],
               draw={"shape": "cut", "plane": "xy", "outline": crest_outline()}),
        # The base under the body, a rounded moulding, and the scrolled drop under it.
        member("base", "furniture_frame", [W + 0.04, 0.05, D + DOOR_T + 0.025],
               [0, 0.07 + 0.025, (D + DOOR_T + 0.025) * 0.5], draw=prof("ogee", "x", "z", "-y")),
        member("drop", "trim", [0.30, 0.07, 0.018], [0, 0.035, D * 0.6],
               draw={"shape": "cut", "plane": "xy", "outline": drop_outline()}),
    ]
    # The crest and drop outlines were laid from their bottom middle; a cut is laid about its middle.
    for m in members:
        if m["id"] == "crest":
            m["draw"]["outline"] = [[x, round(y - 0.04, 4)] for x, y in m["draw"]["outline"]]
        if m["id"] == "drop":
            m["draw"]["outline"] = [[x, round(y - 0.035, 4)] for x, y in m["draw"]["outline"]]
    return {
        "_doc": __doc__.split("\n\nWrites")[0].replace("\n", " ") + " Hung on two nails through its back "
                "(KitProp `hangs`): it falls when its wall board goes. Its glass breaks as a window's; a ball "
                "through its works (`clock.works`) stops it at that minute (#789: a clue for the mission cards). "
                "~6.5 kg. Written by tools/props/wall_clock.py.",
        "id": "wall_clock",
        "kind": "members",
        "fixture": True,
        "in_game": False,
        "wood": "walnut",
        "anchor": "wall",
        "drawn_bounds": True,
        "splits_below": 0.4,
        "blow_wood_share": 0.5,
        "hangs": {"nails": [[0.0, BODY[1] - 0.05, 0.004], [0.0, BODY[0] + 0.06, 0.004]]},
        "factory": "tools/props/wall_clock.py",
        "clock": {
            "_doc": "WallClock (src/props/wall_clock.gd): the hands (model parts, each at 12 in the model) turned "
                    "about `centre` (the seconds about `seconds_centre`); the pendulum about `pivot`, `swing` degrees "
                    "each way, a beat (a tick) each half `period`; `works` the box a ball stops it through; the "
                    "member it stops with if it breaks.",
            "model": "wall_clock",
            "look": "pbr:wall_clock",
            "centre": r([DIAL_C[0], DIAL_C[1], 0.0]),
            "seconds_centre": r([SECONDS_C[0], SECONDS_C[1], 0.0]),
            "pivot": r(PIVOT),
            "swing": SWING_DEG,
            "period": round(PERIOD, 4),
            "works": {"at": r([0, (RAIL_MID[1] + RAIL_TOP[0]) * 0.5, 0.05]), "size": r([W - 2 * T, RAIL_TOP[0] - RAIL_MID[1], 0.09])},
            "members": ["dial_board"],
            "tick": {"unit_size": 0.35, "volume_db": -6.0, "hear_within": 9.0},
            "near": 14.0,
        },
        "members": members,
    }


def main():
    d = build()
    open(OUT, "w").write(json.dumps(d, indent=2) + "\n")
    print("wall_clock: %d members, pendulum %.3f m, period %.3f s" % (len(d["members"]), LENGTH, PERIOD))


if __name__ == "__main__":
    main()
