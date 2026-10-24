#!/usr/bin/env python3
"""New reference paintings for the judge and the blind critic (Sean, 2026-10-16: the old ones are
drawn in squares under a clear sky and argue with the painted-illustration look, DESIGN.md §4, and
his sky and road targets). Each repaints an old painting's shot (`base`: its composition, kept) in
the new look, beside the targets that set it (`refs`), as tools/textures/references.json lists.

    OPENROUTER_API_KEY=... python3 tools/textures/paint_reference.py [--only=street] [--repaint]

Saves assets/textures/raw/ref_<name>.jpg, or a reference's own `out` (the People workflow commits
assets/textures and docs/concept/judge); a reference
replaces its old painting in tools/judge.py only once Sean has seen it. Uses paint_textures.py's
OpenRouter call (and prints each call's cost); runs on GitHub Actions (People workflow,
textures = reference).
"""
import http.client
import json
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import paint_textures as pt  # noqa: E402

SPEC = os.path.join(pt.ROOT, "tools", "textures", "references.json")

ASK = (
    "Repaint the first image as the same picture: keep its composition exactly, the same camera, "
    "the same buildings, signs, people, animals and objects in the same places and at the same "
    "sizes, and the same time of day. Do not zoom out, widen, crop or move the camera: each edge "
    "of the new picture shows what the same edge of the first image shows, and nothing is added "
    "or left out. Change only how it is painted: {look} {finish}"
)
# A new picture with no base to repaint (`scene` in place of `base`): the refs set its hand.
NEW = (
    "Paint a new picture: {scene} Paint it in exactly the same hand as the images given: the same "
    "painted style, palette, light and level of detail, as if by the same artist for the same game. "
    "Wide 16:9 frame, eye level unless said otherwise. {finish}"
)
# The ending a reference gets unless it gives its own `finish` (the judge's set has a bit of square,
# Sean 2026-10-17).
FINISH = ("No pixel squares, blocks or mosaic anywhere: a luminous, detailed painted illustration "
          "with soft painterly brushwork and rich colour. No added text, no frame, no border.")


def main():
    key = os.environ.get("OPENROUTER_API_KEY", "")
    if not key:
        print("No OPENROUTER_API_KEY: references not painted.")
        return
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only=") and a.split("=", 1)[1] not in ("", "all", "reference"):
            only = a.split("=", 1)[1].split(",")
    repaint = "--repaint" in sys.argv
    spec = json.load(open(SPEC))["references"]
    os.makedirs(pt.RAW, exist_ok=True)
    failed = []
    for name, r in spec.items():
        if only and name not in only:
            continue
        out = os.path.join(pt.ROOT, r["out"] % name.replace("judge_", "")) if "out" in r else os.path.join(pt.RAW, "ref_%s.jpg" % name)
        if os.path.exists(out) and not repaint:
            print("already painted:", name)
            continue
        images = []
        for p in ([r["base"]] if "base" in r else []) + r["refs"]:
            im = Image.open(os.path.join(pt.ROOT, p)).convert("RGB")
            im.thumbnail((1344, 1344))  # sent as PNG: full-size pictures made the request huge
            images.append(im)
        img = None
        for attempt in range(2):
            try:
                # `prompt`: the entry's own words in full (OpenAI's model refuses NEW's "the same hand
                # as the artist", 2026-10-24, run 120, though the images are the game's own).
                prompt = (r["prompt"] if "prompt" in r
                          else ASK.format(look=r["look"], finish=r.get("finish", FINISH)) if "base" in r
                          else NEW.format(scene=r["scene"], finish=r.get("finish", FINISH)))
                img = pt.ask(prompt, images,
                             {"aspect_ratio": r.get("aspect", "16:9")}, "ref_" + name, key)
                break
            except (RuntimeError, OSError, KeyError, ValueError, http.client.HTTPException) as e:
                print("failed (try %d):" % (attempt + 1), e)
        if img is None:
            failed.append(name)
            continue
        img.save(out, "JPEG", quality=94)
        print("painted: ref_%s %s" % (name, img.size))
    if failed:
        # The ones painted are still committed (a run that painted none fails).
        print("not painted:", ", ".join(failed))
        if len(failed) == len([n for n in spec if not only or n in only]):
            sys.exit(1)


if __name__ == "__main__":
    main()
