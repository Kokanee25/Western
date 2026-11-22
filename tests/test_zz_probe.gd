extends TestCase
const Lab := preload("res://experiments/building_lab/lab.gd")
func test_probe() -> void:
	Lab.spec_path = "res://config/buildings/church.json"
	var lab = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)
	var b: Structure = lab.building
	for mm: StructureMember in b.get_members():
		var id := String(mm.member_id)
		if id.contains("tower/spire/hip_0") or id.contains("spire/common_0") or id.ends_with("shingle_0_05") or id.ends_with("shingle_0_00") or id.ends_with("tower/belfry/ring_front"):
			print("PROBE ", id, " pos ", mm.transform.origin, " size ", mm.size, " supp ", mm.supported_by)
	var r := Checks.stands(b)
	print("PROBE falling ", r.dead.falling, " ", r.dead.get("falling_first", []))
	check(true, "x")
const Checks := preload("res://experiments/building_lab/checks.gd")
