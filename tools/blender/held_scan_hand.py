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
The handle's two stubs are cut off and their holes closed. The fist is set on the grip (the
handle's axis on the grip's centre line, the wrist behind it) and the flesh nearest the handle
pushed out to the grip's own shape (it's oval and bigger than a broom handle). The index finger is
found (grown over the scan from seeds on it, the thumb, the middle finger and the hand, the
borders falling in the creases), cut free where it touches the thumb and the middle finger (the
cuts closed), and opened out of the fist onto the trigger by turning its three joints about axes
along the handle, as a finger flexes round a thing it holds. The `trigger` shape closes it on the
trigger pulled back; `thumb` swings the thumb up onto the hammer's spur.
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
KNUCKLE_THETA = 105.0                 # the index finger leaves the hand here (theta): no cut before it

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
    used = np.unique(scan.f)
    remap = np.full(len(scan.v), -1)
    remap[used] = np.arange(len(used))
    scan.v = scan.v[used]
    scan.f = remap[scan.f]


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


def cap(bm, rims, step=1.2):
    """Closes each rim (a list of vertices in order) with a patch: rings stepping in to its middle,
    then faired from the rim inward. Returns the patch's new vertices."""
    uvl = bm.loops.layers.uv["UVMap"]
    new = []
    for rim in rims:
        rim = [v for i, v in enumerate(rim) if v is not rim[i - 1]]
        if len(rim) < 3:
            continue
        P = np.array([v.co[:] for v in rim])
        c = P.mean(0)
        span = np.linalg.norm(P - c, axis=1).mean()
        K = int(max(2, min(14, span / step)))
        rings = [rim]
        for k in range(1, K):
            s_ = k / K
            ring = [bm.verts.new(tuple(p * (1 - s_) + c * s_)) for p in P]
            new += ring
            rings.append(ring)
        mid = bm.verts.new(tuple(c))
        new.append(mid)
        n = len(rim)
        faces = []
        for a, b in zip(rings, rings[1:]):
            for i in range(n):
                j = (i + 1) % n
                for tri in ((a[i], a[j], b[j]), (a[i], b[j], b[i])):
                    try:
                        faces.append(bm.faces.new(tri))
                    except ValueError:
                        pass
        last = rings[-1]
        for i in range(n):
            try:
                faces.append(bm.faces.new((last[i], last[(i + 1) % n], mid)))
            except ValueError:
                pass
        for f in faces:
            for lp in f.loops:
                lp[uvl].uv = (0.0, 0.0)
    for _ in range(80):
        bmesh.ops.smooth_vert(bm, verts=new, factor=0.6, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return new


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


def close_stubs(scan):
    bm = to_bmesh(scan)
    n0 = len(bm.verts)
    rims = boundary_loops(bm)
    print("  stub holes: %s rims of %s vertices" % (len(rims), [len(r) for r in rims]))
    cap(bm, rims, step=1.5)
    from_bmesh(scan, bm)
    bm.free()
    return n0


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


def close_cut(scan, index, seam, thumb):
    """Closes the cut's sides apart: the index finger's, the thumb's and the middle finger's (and
    the palm's where the index's tip lay), each rim bridged along its length."""
    bm = to_bmesh(scan)
    bm.verts.ensure_lookup_table()
    is_index = lambda f: sum(index[v.index] for v in f.verts) >= 2   # noqa: E731
    rims = [(r_, index) for r_ in boundary_loops(bm, is_index, seam)]
    other = boundary_loops(bm, lambda f: not is_index(f), seam)
    # The other side's rims run over the thumb and the rest: bridge each body's part on its own.
    for r_ in other:
        lab = np.array([bool(thumb[v.index]) if v.index < len(thumb) else False for v in r_], float)
        k_ = 15
        sm = np.array([lab[max(0, i - k_):i + k_ + 1].mean() for i in range(len(lab))]) > 0.5
        start = 0
        for i in range(1, len(r_) + 1):
            if i == len(r_) or sm[i] != sm[start]:
                if i - start > 6:
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
    n_cut = len(scan.v)
    index, _ = close_cut(scan, index, seam, thumb)
    patch = np.zeros(len(scan.v), bool)
    patch[n_cut:] = True
    thumb = np.concatenate([thumb, np.zeros(len(scan.v) - len(thumb), bool)])
    m = scan.decimate(KEEP, {"index": index, "thumb": thumb, "patch": patch, "hand": parts_hand(scan, parts)})
    index, thumb, patch = m["index"], m["thumb"], m["patch"]
    parts = {"hand": m["hand"]}
    joints = index_joints(scan, index, patch)
    rest = scan.v.copy()
    rng = np.random.default_rng(3)
    hand_sample = rng.choice(np.nonzero(~index & ~patch)[0], 1500, replace=False)
    idx_sample = np.nonzero(index & ~patch)[0][::14]
    results = []
    for t0 in SEARCH_T:
        for roll in SEARCH_ROLL:
            fit = Fit(scan, t0, roll)
            push = grip_push(scan, fit, grip_parts)
            v = apply_push(scan, rest, push)
            scan.v = v
            j = {k: (apply_push(scan, x[None], push)[0]) for k, x in joints.items()}
            b = best_index(scan, fit, j, index, gun, v[idx_sample], top=12)
            n_hand = held_hand.inside(gun, fit(v[hand_sample]), 0.0)
            score = b[0] + n_hand * 0.4
            results.append((score, t0, roll, b, n_hand))
            print("  t0 %5.1f roll %5.1f: index %s %.1f mm off, %d in; hand %d of %d in -> %.1f"
                  % (t0, roll, b[1], b[2], b[3], n_hand, len(hand_sample), score))
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
    G = fit(v)
    sq = best_index(scan, fit, j, index, gun, scan.v[idx_sample], top=60, target=SQUEEZED, around=b[1])
    print("  squeezed: %s, pad %.1f mm off" % (sq[1], sq[2]))
    G_sq = fit(pose_index(scan, index, j, sq[1]))
    G_ck = thumb_up(scan, G, thumb, parts_hand(scan, parts), COCKING)
    if preview:
        show_on_gun(G, scan.f, {"index": index, "thumb": thumb, "patch": patch}, preview)
    write(scan, fit, G, G_sq, G_ck, index, thumb, patch, gun)


def parts_hand(scan, parts):
    h = np.zeros(len(scan.v), bool)
    h[:len(parts["hand"])] = parts["hand"]
    return h


def thumb_up(scan, G, thumb, hand, target):
    """The thumb swung up onto the hammer's spur: turned about its root (where it joins the hand)
    toward the spur, the turn fading in from the root to two thirds of the way out."""
    a, b, _ = neighbours(scan.f, len(scan.v))
    root = np.zeros(len(G), bool)
    for x, y in ((a, b), (b, a)):
        m = thumb[x] & hand[y]
        root[x[m]] = True
    B = G[root].mean(0)
    T = G[thumb][np.argmax(np.linalg.norm(G[thumb] - B, axis=1))]
    ax = np.cross(T - B, np.asarray(target) - B)
    ang = math.degrees(math.atan2(np.linalg.norm(ax), (T - B) @ (np.asarray(target) - B)))
    L = np.linalg.norm(T - B)
    f = np.clip(((G - B) @ unit(T - B)) / L, 0, 1)
    w = np.clip((f - 0.05) / 0.6, 0, 1)
    w = w * w * (3 - 2 * w) * thumb
    out = G.copy()
    for k in np.nonzero(w > 0)[0]:
        out[k] = B + rot(ax, ang * w[k]) @ (G[k] - B)
    print("  thumb: %.0f mm long, turned %.0f degrees up to the spur" % (L * 1000, ang))
    return out


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
    flag = me.uv_layers.new(name="patch")
    fl = np.repeat(patch[F].reshape(-1).astype(float), 1)
    flag.data.foreach_set("uv", np.stack([fl, np.zeros_like(fl)], 1).reshape(-1))
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


def show_on_gun(G, F, parts, out):
    """Renders the fitted hand on the gun (Blender, for checking)."""
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
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
                 ("top", B(0.1, 1, 0.3))], out, "gun", 0.2)
    render_views(ob, B(*TRIGGER), [("cright", B(1, 0.1, 0.2)), ("cfront", B(0.3, 0.2, -1)),
                 ("cunder", B(0.4, -1, -0.3)), ("cleft", B(-1, 0.1, 0.1))], out, "gun", 0.1)


def show_parts(scan, parts, out, prefix="parts"):
    """Renders the scan coloured by part, from a few sides (for checking the growing)."""
    colours = {"index": (0.9, 0.2, 0.2), "thumb": (0.2, 0.4, 0.9), "middle": (0.2, 0.8, 0.3),
               "hand": (0.7, 0.7, 0.7)}
    col = np.ones((len(scan.v), 4))
    for k, m in parts.items():
        col[m, :3] = colours[k]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    me = bpy.data.meshes.new("scan")
    me.from_pydata(scan.v.tolist(), [], scan.f.tolist())
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
