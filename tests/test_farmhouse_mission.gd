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
