extends SceneTree
## Frames of the player's shove or kick (PlayerShove) as you'd see them, and from the side: the
## player and a man a step in front of him facing him on a plain floor in the noon sun, the move
## made as the key makes it, every `--every` physics frame saved. For the films (ffmpeg) and sheets.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 960x540 --fixed-fps 60 \
##       -s res://experiments/kick_shove/fp_view.gd -- --out=DIR [--move=kick|shove] [--gun] \
##       [--view=fp|side] [--seconds=2.5] [--every=2] [--at=1.0] [--model=ID]
## --gun: the revolver drawn (the shove is one-handed); --at: how far in front he stands (m).

var out := "build/kick_shove/fp"
var move := &"kick"
var view := "fp"
var seconds := 2.5
var every := 2
var at := 1.0
var gun := false
var model := &""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var v := a.get_slice("=", 1)
		if a.begins_with("--out="):
			out = v
		elif a.begins_with("--move="):
			move = StringName(v)
		elif a.begins_with("--view="):
			view = v
		elif a.begins_with("--seconds="):
			seconds = float(v)
		elif a.begins_with("--every="):
			every = int(v)
		elif a.begins_with("--at="):
			at = float(v)
		elif a.begins_with("--model="):
			model = StringName(v)
		elif a == "--gun":
			gun = true
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.62, 0.7, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.environment.ambient_light_energy = 0.6
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	w.add_child(sun)
	var ground := StaticBody3D.new()
	ground.collision_layer = 1  # Layers.WORLD (a -s script can't name the game's classes)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	cs.shape = box
	ground.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.45, 0.34)
	mi.material_override = mat
	ground.add_child(mi)
	ground.position.y = -0.5
	w.add_child(ground)
	var man = load("res://src/bodies/human_body.gd").new()
	if model != &"":
		man.body_model = model
	man.position = Vector3(0, 0, -at)
	man.rotation.y = PI  # facing you
	w.add_child(man)
	var player = load("res://scenes/player.tscn").instantiate()
	w.add_child(player)
	for i in 30:
		await physics_frame
	if gun:
		player.select_weapon(player.revolver())
		for i in 60:
			await physics_frame
	var side: Camera3D
	if view == "side":
		side = Camera3D.new()
		w.add_child(side)
		side.position = Vector3(3.2, 1.3, -at * 0.5)
		side.look_at(Vector3(0, 1.0, -at * 0.5))
		side.fov = 50
		side.current = true
	# The move, as the key makes it: a kick is held past hold_for_kick and let go.
	var hold := 0 if move == &"shove" else int(ceil(player.shove.tuning.hold_for_kick * 60.0)) + 8
	Input.action_press(&"shove")
	var n := int(seconds * 60.0)
	var k := 0
	for i in n:
		if i == maxi(hold, 1):
			Input.action_release(&"shove")
		await physics_frame
		if i % every == 0:
			await process_frame
			root.get_texture().get_image().save_png(out.path_join("%04d.png" % k))
			k += 1
	print("fp_view: %d frames into %s; last: %s" % [k, out, player.shove.last])
	quit()
