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

const PATH := "res://config/town.json"
## How far round an old lot a point still counts as its: along the street past either end, and
## out into the street from the front.
const LOT_REACH := 1.5
const LOT_OUT := 5.0

static var _data: Dictionary = {}


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


## The move that takes what stood round an old lot to where its building stands now (identity for
## a point no lot claims: out in the street, away from any front).
static func carry(old: Vector3) -> Transform3D:
	var best := INF
	var move := Transform3D()
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
