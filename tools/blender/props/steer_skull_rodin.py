"""The longhorn steer's skull on a plank (Sean, 2026-10-24: "Do 1, can you source the images"): three
pictures drawn by GPT-5.4 in the deer head pictures' look (the Studio's `prop-pictures`, card
`cards/props/steer_skull.yaml`, $1.00 with a redrawn side), made 3D by Rodin (`prop3d`, $1.60).

    ~/.venvs/studio/bin/python tools/blender/props/steer_skull_rodin.py RODIN.glb

RODIN.glb is the Studio's paid/2d09e98e1905... (its ledger rows prop:steer_skull). Turned into the
kit's space for `steer_skull` by rodin_prop.py: sized by the horns' spread (WIDTH: the skull then
~0.57 m long, a steer's), split into the kit's parts: `plank` (the wood against the wall), `horn_l`
and `horn_r` (each side past the skull) and `skull`.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rodin_prop as R  # noqa: E402

WIDTH = 1.0          # tip to tip (m); the pictures draw the skull large for its horns
TRIS = 6000
TEX_PX = 1024
PLANK_FRONT = 0.065  # nearer the wall than this, and within PLANK_HALF of the middle, is the plank
PLANK_HALF = 0.16
SKULL_HALF = 0.13    # past this either side is a horn


def part_of(c):
    if c[2] < PLANK_FRONT and abs(c[0]) < PLANK_HALF:
        return "plank"
    if c[0] < -SKULL_HALF:
        return "horn_l"
    if c[0] > SKULL_HALF:
        return "horn_r"
    return "skull"


def main():
    obj = R.load(sys.argv[1])
    R.paint(os.path.join(R.MODELS, "steer_skull_paint.png"), TEX_PX)
    R.place(obj, width=WIDTH)
    R.decimate(obj, TRIS)
    R.split_and_export(obj, os.path.join(R.MODELS, "steer_skull.glb"), part_of, ("plank", "skull", "horn_l", "horn_r"))


if __name__ == "__main__":
    main()
