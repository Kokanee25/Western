"""The town's sign painter's alphabet, drawn square by square (Sean, 2026-10-06: the lettering
"jagged", the A's arm "way too thin"). A computer font shrunk to sixteen squares and rounded loses
its thin strokes and steps its diagonals unevenly; the street painting's letters are drawn in
squares by a hand that keeps every stroke the same width. These glyphs are built that way: a
Western slab ("Clarendon", the sign painters' letter) out of a few strokes on the square grid,
every upright STEM squares wide, every bar BAR squares tall, every diagonal the same number of
squares across on every row (so its edge steps evenly), slab serifs SERIF squares deep reaching
REACH squares past the stem, and the rounds a squared ellipse of even thickness.

    from pixel_font import text_mask
    mask = text_mask("JAIL", height=16, track=3)   # bool array, rows x squares

`python3 tools/textures/pixel_font.py --sheet` draws every glyph into
docs/screenshots/textures/pixel_font.png to look at.
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHEET = ROOT / "docs/screenshots/textures/pixel_font.png"

H = 16       # cap height in squares
STEM = 3     # uprights
BAR = 3      # horizontal bars (top and foot of E, the bowls' tops)
MID = 2      # cross bars (E's middle, A's and H's bars)
SERIF = 2    # slab serifs: squares deep
REACH = 2    # squares past the stem either side


# The glyphs are drawn in design squares at H high; a sign of another height draws them at
# K squares a design square (text_mask's `height`), every stroke's width and every edge rounded on
# its own, so a stroke is the same width all along at any height.
K = 1.0


def _sq(v: float) -> int:
    return int(np.floor(v * K + 0.5))


class Glyph:
    def __init__(self, width: int):
        self.w = _sq(width)
        self.h = _sq(H)
        self.m = np.zeros((self.h, self.w), bool)

    def pad(self, extra: int) -> "Glyph":
        self.m = np.pad(self.m, ((0, 0), (0, _sq(extra))))
        self.w = self.m.shape[1]
        return self

    def px(self, x0: int, y0: int, x1: int, y1: int) -> "Glyph":
        """Squares x0..x1, y0..y1 of the sign itself (inclusive), clipped."""
        x0, x1 = max(x0, 0), min(x1, self.w - 1)
        y0, y1 = max(y0, 0), min(y1, self.h - 1)
        if x0 <= x1 and y0 <= y1:
            self.m[y0:y1 + 1, x0:x1 + 1] = True
        return self

    def rect(self, x0: int, y0: int, x1: int, y1: int) -> "Glyph":
        """Design squares x0..x1, y0..y1 (inclusive)."""
        return self.px(_sq(x0), _sq(y0), _sq(x1 + 1) - 1, _sq(y1 + 1) - 1)

    def stem(self, x: int, y0: int = 0, y1: int = H - 1, top: bool = True, foot: bool = True,
             left: bool = True, right: bool = True) -> "Glyph":
        """An upright STEM wide from x, with slab serifs at its ends."""
        self.rect(x, y0, x + STEM - 1, y1)
        a = x - (REACH if left else 0)
        b = x + STEM - 1 + (REACH if right else 0)
        if top:
            self.rect(a, y0, b, y0 + SERIF - 1)
        if foot:
            self.rect(a, y1 - SERIF + 1, b, y1)
        return self

    def diag(self, xa: float, ya: int, xb: float, yb: int, width: int) -> "Glyph":
        """A diagonal from (xa, ya) to (xb, yb), `width` squares across on every row (its left
        edge at the line, rounded the same way each row, so the steps are even)."""
        pya, pyb = _sq(ya), _sq(yb + 1) - 1
        pxa, pxb = xa * K, xb * K
        pw = max(_sq(width), 1)
        for y in range(min(pya, pyb), max(pya, pyb) + 1):
            t = (y - pya) / (pyb - pya) if pyb != pya else 0.0
            x = pxa + (pxb - pxa) * t
            x0 = int(np.floor(x + 0.5))
            self.px(x0, y, x0 + pw - 1, y)
        return self

    def ring(self, x0: int, y0: int, x1: int, y1: int, thick_x: int = STEM, thick_y: int = BAR,
             power: float = 3.0, arc=None) -> "Glyph":
        """A squared ellipse filling x0..x1, y0..y1, thick_x across its sides and thick_y at top
        and bottom; `arc` (a function of (dx, dy) in -1..1 -> bool) keeps part of it."""
        x0, y0, x1, y1 = _sq(x0), _sq(y0), _sq(x1 + 1) - 1, _sq(y1 + 1) - 1
        thick_x, thick_y = max(_sq(thick_x), 1), max(_sq(thick_y), 1)
        cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
        rx, ry = (x1 - x0 + 1) / 2.0, (y1 - y0 + 1) / 2.0
        ix, iy = rx - thick_x, ry - thick_y
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                dx, dy = x - cx, y - cy
                outer = abs(dx / rx) ** power + abs(dy / ry) ** power <= 1.0
                inner = ix > 0 and iy > 0 and abs(dx / ix) ** power + abs(dy / iy) ** power < 1.0
                if outer and not inner and (arc is None or arc(dx / rx, dy / ry)):
                    self.px(x, y, x, y)
        return self


def _a() -> Glyph:
    g = Glyph(15)
    # Two legs of even weight meeting in a flat top; the right one heavier (the thick stroke),
    # the left one as wide as a stem: no hairline.
    g.diag(5.5, 0, 0.5, H - 3, STEM)          # left leg
    g.diag(6.5, 0, 11.5, H - 3, STEM + 1)     # right leg
    g.rect(5, 0, 9, 1)                        # the flat top
    g.rect(3, 10, 11, 10 + MID - 1)           # the bar
    g.rect(0, H - SERIF, 4, H - 1)            # foot serifs
    g.rect(10, H - SERIF, 14, H - 1)
    return g


def _b() -> Glyph:
    g = Glyph(13)
    g.stem(2, top=True, foot=True, right=False)
    g.rect(2, 0, 8, BAR - 1)
    g.rect(2, 7, 8, 7 + MID - 1)
    g.rect(2, H - BAR, 9, H - 1)
    g.ring(4, 0, 11, 8, power=2.6, arc=lambda dx, dy: dx > 0)
    g.ring(4, 7, 12, H - 1, power=2.6, arc=lambda dx, dy: dx > 0)
    return g


def _c() -> Glyph:
    g = Glyph(13)
    g.ring(0, 0, 12, H - 1, power=2.6, arc=lambda dx, dy: not (dx > 0.35 and abs(dy) < 0.42))
    g.rect(10, 1, 12, 4)                      # the beak's serifs
    g.rect(10, H - 5, 12, H - 2)
    return g


def _d() -> Glyph:
    g = Glyph(14)
    g.stem(2, right=False)
    g.rect(2, 0, 7, BAR - 1)
    g.rect(2, H - BAR, 7, H - 1)
    g.ring(0, 0, 13, H - 1, power=2.6, arc=lambda dx, dy: dx > 0.05)
    return g


def _e() -> Glyph:
    g = Glyph(12)
    g.stem(2, right=False)
    g.rect(2, 0, 11, BAR - 1)
    g.rect(2, 7, 9, 7 + MID - 1)
    g.rect(2, H - BAR, 11, H - 1)
    g.rect(10, 0, 11, 4)                      # the arms' serifs, down and up
    g.rect(8, 5, 9, 10)
    g.rect(10, H - 5, 11, H - 1)
    return g


def _f() -> Glyph:
    g = Glyph(12)
    g.stem(2, top=False, right=True)
    g.rect(0, 0, 11, BAR - 1)
    g.rect(2, 7, 9, 7 + MID - 1)
    g.rect(10, 0, 11, 4)
    g.rect(8, 5, 9, 10)
    return g


def _g() -> Glyph:
    g = Glyph(14)
    g.ring(0, 0, 13, H - 1, power=2.6, arc=lambda dx, dy: not (dx > 0.3 and -0.75 < dy < 0.12))
    g.rect(11, 1, 13, 4)
    g.rect(7, 8, 13, 9)                       # the spur's bar
    g.rect(10, 8, 12, H - 2)
    return g


def _h() -> Glyph:
    g = Glyph(15)
    g.stem(2)
    g.stem(10)
    g.rect(2, 7, 12, 7 + MID - 1)
    return g


def _i() -> Glyph:
    g = Glyph(7)
    g.stem(2)
    return g


def _j() -> Glyph:
    g = Glyph(11)
    g.rect(5, 0, 7, H - 4)                    # the stem, down into the hook
    g.rect(3, 0, 9, SERIF - 1)                # top serif
    g.ring(0, H - 9, 7, H - 1, power=2.6, arc=lambda dx, dy: dy > 0.0)   # the hook
    g.rect(0, H - 6, 2, H - 4)                # its knob
    return g


def _k() -> Glyph:
    g = Glyph(14)
    g.stem(2, right=False)
    g.rect(2, 0, 6, SERIF - 1)
    g.rect(2, H - SERIF, 6, H - 1)
    g.diag(10.5, 0, 4.5, 8, STEM)             # the arm
    g.diag(6.5, 7, 10.5, H - 2, STEM + 1)     # the leg
    g.rect(8, 0, 13, SERIF - 1)
    g.rect(8, H - SERIF, 13, H - 1)
    return g


def _l() -> Glyph:
    g = Glyph(12)
    g.stem(2, foot=False)
    g.rect(0, H - BAR, 11, H - 1)
    g.rect(10, H - 5, 11, H - 1)
    return g


def _m() -> Glyph:
    g = Glyph(18)
    g.stem(2)
    g.stem(13)
    g.diag(4.5, 0, 8.5, 11, STEM - 1)
    g.diag(12.5, 0, 8.5, 11, STEM - 1)
    return g


def _n() -> Glyph:
    g = Glyph(15)
    g.stem(2, right=True)
    g.stem(10, foot=False)
    g.diag(3.5, 0, 10.5, H - 1, STEM)
    return g


def _o() -> Glyph:
    g = Glyph(14)
    g.ring(0, 0, 13, H - 1, power=2.6)
    return g


def _p() -> Glyph:
    g = Glyph(13)
    g.stem(2, right=False)
    g.rect(2, 0, 8, BAR - 1)
    g.rect(2, 8, 8, 8 + MID - 1)
    g.ring(4, 0, 12, 9, power=2.6, arc=lambda dx, dy: dx > 0)
    return g


def _q() -> Glyph:
    g = _o().pad(1)
    g.diag(8.5, 11, 12.5, H - 1, STEM)
    return g


def _r() -> Glyph:
    g = _p().pad(1)
    g.diag(6.5, 9, 10.5, H - 1, STEM)
    g.rect(9, H - SERIF, 13, H - 1)
    return g


def _s() -> Glyph:
    g = Glyph(12)
    g.ring(0, 0, 11, 8, power=2.6, arc=lambda dx, dy: not (dx > 0.2 and dy > -0.2) )
    g.ring(0, 7, 11, H - 1, power=2.6, arc=lambda dx, dy: not (dx < -0.2 and dy < 0.2))
    g.rect(9, 1, 11, 4)
    g.rect(0, H - 5, 2, H - 2)
    return g


def _t() -> Glyph:
    g = Glyph(13)
    g.rect(0, 0, 12, BAR - 1)
    g.rect(0, 0, 1, 4)
    g.rect(11, 0, 12, 4)
    g.stem(5, top=False)
    return g


def _u() -> Glyph:
    g = Glyph(15)
    g.stem(2, foot=False)
    g.stem(10, foot=False)
    g.ring(2, 6, 12, H - 1, power=2.6, arc=lambda dx, dy: dy > 0.0)
    g.rect(2, 0, 4, 11)
    g.rect(10, 0, 12, 11)
    return g


def _v() -> Glyph:
    g = Glyph(15)
    g.diag(1.5, 0, 6.5, H - 1, STEM + 1)
    g.diag(12.5, 0, 6.5, H - 1, STEM - 1)
    g.rect(0, 0, 5, SERIF - 1)
    g.rect(10, 0, 14, SERIF - 1)
    return g


def _w() -> Glyph:
    g = Glyph(20)
    g.diag(1.5, 0, 5.5, H - 1, STEM)
    g.diag(9.5, 2, 6.5, H - 1, STEM - 1)
    g.diag(9.5, 2, 12.5, H - 1, STEM)
    g.diag(17.5, 0, 13.5, H - 1, STEM - 1)
    g.rect(0, 0, 5, SERIF - 1)
    g.rect(15, 0, 19, SERIF - 1)
    return g


def _x() -> Glyph:
    g = Glyph(15)
    g.diag(1.5, 0, 10.5, H - 1, STEM + 1)
    g.diag(11.5, 0, 1.5, H - 1, STEM - 1)
    g.rect(0, 0, 5, SERIF - 1)
    g.rect(9, 0, 14, SERIF - 1)
    g.rect(0, H - SERIF, 5, H - 1)
    g.rect(9, H - SERIF, 14, H - 1)
    return g


def _y() -> Glyph:
    g = Glyph(15)
    g.diag(1.5, 0, 5.5, 8, STEM + 1)
    g.diag(12.5, 0, 7.5, 8, STEM - 1)
    g.stem(6, 8, H - 1, top=False)
    g.rect(0, 0, 5, SERIF - 1)
    g.rect(10, 0, 14, SERIF - 1)
    return g


def _z() -> Glyph:
    g = Glyph(12)
    g.rect(0, 0, 11, BAR - 1)
    g.rect(0, H - BAR, 11, H - 1)
    g.diag(8.5, BAR, 0.5, H - BAR - 1, STEM + 1)
    g.rect(0, 0, 1, 4)
    g.rect(10, H - 5, 11, H - 1)
    return g


def _digit(d: str) -> Glyph:
    g = Glyph(12)
    if d == "0":
        g.ring(0, 0, 11, H - 1, power=2.6)
    elif d == "1":
        g.stem(4, top=False)
        g.diag(4.5, 0, 1.5, 3, 2)
    elif d == "2":
        g.ring(0, 0, 11, 9, power=2.6, arc=lambda dx, dy: dy < 0.1 or dx > 0.4)
        g.diag(8.5, 7, 0.5, H - BAR, STEM + 1)
        g.rect(0, H - BAR, 11, H - 1)
    elif d == "3":
        g.ring(0, 0, 11, 8, power=2.6, arc=lambda dx, dy: dx > -0.3)
        g.ring(0, 7, 11, H - 1, power=2.6, arc=lambda dx, dy: dx > -0.3)
    elif d == "4":
        g.stem(7, top=False)
        g.diag(7.5, 0, 0.5, 10, STEM)
        g.rect(0, 10, 11, 10 + MID - 1)
    elif d == "5":
        g.rect(1, 0, 11, BAR - 1)
        g.rect(1, 0, 3, 7)
        g.ring(0, 5, 11, H - 1, power=2.6, arc=lambda dx, dy: not (dx < -0.25 and dy < 0.15))
        g.rect(0, H - 5, 2, H - 3)
    elif d == "6":
        g.ring(0, 5, 11, H - 1, power=2.6)
        g.ring(0, 0, 11, 11, power=2.6, arc=lambda dx, dy: dy < 0.0 and dx < 0.55)
        g.rect(0, 4, 2, 10)
        g.rect(9, 1, 11, 3)
    elif d == "7":
        g.rect(0, 0, 11, BAR - 1)
        g.diag(9.5, BAR, 3.5, H - 1, STEM + 1)
    elif d == "8":
        g.ring(1, 0, 10, 8, power=2.6)
        g.ring(0, 7, 11, H - 1, power=2.6)
    elif d == "9":
        g.ring(0, 0, 11, 10, power=2.6)
        g.ring(0, 4, 11, H - 1, power=2.6, arc=lambda dx, dy: dy > 0.0 and dx > -0.55)
        g.rect(9, 5, 11, 11)
        g.rect(0, H - 4, 2, H - 2)
    return g


def _punct(ch: str) -> Glyph:
    if ch == " ":
        return Glyph(6)
    if ch == ".":
        return Glyph(4).rect(0, H - 3, 2, H - 1)
    if ch == ",":
        return Glyph(4).rect(0, H - 3, 2, H - 1).rect(1, H - 1, 1, H - 1)
    if ch == "&":
        # A small loop up top, a bowl below, the long stroke from the loop down to the bottom
        # right, and the arm reaching out to the right with a serif.
        g = Glyph(15)
        g.ring(2, 0, 9, 6, thick_x=STEM - 1, thick_y=BAR - 1, power=2.6)
        g.ring(0, 5, 10, H - 1, power=2.6, arc=lambda dx, dy: dx < 0.35 or dy > 0.5)
        g.diag(3.5, 5, 11.5, H - 1, STEM)
        g.rect(9, 8, 12, 8 + MID - 1)
        g.rect(11, 7, 14, 8)
        g.rect(11, H - SERIF, 14, H - 1)
        return g
    if ch == "$":
        # The S a little short, its bar through it standing out above and below.
        g = Glyph(12)
        g.ring(0, 2, 11, 9, power=2.6, arc=lambda dx, dy: not (dx > 0.2 and dy > -0.2))
        g.ring(0, 8, 11, H - 3, power=2.6, arc=lambda dx, dy: not (dx < -0.2 and dy < 0.2))
        g.rect(9, 3, 11, 5)
        g.rect(0, H - 6, 2, H - 4)
        g.rect(5, 0, 6, H - 1)
        return g
    if ch == "'":
        return Glyph(4).rect(0, 0, 2, 3)
    if ch == "-":
        return Glyph(8).rect(0, 7, 7, 8)
    return Glyph(6)


GLYPHS = {ch: f for ch, f in zip("ABCDEFGHIJKLMNOPQRSTUVWXYZ",
          [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _s, _t, _u, _v, _w, _x, _y, _z])}


def glyph(ch: str) -> Glyph:
    ch = ch.upper()
    if ch in GLYPHS:
        return GLYPHS[ch]()
    if ch.isdigit():
        return _digit(ch)
    return _punct(ch)


def text_mask(text: str, track: int = 2, height: int = H) -> np.ndarray:
    """The text set in the glyphs `height` squares tall (H as drawn), `track` design squares
    between letters."""
    global K
    K = height / float(H)
    try:
        parts = []
        rows = _sq(H)
        for i, ch in enumerate(text):
            parts.append(glyph(ch).m)
            if i < len(text) - 1:
                parts.append(np.zeros((rows, _sq(track)), bool))
        return np.concatenate(parts, 1) if parts else np.zeros((rows, 0), bool)
    finally:
        K = 1.0


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", action="store_true")
    ap.add_argument("--text", default="")
    args = ap.parse_args()
    lines = [(args.text, H)] if args.text else [("ABCDEFGHIJKLM", H), ("NOPQRSTUVWXYZ", H), ("0123456789 $&.,", H),
                                                 ("JAIL SALOON", H), ("SALOON", 23), ("ASSAY OFFICE", 12)]
    rows = [text_mask(t, 3, h) for t, h in lines]
    w = max(r.shape[1] for r in rows) + 8
    img = np.full((sum(r.shape[0] + 6 for r in rows) + 4, w, 3), (214, 204, 182), np.uint8)
    y = 4
    for r in rows:
        img[y:y + r.shape[0], 4:4 + r.shape[1]][r] = (40, 32, 28)
        y += r.shape[0] + 6
    SHEET.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(img).resize((w * 8, img.shape[0] * 8), Image.NEAREST).save(SHEET)
    print(SHEET)


if __name__ == "__main__":
    main()
