extends TestCase
## The dev bridge (src/debug/dev_bridge.gd): commands over a local socket, one JSON line back each,
## in order, and the game does what they say.

const TEST_PORT := 18737

var holder: Node
var street: Node3D
var bridge: DevBridge


func before_each() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	street = load("res://scenes/test_street.tscn").instantiate()
	holder.add_child(street)
	await process_frames(3)
	bridge = DevBridge.new()
	bridge.main = holder
	bridge.port = TEST_PORT
	bridge.labs_dir = "res://tests/labs"
	holder.add_child(bridge)
	await process_frames(2)


func after_each() -> void:
	Settings.autosave = false
	holder.queue_free()
	await process_frames(2)


## Send lines, wait for one answer each.
func _ask(lines: Array[String], timeout_frames := 60 * 30) -> Array[Dictionary]:
	var peer := StreamPeerTCP.new()
	peer.connect_to_host("127.0.0.1", TEST_PORT)
	for i in 60:
		peer.poll()
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await process_frames(1)
	peer.put_data(("\n".join(lines) + "\n").to_utf8_buffer())
	var text := ""
	var out: Array[Dictionary] = []
	for i in timeout_frames:
		await process_frames(1)
		peer.poll()
		var n: int = peer.get_available_bytes()
		if n > 0:
			text += peer.get_utf8_string(n)
		while "\n" in text:
			out.append(JSON.parse_string(text.get_slice("\n", 0)))
			text = text.substr(text.find("\n") + 1)
		if out.size() >= lines.size():
			break
	peer.disconnect_from_host()
	return out


func test_without_the_flag_there_is_no_bridge() -> void:
	check(DevBridge.maybe_start(holder) == null, "the game doesn't open a port unless asked")


func test_commands_answer_in_order_and_move_you() -> void:
	var replies := await _ask(["ping", "goto 3 0.1 -9 90", "read player", "nonsense", "time 17.5", "wait 0.5"])
	check_eq(replies.size(), 6, "one answer a command")
	check(replies[0].ok, "ping")
	var player: Player = street.get_node(^"Player")
	check(player.global_position.distance_to(Vector3(3, 0, -9)) < 0.3, "goto put you there (%s)" % player.global_position)
	check_eq(int(replies[1].facing), 90, "facing east")
	check_eq(replies[2].player.weapon, "revolver put away, 5 loaded, hammer down", "read player says what's in your hands")
	check(not replies[3].ok and "no such command" in String(replies[3].error), "a bad command says so")
	check_eq(replies[4].clock, "17:30", "time sets the clock")
	check(float(replies[5].t) - float(replies[4].t) >= 0.49, "wait lets game time pass (%.2f s)" % (float(replies[5].t) - float(replies[4].t)))


func test_walk_draw_and_shoot() -> void:
	var replies := await _ask(["goto street_mid", "walk saloon_porch", "weapon revolver", "turn 180", "shoot 1", "events 50"])
	check(replies[1].arrived, "walked round to the saloon's porch (%s)" % str(replies[1].at))
	check(replies[2].ok and String(replies[2].weapon).begins_with("revolver in hand"), "drew the revolver")
	check_eq(int(replies[4].fired), 1, "one shot")
	check(replies[5].events.any(func(e: Dictionary) -> bool: return e.text == "you fired"), "and the log has it")


## `walk X Z` routes as `walk PLACE` does: from the street into the store's aisle, up its steps and
## through its door (straight at it, it walked into the store's front; the D+ playtest's walks
## stopped on chairs and posts).
func test_walk_to_a_point_routes_round_what_is_in_the_way() -> void:
	# Inside the store, between its door and its aisle: straight from the street is its front wall.
	var inside := bridge._places().at(&"store_door").lerp(bridge._places().at(&"store_aisle"), 0.45)
	var replies := await _ask(["goto street_mid", "walk %.2f %.2f" % [inside.x, inside.z]], 60 * 60)
	check(replies[1].arrived, "walked into the store (%s)" % str(replies[1]))
	check(int(replies[1].get("legs", 0)) > 1, "by a route, not straight (%s legs)" % replies[1].get("legs"))


## A run ends where it was sent, not 1.1-1.4 m on (the second D+ playtest slid on after "arrived"),
## and it answers once you've stopped.
func test_a_run_stops_where_it_was_sent() -> void:
	var to := bridge._places().at(&"street_mid") + Vector3(9.0, 0.0, 0.0)
	var replies := await _ask(["goto street_mid", "walk %.2f %.2f run" % [to.x, to.z], "wait 1", "read player"], 60 * 60)
	check(replies[1].arrived, "ran there (%s)" % str(replies[1]))
	var at := Vector3(float(replies[1].at[0]), 0.0, float(replies[1].at[2]))
	var flat := Vector2(at.x - to.x, at.z - to.z).length()
	check(flat < 0.7, "and stopped there (%.2f m off)" % flat)
	var player: Player = street.get_node(^"Player")
	check(player.global_position.distance_to(Vector3(at.x, player.global_position.y, at.z)) < 0.1, "and stays (%s)" % player.global_position)
	check(replies[1].has("crouching"), "it says whether you're crouched")


## A broken gun arm: the gun won't come out, and you're told why (the second D+ playtest's `weapon
## revolver` answered ok: false and nothing more).
func test_a_gun_you_cant_hold_says_why() -> void:
	var player: Player = street.get_node(^"Player")
	player.wounds.physiology.broken[&"humerus_r"] = true
	var replies := await _ask(["weapon revolver", "shoot 1", "events 10"])
	check(not replies[0].ok, "it doesn't come out")
	check(String(replies[0].get("why", "")).contains("broken upper arm"), "and says why (%s)" % str(replies[0]))
	check(String(replies[1].get("why", "")).contains("broken upper arm"), "shoot says why too (%s)" % str(replies[1]))
	check(replies[2].events.any(func(e: Dictionary) -> bool: return e.kind == "screen" and "can't hold the gun" in String(e.text)),
			"and the screen's line is in the events (%s)" % str(replies[2].events))


## `look PERSON [PART]` faces that part of him and says what's in the line and what of him you can
## see (#595: the D+ playtest's sights were on posts while the gang aimed at its head).
func test_look_at_a_man_says_what_you_can_see_of_him() -> void:
	var man := HumanBody.new()
	man.person_id = &"looked_at"
	street.add_child(man)
	var player: Player = street.get_node(^"Player")
	var spot := bridge._places().at(&"street_mid")
	man.global_position = spot + Vector3(6.0, 0.0, 0.0)
	await process_frames(3)
	var replies := await _ask(["goto street_mid", "look looked_at head", "look looked_at elbow"])
	check(replies[1].has("clear_to") and "head" in replies[1].clear_to, "his head's in plain view (%s)" % str(replies[1]))
	check(not replies[1].has("in_the_way"), "nothing in the way")
	check(player.camera.global_basis.z.dot(((man.parts[&"head"] as Node3D).global_position - player.camera.global_position).normalized()) < -0.99,
			"facing his head")
	check(not replies[2].ok, "a part he hasn't says so")
	# What's in the line says whether a ball gets through it, as Ballistics charges it: a board yes,
	# a post no (the third playtest's balls went through batwings `look` called "in the way").
	var says := {}
	for m: StructureMember in street.find_children("*", "StructureMember", true, false):
		if m.kind == &"glass" or says.size() >= 40:
			continue
		var c := (m as Node3D).global_position
		var from := c + Vector3(0.0, 0.0, 3.0)
		var q := PhysicsRayQueryParameters3D.create(from, c)
		q.exclude = [player.get_rid()]
		var hit := street.get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty() and hit.collider == m:
			var line := bridge._ball_through(m, hit.position, Vector3(0, 0, -1))
			says[line.begins_with("a ball goes through")] = line
	check(says.has(true) and says.has(false), "some it goes through, some stop it: %s" % str(says))


## Your "Drop it!" goes in the log (the D+ playtest's shouts read as doing nothing).
func test_a_shout_is_in_the_log() -> void:
	var replies := await _ask(["weapon revolver", "press shout", "events 5"])
	check(replies[2].events.any(func(e: Dictionary) -> bool: return e.kind == "shout" and "Drop it" in String(e.text)),
			"the shout is in the events (%s)" % str(replies[2].events))


func test_a_look_value_set_and_read_back() -> void:
	var replies := await _ask(["set env.glow_intensity 0.5", "get env.glow_intensity", "set day.exposure_night 0.6", "set settings.no_such_thing 1"])
	check(replies[0].ok and is_equal_approx(float(replies[1].value), 0.5), "an environment value set and read back")
	check(replies[2].ok and is_equal_approx(float((street.find_child("DayCycle", true, false) as DayCycle).config.exposure_night), 0.6),
			"a day cycle value set")
	check(not replies[3].ok, "a name that isn't there says so")


func test_a_lab_adds_its_own_commands() -> void:
	var replies := await _ask(["echo three gunmen", "later 0.5", "ping", "count", "help", "events 5"])
	check_eq(String(replies[0].get("said", "")), "three gunmen", "echo_lab's command answered from its own folder")
	check(float(replies[1].t) - float(replies[0].t) >= 0.49 and is_equal_approx(float(replies[1].waited), 0.5),
			"a lab's command can take game time")
	check(replies[2].ok, "a lab can't take the bridge's own ping")
	check_eq(int(replies[3].get("count", 0)), 3, "a second lab's command")
	check(replies[4].commands.any(func(l: String) -> bool: return l.begins_with("echo WORDS") and "(echo_lab)" in l),
			"help lists a lab's commands and whose they are")
	var labs: Dictionary = replies[4].labs
	check_eq(labs.echo_lab.commands, ["echo", "later"], "echo_lab's ping refused")
	check_eq(labs.greedy_lab.refused, ["echo", "ghost"], "greedy_lab's echo (taken) and ghost (no method) refused")
	check(String(labs.not_a_lab).begins_with("not loaded"), "a bridge.gd that isn't a BridgeLab is skipped")
	check(replies[5].events.any(func(e: Dictionary) -> bool: return e.kind == "echo"), "a lab writes to the event log")


func test_the_real_labs_load() -> void:
	# Every experiments/*/bridge.gd loads and keeps its commands (nothing refused).
	var b := DevBridge.new()
	b.main = holder
	b.port = TEST_PORT + 1
	holder.add_child(b)
	await process_frames(2)
	for lab: String in b._labs:
		check(b._labs[lab] is Array, "%s's commands all added (%s)" % [lab, b._labs[lab]])
