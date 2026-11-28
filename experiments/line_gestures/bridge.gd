extends BridgeLab
## The line gestures bench (#1316): what a man saying a line does with his face and body, and what the
## men by him do, in the running valley. `lg_on 0|1` turns LineGesture off (the before) or on; `lg_start`
## begins a watch of every line said (Events.spoke, Events.overheard); `lg_stop` answers, a line each:
## who, the words, its tag, how far from you, and for him and for each man within 4 m the most his face's
## shapes moved off where they were as it began (FaceLife.expression) and his arms, body and head turned
## (degrees, joints off where they were), over the line and a second after. run.py makes the table.

const HELP := {
	"lg_on": "lg_on 0|1 -> LineGesture off (the before) or on",
	"lg_start": "lg_start -> begins a watch of every line said",
	"lg_stop": "lg_stop -> ends it: {lines: [{who, text, tag, d, gestures, speaker: {face, arms, body, head}, listeners: [...]}]}",
}
const NEAR_M := 4.0
const GROUPS := {"arms": [&"upper_arm_r", &"forearm_r", &"upper_arm_l", &"forearm_l"], "body": [&"chest", &"abdomen"],
		"head": [&"head", &"neck"]}

var _on := false
var _hooked := false
var _lines: Array = []
var _watch: Array = []
var _prof0 := {}
var _t0 := 0.0
var _frames0 := 0   # {rec, men: [[man, role, base_pose, base_face, max]], until}


func _cmd_lg_on(a: Array) -> Dictionary:
	LineGesture.enabled = a.size() == 0 or String(a[0]) != "0"
	return {"on": LineGesture.enabled}


func _cmd_lg_start(_a: Array) -> Dictionary:
	if not _hooked:
		_hooked = true
		Events.spoke.connect(func(who: Node, text: String) -> void: _note(who, text, {}))
		Events.overheard.connect(func(who: Node, text: String, info: Dictionary) -> void: _note(who, text, info))
	_on = true
	_lines = []
	_watch = []
	Prof.on = true
	_prof0 = Prof._sum.duplicate()
	_t0 = bridge._game_seconds()
	_frames0 = Engine.get_physics_frames()
	return {"on": LineGesture.enabled}


func _cmd_lg_stop(_a: Array) -> Dictionary:
	_on = false
	for w: Dictionary in _watch:
		_close(w)
	_watch = []
	# The people's cost over the watch, ms a physics tick (Prof's sums, People's timers).
	var ticks := maxi(Engine.get_physics_frames() - _frames0, 1)
	var cost := {}
	for k: StringName in [&"faces", &"people_body", &"brains", &"senses", &"town_life", &"valley_folk"]:
		cost[String(k)] = snappedf((int(Prof._sum.get(k, 0)) - int(_prof0.get(k, 0))) / 1000.0 / ticks, 0.001)
	return {"lines": _lines, "ms_a_tick": cost, "ticks": ticks, "s": snappedf(bridge._game_seconds() - _t0, 0.1)}


func _note(who: Node, text: String, info: Dictionary) -> void:
	if not _on or not (who is HumanBody) or player == null:
		return
	var man := who as HumanBody
	var d := Delivery.of(text)
	var tag: StringName = info.get("tag", d.tag) if info.has("tag") else d.tag
	var rec := {"who": String(man.person_id), "text": text, "tag": String(tag), "exchange": info.has("exchange"),
			"d": snappedf(man.global_position.distance_to(player.global_position), 0.1), "gestures": []}
	var men := [[man, "speaker"]]
	for n: Node in get_tree().get_nodes_in_group(&"people"):
		if n is HumanBody and n != man and (n as HumanBody).global_position.distance_to(man.global_position) <= NEAR_M:
			men.append([n, "listener"])
	var w := {"rec": rec, "men": [], "until": bridge._game_seconds() + FaceSpeech.subtitle_seconds(text) + 1.0}
	for m: Array in men:
		var h := m[0] as HumanBody
		(w.men as Array).append([h, m[1], _pose(h), _face(h), {"face": 0.0, "arms": 0.0, "body": 0.0, "head": 0.0, "shape": ""}])
	_watch.append(w)


func _pose(h: HumanBody) -> Dictionary:
	var out := {}
	for g: String in GROUPS:
		for s: StringName in GROUPS[g]:
			var pv := h.pivots.get(s) as Node3D
			if pv != null:
				out[s] = pv.quaternion
	return out


func _face(h: HumanBody) -> Dictionary:
	var life := h.get_node_or_null(^"FaceLife") as FaceLife
	return life.expression() if life != null else {}


func _physics_process(_delta: float) -> void:
	if _watch.is_empty() or bridge == null:
		return
	var now: float = bridge._game_seconds()
	var done := []
	for w: Dictionary in _watch:
		for m: Array in w.men:
			var h := m[0] as HumanBody
			if not is_instance_valid(h) or not h.is_inside_tree():
				continue
			var mx: Dictionary = m[4]
			var base: Dictionary = m[2]
			for g: String in GROUPS:
				for s: StringName in GROUPS[g]:
					var pv := h.pivots.get(s) as Node3D
					if pv != null and base.has(s):
						mx[g] = maxf(float(mx[g]), rad_to_deg((base[s] as Quaternion).angle_to(pv.quaternion)))
			var f := _face(h)
			var bf: Dictionary = m[3]
			for k: Variant in f:
				var dv := float(f[k]) - float(bf.get(k, 0.0))
				if dv > float(mx.face):
					mx.face = dv
					mx.shape = String(k)
		if now >= float(w.until):
			done.append(w)
	for w: Dictionary in done:
		_close(w)
		_watch.erase(w)


func _close(w: Dictionary) -> void:
	var rec: Dictionary = w.rec
	var ls := []
	for m: Array in w.men:
		var mx: Dictionary = m[4]
		var row := {"who": String((m[0] as HumanBody).person_id) if is_instance_valid(m[0]) else "?",
				"face": snappedf(float(mx.face), 0.01), "shape": mx.shape, "arms": snappedf(float(mx.arms), 0.1),
				"body": snappedf(float(mx.body), 0.1), "head": snappedf(float(mx.head), 0.1)}
		if m[1] == "speaker":
			rec["speaker"] = row
			var lg := LineGesture.of(m[0]) if is_instance_valid(m[0]) else null
			if lg != null and String(lg.last.get("text", "")) == String(rec.text):
				rec["gestures"] = lg.last.get("gestures", [])
		else:
			var lg2 := LineGesture.of(m[0]) if is_instance_valid(m[0]) else null
			row["answered"] = lg2 != null and lg2.last_heard.get("from") == w.men[0][0]
			ls.append(row)
	rec["listeners"] = ls
	_lines.append(rec)
