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
EYE_DEPTH = 0.011         # an eye's middle behind its iris
HEAD_TRIS = 12000
NECK_BLEND = (0.02, 0.06)  # under his chin: all head above the first, all neck below the second


def head_part(V, T, UV, pts):
    """The faces of the bust that are his head and neck (not his collar and shoulders)."""
    chin_y = pts[152, 1]
    ring = (V[:, 1] < chin_y - 0.03) & (V[:, 1] > chin_y - 0.05) & (np.abs(V[:, 0]) < 0.06)
    neck_c = np.array([np.median(V[ring, 0]), np.median(V[ring, 2])]) if ring.any() else np.array([0.0, pts[152, 2] + 0.05])
    r = np.hypot(V[:, 0] - neck_c[0], V[:, 2] - neck_c[1])
    keep_v = (V[:, 1] > chin_y - CUT_BELOW_CHIN) | ((V[:, 1] > chin_y - NECK_DOWN) & (r < NECK_RADIUS))
    keep = keep_v[T].all(1)
    return T[keep]


def build(man, spec):
    pid = man + "_rodin"
    mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
    V, T, UV, pts = mesh["V"], mesh["T"], mesh["UV"], mesh["pts"]
    paint = os.path.join(RP.WORK, man + "_paint.png")
    env = json.load(open(mp.ENVELOPE))
    factory = F.load_factory()
    fspec = {"source": "factory", "targets": dict(P.DEFAULT_MACRO), "hair": "none", "moustache": "none",
             "beard": "none", "skin": "#b07a5a", "outfit": spec.get("outfit", {})}
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
        Tk = head_part(Vp, T, UV, (pts - c_mine) * k + c_goal)
        used = np.unique(Tk)
        remap = -np.ones(len(Vp), int)
        remap[used] = np.arange(len(used))
        Vh, Th, UVh = Vp[used], remap[Tk], UV[used]
        chin_y = ((pts[152] - c_mine) * k + c_goal)[1]
        me = bpy.data.meshes.new("body_head")
        me.from_pydata([mp.to_blender(p) for p in Vh], [], Th.tolist())
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                u, v = UVh[me.loops[li].vertex_index]
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
        tris = len(Th)
        if tris > HEAD_TRIS:
            mod = obj.modifiers.new("decimate", "DECIMATE")
            mod.ratio = HEAD_TRIS / tris
            mod.use_collapse_triangulate = True
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier="decimate")
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
        rep["source"] = "rodin_portrait"
        rep["eyes"] = {s: [round(float(x), 4) for x in eyes[s]] for s in eyes}
        rep["head"] = {"from": "assets/people/tripo/test/%s_rodin.glb" % man, "scale": round(float(k), 4),
                       "triangles": len(obj.data.polygons), "paint": "rodin_portrait.py (the style portraits)"}
        rep["triangles"]["head"] = len(obj.data.polygons)
        rep["triangles"].pop("hair", None)
        made["ok"] = True
        export(person)

    FB.paint_head = lambda *_a, **_k: np.zeros((FB.HEAD_TEX, FB.HEAD_TEX, 3))
    FB.shells = lambda *_a, **_k: []
    FB.mp.export = export_with_rodin_head
    try:
        FB.build(pid, fspec, env, factory)
    finally:
        FB.mp.export = export
    shutil.copy(paint, os.path.join(mp.OUT, pid + "_head.png"))
    print("rodin_portrait: built", pid, made)
