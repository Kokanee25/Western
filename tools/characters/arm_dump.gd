extends SceneTree
## A man's skin, weights and bone moves in each pose, for measuring how his skin bends
## (`tools/characters/arm_measure.py`): built as the game builds him (HumanBody), each pose set and
## settled as the works check does, then every skinned piece's rest vertices, bones and weights and
## each pose's moves (bone global pose × the skin's bind, as the GPU skins him) written to DIR.
##   godot --headless --path . -s res://tools/characters/arm_dump.gd -- --id=doctor_s2_talking \
##       --out=DIR [--poses=stand,hands_up] [--share=0.35]
## Writes DIR/<id>/meta.json and, per piece, <key>.v/.b/.w/.i (float32/int32 little-endian raw)
## and <key>.<pose>.m (each bind's 3x4 move, float32). Untyped where it touches game classes.

var out := "/tmp/arm_dump"
var id := "doctor_s2_talking"
var poses := ["stand", "hands_up"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--id="):
			id = a.substr(5)
		elif a.begins_with("--poses="):
			poses = Array(a.substr(8).split(","))
		elif a.begins_with("--share="):
			# PeopleBodies.shoulder_share (0: no shoulder helpers), for a before and after.
			load("res://src/bodies/people_bodies.gd").shoulder_share = float(a.substr(8))
	var dir := out + "/" + id
	DirAccess.make_dir_recursive_absolute(dir)
	var w := Node3D.new()
	root.add_child(w)
	var man = load("res://src/bodies/human_body.gd").new()
	man.body_model = StringName(id)
	man.person_id = StringName(id + "_dump")
	man.rng_seed = 7
	w.add_child(man)
	man.global_position = Vector3.ZERO
	man.face(Vector3(0, 0, 5))
	for f in 12:
		await physics_frame
	var sk: Skeleton3D = man.skeleton
	var meta := {"id": id, "poses": poses, "pieces": {}, "joints": {}}
	for key: String in man.skin_meshes:
		var mi: MeshInstance3D = man.skin_meshes[key]
		var arr := mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var file := key.replace("/", "__")
		_write(dir + "/" + file + ".v", (v as PackedVector3Array).to_byte_array())
		_write(dir + "/" + file + ".b", bones.to_byte_array())
		_write(dir + "/" + file + ".w", (arr[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array).to_byte_array())
		_write(dir + "/" + file + ".i", (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).to_byte_array())
		var names := []
		for b in mi.skin.get_bind_count():
			var bone := mi.skin.get_bind_bone(b)
			names.append(sk.get_bone_name(bone if bone >= 0 else b))
		meta.pieces[key] = {"file": file, "n": v.size(), "per": bones.size() / maxi(v.size(), 1), "binds": names}
	for pose in poses:
		man.set_pose(StringName(pose))
		man._apply_pose(0.0, true)
		for f in 40:
			await physics_frame
		man.set_physics_process(false)
		man.set_process(false)
		man._update_skeleton()
		sk.force_update_all_bone_transforms()
		var joints := {}
		for b in sk.get_bone_count():
			var g := sk.get_bone_global_pose(b)
			joints[sk.get_bone_name(b)] = [g.origin.x, g.origin.y, g.origin.z]
		meta.joints[pose] = joints
		for key: String in man.skin_meshes:
			var mi: MeshInstance3D = man.skin_meshes[key]
			var m := PackedFloat32Array()
			for b in mi.skin.get_bind_count():
				var bone := mi.skin.get_bind_bone(b)
				var t: Transform3D = sk.get_bone_global_pose(bone if bone >= 0 else b) * mi.skin.get_bind_pose(b)
				for r in 3:
					m.append_array([t.basis[0][r], t.basis[1][r], t.basis[2][r], t.origin[r]])
			_write(dir + "/" + String(meta.pieces[key].file) + "." + pose + ".m", m.to_byte_array())
		man.set_physics_process(true)
		man.set_process(true)
	var f := FileAccess.open(dir + "/meta.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, " "))
	f.close()
	print("arm_dump: %s %d pieces" % [id, meta.pieces.size()])
	quit()


func _write(path: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()
