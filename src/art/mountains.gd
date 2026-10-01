class_name Mountains
extends Node3D
## The red-rock country round Salt Creek, as in docs/concept/street-golden-hour.png: mesas, buttes
## and clusters of spires a few hundred metres out, their cliffs banded in reds and buff, lit by
## the low sun and softened by distance. Built in code from stacked rings (talus, cliff, cap rock),
## deterministic from the seed. On the texel grid at a coarse size (a texel ~1.7 m, so they read as
## chunky blocks like the painting's), with their own haze (mountain.gdshader) that follows the
## scene's fog colour.

const SHADER := preload("res://src/art/mountain.gdshader")
## Texels per metre on the rock (the near world is 64).
const TEXELS_PER_METRE := 0.6
## The haze on them: how fast it thickens past 60 m, how far it goes, and how dark its colour is
## beside the scene's fog colour (the painting's distant shadows go violet, not white).
const HAZE_DENSITY := 0.0016
const HAZE_MAX := 0.62
const HAZE_SHADE := Color(0.62, 0.58, 0.68)

## The formations: [kind, position on the ground (x, z), radius, height, seed]. The biggest stand
## west, down the street toward the sunset as the painting has them, either side of the sun.
const FORMATIONS := [
	[&"cluster", Vector2(-650.0, 20.0), 80.0, 210.0, 1],
	[&"cluster", Vector2(-610.0, -200.0), 65.0, 165.0, 2],
	[&"ridge", Vector2(-740.0, -80.0), 150.0, 38.0, 3],
	[&"butte", Vector2(-600.0, 160.0), 50.0, 120.0, 12],
	[&"spire", Vector2(-560.0, -115.0), 15.0, 115.0, 4],
	[&"mesa", Vector2(-560.0, 300.0), 80.0, 70.0, 5],
	[&"butte", Vector2(-480.0, -330.0), 45.0, 105.0, 6],
	# Round the rest of the town, lower and further.
	[&"mesa", Vector2(60.0, 600.0), 140.0, 80.0, 7],
	[&"cluster", Vector2(-180.0, -620.0), 70.0, 130.0, 8],
	[&"butte", Vector2(450.0, -450.0), 55.0, 100.0, 9],
	[&"mesa", Vector2(620.0, 120.0), 120.0, 75.0, 10],
	[&"spire", Vector2(420.0, 420.0), 20.0, 110.0, 11],
]

var _material: ShaderMaterial
var _env: Environment


func _ready() -> void:
	_material = material()
	for f in FORMATIONS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7000 + int(f[4])
		var at := Vector3((f[1] as Vector2).x, 0.0, (f[1] as Vector2).y)
		match f[0]:
			&"mesa": _rock(at, _mesa(f[2], f[3]), rng)
			&"ridge": _rock(at, _ridge(f[2], f[3]), rng)
			&"butte": _rock(at, _butte(f[2], f[3]), rng)
			&"spire": _rock(at, _spire(f[2], f[3]), rng)
			&"cluster": _cluster(at, f[2], f[3], rng)
	var we := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	_env = we.environment if we else null


func _process(_delta: float) -> void:
	# The haze takes the scene's fog colour (DayCycle sets it from the sky each frame).
	if _env:
		_material.set_shader_parameter(&"haze_color", _env.fog_light_color * HAZE_SHADE)


static func material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"albedo_tex", strata())
	m.set_shader_parameter(&"tint", Color.WHITE)
	m.set_shader_parameter(&"texels_per_meter", TEXELS_PER_METRE)
	m.set_shader_parameter(&"use_mipmaps", false)
	m.set_shader_parameter(&"roughness", 1.0)
	m.set_shader_parameter(&"specular", 0.1)
	# Thinner than the scene's fog, and capped: the painting's rocks keep their lit faces and
	# shadow sides at that distance.
	m.set_shader_parameter(&"haze_density", HAZE_DENSITY)
	m.set_shader_parameter(&"haze_max", HAZE_MAX)
	return m


## Banded sandstone, 64 x 64 texels (~107 m each way): layers of red, rust and buff of varying
## thickness up the cliff, each texel a shade off its neighbours, and dark streaks of desert
## varnish running down from ledges. v runs up the rock.
static func strata() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1882
	var colours := [Color(0.64, 0.33, 0.19), Color(0.68, 0.37, 0.21), Color(0.6, 0.3, 0.18),
			Color(0.72, 0.45, 0.28), Color(0.66, 0.35, 0.2), Color(0.58, 0.29, 0.17), Color(0.7, 0.41, 0.24)]
	var band := []
	var y := 0
	while y < n:
		var c: Color = colours[rng.randi_range(0, colours.size() - 1)]
		for k in rng.randi_range(2, 7):
			band.append(c)
		y += band.size() - y
	var streak := []
	for x in n:
		streak.append(rng.randf() < 0.3)
	for yy in n:
		for x in n:
			var c: Color = band[yy]
			c = c.darkened(rng.randf() * 0.16).lightened(rng.randf() * 0.06)
			if streak[x] and rng.randf() < 0.8:
				c = c.darkened(0.22 + rng.randf() * 0.12)
			img.set_pixel(x, n - 1 - yy, c)
	return ImageTexture.create_from_image(img)


# --- shapes: rings of [radius factor, height factor] from the ground up ------------------------

static func _mesa(r: float, h: float) -> Array:
	return [[[1.7, 0.0], [1.25, 0.32], [1.02, 0.38], [0.98, 0.9], [1.04, 0.93], [1.0, 1.0]], r, h]


## Low and long, far back: the range under the sun, behind the town's end.
static func _ridge(r: float, h: float) -> Array:
	return [[[1.6, 0.0], [1.15, 0.5], [1.0, 0.85], [0.8, 1.0]], r, h]


static func _butte(r: float, h: float) -> Array:
	return [[[2.0, 0.0], [1.3, 0.28], [1.0, 0.33], [0.88, 0.88], [0.95, 0.91], [0.9, 1.0]], r, h]


static func _spire(r: float, h: float) -> Array:
	return [[[2.6, 0.0], [1.4, 0.22], [1.0, 0.27], [0.78, 0.68], [0.88, 0.71], [0.74, 0.95], [0.7, 1.0]], r, h]


## A broad base with spires standing on it, like the painting's cathedral rocks.
func _cluster(at: Vector3, r: float, h: float, rng: RandomNumberGenerator) -> void:
	var base_h := h * 0.35
	_rock(at, [[[1.8, 0.0], [1.3, 0.55], [1.05, 0.65], [1.0, 1.0]], r, base_h], rng)
	for i in rng.randi_range(3, 5):
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.1, 0.65) * r
		var sr := rng.randf_range(0.12, 0.28) * r
		var sh := rng.randf_range(0.45, 1.0) * (h - base_h)
		var shape := [[[1.15, 0.0], [1.0, 0.1], [0.85, 0.72], [0.92, 0.76], [0.8, 0.94], [0.74, 1.0]], sr, sh]
		_rock(at + Vector3(cos(a) * d, base_h - 1.0, sin(a) * d), shape, rng)


## One formation: rings round an irregular footprint (the same wobble up its height, so the cliffs
## stand straight), flat faces, a cap on top, collision so you can't walk through it.
func _rock(at: Vector3, shape: Array, rng: RandomNumberGenerator) -> void:
	var rings: Array = shape[0]
	var r: float = shape[1]
	var h: float = shape[2]
	var sides := 20
	var wobble := []
	for k in 4:
		wobble.append([rng.randf_range(0.04, 0.14), rng.randi_range(2, 5), rng.randf() * TAU])
	var footprint := []
	for s in sides:
		var t := TAU * s / sides
		var f := 1.0
		for w in wobble:
			f += (w[0] as float) * sin((w[1] as int) * t + (w[2] as float))
		# Fluting: each column of cliff in or out a little, the same all the way up (fins and
		# gullies), so the cliffs read craggy rather than turned.
		f += rng.randf_range(-0.09, 0.09)
		footprint.append(Vector2(cos(t), sin(t)) * f)
	# Each ledge a little in or out of the plan.
	var jitter := []
	for i in rings.size():
		jitter.append(rng.randf_range(0.93, 1.07))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rings.size() - 1:
		var r0: float = rings[i][0] * r * (1.0 if i == 0 else jitter[i])
		var r1: float = rings[i + 1][0] * r * jitter[i + 1]
		var y0: float = rings[i][1] * h
		var y1: float = rings[i + 1][1] * h
		var u := 0.0
		for s in sides:
			var a: Vector2 = footprint[s]
			var b: Vector2 = footprint[(s + 1) % sides]
			var q := [Vector3(a.x * r0, y0, a.y * r0), Vector3(b.x * r0, y0, b.y * r0),
					Vector3(b.x * r1, y1, b.y * r1), Vector3(a.x * r1, y1, a.y * r1)]
			var width := (q[1] as Vector3).distance_to(q[0])
			var uvs := [Vector2(u, y0), Vector2(u + width, y0), Vector2(u + width, y1), Vector2(u, y1)]
			u += width
			var out := Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5)
			_quad(st, q, uvs, out)
	# The top: a fan from the middle.
	var top: Array = rings[rings.size() - 1]
	var ry: float = top[0] * r * jitter[rings.size() - 1]
	var yy: float = top[1] * h
	for s in sides:
		var a: Vector2 = footprint[s] * ry
		var b: Vector2 = footprint[(s + 1) % sides] * ry
		var tri := [Vector3(0, yy, 0), Vector3(b.x, yy, b.y), Vector3(a.x, yy, a.y)]
		if ((tri[1] as Vector3) - tri[0]).cross((tri[2] as Vector3) - tri[0]).y > 0.0:
			tri = [tri[0], tri[2], tri[1]]
		for v: Vector3 in tri:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z))
			st.add_vertex(v)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Rock"
	mi.mesh = mesh
	mi.material_override = _material
	add_child(mi)
	mi.position = at
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_convex_shape()
	body.add_child(cs)
	mi.add_child(body)


## A flat-shaded quad (two triangles) facing `out`, wound for Godot (clockwise is the front).
static func _quad(st: SurfaceTool, q: Array, uvs: Array, out: Vector3) -> void:
	var n: Vector3 = ((q[1] as Vector3) - q[0]).cross((q[2] as Vector3) - q[0])
	if n.length_squared() < 1e-8:
		n = ((q[2] as Vector3) - q[0]).cross((q[3] as Vector3) - q[0])
	var order := [0, 1, 2, 0, 2, 3]
	if n.dot(out) > 0.0:
		order = [0, 2, 1, 0, 3, 2]
		n = -n
	var normal: Vector3 = -n.normalized()
	for k in order:
		st.set_normal(normal)
		st.set_uv(uvs[k])
		st.add_vertex(q[k])
