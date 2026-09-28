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
			&"cock": samples = _clicks(rng, [0.0, 0.085], 3100.0, 0.5)
			&"dry_fire": samples = _clicks(rng, [0.0], 2400.0, 0.6)
			&"ratchet": samples = _clicks(rng, [0.0, 0.02, 0.04], 4200.0, 0.25)
			&"gate": samples = _clicks(rng, [0.0], 1800.0, 0.35)
			&"insert": samples = _clicks(rng, [0.0, 0.05], 1500.0, 0.3)
			&"eject": samples = _tink(rng)
			&"glass": samples = _glass(rng)
			_: samples = _clicks(rng, [0.0], 2000.0, 0.3)
		_cache[id] = _to_wav(samples)
	return _cache[id]


static func _gunshot(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 2.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		lp += (white - lp) * 0.25
		lp2 += (white - lp2) * 0.04
		var crack := white * exp(-t / 0.006) * 1.0
		var body := lp * exp(-t / 0.09) * 0.9
		var boom := sin(TAU * lerpf(70.0, 38.0, minf(t / 0.3, 1.0)) * t) * exp(-t / 0.16) * 0.7
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
