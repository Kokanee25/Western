"""The Rodin bold cowboy into the game (tools/characters/rodin_portrait.py build; needs bpy).

The factory's body (tools/blender/factory_build.py: MakeHuman's base mesh warped onto our joints
and the envelope, skinned to our 17 bones, clothes.py's garments) with Rodin's head in place of
its own: the bust cut above his collar (CUT_BELOW_CHIN, inside NECK_RADIUS of his neck), set so
his drawn eyes (MediaPipe's irises on it, EYE_DEPTH behind them) are the factory man's eyes, the
anatomy's (EYES_RULE, tests/test_bodies.gd: within 1.5 cm); on the head bone, blended onto the
neck's below his jaw; cut down to HEAD_TRIS. His paint is rodin_portrait.py's. He wears the
game's hat (not "whole"). → assets/people/<man>_rodin.glb, <man>_rodin_head.png, <man>_rodin.json.
"""
import json
import os
import shutil
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
import factory as F  # noqa: E402
import factory_build as FB  # noqa: E402
import make_people as mp  # noqa: E402
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402

CUT_BELOW_CHIN = 0.012    # everything this far under his chin and lower is cut, but his neck
NECK_DOWN = 0.06          # which goes on down this far
NECK_RADIUS = 0.055       # within this of his neck's middle
EYE_DEPTH = 0.012         # an eye's middle behind its iris
DETAIL_M = 0.03           # round his eyes and mouth the mesh keeps its detail
HEAD_TRIS = 12000
SKIN_CUT = 0.035          # the body's skin cut away above this far under his chin (his head's neck covers it)
NECK_BLEND = (0.02, 0.06)  # under his chin: all head above the first, all neck below the second
COLLAR_FROM = 0.06        # the shirt's collar and neckcloth above this far under his chin...
COLLAR_KEEP = 0.4         # ...squeezed down to this much of their height


def skin_like(c):
    """Rodin's own colours that are skin (warm, mid-bright), not his shirt, tie or coat."""
    lum = c.mean(1)
    return (c[:, 0] > c[:, 1]) & (c[:, 1] > c[:, 2]) & (c[:, 0] - c[:, 2] > 0.08) & (lum > 0.18) & (lum < 0.8)


def head_part(V, T, UV, pts, own=None):
    """The faces of the bust that are his head and neck (not his collar and shoulders): under his
    chin only what's within NECK_RADIUS of his neck's middle and, with `own` (Rodin's colours),
    skin."""
    chin_y = pts[152, 1]
    ring = (V[:, 1] < chin_y - 0.03) & (V[:, 1] > chin_y - 0.05) & (np.abs(V[:, 0]) < 0.06)
    neck_c = np.array([np.median(V[ring, 0]), np.median(V[ring, 2])]) if ring.any() else np.array([0.0, pts[152, 2] + 0.05])
    r = np.hypot(V[:, 0] - neck_c[0], V[:, 2] - neck_c[1])
    neck = (V[:, 1] > chin_y - NECK_DOWN) & (r < NECK_RADIUS)
    if own is not None:
        neck &= skin_like(own)
    keep_v = (V[:, 1] > chin_y - CUT_BELOW_CHIN) | neck
    keep = keep_v[T].all(1)
    return T[keep]


def neck_field(V, pts):
    """Where his head is kept (> 0): above CUT_BELOW_CHIN under his chin, or, down to NECK_DOWN,
    within NECK_RADIUS of his neck's middle. Continuous, so the cut along it is one clean line."""
    chin_y = pts[152, 1]
    ring = (V[:, 1] < chin_y - 0.03) & (V[:, 1] > chin_y - 0.05) & (np.abs(V[:, 0]) < 0.06)
    neck_c = np.array([np.median(V[ring, 0]), np.median(V[ring, 2])]) if ring.any() else np.array([0.0, pts[152, 2] + 0.05])
    r = np.hypot(V[:, 0] - neck_c[0], V[:, 2] - neck_c[1])
    return np.maximum(V[:, 1] - (chin_y - CUT_BELOW_CHIN), np.minimum(NECK_RADIUS - r, V[:, 1] - (chin_y - NECK_DOWN)))


def clip_part(V, T, UV, pts):
    """His head cut exactly along neck_field's zero (each triangle across it clipped, a new corner
    where an edge crosses, its UV between its ends'), not by whole triangles: Rodin's are 5-10 mm,
    so that cut was a row of teeth with the body's neck showing between. → (V, T, UV), V and UV
    one per corner as Rodin's are."""
    f = neck_field(V, pts)
    keep = (f[T] >= 0).all(1)
    cross = (f[T] >= 0).any(1) & ~keep
    V2, UV2, T2 = [V], [UV], [T[keep]]
    extra_v, extra_uv, extra_t = [], [], []
    n = len(V)

    def cut(i, j):
        # The same point for both triangles that share the edge: from its lower endpoint.
        a, b = (i, j) if tuple(V[i]) <= tuple(V[j]) else (j, i)
        t = f[a] / (f[a] - f[b])
        return V[a] + t * (V[b] - V[a]), UV[a] + t * (UV[b] - UV[a])

    for tri in T[cross]:
        poly = []
        for k in range(3):
            i, j = tri[k], tri[(k + 1) % 3]
            if f[i] >= 0:
                poly.append(("v", i))
            if (f[i] >= 0) != (f[j] >= 0):
                poly.append(("c", cut(i, j)))
        ids = []
        for kind, x in poly:
            if kind == "v":
                extra_v.append(V[x])
                extra_uv.append(UV[x])
            else:
                extra_v.append(x[0])
                extra_uv.append(x[1])
            ids.append(n + len(extra_v) - 1)
        for k in range(1, len(ids) - 1):
            extra_t.append((ids[0], ids[k], ids[k + 1]))
    if extra_v:
        V2.append(np.array(extra_v))
        UV2.append(np.array(extra_uv))
        T2.append(np.array(extra_t))
    return np.concatenate(V2), np.concatenate(T2), np.concatenate(UV2)


def build(man, spec):
    pid = man + "_rodin"
    mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    paint = os.path.join(RP.WORK, man + "_paint.png")
    env = json.load(open(mp.ENVELOPE))
    factory = F.load_factory()
    fid = spec.get("fidelity", {})
    fspec = {"source": "factory", "targets": dict(P.DEFAULT_MACRO), "hair": "none", "moustache": "none",
             "beard": "none", "skin": "#b07a5a", "outfit": spec.get("outfit", {})}
    # His body's skin the colour of his painted jaw (portrait.json `fidelity.skin_from_paint`): the
    # factory's flat skin showed paler pink round his neck where it meets his head.
    if fid.get("skin_from_paint"):
        from PIL import Image as _Im
        tex = np.asarray(_Im.open(paint).convert("RGB")).astype(float) / 255
        chin_y0 = pts[152, 1]
        jaw = (V[:, 1] < chin_y0 + 0.03) & (V[:, 1] > chin_y0 - 0.01) & (np.abs(V[:, 0] - pts[152, 0]) < 0.05)
        c = np.median(RP.sample_tex(tex, UV[jaw]), 0)
        fspec["skin"] = "#%02x%02x%02x" % tuple(int(round(255 * x)) for x in c)
    made = {}
    export = mp.export

    def export_with_rodin_head(person):
        import bpy
        for name in ("body_head", "body_hair"):
            o = bpy.data.objects.get(name)
            if o is not None:
                bpy.data.objects.remove(o)
        # Where his eyes go: the factory man's (the anatomy's), and where Rodin's are.
        rep = person.report
        eyes = {s: np.array(rep["eyes"][s]) for s in ("right", "left")}
        # His right eye is the iris further to +X (his right, in body space).
        a, b = (pts[468], pts[473]) if pts[468, 0] > pts[473, 0] else (pts[473], pts[468])
        mine = {"right": a + np.array([0, 0, EYE_DEPTH]), "left": b + np.array([0, 0, EYE_DEPTH])}
        k = np.linalg.norm(eyes["right"] - eyes["left"]) / np.linalg.norm(mine["right"] - mine["left"])
        c_mine = (mine["right"] + mine["left"]) / 2
        c_goal = (eyes["right"] + eyes["left"]) / 2
        Vp = (V - c_mine) * k + c_goal
        # `fidelity.neck_cut` "smooth": his neck cut as a clean cylinder, not by Rodin's own colours
        # (that cut zigzagged along the mesh and left spikes under his jaw).
        UVk = UV
        if fid.get("neck_cut") == "smooth":
            Vp, Tk, UVk = clip_part(Vp, T, UV, (pts - c_mine) * k + c_goal)
        else:
            Tk = head_part(Vp, T, UV, (pts - c_mine) * k + c_goal, mesh.get("own"))
        # One vertex per position (Rodin's corners come split at every UV seam: left so, the mesh
        # is a triangle soup that decimation tears and nothing shades smooth across), each
        # corner keeping its own UV.
        key = np.round(Vp[np.unique(Tk)] / 1e-6).astype(np.int64)
        used = np.unique(Tk)
        _u, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
        weld_of = -np.ones(len(Vp), int)
        weld_of[used] = inv.ravel()
        Vh = Vp[used][first]
        Th = weld_of[Tk]
        corner_uv = UVk[Tk]
        keep = (Th[:, 0] != Th[:, 1]) & (Th[:, 1] != Th[:, 2]) & (Th[:, 0] != Th[:, 2])
        Th, corner_uv = Th[keep], corner_uv[keep]
        chin_y = ((pts[152] - c_mine) * k + c_goal)[1]
        me = bpy.data.meshes.new("body_head")
        me.from_pydata([mp.to_blender(p) for p in Vh], [], Th.tolist())
        uvl = me.uv_layers.new(name="UVMap")
        for pi, poly in enumerate(me.polygons):
            poly.use_smooth = True
            for c, li in enumerate(poly.loop_indices):
                u, v = corner_uv[pi][c]
                uvl.data[li].uv = (u, 1.0 - v)
        obj = bpy.data.objects.new("body_head", me)
        bpy.context.scene.collection.objects.link(obj)
        arm = bpy.data.objects["Skeleton"]
        for b in env["bones"]:
            obj.vertex_groups.new(name=b)
        t = np.clip((chin_y - NECK_BLEND[0] - Vh[:, 1]) / (NECK_BLEND[1] - NECK_BLEND[0]), 0, 1)
        for i, w in enumerate(t):
            obj.vertex_groups["head"].add([i], float(1 - w) if w < 1 else 0.0, "REPLACE")
            if w > 0:
                obj.vertex_groups["neck"].add([i], float(w), "REPLACE")
        # His eyes, lids and mouth keep their detail when he's cut down (the game's wet-eye glint
        # filled a whole flat triangle of lower lid): DETAIL_M round each, weighted.
        det = obj.vertex_groups.new(name="detail")
        feats = [eyes["right"], eyes["left"], ((pts[13] - c_mine) * k + c_goal)]
        # His sideburns too, when they stand off his cheeks (`fidelity.sideburns_m`): cut down
        # with the rest of his head, their relief was flattened away. Each between the front of
        # his ear (234 / 454) and the angle of his jaw (172 / 397).
        if fid.get("sideburns_m"):
            for edge, jaw in ((234, 172), (454, 397)):
                for t in (0.0, 0.5, 1.0):
                    feats.append(((pts[edge] * (1 - t) + pts[jaw] * t) - c_mine) * k + c_goal)
        dmin = np.min([np.linalg.norm(Vh - f, axis=1) for f in feats], axis=0)
        for i, d in enumerate(dmin):
            if d < DETAIL_M:
                det.add([i], float(1.0 - d / DETAIL_M), "REPLACE")
        tris = len(Th)
        if tris > HEAD_TRIS:
            mod = obj.modifiers.new("decimate", "DECIMATE")
            mod.ratio = HEAD_TRIS / tris
            mod.use_collapse_triangulate = True
            mod.vertex_group = "detail"
            mod.invert_vertex_group = True   # the weighted vertices are the ones kept
            mod.vertex_group_factor = 10.0
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier="decimate")
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
        rep["source"] = "rodin_portrait"
        rep["eyes"] = {s: [round(float(x), 4) for x in eyes[s]] for s in eyes}
        rep["head"] = {"from": "assets/people/tripo/test/%s_rodin.glb" % spec.get("shape", man), "scale": round(float(k), 4),
                       "triangles": len(obj.data.polygons), "paint": "rodin_portrait.py (the style portraits)"}
        rep["triangles"]["head"] = len(obj.data.polygons)
        g = obj.vertex_groups.get("detail")
        if g is not None:
            obj.vertex_groups.remove(g)
        vs = np.array([v.co[:] for v in obj.data.vertices])
        body = np.stack([vs[:, 0], vs[:, 2], -vs[:, 1]], 1)  # Blender → body space (mp.to_blender's inverse)
        cen = np.array([body[list(p_.vertices)].mean(0) for p_ in obj.data.polygons])
        near_eyes = np.min([np.linalg.norm(cen - f, axis=1) for f in feats[:2]], axis=0) < 0.02
        rep["head"]["triangles_round_eyes"] = int(near_eyes.sum())
        rep["triangles"].pop("hair", None)
        # The factory's collar stands up to the factory man's chin; Rodin's face is longer, so with
        # his eyes on the anatomy's his chin is lower and the collar cut through his throat (grey
        # and red bits under his jaw): its top squeezed down under his chin.
        h0 = chin_y - COLLAR_FROM
        lowered = {}
        for name in ("cloth_shirt", "cloth_cravat"):
            o = bpy.data.objects.get(name)
            if o is None:
                continue
            mw, inv = o.matrix_world, o.matrix_world.inverted()
            n = 0
            for v in o.data.vertices:
                w = mw @ v.co
                if w.z > h0 and abs(w.x) < 0.12:     # Blender's Z is his height
                    w.z = h0 + (w.z - h0) * COLLAR_KEEP
                    v.co = inv @ w
                    n += 1
            lowered[name.split("_", 1)[1]] = n
        rep["head"]["collar_lowered"] = lowered
        # The factory body's neck ends in a ragged fringe where its own head came off; above
        # SKIN_CUT under his chin his head covers it (down to NECK_DOWN), so it goes
        # (`fidelity.neck_cut` "smooth"): its spikes poked out beside his jaw, bright under the
        # ears (2026-10-14).
        if fid.get("neck_cut") == "smooth":
            import bmesh
            skin_o = bpy.data.objects.get("body_skin")
            if skin_o is not None:
                bm = bmesh.new()
                bm.from_mesh(skin_o.data)
                cut_z = chin_y - SKIN_CUT          # Blender's Z is his height
                gone = [f for f in bm.faces if all(v.co.z > cut_z for v in f.verts)]
                bmesh.ops.delete(bm, geom=gone, context="FACES")
                bm.to_mesh(skin_o.data)
                bm.free()
                rep["head"]["skin_faces_cut"] = len(gone)
        # His own hat (rodin_portrait.py's, from style_hat.py): three rigid pieces on his head
        # bone, moved with his head; they take the place of BodyMesh's (people_bodies.gd: a model's
        # own `hat`, `hat_brim`, `hat_band` replace the game's).
        hat_path = os.path.join(RP.WORK, man + "_hat.npy")
        if spec.get("hat") and spec["hat"].get("wear", True) and os.path.exists(hat_path):
            hat = np.load(hat_path, allow_pickle=True).item()
            for part, d in hat.items():
                Vh2 = (d["V"] - c_mine) * k + c_goal
                me2 = bpy.data.meshes.new("cloth_" + part)
                me2.from_pydata([mp.to_blender(p_) for p_ in Vh2], [], d["T"].tolist())
                uv2 = me2.uv_layers.new(name="UVMap")
                for poly in me2.polygons:
                    poly.use_smooth = True
                    for vi, li in zip(poly.vertices, poly.loop_indices):
                        u, v = d["UV"][vi]
                        uv2.data[li].uv = (u, 1.0 - v)
                o2 = bpy.data.objects.new("cloth_" + part, me2)
                bpy.context.scene.collection.objects.link(o2)
                for b in env["bones"]:
                    o2.vertex_groups.new(name=b)
                o2.vertex_groups["head"].add(list(range(len(Vh2))), 1.0, "REPLACE")
                m2 = o2.modifiers.new("skeleton", "ARMATURE")
                m2.object = arm
                o2.parent = arm
                rep["triangles"][part] = len(me2.polygons)
            rep["hat"] = "his own (style_hat.py)"
        made["ok"] = True
        export(person)

    # `fidelity.garment_budget`: his clothes cut down less (the factory's budgets are small, and
    # cutting a garment down eats its edges: the vest's collar and armholes came out as spikes).
    if fid.get("garment_budget"):
        import clothes as _clothes
        for g in list(_clothes.BUDGET):
            _clothes.BUDGET[g] = int(_clothes.BUDGET[g] * float(fid["garment_budget"]))
    FB.paint_head = lambda *_a, **_k: np.zeros((FB.HEAD_TEX, FB.HEAD_TEX, 3))
    FB.shells = lambda *_a, **_k: []
    FB.mp.export = export_with_rodin_head
    try:
        FB.build(pid, fspec, env, factory)
    finally:
        FB.mp.export = export
    shutil.copy(paint, os.path.join(mp.OUT, pid + "_head.png"))
    for part in ("hat", "hat_brim", "hat_band"):
        src = os.path.join(RP.WORK, "%s_%s.png" % (man, part))
        if spec.get("hat") and spec["hat"].get("wear", True) and os.path.exists(src):
            shutil.copy(src, os.path.join(mp.OUT, "%s_%s.png" % (pid, part)))
    print("rodin_portrait: built", pid, made)
