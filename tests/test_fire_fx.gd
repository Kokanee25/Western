extends TestCase
## How a burning member's flames are drawn (the art session's ask, docs/briefs/fire-look.md): one
## sheet of fire to each of its meshes that fills more of itself as it burns, reaching over its top,
## and a sheet in an opening under a burning head. The flipbook tongues (FireFX.sheets off, kept for
## comparing): a few big tongues off its top that grow, and tongues out of the top of an opening.

var world: Node3D
var fire: FireSystem
var building: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	building = Structure.new()
	building.structure_id = &"shed"
	building.collapses = false
	world.add_child(building)
	await physics_frames(1)


func after_each() -> void:
	FireFX.sheets = true
	world.queue_free()
	await physics_frames(2)


func _flames(fx: FireFX) -> Array[GPUParticles3D]:
	var out: Array[GPUParticles3D] = []
	for e in fx._emitters:
		if is_instance_valid(e) and e is GPUParticles3D and e.has_meta(&"flame"):
			out.append(e)
	return out


func _sheets(fx: FireFX) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for e in fx._emitters:
		if is_instance_valid(e) and e is MeshInstance3D and e.has_meta(&"flame"):
			out.append(e)
	return out


func test_one_sheet_a_mesh_fills_as_it_burns_and_reaches_over_its_top() -> void:
	var wall := building.add_member("wall", &"board", &"weathered_pine", Vector3(3.0, 2.4, 0.025), Vector3(0, 1.2, 0))
	building.infer_supports()
	fire.ignite(wall)
	wall.burn_time = 0.0
	var fx := FireFX.new()
	fx.member = wall
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var sheets := _sheets(fx)
	var meshes := wall.pieces.filter(func(p: Array) -> bool: return is_instance_valid(p[0]) and p[0] is MeshInstance3D).size()
	check(sheets.size() == meshes and meshes > 0, "one sheet to each of its meshes (%d, %d)" % [sheets.size(), meshes])
	if sheets.is_empty():
		return
	var s := sheets[0]
	var catching: float = s.get_instance_shader_parameter(&"heat")
	check(is_equal_approx(catching, fire.tuning.flame_size_catching.y / fire.tuning.flame_size_alight.y), "a low fire when it catches (%.2f)" % catching)
	var size: Vector2 = s.get_instance_shader_parameter(&"size")
	check(size.x > 3.0, "as wide as the board and more (%.2f m)" % size.x)
	check(s.global_position.y + size.y > 2.4 + 1.5, "reaching well over its top (%.2f m)" % (s.global_position.y + size.y))
	check(s.global_position.y < 1.2, "from low on its face (%.2f m)" % s.global_position.y)
	wall.burn_time = fire.tuning.growth_seconds * 2.0
	fx.refresh(true, fire.tuning, true)
	check(is_equal_approx(float(s.get_instance_shader_parameter(&"heat")), 1.0), "all of it once it's fully alight")
	fx.refresh(false, fire.tuning, true)
	await physics_frames(1)
	check(not is_instance_valid(s), "gone when it's out")


func test_a_sheet_pours_out_of_the_top_of_an_opening() -> void:
	var head := building.add_member("front/door/head", &"trim", &"dark_trim", Vector3(1.2, 0.1, 0.05), Vector3(0, 2.1, 0))
	building.infer_supports()
	fire.ignite(head)
	var fx := FireFX.new()
	fx.member = head
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var below := _sheets(fx).filter(func(m: MeshInstance3D) -> bool: return m.global_position.y < 2.0)
	check(not below.is_empty(), "a sheet standing in the opening under the head")


func test_the_tongues_grow_as_it_burns_and_stay_few() -> void:
	FireFX.sheets = false
	var wall := building.add_member("wall", &"board", &"weathered_pine", Vector3(3.0, 2.4, 0.025), Vector3(0, 1.2, 0))
	building.infer_supports()
	fire.ignite(wall)
	wall.burn_time = 0.0
	var fx := FireFX.new()
	fx.member = wall
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var flames := _flames(fx)
	check(not flames.is_empty(), "it has flames")
	if flames.is_empty():
		return
	var quad := flames[0].draw_pass_1 as QuadMesh
	check(quad.size.is_equal_approx(fire.tuning.flame_size_catching), "small when it catches (%s)" % quad.size)
	for f in flames:
		check(f.amount <= fire.tuning.flames_a_member, "few tongues to a member (%d)" % f.amount)
		check(f.position.y > 1.2, "off its upper half (%.2f m up its middle at 1.2)" % f.position.y)
	wall.burn_time = fire.tuning.growth_seconds * 2.0
	fx.refresh(true, fire.tuning, true)
	check(quad.size.is_equal_approx(fire.tuning.flame_size_alight), "big once it's fully alight (%s)" % quad.size)


func test_flames_pour_out_of_the_top_of_an_opening() -> void:
	FireFX.sheets = false
	var head := building.add_member("front/door/head", &"trim", &"dark_trim", Vector3(1.2, 0.1, 0.05), Vector3(0, 2.1, 0))
	building.infer_supports()
	fire.ignite(head)
	var fx := FireFX.new()
	fx.member = head
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var below := _flames(fx).filter(func(f: GPUParticles3D) -> bool: return f.position.y < 2.1)
	check(not below.is_empty(), "tongues from under the head, out of the opening")
