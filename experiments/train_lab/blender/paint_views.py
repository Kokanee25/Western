"""The engine and tender's layout sheet for the paint (train paint, #577): every side the bake needs,
orthographic at one scale (100 px a metre on the 1920 x 1440 layout, rendered at --scale times
that), on a flat grey ground, plus a three-quarter view of the two coupled for the look only. The
image model repaints the sheet in the game's hand keeping every outline; `paint_bake.py` projects the
painting back onto the models from these same views.

    ~/bpyenv/bin/python experiments/train_lab/blender/paint_views.py OUTDIR [--scale=2] [--samples=24]

Writes OUTDIR/layout.png (the clay sheet), OUTDIR/mask.png (each panel's silhouette: the panel's
number + 1 where the model is, 0 on the ground; the three-quarter is 255) and OUTDIR/layout.json
(each panel's rect in layout pixels and its projection: a world point at the rect's top-left, the
world axes along its right and down, pixels a metre, the view's direction toward the camera).
The clay: diffuse colours by material (no metal, so nothing goes black), an even sky and a soft
light from above, so every form reads. The tender's trucks are drawn here for the picture only
(the game draws its own).

Blender's frame is the glb's: +Y the car's front, +Z up, +X its right side.
"""
import json
import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def arg(name, default):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


OUT = os.path.abspath([a for a in sys.argv[1:] if not a.startswith("--")][-1])
SCALE = int(arg("scale", "2"))
SAMPLES = int(arg("samples", "24"))
PPM = 100  # layout pixels a metre
W, H = 1920, 1440
GAP = 20
GROUND = (128, 128, 128)
# The clay's colours (sRGB 0-255): readable mid values in the plain livery's hues.
CLAY = {
    "iron": (58, 58, 62), "jacket": (96, 112, 126), "brass": (176, 136, 60), "red": (140, 40, 30),
    "wood": (120, 74, 40), "steel": (128, 128, 132), "coal": (34, 34, 36), "lamp": (230, 200, 130),
    "glass": (70, 84, 88),
}
TENDER_AT = -9.3  # the tender's origin behind the engine's when coupled (y)
TRUCK_Y = (2.0, -2.0)  # the tender's trucks (its own frame)
TRUCK_R = 0.36


def lin(c):
    v = c / 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


def clay_materials():
    for m in bpy.data.materials:
        name = m.name.split(".")[0]
        c = CLAY.get(name, (128, 128, 128))
        m.use_nodes = True
        nt = m.node_tree
        for nd in list(nt.nodes):
            nt.nodes.remove(nd)
        out = nt.nodes.new("ShaderNodeOutputMaterial")
        dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
        dif.inputs["Color"].default_value = (lin(c[0]), lin(c[1]), lin(c[2]), 1.0)
        nt.links.new(dif.outputs[0], out.inputs["Surface"])


def import_car(path, name):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    roots = [o for o in new if o.parent is None]
    holder = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(holder)
    for r in roots:
        r.parent = holder
    return holder, new


def tender_trucks(holder):
    """Arch-bar trucks for the picture: two wheelsets a truck, side frames, a bolster."""
    bm = bmesh.new()
    for ty in TRUCK_Y:
        for dy in (-0.75, 0.75):
            for s in (-1, 1):
                r = bmesh.ops.create_cone(bm, cap_ends=True, segments=24, radius1=TRUCK_R, radius2=TRUCK_R,
                                          depth=0.1)
                m = Matrix.Translation((s * 0.5, ty + dy, TRUCK_R)) @ Matrix.Rotation(math.pi / 2, 4, "Y")
                for v in r["verts"]:
                    v.co = m @ v.co
        for s in (-1, 1):
            r = bmesh.ops.create_cube(bm, size=1.0)
            m = Matrix.Translation((s * 0.62, ty, TRUCK_R + 0.05)) @ Matrix.Diagonal((0.1, 2.1, 0.32, 1))
            for v in r["verts"]:
                v.co = m @ v.co
        r = bmesh.ops.create_cube(bm, size=1.0)
        m = Matrix.Translation((0, ty, 0.5)) @ Matrix.Diagonal((1.4, 0.3, 0.15, 1))
        for v in r["verts"]:
            v.co = m @ v.co
    me = bpy.data.meshes.new("Trucks")
    bm.to_mesh(me)
    bm.free()
    me.materials.append(bpy.data.materials.get("iron") or bpy.data.materials.new("iron"))
    ob = bpy.data.objects.new("Trucks", me)
    bpy.context.collection.objects.link(ob)
    ob.parent = holder
    return ob


def bounds(objs):
    lo = Vector((1e9, 1e9, 1e9))
    hi = -lo
    for o in objs:
        if o.type != "MESH":
            continue
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
    return lo, hi


# A view: its right and down axes in the world and its direction toward the camera.
AXES = {
    "right": (Vector((0, 1, 0)), Vector((0, 0, -1)), Vector((1, 0, 0))),    # front at the picture's right
    "left": (Vector((0, -1, 0)), Vector((0, 0, -1)), Vector((-1, 0, 0))),   # front at the left
    "front": (Vector((-1, 0, 0)), Vector((0, 0, -1)), Vector((0, 1, 0))),   # as you face it: its right at the left
    "back": (Vector((1, 0, 0)), Vector((0, 0, -1)), Vector((0, -1, 0))),    # its right side at the right
    "top": (Vector((0, 1, 0)), Vector((1, 0, 0)), Vector((0, 0, 1))),       # front at the right, right side down
}


def extent(lo, hi, view):
    r, d, _t = AXES[view]
    corners = [Vector((x, y, z)) for x in (lo.x, hi.x) for y in (lo.y, hi.y) for z in (lo.z, hi.z)]
    rs = [c.dot(r) for c in corners]
    ds = [c.dot(d) for c in corners]
    return min(rs), max(rs), min(ds), max(ds)


def panel(name, car, view, lo, hi, x, y):
    r0, r1, d0, d1 = extent(lo, hi, view)
    w = int(math.ceil((r1 - r0) * PPM)) + 8
    h = int(math.ceil((d1 - d0) * PPM)) + 8
    r, d, t = AXES[view]
    # The world point at the rect's top-left: 4 px of margin round the model.
    o = r * (r0 - 4.0 / PPM) + d * (d0 - 4.0 / PPM)
    # ...made a full point: its depth along the view is anywhere on the line; take the far bound.
    return {"name": name, "car": car, "view": view, "rect": [x, y, w, h], "origin": list(o),
            "right": list(r), "down": list(d), "toward": list(t), "ppm": PPM}


def layout(eb, tb):
    """The panels' rects on the 1920 x 1440 layout (rows: right sides, left sides, ends and the
    three-quarter, tops)."""
    ps = []
    y = GAP
    # Row 1: the right sides, tender at the left (the train reads front to the right).
    t = panel("tender_right", "tender", "right", *tb, GAP, y)
    e = panel("engine_right", "engine", "right", *eb, t["rect"][0] + t["rect"][2] + GAP, y)
    ps += [t, e]
    y += max(t["rect"][3], e["rect"][3]) + GAP
    e = panel("engine_left", "engine", "left", *eb, GAP, y)
    t = panel("tender_left", "tender", "left", *tb, e["rect"][0] + e["rect"][2] + GAP, y)
    ps += [e, t]
    y += max(t["rect"][3], e["rect"][3]) + GAP
    x = GAP
    row = []
    for name, car, view, b in (("engine_front", "engine", "front", eb), ("engine_back", "engine", "back", eb),
                               ("tender_front", "tender", "front", tb), ("tender_back", "tender", "back", tb)):
        p = panel(name, car, view, *b, x, y)
        x += p["rect"][2] + GAP
        row.append(p)
    ps += row
    row_h = max(p["rect"][3] for p in row)
    ps.append({"name": "threequarter", "car": "both", "view": "persp", "rect": [x, y, W - GAP - x, row_h]})
    y += row_h + GAP
    e = panel("engine_top", "engine", "top", *eb, GAP, y)
    t = panel("tender_top", "tender", "top", *tb, e["rect"][0] + e["rect"][2] + GAP, y)
    # Tops read with the train: the tender's to the left of the engine's.
    t["rect"][0] = GAP
    e["rect"][0] = GAP + t["rect"][2] + GAP
    ps += [t, e]
    y += max(t["rect"][3], e["rect"][3]) + GAP
    if y > H:
        raise SystemExit("the layout runs %d px past %d" % (y - H, H))
    for p in ps:
        if p["rect"][0] + p["rect"][2] > W - GAP + 1:
            raise SystemExit("%s runs past the layout's width" % p["name"])
    return ps


def setup_scene():
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = False
    sc.render.film_transparent = True
    sc.view_settings.view_transform = "Standard"
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (1.0, 1.0, 1.0, 1.0)
    bg.inputs["Strength"].default_value = 0.75
    sc.world = world
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 1.6
    sun.data.angle = math.radians(30)  # soft
    sun.rotation_euler = (math.radians(25), 0.0, math.radians(20))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    return sc, cam


def show(objs_on, everything):
    for o in everything:
        o.hide_render = o not in objs_on


def render_ortho(sc, cam, p, path):
    r = Vector(p["right"])
    d = Vector(p["down"])
    t = Vector(p["toward"])
    x, y, w, h = p["rect"]
    o = Vector(p["origin"])
    centre = o + r * (w * 0.5 / PPM) + d * (h * 0.5 / PPM) + t * 30.0
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(w, h) / PPM
    cam.data.clip_end = 100.0
    up = -d
    assert abs(r.cross(up).dot(t) - 1.0) < 1e-6, "a view's axes must be right-handed"
    # Blender's camera looks down its -Z with +Y up and +X right.
    m = Matrix((r, up, t)).transposed()
    cam.matrix_world = Matrix.Translation(centre) @ m.to_4x4()
    sc.render.resolution_x = w * SCALE
    sc.render.resolution_y = h * SCALE
    sc.render.pixel_aspect_x = sc.render.pixel_aspect_y = 1.0
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def render_persp(sc, cam, p, path):
    x, y, w, h = p["rect"]
    cam.data.type = "PERSP"
    cam.data.lens = 60
    cam.data.sensor_fit = "HORIZONTAL"
    eye = Vector((13.5, 11.0, 4.2))
    target = Vector((0.0, -3.4, 1.4))
    cam.matrix_world = Matrix.Identity(4)
    cam.location = eye
    cam.rotation_euler = (target - eye).to_track_quat("-Z", "Y").to_euler()
    sc.render.resolution_x = w * SCALE
    sc.render.resolution_y = h * SCALE
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def main():
    from PIL import Image
    import numpy as np
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    eng, eng_objs = import_car(os.path.join(ROOT, "assets", "train", "engine.glb"), "Engine")
    ten, ten_objs = import_car(os.path.join(ROOT, "assets", "train", "tender.glb"), "Tender")
    bpy.context.view_layer.update()
    eb = bounds(eng_objs)
    tb_body = bounds(ten_objs)
    trucks = tender_trucks(ten)
    ten_objs.append(trucks)
    bpy.context.view_layer.update()
    tb = bounds(ten_objs)
    clay_materials()
    sc, cam = setup_scene()
    everything = eng_objs + ten_objs
    ps = layout(eb, tb)
    sheet = Image.new("RGB", (W * SCALE, H * SCALE), GROUND)
    mask = np.zeros((H * SCALE, W * SCALE), np.uint8)
    for i, p in enumerate(ps):
        path = os.path.join(OUT, "panel_%s.png" % p["name"])
        if p["view"] == "persp":
            ten.location = (0.0, TENDER_AT, 0.0)
            bpy.context.view_layer.update()
            show(everything, everything)
            render_persp(sc, cam, p, path)
            ten.location = (0.0, 0.0, 0.0)
            bpy.context.view_layer.update()
            code = 255
        else:
            show(eng_objs if p["car"] == "engine" else ten_objs, everything)
            render_ortho(sc, cam, p, path)
            code = i + 1
        im = Image.open(path).convert("RGBA")
        x, y = p["rect"][0] * SCALE, p["rect"][1] * SCALE
        sheet.paste(im, (x, y), im)
        a = np.asarray(im)[..., 3] > 127
        mask[y:y + a.shape[0], x:x + a.shape[1]][a] = code
        print("panel", p["name"], p["rect"])
    sheet.save(os.path.join(OUT, "layout.png"))
    Image.fromarray(mask).save(os.path.join(OUT, "mask.png"))
    with open(os.path.join(OUT, "layout.json"), "w") as f:
        json.dump({"size": [W, H], "scale": SCALE, "ppm": PPM, "ground": GROUND, "tender_trucks": True,
                   "tender_body_bounds": [list(tb_body[0]), list(tb_body[1])], "panels": ps}, f, indent=1)
    print("WROTE", OUT)


main()
