class_name GarmentCloth
extends ClothProp
## A garment as real cloth while it's taken off (#917, from the garment lab's glove_cloth.gd, #895):
## a ClothProp (its pins carried by the prop, held, let go, knocked, burnt, bloodied) made from the
## garment's own points and triangles (the kit's `mesh`), every point where the worn garment is
## drawn that tick, so the swap doesn't show. Its rest shape is the garment as worn. It meets the
## world and his skin (SkinCollider's layer), nothing else of him.
##
## At rest (`rest_after` s with its points' mean speed, a quarter second at a time, under `rest_speed`)
## the soft body is taken out
## and its shape left as a plain mesh: a glove on the floor costs nothing (`resting`). (Picking it up
## again would make a new soft body from that shape: not built yet.)

signal came_to_rest

var look: Material
var rest_speed := 0.01
var rest_after := 0.75
var resting := false
var baked: MeshInstance3D
var last_mean_speed := 0.0
var _start := PackedVector3Array()
var _tri := PackedInt32Array()
var _still := 0.0
var _prev := PackedVector3Array()
var _edges := PackedInt32Array()   # pairs
var _edge_rest := 0.0


## Made from `points` (world: this node sits at the origin unturned) and `triangles`.
static func make(points: PackedVector3Array, triangles: PackedInt32Array, uv: PackedVector2Array,
		material: Material, mass := 0.035, precision := 12) -> GarmentCloth:
	var c := GarmentCloth.new()
	c.kit_id = &"garment"
	c._start = points
	c._tri = triangles
	c.look = material
	c.definition = {"size": [0.6, 0.1], "points": [points.size(), 1], "mass": mass, "grip_radius": 0.03,
			"stiffness": 1.0, "precision": precision, "damping": 0.06,
			"catch_seconds": 2.0, "burn_seconds": 30.0, "holds_ml": 60.0, "soaks": 0.5,
			"mesh": {"vertices": points, "indices": triangles, "uvs": uv}}
	return c


func _build() -> void:
	super._build()
	soft.name = "Garment"
	# The world and his skin (SkinCollider), not his hitboxes: they're a hand's breadth off his skin.
	soft.collision_mask = Layers.WORLD | SkinCollider.LAYER


func _material() -> StandardMaterial3D:
	# (ClothProp paints blood and char on its image; a garment's is a plain one for that.)
	_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0.05, 0.04, 0.04))
	_tex = ImageTexture.create_from_image(_image)
	if look is StandardMaterial3D:
		return look
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.04, 0.04)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func point_count() -> int:
	return _start.size()


## Pinned to `to` where they are (no jump): the fingertips to the hand that takes them.
func pin_to(points: Array[int], to: Node3D, by: HumanBody, hand_side: String) -> void:
	_release_all()
	# (Not ClothProp._pin: the soft body has no points to read until its first step; it was made
	# with them at the start, so they're pinned there.)
	var inv := to.global_transform.affine_inverse()
	for i in points:
		soft.set_point_pinned(i, true)
		_pins.append([i, to, inv * _start[i]])
	_take_holder(by)
	held = Held.HAND
	side = hand_side


## Held where they are as worn (friction, until a pull reaches them): each pinned to its carrier.
func hold_on(points: Array[int], carrier_of: Callable) -> void:
	for i in points:
		var to: Node3D = carrier_of.call(i)
		soft.set_point_pinned(i, true)
		_pins.append([i, to, to.global_transform.affine_inverse() * _start[i]])


## These let go (the pull has reached them): free cloth from now on.
func release(points: Dictionary) -> void:
	var keep: Array = []
	for p: Array in _pins:
		if points.has(int(p[0])):
			soft.set_point_pinned(int(p[0]), false)
		else:
			keep.append(p)
	_pins = keep


## Its points now (world).
func points_now() -> PackedVector3Array:
	if resting:
		return (baked.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var out := PackedVector3Array()
	out.resize(_start.size())
	for i in _start.size():
		out[i] = soft.get_point_transform(i)
	return out


## Its points as made (world, at the take).
func start_points() -> PackedVector3Array:
	return _start


func triangles() -> PackedInt32Array:
	return _tri


## How much longer its edges are now than as worn, on the whole (1.0 = not stretched).
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


func _physics_step(delta: float) -> void:
	if resting:
		return
	super._physics_step(delta)
	if burnt or held != Held.FREE:
		_still = 0.0
		_prev = PackedVector3Array()
		_sample_t = 0.0
		return
	# Its points compared a quarter second apart (not tick to tick: a few points on a floor shiver a
	# mm or two for ever, which is cm/s a tick but nothing over a quarter second).
	_sample_t += delta
	if _sample_t < SAMPLE:
		return
	var dt := _sample_t
	_sample_t = 0.0
	var now := points_now()
	if _prev.size() == now.size():
		var mean := 0.0
		for i in now.size():
			mean += now[i].distance_to(_prev[i])
		mean /= now.size() * dt
		_still = _still + dt if mean < rest_speed else 0.0
		last_mean_speed = mean
	_prev = now
	if _still >= rest_after - 0.001:
		_to_rest(now)


const SAMPLE := 0.25
var _sample_t := 0.0


## The soft body out, its shape left as a plain mesh where it lies.
func _to_rest(now: PackedVector3Array) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = now
	arrays[Mesh.ARRAY_TEX_UV] = _uv
	arrays[Mesh.ARRAY_INDEX] = _tri
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	baked = MeshInstance3D.new()
	baked.name = "GarmentAtRest"
	baked.mesh = st.commit()
	baked.material_override = soft.material_override
	baked.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(baked)
	soft.queue_free()  # out of the physics: its shape is the baked mesh now
	soft = null
	resting = true
	set_physics_process(false)
	came_to_rest.emit()


func centre() -> Vector3:
	if not resting:
		return super.centre()
	var sum := Vector3.ZERO
	var now := points_now()
	for p in now:
		sum += p
	return sum / maxf(now.size(), 1)


# (At rest there's no soft body for a ball, a blast or water to move: it lies where it is.)
func _on_bullet_hit(info: Dictionary) -> void:
	if not resting:
		super._on_bullet_hit(info)


func _on_exploded(at: Vector3, kg: float) -> void:
	if not resting:
		super._on_exploded(at, kg)


func _on_doused(at: Vector3, litres: float, put_out: int) -> void:
	if not resting:
		super._on_doused(at, litres, put_out)
