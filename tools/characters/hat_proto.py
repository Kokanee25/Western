"""The hat prototype (the fidelity investigation, task 3): a brown wide-brimmed cattleman made to
the bold cowboy's portraits, as its own lab asset, so his approved build is untouched and the
game's hat stays as it is.

    ~/bpyenv/bin/python tools/characters/hat_proto.py [--man=bold_cowboy] [--name=hat_cattleman]
        [--model=lab/bold_cowboy_approved] [--fit=1] [--k=v ...]
    godot --headless --import
    ... art_lab.gd -- --hat=lab:hat_cattleman

The shape is style_hat.make_hat's (portrait.json's `hat` numbers, any --k=v over them, and the
proportions below, measured off the portraits). The paint is designed, not projected: the
earlier hat took the portraits' colours and came out as orange smears of his face on the felt.
Here the felt is the portraits' brown in big squares of a few close tones (the portraits' crown
is a checker of browns), lighter towards the crown's top and on the brim's top, its crease and
the brim's underside darker, the brim's edge bound in a lighter tan line as the portraits draw
it; the band is style_hat.draw_band's (leather, brass studs).

Writes, each in the man's body space (the model's skeleton space: Y up, facing -Z),
assets/people/lab/<name>_{hat,hat_brim,hat_band}.obj and .png, and the outline over his
portraits (build/rodin_portrait/<name>_overlay.png) to check the fit by.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402
import rodin_portrait as RP  # noqa: E402
import style_hat as SH  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))


def _ring(c, hw, hf, hb, n=SH.AROUND, closed=False):
    """style_hat._ring with its back half behind him: there `where(cos > 0, -hf, hb) * cos` put
    the back half (cos < 0) in front too, so every ring folded onto its front and the hat had no
    back (its brim stopped behind the crown, his hair showed through). Patched here only: the
    approved build's hat-hair line (rodin_portrait.py) comes from the folded ring, and stays."""
    a = np.linspace(0, 2 * np.pi, n + 1 if closed else n, endpoint=closed)
    x = c[0] + hw * np.sin(a)
    z = c[2] - np.where(np.cos(a) > 0, hf, hb) * np.cos(a)    # a = 0 is his front (-z)
    return np.stack([x, np.full(len(a), c[1]), z], 1), a


SH._ring = _ring
LAB = os.path.join(ROOT, "assets", "people", "lab")
EYE_DEPTH = 0.012          # as rodin_portrait_build.py: an eye's middle behind its iris
# Off the profile portraits (eye to chin ~0.115 m): the band ~14 mm high, the crown standing
# well clear of the frame's top (taller than the old 0.125), the brim ~0.46 m front to back.
PROTO = {"band_h": 0.016, "crown_h": 0.12, "crown_top": 0.84, "pinch": 0.32, "dent": 0.022,
         "clear": 0.012, "shift_z": 0.0, "tilt": 8.0}
TEX = 256                  # read nearest: a texel ~4 mm on the crown
SQUARE_M = 0.016           # the felt's squares (the portraits' crown checker)
FELT_TONES = (0.86, 0.94, 1.0, 1.07, 1.15)
RIM = (0.55, 0.33, 0.17)   # the brim's bound edge (the portraits' tan line)


def tones(u, v, cells_u, cells_v, seed):
    """A tone per square of a (cells_u × cells_v) grid over UV."""
    rng = np.random.default_rng(seed)
    grid = rng.choice(FELT_TONES, size=(int(cells_v) + 1, int(cells_u) + 1))
    return grid[np.clip((v * cells_v).astype(int), 0, int(cells_v)), np.clip((u * cells_u).astype(int), 0, int(cells_u))]


def paint(parts, h):
    """{part: (TEX, TEX, 3)} the designed paint."""
    felt = np.array(h["colour"], float)
    yy, xx = np.mgrid[0:TEX, 0:TEX]
    u, v = (xx + 0.5) / TEX, (yy + 0.5) / TEX
    out = {}
    # The crown: u round it, v from its top (0) to the band (1).
    Vc = parts["hat"][0]
    girth = 2 * np.pi * np.ptp(Vc[:, 0]) / 2
    t = tones(u, v, girth / SQUARE_M, h["crown_h"] / SQUARE_M, 1)
    lift = 1.12 - 0.2 * v                         # lighter towards the top
    a = u * 2 * np.pi
    crease = (v < 0.22) & (np.abs(np.sin(a)) < 0.3)   # the top's dent, front to back
    c = felt * (t * lift)[..., None]
    c[crease] *= 0.62
    out["hat"] = c
    # The brim: its top in the left half (centre 0.25, 0.5), its underside in the right.
    du = np.where(u < 0.5, u - 0.25, u - 0.75) / 0.24
    dv = (v - 0.5) / 0.48
    rad = np.hypot(du, dv) / 2                    # 0.05 at the crown's foot, 0.5 at the edge
    span = max(h["brim_w"], h["brim_f"], h["brim_b"]) * 2
    t = tones(u, v, 1 / (SQUARE_M / span * 1.0), 1 / (SQUARE_M / span * 1.0), 2)
    top = felt * (t * 1.05)[..., None]
    under = felt * (t * 0.58)[..., None]
    c = np.where((u < 0.5)[..., None], top, under)
    c[(rad > 0.465) & (u < 0.5)] = RIM
    c[(rad > 0.47) & (u >= 0.5)] = np.array(RIM) * 0.7
    c[(rad < 0.07)] *= 0.75                        # the crown's foot shades the brim next to it
    out["hat_brim"] = c
    big = SH.draw_band(h)
    step = big.shape[0] // TEX
    out["hat_band"] = big[step // 2::step, step // 2::step]
    return out


def to_body(parts, pts, eyes):
    """The hat from his bust's space into his body's, as rodin_portrait_build.py puts his head."""
    a, b = (pts[468], pts[473]) if pts[468, 0] > pts[473, 0] else (pts[473], pts[468])
    mine_r, mine_l = a + [0, 0, EYE_DEPTH], b + [0, 0, EYE_DEPTH]
    er, el = np.array(eyes["right"]), np.array(eyes["left"])
    k = np.linalg.norm(er - el) / np.linalg.norm(mine_r - mine_l)
    c_mine, c_goal = (mine_r + mine_l) / 2, (er + el) / 2
    return {n: ((V - c_mine) * k + c_goal, T, UV) for n, (V, T, UV) in parts.items()}


def write_obj(path, V, T, UV, outward):
    """An OBJ with smooth normals, turned to face `outward` (a function of position) on average."""
    n = P.vertex_normals(V, T)
    if np.mean(np.sum(n * outward(V), 1)) < 0:
        n = -n
    with open(path, "w") as f:
        f.write("# hat_proto.py\n")
        for p in V:
            f.write("v %.5f %.5f %.5f\n" % tuple(p))
        for q in UV:
            f.write("vt %.5f %.5f\n" % (q[0], 1.0 - q[1]))
        for q in n:
            f.write("vn %.5f %.5f %.5f\n" % tuple(q))
        for t in T:
            f.write("f %s\n" % " ".join("%d/%d/%d" % (i + 1, i + 1, i + 1) for i in t))


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.pop("--man", "bold_cowboy")
    name = a.pop("--name", "hat_cattleman")
    model = a.pop("--model", "lab/bold_cowboy_approved")
    spec = json.load(open(os.path.join(ROOT, "assets", "people", "portrait.json")))["men"][man]
    h = SH.numbers(spec.get("hat"))
    h.update(PROTO)
    fit = a.pop("--fit", "") == "1"
    for k, val in a.items():
        h[k.lstrip("-")] = float(val)
    mesh = np.load(os.path.join(RP.WORK, man + "_mesh.npy"), allow_pickle=True).item()
    V, pts = mesh["V"], mesh["pts"]
    rep = json.load(open(os.path.join(RP.WORK, man + "_report.json")))
    cams = {v: P.PoseCamera.of(c) for v, c in rep["cameras"].items()}
    if fit and h.get("marks"):
        # --fit=1: the numbers fitted to the brim and band marks on the portraits (portrait.json
        # hat.marks), now that the hat has a back.
        # The portraits' brims droop at the sides as often as they roll up: curl may go below 0.
        SH.FIT_LO[SH.FIT_KEYS.index("curl")] = -0.04
        fitted, err = SH.fit_marks(V, pts, cams, h["marks"], h)
        h.update(fitted)
        print("hat_proto: fitted", fitted, "rms px", err)
    parts = SH.make_hat(V, pts, h)
    pics = {v: np.asarray(Image.open(os.path.join(ROOT, spec["paint_views"][v])).convert("RGB")).astype(float) / 255 for v in cams}
    SH.overlay(pics, cams, parts, os.path.join(RP.WORK, name + "_overlay.png"))
    eyes = json.load(open(os.path.join(ROOT, "assets", "people", model + ".json")))["eyes"]
    body = to_body(parts, pts, eyes)
    os.makedirs(LAB, exist_ok=True)
    tex = paint(parts, h)
    axis = body["hat"][0].mean(0)
    for part, (Vb, T, UV) in body.items():
        if part == "hat_brim":
            # Top and underside: each its own way (the top's half of the vertices first).
            half = len(Vb) // 2
            out = lambda X: np.where((np.arange(len(X)) < half)[:, None], [0, 1, 0], [0, -1, 0])
        else:
            out = lambda X: (X - axis) * [1, 0, 1]
        write_obj(os.path.join(LAB, "%s_%s.obj" % (name, part)), Vb, T, UV, out)
        P.to_pil(np.clip(tex[part], 0, 1)).save(os.path.join(LAB, "%s_%s.png" % (name, part)))
    top = max(float(Vb[:, 1].max()) for Vb, _t, _u in body.values())
    print("hat_proto: wrote %s (%s) top %.3f m, numbers %s" % (name, ", ".join(body), top,
          {k: h[k] for k in ("band_above_eyes", "crown_h", "band_h", "brim_w", "brim_f", "brim_b", "tilt")}))


if __name__ == "__main__":
    main()
