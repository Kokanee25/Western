extends TestCase
## The saloon's light (light pass round 5): the back bar's mirrors are the game's painted looking
## glass set to the room (not a metal finish on a probe taken at noon: black at night), and the
## room's reflection probe is taken again when its lamps are lit or put out, the mirrors' painted
## lamps with them.


func test_the_back_bar_mirrors_are_painted_to_the_room() -> void:
	var saloon := SaloonBuilding.new()
	saloon.structure_id = &"saloon"
	add_child(saloon)
	await physics_frames(1)
	var m := saloon.get_meta(&"mirror_look", null) as ShaderMaterial
	check(m != null and m.shader.resource_path.ends_with("mirror.gdshader"), "the painted looking glass")
	if m:
		check_near(float(m.get_shader_parameter(&"room_depth")), SaloonDressing.MIRROR_ROOM[&"room_depth"], 0.001, "the room's depth")
		check(m != PropModels.mirror(), "its own, not the kit's shared glass")
	var probe := saloon.get_node_or_null(^"RoomReflections") as RoomReflections
	check(probe != null and probe.mirrors.has(m), "the probe knows the mirrors")
	saloon.queue_free()


func test_the_room_is_taken_again_when_its_light_changes() -> void:
	check_eq(RoomReflections.state(23), 1, "night: lamps lit, no sun")
	check_eq(RoomReflections.state(12), 2, "noon: the sun, no lamps")
	check_eq(RoomReflections.state(18), 3, "dusk: both")
	check_eq(RoomReflections.state(5), 0, "before dawn: neither")
	var probe := RoomReflections.new()
	var glass := PropModels.mirror().duplicate() as ShaderMaterial
	probe.mirrors.append(glass)
	add_child(probe)
	probe._on_hour(12)
	check_eq(float(glass.get_shader_parameter(&"glow")), 0.0, "by day the mirror's lamps are out")
	probe._on_hour(23)
	check_eq(float(glass.get_shader_parameter(&"glow")), 1.0, "at night they're lit")
	check_eq(probe.update_mode, ReflectionProbe.UPDATE_ONCE, "taken once, not every frame")
	await process_frames(2)
	check_eq(probe.update_mode, ReflectionProbe.UPDATE_ALWAYS, "then taken again")
	await process_frames(3)
	check_eq(probe.update_mode, ReflectionProbe.UPDATE_ONCE, "and back to once")
	probe.queue_free()
