extends TestCase
## A shadowed lamp draws everything in its reach six times a frame, so its shadow is only drawn
## for a camera near it, and a lamp in a building only for a camera in it or at its door
## (OilLamp.shadow_reach; the saloon's lamps seen from the street were three quarters of the
## frame's draw calls).

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
	return (lamp.find_children("*", "OmniLight3D", false, false)[0] as OmniLight3D).shadow_enabled


func test_a_lamp_shades_near_the_camera_and_not_far_off() -> void:
	var lamp := OilLamp.new()
	world.add_child(lamp)
	lamp.set_lit(true)
	cam.global_position = Vector3(0, 1.6, 5)
	await process_frames(30)
	check(_shadow(lamp), "5 m off: its shadow is drawn")
	cam.global_position = Vector3(0, 1.6, 30)
	await process_frames(30)
	check(not _shadow(lamp), "30 m off: not")
	cam.global_position = Vector3(0, 1.6, 4)
	await process_frames(30)
	check(_shadow(lamp), "back near: drawn again")


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
	check(_shadow(lamp), "inside, 2 m from it: shadows")
	cam.global_position = b.to_global(Vector3(b.width * 0.5, 1.6, -6.0))
	await process_frames(30)
	check(not _shadow(lamp), "out in the street ~10 m off: none (they're behind the walls)")
	var plain := OilLamp.new()
	world.add_child(plain)
	plain.global_position = cam.global_position + Vector3(0, 0, 8)
	plain.set_lit(true)
	await process_frames(30)
	check(_shadow(plain), "a lamp in no building, 8 m off: shadows")
