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
					bark_at.append([float(e[4]), e[0], e[1], who.global_position if who else Vector3.INF])
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
