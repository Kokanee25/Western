#!/usr/bin/env python3
"""The texture factory, step 1: have an image model paint each material as a clean, detailed,
evenly lit surface (DESIGN.md §4 "A texture factory for the world").

    OPENROUTER_API_KEY=... python3 tools/textures/paint_textures.py [--only=floor,road] [--for=saloon]
        [--repaint]

For each material in tools/textures/materials.json, sends its description and a crop of the
concept painting (its colours and character; the model is told not to copy the painting's
pixels) and saves what comes back as assets/textures/raw/<id>.jpg (big, realistic, not
pixelated). tools/textures/reduce.py then makes it seamless and cuts it to tiles and a palette,
the same way for every material: realistic detail first, then tiles. Skips materials already
painted unless --repaint. The key comes from the environment (a GitHub Actions secret, never the
repo); the model is TEXTURE_MODEL, else PAINT_MODEL, else FLUX.2 [max].
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
MODEL = os.environ.get("TEXTURE_MODEL") or os.environ.get("PAINT_MODEL") or "black-forest-labs/flux.2-max"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPEC = os.path.join(ROOT, "tools", "textures", "materials.json")
RAW = os.path.join(ROOT, "assets", "textures", "raw")
PAINTINGS = {"saloon": "docs/concept/saloon-night.png", "street": "docs/concept/street-golden-hour.png"}

TILE = (
    "A seamless, tileable texture: {what}. Seen perfectly straight on (orthographic, no perspective, "
    "no vanishing lines), filling the whole frame edge to edge with the surface and nothing else. "
    "Soft, even, flat light with no cast shadows and no highlights, so it can be lit again in a game. "
    "Realistic and sharp, with rich detail and many close shades of colour. Its colours and character "
    "are those of the surface in the reference image, which is a cropped pixel-art painting: do NOT "
    "copy its square pixels or blocks, paint a clean, detailed real surface instead. No text, no "
    "objects, no border, no vignette, no frame."
)
GROUND = TILE.replace("Seen perfectly straight on (orthographic, no perspective, no vanishing lines)",
                      "Seen from directly above (orthographic, no perspective, no horizon)")
SIGN = (
    "A flat, straight-on picture of {what}. The board fills the whole frame edge to edge, seen "
    "perfectly square on (orthographic, no perspective), in soft, even, flat light with no cast "
    "shadows. The lettering reads exactly \"{text}\", spelled exactly so, big, clear and centred, "
    "hand-painted with crisp edges, a little worn. Realistic and sharp, rich weathering. Its colours "
    "and character are those of the sign in the reference image, which is a cropped pixel-art "
    "painting: do NOT copy its square pixels, paint a clean, detailed real board instead. No other "
    "text, no building, no sky, no border."
)


def data_url(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def aspect_name(metres):
    """The nearest aspect ratio image models are commonly asked for."""
    want = metres[0] / metres[1]
    options = {"1:1": 1.0, "4:3": 4 / 3, "3:2": 1.5, "16:9": 16 / 9, "21:9": 21 / 9,
               "3:4": 3 / 4, "2:3": 2 / 3, "9:16": 9 / 16}
    return min(options, key=lambda k: abs(options[k] - want))


def ask(prompt, images, config, what, key):
    """One request; returns the image it painted (as paint_views.py does)."""
    body = {
        "model": MODEL,
        "modalities": ["image", "text"] if "gemini" in MODEL or "gpt" in MODEL else ["image"],
        "messages": [{
            "role": "user",
            "content": [{"type": "text", "text": prompt}]
            + [{"type": "image_url", "image_url": {"url": data_url(im)}} for im in images],
        }],
        "image_config": config,
    }
    for attempt in (0, 1):
        req = urllib.request.Request(API, data=json.dumps(body).encode(), headers={
            "Authorization": "Bearer " + key,
            "Content-Type": "application/json",
            "X-Title": "Salt Creek texture factory",
        })
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                answer = json.load(r)
            break
        except urllib.error.HTTPError as e:
            said = e.read().decode(errors="replace")[:1000]
            if attempt == 0 and e.code == 400 and "image_config" in body:
                print("%s: OpenRouter said %d (%s); again without image_config" % (what, e.code, said[:200]))
                del body["image_config"]
                continue
            raise RuntimeError("%s: OpenRouter said %d: %s" % (what, e.code, said)) from None
    if not answer.get("choices"):
        raise RuntimeError("%s: no answer: %s" % (what, json.dumps(answer)[:400]))
    message = answer["choices"][0]["message"]
    images = message.get("images") or []
    if not images:
        raise RuntimeError("%s: no image in the answer: %s" % (what, str(message.get("content"))[:300]))
    url = images[0]["image_url"]["url"]
    return Image.open(io.BytesIO(base64.b64decode(url.split(",", 1)[1]))).convert("RGB")


def reference(spec):
    painting, x0, y0, x1, y1 = spec["ref"]
    return Image.open(os.path.join(ROOT, PAINTINGS[painting])).convert("RGB").crop((x0, y0, x1, y1))


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: textures not painted.")
        return
    only = None
    group = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all"):
            only = a.split("=", 1)[1].split(",")
        elif a.startswith("--for=") and a.split("=", 1)[1]:
            group = a.split("=", 1)[1]
    repaint = "--repaint" in sys.argv
    materials = json.load(open(SPEC))["materials"]
    os.makedirs(RAW, exist_ok=True)
    painted, failed = 0, []
    for mid, spec in materials.items():
        if only and mid not in only:
            continue
        if group and spec.get("for") != group:
            continue
        out = os.path.join(RAW, mid + ".jpg")
        if os.path.exists(out) and not repaint:
            print("already painted:", mid)
            continue
        kind = spec["kind"]
        prompt = (SIGN if kind == "sign" else GROUND if kind == "ground" else TILE).format(
            what=spec["what"], text=spec.get("text", ""))
        img = None
        for attempt in range(3):
            try:
                img = ask(prompt, [reference(spec)], {"aspect_ratio": aspect_name(spec["metres"])}, mid, key)
                break
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed (try %d):" % (attempt + 1), e)
        if img is None:
            failed.append(mid)
            continue
        # Kept big enough to reduce well, small enough for git.
        if max(img.size) > 1536:
            s = 1536 / max(img.size)
            img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
        img.save(out, "JPEG", quality=92)
        painted += 1
        print("painted:", mid, img.size)
    if failed:
        print("not painted:", ", ".join(failed))
        if painted == 0:
            sys.exit(1)


if __name__ == "__main__":
    main()
