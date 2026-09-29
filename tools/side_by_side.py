#!/usr/bin/env python3
"""Put a render next to the concept painting at the same size, for judging a shot match.

    python3 tools/side_by_side.py render.png [docs/concept/saloon-night.png] [out.png]

Both are scaled to 960x540 (the render with nearest-neighbour, so its pixels stay pixels), render
on the left, painting on the right, a thin gap between, labels underneath.
"""
import sys
from PIL import Image, ImageDraw

W, H, GAP, FOOT = 960, 540, 8, 28


def main() -> None:
    render = sys.argv[1]
    concept = sys.argv[2] if len(sys.argv) > 2 else "docs/concept/saloon-night.png"
    out = sys.argv[3] if len(sys.argv) > 3 else render.replace(".png", "_vs_concept.png")
    a = Image.open(render).convert("RGB").resize((W, H), Image.NEAREST)
    b = Image.open(concept).convert("RGB").resize((W, H), Image.LANCZOS)
    img = Image.new("RGB", (W * 2 + GAP, H + FOOT), (16, 12, 10))
    img.paste(a, (0, 0))
    img.paste(b, (W + GAP, 0))
    d = ImageDraw.Draw(img)
    d.text((10, H + 7), "game (render)", fill=(220, 200, 170))
    d.text((W + GAP + 10, H + 7), "concept painting", fill=(220, 200, 170))
    img.save(out)
    print(out)


if __name__ == "__main__":
    main()
