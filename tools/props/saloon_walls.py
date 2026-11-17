"""Saloon B's walls (#1030, the prop lab's S5): kit files for the regulator wall clock.

    python3 tools/props/saloon_walls.py       # writes assets/props/kit/wall_clock*.json

The clock: a Seth Thomas / Ansonia style regulator, a long case (a hood with the dial over a trunk with
its pendulum behind glass), ~1.16 m tall, 0.40 wide, 0.17 deep, hung on one nail through the back board.
`wall_clock_case` is the case of members (breaks, burns, falls like any hung prop); `wall_clock` (kind
`clock`, src/props/wall_clock.gd) is the part: the case and the dial, hands and pendulum that move by maths
(DayCycle's time), and its tick. Prop space: origin the case's bottom centre, its back at z 0, facing +Z.
References: a Seth Thomas Regulator No. 2 and an Ansonia "Regulator A" (a 1.0-1.3 m oak or walnut case,
a 12 in dial under a glass door, the trunk door glazed, a brass-bobbed seconds-beating pendulum); ours
beats a shorter pendulum so it fits the case (one beat 0.7 s).
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets/props/kit")


def m(id_, kind, size, at, **kw):
    d = {"id": id_, "kind": kind, "size": [round(v, 4) for v in size], "at": [round(v, 4) for v in at]}
    d.update(kw)
    return d


def case():
    mem = []
    W, D = 0.30, 0.16           # the trunk's width and depth
    HW = 0.36                   # the hood's width
    mem.append(m("base", "furniture_top", [0.34, 0.07, 0.17], [0, 0.035, 0.085]))
    # The trunk: back board, two sides, the glazed door's frame and its glass.
    mem.append(m("trunk_back", "board", [W, 0.66, 0.012], [0, 0.40, 0.006]))
    for s, x in (("l", -0.1375), ("r", 0.1375)):
        mem.append(m("trunk_side_" + s, "post", [0.025, 0.66, D - 0.02], [x, 0.40, 0.012 + (D - 0.02) / 2]))
        mem.append(m("trunk_stile_" + s, "post", [0.03, 0.66, 0.02], [x * 0.98, 0.40, 0.15]))
    mem.append(m("trunk_rail_top", "furniture_frame", [W, 0.04, 0.02], [0, 0.69, 0.15]))
    mem.append(m("trunk_rail_bottom", "furniture_frame", [W, 0.04, 0.02], [0, 0.09, 0.15]))
    mem.append(m("trunk_glass", "glass", [0.24, 0.56, 0.004], [0, 0.39, 0.151], wood="glass", look="glass:clear"))
    # The hood: sides, top and bottom boards, the dial plate, the glazed door.
    HB, HT = 0.72, 1.10
    hc, hh = (HB + HT) / 2, HT - HB
    mem.append(m("hood_back", "board", [HW, hh, 0.012], [0, hc, 0.006]))
    for s, x in (("l", -0.1675), ("r", 0.1675)):
        mem.append(m("hood_side_" + s, "post", [0.025, hh, D - 0.02], [x, hc, 0.012 + (D - 0.02) / 2]))
        mem.append(m("hood_stile_" + s, "post", [0.03, hh, 0.02], [x * 0.985, hc, 0.15]))
    mem.append(m("hood_floor", "furniture_frame", [HW, 0.02, D - 0.02], [0, HB + 0.01, 0.012 + (D - 0.02) / 2]))
    mem.append(m("hood_rail_top", "furniture_frame", [HW - 0.03, 0.035, 0.02], [0, HT - 0.0175, 0.15]))
    mem.append(m("hood_rail_bottom", "furniture_frame", [HW - 0.03, 0.035, 0.02], [0, HB + 0.0175, 0.15]))
    mem.append(m("dial_plate", "board", [0.31, hh - 0.04, 0.012], [0, hc, 0.105]))
    mem.append(m("hood_glass", "glass", [0.30, hh - 0.075, 0.004], [0, hc, 0.151], wood="glass", look="glass:clear"))
    # The cornice: a flat cap on a cove, a finial-less top (the period's plain regulator).
    mem.append(m("cornice", "furniture_top", [0.40, 0.03, 0.18], [0, HT + 0.015, 0.09]))
    mem.append(m("cap", "furniture_top", [0.37, 0.025, 0.16], [0, HT + 0.0425, 0.085]))
    return {
        "_doc": "A regulator wall clock's case (#1030, tools/props/saloon_walls.py): oak, a hood over a "
                "glazed trunk, hung on one nail through its back board. The works (dial, hands, pendulum, tick) "
                "are `wall_clock`'s; this is the case alone: it breaks, burns and falls as any hung prop.",
        "id": "wall_clock_case",
        "kind": "members",
        "wood": "oak",
        "look": "lib:furniture_oak/old",
        "splits_below": 0.4,
        "blow_wood_share": 0.5,
        "hangs": {"nails": [[0.0, 0.85, 0.006]]},
        "members": mem,
    }


def clock():
    return {
        "_doc": "The regulator wall clock (#1030; Sean 2026-11-16, #789: 'the clock needs to be a real clock'): "
                "`wall_clock_case` with a dial, two hands and a pendulum that show DayCycle's time (the town's "
                "local time) and swing, moved by maths each frame only while it's on screen and near, and a "
                "tick (GameAudio, placed: heard in a quiet room, lost under a busy night). WallClock, "
                "src/props/wall_clock.gd. The bank, depot, store and homes reuse it (`size`, `case` and `dial` "
                "are the only things a shelf clock changes).",
        "id": "wall_clock",
        "kind": "clock",
        "in_game": True,
        "case": "wall_clock_case",
        "size": [0.40, 1.16, 0.18],
        "dial": {"at": [0.0, 0.91, 0.114], "radius": 0.135},
        "hands": {"hour": 0.075, "minute": 0.11},
        "pendulum": {"at": [0.0, 0.665, 0.075], "length": 0.46, "bob": 0.042, "swing_deg": 4.5, "period": 1.4},
        "tick": {"reach": 16.0, "volume_db": -15.0, "unit_size": 1.2, "din_db": 2.0, "din_reach": 9.0},
    }


def foot_rail():
    """The brass foot rail along the bar's front (#1030): a 2 in tube 2.9 m long (a bar section's), 0.21 m
    off the floor on three brass stanchions. Its own kit prop, not a member of `bar` (saloon B's bars stand
    in the valley: a member added there tips the card-game chair tests, #834). Ref: the Trinidad saloon's
    arm rail (refs/saloon/), the same brass a foot lower."""
    r = 0.025
    tube = m("rail", "post", [2.9, 2 * r, 2 * r], [0, 0.21, 0], wood="iron", look="prop:brass", solid=0.07,
             draw={"shape": "lathe", "profile": [[0, -1.45], [r, -1.45], [r, 1.45], [0, 1.45]], "segments": 12,
                   "rot": [0, 0, 90], "at": [0, 0.21, 0]})
    mem = [tube]
    for i, x in enumerate((-1.35, 0.0, 1.35)):
        mem.append(m("stanchion%d" % i, "post", [0.03, 0.185, 0.03], [x, 0.0925, 0], wood="iron", look="prop:brass", solid=0.2,
                     draw={"shape": "lathe", "profile": [[0, 0], [0.04, 0.0], [0.04, 0.012], [0.014, 0.02], [0.014, 0.17], [0.022, 0.185], [0, 0.185]],
                           "segments": 10, "at": [x, 0.0, 0], "rot": [0, 0, 0]}))
    return {
        "_doc": "The bar's brass foot rail (#1030, tools/props/saloon_walls.py): a 2 in brass tube 2.9 m long on three stanchions, "
                "0.21 m off the floor, one per bar section, 0.12 m in front of the bar's front edge. Its own kit prop.",
        "id": "foot_rail", "kind": "members", "fixture": True, "in_game": False, "wood": "iron",
        "splits_below": 0.1, "blow_wood_share": 0.3, "members": mem,
    }


def rifle_pegs():
    """A rifle on two pegs (#1030): a lever-action carbine of 1873's shape, ~1.0 m, laid on two oak pegs
    on back plates, hung on two nails. Origin the rail's centre at the wall; the rifle lies along x."""
    mem = []
    for i, x in enumerate((-0.30, 0.12)):
        mem.append(m("plate%d" % i, "furniture_frame", [0.07, 0.07, 0.014], [x, 0.0, 0.007], look="lib:furniture_oak/old"))
        mem.append(m("peg%d" % i, "post", [0.022, 0.022, 0.095], [x, 0.0, 0.0615], look="lib:furniture_oak/old"))
        mem.append(m("lip%d" % i, "cripple", [0.022, 0.03, 0.02], [x, 0.014, 0.0985], look="lib:furniture_oak/old"))
    y, z = 0.0345, 0.052
    b = 0.0125
    mem.append(m("barrel", "furniture_top", [0.50, 2 * b, 2 * b], [-0.26, y, z], wood="iron", look="prop:iron", solid=0.4,
                 draw={"shape": "lathe", "profile": [[0, -0.25], [b, -0.25], [b, 0.25], [0, 0.25]], "segments": 8,
                       "rot": [0, 0, 90], "at": [-0.26, y, z]}))
    mem.append(m("receiver", "furniture_frame", [0.16, 0.04, 0.032], [0.07, y + 0.004, z], wood="iron", look="prop:brass", solid=0.5))
    mem.append(m("stock", "post", [0.36, 0.05, 0.032], [0.33, y - 0.002, z], look="prop:dark_wood"))
    mem.append(m("butt", "trim", [0.012, 0.075, 0.034], [0.516, y - 0.006, z], wood="iron", look="prop:brass", solid=0.5))
    return {
        "_doc": "A lever-action rifle on pegs (#1030, tools/props/saloon_walls.py): two oak pegs on back plates, the carbine "
                "(blued barrel, brass receiver, walnut stock) laid across them, hung over the bar's back or the door. Hung on two nails; "
                "it falls when the board behind goes; the rifle goes where it's pushed.",
        "id": "rifle_pegs", "kind": "members", "in_game": False, "wood": "oak", "look": "lib:furniture_oak/old",
        "splits_below": 0.4, "blow_wood_share": 0.5,
        "hangs": {"nails": [[-0.30, 0.0, 0.004], [0.12, 0.0, 0.004]]},
        "members": mem,
    }


def main():
    for d in (case(), clock(), foot_rail(), rifle_pegs()):
        with open(os.path.join(KIT, d["id"] + ".json"), "w") as f:
            json.dump(d, f, indent=1)
            f.write("\n")
        print("wrote", d["id"])


if __name__ == "__main__":
    main()
