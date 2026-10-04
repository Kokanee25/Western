extends TestCase
## The fixed dressing is drawn in batches: the same mesh and material in a patch of town as one
## MultiMesh, each part where it was; the parts stay (hidden) with their collision. What can
## change (a lamp, a building's members, anything with a brain or loose) is left alone; a part
## that's freed stops being drawn, and one released draws itself again.

var world: Node3D
var batch: StaticBatch


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	batch = StaticBatch.new()
	batch.target = ^""  # built by hand below
	world.add_child(batch)
	await process_frames(3)


func after_each() -> void:
	world.queue_free()
	await process_frames(1)


## A prop like PropLibrary's: a static body with `parts` boxes, the mesh built afresh for each.
func _prop(at: Vector3, parts := 3) -> StaticBody3D:
	var body := StaticBody3D.new()
	world.add_child(body)
	body.position = at
	for i in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = MemberMesh.box(Vector3(0.5, 0.1, 0.5))
		mi.material_override = _shared_mat()
		mi.position = Vector3(0, 0.1 * i, 0)
		body.add_child(mi)
	return body


var _mat: Material
func _shared_mat() -> Material:
	if _mat == null:
		_mat = PixelArt.material(PixelArt.wood("batch_test", Color(0.5, 0.38, 0.25), 3))
	return _mat


## (Headless, the MultiMesh's transforms can't be read back: the dummy renderer keeps none. Where
## each instance lands is checked by rendering, old vs new, pixel for pixel.)


func test_the_same_part_in_many_props_is_one_batch() -> void:
	var a := _prop(Vector3(0, 0, 0))
	var b := _prop(Vector3(2, 0, 0))
	var lamp := OilLamp.new()
	world.add_child(lamp)
	await process_frames(1)
	var lamp_meshes := lamp.find_children("*", "MeshInstance3D", true, false)
	var taken := batch.build(world)
	check_eq(taken, 6, "the six boxes")
	check_eq(batch.batches.size(), 1, "the same box and material: one batch")
	var mmi: MultiMeshInstance3D = batch.batches.keys()[0]
	check_eq(mmi.multimesh.instance_count, 6, "six instances")
	for mi: MeshInstance3D in a.find_children("*", "MeshInstance3D", true, false) + b.find_children("*", "MeshInstance3D", true, false):
		check(not mi.visible, "%s hidden, drawn by the batch" % mi.name)
		check_eq(batch.batches[mmi][batch._of[mi][1]], mi, "its instance is its own")
	for mi: MeshInstance3D in lamp_meshes:
		check(not batch._of.has(mi), "the lamp's own (it can be shot out)")
	check(a.get_child_count() > 0 and a.get_child(0) is MeshInstance3D, "the parts stay")


func test_a_freed_part_stops_drawing_and_a_released_one_draws_itself() -> void:
	var a := _prop(Vector3(0, 0, 0))
	var b := _prop(Vector3(2, 0, 0))
	batch.build(world)
	var gone := a.get_child(0) as MeshInstance3D
	var kept := b.get_child(0) as MeshInstance3D
	check(batch._of.has(gone), "batched")
	a.free()
	check(not batch._of.has(gone), "freed: its instance is gone")
	batch.release(b)
	check(kept.visible, "released: it draws itself again")
	check(not batch._of.has(kept), "and the batch lets it go")
