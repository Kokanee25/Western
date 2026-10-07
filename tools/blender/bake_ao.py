"""Ambient occlusion of a man's model baked into his UV atlas: what his own shape shades, for his
face's modelling in tools/characters/head_paint.py (characters.json `bake.face`: `ao_near`,
`ao_far`). The painter's face and Rodin's are lit flat, so his eye sockets, the sides of his nose
and the line under his jaw came out no darker than his cheek.

    ~/bpyenv/bin/python tools/blender/bake_ao.py assets/people/tripo/stranger2_rodin.glb [--size=2048] [--samples=128]

Writes <glb's name>_ao.png beside it, the size of a texture on his atlas: red the near occlusion
(NEAR_M on him: an eyelid's crease, a nostril, the line of his lips, under his moustache), green
the far (FAR_M: his eye sockets, under his nose, his jaw over his neck, under his hat's brim),
each 255 in the open; its rows as his colour texture's. The glb is read here (its one mesh, as
head_paint.py's load_glb reads it), not through Blender's importer, so the UVs are the file's own.
"""
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

NEAR_M = 0.015
FAR_M = 0.06
HEIGHT_M = 1.8      # head_paint.py's: a man is drawn 1.8 m tall, whatever the glb's own units


def read_glb(path):
    """The first mesh's positions, UVs and triangles."""
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    blen = struct.unpack("<I", f[20 + clen:24 + clen])[0]
    binary = f[28 + clen:28 + clen + blen]

    def accessor(i):
        a = doc["accessors"][i]
        bv = doc["bufferViews"][a["bufferView"]]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        stride = bv.get("byteStride", 0)
        if stride and stride != n * np.dtype(dtype).itemsize:
            rows = np.frombuffer(binary, dtype=np.uint8, count=stride * a["count"], offset=start).reshape(a["count"], stride)
            return rows[:, :n * np.dtype(dtype).itemsize].copy().view(dtype).reshape(a["count"], n)
        return np.frombuffer(binary, dtype=dtype, count=a["count"] * n, offset=start).reshape(a["count"], n)

    prim = doc["meshes"][0]["primitives"][0]
    pos = accessor(prim["attributes"]["POSITION"]).astype(np.float64)
    uv = accessor(prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    tris = accessor(prim["indices"]).reshape(-1, 3).astype(np.int64)
    return pos, uv, tris


def bake(path, size, samples):
    import bpy
    pos, uv, tris = read_glb(path)
    tall = pos[:, 1].max() - pos[:, 1].min()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mesh = bpy.data.meshes.new("man")
    mesh.from_pydata(pos.tolist(), [], tris.tolist())
    layer = mesh.uv_layers.new(name="UVMap")
    # Blender's v runs up from the image's bottom; the glb's down from its top.
    corners = uv[tris.reshape(-1)]
    layer.data.foreach_set("uv", np.stack([corners[:, 0], 1.0 - corners[:, 1]], axis=1).reshape(-1))
    mesh.update()
    obj = bpy.data.objects.new("man", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for poly in mesh.polygons:
        poly.use_smooth = True
    scene = bpy.context.scene
    scene.world = bpy.data.worlds.new("World")
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.render.bake.margin = 4
    out = []
    for metres in (NEAR_M, FAR_M):
        # The glb's own units: the distance on him as head_paint.py measures him (1.8 m tall).
        scene.world.light_settings.distance = metres / HEIGHT_M * tall
        img = bpy.data.images.new("ao", size, size, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        mat = bpy.data.materials.new("bake")
        mat.use_nodes = True
        node = mat.node_tree.nodes.new("ShaderNodeTexImage")
        node.image = img
        mat.node_tree.nodes.active = node
        obj.data.materials.clear()
        obj.data.materials.append(mat)
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.bake(type="AO")
        a = np.array(img.pixels[:]).reshape(size, size, 4)[::-1, :, 0]   # rows top-down, as the texture's
        out.append(a)
        print("  AO at %.3f m: %.0f%% of the atlas baked, median %.2f" % (
            metres, 100.0 * (a > 0).mean(), float(np.median(a[a > 0]))))
    rgb = np.zeros((size, size, 3), dtype=np.uint8)
    rgb[..., 0] = np.clip(out[0] * 255.0 + 0.5, 0, 255)
    rgb[..., 1] = np.clip(out[1] * 255.0 + 0.5, 0, 255)
    dest = os.path.splitext(path)[0] + "_ao.png"
    Image.fromarray(rgb).save(dest)
    print("wrote", dest)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if "--" in sys.argv:
        args = [a for a in sys.argv[sys.argv.index("--") + 1:] if not a.startswith("--")]
    if not args:
        print(__doc__)
        sys.exit(1)
    size, samples = 2048, 128
    for a in sys.argv[1:]:
        if a.startswith("--size="):
            size = int(a.split("=", 1)[1])
        elif a.startswith("--samples="):
            samples = int(a.split("=", 1)[1])
    bake(args[0], size, samples)


if __name__ == "__main__":
    main()
