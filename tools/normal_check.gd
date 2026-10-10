extends SceneTree
## The normal-map convention check, Godot's half (docs/briefs/faces.md, step 1).
##   ~/bpyenv/bin/python tools/blender/normal_check.py          # Blender: the bump, baked
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/normal_check.gd -- [--out=DIR]
## The modelled bump and the flat quad carrying its baked normal map side by side, seen from above,
## lit low from +X, then from -Z (glTF's -Z is Blender's +Y, the normal map's +V). On each, the
## half of the bump facing the light must be the brighter, on the modelled one by geometry and on
## the flat one by its normal map alone. Prints PASS or FAIL per light and quits 1 on a failure.
##
## Other glbs, rendered under the same raking lights (no verdict):
##   ... -- --glb=PATH [--top=0.14] (frame the top share of its bounds: a man's head) [--yaw=DEG]
##   [--flip-green] (the normal maps' green flipped) [--no-normal] (normal maps off) [--name=X]

const DIR := "res://build/normal_check"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "build/normal_check"
	var glb := ""
	var top := 0.0
	var yaw := 0.0
	var flip := false
	var plain := false
	var label := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--glb="):
			glb = a.substr(6)
		elif a.begins_with("--top="):
			top = float(a.substr(6))
		elif a.begins_with("--yaw="):
			yaw = float(a.substr(6))
		elif a == "--flip-green":
			flip = true
		elif a == "--no-normal":
			plain = true
		elif a.begins_with("--name="):
			label = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(768, 384) if glb == "" else Vector2i(640, 640)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.05, 0.05, 0.06)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.12, 0.12, 0.12)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.4
	world.add_child(sun)
	var cam := Camera3D.new()
	world.add_child(cam)
	if glb == "":
		await _bump_check(vp, world, sun, cam, out)
		return
	var scene := _load(glb)
	if scene == null:
		quit(1)
		return
	world.add_child(scene)
	scene.rotation_degrees.y = yaw
	if flip or plain:
		_normal_maps(scene, flip, plain)
	var box := _bounds(scene)
	var frame := box
	if top > 0.0:
		frame.position.y = box.end.y - box.size.y * top
		frame.size.y = box.size.y * top
	var mid := frame.get_center()
	var half := maxf(frame.size.x, frame.size.y) * 0.6
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = half * 2.0
	cam.position = mid + Vector3(0, 0, box.size.z + 2.0)
	cam.look_at(mid, Vector3.UP)
	var name := label if label != "" else glb.get_file().get_basename()
	var tiles: Array[Image] = []
	# Raking light from his right, his left, above and below, seen from in front (+Z).
	for d in [Vector3(1, 0.25, 0.35), Vector3(-1, 0.25, 0.35), Vector3(0, 1, 0.35), Vector3(0, -1, 0.35)]:
		_aim(sun, d)
		tiles.append(await _grab(vp))
	var sheet := Image.create(vp.size.x * 4, vp.size.y, false, Image.FORMAT_RGBA8)
	for i in tiles.size():
		sheet.blit_rect(tiles[i], Rect2i(Vector2i.ZERO, vp.size), Vector2i(vp.size.x * i, 0))
	sheet.save_png("%s/%s_raking.png" % [out, name])
	print("wrote %s/%s_raking.png (light from: right, left, above, below)" % [out, name])
	quit(0)


func _bump_check(vp: SubViewport, world: Node3D, sun: DirectionalLight3D, cam: Camera3D, out: String) -> void:
	var high := _load(DIR + "/bump_high.glb")
	var low := _load(DIR + "/bump.glb")
	if high == null or low == null:
		push_error("run tools/blender/normal_check.py first")
		quit(1)
		return
	world.add_child(high)
	world.add_child(low)
	high.position = Vector3(-0.6, 0, 0)
	low.position = Vector3(0.6, 0, 0)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.2
	cam.position = Vector3(0, 3, 0)
	cam.look_at(Vector3.ZERO, Vector3(0, 0, -1))
	var failed := false
	var sheet := Image.create(vp.size.x, vp.size.y * 2, false, Image.FORMAT_RGBA8)
	var lights := [["+X", Vector3(1, 0.5, 0), Vector2(1, 0)], ["-Z (the map's +V)", Vector3(0, 0.5, -1), Vector2(0, -1)]]
	for li in lights.size():
		var l: Array = lights[li]
		_aim(sun, l[1])
		var img := await _grab(vp)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, vp.size), Vector2i(0, vp.size.y * li))
		for which in [["modelled", -0.6], ["normal-mapped", 0.6]]:
			var lit := _side(img, vp, cam, Vector3(which[1], 0, 0), l[2])
			var dark := _side(img, vp, cam, Vector3(which[1], 0, 0), -l[2])
			var ok: bool = lit > dark + 0.05
			failed = failed or not ok
			print("light from %s, %s bump: the side toward the light %.3f, away %.3f: %s" % [l[0], which[0], lit, dark, "PASS" if ok else "FAIL"])
	sheet.save_png(out + "/bump_check.png")
	print("wrote %s/bump_check.png" % out)
	quit(1 if failed else 0)


## Mean brightness of the bump's half toward `dir` (x, z in the world), around its centre.
func _side(img: Image, vp: SubViewport, cam: Camera3D, centre: Vector3, dir: Vector2) -> float:
	var sum := 0.0
	var n := 0
	for i in 12:
		for j in 12:
			var u := (i + 0.5) / 12.0 * 0.22 + 0.04
			var w := (j - 5.5) / 12.0 * 0.2
			var p := centre + Vector3(dir.x * u - dir.y * w, 0.05, dir.y * u + dir.x * w)
			var s := cam.unproject_position(p)
			var c := img.get_pixel(clampi(int(s.x), 0, vp.size.x - 1), clampi(int(s.y), 0, vp.size.y - 1))
			sum += c.get_luminance()
			n += 1
	return sum / n


func _aim(sun: DirectionalLight3D, toward_light: Vector3) -> void:
	# A DirectionalLight3D shines down its -Z: point -Z away from where the light comes from.
	sun.global_basis = Basis.looking_at(-toward_light.normalized(), Vector3.UP if absf(toward_light.normalized().y) < 0.95 else Vector3.FORWARD)


func _load(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(path), state)
	if err != OK:
		push_error("couldn't load %s: %s" % [path, error_string(err)])
		return null
	return doc.generate_scene(state) as Node3D


func _normal_maps(scene: Node, flip: bool, plain: bool) -> void:
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		for si in mesh.get_surface_count():
			var mat := mesh.surface_get_material(si) as BaseMaterial3D
			if mat == null or not mat.normal_enabled:
				continue
			mat = mat.duplicate()
			if plain:
				mat.normal_enabled = false
			elif flip and mat.normal_texture != null:
				var im := mat.normal_texture.get_image()
				im.decompress()
				im.convert(Image.FORMAT_RGBA8)
				for y in im.get_height():
					for x in im.get_width():
						var c := im.get_pixel(x, y)
						c.g = 1.0 - c.g
						im.set_pixel(x, y, c)
				im.generate_mipmaps()
				mat.normal_texture = ImageTexture.create_from_image(im)
			(mi as MeshInstance3D).set_surface_override_material(si, mat)


func _bounds(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _grab(vp: SubViewport) -> Image:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img
