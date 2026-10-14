"""A portrait-factory man's comparison sheet for Sean (docs/briefs/portrait-factory.md, "Order and
judging"): his style portrait | his plain picture | our man in the game.

    ~/bpyenv/bin/python tools/characters/portrait_sheet.py --man=bold_cowboy \
        --bare=DIR --hat=DIR --saloon=PNG --close=PNG --out=docs/screenshots/portrait/bold_cowboy_sheet.jpg

--bare / --hat: tools/people_lineup.gd --head --poses=stand output (with and without --hatless):
head_stand_front/three_quarter/side.png (orthographic, plain light). --saloon / --close:
tools/screenshots.gd --model=<id>_portrait shot_match_saloon / shot_match_close.

Rows: the three views (front, three-quarter, profile), each style | plain | in game bare-headed |
in game hatted; the saloon shot and its close view; then crops at twice the render's size of the
eyes, nose, moustache and ear, each style | plain | in game (found by MediaPipe's landmarks).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as PT  # noqa: E402

CELL = 300
BG = (24, 22, 20)
INK = (230, 220, 200)


def fit(img, w, h):
    """img scaled to fit w x h, centred on the background."""
    img = img.convert("RGB")
    k = min(w / img.width, h / img.height)
    im = img.resize((max(1, int(img.width * k)), max(1, int(img.height * k))), Image.LANCZOS)
    out = Image.new("RGB", (w, h), BG)
    out.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return out


def head_crop(img):
    """The head: a square round MediaPipe's face (its landmarks' box, grown), or the whole picture."""
    lm = PT.landmarks(img.convert("RGB"))
    if lm is None:
        return img
    lo, hi = lm[:, :2].min(0), lm[:, :2].max(0)
    c = (lo + hi) / 2
    r = max(hi - lo) * 0.95
    return img.crop((int(c[0] - r), int(c[1] - r * 1.05), int(c[0] + r), int(c[1] + r * 0.95)))


def feature_boxes(img, profile=False):
    """{eyes, nose, moustache, ear: box} on img from its landmarks (None where not found)."""
    lm = PT.landmarks(img.convert("RGB"))
    if lm is None:
        return {}
    p = lm[:, :2]
    eye_w = np.linalg.norm(p[33] - p[263])
    nose_len = np.linalg.norm(p[168] - p[2])
    box = lambda c, w, h: (int(c[0] - w / 2), int(c[1] - h / 2), int(c[0] + w / 2), int(c[1] + h / 2))
    out = {}
    if not profile:
        out["eyes"] = box((p[33] + p[263]) / 2, eye_w * 1.5, eye_w * 0.5)
        out["nose"] = box((p[168] + p[2]) / 2 + [0, nose_len * 0.15], nose_len * 1.0, nose_len * 1.2)
        out["moustache"] = box((p[2] + p[17]) / 2, eye_w * 1.25, nose_len * 0.9)
    else:
        # The ear: behind the eye by about the eye-to-nose-tip distance's 1.9 times, at the nose's height.
        faces_right = p[1, 0] > p[234, 0] and p[1, 0] > p[454, 0]
        eye = p[33] if abs(p[33, 0] - p[1, 0]) > abs(p[263, 0] - p[1, 0]) else p[263]
        d = abs(p[1, 0] - eye[0])
        c = np.array([eye[0] + (-1 if faces_right else 1) * d * 1.9, (p[168, 1] + p[2, 1]) / 2])
        out["ear"] = box(c, nose_len * 1.4, nose_len * 1.6)
    return out


def lineup_ear(img):
    """The ear on people_lineup.gd's close side view (no face for MediaPipe there): its camera is
    orthographic, 0.42 m tall, centred 1.62 m up; the ear is about 2 cm under the eyes (1.655 m),
    a little behind the middle of his head's outline at that height."""
    a = np.asarray(img.convert("RGB")).astype(float)
    px = img.height / 0.42
    row = int(img.height / 2 - (1.635 - 1.62) * px)
    bg = a[2, 2]
    him = np.where(np.abs(a[row] - bg).sum(1) > 30)[0]
    if len(him) == 0:
        return None
    x = him.min() + 0.42 * (him.max() - him.min())
    w = 0.06 * px
    return (int(x - w / 2), int(row - w * 0.6), int(x + w / 2), int(row + w * 0.6))


def label(img, text):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=BG)
    d.text((4, 2), text, fill=INK)
    return img


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if x.startswith("--") and "=" in x)
    man = a["--man"].lstrip("-") if a.get("--man") else "bold_cowboy"
    spec = dict(PT.men(man))[man]
    pics = spec["pictures"]
    style = spec.get("style_views", {})
    style_front = Image.open(style.get("front", spec["style"]))
    style_tq = Image.open(style["three_quarter"]) if "three_quarter" in style else None
    style_side = Image.open(style["side"]) if "side" in style else None
    plain_front = Image.open(os.path.join(pics, "front.png"))
    plain_side = Image.open(os.path.join(pics, "right.png"))
    bare = {v: Image.open(os.path.join(a["--bare"], "head_stand_%s.png" % v)) for v in ("front", "three_quarter", "side")}
    hat = {v: Image.open(os.path.join(a["--hat"], "head_stand_%s.png" % v)) for v in ("front", "three_quarter", "side")}
    rows = []
    heads = ["style portrait", "plain picture", "in game, bare-headed", "in game, hatted"]
    for view, st, pl in (("front", style_front, plain_front), ("three_quarter", style_tq, None),
                         ("side", style_side, plain_side)):
        cells = [st and fit(head_crop(st), CELL, CELL), pl and fit(head_crop(pl), CELL, CELL),
                 fit(bare[view], CELL, CELL), fit(hat[view], CELL, CELL)]
        row = Image.new("RGB", (CELL * 4, CELL), BG)
        for i, c in enumerate(cells):
            if c is not None:
                row.paste(label(c, "%s: %s" % (heads[i], view.replace("_", "-"))), (CELL * i, 0))
        rows.append(row)
    # The saloon shot and its close view.
    sal = Image.open(a["--saloon"])
    close = Image.open(a["--close"]) if a.get("--close") and os.path.exists(a["--close"]) else None
    row = Image.new("RGB", (CELL * 4, CELL), BG)
    row.paste(label(fit(sal, CELL * 2, CELL), "the saloon shot"), (0, 0))
    if close is not None:
        row.paste(label(fit(close, CELL * 2, CELL), "the saloon, close"), (CELL * 2, 0))
    rows.append(row)
    # Crops: style | plain | in game, each twice the render's size.
    crops = []
    for feat, srcs in (("eyes", (style_front, plain_front, bare["front"])),
                       ("nose", (style_front, plain_front, bare["front"])),
                       ("moustache", (style_front, plain_front, bare["front"])),
                       ("ear", (style_side, plain_side, bare["side"]))):
        cells = []
        for k, im in enumerate(srcs):
            if im is None:
                cells.append(None)
                continue
            b = feature_boxes(im, profile=feat == "ear").get(feat)
            if b is None and feat == "ear" and k == 2:
                b = lineup_ear(im)
            if b is None:
                cells.append(None)
                continue
            c = im.convert("RGB").crop(b)
            if k == 2:
                c = c.resize((c.width * 2, c.height * 2), Image.NEAREST)
            cells.append(label(fit(c, CELL, CELL // 2 + 40), "%s: %s" % (feat, ["style", "plain", "game x2"][k])))
        crops.append(cells)
    for cells in crops:
        row = Image.new("RGB", (CELL * 4, CELL // 2 + 40), BG)
        for i, c in enumerate(cells):
            if c is not None:
                row.paste(c, (CELL * i, 0))
        rows.append(row)
    sheet = Image.new("RGB", (CELL * 4, sum(r.height for r in rows)), BG)
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height
    out = a.get("--out", "docs/screenshots/portrait/%s_sheet.jpg" % man)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    sheet.save(out, quality=90)
    print("wrote", out, sheet.size)
    PT.close_landmarker()


if __name__ == "__main__":
    main()
