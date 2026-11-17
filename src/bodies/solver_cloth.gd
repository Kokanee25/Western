class_name SolverCloth
extends Node3D
## A garment as our own cloth (`ClothCore` in the native plugin, docs/briefs/garment-cloth.md, #973):
## the same calls as GarmentCloth (the Jolt soft body), so GarmentHandoff can use either (`pin_to`,
## `hold_on`, `move_held`, `release`, `let_go`, `points_now`, `came_to_rest`, `resting`, `stretch`).
## GarmentCloth stays the fallback where the plugin isn't loaded (`available()`; the web build).
##
## Step 1 (the core): stretch with a strain limit, bending, pins, damping and a floor plane at
## `floor_y`. Step 2: his skin as the collider (`set_body`, `move_body`: SkinCollider passes his posed
## skin under the garment each tick), each point kept `body_thickness` off it on the side it came
## from, with friction. It doesn't meet itself or the world's props yet (the brief's steps 3 and 4).
##
## Its points are world positions (this node sits at the origin unturned), drawn each tick as a plain
## mesh of its own triangles. At rest (`rest_after` s with its points' mean speed, a quarter second
## at a time, under `rest_speed`) it stops stepping and stays drawn where it lies: 0 a tick.

signal came_to_rest

enum Held { FREE, HAND }

## Bending: FLAT (isometric: lies flat when let be) or SHAPED (keeps its made shape's folds).
const FLAT := 0
const SHAPED := 1
const SAMPLE := 0.25

var core: RefCounted
var look: Material
var held := Held.FREE
var holder: HumanBody
var side := ""
var resting := false
var rest_speed := 0.01
var rest_after := 0.75
var last_mean_speed := 0.0
## The last tick's solver time (ms, this machine).
var last_millis := 0.0
var mesh_instance: MeshInstance3D

var _start := PackedVector3Array()
var _tri := PackedInt32Array()
var _uv := PackedVector2Array()
var _pins: Array = []   # [point, node, local position] carried by a node (`pin_to`)
var _mesh: ArrayMesh
var _still := 0.0
var _sample_t := 0.0
var _prev := PackedVector3Array()
var _edges := PackedInt32Array()
var _edge_rest := 0.0


static func available() -> bool:
	return ClassDB.class_exists(&"ClothCore")


## Made from `points` (world) and `triangles`; `tune` as ClothCore.tune's names (e.g. bend_stiffness,
## bend_mode, max_strain, damping, floor_y, substeps). Null without the plugin.
static func make(points: PackedVector3Array, triangles: PackedInt32Array, uv: PackedVector2Array,
		material: Material, density := 0.4, tune := {}) -> SolverCloth:
	if not available():
		return null
	var c := SolverCloth.new()
	c.core = ClassDB.instantiate(&"ClothCore")
	for k: String in tune:
		if not c.core.tune(k, float(tune[k])):
			push_warning("SolverCloth: no number '%s'" % k)
	if not c.core.build(points, triangles, density):
		return null
	c._start = points
	c._tri = triangles
	c._uv = uv
	c.look = material
	return c


func _ready() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "Cloth"
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if look:
		mesh_instance.material_override = look
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.05, 0.04, 0.04)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_instance.material_override = m
	add_child(mesh_instance)
	_draw(_start, core.normals())
	set_physics_process(true)


func point_count() -> int:
	return _start.size()


## Pinned to `to` where they are (no jump): the fingertips to the hand that takes them.
func pin_to(points: Array[int], to: Node3D, by: HumanBody = null, hand_side := "") -> void:
	_unpin_carried()
	var now := points_now()
	var inv := to.global_transform.affine_inverse()
	core.pin(PackedInt32Array(points), true)
	for i in points:
		_pins.append([i, to, inv * now[i]])
	holder = by
	side = hand_side
	held = Held.HAND
	_wake()


## Held where they are (friction, until a pull reaches them); moved each tick by `move_held`.
func hold_on(points: Array[int]) -> void:
	core.pin(PackedInt32Array(points), true)
	_wake()


## Held points `points` to `at` (world; `at` indexed by point, as GarmentCloth's).
func move_held(points: PackedInt32Array, at: PackedVector3Array) -> void:
	var to := PackedVector3Array()
	to.resize(points.size())
	for k in points.size():
		to[k] = at[points[k]]
	core.move_pins(points, to)


## These let go (the pull has reached them): free cloth from now on.
func release(points: Dictionary) -> void:
	var go := PackedInt32Array()
	for i: int in points:
		go.append(i)
	core.pin(go, false)
	var keep: Array = []
	for p: Array in _pins:
		if not points.has(int(p[0])):
			keep.append(p)
	_pins = keep
	_wake()


## All of it let go, thrown with `velocity` (m/s).
func let_go(velocity := Vector3.ZERO) -> void:
	_unpin_carried()
	var all := PackedInt32Array()
	for i in _start.size():
		all.append(i)
	core.pin(all, false)
	holder = null
	side = ""
	held = Held.FREE
	if velocity != Vector3.ZERO:
		core.add_velocity(velocity)
	_wake()


## His skin as the collider: `points` (world, now) and `triangles` (fixed from now on).
func set_body(points: PackedVector3Array, triangles: PackedInt32Array) -> bool:
	return core.set_body(points, triangles)


## His skin's points (as many as `set_body` had) where they'll be at the end of the next tick.
func move_body(points: PackedVector3Array) -> void:
	core.move_body(points)


func clear_body() -> void:
	core.clear_body()


## His finer skin (his hand's, #1008: `body_verts`): its vertices kept behind the cloth's triangles,
## where his body (the garment's own points) is too coarse to keep his fingers in. After `set_body`.
func set_skin(points: PackedVector3Array, triangles: PackedInt32Array) -> bool:
	return core.set_skin(points, triangles)


## His finer skin's out of the garment (it's left his hand, #1008): pushed back only from shallow.
func skin_out() -> void:
	core.skin_out()


func move_skin(points: PackedVector3Array) -> void:
	core.move_skin(points)


## Points touching his skin at the last tick's end, and crossings caught since it was set.
func body_contacts() -> int:
	return core.body_contacts()


func body_crossings() -> int:
	return core.body_crossings()


## One of ClothCore.tune's numbers, now (e.g. damping once it's out of his hand).
func tune(name: String, value: float) -> void:
	if not core.tune(name, value):
		push_warning("SolverCloth: no number '%s'" % name)


func points_now() -> PackedVector3Array:
	return core.points()


func start_points() -> PackedVector3Array:
	return _start


func triangles() -> PackedInt32Array:
	return _tri


## How much longer its edges are now than as made, on the whole (1.0 = not stretched).
func stretch(now := PackedVector3Array()) -> float:
	if _edges.is_empty():
		var seen := {}
		for t in range(0, _tri.size(), 3):
			for k in 3:
				var a := _tri[t + k]
				var b := _tri[t + (k + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not seen.has(key):
					seen[key] = true
					_edges.append(key.x)
					_edges.append(key.y)
					_edge_rest += _start[a].distance_to(_start[b])
	if now.is_empty():
		now = points_now()
	var total := 0.0
	for e in range(0, _edges.size(), 2):
		total += now[_edges[e]].distance_to(now[_edges[e + 1]])
	return total / maxf(_edge_rest, 1e-6)


func centre() -> Vector3:
	var sum := Vector3.ZERO
	var now := points_now()
	for p in now:
		sum += p
	return sum / maxf(now.size(), 1)


func _unpin_carried() -> void:
	var ids := PackedInt32Array()
	for p: Array in _pins:
		ids.append(int(p[0]))
	core.pin(ids, false)
	_pins.clear()


func _wake() -> void:
	if resting:
		resting = false
		set_physics_process(true)
	_still = 0.0
	_prev = PackedVector3Array()
	_sample_t = 0.0


func _physics_process(delta: float) -> void:
	if resting:
		return
	var pt := Prof.start()
	if not _pins.is_empty():
		var ids := PackedInt32Array()
		var at := PackedVector3Array()
		for p: Array in _pins:
			var node: Node3D = p[1]
			if not is_instance_valid(node):
				continue
			ids.append(int(p[0]))
			at.append(node.global_transform * (p[2] as Vector3))
		core.move_pins(ids, at)
	core.step(delta)
	last_millis = core.millis()
	var now: PackedVector3Array = core.points()
	_draw(now, core.normals())
	Prof.stop(&"cloth", pt)
	if held != Held.FREE:
		_still = 0.0
		return
	# Its points compared a quarter second apart (as GarmentCloth: a point shivering on the floor is
	# cm/s a tick but nothing over a quarter second).
	_sample_t += delta
	if _sample_t < SAMPLE:
		return
	var dt := _sample_t
	_sample_t = 0.0
	if _prev.size() == now.size():
		var mean := 0.0
		for i in now.size():
			mean += now[i].distance_to(_prev[i])
		mean /= now.size() * dt
		_still = _still + dt if mean < rest_speed else 0.0
		last_mean_speed = mean
	_prev = now
	if _still >= rest_after - 0.001:
		resting = true
		set_physics_process(false)
		came_to_rest.emit()


func _draw(pts: PackedVector3Array, nrm: PackedVector3Array) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pts
	arrays[Mesh.ARRAY_NORMAL] = nrm
	if _uv.size() == pts.size():
		arrays[Mesh.ARRAY_TEX_UV] = _uv
	arrays[Mesh.ARRAY_INDEX] = _tri
	if _mesh == null:
		_mesh = ArrayMesh.new()
		mesh_instance.mesh = _mesh
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
