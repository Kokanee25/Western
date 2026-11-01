extends SceneTree
## The people after a blast (#495): the game's street loaded as the game loads it (the townsfolk
## and the gang in), then each second of physics ticks for a while before a stick and after it:
## how many men ticked every tick and how many were slowed (PeopleTick's bands, more-cores step
## 4b), why each that wasn't slowed wasn't (PeopleTick's `n_full_*` counts: his body's or brain's
## `slow_reason`, near the player, near someone in trouble, the camera), and what the people cost
## a tick (people_body, senses, the brains, people_prep_sum; ms here and at Sean's clock).
##
##   godot --headless --fixed-fps 60 -s res://tools/people_after_blast.gd -- [--before=5] [--after=10]
##       [--spec] [--sticks=2] [--folk=N] [--out=FILE.json] [--people-bands=off]
## Street: the player where perf_bench stands him (in the street, looking down it), the sticks as
## perf_bench's fire scene sets them (the store's front, then the saloon's). --spec: the building
## lab's saloon built out in the desert (as F5's stop and the gunfight lab build it), the player in
## its hall, the stick 7 m from him (the blast-freeze lab's `at` and `player`).
## Untyped on purpose: -s scripts compile before autoloads exist.

const TIMERS := [&"people_body", &"people_skeleton", &"senses", &"civilian_brain", &"outlaw_brain",
		&"people_prep", &"people_prep_sum", &"people_bands", &"town_life", &"blood", &"face_life"]

var _ticks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var before := 5
	var after := 10
	var spec := false
	var sticks := 2
	var folk := 1
	var out_path := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--before="):
			before = int(a.substr(9))
		elif a.begins_with("--after="):
			after = int(a.substr(8))
		elif a == "--spec":
			spec = true
		elif a.begins_with("--sticks="):
			sticks = int(a.substr(9))
		elif a.begins_with("--folk="):
			folk = int(a.substr(7))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
	root.get_node(^"Settings").autosave = false
	var scale: float = load("res://config/frame_budget.tres").clock_scale
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	var street: Node3D = main.find_child("TestStreet", true, false)
	var player = street.get_node(^"Player")
	player.input_enabled = false
	var town = street.get_node(^"TownLife")
	town.bring_gang()
	var spec_saloon = load("res://experiments/gunfight_lab/spec_saloon.gd")
	if spec:
		spec_saloon.ensure(street, town.places)
		for i in 30:
			await physics_frame
		player.global_position = spec_saloon.at(Vector3(12.0, 0.8, 2.0))
	else:
		player.global_position = Vector3(11.0, 0.0, -9.0)
	player.rotation = Vector3(0, deg_to_rad(121.0), 0)
	player.velocity = Vector3.ZERO
	for i in 120:
		await physics_frame
	if folk > 1:
		var copies: Array = load("res://tools/folk_copies.gd").lay(street, folk)
		print("folk: %d more townsfolk, two streets off" % copies.size())
		for i in 120:
			await physics_frame
	physics_frame.connect(func() -> void: _ticks += 1)
	var prof = load("res://src/debug/prof.gd")
	prof.on = true
	prof.reset()
	load("res://src/people/people_tick.gd").time_by_why = true
	var rows := []
	print("people: %d; bands %s" % [load("res://src/people/people_tick.gd").people().size(),
			"on" if root.get_node(^"Settings").people_bands else "off"])
	print("  s  wall  ticked slow trouble | people ms/tick here (Sean's) | body senses brains prep_sum | why not slowed (a tick)")
	for sec in range(-before, after):
		if sec == 0:
			await physics_frame  # (the blast asks the world: World.space's rule)
			_set_off(street, spec, spec_saloon, sticks)
		prof.roll()  # forget what came before
		var t0 := _ticks
		var w0 := Time.get_ticks_usec()
		while _ticks - t0 < 60:
			await process_frame
		var wall := (Time.get_ticks_usec() - w0) / 1000.0 / maxf(_ticks - t0, 1)
		var n := float(_ticks - t0)
		prof._frames = 1  # per_frame as the sums themselves
		prof.roll()
		var per: Dictionary = prof.per_frame
		var row := {"s": sec, "ticks": int(n), "wall_ms": wall}
		var people := 0.0
		for k in TIMERS:
			var v := float(per.get(k, 0.0)) / n
			row[String(k)] = v
			if k != &"people_prep" and k != &"people_bands":
				people += v
		row["people_ms"] = people
		var why := {}
		for k: StringName in per:
			var s := String(k)
			if s.begins_with("n_"):
				row[s] = float(per[k]) / n
				if s.begins_with("n_full_"):
					why[s.substr(7)] = float(per[k]) / n
			elif s.begins_with("t_") or s.begins_with("c_") or s.begins_with("pb_"):
				row[s] = float(per[k]) / n
		rows.append(row)
		var keys := why.keys()
		keys.sort_custom(func(a, b) -> bool: return why[a] > why[b])
		var parts := []
		for k in keys:
			parts.append("%s %.1f" % [k, why[k]])
		print("%3d %5.1f  %5.1f %4.1f %5.1f | %5.2f (%4.2f) | %4.2f %4.2f %4.2f %4.2f | %s" % [sec, wall,
				row.get("n_people_ticked", 0.0), row.get("n_slow", 0.0), row.get("n_people_trouble", 0.0),
				people, people * scale, row.people_body, row.senses, row.civilian_brain + row.outlaw_brain,
				row.people_prep_sum, ", ".join(parts)])
	var pre := rows.filter(func(r) -> bool: return r.s < 0)
	var post := rows.filter(func(r) -> bool: return r.s >= 0)
	var mean := func(rs: Array, k: String) -> float:
		var t := 0.0
		for r in rs:
			t += float(r.get(k, 0.0))
		return t / maxf(rs.size(), 1)
	print("before: people %.2f ms a tick here (%.2f at Sean's), slowed %.1f of %.1f; after (%d s): people %.2f (%.2f), slowed %.1f of %.1f" % [
			mean.call(pre, "people_ms"), mean.call(pre, "people_ms") * scale, mean.call(pre, "n_slow"),
			mean.call(pre, "n_people_ticked") + mean.call(pre, "n_people_owed"), after,
			mean.call(post, "people_ms"), mean.call(post, "people_ms") * scale, mean.call(post, "n_slow"),
			mean.call(post, "n_people_ticked") + mean.call(post, "n_people_owed")])
	# Each state's cost a man a tick (his whole tick and his first half), before and after.
	for part in [["before", pre], ["after", post]]:
		var t := {}
		var c := {}
		for r in part[1]:
			for k: String in r:
				if k.begins_with("t_"):
					t[k.substr(2)] = float(t.get(k.substr(2), 0.0)) + float(r[k])
				elif k.begins_with("c_"):
					c[k.substr(2)] = float(c.get(k.substr(2), 0.0)) + float(r[k])
		var parts := []
		for k in t:
			if float(c.get(k, 0.0)) > 0.0:
				parts.append("%s %.0f us x %.1f" % [k, float(t[k]) / float(c[k]) * 1000.0, float(c[k]) / maxf(part[1].size(), 1)])
		print("%s, a man's tick by state (us here, men a tick): %s" % [part[0], ", ".join(parts)])
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"spec": spec, "sticks": sticks, "folk": folk, "rows": rows}, "  "))
	quit()


## The stick(s): Blast.detonate where perf_bench's fire scene sets them (the store's front, the
## saloon's), or in the spec saloon's hall.
func _set_off(street: Node3D, spec: bool, spec_saloon, sticks: int) -> void:
	var blast = load("res://src/blast/blast.gd")
	if spec:
		blast.detonate(street, spec_saloon.at(Vector3(6.0, 0.8, 6.0)), 0.2)
		print("-- a stick in the spec saloon's hall")
		return
	var lit := 0
	for b in street.get_children():
		var sname: String = (b.get_script() as Script).get_global_name() if b.get_script() else ""
		if sname not in ["FalseFrontBuilding", "SaloonBuilding"]:
			continue
		var members: Array = b.find_children("*", "StructureMember", true, false)
		if members.is_empty():
			continue
		var m = members[members.size() / 3]
		blast.detonate(street, (m as Node3D).global_position + Vector3(0, 0.3, 0), 0.2)
		lit += 1
		if lit >= sticks:
			break
	print("-- %d stick(s) on the street" % lit)
