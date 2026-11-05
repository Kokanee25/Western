class_name MasonryWall
extends RefCounted
## A masonry structure's expanded form as arrays (config/destruction/structures/FORMAT.md; the spec's
## section 2): its elements (boxes, materials, what each rests on) and the joints between them with
## their state. Pure data: MasonryStructure builds members from it and keeps the joints' state here;
## MasonryBlast and the masonry checks in StructuralAnalysis read it. Indices, not ids, inside.

enum Joint { BED, HEAD, COLLAR }
const TYPES := {"bed": Joint.BED, "head": Joint.HEAD, "collar": Joint.COLLAR}

var ids: Array[StringName] = []
var index := {}  # id -> i
var kinds: Array[StringName] = []
var materials: Array[StringName] = []
var at := PackedVector3Array()  # its centre, the file's space
var size := PackedVector3Array()  # [along, high, deep]
var turn := PackedFloat32Array()  # degrees about +y
var mass := PackedFloat32Array()  # kg
var course := PackedInt32Array()
var wythe := PackedInt32Array()
var rests_on: Array[PackedInt32Array] = []  # -1: the ground
## Its box in its wall's own space (x along from `from`, y up, z in from the outer face).
var wall_of := PackedInt32Array()
var lo := PackedVector3Array()
var hi := PackedVector3Array()
## The walls: {from: Vector2, dir: Vector2 (unit, along), normal: Vector2 (in from the outer face), thick}
var walls: Array[Dictionary] = []

## The joints.
var ja := PackedInt32Array()
var jb := PackedInt32Array()
var jtype := PackedByteArray()
var jarea := PackedFloat32Array()
var jtension := PackedFloat32Array()  # Pa: the mortar's tension (what holds the joint open)
var bonded := PackedByteArray()  # 1 bonded, 0 broken (it still bears in compression and by friction)
var of: Array[PackedInt32Array] = []  # each element's joints
## The weight (N) pressing down on each element's bed from the wall over it (its share of every
## element above whose bed overlaps it), and its mortar's friction: what clamps it in by friction
## (the spec's S4: friction x N) however its joints are.
var pressed := PackedFloat32Array()
var friction := PackedFloat32Array()


static func from_spec(spec: Dictionary) -> MasonryWall:
	var w := MasonryWall.new()
	var mats := MasonryMaterials.data()
	for wall: Dictionary in spec.get("walls", []):
		var from := Vector2(float(wall.from[0]), float(wall.from[1]))
		var to := Vector2(float(wall.to[0]), float(wall.to[1]))
		var dir := (to - from).normalized()
		var mat: Dictionary = mats.materials.get(String(wall.material), {})
		var thick := float(wall.get("thick", mat.get("wall", {}).get("thick_typical", 0.5)))
		w.walls.append({"id": String(wall.id), "from": from, "dir": dir, "normal": Vector2(-dir.y, dir.x), "thick": thick})
	var wall_index := {}
	for k in w.walls.size():
		wall_index[w.walls[k].id] = k
	var els: Array = spec.get("elements", [])
	for e: Dictionary in els:
		var i := w.ids.size()
		var id := StringName(e.id)
		w.ids.append(id)
		w.index[id] = i
		w.kinds.append(StringName(e.kind))
		w.materials.append(StringName(e.material))
		var c := Vector3(float(e.at[0]), float(e.at[1]), float(e.at[2]))
		var s := Vector3(float(e.size[0]), float(e.size[1]), float(e.size[2]))
		w.at.append(c)
		w.size.append(s)
		w.turn.append(float(e.get("turn", 0.0)))
		w.mass.append(s.x * s.y * s.z * MasonryMaterials.density(StringName(e.material)))
		w.course.append(int(e.get("course", 0)))
		w.wythe.append(int(e.get("wythe", 0)))
		var k: int = wall_index.get(String(e.id).get_slice("/", 0), 0)
		w.wall_of.append(k)
		var wl: Dictionary = w.walls[k] if k < w.walls.size() else {"from": Vector2.ZERO, "dir": Vector2.RIGHT, "normal": Vector2.UP, "thick": s.z}
		var p: Vector2 = Vector2(c.x, c.z) - (wl.from as Vector2)
		var mid := Vector3(p.dot(wl.dir), c.y, p.dot(wl.normal))
		w.lo.append(mid - s * 0.5)
		w.hi.append(mid + s * 0.5)
		w.of.append(PackedInt32Array())
	for e: Dictionary in els:
		var r := PackedInt32Array()
		for o: String in e.get("rests_on", []):
			r.append(-1 if o == "ground" else int(w.index.get(StringName(o), -1)))
		w.rests_on.append(r)
	w._pressed_from_above()
	for i in w.count():
		w.friction.append(float(MasonryMaterials.mortar_of(w.materials[i]).get("friction", 0.6)))
	for j: Dictionary in spec.get("joints", []):
		var a: int = w.index.get(StringName(j.a), -1)
		var b: int = w.index.get(StringName(j.b), -1)
		if a < 0 or b < 0:
			continue
		var n := w.ja.size()
		w.ja.append(a)
		w.jb.append(b)
		w.jtype.append(TYPES.get(String(j.type), Joint.BED))
		w.jarea.append(float(j.area))
		w.jtension.append(float(mats.mortars.get(String(j.get("mortar", "lime")), {}).get("tension", 0.0)))
		w.bonded.append(1)
		w.of[a].append(n)
		w.of[b].append(n)
	return w


## What presses on each element from above: every element over it (same wall) that overlaps it in
## plan, by the share of its bed that's over it.
func _pressed_from_above() -> void:
	pressed.resize(count())
	pressed.fill(0.0)
	for k in count():
		var bed: float = (hi[k].x - lo[k].x) * (hi[k].z - lo[k].z)
		for i in count():
			if i == k or wall_of[i] != wall_of[k] or lo[k].y < hi[i].y - 0.001:
				continue
			var ox := minf(hi[i].x, hi[k].x) - maxf(lo[i].x, lo[k].x)
			var oz := minf(hi[i].z, hi[k].z) - maxf(lo[i].z, lo[k].z)
			if ox > 0.0 and oz > 0.0:
				pressed[i] += mass[k] * 9.81 * ox * oz / maxf(bed, 1e-6)


func count() -> int:
	return ids.size()


func other(j: int, i: int) -> int:
	return jb[j] if ja[j] == i else ja[j]


## A point in the file's space in wall `k`'s own (x along, y up, z in from the outer face).
func to_wall(k: int, p: Vector3) -> Vector3:
	var wl: Dictionary = walls[k]
	var q := Vector2(p.x, p.z) - (wl.from as Vector2)
	return Vector3(q.dot(wl.dir), p.y, q.dot(wl.normal))


## A direction in wall `k`'s space back into the file's.
func from_wall_dir(k: int, d: Vector3) -> Vector3:
	var wl: Dictionary = walls[k]
	var h: Vector2 = (wl.dir as Vector2) * d.x + (wl.normal as Vector2) * d.z
	return Vector3(h.x, d.y, h.y)


## Its bonded joints' bond (N): what holds it to the rest in tension (the spec's "pushed out of a
## wall whose other side is free"), but the joints in `skip` (j -> true).
func bond_of(i: int, skip := {}) -> float:
	var sum := 0.0
	for j in of[i]:
		if bonded[j] == 1 and not skip.has(j):
			sum += jtension[j] * jarea[j]
	return sum
