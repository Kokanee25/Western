class_name DevBridge
extends Node
## Drive the running game from outside (docs/briefs/review-tools.md "The dev bridge"): a session,
## a script or the playtest agent sends one command a line and gets one JSON line back. Only in
## a debug build started with `--dev-bridge` (after `--` on Godot's command line); never in an
## exported release. Listens on 127.0.0.1:`--bridge-port=` (8737), and runs `--bridge-script=FILE`
## (one command a line, # comments) first. `tools/bridge.py` is the client; the commands are in
## HELP. Commands run one at a time in the order they came; one that takes game time (wait, walk,
## press) answers when it's done.

const PORT := 8737
const HELP := {
	"ping": "ping -> {ok}",
	"help": "help -> every command",
	"screenshot": "screenshot PATH -> the window as you see it, PNG",
	"camera": "camera X Y Z [TX TY TZ] [FOV] | camera player -> a free camera there looking at T, or back to your eyes",
	"goto": "goto X Y Z [YAW] | goto PLACE -> stand there (feet), facing YAW degrees (0 = north, -Z)",
	"look": "look TX TY TZ | look PERSON | look PLACE -> turn to face a point, a person or a place (eye height)",
	"turn": "turn DEGREES [PITCH] -> turn right by DEGREES, pitch up by PITCH",
	"walk": "walk X Z [run] | walk PLACE [run] | walk PERSON [run] -> walk there (routes round buildings to a place)",
	"press": "press ACTION [SECONDS] -> hold an input action (fire, aim, cock, reload, holster, jump, crouch_toggle, shout, weapon_revolver...) then let go",
	"hold": "hold ACTION | release ACTION -> press without letting go / let go",
	"shoot": "shoot [N] -> cock and fire the gun in hand N times (as the keys do)",
	"weapon": "weapon revolver|shotgun|dynamite|none -> take that out (none: put it away)",
	"wait": "wait SECONDS -> let game time pass",
	"time": "time HOUR -> set the clock",
	"clock": "clock SCALE|on|off -> time runs at SCALE (1 = 45 min a day), or stops",
	"set": "set ADDRESS VALUE -> a look value (settings.X, global.X, env.X, day.X, hour; see LookPreset)",
	"get": "get ADDRESS -> read one",
	"preset": "preset FILE -> apply a look preset (JSON)",
	"spawn": "spawn outlaw|townsman X Y Z [YAW] -> a person there",
	"gang": "gang -> the three riders come in from the west on their day",
	"fight": "fight [NAME] -> the gang (or one man) turn on you, as if you'd shot at them",
	"dynamite": "dynamite X Y Z [FUSE] -> a lit stick there",
	"ignite": "ignite [X Y Z] -> set fire to the timber nearest the point (or what you look at)",
	"read": "read frame|player|people|look|places|counts|all -> what's going on",
	"events": "events [N] -> the last N things that happened (shots, words, hits, deaths...)",
	"quit": "quit -> close the game",
}

var port := PORT
var script_path := ""
var main: Node
var street: Node
var player: Player

var _server: TCPServer
var _peers: Array[StreamPeerTCP] = []
var _buffers := {}  # peer -> String
var _queue: Array[Dictionary] = []  # {line, peer}
var _busy := false
var _events: Array[Dictionary] = []
var _free_camera: Camera3D
var _held := {}  # action -> true


## Add a bridge to the game if this run asked for one (and it's a debug build).
static func maybe_start(main_node: Node) -> DevBridge:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if not "--dev-bridge" in args or not OS.is_debug_build():
		return null
	var b := DevBridge.new()
	b.name = "DevBridge"
	b.main = main_node
	for a in args:
		if a.begins_with("--bridge-port="):
			b.port = int(a.get_slice("=", 1))
		elif a.begins_with("--bridge-script="):
			b.script_path = a.get_slice("=", 1)
	main_node.add_child(b)
	return b


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if main == null:
		main = get_parent()
	street = main.find_child("TestStreet", true, false)
	player = main.find_child("Player", true, false) as Player
	Settings.autosave = false  # a bridge run never writes the player's settings file
	_arm_player.call_deferred()
	_listen_to_events()
	_server = TCPServer.new()
	var err := _server.listen(port, "127.0.0.1")
	print("[bridge] %s on 127.0.0.1:%d" % ["listening" if err == OK else "can't listen (%s)" % error_string(err), port])
	if script_path != "":
		for line in FileAccess.get_file_as_string(script_path).split("\n"):
			_queue.append({"line": line, "peer": null})


func _exit_tree() -> void:
	if _server:
		_server.stop()
	for p in _peers:
		p.disconnect_from_host()


## The guns answer the bridge's presses without a captured mouse.
func _arm_player() -> void:
	if player:
		for w in player.weapons:
			w.needs_captured_mouse = false
	# The key help starts hidden (press debug_help for it): it'd cover every screenshot.
	var overlay := main.get_node_or_null(^"DebugOverlay")
	if overlay and "_help" in overlay:
		overlay._help.visible = false
		overlay._help_timer = -1.0


func _process(_delta: float) -> void:
	if _server and _server.is_connection_available():
		var p := _server.take_connection()
		p.set_no_delay(true)
		_peers.append(p)
		_buffers[p] = ""
	for p in _peers.duplicate():
		p.poll()
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(p)
			_buffers.erase(p)
			continue
		var n: int = p.get_available_bytes()
		if n > 0:
			_buffers[p] += p.get_utf8_string(n)
			var text: String = _buffers[p]
			while "\n" in text:
				var i := text.find("\n")
				_queue.append({"line": text.substr(0, i), "peer": p})
				text = text.substr(i + 1)
			_buffers[p] = text
	if not _busy and not _queue.is_empty():
		_run_next()


func _run_next() -> void:
	_busy = true
	while not _queue.is_empty():
		var job: Dictionary = _queue.pop_front()
		var line := String(job.line).strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var reply: Dictionary
		var words := line.split(" ", false)
		var cmd := words[0].to_lower()
		if not HELP.has(cmd):
			reply = {"ok": false, "error": "no such command: %s (try help)" % cmd}
		else:
			reply = await call("_cmd_" + cmd, Array(words.slice(1)))
			if not reply.has("ok"):
				reply["ok"] = true
		reply["cmd"] = line
		reply["t"] = snappedf(_game_seconds(), 0.01)
		var text := JSON.stringify(reply)
		if job.peer != null:
			(job.peer as StreamPeerTCP).put_data((text + "\n").to_utf8_buffer())
		else:
			print("[bridge] " + text)
	_busy = false


func _game_seconds() -> float:
	return float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)


func _physics_frames(n: int) -> void:
	for i in maxi(n, 1):
		await get_tree().physics_frame


func _seconds(s: float) -> void:
	await _physics_frames(int(ceil(s * Engine.physics_ticks_per_second)))


# -- Commands ------------------------------------------------------------------------------------

func _cmd_ping(_a: Array) -> Dictionary:
	return {"ok": true}


func _cmd_help(_a: Array) -> Dictionary:
	return {"commands": HELP.values()}


func _cmd_quit(_a: Array) -> Dictionary:
	get_tree().quit.call_deferred()
	return {"ok": true}


func _cmd_screenshot(a: Array) -> Dictionary:
	if DisplayServer.get_name() == "headless":
		return {"ok": false, "error": "headless: nothing is drawn (run under xvfb with a renderer)"}
	var path: String = a[0] if a.size() > 0 else "user://bridge_shot.png"
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := img.save_png(path)
	return {"ok": err == OK, "path": ProjectSettings.globalize_path(path), "size": [img.get_width(), img.get_height()]}


func _cmd_camera(a: Array) -> Dictionary:
	if a.size() == 1 and a[0] == "player":
		if _free_camera:
			_free_camera.queue_free()
			_free_camera = null
		player.camera.make_current()
		return {"camera": "player"}
	if a.size() < 3:
		return {"ok": false, "error": "camera X Y Z [TX TY TZ] [FOV]"}
	if _free_camera == null:
		_free_camera = Camera3D.new()
		_free_camera.name = "BridgeCamera"
		street.add_child(_free_camera)
		_free_camera.attributes = player.camera.attributes
		_free_camera.cull_mask = player.camera.cull_mask
		_free_camera.far = player.camera.far
		_free_camera.near = player.camera.near
		DepthMosaic.apply(_free_camera, Settings.mosaic, Settings.MOSAIC_K, Settings.MOSAIC_STEPS)
	var at := _vec(a, 0)
	_free_camera.global_position = at
	if a.size() >= 6:
		var target := _vec(a, 3)
		if not target.is_equal_approx(at):
			_free_camera.look_at(target, Vector3.UP if absf((target - at).normalized().y) < 0.99 else Vector3.FORWARD)
	_free_camera.fov = float(a[6]) if a.size() >= 7 else player.camera.fov
	_free_camera.make_current()
	return {"camera": "free", "at": _arr(_free_camera.global_position), "looking": _arr(-_free_camera.global_basis.z)}


func _cmd_goto(a: Array) -> Dictionary:
	var to: Vector3
	var yaw := NAN
	if a.size() >= 3:
		to = _vec(a, 0)
		if a.size() >= 4:
			yaw = float(a[3])
	elif a.size() >= 1 and _places().has(StringName(a[0])):
		to = _places().at(StringName(a[0]))
	else:
		return {"ok": false, "error": "goto X Y Z [YAW] | goto PLACE (read places)"}
	player.global_position = to
	player.velocity = Vector3.ZERO
	if not is_nan(yaw):
		player.rotation.y = deg_to_rad(-yaw)
	await _physics_frames(2)
	return {"at": _arr(player.global_position), "facing": _facing()}


func _cmd_look(a: Array) -> Dictionary:
	var target: Vector3
	if a.size() >= 3:
		target = _vec(a, 0)
	elif a.size() == 1 and _person(a[0]) != null:
		target = _chest(_person(a[0]))
	elif a.size() == 1 and _places().has(StringName(a[0])):
		target = _places().at(StringName(a[0])) + Vector3.UP * 1.5
	else:
		return {"ok": false, "error": "look TX TY TZ | look PERSON | look PLACE"}
	if _free_camera:
		_free_camera.look_at(target)
	else:
		_face(target)
	await _physics_frames(1)
	return {"facing": _facing(), "pitch": snappedf(player.get_pitch_degrees(), 0.1)}


func _cmd_turn(a: Array) -> Dictionary:
	var yaw := float(a[0]) if a.size() > 0 else 0.0
	var pitch := float(a[1]) if a.size() > 1 else 0.0
	_set_view(player.rotation.y - deg_to_rad(yaw), player.get_pitch_degrees() + pitch)
	await _physics_frames(1)
	return {"facing": _facing(), "pitch": snappedf(player.get_pitch_degrees(), 0.1)}


func _cmd_walk(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "walk X Z [run] | walk PLACE [run] | walk PERSON [run]"}
	var run := "run" in a
	var points: Array[Vector3] = []
	var place := StringName(a[0])
	if _places().has(place):
		points = _places().route(player.get_world_3d().direct_space_state, player.global_position, place, [player.get_rid()])
	elif _person(a[0]) != null:
		var p := _person(a[0])
		points = [p.global_position + (player.global_position - p.global_position).normalized() * 1.5]
	elif a.size() >= 2 and a[0].is_valid_float():
		points = [Vector3(float(a[0]), player.global_position.y, float(a[1]))]
	if points.is_empty():
		return {"ok": false, "error": "no way there"}
	var start := player.global_position
	var arrived := true
	if run:
		_act(true, &"run")
	for target in points:
		var limit := _game_seconds() + Vector2(target.x - player.global_position.x, target.z - player.global_position.z).length() / 0.8 + 4.0
		var stuck_since := _game_seconds()
		var last := player.global_position
		while true:
			var flat := Vector2(target.x - player.global_position.x, target.z - player.global_position.z)
			if flat.length() < 0.5:
				break
			if _game_seconds() > limit or _game_seconds() - stuck_since > 3.0:
				arrived = false
				break
			_set_view(atan2(-flat.x, -flat.y), player.get_pitch_degrees())
			_act(true, &"move_forward")
			await get_tree().physics_frame
			if player.global_position.distance_to(last) > 0.3:
				last = player.global_position
				stuck_since = _game_seconds()
		if not arrived:
			break
	_act(false, &"move_forward")
	_act(false, &"run")
	await _physics_frames(10)
	return {"arrived": arrived, "at": _arr(player.global_position), "walked_m": snappedf(start.distance_to(player.global_position), 0.1),
			"facing": _facing()}


func _cmd_press(a: Array) -> Dictionary:
	if a.is_empty() or not InputMap.has_action(StringName(a[0])):
		return {"ok": false, "error": "no action %s" % (a[0] if a.size() > 0 else "")}
	var action := StringName(a[0])
	_act(true, action)
	await _seconds(float(a[1]) if a.size() > 1 else 0.1)
	_act(false, action)
	await _physics_frames(2)
	return {"action": String(action), "weapon": _weapon_line()}


func _cmd_hold(a: Array) -> Dictionary:
	if a.is_empty() or not InputMap.has_action(StringName(a[0])):
		return {"ok": false, "error": "no action"}
	_act(true, StringName(a[0]))
	_held[StringName(a[0])] = true
	await _physics_frames(2)
	return {"holding": _held.keys().map(func(k): return String(k))}


func _cmd_release(a: Array) -> Dictionary:
	var which: Array = _held.keys() if a.is_empty() else [StringName(a[0])]
	for k in which:
		_act(false, k)
		_held.erase(k)
	await _physics_frames(2)
	return {"holding": _held.keys().map(func(k): return String(k))}


func _cmd_shoot(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 1
	var w := player.weapon
	if w == null:
		return {"ok": false, "error": "nothing in hand (weapon revolver)"}
	var fired := 0
	for i in n:
		var before := _shots
		if w is RevolverViewmodel or w is ShotgunViewmodel:
			# Thumb the hammer back till it's cocked (a press while the gun's still coming up or
			# recoiling doesn't take).
			var tries := 0
			while not _cocked(w) and tries < 6:
				_act(true, &"cock")
				await _seconds(0.12)
				_act(false, &"cock")
				await _seconds(0.35)
				tries += 1
		_act(true, &"fire")
		await _seconds(0.1)
		_act(false, &"fire")
		await _seconds(0.6)
		if _shots > before:
			fired += 1
	return {"fired": fired, "weapon": _weapon_line()}


func _cocked(w: WeaponViewmodel) -> bool:
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.hammer == RevolverState.Hammer.FULL_COCK
	if w is ShotgunViewmodel:
		return (w as ShotgunViewmodel).state.cocked_hammers.has(true)
	return true


func _cmd_weapon(a: Array) -> Dictionary:
	var want: String = a[0] if a.size() > 0 else ""
	if want == "none":
		if player.weapon and player.weapon.has_method("put_away"):
			player.weapon.put_away()
		await _seconds(0.8)
		return {"weapon": _weapon_line()}
	var w: WeaponViewmodel = {"revolver": player.revolver(), "shotgun": player.shotgun(), "dynamite": player.dynamite()}.get(want)
	if w == null:
		return {"ok": false, "error": "weapon revolver|shotgun|dynamite|none"}
	player.select_weapon(w)
	var until := _game_seconds() + 4.0
	while _game_seconds() < until and not (player.weapon == w and w.drawn):
		await get_tree().physics_frame
	await _seconds(0.5)
	return {"ok": player.weapon == w and w.drawn, "weapon": _weapon_line()}


func _cmd_wait(a: Array) -> Dictionary:
	await _seconds(float(a[0]) if a.size() > 0 else 1.0)
	return {}


func _cmd_time(a: Array) -> Dictionary:
	var clock := _clock()
	if clock == null or a.is_empty():
		return {"ok": false, "error": "time HOUR"}
	clock.set_time(float(a[0]))
	await _physics_frames(2)
	return {"clock": clock.get_clock_text()}


func _cmd_clock(a: Array) -> Dictionary:
	var clock := _clock()
	var s: String = a[0] if a.size() > 0 else "on"
	clock.set_time_scale(0.0 if s == "off" else 1.0 if s == "on" else float(s))
	return {"clock": clock.get_clock_text(), "scale": clock.time_scale}


func _cmd_set(a: Array) -> Dictionary:
	if a.size() < 2:
		return {"ok": false, "error": "set ADDRESS VALUE"}
	var raw := " ".join(PackedStringArray(a.slice(1)))
	var parsed: Variant = JSON.parse_string(raw)
	var value: Variant = raw if parsed == null else parsed
	var ok := LookPreset.set_value(get_tree(), a[0], value)
	await _physics_frames(2)
	return {"ok": ok, "value": LookPreset._plain(LookPreset.get_value(get_tree(), a[0]))}


func _cmd_get(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "get ADDRESS"}
	var v: Variant = LookPreset.get_value(get_tree(), a[0])
	return {"ok": v != null, "value": LookPreset._plain(v)}


func _cmd_preset(a: Array) -> Dictionary:
	if a.is_empty() or not FileAccess.file_exists(a[0]):
		return {"ok": false, "error": "preset FILE (no such file)"}
	var missed := LookPreset.apply(get_tree(), LookPreset.load_file(a[0]))
	await _physics_frames(2)
	return {"missed": Array(missed)}


func _cmd_spawn(a: Array) -> Dictionary:
	if a.size() < 4:
		return {"ok": false, "error": "spawn outlaw|townsman X Y Z [YAW]"}
	var man := HumanBody.new()
	_spawned += 1
	man.rng_seed = 500 + _spawned
	var kind: String = a[0]
	man.person_id = StringName("%s%d" % [kind, _spawned])
	man.name = String(man.person_id).capitalize()
	if kind == "townsman":
		man.has_gun = false
		var cb := CivilianBrain.new()
		cb.name = "Brain"
		man.add_child(cb)
	else:
		var ob := OutlawBrain.new()
		ob.name = "Brain"
		man.add_child(ob)
	street.add_child(man)
	man.global_position = _vec(a, 1)
	if a.size() >= 5:
		man.rotation.y = deg_to_rad(-float(a[4]))
	if kind == "townsman":
		(man.get_node(^"Brain") as CivilianBrain).post = man.global_position
	await _physics_frames(3)
	return {"person": String(man.person_id)}


func _cmd_gang(_a: Array) -> Dictionary:
	var town := _town()
	if town == null:
		return {"ok": false, "error": "no TownLife"}
	if town.gang.is_empty() or town.gang.all(func(g): return not is_instance_valid(g)):
		town.bring_gang()
	await _physics_frames(3)
	return {"gang": town.gang.filter(func(g): return is_instance_valid(g)).map(func(g): return String(g.person_id))}


func _cmd_fight(a: Array) -> Dictionary:
	var town := _town()
	if town and (town.gang.is_empty() or town.gang.all(func(g): return not is_instance_valid(g))):
		town.bring_gang()
		await _physics_frames(3)
	var who: Array = []
	if a.size() > 0:
		var p := _person(a[0])
		if p:
			who = [p]
	elif town:
		who = town.gang.filter(func(g): return is_instance_valid(g))
	var turned: Array = []
	for man: HumanBody in who:
		var brain := man.get_node_or_null(^"Brain") as OutlawBrain
		if brain and brain.relations:
			brain.relations.provoke(player)
			turned.append(String(man.person_id))
	await _physics_frames(2)
	return {"ok": not turned.is_empty(), "turned": turned}


func _cmd_dynamite(a: Array) -> Dictionary:
	if a.size() < 3:
		return {"ok": false, "error": "dynamite X Y Z [FUSE]"}
	var s := DynamiteStick.make(street, _vec(a, 0), Vector3.ZERO, float(a[3]) if a.size() > 3 else -1.0)
	s.light()
	return {"fuse": snappedf(s.fuse_left, 0.1)}


func _cmd_ignite(a: Array) -> Dictionary:
	var fire := FireSystem.find(get_tree())
	if fire == null:
		return {"ok": false, "error": "no FireSystem"}
	var m: StructureMember
	if a.size() >= 3:
		var at := _vec(a, 0)
		var best := 3.0
		for n in street.find_children("*", "StructureMember", true, false):
			var sm := n as StructureMember
			if sm.broken or sm.burning:
				continue
			var d: float = sm.world_aabb().get_center().distance_to(at)
			if d < best:
				best = d
				m = sm
	else:
		var hit := _look_hit()
		m = hit.get("collider") as StructureMember
	if m == null:
		return {"ok": false, "error": "no timber there"}
	fire.ignite(m)
	return {"member": String(m.member_id)}


func _cmd_read(a: Array) -> Dictionary:
	var what: String = a[0] if a.size() > 0 else "all"
	var out := {}
	if what in ["frame", "all"]:
		out["frame"] = _frame()
	if what in ["player", "all"]:
		out["player"] = _player_state()
	if what in ["people", "all"]:
		out["people"] = _people()
	if what in ["look", "all"]:
		out["look"] = _looking_at()
	if what == "places":
		var ps := {}
		for n: StringName in _places().points:
			ps[String(n)] = _arr(_places().points[n])
		out["places"] = ps
	if what in ["counts", "all"]:
		out["counts"] = _counts()
	if out.is_empty():
		return {"ok": false, "error": "read frame|player|people|look|places|counts|all"}
	return out


func _cmd_events(a: Array) -> Dictionary:
	var n := int(a[0]) if a.size() > 0 else 20
	return {"events": _events.slice(maxi(_events.size() - n, 0))}


# -- What's going on -----------------------------------------------------------------------------

var _shots := 0
var _spawned := 0


func _listen_to_events() -> void:
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, shooter: Node) -> void:
		if shooter == player:
			_shots += 1
		_log("shot", "%s fired" % _who(shooter)))
	Events.spoke.connect(func(who: Node, text: String) -> void: _log("said", "%s: \"%s\"" % [_who(who), text]))
	Events.body_hit.connect(func(info: Dictionary) -> void:
		_log("hit", "%s hit in the %s%s" % [_who(info.get("person")), info.get("segment", "?"), " (graze)" if info.get("graze", false) else ""]))
	Events.person_fell.connect(func(p: Node, conscious: bool) -> void: _log("fell", "%s went down%s" % [_who(p), "" if conscious else ", out cold"]))
	Events.person_died.connect(func(p: Node, cause: StringName) -> void: _log("died", "%s died (%s)" % [_who(p), cause]))
	Events.person_surrendered.connect(func(p: Node) -> void: _log("surrendered", "%s gave up" % _who(p)))
	Events.hat_shot.connect(func(p: Node, s: Node, _at: Vector3) -> void: _log("hat", "%s shot %s's hat off" % [_who(s), _who(p)]))
	Events.exploded.connect(func(at: Vector3, kg: float) -> void: _log("blast", "%.2f kg went off at %s" % [kg, _arr(at)]))
	Events.callout.connect(func(s: Node, kind: StringName, about: Node, _at: Vector3) -> void:
		_log("callout", "%s called %s%s" % [_who(s), kind, " (%s)" % _who(about) if about else ""]))
	Events.member_broken.connect(func(id: StringName) -> void:
		if not _events.is_empty() and _events[-1].kind == "broke" and float(_events[-1].t) > _game_seconds() - 1.0:
			_events[-1].count += 1
			_events[-1].text = "%d pieces of timber broke" % _events[-1].count
		else:
			_log("broke", "timber broke (%s)" % id)
			_events[-1]["count"] = 1)
	Events.near_miss.connect(func(p: Node, s: Node, d: float, _at: Vector3, _sp: float, _tu: bool) -> void:
		if p == player:
			_log("near_miss", "a round from %s passed %.1f m from you" % [_who(s), d]))


func _log(kind: String, text: String) -> void:
	_events.append({"t": snappedf(_game_seconds(), 0.1), "kind": kind, "text": text})
	if _events.size() > 300:
		_events.pop_front()


func _who(n: Variant) -> String:
	if n == null or not is_instance_valid(n):
		return "someone"
	if n == player:
		return "you"
	if n is HumanBody:
		return String((n as HumanBody).person_id)
	return String((n as Node).name)


func _frame() -> Dictionary:
	var fps := maxf(Engine.get_frames_per_second(), 1.0)
	return {"fps": fps, "frame_ms": snappedf(1000.0 / fps, 0.1),
		"process_ms": snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01),
		"physics_ms": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"clock": _clock().get_clock_text() if _clock() else ""}


func _player_state() -> Dictionary:
	var w := player.wounds
	var out := {"at": _arr(player.global_position), "facing": _facing(), "pitch": snappedf(player.get_pitch_degrees(), 0.1),
		"crouching": player.is_crouching, "weapon": _weapon_line()}
	if w and w.physiology:
		out["blood_ml"] = int(w.physiology.blood_ml)
		out["alive"] = w.physiology.alive
		out["conscious"] = w.physiology.is_conscious()
		out["wounds"] = w.physiology.wounds
		out["how"] = w.physiology.describe()
	return out


func _people() -> Array:
	var out := []
	for n in get_tree().get_nodes_in_group(&"people"):
		var man := n as HumanBody
		if man == null or not is_instance_valid(man) or man.physiology == null:
			continue
		var rel := man.global_position - player.global_position
		var e := {"name": String(man.person_id), "at": _arr(man.global_position), "distance_m": snappedf(rel.length(), 0.1),
			"bearing": _bearing(rel), "alive": man.physiology.alive, "conscious": man.physiology.is_conscious(),
			"armed": man.has_gun, "wounds": man.wounds.size()}
		var brain := man.get_node_or_null(^"Brain")
		if brain is OutlawBrain:
			e["mood"] = OutlawBrain.Mood.keys()[brain.mood].to_lower()
			e["tactic"] = OutlawBrain.Tactic.keys()[brain.tactic].to_lower()
			if brain.relations:
				e["toward_you"] = Relations.Stance.keys()[brain.relations.stance(player)].to_lower()
		elif brain is CivilianBrain:
			e["mood"] = CivilianBrain.Mood.keys()[brain.mood].to_lower()
		out.append(e)
	out.sort_custom(func(x, y) -> bool: return x.distance_m < y.distance_m)
	return out


func _looking_at() -> Dictionary:
	var hit := _look_hit()
	if hit.is_empty():
		return {"what": "nothing within 80 m (sky)"}
	var c: Object = hit.collider
	var d := snappedf((hit.position as Vector3).distance_to(_view_camera().global_position), 0.1)
	var out := {"distance_m": d}
	if c is StructureMember:
		var m := c as StructureMember
		var s := m.get_parent()
		while s and not s is Structure:
			s = s.get_parent()
		out["what"] = "%s %s of %s" % [m.wood, m.kind, (s as Structure).structure_id if s else "?"]
		out["member"] = String(m.member_id)
		out["burning"] = m.burning
	else:
		var n := c as Node
		var man: Node = n
		while man and not man is HumanBody:
			man = man.get_parent()
		if man:
			out["what"] = "%s (person)" % (man as HumanBody).person_id
		else:
			out["what"] = String(n.name) if n else "?"
	return out


func _counts() -> Dictionary:
	var fire := FireSystem.find(get_tree())
	var burning := 0
	var broken := 0
	for s in street.find_children("*", "StructureMember", true, false):
		if s.broken:
			broken += 1
		if s.burning:
			burning += 1
	return {"members_broken": broken, "members_burning": burning, "people": get_tree().get_nodes_in_group(&"people").size(),
		"fire": fire != null}


func _weapon_line() -> String:
	var w := player.weapon
	if w == null:
		return "none"
	var kind := "revolver" if w is RevolverViewmodel else "shotgun" if w is ShotgunViewmodel else "dynamite" if w is DynamiteViewmodel else "?"
	var drawn := w.drawn
	var loads := ""
	if "state" in w and w.state and w.state.has_method("to_dict"):
		var st: Dictionary = w.state.to_dict()
		if st.has("chambers"):
			loads = ", %d loaded" % (st.chambers as Array).count(1)
		elif st.has("barrels"):
			loads = ", %d loaded, %d cocked%s" % [(st.barrels as Array).count(1), (st.cocked as Array).count(true), ", open" if st.open else ""]
		if st.has("hammer"):
			loads += ", hammer %s" % ["down", "half cock", "cocked"][int(st.hammer)]
	return "%s %s%s" % [kind, "in hand" if drawn else "put away", loads]


# -- Helpers -------------------------------------------------------------------------------------

func _vec(a: Array, i: int) -> Vector3:
	return Vector3(float(a[i]), float(a[i + 1]), float(a[i + 2]))


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


## Degrees: 0 = north (-Z, toward the saloon side), 90 = east (+X).
func _facing() -> float:
	var f := -player.global_basis.z
	return snappedf(fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0), 1.0)


## Where a point is from where you face: "ahead", "12° right", "behind".
func _bearing(rel: Vector3) -> String:
	var f := -player.global_basis.z
	var ang := rad_to_deg(Vector2(f.x, f.z).angle_to(Vector2(rel.x, rel.z)))
	if absf(ang) < 8.0:
		return "ahead"
	if absf(ang) > 150.0:
		return "behind"
	return "%d° %s" % [int(absf(ang)), "right" if ang > 0.0 else "left"]


## Press or let go of an action as a key would: through the input events (Input.action_press
## from a physics callback isn't "just pressed" to the guns, which read their keys in _process).
func _act(down: bool, action: StringName) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _set_view(yaw: float, pitch_degrees: float) -> void:
	player.rotation.y = yaw
	var delta := pitch_degrees - player.get_pitch_degrees()
	var was := player.input_enabled
	player.input_enabled = true
	player.add_look(Vector2(0.0, delta))
	player.input_enabled = was


func _face(target: Vector3) -> void:
	var eye := player.camera.global_position
	var to := target - eye
	_set_view(atan2(-to.x, -to.z), rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length())))


func _view_camera() -> Camera3D:
	return _free_camera if _free_camera else player.camera


func _look_hit() -> Dictionary:
	var cam := _view_camera()
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - cam.global_basis.z * 80.0)
	q.exclude = [player.get_rid()]
	q.collide_with_areas = false
	return cam.get_world_3d().direct_space_state.intersect_ray(q)


func _chest(man: HumanBody) -> Vector3:
	var chest := man.parts.get(&"chest") as Node3D
	return chest.global_position if chest else man.global_position + Vector3.UP * 1.3


func _person(name: String) -> HumanBody:
	for n in get_tree().get_nodes_in_group(&"people"):
		if n is HumanBody and String((n as HumanBody).person_id).to_lower() == name.to_lower():
			return n
	return null


func _town() -> TownLife:
	return street.get_node_or_null(^"TownLife") as TownLife


func _places() -> Waypoints:
	var t := _town()
	return t.places if t else Waypoints.test_street()


func _clock() -> DayCycle:
	return street.find_child("DayCycle", true, false) as DayCycle
