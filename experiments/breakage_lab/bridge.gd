extends BridgeLab
## The breakage lab's dev bridge commands (README.md beside this file). One scenario a game: the
## street keeps what the last one broke, so run.py starts a fresh game for each.

const Runner := preload("res://experiments/breakage_lab/runner.gd")

const HELP := {
	"breakage": "breakage SCENARIO [seed=N] [body=ID] [seconds=S] [out=DIR] [shots] [frames=T,T...] [novoxels] -> one breakage scenario in this street (it clears the town first): what broke and where, pieces, how far, what caught, faults, frame time; all of it in DIR/summary.json",
	"breakage_list": "breakage_list -> the breakage lab's scenarios and the bodies it uses",
	"breakage_aim": "breakage_aim TARGET [DISTANCE] [near=X,Y,Z] -> for 16 headings round a target, what the shooter's line meets first (picking a clear line for scenarios.json; near= tries another point, building space)",
	"dig": "dig X Z RADIUS DEPTH -> take a bowl out of the ground there (Ground.take): the earth taken (m³) and the ground's height at the middle",
	"ground": "ground X Z -> the ground's height there (Ground.height_at)",
}


func _cmd_dig(a: Array) -> Dictionary:
	var g := Ground.of(get_tree())
	if g == null or a.size() < 4:
		return {"ok": false, "error": "dig X Z RADIUS DEPTH (and a Ground in the street)"}
	var at := Vector3(float(a[0]), 0.0, float(a[1]))
	var m3 := g.take(at, float(a[2]), float(a[3]))
	return {"taken_m3": snappedf(m3, 0.0001), "height": snappedf(g.height_at(at.x, at.z), 0.001)}


func _cmd_ground(a: Array) -> Dictionary:
	var g := Ground.of(get_tree())
	if g == null or a.size() < 2:
		return {"ok": false, "error": "ground X Z"}
	return {"height": snappedf(g.height_at(float(a[0]), float(a[1])), 0.001)}


func _cmd_breakage(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "breakage SCENARIO [seed=N] [body=ID] [seconds=S] [out=DIR] [shots]"}
	var d := Runner.data()
	var r: Node = Runner.new()
	r.name = "BreakageRunner"
	r.lab = self
	r.scenario = String(a[0])
	r.seed_value = int(d.get("seed", 1))
	r.body = StringName((d.bodies as Array)[0])
	r.seconds = float(d.get("seconds", 8.0))
	for w: String in a.slice(1):
		var kv := w.split("=", true, 1)
		match kv[0]:
			"seed": r.seed_value = int(kv[1])
			"body": r.body = StringName(kv[1])
			"seconds": r.seconds = float(kv[1])
			"out": r.out_dir = kv[1]
			"shots": r.shots = true
			"novoxels": r.no_voxels = true
			"frames":
				r.sequence = Array(kv[1].split(",")).map(func(x: String) -> float: return float(x))
				r.shots = true
	if r.out_dir == "":
		r.out_dir = "build/breakage_lab/bridge/%s_%s_s%d" % [r.scenario, r.body, r.seed_value]
	if not r.out_dir.is_absolute_path():
		r.out_dir = ProjectSettings.globalize_path("res://").path_join(r.out_dir)
	# Its CSVs and PNGs aren't the project's to import (they'd be taken for translations).
	DirAccess.make_dir_recursive_absolute(r.out_dir.get_base_dir())
	if not FileAccess.file_exists(r.out_dir.get_base_dir().path_join(".gdignore")):
		FileAccess.open(r.out_dir.get_base_dir().path_join(".gdignore"), FileAccess.WRITE).close()
	add_child(r)
	var out: Dictionary = await r.run()
	r.queue_free()
	if not out.get("ok", true):
		return out
	var short := {"summary": r.out_dir.path_join("summary.json"), "target": out.target_result.result,
			"broken": out.broken.count, "pieces": out.pieces.count, "largest": out.pieces.largest,
			"max_m": out.pieces.max_m, "caught": out.fire.caught_count, "event_frame_ms": out.frame.event_frame_ms,
			"flags": out.flags.size(), "errors": out.errors.size()}
	if not out.men.is_empty():
		short["men"] = out.men.map(func(m: Dictionary) -> Dictionary:
				return {"role": m.role, "body": m.body, "down": m.get("knocked_down", false), "alive": m.get("alive"),
						"peak_part_mps": m.get("peak_part_mps"), "settle_s": m.get("settle_s")})
	log_event("breakage", "%s: %s, %d broken, %d pieces" % [r.scenario, short.target, short.broken, short.pieces])
	return short


func _cmd_breakage_list(_a: Array) -> Dictionary:
	var d := Runner.data()
	return {"scenarios": Runner.names(), "bodies": d.bodies, "seconds": d.seconds, "seed": d.seed}


func _cmd_breakage_aim(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "breakage_aim TARGET [DISTANCE]"}
	var d := Runner.data()
	if not (d.targets as Dictionary).has(a[0]):
		return {"ok": false, "error": "no target %s: %s" % [a[0], ", ".join((d.targets as Dictionary).keys())]}
	var r: Node = Runner.new()
	r.lab = self
	r._spec = (d.targets[a[0]] as Dictionary).duplicate(true)
	var dist := 5.0
	for w: String in a.slice(1):
		if w.begins_with("near="):
			r._spec.find["near"] = Array(w.substr(5).split(",")).map(func(x: String) -> float: return float(x))
		else:
			dist = float(w)
	r._street = street as Node3D
	add_child(r)
	r._building = street.get_node_or_null(NodePath(String(r._spec.building)))
	r._target = r._find_target(r._building, r._spec.find)
	if r._target == null:
		r.queue_free()
		return {"ok": false, "error": "no target found"}
	r._target_kind = "member" if r._target is StructureMember else "prop"
	r._aim = r._target_point()
	var lines := []
	var inv := (r._building as Node3D).global_basis.inverse()
	for i in 16:
		var ang := TAU * i / 16.0
		var h := Vector3(sin(ang), 0.0, cos(ang))
		var c: Dictionary = r._line_check(r._aim + h * dist)
		var local: Vector3 = inv * h
		lines.append({"from_local": [snappedf(local.x, 0.01), 0.0, snappedf(local.z, 0.01)], "clear": c.clear, "first_hit": c.first_hit})
	r.queue_free()
	return {"target": r._describe(r._target), "aim": arr(r._aim), "lines": lines}
