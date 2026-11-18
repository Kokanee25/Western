"""Gold-leaf lettering for a shop's show windows (#1074, Sean's pick on #1067: "A. P. HOLLIS",
"DRY GOODS · GROCERIES · HARDWARE" smaller under it).

A sign-writer gilded on the inside of the glass: the letters laid in leaf, burnished (bright, a
little uneven where the leaf was laid in squares), outlined in black and given a dark drop shade
down and right, so they read against the dark shop behind. Set here in a bold serif (DejaVu Serif
Bold, the font letter_sign.py uses; its licence lets its glyphs be drawn into an image) rather than
painted by the image model, so the name is spelt exactly. Period practice from the sign-writers'
manuals (Atkinson, "Sign Painting", 1909: gilding on glass, outline and shade, "matt and burnish").

    python3 tools/textures/gold_leaf.py [--sheet]

Writes assets/textures/gilt_<id>.png (RGBA: the gold, the outline and shade; alpha where there's no
paint), TEXELS a metre, and its size in metres to assets/textures/textures.json (kind `gilt`).
Storefront.gilt lays it on a show window's panes from the spec's `gilt` block.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures"
INDEX = OUT / "textures.json"
SHEET = ROOT / "docs/screenshots/textures/gold_leaf.png"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
TEXELS = 256  # a metre: a 0.24 m capital is ~60 texels, the small line's ~20

# id: lines (text, cap height in metres), the gap between them (metres), letter spacing (a share of the cap).
GILT = {
    "hollis": {"lines": [["A. P. HOLLIS", 0.24], ["DRY GOODS · GROCERIES · HARDWARE", 0.075]],
               "gap": 0.07, "track": [0.06, 0.12]},
}
GOLD_HI = np.array([250, 222, 140], float)
GOLD = np.array([212, 166, 64], float)
GOLD_LO = np.array([140, 96, 30], float)
INK = np.array([22, 16, 12], float)


def line_mask(text: str, cap_px: int, track: float) -> np.ndarray:
    """The line's letters as a mask, its capitals `cap_px` tall (the font's cap height measured on 'H')."""
    size = 400
    font = ImageFont.truetype(FONT, size)
    hb = font.getbbox("H")
    scale = cap_px / float(hb[3] - hb[1])
    font = ImageFont.truetype(FONT, max(int(round(size * scale)), 6))
    hb = font.getbbox("H")
    t = int(round(cap_px * track))
    w = sum(int(font.getlength(c)) + t for c in text) + cap_px
    img = Image.new("L", (w, cap_px * 2), 0)
    d = ImageDraw.Draw(img)
    x = cap_px // 2
    for c in text:
        d.text((x, cap_px // 2 - hb[1]), c, font=font, fill=255)
        x += int(font.getlength(c)) + t
    a = np.asarray(img)
    ys, xs = np.nonzero(a > 0)
    return a[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def gilt(spec: dict, seed: int = 7) -> Image.Image:
    """The letters, centred line under line: gold over a black outline over a drop shade."""
    masks = [line_mask(t, int(round(cap * TEXELS)), spec["track"][i]) for i, (t, cap) in enumerate(spec["lines"])]
    caps = [int(round(cap * TEXELS)) for _, cap in spec["lines"]]
    gap = int(round(spec["gap"] * TEXELS))
    pad = 12
    W = max(m.shape[1] for m in masks) + pad * 2
    H = sum(m.shape[0] for m in masks) + gap * (len(masks) - 1) + pad * 2
    gold = np.zeros((H, W), float)
    y = pad
    for m in masks:
        x = (W - m.shape[1]) // 2
        gold[y:y + m.shape[0], x:x + m.shape[1]] = np.maximum(gold[y:y + m.shape[0], x:x + m.shape[1]], m / 255.0)
        y += m.shape[0] + gap
    g_img = Image.fromarray((gold * 255).astype(np.uint8))
    # The outline (a fifteenth of the big capital, at least 2 texels) and the shade (down and right).
    ow = max(2, caps[0] // 15)
    outline = np.asarray(g_img.filter(ImageFilter.MaxFilter(ow * 2 + 1))) / 255.0
    sh = max(2, caps[0] // 10)
    shade = np.zeros_like(outline)
    shade[sh:, sh:] = outline[:-sh, :-sh]
    rng = np.random.default_rng(seed)
    # The leaf: lit from above (bright at the top of each line, deeper under), laid in squares a
    # little different from each other, and a fine burnish streak.
    rows = np.linspace(0.0, 1.0, H)[:, None]
    yy = np.zeros((H, 1))
    y = pad
    for m in masks:
        yy[y:y + m.shape[0], 0] = np.linspace(0.0, 1.0, m.shape[0])
        y += m.shape[0] + gap
    t = np.clip(yy * 1.2 - 0.1, 0, 1)
    col = np.where(t[..., None] < 0.45, GOLD_HI + (GOLD - GOLD_HI) * (t[..., None] / 0.45),
                   GOLD + (GOLD_LO - GOLD) * ((t[..., None] - 0.45) / 0.55))
    sq = max(8, caps[0] // 4)
    squares = rng.normal(1.0, 0.06, (H // sq + 1, W // sq + 1))
    squares = np.kron(squares, np.ones((sq, sq)))[:H, :W]
    streak = 1.0 + 0.08 * np.sin(np.arange(W)[None, :] * 0.21 + rows * 9.0)
    col = np.broadcast_to(col, (H, W, 3)) * (squares * streak)[..., None]
    rgb = np.zeros((H, W, 3))
    a = np.maximum(np.maximum(shade * 0.92, outline), gold)
    rgb[:] = INK * 1.6  # the shade a little warmer than the outline
    rgb = np.where(outline[..., None] > 0.5, INK, rgb)
    rgb = np.where(gold[..., None] > 0.5, col, rgb)
    out = np.dstack([np.clip(rgb, 0, 255), a * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args()
    index = json.loads(INDEX.read_text())
    for gid, spec in GILT.items():
        img = gilt(spec)
        name = "gilt_" + gid
        img.save(OUT / (name + ".png"))
        index[name] = {"kind": "gilt", "metres": [round(img.width / TEXELS, 3), round(img.height / TEXELS, 3)],
                       "texels": [img.width, img.height], "strips": 0, "palette": []}
        print("wrote %s.png %dx%d (%.2f x %.2f m)" % (name, img.width, img.height, img.width / TEXELS, img.height / TEXELS))
        if args.sheet:
            SHEET.parent.mkdir(parents=True, exist_ok=True)
            bg = Image.new("RGBA", img.size, (48, 40, 34, 255))
            bg.alpha_composite(img)
            bg.convert("RGB").save(SHEET)
    INDEX.write_text(json.dumps(index, indent=1) + "\n")


if __name__ == "__main__":
    main()
