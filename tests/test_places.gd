extends TestCase
## The places on the test street and the links between them: every link can be walked in a
## straight line (nothing in the way at knee to chest height), and every place has floor under it.

func test_every_link_can_be_walked() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await physics_frames(5)
	# No outlaw in the way.
	for n in get_tree().get_nodes_in_group(&"people"):
		n.queue_free()
	await physics_frames(2)
	var w := Waypoints.test_street()
	var space := street.get_world_3d().direct_space_state
	var ex: Array[RID] = [(street.get_node(^"Player") as Player).get_rid()]
	var bad: Array[String] = []
	for a: StringName in w.links:
		for b: StringName in w.links[a]:
			if String(a) < String(b) and not Cover.path_clear(space, w.at(a), w.at(b), ex):
				bad.append("%s-%s" % [a, b])
	check(bad.is_empty(), "blocked links: %s" % str(bad))
	var floorless: Array[String] = []
	for n: StringName in w.points:
		if Cover._ground(space, w.at(n), ex) == null:
			floorless.append(String(n))
	check(floorless.is_empty(), "no floor under: %s" % str(floorless))
	var way := w.route(space, w.at(&"west_edge"), &"bar_1", ex)
	check(way.size() >= 4, "a way from the edge of town to the bar (%d legs)" % way.size())
	street.queue_free()
