class_name HangingRope
extends Node3D
## A rope hanging from where it's tied (this node's origin) straight down, that a ball can cut:
## the hanging's rope and the Winchester's rope shot (#734, #777). A ball takes the share of the
## rope's section its own width passes through (a centred .44 ball through a 3/4" rope takes about
## two thirds; a graze a sliver); cuts at the same place add up; the rope parts when what's left
## can't hold what hangs on it (`part_left`: under a man's weight the strands left are taut and give
## way long before they'd break whole). What parts falls (the piece below the cut, and its load's
## weight goes with it); `parted` is said.
##
## The ball's flight is a ray (Ballistics), so the rope's shape is fattened by a ball's radius
## (`BALL_PAD`): a ball whose edge clips the rope touches it; the cut is worked out from the true
## rope and the true ball.

signal parted(at: Vector3)

## A .44's half-width: the collision shape's pad round the rope.
const BALL_PAD := 0.0056
## Cuts this close together (m along the rope) count as one place.
const SAME_PLACE := 0.03

## 3/4" manila, a hangman's rope.
@export var length := 2.0
@export var diameter := 0.019
## What hangs on it (kg): a man's weight, or nothing.
@export var load_kg := 0.0
## Under a load it parts with less than this share of its section left; hanging empty, with less
## than `part_left_empty` (it hangs by a few fibres).
@export var part_left := 0.45
@export var part_left_empty := 0.08

var body: StaticBody3D
var mesh: MeshInstance3D
## Where it was cut (m below the knot) -> the share of the section gone there.
var cuts := {}
## Balls that touched it, and how many parted it.
var hits := 0
var is_parted := false
var parted_at := Vector3.ZERO
## The piece that fell (a RigidBody3D), once parted.
var fallen: RigidBody3D

var _mat: StandardMaterial3D


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.62, 0.52, 0.36)
	_mat.roughness = 0.95
	_build(length)


func _build(hang: float) -> void:
	if body:
		body.queue_free()
	body = StaticBody3D.new()
	body.name = "Rope"
	body.collision_layer = Layers.ROPES
	body.collision_mask = 0
	body.set_meta(&"hanging_rope", self)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = diameter * 0.5 + BALL_PAD
	cyl.height = hang
	shape.shape = cyl
	shape.position = Vector3.DOWN * hang * 0.5
	body.add_child(shape)
	mesh = MeshInstance3D.new()
	mesh.name = "RopeMesh"
	mesh.mesh = _rope_mesh(hang)
	mesh.position = Vector3.DOWN * hang * 0.5
	mesh.material_override = _mat
	body.add_child(mesh)
	add_child(body)


func _rope_mesh(hang: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = diameter * 0.5
	m.bottom_radius = diameter * 0.5
	m.height = hang
	m.radial_segments = 8
	m.rings = 1
	return m


## A ball (radius `ball_r`) at `at` going `dir` touched it: cut it by the share of its section the
## ball's width takes, part it if too little's left. Returns that share (0: it only grazed the pad).
func take_ball(at: Vector3, dir: Vector3, ball_r: float) -> float:
	if is_parted:
		return 0.0
	var local := to_local(at)
	var down := -local.y
	# The ball's path across the rope, flattened onto the rope's section: how far it passes from
	# the rope's middle, sideways to its own way.
	var d_local := (global_transform.basis.inverse() * dir)
	var flat := Vector2(d_local.x, d_local.z)
	var p := Vector2(local.x, local.z)
	var offset := 0.0
	if flat.length() > 1e-5:
		var u := flat.normalized()
		offset = absf(p.x * u.y - p.y * u.x)
	var r := diameter * 0.5
	var cut := (_area_left_of(offset + ball_r, r) - _area_left_of(offset - ball_r, r)) / (PI * r * r)
	if cut <= 0.0:
		return 0.0
	hits += 1
	var key := -1.0
	for k: float in cuts:
		if absf(k - down) < SAME_PLACE:
			key = k
	if key < 0.0:
		key = down
		cuts[key] = 0.0
	cuts[key] = minf(float(cuts[key]) + cut, 1.0)
	var left := 1.0 - float(cuts[key])
	if left < (part_left if load_kg > 20.0 else part_left_empty):
		_part(key)
	return cut


## The share of the rope's section left of the line `x` across it (radius `r`), as area.
static func _area_left_of(x: float, r: float) -> float:
	x = clampf(x, -r, r)
	return r * r * acos(-x / r) + x * sqrt(maxf(r * r - x * x, 0.0))


## How much of its section is left at its weakest place (1 whole).
func weakest_left() -> float:
	var worst := 0.0
	for k: float in cuts:
		worst = maxf(worst, float(cuts[k]))
	return 1.0 - worst


func _part(down: float) -> void:
	is_parted = true
	parted_at = to_global(Vector3.DOWN * down)
	var below := length - down
	_build(maxf(down, 0.02))
	if below > 0.02 and is_inside_tree():
		fallen = RigidBody3D.new()
		fallen.name = "RopeEnd"
		fallen.mass = maxf(0.3 * below + load_kg, 0.2)
		fallen.collision_layer = Layers.DEBRIS
		fallen.collision_mask = Layers.DEBRIS_MASK
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = diameter * 0.5
		cap.height = maxf(below, diameter + 0.001)
		shape.shape = cap
		fallen.add_child(shape)
		var m := MeshInstance3D.new()
		m.mesh = _rope_mesh(below)
		m.material_override = _mat
		fallen.add_child(m)
		get_parent().add_child(fallen)
		fallen.global_position = to_global(Vector3.DOWN * (down + below * 0.5))
	parted.emit(parted_at)


## Whole again (the labs and tests: a fresh rope each shot).
func mend() -> void:
	cuts.clear()
	is_parted = false
	if fallen and is_instance_valid(fallen):
		fallen.queue_free()
	fallen = null
	_build(length)
