extends TestCase
## What's on the boards (FloorMarks; docs/briefs/mopping.md): boots bring the street in and shed it
## on the boards, most near the door; a spill lies as a film where it fell, dries and soaks into a
## stain (water leaves none); a mop's `take` lifts dirt, liquid and blood; it's drawn in chunks.

var world: Node3D
var floor_s: Structure
var marks: FloorMarks
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
	# A room's floor of boards, 4 x 4 m, its near edge at z = 0 (the street beyond it, -z).
	floor_s = Structure.new()
	floor_s.structure_id = &"room"
	world.add_child(floor_s)
	for x in [-1.8, -0.6, 0.6, 1.8]:
		floor_s.add_member("joist%d" % int(x * 10), &"joist", &"framing", Vector3(0.05, 0.25, 4.0), Vector3(x, 0.125, 2.0))
	for i in 16:
		floor_s.add_member("board%d" % i, &"floor_board", &"floor", Vector3(4.0, 0.05, 0.25), Vector3(0, 0.275, 0.125 + 0.25 * i))
	floor_s.infer_supports()
	marks = FloorMarks.new()
	world.add_child(marks)
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


## A man walked from the street onto the boards and across them, `step` m a tick.
func _walk(man: HumanBody, from: Vector3, to: Vector3, speed := 1.2) -> void:
	man.global_position = from
	await physics_frames(2)
	var d := from.distance_to(to)
	var ticks := int(d / speed * 60.0)
	for i in ticks + 1:
		man.global_position = from.lerp(to, float(i) / ticks)
		await physics_frames(1)
	await physics_frames(20)


func _man() -> HumanBody:
	var man := HumanBody.new()
	man.has_gun = false
	man.rng_seed = 3
	world.add_child(man)
	return man


func test_boots_bring_the_street_in_and_shed_it_by_the_door() -> void:
	var man := _man()
	await _walk(man, Vector3(0, 0, -6), Vector3(0, FLOOR_TOP, -0.2))
	check(marks.boots_of(man) > 1.0, "six metres of street on his boots (%.2f g)" % marks.boots_of(man))
	await _walk(man, Vector3(0, FLOOR_TOP, -0.2), Vector3(0, FLOOR_TOP, 3.8))
	var near := marks.mess(Vector3(0, FLOOR_TOP, 0.75), 0.7)
	var far := marks.mess(Vector3(0, FLOOR_TOP, 3.25), 0.7)
	check(near.dirt > 0.0, "dirt on the boards by the door (%.2f g)" % near.dirt)
	check(near.dirt > far.dirt * 2.0, "more by the door than at the back (%.2f against %.2f g)" % [near.dirt, far.dirt])
	check(marks.chunk_count() >= 1, "and it's drawn")


func test_a_spill_lies_where_it_fell_dries_and_stains() -> void:
	Events.liquid_spilled.emit(Vector3(0, FLOOR_TOP, 2.0), &"whiskey", 0.6, null)
	var m := marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.0)
	check_near(m.liquid, 600.0, 1.0, "the whole 0.6 l lies on the boards")
	check(marks.mess(Vector3(0, FLOOR_TOP, 2.0), 0.15).liquid < 600.0, "spread out round where it fell")
	marks.age(3.0)
	var later := marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.0)
	check(later.liquid < m.liquid * 0.8, "three hours on, it's drying (%.0f ml left)" % later.liquid)
	check(later.stain > 0.0, "and soaking in: a stain")
	marks.age(48.0)
	check(marks.mess(Vector3(0, FLOOR_TOP, 2.0), 1.0).liquid < 1.0, "two days on, it's dry")
	Events.liquid_spilled.emit(Vector3(1.0, FLOOR_TOP, 1.0), &"water", 0.5, null)
	marks.age(48.0)
	check(marks.mess(Vector3(1.0, FLOOR_TOP, 1.0), 0.6).stain < 0.01, "water dries leaving no stain")


func test_nothing_lies_on_the_street() -> void:
	Events.liquid_spilled.emit(Vector3(0, 0, -5.0), &"whiskey", 0.6, null)
	check(marks.mess(Vector3(0, 0, -5.0), 1.0).liquid == 0.0, "spilled on the dirt it soaks straight in")


func test_a_mop_lifts_dirt_liquid_and_blood() -> void:
	var at := Vector3(0, FLOOR_TOP, 2.0)
	marks.add_dirt(at, 2.0)
	Events.liquid_spilled.emit(at, &"beer", 0.3, null)
	Blood.splat(world, at + Vector3(0.1, 0.0, 0.0), Vector3.UP, 12.0)
	var before := marks.mess(at, 0.5)
	check(before.blood > 10.0, "a splat of blood there (%.1f ml)" % before.blood)
	var got := {"dirt": 0.0, "liquid": 0.0, "blood": 0.0}
	for i in 12:
		var t := marks.take(at, 0.45, 0.35)
		got.dirt += t.dirt
		got.blood += t.blood
		for k in t.liquid:
			got.liquid += t.liquid[k]
	var after := marks.mess(at, 0.5)
	check(after.dirt < before.dirt * 0.05, "the dirt's up (%.3f g left)" % after.dirt)
	check(after.liquid < before.liquid * 0.05, "the beer's up")
	check(after.blood < before.blood * 0.2, "the blood's up (%.1f ml left)" % after.blood)
	check_near(got.dirt, before.dirt - after.dirt, 0.01, "what came up is what went")
	check(got.blood > 0.0, "the mop has the blood")

