"""A fitted man's own fingers as the game's finger pieces (Sean, 2026-10-15: "go with 2").

The game builds each hand as a palm (part of his skin) and five fingers of three bones each
(HumanBody._build_hand: from the anatomy's knuckle `a` to tip `b`, the bones 0.42, 0.33 and 0.25
of its length), so a hand can curl round a grip and a ball can take a finger off. Its fingers
were plain cylinders; these are his own, cut from his model's hand:

- His hand's points welded, and each one's distance from his wrist over the surface (Dijkstra
  along the mesh's edges). His fingers by persistence (see segment): each the piece from its web
  to its tip, the five that stand farthest above their webs (the palm keeps what's below the
  webs: points dragged onto a finger from there swung out as spikes when it was straightened).
- Which is which: the thumb came away lowest; the other four in a row across his knuckles, the
  index nearest the thumb.
- His palm narrowed to the game's hand (Rodin draws big hands, ~15 cm across his knuckles
  against the game's ~7.5): across and through, not along, fading in from the wrist.
- Each finger cut in three by its distance from the wrist (the bones' shares), and each piece
  turned and moved rigidly onto its bone: straight down the anatomy's finger line, its curl
  towards the side the game curls it, scaled by the finger's length to the anatomy's. The game
  curls them back as it needs.

`segment` finds the fingers, `straighten` gives each bone's move, `move` applies one;
fit_tripo.TripoPerson.own_fingers builds the pieces from his own triangles (UVs his skin's). Ideas only from the usual rigging
practice (geodesic segmentation, rigid per-bone pieces); no code copied.
"""
import numpy as np

FINGERS = ["thumb", "index", "middle", "ring", "little"]
SHARES = (0.42, 0.33, 0.25)     # HumanBody._build_hand: each bone's share of the finger
MIN_PIECE = 15                  # welded points: smaller pieces are scraps
PERSIST = 0.012                 # metres: a finger stands this far above its web (a bump doesn't)
FORWARD = np.array([0.0, 0.0, -1.0])
RIGHT = np.array([1.0, 0.0, 0.0])


def along_basis(axis):
    """HumanBody._along: +Y along `axis`, X and Z from Vector3.FORWARD (or RIGHT)."""
    y = axis / np.linalg.norm(axis)
    ref = FORWARD if abs(y @ FORWARD) < 0.9 else RIGHT
    x = np.cross(ref, y)
    x /= np.linalg.norm(x)
    z = np.cross(x, y)
    z /= np.linalg.norm(z)
    return x, y, z


def _graph(pos, tris):
    from scipy.sparse import coo_matrix
    e = np.concatenate([tris[:, [0, 1]], tris[:, [1, 2]], tris[:, [2, 0]]])
    w = np.linalg.norm(pos[e[:, 0]] - pos[e[:, 1]], axis=1) + 1e-9
    n = len(pos)
    return coo_matrix((np.r_[w, w], (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])), shape=(n, n)).tocsr()


def _pieces(g, keep):
    """Connected pieces of the points in `keep`: [array of point ids], biggest first."""
    from scipy.sparse.csgraph import connected_components
    ids = np.nonzero(keep)[0]
    sub = g[ids][:, ids]
    n, lab = connected_components(sub, directed=False)
    out = [ids[lab == k] for k in range(n)]
    out = [p for p in out if len(p) >= MIN_PIECE]
    return sorted(out, key=len, reverse=True)


def segment(v, tris, hand, wrist, knuckle):
    """His hand's fingers: {name: welded point ids}, the welded positions and the map from his
    vertices to them; or None if the hand doesn't come apart into a thumb and four fingers."""
    from scipy.sparse.csgraph import dijkstra
    hv = np.nonzero(hand)[0]
    _u, first, weld = np.unique(np.round(v[hv] / 1e-6).astype(np.int64), axis=0, return_index=True, return_inverse=True)
    weld = weld.ravel()
    pos = v[hv][first]
    local = -np.ones(len(v), np.int64)
    local[hv] = weld
    t = local[tris]
    t = t[(t >= 0).all(1)]
    g = _graph(pos, t)
    u = (knuckle - wrist) / np.linalg.norm(knuckle - wrist)
    reach = float(np.linalg.norm(knuckle - wrist))
    along = (pos - wrist) @ u
    src = np.nonzero(along < along.min() + reach * 0.1)[0]   # his hand from where it starts at the wrist
    d = dijkstra(g, directed=False, indices=src, min_only=True)
    d[~np.isfinite(d)] = 0.0
    # His fingers by persistence (Edelsbrunner's idea, written for this): his points taken
    # from the farthest from his wrist down, each joining its neighbours already taken. Every
    # fingertip starts a piece; where two pieces meet (a finger's web) the one with the lower tip
    # ends, and if it stood more than PERSIST above the meeting it was a finger: its points so
    # far are that finger, web to tip. A bump on the skin ends at once and is dropped.
    nbr = [g.indices[g.indptr[k]:g.indptr[k + 1]] for k in range(len(pos))]
    root = np.arange(len(pos))

    def find(k):
        while root[k] != k:
            root[k] = root[root[k]]
            k = root[k]
        return k

    peak, members, taken = {}, {}, np.zeros(len(pos), bool)
    digits = []
    for k in np.argsort(-d):
        taken[k] = True
        rs = sorted({find(n) for n in nbr[k] if taken[n]}, key=lambda r: -peak[r])
        if not rs:
            peak[k], members[k] = d[k], [k]
            continue
        main = rs[0]
        for r in rs[1:]:
            for c in (r, main):
                if peak[c] - d[k] > PERSIST and not any(c == dc for dc, _p, _m in digits):
                    digits.append((c, peak[c] - d[k], np.array(members[c])))
            root[r] = main
            members[main] += members.pop(r)
        root[k] = main
        members[main].append(k)
    digits = sorted(digits, key=lambda x: -x[1])[:5]
    if len(digits) < 5:
        return None
    pieces = [m for _c, _p, m in digits]
    # The thumb: the one that came away lowest (longest from its web), the others the four.
    first = np.argmin([d[p].min() for p in pieces])
    thumb = pieces[first]
    four = [p for k, p in enumerate(pieces) if k != first]
    # Index to little: in a row across his knuckles, the index nearest the thumb.
    tb = pos[thumb].mean(0)
    base = np.array([pos[p[np.argsort(d[p])[:max(5, len(p) // 6)]]].mean(0) for p in four])
    row = base - base.mean(0)
    _s, _v, vt = np.linalg.svd(row, full_matrices=False)
    ax = vt[0]
    order = np.argsort(row @ ax)
    if np.linalg.norm(base[order[0]] - tb) > np.linalg.norm(base[order[-1]] - tb):
        order = order[::-1]
    named = {"thumb": thumb}
    for name, k in zip(FINGERS[1:], order):
        named[name] = four[k]
    return {"fingers": named, "pos": pos, "d": d, "weld": weld, "hv": hv, "reach": reach, "u": u}


def narrow_palm(v, hand, wrist, knuckle, s, fade=0.4):
    """His hand narrowed by s across and through (not along), from nothing at his wrist to all
    of it FADE of the way to his knuckles."""
    u = (knuckle - wrist) / np.linalg.norm(knuckle - wrist)
    reach = float(np.linalg.norm(knuckle - wrist))
    p = v[hand] - wrist
    a = p @ u
    k = 1.0 + (s - 1.0) * np.clip(a / (reach * fade), 0, 1)
    perp = p - a[:, None] * u
    out = v.copy()
    out[hand] = wrist + a[:, None] * u + perp * k[:, None]
    return out


def straighten(pos, d, pts, a, b, side):
    """One finger (welded ids `pts`): each point's fraction of the way along it (f), and for
    each of its three bones the rigid move (with the finger's scale) laying that piece on the
    bone: (his piece's start, rotation, the bone's origin, scale)."""
    dd = d[pts]
    lo, hi = float(dd.min()), float(dd.max())
    f = (dd - lo) / max(hi - lo, 1e-9)
    cuts = np.cumsum((0.0,) + SHARES)
    # His centreline: the middle of each slice of the finger along it.
    n = 12
    line = []
    for k in range(n):
        m = (f >= k / n) & (f <= (k + 1) / n)
        if m.any():
            line.append(pos[pts[m]].mean(0))
    line = np.array(line)
    lr = float(np.linalg.norm(np.diff(line, axis=0), axis=1).sum())
    at = lambda q: line[min(int(q * (len(line) - 1) + 0.5), len(line) - 1)]
    la = float(np.linalg.norm(b - a))
    k_len = la / max(lr, 1e-6)
    dirn = (b - a) / la
    # The game's curl: knuckle basis _along(a - b), a bone turned about its Z, the right hand's
    # tip towards -X, the left's towards +X.
    x, _y, _z = along_basis(a - b)
    curl_to = -x if side == "r" else x
    curl_to = curl_to - (curl_to @ dirn) * dirn
    curl_to /= np.linalg.norm(curl_to)
    # His own curl: the way his finger bends from its first piece.
    u0 = at(cuts[1]) - at(0.0)
    tip = at(1.0) - at(0.0)
    bend = tip - (tip @ u0) / max(u0 @ u0, 1e-12) * u0
    moves = []
    for i in range(3):
        s0, e0 = at(cuts[i]), at(cuts[i + 1])
        ui = e0 - s0
        if np.linalg.norm(ui) < 1e-6:
            ui = u0
        ui = ui / np.linalg.norm(ui)
        wi = bend - (bend @ ui) * ui
        if np.linalg.norm(wi) < 1e-6:
            wi = np.cross(ui, [0.0, 1.0, 0.0]) if abs(ui[1]) < 0.9 else np.cross(ui, [1.0, 0.0, 0.0])
        wi /= np.linalg.norm(wi)
        src = np.array([ui, wi, np.cross(ui, wi)])
        dst = np.array([dirn, curl_to, np.cross(dirn, curl_to)])
        moves.append((s0, dst.T @ src, a + dirn * la * cuts[i], k_len))
    return f, moves


def bone_of(f):
    """Which bone (0, 1, 2) a point at fraction f of the finger's length belongs to."""
    cuts = np.cumsum(SHARES)
    return np.searchsorted(cuts[:2], f, side="right")


def move(p, m):
    s0, R, origin, k = m
    return origin + ((p - s0) * k) @ R.T
