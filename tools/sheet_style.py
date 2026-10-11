#!/usr/bin/env python3
"""The character-sheet style trial (Prompt 07 territory, 2026-10-11; target
docs/concept/style_candidates/character_sheet.png): a realistic model whose TEXTURES are cut into
squares of a fixed real size, drawn nearest, lit by ordinary smooth light that runs across the
squares. No post filter. Behind `--sheet-style` on any run (Settings, src/art/sheet_style.gd);
nothing here changes the game's defaults.

    python3 tools/sheet_style.py man [--face-mm=3 --hat-mm=6 --body-mm=7 --push=1 --even=0 --jitter=0 --source=rodin|repaint --id=stranger2]
    python3 tools/sheet_style.py world [--world-push=1]
    python3 tools/sheet_style.py painted|real [--ids=stranger2s,kid]   (the style lab's B and C)
    python3 tools/sheet_style.py sheet [--ids=stranger2s,kid]          (the style lab's D: patches, as the sheet)

Writes into build/sheet_style/ (gitignored, remade from what's committed; a .gdignore keeps the
editor from importing it, the game reads it with Image.load_from_file):
  man:   <id>_albedo.png  his own Rodin colour (not the repaint), cut into squares in his body's
         space (cubes in his body's axes, one set per way the surface faces, each the MEAN of the
         texels in it: a downsample, not a pick), face FACE_MM, hat and hair HAT_MM, the rest
         BODY_MM (--push=G: each square's colour pushed away from the mean of the squares round
         it by G, head_paint._mosaic's rule: the sheet's neighbours differ more than a downsample's;
         --even=E: E of the light baked into his skin taken out first, head_paint.even_skin;
         --jitter=J: each square's lightness scaled by 1 + J x a seeded normal, the
         sheet's mosaic of distinct shades, which a plain downsample doesn't give); <id>_normal.png his Rodin normal map, smooth (only resized to the albedo's size).
         Both in the fitted glb's UVs (fit_tripo.py keeps Rodin's).
  world: textures/<key>.png  the texture factory's smooth set (assets/textures/smooth/, 128 texels
         a metre, no palette) box-averaged to 32 texels a metre (textures16/: 16).
"""
import io
import json
import os
import struct
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools", "characters"))
import head_paint as hp  # noqa: E402  (his mesh in body space, the UV raster, his face landmarks)

OUT = os.path.join(ROOT, "build", "sheet_style")
FACE_MM, HAT_MM, BODY_MM = 3.0, 6.0, 7.0
SIZE = 2048
# Round his face's landmarks: this far past their box counts as face (ears, jaw, brow under the brim).
FACE_MARGIN_M = 0.02
SMOOTH_TEXELS = 128


def _glb_textures(path):
    """The first material's base colour and normal map as PIL images (either may be None)."""
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    binary = f[28 + clen:]

    def image(tex_ref):
        if not tex_ref:
            return None
        img = doc["images"][doc["textures"][tex_ref["index"]]["source"]]
        bv = doc["bufferViews"][img["bufferView"]]
        o = bv.get("byteOffset", 0)
        return Image.open(io.BytesIO(binary[o:o + bv["byteLength"]])).convert("RGB")

    mat = doc["materials"][0]
    return image(mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")), image(mat.get("normalTexture"))


# The style lab's candidates (docs/briefs/style-lab.md): B "painted", the game's own painted
# textures as they are; C "real", the models' own realistic colour. Both with the models' normal
# maps (a stylised Rodin man's from the model he was stylised from: the same UVs).
def candidate(cand, cid):
    spec = json.load(open(hp.PEOPLE))["people"][cid]
    src = spec.get("rodin") or spec.get("model") or cid
    colour, normal = _glb_textures(os.path.join(hp.DIR, src + ".glb"))
    if normal is None and "stylise" in spec:
        normal = _glb_textures(os.path.join(hp.DIR, spec["stylise"]["from"] + ".glb"))[1]
    out = os.path.join(OUT, cand)
    os.makedirs(out, exist_ok=True)
    shapes = {"skin": (colour, normal), "head": (colour, normal)}
    for shape, piece in (spec.get("pieces") or {}).items():
        shapes[shape] = _glb_textures(os.path.join(hp.DIR, piece + ".glb"))
    for shape, (col, nrm) in shapes.items():
        # His head is in the same atlas as his skin (the game's _head and _skin are one picture):
        # SheetStyle falls back to the skin's, so it's written and loaded once.
        if shape == "head":
            continue
        if cand == "painted":
            col = Image.open(os.path.join(ROOT, "assets", "people", "%s_%s.png" % (cid, shape))).convert("RGB")
        if col is not None:
            col.save(os.path.join(out, "%s_%s_albedo.png" % (cid, shape)))
        if nrm is not None:
            size = col.size if col is not None else nrm.size
            nrm.resize(size, Image.LANCZOS).save(os.path.join(out, "%s_%s_normal.png" % (cid, shape)))
        print("%s %s %s: albedo %s, normal %s" % (cand, cid, shape, col.size if col else None, "yes" if nrm else "no"))


# The style lab's D, "sheet" (docs/briefs/style-lab.md; Sean: "let's see if we can get it closer
# to the sheet"). Up close the sheet's man isn't cut into squares: his realistic texture is broken
# into irregular flat patches, each one tone, a few millimetres on his face and about a centimetre
# on his clothes, the patches mottled (each a shade off its neighbours), his eyes and lips left
# fine; only the ground is laid in square blocks. So: Voronoi cells round seeds jittered on a grid
# in his body's space (one set per way a surface faces, so a brim's top and underside don't mix),
# each cell the mean of his own colour in it, its lightness jittered; his eyes kept as they are.
SHEET_FACE_MM, SHEET_HEAD_MM, SHEET_BODY_MM = 6.0, 9.0, 14.0
SHEET_JITTER = 0.07
# Each patch pushed away from the mean of the patches round it (a Voronoi of SHEET_AROUND times
# the size): the sheet's patches differ far more than a mean of a realistic texture does.
SHEET_PUSH = 1.8
SHEET_AROUND = 3.0
SHEET_EYE_KEEP_M = 0.012
# The world (all at 128 a metre, the smooth set's own): walls and timber in patches of
# SHEET_WORLD_CELL texels (3 cm), the road in square blocks of SHEET_ROAD_BLOCK texels (6 cm).
SHEET_WORLD_CELL = 4
SHEET_ROAD_BLOCK = 8
SHEET_ROAD_KEYS = ("road", "road_wide")


def _hash01(g, salt):
    """Seeded floats in [0, 1) for integer cells (rows of g), one per salt."""
    h = (g[:, 0] * 73856093) ^ (g[:, 1] * 19349663) ^ (g[:, 2] * 83492791) ^ (salt * 2654435761)
    h = (h ^ (h >> 13)) * 1274126177
    return ((h ^ (h >> 16)) & 0xFFFFFF).astype(np.float64) / float(0x1000000)


def _voronoi(P, size):
    """Each point's cell (an int64 label per row of P, points in metres) among seeds jittered on a
    grid of `size` metres: the nearest of the 27 seeds round it."""
    g = np.floor(P / size).astype(np.int64)
    best = np.full(len(P), np.inf)
    cell = np.zeros((len(P), 3), dtype=np.int64)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                c = g + np.array([dx, dy, dz])
                seed = (c + 0.5 + 0.8 * (np.stack([_hash01(c, s) for s in (1, 2, 3)], axis=1) - 0.5)) * size
                d = ((P - seed) ** 2).sum(axis=1)
                closer = d < best
                best[closer] = d[closer]
                cell[closer] = c[closer]
    return cell


def _patches(rgb, P, faces, size_m, keep):
    """rgb (N x 3, 0..255) as patches: each point its Voronoi cell's mean in linear light, the
    lightness jittered a cell at a time; points in `keep` as they were."""
    out = rgb.copy()
    lin = (rgb / 255.0) ** 2.2
    for size in np.unique(size_m[~keep]):
        sel = np.nonzero((size_m == size) & ~keep)[0]
        cell = _voronoi(P[sel], size)
        key = np.concatenate([cell, faces[sel, None]], axis=1)
        _k, lab = np.unique(key, axis=0, return_inverse=True)
        lab = lab.ravel()
        k = int(lab.max()) + 1
        count = np.bincount(lab, minlength=k).astype(np.float64)
        mean = np.stack([np.bincount(lab, lin[sel, c], minlength=k) for c in range(3)], axis=1) / count[:, None]
        cells = np.zeros((k, 3), dtype=np.int64)
        cells[lab] = cell
        if SHEET_PUSH != 1.0:
            big = _voronoi(P[sel], size * SHEET_AROUND)
            _bk, blab = np.unique(np.concatenate([big, faces[sel, None]], axis=1), axis=0, return_inverse=True)
            blab = blab.ravel()
            bk = int(blab.max()) + 1
            bcount = np.bincount(blab, minlength=bk).astype(np.float64)
            bmean = np.stack([np.bincount(blab, lin[sel, c], minlength=bk) for c in range(3)], axis=1) / bcount[:, None]
            # Each patch against the surround its middle point falls in, in gamma (as the eye sees it).
            around = np.zeros((k, 3))
            around[lab] = bmean[blab]
            g, ga = mean ** (1 / 2.2), np.clip(around, 0.0, 1.0) ** (1 / 2.2)
            mean = np.clip(ga + (g - ga) * SHEET_PUSH, 0.0, 1.0) ** 2.2
        mean *= np.clip(1.0 + SHEET_JITTER * 2.0 * (_hash01(cells, 7 + int(size * 1e4)) - 0.5) * 1.7, 0.6, 1.4)[:, None]
        out[sel] = np.clip(mean[lab], 0.0, 1.0) ** (1 / 2.2) * 255.0
    return out


def _sheet_shape(pos, nrm, uv, tris, colour, size, size_of, keep_of):
    """One mesh's colour (in its UVs, at `size` texels) cut into patches; size_of(p) and keep_of(p)
    give each point's patch size in metres and whether it's kept (p in metres)."""
    base = np.asarray(colour.resize((size, size), Image.LANCZOS), dtype=np.float64).copy()
    tri_id, bary = hp.uv_raster(uv, tris, size)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    n = nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3]
    axis = np.abs(n).argmax(axis=1)
    faces = axis * 2 + (n[np.arange(len(n)), axis] > 0)
    base[ty, tx] = _patches(base[ty, tx], p, faces, size_of(p), keep_of(p))
    return Image.fromarray(np.clip(base, 0, 255).astype(np.uint8)), len(ty)


def sheet_man(cid):
    spec = json.load(open(hp.PEOPLE))["people"][cid]
    out = os.path.join(OUT, "sheet")
    os.makedirs(out, exist_ok=True)
    if spec.get("source") == "rodin":
        pos, nrm, uv, tris, colour = hp.load_man(cid)
        normal = _glb_textures(os.path.join(hp.DIR, spec["rodin"] + ".glb"))[1]
        if normal is None and "stylise" in spec:
            normal = _glb_textures(os.path.join(hp.DIR, spec["stylise"]["from"] + ".glb"))[1]
    else:
        pos, nrm, uv, tris, colour = hp.load_glb(os.path.join(hp.DIR, spec.get("model", cid) + ".glb"))
        normal = _glb_textures(os.path.join(hp.DIR, spec.get("model", cid) + ".glb"))[1]
        y0, y1 = pos[:, 1].min(), pos[:, 1].max()
        pos = (pos - np.array([0.0, y0, 0.0])) / (y1 - y0)
    P_scale = hp.HEIGHT_M
    cut = hp.HEAD_FROM * P_scale
    face = hp.face_points(cid)
    eyes = []
    lo = hi = None
    if face is not None:
        eyes = [face[ring].mean(axis=0) * P_scale for ring in hp.IRIS_RINGS]
        m = FACE_MARGIN_M
        lo, hi = face.min(axis=0) * P_scale - m, face.max(axis=0) * P_scale + m

    def size_of(P):
        s = np.full(len(P), SHEET_BODY_MM / 1000.0)
        s[P[:, 1] > cut] = SHEET_HEAD_MM / 1000.0
        if lo is not None:
            s[(P >= lo).all(axis=1) & (P <= hi).all(axis=1)] = SHEET_FACE_MM / 1000.0
        return s

    def keep_of(P):
        k = np.zeros(len(P), dtype=bool)
        for e in eyes:
            k |= ((P - e) ** 2).sum(axis=1) < SHEET_EYE_KEEP_M ** 2
        return k

    size = 2048 if colour.width >= 2048 else colour.width
    img, n = _sheet_shape(pos * P_scale, nrm, uv, tris, colour, size, size_of, keep_of)
    img.save(os.path.join(out, "%s_skin_albedo.png" % cid))
    if normal is not None:
        normal.resize(img.size, Image.LANCZOS).save(os.path.join(out, "%s_skin_normal.png" % cid))
    print("sheet %s skin: %d texels, face %s, eyes kept %d" % (cid, n, "found" if face is not None else "none", len(eyes)))
    for shape, piece in (spec.get("pieces") or {}).items():
        ppos, pnrm, puv, ptris, pcol = hp.load_glb(os.path.join(hp.DIR, piece + ".glb"))
        pnorm = _glb_textures(os.path.join(hp.DIR, piece + ".glb"))[1]
        # A piece is modelled at a size of its own: a hat's widest span taken as 0.4 m.
        ext = (ppos.max(axis=0) - ppos.min(axis=0)).max()
        P = (ppos - ppos.min(axis=0)) * (0.4 / ext)
        psize = min(pcol.width, 1024)
        img, n = _sheet_shape(P, pnrm, puv, ptris, pcol, psize,
                              lambda q: np.full(len(q), SHEET_HEAD_MM / 1000.0), lambda q: np.zeros(len(q), dtype=bool))
        img.save(os.path.join(out, "%s_%s_albedo.png" % (cid, shape)))
        if pnorm is not None:
            pnorm.resize(img.size, Image.LANCZOS).save(os.path.join(out, "%s_%s_normal.png" % (cid, shape)))
        print("sheet %s %s: %d texels" % (cid, shape, n))


def _tile_patches(a, cell):
    """A seamless texture (H x W x 3, linear) in Voronoi patches of about `cell` texels, the seeds
    on a grid that wraps, so the tile stays seamless; each patch its mean, lightness jittered."""
    h, w = a.shape[:2]
    gw, gh = max(int(round(w / cell)), 1), max(int(round(h / cell)), 1)
    sx, sy = w / gw, h / gh
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64) + 0.5
    gx, gy = np.floor(xx / sx).astype(np.int64), np.floor(yy / sy).astype(np.int64)
    best = np.full((h, w), np.inf)
    lab = np.zeros((h, w), dtype=np.int64)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            cx, cy = gx + dx, gy + dy
            wx, wy = cx % gw, cy % gh
            g = np.stack([wx.ravel(), wy.ravel(), np.zeros(wx.size, dtype=np.int64)], axis=1)
            jx = _hash01(g, 1).reshape(h, w)
            jy = _hash01(g, 2).reshape(h, w)
            seed_x = (cx + 0.5 + 0.8 * (jx - 0.5)) * sx
            seed_y = (cy + 0.5 + 0.8 * (jy - 0.5)) * sy
            d = (xx - seed_x) ** 2 + (yy - seed_y) ** 2
            closer = d < best
            best[closer] = d[closer]
            lab[closer] = (wy * gw + wx)[closer]
    k = gw * gh
    flat = lab.ravel()
    count = np.maximum(np.bincount(flat, minlength=k), 1).astype(np.float64)
    mean = np.stack([np.bincount(flat, a[..., c].ravel(), minlength=k) for c in range(3)], axis=1) / count[:, None]
    g = np.stack([np.arange(k) % gw, np.arange(k) // gw, np.zeros(k, dtype=np.int64)], axis=1)
    if SHEET_PUSH != 1.0:
        # Against the patches round it (the 3 x 3 of the seed grid), in gamma.
        grid = (mean ** (1 / 2.2)).reshape(gh, gw, 3)
        around = sum(np.roll(np.roll(grid, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) / 9.0
        mean = (np.clip(around + (grid - around) * SHEET_PUSH, 0.0, 1.0) ** 2.2).reshape(k, 3)
    mean *= np.clip(1.0 + SHEET_JITTER * 1.7 * 2.0 * (_hash01(g, 9) - 0.5), 0.6, 1.4)[:, None]
    return mean[flat].reshape(h, w, 3)


def _blocks(a, block):
    """Square blocks of `block` texels, each its mean, lightness jittered (the sheet's ground)."""
    h, w = a.shape[:2]
    bh, bw = max(h // block, 1), max(w // block, 1)
    m = a[:bh * block, :bw * block].reshape(bh, block, bw, block, 3).mean(axis=(1, 3))
    g = np.stack([np.tile(np.arange(bw), bh), np.repeat(np.arange(bh), bw), np.zeros(bh * bw, dtype=np.int64)], axis=1)
    m *= np.clip(1.0 + SHEET_JITTER * 1.7 * 2.0 * (_hash01(g, 11) - 0.5), 0.6, 1.4).reshape(bh, bw)[..., None]
    return np.repeat(np.repeat(m, block, axis=0), block, axis=1)


def sheet_world():
    """Every factory key at 128 a metre into sheet/textures/: the smooth set where it has the key
    (realistic paintings, uncut), else the drawn woods and the factory tiles nearest-scaled up from
    32 a metre; then patches (or the road's blocks)."""
    root = os.path.join(ROOT, "assets", "textures")
    dst = os.path.join(OUT, "sheet", "textures")
    os.makedirs(dst, exist_ok=True)
    sources = {}
    for sub, scale in (("", 4), ("drawn", 4), ("smooth", 1)):
        d = os.path.join(root, sub)
        for name in os.listdir(d):
            if name.endswith(".png") and not name.startswith(("flames", "doorway", "poster", "backdrop")):
                sources[name] = (os.path.join(d, name), scale)
    for name, (path, scale) in sorted(sources.items()):
        img = Image.open(path).convert("RGB")
        if scale != 1:
            img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        a = (np.asarray(img, dtype=np.float64) / 255.0) ** 2.2
        key = name[:-4]
        if key.split("_b")[0] in SHEET_ROAD_KEYS or key in SHEET_ROAD_KEYS:
            a = _blocks(a, SHEET_ROAD_BLOCK)
        elif not key.startswith("sign_"):
            a = _tile_patches(a, SHEET_WORLD_CELL)
        a = np.clip(a, 0.0, 1.0) ** (1 / 2.2)
        Image.fromarray((a * 255.0).astype(np.uint8)).save(os.path.join(dst, name))
    print("sheet world: %d textures at 128 texels a metre in %s" % (len(sources), os.path.relpath(dst, ROOT)))


def _glb_images(path):
    f = open(path, "rb").read()
    clen = struct.unpack("<I", f[12:16])[0]
    doc = json.loads(f[20:20 + clen])
    binary = f[28 + clen:]
    out = {}
    for img in doc["images"]:
        bv = doc["bufferViews"][img["bufferView"]]
        o = bv.get("byteOffset", 0)
        out[img.get("name", "")] = Image.open(io.BytesIO(binary[o:o + bv["byteLength"]])).convert("RGB")
    return out


def man(cid, face_mm, hat_mm, body_mm, jitter=0.0, push=1.0, even=0.0, source="rodin"):
    spec = json.load(open(hp.PEOPLE))["people"][cid]
    pos, nrm, uv, tris, colour = hp.load_man(cid)
    if source == "repaint":
        # His style repaint (head_paint.py's bake, already in its own squares) in place of Rodin's
        # colour: the same UVs; only the light and the normal map change. No squares of ours.
        colour = Image.open(os.path.join(hp.DIR, cid + "_color.png")).convert("RGB")
        face_mm = hat_mm = body_mm = 0.0
    images = _glb_images(os.path.join(hp.DIR, spec["rodin"] + ".glb"))
    normal = images.get("texture_normal")
    base = colour.resize((SIZE, SIZE), Image.LANCZOS)
    rgb_img = np.asarray(base, dtype=np.float64).copy()
    tri_id, bary = hp.uv_raster(uv, tris, SIZE)
    ty, tx = np.nonzero(tri_id >= 0)
    t = tris[tri_id[ty, tx]]
    b = bary[ty, tx]
    p = pos[t[:, 0]] * b[:, :1] + pos[t[:, 1]] * b[:, 1:2] + pos[t[:, 2]] * b[:, 2:3]
    n = nrm[t[:, 0]] * b[:, :1] + nrm[t[:, 1]] * b[:, 1:2] + nrm[t[:, 2]] * b[:, 2:3]
    axis = np.abs(n).argmax(axis=1)
    faces = axis * 2 + (n[np.arange(len(n)), axis] > 0)
    y0, y1 = pos[:, 1].min(), pos[:, 1].max()
    cut = y0 + (y1 - y0) * hp.HEAD_FROM
    if even > 0.0:
        # The light Rodin baked into his skin taken out first (head_paint's bake.skin: that share
        # of it, his skin 4 degrees towards yellow), so the game's light is the only light on him.
        hp.even_skin(rgb_img, cid, pos, nrm, uv, tris, SIZE, cut, {"even": even, "hue": 4.0})
    if body_mm <= 0.0:
        _save(cid, rgb_img, normal)
        print("%s: his repaint as it is, with his normal map" % cid)
        return
    size_m = np.full(len(p), body_mm / 1000.0)
    head = p[:, 1] > cut
    size_m[head] = hat_mm / 1000.0
    face = hp.face_points(cid)
    zone = np.zeros(len(p), dtype=bool)
    if face is not None:
        m = FACE_MARGIN_M / hp.HEIGHT_M
        lo, hi = face.min(axis=0) - m, face.max(axis=0) + m
        zone = head & (p >= lo).all(axis=1) & (p <= hi).all(axis=1)
        size_m[zone] = face_mm / 1000.0
    q = np.floor(p * hp.HEIGHT_M / size_m[:, None]).astype(np.int64)
    # Cells of different sizes never share a key (the size is in it).
    key = np.concatenate([q, faces[:, None], np.round(size_m * 1e4)[:, None].astype(np.int64)], axis=1)
    _k, lab = np.unique(key, axis=0, return_inverse=True)
    lab = lab.ravel()
    k = int(lab.max()) + 1
    rgb = rgb_img[ty, tx]
    # The mean in linear light, as a downsample would.
    lin = (rgb / 255.0) ** 2.2
    count = np.bincount(lab, minlength=k).astype(np.float64)
    mean = np.stack([np.bincount(lab, lin[:, c], minlength=k) for c in range(3)], axis=1) / count[:, None]
    if push != 1.0:
        # head_paint._mosaic's rule, one square size at a time (each size is its own grid): its
        # keys are the cube and the facing.
        cell_q = np.zeros((k, 3), dtype=np.int64)
        cell_q[lab] = q
        cell_face = np.zeros(k, dtype=np.int64)
        cell_face[lab] = faces
        cell_size = np.zeros(k)
        cell_size[lab] = size_m
        for size in np.unique(cell_size):
            sel = np.nonzero(cell_size == size)[0]
            keys = np.concatenate([cell_q[sel], cell_face[sel, None], np.zeros((len(sel), 1), dtype=np.int64)], axis=1)
            mean[sel] = hp._mosaic(mean[sel] * 255.0, count[sel], keys, np.full(len(sel), push)) / 255.0
    if jitter > 0.0:
        mean *= np.clip(1.0 + jitter * np.random.default_rng(1882).standard_normal(k), 0.5, 1.5)[:, None]
    rgb_img[ty, tx] = (np.clip(mean[lab], 0.0, 1.0) ** (1 / 2.2)) * 255.0
    _save(cid, rgb_img, normal)
    print("%s: %d texels in %d squares (face %.0f mm: %d texels, hat %.0f, body %.0f)" % (
        cid, len(lab), k, face_mm, zone.sum(), hat_mm, body_mm))


def _save(cid, rgb_img, normal):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(rgb_img, 0, 255).astype(np.uint8)).save(os.path.join(OUT, cid + "_albedo.png"))
    if normal is not None:
        normal.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, cid + "_normal.png"))


def world(push=1.0):
    src = os.path.join(ROOT, "assets", "textures", "smooth")
    for texels, sub in ((32, "textures"), (16, "textures16")):
        f = SMOOTH_TEXELS // texels
        dst = os.path.join(OUT, sub)
        os.makedirs(dst, exist_ok=True)
        n = 0
        for name in sorted(os.listdir(src)):
            if not name.endswith(".png"):
                continue
            img = Image.open(os.path.join(src, name)).convert("RGB")
            w, h = max(img.width // f, 1), max(img.height // f, 1)
            a = (np.asarray(img.crop((0, 0, w * f, h * f)), dtype=np.float64) / 255.0) ** 2.2
            a = a.reshape(h, f, w, f, 3).mean(axis=(1, 3))
            if push != 1.0 and texels <= 16:
                around = sum(np.roll(np.roll(a, dy, 0), dx, 1) for dy in (-1, 0, 1) for dx in (-1, 0, 1)) / 9.0
                a = np.clip(around + (a - around) * push, 0.0, 1.0)
            a = a ** (1 / 2.2)
            Image.fromarray(np.clip(a * 255.0, 0, 255).astype(np.uint8)).save(os.path.join(dst, name))
            n += 1
        print("world: %d textures at %d texels a metre in %s" % (n, texels, os.path.relpath(dst, ROOT)))


def main():
    os.makedirs(OUT, exist_ok=True)
    open(os.path.join(OUT, ".gdignore"), "w").close()
    args = sys.argv[1:]
    opt = {a.split("=")[0]: a.split("=", 1)[1] for a in args if "=" in a}
    if "man" in args:
        man(opt.get("--id", "stranger2"), float(opt.get("--face-mm", FACE_MM)), float(opt.get("--hat-mm", HAT_MM)),
            float(opt.get("--body-mm", BODY_MM)), float(opt.get("--jitter", 0.0)), float(opt.get("--push", 1.0)),
            float(opt.get("--even", 0.0)), opt.get("--source", "rodin"))
    for cand in ("painted", "real"):
        if cand in args:
            for cid in opt.get("--ids", "stranger2s,kid").split(","):
                candidate(cand, cid)
    if "world" in args:
        world(float(opt.get("--world-push", 1.0)))
    if "sheet" in args:
        for cid in opt.get("--ids", "stranger2s,kid").split(","):
            sheet_man(cid)
        sheet_world()
    if not ({"man", "world", "painted", "real", "sheet"} & set(args)):
        print(__doc__)


if __name__ == "__main__":
    main()
