extends TestCase
## PeopleTick (more-cores step 4): the people tick from one place, in the order they came into the
## world, each man's own nodes after him in the order the tree has them; a node's switch is still
## its own; and the first half of their tick on the worker pool is the same game as on one thread.
## Its bands (step 4b): a man far from the player ticks less often, each tick with the time he
## missed, so he walks and bleeds as he would; a man in trouble, or woken, ticks every tick.

var world: Node3D
var log_ticks: Array[String] = []


## A node of a man's with a tick of its own, as his brain, face and senses have: it notes each tick.
class Recorder:
	extends Node
	var out: Array[String]

	func _enter_tree() -> void:
		(get_parent() as HumanBody).add_ticker(self)

	func _exit_tree() -> void:
		(get_parent() as HumanBody).remove_ticker(self)

	func _ready() -> void:
		set_physics_process(true)

	func tick(_delta: float) -> void:
		out.append("%s/%s" % [get_parent().name, name])


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(300, 1, 300)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	log_ticks.clear()


func after_each() -> void:
	Settings.people_threads = Settings.PEOPLE_THREADS
	Settings.people_bands = Settings.PEOPLE_BANDS
	world.queue_free()
	await physics_frames(2)


func _man(n: String, at: Vector3, seed_value: int) -> HumanBody:
	var man := HumanBody.new()
	man.name = n
	man.rng_seed = seed_value
	man.has_gun = false
	world.add_child(man)
	man.global_position = at
	return man


func _recorder(man: HumanBody, n: String) -> Recorder:
	var r := Recorder.new()
	r.name = n
	r.out = log_ticks
	man.add_child(r)
	return r


func test_people_tick_in_the_order_they_came() -> void:
	var men: Array[HumanBody] = []
	for i in 3:
		men.append(_man("M%d" % i, Vector3(i * 2.0, 0, 0), 11 + i))
	_recorder(men[1], "A")
	_recorder(men[1], "B")
	_recorder(men[0], "A")
	_recorder(men[2], "A")
	await physics_frames(3)
	check(men[0].tick_index < men[1].tick_index and men[1].tick_index < men[2].tick_index,
			"indices in the order they came (%d, %d, %d)" % [men[0].tick_index, men[1].tick_index, men[2].tick_index])
	var tick := men[2].get_child(0, true)
	check(tick is PeopleTick, "PeopleTick stands where the last man in does (his first, internal child)")
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M0/A", "M1/A", "M1/B", "M2/A"] as Array[String], "one frame: each man in turn, his nodes in tree order")
	# His index is his for good: out of the world and back, he keeps his place.
	var was := men[0].tick_index
	world.remove_child(men[0])
	world.add_child(men[0])
	log_ticks.clear()
	await physics_frames(1)
	check_eq(men[0].tick_index, was, "kept his index")
	check_eq(log_ticks, ["M0/A", "M1/A", "M1/B", "M2/A"] as Array[String], "still first, though last in the tree now")
	check(men[2].get_child(0, true) is PeopleTick, "the node stays with the last by index")
	# A man added before the frame's ticks ticks in it, as before.
	men[1].queue_free()
	men[2].queue_free()
	men[0].queue_free()
	await physics_frames(2)
	var late := _man("M9", Vector3.ZERO, 19)
	_recorder(late, "A")
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M9/A"] as Array[String], "the first man in ticks in the frame he came")


func test_a_switch_off_is_still_his_own() -> void:
	var a := _man("M0", Vector3.ZERO, 21)
	var b := _man("M1", Vector3(2, 0, 0), 22)
	var ra := _recorder(a, "A")
	_recorder(b, "A")
	await physics_frames(2)
	ra.set_physics_process(false)
	b.process_mode = Node.PROCESS_MODE_DISABLED
	log_ticks.clear()
	await physics_frames(2)
	check_eq(log_ticks, [] as Array[String], "physics processing off, or disabled: not ticked")
	ra.set_physics_process(true)
	log_ticks.clear()
	await physics_frames(1)
	check_eq(log_ticks, ["M0/A"] as Array[String], "back on: ticked again")


## Six men, each with a wound that hurts but doesn't drop him (he favours it, his breath goes, his
## blood runs), stepped on the workers and again on one thread: every number the same.
func _run(threads: bool) -> Array:
	Settings.people_threads = threads
	var men: Array[HumanBody] = []
	for i in 6:
		men.append(_man("M%d" % i, Vector3(i * 1.5, 0, 0), 31 + i))
	await physics_frames(2)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var joules := 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity
	for i in men.size():
		var man := men[i]
		var seg: StringName = [&"thigh_r", &"upper_arm_l", &"abdomen", &"forearm_r", &"thigh_l", &"chest"][i]
		var at := (man.parts[seg] as Node3D).global_position + Vector3(0.03, 0, 0)
		var dir := -man.global_basis.z
		man.take_bullet(man.parts[seg], at - dir * 0.15, dir, joules, t.bullet_diameter * 0.5, t.bullet_mass, 5.0)
	men[2].set_pose(&"aim")
	men[4].set_pose(&"crouch")
	await physics_frames(90)
	var out := []
	for man in men:
		var rots := []
		for sid: StringName in man.pivots:
			rots.append((man.pivots[sid] as Node3D).rotation_degrees)
		out.append([man.limp, man._pose_now.duplicate(true), man._flinch.duplicate(true), man._favour.duplicate(true),
				man._breath, man.physiology.blood_ml, man.physiology.pain, man.physiology.oxygen, rots])
	for man in men:
		man.queue_free()
	await physics_frames(2)
	return out


func test_the_workers_are_the_same_game() -> void:
	var on: Array = await _run(true)
	var off: Array = await _run(false)
	var standing := 0
	for i in on.size():
		check_eq(var_to_str(on[i]), var_to_str(off[i]), "man %d: the same on the workers as on one thread" % i)
		standing += 0 if on[i][0] else 1
	check(standing >= 4, "most still standing, so their pose was worked out ahead (%d)" % standing)


# --- The bands (step 4b) ----------------------------------------------------------------------

## A node of a man's that notes each tick's delta, and (with a target) walks him there, as a brain
## does; `calm` is what it says to `can_slow`, `trouble` to `in_trouble`.
class Walker:
	extends Node
	var deltas: Array[float] = []
	var target := Vector3.INF
	var arrived_at := -1
	var frame := 0
	var calm := true
	var trouble := false

	func _enter_tree() -> void:
		(get_parent() as HumanBody).add_ticker(self)

	func _exit_tree() -> void:
		(get_parent() as HumanBody).remove_ticker(self)

	func _ready() -> void:
		set_physics_process(true)

	func can_slow() -> bool:
		return calm

	func in_trouble() -> bool:
		return trouble

	func tick(delta: float) -> void:
		deltas.append(delta)
		if target != Vector3.INF and arrived_at < 0 and (get_parent() as HumanBody).walk_to(target, 1.2, delta):
			arrived_at = frame


## The player, for the bands: only where he stands (no camera: nobody is in view).
func _player_at(at: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = "PlayerStandIn"
	p.add_to_group(&"player")
	world.add_child(p)
	p.global_position = at
	return p


func _walker(man: HumanBody) -> Walker:
	var w := Walker.new()
	w.name = "Walker"
	man.add_child(w)
	return w


func _sum(a: Array[float]) -> float:
	var t := 0.0
	for d in a:
		t += d
	return t


func test_far_men_tick_less_often_and_are_owed_the_time() -> void:
	_player_at(Vector3.ZERO)
	var near := _man("Near", Vector3(10, 0, 0), 41)
	var mid := _man("Mid", Vector3(40, 0, 0), 42)
	var far := _man("Far", Vector3(100, 0, 0), 43)
	var wn := _walker(near)
	var wm := _walker(mid)
	var wf := _walker(far)
	await physics_frames(4)
	for w in [wn, wm, wf]:
		w.deltas.clear()
	var owed_then := far.tick_owed
	await physics_frames(40)
	check_eq(near.tick_band, 0, "10 m off: near")
	check_eq(mid.tick_band, 1, "40 m off: the middle band")
	check_eq(far.tick_band, 2, "100 m off: far")
	check_eq(wn.deltas.size(), 40, "near: every tick")
	check_eq(wm.deltas.size(), 20, "middle: every 2nd")
	check_eq(wf.deltas.size(), 10, "far: every 4th")
	var step := 1.0 / Engine.physics_ticks_per_second
	check_near(wm.deltas[1], 2.0 * step, 1e-5, "a middle man's tick carries two ticks' time")
	check_near(wf.deltas[1], 4.0 * step, 1e-5, "a far man's carries four")
	check_near(_sum(wf.deltas) + far.tick_owed - owed_then, _sum(wn.deltas), 1e-4, "none of his time lost: what he ticked and what he's owed")
	# Bands off: everyone, every tick, with what they were owed.
	Settings.people_bands = false
	wf.deltas.clear()
	await physics_frames(8)
	check_eq(wf.deltas.size(), 8, "bands off: every tick")
	check_eq(far.tick_owed, 0.0, "and owed nothing")


func test_a_man_on_a_band_edge_doesnt_flicker() -> void:
	_player_at(Vector3.ZERO)
	var man := _man("Edge", Vector3(20, 0, 0), 51)
	_walker(man)
	await physics_frames(2)
	check_eq(man.tick_band, 0, "inside 25 m: near")
	var t: PeopleTickTuning = load("res://config/people_tick.tres")
	man.global_position = Vector3(t.near_m + t.margin_m * 0.5, 0, 0)
	await physics_frames(2)
	check_eq(man.tick_band, 0, "just past the edge, within the margin: still near")
	man.global_position = Vector3(t.near_m + t.margin_m + 0.5, 0, 0)
	await physics_frames(2)
	check_eq(man.tick_band, 1, "past the margin: the middle band")
	man.global_position = Vector3(t.near_m - t.margin_m * 0.5, 0, 0)
	await physics_frames(2)
	check_eq(man.tick_band, 1, "back inside the edge, within the margin: still the middle band")
	man.global_position = Vector3(t.near_m - t.margin_m - 0.5, 0, 0)
	await physics_frames(2)
	check_eq(man.tick_band, 0, "well inside: near again")


func test_a_man_in_trouble_or_woken_ticks_every_tick_and_so_does_his_neighbour() -> void:
	_player_at(Vector3.ZERO)
	var trouble := _man("Trouble", Vector3(100, 0, 0), 61)
	var by := _man("By", Vector3(104, 0, 0), 62)
	var off := _man("Off", Vector3(200, 0, 0), 63)
	var wt := _walker(trouble)
	var wb := _walker(by)
	var wo := _walker(off)
	wt.calm = false  # his brain's in a fight, or fleeing
	wt.trouble = true
	await physics_frames(4)
	for w in [wt, wb, wo]:
		w.deltas.clear()
	await physics_frames(20)
	check_eq(wt.deltas.size(), 20, "a man who can't slow: every tick")
	check_eq(wb.deltas.size(), 20, "a calm man 4 m from him: every tick (near the trouble)")
	check_eq(wo.deltas.size(), 5, "a calm man 100 m from both: every 4th")
	# Woken (he heard a shot, a deed done to him): he ticks the next tick, with what he's owed.
	wo.deltas.clear()
	await physics_frames(1)
	var ticked := wo.deltas.size()
	off.wake()
	await physics_frames(1)
	check_eq(wo.deltas.size(), ticked + 1, "woken: he ticked the next tick")
	# Down (the ragdoll is the engine's): every tick.
	wt.calm = true
	wt.trouble = false
	trouble.go_limp()
	wt.deltas.clear()
	await physics_frames(8)
	check_eq(wt.deltas.size(), 8, "limp: every tick")


## A man walks 12 m, 100 m from the player: he gets there when he would with the bands off, a
## tick or so either way, and his road is the same to the centimetre.
func _walk_far(bands: bool) -> Array:
	Settings.people_bands = bands
	_player_at(Vector3.ZERO)
	var man := _man("Walker%s" % bands, Vector3(100, 0, 0), 71)
	var w := _walker(man)
	await physics_frames(3)
	w.target = Vector3(100, 0, 12)
	var road := []
	for f in 60 * 14:
		w.frame = f
		await physics_frames(1)
		if f % 60 == 0:
			road.append(man.global_position)
	var out := [w.arrived_at, road, man.global_position]
	man.queue_free()
	await physics_frames(2)
	return out


func test_a_far_man_walks_at_the_right_speed() -> void:
	var on: Array = await _walk_far(true)
	var off: Array = await _walk_far(false)
	check(off[0] > 0 and on[0] > 0, "he got there both ways (%d, %d)" % [on[0], off[0]])
	check(absi(on[0] - off[0]) <= 4, "at the same time, within a far man's tick (%d against %d frames)" % [on[0], off[0]])
	var worst := 0.0
	for i in mini(on[1].size(), off[1].size()):
		worst = maxf(worst, (on[1][i] as Vector3).distance_to(off[1][i]))
	check(worst < 0.1, "along the same road, a second at a time (worst %.3f m)" % worst)
	check((on[2] as Vector3).distance_to(off[2]) < 0.05, "and where he stopped")


## Six wounded men 100 m off, stepped with the bands on and off: they bleed, hurt and breathe the
## same (their physiology steps with the time they were owed).
func _bleed(bands: bool) -> Array:
	Settings.people_bands = bands
	_player_at(Vector3.ZERO)
	var men: Array[HumanBody] = []
	for i in 6:
		men.append(_man("B%d" % i, Vector3(100 + i * 1.5, 0, 0), 81 + i))
	await physics_frames(2)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var joules := 0.5 * t.bullet_mass * t.muzzle_velocity * t.muzzle_velocity
	for i in men.size():
		var man := men[i]
		var seg: StringName = [&"thigh_r", &"upper_arm_l", &"abdomen", &"forearm_r", &"thigh_l", &"chest"][i]
		var at := (man.parts[seg] as Node3D).global_position + Vector3(0.03, 0, 0)
		var dir := -man.global_basis.z
		man.take_bullet(man.parts[seg], at - dir * 0.15, dir, joules, t.bullet_diameter * 0.5, t.bullet_mass, 5.0)
	await physics_frames(60 * 6)
	var out := []
	for man in men:
		out.append([man.limp, man.physiology.blood_ml, man.physiology.pain, man.physiology.oxygen, man.tick_band])
		man.queue_free()
	await physics_frames(2)
	return out


func test_a_far_man_bleeds_at_the_right_rate() -> void:
	var on: Array = await _bleed(true)
	var off: Array = await _bleed(false)
	var slowed := 0
	for i in on.size():
		check_eq(on[i][0], off[i][0], "man %d: down or up the same" % i)
		var lost_off: float = 5000.0 - float(off[i][1])
		check(absf(float(on[i][1]) - float(off[i][1])) <= maxf(2.0, 0.01 * absf(lost_off)),
				"man %d: the same blood (%.1f ml against %.1f)" % [i, on[i][1], off[i][1]])
		check_near(float(on[i][2]), float(off[i][2]), 0.02, "man %d: the same pain" % i)
		slowed += 1 if not on[i][0] else 0
	check(slowed >= 3, "most were standing far off, so slowed (%d)" % slowed)
