"""Your arms painted (Sean, 2026-10-24: "next you need to paint the arms"): the held arm is Sean's
Studio man's own (HeldHand cuts it from his model), drawn in his skin's texture: flat orange, no
painted light. This repaints it in the men's hand the way the guns were (guns_blender.py):

    $B arm_blender.py --base     # his right arm from four sides, flat in his own texture, one sheet:
                                 # docs/concept/guns/arm_base.png and assets/textures/guns/arm.json
    (the sheet repainted by tools/textures/paint_reference.py: references.json `arm`, on GitHub)
    $B arm_blender.py --bake     # the painting projected back onto both arms (the left the right's
                                 # mirror) through his UVs: assets/weapons/held_arm_skin.png, his
                                 # skin's texture with the arms' texels painted (HeldHand draws it)

Each texel of the arms takes the views that face it, weighted by how squarely (a view's depth
buffer keeps a finger from painting the palm behind it). Run with Blender's Python (bpy 5.0).
"""
import json
import math
import os
import sys

import bpy
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
MODEL = "sean_s3_talking"
GLB = os.path.join(ROOT, "assets", "people", "%s.glb" % MODEL)
SKIN = os.path.join(ROOT, "assets", "people", "%s_skin.png" % MODEL)
BASE = os.path.join(ROOT, "docs", "concept", "guns", "arm_base.png")
CANVAS = os.path.join(ROOT, "assets", "textures", "guns", "arm.json")
PAINTED = os.path.join(ROOT, "assets", "textures", "guns", "gun_arm_painted.jpg")
OUT = os.path.join(ROOT, "assets", "weapons", "held_arm_skin.png")
## The four views: the direction each looks along (Blender space, Z up; the man faces -Y).
VIEWS = [("out", (-1.0, 0.0, 0.0)), ("front", (0.0, 1.0, 0.0)), ("in", (1.0, 0.0, 0.0)),
         ("back", (0.0, -1.0, 0.0))]
PANEL_PX = (256, 1024)   # each view's width and height in the sheet (four across: 1024 square)
MARGIN = 0.04            # m round the arm in each view
FINGERS = ["index", "middle", "ring", "little", "thumb"]


def arm_bones(side):
    names = ["upper_arm_" + side, "forearm_" + side, "hand_" + side]
    for f in FINGERS:
        names += ["finger_%s_%s_%d" % (f, side, k) for k in range(3)]
    return names


def load():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=GLB)
    return bpy.data.objects["body_skin"]


def cut_arm(body, side):
    """A copy of his skin's mesh with only the faces on `side`'s arm (each vertex on the bone that
    carries it most, as HeldHand.source cuts it)."""
    want = set(arm_bones(side))
    groups = {g.index: g.name for g in body.vertex_groups}
    me = body.data
    on = np.zeros(len(me.vertices), bool)
    for v in me.vertices:
        if v.groups:
            best = max(v.groups, key=lambda g: g.weight)
            on[v.index] = groups.get(best.group, "") in want
    ob = body.copy()
    ob.data = me.copy()
    ob.name = "arm_" + side
    bpy.context.collection.objects.link(ob)
    for m in list(ob.modifiers):
        ob.modifiers.remove(m)
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bm.verts.ensure_lookup_table()
    drop = [f for f in bm.faces if not all(on[v.index] for v in f.verts)]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(ob.data)
    bm.free()
    ob.data.transform(ob.matrix_world)
    ob.matrix_world.identity()
    return ob


def basis(d):
    d = np.array(d)
    up = np.array((0.0, 0.0, 1.0))
    right = np.cross(d, up)
    return d, right / np.linalg.norm(right), up


def canvas_for(arm):
    """Each view's centre and the sheet's scale, from the arm's own extent."""
    pts = np.array([v.co[:] for v in arm.data.vertices])
    zmin, zmax = pts[:, 2].min() - MARGIN, pts[:, 2].max() + MARGIN
    height = zmax - zmin
    width = height * PANEL_PX[0] / PANEL_PX[1]
    views = []
    for name, d in VIEWS:
        d, right, _up = basis(d)
        h = pts @ right
        views.append({"name": name, "dir": d.tolist(), "right": right.tolist(),
                      "centre": float((h.min() + h.max()) * 0.5)})
    return {"views": views, "zmin": float(zmin), "height": float(height), "width": float(width),
            "panel_px": list(PANEL_PX), "model": MODEL}


def flat_material(img):
    """His texture as it is, unlit (the base the painter repaints)."""
    mat = bpy.data.materials.new("flat")
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.links.new(tex.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    return mat


def base():
    body = load()
    arm = cut_arm(body, "r")
    for ob in list(bpy.data.objects):
        if ob != arm:
            bpy.data.objects.remove(ob)
    cv = canvas_for(arm)
    skin = bpy.data.images.load(SKIN)
    arm.data.materials.clear()
    arm.data.materials.append(flat_material(skin))
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.view_settings.view_transform = "Standard"
    scene.render.resolution_x, scene.render.resolution_y = PANEL_PX
    scene.render.film_transparent = True
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = cv["height"]
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    sheet = Image.new("RGB", (PANEL_PX[0] * 4, PANEL_PX[1]), (128, 128, 128))
    tmp = os.path.join(ROOT, "build", "arm_view.png")
    os.makedirs(os.path.dirname(tmp), exist_ok=True)
    from mathutils import Matrix, Vector
    for i, v in enumerate(cv["views"]):
        d = Vector(v["dir"])
        right = Vector(v["right"])
        up = Vector((0, 0, 1))
        centre = right * v["centre"] + up * (cv["zmin"] + cv["height"] * 0.5) - d * 2.0
        # The camera looks down its -Z: its axes are right, up and -d.
        m = Matrix((right, up, -d)).transposed().to_4x4()
        m.translation = centre
        cam.matrix_world = m
        scene.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        im = Image.open(tmp).convert("RGBA")
        panel = Image.new("RGBA", im.size, (128, 128, 128, 255))
        panel.alpha_composite(im)
        sheet.paste(panel.convert("RGB"), (PANEL_PX[0] * i, 0))
    os.makedirs(os.path.dirname(BASE), exist_ok=True)
    sheet.save(BASE)
    os.makedirs(os.path.dirname(CANVAS), exist_ok=True)
    json.dump(cv, open(CANVAS, "w"), indent=1)
    print("WROTE", BASE, CANVAS)


def bake_maps(arms, size):
    """Each arm texel's position and normal (Blender space), baked through his UVs: two float
    images and a mask of which texels the arms cover."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    scene.render.bake.margin = 4
    out = {}
    for what in ("pos", "nrm"):
        img = bpy.data.images.new(what, size, size, alpha=True, float_buffer=True)
        img.pixels.foreach_set(np.zeros(size * size * 4, np.float32))
        mat = bpy.data.materials.new(what)
        mat.use_nodes = True
        nt = mat.node_tree
        for nd in list(nt.nodes):
            nt.nodes.remove(nd)
        o = nt.nodes.new("ShaderNodeOutputMaterial")
        emit = nt.nodes.new("ShaderNodeEmission")
        geo = nt.nodes.new("ShaderNodeNewGeometry")
        # Kept positive (a bake's colour isn't trusted below zero): position + 4 m, normal / 2 + 1/2.
        vm = nt.nodes.new("ShaderNodeVectorMath")
        vm.operation = "MULTIPLY_ADD"
        nt.links.new(geo.outputs["Position" if what == "pos" else "Normal"], vm.inputs[0])
        vm.inputs[1].default_value = (1.0, 1.0, 1.0) if what == "pos" else (0.5, 0.5, 0.5)
        vm.inputs[2].default_value = (4.0, 4.0, 4.0) if what == "pos" else (0.5, 0.5, 0.5)
        nt.links.new(vm.outputs[0], emit.inputs["Color"])
        nt.links.new(emit.outputs[0], o.inputs["Surface"])
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.nodes.active = tex
        for arm in arms:
            arm.data.materials.clear()
            arm.data.materials.append(mat)
        bpy.ops.object.select_all(action="DESELECT")
        for arm in arms:
            arm.select_set(True)
        bpy.context.view_layer.objects.active = arms[0]
        bpy.ops.object.bake(type="EMIT", use_clear=False)
        a = np.zeros(size * size * 4, np.float32)
        img.pixels.foreach_get(a)
        out[what] = a.reshape(size, size, 4)
    mask = out["pos"][..., 3] > 0.5
    pos = out["pos"][..., :3] - 4.0
    nrm = out["nrm"][..., :3] * 2.0 - 1.0
    nrm /= np.maximum(np.linalg.norm(nrm, axis=-1, keepdims=True), 1e-6)
    return mask, pos, nrm


def bake():
    body = load()
    arms = [cut_arm(body, "r"), cut_arm(body, "l")]
    for ob in list(bpy.data.objects):
        if ob not in arms:
            bpy.data.objects.remove(ob)
    cv = json.load(open(CANVAS))
    skin = np.asarray(Image.open(SKIN).convert("RGB")).astype(np.float32)
    size = skin.shape[0]
    mask, pos, nrm = bake_maps(arms, size)
    # The left arm takes the right's painting in the mirror.
    left = pos[..., 0] < 0.0
    pos[left, 0] *= -1.0
    nrm[left, 0] *= -1.0
    paint = np.asarray(Image.open(PAINTED).convert("RGB").resize(
        (PANEL_PX[0] * 4, PANEL_PX[1]), Image.LANCZOS)).astype(np.float32)
    ph, pw = paint.shape[:2]
    acc = np.zeros(skin.shape, np.float32)
    wsum = np.zeros(skin.shape[:2], np.float32)
    ys, xs = np.nonzero(mask)
    p = pos[ys, xs]
    n = nrm[ys, xs]
    for i, v in enumerate(cv["views"]):
        d = np.array(v["dir"])
        right = np.array(v["right"])
        px = ((p @ right - v["centre"]) / cv["width"] + 0.5 + i) * PANEL_PX[0]
        py = (1.0 - (p[:, 2] - cv["zmin"]) / cv["height"]) * PANEL_PX[1]
        depth = p @ d
        # The view's depth buffer from the texels themselves: a texel behind another (a palm under
        # its fingers) is hidden in this view.
        ix = np.clip(px.astype(int) // 2, 0, pw // 2 - 1)
        iy = np.clip(py.astype(int) // 2, 0, ph // 2 - 1)
        zbuf = np.full((ph // 2, pw // 2), np.inf, np.float32)
        np.minimum.at(zbuf, (iy, ix), depth)
        seen = depth <= zbuf[iy, ix] + 0.006
        w = np.clip(-(n @ d), 0.0, 1.0) ** 3 * seen
        sx = np.clip(px.astype(int), 0, pw - 1)
        sy = np.clip(py.astype(int), 0, ph - 1)
        acc[ys, xs] += paint[sy, sx] * w[:, None]
        wsum[ys, xs] += w
    out = skin.copy()
    got = mask & (wsum > 1e-4)
    out[got] = acc[got] / wsum[got][:, None]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    Image.fromarray(out.clip(0, 255).astype(np.uint8)).save(OUT)
    print("WROTE", OUT, int(got.sum()), "texels of", int(mask.sum()))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    if "--base" in args:
        base()
    elif "--bake" in args:
        bake()
    else:
        print(__doc__)
