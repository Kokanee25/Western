"""Salt Creek's horse: a bay at the rail, built, painted, rigged and given an idle loop, by script,
to Sean's pictures of him (docs/concept/horse/: both sides, front and back; 2026-10-24).

    ~/bpyenv/bin/python tools/blender/horse.py --shape=GLB [--out=assets/creatures/horse] [--blend]
    ~/bpyenv/bin/python tools/blender/horse.py [--paint=pictures|rules]      (the sculpt, no Rodin)

--shape: Rodin's model from Sean's approved pictures (the Character Studio's inputs/horse/shape.glb,
2026-10-24), the game's horse since; horse_rodin.py turns, scales and measures it, its own paint is
the coat. Without it, the sculpt below.
    blender -b --python tools/blender/horse.py -- [...]

(the pip `bpy` as tools/blender/make_people.py uses it: `python3.11 -m venv ~/bpyenv &&
~/bpyenv/bin/pip install bpy==5.0.1 numpy pillow scikit-image scipy`). No paid calls, no
downloads: every step is code, and it's repeatable (the sculpt is cached under build/horse/ by a hash
of horse_shape.py, horse_ref.py and the pictures).

1. The sculpt (horse_shape.py): a signed distance field meshed at 1 cm, the horse and his tail's
   hair (~185k triangles), the source the textures are baked from. His body, neck and head are
   lofted from Sean's side outline (horse_ref.py reads it off the picture), his legs, ears and
   tail placed where the pictures have them.
2. Cut down to the game's budget (Blender's collapse decimation, symmetric): the coat ~2,900
   triangles (body and tail), and a ~480-triangle LOD for far off.
3. UVs laid out by parts (horse_uv.py), then baked with Cycles: where each texel is on him, which
   way it faces (the sculpt's), how tucked in it is; painted by projecting Sean's four pictures
   onto him (horse_paint.projected; --paint=rules paints by rule instead) into `horse_coat.png`
   (1024²); the far coat's `horse_coat_lod.png` (256²) baked from it.
4. Tack, each its own mesh so it can come off: saddle (skirts, seat, horn, fenders, wooden
   stirrups, cinch), blanket, bridle (headstall, browband, throatlatch, noseband, bit, conchos),
   reins (over his neck, as a ridden horse's lie), saddlebags; laid on the sculpt's surface,
   painted by rule into `horse_tack.png` (512²). A tack LOD for far off.
5. A skeleton of 39 bones (spine, neck, head, ears, four legs to the hooves, a six-bone tail),
   skin weights by distance to each bone kept to its own part (ears, tail, each leg's side),
   smoothed over the mesh; the tack takes its weights from the bones it rides on.
6. The idle (horse_idle.py, 12 s at 15 fps): weight shifts between resting hinds, tail swishes,
   ear flicks, a head dip; hooves planted.
7. Written to `<out>/horse.glb` (the armature "Horse" with meshes coat, coat_lod, saddle, blanket,
   bridle, reins, saddlebags, tack_lod; action "idle"), the PNGs and `horse.json` (counts, bones,
   the bit's rings, the toes, the collision capsules, for the game and the tests).
"""
import hashlib
import json
import math
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import horse_idle  # noqa: E402
import horse_paint  # noqa: E402
import horse_shape as hs  # noqa: E402
import horse_uv  # noqa: E402

import bpy  # noqa: E402
import bmesh  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402
from mathutils.bvhtree import BVHTree  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CACHE = os.path.join(ROOT, "build", "horse")

COAT_TRIS = 2600
TAIL_TRIS = 300
LOD_TRIS = 480
TACK_LOD_TRIS = 90
COAT_SIZE = 1024
TACK_SIZE = 512
LOD_SIZE = 256

# How the coat is painted: "pictures" projects Sean's (docs/concept/horse/, horse_paint.projected),
# "rules" paints it by rule (horse_paint.coat). --paint=rules|pictures.
PAINT = "pictures"
SCULPT = {}
# --shape=GLB: Rodin's model of him (the Character Studio's inputs/horse/shape.glb, from the
# pictures Sean approved) instead of the sculpt; its image and tail when used.
RODIN = {}

# Where the bake's positions are packed into 0..1 (a box round the horse and his tack).
POS_LO = np.array([-1.8, -0.5, -0.05])
POS_HI = np.array([1.15, 0.5, 2.3])


def log(*a):
    print("[horse %6.1fs]" % (time.time() - T0), *a, flush=True)


# --- the sculpt ---------------------------------------------------------------------------------


def sculpt():
    """The sculpt's meshes, cached by the shape module's hash: {"body": (v, f), "tail": (v, f)}."""
    src = open(os.path.join(os.path.dirname(__file__), "horse_shape.py"), "rb").read()
    import horse_ref
    src += open(os.path.join(os.path.dirname(__file__), "horse_ref.py"), "rb").read()
    key = hashlib.sha1(src).hexdigest()[:12] + horse_ref.key()
    path = os.path.join(CACHE, "sculpt_%s.npz" % key)
    if os.path.exists(path):
        z = np.load(path)
        return {"body": (z["bv"], z["bf"]), "tail": (z["tv"], z["tf"])}
    log("sculpting (1 cm)")
    bv, bf = hs.grid_mesh(hs.body_sdf, *hs.BODY_BOX, 0.01)
    tv, tf = hs.grid_mesh(hs.tail_sdf, *hs.TAIL_BOX, 0.01)
    np.savez_compressed(path, bv=bv, bf=bf, tv=tv, tf=tf)
    return {"body": (bv, bf), "tail": (tv, tf)}


# --- Blender helpers ----------------------------------------------------------------------------


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")


def mesh_object(name, verts, faces, smooth=True):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(map(float, v)) for v in verts], [], [tuple(map(int, f)) for f in faces])
    me.update()
    if smooth:
        me.shade_smooth()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def decimate(obj, target, symmetric=True):
    """Collapse decimation to about `target` triangles, in passes (one pass from the sculpt's
    150k to a few hundred stops short)."""
    for _ in range(6):
        have = tris(obj)
        if have <= target * 1.05:
            return
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = max(target / have, 0.08)
        mod.use_collapse_triangulate = True
        if symmetric:
            mod.use_symmetry = True
            mod.symmetry_axis = "Y"
        activate(obj)
        bpy.ops.object.modifier_apply(modifier="decimate")
        obj.data.shade_smooth()  # (the modifier leaves its new faces flat)
        if tris(obj) >= have * 0.98:
            return


def copy_object(obj, name):
    o = obj.copy()
    o.data = obj.data.copy()
    o.name = name
    o.data.name = name
    bpy.context.scene.collection.objects.link(o)
    return o


def uv_unwrap(obj, margin):
    activate(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin, area_weight=0.6)
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(margin=margin, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def _bake_material(obj, img, emit=None):
    mat = bpy.data.materials.new(obj.name + "_bake")
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    node = nodes.new("ShaderNodeTexImage")
    node.image = img
    nodes.active = node
    if emit is not None:
        em = nodes.new("ShaderNodeEmission")
        links.new(emit(nodes, links), em.inputs["Color"])
        links.new(em.outputs["Emission"], nodes["Material Output"].inputs["Surface"])
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


def bake(obj, size, kind, source=None, emit=None, source_emit=None, samples=32, ao_distance=0.25):
    """One pass baked into obj's UVs as a (size, size, 3) float array, rows top-down. With `source`,
    selected-to-active from it (its emission from `source_emit` for an EMIT pass)."""
    img = bpy.data.images.new("%s_%s" % (obj.name, kind), size, size, float_buffer=True)
    img.colorspace_settings.name = "Non-Color"
    _bake_material(obj, img, emit)
    scene = bpy.context.scene
    scene.cycles.samples = samples
    scene.world.light_settings.distance = ao_distance
    scene.render.bake.margin = 6
    scene.render.bake.use_clear = True
    kw = {}
    if source is not None:
        if source_emit is not None or not source.data.materials:
            source.data.materials.clear()
            m = bpy.data.materials.new(source.name + "_src")
            m.use_nodes = True
            if source_emit is not None:
                em = m.node_tree.nodes.new("ShaderNodeEmission")
                m.node_tree.links.new(source_emit(m.node_tree.nodes, m.node_tree.links), em.inputs["Color"])
                m.node_tree.links.new(em.outputs["Emission"], m.node_tree.nodes["Material Output"].inputs["Surface"])
            source.data.materials.append(m)
        bpy.ops.object.select_all(action="DESELECT")
        source.select_set(True)
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        kw = dict(use_selected_to_active=True, cage_extrusion=0.03, max_ray_distance=0.08)
    else:
        activate(obj)
    if kind == "NORMAL":
        kw["normal_space"] = "OBJECT"
    bpy.ops.object.bake(type=kind, **kw)
    out = np.array(img.pixels[:], dtype=np.float32).reshape(size, size, 4)[::-1, :, :3].copy()
    obj.data.materials.clear()
    bpy.data.images.remove(img)
    return out


def _position_socket(nodes, links):
    geo = nodes.new("ShaderNodeNewGeometry")
    sub = nodes.new("ShaderNodeVectorMath")
    sub.operation = "SUBTRACT"
    sub.inputs[1].default_value = tuple(POS_LO)
    div = nodes.new("ShaderNodeVectorMath")
    div.operation = "DIVIDE"
    div.inputs[1].default_value = tuple(POS_HI - POS_LO)
    links.new(geo.outputs["Position"], sub.inputs[0])
    links.new(sub.outputs["Vector"], div.inputs[0])
    return div.outputs["Vector"]


def _attribute_socket(name):
    def f(nodes, links):
        a = nodes.new("ShaderNodeAttribute")
        a.attribute_name = name
        return a.outputs["Color"]
    return f


def _pointiness(nodes, links):
    return nodes.new("ShaderNodeNewGeometry").outputs["Pointiness"]


def set_point_colour(obj, name, value):
    attr = obj.data.color_attributes.new(name, "FLOAT_COLOR", "POINT")
    for d in attr.data:
        d.color = (value, value, value, 1.0)


def coverage(obj, size):
    """Which texels some face covers (before the bake's margin), as a bool (size, size) array."""
    from PIL import Image, ImageDraw
    img = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(img)
    uv = obj.data.uv_layers.active.data
    for poly in obj.data.polygons:
        pts = [(uv[li].uv[0] * size, (1.0 - uv[li].uv[1]) * size) for li in poly.loop_indices]
        draw.polygon(pts, fill=255)
    return np.array(img) > 0


def save_png(arr, path):
    from PIL import Image
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8)).save(path, optimize=True)


# --- the coat -----------------------------------------------------------------------------------


def build_coat(parts):
    bv, bf = parts["body"]
    tv, tf = parts["tail"]
    body_hi = mesh_object("body_hi", bv, bf)
    tail_hi = mesh_object("tail_hi", tv, tf)
    set_point_colour(body_hi, "part", 0.0)
    set_point_colour(tail_hi, "part", 1.0)
    body = copy_object(body_hi, "coat_body")
    decimate(body, COAT_TRIS)
    tail = copy_object(tail_hi, "coat_tail")
    decimate(tail, TAIL_TRIS)
    # One mesh: the tail's hair is its own island, moved by the tail's bones.
    activate(body)
    tail.select_set(True)
    bpy.ops.object.join()
    coat = body
    coat.name = coat.data.name = "coat"
    # The sculpt as one source to bake from.
    activate(body_hi)
    tail_hi.select_set(True)
    bpy.ops.object.join()
    hi = body_hi
    hi.name = "coat_hi"
    log("coat", tris(coat), "triangles; sculpt", tris(hi))
    return coat, hi


def build_coat_rodin(path):
    """Rodin's model as the source (turned, scaled and measured by horse_rodin.py), the coat cut
    down from it."""
    import horse_rodin
    hi, image = horse_rodin.load(bpy, path)
    tail = horse_rodin.measure(hi, horse_rodin.vertex_colours(hi, image))
    attr = hi.data.color_attributes.new("part", "FLOAT_COLOR", "POINT")
    for i, d in enumerate(attr.data):
        x = 1.0 if tail[i] else 0.0
        d.color = (x, x, x, 1.0)
    RODIN.update(image=image)
    coat = copy_object(hi, "coat")
    coat.data.materials.clear()
    decimate(coat, COAT_TRIS + TAIL_TRIS)
    log("coat", tris(coat), "triangles from Rodin's", tris(hi), "; tail", int(tail.sum()), "of", len(tail), "points")
    return coat, hi


def coat_uvs(coat, size=COAT_SIZE):
    """The coat laid out by parts (horse_uv.py), not smart-projected."""
    me = coat.data
    verts = [v.co[:] for v in me.vertices]
    faces = [list(p.vertices) for p in me.polygons]
    normals = [p.normal[:] for p in me.polygons]
    part_attr = me.color_attributes["part"].data
    parts = [float(np.mean([part_attr[v].color[0] for v in p.vertices])) for p in me.polygons]
    uvs, counts, density = horse_uv.layout(verts, faces, normals, parts, size=size, margin_px=max(4, size // 128))
    layer = me.uv_layers.new(name="UVMap")
    for p, uv in zip(me.polygons, uvs):
        for k, li in enumerate(p.loop_indices):
            layer.data[li].uv = (float(uv[k][0]), float(uv[k][1]))
    log("coat UVs:", counts, "%.0f texels a metre" % density)
    return density


def paint_coat(coat, hi, out_png):
    density = coat_uvs(coat)
    size = COAT_SIZE
    mask = coverage(coat, size)
    if RODIN.get("image") is not None:
        # Rodin's own paint (made from Sean's approved pictures), baked into the coat's layout:
        # the men's way (their models' own texture).
        img = RODIN["image"]
        img.colorspace_settings.name = "Non-Color"   # its values through as they are

        def texture(nodes, links):
            t = nodes.new("ShaderNodeTexImage")
            t.image = img
            return t.outputs["Color"]
        col = bake(coat, size, "EMIT", source=hi, source_emit=texture, samples=4)
        log("coat baked from Rodin's paint")
        col[~mask] = col[mask].mean(axis=0)
        save_png(col, out_png)
        return density
    pos = bake(coat, size, "EMIT", emit=_position_socket, samples=1) * (POS_HI - POS_LO) + POS_LO
    part = bake(coat, size, "EMIT", emit=_attribute_socket("part"), samples=1)[..., 0]
    nrm = bake(coat, size, "NORMAL", source=hi) * 2.0 - 1.0
    ao = bake(coat, size, "AO", source=hi, samples=48)[..., 0]
    log("coat baked")
    if PAINT == "pictures":
        img = horse_paint.projected(pos, nrm, ao, part, mask, np.concatenate([v for v, _f in SCULPT.values()]))
    else:
        img = horse_paint.coat(pos, nrm, ao, part, mask)
    save_png(img, out_png)
    return density


def make_lod(coat, hi, coat_png, out_png):
    lod = copy_object(hi, "coat_lod")
    decimate(lod, LOD_TRIS)
    coat_uvs(lod, LOD_SIZE)
    img = bpy.data.images.load(coat_png)
    img.colorspace_settings.name = "Non-Color"

    def texture(nodes, links):
        t = nodes.new("ShaderNodeTexImage")
        t.image = img
        t.interpolation = "Closest"
        return t.outputs["Color"]

    col = bake(lod, LOD_SIZE, "EMIT", source=coat, source_emit=texture, samples=1)
    save_png(col, out_png)
    return lod


# --- tack ---------------------------------------------------------------------------------------


class Surface:
    """The sculpt's surface, for laying tack on it."""

    def __init__(self, verts, faces):
        self.bvh = BVHTree.FromPolygons([Vector(v) for v in verts], [tuple(map(int, f)) for f in faces])

    def near(self, p, off):
        loc, nor, _i, _d = self.bvh.find_nearest(Vector(p))
        return np.array(loc) + np.array(nor) * off, np.array(nor)

    def cast(self, origin, direction, off):
        loc, nor, _i, _d = self.bvh.ray_cast(Vector(origin), Vector(direction).normalized())
        if loc is None:
            return None, None
        return np.array(loc) + np.array(nor) * off, np.array(nor)

    def outside(self, p, clear):
        """`p` pushed out of the body to `clear` metres off it."""
        loc, nor, _i, d = self.bvh.find_nearest(Vector(p))
        q = np.asarray(p, float)
        if (q - np.array(loc)) @ np.array(nor) < clear:
            return np.array(loc) + np.array(nor) * clear
        return q


class Builder:
    """Triangles with a paint id per vertex and a piece per face."""

    def __init__(self):
        self.v, self.f, self.paint, self.piece = [], [], [], []

    def add(self, verts, faces, paint, piece):
        base = len(self.v)
        self.v.extend([tuple(map(float, x)) for x in verts])
        self.paint.extend([paint] * len(verts))
        for f in faces:
            self.f.append(tuple(base + i for i in f))
            self.piece.append(piece)

    def grid(self, rows, paint, piece, thick=0.0, normals=None, closed=False):
        """A sheet through rows of points (each row a list along the sheet), thickened inwards by
        `thick` along `normals` (same shape) with its rim closed."""
        R = np.asarray(rows, float)
        nr, nc = R.shape[:2]
        layers = [R] if thick <= 0.0 else [R, R - np.asarray(normals, float) * thick]
        verts = np.concatenate([L.reshape(-1, 3) for L in layers])
        faces = []
        cols = nc if closed else nc - 1
        for li, L in enumerate(layers):
            o = li * nr * nc
            for i in range(nr - 1):
                for j in range(cols):
                    a, b = o + i * nc + j, o + i * nc + (j + 1) % nc
                    c, d = a + nc, b + nc
                    faces += [(a, b, d), (a, d, c)] if li == 0 else [(a, d, b), (a, c, d)]
        if thick > 0.0:
            o = nr * nc
            ring = [(0, j) for j in range(nc)] + [(i, nc - 1) for i in range(1, nr)] + \
                [(nr - 1, j) for j in range(nc - 2, -1, -1)] + [(i, 0) for i in range(nr - 2, 0, -1)]
            if closed:
                ring = None
            if ring:
                for k in range(len(ring)):
                    i0, j0 = ring[k]
                    i1, j1 = ring[(k + 1) % len(ring)]
                    a, b = i0 * nc + j0, i1 * nc + j1
                    faces += [(a, o + b, b), (a, o + a, o + b)]
        self.add(verts, faces, paint, piece)

    def strap(self, path, ups, width, thick, paint, piece):
        """A flat strap along `path` lying on its `ups` (surface normals)."""
        P = np.asarray(path, float)
        U = np.asarray(ups, float)
        verts = []
        n = len(P)
        for i in range(n):
            t = P[min(i + 1, n - 1)] - P[max(i - 1, 0)]
            t /= max(np.linalg.norm(t), 1e-9)
            side = np.cross(t, U[i])
            side /= max(np.linalg.norm(side), 1e-9)
            up = np.cross(side, t)
            for sx, sy in ((-1, 0), (1, 0), (1, 1), (-1, 1)):
                verts.append(P[i] + side * sx * width * 0.5 + up * sy * thick)
        faces = []
        for i in range(n - 1):
            for k in range(4):
                a, b = i * 4 + k, i * 4 + (k + 1) % 4
                faces += [(a, b, b + 4), (a, b + 4, a + 4)]
        faces += [(0, 2, 1), (0, 3, 2)]
        e = (n - 1) * 4
        faces += [(e, e + 1, e + 2), (e, e + 2, e + 3)]
        self.add(verts, faces, paint, piece)

    def lathe(self, profile, centre, axis, sides, paint, piece):
        """A turned shape: profile [(radius, height)] round `axis` through `centre`."""
        a = np.asarray(axis, float)
        a /= np.linalg.norm(a)
        u = np.cross(a, [0.0, 0.0, 1.0] if abs(a[2]) < 0.9 else [1.0, 0.0, 0.0])
        u /= np.linalg.norm(u)
        w = np.cross(a, u)
        verts = []
        for r, h in profile:
            for k in range(sides):
                ang = 2 * math.pi * k / sides
                verts.append(np.asarray(centre) + a * h + (u * math.cos(ang) + w * math.sin(ang)) * r)
        faces = []
        for i in range(len(profile) - 1):
            for k in range(sides):
                p0, p1 = i * sides + k, i * sides + (k + 1) % sides
                faces += [(p0, p1, p1 + sides), (p0, p1 + sides, p0 + sides)]
        top = len(profile) - 1
        for k in range(1, sides - 1):
            faces.append((top * sides, top * sides + k, top * sides + k + 1))
            faces.append((0, k + 1, k))
        self.add(verts, faces, paint, piece)

    def ring(self, centre, axis, radius, tube, paint, piece, seg=8, sides=4):
        """A torus (a bit ring, a cinch ring)."""
        a = np.asarray(axis, float)
        a /= np.linalg.norm(a)
        u = np.cross(a, [0.0, 0.0, 1.0] if abs(a[2]) < 0.9 else [1.0, 0.0, 0.0])
        u /= np.linalg.norm(u)
        w = np.cross(a, u)
        verts = []
        for i in range(seg):
            ang = 2 * math.pi * i / seg
            d = u * math.cos(ang) + w * math.sin(ang)
            c = np.asarray(centre) + d * radius
            for k in range(sides):
                b = 2 * math.pi * k / sides
                verts.append(c + (d * math.cos(b) + a * math.sin(b)) * tube)
        faces = []
        for i in range(seg):
            for k in range(sides):
                p0 = i * sides + k
                p1 = i * sides + (k + 1) % sides
                q0 = ((i + 1) % seg) * sides + k
                q1 = ((i + 1) % seg) * sides + (k + 1) % sides
                faces += [(p0, q0, q1), (p0, q1, p1)]
        self.add(verts, faces, paint, piece)

    def blob(self, centre, half, frame, paint, piece, nu=8, nv=6, round_=0.35):
        """A rounded box (a saddlebag): a sphere pushed out towards its box."""
        verts = []
        for i in range(nv + 1):
            th = math.pi * i / nv
            for j in range(nu):
                ph = 2 * math.pi * j / nu
                d = np.array([math.sin(th) * math.cos(ph), math.sin(th) * math.sin(ph), math.cos(th)])
                d = np.sign(d) * np.abs(d) ** round_
                verts.append(np.asarray(centre) + np.asarray(frame).T @ (d * np.asarray(half)))
        faces = []
        for i in range(nv):
            for j in range(nu):
                a, b = i * nu + j, i * nu + (j + 1) % nu
                faces += [(a, b + nu, b), (a, a + nu, b + nu)]
        self.add(verts, faces, paint, piece)

    def object(self, name):
        obj = mesh_object(name, self.v, self.f, smooth=True)
        attr = obj.data.color_attributes.new("paint", "FLOAT_COLOR", "POINT")
        for i, d in enumerate(attr.data):
            v = self.paint[i] / 16.0
            d.color = (v, v, v, 1.0)
        layer = obj.data.attributes.new("piece", "INT", "FACE")
        for i, d in enumerate(layer.data):
            d.value = self.piece[i]
        return obj


# Where the saddle sits along him: laid out on the first horse, whose withers were 0.15 m further
# forward than Sean's horse's (docs/concept/horse/).
DX = 0.14


# How far behind that the saddle sits (Sean, 2026-10-24: "too close to his head"): the tree's front
# a hand behind the withers, the cinch a hand behind the elbow.
SADDLE_BACK = 0.12


def _dx():
    """The saddle's place along him: laid out on a horse with his withers at x = -0.45, then slid
    SADDLE_BACK towards his tail."""
    return hs.WITHERS[0] + 0.45 + SADDLE_BACK

TACK_PIECES = ["saddle", "blanket", "bridle", "reins", "saddlebags"]
P_SADDLE, P_BLANKET, P_BRIDLE, P_REINS, P_BAGS = range(5)


def _densify(points, k):
    out = []
    for i in range(len(points) - 1):
        a, b = np.asarray(points[i], float), np.asarray(points[i + 1], float)
        for s in range(k):
            out.append(a + (b - a) * s / k)
    out.append(np.asarray(points[-1], float))
    return out


def _on_surface(surf, points, off, k=3):
    path, ups = [], []
    for p in _densify(points, k):
        q, n = surf.near(p, off)
        path.append(q)
        ups.append(n)
    return path, ups


def _wrap(surf, x, angles, off, centre_z=1.15):
    """Points round the body at x, cast from inside out at each angle (radians from straight up,
    towards +Y)."""
    pts, nrm = [], []
    for a in angles:
        q, n = surf.cast((x, 0.0, centre_z), (0.0, math.sin(a), math.cos(a)), off)
        pts.append(q)
        nrm.append(n)
    return pts, nrm


def build_tack(surf):
    DX = _dx()  # noqa: N806 (the saddle's place along him, for this horse)
    B = Builder()
    # The blanket: felt over the back, a hand out past the saddle front and back, hanging to the
    # barrel's sides.
    xs = np.linspace(-0.53 + DX, 0.17 + DX, 7)
    ang = np.radians(np.linspace(-98, 98, 11))
    rows, nrms = zip(*[_wrap(surf, x, ang, 0.012) for x in xs])
    B.grid(rows, 1, P_BLANKET, 0.01, nrms)
    # The saddle's skirts: leather over the blanket.
    xs = np.linspace(-0.43 + DX, 0.1 + DX, 6)
    ang = np.radians(np.linspace(-90, 90, 9))
    rows, nrms = zip(*[_wrap(surf, x, ang, 0.03) for x in xs])
    B.grid(rows, 2, P_SADDLE, 0.012, nrms)
    # The seat and tree: the swell in front with its horn, dished, the cantle behind.
    prof_x = [x + DX for x in (-0.41, -0.37, -0.31, -0.22, -0.12, -0.03, 0.03, 0.07, 0.095)]
    prof_z = [1.66, 1.725, 1.715, 1.655, 1.64, 1.655, 1.705, 1.75, 1.735]
    prof_w = [0.13, 0.155, 0.16, 0.17, 0.175, 0.175, 0.17, 0.16, 0.13]
    rings = []
    for x, zt, w in zip(prof_x, prof_z, prof_w):
        us = np.linspace(-1.0, 1.0, 9)
        top, bottom = [], []
        for u in us:
            y = u * w
            q, _n = surf.cast((x, y, 2.6), (0, 0, -1), 0.04)
            zb = q[2] if q is not None else 1.5
            zc = zb + (zt - zb) * (1.0 - u * u) ** 0.35
            top.append((x, y * (1.0 + 0.08 * (1 - u * u)), max(zc, zb + 0.015)))
            bottom.append((x, y, zb))
        ring = top + bottom[::-1][1:-1]
        rings.append(ring)
    R = np.asarray(rings)
    n = R.shape[1]
    verts = list(R.reshape(-1, 3))
    faces = []
    for i in range(len(rings) - 1):
        for j in range(n):
            a, b = i * n + j, i * n + (j + 1) % n
            faces += [(a, b + n, b), (a, a + n, b + n)]
    last = (len(rings) - 1) * n
    for k in range(1, n - 1):
        faces.append((0, k, k + 1))
        faces.append((last, last + k + 1, last + k))
    B.add(verts, faces, 2, P_SADDLE)
    # The horn on the swell.
    B.lathe([(0.024, 0.0), (0.022, 0.07), (0.05, 0.08), (0.05, 0.095), (0.0, 0.1)], (-0.375 + DX, 0.0, 1.69), (0.05, 0, 1), 8, 3, P_SADDLE)
    # Fenders hanging from under the seat to the stirrups; the stirrups (wood, leather-bound).
    for s in (-1.0, 1.0):
        zs = np.linspace(1.5, 0.98, 5)
        fx = [-0.23 + DX, -0.17 + DX, -0.11 + DX]
        rows, nr = [], []
        ymax = 0.0
        for z in zs:
            row, rn = [], []
            for x in fx:
                width = 1.0 + 1.6 * (1.5 - z)  # narrow under the seat, wide at the stirrup
                xx = -0.17 + DX + (x + 0.17 - DX) * width
                q, nn = surf.cast((xx, 0.0, z), (0, s, 0), 0.05)
                yy = abs(q[1]) if q is not None else 0.3
                ymax = max(ymax, yy)
                row.append((xx, s * max(yy, ymax), z))
                rn.append((0.0, s, 0.0))
            rows.append(row)
            nr.append(rn)
        if s < 0:
            rows = [r[::-1] for r in rows]
            nr = [r[::-1] for r in nr]
        B.grid(rows, 2, P_SADDLE, 0.008, nr)
        sy = s * (ymax + 0.012)
        loop = [(x + DX, sy, z) for x, z in ((-0.24, 0.99), (-0.25, 0.92), (-0.23, 0.88), (-0.11, 0.88), (-0.09, 0.92), (-0.1, 0.99))]
        B.strap(_densify(loop, 1), [(0.0, s, 0.0)] * len(loop), 0.06, 0.02, 4, P_SADDLE)
        B.strap([(-0.235 + DX, sy, 0.885), (-0.105 + DX, sy, 0.885)], [(0.0, 0.0, 1.0)] * 2, 0.08, 0.02, 4, P_SADDLE)
    # The cinch: round the girth behind the elbows, its rings at the skirts' edge.
    ang = np.radians(np.linspace(92, 268, 11))
    path, ups = _wrap(surf, -0.3 + DX, ang, 0.014)
    B.strap(path, ups, 0.075, 0.01, 5, P_SADDLE)
    for s in (-1.0, 1.0):
        q, nn = surf.cast((-0.3 + DX, 0.0, 1.15), (0.0, s * math.sin(math.radians(88)), math.cos(math.radians(88))), 0.04)
        B.ring(q, (0.0, s, 0.0), 0.03, 0.006, 8, P_SADDLE, seg=8, sides=4)

    # Saddlebags behind the cantle: two leather bags on a strap over his loins.
    bx = 0.3 + DX
    q_top, _n = surf.cast((bx, 0.0, 2.6), (0, 0, -1), 0.012)
    strap = [(bx, -0.2, 1.38), (bx, -0.12, q_top[2] - 0.02), (bx, 0.0, q_top[2]), (bx, 0.12, q_top[2] - 0.02), (bx, 0.2, 1.38)]
    path, ups = _on_surface(surf, strap, 0.015, 3)
    B.strap(path, ups, 0.12, 0.008, 6, P_BAGS)
    for s in (-1.0, 1.0):
        q, nn = surf.cast((bx, 0.0, 1.27), (0, s, 0.15), 0.0)
        nn = nn / np.linalg.norm(nn)
        side = np.array([1.0, 0.0, 0.0])
        up = np.cross(nn, side) * s
        up = up / np.linalg.norm(up)
        if up[2] < 0:
            up = -up
        centre = q + nn * 0.055
        frame = np.array([side, nn, up])  # rows: the bag's x, depth, height
        B.blob(centre, (0.14, 0.05, 0.11), frame, 6, P_BAGS)
        flap_c = centre + up * 0.085 + nn * 0.02
        B.blob(flap_c, (0.145, 0.035, 0.045), frame, 6, P_BAGS, nu=8, nv=4)
        B.blob(centre + nn * 0.052 + up * 0.03, (0.012, 0.004, 0.03), frame, 9, P_BAGS, nu=4, nv=2)

    # The headstall: crown over the poll behind the ears, cheeks down to the bit, a browband,
    # a throatlatch round behind the jowl, a noseband; the bit's rings and silver conchos.
    def hp(along, face=0.0, side=0.0):
        # The bridle was laid on a 0.664 m head; Sean's horse's is shorter.
        return hs._head_point(along * hs.HEAD_LEN / 0.664, face, side)

    bit = {s: hp(0.55, -0.05, s * 0.07) for s in (-1.0, 1.0)}
    crown = [hp(0.52, -0.03, -0.08), hp(0.4, -0.0, -0.09), hp(0.26, -0.01, -0.1), hp(0.1, -0.03, -0.1),
             hp(0.03, -0.04, -0.075), hp(-0.03, -0.035, 0.0), hp(0.03, -0.04, 0.075), hp(0.1, -0.03, 0.1),
             hp(0.26, -0.01, 0.1), hp(0.4, 0.0, 0.09), hp(0.52, -0.03, 0.08)]
    path, ups = _on_surface(surf, crown, 0.007, 2)
    B.strap(path, ups, 0.024, 0.005, 7, P_BRIDLE)
    brow = [hp(0.06, -0.02, -0.095), hp(0.06, 0.05, -0.06), hp(0.065, 0.08, 0.0), hp(0.06, 0.05, 0.06), hp(0.06, -0.02, 0.095)]
    path, ups = _on_surface(surf, brow, 0.009, 2)
    B.strap(path, ups, 0.02, 0.005, 7, P_BRIDLE)
    throat = [hp(0.06, -0.05, -0.09), hp(0.12, -0.14, -0.08), hp(0.15, -0.2, -0.04), hp(0.15, -0.22, 0.0),
              hp(0.15, -0.2, 0.04), hp(0.12, -0.14, 0.08), hp(0.06, -0.05, 0.09)]
    path, ups = _on_surface(surf, throat, 0.01, 2)
    B.strap(path, ups, 0.016, 0.004, 7, P_BRIDLE)
    nose = []
    centre = hp(0.42, 0.0)
    for k in range(13):
        a = 2 * math.pi * k / 12
        nose.append(centre + hs.HEAD_FACE * math.cos(a) * 0.12 + np.array([0.0, 1.0, 0.0]) * math.sin(a) * 0.12)
    path, ups = _on_surface(surf, nose, 0.008, 1)
    B.strap(path, ups, 0.022, 0.005, 7, P_BRIDLE)
    for s in (-1.0, 1.0):
        q, nn = surf.near(bit[s], 0.012)
        B.ring(q, (0.0, 1.0, 0.0), 0.025, 0.005, 8, P_BRIDLE)
        c, nn = surf.near(hp(0.06, -0.02, s * 0.095), 0.012)
        B.lathe([(0.02, 0.0), (0.02, 0.006), (0.0, 0.01)], c, nn, 6, 9, P_BRIDLE)
    B.lathe([(0.008, -0.08), (0.008, 0.08)], (bit[-1.0] + bit[1.0]) * 0.5, (0.0, 1.0, 0.0), 6, 8, P_BRIDLE)

    # The reins, as a ridden horse wears them: from the bit back along his neck to the withers,
    # sagging off it, joined in front of the horn.
    for s in (-1.0, 1.0):
        q_bit, _n = surf.near(bit[s], 0.012)
        end = np.array([-0.55 + DX, s * 0.035, 1.66])
        n = 15
        pts = []
        for i in range(n):
            u = i / (n - 1)
            p = q_bit + (end - q_bit) * u
            pts.append(p + np.array([0.0, s * 0.05 * math.sin(math.pi * u), -0.14 * math.sin(math.pi * u)]))
        # Hung clear of his neck: pushed out where it would pass through him, then eased so it
        # curves rather than kinks, a few times over.
        for _ in range(6):
            pts = [surf.outside(p, 0.02) for p in pts]
            pts = [pts[0]] + [(pts[i - 1] + 2 * pts[i] + pts[i + 1]) / 4 for i in range(1, n - 1)] + [pts[-1]]
        pts = [pts[0]] + [surf.outside(p, 0.02) for p in pts[1:-1]] + [pts[-1]]
        B.strap(pts, [(0.0, s, 0.0)] * n, 0.018, 0.005, 10, P_REINS)
    B.strap([(-0.5 + DX, -0.03, 1.66), (-0.5 + DX, 0.0, 1.67), (-0.5 + DX, 0.03, 1.66)], [(0, 0, 1)] * 3, 0.018, 0.005, 10, P_REINS)

    tack = B.object("tack_all")
    log("tack", tris(tack), "triangles")
    return tack, {s: surf.near(bit[s], 0.012)[0] for s in (-1.0, 1.0)}


def paint_tack(tack, hi, out_png):
    uv_unwrap(tack, 0.006)
    size = TACK_SIZE
    mask = coverage(tack, size)
    pos = bake(tack, size, "EMIT", emit=_position_socket, samples=1) * (POS_HI - POS_LO) + POS_LO
    paint = bake(tack, size, "EMIT", emit=_attribute_socket("paint"), samples=1)[..., 0]
    nrm = bake(tack, size, "NORMAL") * 2.0 - 1.0
    hi.hide_render = False
    ao = bake(tack, size, "AO", samples=48, ao_distance=0.15)[..., 0]
    curv = bake(tack, size, "EMIT", emit=_pointiness, samples=1)[..., 0]
    log("tack baked")
    img = horse_paint.tack(pos, nrm, ao, curv, paint, mask)
    save_png(img, out_png)


def split(obj, names, attr="piece"):
    out = {}
    for i, name in enumerate(names):
        o = copy_object(obj, name)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        layer = bm.faces.layers.int.get(attr)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f[layer] != i], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        out[name] = o
    bpy.data.objects.remove(obj)
    return out


# --- the rig ------------------------------------------------------------------------------------


def build_armature(bone_defs):
    data = bpy.data.armatures.new("HorseRig")
    arm = bpy.data.objects.new("Horse", data)
    bpy.context.scene.collection.objects.link(arm)
    activate(arm)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (h, t, parent, deform) in bone_defs.items():
        eb = data.edit_bones.new(name)
        eb.head = h
        eb.tail = t
        eb.roll = 0.0
        eb.use_deform = deform
        if parent:
            eb.parent = data.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm


def _neighbours(obj):
    nb = [set() for _ in obj.data.vertices]
    for e in obj.data.edges:
        a, b = e.vertices
        nb[a].add(b)
        nb[b].add(a)
    return [list(s) for s in nb]


def skin(obj, arm, bone_defs, only=None, smooth=3, power=5.0):
    verts = np.array([v.co[:] for v in obj.data.vertices])
    part = obj.data.color_attributes.get("part")
    tail = np.array([d.color[0] > 0.5 for d in part.data]) if part is not None and part.domain == "POINT" else None
    names, idx, w = hs.weights(verts, _neighbours(obj), bone_defs, only=only, smooth=smooth, power=power, tail=tail)
    groups = {n: obj.vertex_groups.new(name=n) for n in names}
    for vi in range(len(verts)):
        for k in range(idx.shape[1]):
            if w[vi, k] > 1e-4:
                groups[names[idx[vi, k]]].add([vi], float(w[vi, k]), "REPLACE")
    mod = obj.modifiers.new("skeleton", "ARMATURE")
    mod.object = arm
    obj.parent = arm


TRUNK = ("pelvis", "spine", "chest")


def skin_tack(pieces, arm, bone_defs):
    skin(pieces["saddle"], arm, bone_defs, only=("spine", "chest"), smooth=4, power=2.0)
    skin(pieces["blanket"], arm, bone_defs, only=TRUNK, smooth=4, power=2.0)
    skin(pieces["saddlebags"], arm, bone_defs, only=("pelvis", "spine"), smooth=4, power=2.0)
    skin(pieces["bridle"], arm, bone_defs, only=("head",), smooth=0)
    skin(pieces["reins"], arm, bone_defs, only=("head", "neck3", "neck2", "neck1", "chest"), smooth=4, power=3.0)


# --- the idle -----------------------------------------------------------------------------------


def key_idle(arm, bone_defs):
    arm.animation_data_create()
    action = bpy.data.actions.new("idle")
    arm.animation_data.action = action
    rest = {b.name: np.array(b.matrix_local) for b in arm.data.bones}
    prev = {}
    times = horse_idle.frames()
    for fi, t in enumerate(times):
        A = horse_idle.pose(bone_defs, t)
        for pb in arm.pose.bones:
            pb.rotation_mode = "QUATERNION"
            name = pb.name
            parent = bone_defs[name][2]
            Ap = A[parent] if parent else np.eye(4)
            basis = np.linalg.inv(rest[name]) @ np.linalg.inv(Ap) @ A[name] @ rest[name]
            m = Matrix(basis.tolist())
            loc, rot, _sc = m.decompose()
            if name in prev and prev[name].dot(rot) < 0.0:
                rot.negate()
            prev[name] = rot.copy()
            pb.location = loc
            pb.rotation_quaternion = rot
            pb.keyframe_insert("location", frame=fi)
            pb.keyframe_insert("rotation_quaternion", frame=fi)
    bpy.context.scene.frame_start = 0
    bpy.context.scene.frame_end = len(times) - 1
    bpy.context.scene.render.fps = horse_idle.FPS
    return action


# --- the build ----------------------------------------------------------------------------------


def main():
    global T0
    T0 = time.time()
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    opts = dict(a[2:].split("=", 1) for a in args if a.startswith("--") and "=" in a)
    out = os.path.join(ROOT, opts.get("out", "assets/creatures/horse"))
    os.makedirs(CACHE, exist_ok=True)
    open(os.path.join(CACHE, ".gdignore"), "w").close()  # Godot mustn't import the .blend
    os.makedirs(out, exist_ok=True)
    clear()
    global PAINT
    PAINT = opts.get("paint", "pictures")
    if "shape" in opts:
        coat, hi = build_coat_rodin(opts["shape"])
        surf = Surface([v.co[:] for v in hi.data.vertices], [list(p.vertices) for p in hi.data.polygons])
    else:
        parts = sculpt()
        SCULPT.update(parts)
        coat, hi = build_coat(parts)
        surf = Surface(*parts["body"])
    tack, bits = build_tack(surf)

    tack.hide_render = True
    paint_coat(coat, hi, os.path.join(out, "horse_coat.png"))
    tack.hide_render = False
    coat.hide_render = True
    paint_tack(tack, hi, os.path.join(out, "horse_tack.png"))
    coat.hide_render = False

    # The far coat: the sculpt cut down further, laid out its own way, the near coat's paint
    # baked onto it. The far tack: the saddle, blanket and bags cut down, their UVs kept.
    lod = make_lod(coat, hi, os.path.join(out, "horse_coat.png"), os.path.join(out, "horse_coat_lod.png"))
    pieces = split(tack, TACK_PIECES)
    tack_lod = copy_object(pieces["saddle"], "tack_lod")
    activate(tack_lod)
    for extra in ("blanket", "saddlebags"):
        o = copy_object(pieces[extra], "lod_" + extra)
        o.select_set(True)
    bpy.context.view_layer.objects.active = tack_lod
    bpy.ops.object.join()
    decimate(tack_lod, TACK_LOD_TRIS, symmetric=False)

    bone_defs = hs.bones()
    arm = build_armature(bone_defs)
    skin(coat, arm, bone_defs)
    skin(lod, arm, bone_defs)
    skin_tack(pieces, arm, bone_defs)
    skin(tack_lod, arm, bone_defs, only=TRUNK, smooth=2, power=2.0)
    key_idle(arm, bone_defs)
    log("rigged and keyed")

    bpy.data.objects.remove(hi)
    for o in list(bpy.data.objects):
        if o.type == "MESH" and o.parent is None:
            bpy.data.objects.remove(o)
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.data.materials.clear()
            for name in list(o.data.color_attributes.keys()):
                o.data.color_attributes.remove(o.data.color_attributes[name])
    if "--blend" in args:
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(CACHE, "horse.blend"))
    bpy.ops.object.select_all(action="SELECT")
    path = os.path.join(out, "horse.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_skins=True,
                              export_animations=True, export_force_sampling=True, export_frame_step=1,
                              export_optimize_animation_size=True, export_def_bones=False, export_apply=False,
                              export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE", export_attributes=False)
    report = {
        "triangles": {o.name: tris(o) for o in bpy.data.objects if o.type == "MESH"},
        "bones": list(bone_defs.keys()),
        "idle": {"seconds": horse_idle.LOOP, "fps": horse_idle.FPS},
        "textures": {"horse_coat.png": COAT_SIZE, "horse_coat_lod.png": LOD_SIZE, "horse_tack.png": TACK_SIZE},
        # Godot's axes (x, y up, z = -Blender y): the bit's rings for the tied reins, the toes.
        "bit": {("L" if s < 0 else "R"): [round(float(bits[s][0]), 4), round(float(bits[s][2]), 4), round(float(-bits[s][1]), 4)]
                for s in bits},
        "capsules": [[c[0], [round(c[1][0], 4), round(c[1][2], 4), round(-c[1][1], 4)],
                      [round(c[2][0], 4), round(c[2][2], 4), round(-c[2][1], 4)], c[3]] for c in hs.capsules()],
        "toes": {n: [round(v[1][0], 4), round(v[1][2], 4), round(-v[1][1], 4)] for n, v in bone_defs.items()
                 if n.startswith(("hoof.", "hhoof."))},
    }
    report["triangles"]["horse (coat + tack, near)"] = sum(v for k, v in report["triangles"].items()
                                                            if k in ["coat"] + TACK_PIECES)
    json.dump(report, open(os.path.join(out, "horse.json"), "w"), indent=1)
    log("wrote", path, report["triangles"])


if __name__ == "__main__":
    main()
