"""The mounted deer head (Sean on #338: "a real taxidermy mount: head, neck, antlers, on a shaped
wooden plaque, glass eyes"): a mule deer's shoulder mount, the head turned a little to its left as
taxidermists set them, a four-point rack. In the kit's space for `deer_head` (the plaque's back on
the wall at z 0.02, its top at y 0.02), so the kit file's members and nails stay where they were.

Parts: plaque (dark wood), neck and head and ears (hide), nose (the dark of the muzzle), eyes
(glass), antlers. ~1,500 triangles.
"""
import math

import numpy as np

import common as C

TURN = 0.03  # how far the head's turned off the plaque's middle (m, at the muzzle)


def _x(t):
    """The head's turn: nothing at the neck's root, TURN at the nose."""
    return TURN * max(0.0, min(1.0, t))


def plaque():
    half = [(0.0, -0.45), (0.07, -0.435), (0.13, -0.395), (0.168, -0.32), (0.182, -0.22), (0.176, -0.12), (0.165, -0.05),
            (0.178, -0.005), (0.16, 0.02), (0.1, 0.008), (0.045, 0.022), (0.0, 0.03)]
    outline = half + [(-x, y) for x, y in reversed(half[1:-1])]
    return C.slab("plaque", outline, 0.02, 0.054, bevel=0.012)


def neck():
    path = [(0.0, -0.275, 0.045), (0.0, -0.255, 0.11), (0.004, -0.225, 0.175), (0.01, -0.19, 0.23), (0.016, -0.16, 0.27), (0.02, -0.14, 0.295)]
    radii = [(0.125, 0.165), (0.118, 0.15), (0.104, 0.128), (0.09, 0.106), (0.08, 0.09), (0.074, 0.08)]
    # Closed where the head comes out of it (the critic: from the side, a hollow).
    return C.tube("neck", path, radii, sides=16, caps=(False, True), noise=0.05, seed=3)


def head():
    # The skull from the poll forward and down to the nose: wide at the eyes, a long tapering face.
    ts = np.linspace(0.0, 1.0, 11)
    path = [(0.02 + _x(t), -0.135 - 0.085 * t ** 1.3, 0.275 + 0.235 * t) for t in ts]
    radii = [(0.072 - 0.038 * t, 0.078 - 0.042 * t + 0.01 * math.sin(math.pi * t)) for t in ts]
    return C.tube("head", path, radii, sides=16, caps=(True, True), seed=5)


def nose():
    return C.blob("nose", (0.02 + TURN, -0.222, 0.506), (0.03, 0.024, 0.016), rings=5, sides=10)


def eyes():
    part = C.Part("eyes")
    for side in (-1, 1):
        part.merge(C.blob("eye", (0.02 + _x(0.25) + side * 0.06, -0.135, 0.335), (0.012, 0.014, 0.014), rings=5, sides=8))
    return part


def ears():
    part = C.Part("ears")
    for side in (-1, 1):
        base = np.array([0.02 + side * 0.05, -0.095, 0.27])
        tip = base + np.array([side * 0.12, 0.06, -0.03])
        path = [base + (tip - base) * t for t in np.linspace(0, 1, 5)]
        radii = [(0.034 * math.sin(math.pi * (0.15 + 0.85 * t)) + 0.004, 0.009) for t in np.linspace(0, 1, 5)]
        part.merge(C.tube("ear", path, radii, sides=8, up_hint=(0, 0, 1)))
    return part


def antlers():
    """A mule deer's rack: each main beam out and back from its burr then forward, forked twice,
    a brow tine; knobbed (noise) and tapering."""
    part = C.Part("antlers")
    for side in (-1, 1):
        def p(x, y, z):
            return np.array([0.02 + side * x, y, z])
        beam = [p(0.04, -0.07, 0.29), p(0.085, 0.0, 0.272), p(0.15, 0.09, 0.248), p(0.205, 0.18, 0.245), p(0.225, 0.27, 0.27), p(0.21, 0.35, 0.31),
                p(0.17, 0.41, 0.35)]
        part.merge(C.tube("beam", beam, [0.021, 0.018, 0.016, 0.014, 0.012, 0.009, 0.005], sides=7, noise=0.12, seed=7 + side))
        # The burr where it leaves the skull.
        part.merge(C.tube("burr", [p(0.035, -0.08, 0.292), p(0.045, -0.06, 0.288)], [0.028, 0.028], sides=8, noise=0.2, seed=11 + side))
        tines = [
            [p(0.08, -0.01, 0.272), p(0.09, 0.03, 0.32), p(0.095, 0.06, 0.36)],                              # brow
            [p(0.2, 0.17, 0.246), p(0.17, 0.25, 0.22), p(0.15, 0.32, 0.2)],                                   # back fork
            [p(0.222, 0.26, 0.268), p(0.28, 0.33, 0.25), p(0.31, 0.4, 0.24)],                                 # outer fork
            [p(0.2, 0.36, 0.315), p(0.23, 0.44, 0.31), p(0.24, 0.5, 0.3)],                                    # top
        ]
        for i, t in enumerate(tines):
            part.merge(C.tube("tine", t, [0.011, 0.008, 0.004], sides=6, noise=0.1, seed=20 + i * 2 + side))
    return part


def build():
    return C.export("deer_head", [plaque(), neck(), head(), nose(), eyes(), ears(), antlers()])
