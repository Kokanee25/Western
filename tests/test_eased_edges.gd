extends TestCase
## Rounded wood (#873, Sean 2026-11-12: "we need to round the wood edges for sure", and handrails of
## "nice rounded wood ... rounded top flat bottom"). The boards' edges are eased in the library shader
## (scan_wood.gdshader's `edge_round`, no geometry); the railing's rail is drawn run to the handrail
## profile, in the game's woods and in a building's library wood alike, its physics still its box.

var world: Node3D


func before_each() -> void:
	world = Node3D.new()
	add_child(world)


func after_each() -> void:
	world.queue_free()
	await physics_frames(1)


func _railing() -> Structure:
	var s := Structure.new()
	s.structure_id = &"eased_test"
	world.add_child(s)
	s.add_member("deck", &"sill", &"floor", Vector3(4.0, 0.05, 2.0), Vector3(0, 0.025, 0.45))
	Railing.build(s, "rail", Vector3(-1.2, 0.05, -0.5), Vector3(1.2, 0.05, -0.5), {"height": 1.0})
	return s


func _rails(s: Structure) -> Array:
	return s.get_members().filter(func(m: StructureMember) -> bool: return m.kind == &"trim")


func test_the_rail_is_drawn_as_the_handrail_its_physics_a_box() -> void:
	var s := _railing()
	var rails := _rails(s)
	check(rails.size() >= 2, "the rail in spans (%d)" % rails.size())
	for m: StructureMember in rails:
		var mesh := m.drawn_node().mesh
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		check(verts.size() > 24, "%s drawn as a profile, not a box (%d vertices)" % [m.member_id, verts.size()])
		check(m.has_meta(&"draw") and String(m.get_meta(&"draw").profile) == "handrail", "%s keeps its profile for a finish laid later" % m.member_id)
		var box := (m.get_child(1) as CollisionShape3D).shape as BoxShape3D
		check(box != null and box.size.is_equal_approx(m.size), "%s collides as its box (%s)" % [m.member_id, box.size if box else null])
		# Rounded top, flat bottom: the drawn top is narrower than the box at its crown, the foot flat.
		var top := -INF
		var bottom := INF
		for p in verts:
			top = maxf(top, p.y)
			bottom = minf(bottom, p.y)
		check_near(top - bottom, m.size.y, 0.002, "%s fills its box's height" % m.member_id)


func test_a_plain_rail_when_asked() -> void:
	var s := Structure.new()
	world.add_child(s)
	var made := Railing.build(s, "rail", Vector3(-0.6, 0.0, 0.0), Vector3(0.6, 0.0, 0.0), {"profile": ""})
	for m: StructureMember in made:
		check(not m.has_meta(&"draw"), "%s plain" % m.member_id)


func test_a_library_wood_runs_along_the_profile() -> void:
	var s := _railing()
	for m: StructureMember in _rails(s):
		# As a building's finish lays a library wood over a member drawn already (PropKit.dress_member).
		PropKit.dress_member(m, {}, "lib:furniture_oak/few")
		var mi := m.drawn_node()
		var arr: Array = mi.mesh.get_meta(&"arrays")
		var c0: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM0]
		var c1: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM1]
		var c2: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM2]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		check(v.size() > 24, "%s still the profile in the library wood" % m.member_id)
		check(c2[3] >= 10.0, "marked shaped (role + 10): the shader keeps its normals")
		# The outline's length is the board's "width" (the scan wraps round it), longer than its box's sides.
		check(c1[1] > m.size.y + m.size.z, "the across runs round the outline (%.3f)" % c1[1])
		# The sides' normals turn round the top (not all one way, as a flat board's are).
		var ups := {}
		for i in v.size():
			if c0[i * 4 + 3] < 0.5:
				ups[snappedf(n[i].z, 0.25)] = true
		check(ups.size() >= 4, "the side normals turn round the profile (%d ways)" % ups.size())
		check((arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() % 3 == 0, "triangles")
		check(mi.material_override is ShaderMaterial, "in the library's shader")


func test_the_library_shader_eases_edges_by_age() -> void:
	var sh := load("res://src/render/scan_wood.gdshader") as Shader
	check(sh.code.contains("uniform vec2 edge_round"), "scan_wood has edge_round")
	var m := ShaderMaterial.new()
	m.shader = sh
	MaterialLibrary.apply(m, MaterialLibrary.entry("rough_pine_batten"), 1.0, &"wall")
	var r: Vector2 = m.get_shader_parameter(&"edge_round")
	check(r.x > 0.0 and r.y > r.x, "rounder with age (%s)" % r)
	MaterialLibrary.apply(m, MaterialLibrary.entry("furniture_oak"), 0.0, &"wall")
	var f: Vector2 = m.get_shader_parameter(&"edge_round")
	check(f.y < r.y, "joinery stays crisper than a rough board (%s / %s)" % [f, r])
