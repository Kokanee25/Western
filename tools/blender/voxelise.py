"""The voxel trial, step 2 (docs/screenshots/voxel_trial/): the saloon shot's props and the seated
man's hat cut into cubes with Blender's Remesh in Blocks mode, so their outlines go stair-stepped
like the concept painting's (a hat brim, a mug's rim, a bottle's shoulder).

    ~/bpyenv/bin/python tools/blender/voxelise.py [--cubes=128,64] [--only=cup,lamp,bottle,ashtray,hat]

Props: build/voxel/<prop>_<part>.obj (tools/voxel_export.gd) -> assets/props/voxel/<prop>_<cubes>.glb,
one object a part, named as the part (the game puts the part's own material back on, mapped by
position, so each cube face shows the texel under it and is lit like everything else).
The hat: the seated man's (assets/people/<HAT_OF>.glb, body_head above the brim, HAT_FROM) with
its texture (<HAT_OF>_head.png): each cube face takes the colour of the nearest point of the
original hat, written as one texel of its own atlas -> assets/people/voxel/<HAT_OF>_hat_<cubes>.glb
+ .png (UVs into the atlas; the game lays it on by UV like his other textures).
The cubes are a shell over the surface: every cube of a grid (1 / cubes metres, aligned to the
part's own space) whose centre lies within half a cube of the part's surface is filled, and the
faces between filled and empty cubes are written out (Blender's Remesh in Blocks mode was tried
first: it fills volumes, so a hat's brim or a mug's wall, thinner than a cube, fell out of it).
"""
import json
import math
import os
import struct
import sys

import bpy
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "build", "voxel")
PROPS_OUT = os.path.join(ROOT, "assets", "props", "voxel")
PEOPLE_OUT = os.path.join(ROOT, "assets", "people", "voxel")
HAT_OF = "stranger"
# The hat: the head mesh above the brim's underside (metres, our body space).
HAT_FROM = 1.778
ATLAS = 256


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_obj(path, name):
    verts, faces = [], []
    for line in open(path):
        if line.startswith("v "):
            verts.append([float(x) for x in line.split()[1:4]])
        elif line.startswith("f "):
            faces.append([int(p.split("/")[0]) - 1 for p in line.split()[1:]])
    return make_object(name, verts, faces)


def make_object(name, verts, faces, uvs=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([to_blender(v) for v in verts], [], faces)
    mesh.update()
    if uvs is not None:
        layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                u, v = uvs[mesh.loops[li].vertex_index]
                layer.data[li].uv = (u, 1.0 - v)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def to_blender(p):
    """Our body space (Y up, facing -Z) -> Blender (Z up); the glTF export turns it back."""
    return (p[0], -p[2], p[1])


def fill_holes(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    edges = [e for e in bm.edges if e.is_boundary]
    if edges:
        bmesh.ops.holes_fill(bm, edges=edges, sides=0)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()


def shell(original, cubes, name):
    """Cubes along `original`'s surface (see the top): a new object of their outer faces, plus,
    per face, the nearest point of the original's surface, the face it's on (for its colour) and
    the surface's normal there (the face's own)."""
    cube = 1.0 / cubes
    bvh = BVHTree.FromObject(original, bpy.context.evaluated_depsgraph_get())
    co = np.array([v.co[:] for v in original.data.vertices])
    lo = co.min(axis=0) - cube * 1.5
    n = np.ceil((co.max(axis=0) + cube * 1.5 - lo) / cube).astype(int)
    filled = np.zeros(n, dtype=bool)
    nearest = {}
    for i in range(n[0]):
        for j in range(n[1]):
            for k in range(n[2]):
                centre = Vector((lo[0] + (i + 0.5) * cube, lo[1] + (j + 0.5) * cube, lo[2] + (k + 0.5) * cube))
                loc, normal, fi, dist = bvh.find_nearest(centre, cube * 0.87)
                if loc is not None and dist <= cube * 0.5:
                    filled[i, j, k] = True
                    nearest[(i, j, k)] = (loc, fi, normal)
    verts, index = [], {}

    def vert(i, j, k):
        key = (i, j, k)
        if key not in index:
            index[key] = len(verts)
            verts.append((lo[0] + i * cube, lo[1] + j * cube, lo[2] + k * cube))
        return index[key]

    def empty(i, j, k):
        return not (0 <= i < n[0] and 0 <= j < n[1] and 0 <= k < n[2]) or not filled[i, j, k]

    faces, hits = [], []
    for (i, j, k), hit in nearest.items():
        # Outward faces, wound anticlockwise seen from outside (right-hand rule).
        if empty(i + 1, j, k):
            faces.append([vert(i + 1, j, k), vert(i + 1, j + 1, k), vert(i + 1, j + 1, k + 1), vert(i + 1, j, k + 1)]); hits.append(hit)
        if empty(i - 1, j, k):
            faces.append([vert(i, j, k), vert(i, j, k + 1), vert(i, j + 1, k + 1), vert(i, j + 1, k)]); hits.append(hit)
        if empty(i, j + 1, k):
            faces.append([vert(i, j + 1, k), vert(i, j + 1, k + 1), vert(i + 1, j + 1, k + 1), vert(i + 1, j + 1, k)]); hits.append(hit)
        if empty(i, j - 1, k):
            faces.append([vert(i, j, k), vert(i + 1, j, k), vert(i + 1, j, k + 1), vert(i, j, k + 1)]); hits.append(hit)
        if empty(i, j, k + 1):
            faces.append([vert(i, j, k + 1), vert(i + 1, j, k + 1), vert(i + 1, j + 1, k + 1), vert(i, j + 1, k + 1)]); hits.append(hit)
        if empty(i, j, k - 1):
            faces.append([vert(i, j, k), vert(i, j + 1, k), vert(i + 1, j + 1, k), vert(i + 1, j, k)]); hits.append(hit)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    # Each face keeps the smooth surface's normal at its nearest point, so the cubes are lit as the
    # smooth thing was and only the outline is stepped (with their own normals every face is
    # either square to the lamp or not: a foot under a lamp went black down its sides).
    mesh.normals_split_custom_set([hits[poly.index][2] for poly in mesh.polygons for _ in poly.loop_indices])
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj, hits, cube


def export(objs, path):
    for o in bpy.context.scene.objects:
        o.select_set(o in objs)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_normals=True, export_texcoords=True, export_materials="NONE",
                              export_animations=False, export_skins=False)


def do_props(cubes, only):
    manifest = json.load(open(os.path.join(SRC, "manifest.json")))
    for prop, parts in manifest.items():
        if only and prop not in only:
            continue
        reset()
        objs = []
        report = {}
        for part, info in parts.items():
            src = import_obj(os.path.join(ROOT, info["obj"]), part + "_src")
            if len(src.data.polygons) == 0:
                continue  # a flat disc (the mug's bottom, the bottle's base): hidden inside anyway
            obj, _hits, cube = shell(src, cubes, part)
            report[part] = {"faces": len(obj.data.polygons), "was": len(src.data.polygons), "cube_mm": round(cube * 1000, 2)}
            objs.append(obj)
        path = os.path.join(PROPS_OUT, "%s_%d.glb" % (prop, cubes))
        export(objs, path)
        print("wrote", os.path.relpath(path, ROOT), json.dumps(report))


# --- the hat ---------------------------------------------------------------------------------

def load_glb(path):
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    blen = struct.unpack("<I", f[20 + clen:24 + clen])[0]
    binary = f[28 + clen:28 + clen + blen]

    def accessor(i):
        a = doc["accessors"][i]
        bv = doc["bufferViews"][a["bufferView"]]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        return np.frombuffer(binary, dtype=dtype, count=a["count"] * n, offset=start).reshape(a["count"], n).astype(np.float64)

    out = {}
    for m in doc["meshes"]:
        p = m["primitives"][0]
        out[m["name"]] = (accessor(p["attributes"]["POSITION"]), accessor(p["attributes"]["TEXCOORD_0"]),
                          accessor(p["indices"]).reshape(-1, 3).astype(np.int64))
    return out


def do_hat(cubes):
    from PIL import Image
    pos, uv, tris = load_glb(os.path.join(ROOT, "assets", "people", HAT_OF + ".glb"))["body_head"]
    keep = (pos[tris, 1] > HAT_FROM).all(axis=1)
    htris = tris[keep]
    used = np.unique(htris)
    index = {int(o): i for i, o in enumerate(used)}
    faces = [[index[int(i)] for i in t] for t in htris]
    reset()
    original = make_object("hat_original", pos[used].tolist(), faces, uv[used].tolist())
    before = len(original.data.polygons)
    hat, hits, cube = shell(original, cubes, "hat")
    # Each cube face's colour: the original hat's texture at the nearest point of its surface.
    tex = np.asarray(Image.open(os.path.join(ROOT, "assets", "people", HAT_OF + "_head.png")).convert("RGB"))
    th, tw = tex.shape[:2]
    mesh = hat.data
    layer = mesh.uv_layers.new(name="UVMap")
    atlas = np.zeros((ATLAS, ATLAS, 3), dtype=np.uint8)
    polys = mesh.polygons
    if len(polys) > ATLAS * ATLAS:
        raise SystemExit("hat has %d faces, more than the atlas holds" % len(polys))
    ouv = original.data.uv_layers.active.data
    for k, poly in enumerate(polys):
        loc, fi, _normal = hits[k]
        colour = (120, 90, 60)
        if fi is not None:
            op = original.data.polygons[fi]
            # Barycentric UV at the nearest point on that (triangular) face.
            vs = [original.data.vertices[i].co for i in op.vertices]
            us = [ouv[li].uv for li in op.loop_indices]
            w = bary(loc, vs)
            u = sum(w[i] * us[i][0] for i in range(3))
            v = 1.0 - sum(w[i] * us[i][1] for i in range(3))
            colour = tex[min(th - 1, max(0, int(v * th))), min(tw - 1, max(0, int(u * tw)))]
        ax, ay = k % ATLAS, k // ATLAS
        atlas[ay, ax] = colour
        cu, cv = (ax + 0.5) / ATLAS, 1.0 - (ay + 0.5) / ATLAS
        for li in poly.loop_indices:
            layer.data[li].uv = (cu, cv)
    os.makedirs(PEOPLE_OUT, exist_ok=True)
    Image.fromarray(atlas).save(os.path.join(PEOPLE_OUT, "%s_hat_%d.png" % (HAT_OF, cubes)))
    path = os.path.join(PEOPLE_OUT, "%s_hat_%d.glb" % (HAT_OF, cubes))
    export([hat], path)
    print("wrote", os.path.relpath(path, ROOT), json.dumps({"faces": len(polys), "was": before, "cube_mm": round(cube * 1000, 2),
                                                         "hat_from": HAT_FROM, "triangles_cut": int(keep.sum())}))


def bary(p, vs):
    a, b, c = vs
    v0, v1, v2 = b - a, c - a, p - a
    d00, d01, d11 = v0.dot(v0), v0.dot(v1), v1.dot(v1)
    d20, d21 = v2.dot(v0), v2.dot(v1)
    den = d00 * d11 - d01 * d01
    if abs(den) < 1e-12:
        return (1.0, 0.0, 0.0)
    v = (d11 * d20 - d01 * d21) / den
    w = (d00 * d21 - d01 * d20) / den
    return (1.0 - v - w, v, w)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    cubes_list = [128, 64]
    only = None
    for a in args:
        if a.startswith("--cubes="):
            cubes_list = [int(x) for x in a.split("=", 1)[1].split(",")]
        elif a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for cubes in cubes_list:
        do_props(cubes, [o for o in only if o != "hat"] if only else None)
        if not only or "hat" in only:
            do_hat(cubes)


if __name__ == "__main__":
    main()
