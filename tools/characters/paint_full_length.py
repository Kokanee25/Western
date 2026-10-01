#!/usr/bin/env python3
"""Characters by image-to-3D, step 1: have an image model paint a man full length, the way an
image-to-3D service wants him (DESIGN.md §4 "The plan from here" 1).

    OPENROUTER_API_KEY=... python3 tools/characters/paint_full_length.py [--only=stranger] [--repaint]

For each man in tools/characters/characters.json: his description, and the concept painting's man
(his face and clothes, cut from docs/concept/saloon-night.png) as the reference for who he is,
painted standing straight in an A-pose (arms out and down, legs a little apart), seen from the
front, whole body from hat to boots, in flat even light on a plain light-grey ground, realistic
(not pixelated: the tiles are made afterwards, as for everything). Saves
assets/people/tripo/<id>_full.png. tools/characters/tripo.py turns it into a model.
"""
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures"))
import paint_textures as pt  # noqa: E402  (the OpenRouter call, shared)

from PIL import Image  # noqa: E402

ROOT = pt.ROOT
SPEC = os.path.join(ROOT, "tools", "characters", "characters.json")
OUT = os.path.join(ROOT, "assets", "people", "tripo")
ASK = (
    "A full-length character reference for a 3D model: {what}. He stands perfectly straight facing "
    "the viewer in an A-pose (arms held straight out and down at 45 degrees from his body, palms "
    "down, fingers together; feet a little apart), the whole of him in the frame from the top of "
    "his hat to the soles of his boots with a little space round him, seen straight on at his "
    "chest's height (no perspective). Soft, even, flat studio light from the front, no cast "
    "shadows, a plain light grey background. Realistic and sharp, every detail of his face, hat and "
    "clothes clear. He is the man in the reference image (a cropped pixel-art painting): his face, "
    "moustache, hair, hat and clothes, but painted clean and real, NOT in square pixels. Nothing "
    "in his hands, nothing else in the picture, no text."
)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: nobody painted.")
        return
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1]:
            only = a.split("=", 1)[1].split(",")
    repaint = "--repaint" in sys.argv
    people = json.load(open(SPEC))["characters"]
    os.makedirs(OUT, exist_ok=True)
    painting = Image.open(os.path.join(ROOT, "docs", "concept", "saloon-night.png")).convert("RGB")
    failed = []
    for cid, spec in people.items():
        if only and cid not in only:
            continue
        out = os.path.join(OUT, cid + "_full.png")
        if os.path.exists(out) and not repaint:
            print("already painted:", cid)
            continue
        refs = [painting.crop(tuple(b)) for b in spec.get("refs", [])]
        img = None
        for attempt in range(3):
            try:
                img = pt.ask(ASK.format(what=spec["what"]), refs, {"aspect_ratio": "3:4"}, cid, key)
                break
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed (try %d):" % (attempt + 1), e)
        if img is None:
            failed.append(cid)
            continue
        img.save(out)
        print("painted:", cid, img.size)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
