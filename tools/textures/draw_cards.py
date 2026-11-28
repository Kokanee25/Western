"""The card table's deck and chips, drawn in code (#1294: the real card game). One atlas, eight cards
across and seven down: the 52 faces (index `suit * 13 + rank`, as Poker counts them: spades, hearts,
diamonds, clubs; two .. ace), the back at 52, and the chip's clay face and edge in chips.png.

What a deck of 1882 looked like (the sources, read 2026-11-27):
- The World of Playing Cards, USPCC "Squared Faro #366" (wopc.co.uk/usa/uspcc/squared-faro-366): first
  issued 1887, square corners and no indices, one of two known USPC packs without them, made for faro
  dealers who kept to the old cards.
- WOPC, Russell, Morgan & Co. "Tigers No.101" (wopc.co.uk/usa/uspcc/tigers-101.html): the firm (later
  USPCC) began making cards in 1881, six grades with American names.
- WOPC, Andrew Dougherty "Ivorette" (wopc.co.uk/usa/dougherty/ivorette) and "Squeezers"
  (wopc.co.uk/usa/squeezers): corner indices ("squeezers", so a hand can be fanned tight) were on the
  market by 1877 and patented variants followed in 1883; rounded corners came in the same years.
- The collectors' history of indices (collectorsplayingcards.blogspot.com, 2012-07, "Have there always
  been numbers on playing cards?"): the change from square, unindexed cards to rounded, indexed ones is
  the 1880s.
So a saloon's deck in 1882 is likely an older, cheaper pack: square corners, no indices (you read a card
by its pips and its court), double-ended courts (standard in America since the 1860s-70s), a plain back
in one colour. That's this deck. Nothing here is copied from a scan: the pips are drawn shapes and the
courts are our own blocky figures (crown, coronet, cap), in the game's painted-block manner.

    assets/textures/cards/deck.png   120 x 168 a card (63 x 88 mm), 8 x 7 cards
    assets/textures/cards/chips.png  64 x 64 the chip's face (left) and its edge (right), 128 x 64

    python3 tools/textures/draw_cards.py [--sheet]
"""
import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/textures/cards"
SHEET = ROOT / "docs/screenshots/textures/cards_sheet.png"

W, H = 120, 168  # a card, in the atlas
SS = 4  # drawn this many times larger, then reduced
COLS, ROWS = 8, 7
PAPER = (232, 225, 204)
INK = (28, 24, 22)
RED = (162, 34, 28)
BACK = (118, 30, 26)
GOLD = (200, 158, 60)
BLUE = (44, 62, 112)
FLESH = (226, 186, 150)
RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

# Pip places on the card (x, y as shares of the card), the standard layouts; a pip below the middle
# is drawn turned over, as on a real card.
L, M, R = 0.3, 0.5, 0.7
T, B = 0.17, 0.83
PIPS = {
    2: [(M, T), (M, B)],
    3: [(M, T), (M, 0.5), (M, B)],
    4: [(L, T), (R, T), (L, B), (R, B)],
    5: [(L, T), (R, T), (M, 0.5), (L, B), (R, B)],
    6: [(L, T), (R, T), (L, 0.5), (R, 0.5), (L, B), (R, B)],
    7: [(L, T), (R, T), (M, 0.335), (L, 0.5), (R, 0.5), (L, B), (R, B)],
    8: [(L, T), (R, T), (M, 0.335), (L, 0.5), (R, 0.5), (M, 0.665), (L, B), (R, B)],
    9: [(L, T), (R, T), (L, 0.39), (R, 0.39), (M, 0.5), (L, 0.61), (R, 0.61), (L, B), (R, B)],
    10: [(L, T), (R, T), (M, 0.28), (L, 0.39), (R, 0.39), (L, 0.61), (R, 0.61), (M, 0.72), (L, B), (R, B)],
}


def pip(d: ImageDraw.ImageDraw, suit: int, cx: float, cy: float, size: float, colour, flip=False):
    """A suit's pip, `size` its height (pixels, drawn scale), centred at (cx, cy)."""
    s = size / 2.0
    sign = -1.0 if flip else 1.0

    def P(x, y):  # a point in pip space (-1..1, up is -y), turned over when `flip`
        return (cx + x * s * sign, cy + y * s * sign)

    if suit == 2:  # diamond
        d.polygon([P(0, -1), P(0.72, 0), P(0, 1), P(-0.72, 0)], fill=colour)
    elif suit == 1:  # heart: two lobes and a point
        for lx in (-0.42, 0.42):
            x, y = P(lx, -0.38)
            r = 0.5 * s
            d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
        d.polygon([P(-0.9, -0.22), P(0.9, -0.22), P(0, 0.95)], fill=colour)
    elif suit == 0:  # spade: a heart turned over, and a stem
        for lx in (-0.42, 0.42):
            x, y = P(lx, 0.22)
            r = 0.48 * s
            d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
        d.polygon([P(-0.88, 0.08), P(0.88, 0.08), P(0, -1.0)], fill=colour)
        d.polygon([P(0, 0.35), P(0.34, 1.0), P(-0.34, 1.0)], fill=colour)
    else:  # club: three balls and a stem
        for bx, by in ((0, -0.5), (-0.5, 0.12), (0.5, 0.12)):
            x, y = P(bx, by)
            r = 0.4 * s
            d.ellipse([x - r, y - r, x + r, y + r], fill=colour)
        d.polygon([P(0, 0.1), P(0.32, 1.0), P(-0.32, 1.0)], fill=colour)


def blank() -> Image.Image:
    im = Image.new("RGB", (W * SS, H * SS), PAPER)
    d = ImageDraw.Draw(im)
    # A faint tooth to the board: fine dots, one tone off (seeded by position: the same every run).
    for k in range(0, W * SS * H * SS // 700):
        x = (k * 7919) % (W * SS)
        y = (k * 104729 // (W * SS) * 13 + k * 31) % (H * SS)
        d.point((x, y), fill=(222, 214, 192))
    return im


def court(suit: int, rank: int) -> Image.Image:
    """J, Q, K: a frame, and in it the figure from the waist up, mirrored head to foot (double-ended);
    told apart by the headgear (cap and feather, coronet, crown), the K's beard, and the suit's pip
    by each head."""
    im = blank()
    d = ImageDraw.Draw(im)
    colour = RED if suit in (1, 2) else INK
    fx0, fy0, fx1, fy1 = 0.14 * W * SS, 0.09 * H * SS, 0.86 * W * SS, 0.91 * H * SS
    half = Image.new("RGBA", (int(fx1 - fx0), int((fy1 - fy0) / 2)), (0, 0, 0, 0))
    h = ImageDraw.Draw(half)
    hw, hh = half.size
    robe = [RED, BLUE, GOLD][(suit + rank) % 3]
    trim = [GOLD, RED, BLUE][(suit + rank) % 3]
    # Shoulders and robe.
    h.polygon([(hw * 0.08, hh), (hw * 0.18, hh * 0.62), (hw * 0.82, hh * 0.62), (hw * 0.92, hh)], fill=robe)
    h.rectangle([hw * 0.44, hh * 0.62, hw * 0.56, hh], fill=trim)
    h.line([(hw * 0.18, hh * 0.62), (hw * 0.82, hh * 0.62)], fill=INK, width=SS * 2)
    # The head.
    hx, hy, hr = hw * 0.5, hh * 0.45, hw * 0.17
    h.ellipse([hx - hr, hy - hr, hx + hr, hy + hr * 1.1], fill=FLESH, outline=INK, width=SS * 2)
    h.rectangle([hx - hr * 0.5, hy - hr * 0.1, hx - hr * 0.2, hy + hr * 0.05], fill=INK)  # eyes
    h.rectangle([hx + hr * 0.2, hy - hr * 0.1, hx + hr * 0.5, hy + hr * 0.05], fill=INK)
    if rank == 11:  # the king: a grey beard and a pointed crown
        h.polygon([(hx - hr, hy + hr * 0.3), (hx + hr, hy + hr * 0.3), (hx, hy + hr * 1.6)], fill=(190, 186, 178), outline=INK)
        pts = [(hx - hr * 1.05, hy - hr * 0.7)]
        for k in range(5):
            x = hx - hr * 1.05 + k * hr * 0.525
            pts += [(x + hr * 0.26, hy - hr * 1.9), (x + hr * 0.525, hy - hr * 0.95)]
        pts += [(hx + hr * 1.05, hy - hr * 0.7)]
        h.polygon(pts, fill=GOLD, outline=INK)
    elif rank == 10:  # the queen: a veil down her shoulders and a low coronet with a flower
        h.polygon([(hx - hr * 1.2, hy - hr * 0.6), (hx + hr * 1.2, hy - hr * 0.6), (hx + hr * 1.6, hh * 0.7), (hx - hr * 1.6, hh * 0.7)], fill=trim)
        h.ellipse([hx - hr, hy - hr, hx + hr, hy + hr * 1.1], fill=FLESH, outline=INK, width=SS * 2)
        h.rectangle([hx - hr * 0.5, hy - hr * 0.1, hx - hr * 0.2, hy + hr * 0.05], fill=INK)
        h.rectangle([hx + hr * 0.2, hy - hr * 0.1, hx + hr * 0.5, hy + hr * 0.05], fill=INK)
        h.rectangle([hx - hr * 0.95, hy - hr * 1.25, hx + hr * 0.95, hy - hr * 0.75], fill=GOLD, outline=INK)
        h.ellipse([hx - hr * 0.3, hy - hr * 1.75, hx + hr * 0.3, hy - hr * 1.15], fill=RED, outline=INK)
    else:  # the jack: a flat cap and a feather, and long hair
        h.rectangle([hx - hr * 1.15, hy - hr * 0.2, hx - hr * 0.85, hy + hr * 1.0], fill=(120, 80, 40))
        h.rectangle([hx + hr * 0.85, hy - hr * 0.2, hx + hr * 1.15, hy + hr * 1.0], fill=(120, 80, 40))
        h.polygon([(hx - hr * 1.3, hy - hr * 0.6), (hx + hr * 1.3, hy - hr * 0.6), (hx + hr * 0.9, hy - hr * 1.3), (hx - hr * 0.9, hy - hr * 1.3)], fill=robe, outline=INK)
        h.polygon([(hx + hr * 0.6, hy - hr * 1.2), (hx + hr * 1.7, hy - hr * 2.2), (hx + hr * 1.0, hy - hr * 1.0)], fill=(236, 232, 220), outline=INK)
    # The suit's pip by his head (where the old courts carry it), both halves.
    pip(h, suit, hw * 0.16, hh * 0.2, hh * 0.2, colour)
    top = half
    bottom = half.rotate(180)
    im.paste(top, (int(fx0), int(fy0)), top)
    im.paste(bottom, (int(fx0), int(fy0 + hh)), bottom)
    d.rectangle([fx0, fy0, fx1, fy1], outline=INK, width=SS * 2)
    d.line([(fx0, fy0 + hh), (fx1, fy0 + hh)], fill=INK, width=SS)
    return im


def face(suit: int, rank: int) -> Image.Image:
    if rank in (9, 10, 11):
        return court(suit, rank)
    im = blank()
    d = ImageDraw.Draw(im)
    colour = RED if suit in (1, 2) else INK
    if rank == 12:
        big = H * SS * (0.42 if suit == 0 else 0.3)
        if suit == 0:  # the ace of spades, the maker's card: the big spade in a ring of leaves
            cx, cy, r = W * SS / 2, H * SS / 2, W * SS * 0.42
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=INK, width=SS * 2)
            for k in range(16):
                a = k * math.tau / 16
                x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
                d.ellipse([x - SS * 4, y - SS * 4, x + SS * 4, y + SS * 4], fill=INK)
        pip(d, suit, W * SS / 2, H * SS / 2, big, colour)
        return im
    n = rank + 2
    size = H * SS * (0.15 if n <= 6 else 0.13)
    for x, y in PIPS[n]:
        pip(d, suit, x * W * SS, y * H * SS, size, colour, flip=y > 0.55)
    return im


def back() -> Image.Image:
    """Plain: one deep red, a fine lattice a shade off it and a thin paper margin (square corners)."""
    im = Image.new("RGB", (W * SS, H * SS), PAPER)
    d = ImageDraw.Draw(im)
    m = 6 * SS
    d.rectangle([m, m, W * SS - m, H * SS - m], fill=BACK)
    step = 7 * SS
    shade = (104, 26, 22)
    for k in range(-H * SS, W * SS + H * SS, step):
        d.line([(k, m), (k + H * SS, m + H * SS)], fill=shade, width=SS)
        d.line([(k, m), (k - H * SS, m + H * SS)], fill=shade, width=SS)
    d.rectangle([0, 0, W * SS, m], fill=PAPER)
    d.rectangle([0, H * SS - m, W * SS, H * SS], fill=PAPER)
    d.rectangle([0, 0, m, H * SS], fill=PAPER)
    d.rectangle([W * SS - m, 0, W * SS, H * SS], fill=PAPER)
    return im


def chips() -> Image.Image:
    """The chip's clay, in greys the table's colour multiplies: the face (left) an embossed ring and
    a star of dots, the edge (right) four light inlay spots round it."""
    s = 64 * SS
    im = Image.new("RGB", (s * 2, s), (215, 215, 215))
    d = ImageDraw.Draw(im)
    c = s / 2
    d.ellipse([c - s * 0.36, c - s * 0.36, c + s * 0.36, c + s * 0.36], outline=(170, 170, 170), width=SS * 3)
    for k in range(8):
        a = k * math.tau / 8
        x, y = c + math.cos(a) * s * 0.2, c + math.sin(a) * s * 0.2
        d.ellipse([x - SS * 3, y - SS * 3, x + SS * 3, y + SS * 3], fill=(240, 240, 240))
    d.ellipse([c - SS * 5, c - SS * 5, c + SS * 5, c + SS * 5], fill=(180, 180, 180))
    # The edge: u round it, v across it; inlaid spots, a quarter round apart.
    for k in range(4):
        x = s + (k + 0.5) * s / 4
        d.rectangle([x - s * 0.04, s * 0.15, x + s * 0.04, s * 0.85], fill=(250, 250, 250))
    return im.resize((128, 64), Image.LANCZOS)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true", help="also a contact sheet in docs/screenshots/textures")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    atlas = Image.new("RGB", (W * COLS, H * ROWS), PAPER)
    cards = [face(c // 13, c % 13) for c in range(52)] + [back()]
    for i, im in enumerate(cards):
        im = im.filter(ImageFilter.GaussianBlur(SS * 0.25)).resize((W, H), Image.LANCZOS)
        atlas.paste(im, ((i % COLS) * W, (i // COLS) * H))
    atlas.save(OUT / "deck.png", optimize=True)
    chips().save(OUT / "chips.png", optimize=True)
    print("wrote", OUT / "deck.png", OUT / "chips.png")
    if a.sheet:
        SHEET.parent.mkdir(parents=True, exist_ok=True)
        atlas.resize((W * COLS // 2, H * ROWS // 2), Image.LANCZOS).save(SHEET, optimize=True)
        print("wrote", SHEET)


if __name__ == "__main__":
    main()
