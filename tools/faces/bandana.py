#!/usr/bin/env python3
"""Two bandanas fitted to a man: one knotted round his neck, its point hanging on his chest, and one
pulled up over his nose and mouth, tied behind his head (Sean, 2026-10-21: "bandanas that can
actually go over a face"). Added to his model as two cloth pieces, `cloth_bandana` and
`cloth_bandana_mask`; the game wears one or the other (PeopleBodies: the neck one when he has a
bandana, the mask when he's masked).

    python3 tools/faces/bandana.py --man=hothead_lyle_s2_talking --landmarks=FILE.npy \
        [--colour=R,G,B] [--neck=no]

→ assets/people/<man>.glb with the two pieces added (or replaced), <man>_bandana.png and
<man>_bandana_mask.png (the cloth), <man>.json `bandana` (what this did).

How each is fitted: his head and body are sampled as points and seen from his head's axis, a
cylinder's (angle, height) grid holding the outermost surface in each cell. Cloth hangs: going
down a column its distance from the axis never shrinks, so the mask falls straight from the tip of
his nose to his chin and on below it, the way a stretched cloth does, and anything further out
below (his chest) lifts it. Where it lies is set by his face's landmarks (MediaPipe's 478, found
on his own mesh): the mask's top edge under his eyes, its point below his chin; the neck one under
his jaw. --neck=no: a man whose own paint already has a bandana at his neck gets the mask only.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from glb_io import Glb  # noqa: E402

PEOPLE = os.path.join(ROOT, "assets", "people")

COLS = 96                 # columns round his head
ROWS = 16                 # rows from the top edge to the hem
CELL_DEG = 3.0            # the surface grid's angle step
CELL_M = 0.004            # and its height step
GAP_MASK = 0.006          # metres the mask stands off his skin
GAP_NECK = 0.012          # the neck one, looser
SPREAD_DEG = 4.0          # the surface widened this far round (the cloth bridges hollows)
# The mask: its top edge this far below his irises; its point this far below his chin; from this
# angle round (degrees from his front) it is only the band that ties it, this tall.
MASK_TOP = 0.026
MASK_POINT = 0.10
MASK_SIDE = 95.0
BAND = 0.022
GAP_BAND = 0.003         # the band that ties it, closer (it's pulled tight)
DIP = 0.018              # the band dips this much toward the knot at the back of his head
KNOT = (0.020, 0.015, 0.011)   # the knot's half-sizes: across, up, out (metres)
TAILS = ((0.075, 16.0), (0.062, -20.0))   # its two ends: length, and degrees off straight down (+: his left)
TAIL_W = (0.026, 0.012)  # an end's width at the knot and at its tip
# The neck one: its top this far below his chin's front, the roll this tall, its point this far
# below the roll.
NECK_TOP = 0.030
NECK_ROLL = 0.035
NECK_POINT = 0.11
NECK_REACH = 0.085          # metres from his head's axis: his neck, not his shoulders
TEX = (512, 256)


def sample_surface(meshes, n=400000, seed=3):
    """Points spread over the meshes' triangles (by area)."""
    rng = np.random.default_rng(seed)
    P = []
    areas = []
    tris = []
    for V, T in meshes:
        a, b, c = V[T[:, 0]], V[T[:, 1]], V[T[:, 2]]
        ar = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
        tris.append((a, b, c))
        areas.append(ar)
    tot = sum(x.sum() for x in areas)
    for (a, b, c), ar in zip(tris, areas):
        k = max(1, int(n * ar.sum() / tot))
        pick = rng.choice(len(ar), k, p=ar / ar.sum())
        u, v = rng.random(k), rng.random(k)
        flip = u + v > 1
        u[flip], v[flip] = 1 - u[flip], 1 - v[flip]
        P.append(a[pick] + (b[pick] - a[pick]) * u[:, None] + (c[pick] - a[pick]) * v[:, None])
    return np.concatenate(P)


class Shell:
    """His outermost surface seen from his head's axis: r(angle, height), angle 0 his front (-Z),
    positive to his left (+X)."""

    def __init__(self, P, axis, y_lo, y_hi):
        self.axis = axis
        self.y0 = y_lo
        th = np.degrees(np.arctan2(P[:, 0] - axis[0], -(P[:, 2] - axis[1])))
        r = np.hypot(P[:, 0] - axis[0], P[:, 2] - axis[1])
        keep = (P[:, 1] >= y_lo) & (P[:, 1] <= y_hi)
        th, r, y = th[keep], r[keep], P[keep, 1]
        self.na = int(round(360 / CELL_DEG))
        self.ny = int(math.ceil((y_hi - y_lo) / CELL_M)) + 1
        ia = np.round((th + 180) / CELL_DEG).astype(int) % self.na
        iy = np.clip(np.round((y - y_lo) / CELL_M).astype(int), 0, self.ny - 1)
        R = np.zeros((self.na, self.ny))
        np.maximum.at(R, (ia, iy), r)
        # Empty cells take their column's neighbours (a sparse sample), then the angle spread.
        for _ in range(3):
            empty = R == 0
            if not empty.any():
                break
            nb = np.maximum(np.roll(R, 1, 0), np.roll(R, -1, 0))
            nb = np.maximum(nb, np.maximum(np.roll(R, 1, 1), np.roll(R, -1, 1)))
            R[empty] = nb[empty]
        w = int(round(SPREAD_DEG / CELL_DEG))
        S = R.copy()
        for k in range(1, w + 1):
            S = np.maximum(S, np.maximum(np.roll(R, k, 0), np.roll(R, -k, 0)))
        self.R = S

    def r(self, ang, y):
        ia = np.round((np.asarray(ang) + 180) / CELL_DEG).astype(int) % self.na
        iy = np.clip(np.round((np.asarray(y) - self.y0) / CELL_M).astype(int), 0, self.ny - 1)
        return self.R[ia, iy]


def sheet(shell, top, bottom, gap, cols=COLS, rows=ROWS, band=None):
    """A cloth sheet round him: column angles all round, each from height top(a) down to bottom(a),
    its radius hung (never shrinking going down) off the shell plus the gap. → V (cols*rows, 3),
    UV, the grid's triangles (closed round)."""
    ang = np.linspace(-180, 180, cols, endpoint=False)
    V = np.zeros((cols, rows, 3))
    UV = np.zeros((cols, rows, 2))
    for i, a in enumerate(ang):
        y = np.linspace(top(a), bottom(a), rows)
        fine = np.linspace(top(a), bottom(a), rows * 6)
        rf = np.maximum.accumulate(shell.r(np.full_like(fine, a), fine)) + gap
        r = np.interp(y, fine[::-1], rf[::-1])
        t = np.radians(a)
        if band is not None:
            # Round the back it is only the band, pulled tight over his hair.
            r = r - (gap - band[1]) * band[0](a)
        V[i, :, 0] = shell.axis[0] + r * np.sin(t)
        V[i, :, 1] = y
        V[i, :, 2] = shell.axis[1] - r * np.cos(t)
        UV[i, :, 0] = (a + 180) / 360
        UV[i, :, 1] = np.linspace(0, 1, rows)
    T = []
    for i in range(cols):
        j = (i + 1) % cols
        for k in range(rows - 1):
            a, b, c, d = i * rows + k, j * rows + k, j * rows + k + 1, i * rows + k + 1
            T += [[a, b, c], [a, c, d]]
    return V.reshape(-1, 3), UV.reshape(-1, 2), np.array(T)


def knot_and_tails(shell, axis, y, V, UV, T):
    """The mask's knot at the back of his head, where the band meets, and its two ends hanging
    from it: added to the sheet (V, UV, T). His back is +Z from the axis."""
    back = np.array([0.0, 0.0, 1.0])
    r0 = float(shell.r(180, y)) + GAP_BAND
    c = np.array([axis[0], y, axis[1] + r0 + KNOT[2] * 0.6])
    # The knot: a squashed ball of cloth, its UVs a corner of the cloth.
    nu, nv = 10, 7
    kv, kuv = [], []
    for i in range(nv + 1):
        th = math.pi * i / nv
        for j in range(nu):
            ph = 2 * math.pi * j / nu
            d = np.array([math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)])
            kv.append(c + d * KNOT)
            kuv.append((0.02 + 0.06 * j / nu, 0.4 + 0.2 * i / nv))
    kt = []
    for i in range(nv):
        for j in range(nu):
            a, b = i * nu + j, i * nu + (j + 1) % nu
            cc, dd = a + nu, b + nu
            kt += [[a, b, dd], [a, dd, cc]]
    kv, kt = np.array(kv), np.array(kt)
    fn = np.cross(kv[kt[:, 1]] - kv[kt[:, 0]], kv[kt[:, 2]] - kv[kt[:, 0]])
    flip = np.einsum("ij,ij->i", fn, kv[kt].mean(1) - c) < 0
    kt[flip] = kt[flip][:, ::-1]
    parts = [(np.array(kv), np.array(kuv), kt)]
    # The ends: strips from under the knot, falling down and a little out, lying on his hair.
    rows = 7
    for length, ang in TAILS:
        t = math.radians(ang)
        down = np.array([math.sin(t), -math.cos(t), 0.0])
        side = np.array([math.cos(t), math.sin(t), 0.0])
        tv, tuv = [], []
        for k in range(rows):
            s = k / (rows - 1)
            p = c + down * (KNOT[1] * 0.5 + length * s)
            rr = float(shell.r(180, p[1])) + GAP_BAND + 0.004 + 0.006 * s
            p[2] = max(p[2] - KNOT[2] * 0.4, axis[1] + rr)
            w = TAIL_W[0] + (TAIL_W[1] - TAIL_W[0]) * s
            for e in (-0.5, 0.5):
                tv.append(p + side * w * e)
                tuv.append((0.1 + 0.05 * (e + 0.5), 0.1 + 0.8 * s))
        tt = []
        for k in range(rows - 1):
            a = 2 * k
            tt += [[a, a + 1, a + 3], [a, a + 3, a + 2]]
        tv, tt = np.array(tv), np.array(tt)
        tt = facing_out(tv, tt, axis)
        parts.append((tv, np.array(tuv), tt))
    for pv, puv, pt in parts:
        T = np.r_[T, pt + len(V)]
        V = np.r_[V, pv]
        UV = np.r_[UV, puv]
    return V, UV, T


def normals(V, T):
    N = np.zeros_like(V)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for j in range(3):
        np.add.at(N, T[:, j], fn)
    return N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)


def facing_out(V, T, axis):
    """Each triangle wound to face away from the axis (the game draws the cloth both sides, but
    its light comes from the normal)."""
    c = V[T].mean(1)
    out = np.c_[c[:, 0] - axis[0], np.zeros(len(c)), c[:, 2] - axis[1]]
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    flip = np.einsum("ij,ij->i", fn, out) < 0
    T = T.copy()
    T[flip] = T[flip][:, ::-1]
    return T


def cloth_texture(colour, seed):
    """Plain cotton in his colour, painted: a darker hem, a few folds, a faint printed dot."""
    rng = np.random.default_rng(seed)
    w, h = TEX
    base = np.array(colour, float)
    img = np.ones((h, w, 3)) * base
    yy, xx = np.mgrid[0:h, 0:w]
    # Folds: soft diagonal bands of shade, as the cloth gathers.
    shade = np.zeros((h, w))
    for _ in range(9):
        x0 = rng.uniform(0, w)
        ang = rng.uniform(-0.5, 0.5)
        width = rng.uniform(6, 18)
        d = np.abs((xx - x0) - ang * yy)
        shade += rng.uniform(0.08, 0.18) * np.exp(-(d / width) ** 2)
    img *= (1 - np.clip(shade, 0, 0.35))[..., None]
    # The hem: a darker line along the edges.
    hem = (yy > h - 10) | (yy < 6)
    img[hem] *= 0.72
    # A faint printed dot, lighter than the cloth.
    dots = ((xx % 22) - 11) ** 2 + ((yy + (xx // 22) % 2 * 11) % 22 - 11) ** 2 < 6
    img[dots] = img[dots] * 0.75 + np.minimum(base * 1.6 + 30, 255) * 0.25
    img *= (1 + rng.normal(0, 0.03, (h, w)))[..., None]
    out = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8))
    return out


def build(man, landmarks, colour, neck=True):
    path = os.path.join(PEOPLE, man + ".glb")
    g = Glb(path)
    names = g.joint_names()
    lm = np.load(landmarks)
    head = g.mesh("body_head")
    skin = g.mesh("body_skin")
    eye_y = float(lm[[468, 473], 1].mean())
    chin = lm[152]
    # His head's axis: the middle of its extent at eye height (a mean of its vertices sits forward,
    # his face having far more of them, and from there his sides fall away steeply).
    hv = head["V"]
    band = hv[np.abs(hv[:, 1] - eye_y) < 0.03]
    axis = (float((band[:, 0].min() + band[:, 0].max()) / 2), float((band[:, 2].min() + band[:, 2].max()) / 2))
    P = sample_surface([(head["V"], head["T"]), (skin["V"], skin["T"])])
    shell = Shell(P, axis, chin[1] - 0.35, eye_y + 0.15)
    rep = {"colour": list(colour), "neck": bool(neck)}

    def tri(a, lo, hi):
        """1 at his front, falling to 0 at `hi` degrees round, flat from `lo`."""
        a = abs(a)
        return float(np.clip((hi - a) / max(hi - lo, 1e-6), 0, 1))

    pieces = {}
    # The mask: the band all round at its top edge; in front, down over his face to a point.
    m_top = eye_y - MASK_TOP
    def mask_top(a):
        # level across his face, dipping round the back to the knot
        k = float(np.clip((abs(a) - 90) / 90, 0, 1))
        return m_top - DIP * k * k * (3 - 2 * k)
    def mask_bottom(a):
        f = tri(a, 0, MASK_SIDE)
        face = chin[1] - MASK_POINT * max(0.0, 1 - abs(a) / MASK_SIDE) ** 1.5
        return mask_top(a) - BAND + (face - (mask_top(a) - BAND)) * min(1.0, f * 1.6)
    V, UV, T = sheet(shell, mask_top, mask_bottom, GAP_MASK,
                     band=(lambda a: float(np.clip((abs(a) - 60) / 35, 0, 1)), GAP_BAND))
    T = facing_out(V, T, axis)
    V, UV, T = knot_and_tails(shell, axis, mask_top(180) - BAND / 2, V, UV, T)
    hj = names.index("head")
    pieces["cloth_bandana_mask"] = (V, UV, T, np.tile([hj, 0, 0, 0], (len(V), 1)), np.tile([1.0, 0, 0, 0], (len(V), 1)))
    rep["mask"] = {"top_y": round(m_top, 3), "point_y": round(float(mask_bottom(0)), 3), "triangles": len(T)}

    if neck:
        n_top = chin[1] - NECK_TOP
        neck_top = lambda a: n_top
        def neck_bottom(a):
            f = tri(a, 0, 70)
            return n_top - NECK_ROLL - NECK_POINT * f ** 1.5
        # The roll hugs his neck: at its height his shoulders are further out at the sides, so only
        # what is within his neck's reach counts there; below it, the front of his chest, which the
        # point lies on (not his shoulders, which the roll's sides would snag on).
        r_ax = np.hypot(P[:, 0] - axis[0], P[:, 2] - axis[1])
        roll_lo = n_top - NECK_ROLL - 0.01
        a_ax = np.degrees(np.arctan2(P[:, 0] - axis[0], -(P[:, 2] - axis[1])))
        on_neck = (r_ax < NECK_REACH) | ((P[:, 1] < roll_lo) & (np.abs(a_ax) < 55))
        neck_shell = Shell(P[on_neck], axis, chin[1] - 0.35, eye_y + 0.15)
        V, UV, T = sheet(neck_shell, neck_top, neck_bottom, GAP_NECK)
        T = facing_out(V, T, axis)
        nj, cj = names.index("neck"), names.index("chest")
        # The roll on his neck; its point, lying on his chest, moves with his chest.
        w_chest = np.clip((n_top - NECK_ROLL - V[:, 1]) / NECK_POINT, 0, 1)
        J = np.tile([nj, cj, 0, 0], (len(V), 1))
        W = np.c_[1 - w_chest, w_chest, np.zeros(len(V)), np.zeros(len(V))]
        pieces["cloth_bandana"] = (V, UV, T, J, W)
        rep["neck_piece"] = {"top_y": round(n_top, 3), "point_y": round(float(neck_bottom(0)), 3), "triangles": len(T)}

    for name, (V, UV, T, J, W) in pieces.items():
        g.set_mesh(name, V, normals(V, T), UV, J, W, T, node_like="body_head")
        tex = cloth_texture(colour, seed=len(name))
        tex.save(os.path.join(PEOPLE, "%s_%s.png" % (man, name[len("cloth_"):])))
    g.save(path)
    info_p = os.path.join(PEOPLE, man + ".json")
    info = json.load(open(info_p))
    info["bandana"] = rep
    json.dump(info, open(info_p, "w"), indent=1)
    print("bandana:", man, json.dumps(rep))


if __name__ == "__main__":
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    col = tuple(int(v) for v in a.get("--colour", "140,31,26").split(","))
    build(a["--man"], a["--landmarks"], col, a.get("--neck", "yes") != "no")
