class_name ValleyTrees
extends RefCounted
## The valley's trees built in code (#891): Poly Haven's scanned trees are millions of triangles
## (the scans' fetch skips them), so a ponderosa pine and a cottonwood are made here, each a trunk
## (and the cottonwood's limbs) and a crown of noise-holed blobs (src/art/foliage.gdshader), at two
## levels of detail. Seeded: the same tree every run. ValleyScatter instances them.

const FOLIAGE := "res://src/art/foliage.gdshader"
const BARK_NORMAL := "res://assets/textures/scans/Wood086/normal.jpg"

static var _cache := {}


## {trunk: ArrayMesh, crown: ArrayMesh} of `kind` (&"pine", &"cottonwood") at `near` or far detail.
static func meshes(kind: StringName, near: bool) -> Dictionary:
	var key := "%s_%s" % [kind, near]
	if not _cache.has(key):
		_cache[key] = _pine(near) if kind == &"pine" else _cottonwood(near)
	return _cache[key]


static func _bark(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if ResourceLoader.exists(BARK_NORMAL):
		m.normal_enabled = true
		m.normal_texture = load(BARK_NORMAL)
		m.normal_scale = 1.6
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(1.6, 0.35, 1.6)
	return m


static func _foliage(a: Color, b: Color, fade_from: float, fade_to: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(FOLIAGE)
	m.set_shader_parameter(&"colour_a", a)
	m.set_shader_parameter(&"colour_b", b)
	m.set_shader_parameter(&"fade_from", fade_from)
	m.set_shader_parameter(&"fade_to", fade_to)
	return m


## A ponderosa pine 18 m tall: a straight trunk bare to half way, a ragged rounded-conical crown.
static func _pine(near: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1873
	var h := 18.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_limb(st, Vector3.ZERO, Vector3(0, h * 0.97, 0), 0.32, 0.06, 8 if near else 5, 5 if near else 2)
	var trunk := st.commit()
	trunk.surface_set_material(0, _bark(Color(0.36, 0.25, 0.18)))
	var cs := SurfaceTool.new()
	cs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blobs := 36 if near else 10
	var centre := Vector3(0, h * 0.7, 0)
	for i in blobs:
		var t := (float(i) + rng.randf() * 0.7) / blobs
		var y := lerpf(h * 0.36, h * 0.99, t)
		# Branch clumps standing out from the trunk, widest a third of the way up the crown.
		var spread := (2.9 * pow(1.0 - t, 0.6) * (0.6 + 0.4 * sin(PI * minf(1.0, t * 1.6 + 0.3)))) + 0.3
		var a := rng.randf() * TAU
		var off := Vector3(cos(a), 0, sin(a)) * spread * rng.randf_range(0.55, 1.0)
		var r := lerpf(1.35, 0.7, t) * rng.randf_range(0.8, 1.2) * (1.0 if near else 1.4)
		_blob(cs, Vector3(off.x, y - 0.4 * t, off.z), Vector3(r * 1.5, r * 0.62, r * 1.5), centre, 2 if near else 1, rng)
	var crown := cs.commit()
	crown.surface_set_material(0, _foliage(Color(0.13, 0.19, 0.10), Color(0.24, 0.30, 0.15), 0.0, 0.0))
	return {"trunk": trunk, "crown": crown, "height": h, "trunk_r": 0.32}


## A cottonwood 14 m tall: a stout trunk forking low into leaning limbs, a broad round crown.
static func _cottonwood(near: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1878
	var h := 14.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 8 if near else 5
	var fork := Vector3(0.2, 3.4, 0.1)
	_limb(st, Vector3.ZERO, fork, 0.5, 0.36, sides, 3 if near else 1)
	var tips: Array[Vector3] = []
	for k in 3:
		var a := TAU * k / 3.0 + rng.randf() * 0.8
		var tip := fork + Vector3(cos(a) * 3.2, rng.randf_range(4.5, 6.5), sin(a) * 3.2)
		_limb(st, fork, tip, 0.3, 0.1, sides, 3 if near else 1)
		tips.append(tip)
	var trunk := st.commit()
	trunk.surface_set_material(0, _bark(Color(0.40, 0.36, 0.31)))
	var cs := SurfaceTool.new()
	cs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centre := Vector3(0, h * 0.62, 0)
	var blobs := 30 if near else 9
	for i in blobs:
		var tip: Vector3 = tips[i % tips.size()]
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.8), rng.randf_range(-1, 1)).normalized()
		var p := tip + dir * rng.randf_range(0.5, 3.0)
		p.y = clampf(p.y, 5.5, h - 1.2)
		var r := rng.randf_range(1.5, 2.4) * (1.0 if near else 1.4)
		_blob(cs, p, Vector3(r, r * 0.85, r), centre, 2 if near else 1, rng)
	var crown := cs.commit()
	crown.surface_set_material(0, _foliage(Color(0.24, 0.30, 0.12), Color(0.42, 0.44, 0.20), 0.0, 0.0))
	return {"trunk": trunk, "crown": crown, "height": h, "trunk_r": 0.5}


## A tapered limb from a to b, `rings` + 1 rings of `sides`, open at its ends.
static func _limb(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, sides: int, rings: int) -> void:
	var axis := (b - a).normalized()
	var side := axis.cross(Vector3.FORWARD if absf(axis.z) < 0.9 else Vector3.RIGHT).normalized()
	var up := side.cross(axis).normalized()
	var ring_pts: Array = []
	for k in rings + 1:
		var t := float(k) / rings
		var c := a.lerp(b, t)
		var r := lerpf(ra, rb, t) * (1.0 + (0.25 if k == 0 else 0.0))
		var ring := []
		for s in sides + 1:
			var ang := TAU * s / sides
			var nrm := (side * cos(ang) + up * sin(ang))
			ring.append([c + nrm * r, nrm, Vector2(float(s) / sides, t * (b - a).length())])
		ring_pts.append(ring)
	for k in rings:
		for s in sides:
			var q := [ring_pts[k][s], ring_pts[k][s + 1], ring_pts[k + 1][s + 1], ring_pts[k + 1][s]]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.set_normal(q[idx][1])
				st.set_uv(q[idx][2])
				st.add_vertex(q[idx][0])


## A blob of foliage: an icosphere at `c` of radii `r`, its points pushed about by the die, its
## normals between its own and out from the crown's middle (soft light across the crown); COLOR.r
## how far it faces out from the crown (the shader holes those more).
static func _blob(st: SurfaceTool, c: Vector3, r: Vector3, crown: Vector3, subdiv: int, rng: RandomNumberGenerator) -> void:
	var verts := _icosphere(subdiv)
	var bump := {}
	for tri: Array in verts:
		for v: Vector3 in tri:
			var key := v.snappedf(0.001)
			if not bump.has(key):
				bump[key] = rng.randf_range(0.82, 1.15)
	for tri: Array in verts:
		for k in [0, 2, 1]:
			var v: Vector3 = tri[k]
			var p: Vector3 = c + v * r * float(bump[v.snappedf(0.001)])
			var out := (p - crown).normalized()
			st.set_normal((v.normalized() * 0.5 + out * 0.5).normalized())
			st.set_color(Color(clampf(0.55 + 0.45 * v.normalized().dot(out), 0.0, 1.0), 0, 0))
			st.add_vertex(p)


static var _ico := {}


## An icosphere's triangles (unit), `subdiv` times split.
static func _icosphere(subdiv: int) -> Array:
	if _ico.has(subdiv):
		return _ico[subdiv]
	var t := (1.0 + sqrt(5.0)) / 2.0
	var p := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var f := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2],
		[10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11],
		[6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var tris := []
	for face: Array in f:
		tris.append([(p[face[0]] as Vector3).normalized(), (p[face[1]] as Vector3).normalized(), (p[face[2]] as Vector3).normalized()])
	for s in subdiv:
		var nt := []
		for tri: Array in tris:
			var a: Vector3 = tri[0]
			var b: Vector3 = tri[1]
			var c: Vector3 = tri[2]
			var ab := ((a + b) * 0.5).normalized()
			var bc := ((b + c) * 0.5).normalized()
			var ca := ((c + a) * 0.5).normalized()
			nt.append_array([[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]])
		tris = nt
	_ico[subdiv] = tris
	return tris
