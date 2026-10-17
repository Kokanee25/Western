"""Fit a Tripo man (tools/characters/: assets/people/tripo/<id>.glb, rigged by Tripo) to the game's
skeleton and hitboxes, as make_people.py fits MakeHuman's base mesh.

    ~/bpyenv/bin/python tools/blender/fit_tripo.py [--only=stranger]     (bpy: pip install bpy==5.0.1)
    blender -b --python tools/blender/fit_tripo.py -- [--only=stranger]

For each person in assets/people/people.json with "source": "tripo":
  1. His mesh (one skin: body, clothes, hat and hair as Tripo made them) into our body space
     (metres, facing -Z, feet at the origin, his right +X): Tripo's man faces +X at 1.0 tall.
  2. Warped onto our skeleton (assets/people/envelope.json): each limb bone is moved, turned and
     stretched from Tripo's joints (its rig's bind pose) to ours, blended at the joints, as
     make_people.Person.warp does; the head keeps his own proportions, placed by his drawn eyes
     onto the anatomy's when his face has been found (EYES_RULE). No envelope fit: he wears a
     coat, and his widths are his own (the hitboxes sit inside him).
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
# EYES_RULE: a whole man whose face has been found (MediaPipe's landmarks on his mesh,
# `<model>_face.json`): his shoulders onto ours and all of him above them scaled as one, so his
# drawn eyes come to the anatomy's eyes' height, then his head set back or forward (a shear up his
# neck) till they are the anatomy's eyes. Joint to joint, Tripo's head joint (half way up his neck)
# went onto ours (at the chin) and the stylised stranger's face sat 12 cm over his head's hitbox,
# 8 cm before it: a shot through his face missed his head. IRISES: the landmarks' two iris centres.
IRISES = [468, 473]
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
PIECE_TRIS = {"coat": 2600, "hat": 700, "trousers": 1600}
# A twin piece keeps its own shape (lapels, pockets, the skirt's fall): more triangles.
TWIN_TRIS = {"coat": 6000, "trousers": 8000, "vest": 5000, "shirt": 5000}
# A layered man's garments, innermost first: each tucked under every one outside it (tuck_layers).
LAYERS = ["shirt", "trousers", "vest", "coat"]
FINGER_TRIS = 140     # a finger bone's piece (own_fingers)
WRIST_CUT = 0.004     # metres short of his wrist joint: his arm's skin ends (makehuman_hands)
WRIST_BLEND = 0.03    # metres past it: the new palm's wrist eases from his arm to its own shape
ARM_TAPER = 0.07      # metres up his forearm over which it tapers in to meet the new wrist
WRIST_SWELL = 1.3     # the meeting ring: this times MakeHuman's wrist (never wider than his arm)
HAND_SQUARE = 0.06    # of his skin's texture a side: each MakeHuman hand's paint (~245 px of 4096)
BRIDGE = 0.003         # metres between his arm's cut and the hand's: the stitched strip
SEAM_BLEND = 0.02     # metres down the hand over which it eases from his arm's edge's weights
HAND_SQUARE_MAX = 0.09  # ... or as big as this, where his texture has the room (skinned_hands)
PIECE_MARGIN = {"coat": 1.06, "hat": 1.05}
# The hat's brim sits this share of the way up his head from the jaw joint to the crown.
HAT_BAND = 0.72
# A coat's collar stands this far above the neck joint (Tripo units, of his height: ~6 cm).
COAT_COLLAR = 0.032
# A piece is pushed out of his skin to this clearance, where it lies within this reach of him
# (Tripo units: ~2 cm and ~11 cm on him).
PIECE_CLEARANCE = 0.012
UNDER_SHIRT_LIGHT = 70.0   # percentile of his shirt's lightness: his neck under it painted the median above it ...
UNDER_SHIRT_NECK = 0.03    # ... from this far under his neck joint up ...
UNDER_NECK_R = 0.08        # ... and within this of the neck joint's axis (the joint sits at his shoulder line: without this his shoulders were "neck")
UNDER_REACH = 0.10         # metres out from his skin a garment lies to be the one over it (paint_under_garments)
BROADEN_LOW = 0.12     # metres under his shoulders where `shoulders` stops widening his trunk ...
BROADEN_FULL = 0.02    # ... and where it widens it in full (0.25 and 0.06 widened his chest: "barrel chested")
TUCK_M = 0.012         # his skin this far under a twin garment's surface (tuck_skin)
TUCK_MAX_M = 0.05
TUCK_SPREAD = 3        # neighbour steps a tuck is eased over (tuck_under)
TUCK_SHIRT_M = 0.025   # his skin this far under his garments when he wears a whole shirt (tuck_skin)
SLEEVE_IN = 0.015      # metres: his arm at least this far inside a shirt's sleeve (_arms_in_sleeves) ...
SLEEVE_MIN = 0.5       # ... but never thinner than this much of itself
ARMHOLE_R = 0.12       # metres from his upper arm's bone: a vest or shirt under a coat is dropped there
COVER_REACH = 0.08     # metres: a vest or shirt triangle with the coat this near straight outside it is under it ...
COVER_SIDE_X = 0.08    # ... and, this far from his middle (his sides, not the opening), with the coat this near in any direction
ARMPIT_DROP = 0.08     # metres below his shoulder joints: his armpit (sleeve and side cut apart below it)
COMB_T = 0.4           # of the way down his upper arm: the shirt's side left in a comb by that cut is dropped there ...
COMB_R = 0.02          # ... within SLEEVE_R plus this of the arm's bone (his skin under it is painted the shirt's colour)
SLEEVE_INNER = 0.02    # metres inside his arm's bone a sleeve still reaches (weights_from_skin)
SLEEVE_RINGS = 12      # bands along an arm a sleeve is kept outside it by (_sleeves_round_arms) ...
SLEEVE_ANGLES = 16     # ... and angles round it
SLEEVE_ROOM = 0.003    # metres between his arm's skin and his sleeve at the least
SLEEVE_ARM_MAX = 0.065 # metres from the bone: skin further out than this isn't his arm's
SLEEVE_R = 0.09        # metres from his arm's bone: a coat's or shirt's point there is its sleeve (weights_from_skin) ...
COAT_SIDES_CUT = False # a coat's sleeves cut from its sides and its body off his arms, as a shirt's: off (Sean, 2026-10-17: it split Rodin's fused
                       # sleeve-and-side, the upper sleeves went skinny and the side cloth sat where the arm hung); the wing stays
TAILS_BELOW = 0.05     # metres under his hip joints and below: a coat's skirt behind him hangs from his pelvis alone (tails_on_pelvis) ...
TAILS_FULL = 50.0      # ... in full within this many degrees of straight behind ...
TAILS_NONE = 80.0      # ... and not at all beyond this (its front and sides follow his thighs: on his lap when he sits)
SLEEVE_FROM = 0.12     # ... from this share of the way from his shoulder to his wrist
COLLAR_TOP_SHARE = 0.91   # of the envelope's head top (1.795 m): his collar's top (neck_ring's ring, 1.61 m, and
                          # stand_collar's 2 cm above it); skin below it is under a shirt
TRUNK_IN = 0.85        # his torso this much of its depth under a shirt (_trunk_in) ...
TRUNK_IN_X = 0.72      # ... and this much of its width
SLEEVE_SPARE = 0.03    # the share of his arm let stay nearer the sleeve than SLEEVE_IN (stray rays)
SLEEVE_FADE = 0.015     # metres above his wrist's cut over which they come back to all of it
PIECE_REACH = 0.06
CUFF_PAST = 0.01       # metres: a sleeve ends this far past the cut his hand joins at (clear_hands)
HAND_LINE = 0.015      # metres: his hand's points this near a skirt point's line behind it count
HAND_FOLD_STEPS = 12   # smoothing steps the skirt's move spreads by round his hand (~a few cm)
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
CLOTH_MEDIAN = 3       # texels: a twin piece's cloth smoothed by a median this wide (paint_cloth) ...
CLOTH_BLUR = 0.0       # ... and a blur this wide (7 and 1.2 kept 30-45% of the coat's fine detail: too soft)
MOTTLE_FINE = 3.0      # texels of a 1024 texture: the blotches people.json `cloth.<shape>.mottle` flattens are
MOTTLE_WIDE = 28.0     # between these two sizes
KEEP_WHITE = (130.0, 170.0)  # luma: cloth.<shape>.keep_ends leaves texels lighter than these untoned (fading in) ...
COAT_SIDE_X = 0.10     # metres from his middle: a white texel on a coat there is Rodin's shirt painted into the fused
COAT_SIDE_WHITE = 140.0  # sleeve-and-side (luma over this, and ...
COAT_SIDE_SPREAD = 70.0  # ... its channels within this of each other: cream; the wool's highlights are browner), not the
                         # shirt seen in its opening: painted its wool (paint_cloth)
KEEP_BLACK = (18.0, 32.0)    # ... and darker than these (the coat's painted shirt front and tie)
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
# A Rodin man's shoulders are found from the top of his shoulder (shoulder_top): the joint is
# SH_TOP under it (Tripo's rigs put theirs 0.030-0.043 under, the stranger, the Kid and the
# bare-headed stranger), within SH_RANGE of RIG_Y's. RIG_Y's share put the stylised stranger's 7 cm
# under his own (his hat is lower than Tripo's men's, his shoulders higher): the trunk's warp then
# lifted his shoulders and head 12 cm over the hitboxes. His neck and head joints keep Tripo's
# spacing from the shoulder.
SH_TOP = 0.036
SH_RANGE = (-0.02, 0.05)
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
    right at +Z), from his shape: the shoulders SH_TOP under the tops of his shoulders, the neck
    and head over them at Tripo's spacing; each arm traced down his side in slices (the pieces well out from his trunk), the elbow and
    wrist along his shoulder to his finger tips on that line; each leg a line through the middles
    of its cross-sections below his coat, the knee and ankle on it, the hip joint where it reaches
    up to RIG_Y (within HIP_WIDTH of his middle)."""
    pts = surface_points(v, tris)
    mid = float(np.median(pts[:, 2]))
    j = {}
    ysh = RIG_Y["shoulder"]
    for _ in range(4):
        # The shoulder joints' height: SH_TOP under the tops of his shoulders, measured over where
        # the joints are at this height (they move out as it drops: the arms hang out).
        at_sh = pts[np.abs(pts[:, 1] - ysh) < 0.006]
        tops = []
        for sgn in (1.0, -1.0):
            out = (at_sh[:, 2] - mid) * sgn
            tops.append(shoulder_top(pts, mid + sgn * (np.percentile(out[out > 0], 99.5) - SH_MARGIN), ysh))
        y = float(np.clip(np.mean(tops) - SH_TOP, RIG_Y["shoulder"] + SH_RANGE[0], RIG_Y["shoulder"] + SH_RANGE[1]))
        if abs(y - ysh) < 0.001:
            break
        ysh = y
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
    # The neck and head joints over the middle of his shoulders, as Tripo's rigs have them (the
    # middle of his cross-section there is pulled back by a coat's collar and his hair: the
    # stylised stranger's sat 6 cm behind his shoulders and leant his trunk back).
    sh = (j["R_Upperarm"] + j["L_Upperarm"]) / 2
    for name, key in (("NeckTwist01", "neck"), ("Head", "head")):
        j[name] = np.array([sh[0], ysh + RIG_Y[key] - RIG_Y["shoulder"], sh[2]])
    return j


def shoulder_top(pts, z, y0, reach=0.12, step=0.003, width=0.01):
    """The top of his shoulder over sideways place z: from y0 up, the last height his surface
    reaches without a gap (a hat's brim further up, over his shoulder, is past the gap)."""
    col = pts[(np.abs(pts[:, 2] - z) < width) & (pts[:, 1] >= y0)]
    filled = np.zeros(int(reach / step) + 1, bool)
    b = np.floor((col[:, 1] - y0) / step).astype(int)
    filled[b[b < len(filled)]] = True
    return y0 + step * (int(np.argmin(filled)) if not filled.all() else len(filled))


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
        # How much more light his drawn whites take (people.json `eye_gain`; the art session's
        # body_skin reads it from this report through PeopleBodies: Sean wants the eyes clear and
        # bright, past the painting's style).
        if "eye_gain" in spec:
            self.report["eye_gain"] = float(spec["eye_gain"])
        # His drawn eyes, in his Tripo space (body orientation), when his face has been found
        # (EYES_RULE): a whole man's head is then placed by them.
        self.face = self.face_points()
        self.by_eyes = self.face is not None and not self.bare
        self.pieces = [Piece(shape, cid, self) for shape, cid in spec.get("pieces", {}).items()]

    def bones(self):
        """The warp: [name, Tripo a, b, our a, b, radius]. Trunk and neck stretched joint to joint
        onto ours (the hitboxes have to sit inside him); the head at his own proportions, scaled
        as the rest of him. A bare-headed man (HAIR_M) and a man whose face has been found
        (EYES_RULE) have his shoulders onto ours and all of him above them scaled as one."""
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
        elif self.by_eyes:
            # EYES_RULE: his shoulders onto ours and all of him above them scaled as one by ku, so
            # his drawn eyes come to our eyes' height; then his head set forward or back (a shear
            # up his neck, the 8th entry) till they are our eyes.
            m_sh = (m["r-shoulder"] + m["l-shoulder"]) / 2
            o_sh = (o["r-shoulder"] + o["l-shoulder"]) / 2
            m_eye = self.face[IRISES].mean(axis=0)
            o_eye = self.anatomy_eyes().mean(axis=0)
            ku = (o_eye[1] - o_sh[1]) / max(m_eye[1] - m_sh[1], 1e-6)
            self.head_scale = ku
            o_neck = o_sh + (m["neck"] - m_sh) * ku
            o_head = o_sh + (m["head"] - m_sh) * ku
            shift = o_eye - (o_sh + (m_eye - m_sh) * ku)
            shift[1] = 0.0
            self.report["head_shift_m"] = [round(float(x), 4) for x in shift]
            head_top = m["head"] + np.array([0.0, 0.16 / ku, 0.0])
            out = [["trunk", m["hips"], m["neck"], o["hips"], o_neck, 0.15],
                   ["neck", m["neck"], m["head"], o_neck, o_head, 0.055, ku, shift],
                   ["head", m["head"], head_top, o_head + shift, o_head + shift + (head_top - m["head"]) * ku, 0.085, ku]]
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
        k = float(self.spec.get("shoulders", 1.0))
        if k != 1.0:
            self.v = self.broaden(self.v, self.region, k, report=True)
            for piece in self.pieces:
                if piece.shape != "hat":
                    piece.v = self.broaden(piece.v, piece.region, k)

    def face_points(self):
        """MediaPipe's face landmarks on his mesh (`<model>_face.json`, written by
        tools/characters/stylise.py in the frame load_rodin gives him; a stylised man's are his
        source's, the irises left where they were), in his Tripo space (body orientation), or None."""
        names = [self.model] + ([self.spec["stylise"]["from"]] if "stylise" in self.spec else [])
        found = [p for p in (os.path.join(TRIPO, n + "_face.json") for n in names) if os.path.exists(p)]
        if not found:
            return None
        pts = to_body_space(np.array(json.load(open(found[0]))["points"]))
        # How far his irises are from his mesh (they should be on it; mm on a 1.8 m man): a check
        # that the frames agree.
        off = [float(np.linalg.norm(self.v - q, axis=1).min()) for q in pts[IRISES]]
        print("  his face from %s, irises %.1f and %.1f mm off his mesh" % (
            os.path.basename(found[0]), off[0] * 1800, off[1] * 1800))
        return pts

    def anatomy_eyes(self):
        """The anatomy's two eyes (their centres, metres in our body space), his right first."""
        at = {s["id"]: np.array(s["sphere"][0], float) for s in self.anatomy["structures"] if s["id"] in ("eye_r", "eye_l")}
        return np.array([at["eye_r"], at["eye_l"]])

    def find_eyes(self, bones):
        """Where his drawn eyes land, in our body space (metres), carried through the warp with his
        head: on the anatomy's eyes under EYES_RULE (the report says how far off), and
        tools/fit_shot.gd aims them at the painting's eyes."""
        if self.face is None:
            return
        moved, _region = self.warp_points(self.face[IRISES], np.ones(2, dtype=bool), bones, only="head")
        right, left = sorted(moved.tolist(), key=lambda p: -p[0])    # his right at +X
        self.report["eyes"] = {"right": [round(x, 4) for x in right], "left": [round(x, 4) for x in left]}
        off = np.linalg.norm(np.array([right, left]) - self.anatomy_eyes(), axis=1)
        self.report["eyes_off_anatomy_m"] = [round(float(x), 4) for x in off]
        print("  his eyes %.1f and %.1f cm from the anatomy's" % (off[0] * 100, off[1] * 100))

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
            if self.bare or self.by_eyes:
                # Past the bone's ends (a shoulder's top over his neck joint, his seat under his
                # hips) at his own scale, not stretched as the bone is.
                inside = np.clip(along, 0.0, float(np.linalg.norm(mb - ma)))
                local = (inside * k + (along - inside) * radial)[:, None] * u + perp * radial
            else:
                local = along[:, None] * u * k + perp * radial
            moved = local @ mp.rotation_between(u, ob - oa).T + oa
            if len(bone) > 7:
                # A shear up the bone (EYES_RULE's neck): none at its start, all of it at its end.
                moved += np.clip(along / np.linalg.norm(mb - ma), 0.0, 1.0)[:, None] * bone[7]
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

    def broaden(self, v, region, k, report=False):
        """His shoulders broader by k (people.json `shoulders`; Sean, 2026-10-15: "shoulders
        aren't broad enough") without moving a joint (the hitboxes are the anatomy's): each arm
        moved out by D at the shoulder, fading to nothing at the wrist (his hands stay on their
        bones, where the game's fingers are), and his upper chest and back stretched out to meet
        them, from his neck's side to the shoulder joint, fading below the armpit. D is half of
        (k - 1) times his width across the shoulders."""
        o = self.our_joints()
        sh_y = (o["r-shoulder"][1] + o["l-shoulder"][1]) * 0.5
        sh_x = abs(o["r-shoulder"][0] - o["l-shoulder"][0]) * 0.5
        row = np.abs(self.v[:, 1] - (sh_y - 0.05)) < 0.015
        width = float(np.ptp(self.v[row, 0])) if row.any() else 2 * sh_x + 0.15
        D = (k - 1.0) * width * 0.5
        out = v.copy()
        reg = np.asarray(region).astype(str)
        for side in "rl":
            a, b = o[side + "-shoulder"], o[side + "-hand"]
            sx = np.sign(a[0])
            arm = np.isin(reg, ["upper_arm_" + side, "forearm_" + side, "hand_" + side])
            t = np.clip(((v - a) @ (b - a)) / max(float((b - a) @ (b - a)), 1e-9), 0, 1)
            out[arm, 0] += sx * D * (1 - t[arm])
        body = np.isin(reg, ["trunk", "neck"])
        ax = np.abs(v[:, 0])
        across = np.clip((ax - 0.06) / max(sh_x - 0.06, 1e-6), 0, 1)
        across = across * across * (3 - 2 * across)
        down = np.clip((v[:, 1] - (sh_y - BROADEN_LOW)) / (BROADEN_LOW - BROADEN_FULL), 0, 1)
        down = down * down * (3 - 2 * down)
        out[body, 0] += np.sign(v[body, 0]) * D * (across * down)[body]
        if report:
            self.report["shoulders"] = {"k": k, "width_m": round(width, 3), "moved_m": round(D, 4)}
        return out

    def tuck_skin(self, pieces):
        """His skin tucked under his twin garments: a garment's faces are long (Rodin's quads,
        ~2 cm, some 10) and its flat faces cut through the round of an arm or the flare of his
        shorts wherever its corners sit only just outside him. Each skin point the garment
        covers (its nearest garment face within 5 cm, facing as his skin does: not the coat's
        lining, which faces him) and that lies outside it or less than TUCK_M under it is drawn
        in along its normal to TUCK_M under, by TUCK_MAX_M at most. Only this man's skin moves
        (the base body is untouched), and only where he is dressed: his hands, neck and head never."""
        bare = np.array([str(r).startswith(("hand", "head", "neck")) for r in self.region])
        shirt = any(pc.shape == "shirt" for pc in pieces)
        if shirt:
            # His arms are in their sleeves already (_arms_in_sleeves), as a whole: not tucked
            # point by point.
            bare |= np.array([str(r).startswith(("upper_arm", "forearm")) for r in self.region])
        # Under a whole shirt his skin is never seen, and posed (his arms down from the model's
        # pose) his armpits and sides move apart from it by more than TUCK_M: deeper there.
        self.v, moved = tuck_under(self.v, self.tris, ~bare, pieces, TUCK_SHIRT_M if shirt else None,
                                   outward_from_bones(self.v, self.region, self.bones()))
        self.report["skin_tucked"] = int(moved)

    def _sleeves_round_arms(self, shirt):
        """A shirt's sleeve never inside his arm: the twin's sleeves are dented in places (their
        insides within 5 mm of the bone where his forearm is 2 cm thick: his arm came through).
        Along each arm in SLEEVE_RINGS bands and round it in SLEEVE_ANGLES, the sleeve's points
        no nearer the bone than his skin's furthest there plus SLEEVE_ROOM."""
        o = self.our_joints()
        moved = 0
        for side in "rl":
            for name, a, b in (("upper_arm_" + side, o[side + "-shoulder"], o[side + "-elbow"]),
                               ("forearm_" + side, o[side + "-elbow"], o[side + "-hand"])):
                ab = b - a
                L = float(np.linalg.norm(ab))
                u = ab / L
                ref = np.cross(u, [0.0, 0.0, 1.0])
                ref /= np.linalg.norm(ref) + 1e-12
                ref2 = np.cross(u, ref)

                def polar(P):
                    t = (P - a) @ u / L
                    f = P - a - (t * L)[:, None] * u
                    return t, np.arctan2(f @ ref2, f @ ref), np.linalg.norm(f, axis=1), f

                ts, as_, rs, _f = polar(self.v[self.region == name])
                tp, ap, rp, fp = polar(shirt.v)
                mine = (tp > 0.05) & (tp < 0.98) & (rp < SLEEVE_R)
                tb = np.clip((ts * SLEEVE_RINGS).astype(int), 0, SLEEVE_RINGS - 1)
                abin = np.clip(((as_ + np.pi) / (2 * np.pi) * SLEEVE_ANGLES).astype(int), 0, SLEEVE_ANGLES - 1)
                need = np.zeros((SLEEVE_RINGS, SLEEVE_ANGLES))
                # (His arm's own skin: not what of his chest or back the region reaches into.)
                arm_pts = (ts >= 0) & (ts < 1) & (rs < SLEEVE_ARM_MAX)
                np.maximum.at(need, (tb[arm_pts], abin[arm_pts]), rs[arm_pts])
                need = np.maximum(need, np.roll(need, 1, 1))     # a little round each way
                need = np.maximum(need, np.roll(need, -1, 1))
                pb = np.clip((tp * SLEEVE_RINGS).astype(int), 0, SLEEVE_RINGS - 1)
                pa = np.clip(((ap + np.pi) / (2 * np.pi) * SLEEVE_ANGLES).astype(int), 0, SLEEVE_ANGLES - 1)
                floor = need[pb, pa] + SLEEVE_ROOM
                low = mine & (need[pb, pa] > 0) & (rp < floor)
                shirt.v[low] = shirt.v[low] + fp[low] / np.maximum(rp[low], 1e-9)[:, None] * (floor[low] - rp[low])[:, None]
                moved += int(low.sum())
        shirt.report["sleeve_points_out_of_arm"] = moved

    def _arms_in_sleeves(self, sleeves):
        """His arms inside a shirt's sleeves (roadmap 1.3), each drawn in towards its bone by one
        factor: from each arm bone straight out through each skin point to the sleeve
        (`sleeves`: the shirt), the factor that puts all but SLEEVE_SPARE of the arm SLEEVE_IN
        inside it (never under SLEEVE_MIN), easing back to his own over SLEEVE_FADE at his
        shoulder and above his wrist's cut. One factor keeps the arm's own smooth shape: point
        by point (the face-by-face tuck, Rodin's faces wound either way) it crumpled into shards
        that came through the shirt. Unseen under the shirt; his wrist where the cuff ends is his
        own."""
        from mathutils import Vector
        from mathutils.bvhtree import BVHTree
        trees = [BVHTree.FromPolygons([tuple(p) for p in pc.v], [tuple(int(i) for i in f) for f in pc.tris]) for pc in sleeves]
        o = self.our_joints()
        wrists = getattr(self, "wrists", {})
        rep = self.report.setdefault("arms_in_sleeves", {})
        for side in "rl":
            sh, el, wr = o[side + "-shoulder"], o[side + "-elbow"], o[side + "-hand"]
            cut = wrists[side][0] if side in wrists else wr
            segs = (("upper_arm_" + side, sh, el), ("forearm_" + side, el, cut))
            ratios = []
            geo = {}
            for name, a, b in segs:
                idx = np.nonzero(self.region == name)[0]
                if not len(idx):
                    continue
                ab = b - a
                t = (self.v[idx] - a) @ ab / max(float(ab @ ab), 1e-12)
                foot = a + t[:, None] * ab
                r_vec = self.v[idx] - foot
                r = np.linalg.norm(r_vec, axis=1)
                geo[name] = (idx, foot, r_vec, t, a, b)
                inside = (t > 0.15) & (t < 0.9) & (r > 1e-6)
                for n in np.nonzero(inside)[0][::3]:
                    best = None
                    for tree in trees:
                        hit, _hn, _f, dist = tree.ray_cast(Vector(foot[n]), Vector(r_vec[n] / r[n]), 0.2)
                        if hit is not None and (best is None or dist < best):
                            best = dist
                    if best is not None:
                        ratios.append((best - SLEEVE_IN) / r[n])
            if not ratios:
                continue
            k = float(np.clip(np.percentile(ratios, 100 * SLEEVE_SPARE), SLEEVE_MIN, 1.0))
            rep[side] = round(k, 3)
            for name, (idx, foot, r_vec, t, a, b) in geo.items():
                if name.startswith("upper_arm"):
                    ease = np.ones(len(idx))      # to his shoulder: under the shirt there too
                else:
                    u = (b - a) / np.linalg.norm(b - a)
                    ease = np.clip(-((self.v[idx] - cut) @ u) / SLEEVE_FADE, 0, 1)  # above his wrist
                kk = 1.0 - (1.0 - k) * ease
                self.v[idx] = foot + r_vec * kk[:, None]

    def _trunk_in(self):
        """His torso drawn in towards its middle under a shirt (TRUNK_IN_X of its width, TRUNK_IN
        of its depth),
        from his hips to under his collar, fading out at his collarbones: the model stands with
        its arms out, the game lets them hang, and his sides came through between his vest and
        his sleeves. His clothes close over it without a gap (checked with his skin hidden), so it
        is never seen; his throat above the collar is his own."""
        o = self.our_joints()
        sh_y = (o["r-shoulder"][1] + o["l-shoulder"][1]) * 0.5
        sel = self.region == "trunk"
        p = self.v[sel]
        axis_x = 0.5 * (o["r-shoulder"][0] + o["l-shoulder"][0])
        axis_z = float(np.median(p[:, 2]))
        fade = np.clip(((sh_y - 0.02) - p[:, 1]) / 0.08, 0, 1)
        kx = 1.0 - (1.0 - TRUNK_IN_X) * fade      # most across: his arms hang at his sides
        kz = 1.0 - (1.0 - TRUNK_IN) * fade
        p[:, 0] = axis_x + (p[:, 0] - axis_x) * kx
        p[:, 2] = axis_z + (p[:, 2] - axis_z) * kz
        self.v[sel] = p
        self.report["trunk_in"] = TRUNK_IN

    def tuck_layers(self, pieces):
        """His garments one inside another (roadmap 1.3): each tucked under every garment outside
        it in LAYERS (the shirt under his trousers, vest and coat; the vest under the coat), as
        his skin is under them all. Garments cut from different twins (his coat from the coated
        one, the rest from the coatless) poke through each other otherwise: his shirt's sleeves
        through the coat's."""
        order = [pc for name in LAYERS for pc in pieces if pc.shape == name]
        for pc in pieces:
            if pc.shape == "vest":
                # A vest has no sleeves: what of it the cut found on his arms (a shadowed fold of
                # his shirt, brown enough) came through the coat's sleeves.
                arm = np.array([str(r).startswith(("upper_arm", "forearm", "hand")) for r in pc.region])
                keep = ~arm[pc.tris].any(axis=1)
                pc.report["arm_bits_dropped"] = int((~keep).sum())
                pc.tris = pc.tris[keep]
        coats = [pc for pc in pieces if pc.shape == "coat"]
        if coats:
            # Under a coat only what shows through its opening is ever seen (the game never
            # takes a coat off): a vest or shirt triangle with the coat straight outside it
            # (out from his middle, or straight ahead, within COVER_REACH) is dropped. Kept, its
            # sides came through the coat when his arms hung.
            from mathutils import Vector
            from mathutils.bvhtree import BVHTree
            o = self.our_joints()
            mid = 0.5 * (o["r-shoulder"] + o["l-shoulder"])
            ctree = [BVHTree.FromPolygons([tuple(q) for q in c.v], [tuple(int(i) for i in f) for f in c.tris]) for c in coats]
            for pc in pieces:
                if pc.shape not in ("vest", "shirt"):
                    continue
                cen = pc.v[pc.tris].mean(1)
                out = cen - mid
                out[:, 1] = 0.0
                out /= np.linalg.norm(out, axis=1, keepdims=True) + 1e-12
                covered = np.zeros(len(pc.tris), bool)
                fwd = Vector((0.0, 0.0, -1.0))         # body space faces -Z
                for k in range(len(cen)):
                    # Out from his middle, and straight ahead (his sides are under the coat's
                    # sleeves when his arms hang, which they don't in the model's A-pose).
                    for d in (Vector(out[k]), fwd):
                        start = Vector(cen[k]) + d * 0.002
                        if any(tree.ray_cast(start, d, COVER_REACH)[0] is not None for tree in ctree):
                            covered[k] = True
                            break
                # At his sides (not the opening, where the lapels are near the shirt front) the
                # coat anywhere within COVER_REACH covers it: at his ribs the coat's side hangs up
                # and out in the A-pose, no ray from the shirt met it, and the shirt's ribs showed
                # through the coat's cut side as cream patches (2026-10-17).
                at_side = np.abs(cen[:, 0] - mid[0]) > COVER_SIDE_X
                for k in np.nonzero(at_side & ~covered)[0]:
                    if any(tree.find_nearest(Vector(cen[k]), COVER_REACH)[0] is not None for tree in ctree):
                        covered[k] = True
                # And by his armholes: the coat's sleeve comes down over them when his arms hang.
                for lr in "rl":
                    a, b = o[lr + "-shoulder"], o[lr + "-elbow"]
                    ab = b - a
                    t = np.clip((cen - a) @ ab / max(float(ab @ ab), 1e-12), 0, 1)
                    covered |= np.linalg.norm(cen - (a + t[:, None] * ab), axis=1) < ARMHOLE_R
                pc.report["covered_by_coat_dropped"] = int(covered.sum())
                pc.tris = pc.tris[~covered]
        if coats:
            # Under a coat his shirt's sleeves are never seen (the game never takes a coat off:
            # a man without one is his own outfit, people.json), and two garments from two twins
            # never nest cleanly: they came through the coat's sleeves. Cut away.
            for pc in pieces:
                if pc.shape == "shirt":
                    arm = np.array([str(r).startswith(("upper_arm", "forearm", "hand")) for r in pc.region])
                    keep = ~arm[pc.tris].any(axis=1)
                    pc.report["sleeves_cut_under_coat"] = int((~keep).sum())
                    pc.tris = pc.tris[keep]
        for k, pc in enumerate(order):
            over = order[k + 1:]
            if not over:
                continue
            movable = np.ones(len(pc.v), bool)
            if pc.shape == "shirt":
                # His sleeves aren't under his trousers or vest: tucked under them where his arm
                # hangs by his hip, their insides were dented into his arm.
                movable &= ~np.array([str(r).startswith(("upper_arm", "forearm", "hand")) for r in pc.region])
            pc.v, moved = tuck_under(pc.v, pc.tris, movable, over,
                                     outward=outward_from_bones(pc.v, pc.region, self.bones()),
                                     flip_faces=pc.shape == "trousers")
            pc.report["tucked_under_" + "_".join(o.shape for o in over)] = int(moved)

    def own_fingers(self):
        """His own fingers as the game's finger pieces (tools/blender/fingers.py; people.json
        `own_fingers`): each hand's thumb and four fingers found on his mesh, cut in three, each
        piece laid straight on its bone in the game's rest pose, and taken out of his skin; his
        palm narrowed to the game's hand. A hand that doesn't come apart in five keeps the old way
        (fingers cut off at the knuckles, the game's own drawn instead)."""
        if self.spec.get("own_fingers") == "makehuman":
            return self.makehuman_hands()
        if self.spec.get("own_fingers") == "skinned":
            return self.skinned_hands()
        import fingers as FG
        o = self.our_joints()
        F = self.env.get("fingers", {})
        self.finger_pieces = {}
        drop = np.zeros(len(self.tris), bool)
        rep = self.report.setdefault("own_fingers", {})
        for side in "rl":
            hand = self.region == "hand_" + side
            w, k = o[side + "-hand"], o[side + "-knuckle"]
            seg = FG.segment(self.v, self.tris, hand, w, k) if F else None
            if seg is None:
                rep[side] = "not found: the game's fingers"
                continue
            pos, d, weld, hv = seg["pos"], seg["d"], seg["weld"], seg["hv"]
            label = np.full(len(pos), -1)
            frac = np.zeros(len(pos))
            moves = {}
            for n, name in enumerate(FG.FINGERS):
                ids = seg["fingers"][name]
                fid = "%s_%s" % (name, side)
                f, mv = FG.straighten(pos, d, ids, np.array(F[fid]["a"]), np.array(F[fid]["b"]), side)
                label[ids] = n
                frac[ids] = f
                moves[fid] = mv
            local = -np.ones(len(self.v), np.int64)
            local[hv] = weld
            t = local[self.tris]
            inhand = (t >= 0).all(1)
            lab = np.where(inhand[:, None], label[np.where(t >= 0, t, 0)], -1)
            # A triangle goes with the finger two or more of its corners are in.
            for n, name in enumerate(FG.FINGERS):
                fid = "%s_%s" % (name, side)
                mine = inhand & ((lab == n).sum(1) >= 2)
                bone = FG.bone_of(np.nanmean(np.where(lab == n, frac[np.where(t >= 0, t, 0)], np.nan)[mine], axis=1) if mine.any() else np.zeros(0))
                pieces = []
                for b in range(3):
                    tb = self.tris[mine][bone == b]
                    used = np.unique(tb)
                    remap = -np.ones(len(self.v), np.int64)
                    remap[used] = np.arange(len(used))
                    pieces.append((self.uv[used], FG.move(self.v[used], moves[fid][b]), remap[tb]))
                self.finger_pieces[fid] = pieces
                drop |= mine
            # His palm to the game's hand: across his index to little knuckles, his against the anatomy's.
            base = lambda ids: pos[ids[np.argsort(d[ids])[:max(5, len(ids) // 6)]]].mean(0)
            his = float(np.linalg.norm(base(seg["fingers"]["index"]) - base(seg["fingers"]["little"])))
            game = float(np.linalg.norm(np.array(F["index_" + side]["a"]) - np.array(F["little_" + side]["a"])))
            s = float(np.clip(game / max(his, 1e-6), 0.5, 1.0))
            palm = hand.copy()
            palm[np.unique(self.tris[drop])] = False
            self.v = FG.narrow_palm(self.v, palm, w, k, s)
            rep[side] = {"palm_narrowed": round(s, 3), "finger_triangles": {n: int(sum(len(p[2]) for p in self.finger_pieces["%s_%s" % (n, side)])) for n in FG.FINGERS}}
        self.report["faces_before_finger_cut"] = int(len(self.tris))
        self.tris = self.tris[~drop]
        self.report["faces_after_finger_cut"] = int(len(self.tris))
        if any(isinstance(rep.get(sd), str) for sd in "rl"):
            # A hand that didn't come apart: its fingers off at the knuckles as before.
            self.cut_fingers()

    def makehuman_hands(self):
        """MakeHuman's hands for his (tools/blender/mh_hand.py; people.json own_fingers
        "makehuman"): his own hand off his skin, MakeHuman's palm in its place and its fingers as
        the game's finger pieces, all fitted to the game's hand, and painted in his skin
        (mh_hand.paint: his hand's colour, shadow from the hand's shape, palm, nails) into a free
        square of his skin's texture (where his own hand was painted, or any space no face uses).
        His own fingers, cut from Rodin's coarse, half-curled, outsized hand, came out in shards."""
        import mh_hand as MH
        o = self.our_joints()
        F = self.env["fingers"]
        self.finger_pieces = {}
        self.hand_paint = []
        rep = self.report.setdefault("own_fingers", {"from": "makehuman"})
        img = np.asarray(self.colour, dtype=np.float64) / 255.0
        hgt, wid = img.shape[:2]
        placed = {}
        for side in "rl":
            hand = self.region == "hand_" + side
            his = np.nonzero(hand)[0]
            uvh = self.uv[his]
            col = img[np.clip((uvh[:, 1] * hgt).astype(int), 0, hgt - 1), np.clip((uvh[:, 0] * wid).astype(int), 0, wid - 1)]
            base = np.median(col, 0)
            # His arm and the new palm cut along one plane just short of his wrist, and the new
            # palm's ring drawn onto his (as the neck ring joins his head): no ragged edge, no gap.
            el, wr = o[side + "-elbow"], o[side + "-hand"]
            ax = (wr - el) / np.linalg.norm(wr - el)
            point = wr - ax * WRIST_CUT
            arm = np.isin(self.region, ["forearm_" + side, "hand_" + side])
            his_arm_tris = arm[self.tris].all(axis=1)
            before = len(self.tris)
            self.v, self.tris, (self.v_tripo, self.uv), (self.region, self.head), ring = MH.clip(
                self.v, self.tris, point, ax, his_arm_tris, lerp=(self.v_tripo, self.uv), copy=(self.region, self.head))
            gone = np.zeros(before, bool)
            (palm, fingers) = MH.place(side, o, F)
            q, t, u, pa = palm
            q, t, (u,), (pa,), ring_q = MH.clip(q, t, point, -ax, np.ones(len(t), bool), lerp=(u,), copy=(pa,))
            used = np.unique(t)
            remap = -np.ones(len(q), np.int64)
            remap[used] = np.arange(len(used))
            ring_q = remap[ring_q][remap[ring_q] >= 0]
            q, t, u, pa = q[used], remap[t], u[used], pa[used]
            if len(ring) and len(ring_q):
                # They meet in the middle: his forearm tapers in towards his wrist over ARM_TAPER
                # (Rodin's forearm runs on thick to the hand) to WRIST_SWELL of MakeHuman's wrist,
                # and the new palm's ring is drawn onto that (all the hand's own flare was a bell).
                palm_dir = np.array([-1.0, 0, 0]) if side == "r" else np.array([1.0, 0, 0])
                fore = np.nonzero(np.isin(self.region, ["forearm_" + side, "hand_" + side]))[0]
                up = (self.v[fore] - point) @ ax
                near = fore[(up <= 1e-9) & (up > -ARM_TAPER)]
                self.v[near] = MH.taper(self.v[near], self.v[ring], q[ring_q], point, ax, palm_dir, ARM_TAPER, WRIST_SWELL)
                q = MH.join_ring(q, ring_q, self.v[ring], point, ax, palm_dir, WRIST_BLEND)
            palm = (q, t, u, pa)
            placed[side] = ((palm, fingers), base, int(gone.sum()))
        squares = self._free_squares(2, HAND_SQUARE)
        for side, (u0, v0) in zip("rl", squares):
            (palm, fingers), base, gone = placed[side]
            paint, palm, fingers = MH.paint(palm, fingers, side, base)
            self.hand_paint.append((paint, (u0, v0, HAND_SQUARE)))
            to_uv = lambda uv: np.c_[u0 + uv[:, 0] * HAND_SQUARE, v0 + uv[:, 1] * HAND_SQUARE]
            for fid, pieces in fingers.items():
                self.finger_pieces[fid] = [(to_uv(pc[2]), pc[0], pc[1]) for pc in pieces]
            q, t, u = palm[:3]
            n0 = len(self.v)
            self.v = np.vstack([self.v, q])
            self.v_tripo = np.vstack([self.v_tripo, q])
            self.uv = np.vstack([self.uv, to_uv(u)])
            self.region = np.concatenate([self.region, np.full(len(q), "hand_" + side, dtype=self.region.dtype)])
            self.head = np.concatenate([self.head, np.zeros(len(q), bool)])
            self.tris = np.vstack([self.tris, t + n0])
            rep[side] = {"his_hand_triangles_off": gone, "palm_triangles": int(len(t)),
                         "painted_at_uv": [round(float(u0), 4), round(float(v0), 4), HAND_SQUARE],
                         "finger_triangles": {fid: int(sum(len(pc[2]) for pc in self.finger_pieces[fid])) for fid in fingers}}

    def skinned_hands(self):
        """MakeHuman's hand whole on each arm, skinned to 15 finger bones (people.json
        own_fingers "skinned"; docs/briefs/skinned-hands.md): no pieces, so no seams or doll
        joints; the game bends the bones by its finger nodes' angles. His arm and the hand are cut
        along one plane and joined as `makehuman_hands` joins them; painted by mh_hand.paint into
        free squares of his texture. Its weights go on in finger_weights (after weights())."""
        import mh_hand as MH
        o = self.our_joints()
        F = self.env["fingers"]
        self.hand_paint, self.hand_fw, self.finger_rests, self.wrists, self.seams = [], [], {}, {}, {}
        self.extra_bones = MH.finger_bone_names("r") + MH.finger_bone_names("l")
        rep = self.report.setdefault("own_fingers", {"from": "makehuman, skinned"})
        # His colours from the texture his skin is drawn with: his repaint where there is one
        # (body_paint.py), not Rodin's own (the hand came out paler and greyer than his arm).
        named = self.spec.get("paint") or (self.id if os.path.exists(os.path.join(TRIPO, self.id + "_color.png")) else self.model)
        painted = os.path.join(TRIPO, named + "_color.png")
        img = np.asarray(Image.open(painted).convert("RGB") if os.path.exists(painted) else self.colour, dtype=np.float64) / 255.0
        hgt, wid = img.shape[:2]
        made = {}
        for side in "rl":
            # His hand's colour from his forearm near the wrist (his own hand's paint is paler: the
            # new hand stood out pink against his arm).
            el, wr = o[side + "-elbow"], o[side + "-hand"]
            axw = (wr - el) / np.linalg.norm(wr - el)
            fore = np.nonzero((self.region == "forearm_" + side) & ((self.v - wr) @ axw > -0.08) & ((self.v - wr) @ axw < -0.01))[0]
            uvh = self.uv[fore]
            col = img[np.clip((uvh[:, 1] * hgt).astype(int), 0, hgt - 1), np.clip((uvh[:, 0] * wid).astype(int), 0, wid - 1)]
            base = np.median(col, 0)
            ax = (wr - el) / np.linalg.norm(wr - el)
            point = wr - ax * WRIST_CUT
            arm = np.isin(self.region, ["forearm_" + side, "hand_" + side])
            self.v, self.tris, (self.v_tripo, self.uv), (self.region, self.head), ring = MH.clip(
                self.v, self.tris, point, ax, arm[self.tris].all(axis=1), lerp=(self.v_tripo, self.uv), copy=(self.region, self.head))
            q, t, u, pa, W, rests = MH.skinned(side, o, F)
            # The hand cut BRIDGE below his arm's cut: the strip between is stitched (a strip of
            # no width between rings in one place had no way to face, and drew a line).
            q, t, (u, W), (pa,), ring_q = MH.clip(q, t, point + ax * BRIDGE, -ax, np.ones(len(t), bool), lerp=(u, W), copy=(pa,))
            used = np.unique(t)
            remap = -np.ones(len(q), np.int64)
            remap[used] = np.arange(len(used))
            ring_q = remap[ring_q][remap[ring_q] >= 0]
            q, t, u, pa, W = q[used], remap[t], u[used], pa[used], W[used]
            palm_dir = np.array([-1.0, 0, 0]) if side == "r" else np.array([1.0, 0, 0])
            self.wrists[side] = (point, ax, palm_dir)
            if len(ring) and len(ring_q):
                fore = np.nonzero(np.isin(self.region, ["forearm_" + side, "hand_" + side]))[0]
                up = (self.v[fore] - point) @ ax
                near = fore[(up <= 1e-9) & (up > -ARM_TAPER)]
                self.v[near] = MH.taper(self.v[near], self.v[ring], q[ring_q], point, ax, palm_dir, ARM_TAPER, WRIST_SWELL)
                q = MH.join_ring(q, ring_q, self.v[ring], point, ax, palm_dir, WRIST_BLEND)
                # One smooth profile across the cut (no crease where the hand meets the wrist).
                band = fore[((self.v[fore] - point) @ ax > -MH.WRIST_ARM - 0.02) & ((self.v[fore] - point) @ ax <= 1e-9)]
                self.v[band], q = MH.smooth_wrist(self.v[band], q, point, ax, palm_dir)
                # And the two cut edges stitched together (they don't share points: cracks
                # between them showed the background, "that line where the hand and wrist meet").
                self.seams[side] = (point, ax, np.asarray(ring)) + self._stitch(ring, q[ring_q], point, ax, palm_dir, side)
                if os.environ.get("WRIST_DEBUG"):
                    np.savez("build/wrist_%s.npz" % side, arm=self.v[fore], hand=q, point=point, ax=ax, ref=palm_dir, ring=self.v[ring], ring_q=q[ring_q])
            for name, (origin, basis) in zip(MH.finger_bone_names(side), rests):
                self.finger_rests[name] = (origin, basis)
            # Laid out and painted by part (the palm, each finger bone), as the pieced hands were.
            pt = pa[t]
            tri_part = np.where((pt[:, 0] == pt[:, 1]) | (pt[:, 0] == pt[:, 2]), pt[:, 0], np.where(pt[:, 1] == pt[:, 2], pt[:, 1], pt[:, 0]))
            pieces, useds = [], []
            for key in [-1] + list(range(15)):
                tk = t[tri_part == key]
                uu = np.unique(tk)
                rm = -np.ones(len(q), np.int64)
                rm[uu] = np.arange(len(uu))
                pieces.append((q[uu], rm[tk], u[uu], pa[uu]))
                useds.append(uu)
            # His forearm's colour round the cut, for the hand's paint to fade into.
            uvr = self.uv[ring] if len(ring) else np.zeros((0, 2))
            ring_col = img[np.clip((uvr[:, 1] * hgt).astype(int), 0, hgt - 1), np.clip((uvr[:, 0] * wid).astype(int), 0, wid - 1)]
            wrist = (point, ax, self.v[ring].copy(), ring_col) if len(ring) else None
            made[side] = (pieces, useds, W, base, [o_ for o_, _b in rests], wrist)
        # The biggest squares his texture has free, up to HAND_SQUARE_MAX: a hand in his
        # texture's chunky squares has few of them (its nails a few texels).
        for hs in np.arange(HAND_SQUARE_MAX, HAND_SQUARE - 1e-9, -0.005):
            try:
                squares = self._free_squares(2, float(hs))
                break
            except RuntimeError:
                continue
        else:
            squares, hs = self._free_squares(2, HAND_SQUARE), HAND_SQUARE
        hs = float(hs)
        rep["hand_square"] = round(hs, 3)
        for side, (u0, v0) in zip("rl", squares):
            pieces, useds, W, base, joints, wrist = made[side]
            paint, palm, fingers = MH.paint(pieces[0], {"%s_%s" % (MH.FINGERS[k // 3], side): pieces[1 + 3 * (k // 3):4 + 3 * (k // 3)] for k in range(0, 15, 3)}, side, base, joints=joints, wrist=wrist)
            self.hand_paint.append((paint, (u0, v0, hs)))
            out = [palm] + [pc for name in MH.FINGERS for pc in fingers["%s_%s" % (name, side)]]
            tris_n = 0
            for (pts, tt, cu, local), uu in zip(out, useds):
                n0 = len(self.v)
                self.v = np.vstack([self.v, pts])
                self.v_tripo = np.vstack([self.v_tripo, pts])
                self.uv = np.vstack([self.uv, np.c_[u0 + cu[:, 0] * hs, v0 + cu[:, 1] * hs]])
                self.region = np.concatenate([self.region, np.full(len(pts), "hand_" + side, dtype=self.region.dtype)])
                self.head = np.concatenate([self.head, np.zeros(len(pts), bool)])
                self.tris = np.vstack([self.tris, tt + n0])
                self.hand_fw.append((n0, W[uu[local]], side))
                tris_n += len(tt)
            rep[side] = {"hand_triangles": tris_n, "painted_at_uv": [round(float(u0), 4), round(float(v0), 4), round(hs, 4)]}
        self.report["finger_bones"] = {n: {"origin": [round(float(x), 5) for x in o_],
                                           "basis": [[round(float(x), 5) for x in row] for row in b_]}
                                       for n, (o_, b_) in self.finger_rests.items()}

    def _stitch(self, ring, hand_ring, point, ax, ref, side):
        """A strip of triangles from his arm's cut edge (`ring`, his points) to the hand's
        (`hand_ring`, positions, BRIDGE below), zipped round the wrist by angle, each triangle
        its own corners in one colour of his arm's. Returns its corners on his arm's ring and on
        the hand's (finger_weights gives each the weights of the ring it lies on)."""
        e1 = ref - (ref @ ax) * ax
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(ax, e1)
        ang = lambda p: np.arctan2((p - point) @ e2, (p - point) @ e1)
        # One point a place (Rodin's triangles share none; the hand's ring has its seams).
        _u, first = np.unique(np.round(self.v[ring] / 1e-6).astype(np.int64), axis=0, return_index=True)
        arm = np.asarray(ring)[first]
        arm = arm[np.argsort(ang(self.v[arm]))]
        _u, first = np.unique(np.round(hand_ring / 1e-6).astype(np.int64), axis=0, return_index=True)
        hp = hand_ring[first]
        hp = hp[np.argsort(ang(hp))]
        if len(arm) < 3 or len(hp) < 3:
            return np.zeros(0, np.int64), np.zeros(0, np.int64)
        n0 = len(self.v)
        aa, ha = ang(self.v[arm]), ang(hp)
        tris, i, j = [], 0, 0
        na, nh = len(arm), len(hp)
        A, H = 0, 1   # a corner on his arm's ring or the hand's
        while i < na or j < nh:
            a0, a1 = (A, i % na), (A, (i + 1) % na)
            h0, h1 = (H, j % nh), (H, (j + 1) % nh)
            # Advance whichever ring's next point comes first round the wrist.
            next_a = aa[(i + 1) % na] + (2 * np.pi if i + 1 >= na else 0)
            next_h = ha[(j + 1) % nh] + (2 * np.pi if j + 1 >= nh else 0)
            if j >= nh or (i < na and next_a <= next_h):
                tris.append((a0, a1, h0))
                i += 1
            else:
                tris.append((a0, h1, h0))
                j += 1
        # Each triangle its own corners, all one colour (its first arm point's place in his
        # texture: his ring's neighbours can lie in different patches of it, and a strip
        # across them drew stripes).
        pos = lambda c: self.v[arm[c[1]]] if c[0] == A else hp[c[1]]
        P = np.array([[pos(c) for c in t] for t in tris])
        on_hand = np.array([[c[0] == H for c in t] for t in tris]).reshape(-1)
        uv = np.repeat(self.uv[arm[[t[0][1] for t in tris]]], 3, axis=0)
        P = P.reshape(-1, 3)
        T = np.arange(len(P)).reshape(-1, 3)
        # Facing out from his wrist.
        fn = np.cross(P[T[:, 1]] - P[T[:, 0]], P[T[:, 2]] - P[T[:, 0]])
        c = P[T].mean(1) - point
        out = c - (c @ ax)[:, None] * ax
        flip = (fn * out).sum(1) < 0
        T[flip] = T[flip][:, [0, 2, 1]]
        self.v = np.vstack([self.v, P])
        self.v_tripo = np.vstack([self.v_tripo, P])
        self.uv = np.vstack([self.uv, uv])
        self.region = np.concatenate([self.region, np.where(on_hand, "hand_" + side, "forearm_" + side).astype(self.region.dtype)])
        self.head = np.concatenate([self.head, np.zeros(len(P), bool)])
        self.tris = np.vstack([self.tris, T + n0])
        self.report.setdefault("own_fingers", {}).setdefault("wrist_stitch", {})[side] = int(len(T))
        idx = np.arange(n0, n0 + len(P))
        return idx[~on_hand], idx[on_hand]

    def finger_weights(self):
        """The skinned hands' finger weights onto his skin's (W grows by the 30 finger bones,
        `extra_bones`): each hand point's finger share taken from its hand weight."""
        extra = getattr(self, "extra_bones", [])
        if not extra:
            return
        # At the wrist the hand bends as his arm's cut edge does (each point its nearest edge
        # point's weights), easing into its own over SEAM_BLEND down the hand: the arm's edge,
        # the hand's and the stitch between them, weighted apart, pulled apart in any pose (a
        # hairline of background, spikes).
        from scipy.spatial import cKDTree
        for side, (point, ax, ring, arm_c, hand_c) in getattr(self, "seams", {}).items():
            if not len(ring):
                continue
            rows = np.concatenate([np.arange(n0, n0 + len(fw)) for n0, fw, sd in self.hand_fw if sd == side]).astype(np.int64)
            ring_tree = cKDTree(self.v[ring])
            k = ring_tree.query(self.v[rows])[1]
            t = np.clip(((self.v[rows] - point) @ ax) / SEAM_BLEND, 0, 1)[:, None]
            self.W[rows] = self.W[ring[k]] * (1 - t) + self.W[rows] * t
            # The strip's corners exactly as the ring each lies on.
            if len(arm_c):
                self.W[arm_c] = self.W[ring[ring_tree.query(self.v[arm_c])[1]]]
            if len(hand_c):
                self.W[hand_c] = self.W[rows[cKDTree(self.v[rows]).query(self.v[hand_c])[1]]]
        nb = self.W.shape[1]
        W = np.zeros((len(self.v), nb + len(extra)))
        W[:, :nb] = self.W
        for n0, fw, side in self.hand_fw:
            rows = np.arange(n0, n0 + len(fw))
            share = fw.sum(1)
            W[rows, :nb] *= (1.0 - share)[:, None]
            off = 0 if side == "r" else 15
            W[rows, nb + off:nb + off + 15] = fw
        self.W = W

    def _free_squares(self, n, side):
        """n squares `side` of the texture a side that no face of his uses (UV, top-left corners):
        his faces drawn into the layout, a texel's margin, the clearest places taken in turn."""
        import sys as _sys
        from scipy import ndimage
        _sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "characters"))
        import portrait as P
        G = 1024
        tid, _b, _z = P.rasterise(self.uv * G, np.zeros(len(self.uv)), self.tris, G, G)
        used = ndimage.binary_dilation(tid >= 0, iterations=2)
        used[:2, :] = used[-2:, :] = True     # the texture's edge is a wall, not free space
        used[:, :2] = used[:, -2:] = True
        half = int(np.ceil(side * G / 2)) + 1
        out = []
        for _k in range(n):
            dt = ndimage.distance_transform_cdt(~used, metric="chessboard")
            y, x = np.unravel_index(np.argmax(dt), dt.shape)
            if dt[y, x] < half:
                raise RuntimeError("no free square %.3f a side in his texture for a hand" % side)
            out.append(((x - half + 1) / G, (y - half + 1) / G))
            used[y - half:y + half + 1, x - half:x + half + 1] = True
        return out

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
        if "model" not in self.spec and "coat" not in self.spec.get("pieces", {}):
            # A whole man's coat skirt is in his skin; a layered man's body wears trousers, and
            # the rule would hand their legs to his pelvis (a base body wears its coat as a piece).
            self.skirt()
        if self.bare:
            self.cut_bridges()
            self.close_cuts()
        if self.spec.get("own_fingers"):
            self.own_fingers()
        else:
            self.cut_fingers()
        self.skin_tone()
        self.weights()
        self.finger_weights()
        for piece in self.pieces:
            if piece.shape == "coat" and not piece.twin:
                piece.as_shell()
            elif piece.shape == "coat":
                # The skirt hangs from his hips, as the shell's does.
                piece.region[np.isin(piece.region, ["thigh_r", "thigh_l"])] = "trunk"
            if piece.twin:
                piece.clear_twin()
            if piece.shape == "hat":
                piece.region[:] = "head"
            mp.Person.weights(piece)
            if piece.twin:
                own = piece.region.copy()
                piece.weights_from_skin()
                piece.clear_hands(own)
        twins = [pc for pc in self.pieces if pc.twin]
        if twins:
            # His arms and torso inside his shirt, while it still has its sleeves (a coat cuts
            # them away in tuck_layers); then the garments into one another; then his skin
            # under all of them (tucked the other way, a shirt drawn in under the coat went
            # under his skin).
            shirt = [pc for pc in twins if pc.shape == "shirt"]
            if shirt:
                self._sleeves_round_arms(shirt[0])
                self._arms_in_sleeves(shirt)
                self._trunk_in()
            self.tuck_layers(twins)
            self.tuck_skin(twins)


def outward_from_bones(v, region, bones):
    """Each point's way out from its own bone (its region's segment in `bones`, the warp's
    [name, .., .., our a, our b, ..]): Rodin's faces are wound either way, and a point moved
    "in" along a face normal that pointed out became a spike through the shirt."""
    out = np.zeros_like(v)
    reg = np.asarray(region).astype(str)
    for b in bones:
        sel = reg == b[0]
        if not sel.any():
            continue
        a, c = np.asarray(b[3]), np.asarray(b[4])
        ac = c - a
        # Square to the bone's line (past its ends too: clipped, the way "out" ran along the arm).
        t = (v[sel] - a) @ ac / max(float(ac @ ac), 1e-12)
        r = v[sel] - (a + t[:, None] * ac)
        out[sel] = r / (np.linalg.norm(r, axis=1, keepdims=True) + 1e-12)
    return out


def tuck_under(v, tris, movable, pieces, depth=None, outward=None, flip_faces=False):
    """Points of a surface (`v`, `tris`) tucked under garments laid over it: a garment's faces are
    long (Rodin's quads, ~2 cm, some 10) and its flat faces cut through the round of an arm or a
    flare wherever its corners sit only just outside. Each movable point a garment covers (its
    nearest garment face within 5 cm, facing as the point does: not a lining, which faces in)
    and that lies outside it or less than TUCK_M under it is drawn in along its normal to TUCK_M
    under, by TUCK_MAX_M at most. Returns the points and how many places moved."""
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    trees = [BVHTree.FromPolygons([tuple(p) for p in pc.v], [tuple(int(i) for i in f) for f in pc.tris]) for pc in pieces]
    fn = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
    vn = np.zeros_like(v)
    for k in range(3):
        np.add.at(vn, tris[:, k], fn)
    # One place, one move: points come in once per face that meets there (Rodin's triangles
    # share none), and moved apart they'd crack.
    _u, first, weld = np.unique(np.round(v / 1e-6).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    weld = weld.ravel()
    gn = np.zeros((len(first), 3))
    np.add.at(gn, weld, vn)
    gn /= np.linalg.norm(gn, axis=1, keepdims=True) + 1e-12
    if outward is not None:
        # Out from the bone, where there is one (the face normals where it agrees, else the bone's).
        ob = outward[first]
        has = np.linalg.norm(ob, axis=1) > 0.5
        flip = has & ((gn * ob).sum(1) < 0)
        gn[flip] = ob[flip]
    still = ~np.asarray(movable)[first]
    gv = v[first].copy()
    moved = np.zeros(len(first), bool)
    # Neighbours over the welded surface, to move patches together.
    wt = weld[tris]
    e = np.concatenate([wt[:, [0, 1]], wt[:, [1, 2]], wt[:, [2, 0]]])
    from scipy.sparse import coo_matrix
    A = coo_matrix((np.ones(2 * len(e)), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])), shape=(len(first),) * 2).tocsr()
    A.data[:] = 1.0
    deg = np.maximum(np.asarray(A.sum(1)).ravel(), 1)
    for _ in range(2):
        need = np.zeros(len(first))
        for g in np.where(~still)[0]:
            p = Vector(gv[g])
            for tree in trees:
                loc, nrm, _f, _d = tree.find_nearest(p, 0.05)
                if loc is None:
                    continue
                if flip_faces and float(nrm.dot(Vector(gn[g]))) < 0:
                    nrm = -nrm          # a twin garment's faces are wound either way (Rodin's)
                if float(nrm.dot(Vector(gn[g]))) < 0.3:
                    continue
                need[g] = max(need[g], float((p - loc).dot(nrm)) + (TUCK_M if depth is None else depth))
        # Eased over neighbours (point by point, next-door points moved apart by centimetres
        # crumpled his forearm into spikes).
        for _ in range(TUCK_SPREAD):
            need = 0.5 * need + 0.5 * (A @ need) / deg
        need[still] = 0.0
        go = need > 1e-4
        gv[go] -= gn[go] * np.minimum(need[go], TUCK_MAX_M)[:, None]
        moved |= go
    return gv[weld], int(moved.sum())


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
        # A twin piece (tools/characters/twin_pieces.py: cut from his dressed twin, Rodin's same
        # man in clothes) comes laid on this body already: carried as it is, not placed by
        # landmarks nor rebuilt as a shell.
        side = os.path.join(TRIPO, cid + ".json")
        meta = json.load(open(side)) if os.path.exists(side) else {}
        self.twin = meta.get("twin") == body.spec.get("rodin", "").split("/")[-1].replace("_rodin", "")
        self.painted = bool(meta.get("painted"))    # its texture painted from his pictures (body_paint --dressed)
        self.report["twin"] = self.twin
        if self.twin:
            return
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
        if self.twin:
            return
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

    def clear_twin(self):
        """A twin piece out of his warped skin: the warp moves a sleeve and the arm under it by a
        little more or less (each point's bones blended by its own distance), so up to a few
        centimetres of cloth end under the skin. Each point set PIECE_CLEARANCE outside the
        nearest point of his skin's surface, along that face's normal (twice: a push can bring it
        nearer another face)."""
        from mathutils import Vector
        from mathutils.bvhtree import BVHTree
        body = self.body
        bvh = BVHTree.FromPolygons([tuple(p) for p in body.v], [tuple(int(i) for i in f) for f in body.tris])
        pushed = np.zeros(len(self.v), bool)
        for _ in range(2):
            for i in range(len(self.v)):
                loc, nrm, _f, _d = bvh.find_nearest(Vector(self.v[i]), PIECE_REACH)
                if loc is None:
                    continue
                sd = float((Vector(self.v[i]) - loc).dot(nrm))
                if sd < PIECE_CLEARANCE:
                    self.v[i] = self.v[i] + np.array(nrm) * (PIECE_CLEARANCE - sd)
                    pushed[i] = True
        self.report["pushed_out_after_warp"] = int(pushed.sum())

    def clear_hands(self, own):
        """His hands out of a twin piece (Sean, 2026-10-15: "his hands seem like they're melting
        into the jacket"). A sleeve ends at his wrist: what of it runs on CUFF_PAST beyond the
        cut his hand joins at (the dressed model's own hands, a long cuff) is dropped. The coat's
        skirt hangs where his hand does: each skirt point inside his hand, or within
        PIECE_CLEARANCE of it, goes behind it (towards his thigh, the way his palm faces), and
        the skirt round it follows smoothly, so the hand hangs in front of the coat."""
        wrists = getattr(self.body, "wrists", {})
        if not wrists:
            return
        from mathutils import Vector
        from mathutils.bvhtree import BVHTree
        from scipy.spatial import cKDTree
        body = self.body
        drop = np.zeros(len(self.tris), bool)
        move = np.zeros_like(self.v)
        for side, (point, ax, palm_dir) in wrists.items():
            # His sleeve by the piece's own regions (by the skin under it, the skirt by his hand
            # is his hand's too).
            arm = np.isin(own, ["forearm_" + side, "hand_" + side])
            past = arm & ((self.v - point) @ ax > CUFF_PAST)
            drop |= past[self.tris].any(1)
            hand = np.nonzero(body.region == "hand_" + side)[0]
            ht = body.tris[np.isin(body.tris, hand).all(1)]
            if not len(ht):
                continue
            bvh = BVHTree.FromPolygons([tuple(p) for p in body.v], [tuple(int(i) for i in f) for f in ht])
            tree = cKDTree(body.v[hand])
            skirt = np.nonzero(~arm & ((self.v - point) @ ax > 0))[0]
            for i in skirt:
                loc, nrm, _f, _d = bvh.find_nearest(Vector(self.v[i]), 0.05)
                if loc is None:
                    continue
                if float((Vector(self.v[i]) - loc).dot(nrm)) >= PIECE_CLEARANCE:
                    continue
                # Behind his hand along the way his palm faces: past the deepest of his hand on
                # this point's line through it.
                near = hand[tree.query_ball_point(self.v[i], 0.06)]
                rel = body.v[near] - self.v[i]
                along_p = rel @ palm_dir
                on_line = np.linalg.norm(rel - along_p[:, None] * palm_dir, axis=1) < HAND_LINE
                if not on_line.any():
                    continue
                move[i] = palm_dir * max(float(along_p[on_line].max()) + PIECE_CLEARANCE, 0.0)
        hit = np.nonzero(np.linalg.norm(move, axis=1) > 0)[0]
        if len(hit):
            # The skirt round each moved point follows, smoothly: the moves spread over his
            # welded skirt (Rodin's triangles share no corners), the moved points held.
            _u, first, weld = np.unique(np.round(self.v / 1e-6).astype(np.int64), axis=0, return_index=True, return_inverse=True)
            weld = weld.ravel()
            n = len(first)
            gm = np.zeros((n, 3))
            order = np.argsort(np.linalg.norm(move, axis=1))
            gm[weld[order]] = move[order]       # each place its corners' biggest move
            held = np.linalg.norm(gm, axis=1) > 0
            from scipy.sparse import coo_matrix
            t = weld[self.tris]
            e = np.concatenate([t[:, [0, 1]], t[:, [1, 2]], t[:, [2, 0]]])
            A = coo_matrix((np.ones(2 * len(e)), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])), shape=(n, n)).tocsr()
            A.data[:] = 1.0
            deg = np.maximum(np.asarray(A.sum(1)).ravel(), 1)
            D = gm.copy()
            for _k in range(HAND_FOLD_STEPS):
                D = 0.5 * D + 0.5 * (A @ D) / deg[:, None]
                D[held] = gm[held]
            self.v = self.v + D[weld]
        self.tris = self.tris[~drop]
        self.report["clear_hands"] = {"cuff_triangles_dropped": int(drop.sum()), "skirt_points_behind_hands": int(len(hit))}

    def weights_from_skin(self):
        """A twin piece bends as the skin under it does: each point takes the weights (and the
        body part) of the nearest point of his skin's surface, the three corners' weights by
        where on the face it lies; by its own region's weights a sleeve and the arm in it bent
        apart and the arm came through. The coat's skirt keeps its own (from his hips: a skirt
        that took his thighs' would split like trousers)."""
        from mathutils import Vector
        from mathutils.bvhtree import BVHTree
        body = self.body
        bvh = BVHTree.FromPolygons([tuple(p) for p in body.v], [tuple(int(i) for i in f) for f in body.tris])
        took = 0
        own = self.region.copy()
        bones = list(self.env["bones"])
        arm_cols = [k for k, b in enumerate(bones) if str(b).startswith(("upper_arm", "forearm", "hand", "finger"))]
        # A sleeve takes only its own arm's skin: on its inside, his side is often nearer than
        # his arm, and a sleeve point weighted to his trunk stayed while the arm moved (his arm
        # came through his shirt's sleeve).
        arm_bvh = {}
        if self.shape in ("coat", "shirt"):
            for lr in "rl":
                parts = ["upper_arm_" + lr, "forearm_" + lr, "hand_" + lr]
                fi = np.nonzero(np.isin(body.region[body.tris], parts).all(axis=1))[0]
                if len(fi):
                    arm_bvh[lr] = (BVHTree.FromPolygons([tuple(p) for p in body.v], [tuple(int(i) for i in f) for f in body.tris[fi]]), fi)
        # Which arm a sleeve point belongs to, by its distance from the arm's bone (shoulder to
        # wrist) rather than its region: the inside of a sleeve, near his side, was "trunk", took
        # his side's weights and stayed while the arm moved (a slit down the inside of his sleeve).
        sleeve_of = np.full(len(self.v), None, dtype=object)
        fn = np.cross(self.v[self.tris[:, 1]] - self.v[self.tris[:, 0]], self.v[self.tris[:, 2]] - self.v[self.tris[:, 0]])
        vnorm = np.zeros_like(self.v)
        for k in range(3):
            np.add.at(vnorm, self.tris[:, k], fn)
        # Faces wound either way (Rodin's): each point's normal turned out from his middle.
        mid_x = 0.5 * (self.our_joints()["r-shoulder"][0] + self.our_joints()["l-shoulder"][0])
        flip = vnorm[:, 0] * np.sign(self.v[:, 0] - mid_x) < 0
        vnorm[flip] *= -1
        vnorm /= np.linalg.norm(vnorm, axis=1, keepdims=True) + 1e-12
        if arm_bvh:
            o = self.our_joints()
            for lr in arm_bvh:
                a, b = o[lr + "-shoulder"], o[lr + "-hand"]
                ab = b - a
                t = (self.v - a) @ ab / max(float(ab @ ab), 1e-12)
                d = np.linalg.norm(self.v - (a + np.clip(t, 0, 1)[:, None] * ab), axis=1)
                mine_reg = np.isin(own.astype(str), ["upper_arm_" + lr, "forearm_" + lr])
                near = (t > SLEEVE_FROM) & (t < 1.1) & ((d < SLEEVE_R) | mine_reg)
                # Where his sleeve meets his coat's side (fused: the dressed model's arms hang
                # against it), the side is what lies inside his arm's bone and faces out; the
                # sleeve lies outside it or faces in, towards him. With his hands up the side
                # stretched from his arm to his waist.
                sx = np.sign(a[0])
                bone_x = a[0] + np.clip(t, 0, 1) * ab[0]
                outside = sx * (self.v[:, 0] - bone_x) > -SLEEVE_INNER
                faces_in = (vnorm[:, 0] * -sx) > 0.3
                sleeve_of[near & (outside | faces_in)] = lr
        # Every layer's sleeves bend alike: a sleeve point takes the mean weights of his arm's
        # skin at its place along the arm (shoulder to wrist), whatever lies nearest it. Each
        # layer weighted from its own nearest skin bent its own way, and posed (his arms down
        # from the model's A-pose) his shirt's sleeves came through the coat's.
        profile = getattr(body, "_arm_profile", None)
        if profile is None and arm_bvh:
            profile = body._arm_profile = {}
            o = self.our_joints()
            nb = self.W.shape[1]
            for lr in arm_bvh:
                a, b = o[lr + "-shoulder"], o[lr + "-hand"]
                ab = b - a
                parts = ["upper_arm_" + lr, "forearm_" + lr]
                sel = np.isin(body.region, parts)
                ts = (body.v[sel] - a) @ ab / max(float(ab @ ab), 1e-12)
                edges = np.linspace(SLEEVE_FROM - 0.05, 1.0, 22)
                mids, rows = [], []
                for k in range(len(edges) - 1):
                    m = (ts >= edges[k]) & (ts < edges[k + 1])
                    if m.sum() >= 3:
                        w = body.W[sel][m][:, :nb].mean(0)
                        mids.append(0.5 * (edges[k] + edges[k + 1]))
                        rows.append(w / max(w.sum(), 1e-9))
                profile[lr] = (a, ab, np.array(mids), np.array(rows))
        # Sleeve and side fused below his armpit (the dressed model's arms hang against its
        # sides): the triangles joining them stretched into a wing with his hands up. Cut, as
        # the cloth is cut there; above his armpit the armhole's seam stays.
        if arm_bvh and (self.shape == "shirt" or (self.shape == "coat" and COAT_SIDES_CUT)):
            o = self.our_joints()
            pit_y = 0.5 * (o["r-shoulder"][1] + o["l-shoulder"][1]) - ARMPIT_DROP
            sl = np.array([x is not None for x in sleeve_of])
            mixed = sl[self.tris].any(axis=1) & ~sl[self.tris].all(axis=1)
            low = (self.v[self.tris][:, :, 1] < pit_y).any(axis=1)
            cut = mixed & low
            # What the cut leaves of the side at his armpit is a comb of strips beside the
            # vest's armhole (white teeth, front and back; 2026-10-17: `--hide=Shirt_whole`
            # took them away): the side's cloth near the arm's bone below the armpit, over the
            # upper arm's first COMB_T, goes too. His skin under it is painted the shirt's colour.
            cen = self.v[self.tris].mean(1)
            comb = np.zeros(len(self.tris), bool)
            for lr in arm_bvh:
                a_, b_ = o[lr + "-shoulder"], o[lr + "-elbow"]
                ab = b_ - a_
                t = (cen - a_) @ ab / max(float(ab @ ab), 1e-12)
                d = np.linalg.norm(cen - (a_ + np.clip(t, 0, 1)[:, None] * ab), axis=1)
                comb |= ~sl[self.tris].any(axis=1) & (t > 0) & (t < COMB_T) & (d < SLEEVE_R + COMB_R) & (cen[:, 1] < pit_y)
            self.tris = self.tris[~(cut | comb)]
            self.report["sleeve_side_cut"] = int(cut.sum())
            self.report["armpit_comb_dropped"] = int(comb.sum())
        for i in range(len(self.v)):
            if sleeve_of[i] is not None and profile and sleeve_of[i] in profile:
                a, ab, mids, rows = profile[sleeve_of[i]]
                if len(mids) >= 2:
                    t = float((self.v[i] - a) @ ab / max(float(ab @ ab), 1e-12))
                    self.W[i] = np.array([np.interp(t, mids, rows[:, c]) for c in range(rows.shape[1])])
                    self.W[i] /= max(self.W[i].sum(), 1e-9)
                    self.region[i] = ("upper_arm_" if t < 0.5 else "forearm_") + sleeve_of[i]
                    took += 1
                    continue
            own_arm = sleeve_of[i] if sleeve_of[i] is not None else (str(own[i])[-1] if str(own[i]).startswith(("upper_arm", "forearm")) else None)
            if own_arm in arm_bvh:
                tree_, fi = arm_bvh[own_arm]
                loc, _n, f, _d = tree_.find_nearest(Vector(self.v[i]))
                f = None if f is None else int(fi[f])
            else:
                loc, _n, f, _d = bvh.find_nearest(Vector(self.v[i]))
            if f is None:
                continue
            tri = body.tris[f]
            a, b, c = body.v[tri]
            p = np.array(loc)
            m = np.array([b - a, c - a]).T
            uv_ = np.linalg.lstsq(m, p - a, rcond=None)[0]
            bary = np.clip(np.array([1 - uv_.sum(), uv_[0], uv_[1]]), 0, 1)
            bary /= max(bary.sum(), 1e-9)
            reg = body.region[tri[int(np.argmax(bary))]]
            if self.shape == "coat" and str(reg).startswith(("thigh", "shin", "foot")):
                continue
            # Nor, cloth that isn't a sleeve, his hanging hands' and forearms' (the skirt and the
            # trousers by his hand took the hand's weights and went where it went: "his hands
            # seem like they're melting into the jacket"); and none of his arms' at all (its own
            # weights blend in the arm's capsule by his hand).
            sleeve = (self.shape == "shirt" and sleeve_of[i] is not None) or (
                self.shape == "coat" and str(own[i]).startswith(("upper", "forearm", "hand")))
            # Cloth beside his ribs follows his ribs, not his arm (with his hands up, his coat's
            # and vest's sides stretched from his arms to his waist): a vest has no sleeves, and
            # a coat's or shirt's body is what isn't its sleeve.
            # The coat too since 2026-10-17 (COAT_SIDES_CUT: with his hands up its sides went up
            # with his arms and its tails with them; cut apart they gaped when he stood, showing
            # his skin, which is now painted the coat's own colour under it).
            body_cloth = self.shape == "vest" or (self.shape in ("shirt", "coat") and sleeve_of[i] is None
                                                  and (self.shape == "shirt" or COAT_SIDES_CUT))
            if body_cloth and str(reg).startswith(("upper_arm", "forearm", "hand")):
                w = bary @ body.W[tri][:, :self.W.shape[1]]
                w[arm_cols] = 0.0
                if w.sum() <= 1e-6:
                    w[bones.index("chest")] = 1.0
                self.W[i] = w / w.sum()
                self.region[i] = "trunk"
                took += 1
                continue
            if not sleeve and str(reg).startswith(("forearm", "hand")):
                w = self.W[i].copy()
                w[arm_cols] = 0.0
                if w.sum() <= 1e-6:
                    w[bones.index("pelvis")] = 1.0
                self.W[i] = w / w.sum()
                continue
            w = bary @ body.W[tri][:, :self.W.shape[1]]    # the body's bones only (not his fingers')
            self.W[i] = w / max(float(w.sum()), 1e-9)
            self.region[i] = reg
            took += 1
        self.report["weights_from_skin"] = took
        if self.shape == "coat":
            self.tails_on_pelvis()

    def tails_on_pelvis(self):
        """A coat's skirt behind him hangs from his pelvis alone: taken from the skin round his
        hip joints, its weights carried a share of each thigh's, and standing with his feet apart
        the tails went apart at the vent and showed his trousers (the painting's hang closed);
        sitting, they hang behind the seat. In front and at the sides the skirt keeps its thighs'
        share (on his lap when he sits), eased in between TAILS_FULL and TAILS_NONE degrees from
        straight behind."""
        o = self.our_joints()
        hip = 0.5 * (o["r-upper-leg"] + o["l-upper-leg"])
        bones = list(self.env["bones"])
        legs = [k for k, b in enumerate(bones) if str(b).startswith(("thigh", "shin", "foot", "toe"))]
        pelvis = bones.index("pelvis")
        low = self.v[:, 1] < hip[1] - TAILS_BELOW
        # Behind him: body space faces -Z, so behind is +Z of his hips.
        ang = np.degrees(np.arctan2(self.v[:, 0] - hip[0], self.v[:, 2] - hip[2]))     # 0 straight behind
        k = np.clip((TAILS_NONE - np.abs(ang)) / (TAILS_NONE - TAILS_FULL), 0, 1)
        k = k * k * (3 - 2 * k)
        sel = np.nonzero(low & (k > 0))[0]
        moved = 0
        for i in sel:
            w = self.W[i]
            leg = float(w[legs].sum())
            if leg <= 1e-6:
                continue
            w[legs] *= (1 - k[i])
            w[pelvis] += leg * k[i]
            self.W[i] = w / max(float(w.sum()), 1e-9)
            moved += 1
        self.report["tails_on_pelvis"] = int(moved)

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

def paint_cloth(piece, tone):
    """A twin piece's cloth as painted illustration (DESIGN.md §4; Sean, 2026-10-16): Rodin's
    texture carries a blotchy patchwork (his pictures' blockiness), so it is smoothed (a median of
    CLOTH_MEDIAN texels, then a soft blur) within the piece's own UV islands (what lies outside
    them filled from the nearest inside first, so no seam takes another island's colour); and
    toned to his pictures where people.json `cloth.<shape>` says (`light`: its lightness times
    that, or `L`: its median brought to that Lab lightness; `chroma`: its colour's strength times
    that; the coat's came out darker and greyer than his paintings)."""
    import sys as _sys
    from PIL import ImageFilter
    from scipy import ndimage
    _sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "characters"))
    import portrait as P
    img = piece.colour.convert("RGB")
    W, H = img.size
    tid, _b, _z = P.rasterise(piece.uv * np.array([W, H]), np.zeros(len(piece.uv)), piece.tris, W, H)
    inside = ndimage.binary_dilation(tid >= 0, iterations=2)
    a = np.asarray(img).copy()
    _d, (iy, ix) = ndimage.distance_transform_edt(~inside, return_indices=True)
    a = a[iy, ix]
    if piece.shape == "coat":
        # White on the coat's sides (beyond COAT_SIDE_X of his middle) is Rodin's shirt painted
        # into the fused sleeve-and-side, inside the sleeve in its A-pose: with the sleeves cut
        # from the sides (COAT_SIDES_CUT) it showed as white patches at his ribs and, before
        # that, as white lines at the sleeves' seams. Painted the coat's wool (its median, white
        # left out). The shirt front and tie seen in its opening are within COAT_SIDE_X.
        cen = piece.v[piece.tris].mean(1)
        side_tri = np.abs(cen[:, 0] - float(np.median(cen[:, 0]))) > COAT_SIDE_X
        lum = a @ np.array([0.299, 0.587, 0.114])
        white = (lum > COAT_SIDE_WHITE) & ((a.max(axis=2) - a.min(axis=2)) < COAT_SIDE_SPREAD)
        on = (tid >= 0) & side_tri[np.maximum(tid, 0)] & white
        wool = np.median(a[(tid >= 0) & ~white], axis=0)
        a[on] = wool.astype(a.dtype)
        piece.report["side_white_painted"] = {"texels": int(on.sum()), "wool": [int(x) for x in wool]}
    # Cloth painted from his pictures (twin_pieces --painted) is as smooth as they are: the median
    # (for Rodin's patchwork) only cost it its finest detail (tools/characters/cloth_detail.py,
    # 2026-10-17: the 3 mm band from 0.85 of the picture's to 0.75).
    median = 1 if getattr(piece, "painted", False) else CLOTH_MEDIAN
    img = Image.fromarray(a).filter(ImageFilter.MedianFilter(median)) if median > 1 else Image.fromarray(a)
    if CLOTH_BLUR > 0:
        img = img.filter(ImageFilter.GaussianBlur(CLOTH_BLUR))
    if tone:
        y, cb, cr = [np.asarray(c).astype(np.float64) for c in img.convert("YCbCr").split()]
        y0, cb0, cr0 = y.copy(), cb.copy(), cr.copy()
        # `keep_ends`: what is painted white or black on this cloth (the coat's shirt front and
        # tie) is left as it is; the toning below lifted the tie to grey and its mottle, taking
        # out the narrow white shirt as a blotch, greyed the shirt (Sean, 2026-10-16).
        keep = np.ones_like(y)
        if tone.get("keep_ends"):
            ss = lambda e0, e1, x: np.clip((x - e0) / (e1 - e0), 0, 1)
            keep = (1 - ss(KEEP_WHITE[0], KEEP_WHITE[1], y)) * ss(KEEP_BLACK[0], KEEP_BLACK[1], y)
        # `mottle`: the blotches' share taken out (light and dark between a few texels and a
        # tenth of the texture across: Rodin's camouflage, not the cloth's folds, which are
        # bigger, nor its weave, which is smaller); measured over the toned cloth alone.
        mo = float(tone.get("mottle", 0.0))
        if mo:
            blur = lambda c, r: ndimage.gaussian_filter(c * keep, r) / np.maximum(ndimage.gaussian_filter(keep, r), 1e-3)
            for ch in (y, cb, cr):
                band = blur(ch, MOTTLE_FINE * W / 1024) - blur(ch, MOTTLE_WIDE * W / 1024)
                ch -= mo * band
        light = float(tone.get("light", 1.0))
        if "L" in tone:
            # Lightness to a target (Lab L of the cloth's median, from his pictures): two cuts of
            # the same trousers came out L 5 and L 14, against his paintings' 20.
            covered = tid >= 0
            med = np.median(y[covered]) / 255.0 if covered.any() else 0.5
            lin = lambda c: ((c + 0.055) / 1.055) ** 2.4 if c > 0.04045 else c / 12.92
            L_now = 116 * lin(med) ** (1 / 3) - 16
            target_lin = ((float(tone["L"]) + 16) / 116) ** 3
            light = (target_lin / max(lin(med), 1e-5)) ** (1 / 2.4)
            piece.report["cloth_L"] = {"from": round(L_now, 1), "to": tone["L"], "light": round(light, 2)}
        y = np.clip(y * light, 0, 255)
        k = float(tone.get("chroma", 1.0))
        cb = np.clip(128 + (cb - 128) * k, 0, 255)
        cr = np.clip(128 + (cr - 128) * k, 0, 255)
        y, cb, cr = (keep * t + (1 - keep) * o for t, o in ((y, y0), (cb, cb0), (cr, cr0)))
        img = Image.merge("YCbCr", [Image.fromarray(c.astype(np.uint8)) for c in (y, cb, cr)]).convert("RGB")
    piece.report["cloth"] = {"median": median, "tone": tone}
    return img


def _piece_colours(piece):
    """A garment's median colour and its light colour (the median of its lightest UNDER_SHIRT_LIGHT
    percentile: its cloth in the light, not its tie or shadows)."""
    sc = np.asarray(piece.colour.convert("RGB"), dtype=np.float64)
    h, w = sc.shape[:2]
    uvs = piece.uv[np.unique(piece.tris)]
    samp = sc[np.clip((uvs[:, 1] * h).astype(int), 0, h - 1), np.clip((uvs[:, 0] * w).astype(int), 0, w - 1)]
    lum = samp @ [0.299, 0.587, 0.114]
    return np.median(samp, axis=0), np.median(samp[lum >= np.percentile(lum, UNDER_SHIRT_LIGHT)], axis=0)


def paint_under_garments(p, colour, pieces):
    """His skin under his clothes (all but his forearms, hands and legs, and what is wholly his
    head mesh) painted the colour of the garment over it: never meant to be seen, where it shows
    through a gap it reads as that garment. Each skin triangle casts out from its middle along
    its outward normal (UNDER_REACH): the furthest garment hit is the one over it (the coat over
    the vest over the shirt); under a shirt its light colour (UNDER_SHIRT_LIGHT: the cloth, not
    its tie or shadows), under the rest their median. Painted the shirt's colour everywhere
    (2026-10-17 and before), his skin showed as white lines at a coat's edges and, in the shirt's
    median cream, as tan slits between his sleeves and his vest. His neck is under his collar:
    the shirt's light colour from UNDER_SHIRT_NECK under his neck joint up."""
    import sys as _sys
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    _sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "characters"))
    import portrait as P
    shirt = next((pc for pc in pieces if pc.shape == "shirt"), None)
    cols = {}
    for pc in pieces:
        med, light = _piece_colours(pc)
        cols[pc.shape] = light if pc.shape == "shirt" else med
    tone = cols["shirt"] if shirt is not None else np.median(np.asarray(colour.convert("RGB")).reshape(-1, 3), axis=0)
    trees = {pc.shape: BVHTree.FromPolygons([tuple(q) for q in pc.v], [tuple(int(i) for i in f) for f in pc.tris]) for pc in pieces}
    reg = np.asarray(p.region).astype(str)
    # His neck too (its triangles reach into his head's region: wholly head is his head mesh,
    # replaced by the painted bust; the rest is under his collar).
    head = np.asarray(p.head, bool)
    bare = np.zeros(len(reg), bool)
    for part in ("forearm", "hand", "thigh", "shin", "foot"):
        bare |= np.char.startswith(reg, part)
    # (Head-weighted skin below his collar's top too: the twin's neck reaches into his head's
    # region; above it is his face, which the layered man's bust replaces anyway.)
    low = p.v[:, 1] < COLLAR_TOP_SHARE * float(p.env["head_top"])
    tri = p.tris[(~bare)[p.tris].all(axis=1) & (~head[p.tris].all(axis=1) | low[p.tris].all(axis=1))]
    # Which garment lies over each triangle: cast out from its middle, the furthest hit within
    # UNDER_REACH; outward by the bones where there are any, else the face's own normal.
    out_v = outward_from_bones(p.v, p.region, p.bones())
    fn = np.cross(p.v[tri[:, 1]] - p.v[tri[:, 0]], p.v[tri[:, 2]] - p.v[tri[:, 0]])
    fn /= np.linalg.norm(fn, axis=1, keepdims=True) + 1e-12
    ob = out_v[tri].mean(1)
    has = np.linalg.norm(ob, axis=1) > 0.5
    fn[has & ((fn * ob).sum(1) < 0)] *= -1
    cen = p.v[tri].mean(1)
    over = np.full(len(tri), "", dtype=object)
    for k in range(len(tri)):
        start = Vector(cen[k]) + Vector(fn[k]) * 0.002
        best, best_d = "", -1.0
        for shape, tree in trees.items():
            hit, _n, _f, d = tree.ray_cast(start, Vector(fn[k]), UNDER_REACH)
            if hit is not None and d > best_d:
                best, best_d = shape, d
        if not best:
            # Nothing straight out (the coat's side hangs away from his ribs in the A-pose):
            # the nearest garment within reach, else the shirt's colour.
            best_d = UNDER_REACH
            for shape, tree in trees.items():
                loc, _n, _f, d = tree.find_nearest(Vector(cen[k]), UNDER_REACH)
                if loc is not None and d < best_d:
                    best, best_d = shape, d
        over[k] = best
    G = colour.width
    out = np.asarray(colour.convert("RGB")).copy()
    counts = {}
    for shape in [""] + sorted(trees):
        sel = tri[over == shape]
        if not len(sel):
            continue
        tid, _b, _z = P.rasterise(p.uv * G, np.zeros(len(p.uv)), sel, G, colour.height)
        out[tid >= 0] = (cols.get(shape, tone) if shape else tone).astype(np.uint8)
        counts[shape or "none"] = int(len(sel))
    light = cols["shirt"] if shirt is not None else tone
    nj = p.j["neck"]
    near_axis = np.hypot(p.v[:, 0] - nj[0], p.v[:, 2] - nj[2]) < UNDER_NECK_R
    neck = tri[((p.v[tri, 1] > nj[1] - UNDER_SHIRT_NECK) & near_axis[tri]).all(axis=1)]
    nid, _b, _z = P.rasterise(p.uv * G, np.zeros(len(p.uv)), neck, G, colour.height)
    out[nid >= 0] = light.astype(np.uint8)
    p.report["painted_under_garments"] = {"triangles": counts, "colours": {k: [int(x) for x in v] for k, v in cols.items()},
                                          "neck": int(len(neck)), "neck_colour": [int(x) for x in light]}
    return Image.fromarray(out)


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
    # The skinned hands' finger bones (skinned_hands), children of the hands.
    for name in getattr(person, "extra_bones", []):
        origin, basis = person.finger_rests[name]
        eb = arm_data.edit_bones.new(name)
        eb.head = mp.to_blender(origin)
        eb.tail = mp.to_blender(origin - basis[1] * 0.02)
        eb.parent = arm_data.edit_bones["hand_" + name.split("_")[2]]
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
        names = bones + (getattr(person, "extra_bones", []) if src is person and src.W.shape[1] > len(bones) else [])
        for bname in names:
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
        made.append(make(piece.shape, piece.tris, (TWIN_TRIS if piece.twin else PIECE_TRIS).get(piece.shape, 1500), piece))
    person.report["triangles"] = {o.name.split("_", 1)[1]: sum(len(p.vertices) - 2 for p in o.data.polygons)
                                  for o in made}
    # His own fingers (own_fingers): each bone's piece a plain mesh in the game's rest pose, not
    # skinned (HumanBody hangs it on that finger bone), named finger_<finger>_<side>_<bone>.
    for fid, pieces in getattr(person, "finger_pieces", {}).items():
        for b, (uvs, pos, tris) in enumerate(pieces):
            if not len(tris):
                continue
            mesh = bpy.data.meshes.new("finger_%s_%d" % (fid, b))
            mesh.from_pydata([mp.to_blender(p) for p in pos], [], [[int(i) for i in t] for t in tris])
            uvl = mesh.uv_layers.new(name="UVMap")
            for poly in mesh.polygons:
                poly.use_smooth = True
                for li in poly.loop_indices:
                    u, vv = uvs[mesh.loops[li].vertex_index]
                    uvl.data[li].uv = (u, 1.0 - vv)
            obj = bpy.data.objects.new("finger_%s_%d" % (fid, b), mesh)
            bpy.context.scene.collection.objects.link(obj)
            if len(tris) > FINGER_TRIS:
                # Welded first (seams would open), then thinned: a finger is a few pixels.
                import bmesh
                bm = bmesh.new()
                bm.from_mesh(mesh)
                bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
                bm.to_mesh(mesh)
                bm.free()
                mod = obj.modifiers.new("decimate", "DECIMATE")
                mod.ratio = FINGER_TRIS / max(len(mesh.polygons), 1)
                bpy.context.view_layer.objects.active = obj
                bpy.ops.object.modifier_apply(modifier="decimate")


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
            # Each piece's own texture, in the same squares as his skin's (SQUARE_TEXELS of his
            # model's texels: a twin piece's texture is written at twin_pieces.TEX, half his
            # model's 4096, so it is squared no further; at 2 of its own it was 1024 a side, 3.6 mm
            # a texel against his skin's 1.8, and the vest's pattern lost its edges); a twin
            # piece's cloth smoothed and toned first.
            if piece.twin:
                piece.colour = paint_cloth(piece, spec.get("cloth", {}).get(piece.shape, {}))
            sq_piece = max(1, SQUARE_TEXELS * piece.colour.width // p.colour.width) if piece.twin else SQUARE_TEXELS
            squares(piece.colour, os.path.join(OUT, "%s_%s%s.png" % (pid, piece.shape, "_smooth" if SMOOTH else "")),
                    1 if SMOOTH else sq_piece)
        # His texture: the head repainted in the style where it has been (head_paint.py works on a
        # glb, so a layered man's repaint is his model's, <model>_color.png).
        # people.json `paint`: another man's repaint (the same body in another outfit).
        named = spec.get("paint") or (pid if os.path.exists(os.path.join(TRIPO, pid + "_color.png")) else spec.get("model", pid))
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
        # MakeHuman's hands painted into his texture's free squares (makehuman_hands).
        for paint, (u0, v0, side) in getattr(p, "hand_paint", []):
            px = max(1, int(round(side * colour.width)))
            tile = Image.fromarray((paint * 255).astype(np.uint8)).resize((px, px), Image.LANCZOS)
            colour = colour.copy()
            colour.paste(tile, (int(round(u0 * colour.width)), int(round(v0 * colour.height))))
        # A man in a shirt: his torso's and upper arms' skin in the shirt's colour (never meant
        # to be seen; where it shows between his vest and sleeves it reads as his shirt, not his
        # bare side). His forearms keep their own (his wrist's join is painted from them).
        shirt = [pc for pc in p.pieces if pc.shape == "shirt"]
        if shirt:
            # His bare skin as it was, for neck_ring to match his face to (build/: rebuilt with him).
            sq0 = max(1, SQUARE_TEXELS * colour.width // p.colour.width)
            os.makedirs(os.path.join("build", "bare_skin"), exist_ok=True)
            squares(colour, os.path.join("build", "bare_skin", pid + "_skin.png"), sq0)
            colour = paint_under_garments(p, colour, p.pieces)
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
