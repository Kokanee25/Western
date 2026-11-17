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
    mem.append(m("trunk_glass", "glass", [0.24, 0.56, 0.004], [0, 0.39, 0.151], wood="glass"))
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
    mem.append(m("hood_glass", "glass", [0.30, hh - 0.075, 0.004], [0, hc, 0.151], wood="glass"))
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


def main():
    for d in (case(), clock()):
        with open(os.path.join(KIT, d["id"] + ".json"), "w") as f:
            json.dump(d, f, indent=1)
            f.write("\n")
        print("wrote", d["id"])


if __name__ == "__main__":
    main()
