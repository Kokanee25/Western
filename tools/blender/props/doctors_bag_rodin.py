"""The doctor's bag (#819 batch D3; Sean's "A" on #823, 2026-11-12): three pictures of an 1880s
physician's Gladstone bag drawn realistic by Nano Banana Pro (the Studio's `prop-pictures`, card
`cards/props/doctors_bag.yaml`, its `look`: $0.42, and a failed GPT-5.4 call counted at $0.25), two of
them made 3D by Rodin (`prop3d`, $1.60).

    ~/bpyenv/bin/python tools/blender/props/doctors_bag_rodin.py RODIN.glb

RODIN.glb is the Studio's paid/04710b060f40... (its ledger rows prop:doctors_bag; branch
claude/studio-doctor-bag). Turned into the kit's space for `doctors_bag` by rodin_prop.py's steps,
but stood on a floor, not hung: its length along x (LENGTH), its base at y = 0, its middle on the
origin. Split into `body` (the leather, its frame and straps) and `handle` (what stands over the
frame).
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rodin_prop as R  # noqa: E402

LENGTH = 0.40        # m: a physician's Gladstone of the 1880s ran 14 to 18 in
TRIS = 5000
TEX_PX = 1024
HANDLE_HALF = 0.09   # the handle: over HANDLE_Y of the height, within this of the middle along x
HANDLE_Y = 0.80


def stand(obj):
    """Its longest level side along x, LENGTH long, its base on y = 0, centred."""
    g = R.game_verts(obj)
    d = np.ptp(g, 0)
    if d[2] > d[0]:      # lying along z: a quarter turn about y
        g = np.stack([g[:, 2], g[:, 1], -g[:, 0]], 1)
    g *= LENGTH / np.ptp(g[:, 0])
    g[:, 0] -= (g[:, 0].min() + g[:, 0].max()) / 2
    g[:, 2] -= (g[:, 2].min() + g[:, 2].max()) / 2
    g[:, 1] -= g[:, 1].min()
    R.set_game_verts(obj, g)
    print("size %s m" % np.round(np.ptp(g, 0), 3))
    return float(np.ptp(g[:, 1]))


def main():
    obj = R.load(sys.argv[1])
    R.paint(os.path.join(R.MODELS, "doctors_bag_paint.png"), TEX_PX)
    height = stand(obj)
    R.decimate(obj, TRIS)

    def part_of(c):
        return "handle" if c[1] > HANDLE_Y * height and abs(c[0]) < HANDLE_HALF else "body"

    R.split_and_export(obj, os.path.join(R.MODELS, "doctors_bag.glb"), part_of, ("body", "handle"))


if __name__ == "__main__":
    main()
