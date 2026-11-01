#!/usr/bin/env python3
"""The farmhouse's contact sheet and F3 numbers (issue #520, step 1), in the game's street through
the dev bridge: the house from the road and closer, round it, inside each room; then a walk from
the road round the house and through it, the frame's numbers (`read frame`: F3's process and
physics, draw calls) at each stop. The breach pictures (breach.py) go on the sheet too if found.

    python3 experiments/farmhouse/sheet.py --out=experiments/farmhouse/results/DATE/sheet [--breach=DIR]
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw

BRIDGE = ["python3", "tools/bridge.py"]
VIEWS = ["closer", "corner", "back", "front_room", "front_room_back", "bedroom", "kitchen", "loft"]
WALK = ["road_farm", "farm_lane", "farm_yard_e", "farm_side_e", "farm_back_e", "farm_back", "farm_back_w", "farm_side_w",
        "farm_yard_w", "farm_steps", "farm_porch", "farm_door", "farm_room", "farm_room_back", "farm_kitchen_door", "farm_kitchen",
        "farm_kitchen_door", "farm_room_back", "farm_room_e", "farm_bedroom_door", "farm_bedroom", "farm_bedroom_door",
        "farm_room_e", "farm_stair_foot", "farm_stair_head", "farm_loft", "farm_loft_window"]


def bridge(*cmds):
    out = subprocess.run(BRIDGE + list(cmds), capture_output=True, text=True).stdout
    return [json.loads(l) for l in out.splitlines() if l.startswith("{")]


def main():
    out_dir = "experiments/farmhouse/results/sheet"
    breach_dir = ""
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out_dir = a[6:]
        elif a.startswith("--breach="):
            breach_dir = a[9:]
    os.makedirs(out_dir, exist_ok=True)
    if "--walk-only" not in sys.argv:
        shots = pictures(out_dir)
        sheet(shots, out_dir, breach_dir)
    if "--sheet-only" not in sys.argv:
        walk(out_dir)


def pictures(out_dir):
    subprocess.run(BRIDGE + ["start", "--size=960x540"], check=True)
    bridge("time 15")
    shots = []
    r = bridge("goto road_farm", "look 98 2.5 -50", "wait 4", "screenshot " + os.path.abspath(os.path.join(out_dir, "road.png")))
    shots.append(("from the road", os.path.join(out_dir, "road.png")))
    for v in VIEWS:
        w = bridge("farm_view " + v)[0]
        path = os.path.abspath(os.path.join(out_dir, v + ".png"))
        bridge("goto %.2f %.2f %.2f" % tuple(w["stand"]), "look %.2f %.2f %.2f" % tuple(w["look"]), "wait 3", "screenshot " + path)
        shots.append((v.replace("_", " "), path))
    subprocess.run(BRIDGE + ["stop"])
    return shots


def walk(out_dir):
    """Round it and through it, F3's numbers at each stop: headless (drawn under lavapipe the frame
    is the software renderer's, not the game's)."""
    subprocess.run(BRIDGE + ["start", "--headless"], check=True)
    bridge("time 15")
    frames = []
    bridge("goto road_farm")
    for place in WALK:
        r = bridge("walk " + place, "wait 1", "read frame")
        f = next((x for x in r if "frame" in x), {}).get("frame", {})
        frames.append({"at": place, **f})
        print(json.dumps(frames[-1]), flush=True)
    subprocess.run(BRIDGE + ["stop"])
    with open(os.path.join(out_dir, "frames.json"), "w") as f:
        json.dump(frames, f, indent=1)


def sheet(shots, out_dir, breach_dir):
    if breach_dir:
        for wall in ["front", "west", "east", "back", "lean_back", "lean_west", "lean_east"]:
            p = os.path.join(breach_dir, "breach_%s.png" % wall)
            if os.path.exists(p):
                shots.append(("breach: " + wall, p))
    # The sheet: 4 across, each 480 wide.
    cols, w, h = 4, 480, 270
    rows = (len(shots) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * w, rows * (h + 22)), (20, 20, 20))
    d = ImageDraw.Draw(sheet)
    for i, (label, path) in enumerate(shots):
        im = Image.open(path).convert("RGB").resize((w, h))
        x, y = (i % cols) * w, (i // cols) * (h + 22)
        sheet.paste(im, (x, y + 22))
        d.text((x + 6, y + 4), label, fill=(240, 230, 210))
    sheet.save(os.path.join(out_dir, "sheet.jpg"), quality=85)
    print("sheet: " + os.path.join(out_dir, "sheet.jpg"))


if __name__ == "__main__":
    main()
