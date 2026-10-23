extends TestCase
## FaceSpeech: a talking man's mouth saying his lines (src/bodies/face_speech.gd). Each test steps
## him by hand, a fixed step at a time.

const MAN := &"bold_cowboy_talking"
const MASKED := &"hothead_lyle_s2_talking"
const DT := 1.0 / 60.0


func _man(id: StringName, model := MAN, masked := false) -> HumanBody:
	var him := HumanBody.new()
	him.body_model = model
	him.person_id = id
	him.masked = masked
	add_child(him)
	return him


func _speech(him: HumanBody) -> FaceSpeech:
	var s := him.get_node(^"FaceSpeech") as FaceSpeech
	s.auto = false
	return s


func _steps(s: FaceSpeech, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		s.step(DT)


func _shape(mi: MeshInstance3D, name: StringName) -> float:
	var k := mi.find_blend_shape_by_name(name)
	return mi.get_blend_shape_value(k) if k >= 0 else -1.0


func _head(him: HumanBody) -> MeshInstance3D:
	return him.skin_meshes.get("head/head") as MeshInstance3D


## The middle of the n-th sound of class `cls` in the plan (seconds from its start).
func _when(p: Dictionary, cls: StringName, nth := 0) -> float:
	var hits := []
	for s: Array in p.segs:
		if s[0] == cls:
			hits.append(float(s[1]) + float(s[2]) * 0.5)
	hits.sort()
	return hits[nth] if nth < hits.size() else -1.0


func test_a_talking_man_has_a_mouth_and_a_plain_one_doesnt() -> void:
	var him := _man(&"speech_talking")
	var plain := _man(&"speech_plain", &"outlaw")
	await physics_frames(2)
	var s := him.get_node_or_null(^"FaceSpeech") as FaceSpeech
	check(s != null and s.has_face(), "the talking man has a FaceSpeech on his face")
	check(plain.get_node_or_null(^"FaceSpeech") == null, "the plain man has none")
	him.queue_free()
	plain.queue_free()


func test_a_line_he_speaks_moves_his_mouth() -> void:
	var him := _man(&"speech_line")
	await physics_frames(2)
	var s := _speech(him)
	Events.spoke.emit(him, "Keep that iron where it is.")
	check(s.speaking(), "Events.spoke starts him talking")
	var most := 0.0
	var shapes := {}
	for i in int(1.0 / DT):
		s.step(DT)
		var m := s.mouth()
		for k: StringName in m:
			shapes[k] = maxf(float(shapes.get(k, 0.0)), m[k])
		most = maxf(most, m.aa + m.jaw_open)
	check(most > 0.4, "his mouth opens on the vowels (aa+jaw %.2f)" % most)
	check(shapes.mbp > 0.7 and shapes.ee > 0.3, "and closes and spreads with the line's sounds (%s)" % shapes)
	check(_shape(_head(him), &"aa") >= 0.0, "drawn on his head")
	# Another man's line doesn't move his mouth.
	var other := _man(&"speech_other", &"outlaw")
	await physics_frames(1)
	var quiet := _man(&"speech_quiet")
	await physics_frames(2)
	var q := _speech(quiet)
	Events.spoke.emit(other, "Hands where I can see 'em.")
	q.step(DT)
	check(not q.speaking(), "a line someone else says leaves him quiet")
	for n: Node in [him, other, quiet]:
		n.queue_free()


func test_mbp_closes_his_lips_fv_bites_oo_rounds() -> void:
	var him := _man(&"speech_lips")
	await physics_frames(2)
	var s := _speech(him)
	for c: Array in [["My hat!", &"m", &"mbp"], ["Fire!", &"f", &"fv"], ["Who knew?", &"uw", &"oo"],
			["Bring the buckets!", &"m", &"mbp"]]:
		s.hush()
		_steps(s, 0.5)
		var p := FaceSpeech.plan(c[0], s.tuning)
		var at := _when(p, c[1])
		s.say(c[0])
		_steps(s, at)
		var m := s.mouth()
		check(m[c[2]] > (0.6 if c[2] == &"oo" else 0.75), "\"%s\": %s at its %s (%.2f at %.2f s)" % [c[0], c[2], c[1], m[c[2]], at])
		if c[2] == &"mbp":
			check(m.jaw_open + m.aa + m.lips_apart < 0.2, "his lips shut, not open (%s)" % m)
			check(_shape(_head(him), &"mbp") > 0.75, "on his head too")
	him.queue_free()


func test_the_shapes_stop_when_hes_done() -> void:
	var him := _man(&"speech_done")
	await physics_frames(2)
	var s := _speech(him)
	var secs := s.say("Whiskey. Leave the bottle.")
	check(secs > 1.0 and secs < 3.0, "a natural pace (%.2f s for five words)" % secs)
	_steps(s, secs * 0.5)
	check(s.speaking(), "talking halfway through")
	_steps(s, secs * 0.5 + 0.4)
	check(not s.speaking(), "done by the end")
	var head := _head(him)
	var all_rest := true
	for k: StringName in FaceSpeech.SHAPES:
		all_rest = all_rest and _shape(head, k) == 0.0 and s.mouth()[k] == 0.0
	check(all_rest, "every mouth shape back to exactly 0 (%s)" % s.mouth())
	him.queue_free()


func test_how_long_he_talks_is_how_long_the_line_shows() -> void:
	var short := FaceSpeech.plan("Smart.").seconds as float
	var long := FaceSpeech.plan("Put it on my tab. What tab? That's a good one.").seconds as float
	check(long > short * 3.0, "a long line takes longer (%.2f against %.2f s)" % [long, short])
	var tu: SpeechTuning = load("res://config/speech.tres")
	check_near(FaceSpeech.subtitle_seconds("Put it on my tab. What tab? That's a good one."), long + tu.subtitle_hold, 0.01,
			"the subtitle stays as long as he talks, and a little more")
	check(FaceSpeech.subtitle_seconds("Smart.") >= tu.subtitle_min, "a short one long enough to read")


func test_a_dead_man_stops_talking() -> void:
	var him := _man(&"speech_dead")
	await physics_frames(2)
	var s := _speech(him)
	s.say("I'm calling you out, mister! Out here!")
	_steps(s, 0.5)
	him.physiology.alive = false
	_steps(s, 0.3)
	check(not s.speaking(), "he stops mid-line when he dies")
	var m := s.mouth()
	var total := 0.0
	for k: StringName in m:
		total += m[k]
	check(total == 0.0, "his mouth at rest (%s)" % m)
	# A line for a dead man (whatever said it) moves nothing.
	Events.spoke.emit(him, "Hhhk— hhk—")
	_steps(s, 0.3)
	check(s.mouth().jaw_open == 0.0, "a dead man's mouth stays still")
	him.queue_free()


func test_the_dying_mans_choke_opens_and_catches() -> void:
	var him := _man(&"speech_choke")
	await physics_frames(2)
	var s := _speech(him)
	var p := FaceSpeech.plan("Hhhk— hhk—", s.tuning)
	s.say("Hhhk— hhk—")
	_steps(s, _when(p, &"gasp"))
	var gasp: float = s.mouth().jaw_open
	check(gasp > 0.3, "his jaw drops on the gasp (%.2f)" % gasp)
	_steps(s, _when(p, &"catch") - _when(p, &"gasp"))
	check(s.mouth().jaw_open < gasp * 0.7, "and catches (%.2f)" % s.mouth().jaw_open)
	him.queue_free()


func test_a_broken_jaw_barely_opens() -> void:
	var whole := _man(&"speech_jaw_whole")
	var broken := _man(&"speech_jaw_broken")
	await physics_frames(2)
	broken.physiology.jaw_broken = true
	var a := _speech(whole)
	var b := _speech(broken)
	var most := [0.0, 0.0]
	a.say("Nnngh! Nnnh! Alright!")
	b.say("Nnngh! Nnnh! Alright!")
	for i in int(1.5 / DT):
		a.step(DT)
		b.step(DT)
		most[0] = maxf(most[0], a.mouth().jaw_open + a.mouth().aa)
		most[1] = maxf(most[1], b.mouth().jaw_open + b.mouth().aa)
	check(most[1] < most[0] * 0.35, "the broken jaw opens a fraction as far (%.2f against %.2f)" % [most[1], most[0]])
	whole.queue_free()
	broken.queue_free()


func test_his_head_nods_on_the_word_he_leans_on() -> void:
	var him := _man(&"speech_nod")
	await physics_frames(2)
	var s := _speech(him)
	var life := him.get_node(^"FaceLife") as FaceLife
	life.auto = false
	var p := FaceSpeech.plan("I'm calling you out, mister!", s.tuning)
	check((p.nods as Array).size() >= 1 and (p.nods as Array).size() <= 3, "a nod or two, not one a word (%s)" % [p.nods])
	s.say("I'm calling you out, mister!")
	var dip := 0.0
	for i in int(2.0 / DT):
		s.step(DT)
		life.step(DT)
		dip = minf(dip, life.gaze.nod.x)
	check(dip < -1.0 and dip > -6.0, "his head dips a little (%.1f degrees)" % dip)
	_steps(s, 0.5)
	check(life.gaze.nod == Vector3.ZERO, "and comes back when he's done")
	him.queue_free()


func test_the_mask_moves_with_his_jaw() -> void:
	var him := _man(&"speech_masked", MASKED, true)
	await physics_frames(2)
	var mask: MeshInstance3D = null
	for k: String in him.skin_meshes:
		if k.begins_with("bandana_mask/"):
			mask = him.skin_meshes[k]
	check(mask != null, "he wears the mask")
	if mask == null:
		him.queue_free()
		return
	check(mask.find_blend_shape_by_name(&"jaw_open") >= 0, "the mask carries the jaw's shape (tools/faces/mask_jaw.py)")
	var s := _speech(him)
	s.say("Open the drawer. Slow.")
	var moved := 0.0
	var same := true
	for i in int(1.0 / DT):
		s.step(DT)
		for k: StringName in FaceSpeech.SHAPES:
			same = same and absf(_shape(mask, k) - _shape(_head(him), k)) < 1e-5
		moved = maxf(moved, _shape(mask, &"jaw_open") + _shape(mask, &"aa"))
	check(same, "the mask's shapes are his mouth's, frame by frame")
	check(moved > 0.3, "and it opens with him (%.2f)" % moved)
	him.queue_free()


func test_a_recording_times_his_mouth() -> void:
	# A made-up line: quiet, a burst of voice, a pause, another burst, quiet.
	var rate := 16000
	var spans := [[0.3, 0.8], [1.2, 1.7]]
	var data := PackedByteArray()
	data.resize(int(2.0 * rate) * 2)
	for i in int(2.0 * rate):
		var t := float(i) / rate
		var on := false
		for sp: Array in spans:
			on = on or (t >= sp[0] and t < sp[1])
		data.encode_s16(i * 2, int(sin(t * TAU * 180.0) * 12000.0) if on else 0)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	var env := FaceSpeech.loudness(wav, 100.0)
	check(env.size() == 200 and env[10] < 0.05 and env[50] > 0.8, "its loudness: quiet then loud (%.2f, %.2f)" % [env[10], env[50]])
	var him := _man(&"speech_audio")
	await physics_frames(2)
	var s := _speech(him)
	var secs := s.say("Hold still, mister.", {"audio": wav})
	check_near(secs, 1.7 + 0.12, 0.05, "he talks as long as the recording (%.2f s)" % secs)
	var open := func() -> float: return s.mouth().jaw_open + s.mouth().aa + s.mouth().lips_apart + s.mouth().ee
	var at := {}
	var t := 0.0
	for i in int(1.9 / DT):
		s.step(DT)
		t += DT
		for k: float in [0.15, 0.55, 1.0, 1.45]:
			if absf(t - k) < DT * 0.5:
				at[k] = open.call()
	check(at[0.15] < 0.02, "still before the voice (%.2f)" % at[0.15])
	check(at[0.55] > 0.15 and at[1.45] > 0.15, "talking in the voice (%.2f, %.2f)" % [at[0.55], at[1.45]])
	check(at[1.0] < 0.05, "quiet in its pause (%.2f): the comma laid on it" % at[1.0])
	him.queue_free()


func test_a_phoneme_track_times_his_mouth() -> void:
	var him := _man(&"speech_track")
	await physics_frames(2)
	var s := _speech(him)
	s.say("map", {"phonemes": [[0.0, 0.2, "sil"], [0.2, 0.3, "M"], [0.3, 0.55, "AE1"], [0.55, 0.65, "P"], [0.65, 1.0, "sil"]]})
	_steps(s, 0.25)
	check(s.mouth().mbp > 0.7, "shut on its M (%.2f)" % s.mouth().mbp)
	_steps(s, 0.18)
	check(s.mouth().aa > 0.2, "open on its AE (%.2f)" % s.mouth().aa)
	_steps(s, 0.17)
	check(s.mouth().mbp > 0.7, "shut on its P (%.2f)" % s.mouth().mbp)
	him.queue_free()


func test_letters_to_sounds() -> void:
	var sounds := func(w: String) -> String:
		return " ".join((FaceSpeech.word_sounds(w).sounds as Array).map(func(x: Array) -> String: return String(x[0])))
	check_eq(sounds.call("time"), "t aa ih m", "a silent e lengthens the vowel")
	check_eq(sounds.call("hat"), "h ae t", "a short a")
	check_eq(sounds.call("lamb"), "l ae m", "a silent b")
	check_eq(sounds.call("knife"), "t aa ih f", "a silent k")
	check_eq(sounds.call("phone"), "f ow t", "ph is f")
	check_eq(sounds.call("buckets"), "m ah k eh t s", "ck, a plural")
	check_eq(sounds.call("the"), "th ah", "the words English spells worst from a table")
	check_eq(FaceSpeech.word_sounds("alone").stress, 1, "a- gives its stress to the next syllable")
	check_eq(FaceSpeech.word_sounds("of").stress, -1, "a little word takes no stress")
