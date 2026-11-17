#!/usr/bin/env python3
"""The guns' albedo graded for the hand (#1014): metal texels darker and a little less blue.

From the eye a held gun is seen from above, so its steel mirrors the open sky; the gun lab's own
shots saw it side on, mirroring the street. A man's own hat and body would shade it, which the
game doesn't draw (judge r1: "saturated electric-blue plastic"). The bake's bluing albedo (~0.36,
a metal's reflectance) is lowered toward blued steel's (~0.13); wood, brass and lead are not
metal in the ORM and stay as baked.

    python3 experiments/viewmodel_rig/held_grade.py ALBEDO ORM OUT [--dark=0.35] [--grey=0.5]
    python3 experiments/viewmodel_rig/held_grade.py --orm ORM OUT [--rough=0.3] [--spread=0.7]

--orm (#1031): the held ORM, the metal's roughness lifted (r * spread + rough) so a highlight spreads
over the cylinder and the receiver's flats as blued steel's does, not a pinpoint glint and a flat
mirror of the sky; occlusion, metal and the wood's roughness kept.
"""
import sys

import numpy as np
from PIL import Image


def held_orm(src, out, rough, spread):
    orm = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0
    metal = np.clip((orm[..., 2] - 0.3) / 0.4, 0.0, 1.0)
    r = orm[..., 1]
    orm = orm.copy()
    orm[..., 1] = r + (np.clip(r * spread + rough, 0.0, 1.0) - r) * metal
    Image.fromarray((np.clip(orm, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out, quality=92)
    print(out, "metal roughness median %.2f" % float(np.median(orm[..., 1][metal > 0.5])))


def main():
    a = [x for x in sys.argv[1:] if not x.startswith("--")]
    opt = dict(x[2:].split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    if "--orm" in sys.argv:
        held_orm(a[0], a[1], float(opt.get("rough", 0.3)), float(opt.get("spread", 0.7)))
        return
    dark, grey = float(opt.get("dark", 0.35)), float(opt.get("grey", 0.5))
    alb = np.asarray(Image.open(a[0]).convert("RGB")).astype(np.float32) / 255.0
    orm = np.asarray(Image.open(a[1]).convert("RGB").resize(alb.shape[1::-1])).astype(np.float32) / 255.0
    metal = np.clip((orm[..., 2] - 0.3) / 0.4, 0.0, 1.0)[..., None]   # glTF's metal in blue
    lum = (alb * np.array([0.2126, 0.7152, 0.0722])).sum(-1, keepdims=True)
    graded = (alb + (lum - alb) * grey) * dark
    out = alb + (graded - alb) * metal
    Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)).save(a[2], quality=92)
    print(a[2], "metal share %.2f" % float(metal.mean()))


if __name__ == "__main__":
    main()
