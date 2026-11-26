extends TestCase
## Every door swings clear (#1266, Sean's walk 2026-11-25: saloon B's leaves crossed in a doorway and
## some wouldn't open): each leaf SpecBuilding hangs in saloon B opens from shut to where it stands
## without meeting a member, furniture or another leaf (Checks.door_swings).

const Lab := preload("res://experiments/building_lab/lab.gd")
const Checks := preload("res://experiments/building_lab/checks.gd")


func _swings(spec: String) -> Dictionary:
	Lab.spec_path = spec
	var lab: Node3D = Lab.new()
	add_child(lab)
	Lab.spec_path = ""
	await physics_frames(3)
	var r := Checks.door_swings(lab.building)
	for l: Dictionary in r.leaves:
		print("  %s at %s swings %s%s" % [l.leaf, l.hinge, l.swings, "" if (l.met as Dictionary).is_empty() else ", meets %s" % [l.met]])
	lab.queue_free()
	await physics_frames(2)
	return r


func test_saloon_b_doors_swing_clear() -> void:
	var r: Dictionary = await _swings("res://config/buildings/saloon_b.json")
	check((r.leaves as Array).size() >= 20, "every door has its leaf (%d)" % (r.leaves as Array).size())
	check(r.ok, "every leaf opens without meeting anything: %s" % [r.failures])
