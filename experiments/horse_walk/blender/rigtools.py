"""Posing the horse's armature in world terms (the glb's bone rolls are whatever the import made
them, so local axes aren't used): a bone turned about a world axis through its head, children
following; and the experiment's rig fixes (hind legs' hip and stifle, their skin weights).
"""
import math

import bpy
import numpy as np
from mathutils import Matrix, Vector

Y = Vector((0.0, 1.0, 0.0))


def turn(arm, name, degrees, axis=Y):
    """Turn a pose bone about a world axis through its head (positive = right-hand about axis;
    about +y that tips a downward bone's lower end forward, toward -x, the head)."""
    pb = arm.pose.bones[name]
    bpy.context.view_layer.update()
    m = pb.matrix.copy()
    h = m.translation.copy()
    r = Matrix.Rotation(math.radians(degrees), 4, axis)
    pb.matrix = Matrix.Translation(h) @ r @ Matrix.Translation(-h) @ m
    bpy.context.view_layer.update()


def reset(arm):
    for pb in arm.pose.bones:
        pb.location = (0, 0, 0)
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = (1, 0, 0, 0)
        pb.scale = (1, 1, 1)
    bpy.context.view_layer.update()


def head(arm, name):
    return arm.matrix_world @ arm.pose.bones[name].head


def tail(arm, name):
    return arm.matrix_world @ arm.pose.bones[name].tail


# --- the hind legs' fix -------------------------------------------------------------------------
# horse_rodin.py puts the stifle on the gaskin's line run on up from the hock, and the hip 12 cm
# behind it: on the left that line caught the tail (hip at x 1.05, behind the buttock), and on both
# sides the tibia stands upright where a horse's slopes down and back from a stifle at the flank.
# Anatomy (Sisson & Grossman's; Clayton's conformation figures): the hip joint at ~0.63 of the
# withers' height, a third of the way from the point of the hip to the point of the buttock; the
# stifle below and well forward of it, just under the belly's line; the tibia down and back to the
# hock.
HIND_FIX = {"hip": (0.74, 1.04), "stifle": (0.55, 0.82)}


def fix_hind(arm, meshes, fore=True):
    """Moves each hind's hip and stifle (x, z; its own y kept) and re-weights the quarters' and
    thighs' vertices to the moved bones; the lower leg's weights (hock down) and the tail's stay.
    With `fore`, the shoulders and fore legs are re-weighted the same way (reweight_fore)."""
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    for s in ("L", "R"):
        th, sh = eb["thigh." + s], eb["shin." + s]
        y_hip, y_st = th.head.y, th.tail.y
        th.head = Vector((HIND_FIX["hip"][0], y_hip, HIND_FIX["hip"][1]))
        th.tail = Vector((HIND_FIX["stifle"][0], (y_st + y_hip) / 2, HIND_FIX["stifle"][1]))
        sh.head = th.tail.copy()
    bpy.ops.object.mode_set(mode="OBJECT")
    import os
    for ob in meshes:
        if ob.name.startswith("coat"):
            png = "horse_coat_lod.png" if ob.name == "coat_lod" else "horse_coat.png"
            fix_tail(ob, arm, os.path.join(os.path.dirname(__file__), "..", "..", "..", "assets", "creatures", "horse", png))
        reweight_hind(ob, arm)
        if fore:
            reweight_fore(ob, arm)
        if ob.name.startswith("coat"):
            weld_weights(ob)


def _seg(p, a, b):
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(ab @ ab, 1e-9), 0.0, 1.0)
    return np.linalg.norm(p - (a + t[:, None] * ab), axis=1)


def coincident(P, tol=0.003):
    """Groups (len > 1) of vertices within `tol` of each other: the glb's copies at UV seams (some
    exact, some a millimetre or two apart after the decimation)."""
    from scipy.spatial import cKDTree
    par = list(range(len(P)))

    def find(a):
        while par[a] != a:
            par[a] = par[par[a]]
            a = par[a]
        return a
    for i, j in cKDTree(P).query_pairs(tol):
        a, b = find(i), find(j)
        if a != b:
            par[a] = b
    groups = {}
    for i in range(len(P)):
        groups.setdefault(find(i), []).append(i)
    return [v for v in groups.values() if len(v) > 1]


def weld_weights(ob):
    """Every group of seam copies given one weighting (their mean): the game's glb has copies that
    disagree (up to 0.26 on the neck, head and forearm), and a seam opens wherever they do."""
    names = {g.index: g.name for g in ob.vertex_groups}
    P = np.array([v.co[:] for v in ob.data.vertices])
    n = 0
    for twins in coincident(P):
        avg = {}
        for t in twins:
            for g in ob.data.vertices[t].groups:
                avg[names[g.group]] = avg.get(names[g.group], 0.0) + g.weight / len(twins)
        top = sorted(avg.items(), key=lambda kv: -kv[1])[:4]
        tot = sum(v for _, v in top)
        for t in twins:
            for g in list(ob.data.vertices[t].groups):
                ob.vertex_groups[g.group].remove([int(t)])
            for name, v in top:
                ob.vertex_groups[name].add([int(t)], v / tot, "REPLACE")
        n += 1
    return n


def neighbours(ob, P):
    nb = [set() for _ in P]
    for e in ob.data.edges:
        a, b = e.vertices
        nb[a].add(b)
        nb[b].add(a)
    for twins in coincident(P):
        allnb = set().union(*(nb[t] for t in twins))
        for t in twins:
            nb[t] |= allnb - {t}
    return [list(x) for x in nb]


def tail_vertices(ob, png):
    """The tail's hair: dark in the coat's paint, near the midline, behind the buttock."""
    from PIL import Image
    img = np.asarray(Image.open(png).convert("RGB"), float) / 255.0
    h, w = img.shape[:2]
    uv = ob.data.uv_layers[0].data
    lum = np.zeros(len(ob.data.vertices))
    for poly in ob.data.polygons:
        for li, vi in zip(poly.loop_indices, poly.vertices):
            u, v = uv[li].uv
            px = img[min(h - 1, max(0, int((1 - v) * h))), min(w - 1, max(0, int(u * w)))]
            lum[vi] = px.mean()
    P = np.array([v.co[:] for v in ob.data.vertices])
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    seg = {b.name: (np.array(b.head_local[:]), np.array(b.tail_local[:])) for b in arm.data.bones}
    d_tail = np.min([_seg(P, *seg[n]) for n in seg if n.startswith("tail")], axis=0)
    d_leg = np.min([_seg(P, *seg[n]) for n in seg if n.split(".")[0] in ("thigh", "shin", "hcannon", "hpastern")], axis=0)
    return ((lum < 0.3) & (np.abs(P[:, 1]) < 0.10) & (P[:, 0] > 0.72) & (P[:, 2] > 0.4) & (P[:, 2] < 1.5)
            & (d_tail < d_leg))


def fix_tail(ob, arm, png, power=4.0):
    """The tail's hair weighted to the tail's bones only (some of it had none: the legs took it)."""
    tv = np.where(tail_vertices(ob, png))[0]
    P = np.array([v.co[:] for v in ob.data.vertices])
    names = [b.name for b in arm.data.bones if b.name.startswith("tail")]
    for n in names:
        if n not in ob.vertex_groups:
            ob.vertex_groups.new(name=n)
    d = np.stack([_seg(P[tv], np.array(arm.data.bones[n].head_local[:]), np.array(arm.data.bones[n].tail_local[:]))
                  for n in names], axis=1)
    w = 1.0 / np.maximum(d, 0.02) ** power
    w /= w.sum(axis=1, keepdims=True)
    for k, i in enumerate(tv):
        for g in list(ob.data.vertices[int(i)].groups):
            ob.vertex_groups[g.group].remove([int(i)])
        top = np.argsort(-w[k])[:2]
        tot = w[k, top].sum()
        for j in top:
            ob.vertex_groups[names[j]].add([int(i)], float(w[k, j] / tot), "REPLACE")
    return len(tv)


def reweight_hind(ob, arm, power=2.0, smooth=12):
    """The quarters and each hind leg, hip to hoof (behind x 0.25, below the croup, not the tail's
    hair), re-weighted among pelvis, thigh, shin, hcannon, hpastern and hhoof of their side by
    inverse distance to each bone, then smoothed over the mesh."""
    vg = {g.name: g.index for g in ob.vertex_groups}
    leg = ("thigh", "shin", "hcannon", "hpastern", "hhoof")
    for n in ["pelvis"] + ["%s.%s" % (b, s) for b in leg for s in "LR"]:
        if n not in vg:
            vg[n] = ob.vertex_groups.new(name=n).index
    names = {i: n for n, i in vg.items()}
    P = np.array([v.co[:] for v in ob.data.vertices])
    W = [dict((names[g.group], g.weight) for g in v.groups) for v in ob.data.vertices]
    tailw = np.array([sum(w for n, w in d.items() if n.startswith("tail")) for d in W])
    bones = {b.name: (np.array(b.head_local[:]), np.array(b.tail_local[:])) for b in arm.data.bones}
    region = (P[:, 0] > 0.25) & (P[:, 2] < 1.42) & (tailw < 0.05)
    new = {}
    for s, sign in (("L", -1.0), ("R", 1.0)):
        side = region & (P[:, 1] * sign > -0.02)
        cand = ["pelvis"] + ["%s.%s" % (b, s) for b in leg]
        d = np.stack([_seg(P, *bones[c]) for c in cand], axis=1)
        # the pelvis bone runs along the back: measure the quarters' mass to a point inside the
        # croup instead, so the thigh doesn't take the top of the croup
        d[:, 0] = np.minimum(d[:, 0], np.linalg.norm(P - np.array([0.62, 0.0, 1.3]), axis=1))
        w = 1.0 / np.maximum(d, 0.015) ** power
        w /= w.sum(axis=1, keepdims=True)
        for i in np.where(side)[0]:
            # the legs stay off the far side: a vertex past the midline only to the pelvis
            new[i] = {"pelvis": 1.0} if P[i, 1] * sign < 0.0 else dict(zip(cand, w[i]))
    _smooth_apply(ob, P, W, new, vg, smooth)
    # the tail's vertices lose any leg weight they had
    for i in np.where(tailw >= 0.05)[0]:
        for g in list(ob.data.vertices[i].groups):
            if names.get(g.group, "").split(".")[0] in ("thigh", "shin"):
                ob.vertex_groups[g.group].remove([int(i)])
    return len(new)


def reweight_fore(ob, arm, power=2.0, smooth=12, radius=0.03):
    """The shoulders and each fore leg, withers to the forearm's lower half, re-weighted among the
    trunk (spine), scapula, upperarm and forearm of their side by inverse distance, then smoothed.
    The game's weights put a hard edge between the leg and the chest at the elbow and the shoulder:
    when the fore reaches, the top of the leg hinged under the chest (Sean, #474).

    Smoothed in space, not over the mesh's edges as the hinds are: the glb is split into islands at
    its UV seams, and most of the shoulder's seams don't meet vertex to vertex (a vertex on one side
    lies on an edge of the other, 3-20 mm from any twin), so weights smoothed island by island
    differ across a seam and it opens (a hole at the elbow's back, seen in the close render). Each
    pass averages a vertex's weights with every region vertex within `radius` (any island), Gaussian.
    The new weights are blended into the game's over the region's edges (the knee down, and the
    neck's and head's skin, keep theirs), so no edge of the region is a step either.
    Coat only (the saddle and girth stay on the trunk)."""
    if not ob.name.startswith("coat"):
        return 0
    from scipy.spatial import cKDTree
    vg = {g.name: g.index for g in ob.vertex_groups}
    leg = ("scapula", "upperarm", "forearm")
    for n in ["spine"] + ["%s.%s" % (b, s) for b in leg for s in "LR"]:
        if n not in vg:
            vg[n] = ob.vertex_groups.new(name=n).index
    names = {i: n for n, i in vg.items()}
    P = np.array([v.co[:] for v in ob.data.vertices])
    W = [dict((names[g.group], g.weight) for g in v.groups) for v in ob.data.vertices]
    headw = np.array([sum(w for n, w in d.items() if n.startswith(("neck", "head", "ear"))) for d in W])
    bones = {b.name: (np.array(b.head_local[:]), np.array(b.tail_local[:])) for b in arm.data.bones}
    # how much of the new weighting a vertex takes: all of it inside, ramped to none over 12 cm
    # above the knee's line, 10 cm behind the girth, and as the neck's or head's weight rises
    ramp = lambda x: np.clip(x, 0.0, 1.0)  # noqa: E731
    f = (ramp((P[:, 2] - 0.62) / 0.12) * ramp((-0.25 - P[:, 0]) / 0.10) * ramp((1.15 + P[:, 0]) / 0.08)
         * ramp((1.55 - P[:, 2]) / 0.08) * ramp(1.0 - headw / 0.3))
    region = np.where(f > 0.0)[0]
    # the trunk's distance: to its bones along the back, or to the barrel's axis at the elbow's
    # height (so the chest wall behind the elbow shares the leg's turn rather than all or nothing)
    axis = (np.array([-1.0, 0.0, 1.0]), np.array([-0.25, 0.0, 1.0]))
    d_trunk = np.min([_seg(P, *bones["spine"]), _seg(P, *bones["chest"]), _seg(P, *axis)], axis=0)
    cols = ["spine"] + ["%s.%s" % (b, s) for s in "LR" for b in leg]
    M = np.zeros((len(P), len(cols)))
    M[:, 0] = 1.0
    for s, sign in (("L", -1.0), ("R", 1.0)):
        cand = ["spine"] + ["%s.%s" % (b, s) for b in leg]
        d = np.stack([d_trunk] + [_seg(P, *bones[c]) for c in cand[1:]], axis=1)
        w = 1.0 / np.maximum(d, 0.015) ** power
        w /= w.sum(axis=1, keepdims=True)
        # each side's leg on its own side only; at the midline, the trunk (smoothing joins them)
        mine = P[:, 1] * sign > 0.0
        M[mine] = 0.0
        M[np.ix_(mine, [cols.index(c) for c in cand])] = w[mine]
    # the game's weights where the region fades out, in the same columns plus whatever else they hold
    Q = P[region]
    tree = cKDTree(Q)
    pairs = tree.query_ball_point(Q, radius * 2.0)
    g = [np.exp(-0.5 * (np.linalg.norm(Q[nb] - Q[k], axis=1) / radius) ** 2) for k, nb in enumerate(pairs)]
    Mr = M[region]
    for _ in range(smooth):
        Mr = np.array([(gk[:, None] * Mr[nb]).sum(axis=0) / gk.sum() for nb, gk in zip(pairs, g)])
    for k, i in enumerate(region):
        mixed = {n: (1.0 - f[i]) * v for n, v in W[i].items()}
        for c, n in enumerate(cols):
            if Mr[k, c] > 0.0:
                mixed[n] = mixed.get(n, 0.0) + f[i] * Mr[k, c]
        for gg in list(ob.data.vertices[int(i)].groups):
            ob.vertex_groups[gg.group].remove([int(i)])
        top = sorted(mixed.items(), key=lambda kv: -kv[1])[:4]
        tot = sum(v for _, v in top)
        for n, v in top:
            if v / tot > 1e-3:
                if n not in vg:
                    vg[n] = ob.vertex_groups.new(name=n).index
                ob.vertex_groups[vg[n]].add([int(i)], v / tot, "REPLACE")
    return len(region)


def _smooth_apply(ob, P, W, new, vg, smooth):
    """`new` (vertex -> {group: weight}) smoothed `smooth` times over the mesh's edges inside it,
    seam copies given one weighting, then written (each vertex's top four, normalised)."""
    # smoothing over the mesh's edges inside the region (the glb's vertices are split at UV seams:
    # copies of one point are joined here, or a seam opens when the weights on its sides differ)
    nb = neighbours(ob, P)
    for _ in range(smooth):
        upd = {}
        for i, ww in new.items():
            acc = dict(ww)
            cnt = 1
            for j in nb[i]:
                if j in new:
                    for n, v in new[j].items():
                        acc[n] = acc.get(n, 0.0) + v
                    cnt += 1
            upd[i] = {n: v / cnt for n, v in acc.items()}
        new = upd
    for twins in coincident(P):
        if any(t in new for t in twins):
            avg = {}
            for t in twins:
                for n, v in new.get(t, W[t]).items():
                    avg[n] = avg.get(n, 0.0) + v / len(twins)
            for t in twins:
                new[t] = avg
    for i, ww in new.items():
        for g in list(ob.data.vertices[i].groups):
            ob.vertex_groups[g.group].remove([int(i)])
        top = sorted(ww.items(), key=lambda kv: -kv[1])[:4]
        tot = sum(v for _, v in top)
        for n, v in top:
            if v / tot > 1e-3:
                ob.vertex_groups[vg[n]].add([int(i)], v / tot, "REPLACE")
