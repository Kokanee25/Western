#!/usr/bin/env python3
"""A Rodin man pushed toward the paintings' stylised realism.

    python3 tools/characters/stylise.py --id=stranger2s

Sean, 2026-10-06, on the Rodin stranger repainted in the style: close, but the style is still a
bit off: the paintings are stylised realism and he's too real. So, as a caricaturist would, his
brow is made heavier and lower, his jaw wider and his chin stronger, his moustache thicker, his
eyes and hands a little bigger (STYLISE's shares), and the fine detail of his skin is smoothed
away (an edge-keeping filter: brows, eyes and moustache keep their edges), before his views are
painted in the style again (head_paint.py) and he's fitted (fit_tripo.py) like any Rodin man.

people.json `<id>`: "source": "rodin", "rodin": the glb this writes (a path under
assets/people/tripo, no .glb), and "stylise": {"from": the Rodin glb it starts from, and any of
STYLISE's keys to change}. It writes a plain glb: his mesh moved, his normals made again, his
colour texture changed; Rodin's normal and roughness maps are left out (nothing of ours reads
them).

His face's landmarks are found once by MediaPipe's face landmarker (tools/paint/align.py's
face_points: pip install mediapipe, apt-get install libegl1 libgles2) on a front view of his head
drawn by head_paint.py, and put back on his mesh through that view's depth. They're kept in
<from>_face.json beside the source, so a run after the first needs no MediaPipe. The numbers in
BROWS, MOUSTACHE and the rest are points of MediaPipe's face mesh (468, and the irises 468-477).
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(ROOT, "tools", "blender"))
sys.path.insert(0, os.path.join(ROOT, "tools", "paint"))
import head_paint as hp  # noqa: E402  (the glb reader, the views and the UV raster)
import fit_tripo as ft  # noqa: E402  (his joints from his shape)

DIR = os.path.join(ROOT, "assets", "people", "tripo")
PEOPLE = os.path.join(ROOT, "assets", "people", "people.json")

# How far each feature is pushed, as shares (0.15: 15 % heavier, wider or bigger); `smooth`, how
# much of his skin's fine detail goes (0 none, 1 all the filter takes).
STYLISE = {"brow": 0.15, "jaw": 0.15, "moustache": 0.2, "eyes": 0.12, "hands": 0.15, "smooth": 1.0}
VIEW_PX = 1024
# MediaPipe face mesh points.
BROWS = [46, 53, 52, 65, 55, 70, 63, 105, 66, 107, 276, 283, 282, 295, 285, 300, 293, 334, 296, 336]
IRISES = (468, 473)
MOUSTACHE = [0, 37, 39, 40, 185, 61, 267, 269, 270, 409, 291, 164, 167, 165, 92, 186, 393, 391, 322,
             410, 2, 97, 326]
CHIN = 152
NOSE_BASE = 2
MOUTH = (61, 291)
CHEEKS = (234, 454)
MIDLINE = (6, 168, 1, 2, 0, 17, 152)


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# ---------------------------------------------------------------- his frame

class Frame:
    """Rodin's axes (facing +Z, his right at -X, his own size) to the one head_paint and
    fit_tripo work in (facing +X, his right at +Z, feet on 0, 1.0 tall, centred), and back."""

    def __init__(self, pos):
        q = self.turn(pos)
        self.y0 = q[:, 1].min()
        self.h = q[:, 1].max() - self.y0
        q = (q - np.array([0.0, self.y0, 0.0])) / self.h
        self.mid = np.array([(q[:, 0].min() + q[:, 0].max()) / 2, 0.0, (q[:, 2].min() + q[:, 2].max()) / 2])

    @staticmethod
    def turn(p):
        return np.stack([p[:, 2], p[:, 1], -p[:, 0]], axis=1)

    @staticmethod
    def unturn(p):
        return np.stack([-p[:, 2], p[:, 1], p[:, 0]], axis=1)

    def to(self, pos):
        return (self.turn(pos) - np.array([0.0, self.y0, 0.0])) / self.h - self.mid

    def back(self, p):
        return self.unturn((p + self.mid) * self.h + np.array([0.0, self.y0, 0.0]))


# ---------------------------------------------------------------- his face's landmarks

def landmarks(P, N, uv, tris, colour, cache):
    """MediaPipe's 478 face points on his mesh (his frame), from the cache when it's there."""
    if os.path.exists(cache):
        return np.array(json.load(open(cache))["points"])
    import align
    htris = hp.head_triangles(P, tris)
    centre, frame = hp.head_frame(P, htris)
    cam = hp.camera(0.0, 0.0)
    img, depth = hp.render_view(P, N, htris, centre, frame, cam, uv, colour, size=VIEW_PX, key=0.25)
    found = align.face_points(img, list(range(478)))
    if found is None:
        raise RuntimeError("MediaPipe found no face on his front view")
    r, u, f = cam
    seen_y, seen_x = np.nonzero(np.isfinite(depth))
    out = []
    for x, y in found:
        d = depth[int(np.clip(y, 0, VIEW_PX - 1)), int(np.clip(x, 0, VIEW_PX - 1))]
        if not np.isfinite(d):
            # Off his outline by a pixel: the nearest pixel of him.
            k = int(np.argmin((seen_x - x) ** 2 + (seen_y - y) ** 2))
            d = depth[seen_y[k], seen_x[k]]
        out.append(centre + (x / VIEW_PX - 0.5) * frame * r + (0.5 - y / VIEW_PX) * frame * u + d * f)
    out = np.array(out)
    json.dump({"note": "MediaPipe's face mesh points on his mesh (stylise.py), in head_paint's frame "
                       "(facing +X, his right at +Z, feet on 0, 1.0 tall)",
               "points": out.round(6).tolist()}, open(cache, "w"), indent=0)
    return out


# ---------------------------------------------------------------- the shape

def push(P, L, j, amount):
    """His points moved toward the paintings' drawing (his frame: front +X, up +Y, right +Z)."""
    P = P.copy()
    s = float(np.linalg.norm(L[CHEEKS[0]] - L[CHEEKS[1]]))     # his face's width
    # Eyes: a little bigger about each iris, in the face's plane.
    for i in IRISES:
        c = L[i]
        w = (1.0 - smoothstep(0.07 * s, 0.16 * s, np.linalg.norm(P - c, axis=1))) * amount["eyes"]
        P[:, 1:] = c[1:] + (P[:, 1:] - c[1:]) * (1.0 + w)[:, None]
    # Jaw: the lower face wider (from nothing at the nose's base to all of it at the mouth and
    # below, gone a little under the chin and behind the cheeks), the chin forward and down.
    zc = float(np.mean(L[list(MIDLINE)][:, 2]))
    y_nose, y_mouth, y_chin = L[NOSE_BASE][1], float(np.mean(L[list(MOUTH)][:, 1])), L[CHIN][1]
    x_side = float(np.mean(L[list(CHEEKS)][:, 0]))
    w = (1.0 - smoothstep(y_mouth, y_nose, P[:, 1])) * smoothstep(y_chin - 0.1 * s, y_chin - 0.02 * s, P[:, 1]) \
        * smoothstep(x_side - 0.25 * s, x_side - 0.05 * s, P[:, 0]) * (1.0 - smoothstep(0.6 * s, 0.8 * s, np.abs(P[:, 2] - zc)))
    P[:, 2] = zc + (P[:, 2] - zc) * (1.0 + amount["jaw"] * w)
    d = np.linalg.norm(P - L[CHIN], axis=1)
    w = np.exp(-0.5 * (d / (0.12 * s)) ** 2) * (d < 0.35 * s)
    P += w[:, None] * amount["jaw"] * s * np.array([0.12, -0.08, 0.0])
    # Moustache: its mass forward and a touch down.
    d = np.min(np.linalg.norm(P[:, None, :] - L[MOUSTACHE][None, :, :], axis=2), axis=1)
    w = np.exp(-0.5 * (d / (0.05 * s)) ** 2) * (d < 0.15 * s)
    P += w[:, None] * amount["moustache"] * s * np.array([0.08, -0.02, 0.0])
    # Brow: forward and lower (the upper lids under it a little hooded with it).
    d = np.min(np.linalg.norm(P[:, None, :] - L[BROWS][None, :, :], axis=2), axis=1)
    w = np.exp(-0.5 * (d / (0.06 * s)) ** 2) * (d < 0.18 * s)
    P += w[:, None] * amount["brow"] * s * np.array([0.17, -0.10, 0.0])
    # Hands: broader and thicker about the line through each wrist (not longer: past his
    # knuckles the fit cuts him for the game's fingers).
    for side, sgn in (("R", 1.0), ("L", -1.0)):
        wrist = j[side + "_Hand"]
        axis = wrist - j[side + "_Forearm"]
        axis /= np.linalg.norm(axis)
        rel = P - wrist
        along = rel @ axis
        radial = rel - along[:, None] * axis
        mine = (along > 0.0) & (along < 0.11) & (np.linalg.norm(radial, axis=1) < 0.035) \
            & (np.sign(P[:, 2]) == sgn)
        w = smoothstep(0.0, 0.012, along) * amount["hands"] * mine
        P = np.where(mine[:, None], wrist + along[:, None] * axis + radial * (1.0 + w)[:, None], P)
    return P, s


def normals(P, tris):
    """Vertex normals again: area-weighted faces, the same at every copy of a point (Rodin splits
    points along UV seams, so his shading has no seams)."""
    fn = np.cross(P[tris[:, 1]] - P[tris[:, 0]], P[tris[:, 2]] - P[tris[:, 0]])
    acc = np.zeros_like(P)
    for k in range(3):
        np.add.at(acc, tris[:, k], fn)
    _, same = np.unique(np.round(P, 6), axis=0, return_inverse=True)
    same = same.ravel()
    welded = np.zeros((same.max() + 1, 3))
    np.add.at(welded, same, acc)
    n = welded[same]
    return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)


# ---------------------------------------------------------------- the texture

def box(a, r):
    """The mean over a (2r+1)^2 window, edges held."""
    p = np.pad(a.astype(np.float64), ((r + 1, r), (r + 1, r)), mode="edge")
    c = p.cumsum(0).cumsum(1)
    n = 2 * r + 1
    return (c[n:, n:] - c[:-n, n:] - c[n:, :-n] + c[:-n, :-n]) / (n * n)


def edge_keeping(a, r, eps):
    """Each channel smoothed by itself as the guide (the guided filter: He, Sun and Tang, "Guided
    Image Filtering", ECCV 2010): flat where it's nearly flat, its edges kept."""
    out = np.empty_like(a)
    for c in range(a.shape[2]):
        i = a[..., c]
        m = box(i, r)
        v = box(i * i, r) - m * m
        k = v / (v + eps)
        out[..., c] = box(k, r) * i + box(m - k * m, r)
    return out


def texel_points(P, uv, tris, size):
    """Every texel of these triangles' UV islands: rows, columns and his point there."""
    tri_id, bary = hp.uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = P[t[:, 0]] * b[:, :1] + P[t[:, 1]] * b[:, 1:2] + P[t[:, 2]] * b[:, 2:3]
    return ty, tx, p


def texels_per_unit(P, uv, tris, size):
    a3 = 0.5 * np.linalg.norm(np.cross(P[tris[:, 1]] - P[tris[:, 0]], P[tris[:, 2]] - P[tris[:, 0]]), axis=1).sum()
    e1, e2 = uv[tris[:, 1]] - uv[tris[:, 0]], uv[tris[:, 2]] - uv[tris[:, 0]]
    a2 = 0.5 * np.abs(e1[:, 0] * e2[:, 1] - e1[:, 1] * e2[:, 0]).sum() * size ** 2
    return float(np.sqrt(a2 / a3))


def repaint_skin(P0, uv, tris, colour, L, j, s, amount):
    """His texture with the fine detail of his face's and hands' skin smoothed away and his
    moustache grown: where (on his mesh as Rodin made it) his face and hands are, skin-coloured."""
    from scipy import ndimage
    size = colour.width
    rgb = np.asarray(colour.convert("RGB"), dtype=np.float32) / 255.0
    htris = hp.head_triangles(P0, tris)
    hand = np.zeros(len(P0), dtype=bool)
    for side in ("R", "L"):
        hand |= np.linalg.norm(P0 - j[side + "_Hand"], axis=1) < 0.08
    ttris = np.concatenate([htris, tris[hand[tris].all(axis=1)]])
    ty, tx, p = texel_points(P0, uv, ttris, size)
    # His face below the hat and his hands; skin by its colour (warm, neither dark hair nor felt).
    face = (np.linalg.norm(p - L[1], axis=1) < 0.75 * s) & (p[:, 1] < L[BROWS][:, 1].max() + 0.18 * s)
    on_hand = np.zeros(len(p), dtype=bool)
    for side in ("R", "L"):
        on_hand |= np.linalg.norm(p - j[side + "_Hand"], axis=1) < 0.08
    c = rgb[ty, tx]
    # Skin: light enough and red over green over blue (his brown coat and felt are darker).
    warm = (c @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32) > 0.28) & (c[:, 0] > c[:, 1]) \
        & (c[:, 1] > c[:, 2]) & (c[:, 0] - c[:, 2] > 0.08)
    skin = np.zeros((size, size), dtype=np.float32)
    keep = (face | on_hand) & warm
    skin[ty[keep], tx[keep]] = 1.0
    skin = ndimage.gaussian_filter(skin, 2.0)
    tpu = texels_per_unit(P0, uv, htris, size)
    out = rgb.copy()
    if amount["smooth"] > 0:
        # The window: about 2.5 mm on him; eps: how big a change still counts as detail.
        r = max(2, int(round(0.018 * s * tpu)))
        y0, y1 = max(ty.min() - 2 * r, 0), min(ty.max() + 2 * r + 1, size)
        x0, x1 = max(tx.min() - 2 * r, 0), min(tx.max() + 2 * r + 1, size)
        flat = edge_keeping(rgb[y0:y1, x0:x1], r, 0.004)
        k = (skin[y0:y1, x0:x1] * amount["smooth"])[..., None]
        out[y0:y1, x0:x1] = rgb[y0:y1, x0:x1] * (1 - k) + flat * k
    if amount["moustache"] > 0:
        # Thicker: its hair (dark and not red, between the nose's base and the mouth: not the
        # nostrils or the lips' line, which are dark too) grown into the skin round it by its share
        # of a moustache's depth, in the hair's own mean colour.
        lum_all = rgb @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
        near = np.min(np.linalg.norm(p[:, None, :] - L[MOUSTACHE][None, :, :], axis=2), axis=1) < 0.12 * s
        zone = near & (p[:, 1] < L[NOSE_BASE][1] - 0.01 * s)
        cz = out[ty, tx]
        hair = zone & (lum_all[ty, tx] < 0.16) & (cz[:, 0] - cz[:, 1] < 0.06)
        rho = max(1, int(round(amount["moustache"] * 0.06 * s * tpu)))
        mask = np.zeros((size, size), dtype=bool)
        mask[ty[hair], tx[hair]] = True
        allowed = np.zeros((size, size), dtype=bool)
        allowed[ty[zone], tx[zone]] = True
        disk = np.hypot(*np.mgrid[-rho:rho + 1, -rho:rho + 1]) <= rho
        grown = ndimage.binary_dilation(mask, structure=disk) & allowed & ~mask
        if hair.any():
            out[grown] = out[ty[hair], tx[hair]].mean(axis=0)
        print("  moustache: %d texels of hair grown by %d into %d more" % (int(hair.sum()), rho, int(grown.sum())))
    print("  skin smoothed over %d texels (window %d)" % (int((skin > 0.5).sum()), max(2, int(round(0.018 * s * tpu)))))
    return Image.fromarray(np.clip(out * 255.0 + 0.5, 0, 255).astype(np.uint8))


# ---------------------------------------------------------------- the glb

def write_glb(path, pos, nrm, uv, tris, colour):
    """A plain glb: one mesh, one material with its colour texture (PNG)."""
    png = io.BytesIO()
    colour.save(png, "PNG")
    blobs = [pos.astype(np.float32).tobytes(), nrm.astype(np.float32).tobytes(), uv.astype(np.float32).tobytes(),
             tris.astype(np.uint32).ravel().tobytes(), png.getvalue()]
    data, views = b"", []
    for k, b in enumerate(blobs):
        data += b"\0" * (-len(data) % 4)
        view = {"buffer": 0, "byteOffset": len(data), "byteLength": len(b)}
        if k < 3:
            view["target"] = 34962
        elif k == 3:
            view["target"] = 34963
        views.append(view)
        data += b
    data += b"\0" * (-len(data) % 4)
    n = len(pos)
    doc = {"asset": {"version": "2.0", "generator": "Salt Creek tools/characters/stylise.py"},
           "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "model", "mesh": 0}],
           "meshes": [{"name": "model", "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
                                                         "indices": 3, "material": 0}]}],
           "materials": [{"name": "model", "doubleSided": True,
                          "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0,
                                                   "roughnessFactor": 1.0}}],
           "textures": [{"source": 0}], "images": [{"bufferView": 4, "mimeType": "image/png"}],
           "buffers": [{"byteLength": len(data)}], "bufferViews": views,
           "accessors": [{"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3",
                          "min": pos.min(axis=0).astype(float).tolist(), "max": pos.max(axis=0).astype(float).tolist()},
                         {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
                         {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
                         {"bufferView": 3, "componentType": 5125, "count": int(tris.size), "type": "SCALAR"}]}
    text = json.dumps(doc, separators=(",", ":")).encode()
    text += b" " * (-len(text) % 4)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(text) + 8 + len(data)))
        f.write(struct.pack("<I4s", len(text), b"JSON") + text)
        f.write(struct.pack("<I4s", len(data), b"BIN\0") + data)


# ---------------------------------------------------------------- run

def stylise(pid):
    spec = json.load(open(PEOPLE))["people"][pid]
    st = spec["stylise"]
    amount = dict(STYLISE, **{k: v for k, v in st.items() if k in STYLISE})
    src = os.path.join(DIR, st["from"] + ".glb")
    pos, nrm, uv, tris, colour = hp.load_glb(src)
    frame = Frame(pos)
    P0, N0 = frame.to(pos), Frame.turn(nrm)
    print("%s from %s: %d points, %d triangles, texture %d^2" % (pid, st["from"], len(pos), len(tris), colour.width))
    L = landmarks(P0, N0, uv, tris, colour, os.path.join(DIR, st["from"] + "_face.json"))
    j = ft.find_joints(P0, tris)
    P, s = push(P0, L, j, amount)
    moved = np.linalg.norm(P - P0, axis=1)
    print("  face %.3f of his height across; %d points moved, the most by %.1f%% of his face's width" %
          (s, int((moved > 1e-6).sum()), 100.0 * moved.max() / s))
    texture = repaint_skin(P0, uv, tris, colour, L, j, s, amount)
    out = os.path.join(DIR, spec["rodin"] + ".glb")
    write_glb(out, frame.back(P), Frame.unturn(normals(P, tris)), uv, tris, texture)
    print("wrote", out)


def main():
    pid = "stranger2s"
    for a in sys.argv[1:]:
        if a.startswith("--id="):
            pid = a.split("=", 1)[1]
    stylise(pid)


if __name__ == "__main__":
    main()
