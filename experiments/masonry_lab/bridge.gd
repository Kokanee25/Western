extends BridgeLab
## The masonry lab's dev bridge commands (README; docs/briefs/masonry-lab.md). `masonry_lab` builds
## a test piece on an empty slab out of town; `masonry_blast` sets a charge off at it and reports
## what broke, what fell and every frame's time; `masonry_cam` puts a camera on it.

const LAB := preload("res://experiments/masonry_lab/lab.gd")

const HELP := {
	"masonry_lab": "masonry_lab [piece=wall_panel] [seed=N] -> build the piece on the lab's slab (seed: its walls laid again with N): its elements, joints, build ms, where it is",
	"masonry_blast": "masonry_blast [x=2] [y=0.12] [z=-0.12] [sticks=1] [wait=6] [out=PATH] -> (sticks=0: none, the frames alone) a charge at x,y,z of the piece (its space: x along, y up, z in from the face; z<0 in front): what it broke, freed and dropped, the hole, every frame's ms over `wait` s (out: them as JSON)",
	"masonry_cam": "masonry_cam front|back|side|close|high [D] -> a camera on the piece from D m (default 6)",
	"masonry": "masonry -> the piece now: standing, fallen, joints broken, rubble awake",
	"masonry_vis": "masonry_vis [hide] -> what draws under the lab (hide: the piece's batches hidden)",
	"masonry_debug": "masonry_debug -> its batches (vertices, dirty, a job running), some rubble (where, drawn)",
}

var _frames := PackedFloat32Array()
var _sampling := false
var _last_us := 0


func _lab() -> Node3D:
	var lab := street.get_node_or_null(^"MasonryLab") as Node3D
	if lab == null:
		lab = LAB.new()
		lab.name = "MasonryLab"
		street.add_child(lab)
	return lab


func _opts(a: Array) -> Dictionary:
	var o := {}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			o[kv[0]] = kv[1]
		else:
			o[w] = true
	return o


func _cmd_masonry_lab(a: Array) -> Dictionary:
	var o := _opts(a)
	var lab := _lab()
	var u := Time.get_ticks_usec()
	var s: MasonryStructure = lab.build(String(o.get("piece", "wall_panel")), int(o.get("seed", "0")))
	await physics_frames(2)
	var ms := float(Time.get_ticks_usec() - u) / 1000.0
	var rep := s.report()
	rep["build_ms"] = snappedf(ms, 0.1)
	rep["seed"] = lab.seed_used
	rep["piece"] = lab.piece_name
	rep["origin"] = arr(s.global_position)
	rep["middle"] = arr(lab.at(Vector3(2.0, 1.5, 0.275)))
	return rep


func _cmd_masonry_cam(a: Array) -> Dictionary:
	var lab := _lab()
	var view: String = a[0] if a.size() > 0 else "front"
	var d := float(a[1]) if a.size() > 1 else 6.0
	var target: Vector3 = lab.at(Vector3(2.0, 1.2, 0.275))
	var from: Vector3
	match view:
		"back":
			from = lab.at(Vector3(2.6, 1.6, 0.55 + d))
		"side":
			from = lab.at(Vector3(4.0 + d * 0.7, 1.8, -d * 0.7))
		"close":
			from = lab.at(Vector3(2.4, 0.9, -d * 0.45))
			target = lab.at(Vector3(2.0, 0.6, 0.275))
		"high":
			from = lab.at(Vector3(2.0 - d * 0.4, 3.0 + d * 0.5, -d * 0.8))
		_:
			from = lab.at(Vector3(1.4, 1.6, -d))
	return await bridge._cmd_camera([str(from.x), str(from.y), str(from.z), str(target.x), str(target.y), str(target.z)])


func _process(_d: float) -> void:
	if not _sampling:
		return
	var now := Time.get_ticks_usec()
	if _last_us > 0:
		_frames.append(float(now - _last_us) / 1000.0)
	_last_us = now


func _cmd_masonry_blast(a: Array) -> Dictionary:
	var o := _opts(a)
	var lab := _lab()
	var s: MasonryStructure = lab.piece
	if s == null:
		return {"ok": false, "error": "masonry_lab first"}
	var local := Vector3(float(o.get("x", "2")), float(o.get("y", "0.12")), float(o.get("z", "-0.12")))
	var sticks := int(o.get("sticks", "1"))
	var wait := float(o.get("wait", "6"))
	var at: Vector3 = lab.at(local)
	_frames.clear()
	_last_us = 0
	_sampling = true
	await physics_frames(1)
	var t0 := Time.get_ticks_usec()
	var report := Blast.detonate(lab, at, Blast.t().tnt_per_stick * sticks) if sticks > 0 else {"kg": 0.0}
	var blast_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	var freed: Dictionary = s.last_blast.get("freed", {})
	await seconds(wait)
	_sampling = false
	var w := s.wall
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var fell := 0
	var top_course := 0
	for i in w.count():
		if not s.element(i).broken:
			continue
		if not freed.has(i):
			fell += 1
			top_course = maxi(top_course, w.course[i])
		var p := w.at[i]
		var h := w.size[i] * 0.5
		lo = lo.min(Vector2(p.x - h.x, p.y - h.y))
		hi = hi.max(Vector2(p.x + h.x, p.y + h.y))
	var sorted := _frames.duplicate()
	sorted.sort()
	var worst := sorted[-1] if sorted.size() > 0 else 0.0
	var over22 := 0
	for f in _frames:
		if f > 1000.0 / 45.0:
			over22 += 1
	var rep := s.report()
	rep.merge({
		"sticks": sticks, "kg": snappedf(float(report.kg), 0.001), "at": arr(local),
		"freed": freed.size(), "cracked": (s.last_blast.get("cracked", []) as PackedInt32Array).size(),
		"joints_broken_by_blast": (s.last_blast.get("broke", []) as PackedInt32Array).size(),
		"fell_after": fell, "fell_top_course": top_course,
		"hole": {"x": [snappedf(lo.x, 0.01), snappedf(hi.x, 0.01)], "y": [snappedf(lo.y, 0.01), snappedf(hi.y, 0.01)]},
		"blast_call_ms": snappedf(blast_ms, 0.1), "frames": _frames.size(),
		"frame_worst_ms": snappedf(worst, 0.1),
		"frame_p95_ms": snappedf(sorted[int(sorted.size() * 0.95)] if sorted.size() > 0 else 0.0, 0.1),
		"frames_under_45fps": over22, "awake_rubble": _awake(s)})
	if o.has("out"):
		var f := FileAccess.open(String(o.out), FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify({"report": rep, "frames_ms": Array(_frames)}, "\t"))
	return rep


func _awake(s: MasonryStructure) -> int:
	var n := 0
	for rb in s.rubble:
		if is_instance_valid(rb) and not rb.sleeping and not rb.freeze:
			n += 1
	return n


func _cmd_masonry(_a: Array) -> Dictionary:
	var lab := _lab()
	if lab.piece == null:
		return {"ok": false, "error": "masonry_lab first"}
	var rep: Dictionary = lab.piece.report()
	rep["awake_rubble"] = _awake(lab.piece)
	return rep


func _cmd_masonry_debug(_a: Array) -> Dictionary:
	var lab := _lab()
	var s: MasonryStructure = lab.piece
	if s == null:
		return {"ok": false, "error": "masonry_lab first"}
	var verts := 0
	for mi: Node in s._batches.values():
		var m := (mi as MeshInstance3D).mesh
		if m and m.get_surface_count() > 0:
			verts += m.surface_get_array_len(0)
	var rb_out := []
	for rb in s.rubble:
		if is_instance_valid(rb) and rb_out.size() < 4:
			var vis := []
			for c in rb.get_children():
				if c is MeshInstance3D:
					vis.append([(c as MeshInstance3D).visible, (c as MeshInstance3D).is_visible_in_tree()])
			rb_out.append({"at": arr(rb.global_position), "meshes": vis, "in_tree": rb.is_inside_tree(), "kids": rb.get_child_count()})
	return {"batches": s._batches.size(), "verts": verts, "batched": s._batched.size(), "dirty": s._batch_dirty.size(),
		"queued": s._rebuild_queued, "task": s._batch_task, "rubble": s.rubble.size(), "some_rubble": rb_out,
		"deterministic": World.deterministic}


func _cmd_masonry_vis(a: Array) -> Dictionary:
	var lab := _lab()
	var out := []
	var walk := func(n: Node, f: Callable) -> void:
		if n is VisualInstance3D and (n as VisualInstance3D).is_visible_in_tree():
			var vi := n as VisualInstance3D
			out.append([String(lab.get_path_to(n)), n.get_class(), arr(vi.global_transform * vi.get_aabb().get_center()), arr(vi.get_aabb().size)])
		for c in n.get_children(true):
			f.call(c, f)
	walk.call(lab, walk)
	if a.size() > 0 and a[0] == "hide":
		for mi: Node in (lab.piece as MasonryStructure)._batches.values():
			(mi as MeshInstance3D).visible = false
	return {"visual": out.slice(0, 40), "count": out.size()}
