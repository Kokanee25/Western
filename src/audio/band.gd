class_name Band
extends Node3D
## The band (#799): the saloon's players playing together from one tune's note data, each part
## heard from where its player is. The parts are rendered once, offline, by the sound lab's own
## models (tools/band/render_band.py: the fiddle B, the banjo, the piano, the harmonica, the bones
## and the tambourine; assets/audio/band/<tune>/<part>.ogg), all from t = 0 of the tune, and played
## here on one clock; `notes.json` beside them is the game's note data: the bars, the phrases (where
## a player stops and starts), the fiddle's bow strokes and the piano's keys, which the players'
## hands follow (PlayChore). One note data drives the sound and the hands.
##
## config/band.json says where the band plays (a lot's points, as ValleyFolk's), its hours, its
## tunes, its players and who plays each part: a part with a `man` (a ValleyFolk man, PlayChore at
## his instrument) sounds only while he's at it and free (he cowers from a shot, runs from a fire,
## dies: his part stops); a part without one is placed sound only, at its point.
##
## Each part is an AudioStreamPlayer3D at its player, re-placed through GameAudio a few times a
## second as a loop is (the Room bus under a roof, Muffled through a wall, the air's highs by
## distance: GameAudio.replace_loop). It isn't held back by the distance as a shot is: a tune going
## on can't be heard to be late.
##
## Stopping: a part stops in `stop_s` (the bow lifted: the strings ring on that long), any time; a
## part starts only at a phrase's start (a player joins at the top of the next four bars). A shot
## within `hush.shot_m` (or a blast within `blast_m`) stops them all dead; once it's been quiet
## `hush.quiet_s` they start again from the top of the phrase they stopped in. A man killed within
## `hush.death_m` and they're done for the night. Out of their hours they finish the tune and stop.
## Between tunes a pause of `between_s`.
##
## Where they play by the night (#938, Sean's decision on #938): `nights` by the town's day kind
## (ValleyFolk.day_kind): Payday Night the full band on saloon B's stage (`hall` saloon, each part at
## a use point of its spec or a `local` point, the curtain drawn open while they play); a night
## with no entry plays as the data's own `players` and `lot` (the yard set). A night's `players`
## names who plays it: a part it leaves out is silent that night.
##
## A fist fight near them (`fight`: a deed of `kinds` within `fight_m`) and they play on faster: at
## the next phrase's top every part goes over to the tune's hurried render (<tune>_fast, the same
## score played `faster` times as fast: tools/band/render_band.py --faster) at the same phrase, and
## back at a phrase's top once it's been `fight_s` since the last blow. A gun drawn or aimed within
## `fight.draw_m` stops them as a shot does.

const DATA := "res://config/band.json"
const PARTS := "res://assets/audio/band/"
## The quietest a part is mixed at before it counts as stopped (dB).
const SILENT_DB := -60.0

## The band's data (config/band.json, or a test's).
var data: Dictionary
## Where its points are (a lot's, as ValleyFolk.lot_point) and its men; null: points are world
## [x, y, z] (`pos`), and no part has a man.
var folk: ValleyFolk
## The tune now and its note data (notes.json).
var tune_id := ""
var notes: Dictionary = {}
## &"off" (out of hours), &"playing", &"between" (tunes), &"hushed" (a shot: waiting for quiet),
## &"done" (for the night: a killing).
var state: StringName = &"off"
## The tune's time (s): where the parts are.
var clock := 0.0
## Where they stopped and will start again (s; a phrase's start).
var resume_at := 0.0
## id -> {spec, sound (AudioStreamPlayer3D), gain (0..1), joining (bool), chore (PlayChore)}.
var players := {}
## Why they last stopped (&"shot", &"blast", &"death", &"hours", &"end"), and the log of it:
## [what, the tune's clock, the game's time] (tests and the bridge).
var why: StringName = &""
var log: Array = []
## Tests: the hours ignored (always in them), and a clock of its own (else ValleyFolk's).
var always := false
var _quiet := 0.0
var _wait := 0.0
var _tune_i := -1
var _replace := 0.0
var _streams := {}
var _sync := 0.0
var rng := RandomNumberGenerator.new()
## The night they're playing (a day kind: &"payday", &"ordinary"), chosen as they start the evening.
var night: StringName = &"ordinary"
## Playing the hurried render (a fight on), and how long the fight's still on for (s).
var fast := false
var _fight_left := 0.0
## After trouble stopped them (a gun, a shot, a blast: `shaky`), the start again is thin and a little
## fast (Sean, #276: "starts again shakily"): the piano alone for the first phrase, the hurried
## render for `shaky.fast_s`. Seconds of it left; and how many times it's happened (tests).
var _shaky_left := 0.0
var _shaky := false
var shaky_starts := 0
var wrong_notes := 0
var _wrong: Array = []
## Tests: the night to play (else the folk's day kind).
var night_override: StringName = &""
## Heard through a real audio device: the tune's clock is kept to the parts (a long frame and the
## hands would fall behind the sound). Without one (the Dummy driver: the tests, headless, a movie's
## recording, where the game's clock isn't the wall's), the parts are kept to the tune's clock.
## (`--fixed-fps` can't be asked: the engine takes it off the command line.)
var follow_clock := true
## The parts and the clock this far apart (s) before one is brought to the other.
const DRIFT := 0.12
## The fiddle's bow, worked out once a tune from its strokes: [t0, t1, s0, s1, string angle].
var bow_plan: Array = []
## The piano's hands, once a tune: hand (0 left, 1 right) -> [[t, midi]...] (a chord one strike).
var strikes := {0: [], 1: []}


func _init() -> void:
	name = "Band"


func _ready() -> void:
	add_to_group(&"band")
	if data.is_empty():
		data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	rng.seed = int(data.get("seed", 1882))
	follow_clock = AudioServer.get_driver_name() == "Dummy"
	for spec: Dictionary in data.get("players", []):
		var id := StringName(spec.id)
		var p := AudioStreamPlayer3D.new()
		p.name = "Part_%s" % spec.id
		var s: Dictionary = data.get("sound", {})
		p.unit_size = float(spec.get("unit_size", s.get("unit_size", 2.0)))
		p.max_db = float(s.get("max_db", 3.0))
		p.volume_db = SILENT_DB
		p.top_level = true
		add_child(p)
		players[id] = {"spec": spec, "sound": p, "gain": 0.0, "joining": false, "chore": null}
	Events.shot_fired.connect(_on_shot)
	Events.exploded.connect(_on_blast)
	Events.person_died.connect(_on_death)
	Events.deed.connect(_on_deed)
	_load_tune(0)
	# Where they are now; their buses from the first physics frame (no physics queries outside it).
	_place_all(false)
	_replace = 0.0


# --- The note data ---------------------------------------------------------------------------

func _load_tune(i: int) -> void:
	var tunes: Array = data.get("tunes", [])
	if tunes.is_empty():
		return
	_tune_i = i % tunes.size()
	tune_id = String(tunes[_tune_i])
	fast = fast and has_fast(tune_id)
	_set_streams()


## The render playing now: the tune's own, or (a fight on) its hurried one.
func render_id() -> String:
	return tune_id + ("_fast" if fast else "")


## The tune has a hurried render (assets/audio/band/<tune>_fast/).
static func has_fast(tune: String) -> bool:
	return FileAccess.file_exists(PARTS + tune + "_fast/notes.json")


func _set_streams() -> void:
	notes = load_notes(render_id())
	for id: StringName in players:
		var part := String(players[id].spec.get("part", id))
		var p: AudioStreamPlayer3D = players[id].sound
		p.stop()
		p.stream = part_stream(render_id(), part)
	_plan_bow()
	_plan_keys()


## Over to the hurried render (or back) at the top of the phrase `clock` is at: the same phrase in
## the other, every part playing on from there at its level.
func _change_tempo(to_fast: bool) -> void:
	var phrases: Array = notes.get("phrases", [0.0])
	var i := maxi(phrases.find(phrase_start(clock)), 0)
	var into := clock - phrase_start(clock)
	var was := float(notes.get("faster", 1.0))
	fast = to_fast
	_set_streams()
	var now := float(notes.get("faster", 1.0))
	var ph: Array = notes.get("phrases", [0.0])
	clock = float(ph[mini(i, ph.size() - 1)]) + into * was / now
	log.append([&"faster" if fast else &"steady", clock, tune_id])
	_sync = 0.6
	for id: StringName in players:
		var p: AudioStreamPlayer3D = players[id].sound
		if p.stream and p.is_inside_tree() and (float(players[id].gain) > 0.0 or bool(players[id].joining)):
			p.play(clock)


static func load_notes(tune: String) -> Dictionary:
	var path := PARTS + tune + "/notes.json"
	if not FileAccess.file_exists(path):
		return {}
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## A part's recording (null if it wasn't rendered).
func part_stream(tune: String, part: String) -> AudioStream:
	var key := tune + "/" + part
	if not _streams.has(key):
		var path := PARTS + key + ".ogg"
		_streams[key] = load(path) if ResourceLoader.exists(path) else null
	return _streams[key]


## The start of the phrase `t` is in (s).
func phrase_start(t: float) -> float:
	var at := 0.0
	for p: float in notes.get("phrases", [0.0]):
		if p <= t + 1e-4:
			at = p
	return at


## The next phrase's start after `t` (INF past the last).
func next_phrase(t: float) -> float:
	for p: float in notes.get("phrases", []):
		if p > t + 1e-4:
			return p
	return INF


## How long the tune lasts, its last notes rung out (s).
func length() -> float:
	return float(notes.get("length_s", 0.0))


func _plan_bow() -> void:
	bow_plan.clear()
	var angles := {"G": 0.3, "D": 0.1, "A": -0.1, "E": -0.3}
	var s := 0.35
	for st: Array in notes.get("strokes", []):
		var t0 := float(st[0])
		var t1 := float(st[1])
		# A down bow draws the hand away from the strings (the hair passes from frog to tip): the
		# frog's way from the strings, `s`, grows; an up bow the other way. Longer strokes use more.
		var used := clampf((t1 - t0) * 1.2, 0.06, 0.42)
		var s1 := clampf(s + used * float(st[2]), 0.1, 0.56)
		bow_plan.append([t0, t1, s, s1, float(angles.get(String(st[3]), 0.0))])
		s = s1


func _plan_keys() -> void:
	strikes = {0: [], 1: []}
	for k: Array in notes.get("keys", []):
		var hand := int(k[3])
		var list: Array = strikes[hand]
		var t := float(k[0])
		if not list.is_empty() and t - float(list[-1][0]) < 0.035:
			# A chord: one strike, the hand over its middle.
			var last: Array = list[-1]
			last[2] = int(last[2]) + 1
			last[1] = float(last[1]) + (float(k[2]) - float(last[1])) / float(last[2])
			continue
		list.append([t, float(k[2]), 1])


## The fiddle's bow at the tune's `t`: [the frog's way from the strings (m), the string angle].
func bow_at(t: float) -> Vector2:
	if bow_plan.is_empty():
		return Vector2(0.35, 0.0)
	var i := _find(bow_plan, t)
	var b: Array = bow_plan[i]
	if t <= float(b[0]):
		return Vector2(float(b[2]), float(b[4]))
	var k := clampf((t - float(b[0])) / maxf(float(b[1]) - float(b[0]), 1e-3), 0.0, 1.0)
	var s := lerpf(float(b[2]), float(b[3]), k)
	# Crossing to the next stroke's string just before it.
	var ang := float(b[4])
	if i + 1 < bow_plan.size():
		var nb: Array = bow_plan[i + 1]
		ang = lerpf(ang, float(nb[4]), smoothstep(float(nb[0]) - 0.06, float(nb[0]), t))
	return Vector2(s, ang)


## The piano's hand (0 left, 1 right) at the tune's `t`: [midi under it, how far lifted (0..1)].
func hand_at(hand: int, t: float) -> Vector2:
	var list: Array = strikes.get(hand, [])
	if list.is_empty():
		return Vector2(60.0, 1.0)
	var i := _find(list, t)
	var a: Array = list[i]
	if t < float(a[0]):
		return Vector2(float(a[1]), 1.0)
	if i + 1 >= list.size():
		return Vector2(float(a[1]), clampf((t - float(a[0])) / 0.3, 0.0, 1.0))
	var b: Array = list[i + 1]
	var gap := maxf(float(b[0]) - float(a[0]), 0.02)
	var k := (t - float(a[0])) / gap
	# Up off the key and over to the next, down on it at its strike.
	var lift := sin(PI * clampf(k, 0.0, 1.0)) * clampf(gap / 0.25, 0.3, 1.0)
	return Vector2(lerpf(float(a[1]), float(b[1]), smoothstep(0.35, 0.95, k)), lift)


## The last entry starting at or before `t` (the first if none): a binary search on [t0, ...].
static func _find(list: Array, t: float) -> int:
	var lo := 0
	var hi := list.size() - 1
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if float(list[mid][0]) <= t:
			lo = mid
		else:
			hi = mid - 1
	return lo


# --- Where they are --------------------------------------------------------------------------

## A player's spot: his instrument (a man at it: PlayChore.sound_at), else the data's point.
func spot_of(id: StringName) -> Vector3:
	var pl: Dictionary = players[id]
	var ch: PlayChore = pl.chore
	if ch != null and ch.at_it():
		return ch.sound_at()
	return point_of(pl.spec)


## The data's point for a spec: [a, b] on the band's lot and `up` over its ground (with folk), or
## `pos` [x, y, z] in the world.
func point_of(spec: Dictionary) -> Vector3:
	var nt := tonight()
	var over: Dictionary = (nt.get("players", {}) as Dictionary).get(String(spec.get("id", "")), {})
	if folk != null and not over.is_empty():
		var up := float(over.get("up", spec.get("up", 1.0)))
		if nt.has("hall"):
			var hall := String(nt.hall)
			if over.has("use"):
				var u := folk.hall_use(hall, String(over.use))
				if not u.is_empty():
					return (u[0] as Vector3) + Vector3.UP * up
			if over.has("local"):
				return folk.hall_point(hall, over.local, up)
		if over.has("at"):
			var a: Array = over.at
			return folk.lot_point(String(nt.get("lot", data.lot)), float(a[0]), float(a[1]), up)
	if spec.has("pos") or folk == null:
		var p: Array = spec.get("pos", [0, 0, 0])
		return Vector3(float(p[0]), float(p[1]), float(p[2]))
	var at: Array = spec.at
	return folk.lot_point(String(data.lot), float(at[0]), float(at[1]), float(spec.get("up", 1.0)))


## The middle of the band (the hush's distances are from here).
func centre() -> Vector3:
	var c := Vector3.ZERO
	var n := 0
	for id: StringName in players:
		if plays_tonight(id):
			c += point_of(players[id].spec)
			n += 1
	return c / maxf(n, 1.0)


## Tonight's entry in `nights` ({} : the data's own players and lot).
func tonight() -> Dictionary:
	var nights: Dictionary = data.get("nights", {})
	var e: Variant = nights.get(String(night), {})
	return e if e is Dictionary else {}


## The night by the town's day kind (or the test's), where `nights` has one, else &"ordinary".
func _pick_night() -> void:
	var k := night_override
	if k == &"" and folk != null:
		k = folk.day_kind(folk.town_day())
	night = k if (data.get("nights", {}) as Dictionary).has(String(k)) else &"ordinary"
	_curtain(true)


## Saloon B's curtain drawn open while they play on its stage (a night with `curtain`), shut after.
func _curtain(open: bool) -> void:
	var nt := tonight()
	if folk == null or not nt.has("hall") or String(nt.get("curtain", "")) != "open":
		return
	var b: Node3D = folk.halls.get(String(nt.hall))
	if b == null or not is_instance_valid(b) or not b.has_method(&"open_curtain"):
		return
	var c: Variant = b.get(&"curtain")
	if c == null or not is_instance_valid(c):
		return
	if open and not c.is_open():
		b.open_curtain()
	elif not open and c.is_open():
		b.close_curtain()


## Whether a part's in tonight's band (a night's `players` names them; else every part).
func plays_tonight(id: StringName) -> bool:
	var nt := tonight()
	return not nt.has("players") or (nt.players as Dictionary).has(String(id))


func _place_all(buses := true) -> void:
	for id: StringName in players:
		var p: AudioStreamPlayer3D = players[id].sound
		p.global_position = spot_of(id)
		if buses and p.is_inside_tree():
			GameAudio.replace_loop(p)


## A PlayChore's man takes his part (ValleyFolk, when he comes in).
func seat(id: StringName, chore: PlayChore) -> void:
	if players.has(id):
		players[id].chore = chore


## Whether a part can sound now: no man to it, or its man at his instrument and free.
func can_play(id: StringName) -> bool:
	if not plays_tonight(id):
		return false
	var pl: Dictionary = players[id]
	if not String(pl.spec.get("man", "")).is_empty():
		var ch: PlayChore = pl.chore
		return ch != null and ch.is_ready()
	return true


## Sounding (or coming in): for the hands.
func sounding(id: StringName) -> bool:
	return players.has(id) and state == &"playing" and (float(players[id].gain) > 0.0 or bool(players[id].joining))


# --- The clock -------------------------------------------------------------------------------

func in_hours() -> bool:
	if always:
		return true
	var h: Array = data.get("hours", [19.0, 1.0])
	var now := folk.hour() if folk else 12.0
	return ValleyFolk.in_hours(now, h)


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	step(delta)
	Prof.stop(&"band", t)


func step(delta: float) -> void:
	if not _wrong.is_empty():
		_wrong_step(delta)
	match state:
		&"off":
			if in_hours():
				_pick_night()
				if _anyone():
					_start(0.0)
		&"done":
			_fade(delta)
			if not in_hours():
				_off()
		&"between":
			_wait -= delta
			if not in_hours():
				_off()
			elif _wait <= 0.0 and _anyone():
				_load_tune(_tune_i + 1)
				_start(0.0)
		&"hushed":
			_quiet += delta
			_fade(delta)
			if not in_hours():
				_off()
			elif _quiet >= float(data.get("hush", {}).get("quiet_s", 45.0)) and _anyone():
				_start(resume_at)
		&"playing":
			clock += delta
			_play_step(delta)
	_replace -= delta
	if _replace <= 0.0:
		_replace = float(data.get("replace_every", 0.25))
		_place_all()


## Out of their hours (or the night over): every part stopped, the next night from the top.
func _off() -> void:
	state = &"off"
	_curtain(false)
	_fight_left = 0.0
	_shaky_left = 0.0
	_shaky = false
	if fast:
		fast = false
		_set_streams()
	for id: StringName in players:
		players[id].gain = 0.0
		players[id].joining = false
		(players[id].sound as AudioStreamPlayer3D).stop()


## Someone to play: a part without a man, or a man at his instrument.
func _anyone() -> bool:
	for id: StringName in players:
		if can_play(id):
			return true
	return false


func _start(at: float) -> void:
	var sh: Dictionary = data.get("shaky", {})
	var shaky := _shaky and not sh.is_empty()
	if shaky and has_fast(tune_id) and not fast:
		# Over to the hurried render at the same phrase's top.
		var i := maxi((notes.get("phrases", [0.0]) as Array).find(phrase_start(at)), 0)
		fast = true
		_set_streams()
		var ph: Array = notes.get("phrases", [0.0])
		at = float(ph[mini(i, ph.size() - 1)])
	state = &"playing"
	clock = at
	resume_at = at
	why = &""
	# A part's playback position reads its last place till the mixer's been round: not read for now.
	_sync = 0.6
	log.append([&"start", at, tune_id])
	var thin := shaky and can_play(StringName(String(sh.get("first", "piano"))))
	if shaky:
		_shaky_left = float(sh.get("fast_s", 16.0))
		shaky_starts += 1
		log.append([&"shaky", at, tune_id])
	_shaky = false
	for id: StringName in players:
		var pl: Dictionary = players[id]
		pl.gain = 0.0
		# Shaky: the piano alone to begin with; the others come in at the next phrase's top.
		pl.joining = can_play(id) and (not thin or String(id) == String(sh.get("first", "piano")))
		var p: AudioStreamPlayer3D = pl.sound
		p.volume_db = SILENT_DB
		if p.stream and p.is_inside_tree():
			p.play(at)


func _play_step(delta: float) -> void:
	var end := length()
	if clock >= end:
		_stop_all(&"end")
		state = &"between"
		var b: Array = data.get("between_s", [5.0, 10.0])
		_wait = rng.randf_range(float(b[0]), float(b[1]))
		return
	var crossed := phrase_start(clock) > clock - delta - 1e-4 and phrase_start(clock) <= clock
	_fight_left = maxf(_fight_left - delta, 0.0)
	_shaky_left = maxf(_shaky_left - delta, 0.0)
	var want_fast := (_fight_left > 0.0 or _shaky_left > 0.0) and has_fast(tune_id)
	if crossed and want_fast != fast:
		_change_tempo(want_fast)
	for id: StringName in players:
		var pl: Dictionary = players[id]
		var can := can_play(id)
		if not can:
			pl.joining = false
		elif float(pl.gain) <= 0.0 and not pl.joining and crossed and not (_shaky_left > 0.0 and clock - resume_at < 0.05):
			pl.joining = true  # in at the top of the phrase
	_sync -= delta
	if _sync <= 0.0:
		_sync = 0.5
		_keep_time()
	# Out of their hours: they finish the tune (each part rings out at its end).
	_fade(delta)


## One clock: the hands to the sound, or (no audio device) the sound to the game.
func _keep_time() -> void:
	var lead: AudioStreamPlayer3D = null
	for id: StringName in players:
		var p: AudioStreamPlayer3D = players[id].sound
		if p.stream and p.is_inside_tree():
			if follow_clock:
				var pos := p.get_playback_position() if p.playing else -INF
				if absf(pos - clock) > DRIFT * 4.0 and clock < p.stream.get_length():
					p.play(clock)
					_sync = 0.6
			elif lead == null and p.playing:
				lead = p
	if lead:
		var pos := lead.get_playback_position() + AudioServer.get_time_since_last_mix()
		if absf(pos - clock) > DRIFT:
			clock = pos
	elif not follow_clock and players.values().any(func(pl: Dictionary) -> bool: return float(pl.gain) > 0.0):
		clock = length()  # the parts have run out ahead of the game (frames too slow to keep up)


## Each part's level toward its want: up quickly when joining, down in `stop_s`.
func _fade(delta: float) -> void:
	var down := delta / maxf(float(data.get("stop_s", 0.25)), 1e-3)
	var up := delta / maxf(float(data.get("start_s", 0.06)), 1e-3)
	for id: StringName in players:
		var pl: Dictionary = players[id]
		var want := state == &"playing" and bool(pl.joining) and can_play(id)
		if state == &"playing" and not want:
			pl.joining = false
		pl.gain = clampf(float(pl.gain) + (up if want else -down), 0.0, 1.0)
		var p: AudioStreamPlayer3D = pl.sound
		var base := float(data.get("sound", {}).get("volume_db", 0.0))
		p.volume_db = maxf(base + linear_to_db(maxf(float(pl.gain), 1e-4)), SILENT_DB)
		if state != &"playing" and float(pl.gain) <= 0.0 and p.playing:
			p.stop()


func _stop_all(reason: StringName) -> void:
	why = reason
	log.append([reason, clock, tune_id])
	for id: StringName in players:
		var pl: Dictionary = players[id]
		pl.joining = false
		if reason == &"end":
			pl.gain = 0.0
			(pl.sound as AudioStreamPlayer3D).stop()


## Stopped dead (the bow lifted): every part fades in `stop_s`, and they wait for quiet.
func hush(reason: StringName) -> void:
	if state == &"done":
		return
	_quiet = 0.0
	if reason in [&"gun", &"shot", &"blast"]:
		_shaky = true
	if state == &"playing":
		if reason in [&"gun", &"shot", &"blast"]:
			_wrong_notes()
		resume_at = phrase_start(clock)
		_stop_all(reason)
		state = &"hushed"
	elif state == &"between":
		resume_at = 0.0
		why = reason
		state = &"hushed"
	elif state == &"hushed":
		why = reason


## The piano player's hands as it stops him (the brief: "two wrong notes after that"): two short
## stabs of his own part, off pitch, from his piano, a moment after the rest have stopped.
func _wrong_notes() -> void:
	var sh: Dictionary = data.get("shaky", {})
	var id := StringName(String(sh.get("first", "piano")))
	if sh.is_empty() or not players.has(id) or float(players[id].gain) <= 0.0:
		return
	var src: AudioStreamPlayer3D = players[id].sound
	var times: Array = sh.get("wrong_at_s", [0.22, 0.47])
	var pitches: Array = sh.get("wrong_pitch", [1.06, 0.89])
	for i in times.size():
		wrong_notes += 1
		log.append([&"wrong_note", clock + float(times[i]), tune_id])
		if src.stream == null or not is_inside_tree():
			continue
		var p := AudioStreamPlayer3D.new()
		p.stream = src.stream
		p.unit_size = src.unit_size
		p.max_db = src.max_db
		p.bus = src.bus
		p.volume_db = float(data.get("sound", {}).get("volume_db", 0.0)) - 2.0
		p.pitch_scale = float(pitches[i % pitches.size()])
		add_child(p)
		p.global_position = src.global_position
		_wrong.append({"p": p, "in": float(times[i]), "for": float(sh.get("wrong_s", 0.16)), "from": clock})


## The wrong notes on their way: each played at its moment and stopped after.
func _wrong_step(delta: float) -> void:
	for w: Dictionary in _wrong.duplicate():
		var p: AudioStreamPlayer3D = w.p
		w["in"] = float(w["in"]) - delta
		if float(w["in"]) <= 0.0 and not p.playing and not w.get("played", false):
			w["played"] = true
			p.play(float(w.from))
		if float(w["in"]) <= -float(w["for"]):
			p.queue_free()
			_wrong.erase(w)


func _near(at: Vector3, m: float) -> bool:
	return at.distance_to(centre()) <= m


func _on_shot(origin: Vector3, _direction: Vector3, _shooter: Node) -> void:
	if _near(origin, float(data.get("hush", {}).get("shot_m", 80.0))):
		hush(&"shot")


func _on_blast(at: Vector3, _kg: float) -> void:
	if _near(at, float(data.get("hush", {}).get("blast_m", 200.0))):
		hush(&"blast")


## A fist fight's blow near them: they play on, faster (from the next phrase); a gun drawn or aimed
## near them: stopped as a shot stops them.
func _on_deed(_actor: Node, kind: StringName, _target: Node, at: Vector3) -> void:
	var f: Dictionary = data.get("fight", {})
	if f.is_empty() or state == &"done" or state == &"off":
		return
	if String(kind) in (f.get("draws", ["draw", "aim_at"]) as Array):
		if _near(at, float(f.get("draw_m", 25.0))):
			hush(&"gun")
	elif String(kind) in (f.get("kinds", []) as Array) and _near(at, float(f.get("fight_m", 25.0))):
		_fight_left = float(f.get("fight_s", 20.0))
		if state == &"playing" and not fast and has_fast(tune_id) and _fight_left > 0.0 and clock < 0.05:
			_change_tempo(true)  # a blow as they start: in at the hurried tempo


func _on_death(person: Node, _cause: StringName) -> void:
	if not (person is Node3D) or not _near((person as Node3D).global_position, float(data.get("hush", {}).get("death_m", 30.0))):
		return
	hush(&"death")
	state = &"done"
	log.append([&"done", clock, tune_id])


## For the bridge and the tests.
func report() -> Dictionary:
	var parts := {}
	for id: StringName in players:
		var pl: Dictionary = players[id]
		var p: AudioStreamPlayer3D = pl.sound
		parts[String(id)] = {"gain": snappedf(float(pl.gain), 0.01), "playing": p.playing, "bus": String(p.bus),
				"at": [snappedf(p.global_position.x, 0.01), snappedf(p.global_position.y, 0.01), snappedf(p.global_position.z, 0.01)],
				"man": String(pl.spec.get("man", "")), "can": can_play(id)}
	return {"state": String(state), "tune": tune_id, "fast": fast, "night": String(night), "clock": snappedf(clock, 0.01),
			"why": String(why), "resume_at": resume_at, "parts": parts}
