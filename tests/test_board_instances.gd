extends TestCase
## Boards drawn as instances (#1262, Structure._apply_instances, PropKit.unit_board): a building's boards
## and strips shared by shape are drawn as instances of one board a metre each way, each instance's
## transform, colour and custom data what scan_wood.gdshader turns back into the board: worked out here
## as the shader does, every vertex and channel is what the batch's merge of the boards' own meshes gave.

const SpecBuilding := preload("res://src/structures/spec_building.gd")


func _building(id: StringName) -> Structure:
	var b := SpecBuilding.new()
	b.spec_path = "res://config/buildings/doctor.json"
	b.structure_id = id
	add_child(b)
	return b


## The arrays scan_wood's vertex() makes of a unit board's instance (positions in the structure).
static func _as_the_shader_draws(unit: Array, xf: Transform3D, color: Color, custom: Color) -> Dictionary:
	var size := Vector3(custom.r, custom.g, custom.b)
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var uc0: PackedFloat32Array = unit[Mesh.ARRAY_CUSTOM0]
	var uc2: PackedFloat32Array = unit[Mesh.ARRAY_CUSTOM2]
	var uv_in: PackedVector3Array = unit[Mesh.ARRAY_VERTEX]
	for i in uv_in.size():
		var p := uv_in[i] * size
		var face := uc0[i * 4 + 3]
		uv.append(Vector2(p.x, p.y) if face < 0.5 else (Vector2(p.y, p.z) if face < 1.5 else Vector2(p.x, p.z)))
		v.append(xf * p)
		c0.append_array([custom.a, uc0[i * 4 + 1], uc0[i * 4 + 2], face])
		c1.append_array([size.x, size.y, size.z, color.r])
		c2.append_array([color.g, color.b, color.a, uc2[i * 4 + 3]])
	return {"v": v, "uv": uv, "c0": c0, "c1": c1, "c2": c2}


static func _worst(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	if a.size() != b.size():
		return INF
	var w := 0.0
	for i in a.size():
		w = maxf(w, absf(a[i] - b[i]))
	return w


func test_instances_are_the_boards_own_meshes() -> void:
	var b := _building(&"doctor_instances")
	await physics_frames(2)
	var keys := b._batch_inst.keys()
	check(keys.size() > 3, "the doctor's boards are drawn as instances (%d batches)" % keys.size())
	var boards := 0
	var strips := 0
	var worst_v := 0.0
	var worst_uv := 0.0
	var worst_c := 0.0
	for key: Array in keys:
		var node := b._batches[key] as MultiMeshInstance3D
		var mm := node.multimesh
		var unit: Array = mm.mesh.surface_get_arrays(0)
		var got := {"v": PackedVector3Array(), "uv": PackedVector2Array(), "c0": PackedFloat32Array(), "c1": PackedFloat32Array(), "c2": PackedFloat32Array()}
		# Read from its buffer as the renderer does (the dummy renderer, headless, answers no get_instance_*):
		# a 3x4 transform by rows, then the colour, then the custom data.
		var buf := mm.buffer
		check_eq(buf.size(), mm.instance_count * 20, "20 floats an instance")
		for i in mm.instance_count:
			var f := buf.slice(i * 20, i * 20 + 20)
			var xf := Transform3D(Basis(Vector3(f[0], f[4], f[8]), Vector3(f[1], f[5], f[9]), Vector3(f[2], f[6], f[10])), Vector3(f[3], f[7], f[11]))
			var one := _as_the_shader_draws(unit, xf, Color(f[12], f[13], f[14], f[15]), Color(f[16], f[17], f[18], f[19]))
			for k: String in got:
				got[k].append_array(one[k])
		# As the batch's merge made them before #1262: the boards' own arrays with their own values in.
		var inputs: Variant = b._member_inputs(b._batch_members[key], null)
		var want: Array = Structure._merge_members(inputs, false)
		for m: StructureMember in b._batch_members[key]:
			if m.drawn_node().mesh.has_meta(&"strips_shared"):
				strips += 1
			else:
				boards += 1
		var wv: PackedVector3Array = want[Mesh.ARRAY_VERTEX]
		check_eq(got.v.size(), wv.size(), "as many vertices as the boards' own meshes (%s)" % [key])
		for i in mini(got.v.size(), wv.size()):
			worst_v = maxf(worst_v, (got.v[i] as Vector3).distance_to(wv[i]))
			worst_uv = maxf(worst_uv, (got.uv[i] as Vector2).distance_to((want[Mesh.ARRAY_TEX_UV] as PackedVector2Array)[i]))
		worst_c = maxf(worst_c, _worst(got.c0, want[Mesh.ARRAY_CUSTOM0]))
		worst_c = maxf(worst_c, _worst(got.c1, want[Mesh.ARRAY_CUSTOM1]))
		worst_c = maxf(worst_c, _worst(got.c2, want[Mesh.ARRAY_CUSTOM2]))
		check(mm.custom_aabb.has_point(wv[0]) and mm.custom_aabb.has_point(wv[wv.size() - 1]), "its box holds its boards")
	check(boards > 50 and strips > 0, "plain boards (%d) and strips (%d) both drawn as instances" % [boards, strips])
	check(worst_v < 0.00002, "every vertex where the board's own is (worst %.7f m)" % worst_v)
	check(worst_uv < 0.00002, "every UV the board's own (worst %.7f)" % worst_uv)
	check(worst_c < 0.000002, "seed, size, warp, nails, ground and role the board's own (worst %.8f)" % worst_c)
	check(b._inst_shadow_node != null and b._inst_shadow_node.multimesh.instance_count > boards,
			"the far lamps' shadow has a box a board")
	b.queue_free()
	await physics_frames(2)


func test_a_hit_board_leaves_its_instances_and_draws_itself() -> void:
	var b := _building(&"doctor_instances_hit")
	await physics_frames(2)
	var key: Array = b._batch_inst.keys()[0]
	var m: StructureMember = b._batch_members[key][0]
	var before: int = (b._batches[key] as MultiMeshInstance3D).multimesh.instance_count
	var own := m.drawn_node()
	check(not own.visible, "a board in its instances isn't drawn on its own")
	b.unbatch(m)
	await physics_frames(2)
	var after: int = (b._batches[key] as MultiMeshInstance3D).multimesh.instance_count if b._batches.has(key) else 0
	check(after < before, "its instances drawn without it (%d -> %d)" % [before, after])
	own = m.drawn_node()
	check(own.visible and not own.mesh.has_meta(&"board_shared") and not own.mesh.has_meta(&"strips_shared"),
			"it's drawn on its own, its own mesh")
	b.queue_free()
	await physics_frames(2)
