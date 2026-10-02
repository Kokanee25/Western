extends TestCase
## Bullet drop, done as it really is: every ball falls under gravity and slows in the air from the
## moment it leaves the muzzle; the sights are regulated for one range (the revolver's for 25
## yards), so the ball rises a little above your line of sight, crosses it there and falls away
## beyond: hold high at long range. The outlaws know their guns and hold over by the range they
## judge.

var world: Node3D
var ballistics: Ballistics
var player: Player
var gun: RevolverViewmodel
var shots: Array[Ballistics.Bullet] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, -100), Vector3(40, 1, 400))  # level ground, a long way
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO
	gun = player.revolver()
	gun.needs_captured_mouse = false
	gun.steady_hands = true
	gun.tuning = gun.tuning.duplicate()
	gun.tuning.spread_aim_degrees = 0.0
	gun.tuning.spread_hip_degrees = 0.0
	shots.clear()
	await physics_frames(5)
	gun.take_out()
	await wait_until(func() -> bool: return gun.is_ready_in_hand(), 60)


func after_each() -> void:
	Input.action_release(&"aim")
	world.queue_free()
	await physics_frames(2)


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


## Where the ball's path is at `distance` down range (by z), above (+) or below your line of
## sight, in metres; INF if it never got there.
func _height_at(b: Ballistics.Bullet, eye: Vector3, sight: Vector3, distance: float) -> float:
	var target := -distance
	for i in range(1, b.path.size()):
		var p0: Vector3 = b.path[i - 1]
		var p1: Vector3 = b.path[i]
		if p0.z >= target and p1.z <= target:
			var f := (p0.z - target) / maxf(p0.z - p1.z, 1e-9)
			var p := p0.lerp(p1, f)
			var on_sight := eye + sight * ((target - eye.z) / sight.z)
			return p.y - on_sight.y
	return INF


## Aim level down the range on the sights and fire one; returns the ball once it's landed.
func _fire_level() -> Array:
	Input.action_press(&"aim")
	await physics_frames(40)
	var cam := player.camera
	var eye := cam.global_position
	var sight := -cam.global_transform.basis.z
	var got: Array[Ballistics.Bullet] = []
	var grab := func(_o: Vector3, _d: Vector3, who: Node) -> void:
		if who == player and ballistics.bullets.size() > 0:
			got.append(ballistics.bullets[ballistics.bullets.size() - 1])
	Events.shot_fired.connect(grab)
	gun.cock_press()
	await physics_frames(20)
	gun.pull_trigger()
	await physics_frames(2)
	Events.shot_fired.disconnect(grab)
	if got.is_empty():
		return []
	var b := got[0]
	await wait_until(func() -> bool: return not b.alive, 60 * 3)
	return [b, eye, sight]


func test_the_ball_crosses_your_sights_at_the_zero_and_falls_away_beyond() -> void:
	var r := await _fire_level()
	check(not r.is_empty(), "it fired")
	if r.is_empty():
		return
	var b: Ballistics.Bullet = r[0]
	var h := {}
	for d in [5.0, 10.0, 15.0, 22.9, 35.0, 50.0, 75.0, 100.0]:
		h[d] = _height_at(b, r[1], r[2], d)
	print("  revolver, sights on at 25 yards, height against your line of sight (cm): %s" % ", ".join(
			h.keys().map(func(d: float) -> String: return "%d m %+.1f" % [roundi(d), float(h[d]) * 100.0])))
	check(absf(h[22.9]) < 0.01, "on at 25 yards (%+.1f cm)" % (h[22.9] * 100.0))
	check(h[10.0] > -0.03 and h[10.0] < 0.04, "a touch off at 10 m: you hit what the sights are on (%+.1f cm)" % (h[10.0] * 100.0))
	check(h[50.0] < -0.05 and h[50.0] > -0.2, "a few inches low at 50 m (%+.1f cm)" % (h[50.0] * 100.0))
	check(h[100.0] < -0.35 and h[100.0] > -0.8, "half a metre low at 100 m: hold over his head (%+.1f cm)" % (h[100.0] * 100.0))
	check(h[50.0] < h[35.0] and h[75.0] < h[50.0] and h[100.0] < h[75.0], "falling faster the further it goes")


func test_it_slows_in_the_air_as_a_real_bullet_does() -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var f50 := ballistics.flight(50.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, t.form_factor)
	var f100 := ballistics.flight(100.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, t.form_factor)
	var keep50 := float(f50.speed) / t.muzzle_velocity
	var keep100 := float(f100.speed) / t.muzzle_velocity
	print("  .45 ball: %.0f m/s at the muzzle, %.0f at 50 m (%.0f%%), %.0f at 100 m (%.0f%%); %.2f s to 100 m, falls %.0f cm" % [
			t.muzzle_velocity, f50.speed, keep50 * 100.0, f100.speed, keep100 * 100.0, f100.time, float(f100.drop) * 100.0])
	check(keep100 > 0.85 and keep100 < 0.94, "keeps about nine tenths of its speed over 100 m (%.0f%%)" % (keep100 * 100.0))
	check(float(f100.time) > 0.33 and float(f100.time) < 0.45, "takes the best part of half a second to get there (%.2f s)" % f100.time)
	# And the prediction is the flight: fire one level and see.
	var b := ballistics.fire(Vector3(0, 30, 0), Vector3.FORWARD, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	b.form = t.form_factor
	await wait_until(func() -> bool: return not b.alive or b.position.z < -100.0, 60 * 2)
	var fell := 30.0 - _height_on(b, 100.0)
	check_near(fell, float(f100.drop), 0.01, "the real ball falls what was predicted")


func _height_on(b: Ballistics.Bullet, distance: float) -> float:
	for i in range(1, b.path.size()):
		var p0: Vector3 = b.path[i - 1]
		var p1: Vector3 = b.path[i]
		if p0.z >= -distance and p1.z <= -distance:
			return p0.lerp(p1, (p0.z + distance) / maxf(p0.z - p1.z, 1e-9)).y
	return INF


func test_a_round_ball_slows_faster_than_the_revolvers_bullet() -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var conical := ballistics.flight(100.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, t.form_factor)
	var ball := ballistics.flight(100.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, 0.0)
	check(float(ball.speed) < float(conical.speed), "the round ball's draggier (%.0f vs %.0f m/s)" % [ball.speed, conical.speed])
	var s: ShotgunTuning = load("res://config/shotgun.tres")
	var pellet := ballistics.flight(40.0, s.muzzle_velocity, s.pellet_mass, s.pellet_diameter)
	check(float(pellet.speed) / s.muzzle_velocity < 0.85, "a light buckshot pellet sheds speed fast (%.0f%% at 40 m)" % (float(pellet.speed) / s.muzzle_velocity * 100.0))


func test_an_outlaw_holds_over_at_long_range() -> void:
	# A man 60 m off: had he allowed for nothing his balls would strike the dirt short; holding over
	# by the range he judges, they arrive about where he aimed.
	player.queue_free()
	var man := HumanBody.new()
	var brain := OutlawBrain.new()
	brain.name = "Brain"
	man.add_child(brain)
	world.add_child(man)
	await physics_frames(5)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var origin := Vector3(0, 1.45, 0)
	var aim := Vector3(0, 1.3, -60)
	var arrive := func(dir: Vector3) -> float:
		var b := ballistics.fire(origin, dir, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
		b.form = t.form_factor
		await wait_until(func() -> bool: return not b.alive or b.position.z < -61.0, 60 * 2)
		return _height_on(b, 60.0)
	var naive: float = await arrive.call((aim - origin).normalized())
	check(naive < 1.3 - 0.15, "aimed straight at you, it'd fall short of where he aimed (%.2f m)" % naive)
	brain.range_judgement = 0.0
	var held: float = await arrive.call(brain._held_over(ballistics, origin, aim))
	check_near(held, 1.3, 0.02, "judging the range right, he puts it where he aimed")
	brain.range_judgement = 0.12
	var worst := 0.0
	for k in 12:
		var y: float = await arrive.call(brain._held_over(ballistics, origin, aim))
		worst = maxf(worst, absf(y - 1.3))
	check(worst > 0.005 and worst < 0.15, "judging it by eye he's off a little, not a lot (worst %.0f cm)" % (worst * 100.0))


func test_the_range_has_boards_at_50_and_100_metres_in_the_clear() -> void:
	player.queue_free()
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	var spawn := street.get_node(^"OutlawSpawn") as OutlawSpawner
	if spawn and spawn.outlaw:
		spawn.outlaw.queue_free()
	var bl := street.find_child("Ballistics", true, false) as Ballistics
	var from := (street.get_node(^"DebugSpawns/Range") as Node3D).global_position + Vector3(0, 1.6, 0)
	for id in [&"target_board", &"target_board_50", &"target_board_100"]:
		var board: Structure = null
		for n in street.get_children():
			if n is Structure and (n as Structure).structure_id == id:
				board = n
		check(board != null, "%s is there" % id)
		if board == null:
			continue
		var bull := board.get_member(StringName("%s/bull" % id))
		var at := bull.global_position
		var space := street.get_world_3d().direct_space_state
		var q := PhysicsRayQueryParameters3D.create(from, at, Layers.BULLETS)
		var hit := space.intersect_ray(q)
		check(not hit.is_empty() and hit.collider is StructureMember and (hit.collider as StructureMember).member_id.begins_with(String(id)),
				"%s in the clear from the firing spot (%.0f m; hit %s)" % [id, from.distance_to(at), hit.get("collider")])
	street.queue_free()
	await physics_frames(2)



func test_the_air_thins_with_height_and_heat() -> void:
	var tu := ballistics.tuning.duplicate() as BallisticsTuning
	ballistics.tuning = tu
	check_near(tu.air_density(), 1.225, 0.005, "sea level, 15 °C: the standard 1.225 kg/m³")
	check_near(tu.speed_of_sound(), 340.3, 0.5, "sound at 340 m/s")
	check_near(tu.drag_cd(0.5 * 340.3, 0.0), 0.49, 0.01, "a round ball well under the speed of sound: Cd ~0.49")
	check(tu.drag_cd(1.07 * 340.3, 0.0) > 0.85, "just over it, nearly double (%.2f)" % tu.drag_cd(1.07 * 340.3, 0.0))
	var t: RevolverTuning = load("res://config/revolver.tres")
	var low := ballistics.flight(100.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, t.form_factor)
	tu.elevation_m = 1600.0
	tu.air_temperature_c = 30.0
	check(tu.air_density() < 1.05 and tu.air_density() > 0.95, "a mile up on a hot day the air's ~1.0 kg/m³ (%.3f)" % tu.air_density())
	check(tu.speed_of_sound() > 345.0, "and sound's faster (%.0f m/s)" % tu.speed_of_sound())
	var high := ballistics.flight(100.0, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, t.form_factor)
	check(float(high.speed) > float(low.speed), "the ball keeps more of its speed in thin air (%.0f vs %.0f m/s)" % [high.speed, low.speed])
	check(float(high.drop) < float(low.drop), "and falls a little less over 100 m (%.1f vs %.1f cm)" % [float(high.drop) * 100.0, float(low.drop) * 100.0])
