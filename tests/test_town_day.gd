extends TestCase
## A day in town on the real test street: the storekeeper and the barkeep at their posts, the gang
## riding in, drinking, leaning on the storekeeper, and leaving; nobody an enemy until something
## happens. Faced down, a man backs off (and a proud one calls you out later); called out, it's a
## duel in the street, stood up, no cover; you can call a man out yourself.

var street: Node3D
var town: TownLife
var player: Player
var lines: Array[String] = []
var shots := {}


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	town = street.get_node(^"TownLife")
	town.gang_arrives = 99999.0
	town.drink_seconds = 2.0
	town.harass_seconds = 24.0
	town.after_seconds = 2.0
	add_child(street)
	await physics_frames(5)
	# Just the town's people: not the man on the range.
	var range_man := (street.get_node(^"OutlawSpawn") as OutlawSpawner).outlaw
	if range_man:
		range_man.queue_free()
	player = street.get_node(^"Player")
	# Out of the way at the east end, looking east.
	_put_player(Vector3(14.0, 0.0, -8.0), -90.0)
	lines.clear()
	shots.clear()
	Events.spoke.connect(_on_spoke)
	Events.shot_fired.connect(_on_shot)
	await physics_frames(3)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	Events.shot_fired.disconnect(_on_shot)
	street.queue_free()
	await physics_frames(2)


func _on_spoke(who: Node, text: String) -> void:
	lines.append("%s: %s" % [(who as HumanBody).person_id if who is HumanBody else &"?", text])


func _on_shot(_o: Vector3, _d: Vector3, who: Node) -> void:
	shots[who] = int(shots.get(who, 0)) + 1


func _put_player(at: Vector3, yaw: float) -> void:
	player.global_position = at
	player.rotation = Vector3(0, deg_to_rad(yaw), 0)
	player.velocity = Vector3.ZERO


func _man(id: StringName) -> HumanBody:
	for g in town.gang:
		if is_instance_valid(g) and g.person_id == id:
			return g
	return null


func _brain(id: StringName) -> OutlawBrain:
	return _man(id).get_node(^"Brain") as OutlawBrain


func _keeper() -> CivilianBrain:
	return town.storekeeper.get_node(^"Brain") as CivilianBrain


func _quicken() -> void:
	for g in town.gang:
		(g.get_node(^"Brain") as OutlawBrain).walk_speed = 3.0


func _look_at(point: Vector3) -> void:
	var to := point - player.camera.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	player.head.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


func _draw() -> void:
	var gun := player.revolver()
	gun.needs_captured_mouse = false
	gun.take_out()
	await wait_until(func() -> bool: return gun.is_ready_in_hand(), 60)


func _said(who: StringName, kind: StringName) -> bool:
	for l in OutlawBrain.LINES.get(kind, []) + CivilianBrain.LINES.get(kind, []):
		if lines.has("%s: %s" % [who, l]):
			return true
	return false


func test_the_townsfolk_mind_their_posts() -> void:
	check(town.storekeeper != null and town.barkeep != null, "a storekeeper and a barkeep")
	check(town.storekeeper.held_gun == null, "the storekeeper has no gun")
	await physics_frames(60 * 2)
	check(town.storekeeper.global_position.distance_to(town.places.at(&"store_keeper")) < 0.4, "behind his counter")
	check(town.barkeep.global_position.distance_to(town.places.at(&"behind_bar")) < 0.4, "the barkeep behind the bar")
	check_eq(_keeper().mood, CivilianBrain.Mood.CALM, "calm")


func test_the_gang_rides_in_and_drinks() -> void:
	town.drink_seconds = 60.0
	town.bring_gang()
	_quicken()
	check_eq(town.gang.size(), 3, "three riders")
	var at_bar := func() -> bool:
		for g in town.gang:
			var b := g.get_node(^"Brain") as OutlawBrain
			if g.global_position.distance_to(town.places.at(b.bar_spot)) > 0.5:
				return false
		return true
	var there := await wait_until(at_bar, 60 * 40)
	var where: Array[String] = []
	for g in town.gang:
		where.append("%s %s" % [g.person_id, str(g.global_position.snapped(Vector3.ONE * 0.1))])
	check(there, "all three at the bar: %s" % str(where))
	for g in town.gang:
		var b := g.get_node(^"Brain") as OutlawBrain
		check(g.gun_holstered, "%s's gun in its holster" % g.person_id)
		check(b.relations.stance(player) <= Relations.Stance.NOTICE, "%s pays you no mind" % g.person_id)
	check(shots.is_empty(), "no shooting")


func test_they_lean_on_the_storekeeper_and_leave_you_be() -> void:
	town.bring_gang([&"lyle", &"kid"])
	_quicken()
	var lyle := _man(&"lyle")
	var robbed := await wait_until(func() -> bool: return _keeper().mood == CivilianBrain.Mood.HANDS_UP and not lyle.gun_holstered, 60 * 60)
	check(robbed, "Lyle draws on the storekeeper, whose hands go up (%s; %s)" % [_keeper().describe().substr(0, 40), _brain(&"lyle").describe().substr(0, 60)])
	check(_said(&"lyle", &"taunt") or _said(&"kid", &"taunt"), "with some talk: %s" % str(lines.slice(-6)))
	check(_keeper().troubled_by.has(lyle), "the storekeeper knows who's troubling him")
	var done := await wait_until(func() -> bool: return lyle.gun_holstered and _brain(&"lyle").agenda.size() <= 3, 60 * 30)
	check(done, "done, gun away, on to the next thing (%d steps left)" % _brain(&"lyle").agenda.size())
	check_eq(_brain(&"lyle").relations.stance(player), Relations.Stance.IGNORE, "and you were never in it")
	check(shots.is_empty(), "nobody fired")
	var calm := await wait_until(func() -> bool: return _keeper().mood != CivilianBrain.Mood.HANDS_UP, 60 * 3)
	check(calm, "the storekeeper's hands come down when they're gone")


func test_face_the_kid_down_and_he_backs_off_and_the_storekeeper_thanks_you() -> void:
	town.harass_seconds = 120.0
	town.bring_gang([&"kid"])
	_quicken()
	var kid := _man(&"kid")
	var b := _brain(&"kid")
	var at_store := await wait_until(func() -> bool: return _keeper().troubled_by.has(kid), 60 * 50)
	check(at_store, "the Kid's at the store, leaning on him (%s)" % b.describe().substr(0, 60))
	# In at the door, gun out and on him.
	_put_player(Vector3(3.0, 0.38, 0.4), 0.0)
	await physics_frames(2)
	_look_at((kid.parts[&"chest"] as Node3D).global_position)
	await _draw()
	var aim_at_kid := func() -> bool:
		_look_at((kid.parts[&"chest"] as Node3D).global_position)
		return b.relations.entry(player).cowed
	var backed := await wait_until(aim_at_kid, 60 * 25)
	check(backed, "he backs down (%s)" % b.describe().substr(0, 80))
	check(_said(&"kid", &"back_down"), "and says so: %s" % str(lines.slice(-5)))
	check(not shots.has(kid), "without firing")
	check(kid.gun_holstered, "gun away")
	check(not b.agenda.is_empty() and b.agenda.all(func(s: Dictionary) -> bool: return s.do != &"harass"), "and gives up leaning on the storekeeper")
	check_eq(_keeper().helped_by, player, "the storekeeper saw who ran him off")
	player.revolver().toggle_holster()
	var thanked := await wait_until(func() -> bool: return _keeper().thanked, 60 * 25)
	check(thanked, "and thanks you once he's gone (%s)" % str(lines.slice(-4)))


func test_a_proud_man_calls_you_out_and_its_a_duel_in_the_street() -> void:
	town.bring_gang([&"lyle"])
	var lyle := _man(&"lyle")
	var b := _brain(&"lyle")
	b.nerve = 99.0
	b.sulk_seconds = 1.0
	b.bar_spot = &""  # sulks where he is
	lyle.global_position = Vector3(6.0, 0.0, -9.0)
	_put_player(Vector3(-6.0, 0.0, -9.0), -90.0)  # looking up the street at him
	await physics_frames(5)
	b._back_down(player)
	check_eq(b.agenda[1].do, &"call_out", "he'll be back for you")
	var called := await wait_until(func() -> bool: return _said(&"lyle", &"call_out"), 60 * 20)
	check(called, "calls you out: %s" % str(lines.slice(-4)))
	check(absf(lyle.global_position.z + 9.0) < 1.6, "from out in the street (%s)" % str(lyle.global_position))
	var d := lyle.global_position.distance_to(player.global_position)
	check(d > 8.0 and d < 16.0, "a dozen paces off (%.1f m)" % d)
	var fight := await wait_until(func() -> bool: return b.mood == OutlawBrain.Mood.FIGHTING, 60 * 10)
	check(fight, "then goes for his gun (%s)" % b.describe().substr(0, 60))
	check(_said(&"lyle", &"duel"), "after a word: %s" % str(lines.slice(-4)))
	var moved := false
	for i in 60 * 4:
		await physics_frames(1)
		moved = moved or b.tactic == OutlawBrain.Tactic.MOVING
	check(not moved, "and stands there and shoots it out, no running for cover")
	check(shots.has(lyle), "shooting at you (%d shots)" % int(shots.get(lyle, 0)))


func test_go_for_your_gun_first_and_he_goes_for_his() -> void:
	town.bring_gang([&"lyle"])
	var lyle := _man(&"lyle")
	var b := _brain(&"lyle")
	b.nerve = 99.0
	b.agenda = [{"do": &"duel", "who": player}]
	lyle.global_position = Vector3(6.0, 0.0, -9.0)
	_put_player(Vector3(-6.0, 0.0, -9.0), -90.0)
	await physics_frames(20)
	check_eq(b.mood, OutlawBrain.Mood.CALM, "face to face, waiting")
	check(lyle.gun_holstered, "hand by his holster")
	await _draw()
	var drew := await wait_until(func() -> bool: return not lyle.gun_holstered, 20)
	check(drew, "you draw, he draws")
	check_eq(b.target, player, "on you")


func test_call_a_man_out_yourself() -> void:
	town.bring_gang([&"lyle", &"kid"])
	var lyle := _man(&"lyle")
	var kid := _man(&"kid")
	for g in [lyle, kid]:
		var gb := (g as HumanBody).get_node(^"Brain") as OutlawBrain
		gb.agenda = [{"do": &"wait", "seconds": 999.0}]
	lyle.global_position = Vector3(6.0, 0.0, -9.0)
	kid.global_position = Vector3(6.0, 0.0, -4.0)
	_put_player(Vector3(-6.0, 0.0, -9.0), -90.0)
	await physics_frames(10)
	Events.shouted.emit(player, &"call_out")
	await physics_frames(5)
	check_eq(_brain(&"lyle").agenda[0].do, &"duel", "the hothead you're facing takes you up on it")
	check(_said(&"lyle", &"accept"), "and says so: %s" % str(lines.slice(-3)))
	check_eq(_brain(&"kid").agenda[0].do, &"wait", "the one you weren't facing stays out of it")
	# A cool man turns it down.
	_brain(&"kid").temper = 0.1
	_look_at((kid.parts[&"chest"] as Node3D).global_position)
	await physics_frames(2)
	_brain(&"lyle").agenda = [{"do": &"wait", "seconds": 999.0}]
	Events.shouted.emit(player, &"call_out")
	await physics_frames(5)
	check(_said(&"kid", &"refuse"), "a cooler head turns it down: %s" % str(lines.slice(-3)))


func test_shoot_one_and_his_friends_turn_on_you() -> void:
	town.bring_gang()
	for g in town.gang:
		var gb := g.get_node(^"Brain") as OutlawBrain
		gb.nerve = 99.0
		g.global_position = town.places.at(gb.bar_spot)
		gb.agenda = [{"do": &"drink", "seconds": 999.0, "face": town.places.at(gb.bar_spot) + Vector3(-2, 1.2, 0)}]
		gb._step_started = false
	_put_player(Vector3(7.0, 0.38, -18.6), 0.0)
	await physics_frames(30)
	var brody := _man(&"brody")
	var at := (brody.parts[&"thigh_r"] as Node3D).global_position
	var bl := street.find_child("Ballistics", true, false) as Ballistics
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ex: Array[RID] = [player.get_rid()]
	var from := player.camera.global_position
	var bullet := bl.fire(from, (at - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
	bullet.shooter = player
	var all_in := func() -> bool:
		for g in town.gang:
			if (g.get_node(^"Brain") as OutlawBrain).target != player:
				return false
		return true
	var fought := await wait_until(all_in, 60 * 4)
	var how: Array[String] = []
	for g in town.gang:
		how.append((g.get_node(^"Brain") as OutlawBrain).describe().substr(0, 50))
	check(fought, "all three on you: %s" % str(how))


func test_they_ride_out() -> void:
	town.bring_gang([&"kid"])
	var kid := _man(&"kid")
	var b := _brain(&"kid")
	b.walk_speed = 3.0
	b.agenda = [{"do": &"leave"}]
	b._step_started = false
	kid.global_position = town.places.at(&"street_west")
	var gone := [false]
	b.left_town.connect(func() -> void: gone[0] = true)
	var left := await wait_until(func() -> bool: return gone[0], 60 * 15)
	check(left, "walks out west and is gone")
	await physics_frames(2)
	check(not is_instance_valid(kid), "out of the world")
