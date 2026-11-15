extends SceneTree
## The cost a tick, ours against Jolt's (#973): in a bare world (a floor), ten of one kind dropped from
## a metre at once, the wall time a frame (headless, --fixed-fps: frames run back to back, so it's all
## the frame's work: our script's tick and Jolt's step) over the first four seconds, against nothing
## dropped; per cloth = the difference / 10. (Performance's physics time lags a second behind: no use.) Kinds: the long glove
## (its mesh from sean_s3_talking's skin, `glove_sean_s3.json`) as GarmentCloth (Jolt) and as our
## SolverCloth (SHAPED, 20 substeps), and a 0.5 m sheet of 16x16 points as the Jolt rag and ours.
## Ours need the native plugin (on a runner: film/request.txt's `@godot` line).
##
##   godot --headless --fixed-fps 60 -s res://experiments/cloth_core/bench.gd -- [--n=10] [--frames=240]
## (Untyped where it names the game's classes: -s scripts compile before the autoloads exist.)

var n := 10
var frames := 240


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.get_slice("=", 1))
		if a.begins_with("--frames="):
			frames = int(a.get_slice("=", 1))
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var g: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/cloth_core/glove_sean_s3.json"))
	var gp := PackedVector3Array()
	for p: Array in g.points:
		gp.append(Vector3(p[0], p[1], p[2]))
	var gt := PackedInt32Array(g.triangles)
	var native := ClassDB.class_exists(&"ClothCore")
	var kinds := ["none", "jolt_glove", "jolt_rag"]
	if native:
		kinds += ["our_glove", "our_sheet"]
	kinds.append("none_again")
	var out := {}
	await _measure(world, "warm", gp, gt)   # (the first run pays for loading)
	for kind: String in kinds:
		out[kind] = await _measure(world, kind, gp, gt)
	var base := (float(out.none.ms) + float(out.none_again.ms)) * 0.5
	var lines := []
	for kind: String in kinds:
		var per := (float(out[kind].ms) - base) / n
		out[kind]["per_cloth_ms"] = snappedf(per, 0.001)
		lines.append("%-11s physics frame %.3f ms, per cloth %.3f ms%s" % [kind, out[kind].ms, per,
				(", own %.3f ms" % out[kind].own) if out[kind].has("own") else ""])
	for l in lines:
		print(l)
	print("BENCH " + JSON.stringify({"n": n, "frames": frames, "native": native, "kinds": out}))
	quit(0)


func _measure(world: Node3D, kind: String, gp: PackedVector3Array, gt: PackedInt32Array) -> Dictionary:
	var SolverClothS = load("res://src/bodies/solver_cloth.gd")
	var GarmentClothS = load("res://src/bodies/garment_cloth.gd")
	var ClothPropS = load("res://src/props/cloth_prop.gd")
	var made: Array = []
	var area := 0.0
	for t in range(0, gt.size(), 3):
		area += 0.5 * (gp[gt[t + 1]] - gp[gt[t]]).cross(gp[gt[t + 2]] - gp[gt[t]]).length()
	for k in (n if kind != "none" and kind != "none_again" else 0):
		var at := Vector3((k % 5) * 0.9 - 1.8, 1.0, (k / 5) * 0.9 - 0.45)
		var c: Node3D = null
		match kind:
			"warm", "jolt_glove":
				c = GarmentClothS.make(_moved(gp, at), gt, PackedVector2Array(), null, 0.035, 12)
			"jolt_rag":
				c = ClothPropS.new()
				c.kit_id = &"bench_rag"
				c.definition = {"size": [0.5, 0.5], "points": [16, 16], "mass": 0.05, "stiffness": 1.0,
						"precision": 12, "damping": 0.06, "grip_radius": 0.03, "catch_seconds": 2.0,
						"burn_seconds": 30.0, "holds_ml": 60.0, "soaks": 0.5}
			"our_glove":
				c = SolverClothS.make(_moved(gp, at), gt, PackedVector2Array(), null, 0.035 / area,
						{"bend_mode": 1, "bend_stiffness": 0.5, "max_strain": 1.05, "substeps": 20})
			"our_sheet":
				var s := _sheet(at)
				c = SolverClothS.make(s[0], s[1], PackedVector2Array(), null, 0.2, {"bend_stiffness": 2e-5})
		if c:
			world.add_child(c)
			if kind == "jolt_rag":
				c.global_transform = Transform3D(Basis(Vector3.RIGHT, 0.6), at)
			made.append(c)
	for f in 3:
		await physics_frame
	var sum := 0.0
	var own := 0.0
	var t0 := Time.get_ticks_usec()
	for f in frames:
		await physics_frame
		var t1 := Time.get_ticks_usec()
		sum += (t1 - t0) / 1000.0
		t0 = t1
		for c in made:
			if c.get("last_millis") != null and not c.resting:
				own += c.last_millis
	for c in made:
		c.queue_free()
	for f in 5:
		await physics_frame
	var r := {"ms": snappedf(sum / frames, 0.001)}
	if kind.begins_with("our"):
		r["own"] = snappedf(own / frames / n, 0.001)
	return r


func _moved(pts: PackedVector3Array, to: Vector3) -> PackedVector3Array:
	var mid := Vector3.ZERO
	for p in pts:
		mid += p
	mid /= maxf(pts.size(), 1)
	var out := PackedVector3Array()
	for p in pts:
		out.append(p - mid + to)
	return out


func _sheet(at: Vector3) -> Array:
	var b := Basis(Vector3.RIGHT, 0.6)
	var pts := PackedVector3Array()
	for r in 16:
		for c in 16:
			pts.append(at + b * Vector3(0.5 * (c / 15.0 - 0.5), 0.0, 0.5 * (r / 15.0 - 0.5)))
	var tris := PackedInt32Array()
	for r in 15:
		for c in 15:
			var i := r * 16 + c
			if (r + c) % 2 == 0:
				tris.append_array([i, i + 1, i + 16, i + 1, i + 17, i + 16])
			else:
				tris.append_array([i, i + 17, i + 16, i, i + 1, i + 17])
	return [pts, tris]
