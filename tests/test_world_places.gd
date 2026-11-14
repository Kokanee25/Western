extends TestCase
## The valley answers with its own places (WorldPlaces; review A8, #864), not the old town's: knocked
## out in the valley you come round at its doctor's, beside the sick room's cots (else on the general
## store's walk); the outlaws' spot out in Main Street is on the valley's Main Street.

var holder: Node
var valley: ValleyWorld


func before_each() -> void:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)


func after_each() -> void:
	holder.queue_free()
	holder = null
	await physics_frames(3)


func test_knocked_out_in_the_valley_you_come_round_at_its_doctors() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Player
	check(player != null, "a player")
	if player == null:
		return
	var doctor: Node3D = valley.buildings.get("doctor")
	check(doctor != null, "the valley's doctor's is built")
	if doctor == null:
		return
	var fell := player.global_position
	var lines: Array[String] = []
	var on_shown := func(text: String) -> void: lines.append(text)
	player.wounds.shown.connect(on_shown)
	player.wounds.physiology.blood_ml = 2800.0
	await physics_frames(10)
	check(player.wounds.out_cold > 0.0, "out cold")
	await wait_until(func() -> bool: return player.wounds.physiology.is_conscious(), 60 * 8)
	check(player.wounds.physiology.is_conscious(), "comes round")
	check(player.global_position.distance_to(fell) > 50.0, "carried off from where you fell")
	# The sick room (doctor.json's rooms: x 0.1-4.0, z 8.23-11.33, the floor at 0.95).
	var local := doctor.to_local(player.global_position)
	check(local.x > 0.1 and local.x < 4.0 and local.z > 8.23 and local.z < 11.33,
			"in the doctor's sick room (%s)" % local)
	check(absf(local.y - 0.95) < 0.3, "on its floor (%.2f)" % local.y)
	player.wounds.shown.disconnect(on_shown)
	check(lines.any(func(l: String) -> bool: return l.begins_with("You come round at the doctor's")),
			"told you came round at the doctor's (%s)" % [lines])
	await physics_frames(30)
	check(player.wounds.physiology.is_conscious() and doctor.to_local(player.global_position).y > 0.6,
			"still standing in there, not fallen through (%s)" % doctor.to_local(player.global_position))


func test_without_its_doctors_the_store_walk() -> void:
	valley.buildings.erase("doctor")
	var spots := WorldPlaces.wake_spots(get_tree())
	check(spots.size() == 1, "one place left (%s)" % [spots])
	if spots.is_empty():
		return
	var lot := ValleyLayout.main().lot("general_store")
	var at: Vector3 = spots[0].at
	check(at.x > float(lot.x0) and at.x < float(lot.x1), "in front of the general store (x %.1f)" % at.x)
	check(at.z < -7.65 and at.z > -10.05, "on its walk (z %.2f)" % at.z)
	check(at.y > valley.markers.town.ground(at.x, at.z) + 0.2, "up on the boards, not the street")


func test_the_street_spot_is_on_the_valleys_main_street() -> void:
	var from := Vector3(80.0, 0.0, -9.0)
	var spot := WorldPlaces.street_spot(get_tree(), from, 12.0)
	check_near(spot.x, 92.0, 0.01, "a dozen paces east")
	check(absf(spot.z) < 1.0, "in the street's middle (z %.2f)" % spot.z)
	check_near(spot.y, valley.markers.town.surface(spot.x, spot.z), 0.01, "on the valley's ground")
	var west_end := WorldPlaces.street_spot(get_tree(), Vector3(-118.0, 0.0, 0.0), -12.0)
	check(west_end.x > -118.0, "turned back at the town's west end (%.1f)" % west_end.x)


func test_an_unknown_place_is_known_to_be_unknown() -> void:
	var l := ValleyLayout.main()
	check(l.has_place("harlan_homestead"), "a real place")
	check(not l.has_place("harlan_homstead"), "a misspelt one isn't")
