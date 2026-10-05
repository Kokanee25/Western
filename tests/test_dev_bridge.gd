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


func test_a_look_value_set_and_read_back() -> void:
	var replies := await _ask(["set env.glow_intensity 0.5", "get env.glow_intensity", "set day.exposure_night 0.6", "set settings.no_such_thing 1"])
	check(replies[0].ok and is_equal_approx(float(replies[1].value), 0.5), "an environment value set and read back")
	check(replies[2].ok and is_equal_approx(float((street.find_child("DayCycle", true, false) as DayCycle).config.exposure_night), 0.6),
			"a day cycle value set")
	check(not replies[3].ok, "a name that isn't there says so")
