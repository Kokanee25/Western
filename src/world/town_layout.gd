class_name TownLayout
extends Node
## Where the town stands, from `config/town.json` (docs/briefs/main-street.md): the street's
## buildings, boardwalks and markers by node path, each at a position and a facing, or in a
## building's own space so it moves with it, with properties set on it (`set`) before it builds.
## The first child of the street, so its `_ready` places the others before any of them builds;
## entries under `StreetDressing/` are the dressing's own buildings, which it places itself.
## `transform_of()` and `point()` give the same places to code that has no scene (the waypoints,
## tests). `carry()` moves a point laid out round where a building stood before the map (its
## `was`) to where it stands now: the dressing's old coordinates, till they're laid out again.
## The street isn't ruled straight: `street_z()` is its middle at an x (streets.main.line), and
## `ground_height()` the authored ground (flat in town, climbing west out of it: ground.rise).

const PATH := "res://config/town.json"
## How far round an old lot a point still counts as its: along the street past either end, and
## out into the street from the front.
const LOT_REACH := 1.5
const LOT_OUT := 5.0

## Where the old straight street's middle ran (z), before it had a line.
const OLD_MIDDLE := -8.4

static var _data: Dictionary = {}
static var _line := PackedVector2Array()


func _ready() -> void:
	var street := get_parent()
	for path: String in nodes():
		if path.begins_with("StreetDressing/"):
			continue
		var node := street.get_node_or_null(NodePath(path)) as Node3D
		if not node:
			push_warning("TownLayout: no %s in the street" % path)
			continue
		node.transform = transform_of(StringName(path))
		var sets: Dictionary = (nodes()[path] as Dictionary).get("set", {})
		for k: String in sets:
			node.set(k, value(k, sets[k]))


static func data() -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string(PATH)
		var parsed: Variant = JSON.parse_string(text)
		_data = parsed if parsed is Dictionary else {"nodes": {}}
		_line = PackedVector2Array()
		var main: Dictionary = (_data.get("streets", {}) as Dictionary).get("main", {})
		for p: Array in main.get("line", []):
			_line.append(Vector2(p[0], p[1]))
	return _data


static func nodes() -> Dictionary:
	return data().get("nodes", {})


static func entry(path: StringName) -> Dictionary:
	return nodes().get(String(path), {})


## A value from the file as the property wants it: `steps` a list of Vector2, `*_size` a Vector2.
static func value(key: String, v: Variant) -> Variant:
	if (key == "steps" or key == "end_steps") and v is Array:
		var out: Array = []
		for s: Array in v:
			out.append(Vector2(s[0], s[1]))
		return out
	if key.ends_with("_size") and v is Array and (v as Array).size() == 2:
		return Vector2(v[0], v[1])
	return v


## Where a node stands in the street (identity if the layout doesn't have it).
static func transform_of(path: StringName) -> Transform3D:
	var e := entry(path)
	if e.is_empty():
		return Transform3D()
	var t := _xform(e)
	if e.has("in"):
		t = transform_of(StringName(e["in"])) * t
	return t


static func _xform(e: Dictionary) -> Transform3D:
	var at: Array = e.get("at", [0, 0, 0])
	return Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.get("facing", 0.0)))), Vector3(at[0], at[1], at[2]))


## A point given in a building's own space, in the street's.
static func point(building: StringName, local: Vector3) -> Vector3:
	return transform_of(building) * local


## A direction given in a building's own space, in the street's (which way its bar runs).
static func facing_toward(building: StringName, local_dir: Vector3) -> Vector3:
	return transform_of(building).basis * local_dir


## Main Street's middle (z) at `x`: a smooth curve through streets.main.line's points (cubic
## Hermite in x, each point's slope from its neighbours'), straight on past its ends; the old
## straight line if the file has none. draw_street.py draws the street's ruts along the same curve.
static func street_z(x: float) -> float:
	data()
	var l := _line
	var n := l.size()
	if n < 2:
		return OLD_MIDDLE
	if x <= l[0].x:
		return l[0].y + (x - l[0].x) * (l[1].y - l[0].y) / (l[1].x - l[0].x)
	if x >= l[n - 1].x:
		return l[n - 1].y + (x - l[n - 1].x) * (l[n - 1].y - l[n - 2].y) / (l[n - 1].x - l[n - 2].x)
	var i := 0
	while i < n - 2 and x > l[i + 1].x:
		i += 1
	var h := l[i + 1].x - l[i].x
	var t := (x - l[i].x) / h
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * l[i].y + (t3 - 2.0 * t2 + t) * h * _slope(i) \
			+ (-2.0 * t3 + 3.0 * t2) * l[i + 1].y + (t3 - t2) * h * _slope(i + 1)


static func _slope(i: int) -> float:
	var a := _line[maxi(i - 1, 0)]
	var b := _line[mini(i + 1, _line.size() - 1)]
	return (b.y - a.y) / (b.x - a.x)


## A point on Main Street at `x`, `across` metres from its middle (+ toward the south side), on the
## ground.
static func street_point(x: float, across := 0.0) -> Vector3:
	var z := street_z(x) + across
	return Vector3(x, ground_height(x, z), z)


## The way the street runs at `x`, east (unit, flat).
static func street_dir(x: float) -> Vector3:
	return Vector3(1.0, 0.0, street_z(x + 0.5) - street_z(x - 0.5)).normalized()


## The authored ground's height at (x, z): the same at every z (config/town.json ground): flat
## from the east through the saloon and the store, falling toward them from Market Street ('fall',
## the town on a slope), level by the hotel and the bank, then climbing west out of town ('rise').
static func ground_height(x: float, z := 0.0) -> float:
	var g: Dictionary = data().get("ground", {})
	var h := 0.0
	for part: String in ["fall", "rise"]:
		var p: Dictionary = g.get(part, {})
		if not p.is_empty():
			var t := clampf((float(p.from) - x) / (float(p.from) - float(p.to)), 0.0, 1.0)
			h += float(p.height) * t * t * (3.0 - 2.0 * t)
	return h + hills_height(x, z)


## The hills out of town (config/town.json ground.hills.bumps; Sean: hilly outskirts, not flat):
## each bump `h` m high at `at` (x, z), falling smoothly to nothing at `r` (a smoothstep of the
## distance, flat on top and at its foot), the bumps summed. None reaches the town or the road, so
## everything in town keeps its height (and code that asks with x alone is right there).
static func hills_height(x: float, z: float) -> float:
	var h := 0.0
	for b: Vector4 in _hill_bumps():
		var d := Vector2(x - b.x, z - b.y).length()
		if d < b.z:
			var t := 1.0 - d / b.z
			h += b.w * t * t * (3.0 - 2.0 * t)
	return h


## The rectangle the hills reach over (x, z), or an empty Rect2 if there are none.
static func hills_area() -> Rect2:
	var bumps := _hill_bumps()
	if bumps.is_empty():
		return Rect2()
	var area := Rect2()
	for i in bumps.size():
		var b: Vector4 = bumps[i]
		var r := Rect2(b.x - b.z, b.y - b.z, b.z * 2.0, b.z * 2.0)
		area = r if i == 0 else area.merge(r)
	return area


static var _bumps: Array[Vector4] = []
static var _bumps_read := false


## The bumps as (x, z, r, h), read once.
static func _hill_bumps() -> Array[Vector4]:
	if not _bumps_read:
		_bumps_read = true
		var hills: Dictionary = (data().get("ground", {}) as Dictionary).get("hills", {})
		for b: Dictionary in hills.get("bumps", []):
			_bumps.append(Vector4(float(b.at[0]), float(b.at[1]), float(b.r), float(b.h)))
	return _bumps


## The x east of which the authored ground is flat (at 0); INF if it's flat everywhere.
static func ground_flat_east_of() -> float:
	var g: Dictionary = data().get("ground", {})
	var east := -INF
	for part: String in ["fall", "rise"]:
		var p: Dictionary = g.get(part, {})
		if not p.is_empty():
			east = maxf(east, float(p.from))
	return east if east > -INF else INF


## Where a building whose footprint (its front's width `w`, its depth `d`, and a boardwalk 2.4 m
## out in front) is turned and placed by `t` stands on the ground: the height under its lowest
## corner, so the uphill side is set into the slope, never the downhill side left in the air.
static func footing(t: Transform3D, w: float, d: float) -> float:
	var low := INF
	for c: Vector3 in [Vector3(0, 0, -2.4), Vector3(w, 0, -2.4), Vector3(0, 0, d), Vector3(w, 0, d)]:
		var p := t * c
		low = minf(low, ground_height(p.x, p.z))
	return low


## The move that takes what stood round an old lot to where its building stands now; a point no
## lot claims (out in the street, away from any front) goes with the street: across as far as its
## middle has moved from the old straight line, and onto the ground.
static func carry(old: Vector3) -> Transform3D:
	var best := INF
	var z := street_z(old.x) - OLD_MIDDLE
	var move := Transform3D(Basis(), Vector3(0.0, ground_height(old.x, old.z + z), z))
	for path: String in nodes():
		var e: Dictionary = nodes()[path]
		for was: Dictionary in e.get("was", []):
			var t := _xform(was)
			var local := t.affine_inverse() * old
			var w := float(was.get("width", 6.0))
			# In the lot's own space the street is -Z of its front (z 0) and it runs 0..w along X.
			if local.z < -LOT_OUT:
				continue
			var off := maxf(0.0, maxf(-local.x, local.x - w))
			if off > LOT_REACH or off >= best:
				continue
			best = off
			move = transform_of(StringName(path)) * t.affine_inverse()
	return move
