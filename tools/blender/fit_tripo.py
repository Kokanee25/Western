"""Fit a Tripo man (tools/characters/: assets/people/tripo/<id>.glb, rigged by Tripo) to the game's
skeleton and hitboxes, as make_people.py fits MakeHuman's base mesh.

    ~/bpyenv/bin/python tools/blender/fit_tripo.py [--only=stranger]     (bpy: pip install bpy==5.0.1)
    blender -b --python tools/blender/fit_tripo.py -- [--only=stranger]

For each person in assets/people/people.json with "source": "tripo":
  1. His mesh (one skin: body, clothes, hat and hair as Tripo made them) into our body space
     (metres, facing -Z, feet at the origin, his right +X): Tripo's man faces +X at 1.0 tall.
  2. Warped onto our skeleton (assets/people/envelope.json): each limb bone is moved, turned and
     stretched from Tripo's joints (its rig's bind pose) to ours, blended at the joints, as
     make_people.Person.warp does; the head keeps his own proportions. No envelope fit: he wears
     a coat, and his widths are his own (the hitboxes sit inside him).
  3. Fingers cut off at the knuckles (the game's fingers are separate parts).
  4. Skinned to our 17 bones with BodyMesh's joint blends (make_people.Person.weights); the head
     (everything above the collar, HEAD_FROM) and the rest as two meshes, "body_head" and
     "body_skin", cut down to a game budget in Blender, exported with our bones to
     assets/people/<id>.glb. Tripo's UVs are kept.
  5. His texture (assets/people/tripo/<id>_color.png when tools/characters/head_paint.py has
     repainted his head, else Tripo's own) in squares of SQUARE_TEXELS Tripo texels (~5 mm on him,
     the painting's), one texel a square → assets/people/<id>_skin.png and <id>_head.png
     (PeopleBodies lays them on by his UVs).
  6. assets/people/<id>.json: what was done ("whole": true tells PeopleBodies he comes dressed, so
     BodyMesh's boots, belts and hat stay off him).
Everything is repeatable: nothing is hand-edited.
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_people as mp  # noqa: E402  (the warp, weights, armature and export, shared)

try:
    import bpy
except ImportError:
    bpy = None

TRIPO = "assets/people/tripo"
OUT = "assets/people"
# The head: everything above this share of his height before the warp (the collar's top).
HEAD_FROM = 0.815
# A bare-headed layered man: the collar's top is this share of the way from his neck joint (the
# collar bone) to his head joint (the jaw).
HEAD_FROM_NECK = 0.35
# ... and within this of the neck's axis (Tripo units, of his height), so the shoulders stay trunk.
HEAD_RADIUS = 0.09
# A bare-headed (layered) man above his shoulders: Tripo's auto-rig puts his neck joint at his
# shoulder line and his head joint half way up his neck (the Kid's at 0.76 and 0.81 of his
# height, his chin at 0.86), where ours are 4 and 13 cm over our shoulders. Mapped joint to joint
# that lifted his shoulders to his jaw and set his head on a stretched neck. So his shoulders go
# onto ours and all of him above them is scaled as one, so his crown lands this far over our
# skull's top (his hair), which also sizes his head to our skull rather than to his hips (the
# image model draws men with big heads: on the old rule the stranger's came out half as big
# again as the hitboxes inside it). A whole man's top is his hat, so he keeps the old rule.
HAIR_M = 0.02
# A hat's crown: where it is narrower than this share of the brim (above a flat brim, and above
# a brim curled up at the sides, whose sides reach a third of the way up the Kid's hat).
CROWN_SHARE = 0.7
# Tripo's scraps: a piece of its mesh joined to nothing else (welded by position), under this
# share of the triangles and further than SCRAP_GAP (his height = 1) from the biggest piece, is
# dropped (flat patches it left in the air beside the Kid's hands). A piece touching the rest (a
# boot's own sole) stays.
SCRAP_SHARE = 0.05
SCRAP_GAP = 0.008
# A bare-headed man's hand bone, for which points are his hand: wrist to knuckles, this many times
# over (the fingers past the knuckles).
FINGER_REACH = 2.5
# Where an arm may meet a bare-headed man's trunk: within this share of the way down his upper arm
# from the shoulder joint. Lower down, a triangle joining them is Tripo's where his arm touched his
# side (or a hand his hip, or his thigh): dropped, as it would stretch into a sheet when he raised
# his arms.
BRIDGE_SHOULDER = 0.35
# Pieces (a garment modelled alone, hung on the body): triangles after decimation, and how much
# wider than what they go over they are scaled (room for the cloth under them).
PIECE_TRIS = {"coat": 2600, "hat": 700}
PIECE_MARGIN = {"coat": 1.06, "hat": 1.05}
# The hat's brim sits this share of the way up his head from the jaw joint to the crown.
HAT_BAND = 0.72
# A coat's collar stands this far above the neck joint (Tripo units, of his height: ~6 cm).
COAT_COLLAR = 0.032
# A piece is pushed out of his skin to this clearance, where it lies within this reach of him
# (Tripo units: ~2 cm and ~11 cm on him).
PIECE_CLEARANCE = 0.012
PIECE_REACH = 0.06
# How many times the clearance push is averaged over neighbours before it is applied.
PIECE_SMOOTH = 8
# The coat as a shell of his body (Piece.as_shell, metres): how far off his skin over the trunk
# and arms, how far below the hips (a skirt), and how far from the Tripo coat a shell face may lie
# before it is cut (the open front, the hem).
COAT_OFFSET_M = 0.025
COAT_SKIRT_OFFSET_M = 0.045
COAT_GAP_M = 0.05
# Triangles after decimation: the body, and the head on its own (its face needs them).
TRI_BUDGET = 5500
HEAD_TRIS = 2200
# One square of the texture: this many of Tripo's 2048 texels a side (~2.8 mm on him: the
# painting's blocks on his face are about 3 mm).
SQUARE_TEXELS = 2
SMOOTH = False  # --smooth: see main()
# The coat's skirt (metres, our space): further than this from a thigh's axis, or nearer the
# middle than this between the legs, it hangs from the hips.
SKIRT_RADIUS = 0.11
BETWEEN_LEGS = 0.06
# Tripo's joint names for ours.
JOINTS = {"hips": "Hip", "neck": "NeckTwist01", "head": "Head",
          "r-shoulder": "R_Upperarm", "r-elbow": "R_Forearm", "r-hand": "R_Hand",
          "l-shoulder": "L_Upperarm", "l-elbow": "L_Forearm", "l-hand": "L_Hand",
          "r-upper-leg": "R_Thigh", "r-knee": "R_Calf", "r-ankle": "R_Foot", "r-toe": "R_ToeBase",
          "l-upper-leg": "L_Thigh", "l-knee": "L_Calf", "l-ankle": "L_Foot", "l-toe": "L_ToeBase"}


# --- The glb ----------------------------------------------------------------------------------

def load_glb(path):
    """Positions, normals, UVs, triangles (per-vertex UVs: the glb's vertices are already split
    at the seams), the rig's joints in their bind pose {name: xyz}, and the colour texture."""
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    blen = struct.unpack("<I", f[20 + clen:24 + clen])[0]
    binary = f[28 + clen:28 + clen + blen]

    def accessor(i):
        a = doc["accessors"][i]
        bv = doc["bufferViews"][a["bufferView"]]
        dtype = {5126: np.float32, 5123: np.uint16, 5125: np.uint32, 5121: np.uint8}[a["componentType"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
        start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
        return np.frombuffer(binary, dtype=dtype, count=a["count"] * n, offset=start).reshape(a["count"], n).astype(np.float64)

    prim = doc["meshes"][0]["primitives"][0]
    pos = accessor(prim["attributes"]["POSITION"])
    nrm = accessor(prim["attributes"]["NORMAL"])
    uv = accessor(prim["attributes"]["TEXCOORD_0"])
    tris = accessor(prim["indices"]).reshape(-1, 3).astype(np.int64)
    joints = {}
    if doc.get("skins"):
        skin = doc["skins"][0]
        ibm = accessor(skin["inverseBindMatrices"]).reshape(-1, 4, 4)
        for j, node in enumerate(skin["joints"]):
            world = np.linalg.inv(ibm[j].T)  # glTF matrices are column-major
            joints[doc["nodes"][node].get("name", str(node))] = world[:3, 3]
    # An item (a garment alone, unrigged) has no skin: joints stay empty.
    mat = doc["materials"][prim.get("material", 0)]
    tex = doc["textures"][mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]]
    img = doc["images"][tex["source"]]
    bv = doc["bufferViews"][img["bufferView"]]
    colour = Image.open(io.BytesIO(binary[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]])).convert("RGB")
    return pos, nrm, uv, tris, joints, colour


def to_body_space(p):
    """Tripo (1.0 tall, facing +X, his left at -Z) → ours (facing -Z, his right at +X); metres
    come with the warp's scale."""
    p = np.asarray(p, dtype=float)
    return np.stack([p[..., 2], p[..., 1], -p[..., 0]], axis=-1)


# --- A Rodin man ------------------------------------------------------------------------------
# Rodin (Hyper3D Gen-2.5, tools/characters/rodin.py) builds a man facing +Z (glTF's way), his right
# at -X, at its own size, and with no rig. load_rodin turns him into Tripo's frame (facing +X, his
# right at +Z, feet on 0, 1.0 tall) and finds his joints from his shape (find_joints), so the rest
# of the fit is a Tripo man's. Tried on the three Tripo men against their own rigs: within 2-3% of
# his height on average, 5.5% at worst (an elbow).
# Where Tripo's rigs put the joints, as shares of his height, hat and all (the stranger, the Kid
# and the bare-headed stranger agree within 0.02); the neck's is its base, the head's his jaw hinge.
RIG_Y = {"neck": 0.746, "head": 0.80, "shoulder": 0.759, "hip": 0.49, "knee": 0.265, "ankle": 0.035}
SH_MARGIN = 0.035            # a shoulder joint, in from his outline at its height
ARM_OUT = 0.10               # an arm's middle is at least this far out from his (a leg's isn't)
F_ELBOW, F_WRIST = 0.40, 0.74  # the elbow and wrist along his shoulder to his finger tips
HIP_WIDTH = (0.045, 0.09)    # a hip joint from his middle (a long coat hides his thighs)


def surface_points(v, tris, n=400000, seed=1):
    """Points spread evenly over his surface (by area): his cross-sections need them dense."""
    a, b, c = v[tris[:, 0]], v[tris[:, 1]], v[tris[:, 2]]
    area = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
    rng = np.random.default_rng(seed)
    pick = rng.choice(len(tris), size=n, p=area / area.sum())
    r1, r2 = rng.random(n), rng.random(n)
    s = np.sqrt(r1)
    return a[pick] * (1 - s)[:, None] + b[pick] * (s * (1 - r2))[:, None] + c[pick] * (s * r2)[:, None]


def _pieces(grid):
    """Each cell of a boolean grid labelled by the piece it's in (4-neighbours; 0 = empty): the
    smallest index in the piece, spread till nothing changes (numpy only: Blender's Python has
    no scipy)."""
    big = grid.size + 1
    lab = np.where(grid, np.arange(1, grid.size + 1).reshape(grid.shape), big)
    while True:
        new = lab.copy()
        new[1:, :] = np.minimum(new[1:, :], lab[:-1, :])
        new[:-1, :] = np.minimum(new[:-1, :], lab[1:, :])
        new[:, 1:] = np.minimum(new[:, 1:], lab[:, :-1])
        new[:, :-1] = np.minimum(new[:, :-1], lab[:, 1:])
        new[~grid] = big
        if (new == lab).all():
            return np.where(grid, lab, 0)
        lab = new


def slice_parts(pts, y, band=0.004, cell=0.004):
    """The separate pieces of his cross-section at height y (each an array of points)."""
    sl = pts[np.abs(pts[:, 1] - y) < band]
    if len(sl) == 0:
        return []
    lo = sl[:, [0, 2]].min(axis=0) - 2 * cell
    ij = np.floor((sl[:, [0, 2]] - lo) / cell).astype(int)
    grid = np.zeros(ij.max(axis=0) + 3, bool)
    grid[ij[:, 0], ij[:, 1]] = True
    # One cell grown round each, so a thin gap in his surface's points doesn't split a piece.
    grown = grid.copy()
    grown[1:, :] |= grid[:-1, :]
    grown[:-1, :] |= grid[1:, :]
    grown[:, 1:] |= grid[:, :-1]
    grown[:, :-1] |= grid[:, 1:]
    which = _pieces(grown)[ij[:, 0], ij[:, 1]]
    return [p for p in (sl[which == k] for k in np.unique(which)) if len(p) > 20]


def find_joints(v, tris):
    """His joints by Tripo's names, in Tripo's frame (v: 1.0 tall, feet on 0, facing +X, his
    right at +Z), from his shape: the trunk's at RIG_Y in the middle of his cross-section there;
    each arm traced down his side in slices (the pieces well out from his trunk), the elbow and
    wrist along his shoulder to his finger tips on that line; each leg a line through the middles
    of its cross-sections below his coat, the knee and ankle on it, the hip joint where it reaches
    up to RIG_Y (within HIP_WIDTH of his middle)."""
    pts = surface_points(v, tris)
    mid = float(np.median(pts[:, 2]))
    j = {}
    ysh = RIG_Y["shoulder"]
    at_sh = pts[np.abs(pts[:, 1] - ysh) < 0.006]
    arms = {"R": [], "L": []}
    for y in np.arange(ysh - 0.04, 0.30, -0.01):
        parts = slice_parts(pts, y)
        if len(parts) < 2:
            continue
        trunk = max(parts, key=len)
        t_lo, t_hi = trunk[:, 2].min(), trunk[:, 2].max()
        for p in parts:
            c = p.mean(axis=0)
            if p is trunk or len(p) < 30 or abs(c[2] - mid) < ARM_OUT:
                continue
            if c[2] > t_hi - 0.01:
                arms["R"].append((c, p[np.argmin(p[:, 1])]))
            elif c[2] < t_lo + 0.01:
                arms["L"].append((c, p[np.argmin(p[:, 1])]))
    for side, sgn in (("R", 1.0), ("L", -1.0)):
        out = (at_sh[:, 2] - mid) * sgn
        z = mid + sgn * (np.percentile(out[out > 0], 99.5) - SH_MARGIN)
        near = at_sh[np.abs(at_sh[:, 2] - z) < 0.02]
        sh = np.array([float(np.median((near if len(near) else at_sh)[:, 0])), ysh, z])
        j[side + "_Upperarm"] = sh
        track = arms[side]
        tip = min((t[1] for t in track), key=lambda q: q[1]) if len(track) >= 4 \
            else pts[np.argmax((pts[:, 2] - mid) * sgn)]
        for name, f in (("_Forearm", F_ELBOW), ("_Hand", F_WRIST)):
            q = sh + (tip - sh) * f
            if len(track) >= 4:
                # The arm's own middle at that height.
                line = np.array([t[0] for t in track])
                k = int(np.argmin(np.abs(line[:, 1] - q[1])))
                if abs(line[k, 1] - q[1]) < 0.02:
                    q = np.array([line[k, 0], q[1], line[k, 2]])
            j[side + name] = q
    rows = {"R": [], "L": []}
    for y in np.arange(0.06, 0.42, 0.02):
        legs = sorted((p for p in slice_parts(pts, y) if len(p) > 200), key=len)[-2:]
        if len(legs) == 2:
            for p in legs:
                c = p.mean(axis=0)
                rows["R" if c[2] > mid else "L"].append([y, c[0], c[2]])
    for side, sgn in (("R", 1.0), ("L", -1.0)):
        r = np.array(rows[side])
        fx, fz = np.polyfit(r[:, 0], r[:, 1], 1), np.polyfit(r[:, 0], r[:, 2], 1)
        at = lambda y: np.array([np.polyval(fx, y), y, np.polyval(fz, y)])
        j[side + "_Calf"] = at(RIG_Y["knee"])
        j[side + "_Foot"] = at(RIG_Y["ankle"])
        th = at(RIG_Y["hip"])
        th[2] = mid + sgn * float(np.clip((th[2] - mid) * sgn, *HIP_WIDTH))
        j[side + "_Thigh"] = th
        # Only its direction counts: TripoPerson.bones finds where his boot ends.
        j[side + "_ToeBase"] = j[side + "_Foot"] + np.array([0.03, -0.01, 0.0])
    j["Hip"] = (j["R_Thigh"] + j["L_Thigh"]) / 2
    for name, key in (("NeckTwist01", "neck"), ("Head", "head")):
        parts = slice_parts(pts, RIG_Y[key])
        c = min(parts, key=lambda p: abs(p[:, 2].mean() - mid)).mean(axis=0)
        j[name] = np.array([c[0], RIG_Y[key], c[2]])
    return j


def load_rodin(path):
    """A Rodin man as load_glb gives a Tripo one: turned into Tripo's frame (his front +X, his
    right +Z), feet on 0, 1.0 tall, centred, and his joints found from his shape."""
    pos, nrm, uv, tris, _joints, colour = load_glb(path)
    turn = lambda p: np.stack([p[:, 2], p[:, 1], -p[:, 0]], axis=1)
    v, n = turn(pos), turn(nrm)
    y0, y1 = v[:, 1].min(), v[:, 1].max()
    v = (v - np.array([0.0, y0, 0.0])) / (y1 - y0)
    v -= np.array([(v[:, 0].min() + v[:, 0].max()) / 2, 0.0, (v[:, 2].min() + v[:, 2].max()) / 2])
    return v, n, uv, tris, find_joints(v, tris), colour


def drop_scraps(v, uv, tris, report):
    """v, uv, tris without Tripo's scraps (SCRAP_SHARE, SCRAP_GAP); how many were dropped goes in
    `report`."""
    _u, weld = np.unique(np.round(v / 1e-6).astype(np.int64), axis=0, return_inverse=True)
    t = weld.ravel()[tris]
    lab = np.arange(t.max() + 1)
    edges = np.concatenate([t[:, [0, 1]], t[:, [1, 2]], t[:, [2, 0]]])
    while True:
        low = np.minimum(lab[edges[:, 0]], lab[edges[:, 1]])
        new = lab.copy()
        np.minimum.at(new, edges[:, 0], low)
        np.minimum.at(new, edges[:, 1], low)
        new = new[new]
        if (new == lab).all():
            break
        lab = new
    piece = lab[t[:, 0]]
    ids, counts = np.unique(piece, return_counts=True)
    main = ids[np.argmax(counts)]
    # The biggest piece's points in cells of SCRAP_GAP, to ask what lies near a small piece.
    cell = lambda pts: np.floor(pts / SCRAP_GAP).astype(np.int64)
    near_main = {tuple(c) for c in np.unique(cell(v[np.unique(tris[piece == main])]), axis=0)}
    keep = np.ones(len(tris), bool)
    dropped = 0
    for pid, n in zip(ids, counts):
        if pid == main or n > SCRAP_SHARE * len(tris):
            continue
        pts = v[np.unique(tris[piece == pid])]
        cells = np.unique(cell(pts), axis=0)
        touching = any((c[0] + dx, c[1] + dy, c[2] + dz) in near_main
                       for c in cells for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1))
        if not touching:
            keep[piece == pid] = False
            dropped += int(n)
    if dropped:
        report["scraps_dropped"] = dropped
    if keep.all():
        return v, uv, tris
    used = np.unique(tris[keep])
    remap = np.full(len(v), -1, np.int64)
    remap[used] = np.arange(len(used))
    return v[used], uv[used], remap[tris[keep]]


# --- The man ----------------------------------------------------------------------------------

class TripoPerson(mp.Person):
    def __init__(self, pid, spec, env):
        self.id = pid
        self.env = env
        self.spec = spec
        with open(mp.ANATOMY) as f:
            self.anatomy = json.load(f)
        # A layered man (docs/DESTRUCTION_BRIEF.md part 5): his body is the Tripo model `model`
        # (bare-headed, no coat) and `pieces` {shape: character id} are his garments modelled alone.
        self.model = spec.get("model", pid)
        self.bare = "model" in spec       # bare-headed: his top is his crown, not a hat
        if spec.get("source") == "rodin":
            # A Rodin man (tools/characters/rodin.py): `rodin` is his glb under assets/people/tripo.
            self.model = spec["rodin"]
            pos, nrm, uv, tris, joints, colour = load_rodin(os.path.join(TRIPO, self.model + ".glb"))
        else:
            pos, nrm, uv, tris, joints, colour = load_glb(os.path.join(TRIPO, self.model + ".glb"))
        self.v = to_body_space(pos)
        self.uv = uv
        self.tris = tris
        scraps = {}
        self.v, self.uv, self.tris = drop_scraps(self.v, self.uv, self.tris, scraps)
        self.colour = colour
        self.j = {ours: to_body_space(joints[theirs]) for ours, theirs in JOINTS.items()}
        self.j["hips"] = (self.j["r-upper-leg"] + self.j["l-upper-leg"]) / 2
        y0, y1 = self.v[:, 1].min(), self.v[:, 1].max()
        if "model" in spec:
            # Bare-headed, his crown is his top: the collar is a share of the neck, from its joints.
            self.head_cut = self.j["neck"][1] + (self.j["head"][1] - self.j["neck"][1]) * HEAD_FROM_NECK
        else:
            self.head_cut = y0 + (y1 - y0) * HEAD_FROM
        self.report = {"id": pid, "source": spec.get("source", "tripo"), "whole": True, "model": self.model,
                       "triangles_in": int(len(tris)),
                       "pieces": dict(spec.get("pieces", {}))}
        self.report.update(scraps)
        self.pieces = [Piece(shape, cid, self) for shape, cid in spec.get("pieces", {}).items()]

    def bones(self):
        """The warp: [name, Tripo a, b, our a, b, radius]. Trunk and neck stretched joint to joint
        onto ours (the hitboxes have to sit inside him); the head at his own proportions, scaled
        as the rest of him."""
        m, o = self.j, self.our_joints()
        # His overall scale (widths, the head): his hips to ours. Each bone's length is its own
        # stretch (Tripo's trunk is shorter than ours for his height).
        k = o["hips"][1] / max(m["hips"][1], 1e-6)
        self.scale = k
        self.head_scale = k
        if self.bare:
            # HAIR_M: his shoulders onto ours, all of him above them scaled as one by ku (each
            # bone may carry its girth's scale as a 7th entry), his crown on ours plus his hair.
            m_sh = (m["r-shoulder"] + m["l-shoulder"]) / 2
            o_sh = (o["r-shoulder"] + o["l-shoulder"]) / 2
            ku = (o["crown"][1] + HAIR_M - o_sh[1]) / max(float(self.v[:, 1].max()) - m_sh[1], 1e-6)
            self.head_scale = ku
            o_neck = o_sh + (m["neck"] - m_sh) * ku
            o_head = o_sh + (m["head"] - m_sh) * ku
            head_top = m["head"] + np.array([0.0, 0.16 / ku, 0.0])
            out = [["trunk", m["hips"], m["neck"], o["hips"], o_neck, 0.15],
                   ["neck", m["neck"], m["head"], o_neck, o_head, 0.055, ku],
                   ["head", m["head"], head_top, o_head, o_head + (head_top - m["head"]) * ku, 0.085, ku]]
        else:
            head_top = m["head"] + np.array([0.0, 0.16 / k, 0.0])      # his jaw hinge to his crown, about
            out = [["trunk", m["hips"], m["neck"], o["hips"], o["neck"], 0.15],
                   ["neck", m["neck"], m["head"], o["neck"], o["head"], 0.055],
                   ["head", m["head"], head_top, o["head"], o["head"] + (head_top - m["head"]) * k, 0.085]]
        for side in "rl":
            hand_dir = m[side + "-hand"] - m[side + "-elbow"]
            knuckle = m[side + "-hand"] + hand_dir / np.linalg.norm(hand_dir) * (np.linalg.norm(o[side + "-knuckle"] - o[side + "-hand"]) / k)
            # Tripo's toe joint sits a few centimetres before the ankle; the foot bone it gave
            # stretched his boots to 0.6 m. His toe is where his boot ends: the foot's own length
            # along the toe's direction, from the mesh.
            ankle = m[side + "-ankle"]
            u = m[side + "-toe"] - ankle
            u[1] = 0.0
            u /= max(np.linalg.norm(u), 1e-6)
            foot = self.v[(self.v[:, 1] < ankle[1] + 0.02) & (np.sign(self.v[:, 0]) == np.sign(ankle[0]) if ankle[0] != 0 else True)]
            reach = float(((foot - ankle) @ u).max()) if len(foot) else np.linalg.norm(m[side + "-toe"] - ankle)
            m = dict(m)
            m[side + "-toe"] = ankle + u * max(reach - 0.01, 0.03)
            out += [["upper_arm_" + side, m[side + "-shoulder"], m[side + "-elbow"], o[side + "-shoulder"], o[side + "-elbow"], 0.05],
                    ["forearm_" + side, m[side + "-elbow"], m[side + "-hand"], o[side + "-elbow"], o[side + "-hand"], 0.04],
                    ["hand_" + side, m[side + "-hand"], knuckle, o[side + "-hand"], o[side + "-knuckle"], 0.03],
                    ["thigh_" + side, m[side + "-upper-leg"], m[side + "-knee"], o[side + "-upper-leg"], o[side + "-knee"], 0.075],
                    ["shin_" + side, m[side + "-knee"], m[side + "-ankle"], o[side + "-knee"], o[side + "-ankle"], 0.05],
                    ["foot_" + side, m[side + "-ankle"], m[side + "-toe"], o[side + "-ankle"], o[side + "-toe"], 0.04]]
        return out

    def warp(self):
        bones = self.bones()
        # The pieces are placed against him in his Tripo space, before anything moves.
        for piece in self.pieces:
            piece.place()
        head = self.head_mask(self.v)
        self.v_tripo = self.v.copy()
        self.find_eyes(bones)
        self.v, self.region = self.warp_points(self.v, head, bones)
        self.head = head
        self.fit_joints = {}
        self.report["scale"] = round(float(self.scale), 4)
        self.report["head_scale"] = round(float(self.head_scale), 4)
        self.report["height_m"] = round(float(self.v[:, 1].max()), 3)
        for piece in self.pieces:
            # A hat moves with his head alone: its brim reaches past the head's radius, and the
            # neck's warp (another girth scale since HAIR_M) would bend it.
            piece.v, piece.region = self.warp_points(piece.v, self.head_mask(piece.v), bones,
                                                     only="head" if piece.shape == "hat" else None)

    def find_eyes(self, bones):
        """Where his painted eyes land, in our body space (metres): MediaPipe's two iris centres on
        his mesh (`<model>_face.json`, written by tools/characters/stylise.py in the frame
        load_rodin gives him; a stylised man's are his source's, the irises left where they were)
        carried through the warp with his head. tools/fit_shot.gd aims them at the painting's
        eyes: his head is his own, so the anatomy's eye points aren't where his are drawn."""
        names = [self.model] + ([self.spec["stylise"]["from"]] if "stylise" in self.spec else [])
        paths = [os.path.join(TRIPO, n + "_face.json") for n in names]
        found = [p for p in paths if os.path.exists(p)]
        if not found:
            return
        irises = to_body_space(np.array(json.load(open(found[0]))["points"])[[468, 473]])
        # How far each is from his mesh (it should be on it): a check that the frames agree.
        off = [float(np.linalg.norm(self.v - p, axis=1).min()) for p in irises]
        print("  his eyes from %s, %.1f and %.1f mm off his mesh" % (os.path.basename(found[0]),
              off[0] * self.scale * 1000, off[1] * self.scale * 1000))
        moved, _region = self.warp_points(irises, np.ones(2, dtype=bool), bones, only="head")
        right, left = sorted(moved.tolist(), key=lambda p: -p[0])    # his right at +X
        self.report["eyes"] = {"right": [round(x, 4) for x in right], "left": [round(x, 4) for x in left]}

    def head_mask(self, v):
        """What is head: above the collar, and within HEAD_RADIUS of the neck's axis (the tops of
        the shoulders rise above a bare-headed man's collar line, and they are trunk) or above
        his head joint."""
        above = v[:, 1] > self.head_cut
        n = self.j["neck"]
        near = np.hypot(v[:, 0] - n[0], v[:, 2] - n[2]) < HEAD_RADIUS
        # ... and anything above his head joint (his jaw hinge), however far it sticks out: a
        # bare-headed man's hair (the Kid's tousled hair past HEAD_RADIUS went with his trunk and
        # stood up off him), a hat's wide brim, and a face set further forward of the neck than
        # Tripo's men's (the Rodin stranger's moustache and mouth went with his trunk and tore).
        near |= v[:, 1] > self.j["head"][1]
        return above & near

    def warp_points(self, v, head, bones, only=None):
        """Points in his Tripo space (body orientation) moved onto our skeleton by his bones, and
        the bone each belongs to. The head is everything above the collar; nothing below it is
        head, nothing above the neck joint is trunk. `only`: one bone moves them all."""
        names = [b[0] for b in bones]
        # A bare-headed man's hands are measured out to his fingertips (FINGER_REACH), so fingers
        # that touch his thigh in Tripo's pose go with the hand and are cut at the knuckles (the
        # Kid's left fingertips went with his thigh and stretched a flap of skin to his hand).
        ends = [b[1] + (b[2] - b[1]) * FINGER_REACH if self.bare and b[0].startswith("hand") else b[2] for b in bones]
        d = np.stack([mp.seg_dist(v, b[1], e)[0] - b[5] for b, e in zip(bones, ends)], axis=1)
        if only:
            d[:, :] = 1e3
            d[:, names.index(only)] = 0.0
        d[~head, names.index("head")] += 1.0
        d[head, names.index("trunk")] += 1.0
        d[head, names.index("neck")] += 0.5
        for i, n in enumerate(names):
            if n.startswith(("upper_arm", "forearm", "hand")):
                d[head, i] += 1.0
        w = np.exp(-(d - d.min(1, keepdims=True)) / mp.BLEND)
        w[w < 1e-3] = 0.0
        w /= w.sum(1, keepdims=True)
        region = np.array([bones[i][0] for i in d.argmin(1)])
        out = np.zeros_like(v)
        for i, bone in enumerate(bones):
            name, ma, mb, oa, ob = bone[:5]
            radial = bone[6] if len(bone) > 6 else self.scale
            sel = w[:, i] > 0
            if not sel.any():
                continue
            u = (mb - ma) / np.linalg.norm(mb - ma)
            k = np.linalg.norm(ob - oa) / np.linalg.norm(mb - ma)
            rel = v[sel] - ma
            along = rel @ u
            perp = rel - along[:, None] * u
            if self.bare:
                # Past the bone's ends (a shoulder's top over his neck joint, his seat under his
                # hips) at his own scale, not stretched as the bone is.
                inside = np.clip(along, 0.0, float(np.linalg.norm(mb - ma)))
                local = (inside * k + (along - inside) * radial)[:, None] * u + perp * radial
            else:
                local = along[:, None] * u * k + perp * radial
            moved = local @ mp.rotation_between(u, ob - oa).T + oa
            out[sel] += w[sel, i][:, None] * moved
        return out, region

    def cut_bridges(self):
        """A bare-headed man: drop the triangles that join parts of him that move apart (an arm
        and his trunk below the shoulder, BRIDGE_SHOULDER; an arm and a leg; one leg and the
        other), which Tripo made where they touched in his pose."""
        reg, t = self.region, self.tris
        def chain(r):
            if r in ("trunk", "neck", "head"):
                return "core"
            return ("arm_" if r.startswith(("upper_arm", "forearm", "hand")) else "leg_") + r[-1]
        ch = np.array([chain(r) for r in reg])
        c = ch[t]
        keep = (c[:, 0] == c[:, 1]) & (c[:, 1] == c[:, 2])
        # An arm and his trunk: kept at his shoulder (the arm's points on his upper arm, high on
        # it); a leg and his trunk: kept (his hips). Anything else across parts is dropped.
        for side in "rl":
            sh, el = self.j[side + "-shoulder"], self.j[side + "-elbow"]
            u = el - sh
            down = ((self.v_tripo - sh) @ u) / float(u @ u)
            arm, leg, core = c == "arm_" + side, c == "leg_" + side, c == "core"
            high = np.where(arm, (reg[t] == "upper_arm_" + side) & (down[t] < BRIDGE_SHOULDER), True).all(axis=1)
            keep |= (arm | core).all(axis=1) & arm.any(axis=1) & core.any(axis=1) & high
            keep |= (leg | core).all(axis=1) & leg.any(axis=1) & core.any(axis=1)
        drop = ~keep
        self.report["bridges_cut"] = int(drop.sum())
        self.tris = t[~drop]

    def close_cuts(self):
        """Close the holes cut_bridges left (Tripo's man is watertight, so every hole is a cut).
        A cut leaves one hole a side, its edge running down his side and back up the inside of
        his arm: each run of it on one part (his trunk, or his arm) gets its own fan of triangles
        to the run's middle, so his side is whole under a raised arm and the arm's inside is too,
        each moving with its own part. A cap is one colour, its run's nearest the middle (its own
        copies of the run's points carry that UV, so it doesn't smear across the texture's
        islands)."""
        _u, weld = np.unique(np.round(self.v_tripo / 1e-6).astype(np.int64), axis=0, return_inverse=True)
        weld = weld.ravel()
        first = np.full(weld.max() + 1, -1, np.int64)
        first[weld[::-1]] = np.arange(len(weld))[::-1]          # a vertex for each welded point
        t = weld[self.tris]
        e = np.concatenate([t[:, [0, 1]], t[:, [1, 2]], t[:, [2, 0]]])
        _k, inv, counts = np.unique(np.sort(e, axis=1), axis=0, return_inverse=True, return_counts=True)
        open_e = e[counts[inv.ravel()] == 1]
        # Each open edge reversed, so the caps face the way the faces round them do.
        nxt = {}
        for a, b in open_e:
            nxt.setdefault(int(b), []).append(int(a))
        loops = []
        while nxt:
            start = next(iter(nxt))
            loop, cur = [start], start
            while True:
                outs = nxt.get(cur)
                if not outs:
                    break
                n = outs.pop()
                if not outs:
                    del nxt[cur]
                if n == start:
                    break
                loop.append(n)
                cur = n
            if len(loop) >= 3:
                loops.append(first[np.array(loop)])
        chain = lambda r: "core" if r in ("trunk", "neck", "head") else ("arm_" if r.startswith(("upper_arm", "forearm", "hand")) else "leg_") + r[-1]
        runs = []
        for ids in loops:
            ch = np.array([chain(r) for r in self.region[ids]])
            change = np.where(ch != np.roll(ch, 1))[0]
            if len(change) == 0:
                runs.append(ids)
                continue
            ids, ch = np.roll(ids, -change[0]), np.roll(ch, -change[0])
            cuts = list(np.where(ch[1:] != ch[:-1])[0] + 1) + [len(ids)]
            lo = 0
            for hi in cuts:
                if hi - lo >= 3:
                    runs.append(ids[lo:hi])
                lo = hi
        v, vt, uv, reg, head = list(self.v), list(self.v_tripo), list(self.uv), list(self.region), list(self.head)
        tris = [self.tris]
        for ids in runs:
            mid, mid_t = self.v[ids].mean(axis=0), self.v_tripo[ids].mean(axis=0)
            names, n = np.unique(self.region[ids], return_counts=True)
            part = names[np.argmax(n)]
            colour = self.uv[ids[np.argmin(np.linalg.norm(self.v[ids] - mid, axis=1))]]
            base = len(v)
            for i in ids:
                v.append(self.v[i]); vt.append(self.v_tripo[i]); uv.append(colour); reg.append(self.region[i]); head.append(False)
            v.append(mid); vt.append(mid_t); uv.append(colour); reg.append(part); head.append(False)
            k = len(ids)
            tris.append(np.array([[base + j, base + (j + 1) % k, base + k] for j in range(k)], np.int64))
        self.v, self.v_tripo, self.uv = np.array(v), np.array(vt), np.array(uv)
        self.region, self.head = np.array(reg), np.array(head)
        self.tris = np.concatenate(tris)
        self.report["cuts_closed"] = len(runs)

    def cut_fingers(self):
        """Drop what lies beyond the knuckles along each hand."""
        v = self.v
        o = self.our_joints()
        drop = np.zeros(len(v), bool)
        for side in "rl":
            hand = self.region == "hand_" + side
            u = o[side + "-knuckle"] - o[side + "-hand"]
            reach = np.linalg.norm(u)
            u /= reach
            along = (v[hand] - o[side + "-hand"]) @ u
            ids = np.where(hand)[0]
            drop[ids[along > reach * 0.92]] = True
        keep = ~drop[self.tris].any(axis=1)
        self.report["faces_before_finger_cut"] = int(len(self.tris))
        self.tris = self.tris[keep]
        self.report["faces_after_finger_cut"] = int(len(self.tris))

    def skin_tone(self):
        """His hands' colour: the median of the texels under the backs of his hands (a third of
        the way from wrist to knuckles and on, clear of his cuffs). It goes in his report, and
        HumanBody paints the game's finger parts in it (they came out the default pale peach on
        the Rodin stranger's tanned hands)."""
        o = self.our_joints()
        img = np.asarray(self.colour, dtype=np.float64) / 255.0
        h, w = img.shape[:2]
        found = []
        for side in "rl":
            hand = np.where(self.region == "hand_" + side)[0]
            u = o[side + "-knuckle"] - o[side + "-hand"]
            reach = np.linalg.norm(u)
            along = (self.v[hand] - o[side + "-hand"]) @ (u / reach)
            uv = self.uv[hand[(along > reach * 0.3) & (along < reach * 0.92)]]
            found.append(img[np.clip((uv[:, 1] % 1.0 * h).astype(int), 0, h - 1),
                             np.clip((uv[:, 0] % 1.0 * w).astype(int), 0, w - 1)])
        found = np.concatenate(found)
        if len(found):
            self.report["skin_tone"] = [round(float(x), 3) for x in np.median(found, axis=0)]

    def skirt(self):
        """The coat's skirt hangs from his hips, not his thighs: what's near a thigh bone but
        outside the leg (SKIRT_RADIUS from its axis, or between the legs) above the knee is trunk,
        so it follows the pelvis as the lofted coat does (the thighs may poke through when he
        sits; a flap stretched between the knees is worse)."""
        v = self.v
        o = self.our_joints()
        for side in "rl":
            thigh = self.region == "thigh_" + side
            a, b = o[side + "-upper-leg"], o[side + "-knee"]
            d, t = mp.seg_dist(v, a, b)
            between = (np.abs(v[:, 0]) < BETWEEN_LEGS) & (v[:, 1] > b[1] + 0.02)
            loose = thigh & (t < 0.9) & ((d > SKIRT_RADIUS) | between)
            self.region[loose] = "trunk"
        self.report["skirt_vertices"] = int((self.region == "trunk").sum())

    def run(self):
        self.warp()
        if "model" not in self.spec:
            # A whole man's coat skirt is in his skin; a layered man's body wears trousers, and
            # the rule would hand their legs to his pelvis.
            self.skirt()
        if self.bare:
            self.cut_bridges()
            self.close_cuts()
        self.cut_fingers()
        self.skin_tone()
        self.weights()
        for piece in self.pieces:
            if piece.shape == "coat":
                piece.as_shell()
            if piece.shape == "hat":
                piece.region[:] = "head"
            mp.Person.weights(piece)


class Piece:
    """A garment modelled alone by Tripo (characters.json `item`, unrigged), hung on the body: in
    his Tripo space it is scaled and placed by landmarks (the coat's shoulders onto his, the hat's
    brim onto his head's band), then carried through the body's own warp and skinned by the same
    tables, so it follows his bones as the lofted clothes do, and comes out as its own mesh
    "body_<shape>" with its own texture <id>_<shape>.png: it can be hidden, dropped or shot off."""

    def __init__(self, shape, cid, body):
        self.shape = shape
        self.cid = cid
        self.body = body
        self.env = body.env
        pos, nrm, uv, tris, _joints, colour = load_glb(os.path.join(TRIPO, cid + ".glb"))
        self.v = to_body_space(pos)
        self.uv = uv
        self.tris = tris
        self.colour = colour
        self.region = None
        self.our_joints = body.our_joints
        self.report = body.report.setdefault("piece_" + shape, {})
        self.v, self.uv, self.tris = drop_scraps(self.v, self.uv, self.tris, self.report)
        if shape == "coat":
            self._drop_lining()

    @staticmethod
    def _torso_at(v, y, x0, half, band=0.015):
        """Width and centre (x, z) at this height of what lies within `half` of x0: the torso,
        without the arms or sleeves either side of it."""
        sel = (np.abs(v[:, 1] - y) < band) & (np.abs(v[:, 0] - x0) < half)
        if sel.sum() < 3:
            return 0.0, x0, 0.0
        xs, zs = v[sel, 0], v[sel, 2]
        return float(xs.max() - xs.min()), float((xs.max() + xs.min()) * 0.5), float((zs.max() + zs.min()) * 0.5)

    @staticmethod
    def _depth_at(v, y, band=0.015):
        """Front to back at this height."""
        sel = np.abs(v[:, 1] - y) < band
        return float(v[sel, 2].max() - v[sel, 2].min()) if sel.sum() >= 3 else 0.0

    def _drop_lining(self):
        """A garment modelled alone is a double shell (its lining 1 to 3 cm inside the cloth);
        decimated to a game budget the two surfaces merge into chunks. The faces that look in
        toward the garment's own axis are dropped, leaving the cloth's outside (drawn two-sided,
        so the open front still shows an inside)."""
        v, tris = self.v, self.tris
        c = v[tris].mean(axis=1)
        fn = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
        fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-12
        axis = np.array([np.median(v[:, 0]), 0.0, np.median(v[:, 2])])
        rad = c - axis
        rad[:, 1] = 0.0
        rad /= np.linalg.norm(rad, axis=1, keepdims=True) + 1e-12
        inward = (fn * rad).sum(axis=1) < -0.2
        self.tris = tris[~inward]
        self.report["lining_faces_dropped"] = int(inward.sum())

    def _levelled(self, v):
        """The hat turned so its least spread (a brimmed hat is wider than it is tall) is
        straight up, crown up, about its middle; how far it was tipped goes in self.tilt."""
        c = v.mean(0)
        _u, _s, vt = np.linalg.svd(v - c, full_matrices=False)
        up = vt[2] if vt[2][1] >= 0 else -vt[2]
        self.tilt = float(np.degrees(np.arccos(min(1.0, abs(float(up[1]))))))
        lv = (v - c) @ mp.rotation_between(up, np.array([0.0, 1.0, 0.0])).T + c
        y0, y1 = lv[:, 1].min(), lv[:, 1].max()
        low, high = lv[lv[:, 1] < y0 + (y1 - y0) * 0.2], lv[lv[:, 1] > y1 - (y1 - y0) * 0.2]
        if np.ptp(high[:, 0]) > np.ptp(low[:, 0]):
            lv = (lv - c) * [1.0, -1.0, -1.0] + c      # it was upside down: the brim is the wide end
        return lv

    @staticmethod
    def _width_at(v, y, band=0.015):
        sel = np.abs(v[:, 1] - y) < band
        if sel.sum() < 3:
            return 0.0, 0.0, 0.0
        xs, zs = v[sel, 0], v[sel, 2]
        return xs.max() - xs.min(), (xs.max() + xs.min()) * 0.5, (zs.max() + zs.min()) * 0.5

    def place(self):
        """Scale and move the piece in the body's Tripo space (before the warp)."""
        body, v = self.body, self.v
        y0, y1 = v[:, 1].min(), v[:, 1].max()
        h = y1 - y0
        if self.shape == "hat":
            # Tripo models a hat as its pictures see it, from a little above: tipped (the Kid's
            # 15 degrees). Levelled, its crown (CROWN_SHARE) is found about its own axis, and the
            # crown's foot, the lowest point of its wall, goes round his head at the band, the
            # crown as wide as his head there plus room.
            v = self._levelled(v)
            y0, y1 = v[:, 1].min(), v[:, 1].max()
            h = y1 - y0
            top = v[v[:, 1] > y1 - h * 0.4]
            ax, az = (top[:, 0].min() + top[:, 0].max()) / 2, (top[:, 2].min() + top[:, 2].max()) / 2
            r = np.hypot(v[:, 0] - ax, v[:, 2] - az)
            bands = [r[np.abs(v[:, 1] - y) < h * 0.04].max(initial=0.0) for y in np.linspace(y0, y1, 26)]
            brim_r = max(bands)
            crown_r = max([b for b in bands if 0.0 < b < brim_r * CROWN_SHARE], default=brim_r * 0.55)
            wall = (r > crown_r * 0.9) & (r < crown_r * 1.05)
            foot_y = v[wall, 1].min() if wall.any() else y0
            head = body.v[body.v[:, 1] > body.head_cut]
            jaw, crown = body.j["head"][1], head[:, 1].max()
            band_y = jaw + (crown - jaw) * HAT_BAND
            head_w, cx, cz = self._width_at(head, band_y, 0.01)
            s = head_w * PIECE_MARGIN["hat"] / max(2.0 * crown_r, 1e-6)
            self.v = (v - [ax, foot_y, az]) * s + [cx, band_y, cz]
            self.report.update({"tilt_deg": round(self.tilt, 1), "crown_of_brim": round(float(crown_r / brim_r), 3)})
        else:
            # The coat: its shoulder line onto his shoulders, its width there his at the shoulder
            # joints plus room. The shoulder line is where, coming down from the collar, the coat
            # first reaches most of its width over the top third (the sleeve heads): the widest
            # row is lower, out along the sleeves, and put the collar over his face.
            ys = np.linspace(y1 - h * 0.02, y1 - h * 0.33, 40)
            widths = np.array([self._width_at(v, y, h * 0.02)[0] for y in ys])
            sh_y = ys[int(np.argmax(widths >= widths.max() * 0.7))]
            _w, px, pz = self._width_at(v, sh_y, h * 0.02)
            # Its size from its length: a coat to the knees runs from the collar's top, COAT_COLLAR
            # above the neck joint, to the knees (widths led the sleeves astray: the ghost
            # mannequin's sleeves stand out, and the body's shoulder row carries its arms).
            body_sh = (body.j["r-shoulder"] + body.j["l-shoulder"]) * 0.5
            knee_y = (body.j["r-knee"][1] + body.j["l-knee"][1]) * 0.5
            top_y = body.j["neck"][1] + COAT_COLLAR
            s = (top_y - knee_y) / max(h, 1e-6)
            # Where it sits and how big round: measured on the torso alone (between the shoulders:
            # his arms and hair, and the coat's sleeves, put the centre forward and the depth
            # wrong), at the chest, a little below the shoulder line. The coat's girth is his plus
            # PIECE_MARGIN (sized by length alone it sat inside his skin and only the sleeves showed).
            sw = float(np.linalg.norm(body.j["r-shoulder"] - body.j["l-shoulder"]))
            bx0 = float(body_sh[0])
            chest_dy = 0.08
            _bw, bx, bz = self._torso_at(body.v, body_sh[1] - chest_dy, bx0, sw * 0.5, 0.012)
            _cw, cx, cz = self._torso_at(v, sh_y - chest_dy / s, px, (sw * 0.5) / s * 1.05, h * 0.015)
            self.v = (v - [cx, y1, cz]) * s + [bx, top_y, bz]
            self._sleeves_to_arms()
            # Its girth from his, measured the same way on both once the sleeves follow his arms:
            # the full width at the elbows (sleeves and arms in), the coat's over his by
            # PIECE_MARGIN, scaled about the torso in x and z. The coat was modelled at an ordinary
            # man's girth and this man is broad: sized by length alone it sat inside him.
            el_y = (body.j["r-elbow"][1] + body.j["l-elbow"][1]) * 0.5
            bw_full = self._width_at(body.v, el_y, 0.012)[0]
            cw_full = self._width_at(self.v, el_y, 0.012)[0]
            g = bw_full * PIECE_MARGIN[self.shape] / cw_full if cw_full > 0 and bw_full > 0 else 1.0
            self.v[:, 0] = bx + (self.v[:, 0] - bx) * g
            self.v[:, 2] = bz + (self.v[:, 2] - bz) * g
            body.report.setdefault("piece_girth", {})[self.shape] = round(float(g), 3)
            body.report.setdefault("piece_landmarks", {})[self.shape] = {
                "shoulder_line_from_top": round(float((y1 - sh_y) / h), 3), "length_m": round(float(h * s * body.scale), 3)}
        body.report.setdefault("piece_scale", {})[self.shape] = round(float(s), 3)

    def as_shell(self):
        """The coat as a shell of his own body (in our space, after the warp): his torso, arms and
        legs to the knees pushed out along their normals by COAT_OFFSET_M, so it fits him by
        construction and is skinned as he is; what it looks like comes from the Tripo coat, placed
        over him as above: each shell vertex takes the UV of the nearest point of that coat, and a
        face more than COAT_GAP_M from any of it (the open front, the shirt and vest it shows) is
        cut away, which gives the coat its opening and its hem. The registered Tripo coat itself
        never fitted him: a double shell at an ordinary man's girth on a broad man, torn by every
        correction."""
        from scipy.spatial import cKDTree
        body = self.body
        bv, tris, reg = body.v, body.tris, body.region
        fn = np.cross(bv[tris[:, 1]] - bv[tris[:, 0]], bv[tris[:, 2]] - bv[tris[:, 0]])
        vn = np.zeros_like(bv)
        for k in range(3):
            np.add.at(vn, tris[:, k], fn)
        vn /= np.linalg.norm(vn, axis=1, keepdims=True) + 1e-12
        covered = np.isin(reg, ["trunk", "neck", "upper_arm_r", "upper_arm_l", "forearm_r", "forearm_l", "thigh_r", "thigh_l"])
        # Below the hips the shell hangs looser (a skirt, not trousers); below the knees nothing.
        o = body.our_joints()
        hip_y = o["hips"][1]
        knee_y = (o["r-knee"][1] + o["l-knee"][1]) * 0.5
        covered &= bv[:, 1] > knee_y + 0.02
        offset = np.where(bv[:, 1] < hip_y, COAT_SKIRT_OFFSET_M, COAT_OFFSET_M)
        shell = bv + vn * offset[:, None]
        # The look from the Tripo coat: nearest point's UV; too far from any of it = no cloth.
        tree = cKDTree(self.v)
        dist, idx = tree.query(shell)
        covered &= dist < COAT_GAP_M
        keep_tri = covered[tris].all(axis=1)
        used = np.unique(tris[keep_tri])
        new_index = -np.ones(len(bv), dtype=np.int64)
        new_index[used] = np.arange(len(used))
        self.tris = new_index[tris[keep_tri]]
        self.v = shell[used]
        self.uv = self.uv[idx[used]]
        region = reg[used].copy()
        # The skirt hangs from the hips, as the lofted coat's does.
        region[np.isin(region, ["thigh_r", "thigh_l"])] = "trunk"
        self.region = region
        self.report["shell_vertices"] = int(len(used))
        self.report["shell_faces"] = int(len(self.tris))

    def _clear_body(self):
        """Whatever of the piece lies inside him, or nearer his skin than PIECE_CLEARANCE, is pushed
        out along his skin's normal to that clearance: no registration by landmarks is exact, and
        cloth under the skin is cloth the game never draws. The far skirt, more than PIECE_REACH
        from any of him, hangs as it is."""
        from scipy.spatial import cKDTree
        body, v = self.body, self.v
        bv, tris = body.v, body.tris
        fn = np.cross(bv[tris[:, 1]] - bv[tris[:, 0]], bv[tris[:, 2]] - bv[tris[:, 0]])
        vn = np.zeros_like(bv)
        for k in range(3):
            np.add.at(vn, tris[:, k], fn)
        vn /= np.linalg.norm(vn, axis=1, keepdims=True) + 1e-12
        # His skin on a grid (every vertex is more than the fit needs and slow to search).
        keep = np.unique((bv / 0.004).round().astype(np.int64), axis=0, return_index=True)[1]
        tree = cKDTree(bv[keep])
        dist, idx = tree.query(v, distance_upper_bound=PIECE_REACH)
        near = np.isfinite(dist)
        b = bv[keep][idx[near]]
        n = vn[keep][idx[near]]
        d = ((v[near] - b) * n).sum(axis=1)
        push = np.clip(PIECE_CLEARANCE - d, 0.0, None)
        move = np.zeros_like(v)
        move[near] = n * push[:, None]
        # Smoothed over the cloth (each vertex takes the mean of its neighbours' moves, a few
        # times), so the shell moves as cloth: pushed one by one along differing normals, the
        # vertices tore apart.
        from scipy.sparse import coo_matrix
        tris = self.tris
        i = np.concatenate([tris[:, 0], tris[:, 1], tris[:, 2], tris[:, 1], tris[:, 2], tris[:, 0]])
        j = np.concatenate([tris[:, 1], tris[:, 2], tris[:, 0], tris[:, 0], tris[:, 1], tris[:, 2]])
        adj = coo_matrix((np.ones(len(i)), (i, j)), shape=(len(v), len(v))).tocsr()
        degree = np.asarray(adj.sum(axis=1)).ravel()
        degree[degree == 0] = 1.0
        for _ in range(PIECE_SMOOTH):
            move = (adj @ move) / degree[:, None]
        v += move
        self.v = v
        self.report["pushed_out"] = int((push > 0).sum())

    def _sleeves_to_arms(self):
        """The painter hangs a coat's sleeves at its sides however it is asked; the body stands in
        an A-pose. Each sleeve (what lies outside the shoulders below the shoulder line) is turned
        about its shoulder joint, in the body's front plane, from the way it hangs to the way his
        arm goes, so the warp's arm bones carry it."""
        body, v = self.body, self.v
        for side in "rl":
            sh, el = body.j[side + "-shoulder"], body.j[side + "-elbow"]
            sign = 1.0 if side == "r" else -1.0
            # The sleeve: beyond the shoulder outward, from the shoulder line down to the hem's
            # level of the cuff (the coat's lower half is the skirt: left alone).
            sel = (sign * (v[:, 0] - sh[0]) > 0.02) & (v[:, 1] < sh[1] + 0.03) & (v[:, 1] > sh[1] - 0.45)
            if sel.sum() < 50:
                continue
            # Its direction: a line through its cross-sections' centres, by height.
            ys = v[sel, 1]
            lo, hi = np.percentile(ys, [10, 85])
            a = v[sel][ys > hi - 0.03].mean(axis=0)
            b = v[sel][ys < lo + 0.03].mean(axis=0)
            have = b - a
            want = el - sh
            have[2] = 0.0
            want[2] = 0.0
            ang = np.arctan2(want[1], want[0]) - np.arctan2(have[1], have[0])
            c, s_ = np.cos(ang), np.sin(ang)
            rel = v[sel] - sh
            x, y = rel[:, 0] * c - rel[:, 1] * s_, rel[:, 0] * s_ + rel[:, 1] * c
            # Ease the turn in over the first 6 cm below the shoulder line, so the sleeve head stays
            # on the shoulder.
            t = np.clip((sh[1] + 0.03 - v[sel, 1]) / 0.06, 0.0, 1.0)
            v[sel, 0] = sh[0] + (1 - t) * rel[:, 0] + t * x
            v[sel, 1] = sh[1] + (1 - t) * rel[:, 1] + t * y
            body.report.setdefault("sleeve_turn_deg", {})[side] = round(float(np.degrees(ang)), 1)
        self.v = v


# --- Textures -----------------------------------------------------------------------------------

def squares(colour, out_path, square=SQUARE_TEXELS):
    """The texture in squares: each `square`×`square` block one colour (its average), one texel
    a square in the written image."""
    a = np.asarray(colour.convert("RGB"), dtype=np.float64)
    h, w = a.shape[:2]
    hs, ws = (h // square) * square, (w // square) * square
    blocks = a[:hs, :ws].reshape(hs // square, square, ws // square, square, 3).mean(axis=(1, 3))
    Image.fromarray(np.clip(blocks, 0, 255).astype(np.uint8)).save(out_path)
    return blocks.shape[1], blocks.shape[0]


# --- Blender --------------------------------------------------------------------------------------

def build_blender(person):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    env = person.env
    bones = env["bones"]
    arm_data = bpy.data.armatures.new("Skeleton")
    arm = bpy.data.objects.new("Skeleton", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for b in bones:
        c = np.array(env["segments"][b]["center"])
        eb = arm_data.edit_bones.new(b)
        eb.head = mp.to_blender(c)
        eb.tail = mp.to_blender(c + np.array([0, 0.05, 0]))
    for b in bones:
        parent = env["segments"][b]["parent"]
        if parent:
            arm_data.edit_bones[b].parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    person.arm = arm

    def make(name, tris, budget, src=person):
        used = np.unique(tris)
        new_index = {int(old): i for i, old in enumerate(used)}
        mesh = bpy.data.meshes.new("body_" + name)
        mesh.from_pydata([mp.to_blender(src.v[i]) for i in used], [], [[new_index[int(i)] for i in t] for t in tris])
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                u, vv = src.uv[used[mesh.loops[li].vertex_index]]
                uv_layer.data[li].uv = (u, 1.0 - vv)   # glTF's v runs down; the export flips it back
        for poly in mesh.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new("body_" + name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for bname in bones:
            obj.vertex_groups.new(name=bname)
        for new_i, old_i in enumerate(used):
            for b, w in enumerate(src.W[old_i]):
                if w > 0.001:
                    obj.vertex_groups[b].add([new_i], float(w), "REPLACE")
        # Welded first: Tripo's atlas cuts him into hundreds of UV islands, and the points along
        # every seam came in twice; decimated apart, the two sides stopped meeting and every seam
        # opened into a crack (the Kid's skin had ~3,900 open edges, the stranger's ~4,800). One
        # point a place, the UVs stay on the face corners.
        import bmesh
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
        bm.to_mesh(mesh)
        bm.free()
        tris_now = len(mesh.polygons)
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = min(1.0, budget / max(tris_now, 1))
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="decimate")
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
        return obj

    head_tris = person.head[person.tris].all(axis=1)
    # people.json `tris` can give a man more (a Rodin man comes clean at ~33k: cut down to the
    # old budget he went lumpy, as the Tripo men did).
    budget = person.spec.get("tris", {})
    head = make("head", person.tris[head_tris], budget.get("head", HEAD_TRIS))
    skin = make("skin", person.tris[~head_tris], budget.get("skin", TRI_BUDGET))
    made = [skin, head]
    for piece in person.pieces:
        made.append(make(piece.shape, piece.tris, PIECE_TRIS.get(piece.shape, 1500), piece))
    person.report["triangles"] = {o.name.split("_", 1)[1]: sum(len(p.vertices) - 2 for p in o.data.polygons)
                                  for o in made}


def export(person):
    path = os.path.join(OUT, person.id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    json.dump(person.report, open(os.path.join(OUT, person.id + ".json"), "w"), indent=1)
    print("wrote", path, person.report.get("triangles"))


def main():
    global SMOOTH
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    SMOOTH = "--smooth" in args
    only = None
    for a in args:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
    env = json.load(open(mp.ENVELOPE))
    people = json.load(open(os.path.join(OUT, "people.json")))["people"]
    for pid, spec in people.items():
        if spec.get("source") not in ("tripo", "rodin") or (only and pid != only):
            continue
        body = spec["rodin"] if spec.get("source") == "rodin" else spec.get("model", pid)
        missing = [m for m in [body] + list(spec.get("pieces", {}).values())
                   if not os.path.exists(os.path.join(TRIPO, m + ".glb"))]
        if missing:
            print("no Tripo model for", pid, ":", ", ".join(missing))
            continue
        p = TripoPerson(pid, spec, env)
        p.run()
        for piece in p.pieces:
            # Each piece's own texture, in the same squares (Tripo's colour: the pieces aren't
            # repainted in the style yet).
            squares(piece.colour, os.path.join(OUT, "%s_%s%s.png" % (pid, piece.shape, "_smooth" if SMOOTH else "")),
                    1 if SMOOTH else SQUARE_TEXELS)
        # His texture: the head repainted in the style where it has been (head_paint.py works on a
        # glb, so a layered man's repaint is his model's, <model>_color.png).
        named = pid if os.path.exists(os.path.join(TRIPO, pid + "_color.png")) else spec.get("model", pid)
        repainted = os.path.join(TRIPO, named + "_color.png")
        if SMOOTH:
            # The "quantise once" set: the smooth repaint (head_paint.py --smooth) if there is one,
            # no squares, written beside the real textures as <id>_skin_smooth.png / _head_smooth.png
            # (PeopleBodies.smooth_paint takes them); the glb is unchanged, so no export.
            smooth_paint = os.path.join(TRIPO, named + "_color_smooth.png")
            src = smooth_paint if os.path.exists(smooth_paint) else repainted
            colour = Image.open(src).convert("RGB") if os.path.exists(src) else p.colour
            squares(colour, os.path.join(OUT, pid + "_skin_smooth.png"), 1)
            squares(colour, os.path.join(OUT, pid + "_head_smooth.png"), 1)
            print("wrote", pid, "smooth textures from", os.path.basename(src) if os.path.exists(src) else "tripo")
            continue
        colour = Image.open(repainted).convert("RGB") if os.path.exists(repainted) else p.colour
        # A repaint smaller than his model's texture (head_paint.py bakes at most 2048 a side; a
        # Rodin man's is 4096) is already in squares that size: it keeps its texels.
        sq = max(1, SQUARE_TEXELS * colour.width // p.colour.width)
        size = squares(colour, os.path.join(OUT, pid + "_skin.png"), sq)
        squares(colour, os.path.join(OUT, pid + "_head.png"), sq)
        p.report["texture"] = {"from": os.path.basename(repainted) if os.path.exists(repainted) else "tripo", "size": size,
                               "square_texels": sq}
        if bpy is None:
            print("no bpy: fitted", pid, "but not exported")
            json.dump(p.report, open(os.path.join(OUT, pid + ".json"), "w"), indent=1)
            continue
        build_blender(p)
        export(p)


if __name__ == "__main__":
    main()
