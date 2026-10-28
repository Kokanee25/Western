"""The bend test: each near leg flexed through a walk's range at every joint, rendered from his
left, the bones drawn on. Before (the game's rig) and after (--fix: rigtools.fix_hind).

    ~/bpyenv/bin/python experiments/horse_walk/blender/bend_test.py [--fix]
Writes build/horse_walk/rig/bend[_fix].png (a strip: rest, then each pose).
"""
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402
import rigtools as R  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
fix = "--fix" in args
arm = C.load()
arm.animation_data.action = None
if fix:
    R.fix_hind(arm, [o for o in bpy.data.objects if o.type == "MESH"])
C.scene(size=(700, 900))
cam = C.side_camera(centre=(0.0, 0, 0.75), width=2.6)
# + about y tips a bone's lower end forward (toward the head, -x)
POSES = [
    ("rest", []),
    # the fore in swing: the knee folded, fetlock and pastern flexed, the arm forward
    ("fore swing", [("upperarm.L", -15), ("forearm.L", 25), ("cannon.L", -70), ("pastern.L", -35)]),
    # the fore's lift-off: the limb back, the fetlock over-extended, the toe down
    ("fore lift-off", [("scapula.L", -15), ("cannon.L", -10), ("pastern.L", 30)]),
    # the hind in swing: hip forward, stifle and hock folded, fetlock flexed
    ("hind swing", [("thigh.L", 25), ("shin.L", -30), ("hcannon.L", 40), ("hpastern.L", -30)]),
    # the hind's mid-stance: the fetlock sunk (pastern toward level), hock a little closed
    ("hind stance", [("thigh.L", -10), ("shin.L", 8), ("hcannon.L", 6), ("hpastern.L", 25)]),
    # the hind's lift-off: the leg back, toe down
    ("hind lift-off", [("thigh.L", -25), ("shin.L", 10), ("hpastern.L", 25)]),
]
out = os.path.join(C.OUT, "rig")
cells = []
for label, turns in POSES:
    R.reset(arm)
    for name, deg in turns:
        R.turn(arm, name, deg)
    p = os.path.join(out, "_bend.png")
    C.render(p)
    im = Image.open(p).convert("RGB")
    d = ImageDraw.Draw(im)
    for leg in ("LF", "LH"):
        for n in C.LEGS[leg]:
            d.line([C.to_pixel(cam, R.head(arm, n)), C.to_pixel(cam, R.tail(arm, n))], fill=(255, 30, 30), width=2)
    d.text((8, 8), label + (" (fixed rig)" if fix else " (game rig)"), fill=(0, 0, 0))
    cells.append(im.crop((0, 200, 700, 900)))
w, h = cells[0].size
sheet = Image.new("RGB", (w * 3, h * 2))
for i, c in enumerate(cells):
    sheet.paste(c, ((i % 3) * w, (i // 3) * h))
sheet = sheet.resize((sheet.width * 2 // 3, sheet.height * 2 // 3), Image.LANCZOS)
path = os.path.join(out, "bend_fix.png" if fix else "bend.png")
sheet.save(path)
print("wrote", path)
