extends SceneTree
## A quick look at the library wood (#901): eight floor boards of an entry under one plain sun, the
## use pass's dials set, from 1 m. Renders in about a minute under lavapipe, where the valley takes ten.
##   xvfb-run -a godot --path . --rendering-driver vulkan --resolution 1280x720 -s res://tools/wood_probe.gd -- \
##       [--entry=floor_fir_worn] [--age=1.0] [--use=1.0] [--dings=1.0] [--out=build/wood_probe.png]
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist; a kit
## prop can't be spawned from here.)

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var a := {"entry": "floor_fir_worn", "age": "1.0", "use": "1.0", "dings": "1.0", "out": "build/wood_probe.png"}
	for arg in OS.get_cmdline_user_args():
		var kv := arg.trim_prefix("--").split("=")
		if kv.size() == 2:
			a[kv[0]] = kv[1]
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 30, 0)
	w.add_child(sun)
	var m := ShaderMaterial.new()
	m.shader = load("res://src/render/scan_wood.gdshader")
	MaterialLibrary.apply(m, MaterialLibrary.entry(String(a.entry)), float(a.age), &"floor")
	m.set_shader_parameter("use_wear", float(a.use))
	m.set_shader_parameter("dings", float(a.dings))
	for i in 8:
		var mi := MeshInstance3D.new()
		mi.mesh = PropKit.board_mesh(1.6, 0.13, 0.022, float(i) * 0.137 + 0.05, 0.0, Vector2.ZERO, 0.0, 0.0)
		mi.material_override = m
		mi.transform = Transform3D(Basis(Vector3.RIGHT, Vector3.BACK * -1.0, Vector3.UP), Vector3(-0.8, 0, -0.5 + i * 0.135))
		w.add_child(mi)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.position = Vector3(0, 0.9, 0.6)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	for i in 8:
		await process_frame
	root.get_texture().get_image().save_png(String(a.out))
	print("saved ", a.out)
	quit()
