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
# Triangles after decimation: the body, and the head on its own (its face needs them).
TRI_BUDGET = 5500
HEAD_TRIS = 2200
# One square of the texture: this many of Tripo's 2048 texels a side (~5.6 mm on him).
SQUARE_TEXELS = 4
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
    skin = doc["skins"][0]
    ibm = accessor(skin["inverseBindMatrices"]).reshape(-1, 4, 4)
    joints = {}
    for j, node in enumerate(skin["joints"]):
        world = np.linalg.inv(ibm[j].T)  # glTF matrices are column-major
        joints[doc["nodes"][node].get("name", str(node))] = world[:3, 3]
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
        pos, nrm, uv, tris, joints, colour = load_glb(os.path.join(TRIPO, pid + ".glb"))
        self.v = to_body_space(pos)
        self.uv = uv
        self.tris = tris
        self.colour = colour
        self.j = {ours: to_body_space(joints[theirs]) for ours, theirs in JOINTS.items()}
        self.j["hips"] = (self.j["r-upper-leg"] + self.j["l-upper-leg"]) / 2
        y0, y1 = self.v[:, 1].min(), self.v[:, 1].max()
        self.head_cut = y0 + (y1 - y0) * HEAD_FROM
        self.report = {"id": pid, "source": "tripo", "whole": True, "triangles_in": int(len(tris))}

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
            out += [["upper_arm_" + side, m[side + "-shoulder"], m[side + "-elbow"], o[side + "-shoulder"], o[side + "-elbow"], 0.05],
                    ["forearm_" + side, m[side + "-elbow"], m[side + "-hand"], o[side + "-elbow"], o[side + "-hand"], 0.04],
                    ["hand_" + side, m[side + "-hand"], knuckle, o[side + "-hand"], o[side + "-knuckle"], 0.03],
                    ["thigh_" + side, m[side + "-upper-leg"], m[side + "-knee"], o[side + "-upper-leg"], o[side + "-knee"], 0.075],
                    ["shin_" + side, m[side + "-knee"], m[side + "-ankle"], o[side + "-knee"], o[side + "-ankle"], 0.05],
                    ["foot_" + side, m[side + "-ankle"], m[side + "-toe"], o[side + "-ankle"], o[side + "-toe"], 0.04]]
        return out

    def warp(self):
        v = self.v
        bones = self.bones()
        radial = self.scale
        names = [b[0] for b in bones]
        d = np.stack([mp.seg_dist(v, b[1], b[2])[0] - b[5] for b in bones], axis=1)
        # The head is everything above the collar; nothing below it is head, nothing above the
        # neck joint is trunk.
        head = v[:, 1] > self.head_cut
        d[~head, names.index("head")] += 1.0
        d[head, names.index("trunk")] += 1.0
        d[head, names.index("neck")] += 0.5
        for i, n in enumerate(names):
            if n.startswith(("upper_arm", "forearm", "hand")):
                d[head, i] += 1.0
        w = np.exp(-(d - d.min(1, keepdims=True)) / mp.BLEND)
        w[w < 1e-3] = 0.0
        w /= w.sum(1, keepdims=True)
        self.region = np.array([bones[i][0] for i in d.argmin(1)])
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
        self.v = out
        self.head = head
        self.fit_joints = {}
        self.report["scale"] = round(float(radial), 4)
        self.report["height_m"] = round(float(out[:, 1].max()), 3)

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
        self.skirt()
        self.cut_fingers()
        self.weights()


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

    def make(name, tris, budget):
        used = np.unique(tris)
        new_index = {int(old): i for i, old in enumerate(used)}
        mesh = bpy.data.meshes.new("body_" + name)
        mesh.from_pydata([mp.to_blender(person.v[i]) for i in used], [], [[new_index[int(i)] for i in t] for t in tris])
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                u, vv = person.uv[used[mesh.loops[li].vertex_index]]
                uv_layer.data[li].uv = (u, 1.0 - vv)   # glTF's v runs down; the export flips it back
        for poly in mesh.polygons:
            poly.use_smooth = True
        obj = bpy.data.objects.new("body_" + name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for bname in bones:
            obj.vertex_groups.new(name=bname)
        for new_i, old_i in enumerate(used):
            for b, w in enumerate(person.W[old_i]):
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
    person.report["triangles"] = {o.name.split("_", 1)[1]: sum(len(p.vertices) - 2 for p in o.data.polygons)
                                  for o in (skin, head)}


def export(person):
    path = os.path.join(OUT, person.id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    json.dump(person.report, open(os.path.join(OUT, person.id + ".json"), "w"), indent=1)
    print("wrote", path, person.report.get("triangles"))


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = None
    for a in args:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
    env = json.load(open(mp.ENVELOPE))
    people = json.load(open(os.path.join(OUT, "people.json")))["people"]
    for pid, spec in people.items():
        if spec.get("source") != "tripo" or (only and pid != only):
            continue
        if not os.path.exists(os.path.join(TRIPO, pid + ".glb")):
            print("no Tripo model for", pid)
            continue
        p = TripoPerson(pid, spec, env)
        p.run()
        # His texture: the head repainted in the style where it has been.
        repainted = os.path.join(TRIPO, pid + "_color.png")
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
