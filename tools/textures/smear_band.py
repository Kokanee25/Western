#!/usr/bin/env python3
"""The drag smear's pieces (WoundSigns._smears): a band that tiles end to end along its length, the
heavy start where he lay, the feathered end where it runs out, and a long drop for a slanting splat.

A swipe left by a bleeding body drawn over a floor is a band about as wide as what touched, streaked
along the way it went (the cloth's folds), heaviest where it started and breaking up into separate
streaks at the end, the feathered edge pointing the way it went (Bevel & Gardner, *Bloodstain
Pattern Analysis*, 3rd ed., ch. 9 "transfer patterns"; James, Kish & Sutton 2005, "swipes").

Laid on the floor by a Decal, the texture's top row (v = 0) is the decal's -Z end and its bottom
row +Z, so every piece runs top to bottom the way he moved. Drawn nearest with no mipmaps, so the
squares are coarse (32 across a 24 cm band: ~7.5 mm a square, a couple of screen pixels at 720p
from standing) and the colours are the splats' reds, so a thin film darkens the wood rather than
tinting it pink.

    python3 tools/textures/smear_band.py   # writes assets/textures/blood/smear_{band0-2,start,end}.png, splat_long.png
"""
import math
import os
import random

from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "textures", "blood")
W, H = 32, 64
SEED = 7319
BANDS = 3  ## band variants, the same at their ends (WoundSigns picks one a piece)

# The splats' reds (assets/textures/blood/splat0.png's commonest) dark to light, and a thinner,
# redder film past them (a smear is a thinner layer than a splat: more of the red, less of the dark).
REDS = [(58, 7, 6), (72, 8, 7), (86, 10, 8), (100, 12, 9), (118, 16, 11), (136, 22, 14)]


def _lattice(n, rng):
    return [rng.random() for _ in range(n)]


def _periodic(t, period, values):
    """Smooth value noise along t, repeating every `period` (values: one a lattice point)."""
    n = len(values)
    f = (t / period) * n
    i = math.floor(f)
    u = f - i
    u = u * u * (3 - 2 * u)
    a = values[i % n]
    b = values[(i + 1) % n]
    return a + (b - a) * u


class Grid:
    """Smooth 2D value noise, nx by ny cells over W x H, repeating in both."""

    def __init__(self, nx, ny, rng):
        self.nx, self.ny = nx, ny
        self.v = [[rng.random() for _ in range(nx)] for _ in range(ny)]

    def at(self, x, y):
        fx, fy = x / W * self.nx, y / H * self.ny
        ix, iy = math.floor(fx), math.floor(fy)
        u, w = fx - ix, fy - iy
        u, w = u * u * (3 - 2 * u), w * w * (3 - 2 * w)
        g = self.v
        a = g[iy % self.ny][ix % self.nx]
        b = g[iy % self.ny][(ix + 1) % self.nx]
        c = g[(iy + 1) % self.ny][ix % self.nx]
        d = g[(iy + 1) % self.ny][(ix + 1) % self.nx]
        return (a + (b - a) * u) * (1 - w) + (c + (d - c) * u) * w


class Field:
    """The smear's streaks and edges as functions of (x, y), periodic in y every H rows."""

    def __init__(self, seed):
        rng = random.Random(seed)
        # Streaks across the band: fixed per column, a coarse and a fine set (the cloth's folds and
        # its weave).
        self.coarse = _lattice(6, rng)
        self.fine = _lattice(16, rng)
        # The streaks wander a little along the length (periodic, so the band tiles).
        self.drift = [_lattice(4, rng) for _ in range(3)]
        # The two edges, ragged along the length, and the band breathing wider and narrower.
        self.left = [_lattice(9, rng), _lattice(3, rng)]
        self.right = [_lattice(9, rng), _lattice(3, rng)]
        self.breath = _lattice(2, rng)
        # Where the cloth lifted off: patches drawn out along the way he went.
        self.lift = Grid(5, 3, rng)
        self.lift_fine = Grid(10, 6, rng)
        self.rng = rng
        self.alt = None

    def variant(self, seed):
        """The same band with its own lifts, wander and edges in the middle of its length, the same
        at both ends: pieces of any variants join."""
        rng = random.Random(seed)
        self.alt = (Grid(5, 3, rng), Grid(10, 6, rng), _lattice(9, rng), _lattice(9, rng), _lattice(4, rng))
        return self

    def _mix(self, y):
        return min(1.0, 10.0 * math.sin(math.pi * y / H)) if self.alt else 0.0

    def streak(self, x, y):
        k = self._mix(y)
        drift = _periodic(y, H, self.drift[0])
        if k:
            drift += (_periodic(y, H, self.alt[4]) - drift) * k
        wander = (drift - 0.5) * 1.0
        xs = x + wander
        c = _periodic(xs, W, self.coarse)
        f = _periodic(xs, W, self.fine)
        along = _periodic(y + x * 3.1, H, self.drift[1])  # some streaks thin out and come back
        return 0.5 * c + 0.3 * f + 0.2 * along

    def lifted(self, x, y):
        v = 0.65 * self.lift.at(x, y) + 0.35 * self.lift_fine.at(x, y)
        k = self._mix(y)
        if k:
            v += (0.65 * self.alt[0].at(x, y) + 0.35 * self.alt[1].at(x, y) - v) * k
        return v

    def edges(self, y):
        k = self._mix(y)
        el = _periodic(y, H, self.left[0])
        er = _periodic(y, H, self.right[0])
        if k:
            el += (_periodic(y, H, self.alt[2]) - el) * k
            er += (_periodic(y, H, self.alt[3]) - er) * k
        narrow = 3.0 * _periodic(y, H, self.breath)
        l = 1.0 + narrow + 3.6 * el + 2.0 * _periodic(y, H, self.left[1])
        r = W - 1.0 - narrow - 3.6 * er - 2.0 * _periodic(y, H, self.right[1])
        return l, r


def _colour(v, alpha):
    i = max(0, min(len(REDS) - 1, int((1.0 - v) * len(REDS))))
    return REDS[i] + (alpha,)


def _shade(field, x, y, heavy=0.0, thin=0.0):
    """The colour at (x, y): `heavy` (0..1) fills the gaps and darkens it (where he lay), `thin`
    (0..1) leaves only the strongest streaks (where it runs out)."""
    l, r = field.edges(y)
    cx = x + 0.5
    if cx < l or cx > r:
        return (0, 0, 0, 0)
    s = field.streak(cx, y)
    rim = min(cx - l, r - cx)
    if rim < 1.5:
        s += 0.1  # blood pushed up at the edges
    # Where the cloth lifted the floor shows through (less of it where he lay heavy).
    if field.lifted(cx, y) < 0.34 - 0.3 * heavy + 0.2 * thin:
        return (0, 0, 0, 0)
    gap = 0.36 - 0.35 * heavy + 0.55 * thin
    if s < gap:
        return (0, 0, 0, 0)
    v = min(1.0, (s - gap) / max(0.25, 1.0 - gap) * 0.9 + 0.5 * heavy)
    # Alpha in three steps: a thin film lets the wood through, the streaks don't.
    alpha = 235 if v > 0.6 else (190 if v > 0.3 else 140)
    return _colour(v, alpha)


def band(field):
    img = Image.new("RGBA", (W, H))
    for y in range(H):
        for x in range(W):
            img.putpixel((x, y), _shade(field, x, y))
    return img


def start(field):
    """The first piece: where he lay at the top, a heavy ragged patch (what soaked into him there),
    running into the band at the bottom (its last row runs into the band's first)."""
    rng = random.Random(SEED + 3)
    lobes = [rng.random() for _ in range(7)]
    img = Image.new("RGBA", (W, H))
    cy, ry = H * 0.3, H * 0.3
    for y in range(H):
        heavy = max(0.0, 1.0 - y / (H * 0.85))
        for x in range(W):
            if y < cy:
                # Above the middle, a ragged round end: its reach out from the centre by angle.
                dx, dy = (x + 0.5 - W / 2) / (W / 2), (y + 0.5 - cy) / ry
                ang = math.atan2(dy, dx)
                reach = 0.8 + 0.3 * _periodic(ang % (2 * math.pi), 2 * math.pi, lobes)
                if dx * dx + dy * dy > reach * reach:
                    continue
            img.putpixel((x, y), _shade(field, x, y, heavy=heavy))
    return img


def end(field):
    """The last piece: the band at the top, breaking up into separate streaks that end each at its
    own length, the feathered edge pointing the way he went (down the image)."""
    rng = random.Random(SEED + 5)
    stop = [H * (0.45 + 0.5 * rng.random() ** 0.7) for _ in range(W)]
    img = Image.new("RGBA", (W, H))
    for y in range(H):
        thin = min(1.0, y / (H * 0.55))
        for x in range(W):
            if y > stop[x]:
                continue
            p = _shade(field, x, y, thin=thin * 0.6)
            if p[3] and y > stop[x] - 6:
                p = p[:3] + (min(p[3], 140),)  # each streak's tip a thin film
            img.putpixel((x, y), p)
    return img


def splat_long():
    """A drop that hit at a slant: an elongated stain, the body at the top and its tail and a
    spine or two running on down the way it flew (Balthazard; James, Kish & Sutton 2005)."""
    w, h = 32, 64
    rng = random.Random(SEED + 11)
    img = Image.new("RGBA", (w, h))
    cx = w / 2
    body_top, body_len, half_w = 6.0, 34.0, 8.5
    for y in range(h):
        for x in range(w):
            px, py = x + 0.5, y + 0.5
            # The body: an ellipse, fullest a third of the way down.
            t = (py - body_top) / body_len
            if 0.0 <= t <= 1.0:
                prof = math.sin(math.pi * min(1.0, t * 1.5 if t < 0.333 else 0.5 + (t - 0.333) * 0.75))
                hw = half_w * prof ** 0.7 * (1.0 - 0.6 * max(0.0, t - 0.5))
                if abs(px - cx) <= hw:
                    v = 1.0 - abs(px - cx) / max(1.0, hw) * 0.6
                    img.putpixel((x, y), _colour(min(1.0, v + 0.2 * (1 - t)), 255))
                    continue
            # The tail: narrow, on down past the body.
            if body_top + body_len * 0.8 <= py <= h - 6:
                k = (py - body_top - body_len * 0.8) / (h - 6 - body_top - body_len * 0.8)
                if abs(px - cx) <= 1.6 * (1.0 - k) + 0.4:
                    img.putpixel((x, y), _colour(0.5, 255))
    # A few satellite drops thrown on ahead of it.
    for _ in range(3):
        sx = int(cx + rng.uniform(-6, 6))
        sy = int(rng.uniform(h - 12, h - 2))
        for dx in (0, 1):
            img.putpixel((min(w - 1, sx + dx), sy), _colour(0.6, 255))
    return img


def main():
    field = Field(SEED)
    os.makedirs(OUT, exist_ok=True)
    pieces = [("smear_band%d" % i, band(Field(SEED).variant(SEED + 100 + i))) for i in range(BANDS)]
    for name, img in pieces + [("smear_start", start(field)), ("smear_end", end(field)),
                               ("splat_long", splat_long())]:
        path = os.path.join(OUT, name + ".png")
        img.save(path)
        print("wrote", os.path.relpath(path))


if __name__ == "__main__":
    main()
