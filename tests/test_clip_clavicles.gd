extends TestCase
## The clips carry the clavicles (#708): tools/blender/retarget_motion.py writes a `clavicle_r` and
## `clavicle_l` channel (the clavicle's turn from rest in the chest's frame) from every source rig
## that turns its clavicles (Uthana's and Mixamo's LeftShoulder), held to the girdle's limits the
## game holds its own drive to; a clip whose source never turns them (the CMU takes) has none; and
## a man playing a clip with them has his clavicles follow it.

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
