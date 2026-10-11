#!/usr/bin/env python3
"""The character-sheet style trial (Prompt 07 territory, 2026-10-11; target
docs/concept/style_candidates/character_sheet.png): a realistic model whose TEXTURES are cut into
squares of a fixed real size, drawn nearest, lit by ordinary smooth light that runs across the
squares. No post filter. Behind `--sheet-style` on any run (Settings, src/art/sheet_style.gd);
nothing here changes the game's defaults.

    python3 tools/sheet_style.py man [--face-mm=3 --hat-mm=6 --body-mm=7 --push=1 --even=0 --jitter=0 --source=rodin|repaint --id=stranger2]
    python3 tools/sheet_style.py world [--world-push=1]
    python3 tools/sheet_style.py painted|real [--ids=stranger2s,kid]   (the style lab's B and C)

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
    if not ({"man", "world", "painted", "real"} & set(args)):
        print(__doc__)


if __name__ == "__main__":
    main()
