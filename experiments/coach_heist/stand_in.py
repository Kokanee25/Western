#!/usr/bin/env python3
"""The heist lab's stand-in coach (issue #770), until the prop lab's `baron_coach` (#782, PR #786)
is on main: the real coach's running gear, frame, panels, roof and its 28 plates (ids, sizes and
places as agreed on #770), without its doors' hinges, benches, driver's box, boot or strongbox
(kit code not on main yet). Its weight is brought to the plan's 1,508 kg with oak ballast in the
benches.

    python3 experiments/coach_heist/stand_in.py SRC_JSON [OUT_JSON]

SRC_JSON: the real coach's kit file (`git show origin/claude/prop-lab-coach-xl8t64:assets/props/kit/baron_coach.json`).
OUT: experiments/coach_heist/coach_stand_in.json.
"""
import json
import sys

DENSITY = {"oak": 750.0, "iron": 7600.0, "weathered_pine": 420.0, "leather": 860.0}
KEEP = ("front_", "hind_", "plate_", "sill_", "post_", "panel_", "roof", "floor", "brace_", "reach",
        "hound_", "splinter_bar", "singletree_", "trace_hook_", "pole", "door_", "bench_")
TARGET_KG = 1508.0


def mass(m):
    s = m["size"]
    return s[0] * s[1] * s[2] * DENSITY.get(m.get("wood", "oak"), 480.0)


def main():
    src = json.load(open(sys.argv[1]))
    out_path = sys.argv[2] if len(sys.argv) > 2 else "experiments/coach_heist/coach_stand_in.json"
    members = []
    for m in src["members"]:
        if not m["id"].startswith(KEEP):
            continue
        m = {k: v for k, v in m.items() if k not in ("shot_breaks", "hinge")}
        if m.get("look") == "prop:plate_iron":
            m["look"] = "prop:iron"  # (the prop lab's plate look comes with its PR)
        if m["kind"] == "door":
            m["kind"] = "trim"  # (no hinges in the kit on main: the doors are shut panels)
        members.append(m)
    kg = sum(mass(m) for m in members)
    my = sum(mass(m) * m["at"][1] for m in members)
    # Ballast: what the driver's box, boot, fittings and strongbox weigh, as two oak blocks in the
    # benches (floor to seat), so the whole has the real coach's weight. Its centre of weight comes
    # out a little lower than the real coach's (printed): the real one carries more up top.
    need = TARGET_KG - kg
    length = need / 2.0 / (750.0 * 0.30 * 0.37)
    for side, x in (("front", -1.04), ("back", 1.04)):
        members.append({"id": "ballast_%s" % side, "kind": "trim", "wood": "oak", "look": "wood:dark_oak",
                        "size": [0.30, 0.37, round(length, 4)], "at": [x, 1.29, 0.0]})
    y = (my + need * 1.29) / TARGET_KG
    out = {
        "_doc": "The coach heist lab's stand-in (#770): the prop lab's baron_coach (#782) without the kit "
                "code not yet on main (hinges, benches, boxes, strongbox), brought to its 1,508 kg and "
                "its weight by oak ballast in the benches. Made by experiments/coach_heist/stand_in.py; "
                "the lab uses baron_coach itself once PropKit has it.",
        "id": "coach_stand_in", "kind": "members", "wood": src.get("wood", "oak"), "look": src.get("look", ""),
        "splits_below": src.get("splits_below", 0.4), "blow_wood_share": src.get("blow_wood_share", 0.5),
        "seats_at": src.get("seats_at", []), "members": members,
    }
    json.dump(out, open(out_path, "w"), indent=0)
    total = kg + need
    print("members %d, kg %.0f (ballast %.0f kg, %.2f m long), centre of weight y %.3f" % (len(members), total, need, length, y))


if __name__ == "__main__":
    main()
