#!/usr/bin/env python3
"""Both floors of the hotel's main block as built (config/buildings/hotel.json's rooms, in feet from the WEST corner,
the street at the bottom), with the grand stair's option 2 (central, with a return: stair_options.png) worked in, and
what it does upstairs. Writes plan_stair2.png. Run: python3 docs/briefs/hotel/draw_plan_stair2.py
"""
import json
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
PAPER = (246, 241, 228)
INK = (34, 30, 26)
SOFT = (120, 110, 96)
FILL = {"public": (232, 220, 196), "service": (214, 220, 210), "private": (224, 214, 226), "guest": (236, 228, 210),
        "stair": (205, 196, 180), "open": (240, 236, 226), "gallery": (226, 214, 190)}
OAK = (120, 72, 40)
RUN = (150, 40, 40)
LAND = (214, 190, 160)
VOID = (205, 214, 226)
S = 12
M = 60
FT = 0.3048
TREAD = 11 / 12
KIND = {"bar": "public", "lobby": "public", "parlour": "public", "dining": "public", "office": "private", "stair_hall": "stair",
        "sample": "public", "hall": "open", "back_stair_up": "stair", "bath": "service", "landlady_sit": "private",
        "landlady_bed": "private"}
NAME = {"bar": "The bar", "lobby": "Lobby", "parlour": "Ladies' parlour", "dining": "Dining room", "office": "Office",
        "stair_hall": "Back stair", "sample": "Sample room", "hall": "Upper hall", "back_stair_up": "Back stair",
        "bath": "Bath", "landlady_sit": "Landlady", "landlady_bed": "Landlady", "suite_parlour": "Suite parlour",
        "suite_bed": "Suite bedroom", "room_1": "1", "room_2": "2", "room_3": "3", "room_4": "4", "room_5": "5",
        "room_6": "6", "room_7": "7", "room_8": "8"}


def font(px, bold=False):
    return ImageFont.truetype(FONT_B if bold else FONT, px)


class Plan:
    def __init__(self, d, ox, oy):
        self.d, self.ox, self.oy = d, ox, oy

    def p(self, x, y):
        return self.ox + M + x * S, self.oy + M + (50 - y) * S

    def rect(self, x0, y0, x1, y1, fill, outline=INK, width=2):
        a, b = self.p(x0, y1), self.p(x1, y0)
        self.d.rectangle([a, b], fill=fill, outline=outline, width=width)

    def text(self, x, y, s, size=12, bold=False, fill=INK):
        self.d.text(self.p(x, y), s, fill=fill, font=font(size, bold), anchor="mm")

    def room(self, rid, r, kind=None, label=None):
        x0, y0, x1, y1 = r
        self.rect(x0, y0, x1, y1, FILL[kind or KIND.get(rid, "guest")], width=3)
        self.text((x0 + x1) / 2, (y0 + y1) / 2, label or NAME.get(rid, rid), 13 if x1 - x0 > 11 else 11, True)

    def flight(self, x0, y0, x1, y1, axis, n):
        self.rect(x0, y0, x1, y1, OAK, width=2)
        if axis == "y":
            m, h = (x0 + x1) / 2, (x1 - x0) * 0.32
            self.rect(m - h, y0, m + h, y1, RUN, outline=RUN, width=1)
            for k in range(1, n):
                y = y0 + (y1 - y0) * k / n
                self.d.line([self.p(x0, y), self.p(x1, y)], fill=INK, width=1)
            self.arrow(m, y0 + 0.8, m, y1 - 0.8)
        else:
            m, h = (y0 + y1) / 2, (y1 - y0) * 0.32
            self.rect(x0, m - h, x1, m + h, RUN, outline=RUN, width=1)
            for k in range(1, n):
                x = x0 + (x1 - x0) * k / n
                self.d.line([self.p(x, y0), self.p(x, y1)], fill=INK, width=1)
            self.arrow(x0 + 0.8, m, x1 - 0.8, m)

    def arrow(self, x0, y0, x1, y1):
        a, b = self.p(x0, y0), self.p(x1, y1)
        self.d.line([a, b], fill=(250, 240, 220), width=3)
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = max((dx * dx + dy * dy) ** 0.5, 1)
        ux, uy = dx / L, dy / L
        self.d.polygon([b, (b[0] - 9 * ux + 5 * uy, b[1] - 9 * uy - 5 * ux), (b[0] - 9 * ux - 5 * uy, b[1] - 9 * uy + 5 * ux)], fill=(250, 240, 220))

    def rail(self, pts):
        self.d.line([self.p(*q) for q in pts], fill=OAK, width=5)

    def street(self):
        a, b = self.p(-1, 0), self.p(81, -8)
        self.d.rectangle([a, b], fill=(236, 226, 206), outline=SOFT, width=1)
        self.text(40, -4, "the walk; the gallery over it", 11, fill=SOFT)
        self.text(40, -10, "MAIN STREET (south)", 13, True)
        self.text(-3.5, 25, "lane", 11, fill=SOFT)
        self.text(83.5, 25, "lane", 11, fill=SOFT)


def main():
    spec = json.load(open(os.path.join(ROOT, "config/buildings/hotel.json")))
    W = float(spec["lot"]["width"])
    rooms = {}
    for r in spec["rooms"]:
        if r["level"] == "cellar":
            continue
        x0, z0, x1, z1 = r["rect"]
        rooms[(r["level"], r["id"])] = [round((W - x1) / FT, 1), round(z0 / FT, 1), round((W - x0) / FT, 1), round(z1 / FT, 1)]

    pw = 80 * S + 2 * M + 40
    ph = 60 * S + 2 * M + 40
    im = Image.new("RGB", (pw * 2, ph + 150), PAPER)
    d = ImageDraw.Draw(im)
    d.text((24, 12), "THE SALT CREEK HOTEL, the main block as built, with the grand stair (option 2: central, with a return)", fill=INK, font=font(22, True))
    d.text((24, 44), "Feet from the west corner; the street at the bottom; the kitchen wing (next step) goes behind the west half. Brown: oak; red: the runner; arrows climb; blue: open to below.", fill=SOFT, font=font(13))

    # --- the ground floor ---
    g = Plan(d, 0, 70)
    d.text((M + 10, 70 + 20), "GROUND FLOOR", fill=INK, font=font(17, True))
    g.street()
    for (lv, rid), r in rooms.items():
        if lv == "ground" and rid != "office":
            g.room(rid, r)
    g.room("office", rooms[("ground", "office")])
    # the desk in front of the office, facing the main doors
    g.rect(23.0, 11.0, 31.0, 13.0, (150, 100, 60), width=1)
    g.text(27.0, 12.0, "desk", 10, fill=(250, 240, 220))
    # the grand stair: curtail steps, a 5 ft flight up the axis, the landing, the return to the upper hall
    for k, (w, y) in enumerate([(9.8, 4.4), (8.2, 5.3), (6.6, 6.2)]):
        a, b = g.p(36 - w / 2, y + TREAD * 1.05), g.p(36 + w / 2, y)
        d.rounded_rectangle([a, b], radius=10, fill=OAK, outline=INK, width=2)
    for side in (-1, 1):
        c = g.p(36 + side * 3.4, 4.9)
        d.ellipse([c[0] - 8, c[1] - 8, c[0] + 8, c[1] + 8], fill=(70, 40, 20), outline=INK, width=2)
        d.ellipse([c[0] - 3, c[1] - 3, c[0] + 3, c[1] + 3], fill=(240, 200, 90))
    g.flight(33.5, 7.2, 38.5, 18.2, "y", 12)
    g.rect(33.5, 18.2, 39.5, 27.7, LAND)
    g.text(36.5, 21.5, "landing", 10)
    g.text(36.5, 20.2, "(clock)", 9, fill=SOFT)
    g.flight(39.5, 23.1, 48.7, 27.7, "x", 10)
    g.rail([(38.5, 7.2), (38.5, 18.2), (39.5, 18.2), (39.5, 23.1), (48.7, 23.1)])
    g.rail([(33.5, 7.2), (33.5, 27.7)])
    # main doors and the ladies' door
    for x, w in ((36.0, 6.0), (73.5, 3.5)):
        a, b = g.p(x - w / 2, 0.6), g.p(x + w / 2, -0.6)
        d.rectangle([a, b], fill=PAPER, outline=INK, width=2)
    g.text(36, 1.6, "main doors", 9, True)
    g.text(73.5, 1.6, "ladies' door", 9, True)
    g.text(36, 30.5, "", 9)

    # --- the upper floor ---
    u = Plan(d, pw, 70)
    d.text((pw + M + 10, 70 + 20), "UPPER FLOOR", fill=INK, font=font(17, True))
    u.street()
    for (lv, rid), r in rooms.items():
        if lv != "upper" or rid in ("suite_parlour", "suite_bed", "hall"):
            continue
        u.room(rid, r)
    # the hall, the suite shortened to 12 ft deep, a gallery round the stair's opening
    u.room("hall", [0.3, 20.2, 33.5, 28.0], label="Upper hall")
    u.room("hall", [48.7, 20.2, 79.7, 28.0], label="Upper hall")
    u.rect(29.8, 12.0, 53.9, 20.2, FILL["gallery"], width=3)
    u.rect(33.5, 16.0, 48.7, 28.0, VOID, outline=(110, 130, 160), width=2)
    u.text(41.1, 23.0, "open to the stair below", 10, fill=(70, 90, 120))
    u.text(41.1, 21.6, "(the chandelier hangs here)", 9, fill=(70, 90, 120))
    u.text(41.1, 14.0, "STAIR GALLERY: a turned rail round the opening", 11, True)
    u.rail([(33.5, 16.0), (48.7, 16.0), (48.7, 23.1)])
    u.rail([(33.5, 16.0), (33.5, 28.0)])
    u.flight(39.5, 23.1, 48.7, 27.7, "x", 10)
    u.room("suite_parlour", [30.2, 0.3, 41.8, 11.8], label="Suite parlour")
    u.room("suite_bed", [42.2, 0.3, 53.9, 11.8], label="Suite bedroom")
    u.text(36, 2.2, "French doors to the balcony", 9, fill=SOFT)

    notes = [
        ("From the main doors the stair is straight ahead on the axis: three curtail steps flared round the statue newel lamps,", True),
        ("then 12 risers of 5 ft dark oak with the red runner to a landing (a tall clock on it), and a 4 ft return of 10 risers", True),
        ("up along the 28 ft wall into the upper hall. The desk and office stay at the left; the bar and dining doors as built.", True),
        ("Upstairs: the floor is opened over the stair's top half and its landing (blue), with a turned rail round it; the hall", False),
        ("passes in front of the opening on a stair gallery 4 ft wide, so the suite's two rooms are 12 ft deep instead of 20 (their doors", False),
        ("open onto the stair gallery). A guest upstairs looks down the stair to the front doors. The other rooms as built.", False),
        ("The changes from what's built: the stair, its opening and rail, the gallery, the suite 8 ft shallower. No posts in the lobby.", False),
    ]
    for i, (s, b) in enumerate(notes):
        d.text((24, ph + 18 + i * 19), s, fill=INK if b else SOFT, font=font(13, b))
    out = os.path.join(HERE, "plan_stair2.png")
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main()
