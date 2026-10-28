"""The rig check: the game horse rendered from his left, the bones drawn over him (from the
render's own projection), into build/horse_walk/rig/rest.png.

    ~/bpyenv/bin/python experiments/horse_walk/blender/rig_check.py 
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
opts = dict(a[2:].split("=", 1) for a in args if a.startswith("--") and "=" in a)
arm = C.load()
arm.animation_data.action = None
C.scene(engine=opts.get("engine", "CYCLES"), size=(1200, 900))
cam = C.side_camera(centre=(-0.15, 0, 1.0), width=3.4)
out = os.path.join(C.OUT, "rig")
os.makedirs(out, exist_ok=True)
path = os.path.join(out, "rest.png")
C.render(path)
im = Image.open(path).convert("RGB")
d = ImageDraw.Draw(im)
M = arm.matrix_world
for b in arm.data.bones:
    h = C.to_pixel(cam, M @ b.head_local)
    t = C.to_pixel(cam, M @ b.tail_local)
    col = (255, 40, 40) if b.name.endswith(".L") else (40, 120, 255) if b.name.endswith(".R") else (255, 220, 0)
    d.line([h, t], fill=col, width=2)
    d.ellipse([h[0] - 3, h[1] - 3, h[0] + 3, h[1] + 3], outline=col)
# a 10 cm grid tick on the left edge, metres labelled
for zc in range(0, 220, 10):
    p = C.to_pixel(cam, (-1.85, 0, zc / 100))
    d.line([(0, p[1]), (8 if zc % 50 else 18, p[1])], fill=(0, 0, 0))
    if zc % 50 == 0:
        d.text((20, p[1] - 6), "%.1f" % (zc / 100), fill=(0, 0, 0))
for xc in range(-180, 140, 10):
    p = C.to_pixel(cam, (xc / 100, 0, 0))
    d.line([(p[0], im.size[1] - (8 if xc % 50 else 18)), (p[0], im.size[1])], fill=(0, 0, 0))
    if xc % 50 == 0:
        d.text((p[0] + 2, im.size[1] - 30), "%.1f" % (xc / 100), fill=(0, 0, 0))
im.save(path)
print("wrote", path)
