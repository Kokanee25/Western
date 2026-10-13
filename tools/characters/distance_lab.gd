extends SceneTree
## How big a face really is in play: each man stood in front of the player's camera (75 degrees,
## 1280x720, eye height 1.6 m, scenes/player.tscn) at a few distances, the people lineup's plain
## light, hatted as the game dresses him; the pixels round his head saved exactly as rendered
## (no scaling): <out>/<id>_<metres>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/distance_lab.gd -- \
##       --out=DIR --ids=bold_cowboy_portrait,stranger2s [--distances=1.2,3,6] [--turns=0,-35,-90]
## --turns: degrees he's turned from facing you (negative: toward the picture's left), each written
## as <id>_<metres>_<turn>.png.
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const FOV := 75.0
const EYE := 1.6


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/distance_lab"
	var ids := ["bold_cowboy_portrait", "stranger2s"]
	var distances := [1.2, 3.0, 6.0]
	var turns := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--ids="):
			ids = Array(a.substr(6).split(","))
		elif a.begins_with("--turns="):
			turns = Array(a.substr(8).split(",")).map(func(x: String) -> float: return float(x))
		elif a.begins_with("--distances="):
			distances = Array(a.substr(12).split(",")).map(func(x: String) -> float: return float(x))
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.5, 0.52)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.72, 0.68)
	e.ambient_light_energy = 0.7
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	w.add_child(sun)
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	var cam := Camera3D.new()
	cam.fov = FOV
	w.add_child(cam)
	cam.current = true
	cam.position = Vector3(0, EYE, 0)
	var body_script = load("res://src/bodies/human_body.gd")
	for id in ids:
		var m = body_script.new()
		m.body_model = StringName(id)
		m.person_id = StringName(String(id) + "_distance")
		m.rng_seed = 7
		w.add_child(m)
		for job in _jobs(distances, turns):
			var d: float = job[0]
			var turn: float = job[1]
			m.global_position = Vector3(0, 0, -d)
			var dir := Vector3(sin(deg_to_rad(turn)), 0, cos(deg_to_rad(turn)))
			m.face(m.global_position + dir * 5.0)
			m.set_pose(&"stand")
			m._apply_pose(0.0, true)
			cam.look_at(Vector3(0, EYE, -d))
			for f in 10:
				await physics_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			# His head and shoulders: a box 0.6 m tall round his eyes, in screen pixels.
			var top := cam.unproject_position(Vector3(0, 1.95, -d))
			var bottom := cam.unproject_position(Vector3(0, 1.35, -d))
			var h := int(bottom.y - top.y)
			var rect := Rect2i(int(top.x - h * 0.5), int(top.y), h, h)
			rect = rect.intersection(Rect2i(Vector2i.ZERO, vp.size))
			var path := "%s/%s_%s.png" % [out, id, str(d)] if turns.is_empty() else "%s/%s_%s_%d.png" % [out, id, str(d), int(turn)]
			img.get_region(rect).save_png(path)
			print("wrote ", path, " ", rect.size)
		m.queue_free()
		await physics_frame
	quit()


## Every distance, each at every turn (or facing you when there are none).
func _jobs(distances: Array, turns: Array) -> Array:
	var out := []
	for d in distances:
		for t in (turns if not turns.is_empty() else [0.0]):
			out.append([float(d), float(t)])
	return out
