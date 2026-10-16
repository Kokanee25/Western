class_name RoadStones
extends Node3D
## Loose stones on the street, as Sean's road has them (docs/concept/targets/6_road_target.jpg,
## roadmap 1.4, 2026-10-15: "yes, 3D stones"): gravel to fist-sized rocks lying on the dirt in
## clumps, each standing up off it so the low sun lights its top and it throws its own shadow,
## which the painted road's relief alone can't do. One lumpy rock mesh, scaled, squashed and turned
## per stone, all of them one MultiMesh (one draw call, and its shadow). Deterministic from the
## seed. None under a floor, a boardwalk or a step; no collision (they're too small to stop a boot).

## The road (StreetScenery's): centre line z and half width.
const ROAD_Z := -8.4
const ROAD_HALF := 6.0
## How many stones to try placing, and the stretch of street (x0, x1).
const TRIES := 22000
const STREET_X := Vector2(-80.0, 30.0)
## Sizes (metres across) and how often: gravel, stones, the odd fist-sized rock.
const SIZES := [[0.035, 0.07, 0.5], [0.07, 0.13, 0.38], [0.13, 0.22, 0.12]]

@export var stone_seed := 1882

## The street's map (tools/textures/draw_street.py): its A says how likely a stone is (churned
## ground and the ruts' lips, none in a groove), its G the ruts' height a stone sits on.
const MAP := "res://assets/textures/street/street_map.png"
const MAP_INFO := "res://assets/textures/street/street_map.json"
var _map: Image
var _area := Vector4.ZERO
var _rut_range := 0.12

## Where each stone lies (the multimesh's transforms; kept here too, as a headless renderer
## doesn't keep them).
var stones: Array[Transform3D] = []


func _ready() -> void:
	# Placed on the first physics frame: the buildings' floors and boardwalks must be in the
	# physics space to keep stones from under them.
	await get_tree().physics_frame
	_scatter()


func _scatter() -> void:
	if ResourceLoader.exists(MAP) and FileAccess.file_exists(MAP_INFO):
		_map = (load(MAP) as Texture2D).get_image()
		if _map.is_compressed():
			_map.decompress()
		var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_INFO))
		if info is Dictionary:
			var a: Array = (info as Dictionary).get("area", [])
			_area = Vector4(a[0], a[1], a[2], a[3])
			_rut_range = float((info as Dictionary).get("rut_range", 0.12))
	var rng := RandomNumberGenerator.new()
	rng.seed = stone_seed
	var space := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = Layers.WORLD
	var noise := FastNoiseLite.new()
	noise.seed = stone_seed
	noise.frequency = 0.35
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in TRIES:
		var p := Vector3(rng.randf_range(STREET_X.x, STREET_X.y), 0.0,
				ROAD_Z + rng.randf_range(-ROAD_HALF - 0.5, ROAD_HALF + 0.5))
		if rng.randf() > _density(p, noise):
			continue
		ray.from = p + Vector3.UP * 6.0
		ray.to = p + Vector3.UP * 0.03
		if not space.intersect_ray(ray).is_empty():
			continue
		var size := _size(rng)
		# Flatter than round, a little longer one way, turned any way, sunk a third into the dirt.
		var basis := Basis(Vector3.UP, rng.randf() * TAU) \
				* Basis(Vector3(rng.randf() - 0.5, 0.0, rng.randf() - 0.5).normalized() if rng.randf() < 0.5 else Vector3.RIGHT,
						rng.randf_range(-0.3, 0.3))
		var tall := size * rng.randf_range(0.45, 0.7)
		basis = basis.scaled(Vector3(size * rng.randf_range(0.9, 1.3), tall, size))
		# The rock is a unit across: its centre a sixth of its height above the dirt (the ruts'
		# height there, on the map).
		p.y = tall / 6.0 + _rut_height(p)
		transforms.append(Transform3D(basis, p))
		# Tan-grey, rust, pale and dark stones, as the target's, near the dirt's own value (paler,
		# they read as white blobs in the noon sun).
		var shades := [Color(0.66, 0.55, 0.43), Color(0.64, 0.46, 0.32), Color(0.72, 0.62, 0.5), Color(0.52, 0.41, 0.31)]
		colours.append((shades[rng.randi() % shades.size()] as Color).lerp(Color(0.66, 0.52, 0.38), rng.randf() * 0.4))
	stones = transforms
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = rock_mesh()
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colours[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Stones"
	mmi.multimesh = mm
	# No visibility range: it's measured to the middle of the whole street's box, so from one end
	# every stone went at once.
	add_child(mmi)


## The map's pixel under `p` (null off the map).
func _sample(p: Vector3) -> Variant:
	if _map == null:
		return null
	var u := (p.x - _area.x) / (_area.z - _area.x)
	var v := (p.z - _area.y) / (_area.w - _area.y)
	if u < 0.0 or u >= 1.0 or v < 0.0 or v >= 1.0:
		return null
	return _map.get_pixel(int(u * _map.get_width()), int(v * _map.get_height()))


func _rut_height(p: Vector3) -> float:
	var c: Variant = _sample(p)
	return ((c as Color).g - 0.5) * 2.0 * _rut_range if c != null else 0.0


## How likely a stone is at `p` (0..1): the map's say where there is one (churned ground and the
## ruts' lips), in clumps; else thicker toward the road's edges, thinning out off it.
func _density(p: Vector3, noise: FastNoiseLite) -> float:
	var c: Variant = _sample(p)
	if c != null:
		var clump_m := clampf(noise.get_noise_2d(p.x, p.z) * 0.9 + 0.5, 0.0, 1.0)
		return (c as Color).a * smoothstep(0.15, 0.7, clump_m)
	var dz := absf(p.z - ROAD_Z)
	var clump := clampf(noise.get_noise_2d(p.x, p.z) * 0.9 + 0.5, 0.0, 1.0)
	var edge := lerpf(0.6, 1.0, smoothstep(1.0, ROAD_HALF - 0.5, dz)) * (1.0 - smoothstep(ROAD_HALF - 0.3, ROAD_HALF + 0.5, dz))
	return edge * smoothstep(0.2, 0.75, clump)


func _size(rng: RandomNumberGenerator) -> float:
	var r := rng.randf()
	for s: Array in SIZES:
		r -= float(s[2])
		if r <= 0.0:
			return rng.randf_range(s[0], s[1])
	return SIZES[0][0]


## A lumpy rock about a unit across: an icosphere split once, pushed out and in by broad lumps,
## its bottom flat, faceted.
func rock_mesh() -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = []
	for v in [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]:
		verts.append((v as Vector3).normalized())
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
			[11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
			[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var mid := {}
	var split: Array = []
	for f: Array in faces:
		var m := []
		for k in 3:
			var a: int = f[k]
			var b: int = f[(k + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			if not mid.has(key):
				verts.append(((verts[a] + verts[b]) * 0.5).normalized())
				mid[key] = verts.size() - 1
			m.append(mid[key])
		split.append_array([[f[0], m[0], m[2]], [f[1], m[1], m[0]], [f[2], m[2], m[1]], [m[0], m[1], m[2]]])
	# Lumpy, not an egg: each corner pushed out or in by a few broad lumps and a little of its own,
	# the bottom sliced flat where it sits in the dirt.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var lumps: Array[Vector3] = []
	for k in 5:
		lumps.append(Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized())
	for i in verts.size():
		var v := verts[i]
		var r := 1.0 + rng.randf_range(-0.08, 0.08)
		for k in lumps.size():
			r += 0.22 * (v.dot(lumps[k]) ** 3) * (1.0 if k % 2 == 0 else -0.7)
		v = v * r * 0.5
		v.y = maxf(v.y, -0.22)
		verts[i] = v
	# Faceted: each face its own normal, so the low sun picks out its planes as the target's
	# stones' do (smooth-shaded they read as eggs).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for f: Array in split:
		for k in [0, 2, 1]:
			st.add_vertex(verts[f[k]])
	st.generate_normals()
	var mesh := st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.95
	m.metallic_specular = 0.2
	mesh.surface_set_material(0, m)
	return mesh
