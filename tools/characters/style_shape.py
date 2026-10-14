"""His shape fitted to his style portraits, and the forms his paint says are there (docs/briefs/
character-style-fidelity.md, phase 2). Used by rodin_portrait.py when portrait.json gives the man
`fidelity` settings; numpy and scipy only.

Rodin built his head from the plain photographs, so the painted face only lines up from each
portrait's own camera: from anywhere else, and under the game's light, the forms are the photo
face's (the bold cowboy's chin a third short, his nose a fifth long). Here:

1. `solve_landmarks`: each face landmark's place in 3D, from every portrait at once. Each portrait
   (an orthographic camera, rodin_portrait.fit_camera) says where the landmark is across its own
   picture; a landmark only counts in a view it faces. A landmark is pulled back to where Rodin
   put it by PULL, so depth no portrait sees stays his. The whole set is then put back on Rodin's
   by the closest similarity, so only the shape changes, not his size or place.
2. `warp`: the mesh moved to them smoothly, a Gaussian falloff of SIGMA round each landmark
   (radial basis interpolation), so his hair, the back of his head and his neck below follow
   gently and are otherwise left alone. Each landmark moves at most MAX_MOVE.
3. `relief`: the forms the paint draws and Rodin didn't model: a moustache raised off the lip
   and brows off the brow ridge, each where the paint is the man's hair colour rather than his
   skin there, softened over the mesh into a rounded mass.
"""
import numpy as np
from scipy.spatial import cKDTree

PULL = 0.15          # a landmark's pull back to Rodin's place, against the portraits' (each 1)
FACING = 0.3         # how squarely a portrait must see a landmark for it to count
MAX_MOVE = 0.018     # metres a landmark may move
MOVE_SMOOTH_R = 0.008  # each landmark's move averaged with its neighbours' within this (3 passes)
SIGMA = 0.035        # metres: the warp's falloff round each landmark
SMOOTH = 3e-2        # the warp's give (so it doesn't ring between close landmarks)
STRAIN_MAX = 0.75    # the most two neighbouring points' moves may differ, per metre apart: past
                     # ~1 the surface folds over itself (the bold cowboy's crease under his chin,
                     # 2026-10-14); the whole warp is eased back until it holds


def linear(cam):
    """An orthographic PoseCamera as q = M p + c (M 2x3)."""
    c = cam.project(np.zeros((1, 3)))[0]
    M = np.stack([cam.project(np.eye(3)[i:i + 1])[0] - c for i in range(3)], 1)
    return M, c


def similarity3(src, dst):
    """Scale, rotation, offset taking src to dst (Umeyama)."""
    ms, md = src.mean(0), dst.mean(0)
    a, b = src - ms, dst - md
    u, s, vt = np.linalg.svd(b.T @ a)
    D = np.diag([1, 1, np.sign(np.linalg.det(u @ vt))])
    R = u @ D @ vt
    k = (s * np.diag(D)).sum() / (a ** 2).sum()
    return k, R, md - k * R @ ms


def solve_landmarks(pts, nrm, cams, lms, use):
    """Each landmark (468 of the face mesh; irises follow their eyes) where the portraits put it,
    as a move from pts (n, 3); and how many portraits saw each."""
    n = 468
    A = np.repeat(np.eye(3)[None] * PULL, n, 0)
    b = PULL * pts[:n].copy()
    seen = np.zeros(n, int)
    for view, cam in cams.items():
        if view not in lms:
            continue
        M, c = linear(cam)
        w = ((nrm[:n] @ cam.toward()) > FACING) & use[:n]
        s2 = cam.s ** 2
        MtM = M.T @ M / s2
        r = (lms[view][:n, :2] - c) @ M / s2       # (n, 3): M^T (lm - c) / s^2
        A[w] += MtM
        b[w] += r[w]
        seen += w
    X = np.linalg.solve(A, b[..., None])[..., 0]
    k, R, t = similarity3(X[use[:n]], pts[:n][use[:n]])
    X = (k * X @ R.T) + t
    move = X - pts[:n]
    mag = np.linalg.norm(move, axis=1, keepdims=True)
    move *= np.minimum(1.0, MAX_MOVE / np.maximum(mag, 1e-9))
    move[~use[:n]] = 0
    # Neighbouring landmarks the portraits disagree on (his jaw, most) asked for moves that
    # fought each other and folded the surface between them: each move is averaged with its
    # neighbours' first.
    from scipy.spatial import cKDTree
    idx = np.nonzero(use[:n])[0]
    tree = cKDTree(pts[idx])
    nb = tree.query_ball_point(pts[idx], MOVE_SMOOTH_R)
    m = move[idx]
    for _ in range(3):
        m = np.array([m[j].mean(0) for j in nb])
    move[idx] = m
    full = np.zeros_like(pts)
    full[:n] = move
    # The irises with their eyes (the mean move of each eye's ring).
    for iris, ring in ((range(468, 473), [33, 133, 159, 145]), (range(473, 478), [362, 263, 386, 374])):
        full[list(iris)] = move[ring].mean(0)
    return full, seen


def strain(V, T, W):
    """The worst stretch of the warp V → W along any edge (metres moved apart per metre)."""
    e = np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]])
    el = np.linalg.norm(V[e[:, 0]] - V[e[:, 1]], axis=1)
    d = W - V
    return float((np.linalg.norm(d[e[:, 0]] - d[e[:, 1]], axis=1) / np.maximum(el, 1e-4)).max())


def warp_safe(V, T, at, move, report):
    """warp(), eased back (the moves scaled down) until its strain is under STRAIN_MAX."""
    scale = 1.0
    for _ in range(8):
        W = warp(V, at, move * scale)
        st = strain(V, T, W)
        if st <= STRAIN_MAX:
            break
        scale *= 0.8
    report.update({"strain_max": round(st, 2), "warp_scale": round(scale, 2)})
    return W, move * scale


def warp_broad(V, at, move, centre, radius=0.09, ridge=1e-3):
    """The landmarks' moves as one broad correction of his face (a quadratic in position, fitted to
    them), fading out past `radius` from the face's middle: it can lengthen his chin, shorten his
    nose, narrow his cheeks, but can't put a lump between two landmarks the portraits disagree on
    (warp() did: a muzzle round his mouth and a groove down to his jaw, 2026-10-14)."""
    ok = ~np.isnan(at).any(1) & (np.linalg.norm(move, axis=1) > 0)

    def feats(p):
        q = (p - centre) / 0.1
        x, y, z = q[:, 0], q[:, 1], q[:, 2]
        return np.stack([np.ones_like(x), x, y, z, x * x, y * y, z * z, x * y, y * z, x * z], 1)

    F = feats(at[ok])
    A = F.T @ F + ridge * len(F) * np.eye(F.shape[1])
    coef = np.linalg.solve(A, F.T @ move[ok])
    d = feats(V) @ coef
    r = np.linalg.norm(V - centre, axis=1)
    fade = np.clip((radius * 1.5 - r) / (radius * 0.5), 0, 1)
    fade = fade * fade * (3 - 2 * fade)
    return V + d * fade[:, None]


def warp(V, at, move):
    """Every vertex moved by the landmarks' moves, interpolated with a Gaussian of SIGMA."""
    ok = ~np.isnan(at).any(1)
    p, d = at[ok], move[ok]
    K = np.exp(-((p[:, None] - p[None]) ** 2).sum(-1) / (2 * SIGMA ** 2))
    alpha = np.linalg.solve(K + SMOOTH * np.eye(len(p)), d)
    out = V.copy()
    for i in range(0, len(V), 20000):
        q = V[i:i + 20000]
        out[i:i + 20000] += np.exp(-((q[:, None] - p[None]) ** 2).sum(-1) / (2 * SIGMA ** 2)) @ alpha
    return out


def _neighbours(T, nv):
    e = np.concatenate([T[:, [0, 1]], T[:, [1, 2]], T[:, [2, 0]]])
    e = np.unique(np.sort(e, 1), axis=0)
    return e


def _soften(x, edges, steps):
    nv = len(x)
    for _ in range(steps):
        acc = np.zeros(nv)
        cnt = np.zeros(nv)
        np.add.at(acc, edges[:, 0], x[edges[:, 1]])
        np.add.at(acc, edges[:, 1], x[edges[:, 0]])
        np.add.at(cnt, edges[:, 0], 1)
        np.add.at(cnt, edges[:, 1], 1)
        x = 0.5 * x + 0.5 * acc / np.maximum(cnt, 1)
    return x


def _near_segment(W, a, b):
    """Each point's distance to the segment a-b."""
    ab = b - a
    t = np.clip(((W - a) @ ab) / max(float(ab @ ab), 1e-12), 0, 1)
    return np.linalg.norm(W - (a + t[:, None] * ab), axis=1)


def relief(V, T, colour, pts, moustache_m, brows_m, report, sideburns_m=0.0):
    """V (loop vertices) with the moustache, brows and sideburns raised along the surface's normal
    where `colour` (each vertex's paint) is hair, not skin. Welded first, so seams move together."""
    key = np.round(V / 1e-6).astype(np.int64)
    _u, first, inv = np.unique(key, axis=0, return_index=True, return_inverse=True)
    inv = inv.ravel()
    W = V[first]
    Tw = inv[T]
    col = np.zeros((len(W), 3))
    cnt = np.zeros(len(W))
    np.add.at(col, inv, colour)
    np.add.at(cnt, inv, 1)
    col /= np.maximum(cnt, 1)[:, None]
    fn = np.cross(W[Tw[:, 1]] - W[Tw[:, 0]], W[Tw[:, 2]] - W[Tw[:, 0]])
    n = np.zeros_like(W)
    for k in range(3):
        np.add.at(n, Tw[:, k], fn)
    n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)
    edges = _neighbours(Tw, len(W))
    front = n[:, 2] < -0.2
    eye_y = (pts[468, 1] + pts[473, 1]) / 2
    # His skin's colour: his cheeks, under the eyes and beside the nose.
    cheek = front & (W[:, 1] < eye_y - 0.015) & (W[:, 1] > pts[2, 1]) & (np.abs(W[:, 0] - pts[1, 0]) > 0.025) \
        & (np.abs(W[:, 0] - pts[1, 0]) < 0.05)
    skin = np.median(col[cheek], 0) if cheek.sum() > 20 else np.median(col[front], 0)
    lum = col @ np.array([0.2126, 0.7152, 0.0722])
    skin_l = float(skin @ np.array([0.2126, 0.7152, 0.0722]))
    # Hair: well darker than his skin, or much greyer (a grey moustache is lighter but has lost
    # the skin's warmth). Lips are redder than the skin, never hair.
    sat = col.max(1) - col.min(1)
    skin_sat = float(skin.max() - skin.min())
    hairlike = (lum < 0.62 * skin_l) | ((sat < 0.45 * skin_sat) & (np.abs(lum - skin_l) > 0.04))
    lip = (col[:, 0] - col[:, 1] > (skin[0] - skin[1]) * 1.15) & (lum > 0.5 * skin_l)
    hairlike &= ~lip
    lift = np.zeros(len(W))
    out = {}
    if moustache_m > 0:
        half = np.linalg.norm(pts[61] - pts[291]) / 2 + 0.012
        mid = (pts[61] + pts[291]) / 2
        # The upper lip only (nose base down to the lips' parting, 13): taken down past the lower
        # lip it lifted his lips too and made a muzzle of his mouth (2026-10-14).
        region = front & (W[:, 1] < pts[2, 1] - 0.002) & (W[:, 1] > pts[13, 1]) \
            & (np.abs(W[:, 0] - mid[0]) < half)
        m = (region & hairlike).astype(float)
        m = _soften(m, edges, 6)
        lift += moustache_m * np.clip(m * 1.6, 0, 1) ** 1.5
        out["moustache_vertices"] = int((region & hairlike).sum())
    if brows_m > 0:
        m = np.zeros(len(W))
        for e in (pts[159], pts[386]):
            region = front & (W[:, 1] > e[1] + 0.004) & (W[:, 1] < e[1] + 0.03) & (np.abs(W[:, 0] - e[0]) < 0.03)
            m += (region & hairlike).astype(float)
        m = _soften(np.clip(m, 0, 1), edges, 4)
        lift += brows_m * np.clip(m * 1.6, 0, 1) ** 1.5
        out["brow_vertices"] = int((m > 0.3).sum())
    if sideburns_m > 0:
        # Each sideburn: the side of his face, from the outer corner of his eye back to the front
        # of his ear (MediaPipe's face edge, 234 / 454, and a little behind it) and from his eye
        # line down to the angle of his jaw (172 / 397); the paint says which of it is hair.
        m = np.zeros(len(W))
        nose_x = pts[1, 0]
        for corner, edge, jaw in ((33, 234, 172), (263, 454, 397)):
            out_x = abs(pts[corner, 0] - nose_x)
            side = np.sign(pts[edge, 0] - nose_x)
            # From 1.5 cm under his eye line and 1.5 cm behind the eye's corner: from the eye line
            # itself it cut a crease across his temple (2026-10-14).
            band = (side * (W[:, 0] - nose_x) > out_x + 0.015) & (W[:, 1] < eye_y - 0.015) & (W[:, 1] > pts[jaw, 1]) \
                & (W[:, 2] < pts[edge, 2] + 0.015) & (side * n[:, 0] > 0.3)
            m += (band & hairlike).astype(float)
        m = _soften(np.clip(m, 0, 1), edges, 2)   # a crisper edge than the moustache's: it stands off the cheek
        lift += sideburns_m * np.clip(m * 1.6, 0, 1) ** 1.5
        out["sideburn_vertices"] = int((m > 0.3).sum())
    out["lift_max_mm"] = round(1000 * float(lift.max()), 1)
    report.update(out)
    return V + (n * lift[:, None])[inv]


def nearest_normals(V, n_loop, at):
    ok = ~np.isnan(at).any(1)
    out = np.zeros_like(at)
    out[ok] = n_loop[cKDTree(V).query(at[ok])[1]]
    return out
