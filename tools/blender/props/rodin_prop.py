"""A Rodin model made into a kit prop (the deer head and the steer skull, 2026-10-24): the steps every
prop made by Rodin through the Character Studio (`studio prop3d`) goes through, its own script
(deer_head_rodin.py, steer_skull_rodin.py) saying only its size and how it splits into the kit's
parts.

    load -> place -> decimate -> paint -> split_and_export

Game space throughout: metres, x right, y up, z out of the wall (Blender: z up, -y out). A wall
prop's back lies on the wall at z `back`, its top at y `top`, as the kit file's nails expect.
"""
import os

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
MODELS = os.path.join(ROOT, "assets", "props", "models")

STRAY = 0.06  # see drop_strays


def load(path):
    """Rodin's model as one mesh object, its transforms applied and its strays dropped."""
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
    """Loose pieces that aren't the prop: Rodin laid a rod under the deer's plaque (the pictures'
    floor shadow), flat and as wide as the antlers, and specks at its ends. A loose piece thinner
    than STRAY of the whole's height and wider than its own height many times over goes, and so
    does any small one wholly in the bottom STRAY of the whole."""
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


def set_game_verts(obj, g):
    for vv, p in zip(obj.data.vertices, g):
        vv.co = (p[0], -p[2], p[1])
    obj.data.update()


def place(obj, back_height=None, width=None, back=0.02, top=0.02):
    """Turned to face +z (its flat back on the wall), scaled so the back's slab (what lies near the
    wall: a plaque, a plank) is `back_height` tall, or the whole `width` wide; the back at z `back`,
    the slab's top at y `top`, centred on x."""
    g = game_verts(obj)
    # The back is flat: the side with the most vertices near its extreme along z.
    near_lo = (g[:, 2] < g[:, 2].min() + 0.02 * np.ptp(g[:, 2])).sum()
    near_hi = (g[:, 2] > g[:, 2].max() - 0.02 * np.ptp(g[:, 2])).sum()
    if near_hi > near_lo:                 # facing -z: half a turn about y
        g[:, 0] *= -1
        g[:, 2] *= -1
    z0 = g[:, 2].min()
    slab = g[g[:, 2] < z0 + 0.15 * np.ptp(g[:, 2])]
    s = back_height / np.ptp(slab[:, 1]) if back_height else width / np.ptp(g[:, 0])
    g *= s
    slab = slab * s
    g[:, 0] -= (slab[:, 0].min() + slab[:, 0].max()) / 2
    g[:, 1] += top - slab[:, 1].max()
    g[:, 2] += back - g[:, 2].min()
    set_game_verts(obj, g)
    print("scale %.4f; size %s m" % (s, np.round(np.ptp(g, 0), 3)))


def decimate(obj, tris):
    import bpy
    n = len(obj.data.polygons)
    before = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    m = obj.modifiers.new("cut", "DECIMATE")
    m.ratio = min(1.0, tris / max(before, 1))
    m.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=m.name)
    print("triangles %d -> %d (%d faces before)" % (before, sum(len(p.vertices) - 2 for p in obj.data.polygons), n))


def paint(out_png, px):
    """Rodin's base colour, resized once to px square: the kit's look `model:<id>` draws it."""
    import bpy
    from PIL import Image
    base = None
    for mat in bpy.data.materials:
        if mat.use_nodes:
            bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            if bsdf and bsdf.inputs["Base Color"].links:
                base = bsdf.inputs["Base Color"].links[0].from_node.image
                break
    if base is None:
        base = next(i for i in bpy.data.images if "diffuse" in i.name.lower() or "base" in i.name.lower())
    tmp = out_png + ".src.png"
    base.filepath_raw = tmp
    base.file_format = "PNG"
    base.save()
    im = Image.open(tmp).convert("RGB")
    print("paint %s %s -> %d" % (base.name, im.size, px))
    im.resize((px, px), Image.LANCZOS).save(out_png, optimize=True)
    os.remove(tmp)


def split_and_export(obj, out, part_of, names, box_of=None):
    """One object a kit part (`part_of(centre)` names each triangle's), written to `out` (.glb, no
    materials: the kit draws them). Prints each part's box (its centre and size, game space) for its
    kit member; `box_of(name, points)` may narrow the points a box is taken round."""
    import bpy
    import bmesh
    g = game_verts(obj)
    which = [part_of(g[list(p.vertices)].mean(0)) for p in obj.data.polygons]
    counts, boxes = {}, {}
    for name in names:
        keep = {i for i, nm in enumerate(which) if nm == name}
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
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        o.data.materials.clear()
        used = sorted({i for poly in o.data.polygons for i in poly.vertices})
        p = game_verts(o)[used]
        if box_of:
            p = box_of(name, p)
        lo, hi = p.min(0), p.max(0)
        boxes[name] = (np.round((lo + hi) / 2, 4).tolist(), np.round(hi - lo, 4).tolist())
        print("box %s at %s size %s" % (name, *boxes[name]))
    bpy.data.objects.remove(obj)
    print("parts (triangles):", counts)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)
    return boxes
