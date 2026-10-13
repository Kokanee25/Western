"""The Rodin bold cowboy's sheet (Sean, 2026-10-13): his face beside the bold portrait at 3x, front,
three-quarter and profile in neutral light, and in the saloon.

    ~/bpyenv/bin/python tools/characters/rodin_sheet.py --dist=DIR --shots=DIR --out=PNG

--dist: tools/characters/distance_lab.gd --distances=1.2 --turns=0,-40,-90 (the player's camera, the
lineup's plain light); --shots: tools/screenshots.gd shot_match_saloon / shot_match_close. Each
game crop is his head at the game's own pixels, enlarged 3x nearest; each portrait crop is cut to
the same head height beside it.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import portrait as P  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
STYLE = "docs/concept/style/portrait-cowboy-%s.png"
K = 3
BG = (22, 20, 18)
INK = (235, 225, 205)
# distance_lab's crop at 1.2 m: 0.6 m tall (1.95 m down to 1.35 m); his head with the hat's crown
# is about 1.93 m down to his chin at 1.53 m.
HEAD = (1.90, 1.53)


def dist_head(path):
    im = Image.open(path).convert("RGB")
    px = im.height / 0.6
    y0, y1 = int((1.95 - HEAD[0]) * px), int((1.95 - HEAD[1]) * px)
    h = y1 - y0
    cx = im.width // 2
    return im.crop((cx - h // 2 - h // 8, y0, cx + h // 2 + h // 8, y1))


def style_head(name, height):
    im = Image.open(os.path.join(ROOT, STYLE % name)).convert("RGB")
    lm = P.landmarks(im)
    if lm is None:
        return im.resize((int(im.width * height / im.height), height))
    top, chin = lm[:, 1].min(), lm[152, 1]
    face = chin - top
    y0 = top - 0.55 * face          # his hat's crown, as on ours
    y1 = chin + 0.05 * face
    cx = lm[:, 0].mean()
    h = y1 - y0
    w = h * 1.25
    c = im.crop((int(cx - w / 2), int(y0), int(cx + w / 2), int(y1)))
    return c.resize((int(c.width * height / c.height), height), Image.LANCZOS)


def frame_head(path):
    """His head in a saloon frame: MediaPipe's face, grown to take his hat and chin."""
    im = Image.open(path).convert("RGB")
    lm = P.landmarks(im)
    if lm is None:
        return None
    top, chin = lm[:, 1].min(), lm[152, 1]
    face = chin - top
    y0, y1 = top - 0.55 * face, chin + 0.05 * face
    cx = lm[:, 0].mean()
    w = (y1 - y0) * 1.25
    return im.crop((int(cx - w / 2), int(y0), int(cx + w / 2), int(y1)))


def label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 8 + 7 * len(text), 16], fill=BG)
    d.text((4, 2), text, fill=INK)
    return im


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    rows = []
    for turn, name, title in ((0, "front", "front"), (-40, "three-quarter", "three-quarter"), (-90, "profile", "profile")):
        g = dist_head(os.path.join(a["--dist"], "bold_cowboy_rodin_1.2_%d.png" % turn))
        g = g.resize((g.width * K, g.height * K), Image.NEAREST)
        s = style_head(name, g.height)
        rows.append([label(s, "bold portrait: " + title), label(g, "ours, neutral light, 3x: " + title)])
    for shot in ("shot_match_saloon", "shot_match_close"):
        g = frame_head(os.path.join(a["--shots"], shot + ".png"))
        if g is None:
            continue
        k = K if shot == "shot_match_saloon" else 1
        g = g.resize((g.width * k, g.height * k), Image.NEAREST)
        s = style_head("front", g.height)
        rows.append([label(s, "bold portrait"), label(g, "ours in the saloon%s" % (", 3x" if k == 3 else ", close view (1x)"))])
    W = max(sum(c.width for c in r) + 10 for r in rows)
    H = sum(max(c.height for c in r) + 10 for r in rows)
    sheet = Image.new("RGB", (W, H), BG)
    y = 0
    for r in rows:
        x = 0
        for c in r:
            sheet.paste(c, (x, y))
            x += c.width + 10
        y += max(c.height for c in r) + 10
    sheet.save(a["--out"])
    print("wrote", a["--out"], sheet.size)
    P.close_landmarker()


if __name__ == "__main__":
    main()
