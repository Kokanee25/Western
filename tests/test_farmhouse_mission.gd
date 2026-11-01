extends TestCase
## The farmhouse hostage rescue (issue #520; src/missions/farmhouse_mission.gd): started, the
## gang's men are at their posts in the house and calm, the rancher tied in his chair; a shot
## raises the alarm and they fight, keeping to the house; E held by the rancher cuts him loose and
## he follows; the guard puts his gun on him when it goes badly. And #488's gap: an outlaw a blast
## hurts reacts to the blast, not as if shot.

var street: Node3D
var town: TownLife
var player: Player
var mission: FarmhouseMission
var lines: Array[String] = []


func before_each() -> void:
	street = load("res://scenes/test_street.tscn").instantiate()
	town = street.get_node(^"TownLife")
	add_child(street)
	await physics_frames(5)
	var range_man := (street.get_node(^"OutlawSpawn") as OutlawSpawner).outlaw
	if range_man:
		range_man.queue_free()
	player = street.get_node(^"Player")
	mission = street.get_node(^"FarmhouseMission")
	lines.clear()
	Events.spoke.connect(_on_spoke)
	await physics_frames(3)


func after_each() -> void:
	Events.spoke.disconnect(_on_spoke)
	street.queue_free()
	await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	lines.append("%s: %s" % [who.name, text])


func _begin() -> void:
	mission.begin(true)
	await physics_frames(60)


func test_it_starts_with_the_men_at_their_posts_and_the_rancher_tied() -> void:
	await _begin()
	check_eq(mission.state, FarmhouseMission.State.ON, "it's on")
	check_eq(mission.brains.size(), 5, "five men")
	check(town.gang_came(), "the gang won't ride into town: they're out there")
	for b in mission.brains:
		check_eq(b.mood, OutlawBrain.Mood.CALM, "%s calm before the alarm" % b.body.name)
		check(b.body.global_position.distance_to(b.hold.post) < 1.2, "%s at his post (%.1f m off)" % [b.body.name, b.body.global_position.distance_to(b.hold.post)])
	check(mission.guard != null and FarmhouseMission.inside_bedroom(mission.guard.body.global_position), "the guard in the bedroom")
	check(mission.hostage_brain.tied, "the rancher tied")
	check(mission.hostage_brain.chair != null and mission.hostage_brain.chair.seated == mission.hostage, "in his chair")
	check(player.global_position.distance_to(town.places.at(&"road_east")) < 1.0, "you at the edge of town")
	check(not FarmhouseMission.inside(player.global_position), "outside the house")


func test_a_shot_raises_the_alarm_and_they_keep_to_the_house() -> void:
	await _begin()
	# A shot from the yard, by the house.
	player.global_position = Farmhouse.on_ground(4.0, -7.0) + Vector3.UP * 0.05
	await physics_frames(10)
	Events.noise.emit(player.global_position, 120.0, &"gunshot", player)
	Events.shot_fired.emit(player.global_position + Vector3.UP * 1.5, Vector3.UP, player)
	await physics_frames(30)
	check(mission.alarm_t >= 0.0, "the alarm's up (%s)" % [mission.timeline])
	var fighting := mission.brains.filter(func(b: OutlawBrain) -> bool: return b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING])
	check(fighting.size() >= 4, "they're in it (%d)" % fighting.size())
	# Out of sight round the back, a while: they stay in.
	player.global_position = Farmhouse.on_ground(4.0, 30.0) + Vector3.UP * 0.05
	await physics_frames(60 * 12)
	for b in mission.brains:
		if b.body.physiology.alive and b.mood != OutlawBrain.Mood.FLEEING:
			check(FarmhouseMission.inside(b.body.global_position), "%s still in the house" % b.body.name)


func test_e_held_by_him_cuts_him_loose_and_he_follows() -> void:
	await _begin()
	# The men elsewhere (their senses on you would start the fight: not what this is about).
	for b in mission.brains:
		b.body.process_mode = Node.PROCESS_MODE_DISABLED
	var h := mission.hostage
	var side := (h.global_position - Farmhouse.at(Vector3(7.3, 0.0, 0.0)))
	player.global_position = h.global_position + Vector3(0.0, 0.05, 0.0) + side.normalized() * -0.9
	await physics_frames(3)
	check(mission.claims_use(player), "E is for him here")
	Input.action_press(&"shove")
	await physics_frames(int(mission.tuning.free_hold * 60.0) + 20)
	Input.action_release(&"shove")
	check(not mission.hostage_brain.tied, "cut loose")
	check(mission.hostage_brain.follow == player, "following you")
	check(player.shove.move == &"", "not a shove or a kick")
	# You walk off a few metres: he comes after you.
	player.global_position = Farmhouse.at(Vector3(3.3, Farmhouse.FLOOR, 1.4)) + Vector3.UP * 0.05
	await physics_frames(2)
	var gap := h.global_position.distance_to(player.global_position)
	await physics_frames(60 * 6)
	var now := h.global_position.distance_to(player.global_position)
	check(now < 3.0 and now < gap - 1.0, "he's come after you through the bedroom door (%.1f m off, was %.1f)" % [now, gap])


func test_the_guard_holds_his_gun_on_him_when_it_goes_badly() -> void:
	await _begin()
	player.global_position = Farmhouse.on_ground(4.0, -7.0) + Vector3.UP * 0.05
	mission._alarm(null, player.global_position, "the test")
	# Two of them out of it.
	var others := mission.brains.filter(func(b: OutlawBrain) -> bool: return b != mission.guard)
	for b: OutlawBrain in others.slice(0, mission.tuning.bad_fight_down):
		b.body.physiology.alive = false
		b.body.go_limp(Vector3.ZERO)
	await physics_frames(60 * 3)
	check(mission.threat_t >= 0.0, "he threatens (%s)" % [mission.timeline])
	check(mission.guard.menace == mission.hostage, "his gun on the rancher")
	check(mission.execute_t < 0.0, "not shot: you're not in the house")
	check(lines.any(func(l: String) -> bool: return l.begins_with("Brody") and (OutlawBrain.LINES[&"menace"] as Array).any(func(m: String) -> bool: return l.ends_with(m))),
			"he says so: %s" % [lines.slice(-6)])


func test_a_man_a_blast_hurts_takes_it_as_a_blast_not_a_ball() -> void:
	await _begin()
	var b: OutlawBrain = mission.brains[1]
	var said_hit := []
	var on_call := func(speaker: Node, kind: StringName, _about: Node, _at: Vector3) -> void:
		if speaker == b.body and kind == &"hit":
			said_hit.append(kind)
	Events.callout.connect(on_call)
	b.relations.provoke(player)
	await physics_frames(30)
	# A stick a metre and a half off him.
	var info := b.body.take_blast(b.body.global_position + Vector3(1.5, 0.3, 0.0), 0.2)
	await physics_frames(3)
	Events.callout.disconnect(on_call)
	check(not (info.get("harm", []) as Array).is_empty(), "it hurt him: %s" % [info.get("harm")])
	check(b.stunned > 0.0, "dazed by it (%.1f s)" % b.stunned)
	check(said_hit.is_empty(), "no \"I'm hit!\" call")
	check(not lines.any(func(l: String) -> bool: return (OutlawBrain.LINES[&"hit"] as Array).any(func(m: String) -> bool: return l.ends_with(m))),
			"no \"I'm hit\": %s" % [lines.slice(-4)])


func test_on_the_alarm_they_man_the_windows_on_your_side() -> void:
	await _begin()
	# Seen out front, on the lane.
	player.global_position = Farmhouse.on_ground(3.0, -9.0) + Vector3.UP * 0.05
	await physics_frames(2)
	mission._alarm(mission.brains[3], player.global_position, "the test")
	await physics_frames(60 * 3)
	check_eq(mission.defence.where, "front", "they have you out front")
	var spots := {}
	for b in mission.brains:
		spots[String(b.order.get("id", ""))] = b.body.name
	check(spots.has("window_front_w") and spots.has("window_front_e"), "both front windows manned: %s" % [spots])
	check(spots.has("inside_door"), "a man on the front door: %s" % [spots])
	check(mission.guard.order.get("id", "") == "bedroom_door", "the guard on the bedroom's door (%s)" % mission.guard.order.get("id", ""))
	# Round the back, a while: the plan follows you.
	player.global_position = Farmhouse.on_ground(4.0, 14.0) + Vector3.UP * 0.05
	for b in mission.brains:
		b.senses.note(player, player.global_position, 0.5)
	await physics_frames(60 * 3)
	check_eq(mission.defence.where, "back", "they have you round the back")
	var back := mission.brains.filter(func(b: OutlawBrain) -> bool: return b.order.get("id", "") in ["window_back", "kitchen_crates"])
	check(back.size() >= 2, "the back window and the back door covered (%d)" % back.size())


func test_with_three_out_the_rest_fall_back_to_the_bedroom() -> void:
	await _begin()
	player.global_position = Farmhouse.on_ground(3.0, -9.0) + Vector3.UP * 0.05
	await physics_frames(2)
	mission._alarm(null, player.global_position, "the test")
	await physics_frames(30)
	var others := mission.brains.filter(func(b: OutlawBrain) -> bool: return b != mission.guard)
	# A steady last man (three friends dying round him, a man of ordinary nerve gives up or runs).
	(others[3] as OutlawBrain).nerve = 9.0
	for b: OutlawBrain in others.slice(0, 3):
		b.body.physiology.alive = false
		b.body.go_limp(Vector3.ZERO)
	await physics_frames(60 * 2)
	check(mission.defence.last_stand, "the last stand")
	var last: OutlawBrain = others[3]
	check(String(last.order.get("id", "")) in ["bedroom_corner", "bedroom_bed"], "the last of them to the bedroom (%s)" % last.order.get("id", ""))
	check(lines.any(func(l: String) -> bool: return (HouseDefence.CALLS["last_stand"] as Array).any(func(m: String) -> bool: return l.ends_with(m))),
			"someone calls it: %s" % [lines.slice(-6)])


func test_seen_a_way_off_with_your_gun_away_you_are_warned_off_not_shot() -> void:
	await _begin()
	player.global_position = Farmhouse.on_ground(3.0, -40.0) + Vector3.UP * 0.05
	if player.weapon:
		player.weapon.drawn = false
	await physics_frames(2)
	var kid: OutlawBrain = mission.brains[3]
	mission._seen(kid, player)
	await physics_frames(30)
	check(mission.warned_t >= 0.0, "warned off (%s)" % [mission.timeline])
	check(mission.alarm_t < 0.0, "not the alarm, not yet")
	check(mission.brains.any(func(b: OutlawBrain) -> bool: return b.hold.get("warned", false)), "men to the windows on your side")
	check(lines.any(func(l: String) -> bool: return l.begins_with("Kid:")), "the Kid calls it: %s" % [lines.slice(-4)])
	# Come on in close: the alarm.
	player.global_position = Farmhouse.on_ground(3.0, -6.0) + Vector3.UP * 0.05
	await physics_frames(2)
	mission._seen(kid, player)
	await physics_frames(5)
	check(mission.alarm_t >= 0.0, "closer than they'll have you: the alarm")


func test_an_out_cold_rancher_is_cut_loose_and_dragged_out() -> void:
	await _begin()
	var h := mission.hostage
	h.go_limp(Vector3.ZERO)
	await physics_frames(60)
	player.global_position = mission.hostage_at() + Vector3(0.0, -0.2, 0.0) + (Farmhouse.at(Vector3(6.0, 0.0, 3.0)) - Farmhouse.at(Vector3(7.3, 0.0, 2.5))).normalized() * 0.9
	player.global_position.y = Farmhouse.at(Vector3(0, Farmhouse.FLOOR, 0)).y + 0.05
	await physics_frames(3)
	check(mission.claims_use(player), "E is for him, out cold as he is")
	Input.action_press(&"shove")
	await physics_frames(int(mission.tuning.free_hold * 60.0) + 20)
	check(not mission.hostage_brain.tied, "cut loose")
	var from := mission.hostage_at()
	# Backing off toward the bedroom door with E held: he comes along by the collar.
	for i in 90:
		player.global_position = player.global_position.move_toward(Farmhouse.at(Vector3(6.2, Farmhouse.FLOOR, 3.2)) + Vector3.UP * 0.05, 1.0 / 60.0)
		await physics_frames(1)
	Input.action_release(&"shove")
	check(mission.hostage_at().distance_to(from) > 0.5, "dragged (%.2f m)" % mission.hostage_at().distance_to(from))
	check(player.shove.move == &"", "not a shove or a kick")


## The surprise assault (issue #537, Sean): a stick set on the kitchen's back wall without them
## knowing. Its hiss isn't heard inside (Hollis is a metre and a half from it, through the wall),
## so there's no alarm before it; the wall going up is the alarm, and they're caught cold: dazed,
## nobody calling where you are, nobody knowing it, till one of them sees you or you fire.
func test_a_stick_they_never_heard_is_a_surprise() -> void:
	await _begin()
	# You in the hiding spot round the lean-to's corner (out of sight of every window and door).
	player.global_position = Farmhouse.on_ground(-0.9, 6.6) + Vector3.UP * 0.05
	await physics_frames(10)
	var eye := Farmhouse.on_ground(2.9, 8.3) + Vector3.UP * 1.6
	var to := Farmhouse.at(Vector3(2.9, 0.0, 7.6))
	to.y = eye.y - 0.4
	var spot := DynamiteViewmodel.plant_spot(World.space(street), eye, (to - eye).normalized(), 2.2, [player.get_rid()])
	check(not spot.is_empty(), "the kitchen's back wall in reach")
	if spot.is_empty():
		return
	var s := DynamiteStick.make(street, spot.at, Vector3.ZERO, 3.0)
	s.owner_node = player
	s.global_basis = spot.basis
	s.stick_to(spot.collider)
	s.light()
	await physics_frames(int(2.8 * 60))
	check_eq(mission.alarm_t, -1.0, "no alarm while it burns (%s)" % [mission.timeline])
	check(not lines.any(func(l: String) -> bool: return l.contains("hiss")), "nobody heard it hiss: %s" % [lines.slice(-3)])
	await wait_until(func() -> bool: return mission.breach_t >= 0.0, 60)
	await physics_frames(2)
	check(mission.surprise_t >= 0.0 and is_equal_approx(mission.alarm_t, mission.surprise_t), "the blast's the alarm (%s)" % [mission.timeline])
	check(not mission.timeline.any(func(e: Array) -> bool: return String(e[1]).begins_with("the alarm: ")), "not raised by what it broke or whom it hit")
	var dazed := mission.brains.filter(func(b: OutlawBrain) -> bool: return b.body.physiology.is_conscious() and b.mood != OutlawBrain.Mood.SURRENDERED)
	check(not dazed.is_empty() and dazed.all(func(b: OutlawBrain) -> bool: return b.stunned > 0.0), "every man still in it dazed")
	check(mission.defence.quiet, "nobody calls where you are")
	await physics_frames(60 * 3)
	var calls: Array = []
	for place: String in HouseDefence.CALLS:
		if place != "last_stand":
			calls.append_array(HouseDefence.CALLS[place])
	check(not lines.any(func(l: String) -> bool: return calls.any(func(c: String) -> bool: return l.ends_with(c))), "no \"Round back!\": %s" % [lines.slice(-5)])
	check_eq(mission.found_t, -1.0, "they don't know where you are")
	# You fire: now they do.
	Events.shot_fired.emit(player.global_position + Vector3.UP * 1.5, Vector3.UP, player)
	await physics_frames(3)
	check(mission.found_t >= 0.0 and not mission.defence.quiet, "found once you fire (%s)" % [mission.timeline.slice(-3)])
