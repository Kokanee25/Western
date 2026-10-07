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
     (PeopleBodies lays them on by his UVs); or (people.json `cells`, CELLS) his UVs laid out again
     in whole squares of him, a few texels a side, so the game lights each square as one, the
     squares meeting softly.
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
PIECE_TRIS = {"coat": 2600, "hat": 700, "hair": 2400}
PIECE_MARGIN = {"coat": 1.06, "hat": 1.05}
# Long hair (people.json `hair`: true, or any of these to change; class Hair): how far round from
# the back of his head it reaches each side (degrees; 180 is his nose), where it ends at the latest
# (metres up: his collar), how thick it lies at its top and its ends, how far in it falls below the
# widest of his head above it (metres a metre down: closer to his neck than a curtain from his ears
# would hang), how wide a lock is (degrees, from-to), how much shorter a lock can be than the
# longest and how far its pointed end reaches, how much fuller a lock is at its middle than its
# edges (metres; and up to how much fuller one lock is than the next, at its end), how it waves
# down its length (metres out, waves along it), over how many degrees it thins to its front edge
# beside his face and how that edge waves in and out down its length (degrees, waves along it),
# the shell's grid (rows down, degrees round), the squares (metres, cut in his body's space as
# head_paint.py's are), its texture's size, its five tones (shares of his painted hair's middle
# colour), how much of it each is and how far they're greyed, and how many squares long a strand
# of one tone runs down it, and how much shorter it is beside his face than at the back (metres at
# its front edge, from how many degrees round). Lank and close to his head, in long dark strands,
# longest at the back: fuller, rounder locks speckled with light squares read as a poodle's curls,
# and as long beside his face as behind, a curtain (Sean, 2026-10-06).
HAIR = {"front_deg": 104.0, "to": 1.49, "thick": [0.002, 0.006], "taper": 0.12, "lock_deg": [10.0, 20.0],
        "ragged": 0.01, "tip": 0.005, "bulge": [0.0005, 0.0015], "wave": [0.0015, 1.0], "thin": 14.0,
        "edge": [5.0, 1.7], "rows": 40, "step_deg": 2.0, "cell_m": 0.008, "texels": [512, 256],
        "tones": [0.35, 0.6, 0.85, 1.1, 1.4], "share": [0.28, 0.34, 0.22, 0.11, 0.05], "grey": 0.35,
        "strand_cells": 5, "short": [0.055, 55.0], "seed": 1882}
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
# A texel a square (people.json `cells`: true, or any of these to change; --cells=key:value,... to
# try some; cell_layout): his texture laid out again in whole squares of him, each a few texels a
# side lit as one (`head_texels` on his head, so his eyes can be drawn finer than his squares;
# `body_texels`, `hair_texels`), so the game lights each square as one flat tone, as the
# painting's are; in his model's own atlas a square was ~16 texels a side and the light ran smooth
# across it, so his squares melted into a smooth face. A square is the cell of `head`,
# `body` or `hair` metres a surface meets on the plane square to the way it faces (one of six, along
# his body's axes, as head_paint.py's cells are): the mesh's UVs are that plane, cut into islands
# where a sheet folds over itself and packed `gutter` squares apart. Each square's colour comes from
# the plain repaint (head_paint.py with no cells of its own) by in_cells' rules: its middle sample by
# lightness, or on his head the darker part where DARK_SHARE of it is darker by DARK_GAP (a brow, a
# moustache's edge), from `samples` a texel a side (head, below). A square of his head within
# `eye_zone` of a drawn eye (metres across, up, deep) keeps its texels, each the colour most of it
# is: at three texels a square (2.7 mm) his eyes came out squinting and smudged, at six (1.3 mm)
# as drawn.
# Inside a square (a whole square is still lit as one): the painting's squares meet with soft
# edges and aren't one flat tone edge to edge (the character judge: ours were flatter, 0.76 of
# neighbouring lit pixels within 1 L* to its 0.65, and harder edged). So a texel within `soft` of a
# square's edge (a share of the square: {shape: share}, `skin` for any not named) leans toward the
# square across it, half way at the edge; first each square moves `calm` toward the squares round
# it of near colour (within about `calm_sigma` levels), so blotches calm and a brow keeps its edge.
# The body and hair are `body_texels` / `hair_texels` texels a square, so there are texels to carry
# it; the squares round a drawn eye are left as they are. `detail` keeps that share of each texel's
# own painted colour inside its square (at most `detail_clip` levels): tried at 0.12-0.3 it made his
# squares noisier and his face smeared, and the judge agreed, so it's off. A negative `calm` draws
# the painter's mottle bolder instead (_inside_squares).
# The weave: the bold painting's coat is a tweed drawn square by square, each square a shade off the
# next in diagonal rows (its lit squares differ from their neighbours by ~5-6 L* where the painter's
# coat, cut into our squares, differs by ~3: its mottle runs in patches of a few squares, so
# drawing it bolder made blotches, not tweed). `weave` ({shape: share}) draws a twill over the
# painter's colours: on each facing's plane the squares run in diagonal rows `weave_period` squares
# apart, half a period lighter and half darker by that share, mixed with `weave_noise` of a shade
# of each square's own (a hash of where it is, so it repeats), on cloth only: squares no lighter
# than `weave_max_l` L*, not skin-coloured, and further than `weave_hand` metres from his hands. On
# his head it's his hat's felt: only squares `weave_head_above` metres over his eyes (his brows
# and moustache keep their drawing), `weave_head_noise` of it each square's own shade (felt has
# no rows).
# His face (Sean, 2026-10-07: "He's gone too cartoony ... It's the face the most"): the bold
# painting draws a face in finer squares than the hat over it (about 20 across his face where 9 mm
# gave 15), so `face` (metres, 0 = the head's own) squares the part of his head within `face_box` of
# his drawn eyes (across either side of their middle, above them, below them, behind them) on
# islands of its own. `dark_kept` (0 or 1) keeps the darker-part rule on his head: with it his
# brows, moustache and the hair by his ears went to flat near-black slabs.
# The grain (2026-10-07): in the painting two neighbouring pixels on its man are almost never the
# same (14-23 % of lit pairs within 0.25 L*: a faint paint texture inside every square), where a
# texel a square left 40-55 % of ours exactly the same. `grain` ({shape: L*}) lays a faint grain
# over the texels inside the squares, `grain_size` texels across (a Gaussian's sigma: a grain a
# texel wide made his edges read harder), the same every fit; the squares round a drawn eye keep
# their texels. `face_front` (degrees, 0 = off) puts his face's triangles within that of straight
# ahead on the front plane: a cheek turned past 45 degrees went on a side plane, whose squares drew
# as thin upright strips from in front (and his moustache's edge now steps in squares, as the
# painting's does). `weave_cluster` runs each square's own shade a little into the shades of the
# squares beside it (half that above and below): the bold painting's coat has no rows, its squares
# a little alike one across (0.28 at one square across, 0.12 down), and the twill's rows, met at a
# fold from two planes, drew chevrons. `settle` (passes) and `settle_margin`: where a surface turns
# near 45 degrees between two planes, a triangle that near the line takes whichever of its two
# planes more of its neighbours are on, so the line runs clean, not ragged triangle by triangle
# (his body's islands 512 → 251). `mottle` ({shape: share}): the painting's skin is a mosaic of
# near tones, each square a shade off the next, where ours ran smooth from square to square; each
# square of his skin (warm-coloured, under his hat, not round his drawn eyes) is that share lighter
# or darker by its own shade (the weave's hash, with `weave_cluster`).
CELLS = {"head": 0.008, "body": 0.009, "hair": 0.008, "head_texels": 6, "body_texels": 3, "hair_texels": 3,
         "gutter": 1, "samples": [2, 2], "eye_zone": [0.019, 0.008, 0.03],
         "detail": 0.0, "detail_clip": 40.0, "soft": {"head": 0.17, "skin": 0.25},
         "calm": {"head": 0.4, "skin": 0.25}, "calm_sigma": 25.0,
         "weave": {"head": 0.0, "skin": 0.0}, "weave_period": 4, "weave_noise": 0.5, "weave_max_l": 46.0,
         "weave_hand": 0.075, "weave_head_noise": 1.0, "weave_head_above": 0.035, "dark_kept": 1,
         "face": 0.0, "face_box": [0.08, 0.03, 0.16, 0.07], "grain": {"head": 0.0, "skin": 0.0}, "grain_size": 0.8,
         "face_front": 0.0, "weave_cluster": 0.0, "settle": 0, "settle_margin": 0.2,
         "mottle": {"head": 0.0, "skin": 0.0}, "collar": 0.0, "collar_box": [0.11, 0.10, 0.36, 0.09]}
DARK_SHARE = 0.3
DARK_GAP = 30.0
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
            if "shape" in spec:
                # He wears his paint on another glb of the same mesh (people.json `shape`: the same
                # points, triangles and UVs, moved): his views were painted on `rodin` and are baked
                # onto it, and the paint stays on its points when they move. The stylised stranger's
                # paint on the Rodin man as made: the caricature's heavier brow, wider jaw and
                # bigger moustache read as a cartoon (Sean, 2026-10-07).
                spos, snrm, suv, stris, sjoints, _c = load_rodin(os.path.join(TRIPO, spec["shape"] + ".glb"))
                if len(spos) != len(pos) or not np.array_equal(stris, tris) or not np.allclose(suv, uv):
                    raise SystemExit("%s: `shape` %s isn't the same mesh as %s" % (pid, spec["shape"], self.model))
                pos, nrm, joints = spos, snrm, sjoints
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
        if "shape" in spec:
            self.report["shape"] = spec["shape"]
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
        if self.spec.get("hair"):
            self.pieces.append(Hair(self, self.spec["hair"]))


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

class Hair:
    """Long hair as its own piece ("body_hair", <id>_hair.png): Sean, 2026-10-06, wants the painting's
    man, whose hair hangs to his collar; the Rodin stranger was built from a picture with it short.
    Made after the warp, in our body space: a shell round the back and sides of his head, from under
    his hat's brim to his collar. A ray out from his head's axis at each height and bearing finds his
    surface; the hair falls from the widest of him above it, a little inward toward his neck (over his
    ears, clear of his jaw), and rests on whatever comes out to meet it (his collar), ending at
    HAIR's `to` at the latest, in locks of uneven width and length with pointed ends, a little rounded
    and waving, thinner toward his face. Skinned from the nearest
    of his own points (his head at the top, his collar at the ends), its squares cut in his body's
    space as head_paint.py cuts his, each a tone of his own painted hair (the texels the shell hides),
    and lit by the game like the rest of him. It can be hidden or come off with nothing else."""

    shape = "hair"
    square = 1           # its texture is already in squares (main(): no squares() over it)

    def __init__(self, body, spec):
        o = dict(HAIR, **(spec if isinstance(spec, dict) else {}))
        # His colours: the repaint in the style where there is one (main() lays the same on him).
        named = body.id if os.path.exists(os.path.join(TRIPO, body.id + "_color.png")) else body.spec.get("model", body.id)
        painted = os.path.join(TRIPO, named + "_color.png")
        colour = Image.open(painted) if os.path.exists(painted) else body.colour
        self.body = body
        self.report = body.report.setdefault("piece_hair", {})
        v = body.v
        eye_y = float(body.anatomy_eyes()[:, 1].mean())
        # His head's axis, and how far out his head reaches (the brim beyond it is not head): from
        # a band under the hat's brim, half way between his face and the back of his head.
        band = body.head & (np.abs(v[:, 1] - (eye_y - 0.03)) < 0.01)
        z0 = float((v[band, 2].min() + v[band, 2].max()) / 2)
        self.z0 = z0
        reach = (float(np.abs(v[band, 0]).max()) + 0.05, float(v[band, 2].max() - z0) + 0.04)
        th = np.radians(np.arange(-o["front_deg"], o["front_deg"] + 1e-6, o["step_deg"]))
        ys = np.arange(o["to"] - 0.04, eye_y + 0.14, 0.002)
        R = self._radii(v, body.tris, th, ys, z0, reach)
        rows, n = o["rows"], len(th)
        # Under the brim: up from the band, the first height his head isn't there any more (only the
        # brim, past his head's reach) or jumps outward (the brim curled down, the crown).
        k0 = int(np.searchsorted(ys, eye_y - 0.03))
        top, bottom = np.zeros(n), np.zeros(n)
        curtain = np.zeros((n, len(ys)))
        for i in range(n):
            k = k0
            while k + 1 < len(ys) and not np.isnan(R[i, k + 1]) and R[i, k + 1] - R[i, k] < 0.02:
                k += 1
            top[i] = ys[k] + 0.004             # just into the brim, so its edge is hidden
            # The curtain: the widest of him above each height, down from the top.
            r = np.nan_to_num(R[i], nan=0.0)
            c = np.zeros(len(ys))
            run, at = 0.0, ys[k]
            for kk in range(k, -1, -1):
                if r[kk] >= run:
                    run, at = r[kk], ys[kk]
                c[kk] = run - o["taper"] * (at - ys[kk])
            curtain[i] = c
            # It ends where he comes out to meet it (his collar, his shoulders), lying on it a
            # centimetre, and at `to` at the latest.
            end = o["to"]
            for kk in range(k, -1, -1):
                if ys[kk] < eye_y - 0.06 and r[kk] > c[kk] + o["thick"][1] * 0.5:
                    end = max(o["to"], ys[kk] - 0.01)
                    break
            bottom[i] = end
        # Shorter beside his face than at the back (as long all round, it hung like a curtain).
        facing = np.clip((np.abs(np.degrees(th)) - o["short"][1]) / (o["front_deg"] - o["short"][1]), 0, 1)
        bottom = bottom + o["short"][0] * facing ** 1.5
        # Locks of uneven length with pointed ends (the painting's hair ends in ragged locks).
        rng = np.random.default_rng(o["seed"])
        deg = np.degrees(th)
        edges = [-o["front_deg"] - rng.uniform(0, o["lock_deg"][1])]
        while edges[-1] < o["front_deg"]:
            edges.append(edges[-1] + rng.uniform(*o["lock_deg"]))
        self.edges = np.array(edges)
        lock = np.searchsorted(self.edges, deg) - 1
        cut = rng.uniform(0, o["ragged"], len(edges))[lock]
        frac = (deg - self.edges[lock]) / (self.edges[lock + 1] - self.edges[lock])
        bottom = bottom + cut + o["tip"] * np.abs(frac * 2 - 1) ** 1.3
        bottom = np.minimum(bottom, top - 0.03)
        # Each lock rounded (fuller at its middle than its edges), one fuller than the next toward
        # its end, and waving a little down its length: his outline is locks, not a slab.
        full = rng.uniform(0, o["bulge"][1], len(edges))[lock]
        phase = rng.uniform(0, 2 * np.pi, len(edges))[lock]
        mid = 1.0 - (frac * 2 - 1) ** 2
        # Thin toward its front edge, beside his face (a slab there read as a frame round it).
        thin = np.clip((o["front_deg"] - np.abs(deg)) / o["thin"], 0.35, 1.0)
        # The grid: rows from his brim to the ends of his hair, a column a bearing.
        t = np.linspace(0, 1, rows + 1)
        Y = top[:, None] + (bottom - top)[:, None] * t[None, :]
        thick = o["thick"][0] + (o["thick"][1] - o["thick"][0]) * t
        rad = np.zeros_like(Y)
        for i in range(n):
            ri = np.interp(Y[i], ys, np.nan_to_num(R[i], nan=0.0))
            ci = np.interp(Y[i], ys, curtain[i])
            rad[i] = (np.maximum(ri, ci) + thin[i] * (thick + mid[i] * (o["bulge"][0] + full[i] * t))
                      + o["wave"][0] * t * np.sin(2 * np.pi * o["wave"][1] * t + phase[i]))
        # The edge beside his face waves in and out down its length (a straight edge read as a strap),
        # the columns behind it following less and less.
        near = np.clip(1.0 - (o["front_deg"] - np.abs(deg)) / o["thin"], 0.0, 1.0)[:, None]
        side = np.sign(deg)[:, None]
        jag = np.sin(2 * np.pi * o["edge"][1] * t + rng.uniform(0, 2 * np.pi))[None, :]
        ang = th[:, None] - np.radians(o["edge"][0]) * side * near * (0.5 + 0.5 * jag)
        X = rad * np.sin(ang)
        Z = z0 + rad * np.cos(ang)
        self.v = np.stack([X, Y, Z], -1).reshape(-1, 3)
        self.uv = np.stack(np.meshgrid(np.linspace(0, 1, n), t, indexing="ij"), -1).reshape(-1, 2)
        idx = np.arange(n * (rows + 1)).reshape(n, rows + 1)
        a, b, c_, d = idx[:-1, :-1], idx[1:, :-1], idx[1:, 1:], idx[:-1, 1:]
        tris = np.concatenate([np.stack([a, b, c_], -1).reshape(-1, 3), np.stack([a, c_, d], -1).reshape(-1, 3)])
        # Facing out from his head.
        f = self.v[tris]
        nrm = np.cross(f[:, 1] - f[:, 0], f[:, 2] - f[:, 0])
        out = f.mean(1) - np.array([0.0, 0.0, z0])
        out[:, 1] = 0
        if (np.einsum("ij,ij->i", nrm, out) < 0).mean() > 0.5:
            tris = tris[:, [0, 2, 1]]
        self.tris = tris
        self.W = self._weights(body)
        self.colour = self._texture(body, colour, o, n, rows)
        self.report.update({"vertices": int(len(self.v)), "triangles_made": int(len(tris)),
                            "axis_z": round(z0, 4), "top_m": [round(float(top.min()), 3), round(float(top.max()), 3)],
                            "ends_m": [round(float(bottom.min()), 3), round(float(bottom.max()), 3)],
                            "front_deg": o["front_deg"]})
        print("  hair: %d points, from %.3f-%.3f m down to %.3f-%.3f m, %d deg each side" % (
            len(self.v), top.min(), top.max(), bottom.min(), bottom.max(), o["front_deg"]))

    @staticmethod
    def _radii(v, tris, th, ys, z0, reach):
        """How far out from his head's axis (x 0, z z0) he is, along each bearing at each height: the
        furthest of his surface within his head's reach there (an ellipse, `reach` to his side and
        behind), NaN where there's none (the brim alone)."""
        P = v[tris]
        lim = 1.0 / np.sqrt((np.sin(th) / reach[0]) ** 2 + (np.cos(th) / reach[1]) ** 2)
        dirs = np.stack([np.sin(th), np.cos(th)], 1)
        R = np.full((len(th), len(ys)), np.nan)
        for k, y in enumerate(ys):
            s = P[:, :, 1] - y
            over = s > 0
            cross = over.any(1) & (~over).any(1)
            if not cross.any():
                continue
            Q, S = P[cross], s[cross]
            ends = []
            for a, b in ((0, 1), (1, 2), (2, 0)):
                m = (S[:, a] > 0) != (S[:, b] > 0)
                f = S[:, a] / np.where(m, S[:, a] - S[:, b], 1.0)
                pt = Q[:, a] + f[:, None] * (Q[:, b] - Q[:, a])
                ends.append(np.where(m[:, None], pt[:, [0, 2]], np.nan))
            ends = np.stack(ends, 1)                       # (m, 3 edges, 2): two are the segment's ends
            ok = ~np.isnan(ends[:, :, 0])
            order = np.argsort(~ok, axis=1, kind="stable")[:, :2]
            seg = np.take_along_axis(ends, order[:, :, None], 1)
            seg = seg[ok.sum(1) == 2]
            A = seg[:, 0] - np.array([0.0, z0])
            E = seg[:, 1] - seg[:, 0]
            dx, dz = dirs[:, 0:1], dirs[:, 1:2]
            den = dx * E[None, :, 1] - dz * E[None, :, 0]
            with np.errstate(divide="ignore", invalid="ignore"):
                tt = (A[None, :, 0] * E[None, :, 1] - A[None, :, 1] * E[None, :, 0]) / den
                uu = (A[None, :, 0] * dz - A[None, :, 1] * dx) / den
            hit = (np.abs(den) > 1e-12) & (tt > 0) & (uu >= 0) & (uu <= 1) & (tt <= lim[:, None])
            best = np.where(hit, tt, -1.0).max(1)
            R[:, k] = np.where(best > 0, best, np.nan)
        return R

    def _weights(self, body, k=8):
        """Each point's bone weights from the nearest of his own (his head's at the top of the hair,
        his collar's at its ends), by inverse distance."""
        W = np.zeros((len(self.v), body.W.shape[1]))
        for s0 in range(0, len(self.v), 512):
            p = self.v[s0:s0 + 512]
            d = np.linalg.norm(body.v[None, :, :] - p[:, None, :], axis=2)
            near = np.argpartition(d, k, axis=1)[:, :k]
            dn = np.take_along_axis(d, near, 1)
            w = 1.0 / (dn + 0.005)
            W[s0:s0 + 512] = np.einsum("ij,ijk->ik", w, body.W[near]) / w.sum(1, keepdims=True)
        return W / np.maximum(W.sum(1, keepdims=True), 1e-9)

    def _texture(self, body, colour, o, n, rows):
        """Its texture: squares of `cell_m` in his body's space, each one tone of his painted hair
        (the lightness quantiles of the texels the shell hides), darker between locks and at their
        ends, so it reads as hair in the paintings' blocks; flat, as his paint is, for the game to
        light."""
        tw, th_ = o["texels"]
        # His hair's own colours: what the shell's top half hides on his head.
        col = np.asarray(colour.convert("RGB"), dtype=np.float64)
        ch, cw = col.shape[:2]
        top_half = self.v.reshape(n, rows + 1, 3)[:, : rows // 2].reshape(-1, 3)
        d = np.linalg.norm(body.v[None, ::3, :] - top_half[::7, None, :], axis=2)
        near = np.unique(np.argmin(d, axis=1)) * 3
        px = np.clip((body.uv[near] * [cw, ch]).astype(int), 0, [cw - 1, ch - 1])
        hair = col[px[:, 1], px[:, 0]]
        light = hair.mean(1)
        hair = hair[light < np.percentile(light, 85)]        # not the odd lit or skin texel
        # Five tones of his hair's own colour, spread in lightness round its middle (his painted
        # hair's own quantiles bunch together: a slab of one dark).
        mid = np.median(hair, axis=0)
        tones = mid[None, :] * np.array(o["tones"])[:, None]
        tones = np.clip(tones + (tones.mean(1, keepdims=True) - tones) * o["grey"], 0, 255)
        self.report["tones"] = tones.round().astype(int).tolist()
        # Each texel's place on him (the grid's points, bilinear), and its square.
        G = self.v.reshape(n, rows + 1, 3)
        u = (np.arange(tw) + 0.5) / tw * (n - 1)
        w = (np.arange(th_) + 0.5) / th_ * rows
        i0 = np.clip(np.floor(u).astype(int), 0, n - 2)
        j0 = np.clip(np.floor(w).astype(int), 0, rows - 1)
        fu, fw = (u - i0)[None, :, None], (w - j0)[:, None, None]
        g00 = G[i0[None, :], j0[:, None]]
        g10 = G[i0[None, :] + 1, j0[:, None]]
        g01 = G[i0[None, :], j0[:, None] + 1]
        g11 = G[i0[None, :] + 1, j0[:, None] + 1]
        p = (g00 * (1 - fu) + g10 * fu) * (1 - fw) + (g01 * (1 - fu) + g11 * fu) * fw   # (th_, tw, 3)
        cell = np.floor(p / o["cell_m"]).astype(np.int64)
        key = (cell[..., 0] * 73856093) ^ (cell[..., 1] * 19349663) ^ (cell[..., 2] * 83492791)
        rnd = ((key * 2654435761 + o["seed"]) % 1000003) / 1000003.0
        # Its locks (the same bearings the ends were cut by), each a tone of its own, and strands down
        # them: a cell takes its strand's tone (a column of cells a few long) more than its own.
        deg = np.degrees(np.arctan2(p[..., 0], p[..., 2] - self.z0))
        lk = np.clip(np.searchsorted(self.edges, deg) - 1, 0, len(self.edges) - 2)
        lrnd = (((lk + 7) * 40503 + o["seed"]) % 997) / 997.0
        strand = (cell[..., 0] * 73856093) ^ (cell[..., 2] * 83492791) ^ ((cell[..., 1] // o["strand_cells"]) * 19349663)
        srnd = ((strand * 2654435761 + o["seed"] * 7) % 1000003) / 1000003.0
        down = (np.arange(th_)[:, None] + 0.5) / th_
        score = 0.25 * lrnd + 0.6 * srnd + 0.15 * rnd - 0.08 * (down > 0.9)
        level = np.clip(np.digitize(score, np.quantile(score, np.cumsum(o["share"])[:-1])), 0, 4)
        img = tones[level]
        return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


def squares(colour, out_path, square=SQUARE_TEXELS):
    """The texture in squares: each `square`×`square` block one colour (its average), one texel
    a square in the written image."""
    a = np.asarray(colour.convert("RGB"), dtype=np.float64)
    h, w = a.shape[:2]
    hs, ws = (h // square) * square, (w // square) * square
    blocks = a[:hs, :ws].reshape(hs // square, square, ws // square, square, 3).mean(axis=(1, 3))
    Image.fromarray(np.clip(blocks, 0, 255).astype(np.uint8)).save(out_path)
    return blocks.shape[1], blocks.shape[0]


# --- A texel a square (CELLS) ---------------------------------------------------------------------

# The plane each facing is laid on (u and v along his body's axes; v runs down the picture).
_PLANES = {0: ((0, 0, -1), (0, -1, 0)), 1: ((0, 0, 1), (0, -1, 0)),   # -X, +X
           2: ((1, 0, 0), (0, 0, 1)), 3: ((1, 0, 0), (0, 0, -1)),     # -Y, +Y
           4: ((-1, 0, 0), (0, -1, 0)), 5: ((1, 0, 0), (0, -1, 0))}   # -Z, +Z


def _lab(rgb):
    """CIE L*a*b* (D65) of sRGB colours (0-255, any shape ending in 3)."""
    c = np.asarray(rgb, dtype=np.float64) / 255.0
    lin = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    xyz = lin @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0, 500.0 * (f[..., 0] - f[..., 1]), 200.0 * (f[..., 1] - f[..., 2])], -1)


def _square_hash(bi, bj, bf):
    """A shade from -1 to 1 for each square at (column, row, facing) on its facing's plane, the
    same every fit."""
    hsh = (bi.astype(np.uint64) * np.uint64(73856093)) ^ (bj.astype(np.uint64) * np.uint64(19349663)) ^ \
        ((bf + 7).astype(np.uint64) * np.uint64(83492791))
    hsh = (hsh ^ (hsh >> np.uint64(13))) * np.uint64(1274126177)
    return ((hsh >> np.uint64(16)) & np.uint64(1023)).astype(np.float64) / 1023.0 * 2.0 - 1.0


def _weave(blocks, eye, plane, weave, period, noise, max_l, hands, hand_r, above=None, cluster=0.0, mottle=0.0):
    """The squares of `blocks` (rows of squares × columns × RGB) with the weave drawn over the
    cloth among them (CELLS `weave`): `plane` is each square's (column, row, facing) on its facing's
    plane and its middle in our body space (facing -1: no square there); `above`, a height in our
    body space the cloth must be over (his hat); `cluster`, how much of the shades of the squares
    beside it (and half that above and below) each square's own shade takes. `mottle`: his skin's
    squares (under `above` on his head) each that share lighter or darker by its own shade, as the
    painting's skin is a mosaic of near tones (CELLS `mottle`)."""
    bi, bj, bf, bpos = plane
    lab = _lab(blocks)
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    hue = np.degrees(np.arctan2(lab[..., 2], lab[..., 1]))
    skin = (chroma > 20) & (hue > 35) & (hue < 80) & (lab[..., 0] > 35)
    cloth = (bf >= 0) & ~eye & (lab[..., 0] <= max_l) & ~skin
    for h in hands:
        cloth &= np.linalg.norm(bpos - np.asarray(h), axis=-1) > hand_r
    if above is not None:
        cloth &= bpos[..., 1] > above
    # Diagonal rows (a twill): half a period of squares lighter, half darker.
    twill = np.where((bi + bj) % period < period / 2.0, 1.0, -1.0)
    # Each square's own shade: a hash of where it is, the same every fit; with `cluster`, run
    # together with its neighbours' a little, mostly across (the bold painting's coat: no rows, its
    # squares' shades a little alike one square across, less one square down), its spread kept.
    own = _square_hash(bi, bj, bf)
    if cluster > 0:
        own = (own + cluster * (_square_hash(bi - 1, bj, bf) + _square_hash(bi + 1, bj, bf))
               + 0.5 * cluster * (_square_hash(bi, bj - 1, bf) + _square_hash(bi, bj + 1, bf)))
        own /= np.sqrt(1.0 + 2.5 * cluster * cluster)
    shade = 1.0 + weave * ((1.0 - noise) * twill + noise * own)
    out = np.where(cloth[..., None], blocks * shade[..., None], blocks)
    if mottle > 0:
        # His skin's squares, his stubble's too (warm, not grey: his brows and moustache aren't),
        # away from his drawn eyes and under his hat.
        warm = (bf >= 0) & ~eye & (chroma > 12) & (hue > 30) & (hue < 85) & (lab[..., 0] > 22)
        if above is not None:
            warm &= bpos[..., 1] <= above
        out = np.where(warm[..., None], out * (1.0 + mottle * own)[..., None], out)
        print("    his skin mottled on %d squares" % int(warm.sum()))
    return out, int(cloth.sum())


def _grain(shape, size, seed=1882):
    """A field of grain the size of `shape` (rows, columns): noise blurred `size` texels across (a
    Gaussian's sigma, wrapped at the edges), at unit RMS, the same for the same shape every time."""
    rng = np.random.default_rng(seed + shape[0] * 7919 + shape[1])
    g = rng.standard_normal(shape)
    if size > 0:
        r = max(1, int(3.0 * size + 0.5))
        x = np.arange(-r, r + 1)
        kern = np.exp(-x * x / (2.0 * size * size))
        kern /= kern.sum()
        for axis in (0, 1):
            g = sum(w * np.roll(g, int(d), axis=axis) for w, d in zip(kern, x))
    return g / max(float(np.sqrt((g * g).mean())), 1e-9)


def _inside_squares(img, k, W, rgb, lum, tx, ty, eye_blocks, detail, clip, soft, calm=0.0, sigma=25.0,
                    weave=0.0, plane=None, weave_opts=None, grain=0.0, grain_size=0.8):
    """The inside of each k×k square of `img` (filled, rows down): `detail` of each texel's own
    painted colour (the middle of its samples by lightness: `rgb`, `lum` at texels `tx`, `ty`) less
    its square's, at most `clip` levels; and within `soft` of a square's edge (a share of the
    square) a lean toward the square across it, half way at the edge, so neighbouring squares meet
    softly. First, `calm`: each square moves that share toward the squares round it, each weighed
    by how near its colour is (a Gaussian of `sigma` levels), so blotches of near tones calm while
    a brow or a moustache against skin keeps its edge. A negative `calm` moves it away from them
    instead: its difference from the near-coloured squares round it grows by that share, so the
    painter's own mottle (a coat's tweed) is drawn bolder, and an edge between two colours, whose
    squares weigh nothing to each other, stays where it was. The squares in `eye_blocks` (block keys, rows
    of W // k + 1) keep their texels, and their neighbours don't lean toward them (for that they
    stand as the mean of the squares round them). Last, `grain` L* of a faint grain `grain_size`
    texels across over every texel but the eyes' (CELLS)."""
    H = img.shape[0]
    nby, nbx = H // k, W // k
    blocks = img.reshape(nby, k, nbx, k, 3).mean(axis=(1, 3))
    eye = np.zeros((nby, nbx), dtype=bool)
    if eye_blocks is not None:
        by_, bx_ = np.divmod(np.unique(eye_blocks), W // k + 1)
        eye[by_, bx_] = True
    BY, BX = np.arange(H) // k, np.arange(W) // k
    out = img.copy()
    if calm != 0:
        acc = np.zeros_like(blocks)
        num = np.zeros((nby, nbx))
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy or dx:
                    nb = np.roll(blocks, (dy, dx), axis=(0, 1))
                    w = np.exp(-((nb - blocks) ** 2).sum(-1) / (2.0 * sigma * sigma)) * np.roll(~eye, (dy, dx), axis=(0, 1))
                    acc += w[..., None] * nb
                    num += w
        moved = np.where((num > 1e-6)[..., None], calm * (acc / np.maximum(num, 1e-6)[..., None] - blocks), 0.0)
        moved[eye] = 0.0
        out += moved[BY][:, BX]
        blocks = blocks + moved
    if (weave > 0 or (weave_opts or {}).get("mottle", 0.0) > 0) and plane is not None:
        woven, n = _weave(blocks, eye, plane, weave, **(weave_opts or {}))
        out += (woven - blocks)[BY][:, BX]
        blocks = woven
        print("    the weave on %d squares" % n)
    if soft > 0:
        lean = blocks.copy()
        if eye.any():
            acc = np.zeros_like(lean)
            num = np.zeros((nby, nbx))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if dy or dx:
                        acc += np.roll(lean * (~eye)[..., None], (dy, dx), axis=(0, 1))
                        num += np.roll((~eye).astype(np.float64), (dy, dx), axis=(0, 1))
            lean[eye & (num > 0)] = (acc / np.maximum(num, 1.0)[..., None])[eye & (num > 0)]
        off = (np.arange(k) + 0.5) / k - 0.5                     # a texel's offset from its square's middle
        wgt = 0.5 * np.clip(1.0 - (0.5 - np.abs(off)) / soft, 0.0, 1.0)
        step = np.sign(off).astype(np.int64)
        wx, wy = wgt[np.arange(W) % k], wgt[np.arange(H) % k]
        NX = np.clip(BX + step[np.arange(W) % k], 0, nbx - 1)
        NY = np.clip(BY + step[np.arange(H) % k], 0, nby - 1)
        c = lean[BY][:, BX]
        cx, cy, cxy = lean[BY][:, NX], lean[NY][:, BX], lean[NY][:, NX]
        wx3, wy3 = wx[None, :, None], wy[:, None, None]
        out += wx3 * (cx - c) + wy3 * (cy - c) + wx3 * wy3 * (cxy - cx - cy + c)
    if detail > 0:
        # Each texel's own colour: the middle of its samples by lightness.
        tkey = ty * W + tx
        tks, tinv = np.unique(tkey, return_inverse=True)
        tinv = tinv.ravel()
        cnt = np.bincount(tinv)
        srt = np.lexsort((lum, tinv))
        start = np.concatenate([[0], np.cumsum(cnt)[:-1]])
        fine = np.zeros_like(img)
        got = np.zeros(img.shape[:2], dtype=bool)
        fine[tks // W, tks % W] = rgb[srt[start + cnt // 2]]
        got[tks // W, tks % W] = True
        d = fine - blocks[BY][:, BX]
        big = np.abs(d).max(axis=-1, keepdims=True)
        d *= np.minimum(1.0, clip / np.maximum(big, 1e-6))
        out += detail * d * got[..., None]
    if grain > 0:
        # As a change of lightness: a share of the colour that moves L* by about `grain` (sRGB's
        # gamma ~2.2, L* ~ the cube root of the light), so a dark square's grain is as faint as a
        # light one's.
        dl = grain * _grain(out.shape[:2], grain_size)
        L = _lab(np.clip(out, 0.0, 255.0))[..., 0]
        out *= np.clip(1.0 + 3.0 * dl / (2.2 * (L + 16.0)), 0.5, 1.5)[..., None]
    keep = eye[BY][:, BX]
    out[keep] = img[keep]
    return out


def cell_layout(obj, src, cell_m, k, sub, gutter, zone=None, dark_kept=False, detail=0.0, clip=40.0, soft=0.0,
                calm=0.0, sigma=25.0, weave=0.0, weave_opts=None, face=None, face_m=None, grain=0.0,
                grain_size=0.8, face_front=0.0, settle=0, settle_margin=0.2):
    """`obj`'s UVs laid out again a texel a square (CELLS), and its texture coloured from `src`
    (rows down, the texture of its old UVs). Each triangle goes on the plane square to the way it
    faces, at k texels a square of cell_m; triangles of one facing joined by an edge make an
    island, unless a triangle would cover a point of the plane the island already covers (a sheet
    folded over itself: a lapel on the coat). Islands are packed at whole squares, so the squares
    stay on the texel grid. `zone`: a function of points (our body space) true where texels keep
    their own colours (his eyes); elsewhere a square of k×k texels is one colour, give or take
    `detail` of each texel's own (at most `clip` levels), `soft`, the share of a square from its
    edge over which it leans toward the square across it, and `calm` (with `sigma`), how far it
    moves toward the squares round it of near colour, then `weave` drawn over its cloth
    (`weave_opts`: period, noise, max_l, hands, hand_r; CELLS, _inside_squares, _weave), and `grain`
    (L*, `grain_size` texels across) inside the squares. Returns the texture (rows down) and the
    islands' count."""
    import bmesh
    mesh = obj.data
    if any(len(poly.vertices) != 3 for poly in mesh.polygons):
        bm = bmesh.new()
        bm.from_mesh(mesh)
        bmesh.ops.triangulate(bm, faces=bm.faces)
        bm.to_mesh(mesh)
        bm.free()
    co = np.zeros(len(mesh.vertices) * 3)
    mesh.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    pts = np.stack([co[:, 0], co[:, 2], -co[:, 1]], axis=1)       # Blender's axes → our body space
    lv = np.zeros(len(mesh.loops), dtype=np.int64)
    mesh.loops.foreach_get("vertex_index", lv)
    luv = np.zeros(len(mesh.loops) * 2)
    layer = mesh.uv_layers["UVMap"]
    layer.data.foreach_get("uv", luv)
    luv = luv.reshape(-1, 2)
    starts = np.zeros(len(mesh.polygons), dtype=np.int64)
    mesh.polygons.foreach_get("loop_start", starts)
    tl = starts[:, None] + np.arange(3)[None, :]                   # each triangle's three loops
    tv = lv[tl]
    P = pts[tv]
    n = np.cross(P[:, 1] - P[:, 0], P[:, 2] - P[:, 0])
    axis = np.abs(n).argmax(axis=1)
    # His face's triangles (`face`, a function of points in our body space) at their own square,
    # `face_m`: their own islands, so a square never spans the two sizes.
    in_face = face(P.mean(axis=1)) if face is not None and face_m else np.zeros(len(P), dtype=bool)
    fronted = np.zeros(len(n), dtype=bool)
    if face_front > 0:
        # Seen from in front, a cheek turned more than 45 degrees went on a side plane, whose squares
        # drew as thin upright strips; his face's triangles within `face_front` degrees of straight
        # ahead (he faces -z) go on the front plane, so from in front his face is in squares.
        ahead = -n[:, 2] / np.maximum(np.linalg.norm(n, axis=1), 1e-12)
        fronted = in_face & (ahead > np.cos(np.radians(face_front)))
        axis = np.where(fronted, 2, axis)
    facing = axis * 2 + (n[np.arange(len(n)), axis] > 0)
    if settle > 0:
        # Where a surface turns near 45 degrees between two planes its triangles chose one plane or
        # the other one by one, and the line between them ran ragged (a sawtooth of squares that
        # don't meet); a triangle within `settle_margin` of the line (its normal's two largest parts
        # that near) takes whichever of its two planes more of its neighbours are on, `settle` times.
        an = np.abs(n) / np.maximum(np.linalg.norm(n, axis=1), 1e-12)[:, None]
        top = np.argsort(-an, axis=1)
        rows = np.arange(len(n))
        cand = np.stack([top[:, j] * 2 + (n[rows, top[:, j]] > 0) for j in (0, 1)], axis=1)
        near_line = (an[rows, top[:, 0]] - an[rows, top[:, 1]] < settle_margin) & ~fronted
        by_edge = {}
        for t in np.nonzero(near_line)[0]:
            for c in range(3):
                a, b = int(tv[t, c]), int(tv[t, (c + 1) % 3])
                by_edge.setdefault((min(a, b), max(a, b)), [])
        for t in range(len(n)):
            for c in range(3):
                a, b = int(tv[t, c]), int(tv[t, (c + 1) % 3])
                e = (min(a, b), max(a, b))
                if e in by_edge:
                    by_edge[e].append(t)
        nbrs = {int(t): set() for t in np.nonzero(near_line)[0]}
        for ts in by_edge.values():
            for t in ts:
                if t in nbrs:
                    nbrs[t].update(x for x in ts if x != t)
        for _ in range(int(settle)):
            new = facing.copy()
            for t, nb in nbrs.items():
                if not nb:
                    continue
                around = facing[list(nb)]
                v0, v1 = int((around == cand[t, 0]).sum()), int((around == cand[t, 1]).sum())
                if v0 != v1:
                    new[t] = cand[t, 0] if v0 > v1 else cand[t, 1]
            facing = new
    U = np.array([_PLANES[f][0] for f in range(6)], dtype=np.float64)[facing]
    V = np.array([_PLANES[f][1] for f in range(6)], dtype=np.float64)[facing]
    tri_m = np.where(in_face, face_m or cell_m, cell_m)[:, None]
    A = np.einsum("tcj,tj->tc", P, U) / tri_m * k                  # texels, on each facing's plane
    B = np.einsum("tcj,tj->tc", P, V) / tri_m * k
    T = len(tl)
    # Sample points: a lattice `sub` a texel a side on each plane, the points inside each triangle.
    i0 = np.ceil(A.min(axis=1) * sub - 0.5).astype(np.int64)
    i1 = np.floor(A.max(axis=1) * sub - 0.5).astype(np.int64)
    j0 = np.ceil(B.min(axis=1) * sub - 0.5).astype(np.int64)
    j1 = np.floor(B.max(axis=1) * sub - 0.5).astype(np.int64)
    nx = np.maximum(i1 - i0 + 1, 0)
    ny = np.maximum(j1 - j0 + 1, 0)
    cand = nx * ny
    st = np.repeat(np.arange(T), cand)
    local = np.arange(cand.sum()) - np.repeat(np.cumsum(cand) - cand, cand)
    si = i0[st] + local % np.maximum(nx[st], 1)
    sj = j0[st] + local // np.maximum(nx[st], 1)
    x, y = (si + 0.5) / sub, (sj + 0.5) / sub
    ax, ay = A[st, 0], B[st, 0]
    e1x, e1y = A[st, 1] - ax, B[st, 1] - ay
    e2x, e2y = A[st, 2] - ax, B[st, 2] - ay
    det = e1x * e2y - e2x * e1y
    ok = np.abs(det) > 1e-12
    det = np.where(ok, det, 1.0)
    w1 = ((x - ax) * e2y - e2x * (y - ay)) / det
    w2 = (e1x * (y - ay) - (x - ax) * e1y) / det
    w0 = 1.0 - w1 - w2
    inside = ok & (w0 >= 0) & (w1 >= 0) & (w2 >= 0)
    st, si, sj, x, y = st[inside], si[inside], sj[inside], x[inside], y[inside]
    bary = np.stack([w0[inside], w1[inside], w2[inside]], axis=1)
    count = np.bincount(st, minlength=T)
    first = np.concatenate([[0], np.cumsum(count)[:-1]])
    key = (si + (1 << 30)) * (1 << 31) + (sj + (1 << 30))
    # Islands: grown triangle by triangle over shared edges within a facing.
    edges = {}
    for t in range(T):
        for c in range(3):
            a, b = int(tv[t, c]), int(tv[t, (c + 1) % 3])
            edges.setdefault((min(a, b), max(a, b)), []).append(t)
    near = [[] for _ in range(T)]
    for ts in edges.values():
        for a in ts:
            for b in ts:
                if a != b and facing[a] == facing[b] and in_face[a] == in_face[b]:
                    near[a].append(b)
    island = np.full(T, -1, dtype=np.int64)
    islands = 0
    for seed in range(T):
        if island[seed] >= 0:
            continue
        covered = set(key[first[seed]:first[seed] + count[seed]].tolist())
        island[seed] = islands
        todo = [seed]
        while todo:
            t = todo.pop()
            for nb in near[t]:
                if island[nb] >= 0:
                    continue
                ks = key[first[nb]:first[nb] + count[nb]].tolist()
                if covered.isdisjoint(ks):
                    covered.update(ks)
                    island[nb] = islands
                    todo.append(nb)
        islands += 1
    # Each island's box in whole squares (and a gutter round it), packed in shelves.
    g = gutter * k
    lo_a = np.full(islands, np.inf)
    hi_a = np.full(islands, -np.inf)
    lo_b = np.full(islands, np.inf)
    hi_b = np.full(islands, -np.inf)
    np.minimum.at(lo_a, island, A.min(axis=1))
    np.maximum.at(hi_a, island, A.max(axis=1))
    np.minimum.at(lo_b, island, B.min(axis=1))
    np.maximum.at(hi_b, island, B.max(axis=1))
    a0 = (np.floor(lo_a / k) * k - g).astype(np.int64)
    b0 = (np.floor(lo_b / k) * k - g).astype(np.int64)
    w = (np.ceil(hi_a / k) * k + g).astype(np.int64) - a0
    h = (np.ceil(hi_b / k) * k + g).astype(np.int64) - b0
    order = np.lexsort((-w, -h))
    width = int(np.ceil(np.sqrt((w * h).sum()) * 1.1 / k)) * k
    while True:
        ox = np.zeros(islands, dtype=np.int64)
        oy = np.zeros(islands, dtype=np.int64)
        cx = cy = shelf = 0
        for i in order:
            if cx + w[i] > width and cx > 0:
                cx, cy, shelf = 0, cy + shelf, 0
            ox[i], oy[i] = cx, cy
            cx += w[i]
            shelf = max(shelf, h[i])
        height = cy + shelf
        if height <= width * 1.1:
            break
        width = int(np.ceil(width * 1.08 / k)) * k
    W, H = int(max(width, w.max())), int(height)
    # The new UVs (Blender's: v up), a corner at a time.
    X = A - a0[island][:, None] + ox[island][:, None]
    Y = B - b0[island][:, None] + oy[island][:, None]
    new = np.zeros_like(luv)
    new[tl.ravel(), 0] = (X / W).ravel()
    new[tl.ravel(), 1] = (1.0 - Y / H).ravel()
    # Each sample's colour, from the old UVs.
    old = (luv[tl[st]] * bary[:, :, None]).sum(axis=1)
    sh, sw = src.shape[:2]
    rgb = src[np.clip(((1.0 - old[:, 1]) * sh).astype(np.int64), 0, sh - 1),
              np.clip((old[:, 0] * sw).astype(np.int64), 0, sw - 1)].astype(np.float64)
    tx = np.floor(x - a0[island[st]] + ox[island[st]]).astype(np.int64)
    ty = np.floor(y - b0[island[st]] + oy[island[st]]).astype(np.int64)
    if k > 1:
        bk = (ty // k) * (W // k + 1) + tx // k
        own = np.zeros(len(st), dtype=bool)
        if zone is not None:
            body = (P[st] * bary[:, :, None]).sum(axis=1)
            inz = zone(body)
            # Any square the zone touches keeps its texels (an eye's corner cut by a square's edge).
            nb_ = int(bk.max()) + 1
            own = (np.bincount(bk, inz.astype(np.float64), minlength=nb_) > 0)[bk]
        lab_key = np.where(own, (ty * W + tx) * 2 + 1, bk * 2)
    else:
        own = np.ones(len(st), dtype=bool)
        lab_key = (ty * W + tx) * 2 + 1
    keys, lab = np.unique(lab_key, return_inverse=True)
    lab = lab.ravel()
    nk = len(keys)
    lum = rgb @ np.array([0.299, 0.587, 0.114])
    cnt = np.bincount(lab, minlength=nk).astype(np.int64)
    srt = np.lexsort((lum, lab))
    start = np.concatenate([[0], np.cumsum(cnt)[:-1]])
    colour = rgb[srt[start + cnt // 2]]
    if dark_kept:
        mean_l = np.bincount(lab, lum, minlength=nk) / cnt
        dark = lum < mean_l[lab] - DARK_GAP
        dcount = np.bincount(lab, dark.astype(np.float64), minlength=nk)
        dmean = np.stack([np.bincount(lab, np.where(dark, rgb[:, c], 0.0), minlength=nk) for c in range(3)], axis=1)
        colour = np.where((dcount / cnt >= DARK_SHARE)[:, None], dmean / np.maximum(dcount, 1.0)[:, None], colour)
    if k > 1 and zone is not None:
        # A texel of an eye: the colour most of it is (the eyes are drawn in flat colours, and the
        # middle by lightness of white, iris and lid was the iris, the dark part a lid: they squinted).
        code = (rgb // 16).astype(np.int64) @ np.array([256, 16, 1])
        pair, inv = np.unique(lab * 4096 + code, return_inverse=True)
        inv = inv.ravel()
        votes = np.bincount(inv)
        best = np.zeros(nk, dtype=np.int64)
        top = np.full(nk, -1)
        pl = pair // 4096
        for i in np.argsort(votes, kind="stable"):
            if votes[i] >= top[pl[i]]:
                top[pl[i]], best[pl[i]] = votes[i], i
        pick = inv == best[lab]
        mode = np.stack([np.bincount(lab, np.where(pick, rgb[:, c], 0.0), minlength=nk) for c in range(3)], axis=1)
        mode /= np.maximum(np.bincount(lab, pick.astype(np.float64), minlength=nk), 1.0)[:, None]
        colour = np.where((keys % 2 == 1)[:, None], mode, colour)
    img = np.zeros((H, W, 3))
    have = np.zeros((H, W), dtype=bool)
    is_texel = keys % 2 == 1
    tk = keys[is_texel] // 2
    img[tk // W, tk % W] = colour[is_texel]
    have[tk // W, tk % W] = True
    for c, kk in zip(colour[~is_texel], keys[~is_texel] // 2):
        by, bx = divmod(int(kk), W // k + 1)
        blk = (slice(by * k, by * k + k), slice(bx * k, bx * k + k))
        keep = have[blk].copy()
        img[blk] = np.where(keep[..., None], img[blk], c)
        have[blk] = True
    # What no sample reached (an island's edge, its gutter) takes the nearest that one did.
    for _ in range(4 * k + 8):
        if have.all():
            break
        grow = img.copy()
        got = have.copy()
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sh_img = np.roll(img, (dy, dx), axis=(0, 1))
            sh_have = np.roll(have, (dy, dx), axis=(0, 1))
            take = ~got & sh_have
            grow[take] = sh_img[take]
            got |= take
        img, have = grow, got
    plane = None
    if k > 1 and (weave > 0 or (weave_opts or {}).get("mottle", 0.0) > 0):
        # Each square's place on its facing's plane (the islands sit at whole squares, so a square of
        # the texture is one square of the plane) and its middle in our body space, for the weave.
        nby_, nbx_ = H // k, W // k
        sby, sbx = ty // k, tx // k
        fits = (sby < nby_) & (sbx < nbx_)
        bi = np.zeros((nby_, nbx_), dtype=np.int64)
        bj = np.zeros((nby_, nbx_), dtype=np.int64)
        bf = np.full((nby_, nbx_), -1, dtype=np.int64)
        bpos = np.zeros((nby_, nbx_, 3))
        at = (P[st] * bary[:, :, None]).sum(axis=1)
        bi[sby[fits], sbx[fits]] = np.floor(x[fits] / k).astype(np.int64)
        bj[sby[fits], sbx[fits]] = np.floor(y[fits] / k).astype(np.int64)
        bf[sby[fits], sbx[fits]] = facing[st][fits]
        bpos[sby[fits], sbx[fits]] = at[fits]
        plane = (bi, bj, bf, bpos)
    if k > 1 and (detail > 0 or soft > 0 or calm != 0 or weave > 0 or grain > 0 or plane is not None):
        img = _inside_squares(img, k, W, rgb, lum, tx, ty, bk[own] if own.any() else None, detail, clip, soft,
                              calm, sigma, weave, plane, weave_opts, grain, grain_size)
    layer.data.foreach_set("uv", new.ravel())
    mesh.update()
    return np.clip(img, 0, 255).astype(np.uint8), islands


def cell_textures(person, colour, cells):
    """His meshes laid out a texel a square and their textures written (CELLS): skin and head from
    `colour` (the plain repaint), each piece from its own; the report says how."""
    o = dict(CELLS, **(cells if isinstance(cells, dict) else {}))
    eyes = [np.array(e) for e in person.report.get("eyes", {}).values()]
    ez = np.array(o["eye_zone"])

    def zone(pts):
        inz = np.zeros(len(pts), dtype=bool)
        for e in eyes:
            inz |= (((pts - e) / ez) ** 2).sum(axis=1) < 1.0
        return inz

    # His face (`face_box` round his drawn eyes: across either side of their middle, above and
    # below them, and behind them; he faces -z), squared at `face` metres where that's set.
    fb = o["face_box"]
    mid = np.mean(eyes, axis=0) if eyes else None

    def face(pts):
        return ((np.abs(pts[:, 0] - mid[0]) < fb[0]) & (pts[:, 1] < mid[1] + fb[1]) & (pts[:, 1] > mid[1] - fb[2])
                & (pts[:, 2] < mid[2] + fb[3]))

    # His collar and shirt front on his body (`collar_box`: across either side of his eyes' middle,
    # from that far below them down to that far, and behind them), squared at `collar` metres.
    cb = o["collar_box"]

    def collar(pts):
        return ((np.abs(pts[:, 0] - mid[0]) < cb[0]) & (pts[:, 1] < mid[1] - cb[1]) & (pts[:, 1] > mid[1] - cb[2])
                & (pts[:, 2] < mid[2] + cb[3]))

    src = np.asarray(colour.convert("RGB"))

    def inside(shape):
        # The inside of his squares (CELLS): a number for every shape, or {shape: number} with
        # `skin` standing for any shape not named.
        out = {}
        for key, name in (("detail", "detail"), ("detail_clip", "clip"), ("soft", "soft"), ("calm", "calm"),
                          ("calm_sigma", "sigma"), ("weave", "weave"), ("grain", "grain"),
                          ("grain_size", "grain_size")):
            v = o[key]
            out[name] = float(v.get(shape, v.get("skin", 0.0)) if isinstance(v, dict) else v)
        return out

    # The weave's rows, its share of each square's own shade, the lightest square it's drawn on and
    # how far it keeps from his hands (the anatomy's, in our body space: his rest pose).
    segs = person.env["segments"]
    mottle = o["mottle"] if isinstance(o["mottle"], dict) else {"head": o["mottle"], "skin": o["mottle"]}
    weave_opts = {"period": int(o["weave_period"]), "noise": float(o["weave_noise"]),
                  "max_l": float(o["weave_max_l"]), "hand_r": float(o["weave_hand"]),
                  "hands": [segs[h]["center"] for h in ("hand_l", "hand_r") if h in segs],
                  "cluster": float(o["weave_cluster"]), "mottle": float(mottle.get("skin", 0.0))}
    # On his head, only over his brows (no drawn eyes found: nowhere); his skin's mottle under them.
    head_weave = dict(weave_opts, noise=float(o["weave_head_noise"]), mottle=float(mottle.get("head", 0.0)),
                      above=float(np.mean([e[1] for e in eyes])) + float(o["weave_head_above"]) if eyes else np.inf)

    # How the planes are chosen where a surface turns between two (`settle`, `settle_margin`).
    planes = {"settle": int(o["settle"]), "settle_margin": float(o["settle_margin"])}
    done = {}
    per = {}
    how = {}
    for obj in [ob for ob in bpy.data.objects if ob.name.startswith("body_")]:
        shape = obj.name.split("_", 1)[1]
        piece = next((pc for pc in person.pieces if pc.shape == shape), None)
        if shape == "head":
            k = int(o["head_texels"])
            img, isl = cell_layout(obj, src, o["head"], k, o["samples"][0], o["gutter"], zone if eyes else None,
                                   bool(o["dark_kept"]), weave_opts=head_weave, face=face if eyes else None,
                                   face_m=float(o["face"]) or None, face_front=float(o["face_front"]), **planes,
                                   **inside(shape))
        elif shape == "skin":
            k = int(o["body_texels"])
            img, isl = cell_layout(obj, src, o["body"], k, o["samples"][1], o["gutter"], weave_opts=weave_opts,
                                   face=collar if eyes and o["collar"] else None, face_m=float(o["collar"]) or None,
                                   **planes, **inside(shape))
        elif piece is not None and getattr(piece, "colour", None) is not None:
            k = int(o.get(shape + "_texels", o["body_texels"]))
            img, isl = cell_layout(obj, np.asarray(piece.colour.convert("RGB")), o.get(shape, o["body"]), k,
                                   o["samples"][1], o["gutter"], weave_opts=weave_opts, **planes, **inside(shape))
        else:
            continue
        Image.fromarray(img).save(os.path.join(OUT, "%s_%s.png" % (person.id, shape)))
        done[shape] = {"size": [img.shape[1], img.shape[0]], "islands": isl}
        per[shape] = k
        how[shape] = inside(shape)
        print("  %s: a texel a square, %d texels a side, %d×%d, %d islands" % (shape, k, img.shape[1], img.shape[0], isl))
    sizes = {kk: o[kk] for kk in ("head", "body", "hair", "face", "collar") if o[kk]}
    person.report["texture"] = dict(person.report.get("texture", {}), cells=sizes,
                                    shapes=done, texels_per_square=per, inside=how)


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
    cells_args = {}
    for a in args:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
        if a.startswith("--cells="):
            # A trial of CELLS's numbers for a man laid out a texel a square, e.g.
            # --cells=detail:0.3,soft:0.25,body_texels:3 (over people.json's `cells`).
            # A key with a dot is one shape's (detail.head:0.15).
            for kv in a.split("=", 1)[1].split(","):
                key, val = kv.split(":")
                val = float(val) if "." in val else int(val)
                if "." in key:
                    key, shape = key.split(".")
                    base = cells_args.get(key, CELLS.get(key))
                    cells_args[key] = dict(base if isinstance(base, dict) else {"skin": base}, **{shape: val})
                else:
                    cells_args[key] = val
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
                    1 if SMOOTH else getattr(piece, "square", SQUARE_TEXELS))
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
        if spec.get("cells"):
            cells = dict(spec["cells"] if isinstance(spec["cells"], dict) else {}, **cells_args)
            cell_textures(p, colour, cells)
        export(p)


if __name__ == "__main__":
    main()
