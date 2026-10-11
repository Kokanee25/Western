#!/usr/bin/env python3
"""The character judge: the seated man alone against the painting's man, by style, not likeness.

    python3 tools/characters/judge_man.py --from=DIR [--note="what changed"] [--name=TAG] [--dry]
        [--painting=blocks|night]
    python3 tools/characters/judge_man.py --probes     (the self-test; exits 1 if it ranks wrongly)

The reference judge (tools/judge.py, the art session's) scores the whole frame, so a change to
the man barely moves it: the room is most of the picture (Sean, 2026-10-06: "Can we get the
judge to just focus on the character"). This one measures only him. DIR holds a render of the
saloon shot and his outline from the same camera:

    xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd -- \\
        --out=DIR --only=shot_match_saloon --model=stranger2s --fresh --no-mosaic --man-mask

(shot_match_saloon.png and shot_match_saloon_man.png). The painting is DESIGN.md §4's saloon
target, docs/concept/saloon-blocks.png (the saloon painting redrawn in the bold style: the same
man, pose and framing, lit brighter and more evenly, in bolder squares); --painting=night judges
against the old saloon-night.png, the room's mood. Rounds up to 2026-10-06_r4 were judged against
saloon-night.png, so their scores don't compare. The painting's man is its hand-traced outline
(tools/paint/align.py SHOT_OUTLINE: the man is the same in both). The cup in his hand is left out
of both (CUP).

He needn't look like the painting's man, only be drawn in its style (Sean, the same day), so
what's scored is how he's drawn and lit, never where his features are. Inside each outline, at
1280x720 (CIE L*a*b*), with judge.py's measures and scales where they're the same thing:
  light     L* at the 5th, 50th and 95th percentiles; the shares of deep shadow (L* < 10) and of
            blown highlight (L* > 80).
  colour    mean chroma, mean b* (warmth), and the chroma-L* correlation.
  squares   their size (twice the half-width of the masked autocorrelation of the high-passed
            lightness, judge.tile_size's measure with the outside left out); how much each square
            differs from the eight round it (RMS L*, on a grid of the painting's square, SQUARE
            px); and how flat they are (the share of neighbouring pixels within FLAT L* of each
            other: a square is one tone, a smooth face is all slopes).
  edges     hardness, the share of all variation at the 1 px scale (judge.py's).
  paint     coherence and grain, one-sided as judge.py's (noise can't buy a better score).
  palette   12 colours in each man by k-means; the painting's colours we lack and ours it lacks.
  regions   his face, hat and coat (boxes round the painting's man, REGIONS; ours sit on the same
            pixels within a few px, as tools/fit_shot.gd fits his eyes onto its eyes): each one's
            median and bright L*, chroma and square size, so a change to his face shows as his face.
One score: the mean severity of the differences, as judge.py's (lower is closer). Each round goes
in docs/screenshots/tripo/judge/<date>_r<n>/ (man.png: the two men side by side, outside their
outlines dimmed; report.md, report.json) and a line in docs/screenshots/tripo/judge/history.md.
--dry prints the round without writing it.
"""
import ast
import datetime
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy.cluster.vq import kmeans2
from scipy.ndimage import binary_erosion, gaussian_filter, uniform_filter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import judge  # noqa: E402  (the reference judge's colour space and measures, shared not copied)

# The painting he's judged against (--painting=): DESIGN.md §4's saloon target since 2026-10-05,
# and the old night painting.
PAINTINGS = {"blocks": "saloon-blocks.png", "night": "saloon-night.png"}
PAINTING = os.path.join(ROOT, "docs", "concept", PAINTINGS["blocks"])
OUT_DIR = os.path.join(ROOT, "docs", "screenshots", "tripo", "judge")
RENDER = "shot_match_saloon.png"
MASK = "shot_match_saloon_man.png"
W, H = judge.W, judge.H
# The painting's frame (its own pixels: the outline, the boxes and the cup are in them).
PW, PH = 1672, 941
# The cup in his hand, left out of both men (tools/fit_shot.gd puts ours on the painting's).
CUP = (703, 603, 853, 773)
# His face, hat and coat, round the painting's man (its eyes at (614, 360) and (685, 386)).
REGIONS = {"face": (540, 330, 745, 520), "hat": (430, 190, 845, 335), "coat": (210, 520, 900, 941)}
# The painting's square on its man (~9 px at 1672: ~7 at 1280), and how near two neighbouring
# pixels' lightness is to count as one tone.
SQUARE = 9.0
FLAT = 1.0
LIT = 12.0
PALETTE = 12


def outline_mask() -> np.ndarray:
    """The painting's man (SHOT_OUTLINE, read from tools/paint/align.py's source, not imported:
    that module wants MediaPipe) at W x H, without the cup."""
    src = open(os.path.join(ROOT, "tools", "paint", "align.py")).read()
    for node in ast.parse(src).body:
        if isinstance(node, ast.Assign) and any(getattr(t, "id", "") == "SHOT_OUTLINE" for t in node.targets):
            pts = ast.literal_eval(node.value)
            break
    img = Image.new("L", (W, H), 0)
    ImageDraw.Draw(img).polygon([(x * W / PW, y * H / PH) for x, y in pts], fill=255)
    return np.asarray(img) > 127


def _box(b: tuple) -> tuple:
    return (int(b[0] * W / PW), int(b[1] * H / PH), int(b[2] * W / PW), int(b[3] * H / PH))


def _without_cup(mask: np.ndarray) -> np.ndarray:
    x0, y0, x1, y1 = _box(CUP)
    out = mask.copy()
    out[y0:y1, x0:x1] = False
    return out


def masked_tile_size(L: np.ndarray, mask: np.ndarray) -> float:
    """Twice the half-width of the autocorrelation of the high-passed lightness inside `mask`
    (the outside weighs nothing: each lag's correlation is over the pixels both ends of it are
    in), across and down, averaged."""
    ys, xs = np.nonzero(mask)
    if len(ys) < 400:
        return float("nan")
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    lum = L[y0:y1, x0:x1] / 100.0
    m = mask[y0:y1, x0:x1].astype(np.float64)
    hp = (lum - gaussian_filter(lum, 10.0, mode="reflect")) * m
    hp -= m * (hp.sum() / max(m.sum(), 1.0))
    s = (lum.shape[0] * 2, lum.shape[1] * 2)
    f = np.fft.fft2(hp, s=s)
    fm = np.fft.fft2(m, s=s)
    ac = np.real(np.fft.ifft2(f * np.conj(f)))
    n = np.real(np.fft.ifft2(fm * np.conj(fm)))
    ac = np.where(n > 50, ac / np.maximum(n, 1.0), 0.0)
    ac /= max(ac[0, 0], 1e-12)

    def half(v: np.ndarray) -> float:
        for i in range(1, len(v)):
            if v[i] < 0.5:
                return i - 1 + (v[i - 1] - 0.5) / (v[i - 1] - v[i])
        return float(len(v))

    return float(np.mean([2.0 * half(ac[0, :48]), 2.0 * half(ac[:48, 0])]))


def squares_contrast(L: np.ndarray, mask: np.ndarray, size: float) -> float:
    """RMS of each square's mean L* less its eight neighbours' mean, on a grid of `size` px,
    squares at least 80 % inside `mask`."""
    k = max(int(round(size)), 2)
    h, w = (L.shape[0] // k) * k, (L.shape[1] // k) * k
    lm = (L * mask)[:h, :w].reshape(h // k, k, w // k, k).sum(axis=(1, 3))
    cnt = mask[:h, :w].reshape(h // k, k, w // k, k).sum(axis=(1, 3)).astype(np.float64)
    ok = cnt >= 0.8 * k * k
    mean = np.where(ok, lm / np.maximum(cnt, 1.0), 0.0)
    tot = np.zeros_like(mean)
    num = np.zeros_like(mean)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dy or dx:
                tot += np.roll(np.roll(mean * ok, dy, 0), dx, 1)
                num += np.roll(np.roll(ok.astype(np.float64), dy, 0), dx, 1)
    use = ok & (num >= 4)
    if use.sum() < 10:
        return float("nan")
    d = mean[use] - tot[use] / num[use]
    return float(np.sqrt((d ** 2).mean()))


def flatness(L: np.ndarray, mask: np.ndarray) -> float:
    """The share of neighbouring pixel pairs inside `mask` whose lightness is within FLAT, of
    those both lit past LIT (in the dark every pair is within FLAT of the next, square or not:
    a man mostly in shadow read as flatter than the painting's)."""
    lit = mask & (L >= LIT)
    dx = np.abs(np.diff(L, axis=1)) < FLAT
    dy = np.abs(np.diff(L, axis=0)) < FLAT
    mx = lit[:, 1:] & lit[:, :-1]
    my = lit[1:, :] & lit[:-1, :]
    if mx.sum() + my.sum() < 200:
        return float("nan")
    return float((dx[mx].sum() + dy[my].sum()) / (mx.sum() + my.sum()))


def palette(lab: np.ndarray, mask: np.ndarray) -> tuple:
    flat = lab[mask]
    rng = np.random.default_rng(1882)
    sample = flat[rng.choice(len(flat), min(20000, len(flat)), replace=False)]
    centres, _ = kmeans2(sample, PALETTE, minit="++", seed=1882, iter=25)
    return centres, sample


def measure(img: Image.Image, mask: np.ndarray) -> dict:
    """Everything about one man (img at W x H, mask his pixels)."""
    lab = judge.to_lab(np.asarray(img.convert("RGB")))
    L = lab[..., 0]
    C = np.hypot(lab[..., 1], lab[..., 2])
    inner = binary_erosion(mask, iterations=2)
    blurred = np.stack([gaussian_filter(lab[..., c], 3.0, mode="reflect") for c in range(3)], -1)
    detail = np.linalg.norm(lab - blurred, axis=-1)
    b1 = gaussian_filter(L, 1.0, mode="reflect")
    b3 = gaussian_filter(L, 3.0, mode="reflect")
    b12 = gaussian_filter(L, 12.0, mode="reflect")
    hp = np.abs(L - b3)
    mp = np.abs(b3 - b12)
    quiet = inner & (mp < np.percentile(mp[inner], 25))
    v = L[mask]
    p = np.percentile(v, [5, 50, 95])
    out = {
        "L5": float(p[0]), "L50": float(p[1]), "L95": float(p[2]),
        "shadow": float((v < 10.0).mean()), "highlight": float((v > 80.0).mean()),
        "chroma": float(C[mask].mean()), "b": float(lab[..., 2][mask].mean()),
        "corr": float(np.corrcoef(v, C[mask])[0, 1]),
        "coherence": float(np.corrcoef(hp[inner], mp[inner])[0, 1]),
        "grain": float(detail[quiet].mean()),
        "hardness": float(np.abs(L - b1)[inner].mean() / max(detail[inner].mean(), 1e-6)),
        "tile": masked_tile_size(L, inner),
        "squares": squares_contrast(L, mask, SQUARE * W / PW),
        "flat": flatness(L, inner),
        "pixels": int(mask.sum()),
    }
    out["palette"], out["sample"] = palette(lab, mask)
    out["regions"] = {}
    for name, b in REGIONS.items():
        x0, y0, x1, y1 = _box(b)
        rm = np.zeros_like(mask)
        rm[y0:y1, x0:x1] = mask[y0:y1, x0:x1]
        if rm.sum() < 300:
            continue
        rv = L[rm]
        out["regions"][name] = {
            "L50": float(np.median(rv)), "L90": float(np.percentile(rv, 90)),
            "chroma": float(C[rm].mean()), "b": float(lab[..., 2][rm].mean()),
            "tile": masked_tile_size(L, binary_erosion(rm, iterations=2)),
            "squares": squares_contrast(L, rm, SQUARE * W / PW),
            "flat": flatness(L, binary_erosion(rm, iterations=2)),
        }
    return out


def differences(o: dict, p: dict) -> list:
    """Every scored difference, (severity, words, group), worst first. Scales as judge.py's where
    the measure is the same; squares' contrast 3 L*, flat share 0.1, a region's L* 10 and chroma 8.
    Groups: light (how the scene's lamps light him: the art session's), colour (his paint's colours
    as lit) and squares (how he's drawn: size, flatness, edges, grain: the characters session's)."""
    out = []

    group = ["light"]

    def add(sev: float, words: str) -> None:
        if np.isfinite(sev):
            out.append((round(max(float(sev), 0.0), 2), words, group[0]))

    def cmp(key: str, scale: float, more: str, less: str, fmt: str = "%.0f", a: dict = o, b: dict = p,
            where: str = "") -> None:
        d = a[key] - b[key]
        add(abs(d) / scale, "%s%s (%s vs %s)" % (where, more if d > 0 else less, fmt % a[key], fmt % b[key]))

    cmp("L50", 10.0, "midtones too bright", "midtones too dark")
    cmp("L5", 10.0, "shadows too light", "shadows too deep")
    cmp("L95", 10.0, "bright parts too bright", "bright parts too dim")
    cmp("shadow", 0.10, "too much deep shadow", "too little deep shadow (share under L* 10)", "%.2f")
    cmp("highlight", 0.03, "too much blown highlight (share over L* 80)", "too little blown highlight", "%.3f")
    for name in REGIONS:
        a, b = o["regions"].get(name), p["regions"].get(name)
        if a is not None and b is not None:
            cmp("L50", 10.0, "too bright", "too dark", a=a, b=b, where="%s: " % name)
            cmp("L90", 10.0, "lit parts too bright", "lit parts too dim", a=a, b=b, where="%s: " % name)
    group[0] = "colour"
    cmp("chroma", 8.0, "colour too strong", "colour too weak (chroma)")
    cmp("b", 8.0, "too yellow", "too blue/grey (b*)")
    cmp("corr", 0.20, "bright parts too colourful", "bright parts too pale (chroma-L* correlation)", "%.2f")
    add(o["missing"] / 6.0, "palette: the painting's colours we lack (%.1f dE)" % o["missing"])
    add(o["extra"] / 6.0, "palette: colours the painting lacks (%.1f dE)" % o["extra"])
    for name in REGIONS:
        a, b = o["regions"].get(name), p["regions"].get(name)
        if a is not None and b is not None:
            cmp("chroma", 8.0, "colour too strong", "colour too weak", a=a, b=b, where="%s: " % name)
    group[0] = "squares"
    add((p["coherence"] - o["coherence"]) / 0.08, "noisier than paint (coherence %.2f vs %.2f)" % (o["coherence"], p["coherence"]))
    add((o["grain"] - p["grain"]) / 1.5, "grain in his flat parts (%.1f vs %.1f dE)" % (o["grain"], p["grain"]))
    cmp("hardness", 0.10, "edges too hard", "edges too soft", "%.2f")
    if o["tile"] > 0 and p["tile"] > 0:
        add(abs(np.log(o["tile"] / p["tile"])) / np.log(1.5), "squares %s than the painting's (%.1f vs %.1f px)" % (
            "bigger" if o["tile"] > p["tile"] else "smaller", o["tile"], p["tile"]))
    cmp("squares", 3.0, "squares too different from their neighbours", "squares too alike (a smooth surface)", "%.1f")
    cmp("flat", 0.10, "squares flatter than the painting's (one tone, edge to edge)",
        "squares not flat (light runs across them)", "%.2f")
    for name in REGIONS:
        a, b = o["regions"].get(name), p["regions"].get(name)
        if a is None or b is None:
            continue
        if a["tile"] > 0 and b["tile"] > 0:
            add(abs(np.log(a["tile"] / b["tile"])) / np.log(1.5), "%s: squares %s (%.1f vs %.1f px)" % (
                name, "bigger" if a["tile"] > b["tile"] else "smaller", a["tile"], b["tile"]))
    out.sort(key=lambda t: -t[0])
    return out


def judge_pair(ours: dict, theirs: dict) -> tuple:
    ours["missing"] = judge.palette_gap(theirs["sample"], ours["palette"], theirs["palette"])
    ours["extra"] = judge.palette_gap(ours["sample"], theirs["palette"], ours["palette"])
    diffs = differences(ours, theirs)
    return judge.score(diffs), diffs


def by_group(diffs: list) -> dict:
    """Each group's own score (the mean severity of its differences)."""
    return {g: round(float(np.mean([d[0] for d in diffs if d[2] == g])), 3)
            for g in ("light", "colour", "squares") if any(d[2] == g for d in diffs)}


def painting() -> tuple:
    img = judge.load(PAINTING)
    mask = _without_cup(outline_mask())
    return img, mask


def load_render(d: str) -> tuple:
    img = judge.load(os.path.join(d, RENDER))
    m = Image.open(os.path.join(d, MASK)).convert("L").resize((W, H), Image.NEAREST)
    return img, _without_cup(np.asarray(m) > 127)


def picture(p_img: Image.Image, p_mask: np.ndarray, o_img: Image.Image, o_mask: np.ndarray,
            score: float, diffs: list) -> Image.Image:
    """The two men side by side (outside their outlines dimmed), at 2x, and the top differences."""
    x0, y0, x1, y1 = _box((200, 180, 900, 941))

    def dim(img, mask):
        a = np.asarray(img).astype(np.float64)
        a[~mask] *= 0.25
        return Image.fromarray(a.astype(np.uint8)).crop((x0, y0, x1, y1))

    a, b = dim(p_img, p_mask), dim(o_img, o_mask)
    w, h = a.width * 2, a.height * 2
    sheet = Image.new("RGB", (w * 2 + 10, h + 60 + 22 * 6), (22, 22, 22))
    sheet.paste(a.resize((w, h), Image.NEAREST), (0, 40))
    sheet.paste(b.resize((w, h), Image.NEAREST), (w + 10, 40))
    d = ImageDraw.Draw(sheet)
    d.text((8, 10), "the painting's man", fill=(240, 230, 210), font=judge._font(20))
    groups = by_group(diffs)
    d.text((w + 18, 10), "ours: %.3f  (%s; lower is closer)" % (score, ", ".join("%s %.2f" % g for g in groups.items())),
           fill=(240, 230, 210), font=judge._font(20))
    for i, (sev, words, group) in enumerate(diffs[:6]):
        d.text((8, h + 48 + 22 * i), "%.2f  %-7s %s" % (sev, group, words), fill=(220, 220, 220), font=judge._font(17, True))
    return sheet


def next_round() -> str:
    today = datetime.date.today().isoformat()
    os.makedirs(OUT_DIR, exist_ok=True)
    n = 1
    while os.path.exists(os.path.join(OUT_DIR, "%s_r%d" % (today, n))):
        n += 1
    return os.path.join(OUT_DIR, "%s_r%d" % (today, n))


def plain(m: dict) -> dict:
    return {k: v for k, v in m.items() if k not in ("palette", "sample")}


def run(src: str, note: str, name: str, dry: bool) -> float:
    p_img, p_mask = painting()
    o_img, o_mask = load_render(src)
    theirs = measure(p_img, p_mask)
    ours = measure(o_img, o_mask)
    score, diffs = judge_pair(ours, theirs)
    groups = by_group(diffs)
    print("%s: score %.3f (%s; lower is closer)" % (name or src, score, ", ".join("%s %.3f" % g for g in groups.items())))
    for sev, words, group in diffs[:8]:
        print("  %.2f  %-7s %s" % (sev, group, words))
    if dry:
        return score
    out = next_round()
    os.makedirs(out)
    picture(p_img, p_mask, o_img, o_mask, score, diffs).save(os.path.join(out, "man.png"))
    target = os.path.basename(PAINTING)
    report = {"round": os.path.basename(out), "from": os.path.relpath(src, ROOT) if src.startswith(ROOT) else src,
              "note": note, "against": target, "score": score, "groups": groups, "differences": diffs,
              "ours": plain(ours), "painting": plain(theirs)}
    json.dump(report, open(os.path.join(out, "report.json"), "w"), indent=1)
    lines = ["# Character judge, %s" % os.path.basename(out), "", note or "", "",
             "Score **%.3f** (the mean severity; lower is closer): %s. From `%s`, against the man in `%s`." % (
                 score, ", ".join("%s %.3f" % g for g in groups.items()), report["from"], target), "",
             "| Severity | Group | Difference |", "|---|---|---|"]
    lines += ["| %.2f | %s | %s |" % (sev, group, words) for sev, words, group in diffs]
    lines += ["", "![the two men](man.png)", ""]
    open(os.path.join(out, "report.md"), "w").write("\n".join(lines))
    hist = os.path.join(OUT_DIR, "history.md")
    if not os.path.exists(hist):
        open(hist, "w").write("# The character judge's rounds (tools/characters/judge_man.py)\n\n"
                              "| Round | Note | Score | Light | Colour | Squares | Biggest differences |\n"
                              "|---|---|---|---|---|---|---|\n")
    words = note or name or ""
    if target != PAINTINGS["blocks"]:
        words = "(against %s) %s" % (target, words)
    open(hist, "a").write("| %s | %s | %.3f | %s | %s | %s | %s |\n" % (
        os.path.basename(out), words, score,
        *["%.3f" % groups[g] if g in groups else "" for g in ("light", "colour", "squares")],
        "; ".join(w for _s, w, _g in diffs[:3])))
    print("wrote", os.path.relpath(out, ROOT))
    return score


def _blur(img: Image.Image) -> Image.Image:
    a = np.asarray(img).astype(np.float64)
    return Image.fromarray(np.clip(np.stack([gaussian_filter(a[..., c], 2.0) for c in range(3)], -1), 0, 255).astype(np.uint8))


def _smooth_squares(img: Image.Image) -> Image.Image:
    """The squares melted: each square's lightness left, its edges and flat tone gone (a 7 px box
    blur), the way a painted square lit smoothly reads."""
    a = np.asarray(img).astype(np.float64)
    return Image.fromarray(np.clip(np.stack([uniform_filter(a[..., c], 7) for c in range(3)], -1), 0, 255).astype(np.uint8))


def probes() -> bool:
    """The painting's man against himself scores 0 and shifted a little nearly 0; blurred, melted,
    noisy, grey or darkened he scores worse than shifted."""
    p_img, p_mask = painting()
    theirs = measure(p_img, p_mask)

    def score_of(img, mask=p_mask):
        s, _d = judge_pair(measure(img, mask), theirs)
        return s

    shifted = Image.fromarray(np.roll(np.asarray(p_img), (3, 3), axis=(0, 1)))
    rng = np.random.default_rng(7)
    a = np.asarray(p_img).astype(np.float64)
    blocks = np.kron(rng.normal(0, 14, (H // 6 + 1, W // 6 + 1)), np.ones((6, 6)))[:H, :W]
    noisy = Image.fromarray(np.clip(a + blocks[..., None], 0, 255).astype(np.uint8))
    grey = p_img.convert("L").convert("RGB")
    dark = Image.fromarray(np.clip(a * 0.6, 0, 255).astype(np.uint8))
    s = {"itself": score_of(p_img), "shifted 3 px": score_of(shifted, np.roll(p_mask, (3, 3), axis=(0, 1))),
         "blurred": score_of(_blur(p_img)), "squares melted": score_of(_smooth_squares(p_img)),
         "block noise": score_of(noisy), "greyscale": score_of(grey), "darkened": score_of(dark)}
    for k, v in s.items():
        print("  %-16s %.3f" % (k, v))
    ok = s["itself"] < 0.01 and s["shifted 3 px"] < 0.15
    for k in ("blurred", "squares melted", "block noise", "greyscale", "darkened"):
        ok &= s[k] > s["shifted 3 px"]
    print("probes", "pass" if ok else "FAIL")
    return ok


def main() -> None:
    global PAINTING
    args = sys.argv[1:]
    for a in args:
        if a.startswith("--painting="):
            if a[11:] not in PAINTINGS:
                print("--painting= takes", ", ".join(PAINTINGS))
                sys.exit(2)
            PAINTING = os.path.join(ROOT, "docs", "concept", PAINTINGS[a[11:]])
    if "--probes" in args:
        sys.exit(0 if probes() else 1)
    src, note, name = None, "", ""
    for a in args:
        if a.startswith("--from="):
            src = os.path.abspath(a[7:])
        elif a.startswith("--note="):
            note = a[7:]
        elif a.startswith("--name="):
            name = a[7:]
    if src is None:
        print(__doc__)
        sys.exit(2)
    run(src, note, name, "--dry" in args)


if __name__ == "__main__":
    main()
