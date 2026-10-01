extends TestCase
## The gang fights together: they shout to each other (where you are, "Reloading! Cover me!",
## "I'm hit!"), one keeps you busy while another goes round, a friend down in the open gets dragged
## to cover, and when one goes down or gives up it goes through the rest of them. And friends'
## stray rounds don't start fights between friends, nor does a man shoot through his friend.

var world: Node3D
var ballistics: Ballistics
var player: Player
var men := {}  ## id -> HumanBody
var calls: Array[Dictionary] = []
var shots := {}


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	_box(Vector3(0, -0.5, 0), Vector3(90, 1, 90))  # the ground
	ballistics = Ballistics.new()
	world.add_child(ballistics)
	player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.global_position = Vector3.ZERO
	player.rotation = Vector3.ZERO  # facing -Z
	# Bullets stop on you without wounding: these tests are about them, and a gang that's dropped
	# you stands down.
	player.remove_meta(&"human_body")
	men.clear()
	calls.clear()
	shots.clear()
	Events.callout.connect(_on_callout)
	Events.shot_fired.connect(_on_shot)
	await physics_frames(2)


func after_each() -> void:
	Events.callout.disconnect(_on_callout)
	Events.shot_fired.disconnect(_on_shot)
	world.queue_free()
	await physics_frames(2)


func _on_callout(speaker: Node, kind: StringName, about: Node, _at: Vector3) -> void:
	calls.append({"who": (speaker as HumanBody).person_id, "kind": kind, "about": about})


func _on_shot(_o: Vector3, _d: Vector3, who: Node) -> void:
	shots[who] = int(shots.get(who, 0)) + 1


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


## Crates chest high to a crouching man.
func _crate(at: Vector3) -> void:
	_box(at + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 1.0))


## A gang member: every man here is every other man's friend.
func _man(id: StringName, at: Vector3, opts := {}) -> HumanBody:
	var m := HumanBody.new()
	m.name = String(id).capitalize()
	m.person_id = id
	m.rng_seed = 300 + men.size() * 7
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.nerve = float(opts.get("nerve", 99.0))
	b.temper = float(opts.get("temper", 0.5))
	b.leads = bool(opts.get("leads", false))
	b.proud = bool(opts.get("proud", false))
	var friends: Array[StringName] = []
	for other: StringName in opts.get("gang", [&"a", &"b", &"c"]):
		if other != id:
			friends.append(other)
	b.friends = friends
	m.add_child(b)
	world.add_child(m)
	m.global_position = at
	m.rotation_degrees.y = float(opts.get("yaw", 180.0))
	men[id] = m
	return m


func _brain(id: StringName) -> OutlawBrain:
	return (men[id] as HumanBody).get_node(^"Brain") as OutlawBrain


## A ball from you cracking past a man's head: it's a fight with you.
func _shoot_past(m: HumanBody) -> void:
	var t: RevolverTuning = load("res://config/revolver.tres")
	var ex: Array[RID] = [player.get_rid()]
	var head := m.global_position + Vector3.UP * 1.6
	var from := player.camera.global_position + Vector3(0, 0, -0.5)
	var b := ballistics.fire(from, (head + Vector3(0.9, 0.1, 0) - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
	b.shooter = player
	await wait_until(func() -> bool: return not b.alive, 90)


func _all_fighting_you(ids: Array) -> bool:
	for id: StringName in ids:
		if _brain(id).target != player:
			return false
	return true


func _called(who: StringName, kind: StringName, since := 0) -> bool:
	for i in range(since, calls.size()):
		if calls[i].who == who and calls[i].kind == kind:
			return true
	return false


func _anyone_called(kind: StringName, since := 0) -> Dictionary:
	for i in range(since, calls.size()):
		if calls[i].kind == kind:
			return calls[i]
	return {}


func _exclude_of(ids: Array) -> Array[RID]:
	var out: Array[RID] = [player.get_rid()]
	for id: StringName in ids:
		for sid: StringName in (men[id] as HumanBody).parts:
			out.append(((men[id] as HumanBody).parts[sid] as CollisionObject3D).get_rid())
	return out


## Two of them behind crates 12 m off, in a fight with you, both behind cover.
func _two_in_cover() -> void:
	_crate(Vector3(-3.0, 0, -11.0))
	_crate(Vector3(3.0, 0, -11.0))
	_man(&"a", Vector3(-3.0, 0, -12.5), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(3.0, 0, -12.5), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	await _shoot_past(men[&"a"])
	await _shoot_past(men[&"b"])
	var ok := await wait_until(func() -> bool:
		return _all_fighting_you([&"a", &"b"]) and _brain(&"a").tactic == OutlawBrain.Tactic.HIDDEN \
				and _brain(&"b").tactic == OutlawBrain.Tactic.HIDDEN, 60 * 8)
	check(ok, "both in it with you and behind their crates (%s | %s)" % [_brain(&"a").describe().substr(0, 50), _brain(&"b").describe().substr(0, 50)])


# --- Shouting to each other ---------------------------------------------------------------------------

func test_empty_he_calls_for_cover_and_his_friend_comes_up_shooting() -> void:
	await _two_in_cover()
	var a := _brain(&"a")
	var b := _brain(&"b")
	# a's last round goes on his next shot.
	a.rounds = 1
	var empty := await wait_until(func() -> bool: return a.mood == OutlawBrain.Mood.RELOADING, 60 * 10)
	check(empty, "a runs dry and reloads (%s)" % a.describe().substr(0, 60))
	check(_called(&"a", &"reloading"), "and shouts for cover: %s" % str(calls.slice(-4)))
	check(b.covering > 0.0, "b covers him (%s)" % b.describe().substr(0, 60))
	check(_called(&"b", &"covering"), "and says so")
	var b0 := int(shots.get(men[&"b"], 0))
	var a0 := int(shots.get(men[&"a"], 0))
	var up := await wait_until(func() -> bool: return b.tactic == OutlawBrain.Tactic.PEEKING, 60)
	check(up, "b's up within a second (%s)" % b.describe().substr(0, 60))
	await physics_frames(60 * 4)
	check(int(shots.get(men[&"b"], 0)) - b0 >= 2, "and keeps you busy (%d shots in 4 s)" % (int(shots.get(men[&"b"], 0)) - b0))
	check_eq(int(shots.get(men[&"a"], 0)) - a0, 0, "while a reloads behind his crate")


func test_hit_he_shouts_and_his_friend_covers_him() -> void:
	_man(&"a", Vector3(-2.0, 0, -12.0), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(2.0, 0, -12.0), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	await _shoot_past(men[&"a"])
	await wait_until(func() -> bool: return _all_fighting_you([&"a", &"b"]), 60 * 6)
	await physics_frames(30)
	var a := men[&"a"] as HumanBody
	var t: RevolverTuning = load("res://config/revolver.tres")
	var from := player.camera.global_position
	var at := (a.parts[&"upper_arm_l"] as Node3D).global_position
	var ex: Array[RID] = [player.get_rid()]
	var bullet := ballistics.fire(from, (at - from).normalized(), t.muzzle_velocity, t.bullet_mass, t.bullet_diameter, ex)
	bullet.shooter = player
	var hit := await wait_until(func() -> bool: return _called(&"a", &"hit"), 60)
	check(hit, "\"I'm hit!\" (%s; %s)" % [str(calls.slice(-3)), a.describe_wounds()])
	check(_brain(&"b").covering > 0.0, "b covers him")


func test_covering_fire_goes_where_you_were() -> void:
	await _two_in_cover()
	var b := _brain(&"b")
	# You duck behind a wall: b can't see you any more, but knows where you went.
	_box(Vector3(0, 1.2, -1.2), Vector3(4.0, 2.4, 0.3))
	await wait_until(func() -> bool: return not b.senses.sees(player), 60 * 2)
	check(not b.senses.sees(player), "b can't see you")
	var b0 := int(shots.get(men[&"b"], 0))
	Events.callout.emit(men[&"a"], &"reloading", player, Vector3.INF)
	await physics_frames(60 * 4)
	check(int(shots.get(men[&"b"], 0)) - b0 >= 1, "he still puts rounds where you were (%d; %s)" % [int(shots.get(men[&"b"], 0)) - b0, b.describe().substr(0, 60)])
	check(not b.senses.sees(player), "without seeing you")


func test_he_tells_his_friend_where_you_went() -> void:
	_man(&"a", Vector3(-2.0, 0, -12.0), {"gang": [&"a", &"b"]})
	# b looks the other way.
	_man(&"b", Vector3(2.0, 0, -12.0), {"gang": [&"a", &"b"], "yaw": 0.0})
	await physics_frames(5)
	await _shoot_past(men[&"a"])
	await wait_until(func() -> bool: return _all_fighting_you([&"a", &"b"]), 60 * 6)
	_brain(&"b").set_physics_process(false)  # stands there looking away (his senses still work)
	(men[&"b"] as HumanBody).rotation_degrees.y = 0.0
	var since := calls.size()
	player.global_position = Vector3(10.0, 0, -6.0)
	var told := await wait_until(func() -> bool: return _called(&"a", &"spotted", since), 60 * 8)
	check(told, "a shouts where you are now: %s" % str(calls.slice(-3)))
	check(not _brain(&"b").senses.sees(player), "b hasn't seen you there")
	var guess := _brain(&"b").senses.last_known(player)
	check(guess != Vector3.INF and guess.distance_to(player.global_position) < 2.0, "but knows where you are (%s vs %s)" % [str(guess), str(player.global_position)])


# --- One goes round, the other keeps you busy ---------------------------------------------------------

func test_one_goes_round_while_the_other_keeps_you_busy() -> void:
	# Something to go round to on either side.
	_crate(Vector3(-9.0, 0, -7.0))
	_crate(Vector3(9.0, 0, -7.0))
	await _two_in_cover()
	var a := _brain(&"a")
	var b := _brain(&"b")
	var a_at := (men[&"a"] as HumanBody).global_position
	a._flank_after = 0.0
	var since := calls.size()
	var went := await wait_until(func() -> bool: return _called(&"a", &"flank", since), 60 * 6)
	check(went, "a calls it (\"Keep him busy, I'm going round!\"): %s" % str(calls.slice(-4)))
	check(b.covering > 0.0, "b keeps you busy (%s)" % b.describe().substr(0, 60))
	b._flank_after = 0.0  # he'd be due to move too
	var b_moved := false
	var b0 := int(shots.get(men[&"b"], 0))
	for i in 60 * 5:
		await physics_frames(1)
		b_moved = b_moved or b.tactic == OutlawBrain.Tactic.MOVING
	check(not b_moved, "b stays put while a's going round")
	check(int(shots.get(men[&"b"], 0)) - b0 >= 2, "shooting (%d)" % (int(shots.get(men[&"b"], 0)) - b0))
	var new_at: Vector3 = a.cover.get("at", a_at)
	var ang := rad_to_deg((a_at * Vector3(1, 0, 1)).angle_to(new_at * Vector3(1, 0, 1)))
	check(ang > 20.0, "a's gone round to a new angle on you (%.0f°, %s -> %s)" % [ang, str(a_at), str(new_at)])


# --- Friends ------------------------------------------------------------------------------------------

func test_a_friends_stray_round_is_cursed_not_fought() -> void:
	_man(&"a", Vector3(-2.0, 0, -12.0), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(2.0, 0, -12.0), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	await _shoot_past(men[&"a"])
	await wait_until(func() -> bool: return _all_fighting_you([&"a", &"b"]), 60 * 6)
	var lines: Array[String] = []
	var hear := func(who: Node, text: String) -> void: if who == men[&"a"]: lines.append(text)
	Events.spoke.connect(hear)
	Events.near_miss.emit(men[&"a"], men[&"b"], 0.4, (men[&"a"] as HumanBody).global_position + Vector3(0.4, 1.5, 0), 240.0)
	Events.deed.emit(men[&"b"], &"shoot_at", men[&"a"], (men[&"b"] as HumanBody).global_position)
	await physics_frames(30)
	Events.spoke.disconnect(hear)
	var a := _brain(&"a")
	check(a.relations.stance(men[&"b"]) < Relations.Stance.FIGHT, "no fight with his friend (%s)" % str(a.relations.to_dict()))
	check_eq(a.target, player, "still on you")
	check(lines.any(func(l: String) -> bool: return l in OutlawBrain.LINES[&"watch_it"]), "\"Watch where you're shooting!\" %s" % str(lines))


func test_he_wont_shoot_through_his_friend() -> void:
	_man(&"a", Vector3(0.0, 0, -14.0), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(0.0, 0, -7.0), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	_brain(&"b").set_physics_process(false)  # stands square in a's line of fire
	await _shoot_past(men[&"a"])
	var a := _brain(&"a")
	await wait_until(func() -> bool: return a.target == player, 60 * 3)
	shots.clear()
	await physics_frames(60 * 4)
	check_eq(int(shots.get(men[&"a"], 0)), 0, "no shot with b in the way")
	check((men[&"b"] as HumanBody).wounds.is_empty(), "b's unhurt")
	(men[&"b"] as HumanBody).global_position = Vector3(4.0, 0, -7.0)
	var fired := await wait_until(func() -> bool: return int(shots.get(men[&"a"], 0)) > 0, 60 * 5)
	check(fired, "once b's out of the way, he shoots (%s)" % a.describe().substr(0, 60))


# --- Getting a friend out of it -----------------------------------------------------------------------

func test_a_friend_down_in_the_open_gets_dragged_to_cover() -> void:
	_crate(Vector3(4.0, 0, -9.0))
	_man(&"a", Vector3(-1.0, 0, -11.0), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(4.0, 0, -10.5), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	_shoot_past(men[&"a"])
	# Down before he can get to cover.
	var a := men[&"a"] as HumanBody
	await wait_until(func() -> bool: return _brain(&"a").target == player, 30)
	a.physiology.broken[&"femur_r"] = true
	var down := await wait_until(func() -> bool: return a.prone, 60)
	check(down, "a's down on his belly")
	await physics_frames(5)
	check(_called(&"a", &"help"), "and shouts for help: %s" % str(calls.slice(-4)))
	var b := _brain(&"b")
	var going := await wait_until(func() -> bool: return b.rescuing == a, 60 * 3)
	check(going, "b goes to get him (%s)" % b.describe().substr(0, 60))
	check(_called(&"b", &"drag"), "\"Hold on, I got you!\"")
	var grabbed := await wait_until(func() -> bool: return a.dragged_by == men[&"b"], 60 * 8)
	check(grabbed, "takes him by the collar (%s)" % b.describe().substr(0, 60))
	var start := OutlawBrain._lying_at(a)
	var done := await wait_until(func() -> bool: return b.rescuing == null, 60 * 20)
	check(done, "and gets him there (%s)" % b.describe().substr(0, 60))
	var space := world.get_world_3d().direct_space_state
	var at := OutlawBrain._lying_at(a)
	check(at.distance_to(start) > 1.0, "dragged him (%.1f m)" % at.distance_to(start))
	check(Cover.hidden_at(space, at, player.camera.global_position, Cover.LIE_HEAD, _exclude_of([&"a", &"b"])),
			"out of your line of fire, behind the crate (%s)" % str(at))
	check(a.dragged_by == null, "let go")
	check(a.prone and a.physiology.is_conscious(), "a's still with it")
	check_eq(b.mood, OutlawBrain.Mood.FIGHTING, "and b's back in the fight")


func test_an_unconscious_friend_gets_hauled_out_too() -> void:
	_crate(Vector3(4.0, 0, -9.0))
	_man(&"a", Vector3(-2.0, 0, -13.0), {"gang": [&"a", &"b"]})
	_man(&"b", Vector3(4.0, 0, -10.5), {"gang": [&"a", &"b"]})
	await physics_frames(5)
	_shoot_past(men[&"b"])
	_shoot_past(men[&"a"])
	await wait_until(func() -> bool: return _brain(&"a").target == player, 30)
	var a := men[&"a"] as HumanBody
	a.go_limp()  # out cold where he stood
	await wait_until(func() -> bool: return _brain(&"b").target == player, 60 * 6)
	await physics_frames(60)
	var start := (a.parts[&"chest"] as Node3D).global_position
	var b := _brain(&"b")
	var grabbed := await wait_until(func() -> bool: return a.dragged_by == men[&"b"], 60 * 10)
	check(grabbed, "b gets hold of him (%s)" % b.describe().substr(0, 60))
	await wait_until(func() -> bool: return b.rescuing == null, 60 * 20)
	var moved := (a.parts[&"chest"] as Node3D).global_position.distance_to(start)
	check(moved > 1.5, "hauled him along (%.1f m)" % moved)


# --- When one goes down, or quits -------------------------------------------------------------------

func _three() -> void:
	_man(&"a", Vector3(-4.0, 0, -12.0), {"leads": true, "nerve": 0.95, "temper": 0.2})
	_man(&"b", Vector3(0.0, 0, -12.0), {"nerve": 0.7, "temper": 0.9, "proud": true})
	_man(&"c", Vector3(4.0, 0, -12.0), {"nerve": 0.3, "temper": 0.45})
	await physics_frames(5)
	for id in [&"a", &"b", &"c"]:
		_brain(id).flee_chance = 1.0
	await _shoot_past(men[&"b"])
	var ok := await wait_until(func() -> bool: return _all_fighting_you([&"a", &"b", &"c"]), 60 * 6)
	check(ok, "all three in it")
	for id in [&"a", &"b", &"c"]:
		_brain(id).fear = 0.0


func test_a_friend_shot_down_goes_through_the_rest() -> void:
	await _three()
	var c := _brain(&"c")
	c.nerve = 99.0  # watch the fear without him breaking
	var a_fear := _brain(&"a").fear
	(men[&"c"] as HumanBody).go_limp()
	await physics_frames(3)
	var said: Dictionary = _anyone_called(&"down")
	check(not said.is_empty() and said.about == men[&"c"], "somebody shouts he's down: %s" % str(calls.slice(-4)))
	check(_brain(&"a").fear - a_fear >= 0.1, "it shakes them (a's fear %.2f -> %.2f)" % [a_fear, _brain(&"a").fear])
	var b := _brain(&"b")
	check(b.rage > 0.0, "the hothead's in a rage (%s)" % b.describe().substr(0, 70))
	await physics_frames(60 * 2)
	check(b.tactic == OutlawBrain.Tactic.OPEN, "out in the open at you, no cover")
	check(int(shots.get(men[&"b"], 0)) >= 1, "shooting (%d)" % int(shots.get(men[&"b"], 0)))


func test_the_green_one_breaks_when_his_friend_goes_down() -> void:
	await _three()
	var c := _brain(&"c")
	c.fear = 0.2
	(men[&"b"] as HumanBody).go_limp()
	var broke := await wait_until(func() -> bool: return c.mood in [OutlawBrain.Mood.FLEEING, OutlawBrain.Mood.SURRENDERED], 60 * 2)
	check(broke, "the Kid's nerve goes (%s)" % c.describe().substr(0, 60))
	check(_brain(&"a").mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING], "the leader fights on (%s)" % _brain(&"a").describe().substr(0, 60))


func test_fall_back_carries_the_frightened_ones_with_him() -> void:
	await _three()
	_brain(&"c").fear = 0.15
	_brain(&"b").fear = 0.0
	var a := _brain(&"a")
	a.fear = a.nerve + 0.1  # the leader's had enough
	var ran := await wait_until(func() -> bool: return a.mood == OutlawBrain.Mood.FLEEING, 30)
	check(ran, "the leader runs (%s)" % a.describe().substr(0, 60))
	check(_called(&"a", &"fall_back"), "\"Fall back!\": %s" % str(calls.slice(-3)))
	var followed := await wait_until(func() -> bool: return _brain(&"c").mood == OutlawBrain.Mood.FLEEING, 60 * 2)
	check(followed, "the shaky one goes with him (%s)" % _brain(&"c").describe().substr(0, 60))
	check(_brain(&"b").mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING], "the steady one stays and fights (%s)" % _brain(&"b").describe().substr(0, 60))


func test_the_leader_throws_his_gun_down_and_the_rest_follow() -> void:
	await _three()
	_brain(&"b").fear = 0.3
	_brain(&"c").fear = 0.05
	var lines: Array[String] = []
	var hear := func(who: Node, text: String) -> void: if who == men[&"b"]: lines.append(text)
	Events.spoke.connect(hear)
	_brain(&"a")._surrender()
	check(_called(&"a", &"give_up"), "\"That's it, boys. Throw 'em down.\": %s" % str(calls.slice(-3)))
	var all_up := await wait_until(func() -> bool:
		return _brain(&"b").mood == OutlawBrain.Mood.SURRENDERED and _brain(&"c").mood == OutlawBrain.Mood.SURRENDERED, 60 * 3)
	Events.spoke.disconnect(hear)
	check(all_up, "the rest give up too (%s | %s)" % [_brain(&"b").describe().substr(0, 50), _brain(&"c").describe().substr(0, 50)])
	check(lines.any(func(l: String) -> bool: return l == "A! Pick up that gun!" or l in OutlawBrain.LINES[&"scorn"]),
			"the proud one curses him first: %s" % str(lines))


func test_a_steady_man_holds_when_the_leader_quits() -> void:
	await _three()
	var b := _brain(&"b")
	b.fear = 0.0
	_brain(&"a")._surrender()
	await physics_frames(60 * 2)
	check(b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING], "b's got his nerve still (%s)" % b.describe().substr(0, 60))
