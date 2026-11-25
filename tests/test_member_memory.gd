extends TestCase
## What a building's members cost in memory (#1259; tools/member_memory.gd): the hotel built on its own
## (the game's biggest building, 15.7k members) comes in under the frame budget's memory a member
## (config/frame_budget.tres `kb_per_member_held`, the step to `kb_per_member`), and the mesh batches'
## shadow, merged from each member's own arrays and place, is the batches' vertices as they were.

const Lib := preload("res://tools/member_memory_lib.gd")
const SpecBuilding := preload("res://src/structures/spec_building.gd")


func test_the_hotel_costs_under_the_budget_a_member() -> void:
	var fb: FrameBudget = load("res://config/frame_budget.tres")
	# What the first building loads once (scripts, materials, textures) isn't a member's: a small one first.
	await Lib.measure(self, "res://config/buildings/doctor.json")
	var r: Dictionary = await Lib.measure(self, "res://config/buildings/hotel.json")
	Lib.print_report(r)
	check(int(r.members) > 12000, "the hotel is built (%d members)" % r.members)
	check(float(r.kb_per_member) <= fb.kb_per_member_held, "%.1f KB a member, held to %.1f (the aim %.1f)" % [
			r.kb_per_member, fb.kb_per_member_held, fb.kb_per_member])


func test_the_shadow_is_the_batches_vertices() -> void:
	var b := SpecBuilding.new()
	b.spec_path = "res://config/buildings/doctor.json"
	b.structure_id = &"doctor_shadow"
	add_child(b)
	await physics_frames(2)
	var sources := 0
	var want_v := PackedVector3Array()
	var got: Array = []
	for key: Array in b._batch_arrays:
		var part: Variant = b._batch_arrays[key]
		got.append(part)
		if part is Dictionary:
			sources += 1
			# As it was before #1259: the batch's own vertices, put in the structure's space.
			var inputs: Variant = b._member_inputs(b._batch_members[key], b._batch_axes[key])
			var old: Array = Structure._in_structure(Structure._merge_members(inputs, false), b._batch_axes[key])
			want_v.append_array(old[Mesh.ARRAY_VERTEX])
		else:
			want_v.append_array((part as Array)[Mesh.ARRAY_VERTEX])
	check(sources > 0, "the board batches' shadow comes from their members (%d)" % sources)
	# (Boards shared by shape are drawn as instances since #1262: their shadow is their boxes', test_board_instances.)
	var merged: Array = Structure._merge_batches(got)
	var got_v: PackedVector3Array = merged[Mesh.ARRAY_VERTEX]
	check_eq(got_v.size(), want_v.size(), "as many shadow vertices as the batches have")
	var worst := 0.0
	for i in mini(got_v.size(), want_v.size()):
		worst = maxf(worst, got_v[i].distance_to(want_v[i]))
	check(worst < 0.0005, "every shadow vertex where its batch's is (worst %.6f m)" % worst)
	check_eq((merged[Mesh.ARRAY_NORMAL] as PackedVector3Array).size(), got_v.size(), "a normal at every vertex")
	b.queue_free()
	await physics_frames(2)
