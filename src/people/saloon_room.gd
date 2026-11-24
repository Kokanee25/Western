class_name SaloonRoom
extends RefCounted
## The saloon at night as a room (townsfolk step 10, #1157; docs/briefs/townsfolk.md §6; data
## `room` of config/valley_folk.json, its _doc the dials). ValleyFolk owns one, on the set's lot.
##
## - **The mood**: one number, 0 hushed to 1 roaring, from what's really there (who's in, their
##   drink, the band sounding, the night, the town's regard of Harlan while he's in the room, how
##   many of them are calm, the time since trouble); `mood_name()` calm / lively / tense / hushed.
## - **The director** (once a second; Sean's event director, #276): hands out the bits, each to a
##   man who's there, calm, at his chore and may speak (a scene's hush is kept): `CivilianBrain.
##   start_bit`, so his own head, mouth and hands do it. Never from the air: every sound a bit
##   makes is placed at its man and logged with him (`sounds`).
## - **The hush**: trouble in the room (a gun out, a blow, a shot) and the mood falls as each man
##   takes it in. A man who sensed it himself is Reaction's (townsfolk step 5); one who didn't looks
##   round a moment later, by his distance (`CivilianBrain.show_look`); the piano player ducks
##   (`ducks`). Laughter stops mid-laugh (a bit is cut the tick its man isn't calm at his chore).
##   `hush_log`: each man's seconds from the trouble to his turn, for the brief's measure.
## - **You coming in**: the town warm, a man hails you; cold, the talk drops and a few look round.
##
## Ideas from: Sean's plan #276 (the event director: conditions, frequency, cooldowns); the brief.

var folk: ValleyFolk
var d: Dictionary = {}
var rng := RandomNumberGenerator.new()

## The mood now, what it would be with everyone calm (`target`), and its parts (for `report`).
var mood := 0.0
var target := 0.0
var parts := {}
## Who's in: [id] (set each look).
var ins: Array[StringName] = []
var you_in := false

## Seconds since trouble (INF: none), where, who.
var since_trouble := INF
var trouble_at := Vector3.INF
var trouble_who: Node3D
var _trouble_frame := -1
var _live := false
## One trouble's turns: [{id, d, s, how}] (how: own = his Reaction's, look, duck); cleared at the next.
var hush_log: Array = []
var _logged := {}

## Every bit handed out: {t, bit, by, at, seen, others, say, cut} (the bit's own dictionary, so
## `cut` and `t` are as his brain left them).
var log: Array = []
## Every sound a bit made: {t, sound, by, at, seen, bit}.
var sounds: Array = []
## What's to come at a frame: [{frame, id, what, bit | at, who}].
var _pending: Array = []
var _acc := 0.0
var _clock := 0.0
var _next_bit := 6.0
var _last := {}  # "bit:pid" -> when
var _was_state := {}
var _you_was := false
var _enter_tries := 0
var _entered_at := -INF
var _drop_at := -INF
var _by_bar := 0.0
var _glass_day := -1
var glass: MeshInstance3D
## The room's box on the ground: its corner and two sides (world).
var _o := Vector3.ZERO
var _ax := Vector3.RIGHT
var _bx := Vector3.BACK
var _built := false
## A second box (#1213): saloon B's bar room, where the barkeep serves by day (data `hall_rect`
## {hall, rect [x0, z0, x1, z1] in its space}); its corner and sides, or none.
var _ho := Vector3.INF
var _hax := Vector3.ZERO
var _hbx := Vector3.ZERO


func _init(f: ValleyFolk = null, data: Dictionary = {}) -> void:
	folk = f
	d = data
	rng.seed = 1157
	if not d.is_empty():
		Events.deed.connect(_on_deed)
		Events.shot_fired.connect(_on_shot)


func _n(k: String, dflt: float) -> float:
	return float(d.get(k, dflt))


func _build() -> void:
	_built = true
	var r: Array = d.get("rect", [0.0, 0.0, 10.0, 12.0])
	var lot := String((folk.data.get("set", {}) as Dictionary).get("lot", ""))
	_o = folk.lot_point(lot, float(r[0]), float(r[1]))
	_ax = folk.lot_point(lot, float(r[2]), float(r[1])) - _o
	_bx = folk.lot_point(lot, float(r[0]), float(r[3])) - _o
	var hr: Dictionary = d.get("hall_rect", {})
	if not hr.is_empty() and folk.halls.has(String(hr.get("hall", ""))):
		var h := String(hr.hall)
		var q: Array = hr.rect
		var y := float(hr.get("y", 0.95))
		_ho = folk.hall_point(h, [q[0], y, q[1]])
		_hax = folk.hall_point(h, [q[2], y, q[1]]) - _ho
		_hbx = folk.hall_point(h, [q[0], y, q[3]]) - _ho
	if bool((d.get("sounds", {}) as Dictionary).get("on", true)) and GameAudio.enabled():
		SynthSounds.warm([&"laugh_0", &"laugh_1", &"laugh_2", &"cough", &"glass_down"])


## Is `at` in the room (`margin` m round it)?
func inside(at: Vector3, margin := 0.0) -> bool:
	if not _built:
		return false
	return _in_box(at, _o, _ax, _bx, margin) or (_ho != Vector3.INF and _in_box(at, _ho, _hax, _hbx, margin))


static func _in_box(at: Vector3, o: Vector3, ax: Vector3, bx: Vector3, margin: float) -> bool:
	var v := at - o
	var a := v.dot(ax.normalized())
	var b := v.dot(bx.normalized())
	return a >= -margin and a <= ax.length() + margin and b >= -margin and b <= bx.length() + margin \
			and absf(v.y) < 4.0


func centre() -> Vector3:
	return _o + (_ax + _bx) * 0.5


func open() -> bool:
	var h: Array = d.get("hours", [17.0, 3.0])
	return ValleyFolk.in_hours(folk.hour(), h)


## The room's building shows a lit window (BookLights): open, after dark, someone in.
func lit() -> bool:
	var dark: Array = (folk.data.get("book", {}) as Dictionary).get("dark", [18.0, 6.0])
	if not d.has("lights") or not open() or not ValleyFolk.in_hours(folk.hour(), dark):
		return false
	if not _built:
		_build()
	# (Asked as the clock jumps: who's there now, not who was at the last look.)
	for id: StringName in folk.people:
		var man: HumanBody = folk.people[id]
		if is_instance_valid(man) and man.is_inside_tree() and not folk._person(id).has("act") and man.physiology.alive \
				and inside(man.global_position):
			return true
	return false


func _brain(id: StringName) -> CivilianBrain:
	var man := folk.folk_man(id)
	return man.get_node_or_null(^"Brain") as CivilianBrain if man != null else null


func _player() -> Node3D:
	return folk.get_tree().get_first_node_in_group(&"player") as Node3D if folk.is_inside_tree() else null


## His block's doing now (drink, talk, play...).
func doing_of(id: StringName) -> String:
	var p := folk._person(id)
	return String(folk.block_now(p, folk.hour()).get("do", "")) if p.has("day") else ""


static func is_calm(b: CivilianBrain) -> bool:
	return b != null and b.mood == CivilianBrain.Mood.CALM and not b.held and not b.reaction.active() \
			and not (b.showing.get("what", &"") == &"look") and b.body.physiology.is_conscious() and not b.body.limp


## May he be given a bit: calm, at his chore (or sat), free to speak, nothing else on him.
func can_do(id: StringName) -> bool:
	var b := _brain(id)
	if not is_calm(b) or not b.may_speak() or not b.bit.is_empty() or not b.showing.is_empty() or b.returning:
		return false
	if folk._person(id).has("plays"):
		return false  # the band's hands are their instruments'
	return b.chore != null and bool(b.chore.call(&"busy"))


# --- The clock ---------------------------------------------------------------------------------------

## Every frame from ValleyFolk; acts once `every_s`.
func step(delta: float) -> void:
	if d.is_empty() or folk == null:
		return
	_clock += delta
	since_trouble += delta
	_acc += delta
	if _acc < _n("every_s", 1.0):
		return
	var dt := _acc
	_acc = 0.0
	if not _built:
		_build()
	_look_round()
	_set_mood()
	if not open() or ins.is_empty():
		_clear_glass()
		return
	var p := _player()
	if p == null or p.global_position.distance_to(centre()) > _n("live_m", 80.0):
		return
	_events(p, dt)
	_next_bit -= dt
	if _next_bit <= 0.0:
		_next_bit = gap(mood)
		if mood >= _n("none_under", 0.05) and since_trouble > _n("hold_s", 10.0):
			_hand_out()


## Every physics tick from ValleyFolk: only what's due (a late laugh, a look, the turns' log).
func tick() -> void:
	if _pending.is_empty() and not _live:
		return
	var now := Engine.get_physics_frames()
	var i := 0
	while i < _pending.size():
		var e: Dictionary = _pending[i]
		if int(e.frame) > now:
			i += 1
			continue
		_pending.remove_at(i)
		_due(e)
	if _live:
		_log_turns(now)
		_set_mood()
		if now - _trouble_frame > int(float((d.get("trouble", {}) as Dictionary).get("live_s", 3.0)) * Engine.physics_ticks_per_second):
			_live = false


func _after(seconds: float) -> int:
	return Engine.get_physics_frames() + maxi(1, roundi(seconds * Engine.physics_ticks_per_second))


## Who's in the room now, and who came or went since the last look.
func _look_round() -> void:
	ins.clear()
	for p: Dictionary in folk.data.people:
		if p.has("act") or not p.has("day"):
			continue
		var id := StringName(p.id)
		var st: StringName = folk.state.get(id, &"out")
		var man := folk.folk_man(id)
		var here := man != null and st in [&"in", &"coming", &"going"] and man.physiology.alive and inside(man.global_position)
		var was: StringName = _was_state.get(id, &"out")
		if here and st == &"in":
			ins.append(id)
			if was == &"coming":
				_came_in(id)
		elif here and st == &"going" and was == &"in":
			_goes(id)
		_was_state[id] = st if here else &"out"
		# In the room his talk's own laugh is the director's to give (a laugh has a sound and a source).
		if here and man != null:
			var c := SpotChore._chore_of(man)
			if c != null:
				c.directed = true
	var pl := _player()
	you_in = pl != null and inside(pl.global_position)


# --- The mood -----------------------------------------------------------------------------------------

## The night's entry (`nights`, the first the story holds), or {}.
func night() -> Dictionary:
	for e: Dictionary in d.get("nights", []):
		if ValleyFolk.story_holds(e.get("if", {})):
			return e
	return {}


## How much he's drunk tonight, 0-1: the hours since his block at a drinking spot began.
func drink_of(id: StringName) -> float:
	var p := folk._person(id)
	if not p.has("day"):
		return 0.0
	var b := folk.block_now(p, folk.hour())
	if not String(b.get("do", "")) in (d.get("drinks", ["drink", "play", "talk"]) as Array):
		return 0.0
	return clampf(ValleyFolk.since(folk.hour(), float(b.get("from", folk.hour()))) * _n("drink_per_h", 0.3), 0.0, 1.0)


func _set_mood() -> void:
	var n := ins.size()
	if n == 0 or not open():
		mood = 0.0
		target = 0.0
		parts = {}
		return
	var drink := 0.0
	var calm := 0
	for id: StringName in ins:
		drink += drink_of(id)
		if is_calm(_brain(id)):
			calm += 1
	drink /= n
	var music := folk.band != null and folk.band.state == &"playing"
	var ni := night()
	var kind := String(folk.day_kind(folk.town_day()))
	var add := float(ni.get("add", (d.get("kinds", {}) as Dictionary).get(kind, 0.0)))
	var band := String(folk.regard.town_band()) if folk.regard != null and you_in else ""
	var reg := float((d.get("regard", {}) as Dictionary).get(band, 0.0))
	parts = {"people": snappedf(_n("people", 0.35) * minf(float(n) / _n("full", 12.0), 1.0), 0.01),
			"drink": snappedf(_n("drink", 0.25) * drink, 0.01), "music": _n("music", 0.15) if music else 0.0,
			"night": add, "night_id": String(ni.get("id", kind)), "regard": reg, "band": band}
	target = clampf(float(parts.people) + float(parts.drink) + float(parts.music) + add + reg, 0.0, 1.0)
	var calm_frac := float(calm) / n
	var back := smoothstep(_n("hold_s", 10.0), _n("hold_s", 10.0) + _n("recover_s", 150.0), since_trouble)
	var drop: Dictionary = d.get("drop", {})
	var dropped := lerpf(float(drop.get("to", 0.35)), 1.0, clampf((_clock - _drop_at) / float(drop.get("s", 45.0)), 0.0, 1.0))
	parts["calm"] = snappedf(calm_frac, 0.01)
	parts["back"] = snappedf(back, 0.01)
	parts["drop"] = snappedf(dropped, 0.01)
	mood = target * minf(calm_frac, back) * dropped


func mood_name() -> StringName:
	if mood < _n("hushed_under", 0.08):
		return &"hushed"
	var cold := you_in and String(parts.get("band", "")) in ["cold", "afraid"]
	if mood < _n("calm_at", 0.4) and (float(parts.get("back", 1.0)) < 1.0 or cold):
		return &"tense"
	return &"lively" if mood >= _n("lively_at", 0.55) else &"calm"


## Seconds to the next bit at mood `m`: between the `gap` rows ([mood, least, most]).
func gap(m: float) -> float:
	var rows: Array = d.get("gap", [[0.3, 40.0, 60.0], [0.7, 8.0, 20.0]])
	var r := gap_range(rows, m)
	return rng.randf_range(r.x, r.y)


static func gap_range(rows: Array, m: float) -> Vector2:
	var lo: Array = rows[0]
	for r: Array in rows:
		if float(r[0]) <= m:
			lo = r
	var hi: Array = lo
	for i in range(rows.size() - 1, -1, -1):
		if float(rows[i][0]) >= m:
			hi = rows[i]
	if hi == lo or is_equal_approx(float(hi[0]), float(lo[0])):
		return Vector2(float(lo[1]), float(lo[2]))
	var k := (m - float(lo[0])) / (float(hi[0]) - float(lo[0]))
	return Vector2(lerpf(float(lo[1]), float(hi[1]), k), lerpf(float(lo[2]), float(hi[2]), k))


# --- The director -------------------------------------------------------------------------------------

## Does the bit's `from` fit him (his block's doing, or `seated`)?
func _fits(id: StringName, from: Array) -> bool:
	var b := _brain(id)
	if b != null and b._seated():
		return from.has("seated") or from.has(doing_of(id))
	return from.has(doing_of(id))


func _may_again(bit: String, id: StringName) -> bool:
	return _clock - float(_last.get("%s:%s" % [bit, id], -INF)) >= _n("again_s", 300.0)


## One bit, to one man: by weight among the bits someone here can do now.
func _hand_out() -> void:
	var bits: Dictionary = d.get("bits", {})
	var can := {}
	var total := 0.0
	for k: String in bits:
		var b: Dictionary = bits[k]
		if mood < float(b.get("min_mood", 0.0)):
			continue
		var who: Array[StringName] = []
		for id: StringName in ins:
			if can_do(id) and _fits(id, b.get("from", [])) and _may_again(k, id):
				who.append(id)
		if not who.is_empty():
			can[k] = who
			total += float(b.get("weight", 1.0))
	if can.is_empty():
		return
	var x := rng.randf() * total
	for k: String in can:
		x -= float(bits[k].get("weight", 1.0))
		if x <= 0.0:
			var who: Array = can[k]
			start(k, who[rng.randi() % who.size()])
			return


## `id` does `bit` now (the director's pick; the bridge and the tests may ask for one). False if he
## can't (not there, not calm, no line that fits).
func start(bit: String, id: StringName, extra: Dictionary = {}) -> bool:
	if not ins.has(id) or not can_do(id):
		return false
	var spec: Dictionary = (d.get("bits", {}) as Dictionary).get(bit, {})
	var f: Array = spec.get("for", [2.0, 2.0])
	var b := {"what": StringName(bit), "for": rng.randf_range(float(f[0]), float(f[1]))}
	b.merge(extra, true)
	var others: Array = []
	match bit:
		"laugh":
			b["sound"] = _laugh_of(id)
			# His table grins; one of them laughs a beat late.
			var near := _near(id, _n("table_m", 2.4))
			var s: Array = d.get("second_s", [0.5, 0.9])
			var second := &""
			for o: StringName in near:
				if second == &"" and _fits(o, spec.get("from", [])) and _may_again("laugh", o):
					second = o
					_later(rng.randf_range(float(s[0]), float(s[1])), o, {"what": &"laugh", "for": float(b["for"]) * 0.7,
							"sound": _laugh_of(o), "of": String(id)})
				else:
					_later(rng.randf_range(0.2, 0.5), o, {"what": &"grin", "for": float(b["for"]) + 0.6, "look": folk.folk_man(id)})
				others.append(String(o))
		"toast":
			var l := folk.room_line(id, "room.toast")
			if l.is_empty():
				return false
			b["say"] = String(l[1])
			b["line"] = String(l[0])
			b["say_at"] = 0.7
			for o: StringName in ins:
				if o != id and can_do(o) and doing_of(o) == "drink":
					_later(rng.randf_range(1.0, 1.5), o, {"what": &"lift", "for": 2.2, "look": folk.folk_man(id)})
					others.append(String(o))
		"cough":
			b["sound"] = &"cough"
	_give(id, b, others)
	return true


func _laugh_of(id: StringName) -> StringName:
	var man := folk.folk_man(id)
	return StringName("laugh_%d" % (absi(man.rng_seed if man != null else 0) % 3))


## The men within `m` of him who could answer a bit, nearest first.
func _near(id: StringName, m: float) -> Array[StringName]:
	var man := folk.folk_man(id)
	var found: Array = []
	for o: StringName in ins:
		var om := folk.folk_man(o)
		if o == id or om == null or not can_do(o):
			continue
		var dist := om.global_position.distance_to(man.global_position)
		if dist <= m:
			found.append([dist, o])
	found.sort()
	var out: Array[StringName] = []
	for e: Array in found:
		out.append(e[1])
	return out


func _later(seconds: float, id: StringName, bit: Dictionary) -> void:
	_pending.append({"frame": _after(seconds), "id": id, "what": &"bit", "bit": bit})


## The bit onto its man: his brain does it from this tick; its sound placed at his mouth; logged.
func _give(id: StringName, b: Dictionary, others: Array = []) -> void:
	var brain := _brain(id)
	var man := folk.folk_man(id)
	if brain == null or man == null:
		return
	b["by"] = String(id)
	b["at_s"] = snappedf(_clock, 0.01)
	b["seen"] = folk.seen_man_at(man.global_position)
	b["others"] = others
	_last["%s:%s" % [b.what, id]] = _clock
	brain.start_bit(b)
	if b.has("sound"):
		b["player"] = _sound(StringName(b.sound), man, String(b.what))
	log.append(b)
	if log.size() > 200:
		log.pop_front()


## A sound from a man: at his mouth, by GameAudio (walls, rooms, the air), logged with him.
func _sound(id: StringName, man: HumanBody, bit: String, at := Vector3.INF) -> AudioStreamPlayer3D:
	var sd: Dictionary = d.get("sounds", {})
	var where := at if at != Vector3.INF else man.global_transform * Vector3(0.0, 1.58, -0.12)
	sounds.append({"t": snappedf(_clock, 0.01), "sound": String(id), "by": String(man.person_id), "bit": bit,
			"at": where, "seen": folk.seen_man_at(man.global_position)})
	if sounds.size() > 300:
		sounds.pop_front()
	if not bool(sd.get("on", true)):
		return null
	var kind := String(id).get_slice("_", 0)
	# A voice by the man: lower for the heavy, higher for the woman (stand-ins for #807's takes).
	var pitch := 1.0
	if kind in ["laugh", "cough"]:
		pitch = 0.82 + 0.05 * float(absi(man.rng_seed) % 6)
		if "girl" in String(man.person_id) or "wife" in String(man.person_id) or "landlady" in String(man.person_id):
			pitch = 1.55
	return GameAudio.play(folk, id, where, {"volume_db": float(sd.get(kind + "_db", -9.0)), "unit_size": 3.0,
			"pitch": pitch, "limit": 6})


func _due(e: Dictionary) -> void:
	var id: StringName = e.id
	match e.what:
		&"bit":
			if ins.has(id) and can_do(id) and since_trouble > 1.0:
				_give(id, e.bit)
		&"look":
			var b := _brain(id)
			if b == null or not is_calm(b) or _logged.has(id):
				return
			if float(b.dials.get("ducks", 0.0)) > 0.0:
				b.reaction.sense(&"hush", e.at, e.who)
			else:
				b.show_look(e.at, e.who, float((d.get("trouble", {}) as Dictionary).get("look_s", 4.0)))
		&"glance":
			var b := _brain(id)
			if b != null and is_calm(b) and b.showing.is_empty():
				b.show_look(e.at, e.who, 1.6)


# --- Coming and going --------------------------------------------------------------------------------

func _events(p: Node3D, dt: float) -> void:
	var was := _you_was
	_you_was = you_in
	if you_in and not was and _clock - _entered_at > _n("enter_again_s", 120.0):
		_entered_at = _clock
		_enter_tries = 4
	# (A few looks for it: the man who hails him has to have seen him come in.)
	if _enter_tries > 0 and you_in:
		_enter_tries -= 1
		if _you_came_in(p):
			_enter_tries = 0
	_glass_step(p, dt)


## A man of the room's come in: one at the bar or the cards hails him, and he lifts a hand.
func _came_in(id: StringName) -> void:
	var man := folk.folk_man(id)
	if man == null or mood < 0.3:
		return
	for o: StringName in ins:
		if o == id or not can_do(o) or not doing_of(o) in ["drink", "play"] or not _may_again("hail", o):
			continue
		var named := TownNews.PROPER.has(id)
		var l := folk.room_line(o, "room.hail", {"whom": named, "who_you": false,
				"slots": {"whom": String(TownNews.PROPER.get(id, ""))}})
		if l.is_empty():
			continue
		_give(o, {"what": &"hail", "for": 2.2, "look": man, "say": String(l[1]), "line": String(l[0]), "say_at": 0.3}, [String(id)])
		_pending.append({"frame": _after(1.1), "id": id, "what": &"bit", "bit": {"what": &"wave", "for": 1.6, "look": folk.folk_man(o)}})
		return


## A man going home: "Night, all", and one answers.
func _goes(id: StringName) -> void:
	var b := _brain(id)
	var man := folk.folk_man(id)
	if b == null or man == null or not b.may_speak() or b.mood != CivilianBrain.Mood.CALM or mood < 0.2:
		return
	var l := folk.room_line(id, "room.leave")
	if l.is_empty():
		return
	folk.say_soon(man, String(l[1]))
	log.append({"what": &"leave", "by": String(id), "at_s": snappedf(_clock, 0.01), "say": String(l[1]),
			"line": String(l[0]), "seen": folk.seen_man_at(man.global_position), "others": []})
	for o: StringName in ins:
		if o == id or not can_do(o):
			continue
		var a := folk.room_line(o, "room.answer")
		if a.is_empty():
			continue
		_later(1.2, o, {"what": &"nod", "for": 1.4, "look": man, "say": String(a[1]), "line": String(a[0]), "say_at": 0.2})
		(log[-1].others as Array).append(String(o))
		return


## Harlan through the door: the town's answer to what he did, in one doorway (the brief's third night).
func _you_came_in(p: Node3D) -> bool:
	if folk.regard == null or since_trouble < _n("hold_s", 10.0):
		return true
	var band := folk.regard.town_band()
	if band == &"warm":
		# A man who's warm to him himself, who sees him, says it.
		for o: StringName in ins:
			var b := _brain(o)
			if not can_do(o) or folk.regard.band(o) != &"warm" or b.senses == null or not b.senses.sees(p):
				continue
			var l := folk.room_line(o, "room.hail", {"whom": false, "who_you": true})
			if l.is_empty():
				continue
			_give(o, {"what": &"hail", "for": 2.2, "look": p, "say": String(l[1]), "line": String(l[0]), "say_at": 0.3}, ["you"])
			return true
		return false
	elif band in [&"cold", &"afraid"]:
		# The talk drops: mouths shut, the nearest few look round at him and away.
		var drop: Dictionary = d.get("drop", {})
		_drop_at = _clock
		_next_bit = maxf(_next_bit, float(drop.get("quiet_s", 6.0)) + 4.0)
		var near: Array = []
		for o: StringName in ins:
			var b := _brain(o)
			if b == null:
				continue
			b.quiet = float(drop.get("quiet_s", 6.0))
			if not b.bit.is_empty():
				b.cut_bit()
			near.append([b.body.global_position.distance_to(p.global_position), o])
		near.sort()
		for i in mini(int(drop.get("looks", 3)), near.size()):
			_pending.append({"frame": _after(0.3 + 0.25 * i), "id": near[i][1], "what": &"glance",
					"at": p.global_position + Vector3.UP * 1.5, "who": p})
		log.append({"what": &"drop", "by": "", "at_s": snappedf(_clock, 0.01), "band": String(band), "others":
				near.slice(0, int(drop.get("looks", 3))).map(func(e: Array) -> String: return String(e[1]))})
		_set_mood()
	return true


## The barkeep's glass, set down unasked before a man he's warm to (once a night).
func _glass_step(p: Node3D, dt: float) -> void:
	var g: Dictionary = d.get("glass", {})
	var id := &"barkeep"
	var day := folk.town_day()
	if _glass_day == day or not ins.has(id) or not you_in or folk.regard == null or folk.regard.band(id) != &"warm":
		_by_bar = 0.0
		return
	var man := folk.folk_man(id)
	var to := p.global_position - man.global_position
	to.y = 0.0
	if to.length() > float(g.get("m", 2.3)) or doing_of(id) != "counter" or not can_do(id) or not folk.props.has("bar"):
		_by_bar = 0.0
		return
	_by_bar += dt
	if _by_bar < float(g.get("wait_s", 2.0)):
		return
	_glass_day = day
	var top := folk.top_point("bar", 0.0, [0.0, 0.0]).y
	var at := Vector3(man.global_position.x, top, man.global_position.z) + to.normalized() * minf(to.length() * 0.5, 0.62)
	var l := folk.room_line(id, "room.glass")
	var b := {"what": &"glass", "for": 2.8, "at": at, "mark_t": 1.3, "mark": _set_glass.bind(at, man), "look": p}
	if not l.is_empty():
		b["say"] = String(l[1])
		b["line"] = String(l[0])
		b["say_at"] = 1.7
	_give(id, b, ["you"])


func _set_glass(at: Vector3, man: HumanBody) -> void:
	_clear_glass()
	glass = MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.03
	m.bottom_radius = 0.026
	m.height = 0.08
	glass.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.62, 0.45)
	glass.material_override = mat
	glass.name = "RoomGlass"
	folk.add_child(glass)
	glass.global_position = at + Vector3.UP * 0.04
	_sound(&"glass_down", man, "glass", at)


func _clear_glass() -> void:
	if glass != null and is_instance_valid(glass) and (not open() or _glass_day != folk.town_day()):
		glass.queue_free()
		glass = null


# --- The hush -----------------------------------------------------------------------------------------

func _on_deed(actor: Node, kind: StringName, _target: Node, at: Vector3) -> void:
	var t: Dictionary = d.get("trouble", {})
	if not _built or not String(kind) in (t.get("deeds", []) as Array):
		return
	if inside(at, float(t.get("margin_m", 3.0))):
		trouble(at, actor as Node3D)


func _on_shot(origin: Vector3, _direction: Vector3, shooter: Node) -> void:
	if _built and inside(origin, float((d.get("trouble", {}) as Dictionary).get("shot_m", 15.0))):
		trouble(origin, shooter as Node3D)


## Trouble at `at` (by `who`): the director stops, and each man who hasn't sensed it himself looks
## round after his own delay, by his distance (the piano player ducks).
func trouble(at: Vector3, who: Node3D) -> void:
	if ins.is_empty():
		return
	var fresh := since_trouble > 5.0
	since_trouble = 0.0
	trouble_at = at
	trouble_who = who
	if not fresh:
		return
	_trouble_frame = Engine.get_physics_frames()
	_live = true
	hush_log = []
	_logged = {}
	_pending = _pending.filter(func(e: Dictionary) -> bool: return e.what != &"bit")
	var t: Dictionary = d.get("trouble", {})
	var look: Dictionary = t.get("look", {})
	for id: StringName in ins:
		var b := _brain(id)
		if b == null or b.body == who:
			continue
		var dist := b.body.global_position.distance_to(at)
		var after := clampf(float(look.get("base", 0.25)) + float(look.get("per_m", 0.07)) * dist
				+ float(look.get("nerve", 0.15)) * float(b.dials.get("nerve", 0.5)), 0.15, 1.2)
		_pending.append({"frame": _after(after), "id": id, "what": &"look", "at": at + Vector3.UP * 1.3, "who": who})


## Each man's turn, as it comes: his own Reaction's start, or the room's look.
func _log_turns(now: int) -> void:
	for id: StringName in ins:
		if _logged.has(id):
			continue
		var b := _brain(id)
		if b == null or (trouble_who != null and b.body == trouble_who):
			continue
		var how := ""
		if b.reaction.stage >= Reaction.Stage.LOOK:
			how = "duck" if b.reaction.kind == &"hush" else "own"
		elif b.showing.get("what", &"") == &"look":
			how = "look"
		elif b.mood in [CivilianBrain.Mood.COWERING, CivilianBrain.Mood.HANDS_UP, CivilianBrain.Mood.FLEEING]:
			how = "own"
		if how == "":
			continue
		_logged[id] = true
		hush_log.append({"id": String(id), "d": snappedf(b.body.global_position.distance_to(trouble_at), 0.01),
				"s": snappedf(float(now - _trouble_frame) / Engine.physics_ticks_per_second, 0.01), "how": how})


# --- For the bridge and the tests ---------------------------------------------------------------------

func report() -> Dictionary:
	var out := {"mood": snappedf(mood, 0.01), "name": String(mood_name()), "target": snappedf(target, 0.01), "parts": parts,
			"in": ins.map(func(i: StringName) -> String: return String(i)), "you_in": you_in, "open": open(),
			"since_trouble": snappedf(since_trouble, 0.1) if since_trouble < 1e6 else -1.0,
			"next_bit_in": snappedf(_next_bit, 0.1), "hush": hush_log}
	var last: Array = []
	for b: Dictionary in log.slice(-12):
		last.append({"t": b.get("at_s", 0.0), "bit": String(b.what), "by": b.get("by", ""), "seen": b.get("seen", false),
				"others": b.get("others", []), "say": b.get("say", ""), "cut": b.get("cut", false)})
	out["bits"] = last
	out["sounds"] = sounds.slice(-12).map(func(s: Dictionary) -> Dictionary:
		return {"t": s.t, "sound": s.sound, "by": s.by, "bit": s.bit, "seen": s.seen})
	return out
