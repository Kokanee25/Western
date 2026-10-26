"""The saloon cinematic's set and cast, built in Blender (docs/briefs/cinematic.md).

Not the game: a film set. The room, the card table and the men are made here from the game's own
textures, kit props (assets/props/kit/*.json) and Studio men (assets/people/), lit for film and
rendered by Cycles. Run with Blender as a Python module (bpy 5.0.1, as people.yml):

    python tools/cinematic/saloon.py --stills=build/cinematic/stills [--only=ots,room] [--fast]
    python tools/cinematic/saloon.py --blend=build/cinematic/saloon.blend   # the set saved, to look at

Space: Blender's, Z up, metres. The front doors are at +Y (the moon in them), the bar along +X,
the card table in the middle of the room; you (the player) sit at the table's south side looking
up the room toward the doors, as the saloon painting does (docs/concept/saloon-night.png).
"""
import json
import math
import os
import sys

import bpy  # first: the bpy module brings bmesh and mathutils with it
import bmesh
from mathutils import Matrix, Quaternion, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TEX = os.path.join(ROOT, "assets", "textures")
PEOPLE = os.path.join(ROOT, "assets", "people")
KIT = os.path.join(ROOT, "assets", "props", "kit")

# The room.
ROOM_X = (-6.0, 6.0)
ROOM_Y = (0.0, 18.0)
ROOM_H = 5.0
DOOR_X = (-3.9, -2.3)        # the front doors' opening in the +Y wall
DOOR_H = 2.7
TABLE = Vector((-0.6, 8.5, 0.0))
TABLE_TOP = 0.757
BALCONY_Y = 14.6             # the balcony over the front of the room
BALCONY_Z = 3.0

# Warm lamp light and the moon's (linear RGB, roughly 2000 K and 9000 K).
LAMP_RGB = (1.0, 0.50, 0.17)
MOON_RGB = (0.55, 0.68, 1.0)


def args():
    out = {}
    for a in sys.argv[1:]:
        if a.startswith("--"):
            k, _, v = a[2:].partition("=")
            out[k] = v if v else True
    return out


# ---------------------------------------------------------------- materials

_mats = {}


def image(path):
    name = os.path.relpath(path, ROOT)
    im = bpy.data.images.get(name)
    if im is None:
        im = bpy.data.images.load(path)
        im.name = name
    return im


def material(key, tex=None, colour=(0.5, 0.5, 0.5), rough=0.7, emit=None, emit_strength=0.0,
             alpha=None, closest=True, spec=0.25, transmission=0.0):
    """A Principled material, its base from a texture (filtered closest: the game's squares) or a
    colour. Cached by key."""
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Specular IOR Level"].default_value = spec
    if tex:
        t = nt.nodes.new("ShaderNodeTexImage")
        t.image = image(tex)
        t.interpolation = "Closest" if closest else "Linear"
        nt.links.new(t.outputs["Color"], bsdf.inputs["Base Color"])
        if alpha:
            nt.links.new(t.outputs["Alpha"], bsdf.inputs["Alpha"])
    else:
        bsdf.inputs["Base Color"].default_value = (*colour, 1.0)
    if emit:
        bsdf.inputs["Emission Color"].default_value = (*emit, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emit_strength
    if transmission:
        bsdf.inputs["Transmission Weight"].default_value = transmission
        bsdf.inputs["IOR"].default_value = 1.5
    _mats[key] = m
    return m


def wood(name):
    """One of the game's woods (assets/textures/woods/<name>.png, 384 texels a metre): the
    material and its repeat in metres (along the grain, across it)."""
    path = os.path.join(TEX, "woods", name + ".png")
    im = image(path)
    tpm = 384.0
    if name == "dark_oak":
        tpm = 512.0
    return material("wood:" + name, path, rough=0.62), (im.size[0] / tpm, im.size[1] / tpm)


def tile(name):
    """A tile texture (assets/textures/<name>.png, its metres from textures.json)."""
    info = TEXTURES.get(name, {})
    metres = info.get("metres", [0.5, 0.5])
    return material("tile:" + name, os.path.join(TEX, name + ".png"), rough=0.7), tuple(metres)


TEXTURES = json.load(open(os.path.join(TEX, "textures.json")))

LOOKS = {
    # a kit look -> (material, repeat) maker
    "wood:int_oak_light": lambda: wood("int_oak_light"),
    "wood:dark_oak": lambda: wood("dark_oak"),
    "wood:floor": lambda: wood("int_floor"),
    "wood:framing": lambda: wood("int_timber"),
    "wood:dark_trim": lambda: wood("dark_trim"),
    "prop:dark_wood": lambda: wood("dark_trim"),
    "prop:mid_wood": lambda: wood("int_oak"),
    "prop:felt": lambda: tile("prop_felt"),
    "prop:gilt": lambda: (material("gilt", colour=(0.55, 0.38, 0.12), rough=0.35, spec=0.8), (1, 1)),
}


def look(name, default="prop:mid_wood"):
    return LOOKS.get(name or default, LOOKS[default])()


# ---------------------------------------------------------------- meshes


def _uv_box(bm, size, rep, grain=None):
    """UVs for a box's faces in metres over the texture's repeat, the grain (u) along the box's
    longest side in each face's plane (boards run along a member), or `grain` (0/1/2) if given."""
    uv = bm.loops.layers.uv.verify()
    for f in bm.faces:
        n = f.normal
        a = max(range(3), key=lambda i: abs(n[i]))
        axes = [i for i in range(3) if i != a]
        if grain in axes:
            u_ax = grain
        else:
            u_ax = max(axes, key=lambda i: size[i])
        v_ax = axes[0] if axes[1] == u_ax else axes[1]
        for lp in f.loops:
            co = lp.vert.co
            lp[uv].uv = (co[u_ax] / rep[0], co[v_ax] / rep[1])


def box(name, size, at, mat_rep, rot=(0, 0, 0), grain=None, parent=None):
    """A box `size` (x, y, z) centred at `at`, turned by `rot` (degrees XYZ)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    bm.normal_update()
    # UVs in the object's space so the texture keeps its metres.
    _uv_box(bm, size, mat_rep[1], grain)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    me.materials.append(mat_rep[0])
    ob = bpy.data.objects.new(name, me)
    ob.location = at
    ob.rotation_euler = [math.radians(r) for r in rot]
    if parent:
        ob.parent = parent
    bpy.context.scene.collection.objects.link(ob)
    return ob


def lathe(name, profile, segments, at, mat, parent=None, smooth=True, cap=True):
    """A turned shape: `profile` [(radius, height), ...] spun about Z."""
    bm = bmesh.new()
    rings = []
    for r, h in profile:
        ring = []
        for i in range(segments):
            a = 2 * math.pi * i / segments
            ring.append(bm.verts.new((r * math.cos(a), r * math.sin(a), h)))
        rings.append(ring)
    uv = bm.loops.layers.uv.verify()
    for k in range(len(rings) - 1):
        for i in range(segments):
            j = (i + 1) % segments
            f = bm.faces.new((rings[k][i], rings[k][j], rings[k + 1][j], rings[k + 1][i]))
            for lp, (u, v) in zip(f.loops, ((i, k), (i + 1, k), (i + 1, k + 1), (i, k + 1))):
                lp[uv].uv = (u / segments, v / len(rings))
    if cap:
        for ring in (rings[0], rings[-1]):
            if ring[0].co.xy.length > 1e-4:
                try:
                    bm.faces.new(ring if ring is rings[-1] else list(reversed(ring)))
                except ValueError:
                    pass
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    ob.location = at
    if parent:
        ob.parent = parent
    bpy.context.scene.collection.objects.link(ob)
    return ob


def empty(name, at=(0, 0, 0), yaw=0.0):
    ob = bpy.data.objects.new(name, None)
    ob.location = at
    ob.rotation_euler = (0, 0, math.radians(yaw))
    bpy.context.scene.collection.objects.link(ob)
    return ob


def g2b(v):
    """Godot (x, y up, z) -> Blender (x, -z, y)."""
    return Vector((v[0], -v[2], v[1]))


# ---------------------------------------------------------------- kit props


def kit_prop(kid, at, yaw=0.0, skip=()):
    """A kit prop (assets/props/kit/<kid>.json) as boxes: each member its box, lathes turned,
    repeats laid out. Faces +Y (the kit's +Z) at yaw 0."""
    spec = json.load(open(os.path.join(KIT, kid + ".json")))
    root = empty(kid, at, yaw)
    base = spec.get("look")
    discs = set()
    for m in spec.get("members", []):
        if m["id"] in skip:
            continue
        reps = [(m["id"], m["at"], m.get("rot", [0, 0, 0]))]
        rep = m.get("repeat")
        if rep:
            reps = []
            for i in range(int(rep["count"])):
                if "radius" in rep:
                    a = rep.get("start", 0.0) + 360.0 * i / rep["count"]
                    r = Matrix.Rotation(math.radians(a), 3, "Y")
                    p = Vector(m["at"]) + r @ Vector((0, 0, rep["radius"]))
                    rot = list(m.get("rot", [0, 0, 0]))
                    rot[1] += a
                    reps.append((m["id"].replace("%d", str(i)), p, rot))
                else:
                    p = Vector(m["at"]) + Vector(rep["step"]) * i
                    reps.append((m["id"].replace("%d", str(i)), p, m.get("rot", [0, 0, 0])))
        lk = look(m.get("look") or base)
        draw = m.get("draw", {})
        for mid, p, rot in reps:
            shape = draw.get("shape")
            if shape == "lathe":
                prof = [(r, h) for r, h in draw["profile"]]
                ob = lathe(mid, prof, int(draw.get("segments", 12)) * 2, (0, 0, 0), lk[0], parent=root)
                ob.location = g2b(p) - Vector((0, 0, p[1]))
                continue
            if shape in ("disc",):
                # A disc cut from the member's box is part of one round top about the prop's axis:
                # made once, whole.
                rad = draw["radius"]
                key = (rad, round(p[1], 4))
                if key in discs:
                    continue
                discs.add(key)
                p = Vector((0.0, p[1], 0.0))
                ob = lathe(mid, [(0.0, -m["size"][1] / 2), (rad, -m["size"][1] / 2), (rad, m["size"][1] / 2),
                                 (0.0, m["size"][1] / 2)], 64, g2b(p), lk[0], parent=root, smooth=False)
                for d in m.get("dress", []):
                    dl = look(d.get("look"))
                    above = d["draw"].get("above", 0.004)
                    dr = d["draw"]["radius"]
                    lathe(mid + "_dress", [(0.0, 0.0), (dr, 0.0), (dr, above), (0.0, above)], 64,
                          g2b(p) + Vector((0, 0, m["size"][1] / 2)), dl[0], parent=root, smooth=False)
                continue
            if shape == "sweep":
                continue
            size = m["size"]
            box(mid, (size[0], size[2], size[1]), g2b(p), lk, rot=(rot[0], -rot[2], rot[1]), parent=root)
    return root


# ---------------------------------------------------------------- the room


def build_room():
    floor = wood("int_floor")
    walls = wood("int_boards")
    trim = wood("dark_trim")
    timber = wood("int_timber")
    x0, x1 = ROOM_X
    y0, y1 = ROOM_Y
    w, d = x1 - x0, y1 - y0
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    box("floor", (w, d, 0.05), (cx, cy, -0.025), floor, grain=1)
    box("ceiling", (w, d, 0.05), (cx, cy, ROOM_H + 0.025), walls, grain=0)
    # Side and back walls, boards running along.
    box("wall_back", (w, 0.08, ROOM_H), (cx, y0 - 0.04, ROOM_H / 2), walls, grain=0)
    box("wall_left", (0.08, d, ROOM_H), (x0 - 0.04, cy, ROOM_H / 2), walls, grain=1)
    box("wall_right", (0.08, d, ROOM_H), (x1 + 0.04, cy, ROOM_H / 2), walls, grain=1)
    # The front wall with the door's opening and a window either side.
    dl, dr = DOOR_X
    box("front_l", (dl - x0, 0.08, ROOM_H), ((x0 + dl) / 2, y1 + 0.04, ROOM_H / 2), walls, grain=0)
    box("front_r", (x1 - dr, 0.08, ROOM_H), ((dr + x1) / 2, y1 + 0.04, ROOM_H / 2), walls, grain=0)
    box("front_over", (dr - dl, 0.08, ROOM_H - DOOR_H), ((dl + dr) / 2, y1 + 0.04, (DOOR_H + ROOM_H) / 2),
        walls, grain=0)
    box("door_head", (dr - dl + 0.3, 0.14, 0.16), ((dl + dr) / 2, y1 - 0.02, DOOR_H + 0.08), trim, grain=0)
    for sx in (dl - 0.08, dr + 0.08):
        box("door_jamb", (0.16, 0.14, DOOR_H), (sx, y1 - 0.02, DOOR_H / 2), trim, grain=2)
    # Batwing doors half open.
    for i, (hx, yaw) in enumerate(((dl, -35.0), (dr, 215.0))):
        hinge = empty("batwing_%d" % i, (hx, y1 - 0.05, 0.0), yaw)
        bw = (dr - dl) / 2 - 0.02
        box("batwing_%d_panel" % i, (bw, 0.035, 0.95), (bw / 2, 0, 1.3), trim, grain=0, parent=hinge)
    # Wainscot and a chair rail along the walls.
    for name, size, at, g in (("wains_l", (0.04, d, 1.0), (x0 + 0.02, cy, 0.5), 1),
                              ("wains_r", (0.04, d, 1.0), (x1 - 0.02, cy, 0.5), 1),
                              ("wains_b", (w, 0.04, 1.0), (cx, y0 + 0.02, 0.5), 0)):
        box(name, size, at, timber, grain=g)
    for name, size, at, g in (("rail_l", (0.07, d, 0.08), (x0 + 0.05, cy, 1.02), 1),
                              ("rail_r", (0.07, d, 0.08), (x1 - 0.05, cy, 1.02), 1),
                              ("rail_b", (w, 0.07, 0.08), (cx, y0 + 0.05, 1.02), 0)):
        box(name, size, at, trim, grain=g)
    # Ceiling beams and posts.
    for i in range(7):
        y = y0 + 1.5 + i * 2.6
        box("beam_%d" % i, (w, 0.22, 0.28), (cx, y, ROOM_H - 0.14), timber, grain=0)
    for px, py in ((-3.0, 5.0), (2.0, 5.0), (-3.0, 11.2), (2.0, 11.2)):
        box("post", (0.2, 0.2, ROOM_H), (px, py, ROOM_H / 2), timber, grain=2)
    build_balcony(timber, trim, floor)
    # The moonlit street beyond the doors: a dark blue backdrop lit by the moon.
    street = material("street_night", colour=(0.012, 0.016, 0.03), rough=1.0,
                      emit=(0.05, 0.07, 0.14), emit_strength=0.08)
    box("street_backdrop", (14, 0.1, 8), (cx, y1 + 9.0, 3.0), (street, (1, 1)))
    box("street_ground", (14, 9, 0.05), (cx, y1 + 4.5, -0.03), (material("street_dirt", colour=(0.05, 0.05, 0.06),
                                                                       rough=1.0), (1, 1)))
    moon = material("moon", colour=(1, 1, 1), emit=(0.85, 0.9, 1.0), emit_strength=6.0)
    lathe("moon_disc", [(0.0, 0.0), (0.45, 0.0), (0.45, 0.02), (0.0, 0.02)], 32, (0, 0, 0), moon, smooth=False)
    m = bpy.data.objects["moon_disc"]
    m.location = (dl + 0.6, y1 + 8.9, 4.2)
    m.rotation_euler = (math.radians(90), 0, 0)


def build_balcony(timber, trim, floor):
    x0, x1 = ROOM_X
    y1 = ROOM_Y[1]
    depth = y1 - BALCONY_Y
    box("balcony_floor", (x1 - x0, depth, 0.18), ((x0 + x1) / 2, (BALCONY_Y + y1) / 2, BALCONY_Z - 0.09),
        floor, grain=0)
    box("balcony_fascia", (x1 - x0, 0.06, 0.3), ((x0 + x1) / 2, BALCONY_Y, BALCONY_Z - 0.15), trim, grain=0)
    box("balcony_handrail", (x1 - x0, 0.08, 0.06), ((x0 + x1) / 2, BALCONY_Y, BALCONY_Z + 1.0), trim, grain=0)
    n = int((x1 - x0) / 0.14)
    for i in range(n):
        x = x0 + 0.07 + i * 0.14
        box("baluster", (0.035, 0.035, 0.95), (x, BALCONY_Y, BALCONY_Z + 0.5), timber, grain=2)
    for px in (-4.5, -1.5, 1.5, 4.5):
        box("balcony_post", (0.18, 0.18, BALCONY_Z), (px, BALCONY_Y, BALCONY_Z / 2), timber, grain=2)


# ---------------------------------------------------------------- dressing


def build_bar():
    # The bar runs along +X's wall, facing into the room (-X); the back bar behind it on the wall.
    for i, y in enumerate((5.2, 8.2, 11.2)):
        kit_prop("bar", (3.9, y, 0.0), yaw=-90.0)
        kit_prop("back_bar", (5.75, y, 0.0), yaw=-90.0)
    # The mirror over the back bar: dark glass catching the lamps.
    mirror = material("mirror", colour=(0.3, 0.28, 0.24), rough=0.06, spec=1.0)
    mirror.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 1.0
    box("mirror", (0.02, 7.0, 1.4), (5.93, 8.2, 2.0), (mirror, (1, 1)))
    box("mirror_frame", (0.04, 7.3, 1.7), (5.95, 8.2, 2.0), wood("dark_trim"), grain=1)
    # Bottles on the back bar and shelf.
    rng = Rand(7)
    for k in range(70):
        y = 4.9 + rng.f() * 6.6
        z = 0.95 if k < 40 else 1.32
        x = 5.62 + rng.f() * 0.15
        bottle("bbottle_%d" % k, (x, y, z), rng)
    box("back_shelf", (0.3, 7.0, 0.04), (5.72, 8.2, 1.3), wood("int_oak_light"), grain=1)
    # Stools.
    for k in range(6):
        kit_prop("bar_stool", (3.2, 4.4 + k * 1.3, 0.0))


class Rand:
    def __init__(self, seed):
        self.s = seed

    def f(self):
        self.s = (self.s * 1103515245 + 12345) & 0x7FFFFFFF
        return self.s / 0x7FFFFFFF


def bottle(name, at, rng=None, scale=1.0, colour=None):
    tint = colour or [(0.10, 0.05, 0.02), (0.05, 0.09, 0.03), (0.14, 0.07, 0.02), (0.06, 0.04, 0.03)][
        int((rng.f() if rng else 0) * 4) % 4]
    glass = material("bottle_%s" % (tuple(round(c, 2) for c in tint),), colour=tint, rough=0.05, spec=0.9,
                     transmission=0.6)
    s = scale
    prof = [(0.0, 0.0), (0.038 * s, 0.0), (0.04 * s, 0.01 * s), (0.04 * s, 0.19 * s), (0.03 * s, 0.22 * s),
            (0.013 * s, 0.25 * s), (0.012 * s, 0.30 * s), (0.0, 0.30 * s)]
    return lathe(name, prof, 16, at, glass)


def oil_lamp(name, at, power=35.0, chimney=True):
    """The table's oil lamp: brass foot, glass chimney, a flame that lights the room."""
    brass = material("brass", colour=(0.55, 0.38, 0.14), rough=0.35, spec=0.8)
    brass.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.9
    root = empty(name, at)
    lathe(name + "_foot", [(0.0, 0.0), (0.07, 0.0), (0.07, 0.012), (0.03, 0.03), (0.06, 0.06), (0.065, 0.1),
                           (0.03, 0.13), (0.02, 0.15), (0.0, 0.15)], 24, (0, 0, 0), brass, parent=root)
    if chimney:
        glass = material("chimney", colour=(0.95, 0.9, 0.8), rough=0.02, spec=0.8, transmission=0.95)
        lathe(name + "_chimney", [(0.025, 0.15), (0.045, 0.2), (0.042, 0.24), (0.025, 0.3), (0.024, 0.37)], 24,
              (0, 0, 0), glass, parent=root, cap=False)
    flame = material("flame", colour=(1, 0.6, 0.2), emit=(1.0, 0.55, 0.18), emit_strength=60.0)
    lathe(name + "_flame", [(0.0, 0.155), (0.007, 0.165), (0.006, 0.185), (0.0, 0.2)], 12, (0, 0, 0), flame,
          parent=root)
    light = bpy.data.lights.new(name + "_light", "POINT")
    light.energy = power
    light.color = LAMP_RGB
    light.shadow_soft_size = 0.02
    lo = bpy.data.objects.new(name + "_light", light)
    lo.location = (0, 0, 0.19)
    lo.parent = root
    bpy.context.scene.collection.objects.link(lo)
    return root


def hanging_lamp(name, at, power=60.0):
    iron = material("iron", colour=(0.06, 0.055, 0.05), rough=0.5)
    root = empty(name, at)
    box(name + "_rod", (0.015, 0.015, ROOM_H - at[2]), (0, 0, (ROOM_H - at[2]) / 2), (iron, (1, 1)), parent=root)
    oil_lamp(name + "_lamp", (0, 0, -0.18), power=power).parent = root
    shade = material("shade", colour=(0.55, 0.5, 0.42), rough=0.6)
    lathe(name + "_shade", [(0.06, 0.25), (0.3, 0.08), (0.31, 0.06)], 32, (0, 0, -0.18), shade, parent=root,
          cap=False)
    return root


def sconce(name, at, facing, power=150.0):
    root = empty(name, at, facing)
    brass = material("brass")
    box(name + "_plate", (0.12, 0.02, 0.22), (0, 0.0, 0), (brass, (1, 1)), parent=root)
    oil_lamp(name + "_lamp", (0, 0.14, -0.12), power=power).parent = root
    return root


def build_dressing():
    build_bar()
    # Lamps: three hanging down the room, sconces on the side walls.
    for k, (x, y) in enumerate(((-0.6, 10.5), (-0.6, 5.0), (1.5, 13.0))):
        hanging_lamp("hang_%d" % k, (x, y, 3.3), power=400.0)
    for k, y in enumerate((3.0, 7.0, 11.0, 15.0)):
        sconce("sconce_l%d" % k, (ROOM_X[0] + 0.05, y, 2.1), -90.0)
    for k, y in enumerate((2.8, 14.0, 16.8)):
        sconce("sconce_r%d" % k, (ROOM_X[1] - 0.05, y, 2.1), 90.0)
    # The piano by the left wall, other tables about the room.
    kit_prop("upright_piano", (ROOM_X[0] + 0.45, 12.5, 0.0), yaw=90.0)
    for k, (x, y, yaw) in enumerate(((-3.6, 4.2, 20), (1.6, 3.4, -10), (-4.0, 15.6, 5), (1.0, 15.2, 40))):
        kit_prop("card_table", (x, y, 0.0), yaw)
        for c in range(3):
            a = math.radians(yaw + 60 + c * 120)
            kit_prop("chair", (x + 0.75 * math.sin(a), y - 0.75 * math.cos(a), 0.0), yaw + c * 120)
        oil_lamp("tlamp_%d" % k, (x + 0.1, y + 0.1, TABLE_TOP), power=60.0)
    # The haze: lamp smoke hanging in the room.
    haze = bpy.data.materials.new("haze")
    haze.use_nodes = True
    nt = haze.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = 0.006
    vol.inputs["Anisotropy"].default_value = 0.45
    vol.inputs["Color"].default_value = (0.9, 0.85, 0.78, 1)
    nt.links.new(vol.outputs["Volume"], nt.nodes["Material Output"].inputs["Volume"])
    hz = box("haze", (ROOM_X[1] - ROOM_X[0] - 0.2, ROOM_Y[1] - ROOM_Y[0] - 0.2, ROOM_H - 0.1),
             (0, 9.0, ROOM_H / 2), (haze, (1, 1)))
    hz.visible_shadow = False


# ---------------------------------------------------------------- the card table


def build_card_table():
    kit_prop("card_table", tuple(TABLE), 0.0)
    oil_lamp("table_lamp", (TABLE.x + 0.08, TABLE.y + 0.12, TABLE_TOP), power=120.0)
    bottle("table_bottle", (TABLE.x + 0.36, TABLE.y - 0.05, TABLE_TOP), colour=(0.16, 0.08, 0.02))
    tin = material("tin", colour=(0.42, 0.4, 0.37), rough=0.35, spec=0.7)
    tin.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.85
    for k, (dx, dy) in enumerate(((-0.12, -0.38), (-0.4, 0.05), (0.3, 0.35), (0.42, -0.2))):
        lathe("cup_%d" % k, [(0.0, 0.0), (0.038, 0.0), (0.042, 0.095), (0.039, 0.095), (0.035, 0.004),
                             (0.0, 0.004)], 20, (TABLE.x + dx, TABLE.y + dy, TABLE_TOP), tin)
    # Cards and coins.
    card = material("card", colour=(0.78, 0.74, 0.64), rough=0.55)
    back = material("card_back", colour=(0.32, 0.06, 0.05), rough=0.5)
    gold = material("coin", colour=(0.6, 0.45, 0.15), rough=0.3, spec=0.9)
    gold.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 1.0
    rng = Rand(11)
    for k in range(14):
        a = rng.f() * 6.28
        r = 0.1 + rng.f() * 0.25
        ob = box("card_%d" % k, (0.063, 0.088, 0.0008), (TABLE.x + r * math.cos(a), TABLE.y + r * math.sin(a),
                                                      TABLE_TOP + 0.006 + k * 0.0009), (card if k % 3 else back, (1, 1)))
        ob.rotation_euler.z = rng.f() * 6.28
    for k in range(18):
        a = rng.f() * 6.28
        r = 0.2 + rng.f() * 0.22
        ob = lathe("coin_%d" % k, [(0.0, 0.0), (0.012, 0.0), (0.012, 0.0022), (0.0, 0.0022)], 16,
                   (TABLE.x + r * math.cos(a), TABLE.y + r * math.sin(a), TABLE_TOP + 0.005 + (k % 4) * 0.0023),
                   gold, smooth=False)


# ---------------------------------------------------------------- the men

SEATS = {
    # who: (model, where his chair is relative to the table, the way he faces (degrees from +Y))
    "player": ("sean_s3_talking", Vector((0.0, -0.78, 0.0)), 0.0),
    "stranger": ("bold_cowboy_s3_talking", Vector((-0.74, 0.12, 0.0)), -100.0),
    "cheater": ("young_drifter_s3_talking", Vector((0.14, 0.78, 0.0)), 180.0),
    "lyle": ("hothead_lyle_s2_talking", Vector((0.74, 0.06, 0.0)), 95.0),
}


def man(who, model):
    """Import a Studio man (his glTF), dress his meshes in his textures (assets/people/<model>_<shape>.png,
    or his `textures_from`'s), and return his armature."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, model + ".glb"))
    new = [o for o in bpy.data.objects if o not in before]
    report = json.load(open(os.path.join(PEOPLE, model + ".json")))
    src = report.get("textures_from", model)
    arm = next(o for o in new if o.type == "ARMATURE")
    arm.name = who
    for o in new:
        if o.type != "MESH":
            continue
        base = o.name.split(".")[0]
        if not (base.startswith("body_") or base.startswith("cloth_")):
            o.hide_render = True    # the importer's own helpers (a bone shape's icosphere)
            o.hide_viewport = True
            continue
        shape = base.replace("body_", "").replace("cloth_", "")
        if shape == "bandana_mask":
            o.hide_render = True
            continue
        path = os.path.join(PEOPLE, "%s_%s.png" % (model, shape))
        if not os.path.exists(path):
            path = os.path.join(PEOPLE, "%s_%s.png" % (src, shape))
        rough = 0.75 if shape in ("skin", "head") else 0.85
        mat = material("%s:%s" % (model, shape), path, rough=rough, closest=True, spec=0.2)
        o.data.materials.clear()
        o.data.materials.append(mat)
        o.name = "%s_%s" % (who, shape)
        for p in o.data.polygons:
            p.use_smooth = True
    return arm


def face(arm, **keys):
    """Set his face's shape keys (jaw_open, smile_l, brows_up, scowl, squint, look_left ...)."""
    for o in arm.children:
        if o.type == "MESH" and o.data.shape_keys:
            for k, v in keys.items():
                kb = o.data.shape_keys.key_blocks.get(k)
                if kb:
                    kb.value = v


def _bone_ref(pb):
    """A bone's pointing reference: its first child's head, or its tail."""
    if pb.children:
        return pb.children[0].head
    return pb.tail


def aim(arm, bone, direction):
    """Turn `bone` (pose, in place) so it points along `direction` (world), by the least turn."""
    pb = arm.pose.bones.get(bone)
    if pb is None:
        return
    bpy.context.view_layer.update()
    m3 = arm.matrix_world.to_3x3()
    cur = m3 @ (_bone_ref(pb) - pb.head)
    want = Vector(direction).normalized()
    q = cur.rotation_difference(want)
    # The turn in armature space, about his head.
    inv = m3.inverted()
    qa = (inv @ q.to_matrix() @ m3)
    head = pb.head.copy()
    mat = Matrix.Translation(head) @ qa.to_4x4() @ Matrix.Translation(-head) @ pb.matrix
    pb.matrix = mat
    bpy.context.view_layer.update()


def turn(arm, bone, axis, degrees):
    """Turn `bone` about a world axis through its head (twists, tilts)."""
    pb = arm.pose.bones.get(bone)
    if pb is None:
        return
    bpy.context.view_layer.update()
    m3 = arm.matrix_world.to_3x3()
    q = Quaternion(Vector(axis), math.radians(degrees))
    qa = m3.inverted() @ q.to_matrix() @ m3
    head = pb.head.copy()
    pb.matrix = Matrix.Translation(head) @ qa.to_4x4() @ Matrix.Translation(-head) @ pb.matrix
    bpy.context.view_layer.update()


def place_on(arm, point, yaw):
    """Turn him to face `yaw` (degrees from +Y, about Z) and move him so his pelvis is at `point`."""
    # The Studio men face +Y here at no turn (checked in the [debug] views).
    arm.rotation_mode = "XYZ"
    arm.rotation_euler = (0.0, 0.0, math.radians(yaw))
    bpy.context.view_layer.update()
    pel = arm.matrix_world @ arm.pose.bones["pelvis"].head
    arm.location += Vector(point) - pel
    bpy.context.view_layer.update()


def facing(yaw):
    a = math.radians(yaw)
    return Vector((-math.sin(a), math.cos(a), 0.0))


def seat(who, lean=0.15, arms="table", head_turn=0.0, head_tilt=0.0):
    """Sit him in his chair at the card table: thighs forward, shins down, forearms on the table."""
    model, off, yaw = SEATS[who]
    arm = man(who, model)
    chair_at = TABLE + off
    kit_prop("chair", tuple(chair_at), yaw + 180.0)
    f = facing(yaw)
    side = f.cross(Vector((0, 0, 1)))   # his right
    place_on(arm, (0, 0, 0), yaw)
    up = Vector((0, 0, 1))
    for b in ("thigh_l", "thigh_r"):
        aim(arm, b, f + up * -0.08)
    for b in ("shin_l", "shin_r"):
        aim(arm, b, -up + f * 0.12)
    for b in ("foot_l", "foot_r"):
        aim(arm, b, f - up * 0.25)
    aim(arm, "abdomen", up + f * lean)
    aim(arm, "chest", up + f * (lean + 0.1))
    aim(arm, "neck", up + f * 0.05)
    if arms == "table":
        for s, b in ((1, "r"), (-1, "l")):
            aim(arm, "upper_arm_" + b, -up * 0.85 + f * 0.55 + side * 0.08 * s)
            aim(arm, "forearm_" + b, f + side * -0.45 * s + up * 0.05)
            aim(arm, "hand_" + b, f + side * -0.3 * s - up * 0.15)
    if head_turn:
        turn(arm, "head", up, head_turn)
    if head_tilt:
        turn(arm, "head", side, head_tilt)
    # His seat on the chair's: the pelvis a little above and forward of the seat's centre.
    place_on(arm, chair_at + f * 0.04 + Vector((0, 0, 0.56)), yaw)
    return arm


def stand(who, model, at, yaw, pose=None):
    arm = man(who, model)
    arm.rotation_mode = "XYZ"
    arm.rotation_euler = (0.0, 0.0, math.radians(yaw))
    arm.location = Vector(at)
    bpy.context.view_layer.update()
    if pose:
        pose(arm, facing(yaw))
    return arm


def area(name, at, target, power, size, rgb):
    """A film light: an area lamp aimed at `target`, not seen by the camera."""
    lt = bpy.data.lights.new(name, "AREA")
    lt.energy = power
    lt.size = size
    lt.color = rgb
    ob = bpy.data.objects.new(name, lt)
    ob.location = at
    ob.rotation_euler = (Vector(target) - Vector(at)).to_track_quat("-Z", "Y").to_euler()
    ob.visible_camera = False
    bpy.context.scene.collection.objects.link(ob)
    return ob


def face_lights(arm):
    """The lamp's light on his face, a little stronger than the lamp gives (a film's key from the
    lamp's side), and a cool edge from the moon behind him."""
    h = head_of(arm)
    lamp = TABLE + Vector((0.08, 0.12, TABLE_TOP + 0.2))
    to = (h - lamp)
    area(arm.name + "_key", lamp + to * 0.35, h, 2.2, 0.3, LAMP_RGB)
    back = h - (lamp - h).normalized() * 1.2 + Vector((0, 0, 0.9))
    area(arm.name + "_rim", back, h, 6.0, 0.5, MOON_RGB)


def build_cast():
    cast = {}
    cast["player"] = seat("player", lean=0.25, head_tilt=8.0)
    cast["stranger"] = seat("stranger", lean=0.3, head_turn=-18.0)
    cast["cheater"] = seat("cheater", lean=0.2)
    cast["lyle"] = seat("lyle", lean=0.35, head_turn=12.0)
    face(cast["cheater"], smile_l=0.75, brows_up=0.2)
    face(cast["lyle"], scowl=0.5, brows_down=0.45)
    face(cast["stranger"], brows_down=0.15)

    def lean_on_bar(arm, f):
        up = Vector((0, 0, 1))
        side = f.cross(up)
        aim(arm, "upper_arm_r", -up * 0.6 + f * 0.7 + side * 0.2)
        aim(arm, "forearm_r", f - side * 0.3)
        aim(arm, "upper_arm_l", -up * 0.6 + f * 0.7 - side * 0.2)
        aim(arm, "forearm_l", f + side * 0.3)

    for who in ("player", "stranger", "cheater", "lyle"):
        face_lights(cast[who])

    cast["barkeep"] = stand("barkeep", "barkeep_s2_talking", (4.7, 8.9, 0.0), 90.0, lean_on_bar)
    cast["rancher"] = stand("rancher", "old_rancher_s3_talking", (3.25, 11.6, 0.0), -95.0, lean_on_bar)
    cast["miner"] = stand("miner", "miner_s4_talking", (-3.9, 14.5, 0.0), 160.0)
    return cast


# ---------------------------------------------------------------- shots


def camera(name, eye, target, lens=50.0, focus=None, fstop=2.0):
    cam = bpy.data.cameras.new(name)
    cam.lens = lens
    cam.sensor_width = 36.0
    cam.dof.use_dof = True
    cam.dof.aperture_fstop = fstop
    ob = bpy.data.objects.new(name, cam)
    ob.location = eye
    d = Vector(target) - Vector(eye)
    ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam.dof.focus_distance = (Vector(focus) - Vector(eye)).length if focus else d.length
    bpy.context.scene.collection.objects.link(ob)
    return ob


def head_of(arm):
    bpy.context.view_layer.update()
    pb = arm.pose.bones["head"]
    return arm.matrix_world @ (pb.head + (pb.tail - pb.head) * 0.45)


def shots(cast):
    """The look test's four stills (the shot list's numbers in docs/briefs/cinematic.md)."""
    st = head_of(cast["stranger"])
    ch = head_of(cast["cheater"])
    ly = head_of(cast["lyle"])
    pl = head_of(cast["player"])
    out = {}
    # 2: over your shoulder at the stranger, your hat and shoulder soft in the foreground.
    out["ots"] = camera("ots", pl + Vector((-0.38, -0.72, -0.08)), st + Vector((0.08, 0.0, -0.1)), lens=45,
                        focus=st, fstop=2.0)
    # 4: the cheater's smirk, close, the lamp's flame soft in front.
    out["cheater"] = camera("cheater", ch + Vector((-0.45, -1.75, -0.12)), ch + Vector((0, 0, -0.16)), lens=75,
                            focus=ch, fstop=2.2)
    # 5: Lyle's eyes lift.
    out["lyle"] = camera("lyle", ly + Vector((-1.7, 0.55, -0.14)), ly + Vector((0, 0, -0.14)), lens=75, focus=ly,
                         fstop=2.2)
    # 3: the room, slow push down it: the table, the bar, the balcony, the moon in the door.
    out["room"] = camera("room", Vector((-1.4, 2.6, 2.3)), Vector((-0.2, 12.0, 1.1)), lens=30,
                         focus=TABLE + Vector((0, 0, 1)), fstop=4.0)
    return out


# ---------------------------------------------------------------- render


def setup_render(fast=False):
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48 if fast else 160
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 6
    sc.cycles.volume_bounces = 1
    sc.cycles.volume_step_rate = 4.0 if fast else 2.0
    sc.render.resolution_x = 1920
    sc.render.resolution_y = 804      # 2.39:1, the letterbox is the frame
    sc.render.resolution_percentage = 50 if fast else 67
    sc.render.film_transparent = False
    sc.render.image_settings.file_format = "PNG"
    try:
        sc.view_settings.view_transform = "AgX"
        sc.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass
    sc.view_settings.exposure = 2.0
    w = sc.world or bpy.data.worlds.new("World")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.012, 0.009, 0.007, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    # The moon through the door: a cool sun low across the room.
    sun = bpy.data.lights.new("moon", "SUN")
    sun.energy = 0.25
    sun.color = MOON_RGB
    sun.angle = math.radians(1.0)
    so = bpy.data.objects.new("moon", sun)
    so.rotation_euler = (math.radians(68), 0, math.radians(200))
    sc.collection.objects.link(so)
    # Film grain and a soft vignette come in the cut (ffmpeg), not here.


def debug_views(cast):
    """Flat-lit views to check the staging: from above, the front and the side of the table."""
    sc = bpy.context.scene
    sc.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.6, 0.6, 0.6, 1)
    sc.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    sc.cycles.samples = 12
    sc.view_settings.exposure = 0.0
    for n in ("ceiling", "haze"):
        bpy.data.objects[n].hide_render = True
    t = TABLE + Vector((0, 0, 0.8))
    out = {}
    for name, eye, lens in (("dbg_top", t + Vector((0.01, -0.3, 4.0)), 24),
                            ("dbg_front", t + Vector((0.0, -3.2, 0.5)), 35),
                            ("dbg_side", t + Vector((3.2, 0.0, 0.4)), 35),
                            ("dbg_back", t + Vector((0.0, 3.2, 0.5)), 35)):
        c = camera(name, eye, t, lens=lens, fstop=16)
        c.data.dof.use_dof = False
        out[name] = c
    for who, arm in cast.items():
        bpy.context.view_layer.update()
        hp = head_of(arm)
        print("man", who, "head", tuple(round(v, 2) for v in hp), "rot", round(math.degrees(arm.rotation_euler.z), 1),
              flush=True)
    return out


def build():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    build_room()
    build_dressing()
    build_card_table()
    cast = build_cast()
    return cast


def main():
    a = args()
    cast = build()
    setup_render(fast=bool(a.get("fast")))
    cams = shots(cast)
    if a.get("debug"):
        cams = debug_views(cast)
    if a.get("blend"):
        os.makedirs(os.path.dirname(os.path.abspath(a["blend"])), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a["blend"]))
    if a.get("stills"):
        out = os.path.abspath(a["stills"])
        os.makedirs(out, exist_ok=True)
        only = a.get("only")
        names = only.split(",") if isinstance(only, str) else list(cams)
        for n in names:
            bpy.context.scene.camera = cams[n]
            bpy.context.scene.render.filepath = os.path.join(out, n + ".png")
            bpy.ops.render.render(write_still=True)
            print("rendered", n, flush=True)


if __name__ == "__main__":
    main()
