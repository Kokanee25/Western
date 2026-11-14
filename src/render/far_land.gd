class_name FarLand
extends Node3D
## The valley's far land (#918, under the real look; RealSky adds it to the valley): what the
## camera's 800 m far plane cuts off. One ring mesh round the valley's middle out to RING_OUT m: the
## bake's own ground out to its edge (the foothills, the canyon's far rims), then the country beyond
## from valley.json's `envelope.scenery`: the La Plata front to the west and north-west (timbered,
## snow above ~3,700 m: the valley sits at ~2,070 m), the low sunset notch due west down Main
## Street, the San Juan peaks far to the north and north-east, mesa country falling away south,
## broken uplands east; heights drop with the Earth's curve (refraction's 7/6 radius).
## Drawn by src/render/far_land.gdshader in the transparent pass, only over the sky (where nothing
## nearer has drawn: the depth test against the cleared depth), writing no depth: its triangles go
## outer ring first, so a nearer ridge paints over a farther one. (Pushing it behind the far plane in
## depth failed: Godot keeps a 24-bit depth where the card allows, one step there. A 45 km far plane
## drew the whole valley from the trestle: 3,330 draws, 22.7 M primitives.)
## Its sorting puts it after LightFinish's quad and the clouds and before every other transparent
## thing (RealSky.SORT_*). Bearings are compass (valley.json: 0 north, -Z; 90 east, +X).
## `enabled = false` (or `-- --no-far-land`): the before.

const SHADER := "res://src/render/far_land.gdshader"
const RING_IN := 1700.0
## The bake's own ground: a grid every BAKE_STEP m, its quads drawn back to front from the camera
## (exact for a height field, by their distance on the ground), sorted again whenever the camera has
## moved RESORT m.
const BAKE_STEP := 32.0
const RESORT := 150.0
const RING_OUT := 45000.0
const RINGS := 110
const SEGMENTS := 720
const EARTH := 6371000.0 * 7.0 / 6.0
## The valley's height above the sea (valley.json units.y): the snow line and the ranges are
## absolute heights less this.
const ALTITUDE := 2070.0
const SNOW_LINE := 3650.0

static var enabled := not "--no-far-land" in OS.get_cmdline_user_args()
static var _ring_mesh: ArrayMesh
static var _material: ShaderMaterial
static var _bake_arrays: Array

var ring_instance: MeshInstance3D
var bake_instance: MeshInstance3D
var _bake_mesh: ArrayMesh
var _bake_nx := 0
var _bake_nz := 0
var _sorted_at := Vector3(INF, 0, INF)
var _ridges: FastNoiseLite
var _hills: FastNoiseLite
var _mesas: FastNoiseLite


func _ready() -> void:
	name = "FarLand"
	add_to_group(&"far_land")
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load(SHADER)
	var terrain := ValleyTerrain.main()
	if _ring_mesh == null:
		_ring_mesh = ring_mesh(terrain)
	ring_instance = _instance(_ring_mesh, "Ranges", RealSky.SORT_FAR_LAND)

	if terrain.is_loaded():
		if _bake_arrays.is_empty():
			_bake_arrays = bake_arrays(terrain)
		_bake_mesh = ArrayMesh.new()
		var r := terrain.rect()
		_bake_nx = int(r.size.x / BAKE_STEP) + 1
		_bake_nz = int(r.size.y / BAKE_STEP) + 1
		# (after the ranges: nearer)
		bake_instance = _instance(_bake_mesh, "Bake", RealSky.SORT_FAR_LAND - 1.0)


func _process(_delta: float) -> void:
	# On the camera, so it sorts as at RealSky.SORT_FAR_LAND whichever way the camera looks (the
	# shader draws the mesh where it is in the world, leaving this node's place out).
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for mi: MeshInstance3D in [ring_instance, bake_instance]:
		if mi:
			mi.global_position = cam.global_position
	var at := cam.global_position
	if bake_instance and Vector2(at.x - _sorted_at.x, at.z - _sorted_at.z).length() > RESORT:
		_sorted_at = at
		_sort_bake(at)


## The bake's quads in the order back to front from `at` (bucketed by ground distance, 16 m a
## bucket), as the bake mesh's index.
func _sort_bake(at: Vector3) -> void:
	var t := Time.get_ticks_usec()
	var verts: PackedVector3Array = _bake_arrays[Mesh.ARRAY_VERTEX]
	var nx := _bake_nx
	var nq := (nx - 1) * (_bake_nz - 1)
	var bucket := PackedInt32Array()
	bucket.resize(nq)
	var top := 0
	for q in nq:
		var i := q % (nx - 1)
		var j := q / (nx - 1)
		var v := verts[j * nx + i]
		var b := int(Vector2(v.x + BAKE_STEP * 0.5 - at.x, v.z + BAKE_STEP * 0.5 - at.z).length() / 16.0)
		bucket[q] = b
		top = maxi(top, b)
	var counts := PackedInt32Array()
	counts.resize(top + 2)
	for q in nq:
		counts[top - bucket[q] + 1] += 1
	for k in range(1, counts.size()):
		counts[k] += counts[k - 1]
	var order := PackedInt32Array()
	order.resize(nq)
	for q in nq:
		var k := top - bucket[q]
		order[counts[k]] = q
		counts[k] += 1
	var idx := PackedInt32Array()
	idx.resize(nq * 6)
	var w := 0
	for q in order:
		var a := (q / (nx - 1)) * nx + q % (nx - 1)
		idx[w] = a; idx[w + 1] = a + 1; idx[w + 2] = a + nx
		idx[w + 3] = a + 1; idx[w + 4] = a + nx + 1; idx[w + 5] = a + nx
		w += 6
	var arrays := _bake_arrays.duplicate()
	arrays[Mesh.ARRAY_INDEX] = idx
	_bake_mesh.clear_surfaces()
	_bake_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	sort_ms = (Time.get_ticks_usec() - t) / 1000.0


## The air between the eye and the far land (RealSky, as the sky changes): the sky's radiance low
## round the horizon (linear, as the sky shader draws it), what it scatters in.
## `thick`: the air's haze (1.6 clear; more under cloud, where far land greys out).
static func set_haze(horizon: Vector3, thick := 1.6) -> void:
	if _material:
		_material.set_shader_parameter(&"haze_color", horizon)
		_material.set_shader_parameter(&"haze", thick)



## The light on the far land (RealSky, each frame): toward the sun or moon, its colour times its
## energy (linear), the sky's light from overhead and from round the horizon.
static func set_light(dir: Vector3, colour: Vector3, sky_up: Vector3, sky_side: Vector3) -> void:
	if _material:
		_material.set_shader_parameter(&"light_dir", dir)
		_material.set_shader_parameter(&"light_color", colour)
		_material.set_shader_parameter(&"sky_up", sky_up)
		_material.set_shader_parameter(&"sky_side", sky_side)


## How long the last sort of the bake took (ms).
var sort_ms := 0.0


## The bake every BAKE_STEP metres (no index: `_sort_bake` makes it), in the greybox ground's colours.
static func bake_arrays(t: ValleyTerrain) -> Array:
	var r := t.rect()
	var nx := int(r.size.x / BAKE_STEP) + 1
	var nz := int(r.size.y / BAKE_STEP) + 1
	var tune := load("res://config/valley_terrain.tres") as ValleyGroundTuning
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	verts.resize(nx * nz)
	norms.resize(nx * nz)
	cols.resize(nx * nz)
	var step := int(BAKE_STEP / t.spacing)
	for j in nz:
		for i in nx:
			var x := r.position.x + i * BAKE_STEP
			var z := r.position.y + j * BAKE_STEP
			var y := t.height(x, z)
			var g := t.gradient(i * step, j * step, step)
			var n := Vector3(-g.x, 1.0, -g.y).normalized()
			var k := j * nx + i
			verts[k] = Vector3(x, y, z)
			norms[k] = n
			var c := Color(0.6, 0.5, 0.4)
			if tune:
				c = tune.dirt.lerp(tune.rock, smoothstep(tune.rock_from, tune.rock_full, rad_to_deg(acos(clampf(n.y, -1.0, 1.0)))))
				if y < tune.bottom_below:
					c = c.lerp(tune.bottom, 0.6)
			cols[k] = c
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	return arrays


func _instance(mesh: Mesh, n: String, sort: float) -> MeshInstance3D:
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.material_override = _material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mi.sorting_use_aabb_center = false
	mi.sorting_offset = -sort
	mi.custom_aabb = RealSky.HUGE
	mi.top_level = true
	add_child(mi)
	return mi


## The ranges: a polar grid round the bake's middle, rings spaced by a constant ratio.
func ring_mesh(t: ValleyTerrain) -> ArrayMesh:
	_noises()
	var r := t.rect() if t.is_loaded() else Rect2(-2000, -1400, 4480, 3712)
	var centre := r.get_center()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var nx := SEGMENTS + 1
	var nz := RINGS + 1
	verts.resize(nx * nz)
	norms.resize(nx * nz)
	cols.resize(nx * nz)
	var heights := PackedFloat32Array()
	heights.resize(nx * nz)
	for j in nz:
		var rad := RING_IN * pow(RING_OUT / RING_IN, float(j) / RINGS)
		for i in nx:
			var b := 360.0 * i / SEGMENTS
			var p := centre + Vector2(sin(deg_to_rad(b)), -cos(deg_to_rad(b))) * rad
			var y := land_height(t, p.x, p.y)
			heights[j * nx + i] = y
			var d := p.length()
			verts[j * nx + i] = Vector3(p.x, y - d * d / (2.0 * EARTH), p.y)
	# Normals from the grid's own neighbours (round the ring and across the rings).
	for j in nz:
		for i in nx:
			var k := j * nx + i
			var il := posmod(i - 1, SEGMENTS)
			var ir := posmod(i + 1, SEGMENTS)
			var across := verts[j * nx + ir] - verts[j * nx + il]
			var out := verts[mini(j + 1, nz - 1) * nx + i] - verts[maxi(j - 1, 0) * nx + i]
			var n := out.cross(across).normalized()
			if n.y < 0.0:
				n = -n
			norms[k] = n
			var y := heights[k]
			var p := Vector2(verts[k].x, verts[k].z)
			var yn := y + (n.y - 0.8) * 300.0 + _mesas.get_noise_2d(p.x * 3.0, p.y * 3.0) * 220.0
			var snow := smoothstep(SNOW_LINE - ALTITUDE - 120.0, SNOW_LINE - ALTITUDE + 150.0, yn)
			var c := _range_colour(p, y, n.y).lerp(Color(0.92, 0.93, 0.96), snow)
			cols[k] = c
	return _grid(verts, norms, cols, nx, nz)


func _noises() -> void:
	_ridges = FastNoiseLite.new()
	_ridges.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridges.fractal_octaves = 4
	_ridges.frequency = 1.0 / 7000.0
	_ridges.seed = 1918
	_hills = FastNoiseLite.new()
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hills.fractal_octaves = 4
	_hills.frequency = 1.0 / 5000.0
	_hills.seed = 2918
	_mesas = FastNoiseLite.new()
	_mesas.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_mesas.fractal_type = FastNoiseLite.FRACTAL_FBM
	_mesas.fractal_octaves = 3
	_mesas.frequency = 1.0 / 4000.0
	_mesas.seed = 3918


## A soft window over compass bearings a..b (wrapping), `soft` degrees each side.
static func bearing_window(b: float, a: float, c: float, soft: float) -> float:
	var mid := fposmod(a + fposmod(c - a, 360.0) * 0.5, 360.0)
	var half := fposmod(c - a, 360.0) * 0.5
	var off := absf(fposmod(b - mid + 180.0, 360.0) - 180.0)
	return 1.0 - smoothstep(half, half + soft, off)


## The land's height (m above the town's ground) at x, z: the bake inside it, the ranges beyond.
func land_height(t: ValleyTerrain, x: float, z: float) -> float:
	var inside := 0.0
	var edge_h := 0.0
	var out_by := 0.0
	if t.is_loaded():
		var r := t.rect()
		edge_h = t.height(x, z)  # clamped at the bake's edge
		var cx := clampf(x, r.position.x, r.end.x)
		var cz := clampf(z, r.position.y, r.end.y)
		out_by = Vector2(x - cx, z - cz).length()
		if out_by <= 0.0:
			return edge_h - 30.0  # under the bake's own mesh, which is drawn after
	var d := Vector2(x, z).length()
	var b := fposmod(rad_to_deg(atan2(x, -z)), 360.0)
	var lift := smoothstep(0.0, 2500.0, out_by)
	# Broken country everywhere, rising a little with distance.
	var h := (_hills.get_noise_2d(x, z) * 0.5 + 0.5) * (60.0 + 140.0 * smoothstep(2000.0, 12000.0, d))
	# The La Plata front: foothills from the bake's west edge, the range 18-30 km out.
	var west := bearing_window(b, 268.0, 340.0, 14.0)
	var notch := 1.0 - 0.7 * bearing_window(b, 266.0, 274.0, 4.0)
	var foot := smoothstep(0.0, 9000.0, out_by) * 520.0
	var ridge := _ridges.get_noise_2d(x * 1.1, z * 1.1) * 0.5 + 0.5
	var range_r := smoothstep(9000.0, 21000.0, d) * (1.0 - smoothstep(32000.0, 40000.0, d))
	h += west * notch * (foot + range_r * (550.0 + 1250.0 * ridge * ridge))
	# The San Juans, far north and north-east.
	var north := bearing_window(b, 335.0, 60.0, 18.0)
	var far_r := smoothstep(22000.0, 32000.0, d)
	var rn := _ridges.get_noise_2d(x * 0.8 + 9000.0, z * 0.8) * 0.5 + 0.5
	h += north * far_r * (450.0 + 1350.0 * rn * rn)
	# Mesa country to the south: flat tops and cliffs (the noise stepped).
	var south := bearing_window(b, 140.0, 235.0, 20.0)
	var m := _mesas.get_noise_2d(x, z) * 0.5 + 0.5
	var tops := smoothstep(0.52, 0.56, m) * 140.0 + smoothstep(0.66, 0.69, m) * 110.0
	h += south * smoothstep(1500.0, 6000.0, out_by) * tops
	# Uplands east, past the gorge.
	var east := bearing_window(b, 60.0, 140.0, 20.0)
	h += east * smoothstep(1500.0, 10000.0, out_by) * (120.0 + 260.0 * ridge)
	return lerpf(edge_h, edge_h * (1.0 - smoothstep(0.0, 8000.0, out_by)) + h, lift)


## Ground cover by height and slope: desert tan low, pinon and juniper's dark olive on the slopes
## and benches, spruce dark blue-green high, grey rock where it's steep and over the tree line.
func _range_colour(p: Vector2, y: float, up: float) -> Color:
	var mottle := _hills.get_noise_2d(p.x * 1.5, p.y * 1.5) * 0.5 + 0.5
	# The bands by height broken up (a ragged tree line, snow down the gullies), so they don't
	# read as stripes across the range.
	var yn := y + (_mesas.get_noise_2d(p.x * 2.0, p.y * 2.0)) * 260.0
	var d := p.length()
	var tan := Color(0.55, 0.47, 0.37)
	var pinon := Color(0.27, 0.29, 0.20)
	var spruce := Color(0.15, 0.20, 0.16)
	var rock := Color(0.46, 0.44, 0.42)
	# Out past the valley the plain is pinon and juniper country, not bare: darker the further.
	var cover := clampf(smoothstep(80.0, 420.0, yn) + smoothstep(3000.0, 12000.0, d) * 0.55, 0.0, 1.0)
	var c := tan.lerp(pinon, cover * (0.5 + 0.5 * mottle))
	c = c.lerp(spruce, smoothstep(650.0, 1050.0, yn) * (1.0 - smoothstep(1400.0, 1650.0, yn)))
	c = c.lerp(rock, maxf((1.0 - smoothstep(0.7, 0.86, up)) * 0.8, smoothstep(1400.0, 1650.0, yn)))
	return c


## A grid of nx x nz points (row-major) as one indexed triangle mesh, its last rows' triangles first
## (the painter's order: the far rings drawn before the near).
static func _grid(verts: PackedVector3Array, norms: PackedVector3Array, cols: PackedColorArray,
		nx: int, nz: int) -> ArrayMesh:
	var idx := PackedInt32Array()
	idx.resize((nx - 1) * (nz - 1) * 6)
	var w := 0
	for jj in nz - 1:
		var j := nz - 2 - jj
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var c := a + nx
			var d := c + 1
			idx[w] = a; idx[w + 1] = b; idx[w + 2] = c
			idx[w + 3] = b; idx[w + 4] = d; idx[w + 5] = c
			w += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
