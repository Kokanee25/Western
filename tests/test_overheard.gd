extends TestCase
## Things to listen to (#1293; Overheard, src/people/overheard.gd; the town script's `heard.*` scenes):
## - the script: every exchange is 2 to 8 lines, two or three people, each line one wording said to
##   another of its cast with a delivery, a place the board knows, an `if` the picker knows; enough
##   of them for a night out (the saloon's 40, 20 more elsewhere); nobody says Harlan's name;
## - heard by distance: whole close by, words dropping out further off, nothing past `hear_m`;
## - an evening at saloon B's bar: exchanges run in the script's order between men stood together,
##   each line out as Events.overheard with a subtitle; none twice the same night, and the save keeps it;
## - talk nobody is near isn't spent; a shot stops one mid-way; the card table's is started between
##   hands and never by the room's timer; stood at their elbow, one turns to you.

const PLACES := ["saloon.bar", "saloon.table", "saloon.room", "saloon.upstairs", "store", "street", "livery", "hotel",
		"church", "graveyard", "doctor", "smithy", "undertaker", "print_shop", "jail", "depot", "out"]
const KNOWN := ["on", "once", "regard", "fact", "day", "hour"]
## On the People board, not in the valley's day yet: their exchanges wait for them.
const NOT_YET := ["claude", "town_drunk", "runner"]

var holder: Node
var valley: ValleyWorld
var got: Array = []
var said: Array = []


func after_each() -> void:
	for pair: Array in [[Events.overheard, _on_overheard], [Events.spoke, _on_spoke]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])
	ValleyFolk.murder_auto = true
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_overheard(who: Node, text: String, info: Dictionary) -> void:
	got.append([String(who.get("person_id")), text, info.duplicate()])


func _on_spoke(who: Node, text: String) -> void:
	said.append([String(who.get("person_id")) if who.get("person_id") != null else "", text])


func test_the_script_s_exchanges_are_well_made() -> void:
	var roster := {}
	for p: Dictionary in JSON.parse_string(FileAccess.get_file_as_string(ValleyFolk.DATA)).people:
		roster[String(p.id)] = p.has("day")
	var exs := TownScript.exchanges()
	var saloon := 0
	var other := 0
	var playable := 0
	for id: String in exs:
		var ex: Dictionary = exs[id]
		var lines: Array = ex.lines
		check(lines.size() >= 2 and lines.size() <= 8, "%s: 2 to 8 lines (%d)" % [id, lines.size()])
		check((ex.cast as Array).size() in [2, 3], "%s: two or three people (%d)" % [id, (ex.cast as Array).size()])
		check(String(ex.place) in PLACES, "%s: a place the board knows (%s)" % [id, ex.place])
		check(String((ex["if"] as Dictionary).get("on", "")) == "heard", "%s: its first line's `if` is on `heard`" % id)
		for k: String in ex["if"]:
			check(k in KNOWN, "%s: a condition exchanges use (%s)" % [id, k])
		var can := true
		for who: String in ex.cast:
			check(roster.has(who) or who in NOT_YET, "%s: %s is one of the town's people" % [id, who])
			can = can and bool(roster.get(who, false))
		playable += 1 if can else 0
		var last := ""
		for i in lines.size():
			var l: Dictionary = lines[i]
			var ws := TownScript.words(String(l.id))
			check(ws.size() == 1 and String(ws[0]) != "", "%s: one wording (each line answers the last)" % l.id)
			check(String(l.who) in ex.cast and String(l.to) in ex.cast and l.who != l.to, "%s: said by one of its cast to another" % l.id)
			check(String(l.delivery) != "", "%s: a delivery, for the gestures" % l.id)
			check(String(l.who) != last, "%s: not the same man twice running" % l.id)
			last = String(l.who)
			if i > 0:
				check((TownScript.meta()[String(l.id)]["if"] as Dictionary).is_empty(), "%s: only an exchange's first line has an `if`" % l.id)
			for w: String in ws:
				check(not w.contains("Harlan"), "%s: nobody says his name" % l.id)
				check(not w.contains("{"), "%s: no slots" % l.id)
		if String(ex.place).begins_with("saloon"):
			saloon += 1
		else:
			other += 1
	check(saloon >= 40, "the saloon's bar and tables have 40 exchanges (%d)" % saloon)
	check(other >= 20, "the store, the street, the livery, the hotel and the church have 20 (%d)" % other)
	check(playable >= 60, "60 can be held by people in the valley's day now (%d)" % playable)


func test_how_clearly_it_s_heard() -> void:
	check(is_equal_approx(Overheard.clarity_of(2.0, 3.5, 10.0), 1.0), "whole close by")
	check(is_equal_approx(Overheard.clarity_of(10.0, 3.5, 10.0), 0.0), "nothing at the edge")
	check(Overheard.clarity_of(14.0, 3.5, 10.0) == 0.0, "nor past it")
	var mid := Overheard.clarity_of(6.75, 3.5, 10.0)
	check(mid > 0.45 and mid < 0.55, "half way, half (%.2f)" % mid)
	var line := "I sold him the low meadow in 'seventy-six. He paid what I asked, in gold, the same day."
	check(Overheard.garbled(line, 0.9, 0.8, 7) == line, "clear: the whole line")
	var faint := Overheard.garbled(line, 0.35, 0.8, 7)
	check(faint.contains("…") and faint.length() < line.length(), "faint: words drop out (%s)" % faint)
	check(faint == Overheard.garbled(line, 0.35, 0.8, 7), "the same words each time")
	check(not faint.contains("… …"), "a run of lost words is one gap")
	check(Overheard.garbled(line, 0.0, 0.8, 7) == "…", "nothing heard: nothing but the gap")


func _valley(hour: float) -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.day = 2
	c.set_time(hour)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(60 * 4)
	Events.overheard.connect(_on_overheard)
	Events.spoke.connect(_on_spoke)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## You stood `m` from `pid`, on the side away from `from`.
func _stand_by(pid: StringName, m: float) -> void:
	var p := _player()
	var man := valley.folk.folk_man(pid)
	var off := Vector3(0, 0, -m)
	p.global_position = man.global_position + off
	p.velocity = Vector3.ZERO
	await physics_frames(2)


func _quick(o: Overheard) -> void:
	o.d["first_s"] = [0.3, 0.6]
	o.d["rest_s"] = [3.0, 5.0]
	o.d["stagger_s"] = 1.0
	o.d["try_s"] = 0.5
	o.d["notice"] = {"m": 2.0, "s": 7.0, "chance": 0.0, "again_s": 150.0}


func test_an_evening_at_the_bar() -> void:
	await _valley(20.3)
	var folk := valley.folk
	var o := folk.overheard
	check(o != null, "the valley's folk have the listening")
	if o == null:
		return
	# Far off, nothing is spent.
	_player().global_position = folk.folk_man(&"barkeep").global_position + Vector3(0, 0, -70.0)
	_quick(o)
	await physics_frames(60 * 6)
	check(o.log.is_empty() and o.running.is_empty(), "talk nobody's near isn't held (%d lines)" % o.log.size())
	# At the bar: the men there talk.
	var bar: Array = folk.service.customer_spot() if folk.service else []
	check(not bar.is_empty(), "the bar has a place to stand")
	if bar.is_empty():
		return
	_player().global_position = bar[0]
	_player().velocity = Vector3.ZERO
	var frames := 0
	while frames < 60 * 150 and o.ended.filter(func(e: Array) -> bool: return e[1] == "done").size() < 3:
		await physics_frames(30)
		frames += 30
	var done := o.ended.filter(func(e: Array) -> bool: return e[1] == "done")
	check(done.size() >= 3, "three exchanges held to the end in %d s at the bar (%d; ended %s)" % [frames / 60, done.size(), str(o.ended)])
	check(not got.is_empty(), "each line goes out as Events.overheard")
	var by_ex := {}
	for g: Array in got:
		var ex := String(g[2].get("exchange", ""))
		if ex == "":
			continue
		if not by_ex.has(ex):
			by_ex[ex] = []
		(by_ex[ex] as Array).append(String(g[2].line))
		check(float(g[2].clarity) > 0.0, "%s is heard at the bar (clarity %.2f)" % [g[2].line, g[2].clarity])
		check(String(g[2].delivery) != "" and g[2].to is HumanBody, "%s carries its delivery and whom it's said to" % g[2].line)
		check(g[0] == String(_who_says(String(g[2].line))), "%s is said by the man it's written for" % g[2].line)
	for ex: String in by_ex:
		var want: Array = (TownScript.exchanges()[ex].lines as Array).map(func(l: Dictionary) -> String: return String(l.id))
		check(by_ex[ex] == want.slice(0, (by_ex[ex] as Array).size()), "%s runs in the script's order (%s)" % [ex, str(by_ex[ex])])
		check(String(TownScript.exchanges()[ex].place) in ["saloon.bar", "saloon.table", "saloon.room"], "%s is the saloon's" % ex)
	var ids := o.ended.map(func(e: Array) -> String: return String(e[0]))
	for id: String in ids:
		check(ids.count(id) == 1 or o.ended.filter(func(e: Array) -> bool: return e[0] == id and e[1] == "done").size() <= 1, "%s isn't held twice a night" % id)
	for e: Array in done:
		check(int(o.heard_day.get(String(e[0]), -1)) == folk.town_day(), "%s counts as heard today" % e[0])
	check(not _player().wounds.last_heard.is_empty(), "the subtitle shows what's overheard")
	# The save keeps what you've heard.
	var kept := folk.save_dict()
	check((kept.get("overheard", {}) as Dictionary).has("heard_day"), "the save holds the heard exchanges")
	var again := Overheard.new(folk, {})
	again.load_dict(kept.overheard)
	check(again.heard_day == o.heard_day, "and a load puts them back")
	for f: Array in o.fitting(folk._ran + 1000.0):
		check(not o.heard_day.has(String(f[4])) or int(o.heard_day[String(f[4])]) != folk.town_day(), "%s, heard tonight, isn't offered again" % f[4])
	# A shot stops one mid-way.
	frames = 0
	while frames < 60 * 90 and not o.running.any(func(r: Dictionary) -> bool: return int(r.said) >= 1 and int(r.i) < (r.ex.lines as Array).size()):
		await physics_frames(6)
		frames += 6
	check(not o.running.is_empty(), "another exchange under way within %d s" % (frames / 60))
	if not o.running.is_empty():
		var id := String(o.running[0].ex.id)
		var n := got.size()
		Events.shot_fired.emit(_player().global_position + Vector3.UP, Vector3.FORWARD, null)
		check(o.running.is_empty(), "a shot stops the talk")
		check(o.ended.back()[0] == id and o.ended.back()[1] == "shot", "and it's marked as cut short by the shot (%s)" % str(o.ended.back()))
		await physics_frames(60 * 6)
		check(got.slice(n).filter(func(g: Array) -> bool: return String(g[2].get("exchange", "")) == id).is_empty(), "no more of it is said")


func _who_says(line: String) -> String:
	for id: String in TownScript.exchanges():
		for l: Dictionary in TownScript.exchanges()[id].lines:
			if String(l.id) == line:
				return String(l.who)
	return ""


func test_the_card_table_and_the_turn_to_you() -> void:
	await _valley(20.3)
	var folk := valley.folk
	var o := folk.overheard
	if o == null:
		check(false, "the valley's folk have the listening")
		return
	_quick(o)
	# The card table's talk is the table's own: never the room's timer's.
	await _stand_by(&"earl", 2.5)
	await physics_frames(10)
	for f: Array in o.fitting(folk._ran):
		check(not o._at_cards(TownScript.exchanges()[String(f[4])]), "%s (the card players') isn't started by the room" % f[4])
	var hold := 0.0
	var frames := 0
	while frames < 60 * 30 and hold <= 0.0:
		hold = o.table_break(folk._ran)
		await physics_frames(20)
		frames += 20
	check(hold > 0.0 and hold <= float(o.d.table_hold_s), "between hands the table talks, and the deal waits for it (%.1f s)" % hold)
	check(o.table_talking(), "an exchange of the men sat at the cards is under way")
	if o.table_talking():
		var r: Dictionary = o.running.filter(func(x: Dictionary) -> bool: return o._at_cards(x.ex))[0]
		check((r.men as Dictionary).has(&"earl") and (r.men as Dictionary).has(&"drifter"), "between Earl and the drifter")
		check(o.table_break(folk._ran) == 0.0, "not a second one over it")
	# Stood at their elbow: one of them turns to you.
	o.stop_near(_player().global_position, 50.0, "shout", folk._ran)
	await _stand_by(&"liveryman", 6.0)
	o.d["notice"] = {"m": 2.5, "s": 0.5, "chance": 1.0, "again_s": 150.0}
	o._rest.clear()
	frames = 0
	while frames < 60 * 120 and not o.running.any(func(x: Dictionary) -> bool: return (x.men as Dictionary).has(&"liveryman") and int(x.said) >= 1):
		await physics_frames(6)
		frames += 6
	var mine := o.running.filter(func(x: Dictionary) -> bool: return (x.men as Dictionary).has(&"liveryman"))
	check(not mine.is_empty(), "the livery man and the storekeeper talk at the back table (%d s; ended %s)" % [frames / 60, str(o.ended)])
	if mine.is_empty():
		return
	said.clear()
	var ex_id := String(mine[0].ex.id)
	await _stand_by(&"liveryman", 1.2)
	await physics_frames(60 * 4)
	var e: Array = o.ended.filter(func(x: Array) -> bool: return x[0] == ex_id)
	check(not e.is_empty() and e[0][1] == "noticed", "stood at his elbow, the talk breaks off (%s)" % str(e))
	var you: Array = []
	for id: String in TownScript.meta():
		if String((TownScript.meta()[id]["if"] as Dictionary).get("on", "")) == "heard.you":
			you.append_array(TownScript.words(id))
	check(said.any(func(s: Array) -> bool: return s[1] in you), "and one of them says a word to you (%s)" % str(said))
