#!/usr/bin/env python3
"""The Salt Creek Hotel's design drawings (#1146, docs/briefs/hotel.md): the cellar, ground and upper
plans, the front elevation and the gallery's section, drawn from the numbers below (feet; x east from
the main block's west front corner, y north, back from the front wall). A design, not a spec: step 2
(the spec on its lot) settles every size. Free, no calls:

    python3 docs/briefs/hotel/draw_plans.py      # -> docs/briefs/hotel/*.png
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
PAPER = (246, 241, 228)
INK = (34, 30, 26)
SOFT = (120, 110, 96)
FILL = {"public": (232, 220, 196), "service": (214, 220, 210), "private": (224, 214, 226),
        "guest": (236, 228, 210), "cellar": (214, 208, 196), "secret": (226, 196, 186), "stair": (205, 196, 180),
        "open": (240, 236, 226)}

S = 11  # pixels a foot
M = 110  # margin

# Main block 80 x 50; the kitchen wing 42 x 24 behind it (x 14-56); the gallery 8 ft over the walk.
MAIN = (0, 0, 80, 50)
WING = (14, 50, 56, 74)

GROUND = [
	("The bar", (0, 0, 22, 28), "public", "street door; trap to the beer cellar"),
	("Lobby and office", (22, 0, 50, 28), "public", "desk, key board, register; the grand stair"),
	("Ladies' parlour", (50, 0, 80, 28), "public", "ladies' entrance; piano"),
	("Sample room", (0, 28, 14, 50), "public", "drummers' trunks; lane door"),
	("Office", (14, 28, 24, 38), "private", "the safe"),
	("Back stair", (14, 38, 24, 50), "stair", ""),
	("Dining room", (24, 28, 80, 50), "public", "eight tables, sideboards"),
	("Back hall", (14, 50, 22, 74), "service", ""),
	("Serving pantry", (22, 50, 34, 60), "service", "swing doors"),
	("Scullery", (22, 60, 34, 74), "service", "sinks, pump"),
	("Kitchen", (34, 50, 56, 66), "service", "the hotel range"),
	("Store pantry", (34, 66, 44, 74), "service", ""),
	("Cook's room", (44, 66, 56, 74), "private", ""),
]
GROUND_STAIR = (30, 22, 47, 28)  # the grand stair along the lobby's back wall

UPPER = [
	("1", (0, 0, 10, 22), "guest", ""),
	("2", (10, 0, 20, 22), "guest", ""),
	("3", (20, 0, 30, 22), "guest", ""),
	("Suite parlour", (30, 0, 42, 22), "guest", "doors to gallery"),
	("Suite bed", (42, 0, 54, 22), "guest", "brass bed"),
	("4", (54, 0, 67, 22), "guest", "dressed room"),
	("5", (67, 0, 80, 22), "guest", ""),
	("Stair hall", (30, 22, 48, 28), "stair", ""),
	("Hall", (0, 28, 80, 34), "open", ""),
	("", (14, 34, 24, 38), "open", ""),
	("6", (0, 34, 14, 50), "guest", ""),
	("Back stair", (14, 38, 24, 50), "stair", ""),
	("Linen", (24, 34, 30, 40), "service", ""),
	("Bath", (24, 40, 30, 50), "service", "tin tub"),
	("7", (30, 34, 41, 50), "guest", ""),
	("8", (41, 34, 52, 50), "guest", ""),
	("Landlady", (52, 34, 66, 50), "private", "sitting room"),
	("Landlady", (66, 34, 80, 50), "private", "bedroom"),
	("Back hall", (14, 50, 22, 74), "open", ""),
	("9", (22, 50, 34, 62), "guest", "cheap: over the kitchen"),
	("10", (22, 62, 34, 74), "guest", ""),
	("11", (34, 50, 45, 66), "guest", ""),
	("Maids' room", (45, 50, 56, 66), "private", "three beds"),
	("Store", (34, 66, 56, 74), "service", "trunks"),
]
UPPER_FILL = [(0, 22, 30, 28), (48, 22, 80, 28)]  # wardrobe closets between the front rooms and the hall

CELLAR = [
	("Beer cellar", (0, 10, 24, 30), "cellar", "barrels on stillage; bulkhead to the lane"),
	("Stores", (24, 10, 48, 30), "cellar", "potatoes, flour, hams"),
	("Passage", (12, 30, 48, 36), "open", ""),
	("Coal", (0, 30, 12, 50), "cellar", "chute from the lane"),
	("Ice room", (12, 36, 28, 50), "cellar", "ice in sawdust; drain"),
	("Wine room", (28, 36, 48, 50), "cellar", "locked; racks"),
	("Cellar stair", (12, 50, 24, 60), "stair", "up to the back passage"),
]
SECRET = (48, 36, 60, 50)  # where the proposals put their door (unexcavated today)


def font(px, bold=False):
	return ImageFont.truetype(FONT_B if bold else FONT, px)


def canvas(w_ft, h_ft, title):
	w, h = int(w_ft * S + 2 * M), int(h_ft * S + 2 * M + 40)
	im = Image.new("RGB", (w, h), PAPER)
	d = ImageDraw.Draw(im)
	d.text((M, 18), title, fill=INK, font=font(26, True))
	return im, d


def px(x, y, y_top):
	"""Plan feet to pixels: the street (y 0) at the bottom of the drawing."""
	return M + x * S, M + 40 + (y_top - y) * S


def room(d, r, y_top, label, kind, note):
	x0, y0, x1, y1 = r
	a = px(x0, y1, y_top)
	b = px(x1, y0, y_top)
	d.rectangle([a, b], fill=FILL[kind], outline=INK, width=3)
	cx, cy = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
	size = 15 if (x1 - x0) >= 12 else 12
	d.text((cx, cy - (7 if note else 0)), label, fill=INK, font=font(size, True), anchor="mm")
	if note:
		d.text((cx, cy + 12), note, fill=SOFT, font=font(11), anchor="mm")


def scale_bar(d, x, y):
	for i in range(0, 4):
		d.rectangle([x + i * 10 * S, y, x + (i + 1) * 10 * S, y + 8], fill=INK if i % 2 == 0 else PAPER, outline=INK)
	d.text((x, y + 12), "0", fill=INK, font=font(12))
	d.text((x + 40 * S, y + 12), "40 ft", fill=INK, font=font(12), anchor="ra")


def street(d, y_top, label):
	a = px(-2, 0, y_top)
	b = px(82, -8, y_top)
	d.rectangle([a, b], fill=(236, 226, 206), outline=SOFT, width=1)
	d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), label, fill=SOFT, font=font(13), anchor="mm")
	d.text((px(40, -11, y_top)[0], px(40, -11, y_top)[1]), "MAIN STREET (south)", fill=INK, font=font(15, True), anchor="mm")
	d.text(px(-6, 25, y_top), "saloon lane", fill=SOFT, font=font(12), anchor="mm")
	d.text(px(86, 25, y_top), "lane", fill=SOFT, font=font(12), anchor="mm")


def plan(name, title, rooms, extra=None, wing=True):
	y_top = 78
	im, d = canvas(92, 92, title)
	street(d, y_top, {"ground": "the walk, the gallery over it (8 ft), turned posts every 10 ft", "upper": ""}.get(name, "the walk"))
	if name != "cellar":
		for i in range(9):
			c = px(i * 10, -7.5, y_top)
			d.rectangle([c[0] - 4, c[1] - 4, c[0] + 4, c[1] + 4], fill=INK)
	for lab, r, kind, note in rooms:
		room(d, r, y_top, lab, kind, note)
	if extra:
		extra(d, y_top)
	scale_bar(d, M, im.size[1] - 40)
	d.text((im.size[0] - M, im.size[1] - 34), "a design, not a spec: step 2 settles sizes", fill=SOFT, font=font(12), anchor="ra")
	im.save(os.path.join(HERE, name + ".png"))


def ground_extra(d, y_top):
	x0, y0, x1, y1 = GROUND_STAIR
	a, b = px(x0, y1, y_top), px(x1, y0, y_top)
	d.rectangle([a, b], fill=FILL["stair"], outline=INK, width=2)
	for i in range(18):
		x = a[0] + (b[0] - a[0]) * i / 18
		d.line([x, a[1], x, b[1]], fill=SOFT, width=1)
	d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), "grand stair, up east", fill=INK, font=font(11, True), anchor="mm")
	# doors on the street front
	for x, lab in ((16, "bar door"), (36, "main doors"), (75, "ladies' door")):
		c = px(x, 0, y_top)
		d.rectangle([c[0] - 20, c[1] - 3, c[0] + 20, c[1] + 3], fill=PAPER, outline=INK)
		d.text((c[0], c[1] + 14), lab, fill=INK, font=font(11), anchor="mm")
	d.text(px(58, 72, y_top), "the yard: privies,\nwash house, woodshed,\nthe pump, Back Street", fill=SOFT, font=font(12))


def upper_extra(d, y_top):
	for r in UPPER_FILL:
		a, b = px(r[0], r[3], y_top), px(r[2], r[1], y_top)
		d.rectangle([a, b], fill=(222, 214, 196), outline=INK, width=2)
		d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), "closets", fill=SOFT, font=font(11), anchor="mm")
	a, b = px(0, 0, y_top), px(80, -8, y_top)
	d.rectangle([a, b], outline=INK, width=3)
	d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 10), "THE GALLERY: 80 x 8 ft, railed, over the walk", fill=INK, font=font(13, True), anchor="mm")


def cellar_extra(d, y_top):
	a, b = px(SECRET[0], SECRET[3], y_top), px(SECRET[2], SECRET[1], y_top)
	for i in range(0, b[0] - a[0], 8):
		d.line([a[0] + i, a[1], a[0] + i, b[1]], fill=(170, 120, 110), width=1)
	d.rectangle([a, b], outline=(150, 60, 50), width=3)
	d.text(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2), "?", fill=(150, 60, 50), font=font(30, True), anchor="mm")
	d.text(((a[0] + b[0]) / 2, b[1] + 14), "the secret (§5)", fill=(150, 60, 50), font=font(11, True), anchor="mm")
	# the unexcavated part, dashed outline of the main block and the wing
	for r in (MAIN, WING):
		a, b = px(r[0], r[3], y_top), px(r[2], r[1], y_top)
		for x in range(a[0], b[0], 14):
			d.line([x, a[1], x + 7, a[1]], fill=SOFT, width=1)
			d.line([x, b[1], x + 7, b[1]], fill=SOFT, width=1)
		for y in range(a[1], b[1], 14):
			d.line([a[0], y, a[0], y + 7], fill=SOFT, width=1)
			d.line([b[0], y, b[0], y + 7], fill=SOFT, width=1)
	d.text(px(64, 25, y_top), "unexcavated\n(the floor above\non piers)", fill=SOFT, font=font(12))
	c = px(0, 18, y_top)
	d.polygon([(c[0] - 34, c[1] - 26), (c[0], c[1] - 26), (c[0], c[1] + 26), (c[0] - 34, c[1] + 26)], outline=INK, fill=(225, 215, 196))
	d.text((c[0] - 17, c[1]), "bulk-\nhead", fill=INK, font=font(10), anchor="mm")


# ---------------------------------------------------------------- the front and the section

FLOOR = 2.5        # the hotel's floor over the street's dirt (the walk's 0.75 m)
STOREY_1 = 13.5    # ground floor to the upper floor
STOREY_2 = 11.5    # upper floor to the frieze
FRIEZE = 1.5
CORNICE = 3.5      # the bracketed cornice and its parapet with the name
TOP = FLOOR + STOREY_1 + STOREY_2 + FRIEZE + CORNICE


def front():
	w_ft, h_ft = 112, TOP + 8
	im, d = canvas(w_ft, h_ft, "The front, from Main Street (south elevation)")
	base = M + 40 + h_ft * S - 3 * S

	def P(x, y):
		return M + (x + 6) * S, base - y * S

	d.line([P(-6, 0), P(86, 0)], fill=INK, width=2)  # the street
	# body
	d.rectangle([P(0, TOP - CORNICE - FRIEZE), P(80, FLOOR)], fill=(176, 190, 198), outline=INK, width=3)
	for y in [FLOOR + i * 0.6 for i in range(int((STOREY_1 + STOREY_2) / 0.6))]:
		d.line([P(0, y), P(80, y)], fill=(156, 170, 178), width=1)  # the clapboards
	# frieze and cornice
	fr0 = FLOOR + STOREY_1 + STOREY_2
	d.rectangle([P(-0.5, fr0 + FRIEZE), P(80.5, fr0)], fill=(236, 228, 206), outline=INK, width=2)
	d.rectangle([P(-1.5, fr0 + FRIEZE + 1.3), P(81.5, fr0 + FRIEZE + 0.9)], fill=(236, 228, 206), outline=INK, width=3)  # the cornice
	d.rectangle([P(6, TOP), P(74, fr0 + FRIEZE + 1.3)], fill=(120, 40, 36), outline=INK, width=2)  # the name board
	for i in range(17):
		x = i * 5
		d.polygon([P(x - 0.4, fr0 + FRIEZE + 0.9), P(x + 0.4, fr0 + FRIEZE + 0.9), P(x + 0.25, fr0), P(x - 0.25, fr0)], fill=(120, 40, 36), outline=INK)  # brackets
	d.text(((P(0, 0)[0] + P(80, 0)[0]) / 2, P(0, TOP - 1.1)[1]), "SALT CREEK HOTEL", fill=(214, 176, 74), font=font(26, True), anchor="mm")
	d.polygon([P(30, TOP), P(40, TOP + 4), P(50, TOP)], fill=(236, 228, 206), outline=INK)
	d.text((P(40, 0)[0], P(0, TOP + 1.4)[1]), "1881", fill=(150, 112, 30), font=font(16, True), anchor="mm")
	# corner boards
	for x in (0, 79.3):
		d.rectangle([P(x, fr0), P(x + 0.7, FLOOR)], fill=(236, 228, 206), outline=INK)
	# ground floor openings: bar window and door, lobby windows and doors, parlour windows, ladies' door
	g = FLOOR

	def opening(x, w, h, sill, door=False, arch=True, glass=(70, 80, 84)):
		d.rectangle([P(x - w / 2 - 0.4, g + sill + h + 0.8), P(x + w / 2 + 0.4, g + sill)], fill=(236, 228, 206), outline=INK)
		d.rectangle([P(x - w / 2, g + sill + h), P(x + w / 2, g + sill)], fill=glass, outline=INK, width=2)
		if arch:
			d.arc([P(x - w / 2, g + sill + h + w / 2), P(x + w / 2, g + sill + h - w / 2)], 180, 360, fill=INK, width=2)
		if door:
			d.line([P(x, g + sill + h - 2), P(x, g + sill)], fill=(236, 228, 206), width=3)
			d.line([P(x - w / 2, g + sill + h - 2), P(x + w / 2, g + sill + h - 2)], fill=(236, 228, 206), width=3)
		else:
			d.line([P(x - w / 2, g + sill + h * 0.55), P(x + w / 2, g + sill + h * 0.55)], fill=(236, 228, 206), width=2)

	for x in (7, 27, 45, 56, 66):
		opening(x, 5, 8.5, 1.5)
	for x, w in ((16, 4), (36, 6), (75, 4)):
		opening(x, w, 10, 0, door=True)
	# upper openings (behind the gallery)
	u = FLOOR + STOREY_1
	g = u
	for x in (5, 15, 25, 48, 60.5, 73.5):
		opening(x, 3.2, 6.5, 2.2, arch=False)
	opening(36, 5, 8.5, 0, door=True, arch=False)
	g = FLOOR
	# the gallery: deck, posts, railing, fascia
	deck = FLOOR + STOREY_1
	d.rectangle([P(-0.5, deck), P(80.5, deck - 1.1)], fill=(236, 228, 206), outline=INK, width=2)  # fascia
	for i in range(9):
		x = i * 10
		d.rectangle([P(x - 0.3, deck - 1.1), P(x + 0.3, FLOOR)], fill=(236, 228, 206), outline=INK, width=2)
		for t in (0.25, 0.5, 0.75):  # turnings
			y = FLOOR + (deck - 1.1 - FLOOR) * t
			d.ellipse([P(x - 0.5, y + 0.4), P(x + 0.5, y - 0.4)], fill=(236, 228, 206), outline=INK)
	d.line([P(-0.5, deck + 3), P(80.5, deck + 3)], fill=INK, width=4)  # the rail
	for i in range(0, 161):
		x = i * 0.5
		d.line([P(x, deck + 3), P(x, deck)], fill=INK, width=1)  # balusters
	d.line([P(-0.5, deck + 0.3), P(80.5, deck + 0.3)], fill=INK, width=2)
	# the walk and the steps
	d.rectangle([P(-2, FLOOR), P(82, FLOOR - 0.4)], fill=(150, 120, 90), outline=INK)
	for i in range(4):
		d.rectangle([P(31 - i * 0.6, FLOOR - 0.6 * (i + 1) + 0.6), P(41 + i * 0.6, FLOOR - 0.6 * (i + 1))], outline=INK, fill=(170, 140, 104))
	d.text((P(40, 0)[0], P(0, -1.6)[1]), "four easy steps, a wide flight (the walk 0.75 m over the street)", fill=SOFT, font=font(12), anchor="mm")
	# heights
	for y, lab in ((FLOOR, "floor"), (deck, "gallery deck / upper floor"), (fr0, "frieze"), (TOP, "cornice top")):
		d.line([P(83, y), P(85, y)], fill=INK, width=2)
		d.text((P(85.5, y)[0], P(0, y)[1]), "%s %.1f ft (%.2f m)" % (lab, y, y * 0.3048), fill=INK, font=font(11), anchor="lm")
	scale_bar(d, M, im.size[1] - 40)
	im.save(os.path.join(HERE, "front.png"))


def section():
	im, d = canvas(40, 30, "The gallery, in section (holds the Balcony Ambush)")
	base = M + 40 + 27 * S

	def P(x, y):
		return M + (x + 14) * S, base - y * S

	d.line([P(-14, 0), P(24, 0)], fill=INK, width=2)
	d.text(P(-6, -1), "street", fill=SOFT, font=font(12), anchor="mm")
	deck = FLOOR + STOREY_1
	# the front wall
	d.rectangle([P(8, deck + 11), P(8.6, FLOOR)], fill=(176, 190, 198), outline=INK, width=2)
	d.text(P(12, deck + 6), "upper floor\n(a guest room)", fill=SOFT, font=font(12), anchor="mm")
	d.text(P(12, FLOOR + 6), "lobby", fill=SOFT, font=font(12), anchor="mm")
	# the walk
	d.rectangle([P(0, FLOOR), P(8, FLOOR - 0.35)], fill=(170, 140, 104), outline=INK)
	d.rectangle([P(0.2, FLOOR - 0.35), P(0.8, 0)], fill=SOFT, outline=INK)
	# post, footing
	d.rectangle([P(0.2, deck - 1), P(0.8, FLOOR)], fill=(236, 228, 206), outline=INK, width=2)
	d.rectangle([P(-0.4, 0.2), P(1.4, -1.2)], fill=(190, 184, 170), outline=INK)
	d.text((P(-0.6, 0)[0], P(0, FLOOR + 5)[1]), "turned post 6x6,\nevery 10 ft (9)", fill=INK, font=font(12), anchor="rm")
	d.text((P(-0.6, 0)[0], P(0, -0.5)[1]), "stone footing", fill=INK, font=font(11), anchor="rm")
	# the beam, joists, ledger, deck
	d.rectangle([P(0, deck - 0.1), P(1, deck - 1.1)], fill=(205, 180, 140), outline=INK, width=2)
	d.text((P(-0.6, 0)[0], P(0, deck - 0.6)[1]), "beam: three 2x12s", fill=INK, font=font(12), anchor="rm")
	d.polygon([P(0, deck), P(8, deck + 0.2), P(8, deck - 0.6), P(0, deck - 0.8)], fill=(214, 194, 156), outline=INK)
	d.text(P(4, deck - 1.4), "2x10 joists at 16 in, 8 ft span", fill=INK, font=font(12), anchor="mm")
	d.rectangle([P(7.6, deck + 0.2), P(8, deck - 0.8)], fill=(205, 180, 140), outline=INK)
	d.text(P(12.5, deck - 0.4), "ledger bolted to\nthe floor's band", fill=INK, font=font(11), anchor="mm")
	d.line([P(0, deck + 0.05), P(8, deck + 0.25)], fill=INK, width=3)
	# railing
	d.line([P(0.1, deck + 3.2), P(0.1, deck)], fill=INK, width=3)
	d.line([P(-0.2, deck + 3.2), P(0.6, deck + 3.2)], fill=INK, width=5)
	d.text((P(-0.6, 0)[0], P(0, deck + 2.4)[1]), "rail 3 ft, turned balusters\n(breaks: men go over it)", fill=INK, font=font(12), anchor="rm")
	# men on it
	for x in (2.5, 5.5):
		d.ellipse([P(x - 0.45, deck + 5.9), P(x + 0.45, deck + 5.0)], outline=INK, width=2)
		d.line([P(x, deck + 5), P(x, deck + 2.6)], fill=INK, width=3)
		d.line([P(x, deck + 2.6), P(x - 0.5, deck + 0.2)], fill=INK, width=3)
		d.line([P(x, deck + 2.6), P(x + 0.5, deck + 0.2)], fill=INK, width=3)
	d.text(P(4, deck + 7), "the girder men, drinking", fill=INK, font=font(12, True), anchor="mm")
	# dims
	d.line([P(22, 0), P(22, deck)], fill=INK, width=1)
	d.text(P(22.4, deck / 2), "%.1f ft (%.2f m)\nstreet to deck" % (deck, deck * 0.3048), fill=INK, font=font(11), anchor="lm")
	d.text(P(4, -2.2), "the walk, 8 ft", fill=SOFT, font=font(12), anchor="mm")
	im.save(os.path.join(HERE, "gallery_section.png"))


def main():
	plan("ground", "Ground floor: lobby, bar, parlour, dining room; the kitchen wing", GROUND, ground_extra)
	plan("upper", "Upper floor: eleven rooms, the best suite, the landlady's, the maids'", UPPER, upper_extra)
	plan("cellar", "The cellar: beer, coal, ice, wine, stores (and the secret's place)", CELLAR, cellar_extra)
	front()
	section()


if __name__ == "__main__":
	main()
