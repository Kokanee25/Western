extends TestCase
## The saloon stair's walking ramp (SaloonDressing._stair): a slope under the treads for the
## player and people to walk up, on Layers.WALK alone, so a man falling down the stair meets the
## treads (Layers.WORLD) and not a smooth slide through their nosings (Sean, 2026-10-21).


func test_a_falling_man_meets_the_treads_and_a_walker_the_ramp() -> void:
	var saloon := SaloonBuilding.new()
	saloon.structure_id = &"saloon"
	add_child(saloon)
	await physics_frames(2)
	var ramps := saloon.find_children("StairRamp", "StaticBody3D", true, false)
	if not check_eq(ramps.size(), 1, "the stair has its ramp"):
		saloon.queue_free()
		return
	var ramp := ramps[0] as StaticBody3D
	check_eq(ramp.collision_layer, Layers.WALK, "the ramp is for walkers only")
	check(Layers.BULLETS & Layers.WALK == 0, "a ball passes through the ramp")
	var box := (ramp.get_child(0) as CollisionShape3D).shape as BoxShape3D
	var space := ramp.get_world_3d().direct_space_state
	var on_ramp_walking := 0
	var on_ramp_falling := 0
	var treads := 0
	# Down through the flight at 40 points along it, on the stair's middle line.
	for i in 40:
		var along := (float(i) + 0.5) / 40.0 - 0.5
		var top := ramp.global_transform * Vector3(along * box.size.x, 0.0, 0.0) + Vector3.UP * 0.6
		var down := top + Vector3.DOWN * 1.2
		var walk := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, down, Layers.STAND))
		if not walk.is_empty() and walk.collider == ramp:
			on_ramp_walking += 1
		# A ragdoll's parts collide with the world (and each other): what's under a falling man.
		var fall := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, down, Layers.WORLD | Layers.RAGDOLL))
		if not fall.is_empty():
			if fall.collider == ramp:
				on_ramp_falling += 1
			else:
				treads += 1
	check(on_ramp_walking >= 15, "a walker stands on the ramp over the treads' backs (%d of 40)" % on_ramp_walking)
	check_eq(on_ramp_falling, 0, "a falling man never meets the ramp")
	check(treads >= 30, "he meets the treads instead (%d of 40)" % treads)
	saloon.queue_free()
