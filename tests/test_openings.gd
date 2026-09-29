extends TestCase
## Bad wounds open the body: energy dumped close together tears the skin and clothes open and
## shows the inside (flesh, ribs, lungs...); small wounds stay holes; reduced gore keeps it closed.

var world: Node3D
var man: HumanBody


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	man = HumanBody.new()
	man.has_gun = false
	world.add_child(man)
	await physics_frames(2)


func after_each() -> void:
	Settings.reduced_gore = false
	world.queue_free()
	await physics_frames(1)


func _chest_front() -> Vector3:
	return Vector3(0.05, 0.03, -0.12)  # chest-centred: right of the breastbone, on the skin


func _count(seg: StringName) -> int:
	var n := 0
	for mi: MeshInstance3D in (man.visuals[seg] as Node3D).find_children("*", "MeshInstance3D", true, false):
		var m := mi.material_override as ShaderMaterial
		if m and m.shader == BodyInterior.SKIN_SHADER and int(m.get_shader_parameter(&"wound_count")) > 0:
			n += 1
	return n


func test_the_body_parts_can_open() -> void:
	var mi := (man.visuals[&"chest"] as Node3D).get_node(^"Mesh0") as MeshInstance3D
	check((mi.material_override as ShaderMaterial).shader == BodyInterior.SKIN_SHADER, "skin and clothes use the wound shader")


func test_a_small_wound_stays_a_hole() -> void:
	man.open_wound(&"chest", _chest_front(), 60.0)
	check(not man.is_open(&"chest"), "not opened")
	check((man.visuals[&"chest"] as Node3D).get_node_or_null(^"Inside") == null, "nothing built inside")


func test_a_big_wound_opens_and_shows_inside() -> void:
	var o := man.open_wound(&"chest", _chest_front(), 1500.0)
	check(man.is_open(&"chest"), "opened (%.1f cm)" % (o.radius * 100.0))
	var inside := (man.visuals[&"chest"] as Node3D).get_node_or_null(^"Inside")
	check(inside != null, "the inside's built")
	if inside:
		check(inside.get_node_or_null(^"heart") != null and inside.get_node_or_null(^"lung_r") != null, "heart and lungs in there")
		check(inside.get_node_or_null(^"Rib3") != null, "ribs as bars")
	check(_count(&"chest") >= 1, "the skin knows where it's open")
	check((man.visuals[&"abdomen"] as Node3D).get_node_or_null(^"Inside") == null, "only the opened part")


func test_hits_close_together_add_up() -> void:
	var a := man.open_wound(&"chest", _chest_front(), 150.0)
	var r1: float = a.radius
	var b := man.open_wound(&"chest", _chest_front() + Vector3(0.02, 0.01, 0.0), 150.0)
	check(a == b, "the same opening")
	check(b.radius > r1, "and bigger (%.1f -> %.1f cm)" % [r1 * 100.0, b.radius * 100.0])


func test_point_blank_tears_more_than_across_the_street() -> void:
	var ballistics := Ballistics.new()
	world.add_child(ballistics)
	await physics_frames(1)
	var t: RevolverTuning = load("res://config/revolver.tres")
	var at := (man.parts[&"abdomen"] as Node3D).global_position + Vector3(0.04, 0.0, 0.0)
	var b := ballistics.fire(at + Vector3(0, 0, -0.25), Vector3.BACK, t.muzzle_velocity, t.bullet_mass, t.bullet_diameter)
	await wait_until(func() -> bool: return not b.alive, 30)
	var close := 0.0
	for o: Dictionary in man.openings.get(&"abdomen", []):
		close = maxf(close, o.radius)
	check(close >= HumanBody.OPEN_MIN_RADIUS, "a shot with the muzzle on him opens him up (%.1f cm)" % (close * 100.0))


func test_reduced_gore_keeps_it_closed() -> void:
	man.open_wound(&"chest", _chest_front(), 1500.0)
	Settings.reduced_gore = true
	Settings.changed.emit()
	var mi := (man.visuals[&"chest"] as Node3D).get_node(^"Mesh0") as MeshInstance3D
	check((mi.material_override as ShaderMaterial).get_shader_parameter(&"reduced_gore") == true, "the skin stays closed")


func test_openings_are_saved() -> void:
	man.open_wound(&"chest", _chest_front(), 1500.0)
	var d := man.to_dict()
	check(d.openings.has("chest") and (d.openings.chest as Array).size() == 1, "the opening's in the save")
