extends Node
## The perception lab's runner (README.md beside this file): one group of cases (or one case) in the
## running street. Everyone in town is taken out first (TownLife stopped, its people freed), the
## player sent far off, the clock stopped; then each case puts the Studio's men where scenarios.json
## says, with the game's own `Senses` (bare, for sight and hearing) or its own brains
## (`CivilianBrain`, `OutlawBrain`: search, news, leaks), and logs what they saw, heard and did.
##
## Every case is judged against expectations written by hand in scenarios.json (what any person
## standing there would have noticed); none of it changes how the game plays. What the lab itself
## does to set a case up (a fight started by `_provoked`, a gunman told to hold his fire) is named
## in the case's `setup` and in the README.

const DATA := "res://experiments/perception_lab/scenarios.json"
## Where the player waits when a case doesn't use him: beyond anyone's sight (60 m) and earshot of
## his footsteps, on the open range.
const PLAYER_AWAY := Vector3(40.0, 0.0, -120.0)
## The lab's own line of sight (for "could he have seen him at all?"), on the layer Senses uses.
const SAMPLE_EVERY := 0.25

var lab: Node
var want := ""
var seed_value := 1
var out_dir := ""

var _data := {}
var _street: Node3D
var _clock: DayCycle
var _places: Waypoints
var _men: Array[HumanBody] = []
var _player_used := false
## Per-frame jobs: Callables run every physics frame while a case is on (walking a target,
## holding a gunman's fire, sampling).
var _every_frame: Array[Callable] = []
## Undone when a case ends (signal connections a case made to the event bus).
var _cleanups: Array[Callable] = []
var _catcher: ErrorCatcher


class ErrorCatcher extends Logger:
	var errors: Array[String] = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		errors.append("%s:%d %s: %s" % [file, line, function, rationale if rationale != "" else code])
	func _log_message(_message: String, _error: bool) -> void:
		pass


# --- The scenarios --------------------------------------------------------------------------------

static func data() -> Dictionary:
	var f := FileAccess.open(DATA, FileAccess.READ)
	return JSON.parse_string(f.get_as_text()) if f else {}


static func groups() -> Array:
	return ["sight", "hearing", "search", "news", "leaks"]


static func case_names() -> Array:
	var d := data()
	var out := []
	for g: String in groups():
		for c: Dictionary in (d[g].cases as Array):
			out.append(String(c.name))
	return out


## What a man knows right now: his Senses' table, and his stance to each (the gunfight lab can
## call this too, through `perception_known`).
static func knowledge(man: HumanBody, bl: Node) -> Dictionary:
	var s := man.get_node_or_null(^"Brain/Senses") as Senses
	if s == null:
		s = man.find_child("Senses", true, false) as Senses
	if s == null:
		return {"ok": false, "error": "%s has no Senses" % man.person_id}
	var out := {"who": String(man.person_id), "clock": snappedf(s.now(), 0.01), "known": {}}
	for who: Variant in s.known.keys():
		if not is_instance_valid(who):
			continue
		var k: Dictionary = s.known[who]
		out.known[_id(who)] = {"seen": k.seen, "awareness": snappedf(k.awareness, 0.01),
				"last_pos": _v3(k.last_pos, bl), "since_seen": snappedf(s.since_seen(who), 0.01),
				"heard_pos": _v3(k.heard_pos, bl), "since_known": snappedf(s.since_known(who), 0.01),
				"true_pos": bl.arr((who as Node3D).global_position)}
	var brain := man.get_node_or_null(^"Brain")
	if brain is OutlawBrain:
		out["relations"] = (brain as OutlawBrain).relations.to_dict()
		out["mood"] = OutlawBrain.Mood.keys()[(brain as OutlawBrain).mood]
	elif brain is CivilianBrain:
		out["mood"] = CivilianBrain.Mood.keys()[(brain as CivilianBrain).mood]
	return out


static func _v3(v: Vector3, bl: Node) -> Variant:
	return null if v == Vector3.INF else bl.arr(v)


static func _id(who: Object) -> String:
	if who is HumanBody:
		return String((who as HumanBody).person_id)
	if who is Player:
		return "player"
	return str(who)


# --- The run --------------------------------------------------------------------------------------

func run() -> Dictionary:
	_data = data()
	if _data.is_empty():
		return {"ok": false, "error": "no %s" % DATA}
	var todo := []  # [group, case]
	for g: String in groups():
		for c: Dictionary in (_data[g].cases as Array):
			if want == g or want == "all" or want == String(c.name):
				todo.append([g, c])
	if todo.is_empty():
		return {"ok": false, "error": "no group or case %s (perception_list)" % want}
	_street = lab.street as Node3D
	DirAccess.make_dir_recursive_absolute(out_dir)
	_catcher = ErrorCatcher.new()
	OS.add_logger(_catcher)
	_quiet_town()
	await lab.seconds(0.5)
	var results := []
	for job: Array in todo:
		var g: String = job[0]
		var c: Dictionary = job[1]
		var lights: Array = c.get("lights", _data[g].get("lights", [""]))
		for light: String in lights:
			_set_light(light if light != "" else String(c.get("light", "day")))
			var r: Dictionary
			match g:
				"sight": r = await _sight(c, light)
				"hearing": r = await _hearing(c)
				"search": r = await _search(c)
				"news": r = await _news(c)
				"leaks": r = await _leak(c)
			r["group"] = g
			r["case"] = String(c.name)
			r["light"] = light if light != "" else String(c.get("light", "day"))
			r["daylight"] = snappedf(_clock.get_daylight(), 0.001) if _clock else -1.0
			results.append(r)
			await _clear_case()
	OS.remove_logger(_catcher)
	var out := {"want": want, "seed": seed_value, "results": results, "errors": _catcher.errors}
	out["counts"] = _counts(results)
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " ", false))
	f.close()
	return out


func _counts(results: Array) -> Dictionary:
	var n := {"cases": results.size(), "false": 0, "missed": 0, "slow": 0, "leaks": 0, "as_expected": 0}
	for r: Dictionary in results:
		for v: Dictionary in r.get("verdicts", []):
			var k: String = v.verdict
			if n.has(k):
				n[k] += 1
		n.leaks += (r.get("leaks", []) as Array).size()
	return n


## Everyone out of the street, the player far off, the clock stopped, seeded.
func _quiet_town() -> void:
	for tl in get_tree().get_nodes_in_group(&"town_life"):
		(tl as Node).process_mode = Node.PROCESS_MODE_DISABLED
	var town := _street.get_node_or_null(^"TownLife") as TownLife
	_places = town.places if town else Waypoints.test_street()
	for spawner in _street.find_children("*", "OutlawSpawner", true, false):
		(spawner as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for p in get_tree().get_nodes_in_group(&"people"):
		if p is HumanBody:
			(p as Node).queue_free()
	_player_away()
	_clock = _street.find_child("DayCycle", true, false) as DayCycle
	if _clock:
		_clock.set_time_scale(0.0)
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics:
		ballistics._rng.seed = 1873 + seed_value


func _player_away() -> void:
	var p: Player = lab.player
	if p == null:
		return
	p.global_position = PLAYER_AWAY
	p.velocity = Vector3.ZERO


## The light for a case: the clock's hour, and the lamps as the game would have them (`night_out`:
## every lamp put out).
func _set_light(name: String) -> void:
	var hours: Dictionary = _data.hours
	var h := float(hours.get(name, hours.get(name.get_slice("_", 0), 12.0)))
	if _clock:
		_clock.set_time(h)
	for l: Node in _street.find_children("*", "OilLamp", true, false):
		var lamp := l as OilLamp
		if lamp.broken:
			continue
		lamp.set_lit(false if name == "night_out" else lamp.should_be_lit(int(h)))


func _clear_case() -> void:
	_every_frame.clear()
	for undo in _cleanups:
		undo.call()
	_cleanups.clear()
	for m in _men:
		if is_instance_valid(m):
			m.queue_free()
	_men.clear()
	for n in _street.get_children():
		if n is GunSmoke or n is BlastCloud:
			n.queue_free()
	if _player_used:
		var p: Player = lab.player
		if p.weapon and p.weapon.has_method("put_away"):
			p.weapon.put_away()
		for a in [&"move_forward", &"run", &"aim", &"fire", &"cock"]:
			Input.action_release(a)
		_player_away()
		_player_used = false
	await lab.seconds(0.4)


func _physics_process(delta: float) -> void:
	for job in _every_frame.duplicate():
		job.call(delta)


# --- Making men -------------------------------------------------------------------------------

func _v(a: Variant) -> Vector3:
	var x: Array = a
	return Vector3(float(x[0]), float(x[1]), float(x[2]))


## Down onto whatever floor is under a point (a boardwalk, a building's floor, the street).
func _floor(p: Vector3) -> Vector3:
	var space := _street.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.5, p + Vector3.DOWN * 3.0, Layers.STAND)
	var hit := space.intersect_ray(q)
	return hit.position if not hit.is_empty() else p


func _body(role: String) -> StringName:
	var roles: Dictionary = _data.roles
	return StringName(roles.get(role, (_data.bodies as Array)[0]))


## A man of the Studio's (by his role) at a point, facing another. `mind`: "senses" (eyes and ears,
## nothing more), "civilian", "outlaw" or "" (none).
func _man(id: String, role: String, at: Vector3, faces: Vector3, mind := "", gun := false) -> HumanBody:
	var man := HumanBody.new()
	man.name = "Lab_" + id
	man.person_id = StringName(id)
	man.body_model = _body(role)
	man.rng_seed = seed_value * 100 + _men.size() + 1
	man.has_gun = gun
	var feet := _floor(at)
	match mind:
		"senses":
			var s := Senses.new()
			s.name = "Senses"
			man.add_child(s)
		"civilian":
			var b := CivilianBrain.new()
			b.name = "Brain"
			b.post = feet
			b.faces = faces
			b.places = _places
			b.fights_fire = false
			man.add_child(b)
		"outlaw":
			var b := OutlawBrain.new()
			b.name = "Brain"
			b.places = _places
			man.add_child(b)
	man.enter(_street, feet, HumanBody.yaw_toward(feet, faces))
	man.face(faces)
	_men.append(man)
	return man


func _senses(man: HumanBody) -> Senses:
	var s := man.get_node_or_null(^"Senses") as Senses
	if s == null:
		s = man.get_node_or_null(^"Brain/Senses") as Senses
	if s == null:
		s = man.find_child("Senses", true, false) as Senses
	return s


func _eye(who: Node3D) -> Vector3:
	if who is Player:
		return (who as Player).camera.global_position
	var h := who as HumanBody
	var head := h.parts.get(&"head") as Node3D if h else null
	return head.global_position if head else who.global_position + Vector3.UP * 1.6


## What the line between two points meets first on the layer Senses looks along (Layers.WORLD),
## with the two men's own bodies left out: "" if it's clear.
func _line(from: Vector3, to: Vector3, ignore: Array = []) -> String:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	var ex: Array[RID] = []
	for n in ignore:
		if n is CollisionObject3D:
			ex.append((n as CollisionObject3D).get_rid())
	q.exclude = ex
	var hit := _street.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.15:
		return ""
	var c := hit.collider as Node
	var path := String(_street.get_path_to(c)) if c and _street.is_ancestor_of(c) else (str(c.name) if c else "?")
	if c is StructureMember:
		path += " (%s)" % (c as StructureMember).kind
	return path


static func _bearing_error(from: Vector3, truth: Vector3, guess: Vector3) -> float:
	var a := Vector2(truth.x - from.x, truth.z - from.z)
	var b := Vector2(guess.x - from.x, guess.z - from.z)
	if a.length() < 0.01 or b.length() < 0.01:
		return 0.0
	return absf(rad_to_deg(a.angle_to(b)))


func _now() -> float:
	return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)


## A judged expectation: "see"/"hear" true (should have), false (shouldn't have), "either".
func _verdict(what: String, expect: Variant, got: bool, delay := -1.0, notice := -1.0) -> Dictionary:
	var v := {"what": what, "expect": expect, "got": got}
	if expect is bool:
		if expect and not got:
			v.verdict = "missed"
		elif not expect and got:
			v.verdict = "false"
		elif expect and notice > 0.0 and delay > notice:
			v.verdict = "slow"
		else:
			v.verdict = "as_expected"
	else:
		v.verdict = "either"
	if delay >= 0.0:
		v.delay_s = snappedf(delay, 0.01)
	return v


# --- Sight ------------------------------------------------------------------------------------

## A man watching (eyes only) and a man he may or may not see, in one light, for a few seconds.
func _sight(c: Dictionary, light: String) -> Dictionary:
	var g: Dictionary = _data.sight
	var o_at := _v(c.observer.at)
	var t_at := _v(c.target.at)
	var watcher := _man("watcher", "watcher", o_at, _v(c.observer.faces), "senses")
	var s := _senses(watcher)
	s.process_mode = Node.PROCESS_MODE_DISABLED
	var target := _man("target", "target", t_at, _v(c.target.get("faces", c.observer.at)))
	await lab.seconds(0.6)  # both standing
	if c.target.has("pose"):
		target.set_pose(StringName(c.target.pose))
	var walk: Array = c.target.get("walk", [])
	if not walk.is_empty():
		var ends := [t_at, _floor(_v(walk))]
		var leg := [1]
		_every_frame.append(func(delta: float) -> void:
			if not is_instance_valid(target):
				return
			if target.walk_to(ends[leg[0]], float(c.target.get("speed", 1.3)), delta):
				leg[0] = 1 - leg[0])
	# What hides him, from the moment the watcher opens his eyes.
	var veil: Dictionary = c.get("veil", {})
	if veil.get("kind", "") == "smoke":
		for i in int(veil.get("clouds", 4)):
			GunSmoke.spawn(_street, _v(veil.at) + Vector3(0.0, 0.0, (i - 1.5) * 0.4), Vector3.RIGHT if i % 2 == 0 else Vector3.LEFT, 1.0)
	elif veil.get("kind", "") == "dust":
		BlastCloud.spawn(_street, _v(veil.at), float(veil.get("kg", 0.2)))
	var line := _line(s.eye(), _eye(target), [target, watcher])
	var t0 := _now()
	var spotted := [-1.0]
	var lost := [-1.0]
	var peak := [0.0]
	s.spotted.connect(func(who: Node3D) -> void:
		if who == target and spotted[0] < 0.0:
			spotted[0] = _now() - t0)
	s.lost.connect(func(who: Node3D) -> void:
		if who == target and lost[0] < 0.0:
			lost[0] = _now() - t0)
	_every_frame.append(func(_d: float) -> void:
		peak[0] = maxf(peak[0], s.aware_of(target)))
	s.process_mode = Node.PROCESS_MODE_INHERIT
	var window := float(c.get("window_s", g.seconds))
	await lab.seconds(window)
	var seen_in_window: bool = spotted[0] >= 0.0
	var light_used := s._light()
	var expect: Variant = (c.expect as Dictionary).get(light, (c.expect as Dictionary).get("all", "either"))
	var r := {"watcher": String(watcher.body_model), "target": String(target.body_model),
			"distance_m": snappedf(s.eye().distance_to(_eye(target)), 0.1),
			"angle_deg": snappedf(rad_to_deg(s.facing().angle_to(_eye(target) - s.eye())), 0.1),
			"line": line, "senses_light": snappedf(light_used, 0.001), "spotted_s": snappedf(spotted[0], 0.01),
			"lost_s": snappedf(lost[0], 0.01), "awareness_peak": snappedf(peak[0], 0.01),
			"seen_at_end": s.sees(target), "window_s": window, "why": c.get("why", "")}
	r["verdicts"] = [_verdict("sees the target", expect, seen_in_window, spotted[0],
			float(c.get("notice_s", g.notice_s)) if expect is bool and expect else -1.0)]
	return r


# --- Hearing ----------------------------------------------------------------------------------

## A sound made once (a shot, a shout, a hammer cocked) or a walk (footsteps), and men with ears
## round it: who heard, what he took it for, where he thinks it was, and whether he now knows who.
func _hearing(c: Dictionary) -> Dictionary:
	var src: Dictionary = c.source
	var kind := String(src.kind)
	var listeners := []
	for i in (c.listeners as Array).size():
		var l: Dictionary = c.listeners[i]
		var man := _man("ear%d" % i, "listener", _v(l.at), _v(l.get("faces", src.at)), "senses")
		listeners.append(man)
	var maker: Node3D
	if kind in ["gunshot", "shout"]:
		maker = _man("maker", "maker", _v(src.at), _v(src.get("faces", [0, 0, -9])))
	else:
		maker = lab.player
		_player_used = true
		var p: Player = lab.player
		p.global_position = _floor(_v(src.at)) + Vector3.UP * 0.05
		p.velocity = Vector3.ZERO
		lab.bridge._face(_v(src.get("faces", [0, 1.5, -9])))
	await lab.seconds(0.8)
	if kind == "cock":
		await lab.bridge._cmd_weapon(["revolver"])
		await lab.seconds(1.0)
	var heard := {}  # listener -> [{t, at, kind, who, truth}]
	var t0 := _now()
	for man: HumanBody in listeners:
		var s := _senses(man)
		s.known.clear()
		heard[man] = []
		s.heard.connect(func(at: Vector3, k: StringName, who: Node) -> void:
			var truth := (who as Node3D).global_position if who is Node3D else Vector3.INF
			(heard[man] as Array).append({"t": _now() - t0, "at": at, "kind": String(k), "who": _id(who) if who else "",
					"truth": truth}))
	var origin := Vector3.INF
	match kind:
		"gunshot":
			origin = maker.global_position + Vector3.UP * 1.4
			Events.shot_fired.emit(origin, _v(src.get("dir", [0, -1, 0])).normalized(), maker)
			await lab.seconds(float(c.get("seconds", 2.0)))
		"shout":
			origin = maker.global_position + Vector3.UP * 1.6
			Events.shouted.emit(maker, &"shout")
			await lab.seconds(float(c.get("seconds", 2.0)))
		"cock":
			origin = (lab.player as Player).camera.global_position
			await lab.bridge._cmd_press(["cock"])
			await lab.seconds(float(c.get("seconds", 2.0)))
		"steps":
			var to := _v(src.to)
			if src.get("run", false):
				lab.bridge._act(true, &"run")
			await lab.bridge._cmd_walk([str(to.x), str(to.z)])
			lab.bridge._act(false, &"run")
			await lab.seconds(1.0)
	var rows := []
	var verdicts := []
	for i in listeners.size():
		var man: HumanBody = listeners[i]
		var l: Dictionary = c.listeners[i]
		var s := _senses(man)
		var got: Array = (heard[man] as Array).filter(func(h: Dictionary) -> bool: return h.kind == _kind_of(kind))
		var ear := s.eye()
		var row := {"listener": String(l.name), "body": String(man.body_model), "heard": got.size(),
				"wall": _line(ear, origin if origin != Vector3.INF else maker.global_position + Vector3.UP, [man, maker]) if kind != "steps" else "",
				"distance_m": snappedf(ear.distance_to(origin if origin != Vector3.INF else maker.global_position), 0.1)}
		if not got.is_empty():
			var h: Dictionary = got[0]
			var truth: Vector3 = origin if origin != Vector3.INF else h.truth
			row["first_s"] = snappedf(h.t, 0.01)
			row["took_it_for"] = h.kind
			row["guess_error_m"] = snappedf(Vector2(h.at.x - truth.x, h.at.z - truth.z).length(), 0.01)
			row["bearing_error_deg"] = snappedf(_bearing_error(ear, truth, h.at), 0.1)
			row["knows_who"] = s.known.has(maker) and float(s.known[maker].heard_time) > -INF and not s.sees(maker)
			row["saw_maker"] = s.sees(maker)
			if kind == "steps":
				row["steps_heard"] = got.size()
				row["nearest_heard_m"] = snappedf(got.map(func(x: Dictionary) -> float: return ear.distance_to(x.truth)).min(), 0.1)
				row["farthest_heard_m"] = snappedf(got.map(func(x: Dictionary) -> float: return ear.distance_to(x.truth)).max(), 0.1)
		rows.append(row)
		var ex: Dictionary = l.expect
		verdicts.append(_verdict("%s hears it" % l.name, ex.get("hear", "either"), not got.is_empty(),
				row.get("first_s", -1.0), float(ex.get("notice_s", 0.5)) if kind != "steps" and ex.get("hear", "either") is bool and ex.hear else -1.0))
		if ex.has("who") and not got.is_empty():
			verdicts.append(_verdict("%s knows who made it" % l.name, ex.who, row.get("knows_who", false)))
		if ex.has("bearing_deg") and not got.is_empty():
			verdicts.append(_verdict("%s can tell where (within %d deg)" % [l.name, int(ex.bearing_deg)], true,
					float(row.bearing_error_deg) <= float(ex.bearing_deg)))
	return {"source": kind, "at": lab.arr(_v(src.at)), "listeners": rows, "verdicts": verdicts, "why": c.get("why", ""),
			"noise_reach_m": _reach_of(kind, src)}


static func _kind_of(kind: String) -> String:
	return {"gunshot": "gunshot", "shout": "shout", "steps": "footsteps", "cock": "cock"}.get(kind, kind)


## How far the game says each sound carries (DeedWatch, Player._footsteps): for the table.
static func _reach_of(kind: String, src: Dictionary) -> float:
	match kind:
		"gunshot": return DeedWatch.GUNSHOT
		"shout": return DeedWatch.SHOUT
		"steps": return 13.0 if src.get("run", false) else 6.0
	return 0.0


# --- Watching brains: what they act on ----------------------------------------------------------

## Samples a man with a brain every SAMPLE_EVERY s for what he knows of `who` against the truth:
## whether he could see him at all (a clear line from his eye, whichever way he faces), whether he
## heard him lately, and where he faces and goes. Knowledge from no sense (his last-known moved
## while he neither saw nor heard) and facing the man's true place unseen are logged as leaks.
func _watch(man: HumanBody, who: Node3D, log: Array, leaks: Array, tag: String) -> void:
	var s := _senses(man)
	var heard_at := [-INF]
	var was := [s.last_known(who) if s.known.has(who) else Vector3.INF]
	var next := [0.0]
	var t0 := _now()
	s.heard.connect(func(_at: Vector3, _k: StringName, src: Node) -> void:
		if src == who:
			heard_at[0] = _now())
	# Things that may tell him where the man is without his seeing or hearing him: noted, so a leak
	# can say where it came from.
	var told := [""]
	var on_deed := func(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
		if actor == who:
			told[0] = "deed %s against %s" % [kind, _id(target) if target else "nobody"]
	var on_miss := func(person: Node, shooter: Node, _d: float, _a: Vector3, _s: float, _t: bool) -> void:
		if person == man and shooter == who:
			told[0] = "near miss"
	Events.deed.connect(on_deed)
	Events.near_miss.connect(on_miss)
	_cleanups.append(func() -> void:
		Events.deed.disconnect(on_deed)
		Events.near_miss.disconnect(on_miss))
	_every_frame.append(func(_d: float) -> void:
		if not is_instance_valid(man) or not is_instance_valid(who) or not man.physiology.is_conscious():
			return
		var now := _now()
		var lk := s.last_known(who)
		# Could he have seen him at all: a clear line, within the edge of his eye (Senses.PERIPHERAL).
		var could_see := _line(s.eye(), _eye(who), [man, who]) == "" \
				and rad_to_deg(s.facing().angle_to(_eye(who) - s.eye())) <= Senses.PERIPHERAL
		var heard_lately: bool = now - heard_at[0] < 0.3
		# Knowledge that came from nowhere: his idea of where the man is moved, and he neither saw
		# him (Senses says not) nor heard him this tick.
		if lk != Vector3.INF and was[0] != lk and not s.sees(who) and not heard_lately:
			var moved: float = INF if was[0] == Vector3.INF else (lk as Vector3).distance_to(was[0])
			if moved > 0.5:
				leaks.append({"t": snappedf(now - t0, 0.01), "who": tag, "kind": "knows_without_sensing",
						"told_by": told[0] if told[0] != "" else "(no event: a brain's own note)",
						"error_m": snappedf(Vector2(lk.x - who.global_position.x, lk.z - who.global_position.z).length(), 0.1),
						"could_see": could_see, "wall": "" if could_see else _line(s.eye(), _eye(who), [man, who])})
		was[0] = lk
		told[0] = ""
		if now < next[0]:
			return
		next[0] = now + SAMPLE_EVERY
		var fwd := s.facing()
		var to_true := who.global_position - man.global_position
		var to_lk := (lk - man.global_position) if lk != Vector3.INF else Vector3.ZERO
		var a_true := rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(to_true.x, to_true.z)))
		var a_lk := rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(to_lk.x, to_lk.z))) if lk != Vector3.INF else 180.0
		var brain := man.get_node_or_null(^"Brain")
		var row := {"t": snappedf(now - t0, 0.01), "who": tag, "at": lab.arr(man.global_position), "sees": s.sees(who),
				"could_see": could_see, "heard_lately": now - heard_at[0] < 1.0,
				"last_known": _v3(lk, lab), "true": lab.arr(who.global_position),
				"lk_error_m": snappedf(Vector2(lk.x - who.global_position.x, lk.z - who.global_position.z).length(), 0.1) if lk != Vector3.INF else -1.0,
				"face_true_deg": snappedf(absf(a_true), 0.1), "face_lk_deg": snappedf(absf(a_lk), 0.1),
				"since_known": snappedf(s.since_known(who), 0.01)}
		if brain is OutlawBrain:
			var ob := brain as OutlawBrain
			row["mood"] = OutlawBrain.Mood.keys()[ob.mood]
			row["tactic"] = OutlawBrain.Tactic.keys()[ob.tactic]
			row["stance"] = Relations.Stance.keys()[ob.relations.stance(who)]
		elif brain is CivilianBrain:
			row["mood"] = CivilianBrain.Mood.keys()[(brain as CivilianBrain).mood]
		log.append(row)
		# Facing the man's true place though he can't see him, hasn't heard him lately, and isn't
		# facing where he thinks he is: he's acting on what he couldn't know.
		if not could_see and not s.sees(who) and now - heard_at[0] > 1.0 and absf(a_true) < 12.0 and absf(a_lk) > 30.0 \
				and man.global_position.distance_to(who.global_position) > 3.0:
			leaks.append({"t": row.t, "who": tag, "kind": "faces_unseen", "face_true_deg": row.face_true_deg,
					"face_lk_deg": row.face_lk_deg, "wall": _line(s.eye(), _eye(who), [man, who])}))


## Starts the fight a case needs (the lab's doing, named in the case's setup): as if `by` had shot
## at him.
func _provoke(man: HumanBody, by: Node3D) -> void:
	(man.get_node(^"Brain") as OutlawBrain)._provoked(by)


## A gunman who holds his fire (the lab's doing): his next shot never comes.
func _hold_fire(man: HumanBody) -> void:
	var b := man.get_node(^"Brain") as OutlawBrain
	_every_frame.append(func(_d: float) -> void:
		if is_instance_valid(b):
			b._next_shot = 99.0)


func _put_player(at: Vector3, faces: Vector3) -> void:
	var p: Player = lab.player
	_player_used = true
	p.global_position = _floor(at) + Vector3.UP * 0.05
	p.velocity = Vector3.ZERO
	lab.bridge._face(faces)


## The player walks a route (each point in turn, as the bridge's `walk` does: real input, so his
## footsteps sound).
func _walk_player(route: Array, run := false) -> void:
	if run:
		lab.bridge._act(true, &"run")
	for pt: Array in route:
		await lab.bridge._cmd_walk([str(float(pt[0])), str(float(pt[2]))])
	lab.bridge._act(false, &"run")


# --- Search -----------------------------------------------------------------------------------

## A gunman in a fight with the player (holding his fire), who then loses him behind cover: when
## he knows he's lost him, where he thinks he is, where he looks, how long he keeps at it.
func _search(c: Dictionary) -> Dictionary:
	var hunter := _man("hunter", "hunter", _v(c.hunter.at), _v(c.hunter.faces), "outlaw", true)
	_put_player(_v(c.player.at), _v(c.hunter.at) + Vector3.UP * 1.5)
	await lab.seconds(1.0)
	var log := []
	var leaks := []
	var events := []
	var s := _senses(hunter)
	var p: Player = lab.player
	var brain := hunter.get_node(^"Brain") as OutlawBrain
	_hold_fire(hunter)
	var t0 := _now()
	s.lost.connect(func(who: Node3D) -> void:
		if who == p:
			events.append({"t": snappedf(_now() - t0, 0.01), "event": "lost", "true_at": lab.arr(p.global_position),
					"last_known": lab.arr(s.last_known(p))}))
	s.spotted.connect(func(who: Node3D) -> void:
		if who == p:
			events.append({"t": snappedf(_now() - t0, 0.01), "event": "spotted"}))
	brain.mood_changed.connect(func(m: int) -> void:
		events.append({"t": snappedf(_now() - t0, 0.01), "event": "mood " + String(OutlawBrain.Mood.keys()[m])}))
	var said := func(who: Node, text: String) -> void:
		if who == hunter:
			events.append({"t": snappedf(_now() - t0, 0.01), "event": "says \"%s\"" % text})
	Events.spoke.connect(said)
	if s.sees(p):
		events.append({"t": 0.0, "event": "spotted (before the fight)"})
	_watch(hunter, p, log, leaks, "hunter")
	_provoke(hunter, p)
	await lab.seconds(float(c.get("before_s", 2.5)))
	var hide_from := _now() - t0
	await _walk_player(c.player.route, bool(c.player.get("run", false)))
	var hidden_at := _now() - t0
	var spot := p.global_position
	var pace: Array = c.player.get("pace", [])
	var stay := float(c.get("hide_s", 40.0))
	var until := _now() + stay
	while _now() < until:
		if pace.is_empty():
			await lab.seconds(minf(1.0, until - _now()))
		else:
			await _walk_player(pace)
			await _walk_player([lab.arr(spot)])
	Events.spoke.disconnect(said)
	# The numbers.
	# When he truly lost him: the start of the unseen stretch the player was in when he got to his
	# hiding place (the hunter ducking into cover earlier doesn't count).
	var lost_truth := -1.0
	for row: Dictionary in log:
		if row.t > hidden_at:
			break
		if row.could_see:
			lost_truth = -1.0
		elif lost_truth < 0.0 and row.t >= hide_from:
			lost_truth = row.t
	var lost_ev := events.filter(func(e: Dictionary) -> bool: return e.event == "lost" and e.t >= lost_truth - SAMPLE_EVERY) \
			if lost_truth >= 0.0 else []
	var after := log.filter(func(row: Dictionary) -> bool: return row.t >= hidden_at)
	var near_lk := INF
	var near_true := INF
	for row: Dictionary in after:
		var at := _v(row.at)
		if row.last_known != null:
			near_lk = minf(near_lk, Vector2(at.x - row.last_known[0], at.z - row.last_known[2]).length())
		near_true = minf(near_true, Vector2(at.x - spot.x, at.z - spot.z).length())
	var gave_up := events.filter(func(e: Dictionary) -> bool: return e.event == "mood CALM" and e.t >= hide_from)
	# Found him again (saw him after he'd hidden): then giving up isn't judged.
	var found := events.filter(func(e: Dictionary) -> bool: return e.event == "spotted" and e.t > hidden_at)
	var r := {"setup": "the lab starts the fight (OutlawBrain._provoked by the player) and holds his fire (_next_shot)",
			"hunter": String(hunter.body_model), "hide_from_s": snappedf(hide_from, 0.01), "hidden_at_s": snappedf(hidden_at, 0.01),
			"spot": lab.arr(spot), "lost_truth_s": lost_truth, "lost_senses_s": lost_ev[0].t if not lost_ev.is_empty() else -1.0,
			"lost_delay_s": snappedf(lost_ev[0].t - lost_truth, 0.01) if not lost_ev.is_empty() and lost_truth >= 0.0 else -1.0,
			"lk_error_at_loss_m": snappedf(Vector2(lost_ev[0].true_at[0] - lost_ev[0].last_known[0], lost_ev[0].true_at[2] - lost_ev[0].last_known[2]).length(), 0.1) if not lost_ev.is_empty() else -1.0,
			"nearest_to_last_known_m": snappedf(near_lk, 0.1), "nearest_to_true_spot_m": snappedf(near_true, 0.1),
			"gave_up_s": gave_up[0].t if not gave_up.is_empty() else -1.0,
			"found_again_s": snappedf(found[0].t - hidden_at, 0.01) if not found.is_empty() else -1.0,
			"remembered_s": snappedf(gave_up[0].t - hidden_at, 0.01) if not gave_up.is_empty() else -1.0,
			"events": events, "leaks": leaks, "why": c.get("why", "")}
	var ex: Dictionary = c.get("expect", {})
	var verdicts := []
	if ex.has("finds"):
		verdicts.append(_verdict("finds him (within 2 m of his true spot)", ex.finds, near_true <= 2.0))
	if ex.has("goes_to_last_known"):
		verdicts.append(_verdict("goes to where he last knew him (within 2 m)", ex.goes_to_last_known, near_lk <= 2.0))
	if ex.has("gives_up_within_s") and found.is_empty():
		verdicts.append(_verdict("gives up within %d s of losing him" % int(ex.gives_up_within_s), true,
				not gave_up.is_empty() and float(gave_up[0].t) - hidden_at <= float(ex.gives_up_within_s)))
	var saw_first := events.any(func(e: Dictionary) -> bool: return String(e.event).begins_with("spotted") and e.t < hidden_at)
	if ex.has("saw_him_before_he_hid"):
		verdicts.append(_verdict("sees him at all before he hides", ex.saw_him_before_he_hid, saw_first))
	if ex.has("knows_lost_within_s") and saw_first:
		verdicts.append(_verdict("knows he's lost him within %.1f s" % float(ex.knows_lost_within_s), true,
				not lost_ev.is_empty(), float(r.lost_delay_s), float(ex.knows_lost_within_s)))
	r["verdicts"] = verdicts
	r["track"] = log
	return r


# --- News -------------------------------------------------------------------------------------

## Something happens in front of one man; who learns what, how, how soon. The people are the
## game's townsfolk minds (CivilianBrain); the player does the deed with real input.
func _news(c: Dictionary) -> Dictionary:
	var people := {}
	for pd: Dictionary in (c.people as Array):
		people[pd.id] = _man(String(pd.id), String(pd.role), _v(pd.at), _v(pd.faces), String(pd.get("mind", "civilian")),
				bool(pd.get("gun", false)))
	_put_player(_v(c.player.at), _v(c.player.faces))
	await lab.seconds(1.5)
	var p: Player = lab.player
	var t0 := _now()
	var log := []
	var leaks := []
	var shots := []
	var falls := []
	var speech := []
	var on_shot := func(origin: Vector3, _d: Vector3, shooter: Node) -> void:
		var row := {"t": snappedf(_now() - t0, 0.01), "at": lab.arr(origin), "by": _id(shooter), "seen_by": []}
		for id: String in people:
			var s := _senses(people[id])
			if s and s.sees(shooter):
				row.seen_by.append(id)
		shots.append(row)
	var on_fell := func(who: Node, _conscious: bool) -> void:
		var row := {"t": snappedf(_now() - t0, 0.01), "who": _id(who), "seen_by": []}
		for id: String in people:
			var s := _senses(people[id])
			if people[id] != who and s and s.sees(who):
				row.seen_by.append(id)
		falls.append(row)
	var on_spoke := func(who: Node, text: String) -> void:
		speech.append({"t": snappedf(_now() - t0, 0.01), "who": _id(who), "text": text})
	# The deeds each saw done (by the player, to anyone).
	var deeds_seen := {}
	var on_deed := func(actor: Node, kind: StringName, _target: Node, _at: Vector3) -> void:
		if actor != p or kind not in [&"draw", &"aim_at", &"shoot_at", &"hit", &"kill"]:
			return
		for id: String in people:
			var s := _senses(people[id])
			if s and s.sees(p):
				if not deeds_seen.has(id):
					deeds_seen[id] = []
				if String(kind) not in deeds_seen[id]:
					deeds_seen[id].append(String(kind))
	Events.deed.connect(on_deed)
	_cleanups.append(func() -> void: Events.deed.disconnect(on_deed))
	Events.shot_fired.connect(on_shot)
	Events.person_fell.connect(on_fell)
	Events.spoke.connect(on_spoke)
	var heard_gun := {}  # id -> the first gunshot he heard: {t, at}
	for id: String in people:
		_watch(people[id], p, log, leaks, id)
		var ear := _senses(people[id])
		ear.heard.connect(func(at: Vector3, k: StringName, _src: Node) -> void:
			if k == &"gunshot" and not heard_gun.has(id):
				heard_gun[id] = {"t": _now() - t0, "at": at})
	# The deed, by the player's own hands (bridge commands, real input).
	for cmd: Array in (c.deed as Array):
		var name := String(cmd[0])
		var args: Array = cmd.slice(1).map(func(x: Variant) -> String: return str(x))
		if name == "wait":
			await lab.seconds(float(args[0]))
		elif name == "walk":
			await _walk_player([[float(args[0]), 0.0, float(args[1])]])
		else:
			await lab.bridge.call("_cmd_" + name, args)
	var deed_done := _now() - t0
	# Then time passes, and what each man knows is taken at moments.
	var marks: Array = c.get("marks_s", [1, 5, 30, 90])
	var snaps := {}
	var first := float(shots[0].t) if not shots.is_empty() else deed_done
	for m: float in marks:
		var until := t0 + first + m
		if _now() < until:
			await lab.seconds(until - _now())
		snaps[str(m)] = _news_snapshot(people, p, shots, falls, heard_gun, deeds_seen, c)
	Events.shot_fired.disconnect(on_shot)
	Events.person_fell.disconnect(on_fell)
	Events.spoke.disconnect(on_spoke)
	var verdicts := []
	var last: Dictionary = snaps[str(marks[-1])]
	for id: String in (c.get("expect", {}) as Dictionary):
		var ex: Dictionary = c.expect[id]
		var k: Dictionary = last.get(id, {})
		for what: String in ex:
			verdicts.append(_verdict("%s %s (by %ds)" % [id, what.replace("_", " "), int(marks[-1])], ex[what], bool(k.get(what, false))))
	return {"setup": c.get("setup", ""), "shots": shots, "falls": falls, "speech": speech, "snapshots": snaps,
			"verdicts": verdicts, "leaks": leaks, "why": c.get("why", ""), "track_rows": log.size()}


## What each person knows of the deed now: heard a shot (and how near his guess of where), saw
## who fired, knows who fired (by any route), saw the man fall, and what his mind is doing.
func _news_snapshot(people: Dictionary, p: Player, shots: Array, falls: Array, heard_gun: Dictionary, deeds_seen: Dictionary, c: Dictionary) -> Dictionary:
	var out := {}
	var victim: HumanBody = people.get(String(c.get("victim", "")))
	for id: String in people:
		var man: HumanBody = people[id]
		if not is_instance_valid(man):
			continue
		var s := _senses(man)
		var k := {}
		var known_p: Dictionary = s.known.get(p, {})
		k["heard_shot"] = heard_gun.has(id)
		k["saw_shooter"] = shots.any(func(sh: Dictionary) -> bool: return id in sh.seen_by)
		# Who did it: he's seen the player (ever) or has him from a sound. (Senses.knows() alone
		# turns false the moment a man seen and not heard is out of sight: awareness fades from 1.)
		k["who_by_sight"] = float(known_p.get("last_time", -INF)) > -INF
		k["knows_who"] = k.who_by_sight or float(known_p.get("heard_time", -INF)) > -INF
		k["senses_knows"] = s.knows(p)
		k["saw_fall"] = falls.any(func(f: Dictionary) -> bool: return id in f.seen_by)
		k["deeds_seen"] = deeds_seen.get(id, [])
		k["knows_victim_hurt"] = k.saw_fall or "hit" in k.deeds_seen or "kill" in k.deeds_seen \
				or (victim != null and s.sees(victim) and victim.limp)
		var brain := man.get_node_or_null(^"Brain")
		if brain is CivilianBrain:
			var cb := brain as CivilianBrain
			k["mood"] = CivilianBrain.Mood.keys()[cb.mood]
			k["troubled_by"] = cb.troubled_by.filter(func(x: Variant) -> bool: return is_instance_valid(x)).map(func(x: Object) -> String: return _id(x))
			k["helped_by"] = _id(cb.helped_by) if cb.helped_by and is_instance_valid(cb.helped_by) else ""
		elif brain is OutlawBrain:
			var ob := brain as OutlawBrain
			k["mood"] = OutlawBrain.Mood.keys()[ob.mood]
			k["stance_to_player"] = Relations.Stance.keys()[ob.relations.stance(p)]
		k["knows_shooting"] = k.knows_victim_hurt and (k.saw_shooter or k.who_by_sight)
		k["knows_holdup"] = "aim_at" in k.deeds_seen
		if heard_gun.has(id) and not shots.is_empty():
			var o := _v(shots[0].at)
			var g: Vector3 = heard_gun[id].at
			k["heard_error_m"] = snappedf(Vector2(g.x - o.x, g.z - o.z).length(), 0.1)
			k["heard_at_s"] = snappedf(float(heard_gun[id].t), 0.01)
		# Who fired, known only from the shot's sound (Senses keys a noise by who made it).
		k["who_by_sound_only"] = float(known_p.get("heard_time", -INF)) > -INF and not k.who_by_sight
		out[id] = k
	return out


# --- Leaks ------------------------------------------------------------------------------------

## A man who could not know something, and whether he acts as if he did.
func _leak(c: Dictionary) -> Dictionary:
	var people := {}
	for pd: Dictionary in (c.people as Array):
		var man := _man(String(pd.id), String(pd.role), _v(pd.at), _v(pd.faces), String(pd.get("mind", "")), bool(pd.get("gun", false)))
		people[pd.id] = man
		if pd.has("friends"):
			var b := man.get_node(^"Brain") as OutlawBrain
			var fr: Array[StringName] = []
			for f: String in pd.friends:
				fr.append(StringName(f))
			b.friends = fr
			b.crew = Crew.new(man, fr)
			b.relations.friends = fr
	if c.has("player"):
		_put_player(_v(c.player.at), _v(c.player.faces))
	await lab.seconds(1.5)
	var p: Player = lab.player
	var watched: HumanBody = people[c.watch]
	var b := watched.get_node(^"Brain") as OutlawBrain
	var log := []
	var leaks := []
	var t0 := _now()
	var calls := []
	var on_call := func(who: Node, kind: StringName, about: Node, _at: Vector3) -> void:
		calls.append({"t": snappedf(_now() - t0, 0.01), "who": _id(who), "kind": String(kind), "about": _id(about) if about else ""})
	Events.callout.connect(on_call)
	_watch(watched, p, log, leaks, String(c.watch))
	var fear0 := b.fear
	var r := {"setup": c.get("setup", ""), "why": c.get("why", "")}
	match String(c.event):
		"player_shoots":
			for cmd: Array in (c.deed as Array):
				var args: Array = cmd.slice(1).map(func(x: Variant) -> String: return str(x))
				if String(cmd[0]) == "wait":
					await lab.seconds(float(args[0]))
				else:
					await lab.bridge.call("_cmd_" + String(cmd[0]), args)
			await lab.seconds(float(c.get("seconds", 5.0)))
			var e: Dictionary = b.relations.entries.get(p, {})
			r["stance_to_player"] = Relations.Stance.keys()[b.relations.stance(p)]
			r["pressure"] = snappedf(float(e.get("pressure", 0.0)), 0.01)
			r["grudge"] = snappedf(float(e.get("grudge", 0.0)), 0.01)
			r["knows_who"] = b.senses.knows(p)
			r["saw_player"] = b.senses.since_seen(p) < INF
			r["mood"] = OutlawBrain.Mood.keys()[b.mood]
		"mate_falls":
			var mate: HumanBody = people[c.mate]
			r["line"] = _line(b.senses.eye(), _eye(mate), [watched, mate])
			r["distance_m"] = snappedf(watched.global_position.distance_to(mate.global_position), 0.1)
			mate.go_limp(Vector3.ZERO)
			await lab.seconds(float(c.get("seconds", 4.0)))
			r["knows_mate_down"] = b.crew.out.has(mate)
			r["saw_mate"] = b.senses.since_seen(mate) < INF
			r["fear_change"] = snappedf(b.fear - fear0, 0.01)
			r["mood"] = OutlawBrain.Mood.keys()[b.mood]
		"call_out":
			b.agenda.clear()
			b.agenda.append({"do": &"call_out", "who": p, "patience": 30.0})
			await lab.seconds(float(c.get("seconds", 3.0)))
			var step: Dictionary = b.agenda[0] if not b.agenda.is_empty() else {}
			var spot: Vector3 = step.get("spot", Vector3.INF)
			r["spot"] = _v3(spot, lab)
			r["player_at"] = lab.arr(p.global_position)
			r["knew_player_before"] = false
			r["saw_player"] = b.senses.since_seen(p) < INF
			r["spot_dx_from_player_m"] = snappedf(absf(spot.x - p.global_position.x), 0.1) if spot != Vector3.INF else -1.0
			r["knows_who"] = b.senses.knows(p)
	Events.callout.disconnect(on_call)
	r["callouts"] = calls
	r["leaks"] = leaks
	var ex: Dictionary = c.get("expect", {})
	var verdicts := []
	for what: String in ex:
		var got: Variant = r.get(what, false)
		if got is String:
			got = got != "IGNORE" and got != "CALM" and got != ""
		elif got is float or got is int:
			got = float(got) > 0.0 if what != "spot_dx_from_player_m" else absf(float(got) - 12.0) < 1.0
		verdicts.append(_verdict(what.replace("_", " "), ex[what], bool(got)))
	r["verdicts"] = verdicts
	r["track"] = log
	return r
