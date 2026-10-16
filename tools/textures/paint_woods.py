#!/usr/bin/env python3
"""The woods painted in the man's hand (docs/briefs/match-the-man.md; Sean, 2026-10-16): each of the
game's woods (assets/textures/woods/, grain_woods.py's C, read by PixelArt) repainted by the image
model with the layered cowboy's model sheet (docs/concept/targets/8_man_model.png) as the style
reference, then cut back into the very strips the game reads, so no game code changes.

    OPENROUTER_API_KEY=... python3 tools/textures/paint_woods.py [--only=store_boards,...] [--repaint]
    python3 tools/textures/paint_woods.py --cut [--only=...]     # re-cut the kept paintings, no calls

For a wood with `boards` strips (<wood>_b<k>.png, 2 m along the grain, `rows` across) and, if it is
painted, its bare strip (<wood>_bare.png, the wood under the paint): the strips are stacked one
above another, stretched to the nearest picture shape the model paints, and sent with the man's
sheet. The painting is kept (assets/textures/raw/woods_<wood>.jpg), stretched back, and cut into the
same strips; each strip's two ends crossfaded so it still tiles along its length. The stacked
preview <wood>.png (its first four boards) is rewritten. End grain (<wood>_end.png) is left as it is.
Runs on GitHub Actions (People workflow, textures = woods); each call's cost printed.
"""
import http.client
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as pt  # noqa: E402

WOODS = os.path.join(pt.ROOT, "assets", "textures", "woods")
SPEC = os.path.join(pt.ROOT, "tools", "textures", "woods_grain.json")
MAN = os.path.join(pt.ROOT, "docs", "concept", "targets", "8_man_model.png")
RAW = os.path.join(pt.RAW, "woods_%s.jpg")
# The picture shapes the model paints (width / height).
ASPECTS = {"1:1": 1.0, "4:3": 4 / 3, "3:4": 3 / 4, "3:2": 1.5, "2:3": 2 / 3, "16:9": 16 / 9, "9:16": 9 / 16}
# Texels at each strip's ends crossfaded into each other so it tiles along its length.
WRAP = 24

ASK = (
    "The first image is a stack of {n} wooden boards seen flat and face on, each one a horizontal "
    "strip running the full width of the picture, one above another with no gaps: {what}.{bare} "
    "Repaint it in the same painted hand as the second image, the game's character: the soft, "
    "broad, hand-painted mottling of his vest, trousers and boots, a few painted tones to each "
    "board, gentle grain strokes along its length, knots and worn edges painted, not photographed; "
    "no fine photographic noise or texture. Keep every board exactly where it is, the same height "
    "and the same colour and value as in the first image, every strip straight and horizontal "
    "across the full width. Flat, even light: no shadows, no highlights, no perspective. Only the "
    "boards: no text, no frame, no border."
)
BARE = " The bottom strip is the same wood with its paint worn off: bare weathered wood."


def strips(wood, info):
    """The wood's strips in order: its boards, then its bare strip if it has one."""
    names = ["%s_b%d.png" % (wood, k) for k in range(int(info["boards"]))]
    if os.path.exists(os.path.join(WOODS, "%s_bare.png" % wood)):
        names.append("%s_bare.png" % wood)
    return names


def aspect_for(w, h):
    r = w / h
    return min(ASPECTS.items(), key=lambda kv: abs(np.log(kv[1] / r)))


def what_of(spec, wood):
    w = spec.get(wood, {}).get("what", wood.replace("_", " "))
    return w.split(" (")[0]


def paint(wood, info, spec, key):
    names = strips(wood, info)
    ims = [Image.open(os.path.join(WOODS, n)).convert("RGB") for n in names]
    w = ims[0].width
    stack = Image.new("RGB", (w, sum(i.height for i in ims)))
    y = 0
    for i in ims:
        stack.paste(i, (0, y))
        y += i.height
    name, r = aspect_for(stack.width, stack.height)
    send = stack.resize((1024, int(round(1024 / r))), Image.LANCZOS)
    man = Image.open(MAN).convert("RGB")
    man.thumbnail((768, 768))  # the style, not the detail: a smaller request (a 1024 one dropped mid-reply)
    bare = BARE if names[-1].endswith("_bare.png") else ""
    img = pt.ask(ASK.format(n=len(names), what=what_of(spec, wood), bare=bare), [send, man],
                 {"aspect_ratio": name}, "woods_" + wood, key)
    img.convert("RGB").save(RAW % wood, "JPEG", quality=94)
    print("painted: woods_%s %s (%s)" % (wood, img.size, name))


def wrap(strip):
    """A strip seamless along its length: its last WRAP texels crossfaded over its first."""
    a = np.asarray(strip).astype(np.float32)
    w = a.shape[1]
    t = np.linspace(0.0, 1.0, WRAP)[None, :, None]
    head = a[:, :WRAP] * t + a[:, w - WRAP:] * (1.0 - t)
    out = np.concatenate([head, a[:, WRAP:w - WRAP]], axis=1)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).resize((w, a.shape[0]), Image.LANCZOS)


def cut(wood, info):
    names = strips(wood, info)
    sizes = [Image.open(os.path.join(WOODS, n)).size for n in names]
    w = sizes[0][0]
    h = sum(s[1] for s in sizes)
    painted = Image.open(RAW % wood).convert("RGB").resize((w * 4, h * 4), Image.LANCZOS)
    y = 0
    out = []
    for n, (sw, sh) in zip(names, sizes):
        piece = painted.crop((0, y * 4, w * 4, (y + sh) * 4)).resize((sw, sh), Image.LANCZOS)
        piece = wrap(piece)
        piece.save(os.path.join(WOODS, n))
        out.append(piece)
        y += sh
    boards = [p for n, p in zip(names, out) if not n.endswith("_bare.png")][:4]
    preview = Image.new("RGB", (w, sum(p.height for p in boards)))
    y = 0
    for p in boards:
        preview.paste(p, (0, y))
        y += p.height
    preview.save(os.path.join(WOODS, "%s.png" % wood))
    print("cut: %s into %d strips" % (wood, len(names)))


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all", "woods"):
            only = a.split("=", 1)[1].split(",")
    cut_only = "--cut" in sys.argv
    repaint = "--repaint" in sys.argv
    lab = json.load(open(os.path.join(WOODS, "lab.json")))["woods"]
    spec = json.load(open(SPEC))["woods"]
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not cut_only and not key:
        print("No OPENROUTER_API_KEY: woods not painted.")
        return
    os.makedirs(pt.RAW, exist_ok=True)
    failed = []
    for wood, info in lab.items():
        if only and wood not in only:
            continue
        if not cut_only and (repaint or not os.path.exists(RAW % wood)):
            for attempt in range(2):
                try:
                    paint(wood, info, spec, key)
                    break
                except (RuntimeError, OSError, KeyError, ValueError, http.client.HTTPException) as e:
                    print("failed (try %d):" % (attempt + 1), e)
            else:
                failed.append(wood)
                continue
        if os.path.exists(RAW % wood):
            cut(wood, info)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
