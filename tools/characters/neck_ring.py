"""A painted head on a base body through the neck ring (docs/briefs/layered-people.md, option 2).

    ~/bpyenv/bin/python tools/characters/neck_ring.py --body=bold_cowboy_body \\
        --head=bold_cowboy_painterly_lit --out=bold_cowboy_layered

- The base body (assets/people/<body>.glb, fitted by tools/blender/fit_tripo.py) comes in two
  meshes cut at one height above his collar: `body_skin` and `body_head`. That cut is the **neck
  ring**: the loop of `body_skin`'s open edge round his neck. His own head goes.
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
RING_BLEND = 0.03      # metres above the ring over which the head's neck is pulled onto it
NECK_FADE = 0.015      # metres under his jaw over which his painted collar fades to skin
HEAD_TRIS = 12000
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
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o.name not in ("body_skin", "body_head"):
            bpy.data.objects.remove(o)
    # The ring: body_skin's open edge round his neck (the highest open loop).
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    bm.verts.ensure_lookup_table()
    edge_v = {v.index for e in bm.edges if e.is_boundary for v in e.verts}
    co = np.array([v.co[:] for v in bm.verts])
    bv = np.array(sorted(edge_v))
    top_z = co[bv, 2].max()
    ring = co[bv[co[bv, 2] > top_z - 0.04]]                 # Blender: Z is his height
    bm.free()
    centre = ring.mean(0)
    ring_z = float(np.median(ring[:, 2]))
    ring_ang = np.arctan2(ring[:, 1] - centre[1], ring[:, 0] - centre[0])
    order = np.argsort(ring_ang)
    ring, ring_ang = ring[order], ring_ang[order]
    old_co = np.array([v.co[:] for v in old.data.vertices])
    skin_co_all = np.array([v.co[:] for v in skin.data.vertices])
    print("neck_ring: ring of %d points at %.3f m, his old head %d vertices" % (len(ring), ring_z, len(old_co)))
    # The painted bust into Blender's space (body space: Y up, facing -Z → x, -z, y).
    mesh = np.load(os.path.join(WORK, head + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    Vb = np.c_[V[:, 0], -V[:, 2], V[:, 1]]
    chin = float(pts[152, 1])                              # body space: Y is his height
    above = V[:, 1] > chin - 0.01
    s, R, t, err = icp(Vb[above][::3], old_co)
    Vp = s * Vb @ R.T + t
    print("neck_ring: head laid on his by ICP: scale %.3f, median gap %.1f mm" % (s, err * 1000))
    # Cut at the ring and pull the open edge onto it.
    # Under his jaw the bust is still dressed (collar, lapels): only what's within the neck's
    # reach of the ring's axis is his neck; the rest goes.
    chin_p = s * np.array([pts[152, 0], -pts[152, 2], pts[152, 1]]) @ R.T + t
    ring_r = float(np.percentile(np.hypot(ring[:, 0] - centre[0], ring[:, 1] - centre[1]), 90))
    radial = np.hypot(Vp[:, 0] - centre[0], Vp[:, 1] - centre[1])
    neck_only = (Vp[:, 2] > chin_p[2]) | (radial < ring_r + 0.012)
    keepv = (Vp[:, 2] > ring_z - 0.002) & neck_only
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
    # Below his jaw the paintings show his collar and coat: on a bare body that's skin, so the
    # paint there fades to the body's skin colour at the ring (NECK_FADE under his chin).
    import portrait as P
    from PIL import Image
    paint = np.asarray(Image.open(os.path.join(WORK, head + "_paint.png")).convert("RGB")).astype(float) / 255
    size = paint.shape[0]
    sk_tex = np.asarray(Image.open(os.path.join(PEOPLE, body + "_skin.png")).convert("RGB")).astype(float) / 255
    sk_uv = np.array([[d.uv[0], d.uv[1]] for d in skin.data.uv_layers.active.data])
    sk_loop_v = np.array([lp.vertex_index for lp in skin.data.loops])
    ring_loops = np.isin(sk_loop_v, np.nonzero(np.abs(skin_co_all[:, 2] - ring_z) < 0.03)[0])
    uvr = sk_uv[ring_loops]
    hs, ws = sk_tex.shape[:2]
    skin_c = np.median(sk_tex[np.clip(((1 - uvr[:, 1]) * hs).astype(int), 0, hs - 1),
                              np.clip((uvr[:, 0] * ws).astype(int), 0, ws - 1)], 0)
    table = {tuple(t_): [tuple(UVh[i]) for i in t_] for t_ in Th}
    Mz, cover = P.raster_uv(table, [list(t_) for t_ in Th], Vh[:, 2:3], size)
    jaw_z = chin_p[2] - 0.005
    w = np.clip((jaw_z - Mz[..., 0]) / NECK_FADE, 0, 1) * cover
    paint = paint * (1 - w[..., None]) + skin_c * w[..., None]
    neck_paint = paint
    print("neck_ring: neck below his jaw to skin %s over %d texels" % (np.round(skin_c, 3).tolist(), int((w > 0.5).sum())))
    # The new head mesh, skinned as his old one.
    # The bust is a loop mesh (each corner its own vertex, for its UV): welded by position for
    # Blender, the UVs kept per corner, so decimating it doesn't tear it into holes.
    _u, first, wi2 = np.unique(np.round(Vh / 1e-5).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    wi2 = wi2.ravel()
    me = bpy.data.meshes.new("body_head")
    me.from_pydata([tuple(p) for p in Vh[first]], [], [tuple(int(wi2[i]) for i in t_) for t_ in Th])
    uvl = me.uv_layers.new(name="UVMap")
    for poly, t_ in zip(me.polygons, Th):
        poly.use_smooth = True
        for k_, li in enumerate(poly.loop_indices):
            uvl.data[li].uv = (float(UVh[t_[k_], 0]), 1.0 - float(UVh[t_[k_], 1]))
    newh = bpy.data.objects.new("body_head_new", me)
    bpy.context.scene.collection.objects.link(newh)
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
    Vw = Vh[first]
    near = Vw[:, 2] < ring_z + RING_BLEND
    _d, jo = cKDTree(old_co).query(Vw)
    _d2, jb = cKDTree(src_co).query(Vw)
    W = np.where(near[:, None], src_w[jb], w_old[jo])
    for gi, g in enumerate(groups):
        vg = newh.vertex_groups[g]
        for vi in np.nonzero(W[:, gi] > 1e-4)[0]:
            vg.add([int(vi)], float(W[vi, gi]), "REPLACE")
    newh.parent = arm
    mod = newh.modifiers.new("skeleton", "ARMATURE")
    mod.object = arm
    if len(Th) > HEAD_TRIS:
        dec = newh.modifiers.new("dec", "DECIMATE")
        dec.ratio = HEAD_TRIS / len(Th)
        bpy.context.view_layer.objects.active = newh
        bpy.ops.object.modifier_move_to_index(modifier="dec", index=0)
        bpy.ops.object.modifier_apply(modifier="dec")
    bpy.data.objects.remove(old)
    newh.name = "body_head"
    newh.data.name = "body_head"
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    shutil.copy(os.path.join(PEOPLE, body + "_skin.png"), os.path.join(PEOPLE, out + "_skin.png"))
    Image.fromarray((np.clip(neck_paint, 0, 1) * 255).astype(np.uint8)).save(os.path.join(PEOPLE, out + "_head.png"))
    rep = json.load(open(os.path.join(PEOPLE, body + ".json")))
    rep.update({"id": out, "neck_ring": {"body": body, "head": head, "ring_m": round(ring_z, 4),
                                         "icp_scale": round(float(s), 4), "icp_gap_mm": round(err * 1000, 1),
                                         "edge_vertices": int(len(low))}})
    rep["triangles"] = dict(rep.get("triangles", {}), head=len(newh.data.polygons))
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("neck_ring: wrote", path)


if __name__ == "__main__":
    main()
