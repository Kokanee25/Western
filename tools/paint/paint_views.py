#!/usr/bin/env python3
"""Have an image model paint a man's grey views as the concept painting's man (DESIGN.md §4).

    OPENROUTER_API_KEY=... python3 tools/paint/paint_views.py [--only=outlaw] [--views=shot,front,...] [--repaint]

For each view tools/paint_bake.gd rendered (assets/people/paint/<id>_<view>_guide.png: him in plain
grey clay, square), sends the guide and the painting's man (cut from docs/concept/saloon-night.png)
and asks for the guide painted as that man: same outline and pose, the painting's face, clothes,
colours and chunky pixel-art finish. Saves assets/people/paint/<id>_<view>_painted.png at the
guide's size; tools/paint_bake.gd then projects every painted view onto him. Skips views already
painted unless --repaint.

The key comes from the environment (a GitHub Actions secret, never the repo). The model is
OpenRouter's PAINT_MODEL (or FACE_MODEL; default below): any image model that takes images in.
"""
import base64
import io
import json
import os
import sys
import urllib.error
import urllib.request

from PIL import Image

API = "https://openrouter.ai/api/v1/chat/completions"
# An unset repository variable arrives as an empty string, not a missing one.
MODEL = os.environ.get("PAINT_MODEL") or os.environ.get("FACE_MODEL") or "google/gemini-2.5-flash-image"
DIR = "assets/people/paint"
PAINTING = "docs/concept/saloon-night.png"
# The painting's man, in its pixels (x0, y0, x1, y1): hat to the bottom edge, his arm to the cup.
MAN_BOX = (40, 120, 960, 941)

VIEWS = {
    "shot": "from where you sit across the table from him: the same view as the painting",
    "front": "from straight in front of him",
    "three_quarter": "from in front of him and 40 degrees round to his right",
    "side": "from his right side",
    "side_left": "from his left side",
    "back": "from behind him",
}

ASK = (
    "The FIRST image is a plain grey 3D model of a man sitting down, seen {view}. The SECOND image is "
    "a painting of that same man, seated at a card table in a saloon at night: it is how he must look. "
    "Paint the FIRST image as the man in the painting. Copy from the painting: his face, weathered "
    "skin, thick moustache and stubble, dark hair to the collar, his hat with its studded band, his "
    "heavy dark-brown wool coat in mottled blocks, patterned vest, white collar and cuffs, big dark "
    "tie, his hands, and the painting's warm lamplight and its chunky hand-painted pixel-art finish "
    "(visible square blocks of colour, muted warm browns). Keep the FIRST image's shapes exactly: "
    "every edge of him, his hat, arms, hands, legs and anything he holds exactly where they are in "
    "the FIRST image, same size, same pose, nothing added outside his outline and nothing moved. "
    "Parts of him the painting doesn't show (his back, his sides, his legs and boots) are painted "
    "as they would be on that man, in the same clothes and light. {extra}Paint everything that isn't "
    "him plain flat mid grey. Square picture, framed exactly as the FIRST image."
)
EXTRA = {
    "shot": "Here the table, lamp light and cup are as in the painting; the table is the dark shape. ",
}


def data_url(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def reference():
    return Image.open(PAINTING).convert("RGB").crop(MAN_BOX)


def paint(pid, view, ref, key):
    guide_path = os.path.join(DIR, "%s_%s_guide.png" % (pid, view))
    guide = Image.open(guide_path).convert("RGB")
    body = {
        "model": MODEL,
        "modalities": ["image", "text"],
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": ASK.format(view=VIEWS[view], extra=EXTRA.get(view, ""))},
                {"type": "image_url", "image_url": {"url": data_url(guide)}},
                {"type": "image_url", "image_url": {"url": data_url(ref)}},
            ],
        }],
    }
    req = urllib.request.Request(API, data=json.dumps(body).encode(), headers={
        "Authorization": "Bearer " + key,
        "Content-Type": "application/json",
        "X-Title": "Salt Creek people pipeline",
    })
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            answer = json.load(r)
    except urllib.error.HTTPError as e:
        # OpenRouter says why in the body; show it (it never contains the key).
        raise RuntimeError("%s %s: OpenRouter said %d: %s" % (pid, view, e.code, e.read().decode(errors="replace")[:1000])) from None
    message = answer["choices"][0]["message"]
    images = message.get("images") or []
    if not images:
        raise RuntimeError("%s %s: no image in the answer: %s" % (pid, view, str(message.get("content"))[:300]))
    url = images[0]["image_url"]["url"]
    img = Image.open(io.BytesIO(base64.b64decode(url.split(",", 1)[1]))).convert("RGB")
    got = img.size
    # Back to the guide's frame (the bake lays it over the guide's view). A model that answers in
    # another shape has reframed him; say so.
    if abs(got[0] / got[1] - guide.width / guide.height) > 0.02:
        print("warning: %s %s came back %dx%d for a %dx%d guide" % (pid, view, got[0], got[1], guide.width, guide.height))
    img = img.resize(guide.size, Image.LANCZOS)
    out = os.path.join(DIR, "%s_%s_painted.png" % (pid, view))
    img.save(out)
    print("painted", out, "(%dx%d from the model) by" % got, MODEL)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: views not painted.")
        return
    only = None
    views = list(VIEWS)
    repaint = "--repaint" in sys.argv
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1]
        elif a.startswith("--views=") and a.split("=", 1)[1] not in ("", "all"):
            views = a.split("=", 1)[1].split(",")
    ref = reference()
    people = json.load(open("assets/people/people.json"))["people"]
    failed = []
    painted = 0
    for pid in people:
        if only and pid != only:
            continue
        for view in views:
            if not os.path.exists(os.path.join(DIR, "%s_%s_guide.png" % (pid, view))):
                continue
            if os.path.exists(os.path.join(DIR, "%s_%s_painted.png" % (pid, view))) and not repaint:
                print("already painted:", pid, view)
                continue
            try:
                paint(pid, view, ref, key)
                painted += 1
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                # One view failing shouldn't lose the others.
                print("failed:", e)
                failed.append("%s %s" % (pid, view))
    if failed:
        print("not painted:", ", ".join(failed))
        # Keep what did come back (it's committed); fail only if nothing did.
        if painted == 0:
            sys.exit(1)


if __name__ == "__main__":
    main()
