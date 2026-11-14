"""Quick look at a train model in Blender (Cycles on the CPU, a sun and a sky): a few fixed views
of a glb, for shaping it before it goes in the game. Not the game's look: its own flat materials.

    ~/bpyenv/bin/python experiments/train_lab/blender/render_views.py assets/train/engine.glb OUTDIR [--samples=16]

Writes OUTDIR/<view>.png (side, front34, rear34, gear, top) and OUTDIR/sheet.png (all of them).
"""
import math
import os
import sys

import bpy
from mathutils import Vector


def arg(name, default):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


GLB = os.path.abspath(sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else sys.argv[-2])
OUT = os.path.abspath(sys.argv[sys.argv.index("--") + 2] if "--" in sys.argv else sys.argv[-1])
for a in list(sys.argv[1:]):
    if a.startswith("--") and "=" in a:
        pass
SAMPLES = int(arg("samples", "16"))
W, H = 900, 500

# Views in Blender's frame (the glb's: +Y is the engine's front, +Z up): (eye, target, lens).
VIEWS = {
    "side": ((-11.5, 0.3, 1.7), (0.0, 0.3, 1.5), 40),
    "front34": ((-6.5, 9.0, 2.6), (0.0, 1.5, 1.4), 40),
    "rear34": ((6.0, -10.0, 3.6), (0.0, -2.5, 1.6), 40),
    "gear": ((-4.2, 1.2, 0.9), (0.0, 0.3, 0.6), 35),
    "top": ((-5.0, 0.3, 9.0), (0.0, 0.3, 1.0), 35),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=GLB)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = False
    sc.render.resolution_x, sc.render.resolution_y = W, H
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.6, 0.7, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.8
    sc.world = world
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), 0.0, math.radians(-40))
    sc.collection.objects.link(sun)
    # Ground: a big plane at the rail top.
    bpy.ops.mesh.primitive_plane_add(size=60, location=(0, 0, -0.01))
    ground = bpy.context.active_object
    gm = bpy.data.materials.new("ground")
    gm.use_nodes = True
    gm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.45, 0.38, 0.3, 1)
    ground.data.materials.append(gm)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    shots = []
    for name, (eye, target, lens) in VIEWS.items():
        cam.location = Vector(eye)
        cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        path = os.path.join(OUT, name + ".png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        shots.append(path)
    try:
        from PIL import Image
        ims = [Image.open(p).convert("RGB").resize((W // 2, H // 2)) for p in shots]
        sheet = Image.new("RGB", (W, (H // 2) * ((len(ims) + 1) // 2)))
        for i, im in enumerate(ims):
            sheet.paste(im, ((i % 2) * (W // 2), (i // 2) * (H // 2)))
        sheet.save(os.path.join(OUT, "sheet.png"))
    except ImportError:
        pass


main()
