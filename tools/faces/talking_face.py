#!/usr/bin/env python3
"""A talking face for a Rodin portrait man: MakeHuman's face (lips that part, a mouth, teeth,
tongue, eyelids, eyes; all CC0) grafted onto the front of his painted head, with his paint, and
his expressions as blend shapes made from MakeHuman's face pose units (tools/faces/mh_units.py).

    ~/bpyenv/bin/python tools/faces/mh_units.py --fetch
    ~/bpyenv/bin/python tools/faces/talking_face.py --man=bold_cowboy_layered --out=bold_cowboy_talking
    ~/bpyenv/bin/python tools/faces/talking_face.py --man=sean_s3 --out=sean_s3_talking --landmarks=FILE.npy

→ assets/people/<out>.glb (his model, body_head replaced: his kept head, the new face, its eyes,
  teeth and tongue, one mesh with his expressions as blend shapes), <out>_head.png (his own paint
  with the new face's beside it), <out>.json (his report, `facerig` what this did).

The steps (docs/briefs/face-rig.md):
1. Landmarks: his are MediaPipe's 478 on his painted bust (assets/people/heads/<head>_mesh.npz
   `pts`), carried into the game's space by the similarity that lays the bust's vertices on his
   game head's (matched by their UVs). MakeHuman's: MediaPipe on a plain render of its base head.
2. The warp: a thin-plate spline through the landmarks takes MakeHuman's face (and its eyes,
   teeth and tongue) onto his; then its outer skin is pulled onto his surface (closest point), so
   his moustache, brows and cheeks come with it. The inside of the lips, the lid margins and
   anything far from his surface keep the warp, with the pull filled in smoothly from around them.
3. The graft: the front of his face (inside MakeHuman's face patch, in a cylinder's (angle,
   height) about his head's axis) is cut out of his head and the patch stitched to the edge.
4. The paint: each texel of the new face takes his paint from the closest point of his old head;
   the eyes from straight in front of them; mouth, teeth and tongue plain.
5. The expressions: each a sum of pose units (EXPRESSIONS), carried through the same warp (the
   offset of the warped posed face from the warped rest one), faded out toward the patch's edge.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "characters"))
from glb_io import Glb  # noqa: E402
from mh_units import MH, load_obj  # noqa: E402

PEOPLE = os.path.join(ROOT, "assets", "people")
WORK = os.path.join(ROOT, "build", "faces")

# MediaPipe's contours (its face mesh's indices).
LIPS_INNER = [78, 191, 80, 81, 82, 13, 312, 311, 310, 415, 308, 324, 318, 402, 317, 14, 87, 178, 88, 95]
LIPS_OUTER = [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146]
EYE_L = [33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7]
EYE_R = [263, 466, 388, 387, 386, 385, 384, 398, 362, 382, 381, 380, 374, 373, 390, 249]
OVAL = [10, 338, 297, 332, 284, 251, 389, 356, 454, 323, 361, 288, 397, 365, 379, 378, 400, 377, 152,
        148, 176, 149, 150, 136, 172, 58, 132, 93, 234, 127, 162, 21, 54, 103, 67, 109]


def mh_to_body(p):
    """MakeHuman (decimetres, facing +Z, his right at -X) → body space (metres, facing -Z)."""
    return np.asarray(p, float) * 0.1 * np.array([-1.0, 1.0, -1.0])


def quads_to_tris(faces):
    out = []
    for vi, ti in faces:
        for j in range(1, len(vi) - 1):
            out.append(((vi[0], vi[j], vi[j + 1]), (ti[0], ti[j], ti[j + 1])))
    return np.array([o[0] for o in out]), np.array([o[1] for o in out])


def similarity(src, dst):
    """s, R, t with dst ~ s R src + t (Umeyama)."""
    ms, md = src.mean(0), dst.mean(0)
    a, b = src - ms, dst - md
    U, S, Vt = np.linalg.svd(b.T @ a / len(src))
    d = np.sign(np.linalg.det(U @ Vt))
    D = np.diag([1, 1, d])
    R = U @ D @ Vt
    s = (S * np.diag(D)).sum() / (a ** 2).sum() * len(src)
    return s, R, md - s * R @ ms


# --- 1. Landmarks --------------------------------------------------------------------------------

def his_landmarks(head_npz, game):
    """His 478 landmarks in game space: the bust's vertices matched to the game head's by UV."""
    m = np.load(head_npz)
    V, UV, P = m["V"], m["UV"], m["pts"]
    d, k = cKDTree(game["UV"]).query(UV)
    ok = d < 0.5 / 2048
    src, dst = V[ok], game["V"][k[ok]]
    for _ in range(3):                                   # drop the worst matches, refit
        s, R, t = similarity(src, dst)
        err = np.linalg.norm(src @ R.T * s + t - dst, axis=1)
        keep = err < np.percentile(err, 80)
        src, dst = src[keep], dst[keep]
    s, R, t = similarity(src, dst)
    err = np.linalg.norm(src @ R.T * s + t - dst, axis=1)
    print("talking_face: bust → game by %d UV matches: scale %.3f, median %.1f mm" % (len(src), s, np.median(err) * 1000))
    return P @ R.T * s + t


class MHFace:
    """MakeHuman's base mesh in body space: the body's triangles, the helpers', its UVs."""

    def __init__(self):
        v, uv, groups = load_obj(os.path.join(MH, "3dobjs/base.obj"))
        self.v_mh = v
        self.v = mh_to_body(v)
        self.uv = uv
        self.groups = groups
        self.T, self.TT = {}, {}
        for g in ("body", "helper-upper-teeth", "helper-lower-teeth", "helper-tongue", "helper-l-eye", "helper-r-eye"):
            self.T[g], self.TT[g] = quads_to_tris(groups[g])

    def ids(self, g):
        return np.unique(self.T[g])


def mh_landmarks(mh, out):
    """MediaPipe's 478 landmarks on MakeHuman's plain head (cached): body-space points."""
    path = os.path.join(out, "mh_landmarks.npy")
    if os.path.exists(path):
        return np.load(path)
    import portrait as PT
    head = np.where(mh.v[:, 1] > mh.v[:, 1].max() - 0.28)[0]
    keep = np.zeros(len(mh.v), bool)
    keep[head] = True
    tris = [t for g in ("body", "helper-l-eye", "helper-r-eye") for t in mh.T[g] if keep[t].all()]
    tris = np.array(tris)
    col = np.ones((len(mh.v), 3)) * np.array([0.78, 0.6, 0.48])
    for g in ("helper-l-eye", "helper-r-eye"):
        e = mh.ids(g)
        c = mh.v[e].mean(0)
        col[e] = PT.eye_colour(mh.v, e, c)[e]
    size = 1024
    cam = PT.head_camera(mh.v[head], "front", size, fill=0.62)
    img, (tid, bary, _) = PT.render(mh.v, tris, col, cam, size, size)
    pic = PT.to_pil(img)
    os.makedirs(out, exist_ok=True)
    pic.save(os.path.join(out, "mh_landmarks_render.png"))
    lm = PT.landmarks(pic)
    PT.close_landmarker()
    if lm is None:
        raise SystemExit("talking_face: MediaPipe found no face on MakeHuman's head")
    px = np.clip(lm[:, :2].astype(int), 0, size - 1)
    hit = np.argwhere(tid >= 0)
    pts = []
    for k in range(len(px)):
        y, x = px[k, 1], px[k, 0]
        if tid[y, x] < 0:
            j = np.argmin(((hit - [y, x]) ** 2).sum(1))
            y, x = hit[j]
        t = tris[tid[y, x]]
        pts.append((mh.v[t] * bary[y, x][:, None]).sum(0))
    pts = np.array(pts)
    np.save(path, pts)
    return pts


# --- 2. The warp ---------------------------------------------------------------------------------

class TPS:
    """A 3D thin-plate spline (kernel r) from src points to dst points, lightly regularised."""

    def __init__(self, src, dst, reg=1e-5):
        n = len(src)
        K = np.linalg.norm(src[:, None] - src[None], axis=2)
        P = np.c_[np.ones(n), src]
        A = np.zeros((n + 4, n + 4))
        A[:n, :n] = K + reg * np.eye(n)
        A[:n, n:] = P
        A[n:, :n] = P.T
        b = np.zeros((n + 4, 3))
        b[:n] = dst
        self.src = src
        self.w = np.linalg.solve(A, b)

    def __call__(self, x):
        x = np.asarray(x, float)
        out = np.empty_like(x)
        for i in range(0, len(x), 4096):
            xi = x[i:i + 4096]
            K = np.linalg.norm(xi[:, None] - self.src[None], axis=2)
            out[i:i + 4096] = K @ self.w[:len(self.src)] + np.c_[np.ones(len(xi)), xi] @ self.w[len(self.src):]
        return out


class Surface:
    """Closest points on a triangle mesh, by a dense sampling (SPACING apart) of its triangles."""
    SPACING = 0.0012

    def __init__(self, V, T):
        self.V, self.T = V, T
        pts, tri, bary = [], [], []
        a, b, c = V[T[:, 0]], V[T[:, 1]], V[T[:, 2]]
        size = np.maximum(np.linalg.norm(b - a, axis=1), np.maximum(np.linalg.norm(c - b, axis=1), np.linalg.norm(a - c, axis=1)))
        for n in np.unique(np.clip(np.ceil(size / self.SPACING).astype(int), 1, 40)):
            ids = np.where(np.clip(np.ceil(size / self.SPACING).astype(int), 1, 40) == n)[0]
            i, j = np.meshgrid(np.arange(n + 1), np.arange(n + 1))
            m = (i + j) <= n
            u, v = (i[m] / n), (j[m] / n)
            w = np.stack([1 - u - v, u, v], 1)                              # (k, 3)
            P = np.einsum("kc,tcx->tkx", w, V[T[ids]])
            pts.append(P.reshape(-1, 3))
            tri.append(np.repeat(ids, len(w)))
            bary.append(np.tile(w, (len(ids), 1)))
        self.P = np.concatenate(pts)
        self.tri = np.concatenate(tri)
        self.bary = np.concatenate(bary)
        self.tree = cKDTree(self.P)
        n = np.cross(b - a, c - a)
        self.tn = n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)

    def closest(self, x):
        """Each point's closest surface point, its triangle, barycentrics and the triangle's normal."""
        d, k = self.tree.query(x)
        return self.P[k], self.tri[k], self.bary[k], self.tn[self.tri[k]], d


def vertex_normals(V, T):
    n = np.zeros_like(V)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for j in range(3):
        np.add.at(n, T[:, j], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def edges_of(T):
    e = np.sort(np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]]), 1)
    return np.unique(e, axis=0)


def laplace_fill(X, fixed, T, iters=400):
    """Values X (n, k) on a mesh: those not `fixed` replaced by the smooth (harmonic) fill between
    the fixed ones (Jacobi iterations on the edge graph)."""
    from scipy.sparse import coo_matrix
    e = edges_of(T)
    n = len(X)
    A = coo_matrix((np.ones(2 * len(e)), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])), shape=(n, n)).tocsr()
    deg = np.maximum(np.asarray(A.sum(1)).ravel(), 1)
    Y = X.copy()
    free = ~fixed
    Y[free] = 0
    for _ in range(iters):
        Y[free] = (A @ Y)[free] / deg[free, None]
    return Y


def boundary_loops(T):
    """The mesh's boundary edges chained into loops (vertex id lists), longest first."""
    e = np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]])
    key = {}
    for a, b in e:
        key[(a, b)] = key.get((a, b), 0) + 1
    nxt = {}
    for (a, b) in key:
        if (b, a) not in key:
            nxt[a] = b                                     # each boundary edge keeps its direction
    loops, seen = [], set()
    for s in list(nxt):
        if s in seen:
            continue
        loop, v = [], s
        while v not in seen and v in nxt:
            seen.add(v)
            loop.append(v)
            v = nxt[v]
        if len(loop) > 2:
            loops.append(loop)
    return sorted(loops, key=len, reverse=True)


def rings_from(seed, T, n, most):
    """Edge hops from the seed vertices (capped at `most`)."""
    e = edges_of(T)
    hop = np.full(n, most, int)
    hop[list(seed)] = 0
    for h in range(1, most):
        a = hop[e[:, 0]] == h - 1
        b = hop[e[:, 1]] == h - 1
        for x, y in ((e[a, 1], None), (e[b, 0], None)):
            hop[x[hop[x] > h]] = h
    return hop


def inside_polygon(pts, poly):
    """Even-odd test of 2D points against a closed polygon."""
    x, y = pts[:, 0], pts[:, 1]
    inside = np.zeros(len(pts), bool)
    px, py = poly[:, 0], poly[:, 1]
    j = len(poly) - 1
    for i in range(len(poly)):
        c = ((py[i] > y) != (py[j] > y)) & (x < (px[j] - px[i]) * (y - py[i]) / (py[j] - py[i] + 1e-30) + px[i])
        inside ^= c
        j = i
    return inside


# --- The whole build ----------------------------------------------------------------------------

PULL_NEAR = 0.006      # metres: skin this close to his surface is pulled onto it
PULL_OUT = 0.015       # ... and this far when his surface stands out in front of it (moustache, brows)
LIP_KEEP = 0.0025      # within this of his inner lip line the lips keep MakeHuman's own form
EYE_FADE = (0.002, 0.007)  # near his eyes the pull fades in over this (metres from the eye's outline):
                           # the lids keep MakeHuman's form about its eyeballs, or they crumple shut
OVAL_GROW = (1.10, 1.06)   # MakeHuman's patch: MediaPipe's face oval grown this much (angle, height)
ABOVE_RING = 0.010     # the patch stops this far above the bottom of his head mesh (the neck ring)
FADE_RINGS = 4         # the expressions fade to nothing over this many edges in from the patch's edge
MOVED = 0.0005         # metres: a vertex any pose unit moves this much belongs to the face


def cyl(P, axis):
    """(angle about the head's vertical axis from straight ahead, height)."""
    return np.stack([np.arctan2(P[:, 0] - axis[0], -(P[:, 2] - axis[1])), P[:, 1]], 1)


def largest_component(T, n):
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    e = edges_of(T)
    _, lab = connected_components(coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), shape=(n, n)), directed=False)
    big = np.bincount(lab[np.unique(T)]).argmax()
    return T[lab[T[:, 0]] == big]


def cap(V, T, loop):
    """Close a hole with a fan round its centre: new vertex appended."""
    c = V[loop].mean(0)
    V = np.r_[V, [c]]
    k = len(V) - 1
    fan = np.array([[loop[i], k, loop[(i + 1) % len(loop)]] for i in range(len(loop))])
    # boundary loops run with the mesh's own edges, so the fan runs against them
    return V, np.r_[T, fan], k


def zip_loops(A, B, PA, PB, centre):
    """Triangles joining two closed loops (vertex ids A and B, 2D positions PA, PB in the same
    plane about `centre`): both walked the same way round from their nearest pair, each step
    advancing on the loop whose next diagonal is shorter."""
    def walk(L, P):
        ang = np.unwrap(np.arctan2(P[:, 1] - centre[1], P[:, 0] - centre[0]))
        if ang[-1] < ang[0]:
            L, P = L[::-1], P[::-1]
        return list(L), P
    A, PA = walk(np.asarray(A), PA)
    B, PB = walk(np.asarray(B), PB)
    i0 = 0
    j0 = int(np.argmin(np.linalg.norm(PB - PA[0], axis=1)))
    B = B[j0:] + B[:j0]
    PB = np.r_[PB[j0:], PB[:j0]]
    tris, i, j = [], 0, 0
    na, nb = len(A), len(B)
    while i < na or j < nb:
        a0, a1 = A[i % na], A[(i + 1) % na]
        b0, b1 = B[j % nb], B[(j + 1) % nb]
        da = np.linalg.norm(PA[(i + 1) % na] - PB[j % nb]) if i < na else np.inf
        db = np.linalg.norm(PB[(j + 1) % nb] - PA[i % na]) if j < nb else np.inf
        if da <= db:
            tris.append([a0, a1, b0])
            i += 1
        else:
            tris.append([a0, b1, b0])
            j += 1
    return np.array(tris)


# His expressions: pose units and how much of each (MakeHuman's names; Left is his left).
EXPRESSIONS = {
    "jaw_open": {"JawDrop": 1.0},
    "aa": {"JawDrop": 0.7, "UpperLipUp": 0.35, "lowerLipDown": 0.5},
    # the lips parted without the jaw (a performance's mouthUpperUp / mouthLowerDown)
    "lips_apart": {"UpperLipUp": 0.6, "lowerLipDown": 1.0},
    "ee": {"MouthLeftPullSide": 1.1, "MouthRightPullSide": 1.1, "JawDrop": 0.2, "UpperLipUp": 0.35, "lowerLipDown": 0.45},
    "oo": {"LipsKiss": 1.35, "JawDrop": 0.25},
    "fv": {"lowerLipUp": 1.0, "lowerLipBackward": 1.7, "UpperLipUp": 0.5, "JawDrop": 0.12},
    "mbp": {"lowerLipUp": 0.5, "LipsKiss": 0.25},        # shut and pressed (stretched, they part on his teeth)
    "blink_l": {"LeftUpperLidClosed": 1.0, "LeftLowerLidUp": 0.25},
    "blink_r": {"RightUpperLidClosed": 1.0, "RightLowerLidUp": 0.25},
    "squint": {"LeftLowerLidUp": 0.8, "RightLowerLidUp": 0.8, "LeftCheekUp": 0.6, "RightCheekUp": 0.6,
               "LeftUpperLidClosed": 0.12, "RightUpperLidClosed": 0.12},
    # a real brow lifts ~10-12 mm, its inner end most (Sean, 2026-10-21: at full units, ~24 mm and
    # arched high, it read comical)
    "brows_up": {"LeftInnerBrowUp": 0.5, "RightInnerBrowUp": 0.5, "LeftOuterBrowUp": 0.35, "RightOuterBrowUp": 0.35},
    "brows_down": {"LeftBrowDown": 1.0, "RightBrowDown": 1.0},
    "scowl": {"LeftBrowDown": 1.0, "RightBrowDown": 1.0, "NoseWrinkler": 0.7, "MouthLeftPullDown": 0.6,
              "MouthRightPullDown": 0.6, "lowerLipUp": 0.3, "LeftLowerLidUp": 0.3, "RightLowerLidUp": 0.3},
    # a smile shows in his eyes too (the lower lids up): under the moustache its corners barely do
    "smile": {"MouthLeftPullUp": 1.2, "MouthRightPullUp": 1.2, "LeftCheekUp": 0.8, "RightCheekUp": 0.8,
              "LeftLowerLidUp": 0.35, "RightLowerLidUp": 0.35},
    "smile_l": {"MouthLeftPullUp": 1.4, "LeftCheekUp": 0.9, "LeftLowerLidUp": 0.35},
    "smile_r": {"MouthRightPullUp": 1.4, "RightCheekUp": 0.9, "RightLowerLidUp": 0.35},
    # his eyes turned (about 19 degrees; the lids follow up and down), Left his left
    "look_left": {"LeftEyeturnLeft": 1.0, "RightEyeturnLeft": 1.0},
    "look_right": {"LeftEyeturnRight": 1.0, "RightEyeturnRight": 1.0},
    "look_up": {"LeftEyeUp": 1.0, "RightEyeUp": 1.0},
    "look_down": {"LeftEyeDown": 1.0, "RightEyeDown": 1.0},
}
# Inside his mouth, painted dark: the game draws no shadow that small.
DARK = np.array([0.09, 0.03, 0.03])
TEETH = np.array([0.56, 0.48, 0.35])
TEETH_BEHIND = 0.004   # metres: the upper teeth's front behind his inner lip line
TEETH_SHOW = 0.0       # metres: the upper teeth's edge under it (lower and they show through "mbp")
TONGUE = np.array([0.28, 0.10, 0.09])
LID_OUT = 0.0025       # a lid's paint: his skin this far outside his eye's painted outline
TEX = 1024                                    # the new face's texture, texels a side


def bilinear(img, uv):
    h, w = img.shape[:2]
    x = np.clip(uv[:, 0] * w - 0.5, 0, w - 1.001)
    y = np.clip(uv[:, 1] * h - 0.5, 0, h - 1.001)
    x0, y0 = x.astype(int), y.astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    return (img[y0, x0] * (1 - fx) * (1 - fy) + img[y0, x0 + 1] * fx * (1 - fy)
            + img[y0 + 1, x0] * (1 - fx) * fy + img[y0 + 1, x0 + 1] * fx * fy)


def dilate(img, filled, px=8):
    """Grow each island's colours out over `px` texels of the empty ground (no seams in mips)."""
    from scipy.ndimage import distance_transform_edt
    d, (iy, ix) = distance_transform_edt(~filled, return_indices=True)
    out = img.copy()
    grow = (~filled) & (d <= px)
    out[grow] = img[iy[grow], ix[grow]]
    return out


# Strips of the face's texture for the teeth and tongue: (u0, v0, u1, v1).
STRIPS = {"helper-upper-teeth": (0.78, 0.46, 0.98, 0.54), "helper-lower-teeth": (0.78, 0.56, 0.98, 0.64),
          "helper-tongue": (0.78, 0.66, 0.98, 0.80)}
GUM = np.array([0.42, 0.17, 0.15])


def mouth_uv(P, gname):
    """Teeth: across the strip their way round the arch, down it from the biting edge to the gum.
    The tongue: across it side to side, down it front to back."""
    u0, v0, u1, v1 = STRIPS[gname]
    c = P.mean(0)
    if gname == "helper-tongue":
        s = (P[:, 0] - P[:, 0].min()) / np.ptp(P[:, 0])
        h = (P[:, 2] - P[:, 2].min()) / np.ptp(P[:, 2])
    else:
        back = P[:, 2].max()
        a = np.arctan2(P[:, 0] - c[0], -(P[:, 2] - back) + 1e-6)
        s = np.clip(a / np.pi + 0.5, 0, 1)
        y = (P[:, 1] - P[:, 1].min()) / np.ptp(P[:, 1])
        h = 1 - y if "upper" in gname else y                         # 0 at the biting edge
    return np.c_[u0 + (u1 - u0) * (0.04 + 0.92 * s), v0 + (v1 - v0) * (0.04 + 0.92 * h)]


def paint_mouth(img, filled):
    """The teeth and tongue's strips painted by rule: the teeth lighter at the biting edge, a gum
    along the root, a dark line between each front tooth, darker round the arch (further in); the
    tongue darker toward the throat with a groove down its middle. Plain: they're a pixel or two
    in the game, more only in close conversation."""
    for gname, (u0, v0, u1, v1) in STRIPS.items():
        x0, y0, x1, y1 = int(u0 * TEX), int(v0 * TEX), int(u1 * TEX), int(v1 * TEX)
        s, h = np.meshgrid(np.linspace(-0.04, 1.04, x1 - x0) , np.linspace(-0.04, 1.04, y1 - y0))
        s, h = np.clip(s, 0, 1), np.clip(h, 0, 1)
        if gname == "helper-tongue":
            col = TONGUE[None, None] * (1 - 0.65 * h)[..., None]
            col *= (1 - 0.35 * np.exp(-((s - 0.5) / 0.04) ** 2))[..., None]
        else:
            side = np.abs(s - 0.5) * 2                                  # 0 at the front, 1 round the back
            col = TEETH[None, None] * (1 - 0.55 * side)[..., None]
            col = col * (1 + 0.12 * (h < 0.15))[..., None]
            gum = np.clip((h - 0.72) / 0.12, 0, 1)[..., None]
            col = col * (1 - gum) + GUM * (1 - 0.5 * side)[..., None] * gum
            front = side < 0.55
            gap = (np.abs(((s - 0.5) * 16 + 0.5) % 1 - 0.5) < 0.06) & front & (h < 0.8)
            col[gap] *= 0.7
        img[y0:y1, x0:x1] = np.clip(col, 0, 1)
        filled[y0:y1, x0:x1] = True


# The blinks' movement smoothed over the lids (passes): MakeHuman's lid shut on his warped face
# closes along a wavy line, a fold across the lid.
SMOOTH_SHAPES = {"blink_l": 4, "blink_r": 4, "squint": 2}
SMOOTH_NEAR = 0.012    # metres from his eye's outline
SMOOTH_EDGE = 0.0025


def smooth_near(D, V, T, ring, skin, passes):
    """Offsets D averaged with their neighbours' (half and half, `passes` times) on the skin within
    SMOOTH_NEAR of the points `ring`."""
    from scipy.sparse import coo_matrix
    e = edges_of(T)
    n = len(V)
    A = coo_matrix((np.ones(2 * len(e)), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])), shape=(n, n)).tocsr()
    deg = np.maximum(np.asarray(A.sum(1)).ravel(), 1)[:, None]
    near = cKDTree(ring).query(V)[0]
    zone = skin & (near < SMOOTH_NEAR) & (near > SMOOTH_EDGE)      # the lid's own edge keeps its way shut
    for _ in range(passes):
        avg = (A @ D) / deg
        D = np.where(zone[:, None], 0.5 * D + 0.5 * avg, D)
    return D


def build(man, out, head, report_only=False, landmarks=None):
    import portrait as PT
    os.makedirs(WORK, exist_ok=True)
    g = Glb(os.path.join(PEOPLE, man + ".glb"))
    game = g.mesh("body_head")
    hj = g.joint_names().index("head")
    # A whole man from the Character Studio has no portrait bust: his 478 landmarks come found on
    # his own mesh, in game space (`--landmarks=`, the Studio's headshape.landmarks_3d).
    his = np.load(landmarks) if landmarks else his_landmarks(os.path.join(PEOPLE, "heads", head + "_mesh.npz"), game)
    mh = MHFace()
    ml = mh_landmarks(mh, WORK)
    W = TPS(ml, his)
    U = np.load(os.path.join(WORK, "mh_units.npz"))
    names = [str(n) for n in U["names"]]
    rep = {"from": man, "head": head, "makehuman_units": len(names)}

    # The patch: MakeHuman's face (the oval grown, and all its skin the pose units move).
    head_v = mh.v[:, 1] > mh.v[:, 1].max() - 0.3
    hv = np.where(head_v)[0]
    X = np.zeros_like(mh.v)
    X[hv] = W(mh.v[hv])
    moved = np.zeros(len(mh.v))
    for n in names:
        if "Platysma" not in n and "Tongue" not in n:
            moved = np.maximum(moved, np.linalg.norm(U["u_" + n], axis=1) * 0.1)
    axis_mh = (0.0, mh.v[hv, 2].mean())
    oval = cyl(ml[OVAL], axis_mh)
    c = oval.mean(0)
    in_oval = inside_polygon(cyl(mh.v, axis_mh), c + (oval - c) * np.array(OVAL_GROW))
    wide = np.abs(cyl(mh.v, axis_mh)[:, 0]) < np.abs(oval[:, 0]).max() + 0.1
    ring_y = game["V"][:, 1].min()
    sel = head_v & (in_oval | ((moved > MOVED) & wide)) & (X[:, 1] > ring_y + ABOVE_RING)
    Tb, TTb = mh.T["body"], mh.TT["body"]
    keep = sel[Tb].all(1)
    Tp = largest_component(Tb[keep], len(mh.v))
    TTp = TTb[keep][np.isin(np.arange(keep.sum()), np.where(np.isin(Tb[keep], Tp).all(1))[0])]
    # (largest_component keeps the rows in order; match the UV rows to them)
    rows = {tuple(t): k for k, t in enumerate(Tb[keep])}
    TTp = TTb[keep][[rows[tuple(t)] for t in Tp]]
    pv = np.unique(Tp)

    # The pull onto his surface.
    S = Surface(game["V"], game["T"])
    q, _, _, tn, d = S.closest(X[pv])
    nm = vertex_normals(X, Tp)[pv]
    off = np.zeros_like(X)
    off[pv] = q - X[pv]
    outward = ((q - X[pv]) * nm).sum(1) > 0
    dl = cKDTree(his[LIPS_INNER]).query(X[pv])[0]
    de = cKDTree(np.r_[his[EYE_L], his[EYE_R]]).query(X[pv])[0]
    agree = (nm * tn).sum(1) > 0.5
    ok = agree & (dl > LIP_KEEP) & ((d < PULL_NEAR) | (outward & (d < PULL_OUT)))
    for ring in (EYE_L, EYE_R):
        dd = cKDTree(his[ring]).query(X[pv])[0]
        band = (dd > 0.003) & (dd < 0.009) & agree
        print("talking_face: eye ring pull median %.1f mm (n=%d), along normal %.1f mm" % (
            np.median(np.linalg.norm((q - X[pv])[band], axis=1)) * 1000, band.sum(),
            np.median(((q - X[pv]) * nm).sum(1)[band]) * 1000))
    fe = np.clip((de - EYE_FADE[0]) / (EYE_FADE[1] - EYE_FADE[0]), 0, 1)
    off[pv] *= (fe * fe * (3 - 2 * fe))[:, None]
    ok |= de < EYE_FADE[1]
    fixed = np.ones(len(X), bool)
    fixed[pv] = ok
    off = laplace_fill(off, fixed, Tp)
    Xr = X + off                                     # the patch at rest on his head
    inside = np.zeros(len(X))                        # how far into his head (mouth, lid backs)
    inside[pv] = np.clip(np.linalg.norm(S.closest(Xr[pv])[0] - Xr[pv], axis=1) / 0.005, 0, 1)
    rep["patch"] = {"triangles": int(len(Tp)), "vertices": int(len(pv)), "pulled": int(ok.sum()),
                    "pull_mm_median": round(float(np.median(d[ok]) * 1000), 2)}
    print("talking_face: patch %d triangles, %d of %d vertices pulled onto his skin" % (len(Tp), ok.sum(), len(pv)))

    # His head's axis and the patch's outline on it.
    up = game["V"][:, 1] > his[1][1]
    axis = (float(game["V"][up, 0].mean()), float(game["V"][up, 2].mean()))
    R = float(np.abs(game["V"][up, 0]).max())
    loops = boundary_loops(Tp)
    flat = lambda P: cyl(P, axis) * np.array([R, 1.0])
    ext = [np.ptp(flat(Xr[l]), axis=0).prod() for l in loops]
    outer = loops[int(np.argmax(ext))]
    holes = [l for l in loops if l is not outer]
    poly = flat(Xr[outer])
    # Cut his face out: every triangle whose centre is inside the outline, in front of the axis.
    # (His mesh is split at its UV seams: its topology is read on the vertices welded by position.)
    Vh, Th = game["V"], game["T"]
    _, weld = np.unique(np.round(Vh / 1e-6).astype(np.int64), axis=0, return_inverse=True)
    weld = weld.ravel()
    Thw = weld[Th]
    cen = Vh[Th].mean(1)
    cut = inside_polygon(flat(cen), poly) & (cen[:, 2] < axis[1])
    keep_rows = np.where(~cut)[0]
    Tkw = largest_component(Thw[keep_rows], weld.max() + 1)
    rows = {tuple(t): r for t, r in zip(Thw[keep_rows], keep_rows)}
    kept = np.array([rows[tuple(t)] for t in Tkw])
    Tk = Th[kept]
    first = np.zeros(weld.max() + 1, int)
    first[weld] = np.arange(len(weld))                       # a welded vertex's position
    hl = boundary_loops(Tkw)
    pc = poly.mean(0)
    hole = min(hl, key=lambda l: np.linalg.norm(flat(Vh[first[l]]).mean(0) - pc))
    hole_P = Vh[first[hole]]
    rep["cut"] = {"his_triangles_removed": int(len(Th) - len(Tk)), "his_edge": len(hole), "patch_edge": len(outer)}
    print("talking_face: his face cut out (%d triangles), edges %d and %d zipped" % (len(Th) - len(Tk), len(hole), len(outer)))

    # body_head: his kept head, and a strip from his cut edge to the patch's edge. The strip's
    # corners are its own vertices, each triangle's UVs from the kept triangle nearest it (one UV
    # island, so no smear across his texture's seams).
    edge_P = Xr[outer]
    na = len(hole)
    PP = np.r_[hole_P, edge_P]
    strip = zip_loops(np.arange(na), np.arange(na, na + len(outer)), flat(hole_P), flat(edge_P), pc)
    sc = PP[strip].mean(1)
    kc = Vh[Tk].mean(1)
    near = Tk[cKDTree(kc).query(sc)[1]]
    a, b, c3 = Vh[near[:, 0]], Vh[near[:, 1]], Vh[near[:, 2]]
    SV, SUV = [], []
    for j in range(3):
        p = PP[strip[:, j]]
        v0, v1, v2 = b - a, c3 - a, p - a
        d00, d01, d11 = (v0 * v0).sum(1), (v0 * v1).sum(1), (v1 * v1).sum(1)
        d20, d21 = (v2 * v0).sum(1), (v2 * v1).sum(1)
        den = np.maximum(d00 * d11 - d01 * d01, 1e-18)
        bv = (d11 * d20 - d01 * d21) / den
        bw = (d00 * d21 - d01 * d20) / den
        uvs = game["UV"][near]
        SUV.append(uvs[:, 0] * (1 - bv - bw)[:, None] + uvs[:, 1] * bv[:, None] + uvs[:, 2] * bw[:, None])
        SV.append(p)
    nh = len(Vh)
    ns = len(strip)
    ST = nh + np.arange(3 * ns).reshape(3, ns).T
    VH = np.r_[Vh, np.concatenate(SV)]
    UVH = np.r_[game["UV"], np.concatenate(SUV)]
    sn = np.cross(VH[ST[:, 1]] - VH[ST[:, 0]], VH[ST[:, 2]] - VH[ST[:, 0]])
    # Each strip triangle faces out from his head's centre (his eyes' height on its axis), one by
    # one: over his crown and under his chin a sideways test flips some inward (holes, on a coarse
    # whole man's head; Sean's, 2026-10-21).
    centre3 = np.array([axis[0], his[[468, 473], 1].mean(), axis[1]])
    out_dir = VH[ST].mean(1) - centre3
    flip = np.einsum("ij,ij->i", sn, out_dir) < 0
    ST[flip] = ST[flip][:, ::-1]
    TH = np.r_[Tk, ST]
    used = np.unique(TH)
    remap = -np.ones(len(VH), int)
    remap[used] = np.arange(len(used))
    JH = np.r_[game["J"], np.tile([hj, 0, 0, 0], (3 * ns, 1))][used]
    WH = np.r_[game["W"], np.tile([1, 0, 0, 0], (3 * ns, 1))][used]
    VH, UVH, TH = VH[used], UVH[used], remap[TH]
    # his normals for his own vertices (smooth across his seams); the strip's from its own shape
    NH = vertex_normals(VH, TH)
    NHw = np.zeros((weld.max() + 1, 3))
    nfull = vertex_normals(Vh, Th)
    np.add.at(NHw, weld, nfull)
    own = used < nh
    NH[own] = NHw[weld[used[own]]]
    NH /= np.maximum(np.linalg.norm(NH, axis=1, keepdims=True), 1e-12)

    # body_facerig: the patch (split at its UV seams), the caps, eyes, teeth, tongue.
    pairs = {}
    TF, src = [], []
    for t, tt in zip(Tp, TTp):
        row = []
        for a, b in zip(t, tt):
            k = pairs.setdefault((a, b), len(pairs))
            if k == len(src):
                src.append((a, b))
            row.append(k)
        TF.append(row)
    TF = np.array(TF)
    smv = np.array([s[0] for s in src])                     # each face vertex's MakeHuman vertex
    suv = mh.uv[[s[1] for s in src]]
    lo, hi = suv.min(0), suv.max(0)
    scale = 0.74 / (hi - lo).max()
    UVF = (suv - lo) * scale + 0.01
    UVF[:, 1] = 1.0 - UVF[:, 1]                             # glTF's UVs run down
    kind = np.zeros(len(smv), int)                          # 0 skin, 1 eye, 2 teeth, 3 tongue, 4 dark
    VF = Xr[smv].copy()
    # the throat's holes capped, dark
    capped = []
    for l in holes:
        fl = [pairs[(a, b)] for a in l for (aa, b) in [next(k for k in pairs if k[0] == a)] if True]
        VF, TF, kc = cap(VF, TF, fl)
        smv = np.r_[smv, -1]
        UVF = np.r_[UVF, [[0.9, 0.95]]]
        kind = np.r_[kind, 4]
        capped.append((kc, fl))
    rep["holes_capped"] = len(holes)
    parts = [("helper-l-eye", 1), ("helper-r-eye", 1), ("helper-upper-teeth", 2), ("helper-lower-teeth", 2),
             ("helper-tongue", 3)]
    # The right-hand column of the face's texture: each eye a disc (polar about its forward axis,
    # the front half inside, the back the outer ring: every point its own texel, so the eye can
    # turn), the teeth and tongue each a strip painted by rule (paint_mouth).
    eye_box = {"helper-l-eye": (0.78, 0.02), "helper-r-eye": (0.78, 0.24)}
    centres = {}
    span = {}                                               # each part's vertices in VF
    for gname, k in parts:
        ids = mh.ids(gname)
        base = len(VF)
        m = -np.ones(len(mh.v), int)
        m[ids] = np.arange(len(ids)) + base
        P = W(mh.v[ids])
        span[gname] = np.arange(base, base + len(ids))
        VF = np.r_[VF, P]
        TF = np.r_[TF, m[mh.T[gname]]]
        smv = np.r_[smv, ids]
        kind = np.r_[kind, np.full(len(ids), k)]
        if k == 1:
            ex, ey = eye_box[gname]
            c = P.mean(0)
            centres[gname] = (c, (ex, ey))
            d = (P - c) / np.linalg.norm(P - c, axis=1, keepdims=True)
            th = np.arccos(np.clip(-d[:, 2], -1, 1)) / np.pi           # 0 straight ahead, 1 behind
            ph = np.arctan2(d[:, 1], -d[:, 0])
            UVF = np.r_[UVF, np.c_[ex + 0.1 + 0.098 * th * np.cos(ph), ey + 0.1 - 0.098 * th * np.sin(ph)]]
        else:
            UVF = np.r_[UVF, mouth_uv(P, gname)]
    # MakeHuman's teeth land ahead of his lips (his lips sit back behind his moustache): the teeth
    # and tongue go back until the upper teeth are TEETH_BEHIND behind his inner lip line.
    mouth = (kind == 2) | (kind == 3)
    upper = span["helper-upper-teeth"]
    back = max(0.0, float(his[13][2] + TEETH_BEHIND - VF[upper][:, 2].min()))
    VF[mouth, 2] += back
    # ... and down, the upper teeth's edge TEETH_SHOW under his lip line (hidden while his lips
    # meet; there to see when they part, as a man's are)
    drop = max(0.0, float(VF[upper][:, 1].min() - (his[13][1] - TEETH_SHOW)))
    VF[mouth, 1] -= drop
    rep["teeth_back_mm"] = round(back * 1000, 1)
    rep["teeth_down_mm"] = round(drop * 1000, 1)
    # His eyes' centres (body space, at rest): where FaceGaze looks from.
    rep["eye_centres"] = {g: np.round(VF[span[g]].mean(0), 4).tolist() for g in ("helper-l-eye", "helper-r-eye")}
    rep["eye_centre"] = np.round(np.mean([VF[span[g]].mean(0) for g in ("helper-l-eye", "helper-r-eye")], 0), 4).tolist()
    NF = vertex_normals(VF, TF)
    rep["facerig"] = {"vertices": int(len(VF)), "triangles": int(len(TF))}

    # The paint.
    tex = np.asarray(Image.open(os.path.join(PEOPLE, man + "_head.png")).convert("RGB"), float) / 255
    img = np.zeros((TEX, TEX, 3))
    filled = np.zeros((TEX, TEX), bool)
    skin = (kind == 0) | (kind == 1) | (kind == 4)
    Tsk = TF[skin[TF].all(1)]
    tid, bary, _ = PT.rasterise(UVF * TEX, np.zeros(len(UVF)), Tsk, TEX, TEX)
    hit = tid >= 0
    tt = Tsk[tid[hit]]
    b = bary[hit]
    P3 = (VF[tt] * b[:, :, None]).sum(1)
    ins = (np.r_[inside[smv[smv >= 0]] if False else np.where(smv >= 0, inside[np.maximum(smv, 0)], 1.0)][tt] * b).sum(1)
    ins[(kind[tt] == 1).all(1)] = 0
    ins[(kind[tt] == 4).any(1)] = 1
    cq, ct, cb, _, _ = S.closest(P3)
    # Skin whose closest point falls in his painted eye (a lid over it) is painted from just outside.
    lid = (kind[tt] == 0).all(1)
    for ring in (EYE_L, EYE_R):
        cont = his[ring]
        mid = cont.mean(0)
        inn = lid & inside_polygon(cq[:, :2], cont[:, :2])
        if inn.any():
            k = cKDTree(cont[:, :2]).query(cq[inn, :2])[1]
            away = cont[k] - mid
            away /= np.maximum(np.linalg.norm(away, axis=1, keepdims=True), 1e-9)
            _, t2, b2, _, _ = S.closest(cont[k] + away * LID_OUT)
            ct[inn], cb[inn] = t2, b2
    col = bilinear(tex, (game["UV"][Th[ct]] * cb[:, :, None]).sum(1))
    # An eye: his painted eye where it lies in his eye's outline and faces forward; past it white,
    # greying round the back (it shows when he looks aside).
    ball = (kind[tt] == 1).all(1)
    for gname in ("helper-l-eye", "helper-r-eye"):
        c, _ = centres[gname]
        ring = min((EYE_L, EYE_R), key=lambda r: np.linalg.norm(his[r].mean(0)[:2] - c[:2]))
        mine = ball & (np.linalg.norm(P3 - c, axis=1) < 0.03)
        if not mine.any():
            continue
        d = P3[mine] - c
        d /= np.linalg.norm(d, axis=1, keepdims=True)
        seen = inside_polygon(P3[mine, :2], his[ring][:, :2]) & (-d[:, 2] > 0.5)
        inn = inside_polygon(S.P[:, :2], his[ring][:, :2]) & (S.P[:, 2] < c[2])
        pc = bilinear(tex, (game["UV"][Th[S.tri[inn]]] * S.bary[inn][:, :, None]).sum(1))
        # (his whites are painted warm, as the rest of him: the brightest of his paint there)
        white = pc[pc.mean(1) >= np.percentile(pc.mean(1), 95)].mean(0) if len(pc) > 20 else np.array([0.72, 0.56, 0.45])
        fwd = np.clip(-d[:, 2], 0, 1)[:, None]
        plain = white * (0.45 + 0.55 * fwd)
        sub = col[mine]
        sub[~seen] = plain[~seen]
        col[mine] = sub
        rep.setdefault("eye_white", {})[gname] = np.round(white, 3).tolist()
    w = np.clip((ins - 0.15) / 0.6, 0, 1)[:, None]
    img[hit] = col * (1 - w) + DARK * w
    filled |= hit
    paint_mouth(img, filled)
    y0, x0 = int(0.95 * TEX) - 12, int(0.9 * TEX) - 12
    img[y0:y0 + 24, x0:x0 + 24] = DARK
    filled[y0:y0 + 24, x0:x0 + 24] = True
    img = dilate(img, filled)
    face_png = os.path.join(WORK, out + "_facerig.png")
    Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(face_png)
    # The game's head texture: his own on the left, the new face's to its right (one material).
    his_img = Image.open(os.path.join(PEOPLE, man + "_head.png")).convert("RGB")
    hw, hh = his_img.size
    both = Image.new("RGB", (hw + TEX, hh), tuple(int(x * 255) for x in DARK))
    both.paste(his_img, (0, 0))
    both.paste(Image.open(face_png), (hw, 0))
    both.save(os.path.join(PEOPLE, out + "_head.png"))

    # The expressions: the warped posed face less the warped rest face, faded at the patch's edge.
    hop = rings_from([pairs[(a, b)] for (a, b) in pairs if a in set(outer)], TF, len(VF), FADE_RINGS + 1)
    fade = np.clip(hop / FADE_RINGS, 0, 1)
    fade = fade * fade * (3 - 2 * fade)
    fade[kind > 0] = 1
    real = smv >= 0
    rest_w = np.zeros_like(VF)
    rest_w[real] = W(mh.v[smv[real]])
    shapes = {}
    for e, mix in EXPRESSIONS.items():
        dmh = sum(U["u_" + u].astype(float) * w for u, w in mix.items())
        D = np.zeros_like(VF)
        D[real] = (W(mh_to_body(mh.v_mh[smv[real]] + dmh[smv[real]])) - rest_w[real]) * fade[real, None]
        for kc, fl in capped:
            D[kc] = D[fl].mean(0)
        if e in SMOOTH_SHAPES:
            D = smooth_near(D, VF, TF, np.r_[his[EYE_L], his[EYE_R]], kind == 0, SMOOTH_SHAPES[e])
        shapes[e] = D
        print("talking_face: %-10s moves %.1f mm at most" % (e, np.linalg.norm(D, axis=1).max() * 1000))
    rep["expressions"] = {e: {"units": mix, "max_mm": round(float(np.linalg.norm(shapes[e], axis=1).max() * 1000), 1)}
                          for e, mix in EXPRESSIONS.items()}

    # One head mesh: his kept head and the strip, then the new face; the UVs into the joined texture.
    su = hw / (hw + TEX)
    UV_all = np.r_[UVH * [su, 1.0], np.c_[su + UVF[:, 0] * (1 - su), UVF[:, 1] * TEX / hh]]
    V_all = np.r_[VH, VF]
    T_all = np.r_[TH, TF + len(VH)]
    N_all = np.r_[NH, NF]
    J_all = np.r_[JH, np.tile([hj, 0, 0, 0], (len(VF), 1))]
    W_all = np.r_[WH, np.tile([1.0, 0, 0, 0], (len(VF), 1))]
    shapes_all = {k: np.r_[np.zeros_like(VH), d] for k, d in shapes.items()}
    g.set_mesh("body_head", V_all, N_all, UV_all, J_all, W_all, T_all, shapes=shapes_all)
    g.save(os.path.join(PEOPLE, out + ".glb"))
    info = json.load(open(os.path.join(PEOPLE, man + ".json")))
    info["id"] = out
    info["textures_from"] = man               # his skin and clothes: the man he was copied from
    info["facerig"] = rep
    json.dump(info, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    np.savez_compressed(os.path.join(WORK, out + "_facerig.npz"), V=V_all, T=T_all, UV=UV_all,
                        kind=np.r_[np.full(len(VH), -1), kind], **{"s_" + k: v for k, v in shapes_all.items()})
    print("talking_face: wrote", out)


if __name__ == "__main__":
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.get("--man", "bold_cowboy_layered")
    info = json.load(open(os.path.join(PEOPLE, man + ".json")))
    build(man, a.get("--out", "bold_cowboy_talking"), a.get("--head", info.get("neck_ring", {}).get("head")),
          landmarks=a.get("--landmarks"))
