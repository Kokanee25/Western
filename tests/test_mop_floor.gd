extends TestCase
## The barkeep mops (MopFloor; docs/briefs/mopping.md): a spill or tracked mud past what he'll
## stand, and quiet, he fetches his mop and bucket, mops it up and puts them back; trouble and he
## lets go of the mop and sets the bucket down; calm again he picks them up and finishes.

const FLOOR_TOP := 0.12
const POST := Vector3(0.0, FLOOR_TOP, 1.8)
const HOME := Vector3(-2.3, FLOOR_TOP, 2.4)

var world: Node3D
var marks: FloorMarks
var man: HumanBody
var brain: CivilianBrain
var mopping: MopFloor


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
	var room := Structure.new()
	room.structure_id = &"room"
	world.add_child(room)
	for x in [-3.7, -2.5, -1.25, 0.0, 1.25, 2.5, 3.7]:
		room.add_member("sleeper%d" % int(x * 10), &"joist", &"framing", Vector3(0.1, FLOOR_TOP - 0.03, 6.0), Vector3(x, (FLOOR_TOP - 0.03) * 0.5, 0.0))
	var z := -3.0
	var i := 0
	while z < 2.99:
		room.add_member("board%02d" % i, &"floor_board", &"floor", Vector3(8.0, 0.03, 0.145), Vector3(0, FLOOR_TOP - 0.015, z + 0.0725))
		z += 0.15
		i += 1
	room.infer_supports()
	marks = FloorMarks.new()
	world.add_child(marks)
	man = HumanBody.new()
	man.body_model = &"outlaw"
	man.person_id = &"barkeep"
	man.rng_seed = 102
	man.has_gun = false
	brain = CivilianBrain.new()
	brain.name = "Brain"
	brain.post = POST
	brain.faces = Vector3(0, 1.5, -2.0)
	man.add_child(brain)
	world.add_child(man)
	man.global_position = POST
	man.face(brain.faces)
	var bucket := PropKit.make(&"mop_bucket") as MopBucket
	world.add_child(bucket)
	bucket.global_position = HOME
	var mop := PropKit.make(&"mop") as MopProp
	world.add_child(mop)
	await physics_frames(2)
	mop.stand_at(HOME + Vector3(0.18, 0.06, 0.18), Vector3(0.12, 1.0, 0.0))
	mopping = MopFloor.new(man, mop, bucket, POST, HOME)
	mopping.tuning = mopping.tuning.duplicate()
	mopping.tuning.look_every = 0.5
	mopping.set(&"_look", 0.2)
	brain.chores = [mopping]


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_a_spill_and_he_mops_it_up_and_puts_the_mop_back() -> void:
	Events.liquid_spilled.emit(Vector3(0.6, FLOOR_TOP, -0.8), &"whiskey", 0.6, null)
	var started := await wait_until(func() -> bool: return mopping.busy(), 3 * 60)
	check(started, "a bottle's worth on the floor and nobody about: he sees to it")
	var mopped := await wait_until(func() -> bool: return mopping.step == MopFloor.Step.MOP, 20 * 60)
	check(mopped, "he's mopping")
	check(mopping.mop.holder == man, "the mop in his hands")
	check(mopping.mop.water_ml > 0.0, "wet from the bucket first")
	var done := await wait_until(func() -> bool: return mopping.stopped == &"done" and not mopping.busy(), 120 * 60)
	check(done, "he finishes")
	check(marks.mess(Vector3(0.6, FLOOR_TOP, -0.8), 1.0).liquid < 60.0, "the whiskey's up (%.0f ml left)" % marks.mess(Vector3(0.6, FLOOR_TOP, -0.8), 1.0).liquid)
	check(mopping.mop.state == MopProp.State.STANDING, "the mop's stood back in its corner")
	check(mopping.bucket.global_position.distance_to(HOME) < 0.6, "and the bucket")
	check(mopping.bucket.other > 0.0, "the whiskey went into the bucket's water")


func test_mud_tracked_in_is_mopped() -> void:
	for k in 40:
		marks.add_dirt(Vector3(-1.0 + k * 0.05, FLOOR_TOP, -2.5 + k * 0.05), 0.25, 0.7)
	var before: float = marks.mess(POST, 7.0).dirt
	await wait_until(func() -> bool: return mopping.busy(), 3 * 60)
	await wait_until(func() -> bool: return mopping.stopped != &"" and not mopping.busy(), 150 * 60)
	var after: float = marks.mess(POST, 7.0).dirt
	check(after < before * 0.4, "most of the mud's gone (%.2f of %.2f g left)" % [after, before])
	check(mopping.bucket.dirt > 0.0, "it's in the bucket")


func test_trouble_he_lets_go_and_finishes_when_its_calm() -> void:
	Events.liquid_spilled.emit(Vector3(0.6, FLOOR_TOP, -0.8), &"whiskey", 0.6, null)
	await wait_until(func() -> bool: return mopping.step == MopFloor.Step.MOP, 25 * 60)
	Events.noise.emit(Vector3(2.0, 1.2, -2.0), 1.0, &"gunshot", null)
	await physics_frames(2)
	check_eq(mopping.stopped, &"trouble", "a shot: he stops")
	check(mopping.mop.holder == null, "lets go of the mop")
	check(mopping.bucket.carrier == null, "the bucket's down")
	var again := await wait_until(func() -> bool: return mopping.busy(), 40 * 60)
	check(again, "calm again, he picks them up")
	var home := await wait_until(func() -> bool: return not mopping.busy() and mopping.mop.state == MopProp.State.STANDING, 120 * 60)
	check(home, "and finishes, the mop back in its corner")
