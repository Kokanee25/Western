class_name RoadPrints
extends Node3D
## The old prints in the main street's dirt (docs/briefs/road.md; Sean, 2026-10-15: "old prints"):
## horseshoes in front of the hitching rails and the trough, boot prints at the porch steps, half
## worn away, the town's past traffic. Each is a Decal pressing its picture and relief into the
## ground (assets/textures/street/print_<kind>.png and _normal.png, tools/textures/draw_street.py),
## placed where street_map.json lists them. Fresh prints from people walking are gameplay's
## (docs/BACKLOG.md): press(), the same decal anywhere.

const MAP := "res://assets/textures/street/street_map.json"
const PICTURE := "res://assets/textures/street/print_%s.png"
const NORMAL := "res://assets/textures/street/print_%s_normal.png"
## Each kind's picture's size on the ground, metres (the print fills the middle of it).
const SIZE := {&"hoof": 0.19, &"boot": 0.3}

var _textures := {}


func _ready() -> void:
	if not FileAccess.file_exists(MAP):
		return
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
	if not info is Dictionary:
		return
	for p: Dictionary in (info as Dictionary).get("prints", []):
		var x := float(p["x"])
		var z := float(p["z"])
		press(StringName(p["kind"]), Vector3(x, TownLayout.ground_height(x, z), z), float(p["turn"]), float(p["wear"]))


## A print of `kind` (hoof, boot) at `at` on the ground, turned `turn` radians about the vertical,
## `wear` of it worn away (0 fresh, 1 gone).
func press(kind: StringName, at: Vector3, turn: float, wear: float) -> Decal:
	if not _textures.has(kind):
		_textures[kind] = [load(PICTURE % kind), load(NORMAL % kind)]
	var d := Decal.new()
	var s: float = SIZE.get(kind, 0.25)
	d.size = Vector3(s, 0.2, s)
	d.texture_albedo = _textures[kind][0]
	d.texture_normal = _textures[kind][1]
	# Worn, but still read: at most half of it worn off (at a full share a print 13 cm across, worn
	# to a third and mixed in at 0.7, was gone at 2 m).
	d.modulate = Color(1, 1, 1, clampf(1.0 - 0.5 * wear, 0.0, 1.0))
	d.albedo_mix = 1.0
	d.normal_fade = 0.3
	d.cull_mask = 1  # the ground (and what lies on it), not people walking through
	add_child(d)
	d.global_position = at + Vector3.UP * 0.05
	d.rotation.y = turn
	return d
