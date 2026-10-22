extends Node
## The gun lab's quick views, the work (views.gd launches it once the game's autoloads are up).

const STATES := {
	"revolver": ["rest", "aim", "cocked", "reload_open", "reload_eject", "reload_insert", "look_down", "detail_left", "detail_right", "detail_below", "detail_cocked"],
	"shotgun": ["rest", "aim", "cocked", "open", "pulled", "loaded", "look_down", "detail_left", "detail_right", "detail_below", "detail_open"],
}
## The detail views: a camera 0.45 m off the gun (in its own space: from its left, right, below).
const DETAIL := {"left": Vector3(-0.42, 0.06, -0.08), "right": Vector3(0.42, 0.06, -0.08), "below": Vector3(0.12, -0.4, -0.12)}

var _detail: Camera3D

var _player: Player


func _arg(name: String, default := "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return default


func run() -> void:
	var out := _arg("out", "build/gun_lab/views")
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	var world := Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.68, 0.74)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.62, 0.6, 0.58)
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 150, 0)  # low behind the right shoulder, as the town's 16:00
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.shadow_enabled = true
	world.add_child(sun)
	var floor := StaticBody3D.new()
	floor.collision_layer = Layers.WORLD
	var fs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 0.2, 60)
	fs.shape = box
	fs.position.y = -0.1
	floor.add_child(fs)
	var fm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	fm.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.6, 0.45)
	fm.material_override = mat
	floor.add_child(fm)
	world.add_child(floor)
	_player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	world.add_child(_player)
	for i in 10:
		await get_tree().process_frame
	_player.camera.make_current()
	var guns := ["revolver", "shotgun"] if _arg("gun") == "" else [_arg("gun")]
	var only := _arg("only").split(",", false)
	for g: String in guns:
		var w: WeaponViewmodel = _player.revolver() if g == "revolver" else _player.shotgun()
		w.needs_captured_mouse = false
		_player.select_weapon(w)
		w.take_out()
		for i in 80:
			await get_tree().process_frame
		for st: String in STATES[g]:
			if not only.is_empty() and not only.has(st):
				continue
			await _state(w, st)
			if st.begins_with("detail"):
				_detail_cam(w, st)
				_print_hand(w)
				await _frames(2)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [g, st]))
			_player.camera.make_current()
			await _reset(w)
	get_tree().quit()


## A camera looking at the gun from DETAIL's side (its model's space), narrow, its own light on.
func _detail_cam(w: WeaponViewmodel, st: String) -> void:
	if _detail == null:
		_detail = Camera3D.new()
		_detail.fov = 40.0
		_detail.near = 0.02
		_detail.cull_mask = _player.camera.cull_mask
		add_child(_detail)
	var side := "left"
	for k: String in DETAIL:
		if st.contains(k):
			side = k
	var gun: Node3D = w.get(&"model")
	var at := gun.global_transform * Vector3(0.0, -0.02, -0.04)
	_detail.global_position = gun.global_transform * DETAIL[side]
	_detail.look_at(at, gun.global_basis.y if side != "below" else -gun.global_basis.z)
	_detail.make_current()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _reset(w: WeaponViewmodel) -> void:
	Input.action_release(&"aim")
	_player.rotation = Vector3.ZERO
	_player.add_look(Vector2(0.0, -_player.get_pitch_degrees()))
	if w is RevolverViewmodel:
		var r := (w as RevolverViewmodel).state
		r.gate_open = false
		r.hammer = RevolverState.Hammer.DOWN
		r.chambers.fill(RevolverState.Chamber.LOADED)
		r.busy = 0.0
	else:
		var s := (w as ShotgunViewmodel).state
		s.open = false
		s.barrels.assign([ShotgunState.Barrel.LOADED, ShotgunState.Barrel.LOADED])
		s.cocked_hammers.assign([false, false])
		s.busy = 0.0
	await _frames(30)


func _state(w: WeaponViewmodel, st: String) -> void:
	match st:
		"rest":
			await _frames(30)
		"aim":
			Input.action_press(&"aim")
			await _frames(60)
		"look_down":
			w.put_away()
			await _frames(60)
			_player.add_look(Vector2(0.0, -60.0 - _player.get_pitch_degrees()))
			await _frames(10)
			w.take_out()
		"cocked", "detail_cocked":
			w.call(&"cock_press")
			await _frames(6)
		"detail_open":
			_spend(w)
			w.call(&"reload_press")
			await _frames(30)
		"reload_open", "open":
			_spend(w)
			w.call(&"reload_press")
			await _frames(30)
		"reload_eject", "pulled":
			_spend(w)
			w.call(&"reload_press")
			await _until_free(w)
			w.call(&"reload_press")
			await _frames(8)
		"reload_insert", "loaded":
			_spend(w)
			for i in 2:
				w.call(&"reload_press")
				await _until_free(w)
			w.call(&"reload_press")
			await _frames(8)


func _spend(w: WeaponViewmodel) -> void:
	if w is RevolverViewmodel:
		(w as RevolverViewmodel).state.chambers.fill(RevolverState.Chamber.SPENT)
	else:
		(w as ShotgunViewmodel).state.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.SPENT])


func _until_free(w: WeaponViewmodel) -> void:
	var st: Object = w.get(&"state")
	var t := 0
	while not st.call(&"ready") and t < 120:
		await get_tree().process_frame
		t += 1


## Where the grip and every bone are, in the gun model's space (cm), for placing a hand.
func _print_hand(w: WeaponViewmodel) -> void:
	var gun: Node3D = w.get(&"model")
	var inv := gun.global_transform.affine_inverse()
	for n in ["Grip/Panels", "Stock/Wrist", "Barrels/Forend"]:
		var mi := gun.get_node_or_null(n) as MeshInstance3D
		if mi:
			var b := mi.get_aabb()
			var lo := Vector3.INF
			var hi := -Vector3.INF
			for i in 8:
				var p := inv * (mi.global_transform * b.get_endpoint(i))
				lo = lo.min(p)
				hi = hi.max(p)
			print("GRIP %s cm: %s .. %s" % [n, (lo * 100).snappedf(0.1), (hi * 100).snappedf(0.1)])
			var half := (mi.mesh as BoxMesh).size * 0.5 if mi.mesh is BoxMesh else Vector3.ZERO
			for c in [Vector3(0, half.y, -half.z), Vector3(0, half.y, half.z), Vector3(0, -half.y, -half.z), Vector3(0, -half.y, half.z)]:
				print("  corner (top/bottom, front/back) %s" % (inv * (mi.global_transform * c) * 100).snappedf(0.1))
	# Any hand with finger pivots (HandModel's, HeldHand's): by what it has, not its class.
	for h in w.find_children("*", "", true, false):
		if not (h is Node3D and h.get(&"fingers") is Dictionary and h.get(&"wrist") is Node3D):
			continue
		var hand := h as Node3D
		var fingers: Dictionary = hand.get(&"fingers")
		for f: String in fingers:
			var line := ""
			for b: Node3D in fingers[f]:
				line += str((inv * b.global_position * 100).snappedf(0.1)) + " "
			print("HAND %s %s: %s" % [hand.name, f, line])
		print("HAND %s wrist %s" % [hand.name, (inv * (hand.get(&"wrist") as Node3D).global_position * 100).snappedf(0.1)])
