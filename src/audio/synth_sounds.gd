class_name SynthSounds
## Sounds made in code until there are recorded ones: a black-powder gunshot with its echo off the
## hills, the hammer's two clicks, a dry-fire click, the cylinder's ratchet, the gate, brass.
## Mono 16-bit PCM, generated once and cached.

const RATE := 22050

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
			_: samples = _clicks(rng, [0.0], 2000.0, 0.3)
		var wav := _to_wav(_no_sub_bass(samples))
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
static func _no_sub_bass(s: PackedFloat32Array) -> PackedFloat32Array:
	var peak := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
	for q: float in [0.5412, 1.3066]:
		var w := TAU * LOW_CUT_HZ / RATE
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


static func _to_wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(s.size() * 2)
	for i in s.size():
		bytes.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	return wav
