"""Before and after, beside his portraits (docs/briefs/character-style-fidelity.md, phase 4).

    python3 tools/characters/style_compare.py --man=bold_cowboy [--dir=docs/screenshots/portrait/probe]
        [--before=before] [--after=after] [--out=PNG]

Reads two style_probe.py runs (their panels, cropped as each portrait, and their numbers) and lays
them out: for the front, three-quarter and profile, the portrait, then the game's render of him
(neutral light) before and after, then his clay before and after; then the saloon before and
after; then the numbers, one line an axis: proportions, landmarks, patches, tones, detail, light.
"""
import json
import os
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
H = 260
BG = (22, 20, 18)
INK = (235, 225, 205)
VIEWS = ("front", "three_quarter", "profile_left")


def tile(path, title):
    if not os.path.exists(path):
        im = Image.new("RGB", (H, H), (40, 36, 32))
    else:
        im = Image.open(path).convert("RGB")
        im = im.resize((int(im.width * H / im.height), H), Image.NEAREST)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 6 * len(title) + 8, 13], fill=BG)
    d.text((4, 1), title, fill=INK)
    return im


def mean(xs):
    xs = [x for x in xs if x == x]
    return sum(xs) / max(len(xs), 1)


def numbers(r):
    """One run's numbers, averaged over the views (the saloon: front only)."""
    out = {}
    views = [r["views"][v] for v in VIEWS if v in r["views"]]
    prop = []
    for v in views:
        pp, po = v["proportions"]["portrait"], v["proportions"]["ours"]
        prop += [abs(po[k] - pp[k]) / pp[k] for k in pp]
    out["proportions off (mean, %)"] = round(100 * mean(prop), 1)
    out["landmarks off (% eye-chin): jaw"] = round(mean([v["geometry_err_pct"]["jaw"] for v in views]), 1)
    out["landmarks off: brow, eyes, nose, mouth"] = round(mean([mean([v["geometry_err_pct"][g] for g in ("brow", "eyes", "nose", "mouth")]) for v in views]), 1)
    for panel, label in (("game, neutral", "game, neutral"), ("final paint", "paint")):
        ps = [v["panels"].get(panel) for v in views if isinstance(v["panels"].get(panel), dict)]
        if ps:
            out["patch %% (%s)" % label] = round(mean([p["patch_pct"] for p in ps]), 2)
            out["tones (%s)" % label] = round(mean([p["tones"] for p in ps]), 1)
            out["detail rms (%s)" % label] = round(mean([p["detail_rms"] for p in ps]), 1)
    pt = [v["panels"]["portrait"] for v in views]
    out["portrait: patch %, tones, detail"] = "%.2f, %.1f, %.1f" % (mean([p["patch_pct"] for p in pt]), mean([p["tones"] for p in pt]),
                                                                   mean([p["detail_rms"] for p in pt]))
    sal = r["views"].get("front", {}).get("panels", {}).get("game, saloon")
    if isinstance(sal, dict):
        out["saloon L*, chroma, highlights %"] = "%.1f, %.1f, %.1f" % (sal["L_mean"], sal["chroma"], sal["highlights_pct"])
    p0 = r["views"]["front"]["panels"]["portrait"]
    out["portrait L*, chroma, highlights %"] = "%.1f, %.1f, %.1f" % (p0["L_mean"], p0["chroma"], p0["highlights_pct"])
    return out


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    man = a.get("--man", "bold_cowboy")
    d = a.get("--dir", os.path.join(ROOT, "docs", "screenshots", "portrait", "probe"))
    b, f = a.get("--before", "before"), a.get("--after", "after")
    out = a.get("--out", os.path.join(d, "%s_before_after.png" % man))
    rows = []
    for v in VIEWS:
        name = v.replace("_", " ")
        rows.append([tile(os.path.join(d, "%s_%s" % (man, f), "%s_portrait.png" % v), "%s: portrait" % name),
                     tile(os.path.join(d, "%s_%s" % (man, b), "%s_game_neutral.png" % v), "before: game, neutral"),
                     tile(os.path.join(d, "%s_%s" % (man, f), "%s_game_neutral.png" % v), "after: game, neutral"),
                     tile(os.path.join(d, "%s_%s" % (man, b), "%s_clay.png" % v), "before: shape"),
                     tile(os.path.join(d, "%s_%s" % (man, f), "%s_clay.png" % v), "after: shape")])
    rows.append([tile(os.path.join(d, "%s_%s" % (man, f), "front_portrait.png"), "portrait"),
                 tile(os.path.join(d, "%s_%s" % (man, b), "front_game_saloon.png"), "before: game, saloon"),
                 tile(os.path.join(d, "%s_%s" % (man, f), "front_game_saloon.png"), "after: game, saloon"),
                 tile(os.path.join(d, "%s_%s" % (man, b), "front_final_paint.png"), "before: paint (unlit)"),
                 tile(os.path.join(d, "%s_%s" % (man, f), "front_final_paint.png"), "after: paint (unlit)")])
    nb = numbers(json.load(open(os.path.join(d, "%s_%s.json" % (man, b)))))
    na = numbers(json.load(open(os.path.join(d, "%s_%s.json" % (man, f)))))
    W = max(sum(t.width for t in r) + 6 * len(r) for r in rows)
    lines = ["%-42s %14s %14s" % ("measure (against his portraits)", "before", "after")]
    for k in nb:
        lines.append("%-42s %14s %14s" % (k, nb[k], na.get(k, "")))
    TH = 16 * len(lines) + 16
    sheet = Image.new("RGB", (W, len(rows) * (H + 6) + TH), BG)
    y = 0
    for r in rows:
        x = 0
        for t in r:
            sheet.paste(t, (x, y))
            x += t.width + 6
        y += H + 6
    dr = ImageDraw.Draw(sheet)
    for i, line in enumerate(lines):
        dr.text((8, y + 8 + 16 * i), line, fill=INK)
    sheet.save(out)
    print("style_compare: wrote", out)
    print("\n".join(lines))


if __name__ == "__main__":
    main()
