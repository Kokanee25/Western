#!/usr/bin/env python3
"""The prop factory's contact sheet (docs/briefs/prop-factory.md): each prop put down in the running
town before the saloon's porch, seen from the street, a townsman about, at noon and at night under the porch lamps, through
the dev bridge (this lab's `prop` command, bridge.gd), then laid out a row a prop.

    python3 experiments/prop_lab/factory_sheet.py --ids=buckboard,wagon_wheel --out=DIR [--size=960x540]

DIR/<id>_<noon|night>.png and DIR/sheet.jpg. Takes ~1 min a prop under lavapipe.
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]
# Before the saloon's porch, seen from the street: lit by the porch lamps at night.
SPOT = (10.0, 0.0, -5.4)
YAW = -15.0
MAN = (12.2, 0.0, -6.6)


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def bridge(*cmds):
    out = subprocess.run(BRIDGE + list(cmds), capture_output=True, text=True, cwd=ROOT).stdout
    return [json.loads(line) for line in out.splitlines() if line.startswith("{")]


def size_of(prop_id):
    """The prop's box (from its kit file's members), for framing."""
    d = json.load(open(os.path.join(ROOT, "assets", "props", "kit", prop_id + ".json")))
    lo, hi = [1e9] * 3, [-1e9] * 3
    for m in d.get("members", []):
        for a in range(3):
            lo[a] = min(lo[a], m["at"][a] - m["size"][a] * 0.5)
            hi[a] = max(hi[a], m["at"][a] + m["size"][a] * 0.5)
    return [h - l for l, h in zip(lo, hi)], [(l + h) * 0.5 for l, h in zip(lo, hi)]


def main():
    ids = opt("ids", "").split(",")
    out = os.path.abspath(opt("out", os.path.join(ROOT, "build", "factory_sheet")))
    os.makedirs(out, exist_ok=True)
    subprocess.run(BRIDGE + ["start", "--size=" + opt("size", "960x540")], cwd=ROOT, check=True)
    try:
        bridge("spawn townsman %.2f %.2f %.2f" % MAN)
        for prop_id in ids:
            size, mid = size_of(prop_id)
            span = max(size[0], size[2], size[1] * 1.6, 0.6)
            d = 0.8 + span * 0.8
            x, y, z = SPOT
            if span < 2.0:
                z += 1.6  # small things nearer the porch, in its lamps' light at night
            target = (x + mid[0] * 0.5, y + max(0.25, mid[1]), z)
            cam = (x + d * 0.6, y + 0.8 + span * 0.25, z - d * 0.75)
            bridge("props_clear", "prop %s %.2f %.2f %.2f %.1f" % (prop_id, x, y, z, YAW))
            for light, hour in (("noon", 12.0), ("night", 21.5)):
                bridge("time %.1f" % hour, "wait 6", "camera %.2f %.2f %.2f %.2f %.2f %.2f 50" % (cam + target), "wait 1",
                       "screenshot %s" % os.path.join(out, "%s_%s.png" % (prop_id, light)))
    finally:
        subprocess.run(BRIDGE + ["stop"], cwd=ROOT)
    from PIL import Image, ImageDraw
    w, h = 480, 270
    sheet = Image.new("RGB", (w * 2, h * len(ids)), (20, 18, 16))
    draw = ImageDraw.Draw(sheet)
    for r, prop_id in enumerate(ids):
        for c, light in enumerate(("noon", "night")):
            path = os.path.join(out, "%s_%s.png" % (prop_id, light))
            if os.path.exists(path):
                sheet.paste(Image.open(path).convert("RGB").resize((w, h)), (c * w, r * h))
            draw.text((c * w + 6, r * h + 4), "%s  %s" % (prop_id, light), fill=(255, 240, 200))
    sheet.save(os.path.join(out, "sheet.jpg"), quality=88)
    print(os.path.join(out, "sheet.jpg"))


if __name__ == "__main__":
    main()
