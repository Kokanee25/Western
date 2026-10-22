extends TestCase
## How a burning member's flames are drawn (the art session's ask, docs/briefs/fire-look.md): one
## sheet of fire to each of its meshes that fills more of itself as it burns, reaching over its top
## (behind a frame member, in front of a board), from partway up a wall's face and along a sloped
## rafter's middle, the roof's and the openings' shown first,
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


func test_a_frame_members_fire_is_drawn_behind_it_and_a_boards_in_front() -> void:
	var post := building.add_member("post", &"post", &"framing", Vector3(0.15, 2.4, 0.15), Vector3(0, 1.2, 0))
	var beam := building.add_member("beam", &"beam", &"framing", Vector3(6.0, 0.2, 0.15), Vector3(2.0, 2.5, 0))
	var board := building.add_member("board", &"board", &"weathered_pine", Vector3(1.0, 2.4, 0.025), Vector3(3, 1.2, 0))
	building.infer_supports()
	for m in [post, beam, board]:
		fire.ignite(m)
		var fx := FireFX.new()
		fx.member = m
		fire.add_child(fx)
		fx.refresh(true, fire.tuning, true)
		var sheets := _sheets(fx)
		check(not sheets.is_empty(), "%s has a sheet" % m.member_id)
		if sheets.is_empty():
			continue
		var behind: Variant = sheets[0].get_instance_shader_parameter(&"behind")
		var back := 0.0 if behind == null else float(behind)
		if m == board:
			check(back == 0.0, "a board's fire in front of it, so the board doesn't cut it")
		else:
			check(back == 1.0, "%s's fire behind it: the timber stands dark against its flames" % m.member_id)
			var half: Vector3 = sheets[0].get_instance_shader_parameter(&"half_box")
			check(half.x <= 0.301 and half.z <= 0.301, "pushed back by its cross section, not its length (%s)" % half)


func test_a_sloped_rafters_fire_rises_from_its_middle_and_a_walls_from_partway_up() -> void:
	# A rafter pitched 30 degrees, from 2.6 m up to 4.6 m: its box is two metres tall, but it isn't
	# standing, so its fire rises from along its middle (up through the roof), not up from its foot.
	var rafter := building.add_member("roof/rafter/00", &"rafter", &"framing", Vector3(4.0, 0.15, 0.05), Vector3(0, 3.6, 0), Basis(Vector3.BACK, deg_to_rad(30.0)))
	var board := building.add_member("wall/board", &"board", &"weathered_pine", Vector3(0.24, 3.0, 0.025), Vector3(3, 1.5, 0))
	building.infer_supports()
	for m in [rafter, board]:
		fire.ignite(m)
		var fx := FireFX.new()
		fx.member = m
		fire.add_child(fx)
		fx.refresh(true, fire.tuning, true)
		var sheets := _sheets(fx)
		check(not sheets.is_empty(), "%s has a sheet" % m.member_id)
		if sheets.is_empty():
			continue
		var foot: float = sheets[0].global_position.y
		if m == rafter:
			check(absf(foot - 3.6) < 0.2, "the rafter's fire from its middle (%.2f m, its middle 3.6)" % foot)
		else:
			check(absf(foot - 3.0 * FireFX.WALL_FOOT) < 0.05, "the board's from partway up its face (%.2f m)" % foot)


func test_the_roof_and_the_openings_show_flames_before_a_nearer_wall() -> void:
	# More burning boards near the camera than there are flames to show, and a rafter further off:
	# the rafter shows flames all the same (fire through the roof, not one more board).
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0, 1.6, 6)
	cam.make_current()
	var boards: Array[StructureMember] = []
	for i in fire.tuning.max_flames + 5:
		boards.append(building.add_member("wall/b%d" % i, &"board", &"weathered_pine", Vector3(0.24, 2.4, 0.025), Vector3(-6.0 + i * 0.25, 1.2, 0)))
	var rafter := building.add_member("roof/rafter/00", &"rafter", &"framing", Vector3(4.0, 0.15, 0.05), Vector3(0, 3.6, -3.0), Basis(Vector3.BACK, deg_to_rad(30.0)))
	building.infer_supports()
	for m in boards:
		fire.ignite(m)
	fire.ignite(rafter)
	fire._update_fx()
	check(fire._flaming.has(rafter), "the rafter shows flames though %d boards are nearer" % boards.size())
	check(fire._flaming.size() <= fire.tuning.max_flames, "still no more than %d" % fire.tuning.max_flames)


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
