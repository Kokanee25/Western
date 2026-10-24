"""The mounted deer head from Sean's six pictures (2026-10-24: "make a prop that the other session
is having trouble with"), made 3D by Rodin through the Character Studio (its request
`requests/2026-10-24_deer_head_rodin.yaml`, $1.60) in place of deer_head.py's modelled one.

    ~/.venvs/studio/bin/python tools/blender/props/deer_head_rodin.py RODIN.glb

RODIN.glb is the Studio's paid/526815a52c02... (Kokanee25/saltcreek-characters, its ledger row
prop:deer_head): this script remade from it writes the same files. Run it, not build.py.

Rodin's model is turned into the kit's space for `deer_head` (metres, x right, y up, z out of the
wall; the plaque's back on the wall at z 0.02, its top at y 0.02, as deer_head.py's, so the kit
file's nails hold it), cut down to a wall prop's triangles, and split into the kit's parts by where
each triangle lies: `plaque` (the wood: everything within the plaque's thickness of the wall),
`nose` (the muzzle, inside the muzzle member's box), `head` (from the skull up: ears, eyes and
antlers with it) and `neck` (the rest of the hide). Its own painted texture goes beside it as
deer_head_paint.png, its UVs kept (0..1): the kit's look `model:deer_head` draws it.
"""
import os
import sys

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
MODELS = os.path.join(ROOT, "assets", "props", "models")

PLAQUE_H = 0.47      # the plaque's height (m): the kit's plaque member, 0.4695
PLAQUE_FRONT = 0.06  # nearer the wall than this is the plaque (m, z); its back at 0.02
TRIS = 6000          # a wall prop's budget (deer_head.py's was ~1,500 of flat colours)
TEX_PX = 1024        # the paint's size (Rodin's is 4096)
STRAY = 0.06         # see drop_strays
# The split (m, the kit's space): the head from NECK_TOP up (ears, eyes, antlers with it), the
# muzzle the part of it out past MUZZLE_OUT; the kit file's members are boxed round each part.
NECK_TOP = -0.10
MUZZLE_OUT = 0.30    # (below MUZZLE_TOP: the antlers' tines reach as far out)
MUZZLE_TOP = 0.04
SKULL_TOP = 0.06     # the head member's box is the skull's, to here: the ears and rack drawn past it


def load(path):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return drop_strays(obj)


def drop_strays(obj):
    """Loose pieces that aren't the mount: Rodin laid a rod under the plaque (the pictures' floor
    shadow, 2026-10-24), flat and as wide as the antlers, and specks at its ends. A loose piece
    thinner than STRAY of the whole's height and wider than its own height many times over goes,
    and so does any small one wholly in the bottom STRAY of the whole (nothing of the mount's there
    but the plaque's tip, which is part of the plaque)."""
    import bpy
    allv = np.array([v.co[:] for v in obj.data.vertices])
    full = np.ptp(allv, 0)
    floor = allv[:, 2].min() + STRAY * full[2]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    pieces = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    gone = 0
    for o in pieces:
        pv = np.array([v.co[:] for v in o.data.vertices])
        d = np.ptp(pv, 0)   # Blender: z up
        rod = d[2] < STRAY * full[2] and max(d[0], d[1]) > 6 * d[2]
        speck = pv[:, 2].max() < floor and np.linalg.norm(d) < 0.05 * np.linalg.norm(full)
        if rod or speck:
            bpy.data.objects.remove(o)
            gone += 1
    pieces = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in pieces:
        o.select_set(True)
    bpy.context.view_layer.objects.active = pieces[0]
    if len(pieces) > 1:
        bpy.ops.object.join()
    print("loose pieces %d, %d strays dropped" % (len(pieces) + gone, gone))
    return bpy.context.view_layer.objects.active


def game_verts(obj):
    """Its vertices in game space (Blender z up, -y out -> y up, z out)."""
    v = np.array([vv.co[:] for vv in obj.data.vertices])
    return np.stack([v[:, 0], v[:, 2], -v[:, 1]], 1)


def place(obj):
    """Turned to face +z (the plaque's flat back on the wall), scaled by the plaque's height, the
    back at z 0.02 and the plaque's top at y 0.02."""
    import bpy
    g = game_verts(obj)
    # The plaque is the flat back: the side with the most vertices near its extreme along z.
    back_lo = (g[:, 2] < g[:, 2].min() + 0.02 * np.ptp(g[:, 2])).sum()
    back_hi = (g[:, 2] > g[:, 2].max() - 0.02 * np.ptp(g[:, 2])).sum()
    if back_hi > back_lo:                 # facing -z: half a turn about y
        g[:, 0] *= -1
        g[:, 2] *= -1
    # The plaque's height: the vertices in its slab, nearest the wall.
    z0 = g[:, 2].min()
    slab = g[g[:, 2] < z0 + 0.15 * np.ptp(g[:, 2])]
    s = PLAQUE_H / np.ptp(slab[:, 1])
    g *= s
    slab = slab * s
    g[:, 0] -= (slab[:, 0].min() + slab[:, 0].max()) / 2
    g[:, 1] += 0.02 - slab[:, 1].max()
    g[:, 2] += 0.02 - g[:, 2].min()
    for vv, p in zip(obj.data.vertices, g):
        vv.co = (p[0], -p[2], p[1])
    obj.data.update()
    print("scale %.4f; size %s m" % (s, np.round(np.ptp(g, 0), 3)))


def decimate(obj):
    import bpy
    n = len(obj.data.polygons)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    m = obj.modifiers.new("cut", "DECIMATE")
    m.ratio = min(1.0, TRIS / max(tris, 1))
    m.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=m.name)
    print("triangles %d -> %d (%d faces before)" % (tris, sum(len(p.vertices) - 2 for p in obj.data.polygons), n))


def part_of(c):
    """Which kit part a triangle at centre `c` (game space) belongs to."""
    if c[2] < PLAQUE_FRONT:
        return "plaque"
    if c[1] < NECK_TOP:
        return "neck"
    return "nose" if c[2] > MUZZLE_OUT and c[1] < MUZZLE_TOP else "head"


def split_and_export(obj, out):
    import bpy
    import bmesh
    g = game_verts(obj)
    names = [part_of(g[list(p.vertices)].mean(0)) for p in obj.data.polygons]
    counts = {}
    for name in ("plaque", "neck", "head", "nose"):
        keep = [i for i, nm in enumerate(names) if nm == name]
        counts[name] = len(keep)
        if not keep:
            continue
        o = obj.copy()
        o.data = obj.data.copy()
        o.name = o.data.name = name
        bpy.context.scene.collection.objects.link(o)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bm.faces.ensure_lookup_table()
        keep_set = set(keep)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep_set], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        used = sorted({i for poly in o.data.polygons for i in poly.vertices})
        p = game_verts(o)[used]
        if name == "head":
            p = p[p[:, 1] < SKULL_TOP]
        lo, hi = p.min(0), p.max(0)
        print("box %s at %s size %s" % (name, np.round((lo + hi) / 2, 4).tolist(), np.round(hi - lo, 4).tolist()))
        o.data.materials.clear()
    bpy.data.objects.remove(obj)
    print("parts (triangles):", counts)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)


def paint(src_glb, out_png):
    """Rodin's base colour, resized once to TEX_PX."""
    import bpy
    from PIL import Image
    imgs = [i for i in bpy.data.images if i.size[0] > 0]
    base = next((i for i in imgs if "base" in i.name.lower() or "diffuse" in i.name.lower() or "albedo" in i.name.lower()), None)
    if base is None:
        # The image the material's Base Color takes.
        for mat in bpy.data.materials:
            if mat.use_nodes:
                bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
                if bsdf and bsdf.inputs["Base Color"].links:
                    base = bsdf.inputs["Base Color"].links[0].from_node.image
                    break
    tmp = out_png + ".src.png"
    base.filepath_raw = tmp
    base.file_format = "PNG"
    base.save()
    im = Image.open(tmp).convert("RGB")
    print("paint %s %s -> %d" % (base.name, im.size, TEX_PX))
    im.resize((TEX_PX, TEX_PX), Image.LANCZOS).save(out_png, optimize=True)
    os.remove(tmp)


def main():
    src = sys.argv[1]
    obj = load(src)
    paint(src, os.path.join(MODELS, "deer_head_paint.png"))
    place(obj)
    decimate(obj)
    split_and_export(obj, os.path.join(MODELS, "deer_head.glb"))


if __name__ == "__main__":
    main()
