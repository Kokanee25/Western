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
## Run with `--fixed-fps` (the tests, the bridge, a recording): the game's clock isn't the wall's,
## so the parts are kept to the tune's clock; else the tune's clock is kept to the parts (a long
## frame and the hands would fall behind the sound).
static var fixed_fps := "--fixed-fps" in OS.get_cmdline_args()
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
	_load_tune(0)
	_place_all()


# --- The note data ---------------------------------------------------------------------------

func _load_tune(i: int) -> void:
	var tunes: Array = data.get("tunes", [])
	if tunes.is_empty():
		return
	_tune_i = i % tunes.size()
	tune_id = String(tunes[_tune_i])
	notes = load_notes(tune_id)
	for id: StringName in players:
		var part := String(players[id].spec.get("part", id))
		var p: AudioStreamPlayer3D = players[id].sound
		p.stop()
		p.stream = part_stream(tune_id, part)
	_plan_bow()
	_plan_keys()


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
	if spec.has("pos") or folk == null:
		var p: Array = spec.get("pos", [0, 0, 0])
		return Vector3(float(p[0]), float(p[1]), float(p[2]))
	var at: Array = spec.at
	return folk.lot_point(String(data.lot), float(at[0]), float(at[1]), float(spec.get("up", 1.0)))


## The middle of the band (the hush's distances are from here).
func centre() -> Vector3:
	var c := Vector3.ZERO
	for id: StringName in players:
		c += point_of(players[id].spec)
	return c / maxf(players.size(), 1.0)


func _place_all() -> void:
	for id: StringName in players:
		var p: AudioStreamPlayer3D = players[id].sound
		p.global_position = spot_of(id)
		if p.is_inside_tree():
			GameAudio.replace_loop(p)


## A PlayChore's man takes his part (ValleyFolk, when he comes in).
func seat(id: StringName, chore: PlayChore) -> void:
	if players.has(id):
		players[id].chore = chore


## Whether a part can sound now: no man to it, or its man at his instrument and free.
func can_play(id: StringName) -> bool:
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
	match state:
		&"off":
			if in_hours() and _anyone():
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
	state = &"playing"
	clock = at
	why = &""
	# A part's playback position reads its last place till the mixer's been round: not read for now.
	_sync = 0.6
	log.append([&"start", at, tune_id])
	for id: StringName in players:
		var pl: Dictionary = players[id]
		pl.gain = 0.0
		pl.joining = can_play(id)
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
	for id: StringName in players:
		var pl: Dictionary = players[id]
		var can := can_play(id)
		if not can:
			pl.joining = false
		elif float(pl.gain) <= 0.0 and not pl.joining and crossed:
			pl.joining = true  # in at the top of the phrase
	_sync -= delta
	if _sync <= 0.0:
		_sync = 0.5
		_keep_time()
	# Out of their hours: they finish the tune (each part rings out at its end).
	_fade(delta)


## One clock: the hands to the sound, or (fixed fps) the sound to the game.
func _keep_time() -> void:
	var lead: AudioStreamPlayer3D = null
	for id: StringName in players:
		var p: AudioStreamPlayer3D = players[id].sound
		if p.stream and p.is_inside_tree():
			if fixed_fps:
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
	elif not fixed_fps and players.values().any(func(pl: Dictionary) -> bool: return float(pl.gain) > 0.0):
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
	if state == &"playing":
		resume_at = phrase_start(clock)
		_stop_all(reason)
		state = &"hushed"
	elif state == &"between":
		resume_at = 0.0
		why = reason
		state = &"hushed"
	elif state == &"hushed":
		why = reason


func _near(at: Vector3, m: float) -> bool:
	return at.distance_to(centre()) <= m


func _on_shot(origin: Vector3, _direction: Vector3, _shooter: Node) -> void:
	if _near(origin, float(data.get("hush", {}).get("shot_m", 80.0))):
		hush(&"shot")


func _on_blast(at: Vector3, _kg: float) -> void:
	if _near(at, float(data.get("hush", {}).get("blast_m", 200.0))):
		hush(&"blast")


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
	return {"state": String(state), "tune": tune_id, "clock": snappedf(clock, 0.01), "why": String(why),
			"resume_at": resume_at, "parts": parts}
