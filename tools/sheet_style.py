#!/usr/bin/env python3
"""The character-sheet style trial (Prompt 07 territory, 2026-10-11; target
docs/concept/style_candidates/character_sheet.png): a realistic model whose TEXTURES are cut into
squares of a fixed real size, drawn nearest, lit by ordinary smooth light that runs across the
squares. No post filter. Behind `--sheet-style` on any run (Settings, src/art/sheet_style.gd);
nothing here changes the game's defaults.

    python3 tools/sheet_style.py man [--face-mm=3 --hat-mm=6 --body-mm=7 --jitter=0 --id=stranger2]
    python3 tools/sheet_style.py world

Writes into build/sheet_style/ (gitignored, remade from what's committed; a .gdignore keeps the
editor from importing it, the game reads it with Image.load_from_file):
  man:   <id>_albedo.png  his own Rodin colour (not the repaint), cut into squares in his body's
         space (cubes in his body's axes, one set per way the surface faces, each the MEAN of the
         texels in it: a downsample, not a pick), face FACE_MM, hat and hair HAT_MM, the rest
         BODY_MM (--jitter=J: each square's lightness scaled by 1 + J x a seeded normal, the
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


def man(cid, face_mm, hat_mm, body_mm, jitter=0.0):
    spec = json.load(open(hp.PEOPLE))["people"][cid]
    pos, nrm, uv, tris, colour = hp.load_man(cid)
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
    if jitter > 0.0:
        mean *= np.clip(1.0 + jitter * np.random.default_rng(1882).standard_normal(k), 0.5, 1.5)[:, None]
    rgb_img[ty, tx] = (np.clip(mean[lab], 0.0, 1.0) ** (1 / 2.2)) * 255.0
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(rgb_img, 0, 255).astype(np.uint8)).save(os.path.join(OUT, cid + "_albedo.png"))
    if normal is not None:
        normal.resize((SIZE, SIZE), Image.LANCZOS).save(os.path.join(OUT, cid + "_normal.png"))
    print("%s: %d texels in %d squares (face %.0f mm: %d texels, hat %.0f, body %.0f)" % (
        cid, len(lab), k, face_mm, zone.sum(), hat_mm, body_mm))


def world():
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
            a = a.reshape(h, f, w, f, 3).mean(axis=(1, 3)) ** (1 / 2.2)
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
            float(opt.get("--body-mm", BODY_MM)), float(opt.get("--jitter", 0.0)))
    if "world" in args:
        world()
    if not ({"man", "world"} & set(args)):
        print(__doc__)


if __name__ == "__main__":
    main()
