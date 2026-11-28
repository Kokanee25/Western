extends TestCase
## Lines said with the face and body (#1316): a line's delivery tag (Delivery, config/delivery.json)
## drives his face and a gesture (LineGesture) on the beat, never takes a busy hand from its chore,
## and the men he's talking to answer from the same tag; Sarge's steady nerves answer nothing.

const MAN := &"bold_cowboy_talking"


## A brain's one field LineGesture asks of a listener (steady nerves: Sarge's dial, #1312).
class FakeBrain extends Node:
	var is_steady := false

	func steady() -> bool:
		return is_steady


func _man(id: StringName, at := Vector3.ZERO, facing := 0.0) -> HumanBody:
	var him := HumanBody.new()
	him.body_model = MAN
	him.person_id = id
	add_child(him)
	him.global_position = at
	him.rotation.y = facing
	return him


func _arm(him: HumanBody, side: String) -> float:
	var v := 0.0
	for s in ["upper_arm_", "forearm_"]:
		v += (him.gesture_offsets.get(StringName(s + side), Vector3.ZERO) as Vector3).length()
	return v


## He says `text` (marked with `*` for its beat, tagged `tag`), as a town script line is said.
func _say(him: HumanBody, marked: String, tag: StringName) -> String:
	var clean := Delivery.remember(marked, tag)
	Events.spoke.emit(him, clean)
	return clean


func test_the_tags_are_data_and_every_line_carries_a_known_one() -> void:
	var d := Delivery.data()
	check(not d.is_empty(), "config/delivery.json reads")
	for t: StringName in Delivery.TAGS:
		check((d.tags as Dictionary).has(String(t)), "tag %s has its entry" % t)
		var e := Delivery.entry(t)
		for o: Dictionary in e.get("gestures", []):
			check(not Delivery.gesture(String(o.g)).is_empty(), "%s's gesture %s is defined" % [t, o.g])
		for w: String in e.get("with", []):
			check(not Delivery.gesture(w).is_empty(), "%s's %s is defined" % [t, w])
		for role: String in (e.get("listen", {}) as Dictionary):
			var g := String(e.listen[role].get("g", ""))
			check(g == "" or not Delivery.gesture(g).is_empty(), "%s's listeners' %s is defined" % [t, g])
	# Every town script line's tag is one of the set; none of its words keeps a beat mark when said.
	var tagged := 0
	for id: String in TownScript.lines():
		var tg: Array = TownScript.tag_of(id)
		check(Delivery.TAGS.has(tg[0]), "%s's tag %s is in the set" % [id, tg[0]])
		tagged += 1 if tg[0] != &"calm" else 0
		for w: String in TownScript.words(id):
			check(w.find("*") < 0, "%s is said without its beat mark" % id)
	check(tagged > 200, "the town's lines carry their tags (%d)" % tagged)
	# The notes read as the tool reads them: a whole word ("low", not the "low" in "slow").
	check(Delivery.tag_of_note("Low, to his neighbour.")[0] == &"low", "'Low, ...' is low")
	check(Delivery.tag_of_note("slow")[0] == &"calm", "'slow' is calm")
	check(Delivery.tag_of_note("Telling it as a joke.")[0] == &"laughing", "a joke is laughing")
	check(Delivery.tag_of_note("")[0] == &"calm", "no note is calm")


func test_the_beat_mark_is_the_word_it_stands_before() -> void:
	var sb := Delivery.strip_beat("You *never paid me, Earl.")
	check(sb[0] == "You never paid me, Earl." and int(sb[1]) == 1, "the mark comes out and names word 1 (%s)" % [sb])
	check(int(Delivery.strip_beat("No mark here.")[1]) == -1, "no mark, no word")
	check(TownScript.capitalise("*you know it.") == "*You know it.", "a marked first word still takes its capital")


func test_an_angry_line_sets_his_face_and_his_fist_lands_on_its_word() -> void:
	var him := _man(&"lg_angry")
	await physics_frames(3)
	var lg := LineGesture.of(him)
	var life := him.get_node(^"FaceLife") as FaceLife
	check(lg != null, "every man has his LineGesture")
	check(not lg.playing(), "nothing plays before he speaks")
	var text := _say(him, "I told you twice, mister. You *never paid me.", &"angry")
	await physics_frames(1)
	check(lg.last.get("tag") == &"angry", "the line's tag reached him (%s)" % lg.last.get("tag"))
	var plan := FaceSpeech.plan(text)
	var word_t := float((plan.words as Array)[6])
	check_near(float(lg.last.beat), word_t + 0.06, 0.02, "the beat is on the marked word, 'never' (%.2f s)" % word_t)
	check((lg.last.gestures as Array).size() >= 1, "a gesture plays with it (%s)" % [lg.last.gestures])
	var peak := 0.0
	var peak_t := 0.0
	var scowl := 0.0
	for i in int((float(plan.seconds) + 1.0) * 60.0):
		await physics_frames(1)
		var m := _arm(him, "r") + _arm(him, "l") + (him.gesture_offsets.get(&"chest", Vector3.ZERO) as Vector3).length()
		if m > peak:
			peak = m
			peak_t = lg._t
		scowl = maxf(scowl, float(life.expression().scowl))
	check(peak > 10.0, "his arm or body moves with it (%.1f degrees)" % peak)
	check(absf(peak_t - float(lg.last.beat)) < 0.2, "the gesture peaks on the beat (%.2f s, beat %.2f s)" % [peak_t, lg.last.beat])
	check(scowl > 0.3, "he scowls through it (%.2f)" % scowl)
	for i in 120:
		await physics_frames(1)
	check(not lg.playing() and him.gesture_offsets.is_empty(), "and it's over: nothing ticks between lines")
	check(life.expression().scowl < 0.1, "his face back to his own (%.2f)" % life.expression().scowl)
	him.queue_free()


func test_a_laughing_line_smiles_and_lands_after_the_punchline() -> void:
	var him := _man(&"lg_laugh")
	await physics_frames(3)
	var lg := LineGesture.of(him)
	var life := him.get_node(^"FaceLife") as FaceLife
	var text := _say(him, "And the mule walked in after him!", &"laughing")
	await physics_frames(1)
	var plan := FaceSpeech.plan(text)
	check(float(lg.last.beat) > float(plan.voice[1]), "the laugh lands after the last word (%.2f > %.2f)" % [lg.last.beat, plan.voice[1]])
	check((lg.last.gestures as Array).has("laugh_shake"), "his shoulders shake with it (%s)" % [lg.last.gestures])
	var smile := 0.0
	for i in 90:
		await physics_frames(1)
		smile = maxf(smile, float(life.expression().smile))
	check(smile > 0.5, "he smiles (%.2f)" % smile)
	him.queue_free()


func test_a_busy_hand_stays_at_its_chore() -> void:
	var him := _man(&"lg_busy")
	await physics_frames(3)
	var lg := LineGesture.of(him)
	var at := him.global_transform * Vector3(0.25, 1.0, -0.4)
	var chore := func() -> void: him.reach_to("r", at, Vector3.UP, 1.0)   # a glass held, every tick
	get_tree().physics_frame.connect(chore)
	await physics_frames(20)
	check(him.hand_busy("r") and not him.hand_busy("l"), "his right hand is at its chore, his left free")
	_say(him, "You *never paid me.", &"angry")
	var right := 0.0
	var left := 0.0
	for i in 120:
		await physics_frames(1)
		right = maxf(right, _arm(him, "r"))
		left = maxf(left, _arm(him, "l"))
	get_tree().physics_frame.disconnect(chore)
	check(right == 0.0, "nothing of the gesture on the busy right arm (%.1f)" % right)
	check(him.palm("r").distance_to(at) < 0.12, "his right hand is still where the chore has it (%.2f m)" % him.palm("r").distance_to(at))
	check(left > 5.0 or (lg.last.gestures as Array).has("lean_in_small"), "the other hand or his body does it (left %.1f, %s)" % [left, lg.last.gestures])
	him.queue_free()


func test_walking_he_only_moves_his_head() -> void:
	var him := _man(&"lg_walk")
	await physics_frames(3)
	him.gait = &"walk"
	him.move_speed = 1.3
	var lg := LineGesture.of(him)
	_say(him, "You *never paid me.", &"angry")
	var arms := 0.0
	for i in 90:
		await physics_frames(1)
		arms = maxf(arms, _arm(him, "r") + _arm(him, "l") + (him.gesture_offsets.get(&"chest", Vector3.ZERO) as Vector3).length())
	check(lg.last.posture == &"walk", "he's walking")
	check(arms == 0.0, "no arms or body thrown about mid-stride (%.1f)" % arms)
	him.queue_free()


func test_the_men_listening_answer_and_sarge_doesnt() -> void:
	var talker := _man(&"lg_talker")
	var butt := _man(&"lg_butt", Vector3(0, 0, -1.4), PI)
	var mate := _man(&"lg_mate", Vector3(1.2, 0, -0.8), PI)
	var sarge := _man(&"lg_sarge", Vector3(-1.2, 0, -0.8), PI)
	var br := FakeBrain.new()
	br.name = "Brain"
	br.is_steady = true
	sarge.add_child(br)
	await physics_frames(3)
	var clean := Delivery.remember("Your mother *dresses you yet, Wilbur?", &"mocking")
	Events.overheard.emit(talker, clean, {"to": butt, "tag": &"mocking"})
	await physics_frames(1)
	var heard: Array = LineGesture.of(talker).last.listeners
	check(heard.has(butt) and heard.has(mate), "the men by him hear it (%d)" % heard.size())
	check(not heard.has(sarge), "Sarge doesn't: nothing rattles him")
	check(LineGesture.of(butt).last_heard.get("g") == "wince", "the man it's said to winces (%s)" % LineGesture.of(butt).last_heard.get("g"))
	check(LineGesture.of(mate).last_heard.get("g") == "look_each", "the other looks at his mate (%s)" % LineGesture.of(mate).last_heard.get("g"))
	check(LineGesture.of(sarge).last_heard.is_empty(), "Sarge's face and body stay his own")
	var grin := 0.0
	var wince := 0.0
	for i in 150:
		await physics_frames(1)
		grin = maxf(grin, float((mate.get_node(^"FaceLife") as FaceLife).expression().smile))
		wince = maxf(wince, float((butt.get_node(^"FaceLife") as FaceLife).expression().scowl))
	check(grin > 0.3, "his mate grins (%.2f)" % grin)
	check(wince > 0.25, "the butt of it scowls (%.2f)" % wince)
	# Sarge's own line, scared by its tag, comes out calm (nerves of steel).
	Delivery.remember("They're coming for us all!", &"scared")
	Events.spoke.emit(sarge, "They're coming for us all!")
	await physics_frames(1)
	check(LineGesture.of(sarge).last.get("tag") == &"calm", "Sarge isn't scared by his own words (%s)" % LineGesture.of(sarge).last.get("tag"))
	for m in [talker, butt, mate, sarge]:
		m.queue_free()


func test_off_it_does_nothing() -> void:
	var him := _man(&"lg_off")
	await physics_frames(3)
	LineGesture.enabled = false
	_say(him, "You *never paid me.", &"angry")
	await physics_frames(30)
	LineGesture.enabled = true
	check(not LineGesture.of(him).playing() and him.gesture_offsets.is_empty(), "off: his lines move only his mouth (the before)")
	him.queue_free()
