#!/usr/bin/env python3
"""The blind critic (CLAUDE.md "Art merges get a blind critic"; docs/briefs/review-tools.md,
art item 2): after every art merge, a fresh sub-agent that has not seen the work or its
reasoning gets only the concept paintings and the new renders, and lists the five biggest
differences a viewer would notice, with crops. Saved as critic.md in the judge round; its top
three go in the status entry. The judge (tools/judge.py) measures style; the critic says what
a person sees. Use both to choose what's next.

  python3 tools/critic.py prepare ROUND [--extra=DIR]
      lays the paintings (at the renders' 1280x720) and the round's renders out in
      ROUND/critic/ and prints the prompt to give the sub-agent (the Agent tool,
      general-purpose, a fresh context: paste the prompt as its whole task)
  python3 tools/critic.py crop ROUND VIEW X Y W H SLUG
      the sub-agent's tool: cuts the same box (1280x720 coordinates) from the render and the
      painting of VIEW (saloon | street, or the name of an extra render), side by side at 3x,
      labelled, into ROUND/critic/<n>_<slug>.png; prints the path to cite in critic.md
  python3 tools/critic.py top ROUND
      prints the top three from ROUND/critic/critic.md (for the status entry)

ROUND is a judge round folder, e.g. docs/screenshots/judge/2026-10-04_r1. The critic's files
stay in the round (every round is kept).
"""
import argparse
import os
import re
import shutil
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1280, 720
VIEWS = {
    "saloon": ("shot_match_saloon.png", "docs/concept/saloon-night.png", "the saloon at night, the man at the card table"),
    "street": ("shot_match_street.png", "docs/concept/street-golden-hour.png", "the street at golden hour, revolver at the hip"),
}
SCALE = 3

PROMPT = """You are a blind critic for a video game's look. You have NOT seen the game's code, its
history or anyone's reasoning, and you must not read any of it: do not open any file but the
images named here, and do not search the repository. Judge only with your eyes.

The target look is two concept paintings. The game renders the same two shots. For each pair,
look hard at the painting and the render at the same size, then list the FIVE biggest
differences a viewer would notice between the renders and the paintings, biggest first, across
both shots together (say which shot each is in). Think like a viewer, not a tester: light and
shadow, colour, what things look like, how much is going on, the pixel style (the paintings are
cut into small squares of flat colour), the people, the mood. A difference should be something
one could act on ("the lamp's glass is a flat orange disc; the painting's is near-white over the
flame with a halo"), not a score.

Files (all 1280x720):
{files}

For each difference, make one crop with the tool below, picking a box (in 1280x720 pixels,
x y w h; keep it under about 420x240 so the 3x crop fits) that shows it best; the tool cuts the
same box from the render and the painting side by side:

  cd {root} && python3 tools/critic.py crop {round} VIEW X Y W H slug

(VIEW is saloon or street{extra_note}.) It prints the picture's path. Look at the crop to check it shows
what you mean; make another if not.

Then write {md} in this form, nothing else before it:

# Blind critic, {round_name}

1. **<the difference in a few words>** (<saloon|street>). <Two or three sentences: what the
   painting has, what the render has, what a viewer feels about it.> Crop: `critic/<file>.png`
2. ...
5. ...

**What's closest:** one or two sentences on what the renders already get right.

Write the file with the Write tool. Do not edit anything else."""


def ensure_dir(round_dir):
    d = os.path.join(round_dir, "critic")
    os.makedirs(d, exist_ok=True)
    return d


def painting(view, extra_dir=None):
    if view in VIEWS:
        return os.path.join(ROOT, VIEWS[view][1])
    return None


def load(path):
    img = Image.open(path).convert("RGB")
    if img.size != (W, H):
        img = img.resize((W, H), Image.LANCZOS)
    return img


def prepare(round_dir, extra):
    d = ensure_dir(round_dir)
    files = []
    for key, (render_name, painting_path, what) in VIEWS.items():
        src = os.path.join(round_dir, render_name)
        if not os.path.exists(src):
            print("no render %s in %s" % (render_name, round_dir), file=sys.stderr)
            sys.exit(1)
        load(os.path.join(ROOT, painting_path)).save(os.path.join(d, "painting_%s.png" % key))
        load(src).save(os.path.join(d, "render_%s.png" % key))
        files.append("- %s: painting %s, render %s" % (what,
                     os.path.join(round_dir, "critic", "painting_%s.png" % key),
                     os.path.join(round_dir, "critic", "render_%s.png" % key)))
    extra_note = ""
    if extra:
        names = sorted(f for f in os.listdir(extra) if f.endswith(".png"))
        for f in names:
            shutil.copyfile(os.path.join(extra, f), os.path.join(d, "extra_" + f))
            files.append("- another render of the game, no painting for it (judge it against both paintings' style): %s"
                         % os.path.join(round_dir, "critic", "extra_" + f))
        if names:
            extra_note = ", or an extra render's name without extra_ and .png"
    print(PROMPT.format(files="\n".join(files), root=ROOT, round=os.path.relpath(round_dir, ROOT),
                        round_name=os.path.basename(os.path.normpath(round_dir)),
                        md=os.path.join(round_dir, "critic", "critic.md"), extra_note=extra_note))


def crop(round_dir, view, x, y, w, h, slug):
    d = ensure_dir(round_dir)
    if view in VIEWS:
        render = load(os.path.join(round_dir, VIEWS[view][0]))
        paint = load(os.path.join(ROOT, VIEWS[view][1]))
        right_label = "painting"
    else:
        path = os.path.join(d, "extra_%s.png" % view)
        if not os.path.exists(path):
            print("no such view: %s" % view, file=sys.stderr)
            sys.exit(1)
        render = load(path)
        paint = load(os.path.join(ROOT, VIEWS["saloon"][1]))  # the style reference beside it
        right_label = "painting (saloon, for the style)"
    x, y = max(0, min(x, W - 1)), max(0, min(y, H - 1))
    w, h = max(8, min(w, W - x)), max(8, min(h, H - y))
    box = (x, y, x + w, y + h)
    a = render.crop(box).resize((w * SCALE, h * SCALE), Image.NEAREST)
    b = paint.crop(box).resize((w * SCALE, h * SCALE), Image.NEAREST)
    out = Image.new("RGB", (w * SCALE * 2 + 12, h * SCALE + 22), (20, 20, 20))
    out.paste(a, (0, 22))
    out.paste(b, (w * SCALE + 12, 22))
    dr = ImageDraw.Draw(out)
    dr.text((4, 5), "render  (%s %d,%d %dx%d)" % (view, x, y, w, h), fill=(255, 255, 255))
    dr.text((w * SCALE + 16, 5), right_label, fill=(255, 255, 255))
    n = 1 + len([f for f in os.listdir(d) if re.match(r"^\d+_.*\.png$", f)])
    slug = re.sub(r"[^a-z0-9]+", "_", slug.lower()).strip("_") or "crop"
    path = os.path.join(d, "%d_%s.png" % (n, slug))
    out.save(path)
    print(path)


def top(round_dir):
    path = os.path.join(round_dir, "critic", "critic.md")
    with open(path) as f:
        items = [line.strip() for line in f if re.match(r"^\d\. ", line)]
    for line in items[:3]:
        print(re.sub(r"\s*Crop: `[^`]*`", "", line))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("prepare")
    p.add_argument("round")
    p.add_argument("--extra", default=None)
    c = sub.add_parser("crop")
    c.add_argument("round")
    c.add_argument("view")
    for k in ("x", "y", "w", "h"):
        c.add_argument(k, type=int)
    c.add_argument("slug")
    t = sub.add_parser("top")
    t.add_argument("round")
    args = ap.parse_args()
    if args.cmd == "prepare":
        prepare(args.round, args.extra)
    elif args.cmd == "crop":
        crop(args.round, args.view, args.x, args.y, args.w, args.h, args.slug)
    else:
        top(args.round)


if __name__ == "__main__":
    main()
