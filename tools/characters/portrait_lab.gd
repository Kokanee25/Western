extends SceneTree
## Where a portrait-factory man's look is lost (docs/briefs/portrait-factory.md): his head drawn
## the same way round three times, side by side, orthographic, the people lineup's plain light:
##   plain   - his glb with his own textures on a plain unlit material (what the factory made)
##   lit     - the same, lit (a plain StandardMaterial3D: the light alone)
##   game    - HumanBody wearing him (the game's skin and hair materials), hatless
## and each from the front, three-quarter and side. Writes <out>/<view>.png (the three in a row).
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/characters/portrait_lab.gd -- \
##       --out=DIR --id=bold_cowboy_portrait
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const SIZE := 500
const SPAN := 0.42          # metres the picture covers, as people_lineup.gd --head
const EYE_Y := 1.62
const SPACING := 1.2


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/portrait_lab"
	var id := "bold_cowboy_portrait"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--id="):
			id = a.substr(5)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	# The lineup's light (tools/people_lineup.gd), so "game" here is the lineup's man.
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
	var men := []
	for k in 2:
		var scene: PackedScene = load("res://assets/people/%s.glb" % id)
		var man := scene.instantiate() as Node3D
		w.add_child(man)
		man.position = Vector3((k - 1) * SPACING, 0, 0)
		_dress(man, id, k == 0)
		men.append(man)
	var body_script = load("res://src/bodies/human_body.gd")
	var hb = body_script.new()
	hb.body_model = StringName(id)
	hb.person_id = StringName(id + "_lab")
	hb.rng_seed = 7
	hb.hat_color = Color(0, 0, 0, 0)
	w.add_child(hb)
	hb.global_position = Vector3(SPACING, 0, 0)
	men.append(hb)
	for f in 12:
		await physics_frame
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = SPAN
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	w.add_child(cam)
	cam.current = true
	# Front, three-quarter, side: each man turned the same way, the camera looking down -Z.
	for view in [["front", 0.0], ["three_quarter", 35.0], ["side", 90.0]]:
		for i in men.size():
			var m: Node3D = men[i]
			m.rotation_degrees = Vector3(0, 180.0 + float(view[1]), 0) if i < 2 else Vector3.ZERO
			if i == 2:
				m.face(m.global_position + Vector3(sin(deg_to_rad(float(view[1]))), 0, cos(deg_to_rad(float(view[1])))) * 5.0)
				m.set_pose(&"stand")
				m._apply_pose(0.0, true)
		# Each man on his own: the camera over him, his square of the row.
		var row := Image.create(SIZE * 3, SIZE, false, Image.FORMAT_RGBA8)
		for i in men.size():
			cam.position = Vector3((i - 1) * SPACING, EYE_Y, 8)
			for f in 8:
				await physics_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			row.blit_rect(img, Rect2i(0, 0, SIZE, SIZE), Vector2i(SIZE * i, 0))
		var path := "%s/%s.png" % [out, view[0]]
		row.save_png(path)
		print("wrote ", path)
	quit()


## His meshes on plain materials with his own textures (nearest texels): unlit, or lit.
func _dress(man: Node3D, id: String, unlit: bool) -> void:
	for mi in man.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var shape := String(m.name).trim_prefix("body_")
		var png := "res://assets/people/%s_%s.png" % [id, shape]
		var mat := StandardMaterial3D.new()
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if ResourceLoader.exists(png):
			mat.albedo_texture = load(png)
		else:
			mat.albedo_color = Color(0.72, 0.5, 0.38)
		if unlit:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = mat
