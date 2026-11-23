extends TestCase
## Reactions in stages (townsfolk step 5, #982; docs/briefs/townsfolk.md §4, §8's reactions and leaks
## rows). Written as expectations first, as the perception lab's are:
## - per stimulus (a shot heard, a blast, a gun drawn, a man down), each man's start against his
##   distance: later with distance, never two on one frame, never before the sound could reach him;
## - leaks 0: he reacts only to what reached him (out of earshot, nothing), turns to where he *thinks*
##   it was (Senses' guess), and knows no shooter he didn't see;
## - by his dials: the faint-hearted hide (or run for a door), the nosy go to look but stop short, the
##   rest carry on after a breath, the dutiful kneel by a man down; the gawk ring keeps its distance;
## - the come-back: calm a while, he's back at his spot and its chore has him, shaken; shaken, the
##   next one starts him sooner.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(260, 1, 260)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _man(id: String, seed_value: int, at: Vector3, faces: Vector3, dials := {}, kind := &"") -> CivilianBrain:
	var man := HumanBody.new()
	man.body_model = &"storekeeper_s1_talking"
	man.person_id = StringName(id)
	man.rng_seed = seed_value
	man.has_gun = false
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = at
	brain.faces = faces
	for k: String in dials:
		brain.dials[k] = dials[k]
	man.add_child(brain)
	world.add_child(man)
	man.global_position = at
	man.face(faces)
	if kind != &"":
		brain.chores = [SpotChore.new(man, kind, at, faces, {})]
	return brain


## A line of men down the street from the shot, facing it, at these distances (m).
const LINE := [3.0, 9.0, 16.0, 24.0, 33.0, 45.0, 60.0, 78.0, 95.0, 118.0]


func _line_of(dials := {}) -> Array[CivilianBrain]:
	var out: Array[CivilianBrain] = []
	for i in LINE.size():
		var d: float = LINE[i]
		# Every other man a different nerve (the start's by nerve too): the wave must still rise.
		var dl := dials.duplicate()
		if not dl.has("nerve"):
			dl["nerve"] = 0.9 if i % 2 == 0 else 0.1
		out.append(_man("m%d" % i, 300 + i, Vector3(d, 0.0, (i % 3) * 1.5 - 1.5), Vector3(0.0, 1.5, 0.0), dl))
	return out


## The reactions row for one stimulus: each man's start frame against his distance.
func _wave(men: Array[CivilianBrain], what: String, frame0: int) -> void:
	var starts := {}
	var rows := []
	for b in men:
		var r: Reaction = b.reaction
		check(r.start_frame >= 0, "%s: %s started (%s)" % [what, b.body.person_id, r.describe()])
		if r.start_frame < 0:
			continue
		var d: float = r.distance  # (how far it was when it reached him)
		var delay := float(r.start_frame - frame0) / Engine.physics_ticks_per_second
		rows.append([d, delay, b.body.person_id])
		check(not starts.has(r.start_frame), "%s: never two on one frame (%s and %s on %d)" % [what, b.body.person_id, starts.get(r.start_frame, ""), r.start_frame])
		starts[r.start_frame] = b.body.person_id
		check(delay >= d / GameAudio.SPEED_OF_SOUND + Reaction.START_SOONEST - 0.02,
				"%s: %s not before it reached him (%.2f s at %.0f m)" % [what, b.body.person_id, delay, d])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	print("  %s: %s" % [what, ", ".join(rows.map(func(r: Array) -> String: return "%.0f m %.2f s" % [r[0], r[1]]))])
	for i in rows.size():
		for j in range(i + 1, rows.size()):
			if rows[j][0] - rows[i][0] >= 25.0:
				check(rows[j][1] > rows[i][1], "%s: later with distance (%s %.0f m %.2f s, %s %.0f m %.2f s)" % [what,
						rows[i][2], rows[i][0], rows[i][1], rows[j][2], rows[j][0], rows[j][1]])


func test_a_shot_goes_through_the_street_as_a_wave() -> void:
	var men := _line_of()
	await physics_frames(30)
	var f0 := Engine.get_physics_frames()
	Events.noise.emit(Vector3(0.0, 1.5, 0.0), DeedWatch.GUNSHOT, &"gunshot", null)
	await physics_frames(int(2.5 * 60))
	_wave(men, "a shot", f0)
	for b in men:
		check(b.reaction.kind == &"shot", "%s: a shot, the shooter unseen (%s)" % [b.body.person_id, b.reaction.kind])
		check(b.reaction.choice != &"", "%s decided: %s" % [b.body.person_id, b.reaction.describe()])


func test_a_blast_goes_out_as_a_wave_too() -> void:
	var men := _line_of()
	await physics_frames(30)
	var f0 := Engine.get_physics_frames()
	Events.noise.emit(Vector3(0.0, 0.5, 0.0), DeedWatch.BLAST, &"blast", null)
	await physics_frames(int(2.5 * 60))
	_wave(men, "a blast", f0)


## The wave of the brief's table, as the numbers say it: the start's own delay by nerve and distance.
func test_the_start_rises_with_distance_and_comes_sooner_shaken() -> void:
	for n in [0.0, 0.5, 1.0]:
		var last := -1.0
		for d in [0.0, 10.0, 30.0, 60.0, 100.0]:
			var s: float = d / GameAudio.SPEED_OF_SOUND + Reaction.start_after(n, d)
			check(s > last, "nerve %.1f: rises with distance (%.2f s at %.0f m)" % [n, s, d])
			last = s
		check(Reaction.start_after(n, 0.0) >= 0.15 and Reaction.start_after(n, 200.0) <= 0.5, "0.15-0.5 s after it reaches him")
		check(Reaction.start_after(n, 5.0, true) <= Reaction.start_after(n, 5.0), "shaken: no later")
	check(Reaction.start_after(1.0, 5.0, true) < Reaction.start_after(1.0, 5.0), "shaken, the steady man's start is sooner")


## Leaks 0: out of earshot nothing reaches him; in it, he turns to his guess, and knows no shooter
## he didn't see.
func test_leaks_he_acts_only_on_what_reached_him() -> void:
	var near := _man("near", 41, Vector3(6.0, 0.0, 0.0), Vector3(12.0, 1.5, 0.0))  # his back to it
	var far := _man("far", 42, Vector3(90.0, 0.0, 0.0), Vector3(0.0, 1.5, 0.0))
	var shooter := _man("shooter", 43, Vector3(0.0, 0.0, 0.0), Vector3(-5.0, 1.5, 0.0))
	await physics_frames(30)
	var leaks := []
	# A noise heard only 30 m off: the far man never knew.
	Events.noise.emit(Vector3(0.0, 1.5, 0.0), 30.0, &"gunshot", shooter.body)
	await physics_frames(90)
	if far.reaction.active() or far.reaction.start_frame >= 0:
		leaks.append("the far man reacted to a sound he couldn't hear")
	if not near.reaction.active():
		leaks.append("the near man didn't")
	var heard := near.senses.last_sound([&"gunshot"])
	if heard.is_empty() or near.reaction.at != heard.at:
		leaks.append("the near man's 'where' isn't his own guess (%s against %s)" % [near.reaction.at, heard.get("at")])
	if near.reaction.who != null:
		leaks.append("the near man knows who fired, his back to him")
	check_eq(leaks.size(), 0, "leaks: %s" % [leaks])


func test_by_his_dials_hide_look_or_carry_on() -> void:
	var timid := _man("timid", 51, Vector3(4.0, 0.0, 0.0), Vector3(4.0, 1.5, 5.0), {"nerve": 0.2, "nosy": 0.5, "duty": 0.2})
	var nosy := _man("nosy", 52, Vector3(40.0, 0.0, 0.0), Vector3(40.0, 1.5, 5.0), {"nerve": 0.7, "nosy": 0.9, "duty": 0.3})
	var smith := _man("smith", 53, Vector3(-40.0, 0.0, 0.0), Vector3(-40.0, 1.5, 5.0), {"nerve": 0.8, "nosy": 0.2, "duty": 0.5}, &"work")
	var runner := _man("runner", 54, Vector3(0.0, 0.0, 8.0), Vector3(0.0, 1.5, 15.0), {"nerve": 0.1, "nosy": 0.5, "duty": 0.2})
	runner.refuges = [Vector3(0.0, 0.0, 25.0), Vector3(0.0, 0.0, -10.0)]
	await physics_frames(60)
	var said: Array[String] = []
	var heard := func(_who: Node, text: String) -> void: said.append(text)
	Events.spoke.connect(heard)
	Events.noise.emit(Vector3(0.0, 1.5, 0.0), DeedWatch.GUNSHOT, &"gunshot", null)
	await physics_frames(int(3.5 * 60))
	check_eq(timid.reaction.choice, &"hide", "the faint heart hides (%s)" % timid.reaction.describe())
	check_eq(timid.mood, CivilianBrain.Mood.COWERING, "cowering")
	check_eq(runner.reaction.choice, &"flee", "with a door behind him, he runs for it (%s)" % runner.reaction.describe())
	check_eq(nosy.reaction.choice, &"gawk", "the nosy man goes to look (%s)" % nosy.reaction.describe())
	check_eq(smith.reaction.choice, &"carry_on", "the smith carries on (%s)" % smith.reaction.describe())
	var ran := await wait_until(func() -> bool: return runner.body.global_position.distance_to(Vector3(0.0, 0.0, 25.0)) < 1.0, 60 * 12)
	check(ran, "to the door away from it, not the one toward it (%s)" % runner.body.global_position)
	var smith_back := await wait_until(func() -> bool: return not smith.reaction.active() and (smith.chore as SpotChore)._on, 60 * 8)
	check(smith_back, "the smith's back at his work after a breath (%s)" % smith.reaction.describe())
	await wait_until(func() -> bool: return nosy.reaction._arrived, 60 * 20)
	var nd := nosy.body.global_position.distance_to(Vector3.ZERO)
	check(nd < 39.0 and nd >= 8.0, "the nosy man came nearer, but not up to it (%.1f m)" % nd)
	check(nosy.reaction.describe().contains("gawk"), "and stands watching (%s)" % nosy.reaction.describe())
	await physics_frames(60)
	Events.spoke.disconnect(heard)
	# A shot with nobody down (the town gate, #1167): nobody talks of a man down.
	var dead_talk := said.filter(func(t: String) -> bool: return "dead" in t or "give him air" in t)
	check(dead_talk.is_empty(), "no talk of a man down when nobody is (%s)" % [said])
	check(said.any(func(t: String) -> bool: return t in CivilianBrain.LINES[&"gawk_shot"]), "the gawker asks what it was (%s)" % [said])


func test_a_gun_drawn_near_the_timid_back_off_the_steady_watch() -> void:
	var gunman := _man("gunman", 61, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.5, 6.0))
	var timid := _man("timid", 62, Vector3(-1.5, 0.0, 5.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.2})
	var steady := _man("steady", 63, Vector3(1.5, 0.0, 6.5), Vector3(0.0, 1.5, 0.0), {"nerve": 0.9})
	var far := _man("far", 64, Vector3(0.0, 0.0, 20.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.9})
	var noticed := await wait_until(func() -> bool: return timid.senses.sees(gunman.body) and steady.senses.sees(gunman.body), 60 * 4)
	check(noticed, "they've seen him")
	var f0 := Engine.get_physics_frames()
	Events.deed.emit(gunman.body, &"draw", null, gunman.body.global_position)
	await physics_frames(int(3.0 * 60))
	check_eq(timid.reaction.choice, &"back_away", "the timid man backs off (%s)" % timid.reaction.describe())
	check_eq(steady.reaction.choice, &"watch", "the steady man watches him (%s)" % steady.reaction.describe())
	check(not far.reaction.active() and far.reaction.start_frame < 0, "beyond the 9 m: nothing (%s)" % far.reaction.describe())
	check(timid.reaction.start_frame != steady.reaction.start_frame, "not on one frame")
	check(timid.reaction.start_frame > f0 and steady.reaction.start_frame > f0, "each a beat after")
	var away := await wait_until(func() -> bool: return timid.body.global_position.distance_to(gunman.body.global_position) > 8.0, 60 * 6)
	check(away, "he's put distance between them (%.1f m)" % timid.body.global_position.distance_to(gunman.body.global_position))


func test_a_man_down_the_gawk_ring_and_the_dutiful_kneel() -> void:
	var victim := _man("victim", 71, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.5, 5.0))
	var gawkers: Array[CivilianBrain] = []
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.3
		var at := Vector3(cos(a), 0.0, sin(a)) * (14.0 + i * 1.5)
		gawkers.append(_man("g%d" % i, 72 + i, at, Vector3(0.0, 1.5, 0.0), {"nerve": 0.8, "nosy": 0.8, "duty": 0.3}))
	var helper := _man("helper", 80, Vector3(-3.0, 0.0, 10.0), Vector3(0.0, 1.5, 0.0), {"nerve": 0.9, "nosy": 0.3, "duty": 1.0})
	var ok := await wait_until(func() -> bool:
		for g in gawkers + [helper]:
			if not g.senses.sees(victim.body):
				return false
		return true, 60 * 4)
	check(ok, "they all see him standing there")
	var f0 := Engine.get_physics_frames()
	Events.person_fell.emit(victim.body, false)
	await physics_frames(int(3.0 * 60))
	var all: Array[CivilianBrain] = gawkers.duplicate()
	all.append(helper)
	_wave(all, "a man down", f0)
	check_eq(helper.reaction.choice, &"help", "the dutiful man goes to him (%s)" % helper.reaction.describe())
	await physics_frames(60 * 12)
	check(helper.body.global_position.distance_to(victim.body.global_position) < 1.5, "beside him (%.1f m)" % helper.body.global_position.distance_to(victim.body.global_position))
	check_eq(helper.body.pose, &"tend", "down beside him")
	for g in gawkers:
		check_eq(g.reaction.choice, &"gawk", "%s comes to look (%s)" % [g.body.person_id, g.reaction.describe()])
		var d := g.body.global_position.distance_to(victim.body.global_position)
		check(d >= Reaction.GAWK_RING.x - 0.6 and d <= Reaction.GAWK_RING.y + 0.8, "%s in the ring, 5-8 m back (%.1f m)" % [g.body.person_id, d])


func test_calm_a_while_he_comes_back_to_his_spot_and_its_chore_shaken() -> void:
	var b := _man("keeper", 91, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.5, -5.0), {"nerve": 0.92, "nosy": 0.2, "duty": 0.2}, &"stand")
	var chore := b.chores[0] as SpotChore
	await wait_until(func() -> bool: return chore._on, 60 * 5)
	var f0 := Engine.get_physics_frames()
	Events.noise.emit(Vector3(2.0, 1.5, 0.0), DeedWatch.GUNSHOT, &"gunshot", null)
	await physics_frames(int(1.5 * 60))
	check_eq(b.reaction.choice, &"hide", "close by, even the steady man gets down (%s)" % b.reaction.describe())
	check(not chore._on, "the chore let him go")
	var first := float(b.reaction.start_frame - f0) / 60.0
	var calm := Reaction.CALM_HIDE + Reaction.CALM_HIDE_NERVE * 0.08
	await physics_frames(int((calm - 3.0) * 60))
	check(b.reaction.active(), "still down before the calm time (%s)" % b.reaction.describe())
	var back := await wait_until(func() -> bool: return chore._on, 60 * 12)
	check(back, "calm a while: back at his chore (%s)" % b.reaction.describe())
	check(b.reaction.shaken(), "and shaken")
	var f1 := Engine.get_physics_frames()
	Events.noise.emit(Vector3(2.0, 1.5, 0.0), DeedWatch.GUNSHOT, &"gunshot", null)
	await physics_frames(60)
	var second := float(b.reaction.start_frame - f1) / 60.0
	check(second < first, "shaken, he starts sooner (%.2f s against %.2f s)" % [second, first])
	check(b.reaction.fear > Reaction.STIMULI[&"shot"].fear * 0.9, "and it frightens him more (%.2f)" % b.reaction.fear)


## #1184 (gate round 2, run 4): after a shot the liveryman backed off to watch it from the street and
## stayed there, 24.8 m from his post, for the rest of the night. Whatever he chose, off his spot he
## comes back to it.
func test_whatever_he_chose_off_his_spot_he_comes_back() -> void:
	for choice: StringName in [&"watch", &"hide", &"flee", &"gawk"]:
		var b := _man("w_%s" % choice, 95, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 1.5, -5.0))
		await physics_frames(2)
		b.post = Vector3(0.0, 0.0, 0.0)
		b.body.global_position = Vector3(12.0, 0.0, 6.0)
		b.reaction.choice = choice
		b.reaction.stage = Reaction.Stage.BACK
		b.returning = false
		b.reaction._end()
		check(b.returning, "%s: off his spot (12 m), he goes back to it" % choice)
		b.body.queue_free()
		await physics_frames(2)


## #1184 (gate round 2, run 4): after one shot "...They gone?" was said by four men and "Lord, lord" by
## four more. The relief goes round the town in other words, or not at all.
func test_the_relief_is_not_said_twice() -> void:
	var said := []
	var hook := func(_by: Node, text: String) -> void: said.append(text)
	Events.spoke.connect(hook)
	var men: Array[CivilianBrain] = []
	for i in 8:
		men.append(_man("r%d" % i, 120 + i, Vector3(float(i) * 2.0, 0.0, 30.0), Vector3(0.0, 1.5, 0.0)))
	await physics_frames(int(CivilianBrain.SAY_GAP * 60) + 10)
	for b in men:
		b.say(&"relief")
		await physics_frames(30)
	Events.spoke.disconnect(hook)
	var seen := {}
	for t: String in said:
		check(not seen.has(t), "\"%s\" once" % t)
		seen[t] = true
	check(said.size() >= 5, "most of them said something (%s)" % [said])
