extends TestCase
## How the player's body moves (PlayerMotion and Player's momentum), for each preset on a flat
## floor: it takes a step or two to get going and to stop, heavier slower; a footfall on every
## step with the head at its low; a lean into a strafe; a dip on landing; the crouch a spring;
## switching presets takes the movement dials only. `measure()` is also what
## experiments/movement_feel/measure.gd prints for Sean.

const ACTIONS := [&"move_forward", &"move_right", &"run", &"crouch", &"jump"]

var arena: Node3D
var player: Player


func before_each() -> void:
	arena = Node3D.new()
	arena.name = "Arena"
	get_tree().root.add_child(arena)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	arena.add_child(floor_body)
	player = load("res://scenes/player.tscn").instantiate()
	arena.add_child(player)
	await physics_frames(10)


func after_each() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	arena.queue_free()
	await physics_frames(2)


func _eye_offset() -> float:
	return player.head.position.y - player.get_eye_height()


## Frames until `condition` holds (or `limit`), as seconds.
func _seconds_until(condition: Callable, limit := 600) -> float:
	for i in limit:
		if condition.call():
			return i / 60.0
		await get_tree().physics_frame
	return limit / 60.0


func _settle_still() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	await wait_until(func() -> bool: return player.get_horizontal_speed() < 0.01, 600)
	await physics_frames(60)


## Every number Sean's comparison needs, for the preset now on the player.
func measure() -> Dictionary:
	var t := player.tuning
	var m := {}
	# Getting going: to 95% of a walk, and of a full run.
	Input.action_press(&"move_forward")
	m.to_walk = await _seconds_until(func() -> bool: return player.get_horizontal_speed() >= t.walk_speed * 0.95)
	# The bob walking: the head's travel over two seconds at speed, and the steps a second.
	var lo := 9.0
	var hi := -9.0
	var falls := 0
	var at_low := 0
	var s0 := player.motion.steps
	for i in 120:
		await get_tree().physics_frame
		var y := _eye_offset()
		lo = minf(lo, y)
		hi = maxf(hi, y)
		if player.motion.footfall:
			falls += 1
			if fposmod(player.motion.steps, 1.0) < 0.12:
				at_low += 1
	m.bob_walk_cm = (hi - lo) * 100.0
	m.steps_walk = (player.motion.steps - s0) / 2.0
	m.footfalls_at_low = float(at_low) / maxf(falls, 1)
	# Stopping from a walk: how long, and how far you carry.
	var from := player.global_position
	Input.action_release(&"move_forward")
	m.stop_walk = await _seconds_until(func() -> bool: return player.get_horizontal_speed() < 0.05)
	m.carry_walk = from.distance_to(player.global_position)
	await _settle_still()
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	m.to_run = await _seconds_until(func() -> bool: return player.get_horizontal_speed() >= t.run_speed * 0.95)
	lo = 9.0
	hi = -9.0
	s0 = player.motion.steps
	for i in 120:
		await get_tree().physics_frame
		lo = minf(lo, _eye_offset())
		hi = maxf(hi, _eye_offset())
	m.bob_run_cm = (hi - lo) * 100.0
	m.steps_run = (player.motion.steps - s0) / 2.0
	from = player.global_position
	Input.action_release(&"move_forward")
	Input.action_release(&"run")
	m.stop_run = await _seconds_until(func() -> bool: return player.get_horizontal_speed() < 0.05)
	m.carry_run = from.distance_to(player.global_position)
	await _settle_still()
	player.composure.winded = 0.0
	# A strafe: the lean once he's at speed.
	Input.action_press(&"move_right")
	await physics_frames(90)
	m.strafe_lean = -rad_to_deg(player.head.rotation.z)
	Input.action_release(&"move_right")
	await _settle_still()
	# A jump: the dip on landing.
	Input.action_press(&"jump")
	await physics_frames(2)
	Input.action_release(&"jump")
	await wait_until(func() -> bool: return not player.is_on_floor(), 30)
	await wait_until(func() -> bool: return player.is_on_floor(), 120)
	var dip := 0.0
	for i in 60:
		dip = minf(dip, _eye_offset())
		await get_tree().physics_frame
	m.land_dip_cm = -dip * 100.0
	# The crouch: nine tenths of the way down, how far it sinks past, and back up.
	var drop := t.stand_eye_height - t.crouch_eye_height
	Input.action_press(&"crouch")
	m.crouch = await _seconds_until(func() -> bool: return player.get_eye_height() < t.stand_eye_height - drop * 0.9)
	var low := 9.0
	for i in 60:
		low = minf(low, player.get_eye_height())
		await get_tree().physics_frame
	m.crouch_sink_cm = maxf(0.0, t.crouch_eye_height - low) * 100.0
	Input.action_release(&"crouch")
	m.stand = await _seconds_until(func() -> bool: return player.get_eye_height() > t.crouch_eye_height + drop * 0.9)
	await physics_frames(60)
	# What it costs: the player's whole physics frame walking (Prof), and the body's motion alone.
	Prof.on = true
	Prof._sum.clear()
	Input.action_press(&"move_forward")
	await physics_frames(120)
	m.player_ms = float(Prof._sum.get(&"player", 0)) / 1000.0 / 120.0
	Prof.on = false
	Input.action_release(&"move_forward")
	var motion := PlayerMotion.new()
	var t0 := Time.get_ticks_usec()
	for i in 2000:
		motion.step(t, 1.0 / 60.0, Vector3(0.4, 0.0, -2.8), true, false, false, 0.0, 0.0)
	m.motion_us = float(Time.get_ticks_usec() - t0) / 2000.0
	await _settle_still()
	return m


func test_presets_are_light_middle_heavy() -> void:
	var got := {}
	for preset: StringName in [&"light", &"middle", &"heavy"]:
		player.set_movement(preset)
		await _settle_still()
		got[preset] = await measure()
		print("  movement %s: %s" % [preset, JSON.stringify(got[preset])])
	var l: Dictionary = got[&"light"]
	var mi: Dictionary = got[&"middle"]
	var h: Dictionary = got[&"heavy"]
	for k in ["to_walk", "to_run", "stop_walk", "stop_run", "bob_walk_cm", "land_dip_cm", "strafe_lean", "crouch", "stand"]:
		check(l[k] < mi[k] and mi[k] < h[k], "%s: light %.3f < middle %.3f < heavy %.3f" % [k, l[k], mi[k], h[k]])
	# Momentum, but not mud: a step or two to get going and to stop.
	check(mi.to_walk > 0.15 and h.to_walk < 0.8, "to a walk in 0.15-0.8 s (middle %.2f, heavy %.2f)" % [mi.to_walk, h.to_walk])
	check(h.stop_walk < 0.8, "a walking stop under 0.8 s even heavy (%.2f)" % h.stop_walk)
	for p: Dictionary in [l, mi, h]:
		check(p.footfalls_at_low > 0.95, "each footfall at the head's low (%.2f)" % p.footfalls_at_low)
		check(p.steps_walk > 2.5 and p.steps_walk < 4.0, "walking 2.5-4 steps a second (%.1f)" % p.steps_walk)
		check(p.steps_run > p.steps_walk, "quicker steps running (%.1f against %.1f)" % [p.steps_run, p.steps_walk])
		check(p.bob_run_cm > p.bob_walk_cm, "a bigger bob running (%.1f against %.1f cm)" % [p.bob_run_cm, p.bob_walk_cm])
		check(p.motion_us < 30.0, "the body's motion is cheap (%.1f µs)" % p.motion_us)


func test_footsteps_land_on_each_step() -> void:
	var heard := []
	var listen := func(_at: Vector3, _loud: float, kind: StringName, source: Node) -> void:
		if kind == &"footsteps" and source == player:
			heard.append(player.motion.steps)
	Events.noise.connect(listen)
	Input.action_press(&"move_forward")
	await physics_frames(180)
	Events.noise.disconnect(listen)
	var steps := floorf(player.motion.steps)
	check(heard.size() >= steps - 1 and heard.size() <= steps, "one footstep a step (%d for %d steps)" % [heard.size(), steps])
	for s: float in heard:
		check(fposmod(s, 1.0) < 0.2, "the sound on the footfall (step %.2f)" % s)


func test_a_turn_at_a_run_carries_you_wide_a_little() -> void:
	Input.action_press(&"move_forward")
	Input.action_press(&"run")
	await physics_frames(150)
	Events.look_input.emit(Vector2(90.0, 0.0))
	await physics_frames(1)
	var v := Vector2(player.velocity.x, player.velocity.z)
	var f := Vector2(player.get_forward().x, player.get_forward().z)
	check(v.normalized().dot(f) < 0.5, "just after a snap turn he's still going the old way")
	await physics_frames(60)
	v = Vector2(player.velocity.x, player.velocity.z)
	check(v.normalized().dot(f) > 0.98, "a second later his boots have him going the new way")


func test_the_gun_lags_a_turn() -> void:
	player.select_weapon(player.revolver())
	player.revolver().drawn = true
	await physics_frames(30)
	for i in 6:
		Events.look_input.emit(Vector2(4.0, 0.0))
		await physics_frames(1)
	check(player.motion.hand_turn.x < -0.3, "turning right the gun hangs back left (%.2f°)" % player.motion.hand_turn.x)
	await physics_frames(90)
	check(player.motion.hand_turn.length() < 0.05, "and catches up (%.3f°)" % player.motion.hand_turn.length())


func test_switching_takes_only_the_movement_dials() -> void:
	var shared := player.tuning
	var hip := shared.sway_hip
	player.set_movement(&"heavy")
	check(player.tuning != shared, "the shared config isn't changed")
	check_near(player.tuning.ground_accel, (load(Player.MOVEMENT_PRESETS[&"heavy"]) as PlayerTuning).ground_accel, 0.001, "heavy's momentum")
	check_near(player.tuning.sway_hip, hip, 0.0001, "the gun's hold kept")
	player.next_movement()
	check_eq(player.movement, &"light", "F goes heavy -> light")
	var middle := load(Player.MOVEMENT_PRESETS[&"middle"]) as PlayerTuning
	var game := load("res://config/player_tuning.tres") as PlayerTuning
	for dial in game.movement_dials():
		check(is_equal_approx(float(game.get(dial)), float(middle.get(dial))), "the game moves as middle: %s" % dial)
