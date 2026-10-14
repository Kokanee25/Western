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
SIGMA = 0.018        # metres: the warp's falloff round each landmark
SMOOTH = 1e-3        # the warp's give (so it doesn't ring between close landmarks)


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
    full = np.zeros_like(pts)
    full[:n] = move
    # The irises with their eyes (the mean move of each eye's ring).
    for iris, ring in ((range(468, 473), [33, 133, 159, 145]), (range(473, 478), [362, 263, 386, 374])):
        full[list(iris)] = move[ring].mean(0)
    return full, seen


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


def relief(V, T, colour, pts, moustache_m, brows_m, report):
    """V (loop vertices) with the moustache and brows raised along the surface's normal where
    `colour` (each vertex's paint) is hair, not skin. Welded first, so seams move together."""
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
        region = front & (W[:, 1] < pts[2, 1] - 0.002) & (W[:, 1] > pts[17, 1] - 0.004) \
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
    out["lift_max_mm"] = round(1000 * float(lift.max()), 1)
    report.update(out)
    return V + (n * lift[:, None])[inv]


def nearest_normals(V, n_loop, at):
    ok = ~np.isnan(at).any(1)
    out = np.zeros_like(at)
    out[ok] = n_loop[cKDTree(V).query(at[ok])[1]]
    return out
