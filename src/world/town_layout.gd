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


## The authored ground's height at (x, z): flat (0) through town; climbing westward out of it
## (ground.rise: from 0 at x `from` to `height` at x `to`, eased at both ends), the climb full north
## of z `full_north_of` and fading out by `none_south_of` (the flat by the creek).
static func ground_height(x: float, z: float) -> float:
	var r := rise()
	if r.is_empty():
		return 0.0
	return float(r.height) * rise_along(x) * rise_across(z)


## How far up the rise (0..1, eased) the ground is at `x`, and how much of it there is at `z`:
## ground_height is the rise's height times the two.
static func rise_along(x: float) -> float:
	var r := rise()
	if r.is_empty():
		return 0.0
	var t := clampf((float(r.from) - x) / (float(r.from) - float(r.to)), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func rise_across(z: float) -> float:
	var r := rise()
	if r.is_empty():
		return 0.0
	var s := clampf((float(r.none_south_of) - z) / (float(r.none_south_of) - float(r.full_north_of)), 0.0, 1.0)
	return s * s * (3.0 - 2.0 * s)


## The ground's rise (config/town.json ground.rise: from, to, height, full_north_of,
## none_south_of), or empty where the ground's flat everywhere.
static func rise() -> Dictionary:
	return (data().get("ground", {}) as Dictionary).get("rise", {})


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
