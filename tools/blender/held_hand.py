"""Your right hand round the modelled revolver, from MakeHuman's hand (CC0).

Run after held_revolver.py:  ~/bpyenv/bin/python tools/blender/held_hand.py
Writes assets/held/hand.glb: the hand and wrist (`Hand`, with shapes `trigger` and `thumb`), the
shirt's cuff and the coat's sleeve, in the gun's space (as src/weapons/hand_model.gd's code-built
hand is).

How: MakeHuman's base mesh (fetched by tools/blender/fetch_makehuman.py) gives the right hand and
the end of the forearm, and its joints give the bones: the wrist, a bone a finger segment from the
knuckle to the tip, the thumb's three. Each vertex is skinned to its bones by distance. Three of
the hand's joints are fitted to points on the grip (PLACE) and the hand pushed out along its palm
till the palm is clear of the gun; then the middle, ring and little fingers close as a hand closes
on a thing (their joints bending together, each stopping when it touches), so they wrap whatever
grip they're given, and the index finger and the thumb take the angles that bring their tips to
the trigger and the frame's left side (REACH) without going into the gun. The shapes are the same
searches to the trigger pulled back and to the hammer's spur.
The vertex colour carries what the skin shader needs: red the fingernails, green how open (the
gun counts: the hand is dark where it's against it), blue the knuckles' and fingertips' flush.
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
from make_people import MH, joint, load_obj, to_body_space  # noqa: E402

OUT = "assets/held"

# Where the hand goes on the gun (the gun's space: x right, y up, -z forward): three of its joints
# onto these points, fitted (rotation only; the hand keeps its shape at `scale`), then the hand is
# pushed out along its palm until nothing of the palm is in the gun.
PLACE = {
    "r-finger-2-1": (0.026, -0.020, -0.002),    # the index finger's knuckle, by the trigger guard
    "r-finger-5-1": (0.027, -0.074, 0.016),     # the little finger's, low on the front strap
    "r-hand": (0.016, -0.060, 0.098),           # the wrist, behind the grip
    "scale": 1.06,                              # MakeHuman's hand is small for a grown man's
}
# Where the index finger's pad and the thumb's tip go (the gun's space): each finger's angles are
# searched for the pose that brings it there without going into the gun.
REACH = {
    "index": (0.0, -0.0165, -0.0225),       # the trigger's face
    "thumb": (-0.0155, 0.012, -0.004),      # the frame's left side, under the cylinder's back
}
SQUEEZED = (0.0, -0.0175, -0.0175)          # the trigger's face pulled back (the `trigger` shape)
COCKING = (0.0, 0.066, 0.027)               # the hammer's spur (the `thumb` shape)
CLOSE = ["middle", "ring", "little"]        # these close till they touch
COUPLING = [1.0, 1.25, 0.8]                 # how the joints bend together as a finger closes
LIMIT = [95.0, 110.0, 80.0]                 # how far each can
ARM_FROM = 0.62                                  # how much of the forearm (0 elbow, 1 wrist) is kept
SUBDIV = 1

FINGERS = {"thumb": 1, "index": 2, "middle": 3, "ring": 4, "little": 5}


def unit(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)


def rot(axis, deg):
    a = unit(axis)
    t = math.radians(deg)
    k = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + math.sin(t) * k + (1 - math.cos(t)) * (k @ k)


class Hand:
    def __init__(self):
        v, uv, groups = load_obj(os.path.join(MH, "3dobjs/base.obj"))
        J = {n: to_body_space(joint(v, groups, n)) for n in
             ["r-elbow", "r-hand"] + ["r-finger-%d-%d" % (f, k) for f in range(1, 6) for k in range(1, 5)]}
        V = to_body_space(v)
        self.J = J
        # The faces of the hand and the end of the forearm.
        e, w = J["r-elbow"], J["r-hand"]
        axis = w - e
        t = ((V - e) @ axis) / (axis @ axis)
        faces = []
        for vi, ti in groups["body"]:
            near_axis = all(np.linalg.norm(np.cross(V[i] - e, axis)) / np.linalg.norm(axis) < 0.09 for i in vi)
            if all(t[i] > ARM_FROM for i in vi) and all(V[i][0] > 0.15 for i in vi) and near_axis:
                faces.append((vi, ti))
        used = sorted({i for vi, _ in faces for i in vi})
        remap = {o: n for n, o in enumerate(used)}
        self.v = V[used]
        self.faces = [[remap[i] for i in vi] for vi, _ in faces]
        self.t = t[used]
        print("hand: %d verts, %d faces" % (len(self.v), len(self.faces)))
        # Bones: (name, head, tail, parent).
        bones = [("arm", e, w, None), ("hand", w, J["r-finger-3-1"], "arm")]
        for name, f in FINGERS.items():
            parent = "hand"
            for k in range(3):
                bn = "%s%d" % (name, k)
                bones.append((bn, J["r-finger-%d-%d" % (f, k + 1)], J["r-finger-%d-%d" % (f, k + 2)], parent))
                parent = bn
        self.bones = {b[0]: {"head": b[1], "tail": b[2], "parent": b[3]} for b in bones}
        self.order = [b[0] for b in bones]
        self._frame()
        self._weights()

    def _frame(self):
        J = self.J
        W, M, I, L = J["r-hand"], J["r-finger-3-1"], J["r-finger-2-1"], J["r-finger-5-1"]
        long = unit(M - W)
        lat = L - I
        lat = unit(lat - long * (lat @ long))
        n = np.cross(long, lat)     # out of the palm (the fingers curl this way)
        self.rest_frame = np.stack([long, lat, n], 1)
        self.palm_n = n
        # Each finger's flex axis (curling toward the palm) and spread axis, at rest.
        for name in FINGERS:
            for k in range(3):
                b = self.bones["%s%d" % (name, k)]
                d = unit(b["tail"] - b["head"])
                b["flex"] = unit(np.cross(d, n)) if name != "thumb" else unit(np.cross(d, unit(n + lat * 0.8)))
                b["spread"] = unit(np.cross(d, b["flex"]))

    def _weights(self):
        names = self.order
        P = self.v
        D = np.zeros((len(P), len(names)))
        T = np.zeros((len(P), len(names)))
        for j, nme in enumerate(names):
            b = self.bones[nme]
            a, c = b["head"], b["tail"]
            ab = c - a
            t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
            D[:, j] = np.linalg.norm(P - (a + t[:, None] * ab), axis=1)
            T[:, j] = ((P - a) @ ab) / (ab @ ab)
        # Which chain each vertex belongs to: its nearest bone's.
        chain = [n.rstrip("012") for n in names]
        near = D.argmin(1)
        W = np.zeros_like(D)
        for i in range(len(P)):
            ch = chain[near[i]]
            allowed = [j for j, c in enumerate(chain) if c == ch or (ch in FINGERS and c == "hand")
                       or (ch == "hand" and c == "arm") or (ch == "arm" and c == "hand")]
            d = D[i, allowed] + 0.002
            w = (1.0 / d) ** 8
            w /= w.sum()
            W[i, allowed] = w
        # Keep each vertex's two strongest.
        idx = np.argsort(-W, 1)[:, 2:]
        np.put_along_axis(W, idx, 0.0, 1)
        W /= W.sum(1, keepdims=True)
        self.W = W
        self.D = D

    # --- Posing ------------------------------------------------------------------------------------

    def transforms(self, pose):
        """pose: {bone: 3x3 rotation about its head, in rest space}. → {bone: (R, t)} world maps."""
        out = {}
        for nme in self.order:
            b = self.bones[nme]
            R = pose.get(nme, np.eye(3))
            h = b["head"]
            local = (R, h - R @ h)
            if b["parent"]:
                PR, Pt = out[b["parent"]]
                out[nme] = (PR @ local[0], PR @ local[1] + Pt)
            else:
                out[nme] = local
        return out

    def skin(self, pose, place):
        X = self.transforms(pose)
        P = np.zeros_like(self.v)
        for j, nme in enumerate(self.order):
            R, t = X[nme]
            w = self.W[:, j]
            if w.any():
                P += w[:, None] * (self.v @ R.T + t)
        G, g = place
        return P @ G.T + g

    def joint_at(self, pose, place, nme):
        R, t = self.transforms(pose)[nme]
        G, g = place
        return G @ (R @ self.bones[nme]["head"] + t) + g


def placement(hand):
    """The rotation and shift that best lays the PLACE joints on their points (Kabsch)."""
    names = [k for k in PLACE if k != "scale"]
    A = np.array([hand.J[k] for k in names]) * PLACE["scale"]
    Bp = np.array([PLACE[k] for k in names])
    ca, cb = A.mean(0), Bp.mean(0)
    H = (A - ca).T @ (Bp - cb)
    U, _, Vt = np.linalg.svd(H)
    d = np.sign(np.linalg.det(Vt.T @ U.T))
    R = Vt.T @ np.diag([1, 1, d]) @ U.T
    G = R * PLACE["scale"]
    g = cb - R @ ca
    for k, b in zip(names, Bp):
        print("  %s lands %.1f mm off" % (k, np.linalg.norm(G @ hand.J[k] + g - b) * 1000))
    return G, g


def finger_rot(hand, name, k, flex, spread=0.0):
    b = hand.bones["%s%d" % (name, k)]
    return rot(b["flex"], flex) @ rot(b["spread"], spread)


# --- The gun, as something to touch ----------------------------------------------------------------

class Gun:
    """The modelled revolver as things to touch: one tree a part (each part is closed, so the
    nearest face's side says whether a point is in it; overlapping parts would fool one tree) and
    one for the whole, for the rays that shade."""

    def __init__(self):
        bpy.ops.import_scene.gltf(filepath=os.path.join(OUT, "revolver.glb"))
        self.parts = []
        allv, allt = [], []
        for ob in bpy.context.scene.objects:
            if ob.type != "MESH":
                continue
            m = ob.matrix_world
            vs = [m @ v.co for v in ob.data.vertices]
            vs = [Vector((p.x, p.z, -p.y)) for p in vs]   # Blender → the gun's (Godot) space
            ob.data.calc_loop_triangles()
            ts = [list(t.vertices) for t in ob.data.loop_triangles]
            a = np.array(vs)
            self.parts.append((BVHTree.FromPolygons(vs, ts), a.min(0) - 0.01, a.max(0) + 0.01))
            base = len(allv)
            allv += vs
            allt += [[base + i for i in t] for t in ts]
        for ob in list(bpy.context.scene.objects):
            bpy.data.objects.remove(ob)
        self.whole = BVHTree.FromPolygons(allv, allt)

    def ray_cast(self, *a):
        return self.whole.ray_cast(*a)


def inside(gun, pts, skin=0.0012):
    """How many points are in the gun or within `skin` of it."""
    n = 0
    for p in pts:
        for tree, lo, hi in gun.parts:
            if (p < lo).any() or (p > hi).any():
                continue
            loc, nrm, _, d = tree.find_nearest(Vector(p), 0.02)
            if loc is not None and (Vector(p) - loc).dot(nrm) < skin:
                n += 1
                break
    return n


def tip(hand, pose, place, name):
    R, t = hand.transforms(pose)["%s2" % name]
    G, g = place
    return G @ (R @ hand.bones["%s2" % name]["tail"] + t) + g


def reach(hand, place, pose, tree, name, target, pad=0.007):
    """The finger's angles (flex at each joint, spread at the first) that bring its tip within `pad`
    of the target, nearest first, the first that doesn't go into the gun. A coarse grid, then finer."""
    target = np.asarray(target, float)
    j = [n for n in hand.order if n.startswith(name)]
    mask = hand.W[:, [hand.order.index(n) for n in j]].sum(1) > 0.5
    best = None
    flex0 = range(-30, 91, 10) if name == "thumb" else range(-10, 81, 10)
    spread0 = range(-60, 61, 10) if name == "thumb" else range(-20, 21, 10)
    cands = []
    for f0 in flex0:
        for s0 in spread0:
            for f1 in range(0, 91, 10):
                for f2 in range(0, 71, 10):
                    trial = dict(pose)
                    trial[j[0]] = finger_rot(hand, name, 0, f0, s0)
                    trial[j[1]] = finger_rot(hand, name, 1, f1)
                    trial[j[2]] = finger_rot(hand, name, 2, f2)
                    d = abs(np.linalg.norm(tip(hand, trial, place, name) - target) - pad)
                    cands.append((d, (f0, s0, f1, f2)))
    cands.sort()
    for d, a in cands[:200]:
        trial = dict(pose)
        trial[j[0]] = finger_rot(hand, name, 0, a[0], a[1])
        trial[j[1]] = finger_rot(hand, name, 1, a[2])
        trial[j[2]] = finger_rot(hand, name, 2, a[3])
        if inside(tree, hand.skin(trial, place)[mask]) <= 2:
            best = (d, a)
            break
    if best is None:
        best = cands[0]
        print("  %s: nothing clear of the gun; nearest" % name)
    d, a = best
    print("  %s reaches within %.1f mm: flex %d, spread %d, %d, %d" % (name, d * 1000, a[0], a[1], a[2], a[3]))
    pose = dict(pose)
    pose[j[0]] = finger_rot(hand, name, 0, a[0], a[1])
    pose[j[1]] = finger_rot(hand, name, 1, a[2])
    pose[j[2]] = finger_rot(hand, name, 2, a[3])
    return pose


def close_fingers(hand, place, pose, tree):
    """Each finger in CLOSE closes as a hand does: all its joints bending together (COUPLING), a
    joint stopping when the segment past it touches the gun while the rest carry on. A finger that
    starts in the gun is first opened back until it's clear."""
    for name in CLOSE:
        bones = ["%s%d" % (name, k) for k in range(3)]
        masks = [hand.W[:, hand.order.index(b)] > 0.5 for b in bones]
        angles = [0.0, 0.0, 0.0]
        locked = [False, False, False]

        def trial(a):
            t = dict(pose)
            for k in range(3):
                t[bones[k]] = finger_rot(hand, name, k, a[k])
            return hand.skin(t, place)

        def touching(P, k):
            return inside(tree, P[masks[k]]) > 0

        for s0 in np.arange(0.0, -45.0, -3.0):
            a = [s0 * c for c in COUPLING]
            P = trial(a)
            if not any(touching(P, k) for k in range(3)):
                angles = a
                break
        for _ in range(60):
            if all(locked):
                break
            nxt = [angles[k] if locked[k] else min(angles[k] + 3.0 * COUPLING[k], LIMIT[k]) for k in range(3)]
            if nxt == angles:
                break
            P = trial(nxt)
            hit = [touching(P, k) for k in range(3)]
            if any(hit):
                # The first segment that touches stops its joint and every joint before it.
                first = hit.index(True)
                for k in range(first + 1):
                    locked[k] = True
                continue
            angles = nxt
        for k in range(3):
            pose[bones[k]] = finger_rot(hand, name, k, angles[k])
        print("  %s closes %s" % (name, " ".join("%.0f" % a for a in angles)))
    return pose


# --- Clothes ---------------------------------------------------------------------------------------

def tube(axis_from, axis_to, radii, sides=24):
    """Rings round an axis: radii [(t 0..1 along it, r, out-of-round)] → (verts, faces)."""
    a, b = np.asarray(axis_from, float), np.asarray(axis_to, float)
    d = unit(b - a)
    u = unit(np.cross(d, (0, 1, 0)))
    w = np.cross(u, d)
    V, F = [], []
    for t, r, flat in radii:
        c = a + (b - a) * t
        for k in range(sides):
            th = 2 * math.pi * k / sides
            V.append(c + u * math.cos(th) * r * (1 + flat) + w * math.sin(th) * r * (1 - flat))
    for i in range(len(radii) - 1):
        for k in range(sides):
            k2 = (k + 1) % sides
            F.append([i * sides + k, i * sides + k2, (i + 1) * sides + k2, (i + 1) * sides + k])
    return np.array(V), F


# --- Out ---------------------------------------------------------------------------------------

def mesh_object(name, V, F, mat):
    me = bpy.data.meshes.new(name)
    me.from_pydata([(x, -z, y) for x, y, z in V], [], F)   # the gun's space → Blender
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mt = bpy.data.materials.get(mat) or bpy.data.materials.new(mat)
    me.materials.append(mt)
    return ob


def subdivide(ob, levels):
    if levels <= 0:
        return
    m = ob.modifiers.new("subd", "SUBSURF")
    m.levels = levels
    m.render_levels = levels
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ob.modifiers.clear()
    old = ob.data
    ob.data = me
    bpy.data.meshes.remove(old)


def colours(ob, hand_tree, gun, nails, flush):
    """red nails, green openness (the gun and the hand both shade), blue flush."""
    me = ob.data
    m = ob.matrix_world
    rng = np.random.default_rng(1873)
    dirs = rng.normal(size=(32, 3))
    dirs /= np.linalg.norm(dirs, axis=1)[:, None]
    attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
    for i, v in enumerate(me.vertices):
        p = m @ v.co
        n = (m.to_3x3() @ v.normal).normalized()
        pg = Vector((p.x, p.z, -p.y))
        ng = Vector((n.x, n.z, -n.y))
        hit = 0.0
        for d in dirs:
            d = Vector(d)
            if d.dot(ng) < 0:
                d = -d
            for tree in (hand_tree, gun):
                loc, _, _, dist = tree.ray_cast(pg + ng * 0.0006, d, 0.03)
                if loc is not None:
                    hit += 1 - dist / 0.03
                    break
        attr.data[i].color = (float(nails[i]), 1.0 - hit / len(dirs), float(flush[i]), 1.0)
    me.color_attributes.active_color = attr


def main():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    gun = Gun()
    hand = Hand()
    place = placement(hand)
    # The palm against the grip: out along +x until nothing of it is in the gun.
    palm = hand.W[:, [hand.order.index(b) for b in ("hand", "arm", "thumb0")]].sum(1) > 0.5
    for f in ("index", "middle", "ring", "little"):
        palm |= np.linalg.norm(hand.v - hand.bones[f + "0"]["head"], axis=1) < 0.012
    G, g = place
    out = -unit(G @ hand.palm_n)       # away from the palm's face
    for dx in np.arange(-0.01, 0.03, 0.0005):
        if inside(gun, hand.skin({}, (G, g + out * dx))[palm], 0.0005) == 0:
            break
    place = (G, g + out * dx)
    print("palm out %.1f mm along %s" % (dx * 1000, np.round(out, 2)))
    pose = close_fingers(hand, place, {}, gun)
    pose = reach(hand, place, pose, gun, "index", REACH["index"])
    pose = reach(hand, place, pose, gun, "thumb", REACH["thumb"])
    base = hand.skin(pose, place)
    squeeze = hand.skin(reach(hand, place, pose, gun, "index", SQUEEZED), place)
    cocked = hand.skin(reach(hand, place, pose, gun, "thumb", COCKING, 0.009), place)
    print("touching the gun at rest:", inside(gun, base, 0.0))

    # Per-vertex: nails (the back of each finger's last segment, its last 45%), flush (knuckles, tips).
    nails = np.zeros(len(hand.v))
    flush = np.zeros(len(hand.v))
    for name, f in FINGERS.items():
        j = hand.order.index("%s2" % name)
        b = hand.bones["%s2" % name]
        ab = b["tail"] - b["head"]
        t = ((hand.v - b["head"]) @ ab) / (ab @ ab)
        back = (hand.v - (b["head"] + np.clip(t, 0, 1)[:, None] * ab)) @ (-hand.palm_n)
        own = hand.W[:, j] > 0.5
        nails = np.maximum(nails, own * np.clip((t - 0.5) / 0.15, 0, 1) * np.clip(back / 0.004, 0, 1))
        flush = np.maximum(flush, own * np.clip((t - 0.6) / 0.4, 0, 1) * 0.6)
        for k in (0, 1):
            h = hand.bones["%s%d" % (name, k + 1)]["head"]
            flush = np.maximum(flush, np.clip(1 - np.linalg.norm(hand.v - h, axis=1) / 0.012, 0, 1) * 0.5)

    ob = mesh_object("Hand", base, hand.faces, "skin")
    sq = mesh_object("_squeeze", squeeze, hand.faces, "skin")
    ck = mesh_object("_cock", cocked, hand.faces, "skin")
    # Carry the per-vertex numbers through the subdivision as UV channels.
    for o in (ob,):
        uvl = o.data.uv_layers.new(name="data")
        for poly in o.data.polygons:
            for li in poly.loop_indices:
                vi = o.data.loops[li].vertex_index
                uvl.data[li].uv = (nails[vi], flush[vi])
    for o in (ob, sq, ck):
        subdivide(o, SUBDIV)
        o.data.shade_smooth()
    # Shapes: the squeeze and the cock, from their subdivided twins.
    ob.shape_key_add(name="Basis")
    for twin, nm in ((sq, "trigger"), (ck, "thumb")):
        key = ob.shape_key_add(name=nm)
        for i, v in enumerate(twin.data.vertices):
            key.data[i].co = v.co
        bpy.data.objects.remove(twin)
    # Read the carried numbers back per vertex.
    me = ob.data
    nails_s = np.zeros(len(me.vertices))
    flush_s = np.zeros(len(me.vertices))
    for li, loop in enumerate(me.loops):
        u = me.uv_layers["data"].data[li].uv
        nails_s[loop.vertex_index] = u[0]
        flush_s[loop.vertex_index] = u[1]
    me.uv_layers.remove(me.uv_layers["data"])
    bm = bmesh.new()
    bm.from_mesh(me)
    hv = [Vector((v.co.x, v.co.z, -v.co.y)) for v in bm.verts]
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    hand_tree = BVHTree.FromPolygons(hv, [[v.index for v in f.verts] for f in bm.faces])
    bm.free()
    colours(ob, hand_tree, gun, nails_s, flush_s)

    # The shirt's cuff and the coat's sleeve round the forearm, from where the hand's mesh ends back.
    e = hand.joint_at(pose, place, "arm")
    w = hand.joint_at(pose, place, "hand")
    arm_len = np.linalg.norm(w - e)
    cut = e + (w - e) * 0.8
    back = e + (w - e) * (ARM_FROM - 0.9)
    r = 0.031 * PLACE["scale"]
    V, F = tube(cut, back, [(0.0, r * 1.02, 0.12), (0.02, r * 1.12, 0.12), (0.18, r * 1.14, 0.12),
                            (0.2, r * 1.05, 0.12), (0.22, r * 0.9, 0.1)])
    cuff = mesh_object("Cuff", V, F, "cuff")
    cuff.data.shade_smooth()
    sv = cut + (back - cut) * 0.17
    V, F = tube(sv, back, [(0.0, r * 1.18, 0.1), (0.015, r * 1.42, 0.1), (0.05, r * 1.5, 0.08),
                           (0.4, r * 1.62, 0.06), (1.0, r * 1.75, 0.05)])
    sleeve = mesh_object("Sleeve", V, F, "coat")
    sleeve.data.shade_smooth()
    print("forearm %.3f m; wrist at %s" % (arm_len, np.round(w, 3)))

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "hand.glb")
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_normals=True,
                              export_texcoords=False, export_materials="EXPORT", export_vertex_color="ACTIVE",
                              export_morph=True, export_morph_normal=True, export_animations=False,
                              export_skins=False)
    print("wrote", path, len(ob.data.vertices), "verts")


if __name__ == "__main__":
    main()
