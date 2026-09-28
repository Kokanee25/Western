class_name Boardwalk
extends Structure
## A raised plank boardwalk along the street front: sleepers on the ground, planks across them,
## a fascia board along the edge. Runs along +X from the origin; the street side is -Z.

@export var length := 14.5
@export var walk_depth := 2.4
@export var top := 0.38

const PLANK_T := 0.03
const SLEEPER_W := 0.1
const SEGMENT := 4.9


func build() -> void:
	var sleeper_top := top - PLANK_T
	var i := 0
	for z in [-walk_depth + 0.08, -walk_depth * 0.5, -0.1]:
		var x := 0.0
		var seg := 0
		while x < length - 0.01:
			var x1 := minf(x + SEGMENT, length)
			add_member("sleeper/%d_%d" % [i, seg], &"joist", &"framing", Vector3(x1 - x - 0.01, sleeper_top, SLEEPER_W),
					Vector3((x + x1) * 0.5, sleeper_top * 0.5, z))
			x = x1
			seg += 1
		i += 1
	var n := 0
	var px := 0.0
	while px < length - 0.05:
		var pw := minf(0.18 + rand_range(-0.015, 0.02), length - px)
		var h := PLANK_T + rand_range(-0.004, 0.0)
		add_member("plank/%03d" % n, &"floor_board", &"floor", Vector3(pw, h, walk_depth - 0.04),
				Vector3(px + pw * 0.5, sleeper_top + h * 0.5, -walk_depth * 0.5 - 0.01))
		px += pw + 0.018
		n += 1
	add_member("fascia", &"board", &"weathered_pine", Vector3(length, sleeper_top - 0.05, 0.025),
			Vector3(length * 0.5, 0.05 + (sleeper_top - 0.05) * 0.5, -walk_depth - 0.0125))
	_add_step_ramps()


## Invisible ramps so the player walks up onto the boardwalk instead of jumping. Placeholder
## until the player controller learns to climb steps.
func _add_step_ramps() -> void:
	var run := 0.8
	var a := atan2(top, run)
	var hyp := sqrt(top * top + run * run)
	var ramps := [
		# centre of the top edge, direction the ramp rises in, width across
		[Vector3(length * 0.5, top, -walk_depth), Vector3.BACK, length],
		[Vector3(0.0, top, -walk_depth * 0.5), Vector3.RIGHT, walk_depth],
		[Vector3(length, top, -walk_depth * 0.5), Vector3.LEFT, walk_depth],
	]
	for r in ramps:
		var edge: Vector3 = r[0]
		var rise: Vector3 = r[1]
		var across := Vector3.UP.cross(rise).normalized()
		var slope_dir := (rise * run + Vector3.UP * top).normalized()
		var normal := slope_dir.cross(across).normalized()
		if normal.y < 0.0:
			normal = -normal
			across = -across
		var basis := Basis(across, normal, slope_dir).orthonormalized()
		var body := StaticBody3D.new()
		body.name = "StepRamp"
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(r[2], 0.1, hyp)
		shape.shape = box
		body.add_child(shape)
		var mid := edge - rise * (run * 0.5) - Vector3.UP * (top * 0.5)
		body.transform = Transform3D(basis, mid - normal * 0.05)
		add_child(body)
