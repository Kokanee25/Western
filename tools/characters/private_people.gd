extends SceneTree
## A private man in the game (#889): a MetaHuman the Character Studio laid into the git-ignored
## `assets/people/private/` (its tools/metahuman_to_game.sh), and each of his lighter levels, built
## by the game's own HumanBody as any man is (his anatomy, DeformRig, ragdoll and hitboxes on the
## 17), and counted: the triangles and vertices drawn (the meshes visible once his pieces are
## merged), the meshes and the skeleton's bones, how long he took to build, any shape the game
## gave the plain skin (a texture missing). Each level once with a hat, the re-dressed repeat.
##   godot --headless -s res://tools/characters/private_people.gd -- --model=private/<build> --out=FILE
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

var model := ""
var out := "/tmp/private_people.json"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--model="):
			model = a.substr(8)
		elif a.begins_with("--out="):
			out = a.substr(6)
	var pb = load("res://src/bodies/people_bodies.gd")
	var levels: Array = (pb.report(StringName(model)).get("game", {}) as Dictionary).get("levels", [model])
	var w := Node3D.new()
	root.add_child(w)
	var ground := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	w.add_child(ground)
	var res := {"model": model, "levels": []}
	var ok_all := true
	for lv: String in levels:
		for hat in [false, true]:
			var row := {"model": lv, "hat": hat, "ok": true}
			if not pb.has_model(StringName(lv)):
				row.ok = false
				row.why = "no model"
				res.levels.append(row)
				ok_all = false
				continue
			var t0 := Time.get_ticks_usec()
			var m = load("res://src/bodies/human_body.gd").new()
			m.body_model = StringName(lv)
			m.person_id = StringName("%s_check%d" % [lv.get_file(), int(hat)])
			m.rng_seed = 11
			m.has_gun = false
			m.hat_color = Color(0.28, 0.22, 0.16) if hat else Color(0, 0, 0, 0)
			m.bandana_color = Color(0, 0, 0, 0)
			w.add_child(m)
			m.global_position = Vector3.ZERO
			row.build_ms = (Time.get_ticks_usec() - t0) / 1000.0
			for f in 4:
				await physics_frame
			var tris := 0
			var verts := 0
			var meshes := 0
			var shapes := {}
			for mi: MeshInstance3D in m.skeleton.find_children("*", "MeshInstance3D", false, false):
				if not mi.visible or mi.mesh == null:
					continue
				meshes += 1
				for s in mi.mesh.get_surface_count():
					var arr := mi.mesh.surface_get_arrays(s)
					verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
					tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			for key: String in m.skin_meshes:
				shapes[key.get_slice("/", 0)] = true
			row.triangles = tris
			row.vertices = verts
			row.meshes = meshes
			row.shapes = shapes.keys()
			row.bones = m.skeleton.get_bone_count()
			row.hitboxes = m.parts.size()
			# Every shape drawn with his own texture (none fell back to the plain skin).
			var plain := []
			for key: String in m.skin_meshes:
				var mat = (m.skin_meshes[key] as MeshInstance3D).material_override
				var tex = mat.get_shader_parameter(&"albedo_tex") if mat is ShaderMaterial else null
				var shape := key.get_slice("/", 0)
				if shape.begins_with("hat"):
					continue
				if tex == null or not String(tex.resource_path).contains("private/"):
					if not shape in plain:
						plain.append(shape)
			row.plain_shapes = plain
			if not plain.is_empty():
				row.ok = false
				row.why = "drawn without his texture: %s" % ", ".join(plain)
			if hat and not shapes.has("hat"):
				row.ok = false
				row.why = "no hat"
			if row.hitboxes < 17:
				row.ok = false
				row.why = "%d hitboxes" % row.hitboxes
			ok_all = ok_all and row.ok
			res.levels.append(row)
			m.queue_free()
			await process_frame
	res.ok = ok_all
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	f.close()
	print(JSON.stringify(res))
	quit(0 if ok_all else 1)
