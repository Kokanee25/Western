"""The SAA painted (#693 step 1, Sean's yes on #740): saa_blender.py's gun with its surfaces baked into
one atlas. The tiling paintings (surfaces.py: colour case-hardening, worn bluing, oiled walnut) are laid
on each part by its box UVs, then mixed with the gun's own wear and grime, free, from its shape:
- wear: where an edge is sharp (Cycles' Bevel node against the face's normal, broken by noise), the
  bluing rubbed to grey steel, the case colours silvered, the walnut's finish worn lighter;
- grime: in the hollows (Cycles' ambient occlusion within a few millimetres), dark and duller.
Baked by Cycles as emission (no light in it) into saa_albedo (sRGB) and saa_orm (glTF's
occlusion/roughness/metal), every part on one smart-projected atlas; the rounds keep their own solid
brass and lead. Out: the painted saa_<barrel>.glb (the parts, pivots and rig exactly as saa_blender.py's).

    ~/bpyenv/bin/python experiments/gun_lab/saa/saa_paint.py --pick=case_0,blued_0,walnut_0 [--size=2048]
        [--barrel=7.5] [--out=DIR] [--preview=DIR --views=right,front34 --px=1200]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "saa_blender.py")).read().replace("\nmain()\n", "\n")
exec(compile(_src, os.path.join(HERE, "saa_blender.py"), "exec"))  # build(), mats, arg, ... (no export)

import bpy  # noqa: E402  (already imported by saa_blender's code)
import numpy as np  # noqa: E402

SURF = arg("surfaces", os.path.join(HERE, "surfaces"))
SIZE = int(arg("size", "2048"))
PICK = dict(p.split("_", 1)[0:1] + [p] for p in arg("pick", "case_0,blued_0,walnut_0").split(","))
# Each placeholder material's painting, tint, and its wear and grime (wear colour, roughness, metal).
LOOK = {
    # tile: metres a painting covers (the box UVs are a tile every 40 mm). The bluing came back grey
    # from the painter: its tint takes it to blue-black, keeping the polish lines and wear in it. The
    # walnut came back light, oak-like beside the Met gun's grip: darkened to old chocolate; the case
    # colours toned down a little (round 1 in the game read bright and green).
    "saa_case":      {"tex": "case", "tint": (0.72, 0.70, 0.74), "tile": 0.05, "wear_to": "lighter", "wear": 0.45, "rough": 0.30, "metal": 1.0},
    "saa_blued":     {"tex": "blued", "tint": (0.17, 0.20, 0.29), "tile": 0.07, "wear_to": (0.36, 0.36, 0.37), "wear": 0.85, "rough": 0.32, "metal": 1.0},
    "saa_fire_blue": {"tex": "blued", "tint": (0.16, 0.30, 0.75), "tile": 0.07, "wear_to": (0.36, 0.36, 0.38), "wear": 0.6, "rough": 0.26, "metal": 1.0},
    "saa_bright":    {"tex": None, "color": (0.50, 0.50, 0.51), "wear_to": (0.62, 0.62, 0.63), "wear": 0.5, "rough": 0.36, "metal": 1.0},
    "saa_walnut":    {"tex": "walnut", "tint": (0.48, 0.40, 0.34), "tile": 0.06, "wear_to": "lighter", "wear": 0.55, "rough": 0.48, "metal": 0.0},
    "saa_bore":      {"tex": None, "color": (0.035, 0.033, 0.033), "wear_to": (0.06, 0.06, 0.06), "wear": 0.0, "rough": 0.55, "metal": 1.0},
}
KEEP = ("saa_brass", "saa_lead", "saa_primer")  # the rounds: solid, not baked


def node_tree(mat, look, img, mode):
    """Rebuild mat's nodes: the computed colour (mode "albedo") or (1, rough, metal) (mode "orm") into
    an Emission shader, and the target image as the active node (what Cycles bakes into)."""
    nt = mat.node_tree
    nt.nodes.clear()
    N, L = nt.nodes, nt.links
    out = N.new("ShaderNodeOutputMaterial")
    emit = N.new("ShaderNodeEmission")
    L.new(emit.outputs[0], out.inputs[0])
    # Wear: an edge's rounded normal (Bevel) parts from its true one; broken up by noise.
    geo = N.new("ShaderNodeNewGeometry")
    bev = N.new("ShaderNodeBevel")
    bev.inputs["Radius"].default_value = 0.0006
    bev.samples = 8
    dot = N.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    L.new(geo.outputs["Normal"], dot.inputs[0])
    L.new(bev.outputs[0], dot.inputs[1])
    edge = N.new("ShaderNodeMapRange")
    edge.inputs["From Min"].default_value = 0.999
    edge.inputs["From Max"].default_value = 0.94
    L.new(dot.outputs["Value"], edge.inputs["Value"])
    noise = N.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 900.0
    noise.inputs["Detail"].default_value = 6.0
    tc = N.new("ShaderNodeTexCoord")
    L.new(tc.outputs["Object"], noise.inputs["Vector"])
    nr = N.new("ShaderNodeMapRange")
    nr.inputs["From Min"].default_value = 0.35
    nr.inputs["From Max"].default_value = 0.65
    L.new(noise.outputs["Fac"], nr.inputs["Value"])
    wear = N.new("ShaderNodeMath")
    wear.operation = "MULTIPLY"
    wear.use_clamp = True
    L.new(edge.outputs["Result"], wear.inputs[0])
    L.new(nr.outputs["Result"], wear.inputs[1])
    wear_k = N.new("ShaderNodeMath")
    wear_k.operation = "MULTIPLY"
    wear_k.inputs[1].default_value = look["wear"]
    L.new(wear.outputs[0], wear_k.inputs[0])
    # Grime: the hollows (ambient occlusion within 4 mm).
    ao = N.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.004
    ao.samples = 16
    cav = N.new("ShaderNodeMapRange")
    cav.inputs["From Min"].default_value = 1.0
    cav.inputs["From Max"].default_value = 0.35
    L.new(ao.outputs["AO"], cav.inputs["Value"])
    # The surface: the tiling painting on the box UVs, tinted; or a solid colour.
    if look.get("tex"):
        uv = N.new("ShaderNodeUVMap")
        uv.uv_map = "UVMap"
        tex = N.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.join(SURF, PICK[look["tex"]] + ".png"), check_existing=True)
        tex.interpolation = "Cubic"
        scale = N.new("ShaderNodeVectorMath")
        scale.operation = "SCALE"
        scale.inputs["Scale"].default_value = 0.04 / look["tile"]
        L.new(uv.outputs["UV"], scale.inputs[0])
        L.new(scale.outputs[0], tex.inputs["Vector"])
        tint = N.new("ShaderNodeMix")
        tint.data_type = "RGBA"
        tint.blend_type = "MULTIPLY"
        tint.inputs["Factor"].default_value = 1.0
        L.new(tex.outputs["Color"], tint.inputs["A"])
        tint.inputs["B"].default_value = (*look["tint"], 1.0)
        base = tint.outputs["Result"]
    else:
        rgb = N.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = (*look["color"], 1.0)
        base = rgb.outputs[0]
    if mode == "albedo":
        worn = N.new("ShaderNodeMix")
        worn.data_type = "RGBA"
        L.new(wear_k.outputs[0], worn.inputs["Factor"])
        L.new(base, worn.inputs["A"])
        if look["wear_to"] == "lighter":
            light = N.new("ShaderNodeMix")
            light.data_type = "RGBA"
            light.blend_type = "SCREEN"
            light.inputs["Factor"].default_value = 0.45
            L.new(base, light.inputs["A"])
            light.inputs["B"].default_value = (0.55, 0.50, 0.45, 1.0)
            L.new(light.outputs["Result"], worn.inputs["B"])
        else:
            worn.inputs["B"].default_value = (*look["wear_to"], 1.0)
        grime = N.new("ShaderNodeMix")
        grime.data_type = "RGBA"
        gk = N.new("ShaderNodeMath")
        gk.operation = "MULTIPLY"
        gk.inputs[1].default_value = 0.65
        L.new(cav.outputs["Result"], gk.inputs[0])
        L.new(gk.outputs[0], grime.inputs["Factor"])
        L.new(worn.outputs["Result"], grime.inputs["A"])
        grime.inputs["B"].default_value = (0.035, 0.030, 0.025, 1.0)
        L.new(grime.outputs["Result"], emit.inputs["Color"])
    else:
        # roughness: a touch smoother where rubbed, much rougher in the grime.
        r1 = N.new("ShaderNodeMath")
        r1.operation = "MULTIPLY_ADD"
        L.new(wear_k.outputs[0], r1.inputs[0])
        r1.inputs[1].default_value = -0.10
        r1.inputs[2].default_value = look["rough"]
        r2 = N.new("ShaderNodeMath")
        r2.operation = "MULTIPLY_ADD"
        r2.use_clamp = True
        L.new(cav.outputs["Result"], r2.inputs[0])
        r2.inputs[1].default_value = 0.35
        L.new(r1.outputs[0], r2.inputs[2])
        comb = N.new("ShaderNodeCombineColor")
        comb.inputs["Red"].default_value = 1.0
        L.new(r2.outputs[0], comb.inputs["Green"])
        comb.inputs["Blue"].default_value = look["metal"]
        L.new(comb.outputs[0], emit.inputs["Color"])
    target = N.new("ShaderNodeTexImage")
    target.image = img
    uvb = N.new("ShaderNodeUVMap")
    uvb.uv_map = "bake"
    L.new(uvb.outputs["UV"], target.inputs["Vector"])
    N.active = target
    target.select = True


def unwrap(objs):
    """One atlas for every baked part: a second UV layer, smart-projected and packed together."""
    for ob in objs:
        lay = ob.data.uv_layers.new(name="bake")
        ob.data.uv_layers.active = lay
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.hide_set(False)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, area_weight=0.0, correct_aspect=True)
    bpy.ops.uv.pack_islands(margin=0.004, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def bake(objs, img, mode):
    for ob in objs:
        for slot in ob.material_slots:
            m = slot.material
            if m and m.name.split(".")[0] in LOOK:
                node_tree(m, LOOK[m.name.split(".")[0]], img, mode)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.bake(type="EMIT", margin=6, use_clear=True)


def main_paint():
    parts, rounds, markers, hinge, ej = build()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(arg("samples", "24"))
    # The world space the rig, the markers and the export see is build()'s; bake in place.
    objs = [o for o in parts.values() if o.type == "MESH"]
    unwrap(objs)
    albedo = bpy.data.images.new("saa_albedo", SIZE, SIZE)
    orm = bpy.data.images.new("saa_orm", SIZE, SIZE)
    orm.colorspace_settings.name = "Non-Color"
    for m in bpy.data.materials:
        m.use_nodes = True
    bake(objs, albedo, "albedo")
    bake(objs, orm, "orm")
    # The game's material: the two baked maps on the bake UVs, the box UVs dropped (glTF's TEXCOORD_0).
    mat = bpy.data.materials.new("saa_painted")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    t_alb = nt.nodes.new("ShaderNodeTexImage")
    t_alb.image = albedo
    t_orm = nt.nodes.new("ShaderNodeTexImage")
    t_orm.image = orm
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(t_alb.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(t_orm.outputs["Color"], sep.inputs[0])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    for ob in objs:
        for i, slot in enumerate(ob.material_slots):
            if slot.material and slot.material.name.split(".")[0] in LOOK:
                slot.material = mat
        ob.data.uv_layers.remove(ob.data.uv_layers["UVMap"])
    # The atlases kept beside the glb (to look at; the glb carries its own copies).
    out_dir = arg("out", HERE)
    for img in (albedo, orm):
        os.makedirs(os.path.join(out_dir, "surfaces"), exist_ok=True)
        img.filepath_raw = os.path.join(out_dir, "surfaces", img.name + ".png")
        img.file_format = "PNG"
        img.save()
    return parts, rounds, markers, hinge, ej


def export(parts, rounds, markers, hinge, ej):
    keep = set()

    def walk(o):
        keep.add(o.name)
        for c in o.children:
            walk(c)
    walk(bpy.data.objects["ColtSAA"])
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    tag = ("%g" % BARREL).replace(".", "")
    out = arg("out", HERE)
    glb = os.path.join(out, "saa_%s.glb" % tag)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True, export_yup=True,
                              export_image_format="JPEG", export_jpeg_quality=92,
                              export_cameras=False, export_lights=False)
    rig_json(parts, markers, hinge, ej, os.path.join(out, "saa_%s_rig.json" % tag))
    print("SAA painted -> %s (%.1f MB)" % (glb, os.path.getsize(glb) / 1e6))


r = main_paint()
export(*r)
if PREVIEW:
    # The look check: the painted parts in a plain light (the real test is the game's real look).
    preview(PREVIEW)
