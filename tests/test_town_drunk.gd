extends TestCase
## The town drunk (#1312; TownDrunk, DrunkNotes; the `drunk` scene of docs/scripts/town.json):
## - the pool: 60 and more jibes, every one after the badge, his first the brevet's (once for good); the
##   britches gag his thing and not every line; never Harlan's name, Joe, a slur, Rourke, "sir", "pants";
## - the jibe fits the state: what he sees on Harlan and the town knows of his day (`you`) wins over the
##   ordinary, and a line about a thing never plays without it; sober in the morning, the sober lines;
## - no line twice in a game day, through a day of meetings; the next day they come round again;
## - in the valley: a meeting, one jibe (the brevet's first), none again standing there, another after
##   you've been off; the street answers it by its band; a shove, a drink and a walk to the jail each
##   their answer; a note goes up after its deed, and is read up close.

const SAFE_FACTS := {"nolaw.deputy": true}

var holder: Node
var valley: ValleyWorld
var said: Array = []


func before_each() -> void:
	StoryState.clear()
	said = []
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	ValleyFolk.murder_auto = true
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([who, text])


func _jibes() -> Array:
	var out: Array = []
	for id: String in TownScript.meta():
		var c: Dictionary = TownScript.meta()[id]["if"]
		if String(c.get("on", "")) in ["jibe", "jibe.first"]:
			out.append(id)
	return out


func _scene_lines() -> Array:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TownScript.PATH))
	for s: Dictionary in d.scenes:
		if String(s.id) == "drunk":
			return s.lines
	return []


func _ctx(more := {}) -> Dictionary:
	var c := {"pid": "town_drunk", "pools": ["town_drunk"], "band": "cold", "view": "", "hour": 13.0,
			"day_kind": "ordinary", "spot": "lean", "at": [], "shaken": false, "indoors": false, "opinion": {},
			"you": [], "sober": false}
	c.merge(more, true)
	return c


# --- The pool -------------------------------------------------------------------------------------------

func test_the_pool() -> void:
	var jibes := _jibes()
	check(jibes.size() >= 60, "60 and more jibes (%d)" % jibes.size())
	var britches := 0
	var bad := RegEx.create_from_string("(?i)\\b(harlan|joe|rourke|tennessee|bullshit|pants|sir|okay)\\b")
	for l: Dictionary in _scene_lines():
		var c: Dictionary = l.get("if", {})
		var on := String(c.get("on", ""))
		if on.begins_with("jibe") and on != "jibe.heard":
			check(bool((c.get("fact", {}) as Dictionary).get("nolaw.deputy", false)), "%s: only once he wears the badge" % l.id)
		if on in ["jibe", "jibe.first"] and String(l.get("gag", "")) == "britches":
			britches += 1
		for w: Dictionary in l.words:
			check(bad.search(String(w.text)) == null, "%s: nothing about Harlan by name, Joe, Rourke, no sir, no modern words (%s)" % [l.id, w.text])
	var share := float(britches) / float(jibes.size())
	check(share > 0.15 and share < 0.35, "the britches his thing, not every line (%d of %d)" % [britches, jibes.size()])
	var first: Dictionary = TownScript.meta()["drunk.brevet"]["if"]
	check(first.on == "jibe.first" and first.once == "ever", "the brevet's his first, once for good")
	for on: String in ["jibe.nod", "jibe.shake", "jibe.shove", "jibe.drink", "jibe.drink.again", "jibe.lead", "jibe.let_go", "jibe.jail", "jibe.heard"]:
		var n := 0
		for id: String in TownScript.meta():
			n += 1 if String((TownScript.meta()[id]["if"] as Dictionary).get("on", "")) == on else 0
		check(n >= 1, "an answer for %s" % on)


func test_no_jibe_before_the_badge() -> void:
	check(TownBarks.fitting("jibe.first", _ctx()).is_empty(), "no first jibe before the badge")
	check(TownBarks.fitting("jibe", _ctx({"you": ["drunk", "shot_near"]})).is_empty(), "nor any other")
	StoryState.set_fact("nolaw.deputy", true)
	check(TownBarks.fitting("jibe.first", _ctx()) == ["drunk.brevet"], "the badge on: the brevet's first")


# --- The jibe fits the state ---------------------------------------------------------------------------

func test_the_jibe_fits_the_state() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	for tag: String in ["shot_near", "fled", "running", "gun_out", "hurt", "fell", "drunk", "glass", "lost_cards",
			"won_cards", "bluffed", "shoved", "hit_man", "blast", "arrested", "round", "carrying", "noted", "jailed_him"]:
		var top := TownBarks.fitting("jibe", _ctx({"you": [tag]}))
		check(not top.is_empty(), "%s: a jibe fits" % tag)
		if top.is_empty():
			continue
		var c: Dictionary = TownScript.meta()[top[0]]["if"]
		check((c.get("you", []) as Array).has(tag), "%s: the one about it comes first (%s)" % [tag, top[0]])
	# A thing never said without it.
	for id: String in TownBarks.fitting("jibe", _ctx()):
		var c: Dictionary = TownScript.meta()[id]["if"]
		for t: String in c.get("you", []):
			check(t.begins_with("!"), "%s: nothing about what he hasn't seen (%s)" % [id, t])
	# The story: the sheriff dead, his lines; No Justice's arrest.
	StoryState.set_fact("nolaw.sheriff", "dead")
	var all := TownBarks.fitting("jibe", _ctx())
	check(all.has("drunk.boots") and all.has("drunk.peach"), "the sheriff dead: his lines fit")
	StoryState.set_fact("nojustice.ending", "arrest")
	check(TownBarks.fitting("jibe", _ctx()).has("drunk.prisoners"), "the arrest: its line fits")
	# Blood on you not yours: not the 'your blood' line.
	var b := TownBarks.fitting("jibe", _ctx({"you": ["bloody"]}))
	check(not b.is_empty() and b[0] == "drunk.their_blood", "somebody else's blood (%s)" % [b.slice(0, 2)])
	check(not TownBarks.fitting("jibe", _ctx({"you": ["bloody", "hurt"]})).has("drunk.their_blood"), "his own: not that one")


func test_sober_he_says_less() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	var sober := TownBarks.fitting("jibe", _ctx({"sober": true, "hour": 9.5, "band": "wary"}))
	check(not sober.is_empty(), "sober in the morning, a line (%s)" % [sober])
	for id: String in sober:
		check(bool((TownScript.meta()[id]["if"] as Dictionary).get("sober", false)), "%s: a sober line, sober" % id)
	check(not TownBarks.fitting("jibe", _ctx({"hour": 9.5})).has("drunk.morning"), "drunk, not the sober morning")


func test_no_line_twice_in_a_day() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	StoryState.set_fact("nolaw.sheriff", "dead")
	var b := TownBarks.new({"same_line_s": 600.0})
	var tags := [[], ["drunk"], [], ["shot_near"], [], ["lost_cards"], [], [], ["gun_out"], ["fell"]]
	var seen := {}
	var n := 0
	for i in 40:
		var c := _ctx({"you": tags[i % tags.size()], "hour": 10.5 + i * 0.3, "band": ["cold", "wary"][i % 2]})
		var l := b.pick("jibe.first", c, 3, i * 300.0)
		if l.is_empty():
			l = b.pick("jibe", c, 3, i * 300.0)
		if l.is_empty():
			continue
		if n == 0:
			check(l[0] == "drunk.brevet", "his first's the brevet (%s)" % l[0])
		n += 1
		check(not seen.has(l[0]), "never the same twice in a day (%s)" % l[0])
		seen[l[0]] = true
	check(n >= 35, "a day of forty meetings, forty-odd jibes (%d)" % n)
	var l2 := b.pick("jibe", _ctx(), 4, 20000.0)
	check(not l2.is_empty() and l2[0] != "drunk.brevet", "the next day they come round again, the brevet's not")
	check(b.pick("jibe.first", _ctx(), 4, 20100.0).is_empty(), "the brevet's for good")


func test_the_street_answers_by_its_band() -> void:
	StoryState.set_fact("nolaw.deputy", true)
	for band: String in ["cold", "wary", "warm"]:
		var c := _ctx({"pid": "townsman", "pools": ["townsman"], "band": band})
		var l := TownBarks.fitting("jibe.heard", c)
		check(not l.is_empty(), "%s: the street has a word for it" % band)
	check(TownBarks.fitting("jibe.heard", _ctx({"pid": "barkeep", "pools": ["barkeep", "townsman"]}))[0] == "drunk.heard.barkeep",
			"the barkeep: 'That'll do, Sarge'")


# --- In the valley ---------------------------------------------------------------------------------------

func _valley(h: float) -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	for k: String in SAFE_FACTS:
		StoryState.set_fact(k, SAFE_FACTS[k])
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.day = 3
	c.set_time(h)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(60 * 3)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _drunk() -> HumanBody:
	return valley.folk.folk_man(TownDrunk.ID)


## Stood `m` m in front of him, facing him.
func _before_him(m: float) -> void:
	var p := _player()
	var man := _drunk()
	var fwd := -man.global_basis.z
	fwd.y = 0.0
	var at := man.global_position + fwd.normalized() * m
	p.global_position = at
	p.velocity = Vector3.ZERO
	var to := man.global_position - at
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)


func _drunk_said(from := 0) -> Array:
	var out: Array = []
	for i in range(from, said.size()):
		if said[i][0] == _drunk():
			out.append(String(said[i][1]))
	return out


func test_a_meeting_a_jibe_and_the_answers() -> void:
	await _valley(13.0)
	var folk := valley.folk
	check(folk.drunk != null and folk.notes != null, "the town has its drunk")
	var man := _drunk()
	check(man != null, "he's in the street at one (%s)" % folk.state.get(TownDrunk.ID))
	if man == null:
		return
	await _before_him(4.0)
	await wait_until(func() -> bool: return not _drunk_said().is_empty(), 60 * 6)
	var first := _drunk_said()
	check(first.size() == 1 and TownScript.words("drunk.brevet").has(first[0]), "a meeting: his first, the brevet's (%s)" % [first])
	await physics_frames(60 * 8)
	check(_drunk_said().size() == 1, "stood by him: once a meeting, not every second (%s)" % [_drunk_said()])
	# The answer: a shove.
	var n := said.size()
	Events.deed.emit(_player(), &"shove", man, man.global_position)
	await physics_frames(60 * 2)
	var sh := _drunk_said(n)
	var any := false
	for id: String in ["drunk.shove", "drunk.shove_cold", "drunk.shove2"]:
		for w: String in TownScript.words(id):
			any = any or sh.has(w)
	check(any, "a shove gets its answer (%s)" % [sh])
	# Off and back: another, not the same.
	var p := _player()
	p.global_position = man.global_position + Vector3(40.0, 0.0, 0.0)
	await physics_frames(2)
	folk.drunk._away = 60.0
	await physics_frames(10)
	check(not folk.drunk.met, "off a while: the meeting's over")
	n = said.size()
	folk.drunk.did(&"lost_cards")
	await _before_him(4.0)
	await wait_until(func() -> bool: return not _drunk_said(n).is_empty(), 60 * 6)
	var again := _drunk_said(n)
	check(not again.is_empty() and again[0] != first[0], "back again: another jibe (%s)" % [again])
	var cards := TownScript.words("drunk.three_for_three") + TownScript.words("drunk.picket_fence")
	check(not again.is_empty() and cards.has(again[0]), "and it fits what the town knows: cards lost (%s)" % [again])
	# A drink stood him: a sober line, once for good, then the ordinary thanks.
	n = said.size()
	check(folk.drunk.answer(&"drink"), "a drink stood him: an answer")
	await physics_frames(3)
	var dl := _drunk_said(n)
	var sober := false
	for id: String in ["drunk.drink.walk", "drunk.drink.slow", "drunk.drink.earl", "drunk.drink.preach"]:
		for w: String in TownScript.words(id):
			sober = sober or dl.has(w)
	check(sober, "the first drink buys a rare sober line (%s)" % [dl])
	check(folk.drunk.did_today("stood"), "stood him one: counted")


func test_walked_to_the_jail() -> void:
	await _valley(14.0)
	var folk := valley.folk
	var man := _drunk()
	check(man != null, "he's out")
	if man == null:
		return
	await _before_him(2.5)
	var n := said.size()
	Events.shouted.emit(_player(), &"call_out")
	await physics_frames(3)
	check(folk.drunk.led and folk.state.get(TownDrunk.ID) == &"called", "G at him: he comes along (%s)" % folk.state.get(TownDrunk.ID))
	check(not _drunk_said(n).is_empty(), "and says so")
	# At the jail's door: in he goes, out of the world till morning.
	var door := folk.drunk.jail_door()
	man.global_position = door + Vector3(0.6, 0.0, 0.0)
	_player().global_position = door + Vector3(1.6, 0.0, 0.0)
	await physics_frames(5)
	check(folk.folk_man(TownDrunk.ID) == null, "in the jail: off the street")
	check(folk.drunk.jailed_until > folk._abs_hours(), "kept till the morning (%.1f > %.1f)" % [folk.drunk.jailed_until, folk._abs_hours()])
	check("jailed_him" in folk.drunk.you_tags(_player()), "the town knows you put him in")
	var s := folk.save_dict()
	check((s.get("drunk", {}) as Dictionary).has("jailed_until"), "saved")


func test_a_note_turns_up_after_its_deed() -> void:
	await _valley(12.0)
	var folk := valley.folk
	var notes := folk.notes
	await physics_frames(20)
	check(notes.up.has("jail_rhyme"), "the badge's first day: the jail's rhyme is chalked up (%s)" % [notes.up.keys()])
	check(not notes.up.has("wanted"), "the third day's bill not yet")
	check(not notes.up.has("card_sharps"), "the cards' note not before you've lost at them")
	folk.drunk.did(&"lost_cards")
	await physics_frames(20)
	check(not notes.up.has("card_sharps"), "not the moment you lose: he has to hear of it")
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.set_time(14.6)
	await physics_frames(20)
	# Put up where you can't see it go up: turn away if it waits on you.
	var p := _player()
	p.rotation.y += PI
	await physics_frames(20)
	check(notes.up.has("card_sharps"), "two hours on: the cards' note is up (%s)" % [notes.up.keys()])
	# Read up close.
	var node: Node3D = notes.up["jail_rhyme"]
	var normal: Vector3 = node.get_meta(&"normal")
	check(bool(node.get_meta(&"on_wall")), "the rhyme's on the jail's wall, not on a stake")
	var eye := node.global_position + normal * 1.0
	check(notes.readable_by("jail_rhyme", eye, -normal), "a pace off, looking at it: read")
	check(not notes.readable_by("jail_rhyme", node.global_position + normal * 4.0, -normal), "across the street: not")
	check(not notes.readable_by("jail_rhyme", eye, normal), "your back to it: not")
	var s := notes.to_dict()
	check((s.up_day as Dictionary).has("card_sharps"), "saved")
