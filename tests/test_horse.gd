extends TestCase
## The horse (Horse, tools/blender/horse.py): a model in budget with its tack as separate meshes
## that come off, an idle that loops with the standing hooves planted, a capsule per part that
## follows his bones, and the street's horses each standing on the ground, tied at a rail.

var horse: Horse


func before_each() -> void:
	horse = Horse.new()
	add_child(horse)


func after_each() -> void:
	if is_instance_valid(horse):
		horse.queue_free()
	await physics_frames(1)


func _tris(mi: MeshInstance3D) -> int:
	var n := 0
	for s in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(s)
		n += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n


func test_the_model_is_in_budget_with_its_tack_apart() -> void:
	check(Horse.available(), "the model is built (tools/blender/horse.py)")
	for p in [&"coat", &"coat_lod", &"tack_lod"] + Horse.TACK:
		check(horse.parts.has(p), "%s is its own mesh" % p)
	var coat := _tris(horse.parts[&"coat"])
	check(coat >= 2000 and coat <= 4000, "the coat is 2-4k triangles (%d)" % coat)
	var far := _tris(horse.parts[&"coat_lod"])
	check(far <= 600, "the far coat is about 500 triangles (%d)" % far)
	check(horse.skeleton.get_bone_count() >= 30, "a whole rig (%d bones)" % horse.skeleton.get_bone_count())
	check(horse.parts[&"coat_lod"].visibility_range_begin > 0.0 and horse.parts[&"coat"].visibility_range_end > 0.0,
			"near and far coats swap with distance")


func _toe(bone: StringName, rest: Vector3) -> Vector3:
	return horse.bone_move(horse.skeleton.find_bone(bone)) * rest


func test_the_idle_loops_and_the_standing_hooves_stay_put() -> void:
	var idle := horse.animation.get_animation(&"idle")
	check(idle != null and idle.loop_mode == Animation.LOOP_LINEAR, "the idle loops")
	check_near(idle.length, 12.0, 0.01, "twelve seconds")
	var toes: Dictionary = Horse.info().get("toes", {})
	var front := {}
	var worst_front := 0.0
	var lowest := 0.0
	horse.animation.speed_scale = 1.0
	for i in 49:
		horse.animation.seek(i * 0.25, true)
		for bone: String in toes:
			var rest := Vector3(toes[bone][0], toes[bone][1], toes[bone][2])
			var p := _toe(StringName(bone), rest)
			lowest = minf(lowest, p.y)
			if bone.begins_with("hoof."):
				worst_front = maxf(worst_front, p.distance_to(rest))
	check(worst_front < 0.015, "the forehooves stay where they stand (moved %.3f m)" % worst_front)
	check(lowest > -0.015, "no hoof goes into the ground (%.3f m)" % lowest)


func test_the_head_dips_and_his_collision_follows() -> void:
	var shapes := horse.body.get_children().filter(func(c: Node) -> bool: return c is CollisionShape3D)
	check(shapes.size() >= 8, "a shape per part, not one box (%d)" % shapes.size())
	check(shapes.all(func(c: CollisionShape3D) -> bool: return c.shape is CapsuleShape3D), "capsules")
	var head := horse.body.get_node(^"head") as CollisionShape3D
	horse.animation.speed_scale = 1.0
	horse.animation.seek(1.0, true)
	horse.follow_bones()
	var up := head.position
	horse.animation.seek(7.4, true)  # the dip's bottom
	horse.follow_bones()
	check(head.position.y < up.y - 0.1, "the head's capsule goes down with the head (%.2f -> %.2f)" % [up.y, head.position.y])


func test_his_body_stops_a_ray_and_has_no_box() -> void:
	await physics_frames(2)
	var space := horse.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0.0, 1.2, 3.0), Vector3(0.0, 1.2, -3.0), Layers.WORLD)
	var hit := space.intersect_ray(q)
	check(not hit.is_empty() and hit.collider == horse.body, "a shot at his barrel meets him")
	q = PhysicsRayQueryParameters3D.create(Vector3(0.0, 0.35, 3.0), Vector3(0.0, 0.35, -3.0), Layers.WORLD)
	hit = space.intersect_ray(q)
	check(hit.is_empty(), "under his belly between his legs is open")


func test_tack_comes_off_and_goes_back() -> void:
	var saddle := horse.take_off(&"saddle")
	check(saddle != null and not horse.has_tack(&"saddle"), "the saddle comes off")
	check(horse.take_off(&"saddle") == null, "and only once")
	check(saddle.get_child_count() >= 2, "a loose body with its mesh and shape")
	horse.put_on(&"saddle")
	check(horse.has_tack(&"saddle"), "and goes back on")
	saddle.queue_free()


func test_the_streets_horses_stand_on_the_ground_tied_at_their_rails() -> void:
	horse.queue_free()
	var world := load("res://scenes/test_street.tscn").instantiate() as Node3D
	add_child(world)
	await physics_frames(3)
	var horses := world.find_children("*", "Horse", true, false)
	check(horses.size() >= 4, "the street's horses are the new horse (%d)" % horses.size())
	var ground := Ground.of(get_tree())
	var toes: Dictionary = Horse.info().get("toes", {})
	for h: Horse in horses:
		check(h.tied, "%s is tied" % h.get_path())
		var b := h.bits()
		var reach := ((b[0] + b[1]) * 0.5).distance_to(h.tie_point)
		check(reach < Horse.REIN_LENGTH, "%s's reins reach his rail (%.2f m)" % [h.get_path(), reach])
		for bone: String in toes:
			var rest := Vector3(toes[bone][0], toes[bone][1], toes[bone][2])
			var p := h.global_transform * (h.bone_move(h.skeleton.find_bone(bone)) * rest)
			var g := ground.height_at(p.x, p.z) if ground else 0.0
			check(p.y - g > -0.03 and p.y - g < 0.07, "%s's %s on the ground (%.3f m off)" % [h.name, bone, p.y - g])
	world.queue_free()
	await physics_frames(1)
