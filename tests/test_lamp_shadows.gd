extends TestCase
## A shadowed lamp draws everything in its reach six times a frame, so its full shadow (people,
## props) is drawn only for a camera near it, and a lamp in a building only for a camera in it or
## at its door; farther off only the world's layer casts it (OilLamp.shadow_reach; the saloon's
## lamps seen from the street were three quarters of the frame's draw calls). The shadow itself
## stays on, so walls still keep the light in.

var world: Node3D
var cam: Camera3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.current = true


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _shadow(lamp: OilLamp) -> bool:
	var light := lamp.find_children("*", "OmniLight3D", false, false)[0] as OmniLight3D
	check(light.shadow_enabled, "its shadow is always on (walls keep its light in)")
	return light.shadow_caster_mask != OilLamp.FAR_CASTERS


func test_a_lamp_shades_near_the_camera_and_not_far_off() -> void:
	var lamp := OilLamp.new()
	world.add_child(lamp)
	lamp.set_lit(true)
	cam.global_position = Vector3(0, 1.6, 5)
	await process_frames(30)
	check(_shadow(lamp), "5 m off: its full shadow")
	cam.global_position = Vector3(0, 1.6, 40)
	await process_frames(30)
	check(not _shadow(lamp), "40 m off: walls only")
	var light := lamp.find_children("*", "OmniLight3D", false, false)[0] as OmniLight3D
	check(light.omni_shadow_mode == OmniLight3D.SHADOW_DUAL_PARABOLOID, "and two shadow passes, not six")
	cam.global_position = Vector3(0, 1.6, 4)
	await process_frames(30)
	check(_shadow(lamp), "back near: full again")


func test_a_lamp_in_a_building_shades_only_for_a_camera_in_it() -> void:
	var b := FalseFrontBuilding.new()
	world.add_child(b)
	await physics_frames(2)
	var lamp := OilLamp.new()
	b.add_child(lamp)
	lamp.position = Vector3(b.width * 0.5, 1.6, b.depth * 0.5)
	lamp.set_lit(true)
	cam.global_position = b.to_global(Vector3(b.width * 0.5, 1.6, b.depth * 0.5 + 2.0))
	await process_frames(30)
	check(_shadow(lamp), "inside, 2 m from it: full shadow")
	cam.global_position = b.to_global(Vector3(b.width * 0.5, 1.6, -6.0))
	await process_frames(30)
	check(not _shadow(lamp), "out in the street ~10 m off: walls only (the rest is behind them)")
	var plain := OilLamp.new()
	world.add_child(plain)
	plain.global_position = cam.global_position + Vector3(0, 0, 8)
	plain.set_lit(true)
	await process_frames(30)
	check(_shadow(plain), "a lamp in no building, 8 m off: full shadow")
	var porch := OilLamp.new()
	b.add_child(porch)
	porch.position = Vector3(b.width * 0.5, 2.4, -0.4)
	porch.set_lit(true)
	cam.global_position = b.to_global(Vector3(b.width * 0.5, 1.6, -9.0))
	await process_frames(30)
	check(_shadow(porch), "a lantern hung on its porch, 9 m off in the street: full shadow (it's the street's)")


func test_from_inside_one_building_a_lamp_next_door_shades_fully() -> void:
	var a := FalseFrontBuilding.new()
	world.add_child(a)
	var b := FalseFrontBuilding.new()
	world.add_child(b)
	b.position = Vector3(a.width + 0.1, 0, 0)
	await physics_frames(2)
	var lamp := OilLamp.new()
	b.add_child(lamp)
	lamp.position = Vector3(b.width * 0.5, 1.6, b.depth * 0.5)
	lamp.set_lit(true)
	cam.global_position = a.to_global(Vector3(a.width * 0.3, 1.6, a.depth * 0.5))
	await process_frames(30)
	check(_shadow(lamp), "inside the building next door, its light shows through the boards: full shadow")
	cam.global_position = a.to_global(Vector3(a.width * 0.3, 1.6, -8.0))
	await process_frames(30)
	check(not _shadow(lamp), "out in the street: walls only")
