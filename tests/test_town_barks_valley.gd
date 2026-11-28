extends TestCase
## Regard and the barks in the valley (townsfolk step 9, #1152; §8's barks row): a walk down the
## town by day, stopping by each townsman in turn, with a few of them holding a view of Harlan:
## - the folk bark (TownBarks) and nobody says one line id twice; none says news he doesn't hold;
## - one bark at you a group: no two barks within the group's reach while you're stood by it;
## - what they show you (TownRegard) follows each man's band: the warm nod, the cold turn away.

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


func _put_by(man: HumanBody) -> void:
	var p := _player()
	var f := -man.global_basis.z
	f.y = 0.0
	var at := man.global_position + (f.normalized() if f.length() > 0.1 else Vector3.FORWARD) * 3.0
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-(man.global_position.x - at.x), -(man.global_position.z - at.z))


func test_a_walk_down_the_town() -> void:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 2
	clock.set_time(9.0)
	await physics_frames(1)
	f._look = 0.0
	await physics_frames(60 * 3)
	StoryState.set_fact("nolaw.deputy", true)
	var men: Array[StringName] = []
	for id: StringName in f.people:
		var p := f._person(id)
		if not p.has("act") and p.has("day") and f.state.get(id) == &"in" and f.folk_man(id) != null:
			men.append(id)
	check(men.size() >= 4, "townsfolk out on the walks at nine (%s)" % [men])
	var views := {}
	for i in men.size():
		var v: String = ["stopped_a_killer", "shot_a_man", "", ""][i % 4]
		if v != "":
			f.regard.view_of[men[i]] = v
			views[men[i]] = v
	var bark_at := []  # [time, pid, position]
	var seen := f.barks.log.size()
	var t := 0.0
	while t < 240.0:
		for id: StringName in men:
			var man := f.folk_man(id)
			if man == null or f.state.get(id) != &"in":
				continue
			_put_by(man)
			for _k in 4:
				await physics_frames(60 * 2)
				t += 2.0
				while seen < f.barks.log.size():
					var e: Array = f.barks.log[seen]
					seen += 1
					var who := f.folk_man(StringName(e[0]))
					bark_at.append([float(e[4]), e[0], e[1], who.global_position if who else Vector3.INF, e[3]])
		# Off down the street and back: the groups may greet him again.
		_player().global_position += Vector3(0, 0, 40)
		await physics_frames(30)
	var by := {}
	for e: Array in bark_at:
		var key := "%s %s" % [e[1], e[2]]
		check(not by.has(key), "%s said %s once (the walk's day)" % [e[1], e[2]])
		by[key] = true
		if String(e[2]).begins_with("harlan."):
			check(views.has(StringName(e[1])), "%s holds the news he speaks (%s)" % [e[1], e[2]])
	for i in bark_at.size():
		for j in range(i + 1, bark_at.size()):
			var a: Array = bark_at[i]
			var b: Array = bark_at[j]
			if String(a[4]) != "pass" or String(b[4]) != "pass":
				continue  # (two men talking to each other, #1184, aren't barks at you)
			if float(b[0]) - float(a[0]) < 6.0 and a[3] != Vector3.INF and b[3] != Vector3.INF and (a[3] as Vector3).distance_to(b[3]) < 3.0:
				check(false, "one bark a group: %s and %s together (%s, %s)" % [a[1], b[1], a[2], b[2]])
	check(bark_at.size() >= 2, "the town barked (%s)" % [bark_at.map(func(e: Array) -> String: return "%s:%s" % [e[1], e[2]])])
	print("  barks: %s" % [bark_at.map(func(e: Array) -> String: return "%s %s" % [e[1], e[2]])])
	print("  shown: %s" % [f.regard.log])
	var shows := {}
	for e: Array in f.regard.log:
		shows["%s %s" % [e[1], e[2]]] = true
		check(TownRegard.SHOWS[StringName(e[1])] == StringName(e[2]), "%s's %s band shows %s" % [e[0], e[1], e[2]])
	check(shows.has("warm nod"), "a warm man nodded (%s)" % [shows.keys()])
	check(shows.has("cold turn"), "a cold man turned his shoulder (%s)" % [shows.keys()])


## #1240: a man at a spot in a building's own room (`hall`: the barkeep behind saloon B's bar by day,
## #1213) is at that building for his lines: noon's street went thin with the barkeep's bar lines lost.
func test_the_barkeep_behind_saloon_bs_bar_is_at_the_saloon() -> void:
	var f := valley.folk
	var clock := valley.get_node(^"DayCycle") as DayCycle
	clock.day = 2
	clock.set_time(12.0)
	await physics_frames(1)
	check(String(f.block_now(f._person(&"barkeep"), f.hour()).get("at", "")) == "bar_back_day", "at noon the barkeep's at saloon B's bar")
	var ctx := f.bark_ctx(&"barkeep", f.folk_man(&"barkeep"))
	check((ctx.at as Array).has("saloon"), "behind saloon B's bar he's at the saloon (%s)" % [ctx.at])
	var ids: Array = TownBarks.fitting("pass", ctx)
	check(ids.has("bar.day"), "his bar's lines are his to say by day (%s)" % [ids])


## #1184 (gate round 2: 1 line in ten minutes at 07:00, 2 at noon, 4 at 17:30): you stood about the
## store and the saloon's walks for ten minutes of an ordinary day, the clock at the gate's rate:
## about a dozen lines, men to you and to each other, no man saying one line twice, no wording heard
## more than twice.
func test_ten_minutes_on_the_street_by_day() -> void:
	var total := 0
	for h: float in [7.0, 12.0, 17.5]:
		var f := valley.folk
		var clock := valley.get_node(^"DayCycle") as DayCycle
		clock.day = 2
		clock.set_time(h)
		clock.time_scale = 0.03
		await physics_frames(1)
		f._look = 0.0
		await physics_frames(60 * 3)
		var said := []
		var hook := func(who: Node, text: String) -> void:
			said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])
		Events.spoke.connect(hook)
		# Two men's talk to each other goes out as Events.overheard since #1293: it counts where you'd be shown it.
		var hook2 := func(who: Node, text: String, info: Dictionary) -> void:
			if float(info.get("clarity", 0.0)) >= float(Overheard.DIALS.min_clarity):
				said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])
		Events.overheard.connect(hook2)
		var from := f.heard.size()
		var t := 0.0
		var k := 0
		var last := &""
		while t < 600.0:
			# A minute by one man who's out (the next in turn, not the last), as the gate's players went
			# from one to the next; nobody out: up the street a minute.
			var out: Array[StringName] = []
			for id: StringName in f.people:
				var pp := f._person(id)
				if not pp.has("act") and pp.has("day") and f.state.get(id) == &"in" and f.folk_man(id) != null and id != last:
					out.append(id)
			out.sort()
			var p := _player()
			if out.is_empty():
				p.global_position = Vector3(0.0, f.ground(0.0, 0.0) + 0.1, 0.0)
			else:
				last = out[k % out.size()]
				_put_by(f.folk_man(last))
			p.velocity = Vector3.ZERO
			k += 1
			for _i in 12:
				await physics_frames(60 * 5)
				t += 5.0
		Events.spoke.disconnect(hook)
		Events.overheard.disconnect(hook2)
		clock.time_scale = 1.0
		var lines := f.heard.slice(from)
		print("  %05.2f, ten minutes: %d lines heard: %s" % [h, said.size(), said])
		# #1240: noon's ten minutes (dinner: two to five men out) say 10 or 11 by the run's timing (main before
		# #1233: 10; the town seed's fixed, the rest is the machine's speed), so a floor of 10 an hour sat on
		# the count itself. Each hour at least 8 (the gate's thin street said 1 to 4), and the day's
		# half hour about a dozen every ten minutes (below).
		check(said.size() >= 8, "%.1f h: the street talks in ten minutes (%d)" % [h, said.size()])
		total += said.size()
		var by := {}
		for e: Array in lines:
			var key := "%s %s" % [e[0], e[1]]
			check(not by.has(key), "%.1f h: %s says %s once" % [h, e[0], e[1]])
			by[key] = true
		var texts := {}
		for e: Array in said:
			texts[e[1]] = int(texts.get(e[1], 0)) + 1
		for text: String in texts:
			check(int(texts[text]) <= 2, "%.1f h: \"%s\" heard at most twice (%d)" % [h, text, texts[text]])
		if h < 17.0:
			# The next hour afresh: a new valley would cost a minute; the day moves on instead.
			f.barks.said.clear()
	check(total >= 36, "about a dozen lines every ten minutes by day (%d in thirty)" % total)
