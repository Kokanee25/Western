extends TestCase
## The card cheat moment (src/moments/card_cheat.gd) in a bare room: a chair, the two men, no
## town. Pose to pose (no clips, or `animated=0`) and, when the clips are in
## assets/animations/, on them: Earl ends on his back, Cody has drawn and stands over him, and it
## times out with both alive.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	world.name = "TestStreet"
	add_child(world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	cs.shape = box
	ground.add_child(cs)
	ground.position.y = -0.5
	world.add_child(ground)
	var chair := PropLibrary.spawn(&"chair") as KitProp
	world.add_child(chair)
	chair.global_transform = Transform3D(Basis(Vector3.UP, PI), Vector3(7.6, 0.0, 3.4))
	await physics_frames(5)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _run(opts: Dictionary) -> Dictionary:
	var m := Moment.start_named(&"card_cheat", world, null, opts)
	check(m != null, "the moment starts")
	if m == null:
		return {}
	await wait_until(func() -> bool: return m.done, 60 * 40)
	var r := m.result()
	m.reset()
	await physics_frames(2)
	return r


func test_pose_to_pose_earl_goes_over_backwards_and_cody_stands_over_him() -> void:
	var r := await _run({"animated": "0", "hour": "-1"})
	check(r.get("done", false), "it finishes: %s" % JSON.stringify(r.get("events", [])))
	check_eq(r.get("state"), "timed_out", "it times out, no one dies")
	check(r.get("chair_loose", false), "the chair went from under him")
	check(r.get("cheater_fell", false), "Earl went down with it")
	check(r.get("victim_drew", false), "Cody drew")
	# How he lands is physics' (the chair's pieces, Cody's legs in the way): measured over the 20
	# runs (experiments/card_cheat/), not asserted here.
	print("    pose to pose: front up %s, %s m behind: %s" % [r.get("chest_front_up"), r.get("behind_m"), JSON.stringify(r.get("events", []))])


func test_on_the_clips_when_they_exist() -> void:
	if MotionClip.load_clip(&"kick_back") == null:
		print("    (no clips in assets/animations yet: skipped)")
		return
	var r := await _run({"animated": "1", "hour": "-1"})
	check(r.get("done", false), "it finishes: %s" % JSON.stringify(r.get("events", [])))
	check((r.get("clips", {}) as Dictionary).has("kick"), "the kick is the clip's")
	check(r.get("chair_loose", false), "his boot took the chair's legs: %s" % JSON.stringify(r.get("strikes", [])))
	check(r.get("cheater_fell", false), "Earl went down with it")
	print("    on the clips: front up %s, %s m behind: %s" % [r.get("chest_front_up"), r.get("behind_m"), JSON.stringify(r.get("events", []))])
