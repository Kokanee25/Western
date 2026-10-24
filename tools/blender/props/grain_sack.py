"""A grain sack lying full on its side (a 100 lb sack of wheat or corn, ~0.75 by 0.45 by 0.24 m):
a pillow, its sewn end flat and its tied end gathered into ears. For stacking (the kit's
grain_sacks lays three of it). Parts: sack (burlap), tie (cord)."""
import math

import numpy as np

import common as C


def sack(rng):
    sides = 16
    # Along X: the sewn end at -X square, the tied end at +X gathered.
    rows = [(-0.37, 0.19, 0.08), (-0.35, 0.215, 0.11), (-0.28, 0.225, 0.12), (-0.1, 0.228, 0.122), (0.1, 0.225, 0.12),
            (0.25, 0.205, 0.11), (0.32, 0.13, 0.07), (0.355, 0.04, 0.03), (0.38, 0.06, 0.02)]
    verts, faces = [], []
    for i, (x, hz, hy) in enumerate(rows):
        for k in range(sides):
            th = 2 * math.pi * k / sides
            c, s = math.cos(th), math.sin(th)
            z = hz * math.copysign(abs(c) ** (2 / 3.0), c)
            y = hy * math.copysign(abs(s) ** (2 / 2.5), s)
            j = 1.0 + rng.uniform(-0.025, 0.025)
            verts.append((x, max(0.0, 0.12 + y * j), z * j))
    for i in range(len(rows) - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append([a, a + sides, b + sides, b])
    verts.append((-0.372, 0.12, 0.0))
    verts.append((0.382, 0.12, 0.0))
    c0, c1 = len(verts) - 2, len(verts) - 1
    faces += [[c0, k, (k + 1) % sides] for k in range(sides)]
    base = (len(rows) - 1) * sides
    faces += [[c1, base + (k + 1) % sides, base + k] for k in range(sides)]
    return C.Part("sack").add(verts, faces)


def tie():
    pts = [(0.345, 0.12 + 0.035 * math.sin(2 * math.pi * k / 12), 0.04 * math.cos(2 * math.pi * k / 12)) for k in range(13)]
    return C.tube("tie", pts, 0.008, sides=5, caps=(False, False))


def build():
    rng = np.random.default_rng(43)
    return C.export("grain_sack", [sack(rng), tie()])
