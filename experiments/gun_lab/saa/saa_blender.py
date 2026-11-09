"""The Colt Single Action Army (1873) built in Blender by script from its real dimensions (#693 step 1,
Sean 2026-11-07: "build the gun, don't buy it"). Every part the game drives is its own object with
its origin on its pivot: the cylinder (indexes), hammer, trigger, bolt, loading gate, ejector rod;
the frame, barrel, grip frame (backstrap, trigger guard), the one-piece walnut grip, the base pin and
each screw are their own objects too. No maker's name or stamping (the gun lab's rule).

    ~/bpyenv/bin/python experiments/gun_lab/saa/saa_blender.py [--barrel=7.5|5.5|4.75] [--out=DIR] [--preview=DIR]

Out: DIR/saa_<barrel>.glb (default experiments/gun_lab/saa/) and DIR/saa_<barrel>_rig.json (pivots, axes,
travel, markers in the game's space, metres). --preview renders side/three-quarter Cycles stills for
checking the shapes (not the look: the look is judged in Godot under the real look, saa_views.gd).

The dimensions (inches, DIMS below) and where each comes from are in this folder's README.md.
Design space: inches; f forward along the bore (0 = the cylinder's rear face), u up (0 = the bore's
axis), l to the gun's right. Blender: (x, y, z) = (l, f, u) * 0.0254 - ORIGIN; the glTF exporter
turns Blender's +Y forward into Godot's -Z, so in the game the barrel points along -Z, up is +Y,
right +X, as RevolverModel.
"""
import json
import math
import os
import sys

import bpy  # first: Blender's own modules come with it
import bmesh
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))


def arg(name, default=""):
    for a in sys.argv:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


BARREL = float(arg("barrel", "7.5"))
OUT = arg("out", HERE)
PREVIEW = arg("preview", "")
IN = 0.0254

# --- The dimensions (inches). README.md "The dimensions" gives each one's source. ---------------
D = {
    "bore": 0.445,            # .45 Colt: lands .445, grooves .454
    "groove": 0.454,
    "barrel_od_breech": 0.700,
    "barrel_od_muzzle": 0.686,
    "gap": 0.006,             # barrel-cylinder gap
    "cyl_len": 1.608,
    "cyl_dia": 1.650,
    "bolt_circle": 0.520,     # chamber centres from the cylinder's axis (= the axis under the bore)
    "chamber": 0.481,         # chamber mouth .480-.482
    "rim": 0.512, "rim_t": 0.060,
    "case_len": 1.285, "oal": 1.600, "bullet": 0.454,
    "headspace": 0.062,       # the recoil shield's face behind the cylinder: rim + clearance
    "frame_front_len": 0.686, # frame ahead of the cylinder, round the barrel's shank (the Met gun's face at 2.30)
    "top_strap": (0.33, 0.48),  # Met 59.143.4: the strap's top 0.48 over the bore
    "frame_bottom": -1.62,      # at the frame front; it slopes down to the guard (FRAME_BOTTOM)
    "eject_od": 0.44, "eject_rod": 0.22, "eject_len": 4.05, "eject_stroke": 1.78,
    "base_pin": 0.21,
}
CA = -D["bolt_circle"]                       # the cylinder's axis, under the bore
RC = D["cyl_dia"] / 2.0
F_CYL1 = D["cyl_len"]                         # cylinder's front face
F_BARREL = F_CYL1 + D["gap"]                  # barrel's rear face
F_FRONT = F_BARREL + D["frame_front_len"]     # frame's front face
MUZZLE = F_BARREL + BARREL
F_SHIELD = -D["headspace"]                    # recoil shield's front face
F_SHIELD_BACK = -0.33                         # where the hammer's face sits
GATE_DEG = 75.0                               # the chamber at the loading gate, clockwise from the top seen from behind
LOS = 0.43                                    # the rear groove's bottom; the front blade stands to 0.63 (the Met gun)
FRONT_BLADE_TOP = 0.63
ORIGIN = Vector((0.0, -0.62 * IN, -2.12 * IN))  # the frame's underside at the trigger: "where the grip meets the frame"
# The three screws on the left of the Met gun (59.143.4), measured off its side photo.
HAMMER_PIVOT = (-0.72, -1.47)
TRIGGER_PIVOT = (-0.15, -1.79)
BOLT_PIVOT = (0.12, -1.68)
# The lower edge, measured: from the frame front's foot sloping down to the guard and on, along the
# underside of the guard's tang (the top of the guard's opening), to where the tang meets the front strap.
FRAME_BOTTOM = [(1.98, -1.60), (1.80, -1.68), (1.40, -1.81), (1.00, -1.90), (0.80, -1.96), (0.0, -2.08), (-0.98, -2.27)]
# The guard's tang is 0.2" of that, under the frame, from the bow's front to the front strap.
TANG = 0.20
TANG_FRONT = 0.92


def frame_bottom_at(f):
    pts = FRAME_BOTTOM
    if f >= pts[0][0]:
        return pts[0][1]
    for (fa, ua), (fb_, ub) in zip(pts[:-1], pts[1:]):
        if fb_ <= f <= fa:
            return ua + (ub - ua) * (fa - f) / (fa - fb_)
    return pts[-1][1]
SEG = 64


def P(l, f, u):
    return Vector((l * IN, f * IN, u * IN))


def gate_chamber():
    a = math.radians(GATE_DEG)
    return (D["bolt_circle"] * math.sin(a), CA + D["bolt_circle"] * math.cos(a))


# --- Mesh helpers --------------------------------------------------------------------------------
def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def obj_from_bm(name, bm, mat=None):
    me = bpy.data.meshes.new(name)
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    if mat:
        ob.data.materials.append(mat)
    return ob


def chaikin(pts, corners=(), it=3):
    """Smooth a closed outline (Chaikin's corner cutting), keeping the points whose index is in
    `corners` sharp."""
    p = [(Vector(q), i in corners) for i, q in enumerate(pts)]
    for _ in range(it):
        out = []
        n = len(p)
        for i in range(n):
            a, ca = p[i]
            b, _ = p[(i + 1) % n]
            if ca:
                out.append((a, True))
            out.append((a.lerp(b, 0.25), False))
            out.append((a.lerp(b, 0.75), False))
        p = out
    res = []
    for v, _ in p:
        if not res or (res[-1] - v).length > 1e-7:
            res.append(v)
    if (res[0] - res[-1]).length < 1e-7:
        res.pop()
    return [(v.x, v.y) for v in res]


def prism(name, outline, hw, mat=None, l0=None, l1=None, smooth=True, corners=()):
    """A side outline (f, u) extruded across the gun from l = -hw to +hw (or l0..l1)."""
    pts = chaikin(outline, corners) if smooth else outline
    a = -hw if l0 is None else l0
    b = hw if l1 is None else l1
    bm = bmesh.new()
    left = [bm.verts.new(P(a, f, u)) for f, u in pts]
    right = [bm.verts.new(P(b, f, u)) for f, u in pts]
    n = len(pts)
    bm.faces.new(right)
    bm.faces.new(list(reversed(left)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((left[i], left[j], right[j], right[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def lathe(name, profile, center, axis="f", mat=None, seg=SEG, start=0.0):
    """A turned part: profile [(along, r)] about an axis through `center` (l, f, u), along f (the
    bore's way) or l (across the gun). r == 0 at an end closes it to a point."""
    bm = bmesh.new()
    rings = []
    cl, cf, cu = center
    for s, r in profile:
        ring = []
        if r < 1e-9:
            if axis == "f":
                ring = [bm.verts.new(P(cl, cf + s, cu))]
            else:
                ring = [bm.verts.new(P(cl + s, cf, cu))]
        else:
            for k in range(seg):
                t = start + 2 * math.pi * k / seg
                if axis == "f":
                    ring.append(bm.verts.new(P(cl + r * math.sin(t), cf + s, cu + r * math.cos(t))))
                else:
                    ring.append(bm.verts.new(P(cl + s, cf + r * math.cos(t), cu + r * math.sin(t))))
        rings.append(ring)
    for a, b in zip(rings[:-1], rings[1:]):
        if len(a) == 1 and len(b) == 1:
            continue
        if len(a) == 1:
            for k in range(seg):
                bm.faces.new((a[0], b[k], b[(k + 1) % seg]))
        elif len(b) == 1:
            for k in range(seg):
                bm.faces.new((a[k], b[0], a[(k + 1) % seg]))
        else:
            for k in range(seg):
                bm.faces.new((a[k], b[k], b[(k + 1) % seg], a[(k + 1) % seg]))
    if len(rings[0]) > 1:
        bm.faces.new(list(reversed(rings[0])))
    if len(rings[-1]) > 1:
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def cyl(name, r, f0, f1, l, u, seg=32, mat=None):
    return lathe(name, [(f0, 0.0), (f0, r), (f1, r), (f1, 0.0)], (l, 0.0, u), "f", mat, seg)


def box(name, l0, l1, f0, f1, u0, u1, mat=None):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = P(l0 + (v.co.x + 0.5) * (l1 - l0), f0 + (v.co.y + 0.5) * (f1 - f0), u0 + (v.co.z + 0.5) * (u1 - u0))
    return obj_from_bm(name, bm, mat)


def sweep(name, path, rad_lat, rad_in, mat=None, seg=20, closed_ends=True):
    """An oval tube along a path in the (f, u) plane at l = 0: rad_lat across the gun, rad_in in the plane."""
    pts = [Vector(p) for p in path]
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, len(pts) - 1)]
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))
        ring = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            q = p + nrm * (rad_in * math.cos(th))
            ring.append(bm.verts.new(P(rad_lat * math.sin(th), q.x, q.y)))
        rings.append(ring)
    for a, b in zip(rings[:-1], rings[1:]):
        for k in range(seg):
            bm.faces.new((a[k], b[k], b[(k + 1) % seg], a[(k + 1) % seg]))
    if closed_ends:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def realise(ob):
    """Bake the object's modifiers into its mesh."""
    dg = bpy.context.evaluated_depsgraph_get()
    ev = ob.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(ev)
    old = ob.data
    ob.modifiers.clear()
    ob.data = me
    if old.users == 0:
        bpy.data.meshes.remove(old)
    return ob


WARN = []


def boolean(ob, other, op="DIFFERENCE", keep=False):
    """An exact boolean, baked. If it loses the mesh (the solver gives up on a bad input, usually
    faces exactly touching) it is tried once more with the other part nudged 10 microns, self-intersection and hole-tolerant on; failing
    that the original is kept and the failure listed (printed at the end)."""
    before = ob.data.copy()
    n0 = len(before.vertices)
    for attempt in range(2):
        m = ob.modifiers.new("b", "BOOLEAN")
        m.operation = op
        m.solver = "EXACT"
        m.object = other
        if attempt:
            m.use_self = True
            m.use_hole_tolerant = True
        realise(ob)
        if not (len(ob.data.vertices) == 0 or (op != "INTERSECT" and len(ob.data.vertices) < n0 * 0.5)):
            bpy.data.meshes.remove(before)
            break
        lost = len(ob.data.vertices)
        old = ob.data
        ob.data = before.copy()
        bpy.data.meshes.remove(old)
        other.data.transform(Matrix.Translation((1e-5, 1.3e-5, 0.7e-5)))
    else:
        WARN.append("%s %s %s: %d -> %d verts, kept the original" % (ob.name, op, other.name, n0, lost))
        bpy.data.meshes.remove(before)
    if not keep:
        bpy.data.objects.remove(other, do_unlink=True)
    return ob


def union(ob, *others):
    for o in others:
        boolean(ob, o, "UNION")
    return ob


def cut(ob, *others, keep=False):
    for o in others:
        boolean(ob, o, "DIFFERENCE", keep)
    return ob


def dup(ob, name):
    c = ob.copy()
    c.data = ob.data.copy()
    c.name = name
    bpy.context.collection.objects.link(c)
    return c


def bevel(ob, width, seg=3, angle=32.0):
    m = ob.modifiers.new("bevel", "BEVEL")
    m.width = width * IN
    m.segments = seg
    m.limit_method = "ANGLE"
    m.angle_limit = math.radians(angle)
    m.use_clamp_overlap = True
    m.miter_outer = "MITER_ARC"
    m.profile = 0.5
    realise(ob)
    return ob


def finish(ob, sharp_deg=38.0):
    me = ob.data
    me.validate()
    me.shade_smooth()
    me.set_sharp_from_angle(angle=math.radians(sharp_deg))
    return ob


def box_uv(ob, tile=0.05):
    """UVs by box projection, a tile every `tile` metres: the surfaces are tiling materials
    (case colours, bluing, walnut), so the texel size is the same on every part. Walnut's grain runs
    along the grip (u)."""
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    for face in bm.faces:
        n = face.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            c = ob.matrix_world @ loop.vert.co
            if ax == 0:
                loop[uv].uv = (c.y / tile, c.z / tile)
            elif ax == 1:
                loop[uv].uv = (c.x / tile, c.z / tile)
            else:
                # top and bottom faces: u along the bore too (polish lines and grain run with the gun)
                loop[uv].uv = (c.y / tile, c.x / tile)
    bm.to_mesh(me)
    bm.free()
    me.uv_layers[0].name = "UVMap"  # bmesh names a new layer "Float2"; the paint bake asks for "UVMap"


# --- Materials (placeholders until the surfaces: README "The surfaces") --------------------------
def material(name, color, metallic, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Metallic"].default_value = metallic
    b.inputs["Roughness"].default_value = rough
    return m


MAT = {}


def mats():
    MAT["case"] = material("saa_case", (0.20, 0.185, 0.17), 1.0, 0.34)     # colour case-hardened (frame, hammer, gate)
    MAT["blued"] = material("saa_blued", (0.055, 0.06, 0.075), 1.0, 0.30)  # blued steel
    MAT["fire"] = material("saa_fire_blue", (0.04, 0.06, 0.12), 1.0, 0.25)  # fire-blued screws, pins
    MAT["bright"] = material("saa_bright", (0.55, 0.55, 0.56), 1.0, 0.35)  # bright steel (firing pin, ejector rod)
    MAT["walnut"] = material("saa_walnut", (0.20, 0.10, 0.05), 0.0, 0.45)
    MAT["bore"] = material("saa_bore", (0.03, 0.03, 0.035), 1.0, 0.6)
    MAT["brass"] = material("saa_brass", (0.78, 0.58, 0.30), 1.0, 0.35)
    MAT["lead"] = material("saa_lead", (0.30, 0.30, 0.31), 0.6, 0.55)
    MAT["primer"] = material("saa_primer", (0.66, 0.40, 0.25), 1.0, 0.4)


# --- The parts ------------------------------------------------------------------------------------
def make_frame():
    """The main frame: frame front round the barrel's shank and base pin, the bottom under the
    cylinder's window, the top strap with its rear-sight groove, the round recoil shield, the rear
    frame round the hammer and lockwork, cut for the hammer, trigger, bolt, base pin, ejector rod,
    loading channel and gate."""
    fb = D["frame_bottom"]
    ts0, ts1 = D["top_strap"]
    # Frame front: side outline (its foot rounding into the lower edge, as on the Met gun), then
    # rounded across by intersecting with a rounded section.
    front = prism("Frame", [(F_BARREL - 0.01, ts1), (F_FRONT - 0.25, ts1 - 0.01), (F_FRONT - 0.10, ts1 - 0.04), (F_FRONT, 0.40),
                            (F_FRONT, -0.85), (F_FRONT - 0.10, -0.98), (F_FRONT - 0.19, -1.10), (F_FRONT - 0.24, -1.40),
                            (F_FRONT - 0.29, -1.58), (F_FRONT - 0.36, -1.66), (F_BARREL - 0.01, -1.72)], 0.45,
                  MAT["case"], corners=(0, 3, 4, 10))
    front_round = lathe("fr", [(F_BARREL - 0.05, 0.0), (F_BARREL - 0.05, 0.47), (F_FRONT + 0.05, 0.47), (F_FRONT + 0.05, 0.0)],
                        (0.0, 0.0, 0.0), "f", None, 64)
    below = box("fb", -0.40, 0.40, F_BARREL - 0.05, F_FRONT + 0.05, fb - 0.3, -0.05)
    union(front_round, below)
    boolean(front, front_round, "INTERSECT")
    # The top strap.
    # The top strap, carried back to the hammer's face at 0.46 (the Met gun's line).
    strap = prism("strap", [(F_SHIELD_BACK, ts1 - 0.02), (-0.17, ts1), (F_BARREL + 0.05, ts1), (F_BARREL + 0.05, ts0),
                            (-0.10, ts0 - 0.04), (F_SHIELD_BACK, ts0 - 0.10)], 0.27, smooth=False)
    # The recoil shield: turned about the cylinder's axis, its back rounded into the rear frame.
    shield = lathe("shield", [(F_SHIELD_BACK - 0.14, 0.0), (F_SHIELD_BACK - 0.14, 0.50), (F_SHIELD_BACK - 0.05, 0.66),
                              (F_SHIELD_BACK + 0.04, 0.76), (F_SHIELD - 0.06, 0.80), (F_SHIELD, 0.80), (F_SHIELD, 0.0)],
                   (0.0, 0.0, CA), "f", None, 96)
    # The lower frame under the window and the rear frame round the lockwork, one side outline: its
    # lower edge measured off the Met gun (FRAME_BOTTOM); its back behind the shield where the
    # hammer stands out of it, down the backstrap's front, to where the walnut meets it.
    # Its lower edge from the back forward: over the guard's tang (TANG above FRAME_BOTTOM) as far as
    # the bow's front, then down onto the measured edge.
    edge = []
    for f, u in reversed(FRAME_BOTTOM):
        if f >= TANG_FRONT and not any(q[0] >= TANG_FRONT for q in edge):
            edge += [(TANG_FRONT - 0.04, frame_bottom_at(TANG_FRONT) + TANG), (TANG_FRONT, frame_bottom_at(TANG_FRONT))]
        edge.append((f, u + (TANG if f < TANG_FRONT else 0.0)))
    lower = [(F_BARREL + 0.02, -1.37), (-0.10, -1.37), (-0.10, 0.40), (-0.17, 0.42), (-0.36, 0.30), (-0.52, 0.10),
             (-0.68, -0.10), (-0.84, -0.26), (-0.86, -1.15), (-1.00, -1.32)] + edge + [(F_BARREL + 0.02, -1.70)]
    rear = prism("rear", lower, 0.44, corners=(0, 1, 2, 9, 10, len(lower) - 1))
    union(front, strap, shield, rear)
    # The cylinder's window; the barrel's thread; the base pin; the ejector rod's channel.
    cut(front, cyl("win", RC + 0.012, F_SHIELD, F_BARREL, 0.0, CA, 96))
    cut(front, box("win2", -1.0, 1.0, F_SHIELD, F_BARREL, -1.37, CA), )
    cut(front, cyl("thread", D["barrel_od_breech"] / 2 - 0.01, F_BARREL - 0.01, F_FRONT + 0.1, 0.0, 0.0, 48))
    cut(front, cyl("pin", D["base_pin"] / 2 + 0.003, F_SHIELD - 0.3, F_FRONT + 0.1, 0.0, CA, 24))
    gl, gu = gate_chamber()
    cut(front, cyl("rodch", 0.13, F_BARREL - 0.02, F_FRONT + 0.1, gl, gu, 24))
    # The bushing's recess in the frame front, the ratchet's in the shield.
    cut(front, cyl("bush", 0.20, F_BARREL - 0.02, F_BARREL + 0.04, 0.0, CA, 32))
    cut(front, cyl("ratch", 0.33, F_SHIELD - 0.07, F_SHIELD + 0.01, 0.0, CA, 48))
    # The hammer's slot and the firing pin's hole; the trigger's slot underneath; the bolt's.
    cut(front, box("hslot", -0.165, 0.165, -1.30, F_SHIELD_BACK, -1.95, 1.2))
    cut(front, cyl("fpin", 0.06, F_SHIELD - 0.4, F_SHIELD + 0.01, 0.0, 0.0, 20))
    cut(front, box("tslot", -0.09, 0.09, -0.56, 0.04, -2.5, -1.62))
    cut(front, box("bslot", -0.07, 0.07, 0.02, 0.34, -1.85, -1.30))
    # The rear sight: a groove along the top strap's back.
    groove = prism("groove", [(-0.60, ts1 - 0.05), (0.30, ts1 - 0.05), (0.45, ts1 + 0.05), (-0.60, ts1 + 0.05)], 0.045, smooth=False)
    cut(front, groove)
    # The loading channel: the gate's chamber, out through the shield to the rear frame's side.
    cut(front, cyl("chan", D["rim"] / 2 + 0.012, F_SHIELD_BACK - 0.20, F_SHIELD + 0.02, gl, gu, 40))
    # The gate's place in the shield (make_gate makes the gate from the same volume, a hair smaller).
    c2 = cyl("gc2", D["rim"] / 2 + 0.064, F_SHIELD - 0.5, F_SHIELD + 0.1, gl, gu, 40)
    cut(c2, cyl("hub2", 0.396, F_SHIELD - 0.6, F_SHIELD + 0.2, 0.0, CA, 48))
    cut(front, c2)
    bevel(front, 0.028, 3, 30)
    return front


def make_gate(frame_ob):
    """The loading gate: the part of the recoil shield over the gate's chamber, hinged at its lower
    outer edge on an axis along the bore; it swings out and down to open."""
    gl, gu = gate_chamber()
    shield = lathe("Gate", [(F_SHIELD_BACK - 0.0, 0.0), (F_SHIELD_BACK, 0.66), (F_SHIELD_BACK + 0.04, 0.76),
                            (F_SHIELD - 0.06, 0.80), (F_SHIELD - 0.005, 0.80), (F_SHIELD - 0.005, 0.0)],
                   (0.0, 0.0, CA), "f", MAT["case"], 96)
    c = cyl("gc", D["rim"] / 2 + 0.06, F_SHIELD - 0.5, F_SHIELD + 0.1, gl, gu, 40)
    boolean(shield, c, "INTERSECT")
    # Not into the hub: the gate is the outer flap.
    cut(shield, cyl("hub", 0.40, F_SHIELD - 0.5, F_SHIELD + 0.1, 0.0, CA, 48))
    bevel(shield, 0.012, 2, 30)
    a = math.radians(GATE_DEG + 38.0)
    hinge = (0.79 * math.sin(a), F_SHIELD - 0.15, CA + 0.79 * math.cos(a))
    return shield, hinge


def make_barrel():
    ro0 = D["barrel_od_breech"] / 2
    ro1 = D["barrel_od_muzzle"] / 2
    rb = D["bore"] / 2
    prof = [(F_BARREL + 0.10, rb), (F_BARREL, rb + 0.06), (F_BARREL, 0.41), (F_FRONT, 0.41), (F_FRONT, ro0 + 0.012),
            (F_FRONT + 0.03, ro0), (MUZZLE - 0.03, ro1), (MUZZLE - 0.004, ro1 - 0.012), (MUZZLE, ro1 - 0.04),
            (MUZZLE, rb + 0.05), (MUZZLE - 0.03, rb + 0.004), (MUZZLE - 0.06, rb)]
    # Outer profile then the bore back out to the breech: a closed section turned.
    ring = prof + [(F_BARREL + 0.10, rb)]
    bm = bmesh.new()
    seg = 72
    rings = []
    for s, r in ring[:-1]:
        rings.append([bm.verts.new(P(r * math.sin(2 * math.pi * k / seg), s, r * math.cos(2 * math.pi * k / seg))) for k in range(seg)])
    n = len(rings)
    for i in range(n):
        a, b = rings[i], rings[(i + 1) % n]
        for k in range(seg):
            bm.faces.new((a[k], b[k], b[(k + 1) % seg], a[(k + 1) % seg]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    barrel = obj_from_bm("Barrel", bm, MAT["blued"])
    # The front sight: a half-moon blade, part of the barrel.
    # The front sight: a tall half-moon blade 0.40-0.92" back from the muzzle (the Met gun's).
    T = FRONT_BLADE_TOP
    blade = prism("blade", [(MUZZLE - 0.95, 0.25), (MUZZLE - 0.93, ro1 + 0.03), (MUZZLE - 0.84, T - 0.11), (MUZZLE - 0.72, T - 0.01),
                            (MUZZLE - 0.62, T), (MUZZLE - 0.52, T - 0.03), (MUZZLE - 0.44, T - 0.13), (MUZZLE - 0.40, ro1 + 0.03),
                            (MUZZLE - 0.39, 0.25)], 0.035, corners=(0, 8))
    bevel(blade, 0.008, 2, 40)
    union(barrel, blade)
    # Six grooves in the bore (rifling): seen at the muzzle.
    for k in range(6):
        a = 2 * math.pi * k / 6
        g = box("rifl", -0.035, 0.035, MUZZLE - 1.2, MUZZLE + 0.01, rb - 0.01, D["groove"] / 2)
        g.rotation_euler = (0.0, -a, 0.0)
        g.location = (0, 0, 0)
        bpy.context.view_layer.update()
        g.data.transform(Matrix.Rotation(a, 4, "Y"))
        g.rotation_euler = (0, 0, 0)
        cut(barrel, g)
    barrel.data.materials.append(MAT["bore"])
    # The bore's faces dark.
    for poly in barrel.data.polygons:
        c = Vector(poly.center) / IN
        if math.hypot(c.x, c.z) < D["groove"] / 2 + 0.003 and c.y < MUZZLE - 0.005:
            poly.material_index = 1
    return barrel


def make_ejector():
    """The ejector housing (on the barrel's right, under it) with its slot, the rod and its
    crescent head (moves back by the stroke), the tube's screw at its front."""
    gl, gu = gate_chamber()
    ro = D["eject_od"] / 2
    L = min(D["eject_len"], MUZZLE - F_FRONT - 0.08)
    f0, f1 = F_FRONT + 0.005, F_FRONT + L
    house = lathe("EjectorHousing", [(f0, 0.0), (f0, ro - 0.02), (f0 + 0.03, ro), (f1 - 0.16, ro), (f1 - 0.07, ro - 0.03),
                                     (f1 - 0.01, ro - 0.09), (f1, 0.0)], (gl, 0.0, gu), "f", MAT["blued"], 48)
    # The web that seats it on the barrel.
    web = prism("web", [(f0, 0.0), (f1 - 0.10, 0.0), (f1 - 0.10, -0.25), (f0, -0.25)], 0.0, smooth=False,
                l0=0.10, l1=gl)
    union(house, web)
    cut(house, cyl("rodbore", D["eject_rod"] / 2 + 0.01, f0 - 0.1, f1 - 0.12, gl, gu, 24))
    # The slot along its lower outer side, the head's stem riding in it.
    dirn = Vector((math.cos(math.radians(-62)), math.sin(math.radians(-62))))  # (l, u) outward and down: it hangs under the housing
    slot_len = D["eject_stroke"] + 0.20
    s1 = f1 - 0.52  # the head rests ~0.6" behind the housing's front (the Met gun's at 5.65" from the cylinder)
    s0 = s1 - slot_len
    sl = box("slot", -0.05, 0.05, s0, s1, 0.0, ro + 0.1)
    # orient: the box's +u along dirn
    sl.data.transform(Matrix.Translation(P(gl, 0, gu)) @ Matrix.Rotation(math.atan2(dirn.x, dirn.y), 4, "Y"))
    cut(house, sl)
    bevel(house, 0.01, 2, 35)
    # The rod: rest with its rear tip just ahead of the cylinder's face, in the frame's channel.
    tip = F_CYL1 + 0.03
    head_f = s1 - 0.10
    rod = lathe("Ejector", [(tip, 0.0), (tip, D["eject_rod"] / 2 - 0.02), (tip + 0.02, D["eject_rod"] / 2),
                            (head_f + 0.05, D["eject_rod"] / 2), (head_f + 0.05, 0.0)], (gl, 0.0, gu), "f", MAT["bright"], 24)
    # Its head: a crescent thumb-piece on a stem out through the slot.
    hd = Vector((gl, gu)) + dirn * (ro + 0.10)
    head = lathe("head", [(-0.075, 0.0), (-0.075, 0.12), (-0.06, 0.15), (0.06, 0.15), (0.075, 0.12), (0.075, 0.0)],
                 (hd.x, head_f, hd.y), "f", None, 40)
    # crescent: cut the inner side of the disc away
    inner = Vector((gl, gu)) + dirn * (ro + 0.02)
    cut(head, cyl("cres", 0.15, head_f - 0.2, head_f + 0.2, inner.x, inner.y, 40))
    stem2 = box("stem2", -0.035, 0.035, head_f - 0.04, head_f + 0.04, 0.0, ro + 0.12)
    stem2.data.transform(Matrix.Translation(P(gl, 0, gu)) @ Matrix.Rotation(math.atan2(dirn.x, dirn.y), 4, "Y"))
    union(head, stem2)
    bevel(head, 0.01, 2, 35)
    union(rod, head)
    rod.data.materials.append(MAT["blued"])
    # screw at the housing's front, on its right
    return house, rod, (tip, head_f, f1, s0, s1)


def make_cylinder():
    """Six chambers through, six flutes between them, a bolt notch over each chamber with its lead,
    the ratchet at the back, the bushing at the front. Clockwise seen from behind."""
    r = RC
    L = F_CYL1
    body = lathe("Cylinder", [(0.0, 0.0), (0.0, r - 0.03), (0.03, r), (L - 0.05, r), (L - 0.005, r - 0.035), (L, r - 0.06), (L, 0.0)],
                 (0.0, 0.0, CA), "f", MAT["blued"], 128)
    bc = D["bolt_circle"]
    for k in range(6):
        a = math.radians(60 * k)
        cl, cu = bc * math.sin(a), CA + bc * math.cos(a)
        ch = lathe("ch", [(-0.1, 0.0), (-0.1, D["chamber"] / 2), (L - 0.03, D["chamber"] / 2), (L + 0.01, D["chamber"] / 2 + 0.03),
                          (L + 0.1, D["chamber"] / 2 + 0.03), (L + 0.1, 0.0)], (cl, 0.0, cu), "f", None, 40)
        cut(body, ch)
        # Flutes between the chambers: a long round-ended groove.
        fa = a + math.radians(30)
        rf = 0.165
        rr = r + rf - 0.105
        fl = lathe("fl", [(0.0, 0.0), (0.02, 0.07), (0.07, 0.13), (0.14, rf), (0.95, rf), (1.02, 0.13), (1.07, 0.07), (1.09, 0.0)],
                   (rr * math.sin(fa), 0.38, CA + rr * math.cos(fa)), "f", None, 32)
        cut(body, fl)
        # Bolt notch over the chamber, the lead ahead of it (the side that reaches the bolt first).
        nr = r
        for (da, w, depth, f0, f1, nm) in [(0.0, 0.135, 0.055, 0.10, 0.27, "nt"), (9.0, 0.075, 0.022, 0.14, 0.23, "ld")]:
            aa = a + math.radians(da)
            nb = box(nm, -w / 2, w / 2, f0, f1, nr - depth, nr + 0.2)
            nb.data.transform(Matrix.Translation(P(0, 0, CA)) @ Matrix.Rotation(-aa, 4, "Y"))
            cut(body, nb)
    # The ratchet: six teeth at the back, standing into the shield's recess.
    bm = bmesh.new()
    pts = []
    for k in range(12):
        a = math.radians(30 * k)
        rr = 0.30 if k % 2 == 0 else 0.20
        pts.append((rr * math.sin(a), rr * math.cos(a)))
    top = [bm.verts.new(P(x, 0.0, CA + y)) for x, y in pts]
    bot = [bm.verts.new(P(x, -0.055, CA + y)) for x, y in pts]
    bm.faces.new(top)
    bm.faces.new(list(reversed(bot)))
    for i in range(12):
        j = (i + 1) % 12
        bm.faces.new((bot[i], bot[j], top[j], top[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    ratchet = obj_from_bm("ratchet", bm)
    union(body, ratchet)
    bush = lathe("bush", [(L - 0.01, 0.0), (L - 0.01, 0.17), (L + 0.035, 0.17), (L + 0.035, 0.0)], (0.0, 0.0, CA), "f", None, 32)
    union(body, bush)
    cut(body, cyl("pinhole", D["base_pin"] / 2 + 0.004, -0.2, L + 0.2, 0.0, CA, 24))
    bevel(body, 0.008, 2, 40)
    return body


def make_rounds():
    """A loaded round in each chamber: the brass case (rim, primer) and the lead bullet, separate so
    the game can show loaded, spent (case only) or empty."""
    out = []
    bc = D["bolt_circle"]
    rim_f = -D["rim_t"]
    for k in range(6):
        a = math.radians(60 * k)
        cl, cu = bc * math.sin(a), CA + bc * math.cos(a)
        case = lathe("Case%d" % k, [(rim_f, 0.0), (rim_f, D["rim"] / 2 - 0.01), (rim_f + 0.01, D["rim"] / 2), (0.0, D["rim"] / 2),
                                    (0.0, 0.232), (0.02, 0.236), (D["case_len"] + rim_f - 0.01, 0.236), (D["case_len"] + rim_f, 0.228),
                                    (D["case_len"] + rim_f, 0.0)], (cl, 0.0, cu), "f", MAT["brass"], 40)
        primer = lathe("pr", [(rim_f - 0.004, 0.0), (rim_f - 0.004, 0.100), (rim_f + 0.02, 0.100), (rim_f + 0.02, 0.0)],
                       (cl, 0.0, cu), "f", None, 24)
        cut(case, cyl("pk", 0.106, rim_f - 0.01, rim_f + 0.012, cl, cu, 24), )
        union(case, primer)
        case.data.materials.append(MAT["primer"])
        for poly in case.data.polygons:
            c = Vector(poly.center) / IN
            if math.hypot(c.x - cl, c.z - cu) < 0.101 and c.y < rim_f + 0.005:
                poly.material_index = 1
        b0 = D["case_len"] + rim_f - 0.35
        tipf = D["oal"] + rim_f
        bull = lathe("Bullet%d" % k, [(b0, 0.0), (b0, 0.225), (D["case_len"] + rim_f + 0.06, 0.227), (tipf - 0.22, 0.20),
                                      (tipf - 0.12, 0.15), (tipf - 0.04, 0.085), (tipf, 0.0)], (cl, 0.0, cu), "f", MAT["lead"], 32)
        out.append((case, bull))
    return out


def make_hammer():
    """The hammer at rest, its outline off the Met gun: the face at the shield, the top dipping behind
    it and the slim spur curling up and back over the grip; its lower body (inside the frame) down
    round its screw, low on the frame."""
    body = prism("Hammer", [(-0.335, 0.40), (-0.335, -0.12), (-0.42, -0.45), (-0.48, -0.95), (-0.50, -1.35), (-0.56, -1.66),
                            (-0.72, -1.78), (-0.88, -1.70), (-0.95, -1.45), (-0.92, -1.0), (-0.92, -0.55), (-0.96, -0.32),
                            (-1.10, -0.20), (-0.90, 0.13), (-0.70, 0.235), (-0.55, 0.36), (-0.40, 0.47)], 0.155, MAT["case"],
                 corners=(0, 1))
    spur = prism("spur", [(-0.96, -0.32), (-1.10, -0.20), (-1.27, -0.08), (-1.40, 0.09), (-1.52, 0.26), (-1.63, 0.39),
                          (-1.71, 0.48), (-1.67, 0.525), (-1.50, 0.515), (-1.35, 0.435), (-1.20, 0.325), (-1.05, 0.24),
                          (-0.88, 0.20), (-0.80, 0.0)], 0.165, corners=(6,))
    union(body, spur)
    # The spur's checkering is the surface's (a normal map in the surfaces pass): cut as geometry
    # the exact solver dropped a third of the grooves.
    bevel(body, 0.025, 3, 30)
    fp = lathe("fp", [(-0.40, 0.0), (-0.40, 0.065), (-0.30, 0.055), (F_SHIELD - 0.01, 0.035), (F_SHIELD + 0.002, 0.0)],
               (0.0, 0.0, 0.0), "f", None, 20)
    union(body, fp)
    return body


def make_trigger():
    """A slim blade curving down and back in the guard, on its screw (the Met gun's)."""
    blade = prism("Trigger", [(-0.04, -1.66), (-0.48, -1.70), (-0.50, -2.05), (-0.47, -2.35), (-0.42, -2.62), (-0.34, -2.80),
                              (-0.26, -2.85), (-0.22, -2.78), (-0.29, -2.60), (-0.34, -2.35), (-0.36, -2.10), (-0.20, -1.95),
                              (-0.08, -1.88)], 0.07, MAT["blued"], corners=(0, 1))
    bevel(blade, 0.02, 3, 30)
    return blade


def make_bolt():
    """The cylinder stop: a lever from its screw up into the notch under the cylinder."""
    b = prism("Bolt", [(0.02, -1.76), (0.20, -1.76), (0.30, -1.40), (0.27, -1.30), (0.19, -1.30), (0.10, -1.48)], 0.055,
              MAT["blued"], corners=(2, 3, 4))
    bevel(b, 0.01, 2, 30)
    return b


# The grip: a loft of rounded sections between its front and back curves.
# The "plowhandle", measured off the Met gun's side photo (59.143.4; README "The reference"): the
# backstrap one curve from under the hammer, sweeping back to the heel; the front strap from the guard
# nearly upright to the toe; the butt flat at -4.66, its heel and toe rounded.
GRIP_FRONT = [(-0.98, -2.40), (-1.28, -2.55), (-1.56, -2.74), (-1.68, -2.92), (-1.77, -3.11), (-1.81, -3.30), (-1.82, -3.55),
              (-1.80, -3.86), (-1.77, -4.10), (-1.74, -4.38), (-1.72, -4.68)]
GRIP_BACK = [(-1.00, -0.30), (-1.01, -0.60), (-1.02, -0.90), (-1.07, -1.06), (-1.14, -1.20), (-1.24, -1.30), (-1.42, -1.345),
             (-1.65, -1.37), (-1.83, -1.42), (-2.035, -1.48), (-2.235, -1.57), (-2.435, -1.71), (-2.635, -1.89), (-2.835, -2.12),
             (-3.035, -2.44), (-3.235, -2.87), (-3.435, -3.38), (-3.615, -3.86), (-3.765, -4.20), (-3.87, -4.45), (-3.89, -4.68)]


def resample(pts, n):
    v = [Vector(p) for p in pts]
    d = [0.0]
    for a, b in zip(v[:-1], v[1:]):
        d.append(d[-1] + (b - a).length)
    out = []
    for i in range(n):
        t = d[-1] * i / (n - 1)
        j = max(k for k in range(len(d)) if d[k] <= t + 1e-9)
        j = min(j, len(v) - 2)
        s = (t - d[j]) / max(d[j + 1] - d[j], 1e-9)
        # Catmull-Rom between v[j] and v[j+1]
        p0 = v[max(j - 1, 0)]
        p1, p2 = v[j], v[j + 1]
        p3 = v[min(j + 2, len(v) - 1)]
        s2, s3 = s * s, s * s * s
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s2 + (-p0 + 3 * p1 - 3 * p2 + p3) * s3))
    return out


def grip_loft(name, grow=0.0, mat=None, n=40, ring=48):
    """Sections from the top (over the frame, behind the hammer) to the butt. Each section is a
    superellipse between the front and back curves, as wide as the grip at that height."""
    back = resample(GRIP_BACK, n)
    # The front curve, carried up above the grip's top along the frame (the sections above the walnut
    # only feed the backstrap's tang).
    fr_ext = [(-0.40, 0.30), (-0.60, -0.60), (-0.80, -1.50)] + GRIP_FRONT
    front = resample(fr_ext, n)
    bm = bmesh.new()
    rings = []
    for i in range(n):
        t = i / (n - 1)
        F, B = front[i], back[i]
        mid = (F + B) / 2
        ch = (B - F)
        a = ch.length / 2 + grow
        cdir = ch.normalized()
        hw = (0.36 + 0.30 * min(1.0, max(0.0, (t - 0.2) / 0.7)) ** 0.8) + grow  # 0.72" at the top to 1.32" at the butt
        if t < 0.25:
            hw = 0.36 + grow
        e = 2.6
        rr = []
        for k in range(ring):
            ph = 2 * math.pi * k / ring
            c, s = math.cos(ph), math.sin(ph)
            x = math.copysign(abs(c) ** (2 / e), c) * a
            y = math.copysign(abs(s) ** (2 / e), s) * hw
            q = mid + cdir * x
            rr.append(bm.verts.new(P(y, q.x, q.y)))
        rings.append(rr)
    for a_, b_ in zip(rings[:-1], rings[1:]):
        for k in range(ring):
            bm.faces.new((a_[k], b_[k], b_[(k + 1) % ring], a_[(k + 1) % ring]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def offset_curve(pts, d, n=60):
    """The curve moved d inches to its left (read along the curve's direction)."""
    v = resample(pts, n)
    out = []
    for i, p in enumerate(v):
        a = v[max(i - 1, 0)]
        b = v[min(i + 1, n - 1)]
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))
        out.append(p + nrm * d)
    return v, out


def band(name, pts, inward, outward, hw):
    """A strip along a curve (side outline) extruded across: for the straps."""
    v, inner = offset_curve(pts, inward)
    _, outer = offset_curve(pts, -outward)
    poly = [(p.x, p.y) for p in outer] + [(p.x, p.y) for p in reversed(inner)]
    return prism(name, poly, hw, smooth=False)


def make_grip_frame():
    """The backstrap (from its tang behind the hammer round the butt) and the trigger guard (tang
    under the frame, bow, front strap down the grip's front to the toe), both cut from the grip's
    loft so they wrap it; the walnut is what's between them."""
    outer = grip_loft("outer", 0.0)
    # Backstrap: along the back curve and under the butt to the toe.
    bs_band = band("bsb", GRIP_BACK, 0.13, 0.3, 1.0)
    # The butt: the loft's bottom 0.10" (a cut along the butt chord).
    bv = Vector(GRIP_FRONT[-1]) - Vector(GRIP_BACK[-1])
    bn = Vector((bv.y, -bv.x)).normalized()  # pointing up into the grip
    if bn.y < 0:
        bn = -bn
    h0 = Vector(GRIP_BACK[-1]) - bv.normalized() * 0.4
    h1 = Vector(GRIP_FRONT[-1]) + bv.normalized() * 0.4
    butt_poly = [(h0 - bn * 0.3).to_tuple(), (h1 - bn * 0.3).to_tuple(), (h1 + bn * 0.11).to_tuple(), (h0 + bn * 0.11).to_tuple()]
    butt_pr = prism("bp", [(p[0], p[1]) for p in butt_poly], 1.0, smooth=False)
    union(bs_band, butt_pr)
    backstrap = dup(outer, "Backstrap")
    boolean(backstrap, bs_band, "INTERSECT", keep=True)
    # The hammer's channel through the tang.
    cut(backstrap, box("hch", -0.17, 0.17, -1.4, -0.3, -1.95, 1.0))
    # Not into the frame: the frame's rear outline.
    # The frame's place (the walnut and straps stop at it): its rear outline (make_frame's) and below.
    rear = prism("rr", [(0.5, 1.2), (-0.10, 1.2), (-0.10, 0.40), (-0.17, 0.42), (-0.36, 0.30), (-0.52, 0.10), (-0.68, -0.10),
                        (-0.84, -0.26), (-0.86, -1.15), (-1.00, -1.32)] + [(f, u) for f, u in reversed(FRAME_BOTTOM)] + [(0.5, -1.6)],
                 1.0, corners=(0, 1, 2, 9, 10))
    cut(backstrap, rear, keep=True)
    backstrap.data.materials.append(MAT["blued"])
    bevel(backstrap, 0.015, 2, 35)
    # Front strap (part of the guard).
    fs_band = band("fsb", list(reversed(GRIP_FRONT)), 0.12, 0.3, 1.0)
    guard = dup(outer, "TriggerGuard")
    boolean(guard, fs_band, "INTERSECT")
    cut(guard, rear, keep=True)
    cut(guard, prism("bp3", [(p[0], p[1]) for p in butt_poly], 1.0, smooth=False))
    # The bow and the tang under the frame.
    # The bow (its centre line; the Met gun's outline is 0.085 outside it) and the tang under the frame.
    bow_path = [(0.80, -1.96), (0.79, -2.30), (0.72, -2.58), (0.56, -2.80), (0.32, -2.93), (0.05, -2.995), (-0.20, -3.005),
                (-0.38, -2.95), (-0.52, -2.80), (-0.60, -2.62), (-0.72, -2.50), (-0.92, -2.43)]
    bow = sweep("bow", [(p.x, p.y) for p in resample(bow_path, 48)], 0.14, 0.058, None, 24)
    under = [(TANG_FRONT, frame_bottom_at(TANG_FRONT))] + [(f, u) for f, u in FRAME_BOTTOM if f < TANG_FRONT]
    tang = prism("tang", [(f, u + TANG + 0.01) for f, u in under] + list(reversed(under)), 0.30, smooth=False)
    union(guard, bow, tang)
    guard.data.materials.append(MAT["blued"])
    bevel(guard, 0.012, 2, 35)
    # The walnut: the loft less the straps and butt, below the frame.
    walnut = grip_loft("Grip", -0.012, MAT["walnut"])
    cut(walnut, rear)
    cut(walnut, bs_band)
    fs2 = band("fsb2", list(reversed(GRIP_FRONT)), 0.12, 0.3, 1.0)
    cut(walnut, fs2)
    bevel(walnut, 0.02, 2, 30)
    bpy.data.objects.remove(outer, do_unlink=True)
    return backstrap, guard, walnut


def screw(name, center, axis, r=0.085, head=0.03, slot_deg=0.0, dome=True, mat=None):
    """A screw head: domed, slotted; `axis` the way the head faces (unit (l, f, u))."""
    prof = [(0.0, 0.0), (0.0, r), (head * 0.4, r - 0.005), (head * 0.8, r * 0.75), (head, 0.0)] if dome else \
        [(0.0, 0.0), (0.0, r), (head, r - 0.008), (head, 0.0)]
    ob = lathe(name, [(-0.04, 0.0), (-0.04, r)] + prof[1:], (0.0, 0.0, 0.0), "f", mat or MAT["fire"], 32)
    sl = box("slot", -r * 1.2, r * 1.2, head * 0.35, head + 0.05, -0.012, 0.012)
    sl.data.transform(Matrix.Rotation(math.radians(slot_deg), 4, "Y"))
    cut(ob, sl)
    # point +f (local) along axis
    ax = Vector(axis).normalized()
    rot = Vector((0, 1, 0)).rotation_difference(Vector((ax[0], ax[1], ax[2])))
    ob.data.transform(rot.to_matrix().to_4x4())
    ob.data.transform(Matrix.Translation(P(*center)))
    return ob


# --- Build, place, export ---------------------------------------------------------------------------
def set_pivot(ob, pivot):
    """Move the object's origin to `pivot` (design inches) without moving its mesh."""
    p = P(*pivot)
    ob.data.transform(Matrix.Translation(-p))
    ob.location = p


def build():
    clear()
    mats()
    parts = {}
    frame = make_frame()
    gate, hinge = make_gate(frame)
    parts["Frame"] = frame
    parts["Gate"] = gate
    parts["Barrel"] = make_barrel()
    house, rod, ej = make_ejector()
    parts["EjectorHousing"] = house
    parts["Ejector"] = rod
    parts["Cylinder"] = make_cylinder()
    rounds = make_rounds()
    pin = lathe("BasePin", [(F_SHIELD - 0.25, 0.0), (F_SHIELD - 0.25, D["base_pin"] / 2), (F_FRONT + 0.02, D["base_pin"] / 2),
                            (F_FRONT + 0.02, 0.15), (F_FRONT + 0.05, 0.16), (F_FRONT + 0.20, 0.16), (F_FRONT + 0.24, 0.12),
                            (F_FRONT + 0.25, 0.0)], (0.0, 0.0, CA), "f", MAT["fire"], 32)
    # The pin's head knurled: grooves round it.
    for k in range(4):
        g = lathe("kn", [(F_FRONT + 0.075 + k * 0.035, 0.0), (F_FRONT + 0.075 + k * 0.035, 0.17),
                         (F_FRONT + 0.088 + k * 0.035, 0.17), (F_FRONT + 0.088 + k * 0.035, 0.0)], (0.0, 0.0, CA), "f", None, 32)
        cut(g, cyl("kc", 0.152, F_FRONT, F_FRONT + 0.4, 0.0, CA, 32))
        cut(pin, g)
    parts["BasePin"] = pin
    parts["Hammer"] = make_hammer()
    parts["Trigger"] = make_trigger()
    parts["Bolt"] = make_bolt()
    bs, guard, grip = make_grip_frame()
    parts["Backstrap"] = bs
    parts["TriggerGuard"] = guard
    parts["Grip"] = grip
    hf, hu = HAMMER_PIVOT
    tf, tu = TRIGGER_PIVOT
    bf, bu = BOLT_PIVOT
    gl, gu = gate_chamber()
    screws = [
        ("Screw_Hammer", (-0.452, hf, hu), (-1, 0, 0), 0.105, 25),
        ("Screw_HammerR", (0.448, hf, hu), (1, 0, 0), 0.10, 0, False),
        ("Screw_Bolt", (-0.452, bf, bu), (-1, 0, 0), 0.085, 70),
        ("Screw_BoltR", (0.448, bf, bu), (1, 0, 0), 0.08, 0, False),
        ("Screw_Trigger", (-0.452, tf, tu), (-1, 0, 0), 0.085, 115),
        ("Screw_TriggerR", (0.448, tf, tu), (1, 0, 0), 0.08, 0, False),
        ("Screw_BasePin", (-0.20, F_FRONT + 0.0, -0.80), (0, 1, 0), 0.075, 40),
        ("Screw_GateCatch", (0.0, 1.30, frame_bottom_at(1.30) - 0.002), (0, 0, -1), 0.075, 10),
        ("Screw_GuardFront", (0.0, 0.70, frame_bottom_at(0.70) - 0.092), (0, 0, -1), 0.075, 80),
        ("Screw_GuardRear", (0.0, -0.70, frame_bottom_at(-0.70) - 0.092), (0, 0, -1), 0.075, 160),
        ("Screw_Ejector", (gl + D["eject_od"] / 2 + 0.002, ej[2] - 0.32, gu), (1, 0, 0), 0.07, 60),
    ]
    # Backstrap's two at the tang, and one through the butt.
    bt = Vector(GRIP_BACK[1])
    nrm = (Vector(GRIP_BACK[0]) - Vector(GRIP_BACK[2])).normalized()
    nb = Vector((nrm.y, -nrm.x))
    if nb.x > 0:
        nb = -nb
    for side, sx in (("L", -0.13), ("R", 0.13)):
        p = bt + nb * 0.07
        screws.append(("Screw_Backstrap" + side, (sx, p.x, p.y), (0, nb.x, nb.y), 0.07, 30 + 50 * (sx > 0)))
    bv = Vector(GRIP_FRONT[-1]) - Vector(GRIP_BACK[-1])
    bn = Vector((bv.y, -bv.x)).normalized()
    if bn.y > 0:
        bn = -bn
    bp = Vector(GRIP_FRONT[-1]) - bv * 0.18 + bn * 0.05
    screws.append(("Screw_Butt", (0.0, bp.x, bp.y), (0, bn.x, bn.y), 0.07, 100))
    for s in screws:
        name, c, ax, r, slot = s[:5]
        dome = s[5] if len(s) > 5 else True
        parts[name] = screw(name, c, ax, r, 0.03 if dome else 0.008, slot, dome)

    # Pivots.
    set_pivot(parts["Cylinder"], (0.0, 0.0, CA))
    for case, bull in rounds:
        set_pivot(case, (0.0, 0.0, CA))
        set_pivot(bull, (0.0, 0.0, CA))
    set_pivot(parts["Hammer"], (0.0, hf, hu))
    set_pivot(parts["Trigger"], (0.0, tf, tu))
    set_pivot(parts["Bolt"], (0.0, bf, bu))
    set_pivot(parts["Gate"], hinge)
    set_pivot(parts["Ejector"], (gl, ej[0], gu))
    for ob in list(parts.values()) + [x for r in rounds for x in r]:
        finish(ob)
        box_uv(ob, 0.04)
    # The root and the hierarchy: the rounds ride in the cylinder.
    root = bpy.data.objects.new("ColtSAA", None)
    bpy.context.collection.objects.link(root)
    for name, ob in parts.items():
        ob.parent = root
        ob.location -= ORIGIN
    for k, (case, bull) in enumerate(rounds):
        for ob in (case, bull):
            ob.location = Vector((0, 0, 0))
            ob.parent = parts["Cylinder"]
    markers = {
        "Muzzle": (0.0, MUZZLE, 0.0), "SightRear": (0.0, -0.10, LOS), "SightFront": (0.0, MUZZLE - 0.62, FRONT_BLADE_TOP),
        "GripWeb": (0.0, -1.05, -0.45), "TriggerFace": (0.0, -0.30, -2.40), "GatePoint": (gl, F_SHIELD - 0.4, gu),
        "BoreBreech": (0.0, F_BARREL, 0.0),
    }
    for name, c in markers.items():
        e = bpy.data.objects.new(name, None)
        bpy.context.collection.objects.link(e)
        e.empty_display_size = 0.005
        e.parent = root
        e.location = P(*c) - ORIGIN
    spur = bpy.data.objects.new("HammerSpur", None)
    bpy.context.collection.objects.link(spur)
    spur.parent = parts["Hammer"]
    spur.location = P(0.0, -1.50, 0.54) - P(0.0, hf, hu)
    head = bpy.data.objects.new("EjectorHead", None)
    bpy.context.collection.objects.link(head)
    head.parent = parts["Ejector"]
    head.location = P(gl, ej[1], gu) - P(gl, ej[0], gu)
    return parts, rounds, markers, hinge, ej


def g(v):
    """Blender (x, y, z) metres -> Godot (x, z, -y)."""
    return [round(v[0], 6), round(v[2], 6), round(-v[1], 6)]


def rig_json(parts, markers, hinge, ej, path):
    gl, gu = gate_chamber()
    hf, hu = HAMMER_PIVOT
    tf, tu = TRIGGER_PIVOT
    bf, bu = BOLT_PIVOT
    rig = {
        "about": "Colt Single Action Army (1873 pattern), #693 step 1: experiments/gun_lab/saa/saa_blender.py. Godot space, "
                 "metres, the gun's local frame (barrel along -Z, up +Y, right +X). Angles in degrees about the axis given "
                 "(right-hand rule). Travel numbers marked 'est' are estimates from the mechanism's geometry, not measured.",
        "barrel_in": BARREL,
        "parts": [o.name for o in parts.values()],
        "rounds": {"case": "Case<k>", "bullet": "Bullet<k>", "parent": "Cylinder",
                   "show": "loaded: case+bullet; spent: case only; empty: neither"},
        "moving": {
            "Cylinder": {"pivot": g(P(0, 0, CA) - ORIGIN), "axis": [0, 0, -1], "index_deg": 60.0,
                         "note": "chamber k sits at 60k deg clockwise from the top seen from behind; +60 about the axis "
                                 "turns the next chamber up under the hammer (Colt's way, clockwise from behind). "
                                 "Turned by the hand while cocking from half to full cock.",
                         "gate_chamber_deg": GATE_DEG},
            "Hammer": {"pivot": g(P(0, hf, hu) - ORIGIN), "axis": [1, 0, 0],
                       "notches_deg": {"rest": 0.0, "safety": 4.0, "half": 10.0, "full": 24.0},
                       "note": "est: the four clicks (C-O-L-T); the pivot is low (the Met gun's hammer screw), so 24 deg takes the face ~0.6 in back"},
            "Trigger": {"pivot": g(P(0, tf, tu) - ORIGIN), "axis": [1, 0, 0], "pull_deg": -6.0, "cocked_deg": -3.0,
                        "note": "est: the trigger comes back with the hammer as it cocks, a short pull lets it go"},
            "Bolt": {"pivot": g(P(0, bf, bu) - ORIGIN), "axis": [1, 0, 0], "down_deg": -5.0,
                     "note": "est: down while the cylinder turns, up into the next notch at full cock"},
            "Gate": {"pivot": g(P(*hinge) - ORIGIN), "axis": [0, 0, -1], "open_deg": -95.0,
                     "note": "est: swings out and down to the right about an axis along the bore"},
            "Ejector": {"pivot": g(P(gl, ej[0], gu) - ORIGIN), "axis": [0, 0, 1], "stroke_m": round(D["eject_stroke"] * IN, 5),
                        "note": "slides back (toward +Z) by the stroke; its rear tip then stands past the cylinder's back"},
        },
        "markers": {k: g(P(*v) - ORIGIN) for k, v in markers.items()},
        "dims_in": {k: v for k, v in D.items()},
    }
    with open(path, "w") as f:
        json.dump(rig, f, indent=1)


def preview(outdir):
    """Cycles stills for checking the shapes (not the look)."""
    os.makedirs(outdir, exist_ok=True)
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = int(arg("samples", "24"))
    sc.cycles.device = "CPU"
    sc.render.resolution_x = int(arg("px", "1400"))
    sc.render.resolution_y = int(int(arg("px", "1400")) * 0.55)
    world = bpy.data.worlds.new("w")
    sc.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.55, 0.55, 0.58, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(40), math.radians(-20), math.radians(30))
    sc.collection.objects.link(sun)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam)
    sc.camera = cam
    sc.render.film_transparent = arg("alpha", "") == "1"
    cf, cu = (MUZZLE - 3.8) / 2, -1.9
    center = P(0, cf, cu) - ORIGIN
    views = {"right": (90, 0, 90), "left": (90, 0, -90), "front34": (75, 0, 140), "rear34": (70, 0, -30), "top": (0, 0, 90),
             "under34": (115, 0, 60)}
    only = arg("views", "")
    for name, (rx, ry, rz) in views.items():
        if only and name not in only.split(","):
            continue
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = (MUZZLE + 4.2) * IN * 1.02
        rot = Matrix.Rotation(math.radians(rz), 3, "Z") @ Matrix.Rotation(math.radians(rx), 3, "X")
        cam.rotation_euler = rot.to_euler()
        cam.location = center + rot @ Vector((0, 0, 1.0))
        sc.render.filepath = os.path.join(outdir, name + ".png")
        bpy.ops.render.render(write_still=True)
        if name in ("right", "left"):
            # Where the design's inches land in the picture (overlay.py lays it over a photo).
            ppi = sc.render.resolution_x / ((MUZZLE + 4.2) * 1.02)
            with open(os.path.join(outdir, name + ".json"), "w") as f:
                json.dump({"px_per_in": ppi, "centre_f": cf, "centre_u": cu, "muzzle_f": MUZZLE, "barrel_in": BARREL,
                           "size": [sc.render.resolution_x, sc.render.resolution_y],
                           "muzzle_right": name == "right"}, f, indent=1)


def main():
    parts, rounds, markers, hinge, ej = build()
    keep = set()
    def walk(o):
        keep.add(o.name)
        for c in o.children:
            walk(c)
    walk(bpy.data.objects["ColtSAA"])
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    tag = ("%g" % BARREL).replace(".", "")
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "saa_%s.glb" % tag)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True, export_yup=True,
                              export_extras=False, export_cameras=False, export_lights=False)
    rig_json(parts, markers, hinge, ej, os.path.join(OUT, "saa_%s_rig.json" % tag))
    tris = sum(len(o.data.loop_triangles) if o.data.calc_loop_triangles() is None else 0 for o in
               list(parts.values()) + [x for r in rounds for x in r])
    for w in WARN:
        print("WARN boolean", w)
    print("SAA %s in: %d parts, %d triangles -> %s" % (BARREL, len(parts) + 12, tris, glb))
    if PREVIEW:
        preview(PREVIEW)


main()
