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
	_library_pieces()


## Pieces with a `lib` meta (the spring's box, stones and pipe: #1160) drawn as boards of that library
## entry (scan_wood, as SpecBuilding does for a building's members) instead of the factory's `framing` and
## `stone`. Done here, before the structure batches its meshes.
func _library_pieces() -> void:
	var mats := {}
	var gy0 := global_position.y if is_inside_tree() else 0.0
	for m: StructureMember in get_members():
		if not m.has_meta(&"lib"):
			continue
		var mi := m.drawn_node()
		if mi == null:
			continue
		var entry := String(m.get_meta(&"lib"))
		if not mats.has(entry):
			var mat := ShaderMaterial.new()
			mat.shader = load("res://src/render/scan_wood.gdshader")
			MaterialLibrary.apply(mat, MaterialLibrary.entry(entry), 0.5, &"wall")
			mat.set_shader_parameter(&"wall_top", 3.0)
			mat.set_shader_parameter(&"use_wear", 0.2)
			mat.set_shader_parameter(&"dings", 0.0)
			mats[entry] = mat
		var sz := m.size
		var order := [0, 1, 2]
		order.sort_custom(func(a: int, b: int) -> bool: return sz[a] > sz[b])
		var ex := Vector3.ZERO
		ex[order[0]] = 1.0
		var ey := Vector3.ZERO
		ey[order[1]] = 1.0
		var ez := ex.cross(ey)
		var length: float = sz[order[0]]
		var rng := hash(m.member_id)
		mi.mesh = PropKit.board_mesh(length, sz[order[1]], sz[order[2]], float(rng % 100000) / 100000.0, 0.0, Vector2(0, 0.6),
				gy0 + float(m.get_meta(&"ground_y", 0.0)), 0.0)
		mi.transform = Transform3D(Basis(ex, ey, ez), -ex * length * 0.5)
		mi.material_override = mats[entry]


func _place_in_stack(m: StructureMember, box: AABB) -> void:
	var tier := StructureMember.tier_of(m.kind)
	m.grounded = tier <= 1 and box.position.y <= float(m.get_meta(&"ground_y", 0.0)) + GROUND_EPSILON
	m.stack_key = tier * 100.0 + box.position.y
