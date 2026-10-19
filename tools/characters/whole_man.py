"""Test 1 (docs/style_test/two-tests-2026-10-19): a dressed Rodin man kept whole, with the approved
portrait head and his own hat.

    ~/bpyenv/bin/python tools/characters/whole_man.py --body=bold_cowboy_whole_body \\
        --head=bold_cowboy_rodin --out=bold_cowboy_whole [--hat_from=GLB]

- His body: tools/blender/fit_tripo.py's fit of the whole dressed man (people.json `bare`: fitted
  bare-headed at his true height), his clothes part of his skin, nothing cut out.
- His head: the approved man's game head (assets/people/<head>.glb `body_head`, its eyes on the
  anatomy's, and <head>_head.png, the face paint), kept as a bust in assets/people/heads
  (<head>_mesh.npz, <head>_paint.png) the first time, with rodin_portrait.py's landmarks carried
  onto it (build/rodin_portrait/<head>_mesh.npy, laid as rodin_portrait_build lays it). Laid as it
  is (his eyes stay the anatomy's) and joined at the COLLAR (join): his body cut level
  RING_BELOW_CHIN under the head's chin (his own chin and throat go), the head's neck left whole
  down inside his collar (HEAD_TUCK), and the body's cut edge drawn in onto the head's neck all
  round (his collar hugging his throat), eased over COLLAR_EASE down him. A level ring that drew the
  head's neck out to the body (tools/characters/neck_ring.py) flared it to his shoulders: the
  dressed twin's collar stands 3-4 cm before the head's throat. His face's texture is the approved
  one, byte for byte.
- His own hat: the three rigid pieces of the bold cowboy's own hat (look/bold-cowboy-own-hat-
  2026-10-14: `cloth_hat`, `cloth_hat_brim`, `cloth_hat_band` and their textures), kept in
  assets/people/heads/<head>_hat.npz the first time (`--hat_from`, that branch's glb), on his head
  bone: PeopleBodies takes them as his own hat (a whole man wears every piece his model came
  with) and HumanBody.knock_hat_off takes it off.
→ assets/people/<out>.glb, <out>_skin.png, <out>_head.png, <out>_hat*.png, <out>.json.
"""
import json
import os
import shutil
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PEOPLE = os.path.join(ROOT, "assets", "people")
HEADS = os.path.join(PEOPLE, "heads")
WORK = os.path.join(ROOT, "build", "rodin_portrait")
EYE_DEPTH = 0.012          # as rodin_portrait_build: an eye's middle behind its iris
HAT_PARTS = ("hat", "hat_brim", "hat_band")
RING_BELOW_CHIN = 0.012    # metres: the body cut level this far under the head's chin
HEAD_TUCK = 0.02           # metres of the head's neck kept under the cut, inside his collar
COLLAR_CLEAR = 0.003       # the body's edge this far outside the head's neck
COLLAR_EASE = 0.035        # metres down him over which the draw onto the neck fades
NECK_BLEND = (0.02, 0.06)  # under his chin: all head above the first, all neck below (rodin_portrait_build)


def objects(bpy, path):
    """The meshes of a glb, each as (V in body space, T, UV per vertex in image space)."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    out = {}
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        me = o.data
        me.calc_loop_triangles()
        Vb = np.array([(o.matrix_world @ v.co)[:] for v in me.vertices])
        uv = me.uv_layers.active.data if me.uv_layers.active else None
        # One vertex per triangle corner (each its own UV), as Rodin's busts are.
        V, UV, T = [], [], []
        for t in me.loop_triangles:
            T.append([len(V), len(V) + 1, len(V) + 2])
            for li, vi in zip(t.loops, t.vertices):
                V.append(Vb[vi])
                u, v = uv[li].uv if uv is not None else (0.0, 0.0)
                UV.append([u, 1.0 - v])
        V = np.array(V)
        out[o.name.split(".")[0]] = (np.c_[V[:, 0], V[:, 2], -V[:, 1]], np.array(T), np.array(UV))
    return out


def keep_head(bpy, head):
    """The approved head as a kept bust (assets/people/heads/<head>_mesh.npz and _paint.png)."""
    npz = os.path.join(HEADS, head + "_mesh.npz")
    if os.path.exists(npz):
        return
    V, T, UV = objects(bpy, os.path.join(PEOPLE, head + ".glb"))["body_head"]
    mesh = np.load(os.path.join(WORK, head.replace("_rodin", "") + "_mesh.npy"), allow_pickle=True).item()
    pts = mesh["pts"]
    rep = json.load(open(os.path.join(PEOPLE, head + ".json")))
    eyes = {s: np.array(rep["eyes"][s]) for s in ("right", "left")}
    a, b = (pts[468], pts[473]) if pts[468, 0] > pts[473, 0] else (pts[473], pts[468])
    mine = {"right": a + np.array([0, 0, EYE_DEPTH]), "left": b + np.array([0, 0, EYE_DEPTH])}
    k = np.linalg.norm(eyes["right"] - eyes["left"]) / np.linalg.norm(mine["right"] - mine["left"])
    c_mine, c_goal = (mine["right"] + mine["left"]) / 2, (eyes["right"] + eyes["left"]) / 2
    os.makedirs(HEADS, exist_ok=True)
    np.savez_compressed(npz, V=V, T=T, UV=UV, pts=(pts - c_mine) * k + c_goal)
    shutil.copy(os.path.join(PEOPLE, head + "_head.png"), os.path.join(HEADS, head + "_paint.png"))
    print("whole_man: kept %s's game head (%d triangles) as %s" % (head, len(T), npz))


def keep_hat(bpy, head, glb):
    """His own hat's pieces from the hat branch's built man (`--hat_from`)."""
    npz = os.path.join(HEADS, head + "_hat.npz")
    if os.path.exists(npz) or not glb:
        return
    obs = objects(bpy, glb)
    parts = {}
    for p in HAT_PARTS:
        V, T, UV = obs["cloth_" + p]
        parts[p + "_V"], parts[p + "_T"], parts[p + "_UV"] = V, T, UV
        shutil.copy(os.path.join(os.path.dirname(glb), "%s_%s.png" % (head, p)), os.path.join(HEADS, "%s_%s.png" % (head, p)))
    np.savez_compressed(npz, **parts)
    print("whole_man: kept his own hat from", glb)


def add_hat(bpy, out, head):
    """His own hat's pieces into <out>.glb, on his head bone."""
    hat = dict(np.load(os.path.join(HEADS, head + "_hat.npz")))
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.name.startswith(("body_", "finger_", "cloth_")):
            bpy.data.objects.remove(o)        # the importer's bone shapes
    groups = [b.name for b in arm.data.bones]
    tris = {}
    for p in HAT_PARTS:
        V, T, UV = hat[p + "_V"], hat[p + "_T"], hat[p + "_UV"]
        _u, first, wi = np.unique(np.round(V / 1e-5).astype(np.int64), axis=0, return_index=True, return_inverse=True)
        wi = wi.ravel()
        F = wi[T]
        good = (F[:, 0] != F[:, 1]) & (F[:, 1] != F[:, 2]) & (F[:, 0] != F[:, 2])
        F, Tg = F[good], T[good]
        me = bpy.data.meshes.new("cloth_" + p)
        me.from_pydata([(x, -z, y) for x, y, z in V[first]], [], F.tolist())
        uvl = me.uv_layers.new(name="UVMap")
        cuv = np.c_[UV[Tg.ravel(), 0], 1.0 - UV[Tg.ravel(), 1]]
        uvl.data.foreach_set("uv", cuv.astype(np.float32).ravel())
        # Its faces all turned outward: a quarter of the crown's top was wound inward and culled,
        # a sliver of sky through the hat from behind (on the hat's own sheet too, s5_own_hat).
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bm.to_mesh(me)
        bm.free()
        me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), bool))
        obj = bpy.data.objects.new("cloth_" + p, me)
        bpy.context.scene.collection.objects.link(obj)
        for g in groups:
            obj.vertex_groups.new(name=g)
        obj.vertex_groups["head"].add(list(range(len(me.vertices))), 1.0, "REPLACE")
        obj.parent = arm
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        tris[p] = len(me.polygons)
        shutil.copy(os.path.join(HEADS, "%s_%s.png" % (head, p)), os.path.join(PEOPLE, "%s_%s.png" % (out, p)))
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    return tris


def join(bpy, body, head, out):
    """The approved head on the fitted body at his collar (the module's note) → <out>.glb."""
    import bmesh
    from scipy.spatial import cKDTree
    m = dict(np.load(os.path.join(HEADS, head + "_mesh.npz")))
    V, T, UV, pts = m["V"], m["T"], m["UV"], m["pts"]
    chin = float(pts[152, 1])
    ring = chin - RING_BELOW_CHIN
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, body + ".glb"))
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.name.startswith(("body_", "finger_", "cloth_")):
            bpy.data.objects.remove(o)
    skin, old = bpy.data.objects["body_skin"], bpy.data.objects["body_head"]
    # His own head joins his skin (same groups, same UVs) and all of it over the cut goes.
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    bm.from_mesh(old.data)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0, 0, ring), plane_no=(0, 0, 1), clear_outer=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    # Scraps cut loose from him (a lock of his own hair over the cut) go.
    bm.verts.ensure_lookup_table()
    seen, pieces = set(), []
    for v0 in bm.verts:
        if v0.index in seen:
            continue
        stack, piece = [v0], []
        seen.add(v0.index)
        while stack:
            v = stack.pop()
            piece.append(v)
            for e in v.link_edges:
                w = e.other_vert(v)
                if w.index not in seen:
                    seen.add(w.index)
                    stack.append(w)
        pieces.append(piece)
    pieces.sort(key=len)
    dropped = 0
    for piece in pieces[:-1]:
        if len(piece) < 200 and min(v.co.z for v in piece) > ring - 0.08:
            bmesh.ops.delete(bm, geom=piece, context="VERTS")
            dropped += len(piece)
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    bpy.data.objects.remove(old)
    # What's left of his old head is his collar: on his neck, not his head (weighted to his head,
    # it stretched to sheets when he nodded).
    gh, gn = skin.vertex_groups.get("head"), skin.vertex_groups.get("neck")
    moved = 0
    if gh is not None and gn is not None:
        for v in skin.data.vertices:
            for ge in v.groups:
                if ge.group == gh.index and ge.weight > 0:
                    w_n = next((g.weight for g in v.groups if g.group == gn.index), 0.0)
                    gn.add([v.index], w_n + ge.weight, "REPLACE")
                    moved += 1
        gh.remove([v.index for v in skin.data.vertices])
    print("whole_man: %d collar vertices from his head's weight to his neck's" % moved)
    co = np.array([v.co[:] for v in skin.data.vertices])
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    edge = sorted({v.index for e in bm.edges if e.is_boundary for v in e.verts})
    bm.free()
    edge = np.array([i for i in edge if abs(co[i, 2] - ring) < 0.003])
    # The head's neck round the cut: its radius at each angle about its middle there.
    Vb = np.c_[V[:, 0], -V[:, 2], V[:, 1]]                     # body space → Blender's
    band = Vb[np.abs(Vb[:, 2] - ring) < 0.004]
    centre = np.array([band[:, 0].mean(), band[:, 1].mean()])
    ang_h = np.arctan2(band[:, 1] - centre[1], band[:, 0] - centre[0])
    rad_h = np.hypot(band[:, 0] - centre[0], band[:, 1] - centre[1])
    bins = np.linspace(-np.pi, np.pi, 73)
    prof = np.array([rad_h[(ang_h >= a0) & (ang_h < a1)].max() if ((ang_h >= a0) & (ang_h < a1)).any() else np.nan
                     for a0, a1 in zip(bins[:-1], bins[1:])])
    mids = (bins[:-1] + bins[1:]) / 2
    ok = ~np.isnan(prof)
    rad_at = lambda a: np.interp(a, mids[ok], prof[ok], period=2 * np.pi)
    a_e = np.arctan2(co[edge, 1] - centre[1], co[edge, 0] - centre[0])
    r_e = np.hypot(co[edge, 0] - centre[0], co[edge, 1] - centre[1])
    tgt = rad_at(a_e) + COLLAR_CLEAR
    move = np.zeros((len(edge), 3))
    move[:, 0] = np.cos(a_e) * (tgt - r_e)
    move[:, 1] = np.sin(a_e) * (tgt - r_e)
    # Each vertex of his collar moves as its nearest edge vertex does, fading out down him.
    _d, j = cKDTree(co[edge]).query(co)
    fade = np.clip(1 - (ring - co[:, 2]) / COLLAR_EASE, 0, 1) ** 1.5
    fade[co[:, 2] < ring - COLLAR_EASE] = 0.0
    new = co + move[j] * fade[:, None]
    for i, v in enumerate(skin.data.vertices):
        v.co = new[i]
    skin.data.update()
    print("whole_man: his collar cut at %.3f m (%.0f mm under the head's chin), %d edge vertices drawn onto its "
          "neck (%.1f mm median, %.1f max); %d vertices of scraps dropped" % (
              ring, RING_BELOW_CHIN * 1000, len(edge), np.median(np.abs(tgt - r_e)) * 1000,
              np.abs(tgt - r_e).max() * 1000, dropped))
    # The head: whole above the cut and HEAD_TUCK under it, welded by position, its UVs per corner.
    keepv = Vb[:, 2] > ring - HEAD_TUCK
    tk = T[keepv[T].all(1)]
    _u, first, wi = np.unique(np.round(Vb / 1e-5).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    wi = wi.ravel()
    F = wi[tk]
    good = (F[:, 0] != F[:, 1]) & (F[:, 1] != F[:, 2]) & (F[:, 0] != F[:, 2])
    F, tk = F[good], tk[good]
    used = np.unique(F)
    remap = -np.ones(len(first), int)
    remap[used] = np.arange(len(used))
    me = bpy.data.meshes.new("body_head")
    me.from_pydata([tuple(p) for p in Vb[first][used]], [], remap[F].tolist())
    uvl = me.uv_layers.new(name="UVMap")
    cuv = np.c_[UV[tk.ravel(), 0], 1.0 - UV[tk.ravel(), 1]]
    uvl.data.foreach_set("uv", cuv.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), bool))
    me.validate(clean_customdata=False)
    h = bpy.data.objects.new("body_head", me)
    bpy.context.scene.collection.objects.link(h)
    for b in arm.data.bones:
        h.vertex_groups.new(name=b.name)
    # Skinned as the approved man's head is (rodin_portrait_build: head above his chin, neck under).
    hz = np.array([v.co.z for v in me.vertices])
    t = np.clip((chin - NECK_BLEND[0] - hz) / (NECK_BLEND[1] - NECK_BLEND[0]), 0, 1)
    for val in np.unique(np.round(t * 64) / 64):
        idx = [int(i) for i in np.nonzero(np.round(t * 64) / 64 == val)[0]]
        if val < 1:
            h.vertex_groups["head"].add(idx, float(1 - val), "REPLACE")
        if val > 0:
            h.vertex_groups["neck"].add(idx, float(val), "REPLACE")
    h.parent = arm
    mod = h.modifiers.new("skeleton", "ARMATURE")
    mod.object = arm
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    shutil.copy(os.path.join(PEOPLE, body + "_skin.png"), os.path.join(PEOPLE, out + "_skin.png"))
    rep = json.load(open(os.path.join(PEOPLE, body + ".json")))
    rep.update({"id": out, "collar_join": {"cut_m": round(ring, 4), "edge_vertices": int(len(edge)),
                                           "drawn_in_mm_median": round(float(np.median(np.abs(tgt - r_e))) * 1000, 1)}})
    rep["triangles"] = dict(rep.get("triangles", {}), head=len(me.polygons))
    # His eyes are the approved head's (on the anatomy's: tests/test_bodies.gd).
    rep["eyes"] = json.load(open(os.path.join(PEOPLE, head + ".json")))["eyes"]
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    body, head, out = a["--body"], a["--head"], a["--out"]
    import bpy
    keep_head(bpy, head)
    keep_hat(bpy, head, a.get("--hat_from"))
    # His face's texture is the approved one, byte for byte.
    shutil.copy(os.path.join(HEADS, head + "_paint.png"), os.path.join(PEOPLE, out + "_head.png"))
    join(bpy, body, head, out)
    tris = add_hat(bpy, out, head)
    rep = json.load(open(os.path.join(PEOPLE, out + ".json")))
    rep["whole_man"] = {"body": body, "head": head + " (the approved game head and face paint)",
                        "hat": "his own (look/bold-cowboy-own-hat-2026-10-14)"}
    rep["triangles"] = dict(rep.get("triangles", {}), **tris)
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("whole_man: wrote", os.path.join(PEOPLE, out + ".glb"))


if __name__ == "__main__":
    main()
