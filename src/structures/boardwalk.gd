class_name Boardwalk
extends Structure
## A raised plank boardwalk along the street front: sleepers on the ground, planks across them,
## a fascia board along the edge. Runs along +X from the origin; the street side is -Z.
##
## A high walk (the valley's, #737) can stand on posts (`on_posts`: joists under the planks, posts
## to the ground, open underneath to see, shoot or crawl under), with a rail along its street edge
## (`rail`), a porch roof over it (`awning`, a PorchRoof), ramps in place of flights (`ramps`,
## `end_ramps`) and flights counted so no riser is over `riser` (`max_riser`).

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
## Ramps down to the street in place of a flight (a wagon shop's doors): each a Vector2(centre,
## width), 1 in `ramp_slope`.
@export var ramps: Array = []
## Ramps at the ends down to a lower walk or the ground (a barrow ramp): Vector2(end, below) each,
## as end_steps.
@export var end_ramps: Array = []
@export var ramp_slope := 8.0
## How far the street at the flights' feet is under the walk's origin (m): the flights and ramps to
## the street start from there.
@export var street_below := 0.0
## Count every flight's rises so none is over `riser` (else the nearest whole number, the old town's).
@export var max_riser := false
## On posts, open underneath (else sleepers on the ground and a fascia to it).
@export var on_posts := false
## The ground under the walk in its own space (a Callable(x, z) -> y), for the posts' feet; none:
## level with the origin.
var ground_at: Callable
## A rail along the street edge (not at its flights or ramps); a list of Vector2(from, to) along
## the walk to leave open as well (a drop at an end).
@export var rail := false
## A porch roof over the walk: its beam's underside this far over the planks (0: none).
@export var awning := 0.0
@export var awning_depth := 2.2
@export var awning_post_every := 3.0
const TREAD := 0.3
## The joists under a walk on posts (m deep), its posts (square) and how far apart along it.
const JOIST_D := 0.15
const POST_W := 0.12
const POST_EVERY := 2.4

const PLANK_T := 0.03
const SLEEPER_W := 0.1
const SEGMENT := 4.9


func build() -> void:
	var sleeper_top := top - PLANK_T
	# The run along X the planks cover: the end flights take theirs.
	var start := _end_run(0)
	var finish := length - _end_run(1)
	if on_posts:
		_build_on_posts(start, finish, sleeper_top)
	else:
		_build_sleepers(start, finish, sleeper_top)
	_add_planks(start, finish, sleeper_top)
	if not on_posts:
		add_member("fascia", &"board", &"weathered_pine", Vector3(finish - start, sleeper_top - 0.05, 0.025),
				Vector3((start + finish) * 0.5, 0.05 + (sleeper_top - 0.05) * 0.5, -walk_depth - 0.0125))
	if steps.is_empty() and ramps.is_empty():
		_add_step_ramps()
	else:
		_add_steps()
		_add_ramps()
	_add_end_steps()
	_add_end_ramps()
	if rail:
		_add_rail(start, finish)
	if awning > 0.0:
		var clear := []
		for f: Vector2 in steps + ramps:
			clear.append(Vector2(f.x - f.y * 0.5, f.x + f.y * 0.5))
		PorchRoof.build(self, "awning", length, awning_depth, awning, {"base": top, "post_every": awning_post_every, "clear": clear})


func _under_y(x: float, z: float) -> float:
	return ground_at.call(x, z) if ground_at.is_valid() else 0.0


func _build_sleepers(start: float, finish: float, sleeper_top: float) -> void:
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


## Joists along the walk under its planks, each line on posts to the ground every POST_EVERY.
func _build_on_posts(start: float, finish: float, sleeper_top: float) -> void:
	var i := 0
	for z in [-walk_depth + 0.08, -walk_depth * 0.5, -0.1]:
		var x := start
		var seg := 0
		while x < finish - 0.01:
			var x1 := minf(x + SEGMENT, finish)
			add_member("joist/%d_%d" % [i, seg], &"joist", &"framing", Vector3(x1 - x - 0.01, JOIST_D, SLEEPER_W),
					Vector3((x + x1) * 0.5, sleeper_top - JOIST_D * 0.5, z))
			x = x1
			seg += 1
		var n := maxi(1, ceili((finish - start - POST_W) / POST_EVERY))
		for k in n + 1:
			var px := lerpf(start + POST_W * 0.5, finish - POST_W * 0.5, float(k) / n)
			var foot := _under_y(px, z) - 0.1
			var head := sleeper_top - JOIST_D
			if head - foot < 0.05:
				continue
			add_member("post/%d_%d" % [i, k], &"post", &"framing", Vector3(POST_W, head - foot, POST_W),
					Vector3(px, (head + foot) * 0.5, z))
		i += 1
	# A fascia board along the street edge at the planks only: open below.
	add_member("fascia", &"board", &"weathered_pine", Vector3(finish - start, JOIST_D + 0.03, 0.025),
			Vector3((start + finish) * 0.5, sleeper_top - JOIST_D * 0.5, -walk_depth - 0.0125))


func _add_planks(start: float, finish: float, sleeper_top: float) -> void:
	var n := 0
	var px := start
	while px < finish - 0.05:
		var pw := minf(0.18 + rand_range(-0.015, 0.02), finish - px)
		var h := PLANK_T + rand_range(-0.004, 0.0)
		add_member("plank/%03d" % n, &"floor_board", &"floor", Vector3(pw, h, walk_depth - 0.04),
				Vector3(px + pw * 0.5, sleeper_top + h * 0.5, -walk_depth * 0.5 - 0.01))
		px += pw + 0.018
		n += 1


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
	var h := top + street_below
	var n := _rises(h)
	var rise := h / n
	var edge_z := -walk_depth
	var base := -street_below
	for f in steps.size():
		var flight: Vector2 = steps[f]
		for k in range(1, n):
			# Step k (from the bottom: 1 is the lowest, furthest out) stands k rises high, on blocks
			# from a little under the street.
			var out_far := (n - k) * TREAD
			var out_near := (n - k - 1) * TREAD
			var foot := base - (0.1 if max_riser else 0.0)
			var y1 := base + k * rise
			add_member("step/%d_%d" % [f, k], &"joist", &"framing", Vector3(flight.y, y1 - foot, out_far - out_near),
					Vector3(flight.x, (y1 + foot) * 0.5, edge_z - (out_far + out_near) * 0.5))
		_ramp(Vector3(flight.x, top, edge_z), Vector3.BACK, flight.y, n * TREAD, 0.02, base)


## How many rises take a height: none over `riser` (max_riser), or the nearest whole number.
func _rises(h: float) -> int:
	return maxi(1, ceili(h / riser - 0.001) if max_riser else roundi(h / riser))


## Each door ramp: a plank slope from the street up to the walk's edge, 1 in ramp_slope, and a
## block under its high end.
func _add_ramps() -> void:
	var h := top + street_below
	var run := h * ramp_slope
	for f in ramps.size():
		var r: Vector2 = ramps[f]
		var a := Vector3(r.x, -street_below, -walk_depth - run)
		var b := Vector3(r.x, top, -walk_depth)
		_slope_member("ramp/%d" % f, a, b, r.y)


## Each end ramp: across the walk's whole depth, from the walk below (or the ground) at the end up
## to this one's top, ramp_slope long a metre of rise; the planks start past it.
func _add_end_ramps() -> void:
	for f in end_ramps.size():
		var e: Vector2 = end_ramps[f]
		var end := int(e.x)
		var run := (top - e.y) * ramp_slope
		var x_end := 0.0 if end == 0 else length
		var x_top := run if end == 0 else length - run
		_slope_member("end_ramp/%d" % f, Vector3(x_end, e.y, -walk_depth * 0.5), Vector3(x_top, top, -walk_depth * 0.5), walk_depth)


## A sloped plank surface from `a` (low) to `b` (high), `width` across, its top on the line; a
## member, so it's walked on, shot and burned as the rest.
func _slope_member(id: String, a: Vector3, b: Vector3, width: float) -> void:
	var along := b - a
	var dir := along.normalized()
	var across := Vector3.UP.cross(Vector3(along.x, 0.0, along.z)).normalized()
	var up := dir.cross(across).normalized()
	if up.y < 0.0:
		up = -up
		across = -across
	var t := 0.08
	var basis := Basis(across, up, dir).orthonormalized()
	add_member(id, &"floor_board", &"floor", Vector3(width, t, along.length()), (a + b) * 0.5 - up * t * 0.5, basis)


## The rail along the street edge, on the planks, in pieces round the flights and ramps.
func _add_rail(start: float, finish: float) -> void:
	var gaps: Array[Vector2] = []
	for f: Vector2 in steps:
		gaps.append(Vector2(f.x - f.y * 0.5 - 0.05, f.x + f.y * 0.5 + 0.05))
	for f: Vector2 in ramps:
		gaps.append(Vector2(f.x - f.y * 0.5 - 0.05, f.x + f.y * 0.5 + 0.05))
	gaps.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var z := -walk_depth + 0.04
	var x := start + 0.05
	var k := 0
	for g: Vector2 in gaps + [Vector2(finish - 0.05, INF)]:
		if g.x - x > 0.3:
			Railing.build(self, "rail/%d" % k, Vector3(x, top, z), Vector3(g.x, top, z))
			k += 1
		x = maxf(x, g.y)


## How much of the walk's length a flight at that end takes (0 with none there).
func _end_run(end: int) -> float:
	for e in end_steps:
		var flight: Vector2 = e
		if int(flight.x) == end:
			return _end_rises(flight.y) * TREAD
	for e in end_ramps:
		var r: Vector2 = e
		if int(r.x) == end:
			return (top - r.y) * ramp_slope
	return 0.0


func _end_rises(below: float) -> int:
	return _rises(top - below)


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
			# On blocks from the ground (the origin's level; a little under what's below with max_riser).
			var foot := minf(0.0, below) - 0.1 if max_riser else 0.0
			var y1 := below + k * rise
			add_member("end_step/%d_%d" % [f, k], &"joist", &"framing", Vector3(far - near, y1 - foot, walk_depth),
					Vector3(mid_x, (y1 + foot) * 0.5, -walk_depth * 0.5))
		_ramp(Vector3(edge_x, top, -walk_depth * 0.5), Vector3.RIGHT * -out, walk_depth, n * TREAD, 0.02, below)
		# A board closing the walk's end under its planks, above the top tread (nothing walks in
		# under the planks there).
		var sleeper_top := top - PLANK_T
		if not on_posts:
			add_member("end_board/%d" % f, &"board", &"weathered_pine", Vector3(0.025, sleeper_top, walk_depth),
					Vector3(edge_x - out * 0.0125, sleeper_top * 0.5, -walk_depth * 0.5))


## Where a man stands at the foot of a flight, in the walk's own space (the waypoints use it).
func step_foot(flight: int) -> Vector3:
	if flight < 0:
		# A ramp's (-1 the first).
		var r: Vector2 = ramps[-flight - 1]
		return Vector3(r.x, -street_below, -walk_depth - (top + street_below) * ramp_slope - 0.4)
	var n := _rises(top + street_below)
	var f: Vector2 = steps[flight]
	return Vector3(f.x, -street_below, -walk_depth - n * TREAD - 0.4)


## Where a man stands at the foot of an end's flight or ramp (end 0 or 1), in the walk's own space:
## past the end, on what's below; and at its head, on the planks. [] with nothing at that end.
func end_foot_head(end: int) -> Array:
	var run := _end_run(end)
	if run <= 0.0:
		return []
	var below := 0.0
	for e: Vector2 in end_steps + end_ramps:
		if int(e.x) == end:
			below = e.y
	var out := -1.0 if end == 0 else 1.0
	var x_end := 0.0 if end == 0 else length
	return [Vector3(x_end + out * 0.5, below, -walk_depth * 0.5), Vector3(x_end - out * (run + 0.4), top, -walk_depth * 0.5)]


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
