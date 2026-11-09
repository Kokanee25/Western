extends TestCase
## The clips carry the clavicles (#708): tools/blender/retarget_motion.py writes a `clavicle_r` and
## `clavicle_l` channel (the clavicle's turn from rest in the chest's frame) from every source rig
## that turns its clavicles (Uthana's and Mixamo's LeftShoulder), held to the girdle's limits the
## game holds its own drive to; a clip whose source never turns them (the CMU takes) has none; a
## man playing a clip with them has his clavicles follow it; and the library layer passes them on
## too (#715), with its arms, fading across a change of clip.

const ANIM := "res://assets/animations/"

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


## The clips the game plays, by whether their source turns its clavicles: [with, without]. With:
## every Uthana clip (the card cheat's, the chores, the walks; the library's gun moves), but a
## library clip cut to some parts only (the aim's legs: its arms are the pose's). Without: the
## library's CMU takes (B. Hahne's BVH conversion holds every clavicle at zero: the drive stays).
func _clips() -> Array:
	var with: Array[StringName] = []
	var without: Array[StringName] = []
	for f in DirAccess.get_files_at(ANIM):
		if f.ends_with(".json") and not f.begins_with("takes"):
			with.append(StringName(f.get_basename()))
	var man: Variant = JSON.parse_string(FileAccess.get_file_as_string(ANIM + "library/manifest.json"))
	for k: String in (man as Dictionary).get("clips", {}):
		var e: Dictionary = (man as Dictionary).clips[k]
		if e.has("parts") or String(e.get("source", "")).begins_with("CMU"):
			without.append(StringName("library/" + k))
		else:
			with.append(StringName("library/" + k))
	return [with, without]


func test_cmu_clips_leave_the_clavicles_to_the_drive() -> void:
	var without: Array = _clips()[1]
	check(without.size() >= 14, "the CMU clips and the aim's legs (%d)" % without.size())
	for n: StringName in without:
		var c := MotionClip.load_clip(n)
		if check(c != null and not c.frames.is_empty(), "%s loads" % n):
			check(not (c.frames[0] as Dictionary).has(&"clavicle_r") and not (c.frames[0] as Dictionary).has(&"clavicle_l"),
					"%s: no clavicle channel (the arms drive them)" % n)


## A clavicle's turn read as DeformRig.clavicle_turn builds one: [rise, forward] degrees.
func _parts(q: Quaternion, axis: Vector3) -> Vector2:
	var a := q * axis
	var rise := rad_to_deg(asin(clampf(a.y, -1.0, 1.0))) - rad_to_deg(asin(clampf(axis.y, -1.0, 1.0)))
	var fwd_axis := axis.cross(Vector3.FORWARD).normalized()
	var h0 := Vector3(axis.x, 0, axis.z)
	var h1 := Vector3(a.x, 0, a.z)
	return Vector2(rise, rad_to_deg(atan2(h0.cross(h1).dot(fwd_axis), h0.dot(h1))))


func test_every_clip_carries_both_clavicles_within_the_girdles_limits() -> void:
	var t := SkeletonTuning.shared()
	var anatomy := Anatomy.shared()
	var clips: Array = _clips()[0]
	check(clips.size() >= 12, "the Uthana clips (%d)" % clips.size())
	for n: StringName in clips:
		var c := MotionClip.load_clip(n)
		if not check(c != null and not c.frames.is_empty(), "%s loads" % n):
			continue
		var worst := Vector4.ZERO  ## up, down, forward, back
		var all := true
		for side in ["r", "l"]:
			var ends := DeformRig.clavicle_ends(anatomy, side)
			var axis := ((ends[1] as Vector3) - (ends[0] as Vector3)).normalized()
			for fr: Dictionary in c.frames:
				var q: Variant = fr.get(StringName("clavicle_" + side))
				if q == null:
					all = false
					break
				var p := _parts(q, axis)
				worst = Vector4(maxf(worst.x, p.x), maxf(worst.y, -p.x), maxf(worst.z, p.y), maxf(worst.w, -p.y))
		check(all, "%s: a clavicle_r and clavicle_l in every frame" % n)
		check(worst.x <= t.clav_rise_max + 0.5 and worst.y <= t.clav_drop_max + 0.5
				and worst.z <= t.clav_forward_max + 0.5 and worst.w <= t.clav_back_max + 0.5,
				"%s: within the limits (up %.1f, down %.1f, forward %.1f, back %.1f)" % [n, worst.x, worst.y, worst.z, worst.w])


## A bone's move from its rest, in the skeleton's space.
func _move(sk: Skeleton3D, name: String) -> Transform3D:
	var i := sk.find_bone(name)
	return sk.get_bone_global_pose(i) * sk.get_bone_global_rest(i).affine_inverse()


func test_a_man_playing_a_clip_has_his_clavicles_follow_it() -> void:
	var man := HumanBody.new()
	world.add_child(man)
	await physics_frames(2)
	var sk := man.skeleton
	var c := MotionClip.load_clip(&"stand_over")
	check(man.play_clip(&"stand_over") > 0.0, "stand_over plays")
	# Into the clip, eased fully in, where he leans down over the man on the floor (his right
	# clavicle well forward in the capture).
	await physics_frames(int(c.length() * 0.6 * 60.0))
	check_near(man._clip_w, 1.0, 1e-3, "the clip leads")
	var worst := 0.0
	var off_drive := 0.0
	for side in ["r", "l"]:
		var want: Variant = man._pose_played.get(StringName("clavicle_" + side))
		if not check(want is Quaternion, "the played frame has clavicle_" + side):
			return
		var rel := (_move(sk, "chest").basis.inverse() * _move(sk, "clavicle_" + side).basis).get_rotation_quaternion()
		worst = maxf(worst, rad_to_deg(rel.angle_to(want)))
		off_drive = maxf(off_drive, rad_to_deg((want as Quaternion).get_angle()))
	check(worst < 1.0, "his clavicles are the clip's (%.2f degrees off)" % worst)
	check(off_drive > 3.0, "and the clip turns them (%.1f degrees)" % off_drive)
	man.stop_clip()
	await physics_frames(30)
	check_near(man._clip_w, 0.0, 1e-3, "the clip let go")


# --- The library layer's clavicles (#715) -------------------------------------------------------

## A man with the gun out, walking (the library's walk_gun, which carries both channels).
func _gun_walker() -> HumanBody:
	var m := HumanBody.new()
	m.has_gun = true
	world.add_child(m)
	m.global_position = Vector3(8, 0, 10)
	await physics_frames(3)
	m.draw_gun()
	await physics_frames(30)
	var target := m.global_position + Vector3(0, 0, -20)
	for i in 50:
		m.walk_to(target, 1.4, 1.0 / 60.0)
		await physics_frames(1)
	return m


func _rel(sk: Skeleton3D, cid: String) -> Quaternion:
	return (_move(sk, "chest").basis.inverse() * _move(sk, cid).basis).get_rotation_quaternion()


func test_walking_with_the_gun_his_clavicles_follow_the_library_clip() -> void:
	var was: bool = Settings.library_motion
	Settings.library_motion = true
	var m: HumanBody = await _gun_walker()
	check_eq(m._lib.move, &"walk_gun", "the gun walk")
	check_near(m._lib.w, 1.0, 1e-3, "the layer has him")
	var seen := 0
	for cid: StringName in [&"clavicle_r", &"clavicle_l"]:
		var arm := StringName("upper_arm_" + String(cid).right(1))
		if not m._pose_lib.has(arm):
			check(not m._pose_lib.has(cid), "%s: no channel without its arm" % cid)
			continue
		if not check(m._pose_lib.has(cid), "%s: the layer passes the channel with its arm" % cid):
			continue
		seen += 1
		check_near(float(m._lib.clav_k.get(cid, 0.0)), 1.0, 1e-3, "%s: wholly the clip's after the crossing" % cid)
		var off := rad_to_deg(_rel(m.skeleton, String(cid)).angle_to(m._pose_lib[cid]))
		check(off < 1.0, "%s: his clavicle is the clip's (%.2f degrees off)" % [cid, off])
	check(seen >= 1, "at least one side's clavicle led by the clip (%d)" % seen)
	Settings.library_motion = was


func test_aiming_the_gun_arms_clavicle_stays_the_drives() -> void:
	var was: bool = Settings.library_motion
	Settings.library_motion = true
	var m: HumanBody = await _gun_walker()
	m.set_pose(&"aim")
	await physics_frames(30)
	check(not m._pose_lib.has(&"upper_arm_r") and not m._pose_lib.has(&"clavicle_r"),
			"aiming, the gun arm and its clavicle aren't the clip's")
	Settings.library_motion = was


func test_the_cmu_walk_has_no_channel_and_a_crossing_fades_it_in() -> void:
	var was: bool = Settings.library_motion
	Settings.library_motion = true
	var m := HumanBody.new()
	m.has_gun = false
	world.add_child(m)
	await physics_frames(3)
	m._lib.force = &"walk"
	await physics_frames(40)
	check(not m._pose_lib.has(&"clavicle_r") and not m._pose_lib.has(&"clavicle_l"), "the CMU walk: no channel")
	m._lib.force = &"walk_gun"
	await physics_frames(3)
	var early := float(m._lib.clav_k.get(&"clavicle_r", 0.0))
	check(m._pose_lib.has(&"clavicle_r"), "crossing to the gun walk, its channel comes in")
	check(early > 0.0 and early < 0.5, "faded in over the crossing, not at once (%.2f)" % early)
	await physics_frames(30)
	check_near(float(m._lib.clav_k.get(&"clavicle_r", 0.0)), 1.0, 1e-3, "after the crossing, wholly the clip's")
	m._lib.force = &"walk"
	await physics_frames(3)
	var leaving := float(m._lib.clav_k.get(&"clavicle_r", 0.0))
	check(leaving > 0.5 and leaving < 1.0, "back to the CMU walk, it fades out (%.2f)" % leaving)
	await physics_frames(30)
	check(not m._pose_lib.has(&"clavicle_r"), "and is gone")
	Settings.library_motion = was


func test_with_library_motion_off_no_library_channel_reaches_him() -> void:
	var was: bool = Settings.library_motion
	Settings.library_motion = false
	var m: HumanBody = await _gun_walker()
	check(m._lib == null and m._pose_lib.is_empty(), "no library layer")
	Settings.library_motion = was
