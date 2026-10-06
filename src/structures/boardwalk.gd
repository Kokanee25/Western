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
## Flights at the walk's ends down to a lower walk beside it (the saloon's raised walk down to the
## store's): each a Vector2(end, top of the walk below), end 0 the walk's start (x 0, stepping down
## toward -X) or 1 its far end (x length, toward +X). The flight takes the end's first metre or so
## of the walk: blocks from the ground, an invisible ramp over them, the planks start past them.
@export var end_steps: Array = []
const TREAD := 0.3

const PLANK_T := 0.03
const SLEEPER_W := 0.1
const SEGMENT := 4.9


func build() -> void:
	var sleeper_top := top - PLANK_T
	# The run along X the planks cover: the end flights take theirs.
	var start := _end_run(0)
	var finish := length - _end_run(1)
	var i := 0
	for z in [-walk_depth + 0.08, -walk_depth * 0.5, -0.1]:
		var x := start
		var seg := 0
		while x < finish - 0.01:
			var x1 := minf(x + SEGMENT, finish)
			add_member("sleeper/%d_%d" % [i, seg], &"joist", &"framing", Vector3(x1 - x - 0.01, sleeper_top, SLEEPER_W),
					Vector3((x + x1) * 0.5, sleeper_top * 0.5, z))
			x = x1
			seg += 1
		i += 1
	var n := 0
	var px := start
	while px < finish - 0.05:
		var pw := minf(0.18 + rand_range(-0.015, 0.02), finish - px)
		var h := PLANK_T + rand_range(-0.004, 0.0)
		add_member("plank/%03d" % n, &"floor_board", &"floor", Vector3(pw, h, walk_depth - 0.04),
				Vector3(px + pw * 0.5, sleeper_top + h * 0.5, -walk_depth * 0.5 - 0.01))
		px += pw + 0.018
		n += 1
	add_member("fascia", &"board", &"weathered_pine", Vector3(finish - start, sleeper_top - 0.05, 0.025),
			Vector3((start + finish) * 0.5, 0.05 + (sleeper_top - 0.05) * 0.5, -walk_depth - 0.0125))
	if steps.is_empty():
		_add_step_ramps()
	else:
		_add_steps()
	_add_end_steps()


## Invisible ramps so the player walks up onto the boardwalk instead of jumping, along the whole
## street edge and both ends (a boardwalk with no steps).
func _add_step_ramps() -> void:
	_ramp(Vector3(length * 0.5, top, -walk_depth), Vector3.BACK, length, 0.8)
	# Not at an end that has its own flight down to the walk beside it.
	if _end_run(0) == 0.0:
		_ramp(Vector3(0.0, top, -walk_depth * 0.5), Vector3.RIGHT, walk_depth, 0.8)
	if _end_run(1) == 0.0:
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


## How much of the walk's length a flight at that end takes (0 with none there).
func _end_run(end: int) -> float:
	for e in end_steps:
		var flight: Vector2 = e
		if int(flight.x) == end:
			return _end_rises(flight.y) * TREAD
	return 0.0


func _end_rises(below: float) -> int:
	return maxi(1, roundi((top - below) / riser))


## Each end flight: blocks across the walk's whole depth, standing on the ground, stepping up from
## the walk below (its first tread level with it, carrying it on to the step) to this one's top,
## and a ramp over their noses for the player.
func _add_end_steps() -> void:
	for f in end_steps.size():
		var flight: Vector2 = end_steps[f]
		var end := int(flight.x)
		var below := flight.y
		var n := _end_rises(below)
		var rise := (top - below) / n
		var edge_x := n * TREAD if end == 0 else length - n * TREAD
		var out := -1.0 if end == 0 else 1.0
		for k in range(0, n):
			# Tread k (0 level with the walk below, at the very end) stands k rises above it.
			var far := (n - k) * TREAD
			var near := (n - k - 1) * TREAD
			var mid_x := edge_x + out * (far + near) * 0.5
			add_member("end_step/%d_%d" % [f, k], &"joist", &"framing", Vector3(far - near, below + k * rise, walk_depth),
					Vector3(mid_x, (below + k * rise) * 0.5, -walk_depth * 0.5))
		_ramp(Vector3(edge_x, top, -walk_depth * 0.5), Vector3.RIGHT * -out, walk_depth, n * TREAD, 0.02, below)
		# A board closing the walk's end under its planks, above the top tread (nothing walks in
		# under the planks there).
		var sleeper_top := top - PLANK_T
		add_member("end_board/%d" % f, &"board", &"weathered_pine", Vector3(0.025, sleeper_top, walk_depth),
				Vector3(edge_x - out * 0.0125, sleeper_top * 0.5, -walk_depth * 0.5))


## Where a man stands at the foot of a flight, in the walk's own space (the waypoints use it).
func step_foot(flight: int) -> Vector3:
	var n := maxi(1, roundi(top / riser))
	var f: Vector2 = steps[flight]
	return Vector3(f.x, 0.0, -walk_depth - n * TREAD - 0.4)


## An invisible slope rising toward `rise` to the edge at `edge` (its top middle), `width` across,
## `run` long; `lift` raises it clear of the step noses under it.
func _ramp(edge: Vector3, rise: Vector3, width: float, run: float, lift := 0.0, base := 0.0) -> void:
	# `base`: the height the slope starts from (the ground, or a lower walk beside this one).
	var h := top - base
	var across := Vector3.UP.cross(rise).normalized()
	var slope_dir := (rise * run + Vector3.UP * h).normalized()
	var normal := slope_dir.cross(across).normalized()
	if normal.y < 0.0:
		normal = -normal
		across = -across
	var basis := Basis(across, normal, slope_dir).orthonormalized()
	var body := StaticBody3D.new()
	body.name = "StepRamp"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.1, sqrt(h * h + run * run))
	shape.shape = box
	body.add_child(shape)
	var mid := edge - rise * (run * 0.5) - Vector3.UP * (h * 0.5 - lift)
	body.transform = Transform3D(basis, mid - normal * 0.05)
	add_child(body)
