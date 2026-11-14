"""The coat's UVs: each part of the horse unrolled its own way and packed at one texel density
(numpy; tools/blender/horse.py writes them into the mesh).

Smart projection on a decimated mesh cuts it into hundreds of slivers; a pelt laid out by parts
keeps the paint whole and the seams few and out of sight: the barrel unrolled round its length
(the seam along the belly's midline), the breast and buttocks as caps seen from the front and
behind, the neck and head each unrolled round their own axis (seams underneath), each leg round
its own (seam inside, towards the other leg), the tail round its fall, the ears flat.
"""
import math

import numpy as np

import horse_shape as hs

BODY_AXIS_Z = 1.18


def _cyl(points, a, b, seam_dir):
    """Unroll round the axis a→b: (along the axis, arc round it) in metres, the cut at `seam_dir`."""
    a = np.asarray(a, float)
    b = np.asarray(b, float)
    ax = (b - a) / np.linalg.norm(b - a)
    ref = np.asarray(seam_dir, float)
    ref = ref - (ref @ ax) * ax
    ref /= np.linalg.norm(ref)
    other = np.cross(ax, ref)
    q = points - a
    along = q @ ax
    radial = q - along[:, None] * ax
    r = np.linalg.norm(radial, axis=1)
    ang = np.arctan2(radial @ other, radial @ ref)  # 0 at the cut, [0, 2pi) round from it
    ang = np.where(ang < 0, ang + 2 * math.pi, ang)
    return along, ang, r


def _region(c, n, part):
    """Which part a face belongs to by its centre and normal (Blender axes)."""
    x, y, z = c
    if part > 0.5:
        return "tail"
    if z > hs.POLL[1] + 0.03 and abs(y) > 0.03 and x > hs.POLL[0] - 0.08 and x < hs.POLL[0] + 0.08:
        return "ear_L" if y < 0 else "ear_R"
    rel = np.array([x - hs.POLL[0], 0.0, z - hs.POLL[1]])
    if x < -0.98 and rel @ hs.HEAD_DIR > -0.03:
        return "head"
    if x < -0.6 and z > 1.12 + (-0.6 - x) * 0.5:
        return "neck"
    if z < 0.9 and x < -0.25:
        return "fore_L" if y < 0 else "fore_R"
    if z < 0.92 and x > 0.25:
        return "hind_L" if y < 0 else "hind_R"
    if n[0] < -0.72 and x < -0.55:
        return "breast"
    if n[0] > 0.72 and x > 0.55:
        return "buttocks"
    return "barrel"


def _leg_axis(region):
    s = -1.0 if region.endswith("_L") else 1.0
    if region.startswith("fore"):
        j = hs.front_leg(s)
        return np.array(j["elbow"]) + np.array([0, 0, 0.05]), np.array(j["toe"]) * np.array([1, 1, 0]) + np.array([0.03, 0, 0])
    j = hs.hind_leg(s)
    return np.array([0.62, s * 0.16, 0.95]), np.array(j["toe"]) * np.array([1, 1, 0]) + np.array([0.04, 0, 0])


def unroll(region, pts):
    """A region's points to (u, v) metres."""
    if region == "barrel":
        along, ang, r = _cyl(pts, (-1.0, 0, BODY_AXIS_Z), (1.0, 0, BODY_AXIS_Z), (0, 0, -1))
        return np.stack([along, ang * 0.3], 1)
    if region in ("breast", "buttocks"):
        s = 1.0 if region == "breast" else -1.0
        return np.stack([pts[:, 1] * s, pts[:, 2]], 1)
    if region == "neck":
        along, ang, r = _cyl(pts, (-0.6, 0, 1.3), (-1.12, 0, 1.95), (0.8, 0, -0.6))
        return np.stack([along, ang * 0.16], 1)
    if region == "head":
        a = np.array([hs.POLL[0], 0.0, hs.POLL[1]])
        along, ang, r = _cyl(pts, a, a + hs.HEAD_DIR, -hs.HEAD_FACE)
        return np.stack([along, ang * 0.1], 1)
    if region.startswith(("fore", "hind")):
        a, b = _leg_axis(region)
        s = -1.0 if region.endswith("_L") else 1.0
        along, ang, r = _cyl(pts, a, b, (0.3, -s, 0.0))
        return np.stack([ang * 0.06, -along], 1)
    if region == "tail":
        along, ang, r = _cyl(pts, (0.9, 0, 1.4), (0.99, 0, 0.5), (0, -1, 0))
        return np.stack([ang * 0.07, -along], 1)
    # The ears: flat, seen from the side.
    return np.stack([pts[:, 0], pts[:, 2]], 1)


CYLINDRICAL = {"barrel", "neck", "head", "fore_L", "fore_R", "hind_L", "hind_R", "tail"}
ARC = {"barrel": 0.3, "neck": 0.16, "head": 0.1, "fore_L": 0.06, "fore_R": 0.06, "hind_L": 0.06, "hind_R": 0.06,
       "tail": 0.07}


def layout(verts, faces, normals, parts, margin_px=8, size=1024):
    """Per-face-corner UVs (a list per face) packed into the unit square, every region at one
    density. `faces`: lists of vertex indices; `parts`: per face, 1 for the tail's hair."""
    V = np.asarray(verts, float)
    regions = {}
    for fi, f in enumerate(faces):
        c = V[f].mean(axis=0)
        regions.setdefault(_region(c, normals[fi], parts[fi]), []).append(fi)
    raw = {}
    for reg, fis in regions.items():
        per = []
        for fi in fis:
            uv = unroll(reg, V[faces[fi]])
            if reg in CYLINDRICAL:
                # A face across the cut takes its low side round by a full turn.
                col = 1 if reg in ("barrel", "neck", "head") else 0
                full = 2 * math.pi * ARC[reg]
                if uv[:, col].max() - uv[:, col].min() > full * 0.5:
                    uv[uv[:, col] < full * 0.5, col] += full
            per.append(uv)
        allp = np.concatenate(per)
        lo = allp.min(axis=0)
        raw[reg] = (per, lo, allp.max(axis=0) - lo)
    # Shelf packing: tallest first, rows across the square, the scale searched so it all fits.
    order = sorted(raw, key=lambda r: -raw[r][2][1])

    def place(scale):
        m = margin_px / size
        x = y = row_h = 0.0
        spots = {}
        for r in order:
            w, h = raw[r][2] * scale
            if x + w + m > 1.0:
                x = 0.0
                y += row_h + m
                row_h = 0.0
            spots[r] = (x + m, y + m)
            x += w + m
            row_h = max(row_h, h)
        return spots, y + row_h + 2 * m

    lo_s, hi_s = 0.01, 2.0
    for _ in range(40):
        mid = (lo_s + hi_s) * 0.5
        _spots, height = place(mid)
        if height <= 1.0:
            lo_s = mid
        else:
            hi_s = mid
    spots, _h = place(lo_s)
    out = [None] * len(faces)
    for reg, (per, lo, _ext) in raw.items():
        ox, oy = spots[reg]
        for fi, uv in zip(regions[reg], per):
            q = (uv - lo) * lo_s + np.array([ox, oy])
            out[fi] = q
    return out, {r: len(v) for r, v in regions.items()}, lo_s * size
