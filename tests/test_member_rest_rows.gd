extends TestCase
## Members at rest as rows (#1262, StructureMember._rest_data): a batched member's mesh and shape nodes
## are freed at rest, what they were kept as data; its body keeps its shape (it's still hit and stood
## on), its batch reads it as data, and anything that asks for its nodes gets them back as they were.

const SpecBuilding := preload("res://src/structures/spec_building.gd")


func _building(id: StringName) -> Structure:
	var b := SpecBuilding.new()
	b.spec_path = "res://config/buildings/doctor.json"
	b.structure_id = id
	add_child(b)
	return b


func test_a_resting_member_is_a_row_and_comes_back_as_it_was() -> void:
	var b := _building(&"doctor_rows")
	await physics_frames(2)
	var rows := 0
	var resting := 0
	var m: StructureMember = null
	for x: StructureMember in b.get_members():
		if x.resting():
			resting += 1
			if x._rest_data != null:
				rows += 1
				if m == null and x.drawn_mesh() and x.drawn_mesh().has_meta(&"board_shared"):
					m = x
	check(resting > 1000 and rows == resting, "every resting member a row (%d of %d)" % [rows, resting])
	check(m.get_child_count() == 0 and m.pieces.is_empty(), "no nodes under it at rest")
	check(m.get_shape_owners().size() == 1, "its body keeps its shape")
	var mesh := m.drawn_mesh()
	var mat := m.drawn_material()
	var xf := m.drawn_transform()
	var board: Vector4 = m.drawn_meta(&"board", Vector4.ZERO)
	var shape: Shape3D = m.shape_owner_get_shape(m.get_shape_owners()[0], 0)
	m.realise()
	check(m.get_child_count() == 2 and m._rest_data == null, "realised: its mesh and shape nodes back")
	var mi := m.get_child(0) as MeshInstance3D
	var cs := m.get_child(1) as CollisionShape3D
	check(mi.mesh == mesh and mi.material_override == mat and mi.transform == xf, "its mesh, material and place as they were")
	check(mi.get_meta(&"board") == board, "its board's own values")
	check(cs.shape == shape, "its shape")
	check(m.pieces.size() == 1 and m.pieces[0][0] == mi and m.pieces[0][1] == cs, "its piece is them")
	check(m.get_shape_owners().size() == 1, "one shape owner, its node's")
	b.queue_free()
	await physics_frames(2)


func test_a_resting_row_is_hit_and_goes_loose() -> void:
	var b := _building(&"doctor_rows_hit")
	await physics_frames(2)
	var m: StructureMember = null
	for x: StructureMember in b.get_members():
		if x._rest_data != null:
			m = x
			break
	var from := m.global_transform * m.drawn_transform() * m.drawn_mesh().get_aabb().get_center()
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 0.0, 0.0), from + Vector3(0.0, 0.001, 0.0))
	q.hit_from_inside = true
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(q)
	check(not hit.is_empty() and hit.collider is StructureMember, "a ray finds a member there")
	check(m.world_aabb().has_point(from), "its box in the world without its nodes")
	var parts := m.take_parts()
	check(parts.size() == 2 and parts[0] is MeshInstance3D and parts[1] is CollisionShape3D, "going loose, its parts made")
	for p in parts:
		p.free()
	b.queue_free()
	await physics_frames(2)
