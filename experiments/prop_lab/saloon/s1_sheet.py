#!/usr/bin/env python3
"""Saloon B's batch S1 on the judging stand (#866; docs/briefs/prop-factory.md "Every prop is checked"):
each group of props put down in the running town on the road east of it, on the lab's stand (a beam
to hang lamps from, a boarded wall), at noon and at night by a hanging lamp lit
on the beam, through the dev bridge (experiments/prop_lab/bridge.gd: `prop_stand`, `prop`, `prop_light`).
Not placed in saloon B: that waits for #865's body fix and #862.

    python3 experiments/prop_lab/saloon/s1_sheet.py --out=DIR [--groups=lamps,glasses] [--size=960x540]

DIR/<group>_<noon|night>.png and DIR/sheet.jpg. ~1-2 min a group under lavapipe.
"""
import json
import math
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]
SPOT = (40.0, 0.0, -5.4)  # the road east of town: open ground, the desert behind
YAW = 0.0
MAN = (42.6, 0.0, -3.2)
LAMP_Y = 3.0 - 1.0  # a hanging lamp's origin under the stand's beam (its drop 1.0 m)
TABLE = 0.76

# Each group: props [(id, x, y, z, yaw, light height or None)] in the stand's space (x across, z toward
# the camera, y up), and the camera (at, looking at, fov) in the same.
GROUPS = {
    "lamps": {"props": [("hanging_lamp", -0.75, LAMP_Y, 0.0, 0, 0.33), ("hanging_lamp_shaded", 0.75, LAMP_Y, 0.0, 0, 0.33)],
              "cam": ((0.0, 2.05, 1.55), (0.0, 2.3, 0.0), 50)},
    "glasses": {"props": [("table", 0.0, 0.0, 0.1, 0, None), ("shot_glass", -0.42, TABLE, 0.2, 0, None), ("schooner", -0.3, TABLE, 0.08, 0, None),
                          ("decanter", -0.15, TABLE, -0.05, 0, None), ("card_deck", 0.03, TABLE, 0.25, 20, None), ("chip_stacks", 0.08, TABLE, 0.08, -10, None),
                          ("till_drawer", 0.3, TABLE, -0.08, -8, None), ("gold_scales", 0.45, TABLE, 0.22, 10, None)],
                "cam": ((0.05, 1.12, 0.95), (0.0, 0.84, 0.1), 50), "night_lamp": 0.6},
    "work_board": {"props": [("work_board", 0.0, 0.0, -0.45, 180, None), ("slat_mat", 0.0, 0.0, 0.32, 0, None)],
                   "cam": ((1.0, 1.65, 1.0), (0.0, 0.8, -0.45), 58), "night_lamp": 0.6},
    "box_stove": {"props": [("box_stove", 0.0, 0.0, -0.25, 0, None)],
                  "cam": ((1.8, 1.55, 2.0), (0.0, 1.0, -0.25), 56), "night_lamp": 1.2},
    "faro": {"props": [("faro_table", 0.0, 0.0, 0.05, 0, None), ("lookout_stool", -0.85, 0.0, -0.45, 0, None)],
             "cam": ((0.85, 1.75, 1.75), (0.0, 0.72, 0.0), 52), "night_lamp": 0.0},
    "piano_stool": {"props": [("upright_piano", 0.0, 0.0, -0.55, 0, None), ("piano_stool", 0.05, 0.0, 0.25, 0, None)],
                    "cam": ((0.85, 1.25, 1.75), (0.0, 0.55, -0.05), 52), "night_lamp": 0.9},
    "wheel": {"props": [("wheel_of_fortune", 0.0, 1.85, -0.93, 0, None)],
              "cam": ((0.45, 1.75, 1.45), (0.0, 1.8, -0.9), 55), "night_lamp": 1.0},
    "bar": {"props": [("bar", 0.0, 0.0, -0.3, 0, None)],
            "cam": ((1.5, 1.85, 1.6), (0.0, 1.0, -0.3), 52), "night_lamp": 0.9},
}


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def bridge(*cmds):
    out = subprocess.run(BRIDGE + list(cmds), capture_output=True, text=True, cwd=ROOT).stdout
    return [json.loads(line) for line in out.splitlines() if line.startswith("{")]


def world(p):
    """The stand's space to the town's."""
    a = math.radians(YAW)
    x, y, z = p
    return (SPOT[0] + x * math.cos(a) + z * math.sin(a), SPOT[1] + y, SPOT[2] - x * math.sin(a) + z * math.cos(a))


def main():
    groups = opt("groups", ",".join(GROUPS)).split(",")
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "s1_sheet")))
    os.makedirs(out, exist_ok=True)
    subprocess.run(BRIDGE + ["start", "--size=" + opt("size", "960x540")], cwd=ROOT, check=True)
    log = []
    try:
        bridge("spawn townsman %.2f %.2f %.2f" % MAN)
        for g in groups:
            spec = GROUPS[g]
            cmds = ["props_clear", "prop_stand %.2f %.2f %.2f %.1f" % (*SPOT, YAW)]
            for pid, x, y, z, yaw, light in spec["props"]:
                cmds.append("prop %s %.3f %.3f %.3f %.1f" % (pid, *world((x, y, z)), YAW + yaw))
                if light is not None:
                    cmds.append("prop_light %.2f" % light)
            if "night_lamp" in spec:
                # The night's light: a hanging lamp lit on the beam, to one side of the group.
                cmds.append("prop hanging_lamp %.3f %.3f %.3f %.1f" % (*world((spec["night_lamp"], LAMP_Y, 0.0)), YAW))
                cmds.append("prop_light 0.33")
            log.append({g: bridge(*cmds)})
            (cx, cy, cz), (tx, ty, tz), fov = spec["cam"]
            cam = world((cx, cy, cz)) + world((tx, ty, tz))
            for light, hour in (("noon", 12.0), ("night", 21.5)):
                bridge("time %.1f" % hour, "wait 6", "camera %.2f %.2f %.2f %.2f %.2f %.2f %d" % (*cam, fov), "wait 1",
                       "screenshot %s" % os.path.join(out, "%s_%s.png" % (g, light)))
    finally:
        subprocess.run(BRIDGE + ["stop"], cwd=ROOT)
        with open(os.path.join(out, "placed.json"), "w") as f:
            json.dump(log, f, indent=1)
    from PIL import Image, ImageDraw
    w, h = 480, 270
    # Every group rendered into DIR so far (a re-run of a few keeps the rest).
    groups = [g for g in GROUPS if os.path.exists(os.path.join(out, "%s_noon.png" % g))]
    sheet = Image.new("RGB", (w * 2, h * len(groups)), (20, 18, 16))
    draw = ImageDraw.Draw(sheet)
    for r, g in enumerate(groups):
        for c, light in enumerate(("noon", "night")):
            path = os.path.join(out, "%s_%s.png" % (g, light))
            if os.path.exists(path):
                sheet.paste(Image.open(path).convert("RGB").resize((w, h)), (c * w, r * h))
            draw.text((c * w + 6, r * h + 4), "%s  %s" % (g, light), fill=(255, 240, 200))
    sheet.save(os.path.join(out, "sheet.jpg"), quality=88)
    print(os.path.join(out, "sheet.jpg"))


if __name__ == "__main__":
    main()
