class_name SynthSounds
## Sounds made in code until there are recorded ones: a black-powder gunshot with its echo off the
## hills, the hammer's two clicks, a dry-fire click, the cylinder's ratchet, the gate, brass.
## Mono 16-bit PCM, generated once and cached. The sound lab's (docs/briefs/sound-lab.md: the
## reports and their roll) are made at HI_RATE, so their tops survive.

const RATE := 22050
const HI_RATE := 44100
## Made at HI_RATE.
const HI := [&"report", &"report_big", &"rolling", &"rolling_big", &"whirr", &"impact_wood", &"impact_dirt",
	&"impact_metal", &"impact_stone", &"glance_wood", &"glance_dirt", &"glance_metal", &"glance_stone"]

static var _cache := {}


static func get_sound(id: StringName) -> AudioStreamWAV:
	if not _cache.has(id):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var samples: PackedFloat32Array
		match id:
			&"gunshot": samples = _gunshot(rng)
			&"shotgun": samples = _gunshot(rng, 52.0, 0.22, 0.13)
			&"dynamite": samples = _blast(rng)
			&"fuse": samples = _fuse(rng)
			&"match": samples = _match(rng)
			&"ringing": samples = _ringing()
			&"break_open": samples = _clicks(rng, [0.0, 0.06], 900.0, 0.55)
			&"close": samples = _clicks(rng, [0.0], 1100.0, 0.7)
			&"cock": samples = _clicks(rng, [0.0, 0.085], 3100.0, 0.5)
			&"dry_fire": samples = _clicks(rng, [0.0], 2400.0, 0.6)
			&"ratchet": samples = _clicks(rng, [0.0, 0.02, 0.04], 4200.0, 0.25)
			&"gate": samples = _clicks(rng, [0.0], 1800.0, 0.35)
			&"insert": samples = _clicks(rng, [0.0, 0.05], 1500.0, 0.3)
			&"eject": samples = _tink(rng)
			&"glass": samples = _glass(rng)
			&"flesh": samples = _flesh(rng)
			&"zip": samples = _zip(rng)
			&"crack": samples = _crack(rng)
			&"ricochet": samples = _ricochet(rng)
			&"timber_crack": samples = _timber_crack(rng)
			&"timber_crash": samples = _timber_crash(rng)
			&"fire": samples = _fire(rng)
			&"splash": samples = _splash(rng)
			&"fill": samples = _fill(rng)
			&"steam": samples = _steam(rng)
			&"report": samples = _report(rng, false)
			&"report_big": samples = _report(rng, true)
			&"rolling": samples = _rolling(rng, false)
			&"rolling_big": samples = _rolling(rng, true)
			&"whirr": samples = _whirr(rng)
			&"impact_wood", &"impact_dirt", &"impact_metal", &"impact_stone":
				samples = _impact(rng, StringName(String(id).trim_prefix("impact_")))
			&"glance_wood", &"glance_dirt", &"glance_metal", &"glance_stone":
				samples = _glance(rng, StringName(String(id).trim_prefix("glance_")))
			_: samples = _clicks(rng, [0.0], 2000.0, 0.3)
		var rate := HI_RATE if id in HI else RATE
		var wav := _to_wav(_no_sub_bass(samples, rate), rate)
		if id == &"fire" or id == &"fuse" or id == &"ringing":
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_end = samples.size()
		_cache[id] = wav
	return _cache[id]


## A black-powder shot: `boom_hz` the low thump (a shotgun's is deeper), `boom_decay` and
## `body_decay` how long the thump and the roar last.
static func _gunshot(rng: RandomNumberGenerator, boom_hz := 70.0, boom_decay := 0.16, body_decay := 0.09) -> PackedFloat32Array:
	var n := int(RATE * 2.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var boom_phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.25
		lp2 += (white - lp2) * 0.04
		var crack := white * exp(-t / 0.006) * 1.0
		var body := lp * exp(-t / body_decay) * 0.9
		# The thump falls in pitch, but never below ~40 Hz (speakers can't play it; it only loads them).
		# The phase is summed from the pitch: sin(2π f(t) t) with a falling f sweeps below f itself
		# (its pitch is f + t f'), which took the shotgun's thump down to 28 Hz.
		boom_phase += TAU * maxf(lerpf(boom_hz, boom_hz * 0.54, minf(t / 0.3, 1.0)), 40.0) / RATE
		var boom := sin(boom_phase) * exp(-t / boom_decay) * 0.7
		var roll := lp2 * exp(-t / 0.7) * 0.5
		out[i] = crack + body + boom + roll
	# Echoes off the valley walls.
	for echo in [[0.42, 0.22], [0.95, 0.12], [1.5, 0.06]]:
		var d := int(echo[0] * RATE)
		var lp3 := 0.0
		for i in range(n - 1, d - 1, -1):
			lp3 += (out[i - d] - lp3) * 0.08
			out[i] += lp3 * echo[1]
	return _normalise(out, 0.95)


## A black-powder report as it leaves the muzzle, heard close (the sound lab, docs/briefs/sound-lab.md):
## the cap's click, the blast's shock (a Friedlander pulse: a sharp rise, a fall through to a long,
## shallow suck back; black powder's is longer and lower than smokeless powder's), the rough rush of
## the gas, and the deep push of a lot of slow-burning powder: more boom than crack. No echo here:
## the room, the fronts and the hills are where it's heard (GameAudio). `big` for the coach gun: a
## bigger bore and three times the powder, so a longer, deeper push. 44.1 kHz.
static func _report(rng: RandomNumberGenerator, big: bool) -> PackedFloat32Array:
	var n := int(HI_RATE * (0.9 if big else 0.7))
	var out := PackedFloat32Array()
	out.resize(n)
	var t_pos := 0.0016 if big else 0.0011  # the shock's positive phase
	var boom_hz := 64.0 if big else 86.0
	var boom_tau := 0.10 if big else 0.07
	var gas_tau := 0.028 if big else 0.018
	var body_tau := 0.15 if big else 0.10
	var lp := 0.0
	var slow := 0.0
	var deep := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / HI_RATE
		var white := rng.randf_range(-1.0, 1.0)
		var cap := white * exp(-t / 0.0005) * 0.3 if t < 0.004 else 0.0
		var s := cap
		var tt := t - 0.0025  # the charge goes a moment after the cap
		lp += (white - lp) * 0.35
		slow += (lp - slow) * 0.05
		deep += (white - deep) * 0.04  # ~300 Hz
		if tt >= 0.0:
			var shock := (1.0 - tt / t_pos) * exp(-1.6 * tt / t_pos)
			var gas := (lp - slow) * exp(-tt / gas_tau) * 1.1
			var body := deep * exp(-tt / body_tau) * minf(tt / 0.004, 1.0) * 3.2
			phase += TAU * lerpf(boom_hz, boom_hz * 0.62, minf(tt / 0.12, 1.0)) / HI_RATE
			var boom := sin(phase) * exp(-tt / boom_tau) * minf(tt / 0.002, 1.0) * 0.75
			s += shock * 0.9 + gas + body + boom
		out[i] = s
	return _normalise(out, 0.95)


## The report as it carries: a low, rolling boom that swells a moment and dies slow, and the hills
## sending it back, softer and duller each time and smeared (a slope of rock and scrub, not a
## mirror). Heard a little up close and most of all far off, where the report's blast has gone.
static func _rolling(rng: RandomNumberGenerator, big: bool) -> PackedFloat32Array:
	var n := int(HI_RATE * 3.4)
	var base := PackedFloat32Array()
	base.resize(n)
	var k := 0.032 if big else 0.045  # ~230 / 320 Hz
	var tau := 0.6 if big else 0.45
	var a := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / HI_RATE
		a += (rng.randf_range(-1.0, 1.0) - a) * k
		b += (a - b) * k * 2.0
		base[i] = b * minf(t / 0.03, 1.0) * exp(-t / tau)
	var out := base.duplicate()
	for echo: Array in [[0.45, 0.42], [1.0, 0.28], [1.6, 0.17], [2.3, 0.09]]:
		var d := int(float(echo[0]) * HI_RATE)
		var lp := 0.0
		for tap in 3:  # smeared over ~50 ms
			var dd := d + int(tap * 0.025 * HI_RATE)
			var g: float = float(echo[1]) * [0.6, 0.3, 0.15][tap]
			for i in range(dd, n):
				lp += (base[i - dd] - lp) * 0.3
				out[i] += lp * g
	return _normalise(out, 0.9)


## A ball slower than sound going by (a .45 Colt's 270-ish m/s): no snap, a short tearing whirr, the
## air it drags rising fast as it comes and falling in pitch as it goes (Doppler: a source at
## 0.8 of the speed of sound comes in at ~5x its pitch and leaves at ~0.55x).
static func _whirr(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(HI_RATE * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	var level_at := 0.05
	var lp := 0.0
	var bp := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / HI_RATE
		var white := rng.randf_range(-1.0, 1.0)
		var f := 3600.0 if t < level_at else lerpf(3600.0, 550.0, minf((t - level_at) / 0.08, 1.0))
		var k := clampf(TAU * f / HI_RATE, 0.01, 0.9)
		lp += (white - lp) * k
		bp += (lp - bp) * k * 0.5
		var band := lp - bp
		phase += TAU * f * 0.5 / HI_RATE
		var env := pow(t / level_at, 3.0) if t < level_at else exp(-(t - level_at) / 0.045)
		out[i] = (band * 1.4 + sin(phase) * 0.25) * env
	return _normalise(out, 0.85)


## What a ball does to what it strikes, by the surface (the sound lab): `wood` a dull thock (the
## board's few low modes) and the tick of splinters, `dirt` a soft thump and the hiss and patter of
## the dirt it throws, `metal` a clank and a ringing ping (a bar's modes: 1, 2.76, 5.40, 8.93 x
## the first), `stone` a hard click and chips.
static func _impact(rng: RandomNumberGenerator, surface: StringName) -> PackedFloat32Array:
	var n := int(HI_RATE * {&"metal": 0.7, &"dirt": 0.5}.get(surface, 0.3))
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var mid := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / HI_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.06
		mid += (white - mid) * 0.25
		var hp := white - prev
		prev = white
		var spray := mid - lp  # ~0.4–2 kHz: dirt thrown, not a hiss
		var s := 0.0
		match surface:
			&"wood":
				s = white * exp(-t / 0.0015) * 0.6
				for m: Array in [[190.0, 0.035, 0.7], [430.0, 0.025, 0.5], [780.0, 0.015, 0.35]]:
					s += sin(TAU * float(m[0]) * t) * exp(-t / float(m[1])) * float(m[2])
			&"dirt":
				s = lp * exp(-t / 0.02) * 3.0 + sin(TAU * 105.0 * t) * exp(-t / 0.03) * 0.6
				s += spray * exp(-maxf(t - 0.01, 0.0) / 0.12) * 0.5 * minf(t / 0.01, 1.0)
			&"metal":
				s = white * exp(-t / 0.001) * 0.7
				var f := 1150.0
				for m: Array in [[1.0, 0.35, 0.6], [2.76, 0.2, 0.4], [5.40, 0.12, 0.25], [8.93, 0.07, 0.15]]:
					s += sin(TAU * f * float(m[0]) * t) * exp(-t / float(m[1])) * float(m[2])
			_:  # stone
				s = hp * exp(-t / 0.002) * 0.9 + sin(TAU * 2300.0 * t) * exp(-t / 0.012) * 0.3
		out[i] = s
	# Bits thrown off: splinters, clods, chips, landing over the next moments.
	var bits: int = {&"wood": 5, &"dirt": 9, &"stone": 7}.get(surface, 0)
	for k in bits:
		var start := int(rng.randf_range(0.01, 0.6 if surface == &"dirt" else 0.25) * n)
		var level := rng.randf_range(0.05, 0.25)
		var soft := 0.0
		var dull := 0.15 if surface == &"dirt" else 0.8  # a clod is a dull tap, a chip a tick
		for i in range(start, mini(n, start + int(HI_RATE * 0.006))):
			soft += (rng.randf_range(-1.0, 1.0) - soft) * dull
			out[i] += soft * level * exp(-float(i - start) / (HI_RATE * 0.0015)) * (2.5 if surface == &"dirt" else 1.0)
	return _normalise(out, 0.85)


## A ball glancing off a surface: that surface's strike, then the whine of the ball tumbling away,
## falling in pitch and warbling as it turns over (lower and shorter off dirt, which takes more of it).
static func _glance(rng: RandomNumberGenerator, surface: StringName) -> PackedFloat32Array:
	var hit := _impact(rng, surface)
	var n := int(HI_RATE * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var top := 2400.0 if surface == &"dirt" else (3800.0 if surface == &"metal" else 3300.0)
	var low := 800.0 if surface == &"dirt" else 1300.0
	var tau := 0.12 if surface == &"dirt" else 0.2
	var phase := 0.0
	var warble_hz := rng.randf_range(28.0, 46.0)
	for i in n:
		var t := float(i) / HI_RATE
		phase += TAU * lerpf(top, low, pow(minf(t / 0.5, 1.0), 0.7)) / HI_RATE
		var warble := 0.6 + 0.4 * sin(TAU * warble_hz * t)
		out[i] = sin(phase) * warble * minf(t / 0.012, 1.0) * exp(-t / tau) * 0.55
		if i < hit.size():
			out[i] += hit[i] * (0.6 if surface == &"dirt" else 0.8)
	return _normalise(out, 0.85)


## Dynamite: a hard crack, a heavy thump and a long roll back off the hills.
static func _blast(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	var boom_phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.18
		lp2 += (white - lp2) * 0.03
		var crack := white * exp(-t / 0.012)
		var body := lp * exp(-t / 0.25) * 1.1
		boom_phase += TAU * lerpf(60.0, 45.0, minf(t / 0.4, 1.0)) / RATE  # summed: see _gunshot
		var boom := sin(boom_phase) * exp(-t / 0.35) * 0.9
		var roll := lp2 * exp(-t / 1.2) * 0.9
		out[i] = crack + body + boom + roll
	for echo in [[0.5, 0.3], [1.1, 0.18], [1.8, 0.1]]:
		var d := int(echo[0] * RATE)
		var lp3 := 0.0
		for i in range(n - 1, d - 1, -1):
			lp3 += (out[i - d] - lp3) * 0.06
			out[i] += lp3 * echo[1]
	return _normalise(out, 0.95)


## A burning fuse: a spitting hiss. Loops.
static func _fuse(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in n:
		var white := rng.randf_range(-1.0, 1.0)
		var hp := white - prev  # thin and high
		prev = white
		var spit := 1.0 + (2.5 if rng.randf() < 0.004 else 0.0)
		out[i] = hp * 0.3 * spit
	return _normalise(out, 0.5)


## A match struck: a scratch and a flare.
static func _match(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.5
		var scratch := lp * (1.0 if t < 0.12 else 0.0) * 0.8
		var flare := rng.randf_range(-1.0, 1.0) * exp(-(t - 0.12) / 0.15) * 0.5 if t >= 0.12 else 0.0
		out[i] = scratch + flare
	return _normalise(out, 0.6)


## Ringing ears: a high whine with a slow waver. Loops.
static func _ringing() -> PackedFloat32Array:
	var n := RATE * 2
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = sin(TAU * 3800.0 * t) * (0.8 + 0.2 * sin(TAU * 0.5 * t)) + sin(TAU * 3812.0 * t) * 0.3
	return _normalise(out, 0.5)


static func _clicks(rng: RandomNumberGenerator, times: Array, ring_hz: float, level: float) -> PackedFloat32Array:
	var n := int(RATE * (float(times.back()) + 0.08))
	var out := PackedFloat32Array()
	out.resize(n)
	for start in times:
		var s := int(float(start) * RATE)
		for i in range(s, mini(n, s + int(RATE * 0.06))):
			var t := float(i - s) / RATE
			out[i] += (rng.randf_range(-1, 1) * exp(-t / 0.0015) + sin(TAU * ring_hz * t) * exp(-t / 0.008) * 0.6) * level
	return out


static func _tink(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		out[i] = (sin(TAU * 4100.0 * t) * 0.5 + sin(TAU * 6300.0 * t) * 0.3) * exp(-t / 0.07) * 0.4
		out[i] += (sin(TAU * 3900.0 * (t - 0.18)) * 0.3) * exp(-maxf(t - 0.18, 0.0) / 0.05) * (1.0 if t > 0.18 else 0.0) * 0.4
	return out


## Breaking glass: a sharp crash, then pieces tinkling down.
## A bucket of water thrown and landing: a rushing slosh, then a slap and the patter of drops.
static func _splash(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.1)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.35
		lp2 += (lp - lp2) * 0.5
		var rush := (lp - lp2) * smoothstep(0.0, 0.08, t) * exp(-maxf(t - 0.08, 0.0) / 0.12)
		var slap := white * exp(-maxf(t - 0.28, 0.0) / 0.03) * (1.0 if t >= 0.28 else 0.0) * 0.8
		var patter := (white if rng.randf() < 0.02 else 0.0) * exp(-maxf(t - 0.3, 0.0) / 0.35) * (1.0 if t >= 0.3 else 0.0)
		out[i] = rush * 1.4 + slap + patter
	return _normalise(out, 0.7)


## Dipping a bucket in a trough: a gurgle of water running in.
static func _fill(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.2
		# Bubbles: short rising chirps every so often.
		phase += TAU * (300.0 + 900.0 * fmod(t * 7.0, 1.0)) / RATE
		var bubble := sin(phase) * exp(-fmod(t * 7.0, 1.0) * 6.0) * 0.35
		out[i] = (lp * 0.9 + bubble) * smoothstep(0.0, 0.1, t) * smoothstep(1.0, 0.7, t)
	return _normalise(out, 0.45)


## Water on hot timber: a hiss that dies away.
static func _steam(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		var hp := white - prev
		prev = white
		out[i] = hp * exp(-t / 0.45) * (0.7 + 0.3 * sin(t * 37.0))
	return _normalise(out, 0.5)


static func _glass(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var hp := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1, 1)
		hp = 0.6 * (hp + white - prev)
		prev = white
		out[i] = hp * exp(-t / 0.05) * 0.9
	for k in 26:
		var start := int(rng.randf_range(0.02, 1.0) * RATE)
		var f := rng.randf_range(3000.0, 7500.0)
		var level := rng.randf_range(0.1, 0.35)
		for i in range(start, mini(n, start + int(RATE * 0.12))):
			var t := float(i - start) / RATE
			out[i] += sin(TAU * f * t) * exp(-t / 0.025) * level
	return _normalise(out, 0.9)


## A ball striking a body: a dull, wet slap with a low thump under it.
static func _flesh(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.25)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (rng.randf_range(-1, 1) - lp) * 0.18
		out[i] = lp * exp(-t / 0.018) * 1.4 + sin(TAU * lerpf(140.0, 70.0, minf(t / 0.08, 1.0)) * t) * exp(-t / 0.05) * 0.8
	return _normalise(out, 0.8)


## The whiz of a tumbling ball (a ricochet) going by: tearing air coming fast, a tick as it's
## level with you, the pitch falling away behind. (A ball flying true snaps instead: `crack`.)
static func _zip(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.17)
	var out := PackedFloat32Array()
	out.resize(n)
	var bp := 0.0
	var prev := 0.0
	var level_at := 0.045  # level with you
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1, 1)
		bp = 0.75 * (bp + white - prev)
		prev = white
		# Swelling in fast, dying away slower.
		var env := pow(t / level_at, 2.0) if t < level_at else exp(-(t - level_at) / 0.035)
		phase += TAU * (2600.0 if t < level_at else lerpf(2600.0, 900.0, minf((t - level_at) / 0.06, 1.0))) / RATE
		var tick := exp(-absf(t - level_at) / 0.0015) * (1.0 if t >= level_at else 0.4)
		out[i] = (bp * 0.7 + sin(phase) * 0.45) * env + tick * rng.randf_range(0.6, 1.0) * 0.9
	return _normalise(out, 0.9)


## A ball passing close: the snap. A sharp N (an instant jump up, a straight fall through to as far
## below, an instant jump back), then its slap back off the ground a few milliseconds later and a
## short hiss.
static func _crack(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.09)
	var out := PackedFloat32Array()
	out.resize(n)
	var wave := 8  # samples (~0.36 ms)
	for echo: Array in [[0, 1.0], [int(RATE * 0.004), 0.45], [int(RATE * 0.011), 0.2]]:
		var start: int = echo[0]
		for k in wave:
			if start + k < n:
				out[start + k] += lerpf(1.0, -1.0, float(k) / float(wave - 1)) * float(echo[1])
	var lp := 0.0
	for i in range(wave, n):
		var t := float(i) / RATE
		lp += (rng.randf_range(-1, 1) - lp) * 0.6
		out[i] += lp * exp(-t / 0.012) * 0.25
	return _normalise(out, 0.95)


## A ball glancing off something: a hard spang where it strikes, then the whine of it tumbling
## away, falling in pitch and warbling as it turns over.
static func _ricochet(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var spang := rng.randf_range(-1, 1) * exp(-t / 0.004) + sin(TAU * 2900.0 * t) * exp(-t / 0.02) * 0.5
		var pitch := lerpf(3400.0, 1300.0, pow(minf(t / 0.45, 1.0), 0.7))
		phase += TAU * pitch / RATE
		var warble := 0.6 + 0.4 * sin(TAU * 38.0 * t)
		var whine := sin(phase) * warble * minf(t / 0.015, 1.0) * exp(-t / 0.18) * 0.7
		out[i] = spang + whine
	return _normalise(out, 0.85)


## Timber giving way: a few sharp splintering cracks and a woody groan under them.
static func _timber_crack(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	for k in 5:
		var start := int(rng.randf_range(0.0, 0.12 + k * 0.05) * RATE)
		var level := rng.randf_range(0.4, 1.0)
		for i in range(start, mini(n, start + int(RATE * 0.03))):
			var t := float(i - start) / RATE
			out[i] += rng.randf_range(-1, 1) * exp(-t / 0.004) * level
	for i in n:
		var t := float(i) / RATE
		out[i] += sin(TAU * (95.0 + 30.0 * sin(t * 9.0)) * t) * exp(-t / 0.25) * 0.35
	return _normalise(out, 0.85)


## Heavy timber hitting the ground: a deep thump, clatter of boards after it.
static func _timber_crash(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (rng.randf_range(-1, 1) - lp) * 0.12
		out[i] = lp * exp(-t / 0.12) * 1.2 + sin(TAU * lerpf(70.0, 45.0, minf(t / 0.2, 1.0)) * t) * exp(-t / 0.15)
	for k in 7:
		var start := int(rng.randf_range(0.05, 0.7) * RATE)
		var f := rng.randf_range(180.0, 420.0)
		for i in range(start, mini(n, start + int(RATE * 0.08))):
			var t := float(i - start) / RATE
			out[i] += (sin(TAU * f * t) * 0.5 + rng.randf_range(-0.5, 0.5)) * exp(-t / 0.02) * 0.4
	return _normalise(out, 0.9)


## A fire going: a low roar with crackles and pops in it. Loops.
static func _fire(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var white := rng.randf_range(-1, 1)
		lp += (white - lp) * 0.05
		lp2 += (lp - lp2) * 0.3
		var t := float(i) / RATE
		out[i] = lp2 * (0.8 + 0.2 * sin(TAU * 0.7 * t)) * 1.5
	for k in 70:
		var start := rng.randi_range(0, n - 400)
		var level := rng.randf_range(0.2, 0.9)
		for i in range(start, mini(n, start + int(RATE * 0.006))):
			var t := float(i - start) / RATE
			out[i] += rng.randf_range(-1, 1) * exp(-t / 0.0015) * level
	return _normalise(out, 0.6)


## Below this nothing is kept: a monitor's own speaker drops out on deep bass and blanks the
## screen with it (2026-09-29), and nothing small plays it anyway. tests/test_sounds.gd checks.
const LOW_CUT_HZ := 45.0


## A fourth-order Butterworth high-pass at LOW_CUT_HZ (two biquads, Q 0.5412 and 1.3066; RBJ's
## cookbook), run forward, the peak put back where the sound had it.
static func _no_sub_bass(s: PackedFloat32Array, rate := RATE) -> PackedFloat32Array:
	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	for q: float in [0.5412, 1.3066]:
		var w := TAU * LOW_CUT_HZ / rate
		var alpha := sin(w) / (2.0 * q)
		var c := cos(w)
		var a0 := 1.0 + alpha
		var b0 := (1.0 + c) * 0.5 / a0
		var b1 := -(1.0 + c) / a0
		var b2 := b0
		var a1 := -2.0 * c / a0
		var a2 := (1.0 - alpha) / a0
		var x1 := 0.0
		var x2 := 0.0
		var y1 := 0.0
		var y2 := 0.0
		for i in s.size():
			var x := s[i]
			var y := b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
			x2 = x1
			x1 = x
			y2 = y1
			y1 = y
			s[i] = y
	var now := 0.0001
	for v in s:
		now = maxf(now, absf(v))
	for i in s.size():
		s[i] *= peak / now
	return s


static func _normalise(s: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var m := 0.0001
	for v in s:
		m = maxf(m, absf(v))
	for i in s.size():
		s[i] = s[i] / m * peak
	return s


static func _to_wav(s: PackedFloat32Array, rate := RATE) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
