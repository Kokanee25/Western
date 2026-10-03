class_name DynamiteStick
extends RigidBody3D
## A stick of dynamite loose in the world: thrown, dropped or set against a wall. Lit, its fuse
## burns down (you can see it shorten, spitting sparks) and then it goes off (Blast.detonate).
## A bullet through it may set it off; a blast close by will; so will a fire it's lying in (the
## fuse catches). Small loose thing: on the debris layer.

const LENGTH := 0.2
const RADIUS := 0.0145
const FUSE_LENGTH := 0.07

signal went_off

var lit := false
var fuse_left := 5.0
## Kilograms of TNT it's worth (one stick; a bundle is more).
var kg := 0.15
## Who threw or dropped it (for the record).
var owner_node: Node

var _fuse: Node3D
var _sparks: GPUParticles3D
var _hiss: AudioStreamPlayer3D
var _done := false
var _fire_check := 0.0
var _rng := RandomNumberGenerator.new()


static func make(parent: Node, at: Vector3, velocity := Vector3.ZERO, fuse := -1.0) -> DynamiteStick:
	var s := DynamiteStick.new()
	var bt := Blast.t()
	s.kg = bt.tnt_per_stick
	s.fuse_left = bt.fuse_seconds if fuse < 0.0 else fuse
	parent.add_child(s)
	s.global_position = at
	s.linear_velocity = velocity
	return s


func _ready() -> void:
	name = "Dynamite"
	add_to_group(&"dynamite")
	mass = 0.23
	collision_layer = Layers.DEBRIS
	collision_mask = Layers.DEBRIS_MASK
	continuous_cd = true
	# Paper on dirt: it skids and rolls a little, then stops (a round stick would roll on for
	# ever otherwise).
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	pm.rough = true
	pm.bounce = 0.1
	physics_material_override = pm
	linear_damp = 0.4
	angular_damp = 4.0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = RADIUS
	cyl.height = LENGTH
	shape.shape = cyl
	shape.rotation_degrees.x = 90.0
	add_child(shape)
	var parts := build_model(self)
	_fuse = parts.fuse
	_sparks = parts.sparks
	_hiss = AudioStreamPlayer3D.new()
	_hiss.stream = SynthSounds.get_sound(&"fuse")
	_hiss.unit_size = 3.0
	_hiss.volume_db = -8.0
	add_child(_hiss)
	_rng.seed = hash(get_path())
	if lit:
		light()


## The stick (red paper, lying along Z) with its fuse out of one end and the sparks at its tip.
static func build_model(parent: Node3D, spark_scale := 1.0) -> Dictionary:
	var paper := GunParts.material("dynamite_paper", PixelArt.skin("dynamite_paper", Color(0.62, 0.12, 0.08), 131), 0.0, 0.8)
	var ends := GunParts.material("dynamite_ends", PixelArt.skin("dynamite_ends", Color(0.78, 0.68, 0.5), 133), 0.0, 0.9)
	GunParts.tube(parent, "Paper", RADIUS, LENGTH - 0.01, Vector3.ZERO, paper, 10)
	GunParts.tube(parent, "EndA", RADIUS * 0.96, 0.005, Vector3(0, 0, LENGTH * 0.5 - 0.0025), ends, 10)
	GunParts.tube(parent, "EndB", RADIUS * 0.96, 0.005, Vector3(0, 0, -LENGTH * 0.5 + 0.0025), ends, 10)
	var fuse := GunParts.pivot(parent, "Fuse", Vector3(0, 0, -LENGTH * 0.5))
	var cord := GunParts.material("fuse_cord", PixelArt.skin("fuse_cord", Color(0.2, 0.17, 0.12), 135), 0.0, 1.0)
	GunParts.tube(fuse, "Cord", 0.0025, FUSE_LENGTH, Vector3(0, 0, -FUSE_LENGTH * 0.5), cord, 5)
	var sparks := GPUParticles3D.new()
	sparks.name = "Sparks"
	sparks.amount = 24
	sparks.lifetime = 0.35
	sparks.emitting = false
	sparks.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 70.0
	pm.initial_velocity_min = 0.6 * spark_scale
	pm.initial_velocity_max = 1.6 * spark_scale
	pm.gravity = Vector3(0, -3.0, 0) * spark_scale
	pm.color = Color(1.0, 0.75, 0.3)
	sparks.process_material = pm
	var dot := BoxMesh.new()
	dot.size = Vector3.ONE * 0.006 * maxf(spark_scale, 0.4)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.8, 0.35)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.6, 0.2)
	glow.emission_energy_multiplier = 3.0
	dot.material = glow
	sparks.draw_pass_1 = dot
	fuse.add_child(sparks)
	sparks.position = Vector3(0, 0, -FUSE_LENGTH)
	return {"fuse": fuse, "sparks": sparks}


## How much of the fuse is left to see (1 full .. 0 burnt to the paper), for a fuse of `full` s.
static func show_fuse(fuse: Node3D, sparks: GPUParticles3D, left: float, full: float, burning: bool) -> void:
	var k := clampf(left / maxf(full, 0.01), 0.02, 1.0)
	fuse.scale = Vector3(1.0, 1.0, k)
	sparks.emitting = burning
	# The sparks sit at the burning end (the fuse is scaled, so undo it for them).
	sparks.scale = Vector3(1.0, 1.0, 1.0 / k)


func light() -> void:
	lit = true
	if _sparks:
		_sparks.emitting = true
	if _hiss and not _hiss.playing and is_inside_tree():
		_hiss.play()


## A bullet through it: usually it just tears the paper; sometimes it goes.
func shot(impulse_vec: Vector3) -> void:
	apply_central_impulse(impulse_vec * 0.3)
	if _rng.randf() < Blast.t().bullet_detonation_chance:
		detonate.call_deferred()


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"dynamite", t)


func _physics_step(delta: float) -> void:
	if _done:
		return
	if lit:
		fuse_left -= delta
		show_fuse(_fuse, _sparks, fuse_left, Blast.t().fuse_seconds, true)
		if fuse_left <= 0.0:
			detonate()
			return
	else:
		_fire_check -= delta
		if _fire_check <= 0.0:
			_fire_check = 0.5
			_catch_from_fire()


## Lying in a fire, the fuse catches.
func _catch_from_fire() -> void:
	var fire := FireSystem.find(get_tree())
	if fire == null:
		return
	for m in fire.burning_members():
		if is_instance_valid(m) and Blast._nearest_on(m, global_position).distance_to(global_position) < 0.3:
			light()
			return


func detonate() -> void:
	if _done or not is_inside_tree():
		return
	_done = true
	var world := get_parent() as Node3D
	var at := global_position
	went_off.emit()
	queue_free()
	Blast.detonate(world, at, kg, null)
