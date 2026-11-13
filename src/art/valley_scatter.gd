class_name ValleyScatter
extends Node3D
## What grows and lies on the valley's land (#891): dry grass, stones, sagebrush, rocks and boulders,
## fallen logs, ponderosa pines up high and cottonwoods by the water, placed by rules (the slope, the
## water, the roads, the height, the distance from town: ValleyScatterTuning, config/valley_scatter.tres)
## over the ground map (ValleyGroundArt) and the bake (ValleyTerrain). Nothing on a road, a pad, a
## town lot, the rail bed or a ford.
##
## The land is cut into cells a species (its `cell`); a cell near enough the camera is made (seeded by
## where it is: the same stones every run) as one MultiMesh a piece, its near pieces to `near_m` and its
## far ones (fewer triangles) beyond, each to its range by Godot's visibility ranges; cells are made on a
## frame budget as the camera nears and freed as it goes. What you can stand behind or be stopped by
## (boulders, trunks) is one StaticBody3D a cell holding all its shapes (a few dozen bodies in all:
## the town is near Jolt's body limit, docs/reviews/2026-11-valley-bench.md). Prof `scatter` (else).

var terrain: ValleyTerrain
var art: ValleyGroundArt
var tuning: ValleyScatterTuning
## The ground (for its collision layers); none: the scatter's bodies on layer 1.
var ground: Node3D
## Where the cells are chosen from instead of the viewport's camera (a test's, a tool's).
var focus: Variant = null
## Instances placed all told, by species (the tests' and the bench's count), and cells made.
var placed := {}
var cells_made := 0

var _species: Array = []
var _cells := {}  # Vector3i(species, cx, cz) -> Node3D
var _noise := FastNoiseLite.new()
var _frame := 0
var _last := Vector3.INF
var _queue: Array[Vector3i] = []
var _plant_mats := {}

const PLANT := "res://src/art/scatter_plant.gdshader"


class Species:
	var index := 0
	var d: Dictionary
	var near: Array[Mesh] = []
	var far: Array[Mesh] = []
	var piece_scale: Array = []
	var tree: Dictionary = {}
	var tree_far: Dictionary = {}


func setup(t: ValleyTerrain, a: ValleyGroundArt, tn: ValleyScatterTuning) -> void:
	terrain = t
	art = a
	tuning = tn if tn else ValleyScatterTuning.new()
	_noise.seed = 891
	_noise.frequency = 1.0
	_noise.fractal_octaves = 3
	for i in tuning.species.size():
		var d: Dictionary = tuning.species[i]
		var s := Species.new()
		s.index = i
		s.d = d
		if d.has("tree"):
			s.tree = ValleyTrees.meshes(StringName(d.tree), true)
			s.tree_far = ValleyTrees.meshes(StringName(d.tree), false)
		else:
			var tint: Array = d.get("tint", [1.0, 1.0, 1.0])
			for piece: String in d.meshes:
				var nm: Mesh = load(String(d.dir) + piece + "_near.res")
				var fm: Mesh = load(String(d.dir) + piece + "_far.res")
				s.near.append(_tinted(nm, tint, d))
				s.far.append(_tinted(fm, tint, d))
			s.piece_scale = d.get("piece_scale", [])
		_species.append(s)
		placed[String(d.name)] = 0


## A copy of the scan's mesh with its material tinted and set to fade out by distance (dithered); a
## plant's (`plant` in its species: saturation, brightness, vary) drawn by scatter_plant.gdshader.
func _tinted(m: Mesh, tint: Array, d: Dictionary) -> Mesh:
	var out := m.duplicate() as Mesh
	var fade := float(d.get("fade", 0.0))
	for s in out.get_surface_count():
		var mat := out.surface_get_material(s)
		if not mat is StandardMaterial3D:
			continue
		var std := mat as StandardMaterial3D
		if d.has("plant"):
			var pl: Dictionary = d.plant
			var key := "%s_%d" % [d.name, std.get_instance_id()]
			if not _plant_mats.has(key):
				var sm := ShaderMaterial.new()
				sm.shader = load(PLANT)
				sm.set_shader_parameter(&"albedo_tex", std.albedo_texture)
				sm.set_shader_parameter(&"normal_tex", std.normal_texture)
				sm.set_shader_parameter(&"has_normal", std.normal_texture != null)
				sm.set_shader_parameter(&"arm_tex", std.roughness_texture)
				sm.set_shader_parameter(&"has_arm", std.roughness_texture != null)
				sm.set_shader_parameter(&"tint", Color(float(tint[0]), float(tint[1]), float(tint[2])))
				sm.set_shader_parameter(&"saturation", float(pl.get("saturation", 1.0)))
				sm.set_shader_parameter(&"brightness", float(pl.get("brightness", 1.0)))
				sm.set_shader_parameter(&"vary", float(pl.get("vary", 0.15)))
				sm.set_shader_parameter(&"alpha_cut", std.alpha_scissor_threshold if std.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR else 0.4)
				if fade > 0.0:
					sm.set_shader_parameter(&"fade_from", float(d.range) - fade)
					sm.set_shader_parameter(&"fade_to", float(d.range))
				_plant_mats[key] = sm
			out.surface_set_material(s, _plant_mats[key])
			continue
		var sm := std.duplicate() as StandardMaterial3D
		sm.albedo_color = sm.albedo_color * Color(float(tint[0]), float(tint[1]), float(tint[2]))
		if fade > 0.0:
			sm.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
			sm.distance_fade_min_distance = float(d.range)
			sm.distance_fade_max_distance = float(d.range) - fade
		out.surface_set_material(s, sm)
	return out


func _process(_delta: float) -> void:
	if terrain == null or art == null or not art.ready:
		return
	var pt := Prof.start()
	var cam := _eye()
	if cam != Vector3.INF:
		_frame += 1
		var jumped := _last == Vector3.INF or cam.distance_to(_last) > tuning.jump_m
		if jumped or _frame % tuning.look_every == 0:
			_last = cam
			_choose(cam)
		if jumped:
			while not _queue.is_empty():
				_make(_queue.pop_back())
		else:
			var u := Time.get_ticks_usec()
			var n := 0
			while not _queue.is_empty():
				if World.deterministic:
					if n >= 2:
						break
				elif (Time.get_ticks_usec() - u) / 1000.0 > tuning.build_ms:
					break
				_make(_queue.pop_back())
				n += 1
	Prof.stop(&"scatter", pt)


func _eye() -> Vector3:
	if focus != null:
		return focus
	var c := get_viewport().get_camera_3d() if is_inside_tree() else null
	return c.global_position if c else Vector3.INF


## Which cells should be made (queued, nearest last so they're made first) and which freed.
func _choose(cam: Vector3) -> void:
	_queue.clear()
	var want := {}
	for s: Species in _species:
		var cell := float(s.d.cell)
		var r := float(s.d.range) + cell * 0.71
		var c0 := Vector2i(floori((cam.x - r) / cell), floori((cam.z - r) / cell))
		var c1 := Vector2i(floori((cam.x + r) / cell), floori((cam.z + r) / cell))
		for cz in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var mid := Vector2((cx + 0.5) * cell, (cz + 0.5) * cell)
				if mid.distance_to(Vector2(cam.x, cam.z)) <= r:
					var key := Vector3i(s.index, cx, cz)
					want[key] = true
					if not _cells.has(key):
						_queue.append(key)
	for key: Vector3i in _cells.keys():
		if want.has(key):
			continue
		var s: Species = _species[key.x]
		var cell := float(s.d.cell)
		var mid := Vector2((key.y + 0.5) * cell, (key.z + 0.5) * cell)
		if mid.distance_to(Vector2(cam.x, cam.z)) > float(s.d.range) + cell * 0.71 + tuning.evict_m:
			(_cells[key] as Node3D).queue_free()
			_cells.erase(key)
	_queue.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return _dist(a, cam) > _dist(b, cam))


func _dist(key: Vector3i, cam: Vector3) -> float:
	var cell := float((_species[key.x] as Species).d.cell)
	return Vector2((key.y + 0.5) * cell, (key.z + 0.5) * cell).distance_to(Vector2(cam.x, cam.z))


## Everything round `at` made now (a tool's or a test's: no frames to wait).
func make_all_round(at: Vector3) -> void:
	focus = at
	_last = at
	_choose(at)
	while not _queue.is_empty():
		_make(_queue.pop_back())


## How likely a candidate at (x, z) grows, by its species' rules (0 none).
func _chance(d: Dictionary, x: float, z: float, h: float, slope: float) -> float:
	var sl: Array = d.slope
	if slope < float(sl[0]) or slope > float(sl[1]):
		return 0.0
	var hi: Array = d.high
	if h < float(hi[0]) - 10.0 or h > float(hi[1]) + 10.0:
		return 0.0
	if art.kept_clear(x, z, float(d.clear)):
		return 0.0
	var town := _from_town(x, z)
	if town < float(d.town):
		return 0.0
	var water := art.water_at(x, z)
	if d.has("water_within") and water > float(d.water_within):
		return 0.0
	if water < 1.5:
		return 0.0
	var p := 1.0
	# Its height band, eased at the ends.
	p *= smoothstep(float(hi[0]) - 10.0, float(hi[0]) + 10.0, h) * (1.0 - smoothstep(float(hi[1]) - 10.0, float(hi[1]) + 10.0, h))
	# The middle of its slope band.
	var mid := (float(sl[0]) + float(sl[1])) * 0.5
	var span := maxf(1.0, (float(sl[1]) - float(sl[0])) * 0.5)
	p *= 1.0 - 0.6 * clampf(absf(slope - mid) / span, 0.0, 1.0)
	var near_water := 1.0 - smoothstep(0.0, 40.0, water)
	p *= 1.0 + float(d.wet) * near_water
	p *= 1.0 - float(d.dry) * near_water * 0.9
	# Thinning near the town's edge.
	p *= smoothstep(float(d.town), float(d.town) + 40.0, town)
	# Clumps.
	var pm := float(d.patch_m)
	var pn := _noise.get_noise_2d(x / pm, z / pm) * 0.5 + 0.5
	var pt := float(d.patch)
	p *= lerpf(1.0, smoothstep(0.35, 0.75, pn) * 2.0, pt)
	return clampf(p, 0.0, 1.0)


func _from_town(x: float, z: float) -> float:
	var r := tuning.town_rect
	var dx := maxf(maxf(r.position.x - x, x - r.end.x), 0.0)
	var dz := maxf(maxf(r.position.y - z, z - r.end.y), 0.0)
	return Vector2(dx, dz).length()


func _slope(x: float, z: float) -> float:
	var e := 1.0
	var gx := (terrain.height(x + e, z) - terrain.height(x - e, z)) / (2.0 * e)
	var gz := (terrain.height(x, z + e) - terrain.height(x, z - e)) / (2.0 * e)
	return rad_to_deg(atan(Vector2(gx, gz).length()))


func _normal(x: float, z: float) -> Vector3:
	var e := 1.0
	var gx := (terrain.height(x + e, z) - terrain.height(x - e, z)) / (2.0 * e)
	var gz := (terrain.height(x, z + e) - terrain.height(x, z - e)) / (2.0 * e)
	return Vector3(-gx, 1.0, -gz).normalized()


## A cell made: its instances by the rules, a MultiMesh a piece (near and far), its body.
func _make(key: Vector3i) -> void:
	var s: Species = _species[key.x]
	var d := s.d
	var cell := float(d.cell)
	var node := Node3D.new()
	node.name = "%s_%d_%d" % [d.name, key.y, key.z]
	add_child(node)
	_cells[key] = node
	cells_made += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	var n := int(round(float(d.per_100m2) * cell * cell / 100.0))
	var pieces := maxi(1, s.near.size()) if s.tree.is_empty() else 1
	var xfs: Array = []
	for k in pieces:
		xfs.append([])
	var shapes: Array = []
	var origin := Vector3((key.y + 0.5) * cell, 0.0, (key.z + 0.5) * cell)
	var points := PackedVector3Array()
	var sc: Array = d.scale
	for k in n:
		var x := (key.y + rng.randf()) * cell
		var z := (key.z + rng.randf()) * cell
		var roll := rng.randf()
		var piece := rng.randi() % pieces
		var size := rng.randf_range(float(sc[0]), float(sc[1]))
		var turn := rng.randf() * TAU
		if not terrain.rect().has_point(Vector2(x, z)):
			continue
		var h := terrain.height(x, z)
		var slope := _slope(x, z)
		if roll >= _chance(d, x, z, h, slope):
			continue
		var up := Vector3.UP.lerp(_normal(x, z), float(d.tilt)).normalized()
		var b := Basis(Quaternion(Vector3.UP, up)) * Basis(Vector3.UP, turn)
		var ps := float(s.piece_scale[piece]) if piece < s.piece_scale.size() else 1.0
		b = b.scaled(Vector3.ONE * size * ps)
		var aabb: AABB = s.near[piece].get_aabb() if s.tree.is_empty() else AABB(Vector3(-1, 0, -1), Vector3(2, float(s.tree.height), 2))
		var sink := float(d.sink) * aabb.size.y * size * ps
		var p := Vector3(x, h - sink, z)
		(xfs[piece] as Array).append(Transform3D(b, p - origin))
		points.append(p)
		var coll := String(d.get("collide", ""))
		if coll == "sphere":
			var r := maxf(aabb.size.x, aabb.size.z) * 0.38 * size * ps
			if r > 0.3:
				shapes.append([coll, Transform3D(Basis(), p - origin + Vector3(0, aabb.size.y * size * ps * 0.25, 0)), r])
		elif coll == "trunk":
			shapes.append([coll, Transform3D(Basis(), p - origin + Vector3(0, 2.0 * size, 0)), float(s.tree.trunk_r) * size])
		placed[String(d.name)] += 1
	node.position = origin
	# Where each instance stands (world), for the tests and anyone asking (a MultiMesh's own
	# transforms can't be read back without a renderer).
	node.set_meta(&"points", points)
	var near_m := float(d.near_m)
	var range_m := float(d.range)
	for k in pieces:
		var list: Array = xfs[k]
		if list.is_empty():
			continue
		if s.tree.is_empty():
			_multi(node, s.near[k], list, 0.0, minf(near_m, range_m), d)
			if range_m > near_m:
				_multi(node, s.far[k], list, near_m, range_m, d)
		else:
			_multi(node, s.tree.trunk, list, 0.0, near_m, d)
			_multi(node, s.tree.crown, list, 0.0, near_m, d, true)
			_multi(node, s.tree_far.trunk, list, near_m, range_m, d)
			_multi(node, s.tree_far.crown, list, near_m, range_m, d, true)
	if not shapes.is_empty():
		var body := StaticBody3D.new()
		body.name = "Body"
		if ground:
			body.collision_layer = ground.get(&"collision_layer")
			body.collision_mask = ground.get(&"collision_mask")
		body.set_meta(&"surface", &"stone" if String(d.get("collide", "")) == "sphere" else &"wood")
		body.set_meta(&"scatter", true)
		for sh: Array in shapes:
			var shape: Shape3D
			if sh[0] == "sphere":
				var sp := SphereShape3D.new()
				sp.radius = sh[2]
				shape = sp
			else:
				var cy := CylinderShape3D.new()
				cy.radius = sh[2]
				cy.height = 4.0
				shape = cy
			var owner_id := body.create_shape_owner(body)
			body.shape_owner_add_shape(owner_id, shape)
			body.shape_owner_set_transform(owner_id, sh[1])
		node.add_child(body)


## One MultiMesh of `mesh` at `list` (cell-relative), drawn between `from` and `to` metres from the
## camera (the cell's middle: Godot's visibility range); a tree's crown gets its tint and seed.
func _multi(parent: Node3D, mesh: Mesh, list: Array, from: float, to: float, d: Dictionary, crown := false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = crown
	mm.mesh = mesh
	mm.instance_count = list.size()
	for i in list.size():
		mm.set_instance_transform(i, list[i])
		if crown:
			var t: Transform3D = list[i]
			var v := absf(sin(t.origin.x * 12.9898 + t.origin.z * 78.233))
			mm.set_instance_custom_data(i, Color(0.85 + v * 0.3, 0.9 + v * 0.15, 0.85 + (1.0 - v) * 0.25, v))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(d.get("shadows", false)) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_begin = from
	mi.visibility_range_end = to
	parent.add_child(mi)
