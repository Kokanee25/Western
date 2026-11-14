"""Loose straw: a low heap kicked out of a stall or off a wagon (~1.1 by 0.9 m, 0.2 high), ragged,
with stalks lying all over and round it. Parts: heap (straw), stalks (straw)."""
import math

import numpy as np

import common as C


def heap(rng):
    rings, sides = 6, 16
    verts = [(0.0, 0.2, 0.0)]
    for i in range(1, rings + 1):
        t = i / rings
        for k in range(sides):
            th = 2 * math.pi * k / sides
            r = t * (1.0 + 0.18 * math.sin(3 * th + 1.0) + rng.uniform(-0.08, 0.08))
            h = 0.2 * (1.0 - t ** 1.6) * (1.0 + rng.uniform(-0.25, 0.25)) if i < rings else 0.0
            verts.append((math.cos(th) * 0.55 * r, max(0.0, h), math.sin(th) * 0.45 * r))
    faces = [[0, 1 + (k + 1) % sides, 1 + k] for k in range(sides)]
    for i in range(rings - 1):
        for k in range(sides):
            a = 1 + i * sides + k
            b = 1 + i * sides + (k + 1) % sides
            faces.append([a, b, b + sides, a + sides])
    return C.Part("heap", smooth=False).add(verts, faces)


def clumps(rng):
    """Loose straw lies in clumps and tufts, not one smooth heap (the critic, round 1: a draped
    sheet): ragged lumps over the heap, flat-shaded."""
    part = C.Part("clumps", smooth=False)
    for i in range(14):
        a = rng.uniform(0, 2 * np.pi)
        d = rng.uniform(0.0, 0.85) ** 0.7
        x, z = np.cos(a) * 0.5 * d, np.sin(a) * 0.4 * d
        top = 0.2 * (1.0 - d ** 1.6)
        r = rng.uniform(0.09, 0.17)
        part.merge(C.blob("clump", (x, top * 0.6, z), (r, max(0.04, top * 0.6 + 0.03), r * rng.uniform(0.7, 1.2)), rings=4, sides=7,
                          squash_bottom=0.0, noise=0.3, seed=int(rng.integers(1000)), smooth=False))
    return part


def build():
    rng = np.random.default_rng(37)
    stalks = C.straws("stalks", rng, 260, (-0.55, -0.45, 0.55, 0.45), 0.12, length=(0.08, 0.25), lift=0.12)
    stalks.merge(C.straws("s", rng, 40, (-0.85, -0.7, 0.85, 0.7), 0.004, length=(0.08, 0.2), lift=0.0))
    heap_part = heap(rng)
    heap_part.merge(clumps(rng))
    return C.export("straw_pile", [heap_part, stalks])
