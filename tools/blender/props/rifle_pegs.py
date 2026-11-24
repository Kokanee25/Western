"""The rifle over the bar (#1030, S5): the game's own Winchester 1873 (assets/weapons/winchester73.glb, the gun
lab's model, its own painted textures) laid on its side on two pegs in the wall, as saloon keepers hung a
gun where the bartender could reach it. Nothing remodelled: its parts are taken whole (their UVs on the
gun's two sheets, `w73_action` and `w73_long`), turned to lie along x with its right side to the room and
its muzzle to the right, and written as two parts, RifleAction and RifleLong, into
assets/props/models/rifle_pegs.glb. The kit file (tools/props/saloon_walls.py) draws them with the gun's
own textures (`pbr:res://assets/weapons/winchester73_w73_action`). Its numbers (where each peg meets it)
are printed for that file.

    ~/.venvs/bpy/bin/python tools/blender/props/rifle_pegs.py
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import common  # noqa: E402

GUN = os.path.join(common.ROOT, "assets", "weapons", "winchester73.glb")
SKIP = ("Bullet", "Case")      # the rounds aren't shown
OUT_Z = 0.075                  # the gun's middle off the wall's face
PEGS_X = (-0.36, 0.30)         # the pegs under the stock's wrist and the forend (prop x)


def build():
    import bpy
    from mathutils import Matrix
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=GUN)
    groups = {"RifleAction": [], "RifleLong": []}
    # Blender's space -> the game's (x, z up -> y, -y -> z), the gun turned -90 about y (its -z
    # muzzle to +x, its right side +x to the room's +z).
    turn = Matrix.Rotation(math.radians(-90), 4, "Y")
    for ob in bpy.data.objects:
        if ob.type != "MESH" or ob.name.startswith(SKIP):
            continue
        me = ob.data
        uv = me.uv_layers.active.data
        for poly in me.polygons:
            mat = me.materials[poly.material_index].name if me.materials else ""
            key = "RifleAction" if "action" in mat else "RifleLong" if "long" in mat else None
            if key is None:
                continue
            face = []
            for li, vi in zip(poly.loop_indices, poly.vertices):
                w = ob.matrix_world @ me.vertices[vi].co
                g = (w.x, w.z, -w.y)       # the game's space
                p = turn @ __import__("mathutils").Vector(g)
                face.append(((p.x, p.y, p.z), tuple(uv[li].uv)))
            groups[key].append(face)
    allv = [v for fs in groups.values() for f in fs for v, _ in f]
    xs, ys, zs = zip(*allv)
    cx, cz = (min(xs) + max(xs)) * 0.5, (min(zs) + max(zs)) * 0.5
    # Each peg's top: the gun's lowest point within 2 cm of it.
    tops = []
    for px in PEGS_X:
        tops.append(min(y for x, y, z in allv if abs(x - cx - px) < 0.02))
    base = min(tops)
    parts = []
    for name, faces in groups.items():
        part = common.Part(name, True)
        verts, uvs, idx = [], [], []
        for f in faces:
            ids = []
            for (x, y, z), t in f:
                ids.append(len(verts))
                verts.append((x - cx, y - base, z - cz + OUT_Z))
                uvs.append(t)
            idx.append(ids)
        part.add(verts, idx)
        part.uvs = uvs
        parts.append(part)
    _export(parts)
    print("rifle_pegs: length %.3f, height %.3f, depth %.3f; peg tops %s (over the lower)" % (
        max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs), [round(t - base, 4) for t in tops]))


def _export(parts):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for part in parts:
        mesh = bpy.data.meshes.new(part.name)
        mesh.from_pydata([(x, -z, y) for x, y, z in part.verts], [], part.faces)
        lay = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li, vi in zip(poly.loop_indices, poly.vertices):
                lay.data[li].uv = part.uvs[vi]
        mesh.validate()
        for poly in mesh.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new(part.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
    path = os.path.join(common.MODELS, "rifle_pegs.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)
    print("-> %s" % os.path.relpath(path, common.ROOT))


if __name__ == "__main__":
    build()
