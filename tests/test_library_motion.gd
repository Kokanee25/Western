extends TestCase
## The library clips (LibraryMotion, issue #529; assets/animations/library/): the switch, the
## manifest, the clip a man's state picks, and that with them on a man still falls as before (the
## ragdoll's: a clip never holds a dead man up).

var world: Node3D
var was_on := false


func before_each() -> void:
	was_on = Settings.library_motion
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	ground.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	Settings.library_motion = was_on
	world.queue_free()
	await physics_frames(1)


func _man(at: Vector3) -> HumanBody:
	var m := HumanBody.new()
	m.has_gun = false
	world.add_child(m)
	m.global_position = at
	return m


func test_off_by_default_in_the_game() -> void:
	var fresh: Node = load("res://src/autoload/settings.gd").new()
	check(not fresh.library_motion, "off until Sean passes them")
	fresh.free()


func test_the_manifest_lists_every_clip_with_its_licence() -> void:
	var path := "res://assets/animations/library/manifest.json"
	check(FileAccess.file_exists(path), "the manifest is there")
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var clips: Dictionary = d.get("clips", {})
	# The basics, from CMU's motion capture since #539 (the rest of MOVES may come later: a move
	# with no clip leaves him on his pose).
	for m: StringName in [&"idle", &"walk", &"run", &"walk_back", &"strafe_l", &"strafe_r", &"crouch_walk"]:
		check(clips.has(String(m)), "%s is in the manifest" % m)
	for k: String in clips:
		var e: Dictionary = clips[k]
		check(String(e.get("licence", "")) != "", "%s says its licence" % k)
		check(String(e.get("source", "")) != "", "%s says where it's from" % k)
		check(float(e.get("length_s", 0.0)) > 0.0, "%s has a length" % k)
		check(e.has("loop"), "%s says if it loops" % k)
		var c := MotionClip.load_clip(StringName("library/" + k))
		check(c != null and c.frames.size() > 1, "%s loads" % k)
		if c != null:
			check_eq(c.loop, bool(e.loop), "%s loops as the manifest says" % k)
			if c.kind == &"gait":
				check(c.stride > 0.3, "%s has a stride (%.2f m)" % [k, c.stride])


func test_his_state_picks_the_clip() -> void:
	var ahead := Vector3(0, 0, -1.3)
	check_eq(LibraryMotion.move_for(&"stand", &"", 0.0, Vector3.ZERO), &"idle", "standing: idle")
	check_eq(LibraryMotion.move_for(&"stand", &"walk", 1.3, ahead), &"walk", "walking on")
	check_eq(LibraryMotion.move_for(&"stand", &"run", 3.5, ahead * 2.7), &"run", "running")
	check_eq(LibraryMotion.move_for(&"aim", &"walk", 1.2, Vector3(0, 0, 1.2)), &"walk_back", "backing off")
	check_eq(LibraryMotion.move_for(&"aim", &"walk", 1.2, Vector3(1.2, 0, 0.1)), &"strafe_r", "sidestepping right")
	check_eq(LibraryMotion.move_for(&"aim", &"walk", 1.2, Vector3(-1.2, 0, 0.1)), &"strafe_l", "sidestepping left")
	check_eq(LibraryMotion.move_for(&"crouch", &"", 0.0, Vector3.ZERO), &"crouch_idle", "crouched")
	check_eq(LibraryMotion.move_for(&"crouch_aim", &"walk", 0.6, ahead), &"crouch_walk", "crouched on the move")
	check_eq(LibraryMotion.move_for(&"aim", &"", 0.0, Vector3.ZERO), &"pistol_aim", "aiming")
	# Aiming, the gun arm and the trunk stay the pose's (the shot leaves down the barrel).
	var aim := LibraryMotion.mask_for(&"aim", true, false)
	for s: StringName in [&"upper_arm_r", &"forearm_r", &"hand_r", &"chest", &"abdomen", &"pelvis"]:
		check(not s in aim, "aiming, %s is the pose's" % s)
	check(&"thigh_l" in aim and &"upper_arm_l" in aim, "aiming, his legs and free arm are the clip's")
	check(LibraryMotion.mask_for(&"sit", false, false).is_empty(), "sat: none of him")
	check(not &"upper_arm_r" in LibraryMotion.mask_for(&"crouch", true, false), "crouched with a gun: his gun arm the pose's")


func test_on_he_walks_on_the_library_walk_and_off_he_doesnt() -> void:
	Settings.library_motion = true
	var m := _man(Vector3(0, 0, 10))
	await physics_frames(3)
	check(m._lib != null, "the layer's on")
	var target := m.global_position + Vector3(0, 0, -20)
	for i in 60:
		m.walk_to(target, 1.4, 1.0 / 60.0)
		await physics_frames(1)
	check_eq(m._lib.move, &"walk", "he's on the walk")
	check(m._lib.w > 0.9, "the clip has him")
	for i in 60:
		await physics_frames(1)
	check_eq(m._lib.move, &"idle", "stopped, the idle")
	Settings.library_motion = false
	await physics_frames(2)
	check(m._lib == null, "off: no layer")


## Shot dead standing and running, with the clips on and off: he goes down both ways, the clip
## lets go of him, and he ends near where he did without it.
func test_he_still_falls_as_before_with_clips_on() -> void:
	var ends := {}
	for on in [false, true]:
		Settings.library_motion = on
		for run in [false, true]:
			var m := _man(Vector3(-12.0 + (6.0 if on else 0.0) + (3.0 if run else 0.0), 0.0, 12.0))
			await physics_frames(20)
			var target := m.global_position + Vector3(0, 0, -30)
			for i in 75:
				if run:
					m.walk_to(target, 3.5, 1.0 / 60.0)
				await physics_frames(1)
			var at := m.global_position
			m.physiology._die(&"brain")
			m.go_limp()
			for i in 180:
				await physics_frames(1)
			var chest := (m.parts[&"chest"] as Node3D).global_position
			check(chest.y < 0.5, "%s %s: down (chest %.2f m up)" % ["on" if on else "off", "running" if run else "standing", chest.y])
			if on:
				check(m._lib == null or m._lib.w <= 0.01, "the clip let go of him")
			ends["%s_%s" % [on, run]] = Vector2(chest.x - at.x, chest.z - at.z)
			print("    %s %s: chest lands %s from his feet" % ["on" if on else "off", "running" if run else "standing", ends["%s_%s" % [on, run]]])
			m.queue_free()
			await physics_frames(2)
	# Running, the same fall (his speed carries him, as before). Standing, he folds where he stands
	# either way, but which way is the idle's weight then (off: back on his heels; on: the idle had
	# him on his left leg, so he goes to his left): within his own length of his feet.
	var ra: Vector2 = ends["false_true"]
	var rb: Vector2 = ends["true_true"]
	check(ra.distance_to(rb) < 0.8, "running: he lands where he did (%.2f m apart)" % ra.distance_to(rb))
	for on in [false, true]:
		var e: Vector2 = ends["%s_false" % on]
		check(e.length() < 1.2, "standing, %s: he folds where he stands (%.2f m)" % ["on" if on else "off", e.length()])
