#!/usr/bin/env python3
"""The valley's overhead pictures from tools/valley/valley_overview.gd's tiles (Sean, 2026-11-09):
stitched north up, written plain and with the plan laid over it (valley_plan.py's roads, rail,
creek, arroyo and ditch, the pads, places and bridges by name), so what's built can be held against
what's planned. The .gd runs this itself at its end; on its own:

    python3 tools/valley/valley_overview.py --manifest=build/overview/manifest.json [--out=experiments/valley/results]

Writes overview_whole.jpg and overview_whole_plan.jpg (the 4.4 x 3.6 km envelope), and
overview_town.jpg, overview_canyon.jpg, overview_west.jpg (the close views, with the plan's names
and thin lines over them).
"""
import json
import math
import os
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import valley_plan  # noqa: E402  (the plan's own lines, never a copy of them)

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
# The plan's map colours (valley_plan.py's), RGBA.
ROAD = {"wagon": (120, 70, 30, 230), "lane": (150, 95, 45, 220), "track": (150, 110, 60, 210), "path": (160, 130, 90, 200), "street": (120, 70, 30, 230)}
RAIL = (30, 30, 35, 255)
WATER = (40, 110, 200, 235)
ARROYO = (176, 136, 80, 230)
PAD = (255, 255, 255, 200)
INK = (20, 20, 20, 255)


def opt(name, default=None):
	for a in sys.argv[1:]:
		if a.startswith("--%s=" % name):
			return a.split("=", 1)[1]
	return default


def font(size, bold=False):
	try:
		return ImageFont.truetype(FONT_B if bold else FONT, size)
	except OSError:
		return ImageFont.load_default()


def stitch(v):
	img = Image.new("RGB", (v["width"], v["height"]))
	for t in v["tiles"]:
		tile = Image.open(t["file"]).convert("RGB")
		img.paste(tile, tuple(t["px"]))
	return img


def to_px(v, x, z):
	return ((x - v["x0"]) * v["ppm"], (z - v["z0"]) * v["ppm"])


def label(d, xy, text, f, fill=INK):
	x, y = xy
	bb = d.textbbox((x, y), text, font=f)
	pad = max(2, f.size // 6)
	d.rectangle((bb[0] - pad, bb[1] - pad, bb[2] + pad, bb[3] + pad), fill=(255, 255, 255, 190))
	d.text((x, y), text, font=f, fill=fill)


def overlay(img, v, plan, scale):
	"""The plan's lines and names over a copy of `img` (`scale`: line widths and text, by the view)."""
	data = plan.data
	base = img.convert("RGBA")
	layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
	d = ImageDraw.Draw(layer)
	lw = max(1, round(2 * scale))
	W, H = base.size

	def line(pts, col, width, dash=None):
		p = [to_px(v, x, z) for x, z in pts]
		if dash is None:
			d.line(p, fill=col, width=width, joint="curve")
			return
		on, off = dash
		for (ax, ay), (bx, by) in zip(p, p[1:]):
			L = math.hypot(bx - ax, by - ay)
			s = 0.0
			while s < L:
				e = min(s + on, L)
				d.line([(ax + (bx - ax) * s / L, ay + (by - ay) * s / L), (ax + (bx - ax) * e / L, ay + (by - ay) * e / L)], fill=col, width=width)
				s += on + off

	# pads
	for p in data["places"]:
		pd = p.get("pad")
		if not pd:
			continue
		hd = math.radians(pd.get("heading", 90))
		ux, uz = math.sin(hd), -math.cos(hd)
		vx, vz = -uz, ux
		cx, cz = p["at"]
		w, dd = pd["w"] * 0.5, pd["d"] * 0.5
		corners = [(cx + ux * a + vx * b, cz + uz * a + vz * b) for a, b in ((-w, -dd), (w, -dd), (w, dd), (-w, dd), (-w, -dd))]
		line(corners, PAD, lw)
	# water
	for key, col in (("creek", WATER), ("arroyo", ARROYO)):
		L = data["water"][key]["line"]
		line([(q[0], q[1]) for q in L], col, max(1, round(3 * scale)), None if key == "creek" else (12 * scale, 6 * scale))
	line([(q[0], q[1]) for q in data["water"]["ditch"]["line"]], WATER, lw, (4 * scale, 4 * scale))
	# roads (and the town's streets, as valley_plan.py lays them)
	for r in list(data["roads"]) + [dict(t, **{"class": "street"}) for t in valley_plan.town_roads(data)]:
		line([(q[0], q[1]) for q in r["line"]], ROAD.get(r.get("class", "wagon"), ROAD["wagon"]), lw)
	# rail, to the west portal
	r = plan.rail
	m = plan.marks
	pts = [(x, z) for s, x, z in zip(r["s"], r["x"], r["z"]) if s <= m["west_portal"]][::4]
	line(pts, RAIL, max(2, round(3 * scale)))
	line(pts, (255, 255, 255, 230), max(1, round(1.2 * scale)), (6 * scale, 10 * scale))
	# names: places, bridges, viewpoints left out (too many); the view's own size of text
	f = font(max(11, round(15 * scale)))
	fb = font(max(12, round(17 * scale)), True)
	for p in data["places"]:
		x, y = to_px(v, *p["at"])
		if not (0 <= x < W and 0 <= y < H):
			continue
		rr = max(2, round(4 * scale))
		d.ellipse((x - rr, y - rr, x + rr, y + rr), fill=(220, 40, 40, 255), outline=(255, 255, 255, 255))
		label(d, (x + rr + 3, y - rr), p.get("name", p["id"]), f)
	for b in data["bridges"]:
		at = b.get("_at") or b.get("at")
		if not at:
			continue
		x, y = to_px(v, *at)
		if 0 <= x < W and 0 <= y < H:
			label(d, (x + 6, y + 6), b.get("name", b["id"]), fb, fill=(110, 60, 20, 255))
	return Image.alpha_composite(base, layer).convert("RGB")


def furniture(img, v, title, scale):
	"""Title, north arrow and a scale bar (the picture's own, plain or not)."""
	d = ImageDraw.Draw(img, "RGBA")
	W, H = img.size
	f = font(max(14, round(22 * scale)), True)
	fs = font(max(11, round(15 * scale)))
	label(d, (20, 16), title, f)
	# north arrow, top right
	ax, ay, s = W - 60 * scale - 20, 30 * scale + 20, 30 * scale
	d.polygon([(ax, ay - s), (ax - s * 0.5, ay + s * 0.6), (ax, ay + s * 0.25), (ax + s * 0.5, ay + s * 0.6)], fill=(20, 20, 20, 230), outline=(255, 255, 255, 255))
	label(d, (ax - 6 * scale, ay + s * 0.7), "N", f)
	# scale bar, bottom left: a round length near a fifth of the width
	want = W / v["ppm"] / 5.0
	m = 10 ** math.floor(math.log10(want))
	for k in (5, 2, 1):
		if k * m <= want:
			m *= k
			break
	L = m * v["ppm"]
	x0, y0 = 30, H - 40 * scale - 10
	d.rectangle((x0 - 8, y0 - 26 * scale, x0 + L + 8, y0 + 14 * scale), fill=(255, 255, 255, 190))
	for i in range(4):
		d.rectangle((x0 + L * i / 4, y0, x0 + L * (i + 1) / 4, y0 + 8 * scale), fill=(20, 20, 20, 255) if i % 2 == 0 else (255, 255, 255, 255), outline=(20, 20, 20, 255))
	d.text((x0, y0 - 22 * scale), "%d m" % m if m < 1000 else "%g km" % (m / 1000), font=fs, fill=INK)
	return img


def commit():
	try:
		return subprocess.run(["git", "-C", ROOT, "log", "-1", "--format=%h %ad", "--date=short"], capture_output=True, text=True).stdout.strip()
	except OSError:
		return ""


def main():
	man = json.load(open(opt("manifest", os.path.join(ROOT, "build", "overview", "manifest.json"))))
	out = opt("out", os.path.join(ROOT, "experiments", "valley", "results"))
	if not os.path.isabs(out):
		out = os.path.join(ROOT, out)
	os.makedirs(out, exist_ok=True)
	plan = valley_plan.Plan()
	when = commit()
	titles = {"whole": "Salt Creek valley greybox, north up", "town": "The town", "canyon": "The canyon: Bridge A, the great trestle, Bridge B", "west": "The west: the mine and the Ore Works"}
	for v in man["views"]:
		img = stitch(v)
		title = "%s (%s, %02d:00, %g px/m)" % (titles.get(v["name"], v["name"]), when, int(man.get("hour", 12)), v["ppm"])
		scale = max(1.0, v["width"] / 2200.0)
		if v["name"] == "whole":
			furniture(img.copy(), v, title, scale).save(os.path.join(out, "overview_whole.jpg"), quality=85)
			furniture(overlay(img, v, plan, scale), v, title + ", the plan over it", scale).save(os.path.join(out, "overview_whole_plan.jpg"), quality=85)
		else:
			furniture(overlay(img, v, plan, scale * 0.8), v, title + ", the plan over it", scale).save(os.path.join(out, "overview_%s.jpg" % v["name"]), quality=85)
		print("wrote overview_%s (%d x %d)" % (v["name"], v["width"], v["height"]))


if __name__ == "__main__":
	main()
