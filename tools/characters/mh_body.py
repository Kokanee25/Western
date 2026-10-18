"""A base body from MakeHuman's base mesh (CC0), shaped by his targets and stood as his pictures
stand him, written where a Rodin base body goes so the rest of the layered chain takes it as is
(docs/briefs/garments.md, "His body under them": the Rodin body's guessed rig and its webs of skin
under the arms and between the thighs came through every garment laid on it).

    ~/bpyenv/bin/python tools/characters/mh_body.py --id=bold_cowboy_mh_body

His people.json entry's `mh` block: `targets` {MakeHuman target: weight} (fetched by
tools/blender/fetch_makehuman.py) and `arms` (degrees from vertical his arms hang at: his
pictures', so projection lines them up). MakeHuman's own skeleton and skin weights (its default
rig, CC0) lower his arms from the base mesh's 43 degrees: each point turns about its shoulder by
its share of the upper arm's chain, so his armpit bends as MakeHuman's own posing bends it.
→ assets/people/tripo/<entry rodin>.glb (the base mesh's body faces and UVs, in a Rodin glb's
own frame: facing +Z, his right -X; fit_tripo.load_rodin turns it) for body_paint.py,
garments.py and fit_tripo.py.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
import make_people as mp  # noqa: E402
import twin_pieces as TP  # noqa: E402

RIG = os.path.join(mp.MH, "rigs")
SKIN = (196, 140, 110)
ARM_SHARE = 0.5   # a point is his arm's when his upper arm's chain carries more than this of its weight
# fit_tripo.find_joints' names → MakeHuman's default rig's bones (each at its head joint).
JOINTS = {"{s}_Upperarm": "upperarm01.{s}", "{s}_Forearm": "lowerarm01.{s}", "{s}_Hand": "wrist.{s}",
          "{s}_Thigh": "upperleg01.{s}", "{s}_Calf": "lowerleg01.{s}", "{s}_Foot": "foot.{s}",
          "{s}_ToeBase": "toe1-1.{s}", "NeckTwist01": "neck01", "Head": "head"}     # a flat skin colour until body_paint.py paints him


def load_rig():
    skel = json.load(open(os.path.join(RIG, "default.mhskel")))
    weights = json.load(open(os.path.join(RIG, "default_weights.mhw")))["weights"]
    return skel, weights


def subtree(skel, top):
    """The bone `top` and every bone below it."""
    kids = {}
    for name, b in skel["bones"].items():
        kids.setdefault(b["parent"], []).append(name)
    out, todo = [], [top]
    while todo:
        b = todo.pop()
        out.append(b)
        todo += kids.get(b, [])
    return out


def joint_pos(v, skel, name):
    return v[np.asarray(skel["joints"][name], int)].mean(0)


def rotation(u, w):
    u, w = u / np.linalg.norm(u), w / np.linalg.norm(w)
    c = float(u @ w)
    ax = np.cross(u, w)
    s = float(np.linalg.norm(ax))
    if s < 1e-9:
        return np.eye(3)
    ax /= s
    K = np.array([[0, -ax[2], ax[1]], [ax[2], 0, -ax[0]], [-ax[1], ax[0], 0]])
    return np.eye(3) + s * K + (1 - c) * K @ K


def lower_arms(v, skel, weights, deg):
    """Each arm turned about its shoulder joint till shoulder-to-wrist hangs `deg` from vertical
    (out to his side, in the frontal plane), each point by its share of the arm chain's weights."""
    v = v.copy()
    for side, sx in (("L", 1.0), ("R", -1.0)):
        w = np.zeros(len(v))
        for b in subtree(skel, "upperarm01." + side):
            for idx, wt in weights.get(b, []):
                w[int(idx)] += float(wt)
        w = np.clip(w, 0.0, 1.0)
        s = joint_pos(v, skel, "upperarm01.%s____head" % side)
        h = joint_pos(v, skel, "wrist.%s____head" % side)
        want = np.array([sx * np.sin(np.radians(deg)), -np.cos(np.radians(deg)), 0.0])
        R = rotation(h - s, want)
        turned = (v - s) @ R.T + s
        v += w[:, None] * (turned - v)
    return v


# Our skeleton's joints as shares of the crown's height (assets/people/envelope.json through
# make_people.Person.our_joints: hips 0.90, knee 0.485, ankle 0.085, shoulder 1.43, neck 1.47 of
# a 1.795 m crown) and MakeHuman's joint for each.
OURS = {"upperleg01.L____head": 0.90, "lowerleg01.L____head": 0.485, "foot.L____head": 0.085,
        "upperarm01.L____head": 1.43}
# (Not the neck: ours sits 4 cm over the shoulder joints, MakeHuman's at his neck's base, and the
# fitter lays all of him above his shoulders on as one, his own neck's length kept.)
CROWN = 1.795


HEAD_SCALE = ["head/head-scale-vert", "head/head-scale-horiz", "head/head-scale-depth"]   # one dial, "-decr"/"-incr"


def chin_y(u, skel):
    """His chin's height: the frontmost of his face's midline under his mouth (MakeHuman faces +Z)."""
    head = joint_pos(u, skel, "head____head")
    mid = (np.abs(u[:, 0]) < 0.08) & (u[:, 1] < head[1] - 0.2) & (u[:, 1] > head[1] - 1.6) & (u[:, 2] > head[2])
    q = u[mid]
    front = q[:, 2].max()
    near = q[q[:, 2] > front - 0.25]
    return float(near[:, 1].min())


def fit_proportions(v, skel, pairs, head_share=None):
    """MakeHuman's measure targets (each pair "decr|incr", one signed dial) set so his joints
    stand at our skeleton's shares of his height (the fitter then stretches nothing: with
    MakeHuman's own longer legs and shorter trunk it stretched his trunk 16% and his upper back
    stood over his shoulders in a hump, 2026-10-18). Least squares over the dials, each -1..1."""
    from scipy.optimize import minimize
    deltas = []
    for pair in pairs:
        lo, hi = pair.split("|")
        d = []
        for t in (lo, hi):
            dv = np.zeros_like(v)
            mp.apply_target(dv, os.path.join(mp.MH, "targets", t + ".target"), 1.0)
            d.append(dv)
        deltas.append(d)
    if head_share:
        d = []
        for end in ("-decr", "-incr"):
            dv = np.zeros_like(v)
            for t in HEAD_SCALE:
                mp.apply_target(dv, os.path.join(mp.MH, "targets", t + end + ".target"), 1.0)
            d.append(dv)
        deltas.append(d)
        pairs = list(pairs) + ["head|head-scale"]
    ground = v[:, 1].min()
    def shape(x):
        out = v.copy()
        for xi, (dlo, dhi) in zip(x, deltas):
            out += (dhi if xi > 0 else dlo) * abs(xi)
        return out
    def cost(x):
        u = shape(x)
        top = u[:, 1].max() - ground
        c = sum(((joint_pos(u, skel, j)[1] - ground) / top - share / CROWN) ** 2 for j, share in OURS.items())
        if head_share:
            c += 4.0 * ((u[:, 1].max() - chin_y(u, skel)) / top - head_share) ** 2
        return c
    res = minimize(cost, np.zeros(len(pairs)), bounds=[(-1, 1)] * len(pairs), method="L-BFGS-B")
    print("mh_body: proportions %s, error %.4f -> %.4f" % (
        ", ".join("%s %+.2f" % (p_.split("|")[1].rsplit("-", 1)[0].replace("measure/measure-", ""), x) for p_, x in zip(pairs, res.x)),
        np.sqrt(cost(np.zeros(len(pairs))) / len(OURS)), np.sqrt(res.fun / len(OURS))))
    u = shape(res.x)
    top = u[:, 1].max() - ground
    if head_share:
        print("mh_body: head %.3f of his height (pictures %.3f)" % ((u[:, 1].max() - chin_y(u, skel)) / top, head_share))
    print("mh_body: joints (his, ours)", ", ".join("%s %.3f/%.3f" % (j.split(".")[0].split("_")[0], (joint_pos(u, skel, j)[1] - ground) / top, sh / CROWN) for j, sh in OURS.items()))
    return u


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    pid = a["--id"]
    spec = json.load(open(os.path.join(ROOT, "assets", "people", "people.json")))["people"][pid]
    mh = spec["mh"]
    v, uvs, groups = mp.load_obj(os.path.join(mp.MH, "3dobjs/base.obj"))
    for t, wt in mh.get("targets", {}).items():
        mp.apply_target(v, os.path.join(mp.MH, "targets", t + ".target"), float(wt))
    skel, weights = load_rig()
    if mh.get("fit"):
        v = fit_proportions(v, skel, mh["fit"], mh.get("head"))
    v = lower_arms(v, skel, weights, float(mh.get("arms", 10.0)))
    # The body's faces, a vertex per (point, UV) so the glb's UVs are per vertex; quads split.
    pairs, tris = {}, []
    for vids, uvids in groups["body"]:
        ids = []
        for vi, ti in zip(vids, uvids):
            ids.append(pairs.setdefault((vi, ti), len(pairs)))
        for k in range(1, len(ids) - 1):
            tris.append([ids[0], ids[k], ids[k + 1]])
    keys = list(pairs)
    pos = np.array([v[vi] for vi, _ti in keys]) * 0.1          # MakeHuman's decimetres to metres
    pos[:, 1] -= pos[:, 1].min()
    uv = np.array([uvs[ti] for _vi, ti in keys], float)
    uv[:, 1] = 1.0 - uv[:, 1]                                   # obj's v up, the glb's down
    tris = np.array(tris, int)
    out, name = spec["rodin"].rsplit("_", 1)
    TP.write_piece(name, pos, uv, tris, Image.new("RGB", (64, 64), SKIN), pid, out)
    # His joints as fit_tripo.find_joints names them, in the frame load_rodin turns him into.
    y0 = float((v[:, 1] * 0.1).min())
    def to_frame(q):
        q = q * 0.1 - np.array([0.0, y0, 0.0])
        return np.stack([q[..., 2], q[..., 1], -q[..., 0]], -1)
    body = to_frame(np.array([v[vi] for vi, _ti in keys]))
    hy = body[:, 1].max() - body[:, 1].min()
    mid = np.array([(body[:, 0].min() + body[:, 0].max()) / 2, 0.0, (body[:, 2].min() + body[:, 2].max()) / 2])
    js = {}
    for ours, theirs in JOINTS.items():
        for side, s_ in (("R", "R"), ("L", "L")):
            if "{s}" in theirs or ours.startswith("{s}"):
                q = joint_pos(v, skel, theirs.replace("{s}", s_) + "____head")
                js[ours.replace("{s}", side)] = q
        if "{s}" not in theirs:
            js[ours] = joint_pos(v, skel, theirs + "____head")
    js["Hip"] = 0.5 * (js["R_Thigh"] + js["L_Thigh"])
    js = {k: ((to_frame(q) - np.array([0.0, body[:, 1].min(), 0.0])) / hy - mid / hy * np.array([1, 0, 1])).round(5).tolist()
          for k, q in js.items()}
    json.dump(js, open(os.path.join(TP.TRIPO, spec["rodin"] + "_joints.json"), "w"), indent=1)
    # Which of his points are arm (his upper arm's chain carries most of their weight), in the
    # same frame, for garments.py: its sleeves take these and the trunk the rest.
    w = np.zeros(len(v))
    for side_ in "LR":
        for b_ in subtree(skel, "upperarm01." + side_):
            for idx, wt in weights.get(b_, []):
                w[int(idx)] += float(wt)
    # (the body's own points only: MakeHuman's helper meshes (tights, skirt, joint cubes) share
    # the base mesh, carry other weights, and as nearest points they hid his arms)
    own = np.array(sorted({vi for vi, _ti in keys}))
    framed = (to_frame(v[own]) - np.array([0.0, body[:, 1].min(), 0.0])) / hy - mid / hy * np.array([1, 0, 1])
    np.savez_compressed(os.path.join(TP.TRIPO, spec["rodin"] + "_arms.npz"), v=framed.astype(np.float32),
                        arm=(w[own] > ARM_SHARE).astype(np.uint8))
    print("mh_body: %s %d points, %d triangles, %.2f m tall, arms at %s degrees" % (
        pid, len(pos), len(tris), pos[:, 1].max(), mh.get("arms", 10.0)))


if __name__ == "__main__":
    main()
