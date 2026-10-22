extends BridgeLab
## The perception lab's dev bridge commands (README.md beside this file). One group a game: the
## lab clears the town first and leaves its men about, so run.py starts a fresh game for each.

const Runner := preload("res://experiments/perception_lab/runner.gd")

const HELP := {
	"perception": "perception GROUP|CASE [seed=N] [out=DIR] -> a perception group (sight, hearing, search, news, leaks) or one case, in this street (it clears the town first): who saw and heard what, how fast, false and missed against the expectations, anything known that couldn't be; all of it in DIR/summary.json",
	"perception_list": "perception_list -> the perception lab's groups and cases",
	"perception_probe": "perception_probe [X Y Z R] -> windows, doors, batwings and lamps (within R m of X Y Z), and each building's box: for placing cases",
	"perception_known": "perception_known PERSON -> what he knows: everyone in his Senses (seen, awareness, last seen and heard, where) and his stance to each",
}


func _cmd_perception(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "perception GROUP|CASE [seed=N] [out=DIR]"}
	var r: Node = Runner.new()
	r.name = "PerceptionRunner"
	r.lab = self
	r.want = String(a[0])
	r.seed_value = int(Runner.data().get("seed", 1))
	for w: String in a.slice(1):
		var kv := w.split("=", true, 1)
		match kv[0]:
			"seed": r.seed_value = int(kv[1])
			"out": r.out_dir = kv[1]
	if r.out_dir == "":
		r.out_dir = "build/perception_lab/bridge/%s_s%d" % [r.want, r.seed_value]
	if not r.out_dir.is_absolute_path():
		r.out_dir = ProjectSettings.globalize_path("res://").path_join(r.out_dir)
	DirAccess.make_dir_recursive_absolute(r.out_dir.get_base_dir())
	if not FileAccess.file_exists(r.out_dir.get_base_dir().path_join(".gdignore")):
		FileAccess.open(r.out_dir.get_base_dir().path_join(".gdignore"), FileAccess.WRITE).close()
	add_child(r)
	var out: Dictionary = await r.run()
	r.queue_free()
	if not out.get("ok", true):
		return out
	log_event("perception", "%s: %d cases, %d false, %d missed, %d leaks" % [r.want, out.counts.cases,
			out.counts["false"], out.counts.missed, out.counts.leaks])
	return {"summary": r.out_dir.path_join("summary.json"), "counts": out.counts}


func _cmd_perception_list(_a: Array) -> Dictionary:
	return {"groups": Runner.groups(), "cases": Runner.case_names(), "bodies": Runner.data().bodies}


func _cmd_perception_probe(a: Array) -> Dictionary:
	var at := vec(a, 0) if a.size() >= 3 else Vector3.INF
	var reach := float(a[3]) if a.size() >= 4 else 1e9
	var near := func(p: Vector3) -> bool: return at == Vector3.INF or p.distance_to(at) <= reach
	var out := {"buildings": {}, "openings": [], "lamps": []}
	for s: Node in street.find_children("*", "Structure", true, false):
		var box := AABB()
		var first := true
		for m: Node in s.find_children("*", "StructureMember", true, false):
			var p := (m as Node3D).global_position
			if first:
				box = AABB(p, Vector3.ZERO)
				first = false
			else:
				box = box.expand(p)
			var mm := m as StructureMember
			var id := String(m.name)
			if mm.kind in [&"glass", &"door"] and near.call(p):
				var co := m as CollisionObject3D
				out.openings.append({"building": String(s.name), "member": id, "kind": String(mm.kind), "at": arr(p),
						"layer": co.collision_layer if co else -1})
		if not first:
			out.buildings[String(s.name)] = {"from": arr(box.position), "to": arr(box.end)}
	for l: Node in street.find_children("*", "OilLamp", true, false):
		var p := (l as Node3D).global_position
		if near.call(p):
			out.lamps.append({"at": arr(p), "lit": (l as OilLamp).lit, "range": (l as OilLamp).light_range, "path": String(street.get_path_to(l))})
	return out


func _cmd_perception_known(a: Array) -> Dictionary:
	var man := person(String(a[0])) if a.size() > 0 else null
	if man == null:
		return {"ok": false, "error": "perception_known PERSON"}
	return Runner.knowledge(man, self)
