"""The prop factory's Blender half (docs/briefs/prop-factory.md): shared by every prop script here.

    ~/bpyenv/bin/python tools/blender/props/build.py [--only=deer_head,feed_sack]

A prop script builds its parts as plain geometry (numpy, in the game's space: metres, x right, y
up, z toward the viewer, origin where its kit file puts it) and hands them to `export`, which makes
one Blender object a part (named as the kit file's `"draw": {"shape": "mesh", "part"}` asks for it),
lays UVs in metres (each face projected along its nearest axis, so the texel grid lays the world's
squares on it as on every other prop), shades it smooth or flat, and writes
assets/props/models/<id>.glb. Blender is only how the shape is made: the prop is still a kit file,
its members break and burn it.

Everything is seeded, so a re-run writes the same file.
"""
import math
import os

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
MODELS = os.path.join(ROOT, "assets", "props", "models")


class Part:
    """One part's geometry: vertices (game space) and faces (lists of vertex indices)."""

    def __init__(self, name, smooth=True):
        self.name = name
        self.smooth = smooth
        self.verts = []
        self.faces = []

    def add(self, verts, faces):
        base = len(self.verts)
        self.verts.extend([tuple(float(c) for c in v) for v in verts])
        self.faces.extend([[base + i for i in f] for f in faces])
        return self

    def merge(self, other):
        return self.add(other.verts, other.faces)


# --- Shapes ------------------------------------------------------------------------------------------

def frame_along(points):
    """A frame (tangent, side, up) at each point of a path, carried along it without twisting."""
    p = np.asarray(points, float)
    t = np.gradient(p, axis=0)
    t /= np.linalg.norm(t, axis=1, keepdims=True)
    ref = np.array([0.0, 1.0, 0.0]) if abs(t[0][1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    side = np.cross(t[0], ref)
    side /= np.linalg.norm(side)
    frames = []
    for i in range(len(p)):
        side = side - t[i] * np.dot(side, t[i])
        side /= np.linalg.norm(side)
        up = np.cross(side, t[i])
        frames.append((t[i], side, up))
    return frames


def tube(name, points, radii, sides=8, caps=(True, True), smooth=True, noise=0.0, seed=0, up_hint=None):
    """A tube along `points`, its section an ellipse (rx, ry) at each (radii: a list, or a number).

    `noise` roughens it (a share of the radius), seeded: a shaggy neck, an antler's knobs."""
    rng = np.random.default_rng(seed)
    n = len(points)
    if not isinstance(radii, (list, tuple)):
        radii = [radii] * n
    radii = [(r, r) if not isinstance(r, (list, tuple)) else r for r in radii]
    frames = frame_along(points)
    verts = []
    for i, (pt, (t, side, up)) in enumerate(zip(points, frames)):
        if up_hint is not None:
            u = np.asarray(up_hint, float)
            u = u - t * np.dot(u, t)
            if np.linalg.norm(u) > 1e-6:
                up = u / np.linalg.norm(u)
                side = np.cross(t, up)
        rx, ry = radii[i]
        for k in range(sides):
            a = 2 * math.pi * k / sides
            j = 1.0 + (rng.uniform(-noise, noise) if noise else 0.0)
            verts.append(np.asarray(pt) + side * math.cos(a) * rx * j + up * math.sin(a) * ry * j)
    faces = []
    for i in range(n - 1):
        for k in range(sides):
            a = i * sides + k
            b = i * sides + (k + 1) % sides
            faces.append([a, a + sides, b + sides, b])  # outward (anticlockwise seen from outside)
    part = Part(name, smooth)
    if caps[0]:
        verts.append(np.asarray(points[0], float))
        c = len(verts) - 1
        faces += [[c, k, (k + 1) % sides] for k in range(sides)]
    if caps[1]:
        verts.append(np.asarray(points[-1], float))
        c = len(verts) - 1
        base = (n - 1) * sides
        faces += [[c, base + (k + 1) % sides, base + k] for k in range(sides)]
    return part.add(verts, faces)


def blob(name, centre, radii, rings=6, sides=10, squash_bottom=None, noise=0.0, seed=0, smooth=True):
    """An ellipsoid (a lump, an eye, a skull's crown), roughened by `noise`; `squash_bottom` flattens
    it below that height (a sack sitting, a dropping on the ground)."""
    rng = np.random.default_rng(seed)
    c = np.asarray(centre, float)
    verts = [c + [0, -radii[1], 0]]
    for i in range(1, rings):
        phi = math.pi * i / rings - math.pi * 0.5
        for k in range(sides):
            th = 2 * math.pi * k / sides
            j = 1.0 + (rng.uniform(-noise, noise) if noise else 0.0)
            verts.append(c + np.array([math.cos(phi) * math.cos(th) * radii[0], math.sin(phi) * radii[1], math.cos(phi) * math.sin(th) * radii[2]]) * j)
    verts.append(c + [0, radii[1], 0])
    verts = [np.asarray(v, float) for v in verts]
    if squash_bottom is not None:
        for v in verts:
            if v[1] < squash_bottom:
                v[1] = squash_bottom + (v[1] - squash_bottom) * 0.08
    faces = []
    top = len(verts) - 1
    for k in range(sides):
        faces.append([0, 1 + k, 1 + (k + 1) % sides])
    for i in range(rings - 2):
        for k in range(sides):
            a = 1 + i * sides + k
            b = 1 + i * sides + (k + 1) % sides
            faces.append([a, a + sides, b + sides, b])
    last = 1 + (rings - 2) * sides
    for k in range(sides):
        faces.append([last + (k + 1) % sides, last + k, top])
    return Part(name, smooth).add(verts, faces)


def slab(name, outline, z0, z1, bevel=0.0, smooth=False):
    """A board cut to `outline` (x, y points, anticlockwise seen from +z) from z0 to z1, its front
    edge chamfered `bevel` (a plaque's)."""
    o = np.asarray(outline, float)
    n = len(o)
    centre = o.mean(axis=0)
    inner = centre + (o - centre) * (1.0 - bevel / max(1e-6, np.linalg.norm(o - centre, axis=1).mean())) if bevel else o
    verts = [(x, y, z0) for x, y in o] + [(x, y, z1 - bevel) for x, y in o] + [(x, y, z1) for x, y in inner]
    verts.append((centre[0], centre[1], z1))
    verts.append((centre[0], centre[1], z0))
    faces = []
    for k in range(n):
        a, b = k, (k + 1) % n
        faces.append([a, b, n + b, n + a])
        faces.append([n + a, n + b, 2 * n + b, 2 * n + a])
        faces.append([2 * n + a, 2 * n + b, 3 * n])
        faces.append([b, a, 3 * n + 1])
    return Part(name, smooth).add(verts, faces)


def straws(name, rng, count, area, y, length=(0.08, 0.2), thick=0.004, lift=0.05):
    """Loose straws: thin flat sticks lying about `area` (x0, z0, x1, z1) at height y."""
    part = Part(name, smooth=False)
    for _ in range(count):
        x = rng.uniform(area[0], area[2])
        z = rng.uniform(area[1], area[3])
        a = rng.uniform(0, math.pi)
        l = rng.uniform(*length)
        dy = rng.uniform(0, lift)
        d = np.array([math.cos(a) * l * 0.5, dy * 0.5, math.sin(a) * l * 0.5])
        s = np.array([-math.sin(a), 0, math.cos(a)]) * thick
        p0 = np.array([x, y, z]) - d
        p1 = np.array([x, y, z]) + d
        part.add([p0 - s, p0 + s, p1 + s, p1 - s], [[0, 1, 2, 3], [3, 2, 1, 0]])
    return part


# --- Export ------------------------------------------------------------------------------------------

def _metre_uvs(verts, faces):
    """Each face's corners projected along the face's nearest axis, in metres."""
    uvs = []
    for f in faces:
        p = np.asarray([verts[i] for i in f])
        n = np.cross(p[1] - p[0], p[2] - p[0]) if len(p) >= 3 else np.array([0, 1, 0])
        ax = int(np.argmax(np.abs(n)))
        keep = [i for i in range(3) if i != ax]
        uvs.append([(float(q[keep[0]]), float(q[keep[1]])) for q in p])
    return uvs


def export(prop_id, parts):
    """Write assets/props/models/<prop_id>.glb: one object a part, its UVs in metres."""
    import bpy

    bpy.ops.wm.read_factory_settings(use_empty=True)
    for part in parts:
        # Game space (y up, z out) to Blender's (z up, -y out), which the glTF exporter turns back.
        verts = [(x, -z, y) for x, y, z in part.verts]
        mesh = bpy.data.meshes.new(part.name)
        mesh.from_pydata(verts, [], part.faces)
        uv = mesh.uv_layers.new(name="UVMap")
        flat = [c for face in _metre_uvs(part.verts, part.faces) for c in face]
        for loop, value in zip(uv.data, flat):
            loop.uv = value
        mesh.validate()
        for poly in mesh.polygons:
            poly.use_smooth = part.smooth
        obj = bpy.data.objects.new(part.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
    os.makedirs(MODELS, exist_ok=True)
    path = os.path.join(MODELS, prop_id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)
    tris = sum(len(f) - 2 for p in parts for f in p.faces)
    print("%s: %d parts, %d triangles -> %s" % (prop_id, len(parts), tris, os.path.relpath(path, ROOT)))
    return path
