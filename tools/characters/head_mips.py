"""Painted mip levels for a man's head texture (the distance test, 2026-10-20: up close his face reads,
further away not so much). The game samples his head with mipmaps (body_skin's filter_nearest_mipmap)
but heads are imported without any, so at 6 m and beyond each screen pixel is one texel picked from
dozens: his moustache, brows and eyes break up into speckle. These levels are made on purpose for
being seen small (the brief's medoid mips, docs/briefs/character-style-fidelity.md, kept the paint's
own colours; here his features are kept bold as well):

    ~/bpyenv/bin/python tools/characters/head_mips.py --man=bold_cowboy_whole_a2 --out=DIR [--value] [--plain-to=N]

- each level from the one above by 2x2 blocks: a block touching his moustache, a brow or an eye takes
  the darkest of its feature texels (so those dark lines thicken as he shrinks instead of averaging
  away into his skin); any other block takes its medoid (the one of its four colours nearest their
  mean: no new, blended colours, no blur);
- from SIMPLIFY_FROM down his skin is put into a palette of PALETTE colours (simplified, not noisy);
- `--plain-to=N`: levels 1..N not painted but every 2^k-th texel of the full texture (what the game
  draws today without mipmaps, so up close he looks as he does now), the painted levels only below N
  (on his face level 4 is about 3 m in the game, level 5 about 6 m);
- `--value`: first a stronger value pass on the full texture: his brow shadow, eye sockets and
  moustache darkened (VALUE), his eyes' whites kept.
→ DIR/level_0.png (the full texture, after the value pass if asked) ... level_N.png (1x1), read by
PeopleBodies.head_variant "dir:DIR" (and screenshots.gd --head-variant=).
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "blender"))
ROOT = os.path.dirname(os.path.dirname(HERE))
PEOPLE = os.path.join(ROOT, "assets", "people")

BROWS = [70, 63, 105, 66, 107, 46, 53, 52, 65, 55, 300, 293, 334, 296, 336, 276, 283, 282, 295, 285]
MOUSTACHE = [0, 37, 267, 39, 269, 40, 270, 61, 291, 164, 92, 322, 165, 391]
EYE_M = 0.011          # metres round each iris that is his eye (kept bold)
BROW_M = 0.006         # ... round each brow point
MOUSTACHE_M = 0.016    # ... round his upper lip's points where dark is his moustache
DARK = 0.7             # a feature texel is darker than this share of his skin's lightness (brows, moustache)
SIMPLIFY_FROM = 2      # level from which his skin is put in a palette
PALETTE = 16
VALUE = {"brow_shadow": 0.78, "sockets": 0.82, "moustache": 0.8}
LUM = np.array([0.2126, 0.7152, 0.0722])


def masks(man, size):
    """Per texel: his position on the head (raster of his mesh), and the feature masks."""
    import portrait as P
    m = dict(np.load(os.path.join(PEOPLE, "heads", man + "_mesh.npz")))
    V, T, UV, pts = m["V"], m["T"], m["UV"], m["pts"]
    table = {tuple(t): [tuple(UV[i]) for i in t] for t in T}
    M, cover = P.raster_uv(table, [list(t) for t in T], V, size)
    d_eye = np.min([np.linalg.norm(M - pts[i], axis=-1) for i in (468, 473)], axis=0)
    d_brow = np.min([np.linalg.norm(M - pts[i], axis=-1) for i in BROWS], axis=0)
    d_mou = np.min([np.linalg.norm(M - pts[i], axis=-1) for i in MOUSTACHE], axis=0)
    return M, cover, pts, d_eye, d_brow, d_mou


def value_pass(tex, M, cover, pts, d_eye, d_brow, d_mou, skin_l):
    """His brow shadow (between his brows and his upper lids), eye sockets (round each eye, not the
    whites) and moustache darkened by VALUE, feathered."""
    out = tex.copy()
    lum = tex @ LUM
    sat = tex.max(-1) - tex.min(-1)
    eye_y = float((pts[468, 1] + pts[473, 1]) / 2)
    brow_y = float(np.mean(pts[BROWS, 1]))
    f = np.ones(tex.shape[:2])
    # Brow shadow: from his upper lids up to his brows, over each eye.
    band = np.clip((M[..., 1] - eye_y - 0.002) / 0.004, 0, 1) * np.clip((brow_y - M[..., 1]) / 0.004 + 1, 0, 1)
    over_eyes = np.clip(1 - (d_eye - 0.012) / 0.008, 0, 1)
    f *= 1 - (1 - VALUE["brow_shadow"]) * band * over_eyes
    # Sockets: round each eye, his whites (light, grey) left.
    whites = (d_eye < EYE_M) & (lum > skin_l * 0.9) & (sat < 0.25)
    sock = np.clip(1 - (d_eye - 0.008) / 0.008, 0, 1) * (d_eye > 0.004) * ~whites
    f *= 1 - (1 - VALUE["sockets"]) * sock
    # Moustache: its dark texels.
    mou = (d_mou < MOUSTACHE_M) & (lum < skin_l * DARK)
    f *= np.where(mou, VALUE["moustache"], 1.0)
    out = np.clip(tex * f[..., None], 0, 1)
    return np.where(cover[..., None], out, tex)


def down(tex, feat, palette=None):
    """One level down: 2x2 blocks, the darkest feature texel where there is one, else the medoid."""
    h, w = tex.shape[0] // 2, tex.shape[1] // 2
    b = tex[:h * 2, :w * 2].reshape(h, 2, w, 2, 3).transpose(0, 2, 1, 3, 4).reshape(h, w, 4, 3)
    fb = feat[:h * 2, :w * 2].reshape(h, 2, w, 2).transpose(0, 2, 1, 3).reshape(h, w, 4)
    mean = b.mean(2, keepdims=True)
    medoid = np.take_along_axis(b, np.argmin(((b - mean) ** 2).sum(-1), 2)[..., None, None].repeat(3, -1), 2)[:, :, 0]
    l = np.where(fb, b @ LUM, np.inf)
    dark = np.take_along_axis(b, np.argmin(l, 2)[..., None, None].repeat(3, -1), 2)[:, :, 0]
    anyf = fb.any(2)
    out = np.where(anyf[..., None], dark, medoid)
    if palette is not None:
        flat = out[~anyf]
        idx = np.argmin(((flat[:, None, :] - palette[None]) ** 2).sum(-1), 1)
        out[~anyf] = palette[idx]
    return out, anyf


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man, out_dir = a["--man"], a["--out"]
    tex = np.asarray(Image.open(os.path.join(PEOPLE, man + "_head.png")).convert("RGB")).astype(float) / 255.0
    size = tex.shape[0]
    M, cover, pts, d_eye, d_brow, d_mou = masks(man, size)
    lum = tex @ LUM
    skin = cover & (d_eye > 0.02) & (d_mou > 0.02) & (d_brow > 0.01) & (M[..., 2] < -0.05)
    skin_l = float(np.median(lum[skin]))
    if "--value" in sys.argv:
        tex = value_pass(tex, M, cover, pts, d_eye, d_brow, d_mou, skin_l)
        lum = tex @ LUM
    feat = cover & ((d_eye < EYE_M) | (((d_brow < BROW_M) | (d_mou < MOUSTACHE_M)) & (lum < skin_l * DARK)))
    from scipy.cluster.vq import kmeans2
    sample = tex[skin][np.random.default_rng(0).choice(int(skin.sum()), min(int(skin.sum()), 40000), replace=False)]
    palette, _ = kmeans2(sample, PALETTE, minit="++", seed=0)
    os.makedirs(out_dir, exist_ok=True)
    plain_to = int(a.get("--plain-to", "0"))
    level, cur, f = 0, tex, feat
    Image.fromarray((np.clip(cur, 0, 1) * 255).round().astype(np.uint8)).save(os.path.join(out_dir, "level_0.png"))
    while cur.shape[0] > 1:
        level += 1
        cur, f = down(cur, f, palette if level >= SIMPLIFY_FROM else None)
        k = 2 ** level
        shown = tex[k // 2::k, k // 2::k] if level <= plain_to else cur
        Image.fromarray((np.clip(shown, 0, 1) * 255).round().astype(np.uint8)).save(os.path.join(out_dir, "level_%d.png" % level))
    print("head_mips: %s → %s: %d levels, %d feature texels, skin lightness %.3f%s%s" % (
        man, out_dir, level + 1, int(feat.sum()), skin_l, ", value pass" if "--value" in sys.argv else "",
        ", levels 1-%d plain" % plain_to if plain_to else ""))


if __name__ == "__main__":
    main()
