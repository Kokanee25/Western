#!/usr/bin/env python3
"""A photo-real stand-in for what a pro character + proper lighting would give us, to practise the
painted-pixel finish on before we have either (DESIGN.md §4).

    OPENROUTER_API_KEY=... python3 tools/style/photo_reference.py

Sends the concept painting (docs/concept/saloon-night.png) to the image model and asks for the same
shot as a photograph. Saves docs/style_test/photo_<n>.png. tools/style/paint_filter.py then turns
a photo back into the painting's look, so we can see how close the filter gets on its own.
The key comes from the environment (a GitHub Actions secret, never the repo).
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request

API = "https://openrouter.ai/api/v1/chat/completions"
MODEL = os.environ.get("FACE_MODEL") or "google/gemini-2.5-flash-image"
OUT = "docs/style_test"

PROMPT = (
    "Recreate this exact scene as a real photograph: a cinematic film still shot on a full-frame "
    "camera, photorealistic, no painting, no pixel art. Same composition, framing and camera angle: "
    "a weathered man in his forties in an 1880s frontier saloon at night, sitting at a round wooden "
    "card table, holding a tin cup, wearing a dark coat, vest, shirt and hat. Lit only by an oil lamp "
    "on the table (warm golden key light on one side of his face, deep brown shadows), tobacco smoke "
    "haze in the air, the dim saloon behind him with the bar, bottles and other drinkers. Real skin "
    "texture, real cloth, natural film grain. Wide image, 16:9."
)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        sys.exit("No OPENROUTER_API_KEY.")
    with open("docs/concept/saloon-night.png", "rb") as f:
        concept = "data:image/png;base64," + base64.b64encode(f.read()).decode()
    os.makedirs(OUT, exist_ok=True)
    for n in range(1, 3):
        body = {
            "model": MODEL,
            "modalities": ["image", "text"],
            "messages": [{"role": "user", "content": [
                {"type": "text", "text": PROMPT},
                {"type": "image_url", "image_url": {"url": concept}},
            ]}],
        }
        req = urllib.request.Request(API, data=json.dumps(body).encode(), headers={
            "Authorization": "Bearer " + key,
            "Content-Type": "application/json",
            "X-Title": "Salt Creek style test",
        })
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                answer = json.load(r)
        except urllib.error.HTTPError as e:
            sys.exit("OpenRouter said %d: %s" % (e.code, e.read().decode(errors="replace")[:1000]))
        images = answer["choices"][0]["message"].get("images") or []
        if not images:
            sys.exit("No image in the answer: %s" % str(answer["choices"][0]["message"].get("content"))[:300])
        raw = base64.b64decode(images[0]["image_url"]["url"].split(",", 1)[1])
        path = os.path.join(OUT, "photo_%d.png" % n)
        with open(path, "wb") as f:
            f.write(raw)
        print("wrote", path, len(raw), "bytes by", MODEL)


if __name__ == "__main__":
    main()
