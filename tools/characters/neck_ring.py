"""A painted head on a base body through the neck ring (docs/briefs/layered-people.md, option 2).

    ~/bpyenv/bin/python tools/characters/neck_ring.py --body=bold_cowboy_body \\
        --head=bold_cowboy_painterly_lit --out=bold_cowboy_layered

- The base body (assets/people/<body>.glb, fitted by tools/blender/fit_tripo.py) comes in two
  meshes, `body_skin` and `body_head`. The **neck ring** is a level cut RING_BELOW_CHIN under the
  laid head's chin: his old head's neck joins body_skin up to it (the body keeps its own neck,
  painted from the body's pictures), and everything of him above it goes.
- The painted head (rodin_portrait.py's bust and paint: build/rodin_portrait/<head>_mesh.npy and
  _paint.png) is laid where his own head was: a similarity (turn, scale, move) fitted by nearest
  points (ICP) from the bust's head (above its chin) to the body's head, so any head of the same
  build lands where the body expects it.
- Cut at the ring: the bust's triangles below the ring's height go; its new open edge is pulled
  onto the ring (each vertex to the ring's point at its angle round the neck), and the pull fades
  out over RING_BLEND above it, so the seam closes with no gap or step.
- His painted collar under his jaw (the paintings show him dressed) faded to the body's skin.
- Skinned as his own head was (each vertex the weights of the nearest vertex of his old head;
  within RING_BLEND of the ring, of the nearest of either mesh), decimated to HEAD_TRIS.
→ assets/people/<out>.glb (`body_skin`, `body_head`), <out>_skin.png (the body's), <out>_head.png
  (the paint), <out>.json (the body's report).
"""
import json
import math
import os
import shutil
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
WORK = os.path.join(ROOT, "build", "rodin_portrait")
PEOPLE = os.path.join(ROOT, "assets", "people")
HEADS = os.path.join(PEOPLE, "heads")   # painted busts kept for the ring (see LAYERED.md)
RING_BLEND = 0.045     # metres above the ring over which the head's neck is pulled onto it
RING_BELOW_CHIN = 0.03 # the ring's height: this far under the laid head's chin (his body keeps its neck)
NECK_FADE = 0.015      # metres under his jaw over which his painted collar fades to skin
HEAD_TRIS = 12000
COLLAR_BAND = 0.05     # metres either side of the ring: garment points pushed out of the head's neck (collar_out)
COLLAR_CLEAR = 0.004   # ... to this far outside it
COLLAR_UP = 0.012      # a vest's or coat's faces reaching more than this above the ring are cut (a shirt's: above it)
COLLAR_H = 0.022        # metres his shirt's stand-up collar rises above the ring (stand_collar) ...
COLLAR_FROM = 0.035    # ... from this far below it (over the shirt's own top)
COLLAR_ROWS = 4
COLLAR_SIDES = 40
COLLAR_FLARE = 0.004   # metres its top is turned out
COLLAR_SMOOTH = 0.09       # --collar=smooth: metres under the ring smoothed ...
COLLAR_SMOOTH_FADE = 0.02   # ... faded in over this
COLLAR_SMOOTH_UP = 0.045   # ... its front's top this far above the ring ...
COLLAR_SMOOTH_BACK = 0.015  # ... its back's
COLLAR_SMOOTH_STEPS = 12
ICP_ROUNDS = 40


def similarity(src, dst):
    """Scale s, rotation R, translation t with s R src + t ≈ dst (Umeyama)."""
    ms, md = src.mean(0), dst.mean(0)
    a, b = src - ms, dst - md
    U, S, Vt = np.linalg.svd(b.T @ a / len(src))
    d = np.sign(np.linalg.det(U @ Vt))
    D = np.diag([1, 1, d])
    R = U @ D @ Vt
    s = np.trace(np.diag(S) @ D) / (a ** 2).sum(1).mean()
    return s, R, md - s * R @ ms


def icp(src, dst, rounds=ICP_ROUNDS):
    from scipy.spatial import cKDTree
    tree = cKDTree(dst)
    s, R, t = 1.0, np.eye(3), dst.mean(0) - src.mean(0)     # start: the two centred on each other
    for _ in range(rounds):
        cur = s * src @ R.T + t
        d, j = tree.query(cur)
        keep = d < np.percentile(d, 85)        # the bust's neck and hair edges have no partner
        s, R, t = similarity(src[keep], dst[j[keep]])
    err = float(np.median(tree.query(s * src @ R.T + t)[0]))
    return s, R, t, err


T0 = __import__("time").time()


def mark(what):
    print("neck_ring: %5.0f s  %s" % (__import__("time").time() - T0, what), flush=True)


def stand_collar(bpy, shirt, head, tree, centre, ring_z, shirt_png):
    """His shirt's stand-up collar, built: the twin's came apart in shards against his jaw (cut
    in collar_out). A band round his neck from COLLAR_FROM below the ring to COLLAR_H above it,
    at each of COLLAR_SIDES angles COLLAR_CLEAR outside the head's surface there (a ray out from
    his neck's middle), its top turned out a little; in his shirt's white (the UV of the shirt's
    lightest place near his throat), weighted as the head's nearest point is."""
    import bmesh
    from mathutils import Vector
    me = shirt.data
    uvl = me.uv_layers.active
    # His shirt's white: the lightest-looking UV near the front of his neck (its texture is in
    # the material, not here; the collar's own points near his throat are white by the cut).
    from PIL import Image
    tex = np.asarray(Image.open(shirt_png).convert("RGB")).astype(float) / 255
    th, tw = tex.shape[:2]
    uvs = np.array([uvl.data[l.index].uv[:] for l in me.loops])
    # glTF's v runs down (the import flips it): the texel under each loop's UV.
    px = tex[np.clip(((1 - uvs[:, 1]) * th).astype(int), 0, th - 1), np.clip((uvs[:, 0] * tw).astype(int), 0, tw - 1)]
    light = px.mean(1) - (px.max(1) - px.min(1))          # light and colourless: his shirt's cloth
    from mathutils import Vector as _V
    uv_white = _V(uvs[int(np.argsort(light)[int(0.97 * (len(light) - 1))])])
    hgroups = {g.index: g.name for g in head.vertex_groups}
    hv = np.array([v.co[:] for v in head.data.vertices])
    from scipy.spatial import cKDTree
    htree = cKDTree(hv)
    for name in hgroups.values():
        if name not in shirt.vertex_groups:
            shirt.vertex_groups.new(name=name)
    bm = bmesh.new()
    bm.from_mesh(me)
    deform = bm.verts.layers.deform.verify()
    uv_layer = bm.loops.layers.uv[uvl.name]
    rows = []
    zs = np.linspace(ring_z - COLLAR_FROM, ring_z + COLLAR_H, COLLAR_ROWS)
    for k, z in enumerate(zs):
        row = []
        for j in range(COLLAR_SIDES):
            a = 2 * np.pi * j / COLLAR_SIDES
            d = Vector((np.cos(a), np.sin(a), 0.0))
            start = Vector((centre[0], centre[1], z))
            # His neck's outermost surface at this angle (cast in from outside: from the middle,
            # the first hit missed folds of the head's edge standing further out, which came
            # through the collar).
            far = start + d * 0.3
            hit, _n, _f, back = tree.ray_cast(far, -d, 0.3)
            dist = 0.3 - back if hit is not None else None
            if hit is None:
                # Below the head's lowest edge: his body's neck under the old collar, from the head's
                # nearest ring point's distance.
                dist = float(np.median(np.linalg.norm((hv[np.abs(hv[:, 2] - ring_z) < 0.01] - centre)[:, :2], axis=1)))
            flare = COLLAR_FLARE * max(0.0, (z - ring_z) / COLLAR_H)
            p = start + d * (dist + COLLAR_CLEAR + flare)
            v = bm.verts.new(p)
            _dd, hi = htree.query(p[:])
            for ge in head.data.vertices[int(hi)].groups:
                gname = hgroups[ge.group]
                v[deform][shirt.vertex_groups[gname].index] = ge.weight
            row.append(v)
        rows.append(row)
    n = 0
    for k in range(len(rows) - 1):
        for j in range(COLLAR_SIDES):
            a, b = rows[k][j], rows[k][(j + 1) % COLLAR_SIDES]
            c, d = rows[k + 1][(j + 1) % COLLAR_SIDES], rows[k + 1][j]
            f = bm.faces.new((a, b, c, d))
            for l in f.loops:
                l[uv_layer].uv = uv_white
            n += 1
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    me.update()
    print("neck_ring: his shirt's stand-up collar: %d faces, %.0f mm high" % (2 * n, 1000 * (COLLAR_H + COLLAR_FROM)))


def smooth_collar(me, ring_z):
    """His shirt's own collar and tie knot smoothed (--collar=smooth): the coatless twin drew them
    as thin slivers standing off the cloth (Sean, 2026-10-17: the built collar is "a flat straight
    piece"). Taubin smoothing (Taubin 1995: a shrink step then an inflate step, so the shape keeps
    its size) of what lies above COLLAR_SMOOTH under the ring, over points welded by place (Rodin's
    triangles share none), faded in over COLLAR_SMOOTH_FADE."""
    co = np.array([v.co[:] for v in me.vertices])
    _u, weld = np.unique(np.round(co / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    weld = weld.ravel()
    n = weld.max() + 1
    pos = np.zeros((n, 3))
    np.add.at(pos, weld, co)
    pos /= np.bincount(weld, minlength=n)[:, None]
    edges = set()
    for p in me.polygons:
        w = [weld[i] for i in p.vertices]
        for a, b in zip(w, w[1:] + w[:1]):
            if a != b:
                edges.add((min(a, b), max(a, b)))
    e = np.array(sorted(edges))
    nbr = [[] for _ in range(n)]
    for a, b in e:
        nbr[a].append(b)
        nbr[b].append(a)
    fade = np.clip((pos[:, 2] - (ring_z - COLLAR_SMOOTH)) / COLLAR_SMOOTH_FADE, 0, 1)
    live = np.nonzero(fade > 0)[0]
    for _ in range(COLLAR_SMOOTH_STEPS):
        for lam in (0.5, -0.53):
            avg = np.array([pos[nbr[i]].mean(0) if nbr[i] else pos[i] for i in live])
            pos[live] += (lam * fade[live])[:, None] * (avg - pos[live])
    for i, v in enumerate(me.vertices):
        v.co = pos[weld[i]].tolist()
    print("neck_ring: his shirt's collar smoothed: %d points" % len(live))


def collar_out(bpy, head, ring_z, shirt_png, mode="built"):
    """His shirt's collar (and a coat's or vest's) outside his new head's neck: the bust's neck
    is a little fuller than the body's, so a collar laid on the body's neck came out under it
    (his neck showed orange where the collar should stand). Garment points within COLLAR_BAND of
    the ring pushed COLLAR_CLEAR outside the head's surface (out from his neck's middle; the
    bust's faces are wound either way); and what of a garment stands more than COLLAR_UP above
    the ring is cut (shards of the twin's collar against his jaw)."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    hv = [v.co.copy() for v in head.data.vertices]
    tree = BVHTree.FromPolygons(hv, [tuple(p.vertices) for p in head.data.polygons])
    neck = np.array([v[:] for v in hv])
    band = np.abs(neck[:, 2] - ring_z) < 0.02
    centre = neck[band].mean(0) if band.any() else neck.mean(0)
    for ob in [o for o in bpy.data.objects if o.type == "MESH" and o.name in ("body_shirt", "body_vest", "body_coat")]:
        me = ob.data
        moved = 0
        if mode == "smooth" and ob.name == "body_shirt":
            smooth_collar(me, ring_z)
        for v in me.vertices:
            p = v.co
            if abs(p.z - ring_z) > COLLAR_BAND:
                continue
            loc, _n, _f, _d = tree.find_nearest(p, 0.06)
            if loc is None:
                continue
            out = Vector((p.x - centre[0], p.y - centre[1], 0.0))
            if out.length < 1e-6:
                continue
            out.normalize()
            depth = (p - loc).dot(out)
            if depth < COLLAR_CLEAR:
                v.co = p + out * (COLLAR_CLEAR - depth)
                moved += 1
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(me)
        # (A shirt's own collar, ragged, is replaced by the built one: cut from a little above
        # where that starts.)
        if ob.name == "body_shirt" and mode == "built":
            top = ring_z - COLLAR_FROM + 0.008
        elif ob.name == "body_shirt" and mode == "smooth":
            top = ring_z + COLLAR_SMOOTH_UP     # smoothed, no shards left to cut: it stands to his jaw
        else:
            top = ring_z + COLLAR_UP
        if ob.name == "body_shirt" and mode == "smooth":
            # Lower behind: his collar's back stands COLLAR_SMOOTH_BACK above the ring, its front
            # COLLAR_SMOOTH_UP (the twin's collar is shredded high at his nape, white spikes by
            # his hair). Front is where his jaw reaches, over his neck.
            jaw = neck[(neck[:, 2] > ring_z + 0.03) & (neck[:, 2] < ring_z + 0.08)]
            fwd = jaw[:, :2].mean(0) - centre[:2]
            fwd = fwd / max(np.linalg.norm(fwd), 1e-6)
            def top_at(p):
                d = np.array([p.x - centre[0], p.y - centre[1]])
                c = float(d @ fwd) / max(np.linalg.norm(d), 1e-6)          # 1 in front, -1 behind
                return ring_z + COLLAR_SMOOTH_BACK + (COLLAR_SMOOTH_UP - COLLAR_SMOOTH_BACK) * max(c, 0.0) ** 2
            high = [f for f in bm.faces if any(vv.co.z > top_at(vv.co) for vv in f.verts)]
        else:
            high = [f for f in bm.faces if any(vv.co.z > top for vv in f.verts)]
        bmesh.ops.delete(bm, geom=high, context="FACES")
        bm.to_mesh(me)
        bm.free()
        me.update()
        print("neck_ring: %s collar: %d points out of his neck, %d faces above it cut" % (ob.name, moved, len(high)))
        if ob.name == "body_shirt" and mode == "built":
            stand_collar(bpy, ob, head, tree, centre, ring_z, shirt_png)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    body, head, out = a["--body"], a["--head"], a["--out"]
    import bpy
    import bmesh
    from mathutils import Vector
    from scipy.spatial import cKDTree
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, body + ".glb"))
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    skin = bpy.data.objects["body_skin"]
    old = bpy.data.objects["body_head"]
    # His garment pieces (fit_tripo's `pieces`: body_coat ...) and his own fingers (finger_*)
    # come along as they are.
    pieces = [o.name[5:] for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("body_")
              and o.name not in ("body_skin", "body_head")]
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.name.startswith(("body_", "finger_")):
            bpy.data.objects.remove(o)
    old_co = np.array([v.co[:] for v in old.data.vertices])
    # The painted bust into Blender's space (body space: Y up, facing -Z → x, -z, y).
    # The painted bust: kept in assets/people/heads (build/ is wiped with the workspace), else
    # fresh from rodin_portrait.py's work folder.
    kept = os.path.join(HEADS, head + "_mesh.npz")
    if os.path.exists(kept):
        mesh = dict(np.load(kept))
    else:
        mesh = np.load(os.path.join(WORK, head + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    Vb = np.c_[V[:, 0], -V[:, 2], V[:, 1]]
    chin = float(pts[152, 1])                              # body space: Y is his height
    above = V[:, 1] > chin - 0.01
    s, R, t, err = icp(Vb[above][::3], old_co)
    Vp = s * Vb @ R.T + t
    print("neck_ring: head laid on his by ICP: scale %.3f, median gap %.1f mm" % (s, err * 1000))
    mark("laid")
    # Cut at the ring and pull the open edge onto it.
    # Under his jaw the bust is still dressed (collar, lapels): only what's within the neck's
    # reach of the ring's axis is his neck; the rest goes.
    chin_p = s * np.array([pts[152, 0], -pts[152, 2], pts[152, 1]]) @ R.T + t
    # --head_scale: his head smaller or bigger than his body's own (laid by ICP it takes that
    # head's size, from the body's pictures: 1/7.2 of his height, big against his shoulders;
    # Sean, 2026-10-15). Scaled about his neck's middle at his chin, so the ring stays put.
    k = float(a.get("--head_scale", 1.0))
    if k != 1.0:
        at = np.abs(Vp[:, 2] - chin_p[2]) < 0.01
        pivot = np.array([Vp[at, 0].mean(), Vp[at, 1].mean(), chin_p[2]])
        Vp = pivot + (Vp - pivot) * k
        chin_p = pivot + (chin_p - pivot) * k
        print("neck_ring: head scaled %.2f about his neck at the chin" % k)
    # The ring: under his jaw (RING_BELOW_CHIN under the laid head's chin). His body keeps its own
    # neck up to there: his old head's neck is joined onto body_skin and the two cut level at the
    # ring (both are painted from the same pictures, one texture).
    ring_z = float(chin_p[2] - RING_BELOW_CHIN)
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    bm.from_mesh(old.data)                                  # appended: same groups, same UVs
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0, 0, ring_z), plane_no=(0, 0, 1), clear_outer=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    skin_co_all = np.array([v.co[:] for v in skin.data.vertices])
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    edge_v = {v.index for e in bm.edges if e.is_boundary for v in e.verts}
    bm.free()
    bv = np.array(sorted(edge_v))
    ring = skin_co_all[bv[np.abs(skin_co_all[bv, 2] - ring_z) < 0.003]]
    centre = ring.mean(0)
    ring_ang = np.arctan2(ring[:, 1] - centre[1], ring[:, 0] - centre[0])
    order = np.argsort(ring_ang)
    ring, ring_ang = ring[order], ring_ang[order]
    print("neck_ring: ring of %d points at %.3f m (%.0f mm under his chin), his old head %d vertices" % (
        len(ring), ring_z, RING_BELOW_CHIN * 1000, len(old_co)))
    # (Under his jaw the bust is dressed, but the ring is above the collar: everything of the
    # head over the ring stays; trimming by reach left a hole under his chin.)
    keepv = Vp[:, 2] > ring_z - 0.002
    tk = T[keepv[T].all(1)]
    used = np.unique(tk)
    remap = -np.ones(len(Vp), int)
    remap[used] = np.arange(len(used))
    Vh, Th, UVh = Vp[used].copy(), remap[tk], UV[used]
    from collections import Counter
    # Open edges counted with vertices welded by position (the bust is split at its UV seams).
    _u, wi = np.unique(np.round(Vh / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    wi = wi.ravel()
    Tw = wi[Th]
    ec = Counter(tuple(sorted(e)) for t_ in Tw for e in ((t_[0], t_[1]), (t_[1], t_[2]), (t_[2], t_[0])))
    open_w = {i for e, n in ec.items() if n == 1 for i in e}
    open_v = np.array([i for i in range(len(Vh)) if wi[i] in open_w])
    low = open_v[Vh[open_v, 2] < ring_z + 0.01]             # the cut edge, not holes higher up
    ang = np.arctan2(Vh[low, 1] - centre[1], Vh[low, 0] - centre[0])
    tgt = np.c_[np.interp(ang, ring_ang, ring[:, 0], period=2 * math.pi),
                np.interp(ang, ring_ang, ring[:, 1], period=2 * math.pi),
                np.interp(ang, ring_ang, ring[:, 2], period=2 * math.pi)]
    move = tgt - Vh[low]
    # Each vertex near the ring moves as its nearest edge vertex does, fading out above.
    tree = cKDTree(Vh[low])
    d, j = tree.query(Vh)
    fade = np.clip(1 - (Vh[:, 2] - ring_z) / RING_BLEND, 0, 1) ** 1.5
    Vh = Vh + move[j] * fade[:, None]
    Vh[low] = tgt
    print("neck_ring: %d edge vertices onto the ring (moved %.1f mm median, %.1f max)" % (
        len(low), np.median(np.linalg.norm(move, axis=1)) * 1000, np.linalg.norm(move, axis=1).max() * 1000))
    mark("cut and pulled")
    # Below his jaw the paintings show his collar and coat: on a bare body that's skin, so the
    # paint there fades to the body's skin colour at the ring (NECK_FADE under his chin).
    import portrait as P
    from PIL import Image
    paint_path = os.path.join(HEADS, head + "_paint.png")
    if not os.path.exists(paint_path):
        paint_path = os.path.join(WORK, head + "_paint.png")
    paint = np.asarray(Image.open(paint_path).convert("RGB")).astype(float) / 255
    size = paint.shape[0]
    # A shirted body's neck is painted the shirt's colour (under his collar): his face is matched
    # to his bare skin as the fitter wrote it before that (else it took the shirt's colour).
    bare = os.path.join(ROOT, "build", "bare_skin", body + "_skin.png")
    sk_path = bare if os.path.exists(bare) else os.path.join(PEOPLE, body + "_skin.png")
    sk_tex = np.asarray(Image.open(sk_path).convert("RGB")).astype(float) / 255
    sk_uv = np.array([[d.uv[0], d.uv[1]] for d in skin.data.uv_layers.active.data])
    sk_loop_v = np.array([lp.vertex_index for lp in skin.data.loops])
    ring_loops = np.isin(sk_loop_v, np.nonzero(np.abs(skin_co_all[:, 2] - ring_z) < 0.03)[0])
    uvr = sk_uv[ring_loops]
    hs, ws = sk_tex.shape[:2]
    skin_c = np.median(sk_tex[np.clip(((1 - uvr[:, 1]) * hs).astype(int), 0, hs - 1),
                              np.clip((uvr[:, 0] * ws).astype(int), 0, ws - 1)], 0)
    table = {tuple(t_): [tuple(UVh[i]) for i in t_] for t_ in Th}
    Mz, cover = P.raster_uv(table, [list(t_) for t_ in Th], Vh[:, 2:3], size)
    # His face's skin matched to his body's (the two are painted from different pictures): each
    # channel of the whole head scaled so his cheeks' median comes to the body's skin at the ring.
    eye_y = (pts[468, 1] + pts[473, 1]) / 2
    nv = P.vertex_normals(V, T)
    cheek = (nv[:, 2] < -0.2) & (V[:, 1] < eye_y - 0.015) & (V[:, 1] > pts[2, 1]) \
        & (np.abs(V[:, 0] - pts[1, 0]) > 0.025) & (np.abs(V[:, 0] - pts[1, 0]) < 0.05)
    import rodin_portrait as RP
    cheek_c = np.median(RP.sample_tex(paint, UV[cheek]), 0)
    gain = np.clip(skin_c / np.maximum(cheek_c, 1e-3), 0.5, 2.0) if cheek.sum() > 20 else np.ones(3)
    # Only skin takes all of it: each texel by how near his cheeks' colour it is (Lab), so his hair,
    # brows and moustache keep theirs.
    lab = RP._lab(paint.reshape(-1, 3)).reshape(paint.shape)
    near_skin = np.exp(-np.linalg.norm(lab - RP._lab(cheek_c[None])[0], axis=-1) / 25.0)[..., None]
    paint = np.clip(paint * (1 + near_skin * (gain - 1)), 0, 1)
    print("neck_ring: his face's skin %s to the body's %s (gain %s)" % (np.round(cheek_c, 3).tolist(),
          np.round(skin_c, 3).tolist(), np.round(gain, 3).tolist()))
    jaw_z = chin_p[2] - 0.005
    zt = Mz[..., 0]
    w = np.clip((jaw_z - zt) / NECK_FADE, 0, 1)
    # All round his neck just above the ring (the nape, under his ears), and any of the collar's
    # white left low on his head (under his jaw), to skin too.
    w = np.maximum(w, np.clip((ring_z + 0.03 - zt) / 0.03, 0, 1))
    lab_t = RP._lab(paint.reshape(-1, 3)).reshape(paint.shape)
    collar = (lab_t[..., 0] > 68) & (np.hypot(lab_t[..., 1], lab_t[..., 2]) < 30) & (zt < chin_p[2] + 0.06)
    w = np.maximum(w, collar.astype(float))
    w = w * cover
    paint = paint * (1 - w[..., None]) + skin_c * w[..., None]
    neck_paint = paint
    print("neck_ring: neck below his jaw to skin %s over %d texels" % (np.round(skin_c, 3).tolist(), int((w > 0.5).sum())))
    mark("neck repainted")
    # The new head mesh, skinned as his old one.
    # The bust is a loop mesh (each corner its own vertex, for its UV): welded by position for
    # Blender, the UVs kept per corner, so decimating it doesn't tear it into holes.
    _u, first, wi2 = np.unique(np.round(Vh / 1e-5).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    wi2 = wi2.ravel()
    # Triangles that welding folds flat (two corners at one point) go: Blender's decimation hangs
    # on them.
    Fw = wi2[Th]
    good = (Fw[:, 0] != Fw[:, 1]) & (Fw[:, 1] != Fw[:, 2]) & (Fw[:, 0] != Fw[:, 2])
    Th, Fw = Th[good], Fw[good]
    me = bpy.data.meshes.new("body_head")
    me.from_pydata([tuple(p) for p in Vh[first]], [], [tuple(int(i) for i in f) for f in Fw])
    uvl = me.uv_layers.new(name="UVMap")
    corner_uv = np.c_[UVh[Th.ravel(), 0], 1.0 - UVh[Th.ravel(), 1]]    # loops run face by face
    uvl.data.foreach_set("uv", corner_uv.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), bool))
    me.validate(clean_customdata=False)
    print("neck_ring: head mesh %d vertices, %d triangles (%d folded flat dropped)" % (
        len(me.vertices), len(me.polygons), int((~good).sum())), flush=True)
    newh = bpy.data.objects.new("body_head_new", me)
    bpy.context.scene.collection.objects.link(newh)
    mark("mesh made")
    # Cut down to the game's budget first (before any skinning, so nothing needs re-ordering).
    print("neck_ring: head %d triangles" % len(Th), flush=True)
    if len(Th) > HEAD_TRIS:
        # Applied through the evaluated mesh (no operators: they want a selection context).
        dec = newh.modifiers.new("dec", "DECIMATE")
        dec.ratio = HEAD_TRIS / len(Th)
        dg = bpy.context.evaluated_depsgraph_get()
        cut = bpy.data.meshes.new_from_object(newh.evaluated_get(dg))
        newh.modifiers.remove(dec)
        newh.data = cut
        cut.name = "body_head"
    mark("decimated")
    Vw = np.array([v.co[:] for v in newh.data.vertices])
    groups = [g.name for g in old.vertex_groups]
    for g in groups:
        newh.vertex_groups.new(name=g)
    def weights(obj):
        w = np.zeros((len(obj.data.vertices), len(groups)))
        idx = {g.index: groups.index(g.name) for g in obj.vertex_groups if g.name in groups}
        for v in obj.data.vertices:
            for ge in v.groups:
                if ge.group in idx:
                    w[v.index, idx[ge.group]] = ge.weight
        return w
    w_old = weights(old)
    w_skin = weights(skin)
    skin_co = np.array([v.co[:] for v in skin.data.vertices])
    src_co = np.vstack([old_co, skin_co])
    src_w = np.vstack([w_old, w_skin])
    near = Vw[:, 2] < ring_z + RING_BLEND
    _d, jo = cKDTree(old_co).query(Vw)
    _d2, jb = cKDTree(src_co).query(Vw)
    W = np.where(near[:, None], src_w[jb], w_old[jo])
    for gi, g in enumerate(groups):
        vg = newh.vertex_groups[g]
        nz = np.nonzero(W[:, gi] > 1e-4)[0]
        # One call per distinct weight (rounded to 1/256), not one per vertex.
        q = np.round(W[nz, gi] * 256) / 256
        for val in np.unique(q):
            vg.add([int(i) for i in nz[q == val]], float(val), "REPLACE")
    mark("skinned")
    newh.parent = arm
    mod = newh.modifiers.new("skeleton", "ARMATURE")
    mod.object = arm
    bpy.data.objects.remove(old)
    # --collar=none: the garments left as the fit made them, the bust's own painted collar meeting
    # them (a coat's twin's collar and tie are clean, and the built one reads as a neck brace
    # close up: Sean, 2026-10-16); smooth: the twin's own ragged collar and knot smoothed
    # (smooth_collar) and standing to his jaw in front (the coatless man, 2026-10-17); built (the
    # default): collar_out and stand_collar; own: collar_out without the build.
    if a.get("--collar", "built") != "none":
        collar_out(bpy, newh, ring_z, os.path.join(PEOPLE, body + "_shirt.png"), a.get("--collar", "built"))
    newh.name = "body_head"
    newh.data.name = "body_head"
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    shutil.copy(os.path.join(PEOPLE, body + "_skin.png"), os.path.join(PEOPLE, out + "_skin.png"))
    for shape in pieces:
        src = os.path.join(PEOPLE, "%s_%s.png" % (body, shape))
        if os.path.exists(src):
            shutil.copy(src, os.path.join(PEOPLE, "%s_%s.png" % (out, shape)))
    Image.fromarray((np.clip(neck_paint, 0, 1) * 255).astype(np.uint8)).save(os.path.join(PEOPLE, out + "_head.png"))
    rep = json.load(open(os.path.join(PEOPLE, body + ".json")))
    rep.update({"id": out, "pieces_kept": pieces, "neck_ring": {"body": body, "head": head, "head_scale": k, "ring_m": round(ring_z, 4),
                                         "icp_scale": round(float(s), 4), "icp_gap_mm": round(err * 1000, 1),
                                         "edge_vertices": int(len(low))}})
    rep["triangles"] = dict(rep.get("triangles", {}), head=len(newh.data.polygons))
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("neck_ring: wrote", path)


if __name__ == "__main__":
    main()
