"""The engine and tender, built in Blender by script (train step 3, docs/briefs/train.md).

An 1882 narrow-gauge 2-8-0 Consolidation after the Denver & Rio Grande's class 70 (later C-16):
3 ft gauge, 37 in drivers, 15 x 20 in cylinders (a 10 in crank), a diamond stack, a box headlight,
a wooden pilot and cab, Stephenson gear inside the frames (so nothing of the valve gear shows),
the rods outside the wheels. Its tender is a U tank round a coal space on two arch-bar trucks
(the trucks are drawn by the game, `TrainModels`).

The shapes keep step 2's walk path (`TrainCars`): the floors at 1.1 m above the rail, the cab
from 6.8 m behind the engine's front to its back, open at the gangway; the tender's tank top at
2.0 m with the coal heap sloping up to it in front, steps down behind.

Out come `assets/train/engine.glb` and `assets/train/tender.glb`: the still body as one mesh a
material, and every moving part its own node with its origin on its pivot (the wheelsets on their
axles, the rods on their pins, the crossheads on their slides), named as `engine_rig.json` lists
them; that file carries the numbers the game moves them by (`TrainModels`): axles, radii, the
crank, the main rod's length, the slide's line. Materials are named only (the game gives each its
look): iron, jacket, brass, red, wood, steel, coal, lamp, glass.

    python3 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.2.3
    ~/bpyenv/bin/python experiments/train_lab/blender/engine.py

Coordinates: written in the game's (Godot: +Y up, the front toward -Z) through `g2b`; `u` is
metres behind the car's front and becomes z = u - mid (the car's origin is midway between its
trucks, as TrainCars).
"""
import json
import math
import os
import sys

import bpy  # first: Blender's own modules come with it
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "assets", "train")

# The consist's numbers (config/train.tres): length and trucks from the front.
ENGINE_LEN, ENGINE_TRUCKS = 9.4, (1.4, 6.6)
TENDER_LEN, TENDER_TRUCKS = 6.4, (1.2, 5.2)
DECK = 1.1  # TrainCars.DECK

# The engine (D&RG class 70): drivers 37 in, crank 10 in (half the 20 in stroke).
GAUGE = 0.914
DRIVER_R = 0.47
CRANK = 0.254
DRIVERS_U = (2.95, 4.25, 5.55, 6.85)  # axles, m behind the front
MAIN = 2  # the main rod drives the third pair
PONY_U, PONY_R = 1.15, 0.30
CYL_U = (1.55, 2.3)  # the cylinders, front to back cover
CYL_Y, CYL_X, CYL_R = 0.62, 0.74, 0.25
ROD_X = 0.62  # the side rods' plane (just outside the wheels' faces)
MAIN_X = 0.69  # the main rod and crosshead's plane
MAIN_LEN = 2.6
BOILER_Y, BOILER_R = 1.75, 0.56
CAB_U = 6.8


def g2b(v):
    return Vector((v[0], -v[2], v[1]))


class Car:
    """Builds into one Blender object a node, from parts in the car's own `u` frame."""

    def __init__(self, length, trucks):
        self.length = length
        self.mid = (trucks[0] + trucks[1]) * 0.5
        self.parts = {}  # node -> {material: bmesh}
        self.origins = {}  # node -> game-space origin

    def z(self, u):
        return u - self.mid

    def bm(self, node, mat):
        self.parts.setdefault(node, {})
        if mat not in self.parts[node]:
            self.parts[node][mat] = bmesh.new()
        return self.parts[node][mat]

    def _place(self, node, mat, verts_before, bm, m):
        """Moves the verts made since `verts_before` by the game-space matrix `m`, less the node's origin."""
        o = self.origins.get(node, Vector((0, 0, 0)))
        full = Matrix.Translation(-o) @ m
        new = bm.verts[verts_before:]
        for v in new:
            v.co = full @ v.co

    def box(self, node, mat, u0, u1, x0, x1, y0, y1, bevel=0.0):
        """A box from u0..u1 (behind the front), x0..x1 across, y0..y1 up."""
        bm = self.bm(node, mat)
        bm.verts.ensure_lookup_table()
        n = len(bm.verts)
        res = bmesh.ops.create_cube(bm, size=1.0)
        sx, sy, sz = abs(x1 - x0), abs(y1 - y0), abs(u1 - u0)
        m = Matrix.Translation(Vector(((x0 + x1) / 2, (y0 + y1) / 2, self.z((u0 + u1) / 2)))) @ \
            Matrix.Diagonal(Vector((sx, sy, sz, 1.0)))
        bm.verts.ensure_lookup_table()
        self._place(node, mat, n, bm, m)
        if bevel > 0:
            bmesh.ops.bevel(bm, geom=list(res["verts"]) + [e for e in bm.edges if all(v in res["verts"] for v in e.verts)],
                            offset=min(bevel, sx * 0.45, sy * 0.45, sz * 0.45), segments=1, affect="EDGES")

    def cyl(self, node, mat, a, b, r0, r1=None, seg=20, caps=True):
        """A cylinder (or a cone) from game-space point a to b, radius r0 at a and r1 at b."""
        r1 = r0 if r1 is None else r1
        bm = self.bm(node, mat)
        bm.verts.ensure_lookup_table()
        n = len(bm.verts)
        a, b = Vector(a), Vector(b)
        d = b - a
        ln = d.length
        bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=seg, radius1=r0, radius2=r1, depth=ln)
        rot = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
        m = Matrix.Translation((a + b) * 0.5) @ rot
        bm.verts.ensure_lookup_table()
        self._place(node, mat, n, bm, m)

    def cyl_z(self, node, mat, u0, u1, x, y, r0, r1=None, seg=24, caps=True):
        """A cylinder along the car (u0 to u1) at (x, y)."""
        self.cyl(node, mat, (x, y, self.z(u0)), (x, y, self.z(u1)), r0, r1, seg, caps)

    def cyl_y(self, node, mat, u, x, y0, y1, r0, r1=None, seg=20, caps=True):
        self.cyl(node, mat, (x, y0, self.z(u)), (x, y1, self.z(u)), r0, r1, seg, caps)

    def cyl_x(self, node, mat, u, y, x0, x1, r0, r1=None, seg=20, caps=True):
        self.cyl(node, mat, (x0, y, self.z(u)), (x1, y, self.z(u)), r0, r1, seg, caps)

    def sphere(self, node, mat, centre, r, squash=1.0, seg=16, top_only=False):
        bm = self.bm(node, mat)
        bm.verts.ensure_lookup_table()
        n = len(bm.verts)
        bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=r)
        if top_only:
            for v in bm.verts[n:]:
                if v.co.z < 0:
                    v.co.z = 0
        # Blender's sphere poles on its z: lay that up (game y).
        m = Matrix.Translation(Vector(centre)) @ Matrix(((1, 0, 0, 0), (0, 0, squash, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
        bm.verts.ensure_lookup_table()
        self._place(node, mat, n, bm, m)

    def quad_prism(self, node, mat, pts, x0, x1):
        """A prism across x0..x1 of the outline `pts` [(u, y), ...] (convex, in order)."""
        bm = self.bm(node, mat)
        o = self.origins.get(node, Vector((0, 0, 0)))
        a = [bm.verts.new(Vector((x0, y, self.z(u))) - o) for u, y in pts]
        b = [bm.verts.new(Vector((x1, y, self.z(u))) - o) for u, y in pts]
        bm.faces.new(a[::-1])
        bm.faces.new(b)
        for i in range(len(pts)):
            j = (i + 1) % len(pts)
            bm.faces.new((a[i], a[j], b[j], b[i]))

    def slab(self, node, mat, u0, u1, a, b, thick):
        """A board along u0..u1 whose cross-section runs from a=(x, y) to b=(x, y), `thick` up."""
        bm = self.bm(node, mat)
        o = self.origins.get(node, Vector((0, 0, 0)))
        ring = [(a[0], a[1]), (b[0], b[1]), (b[0], b[1] + thick), (a[0], a[1] + thick)]
        f = [bm.verts.new(Vector((x, y, self.z(u0))) - o) for x, y in ring]
        k = [bm.verts.new(Vector((x, y, self.z(u1))) - o) for x, y in ring]
        bm.faces.new(f)
        bm.faces.new(k[::-1])
        for i in range(4):
            j = (i + 1) % 4
            bm.faces.new((f[j], f[i], k[i], k[j]))

    def build(self, name):
        """Every node an object (a mesh a node, its materials as slots), parented under one root."""
        root = bpy.data.objects.new(name, None)
        bpy.context.collection.objects.link(root)
        for node, mats in self.parts.items():
            me = bpy.data.meshes.new(node)
            big = bmesh.new()
            slots = []
            for mat, bm in mats.items():
                bm.normal_update()
                tmp = bpy.data.meshes.new("tmp")
                bm.to_mesh(tmp)
                for p in tmp.polygons:
                    p.material_index = len(slots)
                big.from_mesh(tmp)
                bpy.data.meshes.remove(tmp)
                slots.append(material(mat))
                bm.free()
            bmesh.ops.remove_doubles(big, verts=big.verts, dist=0.0005)
            big.to_mesh(me)
            big.free()
            for s in slots:
                me.materials.append(s)
            # Game space to Blender's: the exporter turns +Y up back again.
            me.transform(Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1))))
            for p in me.polygons:
                p.use_smooth = False
            ob = bpy.data.objects.new(node, me)
            bpy.context.collection.objects.link(ob)
            ob.parent = root
            ob.location = g2b(self.origins.get(node, Vector((0, 0, 0))))
            # Smooth the round things by angle: a weighted-normal-ish look without a modifier stack.
            me.set_sharp_from_angle(angle=math.radians(35))
        return root


_MATS = {}
COLOURS = {  # base colour, metallic, roughness (the game swaps in its own look by name)
    "iron": ((0.035, 0.035, 0.04), 0.4, 0.65),
    "jacket": ((0.13, 0.16, 0.19), 0.6, 0.4),  # Russia iron, the planished blue-grey sheet
    "brass": ((0.55, 0.38, 0.12), 0.9, 0.35),
    "red": ((0.36, 0.06, 0.03), 0.0, 0.6),
    "wood": ((0.30, 0.15, 0.06), 0.0, 0.7),
    "steel": ((0.45, 0.45, 0.46), 0.9, 0.35),
    "coal": ((0.02, 0.02, 0.02), 0.0, 0.5),
    "lamp": ((1.0, 0.8, 0.45), 0.0, 0.3),
    "glass": ((0.2, 0.25, 0.25), 0.0, 0.1),
}


def material(name):
    if name not in _MATS:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        p = m.node_tree.nodes.get("Principled BSDF")
        c, met, rough = COLOURS[name]
        p.inputs["Base Color"].default_value = (c[0], c[1], c[2], 1.0)
        p.inputs["Metallic"].default_value = met
        p.inputs["Roughness"].default_value = rough
        _MATS[name] = m
    return _MATS[name]


def wheel(car, node, u, r, x_faces, spokes=12, crank=None, counter=None, flange=0.025):
    """A wheelset: two wheels (spoked, a tyre and flange), the axle; `crank` = (x, angle) pins."""
    car.origins[node] = Vector((0.0, r, car.z(u)))
    for side in (-1, 1):
        xi, xo = x_faces[0] * side, x_faces[1] * side
        car.cyl_x(node, "steel", u, r, xi, xo, r, seg=28)  # the tyre's tread
        car.cyl_x(node, "steel", u, r, xi - 0.012 * side, xi + 0.012 * side, r + flange, seg=28)  # the flange
        hub_x = (xi + xo) * 0.5
        car.cyl_x(node, "iron", u, r, hub_x - 0.035, hub_x + 0.035, r * 0.86, seg=28)  # the rim
        car.cyl_x(node, "iron", u, r, xi, xo + 0.03 * side, r * 0.22, seg=16)  # the hub
        for k in range(spokes):
            a = 2 * math.pi * k / spokes
            p0 = Vector((hub_x, r + math.cos(a) * r * 0.2, car.z(u) + math.sin(a) * r * 0.2))
            p1 = Vector((hub_x, r + math.cos(a) * r * 0.82, car.z(u) + math.sin(a) * r * 0.82))
            car.cyl(node, "iron", p0, p1, r * 0.055, r * 0.04, seg=6)
    car.cyl_x(node, "iron", u, r, -x_faces[0], x_faces[0], 0.07, seg=12)  # the axle
    if crank:
        for side, ang in crank:
            ca, sa = math.cos(ang), math.sin(ang)
            hub_x = side * (x_faces[0] + x_faces[1]) * 0.5
            pin = Vector((side * ROD_X, r + ca * CRANK, car.z(u) + sa * CRANK))
            car.cyl(node, "steel", (side * x_faces[1], pin.y, pin.z), (pin.x + side * 0.045, pin.y, pin.z), 0.045, seg=12)
            # The crank boss, and a counterweight opposite it (a crescent's bulk as a block).
            car.cyl(node, "iron", (hub_x, pin.y, pin.z), (side * (x_faces[1] + 0.012), pin.y, pin.z), 0.08, seg=12)
            if counter:
                cw = Vector((hub_x, r - ca * r * 0.55, car.z(u) - sa * r * 0.55))
                car.cyl(node, "iron", (hub_x - 0.03 * side, cw.y, cw.z), (hub_x + 0.03 * side, cw.y, cw.z), r * 0.3, seg=14)


def engine():
    car = Car(ENGINE_LEN, ENGINE_TRUCKS)
    L = ENGINE_LEN
    z = car.z
    faces = (GAUGE / 2 - 0.035, GAUGE / 2 + 0.085)  # a wheel's inner and outer face from the middle

    # The frame: two plate bars inside the wheels, the deck under the cab, the buffer beams.
    for s in (-1, 1):
        car.box("Body", "iron", 0.9, L - 0.1, s * 0.3, s * 0.36, 0.3, 0.82)
    car.box("Body", "iron", CAB_U - 0.05, L, -1.12, 1.12, 0.65, DECK)  # the cab's floor and its sills
    car.box("Body", "wood", CAB_U, L, -1.08, 1.08, DECK - 0.03, DECK, 0.0)  # its boards
    car.box("Body", "red", L - 0.25, L, -1.0, 1.0, 0.45, 0.8, 0.02)  # the back beam
    car.box("Body", "steel", L - 0.05, L + 0.25, -0.12, 0.12, 0.55, 0.72, 0.01)  # the drawbar
    # The pilot: the beam, then wooden slats down to a point (a cowcatcher), painted red.
    car.box("Body", "red", 0.72, 0.95, -1.0, 1.0, 0.55, 0.85, 0.02)
    car.box("Body", "steel", 0.5, 0.75, -0.11, 0.11, 0.6, 0.75, 0.01)  # the coupler's pocket
    for k in range(9):
        x = -0.9 + 1.8 * k / 8
        tip = Vector((x * 0.08, 0.08, z(0.02)))
        top = Vector((x, 0.6, z(0.8)))
        car.cyl("Body", "wood", tip, top, 0.03, 0.03, seg=5)
    car.cyl("Body", "wood", (-0.95, 0.12, z(0.45)), (0.95, 0.12, z(0.45)), 0.025, seg=5)
    for s in (-1, 1):
        car.cyl("Body", "wood", (0, 0.1, z(0.02)), (s * 0.97, 0.58, z(0.8)), 0.035, seg=6)
    # The smokebox and boiler, Russia iron; the smokebox black; brass bands.
    car.cyl_z("Body", "iron", 1.28, 2.55, 0.0, BOILER_Y, 0.6, seg=32)
    car.cyl_z("Body", "iron", 1.24, 1.3, 0.0, BOILER_Y, 0.53, seg=32)  # the door
    car.cyl("Body", "steel", (0, BOILER_Y, z(1.2)), (0, BOILER_Y, z(1.25)), 0.06, seg=10)  # its dog
    car.cyl_z("Body", "jacket", 2.55, CAB_U + 0.2, 0.0, BOILER_Y, BOILER_R, seg=32)
    for u in (2.6, 3.9, 5.2, 6.5):
        car.cyl_z("Body", "brass", u - 0.03, u + 0.03, 0.0, BOILER_Y, BOILER_R + 0.012, seg=32)
    # The firebox, between the frames down to them, inside the cab's front.
    car.box("Body", "jacket", 5.9, CAB_U + 0.15, -0.36, 0.36, 0.85, BOILER_Y)
    # The saddle and the cylinders, outside the frames; the steam chests on top.
    car.box("Body", "iron", CYL_U[0] + 0.1, CYL_U[1] - 0.1, -0.62, 0.62, 0.5, 1.3)
    for s in (-1, 1):
        car.cyl_z("Body", "iron", CYL_U[0], CYL_U[1], s * CYL_X, CYL_Y, CYL_R, seg=24)
        for u in CYL_U:
            car.cyl_z("Body", "steel", u - 0.03, u + 0.03, s * CYL_X, CYL_Y, CYL_R + 0.02, seg=24)
        car.box("Body", "iron", CYL_U[0] + 0.08, CYL_U[1] - 0.08, s * 0.64, s * 0.88, CYL_Y + 0.22, CYL_Y + 0.5, 0.02)
        # The guides: two bars over and under the crosshead's path, back to a yoke at the first pair's front.
        for dy in (-0.09, 0.09):
            car.box("Body", "steel", CYL_U[1], DRIVERS_U[0] - 0.12, s * (MAIN_X - 0.03), s * (MAIN_X + 0.03),
                    CYL_Y + dy - 0.02, CYL_Y + dy + 0.02)
        car.box("Body", "iron", DRIVERS_U[0] - 0.2, DRIVERS_U[0] - 0.12, s * 0.36, s * (MAIN_X + 0.05),
                CYL_Y - 0.15, CYL_Y + 0.15)
        # The running board over the wheels, on brackets; a handrail along the boiler.
        car.box("Body", "iron", CYL_U[1], CAB_U, s * 0.62, s * 1.0, 1.12, 1.15)
        car.box("Body", "wood", CYL_U[1], CAB_U, s * 0.62, s * 1.0, 1.15, 1.17)
        car.cyl("Body", "steel", (s * 0.66, 2.05, z(1.5)), (s * 0.66, 2.05, z(CAB_U)), 0.014, seg=6)
        # Sand pipes from the dome down to the second pair.
        car.cyl("Body", "iron", (s * 0.4, 2.35, z(3.35)), (s * 0.55, 0.62, z(DRIVERS_U[1] - 0.5)), 0.018, seg=6)
    # The stack: a diamond stack on the smokebox.
    su = 1.9
    car.cyl_y("Body", "iron", su, 0.0, 2.2, 2.78, 0.17, 0.2)
    car.cyl_y("Body", "iron", su, 0.0, 2.78, 3.15, 0.2, 0.52)
    car.cyl_y("Body", "iron", su, 0.0, 3.15, 3.42, 0.52, 0.34)
    car.cyl_y("Body", "iron", su, 0.0, 3.42, 3.46, 0.36, 0.36)
    # The headlight: a box lamp on a bracket at the smokebox front, its lens lit by the game.
    car.box("Body", "iron", 1.35, 1.75, -0.18, 0.18, 2.32, 2.4)
    car.box("Body", "red", 1.15, 1.72, -0.27, 0.27, 2.4, 2.92, 0.02)
    car.box("Body", "iron", 1.12, 1.76, -0.31, 0.31, 2.92, 2.97)
    car.cyl_y("Body", "iron", 1.45, 0.0, 2.97, 3.12, 0.06)
    car.cyl("Body", "brass", (0, 2.66, z(1.16)), (0, 2.66, z(1.13)), 0.2, seg=24)
    car.cyl("Body", "lamp", (0, 2.66, z(1.135)), (0, 2.66, z(1.125)), 0.17, seg=24)
    # The domes: sand, steam (with the whistle and safety valves), the bell between.
    car.cyl_y("Body", "jacket", 3.35, 0.0, 2.1, 2.5, 0.3)
    car.sphere("Body", "jacket", (0, 2.5, z(3.35)), 0.3, 0.6, top_only=True)
    car.cyl_y("Body", "brass", 4.95, 0.0, 2.1, 2.55, 0.33)
    car.sphere("Body", "brass", (0, 2.55, z(4.95)), 0.33, 0.6, top_only=True)
    car.cyl_y("Body", "brass", 4.95, 0.0, 2.7, 2.95, 0.035)  # the whistle
    car.cyl_y("Body", "brass", 4.95, 0.0, 2.95, 3.0, 0.06)
    car.cyl_y("Body", "brass", 5.25, 0.0, 2.6, 2.82, 0.045)  # a safety valve
    car.cyl_y("Body", "iron", 4.15, 0.0, 2.25, 2.45, 0.03)  # the bell's yoke
    car.box("Body", "iron", 4.1, 4.2, -0.22, 0.22, 2.45, 2.5)
    for s in (-1, 1):
        car.box("Body", "iron", 4.12, 4.18, s * 0.2, s * 0.24, 2.3, 2.75)
    car.cyl_y("Body", "brass", 4.15, 0.0, 2.32, 2.62, 0.2, 0.12)
    # The cab: wooden walls, a window each side ahead of the gangway, two by the boiler in front,
    # an arched roof. Open behind, and its sides stop 0.75 short of the back (TrainCars: the
    # gangway), where a step hangs below.
    top = DECK + 2.1
    for s in (-1, 1):
        x0, x1 = s * 1.02, s * 1.1
        car.box("Body", "wood", CAB_U, L - 0.75, x0, x1, DECK, DECK + 1.0)  # below the windows
        car.box("Body", "wood", CAB_U, L - 0.75, x0, x1, DECK + 1.7, top)  # above
        for u0, u1 in ((CAB_U, CAB_U + 0.15), (CAB_U + 0.85, CAB_U + 1.0), (L - 0.95, L - 0.75)):
            car.box("Body", "wood", u0, u1, x0, x1, DECK + 1.0, DECK + 1.7)  # the posts
        car.box("Body", "glass", CAB_U + 0.15, CAB_U + 0.85, x0 * 0.99, x0 * 0.99 + s * 0.01, DECK + 1.0, DECK + 1.7)
        car.box("Body", "red", CAB_U, L - 0.75, s * 1.1, s * 1.12, DECK + 0.95, DECK + 1.0)  # a sill rail
        car.box("Body", "steel", L - 0.78, L - 0.72, s * 1.12, s * 1.15, DECK + 0.1, DECK + 1.5)  # a grab iron
        car.box("Body", "iron", L - 0.7, L - 0.1, s * 1.0, s * 1.22, 0.62, 0.66)  # the step
        car.box("Body", "iron", L - 0.7, L - 0.66, s * 1.18, s * 1.22, 0.62, DECK)
        car.box("Body", "iron", L - 0.14, L - 0.1, s * 1.18, s * 1.22, 0.62, DECK)
    # The cab's front: round the boiler, windows either side above it.
    fu = CAB_U
    car.box("Body", "wood", fu, fu + 0.08, -1.1, -0.6, DECK, top)
    car.box("Body", "wood", fu, fu + 0.08, 0.6, 1.1, DECK, top)
    car.box("Body", "wood", fu, fu + 0.08, -0.6, 0.6, BOILER_Y + 0.56, top)
    for s in (-1, 1):
        car.box("Body", "glass", fu + 0.03, fu + 0.05, s * 0.68, s * 1.0, DECK + 1.1, DECK + 1.7)
    # The roof: an arch of boards over the cab, past its sides.
    n = 8
    for k in range(n):
        a0 = math.radians(-60 + 120 * k / n)
        a1 = math.radians(-60 + 120 * (k + 1) / n)
        p = [(math.sin(a) * 1.35, top - 2.5 + math.cos(a) * 2.6) for a in (a0, a1)]
        car.slab("Body", "wood", CAB_U - 0.15, L + 0.08, p[0], p[1], 0.05)
    # In the cab: the backhead (a fire door, the gauges), the regulator's lever, the reverse lever.
    car.box("Body", "iron", fu + 0.08, fu + 0.14, -0.55, 0.55, DECK, BOILER_Y + 0.5)
    car.box("Body", "iron", fu + 0.12, fu + 0.2, -0.22, 0.22, DECK + 0.45, DECK + 0.85)  # the fire door
    for s, h in ((-0.3, 2.35), (0.3, 2.35), (0.0, 2.5)):
        car.cyl("Body", "brass", (s, h, z(fu + 0.14)), (s, h, z(fu + 0.2)), 0.09, seg=16)
    car.cyl("Body", "steel", (0.25, BOILER_Y + 0.4, z(fu + 0.15)), (0.55, BOILER_Y + 0.25, z(fu + 0.35)), 0.02, seg=6)
    car.cyl("Body", "steel", (0.85, DECK, z(fu + 0.7)), (0.85, DECK + 1.0, z(fu + 0.55)), 0.025, seg=6)
    # The coupler behind and the tender's drawbar is the tender's.

    # The moving parts: the pony truck's wheels; the four pairs of drivers (the right pin
    # leading the left by a quarter, the train going forward: wheels turn back over their tops).
    wheel(car, "Pony", PONY_U, PONY_R, faces, spokes=8)
    car.box("Body", "iron", PONY_U - 0.35, PONY_U + 0.35, -0.3, 0.3, 0.25, 0.4)  # its frame (still: a sketch)
    pins = ((1, 0.0), (-1, math.pi / 2))  # right at the top at rest, left a quarter on
    for k, u in enumerate(DRIVERS_U):
        wheel(car, "Driver%d" % k, u, DRIVER_R, faces, spokes=14, crank=pins, counter=True)
    # The side rods (each side one bar over the four pins) and the main rods and crossheads, at
    # the rest pose (the right pin up); origins on the main pin.
    for side, ang in pins:
        tag = "R" if side > 0 else "L"
        main_pin = Vector((side * ROD_X, DRIVER_R + math.cos(ang) * CRANK, z(DRIVERS_U[MAIN]) + math.sin(ang) * CRANK))
        node = "SideRod" + tag
        car.origins[node] = main_pin
        for a, b in zip(DRIVERS_U[:-1], DRIVERS_U[1:]):
            car.box(node, "steel", a + math.sin(ang) * CRANK, b + math.sin(ang) * CRANK, side * (ROD_X - 0.02), side * (ROD_X + 0.02), main_pin.y - 0.05, main_pin.y + 0.05, 0.008)
        for u in DRIVERS_U:
            car.cyl_x(node, "steel", u + math.sin(ang) * CRANK, main_pin.y, side * (ROD_X - 0.025), side * (ROD_X + 0.025), 0.075, seg=14)
        # The main rod lies along -Z from its pin at rest (the code turns it about X to the crosshead).
        node = "MainRod" + tag
        car.origins[node] = Vector((side * MAIN_X, main_pin.y, main_pin.z))
        mu = DRIVERS_U[MAIN] + math.sin(ang) * CRANK
        car.box(node, "steel", mu - MAIN_LEN, mu, side * (MAIN_X - 0.025), side * (MAIN_X + 0.025), main_pin.y - 0.05, main_pin.y + 0.05, 0.008)
        car.cyl_x(node, "steel", mu, main_pin.y, side * (MAIN_X - 0.03), side * (MAIN_X + 0.03), 0.085, seg=14)
        car.cyl_x(node, "steel", mu - MAIN_LEN, main_pin.y, side * (MAIN_X - 0.03), side * (MAIN_X + 0.03), 0.06, seg=12)
        # The crosshead and piston rod: origin on the wrist pin at the slide's middle.
        node = "Crosshead" + tag
        mid_u = DRIVERS_U[MAIN] - MAIN_LEN
        car.origins[node] = Vector((side * MAIN_X, CYL_Y, z(mid_u)))
        car.box(node, "steel", mid_u - 0.14, mid_u + 0.14, side * (MAIN_X - 0.05), side * (MAIN_X + 0.05), CYL_Y - 0.07, CYL_Y + 0.07, 0.01)
        car.cyl_z(node, "steel", mid_u - 0.75, mid_u - 0.1, side * MAIN_X, CYL_Y, 0.035, seg=10)
    root = car.build("Engine")
    rig = {
        "mid": car.mid, "gauge": GAUGE, "driver_r": DRIVER_R, "pony_r": PONY_R, "crank": CRANK,
        "drivers_z": [car.z(u) for u in DRIVERS_U], "pony_z": car.z(PONY_U), "main": MAIN,
        "main_len": MAIN_LEN, "rod_x": ROD_X, "main_x": MAIN_X, "slide_y": CYL_Y,
        "pins": {"R": 0.0, "L": math.pi / 2},
        "stack": [0.0, 3.46, car.z(1.9)], "cylinder_cocks": [[s * CYL_X, CYL_Y - 0.2, car.z(CYL_U[0])] for s in (-1, 1)],
        "headlight": [0.0, 2.66, car.z(1.1)], "firebox": [0.0, DECK + 0.65, car.z(CAB_U + 0.25)],
        "bell": [0.0, 2.45, car.z(4.15)], "whistle": [0.0, 3.0, car.z(4.95)],
    }
    return root, rig


def tender():
    car = Car(TENDER_LEN, TENDER_TRUCKS)
    L = TENDER_LEN
    z = car.z
    tank_top = DECK + 0.9
    # The frame and deck (the trucks are the game's), the beams, the drawbars.
    car.box("Body", "iron", 0.0, L, -1.05, 1.05, 0.65, DECK - 0.04)
    car.box("Body", "wood", -0.15, L + 0.15, -1.0, 1.0, DECK - 0.04, DECK)
    for u in (0.0, L - 0.2):
        car.box("Body", "red", u, u + 0.2, -1.0, 1.0, 0.45, 0.8, 0.02)
    car.box("Body", "steel", L - 0.05, L + 0.25, -0.12, 0.12, 0.55, 0.72, 0.01)
    # The tank: a U round the coal space in front (the sides run forward either side of it).
    flare = 0.12
    car.box("Body", "iron", 1.45, L - 1.45, -1.0, 1.0, DECK, tank_top, 0.02)
    for s in (-1, 1):
        car.box("Body", "iron", 0.2, 1.45, s * 0.86, s * 1.0, DECK, tank_top + 0.25, 0.01)  # the coal boards
        car.box("Body", "iron", 0.2, L - 1.45, s * 1.0, s * 1.03, tank_top - 0.08, tank_top)  # a bead
    car.box("Body", "iron", 1.4, 1.5, -0.86, 0.86, tank_top, tank_top + 0.2)  # the coal space's back
    # The coal: a heap up the walk's slope (TrainCars' stairs), lumps on top.
    car.quad_prism("Body", "coal", [(0.0, DECK), (1.45, DECK), (1.45, tank_top + 0.12), (0.4, DECK + 0.15)], -0.86, 0.86)
    for k in range(26):
        u = 0.25 + (k * 0.37) % 1.15
        x = -0.75 + ((k * 0.61) % 1.5)
        y = DECK + 0.15 + (u - 0.2) / 1.25 * 0.85
        car.sphere("Body", "coal", (x, y, z(u)), 0.08 + (k % 3) * 0.025, 0.7, seg=6)
    # The water hatch, a toolbox, the brake staff at the back.
    car.cyl_y("Body", "iron", 3.6, 0.0, tank_top, tank_top + 0.08, 0.32)
    car.cyl_y("Body", "steel", 3.6, 0.32, tank_top + 0.08, tank_top + 0.12, 0.05)
    car.box("Body", "wood", 2.0, 2.6, 0.45, 0.95, tank_top, tank_top + 0.3, 0.02)
    # The back: steps down from the tank top (the walk's), its brake wheel beside them.
    steps = 4
    for k in range(steps):
        u0 = L - 1.45 + (1.2 / steps) * k
        y1 = tank_top - (tank_top - DECK) * (k + 1) / steps + 0.0
        car.box("Body", "wood", u0, L - 0.25, -0.9, 0.9, DECK, max(y1 + (tank_top - DECK) / steps, DECK + 0.05))
    car.cyl_y("Body", "steel", L - 0.15, 0.85, DECK, DECK + 1.1, 0.02)
    car.cyl_y("Body", "steel", L - 0.15, 0.85, DECK + 1.08, DECK + 1.12, 0.22, seg=16)
    for s in (-1, 1):
        car.box("Body", "steel", L - 0.3, L - 0.25, s * 1.02, s * 1.06, DECK, DECK + 0.85)  # grab irons
        car.box("Body", "iron", 0.15, 0.5, s * 1.0, s * 1.2, 0.62, 0.66)  # the front steps
    root = car.build("Tender")
    return root, {"mid": car.mid}


def export(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for c in root.children_recursive:
        c.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True,
                              export_normals=True, export_texcoords=False, export_materials="EXPORT",
                              export_animations=False)


def tris(root):
    n = 0
    for o in root.children_recursive:
        if o.type == "MESH":
            n += sum(len(p.vertices) - 2 for p in o.data.polygons)
    return n


def main():
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    eng, rig = engine()
    export(eng, os.path.join(OUT, "engine.glb"))
    rig["triangles"] = tris(eng)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATS.clear()
    ten, trig = tender()
    export(ten, os.path.join(OUT, "tender.glb"))
    rig["tender"] = trig
    rig["tender"]["triangles"] = tris(ten)
    with open(os.path.join(OUT, "engine_rig.json"), "w") as f:
        json.dump(rig, f, indent=1)
    print("engine", rig["triangles"], "tris; tender", trig["triangles"])


if __name__ == "__main__":
    main()
