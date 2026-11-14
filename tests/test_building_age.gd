extends TestCase
## Old buildings (BuildingAge; issue #326): years of weather and use, seeded per building. An old
## building still stands as built (a sag is a look, not a fault), the same every load; it shows
## its age where it should (the porch sags between its posts, the front leans out, boards gone and
## patched, a step cracked), and a new one is exactly as it was.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _building(id: StringName, years: float, settings := {}) -> FalseFrontBuilding:
	var b := FalseFrontBuilding.new()
	b.structure_id = id
	b.width = 7.0
	b.depth = 10.0
	b.age_years = years
	b.furnished = false
	for k in settings:
		b.set(k, settings[k])
	world.add_child(b)
	return b


func _walk(id: StringName, years: float) -> Boardwalk:
	var walk := Boardwalk.new()
	walk.structure_id = id
	walk.length = 7.0
	walk.steps = [Vector2(3.5, 1.6)]
	walk.age_years = years
	world.add_child(walk)
	return walk


func _shape(s: Structure) -> Dictionary:
	var out := {}
	for m in s.get_members():
		out[m.member_id] = m.transform
	return out


func test_old_buildings_stand_as_built() -> void:
	var made: Array[Structure] = [
		_building(&"plain", 60.0),
		_building(&"store", 60.0, {"facade": "store", "front_wood": &"store_boards"}),
		_building(&"saloon", 60.0, {"facade": "saloon", "front_wood": &"saloon_red", "batwings": true}),
		_building(&"livery", 60.0, {"gable_front": true, "porch": false, "front_windows": false,
				"door_size": Vector2(3.0, 3.0), "roof_pitch_degrees": 38.0, "sign_text": "LIVERY",
				"gable_sign": Rect2(0.45, 1.6, 2.7, 3.6)}),
		_walk(&"walk", 60.0),
	]
	for s in made:
		check(s.members_without_load_path().is_empty(), "%s: every member still has its load path" % s.structure_id)
		var a := StructuralAnalysis.new().analyse(s)
		check(a.overloaded().is_empty(), "%s: nothing overloaded: %s" % [s.structure_id, a.overloaded().slice(0, 5)])
		check(a.falling.is_empty(), "%s: nothing unsupported: %s" % [s.structure_id, a.falling.slice(0, 5)])
		check(s.settle().is_empty(), "%s: nothing comes down when it settles" % s.structure_id)


func test_any_old_building_stands() -> void:
	# Whatever the seed: what the years took never leaves a member hanging on nothing.
	for seed in 8:
		var b := _building(StringName("seed%d" % seed), 30.0 + seed * 5.0,
				{"build_seed": seed, "facade": "store" if seed % 2 else "", "width": 6.0 + seed * 0.5})
		check(b.members_without_load_path().is_empty(), "seed %d: every member still has its load path: %s" % [seed,
				b.members_without_load_path().slice(0, 4)])
		b.free()


func test_the_same_every_load() -> void:
	var a := _shape(_building(&"twin", 40.0))
	world.get_child(world.get_child_count() - 1).free()
	var b := _shape(_building(&"twin", 40.0))
	check_eq(a.size(), b.size(), "as many members")
	var same := true
	for id in a:
		if not b.has(id) or not (a[id] as Transform3D).is_equal_approx(b[id]):
			same = false
	check(same, "every member where it was")
	var twin := world.get_child(world.get_child_count() - 1) as Structure
	var other := _building(&"other", 40.0)
	check(twin.get_member(&"twin/porch/beam").get_meta(&"bent") != other.get_member(&"other/porch/beam").get_meta(&"bent"),
			"another building is old its own way")


func test_new_is_as_built() -> void:
	var young := _building(&"young", 0.0)
	check(young.get_members().all(func(m: StructureMember) -> bool:
		return not m.has_meta(&"bent") and not m.has_meta(&"newer")), "a new building: nothing bent or patched")
	BuildingAge.enabled = false
	var off := _shape(_building(&"off", 50.0))
	BuildingAge.enabled = true
	var plain := _shape(_building(&"off2", 0.0))
	check_eq(off.size(), plain.size(), "--young-town: an old building built as new")


func test_it_shows_its_age() -> void:
	var b := _building(&"old", 60.0)
	var beam := b.get_member(&"old/porch/beam")
	check(beam.has_meta(&"bent"), "the porch beam sags between its posts")
	# The beam drawn lower at its middle than at its ends.
	var mi := beam.pieces[0][0] as MeshInstance3D
	var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var mid_y := INF
	var end_y := -INF
	for v in verts:
		var p := beam.transform * v
		if absf(p.x - b.width * 0.5) < 0.3:
			mid_y = minf(mid_y, p.y)
		if absf(p.x) < 0.2:
			end_y = maxf(end_y, p.y)
	check(end_y - mid_y > 0.18 + 0.03, "the middle well down: %.3f below the end's top" % (end_y - mid_y))
	var cap := b.get_member(&"old/front/cap")
	check(cap.position.z < -0.02, "the false front leans out over the street: cap at z %.3f" % cap.position.z)
	var newer := b.get_members().filter(func(m: StructureMember) -> bool: return m.has_meta(&"newer"))
	check(newer.size() >= 2, "a stretch of wall patched in newer boards (%d)" % newer.size())
	var young := _building(&"fresh", 0.0)
	check(b.member_count() != young.member_count(), "boards gone or shutters hung: %d members, new %d" % [b.member_count(), young.member_count()])
	var shutters := b.get_members().filter(func(m: StructureMember) -> bool: return "/shutter" in String(m.member_id))
	for m: StructureMember in shutters:
		check(not m.supported_by.is_empty(), "%s hangs on the wall" % m.member_id)


func test_an_old_walk() -> void:
	var walk := _walk(&"oldwalk", 60.0)
	var pieces := walk.get_members().filter(func(m: StructureMember) -> bool: return m.has_meta(&"cracked"))
	check_eq(pieces.size(), 2, "a cracked step, in two")
	var worn := walk.get_members().filter(func(m: StructureMember) -> bool:
		return String(m.member_id).contains("/step/") and m.has_meta(&"bent"))
	check(worn.size() >= 1, "treads worn hollow")
	var steps := walk.get_members().filter(func(m: StructureMember) -> bool: return String(m.member_id).contains("/step/"))
	for m: StructureMember in steps:
		check(m.grounded, "%s stands on the ground" % m.member_id)


func test_bent_mesh_is_a_box() -> void:
	var size := Vector3(2.0, 0.2, 0.1)
	var mesh := MemberMesh.warped(size, 5, func(v: Vector3) -> Vector3: return v)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var wound := true
	for t in range(0, idx.size(), 3):
		var c := (verts[idx[t + 1]] - verts[idx[t]]).cross(verts[idx[t + 2]] - verts[idx[t]])
		if c.dot(normals[idx[t]]) >= 0.0:
			wound = false
	check(wound, "every triangle wound as BoxMesh's (faces out)")
	check(mesh.get_aabb().size.is_equal_approx(size), "its bounds the box's")
	# It joins a structure's batch with the boxes (the same arrays).
	var st := SurfaceTool.new()
	st.append_from(MemberMesh.box(size), 0, Transform3D())
	st.append_from(mesh, 0, Transform3D())
	check(st.commit().get_surface_count() == 1, "batched with plain boxes")


func test_painted_letters_stay_on_their_boards() -> void:
	# The front leans out; letters painted on its boards (FacadeArt's ink, a quad on the sign member)
	# lean with them and stay in front of every board behind them.
	for text in ["BANK", "HOTEL", "GENERAL STORE"]:
		var b := _building(StringName(text.to_snake_case()), 60.0,
				{"facade": "store", "front_wood": &"store_boards", "sign_text": text, "wall_height": 4.6, "front_height": 7.2})
		var boards := b.get_members().filter(func(m: StructureMember) -> bool:
			return BuildingAge.path_of(b, m).begins_with("front/siding/r") and not m.has_meta(&"bent"))
		var quads := 0
		var behind := 0
		for m in b.get_members():
			for c in m.get_children():
				if not (c is MeshInstance3D) or c == m.pieces[0][0]:
					continue
				quads += 1
				var mi := c as MeshInstance3D
				var box := mi.get_aabb()
				for corner in 8:
					var p := m.transform * mi.transform * box.get_endpoint(corner)
					for board: StructureMember in boards:
						var local := board.transform.affine_inverse() * p
						var half := board.size * 0.5
						if absf(local.x) < half.x and absf(local.y) < half.y and local.z > -half.z - 0.0005:
							behind += 1
		check(quads > 0, "%s: its letters are painted on" % text)
		check_eq(behind, 0, "%s: no corner of its letters behind a board's face" % text)
