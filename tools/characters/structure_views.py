"""Where does a man's 3D form come from? Grey renders of his head (the characters session's
structure diagnosis, docs/screenshots/tripo/experiments/): geometry, normal map and shading apart.

    ~/bpyenv/bin/python tools/characters/structure_views.py --out=DIR [--what=a,b,c,d] [--size=640]
        [--samples=48] [--man=stranger2s]

  a  the Rodin man as made (tripo/<rodin>.glb, people.json `shape` or `rodin`), grey, with his
     normal map
  b  the same, grey, without it: his geometry alone
  c  the fitted man as the game has him (assets/people/<man>.glb: his head and body), grey: the
     geometry after the fit
  d  the fitted man with the Rodin normal map carried onto him: his own UVs are the square layout,
     so the Rodin man as made (same triangles, moved by the fit) is moved onto him first, point by
     point (nearest point, his head only), and rendered with its normal map in that place

Each in Cycles (CPU), orthographic, plain grey (albedo 0.45, roughness 0.75), lit by one warm key
from his right front above and a dim fill, from the front, three-quarters (35 degrees toward his
right) and his right side, his head filling the frame: <what>_<view>.png. Then close crops of his
ear (side), nose and nostrils (three-quarters, from below a little), lips (front) and eyelids
(front): <what>_<feature>.png, framed from his drawn eyes in the fit report (assets/people/<man>.json
`eyes`, our body space) for c and d, and the Rodin man's own frame for a and b by the same offsets.
"""
import json
import math
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PEOPLE = os.path.join(ROOT, "assets", "people")
GREY = 0.45

# Feature crops, framed on his own MediaPipe landmarks (tripo/<rodin>_face.json): (camera yaw toward
# his right, pitch up, the landmarks whose middle is the centre, an offset from it in metres (his
# right +, up +, forward +), frame height in metres). The ear: from his right side, behind the
# landmark at his right cheek's edge (234 or 454, whichever is on his right).
FEATURES = {
    "ear": (90.0, 0.0, ["ear"], (0.0, 0.005, -0.03), 0.08),
    "nose": (35.0, -15.0, [1, 98, 327], (0.0, 0.0, 0.0), 0.065),
    "lips": (0.0, 0.0, [13, 14, 61, 291], (0.0, 0.0, 0.0), 0.065),
    "eyelids": (0.0, 0.0, [159, 386, 145, 374], (0.0, 0.0, 0.0), 0.10),
    "nostrils": (0.0, -35.0, [98, 327, 2], (0.0, 0.0, 0.0), 0.05),
}
VIEWS = {"front": 0.0, "three_quarter": 35.0, "side": 90.0}


def args():
    o = {"out": "/tmp/structure", "what": "a,b,c,d", "size": 640, "samples": 48, "man": "stranger2s"}
    for a in sys.argv[1:]:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            o[k] = v
    o["size"], o["samples"] = int(o["size"]), int(o["samples"])
    return o


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_glb(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    return [ob for ob in bpy.data.objects if ob not in before]


def greyed(ob, normal_map):
    """Every material on `ob` turned plain grey, its normal map kept or dropped."""
    for slot in ob.material_slots:
        m = slot.material
        if m is None or not m.use_nodes:
            continue
        nt = m.node_tree
        bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        for name in ("Base Color", "Metallic", "Roughness", "Alpha", "Emission Color"):
            inp = bsdf.inputs.get(name)
            if inp is not None:
                for link in list(inp.links):
                    nt.links.remove(link)
        bsdf.inputs["Base Color"].default_value = (GREY, GREY, GREY, 1.0)
        bsdf.inputs["Metallic"].default_value = 0.0
        bsdf.inputs["Roughness"].default_value = 0.75
        if not normal_map:
            for link in list(bsdf.inputs["Normal"].links):
                nt.links.remove(link)


def body_frame_matrix(rodin):
    """glTF's import puts glTF (x, y, z) at Blender (x, -z, y). Our body space is glTF's space as
    the fitted glb has it (facing -Z, his right +X). A Rodin man is built facing +Z with his right at
    -X: turned half round about the vertical (Blender's Z) to face as the fitted man does."""
    return Matrix.Rotation(math.pi, 4, "Z") if rodin else Matrix.Identity(4)


def to_blender(p):
    """Our body space (glTF's axes) → Blender's."""
    return Vector((p[0], -p[2], p[1]))


def setup_scene(o):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = o["samples"]
    try:
        sc.cycles.use_denoising = True
    except Exception:
        pass
    sc.render.resolution_x = sc.render.resolution_y = o["size"]
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.18, 0.18, 0.19, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    sc.world = world
    key = bpy.data.lights.new("key", "SUN")
    key.energy = 3.2
    key.angle = math.radians(3.0)
    key.color = (1.0, 0.92, 0.82)
    k = bpy.data.objects.new("key", key)
    sc.collection.objects.link(k)
    # From his right front, above (he faces +Y in Blender, his right +X).
    # Low enough that his brim doesn't shade his face: the form, not the hat's shadow, is the question.
    k.rotation_euler = (-Vector((0.55, 0.75, 0.2))).to_track_quat("-Z", "Y").to_euler()
    fill = bpy.data.lights.new("fill", "SUN")
    fill.energy = 0.5
    fill.color = (0.8, 0.85, 1.0)
    f = bpy.data.objects.new("fill", fill)
    sc.collection.objects.link(f)
    f.rotation_euler = (-Vector((-0.7, 0.3, 0.2))).to_track_quat("-Z", "Y").to_euler()
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam = bpy.data.objects.new("cam", cam_data)
    sc.collection.objects.link(cam)
    sc.camera = cam
    return cam


def aim(cam, centre, yaw, pitch, height):
    """Look at `centre` (Blender space) from in front of him (he faces +Y: glTF's -Z), turned `yaw`
    degrees toward his right (+X) and `pitch` up."""
    y, p = math.radians(yaw), math.radians(pitch)
    d = Vector((math.sin(y) * math.cos(p), math.cos(y) * math.cos(p), math.sin(p)))
    cam.location = centre + d * 2.0
    cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    cam.data.ortho_scale = height
    cam.data.clip_start = 0.01
    cam.data.clip_end = 10.0


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print("wrote", path)


def eyes_of(man):
    """His drawn eyes in our body space (the fit report), his right first."""
    e = json.load(open(os.path.join(PEOPLE, man + ".json")))["eyes"]
    return [np.array(e["right"]), np.array(e["left"])]


def rodin_glb(man):
    spec = json.load(open(os.path.join(PEOPLE, "people.json")))["people"][man]
    return os.path.join(PEOPLE, "tripo", (spec.get("shape") or spec["rodin"]) + ".glb")


def mesh_points(ob):
    me = ob.data
    co = np.zeros(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    mw = np.array(ob.matrix_world)
    return co @ mw[:3, :3].T + mw[:3, 3]


def rodin_eyes_blender(rodin_ob, man, all_points=False):
    """The Rodin man's iris centres (MediaPipe's 468 and 473, tripo/<rodin>_face.json, in
    head_paint's frame) where they are on his mesh in Blender's space as imported."""
    spec = json.load(open(os.path.join(PEOPLE, "people.json")))["people"][man]
    face = json.load(open(os.path.join(PEOPLE, "tripo", spec.get("shape", spec["rodin"]) + "_face.json")))
    q = np.array(face["points"]) if all_points else np.array([face["points"][468], face["points"][473]])
    me = rodin_ob.data
    co = np.zeros(len(me.vertices) * 3)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)                                          # his own (unturned) points
    g = np.stack([co[:, 0], co[:, 2], -co[:, 1]], axis=1)          # Blender → glTF's axes
    t = np.stack([g[:, 2], g[:, 1], -g[:, 0]], axis=1)              # head_paint.rodin_frame's turn
    y0, h = t[:, 1].min(), t[:, 1].max() - t[:, 1].min()
    t = (t - [0, y0, 0]) / h
    c = np.array([(t[:, 0].min() + t[:, 0].max()) / 2, 0.0, (t[:, 2].min() + t[:, 2].max()) / 2])
    tt = (q + c) * h + [0, y0, 0]
    gg = np.stack([-tt[:, 2], tt[:, 1], tt[:, 0]], axis=1)
    local = np.stack([gg[:, 0], -gg[:, 2], gg[:, 1]], axis=1)
    mw = np.array(rodin_ob.matrix_world)
    return local @ mw[:3, :3].T + mw[:3, 3]


def place_rodin_on_fitted(rodin_ob, fitted_obs, eyes_fit, man, snap=False):
    """The Rodin man moved onto the fitted man (same triangles, moved by the fit): his irises onto
    the fitted man's drawn eyes (their middle, and their spacing for scale), then a few rounds of
    rigid ICP over his face (the scale from his eyes' spacing) (within FACE_R of the eyes). `snap`: then each face point onto
    its nearest fitted point, so the geometry is the fitted man's and the UVs Rodin's (d)."""
    from mathutils.kdtree import KDTree
    face_r = 0.11
    eyes_fit = np.array(eyes_fit)
    fit_pts = np.concatenate([mesh_points(o) for o in fitted_obs if o.type == "MESH"])
    fit_face = fit_pts[np.linalg.norm(fit_pts - eyes_fit.mean(axis=0), axis=1) < face_r + 0.03]
    rp = mesh_points(rodin_ob)
    re = rodin_eyes_blender(rodin_ob, man, all_points=True)
    lm_pts, re = re, re[[468, 473]]
    lm_idx = np.array([np.argmin(np.linalg.norm(rp - q, axis=1)) for q in lm_pts])
    s = np.linalg.norm(eyes_fit[0] - eyes_fit[1]) / max(np.linalg.norm(re[0] - re[1]), 1e-9)
    moved = (rp - re.mean(axis=0)) * s + eyes_fit.mean(axis=0)
    tree = KDTree(len(fit_face))
    for i, p in enumerate(fit_face):
        tree.insert(p, i)
    tree.balance()
    near = np.linalg.norm(moved - eyes_fit.mean(axis=0), axis=1) < face_r
    for _ in range(12):
        src = moved[near]
        dst = np.array([tree.find(p)[0] for p in src])
        mu_s, mu_d = src.mean(axis=0), dst.mean(axis=0)
        u, sv, vt = np.linalg.svd((src - mu_s).T @ (dst - mu_d))
        d = np.diag([1.0, 1.0, np.sign(np.linalg.det(vt.T @ u.T))])
        r = vt.T @ d @ u.T
        moved = (moved - mu_s) @ r.T + mu_d     # rigid: a free scale lets nearest-point ICP shrink him
    err = np.array([tree.find(p)[2] for p in moved[near]])
    print("  the Rodin face on the fitted one: median %.2f mm, 95th percentile %.2f mm"
          % (np.median(err) * 1000, np.percentile(err, 95) * 1000))
    if snap:
        idx = np.nonzero(near)[0]
        hits = [tree.find(moved[i]) for i in idx]
        ok = np.array([h[2] < 0.004 for h in hits])
        moved[idx[ok]] = np.array([h[0] for h, k in zip(hits, ok) if k])
        print("  d: %d of %d face points snapped onto the fitted face" % (ok.sum(), len(idx)))
    mw_inv = np.array(rodin_ob.matrix_world.inverted())
    local = moved @ mw_inv[:3, :3].T + mw_inv[:3, 3]
    rodin_ob.data.vertices.foreach_set("co", local.ravel())
    rodin_ob.data.update()
    return moved[lm_idx]


def main():
    o = args()
    os.makedirs(o["out"], exist_ok=True)
    eyes_body = eyes_of(o["man"])
    eyes_fit = [to_blender(e) for e in eyes_body]
    for what in o["what"].split(","):
        if what not in "abcd":
            continue
        clear()
        cam = setup_scene(o)
        # Every variant places the Rodin man on the fitted one (a, b: moved as a whole; d: each face
        # point snapped onto the fitted face), which gives his landmarks where the fitted man has them.
        rodin = import_glb(rodin_glb(o["man"]))
        for ob in rodin:
            if ob.parent is None:
                ob.matrix_world = body_frame_matrix(True) @ ob.matrix_world
        bpy.context.view_layer.update()
        fitted = import_glb(os.path.join(PEOPLE, o["man"] + ".glb"))
        mesh = next(ob for ob in rodin if ob.type == "MESH")
        lm = place_rodin_on_fitted(mesh, fitted, eyes_fit, o["man"], snap=what == "d")
        keep, drop = (fitted, rodin) if what == "c" else (rodin, fitted)
        for ob in drop:
            bpy.data.objects.remove(ob, do_unlink=True)
        for ob in keep:
            if ob.type == "MESH":
                greyed(ob, what in ("a", "d"))
        eyes_b = np.mean([np.array(e) for e in eyes_fit], axis=0)
        head_c = Vector(eyes_b) + Vector((0.0, -0.02, 0.02))
        for view, yaw in VIEWS.items():
            aim(cam, head_c, yaw, 0.0, 0.30)
            render(os.path.join(o["out"], "%s_%s.png" % (what, view)))
        ear = lm[234] if lm[234][0] > lm[454][0] else lm[454]
        for feat, (yaw, pitch, marks, off, height) in FEATURES.items():
            c = np.mean([ear if m == "ear" else lm[m] for m in marks], axis=0)
            aim(cam, Vector(c) + Vector((off[0], off[2], off[1])), yaw, pitch, height)
            render(os.path.join(o["out"], "%s_%s.png" % (what, feat)))

if __name__ == "__main__":
    main()
