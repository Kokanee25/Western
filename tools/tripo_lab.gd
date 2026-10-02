extends SceneTree
## A Tripo man (tools/characters/, assets/people/tripo/<id>.glb) judged in the character lab as he
## comes: loaded at run time (the folder is .gdignore'd), stood where the painting's man sits, in
## the lab's light, the painting's man hidden. Writes <out>/<id>_<view>.png for the shot view and
## the orbit views (tools/lab_stage.gd VIEWS), plus a contact sheet <id>_lab.png:
##   xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/tripo_lab.gd -- --out=DIR [--id=stranger]
##   [--height=1.8] (he's scaled to this tall) [--yaw=90] (turned about his feet: Tripo's man faces
##   +X, ours -Z) [--fill=] (the lab's fill light, to see his dark side) [--size=WxH]
## docs/ART_REVIEW.md §6: judge the first Tripo man in the lab before building the Blender fit.

const GLB := "res://assets/people/tripo/%s.glb"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "/tmp/tripo_lab"
	var id := "stranger"
	var height := 1.8
	var size := Vector2i(1280, 720)
	var yaw := 90.0
	var energy: Dictionary = load("res://tools/lab_stage.gd").default_energy()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--yaw="):
			yaw = float(a.substr(6))
		elif a.begins_with("--fill="):
			energy.fill = float(a.substr(7))
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--height="):
			height = float(a.substr(9))
		elif a.begins_with("--size="):
			var wh := a.substr(7).split("x")
			size = Vector2i(int(wh[0]), int(wh[1]))
	DirAccess.make_dir_recursive_absolute(out)
	var stage = load("res://tools/lab_stage.gd")
	var vp := SubViewport.new()
	vp.size = size
	root.add_child(vp)
	var set: Dictionary = stage.build(vp, energy)
	var man = set.man
	# The glb as Tripo made it: its own rig and textures (colour, normal, ORM), unimported.
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(GLB % id), state)
	if err != OK:
		push_error("couldn't load %s: %s" % [GLB % id, error_string(err)])
		quit(1)
		return
	var scene := doc.generate_scene(state) as Node3D
	scene.name = "Tripo_" + id
	(set.world as Node3D).add_child(scene)
	# His size: scaled so his bounds are `height` tall, stood on the ground at the man's feet,
	# facing as the man faces.
	var aabb := _bounds(scene)
	var s := height / maxf(aabb.size.y, 0.01)
	scene.scale = Vector3.ONE * s
	scene.global_position = (man as Node3D).global_position - Vector3(0, aabb.position.y * s, 0)
	scene.global_basis = ((man as Node3D).global_basis * Basis(Vector3.UP, deg_to_rad(yaw))).scaled(Vector3.ONE * s)
	var tris := 0
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		tris += (mi as MeshInstance3D).mesh.get_faces().size() / 3
		(mi as MeshInstance3D).layers = Layers.VIS_BODY
	print("%s: %d triangles, %.2f m tall before scaling (x%.2f), bones %d" % [id, tris, aabb.size.y, s,
			(scene.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D).get_bone_count()
			if not scene.find_children("*", "Skeleton3D", true, false).is_empty() else 0])
	(man as Node3D).visible = false
	# The orbit views look at the man's chest part; the Tripo man stands, so look at his chest height.
	var shots := {}
	for view in ["shot", "front", "three_quarter", "side", "back"]:
		if view == "shot":
			stage.aim(set, view)
		else:
			_aim_standing(set, scene, view, height)
		var img: Image = await stage.grab(self, vp)
		img.save_png("%s/%s_%s.png" % [out, id, view])
		shots[view] = img
	# A contact sheet: the painting's man beside him, then the orbit views.
	var painting := Image.load_from_file("res://docs/concept/saloon-night.png")
	painting.convert(Image.FORMAT_RGBA8)
	painting.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
	var w := size.x
	var h := size.y
	var sheet := Image.create(w * 3, h * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.12, 0.12, 0.12))
	sheet.blit_rect(shots["shot"], Rect2i(0, 0, w, h), Vector2i(0, 0))
	sheet.blit_rect(painting, Rect2i(0, 0, w, h), Vector2i(w, 0))
	sheet.blit_rect(shots["front"], Rect2i(0, 0, w, h), Vector2i(w * 2, 0))
	sheet.blit_rect(shots["three_quarter"], Rect2i(0, 0, w, h), Vector2i(0, h))
	sheet.blit_rect(shots["side"], Rect2i(0, 0, w, h), Vector2i(w, h))
	sheet.blit_rect(shots["back"], Rect2i(0, 0, w, h), Vector2i(w * 2, h))
	sheet.save_png("%s/%s_lab.png" % [out, id])
	print("wrote %s/%s_lab.png" % [out, id])
	quit()


static func _bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


## The lab's orbit views, aimed at a standing man's chest.
static func _aim_standing(set: Dictionary, scene: Node3D, view: String, height: float) -> void:
	var stage = load("res://tools/lab_stage.gd")
	var cam: Camera3D = set.camera
	var chest := scene.global_position + Vector3.UP * height * 0.72
	var v: Array = stage.VIEWS[view]
	var dir := (-(set.man as Node3D).global_basis.z.normalized() as Vector3).rotated(Vector3.UP, deg_to_rad(v[0]))
	cam.fov = stage.VIEW_FOV
	cam.global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), chest + dir * stage.VIEW_DISTANCE * 1.3 + Vector3.UP * float(v[1]))
