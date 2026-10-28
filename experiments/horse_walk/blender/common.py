"""Shared by the walk experiment's Blender scripts: the game's horse loaded from its glb (read,
never written), painted with its own textures for preview renders, a side camera, and drawing
the bones over a render.

Axes as Blender imports the glb: x back (the head is at -x), y to his right (his left side is -y),
z up; metres.
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
HORSE = os.path.join(ROOT, "assets", "creatures", "horse")
OUT = os.path.join(ROOT, "build", "horse_walk")
LEGS = {
    "LF": ["scapula.L", "upperarm.L", "forearm.L", "cannon.L", "pastern.L", "hoof.L"],
    "RF": ["scapula.R", "upperarm.R", "forearm.R", "cannon.R", "pastern.R", "hoof.R"],
    "LH": ["thigh.L", "shin.L", "hcannon.L", "hpastern.L", "hhoof.L"],
    "RH": ["thigh.R", "shin.R", "hcannon.R", "hpastern.R", "hhoof.R"],
}


def load(lod=False):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(HORSE, "horse.glb"))
    far = ("coat_lod", "tack_lod")
    for o in list(bpy.data.objects):
        # the glb's stray unparented Icosphere out, and the near or the far meshes
        if o.type == "MESH" and (o.parent is None or (o.name in far) != lod):
            bpy.data.objects.remove(o)
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    paint()
    return arm


def _image_material(name, png):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(HORSE, png))
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.9
    return mat


def paint():
    coat = _image_material("coat", "horse_coat.png")
    tack = _image_material("tack", "horse_tack.png")
    for o in bpy.data.objects:
        if o.type != "MESH":
            continue
        o.data.materials.clear()
        o.data.materials.append(coat if o.name.startswith("coat") else tack)


def scene(fps=30, size=(960, 640), engine="CYCLES"):
    sc = bpy.context.scene
    sc.render.engine = engine
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.resolution_percentage = 100
    sc.render.fps = fps
    sc.render.image_settings.file_format = "PNG"
    if engine == "BLENDER_WORKBENCH":
        sh = sc.display.shading
        sh.light = "STUDIO"
        sh.color_type = "TEXTURE"
        sh.show_shadows = False
        sh.show_cavity = False
    else:
        sc.cycles.samples = 12
        sc.cycles.device = "CPU"
        sc.cycles.use_denoising = False
        sc.cycles.max_bounces = 2
        sun = bpy.data.lights.new("sun", "SUN")
        sun.energy = 3.0
        so = bpy.data.objects.new("sun", sun)
        so.rotation_euler = (0.9, 0.0, -0.6)
        sc.collection.objects.link(so)
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.55, 0.55, 1)
    sc.world = world
    return sc


def ground(size=40.0, z=0.0):
    bpy.ops.mesh.primitive_plane_add(size=size, location=(0, 0, z))
    g = bpy.context.object
    mat = bpy.data.materials.new("ground")
    mat.diffuse_color = (0.42, 0.36, 0.30, 1)
    g.data.materials.append(mat)
    return g


def side_camera(centre=(0.0, 0.0, 0.95), width=3.6, side=-1.0, name="side"):
    """Orthographic, from his left (side=-1) or right, level."""
    cam = bpy.data.cameras.new(name)
    cam.type = "ORTHO"
    cam.ortho_scale = width
    o = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(o)
    o.location = (centre[0], side * 10.0, centre[2])
    o.rotation_euler = (math.radians(90), 0, 0 if side < 0 else math.radians(180))
    bpy.context.scene.camera = o
    return o


def persp_camera(loc, target, lens=50, name="persp"):
    cam = bpy.data.cameras.new(name)
    cam.lens = lens
    o = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(o)
    o.location = loc
    d = Vector(target) - Vector(loc)
    o.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = o
    return o


def to_pixel(cam, p):
    """A world point to the render's pixel (x right, y down)."""
    from bpy_extras.object_utils import world_to_camera_view
    sc = bpy.context.scene
    v = world_to_camera_view(sc, cam, Vector(p))
    return v.x * sc.render.resolution_x, (1.0 - v.y) * sc.render.resolution_y


def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
