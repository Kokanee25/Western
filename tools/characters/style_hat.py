"""His own hat, shaped to his style portraits and painted from them (docs/briefs/
character-style-fidelity.md: the bold cowboy's hat). Used by rodin_portrait.py when portrait.json
gives the man a `hat`; numpy and scipy only.

The game's hat (BodyMesh) is one low black crown for everyone; the bold cowboy's portraits give
him a brown felt cattleman with a creased crown, a wide brim rolled up at the sides and dipping
over his brows, and a leather band with brass studs. Here:

1. `make_hat`: the hat as three meshes in his bust's space (the space his portraits' cameras
   see), each with its own UVs (v down): `hat` (the crown: lofted rings from the band up, pinched
   at the front and dented on top), `hat_brim` (a thin annulus out from the band, its top in the
   left half of its texture and its underside in the right) and `hat_band` (a strap round the
   crown's foot). Sized from his head (the crown clears everything of him above the band, as
   people_bodies.hat_fit does) and the `hat` numbers.
2. `overlay`: the hat's outline drawn on each portrait through its camera, to fit the numbers by.
3. `paint_hat`: each part painted from the portraits as his face is (each texel from the portrait
   facing it squarest that sees it, depth-tested against his head and the hat; the portrait's
   backdrop never paints it), then cut into patches by anatomy. What no portrait sees (the brim's
   underside, mostly) takes the seen part's median, darker below.
"""
import math

import numpy as np

# The hat's numbers (portrait.json `hat` overrides any): metres in his bust's space.
HAT = {
    "band_above_eyes": 0.036,   # the band's foot over his eyes' middle, at the front
    "tilt": 0.0,                # degrees the hat tips back (up at the front)
    "roll": 0.0,                # degrees the hat is cocked to one side
    "clear": 0.006,             # the crown's foot this far clear of his head and hair
    "crown_h": 0.115,           # band to the top of the crown
    "crown_top": 0.86,          # the top ring's size against the foot's
    "pinch": 0.22,              # how far the front of the crown pinches in near the top
    "dent": 0.018,              # the crease down the top
    "brim_w": 0.205,            # the brim's half width at its edge
    "brim_f": 0.215,            # ... in front
    "brim_b": 0.195,            # ... behind
    "curl": 0.03,               # how far the brim's edge rolls up at the sides
    "dip": 0.012,               # how far its front and back edge drop
    "band_h": 0.026,            # the band's height
    "shift_z": 0.0,             # the crown moved back (+) or forward on his head
    "colour": [0.36, 0.22, 0.13],   # felt, for what no portrait paints
}
CROWN_RINGS = 8
AROUND = 48
BRIM_RINGS = 5
TEX = 1024


def numbers(spec_hat):
    h = dict(HAT)
    h.update(spec_hat or {})
    return h


def _ring(c, hw, hf, hb, n=AROUND, closed=False):
    """An oval ring round centre c (x half width, z half depth in front (-z) and behind); closed:
    one more point, the first again (so a texture can wrap without a seam)."""
    a = np.linspace(0, 2 * math.pi, n + 1 if closed else n, endpoint=closed)
    x = c[0] + hw * np.sin(a)
    # a = 0 is his front (-z). (Until 2026-10-14 this read `+ where(cos > 0, -hf, hb) * cos`,
    # which put the back half in front too: every ring folded onto its front and the hat had no
    # back; the refill plane rodin_portrait.py takes from the foot ring was unaffected.)
    z = c[2] - np.where(np.cos(a) > 0, hf, hb) * np.cos(a)
    return np.stack([x, np.full(len(a), c[1]), z], 1), a


def _grid_tris(rows, cols, wrap=True):
    T = []
    for i in range(rows - 1):
        for j in range(cols if wrap else cols - 1):
            a, b = i * cols + j, i * cols + (j + 1) % cols
            c, d = a + cols, b + cols
            T += [(a, c, b), (b, c, d)]
    return np.array(T)


def make_hat(V, pts, h):
    """{part: (V, T, UV)} in his bust's space."""
    eye_y = float((pts[468, 1] + pts[473, 1]) / 2)
    band_y = eye_y + h["band_above_eyes"]
    above = V[V[:, 1] > band_y - 0.005]
    lo, hi = above.min(0), above.max(0)
    c = np.array([(lo[0] + hi[0]) / 2, band_y, (lo[2] + hi[2]) / 2 + h.get("shift_z", 0.0)])
    hw = (hi[0] - lo[0]) / 2 + h["clear"]
    hd = (hi[2] - lo[2]) / 2 + h["clear"]
    # The crown: rings from the band up, narrowing, pinched at the front near the top.
    rings, uv = [], []
    for i in range(CROWN_RINGS):
        t = i / (CROWN_RINGS - 1)
        s = 1 + (h["crown_top"] - 1) * t ** 1.5
        r, a = _ring(c + [0, h["crown_h"] * t, 0], hw * s, hd * s, hd * s, closed=True)
        front = np.clip(np.cos(a), 0, 1) ** 2
        r[:, 0] = c[0] + (r[:, 0] - c[0]) * (1 - h["pinch"] * t ** 2 * front)
        if i == CROWN_RINGS - 1:   # the top's crease, front to back
            r[:, 1] -= h["dent"] * np.exp(-(np.sin(a) / 0.35) ** 2)
        rings.append(r)
        uv.append(np.stack([a / (2 * math.pi), np.full(AROUND + 1, 1 - t)], 1))
    Vc = np.concatenate(rings)
    Tc = _grid_tris(CROWN_RINGS, AROUND + 1, wrap=False)
    # The top's cap: a fan to the dented middle.
    top_c = c + [0, h["crown_h"] - h["dent"], 0]
    Vc = np.vstack([Vc, top_c])
    base = (CROWN_RINGS - 1) * (AROUND + 1)
    Tc = np.vstack([Tc, [(base + j, base + j + 1, len(Vc) - 1) for j in range(AROUND)]])
    UVc = np.vstack(uv + [[[0.5, 0.0]]])
    UVc[:, 1] = UVc[:, 1] * 0.98 + 0.01
    # The brim: rings out from the crown's foot; top and underside a few mm apart.
    a = np.linspace(0, 2 * math.pi, AROUND, endpoint=False)
    top, bot, uvt, uvb = [], [], [], []
    for i in range(BRIM_RINGS):
        t = i / (BRIM_RINGS - 1)
        w = hw + (h["brim_w"] - hw) * t
        f = hd + (h["brim_f"] - hd) * t
        b = hd + (h["brim_b"] - hd) * t
        r, _a = _ring(c, w, f, b)
        side = np.sin(a) ** 2
        r[:, 1] += h["curl"] * side * t ** 2 - h["dip"] * (1 - side) * t ** 1.5
        top.append(r + [0, 0.002, 0])
        bot.append(r - [0, 0.002, 0])
        rad = 0.05 + 0.45 * t
        uvt.append(np.stack([0.25 + 0.24 * rad * 2 * np.sin(a), 0.5 - 0.48 * rad * 2 * np.cos(a)], 1))
        uvb.append(np.stack([0.75 + 0.24 * rad * 2 * np.sin(a), 0.5 - 0.48 * rad * 2 * np.cos(a)], 1))
    Vb = np.concatenate(top + bot)
    Tt = _grid_tris(BRIM_RINGS, AROUND)
    Tb = _grid_tris(BRIM_RINGS, AROUND)[:, ::-1] + BRIM_RINGS * AROUND
    # The rim joining top and underside.
    n0, n1 = (BRIM_RINGS - 1) * AROUND, (2 * BRIM_RINGS - 1) * AROUND
    rim = [(n0 + j, n1 + j, n0 + (j + 1) % AROUND) for j in range(AROUND)] + \
        [(n0 + (j + 1) % AROUND, n1 + j, n1 + (j + 1) % AROUND) for j in range(AROUND)]
    Tb_all = np.vstack([Tt, Tb, rim])
    UVb = np.concatenate(uvt + uvb)
    # The band: a strap round the crown's foot, a few mm off it.
    bands, uvbn = [], []
    for i, y in enumerate((0.0, h["band_h"])):
        k = 1 + 0.004 / hw
        s = 1 + (h["crown_top"] - 1) * (y / h["crown_h"]) ** 1.5
        r, a2 = _ring(c + [0, y, 0], hw * s * k, hd * s * k, hd * s * k, closed=True)
        bands.append(r)
        uvbn.append(np.stack([a2 / (2 * math.pi), np.full(AROUND + 1, 0.9 - 0.8 * i)], 1))
    Vn = np.concatenate(bands)
    Tn = _grid_tris(2, AROUND + 1, wrap=False)
    UVn = np.concatenate(uvbn)
    parts = {"hat": (Vc, Tc, UVc), "hat_brim": (Vb, Tb_all, UVb), "hat_band": (Vn, Tn, UVn)}
    if h.get("tilt") or h.get("roll"):
        R = _rot_z(math.radians(h.get("roll", 0.0))) @ _rot_x(math.radians(h.get("tilt", 0.0)))
        pivot = c
        parts = {k: ((v - pivot) @ R.T + pivot, t, u) for k, (v, t, u) in parts.items()}
    return parts


def _rot_z(a):
    return np.array([[math.cos(a), -math.sin(a), 0], [math.sin(a), math.cos(a), 0], [0, 0, 1]])


def _rot_x(a):
    return np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])


def overlay(pics, cams, parts, path):
    """The hat's outline over each portrait (its camera): the fit's check."""
    from PIL import Image, ImageDraw
    tiles = []
    for view, cam in cams.items():
        img = Image.fromarray((pics[view] * 255).astype(np.uint8)).convert("RGB")
        d = ImageDraw.Draw(img)
        for name, (V, T, _uv) in parts.items():
            q = cam.project(V)
            col = {"hat": (60, 230, 90), "hat_brim": (240, 220, 60), "hat_band": (230, 60, 60)}[name]
            for t in T[:: max(1, len(T) // 1500)]:
                d.line([tuple(q[t[0]]), tuple(q[t[1]]), tuple(q[t[2]]), tuple(q[t[0]])], fill=col, width=1)
        img.thumbnail((640, 640))
        tiles.append(img)
    W = sum(t.width for t in tiles) + 6 * len(tiles)
    out = Image.new("RGB", (W, max(t.height for t in tiles)), (20, 18, 16))
    x = 0
    for t in tiles:
        out.paste(t, (x, 0))
        x += t.width + 6
    out.save(path)


def draw_band(h):
    """The band drawn rather than projected (the portraits disagree on its height, so projected it
    blurs into the felt): leather in two tones, a lit top edge, and `studs` square brass studs
    evenly round it, each with a dark rim and a lit corner (the portrait's conchos)."""
    tex = np.zeros((TEX, TEX, 3))
    leather = np.array(h["band_colour"], float)
    v = (np.arange(TEX) + 0.5) / TEX
    shade = np.where(v < 0.22, 1.35, np.where(v > 0.8, 0.8, 1.0))     # v down: the top edge lit
    tex[:] = leather * shade[:, None, None]
    stud = np.array(h.get("stud_colour", [0.85, 0.63, 0.37]), float)
    n = int(h.get("studs", 8))
    half_u = 0.012                     # a stud's half width, of the way round
    for i in range(n):
        u0 = (i + 0.5) / n
        x0, x1 = int((u0 - half_u) * TEX), int((u0 + half_u) * TEX)
        y0, y1 = int(0.3 * TEX), int(0.7 * TEX)
        tex[y0 - 6:y1 + 6, x0 - 6:x1 + 6] = leather * 0.45
        tex[y0:y1, x0:x1] = stud
        tex[y0:y0 + (y1 - y0) // 3, x0 + (x1 - x0) // 2:x1] = np.minimum(stud * 1.18, 1.0)
    return tex


# The designed paint (`hat.paint` "designed"): projected from the portraits the felt came out as
# orange smears of his face; drawn instead, as the portraits draw a hat: the felt's brown in
# squares of a few close tones, lighter up the crown, the crease and the brim's underside darker,
# the brim's edge bound in a lighter tan.
DESIGN_TEX = 256                  # read nearest: a texel ~4 mm on the crown
DESIGN_SQUARE_M = 0.016           # the felt's squares (the portraits' crown checker)
FELT_TONES = (0.86, 0.94, 1.0, 1.07, 1.15)
RIM = (0.55, 0.33, 0.17)          # the brim's bound edge (the portraits' tan line)


def _tones(u, v, cells_u, cells_v, seed):
    """A tone per square of a (cells_u × cells_v) grid over UV."""
    rng = np.random.default_rng(seed)
    grid = rng.choice(FELT_TONES, size=(int(cells_v) + 1, int(cells_u) + 1))
    return grid[np.clip((v * cells_v).astype(int), 0, int(cells_v)), np.clip((u * cells_u).astype(int), 0, int(cells_u))]


def design_hat(parts, h):
    """{part: (DESIGN_TEX, DESIGN_TEX, 3)}: the designed paint (see above)."""
    tex_n, sq_m = DESIGN_TEX, float(h.get("square_m", DESIGN_SQUARE_M))
    felt = np.array(h["colour"], float)
    yy, xx = np.mgrid[0:tex_n, 0:tex_n]
    u, v = (xx + 0.5) / tex_n, (yy + 0.5) / tex_n
    out = {}
    # The crown: u round it, v from its top (0) to the band (1).
    girth = math.pi * np.ptp(parts["hat"][0][:, 0])
    t = _tones(u, v, girth / sq_m, h["crown_h"] / sq_m, 1)
    c = felt * (t * (1.12 - 0.2 * v))[..., None]          # lighter towards the top
    c[(v < 0.22) & (np.abs(np.sin(u * 2 * math.pi)) < 0.3)] *= 0.62   # the top's dent
    out["hat"] = c
    # The brim: its top in the left half (centre 0.25, 0.5), its underside in the right.
    du = np.where(u < 0.5, u - 0.25, u - 0.75) / 0.24
    rad = np.hypot(du, (v - 0.5) / 0.48) / 2               # 0.05 at the crown's foot, 0.5 at the edge
    cells = 2 * max(h["brim_w"], h["brim_f"], h["brim_b"]) / sq_m
    t = _tones(u, v, cells, cells, 2)
    c = np.where((u < 0.5)[..., None], felt * (t * 1.05)[..., None], felt * (t * 0.58)[..., None])
    c[(rad > 0.465) & (u < 0.5)] = RIM
    c[(rad > 0.47) & (u >= 0.5)] = np.array(RIM) * 0.7
    c[rad < 0.07] *= 0.75                                  # the crown's foot shades the brim
    out["hat_brim"] = c
    big = draw_band(h)
    step = big.shape[0] // tex_n
    out["hat_band"] = big[step // 2::step, step // 2::step]
    return out


def paint_hat(parts, occluders, cams, pics, h, patch_squares, delight=None):
    """Each part's texture (TEX, TEX, 3): the portraits projected as on his face."""
    import portrait as P
    from scipy import ndimage
    allV = [o[0] for o in occluders] + [p[0] for p in parts.values()]
    allT, off = [], 0
    for o in [*occluders, *parts.values()]:
        allT.append(o[1] + off)
        off += len(o[0])
    AV, AT = np.concatenate(allV), np.concatenate(allT)
    zbufs = {}
    for view, cam in cams.items():
        hh, ww = pics[view].shape[:2]
        _tid, _b, zb = P.rasterise(cam.project(AV), cam.depth(AV), AT, ww, hh)
        zbufs[view] = zb
    out = {}
    for name, (V, T, UV) in parts.items():
        n_v = P.vertex_normals(V, T)
        table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
        M, cover = P.raster_uv(table, [list(t) for t in T], np.concatenate([V, n_v], 1), TEX)
        Pp, N = M[..., :3], M[..., 3:]
        N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-9)
        idx = np.nonzero(cover)
        p, n = Pp[idx], N[idx]
        best = np.full(len(p), -np.inf)
        col = np.zeros((len(p), 3))
        for view, cam in cams.items():
            img = pics[view]
            hh, ww = img.shape[:2]
            q = cam.project(p)
            qi = np.clip(q.astype(int), 0, [ww - 1, hh - 1])
            seen = (cam.depth(p) <= zbufs[view][qi[:, 1], qi[:, 0]] + 0.004) & (q[:, 0] >= 0) & (q[:, 0] < ww) \
                & (q[:, 1] >= 0) & (q[:, 1] < hh)
            c = P.sample(img, q[:, 0], q[:, 1])
            edge = np.concatenate([img[:, :40].reshape(-1, 3), img[:, -40:].reshape(-1, 3)])
            bg = np.median(edge, 0)
            # The backdrop: the portraits' ground is dark brown, the felt is lighter and warmer.
            bg_like = np.linalg.norm(c - bg, axis=1) < h.get("bg_tol", 0.07)
            f = n @ cam.toward()
            ok = seen & ~bg_like & (f > 0.1) & (f > best)
            best[ok] = f[ok]
            col[ok] = c[ok]
        tex = np.zeros((TEX, TEX, 3))
        tex[idx] = col
        have = np.zeros((TEX, TEX), bool)
        have[idx] = np.isfinite(best)
        felt = np.median(col[np.isfinite(best)], 0) if np.isfinite(best).any() else np.array(h["colour"])
        if name == "hat_brim":
            # The underside, which no portrait sees much of: the seen felt, in its own shadow.
            under = idx[1] >= TEX // 2
            unseen = ~np.isfinite(best)
            tex[idx[0][under & unseen], idx[1][under & unseen]] = felt * 0.55
            have[idx[0][under & unseen], idx[1][under & unseen]] = True
        if have.any():
            _d, (iy, ix) = ndimage.distance_transform_edt(~have, return_indices=True)
            tex = tex[iy, ix]
        tex[~cover] = felt
        if delight is not None:
            tex = delight(tex, cover, Pp, N)
        if name == "hat_band" and h.get("band_colour"):
            out[name] = draw_band(h)
            continue
        sq, _n = patch_squares(tex, cover, Pp, float(h.get("patch_m", 0.004)), float(h.get("patch_compact", 12.0)))
        sq[~cover] = felt
        out[name] = sq
    return out


# What each mark on a portrait is on the hat: a ring of the hat and which of its projected points
# (the left- or rightmost, the top, or the point at an angle round him: 0 his front, pi his back).
MARKS = {
    "brim_left": ("brim_edge", "left"), "brim_right": ("brim_edge", "right"),
    "brim_front": ("brim_edge", "front"), "band_front": ("foot", "front"), "band_back": ("foot", "back"),
    "band_left": ("foot", "left"), "band_right": ("foot", "right"), "crown_top": ("top", "top"),
}
# The crown's height isn't fitted (no portrait shows its top whole): `crown_h` as given.
FIT_KEYS = ["band_above_eyes", "tilt", "roll", "brim_w", "brim_f", "brim_b", "curl", "dip", "clear", "shift_z"]
# A cattleman's brim: flat or rolled up at the sides (curl >= 0), a little dip front and back.
# The portraits' brims droop at the sides as often as they roll up: curl may go below 0.
FIT_LO = [0.0, -25.0, -20.0, 0.12, 0.12, 0.12, -0.04, 0.0, -0.01, -0.04]
FIT_HI = [0.08, 25.0, 20.0, 0.32, 0.36, 0.40, 0.05, 0.03, 0.07, 0.10]


def _rings(parts):
    """The hat's rings the marks are on: the brim's edge (top side), the crown's foot, its top."""
    Vb = parts["hat_brim"][0]
    Vc = parts["hat"][0]
    n = AROUND + 1
    return {"brim_edge": Vb[(BRIM_RINGS - 1) * AROUND:BRIM_RINGS * AROUND], "foot": Vc[:AROUND],
            "top": Vc[(CROWN_RINGS - 1) * n:(CROWN_RINGS - 1) * n + AROUND]}


def _measure(q, which):
    """The projected point of a ring (q: (AROUND, 2)) a mark names."""
    if which == "left":
        return q[np.argmin(q[:, 0])]
    if which == "right":
        return q[np.argmax(q[:, 0])]
    if which == "top":
        return q[np.argmin(q[:, 1])]
    return q[0] if which == "front" else q[AROUND // 2]


def fit_marks(V, pts, cams, marks, h0):
    """The hat's numbers (FIT_KEYS) that put its rings on the marks Sean's portraits show
    (portrait.json `hat.marks`: per view, per mark, [x, y] in the portrait's pixels, either None
    when only the other counts). → (numbers, rms error in pixels)."""
    from scipy.optimize import least_squares
    items = [(v, m, xy) for v, ms in marks.items() if v in cams for m, xy in ms.items() if m in MARKS]

    def numbers_of(z):
        h = dict(h0)
        h.update(dict(zip(FIT_KEYS, z)))
        return h

    def residuals(z):
        h = numbers_of(z)
        rings = _rings(make_hat(V, pts, h))
        r = []
        for view, m, xy in items:
            ring, which = MARKS[m]
            q = _measure(cams[view].project(rings[ring]), which)
            for k in (0, 1):
                if xy[k] is not None:
                    r.append((q[k] - xy[k]) / 10.0)
        return np.array(r)

    z0 = np.clip([float(h0.get(k, 0.0)) for k in FIT_KEYS], FIT_LO, FIT_HI)
    res = least_squares(residuals, z0, bounds=(FIT_LO, FIT_HI), loss="soft_l1", f_scale=2.0, x_scale=np.array(FIT_HI) - np.array(FIT_LO))
    h = numbers_of(res.x)
    err = float(np.sqrt(np.mean((residuals(res.x) * 10) ** 2)))
    rings = _rings(make_hat(V, pts, h))
    for view, m, xy in items:
        ring, which = MARKS[m]
        q = _measure(cams[view].project(rings[ring]), which)
        print("   %-13s %-11s mark %-14s ours %s" % (view, m, xy, q.round(0).tolist()))
    return {k: round(float(h[k]), 4) for k in FIT_KEYS}, round(err, 1)


def main():
    """python style_hat.py --man=M [--out=PNG]: the hat's outline over his portraits."""
    import json
    import os
    import sys
    from PIL import Image
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, here)
    import portrait as P
    import rodin_portrait as RP
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.get("--man", "bold_cowboy")
    root = os.path.dirname(os.path.dirname(here))
    spec = json.load(open(os.path.join(root, "assets", "people", "portrait.json")))["men"][man]
    rep = json.load(open(os.path.join(RP.WORK, man + "_report.json")))
    mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
    cams = {v: P.PoseCamera.of(c) for v, c in rep["cameras"].items()}
    pics = {v: np.asarray(Image.open(os.path.join(root, spec["paint_views"][v])).convert("RGB")).astype(float) / 255 for v in cams}
    h = numbers(spec.get("hat"))
    if h.get("marks") and h.get("fit", True):
        fitted, err = fit_marks(mesh["V"], mesh["pts"], cams, h["marks"], h)
        h.update(fitted)
        print("style_hat: fitted", fitted, "rms px", err)
    parts = make_hat(mesh["V"], mesh["pts"], h)
    path = a.get("--out", os.path.join(RP.WORK, man + "_hat_overlay.png"))
    overlay(pics, cams, parts, path)
    print("style_hat: wrote", path)


if __name__ == "__main__":
    main()
