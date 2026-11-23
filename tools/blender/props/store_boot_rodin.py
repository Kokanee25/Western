"""The general store's hung boots, by Rodin (#1175, #1192 G4/G5; Sean made the model himself in his own Rodin
account from a picture, 2026-11-23: one russet pull-on boot with two pull straps, 500,000 triangles, three
2048 textures). The steps are rodin_prop.py's (the doctor's bag's recipe):

    ~/.venvs/studio/bin/python tools/blender/props/store_boot_rodin.py BOOT.glb [OUT_DIR]

Stood on y = 0, its toe to +z (game space), its length LENGTH along z, centred on x and on its length, decimated
to TRIS, its base colour resized to TEX_PX (`store_boot_paint.png`; the kit draws it as `model:store_boot`).
Writes `store_boot.glb` (one part, `boot`, no materials) and the paint into OUT_DIR (default assets/props/models).
**Licence first:** the Rodin file's terms for Sean's Creator plan are unrecorded (Studio ledgers/licences.md): do not
commit the outputs to this public repo until they are.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rodin_prop as R  # noqa: E402

LENGTH = 0.31        # m, toe to heel: a 12 in pull-on's sole with the heel (~0.30 to 0.32)
TRIS = 10000
TEX_PX = 1024


def stand(obj):
    """Length along z, toe to +z, base on y = 0, centred on x and z. Returns the size."""
    g = R.game_verts(obj)
    d = np.ptp(g, 0)
    if d[0] > d[2]:      # lying along x: a quarter turn about y
        g = np.stack([g[:, 2], g[:, 1], -g[:, 0]], 1)
    top = g[:, 1] > g[:, 1].min() + 0.8 * np.ptp(g[:, 1])    # the shaft's rim
    if g[top, 2].mean() > (g[:, 2].min() + g[:, 2].max()) / 2:   # the shaft is over the +z end: that's the heel
        g[:, 0] *= -1
        g[:, 2] *= -1
    g *= LENGTH / np.ptp(g[:, 2])
    g[:, 0] -= (g[:, 0].min() + g[:, 0].max()) / 2
    g[:, 2] -= (g[:, 2].min() + g[:, 2].max()) / 2
    g[:, 1] -= g[:, 1].min()
    R.set_game_verts(obj, g)
    print("size %s m" % np.round(np.ptp(g, 0), 3))
    return np.ptp(g, 0)


def bake_paint(high, low, out_png):
    """The high model's base colour baked onto the low one's own fresh UVs (plain decimation left streaks along
    the old UV seams): smart-UV the low, Cycles `selected to active` DIFFUSE colour only, TEX_PX square."""
    import bpy
    low.data.materials.clear()
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    img = bpy.data.images.new("bake", TEX_PX, TEX_PX)
    mat = bpy.data.materials.new("bake")
    mat.use_nodes = True
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = img
    mat.node_tree.nodes.active = node
    low.data.materials.append(mat)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 8
    sc.render.bake.use_pass_direct = False
    sc.render.bake.use_pass_indirect = False
    sc.render.bake.use_pass_color = True
    sc.render.bake.margin = 8
    bpy.ops.object.select_all(action="DESELECT")
    high.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.bake(type="DIFFUSE", use_selected_to_active=True, cage_extrusion=0.006, max_ray_distance=0.02)
    img.filepath_raw = out_png
    img.file_format = "PNG"
    img.save()
    low.data.materials.clear()
    print("baked", out_png)


def main():
    import bpy
    out = sys.argv[2] if len(sys.argv) > 2 else R.MODELS
    os.makedirs(out, exist_ok=True)
    high = R.load(sys.argv[1])
    stand(high)
    low = high.copy()
    low.data = high.data.copy()
    bpy.context.scene.collection.objects.link(low)
    R.decimate(low, TRIS)
    bake_paint(high, low, os.path.join(out, "store_boot_paint.png"))
    bpy.data.objects.remove(high)
    R.split_and_export(low, os.path.join(out, "store_boot.glb"), lambda c: "boot", ("boot",))


if __name__ == "__main__":
    main()
