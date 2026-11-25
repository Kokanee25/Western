#!/usr/bin/env python3
"""Layout A (the deep hall: plan_ideas.png) with the kitchen wing drawn in, behind the EAST half instead of the west,
so its serving pantry opens straight into the dining room (which A moves east). The wing as the brief's
(docs/briefs/hotel.md: 42 x 24 ft, two storeys, the kitchen, serving pantry, scullery, store pantry, the cook's
room, the back hall with the yard door and the cellar stair; rooms over the kitchen). Writes plan_a_kitchen.png.
Run: python3 docs/briefs/hotel/draw_plan_a_kitchen.py
"""
import os
from PIL import Image, ImageDraw

import draw_plan_ideas as ideas

base = ideas.base
HERE = os.path.dirname(os.path.abspath(__file__))
S, M = base.S, base.M
Plan, font, FILL = base.Plan, base.font, base.FILL
PAPER, INK, SOFT, OAK, LAND, VOID = base.PAPER, base.INK, base.SOFT, base.OAK, base.LAND, base.VOID
SKY = ideas.SKY
WING = 24 * S        # the wing stands 24 ft behind the main block: the plans start that much lower
KITCHEN = (236, 214, 200)


def ground(d, ox, oy):
    g = Plan(d, ox, oy + WING)
    d.text((ox + M, oy + 18), "GROUND FLOOR", fill=INK, font=font(16, True))
    g.street()
    g.room("bar", [0.3, 0.3, 21.8, 28.0])
    g.room("sample", [0.3, 28.3, 13.8, 49.7])
    g.room("stair_hall", [14.2, 28.3, 23.8, 49.7])
    g.room("lobby", [22.2, 0.3, 49.8, 28.0], label=" ")
    g.rect(24.2, 28.0, 47.8, 49.7, FILL["public"], width=3)
    g.room("office", [22.2, 0.3, 31.8, 9.8])
    g.room("parlour", [50.2, 0.3, 79.7, 28.0])
    g.room("dining", [50.2, 28.3, 79.7, 49.7], label="Dining room")
    g.rect(27.0, 27.7, 45.0, 28.6, FILL["public"], outline=FILL["public"], width=1)
    ideas.column(g, 26.6, 28.15)
    ideas.column(g, 45.4, 28.15)
    g.text(36, 26.6, "arch on two columns", 9, fill=SOFT)
    g.text(36, 14.5, "LOBBY", 13, True)
    g.rect(23.0, 11.0, 31.0, 13.0, (150, 100, 60), width=1)
    g.text(27.0, 12.0, "desk", 9, fill=(250, 240, 220))
    ideas.curtail(g, 36.0, 28.4, 7.0, "y")
    g.flight(32.5, 31.2, 39.5, 41.1, "y", 11)
    g.rect(24.2, 41.1, 47.8, 49.7, LAND)
    g.text(36, 46.8, "half landing (gilt mirror)", 9, True)
    ideas.flight_down(g, 24.4, 31.2, 28.4, 41.1, 11)
    ideas.flight_down(g, 43.6, 31.2, 47.6, 41.1, 11)
    g.text(36, 43.0, "under it: the staff way, back stair to kitchen", 8, fill=SOFT)
    ideas.walk_line(g, [(36, 1.2), (36, 27.8)])
    ideas.door(g, 36.0, 6.0, "main doors")
    ideas.door(g, 73.5, 3.5, "ladies' door")

    # the kitchen wing, behind the east half
    g.rect(38.0, 50.0, 80.0, 74.0, KITCHEN, width=4)
    g.room("back_hall", [38.3, 50.3, 47.3, 73.7], kind="service", label=" ")
    g.text(42.8, 70.5, "Back hall", 11, True)
    g.text(42.8, 68.8, "yard door", 8, fill=SOFT)
    g.flight(39.3, 52.0, 43.3, 64.0, "y", 12)
    g.text(45.3, 58.0, "cellar", 8, fill=SOFT)
    g.text(45.3, 56.6, "stair", 8, fill=SOFT)
    g.room("store", [47.7, 50.3, 57.3, 61.8], kind="service", label="Store pantry")
    g.room("cook", [47.7, 62.2, 57.3, 73.7], kind="private", label="Cook's room")
    g.room("serving", [57.7, 50.3, 69.7, 59.9], kind="service", label="Serving pantry")
    g.text(63.7, 52.4, "china, hot closet, swing doors", 7, fill=SOFT)
    g.room("scullery", [70.1, 50.3, 79.7, 59.9], kind="service", label="Scullery")
    g.text(74.9, 52.4, "pump, sink", 7, fill=SOFT)
    g.rect(57.7, 60.3, 79.7, 73.7, KITCHEN, width=3)
    g.text(68.7, 67.8, "KITCHEN", 13, True)
    g.rect(60.0, 71.0, 74.0, 73.4, (60, 55, 52), width=1)
    g.text(67.0, 72.2, "the hotel range", 8, fill=(240, 220, 190))
    g.rect(62.5, 63.0, 72.5, 65.5, (226, 210, 180), width=1)
    g.text(67.5, 64.2, "deal table", 8)
    # the doors that matter: pantry to dining, pantry to kitchen, the yard door
    for x0, x1, y in ((61.5, 65.5, 49.85), (61.5, 65.5, 60.1), (40.5, 44.5, 73.85)):
        a, b = g.p(x0, y + 0.5), g.p(x1, y - 0.5)
        d.rectangle([a, b], fill=PAPER, outline=INK, width=1)
    ideas.walk_line(g, [(66.0, 66.0), (63.5, 55.0), (63.5, 40.0)])
    g.text(58.0, 43.5, "a dish's way: about 20 ft", 9, True, fill=(40, 110, 60))
    g.text(30.0, 62.0, "the yard", 11, fill=SOFT)
    g.text(30.0, 60.3, "(the old wing's place)", 8, fill=SOFT)


def upper(d, ox, oy):
    u = Plan(d, ox, oy + WING)
    d.text((ox + M, oy + 18), "UPPER FLOOR", fill=INK, font=font(16, True))
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
    u.text(36, 39.8, "SKYLIGHT", 10, True, fill=(70, 90, 120))
    ideas.flight_down(u, 24.4, 31.2, 28.4, 41.1, 11)
    ideas.flight_down(u, 43.6, 31.2, 47.6, 41.1, 11)
    u.rail([(28.4, 41.1), (28.4, 31.2), (43.6, 31.2), (43.6, 41.1)])
    u.rail([(24.2, 28.0), (47.8, 28.0)])
    u.text(36, 29.6, "gallery over the stair", 8, True)
    u.room("hall", [48.2, 28.3, 51.9, 73.7], label=" ")
    u.text(50.05, 40.0, "passage", 8)
    # the wing upstairs
    u.rect(38.0, 50.0, 80.0, 74.0, KITCHEN, width=4)
    u.room("room_9", [38.3, 50.3, 47.8, 61.8], label="9")
    u.room("bath", [38.3, 62.2, 47.8, 73.7], kind="service", label="Bath")
    u.room("room_10", [52.3, 50.3, 65.8, 61.8], label="10")
    u.room("room_11", [66.2, 50.3, 79.7, 61.8], label="11")
    u.room("room_12", [52.3, 62.2, 79.7, 73.7], label="12")
    u.text(66.0, 66.0, "(over the range: warm and cheap)", 8, fill=SOFT)
    u.text(58.0, 57.5, "the cheap rooms", 8, fill=SOFT)


def main():
    pw = 80 * S + 2 * M + 30
    ph = 88 * S + 2 * M
    note_h = 9 * 18 + 30
    im = Image.new("RGB", (2 * pw + 20, 70 + ph + note_h), PAPER)
    d = ImageDraw.Draw(im)
    d.text((24, 12), "LAYOUT A, THE DEEP HALL, WITH THE KITCHEN WING BEHIND THE EAST HALF", fill=INK, font=font(22, True))
    d.text((24, 44), "Feet from the west corner; the street at the bottom, the yard at the top. Brown: oak; red: the runner; arrows climb; blue: open to below; green: the walk.", fill=SOFT, font=font(12))
    ground(d, 0, 70)
    upper(d, pw, 70)
    notes = [
        ("The kitchen wing (42 x 24 ft, two storeys, the brief's) moves from behind the west half to behind the east half, so it backs onto the", True),
        ("dining room that A moves east: the serving pantry's swing doors open straight into it, a dish carried about 20 ft from the range.", True),
        ("Ground: the kitchen (22 x 13 ft) with the hotel range and the deal table; the serving pantry (12 x 10) between it and the dining room;", False),
        ("the scullery with the pump and sink; the store pantry and the cook's room beside the kitchen; the back hall with the yard door and", False),
        ("the cellar stair, going down under the back wall into the cellar's wine room. The back hall opens into the staff way under the", False),
        ("landing, which runs west to the back stair, so the help reach the guests' floors without crossing the stair hall.", False),
        ("Upper: the old bath strip becomes a passage from the upper hall back into the wing; there, rooms 9 to 12 (the cheap rooms, 12 over", True),
        ("the range) and the bath. Rooms: 11 in the main block and 4 in the wing, 15 in all (13 + 3 = 16 in the old plan); the suite kept.", True),
        ("The yard (the old wing's place) behind the west half stays open: the back door, the drift and saloon B's lane are untouched.", False),
    ]
    for i, (s, b) in enumerate(notes):
        d.text((24, 70 + ph + 6 + i * 18), s, fill=INK if b else SOFT, font=font(12, b))
    out = os.path.join(HERE, "plan_a_kitchen.png")
    im.save(out)
    print("wrote", out, im.size)


if __name__ == "__main__":
    main()
