class_name ValleyTown
extends Node3D
## The valley town's greybox (G5, #724; docs/briefs/valley-plan.md §3, §12): what stands between
## and in front of the lots' blocks (ValleyMarkers.blocks), from config/valley.json alone.
##
##   - **Boardwalks** (`walks`): the game's Boardwalk part along every building lot's front (the
##     town's `main_street.boardwalk_depth` deep, 0.38 m up), each its own level from the ground at
##     its street edge's middle, so they step up and down as the street falls (each owner built his
##     own: Sean's period guide, #467). A walk runs over a shoulder-to-shoulder gap (narrower than
##     TIGHT) to its neighbour's; where it ends at a lane, an alley, a yard or a street it steps down
##     to the ground (end steps); a flight of steps to the street in front of each lot's door, the
##     edge elsewhere a step too high (people come and go by the steps, as in the old town).
##   - **Passages** (`passages`): every way from Main Street to Back Street (north) or the rear lane
##     (south) between the blocks: the lanes, the 1.2 m gameplay alleys, the yards, the vacant lot,
##     the house lots and the unnamed gaps between buildings, each its lot's id (or `gap_<side>@x`).
##   - **The junk** (`junk`): a lot's `junk` (the undertaker's alley, plan §3) piled across it, crates
##     and boards in tiers of JUNK_TIER: climbed by jumping, not walked.
##   - **The town's ways** (`add_ways`): the places a man walks by in town and their links: Main
##     Street's middle (`main@x`), each building's door on its walk (the lot's id) and the foot of its
##     steps (`<id>_steps`), each passage's mouth on Main Street (its id) and its end on Back Street or
##     the rear lane (`<id>_back`), Back Street (`back@x`), the rear lane (`rear@x`), the North-South
##     Street (`ns@z`) and Creek Street (`creek@x`). `walk PLACE` routes round the blocks by them.

## A gap between two buildings narrower than this is shoulder to shoulder: their walks join over it.
const TIGHT := 1.0
## The walks' height over the ground at their street edge's middle (the old town's walk).
const WALK_TOP := 0.38
## A door's place: this far out from the lot's front, on its walk.
const DOOR_OUT := 0.6
## The flight of steps to the street before each door: its width (m).
const FLIGHT_W := 1.8
## The junk's tiers (m): each this much higher than the one before (a jump clears ~0.65 m: the
## player's jump_velocity 3.6 m/s), each tread this deep.
const JUNK_TIER := 0.5
const JUNK_TREAD := 0.6
const JUNK_COLOUR := Color(0.45, 0.36, 0.27)
## Where the town's streets run across (z of their middles), as ValleyRoads/valley_plan.py have them.
const BACK_Z := -51.2
const REAR_Z := 51.2

var layout: ValleyLayout
var terrain: ValleyTerrain

## {id, side, x0, x1 (world, west to east), y (its origin: the ground at its street edge's middle),
## top (world), door (x), joined_w, joined_e (the walk it meets over a tight gap, or ""), node} each.
var walks: Array[Dictionary] = []
## {id, side, x0, x1, x (its middle), kind, junk (bool)} each passage, west to east a side.
var passages: Array[Dictionary] = []
## {id, boxes: [{centre (Vector3, the box's middle), size}]} each lot's junk.
var junk: Array[Dictionary] = []
var junk_body: StaticBody3D
var front := 10.05
var walk_depth := 2.4
var build_ms := {}


func _init() -> void:
	name = "Town"


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	if terrain == null:
		terrain = ValleyTerrain.main()
	var ms: Dictionary = layout.town().get("main_street", {})
	front = float(ms.get("width_between_fronts", 20.1)) * 0.5
	walk_depth = float(ms.get("boardwalk_depth", 2.4))
	var u := Time.get_ticks_usec()
	_find_walks()
	_build_walks()
	build_ms["walks"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	_find_passages()
	_find_junk()
	_build_junk()
	build_ms["junk"] = (Time.get_ticks_usec() - u) / 1000.0


func ground(x: float, z: float) -> float:
	return terrain.height(x, z)


static func sign_of(side: String) -> float:
	return -1.0 if side == "north" else 1.0


## The buildings' extents on a side, west to east: [{id, x0, x1}] (the lots of kind building).
func _buildings(side: String) -> Array:
	var out := []
	for l: Dictionary in layout.lots(side):
		if l.get("kind", "") == "building":
			out.append({"id": String(l.id), "x0": float(l.x0), "x1": float(l.x1)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.x0 < b.x0)
	return out


# --- The boardwalks ----------------------------------------------------------------------------

func _find_walks() -> void:
	walks.clear()
	for side in ["north", "south"]:
		var sgn := sign_of(side)
		var bs := _buildings(side)
		for i in bs.size():
			var b: Dictionary = bs[i]
			var x1 := float(b.x1)
			var joined_e := ""
			if i + 1 < bs.size() and float(bs[i + 1].x0) - x1 < TIGHT:
				joined_e = String(bs[i + 1].id)
				x1 = float(bs[i + 1].x0)
			var joined_w := ""
			if i > 0 and float(b.x0) - float(bs[i - 1].x1) < TIGHT:
				joined_w = String(bs[i - 1].id)
			var door := (float(b.x0) + float(b.x1)) * 0.5
			var edge_z := sgn * (front - walk_depth)
			var y := ground((float(b.x0) + x1) * 0.5, edge_z)
			walks.append({"id": String(b.id), "side": side, "x0": float(b.x0), "x1": x1, "y": y, "top": y + WALK_TOP,
				"door": door, "joined_w": joined_w, "joined_e": joined_e, "node": null})


## A walk's x along it (its own space: north walks run east to west, their street side +Z; south
## walks west to east, theirs -Z).
static func _local_x(w: Dictionary, x: float) -> float:
	return float(w.x1) - x if w.side == "north" else x - float(w.x0)


func _build_walks() -> void:
	for w: Dictionary in walks:
		var bw := Boardwalk.new()
		bw.name = "Walk_%s" % w.id
		bw.structure_id = StringName("valley_walk_%s" % w.id)
		bw.build_seed = hash(String(w.id)) & 0xffff
		bw.length = float(w.x1) - float(w.x0)
		bw.walk_depth = walk_depth
		bw.top = WALK_TOP
		bw.steps = [Vector2(_local_x(w, float(w.door)), FLIGHT_W)]
		var ends := []
		# End 0 is the walk's start (east on the north side, west on the south), 1 its far end.
		for end in [0, 1]:
			var east: bool = (end == 0) == (w.side == "north")
			if String(w.joined_e if east else w.joined_w) != "":
				continue
			var ex := float(w.x1) if east else float(w.x0)
			var sgn := sign_of(String(w.side))
			var g := maxf(ground(ex, sgn * front), ground(ex, sgn * (front - walk_depth)))
			ends.append(Vector2(end, clampf(g - float(w.y), 0.0, WALK_TOP - 0.1)))
		bw.end_steps = ends
		var at := Vector3(float(w.x1) if w.side == "north" else float(w.x0), float(w.y), sign_of(String(w.side)) * front)
		bw.transform = Transform3D(Basis(Vector3.UP, PI) if w.side == "north" else Basis.IDENTITY, at)
		add_child(bw)
		w.node = bw


## The walk under a map point, or {}.
func walk_at(x: float, z: float) -> Dictionary:
	for w: Dictionary in walks:
		var sgn := sign_of(String(w.side))
		var a := absf(z)
		if signf(z) == sgn and a <= front and a >= front - walk_depth and x >= float(w.x0) and x <= float(w.x1):
			return w
	return {}


## What a man stands on at a map point: a walk's planks, else the ground.
func surface(x: float, z: float) -> float:
	var w := walk_at(x, z)
	return float(w.top) if not w.is_empty() else ground(x, z)


## Where a man stands at the foot of a walk's door flight (world).
func steps_foot(w: Dictionary) -> Vector3:
	var bw := w.node as Boardwalk
	var local := bw.step_foot(0)
	var p := bw.transform * local
	return Vector3(p.x, ground(p.x, p.z) + 0.05, p.z)


# --- The passages ------------------------------------------------------------------------------

## Every gap between the blocks from Main Street to the back: the lots that aren't buildings (but
## the tight ones), and any gap between two buildings no lot names, wider than TIGHT (not the
## North-South Street).
func _find_passages() -> void:
	passages.clear()
	var ns: Dictionary = layout.town().get("ns_street", {})
	var ns_half := float(ns.get("width", 15.2)) * 0.5
	var ns_x := float(ns.get("x", 0.0))
	for side in ["north", "south"]:
		var named := []
		for l: Dictionary in layout.lots(side):
			var kind := String(l.get("kind", ""))
			if kind == "building" or kind == "tight":
				continue
			named.append({"id": String(l.id), "side": side, "x0": float(l.x0), "x1": float(l.x1), "kind": kind,
				"junk": l.has("junk")})
		var bs := _buildings(side)
		for i in range(bs.size() - 1):
			var g0 := float(bs[i].x1)
			var g1 := float(bs[i + 1].x0)
			if g1 - g0 < TIGHT or (g0 <= ns_x + ns_half and g1 >= ns_x - ns_half):
				continue
			var covered := false
			for n: Dictionary in named:
				covered = covered or (float(n.x0) < g1 and float(n.x1) > g0)
			if not covered:
				named.append({"id": "gap_%s@%d" % [side, roundi((g0 + g1) * 0.5)], "side": side, "x0": g0, "x1": g1, "kind": "gap", "junk": false})
		named.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.x0 < b.x0)
		for n: Dictionary in named:
			n["x"] = (float(n.x0) + float(n.x1)) * 0.5
			passages.append(n)


func passage(id: String) -> Dictionary:
	for p: Dictionary in passages:
		if p.id == id:
			return p
	return {}


## A passage's mouth on Main Street (on its lots' front line) and its end on Back Street or the
## rear lane (map points).
func mouth_of(p: Dictionary) -> Vector2:
	return Vector2(float(p.x), sign_of(String(p.side)) * front)


func back_of(p: Dictionary) -> Vector2:
	return Vector2(float(p.x), BACK_Z if p.side == "north" else REAR_Z)


# --- The junk ----------------------------------------------------------------------------------

## A lot's `junk` ({from, to}: metres back from the front) across its whole width: a tier
## JUNK_TIER high a tread deep at each side, the rest twice that, so it's two jumps up and down.
func _find_junk() -> void:
	junk.clear()
	for side in ["north", "south"]:
		var sgn := sign_of(side)
		for l: Dictionary in layout.lots(side):
			if not l.has("junk"):
				continue
			var j: Dictionary = l.junk
			var x0 := float(l.x0)
			var x1 := float(l.x1)
			var a := front + float(j.get("from", 6.0))
			var b := front + float(j.get("to", 9.0))
			var boxes := []
			for tier: Array in [[a, a + JUNK_TREAD, JUNK_TIER], [a + JUNK_TREAD, b - JUNK_TREAD, JUNK_TIER * 2.0], [b - JUNK_TREAD, b, JUNK_TIER]]:
				var d0: float = tier[0]
				var d1: float = tier[1]
				var lo := INF
				var hi := -INF
				for x in [x0, x1]:
					for d in [d0, d1]:
						var g := ground(x, sgn * d)
						lo = minf(lo, g)
						hi = maxf(hi, g)
				var bottom := lo - 0.2
				var top := hi + float(tier[2])
				boxes.append({"centre": Vector3((x0 + x1) * 0.5, (bottom + top) * 0.5, sgn * (d0 + d1) * 0.5),
					"size": Vector3(x1 - x0, top - bottom, d1 - d0)})
			junk.append({"id": String(l.id), "boxes": boxes})


func _build_junk() -> void:
	if junk.is_empty():
		return
	junk_body = StaticBody3D.new()
	junk_body.name = "Junk"
	junk_body.collision_layer = Layers.WORLD
	junk_body.collision_mask = 0
	add_child(junk_body)
	var st := SurfaceTool.new()
	for j: Dictionary in junk:
		for b: Dictionary in j.boxes:
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = b.size
			shape.shape = box
			shape.position = b.centre
			shape.name = "J_%s_%d" % [j.id, (j.boxes as Array).find(b)]
			junk_body.add_child(shape)
			var bm := BoxMesh.new()
			bm.size = b.size
			st.append_from(bm, 0, Transform3D(Basis.IDENTITY, b.centre))
	var mi := MeshInstance3D.new()
	mi.name = "JunkMesh"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = JUNK_COLOUR
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)


# --- The town's ways ---------------------------------------------------------------------------

## The town's places and their links into `places` (see the top). A lot's own id is its door (a
## building's) or its mouth (a passage's).
func add_ways(places: Waypoints) -> void:
	var t := layout.town()
	var mx := layout.main_street_x()
	var on := func(c: Vector2) -> Vector3: return Vector3(c.x, surface(c.x, c.y) + 0.05, c.y)
	# Main Street's middle at every door and passage, the crossroads and its ends.
	var main_x := {0.0: true, mx.x: true, mx.y: true}
	for w: Dictionary in walks:
		main_x[snappedf(float(w.door), 0.1)] = true
	for p: Dictionary in passages:
		main_x[snappedf(float(p.x), 0.1)] = true
	var main_names := _chain(places, "main", main_x.keys(), func(x: float) -> Vector2: return Vector2(x, 0.0), on)
	if places.has(&"town"):
		places.link(&"town", main_names[0.0])
	# Each building's door on its walk, the foot of its steps, Main Street before them.
	for w: Dictionary in walks:
		var id := StringName(String(w.id))
		var sgn := sign_of(String(w.side))
		places.add(id, Vector3(float(w.door), float(w.top) + 0.05, sgn * (front - DOOR_OUT)))
		var foot := StringName("%s_steps" % w.id)
		places.add(foot, steps_foot(w), [id])
		places.link(foot, main_names[snappedf(float(w.door), 0.1)])
	# Along a run of walks joined over tight gaps, door to door.
	for w: Dictionary in walks:
		if String(w.joined_e) != "":
			places.link(StringName(String(w.id)), StringName(String(w.joined_e)))
	# Back Street and the rear lane: a place at every passage's end, the North-South Street's, the ends.
	var back_x := {0.0: true, float((t.get("back_street", {}) as Dictionary).get("x", [mx.x])[0]): true,
		float((t.get("back_street", {}) as Dictionary).get("x", [0, mx.y])[1]): true}
	var rear_x := {0.0: true, float((t.get("rear_lane", {}) as Dictionary).get("x", [mx.x])[0]): true,
		float((t.get("rear_lane", {}) as Dictionary).get("x", [0, mx.y])[1]): true}
	for p: Dictionary in passages:
		(back_x if p.side == "north" else rear_x)[snappedf(float(p.x), 0.1)] = true
	var back_names := _chain(places, "back", back_x.keys(), func(x: float) -> Vector2: return Vector2(x, BACK_Z), on)
	var rear_names := _chain(places, "rear", rear_x.keys(), func(x: float) -> Vector2: return Vector2(x, REAR_Z), on)
	# Each passage: its mouth on Main Street, its end at the back (named for it), the two linked
	# unless junk fills it.
	for p: Dictionary in passages:
		var id := StringName(String(p.id))
		var names: Dictionary = back_names if p.side == "north" else rear_names
		var end: StringName = names[snappedf(float(p.x), 0.1)]
		places.add(id, on.call(mouth_of(p)), [main_names[snappedf(float(p.x), 0.1)]])
		var back := StringName("%s_back" % p.id)
		places.add(back, places.at(end), [end])
		places.link(back, end)
		if not p.junk:
			_line(places, id, back, on)
	# The North-South Street from the rail's side to the creek's, through every street it crosses;
	# Creek Street.
	var ns: Dictionary = t.get("ns_street", {})
	var creek_z := NAN
	for ex: Dictionary in t.get("extras", []):
		for row: Dictionary in ex.get("rows", []):
			if row.get("street", false):
				creek_z = (float(row.z[0]) + float(row.z[1])) * 0.5
	var ns_chain: Array[StringName] = []
	var top := StringName("ns@%d" % roundi(float(ns.z[0]) + 14.0))
	places.add(top, on.call(Vector2(0.0, float(ns.z[0]) + 14.0)))
	ns_chain.append(top)
	ns_chain.append(back_names[0.0])
	ns_chain.append(main_names[0.0])
	ns_chain.append(rear_names[0.0])
	if not is_nan(creek_z):
		var cx := {}
		var x := mx.x
		while x < mx.y:
			cx[snappedf(x, 0.1)] = true
			x += 25.0
		cx[0.0] = true
		cx[mx.y] = true
		var creek_names := _chain(places, "creek", cx.keys(), func(x2: float) -> Vector2: return Vector2(x2, creek_z), on)
		ns_chain.append(creek_names[0.0])
	var south := StringName("ns@%d" % roundi(float(ns.z[1]) - 20.0))
	places.add(south, on.call(Vector2(0.0, float(ns.z[1]) - 20.0)))
	ns_chain.append(south)
	for i in range(1, ns_chain.size()):
		_line(places, ns_chain[i - 1], ns_chain[i], on)


## The longest link (m), and the most the ground may rise along one above its lower end (m): a
## straight way is swept a man's height over its lower end (Waypoints._walkable), so where the
## ground climbs (3 % across the town, steeper toward the rail's bench) it's split.
const LINK_MAX := 12.0
const LINK_RISE := 0.3


## `a` linked to `b` through places between (`a>b~1`, `a>b~2`...) on what's there, as few as keep
## each piece under LINK_MAX and LINK_RISE.
func _line(places: Waypoints, a: StringName, b: StringName, on: Callable) -> void:
	var pa := places.at(a)
	var pb := places.at(b)
	var flat := Vector2(pb.x - pa.x, pb.z - pa.z).length()
	var n := maxi(1, ceili(flat / LINK_MAX))
	while n < 64 and _rises(pa, pb, n, on) > LINK_RISE:
		n += 1
	var prev := a
	for k in range(1, n):
		var q := pa.lerp(pb, float(k) / n)
		var name_k := StringName("%s>%s~%d" % [a, b, k])
		places.add(name_k, on.call(Vector2(q.x, q.z)), [prev])
		prev = name_k
	places.link(prev, b)


## The most the ground rises over the lower end of any of the n pieces from pa to pb.
func _rises(pa: Vector3, pb: Vector3, n: int, on: Callable) -> float:
	var worst := 0.0
	var ends: Array[float] = []
	for k in n + 1:
		var q := pa.lerp(pb, float(k) / n)
		ends.append((on.call(Vector2(q.x, q.z)) as Vector3).y)
	for k in n:
		var low := minf(ends[k], ends[k + 1])
		for i in 9:
			var q := pa.lerp(pb, (k + i / 8.0) / n)
			worst = maxf(worst, (on.call(Vector2(q.x, q.z)) as Vector3).y - low)
	return worst


## Places along a street, one at each x (sorted, `point` the map point of an x), linked in turn:
## {x: name}.
func _chain(places: Waypoints, prefix: String, xs: Array, point: Callable, on: Callable) -> Dictionary:
	xs.sort()
	var out := {}
	var prev := &""
	for x: float in xs:
		var n := StringName("%s@%s" % [prefix, _fmt(x)])
		places.add(n, on.call(point.call(x)))
		if prev != &"":
			_line(places, prev, n, on)
		prev = n
		out[x] = n
	return out


static func _fmt(x: float) -> String:
	return str(roundi(x)) if absf(x - roundf(x)) < 0.05 else "%.1f" % x


func report() -> Dictionary:
	var members := 0
	for w: Dictionary in walks:
		members += (w.node as Boardwalk).get_members().size() if w.node else 0
	return {"walks": walks.size(), "walk_members": members, "passages": passages.size(), "junk": junk.size(), "build_ms": build_ms}
