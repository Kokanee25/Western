extends TestCase
## RoomLight (issue #608 part 1): off it touches nothing; on, each lit lamp's bounce lights sit
## where its light lands and follow it (moved, put out); the room's fill goes amber and follows its
## lamps; a hole broken in a wall becomes an opening; a shot thickens the room's haze; off again
## puts back everything it changed.


func before_each() -> void:
	Settings.room_light = false
	RoomLight.active = false


func after_each() -> void:
	Settings.room_light = false


func _room(lamp_at := Vector3(3.0, 1.9, 4.5), haze := 0.0) -> Array:
	var b := FalseFrontBuilding.new()
	b.structure_id = &"lit_store"
	b.furnished = false
	b.porch = false
	b.room_haze = haze
	add_child(b)
	var lamp := OilLamp.new()
	lamp.casts_shadows = false
	b.add_child(lamp)
	lamp.position = lamp_at
	var rl := RoomLight.new()
	add_child(rl)
	await physics_frames(2)
	return [b, lamp, rl]


func _settle(rl: RoomLight) -> void:
	# A refresh first (lamps are looked at every refresh_seconds), then till nothing's waiting.
	var least := int(ceil((RoomLight.tune().refresh_seconds + 0.05) * 60.0))
	for i in 400:
		await physics_frames(1)
		await process_frames(1)
		if not rl.busy() and i > least:
			break
	await physics_frames(1)


func _tidy(parts: Array) -> void:
	Settings.room_light = false
	await process_frames(2)
	for n: Node in parts:
		n.queue_free()


func test_off_it_changes_nothing() -> void:
	var parts: Array = await _room()
	var b: FalseFrontBuilding = parts[0]
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	var colour := probe.ambient_color
	await process_frames(5)
	check(not RoomLight.active, "off by default")
	check(b.get_tree().get_nodes_in_group(&"room_light_bounce").is_empty(), "no bounce lights")
	check(b.get_tree().get_nodes_in_group(&"room_light_opening").is_empty(), "no opening lights")
	check(not probe.has_meta(&"room_light_scale"), "the fill left alone")
	check_eq(probe.ambient_color, colour, "its colour too")
	await _tidy(parts)


func test_a_lamps_bounce_lands_where_its_light_does_and_follows_it() -> void:
	var parts: Array = await _room()
	var b: FalseFrontBuilding = parts[0]
	var lamp: OilLamp = parts[1]
	var rl: RoomLight = parts[2]
	Settings.room_light = true
	await _settle(rl)
	var spots := rl.bounces_of(b)
	check(spots.size() >= 3, "floor, ceiling and wall (%d)" % spots.size())
	var floor_spot: SpotLight3D = null
	for s in spots:
		check(s.spot_angle < 90.0, "a bounce never lights the surface it comes off (%.0f)" % s.spot_angle)
		check(not s.shadow_enabled, "shadowless")
		check(s.light_energy > 0.0, "lit")
		var facing := -s.global_transform.basis.z
		if facing.y > 0.9:
			floor_spot = s
	check(floor_spot != null, "one off the floor, facing up")
	if floor_spot:
		check_near(floor_spot.global_position.x, lamp.light_position().x, 0.05, "under the lamp")
		check(floor_spot.global_position.y < b.floor_top + 0.3, "on the floor (%.2f)" % floor_spot.global_position.y)
		# Carried two metres along the room: the floor's bounce goes with it.
		lamp.position.x += 2.0
		await _settle(rl)
		var moved := false
		for s in rl.bounces_of(b):
			if (-s.global_transform.basis.z).y > 0.9 and absf(s.global_position.x - lamp.light_position().x) < 0.05:
				moved = true
		check(moved, "the floor's bounce followed the lamp")
	# Put out: no bounce left.
	lamp.set_lit(false)
	await _settle(rl)
	check(rl.bounces_of(b).is_empty(), "put out, its bounces go (%d)" % rl.bounces_of(b).size())
	# Lit again, then smashed: gone again.
	lamp.set_lit(true)
	await _settle(rl)
	check(not rl.bounces_of(b).is_empty(), "lit again, back")
	lamp.smash()  # (in the physics frame: its oil's ray)
	await _settle(rl)
	check(rl.bounces_of(b).is_empty(), "smashed, gone")
	await _tidy(parts)


func test_the_rooms_fill_goes_amber_follows_its_lamps_and_comes_back() -> void:
	var parts: Array = await _room()
	var b: FalseFrontBuilding = parts[0]
	var lamp: OilLamp = parts[1]
	var rl: RoomLight = parts[2]
	var probe := b.get_node(^"InteriorAmbient") as ReflectionProbe
	var colour := probe.ambient_color
	Settings.room_light = true
	await _settle(rl)
	var tn := RoomLight.tune()
	check_near(float(probe.get_meta(&"room_light_scale", -1.0)), tn.ambient_scale, 0.001, "the fill down to the dial with its lamp lit")
	check_eq(probe.ambient_color, tn.ambient_colour, "dark amber")
	lamp.set_lit(false)
	await _settle(rl)
	check_near(float(probe.get_meta(&"room_light_scale", -1.0)), 0.0, 0.001, "its only lamp out, no lamp fill")
	Settings.room_light = false
	await process_frames(3)
	check(not probe.has_meta(&"room_light_scale"), "off: the fill as it was")
	check_eq(probe.ambient_color, colour, "and its colour")
	check(b.get_tree().get_nodes_in_group(&"room_light_bounce").filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).is_empty(), "no bounce lights left")
	await _tidy(parts)


func test_the_door_and_windows_and_a_hole_broken_in_a_wall_let_the_sky_in() -> void:
	var parts: Array = await _room()
	var b: FalseFrontBuilding = parts[0]
	var rl: RoomLight = parts[2]
	Settings.room_light = true
	await _settle(rl)
	var kinds := rl.openings_of(b).map(func(o: Dictionary) -> StringName: return o.kind)
	check_eq(kinds.count(&"door"), 1, "the door")
	check_eq(kinds.count(&"window"), 2 if b.front_windows else 0, "the front windows")
	# A floor board broken: no opening.
	var board: StructureMember = null
	for m in b.members_of_kind(&"floor_board"):
		board = m
		break
	if board:
		b.break_member(board)
	# Everything in a patch of the left wall broken: a hole.
	var patch := Rect2(3.6, 1.0, 1.4, 1.2)
	var broke: Array[StructureMember] = []
	for m in b.get_members():
		var found := RoomLight.wall_patch(b, m.transform * AABB(-m.size * 0.5, m.size))
		if found.get("wall", &"") == &"left" and (found.rect as Rect2).intersects(patch) and m.kind != &"sill":
			broke.append(m)
	check(broke.size() >= 2, "the wall's boards and studs there (%d)" % broke.size())
	var pushes: Array[Vector3] = []
	for m in broke:
		pushes.append(Vector3.LEFT * 4.0)  # blown out into the lot
	await physics_frames(1)
	b.break_members(broke, pushes)
	# Unblasted, the pieces stand where they broke: cleared, as a charge would throw them.
	await physics_frames(3)
	for n in b.get_tree().root.find_children("*", "RigidBody3D", true, false):
		if (n as Node3D).global_position.distance_to(b.to_global(Vector3(0.0, 1.6, 4.3))) < 2.5:
			n.queue_free()
	await _settle(rl)
	var holes := rl.openings_of(b).filter(func(o: Dictionary) -> bool: return o.kind == &"hole")
	check_eq(holes.size(), 1, "one hole, in the left wall")
	if holes.size() == 1:
		check_eq(holes[0].wall, &"left", "the left wall")
		check(float(holes[0].area) > 0.3, "about the patch's size (%.2f m2)" % float(holes[0].area))
		check((holes[0].spot as SpotLight3D).get_parent() == b, "its light in the building")
	await _tidy(parts)


func test_a_shot_inside_thickens_the_rooms_haze_and_it_clears() -> void:
	var parts: Array = await _room(Vector3(3.0, 1.9, 4.5), 0.02)
	var b: FalseFrontBuilding = parts[0]
	var rl: RoomLight = parts[2]
	var haze := b.get_node_or_null(^"RoomHaze") as FogVolume
	Settings.room_light = true
	await _settle(rl)
	var inside := b.to_global(Vector3(3.0, 1.4, 4.0))
	Events.shot_fired.emit(inside, Vector3.FORWARD, null)
	Events.shot_fired.emit(b.to_global(Vector3(3.0, 1.4, -6.0)), Vector3.FORWARD, null)  # out on the street
	check_near(rl.haze_extra_of(b), RoomLight.tune().haze_per_shot, 0.0001, "one shot's haze (the street's not)")
	if haze:
		await process_frames(2)
		check((haze.material as FogMaterial).density > 0.02, "the room's fog thicker")
		Settings.room_light = false
		await process_frames(2)
		check_near((haze.material as FogMaterial).density, 0.02, 0.0001, "off: as it was")
	await _tidy(parts)


func test_the_pure_parts() -> void:
	check(RoomLight.omni_falloff(1.0, 4.0, 1.0) > RoomLight.omni_falloff(2.0, 4.0, 1.0), "falls off")
	check_near(RoomLight.omni_falloff(4.0, 4.0, 1.0), 0.0, 0.0001, "nothing at its range")
	var b := FalseFrontBuilding.new()
	b.width = 6.0
	b.depth = 9.0
	check_eq(RoomLight.wall_patch(b, AABB(Vector3(1, 1, -0.02), Vector3(0.3, 2, 0.02))).get("wall"), &"front", "a front board")
	check_eq(RoomLight.wall_patch(b, AABB(Vector3(5.95, 1, 3), Vector3(0.02, 2, 0.3))).get("wall"), &"right", "a right-hand board")
	check(RoomLight.wall_patch(b, AABB(Vector3(1, 0.3, 2), Vector3(0.15, 0.03, 4))).is_empty(), "a floor board is in no wall")
	b.free()
