#!/usr/bin/env python3
"""The Baron's coach's contact sheet (#782): the coach put down before the saloon's porch as the
factory's sheet does (factory_sheet.py), a townsman beside it for scale, seen from the street at noon
and at night, from the front (the driver's box, the pole and the team's hooks), with its left door open,
and its strongbox put down alone with the lid shut and open.

    python3 experiments/prop_lab/coach_sheet.py --out=DIR [--size=960x540]

DIR/<shot>.png and DIR/sheet.jpg. ~1 min a shot under lavapipe.
"""
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from factory_sheet import BRIDGE, MAN, ROOT, SPOT, YAW, bridge, opt  # noqa: E402


def cam(off, look, fov=50):
    x, y, z = SPOT
    c = (x + off[0], y + off[1], z + off[2])
    t = (x + look[0], y + look[1], z + look[2])
    return "camera %.2f %.2f %.2f %.2f %.2f %.2f %d" % (c + t + (fov,))


def main():
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "coach_sheet")))
    os.makedirs(out, exist_ok=True)
    shots = []

    def shoot(name, hour, camera):
        path = os.path.join(out, name + ".png")
        bridge("time %.1f" % hour, "wait 6", camera, "wait 1", "screenshot %s" % path)
        shots.append(name)

    subprocess.run(BRIDGE + ["start", "--size=" + opt("size", "960x540")], cwd=ROOT, check=True)
    try:
        bridge("spawn townsman %.2f %.2f %.2f" % MAN)
        print(bridge("props_clear", "prop baron_coach %.2f %.2f %.2f %.1f" % (SPOT + (YAW,))))
        # The factory's framing (its left side and back, from the street), then the front.
        shoot("coach_noon", 12.0, cam((4.4, 3.0, -5.6), (0.3, 1.3, 0)))
        shoot("coach_night", 21.5, cam((4.4, 3.0, -5.6), (0.3, 1.3, 0)))
        shoot("coach_front", 12.0, cam((-6.5, 2.4, -3.2), (-0.8, 1.3, 0)))
        print(bridge("prop_open door_l"))
        shoot("coach_door_open", 12.0, cam((-1.0, 1.9, -3.4), (0.4, 1.5, 0.2), 55))
        # Out in the street (its middle toward -Z), clear of the horses at the rail, seen toward the store.
        bx, bz = SPOT[0] - 1.5, SPOT[2] - 3.0
        print(bridge("props_clear", "prop strongbox %.2f %.2f %.2f %.1f" % (bx, SPOT[1], bz, 205.0)))
        box = (bx - SPOT[0], 0.15, bz - SPOT[2])
        shoot("strongbox_shut", 12.0, cam((box[0] + 0.5, 0.75, box[2] - 0.9), box, 45))
        print(bridge("prop_open lid"))
        shoot("strongbox_open", 12.0, cam((box[0] + 0.5, 0.95, box[2] - 0.9), box, 45))
    finally:
        subprocess.run(BRIDGE + ["stop"], cwd=ROOT)
    from PIL import Image, ImageDraw
    w, h = 480, 270
    cols = 2
    rows = (len(shots) + 1) // 2
    sheet = Image.new("RGB", (w * cols, h * rows), (20, 18, 16))
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(shots):
        path = os.path.join(out, name + ".png")
        c, r = i % cols, i // cols
        if os.path.exists(path):
            sheet.paste(Image.open(path).convert("RGB").resize((w, h)), (c * w, r * h))
        draw.text((c * w + 6, r * h + 4), name, fill=(255, 240, 200))
    sheet.save(os.path.join(out, "sheet.jpg"), quality=88)
    print(os.path.join(out, "sheet.jpg"))


if __name__ == "__main__":
    main()
