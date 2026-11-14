"""Sean's horse pictures (docs/concept/horse/: side_left, side_right, front, back; 2026-10-24) read
as numbers for the horse's build: his outline in metres to sculpt the body to, and each view's
place, for painting the coat by projecting the pictures onto the model.

The pictures are cut out by colour: the backdrop is flat grey, the horse is coloured or very dark
or very light (the ground shadow under him is grey, so it stays out). Scale: his withers at 1.52 m
(15 hands): 454 px a metre in the left side view. Blender axes as horse_shape.py: his head at -X,
his right +Y, the ground z = 0.
"""
import hashlib
import os

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DIR = os.path.join(ROOT, "docs", "concept", "horse")
VIEWS = ("side_left", "side_right", "front", "back")

# The left side view: ground row, px a metre, the column of x = 0 (his barrel's middle, halfway
# from the front of his chest at 490 px to the back of his quarters at 1150 px).
GROUND = 970
SCALE = 454.0
X0 = 820.0
# The right side view (he faces right): drawn 7% longer than the left, so its own scale along him,
# fitted to his trunk at 1.1 m up (the left's chest front 465 px and quarters 1171 px against the
# right's 1130 and 373); up and down, its ground to ear tips (938 px against the left's 929).
NOSE_X = -1.39
RIGHT_FRONT = 1130.0
RIGHT_FRONT_X = (465 - X0) / SCALE
RIGHT_LONG = (1130.0 - 373.0) / ((1171 - 465) / SCALE)
RIGHT_GROUND = 969
RIGHT_SCALE = SCALE * 938.0 / 929.0
# The front and back views: ground to ear tips (2.05 m) and the middle column.
EAR_TOP = (GROUND - 41) / SCALE
FRONT = {"ground": 894, "scale": (894 - 114) / EAR_TOP, "mid": 770.5}
BACK = {"ground": 894, "scale": (894 - 124) / EAR_TOP, "mid": 761.5}


def image(name):
    from PIL import Image
    return np.asarray(Image.open(os.path.join(DIR, name + ".png")).convert("RGB")).astype(np.float32)


def mask(a):
    """The horse in a picture: coloured, very dark, or lighter than the grey backdrop (the blaze, the
    stockings; his shadow on the ground is darker grey, so it stays out); the largest piece, small
    holes filled."""
    from scipy import ndimage
    sat = a.max(2) - a.min(2)
    val = a.mean(2)
    m = (sat > 18) | (val < 62) | (val > 118)
    m = ndimage.binary_opening(m, iterations=2)
    lab, k = ndimage.label(m)
    sizes = ndimage.sum(m, lab, range(1, k + 1))
    m = lab == (np.argmax(sizes) + 1)
    holes = ndimage.binary_fill_holes(m) & ~m
    hl, hk = ndimage.label(holes)
    hs = ndimage.sum(holes, hl, range(1, hk + 1))
    return m | np.isin(hl, [i + 1 for i, v in enumerate(hs) if v < 1500])


def key():
    """A hash of the pictures (the sculpt's cache key includes it)."""
    h = hashlib.sha1()
    for v in VIEWS:
        h.update(open(os.path.join(DIR, v + ".png"), "rb").read())
    return h.hexdigest()[:8]


def to_px(x, z):
    return X0 + x * SCALE, GROUND - z * SCALE


def side_outline(step=0.005):
    """His body's outline in the left side view without the tail's hair: for x from his nose to his
    quarters every `step` m, the top and bottom (m) of the column's longest run, or NaN where the
    column misses him (the ears where they stand on the poll are the sculpt's to cap). (The bottom runs down a leg where one stands; the
    sculpt caps it.)"""
    a = image("side_left")
    m = mask(a)
    val = a.mean(2)
    # The tail's hair: dark, behind his quarters (and not the hocks below).
    ys, xs = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    tail = m & (val < 80) & (xs > 1140) & (ys < 700)
    body = m & ~tail
    out_x, top, bottom = [], [], []
    for x in np.arange(NOSE_X, 0.8, step):
        px = int(round(X0 + x * SCALE))
        col = np.nonzero(body[:, px])[0]
        out_x.append(x)
        if len(col) == 0:
            top.append(np.nan)
            bottom.append(np.nan)
            continue
        # The column's longest run (an ear tip or a lock of mane above it is apart from it).
        breaks = np.nonzero(np.diff(col) > 1)[0]
        starts = np.concatenate([[0], breaks + 1])
        ends = np.concatenate([breaks, [len(col) - 1]])
        i = int(np.argmax(col[ends] - col[starts]))
        top.append((GROUND - col[starts[i]]) / SCALE)
        bottom.append((GROUND - col[ends[i]]) / SCALE)
    return np.array(out_x), np.array(top), np.array(bottom)


def views():
    """Each picture with its mask and how a point (Blender x, y, z) lands on it: [(name, image,
    mask, project(P) -> (u, v), facing(N) -> weight)]."""
    out = []
    for name in VIEWS:
        a = image(name)
        m = mask(a)
        if name == "side_left":
            def proj(P):
                return X0 + P[:, 0] * SCALE, GROUND - P[:, 2] * SCALE

            def facing(N):
                return -N[:, 1]
        elif name == "side_right":
            def proj(P):
                return RIGHT_FRONT - (P[:, 0] - RIGHT_FRONT_X) * RIGHT_LONG, RIGHT_GROUND - P[:, 2] * RIGHT_SCALE

            def facing(N):
                return N[:, 1]
        elif name == "front":
            def proj(P):
                return FRONT["mid"] - P[:, 1] * FRONT["scale"], FRONT["ground"] - P[:, 2] * FRONT["scale"]

            def facing(N):
                return -N[:, 0]
        else:
            def proj(P):
                return BACK["mid"] + P[:, 1] * BACK["scale"], BACK["ground"] - P[:, 2] * BACK["scale"]

            def facing(N):
                return N[:, 0]
        out.append((name, a, m, proj, facing))
    return out
