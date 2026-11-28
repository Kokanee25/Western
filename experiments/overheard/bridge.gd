extends BridgeLab
## The listening bench (#1293, "Things to listen to"): what the player hears standing somewhere, and
## who is near whom to talk. `oh_start` begins a watch, `oh_stop` ends it and answers: every line
## said (who, the words, how far from you, the clock, whether it was an exchange's line), and how
## many game minutes each pair of the valley's men stood within 6 m of each other (and where).
## `run.py` stands the player at each spot for its hours and makes the table.

const HELP := {
	"oh_start": "oh_start -> begins a watch of every line said and who stands by whom",
	"oh_stop": "oh_stop -> ends it: {lines: [[who, text, metres from you, clock, kind, shown]], pairs: {a|b: game minutes within 6 m}, where: {a|b: spots}, s}",
	"oh_by": "oh_by PERSON [D] -> you stood D m (2.5) from PERSON, facing him",
	"oh_where": "oh_where -> each valley man in play: his spot, his place tags, metres from you",
}

const PAIR_M := 6.0
const SAMPLE_S := 5.0

var _on := false
var _lines: Array = []
var _pairs := {}
var _where := {}
var _t0 := 0.0
var _next := 0.0
var _hooked := false
## #1325: each sample, every exchange that might be on (its hours, not heard today) whose cast are all in
## play near you: why it isn't (the first that fails: a man not free, at a spot not of its place, apart,
## its `if`), counted.
var _why_not := {}


func _folk() -> ValleyFolk:
	return get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk


func _clock_text() -> String:
	var c := bridge._clock()
	return c.get_clock_text() if c != null else ""


func _hook() -> void:
	if _hooked:
		return
	_hooked = true
	Events.spoke.connect(func(who: Node, text: String) -> void: _note(who, text, "said", 1.0))
	if Events.has_signal(&"overheard"):
		Events.connect(&"overheard", func(who: Node, text: String, info: Dictionary) -> void:
			_note(who, text, "exchange:" + String(info.get("exchange", "")), float(info.get("clarity", 1.0))))


func _note(who: Node, text: String, kind: String, clarity: float) -> void:
	if not _on or not (who is Node3D) or player == null:
		return
	var pid := String(who.get("person_id")) if who.get("person_id") != null else ""
	_lines.append([pid, text, snappedf((who as Node3D).global_position.distance_to(player.global_position), 0.1),
			_clock_text(), kind, snappedf(clarity, 0.01)])


func _cmd_oh_start(_a: Array) -> Dictionary:
	_hook()
	_on = true
	_lines = []
	_pairs = {}
	_where = {}
	_why_not = {}
	_t0 = bridge._game_seconds()
	_next = _t0
	return {"clock": _clock_text()}


func _cmd_oh_stop(_a: Array) -> Dictionary:
	_on = false
	var pairs := {}
	for k: String in _pairs:
		# Game minutes: a sample each SAMPLE_S real seconds; a game hour is 112.5 s (config/day_cycle.tres).
		pairs[k] = snappedf(float(_pairs[k]) * SAMPLE_S / 112.5 * 60.0, 1.0)
	var vf := _folk()
	return {"lines": _lines, "pairs": pairs, "where": _where, "s": snappedf(bridge._game_seconds() - _t0, 0.1),
			"clock": _clock_text(), "ended": vf.overheard.ended if vf != null and vf.overheard != null else [],
			"why_not": _why_not}


func _men() -> Dictionary:
	var out := {}
	var vf := _folk()
	if vf == null:
		return out
	for pid: StringName in vf.people:
		var man: HumanBody = vf.people[pid]
		if man == null or not is_instance_valid(man) or not man.is_inside_tree() or vf.state.get(pid) != &"in":
			continue
		out[pid] = man
	return out


func _spot_name(vf: ValleyFolk, pid: StringName) -> String:
	var p := vf._person(pid)
	if not p.has("day"):
		return ""
	var b := vf.block_now(p, vf.hour())
	return "%s:%s" % [b.get("at", b.get("in", "?")), b.get("do", "")]


func _cmd_oh_where(_a: Array) -> Dictionary:
	var vf := _folk()
	var out := {}
	var men := _men()
	for pid: StringName in men:
		var man: HumanBody = men[pid]
		out[String(pid)] = {"spot": _spot_name(vf, pid), "d": snappedf(man.global_position.distance_to(player.global_position), 0.1),
				"tags": vf.overheard.tags_of(pid, man) if vf.get("overheard") != null else []}
	return {"men": out, "clock": _clock_text()}


func _cmd_oh_by(a: Array) -> Dictionary:
	var man := person(String(a[0])) if a.size() > 0 else null
	if man == null:
		return {"ok": false, "error": "oh_by PERSON [D]: nobody of that name in play"}
	var dist := float(a[1]) if a.size() > 1 else 2.5
	var to := player.global_position - man.global_position
	to.y = 0.0
	to = to.normalized() if to.length() > 0.01 else Vector3.FORWARD
	player.global_position = man.global_position + to * dist
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(to.x, to.z)
	await physics_frames(2)
	return {"d": snappedf(player.global_position.distance_to(man.global_position), 0.01)}


func _physics_process(_delta: float) -> void:
	if not _on or bridge == null or bridge._game_seconds() < _next:
		return
	_next = bridge._game_seconds() + SAMPLE_S
	var vf := _folk()
	if vf == null:
		return
	var men := _men()
	var ids := men.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: HumanBody = men[ids[i]]
			var b: HumanBody = men[ids[j]]
			if a.global_position.distance_to(b.global_position) > PAIR_M:
				continue
			var key := "%s|%s" % [ids[i], ids[j]] if String(ids[i]) < String(ids[j]) else "%s|%s" % [ids[j], ids[i]]
			_pairs[key] = int(_pairs.get(key, 0)) + 1
			var w := "%s + %s" % [_spot_name(vf, ids[i]), _spot_name(vf, ids[j])]
			if not _where.has(key):
				_where[key] = {}
			_where[key][w] = int((_where[key] as Dictionary).get(w, 0)) + 1
	_sample_why(vf, men)


func _sample_why(vf: ValleyFolk, men: Dictionary) -> void:
	var o := vf.overheard
	if o == null:
		return
	var now := vf._ran
	var all := TownScript.exchanges()
	for id: String in all:
		var ex: Dictionary = all[id]
		var c: Dictionary = ex["if"]
		if String(c.get("on", "")) != "heard" or String(ex.place).begins_with("saloon"):
			continue
		if c.has("hour") and not TownBarks.in_hours(vf.hour(), float(c.hour[0]), float(c.hour[1])):
			continue
		if int(o.heard_day.get(id, -1)) == vf.town_day():
			continue
		var near := true
		for who: String in ex.cast:
			var m: HumanBody = men.get(StringName(who))
			near = near and m != null and m.global_position.distance_to(player.global_position) <= 15.0
		if not near:
			continue
		var why := ""
		var fm := {}
		for who: String in ex.cast:
			var pid := StringName(who)
			if o.busy(pid):
				why = "busy:" + who
			elif o.free_man(pid, now) == null:
				why = "not_free:" + who
			elif not o.tags_of(pid).has(String(ex.place)):
				why = "tags:" + who
			if why != "":
				break
			fm[pid] = men[pid]
		if why == "" and not o._together(fm, player.global_position):
			why = "apart"
		if why == "" and not TownBarks.holds(c, vf.bark_ctx(StringName(String(ex.lines[0].who)), fm[StringName(String(ex.lines[0].who))])):
			why = "if"
		if why == "" and now - float(o._left.get(id, -INF)) < float(o.d.unheard_again_s):
			why = "left"
		if why == "":
			why = "could"
		if not _why_not.has(id):
			_why_not[id] = {}
		_why_not[id][why] = int((_why_not[id] as Dictionary).get(why, 0)) + 1
