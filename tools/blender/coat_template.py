#!/usr/bin/env python3
"""The sack coat's template (docs/briefs/fitted-coat.md, step 2): a period sack coat drafted by
Mitchell's Standard Work on Cutting (1886) and laid on a neutral standard man, built once by script.

    ~/bpyenv/bin/python tools/blender/coat_template.py [--hem=knee|mid_thigh|oversack] [--sheet=DIR]
        [--views=front,side,back,three_quarter,collar,collar_back,chest,arm,arm_top] [--by-piece] [--no-stand]

Reads assets/people/garments/sack_coat.json (the manual's numbers and the plates' traced outlines,
each with its page, and the "to taste" numbers from his pictures) and writes:
- assets/people/garments/sack_coat.glb: the coat's pieces, each its own mesh, UVs laid out as the
  tailor's flat pattern (one atlas, one material), no weights (the fit, tools/faces/coat.py, adds them);
- sack_coat.json's `template`: the stand's measures, the landmarks the fit reads, each piece's
  triangles and how its drafted widths sit on the stand (the ease);
- with --sheet, renders of the template alone (front, side, back, the collar close) into DIR.

How it's made:
1. **The stand:** MakeHuman's base (CC0), a young man of average build, warped onto the game's
   skeleton as tools/blender/make_people.py makes its people (our body space: metres, facing -Z,
   his right +X, feet at 0).
2. **The form:** his trunk seen from its axis (the outermost surface in each angle and height, as
   tools/faces/bandana.py's Shell), a waistcoat's allowance over it; below the breast line it hangs
   (a column's distance from the axis never shrinks going down), so the coat falls straight from his
   chest and shoulder blades as the apron does.
3. **The draft:** the plates' outlines (plate 8 the sack's back and forepart, plate 16 the two-piece
   sleeve) scaled to the stand by the manual's own system: widths by his breast over 36, lengths by
   his own depth of scye, natural waist and the hem's length, the sack's skirt drawn out to the
   oversack's (p. 32), with its back spring.
4. **Laid on the stand:** each piece's seams and edges are curves on the stand (the neckline at the
   base of his neck, the shoulder seam a straight slope from neck point to shoulder point, the
   armhole round his arm's root lowered by the manual's inch, the side seam where the back's drafted
   width reaches round him, the front edges where his pictures hang them). The flat piece is meshed
   and its inside laid by a harmonic map onto the form's surface in its own coordinates (round the
   trunk, or round and along the arm), so the mesh and its UVs share one parameterisation: the UVs
   are the pattern as drafted and the shape is the stand's.
5. **Collar and lapels:** the lapels turned back along the roll line (the manual's break line) and
   lying on the fronts; the collar a stand of the manual's 1 1/8 in and a fall from his pictures,
   its crease running on into the roll line.
6. **Thickness:** every edge a viewer sees is closed with a 4 mm strip; the collar's fall and the
   lapels lie a cloth's thickness over what they cover.
"""
import json
import math
import os
import sys

import numpy as np
from scipy.sparse import lil_matrix
from scipy.sparse.linalg import spsolve
from scipy.spatial import ConvexHull, Delaunay

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import make_people as mp  # noqa: E402  (the MakeHuman stand, warped onto our skeleton)

GARMENTS = os.path.join(ROOT, "assets", "people", "garments")
CFG_PATH = os.path.join(GARMENTS, "sack_coat.json")
IN = 0.0254
# The stand: MakeHuman's young male at average muscle and weight (half way between its two weight
# targets), the face and build left at the base's. Not any man in the game.
STAND = {"macrodetails/caucasian-male-young": 1.0,
         "macrodetails/universal-male-young-averagemuscle-minweight": 0.5,
         "macrodetails/universal-male-young-averagemuscle-maxweight": 0.5}
CELL_DEG = 2.0           # the form's grid: degrees round the trunk
CELL_M = 0.004           # and metres up it
EDGE_IN = 1.05           # the flat pieces' mesh: triangles about this many inches a side


def v(cfg, *keys):
    """A number from the config, through its {"value": ...} wrapper if it has one."""
    x = cfg
    for k in keys:
        x = x[k]
    return x["value"] if isinstance(x, dict) and "value" in x else x


# --- The stand ---------------------------------------------------------------------------------

class Stand:
    def __init__(self):
        cwd = os.getcwd()
        os.chdir(ROOT)
        try:
            env = json.load(open(mp.ENVELOPE))
            p = mp.Person("stand", {"targets": STAND}, env)
            p.warp()
            p.fit()
        finally:
            os.chdir(cwd)
        tris = []
        for fv, _ft in p.body_faces:
            for k in range(1, len(fv) - 1):
                tris.append([fv[0], fv[k], fv[k + 1]])
        T = np.array(tris)
        used = np.unique(T)
        remap = -np.ones(len(p.v), int)
        remap[used] = np.arange(len(used))
        self.V = p.v[used]
        self.T = remap[T]
        self.region = np.asarray(p.region)[used]
        self.joints = {k: np.asarray(x, float) for k, x in p.our_joints().items()}
        self.height = float(self.V[:, 1].max())

    def part(self, names):
        """Triangles all of whose vertices are in these regions."""
        keep = np.isin(self.region[self.T], names).all(1)
        return self.T[keep]


def sample(V, T, n, seed=3):
    rng = np.random.default_rng(seed)
    a, b, c = V[T[:, 0]], V[T[:, 1]], V[T[:, 2]]
    ar = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
    pick = rng.choice(len(T), n, p=ar / ar.sum())
    u, w = rng.random(n), rng.random(n)
    f = u + w > 1
    u[f], w[f] = 1 - u[f], 1 - w[f]
    return a[pick] + (b[pick] - a[pick]) * u[:, None] + (c[pick] - a[pick]) * w[:, None]


class Form:
    """A surface seen from a vertical axis: r(theta, y), theta 0 his front (-Z), +90 his right (+X),
    180 his back. The outermost point in each cell, gaps filled from neighbours."""

    def __init__(self, P, axis, y_lo, y_hi, spread=1):
        self.axis = np.asarray(axis, float)
        self.y0 = y_lo
        th = np.degrees(np.arctan2(P[:, 0] - axis[0], -(P[:, 2] - axis[1])))
        r = np.hypot(P[:, 0] - axis[0], P[:, 2] - axis[1])
        keep = (P[:, 1] >= y_lo) & (P[:, 1] <= y_hi)
        self.na = int(round(360 / CELL_DEG))
        self.ny = int(math.ceil((y_hi - y_lo) / CELL_M)) + 1
        ia = np.round((th[keep] + 180) / CELL_DEG).astype(int) % self.na
        iy = np.clip(np.round((P[keep, 1] - y_lo) / CELL_M).astype(int), 0, self.ny - 1)
        R = np.zeros((self.na, self.ny))
        np.maximum.at(R, (ia, iy), r[keep])
        for _ in range(6):
            empty = R == 0
            if not empty.any():
                break
            nb = np.maximum(np.roll(R, 1, 0), np.roll(R, -1, 0))
            nb = np.maximum(nb, np.maximum(np.roll(R, 1, 1), np.roll(R, -1, 1)))
            R[empty] = nb[empty]
        S = R.copy()
        for k in range(1, spread + 1):
            S = np.maximum(S, np.maximum(np.roll(R, k, 0), np.roll(R, -k, 0)))
        self.R = S

    def hang(self, y_from):
        """Below y_from, each column's radius never shrinks going down."""
        k = int(np.clip(round((y_from - self.y0) / CELL_M), 0, self.ny - 1))
        R = self.R.copy()
        R[:, :k + 1] = np.maximum.accumulate(R[:, :k + 1][:, ::-1], axis=1)[:, ::-1]
        self.R = R

    def r(self, theta, y):
        """Bilinear in the grid."""
        fa = (np.asarray(theta, float) + 180) / CELL_DEG
        fy = np.clip((np.asarray(y, float) - self.y0) / CELL_M, 0, self.ny - 1.001)
        a0 = np.floor(fa).astype(int)
        y0 = np.floor(fy).astype(int)
        ta, ty = fa - a0, fy - y0
        a0 %= self.na
        a1 = (a0 + 1) % self.na
        R = self.R
        return ((R[a0, y0] * (1 - ta) + R[a1, y0] * ta) * (1 - ty)
                + (R[a0, y0 + 1] * (1 - ta) + R[a1, y0 + 1] * ta) * ty)

    def at(self, theta, y, out=0.0):
        """The point on the surface (pushed `out` further), shape (..., 3)."""
        theta = np.asarray(theta, float)
        y = np.asarray(y, float)
        r = self.r(theta, y) + out
        t = np.radians(theta)
        return np.stack([self.axis[0] + r * np.sin(t), y, self.axis[1] - r * np.cos(t)], -1)

    def polar(self, P):
        P = np.asarray(P, float)
        th = np.degrees(np.arctan2(P[..., 0] - self.axis[0], -(P[..., 2] - self.axis[1])))
        return th, P[..., 1], np.hypot(P[..., 0] - self.axis[0], P[..., 2] - self.axis[1])


def smooth_circular(x, sigma):
    """Gaussian smoothing of a periodic series (sigma in samples)."""
    k = np.arange(-3 * int(sigma + 1), 3 * int(sigma + 1) + 1)
    w = np.exp(-0.5 * (k / max(sigma, 1e-6)) ** 2)
    w /= w.sum()
    return sum(wi * np.roll(x, -ki) for ki, wi in zip(k, w))


def girth(P):
    if len(P) < 5:
        return 0.0
    return float(ConvexHull(P[:, [0, 2]]).area)


class Landmarks:
    """Where the coat lies on the stand: its form, neckline, shoulder and armhole, its lines."""

    def __init__(self, st, cfg, hem):
        self.st = st
        J = st.joints
        vest = v(cfg, "cloth", "vest_allowance_m")
        clear = v(cfg, "cloth", "clearance_m")
        self.vest, self.clear = vest, clear
        trunk_T = st.part(["trunk", "neck"])
        P = sample(st.V, trunk_T, 500000)
        chest = P[np.abs(P[:, 1] - 1.25) < 0.03]
        self.axis = (0.0, float((chest[:, 2].min() + chest[:, 2].max()) / 2))
        self.trunk_pts = P

        # His arm's root: the edge on his skin between the trunk and the upper arm (the warp's
        # regions), a loop round the top of the arm.
        loop = self._arm_root("upper_arm_r")
        self.armpit_y = float(loop[:, 1].min())
        self.shoulder_top_y = float(loop[:, 1].max())
        # The neck's base: his section's width beside the neck, going up from the shoulders, falls to
        # the neck's own; the neck point is where it first comes within a centimetre of it. (The
        # skeleton's neck joint is no guide: on the stand it lies under the shoulders' top.)
        A = sample(st.V, st.part(["trunk", "neck", "head"]), 400000)
        top = self.shoulder_top_y
        ys = np.arange(top - 0.02, top + 0.14, 0.002)
        ext = []
        for y in ys:
            s = A[(np.abs(A[:, 1] - y) < 0.002) & (np.abs(A[:, 2] - 0.01) < 0.03)]
            ext.append(np.abs(s[:, 0]).max() if len(s) else np.nan)
        ext = np.array(ext)
        w_neck = np.nanmin(ext)
        k = int(np.argmax(ext <= w_neck + 0.01))
        np_y = float(ys[k])
        nk = A[np.abs(A[:, 1] - np_y) < 0.003]
        nk = nk[np.abs(nk[:, 0]) < w_neck + 0.01]
        self.neck_axis = (0.0, float((nk[:, 2].min() + nk[:, 2].max()) / 2))
        # That height is still on his neck: the neck point is lower, where the neck's side wall meets
        # the top of his shoulder (down each side till the surface flares 1.5 cm out from the neck).
        nform = Form(A, self.neck_axis, np_y - 0.12, np_y + 0.04)
        found = []
        for side in (90, -90):
            r0 = nform.r(side, np_y)
            for y in np.arange(np_y, np_y - 0.12, -0.002):
                if nform.r(side, y) > r0 + 0.015:
                    found.append(y + 0.002)
                    break
        np_y = float(np.mean(found)) if found else np_y
        # The back's neck dips under the neck point by plate 8's D to 2 (5/8 in, p. 24); the
        # neckline runs round the back of his neck between them, on his surface.
        self.drop = v(cfg, "plate8_rules", "neck_point_above_top_of_back")
        th = np.arange(-180, 180.01, CELL_DEG)
        a = np.abs(th)
        lift = np.clip((180 - a) / 90, 0, 1)
        lift = (1 - np.cos(np.pi * np.minimum(lift, 1))) / 2
        base = np_y - self.drop * IN * (1 - lift)
        rb = nform.r(th, base) + vest + clear
        rb = smooth_circular(rb, 2)
        tt = np.radians(th)
        self.neckline_ring = (th, np.stack([self.neck_axis[0] + rb * np.sin(tt), base,
                                            self.neck_axis[1] - rb * np.cos(tt)], -1))
        self.nform = nform
        self.nape = self.neck_pt(180)
        self.neck_point = self.neck_pt(90)
        self.nape_y = float(self.nape[1])
        self.neck_point_y = np_y

        # His shoulder point: where the top of his shoulder turns down into the arm (the outermost
        # point still within a centimetre of the shoulder's height over the arm's joint).
        Pall = sample(st.V, st.T, 600000)
        xs_top = np.arange(0.10, 0.32, 0.005)
        ytop = []
        for x in xs_top:
            sl = Pall[(np.abs(Pall[:, 0] - x) < 0.003) & (np.abs(Pall[:, 2]) < 0.04) & (Pall[:, 1] > self.armpit_y)]
            ytop.append(sl[:, 1].max() if len(sl) else np.nan)
        ytop = np.array(ytop)
        y_joint = float(np.interp(J["r-shoulder"][0], xs_top, ytop))
        ok = np.where(ytop >= y_joint - 0.01)[0]
        x_sp = float(xs_top[ok.max()])
        near = Pall[np.abs(Pall[:, 0] - x_sp) < 0.004]
        self.shoulder_point = near[np.argmax(near[:, 1])]
        # The breast line: the armhole's bottom, the manual's inch under his armpit (p. 24: the
        # depth of scye as drafted is the measure + 1).
        self.breast_y = self.armpit_y - IN
        # His breast over the vest, round his chest at the armpit (his arms left out).
        band = P[(np.abs(P[:, 1] - self.armpit_y) < 0.01)]
        self.breast_in = (girth(band) + 2 * math.pi * vest) / IN
        # The natural waist: his narrowest between the breast line and his hips.
        hip_y = float(J["hips"][1])
        ys = np.arange(hip_y + 0.08, self.breast_y - 0.06, 0.005)
        gs = [girth(P[np.abs(P[:, 1] - y) < 0.004]) for y in ys]
        self.waist_y = float(ys[int(np.argmin(gs))])
        self.waist_girth_in = float(min(gs) / IN)
        knee_y = float((J["r-knee"][1] + J["l-knee"][1]) / 2)
        self.hip_y, self.knee_y = hip_y, knee_y
        hc = cfg["hem"][hem]
        if "above_knee_share_of_thigh" in hc:
            self.hem_y = knee_y + hc["above_knee_share_of_thigh"] * (hip_y - knee_y)
        else:
            self.hem_y = self.nape_y - hc["inches_from_top_of_back"] * self.breast_in / 38 * IN

        # The trunk's form: his surface plus the vest, hanging below the breast line.
        self.form = Form(P, self.axis, self.hem_y - 0.1, self.nape_y + 0.1, spread=1)
        self.form.R += vest
        self.form.hang(self.breast_y)
        self.loop_skin = loop

    def neck_pt(self, theta):
        th, pts = self.neckline_ring
        i = int(np.argmin(np.abs(((th - theta + 180) % 360) - 180)))
        return pts[i].copy()

    def _arm_root(self, arm):
        st = self.st
        reg = st.region[st.T]
        mixed = st.T[(reg == "trunk").any(1) & (reg == arm).any(1)]
        pts = st.V[mixed].mean(1)
        return pts


# --- The draft, scaled to the stand -------------------------------------------------------------

class Draft:
    """Plate 8's back and forepart and plate 16's sleeve, in inches, at the stand's measures."""

    def __init__(self, cfg, lm):
        m = cfg["measures"]
        self.xs = lm.breast_in / v(m, "breast")
        self.scye = (lm.nape_y - lm.breast_y) / IN
        self.waist = (lm.nape_y - lm.waist_y) / IN
        self.length = (lm.nape_y - lm.hem_y) / IN
        self.p_scye, self.p_waist = v(m, "depth_of_scye"), v(m, "natural_waist")
        self.p_hem = 28.55      # plate 8's hem at the back (V)
        self.spring = v(cfg, "oversack", "back_spring_at_hem") * lm.breast_in / 38
        p8 = cfg["plate8"]
        self.back = {k: self.scale(np.array(p, float)) for k, p in p8["back"].items() if not k.startswith("_")}
        self.fore = {k: self.scale(np.array(p, float)) for k, p in p8["fore"].items() if not k.startswith("_")}
        # The oversack's back spring: the back's side seam out at the hem, from nothing at the waist.
        for k in ("side", "hem"):
            pts = self.back[k]
            t = np.clip((pts[:, 1] - self.waist) / (self.length - self.waist), 0, None)
            pts[:, 0] += self.spring * t * (pts[:, 0] > 1.0)

    def ymap(self, y):
        y = np.asarray(y, float)
        return np.interp(y, [-5, 0, self.p_scye, self.p_waist, self.p_hem, self.p_hem + 5],
                         [-5 * self.scye / self.p_scye, 0, self.scye, self.waist, self.length,
                          self.length + 5 * (self.length - self.waist) / (self.p_hem - self.p_waist)])

    def scale(self, p):
        return np.c_[p[:, 0] * self.xs, self.ymap(p[:, 1])]

    @staticmethod
    def width_at(poly, y):
        """x of a polyline (going down) at draft height y."""
        poly = np.asarray(poly)
        order = np.argsort(poly[:, 1])
        return float(np.interp(y, poly[order, 1], poly[order, 0]))




# --- Curves and flat meshes -------------------------------------------------------------------

def arclen(poly):
    poly = np.asarray(poly, float)
    return np.r_[0, np.cumsum(np.linalg.norm(np.diff(poly, axis=0), axis=1))]


def resample(poly, n):
    """n points evenly along a polyline, both ends kept."""
    poly = np.asarray(poly, float)
    d = arclen(poly)
    t = np.linspace(0, d[-1], n)
    return np.stack([np.interp(t, d, poly[:, k]) for k in range(poly.shape[1])], -1)


def point_at(poly, dist):
    """The point `dist` along a polyline from its start."""
    poly = np.asarray(poly, float)
    d = arclen(poly)
    return np.array([np.interp(dist, d, poly[:, k]) for k in range(poly.shape[1])])


def inside_poly(P, poly):
    """Even-odd test, vectorised."""
    x, y = P[:, 0][:, None], P[:, 1][:, None]
    x0, y0 = poly[:, 0][None, :], poly[:, 1][None, :]
    x1, y1 = np.roll(poly[:, 0], -1)[None, :], np.roll(poly[:, 1], -1)[None, :]
    cross = ((y0 > y) != (y1 > y)) & (x < (x1 - x0) * (y - y0) / np.where(y1 == y0, 1e-12, y1 - y0) + x0)
    return cross.sum(1) % 2 == 1


def dist_poly(P, poly):
    a, b = poly, np.roll(poly, -1, 0)
    ab = b - a
    t = np.clip(((P[:, None, :] - a[None]) * ab[None]).sum(2) / np.maximum((ab * ab).sum(1), 1e-12)[None], 0, 1)
    q = a[None] + t[..., None] * ab[None]
    return np.linalg.norm(P[:, None, :] - q, axis=2).min(1)


class Flat:
    """A flat piece: its outline as named segments (each a polyline meeting the next), meshed."""

    def __init__(self, name, segs, edge=EDGE_IN):
        self.name = name
        self.seg_names = [s[0] for s in segs]
        B, self.ranges = [], {}
        for nm, pts in segs:
            start = len(B)
            B.extend(pts[:-1])
            self.ranges[nm] = list(range(start, start + len(pts))) if True else None
        self.nb = len(B)
        for nm in self.ranges:   # each segment's last index is the next one's first
            self.ranges[nm] = [i % self.nb for i in self.ranges[nm]]
        B = np.array(B)
        lo, hi = B.min(0), B.max(0)
        h = edge * math.sqrt(3) / 2
        G = []
        for j, y in enumerate(np.arange(lo[1] + h / 2, hi[1], h)):
            for x in np.arange(lo[0] + (edge / 2 if j % 2 else 0), hi[0], edge):
                G.append((x, y))
        G = np.array(G)
        G = G[inside_poly(G, B)]
        G = G[dist_poly(G, B) > 0.55 * edge]
        P = np.vstack([B, G])
        tri = Delaunay(P).simplices
        tri = tri[inside_poly(P[tri].mean(1), B)]
        # Slivers across a concave notch: a triangle of boundary points whose edges leave the outline.
        mids = [P[tri][:, [0, 1]].mean(1), P[tri][:, [1, 2]].mean(1), P[tri][:, [2, 0]].mean(1)]
        ok = np.all([inside_poly(m, B) | (dist_poly(m, B) < 1e-6) for m in mids], axis=0)
        tri = tri[ok]
        a, b, c = P[tri[:, 0]], P[tri[:, 1]], P[tri[:, 2]]
        neg = np.cross(b - a, c - a) < 0
        tri[neg] = tri[neg][:, ::-1]
        self.P, self.T = P, tri

    def boundary(self, names):
        idx = []
        for nm in names:
            r = self.ranges[nm]
            idx.extend(r if not idx else r[1:])
        return idx


def harmonic(P2, T, fixed, values):
    """Positions for every vertex: `values` at `fixed`, the rest the average of their neighbours."""
    n = len(P2)
    nb = [set() for _ in range(n)]
    for a, b, c in T:
        nb[a] |= {b, c}
        nb[b] |= {a, c}
        nb[c] |= {a, b}
    fixed = np.asarray(fixed)
    is_fixed = np.zeros(n, bool)
    is_fixed[fixed] = True
    free = np.where(~is_fixed)[0]
    pos = {int(i): k for k, i in enumerate(free)}
    L = lil_matrix((len(free), len(free)))
    rhs = np.zeros((len(free), values.shape[1]))
    X = np.zeros((n, values.shape[1]))
    X[fixed] = values
    for k, i in enumerate(free):
        L[k, k] = len(nb[i])
        for j in nb[i]:
            if is_fixed[j]:
                rhs[k] += X[j]
            else:
                L[k, pos[j]] = -1
    L = L.tocsr()
    for d in range(values.shape[1]):
        X[free, d] = spsolve(L, rhs[:, d])
    return X


# --- The coat's surfaces on the stand -----------------------------------------------------------

def smoothstep(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


class Body:
    """The coat round his trunk: the form, its clearance and the coat's ease, as meridians: for
    each angle a profile (r, y) up from below the hem over the shoulders' top to the neck, and s the
    arc along it. So the yoke over his shoulders is reached as the sides are."""

    def __init__(self, lm, ease):
        self.lm = lm
        self.ys = np.arange(lm.hem_y - 0.08, lm.neck_point_y + 0.03, 0.003)
        self.th = np.arange(-180.0, 180.0, CELL_DEG)
        R = lm.form.r(self.th[:, None], self.ys[None, :]) + lm.clear + ease(self.ys)[None, :]
        # A little smoothing up each column (the grid's steps) and round.
        for _ in range(2):
            R[:, 1:-1] = (R[:, :-2] + 2 * R[:, 1:-1] + R[:, 2:]) / 4
            R = (np.roll(R, 1, 0) + 2 * R + np.roll(R, -1, 0)) / 4
        self.R = R
        # The arc: up the sides by height alone (so the columns agree, whatever small wiggles the
        # form has), and over the shoulders' top, where the surface turns in, by its run as well.
        dr, dy = np.diff(R, axis=1), np.diff(self.ys)[None, :]
        steep = np.abs(dr) > np.abs(dy)
        self.S = np.c_[np.zeros(len(self.th)), np.cumsum(np.where(steep, np.hypot(dr, dy), dy), axis=1)]

    def _cols(self, theta):
        f = (np.asarray(theta, float) + 180) / CELL_DEG
        i0 = np.floor(f).astype(int) % len(self.th)
        return i0, (i0 + 1) % len(self.th), f - np.floor(f)

    def s_of(self, theta, y):
        theta, y = np.atleast_1d(theta), np.atleast_1d(y)
        i0, i1, w = self._cols(theta)
        return np.array([np.interp(yy, self.ys, self.S[a]) * (1 - ww) + np.interp(yy, self.ys, self.S[b]) * ww
                         for yy, a, b, ww in zip(y, i0, i1, w)])

    def y_r(self, theta, s):
        theta, s = np.atleast_1d(theta), np.atleast_1d(s)
        i0, i1, w = self._cols(theta)
        out = []
        for ss, a, b, ww in zip(s, i0, i1, w):
            ya, yb = np.interp(ss, self.S[a], self.ys), np.interp(ss, self.S[b], self.ys)
            ra, rb = np.interp(ya, self.ys, self.R[a]), np.interp(yb, self.ys, self.R[b])
            out.append((ya * (1 - ww) + yb * ww, ra * (1 - ww) + rb * ww))
        return np.array(out)

    def at(self, theta, s, out=0.0):
        yr = self.y_r(theta, s)
        t = np.radians(np.atleast_1d(theta))
        r = yr[:, 1] + out
        ax = self.lm.axis
        return np.stack([ax[0] + r * np.sin(t), yr[:, 0], ax[1] - r * np.cos(t)], -1)

    def polar(self, P):
        """(angle, meridian arc) of points on or near the surface: the arc at the nearest point of
        their angle's profile (on the shoulders' top a point's height alone doesn't place it)."""
        P = np.atleast_2d(P)
        ax = self.lm.axis
        th = np.degrees(np.arctan2(P[:, 0] - ax[0], -(P[:, 2] - ax[1])))
        rp = np.hypot(P[:, 0] - ax[0], P[:, 2] - ax[1])
        i0, i1, w = self._cols(th)
        s = np.zeros(len(P))
        for k in range(len(P)):
            for col, ww in ((i0[k], 1 - w[k]), (i1[k], w[k])):
                j = int(np.argmin((self.R[col] - rp[k]) ** 2 + (self.ys - P[k, 1]) ** 2))
                s[k] += ww * self.S[col, j]
        return th, s

    def onto(self, P, out=0.0, only_out=False):
        """Each point to the nearest point of its own angle's profile (pushed `out`); with only_out,
        only the points inside it."""
        P = np.atleast_2d(np.asarray(P, float))
        ax = self.lm.axis
        th = np.degrees(np.arctan2(P[:, 0] - ax[0], -(P[:, 2] - ax[1])))
        rp = np.hypot(P[:, 0] - ax[0], P[:, 2] - ax[1])
        i0, i1, w = self._cols(th)
        Q = P.copy()
        for k in range(len(P)):
            prof = self.R[i0[k]] * (1 - w[k]) + self.R[i1[k]] * w[k] + out
            if only_out and rp[k] >= np.interp(P[k, 1], self.ys, prof):
                continue
            d = (prof - rp[k]) ** 2 + (self.ys - P[k, 1]) ** 2
            j = int(np.argmin(d))
            t = math.radians(th[k])
            Q[k] = [ax[0] + prof[j] * math.sin(t), self.ys[j], ax[1] - prof[j] * math.cos(t)]
        return Q

    def ring(self, y, th_from, th_to, n=200):
        th = np.linspace(th_from, th_to, n)
        return th, self.at(th, self.s_of(th, np.full(n, y)))


class Armhole:
    """The coat's armhole: an oval round his arm's root, N points from the top (his shoulder point)
    forward, under and back up. Its top at the shoulder point, its bottom the manual's inch under
    his armpit (p. 24), its front and back where his arm's root is (the edge on his skin between
    trunk and arm), each stood off by the vest and the clearance."""
    N = 72
    POWER = 2.5            # a little squarer than an ellipse, as an armhole is drawn (plate 8)

    def __init__(self, lm, body, push=None):
        skin = lm.loop_skin
        m = lm.vest + lm.clear
        top = lm.shoulder_point + np.array([0, m, 0])
        y_bot = lm.armpit_y - IN
        z_f, z_b = skin[:, 2].min() - m, skin[:, 2].max() + m
        yc, zc = (top[1] + y_bot) / 2, (z_f + z_b) / 2
        a, b = (top[1] - y_bot) / 2, (z_b - z_f) / 2
        x_bot = float(np.median(skin[skin[:, 1] < lm.armpit_y + 0.03, 0])) + m
        t = np.radians(np.linspace(0, 360, self.N, endpoint=False))
        c, s_ = np.cos(t), np.sin(t)
        e = 2 / self.POWER
        y = yc + a * np.sign(c) * np.abs(c) ** e
        z = zc - b * np.sign(s_) * np.abs(s_) ** e          # forward (-Z) first
        frac = (yc + a - y) / (2 * a)                       # 0 at the top, 1 at the bottom
        x = top[0] + (x_bot - top[0]) * smoothstep(frac)
        L = np.c_[x, y, z]
        L = body.onto(L, only_out=True)
        if push is not None:
            L = push(L)
        L[0] = top
        self.P = L
        self.top = 0

    def index_at_height(self, y, half):
        """The point on the front (half=+1) or back (-1) half nearest height y."""
        i = np.arange(self.N)
        sel = (i > 0) & (i < self.N // 2) if half > 0 else (i > self.N // 2)
        cand = i[sel]
        return int(cand[np.argmin(np.abs(self.P[cand, 1] - y))])

    def path(self, i, j, step):
        """Indices from i to j going `step` (+1 forward/under, -1 back/over), both kept."""
        out = [i % self.N]
        while out[-1] != j % self.N:
            out.append((out[-1] + step) % self.N)
        return out

    def pts(self, idx):
        return self.P[np.array(idx) % self.N]


def mirror(P):
    P = np.array(P, float)
    P[..., 0] *= -1
    return P


def unwrap(theta, centre):
    return centre + ((np.asarray(theta, float) - centre + 180) % 360) - 180


class Piece:
    """A finished piece: positions, triangles, pattern coordinates (inches, as drafted), and its
    open edges (index lists) to be closed with a strip."""

    def __init__(self, name, V, T, UV, edges=(), axis=None):
        self.name, self.V, self.T, self.UV = name, np.asarray(V, float), np.asarray(T, int), np.asarray(UV, float)
        self.edges = [list(e) for e in edges]
        self.axis = axis    # (point, direction) its normals face away from, or None for the trunk's

    def mirrored(self, name):
        p = Piece(name, mirror(self.V), self.T[:, ::-1], self.UV * [-1, 1], self.edges, None)
        if self.axis is not None:
            kind, data = self.axis
            p.axis = (kind, mirror(data) if kind == "arm" else (-data[0], data[1]))
        return p


def folded(V, T, UV=None, ref=None):
    """Triangles turned over against their neighbours: each face's normal against the mean of its
    corners' (area-weighted) normals, the mesh's own winding throughout."""
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    N = np.zeros_like(V)
    for j in range(3):
        np.add.at(N, T[:, j], fn)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)
    fu = fn / np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    return (fu * N[T].mean(1)).sum(1) < 0.2


def untangle(V, T, UV, fixed, ref, push, rounds=30):
    """Smooth the vertices of turned-over triangles (and their neighbours) till none are left."""
    n = len(V)
    nb = [set() for _ in range(n)]
    for a, b, c in T:
        nb[a] |= {b, c}
        nb[b] |= {a, c}
        nb[c] |= {a, b}
    nbl = [np.array(sorted(x)) for x in nb]
    is_fixed = np.zeros(n, bool)
    is_fixed[list(fixed)] = True
    for _ in range(rounds):
        bad = folded(V, T, UV, ref)
        if not bad.any():
            break
        vs = set(T[bad].ravel().tolist())
        for i in list(vs):
            vs |= set(nbl[i].tolist())
        vs = np.array([i for i in vs if not is_fixed[i]])
        if not len(vs):
            break
        for _k in range(3):
            V[vs] = np.array([V[nbl[i]].mean(0) for i in vs])
        V[vs] = push(V[vs])
    return V


def lay_on_body(flat, segs3d, body, centre, rounds=40, push=None):
    """A flat trunk piece onto the coat's surface: its edges on their curves, its inside a harmonic
    map of the flat piece spanned between them, then relaxed against the form (each round smoothed
    and pushed back out of it): the cloth lies on him where he's fullest and spans the hollows."""
    bidx, b3 = [], []
    for nm, pts in segs3d:
        r = flat.ranges[nm]
        for k, i in enumerate(r[:-1]):
            bidx.append(i)
            b3.append(pts[k])
    b3 = np.array(b3)
    V = harmonic(flat.P, flat.T, bidx, b3)
    free = np.ones(len(V), bool)
    free[bidx] = False
    nb = [set() for _ in range(len(V))]
    for a, b, c in flat.T:
        nb[a] |= {b, c}
        nb[b] |= {a, c}
        nb[c] |= {a, b}
    nbl = [np.array(sorted(x)) for x in nb]
    fi = np.where(free)[0]
    out = (lambda X: push(body.onto(X, only_out=True))) if push else (lambda X: body.onto(X, only_out=True))  # noqa: E731
    V[fi] = out(V[fi])
    for _ in range(rounds):
        avg = np.array([V[nbl[i]].mean(0) for i in fi])
        V[fi] = out(V[fi] + 0.6 * (avg - V[fi]))
    return untangle(V, flat.T, flat.P, bidx, ("trunk", body.lm.axis), out)


def ease_fn(lm, dr, body0):
    """The coat's stand-off over the form by height: its drafted ease spread evenly round, as it
    hangs buttoned (the half-width centre back to the front edge against the form's half round);
    over the yoke it closes to nothing at the shoulder point (the clearance only)."""
    ys = np.linspace(lm.hem_y, lm.breast_y, 30)
    d = []
    for y in ys:
        yd = (lm.nape_y - y) / IN
        half = Draft.width_at(dr.back["side"], yd) + Draft.width_at(dr.fore["front"], yd) - Draft.width_at(dr.fore["side"], yd)
        th, P = body0.ring(y, 180, 0, 181)
        d.append(max(0.0, (half * IN - arclen(P)[-1]) / math.pi))
    d = np.array(d)
    d = np.convolve(np.pad(d, 3, mode="edge"), np.ones(7) / 7, mode="valid")
    top = lm.shoulder_top_y

    def f(y):
        y = np.asarray(y, float)
        base = np.interp(y, ys, d)
        return base * (1 - smoothstep((y - lm.breast_y) / (top - lm.breast_y)))
    f.table = [(round(float(y), 3), round(float(x), 4)) for y, x in zip(ys[::5], d[::5])]
    return f


class Build:
    def __init__(self, cfg, hem):
        self.cfg = cfg
        self.st = Stand()
        lm = self.lm = Landmarks(self.st, cfg, hem)
        dr = self.dr = Draft(cfg, lm)
        body0 = Body(lm, lambda y: np.zeros_like(np.asarray(y, float)))
        self.ease = ease_fn(lm, dr, body0)
        body = self.body = Body(lm, self.ease)
        # His skin with its normals: every piece kept a vest and clearance outside it. The body's
        # panels feel his trunk, neck and the top of his arms (not the arms hanging beside them).
        from scipy.spatial import cKDTree
        st = self.st
        SN = vertex_normals(st.V, st.T, ("trunk", lm.axis))
        armish = np.isin(st.region, ["upper_arm_r", "forearm_r", "hand_r", "upper_arm_l", "forearm_l", "hand_l"])
        J = st.joints
        for sd in "rl":
            axis_s = np.array([J[sd + "-shoulder"], J[sd + "-elbow"], J[sd + "-hand"]])
            m = np.isin(st.region, ["upper_arm_" + sd, "forearm_" + sd, "hand_" + sd])
            SN[m] = vertex_normals(st.V, st.T, ("arm", axis_s))[m]
        self.skin_n = SN
        r_neck = float(np.hypot(lm.neck_point[0], lm.neck_point[2] - lm.neck_axis[1])) - lm.vest - lm.clear
        neck_col = (st.V[:, 1] > lm.neck_point_y + 0.005) & (np.hypot(st.V[:, 0], st.V[:, 2] - lm.neck_axis[1]) < r_neck + 0.012)
        trunkish = (~armish | (st.V[:, 1] > lm.armpit_y)) & ~neck_col
        self.skin_trees = {"all": (cKDTree(st.V), np.arange(len(st.V))),
                           "body": (cKDTree(st.V[trunkish]), np.where(trunkish)[0])}
        arm = self.arm = Armhole(lm, body, push=lambda X: self.skin_push(X, "body"))
        xs = dr.xs
        self.pieces = []
        self.landmarks = {}
        yd = lambda y: (lm.nape_y - y) / IN        # noqa: E731  3D height -> draft inches
        y3 = lambda d: lm.nape_y - d * IN          # noqa: E731

        # The lines.
        self.y_break = lm.breast_y - v(cfg, "lapel", "break_between_breast_and_waist") * (lm.breast_y - lm.waist_y)
        hscale = self.st.height / 1.787     # his pictures' metres to the stand's
        self.hscale = hscale
        NP = lm.neck_point
        SP = arm.P[0]
        # The shoulder seam: a straight slope from neck point to shoulder point (DONT_REPEAT 2), off
        # the form, and where his shoulder dips under it held within 12 mm of his skin.
        sh = np.linspace(NP, SP, 24)
        sh = body.onto(sh, only_out=True)
        from scipy.spatial import cKDTree
        self.skin = cKDTree(sample(self.st.V, self.st.T, 400000))
        dd, ii = self.skin.query(sh)
        q = self.skin.data[ii]
        far = dd > 0.012
        sh[far] = q[far] + (sh[far] - q[far]) * (0.012 / dd[far])[:, None]
        i_st = arm.index_at_height(y3(dr.back["side"][0][1]), -1)
        notch_y = lm.breast_y + v(cfg, "plate16", "forearm_notch_above_breast_line") * dr.scye / dr.p_scye * IN
        i_notch = arm.index_at_height(notch_y, +1)

        # The side seam: where the back's drafted width reaches round from the centre back.
        ys_side = np.linspace(lm.breast_y, lm.hem_y, 40)
        side = [arm.P[i_st]]
        th_side = []
        for y in ys_side:
            th, P = body.ring(y, 180, 0, 361)
            a = arclen(P)
            t = float(np.interp(Draft.width_at(dr.back["side"], yd(y)) * IN, a, th))
            th_side.append(t)
            side.append(body.at(t, body.s_of(t, y))[0])
        side = np.array(side)
        th_hem_side = th_side[-1]

        # The front edges, where his pictures hang them, from the hem to the break.
        g_break = v(cfg, "front", "half_gap_at_break_m") * hscale
        g_belt = v(cfg, "front", "half_gap_at_belt_m") * hscale
        g_hem = v(cfg, "front", "half_gap_at_hem_m") * hscale
        ys_front = np.linspace(lm.hem_y, self.y_break, 30)
        g = np.interp(ys_front, [lm.hem_y, lm.waist_y, self.y_break], [g_hem, g_belt, g_break])
        front, th_front = [], []
        for y, gx in zip(ys_front, g):
            th, P = body.ring(y, 0, 90, 181)
            t = float(np.interp(gx, P[:, 0], th))
            th_front.append(t)
            front.append(body.at(t, body.s_of(t, y))[0])
        front = np.array(front)
        B3 = front[-1]
        # The roll line: from the break to the manual's point A, a quarter inch ahead of the neck point.
        th_ring, ring = lm.neckline_ring
        sel = (th_ring >= 0) & (th_ring <= 90)
        nk = ring[sel][::-1]             # from the neck point forward
        A3 = point_at(nk, v(cfg, "plate8_rules", "break_line_ahead_of_neck_point") * xs * IN)
        neck_front = np.vstack([nk[:1], A3[None]])
        # Up the front of his chest from the break at the break's own width out (as his pictures show
        # the lapels' roll, nearly upright), turning back to A over the last 5 cm.
        def front_at(gx, y):
            lo_t, hi_t = 3.0, 75.0
            for _ in range(30):
                mid = (lo_t + hi_t) / 2
                if body.at(mid, body.s_of(mid, y))[0, 0] < gx:
                    lo_t = mid
                else:
                    hi_t = mid
            return body.at(lo_t, body.s_of(lo_t, y))[0]
        # One smooth curve: from the break up the front of his chest to where it would reach his neck's
        # base, leaning back to A (a quadratic, so the flat roll line's straight run maps evenly).
        C = front_at(A3[0], A3[1] - 0.01)
        uu = np.linspace(0, 1, 26)[:, None]
        roll = (1 - uu) ** 2 * B3 + 2 * uu * (1 - uu) * C + uu ** 2 * A3
        roll = body.onto(roll, only_out=True)
        roll[0], roll[-1] = B3, A3
        # The back's neckline, centre back to the neck point.
        selb = (th_ring >= 90) & (th_ring <= 180)
        neck_back = ring[selb][::-1]

        # The hem rings.
        _, hem_back = body.ring(lm.hem_y, th_hem_side, 180, 60)
        _, hem_fore = body.ring(lm.hem_y, th_hem_side, th_front[0], 60)
        # The centre back.
        cb_y = np.linspace(lm.hem_y, lm.nape_y, 40)
        cb = body.at(np.full(40, 180.0), body.s_of(np.full(40, 180.0), cb_y))
        cb[-1] = lm.nape

        # --- The back (right half) ---
        D = dr.back
        n = lambda *polys: max(3, int(round(max(arclen(p)[-1] for p in polys) / EDGE_IN)) + 1)  # noqa: E731
        n_sh = n(D["shoulder"], dr.fore["shoulder"])
        n_side = n(D["side"], dr.fore["side"])
        n_ah_b = max(4, len(arm.path(0, i_st, -1)))
        segs2 = [("neck", resample(D["neck"], n(D["neck"]))),
                 ("shoulder", resample(D["shoulder"], n_sh)),
                 ("armhole", resample(D["armhole"], n_ah_b)),
                 ("side", resample(D["side"], n_side)),
                 ("hem", resample(D["hem"], n(D["hem"]))),
                 ("centre", resample(D["centre"], n(D["centre"])))]
        segs3 = [("neck", resample(neck_back, n(D["neck"]))),
                 ("shoulder", resample(sh, n_sh)),
                 ("armhole", arm.pts(arm.path(0, i_st, -1))),
                 ("side", resample(side, n_side)),
                 ("hem", resample(hem_back, n(D["hem"]))),
                 ("centre", resample(cb, n(D["centre"])))]
        self.shoulder3 = segs3[1][1]
        self.side3 = segs3[3][1]
        fb = Flat("back_r", segs2)
        bpush = lambda X: self.skin_push(X, "body")  # noqa: E731
        Vb = lay_on_body(fb, segs3, body, 135, push=bpush)
        y_vent = v(cfg, "back", "half_belt_centre_of_his_height") * self.st.height - v(cfg, "back", "half_belt_height_m") * hscale / 2
        self.y_vent = y_vent
        cen = fb.ranges["centre"]
        vent = [i for i in cen if Vb[i, 1] <= y_vent + 1e-6]
        back = Piece("back_r", Vb, fb.T, fb.P, [fb.ranges["hem"], vent])
        back.flat = fb

        # --- The forepart (right) ---
        F = dr.fore
        front2 = F["front"]                               # from the hem up
        yb = yd(self.y_break)
        f2 = [p for p in front2 if p[1] > yb]
        xb = float(np.interp(yb, F["front"][:, 1], F["front"][:, 0]))
        front2 = np.vstack([f2, [[xb, yb]]])
        A2 = point_at(F["neck"], v(cfg, "plate8_rules", "break_line_ahead_of_neck_point") * xs)
        n_ah_f = len(arm.path(0, i_st, +1))
        n_front = n(front2)
        n_roll = n(np.vstack([front2[-1:], A2[None]]))
        segs2 = [("shoulder", resample(F["shoulder"], n_sh)),
                 ("armhole", resample(F["armhole"], n_ah_f)),
                 ("side", resample(F["side"], n_side)),
                 ("hem", resample(F["hem"], n(F["hem"]))),
                 ("front", resample(front2, n_front)),
                 ("roll", resample(np.vstack([front2[-1:], A2[None]]), n_roll)),
                 ("neck", np.vstack([A2, F["neck"][0]]))]
        segs3 = [("shoulder", resample(sh, n_sh)),
                 ("armhole", arm.pts(arm.path(0, i_st, +1))),
                 ("side", resample(side, n_side)),
                 ("hem", resample(hem_fore, n(F["hem"]))),
                 ("front", resample(front, n_front)),
                 ("roll", resample(roll, n_roll)),
                 ("neck", neck_front)]
        ff = Flat("fore_r", segs2)
        Vf = lay_on_body(ff, segs3, body, 50, push=bpush)
        fore = Piece("fore_r", Vf, ff.T, ff.P, [ff.ranges["hem"], ff.ranges["front"]])
        fore.flat = ff
        self.roll3 = segs3[5][1]
        self.front3 = segs3[4][1]

        self.landmarks.update({
            "neck_point": NP, "nape": lm.nape, "shoulder_point": SP, "armhole_top": SP,
            "armhole_bottom": arm.P[int(np.argmin(arm.P[:, 1]))], "forearm_notch": arm.P[i_notch],
            "side_top": arm.P[i_st], "break": B3, "roll_top": A3,
            "chest_line_y": lm.breast_y, "waist_line_y": lm.waist_y, "hip_line_y": lm.hip_y, "hem_y": lm.hem_y,
            "vent_top_y": y_vent})
        self.idx = {"st": i_st, "notch": i_notch}
        self.back, self.fore = back, fore
        self.pieces += [back, fore]
        self._sleeve()
        self._lapel()
        self._collar()
        self._belt()
        self._folds()
        # The left side: the right's mirror image, its pattern turned over (the other of the pair).
        left = [p.mirrored(p.name[:-2] + "_l") for p in self.pieces if p.name.endswith("_r")]
        self.pieces += left
        # The vent: below its top the left half laps over the right by a cloth's thickness (lying
        # exactly together their edges would fight on screen), easing in over 3 cm.
        th = v(cfg, "cloth", "thickness_m")
        for p, sgn in ((self.back, -0.5), (next(q for q in left if q.name == "back_l"), 0.5)):
            n = vertex_normals(p.V, p.T, ("trunk", lm.axis))
            w = smoothstep((self.y_vent - p.V[:, 1]) / 0.03) * np.clip(1 - np.abs(p.V[:, 0]) / 0.04, 0, 1)
            p.V = p.V + n * (sgn * th * w)[:, None]

    def skin_push(self, P, which="all"):
        """Each point at least the vest and clearance outside his skin, along the skin's normal."""
        tree, idx = self.skin_trees[which]
        P = np.array(P, float)
        margin = self.lm.vest + self.lm.clear
        # Against one plane through his nearest skin (their mean point and normal), so neighbouring
        # points are pushed alike where his skin turns.
        _, j = tree.query(P, k=8)
        q = self.st.V[idx[j]].mean(1)
        n = self.skin_n[idx[j]].mean(1)
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        d = ((P - q) * n).sum(1)
        fix = d < margin
        P[fix] += n[fix] * (margin - d[fix])[:, None]
        return P

    # --- The sleeves (plate 16) ---
    def _sleeve(self):
        cfg, lm, arm, st, body = self.cfg, self.lm, self.arm, self.st, self.body
        J = st.joints
        sh, el, wr = J["r-shoulder"], J["r-elbow"], J["r-hand"]
        axis = np.array([sh, el, wr + (wr - el) * 0.2])
        self.arm_axis = axis
        sig = arclen(axis)
        X = np.array([1.0, 0, 0])

        def frame(k):
            t = axis[k + 1] - axis[k]
            t /= np.linalg.norm(t)
            eo = X - (X @ t) * t
            eo /= np.linalg.norm(eo)
            ef = np.cross(t, eo)
            if ef[2] > 0:
                ef = -ef
            return t, eo, ef

        frames = [frame(k) for k in range(len(axis) - 1)]

        def to_arm(P):
            P = np.atleast_2d(P)
            out = []
            for p in P:
                best = None
                for k in range(len(axis) - 1):
                    a, b = axis[k], axis[k + 1]
                    t = float(np.clip((p - a) @ (b - a) / ((b - a) @ (b - a)), -1 if k == 0 else 0, 1 if k < len(axis) - 2 else 2))
                    q = a + t * (b - a)
                    d = np.linalg.norm(p - q)
                    if best is None or d < best[0]:
                        best = (d, k, t, q)
                d, k, t, q = best
                _, eo, ef = frames[k]
                w = p - q
                out.append((sig[k] + t * (sig[k + 1] - sig[k]), math.degrees(math.atan2(w @ ef, w @ eo)), d))
            return np.array(out)

        def from_arm(s, phi, r):
            s, phi, r = np.atleast_1d(s), np.atleast_1d(phi), np.atleast_1d(r)
            out = []
            for ss, pp, rr in zip(s, phi, r):
                k = int(np.clip(np.searchsorted(sig, ss) - 1, 0, len(axis) - 2))
                t = (ss - sig[k]) / (sig[k + 1] - sig[k])
                q = axis[k] + t * (axis[k + 1] - axis[k])
                _, eo, ef = frames[k]
                a = math.radians(pp)
                out.append(q + rr * (math.cos(a) * eo + math.sin(a) * ef))
            return np.array(out)

        # His arm, seen from its bones: the outermost radius by (along, round).
        AP = sample(st.V, st.part(["upper_arm_r", "forearm_r"]), 60000)
        ap = to_arm(AP[::3])
        s_bins = np.arange(-0.05, sig[-1] + 0.05, 0.01)
        f_bins = np.arange(-180, 181, 15)
        Rarm = np.zeros((len(s_bins), len(f_bins)))
        iS = np.clip(np.searchsorted(s_bins, ap[:, 0]) - 1, 0, len(s_bins) - 1)
        iF = np.clip(np.searchsorted(f_bins, ap[:, 1]) - 1, 0, len(f_bins) - 1)
        np.maximum.at(Rarm, (iS, iF), ap[:, 2])
        Rarm = np.maximum(Rarm, np.maximum(np.roll(Rarm, 1, 1), np.roll(Rarm, -1, 1)))

        def arm_r(s, phi):
            i = np.clip(np.searchsorted(s_bins, s) - 1, 0, len(s_bins) - 1)
            j = np.clip(np.searchsorted(f_bins, ((phi + 180) % 360) - 180) - 1, 0, len(f_bins) - 1)
            return Rarm[i, j]

        # The pattern: s along A-O, h across. Its crown E (s 5) is his shoulder point, its cuff his
        # wrist less the shirt's cuff showing (his pictures).
        p16 = cfg["plate16"]
        top = {k: np.array(p, float) for k, p in p16["top"].items()}
        und = {k: np.array(p, float) for k, p in p16["under"].items()}
        loop = to_arm(arm.P)
        s_sp = loop[0, 0]
        s_cuff = to_arm(J["r-hand"])[0, 0] - v(cfg, "sleeve", "shirt_cuff_showing_m") * self.hscale
        p_crown, p_cuff = 5.0, float((top["cuff"][:, 0].mean() + und["cuff"][:, 0].mean()) / 2)
        fs = (s_cuff - s_sp) / ((p_cuff - p_crown) * IN)          # along the sleeve, pattern to stand
        # Across: the manual sizes the sleeve's top by the armhole ('C to E is half scye and 1/2 inch',
        # 'enlarge or decrease equally ... until the desired size is obtained', p. 40) and gives the
        # cuff as it is ('6 1/4 inches, more or less'): the top scaled to his armhole, easing to the
        # plate's own widths by the elbow.
        scye_in = arclen(np.vstack([arm.P, arm.P[:1]]))[-1] / IN
        ce = float(np.linalg.norm(top["cap"][-1] - top["cap"][0]))
        k_cap = (scye_in / 2 + 0.5) / ce
        p_elbow = 12.92

        def kx(s):
            return k_cap + (1 - k_cap) * smoothstep((np.asarray(s) - p_crown) / (p_elbow - p_crown))

        sc = lambda P: np.c_[P[:, 0] * fs, P[:, 1] * kx(P[:, 0])]          # noqa: E731
        self.sleeve_scale = (fs, k_cap)

        def width(piece, s):
            hind, fore = piece["hind"], piece["fore"]
            hi = np.interp(s, hind[:, 0], hind[:, 1])
            fo = fore[np.argsort(fore[:, 0])]
            lo = np.interp(s, fo[:, 0], fo[:, 1])
            return hi - lo

        def s_pat(s):
            return p_crown + (np.asarray(s) - s_sp) / (fs * IN)

        def r_tube(s):
            ps = np.clip(s_pat(s), p_crown, p_cuff)
            return (width(top, ps) + width(und, ps)) * kx(ps) * IN / (2 * math.pi)

        cap = v(cfg, "plate8_rules", "cap_height") * IN
        s_el = to_arm(el)[0, 0]
        amp_el = v(cfg, "folds", "elbow_m")
        clear = lm.clear

        s_cap0 = float(np.median(loop[:, 0]))       # the cap's middle, along the arm

        def R(s, phi):
            """The sleeve's form: his arm and the clearance; below the cap, the pattern's girth."""
            s, phi = np.atleast_1d(s), np.atleast_1d(phi)
            pw = ((phi + 180) % 360) - 180
            w = smoothstep((s - s_cap0) / cap)
            r = np.maximum(arm_r(s, pw) + clear, r_tube(s) * w)
            # The wool broken in the crook of the elbow.
            crook = np.exp(-((pw - 125) / 35) ** 2) * np.exp(-((s - s_el) / 0.05) ** 2)
            return r + amp_el * crook * np.sin(2 * np.pi * (s - s_el) / 0.025)

        # The seams: the forearm seam from the notch (p. 40: 3/4 in over the breast line), the hind
        # seam from the back pitch, where the under sleeve's top (N-K-L) reaches round the bottom.
        i_n = self.idx["notch"]
        under_cap_len = arclen(sc(und["cap"]))[-1] * IN
        path = arm.path(i_n, i_n - 1, +1)
        a = arclen(arm.pts(path))
        i_bp = path[int(np.argmin(np.abs(a - under_cap_len)))]
        self.idx["back_pitch"] = i_bp
        self.landmarks["back_pitch"] = arm.P[i_bp]
        ps_el = s_pat(s_el)
        share = width(top, ps_el) / (width(top, ps_el) + width(und, ps_el))
        alpha = 180 * share
        n_seam = max(3, int(round(max(arclen(sc(top["hind"]))[-1], arclen(sc(und["hind"]))[-1]) / EDGE_IN)) + 1)

        def seam(i_start, phi_end):
            s0, p0, _ = loop[i_start]
            ss = np.linspace(s0, s_cuff, n_seam)
            ph = p0 + (phi_end - p0) * smoothstep((ss - s0) / cap)
            P = from_arm(ss, ph, R(ss, ph))
            w = smoothstep((ss - s0) / cap)[:, None]
            return arm.P[i_start] * (1 - w) + P * w

        f_end, h_end = alpha, -alpha
        fseam = seam(i_n, f_end)
        hseam = seam(i_bp, h_end)
        self.landmarks.update({"elbow": from_arm(s_el, 0, R(s_el, 0))[0], "cuff": from_arm(s_cuff, 0, R(s_cuff, 0))[0]})

        def cuff_ring(p_from, p_to, nn):
            ph = np.linspace(p_from, p_to, nn)
            return from_arm(np.full(nn, s_cuff), ph, R(np.full(nn, s_cuff), ph))

        amp_head = v(cfg, "folds", "sleeve_head_m")

        def push(P):
            P = P.copy()
            ta = to_arm(P)
            w = smoothstep((ta[:, 0] - s_cap0) / cap)
            r_min = r_tube(ta[:, 0]) * w
            low = ta[:, 2] < r_min
            if low.any():
                P[low] = from_arm(ta[low, 0], ta[low, 1], r_min[low])
            return body.onto(self.skin_push(P, "all"), only_out=True)

        def lay(flat, segs3, phis, rounds=40):
            """Its edges on their curves; inside, first round his arm (along, round and out, each a
            harmonic map of the flat piece, the round of each edge given: the top sleeve from the
            forearm seam over the outside to the hind seam, the under sleeve round the inside),
            then relaxed against the sleeve's form and his skin."""
            bidx, b3, bph = [], [], []
            for (nm, pts), ph in zip(segs3, phis):
                r = flat.ranges[nm]
                a = arclen(pts)
                f = a / max(a[-1], 1e-9)
                for k, i in enumerate(r[:-1]):
                    bidx.append(i)
                    b3.append(pts[k])
                    bph.append(ph[0] + (ph[1] - ph[0]) * f[k])
            b3 = np.array(b3)
            ta = to_arm(b3)
            kk = math.radians(1) * 0.06
            prm = harmonic(flat.P, flat.T, bidx, np.c_[ta[:, 0], np.array(bph) * kk, ta[:, 2]])
            V = from_arm(prm[:, 0], prm[:, 1] / kk, prm[:, 2])
            V[bidx] = b3
            fi = np.setdiff1d(np.arange(len(V)), bidx)
            nb = [set() for _ in range(len(V))]
            for a, b_, c in flat.T:
                nb[a] |= {b_, c}
                nb[b_] |= {a, c}
                nb[c] |= {a, b_}
            nbl = [np.array(sorted(x)) for x in nb]
            V[fi] = push(V[fi])
            for _ in range(rounds):
                avg = np.array([V[nbl[i]].mean(0) for i in fi])
                V[fi] = push(V[fi] + 0.6 * (avg - V[fi]))
            V = untangle(V, flat.T, flat.P, bidx, ("arm", axis), push)
            # The sleeve head's ease: a little fullness over the top of the cap.
            ta = to_arm(V[fi])
            bump = amp_head * np.exp(-(ta[:, 1] / 50) ** 2) * np.sin(np.pi * np.clip((ta[:, 0] - (s_cap0 - cap / 2)) / cap, 0, 1))
            V[fi] = from_arm(ta[:, 0], ta[:, 1], ta[:, 2] + bump)
            return V

        nn = lambda P: max(3, int(round(arclen(P)[-1] / EDGE_IN)) + 1)  # noqa: E731
        over = arm.path(i_n, i_bp, -1)
        under = arm.path(i_n, i_bp, +1)
        # Top sleeve: cap C->E over his shoulder, hind E->U, cuff U->S round the outside, fore S->C.
        segs2 = [("cap", resample(sc(top["cap"]), len(over))),
                 ("hind", resample(sc(top["hind"]), n_seam)),
                 ("cuff", resample(sc(top["cuff"]), nn(sc(top["cuff"])))),
                 ("fore", resample(sc(top["fore"]), n_seam))]
        segs3 = [("cap", arm.pts(over)),
                 ("hind", hseam),
                 ("cuff", cuff_ring(h_end, f_end, nn(sc(top["cuff"])))),
                 ("fore", fseam[::-1])]
        ft = Flat("sleeve_top_r", segs2)
        Vt = lay(ft, segs3, [(alpha, -alpha), (-alpha, -alpha), (-alpha, alpha), (alpha, alpha)])
        # Under sleeve: cap L->N under his arm, hind N->T, cuff T->S' round the inside, fore S'->L.
        segs2 = [("cap", resample(sc(und["cap"]), len(under))),
                 ("hind", resample(sc(und["hind"]), n_seam)),
                 ("cuff", resample(sc(und["cuff"]), nn(sc(und["cuff"])))),
                 ("fore", resample(sc(und["fore"]), n_seam))]
        segs3 = [("cap", arm.pts(under)),
                 ("hind", hseam),
                 ("cuff", cuff_ring(h_end, -360 + f_end, nn(sc(und["cuff"])))),
                 ("fore", fseam[::-1])]
        fu = Flat("sleeve_under_r", segs2)
        Vu = lay(fu, segs3, [(alpha, 360 - alpha), (360 - alpha, 360 - alpha), (360 - alpha, alpha), (alpha, alpha)])
        ax = ("arm", axis)
        self.pieces += [Piece("sleeve_top_r", Vt, ft.T, ft.P, [ft.ranges["cuff"]], ax),
                        Piece("sleeve_under_r", Vu, fu.T, fu.P, [fu.ranges["cuff"]], ax)]
        self.sleeve_report = {"crown_to_cuff_m": round(float(s_cuff - s_sp), 3), "along_scale": round(float(fs), 3),
                              "armhole_in": round(float(scye_in), 2), "cap_width_scale": round(float(k_cap), 3),
                              "tube_round_at_elbow_m": round(float(2 * math.pi * r_tube(s_el)), 3),
                              "top_share": round(float(share), 3)}

    # --- The lapels: the forepart's front above the break, turned back along the roll line ---
    def _project_fore(self):
        """Points onto the forepart's outside: (nearest sample, its normal)."""
        if not hasattr(self, "_fore_proj"):
            from scipy.spatial import cKDTree
            fore = self.fore
            FS = sample(fore.V, fore.T, 40000)
            fn = vertex_normals(fore.V, fore.T, ("trunk", self.lm.axis))
            self._fore_proj = (cKDTree(FS), FS, cKDTree(fore.V), fn)
        tree, FS, vtree, fn = self._fore_proj

        def proj(P, out):
            P = np.atleast_2d(P)
            q = FS[tree.query(P)[1]]
            n = fn[vtree.query(q)[1]]
            return q + n * out, n
        return proj

    def _lapel(self):
        cfg = self.cfg
        th = v(cfg, "cloth", "thickness_m")
        roll = self.roll3                     # the forepart's roll edge, from the break up to A
        ar = arclen(roll)
        y_notch = v(cfg, "lapel", "notch_height_of_his_height") * self.st.height
        w_p = v(cfg, "lapel", "width_at_notch_m") * self.hscale
        # The gorge seam meets the roll line level with the notch; the lapel turns back below it.
        iG = int(np.argmin(np.abs(roll[:, 1] - y_notch)))
        t_g = ar[iG]
        proj = self._project_fore()
        fn_at = lambda P: proj(P, 0)[1]   # noqa: E731
        tan = np.gradient(roll, axis=0)

        def across(i):
            d = np.cross(fn_at(roll[i])[0], tan[i])
            d /= np.linalg.norm(d)
            return d if d[0] > 0 else -d
        # Its point: the lapel's width out from the roll, square to it, at the gorge.
        P3 = proj(roll[iG] + across(iG) * w_p, th)[0][0]
        segs2 = [("roll", np.c_[ar[:iG + 1] / IN, np.zeros(iG + 1)]),
                 ("top", resample(np.array([[t_g / IN, 0], [t_g / IN, w_p / IN]]), max(3, int(w_p / IN / EDGE_IN) + 2))),
                 ("outer", resample(np.array([[t_g / IN, w_p / IN], [0, 0]]), max(3, int(math.hypot(t_g, w_p) / IN / EDGE_IN) + 2)))]
        fl = Flat("lapel_r", segs2, edge=EDGE_IN * 0.8)

        def place(t_in, w_in):
            t = np.clip(t_in * IN, 0, t_g)
            base = np.stack([np.interp(t, ar, roll[:, k]) for k in range(3)], -1)
            d = np.array([across(int(np.clip(np.searchsorted(ar, tt), 0, len(ar) - 1))) for tt in t])
            return proj(base + d * (w_in * IN)[:, None], th)[0]
        V = place(fl.P[:, 0], fl.P[:, 1])
        rr = fl.ranges["roll"]
        V[rr] = proj(roll[:iG + 1], th)[0]
        lap = Piece("lapel_r", V, fl.T, fl.P, [fl.ranges["top"], fl.ranges["outer"]])
        lap.flat = fl
        # The fold: a cloth's thickness from the forepart's roll edge up to the lapel's.
        fr = self.fore.flat.ranges["roll"][:iG + 1]
        fv = self.fore.V[fr]
        lv = V[rr]
        n = len(fv)
        Vf = np.vstack([fv, lv])
        T = []
        for i in range(n - 1):
            T += [[i, i + 1, n + i + 1], [i, n + i + 1, n + i]]
        fold = Piece("fold_r", Vf, np.array(T), np.vstack([self.fore.UV[fr], self.fore.UV[fr]]), [], None)
        self.pieces += [lap, fold]
        self.lapel = lap
        self.iG = iG
        self.landmarks.update({"lapel_point": P3, "gorge": roll[iG], "notch_y": y_notch})

    # --- The collar: a stand (p. 44) and a fall (his pictures), its crease running into the roll ---
    def _collar(self):
        cfg, lm, body = self.cfg, self.lm, self.body
        th_c = v(cfg, "cloth", "thickness_m")
        stand = v(cfg, "collar", "stand") * IN
        fall = v(cfg, "collar", "fall_m") * self.hscale
        gap = v(cfg, "lapel", "notch_gap_m") * self.hscale
        ring_th, ring = lm.neckline_ring
        sel = (ring_th >= 90) & (ring_th <= 180)
        back = ring[sel][np.argsort(-ring_th[sel])]      # centre back round to the neck point
        back = resample(back, 9)
        ax = lm.neck_axis
        # Onto the coat under it (the back over his shoulder, the forepart and the lapel in front).
        from scipy.spatial import cKDTree
        S, Nn = [], []
        for pc in (self.back, self.fore, self.lapel):
            vn = vertex_normals(pc.V, pc.T, ("trunk", lm.axis))
            a, b_, c = pc.T[:, 0], pc.T[:, 1], pc.T[:, 2]
            rng = np.random.default_rng(5)
            k = 12000
            ti = rng.integers(0, len(pc.T), k)
            u, w = rng.random(k), rng.random(k)
            f = u + w > 1
            u[f], w[f] = 1 - u[f], 1 - w[f]
            S.append(pc.V[a[ti]] + (pc.V[b_[ti]] - pc.V[a[ti]]) * u[:, None] + (pc.V[c[ti]] - pc.V[a[ti]]) * w[:, None])
            nn_ = vn[a[ti]] + vn[b_[ti]] + vn[c[ti]]
            Nn.append(nn_ / np.linalg.norm(nn_, axis=1, keepdims=True))
        S, Nn = np.vstack(S), np.vstack(Nn)
        ctree = cKDTree(S)

        def proj(P, out):
            P = np.atleast_2d(P)
            j = ctree.query(P)[1]
            return S[j] + Nn[j] * out, Nn[j]
        # Round the back: the stand up his neck, then the fall down over it and onto the coat.
        cols = []
        for B in back:
            radial = np.array([B[0] - ax[0], 0, B[2] - ax[1]])
            radial /= max(np.linalg.norm(radial), 1e-9)
            up = np.array([0, 1.0, 0]) - 0.12 * radial
            up /= np.linalg.norm(up)
            K = B + up * stand
            t, sB = body.polar(B[None])
            F = body.at(t, sB - (fall - stand), out=th_c)[0]
            ctrl = K + radial * 0.25 * np.linalg.norm(F - K) + np.array([0, 0.003, 0])
            fall_rows = [(1 - u) ** 2 * K + 2 * (1 - u) * u * ctrl + u * u * F for u in (1 / 3, 2 / 3, 1.0)]
            cols.append([B, (B + K) / 2, K] + fall_rows)
        # Toward the front: it lies flat over the roll line, from the neck point down to the gorge,
        # out to its edge, which comes down over the shoulder to the collar's end at the notch.
        roll = self.roll3[self.iG:][::-1]              # from A down to the gorge
        lap = self.lapel
        top = lap.V[lap.flat.ranges["top"]]            # the gorge seam: from the roll out to the lapel's point
        CE = point_at(top, max(0.0, arclen(top)[-1] - gap))
        F0 = np.array(cols[-1][-1])
        K0 = np.array(cols[-1][2])
        nf = 6
        for k in range(1, nf + 1):
            u = k / nf
            inner = point_at(roll, u * arclen(roll)[-1])
            inner = proj(inner, 2 * th_c)[0][0]
            outer = proj(F0 + (CE - F0) * u, 2 * th_c)[0][0]
            inner = K0 + (inner - K0) * smoothstep(u * 2) if u < 0.5 else inner
            rows = [inner + (outer - inner) * f for f in (0, 0, 0, 1 / 3, 2 / 3, 1.0)]
            rows = [proj(r, 2 * th_c)[0][0] if 0 < f < 1 else r for r, f in zip(rows, (0, 0, 0, 1 / 3, 2 / 3, 1))]
            st_h = stand * 0.06
            rows[0] = rows[2] - np.array([0, st_h, 0])
            rows[1] = rows[2] - np.array([0, st_h / 2, 0])
            cols.append(rows)
        G = np.array(cols)                      # (columns, 6, 3), centre back first
        Gl = mirror(G[1:][::-1])
        G = np.vstack([Gl, G])
        nc, nr = G.shape[0], G.shape[1]
        V = G.reshape(-1, 3)
        T = []
        for i in range(nc - 1):
            for j in range(nr - 1):
                a, b, c, d = i * nr + j, (i + 1) * nr + j, (i + 1) * nr + j + 1, i * nr + j + 1
                T += [[a, b, c], [a, c, d]]
        crease = G[:, 2]
        u = arclen(crease) / IN
        UV = np.zeros((nc, nr, 2))
        for i in range(nc):
            UV[i, :, 0] = u[i]
            d = arclen(G[i]) / IN
            UV[i, :, 1] = d - d[2]
        UV = UV.reshape(-1, 2)
        fall_edge = [i * nr + nr - 1 for i in range(nc)]
        end_r = [(nc - 1) * nr + j for j in range(2, nr)]
        end_l = [j for j in range(2, nr)]
        col = Piece("collar", V, np.array(T), UV, [fall_edge, end_r, end_l], ("neck", lm.neck_axis))
        self.pieces.append(col)
        r_crease = np.hypot(back[:, 0] - ax[0], back[:, 2] - ax[1]).mean() + 0.0
        r_neck = r_crease - lm.vest - lm.clear
        self.collar_report = {"stand_m": round(float(stand), 4), "fall_m": round(float(fall), 4),
                              "crease_over_neck_round": round(float(r_crease / r_neck), 3)}

    # --- The half-belt across the back, and its two buttons (his pictures) ---
    def _belt(self):
        cfg, body = self.cfg, self.body
        th_c = v(cfg, "cloth", "thickness_m")
        y_c = v(cfg, "back", "half_belt_centre_of_his_height") * self.st.height
        L = v(cfg, "back", "half_belt_length_m") * self.hscale
        H = v(cfg, "back", "half_belt_height_m") * self.hscale
        self.y_belt = y_c
        # Across the back: arc from the centre back on the coat's ring at its height.
        th, P = body.ring(y_c, 180, 90, 181)
        a = arclen(P)
        cols = 13
        offs = np.linspace(-L / 2, L / 2, cols)
        G = []
        for o in offs:
            t = float(np.interp(abs(o), a, th))
            t = t if o >= 0 else -t
            col = []
            for dy in (-H / 2, 0, H / 2):
                s = body.s_of(t, y_c + dy)
                col.append(body.at(t, s, out=th_c)[0])
            G.append(col)
        G = np.array(G)
        V = G.reshape(-1, 3)
        T = []
        for i in range(cols - 1):
            for j in range(2):
                a0, b0, c0, d0 = i * 3 + j, (i + 1) * 3 + j, (i + 1) * 3 + j + 1, i * 3 + j + 1
                T += [[a0, b0, c0], [a0, c0, d0]]
        UV = np.stack(np.meshgrid(offs / IN, np.array([-H / 2, 0, H / 2]) / IN, indexing="ij"), -1).reshape(-1, 2)
        ring_edge = [i * 3 for i in range(cols)] + [(cols - 1) * 3 + 1, (cols - 1) * 3 + 2] + \
            [i * 3 + 2 for i in range(cols - 1)][::-1] + [1]
        V, T, UV = list(V), list(T), list(UV)
        # The buttons: flat octagons a little proud of the belt.
        r_b = 0.0135 * self.hscale
        apart = v(cfg, "back", "half_belt_buttons_apart_m") * self.hscale
        for sgn in (-1, 1):
            t = float(np.interp(apart / 2, a, th)) * sgn
            s = body.s_of(t, y_c)
            c = body.at(t, s, out=th_c + 0.004)[0]
            nrm = c - np.array([self.lm.axis[0], c[1], self.lm.axis[1]])
            nrm /= np.linalg.norm(nrm)
            e1 = np.cross([0, 1.0, 0], nrm)
            e1 /= np.linalg.norm(e1)
            e2 = np.cross(nrm, e1)
            k0 = len(V)
            V.append(c)
            UV.append([L / IN / 2 + 1.0 + (0 if sgn < 0 else 1.2), 0])
            for k in range(8):
                ang = 2 * math.pi * k / 8
                V.append(c + r_b * (math.cos(ang) * e1 + math.sin(ang) * e2))
                UV.append([L / IN / 2 + 1.0 + (0 if sgn < 0 else 1.2) + 0.5 * math.cos(ang), 0.5 * math.sin(ang)])
            for k in range(8):
                T.append([k0, k0 + 1 + k, k0 + 1 + (k + 1) % 8])
        self.pieces.append(Piece("belt", np.array(V), np.array(T), np.array(UV), [ring_edge], None))

    # --- Folds where the wool breaks across the back of the waist, under the half-belt ---
    def _folds(self):
        amp = v(self.cfg, "folds", "back_waist_m")
        p = self.back
        n = vertex_normals(p.V, p.T, ("trunk", self.lm.axis))
        L = v(self.cfg, "back", "half_belt_length_m") * self.hscale / 2
        x = np.abs(p.V[:, 0])
        dy = p.V[:, 1] - self.y_belt
        w = np.clip(1 - np.abs(dy) / 0.12, 0, 1) * np.clip((L - x) / 0.04, 0, 1)
        p.V = p.V + n * (amp * w * np.sin(2 * np.pi * x / 0.035))[:, None]


def vertex_normals(V, T, ref):
    """Area-weighted, turned to face away from `ref`: ("trunk"|"neck", (x, z) axis) or ("arm", polyline)."""
    a, b, c = V[T[:, 0]], V[T[:, 1]], V[T[:, 2]]
    fn = np.cross(b - a, c - a)
    N = np.zeros_like(V)
    for j in range(3):
        np.add.at(N, T[:, j], fn)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)
    out = away(V, ref)
    flip = (N * out).sum(1) < 0
    N[flip] *= -1
    return N


def away(V, ref):
    kind, ax = ref
    if kind == "arm":
        out = np.zeros_like(V)
        for i, p in enumerate(V):
            best = None
            for k in range(len(ax) - 1):
                aa, bb = ax[k], ax[k + 1]
                t = float(np.clip((p - aa) @ (bb - aa) / ((bb - aa) @ (bb - aa)), 0, 1))
                q = aa + t * (bb - aa)
                d = np.linalg.norm(p - q)
                if best is None or d < best[0]:
                    best = (d, p - q)
            out[i] = best[1]
        return out
    return np.c_[V[:, 0] - ax[0], np.zeros(len(V)), V[:, 2] - ax[1]]


# --- Thickness, the pattern's atlas, the files ----------------------------------------------------

def close_edges(p, ref, th):
    """Each open edge closed with a strip a cloth's thickness deep, turned in under the piece."""
    N = vertex_normals(p.V, p.T, ref)
    V, T, UV = [p.V], [p.T], [p.UV]
    n0 = len(p.V)
    nbr = [set() for _ in range(n0)]
    for a, b, c in p.T:
        nbr[a] |= {b, c}
        nbr[b] |= {a, c}
        nbr[c] |= {a, b}
    # Which way round each edge runs in the piece's own triangles (the strip folds under it the same way).
    run = {}
    for t in p.T:
        for k in range(3):
            run[(int(t[k]), int(t[(k + 1) % 3]))] = True
    for e in p.edges:
        if len(e) < 2:
            continue
        e = np.array(e)
        base = sum(len(x) for x in V)
        V.append(p.V[e] - N[e] * th)
        UV.append(p.UV[e])
        tri = []
        for i in range(len(e) - 1):
            a, b = int(e[i]), int(e[i + 1])
            c, d = base + i + 1, base + i
            if run.get((a, b)):
                tri += [[b, a, d], [b, d, c]]
            else:
                tri += [[a, b, c], [a, c, d]]
        T.append(np.array(tri))
    return np.vstack(V), np.vstack(T), np.vstack(UV)


def pack(islands, margin=0.6):
    """Shelf-pack the pieces' patterns (inches) into one square: {name: (offset, flip-free)}, side."""
    boxes = {k: (P.min(0), P.max(0)) for k, P in islands.items()}
    order = sorted(boxes, key=lambda k: -(boxes[k][1][1] - boxes[k][0][1]))
    total = sum((b[1] - b[0] + margin).prod() for b in boxes.values())
    width = math.sqrt(total) * 1.15
    x = y = shelf = 0.0
    place = {}
    for k in order:
        lo, hi = boxes[k]
        w, h = hi - lo + margin
        if x + w > width and x > 0:
            x, y, shelf = 0.0, y + shelf, 0.0
        place[k] = np.array([x, y]) - lo + margin / 2
        x += w
        shelf = max(shelf, h)
    side = max(width, y + shelf)
    return place, side


def pattern_image(islands, place, side, path, px=2048):
    from PIL import Image, ImageDraw
    im = Image.new("RGB", (px, px), (236, 232, 222))
    d = ImageDraw.Draw(im)
    k = px / side
    for name, (P, T) in islands.items():
        Q = (P + place[name]) * k
        for t in T:
            d.polygon([tuple(Q[i]) for i in t], fill=(214, 196, 168), outline=(196, 176, 146))
    for name, (P, T) in islands.items():
        Q = (P + place[name]) * k
        c = Q.mean(0)
        d.text((c[0] - 30, c[1]), name, fill=(60, 30, 20))
    im.save(path)


def main():
    args = dict(a.split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    cfg = json.load(open(CFG_PATH))
    hem = args.get("--hem", cfg["hem"]["default"])
    b = Build(cfg, hem)
    lm = b.lm
    th = v(cfg, "cloth", "thickness_m")
    final = []
    for p in b.pieces:
        ref = p.axis if p.axis is not None else ("trunk", lm.axis)
        # Every triangle facing away from what it covers (the strips are wound by their own edge).
        N0 = vertex_normals(p.V, p.T, ref)
        fnorm = np.cross(p.V[p.T[:, 1]] - p.V[p.T[:, 0]], p.V[p.T[:, 2]] - p.V[p.T[:, 0]])
        flip = (fnorm * N0[p.T].mean(1)).sum(1) < 0
        p.T[flip] = p.T[flip][:, ::-1]
        V, T, UV = close_edges(p, ref, th)
        N = vertex_normals(V, T, ref)
        final.append((p.name, V, T, UV, N))
    # The pattern's atlas: each piece where it lies in the drafted pattern, packed (the folds take
    # their forepart's place).
    share = {"fold_r": "fore_r", "fold_l": "fore_l"}
    islands = {n: (UV[:len(p.UV)], p.T) for (n, V, T, UV, N), p in zip(final, b.pieces) if n not in share}
    place, side = pack({k: x[0] for k, x in islands.items()})
    out = []
    for n, V, T, UV, N in final:
        q = (UV + place[share.get(n, n)]) / side
        out.append((n, V, T, np.c_[q[:, 0], 1 - q[:, 1]], N))
    pattern_image(islands, place, side, os.path.join(ROOT, "docs", "style_test", "coat", "sack_coat_pattern.png"))
    tris = sum(len(T) for _n, _V, T, _u, _N in out)
    rep = report(b, out, place, side, tris, hem)
    cfg["template"] = rep
    with open(CFG_PATH, "w") as f:
        f.write(dumps(cfg) + "\n")
    export_glb(out, os.path.join(GARMENTS, "sack_coat.glb"))
    print("sack_coat:", tris, "triangles,", len(out), "pieces;", json.dumps({k: rep[k] for k in ("faults",)}))
    if "--sheet" in args:
        render_sheet(b, out, args["--sheet"], by_piece="--by-piece" in sys.argv,
                     only=args["--views"].split(",") if "--views" in args else None)


def dumps(obj):
    """JSON with each list of numbers on one line."""
    import re
    text = json.dumps(obj, indent=1)
    text = re.sub(r"\[\s*([-0-9.eE,\s]+?)\s*\]", lambda m: "[" + re.sub(r"\s+", " ", m.group(1)).strip() + "]", text)
    return re.sub(r"\{\n\s*((?:\"[^\"\n]*\": (?:-?[0-9.eE]+|\"[^\"\n]*\"|true|false|null|\[[^\]\n]*\]),?\n\s*){1,4})\}",
                  lambda m: "{" + ", ".join(x.strip().rstrip(",") for x in m.group(1).strip().split("\n")) + "}", text)


def report(b, out, place, side, tris, hem):
    lm, st = b.lm, b.st
    from scipy.spatial import cKDTree
    skin = cKDTree(sample(st.V, st.T, 400000))
    # DONT_REPEAT 2: over the shoulder line, at most 12 mm off his skin.
    sh = b.shoulder3
    sh_mm = float(skin.query(sh)[0].max() * 1000)
    col = b.collar_report
    neck_girth = girth_at(st, lm.neck_point_y)
    pieces = {}
    for (n, V, T, UV, N), p in zip(out, b.pieces):
        a3 = 0.5 * np.linalg.norm(np.cross(p.V[p.T[:, 1]] - p.V[p.T[:, 0]], p.V[p.T[:, 2]] - p.V[p.T[:, 0]]), axis=1).sum()
        a2 = 0.5 * np.abs(np.cross(p.UV[p.T[:, 1]] - p.UV[p.T[:, 0]], p.UV[p.T[:, 2]] - p.UV[p.T[:, 0]])).sum() * IN * IN
        pieces[n] = {"triangles": int(len(T)), "vertices": int(len(V)), "area_m2": round(float(a3), 4),
                     "pattern_area_m2": round(float(a2), 4),
                     # (a fold is a strip on its forepart's roll edge: no area of its own in the pattern)
                     "laid_over_drafted": None if n.startswith("fold") else round(float(a3 / max(a2, 1e-9)), 3)}
    ease = []
    for name, y in (("breast", lm.breast_y), ("waist", lm.waist_y), ("hip", lm.hip_y), ("hem", lm.hem_y + 0.005)):
        yd = (lm.nape_y - y) / IN
        half = Draft.width_at(b.dr.back["side"], yd) + Draft.width_at(b.dr.fore["front"], yd) - Draft.width_at(b.dr.fore["side"], yd)
        ease.append({"line": name, "y": round(y, 3), "drafted_half_in": round(half, 2), "stand_off_m": round(float(b.ease(y)), 4)})
    L = lambda p: [round(float(x), 4) for x in np.asarray(p).ravel()]  # noqa: E731
    return {
        "_note": "Written by tools/blender/coat_template.py. Body space: metres, facing -Z, his right +X. The pieces' `laid_over_drafted` is each piece's area on the stand over its drafted area (under 1: the drafted cloth is fuller than where it lies; the open fronts carry the cloth that would have crossed to the buttons).",
        "hem": hem,
        "stand": {"source": "MakeHuman base (CC0): caucasian-male-young 1, averagemuscle min/max weight 0.5 each, on the game's skeleton (make_people.py warp + fit)",
                  "height_m": round(st.height, 3), "breast_over_vest_in": round(lm.breast_in, 2),
                  "waist_girth_in": round(lm.waist_girth_in, 2), "depth_of_scye_in": round(b.dr.scye, 2),
                  "natural_waist_in": round(b.dr.waist, 2), "full_length_in": round(b.dr.length, 2),
                  "width_scale": round(b.dr.xs, 4)},
        "landmarks": {k: (L(x) if np.ndim(x) else round(float(x), 4)) for k, x in b.landmarks.items()},
        "landmarks_joints": {k: L(st.joints[k]) for k in ("neck", "r-shoulder", "r-elbow", "r-hand", "hips", "r-knee")},
        "pocket_y": round(float(lm.breast_y - v(b.cfg, "pocket", "below_breast_line") * b.dr.scye / b.dr.p_scye * IN), 4),
        "ease": ease,
        "sleeve": b.sleeve_report,
        "collar": dict(col, neck_girth_m=round(neck_girth, 3)),
        "pieces": pieces,
        "triangles": int(tris),
        "atlas": {"side_in": round(float(side), 2), "islands": {k: L(x) for k, x in place.items()}},
        "faults": {"shoulder_line_max_off_skin_mm": round(sh_mm, 1), "shoulder_line_limit_mm": 12,
                   "collar_stand_m": col["stand_m"], "collar_stand_limit_m": 0.035,
                   "collar_over_neck_girth": col["crease_over_neck_round"], "collar_over_neck_limit": 1.25},
    }


def girth_at(st, y):
    P = sample(st.V, st.part(["trunk", "neck", "head"]), 300000)
    return girth(P[np.abs(P[:, 1] - y) < 0.003])


def to_blender(P):
    P = np.asarray(P, float)
    return np.c_[P[:, 0], -P[:, 2], P[:, 1]]


PIECE_COLOURS = {"back": (0.55, 0.25, 0.12), "fore": (0.25, 0.4, 0.6), "sleeve_top": (0.3, 0.55, 0.25),
                 "sleeve_under": (0.6, 0.55, 0.2), "lapel": (0.7, 0.2, 0.5), "collar": (0.85, 0.75, 0.6),
                 "belt": (0.2, 0.2, 0.2), "fold": (1, 1, 1)}


def blender_scene(out, stand=None, colour=(0.36, 0.2, 0.11), by_piece=False):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mat = bpy.data.materials.new("cloth_coat")
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*colour, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.9
    objs = []
    for n, V, T, UV, N in out:
        me = bpy.data.meshes.new(n)
        me.from_pydata(to_blender(V).tolist(), [], T.tolist())
        me.update()
        uv = me.uv_layers.new(name="UVMap")
        loops = np.array([li for poly in me.polygons for li in poly.vertices])
        uv.data.foreach_set("uv", UV[loops].ravel())
        me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
        if by_piece:
            m2 = bpy.data.materials.new(n)
            key = n[:-2] if n[-2:] in ("_r", "_l") else n
            m2.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (*PIECE_COLOURS.get(key, colour), 1)
            me.materials.append(m2)
        else:
            me.materials.append(mat)
        ob = bpy.data.objects.new(n, me)
        bpy.context.scene.collection.objects.link(ob)
        objs.append(ob)
    if stand is not None:
        V, T = stand
        me = bpy.data.meshes.new("stand")
        me.from_pydata(to_blender(V).tolist(), [], T.tolist())
        me.polygons.foreach_set("use_smooth", [True] * len(me.polygons))
        sm = bpy.data.materials.new("stand")
        sm.use_nodes = True
        sm.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (0.55, 0.55, 0.56, 1)
        me.materials.append(sm)
        ob = bpy.data.objects.new("stand", me)
        bpy.context.scene.collection.objects.link(ob)
    return objs


def export_glb(out, path):
    import bpy
    blender_scene(out)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False,
                              export_yup=True, export_normals=True, export_texcoords=True)


def render_sheet(b, out, folder, by_piece=False, only=None):
    import bpy
    os.makedirs(folder, exist_ok=True)
    blender_scene(out, stand=None if "--no-stand" in sys.argv else (b.st.V, b.st.T), by_piece=by_piece)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 24
    sc.render.film_transparent = False
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.62, 0.62, 0.64, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    sc.world = world
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), math.radians(-20), math.radians(-30))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.type = "ORTHO"
    sc.collection.objects.link(cam)
    sc.camera = cam
    from mathutils import Vector
    # Our body space faces -Z, which is Blender's +Y: the front camera stands at +Y.
    views = {"front": ((0, 4, 1.1), (0, 0, 1.1), 1.75, (520, 900)),
             "side": ((4, 0, 1.1), (0, 0, 1.1), 1.75, (520, 900)),
             "back": ((0, -4, 1.1), (0, 0, 1.1), 1.75, (520, 900)),
             "three_quarter": ((2.83, 2.83, 1.1), (0, 0, 1.1), 1.75, (520, 900)),
             "collar": ((0.55, 1.1, 1.75), (0.03, 0.0, 1.42), 0.42, (900, 640)),
             "collar_back": ((-0.45, -1.1, 1.75), (0.0, 0.0, 1.42), 0.42, (900, 640))}
    views["chest"] = ((0, 3, 1.35), (0, 0, 1.35), 0.75, (700, 700))
    views["arm"] = ((3, 0.4, 1.35), (0.2, 0, 1.3), 0.7, (700, 700))
    views["arm_top"] = ((1.5, 0.6, 3.0), (0.2, 0, 1.45), 0.6, (700, 700))
    only = only or ["front", "side", "back", "three_quarter", "collar", "collar_back"]
    for name, (loc, at, scale, res) in views.items():
        if name not in only:
            continue
        cam.location = loc
        cam.rotation_euler = (Vector(at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        cam.data.ortho_scale = scale
        sc.render.resolution_x, sc.render.resolution_y = res
        sc.render.filepath = os.path.join(folder, name + ".png")
        bpy.ops.render.render(write_still=True)
        print("rendered", name)


if __name__ == "__main__":
    main()
