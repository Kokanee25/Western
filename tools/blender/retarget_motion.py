"""A generated or captured motion onto the game's rig: the card cheat's moves from Uthana's
text-to-motion (the Studio's motions/<set>/<move>_<take>.glb), or any glTF/FBX/BVH with a humanoid
skeleton, retargeted to our 17 segments, trimmed, its feet held still where they're planted, and
written as the clip HumanBody plays (assets/animations/<name>.json, MotionClip) and as glTF for
the record (assets/animations/<name>.glb). Headless Blender (docs/MOCAP.md "Pipeline"):

    ~/.venvs/bpy/bin/python tools/blender/retarget_motion.py IN.glb --name=kick_back [--rest=REST.glb] [--out=assets/animations]
        [--trim=0.03] [--strike=foot_r] [--event=strike:auto] [--no-feet] [--report=DIR]
    ~/.venvs/bpy/bin/python tools/blender/retarget_motion.py --set=DIR --rest=REST.glb --report=DIR   # every take in a folder; a report that ranks them
(--rest: a file of the same character with its mesh, for the rig's rest pose; Uthana's
animation-only files are a hierarchy of empties with no armature.)
    blender -b --python tools/blender/retarget_motion.py -- IN.glb --name=...

The method (the CMU walk's, experiments/mocap_walk/retarget.py, made general): each of our
segments turns from its rest by what the source bone turned from its rest pose, after a fixed turn
that takes the source's rest bone onto ours (so a T pose or an A pose both give our hanging arms).
Quaternions throughout, our rest from experiments/mocap_walk/rig_rest.json (the rig as HumanBody
builds it). The root's travel is the hips' path in the first frame's heading, scaled to our leg;
his heading is the hips' yaw. A foot that stands (low and slow) pins the root's travel to it for
those frames (no sliding). Written for this project.
"""
import json
import math
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gltf_motion

try:
    import bpy
    from mathutils import Matrix, Quaternion, Vector
except ImportError:  # the report and the pure maths run without Blender
    bpy = None

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
RIG_REST = os.path.join(ROOT, "experiments", "mocap_walk", "rig_rest.json")

# Our segment -> the words that name its source bone (lower-cased; the first pattern to match a bone wins,
# tried in order), and the bone whose head is its tip (for the rest direction).
# Mixamo's names (Hips, Spine, Spine1, Spine2, Neck, Head, LeftUpLeg...), CMU's (LowerBack...),
# Rokoko's/Move's, SMPL's (pelvis, left_hip, spine1...) and Uthana's are all caught by these.
BONES = {
    "pelvis": [r"^(mixamorig:?)?hips?$", r"^pelvis$", r"^root$", r"hip"],
    "abdomen": [r"^(mixamorig:?)?spine$", r"^lowerback$", r"^spine_?0?1$", r"spine"],
    "chest": [r"^(mixamorig:?)?spine1$", r"^spine_?0?2$", r"^chest$", r"spine2", r"upper.?chest"],
    "neck": [r"^(mixamorig:?)?neck$", r"^neck_?0?1$", r"neck"],
    "head": [r"^(mixamorig:?)?head$", r"head"],
    "thigh_l": [r"^(mixamorig:?)?leftupleg$", r"^(l|left)[_.]?(hip|thigh|upleg|up_leg|upper_?leg)$", r"left.*(thigh|upleg|up_leg|upperleg)", r"^thigh[_.]?l$", r"(thigh|upleg).*[_.]l$"],
    "shin_l": [r"^(mixamorig:?)?leftleg$", r"^(l|left)[_.]?(knee|leg|shin|lowerleg|lower_leg|calf)$", r"left.*(shin|lowerleg|lower_leg|calf|knee)", r"^(shin|calf)[_.]?l$", r"(shin|calf|leg).*[_.]l$"],
    "foot_l": [r"^(mixamorig:?)?leftfoot$", r"^(l|left)[_.]?(ankle|foot)$", r"left.*(foot|ankle)", r"^foot[_.]?l$", r"foot.*[_.]l$"],
    "thigh_r": [r"^(mixamorig:?)?rightupleg$", r"^(r|right)[_.]?(hip|thigh|upleg|up_leg|upper_?leg)$", r"right.*(thigh|upleg|up_leg|upperleg)", r"^thigh[_.]?r$", r"(thigh|upleg).*[_.]r$"],
    "shin_r": [r"^(mixamorig:?)?rightleg$", r"^(r|right)[_.]?(knee|leg|shin|lowerleg|lower_leg|calf)$", r"right.*(shin|lowerleg|lower_leg|calf|knee)", r"^(shin|calf)[_.]?r$", r"(shin|calf|leg).*[_.]r$"],
    "foot_r": [r"^(mixamorig:?)?rightfoot$", r"^(r|right)[_.]?(ankle|foot)$", r"right.*(foot|ankle)", r"^foot[_.]?r$", r"foot.*[_.]r$"],
    "upper_arm_l": [r"^(mixamorig:?)?leftarm$", r"^(l|left)[_.]?(shoulder_joint|upperarm|upper_arm|arm|uparm)$", r"left.*(upperarm|upper_arm|uparm)", r"^upper_?arm[_.]?l$", r"upper_?arm.*[_.]l$"],
    "forearm_l": [r"^(mixamorig:?)?leftforearm$", r"^(l|left)[_.]?(elbow|forearm|fore_arm|lowerarm|lower_arm)$", r"left.*(forearm|fore_arm|lowerarm|lower_arm|elbow)", r"^fore_?arm[_.]?l$", r"fore_?arm.*[_.]l$"],
    "hand_l": [r"^(mixamorig:?)?lefthand$", r"^(l|left)[_.]?(wrist|hand)$", r"left.*(hand|wrist)$", r"^hand[_.]?l$", r"hand.*[_.]l$"],
    "upper_arm_r": [r"^(mixamorig:?)?rightarm$", r"^(r|right)[_.]?(shoulder_joint|upperarm|upper_arm|arm|uparm)$", r"right.*(upperarm|upper_arm|uparm)", r"^upper_?arm[_.]?r$", r"upper_?arm.*[_.]r$"],
    "forearm_r": [r"^(mixamorig:?)?rightforearm$", r"^(r|right)[_.]?(elbow|forearm|fore_arm|lowerarm|lower_arm)$", r"right.*(forearm|fore_arm|lowerarm|lower_arm|elbow)", r"^fore_?arm[_.]?r$", r"fore_?arm.*[_.]r$"],
    "hand_r": [r"^(mixamorig:?)?righthand$", r"^(r|right)[_.]?(wrist|hand)$", r"right.*(hand|wrist)$", r"^hand[_.]?r$", r"hand.*[_.]r$"],
}
# The bone at each segment's far end (its tip), for the rest direction: the child bone that is
# the next segment down, else the bone's own tail.
TIP = {"pelvis": None, "abdomen": "chest", "chest": "neck", "neck": "head", "head": None,
       "thigh_l": "shin_l", "shin_l": "foot_l", "foot_l": None, "thigh_r": "shin_r", "shin_r": "foot_r", "foot_r": None,
       "upper_arm_l": "forearm_l", "forearm_l": "hand_l", "hand_l": None,
       "upper_arm_r": "forearm_r", "forearm_r": "hand_r", "hand_r": None}
# For the ends (feet, head, hands), the source's own tip joint when it has one (Mixamo's ToeBase,
# HeadTop_End, HandMiddle1): the importer gives a childless bone a made-up tail.
TIP_SRC = {"foot_l": [r"lefttoebase", r"lefttoe_end", r"left.*toe"], "foot_r": [r"righttoebase", r"righttoe_end", r"right.*toe"],
           "head": [r"headtop_end", r"head_end", r"headtop"],
           "hand_l": [r"lefthandmiddle1", r"lefthandindex1", r"left.*middle1", r"left.*index1"],
           "hand_r": [r"righthandmiddle1", r"righthandindex1", r"right.*middle1", r"right.*index1"]}
PARENT = {"pelvis": None, "abdomen": "pelvis", "chest": "abdomen", "neck": "chest", "head": "neck",
          "thigh_l": "pelvis", "shin_l": "thigh_l", "foot_l": "shin_l", "thigh_r": "pelvis", "shin_r": "thigh_r", "foot_r": "shin_r",
          "upper_arm_l": "chest", "forearm_l": "upper_arm_l", "hand_l": "forearm_l",
          "upper_arm_r": "chest", "forearm_r": "upper_arm_r", "hand_r": "forearm_r"}
FPS = 30

# Rigs read by their own names, not the patterns above (their names fool them: Quaternius' rigify
# DEF- bones have a "root" under the hips' parent; KayKit's legs are upperleg/lowerleg): picked when
# the file has the rig's `detect` bone. `bones`: our segment -> theirs; `tips`: the joint at a
# segment's far end where it isn't the next segment's (a toe, the hand's middle).
RIGS = {
    # Quaternius' Universal Animation Library (a rigify-style humanoid): spine.001 the belly,
    # spine.003 the upper chest the shoulders hang from (spine.002's turn is in the chest's world
    # turn, which is all the retarget reads).
    "quaternius": {"detect": "DEF-hips", "bones": {
        "pelvis": "DEF-hips", "abdomen": "DEF-spine.001", "chest": "DEF-spine.003", "neck": "DEF-neck", "head": "DEF-head",
        "thigh_l": "DEF-thigh.L", "shin_l": "DEF-shin.L", "foot_l": "DEF-foot.L",
        "thigh_r": "DEF-thigh.R", "shin_r": "DEF-shin.R", "foot_r": "DEF-foot.R",
        "upper_arm_l": "DEF-upper_arm.L", "forearm_l": "DEF-forearm.L", "hand_l": "DEF-hand.L",
        "upper_arm_r": "DEF-upper_arm.R", "forearm_r": "DEF-forearm.R", "hand_r": "DEF-hand.R"},
        "tips": {"foot_l": "DEF-toe.L", "foot_r": "DEF-toe.R", "hand_l": "DEF-f_middle.01.L", "hand_r": "DEF-f_middle.01.R"}},
    # KayKit's Rig_Medium (Character Animations 1.1): no neck bone (the head hangs from the chest:
    # our neck stays the pose's); wrist.* is the hand's joint, hand.* its middle.
    "kaykit": {"detect": "upperleg.l", "bones": {
        "pelvis": "hips", "abdomen": "spine", "chest": "chest", "head": "head",
        "thigh_l": "upperleg.l", "shin_l": "lowerleg.l", "foot_l": "foot.l",
        "thigh_r": "upperleg.r", "shin_r": "lowerleg.r", "foot_r": "foot.r",
        "upper_arm_l": "upperarm.l", "forearm_l": "lowerarm.l", "hand_l": "wrist.l",
        "upper_arm_r": "upperarm.r", "forearm_r": "lowerarm.r", "hand_r": "wrist.r"},
        "tips": {"foot_l": "toes.l", "foot_r": "toes.r", "hand_l": "hand.l", "hand_r": "hand.r"}},
}


def rig_of(names):
    """The known rig these bone names are (RIGS), or None."""
    for key, r in RIGS.items():
        if r["detect"] in names:
            return r
    return None


def opt(name, default=None, args=None):
    for a in (args if args is not None else sys.argv[1:]):
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
        if a == "--" + name:
            return True
    return default


# --- Maths ----------------------------------------------------------------------------------------

def arc(u, v):
    """The shortest rotation (3x3) taking direction u onto v."""
    u, v = u / np.linalg.norm(u), v / np.linalg.norm(v)
    axis = np.cross(u, v)
    s, c = np.linalg.norm(axis), float(np.dot(u, v))
    if s < 1e-8:
        if c > 0:
            return np.eye(3)
        # Opposite: a half turn about any axis square to u.
        k = np.cross(u, [1.0, 0.0, 0.0])
        if np.linalg.norm(k) < 1e-6:
            k = np.cross(u, [0.0, 1.0, 0.0])
        k /= np.linalg.norm(k)
        K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
        return np.eye(3) + 2 * K @ K
    k = axis / s
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    a = math.atan2(s, c)
    return np.eye(3) + math.sin(a) * K + (1 - math.cos(a)) * K @ K


def yaw_m(theta):
    c, s = math.cos(theta), math.sin(theta)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def quat(R):
    """A rotation matrix as [x, y, z, w] (Godot's order), w >= 0."""
    t = R[0, 0] + R[1, 1] + R[2, 2]
    if t > 0:
        s = math.sqrt(t + 1.0) * 2
        q = [(R[2, 1] - R[1, 2]) / s, (R[0, 2] - R[2, 0]) / s, (R[1, 0] - R[0, 1]) / s, 0.25 * s]
    elif R[0, 0] > R[1, 1] and R[0, 0] > R[2, 2]:
        s = math.sqrt(1.0 + R[0, 0] - R[1, 1] - R[2, 2]) * 2
        q = [0.25 * s, (R[0, 1] + R[1, 0]) / s, (R[0, 2] + R[2, 0]) / s, (R[2, 1] - R[1, 2]) / s]
    elif R[1, 1] > R[2, 2]:
        s = math.sqrt(1.0 + R[1, 1] - R[0, 0] - R[2, 2]) * 2
        q = [(R[0, 1] + R[1, 0]) / s, 0.25 * s, (R[1, 2] + R[2, 1]) / s, (R[0, 2] - R[2, 0]) / s]
    else:
        s = math.sqrt(1.0 + R[2, 2] - R[0, 0] - R[1, 1]) * 2
        q = [(R[0, 2] + R[2, 0]) / s, (R[1, 2] + R[2, 1]) / s, 0.25 * s, (R[1, 0] - R[0, 1]) / s]
    if q[3] < 0:
        q = [-c for c in q]
    n = math.sqrt(sum(c * c for c in q))
    return [round(c / n, 5) for c in q]


def yaw_of(R):
    """The heading of a rotation's forward (-z) axis, as Godot reads it (rotation.y)."""
    f = R @ np.array([0.0, 0.0, -1.0])
    return math.atan2(-f[0], -f[2])


# --- Reading the source with Blender --------------------------------------------------------------

def match_bones(names):
    """Our segment -> the source bone that carries it, by name."""
    r = rig_of(names)
    if r is not None:
        return {seg: b for seg, b in r["bones"].items() if b in names}
    low = {n: n.lower() for n in names}
    out = {}
    used = set()
    for seg, pats in BONES.items():
        for pat in pats:
            hit = [n for n in names if n not in used and re.search(pat, low[n])]
            if hit:
                # The shortest name: "Spine" before "Spine1", "LeftFoot" before "LeftFootIndex".
                hit.sort(key=lambda n: (len(low[n]), low[n]))
                out[seg] = hit[0]
                used.add(hit[0])
                break
    return out


def _to_gltf(path, work):
    """Not glTF (an FBX from the phone, a BVH): Blender reads it and writes a GLB to read as glTF."""
    if bpy is None:
        sys.exit("retarget_motion: %s needs Blender (bpy) to read" % path)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    ext = os.path.splitext(path)[1].lower()
    if ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif ext == ".bvh":
        bpy.ops.import_anim.bvh(filepath=path, global_scale=0.01, update_scene_fps=True, update_scene_duration=True)
    else:
        sys.exit("retarget_motion: can't read %s" % path)
    os.makedirs(work, exist_ok=True)
    out = os.path.join(work, os.path.splitext(os.path.basename(path))[0] + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_animations=True, export_apply=False)
    return out


def anim_index(g, anim):
    """The animation called `anim` in the file (its index; 0 when `anim` is empty)."""
    if not anim:
        return 0
    for i, a in enumerate(g.doc.get("animations", [])):
        if a.get("name") == anim:
            return i
    sys.exit("retarget_motion: no animation %r in the file" % anim)


def read_source(path, rest_path=None, work=None, anim=None):
    """The motion as (joint names, the rest pose, the animation sampled at FPS, the file's frame
    rate), each pose a joint name -> 4x4 world matrix in glTF's axes (Godot's: y up, -z forward),
    metres. Read from the glTF itself (tools/blender/gltf_motion.py): the rest is the nodes' default
    transforms (the bind pose in Mixamo-style exports, the same in Uthana's animation-only files as
    in one with the mesh), or the --rest file's."""
    if not path.lower().endswith((".glb", ".gltf")):
        path = _to_gltf(path, work or os.path.join(ROOT, "build", "motion", "converted"))
    g = gltf_motion.Gltf(path)
    rest_src = gltf_motion.Gltf(rest_path).rest() if rest_path else g.rest()
    rest = {n: (m, m[:3, 3].copy(), None) for n, m in rest_src.items()}
    frames = g.frames(FPS, anim_index(g, anim))
    names = [n for n in g.names().values() if n in rest]
    return names, rest, frames, FPS


def to_godot_m(m4):
    """A joint's world matrix as (rotation, position): glTF's axes are Godot's; the rig's root may
    carry a scale (Mixamo's centimetres), taken out of the rotation."""
    return gltf_motion.rotation_of(m4), m4[:3, 3].copy()


# --- The retarget ---------------------------------------------------------------------------------

def retarget(names, rest, frames, rig, source_name=""):
    """Our clip from the source's frames: per frame each segment's local quaternion, the root's
    travel and heading, the hips' height. Returns the clip dict (before trimming) and notes."""
    bones = match_bones(names)
    missing = [s for s in rig if s not in bones]
    if "pelvis" not in bones or "thigh_l" not in bones or "thigh_r" not in bones:
        sys.exit("retarget_motion: can't find the hips or thighs among %s" % names)
    notes = {"bones": bones, "missing": missing}

    def head_of(bone, pose):
        R, t = to_godot_m(pose[bone])
        return t

    # Rest directions of each source bone we use, in Godot axes: towards the next segment's bone
    # head when there is one, else along the bone itself.
    low = {n.lower(): n for n in names}

    def rest_dir(seg):
        b = bones[seg]
        R0, h0 = to_godot_m(rest[b][0])
        tip = TIP.get(seg)
        if tip and tip in bones:
            _, ht = to_godot_m(rest[bones[tip]][0])
            d = ht - h0
            if np.linalg.norm(d) > 1e-6:
                return d
        known = (rig_of(names) or {}).get("tips", {}).get(seg)
        if known and known in rest:
            _, ht = to_godot_m(rest[known][0])
            d = ht - h0
            if np.linalg.norm(d) > 1e-6:
                return d
        for pat in TIP_SRC.get(seg, []):
            hit = [n for n in names if re.search(pat, n.lower()) and n in rest]
            if hit:
                hit.sort(key=len)
                _, ht = to_godot_m(rest[hit[0]][0])
                d = ht - h0
                if np.linalg.norm(d) > 1e-6:
                    return d
        # No tip joint: along the parent bone's line (a childless end carries on straight).
        parent = PARENT.get(seg)
        if parent and parent in bones:
            _, hp = to_godot_m(rest[bones[parent]][0])
            d = h0 - hp
            if np.linalg.norm(d) > 1e-6:
                return d
        return np.array([0.0, -1.0, 0.0])

    rest_R = {seg: to_godot_m(rest[bones[seg]][0])[0] for seg in bones}
    rest_pose = {bones[seg]: rest[bones[seg]][0] for seg in bones}  # the rest as a pose, for its facing

    # His facing, from his joints (the thighs' and the shoulders' left-to-right lines, level, turned
    # a right angle): the source's rest may face any way (Mixamo's faces +z in these axes). The
    # first frame's facing is turned to -z, the way our clips start; each frame's heading is read
    # the same way for the clip's yaw.
    def facing(pose):
        f = np.zeros(3)
        for l, r in (("thigh_l", "thigh_r"), ("upper_arm_l", "upper_arm_r")):
            if l in bones and r in bones:
                left = to_godot_m(pose[bones[l]])[1] - to_godot_m(pose[bones[r]])[1]
                left[1] = 0.0
                if np.linalg.norm(left) > 1e-6:
                    f += np.cross(left / np.linalg.norm(left), np.array([0.0, 1.0, 0.0]))
        return f / np.linalg.norm(f) if np.linalg.norm(f) > 1e-6 else np.array([0.0, 0.0, -1.0])

    def yaw_of_dir(f):
        return math.atan2(-f[0], -f[2])

    H = yaw_m(-yaw_of_dir(facing(frames[0])))
    # The fixed turns: the whole rest turned to face -z as ours does (W: without it every limb
    # would carry the facing's half turn as a twist about its own length), then each limb's rest
    # bone onto ours by the shortest turn; the pelvis takes W alone.
    W = yaw_m(-yaw_of_dir(facing(rest_pose)))
    q_off = {}
    for seg in rig:
        if seg not in bones:
            continue
        if seg == "pelvis":
            q_off[seg] = W
            continue
        ours = np.array(rig[seg]["b"]) - np.array(rig[seg]["a"])
        q_off[seg] = arc(W @ rest_dir(seg), ours) @ W

    def globals_at(pose):
        g = {}
        for seg in rig:
            if seg not in bones:
                continue
            R = to_godot_m(pose[bones[seg]])[0]
            g[seg] = H @ R @ rest_R[seg].T @ q_off[seg].T
        return g

    # Scale: the source's leg against ours (thigh + shin, from the rest pose).
    def length(a, b):
        return float(np.linalg.norm(to_godot_m(rest[bones[a]][0])[1] - to_godot_m(rest[bones[b]][0])[1]))
    leg_src = 0.0
    if "shin_l" in bones and "foot_l" in bones:
        leg_src = length("thigh_l", "shin_l") + length("shin_l", "foot_l")
    leg_ours = float(np.linalg.norm(np.array(rig["thigh_l"]["a"]) - np.array(rig["thigh_l"]["b"]))
                     + np.linalg.norm(np.array(rig["shin_l"]["a"]) - np.array(rig["shin_l"]["b"])))
    scale = leg_ours / leg_src if leg_src > 1e-3 else 1.0
    notes["leg_source_m"] = round(leg_src, 3)
    notes["scale"] = round(scale, 3)

    out_frames, root, yaw, hips = [], [], [], []
    feet_l, feet_r, hips_path, hands_path = [], [], [], []
    hip0 = None
    for pose in frames:
        g = globals_at(pose)
        local = {}
        for seg in rig:
            if seg not in g:
                continue
            parent = PARENT[seg]
            gp = g[parent] if parent and parent in g else np.eye(3)
            local[seg] = quat(gp.T @ g[seg])
        out_frames.append(local)
        hp = H @ to_godot_m(pose[bones["pelvis"]])[1]
        if hip0 is None:
            hip0 = hp.copy()
        p = (hp - hip0) * scale
        root.append([round(float(p[0]), 4), round(float(p[1]), 4), round(float(p[2]), 4)])
        yaw.append(round(yaw_of_dir(H @ facing(pose)), 4))
        hj = []
        for s in ("thigh_l", "thigh_r"):
            hj.append(H @ to_godot_m(pose[bones[s]])[1])
        hips.append(float((hj[0][1] + hj[1][1]) / 2))
        hips_path.append([round(float(c), 4) for c in hp])
        if "hand_l" in bones and "hand_r" in bones:
            hm = (H @ to_godot_m(pose[bones["hand_l"]])[1] + H @ to_godot_m(pose[bones["hand_r"]])[1]) * 0.5
            hands_path.append([round(float(c), 4) for c in hm])
        for seg, lst in (("foot_l", feet_l), ("foot_r", feet_r)):
            lst.append(H @ to_godot_m(pose[bones[seg]])[1] if seg in bones else hp)
    # The ground: the lowest the feet get over the clip; hips over it in leg lengths.
    feet = np.array(feet_l + feet_r)
    ground = float(np.percentile(feet[:, 1], 3)) if len(feet) else 0.0
    hip_height = [round((h - ground) / leg_src, 4) if leg_src > 1e-3 else -1.0 for h in hips]
    clip = {"name": source_name, "fps": FPS, "frames": out_frames, "root": root, "yaw": yaw, "hip_height": hip_height,
            "feet": {"l": [[round(float(c), 4) for c in p] for p in feet_l], "r": [[round(float(c), 4) for c in p] for p in feet_r]},
            "hips_path": hips_path, "hands_path": hands_path, "ground": round(ground, 4), "scale": round(scale, 4)}
    return clip, notes


# --- Trimming and the feet ------------------------------------------------------------------------

def energy(clip):
    """How much he moves each frame: the sum of the joints' turning (rad) plus the root's travel."""
    fr = clip["frames"]
    e = [0.0]
    for i in range(1, len(fr)):
        s = 0.0
        for seg, q in fr[i].items():
            p = fr[i - 1].get(seg, q)
            d = abs(sum(a * b for a, b in zip(p, q)))
            s += 2 * math.acos(min(1.0, d))
        r0, r1 = clip["root"][i - 1], clip["root"][i]
        s += 20.0 * math.dist(r0, r1)
        e.append(s)
    return e


def trim(clip, threshold=0.03, keep_s=0.1):
    """Cut the still start and end (frames whose motion is under `threshold` of the peak), keeping
    a tenth of a second each side. Returns the frames cut (start, end)."""
    e = energy(clip)
    if len(e) < 3:
        return 0, 0
    peak = max(e[1:]) or 1.0
    live = [i for i, v in enumerate(e) if v >= threshold * peak]
    if not live:
        return 0, 0
    a = max(0, live[0] - int(keep_s * clip["fps"]))
    b = min(len(e) - 1, live[-1] + int(keep_s * clip["fps"]))
    _cut(clip, a, b)
    return a, len(e) - 1 - b


def _cut(clip, a, b):
    for k in ("frames", "root", "yaw", "hip_height", "hips_path", "hands_path"):
        if clip.get(k):
            clip[k] = clip[k][a:b + 1]
    for side in clip["feet"]:
        clip["feet"][side] = clip["feet"][side][a:b + 1]
    r0 = clip["root"][0]
    clip["root"] = [[round(p[0] - r0[0], 4), round(p[1] - r0[1], 4), round(p[2] - r0[2], 4)] for p in clip["root"]]
    y0 = clip["yaw"][0]
    clip["yaw"] = [round(math.remainder(y - y0, math.tau), 4) for y in clip["yaw"]]
    if "events" in clip:
        clip["events"] = {k: round(max(0.0, v - a / clip["fps"]), 3) for k, v in clip["events"].items()}


def hold_feet(clip, stand_height=0.08, stand_speed=0.6):
    """Foot sliding: while a foot stands (near the ground and slow in the source), the root's travel
    is corrected by that foot's drift, frame by frame, so in the game the planted foot stays where it
    was put down (the legs' angles are the source's; only the root moves differently). Both feet
    standing, each takes half. The correction is a running offset of the root's path, so the path
    stays continuous. Returns the feet's slide while standing (m, summed over the clip) before and
    after, in our metres."""
    fps = clip["fps"]
    scale = clip["scale"]
    feet = {s: np.array(clip["feet"][s]) for s in ("l", "r")}
    n = len(clip["root"])
    if n < 3:
        return 0.0, 0.0
    ground = clip["ground"]
    root = np.array(clip["root"], dtype=float)
    vel = {s: np.vstack([np.zeros((1, 3)), np.diff(feet[s], axis=0) * fps]) for s in feet}
    standing = {s: [(feet[s][i][1] - ground) * scale < stand_height and np.linalg.norm(vel[s][i][[0, 2]]) * scale < stand_speed
                    for i in range(n)] for s in feet}
    before = 0.0
    offset = np.zeros(3)
    out = root.copy()
    for i in range(1, n):
        drift = np.zeros(3)
        k = 0
        for s in feet:
            if standing[s][i] and standing[s][i - 1]:
                d = (feet[s][i] - feet[s][i - 1]) * scale
                d[1] = 0.0
                before += float(np.linalg.norm(d))
                drift += d
                k += 1
        if k:
            offset -= drift / k
        out[i] = root[i] + offset
    after = 0.0
    for i in range(1, n):
        for s in feet:
            if standing[s][i] and standing[s][i - 1]:
                d = (feet[s][i] - feet[s][i - 1]) * scale + (out[i] - out[i - 1]) - (root[i] - root[i - 1])
                after += float(np.linalg.norm(d[[0, 2]]))
    clip["root"] = [[round(float(c), 4) for c in p] for p in out]
    clip["stand"] = {s: [bool(v) for v in standing[s]] for s in standing}
    return round(before, 3), round(after, 3)


def hands_high(clip):
    """When his hands are highest (s): water scooped reaches his face about then."""
    hp = np.array(clip["hands_path"]) if clip.get("hands_path") else None
    if hp is None or len(hp) < 3:
        return round(clip["frames"].__len__() / clip["fps"] * 0.5, 3)
    return round(int(np.argmax(hp[:, 1])) / clip["fps"], 3)


def find_strike(clip, part="foot_r"):
    """When the kicking foot is fastest (s): the moment it would land."""
    return strike_marks(clip, part)["strike"]


def strike_marks(clip, part="foot_r"):
    """The kick read off the clip, as marks for the game (MotionClip.events): `strike` (s, the
    foot at its fastest), `reach_m` (the foot's reach from his hips then, level, at our size),
    `kick_height_m` (the foot over the ground then), `kick_dir` (+1 behind him, -1 in front: the
    foot's way from his hips along his facing, which the model may not have followed)."""
    side = "r" if part.endswith("_r") else "l"
    f = np.array(clip["feet"][side])
    if len(f) < 3:
        return {"strike": 0.0}
    v = np.linalg.norm(np.diff(f, axis=0), axis=1)
    i = int(np.argmax(v)) + 1
    hp = np.array(clip["hips_path"][min(i, len(clip["hips_path"]) - 1)])
    d = f[i] - hp
    yaw_i = clip["yaw"][min(i, len(clip["yaw"]) - 1)]
    # His facing then (the clip starts facing -z; yaw turns it): the foot's part along it.
    fwd = np.array([-math.sin(yaw_i), 0.0, -math.cos(yaw_i)])
    along = float(np.dot(np.array([d[0], 0.0, d[2]]), fwd))
    # Where the boot is at the strike, in the clip's own frame (he starts facing -z at the
    # origin): his hips then, and the boot from his hips. Whoever plays it turns and places him
    # from these so the boot's line passes through what he's to kick.
    hp_scaled = hp * clip["scale"]
    return {"strike": round(i / clip["fps"], 3), "reach_m": round(float(np.linalg.norm([d[0], d[2]])) * clip["scale"], 3),
            "kick_height_m": round(float(f[i][1] - clip["ground"]) * clip["scale"], 3), "kick_dir": -1.0 if along > 0 else 1.0,
            "strike_hips_x": round(float(hp_scaled[0]), 3), "strike_hips_z": round(float(hp_scaled[2]), 3),
            "reach_x": round(float(d[0]) * clip["scale"], 3), "reach_z": round(float(d[2]) * clip["scale"], 3)}


# --- Writing --------------------------------------------------------------------------------------

def write_json(clip, path, source, strikes=(), events=None, credit=""):
    out = {"name": clip["name"], "fps": clip["fps"], "source": source, "credit": credit,
           "frames": clip["frames"], "root": clip["root"], "yaw": clip["yaw"], "hip_height": clip["hip_height"],
           "events": events or {}, "strikes": list(strikes), "length_s": round((len(clip["frames"]) - 1) / clip["fps"], 3)}
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    return out


def write_gltf(clip, rig, path):
    """The clip on a Blender armature built as our rig (a bone a segment, its head at the pivot),
    exported as glTF with the animation: the record of the motion a Godot scene can import."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    arm_data = bpy.data.armatures.new("SaltCreekRig")
    arm = bpy.data.objects.new("SaltCreekRig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    G2B = np.array([[1.0, 0, 0], [0, 0, -1.0], [0, 1.0, 0]])  # Godot (y up) -> Blender (z up)
    order = [s for s in ("pelvis", "abdomen", "chest", "neck", "head", "thigh_l", "shin_l", "foot_l", "thigh_r", "shin_r",
                         "foot_r", "upper_arm_l", "forearm_l", "hand_l", "upper_arm_r", "forearm_r", "hand_r") if s in rig]
    eb = {}
    for seg in order:
        b = arm_data.edit_bones.new(seg)
        head = G2B @ np.array(rig[seg]["pivot"])
        tail = G2B @ np.array(rig[seg]["b"])
        if np.linalg.norm(tail - head) < 0.02:
            tail = head + np.array([0, 0, 0.05])
        b.head, b.tail = Vector(head), Vector(tail)
        if PARENT[seg] and PARENT[seg] in eb:
            b.parent = eb[PARENT[seg]]
        eb[seg] = b
    bpy.ops.object.mode_set(mode="POSE")
    scene = bpy.context.scene
    scene.render.fps = clip["fps"]
    scene.frame_start, scene.frame_end = 0, len(clip["frames"]) - 1
    arm.animation_data_create()
    action = bpy.data.actions.new(clip["name"])
    arm.animation_data.action = action
    rest_q = {}
    for seg in order:
        pb = arm.pose.bones[seg]
        pb.rotation_mode = "QUATERNION"
    for i, fr in enumerate(clip["frames"]):
        for seg in order:
            if seg not in fr:
                continue
            pb = arm.pose.bones[seg]
            x, y, z, w = fr[seg]
            # Our pivot's turn (Godot axes) -> the bone's local pose turn: the same turn seen in the
            # bone's own frame (the bone rest basis), since our pivots have no rest turn.
            qg = Quaternion((w, x, z, -y))  # Godot (y up) quaternion into Blender's axes (z up)
            Rb = pb.bone.matrix_local.to_3x3() if pb.parent is None else (pb.parent.bone.matrix_local.inverted() @ pb.bone.matrix_local).to_3x3()
            qb = (Rb.inverted().to_quaternion() @ qg @ Rb.to_quaternion())
            pb.rotation_quaternion = qb
            pb.keyframe_insert("rotation_quaternion", frame=i)
        # The root's travel on the armature object (Godot axes -> Blender's).
        arm.location = Vector(G2B @ np.array(clip["root"][i]))
        arm.keyframe_insert("location", frame=i)
    bpy.ops.object.mode_set(mode="OBJECT")
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_animations=True, export_skins=False,
                              export_apply=False, use_selection=False)


# --- The report (which take) ----------------------------------------------------------------------

def judge(clip, move, notes):
    """Numbers a reader can weigh: length, travel, the peak speed of the part that matters, how still
    the start is, foot slide, missing bones. Higher `score` is better for the move's purpose."""
    n = len(clip["frames"])
    fps = clip["fps"]
    root = np.array(clip["root"])
    travel = float(np.linalg.norm((root[-1] - root[0])[[0, 2]])) if n > 1 else 0.0
    feet = {s: np.array(clip["feet"][s]) * clip["scale"] for s in ("l", "r")}
    speed = {s: float(np.max(np.linalg.norm(np.diff(feet[s], axis=0), axis=1)) * fps) if n > 2 else 0.0 for s in feet}
    hands = {}
    for s in ("hand_l", "hand_r"):
        pass
    e = energy(clip)
    j = {"frames": n, "seconds": round((n - 1) / fps, 2), "travel_m": round(travel, 2),
         "foot_peak_mps": {s: round(v, 2) for s, v in speed.items()},
         "hip_min_legs": round(min(clip["hip_height"]), 3), "hip_max_legs": round(max(clip["hip_height"]), 3),
         "jitter": round(float(np.mean(np.abs(np.diff(e)))), 4) if n > 2 else 0.0,
         "slide_m": notes.get("slide_after"), "missing": notes.get("missing", [])}
    score = 0.0
    if move == "walk_angry":
        score = travel * 2.0 - abs(j["seconds"] - 3.0) * 0.3   # he should cross the room
    elif move.startswith("kick"):
        ev = notes.get("events", {})
        height = float(ev.get("kick_height_m", 0.5))
        # The right foot fast, the left planted, no walking off, the boot low (a chair's legs:
        # under the seat, 0.47 m), and backward as asked (a front kick still works, turned round).
        score = speed["r"] * 1.0 - speed["l"] * 0.5 - travel * 1.0 - max(0.0, height - 0.35) * 4.0 + (0.5 if ev.get("kick_dir", 1) > 0 else 0.0)
        j["kick"] = {k: ev.get(k) for k in ("strike", "reach_m", "kick_height_m", "kick_dir")}
    elif move == "draw":
        score = 1.0 - travel * 2.0 - j["jitter"] * 10.0            # stands still, a clean motion
    elif move == "stand_over":
        score = (1.0 - j["hip_min_legs"]) * 2.0 - travel * 2.0       # leans down, stays put
    elif move.startswith("walk_"):
        # A walk that goes (travel), steady (low jitter), no slide left; an old man's or a drunk's
        # may be slow: travel over a metre is enough.
        score = min(travel, 3.0) * 1.0 - j["jitter"] * 20.0 + (1.0 if travel > 1.0 else -2.0)
    elif move in ("wipe_bar", "mop_floor"):
        score = 1.0 - travel * 1.5 - j["jitter"] * 10.0 + (0.5 if j["seconds"] > 3.0 else 0.0)  # stays at his work
    elif move.startswith("scoop"):
        score = (1.0 - j["hip_min_legs"]) * 2.0 - travel * 1.5 + (0.5 if j["seconds"] > 3.5 else 0.0)  # bends down, stays
    score -= 0.5 * len(j["missing"]) + 2.0 * (j["slide_m"] or 0.0)
    j["score"] = round(score, 3)
    return j


# --- Main -----------------------------------------------------------------------------------------

def process(path, name, out_dir, rig, trim_th=0.03, strikes=(), events_spec=None, feet=True, credit="", rest_path=None):
    names, rest, frames, src_fps = read_source(path, rest_path, os.path.join(out_dir, "converted"))
    clip, notes = retarget(names, rest, frames, rig, name)
    notes["source_fps"] = src_fps
    notes["frames_in"] = len(frames)
    cut = trim(clip, trim_th) if trim_th > 0 else (0, 0)
    notes["trimmed"] = cut
    if feet:
        before, after = hold_feet(clip)
        notes["slide_before"], notes["slide_after"] = before, after
    events = {}
    for spec in (events_spec or []):
        k, v = spec.split(":", 1)
        if v == "auto":
            marks = strike_marks(clip, strikes[0] if strikes else "foot_r")
            events[k] = marks["strike"]
            if k == "strike":
                events.update({kk: vv for kk, vv in marks.items() if kk != "strike"})
        elif v == "hands_high":
            events[k] = hands_high(clip)
        else:
            events[k] = float(v)
    notes["events"] = events
    json_path = os.path.join(out_dir, name + ".json")
    write_json(clip, json_path, os.path.basename(path), strikes, events, credit)
    try:
        write_gltf(clip, rig, os.path.join(out_dir, name + ".glb"))
    except Exception as e:  # the JSON is what the game plays; the glTF is the record
        notes["gltf_error"] = str(e)[:200]
    notes["json"] = json_path
    return clip, notes


def main(argv):
    rig = json.load(open(RIG_REST))
    out_dir = opt("out", os.path.join(ROOT, "assets", "animations"), argv)
    report_dir = opt("report", None, argv)
    credit = opt("credit", "", argv)
    set_dir = opt("set", None, argv)
    strikes = [s for s in (opt("strike", "", argv) or "").split(",") if s]
    events_spec = [e for e in (opt("event", "", argv) or "").split(",") if e]
    trim_th = float(opt("trim", "0.03", argv))
    feet = not opt("no-feet", False, argv)
    rest_path = opt("rest", None, argv)
    if set_dir:
        # Every take in the folder (<move>_<take>.glb|fbx|bvh): each retargeted to build/, judged;
        # the best of each move copied to out_dir under the move's name.
        import shutil
        takes = sorted(f for f in os.listdir(set_dir) if f.lower().endswith((".glb", ".gltf", ".fbx", ".bvh")))
        work = os.path.join(report_dir or os.path.join(ROOT, "build", "motion"), "takes")
        os.makedirs(work, exist_ok=True)
        results = {}
        for f in takes:
            m = re.match(r"(.+)_(\d+)\.\w+$", f)
            move, take_i = (m.group(1), int(m.group(2))) if m else (os.path.splitext(f)[0], 1)
            st = ["foot_r"] if move.startswith("kick") else strikes
            ev = ["strike:auto"] if move.startswith("kick") else (["splash:hands_high"] if move.startswith("scoop") else events_spec)
            clip, notes = process(os.path.join(set_dir, f), "%s_%02d" % (move, take_i), work, rig, trim_th, st, ev, feet, credit, rest_path)
            j = judge(clip, move, notes)
            j["notes"] = {k: v for k, v in notes.items() if k != "bones"}
            j["bones"] = notes["bones"]
            results.setdefault(move, {})[take_i] = j
            print("%s take %d: %s" % (move, take_i, json.dumps({k: j[k] for k in ("seconds", "travel_m", "foot_peak_mps", "slide_m", "score")})))
        best = {}
        for move, by in results.items():
            best[move] = max(by, key=lambda t: by[t]["score"])
            src = os.path.join(work, "%s_%02d" % (move, best[move]))
            os.makedirs(out_dir, exist_ok=True)
            for ext in (".json", ".glb"):
                if os.path.exists(src + ext):
                    shutil.copyfile(src + ext, os.path.join(out_dir, move + ext))
            # The game's clip carries its own name.
            jp = os.path.join(out_dir, move + ".json")
            d = json.load(open(jp))
            d["name"] = move
            d["take"] = best[move]
            json.dump(d, open(jp, "w"), separators=(",", ":"))
        rep = {"takes": results, "best": best}
        os.makedirs(report_dir or work, exist_ok=True)
        with open(os.path.join(report_dir or work, "takes.json"), "w") as f:
            json.dump(rep, f, indent=1, sort_keys=True, default=str)
        print("best:", json.dumps(best))
        return
    path = [a for a in argv if not a.startswith("--")][0]
    name = opt("name", os.path.splitext(os.path.basename(path))[0], argv)
    clip, notes = process(path, name, out_dir, rig, trim_th, strikes, events_spec, feet, credit, rest_path)
    print(json.dumps({"name": name, "frames": len(clip["frames"]), "notes": {k: v for k, v in notes.items() if k != "bones"}}))


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(args)
