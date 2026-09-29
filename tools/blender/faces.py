"""Faces painted by an image model, put on the MakeHuman head (DESIGN.md §4 step 4).

  1. `guide()`: a flat front view of his fitted head (orthographic, grey, 512 px, a known frame),
     saved as assets/people/<id>_face_guide.png. tools/faces/paint_face.py sends it with a prompt
     and a style reference to the image model, which paints a face onto it, keeping the outline
     and where the eyes, nose and mouth are; its answer is assets/people/<id>_face_portrait.png.
  2. `project()`: that portrait projected straight onto the front of the head and baked into the
     face painter's layout (u round the head, v by height), then cut to a small palette: the
     front of the face comes from the painting, fading out round the sides where the front view
     can't see, so PeopleArt.face's painted hair, ears and back of the head show there. Saved as
     assets/people/<id>_face.png (RGBA: alpha = how much of the portrait to use).
"""
import os

import numpy as np

try:
    import bpy
except ImportError:
    bpy = None

# The guide's frame in our body space (metres): centred on the face, square.
FRAME_X = 0.0
FRAME_Y = 1.665
FRAME_SIZE = 0.3
GUIDE_PX = 512


def guide(head_obj, path):
    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("guide")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = FRAME_SIZE
    cam = bpy.data.objects.new("guide", cam_data)
    scene.collection.objects.link(cam)
    # In Blender space he faces +Y (our -Z); stand in front of him looking back at him.
    cam.location = (FRAME_X, 1.0, FRAME_Y)
    cam.rotation_euler = (np.pi / 2, 0.0, np.pi)
    scene.camera = cam
    # Cycles on the CPU (Workbench/EEVEE need a GPU): plain grey clay in soft, even light.
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    scene.world.use_nodes = True
    bg = scene.world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.9, 0.9, 0.9, 1.0)
        bg.inputs[1].default_value = 1.0
    clay = bpy.data.materials.new("clay")
    clay.use_nodes = True
    bsdf = clay.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.6, 0.58, 0.56, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
    old = list(head_obj.data.materials)
    head_obj.data.materials.clear()
    head_obj.data.materials.append(clay)
    scene.render.resolution_x = GUIDE_PX
    scene.render.resolution_y = GUIDE_PX
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    hidden = []
    for o in scene.objects:
        if o.type == "MESH" and o is not head_obj and not o.hide_render:
            o.hide_render = True
            hidden.append(o)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hidden:
        o.hide_render = False
    head_obj.data.materials.clear()
    for m in old:
        head_obj.data.materials.append(m)
    bpy.data.objects.remove(cam)


def _front_uv(p):
    """Where a point (our body space) falls in the guide image (0..1, top-left origin)."""
    u = 0.5 - (p[0] - FRAME_X) / FRAME_SIZE  # his right (+X) is on the picture's left
    v = 0.5 - (p[1] - FRAME_Y) / FRAME_SIZE
    return u, v


def project(person, head_faces, head_uv, portrait_path, out_path, width=192, height=128, colours=24):
    """Rasterise the portrait into the face layout, triangle by triangle, weighted by how square
    to the front each bit of the head is. Pure numpy: no bake needed, and exact."""
    from PIL import Image  # only here: the rest of the pipeline doesn't need PIL
    img = np.asarray(Image.open(portrait_path).convert("RGB").resize((GUIDE_PX, GUIDE_PX)), dtype=float) / 255.0
    out = np.zeros((height, width, 3))
    alpha = np.zeros((height, width))
    v = person.v
    for fv, _t in head_faces:
        if len(fv) < 3:
            continue
        for tri in ([fv[0], fv[i], fv[i + 1]] for i in range(1, len(fv) - 1)):
            uv = np.array([head_uv(v[i]) for i in tri])
            if uv[:, 0].max() - uv[:, 0].min() > 0.12:
                continue  # across the seam, or smeared round the axis under the chin
            src = np.array([_front_uv(v[i]) for i in tri])
            nrm = np.cross(v[tri[1]] - v[tri[0]], v[tri[2]] - v[tri[0]])
            ln = np.linalg.norm(nrm)
            if ln < 1e-12:
                continue
            # How square it is to the front (toward -Z, the viewer); its own normal, so the
            # eyeballs and anything without smooth normals count too.
            facing = np.full(3, max(0.0, -nrm[2] / ln) if abs(nrm[1] / ln) < 0.85 else 0.0)
            xs = uv[:, 0] * width
            ys = uv[:, 1] * height
            x0, x1 = int(max(np.floor(xs.min()), 0)), int(min(np.ceil(xs.max()), width - 1))
            y0, y1 = int(max(np.floor(ys.min()), 0)), int(min(np.ceil(ys.max()), height - 1))
            d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
            if abs(d) < 1e-9:
                continue
            for py in range(y0, y1 + 1):
                for px in range(x0, x1 + 1):
                    cx, cy = px + 0.5, py + 0.5
                    a = ((ys[1] - ys[2]) * (cx - xs[2]) + (xs[2] - xs[1]) * (cy - ys[2])) / d
                    b = ((ys[2] - ys[0]) * (cx - xs[2]) + (xs[0] - xs[2]) * (cy - ys[2])) / d
                    c = 1 - a - b
                    if min(a, b, c) < -0.02:
                        continue
                    su, sv = a * src[0] + b * src[1] + c * src[2]
                    f = a * facing[0] + b * facing[1] + c * facing[2]
                    ix = int(np.clip(su * GUIDE_PX, 0, GUIDE_PX - 1))
                    iy = int(np.clip(sv * GUIDE_PX, 0, GUIDE_PX - 1))
                    out[py, px] = img[iy, ix]
                    alpha[py, px] = np.clip((f - 0.35) / 0.35, 0, 1)
    # A small palette, so it stays pixel art: the portrait's own colours, clustered.
    pim = Image.fromarray((out * 255).astype(np.uint8)).quantize(colors=colours, method=Image.Quantize.MEDIANCUT)
    rgb = np.asarray(pim.convert("RGB"), dtype=np.uint8)
    rgba = np.concatenate([rgb, (alpha[:, :, None] * 255).astype(np.uint8)], axis=2)
    Image.fromarray(rgba, "RGBA").save(out_path)
