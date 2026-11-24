#!/usr/bin/env python3
"""The grand stair's three options on the lobby's plan (Sean, 2026-11-24: "more central ... wider at the base
and narrower as it goes up ... we're going for opulence"). Feet, the lobby's own: x from its west wall (the
bar's) east to the parlour's (28 ft), y from the front wall (the main doors, on the axis x 14) back to the
28 ft wall. 13 ft 6 in floor to floor: 22 risers of 7 3/8 in on 11 in treads. Writes stair_options.png.
Run: python3 docs/briefs/hotel/draw_stairs.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
PAPER = (246, 241, 228)
INK = (34, 30, 26)
SOFT = (120, 110, 96)
OAK = (120, 72, 40)
RUN = (150, 40, 40)
LAND = (214, 190, 160)
VOID = (205, 214, 226)
S = 17          # pixels a foot
W, D = 28, 28   # the lobby
TREAD = 11 / 12
PW, PH = W * S + 120, D * S + 300


def font(px, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, px)


class Panel:
    def __init__(self, im, ox, oy):
        self.d = ImageDraw.Draw(im)
        self.ox, self.oy = ox, oy

    def p(self, x, y):
        # y 0 (the front, the main doors) at the bottom
        return self.ox + 60 + x * S, self.oy + 100 + (D - y) * S

    def rect(self, x0, y0, x1, y1, fill, outline=INK, width=2):
        a, b = self.p(x0, y1), self.p(x1, y0)
        self.d.rectangle([a, b], fill=fill, outline=outline, width=width)

    def text(self, x, y, s, size=12, bold=False, fill=INK, anchor="mm"):
        self.d.text(self.p(x, y), s, fill=fill, font=font(size, bold), anchor=anchor)

    def flight(self, x0, y0, x1, y1, axis, up, n, flare=0.0):
        """A flight's treads: `axis` 'y' or 'x' the way it climbs, `up` +1/-1, n treads from its foot."""
        self.rect(x0, y0, x1, y1, OAK, width=2)
        # the runner down the middle
        if axis == "y":
            m, h = (x0 + x1) / 2, (x1 - x0) * 0.32
            self.rect(m - h, y0, m + h, y1, RUN, outline=RUN, width=1)
            for k in range(1, n):
                y = y0 + (y1 - y0) * k / n
                self.d.line([self.p(x0, y), self.p(x1, y)], fill=INK, width=1)
            foot = y0 if up > 0 else y1
            self.arrow((x0 + x1) / 2, foot + up * 1.2, (x0 + x1) / 2, foot + up * ((y1 - y0) - 1.2))
        else:
            m, h = (y0 + y1) / 2, (y1 - y0) * 0.32
            self.rect(x0, m - h, x1, m + h, RUN, outline=RUN, width=1)
            for k in range(1, n):
                x = x0 + (x1 - x0) * k / n
                self.d.line([self.p(x, y0), self.p(x, y1)], fill=INK, width=1)
            foot = x0 if up > 0 else x1
            self.arrow(foot + up * 1.2, (y0 + y1) / 2, foot + up * ((x1 - x0) - 1.2), (y0 + y1) / 2)

    def arrow(self, x0, y0, x1, y1):
        a, b = self.p(x0, y0), self.p(x1, y1)
        self.d.line([a, b], fill=(250, 240, 220), width=3)
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = max((dx * dx + dy * dy) ** 0.5, 1)
        ux, uy = dx / L, dy / L
        self.d.polygon([b, (b[0] - 10 * ux + 6 * uy, b[1] - 10 * uy - 6 * ux), (b[0] - 10 * ux - 6 * uy, b[1] - 10 * uy + 6 * ux)], fill=(250, 240, 220))

    def curtail(self, cx, y_front, width, steps=3):
        """The flared, rounded bottom steps (curtail steps), each wider and deeper than the flight, the newel and
        its statue lamp on the scroll of the lowest."""
        for k in range(steps, 0, -1):
            w = width + 1.6 * k
            y0 = y_front + (steps - k) * TREAD
            a, b = self.p(cx - w / 2, y0 + TREAD * 1.05), self.p(cx + w / 2, y0)
            self.d.rounded_rectangle([a, b], radius=int(S * 0.9), fill=OAK, outline=INK, width=2)
        for side in (-1, 1):
            nx = cx + side * (width / 2 + 0.9)
            c = self.p(nx, y_front + 0.55)
            self.d.ellipse([c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9], fill=(70, 40, 20), outline=INK, width=2)
            self.d.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=(240, 200, 90))

    def frame(self, title, sub):
        d = self.d
        d.text((self.ox + 20, self.oy + 8), title, fill=INK, font=font(19, True))
        d.text((self.ox + 20, self.oy + 34), sub, fill=SOFT, font=font(12))
        self.rect(0, 0, W, D, (240, 233, 216), width=4)
        # the office's corner (behind the desk) and the desk
        self.rect(0, 0, 10, 10, (224, 214, 226), width=2)
        self.text(5, 5, "office", 11, fill=SOFT)
        self.rect(1.0, 10.6, 9.0, 12.6, (150, 100, 60), width=1)
        self.text(5, 11.6, "desk", 10, fill=(250, 240, 220))
        # the main doors on the axis, the street below
        a, b = self.p(11, 0.5), self.p(17, -0.5)
        d.rectangle([a, b], fill=PAPER, outline=INK, width=2)
        self.text(14, -2.2, "MAIN DOORS (on the axis)", 11, True)
        self.text(-1.6, 14, "bar", 11, fill=SOFT)
        self.text(29.8, 14, "parlour", 11, fill=SOFT)
        self.text(14, 29.4, "28 ft wall: the dining room behind", 11, fill=SOFT)
        d.line([self.p(14, 0.6), self.p(14, 27.6)], fill=(200, 190, 170), width=1)


def notes(pn, lines, y0):
    for i, (s, b) in enumerate(lines):
        pn.d.text((pn.ox + 20, pn.oy + y0 + i * 19), s, fill=INK if b else SOFT, font=font(13 if b else 12, b))


def main():
    im = Image.new("RGB", (PW * 3 + 40, PH + 110), PAPER)
    d = ImageDraw.Draw(im)
    d.text((24, 14), "THE GRAND STAIR: three ways, the lobby in plan (28 x 28 ft, the main doors at the bottom)", fill=INK, font=font(24, True))
    d.text((24, 48), "Each: dark oak (OakStair), the red runner on brass rods, a statue newel lamp, turned balusters; curtail steps flared at the foot; no posts in the room (the well framed from the walls).", fill=SOFT, font=font(14))

    # 1. Imperial
    p = Panel(im, 20, 80)
    p.frame("1. IMPERIAL (the showpiece)", "one wide flight up the axis, splitting in two")
    p.rect(3, 6.5, 25, 27.6, VOID, outline=(110, 130, 160), width=2)
    p.text(14, 26.6, "open to the upper floor: a gallery rails round the void", 10, fill=(70, 90, 120))
    p.flight(11, 8.8, 17, 18.0, "y", 1, 10)
    p.curtail(14, 6.0, 6.0)
    p.rect(5, 18.0, 23, 22.5, LAND)
    p.text(14, 20.2, "half landing (a tall gilt mirror on the wall)", 10)
    p.flight(5, 9.0, 9, 18.0, "y", -1, 10)
    p.flight(19, 9.0, 23, 18.0, "y", -1, 10)
    p.text(7, 7.6, "to gallery", 10, True)
    p.text(21, 7.6, "to gallery", 10, True)
    notes(p, [("6 ft centre flight, 11 up; two 4 ft flights, 11 up, back toward the front", True),
              ("The lobby double height: the chandelier hangs in the void,", False),
              ("men look down over the gallery's rail.", False),
              ("Upstairs: room 3 and the suite's parlour give way to the gallery.", False),
              ("Most work: a landing, two flights, a gallery round a void.", False),
              ("A big-city hotel's move (the Windsor, Denver).", False)], D * S + 150)

    # 2. Central flight, return
    p = Panel(im, 20 + PW + 20, 80)
    p.frame("2. CENTRAL, WITH A RETURN (recommended)", "up the axis to a landing, a turn to the upper hall")
    p.rect(11, 15.5, 27.6, 27.6, VOID, outline=(110, 130, 160), width=2)
    p.text(19.5, 15.0, "well (railed upstairs)", 10, fill=(70, 90, 120))
    p.flight(11.5, 8.6, 16.5, 19.6, "y", 1, 12)
    p.curtail(14, 5.8, 5.0)
    p.rect(11.5, 19.6, 17.5, 27.6, LAND)
    p.text(14.5, 23.6, "landing", 10)
    p.flight(17.5, 23.0, 26.8, 27.6, "x", 1, 10)
    p.text(22.2, 21.9, "to the upper hall", 10, True)
    notes(p, [("5 ft centre flight, 13 up, on the axis; 4 ft return, 9 up", True),
              ("The first thing seen from the doors; the landing's", False),
              ("tall clock or mirror its backdrop.", False),
              ("Upstairs: the hall over the well, a turned rail round it;", False),
              ("the rooms as built.", False),
              ("One landing and one turn more than now.", False)], D * S + 150)

    # 3. Along the back wall, dressed
    p = Panel(im, 20 + 2 * (PW + 20), 80)
    p.frame("3. ALONG THE BACK WALL, DRESSED", "today's line, made grand (as Sean's picture)")
    p.rect(4.5, 22.6, 27.6, 27.6, VOID, outline=(110, 130, 160), width=2)
    p.flight(4.5, 23.0, 24.8, 27.6, "x", 1, 22)
    for k in range(3, 0, -1):
        w = 5.0 + 1.4 * k
        x0 = 4.5 - (3 - k + 1) * TREAD
        a, b = p.p(x0, 23.0 - 0.7 * k + w), p.p(x0 + TREAD * 1.1, 27.6 - w + 0.7 * k - 0.0)
        p.d.rounded_rectangle([p.p(x0, 27.6), p.p(x0 + TREAD * 1.1, 27.6 - (5.0 + 1.4 * k))], radius=int(S * 0.9), fill=OAK, outline=INK, width=2)
    c = p.p(3.0, 21.0)
    p.d.ellipse([c[0] - 9, c[1] - 9, c[0] + 9, c[1] + 9], fill=(70, 40, 20), outline=INK, width=2)
    p.d.ellipse([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=(240, 200, 90))
    p.text(14, 21.4, "5 ft, 22 up in one flight, a panelled wall beside it", 10)
    notes(p, [("5 ft flight, curtail foot and statue newel at the west", True),
              ("Handsome and cheapest; off the axis, to one side.", False),
              ("Upstairs: as built.", False),
              ("(The game's stair today: this line, 3 ft 9 in, plain,", False),
              ("with posts in the room.)", False)], D * S + 150)

    d.text((24, im.size[1] - 30), "Brown: oak treads; red: the runner; gold dot: the newel's lamp; blue: open to the upper floor; arrows climb. A design to choose from; the spec settles sizes.", fill=SOFT, font=font(13))
    out = os.path.join(HERE, "stair_options.png")
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main()
