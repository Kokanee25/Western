extends TestCase
## The cemetery (#1142; src/world/cemetery.gd, config/cemetery.json): a picket fence and gate round the yard,
## and the graves: the funeral's old ones at their old places first, crosses and headboards most, some
## stone markers; its markers are kit props standing on the ground.

var world: Node3D
var yard: Cemetery


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(-100, 10.0, -197)
	world.add_child(ground)
	yard = Cemetery.new()
	yard.position = Cemetery.world_at(Cemetery.load_config())
	world.add_child(yard)
	await physics_frames(KitProp.SETTLE_FRAMES + 3)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_the_fence_and_gate_are_members() -> void:
	check(yard.fence_posts > 20, "the fence has its posts (%d)" % yard.fence_posts)
	check(yard.pickets > 150, "the fence has its pickets (%d)" % yard.pickets)
	var gates := 0
	for m: StructureMember in yard.get_members():
		if String(m.member_id).contains("/gate_"):
			gates += 1
	check(gates == 2, "the gate's two leaves (%d)" % gates)
	# The gate's gap in the south fence is clear: no picket across it.
	var gap_ok := true
	for m: StructureMember in yard.get_members():
		var id := String(m.member_id)
		if id.contains("fence/s/picket_"):
			var x := m.position.x
			if x > -4.0 - 0.95 and x < -4.0 + 0.95:
				gap_ok = false
	check(gap_ok, "no picket across the gate")


func test_the_graves_the_funeral_s_first_and_mostly_wood() -> void:
	var funeral: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Cemetery.FUNERAL))
	var olds: Array = funeral.old_graves
	check(yard.graves.size() >= olds.size() + 10, "the old graves and more (%d)" % yard.graves.size())
	for i in olds.size():
		var want := Vector2(float(funeral.grave[0]) + float(olds[i][0]), float(funeral.grave[1]) + float(olds[i][1]))
		check((yard.graves[i].at as Vector2).distance_to(want) < 0.01, "the funeral's old grave %d is where its scene had it" % i)
	var wood := 0
	var stone := 0
	for g: Dictionary in yard.graves:
		match g.kind:
			&"wood_cross", &"headboard":
				wood += 1
			&"grave_marker", &"headstone_arched":
				stone += 1
	check(wood > stone * 2 and stone >= 1, "mostly wooden crosses and headboards, a few stone (%d wood, %d stone)" % [wood, stone])
	var funeral_grave := Vector2(float(funeral.grave[0]), float(funeral.grave[1]))
	for g: Dictionary in yard.graves:
		check((g.at as Vector2).distance_to(funeral_grave) > 3.0, "nothing on the funeral's own grave")
	for g: Dictionary in yard.graves.slice(0, 6):
		var kp := g.marker as KitProp
		check(not kp.loose and kp.settle().is_empty(), "%s stands" % kp.name)
