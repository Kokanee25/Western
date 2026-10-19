"""The whole man's head and neck (Sean, 2026-10-19: "his face for sure needs work", "his neck needs
work too, it looks off"): try A, the approved Oct 14 head given a chin, a neck and a smooth paint.

    ~/bpyenv/bin/python tools/characters/head_neck.py shape --head=bold_cowboy_rodin --out=bold_cowboy_whole_a
    ~/bpyenv/bin/python tools/characters/head_neck.py paint --man=bold_cowboy_whole_a
    ~/bpyenv/bin/python tools/characters/head_neck.py join --body=bold_cowboy_whole_body --man=bold_cowboy_whole_a \\
        --out=bold_cowboy_whole_a

1. shape: the kept game head (assets/people/heads/<head>_mesh.npz: V, T, UV per corner, MediaPipe
   `pts`, his eyes on the anatomy's). Measured against his front portrait (MediaPipe, in eye spans,
   left plus right so its small turn cancels), the Oct 14 head matches down to his lower lip but
   his chin is 1.1-1.3 cm short and his lower jaw a quarter narrow (CHIN_TARGET): those landmarks
   are moved to the portrait's and the head warped to them (a thin-plate spline, everything above
   his lower lip and behind his ears held). Then his ragged underside (the bust had no throat:
   flaps under the chin, a short torn nape) is cut along his jaw and a neck lofted from that edge:
   under his chin back to his throat, round his sides, and under his hair in to his nape (NECK),
   then straight down into his collar. The neck's own UVs go in the head atlas's empty corner.
   → assets/people/heads/<out>_mesh.npz (V, T, UV per corner, pts, `neck` per corner).
2. paint: rodin_portrait.paint on that mesh (portrait.json <out>: `mesh`), smooth (no squares,
   the portraits' squares blurred out, his eyes kept from the portrait), de-lit, his skin muted.
   → build/head_neck/<out>_paint.png.
3. join: the head on the fitted whole body (whole_man's chain), the body cut round his collar
   (lower in front, under his throat) and its edge stood round the new neck (COLLAR), his own hat.
   → assets/people/<out>.glb, _head.png, _skin.png, _hat*.png, .json.
"""
import json
import os
import shutil
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
PEOPLE = os.path.join(ROOT, "assets", "people")
HEADS = os.path.join(PEOPLE, "heads")
WORK = os.path.join(ROOT, "build", "head_neck")

# His front portrait's lower face, in eye spans from between his irises (half-widths, heights), the
# mean of both sides (docs/concept/style/portrait-cowboy-front.png, MediaPipe; the Oct 14 head in
# brackets). Only the jaw's lower half and chin differ: 136 (0.68, -1.38), 150 (0.59, -1.52),
# 149 (0.53, -1.58), 176 (0.44, -1.63), 148 (0.23, -1.66), 152 (0, -1.64).
CHIN_TARGET = {(136, 365): (0.89, -1.36), (150, 379): (0.75, -1.52), (149, 378): (0.61, -1.635),
               (176, 400): (0.45, -1.745), (148, 377): (0.25, -1.83), (152, 152): (0.0, -1.86)}
JAW_WIDTH_SHARE = 0.75   # how much of the portrait's wider jaw he takes (its outline has his sideburns in it)
HOLD_BEHIND = 0.0        # vertices behind this z (his ears, the back of his head) held still by the warp
HAIR_FROM_Z = (0.0, 0.025)  # his hair smoothed behind his ears: none in front of the first z, all behind the second
HAIR_SMOOTH = 12            # ... Taubin rounds

# The neck (metres, body space: y up, he faces -Z). An ellipse round NECK_CENTRE_Z, NECK_HALF_W
# across and NECK_HALF_D front to back (a solid man's neck, ~0.35 m round; at his collar 0.88 of
# his jaw's width, as his front portrait's 0.85); its nape ~3 cm in under the back of his skull,
# his throat ~4.5 cm behind his chin.
NECK_HALF_W = 0.052
NECK_HALF_D = 0.060
NECK_CENTRE_Z = 0.0
NECK_JOIN = (0.022, 0.03)   # metres under the jaw cut where the lofted neck becomes the tube: front, back
NECK_BOTTOM = 1.43           # the tube's open end, well down inside his collar
NECK_RINGS = 7               # rings in the loft
NECK_TUBE_RINGS = 5
NECK_AROUND = 72
CUT_FRONT = 0.004            # the jaw cut: this far under his chin in front ...
CUT_BACK = 1.552             # ... and this height at the back (over the torn nape)
JAW_BORDER = (0.002, 0.004) # the cut under his jaw: this far over his chin's bottom, and under his jaw's angles
JAW_SLOPE = 0.55             # ... rising this much a metre back from his chin
JAW_HALF_W = (0.050, 0.066)  # ... inside his jaw (all of it within the first of his middle, none past the second)
NECK_SKIN_TOL = 0.16         # paint: a neck texel this far from his neck's skin colour is collar or coat (made skin)
NECK_BLUR = 6.0              # ... the neck's paint smoothed over this many texels
NECK_EASE = 0.015            # ... and eased into the head's colour over this far down from the cut
NECK_LIFT = 0.012            # ... its colour from this far up the head plus its own distance down
EYE_R = 0.013                # paint: his eyes' whites lifted within this of each iris ...
EYE_WHITE = 0.35             # ... this much of the way to white
NECK_EASE_BACK = 0.045       # ... this far at his nape, where his hair comes down to his collar
NECK_BLEND = (0.02, 0.06)    # join: under his chin, all head above the first, all neck below (rodin_portrait_build)
# join: the body cut round his collar, a plane through these (z, y) points (front, back): his
# collar's front under his throat, its back up under his nape.
COLLAR_CUT = ((-0.11, 1.512), (0.09, 1.50))
COLLAR_STAND = 0.02         # metres under the cut stood round his neck as a band ...
COLLAR_EASE = 0.04           # ... eased back to the body as it was over this
COLLAR_CLEAR = 0.005         # ... this far outside the neck
COLLAR_REACH = (0.05, 0.08)  # ... all of what's within the first of that band, none past the second
COLLAR_LID = 0.012           # the lid inside his collar this far under its edge
COLLAR_WEIGHTS = 0.02        # the neck takes the body's weights fully this far under the collar's cut
# His shirt's collar (collar_band, his arms-out pictures' turned-down collar): the stand from
# BAND_TUCK under the body's cut up to BAND_TOP (front, back), open BAND_GAP degrees either side of
# his front, and the fall folded down over it.
BAND_TOP = (1.522, 1.538)   # his profile portrait: his chin's underside 0.2 of eye-to-chin over his collar
BAND_TUCK = 0.008
BAND_OUT = 0.006
BAND_GAP = 10.0
BAND_ROWS = 3
FALL = (0.014, 0.038)        # the fall's depth down from the stand's top: at his back, at its points
FALL_FLARE = 0.006           # ... flaring out this far at its edge
FALL_SPREAD = 14.0           # ... its points spread this many degrees apart at their tips
FALL_CLEAR = 0.003           # ... and kept this far off his shirt and vest
FALL_ROWS = 4
BAND_AROUND = 48
BAND_UV = 0.01               # the band's UVs spread this much round his shirt's white texel
# Try B (twin): Rodin run 89's own head, his face found over TWIN_FACE_FROM; scaled so his eye span
# is the anatomy's (within TWIN_SCALE; the approved head's irises span its eyes' middles exactly,
# TWIN_EYE_SPAN_SHARE), his eyes moved onto the anatomy's, eased in up his neck: all of it TWIN_EASE_TOP
# of the way from his neck's foot to his jaw (eased to the jaw, what's under his chin folded forward).
TWIN_FACE_FROM = 1.53
TWIN_FOOT_UNDER = 1.56       # his head's open edges under this are his neck's foot (over it, holes in his face)
TWIN_EYE_SPAN_SHARE = 1.0
TWIN_SCALE = (0.8, 1.0)
TWIN_EASE_TOP = 0.6
TWIN_OWN_BELOW = (0.005, 0.025)  # paint: under his chin, the portraits' paint above the first, his own below the second
HAT_INSIDE = 0.006           # under_hat: his hair drawn in this far inside his hat's crown


def load_head(head):
    m = dict(np.load(os.path.join(HEADS, head + "_mesh.npz")))
    return m["V"], m["T"], m["UV"], m["pts"]


def weld(V, T, tol=1e-5):
    _u, first, inv = np.unique(np.round(V / tol).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    return V[first], inv.ravel()[T]


def chin_targets(pts):
    """CHIN_TARGET in his space: each landmark's (x, y) from the portrait, its z kept."""
    io = float(np.linalg.norm(pts[468] - pts[473]))
    c = (pts[468] + pts[473]) / 2
    side = np.sign(pts[468, 0] - c[0])     # +1: MediaPipe's 468 on his +X side
    out = {}
    for (a, b), (hw, h) in CHIN_TARGET.items():
        for i, s in ((a, side), (b, -side)):
            now = pts[i]
            w_now = abs(now[0] - c[0]) / io
            w = w_now + (hw - w_now) * JAW_WIDTH_SHARE if hw else 0.0
            out[i] = np.array([c[0] + s * w * io, c[1] + h * io, now[2]])
    return out


def warp(V, pts):
    """The chin and lower jaw moved to CHIN_TARGET; a thin-plate spline carries the rest of him,
    with every landmark above his lower lip and every vertex behind his ears held."""
    from scipy.interpolate import RBFInterpolator
    tg = chin_targets(pts)
    ok = ~np.isnan(pts).any(1)
    lip = float(pts[17, 1])
    held = [i for i in range(len(pts)) if ok[i] and i not in tg and pts[i, 1] > lip + 0.002]
    Vw, _F = weld(V, np.arange(len(V)).reshape(-1, 3))
    back = Vw[(Vw[:, 2] > HOLD_BEHIND) | (Vw[:, 1] > float(pts[9, 1]))]
    back = back[np.random.default_rng(0).choice(len(back), min(400, len(back)), replace=False)]
    src = np.r_[np.array([pts[i] for i in tg]), pts[held], back]
    dst = np.r_[np.array([tg[i] for i in tg]), pts[held], back]
    f = RBFInterpolator(src, dst - src, kernel="thin_plate_spline", smoothing=1e-6)
    move = f(V)
    pts2 = pts.copy()
    pts2[ok] = pts[ok] + f(pts[ok])
    for i, p in tg.items():
        pts2[i] = p
    return V + move, pts2, {"chin_mm": round(float(1000 * (pts[152, 1] - pts2[152, 1])), 1),
                            "jaw_150_379_mm": round(float(1000 * (abs(pts2[150, 0] - pts2[379, 0]) - abs(pts[150, 0] - pts[379, 0]))), 1),
                            "max_move_mm": round(float(1000 * np.linalg.norm(move, axis=1).max()), 1)}


def smooth_hair(V, T, pts):
    """His hair behind his ears and round his nape (Rodin's ragged spikes, a grey clump under the
    brim) smoothed into a mass: Taubin's smoothing (lambda then mu, so it doesn't shrink; G. Taubin,
    "A signal processing approach to fair surface design", 1995) on the welded mesh, all of it
    behind HAIR_FROM_Z, none in front of his ears, his face never touched."""
    Vw, F = weld(V, T)
    nv = len(Vw)
    E = np.r_[F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]
    E = np.unique(np.sort(E, 1), axis=0)
    deg = np.bincount(E.ravel(), minlength=nv).astype(float)
    w = np.clip((Vw[:, 2] - HAIR_FROM_Z[0]) / (HAIR_FROM_Z[1] - HAIR_FROM_Z[0]), 0, 1)
    w = (w * w * (3 - 2 * w))[:, None]
    X = Vw.copy()
    for _ in range(HAIR_SMOOTH):
        for lam in (0.5, -0.53):
            acc = np.zeros_like(X)
            np.add.at(acc, E[:, 0], X[E[:, 1]])
            np.add.at(acc, E[:, 1], X[E[:, 0]])
            lap = acc / np.maximum(deg, 1)[:, None] - X
            X = X + lam * lap * w
    key = np.round(V / 1e-5).astype(np.int64)
    _u, inv = np.unique(key, axis=0, return_inverse=True)
    return X[inv.ravel()]


def cut_y(p, pts):
    """The cut's height at points p: a plane from CUT_FRONT under his chin to CUT_BACK behind; and
    under his jaw (inside its outline) along his jaw's lower border, rising from his chin to its
    angles (JAW_BORDER), so the old flaps under it go and the neck's loft makes his under-jaw."""
    zf, yf = float(pts[152, 2]), float(pts[152, 1]) - CUT_FRONT
    zb, yb = 0.09, CUT_BACK
    plane = yf + (p[..., 2] - zf) * (yb - yf) / (zb - zf)
    angle_y = float((pts[172, 1] + pts[397, 1]) / 2) - JAW_BORDER[1]
    border = np.minimum(float(pts[152, 1]) + JAW_BORDER[0] + np.maximum(p[..., 2] - zf - 0.008, 0) * JAW_SLOPE, angle_y)
    inside = np.clip((JAW_HALF_W[1] - np.abs(p[..., 0])) / (JAW_HALF_W[1] - JAW_HALF_W[0]), 0, 1)
    inside = inside * np.clip((0.02 - p[..., 2]) / 0.02, 0, 1)
    return plane + np.maximum(border - plane, 0) * inside


def clip(V, T, UV, f):
    """The triangles (one vertex a corner) cut exactly where f (a function of position) is 0, the
    side where it is positive kept; each cut edge's point found the same way from both its faces."""
    P, U = V[T], UV[T]
    d = f(P)
    out_V, out_U = [], []
    keep = (d >= 0).all(1)
    out_V.append(P[keep])
    out_U.append(U[keep])

    def cross(a, b, ua, ub, da, db):
        # Ordered so both faces of an edge compute the same point.
        swap = (a[:, 0] > b[:, 0]) | ((a[:, 0] == b[:, 0]) & (a[:, 1] > b[:, 1])) | ((a[:, 0] == b[:, 0]) & (a[:, 1] == b[:, 1]) & (a[:, 2] > b[:, 2]))
        A = np.where(swap[:, None], b, a)
        B = np.where(swap[:, None], a, b)
        dA = np.where(swap, db, da)
        dB = np.where(swap, da, db)
        UA = np.where(swap[:, None], ub, ua)
        UB = np.where(swap[:, None], ua, ub)
        t = (dA / (dA - dB))[:, None]
        return A + (B - A) * t, UA + (UB - UA) * t

    for n_in in (1, 2):
        sel = ((d >= 0).sum(1) == n_in)
        if not sel.any():
            continue
        Ps, Us, ds = P[sel], U[sel], d[sel]
        # Roll each triangle so its lone vertex (the one kept, or the one lost) comes first.
        lone = np.argmax((ds >= 0) if n_in == 1 else (ds < 0), axis=1)
        r = (np.arange(3)[None] + lone[:, None]) % 3
        Ps = np.take_along_axis(Ps, r[:, :, None], 1)
        Us = np.take_along_axis(Us, r[:, :, None], 1)
        ds = np.take_along_axis(ds, r, 1)
        p01, u01 = cross(Ps[:, 0], Ps[:, 1], Us[:, 0], Us[:, 1], ds[:, 0], ds[:, 1])
        p02, u02 = cross(Ps[:, 0], Ps[:, 2], Us[:, 0], Us[:, 2], ds[:, 0], ds[:, 2])
        if n_in == 1:
            out_V.append(np.stack([Ps[:, 0], p01, p02], 1))
            out_U.append(np.stack([Us[:, 0], u01, u02], 1))
        else:
            out_V += [np.stack([p01, Ps[:, 1], Ps[:, 2]], 1), np.stack([p01, Ps[:, 2], p02], 1)]
            out_U += [np.stack([u01, Us[:, 1], Us[:, 2]], 1), np.stack([u01, Us[:, 2], u02], 1)]
    Vc = np.concatenate(out_V).reshape(-1, 3)
    Uc = np.concatenate(out_U).reshape(-1, 2)
    # Slivers (a cut through a corner) go.
    Pc = Vc.reshape(-1, 3, 3)
    area = np.linalg.norm(np.cross(Pc[:, 1] - Pc[:, 0], Pc[:, 2] - Pc[:, 0]), axis=1)
    ok = area > 1e-10
    return Vc.reshape(-1, 3, 3)[ok].reshape(-1, 3), Uc.reshape(-1, 3, 2)[ok].reshape(-1, 2)


def trim(V, T, UV, pts):
    """His underside cut away along cut_y, loose scraps dropped; → per-corner V, UV of what's
    kept, welded positions and faces, and the bottom edge's loop."""
    Vc, Uc = clip(V, T, UV, lambda P: P[..., 1] - cut_y(P, pts))
    Tc = np.arange(len(Vc)).reshape(-1, 3)
    Vw, F = weld(Vc, Tc)
    keep = largest_piece(F, np.ones(len(F), bool), len(Vw))
    Vc = Vc.reshape(-1, 3, 3)[keep].reshape(-1, 3)
    Uc = Uc.reshape(-1, 3, 2)[keep].reshape(-1, 2)
    F = F[keep]
    return Vc, Uc, Vw, F, bottom_loop(Vw, F)


def largest_piece(F, keep, nv):
    """Only the biggest connected piece of the kept faces (scraps cut loose go)."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    Fk = F[keep]
    rows = np.r_[Fk[:, 0], Fk[:, 1], Fk[:, 2]]
    cols = np.r_[Fk[:, 1], Fk[:, 2], Fk[:, 0]]
    g = coo_matrix((np.ones(len(rows)), (rows, cols)), shape=(nv, nv))
    _n, lab = connected_components(g, directed=False)
    big = np.bincount(lab[Fk[:, 0]]).argmax()
    out = keep.copy()
    out[np.nonzero(keep)[0]] = lab[Fk[:, 0]] == big
    return out


def boundary_loops(F):
    E = np.r_[F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]
    key = np.sort(E, 1)
    _u, inv, cnt = np.unique(key, axis=0, return_inverse=True, return_counts=True)
    b = E[cnt[inv.ravel()] == 1]            # directed boundary edges (the face's own winding)
    nxt = {}
    for a, c in b:
        nxt.setdefault(int(a), []).append(int(c))
    loops, seen = [], set()
    for a0 in list(nxt):
        if a0 in seen:
            continue
        loop, a = [], a0
        while a not in seen and a in nxt:
            seen.add(a)
            loop.append(a)
            a = nxt[a][0]
        if len(loop) > 2:
            loops.append(loop)
    return loops


def bottom_loop(Vw, F):
    """The longest boundary loop: the cut under his jaw and round his nape."""
    loops = boundary_loops(F)
    return max(loops, key=lambda l: np.linalg.norm(np.diff(Vw[l + l[:1]], axis=0), axis=1).sum())


def ellipse_r(theta):
    """The neck's radius at angle theta (0 his front, -Z; +pi/2 his +X)."""
    return NECK_HALF_W * NECK_HALF_D / np.sqrt((NECK_HALF_D * np.sin(theta)) ** 2 + (NECK_HALF_W * np.cos(theta)) ** 2)


def polar(p):
    d = p[..., [0, 2]] - np.array([0.0, NECK_CENTRE_Z])
    return np.arctan2(d[..., 0], -d[..., 1]), np.hypot(d[..., 0], d[..., 1])


def at_polar(theta, r, y):
    return np.stack([r * np.sin(theta), y, NECK_CENTRE_Z - r * np.cos(theta)], -1)


def loft(Vw, loop):
    """The neck from the jaw cut's loop down: per angle a curve from the loop (leaving it level
    inward under his chin, straight down at his sides and back) to the neck's ellipse NECK_JOIN
    under it, then the tube straight down to NECK_BOTTOM. → new vertices, faces (on Vw + new), the
    new vertices' (angle, distance down the neck) for their UVs."""
    th_l, r_l = polar(Vw[loop])
    y_l = Vw[loop, 1]
    # The loop runs round him one way: sort out its winding so its angles rise.
    d = np.angle(np.exp(1j * np.diff(np.r_[th_l, th_l[:1]])))
    if d.sum() < 0:
        loop, th_l, r_l, y_l = loop[::-1], th_l[::-1], r_l[::-1], y_l[::-1]
    # The loop as functions of the angle (unwrapped, periodic).
    un = np.unwrap(th_l)
    order = np.argsort(un % (2 * np.pi))
    ths = un[order] % (2 * np.pi)

    def periodic(v):
        return lambda t: np.interp(t % (2 * np.pi), np.r_[ths - 2 * np.pi, ths, ths + 2 * np.pi], np.r_[v[order], v[order], v[order]])

    r_at, y_at = periodic(r_l), periodic(y_l)
    T = np.linspace(-np.pi, np.pi, NECK_AROUND, endpoint=False)
    front = np.clip((np.cos(T) - np.cos(np.radians(75))) / (np.cos(np.radians(30)) - np.cos(np.radians(75))), 0, 1)
    front = front * front * (3 - 2 * front)
    r0, y0 = r_at(T), y_at(T)
    r3 = ellipse_r(T)
    y3 = y0 - (NECK_JOIN[1] + (NECK_JOIN[0] - NECK_JOIN[1]) * front)
    # The under-jaw leaves the cut level and inward in front, straight down elsewhere; it meets the
    # tube going straight down.
    L = np.maximum(r0 - r3, 0.0)
    p0 = np.stack([r0, y0], -1)
    p1 = p0 + np.stack([-L * 0.55 * front, -(1 - front) * 0.5 * (y0 - y3)], -1)
    p3 = np.stack([r3, y3], -1)
    p2 = p3 + np.stack([np.zeros_like(r3), 0.45 * (y0 - y3)], -1)
    rings = []
    for s in np.linspace(0, 1, NECK_RINGS + 1)[1:]:
        q = ((1 - s) ** 3)[..., None] * p0 + (3 * s * (1 - s) ** 2)[..., None] * p1 + (3 * s * s * (1 - s))[..., None] * p2 + (s ** 3)[..., None] * p3
        rings.append(q)
    for s in np.linspace(0, 1, NECK_TUBE_RINGS + 1)[1:]:
        rings.append(np.stack([r3, y3 + (NECK_BOTTOM - y3) * s], -1))
    newV = np.concatenate([at_polar(T, q[:, 0], q[:, 1]) for q in rings])
    # Distance down the neck for the UVs (from the loop, along each angle's curve).
    prev = np.stack([r0, y0], -1)
    down = []
    acc = np.zeros(NECK_AROUND)
    for q in rings:
        acc = acc + np.linalg.norm(q - prev, axis=1)
        down.append(acc.copy())
        prev = q
    down = np.concatenate(down)
    n0 = len(Vw)
    idx = lambda k, j: n0 + k * NECK_AROUND + (j % NECK_AROUND)
    F = []
    # The loop to the first ring: a zip by angle (the loop's vertices are his head's own).
    nl = len(loop)
    a_l = np.r_[np.unwrap(th_l) - th_l[0], 2 * np.pi]
    j0 = int(np.argmin(np.abs(np.angle(np.exp(1j * (T - th_l[0]))))))
    a_r0 = float(np.angle(np.exp(1j * (T[j0] - th_l[0]))))
    a_r = a_r0 + np.arange(NECK_AROUND + 1) * 2 * np.pi / NECK_AROUND
    i = j = 0
    while i < nl or j < NECK_AROUND:
        if j >= NECK_AROUND or (i < nl and a_l[i + 1] <= a_r[j + 1]):
            F.append([loop[i % nl], loop[(i + 1) % nl], idx(0, j0 + j)])
            i += 1
        else:
            F.append([loop[i % nl], idx(0, j0 + j + 1), idx(0, j0 + j)])
            j += 1
    for k in range(len(rings) - 1):
        for j in range(NECK_AROUND):
            a, b, c, d = idx(k, j), idx(k, j + 1), idx(k + 1, j), idx(k + 1, j + 1)
            F += [[a, b, d], [a, d, c]]
    return newV, np.array(F), np.r_[np.tile(T, len(rings))], down


def orient_like(Fhead, Fnew):
    """The neck's faces wound as his head's are: from the head's edge inward, each new face takes
    each shared edge the other way round from the face it meets."""
    seen = {}
    for f in Fhead:
        for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
            seen[(int(a), int(b))] = True
    Fnew = [list(map(int, f)) for f in Fnew]
    done = [False] * len(Fnew)
    edges = {}
    for n, f in enumerate(Fnew):
        for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
            edges.setdefault((min(a, b), max(a, b)), []).append(n)
    while not all(done):
        moved = False
        for n, f in enumerate(Fnew):
            if done[n]:
                continue
            for a, b in ((f[0], f[1]), (f[1], f[2]), (f[2], f[0])):
                if (a, b) in seen:          # the same way round as a wound face: turn it
                    Fnew[n] = f[::-1]
                    done[n] = moved = True
                    break
                if (b, a) in seen:
                    done[n] = moved = True
                    break
            if done[n]:
                g = Fnew[n]
                for a, b in ((g[0], g[1]), (g[1], g[2]), (g[2], g[0])):
                    seen[(a, b)] = True
        if not moved:
            break
    return np.array(Fnew)


def free_square(UV, T, N=512):
    """The head atlas's largest empty square: (u0, v0, side), in UV (v down)."""
    from PIL import Image, ImageDraw
    from scipy import ndimage
    im = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(im)
    for t in T:
        d.polygon([(UV[i, 0] * N, UV[i, 1] * N) for i in t], fill=255)
    used = ndimage.binary_dilation(np.asarray(im) > 0, iterations=3)
    dt = ndimage.distance_transform_cdt(~used, metric="chessboard")
    r, c = np.unravel_index(dt.argmax(), dt.shape)
    h = dt.max() - 1
    return (c - h) / N, (r - h) / N, 2 * h / N


def shape(head, out):
    V, T, UV, pts = load_head(head)
    V2, pts2, rep = warp(V, pts)
    V2 = smooth_hair(V2, T, pts2)
    Vc0, Uc0, Vw, F, loop = trim(V2, T, UV, pts2)
    newV, Fn, th, down = loft(Vw, np.array(loop))
    Vall = np.r_[Vw, newV]
    Fn = orient_like(F, Fn)
    # Per corner, as the head comes (one vertex a corner): the head's kept faces with their UVs,
    # the neck's faces with UVs in the atlas's empty square, in two strips (front, back).
    u0, v0, side = free_square(UV, T)
    height = float(down.max()) + 0.005
    span = np.pi * 0.5 * (NECK_HALF_W + NECK_HALF_D) * 1.25   # half his neck round, with room
    k = side / max(span, 2 * height)
    corner_uv = np.zeros((len(Fn), 3, 2))
    th_v = np.r_[polar(Vw)[0], th]
    down_v = np.r_[np.zeros(len(Vw)), down]
    for f, tri in enumerate(Fn):
        t = th_v[tri].copy()
        # Corners on the loop take their own angle; a face straddling the back seam (+-pi) unwraps.
        t = np.where(t - t[0] > np.pi, t - 2 * np.pi, t)
        t = np.where(t - t[0] < -np.pi, t + 2 * np.pi, t)
        half = 0 if abs(np.angle(np.exp(1j * t.mean()))) < np.pi / 2 else 1
        tt = t if half == 0 else np.angle(np.exp(1j * (t - np.pi)))
        tt = np.where(tt - tt[0] > np.pi, tt - 2 * np.pi, tt)
        uu = (tt + np.pi / 2) / np.pi * span
        vv = down_v[tri] + half * (height + 0.004)
        corner_uv[f] = np.c_[u0 + uu * k, v0 + vv * k]
    Vc = np.r_[Vc0, Vall[Fn.ravel()]]
    UVc = np.r_[Uc0, corner_uv.reshape(-1, 2)]
    Tc = np.arange(len(Vc)).reshape(-1, 3)
    neck = np.r_[np.zeros(len(Vc0), bool), np.ones(len(Fn) * 3, bool)]
    down_c = np.r_[np.zeros(len(Vc0)), down_v[Fn.ravel()]]
    os.makedirs(WORK, exist_ok=True)
    np.savez_compressed(os.path.join(HEADS, out + "_mesh.npz"), V=Vc, T=Tc, UV=UVc, pts=pts2, neck=neck, down=down_c)
    rep.update({"faces_cut": int(len(T) - len(F)), "loop_vertices": len(loop), "neck_faces": len(Fn),
                "neck_uv_square": [round(u0, 3), round(v0, 3), round(side, 3)],
                "chin_y": round(float(pts2[152, 1]), 4)})
    json.dump(rep, open(os.path.join(WORK, out + "_shape.json"), "w"), indent=1)
    print("head_neck: shape", json.dumps(rep))


def open_eyes(tex, M, cover, pts):
    """His eyes' whites lifted (they read as a squint under the game's light: dark sockets, the
    whites a sliver): within EYE_R of each iris, the light, grey texels (his whites) taken
    EYE_WHITE of the way to a clean warm white; the irises and lids untouched."""
    out = tex.copy()
    d = np.min([np.linalg.norm(M[..., :3] - pts[i], axis=-1) for i in (468, 473)], axis=0)
    near = cover & (d < EYE_R) & (np.abs(M[..., 1] - float((pts[468, 1] + pts[473, 1]) / 2)) < 0.006)
    c = tex[near]
    lum = c @ np.array([0.2126, 0.7152, 0.0722])
    sat = c.max(1) - c.min(1)
    ref = np.median(lum)
    white = (lum > ref * 1.15) & (sat < 0.28)
    target = np.array([0.86, 0.80, 0.72])
    c[white] = c[white] + (target - c[white]) * EYE_WHITE
    out[near] = c
    return out


def paint(man):
    """rodin_portrait.paint on his shaped head (portrait.json <man>: `mesh`), then his neck's paint:
    where the portraits put his collar or coat on it, his skin (NECK_SKIN_TOL from its own skin's
    middle colour); smoothed (NECK_BLUR texels); and near the jaw cut each texel eased into the
    colour of the head just above it (his hair's ends at his nape, his stubble under his jaw)
    over NECK_EASE down the neck. → build/head_neck/<man>_paint.png."""
    import rodin_portrait as RP
    import portrait as P
    from PIL import Image
    from scipy import ndimage
    from scipy.spatial import cKDTree
    spec = json.load(open(os.path.join(PEOPLE, "portrait.json")))["men"][man]
    RP.paint(man, spec)
    P.close_landmarker()
    tex = np.asarray(Image.open(os.path.join(RP.WORK, man + "_paint.png")).convert("RGB")).astype(float) / 255.0
    m = dict(np.load(os.path.join(ROOT, spec["mesh"])))
    V, T, UV, neck, down = m["V"], m["T"], m["UV"], m["neck"], m["down"]
    size = tex.shape[0]
    table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
    vals = np.c_[V, neck.astype(float), down]
    M, cover = P.raster_uv(table, [list(t) for t in T], vals, size)
    is_neck = cover & (M[..., 3] > 0.5)
    head = cover & ~is_neck
    tex = open_eyes(tex, M, cover, m["pts"])
    if not is_neck.any():
        # His own neck (try B): his own paint kept under his chin (the portraits paint their coat's
        # collar there, a dark smear round his jaw), carried from his old UVs to his new.
        if "old_uv" in m:
            own = np.asarray(Image.open(os.path.join(ROOT, str(m["old_tex"]))).convert("RGB")).astype(float) / 255.0
            Mo, _c = P.raster_uv(table, [list(t) for t in T], m["old_uv"], size)
            h_, w_ = own.shape[:2]
            ownc = own[np.clip((Mo[..., 1] * h_).astype(int), 0, h_ - 1), np.clip((Mo[..., 0] * w_).astype(int), 0, w_ - 1)]
            chin = float(m["pts"][152, 1])
            t = np.clip((chin - TWIN_OWN_BELOW[0] - M[..., 1]) / (TWIN_OWN_BELOW[1] - TWIN_OWN_BELOW[0]), 0, 1)[..., None]
            out = np.where(cover[..., None], tex * (1 - t) + ownc * t, tex)
            _dd, (iy, ix) = ndimage.distance_transform_edt(~cover, return_indices=True)
            P.to_pil(out[iy, ix]).save(os.path.join(WORK, man + "_paint.png"))
        else:
            shutil.copy(os.path.join(RP.WORK, man + "_paint.png"), os.path.join(WORK, man + "_paint.png"))
        print("head_neck: painted %s (his own neck and its own paint under his chin)" % man)
        return
    lum = np.array([0.2126, 0.7152, 0.0722])
    c = tex[is_neck]
    # His neck's skin: the middle of its warm, mid-light texels (not hair, not collar).
    sat = c.max(1) - c.min(1)
    l_ = c @ lum
    skinlike = (sat > 0.12) & (l_ > 0.18) & (l_ < 0.6)
    skin = np.median(c[skinlike], 0) if skinlike.sum() > 100 else np.median(c, 0)
    far = np.linalg.norm(c - skin, axis=1) > NECK_SKIN_TOL
    c[far] = skin
    out = tex.copy()
    out[is_neck] = c
    # Smoothed within the neck's own texels.
    w = ndimage.gaussian_filter(is_neck.astype(float), NECK_BLUR)
    for ch in range(3):
        b = ndimage.gaussian_filter(np.where(is_neck, out[..., ch], 0.0), NECK_BLUR)
        out[..., ch] = np.where(is_neck, b / np.maximum(w, 1e-6), out[..., ch])
    # Eased into the head's colour just above the cut.
    hp = np.nonzero(head)
    pick = np.random.default_rng(0).choice(len(hp[0]), min(len(hp[0]), 300000), replace=False)
    tree = cKDTree(M[hp[0][pick], hp[1][pick], :3])
    npx = np.nonzero(is_neck)
    # Each neck texel's colour from the head NECK_LIFT plus its own distance above it (in his hair
    # behind, not the orange underside of its cut edge; his jaw's stubble in front).
    lifted = M[npx][:, :3] + np.c_[np.zeros(len(npx[0])), NECK_LIFT + M[npx][:, 4], np.zeros(len(npx[0]))]
    _d, j = tree.query(lifted)
    edge = tex[hp[0][pick][j], hp[1][pick][j]]
    # Behind, his hair comes down to his collar (his portrait from behind): eased further there.
    backness = ((1 - np.cos(polar(M[npx][:, :3])[0])) / 2) ** 2
    e = np.clip(1 - M[npx][:, 4] / (NECK_EASE + (NECK_EASE_BACK - NECK_EASE) * backness), 0, 1) ** 1.5
    out[npx] = out[npx] * (1 - e[:, None]) + edge * e[:, None]
    # Texels nobody covers take the nearest covered one's colour (so filtering at the edges of the
    # neck's strips doesn't bleed the atlas's old colours in).
    _dd, (iy, ix) = ndimage.distance_transform_edt(~cover, return_indices=True)
    out = out[iy, ix]
    os.makedirs(WORK, exist_ok=True)
    P.to_pil(out).save(os.path.join(WORK, man + "_paint.png"))
    print("head_neck: painted %s's neck (%d texels, %d from collar to skin, skin %s)" % (
        man, int(is_neck.sum()), int(far.sum()), [round(float(x), 3) for x in skin]))


def collar_y(p):
    """The body's cut round his collar at points p (body space): COLLAR_CUT (front, back) heights."""
    (zf, yf), (zb, yb) = COLLAR_CUT
    return yf + (p[..., 2] - zf) * (yb - yf) / (zb - zf)


def collar_band(bm, uvl, dl, skin):
    """His shirt's collar as in his arms-out pictures (a turned-down collar: a low stand round his
    neck, the fall folded out over it, its points spread over his shirt front with his tie's knot
    under them); the body's paint at the cut is mostly his vest's back and lapels. The stand: from
    BAND_TUCK under the body's cut edge (tucked inside it) up to BAND_TOP (front, back), BAND_OUT
    outside the neck at its foot and COLLAR_CLEAR at its top, open BAND_GAP either side of his
    front. The fall: from the stand's top down outside it FALL (back, at the points), flaring out
    FALL_FLARE, its points spread FALL_SPREAD degrees and kept FALL_CLEAR off his shirt. Painted
    from his shirt's own white (the brightest shirt texel on his chest), each vertex weighted as
    the body's nearest. → the collar's face count."""
    from PIL import Image
    from scipy.spatial import cKDTree
    img = np.asarray(Image.open(skin.data["_tex"]).convert("RGB"))
    co = np.array([v.co[:] for v in bm.verts])
    pb = np.c_[co[:, 0], co[:, 2], -co[:, 1]]
    # His shirt's white: the brightest, least coloured texel among his chest's loops.
    best, best_uv = -1.0, (0.5, 0.5)
    for f in bm.faces:
        for lp in f.loops:
            q = pb[lp.vert.index]
            if 1.38 < q[1] < 1.47 and abs(q[0]) < 0.035 and q[2] < -0.05:
                u, v = lp[uvl].uv
                c = img[int((1 - v) * (img.shape[0] - 1)), int(u * (img.shape[1] - 1))].astype(float) / 255
                score = c.mean() - (c.max() - c.min())
                if score > best:
                    best, best_uv = score, (u, v)
    tree = cKDTree(pb)
    T = np.radians(np.linspace(BAND_GAP, 360 - BAND_GAP, BAND_AROUND))
    T = np.angle(np.exp(1j * T))
    back = (1 - np.cos(T)) / 2                                    # 0 at his front, 1 at his back
    point = np.clip(1 - (np.abs(T) - np.radians(BAND_GAP)) / np.radians(40), 0, 1) ** 2
    rn = ellipse_r(T)
    foot = collar_y(at_polar(T, rn, np.zeros_like(T))) - BAND_TUCK
    top = BAND_TOP[0] + (BAND_TOP[1] - BAND_TOP[0]) * back
    rows = []
    for k in range(BAND_ROWS + 1):
        s_ = k / BAND_ROWS
        rows.append(at_polar(T, rn + BAND_OUT + (COLLAR_CLEAR - BAND_OUT) * s_, foot + (top - foot) * s_))
    fall = FALL[0] + (FALL[1] - FALL[0]) * point
    for k in range(1, FALL_ROWS + 1):
        s_ = k / FALL_ROWS
        th = T + np.sign(T) * np.radians(FALL_SPREAD) * point * s_
        P_ = at_polar(th, ellipse_r(th) + COLLAR_CLEAR + 0.002 + FALL_FLARE * s_ ** 0.7, top - fall * s_)
        # Kept off his shirt and vest: out along his neck's radius past the body's surface where it
        # lies right under the fall (the nearest vertex at his sides is his shoulder's, further out).
        _d, j = tree.query(P_)
        thb, rb = polar(pb[j])
        thp, rp = polar(P_)
        under = (np.abs(np.angle(np.exp(1j * (thb - thp)))) < np.radians(6)) & (np.abs(pb[j, 1] - P_[:, 1]) < 0.008)
        rp = np.where(under, np.maximum(rp, rb + FALL_CLEAR), rp)
        rows.append(at_polar(thp, rp, P_[:, 1]))
    verts = [[bm.verts.new((p[0], -p[2], p[1])) for p in row] for row in rows]
    bm.verts.ensure_lookup_table()
    for row, P_ in zip(verts, rows):
        _d, j = tree.query(P_)
        for v, jj in zip(row, j):
            if dl is not None:
                for gi, w in bm.verts[int(jj)][dl].items():
                    v[dl][gi] = w
    n = 0
    for k in range(len(rows) - 1):
        for j in range(BAND_AROUND - 1):
            a, b, c, d = verts[k][j], verts[k][j + 1], verts[k + 1][j + 1], verts[k + 1][j]
            for quad in ((a, b, c), (a, c, d)):
                f = bm.faces.new(quad)
                f.normal_update()
                ctr = (quad[0].co + quad[1].co + quad[2].co) / 3
                radial = np.array([ctr.x, ctr.y + NECK_CENTRE_Z, 0.0])
                if np.array(f.normal[:]) @ radial < 0:          # every face of it looks out from his neck
                    f.normal_flip()
                for lp in f.loops:
                    lp[uvl].uv = (best_uv[0] + (j / BAND_AROUND - 0.5) * BAND_UV, best_uv[1] + (k / len(rows) - 0.5) * BAND_UV * 0.3)
                f.smooth = True
                n += 1
    return n


def join(body, man, out, head):
    """His shaped, painted head on the fitted whole body (whole_man's chain, at his collar)."""
    import bpy
    import bmesh
    from scipy.spatial import cKDTree
    import whole_man as WM
    spec = json.load(open(os.path.join(PEOPLE, "portrait.json")))["men"][man]
    m = dict(np.load(os.path.join(ROOT, spec["mesh"])))
    V, T, UV, pts = m["V"], m["T"], m["UV"], m["pts"]
    chin = float(pts[152, 1])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, body + ".glb"))
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.name.startswith(("body_", "finger_", "cloth_")):
            bpy.data.objects.remove(o)
    skin, old = bpy.data.objects["body_skin"], bpy.data.objects["body_head"]
    bpy.data.objects.remove(old)
    skin.data["_tex"] = os.path.join(PEOPLE, body + "_skin.png")     # for the collar band's white
    # His body cut round his collar (Blender's space: body (x, y, z) is Blender (x, -z, y)).
    (zf, yf), (zb, yb) = COLLAR_CUT
    slope = (yb - yf) / (zb - zf)
    nrm = np.array([0.0, slope, 1.0])
    nrm /= np.linalg.norm(nrm)
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    bmesh.ops.bisect_plane(bm, geom=bm.verts[:] + bm.edges[:] + bm.faces[:], plane_co=(0, -zf, yf),
                           plane_no=tuple(nrm), clear_outer=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts[:], dist=1e-5)
    # Scraps cut loose from him go (as whole_man.join).
    bm.verts.ensure_lookup_table()
    seen, pieces = set(), []
    for v0 in bm.verts:
        if v0.index in seen:
            continue
        stack, piece = [v0], []
        seen.add(v0.index)
        while stack:
            v = stack.pop()
            piece.append(v)
            for e in v.link_edges:
                w = e.other_vert(v)
                if w.index not in seen:
                    seen.add(w.index)
                    stack.append(w)
        pieces.append(piece)
    pieces.sort(key=len)
    for piece in pieces[:-1]:
        if len(piece) < 200:
            bmesh.ops.delete(bm, geom=piece, context="VERTS")
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    # His collar on his neck's weight, not his head's (as whole_man.join).
    gh, gn = skin.vertex_groups.get("head"), skin.vertex_groups.get("neck")
    if gh is not None and gn is not None:
        for v in skin.data.vertices:
            for ge in v.groups:
                if ge.group == gh.index and ge.weight > 0:
                    w_n = next((g.weight for g in v.groups if g.group == gn.index), 0.0)
                    gn.add([v.index], w_n + ge.weight, "REPLACE")
        gh.remove([v.index for v in skin.data.vertices])
    # His collar stood round the new neck: within COLLAR_STAND under the cut every vertex goes to
    # the neck's ellipse plus COLLAR_CLEAR at its angle (a band standing round his throat), eased
    # back to where it was over COLLAR_EASE under that.
    co = np.array([v.co[:] for v in skin.data.vertices])
    pb = np.c_[co[:, 0], co[:, 2], -co[:, 1]]                     # → body space
    under = collar_y(pb) - pb[:, 1]
    f = np.clip(1 - (under - COLLAR_STAND) / COLLAR_EASE, 0, 1)
    f = f * f * (3 - 2 * f)
    th, r = polar(pb)
    r_t = ellipse_r(th) + COLLAR_CLEAR + BAND_OUT
    # Only his collar, not the tops of his shoulders beside it.
    f = f * np.clip(1 - (r - r_t - COLLAR_REACH[0]) / (COLLAR_REACH[1] - COLLAR_REACH[0]), 0, 1)
    r_new = r + (r_t - r) * f
    pn = at_polar(th, r_new, pb[:, 1])
    moved = np.linalg.norm(pn - pb, axis=1)
    for i, v in enumerate(skin.data.vertices):
        v.co = (pn[i, 0], -pn[i, 2], pn[i, 1])
    skin.data.update()
    # A lid inside his collar a little under the cut (a fan to the neck's middle): the gap between
    # collar and neck shows it, not the room through his back.
    bm = bmesh.new()
    bm.from_mesh(skin.data)
    bm.verts.ensure_lookup_table()
    uvl = bm.loops.layers.uv.active
    dl = bm.verts.layers.deform.active
    edge = [e for e in bm.edges if e.is_boundary and all(abs(collar_y(np.array([v.co.x, v.co.z, -v.co.y])) - v.co.z) < 0.004 for v in e.verts)]
    ev = {v.index for e in edge for v in e.verts}
    nape = max(ev, key=lambda i: bm.verts[i].co.y)
    nape_uv = next(iter(bm.verts[nape].link_loops))[uvl].uv.copy()
    cy = float(np.mean([bm.verts[i].co.z for i in ev])) - COLLAR_LID
    mid = bm.verts.new((0.0, -NECK_CENTRE_Z, cy))
    gi = skin.vertex_groups["neck"].index
    if dl is not None:
        mid[dl][gi] = 1.0
    for e in edge:
        a, b = e.verts
        loop = e.link_loops[0]
        fc = bm.faces.new((b, a, mid)) if loop.vert == a else bm.faces.new((a, b, mid))
        for lp in fc.loops:
            lp[uvl].uv = nape_uv
        fc.smooth = True
    band = collar_band(bm, uvl, dl, skin)
    bm.normal_update()
    bm.to_mesh(skin.data)
    bm.free()
    skin.data.update()
    # The head (and neck), welded by position, its UVs per corner.
    Vw, F = weld(V, T)
    used = np.unique(F)
    remap = -np.ones(len(Vw), int)
    remap[used] = np.arange(len(used))
    Vb = Vw[used]
    me = bpy.data.meshes.new("body_head")
    me.from_pydata([(p[0], -p[2], p[1]) for p in Vb], [], remap[F].tolist())
    uvl = me.uv_layers.new(name="UVMap")
    cuv = np.c_[UV[T.ravel(), 0], 1.0 - UV[T.ravel(), 1]]
    uvl.data.foreach_set("uv", cuv.astype(np.float32).ravel())
    me.polygons.foreach_set("use_smooth", np.ones(len(me.polygons), bool))
    me.validate(clean_customdata=False)
    h = bpy.data.objects.new("body_head", me)
    bpy.context.scene.collection.objects.link(h)
    for bn in arm.data.bones:
        h.vertex_groups.new(name=bn.name)
    # Skinned as the approved head is above (head over his chin, neck under it: NECK_BLEND); inside
    # his collar the neck takes the weights of the body's nearest vertex, so it moves with his
    # collar when he bends (COLLAR_WEIGHTS under the cut, all of them).
    t = np.clip((chin - NECK_BLEND[0] - Vb[:, 1]) / (NECK_BLEND[1] - NECK_BLEND[0]), 0, 1)
    wb = np.clip((collar_y(Vb) - Vb[:, 1]) / COLLAR_WEIGHTS, 0, 1)
    bco = np.array([v.co[:] for v in skin.data.vertices])
    bpb = np.c_[bco[:, 0], bco[:, 2], -bco[:, 1]]
    _d, near = cKDTree(bpb).query(Vb)
    names = {g.index: g.name for g in skin.vertex_groups}
    bw = [{names[g.group]: g.weight for g in skin.data.vertices[int(j)].groups if g.weight > 0} for j in near]
    for i in range(len(Vb)):
        w = {"head": (1 - t[i]) * (1 - wb[i]), "neck": t[i] * (1 - wb[i])}
        if wb[i] > 0:
            tot = sum(bw[i].values()) or 1.0
            for g, x in bw[i].items():
                w[g] = w.get(g, 0.0) + wb[i] * x / tot
        for g, x in w.items():
            if x > 1e-4:
                h.vertex_groups[g].add([i], float(x), "REPLACE")
    h.parent = arm
    mod = h.modifiers.new("skeleton", "ARMATURE")
    mod.object = arm
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    shutil.copy(os.path.join(PEOPLE, body + "_skin.png"), os.path.join(PEOPLE, out + "_skin.png"))
    shutil.copy(os.path.join(WORK, man + "_paint.png"), os.path.join(PEOPLE, out + "_head.png"))
    n_head = len(me.polygons)
    tris = WM.add_hat(bpy, out, head)
    rep = json.load(open(os.path.join(PEOPLE, body + ".json")))
    rep.update({"id": out, "triangles": dict(rep.get("triangles", {}), head=n_head, **tris),
                "eyes": json.load(open(os.path.join(PEOPLE, head + ".json")))["eyes"],
                "head_neck": {"head": man + " (tools/characters/head_neck.py: the Oct 14 head, his portrait's chin, a built neck, painted smooth)",
                              "collar_cut": [list(c) for c in COLLAR_CUT], "collar_moved_mm_max": round(float(moved.max()) * 1000, 1),
                              "chin_y": round(chin, 4)},
                "whole_man": {"body": body, "head": man, "hat": "his own (look/bold-cowboy-own-hat-2026-10-14)"}})
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("head_neck: collar band, %d faces" % band)
    print("head_neck: wrote %s (collar moved up to %.0f mm, head %d triangles)" % (path, moved.max() * 1000, n_head))


def twin(body, out):
    """Try B: Rodin run 89's own head and neck (the fitted whole body's `body_head`), kept with its
    own collar join, set so its drawn eyes are the anatomy's (tests/test_bodies.gd): a similarity
    (scale about his eyes, then moved) on all of it above his jaw, eased to nothing down his neck
    to where it meets his body (TWIN_EASE), so his own neck and collar stay joined; given new UVs
    (Blender's smart project: Rodin's put his face in a corner of the body's atlas) and its
    MediaPipe points. → assets/people/<out>.glb (no hat yet: `join_twin`), assets/people/heads/
    <out>_mesh.npz (V, T, UV per corner, pts) for the paint."""
    import bpy
    import bmesh
    import rodin_portrait as RP
    import portrait as P
    import whole_man as WM
    from PIL import Image
    tex = np.asarray(Image.open(os.path.join(PEOPLE, body + "_head.png")).convert("RGB")).astype(float) / 255.0
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(PEOPLE, body + ".glb"))
    for o in list(bpy.data.objects):
        if o.type == "MESH" and not o.name.startswith(("body_", "finger_", "cloth_")):
            bpy.data.objects.remove(o)
    h = bpy.data.objects["body_head"]
    me = h.data
    me.calc_loop_triangles()
    co = np.array([v.co[:] for v in me.vertices])
    pb = np.c_[co[:, 0], co[:, 2], -co[:, 1]]
    tris = np.array([t.vertices[:] for t in me.loop_triangles])
    luv = me.uv_layers.active.data
    tuv = np.array([[luv[li].uv[:] for li in t.loops] for t in me.loop_triangles])
    Vc, Uc = pb[tris].reshape(-1, 3), np.c_[tuv.reshape(-1, 2)[:, 0], 1 - tuv.reshape(-1, 2)[:, 1]]
    Tc = np.arange(len(Vc)).reshape(-1, 3)
    old_uv = Uc.copy()                                  # his own paint's UVs (kept under his chin)
    # His face found on his head framed whole over his collar (face_points frames the top 60% of a
    # bust, which on a head and neck this short cuts his chin off).
    cam = P.head_camera(Vc[Vc[:, 1] > TWIN_FACE_FROM], "front", 1024, fill=0.95)
    img, (tid, bary) = RP.render_own(Vc, Tc, Uc, tex, cam, 1024)
    lm = P.landmarks(P.to_pil(img))
    P.close_landmarker()
    if lm is None:
        raise SystemExit("head_neck: no face found on run 89's head")
    px = np.clip(lm[:, :2].astype(int), 0, 1023)
    tri, b_ = tid[px[:, 1], px[:, 0]], bary[px[:, 1], px[:, 0]]
    pts = np.full((len(lm), 3), np.nan)
    pts[tri >= 0] = (Vc[Tc[tri[tri >= 0]]] * b_[tri >= 0][:, :, None]).sum(1)
    io = float(np.linalg.norm(pts[468] - pts[473]))
    eyes = json.load(open(os.path.join(PEOPLE, "bold_cowboy_rodin.json")))["eyes"]
    goal = (np.array(eyes["right"]) + np.array(eyes["left"])) / 2
    mine = (pts[468] + pts[473]) / 2 + np.array([0, 0, WM.EYE_DEPTH])
    k = np.linalg.norm(np.array(eyes["right"]) - np.array(eyes["left"])) / (io * TWIN_EYE_SPAN_SHARE)
    k = float(np.clip(k, TWIN_SCALE[0], TWIN_SCALE[1]))
    # How much of the move each vertex takes: none at his neck's foot, all above his jaw.
    bm = bmesh.new()
    bm.from_mesh(me)
    edge = np.array(sorted({v.index for e in bm.edges if e.is_boundary for v in e.verts}))
    bm.free()
    foot = pb[edge]
    low = foot[foot[:, 1] < TWIN_FOOT_UNDER]      # his neck's foot, not holes in his face
    th_f, _r = polar(low)
    order = np.argsort(th_f)
    foot_at = lambda t: np.interp(t, np.r_[th_f[order] - 2 * np.pi, th_f[order], th_f[order] + 2 * np.pi],
                                  np.r_[low[order, 1], low[order, 1], low[order, 1]])
    th_v, _r = polar(pb)
    jaw_y = float(np.nanmean([pts[172, 1], pts[397, 1]]))
    s = np.clip((pb[:, 1] - foot_at(th_v)) / np.maximum((jaw_y - foot_at(th_v)) * TWIN_EASE_TOP, 0.01), 0, 1)
    s = s * s * (3 - 2 * s)
    moved = (pb - mine) * k + goal
    new = pb + (moved - pb) * s[:, None]
    new = under_hat(new, head="bold_cowboy_rodin")
    for i, v in enumerate(me.vertices):
        v.co = (new[i, 0], -new[i, 2], new[i, 1])
    me.update()
    pts2 = np.where(np.isnan(pts), np.nan, (pts - mine) * k + goal)
    # New UVs: his whole head and neck on its own texture.
    bpy.context.view_layer.objects.active = h
    for o in bpy.data.objects:
        o.select_set(o == h)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004)
    bpy.ops.object.mode_set(mode="OBJECT")
    me.calc_loop_triangles()
    luv = me.uv_layers.active.data
    tuv = np.array([[luv[li].uv[:] for li in t.loops] for t in me.loop_triangles])
    Vc = new[np.array([t.vertices[:] for t in me.loop_triangles])].reshape(-1, 3)
    Uc = np.c_[tuv.reshape(-1, 2)[:, 0], 1 - tuv.reshape(-1, 2)[:, 1]]
    os.makedirs(HEADS, exist_ok=True)
    np.savez_compressed(os.path.join(HEADS, out + "_mesh.npz"), V=Vc, T=np.arange(len(Vc)).reshape(-1, 3), UV=Uc, pts=pts2,
                        neck=np.zeros(len(Vc), bool), down=np.zeros(len(Vc)), old_uv=old_uv,
                        old_tex=os.path.join("assets", "people", body + "_head.png"))
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                              export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="NONE")
    rep = json.load(open(os.path.join(PEOPLE, body + ".json")))
    rep.update({"id": out, "eyes": eyes, "twin_head": {"scale": round(k, 3), "eye_span_mm": round(io * 1000, 1),
                "moved_eyes_mm": [round(float(x) * 1000, 1) for x in goal - mine],
                "neck_sheared_mm_max": round(float(np.linalg.norm(new - pb, axis=1)[s < 0.5].max()) * 1000, 1)}})
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("head_neck: twin", json.dumps(rep["twin_head"]))


def under_hat(V, head):
    """Points of his head that would show through his own hat (run 89's hair is fuller than the
    approved head's): drawn in to HAT_INSIDE inside its crown at their angle and height, from its
    brim's height up."""
    hat = dict(np.load(os.path.join(HEADS, head + "_hat.npz")))
    C = hat["hat_V"]
    cx, cz = float(C[:, 0].mean()), float(C[:, 2].mean())
    th_c = np.arctan2(C[:, 0] - cx, -(C[:, 2] - cz))
    r_c = np.hypot(C[:, 0] - cx, C[:, 2] - cz)
    bins = np.linspace(-np.pi, np.pi, 37)
    foot = np.array([C[(th_c >= a) & (th_c < b), 1].min() if ((th_c >= a) & (th_c < b)).any() else np.nan for a, b in zip(bins[:-1], bins[1:])])
    rad = np.array([np.percentile(r_c[(th_c >= a) & (th_c < b)], 10) if ((th_c >= a) & (th_c < b)).any() else np.nan for a, b in zip(bins[:-1], bins[1:])])
    mids = (bins[:-1] + bins[1:]) / 2
    ok = ~np.isnan(foot)
    th = np.arctan2(V[:, 0] - cx, -(V[:, 2] - cz))
    r = np.hypot(V[:, 0] - cx, V[:, 2] - cz)
    f_at = np.interp(th, mids[ok], foot[ok], period=2 * np.pi)
    r_at = np.interp(th, mids[ok], rad[ok], period=2 * np.pi) - HAT_INSIDE
    over = (V[:, 1] > f_at - 0.004) & (r > r_at)
    k = np.where(over, r_at / np.maximum(r, 1e-6), 1.0)
    out = V.copy()
    out[:, 0] = cx + (V[:, 0] - cx) * k
    out[:, 2] = cz + (V[:, 2] - cz) * k
    return out


def join_twin(body, man, out, head):
    """Try B's paint and his own hat on the twin head written by `twin`."""
    import bpy
    import whole_man as WM
    shutil.copy(os.path.join(PEOPLE, body + "_skin.png"), os.path.join(PEOPLE, out + "_skin.png"))
    shutil.copy(os.path.join(WORK, man + "_paint.png"), os.path.join(PEOPLE, out + "_head.png"))
    # A hat from an earlier join comes off first (run twice, he wore two, the second untextured).
    path = os.path.join(PEOPLE, out + ".glb")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    if any(o.name.startswith("cloth_hat") for o in bpy.data.objects):
        for o in list(bpy.data.objects):
            if o.type == "MESH" and (o.name.startswith("cloth_hat") or not o.name.startswith(("body_", "finger_", "cloth_"))):
                bpy.data.objects.remove(o)
        bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_skins=True, export_animations=False,
                                  export_apply=False, export_yup=True, export_normals=True, export_texcoords=True,
                                  export_materials="NONE")
    tris = WM.add_hat(bpy, out, head)
    rep = json.load(open(os.path.join(PEOPLE, out + ".json")))
    rep["triangles"] = dict(rep.get("triangles", {}), **tris)
    rep["whole_man"] = {"body": body, "head": man + " (Rodin run 89's own head and neck)", "hat": "his own"}
    json.dump(rep, open(os.path.join(PEOPLE, out + ".json"), "w"), indent=1)
    print("head_neck: wrote", out)


def measure(men):
    """His neck against his portraits, per man (`name:glb id:head npz`, the npz giving his
    MediaPipe points): chin to collar over eye to chin (his profile portrait: 0.20), the neck's
    width at its narrowest over his jaw's (his front portrait: 0.85), and how far his ear is in
    front of his shoulder joint (mm). → printed, one JSON line a man."""
    import bpy
    import whole_man as WM
    out = {}
    for spec in men.split(","):
        name, gid, npz = spec.split(":")
        pts = dict(np.load(os.path.join(ROOT, npz)))["pts"]
        obs = WM.objects(bpy, os.path.join(PEOPLE, gid + ".glb"))
        skin, head = obs["body_skin"][0], obs["body_head"][0]
        chin = float(pts[152, 1])
        eye = float((pts[468, 1] + pts[473, 1]) / 2)
        # His collar's front: the highest of his body near his front (either side of a tie's gap),
        # under his chin.
        th, r = polar(skin)
        front = (np.abs(th) > np.radians(12)) & (np.abs(th) < np.radians(35)) & (r < 0.11) & (skin[:, 1] < chin)
        collar = float(skin[front, 1].max())
        # The neck's width: the head mesh's narrowest across, between his collar and his jaw.
        jaw = float(np.linalg.norm(pts[172, [0, 2]] - pts[397, [0, 2]]))
        widths = []
        for y in np.arange(collar + 0.004, chin - 0.004, 0.002):
            band = head[(np.abs(head[:, 1] - y) < 0.0015) & (head[:, 2] > -0.03) & (head[:, 2] < 0.03)]
            if len(band) > 4:
                widths.append(np.ptp(band[:, 0]))
        neck_w = float(min(widths)) if widths else float("nan")
        sh = skin[(np.abs(skin[:, 1] - 1.44) < 0.006) & (np.abs(skin[:, 0]) > 0.15)]
        ear_z = float((pts[234, 2] + pts[454, 2]) / 2)
        out[name] = {"chin_to_collar_over_eye_to_chin": round((chin - collar) / (eye - chin), 2),
                     "chin_to_collar_mm": round((chin - collar) * 1000, 1),
                     "neck_over_jaw": round(neck_w / jaw, 2) if widths else None,
                     "ear_ahead_of_shoulder_mm": round((float(sh[:, 2].mean()) - ear_z) * 1000, 1)}
        print("head_neck: measure", name, json.dumps(out[name]))
    return out


def main():
    step = sys.argv[1]
    a = dict(x.split("=", 1) for x in sys.argv[2:] if "=" in x)
    if step == "shape":
        shape(a["--head"], a["--out"])
    elif step == "paint":
        paint(a["--man"])
    elif step == "measure":
        measure(a["--men"])
    elif step == "twin":
        twin(a["--body"], a["--out"])
    elif step == "join_twin":
        join_twin(a["--body"], a["--man"], a["--out"], a.get("--head", "bold_cowboy_rodin"))
    elif step == "join":
        join(a["--body"], a["--man"], a["--out"], a.get("--head", "bold_cowboy_rodin"))


if __name__ == "__main__":
    main()
