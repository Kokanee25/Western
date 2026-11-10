"""The Winchester Model 1873 built in Blender by script from its real dimensions (#734 step 1, the
method of the Colt's #693: experiments/gun_lab/saa/). Every part the game drives is its own object
with its origin on its pivot: the receiver, barrel, magazine tube, lever, hammer, trigger, carrier,
bolt, dust cover, loading gate, the sights (buckhorn rear, blade front), forend and its cap,
buttstock and buttplate, the magazine band, the screws, and a round in the chamber, on the carrier and
in the tube. No maker's name, logo or stamping (the gun lab's rule).

    ~/bpyenv/bin/python experiments/gun_lab/win73/win73_blender.py [--barrel=24|20] [--out=DIR] \
        [--preview=DIR --views=right,left,front34,rear34,top,under34 --px=2000 --alpha=1]

Out: DIR/win73_<barrel>.glb (default experiments/gun_lab/win73/) and DIR/win73_<barrel>_rig.json
(pivots, axes, travel, markers in the game's space, metres). --preview renders Cycles stills of the
shapes for overlay.py (not the look: the look is judged in Godot under the real look, win73_views.gd).

The dimensions (inches, D below) and where each comes from are in this folder's README.md.
Design space: inches; f forward along the bore (0 = the barrel's breech face, where the bolt closes),
u up (0 = the bore's axis), l to the gun's right. The barrel's length is measured as collectors
measure an antique Winchester's, from the receiver's front face (F_RECV) to the muzzle. Blender:
(x, y, z) = (l, f, u) * 0.0254 - ORIGIN; the glTF exporter turns Blender's +Y forward into Godot's
-Z, so in the game the barrel points along -Z, up is +Y, right +X (as the Colt's).

The helpers (prism, lathe, sweep, boolean with its retry, bevel, box UVs) are the Colt's
(saa_blender.py), copied here so the SAA's file stays untouched.
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


BARREL = float(arg("barrel", "24"))
OUT = arg("out", HERE)
PREVIEW = arg("preview", "")
IN = 0.0254
CARBINE = BARREL < 22.0

# --- The dimensions (inches). README.md "The dimensions" gives each one's source. ---------------
D = {
    # .44-40 WCF (.44 Winchester Centre Fire), the cartridge's published dimensions
    "bore": 0.417, "groove": 0.427,
    "rim": 0.525, "rim_t": 0.065, "base": 0.471, "neck": 0.443, "case_len": 1.305, "oal": 1.592,
    "bullet": 0.427,
    "f_recv": 2.25,           # the receiver's front face ahead of the breech (the photo: the side plate's front edge to the face)
    "flats_breech": 1.00,     # the octagon barrel across its flats (the photo, measured)
    "flats_muzzle": 0.88,
    "round_breech": 0.80,     # the carbine's round barrel (est.)
    "round_muzzle": 0.70,
    "tube_od": 0.60, "tube_u": -0.75,   # the magazine tube under the barrel (the photo)
    "width": 1.12,            # the receiver across (est.)
    "bolt_stroke": 1.85,      # the bolt's travel: a round's length and clearance (est.)
    "carrier_lift": 0.75,     # the carrier from the tube's line to the bore's (= -tube_u)
    "cover_stroke": 1.45,     # the dust cover back along its rail (est.)
}
F_RECV = D["f_recv"]
MUZZLE = F_RECV + BARREL
TUBE_U = D["tube_u"]
RT = D["tube_od"] / 2.0
HW = D["width"] / 2.0
STOCK_HEEL = -17.05
# Sight line: the buckhorn's notch and the front blade's top (the photo's sights' places).
SIGHT_REAR_F = 4.95 if not CARBINE else 4.6
LOS_REAR = 0.72
SIGHT_FRONT_F = MUZZLE - 1.15
FRONT_TOP = 0.62
# The pivots, off the photo (the screws on the right side plate).
HAMMER_PIVOT = (-4.37, -1.90)
LEVER_PIVOT = (-2.00, -1.89)
TRIGGER_PIVOT = (-3.62, -1.93)
GATE_F0, GATE_F1 = -1.36, -0.05      # the loading gate's rear and front on the side plate
GATE_U, GATE_H = -0.86, 0.30          # its centre height and half height
ORIGIN = Vector((0.0, -4.4 * IN, -2.1 * IN))  # the frame's underside at the trigger, "where the hand meets the action"
SEG = 64


def P(l, f, u):
    return Vector((l * IN, f * IN, u * IN))


# --- Mesh helpers (the Colt's, saa_blender.py) -----------------------------------------------------
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


def prism_f(name, outline_lu, f0, f1, mat=None, smooth=True, corners=()):
    """A section (l, u) extruded along the bore from f0 to f1 (sights, the forend, bands)."""
    pts = chaikin(outline_lu, corners) if smooth else outline_lu
    bm = bmesh.new()
    a = [bm.verts.new(P(l, f0, u)) for l, u in pts]
    b = [bm.verts.new(P(l, f1, u)) for l, u in pts]
    n = len(pts)
    bm.faces.new(a)
    bm.faces.new(list(reversed(b)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def loft_f(name, sections, mat=None):
    """Sections [(f, [(l, u)...])], each with the same count of points, joined along the bore."""
    bm = bmesh.new()
    rings = [[bm.verts.new(P(l, f, u)) for l, u in sec] for f, sec in sections]
    n = len(rings[0])
    for a_, b_ in zip(rings[:-1], rings[1:]):
        for k in range(n):
            bm.faces.new((a_[k], a_[(k + 1) % n], b_[(k + 1) % n], b_[k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
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


def sweep(name, path, rad_lat, rad_in, mat=None, seg=20, closed_ends=True, square=2.0, l=0.0):
    """A tube along a path in the (f, u) plane at l: rad_lat across the gun, rad_in in the plane; its
    section a superellipse (square 2: an oval; 4 and up: a flat strap with rounded edges). rad_lat
    and rad_in may be lists (one a path point) for a tapering sweep."""
    pts = [Vector(p) for p in path]
    n = len(pts)
    rl = rad_lat if isinstance(rad_lat, (list, tuple)) else [rad_lat] * n
    ri = rad_in if isinstance(rad_in, (list, tuple)) else [rad_in] * n
    bm = bmesh.new()
    rings = []
    for i, p in enumerate(pts):
        a = pts[max(i - 1, 0)]
        b = pts[min(i + 1, n - 1)]
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))
        ring = []
        for k in range(seg):
            th = 2 * math.pi * k / seg
            c, s_ = math.cos(th), math.sin(th)
            c = math.copysign(abs(c) ** (2.0 / square), c)
            s_ = math.copysign(abs(s_) ** (2.0 / square), s_)
            q = p + nrm * (ri[i] * c)
            ring.append(bm.verts.new(P(l + rl[i] * s_, q.x, q.y)))
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


def boolean(ob, other, op="DIFFERENCE", keep=False, transfer=False):
    """An exact boolean, baked. If it loses the mesh (the solver gives up on a bad input, usually
    faces exactly touching) it is tried once more with the other part nudged 10 microns,
    self-intersection and hole-tolerant on; failing that the original is kept and the failure
    listed (printed at the end). The Colt's."""
    before = ob.data.copy()
    n0 = len(before.vertices)
    lost = 0
    for attempt in range(2):
        m = ob.modifiers.new("b", "BOOLEAN")
        m.operation = op
        m.solver = "EXACT"
        m.object = other
        if transfer:
            m.material_mode = "TRANSFER"
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
    # Normals weighted by face area (the flat faces keep their own, the bevels take the bend): without
    # it a big flat face shares its corner normals with the bevel beside it and its long triangles
    # shade in dark diagonal streaks in the game (the first views' receiver).
    m = ob.modifiers.new("wn", "WEIGHTED_NORMAL")
    m.mode = "FACE_AREA"
    m.weight = 50
    m.keep_sharp = True
    realise(ob)
    return ob


def box_uv(ob, tile=0.05):
    """UVs by box projection, a tile every `tile` metres (the Colt's): the surfaces pass bakes from
    these. Polish lines and grain run along the gun."""
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
                loop[uv].uv = (c.y / tile, c.x / tile)
    bm.to_mesh(me)
    bm.free()
    me.uv_layers[0].name = "UVMap"


def resample(pts, n):
    """n points along a polyline, Catmull-Rom between its points (the Colt's)."""
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
        p0 = v[max(j - 1, 0)]
        p1, p2 = v[j], v[j + 1]
        p3 = v[min(j + 2, len(v) - 1)]
        s2, s3 = s * s, s * s * s
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * s + (2 * p0 - 5 * p1 + 4 * p2 - p3) * s2 + (-p0 + 3 * p1 - 3 * p2 + p3) * s3))
    return out


def curve_at(pts, f):
    """A side curve [(f, u)] (f falling) read at f."""
    if f >= pts[0][0]:
        return pts[0][1]
    for (fa, ua), (fb, ub) in zip(pts[:-1], pts[1:]):
        if fb <= f <= fa:
            return ua + (ub - ua) * (fa - f) / (fa - fb)
    return pts[-1][1]


def superellipse(cl, cu, a, b, e=2.6, n=48):
    """(l, u) points round a superellipse: a across, b up."""
    out = []
    for k in range(n):
        ph = 2 * math.pi * k / n
        c, s = math.cos(ph), math.sin(ph)
        out.append((cl + math.copysign(abs(c) ** (2 / e), c) * a, cu + math.copysign(abs(s) ** (2 / e), s) * b))
    return out


# --- Materials (placeholders until the surfaces, as the Colt's after its metal step) -------------
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
    # Metal as metal (Sean's notes from the Colt): metallic 1, the base colour the metal's own
    # reflectance (bluing a dark blue-grey that still mirrors); walnut a dielectric.
    MAT["blued"] = material("w73_blued", (0.17, 0.19, 0.25), 1.0, 0.20)    # receiver, barrel, tube, cover, caps
    MAT["case"] = material("w73_case", (0.38, 0.37, 0.39), 1.0, 0.24)      # hammer, lever, trigger (case colours)
    MAT["fire"] = material("w73_fire_blue", (0.10, 0.17, 0.38), 1.0, 0.16)  # screws
    MAT["bright"] = material("w73_bright", (0.56, 0.56, 0.57), 1.0, 0.28)   # the bolt, the carrier (in the white)
    MAT["walnut"] = material("w73_walnut", (0.12, 0.06, 0.03), 0.0, 0.42)
    MAT["bore"] = material("w73_bore", (0.04, 0.04, 0.045), 1.0, 0.6)
    MAT["brass"] = material("w73_brass", (0.85, 0.68, 0.38), 1.0, 0.30)
    MAT["lead"] = material("w73_lead", (0.45, 0.45, 0.47), 1.0, 0.50)
    MAT["primer"] = material("w73_primer", (0.85, 0.55, 0.42), 1.0, 0.30)


# --- The receiver -----------------------------------------------------------------------------------
# Its side outline off the photo (README "The reference"): the front face at F_RECV, the flat top to
# the rear, the rear upper edge sloping down past the hammer to the wood, the rear face where the
# stock butts, the frame's lower rear round the lever's front loop, the lower edge stepping up to the
# front section under the barrel.
RECV_SIDE = [(F_RECV, 0.50), (-3.05, 0.55), (-3.50, 0.43), (-4.00, 0.23), (-4.50, -0.07), (-4.85, -0.42), (-5.25, -0.70),
             (-5.25, -1.00), (-5.15, -1.50), (-4.95, -1.95), (-4.60, -2.28), (-4.30, -2.40), (-4.08, -2.34),
             (-4.00, -2.10), (-1.95, -2.08), (-1.60, -1.98), (-1.30, -1.80), (-0.90, -1.60), (1.95, -1.56),
             (F_RECV, -1.30)]
# The upper tang along the wrist's top, the lower tang along its belly (the lever's rear loop closes on it).
UPPER_TANG = [(-4.90, -0.55), (-5.50, -0.76), (-6.00, -0.92), (-6.50, -1.04), (-7.00, -1.25), (-7.42, -1.45),
              (-7.36, -1.57), (-7.00, -1.38), (-6.50, -1.17), (-6.00, -1.05), (-5.50, -0.89), (-4.90, -0.84)]
LOWER_TANG = [(-4.05, -2.28), (-4.35, -2.46), (-5.00, -2.57), (-6.00, -3.02), (-6.60, -3.26), (-7.00, -3.56), (-7.50, -3.72),
              (-7.56, -3.86), (-7.00, -3.73), (-6.60, -3.41), (-6.00, -3.16), (-5.00, -2.71), (-4.50, -2.63), (-4.25, -2.47),
              (-4.00, -2.40)]
# The right side plate's outline (the photo's seam): front edge at the breech's plane, the S-curve behind.
SIDE_PLATE = [(0.0, 0.02), (0.0, -1.42), (-1.20, -1.45), (-3.30, -1.55), (-3.55, -1.25), (-3.57, -0.75),
              (-3.42, -0.30), (-3.12, 0.02)]
PORT = (-2.30, -0.10)          # the ejection port on top, under the dust cover


def offset_poly(pts, d):
    """A closed outline moved d outward (each corner along its bisector; the outline counter-clockwise
    or clockwise, the sign found from its area)."""
    n = len(pts)
    area = sum(pts[i][0] * pts[(i + 1) % n][1] - pts[(i + 1) % n][0] * pts[i][1] for i in range(n))
    sgn = -1.0 if area < 0 else 1.0
    out = []
    for i in range(n):
        a, b, c = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        t1, t2 = (b - a).normalized(), (c - b).normalized()
        n1, n2 = Vector((t1.y, -t1.x)) * sgn, Vector((t2.y, -t2.x)) * sgn
        m = (n1 + n2).normalized()
        k = max(0.3, m.dot(n1))
        out.append((b + m * (d / k)).to_tuple())
    return out


def gate_outline(grow=0.0):
    """The loading gate: square at its front (the side plate's front edge), round at the back."""
    f0, f1, u, h = GATE_F0 - grow, GATE_F1 + grow, GATE_U, GATE_H + grow
    pts = [(f1, u + h), (f1, u - h)]
    r = h
    for k in range(1, 12):
        a = -math.pi / 2 - math.pi * k / 12
        pts.append((f0 + r + r * math.cos(a), u + r * math.sin(a)))
    return pts


def make_receiver():
    body = prism("Receiver", RECV_SIDE, HW, MAT["blued"], corners=(0, 5, 6, 18))
    # The top's edges rounded across (a flat top with round shoulders, the 1873's).
    top_round = prism_f("tr", [(-HW - 0.2, -3.0), (HW + 0.2, -3.0), (HW + 0.2, 0.30), (HW - 0.10, 0.52), (HW - 0.28, 0.58),
                               (-HW + 0.28, 0.58), (-HW + 0.10, 0.52), (-HW - 0.2, 0.30)], -6.0, F_RECV + 0.1, smooth=True,
                        corners=(0, 1))
    boolean(body, top_round, "INTERSECT")
    # The tangs follow the wrist's round (each cut to the stock's own outside grown a hair), not flat
    # plates whose edges would stand out of the wood.
    up = prism("utang", UPPER_TANG, 0.30, corners=(0,))
    boolean(up, stock_loft("uw", 0.012, f0=-4.6, f1=-7.8), "INTERSECT")
    lo = prism("ltang", LOWER_TANG, 0.31, corners=(0,))
    boolean(lo, stock_loft("lw", 0.012, f0=-3.9, f1=-7.8), "INTERSECT")
    union(body, up, lo)
    # The dust cover's rail on top (it slides back along it).
    rail = prism("rail", [(-3.0, 0.50), (0.0, 0.50), (0.0, 0.53), (-3.0, 0.53)], 0.13, smooth=False)
    union(body, rail)
    # The barrel's and the tube's seats in the front; the action's cavity (bolt above, carrier below);
    # the port on top, the carrier's window and the lever's slot underneath; the hammer's slot.
    cut(body, cyl("bseat", 0.505, -0.02, F_RECV + 0.1, 0.0, 0.0, 64))
    cut(body, cyl("tseat", RT + 0.005, -0.02, F_RECV + 0.1, 0.0, TUBE_U, 48))
    cut(body, box("cav", -0.31, 0.31, -3.48, 0.0, -1.42, 0.44))
    cut(body, box("port", -0.30, 0.30, PORT[0], PORT[1], 0.20, 0.9))
    cut(body, box("cwin", -0.30, 0.30, -1.90, -0.10, -2.3, -1.3))
    cut(body, box("lslot", -0.13, 0.13, -4.4, -1.7, -2.6, -1.3))
    cut(body, box("hslot", -0.17, 0.17, -4.85, -3.30, -2.25, 1.2))
    cut(body, box("tslot", -0.09, 0.09, -4.05, -3.40, -2.6, -1.8))
    # The loading gate's window in the right side plate, and the seams round both side plates.
    cut(body, prism("gwin", gate_outline(0.012), 0.0, l0=0.20, l1=HW + 0.1, smooth=False))
    for side in (1.0, -1.0):
        # a groove 0.014" wide and deep round each side plate: its outline grown a hair, less itself
        l0, l1 = (HW - 0.014, HW + 0.1) if side > 0 else (-HW - 0.1, -HW + 0.014)
        ring = prism("seam", offset_poly(SIDE_PLATE, 0.014), 0.0, l0=l0, l1=l1, smooth=False)
        cut(ring, prism("seami", SIDE_PLATE, 0.0, l0=l0 - 0.1, l1=l1 + 0.1, smooth=False))
        cut(body, ring)
    bevel(body, 0.03, 3, 30)
    return body


# --- The barrel, the magazine tube, the forend ---------------------------------------------------------
def barrel_apothem(f):
    t = min(1.0, max(0.0, (f - F_RECV) / BARREL))
    if CARBINE:
        return (D["round_breech"] + (D["round_muzzle"] - D["round_breech"]) * t) / 2
    return (D["flats_breech"] + (D["flats_muzzle"] - D["flats_breech"]) * t) / 2


def octagon_section(a, n_round=0):
    """(l, u) of an octagon with flats up, down and to the sides, apothem a."""
    R = a / math.cos(math.pi / 8)
    return [(R * math.sin(math.pi / 8 + k * math.pi / 4), R * math.cos(math.pi / 8 + k * math.pi / 4)) for k in range(8)]


def barrel_solid(name, grow=0.0, f0=None, f1=None, mat=None):
    """The barrel's outside from its shank to the muzzle: octagonal (the rifle) or round (the carbine)."""
    f0 = F_RECV - 0.01 if f0 is None else f0
    f1 = MUZZLE if f1 is None else f1
    bm = bmesh.new()
    rings = []
    steps = 12
    for i in range(steps + 1):
        f = f0 + (f1 - f0) * i / steps
        a = barrel_apothem(f) + grow
        sec = octagon_section(a) if not CARBINE else [(a * math.sin(2 * math.pi * k / 64), a * math.cos(2 * math.pi * k / 64)) for k in range(64)]
        rings.append([bm.verts.new(P(l, f, u)) for l, u in sec])
    n = len(rings[0])
    for a_, b_ in zip(rings[:-1], rings[1:]):
        for k in range(n):
            bm.faces.new((a_[k], b_[k], b_[(k + 1) % n], a_[(k + 1) % n]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def make_barrel():
    barrel = barrel_solid("Barrel", 0.0, mat=MAT["blued"])
    if not CARBINE:
        bevel(barrel, 0.012, 1, 30)   # the octagon's corners softened (polished, then blued)
    shank = cyl("shank", 0.495, 0.0, F_RECV + 0.02, 0.0, 0.0, 64)
    union(barrel, shank)
    # The muzzle's crown: a shallow round chamfer into the bore.
    crown = lathe("crown", [(MUZZLE - 0.06, 0.0), (MUZZLE - 0.06, D["bore"] / 2), (MUZZLE + 0.01, D["bore"] / 2 + 0.09),
                            (MUZZLE + 0.01, 0.0)], (0, 0, 0), "f", None, 64)
    cut(barrel, crown)
    # The bore, six grooves, the chamber and the rim's recess at the breech.
    cut(barrel, cyl("bore", D["bore"] / 2, -0.1, MUZZLE + 0.1, 0.0, 0.0, 48))
    for k in range(6):
        a = 2 * math.pi * k / 6
        g = box("rifl", -0.035, 0.035, MUZZLE - 1.5, MUZZLE + 0.1, D["bore"] / 2 - 0.01, D["groove"] / 2)
        g.data.transform(Matrix.Rotation(a, 4, "Y"))
        cut(barrel, g)
    ch = lathe("ch", [(-0.1, 0.0), (-0.1, D["base"] / 2 + 0.002), (D["case_len"] - 0.12, D["base"] / 2 - 0.004),
                      (D["case_len"] - 0.08, D["neck"] / 2 + 0.003), (D["case_len"] + 0.02, D["neck"] / 2 + 0.003),
                      (D["case_len"] + 0.08, D["bore"] / 2 + 0.003), (D["case_len"] + 0.12, 0.0)], (0, 0, 0), "f", None, 48)
    cut(barrel, ch)
    cut(barrel, cyl("rimrec", D["rim"] / 2 + 0.01, -0.1, 0.02, 0.0, 0.0, 48))
    barrel.data.materials.append(MAT["bore"])
    for poly in barrel.data.polygons:
        c = Vector(poly.center) / IN
        if math.hypot(c.x, c.z) < D["groove"] / 2 + 0.003 and 0.03 < c.y < MUZZLE - 0.08:
            poly.material_index = 1
    return barrel


def make_tube():
    """The magazine tube under the barrel, its plug at the front (a slotted cap), its rear seated in
    the receiver, open there for the rounds."""
    end = MUZZLE - 0.10 if not CARBINE else MUZZLE - 0.40
    tube = lathe("MagTube", [(0.02, 0.0), (0.02, RT), (end - 0.08, RT), (end - 0.08, RT - 0.004), (end - 0.075, RT - 0.012),
                             (end, RT - 0.012), (end + 0.025, RT - 0.04), (end + 0.04, RT - 0.10), (end + 0.045, 0.0)],
                 (0.0, 0.0, TUBE_U), "f", MAT["blued"], 48)
    cut(tube, cyl("tid", RT - 0.028, -0.1, F_RECV + 0.3, 0.0, TUBE_U, 40))
    slot = box("pslot", -0.025, 0.025, end + 0.01, end + 0.1, TUBE_U - 0.2, TUBE_U + 0.2)
    cut(tube, slot)
    return tube, end


FOREND_END = 11.85
FOREND_TOP = -0.10
FOREND_BOT = -1.39   # at the receiver; -1.30 at the cap (the photo)


def forend_section(grow=0.0, bot=FOREND_BOT, hw=0.50):
    cu = (FOREND_TOP + bot) / 2
    return superellipse(0.0, cu, hw + grow, (FOREND_TOP - bot) / 2 + grow, 2.5, 56)


def make_forend():
    end = FOREND_END if not CARBINE else F_RECV + 7.6
    wood = loft_f("Forend", [(F_RECV + 0.01, forend_section()), (end, forend_section(0.0, -1.30, 0.48))], MAT["walnut"])
    cut(wood, barrel_solid("bcut", 0.004, F_RECV - 0.5, end + 1.0))
    cut(wood, cyl("tcut", RT + 0.004, F_RECV - 0.5, end + 1.0, 0.0, TUBE_U, 48))
    bevel(wood, 0.04, 2, 30)
    # The cap: a blued shell over the wood's end, its front edge rounded.
    # (the photo: the wood's bottom -1.30, the cap tapering to -1.12 at its front, round the tube)
    cap = loft_f("ForendCap", [(end, forend_section(0.012, -1.30, 0.48)), (end + 0.30, forend_section(0.0, -1.20, 0.45)),
                               (end + 0.85, forend_section(0.0, -1.10, 0.40))], MAT["blued"])
    cut(cap, barrel_solid("bcut2", 0.002, F_RECV, end + 2.0))
    cut(cap, cyl("tcut2", RT + 0.002, end - 1.0, end + 2.0, 0.0, TUBE_U, 48))
    bevel(cap, 0.05, 3, 30)
    return wood, cap, end


def make_band(f0):
    """The magazine band near the muzzle: a strap round the tube and the barrel's lower half."""
    cu = (TUBE_U - RT - 0.06 + 0.02) / 2
    band = prism_f("MagBand", superellipse(0.0, cu, barrel_apothem(f0) + 0.06, (0.02 - (TUBE_U - RT - 0.06)) / 2, 3.2, 48),
                   f0, f0 + 0.32, MAT["blued"])
    cut(band, barrel_solid("bcut3", 0.002, f0 - 1, f0 + 1))
    cut(band, cyl("tcut3", RT + 0.002, f0 - 1, f0 + 1, 0.0, TUBE_U, 48))
    bevel(band, 0.02, 2, 30)
    return band


# --- The sights -------------------------------------------------------------------------------------
def make_rear_sight():
    """A buckhorn: a plate across the barrel standing on a base dovetailed into the top flat, its
    horns curling up and in round a shallow V notch."""
    top = barrel_apothem(SIGHT_REAR_F)
    base = prism("RearSight", [(SIGHT_REAR_F - 0.42, top - 0.05), (SIGHT_REAR_F + 0.70, top - 0.05), (SIGHT_REAR_F + 0.70, top + 0.05),
                               (SIGHT_REAR_F + 0.60, top + 0.08), (SIGHT_REAR_F - 0.32, top + 0.10), (SIGHT_REAR_F - 0.42, top + 0.06)],
                 0.17, MAT["blued"], corners=(0, 1))
    L = LOS_REAR
    horn = [(-0.30, top + 0.02), (0.30, top + 0.02), (0.36, top + 0.12), (0.42, L + 0.10), (0.45, L + 0.22), (0.41, L + 0.27),
            (0.33, L + 0.21), (0.22, L + 0.11), (0.10, L + 0.06), (0.045, L + 0.05), (0.0, L), (-0.045, L + 0.05),
            (-0.10, L + 0.06), (-0.22, L + 0.11), (-0.33, L + 0.21), (-0.41, L + 0.27), (-0.45, L + 0.22), (-0.42, L + 0.10),
            (-0.36, top + 0.12)]
    plate = prism_f("horn", horn, SIGHT_REAR_F - 0.035, SIGHT_REAR_F + 0.035, None, corners=(0, 1, 10))
    bevel(plate, 0.008, 1, 40)
    # the elevator's stepped slide under the plate
    elev = prism("elev", [(SIGHT_REAR_F + 0.05, top + 0.04), (SIGHT_REAR_F + 0.55, top + 0.04), (SIGHT_REAR_F + 0.55, top + 0.12),
                          (SIGHT_REAR_F + 0.05, top + 0.20)], 0.10, smooth=False)
    union(base, plate, elev)
    return base


def make_front_sight():
    top = barrel_apothem(SIGHT_FRONT_F)
    base = prism("FrontSight", [(SIGHT_FRONT_F - 0.28, top - 0.05), (SIGHT_FRONT_F + 0.28, top - 0.05), (SIGHT_FRONT_F + 0.22, top + 0.07),
                                (SIGHT_FRONT_F - 0.22, top + 0.07)], 0.15, MAT["blued"], smooth=False)
    T = FRONT_TOP
    blade = prism("blade", [(SIGHT_FRONT_F - 0.24, top + 0.05), (SIGHT_FRONT_F + 0.24, top + 0.05), (SIGHT_FRONT_F + 0.18, T - 0.08),
                            (SIGHT_FRONT_F + 0.08, T - 0.01), (SIGHT_FRONT_F - 0.02, T), (SIGHT_FRONT_F - 0.12, T - 0.03),
                            (SIGHT_FRONT_F - 0.20, T - 0.10)], 0.035, corners=(0, 1))
    bevel(blade, 0.006, 1, 40)
    union(base, blade)
    bevel(base, 0.01, 1, 40)
    return base


# --- The action's moving parts -----------------------------------------------------------------------
def make_bolt():
    """The bolt closed against the breech, its firing pin standing out of its back, the extractor on
    top; slides back by the stroke when the lever opens."""
    b = prism("Bolt", [(-3.45, 0.42), (0.0, 0.42), (0.0, -0.28), (-3.45, -0.28)], 0.27, MAT["bright"], smooth=False)
    bevel(b, 0.04, 2, 30)
    fp = cyl("fpin", 0.07, -3.58, -3.40, 0.0, 0.0, 24)
    ext = prism("ext", [(-1.30, 0.40), (0.06, 0.40), (0.06, 0.47), (-0.10, 0.49), (-1.30, 0.47)], 0.06, smooth=False)
    union(b, fp, ext)
    cut(b, cyl("face", D["rim"] / 2 + 0.01, -0.05, 0.1, 0.0, 0.0, 40))   # the bolt face's recess for the rim
    return b


def make_carrier():
    """The carrier (lifter): a block under the bolt with a trough for the round; at rest in line with
    the tube, lifted straight up to the bore's line by the lever's last stroke."""
    c = box("Carrier", -0.29, 0.29, -1.82, -0.06, TUBE_U - 0.60, TUBE_U + 0.32, MAT["bright"])
    cut(c, cyl("trough", D["rim"] / 2 + 0.01, -2.0, 0.2, 0.0, TUBE_U, 40))
    cut(c, box("topopen", -0.20, 0.20, -2.0, 0.2, TUBE_U, TUBE_U + 0.5))
    bevel(c, 0.02, 2, 30)
    return c


def make_cover():
    """The dust cover: a curved plate riding the rail over the port, a ridged grip at its back."""
    sec = [(-0.40, 0.52), (0.40, 0.52), (0.40, 0.55), (0.30, 0.59), (0.0, 0.61), (-0.30, 0.59), (-0.40, 0.55)]
    cov = prism_f("DustCover", sec, -2.62, 0.0, MAT["blued"], corners=(0, 1))
    for k in range(4):
        r = prism_f("ridge", [(-0.30, 0.57), (0.30, 0.57), (0.30, 0.62), (0.0, 0.645), (-0.30, 0.62)],
                    -2.58 + k * 0.07, -2.55 + k * 0.07, None, smooth=False)
        union(cov, r)
    bevel(cov, 0.01, 1, 40)
    return cov


def make_gate():
    """The loading gate in the right side plate (its spring cover), hinged at its front."""
    g = prism("Gate", gate_outline(), 0.0, MAT["blued"], l0=HW - 0.07, l1=HW - 0.002, smooth=False)
    dimple = lathe("dim", [(0.0, 0.0), (0.0, 0.14), (0.03, 0.10), (0.04, 0.0)], (HW - 0.01, -0.70, GATE_U), "l", None, 32)
    cut(g, dimple)
    bevel(g, 0.012, 2, 30)
    return g


# The hammer off the photo: its face against the bolt's back, the body down to its screw low on the
# frame, the spur rising from the frame's top and curling back to its tip at (-4.0, 0.80).
HAMMER_BODY = [(-3.42, 0.20), (-3.42, -0.35), (-3.62, -0.90), (-3.96, -1.60), (-4.14, -2.05), (-4.45, -2.14), (-4.70, -1.95),
               (-4.74, -1.50), (-4.56, -0.90), (-4.32, -0.40), (-4.16, -0.05), (-4.00, 0.20), (-3.75, 0.30), (-3.55, 0.28)]
SPUR = [(-3.60, 0.22), (-3.66, 0.40), (-3.75, 0.55), (-3.86, 0.68), (-3.96, 0.77), (-4.00, 0.79)]


def make_hammer():
    body = prism("Hammer", HAMMER_BODY, 0.15, MAT["case"], corners=(0, 1))
    # The spur: a rounded strap rising and curling back, tapering to a blunt rounded tip, crowned on
    # its back where the thumb draws it (the Colt's lesson: no flat plate with a hard corner).
    path = [(q.x, q.y) for q in resample(SPUR, 16)]
    n = len(path)
    lat = [0.14 - 0.04 * i / (n - 1) for i in range(n)]
    inn = [0.13 - 0.06 * i / (n - 1) for i in range(n)]
    spur = sweep("spur", path, lat, inn, None, 28, square=2.6)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=12, radius=1.0)
    for v in bm.verts:
        v.co = P(v.co.x * lat[-1], SPUR[-1][0] + v.co.y * inn[-1], SPUR[-1][1] + v.co.z * inn[-1])
    eb = obj_from_bm("eb", bm)
    union(body, spur, eb)
    bevel(body, 0.03, 3, 30)
    return body


def make_trigger():
    # Off the photo: the blade curves down and back into the front loop's rear, its tip at (-4.02, -2.84).
    t = prism("Trigger", [(-3.45, -1.82), (-3.80, -1.82), (-3.98, -2.20), (-4.08, -2.55), (-4.08, -2.80), (-4.00, -2.86),
                          (-3.92, -2.72), (-3.76, -2.42), (-3.58, -2.15), (-3.45, -2.02)], 0.07, MAT["case"], corners=(0, 1))
    bevel(t, 0.02, 3, 30)
    return t


# The lever off the photo: the front loop round the trigger (closed above by the frame), the long rear
# loop for the fingers lying along the lower tang, the tongue up into the frame round its pin.
LEVER_OUT = [(-1.58, -1.70), (-1.45, -1.98), (-1.60, -2.45), (-1.85, -2.95), (-2.15, -3.25), (-2.50, -3.50), (-3.00, -3.68),
             (-3.50, -3.68), (-4.00, -3.74), (-4.50, -3.97), (-5.00, -4.12), (-5.50, -4.37), (-6.00, -4.52), (-6.50, -4.46),
             (-6.80, -4.16), (-6.82, -3.80), (-6.66, -3.46), (-6.00, -3.17), (-5.50, -2.97), (-5.00, -2.72), (-4.50, -2.64),
             (-4.25, -2.50), (-4.15, -2.10), (-3.60, -1.98), (-2.40, -2.02), (-2.20, -1.62)]
LEVER_FRONT_HOLE = [(-2.30, -2.00), (-2.35, -2.55), (-2.55, -2.88), (-3.00, -3.16), (-3.50, -3.19), (-3.85, -3.10),
                    (-4.07, -2.92), (-4.05, -2.65), (-3.90, -2.30), (-3.60, -2.00)]
LEVER_REAR_HOLE = [(-4.33, -2.84), (-4.50, -2.80), (-5.00, -2.88), (-5.50, -3.13), (-6.00, -3.33), (-6.50, -3.55),
                   (-6.66, -3.80), (-6.50, -4.22), (-6.00, -4.27), (-5.50, -4.04), (-5.00, -3.84), (-4.50, -3.61),
                   (-4.30, -3.30)]


def make_lever():
    lev = prism("Lever", LEVER_OUT, 0.16, MAT["case"], corners=(0, 21))
    cut(lev, prism("fh", LEVER_FRONT_HOLE, 0.5))
    cut(lev, prism("rh", LEVER_REAR_HOLE, 0.5))
    # Above the frame's bottom only the tongue round the pin stays (it works the link inside).
    cut(lev, prism("inframe", [(-1.0, -2.07), (-2.30, -2.07), (-2.30, -1.0), (-1.0, -1.0)], 0.5, smooth=False))
    tongue = prism("tongue", [(-1.72, -1.66), (-2.30, -1.72), (-2.40, -2.12), (-1.74, -2.12)], 0.12)
    union(lev, tongue)
    bevel(lev, 0.05, 3, 30)
    return lev


# --- The stock ---------------------------------------------------------------------------------------
STOCK_TOP = [(-4.00, 0.20), (-4.50, -0.10), (-4.90, -0.55), (-5.50, -0.76), (-6.00, -0.92), (-6.50, -1.04), (-7.00, -1.25), (-7.50, -1.45),
             (-8.00, -1.62), (-9.0, -1.85), (-10.0, -2.00), (-11.0, -2.13), (-12.0, -2.32), (-13.0, -2.48), (-14.0, -2.62),
             (-15.0, -2.82), (-16.0, -2.98), (-17.3, -3.12)]
STOCK_BOT = [(-4.00, -2.10), (-4.25, -2.40), (-4.50, -2.60), (-5.00, -2.70), (-5.50, -2.95), (-6.00, -3.15), (-6.60, -3.40),
             (-7.00, -3.72), (-7.55, -3.86),
             (-8.00, -3.95), (-9.0, -4.28), (-10.0, -4.67), (-11.0, -5.08), (-12.0, -5.50), (-13.0, -5.90), (-14.0, -6.33),
             (-15.0, -6.72), (-16.0, -7.07), (-17.3, -7.38)]
# The crescent butt (the photo): heel and toe reaching back, the middle hollow.
CRESCENT = [(-17.06, -3.05), (-16.90, -3.79), (-16.60, -4.45), (-16.45, -5.20), (-16.60, -6.00), (-16.90, -6.88), (-17.03, -7.35)]


def stock_hw(f):
    t = min(1.0, max(0.0, (-7.5 - f) / 9.5))
    return 0.56 + 0.22 * (t ** 0.9)


def stock_loft(name, grow=0.0, mat=None, f0=-3.9, f1=-17.35, n=70, ring=48):
    bm = bmesh.new()
    rings = []
    for i in range(n):
        f = f0 + (f1 - f0) * i / (n - 1)
        t, b = curve_at(STOCK_TOP, f) + grow, curve_at(STOCK_BOT, f) - grow
        cu, hh = (t + b) / 2, (t - b) / 2
        sec = superellipse(0.0, cu, stock_hw(f) + grow, hh, 2.7, ring)
        rings.append([bm.verts.new(P(l, f, u)) for l, u in sec])
    for a_, b_ in zip(rings[:-1], rings[1:]):
        for k in range(ring):
            bm.faces.new((a_[k], b_[k], b_[(k + 1) % ring], a_[(k + 1) % ring]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return obj_from_bm(name, bm, mat)


def crescent_poly(offset):
    """The region behind the crescent moved `offset` forward (the plate's inside face at 0.10)."""
    c = [(f + offset, u) for f, u in CRESCENT]
    return [(-20.0, c[0][1] + 1.0)] + c + [(-20.0, c[-1][1] - 1.0)]


def make_stock():
    outer = stock_loft("outer", 0.0)
    # The buttplate: the loft's last 0.10" behind the crescent, with the heel's and toe's lips.
    plate = dup(outer, "Buttplate")
    band = prism("bpband", crescent_poly(0.10), 2.0, smooth=False)
    boolean(plate, band, "INTERSECT")
    plate.data.materials.append(MAT["blued"])
    cut(plate, prism("behind", crescent_poly(0.0), 2.0, smooth=False))
    bevel(plate, 0.02, 2, 35)
    wood = stock_loft("Buttstock", -0.004, MAT["walnut"])
    cut(wood, prism("bp2", crescent_poly(0.10), 2.0, smooth=False))
    # The receiver's place, its tangs inletted.
    cut(wood, prism("rcut", RECV_SIDE[1:-1] + [(2.0, -1.4), (2.0, 0.5)], HW + 0.3, corners=()))
    cut(wood, prism("ut", UPPER_TANG, 0.305))
    cut(wood, prism("lt", LOWER_TANG, 0.315))
    bevel(wood, 0.03, 2, 30)
    bpy.data.objects.remove(outer, do_unlink=True)
    return wood, plate


# --- The rounds ----------------------------------------------------------------------------------------
def make_round(tag, f_rim, u, mat_case=None):
    """A .44-40: the bottlenecked brass case (rim, primer) and the lead bullet, separate so the game can
    show loaded, spent (the case only) or empty."""
    r0 = f_rim
    rim_t = D["rim_t"]
    L = D["case_len"]
    case = lathe("Case" + tag, [(r0, 0.0), (r0, D["rim"] / 2 - 0.008), (r0 + 0.01, D["rim"] / 2), (r0 + rim_t, D["rim"] / 2),
                                (r0 + rim_t, D["base"] / 2 - 0.02), (r0 + rim_t + 0.04, D["base"] / 2),
                                (r0 + L - 0.30, D["base"] / 2 - 0.006), (r0 + L - 0.20, D["neck"] / 2), (r0 + L, D["neck"] / 2),
                                (r0 + L, 0.0)], (0.0, 0.0, u), "f", MAT["brass"], 40)
    primer = lathe("pr", [(r0 - 0.004, 0.0), (r0 - 0.004, 0.088), (r0 + 0.02, 0.088), (r0 + 0.02, 0.0)], (0.0, 0.0, u), "f", None, 24)
    cut(case, cyl("pk", 0.094, r0 - 0.01, r0 + 0.012, 0.0, u, 24))
    union(case, primer)
    case.data.materials.append(MAT["primer"])
    for poly in case.data.polygons:
        c = Vector(poly.center) / IN
        if math.hypot(c.x, c.z - u) < 0.089 and c.y < r0 + 0.005:
            poly.material_index = 1
    b0 = r0 + L - 0.40
    tip = r0 + D["oal"]
    bull = lathe("Bullet" + tag, [(b0, 0.0), (b0, D["bullet"] / 2 - 0.006), (r0 + L + 0.04, D["bullet"] / 2), (tip - 0.18, 0.19),
                                  (tip - 0.09, 0.14), (tip - 0.03, 0.08), (tip, 0.0)], (0.0, 0.0, u), "f", MAT["lead"], 32)
    return case, bull


def screw(name, center, axis, r=0.085, head=0.03, slot_deg=0.0, dome=True, mat=None):
    """A screw head: domed, slotted; `axis` the way the head faces (unit (l, f, u)). The Colt's."""
    prof = [(0.0, 0.0), (0.0, r), (head * 0.4, r - 0.005), (head * 0.8, r * 0.75), (head, 0.0)] if dome else \
        [(0.0, 0.0), (0.0, r), (head, r - 0.008), (head, 0.0)]
    ob = lathe(name, [(-0.04, 0.0), (-0.04, r)] + prof[1:], (0.0, 0.0, 0.0), "f", mat or MAT["fire"], 32)
    sl = box("slot", -r * 1.2, r * 1.2, head * 0.35, head + 0.05, -0.012, 0.012)
    sl.data.transform(Matrix.Rotation(math.radians(slot_deg), 4, "Y"))
    cut(ob, sl)
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


BAND_F = MUZZLE - 4.0


def build():
    clear()
    mats()
    parts = {}
    parts["Receiver"] = make_receiver()
    parts["Barrel"] = make_barrel()
    tube, tube_end = make_tube()
    parts["MagTube"] = tube
    forend, cap, fend = make_forend()
    parts["Forend"] = forend
    parts["ForendCap"] = cap
    if not CARBINE:
        parts["MagBand"] = make_band(BAND_F)
    parts["RearSight"] = make_rear_sight()
    parts["FrontSight"] = make_front_sight()
    parts["Bolt"] = make_bolt()
    parts["Carrier"] = make_carrier()
    parts["DustCover"] = make_cover()
    parts["Gate"] = make_gate()
    parts["Hammer"] = make_hammer()
    parts["Trigger"] = make_trigger()
    parts["Lever"] = make_lever()
    stock, plate = make_stock()
    parts["Buttstock"] = stock
    parts["Buttplate"] = plate
    hf, hu = HAMMER_PIVOT
    lf, lu = LEVER_PIVOT
    # Screws: through the receiver (heads on the right, ends on the left), the tangs, the butt, the cap, the band.
    screws = [
        ("Screw_Hammer", (HW + 0.002, hf, hu), (1, 0, 0), 0.095, 20),
        ("Screw_HammerL", (-HW - 0.002, hf, hu), (-1, 0, 0), 0.09, 0, False),
        ("Screw_LeverPin", (HW + 0.002, lf, lu), (1, 0, 0), 0.09, 65),
        ("Screw_LeverPinL", (-HW - 0.002, lf, lu), (-1, 0, 0), 0.085, 0, False),
        ("Screw_SidePlate", (HW + 0.002, -3.23, -0.77), (1, 0, 0), 0.055, 110),
        ("Screw_SidePlateL", (-HW - 0.002, -3.23, -0.77), (-1, 0, 0), 0.055, 30),
        ("Screw_Spring", (HW + 0.002, -3.10, -1.13), (1, 0, 0), 0.05, 140),
        ("Screw_UpperTang", (0.0, -6.95, curve_at(STOCK_TOP, -6.95) + 0.005), (0, -0.25, 1), 0.075, 90),
        ("Screw_LowerTang", (0.0, -7.20, curve_at(STOCK_BOT, -7.20) - 0.005), (0, -0.3, -1), 0.07, 10),
        ("Screw_ForendCap", (0.51 + 0.012 + 0.002, fend + 0.42, (FOREND_TOP + FOREND_BOT) / 2), (1, 0, 0), 0.07, 45),
    ]
    if not CARBINE:
        screws.append(("Screw_MagBand", (-(barrel_apothem(BAND_F) + 0.06) - 0.002, BAND_F + 0.16, (TUBE_U - RT - 0.04) / 2),
                       (-1, 0, 0), 0.06, 75))
    # Two screws through the buttplate's face, along its normal.
    for nm, k in (("Screw_ButtTop", 1), ("Screw_ButtBottom", 5)):
        a, b = Vector(CRESCENT[k - 1]), Vector(CRESCENT[k + 1])
        t = (b - a).normalized()
        nrm = Vector((-t.y, t.x))
        if nrm.x > 0:
            nrm = -nrm
        p = Vector(CRESCENT[k])
        screws.append((nm, (0.0, p.x + nrm.x * 0.002, p.y + nrm.y * 0.002), (0, nrm.x, nrm.y), 0.075, 30 + 60 * k))
    for s in screws:
        name, c, ax, r, slot = s[:5]
        dome = s[5] if len(s) > 5 else True
        parts[name] = screw(name, c, ax, r, 0.028 if dome else 0.008, slot, dome)

    # The rounds: in the chamber (its rim at the breech face), on the carrier, first in the tube.
    rounds = {"Chamber": make_round("Chamber", 0.0, 0.0), "Carrier": make_round("Carrier", -1.72, TUBE_U),
              "Tube": make_round("Tube", 0.10, TUBE_U)}

    # Pivots.
    set_pivot(parts["Hammer"], (0.0, hf, hu))
    set_pivot(parts["Lever"], (0.0, lf, lu))
    set_pivot(parts["Trigger"], (0.0, TRIGGER_PIVOT[0], TRIGGER_PIVOT[1]))
    set_pivot(parts["Gate"], (HW - 0.03, GATE_F1, GATE_U))
    set_pivot(parts["Bolt"], (0.0, 0.0, 0.0))
    set_pivot(parts["Carrier"], (0.0, -0.94, TUBE_U))
    set_pivot(parts["DustCover"], (0.0, 0.0, 0.60))
    set_pivot(parts["MagTube"], (0.0, 0.0, TUBE_U))
    for k, (case, bull) in rounds.items():
        f_rim = {"Chamber": 0.0, "Carrier": -1.72, "Tube": 0.10}[k]
        u = 0.0 if k == "Chamber" else TUBE_U
        set_pivot(case, (0.0, f_rim, u))
        set_pivot(bull, (0.0, f_rim, u))
    allobs = list(parts.values()) + [x for r in rounds.values() for x in r]
    for ob in allobs:
        finish(ob)
        box_uv(ob, 0.04)
    root = bpy.data.objects.new("Win73", None)
    bpy.context.collection.objects.link(root)
    for name, ob in parts.items():
        ob.parent = root
        ob.location -= ORIGIN
    # The rounds ride their parts: the carrier's on the carrier, the tube's in the tube.
    for k, (case, bull) in rounds.items():
        for ob in (case, bull):
            if k == "Chamber":
                ob.parent = root
                ob.location -= ORIGIN
            else:
                host = parts["Carrier"] if k == "Carrier" else parts["MagTube"]
                ob.location = ob.location - host.location - ORIGIN
                ob.parent = host
    markers = {
        "Muzzle": (0.0, MUZZLE, 0.0), "ReceiverFront": (0.0, F_RECV, 0.0), "BoreBreech": (0.0, 0.0, 0.0),
        "SightRear": (0.0, SIGHT_REAR_F, LOS_REAR), "SightFront": (0.0, SIGHT_FRONT_F, FRONT_TOP),
        "Wrist": (0.0, -6.0, -2.2), "TriggerFace": (0.0, -3.9, -2.7), "Forend": (0.0, 7.0, -0.9),
        "GatePoint": (HW, -0.80, GATE_U), "Port": (0.0, -1.0, 0.6), "Butt": (0.0, -16.5, -5.0),
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
    spur.location = P(0.0, -4.02, 0.78) - P(0.0, hf, hu)
    loop = bpy.data.objects.new("LeverLoop", None)
    bpy.context.collection.objects.link(loop)
    loop.parent = parts["Lever"]
    loop.location = P(0.0, -5.5, -3.9) - P(0.0, lf, lu)
    return parts, rounds, markers, tube_end


def g(v):
    """Blender (x, y, z) metres -> Godot (x, z, -y)."""
    return [round(v[0], 6), round(v[2], 6), round(-v[1], 6)]


def rig_json(parts, markers, path):
    hf, hu = HAMMER_PIVOT
    lf, lu = LEVER_PIVOT
    tf, tu = TRIGGER_PIVOT
    rig = {
        "about": "Winchester Model 1873, #734 step 1: experiments/gun_lab/win73/win73_blender.py. Godot space, metres, the gun's "
                 "local frame (barrel along -Z, up +Y, right +X). Angles in degrees about the axis given (right-hand rule). "
                 "Travel numbers marked 'est' are estimates from the mechanism's geometry, not measured.",
        "barrel_in": BARREL,
        "kind": "carbine" if CARBINE else "rifle",
        "magazine": 12 if CARBINE else 15,
        "parts": [o.name for o in parts.values()],
        "rounds": {"Chamber": {"case": "CaseChamber", "bullet": "BulletChamber", "parent": "Win73"},
                   "Carrier": {"case": "CaseCarrier", "bullet": "BulletCarrier", "parent": "Carrier"},
                   "Tube": {"case": "CaseTube", "bullet": "BulletTube", "parent": "MagTube"},
                   "show": "loaded: case+bullet; spent: case only; empty: neither"},
        "moving": {
            "Lever": {"pivot": g(P(0, lf, lu) - ORIGIN), "axis": [1, 0, 0], "throw_deg": 52.0,
                      "note": "est: + swings the loop down and forward; the bolt, carrier and hammer follow (win73_rig.gd)"},
            "Bolt": {"rest": g(P(0, 0, 0) - ORIGIN), "axis": [0, 0, 1], "stroke_m": round(D["bolt_stroke"] * IN, 5),
                     "note": "est: back (+Z) as the toggle links unfold, (1 - cos(pi t)) / 2 of the stroke over the lever's throw"},
            "Carrier": {"rest": g(P(0, -0.94, TUBE_U) - ORIGIN), "axis": [0, 1, 0], "lift_m": round(D["carrier_lift"] * IN, 5),
                        "note": "lifts straight up from the tube's line to the bore's in the last 30% of the opening, "
                                "drops in the last 15% of the closing (the round already in the chamber)"},
            "Hammer": {"pivot": g(P(0, hf, hu) - ORIGIN), "axis": [1, 0, 0],
                       "notches_deg": {"rest": 0.0, "half": 13.0, "full": 34.0},
                       "note": "est: + takes the spur back; the bolt's back cocks it in the first 45% of the throw"},
            "Trigger": {"pivot": g(P(0, tf, tu) - ORIGIN), "axis": [1, 0, 0], "pull_deg": -8.0,
                        "note": "est: - takes the blade back"},
            "DustCover": {"rest": g(P(0, 0, 0.60) - ORIGIN), "axis": [0, 0, 1], "stroke_m": round(D["cover_stroke"] * IN, 5),
                          "note": "est: slides back along its rail, uncovering the port"},
            "Gate": {"pivot": g(P(HW - 0.03, GATE_F1, GATE_U) - ORIGIN), "axis": [0, 1, 0], "push_deg": -16.0,
                     "note": "est: hinged at its front, its back pressed in by a round going into the tube"},
        },
        "markers": {k: g(P(*v) - ORIGIN) for k, v in markers.items()},
        "dims_in": dict(D, muzzle_f=MUZZLE, sight_rear_f=SIGHT_REAR_F, sight_front_f=SIGHT_FRONT_F, los_rear=LOS_REAR,
                        front_top=FRONT_TOP, heel_f=STOCK_HEEL),
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
    px = int(arg("px", "2000"))
    sc.render.resolution_x = px
    sc.render.resolution_y = int(px * 0.26)
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
    span = MUZZLE - STOCK_HEEL + 1.0
    cf, cu = (MUZZLE + STOCK_HEEL) / 2, -3.0
    center = P(0, cf, cu) - ORIGIN
    views = {"right": (90, 0, 90), "left": (90, 0, -90), "front34": (75, 0, 140), "rear34": (70, 0, -30), "top": (0, 0, 90),
             "under34": (115, 0, 60),
             # close on the action (the 3D shape of the hammer, lever, gate; an outline can match and the
             # shape still be wrong, the Colt's lesson)
             "action_rear34": (62, 0, -38), "action_front34": (70, 0, 128), "action_left34": (65, 0, -142),
             "spur_top": (25, 0, -20)}
    only = arg("views", "")
    for name, (rx, ry, rz) in views.items():
        if only and name not in only.split(","):
            continue
        close = name.startswith(("action", "spur"))
        cam.data.type = "ORTHO"
        cam.data.ortho_scale = (4.0 if name == "spur_top" else 11.0 if close else span) * IN * 1.02
        rot = Matrix.Rotation(math.radians(rz), 3, "Z") @ Matrix.Rotation(math.radians(rx), 3, "X")
        cam.rotation_euler = rot.to_euler()
        at = (P(0, -3.8, 0.0) if name == "spur_top" else P(0, -2.6, -1.4)) - ORIGIN if close else center
        sc.render.resolution_y = int(px * (0.62 if close else 0.26))
        cam.location = at + rot @ Vector((0, 0, 1.5))
        sc.render.filepath = os.path.join(outdir, name + ".png")
        bpy.ops.render.render(write_still=True)
        if name in ("right", "left"):
            ppi = sc.render.resolution_x / (span * 1.02)
            with open(os.path.join(outdir, name + ".json"), "w") as f:
                json.dump({"px_per_in": ppi, "centre_f": cf, "centre_u": cu, "muzzle_f": MUZZLE, "barrel_in": BARREL,
                           "size": [sc.render.resolution_x, sc.render.resolution_y], "muzzle_right": name == "right"}, f, indent=1)


def main():
    parts, rounds, markers, tube_end = build()
    keep = set()

    def walk(o):
        keep.add(o.name)
        for c in o.children:
            walk(c)
    walk(bpy.data.objects["Win73"])
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    tag = "%g" % BARREL
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "win73_%s.glb" % tag)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True, export_yup=True,
                              export_extras=False, export_cameras=False, export_lights=False)
    rig_json(parts, markers, os.path.join(OUT, "win73_%s_rig.json" % tag))
    obs = list(parts.values()) + [x for r in rounds.values() for x in r]
    tris = 0
    for o in obs:
        o.data.calc_loop_triangles()
        tris += len(o.data.loop_triangles)
    for w in WARN:
        print("WARN boolean", w)
    print("Win73 %s in: %d parts, %d triangles -> %s" % (BARREL, len(obs), tris, glb))
    if PREVIEW:
        preview(PREVIEW)


main()
