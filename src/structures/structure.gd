class_name Structure
extends Node3D
## A building (or boardwalk, trough, rail) made of individual members. Subclasses describe what to
## build in build(); the structure then works out what rests on what (the support graph) from the
## members' positions and kinds. M3 breaks members and lets whatever loses its load path fall.

## Members whose bottom is within this of y = 0 (structure space) rest on the ground.
const GROUND_EPSILON := 0.02
## Members closer than this are in contact (nailed, resting, bolted).
const CONTACT_EPSILON := 0.012

@export var structure_id: StringName = &"structure"
## Seed for any variation in the build (board gaps, tints), so rebuilding is identical.
@export var build_seed := 1

## StringName -> StructureMember
var members := {}

var _order: Array[StructureMember] = []
var _rng := RandomNumberGenerator.new()
var _mesh_cache := {}
var _shape_cache := {}


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for m in _order:
		m.free()
	members.clear()
	_order.clear()
	_rng.seed = build_seed
	build()
	infer_supports()


## Override: add members with add_member().
func build() -> void:
	pass


func member_count() -> int:
	return _order.size()


func get_member(id: StringName) -> StructureMember:
	return members.get(id)


func get_members() -> Array[StructureMember]:
	return _order


func members_of_kind(kind: StringName) -> Array[StructureMember]:
	return _order.filter(func(m: StructureMember) -> bool: return m.kind == kind)


## Add one member: an axis-aligned box of `size` centred at `center` (structure space),
## optionally rotated by `basis`. `id_path` is local to this structure, e.g. "front/stud/03".
func add_member(id_path: String, kind: StringName, wood: StringName, size: Vector3, center: Vector3, basis := Basis()) -> StructureMember:
	var id := StringName("%s/%s" % [structure_id, id_path])
	assert(not members.has(id), "Duplicate member id %s" % id)
	var m := StructureMember.new()
	m.name = id_path.validate_node_name().replace("/", "_")
	m.member_id = id
	m.kind = kind
	m.wood = wood
	m.size = size
	m.transform = Transform3D(basis, center)

	var mi := MeshInstance3D.new()
	mi.mesh = _box_mesh(size)
	mi.material_override = WoodMaterials.get_material(wood, hash(id))
	m.add_child(mi)
	var cs := CollisionShape3D.new()
	cs.shape = _box_shape(size)
	m.add_child(cs)

	add_child(m)
	members[id] = m
	_order.append(m)
	return m


## Work out supports from geometry: a member rests on every lower-tier member it touches.
func infer_supports() -> void:
	var boxes := {}
	for m in _order:
		boxes[m] = m.structure_aabb()
	for m in _order:
		m.supported_by.clear()
		var box: AABB = boxes[m]
		var tier := StructureMember.tier_of(m.kind)
		m.grounded = tier <= 1 and box.position.y <= GROUND_EPSILON
		var grown := box.grow(CONTACT_EPSILON)
		for other in _order:
			if StructureMember.tier_of(other.kind) < tier and grown.intersects(boxes[other]):
				m.supported_by.append(other.member_id)


## True if a chain of supports leads from this member down to the ground.
func has_load_path(id: StringName, broken := {}) -> bool:
	return not id in members_without_load_path(broken)


## Every member that would fall if the members in `broken` (id -> true) were gone. Supports
## always sit in a lower tier, so one pass in tier order settles it.
func members_without_load_path(broken := {}) -> Array[StringName]:
	var sorted := _order.duplicate()
	sorted.sort_custom(func(a: StructureMember, b: StructureMember) -> bool:
		return StructureMember.tier_of(a.kind) < StructureMember.tier_of(b.kind))
	var held := {}
	var falling: Array[StringName] = []
	for m: StructureMember in sorted:
		if broken.has(m.member_id):
			continue
		var ok := m.grounded
		if not ok:
			for s in m.supported_by:
				if held.has(s):
					ok = true
					break
		if ok:
			held[m.member_id] = true
		else:
			falling.append(m.member_id)
	return falling


func rand_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func chance(p: float) -> bool:
	return _rng.randf() < p


func _box_mesh(size: Vector3) -> BoxMesh:
	var key := size.snappedf(0.001)
	if not _mesh_cache.has(key):
		var mesh := BoxMesh.new()
		mesh.size = size
		_mesh_cache[key] = mesh
	return _mesh_cache[key]


func _box_shape(size: Vector3) -> BoxShape3D:
	var key := size.snappedf(0.001)
	if not _shape_cache.has(key):
		var shape := BoxShape3D.new()
		shape.size = size
		_shape_cache[key] = shape
	return _shape_cache[key]
