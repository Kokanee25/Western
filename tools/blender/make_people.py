"""Build the game's people from MakeHuman's base mesh (CC0), fitted to our skeleton.

    python3 tools/blender/fetch_makehuman.py           # once: the CC0 assets into build/makehuman
    python tools/blender/make_people.py [--only=outlaw]   # with the `bpy` module (pip install bpy==5.0.1)
    blender -b --python tools/blender/make_people.py -- [--only=outlaw]   # or with Blender itself

For each person in assets/people/people.json:
  1. MakeHuman's base mesh, with that person's targets (age, build, ...) mixed in.
  2. Into our body space (metres, facing -Z, feet at the origin, his right is +X) and warped so
     his joints land on our skeleton's (assets/people/envelope.json, written by
     tools/people_envelope.gd from config/anatomy.json): each limb bone is moved, turned and
     stretched from MakeHuman's joints to ours, blended at the joints.
  3. Fitted to the body envelope BodyMesh uses (cross-sections of the trunk, neck, head, arms and
     legs), so he's the size and shape the hitboxes and the clothes expect: each cross-section is
     scaled to match, gently, keeping his own shape (the face, muscles) inside it. The head is
     also stretched so his eyes and mouth sit where PeopleArt.face paints them.
  4. Fingers cut off at the knuckles (the game's fingers are separate parts: they can be shot off).
  5. Skinned to our 17 bones with the same joint blends BodyMesh uses; cut down to a game budget.
  6. Written to assets/people/<id>.glb: an armature with our bones and two meshes, "skin" (body,
     UVs in metres for tiling skin) and "head" (face UVs laid out for PeopleArt.face) — objects
     "body_skin" and "body_head" — and
     assets/people/<id>.json (what was done, for checking).
Everything is repeatable: nothing is hand-edited.
"""
import json
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import clothes  # noqa: E402
import faces  # noqa: E402

try:
    import bpy
except ImportError:  # the fitting itself runs without Blender (for checks); export needs it
    bpy = None

MH = "build/makehuman/makehuman/data"
ENVELOPE = "assets/people/envelope.json"
ANATOMY = "config/anatomy.json"
OUT = "assets/people"
# The neck's lean is carried from its base (none) to the head (all), heights in our body space.
NECK_BASE_Y = 1.40
HEAD_BASE_Y = 1.56
# Triangles for the whole body (skin + head) after decimation.
TRI_BUDGET = 7000
# Joint blending (metres): how soft the boundary between two bones' pull is when warping.
BLEND = 0.012


# --- MakeHuman -------------------------------------------------------------------------------

def load_obj(path):
    """Vertices, UVs, and faces per group: {group: [(vertex ids, uv ids), ...]}."""
    verts, uvs, groups = [], [], {}
    cur = None
    for line in open(path):
        if line.startswith("v "):
            verts.append([float(x) for x in line.split()[1:4]])
        elif line.startswith("vt "):
            uvs.append([float(x) for x in line.split()[1:3]])
        elif line.startswith("g "):
            cur = line.split()[1]
        elif line.startswith("f ") and cur:
            vi, ti = [], []
            for p in line.split()[1:]:
                bits = p.split("/")
                vi.append(int(bits[0]) - 1)
                ti.append(int(bits[1]) - 1 if len(bits) > 1 and bits[1] else -1)
            groups.setdefault(cur, []).append((vi, ti))
    return np.array(verts), np.array(uvs), groups


def apply_target(v, path, weight):
    for line in open(path):
        if line[:1].isdigit():
            i, x, y, z = line.split()
            v[int(i)] += weight * np.array([float(x), float(y), float(z)])


def joint(v, groups, name):
    ids = sorted({i for f in groups["joint-" + name] for i in f[0]})
    return v[ids].mean(0)


def to_body_space(p):
    """MakeHuman (decimetres, facing +Z, his right at -X) → ours (metres, facing -Z, right +X)."""
    p = np.asarray(p, dtype=float) * 0.1
    return p * np.array([-1.0, 1.0, -1.0])


# --- Geometry helpers ------------------------------------------------------------------------

def seg_dist(p, a, b):
    """Distance from points p (N,3) to segment a-b, and the parameter along it (0..1)."""
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(ab @ ab, 1e-12), 0.0, 1.0)
    return np.linalg.norm(p - (a + t[:, None] * ab), axis=1), t


def rotation_between(u, w):
    u = u / np.linalg.norm(u)
    w = w / np.linalg.norm(w)
    c = float(u @ w)
    axis = np.cross(u, w)
    s = np.linalg.norm(axis)
    if s < 1e-9:
        return np.eye(3)
    axis /= s
    k = np.array([[0, -axis[2], axis[1]], [axis[2], 0, -axis[0]], [-axis[1], axis[0], 0]])
    ang = math.atan2(s, c)
    return np.eye(3) + math.sin(ang) * k + (1 - math.cos(ang)) * (k @ k)


def smooth(values, passes=3):
    v = np.array(values, dtype=float)
    for _ in range(passes):
        v[1:-1] = (v[:-2] + 2 * v[1:-1] + v[2:]) / 4
    return v


# --- The man ---------------------------------------------------------------------------------

class Person:
    def __init__(self, pid, spec, env):
        self.id = pid
        self.env = env
        with open(ANATOMY) as f:
            self.anatomy = json.load(f)
        v, uv, groups = load_obj(os.path.join(MH, "3dobjs/base.obj"))
        for t, w in spec.get("targets", {}).items():
            apply_target(v, os.path.join(MH, "targets", t + ".target"), float(w))
        self.uv = uv
        self.groups = groups
        j = {}
        for name in ["ground", "pelvis", "neck", "head", "head-2", "mouth", "r-eye", "l-eye", "jaw"]:
            j[name] = joint(v, groups, name)
        for side in "rl":
            for name in ["shoulder", "elbow", "hand", "upper-leg", "knee", "ankle", "foot-1", "foot-2", "clavicle"]:
                j[side + "-" + name] = joint(v, groups, side + "-" + name)
            for f in range(1, 6):
                for k in range(1, 5):
                    j["%s-finger-%d-%d" % (side, f, k)] = joint(v, groups, "%s-finger-%d-%d" % (side, f, k))
        ground = to_body_space(j["ground"])
        self.j = {k: to_body_space(p) - ground * np.array([0, 1, 0]) for k, p in j.items()}
        self.v = to_body_space(v) - ground * np.array([0, 1, 0])
        # The faces we keep: the body, and the eyeballs (they go with the head).
        self.body_faces = groups["body"]
        self.eye_faces = groups["helper-r-eye"] + groups["helper-l-eye"]
        self.report = {"id": pid, "targets": spec.get("targets", {})}
        self.spec = spec

    # Our side names: MakeHuman's "r" is his right, ours "_r" too.
    def our_joints(self):
        s = self.env["segments"]
        cap = lambda sid, i: np.array(s[sid]["capsules"][0][i])
        o = {}
        for side in "rl":
            sx = 1.0 if side == "r" else -1.0
            o[side + "-shoulder"] = cap("upper_arm_" + side, 0)
            o[side + "-elbow"] = (cap("upper_arm_" + side, 1) + cap("forearm_" + side, 0)) / 2
            o[side + "-hand"] = (cap("forearm_" + side, 1) + cap("hand_" + side, 0)) / 2
            o[side + "-knuckle"] = np.array([0.24 * sx, 0.773, -0.012])
            o[side + "-upper-leg"] = cap("thigh_" + side, 0)
            o[side + "-knee"] = (cap("thigh_" + side, 1) + cap("shin_" + side, 0)) / 2
            o[side + "-ankle"] = np.array([0.1 * sx, 0.085, 0.01])
            o[side + "-toe"] = np.array([0.1 * sx, 0.035, -0.17])
        o["hips"] = (o["r-upper-leg"] + o["l-upper-leg"]) / 2
        o["neck"] = np.array([0.0, 1.47, 0.005])
        o["head"] = np.array([0.0, 1.56, 0.0])
        o["crown"] = np.array([0.0, self.env["head_top"], 0.004])
        return o

    def bones(self):
        """The warp: [name, MakeHuman a, b, our a, b, radius (for who pulls a vertex)]."""
        m, o = self.j, self.our_joints()
        hips = (m["r-upper-leg"] + m["l-upper-leg"]) / 2
        # Trunk, neck and head move as one, at his own proportions (scaled to our height):
        # MakeHuman's "head" joint is at the jaw hinge, not the chin, so stretching joint to joint
        # onto our head segment made him a long thin neck and an egg of a head.
        k = self.env["head_top"] / m["head-2"][1]
        up = lambda p: np.array([0.0, p[1] * k, p[2] * k])
        out = [["trunk", hips, m["neck"], up(hips), up(m["neck"]), 0.15],
               ["neck", m["neck"], m["head"], up(m["neck"]), up(m["head"]), 0.055],
               ["head", m["head"], m["head-2"], up(m["head"]), up(m["head-2"]), 0.085]]
        for side in "rl":
            knuckle = m[side + "-finger-3-2"]
            out += [["upper_arm_" + side, m[side + "-shoulder"], m[side + "-elbow"], o[side + "-shoulder"], o[side + "-elbow"], 0.05],
                    ["forearm_" + side, m[side + "-elbow"], m[side + "-hand"], o[side + "-elbow"], o[side + "-hand"], 0.04],
                    ["hand_" + side, m[side + "-hand"], knuckle, o[side + "-hand"], o[side + "-knuckle"], 0.03],
                    ["thigh_" + side, m[side + "-upper-leg"], m[side + "-knee"], o[side + "-upper-leg"], o[side + "-knee"], 0.075],
                    ["shin_" + side, m[side + "-knee"], m[side + "-ankle"], o[side + "-knee"], o[side + "-ankle"], 0.05],
                    ["foot_" + side, m[side + "-ankle"], m[side + "-foot-2"], o[side + "-ankle"], o[side + "-toe"], 0.04]]
        return out

    # 2. Warp onto our joints.
    def warp(self):
        v = self.v
        bones = self.bones()
        mh_height = self.j["head-2"][1]
        radial = self.env["head_top"] / mh_height
        d = np.stack([seg_dist(v, b[1], b[2])[0] - b[5] for b in bones], axis=1)
        # The trunk's fat capsule reaches past the chin: nothing above his neck joint is trunk,
        # and nothing below it is head.
        names = [b[0] for b in bones]
        neck_y = self.j["neck"][1]
        d[v[:, 1] > neck_y + 0.01, names.index("trunk")] += 1.0
        d[v[:, 1] < neck_y, names.index("head")] += 1.0
        w = np.exp(-(d - d.min(1, keepdims=True)) / BLEND)
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
            moved = local @ rotation_between(u, ob - oa).T + oa
            out[sel] += w[sel, i][:, None] * moved
        self.fit_joints = {}
        # Where his own joints went (the eyes and mouth, for the face).
        for name in ["r-eye", "l-eye", "mouth", "jaw"]:
            self.fit_joints[name] = self._warp_point(self.j[name], bones, radial, "head")
        for side in "rl":
            for f in range(1, 6):
                for kk in range(1, 5):
                    key = "%s-finger-%d-%d" % (side, f, kk)
                    self.fit_joints[key] = self._warp_point(self.j[key], bones, radial, "hand_" + side)
        self.v = out
        self.report["mh_height_m"] = float(mh_height)

    def _warp_point(self, p, bones, radial, bone):
        for name, ma, mb, oa, ob, _r in bones:
            if name == bone:
                u = (mb - ma) / np.linalg.norm(mb - ma)
                k = np.linalg.norm(ob - oa) / np.linalg.norm(mb - ma)
                rel = p - ma
                along = rel @ u
                local = u * along * k + (rel - along * u) * radial
                return rotation_between(u, ob - oa) @ local + oa
        return p

    # 3. Fit to the envelope.
    def fit(self):
        T = self.env["tables"]
        v = self.v
        body_ids = sorted({i for f in self.body_faces for i in f[0]})
        mask = np.zeros(len(v), bool)
        mask[body_ids] = True
        reg = self.region
        # The head first: its heights so the eyes and mouth are where the face painter puts them.
        head = mask & (reg == "head")
        eye_y = (self.fit_joints["r-eye"][1] + self.fit_joints["l-eye"][1]) / 2
        mouth_y = self.fit_joints["mouth"][1]
        chin_y = v[head, 1].min()
        crown_y = v[head, 1].max()
        # Chin, eyes and crown only: MakeHuman's "mouth" joint sits well above the lips, and
        # pinning it to the painter's mouth row squashed his lower face.
        src = [chin_y, eye_y, crown_y]
        dst = [self.env["head_bottom"], 1.655, self.env["head_top"]]
        eyes = np.zeros(len(v), bool)
        for fv, _t in self.eye_faces:
            eyes[fv] = True
        hy = head | eyes
        v[hy, 1] = np.interp(v[hy, 1], src, dst)
        for k in ["r-eye", "l-eye", "mouth"]:
            self.fit_joints[k][1] = float(np.interp(self.fit_joints[k][1], src, dst))
        self.report["head_map"] = {"from": [float(x) for x in src], "to": dst}
        # Front to back: MakeHuman's neck leans further forward than our anatomy's, which put his
        # head ~5 cm in front of its hitboxes (and in front of the hat made for them). Slide the
        # head back till his eyes are the anatomy's eyes, the neck taking the lean from nothing
        # at its base to all of it at the head.
        eye_z = np.mean([s["sphere"][0][2] for s in self.anatomy["structures"] if s.get("organ") == "eye"])
        dz = float(eye_z - (self.fit_joints["r-eye"][2] + self.fit_joints["l-eye"][2]) / 2)
        upper = mask & np.isin(reg, ["trunk", "neck", "head"]) | eyes
        t = np.clip((v[:, 1] - NECK_BASE_Y) / (HEAD_BASE_Y - NECK_BASE_Y), 0.0, 1.0)
        t = t * t * (3.0 - 2.0 * t)
        v[upper, 2] += dz * t[upper]
        for k in ["r-eye", "l-eye", "mouth", "jaw"]:
            self.fit_joints[k][2] += dz
        self.report["head_back_m"] = round(-dz, 4)
        # Trunk, neck and head cross-sections, by height.
        # Gently: the envelope is the old mannequin's, and squeezing a real man into it thins his
        # neck and shrinks his head. Only the trunk and limbs are pulled toward it (the clothes
        # are made from his own body now, so they fit him whatever his shape); neck and head
        # keep MakeHuman's own proportions.
        self._fit_upright(mask & np.isin(reg, ["trunk"]), T["TRUNK"], strength=0.45)
        # Arms and legs, along each limb.
        for side, sx in (("r", 1.0), ("l", -1.0)):
            arm = mask & np.isin(reg, ["upper_arm_" + side, "forearm_" + side, "hand_" + side])
            self._fit_limb(arm, self._mirror(T["ARM"], sx), strength=0.4)
            leg = mask & np.isin(reg, ["thigh_" + side, "shin_" + side])
            self._fit_limb(leg, self._mirror(T["LEG"], sx), strength=0.4)
        self.v = v

    @staticmethod
    def _mirror(rows, sx):
        out = []
        for r in rows:
            c = list(r[0])
            c[0] *= sx
            out.append([c] + list(r[1:]))
        return out

    def _fit_upright(self, sel, rows, strength, carry=None):
        """Scale each horizontal slice to the envelope: half width, front and back depth."""
        v = self.v
        ys = np.array([r[0][1] for r in rows])
        cz = np.array([r[0][2] for r in rows])
        hw = np.array([r[1] for r in rows])
        fr = np.array([r[2] for r in rows])
        bk = np.array([r[3] for r in rows])
        pts = v[sel]
        levels = np.linspace(ys.min(), ys.max(), 24)
        mw, mf, mb = [], [], []
        for y in levels:
            band = pts[np.abs(pts[:, 1] - y) < 0.012]
            if len(band) < 6:
                mw.append(np.nan); mf.append(np.nan); mb.append(np.nan)
                continue
            c = np.interp(y, ys, cz)
            mw.append(np.percentile(np.abs(band[:, 0]), 92))
            front = c - band[:, 2]
            back = band[:, 2] - c
            mf.append(np.percentile(front[front > 0], 92) if (front > 0).sum() > 3 else np.nan)
            mb.append(np.percentile(back[back > 0], 92) if (back > 0).sum() > 3 else np.nan)
        def ratio(meas, target):
            meas = np.array(meas)
            tgt = np.interp(levels, ys, target)
            r = np.where(np.isnan(meas), 1.0, tgt / np.maximum(meas, 1e-4))
            r = smooth(np.clip(r, 0.7, 1.4))
            return 1.0 + (r - 1.0) * strength
        sx, sf, sb = ratio(mw, hw), ratio(mf, fr), ratio(mb, bk)
        idx = np.where(sel if carry is None else (sel | carry))[0]
        y = v[idx, 1]
        c = np.interp(y, ys, cz)
        fx = np.interp(y, levels, sx)
        ff = np.interp(y, levels, sf)
        fb = np.interp(y, levels, sb)
        v[idx, 0] *= fx
        dz = v[idx, 2] - c
        v[idx, 2] = c + dz * np.where(dz < 0, ff, fb)

    def _fit_limb(self, sel, rows, strength):
        """Scale each slice across a limb to the envelope's rings along it."""
        v = self.v
        cs = np.array([r[0] for r in rows], dtype=float)
        seg_len = np.linalg.norm(np.diff(cs, axis=0), axis=1)
        s_at = np.concatenate([[0], np.cumsum(seg_len)])
        idx = np.where(sel)[0]
        p = v[idx]
        # Nearest point on the ring polyline: its arc length.
        best_d = np.full(len(p), np.inf)
        best_s = np.zeros(len(p))
        for i in range(len(cs) - 1):
            d, t = seg_dist(p, cs[i], cs[i + 1])
            better = d < best_d
            best_d[better] = d[better]
            best_s[better] = s_at[i] + t[better] * seg_len[i]
        def frame_at(s):
            i = min(np.searchsorted(s_at, s, side="right") - 1, len(cs) - 2)
            i = max(i, 0)
            axis = (cs[i + 1] - cs[i]) / seg_len[i]
            front = np.array([0, 0, -1.0]) - axis * axis[2] * -1.0
            front /= np.linalg.norm(front)
            side = np.cross(front, axis)
            t = (s - s_at[i]) / seg_len[i]
            c = cs[i] + (cs[i + 1] - cs[i]) * t
            return c, axis, front, side
        n = 20
        levels = np.linspace(0, s_at[-1], n)
        tw = np.interp(levels, s_at, [r[1] for r in rows])
        tf = np.interp(levels, s_at, [r[2] for r in rows])
        tb = np.interp(levels, s_at, [r[3] for r in rows])
        mw, mf, mb = [], [], []
        local = np.zeros((len(p), 3))
        for k in range(len(p)):
            c, axis, front, side = frame_at(best_s[k])
            d = p[k] - c
            local[k] = [d @ side, d @ front, d @ axis]
        for L in levels:
            band = np.abs(best_s - L) < 0.02
            if band.sum() < 6:
                mw.append(np.nan); mf.append(np.nan); mb.append(np.nan)
                continue
            q = local[band]
            mw.append(np.percentile(np.abs(q[:, 0]), 92))
            fwd = q[:, 1][q[:, 1] > 0]
            bwd = -q[:, 1][q[:, 1] < 0]
            mf.append(np.percentile(fwd, 92) if len(fwd) > 3 else np.nan)
            mb.append(np.percentile(bwd, 92) if len(bwd) > 3 else np.nan)
        def ratio(meas, tgt):
            meas = np.array(meas)
            r = np.where(np.isnan(meas), 1.0, tgt / np.maximum(meas, 1e-4))
            r = smooth(np.clip(r, 0.7, 1.45))
            return 1.0 + (r - 1.0) * strength
        rw, rf, rb = ratio(mw, tw), ratio(mf, tf), ratio(mb, tb)
        for k in range(len(p)):
            c, axis, front, side = frame_at(best_s[k])
            a, b, h = local[k]
            a *= np.interp(best_s[k], levels, rw)
            b *= np.interp(best_s[k], levels, rf if b > 0 else rb)
            v[idx[k]] = c + side * a + front * b + axis * h

    # 4. Fingers off at the knuckles.
    def cut_fingers(self):
        v = self.v
        J = self.fit_joints
        drop = np.zeros(len(v), bool)
        for side in "rl":
            reg = self.region == "hand_" + side
            ids = np.where(reg)[0]
            p = v[ids]
            palm_d = np.full(len(p), np.inf)
            finger_d = np.full(len(p), np.inf)
            wrist = self.our_joints()[side + "-hand"]
            for f in range(1, 6):
                k1, k2, k3, k4 = [J["%s-finger-%d-%d" % (side, f, k)] for k in range(1, 5)]
                tip = k4 + (k4 - k3) * 1.2
                base = k2 if f > 1 else k2
                for a, b in ((wrist, k1), (k1, base)):
                    palm_d = np.minimum(palm_d, seg_dist(p, a, b)[0])
                for a, b in ((base, k3), (k3, k4), (k4, tip)):
                    d, t = seg_dist(p, a, b)
                    # A little past the knuckle before it counts as finger.
                    d = np.where((a == base).all() & (t < 0.12), np.inf, d)
                    finger_d = np.minimum(finger_d, d)
            drop[ids[finger_d < palm_d]] = True
        keep = []
        for fv, ft in self.body_faces:
            if not drop[fv].any():
                keep.append((fv, ft))
        self.report["faces_before_finger_cut"] = len(self.body_faces)
        self.body_faces = keep
        self.report["faces_after_finger_cut"] = len(keep)

    # 5. Skin weights: BodyMesh's blends along the trunk, neck, arms and legs.
    def weights(self):
        T = self.env["tables"]
        bones = self.env["bones"]
        bi = {b: i for i, b in enumerate(bones)}
        v = self.v
        W = np.zeros((len(v), len(bones)))
        reg = self.region

        def along_table(sel, rows, key):
            ys = np.array([r[0][1] for r in rows])
            order = np.argsort(ys)
            ys = ys[order]
            for i in np.where(sel)[0]:
                y = key(v[i])
                j = int(np.clip(np.searchsorted(ys, y), 1, len(ys) - 1))
                t = float(np.clip((y - ys[j - 1]) / max(ys[j] - ys[j - 1], 1e-6), 0, 1))
                for rr, wr in ((rows[order[j - 1]], 1 - t), (rows[order[j]], t)):
                    a, b, wb = rr[4], rr[5], rr[6]
                    W[i, bi[a]] += wr * (1 - wb)
                    W[i, bi[b]] += wr * wb

        along_table(reg == "trunk", T["TRUNK"], lambda p: p[1])
        along_table(reg == "neck", T["NECK"], lambda p: p[1])
        W[reg == "head", bi["head"]] = 1.0
        for side, sx in (("r", 1.0), ("l", -1.0)):
            m = lambda rows: [[r[0], r[1], r[2], r[3], r[4].replace("_r", "_" + side), r[5].replace("_r", "_" + side), r[6]] for r in rows]
            arm = np.isin(reg, ["upper_arm_" + side, "forearm_" + side, "hand_" + side])
            along_table(arm, m(T["ARM"]), lambda p: p[1])
            leg = np.isin(reg, ["thigh_" + side, "shin_" + side])
            along_table(leg, m(T["LEG"]), lambda p: p[1])
            foot = reg == "foot_" + side
            # The foot: the shin near the ankle, the foot beyond.
            for i in np.where(foot)[0]:
                t = float(np.clip((0.1 - v[i][1]) / 0.05 + (v[i][2] < 0.0) * 0.5, 0, 1))
                W[i, bi["shin_" + side]] += 1 - t
                W[i, bi["foot_" + side]] += t
        # Anything left over (none, normally): its region's bone.
        empty = W.sum(1) == 0
        for i in np.where(empty)[0]:
            name = reg[i] if reg[i] != "trunk" else "chest"
            W[i, bi.get(name, 0)] = 1.0
        W /= W.sum(1, keepdims=True)
        self.W = W

    # Head UVs: the face painter's layout (u round the head, 0.5 straight ahead; v by height).
    def head_uv(self, p):
        hb, ht = self.env["head_bottom"], self.env["head_top"]
        rows = self.env["tables"]["HEAD"]
        cz = np.interp(p[1], [r[0][1] for r in rows], [r[0][2] for r in rows])
        theta = math.atan2(p[0], -(p[2] - cz))  # 0 straight ahead, + to his right
        eye = self.fit_joints["r-eye"]
        eye_theta = abs(math.atan2(eye[0], -(eye[2] - cz)))
        # Painted eyes sit 6 of 96 texels either side of the middle.
        k = (math.tau * 6 / 96) / max(eye_theta, 0.05)
        a = abs(theta)
        blend = min(a / (math.pi * 0.5), 1.0)
        theta = theta * (k * (1 - blend) + blend)
        u = 0.5 + theta / math.tau
        return [u % 1.0, 1.0 - (p[1] - hb) / (ht - hb)]

    def run(self):
        self.warp()
        self.fit()
        self.cut_fingers()
        self.weights()


# --- Blender: meshes, decimation, export ---------------------------------------------------------

def to_blender(p):
    """Our body space (Y up, facing -Z) → Blender (Z up); glTF export turns it back."""
    return (p[0], -p[2], p[1])


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
        eb.head = to_blender(c)
        eb.tail = to_blender(c + np.array([0, 0.05, 0]))
    for b in bones:
        parent = env["segments"][b]["parent"]
        if parent:
            arm_data.edit_bones[b].parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")

    def make(name, faces, uv_of):
        # Per-corner UVs: split vertices where the UV differs (the seams).
        verts, loops_uv, polys, weights = [], [], [], []
        key_index = {}
        for fv, ft in faces:
            uvs = [uv_of(i, t) for i, t in zip(fv, ft)]
            if name == "head":
                us = [u for u, _ in uvs]
                if max(us) - min(us) > 0.5:  # across the seam at the back of the head
                    uvs = [(u + 1.0 if u < 0.5 else u, vv) for u, vv in uvs]
            poly = []
            for i, (u, vv) in zip(fv, uvs):
                k = (i, round(u, 5), round(vv, 5))
                if k not in key_index:
                    key_index[k] = len(verts)
                    verts.append(i)
                    loops_uv.append((u, vv))
                poly.append(key_index[k])
            polys.append(poly)
        mesh = bpy.data.meshes.new("body_" + name)
        mesh.from_pydata([to_blender(person.v[i]) for i in verts], [], polys)
        uv_layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                u, vv = loops_uv[mesh.loops[li].vertex_index]
                uv_layer.data[li].uv = (u, 1.0 - vv)  # glTF flips v back
        for poly in mesh.polygons:
            poly.use_smooth = True
        # "body_skin", "body_head": not the bones' names (Godot would rename the bone).
        obj = bpy.data.objects.new("body_" + name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        for bname in bones:
            obj.vertex_groups.new(name=bname)
        for new_i, old_i in enumerate(verts):
            for b, w in enumerate(person.W[old_i]):
                if w > 0.001:
                    obj.vertex_groups[b].add([new_i], float(w), "REPLACE")
        return obj

    person.arm = arm
    head_ids = person.region == "head"
    skin_faces = [f for f in person.body_faces if not head_ids[f[0]].all()]
    head_faces = [f for f in person.body_faces if head_ids[f[0]].all()] + person.eye_faces
    # Skin UVs: MakeHuman's own layout, scaled to about a metre per unit for the tiling skin.
    skin = make("skin", skin_faces, lambda i, t: (person.uv[t][0] * 1.8, (1.0 - person.uv[t][1]) * 1.8))
    head = make("head", head_faces, lambda i, t: tuple(person.head_uv(person.v[i])))
    # The face: a guide for the image model, and its portrait (if it's painted one) projected on.
    person.normals = clothes.vertex_normals(person.v, person.body_faces)
    faces.guide(head, os.path.abspath(os.path.join(OUT, "%s_face_guide.png" % person.id)))
    portrait = os.path.join(OUT, "%s_face_portrait.png" % person.id)
    if os.path.exists(portrait):
        faces.project(person, head_faces, person.head_uv, portrait, os.path.join(OUT, "%s_face.png" % person.id))
        person.report["face"] = "projected from " + os.path.basename(portrait)
    # Clothes: made on the fitted body, the coat draped, detail baked into pixel textures.
    outfit = person.spec.get("outfit", {})
    garments = clothes.make_all(person, outfit)
    cloth_objs = {n: clothes.to_object(g, to_blender, bones) for n, g in garments.items()}
    if "coat" in cloth_objs:
        clothes.drape(cloth_objs["coat"], garments["coat"], skin)
    person.report["textures"] = {}
    for n, obj in cloth_objs.items():
        clothes.unwrap(obj)
        png = os.path.join(OUT, "%s_%s.png" % (person.id, n))
        over = [o for m, o in cloth_objs.items() if clothes.OFFSET.get(m, 0.0) > clothes.OFFSET.get(n, 0.0)]
        size = clothes.bake_texture(obj, clothes.hex_colour(outfit[n]), os.path.abspath(png), seed=len(n) * 7 + 3,
                                    style="wool" if n in ("coat", "vest", "trousers") else "cotton", over=over)
        person.report["textures"][n] = size
    clothes.bake_head_ao(head, os.path.abspath(os.path.join(OUT, "%s_head_ao.png" % person.id)))
    for n, obj in cloth_objs.items():
        clothes.decimate(obj, clothes.BUDGET.get(n, 1000))
    total = sum(len(o.data.polygons) * 2 for o in (skin, head))
    for obj in (skin, head):
        share = len(obj.data.polygons) * 2 / total
        tris = len(obj.data.polygons) * 2
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = min(1.0, TRI_BUDGET * share / max(tris, 1))
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="decimate")
    # Cutting everything down lets under-layers poke through: push each layer back out.
    layers = dict(cloth_objs)
    layers["skin"] = skin
    clothes.separate(layers)
    for obj in [skin, head] + list(cloth_objs.values()):
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
    person.report["triangles"] = {o.name.split("_", 1)[1]: sum(len(p.vertices) - 2 for p in o.data.polygons)
                                  for o in [skin, head] + list(cloth_objs.values())}


def export(person):
    path = os.path.join(OUT, person.id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    person.report["fit_joints"] = {k: [round(float(x), 4) for x in v] for k, v in person.fit_joints.items()
                                   if "finger" not in k}
    json.dump(person.report, open(os.path.join(OUT, person.id + ".json"), "w"), indent=1)
    print("wrote", path, person.report.get("triangles"))


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = None
    for a in args:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
    env = json.load(open(ENVELOPE))
    people = json.load(open(os.path.join(OUT, "people.json")))["people"]
    for pid, spec in people.items():
        if only and pid != only:
            continue
        if spec.get("source") == "tripo":   # a Tripo model: tools/blender/fit_tripo.py's
            continue
        p = Person(pid, spec, env)
        p.run()
        if bpy is None:
            print("no bpy: fitted", pid, "but not exported")
            continue
        build_blender(p)
        export(p)


if __name__ == "__main__":
    main()
