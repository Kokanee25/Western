class_name WaterTrough
extends Structure
## A plank water trough on two skids, full of water. Runs along +X from the origin.

@export var length := 2.0
@export var trough_width := 0.65
@export var height := 0.6

const T := 0.04


func build() -> void:
	add_to_group(&"water_source")  # a bucket can be filled here (BucketViewmodel)
	var skid_h := 0.1
	for i in 2:
		var x := 0.2 if i == 0 else length - 0.2
		add_member("skid%d" % i, &"sill", &"framing", Vector3(0.1, skid_h, trough_width + 0.1), Vector3(x, skid_h * 0.5, 0.0))
	add_member("bottom", &"floor_board", &"floor", Vector3(length, T, trough_width), Vector3(length * 0.5, skid_h + T * 0.5, 0.0))
	var y0 := skid_h + T
	var wall_h := height - y0
	# Corner cleats inside the trough hold the side and end boards together.
	for i in 4:
		var cx := T * 1.5 if i % 2 == 0 else length - T * 1.5
		var cz := (trough_width * 0.5 - T * 1.5) * (1.0 if i < 2 else -1.0)
		add_member("cleat%d" % i, &"furniture_frame", &"framing", Vector3(T, wall_h, T), Vector3(cx, y0 + wall_h * 0.5, cz))
	for side in 2:
		var z := (trough_width - T) * 0.5 * (1.0 if side == 0 else -1.0)
		for row in 2:
			add_member("side%d/%d" % [side, row], &"board", &"weathered_pine", Vector3(length, wall_h * 0.5 - 0.004, T),
					Vector3(length * 0.5, y0 + wall_h * (0.25 + 0.5 * row), z))
	for side in 2:
		var x := T * 0.5 if side == 0 else length - T * 0.5
		add_member("end%d" % side, &"board", &"weathered_pine", Vector3(T, wall_h, trough_width - T * 2.0),
				Vector3(x, y0 + wall_h * 0.5, 0.0))
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(length - T * 2.0, trough_width - T * 2.0)
	water.mesh = plane
	water.material_override = WoodMaterials.water()
	water.position = Vector3(length * 0.5, height - 0.08, 0.0)
	add_child(water)
