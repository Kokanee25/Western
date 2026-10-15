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
WRIST_OVERLAP = 0.025  # metres up his forearm: the new palm runs over his arm's cut edge
STRAY = 0.02       # metres off its bone: a point that far isn't that finger's
TIP_LENGTH = 0.25  # ... and the last bone's length (joint 3 to its tip) taken this far past joint 4
FINGERS = ["thumb", "index", "middle", "ring", "little"]
_cache = {}
PAINT_PX = 512      # his hand's paint, a side (a hand's texture in his skin's)
AO_RAYS = 24
AO_REACH = 0.03     # metres: what shades a point (a finger beside it, the palm under the thumb)


def _base():
    if "base" not in _cache:
        v, uv, groups = mp.load_obj(os.path.join(mp.MH, "3dobjs/base.obj"))
        j = {}
        for side in "rl":
            for name in ("elbow", "hand"):
                j[side + "-" + name] = mp.joint(v, groups, side + "-" + name)
            for f in range(1, 6):
                for k in range(1, 5):
                    key = "%s-finger-%d-%d" % (side, f, k)
                    j[key] = mp.joint(v, groups, key)
        body = groups["body"]
        _cache["base"] = (mp.to_body_space(v), {k: mp.to_body_space(p) for k, p in j.items()}, body, uv)
    return _cache["base"]


def _corners(faces, keep):
    """The kept faces as triangles of (vertex, uv) corners: [n, 3, 2]."""
    out = []
    for fv, ft in faces:
        if all(keep[i] for i in fv):
            c = list(zip(fv, ft))
            out += [[c[0], c[k], c[k + 1]] for k in range(1, len(c) - 1)]
    return np.array(out, np.int64).reshape(-1, 3, 2)


def hand(side):
    """MakeHuman's hand: its points, triangles (indices into the points), each point's part
    (-1 the palm, else finger * 3 + bone: finger 0 the thumb .. 4 the little; bone 0..2), its
    joints and each point's UV in MakeHuman's layout."""
    v, j, faces, uvs = _base()
    wrist, elbow = j[side + "-hand"], j[side + "-elbow"]
    knuckle = j[side + "-finger-3-1"]
    d_hand, t_hand = mp.seg_dist(v, wrist, knuckle)
    d_arm, _t = mp.seg_dist(v, elbow, wrist)
    u = (knuckle - wrist) / np.linalg.norm(knuckle - wrist)
    # Straight across his forearm WRIST_OVERLAP above the wrist (a ragged top edge showed as a
    # rim once wrapped onto his arm), within a hand's reach of its line.
    reach, _t = mp.seg_dist(v, wrist - u * WRIST_OVERLAP, knuckle + (knuckle - wrist) * 1.1)   # to his fingertips
    t1, t4 = j[side + "-finger-1-1"], j[side + "-finger-1-4"]
    thumb, _t = mp.seg_dist(v, t1, t4 + (t4 - j[side + "-finger-1-3"]) * 0.8)   # and his thumb's
    near = ((v - wrist) @ u > -WRIST_OVERLAP) & ((reach < 0.06) | (thumb < 0.03))
    keep = np.zeros(len(v), bool)
    used = set(i for fv, _ft in faces for i in fv)
    keep[list(used)] = True
    keep &= near
    corners = _corners(faces, keep)
    # One point a (vertex, uv) pair: split where MakeHuman's UV layout is cut, so his hand keeps
    # it (the hand is painted in it, paint()).
    pairs, inv = np.unique(corners.reshape(-1, 2), axis=0, return_inverse=True)
    tris = inv.reshape(-1, 3)
    p = v[pairs[:, 0]]
    uv = uvs[pairs[:, 1]]
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
    return p, tris, part, joints, uv


def _frame(wrist, knuckle, across):
    u = knuckle - wrist
    length = float(np.linalg.norm(u))
    u = u / length
    b = across - (across @ u) * u
    width = float(np.linalg.norm(across))
    b /= np.linalg.norm(b)
    return np.array([u, b, np.cross(u, b)]), length, width


def place(side, ours, fingers_env):
    """MakeHuman's hand on the game's, in the game's rest pose: the palm (points, triangles, UVs,
    parts) and {finger id: [(points, triangles, UVs, parts)] x 3}. `ours`: the game's joints (fit_tripo's
    our_joints); `fingers_env`: envelope.json's fingers (knuckle a, tip b)."""
    p, tris, part, j, uv = hand(side)
    mw, mk = j[side + "-hand"], j[side + "-finger-3-1"]
    m_across = j[side + "-finger-5-1"] - j[side + "-finger-2-1"]
    gw, gk = np.array(ours[side + "-hand"]), np.array(ours[side + "-knuckle"])
    g_across = np.array(fingers_env["little_" + side]["a"]) - np.array(fingers_env["index_" + side]["a"])
    Fm, lm, wm = _frame(mw, mk, m_across)
    Fg, lg, wg = _frame(gw, gk, g_across)
    S = np.diag([lg / lm, wg / wm, wg / wm])        # along; across and through as wide
    A0 = Fg.T @ S @ Fm
    # Then fitted so his knuckles land on the game's exactly (the fingers turn about them; off
    # them, each finger's base stood off the palm): an affine through the wrist and the five
    # knuckles, the hand's thickness held by two points off the palm either side.
    src = [mw] + [j["%s-finger-%d-1" % (side, f)] for f in range(1, 6)]
    dst = [gw] + [np.array(fingers_env["%s_%s" % (n, side)]["a"]) for n in FINGERS]
    nm, ng = Fm[2] * 0.02, (A0 @ Fm[2]) * 0.02
    for k in range(2, 4):
        src += [j["%s-finger-%d-1" % (side, k)] + nm, j["%s-finger-%d-1" % (side, k)] - nm]
        g0 = np.array(fingers_env["%s_%s" % (FINGERS[k - 1], side)]["a"])
        dst += [g0 + ng, g0 - ng]
    X = np.c_[np.array(src), np.ones(len(src))]
    M, *_ = np.linalg.lstsq(X, np.array(dst), rcond=None)

    def affine(q):
        return np.c_[q, np.ones(len(q))] @ M if q.ndim == 2 else np.r_[q, 1.0] @ M

    q = affine(p)
    # Every triangle to one part: the part most of its corners are in, else its first corner's
    # (a triangle across three parts went to none and left a hole).
    pt = part[tris]
    tri_part = np.where((pt[:, 0] == pt[:, 1]) | (pt[:, 0] == pt[:, 2]), pt[:, 0], np.where(pt[:, 1] == pt[:, 2], pt[:, 1], pt[:, 0]))
    palm_tris = tris[tri_part == -1]
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
            sel = tris[tri_part == f * 3 + bone]
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
            pieces.append((pts, tt, uv[used], part[used]))
            start = start + dirn * la * SHARES[bone]
        fingers[fid] = pieces
    used = np.unique(palm_tris)
    remap = -np.ones(len(q), np.int64)
    remap[used] = np.arange(len(used))
    return (q[used], remap[palm_tris], uv[used], part[used]), fingers


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


def paint(palm, fingers, side, base, size=PAINT_PX, seed=7):
    """His hand painted in his own skin: an image (size x size, 0..1), and the palm and the
    fingers' pieces again ((points, triangles, UV in the image 0..1), each triangle its own
    corners) laid out in it.

    - His hand's colour (`base`, the median of his own hand's paint) with a soft painterly
      variation (the bold cowboy's paintings are brushwork, not flat colour);
    - shadow baked in from the hand's own shape (how much of the sky each point sees, within
      AO_REACH): dark between the fingers, in the creases at the joints, under the thumb;
    - the palm lighter and pinker, the backs of the fingers' last bones a pale nail with a darker rim.
    Hand-painted rules after how painters lay in a hand (no texture copied from anywhere).
    """
    import sys
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    from scipy import ndimage
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "characters"))
    import portrait as P
    pieces = [palm] + [pc for name in FINGERS for pc in fingers["%s_%s" % (name, side)]]
    pts, tris, uvs, parts, n0 = [], [], [], [], 0
    for q, t, u, pa in pieces:
        pts.append(q)
        tris.append(t + n0)
        uvs.append(u)
        parts.append(pa)
        n0 += len(q)
    pts, tris, uvs, parts = np.vstack(pts), np.vstack(tris), np.vstack(uvs), np.concatenate(parts)
    # Normals, the same at a place however many points sit there (the layout's seams).
    _u, weld = np.unique(np.round(pts / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    weld = weld.ravel()
    fn = np.cross(pts[tris[:, 1]] - pts[tris[:, 0]], pts[tris[:, 2]] - pts[tris[:, 0]])
    nw = np.zeros((weld.max() + 1, 3))
    for k in range(3):
        np.add.at(nw, weld[tris[:, k]], fn)
    nrm = nw[weld]
    nrm /= np.linalg.norm(nrm, axis=1, keepdims=True) + 1e-12
    # Ambient occlusion: AO_RAYS rays over each point's half of the sky.
    bvh = BVHTree.FromPolygons([tuple(p) for p in pts], [tuple(int(i) for i in t) for t in tris])
    rng = np.random.default_rng(seed)
    dirs = rng.normal(size=(AO_RAYS, 3))
    dirs /= np.linalg.norm(dirs, axis=1, keepdims=True)
    ao = np.zeros(len(pts))
    for i in range(len(pts)):
        n = nrm[i]
        d = np.where((dirs @ n)[:, None] < 0, -dirs, dirs)
        o = Vector(pts[i] + n * 0.0015)
        hit = sum(bvh.ray_cast(o, Vector(x), AO_REACH)[0] is not None for x in d)
        ao[i] = 1.0 - hit / AO_RAYS
    # Which way each point faces: towards his body's middle is his palm.
    palm_dir = np.array([-1.0, 0, 0]) if side == "r" else np.array([1.0, 0, 0])
    palmness = np.clip((nrm @ palm_dir - 0.2) / 0.6, 0, 1)
    # Nails: the backs of the last bones, their outer half.
    nail = np.zeros(len(pts))
    for f in range(5):
        m = parts == f * 3 + 2
        if not m.any():
            continue
        q = pts[m]
        axis = q.mean(0) - pts[parts == f * 3 + 1].mean(0) if (parts == f * 3 + 1).any() else np.array([0, -1.0, 0])
        axis /= np.linalg.norm(axis)
        t = (q - q.mean(0)) @ axis
        back = np.clip((nrm[m] @ -palm_dir - 0.35) / 0.4, 0, 1)
        nail[m] = back * np.clip((t / max(np.ptp(t), 1e-6) + 0.1) * 3.0, 0, 1)
    # The hand's own part of MakeHuman's layout (a few wrist points belong to the forearm's,
    # far off: they're clamped to its edge, not let stretch the frame).
    # His hand's own layout (MakeHuman's runs the hand into the forearm's patch, small and
    # stretched): every triangle its own corners; the palm side and the back of the hand
    # flattened into the top two squares, each finger bone unrolled round its own axis into a cell
    # of the bottom half (five fingers across, three bones down).
    owner = np.concatenate([np.full(len(pc[1]), k) for k, pc in enumerate(pieces)])
    corner = tris.reshape(-1)
    cu = np.zeros((len(corner), 2))
    u_al = pts[parts >= 0].mean(0) - pts[parts == -1].mean(0)
    u_al /= np.linalg.norm(u_al)
    across = np.cross(u_al, palm_dir)
    for k in range(len(pieces)):
        tk = np.nonzero(owner == k)[0]
        cs = (tk[:, None] * 3 + np.arange(3)).reshape(-1)
        q = pts[corner[cs]]
        if k == 0:
            front = (nrm[tris[tk]].mean(1) @ palm_dir) >= 0
            for side_k, sel in ((0, front), (1, ~front)):
                cc = (tk[sel][:, None] * 3 + np.arange(3)).reshape(-1)
                qq = pts[corner[cc]]
                a, b = qq @ u_al, qq @ across
                a = (a - a.min()) / max(np.ptp(a), 1e-6)
                b = (b - b.min()) / max(np.ptp(b), 1e-6)
                cu[cc] = np.c_[0.5 * side_k + 0.02 + 0.46 * b, 0.02 + 0.46 * a]
            continue
        f, bone = (k - 1) // 3, (k - 1) % 3
        c = q.mean(0)
        _s, _v, vt = np.linalg.svd(q - c, full_matrices=False)
        ax = vt[0] if vt[0] @ u_al > 0 else -vt[0]
        ref = palm_dir - (palm_dir @ ax) * ax
        ref /= np.linalg.norm(ref) + 1e-12
        ref2 = np.cross(ax, ref)
        d = q - c
        th = np.arctan2(d @ ref2, d @ ref)            # 0 on the palm side, the seam on the back
        th = th.reshape(-1, 3)
        wrap = np.ptp(th, axis=1) > np.pi            # a triangle across the seam: one side round
        th[wrap] = np.where(th[wrap] < 0, th[wrap] + 2 * np.pi, th[wrap])
        th = th.reshape(-1)
        x = (th + np.pi) / (2.5 * np.pi)             # 0 .. 1 (with the wrapped ones)
        t = d @ ax
        y = (t - t.min()) / max(np.ptp(t), 1e-6)
        cx, cy = 0.2 * f, 0.5 + bone * (0.5 / 3)
        cu[cs] = np.c_[cx + 0.01 + 0.18 * x, cy + 0.01 + (0.5 / 3 - 0.02) * y]
    tris_c = np.arange(len(corner)).reshape(-1, 3)
    pts_c = pts[corner]
    table = {tuple(int(i) for i in t): [tuple(cu[i]) for i in t] for t in tris_c}
    vals = np.c_[ao, palmness, nail][corner]
    M, cover = P.raster_uv(table, [list(map(int, t)) for t in tris_c], vals, size)
    _d, (iy, ix) = ndimage.distance_transform_edt(~cover, return_indices=True)
    M = M[iy, ix]
    ao_t, palm_t, nail_t = M[..., 0], M[..., 1], ndimage.gaussian_filter(M[..., 2], 1.0)
    base = np.asarray(base, float)
    # Brushwork: low-frequency light and warm/cool shifts, a little finer grain.
    noise = lambda s: ndimage.zoom(rng.normal(size=(s, s)), size / s, order=3)[:size, :size]
    light = 1.0 + 0.07 * noise(6) + 0.03 * noise(24)
    warm = 0.03 * noise(8)
    col = base[None, None] * light[..., None]
    col[..., 0] *= 1 + warm
    col[..., 2] *= 1 - warm
    pink = np.array([1.08, 0.98, 0.95])
    col = col * (1 - 0.35 * palm_t[..., None]) + (col * 1.12 * pink) * (0.35 * palm_t[..., None])
    col *= (0.45 + 0.55 * np.clip(ao_t, 0, 1) ** 0.8)[..., None]
    nail_col = np.clip(base * 1.3 + 0.08, 0, 1) * np.array([1.0, 0.92, 0.88])
    rim = np.clip(nail_t * (1 - nail_t) * 4 - 0.5, 0, 1)
    col = col * (1 - nail_t[..., None]) + nail_col * nail_t[..., None]
    col *= (1 - 0.25 * rim)[..., None]
    # The pieces again, each triangle its own corners, with their place in this paint (0..1).
    out, n0 = [], 0
    for k, pc in enumerate(pieces):
        nt = len(pc[1])
        sl = slice(n0 * 3, (n0 + nt) * 3)
        out.append((pts_c[sl], np.arange(nt * 3).reshape(-1, 3), cu[sl]))
        n0 += nt
    palm_out = out[0]
    fingers_out = {}
    for f, name in enumerate(FINGERS):
        fingers_out["%s_%s" % (name, side)] = out[1 + 3 * f: 4 + 3 * f]
    return np.clip(col, 0, 1), palm_out, fingers_out
