"""Clothes for a MakeHuman man (tools/blender/make_people.py): made on his fitted body, draped, and
their detail baked into small pixel textures.

Each garment starts as a shell over the parts of the body it covers, pushed out by the cloth's
thickness: the shirt (with a collar), trousers, a vest open at the neck, a coat open down the front
with raised lapels and a collar. The coat's skirt is extruded down from its hem to mid-thigh and
draped with Blender's cloth simulation over his hips and legs (the top of the coat pinned), so it
hangs and folds. A string tie hangs at the collar. Then for each garment: its UVs unwrapped with
every island turned upright (so rows of texels run across the body, like the painting's tiles), and
its look baked with Cycles into a texture of about 48 texels per metre (one tile, ~2 cm): shadow in
creases and laps and under the arms (occlusion near and far), worn pale edges where it sticks out,
dust low down and on what faces up, and the cloth's own mottle, on a ramp of the garment's colour
cut to 16 colours. The game lights each texel as one tile (src/render/tiles.gdshaderinc). Saved next
to the .glb as <id>_<garment>.png.
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
TIE = ([0.032, 0.026, 0.016], 0.011, 7, 0.02)
# The vest's opening at the neck (the painting's: a narrow V of shirt round the tie, ~12 cm deep and
# ~9 cm across at the top): depth below the vest's top, half-width at the top.
VEST_V = (0.12, 0.045)
# The shirt collar's turned-down points either side of the knot: inner and outer top corners and the
# tip, as (across, up) from the knot, and how far they stand off his chest (over the vest's top).
COLLAR_POINT = ((0.012, 0.004), (0.046, 0.012), (0.03, -0.05), 0.019)
# How far the tie lies off his chest: over the shirt, under the vest (its ends tuck in at the V's foot).
TIE_OFF = 0.011
# How far each sits off the skin (m).
OFFSET = {"shirt": 0.005, "trousers": 0.008, "vest": 0.013, "coat": 0.024, "cravat": 0.0}
# The coat stands further off where it's cut loose and padded (the painting's man is broad in a
# heavy sack coat): extra metres by how much of a vertex each bone moves.
COAT_BULK = {"upper_arm": 0.045, "forearm": 0.024, "chest": 0.03, "abdomen": 0.015}


def hex_colour(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


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
        _level_top(g, neck_y + 0.045)
        _collar(g, neck_y + 0.02, 0.03, 0.006)
        _collar_points(g, person)
        out["shirt"] = g
    if "trousers" in outfit:
        g = shell(person, "trousers", lambda c, r, pts: (r == "trunk" and c[1] < 1.02) or (legs(r) and c[1] > 0.1),
                  OFFSET["trousers"])
        out["trousers"] = g
    if "vest" in outfit:
        top = neck_y - 0.025
        vest_gap = lambda y: v_gap(y, top, top - VEST_V[0], VEST_V[1])

        def keep_vest(c, r, pts):
            if r != "trunk" or not (0.93 < c[1] < top):
                return False
            front = c[2] < 0.0
            return not (front and abs(c[0]) < vest_gap(c[1]))
        g = shell(person, "vest", keep_vest, OFFSET["vest"])
        _clean_opening(g, vest_gap, top - VEST_V[0], top)
        out["vest"] = g
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


def _clean_opening(g, gap, bottom, top):
    """The front opening's edge laid on its line: the faces kept by their centres leave a sawtooth
    edge (squares of shirt stepping down the V); each edge vertex near the line is moved onto it."""
    edge = {i for e in g.boundary() for i in e}
    for i in edge:
        p = g.P[i]
        if p[2] > -0.02 or not (bottom - 0.015 < p[1] < top - 0.004):
            continue
        want = gap(p[1])
        if abs(abs(p[0]) - want) < 0.03:
            p[0] = math.copysign(want, p[0]) if want > 0.002 else 0.0


def _level_top(g, cut):
    """The garment's top edge round his neck made level at `cut`: the faces kept by their centres
    leave it a sawtooth, which the collar built on it turns into spikes."""
    for i in {i for e in g.boundary() for i in e}:
        if cut - 0.025 < g.P[i][1] < cut + 0.02:
            g.P[i][1] = cut


def _front_surface(person):
    """(x, y) -> (z of the front of his neck or chest there, the bone weights there)."""
    v = person.v
    front = np.array([i for i in range(len(v)) if person.region[i] in ("neck", "trunk") and v[i][2] < 0])

    def at(x, y):
        d = np.abs(v[front, 0] - x) + np.abs(v[front, 1] - y)
        near = front[d < 0.015]
        if len(near) == 0:
            near = front[np.argsort(d)[:4]]
        i = near[np.argmin(v[near, 2])]
        return float(v[i][2]), person.W[i]
    return at


def _knot(person):
    """Where the tie's knot sits: the front of his throat on his centre line, 2 cm over neck_y."""
    v = person.v
    y = getattr(person, "neck_y", 1.47) + 0.02
    neck = [i for i in range(len(v)) if person.region[i] in ("neck", "trunk") and abs(v[i][1] - y) < 0.012]
    # The most forward point at that height is on his chest muscle, off to one side: keep to the middle.
    middle = [i for i in neck if abs(v[i][0]) < 0.02] or neck
    front = min(middle, key=lambda i: v[i][2])
    return v[front] + np.array([0, 0.0, -0.012]), person.W[front]


def _collar_points(g, person):
    """The shirt collar's two points, turned down over the top of the vest either side of the knot
    (COLLAR_POINT), each a flat triangle lying a little off his chest."""
    knot, _w = _knot(person)
    surface = _front_surface(person)
    for side in (-1, 1):
        ids = []
        for dx, dy in COLLAR_POINT[:3]:
            x, y = side * dx, knot[1] + dy
            z, w = surface(x, y)
            ids.append(g.add_vertex(np.array([x, y, min(z - COLLAR_POINT[3], knot[2] - 0.004)]), w))
        g.F.append(ids if side > 0 else ids[::-1])


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
    """A dark necktie, the painting's man's: a knot at the collar and two ends hanging together
    down the shirt front into the vest (TIE: knot size, end half-width, segments, step)."""
    base, w = _knot(person)
    surface = _front_surface(person)
    g = Garment("cravat")

    def box(c, size):
        ids = [g.add_vertex(c + np.array([sx, sy, sz]) * size / 2, w)
               for sx in (-1, 1) for sy in (-1, 1) for sz in (-1, 1)]
        for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
            g.F.append([ids[k] for k in q])
    knot, half, segments, step = TIE
    box(base, np.array(knot))
    for side in (-1, 1):
        # Hanging straight down together from the knot, one just over the other, widening a little
        # and lying on his shirt front (splayed apart at the top they read as a bow).
        prev = None
        for k in range(segments):
            x = 0.003 * side + 0.005 * side * k / (segments - 1)
            y = base[1] - 0.01 - step * k
            z, wk_bones = surface(x, y)
            z = min(z - TIE_OFF - 0.0015 * (side > 0), base[2] + 0.004)
            wk = half * (0.7 + 0.3 * k / (segments - 1))
            p = np.array([x, y, z])
            a = g.add_vertex(p + [-wk, 0, 0], wk_bones if k > 1 else w)
            bb = g.add_vertex(p + [wk, 0, 0], wk_bones if k > 1 else w)
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
    # Each island turned so "up" on the body is up in the texture: rows of texels (tiles) run
    # across the body and line up from island to island.
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.align_rotation(method="GEOMETRY", axis="Z")
    bpy.ops.uv.pack_islands(rotate=False, margin=0.01)
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


def _bake(obj, size, kind, samples=64, emit=None):
    """One pass of `obj` baked into a fresh size x size data image, returned as an array (rows
    bottom-up, like Blender's): "AO", or "EMIT" with `emit(nodes, links)` giving the socket to bake."""
    img = bpy.data.images.new("%s_%s" % (obj.name, kind), size, size, float_buffer=True)
    img.colorspace_settings.name = "Non-Color"
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
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.render.bake.margin = 3
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.bake(type=kind)
    out = np.array(img.pixels[:]).reshape(size, size, 4)[:, :, :3].copy()
    obj.data.materials.clear()
    return out


def _smooth_noise(rng, size, cell):
    """Value noise with blobs about `cell` texels across (bilinear between random points)."""
    n = rng.random((size // cell + 2, size // cell + 2))
    f = np.arange(size) / cell
    i = np.floor(f).astype(int)
    t = (f - i)[:, None]
    rows = n[i] * (1 - t) + n[i + 1] * t
    cols = rows[:, i] * (1 - t.T) + rows[:, i + 1] * t.T
    return cols


def cloth_look(colour, ao_near, ao_far, point, height, up, seed, style):
    """The garment's colour per texel from its baked passes (each size x size): what a painter
    would put in each tile of the painting's coat."""
    size = ao_near.shape[0]
    rng = np.random.default_rng(seed)
    wool = style == "wool"
    per_tile = rng.random((size, size)) - 0.5
    blobs = _smooth_noise(rng, size, 3) - 0.5
    broad = _smooth_noise(rng, size, 9) - 0.5
    # Light and dark (in stops): creases and laps, the hollows under the arms and inside the coat,
    # edges that catch the light, and the cloth's own unevenness (wool mottles more than cotton).
    # Deep creases go dark brown, never black: the game's own light and shadow do the rest.
    shade = (-0.5 * (1.0 - ao_near) ** 0.8 - 0.3 * (1.0 - ao_far)
             + 4.0 * np.clip(point - 0.52, -0.04, 0.04)
             + (0.17 if wool else 0.1) * per_tile + 0.12 * blobs + 0.08 * broad)
    c = colour[None, None, :] * np.exp2(2.0 * shade)[..., None]
    # Each tile leans a little warm or cool (heathered wool, sun-faded cotton).
    lean = (rng.random((size, size)) - 0.5) * (0.1 if wool else 0.05)
    c = c * (1.0 + lean[..., None] * np.array([1.0, 0.3, -0.8]))
    # Wear: edges that stick out rubbed paler and greyer.
    wear = np.clip((point - 0.52) * 7.0, 0.0, 1.0) * 0.5
    grey = c.mean(-1, keepdims=True)
    c = c * (1.0 - wear[..., None]) + (grey * 1.25 + 0.015) * wear[..., None]
    # Dust: thickest low down (hems, cuffs, knees) and on what faces up (shoulders), in patches.
    dust = np.clip((0.8 - height) / 0.6, 0.0, 1.0) * 0.35 + np.clip(up - 0.55, 0.0, 0.45) * 0.45
    dust = dust * (0.7 + 0.6 * (blobs + 0.5))
    c = c * (1.0 - dust[..., None]) + np.array([0.5, 0.43, 0.34]) * dust[..., None]
    return np.clip(c, 0.0, 1.0)


def bake_texture(obj, colour, path, seed=1, style="wool", over=()):
    """The garment's look baked into a small texture, one texel per tile (cloth_look), cut to 16
    colours without dithering, so each tile is one clean colour. `over`: the garments worn over
    this one, left out of the bake (where they cover it, it isn't seen; where it shows, they'd
    only darken it wholesale: their shadow is the game's to cast)."""
    from PIL import Image
    for o in over:
        o.hide_render = True
    area = surface_area(obj)
    size = int(2 ** round(math.log2(max(32, min(256, math.sqrt(area / uv_coverage(obj)) * TEXELS_PER_M)))))
    scene = bpy.context.scene
    if scene.world is None:
        scene.world = bpy.data.worlds.new("World")
    # Near: creases, laps, folds. Far: under the arms, inside the coat, between the legs.
    scene.world.light_settings.distance = 0.04
    ao_near = _bake(obj, size, "AO")[:, :, 0]
    scene.world.light_settings.distance = 0.3
    ao_far = _bake(obj, size, "AO")[:, :, 0]

    def pointiness(nodes, links):
        return nodes.new("ShaderNodeNewGeometry").outputs["Pointiness"]

    def height_up(nodes, links):
        geo = nodes.new("ShaderNodeNewGeometry")
        pos = nodes.new("ShaderNodeSeparateXYZ")
        nrm = nodes.new("ShaderNodeSeparateXYZ")
        out = nodes.new("ShaderNodeCombineXYZ")
        links.new(geo.outputs["Position"], pos.inputs[0])
        links.new(geo.outputs["Normal"], nrm.inputs[0])
        links.new(pos.outputs["Z"], out.inputs["X"])
        links.new(nrm.outputs["Z"], out.inputs["Y"])
        return out.outputs[0]

    point = _bake(obj, size, "EMIT", 1, pointiness)[:, :, 0]
    hu = _bake(obj, size, "EMIT", 1, height_up)
    if os.environ.get("CLOTH_PASSES"):  # for tuning: the raw passes as .npz
        np.savez(os.path.join(os.environ["CLOTH_PASSES"], os.path.basename(path) + ".npz"),
                 ao_near=ao_near, ao_far=ao_far, point=point, height=hu[:, :, 0], up=hu[:, :, 1])
    rgb = cloth_look(colour, ao_near, ao_far, point, hu[:, :, 0], hu[:, :, 1], seed, style)
    img = Image.fromarray((np.flipud(rgb) * 255.0 + 0.5).astype(np.uint8), "RGB")
    img = img.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    img.save(path)
    for o in over:
        o.hide_render = False
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
