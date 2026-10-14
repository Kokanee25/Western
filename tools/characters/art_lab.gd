extends SceneTree
## The character art test scene (docs/briefs/character-art-convergence.md): one man, framed as his
## style portraits are (head and shoulders, a long lens), turned as each portrait is, in neutral
## light or a warm interior made to the portraits, with the game's own material on his head or
## the painted experiment; each saved whole: <out>/<material>_<light>_<turn>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- \
##       --out=DIR [--id=bold_cowboy_rodin] [--turns=0,-45,-80,80] [--lights=neutral,warm]
##       [--materials=game,painted] [--texture=PATH.png] [--hat=game|none] [--look=k:v,...]
## --texture: his head's texture for the painted material (a PNG on disk, read as is, nearest).
## --look: the painted material's values over PAINTED (the skin shader's painted mode,
## src/bodies/shaders/body_skin.gdshaderinc: used, not changed).
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const SIZE := Vector2i(1280, 720)
const FOV := 21.0          # head and shoulders filling the frame from DIST, as the portraits do
const DIST := 1.7
const EYE := 1.66
## The painted experiment on his head (the shader's painted mode): the painted light carries him
## (self_lit), the scene's lamps add a share (paint_gain), never past paint_limit × painted,
## wrapped round him (paint_wrap), in light_steps steps, a little ambient (paint_ambient).
const PAINTED := {"self_lit": 0.55, "paint_gain": 1.2, "paint_wrap": 0.4, "paint_limit": 1.35,
		"light_steps": 3.0, "paint_ambient": 0.25, "square_texels": 1.0}
## The portraits' felt (sampled from the bold cowboy's front portrait).
const HAT := Color(0.36, 0.22, 0.13)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/art_lab"
	var id := "bold_cowboy_rodin"
	var turns := [-45.0]
	var lights := ["neutral", "warm"]
	var materials := ["game", "painted"]
	var texture_path := ""
	var hat := "game"
	var look := PAINTED.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--turns="):
			turns = Array(a.substr(8).split(",")).map(func(x: String) -> float: return float(x))
		elif a.begins_with("--lights="):
			lights = Array(a.substr(9).split(","))
		elif a.begins_with("--materials="):
			materials = Array(a.substr(12).split(","))
		elif a.begins_with("--texture="):
			texture_path = a.substr(10)
		elif a.begins_with("--hat="):
			hat = a.substr(6)
		elif a.begins_with("--look="):
			for kv in a.substr(7).split(","):
				var p := kv.split(":")
				if p.size() == 2:
					look[p[0]] = float(p[1])
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env_node.environment = env
	w.add_child(env_node)
	var cam := Camera3D.new()
	cam.fov = FOV
	w.add_child(cam)
	cam.current = true
	var tex: Texture2D = null
	if texture_path != "":
		var img := Image.load_from_file(texture_path)
		if img != null:
			tex = ImageTexture.create_from_image(img)
	var body_script = load("res://src/bodies/human_body.gd")
	var m = body_script.new()
	m.body_model = StringName(id)
	m.person_id = StringName(id + "_artlab")
	m.rng_seed = 7
	m.hat_color = HAT if hat == "game" else Color(0, 0, 0, 0)
	w.add_child(m)
	m.global_position = Vector3.ZERO
	cam.position = Vector3(0, EYE, -DIST)
	cam.look_at(Vector3(0, EYE - 0.05, 0))
	var rig := []
	for light in lights:
		for n in rig:
			n.queue_free()
		rig = _light(w, env, light)
		for mat in materials:
			_set_material(m, mat, tex, look)
			for turn in turns:
				# Turned as the portrait is: negative toward the picture's left.
				var dir := Vector3(sin(deg_to_rad(-turn)), 0, -cos(deg_to_rad(-turn)))
				m.face(m.global_position + dir * 5.0)
				m.set_pose(&"stand")
				m._apply_pose(0.0, true)
				for f in 8:
					await physics_frame
				await RenderingServer.frame_post_draw
				var path := "%s/%s_%s_%d.png" % [out, mat, light, int(turn)]
				vp.get_texture().get_image().save_png(path)
				print("wrote ", path)
	quit()


## The light: "neutral", the people lineup's (a grey ground, a sun and soft ambient); "warm", the
## portraits' (a warm lamp in front of him and to his right, a dim warm fill on the other side, a
## dark brown ground, little ambient).
func _light(w: Node3D, env: Environment, kind: String) -> Array:
	var nodes := []
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if kind == "warm":
		env.background_color = Color(0.11, 0.05, 0.025)
		env.ambient_light_color = Color(0.5, 0.34, 0.22)
		env.ambient_light_energy = 0.22
		var key := OmniLight3D.new()
		w.add_child(key)
		key.position = Vector3(0.55, EYE + 0.35, -0.8)      # his right (+X, facing -Z), in front, above
		key.light_color = Color(1.0, 0.72, 0.42)
		key.light_energy = 2.4
		key.omni_range = 4.0
		key.shadow_enabled = true
		var fill := OmniLight3D.new()
		w.add_child(fill)
		fill.position = Vector3(-0.9, EYE, -0.6)
		fill.light_color = Color(0.6, 0.42, 0.3)
		fill.light_energy = 0.3
		fill.omni_range = 4.0
		nodes = [key, fill]
	else:
		env.background_color = Color(0.5, 0.5, 0.52)
		env.ambient_light_color = Color(0.75, 0.72, 0.68)
		env.ambient_light_energy = 0.7
		var sun := DirectionalLight3D.new()
		w.add_child(sun)
		sun.rotation_degrees = Vector3(-35, 25, 0)
		sun.light_energy = 1.1
		sun.shadow_enabled = true
		nodes = [sun]
	return nodes


## His head's material: "game", as the game builds it; "painted", the painted mode with `look`
## (and `tex` for its texture, if given). Only the head's pieces (Head_*) are changed.
func _set_material(m: Node, kind: String, tex: Texture2D, look: Dictionary) -> void:
	for mi in _meshes(m):
		if not String(mi.name).begins_with("Head_"):
			continue
		var sm := mi.material_override as ShaderMaterial
		if sm == null:
			continue
		if not mi.has_meta("game_material"):
			mi.set_meta("game_material", sm.duplicate())
		var base: ShaderMaterial = mi.get_meta("game_material")
		if kind == "game":
			mi.material_override = base
			continue
		var p := base.duplicate() as ShaderMaterial
		p.set_shader_parameter(&"uv_rect", Vector4(0, 0, 1, 1))
		for k in look:
			p.set_shader_parameter(StringName(k), look[k])
		if tex != null:
			p.set_shader_parameter(&"albedo_tex", tex)
		mi.material_override = p


func _meshes(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out += _meshes(c)
	return out
