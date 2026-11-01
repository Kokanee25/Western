"""A man from MPFB's data (the character bake-off's route B, issue #505), fitted to our skeleton.

    python3 tools/blender/fetch_mpfb.py                       # once: MPFB's data and the CC0 assets
    ~/.venvs/studio/bin/python tools/blender/mpfb_man.py [--only=mpfb_drifter]   # bpy 5.0.1

Each man in assets/people/mpfb_men.json is made from:
  1. MPFB's base mesh (MakeHuman's hm08) with his macros (gender, age, muscle, weight, height,
     proportions, race) mixed in the way MPFB's macro.json lays them out, and his own targets
     (chin, nose, cheeks...) from MPFB's target library.
  2. MPFB's "game_engine" rig: its 53 bones placed on the joints the rig file names, and MPFB's
     weights for them (weights.game_engine.json).
  3. MakeHuman's system assets (CC0) as proxies: eyes, clothes, boots, the hat, each placed on his
     body by its .mhclo binding (three of his vertices, their weights and a scaled offset), and
     weighted by the same binding. What a garment hides of his body is deleted (delete_verts).
     Hair and brows are cards with alpha, which the game's skin shader doesn't draw: they're
     painted into his skin texture through their binding instead (each card's pixels laid onto
     the skin's UVs under it).
  4. Posed onto our skeleton's rest (assets/people/envelope.json; arms down) by his own rig: each
     limb bone carried from MPFB's joints to ours (turned and stretched along the bone), the
     trunk, neck and head scaled to our height, all blended by MPFB's weights (linear blend
     skinning, as the game will move him).
  5. Weighted to our 17 bones by summing MPFB's bones into ours (MAP below).
  6. Written to assets/people/<id>.glb ("body_skin", "body_eyes", "cloth_<garment>": a "whole" man,
     PeopleBodies) with a texture a shape, assets/people/<id>_<shape>.png: MakeHuman's own albedo,
     no squares, no light painted in (the skin's stubble and weather are colour only).

MPFB's code (GPL-3) isn't run or copied: this reads its data files. Nothing is hand-edited.
"""
import gzip
import json
import math
import os
import sys
import time
import types

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

DATA = "build/mpfb/mpfb2/src/mpfb/data"
ASSETS = "build/mpfb/mh_system"
ENVELOPE = "assets/people/envelope.json"
SPEC = "assets/people/mpfb_men.json"
OUT = "assets/people"

# MPFB's game_engine bones -> our 17 segments. The clavicles are the chest's (as our skeleton has
# no collarbone); fingers ride the hand (the game's own fingers are separate pieces).
OUR = ["pelvis", "abdomen", "chest", "neck", "head", "upper_arm_r", "forearm_r", "hand_r", "thigh_r",
       "shin_r", "foot_r", "upper_arm_l", "forearm_l", "hand_l", "thigh_l", "shin_l", "foot_l"]
MAP = {"Root": "pelvis", "pelvis": "pelvis", "spine_01": "abdomen", "spine_02": "abdomen", "spine_03": "chest",
       "neck_01": "neck", "head": "head"}
for _s in "lr":
    MAP.update({"clavicle_" + _s: "chest", "upperarm_" + _s: "upper_arm_" + _s, "lowerarm_" + _s: "forearm_" + _s,
                "hand_" + _s: "hand_" + _s, "thigh_" + _s: "thigh_" + _s, "calf_" + _s: "shin_" + _s,
                "foot_" + _s: "foot_" + _s, "ball_" + _s: "foot_" + _s})
    for _f in ["thumb", "index", "middle", "ring", "pinky"]:
        for _k in "123":
            MAP["%s_0%s_%s" % (_f, _k, _s)] = "hand_" + _s


# Heights (m) over which the neck hands over to the head and the chest to the neck (our joints at
# 1.56 and 1.47).
NECK_HEAD = (1.53, 1.60)
CHEST_NECK = (1.44, 1.50)


# --- Reading MPFB's and MakeHuman's files ------------------------------------------------------

def load_obj(path):
    """Vertices (N,3), UVs (M,2), faces [(vertex ids, uv ids)], groups {name: [face index]}."""
    v, vt, faces, groups = [], [], [], {}
    group = "default"
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if line.startswith("v "):
                v.append([float(x) for x in line.split()[1:4]])
            elif line.startswith("vt "):
                vt.append([float(x) for x in line.split()[1:3]])
            elif line.startswith("g "):
                group = line.split(None, 1)[1].strip()
            elif line.startswith("f "):
                ids, uvs = [], []
                for tok in line.split()[1:]:
                    p = tok.split("/")
                    ids.append(int(p[0]) - 1)
                    uvs.append(int(p[1]) - 1 if len(p) > 1 and p[1] else -1)
                groups.setdefault(group, []).append(len(faces))
                faces.append((ids, uvs))
    return np.array(v), np.array(vt) if vt else np.zeros((0, 2)), faces, groups


def load_target(path):
    opener = gzip.open if path.endswith(".gz") else open
    idx, d = [], []
    with opener(path, "rt") as f:
        for line in f:
            p = line.split()
            if len(p) == 4 and not line.startswith("#"):
                idx.append(int(p[0]))
                d.append([float(x) for x in p[1:]])
    return np.array(idx, dtype=int), np.array(d)


def macro_weights(m):
    """{target path (under targets/macrodetails): weight} for macros m, by macro.json's parts: a value
    inside a part weighs its low end 1-t and its high end t (t its place in the part)."""
    def parts(lo_hi):  # [(bound, name)] -> {name: weight}
        def f(x):
            for (a, na), (b, nb) in zip(lo_hi, lo_hi[1:]):
                if x <= b or (b == lo_hi[-1][0]):
                    t = min(max((x - a) / (b - a), 0.0), 1.0)
                    out = {}
                    if na:
                        out[na] = out.get(na, 0.0) + 1 - t
                    if nb:
                        out[nb] = out.get(nb, 0.0) + t
                    return out
        return f
    gender = {"female": 1 - m["gender"], "male": m["gender"]}
    age = parts([(0.0, "baby"), (0.1875, "child"), (0.5, "young"), (1.0, "old")])(m["age"])
    muscle = parts([(0.0, "minmuscle"), (0.5, "averagemuscle"), (1.0, "maxmuscle")])(m["muscle"])
    weight = parts([(0.0, "minweight"), (0.5, "averageweight"), (1.0, "maxweight")])(m["weight"])
    height = parts([(0.0, "minheight"), (0.5, ""), (1.0, "maxheight")])(m["height"])
    prop = parts([(0.0, "uncommonproportions"), (0.5, ""), (1.0, "idealproportions")])(m["proportions"])
    race = {r: m.get(r, 0.0) for r in ("african", "asian", "caucasian")}
    out = {}
    for g, wg in gender.items():
        for a, wa in age.items():
            for r, wr in race.items():
                out["%s-%s-%s.target.gz" % (r, g, a)] = wr * wg * wa
            for mu, wm in muscle.items():
                for we, ww in weight.items():
                    base = wg * wa * wm * ww
                    out["universal-%s-%s-%s-%s.target.gz" % (g, a, mu, we)] = base
                    for h, wh in height.items():
                        out["height/%s-%s-%s-%s-%s.target.gz" % (g, a, mu, we, h)] = base * wh
                    for p, wp in prop.items():
                        out["proportions/%s-%s-%s-%s-%s.target.gz" % (g, a, mu, we, p)] = base * wp
    return {k: w for k, w in out.items() if w > 1e-4}


def load_mhclo(path):
    """A proxy's binding: header fields, refs (per proxy vertex: ([ids], [weights], offset)), and the
    body vertices it deletes."""
    head, refs, delete = {}, [], set()
    mode = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            s = line.split("#", 1)[0].strip()
            if not s:
                continue
            p = s.split()
            if p[0] == "verts":
                mode = "verts"
                continue
            if p[0] == "delete_verts":
                mode = "delete"
                continue
            if mode == "verts" and len(p) in (1, 9) and _numeric(p):
                if len(p) == 1:
                    refs.append(([int(p[0])] * 3, [1.0, 0.0, 0.0], [0.0, 0.0, 0.0]))
                else:
                    refs.append(([int(x) for x in p[:3]], [float(x) for x in p[3:6]], [float(x) for x in p[6:9]]))
                continue
            if mode == "delete" and _numeric([x for x in p if x != "-"]):
                i = 0
                while i < len(p):
                    if i + 2 < len(p) and p[i + 1] == "-":
                        delete.update(range(int(p[i]), int(p[i + 2]) + 1))
                        i += 3
                    else:
                        delete.add(int(p[i]))
                        i += 1
                continue
            # A header line may come after "verts" (short04 names its material there): kept, and
            # the binding's lines go on.
            head.setdefault(p[0], []).append(p[1:])
    return head, refs, delete


def _numeric(p):
    try:
        [float(x) for x in p]
        return True
    except ValueError:
        return False


def read_mhmat(path):
    out = {}
    for line in open(path, encoding="utf-8", errors="replace"):
        p = line.split("#", 1)[0].split()
        if len(p) >= 2:
            out[p[0]] = " ".join(p[1:])
    return out


# --- Geometry -----------------------------------------------------------------------------------

def to_ours(p):
    """MakeHuman (decimetres, Y up, facing +Z, his right at -X) -> ours (metres, facing -Z, right +X)."""
    return np.asarray(p, dtype=float) * np.array([-0.1, 0.1, -0.1])


def rotation_between(u, w):
    u = u / np.linalg.norm(u)
    w = w / np.linalg.norm(w)
    axis = np.cross(u, w)
    s, c = np.linalg.norm(axis), float(u @ w)
    if s < 1e-9:
        return np.eye(3)
    axis /= s
    k = np.array([[0, -axis[2], axis[1]], [axis[2], 0, -axis[0]], [-axis[1], axis[0], 0]])
    a = math.atan2(s, c)
    return np.eye(3) + math.sin(a) * k + (1 - math.cos(a)) * (k @ k)


def bone_affine(h, t, H, T):
    """The 3x4 map carrying bone h->t onto H->T: turned the short way and stretched along its length."""
    d = t - h
    L = np.linalg.norm(d)
    u = d / L
    stretch = np.eye(3) + (np.linalg.norm(T - H) / L - 1.0) * np.outer(u, u)
    m = rotation_between(d, T - H) @ stretch
    return np.hstack([m, (H - m @ h)[:, None]])


def vertex_normals(v, tris):
    n = np.zeros_like(v)
    fn = np.cross(v[tris[:, 1]] - v[tris[:, 0]], v[tris[:, 2]] - v[tris[:, 0]])
    for k in range(3):
        np.add.at(n, tris[:, k], fn)
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


def triangulate(faces):
    out = []
    for ids, uvs in faces:
        for k in range(1, len(ids) - 1):
            out.append(((ids[0], ids[k], ids[k + 1]), (uvs[0], uvs[k], uvs[k + 1])))
    return out


# --- Painting into a texture through UVs --------------------------------------------------------

def raster(tex_size, dst_uv, src, fn):
    """For each triangle (dst_uv (T,3,2) in 0..1, v up), every texel it covers: fn(ys, xs, bary (n,3),
    triangle index). Texel centres; v flipped to image rows."""
    W, H = tex_size
    for i in range(len(dst_uv)):
        p = dst_uv[i] * np.array([W, H])
        p[:, 1] = H - p[:, 1]
        x0, y0 = np.floor(p.min(0)).astype(int)
        x1, y1 = np.ceil(p.max(0)).astype(int)
        x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
        if x1 < x0 or y1 < y0:
            continue
        ys, xs = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        q = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], 1)
        a, b, c = p
        m = np.array([[b[0] - a[0], c[0] - a[0]], [b[1] - a[1], c[1] - a[1]]])
        det = np.linalg.det(m)
        if abs(det) < 1e-9:
            continue
        st = np.linalg.solve(m, (q - a).T).T
        bary = np.stack([1 - st[:, 0] - st[:, 1], st[:, 0], st[:, 1]], 1)
        inside = (bary >= -0.02).all(1)
        if inside.any():
            fn(ys.ravel()[inside], xs.ravel()[inside], bary[inside], i)


def sample(img, uv):
    """Bilinear samples of img (H,W,C float) at uv (n,2), v up, wrapping."""
    H, W = img.shape[:2]
    x = (uv[:, 0] % 1.0) * W - 0.5
    y = (1.0 - uv[:, 1] % 1.0) * H - 0.5
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[:, None], (y - y0)[:, None]
    g = lambda yy, xx: img[np.clip(yy, 0, H - 1), np.clip(xx, 0, W - 1)]
    return (g(y0, x0) * (1 - fx) * (1 - fy) + g(y0, x0 + 1) * fx * (1 - fy) +
            g(y0 + 1, x0) * (1 - fx) * fy + g(y0 + 1, x0 + 1) * fx * fy)


def value_noise(shape, cell, seed):
    rng = np.random.default_rng(seed)
    gh, gw = shape[0] // cell + 2, shape[1] // cell + 2
    g = rng.random((gh, gw))
    ys, xs = np.mgrid[0:shape[0], 0:shape[1]] / cell
    y0, x0 = ys.astype(int), xs.astype(int)
    fy, fx = ys - y0, xs - x0
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    return (g[y0, x0] * (1 - fx) * (1 - fy) + g[y0, x0 + 1] * fx * (1 - fy) +
            g[y0 + 1, x0] * (1 - fx) * fy + g[y0 + 1, x0 + 1] * fx * fy)


# --- The man ------------------------------------------------------------------------------------

class Man:
    def __init__(self, mid, spec, env):
        self.id, self.spec, self.env = mid, spec, env
        self.report = {"id": mid, "whole": True, "spec": spec,
                       "made_by": "tools/blender/mpfb_man.py (the bake-off's route B: MPFB's data, MakeHuman's CC0 assets)"}
        self.timings = {}

    def tick(self, what, t0):
        self.timings[what] = round(time.time() - t0, 2)

    # 1. Body and targets.
    def body(self):
        t0 = time.time()
        v, vt, faces, groups = load_obj(os.path.join(DATA, "3dobjs/base.obj"))
        self.base_count = len(v)
        mods = {}
        for path, w in macro_weights(self.spec["macros"]).items():
            mods["macrodetails/" + path] = w
        for name, w in self.spec.get("targets", {}).items():
            mods[name] = mods.get(name, 0.0) + w
        applied = {}
        for path, w in mods.items():
            full = os.path.join(DATA, "targets", path if path.endswith(".gz") else path + ".target.gz")
            if not os.path.exists(full):
                raise FileNotFoundError(full)
            idx, d = load_target(full)
            if len(idx):  # the neutral targets (averagemuscle-averageweight) are empty
                v[idx] += w * d
            applied[path] = round(w, 4)
        self.report["targets"] = applied
        self.v0, self.vt, self.faces, self.groups = v, vt, faces, groups
        self.tick("body", t0)

    def joint(self, name):
        ids = sorted({i for f in self.groups["joint-" + name] for i in self.faces[f][0]})
        return self.v0[ids].mean(0)

    def point(self, spec):
        s = spec.get("strategy", "CUBE")
        if s == "CUBE":
            return self.joint(spec["cube_name"].replace("joint-", "", 1))
        if s == "VERTEX":
            return self.v0[spec["vertex_index"]]
        if s == "MEAN":
            return self.v0[spec["vertex_indices"]].mean(0)
        if s == "XYZ":
            return np.array([self.v0[spec["x"]][0], self.v0[spec["y"]][1], self.v0[spec["z"]][2]])
        raise ValueError("rig strategy " + s)

    # 2. The rig and its weights.
    def rig(self):
        t0 = time.time()
        rig = json.load(open(os.path.join(DATA, "rigs/standard/rig.game_engine.json")))
        self.bones = list(rig)
        self.bone_ht = {b: (self.point(r["head"]), self.point(r["tail"])) for b, r in rig.items()}
        wj = json.load(open(os.path.join(DATA, "rigs/standard/weights.game_engine.json")))["weights"]
        W = np.zeros((len(self.v0), len(self.bones)))
        for k, b in enumerate(self.bones):
            for vi, w in wj.get(b, []):
                W[vi, k] += w
        s = W.sum(1, keepdims=True)
        self.W = np.divide(W, s, out=np.zeros_like(W), where=s > 0)
        self.tick("rig", t0)

    # 3. Proxies.
    def proxy(self, kind, name, mat=None):
        folder = os.path.join(ASSETS, kind, name)
        mhclo = [f for f in os.listdir(folder) if f.endswith(".mhclo")][0]
        head, refs, delete = load_mhclo(os.path.join(folder, mhclo))
        pv, pvt, pfaces, _ = load_obj(os.path.join(folder, head["obj_file"][0][0]))
        scale = np.ones(3)
        for k, axis in enumerate(["x_scale", "y_scale", "z_scale"]):
            if axis in head:
                a, b, d = head[axis][0]
                scale[k] = abs(self.v0[int(a), k] - self.v0[int(b), k]) / float(d)
        ids = np.array([r[0] for r in refs])
        ws = np.array([r[1] for r in refs])
        off = np.array([r[2] for r in refs])
        pos = (self.v0[ids] * ws[..., None]).sum(1) + off * scale
        weights = (self.W[ids] * ws[..., None]).sum(1)
        s = weights.sum(1, keepdims=True)
        weights = np.divide(weights, s, out=np.zeros_like(weights), where=s > 1e-9)
        mat_path = os.path.normpath(os.path.join(folder, mat or head["material"][0][0]))
        material = read_mhmat(mat_path)
        tex = os.path.normpath(os.path.join(os.path.dirname(mat_path), material["diffuseTexture"]))
        return {"name": name, "v": pos, "vt": pvt, "faces": pfaces, "W": weights, "ids": ids, "ws": ws,
                "delete": delete, "texture": tex, "verts": len(pv)}

    def dress(self):
        t0 = time.time()
        sp = self.spec
        self.proxies = {}
        self.proxies["eyes"] = self.proxy("eyes", "high-poly", "../materials/%s.mhmat" % sp["eyes"])
        drop_corneas(self.proxies["eyes"])
        for shape, (kind, name) in sp["wear"].items():
            self.proxies[shape] = self.proxy(kind, name)
        self.painted = {k: self.proxy(kind, name) for k, (kind, name) in sp.get("paint_on", {}).items()}
        self.deleted = set()
        for p in self.proxies.values():
            self.deleted |= p["delete"]
        self.tick("dress", t0)

    # 4. Posed onto our rest.
    def our_joints(self):
        import make_people  # our skeleton's joints, as the MakeHuman people are fitted to them
        return make_people.Person.our_joints(types.SimpleNamespace(env=self.env))

    def pose(self):
        t0 = time.time()
        body = self.groups["body"]
        body_ids = sorted({i for f in body for i in self.faces[f][0]})
        o = self.our_joints()
        P = to_ours(self.v0)
        ground, crown = P[body_ids, 1].min(), P[body_ids, 1].max()
        k = (self.env["head_top"] - 0.0) / (crown - ground)
        hips = (to_ours(self.joint("r-upper-leg")) + to_ours(self.joint("l-upper-leg"))) / 2
        lift = np.array([-hips[0] * k, -ground * k, o["hips"][2] - hips[2] * k])
        G = np.hstack([np.eye(3) * k, lift[:, None]])
        g = lambda p: G[:, :3] @ p + G[:, 3]
        bt = {b: (g(to_ours(h)), g(to_ours(t))) for b, (h, t) in self.bone_ht.items()}
        A = {b: G for b in self.bones}
        targets = {}
        for s in "rl":
            sx = 1.0 if s == "r" else -1.0
            mid1 = "middle_01_" + s
            targets.update({
                "upperarm_" + s: (o[s + "-shoulder"], o[s + "-elbow"]),
                "lowerarm_" + s: (o[s + "-elbow"], o[s + "-hand"]),
                "hand_" + s: (o[s + "-hand"], o[s + "-knuckle"]),
                "thigh_" + s: (o[s + "-upper-leg"], o[s + "-knee"]),
                "calf_" + s: (o[s + "-knee"], o[s + "-ankle"]),
                "foot_" + s: (o[s + "-ankle"], o[s + "-toe"])})
            self._hand_src = None
            for b in ("upperarm_", "lowerarm_", "thigh_", "calf_", "foot_"):
                h, t = bt[b + s]
                A[b + s] = bone_affine(h, t, *targets[b + s])
            # The hand from his wrist to his middle knuckle (the hand bone ends short of it).
            h = bt["hand_" + s][0]
            A["hand_" + s] = bone_affine(h, bt[mid1][0], *targets["hand_" + s])
            for f in ["thumb", "index", "middle", "ring", "pinky"]:
                for kk in "123":
                    A["%s_0%s_%s" % (f, kk, s)] = A["hand_" + s]
            A["ball_" + s] = A["foot_" + s]
            del sx
        # Each limb's map is made in the scaled space: put the scale first.
        then = lambda a: np.hstack([a[:, :3] @ G[:, :3], (a[:, :3] @ G[:, 3] + a[:, 3])[:, None]])
        self.A = np.stack([A[b] if A[b] is G else then(A[b]) for b in self.bones])  # (B,3,4)
        self.report["scale"] = round(float(k), 4)
        self.report["bone_heights"] = {b: [round(float(x), 3) for x in bt[b][0]] for b in
                                       ("pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "head",
                                        "clavicle_r", "upperarm_r", "thigh_r")}
        self.P = self.skin_points(P, self.W)
        for p in list(self.proxies.values()) + list(self.painted.values()):
            p["P"] = self.skin_points(to_ours(p["v"]), p["W"])
        self.tick("pose", t0)

    def skin_points(self, P, W):
        X = np.hstack([P, np.ones((len(P), 1))])  # (N,4)
        per = np.einsum("bij,nj->nbi", self.A, X)  # (N,B,3)
        return np.einsum("nb,nbi->ni", W, per)

    def our_weights(self, W, P):
        """MPFB's weights summed into our bones (MAP), with the neck re-blended to our joints: MPFB's
        neck runs from 1.55 to its head bone at 1.65 m (the skull's base), ours from 1.47 to the
        head's pivot at 1.56, so what MPFB gives its neck and head is shared out again by height,
        his jaw (MPFB's head) kept on our head."""
        M = np.zeros((len(self.bones), len(OUR)))
        for k, b in enumerate(self.bones):
            M[k, OUR.index(MAP[b])] = 1.0
        out = W @ M
        bi = {b: k for k, b in enumerate(self.bones)}
        nh = W[:, bi["neck_01"]] + W[:, bi["head"]]
        y = P[:, 1]
        smooth = lambda a, b, x: np.clip((x - a) / (b - a), 0, 1) ** 2 * (3 - 2 * np.clip((x - a) / (b - a), 0, 1))
        head = np.maximum(W[:, bi["head"]] / np.maximum(nh, 1e-9), smooth(*NECK_HEAD, y))
        chest = 1 - smooth(*CHEST_NECK, y)
        out[:, OUR.index("head")] = nh * head
        out[:, OUR.index("neck")] = nh * (1 - head) * (1 - chest)
        out[:, OUR.index("chest")] += nh * (1 - head) * chest
        s = out.sum(1, keepdims=True)
        out = np.divide(out, s, out=np.zeros_like(out), where=s > 0)
        out[s[:, 0] <= 0, OUR.index("pelvis")] = 1.0
        return out

    # 6. Textures.
    def body_uv(self):
        """One UV per body vertex (the first face corner's), for painting cards onto the skin."""
        uv = np.zeros((len(self.v0), 2))
        for f in self.groups["body"]:
            ids, uvs = self.faces[f]
            for i, t in zip(ids, uvs):
                uv[i] = self.vt[t]
        return uv

    def skin_texture(self, path):
        t0 = time.time()
        sp = self.spec
        img = np.asarray(Image.open(sp_path(sp["skin"])).convert("RGB"), dtype=float) / 255.0
        H, W_ = img.shape[:2]
        tris = [t for f in self.groups["body"] for t in triangulate([self.faces[f]])]
        tri_v = np.array([t[0] for t in tris])
        tri_uv = self.vt[np.array([t[1] for t in tris])]
        # Where on him: per body vertex weights for stubble and weather, from his posed points.
        P = self.P
        head_c = (self.our_joints()["head"] + np.array([0, 0.09, 0]))
        y, z = P[:, 1], P[:, 2]
        # His beard's ground, from his own face (posed, metres): under the jaw (1.52) up to below his
        # nose at the middle (1.635) and up the cheeks at the sides (1.655), the front of the face
        # back to the jaw's angle, lips left bare. The numbers are this head's (MakeHuman's jaw and
        # mouth joints don't mark the lips: see make_people.py).
        ax = np.abs(P[:, 0])
        ramp = lambda a, b, t: np.clip((t - a) / (b - a), 0, 1)
        top = 1.635 + 0.02 * ramp(0.02, 0.05, ax)
        stubble = ramp(1.515, 1.545, y) * ramp(top + 0.012, top, y) * ramp(0.075, 0.06, ax) * ramp(-0.02, -0.05, z)
        lips = ramp(1.600, 1.607, y) * ramp(1.630, 1.624, y) * ramp(0.03, 0.022, ax) * ramp(-0.14, -0.15, z)
        stubble = np.clip(stubble * (1 - lips), 0, 1)
        weather = np.clip((y - 1.45) / 0.05, 0, 1) * np.clip(1 - np.linalg.norm(P - head_c, axis=1) / 0.16, 0, 1) ** 0.3
        hands = np.clip((0.86 - y) / 0.03, 0, 1) * np.clip((y - 0.6) / 0.03, 0, 1) * (np.abs(P[:, 0]) > 0.15)
        weather = np.maximum(weather, hands * 0.8)
        field = np.zeros((H, W_, 2))

        def put(ys, xs, bary, i):
            vals = np.stack([stubble[tri_v[i]], weather[tri_v[i]]], 1)  # (3,2)
            field[ys, xs] = np.maximum(field[ys, xs], bary.clip(0, 1) @ vals)
        raster((W_, H), tri_uv, None, put)
        st, we = field[..., 0], field[..., 1]
        # Weathered: warmer and a touch darker where the sun has had him (face, neck, hands).
        tan = np.array(sp.get("tan", [0.93, 0.84, 0.74]))
        img = img * (1 - we[..., None] * (1 - tan))
        # Stubble: dark specks of beard at the given density, thinning to the edge.
        grain = np.random.default_rng(7).random((H, W_))
        blot = value_noise((H, W_), 6, 3)
        hair = (grain > 1 - sp.get("stubble", 0.55) * st * (0.6 + 0.6 * blot)).astype(float)
        beard = np.array(sp.get("beard_colour", [0.16, 0.12, 0.09]))
        # A soft shadow of beard (the read from a few metres) and faint hairs over it (close up):
        # bright specks alias on the game's sharp texels, so the shadow carries it.
        st = np.asarray(Image.fromarray((st * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4)), dtype=float) / 255.0
        cover = np.clip(hair * 0.18 + st * sp.get("stubble_shadow", 0.32), 0, 1)[..., None]
        img = img * (1 - cover) + beard * cover
        # Cards painted on through their binding: brows, hair.
        uv = self.body_uv()
        for name, p in self.painted.items():
            ptex = np.asarray(Image.open(p["texture"]).convert("RGBA"), dtype=float) / 255.0
            tint = np.array(sp.get("hair_tint", [1, 1, 1]))
            ptris = triangulate(p["faces"])
            dst = []
            src = []
            for ids, uvs in ptris:
                d = np.array([(uv[p["ids"][i]] * p["ws"][i][:, None]).sum(0) for i in ids])
                if np.ptp(d[:, 0]) > 0.05 or np.ptp(d[:, 1]) > 0.05:
                    continue  # across a seam in his skin's UVs
                dst.append(d)
                src.append(p["vt"][list(uvs)])
            src = np.array(src)

            def card(ys, xs, bary, i):
                c = sample(ptex, bary @ src[i])
                a = c[:, 3:4] * sp.get("paint_alpha", {}).get(name, 1.0)
                img[ys, xs] = img[ys, xs] * (1 - a) + c[:, :3] * tint * a
            raster((W_, H), np.array(dst), None, card)
        Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).save(path)
        self.tick("skin_texture", t0)

    def regions(self, shape, p, hw):
        """A garment's parts as texture masks, by where its faces are on him: {"legs": "below:0.93"}
        is every face whose middle is under 0.93 m (the trousers of a shirt-and-trousers mesh; a third
        number keeps it within that far of his middle, leaving the cuffs out), and
        "top" the rest. A colour can't tell faded denim from a white stripe; where it is can."""
        out = {}
        for name, rule in self.spec.get("regions", {}).get(shape, {}).items():
            kind, val = rule.split(":")[:2]
            near = float(rule.split(":")[2]) if rule.count(":") > 1 else 9.0  # "below:0.93:0.17": and within 0.17 m of his middle (not the cuffs)
            mask = np.zeros(hw)
            tris = triangulate(p["faces"])
            mid = lambda t: p["P"][list(t[0])].mean(0)
            sel = [t for t in tris if (mid(t)[1] < float(val)) == (kind == "below") and abs(mid(t)[0]) < near]
            uv = p["vt"][np.array([t[1] for t in sel])]

            def fill(ys, xs, bary, i):
                mask[ys, xs] = 1.0
            raster((hw[1], hw[0]), uv, None, fill)
            # Grown a few texels so the seams' edges go with their part.
            grown = mask.copy()
            for dy, dx in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
                grown = np.maximum(grown, np.roll(np.roll(mask, dy, 0), dx, 1))
            out[name] = grown
            out.setdefault("top" if name != "top" else "rest", 1.0 - grown)
        return out

    def garment_texture(self, shape, p, path):
        img = np.asarray(Image.open(p["texture"]).convert("RGB"), dtype=float) / 255.0
        rule = self.spec.get("retint", {}).get(shape)
        if rule:
            img = retint(img, rule, self.regions(shape, p, img.shape[:2]))
        size = self.spec.get("texture_size", {}).get(shape)
        im = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
        if size and im.size[0] > size:
            im = im.resize((size, size), Image.LANCZOS)
        im.save(path)

    def run(self):
        self.body()
        self.rig()
        self.dress()
        self.pose()
        self.reshape_hat()


    def reshape_hat(self):
        """A wider brim and a taller crown on MakeHuman's fedora: a working man's hat, not a city one.
        Points below the band are pushed out from the crown's axis, the crown's top raised."""
        h = self.spec.get("hat_shape")
        p = self.proxies.get("hat")
        if not h or p is None:
            return
        P = p["P"]
        c = P.mean(0)
        top = P[:, 1].max()
        band = np.percentile(P[:, 1], h.get("band_percentile", 30))
        r = P[:, [0, 2]] - c[[0, 2]]
        dist = np.linalg.norm(r, axis=1)
        rim = np.percentile(dist, 60)
        out = np.clip((dist - rim) / max(dist.max() - rim, 1e-6), 0, 1)
        P[:, [0, 2]] = c[[0, 2]] + r * (1 + (h["brim"] - 1) * out)[:, None]
        up = np.clip((P[:, 1] - band) / max(top - band, 1e-6), 0, 1)
        P[:, 1] += up * h.get("crown_raise", 0.0)


def drop_corneas(p):
    """MakeHuman's high-poly eyes are two shells each: the ball, and over it a cornea drawn see-through
    from a corner of the texture. The game draws no see-through skin, so the cornea (a shell whose
    UVs cover under 2% of the texture) would hide the iris: it goes."""
    n = len(p["v"])
    par = np.arange(n)

    def find(a):
        while par[a] != a:
            par[a] = par[par[a]]
            a = par[a]
        return a
    for ids, _ in p["faces"]:
        for i in ids[1:]:
            par[find(i)] = find(ids[0])
    keep = []
    by_comp = {}
    for k, (ids, uvs) in enumerate(p["faces"]):
        by_comp.setdefault(find(ids[0]), []).append(k)
    for c, fs in by_comp.items():
        uv = p["vt"][[t for k in fs for t in p["faces"][k][1]]]
        if np.prod(np.ptp(uv, 0)) >= 0.02:
            keep += fs
    p["faces"] = [p["faces"][k] for k in sorted(keep)]


def retint(img, rule, regions=None):
    """Grade a garment's albedo: each rule {"where": "blue"|"all", "to": [r,g,b], "keep": share of
    its own colour kept, "gain": brightness}: the selected pixels' luminance carried in the new
    colour (cloth weave and folds kept, its hue changed)."""
    blue = np.clip((img[..., 2] - np.maximum(img[..., 0], img[..., 1]) - 0.02) / 0.08, 0, 1)  # of the original
    for r in rule:
        lum = img @ np.array([0.3, 0.59, 0.11])
        if r["where"].startswith("region:"):
            m = (regions or {})[r["where"].split(":", 1)[1]]
        else:
            m = {"blue": blue, "not_blue": 1 - blue}.get(r["where"], np.ones(lum.shape))
        mean = (lum * m).sum() / max(m.sum(), 1)
        rel = (lum / max(mean, 1e-3)) ** r.get("contrast", 1.0)  # <1 evens out fades and highlights
        to = np.array(r["to"]) * rel[..., None] * r.get("gain", 1.0)
        new = img * r.get("keep", 0.0) + to * (1 - r.get("keep", 0.0))
        if r.get("desaturate"):
            g = new @ np.array([0.3, 0.59, 0.11])
            new = new * (1 - r["desaturate"]) + g[..., None] * r["desaturate"]
        img = img * (1 - m[..., None]) + new * m[..., None]
    return np.clip(img, 0, 1)


def sp_path(rel):
    return os.path.join(ASSETS, rel)


# --- Export ---------------------------------------------------------------------------------------

def to_blender(p):
    return (p[0], -p[2], p[1])


def export(man):
    import bpy
    t0 = time.time()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    env = man.env
    arm_data = bpy.data.armatures.new("Skeleton")
    arm = bpy.data.objects.new("Skeleton", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for b in OUR:
        c = np.array(env["segments"][b]["center"])
        eb = arm_data.edit_bones.new(b)
        eb.head = to_blender(c)
        eb.tail = to_blender(c + np.array([0, 0.05, 0]))
    for b in OUR:
        parent = env["segments"][b]["parent"]
        if parent:
            arm_data.edit_bones[b].parent = arm_data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    tris = {}

    def make(obj_name, P, W, vt, faces):
        verts, loops_uv, polys = [], [], []
        index = {}
        for ids, uvs in faces:
            poly = []
            for i, t in zip(ids, uvs):
                u = tuple(np.round(vt[t], 6)) if t >= 0 else (0.0, 0.0)
                key = (i, u)
                if key not in index:
                    index[key] = len(verts)
                    verts.append(i)
                    loops_uv.append(u)
                poly.append(index[key])
            polys.append(poly)
        mesh = bpy.data.meshes.new(obj_name)
        mesh.from_pydata([to_blender(P[i]) for i in verts], [], polys)
        layer = mesh.uv_layers.new(name="UVMap")
        for poly in mesh.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                layer.data[li].uv = loops_uv[mesh.loops[li].vertex_index]
        obj = bpy.data.objects.new(obj_name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        ours = man.our_weights(W, P)
        for b in OUR:
            obj.vertex_groups.new(name=b)
        for new_i, old_i in enumerate(verts):
            for b in np.argsort(-ours[old_i])[:4]:
                if ours[old_i, b] > 0.001:
                    obj.vertex_groups[int(b)].add([new_i], float(ours[old_i, b]), "REPLACE")
        m = obj.modifiers.new("skeleton", "ARMATURE")
        m.object = arm
        obj.parent = arm
        tris[obj_name] = sum(len(p) - 2 for p in polys)
        return obj

    body_faces = [man.faces[f] for f in man.groups["body"] if not (set(man.faces[f][0]) & man.deleted)]
    make("body_skin", man.P, man.W, man.vt, body_faces)
    for shape, p in man.proxies.items():
        prefix = "body_" if shape == "eyes" else "cloth_"
        make(prefix + shape, p["P"], p["W"], p["vt"], p["faces"])
    path = os.path.join(OUT, man.id + ".glb")
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(path), export_format="GLB", export_skins=True,
                              export_animations=False, export_apply=False, export_yup=True, export_normals=True,
                              export_texcoords=True, export_materials="NONE")
    man.report["triangles"] = tris
    man.report["triangles_total"] = sum(tris.values())
    man.tick("export", t0)
    print("wrote", path, tris)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    only = next((a.split("=", 1)[1] for a in args if a.startswith("--only=")), None)
    env = json.load(open(ENVELOPE))
    men = json.load(open(SPEC))["men"]
    for mid, spec in men.items():
        if only and mid != only:
            continue
        t0 = time.time()
        man = Man(mid, spec, env)
        man.run()
        man.skin_texture(os.path.join(OUT, "%s_skin.png" % mid))
        for shape, p in man.proxies.items():
            man.garment_texture(shape, p, os.path.join(OUT, "%s_%s.png" % (mid, shape)))
        if "--no-export" not in args:
            export(man)
        man.report["timings_s"] = man.timings
        man.report["total_s"] = round(time.time() - t0, 1)
        json.dump(man.report, open(os.path.join(OUT, mid + ".json"), "w"), indent=1)
        print(mid, "done in", man.report["total_s"], "s", man.timings)


if __name__ == "__main__":
    main()
