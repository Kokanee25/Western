extends TestCase
## The smoke column over a burning building's roofline (the art session's SmokeColumn,
## smoke_sheet.gdshader: the simulated smoke can't be drawn against the sky). A wall of boards, some
## of them alight at one end: the column stands over them at the roofline, grows with the fire, and
## fades when it's out; a fire just caught has none yet.

var world: Node3D
var fire: FireSystem
var building: Structure
var boards: Array[StructureMember] = []


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	building = Structure.new()
	building.structure_id = &"wall"
	building.collapses = false
	world.add_child(building)
	boards.clear()
	for i in 32:
		boards.append(building.add_member("wall%d" % i, &"board", &"weathered_pine", Vector3(0.24, 3.2, 0.025), Vector3(-3.875 + i * 0.25, 1.6, 0.0)))
	building.infer_supports()
	await physics_frames(2)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func test_it_stands_over_the_fire_at_the_roofline_and_fades_when_its_out() -> void:
	if not SmokeField.available():
		print("    (no native plugin: nothing to test)")
		return
	# The east end well alight (burning a while): boards from x 2.1 to 3.9.
	for i in range(24, 32):
		fire.ignite(boards[i])
		boards[i].burn_time = fire.tuning.growth_seconds
	var field := SmokeField.around(fire, fire._box_of(building), building)
	var column := SmokeColumn.over(field)
	await physics_frames(30)
	check(column.visible, "drawn while the wall burns")
	var at := column.global_position
	check(absf(at.x - 3.0) < 0.6, "over the burning end of the wall (x %.2f)" % at.x)
	check(absf(at.y - 3.2) < 0.1, "from the roofline (y %.2f)" % at.y)
	var small := float(column.get_instance_shader_parameter(&"strength"))
	check(small > 0.1, "some smoke for a few boards (%.2f)" % small)
	# More of it alight: a bigger column, moving over the middle of the fire.
	for i in range(8, 24):
		fire.ignite(boards[i])
	await physics_frames(60 * 6)
	var big := float(column.get_instance_shader_parameter(&"strength"))
	check(big > small + 0.1, "more fire, more smoke (%.2f to %.2f)" % [small, big])
	check(column.global_position.x < at.x - 0.5, "it moves over where it burns now (x %.2f)" % column.global_position.x)
	# Out: it fades away.
	for b in boards:
		b.burning = false
	await physics_frames(60 * 8)
	check(not column.visible, "gone when the fire's out")


func test_a_fire_just_caught_has_no_column_yet() -> void:
	if not SmokeField.available():
		print("    (no native plugin: nothing to test)")
		return
	# A blast's few boards, a second or two alight: no smoke over the roof yet (it stood there as a
	# dark blot a second after a stick went off by the store).
	for i in range(24, 31):
		fire.ignite(boards[i])
		boards[i].burn_time = 1.5
	var field := SmokeField.around(fire, fire._box_of(building), building)
	var column := SmokeColumn.over(field)
	await physics_frames(30)
	check(not column.visible, "no column over a fire just caught")
	# Grown enough to put smoke over the roof: it eases in rather than standing there at once.
	for i in range(24, 31):
		boards[i].burn_time = fire.tuning.growth_seconds * 0.25
	await physics_frames(40)
	var first := float(column.get_instance_shader_parameter(&"strength"))
	await physics_frames(60 * 3)
	var later := float(column.get_instance_shader_parameter(&"strength"))
	check(column.visible, "there once the fire's grown")
	check(later > first + 0.05, "easing in (%.2f to %.2f)" % [first, later])
