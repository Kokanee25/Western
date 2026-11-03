class_name TrainSynth
## The train's sounds made in code (train step 4, issue #571; TrainSound plays them). Since train
## sound 2 (#586) most are real recordings (`recording`, below: assets/audio/train/, cut from
## Wikimedia Commons, CREDITS.md) and these are the fallback, the before (`-- --train-synth`) and
## the brakes' squeal and grind, which no recording had. SynthSounds makes and caches them
## (`train_*` ids come here); the ideas, not code, are from the usual sources:
## noise through resonant filters for the exhaust and the hiss (R. Bristow-Johnson's biquads),
## decaying partials for struck iron and the bell (modal synthesis; a bell's hum, prime, tierce,
## quint and nominal), three detuned pipes for a chime whistle.
##
## One-shots start with LEAD seconds of silence: TrainSound starts each that much early and skips
## into it by how late it is, so a beat lands on its own moment, not on the drawn frame's.
## Loops are made seamless (the tones whole cycles, the noise crossfaded over the seam).

const RATE := 44100
## The silence before every one-shot, s (more than the longest a drawn frame can be: two ticks).
const LEAD := 0.05

## Looping (TrainSound holds them on and sets their level).
const LOOPS := [&"train_rumble", &"train_squeal", &"train_grind", &"train_cocks_loop", &"train_simmer",
	&"train_safety", &"train_whistle"]
const SHOTS := [&"train_chuff_long_0", &"train_chuff_long_1", &"train_chuff_mid_0", &"train_chuff_mid_1",
	&"train_chuff_short_0", &"train_chuff_short_1", &"train_cocks", &"train_clack_0", &"train_clack_1",
	&"train_clack_2", &"train_bang", &"train_bump", &"train_bell"]
const IDS := SHOTS + LOOPS
## The order they're made in when a train is first heard (~5 s on one 2.1 GHz core): what a standing
## engine and a start need first.
const WARM := [&"train_simmer", &"train_bell", &"train_whistle", &"train_chuff_long_0", &"train_chuff_long_1",
	&"train_cocks", &"train_cocks_loop", &"train_bang", &"train_bump", &"train_clack_0", &"train_clack_1",
	&"train_clack_2", &"train_rumble", &"train_chuff_mid_0", &"train_chuff_mid_1", &"train_chuff_short_0",
	&"train_chuff_short_1", &"train_grind", &"train_squeal", &"train_safety"]


## Recordings (train sound 2, #586): a train sound cut from a real recording by
## experiments/train_lab/recordings.py (sources and licences in CREDITS.md) is used in place of the
## synthesis when its file is there; what has none stays synthesised. Mono, 16-bit, at RATE, with
## the same rules as the synthesis: a one-shot led by LEAD of silence, a loop seamless.
const RECORDED := "res://assets/audio/train/%s.wav"
## Off with `-- --train-synth`: every train sound synthesised (step 4's, the before).
static var use_recordings := not OS.get_cmdline_user_args().has("--train-synth")


## The recording for `id` as the game plays it (its loop set), or null (none, or off).
static func recording(id: StringName) -> AudioStreamWAV:
	var path := RECORDED % id
	if not use_recordings or not ResourceLoader.exists(path):
		return null
	var wav := load(path) as AudioStreamWAV
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS or wav.stereo or wav.mix_rate != RATE:
		push_warning("TrainSynth: %s isn't mono 16-bit PCM at %d Hz (its import), synthesised instead" % [path, RATE])
		return null
	wav = wav.duplicate()
	if is_loop(id):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	else:
		wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return wav


static func is_train(id: StringName) -> bool:
	return String(id).begins_with("train_")


static func is_loop(id: StringName) -> bool:
	return id in LOOPS


## The samples (mono, -1..1, at RATE) of a train sound.
static func make(id: StringName, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var s := String(id)
	if s.begins_with("train_chuff_"):
		var parts := s.trim_prefix("train_chuff_").split("_")
		var tau: float = {"long": 0.2, "mid": 0.1, "short": 0.045}[parts[0]]
		return _chuff(rng, tau, int(parts[1]))
	if s.begins_with("train_clack_"):
		return _clack(rng, int(s.trim_prefix("train_clack_")))
	match id:
		&"train_cocks": return _cocks(rng)
		&"train_bang": return _bang(rng, true)
		&"train_bump": return _bang(rng, false)
		&"train_bell": return _bell(rng)
		&"train_rumble": return _rumble(rng)
		&"train_squeal": return _squeal(rng)
		&"train_grind": return _grind(rng)
		&"train_cocks_loop": return _hiss_loop(rng, 1500.0, 3300.0, 2.0)
		&"train_simmer": return _simmer(rng)
		&"train_safety": return _safety(rng)
		&"train_whistle": return _whistle(rng)
	return PackedFloat32Array([0.0])


## Silence before a one-shot (after it's made and cleaned).
static func lead(s: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(RATE * LEAD))
	out.append_array(s)
	return out


# --- The sounds ----------------------------------------------------------------------------------

## One exhaust beat up the stack: a burst of steam through the blast pipe and out of the chimney. A
## deep "whoof" (noise round the stack's low resonance), the steam's hiss over it, and a thump of
## the gas column; `tau` how long it lasts (a start's beat is long and heavy, at speed short).
static func _chuff(rng: RandomNumberGenerator, tau: float, variant: int) -> PackedFloat32Array:
	var n := int(RATE * (0.06 + tau * 5.5))
	var body := _noise(rng, n)
	var centre := 210.0 * (1.0 + 0.14 * variant)
	_biquad(body, &"bp", centre, 0.7)
	_biquad(body, &"lp", 1300.0, 0.7)
	_rms_one(body)
	var hiss := _noise(rng, n)
	_biquad(hiss, &"hp", 1700.0, 0.7)
	_biquad(hiss, &"lp", 7000.0, 0.7)
	_rms_one(hiss)
	var rough := _wander(rng, n, 35.0)  # the gas tearing through: the body's level wavers
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var att := 1.0 - exp(-t / 0.005)
		var f := 58.0 + 40.0 * exp(-t / 0.05)
		phase += TAU * f / RATE
		var thump := sin(phase) * att * exp(-t / (0.03 + tau * 0.35))
		out[i] = body[i] * att * exp(-t / tau) * (1.0 + 0.35 * rough[i]) \
			+ 0.32 * hiss[i] * att * exp(-t / (tau * 1.5)) + 0.9 * thump
	return _fade_out(_normalise(out, 0.85), 0.02)


## Steam out of the cylinder cocks: a sharp hiss that dies over a third of a second.
static func _cocks(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.2)
	var out := _noise(rng, n)
	_biquad(out, &"hp", 1300.0, 0.7)
	_biquad(out, &"bp", 3400.0, 0.6)
	for i in n:
		var t := float(i) / RATE
		out[i] *= (1.0 - exp(-t / 0.012)) * exp(-t / 0.28)
	return _fade_out(_normalise(out, 0.6), 0.03)


## A wheel over a rail joint: the tread dropping onto the next rail's end. A hard tick, the rail's
## ring (a few iron partials, short) and the thud of the wheel's weight.
static func _clack(rng: RandomNumberGenerator, variant: int) -> PackedFloat32Array:
	var n := int(RATE * 0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	var k := 1.0 + 0.06 * (variant - 1)
	var modes := [[540.0, 0.055, 0.6], [1190.0, 0.04, 0.5], [2330.0, 0.026, 0.35], [3870.0, 0.016, 0.22]]
	var ph := []
	for m in modes:
		ph.append(rng.randf() * TAU)
	var thud := _noise(rng, n)
	_biquad(thud, &"lp", 260.0, 0.8)
	_rms_one(thud)
	var tick := _noise(rng, n)
	_biquad(tick, &"hp", 2500.0, 0.7)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for j in modes.size():
			var m: Array = modes[j]
			v += float(m[2]) * sin(TAU * float(m[0]) * k * t + float(ph[j])) * exp(-t / float(m[1]))
		v += 0.55 * thud[i] * exp(-t / 0.018) + 0.8 * sin(TAU * 105.0 * k * t) * exp(-t / 0.025)
		v += 0.7 * tick[i] * exp(-t / 0.0025)
		out[i] = v * (1.0 - exp(-t / 0.0004))
	return _fade_out(_normalise(out, 0.8), 0.02)


## A coupler's slack running out or bunching: link and pin, iron on iron, and the car's frame
## answering. `hard`: a bang (a crack, ringing iron, the pin rattling after); else a bump (dull).
static func _bang(rng: RandomNumberGenerator, hard: bool) -> PackedFloat32Array:
	var n := int(RATE * (1.0 if hard else 0.6))
	var out := PackedFloat32Array()
	out.resize(n)
	var modes := [[310.0, 0.32, 0.5], [318.0, 0.3, 0.3], [744.0, 0.26, 0.55], [1268.0, 0.18, 0.45],
		[1985.0, 0.12, 0.32], [2870.0, 0.085, 0.24], [4120.0, 0.05, 0.14]]
	var dull := 1.0 if hard else 0.35
	var ph := []
	for m in modes:
		ph.append(rng.randf() * TAU)
	var thud := _noise(rng, n)
	_biquad(thud, &"lp", 320.0, 0.8)
	_rms_one(thud)
	var crack := _noise(rng, n)
	_biquad(crack, &"hp", 2000.0, 0.7)
	var rattle := [0.034, 0.061, 0.09] if hard else []
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for j in modes.size():
			var m: Array = modes[j]
			var a := float(m[2]) * (dull if float(m[0]) > 600.0 else 1.0)
			v += a * sin(TAU * float(m[0]) * t + float(ph[j])) * exp(-t / (float(m[1]) * (1.0 if hard else 0.6)))
		phase += TAU * (55.0 + 45.0 * exp(-t / 0.06)) / RATE
		v += 1.1 * sin(phase) * exp(-t / 0.08) + 0.6 * thud[i] * exp(-t / 0.035)
		if hard:
			v += 0.9 * crack[i] * exp(-t / 0.004)
			for r: float in rattle:
				if t >= r:
					v += 0.22 * sin(TAU * 1830.0 * (t - r)) * exp(-(t - r) / 0.012)
		out[i] = v * (1.0 - exp(-t / 0.0005))
	return _fade_out(_normalise(out, 0.85 if hard else 0.6), 0.05)


## The locomotive bell struck once: a cast-brass bell's partials (hum, prime, tierce, quint,
## nominal and above), each a close pair that beats, the high ones short, the hum long; the
## clapper's knock at the start.
static func _bell(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var f0 := 452.0
	var parts := [[0.5, 0.3, 3.0], [1.0, 0.55, 2.2], [1.2, 0.45, 1.7], [1.5, 0.3, 1.3], [2.0, 0.75, 1.1],
		[2.51, 0.28, 0.7], [2.66, 0.22, 0.55], [3.01, 0.18, 0.42], [4.16, 0.12, 0.28], [5.43, 0.07, 0.18]]
	var ph := []
	for p in parts:
		ph.append(rng.randf() * TAU)
	var knock := _noise(rng, n)
	_biquad(knock, &"bp", 1800.0, 1.2)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for j in parts.size():
			var p: Array = parts[j]
			var f := f0 * float(p[0])
			var e := float(p[1]) * exp(-t / float(p[2]))
			v += e * (sin(TAU * f * t + float(ph[j])) + 0.6 * sin(TAU * (f + 0.7) * t))
		v += 0.8 * knock[i] * exp(-t / 0.006)
		out[i] = v * (1.0 - exp(-t / 0.0006))
	return _fade_out(_normalise(out, 0.8), 0.2)


## The wheels rolling on the rails between the joints: a low roar that wavers.
static func _rumble(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 4.0)
	var x := int(RATE * 0.25)
	var out := _noise(rng, n + x)
	_biquad(out, &"bp", 130.0, 0.9)
	_biquad(out, &"lp", 500.0, 0.7)
	_rms_one(out)
	var hi := _noise(rng, n + x)
	_biquad(hi, &"bp", 1100.0, 2.0)
	_rms_one(hi)
	var sway := _wander(rng, n + x, 3.0)
	for i in n + x:
		out[i] = out[i] * (1.0 + 0.3 * sway[i]) + 0.12 * hi[i]
	return _normalise(_seam(out, n, x), 0.7)


## Cast-iron shoes squealing on the treads as a train comes to a stand: a high whine that wanders
## in pitch and comes and goes, over a grind.
static func _squeal(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.0)
	var x := int(RATE * 0.3)
	var drift := _wander(rng, n + x, 0.9)
	var flutter := _wander(rng, n + x, 9.0)
	var gate := _wander(rng, n + x, 0.7)
	var grind := _noise(rng, n + x)
	_biquad(grind, &"bp", 1900.0, 1.5)
	_rms_one(grind)
	var out := PackedFloat32Array()
	out.resize(n + x)
	var phase := 0.0
	for i in n + x:
		var f := 2950.0 * (1.0 + 0.018 * drift[i])
		phase += TAU * f / RATE
		var on := clampf(0.55 + 0.6 * gate[i], 0.0, 1.0)
		var a := on * (0.75 + 0.25 * flutter[i])
		out[i] = a * (sin(phase) + 0.3 * sin(phase * 1.5 + 0.4) + 0.12 * sin(phase * 2.0)) + 0.18 * grind[i]
	return _normalise(_seam(out, n, x), 0.6)


## The shoes grinding on the treads at speed.
static func _grind(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 2.5)
	var x := int(RATE * 0.25)
	var a := _noise(rng, n + x)
	_biquad(a, &"bp", 900.0, 0.7)
	_rms_one(a)
	var b := _noise(rng, n + x)
	_biquad(b, &"bp", 2600.0, 1.4)
	_rms_one(b)
	var rough := _wander(rng, n + x, 14.0)
	for i in n + x:
		a[i] = (a[i] + 0.5 * b[i]) * (1.0 + 0.3 * rough[i])
	return _normalise(_seam(a, n, x), 0.5)


## A steady hiss (the cocks open between beats): noise high-passed at `hp`, peaked at `peak`.
static func _hiss_loop(rng: RandomNumberGenerator, hp: float, peak: float, secs: float) -> PackedFloat32Array:
	var n := int(RATE * secs)
	var x := int(RATE * 0.2)
	var out := _noise(rng, n + x)
	_biquad(out, &"hp", hp, 0.7)
	_biquad(out, &"bp", peak, 0.6)
	_rms_one(out)
	var sway := _wander(rng, n + x, 5.0)
	for i in n + x:
		out[i] *= 1.0 + 0.2 * sway[i]
	return _normalise(_seam(out, n, x), 0.5)


## A standing engine: the fire's low roar under the blower, a little steam.
static func _simmer(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.0)
	var x := int(RATE * 0.25)
	var fire := _noise(rng, n + x)
	_biquad(fire, &"bp", 180.0, 0.8)
	_biquad(fire, &"lp", 700.0, 0.7)
	_rms_one(fire)
	var steam := _noise(rng, n + x)
	_biquad(steam, &"hp", 2400.0, 0.7)
	_biquad(steam, &"lp", 8000.0, 0.7)
	_rms_one(steam)
	var flick := _wander(rng, n + x, 6.0)
	for i in n + x:
		fire[i] = fire[i] * (1.0 + 0.3 * flick[i]) + 0.35 * steam[i]
	return _normalise(_seam(fire, n, x), 0.5)


## The safety valve blowing off: a loud, rough roar of steam with a whistle in it.
static func _safety(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 3.0)
	var x := int(RATE * 0.25)
	var roar := _noise(rng, n + x)
	_biquad(roar, &"bp", 2500.0, 0.7)
	_rms_one(roar)
	var top := _noise(rng, n + x)
	_biquad(top, &"hp", 5000.0, 0.7)
	_rms_one(top)
	var low := _noise(rng, n + x)
	_biquad(low, &"bp", 400.0, 0.8)
	_rms_one(low)
	var pipe := _noise(rng, n + x)
	_biquad(pipe, &"bp", 1150.0, 25.0)
	_rms_one(pipe)
	var sway := _wander(rng, n + x, 4.0)
	for i in n + x:
		roar[i] = (roar[i] + 0.35 * top[i] + 0.5 * low[i] + 0.25 * pipe[i]) * (1.0 + 0.15 * sway[i])
	return _normalise(_seam(roar, n, x), 0.6)


## A three-chime steam whistle: three pipes of a minor chord (the American "hooter"), each a
## fundamental and a few harmonics, a breath of noise round each, a slight waver. Every tone is
## a whole number of cycles in the loop, so it loops clean.
static func _whistle(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var secs := 2.0
	var n := int(RATE * secs)
	var x := int(RATE * 0.2)
	var pipes := [440.0, 523.0, 659.0]
	var harm := [1.0, 0.32, 0.16, 0.07]
	var breath := []
	for f: float in pipes:
		var b := _noise(rng, n + x)
		_biquad(b, &"bp", f, 14.0)
		_rms_one(b)
		breath.append(b)
	var air := _noise(rng, n + x)
	_biquad(air, &"hp", 3000.0, 0.7)
	_rms_one(air)
	var flutter := _wander(rng, n + x, 7.0)
	var out := PackedFloat32Array()
	out.resize(n + x)
	for i in n + x:
		var t := float(i % n) / RATE  # the tones repeat exactly; the noise is crossfaded at the seam
		var vib := 0.0018 * sin(TAU * 5.0 * t)  # whole cycles in the loop
		var v := 0.0
		for p in pipes.size():
			var f: float = pipes[p]
			var ph := TAU * f * t - (f * 0.0018 / 5.0) * cos(TAU * 5.0 * t)  # the waver's phase, integrated
			for h in harm.size():
				v += float(harm[h]) * sin(ph * (h + 1) + p)
			v += 0.22 * (breath[p] as PackedFloat32Array)[i]
		out[i] = v * (1.0 + 0.06 * flutter[i] + vib) + 0.05 * air[i]
	return _normalise(_seam(out, n, x, false), 0.7)


# --- Helpers -------------------------------------------------------------------------------------

static func _noise(rng: RandomNumberGenerator, n: int) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		s[i] = rng.randf_range(-1.0, 1.0)
	return s


## A smooth random curve in -1..1 changing about `hz` times a second (cosine between random points).
static func _wander(rng: RandomNumberGenerator, n: int, hz: float) -> PackedFloat32Array:
	var step := maxi(1, int(RATE / hz))
	var pts := PackedFloat32Array()
	for k in n / step + 2:
		pts.append(rng.randf_range(-1.0, 1.0))
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var k := i / step
		var f := float(i % step) / step
		var w := 0.5 - 0.5 * cos(PI * f)
		s[i] = lerpf(pts[k], pts[k + 1], w)
	return s


## R. Bristow-Johnson's biquads (the Audio EQ Cookbook): low-pass, high-pass, band-pass (0 dB at
## its peak), run once forward, in place.
static func _biquad(s: PackedFloat32Array, kind: StringName, f: float, q: float) -> void:
	var w := TAU * f / RATE
	var c := cos(w)
	var alpha := sin(w) / (2.0 * q)
	var b0: float
	var b1: float
	var b2: float
	match kind:
		&"lp":
			b0 = (1.0 - c) * 0.5
			b1 = 1.0 - c
			b2 = b0
		&"hp":
			b0 = (1.0 + c) * 0.5
			b1 = -(1.0 + c)
			b2 = b0
		_:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
	var a0 := 1.0 + alpha
	b0 /= a0
	b1 /= a0
	b2 /= a0
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


## Scaled to an RMS of one (so mixed parts keep the shares they're given).
static func _rms_one(s: PackedFloat32Array) -> void:
	var acc := 0.0
	for v in s:
		acc += v * v
	var r := sqrt(acc / maxf(s.size(), 1)) + 1e-9
	for i in s.size():
		s[i] /= r


static func _normalise(s: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var m := 0.0001
	for v in s:
		m = maxf(m, absf(v))
	for i in s.size():
		s[i] = s[i] / m * peak
	return s


## The last `secs` faded to nothing (no click where a one-shot is cut off).
static func _fade_out(s: PackedFloat32Array, secs: float) -> PackedFloat32Array:
	var k := mini(int(RATE * secs), s.size())
	for j in k:
		s[s.size() - 1 - j] *= float(j) / k
	return s


## `n` samples that loop: the `x` made past the end crossfaded (equal power) over the start.
## `power` false: a straight crossfade (for what's the same either side of the seam, the whistle's
## tones, which an equal-power one would swell).
static func _seam(s: PackedFloat32Array, n: int, x: int, power := true) -> PackedFloat32Array:
	for i in x:
		var w := float(i) / x
		if power:
			s[i] = s[i] * sin(w * PI * 0.5) + s[n + i] * cos(w * PI * 0.5)
		else:
			s[i] = s[i] * w + s[n + i] * (1.0 - w)
	s.resize(n)
	return s
