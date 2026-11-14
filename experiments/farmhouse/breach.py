#!/usr/bin/env python3
"""The farmhouse's breach check (issue #520, step 1): one stick planted chest high from outside on
each wall, by the player's own planting (E held at the wall, lit on letting go), in the game's
street through the dev bridge; then the hole's clear height (farm_hole) and a picture of it.

    python3 experiments/farmhouse/breach.py --out=experiments/farmhouse/results/DATE/breach [--walls=front,west]

Starts and stops the game itself (six sticks carried: a game for each four walls).
"""
import json
import os
import subprocess
import sys

WALLS = ["front", "west", "east", "back", "lean_back", "lean_west", "lean_east"]
BRIDGE = ["python3", "tools/bridge.py"]


def bridge(*cmds):
    out = subprocess.run(BRIDGE + list(cmds), capture_output=True, text=True).stdout
    lines = [json.loads(l) for l in out.splitlines() if l.startswith("{")]
    return lines


def one(wall, out_dir):
    w = bridge("farm_wall " + wall)[0]
    sx, sy, sz = w["stand"]
    lx, ly, lz = w["look"]
    # Back out from the wall 4 m (the stand point is 0.9 m out) to watch it go.
    dx, dz = sx - lx, sz - lz
    n = (dx * dx + dz * dz) ** 0.5 or 1.0
    bx, bz = lx + dx / n * 4.5, lz + dz / n * 4.5
    fx, fz = lx + dx / n * 14.0, lz + dz / n * 14.0
    r = bridge("weapon dynamite", "goto %.2f %.2f %.2f" % (sx, sy, sz), "look %.2f %.2f %.2f" % (lx, ly, lz),
               "wait 0.5", "press shove 1.2", "goto %.2f %.2f %.2f" % (fx, sy, fz), "wait 7",
               "goto %.2f %.2f %.2f" % (bx, sy, bz), "look %.2f %.2f %.2f" % (lx, ly - 0.4, lz), "wait 3",
               "screenshot " + os.path.abspath(os.path.join(out_dir, "breach_%s.png" % wall)), "farm_hole " + wall,
               "events 12")
    hole = next((x for x in r if x.get("cmd", "").startswith("farm_hole")), {})
    return {"wall": wall, "clear": hole.get("clear"), "walk": hole.get("walk"), "stoop": hole.get("stoop"),
            "events": [e for x in r if x.get("cmd", "").startswith("events") for e in x.get("events", [])][-6:]}


def main():
    out_dir = "experiments/farmhouse/results/breach"
    walls = WALLS
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out_dir = a[6:]
        elif a.startswith("--walls="):
            walls = a[8:].split(",")
    os.makedirs(out_dir, exist_ok=True)
    rows = []
    for i in range(0, len(walls), 4):
        subprocess.run(BRIDGE + ["start", "--size=960x540"], check=True)
        bridge("time 14")
        for wall in walls[i:i + 4]:
            rows.append(one(wall, out_dir))
            print(json.dumps({k: rows[-1][k] for k in ("wall", "clear", "walk", "stoop")}), flush=True)
        subprocess.run(BRIDGE + ["stop"])
    walk = sum(1 for r in rows if r["walk"])
    stoop = sum(1 for r in rows if r["stoop"])
    with open(os.path.join(out_dir, "breach.json"), "w") as f:
        json.dump({"walk": walk, "stoop": stoop, "of": len(rows), "rows": rows}, f, indent=2)
    print("walk-through %d of %d, stoop-through %d of %d" % (walk, len(rows), stoop, len(rows)))


if __name__ == "__main__":
    main()
