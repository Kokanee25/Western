extends Node
## The crowd bench's runner (crowd_bench.gd starts it: -s scripts compile before the autoloads).

const Lab := preload("res://experiments/building_lab/lab.gd")
const SPEC := "res://config/buildings/railroad_saloon.json"
const MAN_KG := 75.0
const STAMP := 1.8

var args := {}
var seeds := 10
var seconds := 8.0
var out := "build/railroad_saloon_crowd"
var rows: Array = []


func _ready() -> void:
	seeds = int(args.get("seeds", seeds))
	seconds = float(args.get("seconds", seconds))
	out = String(args.get("out", out))
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## The men's places: [[x, z, upstairs, role]] from the spec's use points and the seed.
func _places(spec: Dictionary, dice: RandomNumberGenerator) -> Array:
	var lv: Dictionary = spec.levels
	var u_top := float(lv.upper.top)
	var w := float(spec.lot.width)
	var d := float(spec.lot.depth)
	var up: Array = []
	var down: Array = []
	for u: Dictionary in spec.use_points:
		var p: Array = u.at
		var upper := float(p[1]) > u_top - 0.05
		var e := [float(p[0]), float(p[2]), upper, String(u.who)]
		if upper:
			up.append(e)
		else:
			down.append(e)
	# Upstairs to 40: dancers round the middle set (the reel's other sets, front and back bays) and men on
	# the benches by the walls; never two closer than 0.55 m, never inside the piano's corner.
	var tries := 0
	while up.size() < 40 and tries < 4000:
		tries += 1
		var bench := up.size() >= 28
		var x := dice.randf_range(0.5, w - 0.5)
		var z := dice.randf_range(0.6, d - 1.4)
		if bench:
			var side := dice.randi_range(0, 2)
			x = 0.75 if side == 0 else (w - 0.75 if side == 1 else x)
			z = 0.75 if side == 2 else z
		if x < 3.1 and z > d - 1.5:
			continue
		var ok := true
		for e: Array in up:
			ok = ok and Vector2(x - float(e[0]), z - float(e[1])).length() > 0.55
		if ok:
			up.append([x, z, true, "bench" if bench else "dancer"])
	# Below to 15: drinkers standing at the bar's ends, by the stove and the tables.
	tries = 0
	while down.size() < 15 and tries < 4000:
		tries += 1
		var x := dice.randf_range(2.6, w - 0.6)
		var z := dice.randf_range(0.8, d - 0.8)
		var ok := true
		for e: Array in down:
			ok = ok and Vector2(x - float(e[0]), z - float(e[1])).length() > 0.7
		for f: Dictionary in spec.furniture:
			ok = ok and Vector2(x - float(f.at[0]), z - float(f.at[1])).length() > 0.9
		if ok:
			down.append([x, z, false, "drinker"])
	return up + down


func _run() -> void:
	for sd in range(1, seeds + 1):
		await _one(sd)
	var f := FileAccess.open(out.path_join("crowd.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  "))
	f.close()
	print("crowd bench: %d seeds into %s" % [rows.size(), out])
	get_tree().quit(0)


func _one(sd: int) -> void:
	Lab.spec_path = SPEC
	Lab.settles_with = &"queue"  # (the valley's: no fire, the collapse sliced, #1128)
	var lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	Lab.settles_with = &"fire"
	await _frames(20)
	var b = lab.building
	var spec: Dictionary = lab.spec
	b.settle()
	var lv: Dictionary = spec.levels
	var g_top := float(lv.ground.top)
	var u_top := float(lv.upper.top)
	var dice := RandomNumberGenerator.new()
	dice.seed = hash(["railroad_crowd", sd])
	var empty := await _cost(90)
	var men: Array = []
	var space: PhysicsDirectSpaceState3D = lab.get_world_3d().direct_space_state
	var k := 0
	for e: Array in _places(spec, dice):
		var man = HumanBody.new()
		man.rng_seed = sd * 100 + k
		man.person_id = StringName("crowd_%02d" % k)
		var y := u_top if e[2] else g_top
		lab.add_child(man)
		var local := Vector3(float(e[0]), y, float(e[1]))
		var face := Vector3(dice.randf_range(-1, 1), 0, dice.randf_range(-1, 1)).normalized()
		man.global_transform = Transform3D(Basis.looking_at(face if face.length() > 0.1 else Vector3.FORWARD), b.global_transform * local)
		var row := {"man": man, "role": String(e[3]), "up": bool(e[2]), "at": local, "falls": [], "limp": false, "board": null}
		man.fell_from.connect(func(fall: Dictionary) -> void: (row.falls as Array).append(fall.duplicate(true)))
		row.blows = []
		man.hit.connect(func(info: Dictionary) -> void:
			if info.get("kind", &"") == &"blow":
				(row.blows as Array).append([snappedf(float(info.joules), 1.0), String(info.segment), Array(info.harm).map(func(h) -> String: return String(h))]))
		men.append(row)
		k += 1
	await _frames(10)
	# Each man's weight on the board under his feet (stamping, upstairs): the floor board whose box holds his
	# feet in plan, on his floor (found from the members, not a ray: a ray starting in his own blocker or a
	# batched collider misses).
	var floor_boards: Array = []
	for m: StructureMember in b.get_members():
		if m.kind == &"floor_board":
			floor_boards.append(m)
	for r: Dictionary in men:
		var at: Vector3 = r.at
		for m: StructureMember in floor_boards:
			var top := m.position.y + m.size.y * 0.5
			if absf(top - at.y) > 0.05:
				continue
			if absf(at.x - m.position.x) <= m.size.x * 0.5 + 0.01 and absf(at.z - m.position.z) <= m.size.z * 0.5 + 0.01:
				m.extra_load += MAN_KG * 9.81 * (STAMP if r.up else 1.0)
				r.board = m
				break
	b.invalidate_analysis()
	var gave: Array = b.settle()
	# The frame's cost with them all in it, before the cut.
	var before := await _cost(90)
	# The cut.
	var t0 := Time.get_ticks_usec()
	var halves: Array = b.saw_girder()
	var sid := String(b.structure_id) + "/"
	var worst := 0.0
	var last := Time.get_ticks_usec()
	var bodies_peak := 0
	var down_at := -1.0
	var ticks := int(seconds * 60.0)
	for t in ticks:
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
		if t % 30 == 0:
			bodies_peak = maxi(bodies_peak, _bodies(self))
		if t % 15 == 0:
			b.settle()
		# A man whose board went (broken, or nothing under his feet) goes down with it.
		if t % 3 == 0:
			for r: Dictionary in men:
				if r.limp or not r.up:
					continue
				var bd: StructureMember = r.board
				if bd != null and bd.broken:
					r.man.go_limp(Vector3.DOWN * 1.0)
					r.limp = true
					r.limp_t = t / 60.0
		# The bay is down when its joists' pieces are all a metre under the floor.
		if down_at < 0.0 and t % 6 == 0:
			var n := 0
			var low := 0
			for rb in get_tree().get_nodes_in_group(&"rubble"):
				var ids: Array = rb.get_meta(&"members", [])
				if ids.is_empty() or not String(ids[0]).begins_with(sid + "floor/dance_mid/joist/"):
					continue
				n += 1
				if b.to_local(rb.global_position).y < u_top - 0.8:
					low += 1
			if n > 0 and low >= int(ceil(n * 0.9)):
				down_at = t / 60.0
	if args.has("debug"):
		var shown := 0
		for rb in get_tree().get_nodes_in_group(&"rubble"):
			var ids: Array = rb.get_meta(&"members", [])
			if shown < 6:
				print("DBG rubble ", ids.slice(0, 2), " y ", b.to_local(rb.global_position).y, " layer ", rb.collision_layer, " mask ", rb.collision_mask)
				shown += 1
		for r: Dictionary in men:
			if not r.up:
				var hb: Array = []
				for c in r.man.get_children():
					if c is CollisionObject3D:
						hb.append([c.name, c.collision_layer, c.collision_mask, c.has_meta(&"human_body")])
				print("DBG below ", r.at, " ", hb.slice(0, 3))
				break
	var mem_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	# What came down.
	var boards := 0
	var area := 0.0
	var joists := 0
	for m: StructureMember in b.get_members():
		if not m.broken:
			continue
		var id := String(m.member_id).trim_prefix(sid)
		if id.begins_with("floor/dance_mid/board/"):
			boards += 1
			area += m.size.x * m.size.z
		elif id.begins_with("floor/dance_mid/joist/"):
			joists += 1
	# The men: fallen, struck, bones, dead in ten minutes.
	var fell := 0
	var struck_below := 0
	var dead := 0
	var hurt := 0
	var people: Array = []
	for r: Dictionary in men:
		var man = r.man
		var p = man.physiology
		var bones: Array = p.broken.keys()
		var alive_now: bool = p.alive
		var tt := 0.0
		while p.alive and tt < 600.0:
			p.step(1.0)
			tt += 1.0
		var struck: bool = not r.up and (not bones.is_empty() or not (man.wounds as Array).is_empty() or not p.alive)
		if r.limp:
			fell += 1
		if struck:
			struck_below += 1
		if not p.alive:
			dead += 1
		if not bones.is_empty() or not p.alive:
			hurt += 1
		people.append({"id": String(man.person_id), "role": r.role, "up": r.up, "at": [snappedf(r.at.x, 0.01), snappedf(r.at.z, 0.01)],
			"fell": r.limp, "landings": (r.falls as Array).map(func(f: Dictionary) -> Dictionary: return {"speed": f.get("speed", 0.0), "harm": f.get("harm", [])}),
			"blows": r.blows, "bones": bones.map(func(x) -> String: return String(x)), "alive_at_cut_end": alive_now, "dead_10min": not p.alive, "cause": String(p.cause_of_death)})
	var row := {"seed": sd, "gave_whole": gave.size(), "halves": halves.size(), "down_s": snappedf(down_at, 0.01),
		"joists_down": joists, "boards_down": boards, "area_down_m2": snappedf(area, 0.1),
		"fell": fell, "struck_below": struck_below, "hurt": hurt, "dead": dead,
		"empty": empty, "before": before, "people_ms": snappedf(float(before.frame_ms) - float(empty.frame_ms), 0.01), "fall_worst_frame_ms": snappedf(worst, 0.1),
		"bodies_peak": bodies_peak, "memory_static_mb": snappedf(mem_mb, 1.0), "people": people}
	rows.append(row)
	print("seed %d: whole gave %d | down in %.2f s: %d joists, %d boards (%.1f m2) | fell %d, struck below %d, hurt %d, dead %d | frame %.1f ms empty, %.1f with them (%.1f the men) | fall worst %.0f ms | bodies %d | mem %d MB" % [
		sd, gave.size(), down_at, joists, boards, area, fell, struck_below, hurt, dead, empty.frame_ms, before.frame_ms, float(before.frame_ms) - float(empty.frame_ms), worst, bodies_peak, int(mem_mb)])
	lab.queue_free()
	await _frames(5)


## The mean frame (ms) over `n` ticks and the worst; and the collision objects in the lab.
func _cost(n: int) -> Dictionary:
	var last := Time.get_ticks_usec()
	var sum := 0.0
	var worst := 0.0
	for i in n:
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		last = now
		if i > 0:
			sum += ms
			worst = maxf(worst, ms)
	return {"frame_ms": snappedf(sum / (n - 1), 0.01), "worst_ms": snappedf(worst, 0.1), "bodies": _bodies(self)}


## Collision objects under `n` (the building's members, the rubble, the men's ragdoll parts and hitboxes).
static func _bodies(n: Node) -> int:
	var c := 1 if n is CollisionObject3D else 0
	for ch in n.get_children():
		c += _bodies(ch)
	return c
