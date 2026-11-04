extends BridgeLab
## The blast-freeze lab (README.md beside this file; issue #374): Sean's 20-second freeze when a
## stick of dynamite goes off in the spec saloon with a fire already burning. One command sets the
## scene up (the building lab's saloon, a fire lit near the spot and left to grow, the men if asked),
## then throws the stick and records every frame through the blast: wall-clock ms, each system's
## share (Prof), the blast's and the settle's own timers, what broke, what fell. Its answer is the
## headline (the worst frame, the frames over the stall line, where the time went); the whole trace
## goes to `out`.

const SpecSaloon := preload("res://experiments/gunfight_lab/spec_saloon.gd")
const FarmLab := preload("res://experiments/farmhouse/bridge.gd")

const HELP := {
	"bf_blast": "bf_blast [at=X,Y,Z] [fire=N] [burn=S] [fuse=S] [seconds=S] [stall=MS] [player=X,Y,Z] [census=1] [in=street] [sticks=N] [gap=S] [spread=M] [awake=S] [world=X,Y,Z] [stand=X,Y,Z] [men=N] [men_r=M] [lift=F] [bundle=N] [plunger=1] [out=FILE.json] -> the spec saloon (or Main Street's first buildings, in=street; `sticks` of them `gap` s apart, `spread` m along the saloon's front) (built if it isn't), the player put at `player` (the saloon's own space; left where he is if not given), N members alight near `at` (the saloon's own space) and left to burn S s, then a stick there and every frame recorded for S s after: the worst frame, frames over the stall line, where the time went; `awake=S` a census of the awake rubble every S s (`awake_log`: speeds, contacts, piles, wakes and sleeps since the last, RubbleSleep's counts; #585); in=farm `world` one stick at that world point instead of the ring, `stand` the player there (world; #626); `men` standing men `men_r` m round the first stick, `lift` BlastTuning.blast_lift (#596 step 3b); `bundle` sticks a charge (#647), `plunger=1` the charges wired and fired by the plunger at `fuse` s (a tick apart, the game's) instead of fuses `gap` apart",
	"bf_movers": "bf_movers [N] -> the N awake bodies moving most, each with every contact (what, where, normal, impulse) (#584)",
	"bf_frames": "bf_frames [N] -> the last N recorded frames (bf_blast), newest last",
	"bf_analyse": "bf_analyse -> the spec saloon (built if it isn't) analysed from the top, a member at a time, timed: µs a member by kind (count, mean, worst) and the ten slowest (more-cores step 5: the load check's slices)",
	"bf_batches": "bf_batches -> the batches every structure in the town draws in (Structure.batch_count), in all and the five largest, and the spec saloon's if it's built",
	"bf_shot": "bf_shot [from=X,Y,Z] [dirs=x,-x,z,-z] [gap=S] [stall=MS] [out=FILE.json] -> the spec saloon (built if it isn't), a revolver ball from `from` (the saloon's own space) each way in `dirs`, `gap` s apart, every frame recorded: each shot's worst frame and what was in it, and the saloon's batches (members a material) (Sean's per-shot hitch, #385)",
}

## A frame longer than this (ms, this workspace's wall clock) counts as a stall.
const STALL_MS := 50.0

var _frames: Array[Dictionary] = []
var _recording := false
var _last_us := 0
var _event_tick := -1
var _broken := 0
var _cut := 0
## The frame's phases (#538 round 3): stamps at the last _process, the first physics tick and
## process_frame, so a frame's time splits into late process / the frame's end (deferred calls,
## frees, the server sync) / physics / early process.
var _late_us := 0
var _phys_us := 0
var _proc_us := 0
var _late_node: Node
## The awake rubble's census (#585, `awake=S`): instance id -> [asleep last tick, wakes].
var _sleep_state := {}
var _wakes_since := 0
var _sleeps_since := 0
var _awake_log: Array = []
var _awake_every := 0.0
var _awake_next := 0.0
var _ground_edits := 0
var _was_asleep := {}


func _cmd_bf_blast(a: Array) -> Dictionary:
	var opts := {"at": "6.0,0.8,6.0", "fire": 0, "burn": 20.0, "fuse": 1.0, "seconds": 8.0, "stall": STALL_MS, "out": "", "player": "", "census": 0, "in": "saloon", "sticks": 1, "gap": 0.4, "spread": 3.0, "awake": 0.0,
			"men": 0, "men_r": 1.0, "lift": -1.0, "bundle": 1, "plunger": 0}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var on_street := String(opts["in"]) == "street"
	var on_farm := String(opts["in"]) == "farm"
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon: Structure = null
	if not on_street and not on_farm:
		saloon = SpecSaloon.ensure(street, town.places if town else null) as Structure
		if not built:
			await physics_frames(30)
	var parts := String(opts.at).split(",")
	if parts.size() != 3:
		return {"ok": false, "error": "at=X,Y,Z (the saloon's own space)"}
	var local := Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	# Where the sticks go: in the saloon `at`, the rest `spread` m apart along its front; on Main
	# Street (in=street) perf_bench's spots, a third of the way through the first buildings' members.
	var spots: Array[Vector3] = []
	var n_sticks := maxi(int(opts.sticks), 1)
	if on_farm:
		# #584: Sean's ring of sticks thrown round the farmhouse: one lying on the ground 0.6 m out
		# from each wall's breach spot (the farmhouse lab's WALLS), in `walls`' order, `gap` s apart.
		var walls := String(opts.get("walls", "front,east,back,lean_back,lean_west,west")).split(",")
		for k in walls.size():
			var w: Array = FarmLab.WALLS.get(walls[k], [])
			if w.is_empty():
				return {"ok": false, "error": "no wall %s (%s)" % [walls[k], FarmLab.WALLS.keys()]}
			var on: Vector3 = w[0]
			var out: Vector3 = w[1]
			spots.append(Farmhouse.on_ground(on.x + out.x * 0.6, on.z + out.z * 0.6) + Vector3.UP * 0.1)
		if String(opts.get("world", "")) != "":
			# #626: Sean's one stick inside the house (world X,Y,Z; his F12s: 97.8,2.34,-48.94), not the ring.
			var wp := String(opts.world).split(",")
			spots = [Vector3(float(wp[0]), float(wp[1]), float(wp[2]))]
		n_sticks = spots.size()
		if String(opts.get("stand", "")) != "" and player:
			# #626: where Sean stood (world X,Y,Z; his F12s: 96.3,1.1,-33.6), looking at the stick.
			var sp := String(opts.stand).split(",")
			player.global_position = Vector3(float(sp[0]), float(sp[1]), float(sp[2]))
			player.velocity = Vector3.ZERO
			await physics_frames(2)
		elif String(opts.player) == "" and player:
			# In the yard 12 m off the front, as a man throwing round the house would be.
			player.global_position = Farmhouse.on_ground(4.5, -12.0) + Vector3.UP * 0.1
			player.velocity = Vector3.ZERO
			await physics_frames(2)
		if int(opts.get("mission", 0)) != 0:
			var mission := FarmhouseMission.of(get_tree())
			if mission and mission.state != FarmhouseMission.State.ON:
				mission.begin(false)
			await seconds(float(opts.get("settle", 5.0)))
	elif on_street:
		for b in street.get_children():
			var sname: String = (b.get_script() as Script).get_global_name() if b.get_script() else ""
			if sname not in ["FalseFrontBuilding", "SaloonBuilding"]:
				continue
			var ms: Array = b.find_children("*", "StructureMember", true, false)
			if ms.is_empty():
				continue
			spots.append((ms[ms.size() / 3] as Node3D).global_position + Vector3(0, 0.3, 0))
			if spots.size() >= n_sticks:
				break
	else:
		for k in n_sticks:
			spots.append(SpecSaloon.at(local + Vector3(float(opts.spread) * k, 0.0, 0.0)))
	var at: Vector3 = spots[0]
	if String(opts.player) != "" and player and not on_farm:
		# Where he stands decides the fire's bands (FireSystem.bands): in the hall, everything near.
		var pp := String(opts.player).split(",")
		player.global_position = SpecSaloon.at(Vector3(float(pp[0]), float(pp[1]), float(pp[2])))
		player.velocity = Vector3.ZERO
		await physics_frames(2)
	# Issue #596 step 3b: `men` standing men (no brain: they don't run from the fuse) round the
	# first stick, `men_r` m from it, on the floor under each; `lift` BlastTuning.blast_lift.
	if float(opts.lift) >= 0.0:
		Blast.t().blast_lift = float(opts.lift)
	var men: Array[HumanBody] = []
	for k in int(opts.men):
		var ang := TAU * k / maxf(float(opts.men), 1.0)
		var p := at + Vector3(cos(ang), 0.0, sin(ang)) * float(opts.men_r)
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 3.0, Layers.WORLD)
		var hit := World.space(street).intersect_ray(q)
		if not hit.is_empty():
			p = hit.position
		var man := HumanBody.new()
		man.rng_seed = 700 + k
		man.person_id = StringName("bf_man%d" % k)
		man.name = String(man.person_id)
		man.has_gun = false
		man.enter(street, p, ang + PI * 0.5)
		men.append(man)
	if not men.is_empty():
		await physics_frames(10)
	var fire := FireSystem.find(get_tree())
	var lit: Array = []
	var n_fire := int(opts.fire)
	if n_fire > 0 and fire and saloon:
		# The nearest flammable boards to the spot, so the fire is where the stick lands.
		var cands: Array = []
		for m: StructureMember in saloon.get_members():
			if m.broken or m.burning or not fire.flammable(m) or not (m.kind in [&"floor_board", &"board", &"roof_board"]):
				continue
			cands.append([m.world_aabb().get_center().distance_to(at), m])
		cands.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for i in mini(n_fire, cands.size()):
			var m: StructureMember = cands[i][1]
			fire.ignite(m)
			lit.append(String(m.member_id))
		await seconds(float(opts.burn))
	var burning_before := fire.burning_members().size() if fire else 0
	var members_before := saloon.member_count() if saloon else 0
	var rubble_before := saloon.rubble.size() if saloon else 0
	# Record from a second before the stick to `seconds` after it goes off.
	PhysicsWindow.add_to(get_tree().root)  # the frame as window, step (Jolt's) and rest
	_frames.clear()
	_broken = 0
	_cut = 0
	_event_tick = -1
	Prof.on = true
	Prof._sum.clear()
	var on_broken := func(_id: StringName) -> void: _broken += 1
	var on_cut := func(_m: Node, _p: Array) -> void: _cut += 1
	Events.member_broken.connect(on_broken)
	Events.member_cut.connect(on_cut)
	if not Events.ground_changed.is_connected(_on_ground_edit):
		Events.ground_changed.connect(_on_ground_edit)
	_last_us = Time.get_ticks_usec()
	if _late_node == null:
		_late_node = Node.new()
		_late_node.process_priority = 1000000
		_late_node.set_script(_LATE)
		_late_node.set_meta(&"lab", self)
		add_child(_late_node)
		get_tree().physics_frame.connect(func() -> void:
			if _phys_us == 0:
				_phys_us = Time.get_ticks_usec())
		get_tree().process_frame.connect(func() -> void: _proc_us = Time.get_ticks_usec())
	_awake_every = float(opts.awake)
	_awake_log.clear()
	_sleep_state.clear()
	_awake_next = World.now()
	if _awake_every > 0.0 and not get_tree().physics_frame.is_connected(_track_sleep):
		get_tree().physics_frame.connect(_track_sleep)
	_recording = true
	await seconds(1.0)
	var n_per := maxi(int(opts.bundle), 1)
	var by_plunger := int(opts.plunger) != 0
	var stick := DynamiteStick.make(street, at, Vector3.ZERO, float(opts.fuse), n_per)
	var charges: Array[DynamiteStick] = [stick]
	for k in range(1, spots.size()):
		charges.append(DynamiteStick.make(street, spots[k], Vector3.ZERO, float(opts.fuse) + float(opts.gap) * k, n_per))
	if by_plunger:
		# Wired and fired as the plunger does it (#647), at `fuse` s.
		for c in charges:
			c.planted = true
			c.wire()
		get_tree().create_timer(float(opts.fuse), true, true).timeout.connect(func() -> void:
			DynamiteStick.fire_wired(get_tree(), at))
	else:
		for c in charges:
			c.light()
	# The census walks the whole tree (~26,000 nodes, ~0.1 s): only when asked, as it lands on the
	# frames measured (#538: it was the stick's frame's deferred calls and the one before).
	var take_census := int(opts.census) != 0
	var census := [_census() if take_census else {}, {}]
	stick.went_off.connect(func() -> void:
		_event_tick = Engine.get_physics_frames()
		if take_census:
			(func() -> void: census[1] = _census()).call_deferred())
	await seconds(float(opts.fuse) + float(opts.gap) * (spots.size() - 1) + float(opts.seconds))
	_recording = false
	if get_tree().physics_frame.is_connected(_track_sleep):
		get_tree().physics_frame.disconnect(_track_sleep)
	Events.member_broken.disconnect(on_broken)
	Events.member_cut.disconnect(on_cut)
	var stall := float(opts.stall)
	var summary := _summarise(stall)
	if _awake_every > 0.0:
		summary["awake_log"] = _awake_log.duplicate()
	var sleeper := _sleeper()
	summary["rubble_sleep"] = (sleeper.get(&"counts") as Dictionary).duplicate() if sleeper else {}
	summary["awake_end"] = _rubble_count(true)
	summary["setup"] = {"at": arr(at), "at_local": [local.x, local.y, local.z], "lit": lit, "burn_s": float(opts.burn),
			"in": String(opts["in"]), "spots": spots.map(func(v: Vector3) -> Array: return arr(v)), "gap": float(opts.gap),
			"burning_before": burning_before, "members_before": members_before, "rubble_before": rubble_before,
			"members_after": saloon.member_count() if saloon else 0, "rubble_after": saloon.rubble.size() if saloon else 0,
			"burning_after": fire.burning_members().size() if fire else 0, "broken": _broken, "cut": _cut,
			"rubble_end": _rubble_count(false), "awake_end": _rubble_count(true),
			"mission": int(opts.get("mission", 0)), "blast_lift": Blast.t().blast_lift,
			"men": men.map(func(m: HumanBody) -> Dictionary: return {"limp": m.limp, "from_stick": m.global_position.distance_to(at),
					"thrown_to": (m.parts[&"pelvis"] as Node3D).global_position.distance_to(at) if m.parts.has(&"pelvis") else -1.0}),
			"people": get_tree().get_nodes_in_group(&"people").size(), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"player": arr(player.global_position) if player else [], "player_from_stick": player.global_position.distance_to(at) if player else -1.0,
			"fire_bands": (load("res://src/fire/fire_system.gd") as Script).get(&"bands")}  # null before step 5
	# Which members are broken at the end: two runs of the same scenario should name the same.
	var broken_ids: Array = []
	for st: Node in ([saloon] if saloon else get_tree().get_nodes_in_group(&"structures")):
		if not is_instance_valid(st) or not st is Structure:
			continue
		for m: StructureMember in (st as Structure).get_members():
			if m.broken:
				broken_ids.append(String(m.member_id))
	broken_ids.sort()
	summary.setup["broken_ids_hash"] = hash(broken_ids)
	# What the stick's frame added, by class (the nodes in the tree just after it went off).
	var added: Array = []
	for k: String in census[1]:
		var n := int(census[1][k]) - int(census[0].get(k, 0))
		if n != 0:
			added.append([n, k])
	added.sort()
	added.reverse()
	summary["stick_added"] = added.slice(0, 12)
	summary.setup["broken_now"] = broken_ids.size()
	summary["broken_ids"] = broken_ids
	if String(opts.out) != "":
		var path := String(opts.out)
		if not path.is_absolute_path():
			path = ProjectSettings.globalize_path("res://").path_join(path)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		var full := summary.duplicate()
		full["frames"] = _frames
		f.store_string(JSON.stringify(full, " "))
		f.close()
		summary["out"] = path
	summary.erase("broken_ids")
	log_event("lab", "bf_blast: worst frame %.0f ms, %d over %.0f ms (%.1f s in all)" % [summary.worst_ms, summary.stalls, stall, summary.stall_s])
	return summary


## Sean's per-shot hitch (#385, more-cores step 2): a ball into the saloon's wall, each way in turn,
## each frame recorded (wall clock and Prof, as bf_blast), and per shot the worst frame in the
## second after it.
func _cmd_bf_shot(a: Array) -> Dictionary:
	var opts := {"from": "6.0,1.5,6.0", "dirs": "x,-x,z,-z", "gap": 1.0, "stall": STALL_MS, "out": ""}
	for w: String in a:
		var kv := w.split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon := SpecSaloon.ensure(street, town.places if town else null) as Structure
	if not built:
		await physics_frames(30)
	await seconds(1.0)  # the build's own rebuilds and shadow out of the way
	var p := String(opts.from).split(",")
	var from := SpecSaloon.at(Vector3(float(p[0]), float(p[1]), float(p[2])))
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var t: RevolverTuning = load("res://config/revolver.tres")
	var sizes: Array = []
	for key: Variant in saloon._batch_members:
		sizes.append((saloon._batch_members[key] as Array).size())
	sizes.sort()
	_frames.clear()
	_event_tick = -1
	Prof.on = true
	Prof._sum.clear()
	_last_us = Time.get_ticks_usec()
	_recording = true
	await seconds(0.5)
	var shots: Array = []
	for d: String in String(opts.dirs).split(","):
		var axis := {"x": Vector3.RIGHT, "-x": Vector3.LEFT, "z": Vector3.BACK, "-z": Vector3.FORWARD}.get(d, Vector3.FORWARD) as Vector3
		# The saloon's own axes in the world (it may stand turned).
		var dir := (SpecSaloon.at(axis) - SpecSaloon.at(Vector3.ZERO)).normalized()
		var damaged := [0]
		var on_damaged := func(_info: Dictionary) -> void: damaged[0] += 1
		Events.bullet_hit.connect(on_damaged)
		var tick := Engine.get_physics_frames()
		_event_tick = tick
		ballistics.fire(from, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, [])
		await seconds(float(opts.gap))
		Events.bullet_hit.disconnect(on_damaged)
		var worst := {}
		for f: Dictionary in _frames:
			if int(f.tick) >= tick and (worst.is_empty() or float(f.ms) > float(worst.ms)):
				worst = f
		shots.append({"dir": d, "hits": damaged[0], "worst_ms": worst.get("ms", 0.0),
				"worst_after_ticks": int(worst.get("tick", tick)) - tick, "top": _top(worst.get("prof", {}), 6)})
	_recording = false
	var summary := _summarise(float(opts.stall))
	summary["shots"] = shots
	summary["batches"] = {"count": saloon.batch_count(), "members": saloon.member_count(),
			"largest": sizes.slice(maxi(sizes.size() - 5, 0)), "median": sizes[sizes.size() / 2] if not sizes.is_empty() else 0}
	if String(opts.out) != "":
		var path := String(opts.out)
		if not path.is_absolute_path():
			path = ProjectSettings.globalize_path("res://").path_join(path)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		var full := summary.duplicate()
		full["frames"] = _frames
		f.store_string(JSON.stringify(full, " "))
		f.close()
		summary["out"] = path
	log_event("lab", "bf_shot: %s" % [shots.map(func(x: Dictionary) -> String: return "%s %.0f ms" % [x.dir, x.worst_ms])])
	return summary


func _cmd_bf_analyse(_a: Array) -> Dictionary:
	var town := street.get_node_or_null(^"TownLife") as TownLife
	var built := street.get_node_or_null(^"SpecSaloon") != null
	var saloon := SpecSaloon.ensure(street, town.places if town else null) as Structure
	if not built:
		await physics_frames(30)
	var out := {}
	for run in 2:  # the second with every member's geometry already kept
		var a := StructuralAnalysis.new(saloon.tuning)
		var t0 := Time.get_ticks_usec()
		a.begin(saloon)
		var t_begin := Time.get_ticks_usec() - t0
		var by_kind := {}
		var slow: Array = []
		var n := a.left()
		var t_all := Time.get_ticks_usec()
		for i in n:
			var m: StructureMember = a._sorted[a._next]
			var t := Time.get_ticks_usec()
			a.advance(1)
			var us := Time.get_ticks_usec() - t
			var k: Array = by_kind.get_or_add(String(m.kind), [0, 0, 0])
			k[0] += 1
			k[1] += us
			k[2] = maxi(k[2], us)
			slow.append([us, String(m.member_id), m.supported_by.size(), (a._received.get(m.member_id, {}) as Dictionary).size()])
		var total := Time.get_ticks_usec() - t_all
		slow.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
		var kinds := {}
		for k: String in by_kind:
			var v: Array = by_kind[k]
			kinds[k] = "n %d mean %.0f worst %d (total %.1f ms)" % [v[0], float(v[1]) / v[0], v[2], v[1] / 1000.0]
		var whole := StructuralAnalysis.new(saloon.tuning)
		var t_w := Time.get_ticks_usec()
		whole.begin(saloon)
		whole.advance(whole.left())
		out["whole%d_ms" % run] = (Time.get_ticks_usec() - t_w) / 1000.0  # begin and every member in one go, untimed inside
		out["run%d" % run] = {"begin_ms": t_begin / 1000.0, "members": n, "advance_ms": total / 1000.0,
				"us_a_member": float(total) / maxi(n, 1), "kinds": kinds, "slowest": slow.slice(0, 10)}
	return out


func _cmd_bf_batches(_a: Array) -> Dictionary:
	var rows: Array = []
	var total := 0
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		var st := s as Structure
		if st == null:
			continue
		total += st.batch_count()
		rows.append([st.batch_count(), String(st.name), st.member_count()])
	rows.sort()
	return {"structures": rows.size(), "batches": total, "largest": rows.slice(maxi(rows.size() - 5, 0))}


## #584: the awake bodies that move most, each with every contact (its contact count raised to 16
## for a few ticks first): what it touches, where, the normal and the impulse.
func _cmd_bf_movers(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 5
	var all: Array = []
	for nd: Node in street.find_children("*", "RigidBody3D", true, false):
		var rb := nd as RigidBody3D
		if not rb.sleeping and not rb.freeze:
			all.append([rb.linear_velocity.length() + 0.1 * rb.angular_velocity.length(), rb])
	all.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	var picked: Array = all.slice(0, n).map(func(x: Array) -> RigidBody3D: return x[1])
	for rb: RigidBody3D in picked:
		rb.contact_monitor = true
		rb.max_contacts_reported = 16
	await physics_frames(3)
	var out: Array = []
	for rb: RigidBody3D in picked:
		if not is_instance_valid(rb):
			continue
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		var contacts: Array = []
		for i in st.get_contact_count():
			var o := st.get_contact_collider_object(i)
			contacts.append({"with": (String(o.name) + ":" + o.get_class()) if o else "?", "shape": st.get_contact_collider_shape(i),
					"at": arr(st.get_contact_collider_position(i)), "n": arr(st.get_contact_local_normal(i)),
					"impulse": arr(st.get_contact_impulse(i))})
		var shapes: Array = []
		for o in rb.get_shape_owners():
			for k in rb.shape_owner_get_shape_count(o):
				var s := rb.shape_owner_get_shape(o, k)
				shapes.append(s.get_class() + (" %s" % [arr((s as BoxShape3D).size)] if s is BoxShape3D else ""))
		out.append({"name": String(rb.name), "parent": String(rb.get_parent().name), "at": arr(rb.global_position),
				"house": arr(Farmhouse.origin().affine_inverse() * rb.global_position) if Farmhouse.of(get_tree()) else [],
				"v": arr(rb.linear_velocity), "w": arr(rb.angular_velocity), "mass": rb.mass, "ccd": rb.continuous_cd,
				"members": rb.get_meta(&"members", []), "shapes": shapes, "contacts": contacts,
				"ground_h": TownLayout.ground_height(rb.global_position.x, rb.global_position.z)})
	return {"awake": all.size(), "movers": out}


func _on_ground_edit(_area: Rect2) -> void:
	_ground_edits += 1


func _cmd_bf_frames(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 20
	return {"frames": _frames.slice(maxi(_frames.size() - n, 0))}


## The headline: the worst frame and what was in it, every frame over the stall line, the sum of the
## blast's own timers over the recording.
func _summarise(stall: float) -> Dictionary:
	var worst := {}
	var stalls: Array = []
	var stall_s := 0.0
	var totals := {}
	var after_sum := 0.0
	var after_n := 0
	for f in _frames:
		var ms: float = f.ms
		if worst.is_empty() or ms > float(worst.ms):
			worst = f
		if ms > stall:
			stalls.append({"tick": f.tick, "after": f.after, "ms": snappedf(ms, 0.1), "top": _top(f.prof, 5)})
			stall_s += ms / 1000.0
		for k: String in f.prof:
			totals[k] = float(totals.get(k, 0.0)) + float(f.prof[k])
		if int(f.after) > 60 and int(f.after) <= 60 * 6:
			after_sum += ms
			after_n += 1
	var keys := totals.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return totals[x] > totals[y])
	var tot := {}
	for k: String in keys.slice(0, 16):
		tot[k] = snappedf(totals[k], 0.1)
	return {"frames": _frames.size(), "worst_ms": snappedf(float(worst.get("ms", 0.0)), 0.1),
			"worst_after": worst.get("after", -1), "worst_top": _top(worst.get("prof", {}), 8),
			"stalls": stalls.size(), "stall_s": snappedf(stall_s, 0.2), "stall_frames": stalls.slice(0, 12),
			"after_mean_ms": snappedf(after_sum / maxf(after_n, 1.0), 0.1), "totals_ms": tot}


static func _top(prof: Dictionary, n: int) -> Array:
	var keys := prof.keys()
	keys.sort_custom(func(x: String, y: String) -> bool: return prof[x] > prof[y])
	var out: Array = []
	for k: String in keys.slice(0, n):
		out.append("%s %.1f" % [k, prof[k]])
	return out


func _census() -> Dictionary:
	var out := {}
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var k := n.get_class()
		if n is RigidBody3D:
			k += ":rubble" if n.is_in_group(&"rubble") else ":%s<%s>" % [n.get_parent().name if n.get_parent() else "", n.get_script().resource_path.get_file() if n.get_script() else ""]
		out[k] = int(out.get(k, 0)) + 1
		stack.append_array(n.get_children())
	return out


## RubbleSleep (#585), if this build has it (the lab runs on main's too: not named, found).
func _sleeper() -> Node:
	for n: Node in [street, get_tree().root]:
		var top: Node = n
		while top and top.get_parent() is Node3D:
			top = top.get_parent()
		var r := top.get_node_or_null(^"RubbleSleep") if top else null
		if r:
			return r
	return null


## Each tick (`awake=S`): every rubble body's sleep looked at, wakes and sleeps counted, and every
## S s the census taken.
func _track_sleep() -> void:
	if not _recording:
		return
	for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
		var id := rb.get_instance_id()
		var asleep := (rb as RigidBody3D).sleeping
		var was: Variant = _sleep_state.get(id)
		if was == null:
			_sleep_state[id] = [asleep, 0, World.now()]
			continue
		if was[0] and not asleep:
			_wakes_since += 1
			was[1] = int(was[1]) + 1
			was[2] = World.now()
		elif not was[0] and asleep:
			_sleeps_since += 1
		was[0] = asleep
	if World.now() >= _awake_next:
		_awake_next = World.now() + _awake_every
		_awake_log.append(_awake_census())


## The awake rubble now: how fast each moves (its farthest point: what Jolt's sleep test looks at),
## what it touches, the piles it's in (awake bodies joined by contact), the fastest few.
func _awake_census() -> Dictionary:
	var awake: Array[RigidBody3D] = []
	var n_all := 0
	for n: Node in get_tree().get_nodes_in_group(&"rubble"):
		n_all += 1
		if not (n as RigidBody3D).sleeping and not (n as RigidBody3D).freeze:
			awake.append(n)
	var edges := [0.01, 0.03, 0.1, 0.3, 1.0, 1e9]
	var speed_hist := [0, 0, 0, 0, 0, 0]
	var touch := {"rubble": 0, "only_other": 0, "none": 0, "in_cell": 0, "ccd": 0, "multi": 0}
	var parent := {}
	var info := []
	for rb in awake:
		var reach := RubbleRest._reach(rb)
		var ps := rb.linear_velocity.length() + rb.angular_velocity.length() * reach
		for i in edges.size():
			if ps < edges[i]:
				speed_hist[i] += 1
				break
		var cols := rb.get_colliding_bodies()
		var on_rubble := false
		for c: Node in cols:
			if c.is_in_group(&"rubble"):
				on_rubble = true
				_union(parent, rb.get_instance_id(), c.get_instance_id())
		if cols.is_empty():
			touch.none += 1
		elif on_rubble:
			touch.rubble += 1
		else:
			touch.only_other += 1
		if rb.has_meta(&"resting_in"):
			touch.in_cell += 1
		if rb.continuous_cd:
			touch.ccd += 1
		if (rb.get_meta(&"members", []) as Array).size() > 1:
			touch.multi += 1
		var st: Variant = _sleep_state.get(rb.get_instance_id())
		info.append([ps, rb, cols.size(), int(st[1]) if st else 0, World.now() - float(st[2]) if st else -1.0])
	# Piles: awake bodies joined by contact (through any rubble, asleep or not).
	var piles := {}
	var pile_fast := {}
	for e: Array in info:
		var root: int = _find(parent, (e[1] as Node).get_instance_id())
		piles[root] = int(piles.get(root, 0)) + 1
		pile_fast[root] = maxf(float(pile_fast.get(root, 0.0)), float(e[0]))
	var sizes := piles.values()
	sizes.sort()
	sizes.reverse()
	# Each pile of 10 or more: its size, its fastest body (point, linear, angular), what it touches
	# that isn't rubble and is awake (a prop, a man, a shard: Jolt keeps the island awake with it).
	var pile_rows := []
	var pile_other := {}
	for e: Array in info:
		var rb: RigidBody3D = e[1]
		var root: int = _find(parent, rb.get_instance_id())
		if int(piles[root]) < 10:
			continue
		var row: Dictionary = pile_other.get(root, {"n": piles[root], "fast": 0.0, "v": 0.0, "w": 0.0, "fast_at": [], "fast_n": 0, "other": {}})
		var ps: float = e[0]
		if ps > float(row.fast):
			row.fast = snappedf(ps, 0.001)
			row.v = snappedf(rb.linear_velocity.length(), 0.001)
			row.w = snappedf(rb.angular_velocity.length(), 0.001)
			row.fast_at = arr(rb.global_position)
		if ps >= 0.03:
			row.fast_n = int(row.fast_n) + 1
		for c: Node in rb.get_colliding_bodies():
			if c.is_in_group(&"rubble"):
				continue
			var key := "%s:%s%s" % [c.get_class(), (c.get_script() as Script).get_global_name() if c.get_script() else "", "(awake)" if c is RigidBody3D and not (c as RigidBody3D).sleeping else ""]
			if c is RigidBody3D and not (c as RigidBody3D).sleeping:
				key += " %s<%s>" % [String(c.name).left(14), String(c.get_parent().name).left(14) if c.get_parent() else ""]
			row.other[key] = int(row.other.get(key, 0)) + 1
		pile_other[root] = row
	for root: int in pile_other:
		pile_rows.append(pile_other[root])
	pile_rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x.n) > int(y.n))
	info.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	var fastest := []
	for e: Array in info.slice(0, 8):
		var rb: RigidBody3D = e[1]
		fastest.append({"ps": snappedf(e[0], 0.001), "v": snappedf(rb.linear_velocity.length(), 0.001),
				"w": snappedf(rb.angular_velocity.length(), 0.001), "reach": snappedf(RubbleRest._reach(rb), 0.01),
				"mass": snappedf(rb.mass, 0.1), "n": (rb.get_meta(&"members", []) as Array).size(), "contacts": e[2],
				"wakes": e[3], "since_wake": snappedf(e[4], 0.1), "at": arr(rb.global_position)})
	var quiet := 0  # awake, slower than Jolt's own line (0.03 m/s) at every point
	for e: Array in info:
		if float(e[0]) < 0.03:
			quiet += 1
	var woke_hist := {}
	for e: Array in info:
		var k := str(mini(int(e[3]), 5))
		woke_hist[k] = int(woke_hist.get(k, 0)) + 1
	var out := {"t": snappedf(World.now(), 0.1), "after": Engine.get_physics_frames() - _event_tick if _event_tick >= 0 else -1,
			"rubble": n_all, "awake": awake.size(), "quiet": quiet, "speed_hist": speed_hist, "touch": touch,
			"piles": sizes.size(), "pile_sizes": sizes.slice(0, 8), "wakes": _wakes_since, "sleeps": _sleeps_since,
			"woken_times": woke_hist, "fastest": fastest, "pile_rows": pile_rows.slice(0, 12),
			"other_awake": _other_awake() if awake.size() > 0 else {},
			"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS)}
	var sleeper := _sleeper()
	if sleeper:
		out["rs"] = (sleeper.get(&"counts") as Dictionary).duplicate()
		out["rs_held"] = sleeper.call(&"held_count")
		out["rs_disturbed"] = (sleeper.get(&"_disturbed") as Dictionary).size()
		var still_s := float((sleeper.get_script() as Script).get_script_constant_map().get("STILL_S", 1.5))
		var now := Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)
		var spells := [0, 0, 0]  # awake rubble: not still yet, still but near a break, still and quiet
		for e: Array in info:
			var sp: Variant = (sleeper.get(&"_still") as Dictionary).get(e[1])
			if sp == null or now - float(sp[1]) < still_s:
				spells[0] += 1
			elif sleeper.call(&"_near_disturbed", (e[1] as Node3D).global_position):
				spells[1] += 1
			else:
				spells[2] += 1
		out["rs_spells"] = spells
	_wakes_since = 0
	_sleeps_since = 0
	return out


## Awake rigid bodies that aren't rubble, by class and script (a walk of the tree: census only).
func _other_awake() -> Dictionary:
	var out := {}
	var stack: Array[Node] = [get_tree().root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is RigidBody3D and not n.is_in_group(&"rubble") and not (n as RigidBody3D).sleeping and not (n as RigidBody3D).freeze:
			var rb := n as RigidBody3D
			var key := "%s<%s> %s inner=%d" % [n.name.left(16), (n.get_script() as Script).resource_path.get_file() if n.get_script() else "", str(n.get_groups().filter(func(g: StringName) -> bool: return not String(g).begins_with("_"))), n.find_children("*", "CollisionObject3D", true, false).size()]
			var row: Dictionary = out.get(key, {"n": 0, "v": 0.0, "w": 0.0})
			row.n = int(row.n) + 1
			row.v = maxf(float(row.v), snappedf(rb.linear_velocity.length(), 0.001))
			row.w = maxf(float(row.w), snappedf(rb.angular_velocity.length(), 0.001))
			out[key] = row
		stack.append_array(n.get_children())
	return out


static func _find(parent: Dictionary, a: int) -> int:
	while parent.has(a) and parent[a] != a:
		a = parent[a]
	return a


static func _union(parent: Dictionary, a: int, b: int) -> void:
	if not parent.has(a):
		parent[a] = a
	if not parent.has(b):
		parent[b] = b
	var ra := _find(parent, a)
	var rb := _find(parent, b)
	if ra != rb:
		parent[ra] = rb


## The rubble bodies in the world, or those of them awake (moving: the physics engine's work).
func _rubble_count(awake: bool) -> int:
	var n := 0
	for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
		if not awake or not ((rb as RigidBody3D).sleeping or (rb as RigidBody3D).freeze):
			n += 1  # (frozen, held still by RubbleSleep: no work for the physics either)
	return n


## The awake rubble reporting its contacts (#626: only while it's fast; the rest settle unreported).
func _reporting() -> int:
	var n := 0
	for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
		if not (rb as RigidBody3D).sleeping and (rb as RigidBody3D).max_contacts_reported > 0:
			n += 1
	return n


func _process(_delta: float) -> void:
	if not _recording:
		return
	var now := Time.get_ticks_usec()
	var tick := Engine.get_physics_frames()
	var prof := {}
	for k: StringName in Prof._sum:
		prof[String(k)] = snappedf(float(Prof._sum[k]) / 1000.0, 0.01)
	var fire := FireSystem.find(get_tree())
	_frames.append({"tick": tick, "after": tick - _event_tick if _event_tick >= 0 else -1,
			"ms": snappedf((now - _last_us) / 1000.0, 0.01), "prof": prof,
			"ph": _phases(now),
			"hot": fire.active.size() if fire else 0, "broken": _broken,
			"set": fire._check.last_set if fire and fire._check else -1,
			"seeds": fire._check.last_seeds if fire and fire._check else -1,
			"left": fire._check.left() if fire and fire._check else -1,
			"queue": fire._to_settle.size() if fire else -1,
			"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS),
			"rubble": _rubble_count(false), "awake": _rubble_count(true), "reporting": _reporting(),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			# #626: what's drawn (0 headless): the rubble not yet in RubbleRest's cells, the cloud.
			"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"prims": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	Prof._sum.clear()
	_phys_us = 0
	# #584: twice a second, what the awake bodies are doing (outside the frame's time: the next
	# frame starts after it).
	# Rubble falling asleep and waking this frame (a pile sleeps and wakes whole: when it wakes, is
	# it on the tick after it slept, or later?).
	var slept := 0
	var woke := 0
	for n: Node in get_tree().get_nodes_in_group(&"rubble"):
		var asleep := (n as RigidBody3D).sleeping
		var was: Variant = _was_asleep.get(n.get_instance_id())
		if was != null and was != asleep:
			if asleep:
				slept += 1
			else:
				woke += 1
		_was_asleep[n.get_instance_id()] = asleep
	_frames[-1]["slept"] = slept
	_frames[-1]["woke"] = woke
	if _frames.size() % 30 == 0:
		_frames[-1]["bodies"] = _body_census()
	now = Time.get_ticks_usec()
	_last_us = now


## The awake bodies (#584): rubble and everything else the physics steps; of the rubble, how fast
## (m/s), how high over the hills' ground, how steep the ground under it, touching anything.
func _body_census() -> Dictionary:
	var rub := 0
	var speeds: Array[float] = []
	var slow := 0
	var creep := 0
	var on_ground := 0
	var steep := 0
	var touching := 0
	var spin := 0
	var gr := Ground.of(get_tree())
	var buried := 0
	for n: Node in get_tree().get_nodes_in_group(&"rubble"):
		var rb := n as RigidBody3D
		if rb == null or rb.sleeping or rb.freeze:
			continue
		rub += 1
		if gr and gr.height_at(rb.global_position.x, rb.global_position.z) > rb.global_position.y:
			buried += 1  # its middle under the dug ground's surface
		var v := rb.linear_velocity.length()
		speeds.append(v)
		if v < 0.03:
			slow += 1
		elif v < 0.2:
			creep += 1
		if rb.angular_velocity.length() > 0.5:
			spin += 1
		var p := rb.global_position
		var g := TownLayout.ground_height(p.x, p.z)
		if p.y - g < 0.35:
			on_ground += 1
			var dx := TownLayout.ground_height(p.x + 0.5, p.z) - TownLayout.ground_height(p.x - 0.5, p.z)
			var dz := TownLayout.ground_height(p.x, p.z + 0.5) - TownLayout.ground_height(p.x, p.z - 0.5)
			if Vector2(dx, dz).length() > 0.1:  # steeper than ~1 in 10
				steep += 1
		if rb.contact_monitor and rb.get_contact_count() > 0:
			touching += 1
	speeds.sort()
	# Every awake body, not only rubble (kit props, shards, ragdolls), and the fastest few: what
	# keeps an island of resting pieces awake is whatever in it still moves.
	var awake_other := 0
	var movers: Array = []
	for n: Node in street.find_children("*", "RigidBody3D", true, false):
		var rb := n as RigidBody3D
		if rb.sleeping or rb.freeze:
			continue
		var is_rubble := rb.is_in_group(&"rubble")
		if not is_rubble:
			awake_other += 1
		var v := rb.linear_velocity.length()
		var w := rb.angular_velocity.length()
		movers.append([v + 0.1 * w, rb, is_rubble])
	movers.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0])
	var top: Array = []
	for mv: Array in movers.slice(0, 6):
		var rb: RigidBody3D = mv[1]
		var p := rb.global_position
		var with: Array = []
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		for i in mini(st.get_contact_count(), 16):
			var o := st.get_contact_collider_object(i)
			var nm := String(o.name).left(14) if o else "?"
			if o is GroundTile:
				nm += "/" + ("field" if st.get_contact_collider_shape(i) == 0 else "column")
			with.append("%s n%s d%.3f" % [nm, arr(st.get_contact_local_normal(i)), st.get_contact_impulse(i).length()])
		rb.contact_monitor = true
		rb.max_contacts_reported = 16  # (all of them at the next look)
		top.append({"name": String(rb.name).left(24), "rubble": mv[2], "script": rb.get_script().resource_path.get_file() if rb.get_script() else "",
				"house": arr(Farmhouse.origin().affine_inverse() * p) if Farmhouse.of(get_tree()) else [], "v": snappedf(rb.linear_velocity.length(), 0.001),
				"w": snappedf(rb.angular_velocity.length(), 0.001), "mass": snappedf(rb.mass, 0.01),
				"over_ground": snappedf(p.y - TownLayout.ground_height(p.x, p.z), 0.01),
				"over_dug": snappedf(p.y - Ground.of(get_tree()).height_at(p.x, p.z), 0.01) if Ground.of(get_tree()) else 0.0, "touching": with})
	return {"rubble_awake": rub, "v_med": snappedf(speeds[speeds.size() / 2], 0.001) if rub else 0.0,
			"v_max": snappedf(speeds[-1], 0.01) if rub else 0.0, "under_sleep_v": slow, "creeping": creep,
			"spinning": spin, "on_ground": on_ground, "on_steep": steep, "touching": touching,
			"active": PhysicsServer3D.get_process_info(PhysicsServer3D.INFO_ACTIVE_OBJECTS),
			"awake_other": awake_other, "movers": top, "rr": _rr_counts(), "buried": buried, "ground_edits": _ground_edits, "lifted": (load("res://src/world/ground.gd") as Script).get(&"lifted"),
			"rescued": (load("res://src/world/ground.gd") as Script).get(&"rescued")}


## RubbleRest's counters (joined, woken in its cell, let go: why), summed over every one.
func _rr_counts() -> Dictionary:
	var out := {}
	for n: Node in get_tree().root.find_children("RubbleRest", "", true, false):
		if n is RubbleRest:
			for k: String in (n as RubbleRest).counts:
				out[k] = int(out.get(k, 0)) + int((n as RubbleRest).counts[k])
			out["resting"] = int(out.get("resting", 0)) + (n as RubbleRest).piece_count()
	return out


const _LATE := preload("res://experiments/blast_freeze/late_stamp.gd")


func _phases(now: int) -> Dictionary:
	if _late_us == 0 or _phys_us == 0:
		return {}
	var p := _phys_us if _phys_us > _late_us else _proc_us
	return {"late": snappedf((_late_us - _last_us) / 1000.0, 0.01), "end": snappedf((p - _late_us) / 1000.0, 0.01),
			"physics": snappedf((_proc_us - p) / 1000.0, 0.01), "early": snappedf((now - _proc_us) / 1000.0, 0.01)}
