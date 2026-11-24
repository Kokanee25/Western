#!/usr/bin/env python3
"""Two ways to rebuild the hotel's main block inside (the footprint as built, 80 x 50 ft) so the grand stair has room
and starts well back from the main doors (Sean, 2026-11-24: option 2 put its foot 4 ft inside the doors). Both
floors of each, in feet from the west corner, the street at the bottom. Writes plan_ideas.png.
Run: python3 docs/briefs/hotel/draw_plan_ideas.py
"""
import os
from PIL import Image, ImageDraw

import draw_plan_stair2 as base

HERE = os.path.dirname(os.path.abspath(__file__))
base.S = 10
S, M = base.S, base.M
Plan, font, FILL = base.Plan, base.font, base.FILL
PAPER, INK, SOFT, OAK, LAND, VOID = base.PAPER, base.INK, base.SOFT, base.OAK, base.LAND, base.VOID
TREAD = base.TREAD
SKY = (110, 130, 160)


def curtail(pl, cx, cy, width, axis):
    """Three flared, rounded bottom steps, wider than the flight; the statue newel lamps either side."""
    d = pl.d
    for k, grow in enumerate((3.2, 1.6, 0.0)):
        w = width + grow
        if axis == "y":      # climbs +y, foot at cy
            a, b = pl.p(cx - w / 2, cy + (k + 1) * TREAD), pl.p(cx + w / 2, cy + k * TREAD)
        else:                # climbs +x, foot at cx
            a, b = pl.p(cx + k * TREAD, cy + w / 2), pl.p(cx + (k + 1) * TREAD, cy - w / 2)
        d.rounded_rectangle([a, b], radius=8, fill=OAK, outline=INK, width=2)
    for side in (-1, 1):
        c = pl.p(cx + side * (width / 2 + 2.2), cy + 0.6) if axis == "y" else pl.p(cx + 0.6, cy + side * (width / 2 + 2.2))
        d.ellipse([c[0] - 7, c[1] - 7, c[0] + 7, c[1] + 7], fill=(70, 40, 20), outline=INK, width=2)
        d.ellipse([c[0] - 3, c[1] - 3, c[0] + 3, c[1] + 3], fill=(240, 200, 90))


def flight_down(pl, x0, y0, x1, y1, n):
    """A flight climbing -y (toward the street): draw it, then point the arrow the right way."""
    m = (x0 + x1) / 2
    pl.rect(x0, y0, x1, y1, OAK, width=2)
    pl.rect(m - (x1 - x0) * 0.32, y0, m + (x1 - x0) * 0.32, y1, base.RUN, outline=base.RUN, width=1)
    for k in range(1, n):
        y = y0 + (y1 - y0) * k / n
        pl.d.line([pl.p(x0, y), pl.p(x1, y)], fill=INK, width=1)
    pl.arrow(m, y1 - 0.8, m, y0 + 0.8)


def flight_west(pl, x0, y0, x1, y1, n):
    """A flight climbing -x."""
    m = (y0 + y1) / 2
    pl.rect(x0, y0, x1, y1, OAK, width=2)
    pl.rect(x0, m - (y1 - y0) * 0.32, x1, m + (y1 - y0) * 0.32, base.RUN, outline=base.RUN, width=1)
    for k in range(1, n):
        x = x0 + (x1 - x0) * k / n
        pl.d.line([pl.p(x, y0), pl.p(x, y1)], fill=INK, width=1)
    pl.arrow(x1 - 0.8, m, x0 + 0.8, m)


def door(pl, x, w, label):
    a, b = pl.p(x - w / 2, 0.6), pl.p(x + w / 2, -0.6)
    pl.d.rectangle([a, b], fill=PAPER, outline=INK, width=2)
    pl.text(x, 1.7, label, 9, True)


def walk_line(pl, pts):
    """The guest's way from the main doors to the stair's foot, dotted."""
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) / 1.2)
        for k in range(0, n, 2):
            a = pl.p(x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n)
            b = pl.p(x0 + (x1 - x0) * (k + 1) / n, y0 + (y1 - y0) * (k + 1) / n)
            pl.d.line([a, b], fill=(40, 110, 60), width=3)


def column(pl, x, y):
    c = pl.p(x, y)
    pl.d.ellipse([c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6], fill=(240, 236, 226), outline=INK, width=2)


def idea_a(d, ox, oy):
    """A: the deep hall. The lobby runs through the 28 ft wall to the back; the stair rises at the far end."""
    g = Plan(d, ox, oy)
    d.text((ox + M, oy + 18), "A. THE DEEP HALL: ground floor", fill=INK, font=font(16, True))
    g.street()
    g.room("bar", [0.3, 0.3, 21.8, 28.0])
    g.room("sample", [0.3, 28.3, 13.8, 49.7])
    g.room("stair_hall", [14.2, 28.3, 23.8, 49.7])
    g.room("lobby", [22.2, 0.3, 49.8, 28.0], label=" ")
    g.rect(24.2, 28.0, 47.8, 49.7, FILL["public"], width=3)
    g.room("office", [22.2, 0.3, 31.8, 9.8])
    g.room("parlour", [50.2, 0.3, 79.7, 28.0])
    g.room("dining", [50.2, 28.3, 79.7, 49.7], label="Dining room")
    g.text(65, 44.0, "(moved east)", 9, fill=SOFT)
    # the 28 ft wall opened: a wide arch on two columns
    g.rect(27.0, 27.7, 45.0, 28.6, FILL["public"], outline=FILL["public"], width=1)
    column(g, 26.6, 28.15)
    column(g, 45.4, 28.15)
    g.text(36, 26.6, "arch, 18 ft, on two columns", 9, fill=SOFT)
    g.text(36, 14.5, "LOBBY", 13, True)
    g.text(36, 12.8, "(as built, 28 ft deep)", 9, fill=SOFT)
    g.rect(23.0, 11.0, 31.0, 13.0, (150, 100, 60), width=1)
    g.text(27.0, 12.0, "desk", 9, fill=(250, 240, 220))
    # imperial stair: a 7 ft centre flight up to a landing at the back wall, two 4 ft returns coming forward
    curtail(g, 36.0, 28.4, 7.0, "y")
    g.flight(32.5, 31.2, 39.5, 41.1, "y", 11)
    g.rect(24.2, 41.1, 47.8, 49.7, LAND)
    g.text(36, 46.5, "half landing", 10, True)
    g.text(36, 44.8, "(tall gilt mirror on the back wall)", 8, fill=SOFT)
    flight_down(g, 24.4, 31.2, 28.4, 41.1, 11)
    flight_down(g, 43.6, 31.2, 47.6, 41.1, 11)
    g.text(36, 42.6, "under it: service way, kitchen to dining (6 ft 6 in clear)", 8, fill=SOFT)
    walk_line(g, [(36, 1.2), (36, 27.8)])
    g.text(38.2, 20.0, "28 ft", 10, True, fill=(40, 110, 60))
    door(g, 36.0, 6.0, "main doors")
    door(g, 73.5, 3.5, "ladies' door")

    u = Plan(d, ox + 80 * S + 2 * M + 30, oy)
    d.text((u.ox + M, oy + 18), "A. upper floor", fill=INK, font=font(16, True))
    u.street()
    for rid, r in (("room_1", [0.3, 0.3, 9.8, 19.8]), ("room_2", [10.2, 0.3, 19.8, 19.8]), ("room_3", [20.2, 0.3, 29.8, 19.8]),
                   ("suite_parlour", [30.2, 0.3, 41.8, 19.8]), ("suite_bed", [42.2, 0.3, 53.9, 19.8]),
                   ("room_4", [54.2, 0.3, 66.8, 19.8]), ("room_5", [67.2, 0.3, 79.7, 19.8]), ("room_6", [0.3, 28.3, 13.8, 49.7]),
                   ("back_stair_up", [14.2, 28.3, 23.8, 49.7]), ("landlady_sit", [52.2, 28.3, 65.8, 49.7]),
                   ("landlady_bed", [66.2, 28.3, 79.7, 49.7])):
        u.room(rid, r)
    u.room("hall", [0.3, 20.2, 79.7, 28.0], label=" ")
    u.text(12, 24.1, "Upper hall", 12, True)
    u.text(64, 24.1, "Upper hall", 12, True)
    u.rect(24.2, 28.0, 47.8, 31.2, FILL["gallery"], width=2)
    u.rect(28.4, 31.2, 43.6, 49.7, VOID, outline=SKY, width=2)
    u.text(36, 41.5, "open to the stair", 10, fill=(70, 90, 120))
    u.text(36, 39.8, "SKYLIGHT in the flat roof", 10, True, fill=(70, 90, 120))
    u.text(36, 38.2, "(chandelier hangs here)", 8, fill=(70, 90, 120))
    flight_down(u, 24.4, 31.2, 28.4, 41.1, 11)
    flight_down(u, 43.6, 31.2, 47.6, 41.1, 11)
    u.rail([(28.4, 41.1), (28.4, 31.2), (43.6, 31.2), (43.6, 41.1)])
    u.rail([(24.2, 28.0), (47.8, 28.0)])
    u.rect(48.2, 28.3, 51.9, 49.7, FILL["service"], width=2)
    u.text(50.05, 39, "bath", 8)
    u.text(36, 29.6, "gallery: the hall's back wall replaced by a rail", 8, True)
    return [
        ("A. THE DEEP HALL: the lobby goes on through the 28 ft wall (a wide arch on two columns) into a stair hall that runs to the back wall.", True),
        ("You come in through the doors, cross the 28 ft lobby, and the stair rises in front of you at the far end: three flared steps and the", True),
        ("newel lamps, a 7 ft centre flight to a half landing against the back wall, then two 4 ft flights returning forward to the gallery.", True),
        ("Over the stair, the flat roof gets a skylight; the upper hall looks down over a rail. The ladies' parlour stays at the front east.", False),
        ("Costs: the dining room moves east and gets smaller (30 x 21 ft, from 56 x 21); upstairs, rooms 7 and 8 go to the stair well", False),
        ("(13 rooms become 11, the suite kept), the bath moves beside it. A service way under the landing joins the kitchen to the dining room.", False),
    ]


def idea_b(d, ox, oy):
    """B: the stair hall beside the lobby. The east front bay becomes the stair hall, seen through an arch."""
    g = Plan(d, ox, oy)
    d.text((ox + M, oy + 18), "B. THE STAIR HALL BESIDE THE LOBBY: ground floor", fill=INK, font=font(16, True))
    g.street()
    g.room("bar", [0.3, 0.3, 21.8, 28.0])
    g.room("sample", [0.3, 28.3, 13.8, 49.7])
    g.room("stair_hall", [14.2, 28.3, 23.8, 49.7])
    g.room("lobby", [22.2, 0.3, 49.8, 28.0], label=" ")
    g.text(40, 9.0, "LOBBY", 13, True)
    g.room("office", [22.2, 0.3, 31.8, 9.8])
    g.rect(23.0, 11.0, 31.0, 13.0, (150, 100, 60), width=1)
    g.text(27.0, 12.0, "desk", 9, fill=(250, 240, 220))
    g.room("dining", [24.2, 28.3, 57.8, 49.7], label="Dining room")
    g.room("parlour", [58.2, 28.3, 79.7, 49.7], label="Ladies' parlour")
    g.text(69, 36.0, "(moved behind the stair)", 9, fill=SOFT)
    g.rect(50.2, 0.3, 79.7, 28.0, FILL["public"], width=3)
    g.text(54.5, 25.8, "STAIR HALL", 11, True)
    # the arch through the lobby's east wall, on the stair's axis
    g.rect(49.6, 7.0, 50.4, 21.0, FILL["public"], outline=FILL["public"], width=1)
    column(g, 50.0, 6.6)
    column(g, 50.0, 21.4)
    g.text(47.0, 4.6, "arch, 14 ft", 9, fill=SOFT)
    # a 6 ft flight rising east from the arch to a landing at the east wall, one return along the back wall
    curtail(g, 55.4, 14.0, 6.0, "x")
    g.flight(58.2, 11.0, 68.2, 17.0, "x", 11)
    g.rect(68.2, 5.0, 79.7, 27.7, LAND)
    g.text(74.0, 15.0, "landing", 10, True)
    g.text(74.0, 13.4, "(tall clock)", 8, fill=SOFT)
    flight_west(g, 58.2, 23.2, 68.2, 27.7, 11)
    g.text(63.2, 21.6, "return to the upper hall", 8, True)
    walk_line(g, [(36, 1.2), (36, 14.0), (54.4, 14.0)])
    g.text(43, 16.0, "about 30 ft walked", 10, True, fill=(40, 110, 60))
    g.rail([(58.2, 17.0), (68.2, 17.0)])
    door(g, 36.0, 6.0, "main doors")
    door(g, 63.0, 3.5, "ladies' door (moved)")

    u = Plan(d, ox + 80 * S + 2 * M + 30, oy)
    d.text((u.ox + M, oy + 18), "B. upper floor", fill=INK, font=font(16, True))
    u.street()
    for rid, r in (("room_1", [0.3, 0.3, 9.8, 19.8]), ("room_2", [10.2, 0.3, 19.8, 19.8]), ("room_3", [20.2, 0.3, 29.8, 19.8]),
                   ("suite_parlour", [30.2, 0.3, 41.8, 19.8]), ("suite_bed", [42.2, 0.3, 53.9, 19.8]),
                   ("room_6", [0.3, 28.3, 13.8, 49.7]), ("back_stair_up", [14.2, 28.3, 23.8, 49.7]), ("bath", [24.2, 28.3, 28.7, 49.7]),
                   ("room_7", [29.0, 28.3, 40.8, 49.7]), ("room_8", [41.2, 28.3, 51.9, 49.7]),
                   ("landlady_sit", [52.2, 28.3, 65.8, 49.7]), ("landlady_bed", [66.2, 28.3, 79.7, 49.7])):
        u.room(rid, r)
    u.room("hall", [0.3, 20.2, 58.2, 28.0], label="Upper hall")
    u.rect(54.2, 0.3, 79.7, 28.0, FILL["gallery"], width=3)
    u.rect(58.2, 4.0, 79.4, 23.2, VOID, outline=SKY, width=2)
    u.text(68.8, 15.5, "open to the stair hall", 10, fill=(70, 90, 120))
    u.text(68.8, 13.8, "SKYLIGHT in the flat roof", 10, True, fill=(70, 90, 120))
    u.text(68.8, 12.2, "(chandelier hangs here)", 8, fill=(70, 90, 120))
    flight_west(u, 58.2, 23.2, 68.2, 27.7, 11)
    u.rail([(58.2, 23.2), (58.2, 4.0), (79.4, 4.0)])
    u.rail([(68.2, 23.2), (79.4, 23.2)])
    u.text(56.2, 12.0, "gallery", 8, True)
    return [
        ("B. THE STAIR HALL BESIDE THE LOBBY: the ladies' parlour's front bay (30 x 28 ft) becomes a stair hall of its own, two storeys high,", True),
        ("seen through a 14 ft arch in the lobby's east wall. You come in, the desk to your left, turn right, and the stair rises straight ahead:", True),
        ("three flared steps and the newel lamps, a 6 ft flight east to a big landing (the tall clock), then a 4 ft return along the back to the hall.", True),
        ("A skylight over it; a gallery on three sides upstairs. The lobby itself stays clear and as built, so the doors never face the stair.", False),
        ("Costs: the ladies' parlour moves behind the stair hall (21 x 21 ft, off the dining room's east end, its door from the stair hall); the", False),
        ("ladies' door moves to 63 ft, onto the stair hall; upstairs, rooms 4 and 5 go to the stair well (13 rooms become 11, the suite kept).", False),
    ]


def main():
    pw = 2 * (80 * S + 2 * M + 30)
    ph = 60 * S + 2 * M
    title_h = 70
    note_h = 6 * 18 + 30
    im = Image.new("RGB", (pw + 20, title_h + 2 * (ph + note_h) + 40), PAPER)
    d = ImageDraw.Draw(im)
    d.text((24, 12), "THE HOTEL'S INSIDE REWORKED FOR THE GRAND STAIR: two ways (the footprint as built, 80 x 50 ft)", fill=INK, font=font(22, True))
    d.text((24, 44), "Feet from the west corner; the street at the bottom. Brown: oak; red: the runner; arrows climb; blue: open to below; gold dots: newel lamps; green: the walk from the main doors to the stair's foot.", fill=SOFT, font=font(12))
    y = title_h
    for fn in (idea_a, idea_b):
        notes = fn(d, 0, y)
        for i, (s, b) in enumerate(notes):
            d.text((24, y + ph + 6 + i * 18), s, fill=INK if b else SOFT, font=font(12, b))
        y += ph + note_h
        d.line([(20, y - 12), (pw, y - 12)], fill=(200, 190, 170), width=2)
    out = os.path.join(HERE, "plan_ideas.png")
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main()
