class_name YardStructure
extends Structure
## Loose things of members set out over uneven ground (#1126, Harlan's yard: the woodpile, the chopping
## block and its axe, the repair stock, the spring's box and its pipe down the slope): a Structure whose
## members stand on the ground under them, wherever it is, not only at its own y 0. Each member made by
## `put` carries the ground's height under its foot (meta `ground_y`, this structure's space); a
## sill or post whose foot is on it (within GROUND_EPSILON) is grounded. Built from `pieces`, a list of
## {id, kind, wood, size, at, basis, ground_y, meta} set before it's added (Homestead fills it).

var pieces: Array = []


func build() -> void:
	for p: Dictionary in pieces:
		var m := add_member(String(p.id), StringName(p.kind), StringName(p.wood), p.size, p.at, p.get("basis", Basis()))
		m.set_meta(&"ground_y", float(p.get("ground_y", 0.0)))
		for k: String in (p.get("meta", {}) as Dictionary):
			m.set_meta(StringName(k), p.meta[k])


func _place_in_stack(m: StructureMember, box: AABB) -> void:
	var tier := StructureMember.tier_of(m.kind)
	m.grounded = tier <= 1 and box.position.y <= float(m.get_meta(&"ground_y", 0.0)) + GROUND_EPSILON
	m.stack_key = tier * 100.0 + box.position.y
