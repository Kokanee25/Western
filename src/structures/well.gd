class_name Well
extends Structure
## A dug well: a ring of laid stone round the shaft, a windlass on two posts with its roller and
## crank, and a little roof over it. A bucket can be filled here (group water_source, as a
## trough's: `length` and `trough_width` are the opening the water's reached through, `Water`
## is its surface). Centred on its origin.

@export var radius := 0.62
@export var ring_height := 0.75
## For the bucket and the bucket runners (BucketViewmodel, CivilianBrain): the opening's size.
@export var length := 0.9
@export var trough_width := 0.9

const STONES := 10
const STONE_T := 0.22


func build() -> void:
	add_to_group(&"water_source")
	for course in 3:
		var h := ring_height / 3.0
		for i in STONES:
			var a := TAU * (i + 0.5 * course) / STONES
			var chord := 2.0 * radius * sin(PI / STONES) + 0.04
			var at := Vector3(cos(a) * radius, h * (course + 0.5), sin(a) * radius)
			add_member("ring/%d_%d" % [course, i], &"sill" if course == 0 else &"plate", &"stone", Vector3(STONE_T, h - 0.004, chord), at, Basis(Vector3.UP, -a))
	# The windlass: posts either side, the roller across them, a crank, and a roof of two boards.
	var post_h := 1.9
	for side in 2:
		var x := (radius + 0.05) * (1.0 if side == 0 else -1.0)
		add_member("post%d" % side, &"post", &"framing", Vector3(0.1, post_h, 0.1), Vector3(x, post_h * 0.5, 0.0))
	add_member("roller", &"beam", &"weathered_pine", Vector3(radius * 2.0 + 0.6, 0.12, 0.12), Vector3(0.0, 1.15, 0.0))
	add_member("crank", &"trim", &"iron", Vector3(0.03, 0.3, 0.03), Vector3(radius + 0.22, 1.05, 0.0))
	add_member("ridge", &"beam", &"framing", Vector3(radius * 2.0 + 0.5, 0.08, 0.08), Vector3(0.0, post_h + 0.04, 0.0))
	for side in 2:
		var s := 1.0 if side == 0 else -1.0
		var tilt := Basis(Vector3.RIGHT, s * deg_to_rad(35.0))
		add_member("roof%d" % side, &"roof_board", &"weathered_pine", Vector3(radius * 2.0 + 0.6, 0.025, 0.6),
				Vector3(0.0, post_h + 0.02 - 0.17, s * 0.24), tilt)
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 1.6, radius * 1.6)
	water.mesh = plane
	water.material_override = WoodMaterials.water()
	water.position = Vector3(0.0, ring_height - 0.25, 0.0)
	add_child(water)
