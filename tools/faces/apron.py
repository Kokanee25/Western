#!/usr/bin/env python3
"""A blacksmith's leather apron fitted to a man (Sean, 2026-10-28: "let's start the apron"): a bib
from his upper chest and a skirt to just below his knees, a strap round the back of his neck and
ties round his waist. Added to his model as one cloth piece, `cloth_apron`, which the game wears
(PeopleBodies: a piece it doesn't make itself is always worn), painted as worn, scorched leather.

    python3 tools/faces/apron.py --man=blacksmith_s1_talking [--colour=R,G,B]

→ assets/people/<man>.glb with the piece added (or replaced), <man>_apron.png (the leather),
<man>.json `apron` (what this did).

How it's fitted, as the bandana is (bandana.py): his body sampled as points and seen from his
trunk's axis, the outermost surface in each (angle, height) cell. The leather hangs: going down a
column its distance from the axis never shrinks, so the skirt falls straight from his belly and
bridges the gap between his legs, the way a stiff hide does. Where it lies is set by his own
joints (the skin's binds). It moves with him: the bib with his chest, the ties with his waist,
the skirt with his hips and, lower down, partly with each thigh, so it swings as he walks without
stretching to follow one leg.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from glb_io import Glb  # noqa: E402
import bandana  # noqa: E402  (its surface sampling, shell, normals and winding)

PEOPLE = os.path.join(ROOT, "assets", "people")

GAP = 0.014               # metres the leather stands off him (a stiff hide over a shirt)
GAP_STRAP = 0.008         # the straps, over his shirt and braces
BIB_BELOW_NECK = 0.12     # the bib's top edge this far below the base of his neck
BIB_HALF = 0.14           # half the bib's width (metres across his chest)
SKIRT_HALF = 0.36         # half the skirt's width at its hem (round his front and sides: its edges
WAIST_HALF = 0.28         # show past his hips from behind) and where it meets the ties
ABOVE_KNEE = 0.03         # the hem this far above his knees: knee length, so it lies on his lap as
                          # he sits (to below the knee it stuck straight out past his knees)
STRAP_W = 0.032           # the crossed straps' width
TIE_W = 0.03              # the waist ties'
GAP_TIE = 0.008           # the ties stand this far off his shirt (closer, the braces hid them)
TIE_DROP = 0.02           # the ties sit this far below the bib's waist line
COLS, ROWS = 28, 40       # the sheet: columns across, rows from the bib's top to the hem
STRAP_N = 40              # segments along a strap and round the ties
BEND = 0.12              # metres below his hips over which the skirt passes from his hips to his thighs:
                          # short, so it bends at his hip crease as he sits (over the thigh's length it
                          # bowed up off his lap)
TIE_TAILS = ((0.21, 8.0), (0.17, -12.0))   # the ties' ends from the knot: length, degrees off down
THIGH_SHARE = 0.95        # by his knees the skirt follows his thighs this much (the rest: his hips):
                          # it lies on his lap when he sits (at 0.55 it curled back under his thighs)
TEX = (512, 1024)
LEATHER = (150, 104, 68)   # lighter than it looks: the game's painted light darkens it (2026-10-28: (92, 60, 38) drew near black)


def joints(g):
    """{name: rest position} from the skin's inverse binds."""
    sk = g.g["skins"][0]
    ibm = np.array(g.accessor(sk["inverseBindMatrices"])).reshape(-1, 4, 4)
    return {n: np.linalg.inv(ibm[i].T)[:3, 3] for i, n in enumerate(g.joint_names())}


def half_angle(shell, y, half_m):
    """The angle either side of his front that `half_m` metres of leather spans at height y."""
    r = float(shell.r(0, y)) + GAP
    return math.degrees(min(half_m / max(r, 0.05), math.radians(100)))


def build(man, colour=LEATHER):
    path = os.path.join(PEOPLE, man + ".glb")
    g = Glb(path)
    names = g.joint_names()
    J = joints(g)
    meshes = [g.mesh(m["name"]) for m in g.g["meshes"] if m["name"] in ("body_skin", "body_head")]
    # His trunk only: a triangle his arms move is left out, or the ties would loop round the hands
    # hanging at his sides and the skirt's sides stand out over them.
    arm = np.array([n.startswith(("upper_arm", "forearm", "hand", "finger")) for n in names])
    trunk = []
    for m in meshes:
        T = m["T"]
        if "J" in m and "W" in m:
            lead = m["J"][np.arange(len(m["V"])), np.argmax(m["W"], axis=1)].astype(int)
            T = T[~arm[lead[T]].any(1)]
        trunk.append((m["V"], T))
    P = bandana.sample_surface(trunk)
    neck_y = float(J["neck"][1])
    knee_y = float((J["shin_r"][1] + J["shin_l"][1]) / 2)
    hip_y = float((J["thigh_r"][1] + J["thigh_l"][1]) / 2)
    waist_y = float(J["abdomen"][1])
    top_y = neck_y - BIB_BELOW_NECK
    hem_y = knee_y + ABOVE_KNEE
    # His trunk's axis: the middle of his extent at his waist (his belly forward, his back behind).
    band = P[np.abs(P[:, 1] - waist_y) < 0.03]
    axis = (float((band[:, 0].min() + band[:, 0].max()) / 2), float((band[:, 2].min() + band[:, 2].max()) / 2))
    shell = bandana.Shell(P, axis, hem_y - 0.05, neck_y + 0.12)

    def half_m(y):
        """Half the leather's width at height y: the bib narrow, flaring at the waist, the skirt wide."""
        if y >= waist_y:
            k = np.clip((top_y - y) / max(top_y - waist_y, 1e-6), 0, 1)
            k = k * k * (3 - 2 * k)
            return BIB_HALF + (WAIST_HALF - BIB_HALF) * k
        k = np.clip((waist_y - y) / max(waist_y - hem_y, 1e-6), 0, 1)
        return WAIST_HALF + (SKIRT_HALF - WAIST_HALF) * math.sqrt(k)

    # The sheet: each column a fixed share u of the width, hung from the top down.
    ys = np.linspace(top_y, hem_y, ROWS)
    fine = np.linspace(top_y, hem_y, ROWS * 6)
    V = np.zeros((COLS, ROWS, 3))
    UV = np.zeros((COLS, ROWS, 2))
    for i, u in enumerate(np.linspace(-1, 1, COLS)):
        ang = np.array([u * half_angle(shell, y, half_m(y)) for y in fine])
        rf = np.maximum.accumulate(shell.r(ang, fine)) + GAP
        r = np.interp(ys, fine[::-1], rf[::-1])
        a = np.radians(np.interp(ys, fine[::-1], ang[::-1]))
        V[i, :, 0] = axis[0] + r * np.sin(a)
        V[i, :, 1] = ys
        V[i, :, 2] = axis[1] - r * np.cos(a)
        UV[i, :, 0] = 0.02 + 0.96 * (u + 1) / 2
        UV[i, :, 1] = 0.02 + 0.80 * np.linspace(0, 1, ROWS)
    T = []
    for i in range(COLS - 1):
        for k in range(ROWS - 1):
            a, b, c, d = i * ROWS + k, (i + 1) * ROWS + k, (i + 1) * ROWS + k + 1, i * ROWS + k + 1
            T += [[a, b, c], [a, c, d]]
    V, UV, T = V.reshape(-1, 3), UV.reshape(-1, 2), np.array(T)

    # Who moves it: above his waist his chest and belly; below, his hips and, more toward the hem,
    # each thigh by how far across that side the column is.
    jc, ja, jp = names.index("chest"), names.index("abdomen"), names.index("pelvis")
    jr, jl = names.index("thigh_r"), names.index("thigh_l")
    right_x = 1.0 if J["thigh_r"][0] > J["thigh_l"][0] else -1.0
    Jw, Ww = [], []
    for p in V:
        y = p[1]
        if y >= waist_y:
            k = float(np.clip((y - waist_y) / max(J["chest"][1] - waist_y, 1e-6), 0, 1))
            Jw.append([jc, ja, 0, 0])
            Ww.append([k, 1 - k, 0, 0])
        else:
            # Below his hips, his hips and more and more his thighs, each by how far across that
            # side the column is. (Below his knees it stays on his thighs: given to his shins too,
            # it stretched as he sat; 2026-10-28, works_check sit 1254 cm2.)
            t = float(np.clip((hip_y - y) / BEND, 0, 1)) * THIGH_SHARE
            s = float(np.clip((p[0] - axis[0]) * right_x / 0.12, -1, 1))
            wr, wl = t * (0.5 + 0.5 * s), t * (0.5 - 0.5 * s)
            Jw.append([jp, jr, jl, ja])
            above = float(np.clip((y - hip_y) / max(waist_y - hip_y, 1e-6), 0, 1))
            Ww.append([(1 - t) * (1 - above), wr, wl, (1 - t) * above])
    Jw, Ww = np.array(Jw), np.array(Ww)

    # The straps: from the bib's top corners over his shoulders, crossed on his back and down to the
    # ties at his sides (a lone strap round his neck didn't show from behind); the ties: from the
    # skirt's sides round his waist to a knot at his back, its ends hanging.
    def wy(y):
        """Chest and belly by height, as the bib."""
        k = float(np.clip((y - waist_y) / max(J["chest"][1] - waist_y, 1e-6), 0, 1))
        return [jc, ja, 0, 0], [k, 1 - k, 0, 0]

    def strip(route, width, gap, uv_v):
        """A strap along `route` [(angle, height)], angles unwrapped, lying on him."""
        route = np.array(route, float)
        seg = np.r_[0, np.cumsum(np.hypot(np.radians(np.diff(route[:, 0])) * 0.15, np.diff(route[:, 1])))]
        ts = np.linspace(0, seg[-1], STRAP_N + 1)
        pa, py = np.interp(ts, seg, route[:, 0]), np.interp(ts, seg, route[:, 1])

        def at(a, y):
            aa = ((a + 180) % 360) - 180
            r = float(shell.r(aa, y)) + gap
            t = math.radians(aa)
            return np.array([axis[0] + r * math.sin(t), y, axis[1] - r * math.cos(t)])

        mid = np.array([at(a, y) for a, y in zip(pa, py)])
        lv, luv, lj, lw = [], [], [], []
        for i, (a, y) in enumerate(zip(pa, py)):
            tan = mid[min(i + 1, STRAP_N)] - mid[max(i - 1, 0)]
            out = np.array([math.sin(math.radians(a)), 0.0, -math.cos(math.radians(a))])
            side = np.cross(tan, out)
            side /= max(np.linalg.norm(side), 1e-9)
            for e in (-0.5, 0.5):
                q = mid[i] + side * width * e
                qa = math.degrees(math.atan2(q[0] - axis[0], -(q[2] - axis[1])))
                lv.append(at(qa + 360 * round((a - qa) / 360), q[1]))
                luv.append([0.02 + 0.96 * i / STRAP_N, uv_v + (e + 0.5) * 0.04])
                j, w = wy(q[1])
                lj.append(j)
                lw.append(w)
        lt = []
        for k in range(STRAP_N):
            a2 = 2 * k
            lt += [[a2, a2 + 1, a2 + 3], [a2, a2 + 3, a2 + 2]]
        return np.array(lv), np.array(luv), np.array(lt), np.array(lj), np.array(lw)

    def loop(y, a_front, width, gap, uv_v):
        """The ties: round his back from his left side to his right, level."""
        route = [(a, y) for a in np.linspace(a_front, 360 - a_front, 9)]
        lv, luv, lt, _lj, _lw = strip(route, width, gap, uv_v)
        return lv, luv, lt, np.tile([ja, jp, 0, 0], (len(lv), 1)), np.tile([0.5, 0.5, 0, 0], (len(lv), 1))

    a_top = half_angle(shell, top_y, BIB_HALF) * 0.85
    tie_y = waist_y - TIE_DROP
    a_tie = half_angle(shell, tie_y, half_m(tie_y)) * 0.97
    cross_y = (J["chest"][1] + waist_y) / 2 + 0.06
    over = neck_y - 0.03
    pieces = []
    for sgn in (1, -1):
        route = [(a_top, top_y + 0.005), (40, over - 0.01), (68, over), (110, over - 0.04),
                 (180, cross_y), (360 - a_tie - 12, tie_y + 0.02)]
        pieces.append(strip([(sgn * a, y) for a, y in route], STRAP_W, GAP_STRAP, 0.86))
    pieces.append(loop(tie_y, a_tie, TIE_W, GAP_TIE, 0.92))
    # The knot at his back and its two ends, hanging (the bandana's, made bigger).
    bandana.KNOT, bandana.TAILS, bandana.TAIL_W = (0.03, 0.022, 0.016), TIE_TAILS, (0.03, 0.026)
    bandana.GAP_BAND = GAP_TIE
    kv, kuv, kt = bandana.knot_and_tails(shell, axis, tie_y, np.zeros((0, 3)), np.zeros((0, 2)), np.zeros((0, 3), int))
    pieces.append((kv, 0.02 + 0.2 * kuv, kt, np.tile([ja, jp, 0, 0], (len(kv), 1)), np.tile([0.4, 0.6, 0, 0], (len(kv), 1))))
    for lv, luv, lt, lj, lw in pieces:
        T = np.r_[T, lt + len(V)]
        V = np.r_[V, lv]
        UV = np.r_[UV, luv]
        Jw = np.r_[Jw, lj]
        Ww = np.r_[Ww, lw]
    T = bandana.facing_out(V, T, axis)
    g.set_mesh("cloth_apron", V, bandana.normals(V, T), UV, Jw, Ww, T, node_like="body_skin")
    leather(colour).save(os.path.join(PEOPLE, man + "_apron.png"))
    g.save(path)
    rep = {"top_y": round(top_y, 3), "hem_y": round(hem_y, 3), "triangles": int(len(T)), "colour": list(colour)}
    info_p = os.path.join(PEOPLE, man + ".json")
    info = json.load(open(info_p))
    info["apron"] = rep
    json.dump(info, open(info_p, "w"), indent=1)
    print("apron:", man, json.dumps(rep))


def leather(colour, seed=11):
    """Worn leather: mottled hide, a darker sweat-and-soot belly, scorch marks low in the middle
    where the forge's sparks land, pale scuffs, a stitched edge, the strap and ties darker."""
    rng = np.random.default_rng(seed)
    w, h = TEX
    yy, xx = np.mgrid[0:h, 0:w] / np.array([h, w])[:, None, None]
    img = np.ones((h, w, 3)) * np.array(colour, float)
    # Mottling: a few octaves of smooth noise.
    m = np.zeros((h, w))
    for octave, amp in ((8, 0.10), (24, 0.06), (80, 0.04)):
        n = rng.normal(0, 1, (octave, octave // 2))
        n = np.asarray(Image.fromarray(((n - n.min()) / (np.ptp(n) + 1e-9) * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)) / 255.0
        m += amp * (n - 0.5) * 2
    img *= (1 + m)[..., None]
    # Darker where it's handled and sweated: the belly and down the middle.
    belly = np.exp(-(((xx - 0.5) / 0.28) ** 2) - (((yy - 0.42) / 0.25) ** 2))
    img *= (1 - 0.15 * belly)[..., None]
    # Scorch marks: a few ragged burns, most low and central, each a cluster of small blots of
    # unequal darkness (a lone round blot reads as a polka dot), with a scatter of spark pits.
    for _ in range(9):
        cx, cy = rng.normal(0.5, 0.17), rng.uniform(0.4, 0.78)
        for _k in range(int(rng.integers(3, 7))):
            bx, by = cx + rng.normal(0, 0.025), cy + rng.normal(0, 0.012)
            rx, ry = rng.uniform(0.004, 0.02), rng.uniform(0.003, 0.012)
            d = np.hypot((xx - bx) * w / h / rx, (yy - by) / ry)
            img *= (1 - rng.uniform(0.2, 0.5) * np.exp(-d ** 2))[..., None]
    for _ in range(120):
        px, py = rng.normal(0.5, 0.2), rng.uniform(0.3, 0.8)
        d = np.hypot((xx - px) * w / h, yy - py) / rng.uniform(0.0015, 0.0035)
        img *= (1 - 0.5 * np.exp(-d ** 2))[..., None]
    # Pale scuffs: short streaks across the grain.
    # (soft and few: 40 sharp ones read as white matchsticks, 2026-10-28)
    for _ in range(14):
        cx, cy = rng.uniform(0.1, 0.9), rng.uniform(0.1, 0.8)
        ang, ln = rng.uniform(-0.6, 0.6), rng.uniform(0.015, 0.05)
        d_along = (xx - cx) * math.cos(ang) + (yy - cy) * math.sin(ang)
        d_across = -(xx - cx) * math.sin(ang) + (yy - cy) * math.cos(ang)
        mask = np.exp(-(d_across / 0.004) ** 2) * np.exp(-(d_along / ln) ** 2)
        img += (mask * 14)[..., None]
    # The stitched edge: a row of pale dashes in from the sheet's border.
    sheet_v = (yy >= 0.02) & (yy <= 0.82)
    border = np.minimum.reduce([np.abs(xx - 0.035), np.abs(xx - 0.965), np.abs(yy - 0.035), np.abs(yy - 0.81)])
    stitch = sheet_v & (border < 0.003) & (((xx + yy) * 160) % 1 < 0.5)
    img[stitch] = img[stitch] * 0.4 + np.array([200, 180, 140]) * 0.6
    # The strap and ties: darker, oiled.
    img[yy > 0.84] *= 0.72
    img *= (1 + rng.normal(0, 0.025, (h, w)))[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))


if __name__ == "__main__":
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    col = tuple(int(v) for v in a.get("--colour", ",".join(map(str, LEATHER))).split(","))
    build(a["--man"], col)
