extends TestCase
## The valley's places with height (#736 B, #752; config/valley.json `heights`, the plan
## docs/briefs/valley-heights.md): their landforms in the bake, their greybox blocks, a Ladder up
## each one climbed that the player climbs, and a place for each (`<id>`, `<id>_top`).

var holder: Node
var valley: ValleyWorld


## The valley built once for the file (it's freed with the case, after its last test).
func before_each() -> void:
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(3)


func _markers() -> ValleyMarkers:
	return valley.markers


func test_every_height_is_a_place_on_its_ground_or_block() -> void:
	var mk := _markers()
	var lay := ValleyLayout.main()
	check(lay.heights().size() >= 12, "#736 B: 12-15 places with height (%d)" % lay.heights().size())
	var ids := {}
	for l: Dictionary in mk.ladders:
		ids[l.id] = true
	for hp: Dictionary in lay.heights():
		var id := String(hp.id)
		check(mk.places.has(StringName(id)), "%s is a place" % id)
		check(not (hp.get("why", "") as String).is_empty() and hp.has("above") and hp.has("below"), "%s says why, who's above and below" % id)
		var feet := mk.high_spot(id)
		check(not is_nan(feet.y), "%s has a high spot" % id)
		if ids.has(id):
			check(mk.places.has(StringName(id + "_top")), "%s_top is a place" % id)
			var top := mk.places.at(StringName(id + "_top"))
			check_near(top.y - 0.05, feet.y, 0.05, "%s: the ladder's top is the high spot's level" % id)


func test_the_landforms_are_in_the_bake() -> void:
	var ter := ValleyTerrain.main()
	var mk := _markers()
	# Sentinel Butte: 90 m over the mesas, the spire on it.
	var butte := mk.high_spot("sentinel_butte")
	check(butte.y > 130.0, "the butte's top at Y %.1f (planned about +140)" % butte.y)
	check(butte.y - ter.height(260.0, 1962.0) > 80.0, "the butte stands %.0f m over its foot" % (butte.y - ter.height(260.0, 1962.0)))
	# The Jump-off: a sheer face at the lip (2 m out it's 20 m lower).
	var lip := mk.high_spot("jump_off")
	var below := ter.height(lip.x - 3.0, lip.z)
	check(lip.y - below > 18.0, "the Jump-off drops %.1f m within 3 m of the lip" % (lip.y - below))
	# The coach cut: the road 7 m under the log deck's lip, in the cut.
	var deck := mk.high_spot("coach_cut")
	check(deck.y - ter.height(400.0, 805.0) > 7.0, "the coach cut: the lip %.1f m over the road" % (deck.y - ter.height(400.0, 805.0)))
	# The south rim: 12 m high beside the notch, the notch at the mesa's own level.
	var rim := mk.high_spot("south_rim")
	check(rim.y - ter.height(300.0, 2060.0) > 9.0, "the rim %.1f m over the notch" % (rim.y - ter.height(300.0, 2060.0)))


func test_each_laddered_height_has_a_ladder_to_its_top() -> void:
	var mk := _markers()
	var want := ["stage_station", "burned_homestead", "windmill_homestead", "water_tower", "headframe", "ore_chute", "bell_tower"]
	var have := {}
	for l: Dictionary in mk.ladders:
		have[l.id] = l
	for id: String in want:
		check(have.has(id), "%s has a ladder" % id)
		if not have.has(id):
			continue
		var lad: Ladder = have[id].ladder
		check(lad.is_in_group(Ladder.GROUP), "%s's ladder is found by the player" % id)
		check_near(lad.global_position.y + lad.height, (have[id].top as Vector3).y - 0.05, 0.05, "%s's ladder reaches its top" % id)


func test_the_player_climbs_the_windmill() -> void:
	var mk := _markers()
	var lad := {}
	for l: Dictionary in mk.ladders:
		if l.id == "windmill_homestead":
			lad = l
	check(not lad.is_empty(), "the windmill's ladder")
	if lad.is_empty():
		return
	var player := valley.get_node(^"Player") as Player
	var ladder: Ladder = lad.ladder
	player.velocity = Vector3.ZERO
	player.global_position = lad.foot
	await physics_frames(3)
	var to := ladder.global_position - player.global_position
	player.rotation.y = atan2(-to.x, -to.z)
	var got_on := false
	var on_top := false
	for i in 60 * 20:
		_press(true)
		await physics_frames(1)
		got_on = got_on or player.ladder != null
		if player.ladder == null and player.global_position.y > (lad.top as Vector3).y - 0.3:
			on_top = true
			break
	_press(false)
	check(got_on, "on the ladder")
	check(on_top, "on the windmill's platform (at %s, the top %s)" % [player.global_position, lad.top])


func _press(down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = &"move_forward"
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)
