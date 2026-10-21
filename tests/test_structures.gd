extends TestCase
## The test street's timber is built from individual members with IDs and a support graph that
## M3 can break: every member has a load path to the ground; knock out one stud and the wall
## shrugs it off; take out the porch posts and the awning has nothing holding it up.

var store: FalseFrontBuilding


func before_each() -> void:
	store = FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	add_child(store)
	await physics_frames(2)


func after_each() -> void:
	store.queue_free()
	await process_frames(1)


func test_built_from_members() -> void:
	check(store.member_count() > 400, "hundreds of members (%d)" % store.member_count())
	for kind in [&"sill", &"joist", &"floor_board", &"stud", &"cripple", &"header", &"plate", &"rafter",
			&"ridge", &"roof_board", &"board", &"trim", &"post", &"beam", &"ledger", &"glass", &"door"]:
		check(not store.members_of_kind(kind).is_empty(), "has %s members" % kind)
	var ids := {}
	for m in store.get_members():
		check(StructureMember.TIERS.has(m.kind), "%s has a known kind" % m.member_id)
		check(String(m.member_id).begins_with("store/"), "id is namespaced")
		ids[m.member_id] = true
	check_eq(ids.size(), store.member_count(), "ids are unique")


func test_every_member_has_a_load_path() -> void:
	var falling := store.members_without_load_path()
	check(falling.is_empty(), "nothing unsupported: %s" % [falling.slice(0, 12)])


func test_other_street_structures_stand() -> void:
	for s: Structure in [Boardwalk.new(), HitchingRail.new(), WaterTrough.new()]:
		add_child(s)
		check(s.member_count() > 2, "%s has members" % s.get_script().get_global_name())
		var falling := s.members_without_load_path()
		check(falling.is_empty(), "%s all supported: %s" % [s.get_script().get_global_name(), falling.slice(0, 8)])
		s.queue_free()


func test_one_stud_is_not_missed() -> void:
	var stud := store.get_member(&"store/left/stud/05")
	check(stud != null, "left wall stud 5 exists")
	var falling := store.members_without_load_path({stud.member_id: true})
	check(falling.is_empty(), "the wall shrugs off one missing stud: %s" % [falling.slice(0, 8)])


func test_porch_loses_its_load_path() -> void:
	# Posts gone: the beam has nothing under it. (The rafters still hang off the ledger; whether
	# one end is enough is M3's job, with real load and strength.)
	var falling := store.members_without_load_path({&"store/porch/post0": true, &"store/porch/post1": true})
	check(&"store/porch/beam" in falling, "porch beam loses its load path")
	check(not &"store/roof/ridge" in falling, "the main roof still stands")
	# Posts and ledger gone: the whole awning comes down, the building stays up.
	falling = store.members_without_load_path({&"store/porch/post0": true, &"store/porch/post1": true, &"store/porch/ledger": true})
	var porch := store.get_members().filter(func(m: StructureMember) -> bool:
		return String(m.member_id).begins_with("store/porch/") and not m.kind in [&"post", &"ledger"])
	check(porch.size() > 10, "porch has rafters and boards")
	check(porch.all(func(m: StructureMember) -> bool: return m.member_id in falling), "every porch member falls")
	check(not &"store/front/sign" in falling and not &"store/roof/ridge_cap" in falling, "the store stands")


func test_supports_point_down_the_tiers() -> void:
	var rafter := store.get_member(&"store/roof/left/rafter/03")
	check(rafter != null and not rafter.supported_by.is_empty(), "a rafter rests on something")
	for id in rafter.supported_by:
		check(StructureMember.tier_of(store.get_member(id).kind) < StructureMember.tier_of(&"rafter"), "rafter rests on lower tiers")
	check(rafter.supported_by.has(&"store/left/plate"), "rafter rests on the wall plate")
	var sill := store.get_member(&"store/sill/front")
	check(sill.grounded, "sills sit on the ground")


func test_build_is_deterministic() -> void:
	var other := FalseFrontBuilding.new()
	other.structure_id = &"store"
	other.build_seed = 7
	add_child(other)
	check_eq(other.member_count(), store.member_count(), "same member count")
	var same := true
	for m in store.get_members():
		var o := other.get_member(m.member_id)
		if o == null or not o.transform.is_equal_approx(m.transform) or not o.size.is_equal_approx(m.size):
			same = false
			break
	check(same, "same members in the same places")
	check_eq(store.get_member(&"store/front/door").to_dict()["kind"], "door", "members serialise")
	other.queue_free()


func test_door_is_open_and_walkable() -> void:
	var door := store.door_rect
	var space := store.get_world_3d().direct_space_state
	for h in [0.5, 1.2, 1.9]:
		var from := store.to_global(Vector3(door.get_center().x, door.position.y + h, -1.0))
		var to := store.to_global(Vector3(door.get_center().x, door.position.y + h, 1.5))
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		check(hit.is_empty(), "clear through the doorway at %.1f m (hit %s)" % [h, hit.get("collider")])
	var wall_from := store.to_global(Vector3(0.3, 1.5, -1.0))
	var wall_to := store.to_global(Vector3(0.3, 1.5, 1.5))
	check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(wall_from, wall_to)).is_empty(), "the wall beside it is solid")


## A charge's hole in a board (Structure.cut_member): the stretch torn out flies in short pieces,
## the ends either side stay in the frame as members of their own, resting where the board rested,
## and the record of it saves.
func test_a_cut_board_keeps_its_ends_in_the_frame() -> void:
	var board: StructureMember = null
	for m in store.members_of_kind(&"floor_board"):
		if m.length() > 3.0:
			board = m
			break
	check(board != null, "a long floor board")
	var length := board.length()
	var rubble_before := store.rubble.size()
	var left := store.cut_member(board, -0.3, 0.4, Vector3.UP * 3.0)
	check(board.broken and board.has_meta(&"cut"), "the board itself is gone, its cut recorded")
	check_eq(left.size(), 2, "two ends left")
	var lengths := 0.0
	for p in left:
		check(not p.broken and store.get_member(p.member_id) == p, "%s stands, by its own id" % p.member_id)
		check(not p.supported_by.is_empty(), "%s rests on something (%s)" % [p.member_id, p.supported_by])
		lengths += p.length()
	check_near(lengths, length - 0.7, 0.001, "the ends are the board less the stretch")
	check(store.rubble.size() - rubble_before >= 2, "the stretch flies in pieces (%d)" % (store.rubble.size() - rubble_before))
	var fell := store.settle()
	for p in left:
		check(not p.broken, "%s still stands after the building settles (%s)" % [p.member_id, fell.slice(0, 6)])
	check(store.members_without_load_path().is_empty(), "nothing else lost its load path")
	var saved: Dictionary = store.to_dict()
	check(saved.cuts.has(String(board.member_id)), "the save has the cut")


func test_a_short_end_goes_with_the_stretch() -> void:
	var board: StructureMember = store.members_of_kind(&"floor_board")[5]
	var half := board.length() * 0.5
	var left := store.cut_member(board, -half + 0.05, 0.2)
	check_eq(left.size(), 1, "the 5 cm end isn't left hanging: one piece stays")
	check_near(left[0].length(), half - 0.2, 0.001, "the far end")
