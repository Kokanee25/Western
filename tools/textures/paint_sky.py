#!/usr/bin/env python3
"""The painted sky, step 1 (tools/textures/sky.json; Sean's target docs/concept/targets/7_sky_target.jpg,
2026-10-16): have the image model paint the sky round the town as two 180-degree panels, one toward
the setting sun and one away from it, each from the horizon at its bottom edge to near the top of
the sky, in the target's look (deep blue above, towering cumulus lit gold and rose by the low sun).

    OPENROUTER_API_KEY=... python3 tools/textures/paint_sky.py [--only=sun,away] [--repaint]

Saves assets/textures/raw/sky_<panel>.jpg; reduce_sky.py cuts them for the game. Uses
paint_textures.py's OpenRouter call (and prints each call's cost); runs on GitHub Actions (People
workflow, textures = sky).
"""
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as pt  # noqa: E402

SPEC = os.path.join(pt.ROOT, "tools", "textures", "sky.json")
TARGET = os.path.join(pt.ROOT, "docs", "concept", "targets", "7_sky_target.jpg")

ASK = (
    "A wide panorama of the sky for a game, painted in the style of the reference image (a "
    "luminous, detailed illustration: soft painterly brushwork, glowing light, rich colour): {look}. "
    "The picture spans half the sky, 180 degrees from side to side, seen from the ground with no "
    "perspective tilt: the horizon is a straight line exactly along the bottom edge, and the top "
    "edge is near the top of the sky. Only sky and clouds: no land, no mountains, no trees, no "
    "buildings, no birds, no people, no text, no frame. The left and right edges are open sky and "
    "cloud that could continue on either side."
)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: sky not painted.")
        return
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all", "sky"):
            only = a.split("=", 1)[1].split(",")
    repaint = "--repaint" in sys.argv
    spec = json.load(open(SPEC))["panels"]
    target = Image.open(TARGET).convert("RGB")
    os.makedirs(pt.RAW, exist_ok=True)
    failed = []
    for name, p in spec.items():
        if only and name not in only:
            continue
        out = os.path.join(pt.RAW, "sky_%s.jpg" % name)
        if os.path.exists(out) and not repaint:
            print("already painted:", name)
            continue
        img = None
        for attempt in range(2):
            try:
                img = pt.ask(ASK.format(look=p["look"]), [target.crop(tuple(p["ref"]))], {"aspect_ratio": "21:9"},
                             "sky_" + name, key)
                break
            except (RuntimeError, OSError, KeyError, ValueError) as e:
                print("failed (try %d):" % (attempt + 1), e)
        if img is None:
            failed.append(name)
            continue
        img.save(out, "JPEG", quality=93)
        print("painted: sky_%s %s" % (name, img.size))
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
