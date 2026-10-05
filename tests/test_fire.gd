extends TestCase
## Fire: dry boards catch from their neighbours and flames climb; stone doesn't burn; a heavy
## timber shrugs off a little flame; charring weakens timber until what it carries brings it
## down; a building set alight burns and falls in; a lit lamp shot to pieces starts a fire.

var world: Node3D
var fire: FireSystem


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
	fire = FireSystem.new()
	world.add_child(fire)
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## Run the fire's rules for `seconds` in coarse steps (no waiting on the clock).
func _burn(seconds: float, until: Callable = func() -> bool: return false) -> float:
	var t := 0.0
	while t < seconds and not until.call():
		fire.step(0.5)
		t += 0.5
	return t


func _rig() -> Structure:
	var s := Structure.new()
	s.structure_id = &"rig"
	s.collapses = false
	world.add_child(s)
	return s


func test_boards_catch_but_stone_doesnt() -> void:
	var s := _rig()
	var a := s.add_member("a", &"board", &"weathered_pine", Vector3(0.24, 2.0, 0.025), Vector3(0, 1.0, 0))
	var b := s.add_member("b", &"board", &"weathered_pine", Vector3(0.24, 2.0, 0.025), Vector3(0.25, 1.0, 0))
	var stone := s.add_member("stone", &"board", &"stone", Vector3(0.4, 2.0, 0.4), Vector3(-0.33, 1.0, 0))
	s.infer_supports()
	fire.ignite(a)
	var t := _burn(120, func() -> bool: return b.burning)
	check(b.burning, "the next board catches")
	check(t < 60.0, "within a minute (%.0f s)" % t)
	_burn(60)
	check(not stone.burning, "stone doesn't burn")
	check(stone.temperature > 30.0, "though it gets hot (%.0f °C)" % stone.temperature)


func test_flames_climb() -> void:
	var s := _rig()
	var low := s.add_member("low", &"board", &"weathered_pine", Vector3(1.0, 0.2, 0.025), Vector3(0, 1.0, 0))
	var above := s.add_member("above", &"board", &"weathered_pine", Vector3(1.0, 0.2, 0.025), Vector3(0, 1.4, 0))
	var below := s.add_member("below", &"board", &"weathered_pine", Vector3(1.0, 0.2, 0.025), Vector3(0, 0.6, 0))
	s.infer_supports()
	fire.ignite(low)
	var t_up := _burn(200, func() -> bool: return above.burning)
	check(above.burning, "the board above catches")
	check(not below.burning, "before the one below (%.0f s)" % t_up)


func test_a_heavy_timber_shrugs_off_a_little_flame() -> void:
	var s := _rig()
	var board := s.add_member("board", &"board", &"weathered_pine", Vector3(0.24, 0.6, 0.025), Vector3(0, 0.3, 0))
	var beam := s.add_member("beam", &"beam", &"framing", Vector3(0.25, 0.25, 2.0), Vector3(0, 0.735, 0))
	s.infer_supports()
	fire.ignite(board)
	_burn(120)
	check(board.consumed, "the board burns away")
	check(not beam.burning, "the beam over it scorches but doesn't catch (%.0f °C)" % beam.temperature)


func test_char_weakens_until_it_gives() -> void:
	var s := Structure.new()
	s.structure_id = &"bridge"
	world.add_child(s)
	s.add_member("left", &"post", &"stone", Vector3(0.3, 1.0, 0.3), Vector3(-1.6, 0.5, 0))
	s.add_member("right", &"post", &"stone", Vector3(0.3, 1.0, 0.3), Vector3(1.6, 0.5, 0))
	var beam := s.add_member("beam", &"beam", &"framing", Vector3(3.5, 0.15, 0.1), Vector3(0, 1.075, 0))
	beam.extra_load = 300.0 * 9.81
	s.infer_supports()
	check(StructuralAnalysis.new().analyse(s).utilisation[beam.member_id] < 1.0, "it carries 300 kg sound")
	fire.ignite(beam)
	_burn(600, func() -> bool: return beam.broken)
	check(beam.broken, "burning, it gives way")
	check(not beam.consumed, "long before it's burnt away (char %.0f mm)" % (beam.char_depth * 1000.0))


func test_a_store_burns_down() -> void:
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await physics_frames(1)
	var rafters := store.members_of_kind(&"rafter").filter(func(m: StructureMember) -> bool:
		return String(m.member_id).begins_with("store/roof/"))
	var roof_in := func() -> bool:
		var down := 0
		for r: StructureMember in rafters:
			if r.broken:
				down += 1
		return down >= rafters.size() / 2
	fire.ignite(store.get_member(&"store/back/siding/c10_0"))
	fire.ignite(store.get_member(&"store/back/siding/c11_0"))
	var t := _burn(1800, roof_in)
	var t_down := t + _burn(1800 - t, func() -> bool:
		var n := 0
		for m in store.get_members():
			if m.broken or m.consumed:
				n += 1
		return n > store.member_count() * 0.6)
	var gone := 0
	for m in store.get_members():
		if m.broken or m.consumed:
			gone += 1
	print("  roof in after %.0f s; %d of %d members gone after %.0f s" % [t, gone, store.member_count(), t_down])
	check(roof_in.call(), "the roof comes in")
	preload("res://tests/feel.gd").within(self, "fire_store_roof_seconds", t)  # in minutes, not seconds or hours
	check(gone > store.member_count() * 0.6, "and most of it burns down (%d%%)" % (gone * 100 / store.member_count()))


func test_shooting_a_lit_lamp_starts_a_fire() -> void:
	var s := _rig()
	var floor_board := s.add_member("floor", &"floor_board", &"floor", Vector3(2.0, 0.025, 2.0), Vector3(0, 0.0125, 0))
	var lamp := OilLamp.new()
	world.add_child(lamp)
	lamp.global_position = Vector3(0, 0.9, 0)
	lamp.set_lit(true)
	await physics_frames(2)
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var b := ballistics.fire(Vector3(-5, 1.02, 0), Vector3.RIGHT, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 60)
	check(lamp.broken, "the lamp's smashed")
	check_eq(fire.spills.size(), 1, "burning oil on the floor")
	_burn(40, func() -> bool: return floor_board.burning)
	check(floor_board.burning, "and the floor catches")


func test_an_unlit_lamp_just_breaks() -> void:
	var lamp := OilLamp.new()
	world.add_child(lamp)
	await physics_frames(1)
	lamp.set_lit(false)
	lamp.smash()
	check(lamp.broken and fire.spills.is_empty(), "no flame, no fire")


func test_glass_cracks_in_the_heat() -> void:
	var s := _rig()
	var wall := s.add_member("wall", &"board", &"weathered_pine", Vector3(1.0, 0.8, 0.025), Vector3(0, 0.4, 0))
	var pane := s.add_member("pane", &"glass", &"glass", Vector3(0.8, 0.6, 0.004), Vector3(0, 1.12, 0.0))
	s.infer_supports()
	fire.ignite(wall)
	_burn(120, func() -> bool: return pane.broken)
	check(pane.broken, "the window cracks and falls out")
	check(not pane.burning, "glass doesn't burn")


func test_standing_in_it_burns() -> void:
	var s := _rig()
	var board := s.add_member("board", &"board", &"weathered_pine", Vector3(1.0, 2.0, 0.025), Vector3(0, 1.0, 0))
	s.infer_supports()
	var man := HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	man.global_position = Vector3(0, 0, -0.35)
	await physics_frames(2)
	fire.ignite(board)
	_burn(10)
	check(man.physiology.burns > 0.0, "a man standing against the burning wall is burnt (%.2f)" % man.physiology.burns)
	check(man.physiology.wound_pain > 0.0, "and it hurts")
