"""The horse's form, skeleton and idle as numbers (no Blender here: tools/blender/horse.py builds,
rigs, paints and exports it).

Coordinates are Blender's: metres, +Z up, the horse facing -X (his head at -X, as PropModels.horse's
was, so the street's placements carry over), his right side +Y, the ground at z = 0 and the origin
under the middle of his barrel. Exported to glTF, -X stays -X and +Y becomes Godot's -Z.

The form is a signed distance field: ellipsoids and round cones (each a muscle mass or a bone's
length) joined by a smooth union, cut flat under the hooves, then meshed by marching cubes at 1 cm.
The distance functions and the smooth union are the ones Inigo Quilez describes in his articles
("distance functions", "smooth minimum", iquilezles.org); written here from those descriptions.

A 15-hand bay (1.52 m at the withers) after the street painting's (docs/concept/
street-golden-hour-painted.png, the horse at the livery rail): a deep chest, a round croup, a
long arched neck, a fine head held low, clean legs, the mane falling to his right.
"""
import math

import numpy as np

# --- distance functions -------------------------------------------------------------------------


def _frame(axis):
    """Three orthonormal axes, the first along `axis`, the third as close to +Z as it can be."""
    a = np.asarray(axis, float)
    a = a / np.linalg.norm(a)
    up = np.array([0.0, 0.0, 1.0]) if abs(a[2]) < 0.95 else np.array([1.0, 0.0, 0.0])
    side = np.cross(up, a)
    side /= np.linalg.norm(side)
    third = np.cross(a, side)
    return a, side, third


def ellipsoid(p, centre, radii, axis=(1.0, 0.0, 0.0)):
    """An ellipsoid's (approximate, bound-correct near the surface) distance: radii along `axis`,
    across it sideways, and across it in the plane holding +Z."""
    a, s, t = _frame(axis)
    q = p - np.asarray(centre, float)
    local = np.stack([q @ a, q @ s, q @ t], axis=-1)
    r = np.asarray(radii, float)
    k0 = np.linalg.norm(local / r, axis=-1)
    k1 = np.linalg.norm(local / (r * r), axis=-1)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def round_cone(p, a, b, ra, rb):
    """A cone with round ends: radius ra at a, rb at b (Quilez's exact round cone)."""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    ba = b - a
    l2 = ba @ ba
    rr = ra - rb
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = p - a
    y = pa @ ba
    z = y - l2
    xv = pa * l2 - y[..., None] * ba
    x2 = np.einsum("...i,...i->...", xv, xv)
    y2 = y * y * l2
    z2 = z * z * l2
    k = math.copysign(1.0, rr) * rr * rr * x2
    out = (np.sqrt(x2 * a2 * il2) + y * rr) * il2 - ra
    first = np.sign(z) * a2 * z2 > k
    out = np.where(first, np.sqrt(x2 + z2) * il2 - rb, out)
    second = np.sign(y) * a2 * y2 < k
    out = np.where(second, np.sqrt(x2 + y2) * il2 - ra, out)
    return out


def flat_cone(p, a, b, ra, rb, squash):
    """A round cone squashed across +Y by `squash` (a flat ear, a flat sheaf of tail hair)."""
    q = p.copy()
    mid = (np.asarray(a, float) + np.asarray(b, float)) * 0.5
    q[..., 1] = mid[1] + (q[..., 1] - mid[1]) / squash
    return round_cone(q, a, b, ra, rb) * squash


def smin(a, b, k):
    """Smooth union (polynomial smooth minimum, blend width k metres)."""
    if k <= 0.0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


# --- the horse ----------------------------------------------------------------------------------

# Side profile points (x, z) the parts are hung on; y is given where a part is paired. Measured off
# Sean's pictures (docs/concept/horse/, horse_ref.py; 454 px a metre in the left side view, his
# withers at 1.52 m): a short-backed, deep-bodied bay, the head small and carried high.
WITHERS = (-0.31, 1.55)
POLL = (-1.07, 1.93)
MUZZLE = (-1.36, 1.5)
HEAD_DIR = np.array([MUZZLE[0] - POLL[0], 0.0, MUZZLE[1] - POLL[1]])
HEAD_LEN = float(np.linalg.norm(HEAD_DIR))
HEAD_DIR /= HEAD_LEN
# The head's "face" side (forehead, nose) is perpendicular to its axis, forward and up.
HEAD_FACE = np.array([HEAD_DIR[2], 0.0, -HEAD_DIR[0]])


# Overrides measured off a model (horse_rodin.py): legs by (part, side), the trunk's front and rear.
LEGS = {}
TRUNK = (-0.78, 0.78)


def set_head(poll, muzzle, withers):
    """The head and withers measured off a model (horse_rodin.measure)."""
    global POLL, MUZZLE, WITHERS, HEAD_DIR, HEAD_LEN, HEAD_FACE
    POLL, MUZZLE, WITHERS = tuple(poll), tuple(muzzle), tuple(withers)
    HEAD_DIR = np.array([MUZZLE[0] - POLL[0], 0.0, MUZZLE[1] - POLL[1]])
    HEAD_LEN = float(np.linalg.norm(HEAD_DIR))
    HEAD_DIR = HEAD_DIR / HEAD_LEN
    HEAD_FACE = np.array([HEAD_DIR[2], 0.0, -HEAD_DIR[0]])


def set_legs(joints):
    """Each leg's joints measured off a model: {("front"|"hind", side): {joint: (x, y, z)}}."""
    LEGS.clear()
    LEGS.update(joints)


def set_tail(points):
    global TAIL
    TAIL = [tuple(p) for p in points]


def set_trunk(front, rear):
    global TRUNK
    TRUNK = (front, rear)


def _head_point(along, face=0.0, side=0.0):
    """A point on the head: `along` metres from the poll down its axis, `face` towards the forehead."""
    p = np.array([POLL[0], 0.0, POLL[1]]) + HEAD_DIR * along + HEAD_FACE * face
    p[1] = side
    return p


# Legs, each (side sign s): joints by name -> (x, y, z). From the pictures: the forelegs under
# the withers, the hinds under the quarters with the hocks behind the buttock's line.
# He stands staggered, as both side pictures have him: his left fore and hind forward, the right
# ones back, the right hind well back (where each picture's cannons are, the two views lined up
# by his trunk). The shift (m along x) of each side's leg from the elbow or stifle down.
STAGGER_FORE = {-1.0: -0.04, 1.0: 0.07}
STAGGER_HIND = {-1.0: -0.08, 1.0: 0.17}


def front_leg(s):
    if ("front", s) in LEGS:
        return dict(LEGS[("front", s)])
    d = STAGGER_FORE[s]
    return {
        "shoulder": (-0.66, s * 0.14, 1.08),  # point of shoulder
        "elbow": (-0.49 + d * 0.3, s * 0.13, 0.9),
        "knee": (-0.49 + d, s * 0.115, 0.5),
        "fetlock": (-0.49 + d, s * 0.115, 0.18),
        "coronet": (-0.52 + d, s * 0.115, 0.075),
        "toe": (-0.555 + d, s * 0.115, 0.0),
    }


def hind_leg(s):
    if ("hind", s) in LEGS:
        return dict(LEGS[("hind", s)])
    d = STAGGER_HIND[s]
    return {
        "hip": (0.5, s * 0.15, 1.27),
        "stifle": (0.38 + d * 0.3, s * 0.17, 0.9),
        "hock": (0.64 + d, s * 0.115, 0.58),
        "fetlock": (0.66 + d, s * 0.115, 0.18),
        "coronet": (0.635 + d, s * 0.115, 0.075),
        "toe": (0.605 + d, s * 0.115, 0.0),
    }


def _dir(a, b):
    v = np.asarray(b, float) - np.asarray(a, float)
    return v / np.linalg.norm(v)


def _leg_sdf(p, j, front):
    """One leg from the elbow or stifle down: muscle at the top, bone and tendon below."""
    d = np.full(p.shape[:-1], 1e9)
    if front:
        # The forearm: muscled at the elbow, down to a flat knee.
        d = smin(d, round_cone(p, j["elbow"], j["knee"], 0.085, 0.048), 0.02)
        d = smin(d, ellipsoid(p, np.add(j["elbow"], (-0.01, 0.0, -0.12)), (0.17, 0.07, 0.088), _dir(j["elbow"], j["knee"])), 0.035)
        d = smin(d, ellipsoid(p, j["knee"], (0.052, 0.05, 0.06)), 0.02)
        top = j["knee"]
    else:
        # The gaskin: a muscle down the back of the shin to the hock; the hock's point behind.
        d = smin(d, round_cone(p, j["stifle"], j["hock"], 0.085, 0.05), 0.02)
        gm = np.add(np.multiply(j["stifle"], 0.45), np.multiply(j["hock"], 0.55)) + np.array([0.035, 0.0, 0.0])
        d = smin(d, ellipsoid(p, gm, (0.15, 0.058, 0.07), _dir(j["stifle"], j["hock"])), 0.03)
        d = smin(d, ellipsoid(p, j["hock"], (0.07, 0.05, 0.065)), 0.02)
        d = smin(d, round_cone(p, j["hock"], np.add(j["hock"], (0.04, 0.0, 0.05)), 0.045, 0.032), 0.03)
        top = j["hock"]
    # The cannon (flat side to side, the tendon behind it), the fetlock, the pastern, the hoof.
    d = smin(d, round_cone(p, top, j["fetlock"], 0.04, 0.037), 0.012)
    d = smin(d, round_cone(p, np.add(top, (0.025, 0.0, -0.04)), np.add(j["fetlock"], (0.025, 0.0, 0.02)), 0.022, 0.024), 0.012)
    d = smin(d, ellipsoid(p, np.add(j["fetlock"], (0.012, 0.0, -0.01)), (0.058, 0.045, 0.05)), 0.015)
    d = smin(d, round_cone(p, j["fetlock"], j["coronet"], 0.04, 0.042), 0.012)
    hoof_top = j["coronet"]
    hoof_bottom = (j["toe"][0] + 0.03, j["toe"][1], 0.012)
    hoof = round_cone(p, hoof_top, hoof_bottom, 0.046, 0.064)
    d = smin(d, hoof, 0.008)
    return d


# How wide he is (half-widths, m) along his length: the head and neck, and the trunk.
NECK_WIDTH = [(-1.4, 0.055), (-1.34, 0.085), (-1.25, 0.1), (-1.15, 0.115), (-1.07, 0.12), (-0.98, 0.1),
              (-0.88, 0.09), (-0.78, 0.1), (-0.68, 0.12), (-0.55, 0.14), (-0.45, 0.15), (-0.3, 0.15)]
TRUNK_WIDTH = [(-0.8, 0.08), (-0.72, 0.16), (-0.62, 0.2), (-0.5, 0.22), (-0.35, 0.24), (-0.15, 0.26),
               (0.1, 0.265), (0.3, 0.26), (0.45, 0.25), (0.6, 0.22), (0.7, 0.18), (0.78, 0.08)]
# Where the neck meets the trunk in the side view: a line from the withers down to the front of
# the chest (above and before it is neck, below and behind it trunk; they overlap OVERLAP).
SPLIT = ((-0.31, 1.55), (-0.74, 1.0))
OVERLAP = 0.1
# The trunk's underline where a leg runs down from it (the outline goes on down the leg there):
# the girth behind the elbows, the belly, and the quarters' bottom rising to the buttock.
TRUNK_FLOOR = [(-0.8, 0.95), (-0.62, 0.92), (-0.55, 0.86), (0.3, 0.86), (0.45, 0.95), (0.6, 1.02), (0.8, 1.1)]
# The head's top under the ears: the poll, then the forehead down to the nose.
HEAD_ROOF = [(-1.4, 1.62), (-1.34, 1.6), (-1.07, 1.93), (-0.98, 1.95)]

_outline = None


def outline():
    """Sean's side outline (horse_ref.side_outline), loaded once: (x, top, bottom), m."""
    global _outline
    if _outline is None:
        import horse_ref
        _outline = horse_ref.side_outline(0.005)
    return _outline


def _interp(table, x):
    return np.interp(x, [t[0] for t in table], [t[1] for t in table])


def _loft(p, lo, hi, width, egg=0.0):
    """A body lofted along x from the side outline: at each x an ellipse from `lo` to `hi` (z, per
    x) and `width` (half, per x) across, wider towards the top by `egg`. A distance good near the
    surface, which is all marching cubes reads."""
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    ok = np.isfinite(lo) & np.isfinite(hi) & (hi > lo + 0.004)
    lo = np.where(ok, lo, 0.0)
    hi = np.where(ok, hi, 0.0)
    c = (lo + hi) * 0.5
    h = np.maximum((hi - lo) * 0.5, 0.002)
    u = (z - c) / h
    w = np.maximum(width * (1.0 + egg * np.clip(u, -1.0, 1.0)), 0.01)
    r = np.sqrt(u * u + (y / w) ** 2)
    d = (r - 1.0) * np.minimum(h, w)
    return np.where(ok, d, 1.0)


def body_sdf(p):
    """The horse but his tail's hair (that's its own mesh, tail_sdf): his side outline lofted
    (the head and neck, the trunk), the muscles that show from in front and behind, the ears,
    and the legs below the trunk."""
    ox, otop, obot = outline()
    x = p[..., 0]
    top = np.interp(x, ox, otop, left=np.nan, right=np.nan)
    bot = np.interp(x, ox, obot, left=np.nan, right=np.nan)
    (ax, az), (bx, bz) = SPLIT
    split = az + (x - ax) * (az - bz) / (ax - bx)
    roof = np.where(x < HEAD_ROOF[-1][0], _interp(HEAD_ROOF, x), np.inf)
    neck_top = np.minimum(top, roof)
    neck_bot = np.maximum(bot, split - OVERLAP)
    neck = _loft(p, np.where(x < ax + 0.02, neck_bot, np.nan), neck_top, _interp(NECK_WIDTH, x))
    trunk_bot = np.maximum(bot, _interp(TRUNK_FLOOR, x))
    trunk_top = np.minimum(top, split + OVERLAP)
    trunk = _loft(p, np.where(x > bx - 0.06, trunk_bot, np.nan), trunk_top, _interp(TRUNK_WIDTH, x), egg=0.12)
    d = smin(neck, trunk, 0.05)
    for s in (-1.0, 1.0):
        # The quarters' round muscles either side of the spine (seen from behind, a heart shape).
        d = smin(d, ellipsoid(p, (0.5, s * 0.11, 1.22), (0.24, 0.14, 0.24)), 0.06)
        # The scapula's muscle, from the withers down to the point of shoulder.
        d = smin(d, ellipsoid(p, (-0.5, s * 0.13, 1.24), (0.24, 0.085, 0.12), (-0.5, 0.0, -0.75)), 0.06)
        # The ears: cupped leaves pricked up, from the poll.
        base = (POLL[0] + 0.01, s * 0.065, POLL[1] + 0.02)
        tip = (POLL[0] - 0.03, s * 0.1, POLL[1] + 0.15)
        d = smin(d, flat_cone(p, base, tip, 0.036, 0.012, 0.55), 0.015)
        d = smin(d, ellipsoid(p, (POLL[0] - 0.01, s * 0.08, POLL[1] + 0.075), (0.028, 0.02, 0.05)), 0.02)
    d = smin(d, round_cone(p, (0.7, 0.0, 1.44), (0.78, 0.0, 1.38), 0.06, 0.045), 0.04)  # the dock
    # The legs: the upper arm and the thigh hang off the body; below them, each leg.
    for s in (-1.0, 1.0):
        f = front_leg(s)
        d = smin(d, round_cone(p, f["shoulder"], f["elbow"], 0.11, 0.085), 0.05)
        d = smin(d, _leg_sdf(p, f, True), 0.035)
        h = hind_leg(s)
        d = smin(d, round_cone(p, h["hip"], h["stifle"], 0.16, 0.1), 0.06)
        # The hamstring's curve from the point of buttock down to the gaskin.
        d = smin(d, round_cone(p, (0.7, s * 0.12, 1.2), (0.62, s * 0.13, 0.78), 0.11, 0.07), 0.06)
        d = smin(d, _leg_sdf(p, h, False), 0.04)
    # Flat under the hooves.
    return np.maximum(d, -p[..., 2])


# The tail's hair: set high, a low arch off the dock, then falling to below the hocks (the
# pictures' tail); wider seen from the side, thin seen from behind.
TAIL = [(0.74, 1.47), (0.85, 1.54), (0.95, 1.47), (1.0, 1.26), (1.02, 1.01), (1.03, 0.79), (1.02, 0.62)]


def tail_sdf(p):
    d = np.full(p.shape[:-1], 1e9)
    radii = [0.035, 0.045, 0.06, 0.075, 0.09, 0.09, 0.05]
    for i in range(len(TAIL) - 1):
        a = (TAIL[i][0], 0.0, TAIL[i][1])
        b = (TAIL[i + 1][0], 0.0, TAIL[i + 1][1])
        d = smin(d, flat_cone(p, a, b, radii[i], radii[i + 1], 0.4), 0.03)
    return d


def grid_mesh(sdf, lo, hi, step):
    """Marching cubes over a box (lo, hi) at `step` metres: (verts, faces)."""
    from skimage import measure

    xs = np.arange(lo[0], hi[0] + step, step)
    ys = np.arange(lo[1], hi[1] + step, step)
    zs = np.arange(lo[2], hi[2] + step, step)
    g = np.stack(np.meshgrid(xs, ys, zs, indexing="ij"), axis=-1)
    field = np.empty(g.shape[:-1], np.float32)
    # In slabs along x, so the intermediate arrays stay small.
    for i in range(0, len(xs), 24):
        field[i:i + 24] = sdf(g[i:i + 24])
    verts, faces, _n, _v = measure.marching_cubes(field, 0.0, spacing=(step, step, step))
    verts += np.asarray(lo, float)
    # (skimage winds them facing out of the inside region, as Blender and glTF want.)
    return verts, faces


BODY_BOX = ((-1.5, -0.4, -0.025), (0.95, 0.4, 2.15))  # z off the grid: the soles at 0 fall between samples
TAIL_BOX = ((0.62, -0.12, 0.45), (1.25, 0.12, 1.75))


# --- the skeleton -------------------------------------------------------------------------------

# Bones: name -> (head, tail, parent, deform). The trunk runs from the croup to the withers; legs
# hang off the pelvis and the chest by their own top bone (scapula, thigh) so the body can sway
# over planted hooves.
def bones():
    b = {}

    def add(name, head, tail, parent, deform=True):
        b[name] = (tuple(map(float, head)), tuple(map(float, tail)), parent, deform)

    add("root", (0.0, 0.0, 0.0), (0.0, 0.0, 0.25), None, False)
    add("body", (0.05, 0.0, 1.2), (0.05, 0.0, 1.4), "root", False)
    add("pelvis", (0.1, 0.0, 1.3), (TRUNK[1] - 0.06, 0.0, 1.36), "body")
    add("spine", (0.1, 0.0, 1.3), (WITHERS[0] + 0.16, 0.0, 1.28), "body")
    # The neck from in front of the withers up to the poll (shares from Sean's pictured horse).
    c = (WITHERS[0] - 0.14, 1.32)
    pp = (POLL[0] + 0.05, POLL[1] - 0.05)

    def along(fx, fz):
        return (c[0] + (pp[0] - c[0]) * fx, 0.0, c[1] + (pp[1] - c[1]) * fz)
    add("chest", (WITHERS[0] + 0.16, 0.0, 1.28), (c[0], 0.0, c[1]), "spine")
    add("neck1", (c[0], 0.0, c[1]), along(0.34, 0.46), "chest")
    add("neck2", along(0.34, 0.46), along(0.66, 0.79), "neck1")
    add("neck3", along(0.66, 0.79), along(0.92, 0.92), "neck2")
    poll = (POLL[0] + 0.02, 0.0, POLL[1] - 0.06)
    add("head", poll, tuple(np.add(poll, HEAD_DIR * HEAD_LEN * 0.95)), "neck3")
    for side, s in (("L", -1.0), ("R", 1.0)):
        add("ear." + side, (POLL[0] + 0.01, s * 0.065, POLL[1] + 0.02), (POLL[0] - 0.03, s * 0.1, POLL[1] + 0.15), "head")
        f = front_leg(s)
        add("scapula." + side, (WITHERS[0] - 0.02, s * 0.11, WITHERS[1] - 0.08), f["shoulder"], "chest")
        add("upperarm." + side, f["shoulder"], f["elbow"], "scapula." + side)
        add("forearm." + side, f["elbow"], f["knee"], "upperarm." + side)
        add("cannon." + side, f["knee"], f["fetlock"], "forearm." + side)
        add("pastern." + side, f["fetlock"], f["coronet"], "cannon." + side)
        add("hoof." + side, f["coronet"], f["toe"], "pastern." + side)
        h = hind_leg(s)
        add("thigh." + side, h["hip"], h["stifle"], "pelvis")
        add("shin." + side, h["stifle"], h["hock"], "thigh." + side)
        add("hcannon." + side, h["hock"], h["fetlock"], "shin." + side)
        add("hpastern." + side, h["fetlock"], h["coronet"], "hcannon." + side)
        add("hhoof." + side, h["coronet"], h["toe"], "hpastern." + side)
    parent = "pelvis"
    pts = [(TAIL[0][0] - 0.02, TAIL[0][1] - 0.03)] + TAIL[1:]
    for i in range(len(pts) - 1):
        name = "tail%d" % (i + 1)
        add(name, (pts[i][0], 0.0, pts[i][1]), (pts[i + 1][0], 0.0, pts[i + 1][1]), parent)
        parent = name
    return b


# --- skin weights -------------------------------------------------------------------------------


def _seg_dist(p, a, b):
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    ab = b - a
    t = np.clip(((p - a) @ ab) / (ab @ ab), 0.0, 1.0)
    return np.linalg.norm(p - (a + t[:, None] * ab), axis=1), t


# Bones a vertex may only take weight from inside these boxes (lo, hi): the ears from the head's
# top, the tail from behind the croup; the legs only on their own side.
def _allowed(name, p):
    ok = np.ones(len(p), bool)
    if name.endswith(".L"):
        ok &= p[:, 1] < 0.02
    if name.endswith(".R"):
        ok &= p[:, 1] > -0.02
    if name.startswith("ear."):
        ok &= p[:, 2] > POLL[1] + 0.0
    if name.startswith("tail"):
        # The hair and the dock, not the buttock under it.
        ok &= p[:, 0] > TAIL[0][0] - 0.02 + np.maximum(0.0, TAIL[0][1] - 0.09 - p[:, 2]) * 0.45
    lower = ("forearm", "cannon", "pastern", "hoof", "shin", "hcannon", "hpastern", "hhoof")
    if name.split(".")[0] in lower:
        ok &= p[:, 2] < (1.02 if name.startswith(("forearm", "shin")) else 0.62)
    return ok


def weights(verts, neighbours, bone_defs, only=None, smooth=3, power=5.0, tail=None):
    """Skin weights by distance to each deform bone (closest bones dominate, power `power`),
    limited to the bones a part may move with, smoothed over the mesh `smooth` times, the four
    largest kept: (bone names, (n, 4) indices, (n, 4) weights)."""
    names = [n for n, v in bone_defs.items() if v[3] and (only is None or n in only)]
    p = np.asarray(verts, float)
    d = np.empty((len(p), len(names)))
    for i, n in enumerate(names):
        h, t, _par, _def = bone_defs[n]
        d[:, i], _ = _seg_dist(p, h, t)
        d[~_allowed(n, p), i] = 1e3
        if tail is not None:
            # A model's tail (measured): the tail's bones move it and nothing else does but the
            # pelvis at the dock; the tail's bones move nothing else.
            if n.startswith("tail"):
                d[~tail, i] = 1e3
            elif n != "pelvis":
                d[tail, i] = 1e3
    near = d.min(axis=1, keepdims=True)
    w = (np.maximum(near, 0.01) / np.maximum(d, 0.01)) ** power
    w[d > near * 2.0 + 0.06] = 0.0
    w /= w.sum(axis=1, keepdims=True)
    # Below the knees and hocks the bones turn far from each other (a rested hind's pastern
    # 45 degrees off its cannon): there the weights stay crisp, or the fetlock crumples.
    crisp = p[:, 2] < 0.6
    for _ in range(smooth):
        w2 = w.copy()
        for i, nb in enumerate(neighbours):
            if nb and not crisp[i]:
                w2[i] = 0.5 * w[i] + 0.5 * w[nb].mean(axis=0)
        w = w2
    order = np.argsort(-w, axis=1)[:, :4]
    top = np.take_along_axis(w, order, axis=1)
    top /= np.maximum(top.sum(axis=1, keepdims=True), 1e-9)
    return names, order, top


# --- collision ----------------------------------------------------------------------------------


def capsules():
    """His collision (Horse's body: cover later), a capsule per part on the bone that carries it:
    [bone, from, to, radius] in these axes."""
    out = [
        ["spine", (TRUNK[0] + 0.12, 0.0, 1.18), (0.18, 0.0, 1.18), 0.27],
        ["pelvis", (0.28, 0.0, 1.22), (TRUNK[1] - 0.12, 0.0, 1.22), 0.25],
        ["neck2", (WITHERS[0] - 0.21, 0.0, 1.38), (POLL[0] + 0.13, 0.0, POLL[1] - 0.13), 0.13],
        ["head", (POLL[0] - 0.03, 0.0, POLL[1] - 0.06), (MUZZLE[0] + 0.06, 0.0, MUZZLE[1] + 0.02), 0.1],
    ]
    for side, s in (("L", -1.0), ("R", 1.0)):
        f = front_leg(s)
        out.append(["forearm." + side, f["elbow"], f["coronet"], 0.065])
        h = hind_leg(s)
        out.append(["shin." + side, h["stifle"], h["hock"], 0.075])
        out.append(["hcannon." + side, h["hock"], h["coronet"], 0.05])
    return out
