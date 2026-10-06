extends TestCase
## The town's layout (config/town.json): every node it names is in the street and stands where it
## says, and a place given in a building's own space turns and moves with the building.


func test_the_street_stands_where_the_layout_says() -> void:
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	add_child(street)
	await process_frames(2)
	for path: String in TownLayout.nodes():
		var node := street.get_node_or_null(NodePath(path)) as Node3D
		check(node != null, "%s is in the street" % path)
		if node:
			var want := TownLayout.transform_of(StringName(path))
			check(node.transform.origin.distance_to(want.origin) < 0.001, "%s at %s" % [path, want.origin])
	street.queue_free()
	await process_frames(2)


func test_a_place_inside_moves_with_its_building() -> void:
	# At the saloon's own floor (config/town.json raises it above the street's other walks).
	var f := float((TownLayout.entry(&"Saloon").get("set", {}) as Dictionary).get("floor_top", 0.38))
	var door := TownLayout.point(&"Saloon", Vector3(5, f, 0.9))
	var saloon := TownLayout.transform_of(&"Saloon")
	check((saloon.affine_inverse() * door).distance_to(Vector3(5, f, 0.9)) < 0.001, "the door's in the saloon's space")
	var w := Waypoints.test_street()
	check(w.points[&"saloon_door"].distance_to(door) < 0.001, "the waypoints use it")
