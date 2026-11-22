extends TestCase
## The church and cemetery's props (#1142; tools/props/church.py): each is a kit prop that stands where
## it's put on the ground, with its members, and PropLibrary hands it out by name.

const IDS := [&"pew", &"pulpit", &"altar_rail", &"hymn_stand", &"wood_cross", &"headboard", &"grave_marker"]
var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_each_church_prop_stands_and_is_handed_out_by_name() -> void:
	for id: StringName in IDS:
		var p := PropKit.spawn(id)
		world.add_child(p)
		await physics_frames(KitProp.SETTLE_FRAMES + 2)
		var st := p.settle()
		check(st.is_empty(), "%s stands: nothing breaks or falls (%s)" % [id, st.slice(0, 4)])
		check(not p.loose, "%s stands on its feet" % id)
		check(p.mass() > 0.5, "%s weighs something (%.1f kg)" % [id, p.mass()])
		check(PropLibrary.spawn(id) is KitProp, "PropLibrary hands out %s by name" % id)
		p.queue_free()
		await physics_frames(2)
