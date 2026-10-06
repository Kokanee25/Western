extends TestCase
## Black-powder smoke drifts on the breeze outdoors, hangs indoors, fades, and the number of clouds
## (and costly fog volumes) is capped.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await process_frames(2)


func test_drifts_outdoors() -> void:
	var s := GunSmoke.spawn(world, Vector3(0, 1.5, 0), Vector3.FORWARD)
	await process_frames(120)
	var moved := s.global_position - Vector3(0, 1.5, 0)
	check(Vector2(moved.x, moved.z).length() > 0.3, "the breeze carries it off (%s)" % moved)
	check(moved.y > 0.05, "and it rises")


func test_hangs_indoors() -> void:
	var roof := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10, 0.2, 10)
	cs.shape = box
	roof.add_child(cs)
	roof.position = Vector3(0, 4, 0)
	world.add_child(roof)
	await physics_frames(2)
	var s := GunSmoke.spawn(world, Vector3(0, 1.5, 0), Vector3.FORWARD)
	await process_frames(120)
	var moved := s.global_position - Vector3(0, 1.5, 0)
	check(Vector2(moved.x, moved.z).length() < 0.1, "under a roof it barely drifts (%s)" % moved)


func test_clouds_and_fog_are_capped() -> void:
	var t: SmokeTuning = load("res://config/smoke.tres")
	for i in t.max_clouds + 4:
		GunSmoke.spawn(world, Vector3(i, 1, 0), Vector3.FORWARD)
	await process_frames(2)
	var clouds := world.find_children("*", "GunSmoke", true, false)
	check(clouds.size() <= t.max_clouds, "at most %d clouds (%d)" % [t.max_clouds, clouds.size()])
	var fogs := world.find_children("*", "FogVolume", true, false)
	check(fogs.size() <= t.max_fog_volumes, "at most %d fog volumes (%d)" % [t.max_fog_volumes, fogs.size()])
	var puffs := world.find_children("*", "GPUParticles3D", true, false)
	check(puffs.all(func(p: GPUParticles3D) -> bool: return p.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "smoke doesn't cast shadows")
