class_name EngineModel
extends Node3D
## The engine as built in Blender (`experiments/train_lab/blender/engine.py` -> assets/train/engine.glb,
## train step 3, docs/briefs/train.md): an 1882 narrow-gauge 2-8-0 after the D&RG's class 70. The
## glb's still body and its moving parts (each a node on its own pivot); the numbers it moves them
## by come with it (`engine_rig.json`).
##
## Everything moves exactly with the distance travelled (`roll(s)`), never with time: the drivers
## turn s / r, the side rods ride the crank pins (the right side leading the left by a quarter),
## each main rod runs from its pin to a crosshead on its slide. The exhaust beats four a wheel turn
## (two cylinders, both strokes): each sends a puff up the stack, as big as the steam the cylinders
## take; at a start the cylinder cocks blow white steam out at the beats too. The stack smokes
## lightly always (the fire). The headlight is lit at night.
##
## A child of a car's drawn body (TrainView), so its origin is the car's (midway between its
## trucks on the rail top, -Z forward).

const GLB := "res://assets/train/engine.glb"
const RIG := "res://assets/train/engine_rig.json"
## Below this speed (m/s) with steam on, the cocks are open (they drain the cylinders at a start).
const COCKS_BELOW := 2.5
## The puffs' size and life at full steam.
const PUFF_PARTICLES := 3

var rig := {}
var drivers: Array[Node3D] = []
var pony: Node3D
var side_rods := {}  # "R"/"L" -> Node3D
var main_rods := {}
var crossheads := {}
var stack_smoke: GPUParticles3D
var exhaust: GPUParticles3D
var cocks: Array[GPUParticles3D] = []
var headlight: SpotLight3D
var lens: MeshInstance3D
## How many beats have gone up the stack (the sound's step 4 counts on them).
var beats := 0
## The steam share (0..1) the next beats use: TrainView sets it from the sim each frame.
var steam := 0.0
var speed := 0.0

var _rest := {}  # node -> its rest position
var _beat := 0  # the quarter-turn the drivers were last in
var _rolled := false


## Built at once (TrainView places and rolls it before it's in the tree).
func _init() -> void:
	rig = JSON.parse_string(FileAccess.get_file_as_string(RIG))
	var scene: PackedScene = load(GLB)
	var root := scene.instantiate()
	add_child(root)
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		TrainModels.dress(mi as MeshInstance3D)
	for k in 4:
		drivers.append(root.find_child("Driver%d" % k, true, false))
	pony = root.find_child("Pony", true, false)
	for side in ["R", "L"]:
		side_rods[side] = root.find_child("SideRod" + side, true, false)
		main_rods[side] = root.find_child("MainRod" + side, true, false)
		crossheads[side] = root.find_child("Crosshead" + side, true, false)
	for n: Node3D in [side_rods.R, side_rods.L, main_rods.R, main_rods.L, crossheads.R, crossheads.L]:
		_rest[n] = n.position
	_smoke()
	_headlight()
	roll(0.0)


## Every moving part where the engine is `s` metres along (its front's distance; any origin).
func roll(s: float) -> void:
	var r: float = rig.driver_r
	var theta := -s / r  # forward (-Z): the tops turn forward
	for d in drivers:
		d.rotation.x = theta
	if pony:
		pony.rotation.x = -s / float(rig.pony_r)
	var crank: float = rig.crank
	var main_z: float = rig.drivers_z[int(rig.main)]
	for side in ["R", "L"]:
		var phase: float = rig.pins[side]
		# The pin's offset from its axle: at rest (cos phase, sin phase) x crank in (y, z), turned by theta.
		var y0 := cos(phase) * crank
		var z0 := sin(phase) * crank
		var y := y0 * cos(theta) - z0 * sin(theta)
		var z := y0 * sin(theta) + z0 * cos(theta)
		var rod: Node3D = side_rods[side]
		rod.position = _rest[rod] + Vector3(0.0, y - y0, z - z0)
		var pin := Vector3(0.0, r + y, main_z + z)
		var dy := pin.y - float(rig.slide_y)
		var length: float = rig.main_len
		var cz := pin.z - sqrt(maxf(length * length - dy * dy, 0.0))
		var ch: Node3D = crossheads[side]
		ch.position = Vector3(ch.position.x, float(rig.slide_y), cz)
		var mr: Node3D = main_rods[side]
		mr.position = Vector3(mr.position.x, pin.y, pin.z)
		# The rod lies along -Z from its pin: turn it about X so it points at the crosshead.
		mr.rotation.x = atan2(-dy, pin.z - cz)
	# The beats: four a turn (each cylinder's two strokes).
	var quarter := int(floor(theta / (PI * 0.5)))
	if _rolled and quarter != _beat:
		for k in mini(absi(quarter - _beat), 4):
			_exhaust_beat()
	_beat = quarter
	_rolled = true


func _exhaust_beat() -> void:
	beats += 1
	if steam < 0.03:
		return
	var up := global_basis.y
	var at := to_global(_v3(rig.stack))
	var n := maxi(1, int(round(PUFF_PARTICLES * clampf(steam * 1.5, 0.3, 1.5))))
	for k in n:
		var v := up * (3.0 + 5.0 * steam) + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4))
		exhaust.emit_particle(Transform3D(Basis.IDENTITY, at), v, Color(1, 1, 1, clampf(0.4 + steam, 0.4, 1.0)),
			Color(), GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY | GPUParticles3D.EMIT_FLAG_COLOR)
	if speed < COCKS_BELOW:
		for k in cocks.size():
			var c := cocks[k]
			var out := global_basis.x * (1.0 if k == 1 else -1.0)
			for j in 2:
				c.emit_particle(Transform3D(Basis.IDENTITY, c.global_position), out * randf_range(2.0, 3.5) + up * 0.3,
					Color.WHITE, Color(), GPUParticles3D.EMIT_FLAG_POSITION | GPUParticles3D.EMIT_FLAG_VELOCITY)


static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _smoke() -> void:
	# The fire's own smoke, always: a thin drift out of the stack, left behind in the air.
	stack_smoke = FireFX._particles(24, 4.0, FireFX._smoke_material(), 0.9)
	var pm := stack_smoke.process_material as ParticleProcessMaterial
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0.2, 0.4, 0.0)
	pm.damping_min = 0.3
	pm.damping_max = 0.6
	pm.scale_min = 0.6
	pm.scale_max = 1.8
	pm.color_ramp = _ramp([[0.0, Color(0.2, 0.19, 0.18, 0.0)], [0.1, Color(0.22, 0.21, 0.2, 0.45)],
		[0.6, Color(0.35, 0.34, 0.33, 0.3)], [1.0, Color(0.45, 0.44, 0.43, 0.0)]])
	stack_smoke.visibility_aabb = AABB(Vector3(-30, -5, -30), Vector3(60, 30, 60))
	add_child(stack_smoke)
	stack_smoke.position = _v3(rig.stack)
	# The exhaust: puffs emitted one by one at the beats (no steady stream), grey-white, fast up
	# then slowing and spreading.
	exhaust = FireFX._particles(160, 3.0, FireFX._smoke_material(), 1.0)
	exhaust.emitting = true
	exhaust.amount_ratio = 0.0  # nothing on its own: only what emit_particle sends
	var em := exhaust.process_material as ParticleProcessMaterial
	em.gravity = Vector3(0.0, 0.3, 0.0)
	em.damping_min = 3.0
	em.damping_max = 4.0
	em.scale_min = 0.9
	em.scale_max = 1.6
	em.scale_curve = _curve(0.6, 2.6)
	em.color_ramp = _ramp([[0.0, Color(0.55, 0.54, 0.52, 0.85)], [0.35, Color(0.45, 0.44, 0.43, 0.55)],
		[1.0, Color(0.6, 0.6, 0.6, 0.0)]])
	exhaust.visibility_aabb = AABB(Vector3(-40, -5, -40), Vector3(80, 30, 80))
	add_child(exhaust)
	exhaust.position = _v3(rig.stack)
	for p: Array in rig.cylinder_cocks:
		var c := FireFX._particles(48, 1.1, FireFX._steam_material(), 0.5)
		c.emitting = true
		c.amount_ratio = 0.0
		var cm := c.process_material as ParticleProcessMaterial
		cm.gravity = Vector3(0.0, 0.6, 0.0)
		cm.damping_min = 2.0
		cm.damping_max = 3.0
		cm.scale_curve = _curve(0.5, 2.4)
		cm.color_ramp = _ramp([[0.0, Color(0.95, 0.95, 0.93, 0.8)], [1.0, Color(0.9, 0.9, 0.9, 0.0)]])
		add_child(c)
		c.position = _v3(p)
		cocks.append(c)


static func _ramp(points: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(points.map(func(p: Array) -> float: return p[0]))
	g.colors = PackedColorArray(points.map(func(p: Array) -> Color: return p[1]))
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


static func _curve(a: float, b: float) -> CurveTexture:
	var c := Curve.new()
	c.max_value = maxf(a, b)
	c.add_point(Vector2(0.0, a))
	c.add_point(Vector2(1.0, b))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _headlight() -> void:
	headlight = SpotLight3D.new()
	headlight.light_color = Color(1.0, 0.78, 0.45)
	headlight.light_energy = 0.0
	headlight.spot_range = 45.0
	headlight.spot_angle = 16.0
	headlight.shadow_enabled = false
	add_child(headlight)
	headlight.position = _v3(rig.headlight)
	headlight.rotation_degrees = Vector3(-2.0, 0.0, 0.0)


## The headlight lit (an oil lamp behind a reflector: a warm, narrow, short beam) by night.
func set_night(night: float) -> void:
	headlight.light_energy = 3.0 * night
	headlight.visible = night > 0.01
