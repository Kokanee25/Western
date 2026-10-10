"""The normal-map convention check, Blender's half (docs/briefs/faces.md, step 1).

    ~/bpyenv/bin/python tools/blender/normal_check.py [--out=build/normal_check]

A hemisphere bump modelled on a dense plane, and its normals baked onto a flat quad with
Blender's default bake settings (tangent space, +X +Y +Z: OpenGL's +Y), then both exported to glTF
(the quad with tangents and its normal map). tools/normal_check.gd lights the two the same way in
Godot and checks the flat quad's bump lights on the same side as the modelled one. If Blender,
glTF and Godot disagree about the green channel or the tangents, the baked bump lights from the
wrong side.

Writes <out>/bump_high.glb (the modelled bump), <out>/bump.glb (the flat quad, normal-mapped),
<out>/bump_normal.png.
"""
import math
import os
import sys

import bpy

OUT = "build/normal_check"
SIZE = 256          # the normal map's texels a side
BUMP_R = 0.3        # metres, on a 1 m quad
BUMP_H = 0.15


def bump_z(x, y):
    d = math.hypot(x, y)
    if d >= BUMP_R:
        return 0.0
    # A smooth dome (a squashed hemisphere), so the bake has no hard crease at its foot.
    return BUMP_H * (1.0 - (d / BUMP_R) ** 2) ** 1.5


def plane(name, cuts):
    bpy.ops.mesh.primitive_grid_add(x_subdivisions=cuts, y_subdivisions=cuts, size=1.0)
    ob = bpy.context.active_object
    ob.name = name
    for v in ob.data.vertices:
        v.co.z = bump_z(v.co.x, v.co.y)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def export(ob, path):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
                              export_tangents=True, export_normals=True, export_texcoords=True,
                              export_materials="EXPORT", export_image_format="AUTO")


def main():
    out = OUT
    for a in sys.argv[1:]:
        if a.startswith("--out="):
            out = a.split("=", 1)[1]
    os.makedirs(out, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 4

    high = plane("bump_high", 200)
    low = plane("bump", 1)
    for v in low.data.vertices:
        v.co.z = 0.0

    img = bpy.data.images.new("bump_normal", SIZE, SIZE, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    mat = bpy.data.materials.new("bump")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.6, 0.6, 0.6, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tex.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    nt.nodes.active = tex
    low.data.materials.append(mat)
    grey = bpy.data.materials.new("bump_high")
    grey.use_nodes = True
    grey.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.6, 0.6, 0.6, 1.0)
    grey.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    high.data.materials.append(grey)

    # Blender's defaults: tangent space, swizzle +X +Y +Z, high to low.
    bpy.ops.object.select_all(action="DESELECT")
    high.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bake = scene.render.bake
    bake.use_selected_to_active = True
    bake.cage_extrusion = BUMP_H + 0.02
    bpy.ops.object.bake(type="NORMAL")
    path = os.path.join(out, "bump_normal.png")
    img.filepath_raw = os.path.abspath(path)
    img.file_format = "PNG"
    img.save()
    print("normal space %s, swizzle %s %s %s" % (bake.normal_space, bake.normal_r, bake.normal_g, bake.normal_b))

    export(low, os.path.abspath(os.path.join(out, "bump.glb")))
    export(high, os.path.abspath(os.path.join(out, "bump_high.glb")))
    print("wrote", out)


if __name__ == "__main__":
    main()
