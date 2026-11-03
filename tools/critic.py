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
  python3 tools/critic.py judge OUT IMAGE [IMAGE...]
      the art judge (docs/concept/judge/RUBRIC.md, 2026-10-18): lays the images (named a, b,
      c... so nothing in a filename gives them away) and Sean's reference set out in OUT/ and
      prints the prompt for a fresh sub-agent, which writes OUT/verdict.md: per image, each
      trait PASS / FAIL / N/A and the three biggest problems with their cause and a fix
  python3 tools/critic.py cut OUT NAME X Y W H SLUG
      the judge's tool: a box of image NAME (a, b, ...) at 3x into OUT/<slug>.png
  python3 tools/critic.py cheap OUT VIEW [VIEW...] [--from=DIR] [--film=DIR]
      the "this looks cheap" judge (docs/concept/judge/CHEAP.md, #609): each VIEW (a render
      DIR/VIEW.png, or a path to a PNG) laid out as a, b, c... in OUT/, a film strip of DIR's
      frames as the last letter, the concept targets for the verdict's top end; prints the prompt
      for a fresh sub-agent, which writes OUT/cheap.md (each tell PASS/FAIL/N/A with a crop, a
      verdict on the scale, the five biggest reasons with cause and cheapest fix). The measures
      (light, atmosphere, repetition) go in OUT/numbers.md, not shown to the agent. Its tool is
      `cut` above.
  python3 tools/critic.py cheap-log OUT [--round=NAME] [--note=...]
      reads OUT/cheap.md, prints each view's verdict beside its numbers, and adds one line per
      view to docs/screenshots/judge/history.md ("cheap -> good indie -> AA" down the page)
  python3 tools/critic.py cheap-probes OUT [--check | --numbers]
      the judge's self-test: the game's own old renders of one shot (cheap_probes/, ranked by
      Sean in ranking.json) shuffled under letters, the same prompt; --check fails unless the
      agent's cheap.md ranks them as Sean did; --numbers checks the measures alone (no agent)

ROUND is a judge round folder, e.g. docs/screenshots/judge/2026-10-04_r1. The critic's files
stay in the round (every round is kept).
"""
import argparse
import json
import os
import re
import shutil
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1280, 720
VIEWS = {
    "saloon": ("shot_match_saloon.png", "docs/concept/saloon-painted.png", "the saloon at night, the man at the card table"),
    "street": ("shot_match_street.png", "docs/concept/street-golden-hour-painted.png", "the street at golden hour, revolver at the hip"),
    # Only when the round has it (judge.py --only=...,fire).
    "fire": ("livery_fire_dusk.png", "docs/concept/livery-fire-painted.png", "the livery burning at dusk, seen from the street"),
}
OPTIONAL = {"fire"}
SCALE = 3

PROMPT = """You are a blind critic for a video game's look. You have NOT seen the game's code, its
history or anyone's reasoning, and you must not read any of it: do not open any file but the
images named here, and do not search the repository. Judge only with your eyes.

The target look is the concept paintings below. The game renders the same shots. For each pair,
look hard at the painting and the render at the same size, then list the FIVE biggest
differences a viewer would notice between the renders and the paintings, biggest first, across
all the shots together (say which shot each is in). Think like a viewer, not a tester: light and
shadow, colour, what things look like, how much is going on, the painting style (the paintings
are painted illustrations with soft brushwork; the game's look is painted with a bit of square
showing, as its main character's model sheet is, so small squares are not a difference in
themselves: only coarse or noisy squares beside smooth work are), the people, the mood. A difference should be something
one could act on ("the lamp's glass is a flat orange disc; the painting's is near-white over the
flame with a halo"), not a score.

Files (all 1280x720):
{files}

For each difference, make one crop with the tool below, picking a box (in 1280x720 pixels,
x y w h; keep it under about 420x240 so the 3x crop fits) that shows it best; the tool cuts the
same box from the render and the painting side by side:

  cd {root} && python3 tools/critic.py crop {round} VIEW X Y W H slug

(VIEW is {view_names}{extra_note}.) It prints the picture's path. Look at the crop to check it shows
what you mean; make another if not.

Then write {md} in this form, nothing else before it:

# Blind critic, {round_name}

1. **<the difference in a few words>** (<{view_bar}>). <Two or three sentences: what the
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
    round_dir = os.path.abspath(round_dir)
    d = ensure_dir(round_dir)
    files = []
    keys = []
    for key, (render_name, painting_path, what) in VIEWS.items():
        src = os.path.join(round_dir, render_name)
        if not os.path.exists(src) and key in OPTIONAL:
            continue
        if not os.path.exists(src):
            print("no render %s in %s" % (render_name, round_dir), file=sys.stderr)
            sys.exit(1)
        keys.append(key)
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
                        md=os.path.join(round_dir, "critic", "critic.md"), extra_note=extra_note,
                        view_names=" or ".join(keys), view_bar="|".join(keys)))


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


JUDGE_DIR = os.path.join(ROOT, "docs", "concept", "judge")
# The references the judge is shown (README.md): the authority first, then the style pictures.
JUDGE_REFS = ["10_authority_saloon_man.jpg", "05_style_table_lantern.jpg", "08_style_street_a.jpg",
              "09_style_street_b.jpg", "11_style_saloon_bar.jpg", "13_style_saloon_door.jpg",
              "14_style_man_saloon_front.jpg"]

JUDGE_PROMPT = """You are Salt Creek's art judge. You have NOT seen the game's code, its history or
anyone's reasoning, and you must not read any of it: open only the files named here. Judge with
your eyes.

Read the rubric first: {rubric}

The references (the first is the authority, which wins when they disagree):
{refs}

The pictures to judge (each on its own; some may be references for other games, some renders of
this one; judge each against the rubric and the authority, not against each other):
{images}

For each problem you name, cut its box to look at it closely (it prints the path; look at it):

  cd {root} && python3 tools/critic.py cut {out} NAME X Y W H slug

Then write {md} in this form, nothing else before it:

# Art judge, {name}

## <image name, e.g. a>
- Shapes: PASS|FAIL|N/A (the region that decides it)
- Painted surface: PASS|FAIL|N/A (...)
- Light: PASS|FAIL|N/A (...)
- People: PASS|FAIL|N/A (...)
- One hand: PASS|FAIL|N/A (...)
- **Verdict: PASS|FAIL**
1. **<problem>** (`x y w h`): <what's wrong against the authority>. Cause: paint|shape|light. Fix: <one thing to try>.
2. ...
3. ...

(one section per image, in order). Write it with the Write tool. Do not edit anything else."""


def judge(out, images):
    out = os.path.abspath(out)
    os.makedirs(out, exist_ok=True)
    refs = []
    for i, f in enumerate(JUDGE_REFS):
        dst = os.path.join(out, "ref_%d.jpg" % (i + 1))
        shutil.copyfile(os.path.join(JUDGE_DIR, f), dst)
        refs.append("- ref_%d%s: %s" % (i + 1, " (the authority)" if i == 0 else "", dst))
    listed = []
    for i, src in enumerate(images):
        name = chr(ord("a") + i)
        Image.open(src).convert("RGB").save(os.path.join(out, name + ".png"))
        listed.append("- %s: %s" % (name, os.path.join(out, name + ".png")))
    with open(os.path.join(out, "sources.txt"), "w") as f:
        f.write("".join("%s %s\n" % (chr(ord("a") + i), src) for i, src in enumerate(images)))
    print(JUDGE_PROMPT.format(rubric=os.path.join(JUDGE_DIR, "RUBRIC.md"), refs="\n".join(refs),
                              images="\n".join(listed), root=ROOT, out=os.path.relpath(out, ROOT),
                              md=os.path.join(out, "verdict.md"), name=os.path.basename(out)))


def cut(out, name, x, y, w, h, slug):
    img = Image.open(os.path.join(out, name + ".png")).convert("RGB")
    x, y = max(0, min(x, img.width - 1)), max(0, min(y, img.height - 1))
    w, h = max(8, min(w, img.width - x)), max(8, min(h, img.height - y))
    piece = img.crop((x, y, x + w, y + h)).resize((w * SCALE, h * SCALE), Image.NEAREST)
    slug = re.sub(r"[^a-z0-9]+", "_", slug.lower()).strip("_") or "cut"
    path = os.path.join(out, "%s_%s.png" % (name, slug))
    piece.save(path)
    print(path)


# --- the "this looks cheap" judge (CHEAP.md, #609) -----------------------------------------

CHEAP_RUBRIC = os.path.join(JUDGE_DIR, "CHEAP.md")
CHEAP_PROBES = os.path.join(JUDGE_DIR, "cheap_probes")
TARGETS_DIR = os.path.join(ROOT, "docs", "concept", "targets")
# The top of the scale (CHEAP.md): the concept targets, never commercial games' screenshots.
CHEAP_TARGETS = ["3_street_golden_target.jpg", "2_saloon_night_target.jpg", "1_man_at_table_target.jpg",
                 "6_road_target.jpg"]
SCALE_WORDS = ["AI slop", "cheap indie", "good indie", "AA", "AAA-feeling"]
TELLS = ["Flat light", "No atmosphere", "Too clean", "Too straight", "Floating objects", "Repetition",
         "Empty", "Scale tells", "Edges of the world", "Stiff people"]
FILM_COLS, FILM_W = 4, 480

CHEAP_PROMPT = """You are a player looking at screenshots of a video game for the first time. You
have NOT seen the game's code, its history, its plans or anyone's reasoning, and you must not read
any of it: open only the files named here, do not list folders and do not search the repository.
Judge with your eyes.

The question: **does this look like a cheap indie or AI-made game, and why?** Be honest and
specific; flattery is useless here, and so is harshness for its own sake.

Read the rubric first (its ten tells, the verdict scale and what each answer needs): {rubric}

The game is meant to look like a painted illustration with a bit of square to the paint: that style
is not itself a tell. Judge whether it looks made with care.

The pictures to judge (each on its own; judge each against the rubric, not against each other):
{images}

For the verdict's top end only ("AA" and "AAA-feeling"), these concept targets show what the game
is aiming at; do not judge the pictures by how closely they match them:
{targets}

For every FAIL, cut its box to look closely and to cite as evidence (x y w h in the picture's own
pixels; it prints the path; look at it):

  cd {root} && python3 tools/critic.py cut {out} NAME X Y W H slug

Then write {md} in this form, nothing before it:

# Cheap judge, {name}

## a
- 1 Flat light: PASS|FAIL|N/A (`x y w h` or the region; `cut file` for a FAIL)
- 2 No atmosphere: ...
- 3 Too clean: ...
- 4 Too straight: ...
- 5 Floating objects: ...
- 6 Repetition: ...
- 7 Empty: ...
- 8 Scale tells: ...
- 9 Edges of the world: ...
- 10 Stiff people: ...
- **Verdict: AI slop|cheap indie|good indie|AA|AAA-feeling**
1. **<reason>** (tell N, `x y w h`): <what a player sees>. Cause: light|material|geometry|dressing|people|camera. Cheapest fix: <one thing>.
2. ...
5. ...

(one section per picture, in order; a still's "10 Stiff people" is N/A; a film strip's frames are
in time order left to right, top to bottom). Then, last, one ranking of all the pictures, judged
each on its own as above but now put in order (a verdict band holds several; this says which
looks more made with care within it):

## Ranking
From least to most cheap-looking: <letters, comma separated, e.g. c, a, d, b>

Write it with the Write tool. Do not edit anything else."""


def _lab(img):
    import numpy as np
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import judge as jd
    return jd, np, jd.to_lab(np.asarray(img.convert("RGB")))


def cheap_numbers(img, depth=None):
    """The measures beside the eye (CHEAP.md "The numbers"): light, atmosphere, repetition."""
    jd, np, lab = _lab(img)
    from scipy.ndimage import gaussian_filter
    L = lab[..., 0]
    h, w = L.shape
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    p1, p5, p50, p95 = np.percentile(L, [1, 5, 50, 95])
    out = {"shadow": float((L < 10.0).mean()), "spread": float(p95 - p5), "floor": float(p1),
           "L5": float(p5), "L50": float(p50), "L95": float(p95)}
    # Atmosphere: local contrast (L*'s std in ~6 px) and chroma, far over near.
    m = gaussian_filter(L, 6.0)
    local = np.sqrt(np.maximum(gaussian_filter(L * L, 6.0) - m * m, 0.0))
    if depth is not None:
        d = np.asarray(depth.convert("L").resize((w, h)), dtype=np.float64) / 255.0
        near, far = d < np.percentile(d, 33), (d > np.percentile(d, 67)) & (d < 0.999)
        out["depth"] = "depth image"
    else:
        rows = np.arange(h)[:, None] * np.ones((1, w))
        near, far = rows >= h * 2 // 3, (rows >= h * 0.38) & (rows < h * 0.55)
        out["depth"] = "frame bands"
    out["contrast_far_near"] = float(local[far].mean() / max(local[near].mean(), 1e-6))
    out["chroma_far_near"] = float(chroma[far].mean() / max(chroma[near].mean(), 1e-6))
    # Repetition: the strongest repeat of the high-passed luminance away from its own centre,
    # over the whole frame and its four quarters (a repeated tile on one wall shows in its quarter).
    def repeat(a):
        hp = a - gaussian_filter(a, 8.0)
        hp = hp - hp.mean()
        if hp.std() < 1e-4:
            return 0.0
        f = np.fft.rfft2(hp, s=(a.shape[0] * 2, a.shape[1] * 2))
        ac = np.fft.irfft2(f * np.conj(f), s=(a.shape[0] * 2, a.shape[1] * 2))
        ac = np.fft.fftshift(ac / ac[0, 0])
        cy, cx = ac.shape[0] // 2, ac.shape[1] // 2
        ry, rx = a.shape[0] // 3, a.shape[1] // 3
        win = ac[cy - ry:cy + ry + 1, cx - rx:cx + rx + 1]
        yy, xx = np.mgrid[-ry:ry + 1, -rx:rx + 1]
        win = np.where(np.hypot(yy, xx) < 16.0, -1.0, win)
        # Count only lags with real overlap (the autocorrelation's edge is a few pixels' worth).
        return float(win.max())
    lum = L / 100.0
    parts = [lum] + [lum[y0:y0 + h // 2, x0:x0 + w // 2] for y0 in (0, h // 2) for x0 in (0, w // 2)]
    reps = [repeat(p) for p in parts]
    out["repeat"] = reps[0]
    out["repeat_quarter"] = max(reps[1:])
    return out


def _numbers_md(rows):
    lines = ["# The cheap judge's numbers (not shown to the judge)", "",
             "Light: deep shadow (L* < 10), the L* spread (95th - 5th), the black floor (1st percentile: high is "
             "lifted). Atmosphere: local contrast and chroma far / near (1 = no falloff). Repetition: the strongest "
             "repeat of the high-passed luminance away from its centre, the frame and its worst quarter.", "",
             "| picture | source | deep shadow | L* spread | black floor | contrast far/near | chroma far/near | "
             "repeat / quarter | near-far by |", "|---|---|---|---|---|---|---|---|---|"]
    for name, src, n in rows:
        if n is None:
            lines.append("| %s | %s | (film strip) | | | | | | |" % (name, src))
            continue
        lines.append("| %s | %s | %.1f%% | %.0f | %.1f | %.2f | %.2f | %.2f / %.2f | %s |" % (
            name, src, n["shadow"] * 100, n["spread"], n["floor"], n["contrast_far_near"], n["chroma_far_near"],
            n["repeat"], n["repeat_quarter"], n["depth"]))
    return "\n".join(lines) + "\n"


def film_strip(frames_dir):
    names = sorted(f for f in os.listdir(frames_dir) if f.lower().endswith((".png", ".jpg")))
    if not names:
        print("no frames in %s" % frames_dir, file=sys.stderr)
        sys.exit(1)
    if len(names) > 8:
        step = len(names) / 8.0
        names = [names[int(i * step)] for i in range(8)]
    ims = [Image.open(os.path.join(frames_dir, n)).convert("RGB") for n in names]
    fh = int(FILM_W * ims[0].height / ims[0].width)
    rows = (len(ims) + FILM_COLS - 1) // FILM_COLS
    out = Image.new("RGB", (FILM_COLS * FILM_W + (FILM_COLS - 1) * 4, rows * fh + (rows - 1) * 4), (10, 10, 10))
    for i, im in enumerate(ims):
        out.paste(im.resize((FILM_W, fh), Image.LANCZOS), ((i % FILM_COLS) * (FILM_W + 4), (i // FILM_COLS) * (fh + 4)))
    return out


def cheap(out, views, src_dir=None, film=None, name=None):
    """Lay the pictures out under letters, measure them, print the prompt."""
    out = os.path.abspath(out)
    os.makedirs(out, exist_ok=True)
    listed, sources, rows = [], [], []
    for i, view in enumerate(views):
        letter = chr(ord("a") + i)
        path = view if view.endswith(".png") or view.endswith(".jpg") else os.path.join(src_dir or ".", view + ".png")
        if not os.path.exists(path):
            print("no picture %s" % path, file=sys.stderr)
            sys.exit(1)
        img = Image.open(path).convert("RGB")
        img.save(os.path.join(out, letter + ".png"))
        depth_path = os.path.splitext(path)[0] + "_depth.png"
        depth = Image.open(depth_path) if os.path.exists(depth_path) else None
        label = os.path.splitext(os.path.basename(path))[0]
        listed.append("- %s: %s (a still, %dx%d)" % (letter, os.path.join(out, letter + ".png"), img.width, img.height))
        sources.append("%s %s %s" % (letter, label, os.path.relpath(path, ROOT) if path.startswith(ROOT) else path))
        rows.append((letter, label, cheap_numbers(img, depth)))
    if film:
        letter = chr(ord("a") + len(views))
        strip = film_strip(film)
        strip.save(os.path.join(out, letter + ".png"))
        listed.append("- %s: %s (a film strip: %s frames of the game moving, in time order)" % (
            letter, os.path.join(out, letter + ".png"), "eight" if len(os.listdir(film)) >= 8 else "its"))
        sources.append("%s film %s" % (letter, film))
        rows.append((letter, "film", None))
    targets = ["- %s" % os.path.join(TARGETS_DIR, f) for f in CHEAP_TARGETS]
    with open(os.path.join(out, "sources.txt"), "w") as f:
        f.write("\n".join(sources) + "\n")
    numbers = {r[0]: {"source": r[1], "numbers": r[2]} for r in rows}
    with open(os.path.join(out, "numbers.json"), "w") as f:
        json.dump(numbers, f, indent=1)
    with open(os.path.join(out, "numbers.md"), "w") as f:
        f.write(_numbers_md(rows))
    print(CHEAP_PROMPT.format(rubric=CHEAP_RUBRIC, images="\n".join(listed), targets="\n".join(targets), root=ROOT,
                              out=os.path.relpath(out, ROOT), md=os.path.join(out, "cheap.md"),
                              name=name or os.path.basename(out)))


def read_cheap(out):
    """OUT/cheap.md as {letter: {"verdict": i on SCALE_WORDS, "fails": [tell numbers], "tells": {n: word},
    "reasons": [lines]}}."""
    sections, cur = {}, None
    with open(os.path.join(out, "cheap.md")) as f:
        for line in f:
            m = re.match(r"^\s*From least to most cheap-looking:\s*(.+)$", line)
            if m:
                order = [x for x in re.findall(r"\b([a-z])\b", m.group(1).lower())]
                for i, letter in enumerate(order):
                    sections.setdefault(letter, {"verdict": None, "fails": [], "tells": {}, "reasons": []})["rank"] = i
                cur = None
                continue
            m = re.match(r"^##\s+([a-z])\b", line)
            if m:
                cur = sections.setdefault(m.group(1), {"verdict": None, "fails": [], "tells": {}, "reasons": []})
                continue
            if cur is None:
                continue
            m = re.match(r"^-\s*(\d+)\s+[^:]+:\s*\**(PASS|FAIL|N/A)", line)
            if m:
                cur["tells"][int(m.group(1))] = m.group(2)
                if m.group(2) == "FAIL":
                    cur["fails"].append(int(m.group(1)))
                continue
            m = re.search(r"Verdict:\s*\**\s*([A-Za-z -]+?)\s*\**\s*$", line)
            if m:
                word = m.group(1).strip().lower()
                for i, w in enumerate(SCALE_WORDS):
                    if word == w.lower():
                        cur["verdict"] = i
                continue
            if re.match(r"^\d\. ", line):
                cur["reasons"].append(line.strip())
    return sections


def _sources(out):
    src = {}
    with open(os.path.join(out, "sources.txt")) as f:
        for line in f:
            parts = line.split()
            if len(parts) >= 2:
                src[parts[0]] = parts[1]
    return src


def cheap_score(sec):
    """One number to rank by: the verdict band first, then the judge's own ranking within it (its
    "## Ranking", least cheap first), then fewer FAILs."""
    rank = sec.get("rank", 50)
    return (sec["verdict"] if sec["verdict"] is not None else -1) * 10000 - rank * 100 - len(sec["fails"])


def cheap_log(out, round_name=None, note=""):
    out = os.path.abspath(out)
    secs = read_cheap(out)
    src = _sources(out)
    nums = json.load(open(os.path.join(out, "numbers.json")))
    round_name = round_name or os.path.basename(os.path.normpath(out))
    hist = os.path.join(ROOT, "docs", "screenshots", "judge", "history.md")
    have = open(hist).read() if os.path.exists(hist) else ""
    lines = []
    if "## The cheap judge" not in have:
        lines.append("\n## The cheap judge (from 2026-11-03): does it look cheap? (tools/critic.py cheap, "
                     "docs/concept/judge/CHEAP.md)\n\nVerdict on AI slop / cheap indie / good indie / AA / "
                     "AAA-feeling; the tells it failed (CHEAP.md's numbers); its biggest reason; the numbers "
                     "beside it (deep shadow, black floor, contrast far/near, repeat).\n\n"
                     "| round | view | verdict | tells failed | biggest reason | shadow / floor / far-near / repeat | note |\n"
                     "|---|---|---|---|---|---|---|")
    for letter in sorted(secs):
        sec = secs[letter]
        verdict = SCALE_WORDS[sec["verdict"]] if sec["verdict"] is not None else "?"
        reason = re.sub(r"\s*\(tell.*", "", sec["reasons"][0]).strip("0123456789. *") if sec["reasons"] else ""
        n = nums.get(letter, {}).get("numbers")
        meas = ("%.0f%% / %.1f / %.2f / %.2f" % (n["shadow"] * 100, n["floor"], n["contrast_far_near"], n["repeat"])
                if n else "(film)")
        view = src.get(letter, letter)
        print("%-24s %-12s fails %-20s %s" % (view, verdict, ",".join(map(str, sec["fails"])) or "-", meas))
        lines.append("| %s | %s | **%s** | %s | %s | %s | %s |" % (round_name, view, verdict,
                     ", ".join(str(t) for t in sec["fails"]) or "none", reason.replace("|", "/"), meas, note))
    with open(hist, "a") as f:
        f.write("\n".join(lines) + "\n")


def _probe_set():
    with open(os.path.join(CHEAP_PROBES, "ranking.json")) as f:
        return json.load(f)


def cheap_probes(out):
    """The self-test's layout: the probes in a fixed shuffled order (no order gives the ranking away)."""
    import random
    probes = _probe_set()["probes"]
    order = [p["file"] for p in probes if p.get("eye", True)]
    random.Random(609).shuffle(order)
    cheap(out, [os.path.join(CHEAP_PROBES, f) for f in order], name=os.path.basename(os.path.abspath(out)))


def cheap_probes_check(out):
    """The agent's cheap.md against Sean's ranking: every rule in ranking.json must hold."""
    out = os.path.abspath(out)
    secs = read_cheap(out)
    by_file = {}
    for letter, path in _sources(out).items():
        if letter in secs:
            by_file[os.path.splitext(os.path.basename(path))[0]] = secs[letter]
    ok = True
    for name, sec in sorted(by_file.items(), key=lambda kv: -cheap_score(kv[1])):
        print("  %-14s %-12s rank %-3s fails %s" % (name, SCALE_WORDS[sec["verdict"]] if sec["verdict"] is not None else "?",
              sec.get("rank", "-"), ",".join(map(str, sec["fails"])) or "-"))
    for rule in _probe_set()["rules"]:
        if rule["kind"] == "above":
            a, b = by_file.get(rule["better"]), by_file.get(rule["worse"])
            held = a is not None and b is not None and cheap_score(a) > cheap_score(b)
        elif rule["kind"] == "fails_any":
            sec = by_file.get(rule["probe"])
            held = sec is not None and any(t in sec["fails"] for t in rule["tells"])
        else:
            held = False
        # A rule with "gate": false is reported, not failed on (ranking.json says why).
        gate = rule.get("gate", True)
        print("  %s %s" % ("ok  " if held else ("FAIL" if gate else "warn"), rule["words"]))
        ok = ok and (held or not gate)
    return ok


def cheap_probes_numbers():
    """The measures alone on the probes (no agent): the broken probe flatter and airless."""
    probes = _probe_set()
    got = {}
    for p in probes["probes"]:
        name = os.path.splitext(p["file"])[0]
        got[name] = cheap_numbers(Image.open(os.path.join(CHEAP_PROBES, p["file"])))
        n = got[name]
        print("  %-14s shadow %4.1f%%  spread %3.0f  floor %4.1f  contrast far/near %.2f  chroma far/near %.2f  "
              "repeat %.2f/%.2f" % (name, n["shadow"] * 100, n["spread"], n["floor"], n["contrast_far_near"],
                                    n["chroma_far_near"], n["repeat"], n["repeat_quarter"]))
    ok = True
    for rule in probes["number_rules"]:
        a, b = got[rule["a"]][rule["measure"]], got[rule["b"]][rule["measure"]]
        held = a < b if rule["op"] == "<" else a > b
        print("  %s %s (%.3f %s %.3f)" % ("ok  " if held else "FAIL", rule["words"], a, rule["op"], b))
        ok = ok and held
    return ok


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
    j = sub.add_parser("judge")
    j.add_argument("out")
    j.add_argument("images", nargs="+")
    k = sub.add_parser("cut")
    k.add_argument("out")
    k.add_argument("name")
    for v in ("x", "y", "w", "h"):
        k.add_argument(v, type=int)
    k.add_argument("slug")
    ch = sub.add_parser("cheap")
    ch.add_argument("out")
    ch.add_argument("views", nargs="+")
    ch.add_argument("--from", dest="src", default=None)
    ch.add_argument("--film", default=None)
    cl = sub.add_parser("cheap-log")
    cl.add_argument("out")
    cl.add_argument("--round", default=None)
    cl.add_argument("--note", default="")
    cp = sub.add_parser("cheap-probes")
    cp.add_argument("out", nargs="?", default=None)
    cp.add_argument("--check", action="store_true")
    cp.add_argument("--numbers", action="store_true")
    args = ap.parse_args()
    if args.cmd == "cheap":
        cheap(args.out, args.views, args.src, args.film)
    elif args.cmd == "cheap-log":
        cheap_log(args.out, args.round, args.note)
    elif args.cmd == "cheap-probes":
        if args.numbers:
            sys.exit(0 if cheap_probes_numbers() else 1)
        if not args.out:
            ap.error("cheap-probes needs OUT (or --numbers)")
        if args.check:
            sys.exit(0 if cheap_probes_check(args.out) else 1)
        cheap_probes(args.out)
    elif args.cmd == "judge":
        judge(args.out, args.images)
    elif args.cmd == "cut":
        cut(args.out, args.name, args.x, args.y, args.w, args.h, args.slug)
    elif args.cmd == "prepare":
        prepare(args.round, args.extra)
    elif args.cmd == "crop":
        crop(args.round, args.view, args.x, args.y, args.w, args.h, args.slug)
    else:
        top(args.round)


if __name__ == "__main__":
    main()
