extends TestCase
## Men thrown through the air by a blast (issue #596 step 3b): BlastTuning.blast_lift 0 is the real
## push alone (as before); at the proposed 1 a stick on the floor a metre off throws him up and back
## 3-6 m with the arc's top 1-2 m up, 3 m off takes him off his feet, 6 m off changes nothing; the
## same blast throws him the same way; he lands hurt. The numbers are the ragdoll lab's group Z
## (experiments/physics_lab/thrown.py) held loosely.

var world: Node3D
var lift_was := 0.0


func before_each() -> void:
	lift_was = Blast.t().blast_lift
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	await physics_frames(2)


func after_each() -> void:
	Blast.t().blast_lift = lift_was
	world.queue_free()
	await physics_frames(2)


func _man(seed := 1) -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = false
	man.rng_seed = seed
	world.add_child(man)
	man.global_position = Vector3.ZERO
	await physics_frames(30)
	return man


## His weight's centre over `seconds`: [start, highest y, where it is at the end].
func _flight(man: HumanBody, seconds: float) -> Array:
	var start := _com(man)
	var top := start.y
	for i in int(seconds * 60.0):
		await physics_frames(1)
		top = maxf(top, _com(man).y)
	return [start, top, _com(man)]


func _com(man: HumanBody) -> Vector3:
	var c := Vector3.ZERO
	var m := 0.0
	for sid: StringName in man.parts:
		var p := man.parts[sid] as Node3D
		if p == null or not is_instance_valid(p) or man.physiology.severed_segments.has(sid):
			continue
		var w := float(p.get_meta(&"mass", 1.0))
		c += p.global_position * w
		m += w
	return c / maxf(m, 1e-3)


## A 0.2 kg stick lying on the ground hits as 0.36 kg (BlastTuning.ground_factor).
const KG := 0.36


func test_lift_share_falls_away() -> void:
	var near := Blast.lift_share(KG, 1.5)
	var mid := Blast.lift_share(KG, 3.2)
	var far := Blast.lift_share(KG, 6.1)
	check(near > 0.8, "nearly all of it at a metre's reach (%.2f)" % near)
	check(mid > 0.15 and mid < 0.4, "a share at 3 m (%.2f)" % mid)
	check(far < 0.05, "next to none at 6 m (%.3f)" % far)


func test_no_lift_is_the_real_push() -> void:
	Blast.t().blast_lift = 0.0
	var man := await _man()
	var info := man.take_blast(Vector3(0, 0.05, -1.0), KG)
	check(info.knocked_down, "knocked down at a metre, as before")
	check_eq(float(info.lift), 0.0, "no lift")
	var f := await _flight(man, 1.5)
	check(float(f[1]) - (f[0] as Vector3).y < 0.15, "not thrown up (%.2f m)" % (float(f[1]) - (f[0] as Vector3).y))


func test_a_metre_off_thrown_up_and_back() -> void:
	Blast.t().blast_lift = 1.0
	var man := await _man()
	var info := man.take_blast(Vector3(0, 0.05, -1.0), KG)
	check(float(info.lift) > 5.0, "thrown hard (%.1f m/s)" % float(info.lift))
	var f := await _flight(man, 2.5)
	var start: Vector3 = f[0]
	var end: Vector3 = f[2]
	var up := float(f[1]) - start.y
	var gone := Vector2(end.x - start.x, end.z - start.z)
	check(up > 0.9 and up < 2.2, "the arc's top 1-2 m up (%.2f)" % up)
	check(gone.length() > 2.8 and gone.length() < 6.5, "landed 3-6 m off (%.2f)" % gone.length())
	check(gone.y > 0.0, "away from the charge (it was in front of him, -z: %s)" % str(gone))
	check(man.limp, "a ragdoll")


func test_three_metres_off_his_feet_six_as_before() -> void:
	Blast.t().blast_lift = 1.0
	var man := await _man()
	var info := man.take_blast(Vector3(0, 0.05, -3.0), KG)
	check(info.knocked_down, "off his feet at 3 m")
	var f := await _flight(man, 1.5)
	check(float(f[1]) - (f[0] as Vector3).y < 0.4, "not flying from 3 m (%.2f up)" % (float(f[1]) - (f[0] as Vector3).y))
	var far := await _man(2)
	far.global_position = Vector3(10, 0, 0)
	await physics_frames(5)
	var info6 := far.take_blast(Vector3(10, 0.05, -6.0), KG)
	check(not info6.knocked_down, "standing at 6 m, as before")


func test_same_blast_same_throw() -> void:
	Blast.t().blast_lift = 1.0
	var ends: Array[Vector3] = []
	for k in 2:
		var man := await _man(3)
		man.take_blast(Vector3(0, 0.05, -1.0), KG)
		var f := await _flight(man, 1.0)
		ends.append(f[2])
		man.queue_free()
		await physics_frames(2)
	check(ends[0].distance_to(ends[1]) < 0.05, "the same throw twice (%s vs %s)" % [ends[0], ends[1]])


func test_landing_hurts() -> void:
	Blast.t().blast_lift = 1.0
	var man := await _man()
	var blows: Array = []
	var on_hit := func(info: Dictionary) -> void:
		if info.get("kind") == &"blow" and info.get("person") == man:
			blows.append(info)
	Events.body_hit.connect(on_hit)
	man.take_blast(Vector3(0, 0.05, -1.0), KG)
	await _flight(man, 2.5)
	Events.body_hit.disconnect(on_hit)
	check(not blows.is_empty(), "the ground hurt him landing")
	check(blows.size() <= man.parts.size(), "once a part at most (%d)" % blows.size())
