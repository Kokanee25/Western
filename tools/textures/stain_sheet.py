#!/usr/bin/env python3
"""The weathering layer's stain sheet (material lab round 3, Sean 2026-10-21; docs/briefs/material-lab.md):
four masks in one seamless RGBA tile that texel_grid.gdshaderinc (`weathered`) lays in a structure's
own space with one fetch: R mud splash, G rain streaks, B grime, A sun-bleach. Masks, not colour: the
colours are the set's palette (material_lab.json "weathering"), the same for every wood. Each mask is
rank-evened to 0-1, so the shader's reach for a stain is about the share of the wall it covers.

    python3 tools/textures/stain_sheet.py --procedural --out=assets/textures/weather/stains_free.png
    python3 tools/textures/stain_sheet.py --from=assets/textures/raw/stains_NAME.jpg --out=...
    OPENROUTER_API_KEY=... python3 tools/textures/stain_sheet.py --paint=assets/textures/raw/stains_NAME.jpg

--procedural (no call): the free stand-in, soft shapes from filtered noise.
--from: a painting of four panels in a 2 x 2 grid (top left mud splash, top right rain streaks,
bottom left grime, bottom right bleach, each on a plain grey ground; STAIN_ASK), each panel's stain
taken as its distance from the panel's own ground colour, made seamless and evened.
--paint: that painting asked of the image model with the men's sheet as the style (one call,
~$0.22; on Actions: People workflow, textures = mlab:NAME for a set with "stains"). Also a
--sheet=PNG preview of the four masks side by side.
"""
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

SIZE = 512
STAIN_ASK = (
    "The image shows a game's characters, painted. In exactly their painted hand, paint a sheet of four "
    "square panels in a two by two grid, each panel a plain, flat, even mid grey with nothing else on it: "
    "no wood, no boards, no wall, no objects, no lettering, no frame. Top left: mud splashed up from the "
    "ground, big soft earthy brown splash shapes, joined and heaviest along the bottom edge, broken and "
    "fewer higher up, none in the top third. Top right: rain streaks, long soft grey-brown runs hanging "
    "straight down from the top edge, some long, some short, of different widths. Bottom left: grime, "
    "big soft dark brown smudges and patches of different sizes scattered over the panel. Bottom right: "
    "sun bleaching, big soft pale grey patches scattered over the panel. Every stain painted as broad, "
    "soft shapes of two or three close tones with clean edges between them, like the dirt and wear on "
    "the characters' clothes: no specks, no spatter, no dots, no drips of single lines, no fine "
    "texture, nothing photographic. Flat, even light, seen face on."
)


def periodic_noise(rng, size, sx, sy, octaves=((1.0, 1.0),)):
    """Seamless smooth noise (white noise low-passed in the frequency domain, so it tiles), shapes
    about sx by sy pixels; a sum of octaves [(scale, weight)]."""
    fy = np.fft.fftfreq(size)[:, None]
    fx = np.fft.fftfreq(size)[None, :]
    out = np.zeros((size, size))
    for scale, weight in octaves:
        w = np.fft.fft2(rng.standard_normal((size, size)))
        g = np.exp(-((fx * sx * scale) ** 2 + (fy * sy * scale) ** 2) * 2.0)
        n = np.real(np.fft.ifft2(w * g))
        out += weight * n / max(n.std(), 1e-9)
    return out


def even(a):
    """Rank-evened to 0-1: the share of the tile under a value is that value; ties (a panel's bare
    ground) share one rank, so bare ground stays one flat value, never a ramp."""
    from scipy.stats import rankdata
    r = rankdata(a.ravel(), method="average")
    return ((r - r.min()) / max(r.max() - r.min(), 1e-9)).reshape(a.shape)


def soft_round(a, px):
    """Blurred with wrap-around (seamless), px pixels."""
    from scipy.ndimage import gaussian_filter
    return gaussian_filter(a.astype(np.float64), px, mode="wrap")


def procedural(seed=7, size=SIZE):
    """The free stand-in: the four masks from noise, shaped as the stains are (3 m a side at the
    shader's default weather_metres: a pixel ~6 mm)."""
    rng = np.random.default_rng(seed)
    # Mud: blobs five to twenty centimetres, clumped (a coarse field under a finer one).
    mud = periodic_noise(rng, size, 22, 16, ((1.0, 1.0), (2.0, 0.5))) + 0.9 * periodic_noise(rng, size, 60, 40)
    # Streaks: narrow across (3-8 cm), long down (50-90 cm).
    streaks = periodic_noise(rng, size, 9, 110, ((1.0, 1.0), (1.8, 0.4)))
    # Grime: soft patches 20-60 cm.
    grime = periodic_noise(rng, size, 45, 35, ((1.0, 1.0), (2.2, 0.4)))
    # Bleach: broad, longer than high (the grain and the boards' run), 40 cm - 1 m.
    bleach = periodic_noise(rng, size, 90, 45, ((1.0, 1.0), (2.0, 0.35)))
    return np.stack([even(soft_round(m, 1.5)) for m in (mud, streaks, grime, bleach)], axis=-1)


def from_painting(path, size=SIZE):
    """The four masks from a painted 2 x 2 sheet (STAIN_ASK): each panel's stain = its distance from
    the panel's ground colour in L*a*b*, the panel's border trimmed, made seamless, evened."""
    import reduce  # noqa: E402 (its Lab conversions)
    im = np.asarray(Image.open(path).convert("RGB"))
    h, w = im.shape[:2]
    out = []
    for i, (r, c) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
        m = 0.06
        y0, y1 = int(h * (r * 0.5 + m * 0.5)), int(h * ((r + 1) * 0.5 - m * 0.5))
        x0, x1 = int(w * (c * 0.5 + m * 0.5)), int(w * ((c + 1) * 0.5 - m * 0.5))
        lab = reduce.to_lab(im[y0:y1, x0:x1])
        ground = np.median(lab.reshape(-1, 3), axis=0)
        d = np.sqrt(((lab - ground) ** 2).sum(axis=-1))
        if i == 3:
            # Bleach: only what's lighter than the ground.
            d = d * (lab[..., 0] > ground[0])
        else:
            d = d * (lab[..., 0] < ground[0] + 4.0)
        # The painting's grain and JPEG noise on the bare ground left out: softened, then a dead
        # zone above the ground's own spread, so bare ground is exactly bare.
        d = soft_round(d, 1.5)
        d = np.maximum(d - (np.percentile(d, 50) + 3.0), 0.0)
        a = np.asarray(Image.fromarray(d.astype(np.float32), mode="F").resize((size, size), Image.BILINEAR))
        a = np.round(soft_round(seamless(a), 1.0), 3)
        out.append(even(a))
    return np.stack(out, axis=-1)


def seamless(a):
    """A panel made to tile: blended with itself rolled half a tile (whose edges are the panel's own
    middle, so they wrap), the panel kept in the middle, the rolled copy at the edges."""
    n, m = a.shape
    b = np.roll(a, (n // 2, m // 2), axis=(0, 1))
    wy = np.sin(np.linspace(0.0, np.pi, n))[:, None]
    wx = np.sin(np.linspace(0.0, np.pi, m))[None, :]
    w = np.clip(np.minimum(wy, wx) * 1.6, 0.0, 1.0)
    return a * w + b * (1.0 - w)


def save(masks, out):
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    Image.fromarray(np.clip(masks * 255.0 + 0.5, 0, 255).astype(np.uint8), "RGBA").save(out)
    print("stains: %s (%dx%d)" % (out, masks.shape[1], masks.shape[0]))


def preview(masks, out):
    """The four masks side by side, each as dark stain on a pale ground."""
    h, w = masks.shape[:2]
    tiles = [Image.fromarray(((1.0 - masks[..., i]) * 255).astype(np.uint8)).convert("RGB") for i in range(4)]
    sheet = Image.new("RGB", (w * 4 + 12, h), (255, 255, 255))
    for i, t in enumerate(tiles):
        sheet.paste(t, (i * (w + 4), 0))
    sheet.save(out)


def paint(out, key):
    """One call: the four-panel stain painting, in the men's hand."""
    import paint_textures as pt
    man = Image.open(pt.MAN).convert("RGB")
    man.thumbnail((768, 768))
    img = pt.ask(STAIN_ASK, [man], {"aspect_ratio": "1:1"}, "stains", key)
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    img.convert("RGB").save(out, "JPEG", quality=94)
    print("painted: %s %s" % (out, img.size))
    return pt.SPENT


def main():
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "") for a in sys.argv[1:] if a.startswith("--"))
    if "paint" in args:
        key = os.environ.get("OPENROUTER_API_KEY", "")
        if not key:
            print("No OPENROUTER_API_KEY: stains not painted.")
            sys.exit(1)
        paint(args["paint"], key)
        return
    if "procedural" in args:
        masks = procedural(int(args.get("seed", "7") or 7))
    elif "from" in args:
        masks = from_painting(args["from"])
    else:
        print(__doc__)
        sys.exit(1)
    save(masks, args.get("out", "assets/textures/weather/stains.png"))
    if args.get("sheet"):
        preview(masks, args["sheet"])


if __name__ == "__main__":
    main()
