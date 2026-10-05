class_name TownLayout
extends Node
## Where the town stands, from `config/town.json` (docs/briefs/main-street.md): the street's
## buildings, boardwalks and markers by node path, each at a position and a facing, or in a
## building's own space so it moves with it. The first child of the street, so its `_ready` places
## the others before any of them builds. `transform_of()` and `point()` give the same places to
## code that has no scene (the waypoints, tests).

const PATH := "res://config/town.json"

static var _data: Dictionary = {}


func _ready() -> void:
	var street := get_parent()
	for path: String in nodes():
		var node := street.get_node_or_null(NodePath(path)) as Node3D
		if node:
			node.transform = transform_of(StringName(path))
		else:
			push_warning("TownLayout: no %s in the street" % path)


static func data() -> Dictionary:
	if _data.is_empty():
		var text := FileAccess.get_file_as_string(PATH)
		var parsed: Variant = JSON.parse_string(text)
		_data = parsed if parsed is Dictionary else {"nodes": {}}
	return _data


static func nodes() -> Dictionary:
	return data().get("nodes", {})


## Where a node stands in the street (identity if the layout doesn't have it).
static func transform_of(path: StringName) -> Transform3D:
	var e: Dictionary = nodes().get(String(path), {})
	if e.is_empty():
		return Transform3D()
	var at: Array = e.get("at", [0, 0, 0])
	var t := Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.get("facing", 0.0)))), Vector3(at[0], at[1], at[2]))
	if e.has("in"):
		t = transform_of(StringName(e["in"])) * t
	return t


## A point given in a building's own space, in the street's.
static func point(building: StringName, local: Vector3) -> Vector3:
	return transform_of(building) * local
