class_name ValleyRoads
extends RefCounted
## The valley's roads as one network (G4, #720; docs/briefs/valley-tables.md "F. Travel from the
## crossroads"): config/valley.json's roads and the town's own streets (Main Street, the North-South
## Street, Back Street and the rear lane, as tools/valley/valley_plan.py's `town_roads` lays them),
## a node every `STEP` m along each, linked along its road and to any other road's node within
## `JOIN` m (a junction), as the plan's `network` is built. `journey(a, b)` is the shortest way by
## road between two map points: its points from the node nearest a to the node nearest b, the roads
## it takes and its length, the plan's own route for its travel tables. Pure data, no nodes.

const STEP := 5.0
const JOIN := 6.0

var layout: ValleyLayout
## Node i: its map point, its road's id; its links [j, length].
var points := PackedVector2Array()
var owner: Array[String] = []
var links: Array = []


static func make(l: ValleyLayout) -> ValleyRoads:
	var r := ValleyRoads.new()
	r.layout = l
	r._build()
	return r


## The town's streets as roads for the network, as valley_plan.py's `town_roads` has them (Main
## Street along z 0; the North-South Street from 14 m past the rail's side to 12 m past the creek's).
static func town_roads(l: ValleyLayout) -> Array:
	var t := l.town()
	if t.is_empty():
		return []
	var ms: Dictionary = t.main_street
	var ns: Dictionary = t.ns_street
	var bs: Dictionary = t.back_street
	var rl: Dictionary = t.rear_lane
	return [
		{"id": "main_street", "line": [[ms.x[0], 0], [0, 0], [ms.x[1], 0]]},
		{"id": "ns_street", "line": [[0, float(ns.z[0]) + 14.0], [0, 0], [0, float(ns.z[1]) + 12.0]]},
		{"id": "back_street", "line": [[bs.x[0], -51.2], [0, -51.2], [bs.x[1], -51.2]]},
		{"id": "rear_lane", "line": [[rl.x[0], 51.2], [0, 51.2], [rl.x[1], 51.2]]},
	]


func _build() -> void:
	var roads: Array = layout.roads().duplicate()
	roads.append_array(town_roads(layout))
	for r: Dictionary in roads:
		var line := ValleyLayout.xz_line(r.line)
		var base := points.size()
		var pts := PackedVector2Array([line[0]])
		for i in range(1, line.size()):
			var n := maxi(1, ceili(line[i - 1].distance_to(line[i]) / STEP))
			for k in range(1, n + 1):
				pts.append(line[i - 1].lerp(line[i], float(k) / n))
		for i in pts.size():
			points.append(pts[i])
			owner.append(String(r.id))
			links.append([])
			if i > 0:
				var d := pts[i].distance_to(pts[i - 1])
				(links[base + i] as Array).append([base + i - 1, d])
				(links[base + i - 1] as Array).append([base + i, d])
	# Junctions: nodes of different roads within JOIN m, found through a grid of JOIN m cells.
	var grid := {}
	for i in points.size():
		var c := Vector2i(floori(points[i].x / JOIN), floori(points[i].y / JOIN))
		if not grid.has(c):
			grid[c] = []
		(grid[c] as Array).append(i)
	for i in points.size():
		var c := Vector2i(floori(points[i].x / JOIN), floori(points[i].y / JOIN))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for j: int in grid.get(c + Vector2i(dx, dz), []):
					if j > i and owner[j] != owner[i]:
						var d := points[i].distance_to(points[j])
						if d < JOIN:
							(links[i] as Array).append([j, d])
							(links[j] as Array).append([i, d])


func nearest(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in points.size():
		var d := points[i].distance_squared_to(p)
		if d < bd:
			bd = d
			best = i
	return best


## The shortest way by road from a to b: {points (map), roads (in order), length (m, along the
## roads plus the steps on and off them)}; empty if there's none.
func journey(a: Vector2, b: Vector2) -> Dictionary:
	var ia := nearest(a)
	var ib := nearest(b)
	if ia < 0 or ib < 0:
		return {}
	var dist := {ia: 0.0}
	var prev := {}
	var heap: Array = [[0.0, ia]]
	while not heap.is_empty():
		var top: Array = _pop(heap)
		var d: float = top[0]
		var u: int = top[1]
		if u == ib:
			break
		if d > float(dist.get(u, INF)):
			continue
		for l: Array in links[u]:
			var v: int = l[0]
			var nd: float = d + float(l[1])
			if nd < float(dist.get(v, INF)):
				dist[v] = nd
				prev[v] = u
				_push(heap, [nd, v])
	if not dist.has(ib):
		return {}
	var path: Array[int] = [ib]
	while path[-1] != ia:
		path.append(int(prev[path[-1]]))
	path.reverse()
	var pts := PackedVector2Array()
	var used: Array[String] = []
	for i in path:
		pts.append(points[i])
		if used.is_empty() or used[-1] != owner[i]:
			used.append(owner[i])
	return {"points": pts, "roads": used, "length": float(dist[ib]) + a.distance_to(points[ia]) + b.distance_to(points[ib])}


# A binary heap of [cost, node], least cost on top.
static func _push(h: Array, e: Array) -> void:
	h.append(e)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) >> 1
		if float(h[p][0]) <= float(h[i][0]):
			break
		var t: Variant = h[p]
		h[p] = h[i]
		h[i] = t
		i = p


static func _pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if h.is_empty():
		return top
	h[0] = last
	var i := 0
	while true:
		var l := i * 2 + 1
		var r := l + 1
		var m := i
		if l < h.size() and float(h[l][0]) < float(h[m][0]):
			m = l
		if r < h.size() and float(h[r][0]) < float(h[m][0]):
			m = r
		if m == i:
			break
		var t: Variant = h[m]
		h[m] = h[i]
		h[i] = t
		i = m
	return top
