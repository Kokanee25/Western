"""A hay bale (two-string, 3 ft by 18 in by 16 in, ~27 kg): a block of pressed hay, its corners
rounded and its faces bulged and ragged, two strings of twine round it, loose stalks sticking out.
Lying along X, on the ground. Parts: bale (straw), twine, stalks (straw)."""
import math

import numpy as np

import common as C

L, H, W = 0.9, 0.45, 0.5


def section(theta, hw, hh, n=5.0):
    """A rounded rectangle (superellipse) of half-sizes hw, hh at angle theta."""
    c, s = math.cos(theta), math.sin(theta)
    return hw * math.copysign(abs(c) ** (2.0 / n), c), hh * math.copysign(abs(s) ** (2.0 / n), s)


def bale(rng):
    sides = 20
    xs = [-L / 2, -L / 2 + 0.03, -L / 2 + 0.1, -0.2, 0.0, 0.2, L / 2 - 0.1, L / 2 - 0.03, L / 2]
    verts, faces = [], []
    for i, x in enumerate(xs):
        end = 1.0 - (0.12 if i in (0, len(xs) - 1) else 0.03 if i in (1, len(xs) - 2) else 0.0)
        bulge = 1.0 + 0.04 * math.cos(math.pi * x / L)
        for k in range(sides):
            th = 2 * math.pi * k / sides
            z, y = section(th, W / 2 * end * bulge, H / 2 * end * bulge)
            j = 1.0 + rng.uniform(-0.035, 0.035)
            verts.append((x + rng.uniform(-0.01, 0.01), H / 2 + y * j, z * j))
    for i in range(len(xs) - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append([a, a + sides, b + sides, b])
    n = len(xs)
    verts.append((-L / 2 - 0.005, H / 2, 0.0))
    verts.append((L / 2 + 0.005, H / 2, 0.0))
    c0, c1 = len(verts) - 2, len(verts) - 1
    faces += [[c0, k, (k + 1) % sides] for k in range(sides)]
    base = (n - 1) * sides
    faces += [[c1, base + (k + 1) % sides, base + k] for k in range(sides)]
    for v in range(len(verts)):
        x, y, z = verts[v]
        verts[v] = (x, max(0.0, y), z)
    return C.Part("bale").add(verts, faces)


def twine():
    part = C.Part("twine", smooth=True)
    for x in (-0.22, 0.22):
        pts = []
        for k in range(25):
            th = 2 * math.pi * k / 24
            z, y = section(th, W / 2 * 1.045, H / 2 * 1.045)
            pts.append((x, H / 2 + y, z))
        part.merge(C.tube("string", pts, 0.005, sides=4, caps=(False, False)))
    return part


def stalks(rng):
    part = C.straws("stalks", rng, 45, (-L / 2, -W / 2, L / 2, W / 2), H - 0.005, length=(0.08, 0.22), lift=0.06)
    # And some out of the ends and sides.
    for side in (-1, 1):
        part.merge(C.straws("s", rng, 12, (side * L / 2 - 0.05, -W / 2, side * L / 2 + 0.04, W / 2), rng.uniform(0.1, 0.35), length=(0.06, 0.16)))
    return part


def build():
    rng = np.random.default_rng(31)
    return C.export("hay_bale", [bale(rng), twine(), stalks(rng)])
