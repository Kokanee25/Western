#!/usr/bin/env python3
"""The valley town's boardwalks at each lot's own height (#737): the table and Main Street's elevation.

    python3 tools/valley/town_walks.py            # docs/concept/valley-walks.png + docs/briefs/valley-walks.md
    python3 tools/valley/town_walks.py --check    # the checks only (exit 1 on a FAIL)

Reads config/valley.json (`town.main_street`, `town.walks`' rules, each building lot's `walk`) and the
baked ground (config/valley_ground/), and lays the walks out by the same rules as the game's
`ValleyTown` (src/world/valley_town.gd): a walk is level, its height `h` over the ground at its
street edge's middle; neighbours over a tight gap join with a flight (or a ramp) on the higher one;
elsewhere its ends step down to the ground, ramp, or drop; a flight of steps (or a ramp) to the
street at its door; treads of at most `riser_max`, ramps 1 in `ramp_slope`; a rail along the street
edge from `rail_at` over the dirt, posts and room under it from `posts_at`. Change a rule there,
change it here.

Both sides are drawn with west on the left (the north side as you see it from the street; the
south side as if seen through from the north), so the two rows line up at the crossroads. Heights
are drawn 2.5 times their length.
"""
import argparse
import gzip
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONFIG = os.path.join(ROOT, "config", "valley.json")
BAKE = os.path.join(ROOT, "config", "valley_ground")
PNG = os.path.join(ROOT, "docs", "concept", "valley-walks.png")
TABLE = os.path.join(ROOT, "docs", "briefs", "valley-walks.md")

TIGHT = 1.0          # ValleyTown.TIGHT: a gap narrower than this is shoulder to shoulder
FLIGHT_W = 1.8       # ValleyTown.FLIGHT_W
VE = 2.5             # vertical exaggeration of the drawing
STOREY = 4.6         # a block drawn this far over its floor (one storey and a false front)
TWO_STOREY = {"saloon": 9.6, "hotel": 8.6}


class Ground:
	"""The bake (heights.json, heights.r16.gz), bilinear as ValleyTerrain.height."""

	def __init__(self):
		h = json.load(open(os.path.join(BAKE, "heights.json")))
		raw = gzip.open(os.path.join(BAKE, h["file"])).read()
		self.a = np.frombuffer(raw, dtype="<u2").reshape(h["depth"], h["width"]).astype(np.float64)
		self.h = h

	def __call__(self, x, z):
		h = self.h
		fx = (x - h["x0"]) / h["spacing"]
		fz = (z - h["z0"]) / h["spacing"]
		i, j = int(math.floor(fx)), int(math.floor(fz))
		tx, tz = fx - i, fz - j
		a = self.a
		v = (a[j, i] * (1 - tx) + a[j, i + 1] * tx) * (1 - tz) + (a[j + 1, i] * (1 - tx) + a[j + 1, i + 1] * tx) * tz
		return h["offset"] + h["scale"] * v


def treads(rise, riser):
	return max(1, math.ceil(rise / riser - 1e-6)) if rise > 0.02 else 0


def lay_out(data, g):
	"""Every walk on both sides, west to east: a dict each (see the keys below)."""
	t = data["town"]
	ms = t["main_street"]
	rules = t.get("walks", {})
	riser = float(rules.get("riser_max", 0.2))
	slope = float(rules.get("ramp_slope", 8))
	rail_at = float(rules.get("rail_at", 1.0))
	posts_at = float(rules.get("posts_at", 0.8))
	tread = float(rules.get("tread", 0.3))
	front = float(ms["width_between_fronts"]) * 0.5
	depth = float(ms["boardwalk_depth"])
	out = {}
	for side in ("north", "south"):
		sgn = -1.0 if side == "north" else 1.0
		edge = sgn * (front - depth)
		lots = sorted(t[side], key=lambda l: l["x0"])
		bs = [l for l in lots if l["kind"] == "building"]
		walks = []
		for i, b in enumerate(bs):
			w = dict(b.get("walk", {}))
			if w.get("none"):
				walks.append({"id": b["id"], "name": b["name"], "side": side, "x0": b["x0"], "x1": b["x1"], "none": True,
					"why": w.get("why", ""), "ground": g((b["x0"] + b["x1"]) * 0.5, edge)})
				continue
			x1 = b["x1"]
			nb = bs[i + 1] if i + 1 < len(bs) else None
			pb = bs[i - 1] if i > 0 else None
			join_e = nb if nb and nb["x0"] - b["x1"] < TIGHT and not nb.get("walk", {}).get("none") else None
			join_w = pb if pb and b["x0"] - pb["x1"] < TIGHT and not pb.get("walk", {}).get("none") else None
			if join_e:
				x1 = nb["x0"]
			xm = (b["x0"] + x1) * 0.5
			y = g(xm, edge)
			h = float(w.get("h", 0.38))
			door = (b["x0"] + b["x1"]) * 0.5
			walks.append({"id": b["id"], "name": b["name"], "side": side, "x0": b["x0"], "x1": x1, "lot_x1": b["x1"],
				"ground": y, "h": h, "top": y + h, "door": door, "door_kind": w.get("door", "steps"),
				"door_w": float(w.get("door_w", FLIGHT_W)), "awning": float(w.get("awning", 0)),
				"end_w": w.get("w", "steps"), "end_e": w.get("e", "steps"), "join_w": join_w["id"] if join_w else "",
				"join_e": join_e["id"] if join_e else "", "why": w.get("why", "")})
		by_id = {w["id"]: w for w in walks}
		for w in walks:
			if w.get("none"):
				continue
			# The door's flight (or ramp) down to the street before it.
			gd = g(w["door"], sgn * (front - depth - 0.6))
			rise = w["top"] - gd
			w["door_rise"] = rise
			w["door_n"] = treads(rise, riser) if w["door_kind"] == "steps" else 0
			w["door_run"] = rise * slope if w["door_kind"] == "ramp" else w["door_n"] * tread
			# Each end: joined to a neighbour (the higher walk carries the flight), else to the ground.
			for end in ("w", "e"):
				ex = w["x0"] if end == "w" else w["x1"]
				nid = w["join_" + end]
				kind = w["end_" + end]
				info = {"kind": kind, "x": ex}
				if nid:
					o = by_id[nid]
					diff = w["top"] - o["top"]
					wants = "ramp" if "ramp" in (kind, o["end_" + ("e" if end == "w" else "w")]) else "steps"
					info.update({"to": nid, "rise": diff, "kind": "join"})
					if diff > 0.02:
						info["flight"] = wants
						info["n"] = treads(diff, riser) if wants == "steps" else 0
						info["run"] = diff * slope if wants == "ramp" else info["n"] * tread
					else:
						info["flight"] = "level" if abs(diff) <= 0.02 else "theirs"
						info["n"] = 0
						info["run"] = 0.0
				else:
					ge = max(g(ex, sgn * front), g(ex, edge))
					rise = w["top"] - ge
					info["rise"] = rise
					info["flight"] = kind
					info["n"] = treads(rise, riser) if kind == "steps" else 0
					info["run"] = rise * slope if kind == "ramp" else info["n"] * tread if kind == "steps" else 0.0
				w["ends"] = w.get("ends", {})
				w["ends"][end] = info
			w["rail"] = w["h"] >= rail_at - 1e-6
			w["posts"] = w["h"] >= posts_at - 1e-6
			# The clear height under the walk at the building's wall (the ground rises toward a north front).
			w["under"] = w["top"] - 0.2 - g(w["door"], sgn * front)
		out[side] = walks
	return out, {"riser": riser, "slope": slope, "rail_at": rail_at, "posts_at": posts_at, "front": front, "depth": depth}


def checks(lay, rules):
	res = []
	ok = True
	for side, walks in lay.items():
		for w in walks:
			if w.get("none"):
				continue
			for what, n, rise in [("door", w["door_n"], w["door_rise"])] + [(e, w["ends"][e]["n"], w["ends"][e]["rise"]) for e in ("w", "e")]:
				if n and rise / n > rules["riser"] + 1e-6:
					ok = False
					res.append("FAIL %s %s: %.2f m in %d treads" % (w["id"], what, rise, n))
			for e in ("w", "e"):
				info = w["ends"][e]
				run = info.get("run", 0.0)
				if what == "x" and run > (w["x1"] - w["x0"]) * 0.5:
					ok = False
			span = w["x1"] - w["x0"]
			used = w["ends"]["w"].get("run", 0) + w["ends"]["e"].get("run", 0)
			if used > span - w["door_w"] - 0.5:
				ok = False
				res.append("FAIL %s: its end flights take %.1f of its %.1f m" % (w["id"], used, span))
	res.append("%s every tread at most %.2f m, every walk room for its flights" % ("PASS" if ok else "FAIL", rules["riser"]))
	return ok, res


# --------------------------------------------------------------------------------------- drawing

def draw(lay, rules, g, path):
	import matplotlib
	matplotlib.use("Agg")
	import matplotlib.pyplot as plt
	from matplotlib.patches import Polygon, Rectangle

	data = json.load(open(CONFIG))
	t = data["town"]
	front, depth = rules["front"], rules["depth"]
	halves = [(-125.0, 0.0), (0.0, 130.0)]
	fig, axes = plt.subplots(4, 1, figsize=(26, 31), dpi=100)
	C = {"ground": "#a07e57", "dirt": "#d8c3a0", "walk": "#8a5a2b", "block": "#e9e3d8", "edge": "#6b6257",
		"step": "#5a3a1a", "rail": "#2c4a6e", "awning": "#9c3d2a", "drop": "#c0392b", "ramp": "#3d7a3d", "gap": "#7a6a55"}
	rows = [("north", halves[0]), ("north", halves[1]), ("south", halves[0]), ("south", halves[1])]
	for ax, (side, (xa, xb)) in zip(axes, rows):
		sgn = -1.0 if side == "north" else 1.0
		edge = sgn * (front - depth)
		xs = np.linspace(xa - 2, xb + 2, 400)
		gy = np.array([g(x, edge) for x in xs])
		ax.fill_between(xs, gy, -2.0, color=C["dirt"], zorder=0)
		ax.plot(xs, gy, color=C["ground"], lw=1.5, zorder=1)
		# The lots that aren't buildings: their names on the dirt.
		for l in t[side]:
			if l["kind"] in ("building", "tight") or l["x1"] < xa or l["x0"] > xb:
				continue
			xm = (max(l["x0"], xa) + min(l["x1"], xb)) * 0.5
			label = l["name"].split(" (")[0]
			if l["kind"] == "alley":
				label = label.replace("Undertaker's alley", "alley") + "\n1.2 m"
			ax.text(xm, g(xm, edge) - 0.55, label, ha="center", va="top", fontsize=8, color=C["gap"], style="italic",
				rotation=90 if l["x1"] - l["x0"] < 4 else 0, zorder=6)
			if l["kind"] in ("yard", "vacant", "houses"):
				ax.text(xm, g(xm, edge) + 0.25, "no walk: down into the dirt", ha="center", fontsize=7.5, color=C["drop"], zorder=6)
		if xa < 0 < xb or xa == 0.0 or xb == 0.0:
			xc = 0.0
			ax.axvspan(-7.6, 7.6, color="#efe6d2", zorder=0.5)
			ax.text(0 if xa < 0 < xb else (xa + 3.8 if xa == 0 else xb - 3.8), g(0, edge) - 0.55, "North-South\nStreet",
				ha="center", va="top", fontsize=8, color=C["gap"], style="italic", zorder=6)
		for w in lay[side]:
			if w["x1"] < xa - 0.5 or w["x0"] > xb + 0.5:
				continue
			if w.get("none"):
				x0, x1 = w["x0"], w["x1"]
				gb = min(g(x0, sgn * front), g(x1, sgn * front))
				ax.add_patch(Rectangle((x0, gb), x1 - x0, STOREY, facecolor=C["block"], edgecolor=C["edge"], lw=0.8, zorder=2))
				ax.text((x0 + x1) * 0.5, gb + STOREY - 0.4, "%s\nno walk" % short(w["name"]), ha="center", va="top", fontsize=9, zorder=7)
				continue
			top = w["top"]
			x0, x1 = w["x0"], w["x1"]
			# The block behind it: from its floor (the walk's top) up.
			bx1 = w["lot_x1"]
			hgt = TWO_STOREY.get(w["id"], STOREY)
			gb = min(g(x0, sgn * front), g(bx1, sgn * front))
			ax.add_patch(Rectangle((w["x0"], gb), bx1 - w["x0"], top + hgt - gb, facecolor=C["block"], edgecolor=C["edge"], lw=0.8, zorder=2))
			# The walk: its deck, then posts open underneath or a skirting to the ground.
			lo = w["ends"]["w"]["run"] if w["ends"]["w"].get("flight") in ("steps", "ramp") else 0.0
			hi = w["ends"]["e"]["run"] if w["ends"]["e"].get("flight") in ("steps", "ramp") else 0.0
			d0, d1 = x0 + lo, x1 - hi
			ax.add_patch(Rectangle((d0, top - 0.18), d1 - d0, 0.18, facecolor=C["walk"], edgecolor="none", zorder=4))
			if w["posts"]:
				px = d0 + 0.15
				while px < d1:
					ax.plot([px, px], [g(px, edge), top - 0.18], color=C["walk"], lw=2.2, zorder=3)
					px += 2.4
				ax.plot([d1 - 0.15] * 2, [g(d1, edge), top - 0.18], color=C["walk"], lw=2.2, zorder=3)
			else:
				poly = [(d0, top - 0.18), (d1, top - 0.18)] + [(x, g(x, edge)) for x in np.linspace(d1, d0, 12)]
				ax.add_patch(Polygon(poly, closed=True, facecolor="#b48a5c", edgecolor="none", zorder=3))
			# The ends: flights along the walk, ramps, joins, drops.
			for end in ("w", "e"):
				info = w["ends"][end]
				fl = info.get("flight")
				ex = info["x"]
				dirn = 1.0 if end == "w" else -1.0   # into the walk from its end
				if fl == "steps" and info["n"]:
					n = info["n"]
					base = top - info["rise"]
					step_profile(ax, ex, dirn, base, top, n, info["run"], C["step"], g if not info.get("to") else None, edge)
				elif fl == "ramp":
					base = top - info["rise"]
					ax.add_patch(Polygon([(ex, base), (ex + dirn * info["run"], top), (ex + dirn * info["run"], top - 0.18),
						(ex, base - 0.0)], closed=True, facecolor=C["ramp"], edgecolor=C["ramp"], zorder=4))
					ax.text(ex + dirn * info["run"] * 0.5, top + 0.12, "ramp", fontsize=7.5, color=C["ramp"], ha="center", zorder=7)
				elif fl == "drop":
					ax.annotate("", xy=(ex + (-dirn) * 0.6, g(ex, edge) + 0.05), xytext=(ex - dirn * 0.1, top),
						arrowprops=dict(arrowstyle="->", color=C["drop"], lw=1.8), zorder=8)
					ax.text(ex - dirn * 0.4, top + 0.18, "drop %.1f m:\njump" % info["rise"], fontsize=8, color=C["drop"],
						ha="right" if end == "w" else "left", va="bottom", zorder=8, fontweight="bold")
			# The door's flight to the street (seen end on: a nose a tread) or its ramp.
			dx, dw = w["door"], w["door_w"]
			gd = top - w["door_rise"]
			if w["door_kind"] == "ramp":
				ax.add_patch(Rectangle((dx - dw / 2, gd), dw, w["door_rise"], facecolor="none", edgecolor=C["ramp"], hatch="////", lw=1.2, zorder=5))
				ax.text(dx, gd - 0.12, "ramp %.1f m" % w["door_run"], fontsize=7.5, color=C["ramp"], ha="center", va="top", zorder=7)
			elif w["door_n"]:
				ax.add_patch(Rectangle((dx - dw / 2, gd), dw, w["door_rise"], facecolor="#c79a63", edgecolor=C["step"], lw=0.8, zorder=5))
				for k in range(1, w["door_n"]):
					yk = gd + w["door_rise"] * k / w["door_n"]
					ax.plot([dx - dw / 2, dx + dw / 2], [yk, yk], color=C["step"], lw=0.8, zorder=5)
				ax.text(dx, gd - 0.12, "%d up" % w["door_n"], fontsize=7.5, color=C["step"], ha="center", va="top", zorder=7)
			# The door itself.
			ax.add_patch(Rectangle((dx - 0.55, top), 1.1, 2.3, facecolor="#5b4632", edgecolor="none", zorder=3))
			# The rail, along the street edge but its flights and a drop.
			if w["rail"]:
				segs = [(d0, dx - dw / 2), (dx + dw / 2, d1)]
				for a, b in segs:
					if b - a < 0.3:
						continue
					ax.plot([a, b], [top + 1.0, top + 1.0], color=C["rail"], lw=1.8, zorder=6)
					for bx in np.arange(a, b + 0.01, 0.6):
						ax.plot([bx, bx], [top, top + 1.0], color=C["rail"], lw=0.6, zorder=6)
			# The awning: its eave over the walk, posts at the street edge.
			if w["awning"] > 0:
				ay = top + w["awning"]
				ax.plot([x0, bx1], [ay, ay], color=C["awning"], lw=4, solid_capstyle="butt", zorder=6)
				px = x0 + 0.3
				while px < bx1:
					ax.plot([px, px], [top, ay], color=C["awning"], lw=1.0, zorder=5)
					px += 3.0
			# Its label.
			txt = "%s\nwalk %.2f m up" % (short(w["name"]), w["h"])
			if w["posts"]:
				txt += "\nroom under %.1f m" % max(0.0, w["under"])
			ax.text((w["x0"] + bx1) * 0.5, top + hgt - 0.35, txt, ha="center", va="top", fontsize=9, zorder=7,
				fontweight="bold" if w["h"] >= 1.0 else "normal")
		ax.set_xlim(xa - 2, xb + 2)
		ax.set_ylim(-2.0, 11.5)
		ax.set_aspect(VE)
		ax.set_yticks(range(-1, 12, 1))
		ax.set_xticks(range(int(math.ceil(xa / 10) * 10), int(xb) + 1, 10))
		ax.grid(axis="y", color="#00000014", lw=0.5)
		ax.set_ylabel("Y (m, the crossroads 0)")
		where = "the north side (seen from the street)" if side == "north" else "the south side (west on the left, as if seen through from the north)"
		ax.set_title("%s, x %d to %d" % (where.capitalize(), xa, xb), loc="left", fontsize=12)
		for s in ("top", "right"):
			ax.spines[s].set_visible(False)
	axes[-1].set_xlabel("x (m along Main Street, east +)")
	fig.suptitle("Main Street's walks, each at its owner's height (#737, PROPOSED). Heights drawn 2.5x. "
		"Brown: walk deck and skirting / posts; blue: rail; red bar: awning eave; green: ramp; red arrow: a drop to jump.",
		fontsize=13, x=0.01, ha="left")
	fig.tight_layout(rect=(0, 0, 1, 0.98))
	fig.savefig(path, dpi=100)
	plt.close(fig)


def step_profile(ax, ex, dirn, base, top, n, run, colour, g, edge):
	"""A flight seen from the side, running from the end at ex into the walk (dirn +1 east)."""
	rise = (top - base) / n
	pts = [(ex, base - (0.3 if g else 0.0))]
	x, y = ex, base
	for k in range(n):
		y += rise
		pts.append((x, y))
		x += dirn * run / n
		pts.append((x, y))
	pts.append((x, base - (0.3 if g else 0.0)))
	from matplotlib.patches import Polygon
	ax.add_patch(Polygon(pts, closed=True, facecolor="#c79a63", edgecolor=colour, lw=1.0, zorder=4))


def short(name):
	n = name.split(" (")[0]
	for a, b in (("Carpenter & Joiner", "Carpenter"), ("Hardware & Supply", "Hardware"), ("General Store / Grocer", "General Store"),
			("Barber & Bathhouse", "Barber"), ("Doctor / Dispensary", "Doctor"), ("Blacksmith & Farrier", "Blacksmith"),
			("Wagonwright & Repair", "Wagonwright"), ("Livery & Feed Stable", "Livery"), ("Sheriff's Office & Jail", "Jail"),
			("5 Saloon", "5 Saloon"), ("Salt Creek Hotel", "Hotel"), ("Land office", "Land office")):
		n = n.replace(a, b)
	return n.split(":")[0]


# ---------------------------------------------------------------------------------------- the table

def end_words(info):
	fl = info.get("flight")
	if info.get("kind") == "join":
		if fl == "level":
			return "level with %s" % info["to"]
		if fl == "theirs":
			return "up to %s (its flight)" % info["to"]
		if fl == "ramp":
			return "ramp down to %s (%.2f m, %.1f m long)" % (info["to"], info["rise"], info["run"])
		return "%d down to %s (%.2f m)" % (info["n"], info["to"], info["rise"])
	if fl == "drop":
		return "**drop %.1f m** (jump)" % info["rise"]
	if fl == "ramp":
		return "ramp %.1f m" % info["run"]
	return "%d down" % info["n"]


def write_table(lay, rules, path):
	lines = ["# The valley town's walks (#737): each lot at its own height", "",
		"Generated by `tools/valley/town_walks.py` from `config/valley.json` (`town.walks`, each lot's `walk`) and the bake; "
		"the drawing is `docs/concept/valley-walks.png`. **PROPOSED, for Sean to change.** Never edit by hand: change "
		"valley.json and re-run.", "",
		"- **Walk** is the walk's top over the ground at its street edge's middle; **Y** the same from the crossroads (0).",
		"- **Door** is the flight to the street before the door: treads of at most %.2f m, a ramp 1 in %d." % (rules["riser"], rules["slope"]),
		"- **West / East** is how the walk ends: down to the ground, to a neighbour over a shoulder-to-shoulder gap, a ramp, or a drop to jump.",
		"- **Under**: from %.1f m the walk stands on posts, open underneath (the clear height at the wall), and from %.1f m it has a rail along the street (not at its flights or a drop)." % (rules["posts_at"], rules["rail_at"]),
		"- **Awning** is the eave over the walk; the roofline steps with the floors.", ""]
	for side in ("north", "south"):
		lines += ["## The %s side, west to east" % side, "",
			"| Lot | x | Ground Y | Walk | Walk Y | Door | West end | East end | Under | Awning | Why |",
			"|---|---|---|---|---|---|---|---|---|---|---|"]
		for w in lay[side]:
			if w.get("none"):
				lines.append("| %s | %.0f..%.0f | %+.2f | none | | | | | | | %s |" % (short(w["name"]), w["x0"], w["x1"], w["ground"], w["why"]))
				continue
			door = ("ramp %.1f m" % w["door_run"]) if w["door_kind"] == "ramp" else "%d up" % w["door_n"]
			under = ("posts, %.1f m clear%s" % (max(0, w["under"]), ", rail" if w["rail"] else "")) if w["posts"] else "skirted"
			aw = ("%.2f (Y %+.2f)" % (w["awning"], w["top"] + w["awning"])) if w["awning"] else "none"
			lines.append("| %s | %.0f..%.0f | %+.2f | **%.2f** | %+.2f | %s | %s | %s | %s | %s | %s |" % (
				short(w["name"]), w["x0"], w["lot_x1"], w["ground"], w["h"], w["top"], door,
				end_words(w["ends"]["w"]), end_words(w["ends"]["e"]), under, aw, w["why"]))
		lines.append("")
	open(path, "w").write("\n".join(lines) + "\n")


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--check", action="store_true")
	a = ap.parse_args()
	data = json.load(open(CONFIG))
	g = Ground()
	lay, rules = lay_out(data, g)
	ok, res = checks(lay, rules)
	print("\n".join(res))
	if not a.check:
		write_table(lay, rules, TABLE)
		draw(lay, rules, g, PNG)
		print("wrote", os.path.relpath(TABLE, ROOT), os.path.relpath(PNG, ROOT))
	sys.exit(0 if ok else 1)


if __name__ == "__main__":
	main()
