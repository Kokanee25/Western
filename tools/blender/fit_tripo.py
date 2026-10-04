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
# Pieces (a garment modelled alone, hung on the body): triangles after decimation, and how much
# wider than what they go over they are scaled (room for the cloth under them).
PIECE_TRIS = {"coat": 2600, "hat": 700}
PIECE_MARGIN = {"coat": 1.06, "hat": 1.05}
# The hat's brim sits this share of the way up his head from the jaw joint to the crown.
HAT_BAND = 0.72
# A coat's collar stands this far above the neck joint (Tripo units, of his height: ~6 cm).
COAT_COLLAR = 0.032
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
        pos, nrm, uv, tris, joints, colour = load_glb(os.path.join(TRIPO, self.model + ".glb"))
        self.v = to_body_space(pos)
        self.uv = uv
        self.tris = tris
        self.colour = colour
        self.j = {ours: to_body_space(joints[theirs]) for ours, theirs in JOINTS.items()}
        self.j["hips"] = (self.j["r-upper-leg"] + self.j["l-upper-leg"]) / 2
        y0, y1 = self.v[:, 1].min(), self.v[:, 1].max()
        if "model" in spec:
            # Bare-headed, his crown is his top: the collar is a share of the neck, from its joints.
            self.head_cut = self.j["neck"][1] + (self.j["head"][1] - self.j["neck"][1]) * HEAD_FROM_NECK
        else:
            self.head_cut = y0 + (y1 - y0) * HEAD_FROM
        self.report = {"id": pid, "source": "tripo", "whole": True, "model": self.model, "triangles_in": int(len(tris)),
                       "pieces": dict(spec.get("pieces", {}))}
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
        self.v, self.region = self.warp_points(self.v, head, bones)
        self.head = head
        self.fit_joints = {}
        self.report["scale"] = round(float(self.scale), 4)
        self.report["height_m"] = round(float(self.v[:, 1].max()), 3)
        for piece in self.pieces:
            piece.v, piece.region = self.warp_points(piece.v, self.head_mask(piece.v), bones)

    def head_mask(self, v):
        """What is head: above the collar, and within HEAD_RADIUS of the neck's axis (the tops of
        the shoulders rise above a bare-headed man's collar line, and they are trunk)."""
        above = v[:, 1] > self.head_cut
        n = self.j["neck"]
        near = np.hypot(v[:, 0] - n[0], v[:, 2] - n[2]) < HEAD_RADIUS
        return above & near

    def warp_points(self, v, head, bones):
        """Points in his Tripo space (body orientation) moved onto our skeleton by his bones, and
        the bone each belongs to. The head is everything above the collar; nothing below it is
        head, nothing above the neck joint is trunk."""
        radial = self.scale
        names = [b[0] for b in bones]
        d = np.stack([mp.seg_dist(v, b[1], b[2])[0] - b[5] for b in bones], axis=1)
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
        for i, (name, ma, mb, oa, ob, _r) in enumerate(bones):
            sel = w[:, i] > 0
            if not sel.any():
                continue
            u = (mb - ma) / np.linalg.norm(mb - ma)
            k = np.linalg.norm(ob - oa) / np.linalg.norm(mb - ma)
            rel = v[sel] - ma
            along = rel @ u
            perp = rel - along[:, None] * u
            local = along[:, None] * u * k + perp * radial
            moved = local @ mp.rotation_between(u, ob - oa).T + oa
            out[sel] += w[sel, i][:, None] * moved
        return out, region

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
        self.cut_fingers()
        self.weights()
        for piece in self.pieces:
            if piece.shape == "coat":
                TripoPerson.skirt(piece)
                # A coat is never head: its collar follows the neck, not a turned head.
                piece.region[piece.region == "head"] = "neck"
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
            # The brim is where the hat is widest; the crown's foot a little above it goes round
            # the head at the band, its width the head's there plus room.
            ys = np.linspace(y0, y1, 40)
            widths = [self._width_at(v, y, h * 0.03)[0] for y in ys]
            brim_y = ys[int(np.argmax(widths))]
            crown_w = self._width_at(v, brim_y + h * 0.12, h * 0.03)[0] or max(widths) * 0.6
            head = body.v[body.v[:, 1] > body.head_cut]
            jaw, crown = body.j["head"][1], head[:, 1].max()
            band_y = jaw + (crown - jaw) * HAT_BAND
            head_w, cx, cz = self._width_at(head, band_y, 0.01)
            s = head_w * PIECE_MARGIN["hat"] / max(crown_w, 1e-6)
            self.v = (v - [0.0, brim_y, 0.0]) * s + [cx, band_y, cz]
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
            bw, bx, bz = self._torso_at(body.v, body_sh[1] - chest_dy, bx0, sw * 0.5, 0.012)
            cw, cx, cz = self._torso_at(v, sh_y - chest_dy / s, px, (sw * 0.5) / s * 1.05, h * 0.015)
            g = bw * PIECE_MARGIN[self.shape] / max(cw, 1e-6) / s if cw > 0 and bw > 0 else 1.0
            moved = v - [cx, y1, cz]
            moved[:, 0] *= s * g
            moved[:, 2] *= s * g
            moved[:, 1] *= s
            self.v = moved + [bx, top_y, bz]
            body.report.setdefault("piece_girth", {})[self.shape] = round(float(g), 3)
            body.report.setdefault("piece_landmarks", {})[self.shape] = {
                "shoulder_line_from_top": round(float((y1 - sh_y) / h), 3), "length_m": round(float(h * s * body.scale), 3)}
            self._sleeves_to_arms()
        body.report.setdefault("piece_scale", {})[self.shape] = round(float(s), 3)

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
    head = make("head", person.tris[head_tris], HEAD_TRIS)
    skin = make("skin", person.tris[~head_tris], TRI_BUDGET)
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
        if spec.get("source") != "tripo" or (only and pid != only):
            continue
        missing = [m for m in [spec.get("model", pid)] + list(spec.get("pieces", {}).values())
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
        # His texture: the head repainted in the style where it has been.
        repainted = os.path.join(TRIPO, pid + "_color.png")
        if SMOOTH:
            # The "quantise once" set: the smooth repaint (head_paint.py --smooth) if there is one,
            # no squares, written beside the real textures as <id>_skin_smooth.png / _head_smooth.png
            # (PeopleBodies.smooth_paint takes them); the glb is unchanged, so no export.
            smooth_paint = os.path.join(TRIPO, pid + "_color_smooth.png")
            src = smooth_paint if os.path.exists(smooth_paint) else repainted
            colour = Image.open(src).convert("RGB") if os.path.exists(src) else p.colour
            squares(colour, os.path.join(OUT, pid + "_skin_smooth.png"), 1)
            squares(colour, os.path.join(OUT, pid + "_head_smooth.png"), 1)
            print("wrote", pid, "smooth textures from", os.path.basename(src) if os.path.exists(src) else "tripo")
            continue
        colour = Image.open(repainted).convert("RGB") if os.path.exists(repainted) else p.colour
        size = squares(colour, os.path.join(OUT, pid + "_skin.png"))
        squares(colour, os.path.join(OUT, pid + "_head.png"))
        p.report["texture"] = {"from": os.path.basename(repainted) if os.path.exists(repainted) else "tripo", "size": size,
                               "square_texels": SQUARE_TEXELS}
        if bpy is None:
            print("no bpy: fitted", pid, "but not exported")
            json.dump(p.report, open(os.path.join(OUT, pid + ".json"), "w"), indent=1)
            continue
        build_blender(p)
        export(p)


if __name__ == "__main__":
    main()
