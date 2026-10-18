"""Garments made on a man's base body (docs/briefs/garments.md): a shirt with a stand collar, its
points and separate sleeves, a waistcoat and trousers, each its own clean mesh, painted from his
pictures by projection, written as pieces tools/blender/fit_tripo.py carries on him as they are.

    ~/bpyenv/bin/python tools/characters/garments.py --body=bold_cowboy_body --out=bold_cowboy_made \\
        --garments=shirt --views=front:PATH,left:PATH,right:PATH,back:PATH [--preview]

- His base body (assets/people/tripo/test/<body>_rodin.glb) in his Tripo frame (twin_pieces.frame:
  facing +X, his right +Z, 1.0 tall) with his joints found from his shape (fit_tripo.find_joints).
- Each garment part is a **tube lofted from his cross-sections**: round a bone (the trunk's
  axis, a sleeve's shoulder to wrist) in ROWS bands and ANGLES angles, the radius of his skin
  there (the 90th percentile of the points in the cell, the arm's points left out of the trunk's
  tube and the trunk's out of a sleeve's), filled where he has no skin (the armhole, under his
  arm: straight down between the rows above and below), smoothed, and pushed out by the cloth's
  OFFSET. A sleeve is its own tube joined to nothing: no shirt can lie between his arm and his
  side. Where a tube runs inside another (the sleeve's head in the body, the body's side in the
  sleeve) the hidden faces are cut.
- The collar: a band round his neck from the shirt's top to COLLAR_UNDER_CHIN below his chin,
  leaning out COLLAR_LEAN; two points folded down from its front edge over his chest, either
  side of the tie's knot; the tie a knot and two ends lying TIE_OFF off his chest.
- UVs by construction: each tube unwrapped flat (angle across, height down), every part its own
  upright island in a fixed layout, at the skin's density (TEX a side).
- Painted as body_paint.py --dressed paints a twin: his body and every garment, stood as the
  pictures show him, lined up with each picture by the figure's outline; each garment texel
  takes the colour of the picture facing it squarest that sees it (depth-tested against the
  whole dressed man), only colour of the garment's own kind (light: shirt; dark: tie, waistcoat,
  trousers), feathered between views; what no picture sees is filled from its own island.
→ assets/people/tripo/<out>_<garment>.glb + .json (`twin`: the body, `painted`, `made`), and
  build/garments/<out>_*.png (previews, the outline fits, which view painted what).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TRIPO = os.path.join(ROOT, "assets", "people", "tripo")
WORK = os.path.join(ROOT, "build", "garments")
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
import portrait as P  # noqa: E402
import body_paint as BP  # noqa: E402
import twin_pieces as TP  # noqa: E402
import fit_tripo as FT  # noqa: E402

TEX = 2048
# Metres, turned into his frame by his height (fit_tripo's report, assets/people/<body>.json).
OFFSET = {"shirt": 0.006, "vest": 0.014, "trousers": 0.009}
ARM_R = 0.050          # of his height: skin nearer his arm's bone than this is his arm's (t > ARM_FROM) ...
ARM_FROM = 0.22        # of the way down his arm: above it his shoulder and deltoid are the trunk's (the yoke)
ARM_LOW_R = 0.10       # ... and below ARM_LOW of the way down it (his hand, his cuff) this much nearer
ARM_LOW = 0.35
SLEEVE_R = 0.080       # of his height: skin within this of the arm's bone makes the sleeve
SLEEVE_HEAD_T = 0.2    # of the way down the arm: above it the sleeve's head takes its outer side's radius on its inner side
NECK_BASE_WIDE = 2.0   # the neck's base: where his neck is this much wider than its narrowest
CHIN_WIDE = 1.2        # his chin: where, above the narrowest, he is this much wider again
ROWS = {"trunk": 36, "sleeve": 28, "collar": 4, "leg": 30}
ANGLES = {"trunk": 56, "sleeve": 28, "collar": 36, "leg": 28}
PCT = 95               # the percentile of a cell's radii that is "his skin" there
HEM_BELOW_HIP = 0.07   # metres: the shirt's hem under his hip joints (tucked under the trousers)
CUFF_PAST = 0.02       # of the way past his wrist a sleeve runs (fit_tripo.clear_hands trims it)
COLLAR_UNDER_CHIN = 0.02    # metres: the collar's top under his chin (the neck ring is 0.03 under it; at 0.008 it
                            # ran up into the grafted head's fuller jaw)
COLLAR_GAP = (4.0, 13.0)    # degrees either side of his front the stand is open, at its foot and top (the knot's gap)
COLLAR_LEAN = 0.10     # out per up: the stand leans out
COLLAR_EASE = 0.010    # metres the stand stands off his neck at its narrowest (its radius there, all the way up:
                       # with the neck base's radius, where his trapezius flares, it was a ring as wide as his
                       # shoulders' top, a neck brace; 2026-10-18)
COLLAR_TRUNK_UNDER = 0.006 # metres the shirt's trunk ends under the collar's top, inside it
COLLAR_BACK_DROP = 0.014   # metres the stand's top is lower behind (a collar sits lower at the nape)
COLLAR_OVERLAP = 0.012 # metres the band reaches down into the shirt's top
NECK_R = 0.075         # of his height: skin within this of the neck's axis is his neck's
# The turned-down collar: a stand round his neck and a fall folded down over it from the fold
# (the stand's top), FALL_DEPTH down round the back and sides and FALL_OUT out from the stand at
# its lower edge; in front it ends in two points, from POINT["in"] degrees either side of the
# front (the gap the tie's knot sits in) to POINT["out"], their tips POINT["drop"] below the
# fold, lying POINT["stand"] off his chest.
FALL_DEPTH = 0.034     # metres
FALL_OUT = 0.006       # metres (0.022 flared it out all round like a lampshade)
FALL_ROWS = 5
POINT = {"in": 13.0, "out": 50.0, "drop": 0.062, "stand": 0.014}
FILL_FEATHER = 24     # texels: unpainted cloth goes from its painted edge to its class's own colour over this
SKIN_MASK = 0.01       # of the figure's height: picture pixels this near his own hands' and head's outline are never sampled
                       # (0.02 swallowed his whole collar under his chin; the hue rule keeps his skin off now)
FILL_LIT = 60          # unpainted cloth's colour: the median of its painted texels lighter than this percentile (the
                       # whole median was the shirt's shadowed tan, on a collar his pictures show white)
TIE = {"knot": (0.034, 0.026, 0.016), "width": 0.036, "length": 0.17, "spread": 0.03, "off": 0.012, "drop": 0.008}
# What each garment is in his pictures (Lab: L from, L to, chroma at most), measured on the
# arms-out front picture (2026-10-18): the shirt L 65-87, chroma 13-31 (warm cream); his skin
# L 39-69 at chroma 35-55; the waistcoat L 8-38, chroma 4-38; the tie L under 40, chroma under 25.
# A garment's colours in his pictures: Lab lightness from, to, chroma up to, and a hue (degrees) from
# when its chroma is over HUE_FROM_CHROMA (his cream shirt is hue ~75, his throat ~53: by lightness
# and chroma alone his skin painted his collar tan, 2026-10-18).
CLASS = {"shirt": (58.0, 101.0, 31.0, 62.0), "tie": (0.0, 42.0, 24.0, 0.0), "vest": (4.0, 46.0, 42.0, 0.0),
         "trousers": (0.0, 46.0, 16.0, 0.0)}
HUE_FROM_CHROMA = 12.0
# Each part's island in the texture (left, top, width, height), as shares of it.
# The waistcoat (metres): its hem this far above his hip joints at his back, its two front points
# this much lower; its V open from his neck's base down this far, as wide at the top as his
# neck; its armholes ovals this wide (front to back) and tall, centred this far under his shoulder
# joint, reaching this far in from it towards his neck (and all the way out past it); its shoulder
# seam ending this far inside his shoulder joint. Measured on the cut twin's
# waistcoat (hem 0.21 above the hip at the back, points 0.165; the V to 0.15 under the neck's base);
# the hem lowered to 0.17 (at 0.21 the shirt showed between it and the trousers behind) and the
# shoulders cut in further (seam_in 0.075, arm_in 0.11; at 0.05/0.09 they stood broader than his
# pictures'); the armholes a waistcoat's (arm_h 0.16 from arm_down 0.03: at 0.22 from 0.05, with the
# seam's cut running down to their foot, the waistcoat was a plate and the shirt showed down both
# his flanks in the game's stand), the shoulder seam's straight cut only over his shoulder
# (above seam_low under the joint).
VEST = {"hem": 0.17, "points": 0.045, "notch": 0.8, "v_depth": 0.15, "v_top": 0.085,
        "arm_w": 0.13, "arm_h": 0.16, "arm_down": 0.03, "arm_in": 0.11, "seam_in": 0.075, "top": 0.004,
        "seam_low": 0.02}
LAYOUT = {"vest": {"vest": (0.0, 0.0, 1.0, 0.8)},
          "shirt": {"trunk": (0.0, 0.0, 0.52, 0.5), "sleeve_r": (0.53, 0.0, 0.22, 0.5), "sleeve_l": (0.76, 0.0, 0.22, 0.5),
                    "collar": (0.0, 0.52, 0.5, 0.06), "fall": (0.0, 0.6, 0.5, 0.12),
                    "knot": (0.74, 0.52, 0.08, 0.06), "tie_r": (0.52, 0.64, 0.06, 0.3), "tie_l": (0.6, 0.64, 0.06, 0.3)}}


class Mesh:
    def __init__(self):
        self.v, self.uv, self.tris, self.part = [], [], [], []
        self.tubes = {}

    def add(self, v, uv, tris, part):
        k = len(self.v)
        self.v += list(v)
        self.uv += list(uv)
        self.tris += [[i + k for i in t] for t in tris]
        self.part += [part] * len(tris)

    def arrays(self):
        return np.array(self.v, float), np.array(self.uv, float), np.array(self.tris, int), np.array(self.part)


class Tube:
    """A surface round an axis a→b: R[i, j] at ROWS t's along it and ANGLES round it."""

    def __init__(self, a, b, ts, R, e1, e2):
        self.a, self.b, self.ts, self.R, self.e1, self.e2 = a, b, ts, R, e1, e2

    def radius_at(self, p):
        """The tube's radius at each point's t and angle (bilinear), and the point's own radius
        and t: inside when r < R."""
        ab = self.b - self.a
        t = (p - self.a) @ ab / max(float(ab @ ab), 1e-12)
        q = p - (self.a + t[:, None] * ab)
        ang = np.arctan2(q @ self.e2, q @ self.e1) % (2 * np.pi)
        n = self.R.shape[1]
        fj = ang / (2 * np.pi) * n
        j0 = np.floor(fj).astype(int) % n
        j1 = (j0 + 1) % n
        wj = fj - np.floor(fj)
        fi = np.interp(t, self.ts, np.arange(len(self.ts)))
        i0 = np.clip(np.floor(fi).astype(int), 0, len(self.ts) - 1)
        i1 = np.clip(i0 + 1, 0, len(self.ts) - 1)
        wi = np.clip(fi - i0, 0, 1)
        R = ((1 - wi) * ((1 - wj) * self.R[i0, j0] + wj * self.R[i0, j1]) + wi * ((1 - wj) * self.R[i1, j0] + wj * self.R[i1, j1]))
        return R, np.linalg.norm(q, axis=1), t


def _basis(ab, front):
    ab = ab / max(np.linalg.norm(ab), 1e-12)
    e1 = front - (front @ ab) * ab
    e1 /= max(np.linalg.norm(e1), 1e-12)
    e2 = np.cross(ab, e1)
    return e1, e2


def loft(pts, a, b, t0, t1, rows, angles, offset, rmax_of_median=None, fill="down", front=np.array([1.0, 0, 0])):
    """A tube of his skin round the axis a→b, from t0 to t1 of it, pushed out by offset."""
    ab = b - a
    e1, e2 = _basis(ab, front)
    t = (pts - a) @ ab / max(float(ab @ ab), 1e-12)
    q = pts - (a + t[:, None] * ab)
    ang = np.arctan2(q @ e2, q @ e1) % (2 * np.pi)
    rad = np.linalg.norm(q, axis=1)
    ts = np.linspace(t0, t1, rows)
    dt = (t1 - t0) / (rows - 1)
    R = np.full((rows, angles), np.nan)
    ji = np.round(ang / (2 * np.pi) * angles).astype(int) % angles   # bins centred on the vertices' angles
    for i, tc in enumerate(ts):
        sel = np.abs(t - tc) < dt * 0.6
        for j in range(angles):
            cell = rad[sel & (ji == j)]
            if len(cell) >= 3:
                R[i, j] = np.percentile(cell, PCT)
    # Fill: straight down between the rows above and below (the armhole), then round.
    if fill == "down":
        for j in range(angles):
            col = R[:, j]
            ok = np.isfinite(col)
            if ok.sum() >= 2:
                R[:, j] = np.interp(np.arange(rows), np.nonzero(ok)[0], col[ok])
    for i in range(rows):
        row = R[i]
        ok = np.isfinite(row)
        if 0 < ok.sum() < angles:
            js = np.nonzero(ok)[0]
            R[i] = np.interp(np.arange(angles), np.r_[js - angles, js, js + angles], np.r_[row[js], row[js], row[js]])
        elif ok.sum() == 0:
            R[i] = np.nan
    ok_rows = np.nonzero(np.isfinite(R).all(1))[0]
    for i in range(rows):
        if not np.isfinite(R[i]).all():
            R[i] = R[ok_rows[np.argmin(np.abs(ok_rows - i))]]
    if rmax_of_median:
        R = np.minimum(R, rmax_of_median * np.median(R, axis=1, keepdims=True))
    R = (np.roll(R, 1, 1) + 2 * R + np.roll(R, -1, 1)) / 4
    R[1:-1] = (R[:-2] + 2 * R[1:-1] + R[2:]) / 4
    R += offset
    return Tube(a, b, ts, R, e1, e2)


def tube_mesh(tube, mesh, part, rect, closed=False):
    """The tube's grid as faces: angle across, t down; the seam column doubled for the UVs."""
    rows, angles = tube.R.shape
    ab = tube.b - tube.a
    V, UV, k = [], [], {}
    left, top, w, h = rect
    for i, t in enumerate(tube.ts):
        for j in range(angles + 1):
            jj = j % angles
            th = 2 * np.pi * jj / angles
            V.append(tube.a + t * ab + tube.R[i, jj] * (np.cos(th) * tube.e1 + np.sin(th) * tube.e2))
            UV.append([left + w * j / angles, top + h * i / (rows - 1)])
            k[(i, j)] = len(V) - 1
    tris = []
    for i in range(rows - 1):
        for j in range(angles):
            a, b, c, d = k[(i, j)], k[(i, j + 1)], k[(i + 1, j + 1)], k[(i + 1, j)]
            tris += [[a, b, c], [a, c, d]]
    mesh.add(V, UV, tris, part)
    mesh.tubes[part] = tube


def grid_mesh(P4, mesh, part, rect, n=4, m=4):
    """A strip between corners P4 = (A, B, C, D) (A-B one edge, D-C the opposite), n x m cells."""
    A, B, C, D = [np.asarray(p, float) for p in P4]
    left, top, w, h = rect
    V, UV, k = [], [], {}
    for i in range(n + 1):
        s = i / n
        for j in range(m + 1):
            u = j / m
            V.append((1 - s) * ((1 - u) * A + u * B) + s * ((1 - u) * D + u * C))
            UV.append([left + w * u, top + h * s])
            k[(i, j)] = len(V) - 1
    tris = []
    for i in range(n):
        for j in range(m):
            a, b, c, d = k[(i, j)], k[(i, j + 1)], k[(i + 1, j + 1)], k[(i + 1, j)]
            tris += [[a, b, c], [a, c, d]]
    mesh.add(V, UV, tris, part)


def cut_inside(mesh, part, tube, margin, t_range=(-1e9, 1e9)):
    """Drop this part's faces whose centres lie inside the tube (hidden under it)."""
    v, uv, tris, parts = mesh.arrays()
    cen = v[tris].mean(1)
    R, r, t = tube.radius_at(cen)
    inside = (parts == part) & (r < R - margin) & (t > t_range[0]) & (t < t_range[1])
    keep = ~inside
    mesh.tris = [list(x) for x in tris[keep]]
    mesh.part = list(parts[keep])
    return int(inside.sum())


def cut_along(mesh, f):
    """Cut a mesh along the zero of a field over its vertices (below 0: cut away) cleanly: faces
    wholly below go, and each vertex below that a kept face still holds is moved to where its
    edges to the kept side cross the zero (the mean of the crossings), UVs with it. Cut face by
    face, a tube's edges were a sawtooth a row deep (2 cm). Returns how many faces went."""
    v, uv, tris, parts = mesh.arrays()
    f = np.where(np.isfinite(f), f, 1e9)
    keep = (f[tris] >= 0).any(1)
    acc_v, acc_uv, n = np.zeros_like(v), np.zeros_like(uv), np.zeros(len(v))
    for a_, b_ in ((0, 1), (1, 2), (2, 0), (1, 0), (2, 1), (0, 2)):
        ia, ib = tris[keep, a_], tris[keep, b_]
        e = (f[ia] < 0) & (f[ib] >= 0)
        ia, ib = ia[e], ib[e]
        s = (f[ia] / (f[ia] - f[ib]))[:, None]
        np.add.at(acc_v, ia, v[ia] + s * (v[ib] - v[ia]))
        np.add.at(acc_uv, ia, uv[ia] + s * (uv[ib] - uv[ia]))
        np.add.at(n, ia, 1)
    moved = n > 0
    v[moved] = acc_v[moved] / n[moved, None]
    uv[moved] = acc_uv[moved] / n[moved, None]
    mesh.v, mesh.uv = list(v), list(uv)
    mesh.tris = [list(x) for x in tris[keep]]
    mesh.part = list(parts[keep])
    return int((~keep).sum())


def chest_x(pts, y, z, band=0.01):
    """How far forward his chest reaches at (y, z): the front of his skin there."""
    sel = (np.abs(pts[:, 1] - y) < band) & (np.abs(pts[:, 2] - z) < band)
    return float(np.percentile(pts[sel, 0], 97)) if sel.sum() >= 3 else float(pts[:, 0].max())


class Man:
    def __init__(self, body):
        pos, _n, uv, tris, _j, colour = FT.load_glb(os.path.join(TRIPO, "test", body + "_rodin.glb"))
        self.body = body
        self.v = TP.frame(pos)
        self.uv, self.tris, self.colour = uv, tris, colour
        self.j = FT.find_joints(self.v, tris)
        self.pts = np.concatenate([self.v, FT.surface_points(self.v, tris, n=250000, seed=2)])
        rep = os.path.join(ROOT, "assets", "people", body + ".json")
        self.height_m = json.load(open(rep)).get("height_m", 1.78) if os.path.exists(rep) else 1.78
        self.m = 1.0 / self.height_m   # metres → his frame
        self.label_arms()
        self.find_neck()

    def label_arms(self):
        """Which points are his arms (near the arm's bone, below the shoulder cap)."""
        self.arm = np.zeros(len(self.pts), bool)
        self.arm_t = {}
        for lr in "RL":
            a, b = self.j[lr + "_Upperarm"], self.j[lr + "_Hand"]
            ab = b - a
            t = (self.pts - a) @ ab / float(ab @ ab)
            d = np.linalg.norm(self.pts - (a + t[:, None] * ab), axis=1)
            self.arm |= ((d < ARM_R) & (t > ARM_FROM)) | ((d < ARM_LOW_R) & (t > ARM_LOW))
            self.arm_t[lr] = (t, d)

    def find_neck(self):
        """His neck's base (where it meets his shoulders), the narrowest of his neck, and his chin,
        from the width of his sections near his middle above the shoulders."""
        p = self.pts
        xc, zc = self.j["NeckTwist01"][0], self.j["NeckTwist01"][2]
        ys = np.arange(self.j["R_Upperarm"][1] - 0.03, self.j["Head"][1] + 0.08, 0.004)
        widths = []
        for y in ys:
            sel = (np.abs(p[:, 1] - y) < 0.003) & (np.abs(p[:, 0] - xc) < 0.07) & (np.abs(p[:, 2] - zc) < 0.14)
            widths.append(float(np.percentile(np.abs(p[sel, 2] - zc), 98) * 2) if sel.sum() > 5 else np.nan)
        widths = np.array(widths)
        # The neck: the narrowest rows; the chin: above them, where the width is back up by a fifth.
        above = ys > self.j["R_Upperarm"][1]
        i_min = int(np.nanargmin(np.where(above, widths, np.nan)))
        w_min = widths[i_min]
        i = i_min
        while i < len(ys) - 1 and widths[i + 1] < w_min * CHIN_WIDE:
            i += 1
        self.chin_y = float(ys[i])
        i = i_min
        while i > 0 and widths[i - 1] < w_min * NECK_BASE_WIDE:
            i -= 1
        self.neck_base_y = float(ys[i])
        self.neck_narrow_y = float(ys[i_min])
        self.neck_axis = np.array([xc, 0.0, zc])
        self.ring_y = self.chin_y - 0.03 * self.m
        print("garments: neck base %.3f, narrowest %.3f (%.0f mm wide), chin %.3f, ring %.3f (of his height; %.2f m tall)" % (
            self.neck_base_y, ys[i_min], w_min * self.height_m * 1000, self.chin_y, self.ring_y, self.height_m))

    def trunk_tube(self, offset):
        """The tube up his trunk's axis from under his hips to his neck's base, his arms' points
        left out (the shoulder caps kept: the yoke), pushed out by offset (metres). One loft for
        every garment on his trunk: a shirt's and a waistcoat's differ only by their offsets, so
        one lies inside the other everywhere by construction."""
        if not hasattr(self, "_trunk"):
            m = self.m
            xc = float(np.median(self.pts[~self.arm & (np.abs(self.pts[:, 1] - 0.6) < 0.05), 0]))
            a = np.array([xc, self.j["Hip"][1] - HEM_BELOW_HIP * m, 0.0])
            # Up over his trapezius into his neck, to its narrowest, inside the collar's stand
            # (ending at the neck's base, his shoulders' skin showed between it and the collar).
            b = np.array([xc, self.neck_narrow_y, 0.0])
            # Filled round (from his chest and back at the same height), not down: under his arm
            # the trunk has none of its own points, and filled down from his deltoids its sides
            # fell straight to his hips as wide as his shoulders, a sheet once his arms hung.
            self._trunk = loft(self.pts[~self.arm], a, b, 0.0, 1.0, ROWS["trunk"], ANGLES["trunk"], 0.0, fill="round")
            # Under his hips no wider than at them: round both thighs the loft took the 95th
            # percentile of the two, a flare too far out to tuck under the trousers (it hung
            # down his sides in the game's stand, 2026-10-18).
            tr = self._trunk
            at_hip = int(np.argmin(np.abs(tr.a[1] + tr.ts * (tr.b[1] - tr.a[1]) - self.j["Hip"][1])))
            tr.R[:at_hip] = np.minimum(tr.R[:at_hip], tr.R[at_hip][None])
        t = self._trunk
        return Tube(t.a, t.b, t.ts, t.R + offset * self.m, t.e1, t.e2)

    # --- the waistcoat -----------------------------------------------------------------------
    def vest(self):
        """The waistcoat: his trunk's tube at the waistcoat's offset, cut to its shape: the hem
        and its two front points, the V in front, the armholes. Buttons, pockets, lapels' lines
        and the back's belt are painted (his pictures)."""
        mesh = Mesh()
        m, j = self.m, self.j
        tube = self.trunk_tube(OFFSET["vest"])
        tube_mesh(tube, mesh, "vest", LAYOUT["vest"]["vest"])
        v, uv, tris, parts = mesh.arrays()
        ab = tube.b - tube.a
        q = v - (tube.a + (((v - tube.a) @ ab) / float(ab @ ab))[:, None] * ab)
        fwd = (q @ tube.e1) / np.maximum(np.linalg.norm(q, axis=1), 1e-9)       # 1 in front, -1 behind
        y, az = v[:, 1], np.abs(v[:, 2])
        # Each edge as a field, metres from it, below 0 where the cloth is cut away.
        hem = j["Hip"][1] + VEST["hem"] * m
        fields = [y - (hem - VEST["points"] * m * np.clip(fwd, 0, 1) ** 2)]
        # The fronts part below the last button (an upturned V between the points).
        fields.append(np.where((fwd > 0.7) & (y < hem), az - (hem - y) * VEST["notch"], np.inf))
        v_y = self.neck_base_y - VEST["v_depth"] * m
        half = VEST["v_top"] * m * np.clip((y - v_y) / (self.neck_base_y - v_y), 0, None)
        fields.append(np.where((fwd > 0) & (y > v_y), az - half, np.inf))
        for lr in "RL":
            # Round his shoulder joint: the side under his arm and the cap over it (the trunk's
            # tube carries his deltoids, the shirt's yoke), leaving a strap by his neck.
            sh = j[lr + "_Upperarm"]
            t_, d_ = self.arm_t[lr]
            ax = float(np.median(self.pts[(d_ < ARM_R) & (t_ > 0.12) & (t_ < 0.3), 0]))    # his arm's middle, front to back
            ex = (v[:, 0] - ax) / (0.5 * VEST["arm_w"] * m)
            ey = (y - (sh[1] - VEST["arm_down"] * m)) / (0.5 * VEST["arm_h"] * m)
            ez = np.minimum((v[:, 2] - sh[2]) * np.sign(sh[2]), 0) / (VEST["arm_in"] * m)
            fields.append((np.sqrt(ex ** 2 + ey ** 2 + ez ** 2) - 1.0) * 0.5 * VEST["arm_w"] * m)
            # The shoulder seam ends short of his shoulder's point, front and back.
            mine = v[:, 2] * np.sign(sh[2]) > 0
            low = sh[1] - VEST["seam_low"] * m
            fields.append(np.where(mine & (y > low), abs(sh[2]) - VEST["seam_in"] * m - az, np.inf))
        # Its top at his neck's base (the trunk's tube runs on up his neck, inside the collar).
        fields.append(self.neck_base_y + VEST["top"] * m - y)
        cut = cut_along(mesh, np.min(fields, axis=0))
        print("garments: vest cut to shape: %d faces" % cut)
        return mesh

    # --- the shirt ---------------------------------------------------------------------------
    def shirt(self):
        mesh = Mesh()
        m = self.m
        lay = LAYOUT["shirt"]
        j = self.j
        hip_y = j["Hip"][1]
        # The body: a tube up his trunk's axis from under his hips to his neck's base, his arms'
        # points left out (the shoulder caps kept: the yoke).
        trunk = self.trunk_tube(OFFSET["shirt"])
        tube_mesh(trunk, mesh, "trunk", lay["trunk"])
        # Each sleeve: a tube down the arm's bone from the shoulder cap to past the wrist.
        for lr, part in (("R", "sleeve_r"), ("L", "sleeve_l")):
            t, d = self.arm_t[lr]
            # The sleeve's axis through the middle of his arm (the rig's joints sit off it: round
            # them the radius ran from 25 to 100 mm and the tube missed the back of his arm).
            ja, jb = j[lr + "_Upperarm"], j[lr + "_Hand"]
            core = (d < ARM_R) & (t > 0.12) & (t < 0.95)
            ta = self.pts[core & (t < 0.3)].mean(0)
            tb = self.pts[core & (t > 0.8)].mean(0)
            axis = (tb - ta) / np.linalg.norm(tb - ta)
            sa = ta + axis * ((ja - ta) @ axis)
            sb = ta + axis * ((jb - ta) @ axis)
            # His arm's own skin (what the trunk leaves out, `arm`) and his shoulder's cap: out to
            # SLEEVE_R the whole way it took his side and the sleeve was a sack round his arm
            # once he stood with it down (2026-10-18).
            near = (d < SLEEVE_R) & (self.arm | (t < SLEEVE_HEAD_T)) & (t > -0.12) & (t < 1.1)
            up = np.array([0, 1.0, 0])
            sleeve = loft(self.pts[near], sa, sb, -0.06, 1.0 + CUFF_PAST, ROWS["sleeve"], ANGLES["sleeve"],
                          OFFSET["shirt"] * m, front=up)
            # The sleeve's head: on its inner side (towards his trunk) the loft took his side's
            # skin; it gets the outer side's radius instead.
            dirs = np.array([np.cos(th) * sleeve.e1 + np.sin(th) * sleeve.e2 for th in 2 * np.pi * np.arange(ANGLES["sleeve"]) / ANGLES["sleeve"]])
            inner = dirs[:, 2] * -np.sign(sa[2]) > 0.2
            for i, t in enumerate(sleeve.ts):
                if t < SLEEVE_HEAD_T:
                    sleeve.R[i, inner] = np.minimum(sleeve.R[i, inner], np.median(sleeve.R[i, ~inner]))
            tube_mesh(sleeve, mesh, part, lay[part])
        # Both tubes stay whole where they overlap (the body's side under the sleeve's head):
        # cut, the one left his shoulder bare where the other didn't quite cover it.
        self.collar(mesh, lay, trunk)
        # The trunk under the collar's top all round (it runs up his neck; behind, the collar
        # sits lower and the shirt stood over it to his hair).
        v = np.array(mesh.v, float)
        part_v = np.empty(len(v), object)
        _v, _uv, tris, parts = mesh.arrays()
        part_v[tris.ravel()] = np.repeat(parts, 3)
        top = np.array([self.collar_top - self.collar_drop_at(p) - COLLAR_TRUNK_UNDER * self.m for p in v])
        cut_along(mesh, np.where(part_v == "trunk", top - v[:, 1], np.inf))
        self.tie(mesh, lay)
        return mesh

    def collar(self, mesh, lay, trunk):
        m = self.m
        y0 = self.neck_base_y - COLLAR_OVERLAP * m * 0.5
        y1 = self.ring_y + (0.03 - COLLAR_UNDER_CHIN) * m
        self.collar_top = y1
        a = self.neck_axis + np.array([0, y0, 0])
        b = self.neck_axis + np.array([0, y1, 0])
        near = (np.linalg.norm((self.pts - self.neck_axis)[:, [0, 2]], axis=1) < NECK_R) & (self.pts[:, 1] > y0 - 0.02) & (self.pts[:, 1] < y1 - 0.004)
        band = loft(self.pts[near], a, b, 0.0, 1.0, ROWS["collar"], ANGLES["collar"], OFFSET["shirt"] * m, fill="down")
        # The stand: its radius his neck's at its narrowest (a ring of his skin there, his jaw
        # left out) and COLLAR_EASE, leaning out as it rises.
        ring = (np.abs(self.pts[:, 1] - self.neck_narrow_y) < 0.006) & (np.linalg.norm((self.pts - self.neck_axis)[:, [0, 2]], axis=1) < NECK_R)
        tn = (self.neck_narrow_y - y0) / (y1 - y0)
        narrow = loft(self.pts[ring], a, b, tn - 0.2, tn + 0.2, 2, ANGLES["collar"], COLLAR_EASE * m, fill="down").R.mean(0)
        for i, t in enumerate(band.ts):
            band.R[i] = narrow + COLLAR_LEAN * t * (y1 - y0)
        tube_mesh(band, mesh, "collar", lay["collar"])
        # Lower behind: each point's height above the foot shrunk by its share of COLLAR_BACK_DROP.
        drop = self.collar_drop(band)
        self.collar_drop_at = drop
        k0 = len(mesh.v) - ROWS["collar"] * (ANGLES["collar"] + 1)
        for k in range(k0, len(mesh.v)):
            p = np.asarray(mesh.v[k], float)
            sh = (p[1] - y0) / (y1 - y0)
            p[1] -= sh * drop(p)
            mesh.v[k] = p
        # Open in front, its two ends either side of the knot.
        f = np.full(len(mesh.v), np.inf)
        for k in range(k0, len(mesh.v)):
            q = np.asarray(mesh.v[k], float) - self.neck_axis
            th = np.degrees(np.arccos(np.clip((q[0] * band.e1[0] + q[2] * band.e1[2]) / max(np.hypot(q[0], q[2]), 1e-9), -1, 1)))
            sh = np.clip((q[1] - y0) / (y1 - y0), 0, 1)
            f[k] = th - (COLLAR_GAP[0] + sh * (COLLAR_GAP[1] - COLLAR_GAP[0]))
        cut_along(mesh, f)
        # The fall: folded down from the stand's top, round the back and sides, out over his
        # shoulders; in front its two points lie down over his chest either side of the knot.
        n_ang = ANGLES["collar"] * 2
        th_in, th_out = np.radians(POINT["in"]), np.radians(POINT["out"])
        angles = np.linspace(th_in, 2 * np.pi - th_in, n_ang)
        top = band.R[-1]
        V, UV, k = [], [], {}
        left, tp, w, h = lay["fall"]
        for j, th in enumerate(angles):
            # How far from the front (0 ahead, pi behind); the point's share of the way out.
            front = min(th, 2 * np.pi - th)
            pt = 1.0 - np.clip((front - th_in) / (th_out - th_in), 0, 1)
            pt = pt * pt * (3 - 2 * pt)
            depth = FALL_DEPTH * m + pt * (POINT["drop"] - FALL_DEPTH) * m
            jf = (th % (2 * np.pi)) / (2 * np.pi) * len(top)
            r0 = np.interp(jf, np.arange(len(top) + 1), np.r_[top, top[0]]) + 0.003 * m
            d = np.cos(th) * band.e1 + np.sin(th) * band.e2
            y_top = y1 - drop(self.neck_axis + d)
            for i in range(FALL_ROWS):
                sfr = i / (FALL_ROWS - 1)
                y = y_top - sfr * depth
                r = r0 + sfr * FALL_OUT * m * (1.0 + 0.6 * pt)
                p = self.neck_axis + np.array([0, y, 0]) + d * r
                if front < th_out + 0.2:
                    # Over his chest: the point lies on it, standing off a little (less at its tip).
                    cx = chest_x(self.pts, p[1], p[2]) + POINT["stand"] * m * (1.0 - 0.4 * sfr * pt)
                    p[0] = min(p[0], cx) if sfr > 0.3 else p[0]
                V.append(p)
                UV.append([left + w * j / (n_ang - 1), tp + h * sfr])
                k[(i, j)] = len(V) - 1
        tris = []
        for i in range(FALL_ROWS - 1):
            for j in range(n_ang - 1):
                a_, b_, c_, d_ = k[(i, j)], k[(i, j + 1)], k[(i + 1, j + 1)], k[(i + 1, j)]
                tris += [[a_, b_, c_], [a_, c_, d_]]
        mesh.add(V, UV, tris, "fall")

    def collar_drop(self, band):
        """How much lower the collar's top is at a point: COLLAR_BACK_DROP behind, none in front."""
        def drop(p):
            q = np.asarray(p, float) - self.neck_axis
            c = (q[0] * band.e1[0] + q[2] * band.e1[2]) / max(np.hypot(q[0], q[2]), 1e-9)     # 1 in front
            return COLLAR_BACK_DROP * self.m * max(-c, 0.0) ** 1.5
        return drop

    def tie(self, mesh, lay):
        m = self.m
        kw, kh, kd = [x * m for x in TIE["knot"]]
        yk = self.neck_base_y + TIE["drop"] * m
        x0 = chest_x(self.pts, yk, 0.0) + OFFSET["shirt"] * m + TIE["off"] * m * 0.5
        # The knot: a box, its front and sides (the back is against his collar).
        front = [(x0 + kd, yk + kh / 2, -kw / 2), (x0 + kd, yk + kh / 2, kw / 2), (x0 + kd, yk - kh / 2, kw / 2), (x0 + kd, yk - kh / 2, -kw / 2)]
        grid_mesh((front[0], front[1], front[2], front[3]), mesh, "knot", lay["knot"], n=1, m=1)
        for sgn in (-1, 1):
            side = [(x0, yk + kh / 2, sgn * kw / 2), (x0 + kd, yk + kh / 2, sgn * kw / 2), (x0 + kd, yk - kh / 2, sgn * kw / 2), (x0, yk - kh / 2, sgn * kw / 2)]
            grid_mesh(side, mesh, "knot", lay["knot"], n=1, m=1)
        # The ends: two strips from under the knot, lying off his chest, spreading a little.
        for sgn, part in ((1.0, "tie_r"), (-1.0, "tie_l")):
            w = TIE["width"] * m
            rows = 7
            V, UV, k = [], [], {}
            left, top, tw, th = lay[part]
            for i in range(rows):
                s = i / (rows - 1)
                y = yk - kh / 2 - s * TIE["length"] * m
                zc = sgn * (0.2 * kw + s * TIE["spread"] * m)
                for jj, u in enumerate((-0.5, 0.5)):
                    z = zc + u * w * (1.0 - 0.3 * s)
                    x = chest_x(self.pts, y, z) + (OFFSET["shirt"] + TIE["off"]) * m
                    V.append([x, y, z])
                    UV.append([left + tw * jj, top + th * s])
                    k[(i, jj)] = len(V) - 1
            tris = []
            for i in range(rows - 1):
                a, b, c, d = k[(i, 0)], k[(i, 1)], k[(i + 1, 1)], k[(i + 1, 0)]
                tris += [[a, b, c], [a, c, d]]
            mesh.add(V, UV, tris, part)


# --- painting ----------------------------------------------------------------------------------
def to_body(v):
    """His Tripo frame (facing +X, right +Z) → body_paint's (facing -Z, right +X)."""
    return np.stack([v[:, 2], v[:, 1], -v[:, 0]], 1)


def paint(man, meshes, views, uns):
    """Every garment's texture from his pictures, his whole dressed figure as the occluder."""
    from scipy import ndimage
    os.makedirs(WORK, exist_ok=True)
    V_all, T_all = [to_body(man.v)], [man.tris]
    n = len(man.v)
    arrays = {}
    for name, mesh in meshes.items():
        v, uv, tris, part = mesh.arrays()
        arrays[name] = (to_body(v), uv, tris, part)
        V_all.append(to_body(v))
        T_all.append(tris + n)
        n += len(v)
    V_all, T_all = np.concatenate(V_all), np.concatenate(T_all)
    # His own bare skin in the pictures (his hands, his head): nothing is sampled on or near it.
    nb = len(man.v)
    bare_v = man.v[:, 1] > man.chin_y - 0.01
    for lr in "RL":
        t, d = man.arm_t[lr]
        bare_v |= (t[:nb] > 0.9) & (d[:nb] < ARM_LOW_R)
    bare_t = man.tris[bare_v[man.tris].all(1)]
    pics, cams, masks, bgs, samp, zbs = {}, {}, {}, {}, {}, {}
    for view, path in views.items():
        raw = Image.open(os.path.join(ROOT, path)).convert("RGB")
        img01 = np.asarray(raw).astype(float) / 255
        masks[view] = BP.figure_mask(img01)
        bgs[view] = BP.backdrop(img01)
        samp[view] = ndimage.binary_erosion(masks[view], iterations=BP.BG_ERODE)
        from PIL import ImageFilter
        img = raw.filter(ImageFilter.MedianFilter(uns)).filter(ImageFilter.GaussianBlur(1.0)) if uns > 1 else raw
        pics[view] = np.asarray(img).astype(float) / 255
        cams[view] = BP.Ortho(*BP.VIEWS[view], V_all, masks[view])
        BP.refine(cams[view], V_all, T_all, masks[view])
        h, w = masks[view].shape
        tid, _b, zb = P.rasterise(cams[view].project(V_all), cams[view].depth(V_all), T_all, w, h)
        zbs[view] = zb
        bt, _b, _z = P.rasterise(cams[view].project(to_body(man.v)), cams[view].depth(to_body(man.v)), bare_t, w, h)
        ys, xs = np.nonzero(masks[view])
        samp[view] &= ~ndimage.binary_dilation(bt >= 0, iterations=int(SKIN_MASK * (ys.max() - ys.min())))
        mine = tid >= 0
        iou = (mine & masks[view]).sum() / max((mine | masks[view]).sum(), 1)
        chk = img01.copy()
        edge = mine & ~np.roll(mine, 2, 0) | mine & ~np.roll(mine, 2, 1)
        chk[edge] = [0.1, 1.0, 0.3]
        Image.fromarray((chk * 255).astype(np.uint8)).resize((w // 2, h // 2)).save(os.path.join(WORK, "%s_%s_fit.png" % (man.body, view)))
        print("garments: %-5s outline overlap %.2f (scale %.0f px/m)" % (view, iou, cams[view].s))
    names = list(views)
    out = {}
    for gname, (V, UV, T, part) in arrays.items():
        n_v = P.vertex_normals(V, T)
        table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
        M, cover = P.raster_uv(table, [list(t) for t in T], np.concatenate([V, n_v], 1), TEX)
        idx = np.nonzero(cover)
        p, nrm = M[..., :3][idx], M[..., 3:][idx]
        nrm /= np.maximum(np.linalg.norm(nrm, axis=-1, keepdims=True), 1e-9)
        # Each texel's class (what colour it may take) from the part whose island it lies in.
        cls = np.zeros((len(p), 4))
        cls[:] = CLASS[gname]
        lay = LAYOUT[gname]
        u, vv = idx[1] / TEX, idx[0] / TEX
        for pname, (left, top, w_, h_) in lay.items():
            if pname.startswith(("tie", "knot")):
                inside = (u >= left) & (u <= left + w_) & (vv >= top) & (vv <= top + h_)
                cls[inside] = CLASS["tie"]
        S = np.full((len(names), len(p)), -np.inf)
        C = np.zeros((len(names), len(p), 3))
        for k, view in enumerate(names):
            cam, img, mask = cams[view], pics[view], masks[view]
            h, w = mask.shape
            q = cam.project(p)
            qi = np.clip(q.astype(int), 0, [w - 1, h - 1])
            seen = (cam.depth(p) <= zbs[view][qi[:, 1], qi[:, 0]] + 0.01) & samp[view][qi[:, 1], qi[:, 0]]
            f = nrm @ cam.toward_v
            C[k] = P.sample(img, q[:, 0], q[:, 1])
            grey = np.linalg.norm(BP._lab(C[k]) - BP._lab(bgs[view][None])[0], axis=1) < BP.BG_DE
            # The wrong kind: a colour outside the garment's class (the waistcoat's brown or his
            # skin on the shirt, the shirt on the tie).
            lab = BP._lab(C[k])
            chroma = np.hypot(lab[:, 1], lab[:, 2])
            hue = np.degrees(np.arctan2(lab[:, 2], lab[:, 1]))
            wrong = grey | (lab[:, 0] < cls[:, 0]) | (lab[:, 0] > cls[:, 1]) | (chroma > cls[:, 2])
            wrong |= (chroma > HUE_FROM_CHROMA) & (hue < cls[:, 3])
            S[k] = np.where(seen & (f > BP.MIN_FACING) & ~wrong, f, -np.inf)
        best = S.max(0)
        ok = np.isfinite(best)
        Wt = np.where(np.isfinite(S), np.exp((S - np.where(ok, best, 0)[None]) / BP.SEAM), 0.0)
        Wt /= np.maximum(Wt.sum(0, keepdims=True), 1e-9)
        col = (Wt[..., None] * C).sum(0)
        tex = np.zeros((TEX, TEX, 3))
        have = np.zeros((TEX, TEX), bool)
        tex[idx] = col
        have[idx] = ok
        # What no picture paints (his shoulders the side views miss, the shirt under the
        # waistcoat) takes its class's own lit colour (FILL_LIT),
        # feathered over FILL_FEATHER texels from the painted edge. Filled from the nearest
        # painted texel alone, it was streaked with the shadowed shirt beside the waistcoat: brown
        # smears on his shoulders (2026-10-18).
        near = BP.island_fill(tex, have, cover)
        kind = np.zeros((TEX, TEX), int)
        kind[idx] = (cls[:, 1] < CLASS[gname][1]).astype(int)        # 1: the tie's dark among the shirt's light
        own = np.zeros((TEX, TEX, 3))
        for k_ in (0, 1):
            sel = ok & (kind[idx] == k_)
            if sel.any():
                lum = col[sel] @ np.array([0.3, 0.59, 0.11])
                own[kind == k_] = np.median(col[sel][lum >= np.percentile(lum, FILL_LIT)], axis=0)
        far = np.clip(ndimage.distance_transform_edt(~have) / FILL_FEATHER, 0, 1)[..., None]
        tex = np.where(have[..., None], tex, near * (1 - far) + own * far)
        which = np.zeros((TEX, TEX, 3))
        pal = np.array([[0.9, 0.3, 0.3], [0.3, 0.9, 0.3], [0.3, 0.3, 0.9], [0.9, 0.9, 0.3]])
        which[idx] = pal[np.argmax(S, 0) % 4] * np.where(ok, 1.0, 0.2)[:, None]
        P.to_pil(which).resize((512, 512)).save(os.path.join(WORK, "%s_which_view.png" % gname))
        print("garments: %s painted %.0f%% from his pictures, the rest from its own island" % (gname, 100 * ok.mean()))
        out[gname] = P.to_pil(np.clip(tex, 0, 1))
    return out


# --- a preview without the game ----------------------------------------------------------------
def preview(man, meshes, path, size=900):
    """Flat-shaded orthographic views (front, right, back) of him in his garments."""
    tiles = []
    cols = {"body": [0.80, 0.62, 0.50], "trunk": [0.93, 0.90, 0.80], "sleeve_r": [0.9, 0.88, 0.78], "sleeve_l": [0.9, 0.88, 0.78],
            "collar": [1.0, 1.0, 0.95], "fall": [0.98, 0.98, 0.9], "knot": [0.1, 0.1, 0.1],
            "tie_r": [0.15, 0.12, 0.12], "tie_l": [0.15, 0.12, 0.12], "vest": [0.45, 0.22, 0.12]}
    V = [man.v]
    T = [man.tris]
    labels = [np.array(["body"] * len(man.tris), dtype=object)]
    n = len(man.v)
    for mesh in meshes.values():
        v, uv, tris, part = mesh.arrays()
        V.append(v)
        T.append(tris + n)
        labels.append(part.astype(object))
        n += len(v)
    V, T, labels = np.concatenate(V), np.concatenate(T), np.concatenate(labels)
    for name, (xaxis, toward) in (("front", ([0, 0, -1.0], [1.0, 0, 0])), ("right", ([1.0, 0, 0], [0, 0, 1.0])), ("back", ([0, 0, 1.0], [-1.0, 0, 0]))):
        xaxis, toward = np.array(xaxis), np.array(toward)
        s = size * 0.9
        xy = np.stack([s * (V @ xaxis) + size / 2, s * (-V[:, 1]) + size * 0.95], 1)
        depth = -(V @ toward)
        tid, bary, _zb = P.rasterise(xy, depth, T, size, size)
        fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
        fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-12
        light = np.abs(fn @ (toward * 0.8 + np.array([0, 0.5, 0]) + xaxis * 0.3)) * 0.7 + 0.3
        img = np.full((size, size, 3), 0.35)
        ok = tid >= 0
        c = np.array([cols.get(l, [0.5, 0.5, 0.5]) for l in labels])
        img[ok] = c[tid[ok]] * light[tid[ok]][:, None]
        tiles.append((np.clip(img, 0, 1) * 255).astype(np.uint8))
    Image.fromarray(np.concatenate(tiles, 1)).save(path)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    body, out = a["--body"], a["--out"]
    garments = a.get("--garments", "shirt").split(",")
    man = Man(body)
    meshes = {}
    if "shirt" in garments:
        meshes["shirt"] = man.shirt()
    if "vest" in garments:
        meshes["vest"] = man.vest()
    for name, mesh in meshes.items():
        v, uv, tris, part = mesh.arrays()
        print("garments: %s: %d triangles (%s)" % (name, len(tris), ", ".join("%s %d" % (p, (part == p).sum()) for p in dict.fromkeys(part))))
    os.makedirs(WORK, exist_ok=True)
    if "--preview" in sys.argv:
        preview(man, meshes, os.path.join(WORK, "%s_preview.png" % out))
        print("garments: preview build/garments/%s_preview.png" % out)
    if "--views" not in a:
        return
    views = dict(kv.split(":", 1) for kv in a["--views"].split(","))
    textures = paint(man, meshes, views, int(a.get("--unsquare", 1)))
    for name, mesh in meshes.items():
        v, uv, tris, _part = mesh.arrays()
        textures[name].save(os.path.join(WORK, "%s_%s_paint.png" % (out, name)))
        TP.write_piece(name, v, uv, tris, textures[name], body, out, painted=True, made=True, islands=LAYOUT[name])


if __name__ == "__main__":
    main()
