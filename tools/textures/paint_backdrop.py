#!/usr/bin/env python3
"""The painted backdrop, step 1: have an image model paint the red-rock country round the town,
layer by layer and panel by panel (tools/textures/backdrop.json), each on a green screen so the
game can cut it out and stand it on its own ring.

    OPENROUTER_API_KEY=... python3 tools/textures/paint_backdrop.py [--only=far,near_2] [--repaint]

Every panel is a 21:9 picture of 90 degrees of horizon: the rocks (or hills and trees) rise from
its bottom edge on a flat pure green background, clear of its left and right edges (so panels meet
without a seam: where they meet there's only background, and the other layers fill it), in soft
even daylight (the game lights it again: gold rims at sunset, dark at night). The concept
painting's mountains are the reference for colour and character. Saves
assets/textures/raw/backdrop_<layer>_<n>.jpg; reduce_backdrop.py cuts them into the game's strips.
Uses paint_textures.py's OpenRouter call; runs on GitHub Actions (People workflow, `backdrop`).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as pt  # noqa: E402

SPEC = os.path.join(pt.ROOT, "tools", "textures", "backdrop.json")

ASK = (
    "A wide panorama for a game's backdrop, painted realistically and sharply: {what}. The red-rock "
    "desert country of the American Southwest, seen at eye level from far away, so there's no "
    "perspective: the horizon runs straight across close to the bottom of the picture. {look}. "
    "Sandstone banded in reds, rust, salmon and buff, fluted cliffs, desert-varnish streaks, talus "
    "at the feet of the cliffs. Everything that isn't land stands on a flat, solid, pure bright "
    "green background (#00FF00), like a green screen: no sky, no clouds, no sun, no ground in front. "
    "The land rises from the bottom edge to no more than {rise}% of the picture's height, and "
    "nothing touches the left or right edge (keep a band of green at both sides). Soft, even "
    "daylight from the front, without deep shadows or a sunset glow (it will be lit again). Its "
    "colours and character are those of the reference image, a cropped pixel-art painting: do NOT "
    "copy its square pixels, paint it clean and real. No people, no buildings, no text, no frame."
)


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: backdrop not painted.")
        return
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all"):
            only = a.split("=", 1)[1].split(",")
    repaint = "--repaint" in sys.argv
    spec = json.load(open(SPEC))
    os.makedirs(pt.RAW, exist_ok=True)
    failed = []
    for lid, layer in spec["layers"].items():
        for i, panel in enumerate(layer["panels"]):
            pid = "backdrop_%s_%d" % (lid, i)
            if only and lid not in only and pid[len("backdrop_"):] not in only:
                continue
            out = os.path.join(pt.RAW, pid + ".jpg")
            if os.path.exists(out) and not repaint:
                print("already painted:", pid)
                continue
            prompt = ASK.format(what=panel["what"], look=layer["look"][0].upper() + layer["look"][1:],
                                rise=int(round(layer["rise"] * 100)))
            ref = pt.reference({"ref": panel["ref"]})
            img = None
            for attempt in range(3):
                try:
                    img = pt.ask(prompt, [ref], {"aspect_ratio": "21:9"}, pid, key)
                    break
                except (RuntimeError, OSError, KeyError, ValueError) as e:
                    print("failed (try %d):" % (attempt + 1), e)
            if img is None:
                failed.append(pid)
                continue
            img.save(out, quality=95)
            print("painted:", pid, img.size)
    if failed:
        print("not painted:", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
