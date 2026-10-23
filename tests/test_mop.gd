extends TestCase
## The mop and its bucket (MopProp, MopBucket; docs/briefs/mopping.md): it stands in its corner with
## its head slumped on the boards; in its bucket's water it soaks up and rinses out, pressed it's
## wrung; dragged wet over dirt it lifts it (FloorMarks), and a dirty one spreads it; let go it falls.

var world: Node3D
var marks: FloorMarks
var mop: MopProp
var bucket: MopBucket
const FLOOR_TOP := 0.3


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
	var floor_s := Structure.new()
	floor_s.structure_id = &"room"
	world.add_child(floor_s)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		floor_s.add_member("joist%d" % int(x * 10), &"joist", &"framing", Vector3(0.05, 0.25, 4.0), Vector3(x, 0.125, 2.0))
	for i in 27:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(4.0, 0.05, 0.145), Vector3(0, 0.275, 0.08 + 0.15 * i))
	floor_s.infer_supports()
	marks = FloorMarks.new()
	world.add_child(marks)
	mop = PropKit.make(&"mop") as MopProp
	world.add_child(mop)
	bucket = PropKit.make(&"mop_bucket") as MopBucket
	world.add_child(bucket)
	bucket.global_position = Vector3(1.2, FLOOR_TOP, 1.0)
	await physics_frames(2)
	mop.stand_at(Vector3(-1.5, FLOOR_TOP + 0.06, 3.5), Vector3(0.15, 1.0, 0.0))
	await physics_frames(60)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## Held by nobody (the tests' hands), its foot moved along `path`, `speed` m/s.
func _drag(path: Array, speed := 0.5) -> void:
	mop.take(null)
	for i in range(1, path.size()):
		var a: Vector3 = path[i - 1]
		var b: Vector3 = path[i]
		var n := maxi(int(a.distance_to(b) / speed * 60.0), 1)
		for k in n + 1:
			mop.hold_at(a.lerp(b, float(k) / n), Vector3(0.0, 1.0, -0.6))
			await physics_frames(1)


func test_it_stands_with_its_head_on_the_floor() -> void:
	var lo := INF
	for i in mop.point_count():
		lo = minf(lo, mop.point(i).y)
	check(lo > FLOOR_TOP - 0.02, "no strand through the boards (lowest %.3f)" % lo)
	check(lo < FLOOR_TOP + 0.05, "the head slumps on them")
	check(mop.foot().distance_to(Vector3(-1.5, FLOOR_TOP + 0.06, 3.5)) < 0.01, "where it was stood")


func test_it_soaks_in_its_bucket_and_wrings_out() -> void:
	var water := bucket.water_ml
	await _drag([mop.foot(), Vector3(1.2, FLOOR_TOP + 0.3, 1.0), Vector3(1.2, FLOOR_TOP + 0.06, 1.0)])
	await physics_frames(60)
	check(mop.water_ml > mop.capacity_ml() * 0.8, "dipped, it's soaked (%.0f ml)" % mop.water_ml)
	check(bucket.water_ml < water, "out of the bucket")
	await _drag([mop.foot(), Vector3(1.2, FLOOR_TOP + 0.65, 1.0)], 0.4)  # up out of the water, over it
	for i in 90:
		mop.hold_at(Vector3(1.2, FLOOR_TOP + 0.65, 1.0), Vector3(0.0, 1.0, -0.6))
		mop.press(bucket, 1.0 / 60.0)
		await physics_frames(1)
	check_near(mop.water_ml, mop.wrung_ml(), 5.0, "pressed, it keeps about its own weight")


func test_dragged_wet_it_lifts_the_dirt_and_rinses_it_out() -> void:
	for x in range(-8, 9):
		for z in range(-3, 4):
			marks.add_dirt(Vector3(x * 0.1, FLOOR_TOP, 2.0 + z * 0.1), 0.15)
	var before: float = marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.2).dirt
	mop.water_ml = mop.wrung_ml()
	await _drag([mop.foot(), Vector3(-0.9, FLOOR_TOP + 0.05, 2.0), Vector3(0.9, FLOOR_TOP + 0.05, 2.0),
			Vector3(-0.9, FLOOR_TOP + 0.05, 2.0), Vector3(0.9, FLOOR_TOP + 0.05, 2.0)], 0.6)
	var after: float = marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.2).dirt
	check(after < before * 0.6, "two passes lift most of it (%.2f of %.2f g left)" % [after, before])
	check(mop.dirt > 0.1, "it's in the mop (%.2f g)" % mop.dirt)
	check(marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.2).liquid > 0.0, "it leaves the boards damp")
	var in_mop := mop.dirt
	await _drag([mop.foot(), Vector3(1.2, FLOOR_TOP + 0.3, 1.0), Vector3(1.2, FLOOR_TOP + 0.06, 1.0)])
	await physics_frames(60)
	check(bucket.dirt > in_mop * 0.5, "rinsed, the dirt's in the bucket (%.2f g)" % bucket.dirt)
	check(bucket.murk() > 0.0, "its water's darker")


func test_a_dirty_mop_spreads_dirt() -> void:
	mop.water_ml = mop.capacity_ml() * 0.6
	mop.dirt = 6.0
	await _drag([mop.foot(), Vector3(-0.9, FLOOR_TOP + 0.05, 3.0), Vector3(0.9, FLOOR_TOP + 0.05, 3.0)], 0.6)
	check(marks.mess(Vector3(0, FLOOR_TOP, 3.0), 1.0).dirt > 0.05, "clean boards, a dirty mop: dirtier")


func test_let_go_it_falls() -> void:
	await _drag([mop.foot(), Vector3(0, FLOOR_TOP + 0.06, 2.0)], 0.8)
	mop.let_go()
	await physics_frames(180)
	check(mop.grip(mop.length()).y < FLOOR_TOP + 0.3, "the handle's down on the boards (%.2f)" % mop.grip(mop.length()).y)
	var lo := INF
	for i in mop.point_count():
		lo = minf(lo, mop.point(i).y)
	check(lo > FLOOR_TOP - 0.03, "the head's on them, not through (lowest %.3f, foot %.3f)" % [lo, mop.foot().y])
