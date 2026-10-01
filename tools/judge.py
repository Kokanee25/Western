#!/usr/bin/env python3
"""The reference judge: render the two shot-match views, put each beside its painting, and measure
how they differ, so a round of art work can be judged by numbers as well as by eye.

    python3 tools/judge.py [--note="what changed"] [--only=saloon|street] [--from=DIR] [--godot=godot]

Renders `shot_match_saloon` and `shot_match_street` (tools/screenshots.gd, Vulkan under xvfb) into
a new round folder, docs/screenshots/judge/<date>_r<n>/, and writes there for each view:
  <view>.png         the render (1280x720, untouched)
  <view>_judge.png   render | painting, the 3x3 region grid with each region's numbers, both
                     palettes, and the biggest differences in words
and report.json (every number) and report.md (the summary). docs/screenshots/judge/history.md
gets one line per view per round, so progress reads down the page. --from=DIR judges renders
already made (DIR/shot_match_saloon.png, DIR/shot_match_street.png) instead of rendering.

What's measured (both pictures at 1280x720; CIE L*a*b*):
  brightness   mean L* (0 black .. 100 white), whole frame and per region
  warmth       mean b* (+ yellow / - blue) and a* (+ red / - green)
  colourfulness mean chroma
  contrast     standard deviation of L*, and the 5th..95th percentile range
  detail       the mosaic: mean colour difference (dE) between each pixel and its surroundings
               blurred over ~6 px, i.e. how much the shades change square to square
  tile size    the painting's pixels are tiles on the surfaces; the size (px at 1280 wide) is twice
               the half-width of the autocorrelation of the high-passed luminance, across (h) and
               down (v): random flat tiles of size s give s. Long grain streaks read as tall v.
  palette      16 colours by k-means in Lab; "missing" = how far (dE) the painting's pixels are
               from our nearest palette colour, "extra" = the same the other way round
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


def palette_gap(sample: np.ndarray, other: np.ndarray) -> float:
    """Mean dE from each sampled pixel to the nearest colour of the other palette."""
    d = np.sqrt(((sample[:, None, :] - other[None, :, :]) ** 2).sum(-1)).min(1)
    return float(d.mean())


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
    return {"whole": whole, "regions": regions, "palette": centres, "share": share, "sample": sample}


def load(path: str) -> Image.Image:
    img = Image.open(path).convert("RGB")
    if img.size != (W, H):
        img = img.resize((W, H), Image.LANCZOS)
    return img


# --- judging --------------------------------------------------------------------------------

def differences(ours: dict, theirs: dict) -> list:
    """Every difference worth naming, as (severity, words), worst first. Severity 1 is about
    'clearly visible': 10 L*, 8 b*, a factor of 1.5 in tile size or detail, 6 dE of palette."""
    out = []

    def add(sev: float, words: str) -> None:
        out.append((round(float(sev), 2), words))

    w, p = ours["whole"], theirs["whole"]
    add(abs(w["L"] - p["L"]) / 10.0, "whole frame %s (L* %.0f vs %.0f)" % (
        "too bright" if w["L"] > p["L"] else "too dark", w["L"], p["L"]))
    add(abs(w["contrast"] - p["contrast"]) / 6.0, "contrast %s (L* spread %.0f vs %.0f)" % (
        "too high" if w["contrast"] > p["contrast"] else "too low", w["contrast"], p["contrast"]))
    add(abs(w["chroma"] - p["chroma"]) / 8.0, "colour %s (chroma %.0f vs %.0f)" % (
        "too strong" if w["chroma"] > p["chroma"] else "too weak", w["chroma"], p["chroma"]))
    add(abs(np.log(w["detail"] / p["detail"])) / np.log(1.5), "mosaic %s (detail %.1f vs %.1f dE)" % (
        "too busy" if w["detail"] > p["detail"] else "too plain", w["detail"], p["detail"]))
    add(ours["missing"] / 6.0, "palette: painting colours we lack (%.1f dE)" % ours["missing"])
    add(ours["extra"] / 6.0, "palette: colours the painting lacks (%.1f dE)" % ours["extra"])
    for gy in range(GRID):
        for gx in range(GRID):
            a, b = ours["regions"][gy][gx], theirs["regions"][gy][gx]
            name = REGION_NAMES[gy][gx]
            add(abs(a["L"] - b["L"]) / 10.0, "%s %s (L* %.0f vs %.0f)" % (
                name, "too bright" if a["L"] > b["L"] else "too dark", a["L"], b["L"]))
            add(abs(a["b"] - b["b"]) / 8.0, "%s %s (b* %+.0f vs %+.0f)" % (
                name, "too yellow" if a["b"] > b["b"] else "too blue/grey", a["b"], b["b"]))
            add(abs(a["a"] - b["a"]) / 8.0, "%s %s (a* %+.0f vs %+.0f)" % (
                name, "too red" if a["a"] > b["a"] else "too green", a["a"], b["a"]))
            for axis, label in (("tile_h", "across"), ("tile_v", "down")):
                if np.isfinite(a[axis]) and np.isfinite(b[axis]) and a[axis] > 0 and b[axis] > 0:
                    r = a[axis] / b[axis]
                    add(abs(np.log(r)) / np.log(1.5), "%s tiles %s %.1fx the painting's (%.1f vs %.1f px)" % (
                        name, label, r, a[axis], b[axis]))
            add(abs(np.log(a["detail"] / b["detail"])) / np.log(1.5), "%s mosaic %s (%.1f vs %.1f dE)" % (
                name, "too busy" if a["detail"] > b["detail"] else "too plain", a["detail"], b["detail"]))
    out.sort(key=lambda t: -t[0])
    return out


def score(diffs: list) -> float:
    """One number for the round: the mean severity of all differences (lower is closer)."""
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
    w, p = ours["whole"], theirs["whole"]
    rows = [
        ("", "game", "painting"),
        ("brightness L*", "%.1f" % w["L"], "%.1f" % p["L"]),
        ("warmth a*/b*", "%+.1f / %+.1f" % (w["a"], w["b"]), "%+.1f / %+.1f" % (p["a"], p["b"])),
        ("chroma", "%.1f" % w["chroma"], "%.1f" % p["chroma"]),
        ("contrast sd / 5-95", "%.1f / %.0f" % (w["contrast"], w["contrast_range"]), "%.1f / %.0f" % (p["contrast"], p["contrast_range"])),
        ("detail dE", "%.2f" % w["detail"], "%.2f" % p["detail"]),
        ("tile across/down px", "%.1f / %.1f" % (w["tile_h"], w["tile_v"]), "%.1f / %.1f" % (p["tile_h"], p["tile_v"])),
        ("palette missing/extra", "%.1f / %.1f dE" % (ours["missing"], ours["extra"]), ""),
        ("score (lower closer)", "%.3f" % score(diffs), ""),
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
    return {"whole": m["whole"], "regions": m["regions"],
            "palette": [[round(float(x), 1) for x in c] for c in m["palette"]],
            "share": [round(float(s), 4) for s in m["share"]]}


def judge(view: str, render_path: str, out_dir: str, title: str) -> dict:
    painting = load(os.path.join(ROOT, VIEWS[view][1]))
    shot = load(render_path)
    theirs = measure(painting)
    ours = measure(shot)
    ours["missing"] = palette_gap(theirs["sample"], ours["palette"])
    ours["extra"] = palette_gap(ours["sample"], theirs["palette"])
    diffs = differences(ours, theirs)
    panel(view, shot, painting, ours, theirs, diffs, title).save(os.path.join(out_dir, "%s_judge.png" % view))
    return {"view": VIEWS[view][0], "painting": VIEWS[view][1], "score": score(diffs),
            "missing": ours["missing"], "extra": ours["extra"],
            "ours": plain(ours), "painting_measures": plain(theirs),
            "differences": [{"severity": s, "what": w} for s, w in diffs[:20]]}


def main() -> None:
    args = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True) for a in sys.argv[1:]}
    views = [args["--only"]] if "--only" in args else list(VIEWS)
    godot = args.get("--godot", "godot")
    note = args.get("--note", "")
    out_dir = next_round_dir()
    src = args.get("--from")
    if src:
        for v in views:
            Image.open(os.path.join(src, VIEWS[v][0] + ".png")).save(os.path.join(out_dir, VIEWS[v][0] + ".png"))
    else:
        render(out_dir, views, godot)
    name = os.path.basename(out_dir)
    report = {"round": name, "note": note, "views": {}}
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
    new = not os.path.exists(hist)
    with open(hist, "a") as f:
        if new:
            f.write("# Reference judge history\n\nOne line per view per round (tools/judge.py). Score: mean "
                    "severity of every measured difference, lower is closer to the painting.\n\n"
                    "| round | view | score | L* game/painting | contrast | detail | tile across/down | "
                    "palette missing | biggest difference | note |\n|---|---|---|---|---|---|---|---|---|---|\n")
        for v, r in report["views"].items():
            o, p = r["ours"]["whole"], r["painting_measures"]["whole"]
            f.write("| %s | %s | %.3f | %.0f / %.0f | %.1f / %.1f | %.2f / %.2f | %.1f/%.1f vs %.1f/%.1f | %.1f | %s | %s |\n" % (
                name, v, r["score"], o["L"], p["L"], o["contrast"], p["contrast"], o["detail"], p["detail"],
                o["tile_h"], o["tile_v"], p["tile_h"], p["tile_v"], r["missing"],
                r["differences"][0]["what"], note))
    print(out_dir)
    for v, r in report["views"].items():
        print("%s score %.3f" % (v, r["score"]))
        for dd in r["differences"][:6]:
            print("  %.1f %s" % (dd["severity"], dd["what"]))


if __name__ == "__main__":
    main()
