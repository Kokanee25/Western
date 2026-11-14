extends ClothProp
## The glove as real cloth (#895; lab only): the game's ClothProp (its pins carried by the prop,
## held, let go, knocked, burnt, bloodied) with the glove's own points and triangles instead of the
## rag's flat grid. Made at the moment of the handoff with every point where the worn glove is drawn
## that tick, so the swap doesn't show. Its rest shape is the glove as worn (that's the length of
## every edge it keeps). It meets the world (floor, chair) and the arm's fitted shapes
## (arm_colliders.gd), nothing else of him.
##
## At rest (`rest_after` s with its points slower than `rest_speed` on the whole) the soft body is taken out and
## its shape left as a plain mesh: a glove on the floor costs nothing (`resting`). (Picking it up
## again would make a new soft body from that shape: not built here.)

signal came_to_rest

const ArmColliders := preload("res://experiments/garment_handoff/arm_colliders.gd")

var start := PackedVector3Array()
var tri := PackedInt32Array()
var tex_uv := PackedVector2Array()
var look: Material
var stiffness := 1.0
var precision := 12
var damping := 0.06
var mass := 0.035
var rest_speed := 0.01
var rest_after := 0.75
var resting := false
var baked: MeshInstance3D
var _still := 0.0
var last_fastest := 0.0
var _prev := PackedVector3Array()


func _init() -> void:
	kit_id = &"glove"


func setup(points: PackedVector3Array, triangles: PackedInt32Array, uv: PackedVector2Array, material: Material) -> void:
	start = points
	tri = triangles
	tex_uv = uv
	look = material
	definition = {"size": [0.6, 0.1], "points": [points.size(), 1], "mass": mass, "grip_radius": 0.03,
			"catch_seconds": 2.0, "burn_seconds": 30.0, "holds_ml": 60.0, "soaks": 0.5}


func _build() -> void:
	soft = SoftBody3D.new()
	soft.name = "Glove"
	soft.mesh = _grid_mesh()
	soft.total_mass = mass
	soft.linear_stiffness = stiffness
	soft.damping_coefficient = damping
	soft.simulation_precision = precision
	soft.collision_layer = 0
	soft.collision_mask = Layers.WORLD | (0 if OS.has_environment("GH_NO_ARM") else ArmColliders.LAYER)
	soft.ray_pickable = false
	soft.material_override = look
	soft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(soft)


## Its own points and triangles, where the worn glove is drawn now (world; this node sits at the
## origin unturned).
func _grid_mesh() -> ArrayMesh:
	_rest = start.duplicate()
	_uv = tex_uv
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = start
	# (Normals too: the soft body writes position and normal into the drawn mesh's buffer by the
	# layout of one with both; without them it's drawn scrambled, a bar a metre long.)
	arrays[Mesh.ARRAY_NORMAL] = normals_of(start, tri)
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = tri
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


static func normals_of(pts: PackedVector3Array, tris: PackedInt32Array) -> PackedVector3Array:
	var acc := PackedVector3Array()
	acc.resize(pts.size())
	for t in range(0, tris.size(), 3):
		var n := (pts[tris[t + 1]] - pts[tris[t]]).cross(pts[tris[t + 2]] - pts[tris[t]])
		for k in 3:
			acc[tris[t + k]] += n
	for i in acc.size():
		acc[i] = acc[i].normalized() if acc[i].length_squared() > 0.0 else Vector3.UP
	return acc


func _material() -> StandardMaterial3D:
	# (ClothProp paints blood and char on its image; the glove's is a plain one for that.)
	_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0.05, 0.04, 0.04))
	_tex = ImageTexture.create_from_image(_image)
	return look as StandardMaterial3D


## Pinned to `to` where they are (no jump): the fingertips to the hand that takes them.
func pin_to(points: Array[int], to: Node3D, by: HumanBody, hand_side: String) -> void:
	_release_all()
	# (Not ClothProp._pin: the soft body has no points to read until its first step; it was made
	# with them at `start`, so they're pinned where they're drawn.)
	var inv := to.global_transform.affine_inverse()
	for i in points:
		soft.set_point_pinned(i, true)
		_pins.append([i, to, inv * start[i]])
	_take_holder(by)
	held = Held.HAND
	side = hand_side


## Held on his arm as worn (friction, until the pull reaches them): each point pinned to its own
## bone's carrier where it's drawn.
func hold_on(points: Array[int], carrier_of: Callable) -> void:
	for i in points:
		var to: Node3D = carrier_of.call(i)
		soft.set_point_pinned(i, true)
		_pins.append([i, to, to.global_transform.affine_inverse() * start[i]])


## These let go of the arm (the pull has reached them): free cloth from now on.
func release(points: Dictionary) -> void:
	var keep: Array = []
	for p: Array in _pins:
		if points.has(int(p[0])):
			soft.set_point_pinned(int(p[0]), false)
		else:
			keep.append(p)
	_pins = keep


## How much longer its edges are now than as worn, on the whole (1.0 = not stretched).
func stretch() -> float:
	if _edges.is_empty():
		var seen := {}
		for t in range(0, tri.size(), 3):
			for k in 3:
				var a := tri[t + k]
				var b := tri[t + (k + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not seen.has(key):
					seen[key] = true
					_edges.append(key)
					_edge_rest += start[a].distance_to(start[b])
	var now := points_now()
	var total := 0.0
	for e: Vector2i in _edges:
		total += now[e.x].distance_to(now[e.y])
	return total / maxf(_edge_rest, 1e-6)


var _edges: Array[Vector2i] = []
var _edge_rest := 0.0


func points_now() -> PackedVector3Array:
	var out := PackedVector3Array()
	if resting:
		var a := (baked.mesh as ArrayMesh).surface_get_arrays(0)
		return a[Mesh.ARRAY_VERTEX]
	out.resize(point_count())
	for i in point_count():
		out[i] = soft.get_point_transform(i)
	return out


func _physics_step(delta: float) -> void:
	if resting:
		return
	super._physics_step(delta)
	if held != Held.FREE:
		_still = 0.0
		return
	var now := points_now()
	if _prev.size() == now.size():
		# Its points' mean speed (a point or two on the floor shiver a few cm/s for ever).
		var mean := 0.0
		for i in now.size():
			mean += now[i].distance_to(_prev[i]) / delta
		mean /= now.size()
		_still = _still + delta if mean < rest_speed else 0.0
		last_fastest = mean
	_prev = now
	if _still >= rest_after:
		_to_rest(now)


## The soft body out, its shape left as a plain mesh where it lies.
func _to_rest(now: PackedVector3Array) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = now
	arrays[Mesh.ARRAY_TEX_UV] = tex_uv
	arrays[Mesh.ARRAY_INDEX] = tri
	var st := SurfaceTool.new()
	st.create_from_arrays(arrays)
	st.generate_normals()
	baked = MeshInstance3D.new()
	baked.name = "GloveAtRest"
	baked.mesh = st.commit()
	baked.material_override = look
	add_child(baked)
	soft.queue_free()  # out of the physics: its shape is the baked mesh now
	resting = true
	set_physics_process(false)
	came_to_rest.emit()
