extends TestCase
## Sound checks (docs/briefs/automated-checks.md, item 6): every sound the game makes in code is
## heard, never clips, and carries next to nothing under 40 Hz (Sean's monitor speaker drops out on
## deep bass, and the screen with it), and the master bus still has its guard (the cut and the
## limiter) whatever piles up at once.

## Every sound SynthSounds makes.
const SOUNDS := [&"gunshot", &"shotgun", &"dynamite", &"fuse", &"match", &"ringing", &"break_open", &"close",
	&"cock", &"dry_fire", &"ratchet", &"gate", &"insert", &"eject", &"glass", &"flesh", &"zip", &"crack",
	&"ricochet", &"timber_crack", &"timber_crash", &"fire"]
## Share of a sound's energy allowed below 40 Hz.
const SUB_BASS_SHARE := 0.03
## Samples at full scale (or within a hair of it) allowed: none.
const CLIP := 32700
## A sound's loudest 50 ms must reach this (RMS, of full scale): it isn't silent.
const HEARD := 0.02


func _samples(id: StringName) -> PackedFloat32Array:
	var wav := SynthSounds.get_sound(id)
	var bytes := wav.data
	var out := PackedFloat32Array()
	out.resize(bytes.size() / 2)
	for i in out.size():
		out[i] = bytes.decode_s16(i * 2) / 32767.0
	return out


## The share of the energy below `hz`: the signal boxcar-averaged down to ~1.4 kHz (flat well past
## 40 Hz), then a DFT bin by bin below the line (Parseval: twice each positive bin over N·Σx²).
static func energy_below(s: PackedFloat32Array, rate: float, hz: float) -> float:
	var step := 16
	var d := PackedFloat32Array()
	d.resize(s.size() / step)
	for i in d.size():
		var acc := 0.0
		for j in step:
			acc += s[i * step + j]
		d[i] = acc / step
	var n := d.size()
	var r := rate / step
	var total := 0.0
	for v in d:
		total += v * v
	if total <= 0.0 or n < 4:
		return 0.0
	var low := 0.0
	var kmax := int(hz * n / r)
	for k in kmax + 1:
		var re := 0.0
		var im := 0.0
		var w := TAU * k / n
		for i in n:
			re += d[i] * cos(w * i)
			im -= d[i] * sin(w * i)
		low += (re * re + im * im) * (1.0 if k == 0 else 2.0)
	return low / (n * total)


func test_every_sound_is_heard_and_never_clips() -> void:
	for id: StringName in SOUNDS:
		var s := _samples(id)
		check(s.size() > SynthSounds.RATE * 0.01, "%s has samples (%d)" % [id, s.size()])
		var clipped := 0
		for v in s:
			if absf(v) * 32767.0 >= CLIP:
				clipped += 1
		check_eq(clipped, 0, "%s never reaches full scale" % id)
		var win := int(SynthSounds.RATE * 0.05)
		var loudest := 0.0
		var i := 0
		while i + win <= s.size():
			var acc := 0.0
			for j in win:
				acc += s[i + j] * s[i + j]
			loudest = maxf(loudest, sqrt(acc / win))
			i += win
		check(loudest >= HEARD, "%s is heard (loudest 50 ms at %.3f of full scale)" % [id, loudest])


func test_nothing_under_forty_hertz() -> void:
	var worst := ""
	var worst_share := 0.0
	for id: StringName in SOUNDS:
		var share := energy_below(_samples(id), SynthSounds.RATE, 40.0)
		if share > worst_share:
			worst_share = share
			worst = id
		check(share <= SUB_BASS_SHARE, "%s: %.1f%% of its energy under 40 Hz (allowed %.0f%%)" % [id, share * 100.0, SUB_BASS_SHARE * 100.0])
	print("    deepest: %s, %.2f%% under 40 Hz" % [worst, worst_share * 100.0])


func test_the_check_hears_sub_bass() -> void:
	# The measure itself: a 30 Hz tone is all under the line, a 200 Hz one none of it.
	var low := PackedFloat32Array()
	var high := PackedFloat32Array()
	for i in SynthSounds.RATE:
		low.append(0.5 * sin(TAU * 30.0 * i / SynthSounds.RATE))
		high.append(0.5 * sin(TAU * 200.0 * i / SynthSounds.RATE))
	check(energy_below(low, SynthSounds.RATE, 40.0) > 0.9, "30 Hz is under 40 Hz")
	check(energy_below(high, SynthSounds.RATE, 40.0) < 0.01, "200 Hz isn't")


func test_the_master_bus_cuts_the_bass_and_limits() -> void:
	var master := AudioServer.get_bus_index(&"Master")
	var cut := false
	var limit := false
	for i in AudioServer.get_bus_effect_count(master):
		var e := AudioServer.get_bus_effect(master, i)
		if e is AudioEffectHighPassFilter and (e as AudioEffectHighPassFilter).cutoff_hz >= 40.0:
			cut = true
		if e is AudioEffectHardLimiter and (e as AudioEffectHardLimiter).ceiling_db < 0.0:
			limit = true
	check(cut, "the master bus cuts below 40 Hz")
	check(limit, "and limits under full scale, so a pile of sounds at once can't clip")
