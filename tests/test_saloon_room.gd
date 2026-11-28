extends TestCase
## The saloon at night as a room (townsfolk step 10, #1157; SaloonRoom; the brief's §6 and §8's
## saloon and hush rows):
## - the mood from who's in, their drink, the band, the night (night 1 about 0.7 at the door; the
##   night the sheriff dies louder) and it names itself;
## - the director's bits: each done by a man who's in the room, his mouth and hands moving; every
##   sound a bit makes has its man; the same bit from the same man not twice in five minutes;
## - the hush: a gun out in the room cuts a laugh, every man turns within 0.15-1.2 s, the far ones
##   later, the piano player gets two wrong notes in and ducks, the band starts again shakily and
##   the mood climbs back;
## - Harlan through the door: the town warm, a man hails him and the barkeep sets a glass down
##   unasked; the town cold, the talk drops.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	ValleyFolk.murder_auto = true  # (static: the tests after this one in the shard want No Law's beats)
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## The player stood at [x, z] on saloon B's floor (its space; #1230: the room is its bar room),
## looking at `look` [x, z].
func _stand(a: float, b: float, look_a: float, look_b: float) -> void:
	var f := valley.folk
	var p := _player()
	var at := f.hall_point("saloon", [a, 0.95, b])
	var to := f.hall_point("saloon", [look_a, 0.95, look_b])
	_put(p, at, to)


## Out in the street, 30 m off the saloon.
func _out() -> void:
	var f := valley.folk
	var at := f.lot_point("saloon_annex", 5.2, -30.0)
	_put(_player(), at, f.lot_point("saloon_annex", 5.2, 0.0))


func _put(p: Player, at: Vector3, to: Vector3) -> void:
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-(to.x - at.x), -(to.z - at.z))


## Night in the room: the clock at `h`, the folk placed, a few seconds for chairs and glasses.
func _night(h: float) -> SaloonRoom:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.set_time(h)
	await physics_frames(1)
	f._look = 0.0
	await physics_frames(60 * 6)
	return f.room


func _brain(id: String) -> CivilianBrain:
	var man := valley.folk.folk_man(StringName(id))
	return man.get_node_or_null(^"Brain") as CivilianBrain if man != null else null


func _has_bit(room: SaloonRoom, by: String, bit: String, t: float) -> bool:
	for b: Dictionary in room.log:
		if String(b.get("by", "")) == by and String(b.what) == bit and absf(float(b.get("at_s", -99.0)) - t) < 2.6:
			return true
	return false


func test_the_gap_between_bits_follows_the_mood() -> void:
	var rows := [[0.05, 90.0, 120.0], [0.3, 40.0, 60.0], [0.7, 8.0, 20.0], [1.0, 5.0, 12.0]]
	check(SaloonRoom.gap_range(rows, 0.7) == Vector2(8.0, 20.0), "a bit every 8-20 s at mood 0.7")
	check(SaloonRoom.gap_range(rows, 0.3) == Vector2(40.0, 60.0), "every 40-60 s at 0.3")
	var mid := SaloonRoom.gap_range(rows, 0.5)
	check(mid.x > 8.0 and mid.x < 40.0 and mid.y > 20.0 and mid.y < 60.0, "between them between (%s)" % mid)
	check(SaloonRoom.gap_range(rows, 0.0) == Vector2(90.0, 120.0), "slowest under the first row")
	check(SaloonRoom.gap_range(rows, 1.2) == Vector2(5.0, 12.0), "quickest over the last")


func test_the_mood_and_the_bits() -> void:
	_out()  # out in the street
	var room: SaloonRoom = await _night(20.4)
	var f := valley.folk
	print("  in the room: %s" % [room.ins])
	check(room.ins.size() >= 10, "ten or more in the room at 20:24 (%d: %s)" % [room.ins.size(), room.ins])
	for id: String in ["barkeep", "miner", "loudmouth", "liveryman", "storekeeper", "saloon_girl", "pianist"]:
		check(room.ins.has(StringName(id)), "%s is in the room" % id)
	print("  night 1: mood %.2f (%s) target %.2f %s" % [room.mood, room.mood_name(), room.target, room.parts])
	check(room.mood >= 0.55 and room.mood <= 0.85, "night 1: about 0.7 at the door (%.2f, %s)" % [room.mood, room.parts])
	check(room.mood_name() == &"lively", "and lively (%s)" % room.mood_name())
	check(String(room.parts.get("night_id", "")) == "bold", "the night is No Law's bold one (%s)" % [room.parts])
	var first := room.mood
	# The night the sheriff dies (Sean's pick 4 C): louder than ever.
	StoryState.set_fact("nolaw.murder", "done")
	StoryState.set_fact("nolaw.sheriff", "dead")
	await physics_frames(70)
	print("  the sheriff dead: mood %.2f (%s)" % [room.mood, room.parts])
	check(room.mood > first + 0.1, "the night the sheriff dies is louder (%.2f over %.2f)" % [room.mood, first])
	StoryState.clear()
	await physics_frames(70)

	# In at the door: the director's own bits for two minutes, and two asked for.
	_stand(14.6, 2.6, 8.0, 7.0)  # in at the corner door
	await physics_frames(30)
	var spoke := []
	var on_spoke := func(who: Node, text: String) -> void: spoke.append([who, text])
	Events.spoke.connect(on_spoke)
	var seen := 0
	var laughed_at := -1.0
	var asked := false
	for step in 60 * 100 / 6:
		await physics_frames(6)
		if step == 20:
			# (Asked only if the room hasn't just given him one: an asked bit skips the five minutes, #1312:
			# Sarge in the room changed the director's draws and the miner had laughed already.)
			var who := &"miner" if room._may_again("laugh", &"miner") else &"rancher"
			asked = room.start("laugh", who) if room._may_again("laugh", who) else true
			check(asked, "the %s can be given a laugh" % who)
		if step == 150:
			check(room.start("toast", &"rancher") or room.start("toast", &"miner") or room.start("toast", &"loudmouth"), "a man at the bar toasts")
		for b: Dictionary in room.log:
			if b.has("_checked") or not b.has("t") or not b.has("by") or String(b.by) == "":
				continue
			var man := f.folk_man(StringName(String(b.by)))
			if float(b.t) < 0.5 and not b.get("ended", false):
				continue
			b["_checked"] = true
			seen += 1
			check(man != null and room.inside(man.global_position), "%s by %s: he's in the room" % [b.what, b.by])
			if man == null or b.get("ended", false):
				continue
			var brain := man.get_node(^"Brain") as CivilianBrain
			check(brain.bit == b, "%s by %s: his brain is doing it" % [b.what, b.by])
			if b.what == &"laugh":
				var sp := man.get_node_or_null(^"FaceSpeech") as FaceSpeech
				check(sp == null or sp.speaking(), "%s laughing: his mouth is going" % b.by)
				var life := man.get_node_or_null(^"FaceLife") as FaceLife
				check(life == null or life.gaze.tip.x > 2.0, "%s laughing: his head's back (%s)" % [b.by, life.gaze.tip if life else Vector3.ZERO])
				check(float(man.pose_offsets.get(&"chest", Vector3.ZERO).x) != 0.0, "%s laughing: his chest moves" % b.by)
				laughed_at = float(b.at_s)
			if b.what == &"toast":
				var c := SpotChore._chore_of(man)
				check(c != null and c.glass_up > 0.3, "%s toasting: his glass is up (%s)" % [b.by, c.glass_up if c else -1.0])
	Events.spoke.disconnect(on_spoke)
	print("  bits: %s" % [room.log.map(func(b: Dictionary) -> String: return "%s %s %s%s" % [b.get("at_s", 0.0), b.what, b.get("by", ""), " '%s'" % b.say if b.has("say") else ""])])
	print("  sounds: %s" % [room.sounds.map(func(s: Dictionary) -> String: return "%s %s %s" % [s.t, s.sound, s.by])])
	check(seen >= 5, "bits handed out in two minutes at this mood (%d)" % seen)
	check(laughed_at >= 0.0, "someone laughed")
	# Every sound has its man, in the room, and his bit is in the log at that time.
	for s: Dictionary in room.sounds:
		var man := f.folk_man(StringName(String(s.by)))
		check(man != null and room.ins.has(StringName(String(s.by))), "sound %s has a source in the room (%s)" % [s.sound, s.by])
		check(_has_bit(room, String(s.by), String(s.bit), float(s.t)), "sound %s by %s is his bit's (%s)" % [s.sound, s.by, s.bit])
	check(room.sounds.size() >= 2, "bits made sounds (%d)" % room.sounds.size())
	# A toast's line came from the toaster's own mouth.
	for b: Dictionary in room.log:
		if b.has("say") and b.get("said", false):
			var man := f.folk_man(StringName(String(b.by)))
			check(spoke.any(func(e: Array) -> bool: return e[0] == man and e[1] == b.say), "%s said his %s line himself (%s)" % [b.by, b.what, b.say])
	check(room.log.any(func(b: Dictionary) -> bool: return b.what == &"toast" and b.get("said", false)), "a toast was said")
	# The same bit from the same man not twice in five minutes.
	var by := {}
	for b: Dictionary in room.log:
		if b.has("of"):
			continue
		var key := "%s %s" % [b.what, b.get("by", "")]
		check(not by.has(key) or b.what in [&"grin", &"lift"], "%s once in the two minutes" % key)
		by[key] = true


func test_the_hush() -> void:
	_stand(14.4, 2.8, 8.0, 7.0)
	var room: SaloonRoom = await _night(20.4)
	var f := valley.folk
	var band := f.band
	# The band under way (the piano player sat and playing).
	var waited := 0
	while waited < 60 * 40 and not (band.state == &"playing" and band.sounding(&"piano")):
		await physics_frames(30)
		waited += 30
	check(band.state == &"playing" and band.sounding(&"piano"), "the piano's playing (%s)" % band.state)
	check(room.mood > 0.5, "the room's lively before (%.2f)" % room.mood)
	check(room.start("laugh", &"miner"), "the miner laughs")
	await physics_frames(36)
	var laugh: Dictionary = (_brain("miner").bit as Dictionary)
	check(laugh.get("what", &"") == &"laugh", "he's laughing")
	# A gun out, by the door.
	var p := _player()
	var frame0 := Engine.get_physics_frames()
	Events.deed.emit(p, &"draw", null, p.global_position)
	var cut_s := -1.0
	var low := 1.0
	for i in 60 * 3:
		await physics_frames(1)
		if cut_s < 0.0 and laugh.get("cut", false):
			cut_s = float(Engine.get_physics_frames() - frame0) / 60.0
		low = minf(low, room.mood)
	print("  the hush: %s" % [room.hush_log])
	print("  laugh cut after %.2f s; mood down to %.2f (%s)" % [cut_s, low, room.mood_name()])
	check(cut_s >= 0.0 and cut_s <= 1.2, "the laugh stops in mid-laugh (%.2f s)" % cut_s)
	check(low < 0.08 and room.mood_name() in [&"hushed", &"tense"], "the room's hushed (%.2f, %s)" % [low, room.mood_name()])
	var turned := {}
	var looks := []
	for e: Dictionary in room.hush_log:
		turned[e.id] = e
		check(float(e.s) >= 0.15 and float(e.s) <= 1.25, "%s turned in 0.15-1.2 s (%.2f at %.1f m, %s)" % [e.id, e.s, e.d, e.how])
		if e.how == "look":
			looks.append([float(e.d), float(e.s)])
	for id: StringName in room.ins:
		check(turned.has(String(id)), "%s turned to look" % id)
	check(turned.get("miner", {}).has("s") and cut_s <= float(turned.miner.s) + 0.05, "the laugh was cut within the miner's own delay")
	looks.sort()
	if looks.size() >= 2:
		check(looks[-1][1] > looks[0][1], "the far end turns later than the near (%s)" % [looks])
	# The band: stopped, two wrong notes from the piano, its player ducked.
	check(band.state == &"hushed" and band.why == &"gun", "the band's stopped (%s %s)" % [band.state, band.why])
	check(band.wrong_notes == 2, "two wrong notes from the piano (%d)" % band.wrong_notes)
	var pb := _brain("pianist")
	check(pb.reaction.choice == &"hide" or pb.mood == CivilianBrain.Mood.COWERING, "the piano player ducks (%s)" % pb.describe())
	check(not band.can_play(&"piano"), "and he's off his keys")
	Events.deed.emit(p, &"holster", null, p.global_position)
	# Nothing follows: he comes up, the band starts again thin and a little fast, the mood climbs.
	var at_30 := -1.0
	var t := 0
	var thin := false
	while t < 60 * 170 and band.shaky_starts == 0:
		await physics_frames(30)
		t += 30
		if t == 60 * 30:
			at_30 = room.mood
	print("  the band again after %.0f s (%s); mood at 30 s %.2f, now %.2f" % [t / 60.0, band.report().get("state", ""), at_30, room.mood])
	check(band.shaky_starts == 1, "the band starts again, shakily")
	await physics_frames(20)
	thin = bool(band.players[&"piano"].joining) and not bool(band.players[&"fiddle"].joining) and float(band.players[&"fiddle"].gain) <= 0.0
	check(thin, "thin: the piano alone to begin with")
	check(band.fast or not Band.has_fast(band.tune_id), "and a little fast")
	check(at_30 >= 0.0 and at_30 < room.target * 0.5, "the mood's still low half a minute on (%.2f of %.2f)" % [at_30, room.target])
	var joined := false
	for i in 60 * 30 / 10:
		await physics_frames(10)
		joined = joined or float(band.players[&"fiddle"].gain) > 0.5
	check(joined, "the fiddle comes in after")
	check(room.mood > at_30, "the mood climbs back (%.2f from %.2f)" % [room.mood, at_30])


func test_harlan_through_the_door() -> void:
	_out()
	var room: SaloonRoom = await _night(20.4)
	var f := valley.folk
	StoryState.set_fact("nolaw.deputy", true)
	for id: StringName in f.regard.people():
		f.regard.view_of[id] = "stopped_a_killer"
	check(f.regard.town_band() == &"warm", "the town's warm (%s)" % f.regard.town_band())
	_stand(14.2, 3.0, 8.0, 7.0)
	await physics_frames(60 * 6)
	var hails := room.log.filter(func(b: Dictionary) -> bool: return b.what == &"hail" and (b.others as Array).has("you"))
	print("  warm: %s" % [room.log.map(func(b: Dictionary) -> String: return "%s %s '%s'" % [b.what, b.get("by", ""), b.get("say", "")])])
	check(hails.size() == 1, "warm: one man hails him as he comes in (%d)" % hails.size())
	if not hails.is_empty():
		check(String(hails[0].say) in ["Deputy.", "Evening, Deputy."], "the hail is 'Deputy' (%s)" % hails[0].say)
		check(room.ins.has(StringName(String(hails[0].by))), "from a man who's there (%s)" % hails[0].by)
	# At the bar by the barkeep: a glass set down unasked.
	var bk := f.folk_man(&"barkeep")
	var at := f.hall_point("saloon", [3.3, 0.95, 4.0])  # before him at the bar (his barman_a)
	_player().global_position = at + Vector3.UP * 0.1
	_player().rotation.y = atan2(-(bk.global_position.x - at.x), -(bk.global_position.z - at.z))
	await physics_frames(60 * 8)
	check(room.glass != null and is_instance_valid(room.glass), "the barkeep's set a glass down")
	if room.glass != null and is_instance_valid(room.glass):
		var g := room.glass.global_position
		check(g.distance_to(bk.global_position) < 1.6 and g.y > bk.global_position.y + 0.8, "on the bar before him (%s)" % g)
	check(room.sounds.any(func(s: Dictionary) -> bool: return s.sound == "glass_down" and s.by == "barkeep"), "its sound is his")
	var n := room.log.filter(func(b: Dictionary) -> bool: return b.what == &"glass").size()
	await physics_frames(60 * 5)
	check(room.log.filter(func(b: Dictionary) -> bool: return b.what == &"glass").size() == n and n == 1, "once a night (%d)" % n)

	# Out, and the town turned cold: back in, the talk drops.
	_out()
	for id: StringName in f.regard.people():
		f.regard.view_of[id] = "shot_a_man"
	room._entered_at = -INF
	await physics_frames(60 * 3)
	check(f.regard.town_band() in [&"cold", &"afraid"], "the town's cold (%s)" % f.regard.town_band())
	var before := room.mood
	_stand(14.2, 3.0, 8.0, 7.0)
	await physics_frames(60 * 2)
	var drops := room.log.filter(func(b: Dictionary) -> bool: return b.what == &"drop")
	print("  cold: mood %.2f from %.2f (%s) %s" % [room.mood, before, room.mood_name(), drops])
	check(drops.size() == 1, "cold: the talk drops as he comes in")
	check(room.mood < before * 0.6, "the mood falls (%.2f from %.2f)" % [room.mood, before])
	check(room.mood_name() == &"tense", "the room's tense (%s)" % room.mood_name())
	var quiet := 0
	for id: StringName in room.ins:
		var b := _brain(String(id))
		if b != null and b.quiet > 0.0:
			quiet += 1
	check(quiet >= room.ins.size() - 1, "their talk's shut (%d of %d)" % [quiet, room.ins.size()])
	var hailed := false
	for b: Dictionary in room.log:
		if b.what == &"hail" and not drops.is_empty() and float(b.get("at_s", 0.0)) > float(drops[0].at_s):
			hailed = true
	check(not hailed, "and nobody hails him")
