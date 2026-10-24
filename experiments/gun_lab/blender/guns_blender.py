"""The guns rebuilt in Blender (the gun lab, docs/briefs/gun-remake.md): each part from the shape the
game builds it with in code (views.gd --side writes <gun>_parts.json: its outline or turned profile,
its place in the gun at rest, what it's made of), but made properly: real n-gon faces, bevelled and
rounded edges, smooth turned barrels and cylinder. The gun is unwrapped into one texture and its
side painting (the texture factory's in the men's hand) is baked onto it, each point sampled a few
millimetres inside its part so the tops and ends take their part's paint, not a smeared edge. Out comes
assets/weapons/<gun>.glb, a mesh a part named by its path in the gun ("Hammer__Spur"), which
GunParts.blender_meshes lays on the game's parts (their pivots and moving parts stay the code's).

    python3.11 -m venv V && V/bin/pip install bpy==5.0.1      # Blender as a Python module
    V/bin/python experiments/gun_lab/blender/guns_blender.py --gun=revolver [--size=2048]

Coordinates: the game's (Godot: +Y up, the barrel along -Z) are Blender's (x, -z, y); the glTF
exporter turns them back.
"""
import json
import math
import os
import sys

import bpy  # first: Blender's own modules (bmesh, mathutils) come with it
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def arg(name, default=""):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


GUN = arg("gun", "revolver")
SIZE = int(arg("size", "2048"))
# Godot to Blender: (x, y, z) -> (x, -z, y).
C = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def g2b(v):
    return Vector((v[0], -v[2], v[1]))


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def new_object(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    return ob


def build_profile(name, shape):
    """The outline (local (z, y)) extruded across local x, from -hw to +hw."""
    hw = shape["half_width"]
    pts = shape["outline"]
    bm = bmesh.new()
    right = [bm.verts.new(g2b((hw, p[1], p[0]))) for p in pts]
    left = [bm.verts.new(g2b((-hw, p[1], p[0]))) for p in pts]
    n = len(pts)
    bm.faces.new(right)
    bm.faces.new(list(reversed(left)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((right[i], left[i], left[j], right[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = new_object(name, bm)
    # Rounded edges: a bevel as deep as the code's (a little more), three segments, on the edges
    # sharper than 35 degrees (the outline's own curves stay as drawn, smoothed by the normals).
    width = max(min(shape.get("bevel", 0.0012) * 1.4, hw * 0.42), 0.0003)
    mod = ob.modifiers.new("bevel", "BEVEL")
    mod.width = width
    mod.segments = 3
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(35)
    mod.harden_normals = False
    return ob


def build_turned(name, shape):
    """The (radius, z) profile turned round local Z."""
    prof = shape["profile"]
    sides = max(32, shape.get("sides", 16) * 2)
    bm = bmesh.new()
    rings = []
    for r, z in prof:
        if r <= 1e-6:
            rings.append([bm.verts.new(g2b((0.0, 0.0, z)))])
        else:
            rings.append([bm.verts.new(g2b((r * math.cos(2 * math.pi * k / sides), r * math.sin(2 * math.pi * k / sides), z)))
                          for k in range(sides)])
    for a, b in zip(rings, rings[1:]):
        if len(a) == 1 and len(b) == 1:
            continue
        for k in range(sides):
            k1 = (k + 1) % sides
            if len(a) == 1:
                bm.faces.new((a[0], b[k], b[k1]))
            elif len(b) == 1:
                bm.faces.new((a[k], b[0], a[k1]))
            else:
                bm.faces.new((a[k], b[k], b[k1], a[k1]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return new_object(name, bm)


def build_box(name, shape):
    sx, sy, sz = shape["size"]
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        g = (v.co.x * sx, v.co.y * sy, v.co.z * sz)
        v.co = g2b(g)
    ob = new_object(name, bm)
    mod = ob.modifiers.new("bevel", "BEVEL")
    mod.width = min(sx, sy, sz) * 0.18
    mod.segments = 2
    return ob


def build_tube(name, shape):
    """A cylinder along local Y (Godot's CylinderMesh)."""
    r = shape["radius"]
    h = shape["length"]
    sides = max(24, shape.get("sides", 12) * 2)
    bm = bmesh.new()
    top = [bm.verts.new(g2b((r * math.cos(2 * math.pi * k / sides), h * 0.5, r * math.sin(2 * math.pi * k / sides)))) for k in range(sides)]
    bot = [bm.verts.new(g2b((r * math.cos(2 * math.pi * k / sides), -h * 0.5, r * math.sin(2 * math.pi * k / sides)))) for k in range(sides)]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for k in range(sides):
        k1 = (k + 1) % sides
        bm.faces.new((top[k], bot[k], bot[k1], top[k1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ob = new_object(name, bm)
    mod = ob.modifiers.new("bevel", "BEVEL")
    mod.width = min(r, h) * 0.15
    mod.segments = 2
    mod.limit_method = "ANGLE"
    return ob


BUILD = {"profile": build_profile, "turned": build_turned, "box": build_box, "tube": build_tube}


INSET = 0.002
INSET_MAX = 0.012
ALONG = 40
TOP_DARK = 0.38
## The painting's walnut came back a bright orange beside the men's browns: its oranges are taken
## down this much in saturation and value before the bake (no other colour is touched).
WOOD_SAT = 0.62
WOOD_VAL = 0.8


def graded(png):
    """The painting with its oranges (the walnut) browned, saved beside the bake's scratch."""
    import numpy as np
    from PIL import Image
    im = Image.open(png).convert("RGB").convert("HSV")
    a = np.asarray(im).astype(np.float32)
    hue = a[..., 0] * 360.0 / 255.0
    w = np.clip(1.0 - np.abs(hue - 22.0) / 18.0, 0.0, 1.0) * np.clip((a[..., 1] - 90.0) / 60.0, 0.0, 1.0)
    a[..., 1] *= 1.0 - w * (1.0 - WOOD_SAT)
    a[..., 2] *= 1.0 - w * (1.0 - WOOD_VAL)
    out = os.path.join(ROOT, "build", "gun_%s_graded.png" % GUN)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    rgb = Image.fromarray(a.clip(0, 255).astype(np.uint8), "HSV").convert("RGB")
    rgb.save(out)
    # The same smeared along the gun (its width shrunk ALONG times and stretched back), for the tops.
    rgb.resize((rgb.width // ALONG, rgb.height), Image.BOX).resize(rgb.size, Image.BILINEAR).save(
        out.replace(".png", "_along.png"))
    return out


def inset_of(shape):
    """How far inside a part its paint is taken: most of its half thickness (a top face samples its
    part's middle, clear of the painted edge line), within INSET and INSET_MAX."""
    t = shape["type"]
    if t == "profile":
        half = shape["half_width"]
    elif t == "turned":
        half = max(r for r, _z in shape["profile"])
    elif t == "box":
        half = min(shape["size"]) * 0.5
    else:
        half = shape["radius"]
    return min(max(half * 0.7, INSET), INSET_MAX)


def paint_material(canvas, side_png, top_png, target):
    """Emission = the side painting or the top's, chosen by the face's normal, for the bake."""
    mat = bpy.data.materials.new("paint")
    mat.use_nodes = True
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    pos = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], pos.inputs[0])
    nrm = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Normal"], nrm.inputs[0])

    def math_node(op, a, b=None):
        m = nt.nodes.new("ShaderNodeMath")
        m.operation = op
        for i, v in enumerate((a, b)):
            if v is None:
                continue
            if isinstance(v, (int, float)):
                m.inputs[i].default_value = v
            else:
                nt.links.new(v, m.inputs[i])
        return m.outputs[0]

    # Godot's z is Blender's -y, its y Blender's z, its x Blender's x. Each point taken its part's inset
    # inside the surface along its normal: a face that looks up, down or along the gun samples the
    # side painting inside its part, not the edge line it would smear (a side face is unchanged).
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_type = "OBJECT"
    attr.attribute_name = "inset"
    inset = attr.outputs["Fac"]
    gz = math_node("SUBTRACT", math_node("MULTIPLY", pos.outputs["Y"], -1.0),
                   math_node("MULTIPLY", math_node("MULTIPLY", nrm.outputs["Y"], -1.0), inset))
    gy = math_node("SUBTRACT", pos.outputs["Z"], math_node("MULTIPLY", nrm.outputs["Z"], inset))
    gx = pos.outputs["X"]
    r = canvas["rect"]           # side: z_min, y_min, w, h
    t = canvas["top_rect"]       # top: z_min, x_min, w, h
    u_side = math_node("DIVIDE", math_node("SUBTRACT", r[0] + r[2], gz), r[2])
    v_side = math_node("DIVIDE", math_node("SUBTRACT", gy, r[1]), r[3])
    u_top = math_node("DIVIDE", math_node("SUBTRACT", t[0] + t[2], gz), t[2])
    v_top = math_node("SUBTRACT", 1.0, math_node("DIVIDE", math_node("SUBTRACT", gx, t[1]), t[3]))

    def image(png, u, v):
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(png)
        tex.extension = "EXTEND"
        uv = nt.nodes.new("ShaderNodeCombineXYZ")
        nt.links.new(u, uv.inputs[0])
        nt.links.new(v, uv.inputs[1])
        nt.links.new(uv.outputs[0], tex.inputs["Vector"])
        return tex.outputs["Color"]

    # Faces looking up or down cut the painting along a line, so its grain shows as stripes across
    # the part (a top's grain should run along it): they take the painting smeared along the gun.
    sharp = image(side_png, u_side, v_side)
    smooth = image(side_png.replace(".png", "_along.png"), u_side, v_side)
    w = math_node("POWER", math_node("ABSOLUTE", nrm.outputs["Z"]), 2.0)
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    nt.links.new(w, mix.inputs["Factor"])
    nt.links.new(sharp, mix.inputs[6])
    nt.links.new(smooth, mix.inputs[7])
    side_col = mix.outputs[2]
    if top_png:
        top_col = image(top_png, u_top, v_top)
        # The top painting on faces looking up (Godot's +y: Blender's +z), the side's elsewhere.
        up = math_node("MAXIMUM", nrm.outputs["Z"], 0.0)
        w = math_node("POWER", up, 2.0)
        mix = nt.nodes.new("ShaderNodeMix")
        mix.data_type = "RGBA"
        nt.links.new(w, mix.inputs["Factor"])
        nt.links.new(side_col, mix.inputs[6])
        nt.links.new(top_col, mix.inputs[7])
        col = mix.outputs[2]
    else:
        col = side_col
    # Tops darkened: the sun lands square on them and the painting's light is in them already,
    # so from your eye down the gun the stock's top read salmon, the skin's colour (blind judge,
    # 2026-10-24).
    up = math_node("POWER", math_node("MAXIMUM", nrm.outputs["Z"], 0.0), 1.5)
    keep = math_node("SUBTRACT", 1.0, math_node("MULTIPLY", up, TOP_DARK))
    vm = nt.nodes.new("ShaderNodeVectorMath")
    vm.operation = "SCALE"
    nt.links.new(col, vm.inputs[0])
    nt.links.new(keep, vm.inputs["Scale"])
    col = vm.outputs[0]
    nt.links.new(col, emit.inputs["Color"])
    bake = nt.nodes.new("ShaderNodeTexImage")
    bake.image = target
    nt.nodes.active = bake
    return mat


def main():
    clear()
    parts = json.load(open(os.path.join(HERE, "%s_parts.json" % GUN)))["parts"]
    canvas = json.load(open(os.path.join(ROOT, "assets", "textures", "guns", "%s.json" % GUN)))
    side_png = graded(os.path.join(ROOT, "assets", "textures", "guns", "gun_%s_painted.jpg" % GUN))
    # A painting from above was tried (2026-10-23) and came back as the side again: the side's, inset.
    top_png = ""
    obs = []
    for p in parts:
        if p["kind"] == "" or p["own_paint"]:
            continue
        name = p["path"].replace("/", "__")
        ob = BUILD[p["shape"]["type"]](name, p["shape"])
        b = p["basis"]
        o = p["origin"]
        # The part's place in the gun (Godot columns x, y, z and origin), as Blender's matrix.
        g = Matrix(((b[0][0], b[1][0], b[2][0], o[0]), (b[0][1], b[1][1], b[2][1], o[1]),
                    (b[0][2], b[1][2], b[2][2], o[2]), (0, 0, 0, 1)))
        ob.matrix_world = C @ g @ C.inverted()
        ob["inset"] = inset_of(p["shape"])
        obs.append(ob)
    bpy.context.view_layer.update()
    for ob in obs:
        bpy.context.view_layer.objects.active = ob
        ob.select_set(True)
        for m in list(ob.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
        ob.select_set(False)
        # Smooth where the surface curves, hard at the bevels' edges.
        for poly in ob.data.polygons:
            poly.use_smooth = True
        ob.data.set_sharp_from_angle(angle=math.radians(40))
    # One texture for the gun: every part unwrapped together.
    for ob in obs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(55), island_margin=0.004, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(margin=0.003)
    bpy.ops.object.mode_set(mode="OBJECT")
    target = bpy.data.images.new("%s_paint" % GUN, SIZE, SIZE)
    mat = paint_material(canvas, side_png, top_png, target)
    for ob in obs:
        ob.data.materials.clear()
        ob.data.materials.append(mat)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    scene.render.bake.margin = 6
    bpy.ops.object.bake(type="EMIT")
    out_png = os.path.join(ROOT, "assets", "weapons", "%s_paint.png" % GUN)
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    target.filepath_raw = out_png
    target.file_format = "PNG"
    target.save()
    # The glb's material (the game lays <gun>_paint.png on it itself: GunParts.blender_meshes).
    nt = mat.node_tree
    for nd in list(nt.nodes):
        nt.nodes.remove(nd)
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.inputs["Roughness"].default_value = 0.6
    bsdf.inputs["Metallic"].default_value = 0.1
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = target
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(bsdf.outputs[0], out.inputs["Surface"])
    glb = os.path.join(ROOT, "assets", "weapons", "%s.glb" % GUN)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", use_selection=True, export_yup=True,
                              export_image_format="NONE", export_apply=True)
    print("WROTE", glb, len(obs), "parts")


main()
