class_name BucketViewmodel
extends WeaponViewmodel
## A wooden water bucket in your right hand (4), for putting fires out (DESIGN.md: water puts it
## out). Sits under the camera beside the guns.
##
## Controls: reload (R) at a trough dips it and fills it; fire (LMB) swings and throws the water
## where you're looking (fire with it empty at a trough fills it too). The water flies as a spray
## of drops on their own arcs; where each lands it's handed to the fire's rules
## (`FireSystem.douse`), so a bucket thrown well puts out the boards it drenches and leaves them wet.

const HIP_POS := Vector3(0.24, -0.42, -0.42)
const HIP_ROT := Vector3(0.0, -15.0, 0.0)
const SWING_POS := Vector3(0.1, -0.2, -0.6)
const SWING_ROT := Vector3(-55.0, -5.0, 0.0)
const DIP_POS := Vector3(0.12, -0.75, -0.55)
const DIP_ROT := Vector3(25.0, -10.0, 0.0)
const PUT_AWAY_POS := Vector3(0.25, -0.9, 0.0)

## A bucket holds this much water (litres), takes this long to fill, and is swung this long.
const CAPACITY := 10.0
const FILL_TIME := 1.2
const SWING_TIME := 0.3
## How near (m, from your eyes) a trough's water must be to dip the bucket in.
const REACH := 1.9
## The water leaves as this many drops, at this speed (m/s) with this lift, spread over a cone
## this wide and this high (degrees); each drop douses this far round where it lands (m).
const DROPS := 24
const THROW_SPEED := 6.5
const THROW_LIFT := 1.6
const SPREAD_ACROSS := 14.0
const SPREAD_UP := 7.0
const SPLASH_RADIUS := 0.4
## A drop's flight is followed in steps of this long (s), for at most this long.
const STEP := 0.05
const FLIGHT := 1.2

signal thrown_water(landed: Array, put_out: int)

var litres := 0.0
## Seconds left filling it (0 when not), and of the swing before the water leaves.
var filling := 0.0
var swinging := 0.0

var bucket: Node3D
var _water: MeshInstance3D
var _rng_throw := RandomNumberGenerator.new()


func _ready() -> void:
	armed = false  # nobody's afraid of a man with a bucket
	_rng_throw.seed = 1882
	_build()
	_setup_common()
	_pose_pos = HIP_POS
	_pose_rot = HIP_ROT
	_muzzle_local = HIP_POS
	_add_sound(&"splash")
	_add_sound(&"fill")
	_apply_pose(_draw)


func _build() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.held_cloth("coat", Color(0.36, 0.25, 0.16))
	var wood := GunParts.material("bucket_wood", PixelArt.skin("bucket_wood", Color(0.46, 0.34, 0.21), 151), 0.0, 0.9)
	var iron := GunParts.blued()
	bucket = GunParts.pivot(self, "Bucket", Vector3.ZERO)
	# Staves (a tapered tub), two iron hoops, a bail handle up to your fist.
	var tub := MeshInstance3D.new()
	tub.name = "Tub"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.14
	cyl.bottom_radius = 0.115
	cyl.height = 0.27
	cyl.radial_segments = 12
	cyl.rings = 1
	tub.mesh = cyl
	tub.material_override = wood
	tub.position = Vector3(0, -0.2, 0)
	bucket.add_child(tub)
	for y in [-0.29, -0.12]:
		GunParts.tube(bucket, "Hoop", 0.137 if y > -0.2 else 0.123, 0.018, Vector3(0, y, 0), iron, 12, Vector3.ZERO)
	GunParts.box(bucket, "BailLeft", Vector3(0.006, 0.12, 0.006), Vector3(-0.13, -0.03, 0), iron, Vector3(0, 0, -25))
	GunParts.box(bucket, "BailRight", Vector3(0.006, 0.12, 0.006), Vector3(0.13, -0.03, 0), iron, Vector3(0, 0, 25))
	GunParts.box(bucket, "BailTop", Vector3(0.2, 0.008, 0.008), Vector3(0, 0.025, 0), iron)
	_water = GunParts.tube(bucket, "Water", 0.132, 0.006, Vector3(0, -0.1, 0), WoodMaterials.water(), 12, Vector3.ZERO)
	# A fist round the bail, forearm going back and down.
	var hand := GunParts.pivot(self, "Hand", Vector3(0, 0.035, 0))
	GunParts.box(hand, "Fist", Vector3(0.05, 0.05, 0.07), Vector3(0, 0, 0), skin)
	var arm := GunParts.pivot(hand, "Forearm", Vector3(0.0, 0.02, 0.03))
	arm.rotation_degrees = Vector3(55.0, 20.0, 0.0)
	GunParts.box(arm, "Sleeve", Vector3(0.07, 0.07, 0.28), Vector3(0, 0, 0.16), sleeve)


func _process(delta: float) -> void:
	if _can_act():
		_read_controls()
	_tick(delta)
	_animate(delta)


func _read_controls() -> void:
	if hands_busy or arm_disabled:
		filling = 0.0
		return
	if Input.is_action_just_pressed(&"holster"):
		drawn = not drawn
	if not drawn or _draw < 0.9 or filling > 0.0 or swinging > 0.0:
		return
	if Input.is_action_just_pressed(&"reload"):
		fill()
	elif Input.is_action_just_pressed(&"fire") and _action_ok(&"fire"):
		if litres > 0.0:
			throw()
		else:
			fill()


## Dip it in the nearest trough, if one's within reach (it takes a moment).
func fill() -> bool:
	if litres >= CAPACITY or filling > 0.0:
		return false
	if water_in_reach() == null:
		_tell("No water to fill it from here.")
		return false
	filling = FILL_TIME
	_play(&"fill")
	return true


## Swing it: the water leaves at the end of the swing.
func throw() -> void:
	if litres <= 0.0 or swinging > 0.0:
		return
	swinging = SWING_TIME


## A trough whose water is within reach of your eyes, or null.
func water_in_reach() -> Node3D:
	var eye := _eye()
	for t: Node in get_tree().get_nodes_in_group(&"water_source"):
		var w := t.get_node_or_null(^"Water") as Node3D
		if w == null:
			continue
		# The water's surface as a box: the trough's inside, a little deep.
		var size := Vector3(t.get(&"length"), 0.0, t.get(&"trough_width"))
		var local := w.to_local(eye)
		var nearest := Vector3(clampf(local.x, -size.x * 0.5, size.x * 0.5), clampf(local.y, -0.3, 0.0), clampf(local.z, -size.z * 0.5, size.z * 0.5))
		if w.to_global(nearest).distance_to(eye) <= REACH:
			return t as Node3D
	return null


func _tick(delta: float) -> void:
	if filling > 0.0:
		filling -= delta
		if filling <= 0.0:
			filling = 0.0
			litres = CAPACITY
	if swinging > 0.0:
		swinging -= delta
		if swinging <= 0.0:
			swinging = 0.0
			_let_go()


## The water leaves the bucket: drops fly on their own arcs from in front of you; each lands on
## whatever it meets first (a wall, a man, the ground) and the fire is told how much fell there.
func _let_go() -> Dictionary:
	var cam := get_parent() as Node3D
	var basis := cam.global_transform.basis if cam else global_transform.basis
	var eye := _eye()
	var fwd := -basis.z
	var from := eye + fwd * 0.45 - basis.y * 0.25
	var space := get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	if _player:
		exclude.append(_player.get_rid())
		# Out from in front of your face, never from inside a wall you're up against.
		var q := PhysicsRayQueryParameters3D.create(eye, from, Layers.WORLD)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			from = hit.position + (eye - (hit.position as Vector3)).normalized() * 0.05
	var each := litres / DROPS
	var landed: Array[Vector3] = []
	var fire := FireSystem.find(get_tree())
	var put_out := 0
	for i in DROPS:
		var dir := fwd.rotated(basis.y, deg_to_rad(_rng_throw.randf_range(-SPREAD_ACROSS, SPREAD_ACROSS)))
		dir = dir.rotated(basis.x, deg_to_rad(_rng_throw.randf_range(-SPREAD_UP, SPREAD_UP)))
		var v := dir * THROW_SPEED * _rng_throw.randf_range(0.8, 1.1) + Vector3.UP * THROW_LIFT
		if _player:
			v += _player.velocity
		var at := _fly(space, from, v, exclude)
		if at == Vector3.INF:
			continue
		landed.append(at)
		if fire:
			put_out += fire.douse(at, SPLASH_RADIUS, each)
	_spray(from, fwd * THROW_SPEED + Vector3.UP * THROW_LIFT)
	_play(&"splash")
	litres = 0.0
	Events.noise.emit(eye, 10.0, &"splash", _player)
	thrown_water.emit(landed, put_out)
	return {"landed": landed, "put_out": put_out}


## Where a drop leaving `from` at `v` comes down (Vector3.INF if it doesn't within FLIGHT).
static func _fly(space: PhysicsDirectSpaceState3D, from: Vector3, v: Vector3, exclude: Array[RID]) -> Vector3:
	var p := from
	var t := 0.0
	while t < FLIGHT:
		var next := p + v * STEP + Vector3.DOWN * 4.9 * STEP * STEP
		v += Vector3.DOWN * 9.8 * STEP
		var q := PhysicsRayQueryParameters3D.create(p, next, Layers.WORLD | Layers.PEOPLE)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			return hit.position
		p = next
		t += STEP
	return Vector3.INF


## The water seen going: a burst of drops on the throw's arc.
func _spray(from: Vector3, v: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.amount = 90
	p.lifetime = 0.9
	p.one_shot = true
	p.explosiveness = 0.75
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6, -4, -6), Vector3(12, 8, 12))
	var pm := ParticleProcessMaterial.new()
	pm.direction = v.normalized()
	pm.spread = SPREAD_ACROSS
	pm.initial_velocity_min = v.length() * 0.75
	pm.initial_velocity_max = v.length() * 1.05
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pm.color = Color(0.75, 0.82, 0.85, 0.7)
	p.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.04
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = mat
	p.draw_pass_1 = quad
	var world: Node = _player.get_parent() if _player else get_tree().current_scene
	world.add_child(p)
	p.global_position = from
	p.emitting = true
	p.finished.connect(p.queue_free)


func _eye() -> Vector3:
	var cam := get_parent() as Node3D
	return cam.global_position if cam else global_position


func _tell(text: String) -> void:
	if _player and _player.wounds:
		_player.wounds.say(text, 2.0)


func put_away() -> void:
	filling = 0.0
	drawn = false


func take_out() -> void:
	drawn = true


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / 0.4)
	visible = _draw > 0.02
	var target_pos := HIP_POS
	var target_rot := HIP_ROT
	if filling > 0.0:
		target_pos = DIP_POS
		target_rot = DIP_ROT
	elif swinging > 0.0:
		target_pos = SWING_POS
		target_rot = SWING_ROT
	var k := 1.0 - exp(-delta * (18.0 if swinging > 0.0 else 9.0))
	_pose_pos = _pose_pos.lerp(target_pos, k)
	_pose_rot = _pose_rot.lerp(target_rot, k)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * 10.0))
	_apply_pose(_draw)
	_water.visible = litres > 0.0 or filling < FILL_TIME * 0.5 and filling > 0.0
	_animate_camera(delta, _base_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	position = PUT_AWAY_POS.lerp(_pose_pos.lerp(Vector3(0.18, -0.4, -0.2), t), drawn_amount)
	rotation_degrees = _pose_rot
