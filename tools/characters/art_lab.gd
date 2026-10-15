extends SceneTree
## The character art test scene (docs/briefs/character-art-convergence.md): one man, framed as his
## style portraits are (head and shoulders, a long lens), turned as each portrait is, in neutral
## light or a warm interior made to the portraits, with the game's own material on his head or
## the painted experiment; each saved whole: <out>/<material>_<light>_<turn>.png.
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/art_lab.gd -- \
##       --out=DIR [--id=bold_cowboy_rodin] [--turns=0,-45,-80,80] [--lights=neutral,warm]
##       [--materials=game,painted] [--texture=PATH.png] [--hat=game|none] [--look=k:v,...]
##       [--fov=75 --dist=1.2] [--global=name:value,...] [--set=k:v,...] [--nomip] [--tag=NAME]
## --fov, --dist: the camera (75 and 1.2: the player's at conversation distance). --global: shader
## globals for the run (min_square_px, tile_light...). --set: values on his head's game material
## too (light_steps...). --nomip: his head's texture without mipmaps (each pixel one texel); --mip:
## with them (the game imports his head without: each screen pixel then one texel of several);
## --mipdir=DIR: with mips read from DIR/level_N.png (made otherwise than by averaging).
## --grade=tonemap|adjust|game: the game's picture grade on the frame (see _grade).
## --aim=Y: the camera level with height Y and looking at it (with --fov 35 --dist 3.4: the whole man).
## --texture: his head's texture for the painted material (a PNG on disk, read as is, nearest).
## --hide=A,B: his meshes whose names begin A or B not drawn. --curl=r:1,l:0.5: his hands curled.
## --draw: his revolver drawn; --sever=index_r,...: those fingers shot off.
## --hat=lab:NAME: the hat prototype (tools/characters/hat_proto.py: assets/people/lab/NAME_*.obj and
## .png) on his head bone in place of the game's, drawn by the skin shader as his clothes are.
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
	var fov := FOV
	var dist := DIST
	var sets := {}
	var nomip := false
	var mip := false
	var mipdir := ""
	var grade := ""
	var aim := -1.0
	var tag := ""
	var hide := PackedStringArray()
	var curl := PackedStringArray()
	var sever := PackedStringArray()
	var draw := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fov="):
			fov = float(a.substr(6))
		elif a.begins_with("--dist="):
			dist = float(a.substr(7))
		elif a == "--nomip":
			nomip = true
		elif a == "--mip":
			mip = true
		elif a.begins_with("--mipdir="):
			mipdir = a.substr(9)
		elif a.begins_with("--grade="):
			grade = a.substr(8)
		elif a.begins_with("--aim="):
			aim = float(a.substr(6))
		elif a.begins_with("--tag="):
			tag = a.substr(6) + "_"
		elif a.begins_with("--global="):
			for kv in a.substr(9).split(","):
				var g := kv.split(":")
				if g.size() == 2:
					RenderingServer.global_shader_parameter_set(StringName(g[0]), float(g[1]))
		elif a.begins_with("--set="):
			for kv in a.substr(6).split(","):
				var q := kv.split(":")
				if q.size() == 2:
					sets[q[0]] = float(q[1])
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
		elif a.begins_with("--hide="):
			hide = a.substr(7).split(",")
		elif a.begins_with("--curl="):
			curl = a.substr(7).split(",")
		elif a.begins_with("--sever="):
			sever = a.substr(8).split(",")
		elif a == "--draw":
			draw = true
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
	_grade(env, grade)
	w.add_child(env_node)
	var cam := Camera3D.new()
	cam.fov = fov
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
	if hat.begins_with("lab:"):
		_wear_lab_hat(m, hat.substr(4))
	# --draw: his revolver in his hand; --sever=index_r,...: those fingers shot off.
	if draw:
		m.draw_gun()
	for fid: String in sever:
		m.sever_finger(StringName(fid), Vector3(1, 0, 0))
	# --curl=r:1,l:0.5: his hands curled (0 open, 1 a fist), after he's built.
	for c: String in curl:
		var kv := c.split(":")
		if kv.size() == 2:
			m.curl_hand(kv[0], float(kv[1]))
	if not hide.is_empty():
		# --hide=Skin,Trousers: his meshes whose names begin so are not drawn (a garment seen
		# without the body under it).
		for mi in _meshes(m):
			for h in hide:
				if String(mi.name).begins_with(h):
					mi.visible = false
		print("art_lab: meshes ", _meshes(m).map(func(x): return "%s%s" % [x.name, "" if x.visible else " (hidden)"]))
	m.global_position = Vector3.ZERO
	# --aim=Y: the camera level with Y and looking at it (0.9: the whole man), else at his eyes.
	var cy := aim if aim >= 0.0 else EYE
	cam.position = Vector3(0, cy, -dist)
	cam.look_at(Vector3(0, cy - (0.0 if aim >= 0.0 else 0.05), 0))
	var rig := []
	for light in lights:
		for n in rig:
			n.queue_free()
		rig = _light(w, env, light)
		for mat in materials:
			_set_material(m, mat, tex, look, sets, nomip, mip, mipdir)
			for turn in turns:
				# Turned as the portrait is: negative toward the picture's left.
				var dir := Vector3(sin(deg_to_rad(-turn)), 0, -cos(deg_to_rad(-turn)))
				m.face(m.global_position + dir * 5.0)
				m.set_pose(&"stand")
				m._apply_pose(0.0, true)
				for f in 8:
					await physics_frame
				await RenderingServer.frame_post_draw
				var path := "%s/%s%s_%s_%d.png" % [out, tag, mat, light, int(turn)]
				vp.get_texture().get_image().save_png(path)
				print("wrote ", path)
	print("art_lab: done")
	quit()


## --grade: the game's picture grade (scenes/test_street.tscn's Environment) or a part of it:
## "tonemap" (ACES), "adjust" (contrast 1.15, saturation 1.12), "game" both.
func _grade(env: Environment, which: String) -> void:
	if which in ["tonemap", "game"]:
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
	if which in ["adjust", "game"]:
		env.adjustment_enabled = true
		env.adjustment_contrast = 1.15
		env.adjustment_saturation = 1.12


## The light: "noon" (high sun, a post's hard shadow across his face), "fire" (a campfire low in
## front, a cold night), "smoke" (neutral light, a bank of powder smoke before his face); "neutral", the people lineup's (a grey ground, a sun and soft ambient); "warm", the
## portraits' (a warm lamp in front of him and to his right, a dim warm fill on the other side, a
## dark brown ground, little ambient).
func _light(w: Node3D, env: Environment, kind: String) -> Array:
	var nodes := []
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.volumetric_fog_enabled = false
	if kind == "noon":
		# Noon sun high and to his right, a post between it and him laying a hard shadow across
		# his face; a pale sky ambient.
		env.background_color = Color(0.62, 0.68, 0.76)
		env.ambient_light_color = Color(0.7, 0.76, 0.85)
		env.ambient_light_energy = 0.45
		var sun := DirectionalLight3D.new()
		w.add_child(sun)
		sun.rotation_degrees = Vector3(-55, 30, 0)
		sun.light_color = Color(1.0, 0.95, 0.86)
		sun.light_energy = 1.6
		sun.shadow_enabled = true
		var post := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, 3.0, 0.08)
		post.mesh = bm
		w.add_child(post)
		post.position = Vector3(0.25, 1.5, 0.35)
		post.layers = 1
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		return [sun, post]
	if kind == "fire":
		# A campfire low in front of him and to his left: orange from below, a cold night round it.
		env.background_color = Color(0.03, 0.035, 0.06)
		env.ambient_light_color = Color(0.25, 0.3, 0.45)
		env.ambient_light_energy = 0.12
		var fire := OmniLight3D.new()
		w.add_child(fire)
		fire.position = Vector3(-0.35, 0.6, -0.7)
		fire.light_color = Color(1.0, 0.55, 0.22)
		fire.light_energy = 3.2
		fire.omni_range = 4.0
		fire.shadow_enabled = true
		return [fire]
	if kind == "smoke":
		# The neutral light with black-powder smoke drifting between him and you (volumetric fog
		# in a box round his head).
		env.background_color = Color(0.5, 0.5, 0.52)
		env.ambient_light_color = Color(0.75, 0.72, 0.68)
		env.ambient_light_energy = 0.7
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0
		env.volumetric_fog_albedo = Color(0.85, 0.84, 0.82)
		var sun2 := DirectionalLight3D.new()
		w.add_child(sun2)
		sun2.rotation_degrees = Vector3(-35, 25, 0)
		sun2.light_energy = 1.1
		sun2.shadow_enabled = true
		var fog := FogVolume.new()
		w.add_child(fog)
		fog.size = Vector3(1.2, 0.6, 0.5)
		fog.position = Vector3(0.1, EYE - 0.05, -0.35)
		var fm := FogMaterial.new()
		fm.density = 2.5
		fm.albedo = Color(0.88, 0.87, 0.85)
		fog.material = fm
		return [sun2, fog]
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
func _set_material(m: Node, kind: String, tex: Texture2D, look: Dictionary, sets: Dictionary = {}, nomip := false, mip := false, mipdir := "") -> void:
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
			var g := base.duplicate() as ShaderMaterial
			for k in sets:
				g.set_shader_parameter(StringName(k), sets[k])
			if mipdir != "":
				g.set_shader_parameter(&"albedo_tex", _mip_chain(mipdir))
			elif nomip or mip:
				var t0 = g.get_shader_parameter(&"albedo_tex")
				if t0 is Texture2D:
					var im: Image = (t0 as Texture2D).get_image()
					if im.is_compressed():
						im.decompress()
					im.clear_mipmaps()
					if mip:
						im.generate_mipmaps()
					g.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(im))
			mi.material_override = g
			continue
		var p := base.duplicate() as ShaderMaterial
		p.set_shader_parameter(&"uv_rect", Vector4(0, 0, 1, 1))
		for k in look:
			p.set_shader_parameter(StringName(k), look[k])
		if tex != null:
			p.set_shader_parameter(&"albedo_tex", tex)
		mi.material_override = p


## A texture from its own mip levels (DIR/level_0.png, level_1.png ... down to 1×1, each RGB8): to
## try mips made otherwise than by averaging.
func _mip_chain(dir: String) -> ImageTexture:
	var data := PackedByteArray()
	var first: Image = null
	var i := 0
	while FileAccess.file_exists("%s/level_%d.png" % [dir, i]):
		var im := Image.load_from_file("%s/level_%d.png" % [dir, i])
		im.convert(Image.FORMAT_RGB8)
		if first == null:
			first = im
		data.append_array(im.get_data())
		i += 1
	var out := Image.create_from_data(first.get_width(), first.get_height(), true, Image.FORMAT_RGB8, data)
	var it := ImageTexture.create_from_image(out)
	print("art_lab: mip chain %d levels, image mipmaps %s (%d), texture's image mipmaps %s" % [i, out.has_mipmaps(), out.get_mipmap_count(), it.get_image().has_mipmaps()])
	return it


## The prototype hat: each piece on his head bone, its body-space vertices put back at his rest
## pose (so it moves with his head), the material the game gives a baked garment.
func _wear_lab_hat(m: Node, hat_name: String) -> void:
	var skel: Skeleton3D = m.skeleton
	var head := skel.find_bone("head")
	var att := BoneAttachment3D.new()
	att.bone_name = "head"
	skel.add_child(att)
	var to_rest := skel.get_bone_global_rest(head).affine_inverse()
	for part in ["hat", "hat_brim", "hat_band"]:
		var mesh: Mesh = load("res://assets/people/lab/%s_%s.obj" % [hat_name, part])
		var tex: Texture2D = load("res://assets/people/lab/%s_%s.png" % [hat_name, part])
		if mesh == null or tex == null:
			push_error("art_lab: no %s %s (run hat_proto.py, then --import)" % [hat_name, part])
			continue
		var base := StandardMaterial3D.new()
		base.albedo_texture = tex
		base.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		base.roughness = 0.95
		var mat: ShaderMaterial = m._piece_material(base, true)
		mat.set_shader_parameter(&"use_custom_pos", false)
		var mi := MeshInstance3D.new()
		mi.name = "LabHat_" + part
		mi.mesh = mesh
		mi.material_override = mat
		mi.transform = to_rest
		att.add_child(mi)


func _meshes(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out += _meshes(c)
	return out
