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
GAP_STRAP = 0.005         # the strap and ties, pulled close
BIB_BELOW_NECK = 0.12     # the bib's top edge this far below the base of his neck
BIB_HALF = 0.14           # half the bib's width (metres across his chest)
SKIRT_HALF = 0.30         # half the skirt's width at its hem (round his front and sides)
WAIST_HALF = 0.24         # and where it meets the ties
BELOW_KNEE = 0.07         # the hem this far below his knees
STRAP_W = 0.028           # the neck strap's width
TIE_W = 0.022             # the waist ties'
TIE_DROP = 0.02           # the ties sit this far below the bib's waist line
COLS, ROWS = 28, 40       # the sheet: columns across, rows from the bib's top to the hem
STRAP_N = 40              # segments round the neck strap and round the ties
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
    hem_y = knee_y - BELOW_KNEE
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
            t = float(np.clip((hip_y - y) / max(hip_y - knee_y, 1e-6), 0, 1)) * THIGH_SHARE
            s = float(np.clip((p[0] - axis[0]) * right_x / 0.12, -1, 1))
            wr, wl = t * (0.5 + 0.5 * s), t * (0.5 - 0.5 * s)
            Jw.append([jp, jr, jl, ja])
            above = float(np.clip((y - hip_y) / max(waist_y - hip_y, 1e-6), 0, 1))
            Ww.append([(1 - t) * (1 - above), wr, wl, (1 - t) * above])
    Jw, Ww = np.array(Jw), np.array(Ww)

    # The strap: from the bib's top corners up round the back of his neck; the ties: from the
    # skirt's sides at his waist round his back.
    def loop(y_front, y_back, a_front, width, gap, joint_pair, uv_v):
        lv, luv, lj, lw = [], [], [], []
        for s in np.linspace(0, 1, STRAP_N + 1):
            a = a_front + (360 - 2 * a_front) * s            # from his left round his back to his right
            aa = ((a + 180) % 360) - 180
            k = math.sin(math.pi * s)                         # 1 at his back
            y = y_front + (y_back - y_front) * k
            for e in (-0.5, 0.5):
                yy = y + e * width
                r = float(shell.r(aa, yy)) + gap
                t = math.radians(aa)
                lv.append([axis[0] + r * math.sin(t), yy, axis[1] - r * math.cos(t)])
                luv.append([0.02 + 0.96 * s, uv_v + (e + 0.5) * 0.04])
                lj.append([joint_pair[0], joint_pair[1], 0, 0])
                lw.append([1 - 0.5 * k, 0.5 * k, 0, 0])
        lt = []
        for k in range(STRAP_N):
            a = 2 * k
            lt += [[a, a + 1, a + 3], [a, a + 3, a + 2]]
        return np.array(lv), np.array(luv), np.array(lt), np.array(lj), np.array(lw)

    a_top = half_angle(shell, top_y, BIB_HALF) * 0.85
    tie_y = waist_y - TIE_DROP
    a_tie = half_angle(shell, tie_y, half_m(tie_y)) * 0.97
    pieces = [loop(top_y + 0.01, neck_y + 0.02, a_top, STRAP_W, GAP_STRAP, (jc, names.index("neck")), 0.86),
              loop(tie_y, tie_y - 0.01, a_tie, TIE_W, GAP_STRAP, (ja, jp), 0.92)]
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
