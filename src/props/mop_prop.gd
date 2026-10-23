class_name MopProp
extends Node3D
## The barkeep's mop (kit kind "mop", `mop.json`; docs/briefs/mopping.md): an ash handle and a head
## of cotton strands lashed to its foot, the head one Jolt soft body (the rag's parts, ClothProp:
## its pinned tops moved by the prop each tick, as Jolt doesn't hold them).
##
## - **Standing** in its corner: the handle fixed, leaning, the head slumped on the floor.
## - **Held:** whoever has it puts its foot and its lean each tick (`hold_at`); his hands go on its
##   handle (`grip`).
## - **Free:** dropped, the handle a rigid body.
## The head holds water (`holds` times its dry weight; it drips past `drips_above`) and what it's
## picked up. Dragged over the boards (FloorMarks) wet, it lifts a share of what's under it, faster
## the faster it moves; it leaves a thin film of its own water and with it a share of what it holds
## (a dirty mop spreads dirt). In its bucket's water it rinses (`MopBucket`): what it holds goes into
## the water and the water's comes back; `press` wrings it out against the bucket.

enum State { STANDING, HELD, FREE }

const EXCHANGE_EVERY := 0.1  ## s between its passes over the floor
const CONTACT := 0.035  ## a strand point this near the floor is on it (m)
const LIFT_RADIUS := 0.16  ## what's this near the head's middle comes up (m)

var kit_id := &"mop"
var definition := {}
var state := State.STANDING
var holder: HumanBody
var handle: RigidBody3D
var head: SoftBody3D
## Water in the head (ml), and what's in it with the water: dirt (g), blood and drink (ml).
var water_ml := 0.0
var dirt := 0.0
var blood := 0.0
var other := 0.0
var rng_seed := 11

var _pins: Array = []  # [point index, its place in the handle's frame]
var _count := 0
var _mat: StandardMaterial3D
var _t := 0.0
var _last_foot := Vector3.INF
var _marks: FloorMarks
var _through := {}  # buckets its head passes into
var _floor_y := -INF  # the boards under its head at the last pass (-INF: none)


func _ready() -> void:
	if definition.is_empty():
		definition = PropKit.definition(kit_id)
	add_to_group(&"mops")
	_build()


func length() -> float:
	return float(definition.get("handle_length", 1.3))


func dry_mass() -> float:
	return float(definition.get("head_mass", 0.2))


func capacity_ml() -> float:
	return dry_mass() * 1000.0 * float(definition.get("holds", 3.0))


func wrung_ml() -> float:
	return dry_mass() * 1000.0 * float(definition.get("wrung", 1.0))


func _build() -> void:
	handle = RigidBody3D.new()
	handle.name = "Handle"
	handle.mass = float(definition.get("handle_mass", 0.6))
	handle.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	handle.freeze = true
	handle.collision_layer = Layers.DEBRIS
	handle.collision_mask = Layers.DEBRIS_MASK
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = float(definition.get("handle_radius", 0.016))
	cap.height = length()
	cs.shape = cap
	cs.position.y = length() * 0.5
	handle.add_child(cs)
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = cap.radius
	cyl.bottom_radius = cap.radius
	cyl.height = length()
	cyl.radial_segments = 6
	cyl.rings = 1
	mi.mesh = cyl
	mi.position.y = length() * 0.5
	mi.material_override = PropModels.mid_wood()
	handle.add_child(mi)
	handle.set_meta(&"mop", self)
	add_child(handle)
	handle.transform = Transform3D.IDENTITY
	head = SoftBody3D.new()
	head.name = "Head"
	head.mesh = _strands_mesh()
	head.total_mass = dry_mass()
	head.linear_stiffness = float(definition.get("stiffness", 0.9))
	head.damping_coefficient = float(definition.get("damping", 0.08))
	head.simulation_precision = int(definition.get("precision", 6))
	head.collision_layer = 0
	head.collision_mask = Layers.WORLD | Layers.BODY_PARTS | Layers.DEBRIS
	head.ray_pickable = false
	_mat = StandardMaterial3D.new()
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.roughness = 1.0
	_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	head.material_override = _mat
	add_child(head)
	head.add_collision_exception_with(handle)
	_tint()


## The strands, hanging from a ring round the handle's foot (in its frame: the foot at the origin,
## the handle up +Y): each a narrow strip, its top two points pinned.
func _strands_mesh() -> ArrayMesh:
	var n := int(definition.get("strands", 10))
	var rows := int(definition.get("strand_points", 4))
	var l := float(definition.get("strand_length", 0.3))
	var w := float(definition.get("strand_width", 0.03))
	var ring := float(definition.get("ring_radius", 0.03))
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	_pins.clear()
	for s in n:
		var a := TAU * s / n
		var out := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-out.z, 0.0, out.x)
		var base := verts.size()
		for r in rows:
			for c in 2:
				# The strands splay outward as they hang.
				var p := out * (ring + 0.06 * float(r) / (rows - 1)) + side * (c - 0.5) * w - Vector3.UP * l * float(r) / (rows - 1)
				verts.append(p)
				normals.append(out)
				if r == 0:
					_pins.append([verts.size() - 1, p])
		for r in rows - 1:
			var i := base + r * 2
			idx.append_array([i, i + 1, i + 2, i + 1, i + 3, i + 2])
	_count = verts.size()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


func point_count() -> int:
	return _count


func point(i: int) -> Vector3:
	return head.get_point_transform(i)


## The handle's foot (where the head's lashed) and a point `t` m up the handle from it.
func foot() -> Vector3:
	return handle.global_position


func grip(t: float) -> Vector3:
	return handle.global_transform * Vector3(0, t, 0)


func up() -> Vector3:
	return handle.global_basis.y.normalized()


# --- States ----------------------------------------------------------------------------------------

## Standing leant with its foot at `at`, the handle up along `lean` (its pins carry the head there).
func stand_at(at: Vector3, lean := Vector3.UP) -> void:
	if holder != null and is_instance_valid(holder):
		_hands_through(holder, false)
	var was := state
	holder = null
	state = State.STANDING
	handle.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	handle.freeze = true
	handle.collision_layer = Layers.DEBRIS
	_place(at, lean)
	if was != State.HELD:
		_lay_head()  # (put there: laid straight; set down from a hand, it's already hanging right)


## In `by`'s hands: from now on `hold_at` places it each tick.
func take(by: HumanBody) -> void:
	holder = by
	state = State.HELD
	handle.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	handle.freeze = true
	handle.collision_layer = 0  # (his hands move it; it doesn't shove the cups)
	if by != null:
		_hands_through(by, true)


## Its foot at `at`, the handle along `lean` (up from the foot toward his hands).
func hold_at(at: Vector3, lean: Vector3) -> void:
	_place(at, lean)


func let_go() -> void:
	if holder != null and is_instance_valid(holder):
		_hands_through(holder, false)
	holder = null
	state = State.FREE
	handle.collision_layer = Layers.DEBRIS
	handle.freeze = false
	handle.sleeping = false


func _place(at: Vector3, lean: Vector3) -> void:
	var y := lean.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	handle.global_transform = Transform3D(Basis(x, y, z), at)


## The head laid straight where its pins are (placing it at the start).
func _lay_head() -> void:
	if not head.is_inside_tree():
		return
	var rid := head.get_physics_rid()
	var xf := handle.global_transform
	var verts: PackedVector3Array = (head.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] if head.mesh is ArrayMesh else PackedVector3Array()
	# What would hang below the floor is laid out along it instead, splayed from the foot.
	var f := xf.origin
	var q := PhysicsRayQueryParameters3D.create(f + Vector3.UP * 0.2, f - Vector3.UP * 0.6, Layers.WORLD)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var floor_y: float = (hit.position as Vector3).y + 0.012 if not hit.is_empty() else -INF
	for i in verts.size():
		var p := xf * verts[i]
		if p.y < floor_y:
			var out := Vector3(p.x - f.x, 0.0, p.z - f.z)
			out = out.normalized() if out.length() > 1e-4 else Vector3.FORWARD
			p += out * (floor_y - p.y)
			p.y = floor_y
		PhysicsServer3D.soft_body_move_point(rid, i, p)


func _hands_through(who: HumanBody, through: bool) -> void:
	for sid in [&"hand_r", &"hand_l", &"forearm_r", &"forearm_l"]:
		var got: Variant = who.parts.get(sid)
		if not is_instance_valid(got):
			continue
		if through:
			head.add_collision_exception_with(got as PhysicsBody3D)
		else:
			head.remove_collision_exception_with(got as PhysicsBody3D)


# --- Each tick -------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_step(delta)
	Prof.stop(&"mop", t)


func _step(delta: float) -> void:
	if holder != null and (not is_instance_valid(holder) or holder.limp):
		let_go()
	if not head.is_inside_tree():
		return
	var rid := head.get_physics_rid()
	var xf := handle.global_transform
	for p: Array in _pins:
		if not head.is_point_pinned(int(p[0])):
			head.set_point_pinned(int(p[0]), true)
		PhysicsServer3D.soft_body_move_point(rid, int(p[0]), xf * (p[1] as Vector3))
	_keep_on_floor(rid)
	_t -= delta
	if _t > 0.0:
		return
	_t = EXCHANGE_EVERY
	_exchange(EXCHANGE_EVERY)


## A strand dragged or flung hard into thin boards can get through them (the soft body's points
## have no thickness to Jolt): one that's slipped under the floor it's on is put back on top.
func _keep_on_floor(rid: RID) -> void:
	if _floor_y == -INF:
		return
	for i in _count:
		var p := head.get_point_transform(i)
		if p.y < _floor_y - 0.004 and p.y > _floor_y - 0.3:
			PhysicsServer3D.soft_body_move_point(rid, i, Vector3(p.x, _floor_y + 0.002, p.z))


## Its water and the floor and its bucket: what it lifts, what it leaves, what drips.
func _exchange(dt: float) -> void:
	if _marks == null or not is_instance_valid(_marks):
		_marks = FloorMarks.find(get_tree())
	var f := foot()
	var moved := 0.0 if _last_foot == Vector3.INF else Vector2(f.x - _last_foot.x, f.z - _last_foot.z).length() / dt
	_last_foot = f
	# In a bucket's water: it rinses. (Its strands go in past the bucket's sides, not into them.)
	for b: Node in get_tree().get_nodes_in_group(&"mop_buckets"):
		var bucket := b as MopBucket
		if bucket != null and not _through.has(bucket):
			_through[bucket] = true
			head.add_collision_exception_with(bucket.body)
		if bucket != null and bucket.holds(_head_middle()):
			_rinse(bucket, dt)
			return
	if _marks == null:
		return
	var low := _lowest()
	var under := _marks.surface_at(Vector3(f.x, low.y, f.z), 0.25)
	if under.is_empty():
		_floor_y = -INF
		return
	var floor_y: float = (under.at as Vector3).y
	_floor_y = floor_y
	var contact := _contact(floor_y)
	var at := Vector3(_head_middle().x, floor_y, _head_middle().z)
	if contact > 0.0:
		var wet := clampf(water_ml / maxf(wrung_ml(), 1.0), 0.0, 1.5)
		# Wet, dragged, not yet full of muck: it lifts.
		var full := clampf((dirt * 20.0 + blood + other) / maxf(water_ml, 50.0), 0.0, 1.0)
		var share := float(definition.get("take_rate", 1.6)) * contact * clampf(moved / 0.35, 0.15, 1.0) \
				* lerpf(0.25, 1.0, clampf(wet, 0.0, 1.0)) * (1.0 - 0.8 * full) * dt
		var got := _marks.take(at, LIFT_RADIUS, share)
		dirt += float(got.dirt)
		blood += float(got.blood)
		for kind: StringName in got.liquid:
			var ml: float = got.liquid[kind]
			if kind == &"water":
				water_ml += ml
			elif kind == &"blood":
				blood += ml
			else:
				other += ml
		# It leaves a film of its own water, and what's in it.
		var leave := minf(float(definition.get("leave_ml_s", 4.0)) * contact * clampf(wet, 0.0, 1.0) * clampf(moved / 0.35, 0.3, 1.0) * dt, water_ml * 0.5)
		if leave > 0.01:
			var k := leave / maxf(water_ml, 1.0)
			_marks.add_liquid(at, &"water", leave, LIFT_RADIUS)
			_marks.add_dirt(at, dirt * k, 0.6)
			if blood * k > 0.01:
				_marks.add_liquid(at, &"blood", blood * k, LIFT_RADIUS)
			water_ml -= leave
			dirt -= dirt * k
			blood -= blood * k
			other -= other * k
	# Too wet, it drips where it is.
	if water_ml > wrung_ml() * float(definition.get("drips_above", 2.2)) / float(definition.get("wrung", 1.0)):
		var drip := float(definition.get("drip_ml_s", 6.0)) * dt
		var k := drip / maxf(water_ml, 1.0)
		_marks.add_liquid(Vector3(low.x, floor_y, low.z), &"water", drip, FloorMarks.CELL * 0.5)
		water_ml -= drip
		dirt -= dirt * k
		blood -= blood * k
		other -= other * k
	_tint()


func _rinse(bucket: MopBucket, dt: float) -> void:
	# What's in the head and the bucket's water mix a share a second; it soaks up to what it holds.
	var mix := clampf(3.0 * dt, 0.0, 1.0)
	var take_ml := minf(maxf(capacity_ml() - water_ml, 0.0), bucket.water_ml)
	if take_ml > 0.0:
		var got := bucket.give(take_ml)
		water_ml += take_ml
		dirt += float(got.dirt)
		blood += float(got.blood)
		other += float(got.other)
	var c := bucket.concentration()
	var out_d := (dirt - float(c.dirt) * water_ml) * mix
	var out_b := (blood - float(c.blood) * water_ml) * mix
	var out_o := (other - float(c.other) * water_ml) * mix
	dirt -= out_d
	blood -= out_b
	other -= out_o
	bucket.receive(0.0, out_d, out_b, out_o)
	_tint()


## Wrung out against the bucket: its water down toward `wrung`, what's squeezed out (and its share
## of muck) into the bucket.
func press(bucket: MopBucket, dt: float) -> void:
	var out := minf(maxf(water_ml - wrung_ml(), 0.0), capacity_ml() * 1.5 * dt)
	if out <= 0.0:
		return
	var k := out / maxf(water_ml, 1.0)
	bucket.receive(out, dirt * k, blood * k, other * k)
	water_ml -= out
	dirt -= dirt * k
	blood -= blood * k
	other -= other * k
	_tint()


func _head_middle() -> Vector3:
	var sum := Vector3.ZERO
	for i in range(0, _count, 3):
		sum += head.get_point_transform(i)
	return sum / float(ceili(_count / 3.0))


func _lowest() -> Vector3:
	var lo := Vector3(0, INF, 0)
	for i in range(0, _count, 2):
		var p := head.get_point_transform(i)
		if p.y < lo.y:
			lo = p
	return lo


## The share of its strands' ends lying on the floor.
func _contact(floor_y: float) -> float:
	var on := 0
	var n := 0
	for i in range(0, _count, 2):
		n += 1
		if head.get_point_transform(i).y < floor_y + CONTACT:
			on += 1
	return float(on) / maxf(n, 1)


## How wet (darker) and how dirty it looks.
func _tint() -> void:
	var c: Array = definition.get("colour", [0.78, 0.75, 0.68])
	var base := Color(c[0], c[1], c[2])
	var w := maxf(water_ml, 50.0)
	var muck := clampf(1.0 - exp(-(dirt * 300.0 + other * 3.0) / w), 0.0, 0.85)
	var red := clampf(1.0 - exp(-blood * 20.0 / w), 0.0, 0.85)
	var col := base.lerp(Color(0.33, 0.25, 0.16), muck).lerp(Color(0.5, 0.12, 0.09), red)
	_mat.albedo_color = col.darkened(0.35 * clampf(water_ml / capacity_ml(), 0.0, 1.0))
