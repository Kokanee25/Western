extends TestCase
## Wear and dents by use (#901, Sean 2026-11-13: "wear and dents to the wood ... in the saloon and
## basically everywhere"). The library shader draws them (scan_wood.gdshader, wood_use.gdshaderinc)
## from each board's use role (CUSTOM2.w) and its building's `materials.wear`; these check the data
## reaches the boards: the roles, the latch side, the building's use.

const Lab := preload("res://experiments/building_lab/lab.gd")
const SPEC := "res://config/buildings/doctor.json"


func _role_of(mi: MeshInstance3D) -> float:
	var arr: Array = mi.mesh.get_meta(&"arrays") if mi.mesh.has_meta(&"arrays") else mi.mesh.surface_get_arrays(0)
	var c2: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM2]
	return fmod(c2[3], 10.0)


func test_a_looks_use_roles() -> void:
	check_eq(PropKit.lib_parts("lib:furniture_oak/few/bar"), ["furniture_oak", "few", 7.0], "a bar's top")
	check_eq(PropKit.lib_parts("lib:furniture_oak/few/seat")[2], 8.0, "a chair's seat")
	check_eq(PropKit.lib_parts("lib:furniture_oak/few/grip")[2], 9.0, "a grip")
	check_eq(PropKit.lib_parts("lib:furniture_oak/few/kick")[2], 6.0, "a kick board")
	check_eq(PropKit.lib_parts("lib:furniture_oak/few/nonsense")[2], 0.0, "an unknown role is a plain board")
	var mat := PropKit.lib_material("lib:furniture_oak/few")
	check(float(mat.get_shader_parameter(&"use_wear")) > 0.0, "furniture is used")
	# Dents and cuts are off until the judges like them (Sean, 2026-11-14, #901 round 2).
	check_eq(float(mat.get_shader_parameter(&"dings")), 0.0, "no dents on furniture yet")


func test_the_bar_carries_its_wear() -> void:
	for pair in [[&"bar", "top", 7.0], [&"bar", "plinth", 6.0], [&"bar", "rail_low", 6.0]]:
		var p := PropKit.spawn(pair[0])
		add_child(p)
		var found := false
		for m: StructureMember in p.get_members():
			if String(m.member_id).ends_with("/" + String(pair[1])):
				found = true
				check_eq(_role_of(m.drawn_node()), pair[2], "%s's %s drawn with role %d" % [pair[0], pair[1], int(pair[2])])
		check(found, "%s has its %s" % [pair[0], pair[1]])
		p.free()


func test_a_building_wears_by_its_use() -> void:
	Lab.spec_path = SPEC
	var lab: Node3D = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)
	var b: Structure = lab.building
	var treads := 0
	var leaves := 0
	var seen_use := {}
	for m: StructureMember in b.get_members():
		var mi := m.drawn_node()
		if mi == null or not (mi.material_override is ShaderMaterial):
			continue
		var sm := mi.material_override as ShaderMaterial
		if not String(sm.shader.resource_path).ends_with("scan_wood.gdshader"):
			continue
		seen_use[float(sm.get_shader_parameter(&"use_wear"))] = true
		var id := String(m.member_id)
		if id.contains("/tread/"):
			treads += 1
			check_eq(_role_of(mi), 4.0, "%s dished as a tread" % id)
		elif m.has_meta(&"latch"):
			leaves += 1
			check_eq(_role_of(mi), 3.0, "%s worn as a door's leaf" % id)
			# The latch edge (away from the hinge) is the board's +Y.
			var ey: Vector3 = mi.transform.basis.y
			check(ey.dot(m.get_meta(&"latch")) > 0.5, "%s's latch at its board's +Y" % id)
	check(treads > 0, "the doctor's stair treads take the library wood (%d)" % treads)
	check(leaves > 0, "his doors' leaves too (%d)" % leaves)
	check_eq(seen_use.keys(), [0.45], "his wood all worn as his spec's use says")
	lab.queue_free()
	await physics_frames(2)
