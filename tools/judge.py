#!/usr/bin/env python3
"""The reference judge: render the two shot-match views, put each beside its painting, and measure
how they differ, so a round of art work can be judged by numbers as well as by eye.

    python3 tools/judge.py [--note="what changed"] [--only=saloon|street] [--from=DIR] [--godot=godot]
                           [--pick="Sean: B, the lamp's halo"]
    python3 tools/judge.py --probes          (the self-test: the probes of ART_REVIEW.md §5 must rank
                                              the way a viewer would; exits 1 if they don't)

Renders `shot_match_saloon` and `shot_match_street` (tools/screenshots.gd, Vulkan under xvfb) into
a new round folder, docs/screenshots/judge/<date>_r<n>/, and writes there for each view:
  <view>.png         the render (1280x720, untouched)
  <view>_judge.png   render | painting, the 3x3 grid with each region's numbers (information only),
                     both palettes, and the biggest differences in words
and report.json (every number) and report.md (the summary). docs/screenshots/judge/history.md
gets one line per view per round, so progress reads down the page. --from=DIR judges renders
already made (DIR/shot_match_saloon.png, DIR/shot_match_street.png) instead of rendering. --pick
records a human's verdict on the round (Sean's A/B), in the report and the history.

Version 2 (2026-10-02, after docs/ART_REVIEW.md §5): the score measures *style*, not composition.
Version 1 compared 3x3 region means of two differently composed pictures and rewarded any
square-to-square variation, so random block noise scored better than any real round and a grade
that moved the light toward the painting's scored worse. Now everything scored is a whole-frame
statistic, and the things noise can game are one-sided. What's measured (1280x720, CIE L*a*b*):
  light        L* at the 5th, 50th, 95th and 99th percentiles; the share of deep shadow (L* < 10)
               and of blown highlight (L* > 80). The paintings are dark pictures with a few bright
               things; ours were flat.
  colour       mean chroma, mean b* (warmth), and the chroma-L* correlation (in the paintings the
               brighter a thing is the more colourful it is: gold, not cream).
  coherence    whether fine detail sits where the mid-scale structure is (the correlation of |L - a
               3 px blur| with |3 px blur - 12 px blur|): paint's detail follows folds, boards and
               edges; random mosaic spreads it evenly and lowers this. Scored one-sided: only being
               *less* coherent than the painting counts (noise can't buy a better score).
  grain        fine variation in the flattest quarter of the frame (dE to a 3 px blur where the
               mid-scale structure is quietest): paint is calm there, noise isn't. One-sided too.
  hardness     the share of all variation that is at the 1 px scale (dE to a 1 px blur over dE to
               a 3 px blur): the painting's blocks have soft edges; hard pixel edges and blur both
               miss it. Symmetric.
  tiles        tile size (twice the autocorrelation half-width of the high-passed luminance) in a
               near band (the bottom third) and a far band (a strip round the middle). One-sided:
               near tiles smaller than the painting's count, far tiles bigger than the painting's
               count (distance should soften, never chunk).
  palette      16 colours by k-means in Lab; "missing" = how far (dE) the painting's pixels are
               from our nearest palette colour, "extra" = the same the other way round.
  detail       the old "mosaic" measure (dE to a 3 px blur) and the 3x3 region means are still
               reported, for reading, but no longer scored.
"""
import datetime
import json
import os
import subprocess
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.cluster.vq import kmeans2
from scipy.ndimage import gaussian_filter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JUDGE_DIR = os.path.join(ROOT, "docs", "screenshots", "judge")
VIEWS = {
    "saloon": ("shot_match_saloon", "docs/concept/saloon-night.png"),
    "street": ("shot_match_street", "docs/concept/street-golden-hour.png"),
}
W, H = 1280, 720
GRID = 3
REGION_NAMES = [["top-left", "top", "top-right"], ["left", "centre", "right"],
                ["bottom-left", "bottom", "bottom-right"]]
PALETTE = 16
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_MONO = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"


# --- colour ---------------------------------------------------------------------------------

def to_lab(rgb: np.ndarray) -> np.ndarray:
    a = rgb.astype(np.float64) / 255.0
    a = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = a @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116.0 * f[..., 1] - 16.0, 500.0 * (f[..., 0] - f[..., 1]),
                     200.0 * (f[..., 1] - f[..., 2])], -1)


def lab_to_rgb(lab: np.ndarray) -> np.ndarray:
    fy = (lab[..., 0] + 16.0) / 116.0
    fx = fy + lab[..., 1] / 500.0
    fz = fy - lab[..., 2] / 200.0
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f > 0.206893, f ** 3, (f - 16.0 / 116.0) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    a = np.clip(xyz @ m.T, 0.0, 1.0)
    a = np.where(a <= 0.0031308, 12.92 * a, 1.055 * a ** (1 / 2.4) - 0.055)
    return np.clip(a * 255.0 + 0.5, 0, 255).astype(np.uint8)


# --- measures -------------------------------------------------------------------------------

def tile_size(lum: np.ndarray) -> tuple:
    """Twice the autocorrelation half-width of the high-passed luminance, across and down."""
    hp = lum - gaussian_filter(lum, 10.0, mode="reflect")
    hp = hp - hp.mean()
    if hp.std() < 1e-4:
        return (float("nan"), float("nan"))
    f = np.fft.fft2(hp, s=(lum.shape[0] * 2, lum.shape[1] * 2))
    ac = np.real(np.fft.ifft2(f * np.conj(f)))
    ac /= ac[0, 0]

    def half(v: np.ndarray) -> float:
        for i in range(1, len(v)):
            if v[i] < 0.5:
                return i - 1 + (v[i - 1] - 0.5) / (v[i - 1] - v[i])
        return float(len(v))

    return (2.0 * half(ac[0, :48]), 2.0 * half(ac[:48, 0]))


def measure_region(lab: np.ndarray, detail_map: np.ndarray) -> dict:
    lum = lab[..., 0] / 100.0
    # Tile size means nothing on a flat region (a clear sky): noise sets it.
    th, tv = tile_size(lum) if detail_map.mean() > 1.5 else (float("nan"), float("nan"))
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    return {
        "L": float(lab[..., 0].mean()),
        "a": float(lab[..., 1].mean()),
        "b": float(lab[..., 2].mean()),
        "chroma": float(chroma.mean()),
        "contrast": float(lab[..., 0].std()),
        "detail": float(detail_map.mean()),
        "tile_h": th,
        "tile_v": tv,
    }


def palette(lab: np.ndarray, k: int = PALETTE) -> tuple:
    """k colours (Lab) and each one's share of the picture, darkest first."""
    flat = lab.reshape(-1, 3)
    rng = np.random.default_rng(1882)
    sample = flat[rng.choice(len(flat), 40000, replace=False)]
    centres, _ = kmeans2(sample, k, minit="++", seed=1882, iter=25)
    d = ((sample[:, None, :] - centres[None, :, :]) ** 2).sum(-1)
    label = d.argmin(1)
    share = np.bincount(label, minlength=k) / len(label)
    keep = share > 0
    centres, share = centres[keep], share[keep]
    order = np.argsort(centres[:, 0])
    return centres[order], share[order], sample


def palette_gap(sample: np.ndarray, other: np.ndarray, own: np.ndarray = None) -> float:
    """Mean dE from each sampled pixel to the nearest colour of the other palette, less the same
    to its own palette when `own` is given (so an identical picture scores 0, not its k-means
    quantisation error)."""
    d = np.sqrt(((sample[:, None, :] - other[None, :, :]) ** 2).sum(-1)).min(1).mean()
    if own is not None:
        d -= np.sqrt(((sample[:, None, :] - own[None, :, :]) ** 2).sum(-1)).min(1).mean()
    return float(max(d, 0.0))


def style(lab: np.ndarray, detail_map: np.ndarray) -> dict:
    """The whole-frame style measures (the scored ones)."""
    L = lab[..., 0]
    chroma = np.hypot(lab[..., 1], lab[..., 2])
    p = np.percentile(L, [5, 50, 95, 99])
    b3 = gaussian_filter(L, 3.0, mode="reflect")
    b1 = gaussian_filter(L, 1.0, mode="reflect")
    b12 = gaussian_filter(L, 12.0, mode="reflect")
    hp = np.abs(L - b3)
    mp = np.abs(b3 - b12)
    fine = np.abs(L - b1).mean()
    quiet = mp < np.percentile(mp, 25)
    near = L[H * 2 // 3:] / 100.0
    far = L[H * 2 // 5:H * 3 // 5] / 100.0
    tn = tile_size(near)
    tf = tile_size(far)
    return {
        "L5": float(p[0]), "L50": float(p[1]), "L95": float(p[2]), "L99": float(p[3]),
        "shadow": float((L < 10.0).mean()), "highlight": float((L > 80.0).mean()),
        "chroma": float(chroma.mean()), "b": float(lab[..., 2].mean()),
        "corr": float(np.corrcoef(L.ravel(), chroma.ravel())[0, 1]),
        "coherence": float(np.corrcoef(hp.ravel(), mp.ravel())[0, 1]),
        "grain": float(detail_map[quiet].mean()),
        "hardness": float(fine / max(detail_map.mean(), 1e-6)),
        "tile_near": float(np.nanmean(tn)), "tile_far": float(np.nanmean(tf)),
        "detail": float(detail_map.mean()),
    }


def measure(img: Image.Image) -> dict:
    rgb = np.asarray(img.convert("RGB"))
    lab = to_lab(rgb)
    blurred = np.stack([gaussian_filter(lab[..., c], 3.0, mode="reflect") for c in range(3)], -1)
    detail_map = np.linalg.norm(lab - blurred, axis=-1)
    whole = measure_region(lab, detail_map)
    whole["contrast_range"] = float(np.percentile(lab[..., 0], 95) - np.percentile(lab[..., 0], 5))
    regions = []
    for gy in range(GRID):
        row = []
        for gx in range(GRID):
            y0, y1 = gy * H // GRID, (gy + 1) * H // GRID
            x0, x1 = gx * W // GRID, (gx + 1) * W // GRID
            row.append(measure_region(lab[y0:y1, x0:x1], detail_map[y0:y1, x0:x1]))
        regions.append(row)
    centres, share, sample = palette(lab)
    return {"whole": whole, "style": style(lab, detail_map), "regions": regions,
            "palette": centres, "share": share, "sample": sample}


def load(path: str) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if img.size != (W, H):
        img = img.resize((W, H), Image.LANCZOS)
    return img


# --- judging --------------------------------------------------------------------------------

def differences(ours: dict, theirs: dict) -> list:
    """Every scored difference, as (severity, words), worst first. Severity 1 is about 'clearly
    visible': 10 L*, 10 points of deep shadow, 3 points of blown highlight, 8 of chroma or b*, 0.2 of
    correlation, 0.1 of hardness, a factor of 1.5 in tile size, 6 dE of palette. The noise-prone
    measures are one-sided (see the module docstring)."""
    out = []
    o, p = ours["style"], theirs["style"]

    def add(sev: float, words: str) -> None:
        out.append((round(max(float(sev), 0.0), 2), words))

    def cmp(key: str, scale: float, more: str, less: str, fmt: str = "%.0f") -> None:
        d = o[key] - p[key]
        add(abs(d) / scale, "%s (%s vs %s)" % (more if d > 0 else less, fmt % o[key], fmt % p[key]))

    cmp("L50", 10.0, "midtones too bright", "midtones too dark")
    cmp("L5", 10.0, "shadows too light", "shadows too deep")
    cmp("L95", 10.0, "bright things too bright", "bright things too dim")
    cmp("L99", 10.0, "the brightest too bright", "the brightest too dim")
    cmp("shadow", 0.10, "too much deep shadow", "too little deep shadow (share under L* 10)", "%.2f")
    cmp("highlight", 0.03, "too much blown highlight (share over L* 80)", "too little blown highlight", "%.3f")
    cmp("chroma", 8.0, "colour too strong", "colour too weak (chroma)")
    cmp("b", 8.0, "too yellow", "too blue/grey (b*)")
    cmp("corr", 0.20, "bright things too colourful", "bright things too pale (chroma-L* correlation)", "%.2f")
    add((p["coherence"] - o["coherence"]) / 0.08, "noisier than paint: detail not on the structure (coherence %.2f vs %.2f)" % (o["coherence"], p["coherence"]))
    add((o["grain"] - p["grain"]) / 1.5, "grain in flat areas (%.1f vs %.1f dE)" % (o["grain"], p["grain"]))
    cmp("hardness", 0.10, "block edges too hard", "block edges too soft", "%.2f")
    if np.isfinite(o["tile_near"]) and np.isfinite(p["tile_near"]) and o["tile_near"] > 0 and p["tile_near"] > 0:
        add(np.log(p["tile_near"] / o["tile_near"]) / np.log(1.5), "near tiles finer than the painting's (%.1f vs %.1f px)" % (o["tile_near"], p["tile_near"]))
    if np.isfinite(o["tile_far"]) and np.isfinite(p["tile_far"]) and o["tile_far"] > 0 and p["tile_far"] > 0:
        add(np.log(o["tile_far"] / p["tile_far"]) / np.log(1.5), "far tiles chunkier than the painting's (%.1f vs %.1f px)" % (o["tile_far"], p["tile_far"]))
    add(ours["missing"] / 6.0, "palette: painting colours we lack (%.1f dE)" % ours["missing"])
    add(ours["extra"] / 6.0, "palette: colours the painting lacks (%.1f dE)" % ours["extra"])
    out.sort(key=lambda t: -t[0])
    return out


def score(diffs: list) -> float:
    """One number for the round: the mean severity of all scored differences (lower is closer)."""
    return round(float(np.mean([d[0] for d in diffs])), 3)


# --- the picture ----------------------------------------------------------------------------

def _font(size: int, mono: bool = False):
    try:
        return ImageFont.truetype(FONT_MONO if mono else FONT, size)
    except OSError:
        return ImageFont.load_default()


def annotate(img: Image.Image, m: dict) -> Image.Image:
    """The picture with the 3x3 grid and each region's L*, b* and tile size written in it."""
    out = img.copy()
    d = ImageDraw.Draw(out, "RGBA")
    f = _font(15, True)
    for gy in range(GRID):
        for gx in range(GRID):
            x0, y0 = gx * W // GRID, gy * H // GRID
            r = m["regions"][gy][gx]
            d.rectangle((x0, y0, x0 + W // GRID - 1, y0 + H // GRID - 1), outline=(255, 255, 255, 70))
            text = "L*%3.0f b*%+3.0f\ntile %.1f/%.1f\ndetail %.1f" % (r["L"], r["b"], r["tile_h"], r["tile_v"], r["detail"])
            d.rectangle((x0 + 4, y0 + 4, x0 + 170, y0 + 60), fill=(0, 0, 0, 140))
            d.multiline_text((x0 + 8, y0 + 6), text, fill=(255, 240, 210, 255), font=f, spacing=2)
    return out


def swatches(centres: np.ndarray, share: np.ndarray, width: int, height: int) -> Image.Image:
    img = Image.new("RGB", (width, height))
    d = ImageDraw.Draw(img)
    x = 0.0
    rgb = lab_to_rgb(centres)
    for c, s in zip(rgb, share):
        w = s * width
        d.rectangle((int(x), 0, int(x + w), height), fill=tuple(int(v) for v in c))
        x += w
    return img


def panel(view: str, render: Image.Image, painting: Image.Image, ours: dict, theirs: dict,
          diffs: list, title: str) -> Image.Image:
    half = 960
    hh = half * H // W
    top = 34
    strip = 26
    text_h = 236
    img = Image.new("RGB", (half * 2 + 8, top + hh + strip * 2 + 12 + text_h), (18, 14, 11))
    d = ImageDraw.Draw(img)
    d.text((10, 8), title, fill=(235, 215, 180), font=_font(18))
    img.paste(annotate(render, ours).resize((half, hh), Image.NEAREST), (0, top))
    img.paste(annotate(painting, theirs).resize((half, hh), Image.LANCZOS), (half + 8, top))
    y = top + hh + 4
    img.paste(swatches(ours["palette"], ours["share"], half, strip), (0, y))
    img.paste(swatches(theirs["palette"], theirs["share"], half, strip), (half + 8, y))
    y += strip + 6
    f = _font(15, True)
    w, p = ours["style"], theirs["style"]
    rows = [
        ("", "game", "painting"),
        ("L* 5 / 50 / 95 / 99", "%.0f / %.0f / %.0f / %.0f" % (w["L5"], w["L50"], w["L95"], w["L99"]), "%.0f / %.0f / %.0f / %.0f" % (p["L5"], p["L50"], p["L95"], p["L99"])),
        ("shadow <10 / blown >80", "%.0f%% / %.1f%%" % (w["shadow"] * 100, w["highlight"] * 100), "%.0f%% / %.1f%%" % (p["shadow"] * 100, p["highlight"] * 100)),
        ("chroma / b* / corr", "%.1f / %+.1f / %.2f" % (w["chroma"], w["b"], w["corr"]), "%.1f / %+.1f / %.2f" % (p["chroma"], p["b"], p["corr"])),
        ("coherence / grain / hard", "%.2f / %.1f / %.2f" % (w["coherence"], w["grain"], w["hardness"]), "%.2f / %.1f / %.2f" % (p["coherence"], p["grain"], p["hardness"])),
        ("tiles near / far px", "%.1f / %.1f" % (w["tile_near"], w["tile_far"]), "%.1f / %.1f" % (p["tile_near"], p["tile_far"])),
        ("detail dE (not scored)", "%.2f" % w["detail"], "%.2f" % p["detail"]),
        ("palette missing/extra", "%.1f / %.1f dE" % (ours["missing"], ours["extra"]), ""),
        ("score v2 (lower closer)", "%.3f" % score(diffs), ""),
    ]
    for i, (a, b, c) in enumerate(rows):
        d.text((10, y + i * 24), a, fill=(200, 185, 160), font=f)
        d.text((230, y + i * 24), b, fill=(240, 225, 195), font=f)
        d.text((430, y + i * 24), c, fill=(240, 225, 195), font=f)
    d.text((half + 18, y), "Biggest differences", fill=(235, 215, 180), font=_font(16))
    for i, (sev, words) in enumerate(diffs[:8]):
        d.text((half + 18, y + 26 + i * 24), "%.1f  %s" % (sev, words), fill=(240, 225, 195), font=f)
    return img


# --- running --------------------------------------------------------------------------------

def next_round_dir() -> str:
    today = datetime.date.today().isoformat()
    os.makedirs(JUDGE_DIR, exist_ok=True)
    n = 1
    while os.path.exists(os.path.join(JUDGE_DIR, "%s_r%d" % (today, n))):
        n += 1
    path = os.path.join(JUDGE_DIR, "%s_r%d" % (today, n))
    os.makedirs(path)
    return path


def render(out_dir: str, views: list, godot: str) -> None:
    names = ",".join(VIEWS[v][0] for v in views)
    cmd = [godot, "--path", ROOT, "--rendering-driver", "vulkan", "-s", "res://tools/screenshots.gd",
           "--", "--out=" + out_dir, "--only=" + names]
    if os.environ.get("DISPLAY") is None:
        cmd = ["xvfb-run", "-a"] + cmd
    print(" ".join(cmd))
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for v in views:
        x3 = os.path.join(out_dir, VIEWS[v][0] + "_x3.png")
        if os.path.exists(x3):
            os.remove(x3)


def plain(m: dict) -> dict:
    return {"whole": m["whole"], "style": m["style"], "regions": m["regions"],
            "palette": [[round(float(x), 1) for x in c] for c in m["palette"]],
            "share": [round(float(s), 4) for s in m["share"]]}


def judge(view: str, render_path: str, out_dir: str, title: str) -> dict:
    painting = load(os.path.join(ROOT, VIEWS[view][1]))
    shot = load(render_path)
    theirs = measure(painting)
    ours = measure(shot)
    ours["missing"] = palette_gap(theirs["sample"], ours["palette"], theirs["palette"])
    ours["extra"] = palette_gap(ours["sample"], theirs["palette"], ours["palette"])
    diffs = differences(ours, theirs)
    panel(view, shot, painting, ours, theirs, diffs, title).save(os.path.join(out_dir, "%s_judge.png" % view))
    return {"view": VIEWS[view][0], "painting": VIEWS[view][1], "score": score(diffs),
            "missing": ours["missing"], "extra": ours["extra"],
            "ours": plain(ours), "painting_measures": plain(theirs),
            "differences": [{"severity": s, "what": w} for s, w in diffs[:20]]}


# --- the probes (the judge's own test) ------------------------------------------------------

PROBE_ROUND = os.path.join(JUDGE_DIR, "2026-10-02_r25")
# The same views after the engine's light and grade pass (ART_REVIEW §10.1-2): the light moved
# toward the paintings' and nothing else changed.
GRADED_ROUND = os.path.join(JUDGE_DIR, "2026-10-02_r27")


def _block_noise(img: Image.Image, size: int = 6, amount: float = 18.0) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    rng = np.random.default_rng(1)
    n = rng.uniform(-amount, amount, (a.shape[0] // size + 1, a.shape[1] // size + 1, 1))
    n = np.repeat(np.repeat(n, size, 0), size, 1)[: a.shape[0], : a.shape[1]]
    return Image.fromarray(np.clip(a + n, 0, 255).astype(np.uint8))


def _pixel_noise(img: Image.Image, amount: float = 18.0) -> Image.Image:
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    n = np.random.default_rng(2).uniform(-amount, amount, a.shape[:2] + (1,))
    return Image.fromarray(np.clip(a + n, 0, 255).astype(np.uint8))


def _grade_mock(img: Image.Image) -> Image.Image:
    """A grade toward the paintings' light, in the spirit of ART_REVIEW §3.1's mock: blacks pulled
    down (a toe), highlights rolled off (a shoulder), +15 % saturation."""
    a = np.asarray(img.convert("RGB")).astype(np.float64) / 255.0
    v = np.clip((a - 0.06) / 0.94, 0, 1)
    v = v * 0.8 / (0.8 + 0.2 * v)
    g = v.mean(2, keepdims=True)
    v = g + (v - g) * 1.15
    return Image.fromarray((np.clip(v, 0, 1) * 255).astype(np.uint8))


def score_image(view: str, img: Image.Image, painting_m: dict = None) -> float:
    painting = load(os.path.join(ROOT, VIEWS[view][1]))
    theirs = painting_m or measure(painting)
    ours = measure(img if img.size == (W, H) else img.resize((W, H), Image.LANCZOS))
    ours["missing"] = palette_gap(theirs["sample"], ours["palette"], theirs["palette"])
    ours["extra"] = palette_gap(ours["sample"], theirs["palette"], ours["palette"])
    return score(differences(ours, theirs))


def probes() -> bool:
    """ART_REVIEW §5's probes on round 25's renders: the painting scores ~0 and the same shifted
    60 px nearly so; noise, blur and greyscale score worse than the render; a grade toward the
    painting's light (a Python mock, and round 27, the engine's real light pass) scores better.
    Prints the table; True if every rule holds."""
    from PIL import ImageFilter
    ok = True
    for view in VIEWS:
        painting = load(os.path.join(ROOT, VIEWS[view][1]))
        theirs = measure(painting)
        ours = load(os.path.join(PROBE_ROUND, VIEWS[view][0] + ".png"))
        graded = load(os.path.join(GRADED_ROUND, VIEWS[view][0] + ".png"))
        shifted = Image.fromarray(np.roll(np.asarray(painting), 60, axis=1))
        rows = [("the painting itself", painting), ("the painting shifted 60 px", shifted), ("round 25", ours),
                ("round 25 + random 6 px block noise", _block_noise(ours)), ("round 25 + per-pixel noise", _pixel_noise(ours)),
                ("round 25 blurred 3 px", ours.filter(ImageFilter.GaussianBlur(3))), ("round 25 + the mock grade", _grade_mock(ours)),
                ("round 27, the engine's light pass", graded),
                ("the painting in greyscale", painting.convert("L").convert("RGB"))]
        got = {}
        print(view)
        for name, img in rows:
            got[name] = score_image(view, img, theirs)
            print("  %-38s %.3f" % (name, got[name]))
        base = got["round 25"]
        rules = [
            ("the painting scores under 0.03", got["the painting itself"] < 0.03),
            ("shifted 60 px scores under 0.05", got["the painting shifted 60 px"] < 0.05),
            ("block noise scores worse than the render", got["round 25 + random 6 px block noise"] > base),
            ("pixel noise scores worse", got["round 25 + per-pixel noise"] > base),
            ("blur scores worse", got["round 25 blurred 3 px"] > base),
            ("greyscale scores worse", got["the painting in greyscale"] > base),
            ("the mock grade scores better", got["round 25 + the mock grade"] < base),
            ("the engine's light pass scores better", got["round 27, the engine's light pass"] < base),
        ]
        for words, held in rules:
            print("  %s %s" % ("ok  " if held else "FAIL", words))
            ok = ok and held
    return ok


def main() -> None:
    args = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in sys.argv[1:]}
    if "--probes" in args:
        sys.exit(0 if probes() else 1)
    views = [args["--only"]] if "--only" in args else list(VIEWS)
    godot = args.get("--godot", "godot")
    note = args.get("--note", "")
    pick = args.get("--pick", "")
    out_dir = next_round_dir()
    src = args.get("--from")
    if src:
        for v in views:
            Image.open(os.path.join(src, VIEWS[v][0] + ".png")).save(os.path.join(out_dir, VIEWS[v][0] + ".png"))
    else:
        render(out_dir, views, godot)
    name = os.path.basename(out_dir)
    report = {"round": name, "note": note, "pick": pick, "judge": 2, "views": {}}
    for v in views:
        title = "%s  %s  vs %s%s" % (name, VIEWS[v][0], os.path.basename(VIEWS[v][1]), ("  - " + note) if note else "")
        report["views"][v] = judge(v, os.path.join(out_dir, VIEWS[v][0] + ".png"), out_dir, title)
    with open(os.path.join(out_dir, "report.json"), "w") as f:
        json.dump(report, f, indent=1, default=float)
    lines = ["# %s%s" % (name, (": " + note) if note else ""), ""]
    for v, r in report["views"].items():
        lines.append("## %s (score %.3f, lower is closer)" % (r["view"], r["score"]))
        lines.append("")
        lines.append("![%s](%s_judge.png)" % (v, v))
        lines.append("")
        for dd in r["differences"][:8]:
            lines.append("- %.1f %s" % (dd["severity"], dd["what"]))
        lines.append("")
    with open(os.path.join(out_dir, "report.md"), "w") as f:
        f.write("\n".join(lines))
    hist = os.path.join(JUDGE_DIR, "history.md")
    header = ("\n## Judge v2 (from 2026-10-02_r28): style, not composition\n\nScores before this line are the old "
              "judge's and don't compare. Score: mean severity of the whole-frame style differences "
              "(tools/judge.py), lower is closer to the painting.\n\n"
              "| round | view | score | L* 50 / 5 / 95 ours vs painting | shadow / blown | chroma / corr | "
              "coherence / grain / hard | tiles near / far | palette missing | biggest difference | note | pick |\n"
              "|---|---|---|---|---|---|---|---|---|---|---|---|\n")
    have = open(hist).read() if os.path.exists(hist) else ""
    with open(hist, "a") as f:
        if "## Judge v2" not in have:
            if not have:
                f.write("# Reference judge history\n")
            f.write(header)
        for v, r in report["views"].items():
            o, p = r["ours"]["style"], r["painting_measures"]["style"]
            f.write("| %s | %s | %.3f | %.0f/%.0f/%.0f vs %.0f/%.0f/%.0f | %.0f%%/%.1f%% vs %.0f%%/%.1f%% | %.0f/%.2f vs %.0f/%.2f | "
                    "%.2f/%.1f/%.2f vs %.2f/%.1f/%.2f | %.1f/%.1f vs %.1f/%.1f | %.1f | %s | %s | %s |\n" % (
                name, v, r["score"], o["L50"], o["L5"], o["L95"], p["L50"], p["L5"], p["L95"],
                o["shadow"] * 100, o["highlight"] * 100, p["shadow"] * 100, p["highlight"] * 100,
                o["chroma"], o["corr"], p["chroma"], p["corr"], o["coherence"], o["grain"], o["hardness"],
                p["coherence"], p["grain"], p["hardness"], o["tile_near"], o["tile_far"], p["tile_near"], p["tile_far"],
                r["missing"], r["differences"][0]["what"], note, pick))
    print(out_dir)
    for v, r in report["views"].items():
        print("%s score %.3f" % (v, r["score"]))
        for dd in r["differences"][:6]:
            print("  %.1f %s" % (dd["severity"], dd["what"]))


if __name__ == "__main__":
    main()
