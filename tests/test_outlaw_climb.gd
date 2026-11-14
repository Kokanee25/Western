extends TestCase
## Going up for height (OutlawBrain's variant D `climb`, issue #572): his cover gone stale, with you
## below a gallery he can get to, he takes the stair up and fights from behind its rail. A gallery
## of boxes: a floor 3.66 m up along the far side, a rail a metre high at its front, a stair (a
## ramp) up its east end; its places joined as the spec saloon's are.

var world: Node3D
var player: Player
var outlaw: HumanBody
var brain: OutlawBrain
var places: Waypoints

const UP := 3.66
const FROM := Vector3(0.0, 0.0, -11.0)


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(80, 1, 80))  # the ground
	var b := Ballistics.new()
	world.add_child(b)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z
	await physics_frames(2)


func after_each() -> void:
	OutlawBrain._climb_tuning = null
	world.queue_free()
	await physics_frames(2)


func _box(center: Vector3, size: Vector3, layer := Layers.WORLD) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = layer
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	b.add_child(cs)
	b.position = center
	world.add_child(b)
	return b


## The gallery (x -6..9.2, z -14..-12, its floor at UP), its rail along the front to x 7.9, and
## the stair up its east end (x 8..9.2) from z -2.5 on the ground to the gallery's front at z -12.
func _gallery(stair := true) -> void:
	_box(Vector3(1.6, UP - 0.15, -13.0), Vector3(15.2, 0.3, 2.0))
	_box(Vector3(0.95, UP + 0.5, -12.04), Vector3(13.9, 1.0, 0.08))
	places = Waypoints.new()
	places.add(&"floor", Vector3(0.0, 0.0, -7.0))
	if stair:
		var run := 9.5
		var ramp := _box(Vector3(8.6, UP * 0.5 - 0.1, -2.5 - run * 0.5), Vector3(1.2, 0.2, sqrt(run * run + UP * UP)), Layers.WALK)
		ramp.rotation.x = atan2(UP, run)
		places.add(&"foot", Vector3(8.6, 0.0, -1.8), [&"floor"])
		places.add(&"head", Vector3(8.6, UP, -12.8), [&"foot"])
	places.add(&"gallery_e", Vector3(5.0, UP, -13.0), [&"head"] if stair else [])
	places.add(&"gallery_w", Vector3(-4.0, UP, -13.0), [&"gallery_e"])


func _outlaw(at: Vector3) -> void:
	outlaw = HumanBody.new()
	brain = OutlawBrain.new()
	brain.name = "Brain"
	outlaw.add_child(brain)
	world.add_child(outlaw)
	outlaw.global_position = at
	outlaw.rotation_degrees.y = 180.0
	await physics_frames(3)
	brain.variant = OutlawBrain.Variant.D
	brain.places = places
	brain.nerve = 99.0


func _exclude() -> Array[RID]:
	var out: Array[RID] = [player.get_rid()]
	for sid: StringName in outlaw.parts:
		out.append((outlaw.parts[sid] as CollisionObject3D).get_rid())
	return out


func _search(tune: ClimbTuning) -> Dictionary:
	var eye := player.camera.global_position
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var s := Cover.climb_search(world, outlaw.global_position, eye, eye + Vector3.DOWN * 1.6, _exclude(), r, places, tune)
	if not Cover.has_up(s):
		return {}
	while not s.step(40):
		pass
	return s.result


func test_the_gallery_over_you_is_cover_reached_by_the_stair() -> void:
	_gallery()
	await _outlaw(FROM)
	await physics_frames(2)
	var tune: ClimbTuning = load("res://config/climb.tres")
	var spot := _search(tune)
	check(not spot.is_empty(), "a spot up on the gallery")
	if spot.is_empty():
		return
	var at: Vector3 = spot.at
	check(absf(at.y - UP) < 0.1, "on the gallery's floor (%s)" % at)
	check(spot.get("climb", false), "marked a climb")
	check(spot.low, "behind the rail: low cover he shoots over")
	var way: Array = spot.route
	check(way.has(places.at(&"foot")) and way.has(places.at(&"head")), "by the stair, foot to head (%s)" % str(way))
	check(float(spot.way_m) <= tune.max_way, "no further than he'll run (%.1f m)" % spot.way_m)
	var space := world.get_world_3d().direct_space_state
	check(Cover.hidden_at(space, at, player.camera.global_position, Cover.HIDE_HEAD, _exclude(), true), "hidden from you down there")


## The gallery's rail as a balustrade (Railing's: 3.5 cm balusters every 15 cm, a top rail at
## 0.95 m) in place of the solid one.
func _balustrade() -> void:
	for c in world.get_children():
		if c is StaticBody3D and absf((c as Node3D).position.z + 12.04) < 0.01:
			c.queue_free()
	var x := -6.0
	while x < 7.9:
		_box(Vector3(x, UP + 0.475, -12.04), Vector3(0.035, 0.95, 0.035))
		x += 0.15
	_box(Vector3(0.95, UP + 0.975, -12.04), Vector3(13.9, 0.05, 0.08))


func test_behind_a_balustrade_up_over_you_he_is_screened() -> void:
	_gallery()
	_balustrade()
	player.global_position = Vector3(-2.0, 0.0, -6.5)  # 5.5 m short of the gallery: its floor's edge takes his hip
	await _outlaw(FROM)
	await physics_frames(2)
	var tune: ClimbTuning = load("res://config/climb.tres")
	var space := world.get_world_3d().direct_space_state
	var eye := player.camera.global_position
	var at := Vector3(0.0, UP, -13.4)
	check(not Cover.hidden_at(space, at, eye, Cover.HIDE_HEAD, _exclude(), true), "balusters don't hide a man: the lines pass between them")
	var share := Cover.screen_share(space, at, eye, _exclude())
	check(share >= tune.screen, "but ducked behind them, up over you, enough of him's screened (%.2f)" % share)
	var level := Cover.screen_share(space, at, Vector3(at.x, UP + 1.6, -4.0), _exclude())
	check(level < share, "less from up level with him: no floor's edge in the way (%.2f)" % level)
	var spot := _search(tune)
	check(absf(float((spot.get("at", Vector3.ZERO) as Vector3).y) - UP) < 0.1 and (spot.get("screen", false) or spot.get("lie", false)),
			"the search finds him a spot up there, screened or flat behind the edge (%s)" % str(spot).substr(0, 120))
	check(spot.get("low", false) and spot.get("peek", Vector3.INF) == spot.get("at", Vector3.ZERO), "he shoots over its rail where he is")
	var screened := Cover.evaluate(space, at, eye, _exclude(), true, [], false, tune.screen, eye.y - 1.6 + tune.rise)
	check(screened.get("screen", false) or screened.get("lie", false), "the spot by the rail is cover of one kind (%s)" % str(screened).substr(0, 100))
	check(Cover.evaluate(space, at, eye, _exclude(), true).is_empty() or not screened.get("screen", false), "without the screen, a balustrade alone is no cover")


func test_no_way_up_no_climb() -> void:
	_gallery(false)
	await _outlaw(FROM)
	await physics_frames(2)
	check(_search(load("res://config/climb.tres")).is_empty(), "a gallery with no stair to it: nowhere up to go")


func test_not_past_your_gun_on_the_way() -> void:
	_gallery()
	player.global_position = Vector3(8.0, 0.0, -1.0)  # by the stair's foot
	await _outlaw(FROM)
	await physics_frames(2)
	check(_search(load("res://config/climb.tres")).is_empty(), "the stair's foot by you: he doesn't run up past your gun")


func test_his_cover_stale_he_goes_up_and_fights_from_the_rail() -> void:
	_gallery()
	_box(Vector3(1.0, 0.6, -9.6), Vector3(1.4, 1.2, 0.4))  # a crate he's behind
	await _outlaw(FROM)
	var tune: ClimbTuning = (load("res://config/climb.tres") as ClimbTuning).duplicate()
	tune.chance = 1.0
	OutlawBrain._climb_tuning = tune
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()
	var space := world.get_world_3d().direct_space_state
	var eye := player.camera.global_position
	var crate := Cover.evaluate(space, Vector3(1.0, 0.0, -10.2), eye, _exclude(), true)
	check(not crate.is_empty(), "the crate is cover")
	if crate.is_empty():
		return
	brain._start_fight(player)
	await physics_frames(2)
	brain._react = 0.0
	if outlaw.gun_holstered:
		outlaw.draw_gun()
	brain._search = null
	outlaw.global_position = crate.at
	crate.eye = eye
	brain.cover = crate
	brain.tactic = OutlawBrain.Tactic.HIDDEN
	brain._tactic_time = 99.0  # no peeking: just his cover going stale
	brain._in_cover = 30.0
	var went := await wait_until(func() -> bool: return brain.decision.begins_with("go up for height"), 60 * 3)
	check(went, "his cover stale, he goes up for height (%s)" % brain.decision)
	if not went:
		return
	var up := await wait_until(func() -> bool:
		return brain.tactic == OutlawBrain.Tactic.HIDDEN and outlaw.global_position.y > UP - 0.2, 60 * 20)
	check(up, "and gets up there, behind the rail (%s, at %s)" % [brain.decision, outlaw.global_position])
	if not up:
		return
	brain._tactic_time = 0.0
	var shot := [0]
	var count := func(_o: Vector3, _d: Vector3, who: Node) -> void: if who == outlaw: shot[0] += 1
	Events.shot_fired.connect(count)
	await wait_until(func() -> bool: return shot[0] > 0, 60 * 6)
	Events.shot_fired.disconnect(count)
	check(shot[0] > 0, "and shoots down at you from it")
	check(brain._now - brain._climbed_at < tune.again_after, "not again for a while")


func test_without_the_fix_he_stays_on_his_floor() -> void:
	_gallery()
	_box(Vector3(1.0, 0.6, -9.6), Vector3(1.4, 1.2, 0.4))
	await _outlaw(FROM)
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.filter(func(f: StringName) -> bool: return f != &"climb")
	var tune: ClimbTuning = (load("res://config/climb.tres") as ClimbTuning).duplicate()
	tune.chance = 1.0
	OutlawBrain._climb_tuning = tune
	check(not brain._climb_choose(player.camera.global_position, "stale"), "no climb without `climb`")
	OutlawBrain.d_fixes = OutlawBrain.D_FIXES.duplicate()


func test_the_climb_chance_by_nerve_friends_and_hurt() -> void:
	var t: ClimbTuning = load("res://config/climb.tres")
	var calm := t.chance_now(0.5, 0.0, false, 0.0, 0.0)
	check_near(calm, t.chance, 0.001, "a calm man alone: the base chance")
	check(t.chance_now(0.5, 0.0, true, 0.0, 0.0) > calm, "more with a friend keeping you busy")
	check(t.chance_now(0.9, 0.0, false, 0.0, 0.0) > calm, "more for a hothead")
	check(t.chance_now(0.5, 0.9, false, 0.0, 0.0) < calm * 0.5, "far less near breaking")
	check(t.chance_now(0.5, 0.0, false, 0.0, 0.8) < calm * 0.5, "far less hurting")
