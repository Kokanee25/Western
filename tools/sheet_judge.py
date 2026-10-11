#!/usr/bin/env python3
"""The character-sheet trial's judge: a man standing in the lineup (tools/people_lineup.gd
--sheet-style, his front view) against the front view of the turnaround in
docs/concept/style_candidates/character_sheet.png, by tools/characters/judge_man.py's measures
(light, colour, squares; the characters session's judge, its regions moved onto a standing man).

    python3 tools/sheet_judge.py OURS.png [OURS2.png ...] [--names=a,b] [--out=DIR]
    python3 tools/sheet_judge.py --head HEAD_FRONT.png [...] [--names=a,b]

Both men are cut out from their plain backgrounds (the sheet's is dark grey, ours flat), scaled to
the sheet's man's height (ours area-averaged down, as a render at that size would be), and set at
the same place on a 1280x720 frame. His hat, face and coat (here his torso: the sheet's man wears a
vest) are bands of his height. Writes DIR/sheet_judge.png (the men side by side at 2x and each one's
top differences) and DIR/sheet_judge.json; prints each score (lower is closer).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "tools", "characters"))
import judge  # noqa: E402
import judge_man as jm  # noqa: E402

SHEET = os.path.join(ROOT, "docs", "concept", "style_candidates", "character_sheet.png")
# The turnaround's front view in the sheet (its own pixels).
FRONT = (455, 0, 700, 420)
W, H = jm.W, jm.H
# Where the man stands on the frame: his top-left corner.
AT = (560, 150)
# Bands of his height (from the top of his hat): hat, face, torso.
BANDS = {"hat": (0.0, 0.085), "face": (0.085, 0.165), "coat": (0.19, 0.52)}


def cut_out(img: Image.Image, tol: float = 14.0) -> tuple:
    """The man in `img` (on a plain background) and his mask, cropped to him."""
    a = np.asarray(img.convert("RGB")).astype(np.float64)
    edge = np.concatenate([a[:12].reshape(-1, 3), a[:, :8].reshape(-1, 3), a[:, -8:].reshape(-1, 3)])
    bg = np.median(edge, axis=0)
    m = np.linalg.norm(a - bg, axis=-1) > tol
    m = ndimage.binary_opening(m, iterations=1)
    lab, n = ndimage.label(m)
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = np.isin(lab, 1 + np.nonzero(sizes > 0.02 * sizes.max())[0])
    m = ndimage.binary_fill_holes(keep)
    ys, xs = np.nonzero(m)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    return img.convert("RGB").crop(box), Image.fromarray((m * 255).astype(np.uint8)).crop(box)


def on_frame(man: Image.Image, mask: Image.Image, height: int) -> tuple:
    s = height / man.height
    size = (max(int(round(man.width * s)), 1), height)
    man = man.resize(size, Image.LANCZOS if s < 1 else Image.BICUBIC)
    mask = mask.resize(size, Image.BILINEAR)
    frame = Image.new("RGB", (W, H), (36, 34, 35))
    frame.paste(man, (AT[0] + (170 - size[0]) // 2, AT[1]))
    fm = Image.new("L", (W, H), 0)
    fm.paste(mask, (AT[0] + (170 - size[0]) // 2, AT[1]))
    return frame, np.asarray(fm) > 127


def regions(mask: np.ndarray) -> dict:
    ys, xs = np.nonzero(mask)
    y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    h = y1 - y0
    return {k: (x0, int(y0 + a * h), x1, int(y0 + b * h)) for k, (a, b) in BANDS.items()}


# --head: his face, brows to chin, in the sheet's head close-up and in people_lineup.gd --head's
# front view (both ~0.8 mm a pixel: eye to eye ~80 px), measured for its squares only.
HEAD_PANEL = (455, 452, 800, 762)
SHEET_FACE = (575, 542, 735, 692)
OUR_FACE = (180, 200, 320, 345)


def head(paths: list, names: list) -> None:
    import judge_man as m
    rows = [("sheet", Image.open(SHEET).convert("RGB").crop(SHEET_FACE))]
    rows += [(n, Image.open(p).convert("RGB").crop(OUR_FACE)) for p, n in zip(paths, names)]
    print("%-16s %6s %6s %6s %6s %6s %6s %6s" % ("face", "L50", "chroma", "tile", "flat", "sqdiff", "hard", "coher"))
    for name, img in rows:
        lab = judge.to_lab(np.asarray(img))
        L = lab[..., 0]
        mask = np.ones(L.shape, dtype=bool)
        inner = ndimage.binary_erosion(mask, iterations=2)
        b1 = ndimage.gaussian_filter(L, 1.0)
        b3 = ndimage.gaussian_filter(L, 3.0)
        b12 = ndimage.gaussian_filter(L, 12.0)
        blurred = np.stack([ndimage.gaussian_filter(lab[..., c], 3.0) for c in range(3)], -1)
        detail = np.linalg.norm(lab - blurred, axis=-1)
        print("%-16s %6.1f %6.1f %6.1f %6.2f %6.1f %6.2f %6.2f" % (
            name, np.median(L), np.hypot(lab[..., 1], lab[..., 2]).mean(), m.masked_tile_size(L, inner),
            m.flatness(L, inner), m.squares_contrast(L, mask, 7.0),
            np.abs(L - b1)[inner].mean() / max(detail[inner].mean(), 1e-6),
            np.corrcoef(np.abs(L - b3)[inner], np.abs(b3 - b12)[inner])[0, 1]))


def main() -> None:
    if "--head" in sys.argv:
        paths = [a for a in sys.argv[1:] if not a.startswith("--")]
        opt = [a for a in sys.argv[1:] if a.startswith("--names=")]
        head(paths, opt[0][8:].split(",") if opt else [os.path.basename(p) for p in paths])
        return
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a.split("=")[0]: a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--") and "=" in a}
    names = opt.get("--names", "").split(",") if "--names" in opt else [os.path.basename(a) for a in args]
    out = opt.get("--out", os.path.join(ROOT, "build", "sheet_style"))
    ref_man, ref_mask = cut_out(Image.open(SHEET).crop(FRONT))
    height = ref_man.height
    p_img, p_mask = on_frame(ref_man, ref_mask, height)
    # judge_man's boxes are in a frame of its own size (PW x PH); here they're the frame's pixels.
    jm.PW, jm.PH = W, H
    jm.REGIONS = regions(p_mask)
    # The sheet's square at this size: ~8 mm on a 1.9 m man.
    jm.SQUARE = max(0.008 / 1.9 * height, 2.0)
    theirs = jm.measure(p_img, p_mask)
    rows, report = [], {"sheet": os.path.relpath(SHEET, ROOT), "height_px": height, "men": {}}
    for path, name in zip(args, names):
        o_man, o_mask = cut_out(Image.open(path))
        o_img, o_mask = on_frame(o_man, o_mask, height)
        ours = jm.measure(o_img, o_mask)
        score, diffs = jm.judge_pair(ours, theirs)
        groups = jm.by_group(diffs)
        print("%s: score %.3f (%s)" % (name, score, ", ".join("%s %.3f" % g for g in groups.items())))
        for sev, words, group in diffs[:6]:
            print("  %.2f  %-7s %s" % (sev, group, words))
        rows.append((name, o_img, o_mask, score, groups, diffs))
        report["men"][name] = {"from": path, "score": score, "groups": groups, "differences": diffs,
                               "ours": jm.plain(ours)}
    report["sheet_man"] = jm.plain(theirs)
    # The picture: the sheet's man and each of ours at 2x, their top differences under them.
    x0, y0 = AT[0] - 20, AT[1] - 10
    box = (x0, y0, x0 + 210, y0 + height + 20)
    cw, ch = 420, (height + 20) * 2
    sheet = Image.new("RGB", ((cw + 10) * (len(rows) + 1), ch + 40 + 20 * 7), (22, 22, 22))
    d = ImageDraw.Draw(sheet)
    def dim(img, mask):
        a = np.asarray(img).astype(np.float64)
        a[~mask] *= 0.35
        return Image.fromarray(a.astype(np.uint8)).crop(box).resize((cw, ch), Image.NEAREST)

    sheet.paste(dim(p_img, p_mask), (0, 40))
    d.text((6, 10), "the sheet", fill=(240, 230, 210), font=judge._font(18))
    for i, (name, img, mask, score, groups, diffs) in enumerate(rows):
        x = (cw + 10) * (i + 1)
        sheet.paste(dim(img, mask), (x, 40))
        d.text((x + 6, 10), "%s: %.3f" % (name, score), fill=(240, 230, 210), font=judge._font(18))
        for j, (sev, words, group) in enumerate(diffs[:7]):
            d.text((x + 4, ch + 46 + 20 * j), "%.2f %s" % (sev, words[:52]), fill=(210, 210, 210), font=judge._font(13, True))
    os.makedirs(out, exist_ok=True)
    sheet.save(os.path.join(out, "sheet_judge.png"))
    json.dump(report, open(os.path.join(out, "sheet_judge.json"), "w"), indent=1)
    print("wrote", os.path.join(out, "sheet_judge.png"))


if __name__ == "__main__":
    main()
