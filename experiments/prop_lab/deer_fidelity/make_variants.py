"""The deer head's fidelity lab (issue #524): every version of the Rodin deer the A/B/C/D test
draws, made from the one master Rodin made (the Character Studio's paid/526815a52c02..., its ledger
row prop:deer_head, $1.60 on 2026-10-24; never changed: read only).

    ~/.venvs/studio/bin/python experiments/prop_lab/deer_fidelity/make_variants.py MASTER.glb [OUT]

OUT (default build/deer_fidelity/variants, git-ignored, made again by this script) gets:
- geometry, no materials (the stand gives each its material): g_master.glb (Rodin's 33,578
  triangles, only placed: turned and scaled into the kit's space as deer_head_rodin.py places it,
  Rodin's floor rod dropped), g30k.glb, g15k.glb, g6k.glb (cut by Blender's collapse, as
  rodin_prop.decimate cuts the game's: g6k is the game's deer before its split into parts);
- Rodin's own maps at 4096, 2048, 1024: alb_*.png (colour), nrm_*.png (normal, OpenGL: Blender's),
  rgh_*.png (roughness: the green of Rodin's metal/roughness map; its metal is ~0 everywhere);
- bake_nrm_g6k_2048.png, bake_nrm_g15k_2048.png: the master's surface (its shape and normal map)
  baked into the cut meshes' tangent space (Cycles, selected to active);
- split_rgh_2048.png, split_mask_2048.png: roughness by what the surface is (fur, antler, glass eye,
  wet nose, varnished plaque), each texel classed by where it lies on the model and its colour
  (the mask: classes as grey levels, CLASSES' order);
- variants.json: triangles, sizes, the master's sha256.
"""
import hashlib
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "blender", "props"))
import rodin_prop as R  # noqa: E402

PLAQUE_H = 0.47       # as deer_head_rodin.py
PLAQUE_FRONT = 0.06
NECK_TOP = -0.10
MUZZLE_OUT = 0.30
MUZZLE_TOP = 0.04
SKULL_TOP = 0.06
CUTS = {"g30k": 30000, "g15k": 15000, "g6k": 6000}
SIZES = (4096, 2048, 1024)
# The classes' roughness (fur matte, antler satin, a glass eye and a wet nose glossy, a varnished
# plaque), in the mask's order.
CLASSES = [("fur", 0.85), ("antler", 0.55), ("eye", 0.06), ("nose", 0.25), ("plaque", 0.38)]


def _export(obj, path):
    import bpy
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_materials="NONE",
                              export_yup=True, export_apply=True, export_animations=False, export_normals=True,
                              export_tangents=True)


def _tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def _save_maps(out):
    """Rodin's three maps at every size, as PNG."""
    import bpy
    from PIL import Image
    names = {"alb": "texture_diffuse", "nrm": "texture_normal", "rgh": "texture_metallic-texture_roughness"}
    for key, name in names.items():
        im = bpy.data.images[name]
        tmp = os.path.join(out, "_%s.png" % key)
        im.filepath_raw = tmp
        im.file_format = "PNG"
        im.save()
        src = Image.open(tmp).convert("RGB")
        if key == "rgh":
            g = src.split()[1]
            src = Image.merge("RGB", (g, g, g))
        for px in SIZES:
            dst = src if px == src.size[0] else src.resize((px, px), Image.LANCZOS)
            if key == "nrm" and px != src.size[0]:
                a = np.asarray(dst).astype(np.float32) / 127.5 - 1.0
                a /= np.maximum(np.linalg.norm(a, axis=2, keepdims=True), 1e-6)
                dst = Image.fromarray(np.clip((a + 1.0) * 127.5, 0, 255).astype(np.uint8))
            dst.save(os.path.join(out, "%s_%d.png" % (key, px)), optimize=True)
        os.remove(tmp)


def _bake_normals(high, low, path, px=2048):
    """The master's shading normal (its shape and its normal map) into `low`'s tangent space."""
    import bpy
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 1
    img = bpy.data.images.new("bake_" + low.name, px, px, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    mat = bpy.data.materials.new("bake_" + low.name)
    tree = mat.node_tree
    node = tree.nodes.new("ShaderNodeTexImage")
    node.image = img
    tree.nodes.active = node
    low.data.materials.clear()
    low.data.materials.append(mat)
    bpy.ops.object.select_all(action="DESELECT")
    high.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.bake(type="NORMAL", use_selected_to_active=True, cage_extrusion=0.004, max_ray_distance=0.02,
                        normal_space="TANGENT", margin=8, margin_type="EXTEND")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    low.data.materials.clear()
    print("baked", path)


def _texel_positions(obj, px):
    """Each texel's place on the model (game space) and whether a triangle covers it: the UVs
    rasterised, positions interpolated across each triangle."""
    g = R.game_verts(obj)
    uv_layer = obj.data.uv_layers.active.data
    pos = np.zeros((px, px, 3), np.float32)
    hit = np.zeros((px, px), bool)
    for poly in obj.data.polygons:
        li = list(poly.loop_indices)
        vi = list(poly.vertices)
        for k in range(1, len(li) - 1):
            tri = [0, k, k + 1]
            uv = np.array([uv_layer[li[t]].uv[:] for t in tri]) * px
            uv[:, 1] = px - uv[:, 1]  # image rows top down
            p = g[[vi[t] for t in tri]]
            x0, y0 = np.floor(uv.min(0)).astype(int)
            x1, y1 = np.ceil(uv.max(0)).astype(int)
            x0, y0 = max(x0, 0), max(y0, 0)
            x1, y1 = min(x1, px - 1), min(y1, px - 1)
            if x1 < x0 or y1 < y0:
                continue
            xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            (ax, ay), (bx, by), (cx, cy) = uv
            den = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy)
            if abs(den) < 1e-12:
                continue
            w0 = ((by - cy) * (xs - cx) + (cx - bx) * (ys - cy)) / den
            w1 = ((cy - ay) * (xs - cx) + (ax - cx) * (ys - cy)) / den
            w2 = 1 - w0 - w1
            inside = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
            if not inside.any():
                continue
            P = w0[..., None] * p[0] + w1[..., None] * p[1] + w2[..., None] * p[2]
            sub = (slice(y0, y1 + 1), slice(x0, x1 + 1))
            pos[sub][inside] = P[inside]
            hit[sub][inside] = True
    return pos, hit


def _split(obj, out, px=2048):
    """Roughness by class: each texel by where it lies and its colour."""
    from PIL import Image
    pos, hit = _texel_positions(obj, px)
    alb = np.asarray(Image.open(os.path.join(out, "alb_%d.png" % px)).convert("RGB")).astype(np.float32) / 255.0
    lum = alb @ np.array([0.2126, 0.7152, 0.0722], np.float32)
    mx, mn = alb.max(2), alb.min(2)
    sat = (mx - mn) / np.maximum(mx, 1e-4)
    x, y, z = pos[..., 0], pos[..., 1], pos[..., 2]
    cls = np.zeros((px, px), np.uint8)  # fur
    # The rack: above the skull, out past the ears' reach or high over the head, pale and grey.
    # (not the ears' white insides: brighter, and low by the skull)
    antler = (y > SKULL_TOP + 0.015) & (sat < 0.45) & ((np.abs(x) > 0.11) | (y > SKULL_TOP + 0.08))
    antler &= ~((lum > 0.75) & (y < SKULL_TOP + 0.1))
    cls[antler] = 1
    # The nose's leather and the glass eyes: the paint's darks where each lies (measured on the
    # placed master: the eyes at x +-0.05, y 0.04-0.09, z 0.19-0.27; the nose at z 0.37).
    nose = (z > 0.33) & (y < 0.02) & (lum < 0.12)
    cls[nose] = 3
    eye = (np.abs(x) > 0.02) & (np.abs(x) < 0.12) & (y > 0.02) & (y < 0.11) & (z > 0.15) & (z < 0.30) & (lum < 0.10)
    cls[eye] = 2
    cls[z < PLAQUE_FRONT] = 4
    cls[~hit] = 0
    rough = np.array([r for _, r in CLASSES], np.float32)[cls]
    Image.fromarray((rough * 255).astype(np.uint8)).convert("RGB").save(os.path.join(out, "split_rgh_%d.png" % px))
    Image.fromarray((cls * 60).astype(np.uint8)).save(os.path.join(out, "split_mask_%d.png" % px))
    counts = {name: int((cls[hit] == i).sum()) for i, (name, _) in enumerate(CLASSES)}
    print("split texels", counts)
    return counts


def main():
    import bpy
    master = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "build", "deer_fidelity", "variants")
    os.makedirs(out, exist_ok=True)
    sha = hashlib.sha256(open(master, "rb").read()).hexdigest()
    obj = R.load(master)
    _save_maps(out)
    R.place(obj, back_height=PLAQUE_H)
    obj.name = "master"
    info = {"master": master, "master_sha256": sha, "meshes": {}}
    lows = {}
    for name, n in CUTS.items():
        o = obj.copy()
        o.data = obj.data.copy()
        o.name = name
        bpy.context.scene.collection.objects.link(o)
        R.decimate(o, n)
        lows[name] = o
    for name, o in [("g_master", obj)] + list(lows.items()):
        _export(o, os.path.join(out, name + ".glb"))
        info["meshes"][name] = {"triangles": _tris(o), "vertices": len(o.data.vertices)}
    for name in ("g6k", "g15k"):
        _bake_normals(obj, lows[name], os.path.join(out, "bake_nrm_%s_2048.png" % name))
    info["split_texels"] = _split(obj, out)
    info["classes"] = CLASSES
    with open(os.path.join(out, "variants.json"), "w") as f:
        json.dump(info, f, indent=2)
    print(json.dumps(info["meshes"]))


if __name__ == "__main__":
    main()
