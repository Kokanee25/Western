class_name Boardwalk
extends Structure
## A raised plank boardwalk along the street front: sleepers on the ground, planks across them,
## a fascia board along the edge. Runs along +X from the origin; the street side is -Z.

@export var length := 14.5
@export var walk_depth := 2.4
@export var top := 0.38
## Flights of steps down to the street (DESIGN: up on steps, as the street picture has them): each
## a Vector2(centre along the walk, width). None: the old way, the whole street edge and both ends
## an invisible ramp.
@export var steps: Array = []
## The steps' rise and tread.
@export var riser := 0.2
const TREAD := 0.3

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
	if steps.is_empty():
		_add_step_ramps()
	else:
		_add_steps()


## Invisible ramps so the player walks up onto the boardwalk instead of jumping, along the whole
## street edge and both ends (a boardwalk with no steps).
func _add_step_ramps() -> void:
	_ramp(Vector3(length * 0.5, top, -walk_depth), Vector3.BACK, length, 0.8)
	_ramp(Vector3(0.0, top, -walk_depth * 0.5), Vector3.RIGHT, walk_depth, 0.8)
	_ramp(Vector3(length, top, -walk_depth * 0.5), Vector3.LEFT, walk_depth, 0.8)


## Each flight: blocks stepping down from the walk's edge into the street (a rise of `riser` or a
## little less each, `TREAD` deep), members like the rest (they're shot and burn), and an invisible
## ramp over their noses so the player walks up them; elsewhere the edge is a step too high to walk
## up, so people come and go by the steps.
func _add_steps() -> void:
	var n := maxi(1, roundi(top / riser))
	var rise := top / n
	var edge_z := -walk_depth
	for f in steps.size():
		var flight: Vector2 = steps[f]
		for k in range(1, n):
			# Step k (from the bottom: 1 is the lowest, furthest out) stands k rises high.
			var out_far := (n - k) * TREAD
			var out_near := (n - k - 1) * TREAD
			add_member("step/%d_%d" % [f, k], &"joist", &"framing", Vector3(flight.y, k * rise, out_far - out_near),
					Vector3(flight.x, k * rise * 0.5, edge_z - (out_far + out_near) * 0.5))
		_ramp(Vector3(flight.x, top, edge_z), Vector3.BACK, flight.y, n * TREAD, 0.02)


## Where a man stands at the foot of a flight, in the walk's own space (the waypoints use it).
func step_foot(flight: int) -> Vector3:
	var n := maxi(1, roundi(top / riser))
	var f: Vector2 = steps[flight]
	return Vector3(f.x, 0.0, -walk_depth - n * TREAD - 0.4)


## An invisible slope rising toward `rise` to the edge at `edge` (its top middle), `width` across,
## `run` long; `lift` raises it clear of the step noses under it.
func _ramp(edge: Vector3, rise: Vector3, width: float, run: float, lift := 0.0) -> void:
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
	box.size = Vector3(width, 0.1, sqrt(top * top + run * run))
	shape.shape = box
	body.add_child(shape)
	var mid := edge - rise * (run * 0.5) - Vector3.UP * (top * 0.5 - lift)
	body.transform = Transform3D(basis, mid - normal * 0.05)
	add_child(body)
