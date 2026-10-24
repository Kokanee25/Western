"""A feed sack standing, its neck tied (a burlap bag of oats, ~0.7 m high, ~40 kg): it sits wide
and slumped, the corners of its bottom spread on the ground, the cloth gathered into the tie and
the ears of it above. Parts: sack (burlap), tie (cord)."""
import math

import numpy as np

import common as C


def sack(rng):
    sides = 14
    # Height, half-width, half-depth: the slumped belly, then gathered to the neck and the ears.
    rows = [(0.0, 0.19, 0.13), (0.03, 0.215, 0.15), (0.12, 0.225, 0.16), (0.3, 0.215, 0.155), (0.45, 0.19, 0.135), (0.54, 0.14, 0.1),
            (0.6, 0.06, 0.05), (0.63, 0.035, 0.03), (0.66, 0.05, 0.04), (0.71, 0.075, 0.03)]
    verts, faces = [], []
    lean = rng.uniform(-0.03, 0.03)
    for i, (y, hw, hd) in enumerate(rows):
        for k in range(sides):
            th = 2 * math.pi * k / sides
            c, s = math.cos(th), math.sin(th)
            sq = 3.0 if i < 5 else 2.0
            x = hw * math.copysign(abs(c) ** (2 / sq), c)
            z = hd * math.copysign(abs(s) ** (2 / sq), s)
            j = 1.0 + rng.uniform(-0.03, 0.03)
            verts.append((x * j + lean * y, y + (rng.uniform(-0.01, 0.01) if 0 < i < len(rows) - 1 else 0.0), z * j))
    for i in range(len(rows) - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append([a, a + sides, b + sides, b])
    verts.append((0.0, 0.0, 0.0))
    verts.append((lean * 0.71, 0.715, 0.0))
    c0, c1 = len(verts) - 2, len(verts) - 1
    faces += [[c0, k, (k + 1) % sides] for k in range(sides)]
    base = (len(rows) - 1) * sides
    faces += [[c1, base + (k + 1) % sides, base + k] for k in range(sides)]
    return C.Part("sack").add(verts, faces), lean


def tie(lean):
    pts = []
    for k in range(13):
        th = 2 * math.pi * k / 12
        pts.append((0.038 * math.cos(th) + lean * 0.625, 0.625, 0.033 * math.sin(th)))
    part = C.tube("tie", pts, 0.008, sides=5, caps=(False, False))
    # Its ends hanging.
    part.merge(C.tube("end", [(0.035 + lean * 0.62, 0.625, 0.0), (0.06, 0.58, 0.02), (0.07, 0.53, 0.03)], 0.006, sides=5))
    return part


def build():
    rng = np.random.default_rng(41)
    s, lean = sack(rng)
    return C.export("feed_sack", [s, tie(lean)])
