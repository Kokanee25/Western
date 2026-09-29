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


## The face texture's size and palette. Small on purpose: at the painting's distance his face is
## ~70x80 screen pixels at 640x360, and at 96x64 each texel covers 2-3 of them, the painting's
## blocks. The portrait is projected at SUPERSAMPLE x this and averaged down, so each block is the
## real average of its patch (not one sampled pixel), then cut to FACE_COLOURS and cleared of lone
## stray pixels. It matches PeopleArt.FACE_W/FACE_H, the painted face it's laid over.
FACE_W = 96
FACE_H = 64
FACE_COLOURS = 20
SUPERSAMPLE = 4

## How far behind the nearest surface the front view saw a point may be and still count as seen
## (metres): the guide's pixels are 0.6 mm, and steep bits (the sides of the nose) change fast.
DEPTH_SLACK = 0.004


def _triangles(head_faces):
    for fv, _t in head_faces:
        for i in range(1, len(fv) - 1):
            yield [fv[0], fv[i], fv[i + 1]]


def _raster(xs, ys, w, h):
    """Pixel centres inside a triangle (a hair of slack at the edges) and their barycentrics."""
    x0, x1 = int(max(np.floor(xs.min()), 0)), int(min(np.ceil(xs.max()), w - 1))
    y0, y1 = int(max(np.floor(ys.min()), 0)), int(min(np.ceil(ys.max()), h - 1))
    d = (ys[1] - ys[2]) * (xs[0] - xs[2]) + (xs[2] - xs[1]) * (ys[0] - ys[2])
    if x1 < x0 or y1 < y0 or abs(d) < 1e-9:
        return None
    py, px = np.mgrid[y0:y1 + 1, x0:x1 + 1]
    cx, cy = px + 0.5, py + 0.5
    a = ((ys[1] - ys[2]) * (cx - xs[2]) + (xs[2] - xs[1]) * (cy - ys[2])) / d
    b = ((ys[2] - ys[0]) * (cx - xs[2]) + (xs[0] - xs[2]) * (cy - ys[2])) / d
    c = 1 - a - b
    inside = np.minimum(np.minimum(a, b), c) >= -0.02
    return px[inside], py[inside], a[inside], b[inside], c[inside]


def _front_depth(v, tris):
    """The head as the front view sees it: per guide pixel, the depth (our z; he faces -Z, so
    smaller is nearer) of the nearest surface. Loosened to the farthest of each 3x3 block, so a
    point a pixel off an edge still counts as seen."""
    z = np.full((GUIDE_PX, GUIDE_PX), np.inf)
    for tri in tris:
        src = np.array([_front_uv(v[i]) for i in tri]) * GUIDE_PX
        r = _raster(src[:, 0], src[:, 1], GUIDE_PX, GUIDE_PX)
        if r is None:
            continue
        px, py, a, b, c = r
        depth = a * v[tri[0]][2] + b * v[tri[1]][2] + c * v[tri[2]][2]
        np.minimum.at(z, (py, px), depth)
    padded = np.pad(z, 1, mode="edge")
    loose = np.max([padded[1 + dy:GUIDE_PX + 1 + dy, 1 + dx:GUIDE_PX + 1 + dx]
                    for dy in (-1, 0, 1) for dx in (-1, 0, 1)], axis=0)
    return np.where(np.isfinite(loose), loose, z)


def _fill_hidden(out, known, alpha, steps=24):
    """Texels the front view couldn't see (behind the nose, under the brow and chin) take the
    colour of the seen texels next to them, spreading a texel at a time."""
    out, known = out.copy(), known.copy()
    want = alpha > 0
    for _ in range(steps):
        todo = want & ~known
        if not todo.any():
            break
        acc = np.zeros_like(out)
        n = np.zeros(known.shape)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            k = np.roll(known, (dy, dx), axis=(0, 1))
            acc += np.roll(out, (dy, dx), axis=(0, 1)) * k[:, :, None]
            n += k
        grow = todo & (n > 0)
        out[grow] = acc[grow] / n[grow][:, None]
        known = known | grow
    return out


def _despeckle(idx, keep, passes=2):
    """A texel whose colour none of its four neighbours share takes the commonest colour of its
    eight neighbours (only where the portrait shows): broad blocks, not salt and pepper."""
    idx = idx.copy()
    h, w = idx.shape
    for _ in range(passes):
        pad = np.pad(idx, 1, mode="edge")
        same = np.zeros((h, w), dtype=bool)
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            same |= pad[1 + dy:h + 1 + dy, 1 + dx:w + 1 + dx] == idx
        lone = keep & ~same
        if not lone.any():
            break
        for y, x in zip(*np.where(lone)):
            nb = [pad[y + 1 + dy, x + 1 + dx] for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dy or dx]
            vals, counts = np.unique(nb, return_counts=True)
            idx[y, x] = vals[np.argmax(counts)]
    return idx


def project(person, head_faces, head_uv, portrait_path, out_path, width=None, height=None, colours=None):
    """Rasterise the portrait into the face layout, triangle by triangle. A point takes the
    portrait's colour if the front view really saw it (a depth test against the head seen from
    the front), and the portrait fades out only as the head turns away sideways (smooth normals,
    their angle round the head), so the sides of the nose, the eye sockets and what's under the
    nose and moustache are painted too. What the front view couldn't see (behind the nose, under
    the brow) is filled from the seen texels next to it. Pure numpy: no bake needed, and exact."""
    from PIL import Image  # only here: the rest of the pipeline doesn't need PIL
    final_w, final_h = width or FACE_W, height or FACE_H
    colours = colours or FACE_COLOURS
    width, height = final_w * SUPERSAMPLE, final_h * SUPERSAMPLE
    img = np.asarray(Image.open(portrait_path).convert("RGB").resize((GUIDE_PX, GUIDE_PX)), dtype=float) / 255.0
    out = np.zeros((height, width, 3))
    alpha = np.zeros((height, width))
    seen = np.zeros((height, width), dtype=bool)
    v = person.v
    normals = getattr(person, "normals", None)
    tris = list(_triangles(head_faces))
    zfront = _front_depth(v, tris)
    for tri in tris:
        uv = np.array([head_uv(v[i]) for i in tri])
        if uv[:, 0].max() - uv[:, 0].min() > 0.12:
            continue  # across the seam, or smeared round the axis under the chin
        src = np.array([_front_uv(v[i]) for i in tri])
        # How square to the front each corner is, round the head only (toward -Z, the viewer):
        # 1 straight ahead, 0 side-on. Tipped up or down (under the nose, the moustache) still
        # counts as front; the depth test decides whether the front view saw it.
        facing = np.ones(3)
        for k, i in enumerate(tri):
            n = normals[i] if normals is not None else np.cross(v[tri[1]] - v[tri[0]], v[tri[2]] - v[tri[0]])
            flat = np.hypot(n[0], n[2])
            if flat > 0.3 * np.linalg.norm(n):
                facing[k] = max(0.0, -n[2] / flat)
        r = _raster(uv[:, 0] * width, uv[:, 1] * height, width, height)
        if r is None:
            continue
        px, py, a, b, c = r
        su = a * src[0, 0] + b * src[1, 0] + c * src[2, 0]
        sv = a * src[0, 1] + b * src[1, 1] + c * src[2, 1]
        ix = np.clip((su * GUIDE_PX).astype(int), 0, GUIDE_PX - 1)
        iy = np.clip((sv * GUIDE_PX).astype(int), 0, GUIDE_PX - 1)
        depth = a * v[tri[0]][2] + b * v[tri[1]][2] + c * v[tri[2]][2]
        f = a * facing[0] + b * facing[1] + c * facing[2]
        ok = depth <= zfront[iy, ix] + DEPTH_SLACK
        out[py[ok], px[ok]] = img[iy[ok], ix[ok]]
        seen[py[ok], px[ok]] = True
        # The portrait holds to ~65 degrees round the head, gone by ~78 (it smears past that).
        alpha[py, px] = np.maximum(alpha[py, px], np.clip((f - 0.2) / 0.22, 0, 1))
    out = _fill_hidden(out, seen, alpha)
    alpha[~seen & (alpha > 0) & (out.sum(2) == 0)] = 0.0
    # Down to the final size: each texel the alpha-weighted average of its block.
    s = SUPERSAMPLE
    a4 = alpha.reshape(final_h, s, final_w, s)
    wsum = a4.sum(axis=(1, 3))
    out = (out.reshape(final_h, s, final_w, s, 3) * a4[..., None]).sum(axis=(1, 3)) / np.maximum(wsum, 1e-9)[..., None]
    alpha = a4.mean(axis=(1, 3))
    # A small palette, so it stays pixel art: the portrait's own colours, clustered, lone texels
    # cleared into the blocks round them.
    pim = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8)).quantize(colors=colours, method=Image.Quantize.MEDIANCUT)
    pal = np.array(pim.getpalette()[:colours * 3], dtype=np.uint8).reshape(-1, 3)
    idx = _despeckle(np.asarray(pim), alpha > 0.5)
    rgb = pal[idx]
    rgba = np.concatenate([rgb, (alpha[:, :, None] * 255).astype(np.uint8)], axis=2)
    Image.fromarray(rgba, "RGBA").save(out_path)
    # His skin tone, from the painted cheeks, so the painted sides of the head match the front.
    cheeks = out[alpha > 0.9]
    if len(cheeks):
        lum = cheeks.mean(1)
        mid = cheeks[(lum > np.percentile(lum, 40)) & (lum < np.percentile(lum, 80))]
        person.report["skin_tone"] = [round(float(x), 3) for x in (mid.mean(0) if len(mid) else cheeks.mean(0))]
