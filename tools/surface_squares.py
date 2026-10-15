#!/usr/bin/env python3
"""Square size and finish of surfaces in a render, crop by crop, beside the man's (roadmap 1.4,
art, 2026-10-15: "surfaces to the man": the wood, end grain, posts, planks and the road at his face's
and coat's square size and finish, so close and far they're one picture).

    python3 tools/surface_squares.py measure DIR [--spec=tools/surface_squares.json] [--json=OUT]
    python3 tools/surface_squares.py sheet DIR OUT.png [--before=DIR0] [--spec=...]
    python3 tools/surface_squares.py targets DIR OUT_DIR [--before=DIR0]

DIR holds the views' renders (<view>.png, as tools/screenshots.gd writes them). The spec names, per
view, crops of the render (x0, y0, x1, y1 at 1280x720) and what each shows; a crop of the man (his
cheek, his coat) is the yardstick the surfaces round him are read against. For each crop:

  square  the size of its squares in render pixels, across and down: twice the half-width of the
          autocorrelation of its high-passed luminance (tools/judge.py tile_size);
  step    how loud the squares are: the spread of L* once the broad light (a 10 px blur) is taken
          out, i.e. how much one square differs from the next;
  grain   detail finer than a square: the spread of L* left after a blur of a third of a square (0
          on flat squares; the woods' fine grain and the road's per-texel jitter show here);
  flat    the share of pixels within 2 L* of their right-hand neighbour (flat squares: high);
  L*, C*  mean lightness and chroma.

The sheet lays every crop at 3x, the render (and --before's beside it) with its numbers. `targets`
writes, per view the spec gives a target (docs/concept/targets/), target | before | now, each
720 high, as <view>.jpg in OUT_DIR.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy.ndimage import gaussian_filter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from judge import tile_size, to_lab  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = os.path.join(ROOT, "tools", "surface_squares.json")


def measure_crop(img: np.ndarray, box: list) -> dict:
    x0, y0, x1, y1 = box
    lab = to_lab(img[y0:y1, x0:x1])
    L = lab[..., 0]
    th, tv = tile_size(L / 100.0)
    sq = np.nanmean([th, tv]) if not (np.isnan(th) and np.isnan(tv)) else float("nan")
    broad = gaussian_filter(L, 10.0, mode="reflect")
    fine_sigma = max(0.5, (sq if sq == sq else 3.0) / 3.0)
    fine = gaussian_filter(L, fine_sigma, mode="reflect")
    flat = (np.abs(L[:, 1:] - L[:, :-1]) < 2.0).mean()
    return {
        "square_h": round(float(th), 1), "square_v": round(float(tv), 1), "square": round(float(sq), 1),
        "step": round(float((fine - broad).std()), 1),
        "grain": round(float((L - fine).std()), 1),
        "flat": round(float(flat), 2),
        "L": round(float(L.mean()), 1),
        "C": round(float(np.hypot(lab[..., 1], lab[..., 2]).mean()), 1),
    }


def load_spec(path: str) -> dict:
    with open(path) as f:
        return json.load(f)["views"]


def measure(d: str, spec: dict) -> dict:
    out = {}
    for view, crops in spec.items():
        p = os.path.join(d, view + ".png")
        if not os.path.exists(p):
            continue
        img = np.asarray(Image.open(p).convert("RGB"))
        out[view] = {c["name"]: dict(measure_crop(img, c["box"]), what=c["what"]) for c in crops}
    return out


def table(m: dict) -> str:
    lines = ["%-20s %-16s %6s %6s %5s %5s %5s %5s %5s  %s" % ("view", "crop", "sq_h", "sq_v", "step",
            "grain", "flat", "L*", "C*", "what")]
    for view, crops in m.items():
        for name, r in crops.items():
            lines.append("%-20s %-16s %6.1f %6.1f %5.1f %5.1f %5.2f %5.1f %5.1f  %s" % (view, name,
                    r["square_h"], r["square_v"], r["step"], r["grain"], r["flat"], r["L"], r["C"], r["what"]))
    return "\n".join(lines)


def _font(size: int):
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",):
        if os.path.exists(f):
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def sheet(d: str, out: str, spec: dict, before: str = None) -> None:
    font = _font(13)
    rows = []
    zoom = 3
    for view, crops in spec.items():
        p = os.path.join(d, view + ".png")
        if not os.path.exists(p):
            continue
        imgs = [("now", Image.open(p).convert("RGB"))]
        if before and os.path.exists(os.path.join(before, view + ".png")):
            imgs.insert(0, ("before", Image.open(os.path.join(before, view + ".png")).convert("RGB")))
        for c in crops:
            x0, y0, x1, y1 = c["box"]
            # At most 180 px of render a side at 3x.
            w, h = min(x1 - x0, 180), min(y1 - y0, 120)
            tiles = []
            for label, im in imgs:
                crop = im.crop((x0, y0, x0 + w, y0 + h)).resize((w * zoom, h * zoom), Image.NEAREST)
                r = measure_crop(np.asarray(im), c["box"])
                txt = "%s %s/%s: sq %.0f x %.0f  step %.1f  grain %.1f  L* %.0f" % (
                        label, view, c["name"], r["square_h"], r["square_v"], r["step"], r["grain"], r["L"])
                tile = Image.new("RGB", (crop.width, crop.height + 20), (24, 24, 24))
                tile.paste(crop, (0, 20))
                ImageDraw.Draw(tile).text((4, 3), txt, fill=(235, 235, 235), font=font)
                tiles.append(tile)
            row = Image.new("RGB", (sum(t.width for t in tiles) + 8 * (len(tiles) - 1), max(t.height for t in tiles)),
                    (24, 24, 24))
            x = 0
            for t in tiles:
                row.paste(t, (x, 0))
                x += t.width + 8
            rows.append(row)
    if not rows:
        print("no renders for the spec's views in", d)
        return
    W = max(r.width for r in rows)
    H = sum(r.height for r in rows) + 6 * len(rows)
    s = Image.new("RGB", (W, H), (24, 24, 24))
    y = 0
    for r in rows:
        s.paste(r, (0, y))
        y += r.height + 6
    s.save(out)
    print("wrote", out, s.size)


def targets(d: str, out_dir: str, targets_of: dict, before: str = None) -> None:
    font = _font(18)
    os.makedirs(out_dir, exist_ok=True)
    for view, target in targets_of.items():
        p = os.path.join(d, view + ".png")
        if not os.path.exists(p):
            continue
        panels = [("target", Image.open(os.path.join(ROOT, target)).convert("RGB"))]
        if before and os.path.exists(os.path.join(before, view + ".png")):
            panels.append(("before", Image.open(os.path.join(before, view + ".png")).convert("RGB")))
        panels.append(("now", Image.open(p).convert("RGB")))
        h = 720
        panels = [(n, im.resize((im.width * h // im.height, h), Image.LANCZOS)) for n, im in panels]
        W = sum(im.width for _, im in panels) + 8 * (len(panels) - 1)
        sheet = Image.new("RGB", (W, h + 28), (20, 20, 20))
        x = 0
        for n, im in panels:
            sheet.paste(im, (x, 28))
            ImageDraw.Draw(sheet).text((x + 6, 4), "%s  %s" % (n, view if n != "target" else os.path.basename(target)),
                    fill=(235, 235, 235), font=font)
            x += im.width + 8
        out = os.path.join(out_dir, view + ".jpg")
        sheet.save(out, quality=88)
        print("wrote", out, sheet.size)


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    spec = load_spec(opts.get("spec", SPEC))
    with open(opts.get("spec", SPEC)) as f:
        targets_of = json.load(f).get("targets", {})
    if not args:
        print(__doc__)
        sys.exit(2)
    if args[0] == "measure":
        m = measure(args[1], spec)
        print(table(m))
        if "json" in opts:
            with open(opts["json"], "w") as f:
                json.dump(m, f, indent=1)
    elif args[0] == "targets":
        targets(args[1], args[2], targets_of, opts.get("before"))
    elif args[0] == "sheet":
        sheet(args[1], args[2], spec, opts.get("before"))
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
