"""The saloon cinematic as a film (docs/briefs/cinematic.md, step 2): the set and men from
saloon.py, animated pose to pose and shot by shot on the timeline in timeline.py, rendered by Cycles.

    python tools/cinematic/film.py --sheet=OUT                    # key frames of every shot, small and fast
    python tools/cinematic/film.py --render=DIR --quality=preview|final [--chunk=i --chunks=n]
    python tools/cinematic/film.py --blend=FILE                   # the animated scene, to open in Blender

How the men move: each man is a list of keys (frame, the way he faces, where his pelvis is, a pose).
A pose aims his bones along world directions (saloon.aim); every key is worked out on a fresh rest
pose and stored, then all are written as keyframes, so Blender eases between them. Their faces are
their 20 shape keys (smirk, scowl, terror, blinks, the mouth for the line).
"""
import math
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402  (the bpy module first: it brings mathutils)
from mathutils import Matrix, Vector  # noqa: E402

import saloon as S  # noqa: E402
import timeline as T  # noqa: E402

UP = Vector((0.0, 0.0, 1.0))
F = T.frame
FONT = os.path.join(S.ROOT, "build", "fonts", "Rye-Regular.ttf")

# Where the action happens (the table's space, Blender's: +Y toward the doors).
TB = S.TABLE
CHEAT_CHAIR = TB + Vector((0.14, 0.78, 0.0))
LYLE_CHAIR = TB + Vector((0.74, 0.06, 0.0))
P_KICK = TB + Vector((0.88, 1.02, 0.0))      # Lyle beside the cheater's chair
P_OVER = TB + Vector((0.80, 1.55, 0.0))      # Lyle over him on the floor
FLOOR_PELVIS = TB + Vector((0.16, 1.18, 0.11))  # the cheater's pelvis lying down
CHEAT_CHEST = TB + Vector((0.16, 1.55, 0.25))


def side_of(f):
    return f.cross(UP)          # his right


# ---------------------------------------------------------------- poses


def legs_sit(arm, f, spread=0.08):
    s = side_of(f)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "thigh_" + b, f - UP * 0.08 + s * spread * k)
        S.aim(arm, "shin_" + b, -UP + f * 0.12)
        S.aim(arm, "foot_" + b, f - UP * 0.25)


def legs_stand(arm, f, wide=0.06):
    s = side_of(f)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "thigh_" + b, -UP + s * wide * k + f * 0.02)
        S.aim(arm, "shin_" + b, -UP + f * -0.02)
        S.aim(arm, "foot_" + b, f - UP * 0.3)


def torso(arm, f, lean=0.0, sway=0.0, back=0.0):
    s = side_of(f)
    S.aim(arm, "abdomen", UP + f * lean + s * sway - f * back)
    S.aim(arm, "chest", UP + f * (lean + 0.08) + s * sway - f * back)
    S.aim(arm, "neck", UP + f * 0.06)


def head(arm, f, turn=0.0, nod=0.0, roll=0.0):
    if turn:
        S.turn(arm, "head", UP, turn)
    if nod:
        S.turn(arm, "head", side_of(f), nod)     # + chin up
    if roll:
        S.turn(arm, "head", f, roll)


def arms_table(arm, f, reach=0.0):
    s = side_of(f)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "upper_arm_" + b, -UP * 0.85 + f * (0.55 + reach) + s * 0.08 * k)
        S.aim(arm, "forearm_" + b, f + s * -0.45 * k + UP * 0.05)
        S.aim(arm, "hand_" + b, f + s * -0.3 * k - UP * 0.15)


def arms_down(arm, f, out=0.12, which="rl"):
    s = side_of(f)
    for k, b in ((1, "r"), (-1, "l")):
        if b not in which:
            continue
        S.aim(arm, "upper_arm_" + b, -UP + s * out * k + f * 0.04)
        S.aim(arm, "forearm_" + b, -UP + f * 0.18 + s * 0.04 * k)
        S.aim(arm, "hand_" + b, -UP + f * 0.12)


def bone_world(arm, name, tail=False):
    pb = arm.pose.bones[name]
    bpy.context.view_layer.update()
    return arm.matrix_world @ (pb.tail if tail else pb.head)


def aim_arm_at(arm, b, point, bend=0.0):
    """His arm (b: 'r' or 'l') straight at a world point, the elbow bent `bend` (0..1) downward."""
    sh = bone_world(arm, "upper_arm_" + b)
    d = (Vector(point) - sh).normalized()
    S.aim(arm, "upper_arm_" + b, d - UP * bend * 0.6)
    S.aim(arm, "forearm_" + b, d + UP * bend * 0.3)
    S.aim(arm, "hand_" + b, d)


# The men's poses, each pose(arm, f).

def p_sit(lean=0.2, turn=0.0, nod=0.0, reach=0.0):
    def p(arm, f):
        legs_sit(arm, f)
        torso(arm, f, lean)
        arms_table(arm, f, reach)
        head(arm, f, turn, nod)
    return p


def p_stand(turn=0.0, nod=0.0, lean=0.0, arms=True):
    def p(arm, f):
        legs_stand(arm, f)
        torso(arm, f, lean)
        if arms:
            arms_down(arm, f)
        head(arm, f, turn, nod)
    return p


def p_rise(arm, f):
    s = side_of(f)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "thigh_" + b, f * 0.75 - UP * 0.65 + s * 0.06 * k)
        S.aim(arm, "shin_" + b, -UP - f * 0.08)
        S.aim(arm, "foot_" + b, f - UP * 0.3)
    torso(arm, f, 0.85)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "upper_arm_" + b, -UP * 0.7 + f * 0.6 + s * 0.15 * k)
        S.aim(arm, "forearm_" + b, f * 0.6 - UP * 0.6)
    head(arm, f, 0.0, 25.0)


def p_step(lead="r"):
    def p(arm, f):
        a, b = (lead, "l" if lead == "r" else "r")
        S.aim(arm, "thigh_" + a, -UP + f * 0.4)
        S.aim(arm, "shin_" + a, -UP + f * 0.15)
        S.aim(arm, "foot_" + a, f - UP * 0.2)
        S.aim(arm, "thigh_" + b, -UP - f * 0.3)
        S.aim(arm, "shin_" + b, -UP - f * 0.5)
        S.aim(arm, "foot_" + b, f - UP * 0.6)
        torso(arm, f, 0.08)
        arms_down(arm, f)
        S.aim(arm, "upper_arm_" + a, -UP - f * 0.25)
        S.aim(arm, "upper_arm_" + b, -UP + f * 0.25)
        head(arm, f, 0.0, -6.0)
    return p


def p_kick(phase):
    """Lyle's kick out to his front, the right boot at the chair's near legs."""
    def p(arm, f):
        s = side_of(f)
        S.aim(arm, "thigh_l", -UP - f * 0.05 - s * 0.05)
        S.aim(arm, "shin_l", -UP + f * 0.05)
        S.aim(arm, "foot_l", f - UP * 0.3)
        if phase == "wind":
            S.aim(arm, "thigh_r", -UP * 0.6 + f * 0.55)
            S.aim(arm, "shin_r", -UP - f * 0.35)
            torso(arm, f, -0.05)
        elif phase == "hit":
            S.aim(arm, "thigh_r", f * 0.85 - UP * 0.55 - s * 0.12)
            S.aim(arm, "shin_r", f * 0.9 - UP * 0.4 - s * 0.15)
            torso(arm, f, -0.3)
        else:   # follow-through, coming down
            S.aim(arm, "thigh_r", -UP * 0.75 + f * 0.45)
            S.aim(arm, "shin_r", -UP + f * 0.1)
            torso(arm, f, -0.1)
        S.aim(arm, "foot_r", f - UP * 0.1)
        S.aim(arm, "upper_arm_r", -UP * 0.7 - f * 0.2 + s * 0.45)
        S.aim(arm, "forearm_r", -UP * 0.5 + f * 0.4 + s * 0.2)
        S.aim(arm, "upper_arm_l", -UP * 0.7 + f * 0.2 - s * 0.45)
        S.aim(arm, "forearm_l", -UP * 0.3 + f * 0.5 - s * 0.3)
        head(arm, f, 0.0, -14.0)
    return p


def p_draw(phase, target=None):
    def p(arm, f):
        s = side_of(f)
        legs_stand(arm, f, 0.1)
        torso(arm, f, 0.12 if phase == "aim" else 0.04)
        arms_down(arm, f, which="l")
        S.aim(arm, "upper_arm_l", -UP + s * -0.25 - f * 0.1)
        if phase == "holster":
            S.aim(arm, "upper_arm_r", -UP * 0.95 + s * 0.3 - f * 0.15)
            S.aim(arm, "forearm_r", -UP * 0.75 + f * 0.3 + s * 0.08)
            S.aim(arm, "hand_r", -UP + f * 0.2)
        elif phase == "clear":
            S.aim(arm, "upper_arm_r", -UP * 0.75 + f * 0.25 + s * 0.3)
            S.aim(arm, "forearm_r", f * 0.9 + UP * 0.2 + s * 0.05)
            S.aim(arm, "hand_r", f + UP * 0.1)
        else:
            aim_arm_at(arm, "r", target, bend=0.15)
        head(arm, f, 0.0, -18.0 if phase == "aim" else -10.0)
    return p


def p_fall(phase):
    """The cheater going over backwards when his chair goes: 'shock', 'drop', 'sit', 'back'."""
    def p(arm, f):
        s = side_of(f)
        back = -f
        if phase == "shock":
            legs_sit(arm, f)
            torso(arm, f, -0.2)
            for k, b in ((1, "r"), (-1, "l")):
                S.aim(arm, "upper_arm_" + b, -UP * 0.3 + f * 0.6 + s * 0.4 * k)
                S.aim(arm, "forearm_" + b, UP * 0.5 + f * 0.7)
            head(arm, f, 0.0, 10.0)
        elif phase == "drop":
            for k, b in ((1, "r"), (-1, "l")):
                S.aim(arm, "thigh_" + b, f + UP * 0.25 + s * 0.12 * k)
                S.aim(arm, "shin_" + b, -UP * 0.6 + f * 0.6)
            S.aim(arm, "pelvis", UP + back * 0.45)
            torso(arm, f, -0.6)
            for k, b in ((1, "r"), (-1, "l")):
                S.aim(arm, "upper_arm_" + b, UP * 0.5 + s * 0.8 * k + f * 0.2)
                S.aim(arm, "forearm_" + b, UP + s * 0.4 * k)
            head(arm, f, 0.0, -15.0)
        elif phase == "sit":
            for k, b in ((1, "r"), (-1, "l")):
                S.aim(arm, "thigh_" + b, f + UP * 0.6 + s * 0.15 * k)
                S.aim(arm, "shin_" + b, f + UP * 0.1)
            S.aim(arm, "pelvis", UP * 0.7 + back * 0.8)
            S.aim(arm, "abdomen", UP * 0.6 + back * 0.85)
            S.aim(arm, "chest", UP * 0.55 + back * 0.85)
            S.aim(arm, "neck", UP * 0.8 + back * 0.5)
            for k, b in ((1, "r"), (-1, "l")):
                S.aim(arm, "upper_arm_" + b, -UP * 0.2 + s * 0.9 * k + back * 0.3)
                S.aim(arm, "forearm_" + b, -UP * 0.5 + s * 0.6 * k)
            head(arm, f, 0.0, -25.0)
        else:   # flat on his back
            lie(arm, f, bounce=(phase == "bounce"))
    return p


def lie(arm, f, bounce=False, dead=False):
    s = side_of(f)
    back = -f
    up_c = 0.12 if bounce else 0.02
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "thigh_" + b, f * 0.75 + UP * (0.4 if not dead else 0.15) + s * 0.18 * k)
        S.aim(arm, "shin_" + b, f * 0.7 - UP * (0.55 if not dead else 0.2) + s * 0.05 * k)
        S.aim(arm, "foot_" + b, UP + f * 0.3)
    S.aim(arm, "pelvis", back + UP * 0.03)
    S.aim(arm, "abdomen", back + UP * up_c)
    S.aim(arm, "chest", back + UP * up_c)
    S.aim(arm, "neck", back + UP * 0.08)
    for k, b in ((1, "r"), (-1, "l")):
        S.aim(arm, "upper_arm_" + b, s * 0.9 * k + back * 0.35 - UP * 0.15)
        S.aim(arm, "forearm_" + b, s * 0.4 * k + back * 0.7 - UP * 0.1)
        S.aim(arm, "hand_" + b, s * 0.3 * k + back * 0.8 - UP * 0.2)
    head(arm, f, 0.0, 0.0, 28.0 if dead else 8.0)


def p_lie(dead=False, bounce=False):
    def p(arm, f):
        lie(arm, f, bounce=bounce, dead=dead)
    return p


def p_propped(tremble=0.0, flinch=0.0):
    """Up on his left elbow, his right hand up at Lyle, palm out."""
    def p(arm, f):
        s = side_of(f)
        back = -f
        to_lyle = (P_OVER + Vector((0, 0, 1.4)) - CHEAT_CHEST).normalized()
        for k, b in ((1, "r"), (-1, "l")):
            S.aim(arm, "thigh_" + b, f * 0.8 + UP * 0.45 + s * 0.15 * k)
            S.aim(arm, "shin_" + b, f * 0.6 - UP * 0.6)
            S.aim(arm, "foot_" + b, UP + f * 0.4)
        S.aim(arm, "pelvis", back + UP * 0.35)
        S.aim(arm, "abdomen", back * 0.9 + UP * 0.55 + s * 0.1)
        S.aim(arm, "chest", back * 0.7 + UP * 0.75 + s * 0.15)
        S.aim(arm, "neck", UP + back * 0.2 - f * flinch)
        # Left: the elbow on the floor behind him.
        S.aim(arm, "upper_arm_l", -UP * 0.8 + back * 0.3 - s * 0.3)
        S.aim(arm, "forearm_l", back * 0.5 - s * 0.6 - UP * 0.15)
        S.aim(arm, "hand_l", back * 0.4 - s * 0.6 - UP * 0.3)
        # Right: up at him.
        S.aim(arm, "upper_arm_r", to_lyle * 0.8 + UP * 0.3 + s * 0.1)
        S.aim(arm, "forearm_r", to_lyle * 0.3 + UP * 0.9 + s * tremble)
        S.aim(arm, "hand_r", UP + to_lyle * -0.6 + s * tremble)
        S.turn(arm, "head", UP, -35.0 - 10 * flinch)
        S.turn(arm, "head", s, 18.0 - 20 * flinch)
    return p


def p_wipe(phase):
    """The barkeep wiping the bar with his right hand: phase -1..1 across."""
    def p(arm, f):
        s = side_of(f)
        legs_stand(arm, f)
        torso(arm, f, 0.35)
        S.aim(arm, "upper_arm_r", -UP * 0.55 + f * 0.8 + s * 0.15)
        S.aim(arm, "forearm_r", f * 0.9 - UP * 0.35 + s * 0.45 * phase)
        S.aim(arm, "hand_r", f - UP * 0.5 + s * 0.3 * phase)
        S.aim(arm, "upper_arm_l", -UP * 0.6 + f * 0.75 - s * 0.2)
        S.aim(arm, "forearm_l", f * 0.9 - UP * 0.2 + s * 0.35)
        head(arm, f, 0.0, -20.0)
    return p


def p_lean_bar(turn=0.0):
    def p(arm, f):
        s = side_of(f)
        legs_stand(arm, f, 0.1)
        torso(arm, f, 0.25)
        S.aim(arm, "upper_arm_r", -UP * 0.6 + f * 0.7 + s * 0.2)
        S.aim(arm, "forearm_r", f - s * 0.3)
        S.aim(arm, "upper_arm_l", -UP * 0.6 + f * 0.7 - s * 0.2)
        S.aim(arm, "forearm_l", f + s * 0.3)
        head(arm, f, turn, -8.0)
    return p


def p_toast(phase):
    """The stranger: his forearms on the table, the cup lifted to a toast ('up') or set down."""
    def p(arm, f):
        s = side_of(f)
        legs_sit(arm, f)
        torso(arm, f, 0.28 if phase != "up" else 0.18)
        arms_table(arm, f)
        if phase == "up":
            S.aim(arm, "upper_arm_r", -UP * 0.75 + f * 0.55 + s * 0.15)
            S.aim(arm, "forearm_r", UP * 0.75 + f * 0.6 - s * 0.25)
            S.aim(arm, "hand_r", UP * 0.3 + f * 0.8 - s * 0.2)
        head(arm, f, -18.0 if phase == "rest" else -26.0, 0.0 if phase == "rest" else 4.0)
    return p


# ---------------------------------------------------------------- actors


FACE_KEYS = ["jaw_open", "aa", "lips_apart", "ee", "oo", "fv", "mbp", "blink_l", "blink_r", "squint",
             "brows_up", "brows_down", "scowl", "smile", "smile_l", "smile_r", "look_left", "look_right",
             "look_up", "look_down"]


class Actor:
    def __init__(self, who, model):
        self.who = who
        self.arm = S.man(who, model)
        self.keys = []      # (frame, yaw, pelvis point, pose)
        self.faces = []     # (frame, {key: value})
        arm = self.arm
        arm.rotation_mode = "XYZ"
        arm.rotation_euler = (0, 0, 0)
        arm.location = (0, 0, 0)
        bpy.context.view_layer.update()
        self.stand_h = (arm.matrix_world @ arm.pose.bones["pelvis"].head).z

    def key(self, f, yaw, at, pose):
        self.keys.append((f, yaw, Vector(at), pose))

    def standing(self, p, dz=0.0):
        return Vector((p.x, p.y, self.stand_h + dz))

    def face(self, f, **v):
        self.faces.append((f, v))

    def blinks(self, a, b, every=3.1, offset=0.0):
        t = a / T.FPS + 0.8 + offset
        while t < b / T.FPS - 0.3:
            f = F(t)
            self.faces.append((f - 1, {"_blink": 0.0}))
            self.faces.append((f + 1, {"_blink": 1.0}))
            self.faces.append((f + 4, {"_blink": 0.0}))
            t += every

    def bake(self):
        arm = self.arm
        arm.animation_data_clear()
        for pb in arm.pose.bones:
            pb.rotation_mode = "QUATERNION"
        caught = []
        for f, yaw, at, pose in sorted(self.keys, key=lambda k: k[0]):
            for pb in arm.pose.bones:
                pb.location = (0, 0, 0)
                pb.rotation_quaternion = (1, 0, 0, 0)
                pb.scale = (1, 1, 1)
            S.place_on(arm, at, yaw)
            pose(arm, S.facing(yaw))
            S.place_on(arm, at, yaw)
            caught.append((f, arm.location.copy(), arm.rotation_euler.copy(),
                           {pb.name: (pb.location.copy(), pb.rotation_quaternion.copy()) for pb in arm.pose.bones}))
        prev = {}
        for f, loc, rot, bones in caught:
            arm.location = loc
            arm.rotation_euler = rot
            arm.keyframe_insert("location", frame=f)
            arm.keyframe_insert("rotation_euler", frame=f)
            for name, (bl, bq) in bones.items():
                pb = arm.pose.bones[name]
                if name in prev and prev[name].dot(bq) < 0:
                    bq.negate()
                prev[name] = bq
                pb.location = bl
                pb.rotation_quaternion = bq
                pb.keyframe_insert("location", frame=f)
                pb.keyframe_insert("rotation_quaternion", frame=f)
        # Faces: every key the man has, keyed at each face key (unnamed ones held at what they were).
        meshes = [o for o in arm.children if o.type == "MESH" and o.data.shape_keys]
        state = {k: 0.0 for k in FACE_KEYS}
        for f, v in sorted(self.faces, key=lambda x: x[0]):
            for k, val in v.items():
                if k == "_blink":
                    state["blink_l"] = state["blink_r"] = val
                else:
                    state[k] = val
            for o in meshes:
                for k, val in state.items():
                    kb = o.data.shape_keys.key_blocks.get(k)
                    if kb is not None:
                        kb.value = val
                        kb.keyframe_insert("value", frame=f)
        print("baked", self.who, len(caught), "keys", len(self.faces), "face keys", flush=True)


def hold(actor, a, b, yaw, at, pose):
    actor.key(a, yaw, at, pose)
    actor.key(b, yaw, at, pose)


# ---------------------------------------------------------------- props that move


def key_obj(ob, f, loc=None, rot=None, scale=None):
    if loc is not None:
        ob.location = loc
        ob.keyframe_insert("location", frame=f)
    if rot is not None:
        ob.rotation_euler = [math.radians(r) for r in rot]
        ob.keyframe_insert("rotation_euler", frame=f)
    if scale is not None:
        ob.scale = (scale, scale, scale) if isinstance(scale, (int, float)) else scale
        ob.keyframe_insert("scale", frame=f)


def key_hidden(ob, frames_hidden):
    """Hidden over [a, b] ranges, shown otherwise (constant)."""
    ob.hide_render = False
    ob.keyframe_insert("hide_render", frame=0)
    for a, b in frames_hidden:
        ob.hide_render = True
        ob.keyframe_insert("hide_render", frame=a)
        ob.hide_render = False
        ob.keyframe_insert("hide_render", frame=b + 1)
    constant(ob)


def constant(ob, path=None):
    ad = ob.animation_data
    if ad and ad.action:
        for fc in _fcurves(ad.action):
            if path is None or fc.data_path == path:
                for kp in fc.keyframe_points:
                    kp.interpolation = "CONSTANT"


def _fcurves(action):
    """An action's F-curves (Blender 5's layered actions keep them in channelbags)."""
    if hasattr(action, "fcurves") and action.fcurves is not None:
        try:
            return list(action.fcurves)
        except Exception:
            pass
    out = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                out.extend(bag.fcurves)
    return out


def linear(ob):
    ad = ob.animation_data
    if ad and ad.action:
        for fc in _fcurves(ad.action):
            for kp in fc.keyframe_points:
                kp.interpolation = "LINEAR"


class Rand(S.Rand):
    def r(self, a, b):
        return a + (b - a) * self.f()


def rain(start, rng):
    """Cards and coins thrown up off the table's edge by his fall, coming down round him slowly."""
    card = S.material("card")
    back = S.material("card_back")
    gold = S.material("coin")
    src = TB + Vector((0.14, 0.42, S.TABLE_TOP + 0.02))
    obs = []
    for k in range(16):
        is_coin = k >= 8
        if is_coin:
            ob = S.lathe("rain_coin_%d" % k, [(0.0, -0.0011), (0.012, -0.0011), (0.012, 0.0011), (0.0, 0.0011)], 16,
                         (0, 0, 0), gold, smooth=False)
        else:
            ob = S.box("rain_card_%d" % k, (0.063, 0.088, 0.0008), (0, 0, 0), (card if k % 3 else back, (1, 1)))
        land = TB + Vector((rng.r(-0.45, 0.65), rng.r(0.85, 1.95), 0.002 + 0.0012 * k))
        t0 = start + int(rng.r(0, 5))
        dur = int(rng.r(40, 75))           # slow: the rain shot is slowed down
        peak = rng.r(0.35, 0.8)
        spin = [rng.r(-900, 900), rng.r(-900, 900), rng.r(-400, 400)]
        rest_rot = [0, 0, rng.r(0, 360)]
        key_obj(ob, 0, loc=src, rot=[0, 0, 0])
        key_obj(ob, t0, loc=src, rot=[0, 0, 0])
        n = 8
        for i in range(1, n + 1):
            u = i / n
            p = src.lerp(land, u)
            p.z = src.z + (land.z - src.z) * u + 4 * peak * u * (1 - u)
            if i == n:
                key_obj(ob, t0 + dur, loc=land, rot=rest_rot)
            else:
                key_obj(ob, t0 + int(dur * u), loc=p, rot=[spin[j] * u for j in range(3)])
        obs.append(ob)
    return obs


def rolling_coin(a, b):
    """One coin still rolling across the boards after the shot, then wobbling down."""
    gold = S.material("coin")
    ob = S.lathe("rolling_coin", [(0.0, -0.0011), (0.012, -0.0011), (0.012, 0.0011), (0.0, 0.0011)], 24, (0, 0, 0),
                 gold, smooth=False)
    p0 = TB + Vector((0.55, 1.25, 0.012))
    p1 = TB + Vector((0.95, 0.85, 0.012))
    key_obj(ob, 0, loc=p0, rot=[90, 0, 45])
    key_obj(ob, a, loc=p0, rot=[90, 0, 45])
    key_obj(ob, b - 30, loc=p1, rot=[90, 1800, 45])
    key_obj(ob, b - 14, loc=p1 + Vector((0.03, -0.02, -0.004)), rot=[60, 1900, 300])
    key_obj(ob, b - 6, loc=p1 + Vector((0.035, -0.025, -0.008)), rot=[20, 1950, 600])
    key_obj(ob, b, loc=p1 + Vector((0.035, -0.025, -0.0108)), rot=[0, 1960, 760])
    return ob


def ace(cheater, a, b):
    """The ace sliding out of the cheater's right cuff under his hand."""
    card = S.material("card_ace", colour=(0.85, 0.82, 0.74), rough=0.5)
    ob = S.box("ace", (0.063, 0.088, 0.0008), (0, 0, 0), (card, (1, 1)))
    arm = cheater.arm
    ob.parent = arm
    ob.parent_type = "BONE"
    ob.parent_bone = "hand_r"
    ob.matrix_parent_inverse = Matrix()
    L = arm.data.bones["hand_r"].length
    key_obj(ob, 0, loc=Vector((0, -L * 1.6, 0.02)))
    key_obj(ob, a, loc=Vector((0, -L * 1.6, 0.02)))
    key_obj(ob, b, loc=Vector((0, -L * 0.45, 0.02)))
    return ob


def revolver(lyle, at_frame):
    """Lyle's revolver in his right hand (the game's model), set in his grip at the aimed frame."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(S.ROOT, "assets", "weapons", "revolver.glb"))
    new = [o for o in bpy.data.objects if o not in before]
    root = S.empty("revolver")
    for o in new:
        if o.parent is None:
            o.parent = root
    bpy.context.scene.frame_set(at_frame)
    arm = lyle.arm
    pb = arm.pose.bones["hand_r"]
    mh = arm.matrix_world @ pb.matrix
    b = (mh.to_3x3() @ Vector((0, 1, 0))).normalized()
    u = (UP - b * b.dot(UP)).normalized()
    x = b.cross(u)
    rot = Matrix((x, b, u)).transposed()
    palm = (arm.matrix_world @ pb.head) + b * 0.05
    m = Matrix.Translation(palm + u * 0.04) @ rot.to_4x4()
    root.parent = arm
    root.parent_type = "BONE"
    root.parent_bone = "hand_r"
    root.matrix_parent_inverse = Matrix()
    bpy.context.view_layer.update()
    root.matrix_world = m
    bpy.context.view_layer.update()
    return root, new


def muzzle_flash(gun_root, f):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    mz = gun_root.matrix_world @ Vector((0, 0.27, 0.04))
    lt = bpy.data.lights.new("flash", "POINT")
    lt.color = (1.0, 0.75, 0.4)
    lt.shadow_soft_size = 0.05
    lo = bpy.data.objects.new("flash", lt)
    lo.location = mz
    bpy.context.scene.collection.objects.link(lo)
    for fr, e in ((0, 0.0), (f - 1, 0.0), (f, 4000.0), (f + 1, 2500.0), (f + 2, 300.0), (f + 4, 0.0)):
        lt.energy = e
        lt.keyframe_insert("energy", frame=fr)
    fire = S.material("flash_fire", colour=(1, 0.7, 0.3), emit=(1.0, 0.72, 0.35), emit_strength=80.0)
    d = (gun_root.matrix_world.to_3x3() @ Vector((0, 1, 0))).normalized()
    cone = S.lathe("flash_cone", [(0.0, 0.0), (0.05, 0.04), (0.035, 0.14), (0.0, 0.2)], 12, mz, fire)
    cone.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    key_hidden(cone, [(0, f - 1), (f + 2, T.frame(T.LENGTH) + 10)])
    return mz, d


def gun_smoke(mz, d, f):
    """The black-powder cloud: a puff from the muzzle that grows, rises and thins."""
    m = bpy.data.materials.new("gunsmoke")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.remove(nt.nodes["Principled BSDF"])
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (0.75, 0.72, 0.68, 1)
    vol.inputs["Anisotropy"].default_value = 0.3
    # Lumpy: noise into the density.
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 3.0
    noise.inputs["Detail"].default_value = 6.0
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    nt.links.new(noise.outputs["Fac"], mul.inputs[0])
    mul.inputs[1].default_value = 6.0
    ramp = nt.nodes.new("ShaderNodeMath")
    ramp.operation = "MULTIPLY"
    nt.links.new(mul.outputs[0], ramp.inputs[0])
    nt.links.new(ramp.outputs[0], vol.inputs["Density"])
    nt.links.new(vol.outputs["Volume"], nt.nodes["Material Output"].inputs["Volume"])
    ob = S.lathe("gunsmoke", [(0.0, -1.0), (0.7, -0.7), (1.0, 0.0), (0.7, 0.7), (0.0, 1.0)], 16, mz, m)
    for fr, s, dens, off in ((0, 0.01, 0.0, 0.0), (f - 1, 0.01, 0.0, 0.0), (f, 0.12, 1.2, 0.2), (f + 6, 0.35, 0.7, 0.45),
                             (f + 30, 0.7, 0.3, 0.7), (f + 90, 1.1, 0.1, 0.95), (f + 140, 1.4, 0.03, 1.1)):
        ob.location = mz + d * off + UP * (0.0 if fr <= f else 0.15 * (fr - f) / 140.0)
        ob.scale = (s, s, s * 0.8)
        ob.keyframe_insert("location", frame=fr)
        ob.keyframe_insert("scale", frame=fr)
        ramp.inputs[1].default_value = dens
        ramp.inputs[1].keyframe_insert("default_value", frame=fr)
    key_hidden(ob, [(0, f - 1)])
    return ob


# ---------------------------------------------------------------- the title


def title_rig():
    """SALT CREEK in wood-type letters on dark boards, raked by one warm light, dust in the beam.
    Far from the saloon (x = 60) so nothing of it lights the letters."""
    o = Vector((60.0, 0.0, 1.5))
    font = None
    if os.path.exists(FONT):
        font = bpy.data.fonts.load(FONT)
    paint = bpy.data.materials.new("title_paint")
    paint.use_nodes = True
    nt = paint.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    noise = nt.nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 14.0
    noise.inputs["Detail"].default_value = 10.0
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].position = 0.42
    ramp.color_ramp.elements[0].color = (0.18, 0.11, 0.06, 1)
    ramp.color_ramp.elements[1].position = 0.55
    ramp.color_ramp.elements[1].color = (0.78, 0.66, 0.46, 1)
    nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    nt.links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.75

    def text(body, size, z, extrude):
        cu = bpy.data.curves.new("title_" + body, "FONT")
        cu.body = body
        if font:
            cu.font = font
        cu.size = size
        cu.align_x = "CENTER"
        cu.align_y = "CENTER"
        cu.extrude = extrude
        cu.bevel_depth = extrude * 0.12
        cu.space_character = 1.05
        ob = bpy.data.objects.new("title_" + body, cu)
        ob.location = o + Vector((0, -0.06, z))
        ob.rotation_euler = (math.radians(90), 0, 0)
        ob.data.materials.append(paint)
        bpy.context.scene.collection.objects.link(ob)
        return ob

    text("SALT CREEK", 0.95, 0.15, 0.05)
    text("1882", 0.28, -0.62, 0.025)
    boards = S.wood("int_boards")
    S.box("title_boards", (9.0, 0.1, 5.0), o + Vector((0, 0.05, 0)), boards, grain=0)
    # The light: a warm spot raking down from the upper left, and haze to catch its beam.
    lt = bpy.data.lights.new("title_spot", "SPOT")
    lt.energy = 900.0
    lt.color = S.LAMP_RGB
    lt.spot_size = math.radians(55)
    lt.spot_blend = 0.6
    lt.shadow_soft_size = 0.15
    lo = bpy.data.objects.new("title_spot", lt)
    lo.location = o + Vector((-2.2, -2.6, 2.6))
    lo.rotation_euler = (o - lo.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.collection.objects.link(lo)
    haze = bpy.data.materials.get("haze")
    hz = S.box("title_haze", (8.0, 4.0, 4.5), o + Vector((0, -2.0, 0.3)), (haze, (1, 1)))
    hz.visible_shadow = False
    # Dust motes drifting down through the beam.
    rng = Rand(29)
    mote = S.material("mote", colour=(0.9, 0.8, 0.6), emit=(1.0, 0.8, 0.55), emit_strength=0.6)
    a, b = T.frames_of("title")
    for k in range(160):
        p = o + Vector((rng.r(-3.0, 3.0), rng.r(-2.8, -0.2), rng.r(-1.6, 2.2)))
        ob = S.lathe("mote_%d" % k, [(0.0, -0.002), (0.002, 0.0), (0.0, 0.002)], 6, p, mote, smooth=False)
        key_obj(ob, a, loc=p)
        key_obj(ob, b, loc=p + Vector((rng.r(0.05, 0.25), rng.r(-0.1, 0.1), -rng.r(0.15, 0.5))))
        linear(ob)
    return o


# ---------------------------------------------------------------- the performance


def stage():
    """Build the set and every man, key the whole performance. Returns the actors and things."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    S.build_room()
    S.build_dressing()
    S.build_card_table()
    # A warm light on the floor where the cheater lands (the hanging lamp over it, helped).
    S.area("floor_fill", TB + Vector((0.3, 1.3, 2.6)), TB + Vector((0.2, 1.3, 0.0)), 70.0, 1.2, S.LAMP_RGB)

    A = {}
    for who, (model, off, yaw) in S.SEATS.items():
        A[who] = Actor(who, model)
    A["barkeep"] = Actor("barkeep", "barkeep_s2_talking")
    A["rancher"] = Actor("rancher", "old_rancher_s3_talking")
    A["miner"] = Actor("miner", "miner_s4_talking")
    END = F(T.LENGTH)

    chairs = {}
    for who in ("player", "stranger", "cheater", "lyle"):
        model, off, yaw = S.SEATS[who]
        chairs[who] = S.kit_prop("chair", tuple(TB + off), yaw + 180.0)

    def seat_at(who, fwd=0.04):
        model, off, yaw = S.SEATS[who]
        return TB + off + S.facing(yaw) * fwd + Vector((0, 0, 0.56))

    # --- the player: sat still, a small turn of the head now and then.
    pl = A["player"]
    py = S.SEATS["player"][2]
    hold(pl, 0, F(37.5), py, seat_at("player"), p_sit(0.25, 0.0, 8.0))
    pl.key(F(38.6), py, seat_at("player") + Vector((0.12, 0.05, 0.22)), p_rise)
    hold(pl, F(39.4), END, py, seat_at("player") + Vector((0.18, 0.08, 0.32)), p_stand(15.0, -25.0, 0.3, arms=False))

    # --- the stranger: still as a post; the toast with his line.
    st = A["stranger"]
    sy = S.SEATS["stranger"][2]
    hold(st, 0, F(45.4), sy, seat_at("stranger"), p_toast("rest"))
    st.key(F(46.2), sy, seat_at("stranger"), p_toast("up"))
    st.key(F(47.6), sy, seat_at("stranger"), p_toast("up"))
    st.key(F(48.6), sy, seat_at("stranger"), p_toast("rest"))
    st.key(END, sy, seat_at("stranger"), p_toast("rest"))
    st.face(0, brows_down=0.15)
    st.blinks(0, F(49.0), 3.4, 0.5)
    # "Welcome to Salt Creek." (mouth shapes by the syllable, from the line's start).
    t0 = T.BEAT["line"]
    for dt, shape in ((0.0, {"oo": 0.5}), (0.1, {"oo": 0.0, "ee": 0.45}), (0.22, {"ee": 0.0, "lips_apart": 0.3}),
                      (0.3, {"lips_apart": 0.0, "aa": 0.45}), (0.42, {"aa": 0.0, "mbp": 0.9}),
                      (0.5, {"mbp": 0.0, "lips_apart": 0.35}), (0.58, {"lips_apart": 0.0, "oo": 0.6}),
                      (0.7, {"oo": 0.0, "ee": 0.35}), (0.8, {"ee": 0.0, "aa": 0.75, "jaw_open": 0.3}),
                      (0.93, {"aa": 0.0, "jaw_open": 0.0, "lips_apart": 0.45}), (1.05, {"lips_apart": 0.2}),
                      (1.12, {"lips_apart": 0.0, "ee": 0.35}), (1.22, {"ee": 0.85}), (1.36, {"ee": 0.0, "lips_apart": 0.2}),
                      (1.5, {"lips_apart": 0.0}), (1.9, {"smile_r": 0.35}), (2.6, {"smile_r": 0.15})):
        st.face(F(t0 + dt), **shape)

    # --- the cheater.
    ch = A["cheater"]
    cy = S.SEATS["cheater"][2]
    kick = F(T.BEAT["kick"])
    hold(ch, 0, kick - 1, cy, seat_at("cheater"), p_sit(0.2))
    ch.face(0, smile_l=0.0)
    ch.face(F(17.6), smile_l=0.0)
    ch.face(F(18.4), smile_l=0.8, brows_up=0.15)
    ch.face(F(23.4), smile_l=0.8, brows_up=0.15)
    ch.face(F(24.4), smile_l=0.0, brows_up=0.5)
    ch.blinks(0, F(24.0), 2.9, 0.2)
    ch.key(kick + 3, cy, seat_at("cheater"), p_fall("shock"))
    ch.face(kick + 3, brows_up=0.9, jaw_open=0.45)
    ch.key(kick + 8, cy, seat_at("cheater") + Vector((0, 0.05, -0.2)), p_fall("drop"))
    ch.key(kick + 13, cy, seat_at("cheater") + Vector((0.0, 0.12, -0.42)), p_fall("sit"))
    ch.key(kick + 20, cy, FLOOR_PELVIS, p_fall("back"))
    ch.face(kick + 20, brows_up=0.6, jaw_open=0.6, squint=0.6)
    ch.key(kick + 25, cy, FLOOR_PELVIS + Vector((0, 0.02, 0.02)), p_fall("bounce"))
    ch.key(kick + 32, cy, FLOOR_PELVIS, p_fall("back"))
    ch.key(F(31.4), cy, FLOOR_PELVIS, p_lie())
    ch.key(F(32.6), cy, FLOOR_PELVIS + Vector((0, 0.05, 0.06)), p_propped(0.0))
    ch.face(F(32.6), brows_up=1.0, jaw_open=0.35, squint=0.0)
    # Trembling, edging back.
    t = 33.0
    k = 0
    while t < 37.3:
        ch.key(F(t), cy, FLOOR_PELVIS + Vector((0, 0.05 + 0.04 * (t - 33.0), 0.06)),
               p_propped(0.06 if k % 2 else -0.04))
        t += 0.25
        k += 1
    flash = F(T.BEAT["flash"])
    ch.key(flash - 1, cy, FLOOR_PELVIS + Vector((0, 0.22, 0.06)), p_propped(0.0, flinch=1.0))
    ch.face(flash - 1, brows_up=1.0, jaw_open=0.55, squint=0.7)
    ch.key(flash + 4, cy, FLOOR_PELVIS + Vector((0, 0.3, 0.0)), p_lie(dead=True))
    ch.face(flash + 4, brows_up=0.0, jaw_open=0.22, squint=0.0, blink_l=0.55, blink_r=0.6)
    ch.key(END, cy, FLOOR_PELVIS + Vector((0, 0.3, 0.0)), p_lie(dead=True))

    # --- Lyle.
    ly = A["lyle"]
    lyw = S.SEATS["lyle"][2]
    hold(ly, 0, F(T.BEAT["eyes_lift"]) - 4, lyw, seat_at("lyle"), p_sit(0.35, 12.0, -16.0))
    ly.key(F(T.BEAT["eyes_lift"]) + 6, lyw, seat_at("lyle"), p_sit(0.35, 6.0, -4.0))
    ly.key(F(T.BEAT["rise"]), lyw, seat_at("lyle"), p_sit(0.35, 6.0, -4.0))
    ly.face(0, look_down=0.7, brows_down=0.2)
    ly.face(F(T.BEAT["eyes_lift"]) - 3, look_down=0.7)
    ly.face(F(T.BEAT["eyes_lift"]) + 5, look_down=0.0, look_up=0.12, scowl=0.6, brows_down=0.6, squint=0.4)
    ly.blinks(0, F(21.0), 3.0)
    r0 = F(T.BEAT["rise"])
    ly.key(r0 + 12, lyw, seat_at("lyle") + S.facing(lyw) * 0.12 + Vector((0, 0, 0.18)), p_rise)
    stand_at = LYLE_CHAIR + S.facing(lyw) * 0.2
    ly.key(r0 + 24, lyw, ly.standing(stand_at), p_stand(-30.0, -8.0))
    mid = stand_at.lerp(P_KICK, 0.5)
    ly.key(r0 + 36, 120.0, ly.standing(mid, -0.03), p_step("r"))
    ly.key(r0 + 48, 100.0, ly.standing(P_KICK.lerp(mid, 0.2), -0.03), p_step("l"))
    ly.key(kick - 6, 95.0, ly.standing(P_KICK), p_kick("wind"))
    ly.key(kick, 95.0, ly.standing(P_KICK, -0.04), p_kick("hit"))
    ly.key(kick + 7, 95.0, ly.standing(P_KICK), p_kick("down"))
    ly.key(kick + 16, 98.0, ly.standing(P_KICK), p_stand(-15.0, -25.0))
    # To stand over him (unseen: the rain shot).
    over_yaw = 112.0
    ly.key(F(30.2), over_yaw, ly.standing(P_OVER), p_stand(0.0, -30.0))
    draw = F(T.BEAT["draw"])
    target = CHEAT_CHEST + Vector((0, 0.1, 0.1))
    ly.key(draw - 2, over_yaw, ly.standing(P_OVER), p_draw("holster"))
    ly.key(draw + 5, over_yaw, ly.standing(P_OVER), p_draw("clear"))
    ly.key(draw + 12, over_yaw, ly.standing(P_OVER), p_draw("aim", target))
    hold(ly, draw + 13, flash - 1, over_yaw, ly.standing(P_OVER), p_draw("aim", target + Vector((0, 0.08, 0.0))))
    ly.key(flash + 2, over_yaw, ly.standing(P_OVER), p_draw("aim", target + Vector((0, 0.1, 0.25))))   # the kick of it
    ly.key(flash + 10, over_yaw, ly.standing(P_OVER), p_draw("aim", target + Vector((0, 0.1, 0.05))))
    ly.key(F(40.6), over_yaw, ly.standing(P_OVER), p_draw("clear"))
    hold(ly, F(41.6), END, over_yaw, ly.standing(P_OVER), p_draw("holster"))
    ly.face(F(30.0), scowl=0.7, brows_down=0.7, squint=0.5, look_up=0.0, look_down=0.2)

    # --- the barkeep at his rag, the rancher at the bar, the miner at the back.
    bk = A["barkeep"]
    bkp = Vector((4.7, 8.9, 0.0))
    t = 0.0
    k = 0
    while t <= T.LENGTH:
        bk.key(F(t), 90.0, bk.standing(bkp, -0.06), p_wipe(1.0 if k % 2 else -1.0))
        t += 1.1
        k += 1
    ra = A["rancher"]
    hold(ra, 0, F(24.0), -95.0, ra.standing(Vector((3.25, 11.6, 0)), -0.04), p_lean_bar(0.0))
    hold(ra, F(25.0), END, -95.0, ra.standing(Vector((3.25, 11.6, 0)), -0.04), p_lean_bar(-35.0))
    mi = A["miner"]
    hold(mi, 0, F(24.5), 160.0, mi.standing(Vector((-3.9, 14.5, 0))), p_stand(0.0, -5.0))
    hold(mi, F(25.5), END, 160.0, mi.standing(Vector((-3.9, 14.5, 0))), p_stand(-20.0, 0.0))

    for a in A.values():
        a.bake()

    # --- props.
    lc = chairs["lyle"]
    lyc0 = lc.location.copy()
    key_obj(lc, 0, loc=lyc0, rot=[0, 0, math.degrees(lc.rotation_euler.z)])
    key_obj(lc, r0 + 8, loc=lyc0, rot=[0, 0, math.degrees(lc.rotation_euler.z)])
    key_obj(lc, r0 + 20, loc=lyc0 + Vector((0.38, -0.05, 0)), rot=[0, 0, math.degrees(lc.rotation_euler.z) + 14])
    cc = chairs["cheater"]
    c0 = cc.location.copy()
    yaw0 = math.degrees(cc.rotation_euler.z)
    key_obj(cc, 0, loc=c0, rot=[0, 0, yaw0])
    key_obj(cc, kick, loc=c0, rot=[0, 0, yaw0])
    key_obj(cc, kick + 6, loc=c0 + Vector((-0.45, 0.08, 0.12)), rot=[0, -50, yaw0 + 25])
    key_obj(cc, kick + 12, loc=c0 + Vector((-0.85, 0.15, 0.1)), rot=[0, -95, yaw0 + 40])
    key_obj(cc, kick + 20, loc=c0 + Vector((-1.05, 0.2, 0.22)), rot=[0, -90, yaw0 + 48])
    key_obj(cc, kick + 30, loc=c0 + Vector((-1.12, 0.22, 0.22)), rot=[0, -90, yaw0 + 50])
    rain(kick + 4, Rand(41))
    rolling_coin(F(37.6), F(41.5))
    ace(ch, F(T.BEAT["ace_slide"]), F(T.BEAT["ace_slide"]) + 22)
    gun_root, gun_parts = revolver(ly, draw + 14)
    for o in [gun_root] + gun_parts:
        key_hidden(o, [(0, draw - 3)])
    mz, d = muzzle_flash(gun_root, flash)
    gun_smoke(mz, d, flash)
    # The stranger's cup in his hand.
    tin = S.material("tin")
    cup = S.lathe("stranger_cup", [(0.0, 0.0), (0.038, 0.0), (0.042, 0.095), (0.039, 0.095), (0.035, 0.004),
                                   (0.0, 0.004)], 20, (0, 0, 0), tin)
    bpy.context.scene.frame_set(F(44.0))
    arm = st.arm
    pb = arm.pose.bones["hand_r"]
    hp = arm.matrix_world @ pb.head
    b = ((arm.matrix_world.to_3x3() @ (pb.tail - pb.head))).normalized()
    p = hp + b * 0.05
    cup.parent = arm
    cup.parent_type = "BONE"
    cup.parent_bone = "hand_r"
    cup.matrix_parent_inverse = Matrix()
    bpy.context.view_layer.update()
    cup.matrix_world = Matrix.Translation(Vector((p.x, p.y, S.TABLE_TOP + 0.002)))
    for name in ("cup_1",):
        if name in bpy.data.objects:
            bpy.data.objects[name].hide_render = True

    # Face and rim lights for the four at the table, from where they sit (as the look test).
    bpy.context.scene.frame_set(0)
    for who in ("player", "stranger", "cheater", "lyle"):
        S.face_lights(A[who].arm)
    title = title_rig()
    return A, {"gun": gun_root, "muzzle": mz, "title": title, "chairs": chairs}


# ---------------------------------------------------------------- cameras


def cam(name, lens=50.0, fstop=2.0):
    c = bpy.data.cameras.new(name)
    c.lens = lens
    c.sensor_width = 36.0
    c.dof.use_dof = True
    c.dof.aperture_fstop = fstop
    ob = bpy.data.objects.new(name, c)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def look(ob, f, eye, target, lens=None):
    ob.location = eye
    ob.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    ob.keyframe_insert("location", frame=f)
    ob.keyframe_insert("rotation_euler", frame=f)
    if lens:
        ob.data.lens = lens
        ob.data.keyframe_insert("lens", frame=f)


def focus_on(ob, target_obj, bone=None, distance=None):
    if target_obj is not None:
        ob.data.dof.focus_object = target_obj
        if bone:
            ob.data.dof.focus_subtarget = bone
    elif distance:
        ob.data.dof.focus_distance = distance


def handheld(ob, amount=1.0):
    ad = ob.animation_data
    if not ad or not ad.action:
        return
    for fc in _fcurves(ad.action):
        if fc.data_path == "rotation_euler":
            m = fc.modifiers.new("NOISE")
            m.scale = 26.0
            m.strength = 0.006 * amount
            m.phase = 13.0 * fc.array_index + len(ob.name)


def at(arm, bone, f, along=0.45):
    bpy.context.scene.frame_set(f)
    pb = arm.pose.bones[bone]
    return arm.matrix_world @ (pb.head + (pb.tail - pb.head) * along)


def mark(name, cam_ob, size=0.1):
    e = S.empty("focus_" + name)
    e.empty_display_size = size
    return e


def cameras(A, things):
    C = {}

    def shot(name, lens, fstop):
        a, b = T.frames_of(name)
        ob = cam("cam_" + name, lens, fstop)
        C[name] = ob
        return ob, a, b

    ch, ly, st, pl = A["cheater"].arm, A["lyle"].arm, A["stranger"].arm, A["player"].arm

    # 1. The felt and the lamp, very close, sliding across the cards.
    ob, a, b = shot("table", 50, 1.6)
    tgt = TB + Vector((0.12, 0.08, S.TABLE_TOP + 0.03))
    look(ob, a, TB + Vector((-0.42, -0.36, S.TABLE_TOP + 0.13)), tgt)
    look(ob, b, TB + Vector((-0.2, -0.42, S.TABLE_TOP + 0.11)), tgt + Vector((0.08, 0.05, 0)))
    f1 = S.empty("focus_table", tgt)
    focus_on(ob, f1)
    handheld(ob, 0.4)

    # 2. Over your shoulder at the stranger, pushing in.
    ob, a, b = shot("ots", 45, 2.0)
    stp = at(st, "head", a)
    plp = at(pl, "head", a)
    look(ob, a, plp + Vector((-0.38, -0.72, -0.08)), stp + Vector((0.08, 0.0, -0.1)))
    look(ob, b, plp + Vector((-0.3, -0.55, -0.06)), stp + Vector((0.06, 0.0, -0.08)), lens=50)
    ob.data.lens = 45
    ob.data.keyframe_insert("lens", frame=a)
    focus_on(ob, st, "head")
    handheld(ob, 0.6)

    # 3. The room, high in the corner, drifting in.
    ob, a, b = shot("room", 30, 4.0)
    look(ob, a, Vector((-1.4, 2.6, 2.3)), Vector((-0.2, 12.0, 1.1)))
    look(ob, b, Vector((-1.15, 3.5, 2.15)), Vector((0.1, 12.0, 1.1)))
    focus_on(ob, None, distance=5.5)

    # 4. The ace: low at his right hand on the table.
    ob, a, b = shot("ace", 85, 2.8)
    hp = at(ch, "hand_r", a + 20, 0.3)
    look(ob, a, hp + Vector((-0.42, -0.3, 0.1)), hp + Vector((0.02, 0.02, -0.02)))
    look(ob, b, hp + Vector((-0.36, -0.25, 0.08)), hp + Vector((0.04, 0.03, -0.02)))
    focus_on(ob, ch, "hand_r")
    handheld(ob, 0.3)

    # 4. The smirk.
    ob, a, b = shot("smirk", 75, 2.2)
    chp = at(ch, "head", a)
    look(ob, a, chp + Vector((-0.45, -1.75, -0.12)), chp + Vector((0, 0, -0.16)))
    look(ob, b, chp + Vector((-0.4, -1.55, -0.1)), chp + Vector((0, 0, -0.12)), lens=85)
    ob.data.lens = 75
    ob.data.keyframe_insert("lens", frame=a)
    focus_on(ob, ch, "head")
    handheld(ob, 0.4)

    # 5. Lyle's eyes lift.
    ob, a, b = shot("lyle", 75, 2.0)
    lyp = at(ly, "head", a)
    look(ob, a, lyp + Vector((-1.7, 0.55, -0.14)), lyp + Vector((0, 0, -0.14)))
    look(ob, b, lyp + Vector((-1.25, 0.42, -0.1)), lyp + Vector((0, 0, -0.08)), lens=95)
    ob.data.lens = 75
    ob.data.keyframe_insert("lens", frame=a)
    focus_on(ob, ly, "head")

    # 6. He rises: from low by the stranger, across the table.
    ob, a, b = shot("rise", 32, 2.8)
    look(ob, a, TB + Vector((-1.5, -0.55, 0.95)), TB + Vector((0.7, 0.45, 1.05)))
    look(ob, b, TB + Vector((-1.45, -0.35, 1.0)), TB + Vector((0.65, 0.85, 1.15)))
    focus_on(ob, ly, "chest")
    handheld(ob, 1.0)

    # 6. The kick: low on the boards, the chair coming at us.
    ob, a, b = shot("kick", 26, 3.5)
    look(ob, a, TB + Vector((-1.05, 1.45, 0.28)), TB + Vector((0.4, 0.85, 0.55)))
    look(ob, b, TB + Vector((-1.0, 1.55, 0.25)), TB + Vector((0.3, 1.1, 0.35)))
    f8 = S.empty("focus_kick", TB + Vector((0.2, 0.95, 0.4)))
    focus_on(ob, f8)
    handheld(ob, 1.6)

    # 6. The rain: from above, turning slowly over him.
    ob, a, b = shot("rain", 35, 4.0)
    look(ob, a, TB + Vector((0.35, 1.05, 2.5)), TB + Vector((0.16, 1.35, 0.0)))
    look(ob, b, TB + Vector((0.05, 1.25, 2.3)), TB + Vector((0.16, 1.4, 0.0)))
    focus_on(ob, ch, "chest")

    # 7. The draw: low at his right hip, tilting up with the gun.
    ob, a, b = shot("draw", 40, 2.4)
    fl = S.facing(112.0)
    sd = side_of(fl)
    hip = at(ly, "pelvis", a) + sd * 0.22
    eye = hip + fl * 0.95 + sd * 0.55 + Vector((0, 0, -0.35))
    look(ob, a, eye, hip + Vector((0, 0, -0.05)))
    look(ob, a + 10, eye, hip + fl * 0.3 + Vector((0, 0, 0.25)))
    look(ob, b, eye + Vector((0, 0, 0.05)), at(ly, "hand_r", b) + Vector((0, 0, 0.05)))
    focus_on(ob, ly, "hand_r")
    handheld(ob, 1.2)

    # 8. On the floor: over Lyle's gun hand, down at him.
    ob, a, b = shot("floor", 40, 2.2)
    lyh = at(ly, "head", a)
    chh = at(ch, "head", a + 20)
    look(ob, a, lyh + sd * 0.3 - fl * 0.25 + Vector((0, 0, -0.12)), chh)
    look(ob, b, lyh + sd * 0.25 - fl * 0.05 + Vector((0, 0, -0.22)), at(ch, "head", b))
    focus_on(ob, ch, "head")
    handheld(ob, 0.9)

    # 9. Down the barrel: from by his head, up at Lyle.
    ob, a, b = shot("aim", 28, 2.4)
    chh = at(ch, "head", a)
    gp = at(ly, "hand_r", a)
    lyh = at(ly, "head", a)
    look(ob, a, chh + Vector((0.12, 0.05, 0.08)), gp.lerp(lyh, 0.35))
    look(ob, b, chh + Vector((0.14, 0.07, 0.07)), gp.lerp(lyh, 0.5), lens=32)
    ob.data.lens = 28
    ob.data.keyframe_insert("lens", frame=a)
    focus_on(ob, ly, "hand_r")
    handheld(ob, 0.7)

    # 9. Your view after: half up out of your chair, looking over.
    ob, a, b = shot("after", 35, 3.2)
    plh = at(pl, "head", a)
    tgt = TB + Vector((0.2, 1.35, 0.25))
    look(ob, a, plh + Vector((0.0, 0.0, -0.02)), tgt)
    look(ob, a + 30, at(pl, "head", a + 30) + Vector((0.05, 0.05, 0.0)), tgt + Vector((0, 0, 0.1)))
    look(ob, b, at(pl, "head", b) + Vector((0.12, 0.12, 0.0)), tgt + Vector((0.1, 0.0, 0.15)))
    focus_on(ob, ch, "chest")
    handheld(ob, 1.3)

    # 10. The stranger, from your seat: he hasn't moved.
    ob, a, b = shot("stranger", 60, 2.0)
    sth = at(st, "head", a)
    plh = at(pl, "head", a)
    eye = sth.lerp(plh, 0.55) + Vector((0.0, 0.0, -0.04))
    look(ob, a, eye, sth + Vector((0, 0, -0.12)))
    look(ob, b, sth.lerp(eye, 0.75), sth + Vector((0, 0, -0.08)), lens=70)
    ob.data.lens = 60
    ob.data.keyframe_insert("lens", frame=a)
    focus_on(ob, st, "head")
    handheld(ob, 0.35)

    # 11. The title.
    ob, a, b = shot("title", 40, 4.5)
    o = things["title"]
    look(ob, a, o + Vector((0, -5.6, 0.1)), o + Vector((0, 0, 0.0)))
    look(ob, b, o + Vector((0, -5.0, 0.08)), o + Vector((0, 0, 0.0)))
    focus_on(ob, None, distance=5.3)
    return C


# ---------------------------------------------------------------- render


QUALITY = {
    # percentage of 1920x804, samples, volume step rate, frame step, motion blur
    "sheet": (25, 10, 6.0, 1, False),
    "preview": (50, 20, 4.0, 2, False),
    "final": (100, 56, 2.0, 1, True),
}


def setup(quality):
    S.setup_render(fast=False)
    sc = bpy.context.scene
    pct, samples, vstep, step, blur = QUALITY[quality]
    sc.render.resolution_percentage = pct
    sc.cycles.samples = samples
    sc.cycles.use_adaptive_sampling = True
    sc.cycles.adaptive_threshold = 0.04 if quality == "final" else 0.08
    sc.cycles.volume_step_rate = vstep
    sc.cycles.max_bounces = 4 if quality != "final" else 6
    sc.render.use_persistent_data = True
    sc.render.use_motion_blur = blur
    sc.render.motion_blur_shutter = 0.5
    sc.render.motion_blur_position = "START"
    sc.render.fps = T.FPS
    sc.frame_start = 0
    sc.frame_end = F(T.LENGTH) - 1
    return step


def black(f):
    """Frames the fades hold at black: not rendered (the cut fills them)."""
    t = f / T.FPS
    return 49.0 <= t < 50.0


def render_frames(C, frames, out):
    sc = bpy.context.scene
    os.makedirs(out, exist_ok=True)
    for f in frames:
        t0 = time.time()
        sc.frame_set(f)
        sc.camera = C[T.shot_at(f)]
        sc.render.filepath = os.path.join(out, "f%04d.png" % f)
        bpy.ops.render.render(write_still=True)
        print("frame %d %s %.1fs" % (f, T.shot_at(f), time.time() - t0), flush=True)


def sheet(C, out):
    """Three frames of every shot and the beats between, small, on one sheet with their names."""
    picks = []
    for name, a, b in T.SHOTS:
        fa, fb = F(a), F(b) - 1
        for f in (fa + 3, (fa + fb) // 2, fb - 3):
            if not black(f):
                picks.append(f)
    for beat in ("kick", "flash"):
        fb = F(T.BEAT[beat])
        picks += [fb + 6, fb + 14] if beat == "kick" else [fb, fb + 6]
    picks = sorted(set(picks))
    raw = os.path.join(out, "frames")
    render_frames(C, picks, raw)
    from PIL import Image, ImageDraw
    ims = [(f, Image.open(os.path.join(raw, "f%04d.png" % f)).convert("RGB")) for f in picks]
    w, h = ims[0][1].size
    cols = 4
    rows = (len(ims) + cols - 1) // cols
    sh = Image.new("RGB", (cols * (w + 6), rows * (h + 20)), (20, 20, 20))
    d = ImageDraw.Draw(sh)
    for i, (f, im) in enumerate(ims):
        x, y = (i % cols) * (w + 6), (i // cols) * (h + 20)
        sh.paste(im, (x, y + 18))
        d.text((x + 3, y + 3), "%s  %d  %.2fs" % (T.shot_at(f), f, f / T.FPS), fill=(230, 220, 190))
    sh.save(os.path.join(out, "sheet.png"))
    for f, im in ims:
        im.close()
    import shutil
    shutil.rmtree(raw)
    print("sheet", len(picks), "frames", flush=True)


def main():
    a = S.args()
    quality = a.get("quality", "sheet" if a.get("sheet") else "preview")
    A, things = stage()
    step = setup(quality)
    C = cameras(A, things)
    if a.get("blend"):
        bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a["blend"]))
    if a.get("sheet"):
        if quality == "sheet":
            bpy.data.objects["haze"].hide_render = True
        sheet(C, os.path.abspath(a["sheet"]))
    if a.get("render"):
        chunk = int(a.get("chunk", 0))
        chunks = int(a.get("chunks", 1))
        frames = [f for f in range(0, F(T.LENGTH), step) if not black(f)]
        mine = frames[chunk::chunks]
        print("chunk %d of %d: %d frames" % (chunk, chunks, len(mine)), flush=True)
        render_frames(C, mine, os.path.abspath(a["render"]))


if __name__ == "__main__":
    main()
