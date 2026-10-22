#!/usr/bin/env python3
"""Hands with fingers for a Character Studio man: his own Rodin hands (the fingers fused, a
mitten) cut off at the wrist and MakeHuman's hand put on in their place, skinned to the game's
15 finger bones a hand, so his fingers bend in the skin: curl, grip, hold the gun, play the piano,
and come off when shot (Sean, 2026-10-22: "hands giving them bones so they can grab things and
play the piano and shoot guns").

    ~/.venvs/studio/bin/python tools/faces/hands.py --man=sean_s3_talking

The work is the layered cowboy's skinned hands (tools/blender/fit_tripo.py TripoPerson.skinned_hands,
docs/briefs/skinned-hands.md), run on a whole Studio man: his skin read from his model (its parts
from its strongest bone), the hand fitted, cut and stitched at his wrist, painted into free squares
of his skin's texture, weighted to the finger bones. → assets/people/<man>.glb (his skin with the
new hands and the 30 finger bones in its skeleton), <man>_skin.png (his skin's texture with the
hands painted in; a talking man's skin had been his source's), <man>.json `finger_bones` and
`own_fingers`. Run from the game's root (MakeHuman under build/makehuman: fetch_makehuman.py).
"""
import json
import os
import sys
import types

import numpy as np
from PIL import Image
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
from glb_io import Glb  # noqa: E402
import fit_tripo as FT  # noqa: E402
import make_people as mp  # noqa: E402

PEOPLE = os.path.join(ROOT, "assets", "people")


def quat_mat(q):
    x, y, z, w = q
    return np.array([[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
                     [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
                     [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def local_matrix(n):
    M = np.eye(4)
    if "matrix" in n:
        return np.array(n["matrix"]).reshape(4, 4).T
    R = quat_mat(n.get("rotation", [0, 0, 0, 1])) * np.array(n.get("scale", [1, 1, 1]))
    M[:3, :3] = R
    M[:3, 3] = n.get("translation", [0, 0, 0])
    return M


def world_of(g, i):
    """A node's world matrix (its parents' walked up)."""
    parent = {c: p for p, n in enumerate(g.g["nodes"]) for c in n.get("children", [])}
    M = local_matrix(g.g["nodes"][i])
    while i in parent:
        i = parent[i]
        M = local_matrix(g.g["nodes"][i]) @ M
    return M


def add_finger_joints(g, rests):
    """The 30 finger bones as joints of his skin: nodes under his hands (each its parent's
    child, knuckle to tip), their inverse binds. The game takes their rests from his report and
    only their names from here; the binds keep the file whole for any other reader."""
    sk = g.g["skins"][0]
    names = [g.g["nodes"][j]["name"] for j in sk["joints"]]
    ibm = list(g.accessor(sk["inverseBindMatrices"]).astype(np.float32))
    for name, (origin, basis) in rests.items():
        side, k = name.split("_")[2], int(name.split("_")[3])
        parent_name = "hand_" + side if k == 0 else name[:-1] + str(k - 1)
        pi = sk["joints"][names.index(parent_name)]
        world = np.eye(4)
        world[:3, :3] = np.asarray(basis).T
        world[:3, 3] = origin
        local = np.linalg.inv(world_of(g, pi)) @ world
        g.g["nodes"].append({"name": name, "matrix": local.T.reshape(-1).tolist()})
        ni = len(g.g["nodes"]) - 1
        g.g["nodes"][pi].setdefault("children", []).append(ni)
        sk["joints"].append(ni)
        names.append(name)
        ibm.append(np.linalg.inv(world).T.reshape(-1).astype(np.float32))
    sk["inverseBindMatrices"] = g._add(np.array(ibm, np.float32), 5126, "MAT4")
    return names


def his_skin(m, colour):
    """His skin's colour and grain from his own (Rodin's) hands, before they're cut: where his
    forearm by the wrist is a sleeve (a white shirt, a black jacket), the new hands would take its
    colour. Then that band of his texture, in a copy fit_tripo reads (m.colour), is his skin's,
    so the hands are painted from it; his own texture is untouched."""
    tex = np.asarray(colour, np.float64)
    hh, ww = tex.shape[:2]
    at = lambda uv: tex[np.clip((uv[:, 1] * hh).astype(int), 0, hh - 1), np.clip((uv[:, 0] * ww).astype(int), 0, ww - 1)]
    o = m.our_joints()
    hands = np.isin(m.region, ["hand_r", "hand_l"])
    own = at(m.uv[hands])
    rgb = np.median(own, 0)
    grain = float(np.std(own.mean(1) - np.median(own.mean(1))))
    band = []
    for side in "rl":
        wr, el = o[side + "-hand"], o[side + "-elbow"]
        ax = (wr - el) / np.linalg.norm(wr - el)
        up = (m.v - wr) @ ax
        band.append(np.nonzero((m.region == "forearm_" + side) & (up > -0.10) & (up < 0.0))[0])
    band = np.concatenate(band)
    arm = np.median(at(m.uv[band]), 0)
    sleeved = bool(np.linalg.norm(arm - rgb) > 45)
    if sleeved:
        t = tex.copy()
        uv = m.uv[band]
        t[np.clip((uv[:, 1] * hh).astype(int), 0, hh - 1), np.clip((uv[:, 0] * ww).astype(int), 0, ww - 1)] = rgb
        m.colour = Image.fromarray(t.astype(np.uint8))
    print("hands: his own hands' skin", rgb.round(), "his forearm by the wrist", arm.round(), "sleeved" if sleeved else "bare")
    return {"rgb": rgb, "grain": grain, "sleeved": sleeved}


def vertex_normals(V, T):
    N = np.zeros_like(V)
    fn = np.cross(V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]])
    for j in range(3):
        np.add.at(N, T[:, j], fn)
    return N / np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)


def build(man):
    path = os.path.join(PEOPLE, man + ".glb")
    info_p = os.path.join(PEOPLE, man + ".json")
    info = json.load(open(info_p))
    if info.get("finger_bones"):
        raise SystemExit("%s already has finger bones" % man)
    g = Glb(path)
    names = g.joint_names()
    s = g.mesh("body_skin")
    V, UV, T = s["V"].astype(np.float64), s["UV"].astype(np.float64), s["T"].astype(np.int64)
    W17 = np.zeros((len(V), len(names)))
    for k in range(4):
        np.add.at(W17, (np.arange(len(V)), s["J"][:, k].astype(int)), s["W"][:, k])
    src = info.get("textures_from", man)
    colour = Image.open(os.path.join(PEOPLE, src + "_skin.png")).convert("RGB")

    # His skin as fit_tripo's man: points, triangles, UVs, each point's part (its strongest bone).
    m = types.SimpleNamespace()
    m.id = m.model = man
    m.spec = {}
    m.report = {}
    m.colour = colour
    m.env = json.load(open(os.path.join(ROOT, mp.ENVELOPE)))
    m.v, m.v_tripo, m.uv, m.tris = V.copy(), V.copy(), UV.copy(), T.copy()
    m.region = np.array(names, dtype="<U16")[W17.argmax(1)]
    m.head = np.zeros(len(V), bool)
    m.our_joints = types.MethodType(mp.Person.our_joints, m)
    skin = his_skin(m, colour)
    for f in ("_stitch", "_free_squares"):
        setattr(m, f, types.MethodType(getattr(FT.TripoPerson, f), m))
    FT.TripoPerson.skinned_hands(m)

    # His weights for every point after the cut: each its nearest old point's (the arm, tapered
    # a little), the new hands their hand's bone (finger_weights then eases the wrist and adds
    # the fingers').
    W = W17[cKDTree(V).query(m.v)[1]]
    for n0, fw, side in m.hand_fw:
        W[n0:n0 + len(fw)] = 0
        W[n0:n0 + len(fw), names.index("hand_" + side)] = 1
    m.W = W
    FT.TripoPerson.finger_weights(m)

    # Into his model: the finger bones in the skeleton, his skin with the hands, top four
    # weights a point.
    order = add_finger_joints(g, m.finger_rests)
    assert order[len(names):] == m.extra_bones, "finger bone order"
    top = np.argsort(-m.W, axis=1)[:, :4]
    wt = np.take_along_axis(m.W, top, 1)
    wt /= np.maximum(wt.sum(1, keepdims=True), 1e-9)
    N_old = s["N"] if "N" in s else None
    N = vertex_normals(m.v, m.tris)
    if N_old is not None:
        d, k = cKDTree(V).query(m.v)
        keep = d < 1e-6
        N[keep] = N_old[k[keep]]
    g.set_mesh("body_skin", m.v, N, m.uv, top, wt, m.tris)
    g.save(path)
    # His forearm's colour and grain by the wrist (the texels its points sit on): the hands'
    # paint, MakeHuman's lit pink, came out pinker, lighter and smoother than his arm.
    tex = np.asarray(colour, np.float64)
    hh, ww = tex.shape[:2]
    arm_rows = []
    o = m.our_joints()
    for side in "rl":
        wr, el = o[side + "-hand"], o[side + "-elbow"]
        ax = (wr - el) / np.linalg.norm(wr - el)
        up = (m.v - wr) @ ax
        arm_rows.append(np.nonzero((m.region == "forearm_" + side) & (up > -0.10) & (up < -0.02))[0])
    uv = m.uv[np.concatenate(arm_rows)]
    px_arm = tex[np.clip((uv[:, 1] * hh).astype(int), 0, hh - 1), np.clip((uv[:, 0] * ww).astype(int), 0, ww - 1)]
    arm_med = np.median(px_arm, 0)
    grain = float(np.std(px_arm.mean(1) - np.median(px_arm.mean(1))))
    if skin["sleeved"]:
        arm_med, grain = skin["rgb"], skin["grain"]
    rng = np.random.default_rng(5)
    hand_rows = np.concatenate([np.arange(n0, n0 + len(fw)) for n0, fw, _sd in m.hand_fw])
    for paint, (u0, v0, side) in m.hand_paint:
        px = max(1, int(round(side * colour.width)))
        tile = np.asarray(Image.fromarray((np.clip(paint, 0, 1) * 255).astype(np.uint8)).resize((px, px), Image.LANCZOS), np.float64)
        # Its texels the hand's points sit on, for its own colour.
        hu = m.uv[hand_rows]
        inside = (hu[:, 0] >= u0) & (hu[:, 0] < u0 + side) & (hu[:, 1] >= v0) & (hu[:, 1] < v0 + side)
        tx = np.clip(((hu[inside, 0] - u0) / side * px).astype(int), 0, px - 1)
        ty = np.clip(((hu[inside, 1] - v0) / side * px).astype(int), 0, px - 1)
        gain = np.clip(arm_med / np.maximum(np.median(tile[ty, tx], 0), 1.0), 0.6, 1.4)
        tile = tile * gain
        # A fine grain as his arm's paint has (a little blurred: blotches, not noise).
        n = rng.normal(0, 1, (px // 3 + 1, px // 3 + 1))
        n = np.asarray(Image.fromarray(((n * 0.5 + 0.5).clip(0, 1) * 255).astype(np.uint8)).resize((px, px), Image.BICUBIC), np.float64) / 255 - 0.5
        tile = tile * (1 + n[..., None] * 2 * grain / max(arm_med.mean(), 1.0))
        tile = Image.fromarray(np.clip(tile, 0, 255).astype(np.uint8))
        colour = colour.copy()
        colour.paste(tile, (int(round(u0 * colour.width)), int(round(v0 * colour.height))))
    m.report["own_fingers"]["matched_to_arm"] = {"arm_rgb": [round(float(x)) for x in arm_med], "grain": round(grain, 1),
                                                  "from": "his own hand (his forearm is a sleeve)" if skin["sleeved"] else "his forearm"}
    colour.save(os.path.join(PEOPLE, man + "_skin.png"))
    info["finger_bones"] = m.report["finger_bones"]
    info["own_fingers"] = m.report["own_fingers"]
    info["own_fingers"]["from"] = "makehuman, skinned (tools/faces/hands.py)"
    json.dump(info, open(info_p, "w"), indent=1)
    print("hands:", man, json.dumps({k: v for k, v in m.report["own_fingers"].items() if k != "from"}))


if __name__ == "__main__":
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    os.chdir(ROOT)
    build(a["--man"])
