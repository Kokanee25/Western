class_name TrainSound
extends Node3D
## The train heard (train step 4, issue #571; docs/briefs/train.md): every sound timed from the
## simulation, never from the drawn frame, so nothing doubles or drops at a low frame rate.
##
## On each physics tick (`tick`, after the sim's step) it finds what happened during the tick and
## when, to the sub-tick: each exhaust beat (the drivers past a quarter turn, as EngineModel counts
## them: four a turn), each axle over a rail joint (TrainTuning.rail_length), each coupler's slack
## running out or bunching (TrainSim's events), each strike of the bell. Each becomes a one-shot
## heard from where it happened, late by its distance over the speed of sound, pitched by the
## Doppler shift of its source and the ears then, its highs taken by the air (GameAudio.air_cutoff),
## on GameAudio's bus for walls and rooms. The one-shots are started on the drawn frame (`_process`)
## that's due, each skipped into its lead of silence (TrainSynth.LEAD) by how late it is, so it
## sounds on its own moment.
##
## The loops (the wheels rolling, the brakes' squeal and grind, the cocks' hiss at a start, the
## engine simmering, the safety valve, the whistle) are held by the drawn frame on their car: their
## level from the sim, their pitch Doppler-shifted as they move.
##
## The bell and the whistle are worked from outside (`ring`, `whistle`, `blow`: the cab's keys and
## the bridge). Nothing is made or played without ears (a camera or a listener): the headless
## scenarios and tests cost nothing. Dials: config/train_sound.tres (TrainSoundTuning).

const SPEED_OF_SOUND := GameAudio.SPEED_OF_SOUND
## Wheels a car truck, m apart (TrainModels' arch-bar trucks: 1.2 m).
const TRUCK_AXLES := 1.2
## How often the bus (walls, rooms) is worked out again, s.
const BUS_EVERY := 0.25
## Ears moving faster than this (m/s) were put somewhere (a camera cut): no Doppler from it.
const EARS_JUMP := 60.0

var train: Train
var k: TrainSoundTuning
var on := true
## Only these kinds heard, if any (the lab's `train_sound solo`, for listening to one at a time):
## chuff, cocks, clack, clank, bell, rumble, squeal, grind, simmer, safety, whistle.
var solo := PackedStringArray()
## The engine's numbers (assets/train/engine_rig.json): its drivers, the stack, bell, whistle.
var rig := {}

## Counts since setup, for the checks: beats, clacks, couplers heard, bell strikes, one-shots
## started, culled (too quiet at the ears) and stolen (a voice taken from an older one).
var counts := {}
## The one-shots due: {id, at, t, db, pitch, unit, max_db, pool}. Started by the frame that's due.
var queue: Array[Dictionary] = []
## What it costs: microseconds over ticks and frames since `cost_reset`.
var cost := {}
## The last one-shots started, for the checks: {id, t (when it happened), on (when heard), from}.
var log_started := false
var started: Array[Dictionary] = []

var _pools := {}  # pool -> Array[AudioStreamPlayer3D]
var _turn := {}  # pool -> the next to use
var _loops := {}  # name -> AudioStreamPlayer3D
var _axles: Array[Vector2] = []  # (car, m behind the car's front)
var _joint := PackedInt32Array()  # the joint each axle is past
var _quarter := 0
var _primed := false
var _warmed := false
var _ears: Node3D
var _ears_at := Vector3.ZERO
var _ears_vel := Vector3.ZERO
var _bus := &"Master"
var _bus_t := -INF

# The bell and whistle, the safety valve.
var bell := false
var _bell_next := 0.0
var _bell_n := 0
var whistle_held := false
var _blasts: Array[Vector2] = []  # (start, end) in the sim's time
var _whistle := 0.0  # 0..1: the steam at the whistle
var _standing := 0.0
var _valve_until := -INF
var _valve := 0.0


func setup(t: Train) -> void:
	train = t
	k = load("res://config/train_sound.tres")
	rig = JSON.parse_string(FileAccess.get_file_as_string(EngineModel.RIG))
	_axles.clear()
	var sim := t.sim
	for i in sim.cars.size():
		var c: Dictionary = sim.cars[i]
		if c.kind == &"engine":
			_axles.append(Vector2(i, float(rig.mid) + float(rig.pony_z)))
			for z: float in rig.drivers_z:
				_axles.append(Vector2(i, float(rig.mid) + z))
		else:
			var tr: Vector2 = c.trucks
			for at: float in [tr.x, tr.y]:
				_axles.append(Vector2(i, at - TRUCK_AXLES * 0.5))
				_axles.append(Vector2(i, at + TRUCK_AXLES * 0.5))
	_joint.resize(_axles.size())
	_primed = false
	queue.clear()
	process_priority = 90  # after the train's drawn cars are placed


## The pools and loops, made the first time there are ears.
func _make_players() -> void:
	var sizes := {&"exhaust": k.exhaust_voices, &"clack": k.clack_voices, &"clank": k.clank_voices, &"bell": k.bell_voices}
	for pool: StringName in sizes:
		var list: Array[AudioStreamPlayer3D] = []
		for j in int(sizes[pool]):
			list.append(_player("%s%d" % [pool, j]))
		_pools[pool] = list
		_turn[pool] = 0
	for name: StringName in [&"rumble_front", &"rumble_back", &"squeal_front", &"squeal_back", &"grind_front",
			&"grind_back", &"cocks", &"simmer", &"safety", &"whistle"]:
		var p := _player(String(name))
		p.set_meta(&"id", &"train_cocks_loop" if name == &"cocks" else StringName("train_" + String(name).get_slice("_", 0)))
		_loops[name] = p


func _player(nm: String) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.name = nm
	p.top_level = true  # left where it was made: a one-shot stays where it happened
	add_child(p)
	return p


func _warm() -> void:
	_warmed = true
	SynthSounds.warm(TrainSynth.WARM)
	_make_players()


func _count(what: String, n := 1) -> void:
	counts[what] = int(counts.get(what, 0)) + n


# --- The tick: what happened, and when ---------------------------------------------------------

## After the sim's step of `dt`, with its coupler events.
func tick(dt: float, events: Array) -> void:
	if not on or train == null or not is_inside_tree():
		return
	_ears = GameAudio.ears_of(self)
	if _ears == null:
		_primed = false
		return
	var u := Time.get_ticks_usec()
	var t0 := Prof.start()
	if not _warmed:
		_warm()
	var sim := train.sim
	var e := _ears.global_position
	_ears_vel = (e - _ears_at) / dt if _primed else Vector3.ZERO
	if _ears_vel.length() > EARS_JUMP:
		_ears_vel = Vector3.ZERO  # the camera was moved, not carried
	_ears_at = e
	if not _primed or absf(sim.time - _last_t - dt) > dt * 0.5:  # first, or the train was put somewhere
		_prime()
	else:
		_beats(dt)
		_clacks(dt)
		for ev: Dictionary in events:
			_clank(ev)
		_bell_strikes(sim.time)
	_valve_tick(dt)
	_last_t = sim.time
	if sim.time - _bus_t > BUS_EVERY and Engine.is_in_physics_frame():  # (its rays: World.space)
		_bus_t = sim.time
		_bus = _where_heard()
	Prof.stop(&"train_sound", t0)
	cost.tick_us = int(cost.get("tick_us", 0)) + Time.get_ticks_usec() - u
	cost.ticks = int(cost.get("ticks", 0)) + 1


var _last_t := 0.0


## Where things stand now, without a sound (the train was placed or the ears came).
func _prime() -> void:
	var sim := train.sim
	_quarter = _quarter_at(sim.truck_s(0, 0, 1.0))
	for a in _axles.size():
		_joint[a] = _joint_at(a, 1.0)
	_primed = true
	queue.clear()
	_bus_t = -INF


func _quarter_at(s: float) -> int:
	return int(floor(-s / (float(rig.driver_r) * PI * 0.5)))


func _joint_at(a: int, frac: float) -> int:
	var ax := _axles[a]
	return int(floor((train.sim.car_front(int(ax.x), frac) - ax.y) / train.tuning.rail_length))


## The exhaust: the beats crossed in this tick (as EngineModel.roll counts them, from the engine's
## front truck), each when its quarter turn came, sub-tick.
func _beats(dt: float) -> void:
	var sim := train.sim
	var q := float(rig.driver_r) * PI * 0.5
	var a := -sim.truck_s(0, 0, 0.0) / q
	var b := -sim.truck_s(0, 0, 1.0) / q
	var now := int(floor(b))
	if now == _quarter or a == b:
		_quarter = now
		return
	var crossed: Array[int] = []
	if b < a:
		for m in range(int(floor(a)), now, -1):
			crossed.append(m)
	else:
		for m in range(int(floor(a)) + 1, now + 1):
			crossed.append(m)
	_quarter = now
	for m in crossed.slice(0, 8):
		var frac := clampf((a - m) / (a - b), 0.0, 1.0)
		_beat(m, sim.time - dt + frac * dt, frac)


func _beat(m: int, t: float, frac: float) -> void:
	_count("beats")
	var sim := train.sim
	if sim.steam < 0.03:
		return  # no steam, no exhaust (as the puffs)
	var engine := _car_frame(0, frac)
	var vel := -engine.basis.z * float(sim.vel[0])
	var speed := absf(sim.v)
	var bps := 4.0 * speed / (TAU * float(rig.driver_r))
	var size := "long" if bps < k.long_below else ("short" if bps > k.short_above else "mid")
	var beat := posmod(m, 4)
	var id := StringName("train_chuff_%s_%d" % [size, beat % 2])
	var db := k.chuff_db + linear_to_db(lerpf(k.chuff_floor, 1.0, clampf((sim.steam - 0.03) / 0.97, 0.0, 1.0)))
	db += k.chuff_speed_db * clampf(speed / k.full_speed, 0.0, 1.0) + float(k.beat_db[beat])
	db += {"long": 0.0, "mid": k.mid_db, "short": k.short_db}[size]
	_shot(id, engine * _v3(rig.stack), vel, t, db, float(k.beat_pitch[beat]), k.chuff_unit, k.chuff_max_db, &"exhaust")
	if speed < EngineModel.COCKS_BELOW:
		var cocks: Array = rig.cylinder_cocks
		var at := engine * ((_v3(cocks[0]) + _v3(cocks[1])) * 0.5)
		_shot(&"train_cocks", at, vel, t, k.cocks_db + linear_to_db(clampf(sim.steam, 0.05, 1.0)),
			1.0 + 0.04 * (beat - 1.5), k.cocks_unit, k.cocks_db + 3.0, &"exhaust")


## The rail joints: each axle past a joint in this tick.
func _clacks(dt: float) -> void:
	var sim := train.sim
	var rail := train.tuning.rail_length
	for a in _axles.size():
		var j := _joint_at(a, 1.0)
		if j == _joint[a]:
			continue
		var before := _joint[a]
		_joint[a] = j
		var ax := _axles[a]
		var car := int(ax.x)
		var speed := absf(float(sim.vel[car]))
		if speed < k.clack_from:
			continue
		var s0 := sim.car_front(car, 0.0) - ax.y
		var s1 := sim.car_front(car, 1.0) - ax.y
		var joint := float(maxi(j, before)) * rail  # the joint crossed (either way)
		var frac := clampf((joint - s0) / (s1 - s0), 0.0, 1.0) if s1 != s0 else 1.0
		_count("clacks")
		var first := _first_axle(car)
		var engine: bool = sim.cars[car].kind == &"engine" and a > first and a <= first + 4  # the drivers
		var db := k.clack_db + linear_to_db(pow(clampf(speed / k.full_speed, 0.01, 1.2), k.clack_power))
		var pitch := 0.94 + 0.12 * fposmod(float(j) * 0.618 + a * 0.37, 1.0)
		if engine:
			db += k.driver_db
			pitch *= k.driver_pitch
		var f := train.track.global_transform * train.track.transform_at(joint)
		var vel := -f.basis.z * float(sim.vel[car])
		var id := StringName("train_clack_%d" % ((a + j) % 3))
		_shot(id, f.origin, vel, sim.time - dt + frac * dt, db, pitch, k.clack_unit, k.clack_max_db, &"clack")


func _first_axle(car: int) -> int:
	for a in _axles.size():
		if int(_axles[a].x) == car:
			return a
	return 0


## A coupler's slack running out or bunching (TrainSim's event), at the coupler.
func _clank(ev: Dictionary) -> void:
	_count("couplers")
	var sim := train.sim
	var hard: bool = ev.bang
	var speed := float(ev.speed)
	var db := (k.bang_db if hard else k.bang_db + k.bump_db) + linear_to_db(clampf(speed / k.bang_full, 0.08, 1.4))
	var f := train.track.global_transform * train.track.transform_at(float(ev.s))
	var at := f * Vector3(0.0, 0.75, 0.0)
	var j := int(ev.coupler)
	var vel := -f.basis.z * float(sim.vel[j])
	_shot(&"train_bang" if hard else &"train_bump", at, vel, float(ev.t), db, 0.92 + 0.05 * (j % 4), k.bang_unit,
		k.bang_max_db, &"clank")


## The bell: a strike every bell_period while it's rung (alternately a little softer and later: the
## clapper either side).
func _bell_strikes(now: float) -> void:
	if not bell:
		return
	while _bell_next <= now:
		var engine := _car_frame(0, 1.0 - (now - _bell_next) * Engine.physics_ticks_per_second)
		var vel := -engine.basis.z * float(train.sim.vel[0])
		var side := _bell_n % 2
		_shot(&"train_bell", engine * _v3(rig.bell), vel, _bell_next, k.bell_db - 1.5 * side, 1.0 - 0.006 * side,
			k.bell_unit, k.bell_db + 4.0, &"bell")
		_count("bell")
		_bell_n += 1
		_bell_next += k.bell_period * (1.04 if side else 0.96)


## The train was put somewhere: start again from where it is, without a sound for the jump.
func reset() -> void:
	_primed = false
	queue.clear()


## Ring the bell (or stop).
func ring(yes: bool) -> void:
	if yes and not bell:
		_bell_next = train.sim.time
		_bell_n = 0
	bell = yes


## Blow the whistle: a pattern of "-" long and "o" short blasts ("--" off we go, "--o-" a crossing),
## from now.
func blow(pattern := "-") -> void:
	var t0 := train.sim.time
	for ch in pattern:
		var len := k.whistle_long if ch == "-" else (k.whistle_short if ch == "o" else 0.0)
		if len > 0.0:
			_blasts.append(Vector2(t0, t0 + len))
		t0 += len + k.whistle_gap


## Hold the whistle open (the cab's key) or let it go.
func whistle(held: bool) -> void:
	whistle_held = held


## Lift the safety valve now (for a film), for `valve_blow` s.
func lift_valve() -> void:
	_valve_until = train.sim.time + k.valve_blow


## The safety valve: standing with the regulator shut long enough, it lifts and blows a while.
func _valve_tick(dt: float) -> void:
	var sim := train.sim
	if absf(sim.v) < 0.05 and sim.regulator < 0.05:
		_standing += dt
	else:
		_standing = 0.0
	if _standing > k.valve_after and sim.time >= _valve_until:
		_valve_until = sim.time + k.valve_blow
		_standing = -k.valve_blow  # it seats, and the pressure takes as long again to come back


# --- One-shots ---------------------------------------------------------------------------------

## A one-shot heard from `at`, which happened at `t` (the sim's time) on a source moving at `vel`.
func _shot(id: StringName, at: Vector3, vel: Vector3, t: float, db: float, pitch: float, unit: float,
		max_db: float, pool: StringName) -> void:
	if not solo.is_empty() and not _kind(id) in solo:
		return
	var d := _ears_at.distance_to(at)
	if minf(linear_to_db(unit / maxf(d, 0.01)) + db, max_db) < k.cull_db:
		_count("culled")
		return
	queue.append({"id": id, "at": at, "t": t, "on": t + d / SPEED_OF_SOUND, "db": db,
		"pitch": pitch * doppler(at, vel, _ears_at, _ears_vel), "unit": unit, "max_db": max_db, "pool": pool})


## The drawn frame: start what's due (each skipped into its lead by how late it is), hold the loops.
func _process(_delta: float) -> void:
	if not on or train == null or not _warmed or _ears == null or not is_instance_valid(_ears):
		return
	var u := Time.get_ticks_usec()
	var t0 := Prof.start()
	# The game's time this frame stands for: the last tick and how far on from it the frame is.
	var now := train.sim.time + Engine.get_physics_interpolation_fraction() / Engine.physics_ticks_per_second
	var i := 0
	while i < queue.size():
		var q: Dictionary = queue[i]
		if float(q.on) <= now:
			_start(q, now)
			queue.remove_at(i)
		else:
			i += 1
	if queue.size() > 400:  # the ears far off and the train going: never let it grow
		queue = queue.slice(queue.size() - 400)
	_hold_loops()
	Prof.stop(&"train_sound", t0)
	cost.frame_us = int(cost.get("frame_us", 0)) + Time.get_ticks_usec() - u
	cost.frames = int(cost.get("frames", 0)) + 1


func _start(q: Dictionary, now: float) -> void:
	if not SynthSounds.made(q.id):
		_count("unready")  # still being made (the first seconds a train is heard)
		return
	var p := _take(q.pool)
	p.stop()
	p.stream = SynthSounds.get_sound(q.id)
	p.global_position = q.at
	p.unit_size = q.unit
	p.volume_db = q.db
	p.max_db = q.max_db
	p.pitch_scale = clampf(q.pitch, 0.5, 2.0)
	p.attenuation_filter_cutoff_hz = GameAudio.air_cutoff(_ears_at.distance_to(q.at))
	p.bus = _bus
	# The sound's lead is LEAD of silence; started late by (now - on), it's skipped that far in (in
	# its own time: pitched up, it runs faster), so it's heard at its moment.
	var late := maxf(now - float(q.on), 0.0)
	var from := minf(late * p.pitch_scale, TrainSynth.LEAD)
	p.play(from)
	_count("started")
	if log_started:
		started.append({"id": String(q.id), "t": q.t, "on": q.on, "now": now, "from": from, "pitch": p.pitch_scale})


## A free voice of the pool, else the one that started longest ago.
func _take(pool: StringName) -> AudioStreamPlayer3D:
	var list: Array = _pools[pool]
	for j in list.size():
		var p: AudioStreamPlayer3D = list[(int(_turn[pool]) + j) % list.size()]
		if not p.playing:
			_turn[pool] = (int(_turn[pool]) + j + 1) % list.size()
			return p
	var p: AudioStreamPlayer3D = list[int(_turn[pool])]
	_turn[pool] = (int(_turn[pool]) + 1) % list.size()
	_count("stolen")
	return p


# --- Loops -------------------------------------------------------------------------------------

func _hold_loops() -> void:
	var sim := train.sim
	var n := sim.cars.size()
	var frac := train.drawn_frac
	var engine := _car_frame(0, frac)
	var ev := -engine.basis.z * float(sim.vel[0])
	var speed := absf(sim.v)
	var full := clampf(speed / k.full_speed, 0.0, 1.2)
	var dt := get_process_delta_time()
	# Rolling: the engine and tender, and the train's middle.
	var mid := n / 2 + 1 if n > 2 else n - 1
	var roll_db := k.rumble_db + linear_to_db(maxf(pow(full, 1.3), 0.0001))
	var roll_pitch := 0.8 + 0.35 * full
	_loop(&"rumble_front", engine * Vector3(0, 0.6, 0), ev, roll_db, roll_pitch, k.rumble_unit)
	var back := _car_frame(mid, frac)
	_loop(&"rumble_back", back * Vector3(0, 0.6, 0), -back.basis.z * float(sim.vel[mid]), roll_db, roll_pitch * 0.93, k.rumble_unit)
	# The brakes: the front half's shoes and the back half's.
	for half in 2:
		var cars := range(0, n / 2) if half == 0 else range(n / 2, n)
		var brake := 0.0
		for c in cars:
			brake += float(sim.car_brake[c])
		brake /= maxf(cars.size(), 1)
		var at_car: int = cars[cars.size() / 2]
		var f := _car_frame(at_car, frac)
		var v := absf(float(sim.vel[at_car]))
		var cv := -f.basis.z * float(sim.vel[at_car])
		var squeal := brake * smoothstep(k.squeal_stop, k.squeal_stop * 4.0, v) * (1.0 - smoothstep(k.squeal_top, k.squeal_gone, v))
		var nm := "front" if half == 0 else "back"
		_loop(StringName("squeal_" + nm), f * Vector3(0, 0.4, 0), cv, k.squeal_db + linear_to_db(maxf(squeal, 0.0001)),
			1.0 + 0.05 * (half * 2 - 1) - 0.06 * (1.0 - clampf(v / k.squeal_top, 0.0, 1.0)), k.squeal_unit)
		var grind := brake * clampf(v / k.full_speed, 0.0, 1.0)
		_loop(StringName("grind_" + nm), f * Vector3(0, 0.4, 0), cv, k.grind_db + linear_to_db(maxf(grind, 0.0001)),
			0.85 + 0.3 * clampf(v / k.full_speed, 0.0, 1.0), k.squeal_unit)
	# The cocks open at a start, hissing between the beats; the engine simmering; the valve.
	var cocks: Array = rig.cylinder_cocks
	var open := sim.steam * (1.0 - smoothstep(EngineModel.COCKS_BELOW * 0.7, EngineModel.COCKS_BELOW, speed))
	_loop(&"cocks", engine * ((_v3(cocks[0]) + _v3(cocks[1])) * 0.5), ev,
		k.cocks_loop_db + linear_to_db(maxf(open, 0.0001)), 1.0, k.cocks_unit)
	var dome := engine * _v3(rig.whistle)
	_loop(&"simmer", engine * _v3(rig.firebox), ev, k.simmer_db, 1.0, k.simmer_unit)
	var lifting := train.sim.time < _valve_until
	_valve = move_toward(_valve, 1.0 if lifting else 0.0, dt / (0.3 if lifting else 1.2))
	_loop(&"safety", dome, ev, k.valve_db + linear_to_db(maxf(_valve * _valve, 0.0001)), 0.97 + 0.03 * _valve, k.valve_unit)
	# The whistle: the steam to it up quickly, away slower; its pitch with the steam.
	var t := sim.time
	var want := whistle_held
	while not _blasts.is_empty() and _blasts[0].y < t:
		_blasts.pop_front()
	if not _blasts.is_empty() and _blasts[0].x <= t:
		want = true
	_whistle = move_toward(_whistle, 1.0 if want else 0.0, dt / (k.whistle_attack if want else k.whistle_release))
	var w := _whistle * _whistle * (3.0 - 2.0 * _whistle)
	_loop(&"whistle", dome, ev, k.whistle_db + linear_to_db(maxf(w, 0.0001)), lerpf(k.whistle_low, 1.0, sqrt(w)),
		k.whistle_unit, k.whistle_max_db)


## A loop at `at`, moving at `vel`: on at `db` (off when it's next to nothing), pitched and placed.
func _loop(name: StringName, at: Vector3, vel: Vector3, db: float, pitch: float, unit: float, max_db := 6.0) -> void:
	var p: AudioStreamPlayer3D = _loops[name]
	if not solo.is_empty() and not String(name).get_slice("_", 0) in solo:
		db = -80.0
	if p.stream == null:
		if not SynthSounds.made(p.get_meta(&"id")):
			return
		p.stream = SynthSounds.get_sound(p.get_meta(&"id"))
	if db < -55.0:
		if p.playing:
			p.stop()
		return
	p.global_position = at
	p.unit_size = unit
	p.max_db = max_db
	p.volume_db = db
	p.pitch_scale = clampf(pitch * doppler(at, vel, _ears_at, _ears_vel), 0.3, 3.0)
	p.attenuation_filter_cutoff_hz = GameAudio.air_cutoff(_ears_at.distance_to(at))
	p.bus = _bus
	if not p.playing:
		# Each loop from its own place in it (so two of one kind are never in step).
		var len := (p.stream as AudioStreamWAV).data.size() / 2.0 / TrainSynth.RATE
		p.play(fposmod(float(hash(name)) * 0.001, len))


# --- Where and how it's heard ------------------------------------------------------------------

## The Doppler shift of a source at `at` moving at `vel` heard by ears at `ears` moving at `ears_vel`:
## f'/f = (c + the ears' speed toward it) / (c - its speed toward the ears).
static func doppler(at: Vector3, vel: Vector3, ears: Vector3, ears_vel: Vector3) -> float:
	var to_ears := ears - at
	if to_ears.length() < 0.01:
		return 1.0
	var dir := to_ears.normalized()
	var c := SPEED_OF_SOUND
	return clampf((c + ears_vel.dot(-dir)) / maxf(c - vel.dot(dir), 1.0), 0.5, 2.0)


## Car i's frame (its drawn body) `frac` through the tick, in the world.
func _car_frame(i: int, frac: float) -> Transform3D:
	return train.view.global_transform * train.view.car_transform(i, clampf(frac, 0.0, 1.0))


## The bus the train is heard on (GameAudio's: a wall between muffles it, inside it rings), worked
## out from the engine's middle a few times a second.
func _where_heard() -> StringName:
	var engine := _car_frame(0, 1.0)
	var at := engine * Vector3(0.0, 2.0, 0.0)
	var holder := train.track as Node3D
	var own: Array[RID] = []
	for b in train.view.solids:
		own.append(b.get_rid())
	var blocked := GameAudio.walled(holder, _ears_at, at, own)  # not through its own cars
	var is_inside := GameAudio.inside(holder, at)
	GameAudio._make_buses()
	return (&"RoomMuffled" if blocked else &"Room") if is_inside else (&"Muffled" if blocked else &"Master")


## A one-shot's kind (for `solo`): chuff, cocks, clack, clank (a bang or bump), bell.
static func _kind(id: StringName) -> String:
	var k := String(id).trim_prefix("train_").get_slice("_", 0)
	return "clank" if k == "bang" or k == "bump" else k


static func _v3(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func cost_reset() -> void:
	cost = {}
