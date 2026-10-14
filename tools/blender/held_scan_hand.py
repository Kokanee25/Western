"""Your right hand round the modelled revolver, from a scan of a real hand: the Smithsonian's 3D
scan of Leonard Volk's 1860 cast of Abraham Lincoln's right hand closed round a sawn-off broom
handle (National Portrait Gallery S/NPG.71.6, CC0; fetched by tools/held/fetch_scan.py).

Run after held_revolver.py:  ~/bpyenv/bin/python tools/blender/held_scan_hand.py [--preview=DIR]
Writes assets/held/hand.glb as held_hand.py does (the hand, `Hand`, with shapes `trigger` and
`thumb`; the shirt's cuff, the coat's sleeve and a button), and the scan's own surface detail as
assets/held/hand_normal.png (tangent-space normals) and hand_cavity.png (its occlusion and the
cast's shading in the creases).

How: the cast's fist is a hand round a 25 mm cylinder, so the fit works in the handle's own
coordinates (t along it, the index finger's end +; theta round it from the wrist; r out from it).
The handle's two stubs are cut off (their holes are where the grip passes through). The index
finger, the thumb and the middle finger are found (grown over the scan from seeds on each, the
borders falling in the creases) and the index cut free of its neighbours. The index finger and the
thumb lay on the handle and on each other, so the cast has only their backs: each is rebuilt past
its root as a closed digit, a smooth ellipse a section that follows the scan's own surface where
it has it (keeping its texture there), and the middle finger's side closed where the index lay.
The fist is set on the grip (the handle's axis on the grip's centre line, the wrist behind it)
and each ring of it swells out to the grip's oval (bigger than a broom handle). The index opens
onto the trigger by turning its three joints about axes along the handle and swinging at its
knuckle; the `trigger` shape closes it on the trigger pulled back. The thumb's `thumb` shape
swings it up onto the hammer's spur at its root (the ball of the thumb carried with it) and bends
its knuckle and tip joint, searched as the index is.
"""

import math
import os
import sys

import bpy  # noqa: I001 (bpy before bmesh and mathutils)
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.dirname(__file__))
import held_hand  # noqa: E402  (the gun to touch, the cloth, the export's helpers)

OUT = "assets/held"
SCAN = os.path.join(OUT, "scan", "npg_71_6_right-hires_unwrapped-150k-4096-high.glb")

# The broom handle in the scan's own space (mm): a point on its axis, the axis toward the index
# finger's end, its radius, and the centre of the cast's wrist cut (which way the wrist is).
# Found by a Hough search for cylinders over the scan's points and normals (the stubs agree to
# 0.2 mm); `--find-handle` runs it again.
HANDLE_AT = (35.287, 722.176, 137.640)
HANDLE_DIR = (0.80400, 0.24410, 0.54222)
HANDLE_R = 12.5
WRIST_CUT = (-50.0, 743.7, 178.1)
WRIST_NORMAL = (-0.81, 0.58, 0.08)    # the cut's face, out of the hand
CUFF_OVER = 0.012                     # m: the cuff starts this far over the cast's end
HAND_FROM, HAND_TO = -31.5, 51.5      # where the hand is along the handle (mm); beyond, the stubs

# Where the grip is (the gun's space, m): its centre line, up toward the frame.
GRIP_AT = (0.0, -0.05, 0.0226)
GRIP_UP = (0.0, 0.972, -0.236)
# Where the hand goes on it: the handle's t (mm) that lands on GRIP_AT, the wrist's direction from
# the grip (made square to it), and how the fist turns about the grip from there (degrees).
PLACE = {"t": -5.0, "wrist": (0.22, 0.0, 1.0), "roll": 0.0, "scale": 1.0}
GRIP_CLEAR = 0.6                      # mm the flesh against the grip stands off it
KEEP = 0.45                           # of the scan's triangles (the rest is in its normal map)
SEARCH_T = (-1.0,)                   # the handle's t on GRIP_AT and the fist's turn: searched over these
SEARCH_ROLL = (5.0,)
THUMB_REACH = 0.0                     # the placement's score per degree the thumb swings up to cock

# Seeds for growing the index finger, the thumb and the middle finger over the scan (t mm, theta
# degrees, and whether to find the surface from outside or from the handle outward).
SEEDS = {
    "index": [(45, 140, "out"), (35, 170, "out"), (27, 270, "in"), (40, 115, "out")],
    "thumb": [(45, 270, "in"), (50, 300, "out"), (48, 230, "out")],
    "middle": [(10, 270, "in"), (15, 170, "out"), (18, 130, "out")],
    "hand": [(10, 40, "out"), (30, 60, "out"), (-10, 20, "out"), (0, 330, "out"), (45, 340, "out"),
             (50, 70, "out")],
}
CREASE = 6.0                          # how much more a step costs where the surface folds in
KNUCKLE_THETA = 105.0
JOIN = 125.0                          # theta past which the index finger is rebuilt (digit_tube)
# The thumb runs the other way round the handle: from its root (theta ~320) to its tip (~200).
# Measured as how far round from THUMB_REF, back from it: its joints there, its rebuild past
# THUMB_JOIN, and how far each joint may turn to bring its pad onto the hammer's spur.
FOLLOW = 3.0                          # mm the rebuilt digits follow the scan's own surface
THUMB_REF = 360.0
THUMB_JOIN = 50.0
THUMB_JOINTS = {"root": 45.0, "mcp": 72.0, "ip": 118.0}
# The thumb at rest (thumb_rest): its joints searched over these (degrees), its pad on the frame
# within THUMB_TOUCH (m).
THUMB_REST = {"swing": (40, 50), "root": (-40, 40), "mcp": (-40, 40), "ip": (-40, 40)}
THUMB_TOUCH = 0.004
# The rebuilt thumb's form (shape_digit): its knuckle and tip joint standing up on the back, the
# creases under them, a flatter pad side, a full pad and a rounded end.
THUMB_FORM = {"joints": (72.0, 118.0), "flat": 0.18, "knuckle": 0.7, "crease": 0.5, "pad": 0.8,
              "tip": 0.55, "tip_up": 0.25}
THUMB_OPEN = {"swing": (0, 140), "root": (-50, 50), "mcp": (0, 60), "ip": (0, 70)}
THUMB_BASE = 32.0                     # mm round the thumb's root that its swing carries (fading)                 # the index finger leaves the hand here (theta): no cut before it

# The index finger's joints (theta, degrees round the handle) and how far each opens out of the
# fist to the trigger: searched, these are the ranges.
JOINTS = {"mcp": 100.0, "pip": 182.0, "dip": 240.0}
OPEN = {"mcp": (-30, 60), "pip": (-40, 80), "dip": (-30, 50), "abd": (-30, 30)}
# (abd: the whole finger swung at its knuckle along the handle, toward the middle finger (-) or
# away, as a finger spreads.)
TRIGGER = (0.0, -0.0165, -0.0225)     # the trigger's face (the gun's space, m)
SQUEEZED = (0.0, -0.0175, -0.0175)
COCKING = (0.0, 0.066, 0.027)         # the hammer's spur


def unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def rot(axis, deg):
    a = unit(axis)
    th = math.radians(deg)
    K = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + math.sin(th) * K + (1 - math.cos(th)) * K @ K


class Scan:
    """The cast's surface as arrays (mm, the scan's space), with its handle frame."""

    def __init__(self):
        bpy.ops.import_scene.gltf(filepath=SCAN)
        ob = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
        me = ob.data
        M = np.array(ob.matrix_world)
        n = len(me.vertices)
        v = np.zeros(n * 3)
        me.vertices.foreach_get("co", v)
        self.v = v.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
        me.calc_loop_triangles()
        tris = np.zeros(len(me.loop_triangles) * 3, int)
        me.loop_triangles.foreach_get("vertices", tris)
        self.f = tris.reshape(-1, 3)
        loops = np.zeros(len(me.loop_triangles) * 3, int)
        me.loop_triangles.foreach_get("loops", loops)
        uv = np.zeros(len(me.loops) * 2)
        me.uv_layers[0].data.foreach_get("uv", uv)
        self.uv = uv.reshape(-1, 2)[loops].reshape(-1, 3, 2)       # per triangle corner
        # The file splits the surface along its texture's seams: weld it back into one (the
        # texture coordinates stay per corner).
        _, first, inv = np.unique(np.round(self.v, 4), axis=0, return_index=True, return_inverse=True)
        self.v = self.v[first]
        self.f = inv.ravel()[self.f]
        print("  scan: %d vertices welded to %d, %d triangles" % (n, len(self.v), len(self.f)))
        self.images = {}
        for node in me.materials[0].node_tree.nodes:
            if node.type == "TEX_IMAGE":
                to = node.outputs[0].links[0].to_node
                kind = {"BSDF_PRINCIPLED": "colour", "NORMAL_MAP": "normal"}.get(to.type, "occlusion")
                self.images[kind] = node.image
        bpy.data.objects.remove(ob)
        self.q = np.array(HANDLE_AT)
        self.d = unit(HANDLE_DIR)
        u = np.array(WRIST_CUT) - self.q
        self.u = unit(u - self.d * (u @ self.d))
        self.w = np.cross(self.d, self.u)

    def decimate(self, ratio, masks):
        """Fewer triangles where the surface is flat (Blender's collapse; its texture keeps the
        fine detail as normals). `masks` (name: vertex mask) come through it."""
        me = bpy.data.meshes.new("dec")
        me.from_pydata(self.v.tolist(), [], self.f.tolist())
        uvl = me.uv_layers.new(name="UVMap")
        uvl.data.foreach_set("uv", self.uv.reshape(-1))
        for k, m in masks.items():
            a = me.attributes.new("m_" + k, "FLOAT", "POINT")
            a.data.foreach_set("value", m.astype(np.float32))
        ob = bpy.data.objects.new("dec", me)
        bpy.context.scene.collection.objects.link(ob)
        m = ob.modifiers.new("dec", "DECIMATE")
        m.ratio = ratio
        m.use_collapse_triangulate = True
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        bpy.data.objects.remove(ob)
        me2.calc_loop_triangles()
        v = np.zeros(len(me2.vertices) * 3)
        me2.vertices.foreach_get("co", v)
        tris = np.zeros(len(me2.loop_triangles) * 3, int)
        me2.loop_triangles.foreach_get("vertices", tris)
        loops = np.zeros(len(me2.loop_triangles) * 3, int)
        me2.loop_triangles.foreach_get("loops", loops)
        uv = np.zeros(len(me2.loops) * 2)
        me2.uv_layers[0].data.foreach_get("uv", uv)
        out = {}
        for k in masks:
            a = np.zeros(len(me2.vertices), np.float32)
            me2.attributes["m_" + k].data.foreach_get("value", a)
            out[k] = a > 0.5
        self.v = v.reshape(-1, 3)
        self.f = tris.reshape(-1, 3)
        self.uv = uv.reshape(-1, 2)[loops].reshape(-1, 3, 2)
        print("  decimated to %d vertices, %d triangles" % (len(self.v), len(self.f)))
        return out

    def cyl(self, p):
        rel = np.asarray(p) - self.q
        t = rel @ self.d
        th = np.degrees(np.arctan2(rel @ self.w, rel @ self.u)) % 360
        r = np.linalg.norm(rel - np.outer(t, self.d) if rel.ndim > 1 else rel - t * self.d, axis=-1)
        return t, th, r

    def tree(self):
        return BVHTree.FromPolygons([Vector(p) for p in self.v], self.f.tolist())

    def surface(self, tree, t, th, mode):
        a = math.radians(th)
        r = self.u * math.cos(a) + self.w * math.sin(a)
        c = self.q + self.d * t
        if mode == "out":
            hit = tree.ray_cast(Vector(c + r * 90), Vector(-r), 90)
        else:
            hit = tree.ray_cast(Vector(c), Vector(r), 90)
        return None if hit[0] is None else hit[2]          # the triangle hit


def edges_of(f):
    e = np.concatenate([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]])
    e.sort(1)
    return np.unique(e, axis=0)


def grow(scan, tree):
    """Label every vertex with the nearest seed's part, where a step costs its length and more
    where the surface folds in (the creases between fingers are where the parts meet)."""
    import heapq
    v, f = scan.v, scan.f
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    vn = np.zeros_like(v)
    for k in range(3):
        np.add.at(vn, f[:, k], fn)
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-12)
    E = edges_of(f)
    a, b = E[:, 0], E[:, 1]
    L = np.linalg.norm(v[b] - v[a], axis=1)
    # Folding in: the normals turn toward each other along the edge.
    fold = np.clip(-((vn[b] - vn[a]) * (v[b] - v[a])).sum(1) / np.maximum(L, 1e-9), 0, None)
    cost = L * (1 + CREASE * fold * 4)
    nbr = [[] for _ in range(len(v))]
    for i, (x, y) in enumerate(E):
        nbr[x].append((y, cost[i]))
        nbr[y].append((x, cost[i]))
    label = np.full(len(v), -1)
    dist = np.full(len(v), np.inf)
    heap = []
    names = list(SEEDS)
    for k, name in enumerate(names):
        for t, th, mode in SEEDS[name]:
            tri = scan.surface(tree, t, th, mode)
            if tri is None:
                print("  seed %s %s missed" % (name, (t, th, mode)))
                continue
            for vi in f[tri]:
                dist[vi] = 0
                label[vi] = k
                heapq.heappush(heap, (0.0, int(vi), k))
    while heap:
        dd, i, k = heapq.heappop(heap)
        if dd > dist[i]:
            continue
        for j, c in nbr[i]:
            if dd + c < dist[j]:
                dist[j] = dd + c
                label[j] = k
                heapq.heappush(heap, (dd + c, j, k))
    return {name: label == k for k, name in enumerate(names)}, vn


def cut_stubs(scan):
    """Drops the broom handle's two stubs (the handle beyond the hand), leaving two holes."""
    t, th, r = scan.cyl(scan.v)
    stub = (r < HANDLE_R + 0.9) & ((t < HAND_FROM) | (t > HAND_TO))
    keep = ~stub[scan.f].any(1)
    scan.f = scan.f[keep]
    scan.uv = scan.uv[keep]
    print("  stubs: %d vertices dropped" % stub.sum())
    compact(scan)


def compact(scan):
    """Drops vertices no face uses; returns the kept ones' old indices."""
    used = np.unique(scan.f)
    remap = np.full(len(scan.v), -1)
    remap[used] = np.arange(len(used))
    scan.v = scan.v[used]
    scan.f = remap[scan.f]
    return used


def split_index(scan, parts):
    """Gives the index finger its own copies of the vertices it shares with the thumb and the
    middle finger (not the hand: it stays joined at its knuckle), so it can move away from them."""
    lab = np.zeros(len(scan.v), int)              # 0 hand, 1 index, 2 thumb, 3 middle
    for k, name in ((1, "index"), (2, "thumb"), (3, "middle")):
        lab[parts[name]] = k
    # A face is the index's when most of its corners are.
    fl = np.where((lab[scan.f] == 1).sum(1) >= 2, 1, np.where((lab[scan.f] == 0).sum(1) >= 2, 0, 2))
    lab_body = lab
    t, th, r = scan.cyl(scan.v)
    on_index = np.zeros(len(scan.v), bool)
    on_other = np.zeros(len(scan.v), bool)
    on_hand = np.zeros(len(scan.v), bool)
    on_index[scan.f[fl == 1].ravel()] = True
    on_other[scan.f[fl == 2].ravel()] = True
    on_hand[scan.f[fl == 0].ravel()] = True
    split = on_index & (on_other | on_hand) & ~(on_hand & (th < KNUCKLE_THETA + 25))
    new = np.full(len(scan.v), -1)
    new[split] = len(scan.v) + np.arange(split.sum())
    scan.v = np.concatenate([scan.v, scan.v[split]])
    fi = scan.f[fl == 1]
    scan.f[fl == 1] = np.where(new[fi] >= 0, new[fi], fi)
    index = np.zeros(len(scan.v), bool)
    index[np.unique(scan.f[fl == 1])] = True
    thumb = np.concatenate([parts["thumb"], np.zeros(split.sum(), bool)])
    seam = np.concatenate([split, np.ones(split.sum(), bool)])
    print("  index cut free along %d vertices" % split.sum())
    return index, thumb, seam


def digit_tube(scan, mask, th_from, step=2.0, sides=36, sign=1.0, ref=0.0, name="index", form=None):
    """The index finger rebuilt as a closed tube: the scan's own surface where the cast has it (the
    back and sides of the finger), and its palm side, which lay on the broom handle and was never
    cast, rounded off between them. Sections are half-planes through the handle's axis, a step of
    theta apart (the finger runs round the handle); in each, the finger's outline round its middle
    is the scan's furthest point in each direction, and the directions the scan hasn't got are
    filled in round from those either side. Returns (vertices, faces, theta of each vertex, whether
    each vertex is on the scan's surface)."""
    t, th, r = scan.cyl(scan.v)
    th = (sign * (th - ref)) % 360         # how far round from `ref`, the way the digit runs
    m = mask & (th < 300)
    tip = th[m].max()
    secs = []
    for a in np.arange(th_from, tip - 1.0, step):
        near = m & (np.abs(th - a) < step * 0.75)
        if near.sum() < 10:
            continue
        secs.append((a, t[near], r[near]))
    A = np.array([x[0] for x in secs])
    lo = np.array([x[1].min() for x in secs])
    hi = np.array([x[1].max() for x in secs])
    out = np.array([x[2].max() for x in secs])

    def smooth_fit(y, keep=None, deg=3):
        k = np.ones(len(y), bool) if keep is None else keep
        for _ in range(3):
            c = np.polyfit(A[k], y[k], deg)
            f = np.polyval(c, A)
            res = y - f
            k = k & (np.abs(res) < max(2.5 * np.std(res[k]), 0.8))
        return np.polyval(np.polyfit(A[k], y[k], deg), A)

    # The finger's width along the handle and its back are what the cast has best; where the
    # thumb lay on it the back is missing (lower), so the fit leaves those out.
    width = smooth_fit(np.clip(hi - lo, 8, 30))
    ct = smooth_fit((hi + lo) / 2)
    back = smooth_fit(out)
    lowback = out < back - 2.0
    back = smooth_fit(out, ~lowback)
    width = np.minimum(width, 24.0)
    h = width * 0.88
    Cn = np.stack([ct, back - h / 2], 1)
    # Each section an ellipse, nudged by the scan where it has the surface (within 1.5 mm).
    R = []
    have = []
    al = -math.pi + (np.arange(sides) + 0.5) * 2 * math.pi / sides
    for i, (a, ts, rs) in enumerate(secs):
        e = 1.0 / np.sqrt((np.cos(al) / (width[i] / 2)) ** 2 + (np.sin(al) / (h[i] / 2)) ** 2)
        q = np.stack([ts - Cn[i, 0], rs - Cn[i, 1]], 1)
        ang = np.arctan2(q[:, 1], q[:, 0])
        dist = np.linalg.norm(q, axis=1)
        k = ((ang + math.pi) / (2 * math.pi) * sides).astype(int) % sides
        rr = e.copy()
        hv = np.zeros(sides, bool)
        for b in range(sides):
            if (k == b).any():
                dd = dist[k == b].max() - e[b]
                if abs(dd) < FOLLOW + 1.0:
                    rr[b] = e[b] + np.clip(dd, -FOLLOW, FOLLOW)
                    hv[b] = abs(dd) < FOLLOW
        R.append(rr)
        have.append(hv)
    R = np.array(R)
    have = np.array(have)
    for _ in range(5):
        R[1:-1] = 0.5 * R[1:-1] + 0.25 * (R[:-2] + R[2:])
        R = 0.5 * R + 0.25 * (np.roll(R, 1, 1) + np.roll(R, -1, 1))
    if form:
        R = shape_digit(R, A, al, have, form, A[-1])

    def ring(a, c, rr):
        ar = math.radians(ref + sign * a)
        radial = scan.u * math.cos(ar) + scan.w * math.sin(ar)
        tt = c[0] + rr * np.cos(al)
        rd = c[1] + rr * np.sin(al)
        return scan.q + np.outer(tt, scan.d) + np.outer(rd, radial)

    V, TH, ON = [], [], []
    for i in range(len(A)):
        V.append(ring(A[i], Cn[i], R[i]))
        TH.append(np.full(sides, A[i]))
        ON.append(have[i])
    # The fingertip: two rings closing in past the last section, then its end; or, with `form`,
    # a rounded end (a quarter ellipse along the digit, its middle easing toward the nail side).
    if form:
        reach = form.get("tip", 0.45) * R[-1].mean()
        per_deg = max(Cn[-1, 1], 5.0) * math.pi / 180
        caps = [(math.sin(math.radians(p_)), math.cos(math.radians(p_))) for p_ in (22, 44, 63, 78, 88)]
        for e_, sc in caps:
            a = A[-1] + reach * e_ / per_deg
            c = Cn[-1] + np.array([0.0, (1 - sc) * form.get("tip_up", 0.2) * h[-1]])
            V.append(ring(a, c, R[-1] * sc))
            TH.append(np.full(sides, a))
            ON.append(np.zeros(sides, bool))
    else:
        for f_, sc in ((0.5, 0.8), (1.0, 0.5), (1.4, 0.2)):
            a = A[-1] + step * f_ * 1.5
            V.append(ring(a, Cn[-1], R[-1] * sc))
            TH.append(np.full(sides, a))
            ON.append(np.zeros(sides, bool))
    V = np.concatenate(V)
    TH = np.concatenate(TH)
    ON = np.concatenate(ON)
    n = len(V) // sides
    tipc = V[-sides:].mean(0)
    V = np.concatenate([V, tipc[None]])
    TH = np.concatenate([TH, [TH[-1] + step]])
    ON = np.concatenate([ON, [False]])
    F = []
    for i in range(n - 1):
        for j in range(sides):
            a_, b_ = i * sides + j, i * sides + (j + 1) % sides
            c_, d_ = (i + 1) * sides + (j + 1) % sides, (i + 1) * sides + j
            F += [[a_, b_, c_], [a_, c_, d_]]
    last = (n - 1) * sides
    for j in range(sides):
        F.append([last + j, last + (j + 1) % sides, len(V) - 1])
    F = np.array(F)
    # Wound outward: the first face's normal should point away from the finger's middle.
    p0, p1, p2 = V[F[0]]
    if np.cross(p1 - p0, p2 - p0) @ (p0 - V[:sides].mean(0)) < 0:
        F = F[:, ::-1]
    print("  %s rebuilt as a tube: %d sections from %.0f to %.0f round, %.0f%% of it from the scan"
          % (name, len(A), A[0], A[-1], 100 * have.mean()))
    centres = (A, Cn)
    TH = (ref + sign * TH) % 360
    return V, F, TH, ON, centres


def shape_digit(R, A, al, have, form, tip):
    """A rebuilt digit's sections given a finger's form rather than a plain ellipse's: the pad side
    flatter (`flat`), each knuckle standing up on the back (`knuckle` mm) with a crease under it on
    the pad side (`crease` mm), and the pad of the last bone full (`pad` mm). Where a section
    follows the scan's own surface it's left as cast."""
    back = np.clip(np.sin(al), 0, 1)
    palm = np.clip(-np.sin(al), 0, 1)
    js = sorted(form["joints"])
    knuckle = np.zeros(len(A))
    crease = np.zeros(len(A))
    for aj in js:
        knuckle += np.exp(-0.5 * ((A - aj) / form.get("knuckle_w", 7.0)) ** 2)
        crease += np.exp(-0.5 * ((A - aj) / form.get("crease_w", 3.0)) ** 2)
    padc = (js[-1] + tip) / 2
    pad = np.exp(-0.5 * ((A - padc) / max((tip - js[-1]) / 3, 3.0)) ** 2)
    d = (np.outer(knuckle, back ** 2) * form.get("knuckle", 0.0)
         - np.outer(crease, palm ** 2) * form.get("crease", 0.0)
         + np.outer(pad, palm ** 2) * form.get("pad", 0.0))
    out = R * (1 - form.get("flat", 0.0) * palm ** 3) + d
    return np.where(have, R, out)


def tube_uv(scan, tree, V, F, ON):
    """Texture coordinates for the tube from the scan's own (the nearest point of the cast's
    surface) where it lies on the scan; a face whose corners land on different islands of the
    scan's texture, or off it, gets none (flag 1)."""
    uv = np.zeros((len(F), 3, 2))
    flag = np.ones((len(F), 3))
    per = np.zeros((len(V), 2))
    for i, p in enumerate(V):
        if not ON[i]:
            continue
        loc, _, fi, _ = tree.find_nearest(Vector(p))
        if fi is None:
            continue
        a, b, c = scan.v[scan.f[fi]]
        M = np.stack([b - a, c - a], 1)
        w = np.linalg.lstsq(M, np.asarray(loc) - a, rcond=None)[0]
        bc = np.array([1 - w.sum(), w[0], w[1]])
        per[i] = bc @ scan.uv[fi]
    for k, f in enumerate(F):
        if ON[f].all():
            u = per[f]
            if np.max(np.linalg.norm(u[:, None] - u[None], axis=2)) < 0.02:
                uv[k] = u
                flag[k] = 0
                continue
        uv[k] = per[f[0]] if ON[f[0]] else 0
    return uv, flag


def to_bmesh(scan):
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in scan.v]
    uvl = bm.loops.layers.uv.new("UVMap")
    for k, f in enumerate(scan.f):
        try:
            face = bm.faces.new([vs[i] for i in f])
        except ValueError:
            continue
        for li, loop in enumerate(face.loops):
            loop[uvl].uv = scan.uv[k][li]
    bm.verts.index_update()
    return bm


def from_bmesh(scan, bm):
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
    bm.verts.index_update()
    uvl = bm.loops.layers.uv["UVMap"]
    scan.v = np.array([v.co[:] for v in bm.verts])
    scan.f = np.array([[v.index for v in f.verts] for f in bm.faces])
    scan.uv = np.array([[lp[uvl].uv[:] for lp in f.loops] for f in bm.faces])


def boundary_loops(bm, side=None, seam=None):
    """The open rims as ordered vertex lists; with `side` (a face test), only the boundary edges
    whose face passes it, and with `seam` (a vertex mask) only those along it, chained."""
    edges = [e for e in bm.edges if e.is_boundary and (side is None or side(e.link_faces[0]))
             and (seam is None or all(seam[v.index] for v in e.verts))]
    nxt = {}
    for e in edges:
        a, b = e.verts
        nxt.setdefault(a, []).append(b)
        nxt.setdefault(b, []).append(a)
    seen = set()
    loops = []
    for start in nxt:
        if start in seen:
            continue
        # Start from a chain's end if it has one.
        chain_start = start
        stack = [start]
        comp = set()
        while stack:
            x = stack.pop()
            if x in comp:
                continue
            comp.add(x)
            stack += nxt[x]
        ends = [x for x in comp if len(nxt[x]) == 1]
        if ends:
            chain_start = ends[0]
        loop = [chain_start]
        seen.add(chain_start)
        prev = None
        cur = chain_start
        while True:
            options = [y for y in nxt[cur] if y is not prev and y not in seen]
            if not options:
                break
            prev, cur = cur, options[0]
            seen.add(cur)
            loop.append(cur)
        seen |= comp
        loops.append(loop)
    return loops


def bridge(bm, scan, chain, body, rows=5, bulge=0.35):
    """Closes a U-shaped rim (a chain of vertices, both its ends near each other at the knuckle):
    it's split at the far end of the U into two sides running the same way round the handle, and
    a strip is laid between them, rung by rung, bowed out away from the finger (`body`, the
    vertices it closes) as a finger's side is. Returns the strip's new vertices."""
    if len(chain) < 6:
        return []
    P = np.array([v.co[:] for v in chain])
    # The U's far end: the rim's point furthest from the middle of its two ends.
    k = int(np.argmax(np.linalg.norm(P - 0.5 * (P[0] + P[-1]), axis=1)))
    s1, s2 = list(range(0, k + 1)), list(range(len(chain) - 1, k - 1, -1))
    if len(s1) < 2 or len(s2) < 2:
        return []

    def arc(idx):
        q = P[idx]
        a = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(q, axis=0), axis=1))])
        return a / max(a[-1], 1e-9)

    th1, th2 = arc(s1), arc(s2)                    # each side by how far along it, 0 to 1
    sgn = 1.0
    n = max(3, int(max(len(s1), len(s2)) / 3))
    S = np.linspace(0, 1, n)

    def along(idx, a, at):
        return np.array([np.interp(at, a, P[idx][:, j]) for j in range(3)]).T

    A = along(np.array(s1), th1, S)
    B = along(np.array(s2), th2, S)
    bodyv = np.array([v.co[:] for v in bm.verts if body[v.index]]) if body.any() else P
    from mathutils.kdtree import KDTree
    kd = KDTree(len(bodyv))
    for i_, p_ in enumerate(bodyv):
        kd.insert(Vector(p_), i_)
    kd.balance()

    def centre(m):
        near = [i_ for _, i_, _ in kd.find_range(Vector(m), 7.0)]
        return bodyv[near].mean(0) if near else np.asarray(m)

    rowsv = [[chain[i] for i in s1]]
    rows_th = [th1]
    new = []
    for q in range(1, rows):
        f = q / rows
        mid = A * (1 - f) + B * f
        cen = np.array([centre(m) for m in mid])
        chord = B - A
        out = mid - cen
        out -= chord * ((out * chord).sum(1) / np.maximum((chord * chord).sum(1), 1e-9))[:, None]
        out /= np.maximum(np.linalg.norm(out, axis=1, keepdims=True), 1e-9)
        gap = np.linalg.norm(chord, axis=1)
        pts = mid + out * (bulge * gap * math.sin(math.pi * f))[:, None]
        vs = [bm.verts.new(tuple(p)) for p in pts]
        new += vs
        rowsv.append(vs)
        rows_th.append(S)
    rowsv.append([chain[i] for i in s2])
    rows_th.append(th2)
    uvl = bm.loops.layers.uv["UVMap"]
    for (ra, ta), (rb, tb) in zip(zip(rowsv, rows_th), zip(rowsv[1:], rows_th[1:])):
        oa, ob = np.argsort(sgn * ta), np.argsort(sgn * tb)
        i = j = 0
        while i < len(oa) - 1 or j < len(ob) - 1:
            adv_a = j >= len(ob) - 1 or (i < len(oa) - 1 and sgn * ta[oa[i + 1]] <= sgn * tb[ob[j + 1]])
            if adv_a:
                tri = (ra[oa[i]], ra[oa[i + 1]], rb[ob[j]])
                i += 1
            else:
                tri = (ra[oa[i]], rb[ob[j + 1]], rb[ob[j]])
                j += 1
            if len(set(tri)) == 3:
                try:
                    fc = bm.faces.new(tri)
                    for lp in fc.loops:
                        lp[uvl].uv = (0.0, 0.0)
                except ValueError:
                    pass
    return new


def orient(bm, n_faces):
    """Winds each new face (index n_faces on) to agree with the faces it shares an edge with,
    spreading out from the scan's own faces (whose winding is the scan's)."""
    bm.faces.index_update()
    done = set(f for f in bm.faces if f.index < n_faces)
    todo = [f for f in bm.faces if f.index >= n_faces]
    changed = True
    while changed and todo:
        changed = False
        rest = []
        for f in todo:
            ok = None
            for e in f.edges:
                for g in e.link_faces:
                    if g is f or g not in done:
                        continue
                    a, b = e.verts
                    fa = [v for v in f.verts]
                    ga = [v for v in g.verts]
                    same_f = fa[(fa.index(a) + 1) % len(fa)] is b
                    same_g = ga[(ga.index(a) + 1) % len(ga)] is b
                    ok = same_f != same_g
                    break
                if ok is not None:
                    break
            if ok is None:
                rest.append(f)
                continue
            if not ok:
                bmesh.ops.reverse_faces(bm, faces=[f])
            done.add(f)
            changed = True
        todo = rest


def close_cut(scan, index, seam, thumb, parts=None, skip_thumb=False):
    """Closes the cut's sides apart: the index finger's, the thumb's and the middle finger's (and
    the palm's where the index's tip lay), each rim bridged along its length."""
    bm = to_bmesh(scan)
    bm.verts.ensure_lookup_table()
    is_index = lambda f: sum(index[v.index] for v in f.verts) >= 2   # noqa: E731
    rims = []
    other = boundary_loops(bm, lambda f: not is_index(f), seam)
    # The other side's rims run over the thumb and the middle finger: each closed on its own. The
    # rim's vertices the growing gave the index finger (the cut's own) take their neighbours'.
    for r_ in other:
        lab = np.array([1.0 if v.index < len(thumb) and thumb[v.index] else
                        (0.0 if v.index < len(parts["middle"]) and parts["middle"][v.index] else np.nan) for v in r_])
        known = np.nonzero(~np.isnan(lab))[0]
        if len(known):
            lab = np.interp(np.arange(len(lab)), known, lab[known])
        else:
            lab = np.zeros(len(lab))
        k_ = 6
        sm = np.array([lab[max(0, i - k_):i + k_ + 1].mean() for i in range(len(lab))]) > 0.5
        start = 0
        for i in range(1, len(r_) + 1):
            if i == len(r_) or sm[i] != sm[start]:
                if i - start > 6 and not (skip_thumb and sm[start]):
                    rims.append((r_[start:i], thumb if sm[start] else ~thumb & ~index))
                start = i
    print("  cut: rims of %s vertices (the other side's %s)" % ([len(r_) for r_, _ in rims], [len(r_) for r_ in other]))
    n0 = len(bm.verts)
    n_faces = len(bm.faces)
    made = []
    for r_, body in rims:
        made.append(bridge(bm, scan, r_, np.concatenate([body, np.zeros(len(bm.verts) - len(body), bool)])))
    # Fair the strips, and ease the scan's own rims (the creases' bottoms zig-zag) a little with them.
    strip = [v for vs in made for v in vs]
    rimv = list({v for r_, _ in rims for v in r_})
    near = set(rimv)
    for _ in range(2):
        near |= {w for v in list(near) for e in v.link_edges for w in e.verts}
    near = [v for v in near if v.index < n0]
    for _ in range(40):
        bmesh.ops.smooth_vert(bm, verts=strip, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    for _ in range(8):
        bmesh.ops.smooth_vert(bm, verts=near, factor=0.4, use_axis_x=True, use_axis_y=True, use_axis_z=True)
        bmesh.ops.smooth_vert(bm, verts=strip, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    orient(bm, n_faces)
    bm.verts.index_update()
    idx = np.zeros(len(bm.verts), bool)
    idx[:len(index)] = index
    for (r_, body), vs in zip(rims, made):
        if body is index:
            for v in vs:
                idx[v.index] = True
    from_bmesh(scan, bm)
    bm.free()
    return idx, n0


class Fit:
    """The hand frame (mm, the scan's space) onto the gun's (m)."""

    def __init__(self, scan, t0, roll):
        a = unit(GRIP_UP)
        u = np.asarray(PLACE["wrist"], float)
        u = unit(u - a * (u @ a))
        u = rot(a, roll) @ u
        w = np.cross(a, u)
        self.R = np.stack([a, u, w], 1) @ np.stack([scan.d, scan.u, scan.w], 0)
        self.s = PLACE["scale"] / 1000.0
        self.o = np.asarray(GRIP_AT) - self.R @ (scan.q + scan.d * t0) * self.s
        self.a, self.u, self.w = a, u, w

    def __call__(self, p):
        return (np.asarray(p) @ self.R.T) * self.s + self.o


def grip_radius(gun_grip, fit, scan, t, th):
    """How far the grip's surface is from its centre line at each (t, theta) of the hand (mm), or
    0 where the grip isn't (above or below it)."""
    out = np.zeros(len(t))
    for i, (tt, a) in enumerate(zip(t, np.radians(th))):
        c = fit(scan.q + scan.d * tt)
        r = fit.R @ (scan.u * math.cos(a) + scan.w * math.sin(a))
        hit = gun_grip.ray_cast(Vector(c + r * 0.06), Vector(-r), 0.06)
        out[i] = (0.06 - hit[3]) * 1000 / PLACE["scale"] if hit[0] is not None else 0.0
    return out


def neighbours(f, n):
    E = edges_of(f)
    return E[:, 0], E[:, 1], n


def grip_push(scan, fit, gun_grip):
    """How far each part of the fist moves out from the handle's axis to hold the grip in place of
    the broom handle (mm), on a (t, theta) grid: the grip's radius there less the handle's, eased
    over its neighbours. The whole ring of flesh at a (t, theta) moves together, so the fingers
    keep their thickness and close round something bigger."""
    T = np.arange(HAND_FROM - 30, HAND_TO + 4, 1.0)
    TH = np.arange(0, 360, 3.0)
    tt, hh = np.meshgrid(T, TH, indexing="ij")
    G = grip_radius(gun_grip, fit, scan, tt.ravel(), hh.ravel()).reshape(tt.shape)
    D = np.where(G > 0, np.clip(G + GRIP_CLEAR - HANDLE_R, 0, None), 0.0)
    # Within the hand, where the grip ends (above or below it) keep the nearest push; past the
    # hand (the wrist and forearm) let it go.
    for i in range(len(T)):
        if T[i] >= HAND_FROM and not D[i].any():
            j = np.argmin([abs(k - i) if D[k].any() else 1e9 for k in range(len(T))])
            D[i] = D[j]
    fade = np.clip((T - (HAND_FROM - 25)) / 25.0, 0, 1)[:, None]
    D = D * fade
    for _ in range(6):                          # ease it: round the ring and along the handle
        D = 0.5 * D + 0.25 * (np.roll(D, 1, 1) + np.roll(D, -1, 1))
        D[1:-1] = 0.5 * D[1:-1] + 0.25 * (D[:-2] + D[2:])
    return T, TH, D


def apply_push(scan, v, push):
    T, TH, D = push
    t, th, r = scan.cyl(v)
    ti = np.clip((t - T[0]), 0, len(T) - 1.001)
    i0 = ti.astype(int)
    ft = ti - i0
    hj = (th / 3.0) % len(TH)
    j0 = hj.astype(int) % len(TH)
    j1 = (j0 + 1) % len(TH)
    fh = hj - np.floor(hj)
    i1 = np.minimum(i0 + 1, len(T) - 1)
    d = ((D[i0, j0] * (1 - fh) + D[i0, j1] * fh) * (1 - ft) + (D[i1, j0] * (1 - fh) + D[i1, j1] * fh) * ft)
    rel = v - scan.q
    radial = rel - np.outer(t, scan.d)
    radial /= np.maximum(np.linalg.norm(radial, axis=1, keepdims=True), 1e-9)
    return v + radial * d[:, None]


def index_joints(scan, index, patch):
    """The index finger's joint centres (mm, in the scan's space, on its centre line at each
    joint's theta) and its pad (the palm side of its last segment)."""
    t, th, r = scan.cyl(scan.v)
    m = index & ~patch
    out = {}
    for name, a in JOINTS.items():
        near = m & (np.abs(((th - a + 180) % 360) - 180) < 6)
        rho = 0.5 * (r[near].min() + r[near].max())
        tm = t[near].mean()
        ar = math.radians(a)
        out[name] = scan.q + scan.d * tm + (scan.u * math.cos(ar) + scan.w * math.sin(ar)) * rho
        print("  joint %s: theta %.0f, %.1f mm out, t %.1f" % (name, a, rho, tm))
    tipv = m & (th > JOINTS["dip"] + 20)
    inner = tipv & (r < np.percentile(r[tipv], 35))
    out["pad"] = scan.v[inner].mean(0)
    return out


def pose_index(scan, index, joints, angles, pts=None):
    """The index finger's vertices (or `pts`) with its joints opened by `angles` (degrees, each
    joint's distal part turned back about an axis along the handle through it)."""
    v = scan.v if pts is None else pts
    t, th, r = scan.cyl(v)
    out = v.copy()
    for name in ("dip", "pip", "mcp", "abd"):
        a = JOINTS["mcp" if name == "abd" else name]
        s_ = np.clip((th - (a - 10)) / 20.0, 0, 1)
        s_ = s_ * s_ * (3 - 2 * s_)
        sel = index if pts is None else np.ones(len(v), bool)
        c = joints["mcp" if name == "abd" else name]
        if name == "abd":
            ar = math.radians(a)
            axis = scan.u * math.cos(ar) + scan.w * math.sin(ar)
        else:
            axis = scan.d
        for k in np.nonzero(sel & (s_ > 0))[0]:
            Rm = rot(axis, (angles[name] if name == "abd" else -angles[name]) * s_[k])
            out[k] = c + Rm @ (out[k] - c)
    return out


def best_index(scan, fit, joints, index, gun, sample_pts, top=30, target=TRIGGER, around=None):
    """The index finger's joint angles that bring its pad nearest the trigger without going into
    the gun: (score, angles, mm off, points in the gun)."""
    pad = joints["pad"]
    cands = []
    if around is None:
        rng_ = {k: range(OPEN[k][0], OPEN[k][1] + 1, 10) for k in OPEN}
    else:   # near a pose already found, finer
        rng_ = {k: range(around[k] - 10, around[k] + 11, 3) for k in OPEN}
    import itertools
    for m_, p_, d_, a_ in itertools.product(rng_["mcp"], rng_["pip"], rng_["dip"], rng_["abd"]):
        ang = {"mcp": m_, "pip": p_, "dip": d_, "abd": a_}
        q_ = fit(pose_index(scan, None, joints, ang, pad[None])[0])
        cands.append((np.linalg.norm(q_ - np.asarray(target)) * 1000, ang))
    if around is None:      # then finer round the best few
        cands.sort(key=lambda c: c[0])
        for _, a0 in cands[:3]:
            for m_, p_, d_, a_ in itertools.product(*[range(a0[k] - 6, a0[k] + 7, 3) for k in ("mcp", "pip", "dip", "abd")]):
                ang = {"mcp": m_, "pip": p_, "dip": d_, "abd": a_}
                q_ = fit(pose_index(scan, None, joints, ang, pad[None])[0])
                cands.append((np.linalg.norm(q_ - np.asarray(target)) * 1000, ang))
    cands.sort(key=lambda c: c[0])
    best = None
    for err, ang in cands[:top]:
        n_in = held_hand.inside(gun, fit(pose_index(scan, None, joints, ang, sample_pts)), 0.0)
        score = err + n_in * 1.0
        if best is None or score < best[0]:
            best = (score, ang, err, n_in)
    return best


def main():
    preview = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--preview=")), None)
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    gun = held_hand.Gun()
    grip_parts = Grip()
    scan = Scan()
    cut_stubs(scan)
    tree = scan.tree()
    parts, vn = grow(scan, tree)
    for k, m in parts.items():
        print("  %s: %d vertices" % (k, m.sum()))
    index, thumb, seam = split_index(scan, parts)
    # The index finger rebuilt whole past its knuckle (the scan has only its back: its palm side
    # lay on the handle), the scan's own finger dropped there.
    tree0 = scan.tree()
    TV, TF, TTH, TON, _ = digit_tube(scan, index, JOIN - 15)
    tuv, tflag = tube_uv(scan, tree0, TV, TF, TON)
    thumb_scan = thumb.copy()
    UV_, UF, UTH, UON, ucent = digit_tube(scan, thumb_scan, THUMB_JOIN - 15, sign=-1.0, ref=THUMB_REF, name="thumb",
                                          form=THUMB_FORM)
    uuv, uflag = tube_uv(scan, tree0, UV_, UF, UON)
    tjoints = {}
    for k_, u_j in THUMB_JOINTS.items():
        c_ = np.array([np.interp(u_j, ucent[0], ucent[1][:, 0]), np.interp(u_j, ucent[0], ucent[1][:, 1])])
        ar = math.radians(THUMB_REF - u_j)
        tjoints[k_] = scan.q + scan.d * c_[0] + (scan.u * math.cos(ar) + scan.w * math.sin(ar)) * c_[1]
    t_, th_, r_ = scan.cyl(scan.v)
    uu_ = (THUMB_REF - th_) % 360
    # Every face with a corner on the rebuilt part goes (a face half on it, half on a neighbour,
    # would be dragged after the digit as it moves).
    gone_i = index & (th_ > JOIN)
    gone_t = thumb_scan & (uu_ > THUMB_JOIN) & (uu_ < 300)
    drop = gone_i[scan.f].any(1) | gone_t[scan.f].any(1)
    scan.f, scan.uv = scan.f[~drop], scan.uv[~drop]
    n_cut = len(scan.v)
    _, _ = close_cut(scan, index, seam, thumb, parts, skip_thumb=True)
    patch = np.zeros(len(scan.v), bool)
    patch[n_cut:] = True
    pad = len(scan.v) - len(index)
    index = np.concatenate([index, np.zeros(pad, bool)])
    thumb = np.concatenate([thumb, np.zeros(len(scan.v) - len(thumb), bool)])
    base = len(scan.v)
    scan.v = np.concatenate([scan.v, TV, UV_])
    scan.f = np.concatenate([scan.f, TF + base, UF + base + len(TV)])
    scan.uv = np.concatenate([scan.uv, tuv, uuv])
    tpatch = ~TON
    tpatch[np.unique(TF[(tflag > 0).any(1)])] = True
    upatch = ~UON
    upatch[np.unique(UF[(uflag > 0).any(1)])] = True
    index = np.concatenate([index, np.ones(len(TV), bool), np.zeros(len(UV_), bool)])
    thumb = np.concatenate([thumb, np.zeros(len(TV), bool), np.ones(len(UV_), bool)])
    patch = np.concatenate([patch, tpatch, upatch])
    used = compact(scan)
    index, thumb, patch = index[used], thumb[used], patch[used]
    h = np.zeros(base + len(TV) + len(UV_), bool)
    h[:len(parts["hand"])] = parts["hand"]
    parts["hand"] = h[used]
    dbg = next((a_.split("=", 1)[1] for a_ in sys.argv if a_.startswith("--cut-debug=")), None)
    if dbg:
        keep = index | patch
        fk = keep[scan.f].all(1)
        show_parts(scan, {"index": index & ~patch, "thumb": np.zeros(len(scan.v), bool), "middle": patch & index,
                          "hand": patch & ~index}, dbg, "rest", faces=scan.f[fk] if "--only-index" in sys.argv else None)
    m = scan.decimate(KEEP, {"index": index, "thumb": thumb, "patch": patch, "hand": parts_hand(scan, parts)})
    index, thumb, patch = m["index"], m["thumb"], m["patch"]
    parts = {"hand": m["hand"]}
    joints = index_joints(scan, index, patch)
    rest = scan.v.copy()
    rng = np.random.default_rng(3)
    hand_sample = rng.choice(np.nonzero(~index & ~patch)[0], 1500, replace=False)
    idx_sample = np.nonzero(index & ~patch)[0][::14]
    results = []
    arg = lambda k, d: tuple(float(x) for x in next((a_.split("=", 1)[1] for a_ in sys.argv
                                                     if a_.startswith(k + "=")), ",".join(map(str, d))).split(","))
    for t0 in arg("--search-t", SEARCH_T):
        for roll in arg("--search-roll", SEARCH_ROLL):
            fit = Fit(scan, t0, roll)
            push = grip_push(scan, fit, grip_parts)
            v = apply_push(scan, rest, push)
            scan.v = v
            j = {k: (apply_push(scan, x[None], push)[0]) for k, x in joints.items()}
            b = best_index(scan, fit, j, index, gun, v[idx_sample], top=12)
            n_hand = held_hand.inside(gun, fit(v[hand_sample]), 0.0)
            score = b[0] + n_hand * 0.4
            ck = None
            if "--place-search" in sys.argv:
                tj_ = {k: apply_push(scan, x[None], push)[0] for k, x in tjoints.items()}
                vi = pose_index(scan, index, j, b[1])
                ck = thumb_cock(scan, fit, vi, thumb, tj_, gun, pose=False)
                score += ck[1]["swing"] * THUMB_REACH
            results.append((score, t0, roll, b, n_hand))
            print("  t0 %5.1f roll %5.1f: index %s %.1f mm off, %d in; hand %d of %d in%s -> %.1f"
                  % (t0, roll, b[1], b[2], b[3], n_hand, len(hand_sample),
                     "" if ck is None else "; thumb %s %.1f mm off, %d in, root at y %.1f mm"
                     % (ck[1], ck[2], ck[3], fit(tj_["root"])[1] * 1000), score))
            scan.v = rest
    results.sort(key=lambda r: r[0])
    score, t0, roll, b, n_hand = results[0]
    print("  best: t0 %.1f roll %.1f index %s" % (t0, roll, b[1]))
    fit = Fit(scan, t0, roll)
    push = grip_push(scan, fit, grip_parts)
    scan.v = apply_push(scan, rest, push)
    j = {k: (apply_push(scan, x[None], push)[0]) for k, x in joints.items()}
    b = best_index(scan, fit, j, index, gun, scan.v[idx_sample], top=60)
    print("  index to the trigger: %s, pad %.1f mm off, %d of %d sampled points in the gun"
          % (b[1], b[2], b[3], len(idx_sample)))
    v = pose_index(scan, index, j, b[1])
    tj = {k: apply_push(scan, x[None], push)[0] for k, x in tjoints.items()}
    v_rest, rest_ang = thumb_rest(scan, fit, v, thumb, tj, gun)
    G = fit(v_rest)
    sq = best_index(scan, fit, j, index, gun, scan.v[idx_sample], top=60, target=SQUEEZED, around=b[1])
    print("  squeezed: %s, pad %.1f mm off" % (sq[1], sq[2]))
    G_sq = fit(pose_thumb(scan, scan.v, pose_index(scan, index, j, sq[1]), thumb, tj, rest_ang, hand_too=~thumb))
    G_ck = fit(thumb_cock(scan, fit, v, thumb, tj, gun))
    if preview and "--cock-debug" in sys.argv:
        Fc = scan.f
        e_rest = np.linalg.norm(G[Fc[:, 0]] - G[Fc[:, 1]], axis=1) + np.linalg.norm(G[Fc[:, 1]] - G[Fc[:, 2]], axis=1)
        e_ck = np.linalg.norm(G_ck[Fc[:, 0]] - G_ck[Fc[:, 1]], axis=1) + np.linalg.norm(G_ck[Fc[:, 1]] - G_ck[Fc[:, 2]], axis=1)
        bad = e_ck > 3 * e_rest + 0.002
        print("  cocked: %d faces stretched over 3x" % bad.sum())
        bv = np.unique(Fc[bad])
        print("    their corners: thumb %d, index %d, patch %d, other %d" % (thumb[bv].sum(), index[bv].sum(), patch[bv].sum(), (~thumb[bv] & ~index[bv] & ~patch[bv]).sum()))
        if len(bv):
            tt_, hh_, rr_ = scan.cyl(scan.v[bv])
            print("    theta %s, t %.0f..%.0f" % (np.percentile(hh_, [5, 50, 95]).round(), tt_.min(), tt_.max()))
        show_on_gun(G_ck, scan.f, {"index": thumb, "thumb": thumb, "patch": np.isin(np.arange(len(G)), bv)}, preview,
                    gun=False, prefix="cock")
    if preview:
        show_on_gun(G, scan.f, {"index": index, "thumb": thumb, "patch": patch}, preview)
        show_on_gun(G, scan.f, {"index": index, "thumb": thumb, "patch": patch}, preview, gun=False)
    write(scan, fit, G, G_sq, G_ck, index, thumb, patch, gun)


def pose_thumb(scan, rest, pts, mask, joints, angles, hand_too=None):
    """`pts` (the hand as posed so far) with the thumb's joints turned by `angles`: its tip joint,
    knuckle and root bend about axes along the handle (as it curled round it), and the whole
    thumb swings at its root along the handle (up the grip). Weights from the rest pose; the
    root's turns carry the flesh round the root too (`hand_too`), fading over THUMB_BASE, so the
    ball of the thumb moves with it rather than tearing from it."""
    t, th, r = scan.cyl(rest)
    u = (THUMB_REF - th) % 360
    out = pts.copy()
    for name in ("ip", "mcp", "root", "swing"):
        uj = THUMB_JOINTS["root" if name == "swing" else name]
        s_ = np.clip((u - (uj - 8)) / 16.0, 0, 1)
        s_ = s_ * s_ * (3 - 2 * s_) * mask * (u < 300)
        c = joints["root" if name == "swing" else name]
        if name in ("root", "swing") and hand_too is not None:
            d_ = np.linalg.norm(rest - joints["root"], axis=1)
            fall = np.clip(1 - d_ / THUMB_BASE, 0, 1)
            fall = fall * fall * (3 - 2 * fall) * 0.85
            s_ = np.where(mask, np.maximum(s_, fall), fall * hand_too)
            # One smooth field over the ball of the thumb: eased across the mesh, the thumb past
            # its root and the flesh well away from it held.
            held = (mask & (u > uj + 10) & (u < 300)) | (d_ > THUMB_BASE * 1.6)
            a_, b_, _ = neighbours(scan.f, len(rest))
            deg = np.bincount(a_, minlength=len(rest)) + np.bincount(b_, minlength=len(rest))
            for _ in range(40):
                acc = np.bincount(a_, s_[b_], len(rest)) + np.bincount(b_, s_[a_], len(rest))
                sm = np.where(deg > 0, acc / np.maximum(deg, 1), s_)
                s_ = np.where(held, s_, 0.5 * s_ + 0.5 * sm)
        if name == "swing":
            ar = math.radians(THUMB_REF - uj)
            axis = scan.u * math.cos(ar) + scan.w * math.sin(ar)
        else:
            axis = scan.d
        for k in np.nonzero(s_ > 0)[0]:
            out[k] = c + rot(axis, -angles[name] * s_[k]) @ (out[k] - c)
    return out


def thumb_rest(scan, fit, v, thumb, joints, gun):
    """Where the thumb rests while he holds the gun: not wrapped round the grip as the cast's was
    round the broom handle (from there cocking swung it 100 degrees), but swung part way up and
    lying along the frame's left side under the hammer, its pad on the frame. Its joints' angles
    are searched (THUMB_REST's ranges) for the most of its pad within THUMB_TOUCH of the frame,
    none of it in the gun, its joints bent as little as will do. Returns (the hand so posed, the
    angles)."""
    import itertools
    t, th, r = scan.cyl(scan.v)
    u = (THUMB_REF - th) % 360
    on = thumb & (u < 300) & (u > THUMB_JOINTS["mcp"] - 5)
    # Its pad: the inner part of each 4-degree slice of it (nearest the handle's axis).
    pad = np.zeros(len(u), bool)
    for x in np.arange(u[on].min(), u[on].max() + 4, 4.0):
        sl = on & (u >= x) & (u < x + 4)
        if sl.any():
            pad |= sl & (r <= np.percentile(r[sl], 45))
    pad_i = np.nonzero(pad)[0]
    every = np.nonzero(thumb)[0]
    rest = scan.v

    def score(ang, sub_pad, sub_all):
        q_pad = fit(pose_thumb(scan, rest[sub_pad], v[sub_pad], np.ones(len(sub_pad), bool), joints, ang))
        q_all = fit(pose_thumb(scan, rest[sub_all], v[sub_all], np.ones(len(sub_all), bool), joints, ang))
        n_in = held_hand.inside(gun, q_all, 0.0)
        near = held_hand.inside(gun, q_pad, THUMB_TOUCH) - held_hand.inside(gun, q_pad, 0.0)
        bend = abs(ang["root"]) + abs(ang["mcp"]) + abs(ang["ip"])
        return n_in * 3.0 - near * 1.0 + bend * 0.02, near, n_in

    sp = pad_i[:: max(1, len(pad_i) // 14)]
    sa = every[:: max(1, len(every) // 16)]
    rng_ = {k: range(THUMB_REST[k][0], THUMB_REST[k][1] + 1, 20) for k in THUMB_REST}
    rng_["swing"] = range(THUMB_REST["swing"][0], THUMB_REST["swing"][1] + 1, 10)
    coarse = []
    for sw, ro, mc, ip in itertools.product(rng_["swing"], rng_["root"], rng_["mcp"], rng_["ip"]):
        ang = {"swing": sw, "root": ro, "mcp": mc, "ip": ip}
        coarse.append((score(ang, sp, sa)[0], ang))
    coarse.sort(key=lambda c: c[0])
    sp = pad_i[:: max(1, len(pad_i) // 40)]
    sa = every[:: max(1, len(every) // 60)]
    best = None
    seen = set()
    for _, a0 in coarse[:6]:
        for d in itertools.product((-10, 0, 10), repeat=4):
            ang = {k: int(np.clip(a0[k] + d_, *THUMB_REST[k])) for k, d_ in zip(("swing", "root", "mcp", "ip"), d)}
            key = tuple(ang.values())
            if key in seen:
                continue
            seen.add(key)
            sc = score(ang, sp, sa)
            if best is None or sc[0] < best[0]:
                best = (sc[0], ang, sc[1], sc[2])
    print("  the thumb at rest: %s, %d of %d sampled pad points on the frame, %d of %d in the gun"
          % (best[1], best[2], len(sp), best[3], len(sa)))
    return pose_thumb(scan, rest, v, thumb, joints, best[1], hand_too=~thumb), best[1]


def thumb_cock(scan, fit, v, thumb, joints, gun, pose=True):
    """The thumb up on the hammer's spur: its joints' angles searched to bring its pad (the palm
    side of its tip) onto the spur without going into the gun. Returns the hand so posed (or,
    with `pose` false, the search's best: score, angles, mm off, points in the gun)."""
    import itertools
    t, th, r = scan.cyl(scan.v)
    u = (THUMB_REF - th) % 360
    um = u[thumb & (u < 300)]
    tipv = thumb & (u < 300) & (u > um.max() - 18)
    pad_i = np.nonzero(tipv & (r < np.percentile(r[tipv], 40)))[0]
    target = np.asarray(COCKING)
    rest = scan.v
    cands = []
    rng_ = {k: range(THUMB_OPEN[k][0], THUMB_OPEN[k][1] + 1, 10) for k in THUMB_OPEN}
    sub = pad_i[:: max(1, len(pad_i) // 6)]
    for sw, ro, mc, ip in itertools.product(rng_["swing"], rng_["root"], rng_["mcp"], rng_["ip"]):
        ang = {"swing": sw, "root": ro, "mcp": mc, "ip": ip}
        q_ = fit(pose_thumb(scan, rest[sub], v[sub], np.ones(len(sub), bool), joints, ang)).mean(0)
        cands.append((np.linalg.norm(q_ - target) * 1000, ang))
    cands.sort(key=lambda c: c[0])
    sample = np.nonzero(thumb)[0][::10]
    best = None
    for err, ang in cands[:25]:
        pts = fit(pose_thumb(scan, rest[sample], v[sample], np.ones(len(sample), bool), joints, ang))
        n_in = held_hand.inside(gun, pts, 0.0)
        score = err + n_in * 1.0
        if best is None or score < best[0]:
            best = (score, ang, err, n_in)
    if not pose:
        return best
    print("  thumb to the spur: %s, pad %.1f mm off, %d of %d sampled points in the gun"
          % (best[1], best[2], best[3], len(sample)))
    return pose_thumb(scan, rest, v, thumb, joints, best[1], hand_too=~thumb)


def parts_hand(scan, parts):
    h = np.zeros(len(scan.v), bool)
    h[:len(parts["hand"])] = parts["hand"]
    return h


def write(scan, fit, G, G_sq, G_ck, index, thumb, patch, gun):
    """Exports the hand (gun space), its shapes, the per-vertex numbers the skin shader reads,
    the cuff, the sleeve and a button; and the scan's maps as textures."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    F = scan.f
    t, th, r = scan.cyl(scan.v)
    N = held_hand.rest_normals(G, F.tolist())
    # The back of the hand and of the fingers face away from what they hold; the palm and the
    # fingers' pads toward it.
    axis_g = fit.R @ scan.d
    rel = G - fit(scan.q)
    radial = rel - np.outer(rel @ axis_g, axis_g)
    radial /= np.maximum(np.linalg.norm(radial, axis=1, keepdims=True), 1e-9)
    dorsal = np.clip(0.5 + (N * radial).sum(1) * 1.4, 0, 1)
    # The nails: the back of the thumb's and the index finger's last 13 mm.
    nails = np.zeros(len(G))
    for m in (thumb, index & ~patch):
        root = G[m].mean(0)
        tip = G[m][np.argmax(np.linalg.norm(G[m] - root, axis=1))]
        near = m & (np.linalg.norm(G - tip, axis=1) < 0.013)
        out = unit(tip - root)
        back = (N * radial).sum(1)
        nails = np.maximum(nails, near * np.clip((back - 0.15) / 0.3, 0, 1)
                           * np.clip(1 - np.linalg.norm(G - tip, axis=1) / 0.013, 0, 1) * 2)
    nails = np.clip(nails, 0, 1)
    off = np.abs(((th - 100 + 180) % 360) - 180)
    flush = np.clip((r - 40) / 8, 0, 1) * np.clip((45 - off) / 25, 0, 1) * 0.4
    ob = held_hand.mesh_object("Hand", G, F.tolist(), "scan_skin")
    me = ob.data
    uv = me.uv_layers.new(name="UVMap")
    uv.data.foreach_set("uv", scan.uv.reshape(-1))
    # How far along its digit each point of the index finger and thumb is from the nearest joint
    # (m): the skin shader draws the creases and the wrinkles over the knuckles by it, where the
    # rebuilt digits have no scan.
    crease = np.full(len(G), 0.02)
    for m, js, uf in ((index, [JOINTS["pip"], JOINTS["dip"]], lambda a: a),
                      (thumb, [THUMB_JOINTS["mcp"], THUMB_JOINTS["ip"]], lambda a: (THUMB_REF - a) % 360)):
        uu = uf(th)
        dist = np.min([np.abs(uu - j) for j in js], axis=0) * math.pi / 180 * np.maximum(r, 20) / 1000
        crease = np.where(m, np.minimum(dist, 0.02), crease)
    flag = me.uv_layers.new(name="patch")
    fl = patch[F].reshape(-1).astype(float)
    cr = crease[F].reshape(-1)
    flag.data.foreach_set("uv", np.stack([fl, cr], 1).reshape(-1))
    me.uv_layers.active = uv
    me.shade_smooth()
    ob.shape_key_add(name="Basis")
    for P, nm in ((G_sq, "trigger"), (G_ck, "thumb")):
        k = ob.shape_key_add(name=nm)
        k.data.foreach_set("co", np.stack([P[:, 0], -P[:, 2], P[:, 1]], 1).reshape(-1))
    hand_tree = BVHTree.FromPolygons([Vector(p) for p in G], F.tolist())
    held_hand.colours(ob, hand_tree, gun, nails, flush, dorsal)
    cloth(scan, fit, G)
    maps(scan)
    path = os.path.join(OUT, "hand.glb")
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_normals=True,
                              export_tangents=True, export_texcoords=True, export_materials="EXPORT",
                              export_vertex_color="ACTIVE", export_morph=True, export_morph_normal=True,
                              export_morph_tangent=False, export_animations=False, export_skins=False)
    print("wrote", path, len(G), "vertices,", len(F), "triangles")


def cloth(scan, fit, G):
    """The shirt's cuff over the cast's wrist cut, the coat's sleeve behind it, a button."""
    rel = np.asarray(WRIST_CUT) - scan.q
    W = fit(np.asarray(WRIST_CUT))
    d = unit(fit.R @ unit(np.asarray(WRIST_NORMAL)))            # out of the hand, up the arm
    along = (G - W) @ d
    near = (along > -0.03) & (along < 0.0)
    radial = (G[near] - W) - np.outer(along[near], d)
    r = float(np.percentile(np.linalg.norm(radial, axis=1), 97)) + 0.002
    rng = np.random.default_rng(1882)
    start = W - d * CUFF_OVER
    rings = [(0.004, r - 0.0012, 0.0), (0.0, r, 0.0), (0.003, r + 0.0035, 0.3), (0.05, r + 0.004, 0.4),
             (0.058, r + 0.002, 0.2), (0.07, r - 0.004, 0.0)]
    V, F = held_hand.cloth_tube(start, d, rings, rng, folds=0.0012)
    held_hand.mesh_object("Cuff", V, F, "cuff").data.shade_smooth()
    rs = r + 0.009
    rings = [(0.006, rs - 0.003, 0.0), (0.0, rs, 0.0), (0.005, rs + 0.006, 0.5), (0.03, rs + 0.008, 1.0),
             (0.08, rs + 0.01, 1.0), (0.16, rs + 0.016, 0.7), (0.26, rs + 0.022, 0.5)]
    V, F = held_hand.cloth_tube(start + d * 0.018, d, rings, rng, folds=held_hand.FOLDS)
    held_hand.mesh_object("Sleeve", V, F, "coat").data.shade_smooth()
    side = unit(np.cross(d, (0, 1, 0)))
    side = side if side @ np.array([1.0, 0, 0]) > 0 else -side
    up = unit(np.cross(side, d))
    at = start + d * 0.02 + unit(side * 0.6 + up * 0.8) * (r + 0.0045)
    V, F = held_hand.disc(at, unit(side * 0.6 + up * 0.8), 0.0045, 0.0018)
    held_hand.mesh_object("Button", V, F, "button").data.shade_smooth()
    print("  cuff %.1f mm round at the cast's wrist" % (r * 1000))


def maps(scan):
    """The scan's tangent-space normals, and its occlusion with the cast's own darkening in the
    creases (from its colour), as 2048 textures for the skin shader."""
    nrm = scan.images["normal"]
    nrm.scale(2048, 2048)
    nrm.filepath_raw = os.path.abspath(os.path.join(OUT, "hand_normal.png"))
    nrm.file_format = "PNG"
    nrm.save()
    occ, col = scan.images["occlusion"], scan.images["colour"]
    occ.scale(2048, 2048)
    col.scale(2048, 2048)
    o = np.array(occ.pixels[:]).reshape(2048, 2048, 4)[..., 0]
    c = np.array(col.pixels[:]).reshape(2048, 2048, 4)[..., :3].mean(-1)
    # Only the cast's fine shading (its creases and pores), not its patina's patches: the colour
    # less a blur of it (~1.5% of the texture across).
    k = 31
    pad = np.pad(c, k, mode="edge")
    cs = pad.cumsum(0).cumsum(1)
    blur = (cs[2 * k:, 2 * k:] - cs[:-2 * k, 2 * k:] - cs[2 * k:, :-2 * k] + cs[:-2 * k, :-2 * k]) / (2 * k) ** 2
    blur = blur[:2048, :2048]
    hp = c - blur
    sd = max(float(hp.std()), 1e-6)
    cav = np.clip(0.75 + hp / (4 * sd), 0, 1)
    img = bpy.data.images.new("cavity", 2048, 2048, alpha=False)
    px = np.stack([o, cav, np.zeros_like(o), np.ones_like(o)], -1).astype(np.float32)
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = os.path.abspath(os.path.join(OUT, "hand_cavity.png"))
    img.file_format = "PNG"
    img.save()


class Grip:
    """The grip's own parts (the walnut, the backstrap and the guard's front strap) as one tree."""

    def __init__(self):
        bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, "revolver.glb"))
        allv, allt = [], []
        for ob in bpy.context.scene.objects:
            if ob.type != "MESH" or ob.name not in ("Grips", "Backstrap", "Guard"):
                continue
            m = ob.matrix_world
            vs = [m @ v.co for v in ob.data.vertices]
            vs = [Vector((p.x, p.z, -p.y)) for p in vs]
            ob.data.calc_loop_triangles()
            for t in ob.data.loop_triangles:
                tri = [vs[i] for i in t.vertices]
                if ob.name == "Guard" and min(p.z for p in tri) < -0.003:
                    continue            # the bow, not the strap
                base = len(allv)
                allv += tri
                allt.append([base, base + 1, base + 2])
        for ob in list(bpy.context.scene.objects):
            bpy.data.objects.remove(ob)
        self.tree = BVHTree.FromPolygons(allv, allt)

    def ray_cast(self, *a):
        return self.tree.ray_cast(*a)


def show_on_gun(G, F, parts, out, gun=True, prefix=None):
    """Renders the fitted hand on the gun (Blender, for checking); without it, `bare_` views."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    if gun:
        bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, "revolver.glb"))
    metal = bpy.data.materials.new("metal")
    metal.use_nodes = True
    metal.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.15, 0.17, 0.2, 1)
    special = {}
    for nm, c in (("Guard", (0.8, 0.6, 0.1, 1)), ("Blade", (0.9, 0.1, 0.1, 1))):
        mt = bpy.data.materials.new(nm)
        mt.use_nodes = True
        mt.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = c
        special[nm] = mt
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            o.data.materials.clear()
            o.data.materials.append(special.get(o.name, metal))
    me = bpy.data.meshes.new("hand")
    me.from_pydata([(x, -z, y) for x, y, z in G], [], F.tolist())
    ob = bpy.data.objects.new("hand", me)
    bpy.context.scene.collection.objects.link(ob)
    col = np.tile([0.8, 0.62, 0.5, 1.0], (len(G), 1))
    col[parts["index"], :3] = (0.85, 0.5, 0.45)
    col[parts["patch"], :3] = (0.5, 0.8, 0.5)
    a = me.color_attributes.new("C", "FLOAT_COLOR", "POINT")
    a.data.foreach_set("color", col.ravel())
    B = lambda x, y, z: (x, -z, y)   # noqa: E731
    render_views(ob, B(0.0, -0.01, 0.0), [("right", B(1, 0.2, 0.1)), ("left", B(-1, 0.2, 0.1)),
                 ("eye", B(0.15, 0.5, 1)), ("front", B(0.2, 0.1, -1)), ("under", B(0.3, -1, 0.2)),
                 ("top", B(0.1, 1, 0.3))], out, prefix or ("gun" if gun else "bare"), 0.2)
    if not gun:
        return
    render_views(ob, B(*TRIGGER), [("cright", B(1, 0.1, 0.2)), ("cfront", B(0.3, 0.2, -1)),
                 ("cunder", B(0.4, -1, -0.3)), ("cleft", B(-1, 0.1, 0.1))], out, "gun", 0.1)


def show_parts(scan, parts, out, prefix="parts", faces=None):
    """Renders the scan coloured by part, from a few sides (for checking the growing)."""
    colours = {"index": (0.9, 0.2, 0.2), "thumb": (0.2, 0.4, 0.9), "middle": (0.2, 0.8, 0.3),
               "hand": (0.7, 0.7, 0.7)}
    col = np.ones((len(scan.v), 4))
    for k, m in parts.items():
        col[m, :3] = colours[k]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    me = bpy.data.meshes.new("scan")
    me.from_pydata(scan.v.tolist(), [], (scan.f if faces is None else faces).tolist())
    ob = bpy.data.objects.new("scan", me)
    bpy.context.scene.collection.objects.link(ob)
    a = me.color_attributes.new("C", "FLOAT_COLOR", "POINT")
    a.data.foreach_set("color", col.ravel())
    render_views(ob, scan.q + scan.d * 10, [("end", scan.d), ("front", -scan.u),
                 ("palm", -scan.w * 0.7 - scan.u * 0.7), ("side", scan.w), ("below", -scan.w),
                 ("back", scan.w * 0.3 + scan.u)], out, prefix, 140)


def render_views(ob, centre, views, out, prefix, scale, res=600):
    mat = bpy.data.materials.new("vc")
    mat.use_nodes = True
    nt = mat.node_tree
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "C"
    nt.links.new(vc.outputs[0], nt.nodes["Principled BSDF"].inputs["Base Color"])
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    for p in ob.data.polygons:
        p.use_smooth = True
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 8
    sc.render.resolution_x = sc.render.resolution_y = res
    wd = bpy.data.worlds.new("w")
    sc.world = wd
    wd.use_nodes = True
    wd.node_tree.nodes["Background"].inputs[1].default_value = 0.3
    for dd in [(1, 1, 2), (-1, -0.5, 1), (0, -1, -1), (0.5, 1, -1)]:
        L = bpy.data.objects.new("l", bpy.data.lights.new("l", "SUN"))
        L.data.energy = 2.0
        sc.collection.objects.link(L)
        L.rotation_euler = Vector(dd).to_track_quat("Z", "Y").to_euler()
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = scale
    cam.data.clip_end = 5000
    for name, dd in views:
        dd = Vector(unit(dd))
        cam.location = Vector(centre) + dd * (400 if scale > 1 else 1.0)
        cam.rotation_euler = (-dd).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(out, "%s_%s.png" % (prefix, name))
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
