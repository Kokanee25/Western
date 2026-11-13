#!/usr/bin/env python3
"""Saloon B's stage and dressing room props on the judging stand (#903), as S1's (s1_sheet.py: the
same stand on the road east of town, its boarded wall and beam, a townsman for scale, noon and night
by a hanging lamp), through the dev bridge (experiments/prop_lab/bridge.gd: `prop_stand`, `prop`,
`prop_open`, `prop_light`). Not placed in saloon B: that waits for #902 (the room) and #865, #862.

    python3 experiments/prop_lab/saloon/stage_sheet.py --out=DIR [--groups=mirror,trunk] [--size=960x540]

DIR/<group>_<noon|night>.png and DIR/sheet.jpg. ~1-2 min a group under lavapipe.
"""
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import s1_sheet as s1  # noqa: E402

WALL = -0.9  # the stand's wall's face
FOOT_Y = 0.10  # a footlight's flame over its foot

# Each group: props [(id, x, y, z, yaw, light height or None, hinge to open or None)] in the stand's
# space, and the camera (at, looking at, fov).
GROUPS = {
    "mirror": {"props": [("dressing_mirror", 0.0, 0.0, WALL + 0.295, 0, None, None)],
               "cam": ((0.9, 1.6, 1.4), (0.0, 1.15, WALL + 0.3), 52), "night_lamp": 0.5},
    "pegs": {"props": [("costume_pegs", 0.0, 1.72, WALL, 0, None, None)],
             "cam": ((0.6, 1.5, 1.6), (0.0, 1.15, WALL), 56), "night_lamp": 0.6},
    "trunk": {"props": [("travelling_trunk", -0.6, 0.0, -0.35, 8, None, None), ("travelling_trunk", 0.6, 0.0, -0.3, -12, None, "lid")],
              "cam": ((0.4, 1.55, 1.5), (0.0, 0.45, -0.3), 52), "night_lamp": 0.0},
    "screen": {"props": [("dressing_screen", 0.0, 0.0, -0.45, 0, None, None)],
               "cam": ((1.0, 1.45, 2.1), (0.0, 0.95, -0.35), 52), "night_lamp": 0.9},
    "footlights": {"props": [("footlight", x, 0.0, 0.0, 0, FOOT_Y, None) for x in (-1.35, -0.45, 0.45, 1.35)],
                   "cam": ((0.5, 0.75, 1.9), (0.0, 0.15, 0.0), 50)},
}


def main():
    groups = s1.opt("groups", ",".join(GROUPS)).split(",")
    out = os.path.abspath(s1.opt("out", os.path.join(s1.ROOT, "build", "stage_sheet")))
    os.makedirs(out, exist_ok=True)
    subprocess.run(s1.BRIDGE + ["start", "--size=" + s1.opt("size", "960x540")], cwd=s1.ROOT, check=True)
    log = []
    try:
        s1.bridge("spawn townsman %.2f %.2f %.2f" % s1.MAN)
        for g in groups:
            spec = GROUPS[g]
            cmds = ["props_clear", "prop_stand %.2f %.2f %.2f %.1f" % (*s1.SPOT, s1.YAW)]
            for pid, x, y, z, yaw, light, hinge in spec["props"]:
                cmds.append("prop %s %.3f %.3f %.3f %.1f" % (pid, *s1.world((x, y, z)), s1.YAW + yaw))
                if light is not None:
                    cmds.append("prop_light %.2f" % light)
                if hinge:
                    cmds.append("prop_open %s" % hinge)
            if "night_lamp" in spec:
                cmds.append("prop hanging_lamp %.3f %.3f %.3f %.1f" % (*s1.world((spec["night_lamp"], s1.LAMP_Y, 0.0)), s1.YAW))
                cmds.append("prop_light 0.33")
            log.append({g: s1.bridge(*cmds)})
            (cx, cy, cz), (tx, ty, tz), fov = spec["cam"]
            cam = s1.world((cx, cy, cz)) + s1.world((tx, ty, tz))
            for light, hour in (("noon", 12.0), ("night", 21.5)):
                s1.bridge("time %.1f" % hour, "wait 6", "camera %.2f %.2f %.2f %.2f %.2f %.2f %d" % (*cam, fov), "wait 1",
                          "screenshot %s" % os.path.join(out, "%s_%s.png" % (g, light)))
    finally:
        subprocess.run(s1.BRIDGE + ["stop"], cwd=s1.ROOT)
        with open(os.path.join(out, "placed.json"), "w") as f:
            json.dump(log, f, indent=1)
    from PIL import Image, ImageDraw
    w, h = 480, 270
    done = [g for g in GROUPS if os.path.exists(os.path.join(out, "%s_noon.png" % g))]
    sheet = Image.new("RGB", (w * 2, h * len(done)), (20, 18, 16))
    draw = ImageDraw.Draw(sheet)
    for r, g in enumerate(done):
        for c, light in enumerate(("noon", "night")):
            path = os.path.join(out, "%s_%s.png" % (g, light))
            if os.path.exists(path):
                sheet.paste(Image.open(path).convert("RGB").resize((w, h)), (c * w, r * h))
            draw.text((c * w + 6, r * h + 4), "%s  %s" % (g, light), fill=(255, 240, 200))
    sheet.save(os.path.join(out, "sheet.jpg"), quality=88)
    print(os.path.join(out, "sheet.jpg"))


if __name__ == "__main__":
    main()
