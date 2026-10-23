extends SceneTree
## Does SoftBody3D work under Jolt in this Godot (4.7.2), and what does it cost? (The barkeep's rag,
## docs/briefs/barkeep-rag.md.) A 40 x 30 cm cloth, pinned at two corners to a node that moves like
## a hand, dropped on a box like a bar top; then N of them; physics frame time against an empty run.
##
##   godot --headless --fixed-fps 60 -s res://experiments/barkeep_rag/softbody_probe.gd -- [--n=1] [--res=6] [--frames=600]

var opts := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var n := int(opts.get("n", "1"))
	var res := int(opts.get("res", "6"))
	var frames := int(opts.get("frames", "600"))
	print("engine: ", ProjectSettings.get_setting("physics/3d/physics_engine"), " godot ", Engine.get_version_info().string)
	var world := Node3D.new()
	root.add_child(world)
	var bar := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 0.1, 0.8)
	cs.shape = box
	bar.add_child(cs)
	bar.position = Vector3(0, 1.0, 0)
	world.add_child(bar)
	var base := await _time(frames)  # nothing but the bar
	var cloths: Array[SoftBody3D] = []
	var verts := PackedVector3Array()
	var hands: Array[Node3D] = []
	for i in n:
		var hand := Node3D.new()
		hand.position = Vector3(-1.2 + 0.25 * i, 1.6, 0)
		world.add_child(hand)
		hands.append(hand)
		var sb := SoftBody3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.4, 0.3)
		pm.subdivide_width = res
		pm.subdivide_depth = maxi(res - 2, 1)
		sb.mesh = pm
		verts = pm.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
		sb.total_mass = 0.05
		sb.simulation_precision = 5
		sb.linear_stiffness = 0.6
		sb.damping_coefficient = 0.05
		sb.position = hand.position + Vector3(0, 0, 0.15)
		sb.rotation_degrees = Vector3(90, 0, 0)  # hanging
		world.add_child(sb)
		cloths.append(sb)
	await physics_frame
	await physics_frame
	# Pin the two top corners to the hand.
	var pinned := 0
	for i in n:
		var sb := cloths[i]
		var top := -INF
		for v in verts:
			top = maxf(top, v.z)
		for k in verts.size():
			if absf(verts[k].z - top) < 1e-4 and absf(absf(verts[k].x) - 0.2) < 1e-4:
				sb.set_point_pinned(k, true, sb.get_path_to(hands[i]))
				pinned += 1
	print("verts per cloth: ", verts.size(), " points: ", cloths[0].get_point_count() if cloths[0].has_method(&"get_point_count") else -1, " pinned: ", pinned)
	# Swing the hands for a while, then lower them over the bar and let go.
	var t0 := Time.get_ticks_usec()
	var worst := 0.0
	var samples: Array[float] = []
	var bad := 0
	for f in frames:
		var s := f / 60.0
		for i in n:
			hands[i].position = Vector3(-1.2 + 0.25 * i + 0.3 * sin(s * 2.0), 1.6 - 0.4 * clampf(s / 5.0, 0.0, 1.0), 0.2 * cos(s * 3.0))
		if f == frames * 3 / 4:
			for i in n:
				_unpin_all(cloths[i], verts.size())
		var a := Time.get_ticks_usec()
		await physics_frame
		var ms := (Time.get_ticks_usec() - a) / 1000.0
		samples.append(ms)
		worst = maxf(worst, ms)
		for i in n:
			var p := cloths[i].get_point_transform(0)
			if not p.is_finite() or p.length() > 50.0:
				bad += 1
	samples.sort()
	var mean := 0.0
	for x in samples:
		mean += x
	mean /= samples.size()
	# Where the cloths ended: on the bar top (y ~1.05), not through it.
	var lows := []
	for sb in cloths:
		var lo := INF
		var hi := -INF
		for k in verts.size():
			var p := sb.get_point_transform(k)
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
		var under := 0
		for k in verts.size():
			var p := sb.get_point_transform(k)
			if p.y < 1.045 and absf(p.x) < 1.5 and absf(p.z) < 0.4:
				under += 1
		lows.append([snappedf(lo, 0.001), snappedf(hi, 0.001), "inside the bar: %d" % under])
	print("frame ms empty: %.3f  with %d cloth(s): mean %.3f median %.3f p95 %.3f worst %.3f  added mean %.3f ms" % [
			base, n, mean, samples[samples.size() / 2], samples[int(samples.size() * 0.95)], worst, mean - base])
	print("non-finite or flung points: ", bad, "  cloth y range at end (bar top 1.05): ", lows)
	quit()


func _unpin_all(sb: SoftBody3D, count: int) -> void:
	for k in count:
		if sb.is_point_pinned(k):
			sb.set_point_pinned(k, false)


func _time(frames: int) -> float:
	var total := 0.0
	for f in frames:
		var a := Time.get_ticks_usec()
		await physics_frame
		total += (Time.get_ticks_usec() - a) / 1000.0
	return total / frames
