"""The revolver in your hand, modelled: a Colt Single Action Army with the 7½" barrel.

Run (bpy in a venv, see CLAUDE.md):  ~/bpyenv/bin/python tools/blender/held_revolver.py
Writes assets/held/revolver.glb.

Built in the same local space and with the same moving parts as src/weapons/revolver_model.gd
(the code-built gun the game draws today), so the viewmodel animates it as it does that one:
barrel along -Z, top +Y, origin where the grip meets the frame; pivots Hammer, Trigger, Cylinder,
Gate and Ejector at the same points; chambers Rim0-5 / Primer0-5 in the cylinder, chamber 0 at
the top. Sizes from the gun's published dimensions (7½" barrel, a 1.66" cylinder 1.6" long, a
13" gun overall).

Every part is shaped from profiles, lathes and cuts with bevelled edges, then each vertex gets
two numbers in its colour (red: how sharp and outward its edge is, where bluing and case colours
wear first; green: how open it is to the sky, a cheap ambient occlusion), read by
experiments/painterly/held_metal.gdshader. Materials are named slots (case, blued, brass, walnut,
bore, rim, primer); the game lays its own on by name. Nothing is hand-edited.
"""

import math
import os

import bpy  # noqa: I001 (bpy before bmesh and mathutils)
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

OUT = "assets/held"
MATS = {}


def B(x, y, z):
    """Godot (x right, y up, -z forward) → Blender (z up, -y forward on export)."""
    return Vector((x, -z, y))


# --- Builders: each returns a bmesh in the part's own (Godot) space -----------------------------

def prism(profile_zy, x0, x1):
    """A flat shape drawn in the side view (z, y), as thick as x0..x1."""
    bm = bmesh.new()
    a = [bm.verts.new(B(x0, y, z)) for z, y in profile_zy]
    b = [bm.verts.new(B(x1, y, z)) for z, y in profile_zy]
    n = len(profile_zy)
    bm.faces.new(a[::-1])
    bm.faces.new(b)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([a[i], a[j], b[j], b[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def lathe(profile, centre=(0.0, 0.0, 0.0), axis="z", sides=32):
    """Turned along an axis: profile [(t, r)] from one end to the other (r 0 closes an end).
    Axis "z" runs along -Z from the centre for growing t (the barrel's way), "x" along +X."""
    bm = bmesh.new()
    cx, cy, cz = centre
    rings = []
    for t, r in profile:
        ring = []
        for k in range(sides if r > 0 else 1):
            a = 2 * math.pi * k / sides
            if axis == "z":
                p = (cx + math.sin(a) * r, cy + math.cos(a) * r, cz - t)
            else:
                p = (cx + t, cy + math.cos(a) * r, cz + math.sin(a) * r)
            ring.append(bm.verts.new(B(*p)))
        rings.append(ring)
    for r0, r1 in zip(rings, rings[1:]):
        if len(r0) == 1 and len(r1) == 1:
            continue
        if len(r0) == 1:
            for k in range(sides):
                bm.faces.new([r0[0], r1[k], r1[(k + 1) % sides]])
        elif len(r1) == 1:
            for k in range(sides):
                bm.faces.new([r0[(k + 1) % sides], r0[k], r1[0]])
        else:
            for k in range(sides):
                bm.faces.new([r0[k], r0[(k + 1) % sides], r1[(k + 1) % sides], r1[k]])
    if len(rings[0]) > 1:
        bm.faces.new(rings[0])
    if len(rings[-1]) > 1:
        bm.faces.new(rings[-1][::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


def box(size, centre, rot_x_deg=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    sx, sy, sz = size
    m = Matrix.Diagonal((sx, sz, sy, 1.0))  # Godot size → Blender axes
    bmesh.ops.transform(bm, matrix=m, verts=bm.verts)
    if rot_x_deg:
        bmesh.ops.rotate(bm, matrix=Matrix.Rotation(math.radians(rot_x_deg), 3, "X"), verts=bm.verts)
    bmesh.ops.translate(bm, vec=B(*centre), verts=bm.verts)
    return bm


def strip(path_zy, thick, half_widths, flip=False):
    """A band along a side-view path (z, y): `thick` across the path in the side view, each point
    its own half width in x (the trigger guard and the grip straps)."""
    pts = [np.array(p, float) for p in path_zy]
    n = len(pts)
    bm = bmesh.new()
    rows = []
    for i, p in enumerate(pts):
        d = pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]
        d /= np.linalg.norm(d)
        nrm = np.array([-d[1], d[0]]) * (-1 if flip else 1)
        hw = half_widths[i] if isinstance(half_widths, (list, tuple)) else half_widths
        q = p + nrm * thick
        rows.append([bm.verts.new(B(x, yy, zz)) for x, (zz, yy) in
                     ((-hw, p), (hw, p), (hw, q), (-hw, q))])
    for r0, r1 in zip(rows, rows[1:]):
        for k in range(4):
            bm.faces.new([r0[k], r0[(k + 1) % 4], r1[(k + 1) % 4], r1[k]])
    bm.faces.new(rows[0][::-1])
    bm.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bm


# --- Objects -----------------------------------------------------------------------------------

def material(name):
    if name not in MATS:
        MATS[name] = bpy.data.materials.new(name)
    return MATS[name]


def obj(name, bm, mat, parent=None, at=(0.0, 0.0, 0.0)):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    me.materials.append(material(mat))
    if parent is not None:
        ob.parent = parent
    ob.location = B(*at)
    return ob


def pivot(name, at, parent=None):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
    if parent is not None:
        e.parent = parent
    e.location = B(*at)
    return e


def bake(ob):
    """Apply the object's modifiers."""
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ob.modifiers.clear()
    old = ob.data
    ob.data = me
    bpy.data.meshes.remove(old)


def cut(ob, *cutters, op="DIFFERENCE"):
    """Boolean each cutter (a bmesh in the part's space, or an object beside it, which goes)."""
    for bm in cutters:
        if isinstance(bm, bpy.types.Object):
            c = bm
        else:
            c = obj("cutter", bm, "bore")
            c.parent = ob.parent
            c.location = ob.location
        m = ob.modifiers.new("cut", "BOOLEAN")
        m.object = c
        m.operation = op
        m.solver = "EXACT"
        bake(ob)
        bpy.data.objects.remove(c)


def bevel(ob, width, segments=3, angle=35.0):
    m = ob.modifiers.new("bevel", "BEVEL")
    m.width = width
    m.segments = segments
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.miter_outer = "MITER_ARC"
    m.harden_normals = False
    bake(ob)


def smooth(ob, angle=40.0):
    ob.data.shade_smooth()
    ob.data.set_sharp_from_angle(angle=math.radians(angle))


# --- The gun -----------------------------------------------------------------------------------

def build():
    root = pivot("Revolver", (0, 0, 0))

    # Frame: the side profile, cut for the cylinder's window, the hammer's slot and the rear sight
    # groove; the round recoil shield behind the cylinder, cut for the loading gate.
    frame_profile = [(-0.0665, 0.051), (-0.0665, 0.016), (-0.063, 0.010), (-0.057, 0.0065),
                     (-0.035, 0.0035), (-0.016, 0.001), (-0.006, -0.004), (0.004, -0.0075),
                     (0.012, -0.004), (0.0155, 0.006), (0.0165, 0.026), (0.0145, 0.040),
                     (0.010, 0.048), (0.003, 0.0545), (-0.006, 0.0582), (-0.058, 0.0582),
                     (-0.0635, 0.056)]
    frame = obj("Frame", prism(frame_profile, -0.012, 0.012), "case", root)
    shield = obj("Shield", lathe([(0.0, 0.0), (0.0, 0.021), (0.0008, 0.0225), (0.0082, 0.0225),
                                  (0.009, 0.021), (0.009, 0.0)], (0, 0.03, -0.003), "z", 48), "case", root)
    cut(frame, box((0.06, 0.0475, 0.045), (0, 0.0302, -0.034)))            # the cylinder's window
    cut(frame, box((0.0092, 0.05, 0.022), (0, 0.055, 0.007)))              # the hammer's slot
    cut(frame, box((0.0028, 0.006, 0.05), (0, 0.0605, -0.022)))            # the rear sight groove
    cut(frame, shield, op="UNION")
    # The loading gate's recess on the right of the shield.
    cut(frame, box((0.012, 0.0195, 0.0102), (0.0185, 0.0272, -0.0075)))
    bevel(frame, 0.0011, 3)
    smooth(frame)

    # Barrel: the shank where it screws into the frame, then the tube, crowned at the muzzle; the
    # bore cut down it; the front sight a half-moon blade.
    L = 0.19
    barrel = obj("Barrel", lathe([(0.0, 0.0), (0.0, 0.0084), (0.004, 0.0084), (0.0045, 0.0074),
                                  (0.012, 0.0072), (L - 0.0012, 0.0068), (L, 0.0062), (L, 0.0)],
                                 (0, 0.0405, -0.065), "z", 40), "blued", root)
    cut(barrel, lathe([(0.0, 0.0057), (0.06, 0.0057)], (0, 0.0405, -0.065 - L + 0.05), "z", 24))
    sight = obj("FrontSight", prism([(-0.065 - L + 0.004, 0.0465), (-0.065 - L + 0.015, 0.0465),
                                     (-0.065 - L + 0.012, 0.0505), (-0.065 - L + 0.008, 0.0516),
                                     (-0.065 - L + 0.005, 0.0505)], -0.0011, 0.0011), "blued", root)
    cut(barrel, sight, op="UNION")
    bevel(barrel, 0.0005, 2, 50)
    smooth(barrel, 50)
    obj("Bore", lathe([(0.0, 0.0057), (0.003, 0.0057), (0.003, 0.0)], (0, 0.0405, -0.065 - L + 0.004),
                      "z", 24), "bore", root)

    # Ejector: the housing along the barrel's right underside with its slot, the rod's head in front.
    hx, hy = 0.0066, 0.0302
    housing = obj("EjectorHousing", lathe([(0.0, 0.0), (0.0, 0.0048), (0.0012, 0.0052), (0.136, 0.0052),
                                           (0.14, 0.0046), (0.14, 0.0)], (hx, hy, -0.067), "z", 28), "blued", root)
    cut(housing, box((0.006, 0.0022, 0.1), (hx + 0.004, hy, -0.12)))
    lug = obj("HousingLug", prism([(-0.072, 0.0335), (-0.064, 0.0335), (-0.064, 0.0255), (-0.075, 0.0255)],
                                  hx - 0.0035, hx + 0.0056), "blued", root)
    cut(housing, lug, op="UNION")
    bevel(housing, 0.0006, 2, 45)
    smooth(housing, 45)
    ejector = pivot("Ejector", (hx, hy, -0.21), root)
    head = obj("EjectorHead", lathe([(-0.002, 0.0), (-0.002, 0.0034), (0.0, 0.0042), (0.005, 0.0042),
                                     (0.0065, 0.0028), (0.012, 0.0025), (0.06, 0.0025), (0.06, 0.0)],
                                    (0, 0, 0), "z", 20), "blued", ejector)
    head.rotation_euler = (0, 0, 0)
    # The rod runs back inside the housing: flip it so it trails toward the frame.
    for v in head.data.vertices:
        v.co.y = -v.co.y
    smooth(head, 50)

    # Base pin under the barrel, its head in front of the frame; its latch screw across the frame.
    pin = obj("BasePin", lathe([(0.0, 0.0), (0.0, 0.0038), (0.006, 0.0038), (0.0065, 0.0029), (0.066, 0.0029),
                                (0.066, 0.0)], (0, 0.03, -0.0735), "z", 24), "blued", root)
    for v in pin.data.vertices:
        v.co.y = -v.co.y + 2 * B(0, 0.03, -0.0735).y
    smooth(pin, 50)
    obj("PinLatch", lathe([(0.0, 0.0), (0.0, 0.0024), (0.0025, 0.0024), (0.0025, 0.0)],
                          (0.0115, 0.022, -0.061), "x", 16), "blued", root)

    # Screws on the frame's right side (the left side is in the hand).
    for i, (z, y) in enumerate([(-0.004, 0.003), (0.007, 0.019), (0.0115, 0.006), (-0.026, 0.0085)]):
        s = obj("Screw%d" % i, lathe([(0.0, 0.0), (0.0, 0.0021), (0.0007, 0.002), (0.0012, 0.0),
                                      ], (0.0118, y, z), "x", 16), "blued", root)
        cut(s, box((0.003, 0.0006, 0.005), (0.0128, y, z)))
        smooth(s, 60)

    # The cylinder, about its own axis: fluted between the chambers, chambers bored from the front,
    # bolt notches at the rear; the cartridges' rims and primers at the back.
    cyl_at = (0.0, 0.03, -0.034)
    cylinder = pivot("Cylinder", cyl_at, root)
    body = obj("Body", lathe([(-0.021, 0.0), (-0.021, 0.0035), (-0.021, 0.0198), (-0.0198, 0.021),
                              (0.0198, 0.021), (0.021, 0.0196), (0.021, 0.0035), (0.021, 0.0)],
                             (0, 0, 0), "z", 64), "blued", cylinder)
    flutes, chambers, notches = [], [], []
    for i in range(6):
        a = math.radians(i * 60.0)
        fa = a + math.radians(30.0)
        fx, fy = math.sin(fa) * 0.0232, math.cos(fa) * 0.0232
        flutes.append(lathe([(0.0, 0.0), (0.0, 0.002), (0.0015, 0.0042), (0.0045, 0.005), (0.0175, 0.005),
                             (0.0205, 0.0042), (0.022, 0.002), (0.022, 0.0)], (fx, fy, 0.0115), "z", 20))
        cx, cy = math.sin(a) * 0.0135, math.cos(a) * 0.0135
        chambers.append(lathe([(0.0, 0.0059), (0.012, 0.0059), (0.012, 0.0)], (cx, cy, -0.0215), "z", 24))
        nx, ny = math.sin(fa) * 0.021, math.cos(fa) * 0.021
        notches.append(box((0.0034, 0.0034, 0.0045), (nx, ny, 0.0155)))
    cut(body, *flutes, *chambers, *notches)
    bevel(body, 0.0005, 2, 50)
    smooth(body, 50)
    for i in range(6):
        a = math.radians(i * 60.0)
        cx, cy = math.sin(a) * 0.0135, math.cos(a) * 0.0135
        rim = obj("Rim%d" % i, lathe([(0.0, 0.0), (0.0, 0.0063), (0.0006, 0.0063), (0.0015, 0.006),
                                      (0.0015, 0.0)], (0, 0, 0.0012), "z", 24), "rim", cylinder, (cx, cy, 0.0205))
        smooth(rim, 50)
        pr = obj("Primer%d" % i, lathe([(-0.0003, 0.0), (-0.0003, 0.0022), (0.0, 0.0024), (0.0005, 0.0024),
                                        (0.0005, 0.0)], (0, 0, 0.0), "z", 16), "primer", cylinder,
                 (cx, cy, 0.0213))
        smooth(pr, 50)
        obj("Mouth%d" % i, lathe([(0.0, 0.0059), (0.001, 0.0059), (0.001, 0.0)], (cx, cy, -0.0105), "z", 24),
            "bore", cylinder)

    # Loading gate: a curved flap filling its recess, hinged at its foot, a thumb ridge on its face.
    gate = pivot("Gate", (0.0155, 0.018, -0.005), root)
    flap = obj("Flap", box((0.0086, 0.0183, 0.0094), (0.0038, 0.0094, -0.0025)), "case", gate)
    cut(flap, lathe([(-0.02, 0.0225), (0.02, 0.0225)], (-0.0155, 0.012, -0.0025), "z", 48), op="INTERSECT")
    bevel(flap, 0.0006, 2)
    smooth(flap)

    # Hammer: a side profile, the spur wider and chequered where the thumb pulls it.
    hammer = pivot("Hammer", (0.0, 0.03, 0.004), root)
    hp = [(-0.007, -0.004), (-0.007, 0.0115), (-0.0058, 0.0145), (-0.0058, 0.0175), (-0.0035, 0.022),
          (0.001, 0.0265), (0.008, 0.0295), (0.017, 0.0325), (0.025, 0.034), (0.0295, 0.0325),
          (0.0295, 0.0295), (0.026, 0.0275), (0.017, 0.026), (0.0095, 0.0215), (0.0065, 0.012),
          (0.0058, 0.002), (0.003, -0.005), (-0.003, -0.0065)]
    hbody = obj("Body", prism(hp, -0.0039, 0.0039), "case", hammer)
    spur = obj("Spur", prism([(0.0075, 0.0302), (0.017, 0.0332), (0.025, 0.0346), (0.0298, 0.0332),
                              (0.0298, 0.0292), (0.026, 0.0272), (0.017, 0.0255), (0.0095, 0.0225)],
                             -0.0058, 0.0058), "case", hammer)
    cut(hbody, spur, op="UNION")
    grooves = []
    for k in range(7):
        z = 0.012 + k * 0.0024
        y = 0.0312 + (z - 0.012) * 0.25
        grooves.append(box((0.014, 0.0012, 0.0008), (0.0, y + 0.0011, z), -12.0))
    cut(hbody, *grooves)
    bevel(hbody, 0.0006, 2)
    smooth(hbody)

    # Trigger: a curved blade.
    trigger = pivot("Trigger", (0.0, -0.004, -0.018), root)
    blade = obj("Blade", prism([(-0.0022, 0.006), (0.0022, 0.006), (0.0027, -0.004), (0.0019, -0.012),
                                (0.0003, -0.0175), (-0.0021, -0.0198), (-0.0034, -0.0188), (-0.0019, -0.0155),
                                (-0.0012, -0.0098), (-0.0018, -0.003)], -0.0021, 0.0021), "blued", trigger)
    bevel(blade, 0.0006, 2)
    smooth(blade)

    # The brass: trigger guard running into the front strap down the grip, the backstrap and butt.
    front = [(-0.0345, 0.0035), (-0.0362, -0.006), (-0.0352, -0.016), (-0.0305, -0.0238), (-0.022, -0.0278),
             (-0.012, -0.0282), (-0.004, -0.0255), (0.0005, -0.0195), (0.0025, -0.012), (0.0035, -0.03),
             (0.0065, -0.05), (0.0115, -0.07), (0.0165, -0.085), (0.0205, -0.0935)]
    hw = [0.0042, 0.0042, 0.0042, 0.0042, 0.0042, 0.0042, 0.0045, 0.006, 0.0085, 0.0088, 0.009, 0.0092,
          0.0094, 0.0095]
    guard = obj("Guard", strip(front, 0.0034, hw, flip=True), "brass", root)
    bevel(guard, 0.0011, 3, 30)
    smooth(guard)
    back = [(0.0155, 0.012), (0.0185, 0.0), (0.0245, -0.012), (0.0315, -0.03), (0.0385, -0.05),
            (0.0432, -0.07), (0.0445, -0.088), (0.0415, -0.0965), (0.034, -0.0995), (0.024, -0.0985),
            (0.0195, -0.0945)]
    bw = [0.0072, 0.0074, 0.0076, 0.0078, 0.008, 0.0082, 0.0084, 0.0088, 0.0092, 0.0094, 0.0095]
    strap = obj("Backstrap", strip(back, 0.0036, bw), "brass", root)
    bevel(strap, 0.0012, 3, 30)
    smooth(strap)

    # Walnut grips, one piece either side of the grip frame, their edges rounded off; a screw.
    grip_outline = [(0.003, -0.006), (0.003, -0.012), (0.004, -0.03), (0.007, -0.05), (0.012, -0.07),
                    (0.017, -0.085), (0.0205, -0.093), (0.024, -0.098), (0.034, -0.099), (0.041, -0.096),
                    (0.044, -0.088), (0.0427, -0.07), (0.038, -0.05), (0.031, -0.03), (0.024, -0.012),
                    (0.018, 0.0), (0.014, 0.006)]
    grips = obj("Grips", prism(grip_outline, -0.0158, 0.0158), "walnut", root)
    bevel(grips, 0.0052, 5, 30)
    smooth(grips, 60)
    obj("GripScrew", lathe([(-0.0002, 0.0), (-0.0002, 0.0026), (0.0006, 0.0024), (0.0322, 0.0024),
                            (0.033, 0.0026), (0.033, 0.0)], (-0.0164, -0.052, 0.0255), "x", 16), "blued", root)
    return root


# --- Vertex colours: wear and openness ---------------------------------------------------------

def shade_vertices(parts):
    """Red: how far each vertex's edges turn outward (bluing wears off edges first); green: the
    share of a hemisphere of short rays that get out (dark in creases and under parts)."""
    dg = bpy.context.evaluated_depsgraph_get()
    tris_all, verts_all = [], []
    for ob in parts:
        m = ob.matrix_world
        base = len(verts_all)
        verts_all += [m @ v.co for v in ob.data.vertices]
        ob.data.calc_loop_triangles()
        tris_all += [[base + i for i in t.vertices] for t in ob.data.loop_triangles]
    tree = BVHTree.FromPolygons(verts_all, tris_all)
    rng = np.random.default_rng(1873)
    dirs = rng.normal(size=(40, 3))
    dirs /= np.linalg.norm(dirs, axis=1)[:, None]
    for ob in parts:
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        bm.verts.ensure_lookup_table()
        wear = np.zeros(len(bm.verts))
        for v in bm.verts:
            s = 0.0
            for e in v.link_edges:
                if len(e.link_faces) == 2:
                    a = e.calc_face_angle_signed(0.0)
                    if a > 0:
                        s += a
            wear[v.index] = min(s / (math.pi / 2), 1.0)
        bm.free()
        m = ob.matrix_world
        nm = m.to_3x3().inverted().transposed()
        open_ = np.ones(len(ob.data.vertices))
        for v in ob.data.vertices:
            p = m @ v.co
            n = (nm @ v.normal).normalized()
            hit = 0
            tot = 0
            for d in dirs:
                d = Vector(d)
                if d.dot(n) < 0:
                    d = -d
                tot += 1
                loc, _, _, dist = tree.ray_cast(p + n * 0.0003, d, 0.02)
                if loc is not None:
                    hit += 1 - dist / 0.02
            open_[v.index] = 1.0 - hit / max(tot, 1)
        attr = ob.data.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        for i in range(len(ob.data.vertices)):
            attr.data[i].color = (float(wear[i]), float(open_[i]), 0.0, 1.0)
        ob.data.color_attributes.active_color = attr
        print("%-16s verts %5d  wear>0.5 %.2f  open median %.2f" % (ob.name, len(open_), (wear > 0.5).mean(),
                                                                   float(np.median(open_))))


def main():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    root = build()
    parts = [o for o in bpy.data.objects if o.type == "MESH"]
    bpy.context.view_layer.update()
    shade_vertices(parts)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, "revolver.glb")
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_normals=True,
                              export_texcoords=False, export_materials="EXPORT",
                              export_vertex_color="ACTIVE", export_animations=False, export_skins=False)
    tris = sum(len(o.data.loop_triangles) for o in parts)
    print("wrote", path, "parts", len(parts), "triangles", tris)


if __name__ == "__main__":
    main()
