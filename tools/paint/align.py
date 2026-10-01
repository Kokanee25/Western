#!/usr/bin/env python3
"""Fit each painted view back onto its guide before the bake.

    python3 tools/paint/align.py [assets/people/paint] [--only=outlaw] [--source=painted|tile]

The image model paints the man from each grey guide, but draws him a little bigger or smaller and
off to one side. For every <id>_<view>_painted.png: his outline in the painting (whatever isn't
its plain background) is fitted onto his outline in the guide (<id>_<view>_mask.png, from
tools/paint_bake.gd) by the scale and shift that overlap them best, and the painting is moved to
match. Saved as <id>_<view>_aligned.png, its alpha his outline in the painting (a little inside
it, so no background at the edge), which tools/paint_bake.gd uses in place of the raw painting
(--source=tile: the views cut from the turnaround sheet, tools/paint/paint_views.py --sheet):
where his outline and the painted one disagree, nothing is taken.

Each painting's colours are matched to the concept painting's man first (mean and spread per
channel), so the views agree with each other and with the painting.

The shot view also gets <id>_shot_painting.png: the concept painting's own pixels, with alpha from
the painting's man's outline (SHOT_OUTLINE, traced by hand in the painting's pixels), so the bake
takes the painting itself only where it shows him.

Then his face (face_warp): the model draws his features where it likes inside the outline (FLUX
put his eyes ~2 cm higher and closer together than our head's), so painted eyes land on the brow
ridge and the sockets' shadow on the cheeks. Where a face is found in both the guide and the
painting (MediaPipe's face landmarker, a free model fetched into build/ on first use; pip install
mediapipe), the painting is bent so its eyes, brows, nose, mouth and jaw land on the guide's,
smoothly, fading to nothing away from the face and pinned along his outline.
"""
import json
import os
import sys
import urllib.request

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

PAINTING = "docs/concept/saloon-night.png"
# The painting's man, clockwise from the brim's left tip (its 1672x941 pixels, traced by hand on a
# grid): the brim and crown, the brim's right tip, his face and left arm, round the cup, under his
# hand and cuff, along the table's edge to the bottom, his coat's left edge (against the chair),
# his right shoulder, hair and the side of his face back to the brim.
SHOT_OUTLINE = [
    (448, 248), (590, 205), (595, 193), (700, 198), (760, 280), (822, 360), (832, 392), (760, 398),
    (718, 405), (712, 440), (700, 475), (760, 500), (830, 540), (875, 590), (880, 650), (845, 690),
    (840, 770), (790, 790), (790, 820), (700, 825), (600, 830), (590, 860), (560, 900), (545, 941),
    (205, 941), (205, 650), (230, 550), (255, 505), (300, 480), (350, 462), (400, 450), (450, 435),
    (500, 405), (505, 330), (462, 290),
]
# The shot guide's frame in the painting (tools/paint_bake.gd SHOT_CROP, in pixels).
SHOT_BOX = (105, 141, 905, 941)
# The painting's man's head, hat and collar (its pixels): the colours the close head views match.
HEAD_BOX = (430, 180, 830, 620)
# How far inside the painted outline to stop (px at 1024): the model's edge pixels are background.
INSET = 3
# The face landmarker (Apache 2.0) and the points of its face mesh the warp matches: irises, eye
# corners and lids, brows, the nose's bridge, tip and wings, the mouth's corners and lips, chin,
# jaw and forehead.
LANDMARKER_URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
LANDMARKER = "build/mediapipe/face_landmarker.task"
FACE_POINTS = [468, 473, 33, 133, 362, 263, 159, 145, 386, 374, 70, 105, 107, 336, 334, 300, 168, 1, 2,
        98, 327, 61, 291, 0, 17, 13, 14, 152, 172, 397, 150, 379, 234, 454, 10]
# The warp's reach round each point (x the face's size, eyes to chin), how much it smooths
# rather than hitting every point, and the most it may move a feature (x the face's size: past
# that, one of the two faces was misread and the painting is left as it is).
# Each eye's outline on the face mesh (corner, upper lid, corner, lower lid), and how much of the
# painting's own colour the whites inside keep.
EYE_OUTLINES = [[33, 246, 161, 160, 159, 158, 157, 173, 133, 155, 154, 153, 145, 144, 163, 7],
        [263, 466, 388, 387, 386, 385, 384, 398, 362, 382, 381, 380, 374, 373, 390, 249]]
EYE_WHITE_KEEP = 0.8
WARP_REACH = 0.45
WARP_SMOOTH = 0.05
WARP_MAX = 0.35
_landmarker = None


def painted_mask(img):
    a = np.asarray(img.convert("RGB")).astype(float)
    border = np.concatenate([a[:8].reshape(-1, 3), a[-8:].reshape(-1, 3), a[:, :8].reshape(-1, 3), a[:, -8:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    m = np.sqrt(((a - bg) ** 2).sum(2)) > 28
    im = Image.fromarray((m * 255).astype(np.uint8))
    # Close small holes, drop specks.
    im = im.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    im = im.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    # Whatever the background can't reach from the edges is him (a white cuff or collar is close
    # to the background's grey, but it's inside his outline).
    im = im.point(lambda v: 255 if v > 127 else 0)
    w, h = im.size
    for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        if im.getpixel((x, y)) == 0:
            ImageDraw.floodfill(im, (x, y), 128)
    return im.point(lambda v: 0 if v == 128 else 255)


def warp(im, s, tx, ty, size, resample):
    # Output pixel (x, y) takes input pixel ((x - tx) / s, (y - ty) / s).
    return im.transform(size, Image.AFFINE, (1 / s, 0, -tx / s, 0, 1 / s, -ty / s), resample=resample)


def iou(a, b):
    return (a & b).sum() / max((a | b).sum(), 1)


def fit(pmask, gmask):
    """Scale and shift (in guide pixels) that lay the painted outline on the guide's."""
    n = 192
    k = gmask.width / n
    g = np.asarray(gmask.resize((n, n), Image.BILINEAR)) > 127
    p_small = pmask.resize((n, n), Image.BILINEAR)
    p = np.asarray(p_small) > 127
    ys, xs = np.nonzero(g)
    yp, xp = np.nonzero(p)
    s = np.sqrt(len(xs) / max(len(xp), 1))
    tx, ty = xs.mean() - s * xp.mean(), ys.mean() - s * yp.mean()
    best = (iou(np.asarray(warp(p_small, s, tx, ty, (n, n), Image.NEAREST)) > 127, g), s, tx, ty)
    for step_s, step_t in [(0.04, 6.0), (0.02, 3.0), (0.01, 1.5), (0.005, 0.75)]:
        improved = True
        while improved:
            improved = False
            _, s0, tx0, ty0 = best
            for ds in (-step_s, 0, step_s):
                for dx in (-step_t, 0, step_t):
                    for dy in (-step_t, 0, step_t):
                        c = (s0 + ds, tx0 + dx, ty0 + dy)
                        v = iou(np.asarray(warp(p_small, c[0], c[1], c[2], (n, n), Image.NEAREST)) > 127, g)
                        if v > best[0] + 1e-6:
                            best = (v, *c)
                            improved = True
    v, s, tx, ty = best
    # Back to full-size pixels: the painting is resized to the guide's size first.
    return v, s, tx * k, ty * k


def man_pixels(img, mask):
    a = np.asarray(img.convert("RGB")).astype(float)
    return a[np.asarray(mask) > 127]


def match_colours(rgb, mask, ref):
    """Shift and stretch each channel so his pixels have the painting's man's mean and spread: the
    model paints him brighter and cooler than the painting, and each view differently."""
    a = np.asarray(rgb).astype(float)
    his = a[np.asarray(mask) > 127]
    out = (a - his.mean(0)) / np.maximum(his.std(0), 1.0) * ref.std(0) + ref.mean(0)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def face_points(img, points=None):
    """FACE_POINTS (or points) on the face in img (RGB), in pixels (n, 2), or None."""
    global _landmarker
    try:
        import mediapipe as mp
        from mediapipe.tasks import python as mpt
        from mediapipe.tasks.python import vision
    except ImportError:
        return None
    if _landmarker is None:
        if not os.path.exists(LANDMARKER):
            os.makedirs(os.path.dirname(LANDMARKER), exist_ok=True)
            urllib.request.urlretrieve(LANDMARKER_URL, LANDMARKER)
        _landmarker = vision.FaceLandmarker.create_from_options(vision.FaceLandmarkerOptions(
                base_options=mpt.BaseOptions(model_asset_path=LANDMARKER), num_faces=1,
                min_face_detection_confidence=0.2, min_face_presence_confidence=0.2))
    rgb = np.ascontiguousarray(np.asarray(img.convert("RGB")))
    found = _landmarker.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
    if not found.face_landmarks:
        return None
    lm = found.face_landmarks[0]
    return np.array([(lm[i].x * img.width, lm[i].y * img.height) for i in (points or FACE_POINTS)])


def keep_eye_whites(painted, matched):
    """matched, with the whites of his eyes as painted: inside each eye's outline (EYE_OUTLINES) the
    painting's own colours at the matched brightness, where the colour match alone would turn them
    the colour of his skin (the painting keeps them pale)."""
    outlines = [face_points(painted, ring) for ring in EYE_OUTLINES]
    if any(o is None for o in outlines):
        return matched
    mask = Image.new("L", painted.size, 0)
    for ring in outlines:
        ImageDraw.Draw(mask).polygon([tuple(p) for p in ring], fill=255)
    k = np.asarray(mask.filter(ImageFilter.GaussianBlur(1.5)), dtype=float)[..., None] / 255.0 * EYE_WHITE_KEEP
    a = np.asarray(painted.convert("RGB"), dtype=float) + 1.0
    m = np.asarray(matched, dtype=float) + 1.0
    lum = np.array([0.2126, 0.7152, 0.0722])
    own = a * ((m @ lum) / (a @ lum))[..., None]
    return Image.fromarray(np.clip(m * (1 - k) + own * k - 1.0, 0, 255).astype(np.uint8))


def sample(a, x, y):
    """a (h, w, c) at float pixel coordinates x, y (bilinear, clamped at the edges)."""
    h, w = a.shape[:2]
    x = np.clip(x, 0, w - 1.001)
    y = np.clip(y, 0, h - 1.001)
    x0, y0 = np.floor(x).astype(int), np.floor(y).astype(int)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    return (a[y0, x0] * (1 - fx) * (1 - fy) + a[y0, x0 + 1] * fx * (1 - fy)
            + a[y0 + 1, x0] * (1 - fx) * fy + a[y0 + 1, x0 + 1] * fx * fy)


def face_warp(rgba, guide, guide_mask, close=False):
    """Bend rgba (the aligned painting, RGBA, in the guide's pixels) so its face's landmarks land on
    the guide's. Returns {image (None if not bent), moved (px, median), left (px after), fit (moved
    over the face's size), mismatch (a face painted where the guide has none; or, on a close view
    of his head, where a face is big enough always to be found, no face where the guide has one)}."""
    under = Image.new("RGB", rgba.size, (128, 128, 128))
    under.paste(rgba, mask=rgba.getchannel("A"))
    want, have = face_points(guide), face_points(under)
    if want is None or have is None:
        return {"image": None, "mismatch": (want is None and have is not None) or (close and want is not None)}
    size = np.linalg.norm(want[:2].mean(0) - want[FACE_POINTS.index(152)])
    moved = np.linalg.norm(have - want, axis=1)
    result = {"image": None, "mismatch": False, "moved": float(np.median(moved)),
            "fit": float(np.median(moved) / max(size, 1.0))}
    if np.median(moved) > WARP_MAX * size:
        return result
    # Pinned along his outline: nothing at his silhouette moves.
    edge = np.asarray(guide_mask.filter(ImageFilter.FIND_EDGES)) > 127
    ys, xs = np.nonzero(edge)
    pins = np.stack([xs, ys], 1)[:: max(1, len(xs) // 120)].astype(float)
    pins = pins[np.min(np.linalg.norm(pins[:, None] - want[None], axis=2), axis=1) > 0.25 * size]
    at = np.concatenate([want, pins])
    d = np.concatenate([have - want, np.zeros_like(pins)])
    s = WARP_REACH * size
    phi = np.exp(-((at[:, None] - at[None]) ** 2).sum(2) / (2 * s * s))
    wts = np.linalg.solve(phi + WARP_SMOOTH * np.eye(len(at)), d)
    h, w = rgba.height, rgba.width
    gy, gx = np.mgrid[0:h, 0:w].astype(float)
    dx, dy = np.zeros((h, w)), np.zeros((h, w))
    for (px, py), (wx, wy) in zip(at, wts):
        k = np.exp(-((gx - px) ** 2 + (gy - py) ** 2) / (2 * s * s))
        dx += k * wx
        dy += k * wy
    src = np.asarray(rgba, dtype=float)
    out = sample(src, gx + dx, gy + dy)
    out[..., 3] = np.where(out[..., 3] > 127, 255, 0)
    img = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")
    under = Image.new("RGB", img.size, (128, 128, 128))
    under.paste(img, mask=img.getchannel("A"))
    after = face_points(under)
    result["left"] = float(np.median(np.linalg.norm(after - want, axis=1))) if after is not None else -1.0
    result["image"] = img
    return result


def painting_reference(box=None):
    """The painting's man's pixels (inside box, if given: his head for the close head views)."""
    img = Image.open(PAINTING).convert("RGB")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SHOT_OUTLINE, fill=255)
    if box:
        keep = Image.new("L", img.size, 0)
        ImageDraw.Draw(keep).rectangle(box, fill=255)
        mask = Image.fromarray(np.minimum(np.asarray(mask), np.asarray(keep)))
    return man_pixels(img, mask)


def align(src, pid, view, ref, source="painted"):
    guide_mask = Image.open(os.path.join(src, "%s_%s_mask.png" % (pid, view))).convert("L")
    painted = Image.open(os.path.join(src, "%s_%s_%s.png" % (pid, view, source))).convert("RGB").resize(guide_mask.size, Image.LANCZOS)
    pmask = painted_mask(painted)
    before = iou(np.asarray(pmask) > 127, np.asarray(guide_mask) > 127)
    v, s, tx, ty = fit(pmask, guide_mask)
    painted = keep_eye_whites(painted, match_colours(painted, pmask, ref))
    rgb = warp(painted, s, tx, ty, guide_mask.size, Image.BICUBIC)
    alpha = warp(pmask.filter(ImageFilter.MinFilter(2 * INSET + 1)), s, tx, ty, guide_mask.size, Image.NEAREST)
    rgb.putalpha(alpha)
    report = {"overlap_before": round(float(before), 3), "overlap": round(float(v), 3), "scale": round(float(s), 4),
            "shift": [round(float(tx), 1), round(float(ty), 1)]}
    line = "%s %s: outline overlap %.2f -> %.2f (scale %.3f, shift %+.0f, %+.0f px)" % (pid, view, before, v, s, tx, ty)
    guide = Image.open(os.path.join(src, "%s_%s_guide.png" % (pid, view))).convert("RGB")
    bent = face_warp(rgb, guide, guide_mask, close=view.startswith("head_"))
    if bent["mismatch"]:
        # A face painted where the guide shows the back of his head (or none where it shows one):
        # the model drew this view from the wrong side. finish.py leaves it out.
        report["face_mismatch"] = True
        line += "; FACE MISMATCH (painted from the wrong side)"
    if "fit" in bent:
        report["face_fit"] = round(bent["fit"], 3)
    if bent["image"] is not None:
        rgb = bent["image"]
        report["face_moved_px"], report["face_left_px"] = round(bent["moved"], 1), round(bent["left"], 1)
        line += "; face moved %.0f px (%.2f of his face) onto the guide's (%.0f px off after)" % (
                bent["moved"], bent["fit"], bent["left"])
    rgb.save(os.path.join(src, "%s_%s_aligned.png" % (pid, view)))
    print(line)
    return report


def painting_shot(src, pid):
    img = Image.open(PAINTING).convert("RGB")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).polygon(SHOT_OUTLINE, fill=255)
    img.putalpha(mask)
    img = img.crop(SHOT_BOX)
    guide = os.path.join(src, "%s_shot_guide.png" % pid)
    if os.path.exists(guide):
        guide_mask = Image.open(os.path.join(src, "%s_shot_mask.png" % pid)).convert("L")
        bent = face_warp(img.resize(guide_mask.size, Image.LANCZOS), Image.open(guide).convert("RGB"), guide_mask)
        if bent["image"] is not None:
            img = bent["image"]
            print("%s shot (the painting itself): face moved %.0f px onto the guide's (%.0f px off after)" % (
                    pid, bent["moved"], bent["left"]))
    img.save(os.path.join(src, "%s_shot_painting.png" % pid))


def main():
    src = "assets/people/paint"
    only = None
    source = "painted"
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
        elif a.startswith("--source="):
            source = a.split("=", 1)[1]
        elif not a.startswith("--"):
            src = a
    report = {}
    ref = painting_reference()
    ref_head = painting_reference(HEAD_BOX)
    for f in sorted(os.listdir(src)):
        if not f.endswith("_%s.png" % source):
            continue
        stem = f[: -len("_%s.png" % source)]
        pid, view = None, None
        for v in ("head_three_quarter", "head_side_left", "head_front", "head_side", "head_back", "head_shot",
                "three_quarter", "side_left", "shot", "front", "side", "back"):
            if stem.endswith("_" + v):
                pid, view = stem[: -len(v) - 1], v
                break
        if view is None or (only and pid != only):
            continue
        if not os.path.exists(os.path.join(src, "%s_%s_mask.png" % (pid, view))):
            print("no mask for", stem, "(run tools/paint_bake.gd guides)")
            continue
        report.setdefault(pid, {"source": source})[view] = align(src, pid, view, ref_head if view.startswith("head_") else ref, source)
        if view == "shot":
            painting_shot(src, pid)
    for pid, r in report.items():
        with open(os.path.join(src, "%s_aligned.json" % pid), "w") as fh:
            json.dump(r, fh, indent=1)


if __name__ == "__main__":
    main()
