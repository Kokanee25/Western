class_name LineGesture
extends Node
## A line said with the face and body (#1316, Sean 2026-11-27: "angry gestures, or looks like they're
## laughing during a line"): when he says a line (Events.spoke, Events.overheard) its delivery tag
## (Delivery: the town script's `tag`, else calm) sets his face for the line (FaceLife.set_tone) and
## plays the tag's gestures (config/delivery.json) on top of whatever he's doing, through
## HumanBody.gesture_offsets (added to his pose, his chore's lean, his bit: never written over them):
## a fist that lands on the angry word, a laugh that shakes him and lands after the punchline, a look
## away on the sly word. A busy hand is left to its chore (HumanBody.hand_busy): the gesture goes to
## the other hand, or to his head and body alone; walking, only what his head and face can do. The men
## he's talking to answer from the same tag (a grin at a joke, a wince at an insult, a look at each
## other), a beat after his; a man of steady nerves (Sarge, #1312) answers nothing and is never scared.
##
## The beat: a word marked `*` in the script (Delivery.strip_beat), else the tag's `beat` (the line's
## stress: its strongest nod, FaceSpeech.plan's; its end; its start), timed by his mouth's own plan.
## A recorded gesture (MotionClip: config/delivery.json `recorded`, docs/MOCAP.md "Talking gestures")
## plays instead where one has been recorded and he's stood with his hands free.
##
## HumanBody adds one to every man. Nothing runs between lines: he's a ticker only while a gesture or
## a face is playing (on events, not per frame: the people budget).

## Off for a whole run (the before of the bench and the contact sheet; the goldens hold faces still).
static var enabled := true
const ARMS := [&"upper_arm_r", &"forearm_r", &"hand_r", &"upper_arm_l", &"forearm_l", &"hand_l"]

var body: HumanBody
var _items: Array = []   # {keys: [[t, {seg: deg}]], osc, hand, look, look_at, reach, mirror, k, end}
var _tones: Array = []   # {shapes, a, b, peak, k}
var _t := 0.0
var _on := false
var _rng := RandomNumberGenerator.new()
## The last line he said as played: {tag, beat (s from its start), gestures [names], listeners,
## posture, clip}; tests and the bench read it.
var last := {}
## The last answer he gave to someone else's line: {tag, from, g, at}.
var last_heard := {}


func _ready() -> void:
	set_physics_process(true)  # its switch (PeopleTick ticks it while it's a ticker)
	if body == null and get_parent() is HumanBody:
		body = get_parent()
	Events.spoke.connect(_on_spoke)
	Events.overheard.connect(_on_overheard)


## The gesture node of `man` (null if he has none).
static func of(man: Node) -> LineGesture:
	return man.get_node_or_null(^"LineGesture") as LineGesture if man != null else null


func _on_spoke(speaker: Node, text: String) -> void:
	if speaker == body:
		say(text, {})


func _on_overheard(speaker: Node, text: String, info: Dictionary) -> void:
	if speaker == body:
		say(text, info)


func playing() -> bool:
	return _on


## He says `text` now (`info` as Events.overheard's: tag, delivery, to, r). Returns the beat (s).
func say(text: String, info: Dictionary) -> float:
	if not enabled or not _able():
		return -1.0
	var d := Delivery.of(text)
	var tag: StringName = d.tag
	var strength := float(d.strength)
	if info.has("tag") and StringName(info.tag) != &"calm":
		tag = StringName(info.tag)
	elif tag == &"calm" and String(info.get("delivery", "")) != "":
		var tn := Delivery.tag_of_note(String(info.delivery))
		tag = tn[0]
		strength = float(tn[1])
	if _steady(body) and tag in [&"scared", &"pleading", &"angry"]:
		tag = &"calm"   # nerves of steel: nothing rattles him, not even his own line
	_rng.seed = hash([body.rng_seed, text])
	var plan := _plan_of(text)
	var voice: Array = plan.get("voice", [0.0, 0.0])
	var a := float(voice[0])
	var b := maxf(float(voice[1]), a + 0.2)
	var e := Delivery.entry(tag)
	var beat := _beat(plan, int(d.beat), String(e.get("beat", "stress")), a, b)
	_t = 0.0
	_items.clear()
	_tones.clear()
	var posture := _posture()
	var names: Array[String] = []
	var to: Node3D = info.get("to") as Node3D if info.get("to") is Node3D else null
	var clip := _recorded(tag, beat, posture)
	if clip == &"":
		var pick := _choose(e.get("gestures", []), posture)
		if pick != "":
			names.append(pick)
	for w: String in e.get("with", []):
		if _fits(Delivery.gesture(w), posture):
			names.append(w)
	for n in names:
		_add(n, beat, a, b, strength, to, null)
	var face: Dictionary = e.get("face", {})
	var dd := Delivery.data()
	if not face.is_empty():
		_tones.append({"shapes": face, "a": a - float(dd.get("face_in", 0.25)), "b": b + float(dd.get("face_hold", 0.4)),
				"peak": beat, "k": clampf(strength, 0.3, 1.0), "out": float(dd.get("face_out", 0.5))})
	var heard := _listen(e.get("listen", {}), info, to, beat + float(dd.get("listen_delay", 0.3)), strength, tag)
	last = {"tag": tag, "beat": beat, "gestures": names, "posture": posture, "clip": clip, "listeners": heard,
			"voice": [a, b], "text": text}
	_begin()
	return beat


## He answers a line said by `speaker` (its tag's `listen` entry for him: `spec` {face, g}) at `at`
## seconds from now; `mates` the others listening (whom he may look to).
func hear(spec: Dictionary, speaker: Node3D, at: float, strength: float, mates: Array, tag: StringName) -> void:
	if not enabled or not _able() or spec.is_empty():
		return
	_t = 0.0 if not _on else _t
	var g := String(spec.get("g", ""))
	var mate: Node3D = null
	for m: Variant in mates:
		if m != body and is_instance_valid(m):
			mate = m
			break
	if g != "" and _fits(Delivery.gesture(g), _posture()):
		_add(g, _t + at, _t + at, _t + at + 1.2, strength, speaker, mate)
	var face: Dictionary = spec.get("face", {})
	if not face.is_empty():
		_tones.append({"shapes": face, "a": _t + at - 0.1, "b": _t + at + 1.4, "peak": _t + at + 0.2,
				"k": clampf(strength, 0.3, 1.0), "out": 0.5})
	last_heard = {"tag": tag, "from": speaker, "g": g, "at": at}
	_begin()


func tick(delta: float) -> void:
	if not _on:
		return
	var pt := Prof.start()
	_step(delta)
	Prof.stop(&"faces", pt)   # (People: the faces' timer)


func _step(delta: float) -> void:
	_t += delta
	if not _able():
		_stop()
		return
	var offs := {}
	var alive := false
	for it: Dictionary in _items:
		if _t > float(it.end):
			continue
		alive = true
		var w := _eval(it, _t)
		var busy_r := body.hand_busy("r") if not it.has("reach") else false
		var busy_l := body.hand_busy("l") if not it.has("reach") else false
		for seg: StringName in w:
			if seg in ARMS and ((String(seg).ends_with("_r") and busy_r) or (String(seg).ends_with("_l") and busy_l)):
				continue   # that hand is about his chore: the gesture leaves it be
			offs[seg] = (offs.get(seg, Vector3.ZERO) as Vector3) + (w[seg] as Vector3)
		if it.has("reach"):
			_reach_step(it, _t)
		if it.get("look", "") != "" and _t >= float(it.t0) and _t <= float(it.t1):
			_look(it)
	body.gesture_offsets = offs
	var shapes := {}
	for f: Dictionary in _tones:
		var k := _tone_k(f, _t)
		if k <= 0.0:
			continue
		alive = alive or _t < float(f.b) + float(f.out)
		for n: Variant in f.shapes:
			shapes[n] = maxf(float(shapes.get(n, 0.0)), float(f.shapes[n]) * k * float(f.k))
		alive = true
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	if life != null and not shapes.is_empty():
		life.set_tone(shapes)
	if not alive:
		_stop()


# --- the line's timing ------------------------------------------------------------------------------

func _plan_of(text: String) -> Dictionary:
	var sp := body.get_node_or_null(^"FaceSpeech") as FaceSpeech
	if sp != null and sp.line() == text and not sp.current_plan().is_empty():
		return sp.current_plan()
	return FaceSpeech.plan(text)


## When the gesture lands (s from the line's start): the marked word, else by `kind`.
static func _beat(plan: Dictionary, word: int, kind: String, a: float, b: float) -> float:
	var words: Array = plan.get("words", [])
	var dd := Delivery.data()
	if word >= 0 and word < words.size():
		return float(words[word]) + float(dd.get("beat_after_word", 0.06))
	match kind:
		"end":
			return b + float(dd.get("end_after", 0.15))
		"start":
			return a + 0.1
	# The line's stress: its strongest nod (a shout's are bigger), the last of equals.
	var best := -1.0
	var at := lerpf(a, b, 0.6)
	for n: Array in plan.get("nods", []):
		if float(n[1]) >= best:
			best = float(n[1])
			at = float(n[0])
	return at + float(dd.get("beat_after_word", 0.06))


# --- what he does -----------------------------------------------------------------------------------

func _posture() -> StringName:
	if body.gait != &"" and body.move_speed > 0.2:
		return &"walk"
	if String(body.pose).begins_with("sit"):
		return &"sit"
	return &"stand"


func _fits(g: Dictionary, posture: StringName) -> bool:
	if g.is_empty():
		return false
	if posture == &"walk" and not bool(g.get("walk", false)):
		return false
	if g.has("reach") and posture != &"sit":
		return false
	return true


## One of the tag's gestures that fits how he is (its `when`), by his seed among those that do; a
## gesture needing his hands only where one is free.
func _choose(opts: Array, posture: StringName) -> String:
	var fit: Array[String] = []
	for o: Dictionary in opts:
		var n := String(o.get("g", ""))
		var g := Delivery.gesture(n)
		if not (o.get("when", ["stand", "sit"]) as Array).has(String(posture)) or not _fits(g, posture):
			continue
		var hand := String(g.get("hand", ""))
		if hand != "" and body.hand_busy("r") and body.hand_busy("l"):
			continue
		if g.has("reach") and body.hand_busy("r") and body.hand_busy("l"):
			continue
		fit.append(n)
	if fit.is_empty():
		return ""
	return fit[_rng.randi() % fit.size()]


func _add(n: String, beat: float, a: float, b: float, k: float, look_at: Node3D, mate: Node3D) -> void:
	var g := Delivery.gesture(n)
	if g.is_empty():
		return
	var line := String(g.get("span", "")) == "line"
	var span := maxf(b - a, 0.2)
	var keys := []
	var mirror := false
	var hand := String(g.get("hand", ""))
	if hand == "r" and body.hand_busy("r") and not body.hand_busy("l"):
		mirror = true   # his right's busy: the other hand does it
	for kk: Array in g.get("keys", []):
		var t := float(kk[0])
		var at := (a + t * span if t <= 1.0 else b + (t - 1.0)) if line else beat + t
		var segs := {}
		for s: String in (kk[1] as Dictionary):
			var v: Array = kk[1][s]
			var vec := Vector3(float(v[0]), float(v[1]), float(v[2])) * k
			var seg := StringName(s)
			if mirror:
				seg = _mirrored(seg)
				vec = Vector3(vec.x, -vec.y, -vec.z)
			segs[seg] = vec
		keys.append([at, segs])
	var it := {"name": n, "keys": keys, "k": k, "t0": INF, "t1": -INF, "end": -INF, "look": String(g.get("look", "")),
			"look_at": look_at, "mate": mate}
	if not keys.is_empty():
		it.t0 = float(keys[0][0])
		it.t1 = float(keys[-1][0])
		it.end = it.t1
	if g.has("osc"):
		var o: Dictionary = g.osc
		var ol := String(o.get("span", "")) == "line"
		var f := float(o.get("from", 0.0))
		var to := float(o.get("to", 1.0))
		var osegs := {}
		for s: String in (o.get("segs", {}) as Dictionary):
			var v: Array = o.segs[s]
			var vec := Vector3(float(v[0]), float(v[1]), float(v[2])) * k
			osegs[_mirrored(StringName(s)) if mirror else StringName(s)] = Vector3(vec.x, -vec.y, -vec.z) if mirror else vec
		it["osc"] = {"hz": float(o.get("hz", 2.0)), "segs": osegs,
				"from": (a + f * span) if ol else beat + f, "to": (a + to * span if to <= 1.0 else b + to - 1.0) if ol else beat + to}
		it.t0 = minf(float(it.t0), float(it.osc.from))
		it.end = maxf(float(it.end), float(it.osc.to))
	if g.has("reach"):
		var side := "l" if (mirror or body.hand_busy("r")) else "r"
		it["reach"] = {"side": side, "to": String(g.reach), "lift": float(g.get("lift", 0.15)), "beat": beat,
				"from": beat - 0.45, "to_t": beat + 0.6}
		it.t0 = minf(float(it.t0), beat - 0.45)
		it.end = maxf(float(it.end), beat + 0.9)
	_items.append(it)


static func _mirrored(seg: StringName) -> StringName:
	var s := String(seg)
	if s.ends_with("_r"):
		return StringName(s.left(-2) + "_l")
	if s.ends_with("_l"):
		return StringName(s.left(-2) + "_r")
	return seg


## A gesture's offsets at `t`: its keys eased between, its shake on top.
static func _eval(it: Dictionary, t: float) -> Dictionary:
	var out := {}
	var keys: Array = it.keys
	if keys.size() >= 2 and t >= float(keys[0][0]) and t <= float(keys[-1][0]):
		var i := 0
		while i < keys.size() - 2 and t > float(keys[i + 1][0]):
			i += 1
		var t0 := float(keys[i][0])
		var t1 := float(keys[i + 1][0])
		var u := smoothstep(0.0, 1.0, (t - t0) / maxf(t1 - t0, 0.001))
		var p: Dictionary = keys[i][1]
		var q: Dictionary = keys[i + 1][1]
		for s: Variant in p:
			out[s] = (p[s] as Vector3).lerp(q.get(s, Vector3.ZERO), u)
		for s: Variant in q:
			if not p.has(s):
				out[s] = Vector3.ZERO.lerp(q[s], u)
	if it.has("osc"):
		var o: Dictionary = it.osc
		var f := float(o.from)
		var to := float(o.to)
		if t >= f and t <= to:
			var env := clampf((t - f) / 0.15, 0.0, 1.0) * clampf((to - t) / 0.15, 0.0, 1.0)
			var s := sin(TAU * float(o.hz) * (t - f)) * env
			for seg: Variant in o.segs:
				out[seg] = (out.get(seg, Vector3.ZERO) as Vector3) + (o.segs[seg] as Vector3) * s
	return out


## A hand to his knee (a slap as he laughs): it comes in from above and lands on the beat.
func _reach_step(it: Dictionary, t: float) -> void:
	var r: Dictionary = it.reach
	if t < float(r.from) or t > float(r.to_t) + 0.3:
		return
	var side := String(r.side)
	var thigh := body.parts.get(StringName("thigh_" + side)) as Node3D
	var shin := body.parts.get(StringName("shin_" + side)) as Node3D
	if thigh == null or shin == null:
		return
	var knee := thigh.global_position.lerp(shin.global_position, 0.55) + Vector3.UP * 0.06
	var beat := float(r.beat)
	var k := clampf((t - float(r.from)) / maxf(beat - float(r.from), 0.01), 0.0, 1.0)
	if t > float(r.to_t):
		k = clampf(1.0 - (t - float(r.to_t)) / 0.3, 0.0, 1.0)
	var lift := float(r.lift) * clampf((beat - t) / 0.2, 0.0, 1.0)
	body.reach_to(side, knee + Vector3.UP * lift, Vector3.UP, smoothstep(0.0, 1.0, k))


func _look(it: Dictionary) -> void:
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	if life == null or not body.parts.has(&"head"):
		return
	var head := (body.parts[&"head"] as Node3D).global_position
	var bs := body.global_transform.basis
	match String(it.look):
		"away":
			life.attend_to(head + bs * Vector3(-0.55, -0.35, -1.0).normalized() * 3.0)
		"down":
			life.attend_to(head + bs * Vector3(0.0, -1.1, -1.0).normalized() * 2.0)
		"listener", "speaker":
			_look_at_man(life, it.get("look_at"))
		"each_other":
			_look_at_man(life, it.get("mate") if is_instance_valid(it.get("mate")) else it.get("look_at"))


static func _look_at_man(life: FaceLife, man: Variant) -> void:
	if man == null or not is_instance_valid(man) or not (man is Node3D):
		return
	var n := man as Node3D
	if n is HumanBody and (n as HumanBody).parts.has(&"head"):
		life.attend_to(((n as HumanBody).parts[&"head"] as Node3D).global_position)
	elif n is Player:
		life.attend_to((n as Player).camera.global_position)
	else:
		life.attend_to(n.global_position + Vector3.UP * 1.55)


static func _tone_k(f: Dictionary, t: float) -> float:
	var a := float(f.a)
	var b := float(f.b)
	if t < a or t > b + float(f.out):
		return 0.0
	var k := clampf((t - a) / 0.25, 0.0, 1.0) * (1.0 if t <= b else clampf(1.0 - (t - b) / maxf(float(f.out), 0.01), 0.0, 1.0))
	var peak := 1.0 - clampf(absf(t - float(f.peak)) / 0.5, 0.0, 1.0)
	return k * (0.75 + 0.25 * peak)


# --- the slot for recorded gestures ----------------------------------------------------------------

## A recorded gesture for `tag` (MotionClip) where one exists and he's stood with both hands free and
## no clip on: played so its `beat` mark lands on the beat. Its name, or &"" (the procedural one plays).
func _recorded(tag: StringName, beat: float, posture: StringName) -> StringName:
	if posture != &"stand" or body.hand_busy("r") or body.hand_busy("l") or body.clip_playing():
		return &""
	var names: Array = (Delivery.data().get("recorded", {}) as Dictionary).get(String(tag), [])
	var have: Array[MotionClip] = []
	for n: String in names:
		var c := MotionClip.load_clip(StringName(n))
		if c != null:
			have.append(c)
	if have.is_empty():
		return &""
	var c := have[_rng.randi() % have.size()]
	var mark := float(c.events.get("beat", c.length() * 0.5))
	var wait := maxf(beat - mark, 0.0)
	if wait <= 0.0:
		body.play_clip(c.name, 1.0, false, {"travel": false})
	else:
		get_tree().create_timer(wait, false, true).timeout.connect(func() -> void:
			if is_instance_valid(body) and _able() and not body.clip_playing():
				body.play_clip(c.name, 1.0, false, {"travel": false}))
	return c.name


# --- the men listening ------------------------------------------------------------------------------

## The men he's talking to answer: `to` (the man spoken to) by the tag's `to`, the others near him by
## its `others`. The cast of an exchange (Overheard's `r.men`) if it has one, else the men within
## listen_m of him (the nearest listen_max). Returns them.
func _listen(spec: Dictionary, info: Dictionary, to: Node3D, at: float, k: float, tag: StringName) -> Array:
	if spec.is_empty():
		return []
	var dd := Delivery.data()
	var near_m := float(dd.get("listen_m", 4.0))
	var cands: Array = []
	var r: Variant = info.get("r")
	if r is Dictionary and (r as Dictionary).get("men") is Dictionary:
		for pid: Variant in (r as Dictionary).men:
			cands.append((r as Dictionary).men[pid])
	else:
		for n: Node in body.get_tree().get_nodes_in_group(&"people"):
			if n is HumanBody and n != body and (n as HumanBody).global_position.distance_to(body.global_position) <= near_m:
				cands.append(n)
		cands.sort_custom(func(x: Node3D, y: Node3D) -> bool:
			return x.global_position.distance_to(body.global_position) < y.global_position.distance_to(body.global_position))
	var men: Array = []
	for c: Variant in cands:
		if c == body or not is_instance_valid(c) or not (c is HumanBody) or men.size() >= int(dd.get("listen_max", 3)):
			continue
		var m := c as HumanBody
		if not m.is_inside_tree() or m.limp or not m.physiology.is_conscious() or _steady(m) or not _calm(m) \
				or m.global_position.distance_to(body.global_position) > near_m * 1.5:
			continue
		men.append(m)
	for m: HumanBody in men:
		var lg := LineGesture.of(m)
		if lg == null:
			continue
		var role := "to" if m == to else "others"
		lg.hear(spec.get(role, spec.get("others", {})), body, at, k, men, tag)
	return men


static func _steady(m: HumanBody) -> bool:
	var br := m.get_node_or_null(^"Brain")
	return br != null and br.has_method(&"steady") and bool(br.call(&"steady"))


static func _calm(m: HumanBody) -> bool:
	var br := m.get_node_or_null(^"Brain")
	if br is CivilianBrain:
		return (br as CivilianBrain).mood == CivilianBrain.Mood.CALM
	if br is OutlawBrain:
		return (br as OutlawBrain).mood != OutlawBrain.Mood.FIGHTING and (br as OutlawBrain).mood != OutlawBrain.Mood.RELOADING
	return true


# --- on and off -------------------------------------------------------------------------------------

func _able() -> bool:
	return body != null and is_instance_valid(body) and body.is_inside_tree() and not body.limp \
			and body.physiology.alive and body.physiology.is_conscious()


func _begin() -> void:
	if _items.is_empty() and _tones.is_empty():
		return
	if not _on:
		_on = true
		body.add_ticker(self)
	# (No wake(): a line plays on his own tick at his band's rate. Waking him ticked a far man every
	# frame and changed his walk's steps: #1334's CI saw the loudmouth step off the store's dock.)


func _stop() -> void:
	_on = false
	_items.clear()
	_tones.clear()
	if body != null and is_instance_valid(body):
		body.gesture_offsets = {}
		body.remove_ticker(self)


func _exit_tree() -> void:
	if _on:
		_stop()
