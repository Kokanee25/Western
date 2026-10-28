extends TestCase
## A burning building drawn in its batches (#434): a heated or charred member keeps its place in
## its structure's batch, which draws its char and glow (char_batch.gdshader, the member's place
## in CUSTOM2); only the members showing flames get a FireFX; a member drawn on its own once it
## breaks keeps its char (char_overlay.gdshader, its look as instance uniforms).

var world: Node3D
var fire: FireSystem
var store: FalseFrontBuilding


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	store = FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	store.collapses = false
	world.add_child(store)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _boards(n: int) -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	for m in store.get_members():
		if m.kind == &"board" and store._batched.has(m):
			out.append(m)
			if out.size() >= n:
				break
	return out


func _look_in_batch(m: StructureMember) -> Variant:
	var key: Array = store._batched[m]
	var mat: ShaderMaterial = store._fire_mats.get(key)
	if mat == null or (store._batches[key] as MeshInstance3D).material_overlay != mat:
		return null
	var looks: PackedVector2Array = mat.get_shader_parameter(&"looks")
	return looks[(store._batch_built[key] as Array).find(m)]


func test_a_charred_member_stays_in_its_batch_and_its_batch_draws_the_char() -> void:
	var m := _boards(1)[0]
	check(m.resting(), "batched and at rest before")
	var nodes_before := store.get_child_count(true)
	m.temperature = 300.0
	m.char_depth = 0.004
	fire._fx_keys = [m]
	fire._fx_at = 0
	fire._refresh_fx(1)
	await physics_frames(2)
	check(store._batched.has(m), "still in its batch")
	check(m.resting(), "still its body alone: no mesh or shape node of its own")
	check(not fire._fx.has(m), "no FireFX: it isn't showing flames")
	var key: Array = store._batched[m]
	var mesh := (store._batches[key] as MeshInstance3D).mesh
	check(mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM2 != 0, "its batch carries each vertex's member's place")
	var want := store.fire_look(m)
	check(want.x > 0.0, "a char amount (%s)" % want)
	var got: Variant = _look_in_batch(m)
	check(got != null and (got as Vector2).is_equal_approx(want), "its batch's overlay has its look (%s, %s)" % [got, want])
	check_eq(store.get_child_count(true), nodes_before, "no nodes added to the building")


func test_only_the_members_showing_flames_have_a_fire_fx() -> void:
	var boards := _boards(fire.tuning.max_flames + 20)
	check(boards.size() > fire.tuning.max_flames, "enough boards (%d)" % boards.size())
	for m in boards:
		fire.ignite(m)
		m.temperature = 500.0
	fire._update_fx()
	fire._refresh_fx(1)
	await physics_frames(2)
	check(fire._fx.size() <= fire.tuning.max_flames, "%d FireFX, no more than %d" % [fire._fx.size(), fire.tuning.max_flames])
	var resting := boards.filter(func(m: StructureMember) -> bool: return m.resting() and store._batched.has(m)).size()
	check_eq(resting, boards.size(), "every burning board still in its batch")
	var particles := store.find_children("*", "GPUParticles3D", true, false).size()
	check(particles <= fire.tuning.max_flames, "particles only for the flames shown (%d)" % particles)
	var with_flames := 0
	for m in boards:
		var fx: Variant = fire._fx.get(m)
		if is_instance_valid(fx) and not (fx as FireFX)._emitters.is_empty():
			with_flames += 1
	check(with_flames > 0, "the flames shown are drawn (%d members)" % with_flames)
	# Put out, their FireFX go; the char stays.
	for m in boards:
		m.burning = false
		m.char_depth = 0.003
	fire._update_fx()
	fire._refresh_fx(1)
	await physics_frames(2)
	check_eq(fire._fx.size(), 0, "no FireFX once they're out")
	var got: Variant = _look_in_batch(boards[0])
	check(got != null and (got as Vector2).x > 0.0, "the char stays in the batch (%s)" % got)


func test_a_charred_member_that_breaks_keeps_its_char() -> void:
	var m := _boards(1)[0]
	m.temperature = 300.0
	m.char_depth = 0.006
	fire._show_char(m)
	await physics_frames(2)
	var want := store.fire_look(m)
	store.collapses = true
	store.break_member(m)
	await physics_frames(2)
	var meshes := 0
	for p: Array in m.pieces:
		var mi := p[0] as MeshInstance3D if is_instance_valid(p[0]) else null
		if mi == null:
			continue
		meshes += 1
		check(mi.material_overlay != null and (mi.material_overlay as ShaderMaterial).shader == Structure.CHAR_OVERLAY,
				"a piece drawn with the char overlay")
		var got: Variant = mi.get_instance_shader_parameter(&"char_amount")
		check(got != null and is_equal_approx(float(got), want.x),
				"its char amount (%s, %s)" % [mi.get_instance_shader_parameter(&"char_amount"), want.x])
	check(meshes > 0, "its pieces drawn on their own (%d)" % meshes)
