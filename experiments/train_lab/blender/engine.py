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
MAIN_X = 0.72  # the main rod and crosshead's plane (outside the side rods and crank pins)
MAIN_LEN = 2.6
GUIDE_END = 3.55  # the guides' yoke, between the first two pairs
BOILER_Y, BOILER_R = 1.75, 0.56
CAB_U = 6.8


def g2b(v):
    return Vector((v[0], -v[2], v[1]))


class Car:
    """Builds into one Blender object a node, from parts in the car's own `u` frame."""

    def __init__(self, length, trucks):
        self.length = length
        self.mid = (trucks[0] + trucks[1]) * 0.5
        self.parts = {}  # node -> bmesh
        self.slots = {}  # node -> its material names, in slot order
        self.pending = {}  # node -> (slot, first face) still to be given its material
        self.origins = {}  # node -> game-space origin

    def z(self, u):
        return u - self.mid

    def bm(self, node, mat):
        """The node's one bmesh; the faces made from now until the next call take `mat`."""
        self._settle(node)
        if node not in self.parts:
            self.parts[node] = bmesh.new()
            self.slots[node] = []
        if mat not in self.slots[node]:
            self.slots[node].append(mat)
        bm = self.parts[node]
        bm.faces.ensure_lookup_table()
        self.pending[node] = (self.slots[node].index(mat), len(bm.faces))
        return bm

    def _settle(self, node):
        """Gives the faces made since the last `bm` call their material."""
        if node in self.pending:
            index, first = self.pending.pop(node)
            bm = self.parts[node]
            bm.faces.ensure_lookup_table()
            for f in bm.faces[first:]:
                f.material_index = index

    def _place(self, node, verts, m):
        """Moves a primitive's verts (as its bmesh op returned them: they aren't always the last
        ones in the list) by the game-space matrix `m`, less the node's origin."""
        o = self.origins.get(node, Vector((0, 0, 0)))
        full = Matrix.Translation(-o) @ m
        for v in verts:
            v.co = full @ v.co

    def box(self, node, mat, u0, u1, x0, x1, y0, y1, bevel=0.0):
        """A box from u0..u1 (behind the front), x0..x1 across, y0..y1 up."""
        bm = self.bm(node, mat)
        res = bmesh.ops.create_cube(bm, size=1.0)
        sx, sy, sz = abs(x1 - x0), abs(y1 - y0), abs(u1 - u0)
        m = Matrix.Translation(Vector(((x0 + x1) / 2, (y0 + y1) / 2, self.z((u0 + u1) / 2)))) @ \
            Matrix.Diagonal(Vector((sx, sy, sz, 1.0)))
        self._place(node, res["verts"], m)
        # (`bevel` is kept in the calls for a later pass: bmesh.ops.bevel broke the thin boxes.)

    def cyl(self, node, mat, a, b, r0, r1=None, seg=20, caps=True):
        """A cylinder (or a cone) from game-space point a to b, radius r0 at a and r1 at b."""
        r1 = r0 if r1 is None else r1
        bm = self.bm(node, mat)
        a, b = Vector(a), Vector(b)
        d = b - a
        ln = d.length
        res = bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=seg, radius1=r0, radius2=r1, depth=ln)
        rot = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
        m = Matrix.Translation((a + b) * 0.5) @ rot
        self._place(node, res["verts"], m)

    def cyl_z(self, node, mat, u0, u1, x, y, r0, r1=None, seg=24, caps=True):
        """A cylinder along the car (u0 to u1) at (x, y)."""
        self.cyl(node, mat, (x, y, self.z(u0)), (x, y, self.z(u1)), r0, r1, seg, caps)

    def cyl_y(self, node, mat, u, x, y0, y1, r0, r1=None, seg=20, caps=True):
        self.cyl(node, mat, (x, y0, self.z(u)), (x, y1, self.z(u)), r0, r1, seg, caps)

    def cyl_x(self, node, mat, u, y, x0, x1, r0, r1=None, seg=20, caps=True):
        self.cyl(node, mat, (x0, y, self.z(u)), (x1, y, self.z(u)), r0, r1, seg, caps)

    def sphere(self, node, mat, centre, r, squash=1.0, seg=16, top_only=False):
        bm = self.bm(node, mat)
        res = bmesh.ops.create_uvsphere(bm, u_segments=seg, v_segments=seg // 2, radius=r)
        if top_only:
            for v in res["verts"]:
                if v.co.z < 0:
                    v.co.z = 0
        # Blender's sphere poles on its z: lay that up (game y).
        m = Matrix.Translation(Vector(centre)) @ Matrix(((1, 0, 0, 0), (0, 0, squash, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
        self._place(node, res["verts"], m)

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

    def _o(self, node):
        return self.origins.get(node, Vector((0, 0, 0)))

    def _rings(self, bm, rings, cap0, cap1, closed=True):
        """Joins rings of verts (each the same count) side to side; caps the first and last."""
        n = len(rings[0])
        for a, b in zip(rings[:-1], rings[1:]):
            for i in range(n if closed else n - 1):
                j = (i + 1) % n
                bm.faces.new((a[i], a[j], b[j], b[i]))
        if cap0:
            bm.faces.new(rings[0][::-1])
        if cap1:
            bm.faces.new(rings[-1])

    def ring_x(self, node, mat, u, y, x0, x1, r_in, r_out, seg=36, a0=0.0, a1=None):
        """An annulus about the X axis at (u, y), across x0..x1, from r_in to r_out (a tyre, a
        rim, a crank's web); between angles a0..a1 (from up toward the back, +Z) a crescent."""
        bm = self.bm(node, mat)
        o = self._o(node)
        zc = self.z(u)
        full = a1 is None
        a1 = a0 + 2 * math.pi if full else a1
        n = seg if full else max(2, int(round(seg * (a1 - a0) / (2 * math.pi)))) + 1
        quads = []
        for i in range(n):
            a = a0 + (a1 - a0) * i / (n if full else n - 1)
            ca, sa = math.cos(a), math.sin(a)
            quads.append([bm.verts.new(Vector((x, y + r * ca, zc + r * sa)) - o)
                          for x, r in ((x0, r_in), (x0, r_out), (x1, r_out), (x1, r_in))])
        for i in range(n if full else n - 1):
            a, b = quads[i], quads[(i + 1) % n]
            for k in range(4):
                m = (k + 1) % 4
                bm.faces.new((a[k], a[m], b[m], b[k]))
        if not full:
            bm.faces.new(quads[0][::-1])
            bm.faces.new(quads[-1])

    def lathe_y(self, node, mat, u, x, y0, profile, seg=24, rot=0.0):
        """A turned shape standing up at (u, x): `profile` [(radius, height over y0), ...] bottom
        to top; a radius of 0 closes it to a point."""
        bm = self.bm(node, mat)
        o = self._o(node)
        zc = self.z(u)
        rings = []
        for r, h in profile:
            rings.append([bm.verts.new(Vector((x + r * math.cos(rot + 2 * math.pi * i / seg), y0 + h,
                                                 zc + r * math.sin(rot + 2 * math.pi * i / seg))) - o) for i in range(seg)])
        self._rings(bm, rings, profile[0][0] > 0, profile[-1][0] > 0)

    def lathe_z(self, node, mat, x, y, profile, seg=28):
        """A turned shape lying along the car at (x, y): `profile` [(radius, u), ...] front to back."""
        bm = self.bm(node, mat)
        o = self._o(node)
        rings = []
        for r, u in profile:
            rings.append([bm.verts.new(Vector((x + r * math.cos(2 * math.pi * i / seg), y + r * math.sin(2 * math.pi * i / seg),
                                                 self.z(u))) - o) for i in range(seg)])
        self._rings(bm, rings, profile[0][0] > 0, profile[-1][0] > 0)

    def bar(self, node, mat, a, b, h0, h1, x0, x1):
        """A flat bar across x0..x1 from a=(y, u) to b=(y, u), h0 deep at a tapering to h1 at b
        (a rod: deep at the big end)."""
        bm = self.bm(node, mat)
        o = self._o(node)
        d = Vector((b[0] - a[0], self.z(b[1]) - self.z(a[1])))
        nrm = Vector((-d.y, d.x)).normalized()  # across the bar, in (y, z)
        pts = []
        for (y, u), h in ((a, h0), (b, h1)):
            for s in (-1, 1):
                pts.append((y + nrm.x * h * 0.5 * s, self.z(u) + nrm.y * h * 0.5 * s))
        f = [bm.verts.new(Vector((x0, py, pz)) - o) for py, pz in (pts[0], pts[1], pts[3], pts[2])]
        k = [bm.verts.new(Vector((x1, py, pz)) - o) for py, pz in (pts[0], pts[1], pts[3], pts[2])]
        self._rings(bm, [f, k], True, True)

    def build(self, name):
        """Every node an object (a mesh a node, its materials as slots), parented under one root."""
        root = bpy.data.objects.new(name, None)
        bpy.context.collection.objects.link(root)
        for node, big in self.parts.items():
            self._settle(node)
            me = bpy.data.meshes.new(node)
            bmesh.ops.remove_doubles(big, verts=big.verts, dist=0.0005)
            bmesh.ops.recalc_face_normals(big, faces=big.faces)
            big.to_mesh(me)
            big.free()
            for name in self.slots[node]:
                me.materials.append(material(name))
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


def wheel(car, node, u, r, spokes=12, crank=None, counter=False):
    """A wheelset as cast: on each side a tyre with its flange, the wheel centre's rim inside it,
    spokes to a hub, and on a driver the crank boss, its pin and a crescent counterweight opposite
    it between the spokes; the axle across. `crank` = ((side, angle), ...): the pin's angle from up
    toward the back (+Z) at rest."""
    car.origins[node] = Vector((0.0, r, car.z(u)))
    gx = GAUGE / 2
    xi, xo = gx - 0.035, gx + 0.085  # the tread's inner and outer faces
    rim_in = r - 0.1
    hub_r = max(0.07, r * 0.22)
    for side in (-1, 1):
        s = side
        car.ring_x(node, "steel", u, r, s * xi, s * xo, r - 0.05, r, seg=40)  # the tyre
        car.ring_x(node, "steel", u, r, s * xi, s * (xi + 0.022), r, r + 0.025, seg=40)  # its flange
        car.ring_x(node, "iron", u, r, s * (xi + 0.02), s * (xo - 0.025), rim_in, r - 0.05, seg=40)  # the rim
        car.cyl_x(node, "iron", u, r, s * (xi + 0.01), s * (xo + 0.045), hub_r, seg=20)  # the hub
        car.cyl_x(node, "steel", u, r, s * (xo + 0.045), s * (xo + 0.06), hub_r * 0.55, seg=12)  # the axle's end
        xm = s * (xi + xo) * 0.5
        for k in range(spokes):
            a = 2 * math.pi * (k + 0.5) / spokes
            ca, sa = math.cos(a), math.sin(a)
            p0 = Vector((xm, r + ca * hub_r * 0.9, car.z(u) + sa * hub_r * 0.9))
            p1 = Vector((xm, r + ca * (rim_in + 0.01), car.z(u) + sa * (rim_in + 0.01)))
            car.cyl(node, "iron", p0, p1, 0.026, 0.017, seg=6)
        if crank:
            ang = dict(crank)[side]
            if counter:  # opposite the pin, filling between the spokes from the hub's reach to the rim
                car.ring_x(node, "iron", u, r, s * (xi + 0.03), s * (xo - 0.035), hub_r * 1.6, rim_in + 0.005,
                           seg=40, a0=ang + math.pi - 0.85, a1=ang + math.pi + 0.85)
            ca, sa = math.cos(ang), math.sin(ang)
            pin = Vector((s * ROD_X, r + ca * CRANK, car.z(u) + sa * CRANK))
            # The crank boss on the wheel's face, a web to the hub, the pin out to the rods.
            car.cyl(node, "iron", (s * (xo - 0.01), pin.y, pin.z), (s * (xo + 0.03), pin.y, pin.z), 0.085, seg=16)
            mid = Vector((s * (xo + 0.01), r + ca * CRANK * 0.5, car.z(u) + sa * CRANK * 0.5))
            car.cyl(node, "iron", Vector((mid.x, r, car.z(u))), Vector((mid.x, pin.y, pin.z)), 0.06, 0.06, seg=8)
            car.cyl(node, "steel", (s * (xo + 0.03), pin.y, pin.z), (pin.x + s * 0.05, pin.y, pin.z), 0.04, seg=12)
    car.cyl_x(node, "iron", u, r, -gx, gx, 0.075, seg=12)  # the axle


def engine():
    car = Car(ENGINE_LEN, ENGINE_TRUCKS)
    L = ENGINE_LEN
    z = car.z
    top = DECK + 2.1  # the cab's eaves

    # --- The frame and running gear's fixed parts -------------------------------------------
    for s in (-1, 1):
        car.box("Body", "iron", 0.85, L - 0.1, s * 0.3, s * 0.36, 0.32, 0.82)  # the frame's plates
        for u in DRIVERS_U:
            car.box("Body", "iron", u - 0.12, u + 0.12, s * 0.27, s * 0.4, DRIVER_R - 0.13, DRIVER_R + 0.13)  # axle box
            car.box("Body", "steel", u - 0.42, u + 0.42, s * 0.29, s * 0.37, 0.84, 0.9)  # a leaf spring over it
            car.box("Body", "iron", u - 0.05, u + 0.05, s * 0.29, s * 0.37, DRIVER_R + 0.13, 0.9)
        # The running board on brackets from the frame (in the gaps between the drivers), a valance.
        car.box("Body", "wood", CYL_U[1] + 0.05, CAB_U, s * 0.62, s * 1.0, 1.13, 1.17)
        car.box("Body", "iron", CYL_U[1] + 0.05, CAB_U, s * 0.98, s * 1.01, 1.04, 1.17)
        for u in (3.6, 4.9, 6.2):
            car.box("Body", "iron", u - 0.03, u + 0.03, s * 0.36, s * 0.98, 1.08, 1.13)
            car.box("Body", "iron", u - 0.03, u + 0.03, s * 0.36, s * 0.42, 0.82, 1.13)
    car.box("Body", "iron", CAB_U - 0.05, L, -1.12, 1.12, 0.65, DECK)  # the cab's floor and its sills
    car.box("Body", "wood", CAB_U, L, -1.08, 1.08, DECK - 0.03, DECK)
    car.box("Body", "red", L - 0.25, L, -1.0, 1.0, 0.45, 0.8)  # the back beam
    car.box("Body", "steel", L - 0.05, L + 0.25, -0.12, 0.12, 0.55, 0.72)  # the drawbar

    # --- The pilot: a cowcatcher of slats from the beam down to a point at the rail -----------
    beam_u = 0.8
    car.box("Body", "red", beam_u - 0.08, beam_u + 0.15, -1.02, 1.02, 0.55, 0.84)  # the pilot beam
    car.box("Body", "steel", 0.5, beam_u, -0.1, 0.1, 0.6, 0.74)  # the coupler's pocket and drawbar
    car.cyl("Body", "steel", (0, 0.67, z(0.5)), (0, 0.67, z(0.32)), 0.035, seg=8)  # the link
    n = 13
    for k in range(n):
        x = -0.98 + 1.96 * k / (n - 1)
        top_p = Vector((x, 0.62, z(beam_u - 0.06)))
        bot_p = Vector((x, 0.07, z(0.06 + beam_u * abs(x) / 0.98)))
        car.cyl("Body", "red", top_p, bot_p, 0.022, seg=4)
    for s in (-1, 1):  # the bottom of the V, its top rails, a step on the beam's end
        car.cyl("Body", "iron", (s * 0.99, 0.07, z(beam_u)), (0, 0.07, z(0.04)), 0.03, seg=6)
        car.cyl("Body", "iron", (s * 0.99, 0.64, z(beam_u - 0.05)), (s * 0.99, 0.07, z(beam_u)), 0.025, seg=6)
        car.box("Body", "iron", beam_u - 0.05, beam_u + 0.15, s * 0.78, s * 0.98, 0.38, 0.41)
    car.cyl("Body", "iron", (0, 0.66, z(beam_u - 0.06)), (0, 0.07, z(0.04)), 0.03, seg=6)  # the spine

    # --- The pony truck --------------------------------------------------------------------
    for s in (-1, 1):
        car.box("Body", "iron", PONY_U - 0.15, PONY_U + 0.15, s * 0.42, s * 0.52, PONY_R - 0.08, PONY_R + 0.1)
    car.box("Body", "iron", PONY_U - 0.08, PONY_U + 0.08, -0.52, 0.52, PONY_R + 0.05, PONY_R + 0.12)
    car.cyl("Body", "iron", (0, PONY_R + 0.1, z(PONY_U)), (0, 0.5, z(CYL_U[1] + 0.2)), 0.04, seg=6)  # radius bar

    # --- Smokebox, boiler, firebox ---------------------------------------------------------
    sb0, sb1 = 1.28, 2.55
    car.cyl_z("Body", "iron", sb0, sb1, 0.0, BOILER_Y, 0.6, seg=36)
    car.lathe_z("Body", "iron", 0.0, BOILER_Y, [(0.0, 1.17), (0.3, 1.18), (0.5, 1.22), (0.57, 1.27), (0.63, 1.27),
                                                 (0.63, 1.31), (0.6, 1.31)], seg=36)  # the door and its ring
    for dy in (-0.24, 0.2):  # the door's hinge straps
        car.box("Body", "iron", 1.18, 1.23, -0.48, 0.32, BOILER_Y + dy - 0.025, BOILER_Y + dy + 0.025)
    car.cyl("Body", "steel", (0, BOILER_Y, z(1.17)), (0, BOILER_Y, z(1.1)), 0.05, seg=10)  # the dog
    car.cyl("Body", "steel", (-0.12, BOILER_Y, z(1.1)), (0.12, BOILER_Y, z(1.1)), 0.02, seg=6)  # its handle
    car.lathe_z("Body", "brass", 0.0, BOILER_Y + 0.38, [(0.0, 1.17), (0.11, 1.17), (0.11, 1.2)], seg=24)  # the number plate
    car.lathe_z("Body", "iron", 0.0, BOILER_Y, [(0.6, sb1 - 0.02), (0.6, sb1 + 0.04), (0.56, sb1 + 0.04)], seg=36)
    car.cyl_z("Body", "jacket", sb1, CAB_U + 0.2, 0.0, BOILER_Y, BOILER_R, seg=36)
    for u in (3.0, 4.2, 5.55, 6.6):
        car.cyl_z("Body", "brass", u - 0.025, u + 0.025, 0.0, BOILER_Y, BOILER_R + 0.012, seg=36)
    car.box("Body", "jacket", 5.9, CAB_U + 0.15, -0.42, 0.42, 0.85, BOILER_Y)  # the firebox
    car.box("Body", "iron", sb0 + 0.35, sb1 - 0.3, -0.62, 0.62, 0.48, BOILER_Y - 0.45)  # the saddle
    for s in (-1, 1):  # the handrails on stanchions, the feed pipe and its check valve
        car.cyl("Body", "steel", (s * 0.68, 2.06, z(1.45)), (s * 0.68, 2.06, z(CAB_U)), 0.014, seg=6)
        for u in (1.6, 2.9, 4.4, 5.9):
            car.cyl("Body", "steel", (s * 0.47, 2.02, z(u)), (s * 0.68, 2.06, z(u)), 0.012, seg=5)
        car.cyl("Body", "brass", (s * 0.575, 1.6, z(2.95)), (s * 0.575, 1.6, z(CAB_U)), 0.022, seg=8)
        car.lathe_y("Body", "brass", 2.95, s * 0.58, 1.52, [(0.06, 0), (0.06, 0.14), (0.04, 0.16), (0.0, 0.17)], seg=10)
        # Sand pipes from the dome down in front of the second pair.
        car.cyl("Body", "iron", (s * 0.3, 2.2, z(3.35)), (s * 0.62, 1.2, z(3.6)), 0.018, seg=6)
        car.cyl("Body", "iron", (s * 0.62, 1.2, z(3.6)), (s * 0.5, 0.25, z(DRIVERS_U[1] - 0.52)), 0.018, seg=6)

    # --- Cylinders, steam chests, guides ------------------------------------------------------
    for s in (-1, 1):
        x = s * CYL_X
        car.lathe_z("Body", "iron", x, CYL_Y, [(0.0, CYL_U[0] - 0.04), (0.17, CYL_U[0] - 0.04), (0.27, CYL_U[0]),
                                               (0.27, CYL_U[0] + 0.06), (0.25, CYL_U[0] + 0.07), (0.25, CYL_U[1] - 0.07),
                                               (0.27, CYL_U[1] - 0.06), (0.27, CYL_U[1]), (0.12, CYL_U[1] + 0.02),
                                               (0.06, CYL_U[1] + 0.08), (0.0, CYL_U[1] + 0.08)], seg=28)
        car.box("Body", "iron", CYL_U[0] + 0.07, CYL_U[1] - 0.07, s * 0.6, s * 0.9, CYL_Y + 0.2, CYL_Y + 0.5)  # chest
        car.box("Body", "iron", CYL_U[0] + 0.04, CYL_U[1] - 0.04, s * 0.58, s * 0.92, CYL_Y + 0.5, CYL_Y + 0.54)  # its lid
        car.box("Body", "iron", CYL_U[0] + 0.1, CYL_U[1] - 0.1, s * 0.36, s * 0.6, CYL_Y - 0.15, CYL_Y + 0.4)  # to the saddle
        car.cyl("Body", "iron", (x, CYL_Y - 0.25, z(CYL_U[0] + 0.1)), (x, CYL_Y - 0.36, z(CYL_U[0] + 0.1)), 0.02, seg=6)  # a cock
        car.cyl("Body", "iron", (x, CYL_Y - 0.25, z(CYL_U[1] - 0.1)), (x, CYL_Y - 0.36, z(CYL_U[1] - 0.1)), 0.02, seg=6)
        for dy in (-0.1, 0.1):  # the guide bars, from the back cover to the yoke between the first two pairs
            car.box("Body", "steel", CYL_U[1], GUIDE_END, s * (MAIN_X - 0.035), s * (MAIN_X + 0.035), CYL_Y + dy - 0.022,
                    CYL_Y + dy + 0.022)
        car.box("Body", "iron", GUIDE_END - 0.04, GUIDE_END + 0.04, s * 0.36, s * (MAIN_X + 0.06), CYL_Y - 0.17, 0.95)  # the yoke

    # --- The stack, the headlight, the domes, the bell ---------------------------------------
    su = 1.9
    base = BOILER_Y + 0.5
    car.lathe_y("Body", "iron", su, 0.0, base, [(0.3, -0.05), (0.26, 0.06), (0.18, 0.12), (0.17, 0.5), (0.2, 0.56),
                                                  (0.5, 0.98), (0.5, 1.03), (0.4, 1.14), (0.43, 1.17), (0.43, 1.2),
                                                  (0.0, 1.2)], seg=28)
    stack_top = base + 1.2
    # The headlight: a box lamp on a bracket at the smokebox front, a chimney, a lens lit by the game.
    hl0, hl1 = 1.18, 1.68
    hy = BOILER_Y + 0.62
    car.box("Body", "iron", hl0 + 0.1, hl1 - 0.05, -0.16, 0.16, BOILER_Y + 0.5, hy)
    car.box("Body", "red", hl0, hl1, -0.26, 0.26, hy, hy + 0.48)
    car.box("Body", "iron", hl0 - 0.03, hl1 + 0.03, -0.29, 0.29, hy + 0.48, hy + 0.52)
    car.slab("Body", "iron", hl0, hl1, (-0.29, hy + 0.52), (0.0, hy + 0.64), 0.02)
    car.slab("Body", "iron", hl0, hl1, (0.0, hy + 0.64), (0.29, hy + 0.52), 0.02)
    car.lathe_y("Body", "iron", (hl0 + hl1) * 0.5, 0.0, hy + 0.6, [(0.05, 0), (0.05, 0.12), (0.08, 0.14), (0.08, 0.17), (0, 0.17)], seg=10)
    car.lathe_z("Body", "brass", 0.0, hy + 0.24, [(0.2, hl0 + 0.01), (0.2, hl0 - 0.03), (0.17, hl0 - 0.03)], seg=24)
    car.lathe_z("Body", "lamp", 0.0, hy + 0.24, [(0.17, hl0 - 0.02), (0.0, hl0 - 0.02)], seg=24)
    # The sand dome (painted), the steam dome (brass) with the whistle, the safety valves.
    car.lathe_y("Body", "jacket", 3.35, 0.0, BOILER_Y + 0.38, [(0.44, 0.0), (0.36, 0.07), (0.3, 0.14), (0.3, 0.36),
                                                               (0.28, 0.44), (0.21, 0.54), (0.1, 0.59), (0.0, 0.6)], seg=28)
    car.lathe_y("Body", "brass", 4.95, 0.0, BOILER_Y + 0.38, [(0.47, 0.0), (0.38, 0.07), (0.32, 0.15), (0.32, 0.42),
                                                              (0.3, 0.5), (0.22, 0.6), (0.1, 0.66), (0.0, 0.67)], seg=28)
    dome_top = BOILER_Y + 0.38 + 0.67
    car.lathe_y("Body", "brass", 5.08, 0.0, dome_top - 0.05, [(0.03, 0), (0.03, 0.1), (0.05, 0.12), (0.05, 0.28),
                                                             (0.06, 0.3), (0.0, 0.31)], seg=10)  # the whistle
    for dx in (-0.08, 0.08):
        car.lathe_y("Body", "brass", 4.85, dx, dome_top - 0.08, [(0.04, 0), (0.04, 0.14), (0.055, 0.16), (0, 0.18)], seg=10)
    # The bell in its yoke between the domes.
    bu = 4.15
    for s in (-1, 1):
        car.box("Body", "iron", bu - 0.04, bu + 0.04, s * 0.2, s * 0.25, BOILER_Y + 0.48, BOILER_Y + 1.0)
    car.box("Body", "iron", bu - 0.04, bu + 0.04, -0.25, 0.25, BOILER_Y + 0.98, BOILER_Y + 1.03)
    car.lathe_y("Body", "brass", bu, 0.0, BOILER_Y + 0.62, [(0.0, -0.01), (0.18, 0.0), (0.17, 0.03), (0.13, 0.1),
                                                            (0.11, 0.2), (0.1, 0.27), (0.06, 0.31), (0.0, 0.32)], seg=24)
    car.box("Body", "iron", bu - 0.02, bu + 0.02, -0.02, 0.02, BOILER_Y + 0.93, BOILER_Y + 0.98)

    # --- The cab ------------------------------------------------------------------------------
    # Wooden walls, two windows a side (framed, the glass set in), the front round the boiler with a
    # window either side above the running boards, a shallow arched roof overhanging every side.
    # Open behind; its sides stop 0.75 short of the back (TrainCars: the gangway), a step below.
    back = L - 0.75
    wins = ((CAB_U + 0.14, CAB_U + 0.82), (CAB_U + 0.96, back - 0.14))
    for s in (-1, 1):
        x0, x1 = s * 1.02, s * 1.1
        car.box("Body", "wood", CAB_U, back, x0, x1, DECK - 0.15, DECK + 1.0)  # below the windows
        car.box("Body", "wood", CAB_U, back, x0, x1, DECK + 1.68, top)  # above
        posts = [CAB_U] + [p for w in wins for p in w] + [back]
        for a, b in zip(posts[0::2], posts[1::2]):
            car.box("Body", "wood", a, b, x0, x1, DECK + 1.0, DECK + 1.68)  # the posts between
        for a, b in wins:
            car.box("Body", "glass", a, b, s * 1.04, s * 1.05, DECK + 1.0, DECK + 1.68)
            for ya, yb in ((DECK + 0.97, DECK + 1.02), (DECK + 1.66, DECK + 1.71)):
                car.box("Body", "red", a - 0.03, b + 0.03, s * 1.1, s * 1.125, ya, yb)  # sill and head
            for ua in (a - 0.03, b):
                car.box("Body", "red", ua, ua + 0.03, s * 1.1, s * 1.125, DECK + 1.0, DECK + 1.68)
        car.box("Body", "red", CAB_U, back, s * 1.1, s * 1.12, DECK - 0.15, DECK - 0.1)  # a bottom rail
        car.box("Body", "steel", back - 0.03, back + 0.01, s * 1.12, s * 1.15, DECK + 0.1, DECK + 1.5)  # grab iron
        car.box("Body", "iron", back + 0.05, L - 0.1, s * 1.0, s * 1.22, 0.62, 0.66)  # the step
        car.box("Body", "iron", back + 0.05, back + 0.09, s * 1.18, s * 1.22, 0.62, DECK)
        car.box("Body", "iron", L - 0.14, L - 0.1, s * 1.18, s * 1.22, 0.62, DECK)
        for u in (CAB_U, back - 0.06):  # corner posts
            car.box("Body", "red", u, u + 0.06, s * 1.08, s * 1.125, DECK - 0.15, top)
    fu = CAB_U
    car.box("Body", "wood", fu, fu + 0.08, -1.1, -0.6, DECK, top)
    car.box("Body", "wood", fu, fu + 0.08, 0.6, 1.1, DECK, top)
    car.box("Body", "wood", fu, fu + 0.08, -0.6, 0.6, BOILER_Y + 0.56, top)
    for s in (-1, 1):
        car.box("Body", "glass", fu - 0.01, fu + 0.0, s * 0.68, s * 0.98, DECK + 1.1, DECK + 1.62)
        car.box("Body", "red", fu - 0.03, fu, s * 0.65, s * 1.01, DECK + 1.07, DECK + 1.1)
        car.box("Body", "red", fu - 0.03, fu, s * 0.65, s * 1.01, DECK + 1.62, DECK + 1.65)
    # The roof: a shallow arch of boards, over the cab and past it all round, a fascia at its edges.
    n = 10
    rw, rise = 1.24, 0.17
    for k in range(n):
        xa = -rw + 2 * rw * k / n
        xb = -rw + 2 * rw * (k + 1) / n
        ya = top + rise * (1 - (xa / rw) ** 2)
        yb = top + rise * (1 - (xb / rw) ** 2)
        car.slab("Body", "wood", CAB_U - 0.2, L + 0.08, (xa, ya), (xb, yb), 0.04)
    for s in (-1, 1):
        car.box("Body", "red", CAB_U - 0.2, L + 0.08, s * rw, s * (rw + 0.025), top - 0.06, top + 0.04)
    car.box("Body", "iron", CAB_U + 0.9, CAB_U + 1.5, -0.35, 0.35, top + rise, top + rise + 0.1)  # the roof hatch
    # In the cab: the backhead (a fire door, the gauges), the regulator's lever, the reverse lever.
    car.box("Body", "iron", fu + 0.08, fu + 0.14, -0.55, 0.55, DECK, BOILER_Y + 0.5)
    car.box("Body", "iron", fu + 0.12, fu + 0.2, -0.22, 0.22, DECK + 0.45, DECK + 0.85)
    for s, h in ((-0.3, 2.35), (0.3, 2.35), (0.0, 2.5)):
        car.cyl("Body", "brass", (s, h, z(fu + 0.14)), (s, h, z(fu + 0.2)), 0.09, seg=16)
    car.cyl("Body", "steel", (0.25, BOILER_Y + 0.4, z(fu + 0.15)), (0.55, BOILER_Y + 0.25, z(fu + 0.35)), 0.02, seg=6)
    car.cyl("Body", "steel", (0.85, DECK, z(fu + 0.7)), (0.85, DECK + 1.0, z(fu + 0.55)), 0.025, seg=6)

    # --- The moving parts ---------------------------------------------------------------------
    # The pony truck's wheels; the four pairs of drivers (the right pin at the top at rest, the left
    # a quarter on; forward the wheels turn back over their tops).
    wheel(car, "Pony", PONY_U, PONY_R, spokes=8)
    pins = ((1, 0.0), (-1, math.pi / 2))
    for k, u in enumerate(DRIVERS_U):
        wheel(car, "Driver%d" % k, u, DRIVER_R, spokes=14, crank=pins, counter=True)
    # The side rods (each side one rod over the four pins, deeper at the middle, a boss at each
    # pin), the main rods (tapered, a strap at the big end) and the crossheads, at the rest pose;
    # origins on the main pin.
    for side, ang in pins:
        tag = "R" if side > 0 else "L"
        dz = math.sin(ang) * CRANK
        main_pin = Vector((side * ROD_X, DRIVER_R + math.cos(ang) * CRANK, z(DRIVERS_U[MAIN]) + dz))
        node = "SideRod" + tag
        car.origins[node] = main_pin
        y = main_pin.y
        for a, b in zip(DRIVERS_U[:-1], DRIVERS_U[1:]):
            car.bar(node, "steel", (y, a + dz), (y, (a + b) * 0.5 + dz), 0.075, 0.1, side * (ROD_X - 0.02), side * (ROD_X + 0.02))
            car.bar(node, "steel", (y, (a + b) * 0.5 + dz), (y, b + dz), 0.1, 0.075, side * (ROD_X - 0.02), side * (ROD_X + 0.02))
        for u in DRIVERS_U:
            car.cyl_x(node, "steel", u + dz, y, side * (ROD_X - 0.03), side * (ROD_X + 0.03), 0.08, seg=16)
        node = "MainRod" + tag
        car.origins[node] = Vector((side * MAIN_X, y, main_pin.z))
        mu = DRIVERS_U[MAIN] + dz
        car.bar(node, "steel", (y, mu), (y, mu - MAIN_LEN), 0.12, 0.07, side * (MAIN_X - 0.025), side * (MAIN_X + 0.025))
        car.cyl_x(node, "steel", mu, y, side * (MAIN_X - 0.035), side * (MAIN_X + 0.035), 0.1, seg=16)
        car.box(node, "steel", mu - 0.06, mu + 0.12, side * (MAIN_X - 0.03), side * (MAIN_X + 0.03), y - 0.1, y + 0.1)  # strap
        car.cyl_x(node, "steel", mu - MAIN_LEN, y, side * (MAIN_X - 0.03), side * (MAIN_X + 0.03), 0.06, seg=12)
        node = "Crosshead" + tag
        mid_u = DRIVERS_U[MAIN] - MAIN_LEN
        car.origins[node] = Vector((side * MAIN_X, CYL_Y, z(mid_u)))
        car.box(node, "steel", mid_u - 0.16, mid_u + 0.12, side * (MAIN_X - 0.05), side * (MAIN_X + 0.05), CYL_Y - 0.078, CYL_Y + 0.078)
        car.cyl_x(node, "steel", mid_u, CYL_Y, side * (MAIN_X - 0.06), side * (MAIN_X + 0.06), 0.035, seg=10)  # wrist pin
        car.cyl_z(node, "steel", mid_u - 0.85, mid_u - 0.14, side * MAIN_X, CYL_Y, 0.04, seg=12)  # the piston rod
    root = car.build("Engine")
    rig = {
        "mid": car.mid, "gauge": GAUGE, "driver_r": DRIVER_R, "pony_r": PONY_R, "crank": CRANK,
        "drivers_z": [car.z(u) for u in DRIVERS_U], "pony_z": car.z(PONY_U), "main": MAIN,
        "main_len": MAIN_LEN, "rod_x": ROD_X, "main_x": MAIN_X, "slide_y": CYL_Y,
        "pins": {"R": 0.0, "L": math.pi / 2},
        "stack": [0.0, stack_top, car.z(su)],
        "cylinder_cocks": [[s * CYL_X, CYL_Y - 0.36, car.z(CYL_U[0] + 0.1)] for s in (-1, 1)],
        "headlight": [0.0, hy + 0.24, car.z(hl0 - 0.05)], "firebox": [0.0, DECK + 0.65, car.z(CAB_U + 0.25)],
        "bell": [0.0, BOILER_Y + 0.75, car.z(bu)], "whistle": [0.0, dome_top + 0.25, car.z(5.08)],
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
