extends SceneTree
## Renders every prop in assets/props/manifest.json (PropLibrary: the .glb, else PropModels' code
## model) in a row on a plain floor in warm lamplight, for checking their shapes:
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/prop_views.gd -- out.png [--close]

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 700)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.09, 0.07)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.45, 0.38, 0.32)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 35, 0)
	sun.light_color = Color(1.0, 0.82, 0.6)
	sun.shadow_enabled = true
	w.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 8)
	floor_mesh.mesh = plane
	floor_mesh.material_override = PixelArt.material(PixelArt.wood("floor", Color(0.42, 0.3, 0.2), 43, 2, 5), Color.WHITE, PixelArt.Mapping.WORLD_TRIPLANAR)
	w.add_child(floor_mesh)
	var wall := MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(20, 3, 0.1)
	wall.mesh = wall_box
	wall.material_override = PixelArt.material(PixelArt.wood("saloon_wall", Color(0.3, 0.17, 0.1), 5), Color.WHITE, PixelArt.Mapping.WORLD_TRIPLANAR)
	wall.position = Vector3(4.0, 1.5, -0.75)
	w.add_child(wall)
	var x := 0.0
	for id in PropLibrary.ids():
		var prop := PropLibrary.spawn(StringName(id))
		w.add_child(prop)
		var size := PropLibrary.size_of(StringName(id))
		if PropLibrary.definition(StringName(id)).get("anchor", "floor") == "wall":
			prop.position = Vector3(x + size.x * 0.5, 1.4, -0.7)
		else:
			prop.position = Vector3(x + size.x * 0.5, 0.0, 0.0)
			prop.rotation_degrees.y = 20.0
		x += size.x + 0.25
	var cam := Camera3D.new()
	w.add_child(cam)
	if args.has("--close"):
		cam.position = Vector3(6.2, 0.7, 1.6)
		cam.look_at(Vector3(6.8, 0.2, 0.0))
		cam.fov = 40
	else:
		cam.position = Vector3(x * 0.5, 1.6, 4.2)
		cam.look_at(Vector3(x * 0.5, 0.6, 0.0))
		cam.fov = 50
	cam.current = true
	for i in 12:
		await process_frame
	vp.get_texture().get_image().save_png(args[0])
	quit()
