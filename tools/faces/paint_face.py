#!/usr/bin/env python3
"""Have an image model paint a person's face onto his head (DESIGN.md §4, step 4).

    OPENROUTER_API_KEY=... python3 tools/faces/paint_face.py [--only=outlaw] [--repaint]

For each person in assets/people/people.json with a `face` description: sends the front view of
his fitted head (assets/people/<id>_face_guide.png, written by tools/blender/make_people.py) and a
style reference (assets/people/face_style_ref.png, cut from the concept painting), and asks for
his face painted onto that head, same outline and features in the same places. The answer is
saved as assets/people/<id>_face_portrait.png; the next make_people.py run projects it onto the
head. Skips people who already have a portrait unless --repaint.

The key comes from the environment (a GitHub Actions secret, never the repo). The model is
OpenRouter's FACE_MODEL (default below); any image model OpenRouter serves that takes images in.
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request

API = "https://openrouter.ai/api/v1/chat/completions"
# An unset repository variable arrives as an empty string, not a missing one.
MODEL = os.environ.get("FACE_MODEL") or "google/gemini-2.5-flash-image"
PEOPLE = "assets/people"

STYLE = (
    "Paint this man's face onto the plain grey head in the FIRST image. Keep the head exactly as it is "
    "in that image: the same size, outline and position in the frame, the eyes, nose, mouth and ears "
    "exactly where they are, looking straight at us. Paint in the style of the SECOND image (a detail "
    "of our concept painting): chunky hand-painted pixel art, muted warm browns, visible square "
    "pixels. Even, flat, frontal light: no strong shadows or highlights, no lamp glow (the game lights "
    "him). No hat, and no hair above the hairline (a hat covers it). Transparent or plain white "
    "background outside the head. Square image, the same framing as the first image. The man: "
)


def data_url(path):
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode()


def paint(pid, description, key):
    guide = os.path.join(PEOPLE, "%s_face_guide.png" % pid)
    style = os.path.join(PEOPLE, "face_style_ref.png")
    body = {
        "model": MODEL,
        "modalities": ["image", "text"],
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": STYLE + description},
                {"type": "image_url", "image_url": {"url": data_url(guide)}},
                {"type": "image_url", "image_url": {"url": data_url(style)}},
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
        raise RuntimeError("%s: OpenRouter said %d: %s" % (pid, e.code, e.read().decode(errors="replace")[:1000])) from None
    message = answer["choices"][0]["message"]
    images = message.get("images") or []
    if not images:
        raise RuntimeError("%s: no image in the answer: %s" % (pid, str(message.get("content"))[:300]))
    url = images[0]["image_url"]["url"]
    raw = base64.b64decode(url.split(",", 1)[1])
    out = os.path.join(PEOPLE, "%s_face_portrait.png" % pid)
    with open(out, "wb") as f:
        f.write(raw)
    print("painted", out, len(raw), "bytes by", MODEL)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: faces not painted (the painted fallback face is used).")
        return
    only = None
    repaint = "--repaint" in sys.argv
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1]
    people = json.load(open(os.path.join(PEOPLE, "people.json")))["people"]
    for pid, spec in people.items():
        if only and pid != only or "face" not in spec:
            continue
        if os.path.exists(os.path.join(PEOPLE, "%s_face_portrait.png" % pid)) and not repaint:
            print("already painted:", pid)
            continue
        paint(pid, spec["face"], key)


if __name__ == "__main__":
    main()
