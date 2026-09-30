"""Clothes for a MakeHuman man (tools/blender/make_people.py): made on his fitted body, draped, and
their detail baked into small pixel textures.

Each garment starts as a shell over the parts of the body it covers, pushed out by the cloth's
thickness: the shirt (with a collar), trousers, a vest open at the neck, a coat open down the front
with raised lapels and a collar. The coat's skirt is extruded down from its hem to mid-thigh and
draped with Blender's cloth simulation over his hips and legs (the top of the coat pinned), so it
hangs and folds. A string tie hangs at the collar. Then for each garment: its UVs unwrapped, the
ambient occlusion from everything round it baked with Cycles (where cloth tucks under, laps over,
folds), mixed with a little weave, and quantized to a few shades of the garment's colour, at about
48 texels per metre, like the rest of the world. The texture is saved next to the .glb as
<id>_<garment>.png; the game reads it with nearest filtering.
"""
import math
import os

import numpy as np

try:
    import bpy
    from mathutils.bvhtree import BVHTree
except ImportError:
    bpy = None

TEXELS_PER_M = 48
# Triangles per garment after decimation.
BUDGET = {"coat": 2200, "vest": 700, "shirt": 1500, "trousers": 1200, "cravat": 120}
# The necktie: knot box (m), each end's half-width, segments down, step between them (the
# painting's is a big loose dark tie, ~4-5 cm wide ends hanging ~16 cm).
TIE = ([0.046, 0.032, 0.018], 0.012, 8, 0.023)
# How far each sits off the skin (m).
OFFSET = {"shirt": 0.005, "trousers": 0.008, "vest": 0.013, "coat": 0.024, "cravat": 0.0}
# The coat stands further off where it's cut loose and padded (the painting's man is broad in a
# heavy sack coat): extra metres by how much of a vertex each bone moves.
COAT_BULK = {"upper_arm": 0.026, "forearm": 0.014, "chest": 0.012}


def hex_colour(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def ramp(base, count=5, spread=0.45):
    """Dark to light shades of a colour, warmer in the lights (as PixelArt.ramp does)."""
    out = []
    for i in range(count):
        t = i / (count - 1) - 0.5
        c = base * (1.0 + t * spread * 2.0)
        if t > 0:
            c = c + np.array([0.04, 0.02, -0.01]) * t
        else:
            c = c + np.array([-0.01, -0.005, 0.02]) * t
        out.append(np.clip(c, 0, 1))
    return out


def vertex_normals(v, faces):
    n = np.zeros_like(v)
    for fv, _t in faces:
        p = v[fv]
        fn = np.zeros(3)
        for i in range(len(fv)):
            fn += np.cross(p[i], p[(i + 1) % len(fv)])
        n[fv] += fn
    ln = np.linalg.norm(n, axis=1)
    ln[ln < 1e-12] = 1.0
    return n / ln[:, None]


class Garment:
    def __init__(self, name):
        self.name = name
        self.P = []  # positions
        self.W = []  # bone weights per vertex
        self.F = []  # faces (vertex indices)

    def add_vertex(self, p, w):
        self.P.append(np.array(p, dtype=float))
        self.W.append(np.array(w, dtype=float))
        return len(self.P) - 1

    def boundary(self):
        """Edges used by one face only: {(a, b)} with a < b."""
        count = {}
        for f in self.F:
            for i in range(len(f)):
                e = tuple(sorted((f[i], f[(i + 1) % len(f)])))
                count[e] = count.get(e, 0) + 1
        return [e for e, c in count.items() if c == 1]


def shell(person, name, keep, offset, bulk=None):
    """The body faces `keep(face centre, region, vertex positions)` accepts, pushed out by `offset`
    (plus `bulk`: {bone name prefix: extra metres}, weighted by how much each bone moves a vertex)."""
    v = person.v
    n = person.normals
    g = Garment(name)
    remap = {}
    extra = np.zeros(len(v))
    for prefix, m in (bulk or {}).items():
        cols = [k for k, b in enumerate(person.env["bones"]) if b.startswith(prefix)]
        if cols:
            extra += m * np.asarray(person.W)[:, cols].sum(axis=1)
    for fv, _t in person.body_faces:
        pts = v[fv]
        if not keep(pts.mean(0), person.region[fv[0]], pts):
            continue
        face = []
        for i in fv:
            if i not in remap:
                remap[i] = g.add_vertex(v[i] + n[i] * (offset + extra[i]), person.W[i])
            face.append(remap[i])
        g.F.append(face)
    g.src = remap
    return g


def extrude_edge_loop(g, verts, step, rings, flare=0.0, centre_fn=None):
    """Extrude the boundary vertices `verts` (ordered) `rings` times by `step`, flaring outward."""
    prev = list(verts)
    for k in range(1, rings + 1):
        cur = []
        for i in prev:
            p = g.P[i] + step
            if centre_fn is not None and flare:
                c = centre_fn(p)
                d = p - c
                d[1] = 0
                p = p + d * flare
            cur.append(g.add_vertex(p, g.W[i]))
        for a in range(len(prev) - 1):
            g.F.append([prev[a], prev[a + 1], cur[a + 1], cur[a]])
        prev = cur
    return prev


def ordered_loop(g, verts, centre):
    """Boundary vertices sorted by angle round a vertical axis through `centre` (0 = straight ahead)."""
    return sorted(verts, key=lambda i: math.atan2(g.P[i][0] - centre[0], -(g.P[i][2] - centre[2])))


def make_all(person, outfit):
    """The garments for this person, as Garment objects (high detail, before any sim)."""
    v = person.v
    person.normals = vertex_normals(v, person.body_faces)
    out = {}
    # Where his neck meets his shoulders: the lowest of his neck (collars, the vest's top, the
    # coat's V and the tie are all measured from it, not fixed heights).
    neck_y = float(np.percentile(v[person.region == "neck"][:, 1], 5)) if (person.region == "neck").any() else 1.47
    person.neck_y = neck_y
    arms = lambda r: r.startswith("upper_arm") or r.startswith("forearm")
    legs = lambda r: r.startswith("thigh") or r.startswith("shin")

    def v_gap(y, top, bottom, width):
        """Half width of an opening down the front at height y (0 below `bottom`)."""
        if y < bottom:
            return 0.0
        return width * min((y - bottom) / (top - bottom), 1.0)

    if "shirt" in outfit:
        def keep_shirt(c, r, pts):
            if r == "trunk":
                return c[1] > 0.88
            if r == "neck":
                return c[1] < neck_y + 0.045
            return arms(r) and pts[:, 1].min() > 0.868
        g = shell(person, "shirt", keep_shirt, OFFSET["shirt"])
        _collar(g, neck_y + 0.02, 0.03, 0.006)
        out["shirt"] = g
    if "trousers" in outfit:
        g = shell(person, "trousers", lambda c, r, pts: (r == "trunk" and c[1] < 1.02) or (legs(r) and c[1] > 0.1),
                  OFFSET["trousers"])
        out["trousers"] = g
    if "vest" in outfit:
        def keep_vest(c, r, pts):
            top = neck_y - 0.025
            if r != "trunk" or not (0.93 < c[1] < top):
                return False
            front = c[2] < 0.0
            return not (front and abs(c[0]) < v_gap(c[1], top, top - 0.175, 0.075))
        out["vest"] = shell(person, "vest", keep_vest, OFFSET["vest"])
    if "coat" in outfit:
        def keep_coat(c, r, pts):
            if r == "trunk":
                if c[1] < 0.9:
                    return False
                front = c[2] < 0.0
                return not (front and abs(c[0]) < v_gap(c[1], neck_y - 0.01, 1.05, 0.095))
            if r == "neck":
                return c[1] < neck_y + 0.02 and c[2] > -0.02
            return arms(r) and pts[:, 1].min() > 0.895
        g = shell(person, "coat", keep_coat, OFFSET["coat"], COAT_BULK)
        g.arm_bones = [i for i, n in enumerate(person.env["bones"]) if n.startswith(("upper_arm", "forearm", "hand"))]
        _coat_skirt(g)
        _lapels(g, neck_y)
        _collar(g, neck_y, 0.045, 0.012)
        out["coat"] = g
    if "cravat" in outfit:
        out["cravat"] = _string_tie(person)
    return out


def _collar(g, above_y, height, lean):
    """A collar: the garment round the neck above `above_y`, doubled, raised `height` and turned
    out by `lean` (a band of cloth standing round the neck). Built from the garment's own faces,
    so it can't make crossed or stretched triangles the way extruding a ragged edge did."""
    faces = [f for f in g.F if min(g.P[i][1] for i in f) > above_y - 0.02]
    remap = {}
    for f in faces:
        nf = []
        for i in f:
            if i not in remap:
                p = g.P[i].copy()
                out = np.array([p[0], 0.0, p[2] - 0.005])
                n = np.linalg.norm(out)
                out = out / n if n > 1e-6 else out
                t = np.clip((p[1] - (above_y - 0.02)) / 0.05, 0, 1)
                remap[i] = g.add_vertex(p + out * (0.004 + lean * t) + np.array([0, height * 0.35 * t, 0]), g.W[i])
            nf.append(remap[i])
        g.F.append(nf)


def _coat_skirt(g):
    """From the hem at the hips, down to mid-thigh, flaring a little and open at the front."""
    b = g.boundary()
    # The hem round his hips only: the sleeve cuffs are low edges too, and a skirt stitched to
    # them hangs from his wrists (and stretches like wings when he puts his hands up).
    arm = getattr(g, "arm_bones", [])
    hem = sorted({i for e in b for i in e if g.P[i][1] < 0.93 and (not arm or g.W[i][arm].max() < 0.1)})
    if len(hem) < 8:
        return
    loop = ordered_loop(g, hem, np.array([0, 0, 0.0]))
    # Tube down: rings of the hem, each a little lower and wider.
    prev = loop
    rings = 6
    g.skirt = set()
    for k in range(1, rings + 1):
        cur = []
        for i in prev:
            p = g.P[i].copy()
            p[1] -= 0.065
            d = p.copy()
            d[1] = 0
            d[2] -= 0.01
            p = p + d * 0.045
            w = g.W[i].copy()
            if arm:
                w[arm] = 0.0  # the skirt hangs from his hips, whatever his arms do
                w = w / max(w.sum(), 1e-6)
            cur.append(g.add_vertex(p, w))
            g.skirt.add(cur[-1])
        for a in range(len(prev)):
            b2 = (a + 1) % len(prev)
            # Open at the front: no face straight ahead, a wider gap lower down.
            mid = (g.P[prev[a]] + g.P[prev[b2]]) / 2
            ang = abs(math.atan2(mid[0], -mid[2]))
            if ang < 0.12 + 0.05 * k:
                continue
            g.F.append([prev[a], prev[b2], cur[b2], cur[a]])
        prev = cur


def _lapels(g, neck_y=1.47):
    """The lapels: the coat's front edges above the waist, doubled and raised off the chest."""
    b = g.boundary()
    edge = {i for e in b for i in e if 1.08 < g.P[i][1] < neck_y and g.P[i][2] < -0.02}
    if not edge:
        return
    ep = np.array([g.P[i] for i in edge])
    faces = []
    for f in g.F:
        c = np.mean([g.P[i] for i in f], axis=0)
        if not (1.08 < c[1] < neck_y and c[2] < -0.02):
            continue
        if np.min(np.linalg.norm(ep - c, axis=1)) < 0.055 * (0.4 + 0.6 * (c[1] - 1.08) / (neck_y - 1.08)):
            faces.append(f)
    remap = {}
    for f in faces:
        nf = []
        for i in f:
            if i not in remap:
                p = g.P[i].copy()
                out = p.copy()
                out[1] = 0
                out /= max(np.linalg.norm(out), 1e-6)
                remap[i] = g.add_vertex(p + out * 0.007 + np.array([0, 0, -0.004]), g.W[i])
            nf.append(remap[i])
        g.F.append(nf)


def _string_tie(person):
    """A dark necktie, the painting's man's: a fat knot at the collar and two wide ends hanging
    loose down the shirt front, splaying a little (TIE: knot size, end half-width, segments, step)."""
    v = person.v
    y = getattr(person, "neck_y", 1.47) + 0.02
    neck = [i for i in range(len(v)) if person.region[i] in ("neck", "trunk") and abs(v[i][1] - y) < 0.012]
    # The front of the throat, on his centre line: the most forward point at that height is on his
    # chest muscle, off to one side, and put the knot there.
    middle = [i for i in neck if abs(v[i][0]) < 0.02] or neck
    front = min(middle, key=lambda i: v[i][2])
    base = v[front] + np.array([0, 0.0, -0.012])
    w = person.W[front]
    g = Garment("cravat")

    def box(c, size):
        ids = [g.add_vertex(c + np.array([sx, sy, sz]) * size / 2, w)
               for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            g.F.append([ids[k] for k in q])
    knot, half, segments, step = TIE
    box(base, np.array(knot))
    chest = person.W[min(range(len(v)), key=lambda i: np.linalg.norm(v[i] - (base + [0, -0.1, 0])))]
    for side in (-1, 1):
        top = base + np.array([0.008 * side, -0.012, -0.006])
        prev = None
        for k in range(segments):
            y = -step * k
            # Widening and splaying as they hang, lying a little further out over the shirt.
            wk = half * (0.75 + 0.25 * k / (segments - 1))
            p = top + np.array([0.018 * side * k / (segments - 1), y, -0.002 + 0.002 * k])
            a = g.add_vertex(p + [-wk, 0, 0], chest if k > 1 else w)
            bb = g.add_vertex(p + [wk, 0, 0], chest if k > 1 else w)
            if prev:
                g.F.append([prev[0], prev[1], bb, a])
            prev = (a, bb)
    return g


# --- Blender --------------------------------------------------------------------------------

def to_object(g, to_blender, bones):
    mesh = bpy.data.meshes.new("cloth_" + g.name)
    mesh.from_pydata([to_blender(p) for p in g.P], [], g.F)
    mesh.validate()
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new("cloth_" + g.name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    for b in bones:
        obj.vertex_groups.new(name=b)
    for i, w in enumerate(g.W):
        for b, x in enumerate(w):
            if x > 0.001:
                obj.vertex_groups[b].add([i], float(x), "REPLACE")
    return obj


def drape(coat_obj, g, body_obj, frames=45):
    """Let the coat's skirt fall and fold over his hips and legs (everything above pinned)."""
    if not getattr(g, "skirt", None):
        return
    pin = coat_obj.vertex_groups.new(name="pin")
    for i, p in enumerate(g.P):
        if i not in g.skirt:
            pin.add([i], 1.0, "REPLACE")
    bpy.context.view_layer.objects.active = body_obj
    bpy.ops.object.modifier_add(type="COLLISION")
    body_obj.collision.thickness_outer = 0.012
    bpy.context.view_layer.objects.active = coat_obj
    bpy.ops.object.modifier_add(type="CLOTH")
    cloth = coat_obj.modifiers[-1]
    cloth.settings.vertex_group_mass = "pin"
    cloth.settings.quality = 8
    cloth.settings.mass = 0.4  # heavy wool
    cloth.settings.tension_stiffness = 25
    cloth.settings.compression_stiffness = 25
    cloth.settings.bending_stiffness = 2.0
    cloth.collision_settings.distance_min = 0.006
    cloth.point_cache.frame_end = frames
    scene = bpy.context.scene
    scene.frame_start = 1
    for f in range(1, frames + 1):
        scene.frame_set(f)
    bpy.ops.object.modifier_apply(modifier=cloth.name)
    body_obj.modifiers.clear()
    scene.frame_set(1)


def unwrap(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(72), island_margin=0.01)
    bpy.ops.uv.pack_islands(rotate=True, margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")


def uv_coverage(obj):
    """How much of the texture the UV islands cover (0..1)."""
    uv = obj.data.uv_layers.active.data
    total = 0.0
    for poly in obj.data.polygons:
        pts = [uv[li].uv for li in poly.loop_indices]
        a = 0.0
        for i in range(len(pts)):
            a += pts[i].x * pts[(i + 1) % len(pts)].y - pts[(i + 1) % len(pts)].x * pts[i].y
        total += abs(a) / 2
    return max(min(total, 1.0), 0.05)


def surface_area(obj):
    return sum(p.area for p in obj.data.polygons)


def bake_texture(obj, colour, path, seed=1, style="wool"):
    """AO from everything round it, a little weave, a few shades of `colour`: a pixel texture."""
    area = surface_area(obj)
    size = int(2 ** round(math.log2(max(32, min(256, math.sqrt(area / uv_coverage(obj)) * TEXELS_PER_M)))))
    img = bpy.data.images.new(obj.name + "_ao", size, size)
    mat = bpy.data.materials.new(obj.name + "_bake")
    mat.use_nodes = True
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = img
    mat.node_tree.nodes.active = node
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    scene = bpy.context.scene
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    # Only nearby cloth and skin shade it: creases, laps, folds (not the whole man).
    scene.world.light_settings.distance = 0.1
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 128
    scene.render.bake.margin = 3
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.bake(type="AO")
    ao = np.array(img.pixels[:]).reshape(size, size, 4)[:, :, 0]
    # A light blur takes the sampling grain out (the shading should be broad, painted-looking).
    pad = np.pad(ao, 1, mode="edge")
    ao = sum(pad[dy:dy + size, dx:dx + size] for dy in range(3) for dx in range(3)) / 9.0
    rng = np.random.default_rng(seed)
    noise = rng.random((size, size))
    # Coarse mottling (wool), fine weave.
    coarse = np.kron(rng.random((size // 8 + 1, size // 8 + 1)), np.ones((8, 8)))[:size, :size]
    if style == "wool":
        tex = 0.62 * coarse + 0.38 * noise
    else:
        weave = ((np.add.outer(np.arange(size), np.arange(size)) % 2) * 1.0)
        tex = 0.5 * coarse + 0.3 * noise + 0.2 * weave
    value = np.clip(0.05 + 0.85 * ao ** 1.6 + (tex - 0.5) * 0.12, 0, 1)
    shades = ramp(colour, 5)
    band = np.clip((value * len(shades)).astype(int), 0, len(shades) - 1)
    rgb = np.stack([shades[b] for b in band.ravel()]).reshape(size, size, 3)
    out = bpy.data.images.new(os.path.basename(path), size, size)
    px = np.concatenate([rgb, np.ones((size, size, 1))], axis=2)
    out.pixels.foreach_set(px.ravel().astype(np.float32))
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    obj.data.materials.clear()
    return size


def decimate(obj, tris):
    have = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if have <= tris:
        return
    mod = obj.modifiers.new("decimate", "DECIMATE")
    mod.ratio = tris / have
    mod.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="decimate")


# Which layers each garment must stay outside of, and by how much (m), after decimation.
LAYERS = {"shirt": [("skin", 0.004)], "trousers": [("skin", 0.006)],
          "vest": [("skin", 0.01), ("shirt", 0.006)],
          "coat": [("skin", 0.02), ("shirt", 0.014), ("vest", 0.009), ("trousers", 0.01)],
          "cravat": [("shirt", 0.003)]}


def separate(objs):
    """Push each garment's vertices out wherever cutting it down let a layer under it show through."""
    for name, rules in LAYERS.items():
        outer = objs.get(name)
        if outer is None:
            continue
        for inner_name, gap in rules:
            inner = objs.get(inner_name)
            if inner is None:
                continue
            tree = BVHTree.FromObject(inner, bpy.context.evaluated_depsgraph_get())
            moved = 0
            for vert in outer.data.vertices:
                hit = tree.find_nearest(vert.co, 0.06)
                if hit[0] is None:
                    continue
                loc, normal = hit[0], hit[1]
                d = (vert.co - loc).dot(normal)
                if d < gap:
                    vert.co = vert.co + normal * (gap - d)
                    moved += 1
            outer.data.update()


def bake_head_ao(head_obj, path, width=96, height=64):
    """The head's own shading (eye sockets, under the nose and brow, round the ears) in the face
    painter's layout, for PeopleArt.face to shade with instead of painting it."""
    img = bpy.data.images.new(head_obj.name + "_ao", width, height)
    mat = bpy.data.materials.new(head_obj.name + "_bake")
    mat.use_nodes = True
    node = mat.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = img
    mat.node_tree.nodes.active = node
    head_obj.data.materials.clear()
    head_obj.data.materials.append(mat)
    scene = bpy.context.scene
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    scene.world.light_settings.distance = 0.035
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 128
    scene.render.bake.margin = 2
    bpy.ops.object.select_all(action="DESELECT")
    head_obj.select_set(True)
    bpy.context.view_layer.objects.active = head_obj
    bpy.ops.object.bake(type="AO")
    px = np.array(img.pixels[:]).reshape(height, width, 4)
    ao = px[:, :, 0]
    # Texels no face covers (the seam, round the eyeballs' backs): full light.
    ao[px[:, :, 3] < 0.5] = 1.0
    # Broad shading, not speckle: blur it a little.
    pad = np.pad(ao, 1, mode="edge")
    ao = sum(pad[dy:dy + height, dx:dx + width] for dy in range(3) for dx in range(3)) / 9.0
    out = bpy.data.images.new(os.path.basename(path), width, height)
    rgba = np.stack([ao, ao, ao, np.ones_like(ao)], axis=2)
    out.pixels.foreach_set(rgba.ravel().astype(np.float32))
    out.filepath_raw = path
    out.file_format = "PNG"
    out.save()
    head_obj.data.materials.clear()
