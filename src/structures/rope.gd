class_name Rope
extends Node3D
## A rope hanging from where this node is (#734: the rope shot; later Joe's hanging): a hemp line
## `length` m straight down, with whatever hangs on it (`load_kg`, a sack as a stand-in) at its end.
## A ball that touches it cuts the strands it passes through: the band of the rope's section its
## width sweeps, by where it crossed (`cut_share`); a ball through the middle of a 7/8" rope cuts
## about three fifths of it, one grazing its edge a fifth. Cuts at one height add up; the rope parts
## where what's cut reaches `parting_share` (with a man's weight kicking on it a rope goes long
## before every strand is through: est.). Parted, what's below falls with the load; a hit that doesn't
## part it sets it swinging. Balls find it on Layers.ROPES (nothing walks into it); Ballistics calls
## `take_ball`.

signal hit(info: Dictionary)
signal parted(height: float)

## Metres from the anchor down to its end (to the load's knot).
@export var length := 1.8
## A 7/8" hemp hanging rope (22 mm).
@export var diameter := 0.022
## What hangs on it (kg; 0 for a bare rope): a sack of sand as a man's stand-in.
@export var load_kg := 40.0
## The share of its section cut through at one height where it parts (est.: a sound new rope holds a
## man on far less than half its strands; an old one and a kicking man, not).
@export var parting_share := 0.5
## Cuts within this far of each other along it count as one section (m: the ball's width and the
## strands' twist).
@export var section_reach := 0.03
## Swings when hit (tests that count hits on a still rope turn it off).
@export var swings := true
## A fresh rope hung again this many seconds after it parted (the gun lab's range: 0 never).
@export var mend_after := 0.0

## The section cuts: [{y (m below the anchor), cuts: Array of Vector2 (from, to) across the section,
## m from its axis}].
var sections: Array[Dictionary] = []
var is_parted := false
var hits := 0

var _body: StaticBody3D
var _shape: CollisionShape3D
var _mesh: MeshInstance3D
var _load: MeshInstance3D
var _swing := Vector2.ZERO
var _swing_v := Vector2.ZERO
var _cut_at := 0.0
var _mend_in := 0.0
var _fallen: Array[Node] = []


func _ready() -> void:
	_build()


func _build() -> void:
	_body = StaticBody3D.new()
	_body.name = "RopeBody"
	_body.collision_layer = Layers.ROPES
	_body.collision_mask = 0
	_body.set_meta(&"rope", self)
	add_child(_body)
	_shape = CollisionShape3D.new()
	_shape.shape = CylinderShape3D.new()
	_body.add_child(_shape)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Line"
	_mesh.mesh = CylinderMesh.new()
	_mesh.material_override = _hemp()
	_body.add_child(_mesh)
	if load_kg > 0.0:
		_load = MeshInstance3D.new()
		_load.name = "Load"
		var sack := BoxMesh.new()
		sack.size = _sack_size()
		_load.mesh = sack
		_load.material_override = _burlap()
		_body.add_child(_load)
	_hang(length)


## Draws and shapes it `to` m long below the anchor.
func _hang(to: float) -> void:
	var cyl := _shape.shape as CylinderShape3D
	cyl.radius = diameter * 0.5
	cyl.height = maxf(to, 0.01)
	_shape.position = Vector3(0.0, -to * 0.5, 0.0)
	var cm := _mesh.mesh as CylinderMesh
	cm.top_radius = diameter * 0.5
	cm.bottom_radius = diameter * 0.5
	cm.height = maxf(to, 0.01)
	cm.radial_segments = 8
	_mesh.position = _shape.position
	if _load:
		_load.visible = to >= length - 0.001
		_load.position = Vector3(0.0, -length - _sack_size().y * 0.5, 0.0)


func _sack_size() -> Vector3:
	var v := maxf(load_kg, 1.0) / 1600.0  # sand in a sack, m3
	return Vector3(0.32, v / (0.32 * 0.24), 0.24)


static func _hemp() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.58, 0.48, 0.33)
	m.roughness = 0.95
	return m


static func _burlap() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.47, 0.38, 0.25)
	m.roughness = 1.0
	return m


## A ball at `at` going `dir` (`ball_d` m across): cuts what it passes through, and says so. Returns
## the joules it took from the ball.
func take_ball(at: Vector3, dir: Vector3, ball_d: float, energy: float) -> float:
	if is_parted:
		return 0.0
	var local := _body.global_transform.affine_inverse() * at
	var y := -local.y
	var off := cross_offset(_body.global_transform.basis.inverse() * dir, local)
	var share := add_cut(y, off, ball_d * 0.5)
	hits += 1
	var info := {"y": y, "offset": off, "share": share, "parted": false}
	if share >= parting_share:
		part(y)
		info.parted = true
	elif swings:
		var side := (_body.global_transform.basis.inverse() * dir)
		_swing_v += Vector2(side.x, side.z).normalized() * 0.6 * minf(energy / 1000.0, 1.0) / maxf(1.0 + load_kg * 0.05, 1.0)
	hit.emit(info)
	return minf(energy, 5.0)


## Where a ball's line crosses the rope's section, in the rope's own space (`dir`, `at` in it): its
## signed distance from the axis across the section (m).
static func cross_offset(dir: Vector3, at: Vector3) -> float:
	var d := Vector2(dir.x, dir.z)
	if d.length() < 1e-5:
		return 0.0
	d = d.normalized()
	# The axis is the local Y line through (0, 0): its distance from the ball's line, signed.
	var p := Vector2(at.x, at.z)
	return p.x * d.y - p.y * d.x


## The band (off - r, off + r) cut through the section `y` m down; returns the section's share cut.
func add_cut(y: float, off: float, r: float) -> float:
	var sec: Dictionary = {}
	for s in sections:
		if absf(float(s.y) - y) <= section_reach:
			sec = s
			break
	if sec.is_empty():
		sec = {"y": y, "cuts": []}
		sections.append(sec)
	(sec.cuts as Array).append(Vector2(off - r, off + r))
	return cut_share(sec.cuts, diameter * 0.5)


## The share of a round section of radius `big_r` inside the union of the bands across it.
static func cut_share(bands: Array, big_r: float) -> float:
	var spans: Array[Vector2] = []
	for b: Vector2 in bands:
		var lo := clampf(b.x, -big_r, big_r)
		var hi := clampf(b.y, -big_r, big_r)
		if hi > lo:
			spans.append(Vector2(lo, hi))
	spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var merged: Array[Vector2] = []
	for s in spans:
		if not merged.is_empty() and s.x <= merged[-1].y:
			merged[-1].y = maxf(merged[-1].y, s.y)
		else:
			merged.append(s)
	var area := 0.0
	for s in merged:
		area += _chord_area(s.y, big_r) - _chord_area(s.x, big_r)
	return area / (PI * big_r * big_r)


## The area of a circle of radius r from its left edge to x (the strip's integral).
static func _chord_area(x: float, r: float) -> float:
	x = clampf(x, -r, r)
	return x * sqrt(maxf(r * r - x * x, 0.0)) + r * r * asin(x / r) + PI * r * r * 0.5


## It parts `y` m below the anchor: the rest of it and the load fall.
func part(y: float) -> void:
	if is_parted:
		return
	is_parted = true
	_cut_at = clampf(y, 0.0, length)
	_hang(_cut_at)
	var below := length - _cut_at
	var host := get_parent()
	if host and below > 0.005:
		var piece := RigidBody3D.new()
		piece.name = "RopeEnd"
		piece.mass = maxf(load_kg, 0.3)
		piece.collision_layer = Layers.DEBRIS
		piece.collision_mask = Layers.DEBRIS_MASK
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = _sack_size() if load_kg > 0.0 else Vector3(diameter, below, diameter)
		cs.shape = box
		piece.add_child(cs)
		var line := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = diameter * 0.5
		cm.bottom_radius = diameter * 0.5
		cm.height = below
		cm.radial_segments = 8
		line.mesh = cm
		line.material_override = _hemp()
		piece.add_child(line)
		if load_kg > 0.0:
			cs.position = Vector3(0.0, -below * 0.5 - _sack_size().y * 0.5, 0.0)
			var sack := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = _sack_size()
			sack.mesh = bm
			sack.material_override = _burlap()
			sack.position = cs.position
			piece.add_child(sack)
		host.add_child(piece)
		piece.global_transform = _body.global_transform * Transform3D(Basis(), Vector3(0.0, -_cut_at - below * 0.5, 0.0))
		_fallen.append(piece)
	if mend_after > 0.0:
		_mend_in = mend_after
	parted.emit(_cut_at)


## A fresh rope in its place (and what fell of the old one taken away).
func mend() -> void:
	for n in _fallen:
		if is_instance_valid(n):
			n.queue_free()
	_fallen.clear()
	sections.clear()
	is_parted = false
	_swing = Vector2.ZERO
	_swing_v = Vector2.ZERO
	_body.rotation = Vector3.ZERO
	_hang(length)


func _physics_process(delta: float) -> void:
	if _mend_in > 0.0:
		_mend_in -= delta
		if _mend_in <= 0.0:
			mend()
	if not swings or is_parted or (_swing.length() < 1e-4 and _swing_v.length() < 1e-4):
		return
	# A pendulum (small angles, damped): its period by its length to the load.
	var w2 := 9.81 / maxf(length, 0.2)
	_swing_v += (-_swing * w2 - _swing_v * 0.6) * delta
	_swing += _swing_v * delta
	_body.rotation = Vector3(_swing.y, 0.0, -_swing.x)
