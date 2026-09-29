extends SceneTree
## Writes assets/people/envelope.json: the body the generated people are fitted to — the bone
## order, each segment's capsules and centre, and BodyMesh's cross-section tables (trunk, neck,
## head, right arm, right leg). tools/blender/make_people.py reads it, so a MakeHuman man comes
## out the same size and shape as the hitboxes and the clothes expect.
##   godot --headless -s res://tools/people_envelope.gd


func _initialize() -> void:
	var a := Anatomy.shared()
	var out := {"bones": [], "segments": {}, "tables": {}}
	for sid in a.segment_order():
		out.bones.append(String(sid))
		var caps := []
		for c: Array in a.segments[sid].capsules:
			caps.append([_v(c[0]), _v(c[1]), c[2]])
		out.segments[String(sid)] = {"center": _v(a.segment_center(sid)), "capsules": caps,
				"parent": String(a.segments[sid].get("parent", ""))}
	var tables := {"TRUNK": BodyMesh.TRUNK, "NECK": BodyMesh.NECK, "ARM": BodyMesh.ARM, "LEG": BodyMesh.LEG}
	for name: String in tables:
		var rows := []
		for r: Array in tables[name]:
			rows.append([_v(r[0]), r[1], r[2], r[3], String(r[4]), String(r[5]), r[6]])
		out.tables[name] = rows
	var head := []
	for r: Array in BodyMesh.HEAD:
		head.append([_v(r[0]), r[1], r[2], r[3]])
	out.tables["HEAD"] = head
	out["head_bottom"] = BodyMesh.HEAD_BOTTOM
	out["head_top"] = BodyMesh.HEAD_TOP
	var f := FileAccess.open("res://assets/people/envelope.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("wrote assets/people/envelope.json")
	quit()


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.0001), snappedf(p.y, 0.0001), snappedf(p.z, 0.0001)]
