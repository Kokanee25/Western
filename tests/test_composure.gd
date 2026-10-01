extends TestCase
## Your hands aren't a tripod: the gun wanders (more from the hip, winded, or rattled; less
## crouched or once you've held the sights still) and the shot goes where the barrel points. A
## ball past your ear makes you flinch and rounds coming in rattle you, and you hear each one
## snap past, from the side it went by.

const ACTIONS := [&"move_forward", &"run", &"crouch", &"aim"]

var world: Node3D
var player: Player
var gun: RevolverViewmodel
var shot_dirs: Array[Vector3] = []
var ballistics: Ballistics


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(200, 1, 200))  # the ground
	_box(Vector3(0, 2, -40), Vector3(40, 4, 1))  # a wall to shoot at
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	gun = player.revolver()
	gun.needs_captured_mouse = false
	# Spread off: what's left is the sway.
	gun.tuning = gun.tuning.duplicate()
	gun.tuning.spread_aim_degrees = 0.0
	gun.tuning.spread_hip_degrees = 0.0
	shot_dirs.clear()
	Events.shot_fired.connect(_on_shot)
	await physics_frames(5)
	gun.take_out()
	await wait_until(func() -> bool: return gun.is_ready_in_hand(), 60)


func after_each() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	Events.shot_fired.disconnect(_on_shot)
	world.queue_free()
	await physics_frames(2)


func _on_shot(_o: Vector3, d: Vector3, who: Node) -> void:
	if who == player:
		shot_dirs.append(d)


func _box(center: Vector3, size: Vector3) -> StaticBody3D:
	var b := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = center
	world.add_child(b)
	return b


## The furthest the barrel wanders off your line of sight over a few seconds (degrees).
func _wander(seconds: float) -> float:
	# The same stretch of its wandering each time, so windows compare.
	gun._sway_time = 0.0
	gun._breath_phase = 0.0
	var most := 0.0
	for i in int(seconds * 60.0):
		await process_frames(1)
		most = maxf(most, gun.sway.length())
	return most


# --- The gun wanders ------------------------------------------------------------------------------------

func test_the_shot_goes_where_the_barrel_points() -> void:
	Input.action_press(&"aim")
	await physics_frames(20)
	var cam := player.camera
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 3:
		gun.cock_press()
		await physics_frames(20)
		if k > 0:
			gun.jerk(1.2, rng)  # well off line, so which side it went is plain
			await process_frames(1)
		var sway := gun.sway
		var look := -cam.global_transform.basis.z
		# Where the barrel would point with steady hands (the sights' zero raises it a touch).
		var held := gun.zeroed(gun.model.muzzle.global_position, cam.global_position, look, gun._load())
		gun.pull_trigger()
		await physics_frames(30)
		check_eq(shot_dirs.size(), k + 1, "it fired")
		if shot_dirs.size() <= k:
			return
		var off := rad_to_deg(held.angle_to(shot_dirs[k]))
		check(sway.length() > 0.02, "the barrel's off your line of sight (%.2f°)" % sway.length())
		check_near(off, sway.length(), 0.08, "and the ball goes that far off it")
		# And the same way: right is right, up is up.
		var right := cam.global_transform.basis.x
		if k > 0:
			check(signf(shot_dirs[k].dot(right)) == signf(sway.x) or absf(sway.x) < 0.1, "the same side (sway %s)" % str(sway))
			check(signf(shot_dirs[k].dot(cam.global_transform.basis.y) - held.dot(cam.global_transform.basis.y)) == signf(sway.y) \
					or absf(sway.y) < 0.1, "up is up (sway %s)" % str(sway))


func test_it_wanders_less_on_the_sights_and_less_still_crouched() -> void:
	var hip := await _wander(4.0)
	Input.action_press(&"aim")
	await physics_frames(60)  # settle
	var aim := await _wander(4.0)
	Input.action_press(&"crouch")
	await physics_frames(60)
	check(player.is_crouching, "crouched")
	var crouched := await _wander(4.0)
	check(hip > aim * 2.0, "from the hip it wanders far more (%.2f° vs %.2f°)" % [hip, aim])
	check(aim > 0.15 and aim < 0.8, "on the sights, a fraction of a degree: enough to miss a head at 20 m (%.2f°)" % aim)
	check(crouched < aim * 0.8, "crouched it's steadier (%.2f° vs %.2f°)" % [crouched, aim])


func test_raising_the_sights_takes_a_moment_to_settle() -> void:
	Input.action_press(&"aim")
	await physics_frames(2)
	check(gun.steady < 0.1, "just up")
	await physics_frames(70)
	check(gun.steady > 0.9, "held still a second (%.2f s)" % gun.steady)
	gun.cock_press()
	await physics_frames(20)
	gun.pull_trigger()
	await physics_frames(1)
	check(gun.steady < 0.1, "the shot unsettles it (%.2f s)" % gun.steady)


func test_running_leaves_you_winded() -> void:
	Input.action_press(&"aim")
	await physics_frames(60)
	var calm := await _wander(4.0)
	Input.action_release(&"aim")
	Input.action_press(&"run")
	Input.action_press(&"move_forward")
	await physics_frames(60 * 5)
	Input.action_release(&"move_forward")
	Input.action_release(&"run")
	var c := player.composure
	check(c.winded > 0.6, "winded (%s)" % c.describe())
	await physics_frames(20)
	Input.action_press(&"aim")
	await physics_frames(60)
	var blown := await _wander(3.0)
	check(blown > calm * 1.4, "the sights heave with your breathing (%.2f° vs %.2f° calm)" % [blown, calm])
	await physics_frames(60 * 12)
	check(c.winded < 0.1, "and you get your breath back (%s)" % c.describe())


# --- Under fire ---------------------------------------------------------------------------------------

## A ball from an outlaw 25 m off going past your head, `miss` metres to the side.
func _shot_past(miss: float, speed := 240.0) -> void:
	var bl := ballistics
	var head := player.camera.global_position
	var from := Vector3(-6.0, 1.6, -25.0)
	var past := head + Vector3(miss, 0.0, 0.0)
	var b := bl.fire(from, (past - from).normalized(), speed, 0.0165, 0.0114, [])
	await wait_until(func() -> bool: return not b.alive or b.position.z > 2.0, 60 * 2)


func test_a_ball_past_your_ear_makes_you_flinch() -> void:
	Input.action_press(&"aim")
	await physics_frames(60)
	var c := player.composure
	var yaw := player.rotation.y
	var pitch := player.get_pitch_degrees()
	var misses := [0]
	var count := func(who: Node, _s: Node, _d: float, _at: Vector3, _v: float, _t: bool) -> void: if who == player: misses[0] += 1
	Events.near_miss.connect(count)
	await _shot_past(0.5)
	Events.near_miss.disconnect(count)
	check_eq(misses[0], 1, "it went by close")
	check(c.flinch > 0.4, "you flinch (%s)" % c.describe())
	var jolt := absf(rad_to_deg(player.rotation.y - yaw)) + absf(player.get_pitch_degrees() - pitch)
	check(jolt > 0.2, "the view jolts (%.2f°)" % jolt)
	check(gun.sway.length() > 0.5, "the gun jerks off line (%.2f°)" % gun.sway.length())
	check(gun._wobble() > 0.8, "and a shot now would go wide (%.2f° spread)" % gun._wobble())
	await physics_frames(90)
	check(c.flinch < 0.05, "a second later it's passed (%s)" % c.describe())
	check(gun.sway.length() < 0.8, "the gun's back on (%.2f°)" % gun.sway.length())


func test_rounds_coming_in_rattle_you_until_its_quiet() -> void:
	Input.action_press(&"aim")
	await physics_frames(60)
	var calm := await _wander(3.0)
	var misses := [0]
	var count := func(who: Node, _s: Node, _d: float, _at: Vector3, _v: float, _t: bool) -> void: if who == player: misses[0] += 1
	Events.near_miss.connect(count)
	for k in 5:
		await _shot_past(0.8 + 0.2 * k)
		await physics_frames(20)
	Events.near_miss.disconnect(count)
	check_eq(misses[0], 5, "five went by")
	var c := player.composure
	check(c.rattled > 0.6, "rattled (%s)" % c.describe())
	await physics_frames(60)
	var shaken := await _wander(3.0)
	check(shaken > calm * 1.6, "the gun won't keep still (%.2f° vs %.2f° calm)" % [shaken, calm])
	await physics_frames(60 * 12)
	check(c.rattled < 0.1, "once it's been quiet a while you steady (%s)" % c.describe())


func test_a_round_into_the_wall_by_your_head_counts_your_own_dont() -> void:
	var wall := _box(Vector3(1.0, 1.5, -1.2), Vector3(1.0, 3.0, 0.2))
	var c := player.composure
	var bl := ballistics
	# Your own shot into a wall right in front of you: nothing.
	var eye := player.camera.global_position
	var own := bl.fire(eye + Vector3(0.6, 0, -0.3), Vector3(0.1, 0, -1).normalized(), 240.0, 0.0165, 0.0114, [player.get_rid()])
	own.shooter = player
	await wait_until(func() -> bool: return not own.alive, 30)
	check(c.flinch < 0.05, "your own round going out doesn't rattle you (%s)" % c.describe())
	# Theirs smacking into it beside your head, coming at you.
	var from := Vector3(1.0, 1.6, -25.0)
	var b := bl.fire(from, (Vector3(1.0, eye.y, -1.1) - from).normalized(), 240.0, 0.0165, 0.0114, [])
	await wait_until(func() -> bool: return not b.alive, 60 * 2)
	check(c.flinch > 0.3, "theirs into the post by your head does (%s)" % c.describe())
	wall.queue_free()


# --- What you hear --------------------------------------------------------------------------------------

func test_you_hear_it_go_by_from_where_it_went() -> void:
	var fx := ImpactEffects.new()
	world.add_child(fx)
	var passes: Array[Array] = []
	var note := func(who: Node, _s: Node, _d: float, at: Vector3, v: float, _t: bool) -> void: if who == player: passes.append([at, v])
	Events.near_miss.connect(note)
	await _shot_past(0.7)  # a revolver ball
	Events.near_miss.disconnect(note)
	check_eq(passes.size(), 1, "it went by")
	if passes.is_empty():
		return
	var at: Vector3 = passes[0][0]
	check(at.x > player.global_position.x + 0.3, "on your right, where it went by (%s)" % str(at))
	var sound: AudioStreamPlayer3D = null
	for n in fx.get_children():
		if n is AudioStreamPlayer3D and (n as AudioStreamPlayer3D).stream == SynthSounds.get_sound(&"crack"):
			sound = n
	check(sound != null, "it snaps past")
	if sound:
		check((sound.global_position as Vector3).distance_to(at) < 0.01, "from where it passed")
	for id in [&"crack", &"zip"]:
		check((SynthSounds.get_sound(id) as AudioStreamWAV).data.size() > 1000, "%s is a real sound" % id)
