"""The mounted deer head from Sean's six pictures (2026-10-24: "make a prop that the other session
is having trouble with"), made 3D by Rodin through the Character Studio (its request
`requests/2026-10-24_deer_head_rodin.yaml`, $1.60) in place of deer_head.py's modelled one.

    ~/.venvs/studio/bin/python tools/blender/props/deer_head_rodin.py RODIN.glb

RODIN.glb is the Studio's paid/526815a52c02... (Kokanee25/saltcreek-characters, its ledger row
prop:deer_head): this script remade from it writes the same files. Run it, not build.py.

Rodin's model is turned into the kit's space for `deer_head` (metres, x right, y up, z out of the
wall; the plaque's back on the wall at z 0.02, its top at y 0.02, as deer_head.py's, so the kit
file's nails hold it), cut down to a wall prop's triangles, and split into the kit's parts by where
each triangle lies: `plaque` (the wood: everything within the plaque's thickness of the wall),
`nose` (the muzzle, inside the muzzle member's box), `head` (from the skull up: ears, eyes and
antlers with it) and `neck` (the rest of the hide). Its own painted texture goes beside it as
deer_head_paint.png, its UVs kept (0..1): the kit's look `model:deer_head` draws it.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rodin_prop as R  # noqa: E402

PLAQUE_H = 0.47      # the plaque's height (m): the kit's plaque member, 0.4695
PLAQUE_FRONT = 0.06  # nearer the wall than this is the plaque (m, z); its back at 0.02
TRIS = 6000          # a wall prop's budget (deer_head.py's was ~1,500 of flat colours)
TEX_PX = 1024        # the paint's size (Rodin's is 4096)
# The split (m, the kit's space): the head from NECK_TOP up (ears, eyes, antlers with it), the
# muzzle the part of it out past MUZZLE_OUT; the kit file's members are boxed round each part.
NECK_TOP = -0.10
MUZZLE_OUT = 0.30    # (below MUZZLE_TOP: the antlers' tines reach as far out)
MUZZLE_TOP = 0.04
SKULL_TOP = 0.06     # the head member's box is the skull's, to here: the ears and rack drawn past it


def part_of(c):
    """Which kit part a triangle at centre `c` (game space) belongs to."""
    if c[2] < PLAQUE_FRONT:
        return "plaque"
    if c[1] < NECK_TOP:
        return "neck"
    return "nose" if c[2] > MUZZLE_OUT and c[1] < MUZZLE_TOP else "head"


def box_of(name, p):
    return p[p[:, 1] < SKULL_TOP] if name == "head" else p


def main():
    obj = R.load(sys.argv[1])
    R.paint(os.path.join(R.MODELS, "deer_head_paint.png"), TEX_PX)
    R.place(obj, back_height=PLAQUE_H)
    R.decimate(obj, TRIS)
    R.split_and_export(obj, os.path.join(R.MODELS, "deer_head.glb"), part_of, ("plaque", "neck", "head", "nose"), box_of)


if __name__ == "__main__":
    main()
