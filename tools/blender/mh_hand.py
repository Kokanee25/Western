"""MakeHuman's hand (CC0) for a fitted man: its palm in place of his, its fingers as the game's
finger pieces (Sean, 2026-10-15, the hands: "you do what you think will work best").

His own fingers (tools/blender/fingers.py) came out in shards: Rodin models the whole man at one
density (100-180 points a finger), half-curled, and his hand nearly twice the game's width.
MakeHuman's base mesh has a proper hand, fingers straight, every finger joint marked
(r-finger-<f>-<k>: f 1 the thumb to 5 the little finger; k 1 the knuckle, 2 and 3 the finger's
joints, 4 its last bone's end), and it's
CC0 and already in the people pipeline (make_people.py, build/makehuman).

- The hand: the base mesh's points nearer his hand's line (wrist to the middle finger's knuckle)
  than his forearm's, past his wrist; each point a finger bone's if it's nearer that bone's line
  than the palm's (make_people.cut_fingers' test), else the palm's.
- Placed: one affine move takes MakeHuman's wrist, knuckle line and palm onto the game's (his wrist
  to knuckle along, his index to little knuckle across, the palm's thickness with the width);
  then each finger bone's piece turned about its start the least way onto the game's bone and
  scaled to its length (HumanBody._build_hand: the anatomy's knuckle to tip, bones 0.42, 0.33,
  0.25 of it).
- His skin's look: each point takes the UV of the nearest point of his own hand, so the palm and
  fingers are painted in his skin (the game draws them in his skin's material).
"""
import os

import numpy as np

import make_people as mp

SHARES = (0.42, 0.33, 0.25)
TIP = 0.6          # past joint 4 (the last bone's end) by this much of that bone: the fingertip's points
WRIST_OVERLAP = 0.012  # metres up his forearm: the new palm tucks into his wrist, no gap
STRAY = 0.02       # metres off its bone: a point that far isn't that finger's
TIP_LENGTH = 0.25  # ... and the last bone's length (joint 3 to its tip) taken this far past joint 4
FINGERS = ["thumb", "index", "middle", "ring", "little"]
_cache = {}


def _base():
    if "base" not in _cache:
        v, _uv, groups = mp.load_obj(os.path.join(mp.MH, "3dobjs/base.obj"))
        j = {}
        for side in "rl":
            for name in ("elbow", "hand"):
                j[side + "-" + name] = mp.joint(v, groups, side + "-" + name)
            for f in range(1, 6):
                for k in range(1, 5):
                    key = "%s-finger-%d-%d" % (side, f, k)
                    j[key] = mp.joint(v, groups, key)
        body = groups["body"]
        _cache["base"] = (mp.to_body_space(v), {k: mp.to_body_space(p) for k, p in j.items()}, body)
    return _cache["base"]


def _tris(faces, keep):
    out = []
    for fv, _ft in faces:
        if all(keep[i] for i in fv):
            out += [[fv[0], fv[k], fv[k + 1]] for k in range(1, len(fv) - 1)]
    return np.array(out, np.int64).reshape(-1, 3)


def hand(side):
    """MakeHuman's hand: its points, triangles (indices into the points), and each point's part:
    -1 the palm, else finger * 3 + bone (finger 0 the thumb .. 4 the little; bone 0..2)."""
    v, j, faces = _base()
    wrist, elbow = j[side + "-hand"], j[side + "-elbow"]
    knuckle = j[side + "-finger-3-1"]
    d_hand, t_hand = mp.seg_dist(v, wrist, knuckle)
    d_arm, _t = mp.seg_dist(v, elbow, wrist)
    u = (knuckle - wrist) / np.linalg.norm(knuckle - wrist)
    near = (d_hand < d_arm * 1.6) & ((v - wrist) @ u > -WRIST_OVERLAP) & (d_hand < 0.6)
    keep = np.zeros(len(v), bool)
    used = set(i for fv, _ft in faces for i in fv)
    keep[list(used)] = True
    keep &= near
    tris = _tris(faces, keep)
    ids = np.unique(tris)
    remap = -np.ones(len(v), np.int64)
    remap[ids] = np.arange(len(ids))
    p = v[ids]
    palm_d = np.full(len(p), np.inf)
    best = np.full(len(p), np.inf)
    part = -np.ones(len(p), np.int64)
    for f in range(1, 6):
        k1, k2, k3, k4 = [j["%s-finger-%d-%d" % (side, f, k)] for k in range(1, 5)]
        tip = k4 + (k4 - k3) * TIP
        palm_d = np.minimum(palm_d, mp.seg_dist(p, wrist, k1)[0])
        for bone, (a, b) in enumerate(((k1, k2), (k2, k3), (k3, tip))):
            d, t = mp.seg_dist(p, a, b)
            if bone == 0:
                d = np.where(t < 0.12, np.inf, d)       # a little past the knuckle before it counts
            closer = d < best
            best[closer] = d[closer]
            part[closer] = (f - 1) * 3 + bone
    part[best >= palm_d] = -1
    joints = {k: v for k, v in j.items() if k.startswith(side + "-")}
    return p, remap[tris], part, joints


def _frame(wrist, knuckle, across):
    u = knuckle - wrist
    length = float(np.linalg.norm(u))
    u = u / length
    b = across - (across @ u) * u
    width = float(np.linalg.norm(across))
    b /= np.linalg.norm(b)
    return np.array([u, b, np.cross(u, b)]), length, width


def place(side, ours, fingers_env):
    """MakeHuman's hand on the game's: (palm points, palm triangles, {finger id: [(points,
    triangles)] x 3}) in the game's rest pose. `ours`: the game's joints (fit_tripo's
    our_joints); `fingers_env`: envelope.json's fingers (knuckle a, tip b)."""
    p, tris, part, j = hand(side)
    mw, mk = j[side + "-hand"], j[side + "-finger-3-1"]
    m_across = j[side + "-finger-5-1"] - j[side + "-finger-2-1"]
    gw, gk = np.array(ours[side + "-hand"]), np.array(ours[side + "-knuckle"])
    g_across = np.array(fingers_env["little_" + side]["a"]) - np.array(fingers_env["index_" + side]["a"])
    Fm, lm, wm = _frame(mw, mk, m_across)
    Fg, lg, wg = _frame(gw, gk, g_across)
    S = np.diag([lg / lm, wg / wm, wg / wm])        # along; across and through as wide
    A = Fg.T @ S @ Fm

    def affine(q):
        return gw + (q - mw) @ A.T

    q = affine(p)
    palm_tris = tris[(part[tris] == -1).sum(1) >= 2]
    fingers = {}
    for f, name in enumerate(FINGERS):
        fid = "%s_%s" % (name, side)
        a, b = np.array(fingers_env[fid]["a"]), np.array(fingers_env[fid]["b"])
        la = float(np.linalg.norm(b - a))
        dirn = (b - a) / la
        ks = [affine(j["%s-finger-%d-%d" % (side, f + 1, k)]) for k in (1, 2, 3, 4)]
        ks[3] = ks[3] + (ks[3] - ks[2]) * TIP_LENGTH
        # His finger as thick as MakeHuman's for its length; each piece as long as its slot.
        thick = la / sum(float(np.linalg.norm(ks[k + 1] - ks[k])) for k in range(3))
        start = a
        pieces = []
        for bone in range(3):
            s0, e0 = ks[bone], ks[bone + 1]
            u = (e0 - s0) / np.linalg.norm(e0 - s0)
            R = _turn(u, dirn)
            sel = tris[(part[tris] == f * 3 + bone).sum(1) >= 2]
            used = np.unique(sel)
            remap = -np.ones(len(q), np.int64)
            remap[used] = np.arange(len(used))
            # Each piece to its slot on the bone (MakeHuman's bones aren't the game's shares):
            # stretched along the bone, as thick as the whole finger's scale makes it.
            along = la * SHARES[bone] / max(float(np.linalg.norm(e0 - s0)), 1e-6)
            r = (q[used] - s0) @ R.T
            t = r @ dirn
            pts = start + dirn * (t * along)[:, None] + (r - t[:, None] * dirn) * thick
            # A stray (a point classed by its nearest bone but lying off it) goes.
            end = start + dirn * la * SHARES[bone]
            off = mp.seg_dist(pts, start, end)[0] > STRAY
            tt = remap[sel]
            tt = tt[~off[tt].any(1)]
            pieces.append((pts, tt))
            start = start + dirn * la * SHARES[bone]
        fingers[fid] = pieces
    used = np.unique(palm_tris)
    remap = -np.ones(len(q), np.int64)
    remap[used] = np.arange(len(used))
    return q[used], remap[palm_tris], fingers


def _turn(u, w):
    """The least rotation taking unit u to unit w (Rodrigues)."""
    c = float(u @ w)
    ax = np.cross(u, w)
    s = float(np.linalg.norm(ax))
    if s < 1e-9:
        return np.eye(3) if c > 0 else -np.eye(3)
    ax /= s
    K = np.array([[0, -ax[2], ax[1]], [ax[2], 0, -ax[0]], [-ax[1], ax[0], 0]])
    return np.eye(3) + s * K + (1 - c) * K @ K
