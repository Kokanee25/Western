extends Node3D
## A scripted scene (Sean, 2026-10-21): a man sits back in a chair (the prop kit's, KitProp.sit,
## pose sit_back); another kicks out its back legs and he goes over backwards with it; then the
## kicker draws, walks over and shoots him in the head where he lies.
##
## What's real and what's scripted:
## - **Real: the kick** (since 2026-10-24). From his right side the kicker kicks low at the chair's
##   near back leg (HumanBody.kick): his boot meets it and KitProp.take_blow decides; it breaks it
##   and goes on through into the far one. Till then the legs were broken by script.
## - **Real: the fall.** The chair's own balance and the ragdoll take him over backwards.
## - **Real: the shot.** A .45 ball through Ballistics into his head: the anatomy and wounds decide.

var out_dir := "build/scene"
var _world: Node3D
var _chair: KitProp
var _sitter: HumanBody
var _kicker: HumanBody
var _ballistics: Ballistics
var _views: Array[SubViewport] = []
var _tick := 0
var _head_at := Vector3.ZERO
var _stand_at := Vector3.ZERO
var _fired := false

const SECONDS := 10.5
const SIZE := Vector2i(640, 360)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	_world = Node3D.new()
	add_child(_world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.4, 0.34)
	mi.material_override = mat
	ground.add_child(mi)
	ground.position.y = -0.5
	_world.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	_world.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.64, 0.66)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 0.6
	env.environment = e
	_world.add_child(env)
	_ballistics = Ballistics.new()
	_world.add_child(_ballistics)
	# The chair, turned to face -z, its seat point over the origin where he sits.
	_chair = PropLibrary.spawn(&"chair") as KitProp
	_world.add_child(_chair)
	_chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var sp := _chair.seat_position()
	_chair.global_position -= Vector3(sp.x, 0.0, sp.z)
	_sitter = _man(&"old_rancher_s1", Vector3.ZERO, 0.0, false)
	_sitter.set_pose(&"sit_back")
	# The kicker at his right, out of the way of his fall, facing the chair's near back leg.
	_kicker = _man(&"bold_cowboy_s0", Vector3(1.5, 0.0, 0.2), 0.0, true)
	# Two cameras, side by side in the video: from his right (the kick and the fall in profile), and
	# a three-quarter view from his left front.
	for at: Array in [[Vector3(3.2, 1.25, -0.2), Vector3(0.35, 0.55, 0.6)], [Vector3(-3.0, 1.55, -1.2), Vector3(0.0, 0.55, 0.45)]]:
		var view := SubViewport.new()
		view.size = SIZE
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(view)
		var cam := Camera3D.new()
		cam.fov = 45.0
		view.add_child(cam)
		cam.look_at_from_position(at[0], at[1], Vector3.UP)
		cam.current = true
		_views.append(view)


var _kick_at := Vector3.ZERO


func _near_leg() -> Vector3:
	var m := _chair.get_member(StringName("%s/post_back_l" % _chair.structure_id))
	return Vector3(m.global_position.x, 0.07, m.global_position.z)


func _man(model: StringName, at: Vector3, yaw: float, armed: bool) -> HumanBody:
	var m := HumanBody.new()
	m.body_model = model
	m.has_gun = armed
	m.start_holstered = true
	m.person_id = StringName(String(model))
	_world.add_child(m)
	m.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	return m


func _physics_process(delta: float) -> void:
	var t := _tick / 60.0
	if _tick == 30:
		_chair.sit(_sitter)
		# Stood where his leg reaches the near back leg (the chair's left: it faces his way).
		_kick_at = _near_leg()
		_kicker.global_position = _kicker.kick_spot(_kick_at, _kicker.global_position)
		_kicker.face(_kick_at)
	# The kick: low into the near back leg, through it into the far one.
	if _tick == 90:
		_kicker.kick(_kick_at, &"front")
	# He lets him lie a moment, then draws and walks over to stand beside his head.
	if _tick == 200:
		_kicker.draw_gun()
	if _tick == 240:
		var head := _sitter.parts[&"head"] as Node3D
		_head_at = head.global_position
		_stand_at = _head_at + Vector3(1.25, 0.0, 0.55)
		_stand_at.y = 0.0
	if _tick > 240 and _tick < 400:
		_kicker.walk_to(_stand_at, 1.1, delta)
	if _tick == 400:
		_kicker.set_pose(&"aim")
	if _tick >= 400 and not _fired:
		_head_at = (_sitter.parts[&"head"] as Node3D).global_position
		_kicker.face(_head_at)
	# He fires as the outlaws do (OutlawBrain._fire_at): from the revolver's muzzle, its smoke and flash.
	if _tick == 470 and not _fired:
		_fired = true
		var gun := _kicker.held_gun as RevolverModel
		var muzzle := gun.muzzle.global_position
		var dir := (_head_at - muzzle).normalized()
		var t_rev: RevolverTuning = load("res://config/revolver.tres")
		var own: Array[RID] = []
		for p: Variant in _kicker.parts.values():
			own.append((p as CollisionObject3D).get_rid())
		var ball := _ballistics.fire(muzzle, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter, own)
		ball.form = t_rev.form_factor
		ball.shooter = _kicker
		GunSmoke.spawn(_world, muzzle, dir)
		ImpactEffects.muzzle_flash(_world, muzzle)
	if _tick % 2 == 0:
		_save()
	_tick += 1
	if t > SECONDS:
		var f := FileAccess.open(out_dir.path_join("scene.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify({"sitter_alive": _sitter.physiology.alive, "cause": String(_sitter.physiology.cause_of_death),
				"sitter_limp": _sitter.limp}))
		get_tree().quit()


func _save() -> void:
	var n := _tick / 2
	await RenderingServer.frame_post_draw
	var both := Image.create(SIZE.x * _views.size(), SIZE.y, false, Image.FORMAT_RGB8)
	for i in _views.size():
		var img := _views[i].get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		both.blit_rect(img, Rect2i(Vector2i.ZERO, SIZE), Vector2i(SIZE.x * i, 0))
	both.save_png(out_dir.path_join("%04d.png" % n))
