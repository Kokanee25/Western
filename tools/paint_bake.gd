extends SceneTree
## Paint him from the painting: painted views of the man (from an image model, or the painting itself
## for its own view) projected onto every piece of him, so his textures carry the painting's detail.
## The set and pose are the character lab's (tools/lab_stage.gd).
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/paint_bake.gd -- guides
##   python3 tools/paint/align.py      (between the two: fits the painted views onto the guides)
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/paint_bake.gd -- bake
##   [--views=shot,front,three_quarter,side,side_left,back]
## guides: for each view, DIR/<id>_<view>_guide.png (him in grey, the table and props darker, on a
##   plain background: what the image model paints over) and _mask.png (where he is, white).
## bake: renders each view's depth, then, for every shape of him (skin, head, coat, hat...) and
##   every painted source (below: the painting itself and the model's paintings, framed as their
##   guides, transparent where they don't show him), a projection of it into the shape's texture
##   space: DIR/raw/<shape>_<source>_col.png (colour where that view saw it) and _w.png (how
##   squarely), plus DIR/raw/shapes.json (each shape's UV rect and size, and the sources).
##   tools/paint/finish.py then combines the views into assets/people/<id>_paint_<shape>.png.

const DIR := "res://assets/people/paint"
const PAINTING := "res://docs/concept/saloon-night.png"
## The shot view is rendered at the painting's size; its guide is the part of it that is him: a
## square (800 px of the painting's, hat to the bottom edge), as every guide is, so the image model
## paints it back at the same shape.
const SHOT_SIZE := Vector2i(1672, 941)
const SHOT_CROP := Rect2(105.0 / 1672.0, 141.0 / 941.0, 800.0 / 1672.0, 800.0 / 941.0)
const VIEW_SIZE := Vector2i(1024, 1024)
const DEPTH_FAR := 4.0
## Texels per metre of the raw bakes (finish.py averages them down to the finished blocks).
const RAW_TEXELS_PER_M := 512.0
## Shapes whose UV layout isn't even in metres get a set size: the head's face layout gives the face
## the middle third of it, baked finer than the rest (~900 texels a metre round the head): his eyes
## are drawn finer than the squares (finish.py DETAIL).
const RAW_SIZE := {"head": Vector2i(512, 344)}
const BAKE_LAYER := 1 << 19
const ALL_VIEWS := ["shot", "front", "three_quarter", "side", "side_left", "back",
		"head_front", "head_three_quarter", "head_side", "head_side_left", "head_back", "head_shot"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage = load("res://tools/lab_stage.gd")
	var args := OS.get_cmdline_user_args()
	var mode := "guides" if args.is_empty() else args[0]
	var views: Array = ALL_VIEWS.duplicate()
	for a in args:
		if a.begins_with("--views="):
			views = Array(a.substr(8).split(","))
	root.get_node(^"Settings").autosave = false
	if mode == "bake" and RenderingServer.get_current_rendering_method() != "forward_plus":
		push_error("paint_bake: bake on Forward+ (--rendering-driver vulkan): paint_bake.gdshader counts on its clip space")
		quit(1)
		return
	var out := ProjectSettings.globalize_path(DIR)
	DirAccess.make_dir_recursive_absolute(out + "/raw")
	var vp := SubViewport.new()
	vp.size = SHOT_SIZE
	root.add_child(vp)
	var set: Dictionary = stage.build(vp, stage.default_energy())
	var man = set.man
	var cam: Camera3D = set.camera
	cam.cull_mask &= ~BAKE_LAYER
	for i in 90:
		await physics_frame
	# Hold him still (no breathing) so every view and every bake sees the same pose.
	man.process_mode = Node.PROCESS_MODE_DISABLED
	var pid := String(man.body_model)
	var frames := {}
	for view: String in views:
		print("view ", view)
		_frame(stage, set, vp, view)
		frames[view] = {"view_proj": cam.get_camera_projection() * Projection(cam.get_camera_transform().affine_inverse()),
				"cam_pos": cam.global_position, "crop": SHOT_CROP if view == "shot" else Rect2(0, 0, 1, 1)}
		if mode == "guides":
			for kind in ["guide", "mask"]:
				var g: Image
				if kind == "guide":
					g = await _guide(stage, set, vp)
				else:
					g = await _mask(stage, set, vp)
				if view == "shot":
					g = g.get_region(_crop_px(SHOT_CROP, SHOT_SIZE))
				g.save_png("%s/%s_%s_%s.png" % [out, pid, view, kind])
			print("guide ", view)
	if mode == "guides":
		quit()
		return
	# Depth maps for every view (what each one really saw).
	var depths := {}
	for view: String in views:
		_frame(stage, set, vp, view)
		depths[view] = ImageTexture.create_from_image(await _depth(stage, set, vp))
	# What's painted, from where: source -> [image, the view it was painted from]. The painting's view
	# takes the painting itself where it shows him (DIR/<id>_shot_painting.png, tools/paint/align.py)
	# and the model's painting of that view (shot_model) for the rest of him; the other views, the
	# model's paintings fitted onto their guides (_aligned.png; the raw _painted.png if not aligned).
	var painted := {}
	for view: String in views:
		var sources := {view: ["aligned", "painted"]}
		if view == "shot":
			sources = {"shot": ["painting"], "shot_model": ["aligned", "painted"]}
		for source: String in sources:
			for kind: String in sources[source]:
				var path := "%s/%s_%s_%s.png" % [out, pid, view, kind]
				if FileAccess.file_exists(path):
					var img := Image.load_from_file(path)
					img.convert(Image.FORMAT_RGBA8)
					painted[source] = [ImageTexture.create_from_image(img), view]
					break
	if painted.is_empty():
		push_error("paint_bake: no painted views in %s" % out)
		quit(1)
		return
	await _bake(man, vp, frames, depths, painted, out)
	quit()


## Frame a view. Round him, only he is there (the table and chair would hide his legs and back
## from the painter and the bake); in the painting's view, the whole set.
func _frame(stage, set: Dictionary, vp: SubViewport, view: String) -> void:
	vp.size = SHOT_SIZE if view == "shot" else VIEW_SIZE
	stage.aim(set, view)
	var man: Node = set.man
	for gi: GeometryInstance3D in set.world.find_children("*", "GeometryInstance3D", true, false):
		if not man.is_ancestor_of(gi) and not (gi.layers & BAKE_LAYER):
			gi.visible = view == "shot"


func _crop_px(r: Rect2, size: Vector2i) -> Rect2i:
	return Rect2i(roundi(r.position.x * size.x), roundi(r.position.y * size.y), roundi(r.size.x * size.x), roundi(r.size.y * size.y))


## Everything with a stand-in material for one render; returns what to put back.
func _override(root_node: Node, pick: Callable) -> Dictionary:
	var saved := {}
	for gi: GeometryInstance3D in root_node.find_children("*", "GeometryInstance3D", true, false):
		if gi.layers & BAKE_LAYER:
			continue
		saved[gi] = gi.material_override
		gi.material_override = pick.call(gi)
	return saved


func _restore(saved: Dictionary) -> void:
	for gi: GeometryInstance3D in saved:
		if is_instance_valid(gi):
			gi.material_override = saved[gi]


## Him in plain grey clay under one soft light from over the camera (both sides of every face drawn:
## open shells like his hair and brim face either way), his table and props darker,
## on a light grey ground: shapes the image model can read and paint over, keeping the outline.
func _guide(stage, set: Dictionary, vp: SubViewport) -> Image:
	var clay := StandardMaterial3D.new()
	clay.cull_mode = BaseMaterial3D.CULL_DISABLED
	clay.albedo_color = Color(0.62, 0.62, 0.62)
	clay.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.cull_mode = BaseMaterial3D.CULL_DISABLED
	dark.albedo_color = Color(0.3, 0.3, 0.3)
	dark.roughness = 1.0
	var man: Node = set.man
	var saved := _override(set.world, func(gi): return clay if man.is_ancestor_of(gi) else dark)
	var cam: Camera3D = set.camera
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.86, 0.86, 0.86)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	cam.environment = env
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.8
	set.world.add_child(sun)
	sun.global_basis = cam.global_basis * Basis(Vector3.RIGHT, deg_to_rad(-35.0))
	var hidden := _lights_off(set.world, sun)
	var img: Image = await stage.grab(self, vp)
	for l in hidden:
		if is_instance_valid(l):
			l.visible = true
	sun.get_parent().remove_child(sun)
	sun.free()
	cam.environment = null
	_restore(saved)
	return img


## Where he is in a view: white on black (the table and props in front of him black too), for
## tools/paint/align.py to fit the painted views onto.
func _mask(stage, set: Dictionary, vp: SubViewport) -> Image:
	var white := StandardMaterial3D.new()
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var black := StandardMaterial3D.new()
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	var man: Node = set.man
	var saved := _override(set.world, func(gi): return white if man.is_ancestor_of(gi) else black)
	var cam: Camera3D = set.camera
	cam.environment = _flat_environment(Color.BLACK)
	var img: Image = await stage.grab(self, vp)
	cam.environment = null
	_restore(saved)
	return img


func _lights_off(w: Node, keep: Light3D) -> Array:
	var out := []
	for l: Light3D in w.find_children("*", "Light3D", true, false):
		if l != keep and l.visible:
			l.visible = false
			out.append(l)
	return out


## Distance from the camera to the nearest surface, per pixel (paint_depth.gdshader's encoding);
## nothing there reads as further than anything.
func _depth(stage, set: Dictionary, vp: SubViewport) -> Image:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://tools/paint/paint_depth.gdshader")
	mat.set_shader_parameter(&"depth_far", DEPTH_FAR)
	var saved := _override(set.world, func(_gi): return mat)
	var cam: Camera3D = set.camera
	cam.environment = _flat_environment(Color.WHITE)
	var img: Image = await stage.grab(self, vp)
	cam.environment = null
	_restore(saved)
	return img


## No grade at all (so colours come back as written): linear, no glow, no fog.
func _flat_environment(bg: Color) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	return env


## Every shape of him into its texture space, once per painted view.
func _bake(man, vp: SubViewport, frames: Dictionary, depths: Dictionary, painted: Dictionary, out: String) -> void:
	var shapes := {}
	for key: String in man.skin_meshes:
		(shapes.get_or_add(key.get_slice("/", 0), []) as Array).append(man.skin_meshes[key])
	var bvp := SubViewport.new()
	bvp.transparent_bg = true
	bvp.world_3d = vp.find_world_3d()
	bvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(bvp)
	var bcam := Camera3D.new()
	bcam.cull_mask = BAKE_LAYER
	bcam.environment = _flat_environment(Color(0, 0, 0, 0))
	bvp.add_child(bcam)
	var chest: Vector3 = (man.parts[&"chest"] as Node3D).global_position
	bcam.global_transform = Transform3D(Basis.IDENTITY, chest + Vector3(0, 0, 3))
	bcam.current = true
	var info := {}
	for shape: String in shapes:
		var pieces: Array = shapes[shape]
		var m := _measure(pieces)
		if m.uv_area <= 0.0:
			continue
		var per_uv := RAW_TEXELS_PER_M * sqrt(m.area / m.uv_area)
		var rect: Rect2 = m.rect
		# Even sizes: finish.py averages 2x2 raw texels into each finished one.
		var size := Vector2i(clampi(ceili(rect.size.x * per_uv / 2.0) * 2, 16, 1024), clampi(ceili(rect.size.y * per_uv / 2.0) * 2, 16, 1024))
		size = RAW_SIZE.get(shape, size)
		info[shape] = {"uv_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "size": [size.x, size.y]}
		if shape == "head":
			info[shape]["eyes"] = _eye_uvs(man, pieces, rect)
		bvp.size = size
		var mat := ShaderMaterial.new()
		mat.shader = load("res://tools/paint/paint_bake.gdshader")
		mat.set_shader_parameter(&"uv_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
		mat.set_shader_parameter(&"depth_far", DEPTH_FAR)
		mat.set_shader_parameter(&"two_sided", man.DOUBLE_SIDED.has(shape))
		var dups := []
		for mi: MeshInstance3D in pieces:
			var d := MeshInstance3D.new()
			d.mesh = mi.mesh
			d.skin = mi.skin
			d.layers = BAKE_LAYER
			d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			d.custom_aabb = AABB(Vector3(-50, -50, -50), Vector3(100, 100, 100))
			d.material_override = mat
			mi.get_parent().add_child(d)
			d.skeleton = mi.skeleton
			dups.append(d)
		for source: String in painted:
			var view: String = painted[source][1]
			var f: Dictionary = frames[view]
			var crop: Rect2 = f.crop
			mat.set_shader_parameter(&"painted", painted[source][0])
			mat.set_shader_parameter(&"depth_map", depths[view])
			mat.set_shader_parameter(&"view_proj", f.view_proj)
			mat.set_shader_parameter(&"cam_pos", f.cam_pos)
			mat.set_shader_parameter(&"crop", Vector4(crop.position.x, crop.position.y, crop.size.x, crop.size.y))
			for pass_mode in [0, 1]:
				mat.set_shader_parameter(&"mode", pass_mode)
				var img: Image = await load("res://tools/lab_stage.gd").grab(self, bvp)
				img.save_png("%s/raw/%s_%s_%s.png" % [out, shape, source, "col" if pass_mode == 0 else "w"])
		for d: Node in dups:
			d.queue_free()
		print("baked ", shape, " ", size)
	var f := FileAccess.open("%s/raw/shapes.json" % out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"person": man.body_model, "shapes": info, "views": painted.keys()}, "\t"))
	f.close()


## Where his eyes are in the head's texture (0..1 of its rect): the UV of the skin just in front of
## each eyeball (finish.py draws them finer than the squares round them).
func _eye_uvs(man, pieces: Array, rect: Rect2) -> Array:
	var out := []
	for id: StringName in [&"eye_r", &"eye_l"]:
		var eye: Dictionary = man.anatomy.structure(id)
		if eye.is_empty():
			continue
		var at: Vector3 = eye.a
		var best := INF
		var uv_at := Vector2.ZERO
		for mi: MeshInstance3D in pieces:
			var arrays: Array = mi.mesh.surface_get_arrays(0)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			if uv.size() != v.size():
				continue
			for i in v.size():
				var d: Vector3 = v[i] - at
				# Nearest, and in front of the eyeball (he faces -z), not behind or beside it.
				var cost := d.length() + maxf(0.0, d.z) * 4.0
				if cost < best:
					best = cost
					uv_at = uv[i]
		out.append([(uv_at.x - rect.position.x) / rect.size.x, (uv_at.y - rect.position.y) / rect.size.y])
	return out


## A shape's UV bounds, its surface area (m², rest pose) and UV area.
func _measure(pieces: Array) -> Dictionary:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var area := 0.0
	var uv_area := 0.0
	for mi: MeshInstance3D in pieces:
		var arrays: Array = mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if uv.size() != v.size():
			continue
		for t in uv:
			lo = lo.min(t)
			hi = hi.max(t)
		var n := idx.size() if not idx.is_empty() else v.size()
		for k in range(0, n - 2, 3):
			var a := idx[k] if not idx.is_empty() else k
			var b := idx[k + 1] if not idx.is_empty() else k + 1
			var c := idx[k + 2] if not idx.is_empty() else k + 2
			area += (v[b] - v[a]).cross(v[c] - v[a]).length() * 0.5
			var e1 := uv[b] - uv[a]
			var e2 := uv[c] - uv[a]
			uv_area += absf(e1.x * e2.y - e1.y * e2.x) * 0.5
	return {"rect": Rect2(lo, hi - lo), "area": area, "uv_area": uv_area}
