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


func test_the_street_is_not_ruled_straight() -> void:
	# Straight past the saloon and the store, then a jog north across Market Street and on west
	# bending: from the east end you can't see down it to the far end (Sean, 2026-10-23).
	for x in [-12.0, 0.0, 10.0, 25.0]:
		check(absf(TownLayout.street_z(x) - TownLayout.OLD_MIDDLE) < 0.3, "straight past the store and the saloon (x %.0f)" % x)
	var line: Array = (TownLayout.data().streets.main as Dictionary).line
	for p: Array in line:
		check_near(TownLayout.street_z(p[0]), p[1], 0.001, "through its point at x %.0f" % p[0])
	check(TownLayout.street_z(-80.0) - TownLayout.street_z(0.0) < -8.4, "its far end is out of line with its near by more than half its width")
	for x in range(-150, 60, 3):
		var turn := rad_to_deg(absf(TownLayout.street_dir(x).signed_angle_to(Vector3.RIGHT, Vector3.UP)))
		check(turn < 25.0, "it bends, never turns a corner (x %d: %.1f deg)" % [x, turn])


func test_every_front_stands_on_the_street_not_on_a_ruler() -> void:
	# Each building's front about 8.4 m off the street's middle and turned near its line, but not all
	# on one line: set back or forward, turned a degree or two.
	var offsets := []
	var turns := []
	for path: String in ["Saloon", "Store", "Telegraph", "Doctor", "Bank", "StreetDressing/Barber", "StreetDressing/Hotel",
			"StreetDressing/Livery", "StreetDressing/Jail", "StreetDressing/Assay"]:
		var e := TownLayout.entry(StringName(path))
		var w := float(e.get("width", (e.get("set", {}) as Dictionary).get("width", 10.0)))
		var t := TownLayout.transform_of(StringName(path))
		var mid := t * Vector3(w * 0.5, 0.0, 0.0)
		var off := absf(mid.z - TownLayout.street_z(mid.x))
		check(absf(off - 8.4) < 1.6, "%s's front %.1f m off the street's middle" % [path, off])
		var along := t.basis * Vector3.RIGHT
		var turn := rad_to_deg(along.signed_angle_to(TownLayout.street_dir(mid.x) * signf(along.x), Vector3.UP))
		check(absf(turn) < 4.0, "%s turned %.1f deg off the street" % [path, turn])
		offsets.append(snappedf(off, 0.1))
		turns.append(snappedf(turn, 0.5))
	var distinct := {}
	for o in offsets:
		distinct[o] = true
	check(distinct.size() >= 5, "set back and forward, not on one line (%s)" % [offsets])
	check(turns.filter(func(a: float) -> bool: return absf(a) >= 0.5).size() >= 5, "and turned a little (%s)" % [turns])


func test_the_ground_is_flat_in_town_and_climbs_west_out_of_it() -> void:
	for p: Vector2 in [Vector2(0, -8.4), Vector2(-46, -8), Vector2(-40, -22), Vector2(25, 0), Vector2(60, -8.4)]:
		check_eq(TownLayout.ground_height(p.x, p.y), 0.0, "flat in town at %s" % p)
	var h80 := TownLayout.street_point(-80.0).y
	var h120 := TownLayout.street_point(-120.0).y
	check(h80 > 0.3 and h120 > h80 and h120 < 4.0, "the street climbs west out of town (%.2f m at x -80, %.2f at -120)" % [h80, h120])
	# The flat by the creek, south of the far street, where the building lab's saloon stands.
	check_eq(TownLayout.ground_height(-72.0, 26.0), 0.0, "flat where the building lab's saloon stands")
	check_eq(TownLayout.ground_height(-60.0, 43.0), 0.0, "and at its back")
	# Never steep: a man walks it and a wagon rolls up it.
	for x in range(-160, -40, 2):
		for z in range(-40, 30, 2):
			var slope := Vector2(TownLayout.ground_height(x + 0.5, z) - TownLayout.ground_height(x - 0.5, z),
					TownLayout.ground_height(x, z + 0.5) - TownLayout.ground_height(x, z - 0.5)).length()
			if not check(slope < 0.2, "never steeper than 1 in 5 (%.2f at %d, %d)" % [slope, x, z]):
				return
