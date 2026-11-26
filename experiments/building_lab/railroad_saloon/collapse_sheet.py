#!/usr/bin/env python3
"""The Railroad Saloon's collapse, drawn from its spec (#1285): the dance floor's plan with the crowd, the band and
the sawn bay; the long section through the girder (its three bays, the cut, the posts); the cross-section through
the sawn bay (the joists hinging on the side walls' ribbons onto the bar and the tables). North up, east on the right.

    python3 experiments/building_lab/railroad_saloon/collapse_sheet.py   # -> plan/collapse.png
"""
import json
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))
SPEC = os.path.join(ROOT, "config", "buildings", "railroad_saloon.json")
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "plan", "collapse.png")
S = 60
INK, RED, BLUE, GREEN, PALE, HATCH = (25, 20, 15), (190, 40, 30), (40, 80, 170), (40, 120, 50), (247, 242, 230), (240, 200, 190)


def font(n, bold=False):
	try:
		return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if bold else ""), n)
	except OSError:
		return ImageFont.load_default()


def main():
	sp = json.load(open(SPEC))
	W, D = sp["lot"]["width"], sp["lot"]["depth"]
	lv = sp["levels"]
	g_top, u_top, plate = lv["ground"]["top"], lv["upper"]["top"], lv["plate"]
	gx = sp["posts"]["free"][0][0]
	pz = [p[1] for p in sp["posts"]["free"]]
	beam = sp["frame"]["beam"]["section"]
	joist = sp["frame"]["dance_joist"]["section"]
	im = Image.new("RGB", (1500, 1230), PALE)
	d = ImageDraw.Draw(im)
	d.text((30, 18), "The Silver Spike: the dance floor's collapse, from the spec (#1285)", fill=INK, font=font(26, True))
	d.text((30, 54), "red hatch: the sawn bay (beam/spine/1, 10 ft) and the floor that falls; green: the crowd; blue: the band", fill=INK, font=font(17))

	# --- the upstairs plan (x mirrored: east on the right)
	ox, oy = 110, 215

	def P(x, z):
		return (ox + (W - x) * S, oy + (D - z) * S)
	d.text((ox, oy + D * S + 78), "UPSTAIRS: the dance floor (7.1 x 8.9 m)", fill=INK, font=font(19, True))
	d.rectangle([P(W, D), P(0, 0)], outline=INK, width=6)
	d.rectangle([P(W - 0.1, pz[1]), P(0.1, pz[0])], fill=HATCH)
	for k in range(0, 40):
		x0 = W - 0.1 - k * 0.35
		if x0 < 0.1:
			break
		d.line([P(x0, pz[1]), P(max(0.1, x0 - 0.9), pz[0])], fill=RED, width=1)
	d.line([P(gx, 0.1), P(gx, D - 0.1)], fill=INK, width=2)
	for z in pz:
		d.rectangle([P(gx + 0.075, z + 0.075), P(gx - 0.075, z - 0.075)], fill=INK)
	d.text(P(gx - 0.1, pz[0] - 0.4), "girder's line, posts below", fill=INK, font=font(13))
	d.text(P(3.3, (pz[0] + pz[1]) / 2 + 0.35), "THE SAWN BAY\n21.6 m2\n~12 dancers\non it", fill=RED, font=font(16, True))
	for b in sp["dressing"]["batches"]["plan"]:
		if b["kit"] == "wall_bench":
			x, _, z = b["at"]
			n = b.get("repeat", {}).get("count", 1)
			for i in range(n):
				zz = z + i * b.get("repeat", {}).get("step", [0, 0])[1]
				if b["facing"] in (90, 270):
					d.rectangle([P(x + 0.2, zz + 1.0), P(x - 0.2, zz - 1.0)], outline=INK, fill=(225, 214, 190))
				else:
					d.rectangle([P(x + 1.0, zz + 0.2), P(x - 1.0, zz - 0.2)], outline=INK, fill=(225, 214, 190))
		if b["kit"] == "upright_piano":
			x, _, z = b["at"]
			d.rectangle([P(x + 0.75, z + 0.3), P(x - 0.75, z - 0.3)], fill=INK)
			d.text(P(x + 0.7, z - 0.4), "piano (carried up)", fill=INK, font=font(13))
	for u in sp["use_points"]:
		if u["at"][1] < u_top - 0.01:
			continue
		col = BLUE if u["who"] == "band" else GREEN
		x, _, z = u["at"]
		d.ellipse([P(x + 0.15, z + 0.15), P(x - 0.15, z - 0.15)], fill=col)
	door_x = [o for w in sp["walls"] if w["id"] == "back" for o in w["openings"] if o["type"] == "door" and o["level"] == "upper"][0]["at"]
	for bal in sp.get("balconies", []):
		for dk in bal["decks"]:
			x0, z0, x1, z1 = dk["rect"]
			d.rectangle([P(x1, z1), P(x0, z0)], outline=INK, fill=(236, 228, 210))
	d.text(P(door_x - 0.3, D + 0.85), "landing", fill=INK, font=font(12))
	d.rectangle([P(door_x + 0.4, D + 0.12), P(door_x - 0.4, D - 0.12)], fill=RED)
	st = sp["stairs"][0]
	sx0, sx1 = st["head"][0], st["head"][0] + st["width"]
	foot = st["head"][1] - (st["risers"] - 1) * st["going"]
	d.rectangle([P(sx1, st["head"][1]), P(sx0, foot)], outline=INK, fill=(236, 228, 210))
	d.text(P(sx1 + 0.75, foot - 0.2), "outside\nstair,\n17R down\nto the\nfront.", fill=INK, font=font(12))
	d.text(P(sx1 + 0.75, foot - 1.6), "Its door\n(red, in the\nback gable\nover the\nlanding):\nTHE JAM", fill=RED, font=font(13, True))
	d.text(P(W, -0.25), "FRONT (Back Street)", fill=INK, font=font(14))
	d.text(P(W - 2.6, D + 1.75), "BACK (the pens, the tracks)", fill=INK, font=font(14))
	d.text(P(-0.1, D * 0.5), "E", fill=INK, font=font(16, True))
	d.text(P(W + 1.6, D * 0.15), "W", fill=INK, font=font(16, True))
	# the crowd's count
	ups = [u for u in sp["use_points"] if u["at"][1] >= u_top - 0.01]
	d.text((ox, oy + D * S + 30), "Payday: 40 up: ~28 dancing (12 marked: the middle set),\n~8 on the benches, 4 in the band. Below: ~15 drinkers.",
		fill=INK, font=font(15))

	# --- the long section along the girder (z left to right: front to back)
	sx, sy = 640, 470
	Z = 70

	def L(z, y):
		return (sx + z * Z, sy - y * Z)
	d.text((sx, 110), "LONG SECTION on the girder's line (front left, back right)", fill=INK, font=font(19, True))
	d.line([L(-0.5, 0), L(D + 1.5, 0)], fill=INK, width=2)
	d.rectangle([L(0, g_top), L(D, g_top - 0.05)], fill=INK)
	bt = u_top - joist[1] - 0.025
	for i, (a, b) in enumerate([(0.1, pz[0]), (pz[0], pz[1]), (pz[1], D - 0.1)]):
		if i == 1:
			mid = (a + b) / 2
			d.rectangle([L(a, bt), L(mid - 0.15, bt - beam[1])], fill=RED)
			d.rectangle([L(mid + 0.15, bt), L(b, bt - beam[1])], fill=RED)
			d.polygon([L(mid - 0.15, bt - beam[1]), L(mid - 0.15, bt - beam[1] + 0.229), L(mid + 0.15, bt - beam[1] + 0.229), L(mid + 0.15, bt - beam[1])], fill=PALE)
			d.text(L(mid - 1.4, bt - beam[1] - 0.25), "sawn 9 of 12 in from below\n(the pale kerf a lamp finds)", fill=RED, font=font(13, True))
		else:
			d.rectangle([L(a, bt), L(b, bt - beam[1])], fill=(140, 110, 80), outline=INK)
	for z in pz:
		d.rectangle([L(z - 0.075, bt - beam[1]), L(z + 0.075, g_top)], fill=(140, 110, 80), outline=INK)
	d.rectangle([L(0, u_top), L(D, u_top - joist[1] - 0.025)], outline=INK, fill=(200, 180, 150))
	d.rectangle([L(pz[0], u_top), L(pz[1], u_top - joist[1] - 0.025)], fill=HATCH, outline=RED)
	d.line([L(0, u_top), L(0, plate)], fill=INK, width=3)
	d.line([L(D, u_top), L(D, plate)], fill=INK, width=3)
	d.text(L(0.1, u_top + 0.4), f"dance floor {u_top:.2f} m", fill=INK, font=font(13))
	d.text(L(0.1, g_top + 0.25), f"bar room {g_top:.2f} m (2.29 m clear under the girder)", fill=INK, font=font(13))
	d.rectangle([L(pz[0] + 0.02, g_top + 1.07), L(pz[1] - 0.02, g_top)], outline=INK, fill=(170, 130, 90))
	d.text(L(pz[0] + 0.5, g_top + 0.75), "THE BAR (east wall)", fill=PALE, font=font(13, True))
	d.text(L(D - 2.6, u_top + 1.2), "piano, band\n(back bay: holds)", fill=BLUE, font=font(13, True))
	d.text(L(0.3, u_top + 1.2), "front bay: holds", fill=INK, font=font(13))

	# --- the cross-section through the sawn bay (x: east right)
	cx, cy = 640, 1170
	X = 60

	def C(x, y):
		return (cx + (W - x) * X, cy - y * X)
	d.text((cx, 650), "CROSS-SECTION through the sawn bay, looking north (east right)", fill=INK, font=font(19, True))
	d.line([C(W + 1.5, 0), C(-0.5, 0)], fill=INK, width=2)
	for x in (0, W):
		d.line([C(x, 0), C(x, plate)], fill=INK, width=4)
	d.line([C(W, plate), C(gx, lv["plate"] + gx * 10 / 12), C(0, plate)], fill=INK, width=3)
	d.rectangle([C(gx + 0.075, bt), C(gx - 0.075, bt - beam[1])], fill=RED)
	# the joists hinging down from the ribbons
	d.line([C(0.05, bt), C(gx - 0.1, g_top + 1.1)], fill=RED, width=6)
	d.line([C(W - 0.05, bt), C(gx + 0.1, g_top + 0.8)], fill=RED, width=6)
	d.line([C(0.05, bt), C(gx, bt)], fill=(200, 160, 150), width=2)
	d.line([C(W - 0.05, bt), C(gx, bt)], fill=(200, 160, 150), width=2)
	d.text(C(gx - 0.2, bt + 0.25), "before", fill=(150, 110, 100), font=font(12))
	d.rectangle([C(2.3, g_top + 1.07), C(1.7, g_top)], fill=(170, 130, 90), outline=INK)
	d.rectangle([C(0.85, g_top + 1.4), C(0.1, g_top)], outline=INK)
	d.text(C(0.95, g_top + 1.6), "racks", fill=INK, font=font(12))
	d.text(C(2.4, g_top + 1.3), "bar", fill=INK, font=font(12))
	d.rectangle([C(6.0, g_top + 0.75), C(4.6, g_top + 0.7)], fill=INK)
	d.text(C(6.0, g_top + 1.0), "tables", fill=INK, font=font(12))
	d.text(C(W + 0.1, bt - 0.4), "west half hinges\non the stair wall's ribbon", fill=RED, font=font(12))
	d.text(C(1.6, bt + 0.95), "east half hinges on\nthe yard wall's ribbon:\ndown onto the bar", fill=RED, font=font(12))
	d.text(C(W + 1.4, 0.4), "fall: %.1f m (9.4 ft)" % (u_top - g_top), fill=INK, font=font(13, True))
	os.makedirs(os.path.dirname(OUT), exist_ok=True)
	im.save(OUT)
	print(os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
	main()
