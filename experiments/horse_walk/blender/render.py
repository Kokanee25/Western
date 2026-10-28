"""Preview renders of the walk (build/horse_walk/walk.blend, from walk_build.py): Cycles on the
CPU, low samples. The armature is moved forward at the walking speed, so planted hooves stand
on the chequered ground (25 cm squares: a slide shows against them).

    ~/bpyenv/bin/python experiments/horse_walk/blender/render.py --film=side|threeq [--strides=2]
    ~/bpyenv/bin/python experiments/horse_walk/blender/render.py --phases=0,0.125,...  (stills)
Frames go to build/horse_walk/<name>/; films are made from them with ffmpeg (make_films.sh).
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as C  # noqa: E402

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
opts = dict(a[2:].split("=", 1) for a in args if a.startswith("--") and "=" in a)
bpy.ops.wm.open_mainfile(filepath=os.path.join(C.OUT, "walk.blend"))
arm = bpy.data.objects["Horse"]
sc = bpy.context.scene
import json  # noqa: E402
rep = json.load(open(os.path.join(C.OUT, "walk_report.json")))
T, v, keys = rep["walk"]["T"], rep["walk"]["v"], rep["walk"]["frames"]
KEY_FPS = keys / T


def chequer():
    bpy.ops.mesh.primitive_plane_add(size=60, location=(-10, 0, -0.03))
    g = bpy.context.object
    mat = bpy.data.materials.new("chequer")
    mat.use_nodes = True
    nt = mat.node_tree
    ch = nt.nodes.new("ShaderNodeTexChecker")
    ch.inputs["Scale"].default_value = 60 / 0.25 / 2 * 1.0
    ch.inputs["Color1"].default_value = (0.36, 0.30, 0.24, 1)
    ch.inputs["Color2"].default_value = (0.46, 0.39, 0.31, 1)
    tc = nt.nodes.new("ShaderNodeTexCoord")
    nt.links.new(tc.outputs["UV"], ch.inputs["Vector"])
    nt.links.new(ch.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
    nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 1.0
    g.data.materials.append(mat)


def setup(size):
    C.scene(size=size)
    sc.cycles.samples = int(opts.get("samples", 10))
    sc.view_settings.view_transform = "Standard"
    chequer()


def at(t):
    """The pose at time t (seconds) with the body moved forward."""
    k = (t * KEY_FPS) % keys
    sc.frame_set(int(math.floor(k)), subframe=k - math.floor(k))
    arm.location = (-v * t, 0, 0)
    bpy.context.view_layer.update()


def film(kind):
    strides = float(opts.get("strides", 2))
    fps = 30
    n = int(round(strides * T * fps))
    out = os.path.join(C.OUT, "film_" + kind)
    os.makedirs(out, exist_ok=True)
    if kind == "side":
        setup((960, 600))
        # from his left, a little above (as the clip's camera): the ground shows
        cam = C.persp_camera((-0.1, -8.0, 1.7), (-0.1, 0, 0.85), lens=45)
    else:
        setup((960, 600))
        cam = C.persp_camera((-3.2, -4.6, 1.9), (-0.25, 0, 0.85), lens=40)
    base = cam.location.copy()
    for i in range(n):
        t = i / fps
        at(t)
        cam.location = (base.x - v * t, base.y, base.z)
        C.render(os.path.join(out, "f%03d.png" % i))
    print("film", kind, n, "frames")


def stills():
    phases = [float(p) for p in opts["phases"].split(",")]
    out = os.path.join(C.OUT, opts.get("name", "stills"))
    os.makedirs(out, exist_ok=True)
    setup((900, 640))
    cam = C.persp_camera((-0.15, -9.0, 1.35), (-0.15, 0, 0.95), lens=70)
    base = cam.location.copy()
    for ph in phases:
        t = ph * T + T     # the second stride (the solve has warmed up; it's periodic anyway)
        at(t)
        cam.location = (base.x - v * t, base.y, base.z)
        C.render(os.path.join(out, "p%03d.png" % int(round(ph * 1000))))
    print("stills", phases)


if "film" in opts:
    film(opts["film"])
if "phases" in opts:
    stills()
