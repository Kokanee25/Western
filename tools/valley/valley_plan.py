#!/usr/bin/env python3
"""Salt Creek Valley master plan: maps, profiles, tables and checks from config/valley.json.

Planning only (issue #467, Sean's brief of 2026-11-07). Nothing in the game reads valley.json yet;
this tool makes everything a reviewer looks at from that one file, so a moved point moves on every
map and in every table at once.

    python3 tools/valley/valley_plan.py                 # everything (maps, profiles, tables, checks)
    python3 tools/valley/valley_plan.py --check         # the checks only (exit 1 on a FAIL)

Writes docs/concept/valley-map.png (west at the top, as town-map.png), valley-town.png (north up,
as Sean's November 7 town picture), valley-profiles.png, valley-decisions.png, and
docs/briefs/valley-tables.md. Needs numpy and matplotlib.

The railway is laid exactly as the game's TrainRoute/TrackLine lay a route (compass heading,
curvature + to the left, spirals linear in curvature), so the line drawn here is the line train
step 6 builds. The terrain is a thin-plate spline through the plan's control points, cut by the
creek, canyon and arroyo by their bed profiles and levelled by the places' pads; Phase 2 bakes the
same function to a height map.
"""
import argparse
import heapq
import json
import math
import os
import sys

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONFIG = os.path.join(ROOT, "config", "valley.json")

# ---------------------------------------------------------------- the railway (TrainRoute's maths)


def route_segments(plan):
	"""TrainRoute.segments(): [(length, k0, k1)], curvature + to the left."""
	out, so_far = [], 0.0
	for item in plan:
		if "straight" in item:
			out.append((float(item["straight"]), 0.0, 0.0))
			so_far += float(item["straight"])
		elif "straight_to" in item:
			l = max(0.0, float(item["straight_to"]) - so_far)
			if l > 0:
				out.append((l, 0.0, 0.0))
				so_far += l
		else:
			b = item["bend"]
			k = 1.0 / float(b["radius"]) * (1.0 if b.get("side", "left") == "left" else -1.0)
			sp = float(b.get("spirals", 0.0))
			turn = math.radians(float(b["turn"]))
			arc = (turn - sp * abs(k)) / abs(k)
			if sp > 0:
				out.append((sp, 0.0, k))
			out.append((arc, k, k))
			if sp > 0:
				out.append((sp, k, 0.0))
			so_far += arc + 2 * sp
	return out


def route_sections(plan):
	out, so_far = [], 0.0
	for i, item in enumerate(plan):
		if "straight" in item:
			l = float(item["straight"])
		elif "straight_to" in item:
			l = max(0.0, float(item["straight_to"]) - so_far)
		else:
			b = item["bend"]
			k = 1.0 / float(b["radius"])
			sp = float(b.get("spirals", 0.0))
			l = max(0.0, (math.radians(float(b["turn"])) - sp * k) / k) + 2 * sp
		out.append({"id": item.get("id", "p%d" % i), "from": so_far, "length": l, "item": item})
		so_far += l
	return out


def grade_at(grades, s, vc):
	"""TrackLine.grade_profile: each change eased over the vertical curve's length."""
	g = grades[0][1] / 100.0
	for n in range(1, len(grades)):
		at, to = grades[n][0], grades[n][1] / 100.0
		if s >= at + vc * 0.5:
			g = to
		elif s > at - vc * 0.5:
			f = (s - (at - vc * 0.5)) / vc
			g = g + (to - g) * f
	return g


def lay_route(route, step=1.0):
	"""Positions along the line: arrays s, x, z, y (rail top), heading (compass deg), curvature."""
	segs = route_segments(route["plan"])
	total = sum(L for L, _, _ in segs)
	ox, oy, oz = route["origin"]
	b = math.radians(route["heading"])
	grades = route["profile"]["grades"]
	vc = float(route["profile"].get("vertical_curve", 60.0))
	S, X, Z, Y, H, K = [0.0], [ox], [oz], [oy], [route["heading"]], [0.0]
	s, x, z, y = 0.0, ox, oz, oy
	for L, k0, k1 in segs:
		n = max(1, int(round(L / step)))
		ds = L / n
		for i in range(n):
			f = (i + 0.5) / n
			k = k0 + (k1 - k0) * f
			bm = b - k * ds * 0.5  # left (+k) turns the compass bearing down
			x += math.sin(bm) * ds
			z += -math.cos(bm) * ds
			y += grade_at(grades, s + ds * 0.5, vc) * ds
			b -= k * ds
			s += ds
			S.append(s); X.append(x); Z.append(z); Y.append(y); H.append(math.degrees(b) % 360); K.append(k)
	return {"s": np.array(S), "x": np.array(X), "z": np.array(Z), "y": np.array(Y), "h": np.array(H), "k": np.array(K), "total": total}


def along(line, s):
	i = int(np.clip(np.searchsorted(line["s"], s), 0, len(line["s"]) - 1))
	return line["x"][i], line["z"][i], line["y"][i], line["h"][i]


# ---------------------------------------------------------------- geometry helpers


def poly_len(pts):
	p = np.asarray(pts, float)[:, :2]
	return float(np.sum(np.hypot(*(p[1:] - p[:-1]).T)))


def resample(pts, step):
	p = np.asarray(pts, float)
	out = [p[0]]
	for a, b in zip(p[:-1], p[1:]):
		d = float(np.hypot(*(b[:2] - a[:2])))
		n = max(1, int(math.ceil(d / step)))
		for i in range(1, n + 1):
			out.append(a + (b - a) * (i / n))
	return np.array(out)


def nearest_on_polyline(px, pz, line):
	"""Per-point distance to a polyline [N, >=2] and the interpolated row of the nearest point.
	px, pz: arrays. Returns (d, rows) with rows [len(px), line.shape[1]]."""
	L = np.asarray(line, float)
	best = np.full(px.shape, np.inf)
	rows = np.zeros(px.shape + (L.shape[1],))
	for a, b in zip(L[:-1], L[1:]):
		dx, dz = b[0] - a[0], b[1] - a[1]
		ll = dx * dx + dz * dz
		t = np.clip(((px - a[0]) * dx + (pz - a[1]) * dz) / ll, 0.0, 1.0)
		cx, cz = a[0] + t * dx, a[1] + t * dz
		d = np.hypot(px - cx, pz - cz)
		m = d < best
		if np.any(m):
			best[m] = d[m]
			rows[m] = a + (b - a) * t[m][:, None]
	return best, rows


# ---------------------------------------------------------------- the terrain


class Terrain:
	def __init__(self, data, rail):
		self.data = data
		self.rail = rail
		env = data["envelope"]["playable"]
		self.g = float(data["terrain"].get("grid", 10))
		pad = 300.0
		self.x0, self.x1 = env["x"][0] - pad, env["x"][1] + pad
		self.z0, self.z1 = env["z"][0] - pad, env["z"][1] + pad
		self.xs = np.arange(self.x0, self.x1 + 0.1, self.g)
		self.zs = np.arange(self.z0, self.z1 + 0.1, self.g)
		self.XX, self.ZZ = np.meshgrid(self.xs, self.zs)  # [z, x]
		self._fit()
		self.natural = self._tps(self.XX, self.ZZ)
		self.h = self.natural.copy()
		self._pads()
		self.shaped = self.h.copy()  # natural ground with the pads, before the rail's formation and the channels
		self._formation()
		self.before_channels = self.h.copy()
		self.channels = {}
		for key in ("creek", "arroyo"):
			self._carve(key)

	# thin-plate spline through the control points
	def _fit(self):
		c = np.array(self.data["terrain"]["control"], float)
		self.cp = c
		n = len(c)
		d = np.hypot(c[:, None, 0] - c[None, :, 0], c[:, None, 1] - c[None, :, 1])
		with np.errstate(divide="ignore", invalid="ignore"):
			K = np.where(d > 0, d * d * np.log(d), 0.0)
		P = np.column_stack([np.ones(n), c[:, 0] / 1000.0, c[:, 1] / 1000.0])
		A = np.zeros((n + 3, n + 3))
		A[:n, :n] = K
		A[:n, n:] = P
		A[n:, :n] = P.T
		rhs = np.concatenate([c[:, 2], np.zeros(3)])
		sol = np.linalg.solve(A, rhs)
		self.w, self.a = sol[:n], sol[n:]

	def _tps(self, X, Z):
		X = np.asarray(X, float)
		Z = np.asarray(Z, float)
		out = self.a[0] + self.a[1] * X / 1000.0 + self.a[2] * Z / 1000.0
		for (cx, cz, _), w in zip(self.cp, self.w):
			d2 = (X - cx) ** 2 + (Z - cz) ** 2
			with np.errstate(divide="ignore", invalid="ignore"):
				out = out + w * np.where(d2 > 0, 0.5 * d2 * np.log(d2), 0.0)
		return out

	def _blend(self, cx, cz, w, d, heading, blend, y_fn):
		hd = math.radians(heading)
		ux, uz = math.sin(hd), -math.cos(hd)  # along the heading
		vx, vz = -uz, ux
		rx = (self.XX - cx) * ux + (self.ZZ - cz) * uz
		rz = (self.XX - cx) * vx + (self.ZZ - cz) * vz
		ex = np.maximum(np.abs(rx) - w * 0.5, 0.0)
		ez = np.maximum(np.abs(rz) - d * 0.5, 0.0)
		dist = np.hypot(ex, ez)
		t = np.clip(1.0 - dist / blend, 0.0, 1.0)
		wgt = t * t * (3 - 2 * t)
		m = wgt > 0
		self.h[m] = self.h[m] * (1 - wgt[m]) + y_fn(self.XX[m], self.ZZ[m]) * wgt[m]

	def _pads(self):
		tg = self.data["town"]["ground"]
		pl = tg["plane"]
		rx, rz = tg["rect"]["x"], tg["rect"]["z"]
		self._blend((rx[0] + rx[1]) / 2, (rz[0] + rz[1]) / 2, rx[1] - rx[0], rz[1] - rz[0], 90, tg["blend"],
			lambda X, Z: pl["y0"] + pl["gx"] * X + pl["gz"] * Z)
		for p in self.data["places"]:
			pd = p.get("pad")
			if not pd:
				continue
			y = float(pd["y"])
			self._blend(p["at"][0], p["at"][1], pd["w"], pd["d"], pd.get("heading", 90), pd.get("blend", 30), lambda X, Z, y=y: np.full(X.shape, y))

	def _formation(self):
		"""The rail's bed: rail top less 1 m within 4 m of the line, eased out over its cut or fill;
		none on the trestle's span or past the west portal (the tunnel)."""
		r = self.rail
		marks = self.data["railway"]["route"]["marks"]
		cross = self.data["railway"]["route"]["crossings"]
		keep = r["s"] <= marks["west_portal"]
		for c in cross:
			keep &= ~((r["s"] > c["from"] - 2) & (r["s"] < c["to"] + 2))
		idx = np.where(keep)[0][::5]
		line = np.column_stack([r["x"][idx], r["z"][idx], r["y"][idx] - 1.0, r["s"][idx]])
		# split into runs so the line doesn't jump the trestle gap
		runs, cur = [], [line[0]]
		for a, b in zip(line[:-1], line[1:]):
			if b[3] - a[3] > 10:
				runs.append(np.array(cur)); cur = []
			cur.append(b)
		runs.append(np.array(cur))
		for run in runs:
			if len(run) < 2:
				continue
			bx = (run[:, 0].min() - 60, run[:, 0].max() + 60)
			bz = (run[:, 1].min() - 60, run[:, 1].max() + 60)
			m = (self.XX > bx[0]) & (self.XX < bx[1]) & (self.ZZ > bz[0]) & (self.ZZ < bz[1])
			d, rows = nearest_on_polyline(self.XX[m], self.ZZ[m], run)
			form = rows[:, 2]
			hh = self.h[m]
			reach = 4.0 + 1.5 * np.abs(hh - form)
			t = np.clip((d - 4.0) / np.maximum(reach - 4.0, 1e-3), 0.0, 1.0)
			wgt = np.where(d <= 4.0, 1.0, 1.0 - t)
			self.h[m] = hh * (1 - wgt) + form * wgt

	def _carve(self, key):
		w = self.data["water"][key]
		L = np.array(w["line"], float)
		d, rows = nearest_on_polyline(self.XX, self.ZZ, L)
		bed, half, floor, pw = rows[:, :, 2], rows[:, :, 3], rows[:, :, 4], rows[:, :, 5]
		f = np.clip((d - floor) / np.maximum(half - floor, 1e-3), 0.0, 1.0)
		carve = bed + (self.h - bed) * f ** pw
		m = d < half
		self.h[m] = np.minimum(self.h[m], carve[m])
		self.channels[key] = (d, rows)

	def at(self, x, z, field=None):
		F = self.h if field is None else field
		fx = (np.asarray(x, float) - self.x0) / self.g
		fz = (np.asarray(z, float) - self.z0) / self.g
		ix = np.clip(np.floor(fx).astype(int), 0, len(self.xs) - 2)
		iz = np.clip(np.floor(fz).astype(int), 0, len(self.zs) - 2)
		tx, tz = np.clip(fx - ix, 0, 1), np.clip(fz - iz, 0, 1)
		a = F[iz, ix] * (1 - tx) + F[iz, ix + 1] * tx
		b = F[iz + 1, ix] * (1 - tx) + F[iz + 1, ix + 1] * tx
		return a * (1 - tz) + b * tz

	def natural_at(self, x, z):
		return self._tps(np.atleast_1d(x), np.atleast_1d(z))


# ---------------------------------------------------------------- the plan


class Plan:
	def __init__(self, path=CONFIG):
		with open(path) as f:
			self.data = json.load(f)
		self.route = self.data["railway"]["route"]
		self.rail = lay_route(self.route)
		self.marks = self.route["marks"]
		self.terrain = Terrain(self.data, self.rail)
		self.places = {p["id"]: p for p in self.data["places"]}
		self.roads = {r["id"]: r for r in self.data["roads"]}
		self.bridges = {b["id"]: b for b in self.data["bridges"]}
		self.speeds = self.data["speeds"]
		self.checks = []  # (status, what, detail)
		self._bridge_points()

	def check(self, ok, what, detail, warn=False):
		self.checks.append(("PASS" if ok else ("WARN" if warn else "FAIL"), what, detail))

	def mark_xz(self, name):
		x, z, y, h = along(self.rail, self.marks[name])
		return x, z, y, h

	def _bridge_points(self):
		"""Each bridge's position and deck height."""
		for b in self.bridges.values():
			if "route_crossing" in b:
				c = [c for c in self.route["crossings"] if c["id"] == b["route_crossing"]][0]
				x, z, y, _ = along(self.rail, (c["from"] + c["to"]) / 2)
				b["_at"] = (x, z)
				b["_deck"] = y
			elif "route_mark" in b:
				x, z, y, _ = along(self.rail, self.marks[b["route_mark"]])
				b["_at"] = (x, z)
				b["_deck"] = y + b["deck_over_rail"]
				b["_rail"] = y
			else:
				b["_at"] = tuple(b["at"])
				b["_deck"] = b["deck_y"]

	# the town's own streets, as roads for the network
	def town_roads(self):
		t = self.data["town"]
		ms = t["main_street"]
		ns = t["ns_street"]
		bs = t["back_street"]
		rl = t["rear_lane"]
		return [
			{"id": "main_street", "class": "street", "line": [[ms["x"][0], 0], [0, 0], [ms["x"][1], 0]]},
			{"id": "ns_street", "class": "street", "line": [[0, ns["z"][0] + 14], [0, 0], [0, 124]]},
			{"id": "back_street", "class": "street", "line": [[bs["x"][0], -51.2], [0, -51.2], [bs["x"][1], -51.2]]},
			{"id": "rear_lane", "class": "street", "line": [[rl["x"][0], 51.2], [0, 51.2], [rl["x"][1], 51.2]]},
		]

	GRADED = {"wagon": 40.0, "lane": 30.0, "street": 30.0, "track": 20.0, "path": 10.0}

	def road_profile(self, line, step=5.0, cls="wagon", fills=()):
		"""Samples along a road: x, z, y, s. The road is graded as built: its surface the ground
		averaged over a run (40 m for a wagon road: the cuts and fills a road crew makes through
		bumps, pad edges and a ford's banks), and bridge decks over their spans."""
		pts = resample(line, step)
		x, z = pts[:, 0], pts[:, 1]
		y = self.terrain.at(x, z)
		decks = []
		for b in self.bridges.values():
			if b["id"] == "bridge_c":
				continue
			bx, bz = b["_at"]
			span = b.get("span", 14)
			d = np.hypot(x - bx, z - bz)
			m = d < span * 0.5 + 6
			if np.any(m):
				y[m] = b["_deck"]
				decks.append((d < span * 0.5 + 1, b["_deck"]))
		for f in fills:
			if "fill_y" in f:
				m = np.hypot(x - f["at"][0], z - f["at"][1]) < f.get("span", 30) * 0.5
				y[m] = f["fill_y"]
		n = max(1, int(self.GRADED.get(cls, 30.0) / step))
		if n > 1 and len(y) > n:
			k = np.ones(n) / n
			pad = np.concatenate([np.full(n, y[0]), y, np.full(n, y[-1])])
			y = np.convolve(pad, k, mode="same")[n:-n]
		for m, deck in decks:
			y[m] = deck
		s = np.concatenate([[0], np.cumsum(np.hypot(np.diff(x), np.diff(z)))])
		return x, z, y, s

	@staticmethod
	def grades(y, s, window=20.0):
		g = []
		j = 0
		for i in range(len(s)):
			while j < len(s) - 1 and s[j] - s[i] < window:
				j += 1
			if s[j] - s[i] >= window * 0.75:
				g.append((y[j] - y[i]) / (s[j] - s[i]) * 100.0)
		return np.array(g) if g else np.zeros(1)

	# --------------------------------------------- the road network and journeys
	def network(self, step=5.0):
		nodes, adj = [], {}
		owner = []
		roads = list(self.data["roads"]) + self.town_roads()
		for r in roads:
			x, z, y, s = self.road_profile(r["line"], step, r.get("class", "wagon"), r.get("crosses", ()))
			base = len(nodes)
			for i in range(len(x)):
				nodes.append((x[i], z[i], y[i]))
				owner.append(r["id"])
				adj[base + i] = []
			for i in range(len(x) - 1):
				d = math.hypot(x[i + 1] - x[i], z[i + 1] - z[i])
				adj[base + i].append((base + i + 1, d))
				adj[base + i + 1].append((base + i, d))
		N = np.array(nodes)
		# junctions: points of different roads within 6 m
		for i in range(len(N)):
			d = np.hypot(N[:, 0] - N[i, 0], N[:, 1] - N[i, 1])
			for j in np.where((d < 6.0) & (np.arange(len(N)) > i))[0]:
				if owner[j] != owner[i]:
					adj[i].append((int(j), float(d[j])))
					adj[int(j)].append((i, float(d[j])))
		self.net = (N, adj, owner)

	def journey(self, a, b):
		N, adj, owner = self.net
		ia = int(np.argmin(np.hypot(N[:, 0] - a[0], N[:, 1] - a[1])))
		ib = int(np.argmin(np.hypot(N[:, 0] - b[0], N[:, 1] - b[1])))
		dist = {ia: 0.0}
		prev = {}
		q = [(0.0, ia)]
		while q:
			d, u = heapq.heappop(q)
			if u == ib:
				break
			if d > dist.get(u, 1e18):
				continue
			for v, w in adj[u]:
				nd = d + w
				if nd < dist.get(v, 1e18):
					dist[v] = nd
					prev[v] = u
					heapq.heappush(q, (nd, v))
		path = [ib]
		while path[-1] != ia:
			path.append(prev[path[-1]])
		path = path[::-1]
		P = N[path]
		off_a = math.hypot(P[0, 0] - a[0], P[0, 1] - a[1])
		off_b = math.hypot(P[-1, 0] - b[0], P[-1, 1] - b[1])
		ys = P[:, 2]
		dy = np.diff(ys)
		roads_used = []
		for i in path:
			if not roads_used or roads_used[-1] != owner[i]:
				roads_used.append(owner[i])
		return {"length": dist[ib] + off_a + off_b, "gain": float(dy[dy > 0].sum()), "loss": abs(float(dy[dy < 0].sum())),
			"roads": roads_used, "pts": P, "off": max(off_a, off_b)}


# ---------------------------------------------------------------- the checks


def run_checks(plan):
	d = plan.data
	r = plan.rail
	T = plan.terrain
	m = plan.marks
	lim = d["railway"]["limits"]
	results = {}

	# rail: radius, grade, stations level, cut and fill
	k = np.abs(r["k"])
	rmin = 1.0 / k.max() if k.max() > 0 else float("inf")
	plan.check(rmin >= lim["min_radius"], "Rail: sharpest curve", "%.0f m radius (limit %d m)" % (rmin, lim["min_radius"]))
	gr = np.diff(r["y"]) / np.diff(r["s"]) * 100
	plan.check(np.abs(gr).max() <= lim["ruling_grade"] + 1e-6, "Rail: steepest grade", "%.2f %% (ruling %.1f %%)" % (np.abs(gr).max(), lim["ruling_grade"]))
	for a, b, name in [("depot_east_switch", "depot_west_switch", "depot"), ("ore_works_east", "ore_works_west", "Ore Works")]:
		sel = (r["s"] > m[a] + 30) & (r["s"] < m[b] - 30)
		g = np.abs(gr[sel[1:]]).max() if np.any(sel[1:]) else 0
		plan.check(g <= 0.05, "Rail: %s tracks level" % name, "steepest %.2f %% between its switches" % g)
	# the trestle
	c = d["railway"]["route"]["crossings"][0]
	xm, zm, ym, _ = along(r, (c["from"] + c["to"]) / 2)
	bed_d, bed_rows = nearest_on_polyline(np.array([xm]), np.array([zm]), d["water"]["creek"]["line"])
	creek_bed = bed_rows[0, 2]
	depth = ym - creek_bed
	plan.check(abs(depth - 27) <= 1.5, "Trestle: rail over the creek floor", "%.1f m (the lab's ~27 m; the creek's line passes %.1f m from its middle)" % (depth, bed_d[0]))
	xe, ze, ye, _ = along(r, c["from"])
	xw, zw, yw, _ = along(r, c["to"])
	nat_e = float(T.at(xe, ze, T.shaped))
	nat_w = float(T.at(xw, zw, T.shaped))
	plan.check(abs(ye - 1 - nat_e) < 1.6 and abs(yw - 1 - nat_w) < 1.6, "Trestle: abutments on the rims",
		"rims %.1f / %.1f m under rail %.1f / %.1f m (the deck meets the bench)" % (nat_e, nat_w, ye, yw))
	rim = [T.at(xm + dx, zm, T.h) for dx in (-70, -60, 60, 70)]
	results["trestle"] = {"x": xm, "z": zm, "rail": ym, "bed": creek_bed, "depth": depth}

	# cut and fill along the line (natural ground, before the formation, against the formation)
	natural_line = T.at(r["x"], r["z"], T.shaped)
	carved_line = []
	for key in ("creek", "arroyo"):
		pass
	ground = np.array(T.at(r["x"], r["z"], T.h))  # includes channels (formation applied, so read pre-formation too)
	pre = plan.terrain.natural_at(r["x"], r["z"])
	cutfill = []
	sel = r["s"] <= m["west_portal"]
	formation = r["y"] - 1.0
	# natural with channels but without the formation: rebuild cheaply from h before formation is not kept;
	# use the spline plus the channels' carve at the line's points
	cf = natural_line - formation
	results["cutfill"] = (r["s"][sel], cf[sel])
	big = []
	cur = None
	for s, v in zip(r["s"][sel], cf[sel]):
		inside = any(cc["from"] - 2 < s < cc["to"] + 2 for cc in d["railway"]["route"]["crossings"])
		if inside:
			continue
		kind = "cut" if v > 3 else ("fill" if v < -3 else None)
		if kind and cur and cur["kind"] == kind and s - cur["to"] < 15:
			cur["to"] = s
			cur["max"] = max(cur["max"], abs(v))
		elif kind:
			cur = {"kind": kind, "from": s, "to": s, "max": abs(v)}
			big.append(cur)
	results["earthworks"] = big
	ov_x, ov_z, ov_y, _ = along(r, m["overpass"])
	ov_ground = float(T.at(ov_x, ov_z, T.shaped))
	clear = ov_ground - ov_y
	need = d["railway"]["clearance"]["overpass_deck_over_rail"]
	plan.check(abs(clear - need) < 0.8, "Overpass: the road's deck over the rail", "%.2f m (planned %.2f: %.2f m clear under a %.1f m deck; the engine is %.1f m)" % (
		clear, need, clear - d["railway"]["clearance"]["deck_structure"], d["railway"]["clearance"]["deck_structure"], d["railway"]["clearance"]["engine_top_over_rail"]))
	results["overpass"] = {"x": ov_x, "z": ov_z, "rail": ov_y, "deck": ov_ground}

	# water: beds fall, banks stand
	for key in ("creek", "arroyo"):
		L = np.array(d["water"][key]["line"], float)
		falls = np.all(np.diff(L[:, 2]) < 0)
		plan.check(falls, "Water: %s's bed falls every step" % key, "%.1f m at its top to %.1f m at its foot over %.0f m (%.2f %% on average)" % (
			L[0, 2], L[-1, 2], poly_len(L[:, :2]), (L[0, 2] - L[-1, 2]) / poly_len(L[:, :2]) * 100))
		P = resample(L, 10)
		# natural at the rim (half width out on either side) must stand above the bed
		low = []
		for i in range(1, len(P) - 1):
			dx, dz = P[i + 1, 0] - P[i - 1, 0], P[i + 1, 1] - P[i - 1, 1]
			n = math.hypot(dx, dz)
			nx, nz = -dz / n, dx / n
			hw = P[i, 3]
			bank = min(float(T.at(P[i, 0] + nx * hw, P[i, 1] + nz * hw, T.before_channels)), float(T.at(P[i, 0] - nx * hw, P[i, 1] - nz * hw, T.before_channels)))
			low.append(bank - P[i, 2])
		low = np.array(low)
		iw = int(np.argmin(low)) + 1
		plan.check(low.min() >= 0.5, "Water: %s has banks all along" % key, "lowest bank %.1f m over the bed at (%.0f, %.0f); median %.1f m" % (low.min(), P[iw, 0], P[iw, 1], np.median(low)))
		results["banks_" + key] = (P, low)
	cr = d["water"]["creek"]["line"]
	ar = d["water"]["arroyo"]["line"]
	plan.check(abs(cr[22][2] - ar[-1][2]) < 0.6 and math.hypot(cr[22][0] - ar[-1][0], cr[22][1] - ar[-1][1]) < 1,
		"Water: the arroyo joins the creek level", "at (%d, %d), %.1f m, below the widow's (the creek at her fields %.1f m)" % (ar[-1][0], ar[-1][1], ar[-1][2], cr[19][2]))
	# mine drainage reaches the creek only below the widow's and the town
	town_bed = cr[7][2]
	plan.check(ar[-1][2] < cr[19][2] and ar[-1][0] > cr[20][0], "Water: mine and Ore Works drainage joins below town and the widow",
		"the arroyo meets Salt Creek %.0f m downstream of the widow's fields" % poly_len(np.array(cr)[19:23, :2]))
	ditch = d["water"]["ditch"]["line"]
	_, rows = nearest_on_polyline(np.array([ditch[0][0]]), np.array([ditch[0][1]]), cr)
	plan.check(rows[0, 2] > town_bed, "Water: the town ditch heads upstream of town", "its head by the creek at %.1f m (town reach %.1f m), above every works" % (rows[0, 2], town_bed))
	# the ditch must fall from head to town
	dy = [float(T.at(p[0], p[1], T.before_channels)) for p in ditch]
	plan.check(dy[0] > dy[-1] + 2, "Water: the ditch can run by gravity", "ground at its head %.1f m, at the cistern %.1f m" % (dy[0], dy[-1]))

	# canyon: deepest and narrowest at the trestle, shallow at Bridge A
	P, low = results["banks_creek"]
	results["canyon_depths"] = [(i, float(T.at(v[0], v[1], T.before_channels) - v[2]), v[3] * 2) for i, v in enumerate(cr)]
	ba = plan.bridges["bridge_a"]
	_, rows = nearest_on_polyline(np.array([ba["at"][0]]), np.array([ba["at"][1]]), cr)
	banks_a = float(T.at(ba["at"][0], ba["at"][1], T.before_channels)) - rows[0, 2]
	plan.check(banks_a <= 4.5, "Canyon: shallow and passable at Bridge A", "the creek %.1f m under the natural ground there (Bridge A's deck at %.1f m over a bed at %.1f m)" % (
		banks_a, ba["deck_y"], rows[0, 2]))

	# places: pads against natural ground (earthwork) and envelope
	env = d["envelope"]["playable"]
	results["places"] = {}
	for p in d["places"]:
		x, z = p["at"]
		nat = float(T.at(x, z, T.before_channels)) if not p.get("pad") else float(plan.terrain.natural_at(x, z)[0])
		y = float(T.at(x, z))
		inside = env["x"][0] <= x <= env["x"][1] and env["z"][0] <= z <= env["z"][1]
		results["places"][p["id"]] = {"y": y, "natural": nat}
		if not inside:
			plan.check(False, "Place inside the envelope: " + p["id"], "(%d, %d)" % (x, z), warn=True)
	return results


def extra_checks(plan, res, jr, vis):
	sp = plan.speeds
	jh = [j for j in jr if j["id"] == "harlan_homestead"][0]
	plan.check(95 <= jh["canter"] <= 140, "Harlan: about a two-minute ride", "%.0f m by road: %s at a canter, %s at a trot (DECIDED: about two minutes)" % (
		jh["road"], fmt_min(jh["canter"]), fmt_min(jh["trot"])))
	crossed = any("Bridge B" in o for o in jh["obstacles"])
	plan.check(not crossed, "Harlan: his daily ride doesn't cross the overpass (Nov 2 baseline)", "his way: " + " > ".join(jh["roads"]))
	m = plan.marks
	run_in = m["trestle_east"] - m["overpass"]
	_, _, stop = train_numbers(plan)
	t22 = run_in / (sp["train_planned_kmh"] / 3.6)
	plan.check(run_in >= 600, "Runaway: track from the overpass to the trestle", "%d m: %s at the planned 22 km/h, %s at 32; a full stop from 32 km/h takes %.0f m" % (
		run_in, fmt_min(t22), fmt_min(run_in / (sp["train_max_kmh"] / 3.6)), stop(32)))
	cl = plan.data["railway"]["clearance"]
	deck = cl["overpass_deck_over_rail"]
	plan.check(deck - cl["deck_structure"] - cl["engine_top_over_rail"] >= 0.6 and deck - cl["coach_roof"] <= 2.5,
		"Overpass: room under it, and a jump down onto the train", "%.1f m clear over the engine's stack; drops from the deck: %.1f m to the coach roof, %.1f m to the boxcar roof, %.1f m into an ore car" % (
		deck - cl["deck_structure"] - cl["engine_top_over_rail"], deck - cl["coach_roof"], deck - cl["boxcar_roof"], deck - cl["ore_car_side"]))
	tr = res["trestle"]
	plan.check(900 <= tr["x"] <= 1400, "Trestle: about 1 km east of town", "its middle %.0f m east of the crossroads, %.0f m past Main Street's east end, %.0f m of track from the depot" % (
		tr["x"], tr["x"] - 130, m["trestle_mid"] - m["depot"] if m["trestle_mid"] > m["depot"] else m["depot"] - m["trestle_mid"]))
	full = [v["name"] for v in vis if v["all"] >= 0.6]
	plan.check(len(full) >= 2, "Trestle: whole-bridge vantage points", "; ".join(full))
	deck_only = [v["name"] for v in vis if v["deck"] >= 0.9 and v["all"] < 0.3]
	plan.check(False, "Trestle: seen from town", "only the deck and the train on it from " + "; ".join(deck_only) + ": the bents stand below the bench (see the plan)", warn=True)


def journeys(plan):
	plan.network()
	sp = plan.speeds
	origin = (0.0, 0.0)
	rows = []
	targets = [("harlan_homestead", "Harlan's homestead"), ("opening_site", "The opening's encounter site"), ("widow_homestead", "The widow's homestead"),
		("bridge_a", "Bridge A (creek crossing)"), ("bridge_b", "Bridge B (the overpass)"), ("vp_trestle_overlook", "Trestle overlook"),
		("ore_works", "Ore Works"), ("mine", "The mine"), ("timber_camp", "Timber camp"), ("baron_ranch", "The Baron's ranch"),
		("baron_town_house", "The Baron's town house"), ("ute_community", "Southern Ute community"), ("hideout", "Outlaw hideout (OPEN)"),
		("cemetery", "Cemetery"), ("depot", "Depot"), ("east_exit", "East exit")]
	for pid, name in targets:
		if pid in plan.places:
			at = plan.places[pid]["at"]
		elif pid in plan.bridges:
			at = plan.bridges[pid]["_at"]
		else:
			at = [v for v in plan.data["viewpoints"] if v["id"] == pid][0]["at"]
		j = plan.journey(origin, at)
		straight = math.hypot(at[0], at[1])
		obstacles = []
		pts = j["pts"]
		for b in plan.bridges.values():
			if b["id"] == "bridge_c":
				continue
			if np.min(np.hypot(pts[:, 0] - b["_at"][0], pts[:, 1] - b["_at"][1])) < 12:
				obstacles.append(b["name"].split(":")[0])
		for rd in plan.data["roads"]:
			for c in rd.get("crosses", []):
				if np.min(np.hypot(pts[:, 0] - c["at"][0], pts[:, 1] - c["at"][1])) < 12:
					obstacles.append(c["what"])
		rows.append({"id": pid, "name": name, "straight": straight, "road": j["length"], "gain": j["gain"], "loss": j["loss"],
			"walk": j["length"] / sp["player_walk"], "trot": j["length"] / sp["horse_trot"], "canter": j["length"] / sp["horse_canter"],
			"roads": j["roads"], "obstacles": obstacles, "pts": pts, "off": j["off"]})
	return rows


def visibility(plan, res):
	T = plan.terrain
	tr = res["trestle"]
	c = plan.route["crossings"][0]
	ss = np.linspace(c["from"] + 5, c["to"] - 5, 7)
	out = []
	for vp in plan.data["viewpoints"]:
		vx, vz = vp["at"]
		ey = float(T.at(vx, vz)) + vp["eye"]
		seen_deck = 0
		seen = 0
		total = 0
		deepest = 0.0
		for s in ss:
			x, z, y, _ = along(plan.rail, s)
			floor = float(T.at(x, z))
			for f in np.linspace(0, 1, 7):
				ty = floor + 1.0 + (y + 0.5 - floor - 1.0) * f
				dist = math.hypot(x - vx, z - vz)
				n = int(dist / 4)
				t = np.linspace(0.02, 0.985, max(n, 2))
				rx, rz = vx + (x - vx) * t, vz + (z - vz) * t
				ry = ey + (ty - ey) * t
				g = T.at(rx, rz)
				ok = np.all(g < ry - 0.3)
				total += 1
				if ok:
					seen += 1
					deepest = max(deepest, y - ty)
					if f == 1.0:
						seen_deck += 1
		out.append({"id": vp["id"], "name": vp["name"], "dist": math.hypot(tr["x"] - vx, tr["z"] - vz), "deck": seen_deck / len(ss),
			"all": seen / total, "deepest": deepest})
	return out


def train_numbers(plan):
	sp = plan.speeds
	g = 9.81 * sp["train_brake_g"]

	def stop(kmh):
		v = kmh / 3.6
		return v * v / (2 * g) + v * sp["train_brake_setup_s"] * 0.5

	m = plan.marks
	legs = []
	pairs = [("east_portal", "overpass"), ("overpass", "trestle_east"), ("trestle_east", "trestle_west"), ("trestle_west", "depot"), ("depot", "ore_works"), ("ore_works", "west_portal")]
	for a, b in pairs:
		dd = m[b] - m[a]
		legs.append((a, b, dd, dd / (sp["train_planned_kmh"] / 3.6), dd / (sp["train_max_kmh"] / 3.6)))
	brakes = [(k, stop(k)) for k in (15, 22, 30, 32, 40, 43)]
	return legs, brakes, stop


# ---------------------------------------------------------------- tables (markdown)


def fmt_min(sec):
	return "%d:%02d" % (int(sec // 60), int(round(sec % 60)) % 60) if sec < 3600 else "%.0f min" % (sec / 60)


def write_tables(plan, res, jr, vis, path):
	d = plan.data
	r = plan.rail
	L = []
	w = L.append
	w("# Salt Creek Valley: the generated tables")
	w("")
	w("Generated by `tools/valley/valley_plan.py` from `config/valley.json`: never edit by hand (run the tool). "
		"Coordinates are world metres (x east, z south, north is -z); Y is height above the new crossroads' ground. "
		"The plan and its reasons: `docs/briefs/valley-plan.md`.")
	w("")
	w("## Checks")
	w("")
	w("| | Check | Result |")
	w("|---|---|---|")
	for st, what, det in plan.checks:
		w("| %s | %s | %s |" % (st, what, det))
	w("")
	w("## D. The coordinate schedule")
	w("")
	w("Y is the planned ground (a place's pad, or the shaped ground); 'natural' is the ground before levelling, so the difference is earthwork.")
	w("")
	w("| ID | Name | X | Z | Y | natural | Footprint (m) | Access | Missions | Status |")
	w("|---|---|---|---|---|---|---|---|---|---|")
	for p in d["places"]:
		pr = res["places"][p["id"]]
		pd = p.get("pad")
		fp = "%d x %d" % (pd["w"], pd["d"]) if pd else "-"
		w("| `%s` | %s | %d | %d | %.1f | %.1f | %s | %s | %s | %s |" % (p["id"], p["name"], p["at"][0], p["at"][1], pr["y"], pr["natural"], fp,
			", ".join(p.get("access", [])) or "-", ", ".join(p.get("missions", [])) or "-", p["status"]))
	for b in d["bridges"]:
		x, z = b["_at"]
		w("| `%s` | %s | %d | %d | %.1f (deck) | - | %s | %s | - | %s |" % (b["id"], b["name"], x, z, b["_deck"], ("%d long" % b["length"]) if "length" in b else ("%d span" % b.get("span", 0)),
			b.get("road", "rail"), b["status"]))
	for vp in d["viewpoints"]:
		w("| `%s` | %s (viewpoint) | %d | %d | %.1f | - | - | - | - | %s |" % (vp["id"], vp["name"], vp["at"][0], vp["at"][1], float(plan.terrain.at(*vp["at"])), vp["status"]))
	w("")
	w("### The town's lots (measured off Sean's November 7 picture)")
	w("")
	w("x = (picture px - 808) / 5 along Main Street (the 250 m street drawn 1,250 px). North lots front z -10.05, south lots z +10.05; 38.1 m deep.")
	w("")
	w("| Side | ID | Name | x from | x to | Frontage | Kind | Picture px |")
	w("|---|---|---|---|---|---|---|---|")
	for side in ("north", "south"):
		for lot in d["town"][side]:
			w("| %s | `%s` | %s | %.1f | %.1f | %.1f | %s | %s |" % (side, lot["id"], lot["name"], lot["x0"], lot["x1"], lot["x1"] - lot["x0"], lot["kind"], lot.get("px", "")))
	w("")
	w("## E. The ground: levels, grades, earthworks")
	w("")
	w("### The railway (east to west, TrainRoute's distances)")
	w("")
	w("| Mark | Along (m) | X | Z | Rail Y | Ground (natural) | Heading |")
	w("|---|---|---|---|---|---|---|")
	for name, s in sorted(plan.marks.items(), key=lambda kv: kv[1]):
		x, z, y, h = along(r, s)
		w("| %s | %d | %.0f | %.0f | %.1f | %.1f | %.1f |" % (name, s, x, z, y, float(plan.terrain.at(x, z, plan.terrain.shaped)), h))
	w("")
	w("Sections (TrainRoute ids):")
	w("")
	w("| Section | From | Length | What |")
	w("|---|---|---|---|")
	for sec in route_sections(plan.route["plan"]):
		it = sec["item"]
		what = ("straight" if "straight" in it or "straight_to" in it else "bend %s %d m radius, %d degrees, %d m spirals" % (
			it["bend"]["side"], it["bend"]["radius"], it["bend"]["turn"], it["bend"].get("spirals", 0)))
		w("| %s | %.0f | %.0f | %s |" % (sec["id"], sec["from"], sec["length"], what))
	w("")
	w("Grades (+ rising westward): " + "; ".join("from %d m %+.2f %%" % (g[0], g[1]) for g in plan.route["profile"]["grades"]) + ".")
	w("")
	w("Earthworks over 3 m (the formation is rail - 1 m; the trestle's span and the tunnel aside):")
	w("")
	w("| Kind | From (m) | To (m) | Deepest (m) | Where |")
	w("|---|---|---|---|---|")
	for e in res["earthworks"]:
		x, z, _, _ = along(r, (e["from"] + e["to"]) / 2)
		w("| %s | %.0f | %.0f | %.1f | near (%.0f, %.0f) |" % (e["kind"], e["from"], e["to"], e["max"], x, z))
	w("")
	w("### Salt Creek and the canyon")
	w("")
	w("| Vertex | X | Z | Bed Y | Natural ground over the bed | Rim to rim (m) |")
	w("|---|---|---|---|---|---|")
	for i, dep, width in res["canyon_depths"]:
		v = d["water"]["creek"]["line"][i]
		w("| %d | %d | %d | %.1f | %.1f | %.0f |" % (i, v[0], v[1], v[2], dep, width))
	w("")
	w("### Roads")
	w("")
	w("Grades over 20 m windows on the shaped ground; bridges at their decks. Period practice (PROPOSED limits): wagon roads aim at 6 % and take 10 % only in short pitches; farm lanes the same; horse tracks to 15 %; foot paths steeper.")
	w("")
	w("| Road | Class | Length (m) | Low Y | High Y | Steepest | Over 6 % | Over 10 % | Status |")
	w("|---|---|---|---|---|---|---|---|---|")
	for rd in d["roads"]:
		x, z, y, s = plan.road_profile(rd["line"], cls=rd["class"], fills=rd.get("crosses", ()))
		g = np.abs(plan.grades(y, s))
		over6 = (g > 6).mean() * s[-1]
		over10 = (g > 10).mean() * s[-1]
		lim = {"wagon": 10, "lane": 10, "track": 15, "path": 30}[rd["class"]]
		over = (g > lim + 0.5).mean() * s[-1]
		w("| %s | %s | %.0f | %.1f | %.1f | %.1f %% | %.0f m | %.0f m | %s |" % (rd["name"], rd["class"], s[-1], y.min(), y.max(), g.max(), over6, over10,
			"ok" if over == 0 else ("a short pitch (%.0f m over %d %%)" % (over, lim) if over <= 30 else "TOO STEEP")))
	w("")
	w("## F. Travel from the crossroads")
	w("")
	w("By the road network (shortest way), the game's walk (2.8 m/s) and the PROPOSED horse gaits: trot 3.9 m/s, canter 5.5 m/s.")
	w("")
	w("| To | Straight (m) | By road (m) | Walk | Trot | Canter | Climb / descent (m) | Crossings on the way | Roads |")
	w("|---|---|---|---|---|---|---|---|---|")
	for j in jr:
		w("| %s | %.0f | %.0f | %s | %s | %s | +%.0f / -%.0f | %s | %s |" % (j["name"], j["straight"], j["road"], fmt_min(j["walk"]), fmt_min(j["trot"]), fmt_min(j["canter"]),
			j["gain"], j["loss"], "; ".join(dict.fromkeys(j["obstacles"])) or "-", " > ".join(j["roads"])))
	w("")
	legs, brakes, stop = train_numbers(plan)
	w("### The train")
	w("")
	w("| From | To | Track (m) | At 22 km/h (planned) | At 32 km/h (max) |")
	w("|---|---|---|---|---|")
	for a, b, dd, t1, t2 in legs:
		w("| %s | %s | %.0f | %s | %s |" % (a, b, dd, fmt_min(t1), fmt_min(t2)))
	w("")
	w("Stopping distance with the brakes full on (brake_g %.3f, set along the train over %.0f s): " % (plan.speeds["train_brake_g"], plan.speeds["train_brake_setup_s"]) +
		"; ".join("%d km/h %.0f m" % (k, v) for k, v in brakes) + ". The engineer's planned service stop takes about 1/0.6 of these.")
	w("")
	w("### Can the trestle be seen? (lines of sight over the shaped ground; buildings not counted)")
	w("")
	w("| Viewpoint | Distance (m) | Deck seen (share of the span) | Of the whole bridge | Deepest seen below the rail |")
	w("|---|---|---|---|---|")
	for v in vis:
		w("| %s | %.0f | %d %% | %d %% | %.0f m |" % (v["name"], v["dist"], v["deck"] * 100, v["all"] * 100, v["deepest"]))
	w("")
	with open(path, "w") as f:
		f.write("\n".join(L) + "\n")


# ---------------------------------------------------------------- drawing

INK = "#0b0b0b"
INK2 = "#52514e"
WATER = "#2a78d6"
ROAD = "#7a5a2e"
RAIL = "#0b0b0b"
STRUCT = "#e34948"
CAT = {"town": "#eb6834", "rail": "#52514e", "industry": "#6250d6", "homestead": "#1baf7a", "baron": "#e34948", "community": "#eda100",
	"outlaw": "#0b0b0b", "wild": "#008300", "mission": "#e87ba4", "edge": "#52514e"}
MARK = {"town": "s", "rail": "s", "industry": "D", "homestead": "o", "baron": "^", "community": "h", "outlaw": "X", "wild": "P", "mission": "*", "edge": ">"}
CATNAME = {"town": "Town and its buildings", "rail": "Railroad facilities", "industry": "Mine, Ore Works, timber", "homestead": "Homesteads",
	"baron": "The Baron's", "community": "Southern Ute community", "outlaw": "Outlaw hideout (OPEN)", "wild": "Wilderness pockets", "mission": "Mission sites"}


def _plt():
	import matplotlib
	matplotlib.use("Agg")
	import matplotlib.pyplot as plt
	return plt


def hillshade(h, g):
	gz, gx = np.gradient(h, g)
	az, alt = math.radians(315), math.radians(40)
	slope = np.arctan(np.hypot(gx, gz))
	aspect = np.arctan2(-gx, gz)
	return np.clip(np.sin(alt) * np.cos(slope) + np.cos(alt) * np.sin(slope) * np.cos(az - aspect), 0, 1)


def tint(h):
	"""Elevation tint: the valley's dry palette, low (ochre) to high (pine-dark)."""
	stops = [(-35, (0.80, 0.74, 0.58)), (-10, (0.86, 0.80, 0.62)), (5, (0.90, 0.85, 0.68)), (30, (0.86, 0.79, 0.60)), (80, (0.74, 0.70, 0.52)), (160, (0.58, 0.60, 0.44))]
	out = np.zeros(h.shape + (3,))
	for (h0, c0), (h1, c1) in zip(stops[:-1], stops[1:]):
		m = (h >= h0) & (h < h1)
		t = ((h - h0) / (h1 - h0))[m][:, None]
		out[m] = np.array(c0) * (1 - t) + np.array(c1) * t
	out[h < stops[0][0]] = stops[0][1]
	out[h >= stops[-1][0]] = stops[-1][1]
	return out


class View:
	"""The master map's orientation: west at the top, north on the right, east at the bottom,
	south on the left. Screen u (right) = -z, screen v (down) = +x."""

	def __init__(self, rotated=True):
		self.rot = rotated

	def uv(self, x, z):
		x = np.asarray(x, float)
		z = np.asarray(z, float)
		return (-z, x) if self.rot else (x, z)


def draw_master(plan, res, jr, vis, path):
	plt = _plt()
	from matplotlib.lines import Line2D
	from matplotlib.patches import Polygon, Rectangle, FancyArrow
	d = plan.data
	T = plan.terrain
	V = View(True)
	env = d["envelope"]["playable"]
	fig = plt.figure(figsize=(19, 19.5), dpi=110)
	ax = fig.add_axes([0.05, 0.04, 0.70, 0.87])
	# terrain image: rows = x (down), cols = -z (right)
	h = T.h
	img = tint(h) * (0.55 + 0.45 * hillshade(h, T.g))[..., None]
	img = np.transpose(img, (1, 0, 2))[:, ::-1]  # [x, -z]
	ax.imshow(img, extent=[-T.zs[-1], -T.zs[0], T.xs[-1], T.xs[0]], interpolation="bilinear", zorder=0)
	U, Vv = V.uv(T.XX, T.ZZ)
	lv = np.arange(-40, 200, 5)
	cs = ax.contour(U, Vv, h, levels=lv, colors=INK2, linewidths=0.25, alpha=0.45, zorder=1)
	ci = ax.contour(U, Vv, h, levels=np.arange(-25, 200, 25), colors=INK2, linewidths=0.7, alpha=0.75, zorder=1)
	ax.clabel(ci, fmt="%d", fontsize=7, inline=True)
	# the canyon: rims as a hatched band
	cr = np.array(d["water"]["creek"]["line"])
	a, b = d["water"]["canyon"]["from_vertex"], d["water"]["canyon"]["to_vertex"]
	can = resample(cr[a:b + 1], 8)
	left, right = [], []
	for i in range(len(can)):
		i0, i1 = max(i - 1, 0), min(i + 1, len(can) - 1)
		dx, dz = can[i1, 0] - can[i0, 0], can[i1, 1] - can[i0, 1]
		n = math.hypot(dx, dz)
		nx, nz = -dz / n, dx / n
		hw = can[i, 3]
		left.append((can[i, 0] + nx * hw, can[i, 1] + nz * hw))
		right.append((can[i, 0] - nx * hw, can[i, 1] - nz * hw))
	poly = np.array(left + right[::-1])
	pu, pv = V.uv(poly[:, 0], poly[:, 1])
	ax.add_patch(Polygon(np.column_stack([pu, pv]), closed=True, fill=False, hatch="////", edgecolor="#8a4b2a", linewidth=1.0, zorder=2))
	# water
	for key, col, lw, ls in (("creek", WATER, 2.4, "-"), ("arroyo", "#b08850", 1.6, (0, (6, 2)))):
		Lw = np.array(d["water"][key]["line"])
		u, v = V.uv(Lw[:, 0], Lw[:, 1])
		ax.plot(u, v, color=col, lw=lw, ls=ls, zorder=4, solid_capstyle="round")
	dl = np.array(d["water"]["ditch"]["line"])
	u, v = V.uv(dl[:, 0], dl[:, 1])
	ax.plot(u, v, color=WATER, lw=0.9, ls=":", zorder=4)
	for sp in d["water"]["springs"]:
		u, v = V.uv(*sp["at"])
		ax.plot(u, v, "o", ms=6, mfc="white", mec=WATER, mew=1.6, zorder=6)
	# roads
	for rd in d["roads"]:
		Lr = np.array(rd["line"])
		u, v = V.uv(Lr[:, 0], Lr[:, 1])
		style = {"wagon": dict(lw=2.4, ls="-"), "lane": dict(lw=1.6, ls="-"), "track": dict(lw=1.3, ls=(0, (5, 2))), "path": dict(lw=1.1, ls=(0, (1.5, 2)))}[rd["class"]]
		ax.plot(u, v, color=ROAD, zorder=5, solid_capstyle="round", **style)
	# rail
	r = plan.rail
	m = plan.marks
	sel = r["s"] <= m["west_portal"]
	u, v = V.uv(r["x"][sel], r["z"][sel])
	ax.plot(u, v, color=RAIL, lw=3.0, zorder=7)
	ax.plot(u, v, color="white", lw=1.2, ls=(0, (3, 5)), zorder=8)
	selt = r["s"] > m["west_portal"]
	u, v = V.uv(r["x"][selt], r["z"][selt])
	ax.plot(u, v, color=RAIL, lw=1.5, ls=(0, (2, 2)), zorder=7)
	for tk in d["railway"]["tracks"]:
		a0 = m[tk["from_mark"]] if "from_mark" in tk else tk["from"]
		b0 = m[tk["to_mark"]] if "to_mark" in tk else tk["to"]
		ss = (r["s"] >= a0) & (r["s"] <= b0)
		hd = np.radians(r["h"][ss])
		off = tk["offset"]
		# north side of a westbound line is its right: (x, z) + right normal
		nx, nz = np.cos(hd), np.sin(hd)
		sgn = 1.0
		uu, vv = V.uv(r["x"][ss] + sgn * nx * off, r["z"][ss] + sgn * nz * off)
		ax.plot(uu, vv, color=RAIL, lw=1.2, zorder=7)
	# structures
	c = plan.route["crossings"][0]
	ss = (r["s"] >= c["from"]) & (r["s"] <= c["to"])
	u, v = V.uv(r["x"][ss], r["z"][ss])
	ax.plot(u, v, color=STRUCT, lw=7, zorder=9, solid_capstyle="butt")
	for bid, lab in (("bridge_c", "C  great trestle"), ("bridge_b", "B  overpass"), ("bridge_a", "A  creek crossing"), ("bridge_t", "town bridge")):
		bx, bz = plan.bridges[bid]["_at"]
		u, v = V.uv(bx, bz)
		ax.plot(u, v, marker="s" if bid != "bridge_c" else None, ms=10, mfc=STRUCT, mec="white", mew=1.2, zorder=10)
		off = {"bridge_t": (-60, 10), "bridge_c": (14, -34)}.get(bid, (10, -12))
		ax.annotate(lab, (u, v), xytext=off, textcoords="offset points", fontsize=11, fontweight="bold", color=INK,
			bbox=dict(boxstyle="round,pad=0.2", fc="white", ec=STRUCT, lw=1.0), zorder=11)
	# the town's footprint
	tg = d["town"]["ground"]["rect"]
	u0, v0 = V.uv(tg["x"][0], tg["z"][1])
	ax.add_patch(Rectangle((u0, v0), tg["z"][1] - tg["z"][0], tg["x"][1] - tg["x"][0], fill=False, ec=CAT["town"], lw=1.6, ls="--", zorder=6))
	for side, z0 in (("north", -10.05), ("south", 10.05)):
		for lot in d["town"][side]:
			if lot["kind"] not in ("building", "yard"):
				continue
			zz = (z0, z0 - 30) if side == "north" else (z0, z0 + 30)
			uu, vv = V.uv(lot["x0"], max(zz))
			ax.add_patch(Rectangle((uu, vv), 30, lot["x1"] - lot["x0"], fc=CAT["town"], ec="none", alpha=0.55, zorder=6))
	# places
	for p in d["places"]:
		if p["id"] == "town":
			continue
		u, v = V.uv(*p["at"])
		cat = p["cat"]
		pd = p.get("pad")
		if pd and pd["w"] >= 60:
			ax.add_patch(Rectangle((u - pd["d"] / 2, v - pd["w"] / 2), pd["d"], pd["w"], fill=False, ec=CAT.get(cat, INK), lw=1.2, zorder=6))
		ax.plot(u, v, marker=MARK.get(cat, "o"), ms=10, mfc=CAT.get(cat, INK), mec="white", mew=1.2, zorder=12)
		if p["id"] in ("depot", "freight_warehouse", "water_tank", "rail_yard", "stock_pens", "church", "cemetery", "powder_magazine"):
			continue
		ax.annotate(p["name"].split(" (")[0], (u, v), xytext=(9, 6), textcoords="offset points", fontsize=10, color=INK,
			bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.8), zorder=13)
	u, v = V.uv(30, 0)
	ax.annotate("SALT CREEK\n(town: see the inset)", (u, v), xytext=(-150, 18), textcoords="offset points", fontsize=12, fontweight="bold", color=INK,
		bbox=dict(boxstyle="round,pad=0.3", fc="white", ec=CAT["town"], lw=1.2), arrowprops=dict(arrowstyle="-", color=CAT["town"]), zorder=13)
	# viewpoints and their lines to the trestle
	tr = res["trestle"]
	vmap = {v["id"]: v for v in vis}
	for vp in d["viewpoints"]:
		u, v = V.uv(*vp["at"])
		ok = vmap[vp["id"]]["all"] >= 0.3
		ax.plot(u, v, marker="v", ms=8, mfc="#008300" if ok else "white", mec="#008300", mew=1.4, zorder=12)
		if ok:
			tu, tv = V.uv(tr["x"], tr["z"])
			ax.plot([u, tu], [v, tv], color="#008300", lw=0.8, ls=(0, (2, 3)), zorder=6, alpha=0.8)
	# labels for features
	labels = [((1090, -360), "Salt Creek Canyon", "#8a4b2a"), ((-1150, 760), "Salt Creek", WATER), ((-650, -330), "the dry arroyo", "#8a6a3a"),
		((900, -620), "lower basin", INK2), ((1700, 1150), "open grazing upland", INK2), ((-1850, -150), "sunset notch (beyond)", INK2),
		((-1800, -1150), "pine timber", INK2), ((-200, 1900), "southern rimrock mesas", INK2), ((-1850, 500), "western foothills", INK2),
		((2300, -390), "to Durango", INK2), ((-1990, -420), "tunnel", INK2)]
	for (x, z), t, col in labels:
		u, v = V.uv(x, z)
		ax.text(u, v, t, fontsize=11, style="italic", color=col, ha="center", va="center", zorder=13,
			bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.6))
	# the envelope
	u0, v0 = V.uv(env["x"][0], env["z"][1])
	ax.add_patch(Rectangle((u0, v0), env["z"][1] - env["z"][0], env["x"][1] - env["x"][0], fill=False, ec=INK, lw=2.0, zorder=14))
	ax.set_xlim(-env["z"][1] - 120, -env["z"][0] + 120)
	ax.set_ylim(env["x"][1] + 120, env["x"][0] - 120)
	ax.set_aspect("equal")
	tz = np.arange(-1500, 2300, 500)
	ax.set_xticks(-tz)
	ax.set_xticklabels(["z %d" % t for t in tz])
	tx = np.arange(-2000, 2500, 500)
	ax.set_yticks(tx)
	ax.set_yticklabels(["x %d" % t for t in tx])
	ax.set_xlabel("world Z (metres). North (-Z) is to the RIGHT", fontsize=12)
	ax.set_ylabel("world X (metres). West (-X) is at the TOP, east at the bottom", fontsize=12)
	ax.tick_params(labelsize=10, top=True, labeltop=True)
	ax.grid(color=INK2, lw=0.3, alpha=0.3)
	ax.set_title("Salt Creek Valley: master plan (Phase 1, PROPOSED geometry for review)\nGenerated from config/valley.json by tools/valley/valley_plan.py. Contours every 5 m, labelled every 25 m (Y from the crossroads)",
		fontsize=15, loc="left")
	# compass
	cax = fig.add_axes([0.80, 0.78, 0.15, 0.13])
	cax.set_xlim(-1, 1); cax.set_ylim(-1, 1); cax.axis("off"); cax.set_aspect("equal")
	for (dx, dy, lab) in ((0, 1, "W  (-X)"), (1, 0, "N (-Z)"), (0, -1, "E  (+X)"), (-1, 0, "S (+Z)")):
		cax.add_patch(FancyArrow(0, 0, dx * 0.6, dy * 0.6, width=0.05, head_width=0.18, color=INK if lab[0] in "WN" else INK2))
		cax.text(dx * 0.95, dy * 0.95 + (0.12 if dx else 0), lab, ha="center", va="center", fontsize=11, fontweight="bold",
			bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none"))
	cax.text(0, -1.25, "sunset: straight down Main Street, from the top", ha="center", fontsize=9, color=INK2)
	# scale bar
	ax.plot([-2050, -1050], [2440, 2440], color=INK, lw=4, zorder=15)
	ax.text(-1550, 2410, "1 km", ha="center", fontsize=11, zorder=15)
	# legend
	lax = fig.add_axes([0.765, 0.33, 0.23, 0.42])
	lax.axis("off")
	H = [Line2D([], [], color=WATER, lw=2.4, label="Salt Creek"),
		Line2D([], [], color="#b08850", lw=1.6, ls=(0, (6, 2)), label="dry arroyo (the mine's drainage)"),
		Line2D([], [], color=WATER, lw=0.9, ls=":", label="town ditch"),
		Line2D([], [], color="#8a4b2a", lw=1.0, label="canyon rims (hatched)"),
		Line2D([], [], color=RAIL, lw=3.0, label="main line (dashed: in the tunnel)"),
		Line2D([], [], color=STRUCT, lw=6, label="Bridge C, the great trestle"),
		Line2D([], [], color=STRUCT, marker="s", ls="", ms=9, label="Bridges A, B and the town bridge"),
		Line2D([], [], color=ROAD, lw=2.4, label="wagon road"), Line2D([], [], color=ROAD, lw=1.6, label="lane"),
		Line2D([], [], color=ROAD, lw=1.3, ls=(0, (5, 2)), label="horse track"), Line2D([], [], color=ROAD, lw=1.1, ls=(0, (1.5, 2)), label="foot path"),
		Line2D([], [], color="#008300", marker="v", ls="", ms=8, label="viewpoint (filled: sees the bents)")]
	for cat in ("town", "rail", "industry", "homestead", "baron", "community", "outlaw", "wild", "mission"):
		H.append(Line2D([], [], color=CAT[cat], marker=MARK[cat], ls="", ms=9, mec="white", label=CATNAME[cat]))
	H.append(Line2D([], [], color=INK, lw=2, label="playable area, 4.4 x 3.6 km"))
	lax.legend(handles=H, loc="upper left", fontsize=10.5, frameon=False, labelspacing=0.75)
	# notes
	nax = fig.add_axes([0.765, 0.04, 0.23, 0.27])
	nax.axis("off")
	notes = ["Railway order, east to west (DECIDED):", "  east entrance > overpass B > trestle C", "  > depot > Ore Works > tunnel west.",
		"", "Track: overpass to trestle %d m;" % (m["trestle_east"] - m["overpass"]), "  trestle to depot %d m;" % (m["depot"] - m["trestle_west"]),
		"  depot to Ore Works %d m." % (m["ore_works"] - m["depot"]), "",
		"Trestle: %.0f m east of the crossroads," % res["trestle"]["x"], "  rail %.1f m over the creek floor." % res["trestle"]["depth"],
		"", "Salt Creek flows from the south-west,", "  past the town's south edge, east,", "  north through the canyon, out north-east.",
		"", "Every number is PROPOSED until Sean", "approves it (docs/briefs/valley-plan.md)."]
	nax.text(0, 1, "\n".join(notes), va="top", fontsize=11, family="monospace")
	fig.savefig(path, dpi=110)
	plt.close(fig)


def draw_town(plan, path):
	plt = _plt()
	from matplotlib.patches import Rectangle, Polygon
	from matplotlib.lines import Line2D
	d = plan.data
	t = d["town"]
	T = plan.terrain
	fig = plt.figure(figsize=(20, 15), dpi=100)
	ax = fig.add_axes([0.05, 0.06, 0.72, 0.86])
	X0, X1, Z0, Z1 = -280, 300, -260, 200
	sel_x = (T.xs >= X0 - 20) & (T.xs <= X1 + 20)
	sel_z = (T.zs >= Z0 - 20) & (T.zs <= Z1 + 20)
	hh = T.h[np.ix_(sel_z, sel_x)]
	img = tint(hh) * (0.7 + 0.3 * hillshade(hh, T.g))[..., None]
	# north up: plot (x, -z)
	ax.imshow(img[::-1], extent=[T.xs[sel_x][0], T.xs[sel_x][-1], -T.zs[sel_z][-1], -T.zs[sel_z][0]], origin="lower", interpolation="bilinear", zorder=0)
	XX, ZZ = np.meshgrid(T.xs[sel_x], T.zs[sel_z])
	ci = ax.contour(XX, -ZZ, hh, levels=np.arange(-12, 20, 1), colors=INK2, linewidths=0.35, alpha=0.5, zorder=1)
	ax.clabel(ci, levels=ci.levels[::2], fmt="%d", fontsize=7)
	ms = t["main_street"]
	W = ms["width_between_fronts"]
	ax.add_patch(Rectangle((ms["x"][0] - 40, -W / 2), ms["x"][1] - ms["x"][0] + 80, W, fc="#d8c9a4", ec="none", zorder=2))
	ns = t["ns_street"]
	ax.add_patch(Rectangle((-ns["width"] / 2, -112), ns["width"], 112 + 74.5, fc="#d8c9a4", ec="none", zorder=2))
	for key in ("back_street", "rear_lane"):
		s = t[key]
		ax.add_patch(Rectangle((s["x"][0], -s["z"][1]), s["x"][1] - s["x"][0], s["z"][1] - s["z"][0], fc="#e2d5b4", ec="none", zorder=2))
	kinds = {"building": dict(fc=CAT["town"], alpha=0.85), "yard": dict(fc="#c9b98f", alpha=0.9), "lane": dict(fc="#f2e9d0", alpha=1),
		"alley": dict(fc="#e34948", alpha=0.95), "tight": dict(fc=INK, alpha=1), "vacant": dict(fc="#f2e9d0", alpha=1), "houses": dict(fc="#1baf7a", alpha=0.35)}
	for side, z0, sgn in (("north", -W / 2, -1), ("south", W / 2, 1)):
		for lot in t[side]:
			k = lot["kind"]
			depth = lot.get("depth", t["lot_depth"]) if k == "building" else t["lot_depth"]
			if k in ("lane", "alley", "tight", "vacant", "yard", "houses"):
				depth = t["lot_depth"]
			proposed = "PROPOSED" in lot.get("status", "") or lot["id"] in ("bank", "land_office", "assay_office")
			zz0 = z0
			zz1 = z0 + sgn * depth
			y0 = -max(zz0, zz1)
			st = dict(kinds[k])
			ax.add_patch(Rectangle((lot["x0"], y0), lot["x1"] - lot["x0"], depth, ec="white" if not proposed else INK, lw=1.4 if proposed else 0.6,
				ls="--" if proposed else "-", zorder=4, **st))
			# lot line behind
			ax.add_patch(Rectangle((lot["x0"], -max(z0, z0 + sgn * t["lot_depth"])), lot["x1"] - lot["x0"], t["lot_depth"], fill=False, ec=INK2, lw=0.3, zorder=3))
			if k in ("building", "yard", "vacant", "houses"):
				lab = lot["name"].split(" (")[0].split(":")[0]
				ax.text((lot["x0"] + lot["x1"]) / 2, y0 + depth / 2, lab, rotation=90, ha="center", va="center", fontsize=8.5, color=INK, zorder=6)
			if k == "alley":
				ax.annotate("%.1f m alley" % (lot["x1"] - lot["x0"]), ((lot["x0"] + lot["x1"]) / 2, y0 + (depth if side == "north" else 0)),
					xytext=(0, 26 if side == "north" else -30), textcoords="offset points", ha="center", fontsize=8, color=STRUCT,
					arrowprops=dict(arrowstyle="-", color=STRUCT, lw=0.8), zorder=7)
	# the rail, the depot area
	r = plan.rail
	ss = (r["x"] > X0 - 50) & (r["x"] < X1 + 50)
	ax.plot(r["x"][ss], -r["z"][ss], color=RAIL, lw=2.5, zorder=5)
	for tk in d["railway"]["tracks"][:2]:
		ax.plot(r["x"][ss], -(r["z"][ss] - tk["offset"]), color=RAIL, lw=1.0, zorder=5)
	for pid in ("depot", "freight_warehouse", "rail_yard", "stock_pens", "church", "cemetery", "baron_town_house"):
		p = plan.places[pid]
		pd = p["pad"]
		proposed = p["status"].startswith("PROPOSED")
		ax.add_patch(Rectangle((p["at"][0] - pd["w"] / 2, -p["at"][1] - pd["d"] / 2), pd["w"], pd["d"], fc=CAT.get(p["cat"], INK), alpha=0.7,
			ec=INK, lw=1.2 if proposed else 0.5, ls="--" if proposed else "-", zorder=4))
		short = {"depot": "Depot", "freight_warehouse": "Freight", "rail_yard": "Rail yard", "stock_pens": "Old stock pens", "baron_town_house": "Baron's house"}.get(pid, p["name"].split(" (")[0])
		ax.text(p["at"][0], -p["at"][1] + (5 if pid in ("depot",) else 0), short, ha="center", va="center", fontsize=8.5, zorder=6,
			bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none", alpha=0.7))
	ax.plot(81, 66, "o", ms=9, mfc=CAT["rail"], mec="white", zorder=6)
	ax.text(81, 72, "water tank", fontsize=8, ha="center", zorder=6)
	for ex in t["extras"]:
		if "at" in ex and "w" in ex:
			ax.add_patch(Rectangle((ex["at"][0] - ex["w"] / 2, -ex["at"][1] - ex["d"] / 2), ex["w"], ex["d"], fc=CAT["town"], alpha=0.6, ec=INK, lw=1.2, ls="--", zorder=4))
			ax.text(ex["at"][0], -ex["at"][1], "2nd saloon", ha="center", va="center", fontsize=8.5, zorder=6)
	# water
	for key, col, lw in (("creek", WATER, 5), ("arroyo", "#b08850", 3)):
		Lw = np.array(d["water"][key]["line"])
		ax.plot(Lw[:, 0], -Lw[:, 1], color=col, lw=lw, zorder=3)
	dl = np.array(d["water"]["ditch"]["line"])
	ax.plot(dl[:, 0], -dl[:, 1], color=WATER, lw=1.2, ls=":", zorder=3)
	# roads and exits
	for rd in d["roads"]:
		Lr = np.array(rd["line"])
		ax.plot(Lr[:, 0], -Lr[:, 1], color=ROAD, lw=3 if rd["class"] == "wagon" else 1.8, ls="-" if rd["class"] in ("wagon", "lane") else (0, (5, 2)), zorder=3)
	exits = [((-275, 20), "West Road to the Ore Works (1.5 km), sunset straight down Main Street", "left"), ((290, -45), "East Road: Bridge A, the canyon, overpass, widow's", "right"),
		((30, -190), "South Road (the Baron's) and Harlan's lane over the town bridge", "left"), ((-235, -150), "Ute trail", "left"),
		((-250, 250), "timber road over the arroyo", "left")]
	for (x, y), txt, ha in exits:
		ax.text(x, y, txt, fontsize=9, ha=ha, color=ROAD, style="italic", zorder=8, bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none", alpha=0.7))
	b = plan.bridges["bridge_t"]
	ax.add_patch(Rectangle((-4, -b["at"][1] - 7), 8, 14, fc=STRUCT, ec="white", zorder=6))
	ax.text(8, -b["at"][1] - 4, "town bridge", fontsize=8.5, zorder=7)
	ax.set_xlim(X0, X1)
	ax.set_ylim(-Z1, -Z0)
	ax.set_aspect("equal")
	xt = np.arange(-250, 301, 50)
	ax.set_xticks(xt)
	ax.set_xticklabels(["x %d" % v for v in xt])
	zt = np.arange(-250, 201, 50)
	ax.set_yticks(-zt)
	ax.set_yticklabels(["z %d" % v for v in zt])
	ax.set_xlabel("world X (east to the right)", fontsize=11)
	ax.set_ylabel("world Z (north, -Z, at the top: as Sean's November 7 picture)", fontsize=11)
	ax.grid(color=INK2, lw=0.3, alpha=0.3)
	ax.set_title("Salt Creek town, enlarged (north up, as the November 7 picture). Lots measured off the picture at 5 px a metre along Main Street.\n"
		"Solid: as drawn. Dashed outline: PROPOSED story buildings. Red slivers: the 1-1.5 m gameplay alleys. Contours every 1 m.", fontsize=13, loc="left")
	lax = fig.add_axes([0.78, 0.35, 0.21, 0.55])
	lax.axis("off")
	H = [Rectangle((0, 0), 1, 1, fc=CAT["town"], alpha=0.85, label="building (as drawn)"), Rectangle((0, 0), 1, 1, fc=CAT["town"], alpha=0.6, ec=INK, ls="--", label="PROPOSED story building"),
		Rectangle((0, 0), 1, 1, fc="#c9b98f", label="yard"), Rectangle((0, 0), 1, 1, fc="#f2e9d0", ec=INK2, label="lane / vacant lot"),
		Rectangle((0, 0), 1, 1, fc="#e34948", label="gameplay alley (1.2 m)"), Rectangle((0, 0), 1, 1, fc=INK, label="shoulder to shoulder"),
		Rectangle((0, 0), 1, 1, fc="#1baf7a", alpha=0.35, label="houses and gardens"), Line2D([], [], color=RAIL, lw=2.5, label="main line, passing siding, team track"),
		Line2D([], [], color=WATER, lw=5, label="Salt Creek"), Line2D([], [], color=WATER, lw=1.2, ls=":", label="town ditch to the cistern"),
		Line2D([], [], color=ROAD, lw=3, label="wagon road")]
	lax.legend(handles=H, loc="upper left", fontsize=10, frameon=False, labelspacing=1.0)
	nax = fig.add_axes([0.78, 0.06, 0.21, 0.27])
	nax.axis("off")
	front = max(l["x1"] for l in t["north"] + t["south"]) - min(l["x0"] for l in t["north"] + t["south"])
	notes = ["Main Street: %d m of frontage, %.1f m" % (front, W), "  between fronts (66 ft), due west.",
		"Lots %.1f m deep; Back Street and the" % t["lot_depth"], "  rear lane 6.1 m (20 ft).",
		"Main line z %.1f; creek z +112:" % float(np.mean(r["z"][(r["x"] > -100) & (r["x"] < 100)])), "  %.0f m rail to creek (the picture's" % (112 + 74.5), "  notes say 300: OPEN).",
		"Saloon on the north corner, the stone", "  jail opposite (DECIDED).", "Lanes and alleys where the picture", "  draws them (Sean, 2026-11-07)."]
	nax.text(0, 1, "\n".join(notes), va="top", fontsize=11, family="monospace")
	fig.savefig(path, dpi=100)
	plt.close(fig)


def draw_profiles(plan, res, path):
	plt = _plt()
	d = plan.data
	T = plan.terrain
	r = plan.rail
	m = plan.marks
	fig, axs = plt.subplots(3, 2, figsize=(20, 17), dpi=100, gridspec_kw=dict(height_ratios=[1.2, 1, 1]))
	# 1 the railway profile
	ax = axs[0, 0]
	sel = r["s"] <= m["west_portal"] + 120
	nat = T.at(r["x"][sel], r["z"][sel], T.shaped)
	carved = T.at(r["x"][sel], r["z"][sel], T.h)
	ax.fill_between(r["s"][sel], -40, nat, color="#d8c9a4", label="natural ground under the line")
	ax.plot(r["s"][sel], np.minimum(nat, plan.terrain.natural_at(r["x"][sel], r["z"][sel]) * 0 + nat), color=INK2, lw=0.5)
	# the canyon floor under the trestle
	c = plan.route["crossings"][0]
	cs = (r["s"] >= c["from"] - 40) & (r["s"] <= c["to"] + 40)
	ax.fill_between(r["s"][cs], -40, T.at(r["x"][cs], r["z"][cs], T.h), color="#b9a37a", label="the canyon under the trestle")
	ax.plot(r["s"][sel], r["y"][sel], color=RAIL, lw=2.2, label="rail top")
	ax.axvspan(c["from"], c["to"], color=STRUCT, alpha=0.18)
	for name, s in m.items():
		if s > m["west_portal"] + 100:
			continue
		ax.axvline(s, color=INK2, lw=0.5, ls=":")
		ax.text(s, 46, name.replace("_", " "), rotation=90, fontsize=8, va="top", ha="right", color=INK)
	for g in plan.route["profile"]["grades"]:
		if g[0] < m["west_portal"]:
			ax.text(g[0] + 15, -36, "%+.2f%%" % g[1], fontsize=8, color=INK2)
	ax.set_xlim(0, m["west_portal"] + 120)
	ax.set_ylim(-40, 50)
	ax.set_xlabel("metres along the line from the east entrance (east is left, west right)")
	ax.set_ylabel("Y (m)")
	ax.set_title("The main line's profile (TrainRoute's grades; vertical x10 roughly)", loc="left")
	ax.legend(loc="upper left", fontsize=9, frameon=False)
	ax.grid(alpha=0.3)
	# 2 cut and fill
	ax = axs[0, 1]
	s_cf, cf = res["cutfill"]
	ax.fill_between(s_cf, 0, cf, where=cf > 0, color="#8a6a3a", label="cut (ground over the formation)")
	ax.fill_between(s_cf, 0, cf, where=cf < 0, color="#2a78d6", alpha=0.6, label="fill (formation over the ground)")
	ax.axvspan(c["from"], c["to"], color=STRUCT, alpha=0.18, label="trestle span (no fill)")
	ax.axhline(3, color=INK2, lw=0.6, ls="--"); ax.axhline(-3, color=INK2, lw=0.6, ls="--")
	ax.set_ylim(-30, 30)
	ax.set_xlim(0, m["west_portal"] + 20)
	ax.set_xlabel("metres along the line")
	ax.set_ylabel("m")
	ax.set_title("Cut and fill along the line (formation = rail - 1 m); dashed: 3 m", loc="left")
	ax.legend(fontsize=9, frameon=False, loc="lower left")
	ax.grid(alpha=0.3)
	# 3 the creek
	ax = axs[1, 0]
	cr = np.array(d["water"]["creek"]["line"])
	P = resample(cr, 10)
	sP = np.concatenate([[0], np.cumsum(np.hypot(np.diff(P[:, 0]), np.diff(P[:, 1])))])
	banks = res["banks_creek"][1]
	ax.plot(sP, P[:, 2], color=WATER, lw=2, label="creek bed")
	ax.plot(sP[1:-1], P[1:-1, 2] + banks, color="#8a4b2a", lw=1.2, label="lower rim (natural ground at the channel's edge)")
	cv = np.concatenate([[0], np.cumsum(np.hypot(np.diff(cr[:, 0]), np.diff(cr[:, 1])))])
	for i, lab in ((7, "town"), (11, "Bridge A"), (15, "trestle"), (17, "canyon mouth"), (19, "widow's fields"), (22, "arroyo joins")):
		ax.axvline(cv[i], color=INK2, lw=0.5, ls=":")
		ax.text(cv[i], 58, lab, rotation=90, fontsize=9, va="top", ha="right")
	ax.axhline(r["y"][np.argmin(np.abs(r["s"] - m["trestle_mid"]))], color=RAIL, lw=1, ls="--", label="rail on the trestle")
	ax.set_xlabel("metres along Salt Creek from where it enters (south-west) to where it leaves (north-east)")
	ax.set_ylabel("Y (m)")
	ax.set_title("Salt Creek: always downhill; the canyon is where the rim stands far over the bed", loc="left")
	ax.legend(fontsize=9, frameon=False, loc="upper right")
	ax.grid(alpha=0.3)
	# 4 canyon sections
	ax = axs[1, 1]
	for vi, col, lab in ((11, "#eda100", "at Bridge A (head)"), (13, "#6250d6", "half way"), (15, STRUCT, "at the trestle"), (17, "#1baf7a", "at the mouth")):
		v = cr[vi]
		a0, b0 = cr[vi - 1], cr[vi + 1]
		dx, dz = b0[0] - a0[0], b0[1] - a0[1]
		n = math.hypot(dx, dz)
		nx, nz = -dz / n, dx / n
		tt = np.linspace(-110, 110, 221)
		ys = T.at(v[0] + nx * tt, v[1] + nz * tt)
		ax.plot(tt, ys, color=col, lw=1.8, label=lab)
	tr = res["trestle"]
	ax.plot([-65, 65], [tr["rail"], tr["rail"]], color=RAIL, lw=3, label="rail on the trestle (130 m)")
	ax.set_xlabel("metres across the canyon (west to east)")
	ax.set_ylabel("Y (m)")
	ax.set_aspect("equal")
	ax.set_title("Canyon sections, true scale", loc="left")
	ax.legend(fontsize=9, frameon=False, loc="lower right")
	ax.grid(alpha=0.3)
	# 5-6 roads
	for ax, ids in ((axs[2, 0], ("east_road", "harlan_lane", "south_road", "west_road")), (axs[2, 1], ("mine_road", "timber_road", "ranch_canyon_road", "hideout_trail"))):
		for rid, col in zip(ids, ("#2a78d6", "#eb6834", "#1baf7a", "#6250d6")):
			rd = plan.roads[rid]
			x, z, y, s = plan.road_profile(rd["line"], cls=rd["class"], fills=rd.get("crosses", ()))
			ax.plot(s, y, color=col, lw=1.8, label="%s (%s, steepest %.1f %%)" % (rd["name"], rd["class"], np.abs(plan.grades(y, s)).max()))
		ax.set_xlabel("metres along the road from its town end")
		ax.set_ylabel("Y (m)")
		ax.legend(fontsize=9, frameon=False, loc="upper left")
		ax.grid(alpha=0.3)
		ax.set_title("Road profiles", loc="left")
	fig.suptitle("Salt Creek Valley: profiles and sections (generated from config/valley.json)", fontsize=15, x=0.01, ha="left")
	fig.tight_layout(rect=[0, 0, 1, 0.97])
	fig.savefig(path, dpi=100)
	plt.close(fig)


def draw_decisions(plan, res, jr, path):
	plt = _plt()
	from matplotlib.patches import Rectangle
	d = plan.data
	r = plan.rail
	m = plan.marks
	fig, axs = plt.subplots(2, 2, figsize=(20, 16), dpi=100)
	V = View(True)

	def base(ax, xr, zr):
		Lw = np.array(d["water"]["creek"]["line"])
		u, v = V.uv(Lw[:, 0], Lw[:, 1])
		ax.plot(u, v, color=WATER, lw=2.5)
		sel = r["s"] <= m["west_portal"]
		u, v = V.uv(r["x"][sel], r["z"][sel])
		ax.plot(u, v, color=RAIL, lw=2.5)
		c = plan.route["crossings"][0]
		ss = (r["s"] >= c["from"]) & (r["s"] <= c["to"])
		u, v = V.uv(r["x"][ss], r["z"][ss])
		ax.plot(u, v, color=STRUCT, lw=7)
		for rd in d["roads"]:
			Lr = np.array(rd["line"])
			u, v = V.uv(Lr[:, 0], Lr[:, 1])
			ax.plot(u, v, color=ROAD, lw=1.0, alpha=0.5)
		u, v = V.uv(0, 0)
		ax.plot(u, v, "s", ms=14, color=CAT["town"])
		ax.text(u, v - 60, "town", ha="center", fontsize=11)
		for bid, lab in (("bridge_b", "B"), ("bridge_a", "A"), ("bridge_c", "C")):
			bx, bz = plan.bridges[bid]["_at"]
			u, v = V.uv(bx, bz)
			ax.plot(u, v, "s", ms=11, color=STRUCT)
			ax.text(u + 30, v, lab, fontsize=13, fontweight="bold")
		ax.set_xlim(-zr[1], -zr[0])
		ax.set_ylim(xr[1], xr[0])
		ax.set_aspect("equal")
		ax.set_xticks([]); ax.set_yticks([])
		ax.text(0.01, 0.99, "W at the top, N right", transform=ax.transAxes, va="top", fontsize=9, color=INK2)

	# H1 a: Nov 2 baseline
	jh = [j for j in jr if j["id"] == "harlan_homestead"][0]
	ax = axs[0, 0]
	base(ax, (-400, 2100), (-800, 900))
	u, v = V.uv(jh["pts"][:, 0], jh["pts"][:, 1])
	ax.plot(u, v, color="#1baf7a", lw=5)
	hx, hz = plan.places["harlan_homestead"]["at"]
	u, v = V.uv(hx, hz)
	ax.plot(u, v, "o", ms=14, color="#1baf7a")
	ax.text(u, v + 70, "Harlan", ha="center", fontsize=11)
	ax.set_title("Decision 1, option A (Nov 2 baseline, RECOMMENDED):\nHarlan's daily ride stays south of the creek: %.0f m, %s at a canter, %s at a trot.\nHe crosses the overpass only on the early missions (the widow's road)." % (
		jh["road"], fmt_min(jh["canter"]), fmt_min(jh["trot"])), loc="left", fontsize=12)
	# H1 b: Nov 7 alternative
	ax = axs[0, 1]
	base(ax, (-400, 2100), (-800, 900))
	bx, bz = plan.bridges["bridge_b"]["_at"]
	alt = (bx - 60, bz - 120)
	jalt = plan.journey((0, 0), (bx, bz))
	ln = jalt["length"] + math.hypot(alt[0] - bx, alt[1] - bz)
	u, v = V.uv(jalt["pts"][:, 0], jalt["pts"][:, 1])
	ax.plot(u, v, color="#e87ba4", lw=5)
	u, v = V.uv(*alt)
	ax.plot(u, v, "o", ms=14, color="#e87ba4")
	ax.text(u - 80, v + 40, "Harlan\n(moved)", ha="center", fontsize=11)
	ax.set_title("Decision 1, option B (Nov 7 comment): his daily ride crosses the overpass.\nThe overpass is east of the trestle (hard rule), so his house moves there, north of the rail:\n"
		"%.0f m, %s at a canter: the two-minute ride is lost. No layout gives both." % (ln, fmt_min(ln / plan.speeds["horse_canter"])), loc="left", fontsize=12)
	# trestle position
	ax = axs[1, 0]
	ax.set_xlim(-300, 4200)
	ax.set_ylim(-1, 3)
	ax.axis("off")
	rows = [("PROPOSED: %.2f km" % (res["trestle"]["x"] / 1000), res["trestle"]["x"], 2.2, "#1baf7a"), ("the picture's 3.5 km", 3500, 1.2, "#e87ba4")]
	for lab, xt, yy, col in rows:
		ax.plot([0, 4000], [yy, yy], color=RAIL, lw=2)
		ax.plot(0, yy, "s", ms=14, color=CAT["town"])
		ax.plot([xt - 65, xt + 65], [yy, yy], color=STRUCT, lw=9)
		ax.plot(xt + 680, yy, "s", ms=11, color=STRUCT)
		ax.text(xt + 700, yy + 0.18, "B", fontsize=12, fontweight="bold")
		ax.text(xt, yy + 0.25, "C", fontsize=12, fontweight="bold", ha="center")
		ax.text(-250, yy + 0.35, lab, fontsize=12, color=col, fontweight="bold")
		ax.text(0, yy - 0.35, "town", fontsize=10, ha="center")
	ax.text(-250, 0.4, "Track kept from the overpass to the trestle (%d m) in both, for boarding and the fight back to the cab.\n"
		"At %.1f km the train is seen crossing every day from the East Road, Bridge A and the widow's; the valley stays 4.4 km wide.\n"
		"At 3.5 km the overpass and the widow's fall off a 4 km map." % (m["trestle_east"] - m["overpass"], res["trestle"]["x"] / 1000), fontsize=11, va="top")
	ax.set_title("Decision 2: where the trestle stands (east of the depot, along the line)", loc="left", fontsize=12)
	# town depth
	ax = axs[1, 1]
	ax.set_xlim(0, 10)
	ax.set_ylim(-45, 330)
	ax.axis("off")
	cols = [("picture as drawn\n(its own 5 px/m)", [("rail", 0), ("depot", 15), ("Back St", 31), ("Main St", 68), ("creek", 129)]),
		("PROPOSED\n(period lots)", [("main line", 0), ("depot", 15), ("Back St", 23), ("Main St", 74.5), ("rear lane", 125), ("creek", 186.5)]),
		("picture's notes\n(300 m)", [("rail", 0), ("Main St", 120), ("creek", 300)])]
	for i, (lab, items) in enumerate(cols):
		xx = 1.5 + i * 3.2
		top = max(v for _, v in items)
		ax.add_patch(Rectangle((xx - 0.3, 0), 0.6, top, fc="#d8c9a4", ec=INK2))
		for name, v in items:
			ax.plot([xx - 0.45, xx + 0.45], [v, v], color=INK, lw=1.5)
			ax.text(xx + 0.55, v, "%s %d" % (name, v), va="center", fontsize=10)
		ax.text(xx, -8, lab, ha="center", va="bottom", fontsize=11, fontweight="bold")
	ax.invert_yaxis()
	ax.set_title("Decision 3: the town's depth, rail to creek (metres)", loc="left", fontsize=12)
	fig.tight_layout()
	fig.savefig(path, dpi=100)
	plt.close(fig)


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--check", action="store_true", help="the checks only")
	ap.add_argument("--out", default=os.path.join(ROOT, "docs", "concept"))
	ap.add_argument("--tables", default=os.path.join(ROOT, "docs", "briefs", "valley-tables.md"))
	args = ap.parse_args()
	plan = Plan()
	res = run_checks(plan)
	jr = journeys(plan)
	vis = visibility(plan, res)
	extra_checks(plan, res, jr, vis)
	for st, what, det in plan.checks:
		print("%-4s %s: %s" % (st, what, det))
	if not args.check:
		write_tables(plan, res, jr, vis, args.tables)
		draw_master(plan, res, jr, vis, os.path.join(args.out, "valley-map.png"))
		draw_town(plan, os.path.join(args.out, "valley-town.png"))
		draw_profiles(plan, res, os.path.join(args.out, "valley-profiles.png"))
		draw_decisions(plan, res, jr, os.path.join(args.out, "valley-decisions.png"))
		print("wrote", args.tables, "and docs/concept/valley-{map,town,profiles,decisions}.png")
	return 1 if any(c[0] == "FAIL" for c in plan.checks) else 0


if __name__ == "__main__":
	sys.exit(main())
