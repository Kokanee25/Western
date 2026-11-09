class_name FramedStructure
extends Structure
## A structure whose members are framed by code that knows what bears on what (the valley's road
## bridges and the tunnel portal, G3; the way the Trestle is framed): the builder says each link as
## it frames it (`framed`: this member bears on that one, here), so the support graph isn't searched
## by pairs, and members of the kinds in `ground_kinds` stand on the ground wherever it is (a bridge's
## footings on a slope, not on y = 0). The stack order is each member after everything it rests on.
##
## Subclasses add members in `build()` with `timber()` (a squared timber from a to b) or
## `add_member()`, and call `framed()` for each support.

## Members of these kinds rest on the ground (their footings), wherever they stand.
var ground_kinds: Array[StringName] = [&"pier", &"sill"]
## [member, support, point (structure space)] as framed.
var _links: Array = []
## [member, member] touching but not bearing (nailed side by side).
var _touch: Array = []


func build() -> void:
	_links.clear()
	_touch.clear()


## A squared timber from a to b (structure space), `width` across and `depth` toward `up_hint`.
func timber(path: String, kind: StringName, wood: StringName, a: Vector3, b: Vector3, width: float, depth: float, up_hint := Vector3.UP) -> StructureMember:
	var dir := b - a
	var length := dir.length()
	dir /= maxf(length, 1e-6)
	var y := up_hint - dir * up_hint.dot(dir)
	if y.length() < 1e-4:
		y = Vector3.FORWARD - dir * Vector3.FORWARD.dot(dir)
	y = y.normalized()
	var x := y.cross(dir).normalized()
	return add_member(path, kind, wood, Vector3(width, depth, length), (a + b) * 0.5, Basis(x, y, dir))


## `m` bears on `support` at `at` (structure space).
func framed(m: StructureMember, support: StructureMember, at: Vector3) -> void:
	if m and support:
		_links.append([m, support, at])


## `a` and `b` touch (nailed side by side) without one bearing on the other.
func touch(a: StructureMember, b: StructureMember) -> void:
	if a and b:
		_touch.append([a, b])


func infer_supports() -> void:
	invalidate_analysis()
	for m in _order:
		m.supported_by.clear()
		m.dependents.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		m.grounded = m.kind in ground_kinds
	for l: Array in _links:
		var m: StructureMember = l[0]
		var s: StructureMember = l[1]
		if not is_instance_valid(m) or not is_instance_valid(s) or m.supported_by.has(s.member_id):
			continue
		m.supported_by.append(s.member_id)
		s.dependents.append(m.member_id)
		m.support_points[s.member_id] = l[2]
		m.touching.append(s.member_id)
		s.touching.append(m.member_id)
	for l: Array in _touch:
		if is_instance_valid(l[0]) and is_instance_valid(l[1]):
			(l[0] as StructureMember).touching.append((l[1] as StructureMember).member_id)
			(l[1] as StructureMember).touching.append((l[0] as StructureMember).member_id)
	var depth := {}
	for m in _order:
		_depth(m, depth)
	for m in _order:
		m.stack_key = float(depth[m.member_id]) + m.position.y * 1e-4


func _depth(m: StructureMember, depth: Dictionary) -> int:
	var id := m.member_id
	if depth.has(id):
		return int(depth[id])
	depth[id] = 0
	var d := 0
	for s in m.supported_by:
		var o := get_member(s)
		if o:
			d = maxi(d, _depth(o, depth) + 1)
	depth[id] = d
	return d
