"""His clothes out of his dressed twin (docs/briefs/layered-people.md): the coat as a garment piece
the fitter hangs on his base body (tools/blender/fit_tripo.py `pieces`).

    ~/bpyenv/bin/python tools/characters/twin_pieces.py --dressed=bold_cowboy_dressed --out=bold_cowboy

- His dressed twin: Rodin's whole man from the four dressed pictures
  (assets/people/tripo/test/<dressed>_rodin.glb), painted from them by body_paint.py
  (assets/people/tripo/<dressed>_color.png; else Rodin's own colours).
- Turned into Tripo's frame (facing +X, 1.0 tall, feet on 0) as fit_tripo.load_rodin turns a
  Rodin man, and cut to the coat: from his collar (COLLAR of his height) to its hem (HEM), his
  head and his legs below the hem gone. What his coat shows at the front (vest, shirt, tie) stays
  on it: fit_tripo makes the coat a shell of the body and takes only its look from this piece.
→ assets/people/tripo/<out>_coat.glb (a Tripo-style item: unrigged, its texture inside).
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TRIPO = os.path.join(ROOT, "assets", "people", "tripo")
COLLAR = 0.845     # of his height: the coat's collar top (his neck)
HEM = 0.30         # of his height: the coat's hem, at his knees


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    dressed, out = a["--dressed"], a["--out"]
    sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
    import fit_tripo as FT
    import bpy
    from PIL import Image
    pos, _n, uv, tris, _j, colour = FT.load_glb(os.path.join(TRIPO, "test", dressed + "_rodin.glb"))
    painted = os.path.join(TRIPO, dressed + "_color.png")
    if os.path.exists(painted):
        colour = Image.open(painted).convert("RGB")
    v = np.stack([pos[:, 2], pos[:, 1], -pos[:, 0]], axis=1)          # as load_rodin turns him
    y0, y1 = v[:, 1].min(), v[:, 1].max()
    v = (v - [0, y0, 0]) / (y1 - y0)
    v -= [(v[:, 0].min() + v[:, 0].max()) / 2, 0, (v[:, 2].min() + v[:, 2].max()) / 2]
    cy = v[tris].mean(1)[:, 1]
    keep = (cy < COLLAR) & (cy > HEM)
    t = tris[keep]
    used = np.unique(t)
    remap = -np.ones(len(v), int)
    remap[used] = np.arange(len(used))
    vk, tk, uvk = v[used], remap[t], uv[used]
    print("twin_pieces: coat %d of %d triangles (collar %.2f, hem %.2f of his height)" % (len(tk), len(tris), COLLAR, HEM))
    # Into Blender (its Z up; glTF's export turns (x, y, z) back to (x, z, -y)), textured, out.
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new("coat")
    me.from_pydata([(p[0], -p[2], p[1]) for p in vk], [], [tuple(int(i) for i in f) for f in tk])
    uvl = me.uv_layers.new(name="UVMap")
    corner = uvk[tk.ravel()]
    uvl.data.foreach_set("uv", np.c_[corner[:, 0], 1.0 - corner[:, 1]].astype(np.float32).ravel())
    ob = bpy.data.objects.new("coat", me)
    bpy.context.scene.collection.objects.link(ob)
    tex_path = os.path.join(ROOT, "build", out + "_coat_tex.png")
    os.makedirs(os.path.dirname(tex_path), exist_ok=True)
    colour.save(tex_path)
    mat = bpy.data.materials.new("coat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = bpy.data.images.load(tex_path)
    mat.node_tree.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    me.materials.append(mat)
    path = os.path.join(TRIPO, out + "_coat.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_texcoords=True, export_normals=True,
                              export_materials="EXPORT", export_image_format="AUTO")
    print("twin_pieces: wrote", path)


if __name__ == "__main__":
    main()
