class_name GarmentHandoff
extends Node3D
## The garment handoff (#917, promoted from the lab, #895, experiments/garment_handoff/): a garment
## worn as part of a man's skinned mesh (WornGarment) becomes real cloth as it's taken off, and lies
## where it lands at no cost. The cloth is our own (SolverCloth, the native plugin's ClothCore, #986:
## it meets his posed skin itself, with a thickness, on the side each point came from, so the glove's
## wrist stretches over his hand instead of going through it) where the plugin is, else Jolt's soft
## body (GarmentCloth, his skin a Jolt shape: the web build's fallback).
##
## The part gives the steps; the choreography (where the hands go, when, the toss's aim) is the
## caller's (the lab's handoff.gd, a dancer's act):
## - `wear(man, garment, look)`: on him, drawn by the GPU with his skin, costing nothing a tick;
## - `take(hand_side)`: the worn mesh hidden and the cloth in its place, every point started where
##   the GPU drew it this tick (no pop), the fingertips pinned to his hand on `hand_side`, the rest
##   held to its own bones as worn (friction), his skin the collider (SkinCollider);
## - while held, **friction gives way by the pull**: while the cloth already pulled free is stretched
##   past `give`, the points still on him nearest the tips let go, the front moving `front_step` m
##   along him a tick at most (a release by distance drawn stretched the lab's stalls to 1.9x);
## - `let_go_of_arm()`: all of it off him; `let_go(velocity)`: out of his hand too, falling;
## - at rest (GarmentCloth) the soft body is out, his skin shape off, and nothing runs (`came_to_rest`).
## Measures: `pop_mm` (the swap's worst move, its first three ticks), `under_skin()`, `stretch()`.

signal taken
signal came_to_rest

enum State { NONE, WORN, HELD, FREE, REST }

## His skin under the glove as SkinCollider has it: simplified to about this many triangles (0: the
## glove's own points).
const COLLIDER_TRIS := 0
## His skin finer than the glove, its hand's vertices kept under our cloth's triangles (#1008: his
## fingers showed through the glove between its ~5 points round each as it was drawn off): about
## this many triangles over the glove's cut (0: none). Our cloth only (`body_verts`); his hand and
## forearm (SkinCollider.FINE_FOREARM). On since #1008's second part: pop ~1.8 mm, stretch ~1.08, and
## ~2.3 ms a tick more at Sean's while it's drawn (0 worn, ~0.2 tossed, 0 at rest).
const FINE_TRIS := 3000

## The release rule's numbers (m, the edges' length ratio). `release_lead`: the finger ends this
## far from the tips let go at the take; `clear_after`: his skin shape stays this long after he lets
## go (it's falling off him).
var tune := {"release_lead": 0.035, "give": 1.05, "front_step": 0.01, "clear_after": 0.25,
		"precision": 12, "skin_every": 2, "uncover_at": 0.018,
		"free_damping": 0.5, "solver": true}

## Our cloth's numbers for kid leather (ClothCore.tune's names): it keeps its made shape's folds
## (SHAPED), gives 5% at most, 20 substeps (a landing stretches short edges past the limit with
## fewer); his skin met 0.7 mm off (SkinCollider's pad: where the cloth starts), little friction
## (the release rule is the hold; free leather slides on skin). `floor_y` is his feet's.
## His skin is closed: every point belongs on its front (`body_front_only`).
## His hand's own skin kept 0.5 mm behind its triangles (`body_verts`, #1008) when he has a finer
## skin (FINE_TRIS). Itself off (`self_thickness` 0): on (2 mm) it lies on itself, but costs ~4.5 ms a tick more at Sean's
## drawn and sean_s3_talking's seed 2 never comes to rest (#1029; the lab's `--solver=`).
var solver_tune := {"bend_mode": SolverCloth.SHAPED, "bend_stiffness": 0.5, "max_strain": 1.05,
		"substeps": 20, "damping": 1.0, "body_thickness": SkinCollider.SKIN_PAD, "body_band": 0.01, "body_every": 1,
		"body_friction_static": 0.15, "body_friction_kinetic": 0.1, "body_front_only": 1,
		"self_thickness": 0.0, "body_verts": 0.0005}
## Once out of his hand (falling, lying): damped more, as `free_damping` is Jolt's.
const SOLVER_FREE_DAMPING := 2.0

var man: HumanBody
var garment: WornGarment
var look: Material
var worn_mesh: MeshInstance3D
## SolverCloth or GarmentCloth (the same calls).
var cloth: Node3D
var collider: SkinCollider
var state := State.NONE
## The swap's worst move (mm): the cloth's points against where the worn garment would be drawn,
## its first three ticks. -1 until taken.
var pop_mm := -1.0
## The free cloth's stretch (the release rule's measure) and the points still held on him.
var free_stretch := 1.0
var released_all_at := -1.0
## Its own tick's cost (µs, the last tick: the release rule and the skin shape).
var tick_us := 0

var _on_arm := {}
var _free_edges := PackedInt32Array()   # pairs, both points free
var _free_rest := 0.0
var _nbr: Array = []                    # point -> [other, rest length] ...
var _held_mask := PackedByteArray()     # 1 a point still held on him
var _moved := PackedByteArray()         # 1 a point whose spot the cloth has left (his skin shown)
var _uncover_turn := 0
var _ring2: Array = []                  # each point's neighbours two edges out (PackedInt32Array)
var _clear_t := 0.0
var _pop_ticks := 0
var _t := 0.0


## `g` on `who` (made from his skin by WornGarment), drawn with `material`.
func wear(who: HumanBody, g: WornGarment, material: Material = null) -> MeshInstance3D:
	man = who
	garment = g
	look = material if material else WornGarment.kid_leather()
	worn_mesh = g.wear(look)
	g.cover_skin(true)  # (his skin under it not drawn: his sleeve's folds would show through)
	state = State.WORN
	set_physics_process(false)  # worn, nothing to do: the GPU draws it with his skin
	return worn_mesh


## A long glove on `who`'s arm on `side`, worn (null if he has no skin to make it from).
static func glove_on(who: HumanBody, parent: Node, side := "l", material: Material = null, tris := 700,
		under_tris := COLLIDER_TRIS, fine_tris := FINE_TRIS) -> GarmentHandoff:
	var g := WornGarment.glove(who, side, 0.42, tris, under_tris, fine_tris)
	if g == null:
		return null
	var h := GarmentHandoff.new()
	h.name = "Glove_" + side
	parent.add_child(h)
	h.wear(who, g, material)
	return h


## The handoff: the worn garment out, the cloth in where it was drawn, its tips (`points`, the
## garment's own by default) pinned to his hand on `hand_side`, the rest held on his bones.
func take(hand_side := "r", points: Array[int] = []) -> void:
	if state != State.WORN:
		return
	if points.is_empty():
		points = garment.tips
	var pts := garment.posed()
	var ours: SolverCloth = null
	if bool(tune.solver) and SolverCloth.available():
		var t := solver_tune.duplicate()
		t["floor_y"] = man.global_position.y
		ours = SolverCloth.make(pts, garment.indices, garment.uvs, look, 0.035 / maxf(_area(pts), 1e-4), t)
	if ours:
		cloth = ours
		cloth.name = "SolverCloth"
	else:
		cloth = GarmentCloth.make(pts, garment.indices, garment.uvs, look, 0.035, int(tune.precision))
		cloth.name = "GarmentCloth"
	add_child(cloth)
	cloth.global_transform = Transform3D.IDENTITY
	worn_mesh.visible = false
	collider = SkinCollider.new()
	collider.name = "SkinCollider"
	add_child(collider)
	collider.global_transform = Transform3D.IDENTITY
	collider.setup(garment.under if garment.under else garment, ours)
	if ours and garment.fine and float(solver_tune.get("body_verts", 0.0)) > 0.0:
		collider.fine = garment.fine
	collider.every = int(tune.skin_every)
	var is_tip := {}
	for i in points:
		is_tip[i] = true
	cloth.pin_to(points, man.parts[StringName("hand_" + hand_side)], man, hand_side)
	var rest: Array[int] = []
	for i in pts.size():
		if not is_tip.has(i):
			rest.append(i)
	cloth.hold_on(rest)
	_on_arm = {}
	_held_mask = PackedByteArray()
	_held_mask.resize(pts.size())
	for i in rest:
		_on_arm[i] = true
		_held_mask[i] = 1
	_nbr.resize(pts.size())
	for i in _nbr.size():
		_nbr[i] = []
	var tri := garment.indices
	for k in range(0, tri.size(), 3):
		for e in 3:
			var a: int = tri[k + e]
			var b: int = tri[k + (e + 1) % 3]
			var l := pts[a].distance_to(pts[b])
			(_nbr[a] as Array).append([b, l])
			(_nbr[b] as Array).append([a, l])
	_free_edges = PackedInt32Array()
	_free_rest = 0.0
	_free = {}
	for i in points:
		_freed(i)
	_release_along(float(tune.release_lead))
	_moved = PackedByteArray()
	_moved.resize(pts.size())
	_ring2 = []
	_ring2.resize(pts.size())
	for i in pts.size():
		var r := {}
		for nb: Array in _nbr[i]:
			r[nb[0]] = true
			for nb2: Array in _nbr[int(nb[0])]:
				r[nb2[0]] = true
		r.erase(i)
		_ring2[i] = PackedInt32Array(r.keys())
	collider.free_box = _free_box(pts)
	collider.on()
	state = State.HELD
	_pop_ticks = 3
	pop_mm = 0.0
	_t = 0.0
	set_physics_process(true)
	taken.emit()


## All of it off his arm (the draw's end): only his hand has it.
func let_go_of_arm() -> void:
	if cloth == null:
		return
	_release(_on_arm.duplicate())


## Out of his hand and off him: it falls, with `velocity` added (m/s).
func let_go(velocity := Vector3.ZERO) -> void:
	if cloth == null or state != State.HELD:
		return
	let_go_of_arm()
	cloth.let_go(velocity)
	# Falling and lying, damped harder: Godot's soft body has no bending stiffness, and an undamped
	# glove crumples to a knot of fingers through each other (it doesn't meet itself); damped, it
	# keeps its hand's shape as leather does.
	if cloth is SolverCloth:
		(cloth as SolverCloth).tune("damping", SOLVER_FREE_DAMPING)
	else:
		cloth.soft.damping_coefficient = float(tune.free_damping)
	garment.cover_skin(false)  # out of his hand: all his skin drawn again
	if cloth is SolverCloth:
		(cloth as SolverCloth).skin_out()  # his hand's no longer in it (#1008: 25 ms a tick tossed)
	state = State.FREE
	_clear_t = float(tune.clear_after)
	if not cloth.came_to_rest.is_connected(_on_rest):
		cloth.came_to_rest.connect(_on_rest)


## Whether it's our own cloth (SolverCloth) rather than Jolt's.
func ours() -> bool:
	return cloth is SolverCloth


## Its triangles' area (m²): our cloth is given a density, Jolt's a mass.
func _area(pts: PackedVector3Array) -> float:
	var a := 0.0
	var idx := garment.indices
	for k in range(0, idx.size(), 3):
		a += 0.5 * (pts[idx[k + 1]] - pts[idx[k]]).cross(pts[idx[k + 2]] - pts[idx[k]]).length()
	return a


## Points still held on him.
func on_arm() -> int:
	return _on_arm.size()


func points_now() -> PackedVector3Array:
	return cloth.points_now() if cloth else garment.posed()


func stretch() -> float:
	return cloth.stretch() if cloth else 1.0


## How many of its points are under his skin as drawn now, more than `depth` (m). A measure (~10 ms).
func under_skin(depth := 0.002) -> int:
	return garment.under_skin(points_now(), depth)


func _physics_process(delta: float) -> void:
	var pt := Prof.start()
	var t0 := Time.get_ticks_usec()
	_t += delta
	_step(delta)
	tick_us = Time.get_ticks_usec() - t0
	Prof.stop(&"garment", pt)


func _step(delta: float) -> void:
	if cloth == null or cloth.resting:
		return
	# Where the worn garment would be drawn now (once a tick, while it's on him): the held points go
	# there, and his skin is shown where the cloth has left it.
	var drawn := PackedVector3Array()
	if state == State.HELD and (_pop_ticks > 0 or Engine.get_physics_frames() % 2 == 0):
		drawn = garment.posed()
		if not _on_arm.is_empty():
			cloth.move_held(PackedInt32Array(_on_arm.keys()), drawn)
	var pts := PackedVector3Array()
	if state == State.HELD or _pop_ticks > 0:
		pts = cloth.points_now()
	if _pop_ticks > 0:
		_pop_ticks -= 1
		if drawn.is_empty():
			drawn = garment.posed()
		for i in pts.size():
			pop_mm = maxf(pop_mm, pts[i].distance_to(drawn[i]) * 1000.0)
	if state == State.HELD:
		_by_the_pull(pts)
		_uncover(pts, drawn)
		collider.free_box = _free_box(pts)
	elif state == State.FREE and collider.active:
		_clear_t -= delta
		if _clear_t <= 0.0:
			collider.off()  # it's clear of him: the skin shape (and its cost) gone
		else:
			collider.free_box = _free_box(cloth.points_now())
	collider.step()


## Friction giving way: while the cloth already pulled free is stretched past its give, the points
## still on him nearest the tips let go, the front moving up at most `front_step` m a tick. (The
## free cloth as a whole, not the edges at the front: with the solver's few iterations the stretch
## gathers in the middle of the free cloth, away from the pins.)
func _by_the_pull(pts: PackedVector3Array) -> void:
	if _on_arm.is_empty():
		return
	var now := 0.0
	var fe := _free_edges
	for e in range(0, fe.size(), 2):
		now += pts[fe[e]].distance_to(pts[fe[e + 1]])
	free_stretch = now / maxf(_free_rest, 1e-6)
	if free_stretch <= float(tune.give):
		return
	var front := INF
	for i: int in _on_arm:
		front = minf(front, garment.along[i])
	_release_along(front + float(tune.front_step))


## His skin shown under each point the cloth has left: the cloth there has moved off where the
## worn garment was (`tune.uncover_at`, m) and none of the cloth near it (its neighbours two edges
## out: the cloth slides along him, so the cloth that covers a spot next comes from beside it) lies
## within `uncover_at` of that spot. Until then his skin there stays hidden: his sleeve's modelled
## folds stand above the cloth's few hundred points. Every 2nd tick, a third of the points.
func _uncover(pts: PackedVector3Array, drawn: PackedVector3Array) -> void:
	if not garment.skin_covered() or drawn.is_empty():
		return
	var far := float(tune.uncover_at) * float(tune.uncover_at)
	var ids: Array[int] = []
	_uncover_turn = (_uncover_turn + 1) % 3
	for i in range(_uncover_turn, pts.size(), 3):  # (a third of them each time: shown within 0.1 s)
		if _moved[i] == 1 or _held_mask[i] == 1:
			continue
		var w := drawn[i]
		if pts[i].distance_squared_to(w) <= far:
			continue
		var covered := false
		for j: int in _ring2[i]:
			if pts[j].distance_squared_to(w) <= far:
				covered = true
				break
		if not covered:
			_moved[i] = 1
			ids.append(i)
	garment.uncover(ids)


## Those still on him up to `reach` along him from the tips let go.
func _release_along(reach: float) -> void:
	var go := {}
	for i: int in _on_arm:
		if garment.along[i] <= reach:
			go[i] = true
	_release(go)


func _release(go: Dictionary) -> void:
	if go.is_empty():
		return
	for i: int in go:
		_on_arm.erase(i)
		_held_mask[i] = 0
	for i: int in go:
		_freed(i)
	cloth.release(go)
	if _on_arm.is_empty() and released_all_at < 0.0:
		released_all_at = _t


## Point `i` is free: its edges to points already free join the free cloth's measure.
func _freed(i: int) -> void:
	if _free.has(i):
		return
	for nb: Array in _nbr[i]:
		var j: int = nb[0]
		if _free.has(j):
			_free_edges.append(i)
			_free_edges.append(j)
			_free_rest += float(nb[1])
	_free[i] = true


var _free := {}


## The free cloth's box (world): what his skin shape is rebuilt near.
func _free_box(pts: PackedVector3Array) -> AABB:
	var box := AABB()
	var first := true
	for i in pts.size():
		if _on_arm.has(i):
			continue
		if first:
			box = AABB(pts[i], Vector3.ZERO)
			first = false
		else:
			box = box.expand(pts[i])
	return box


func _on_rest() -> void:
	state = State.REST
	garment.cover_skin(false)
	if collider:
		collider.off()
	set_physics_process(false)
	came_to_rest.emit()
