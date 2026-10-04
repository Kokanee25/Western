class_name BodyInterior
## What's under the skin, for when a wound opens a body part: built from the same anatomy the
## bullets trace through (config/anatomy.json), low-poly and pixel-textured like everything else.
## A wet flesh wall lining the part, ribs as bars round the chest, spine, skull and jaw, lungs,
## heart, liver, gut, kidneys, muscle, the big vessels. Only built for a part the first time it opens.
##
## Skin, clothes, the flesh wall and the hollow bones (skull, ribs) use the wound shaders
## (src/bodies/shaders/), which cut the openings out; `apply()` hands them the openings.

const SKIN_SHADER := preload("res://src/bodies/shaders/body_skin.gdshader")
const SKIN_DOUBLE_SHADER := preload("res://src/bodies/shaders/body_skin_double.gdshader")
const INSIDE_SHADER := preload("res://src/bodies/shaders/body_inside.gdshader")
const MAX_OPENINGS := 8

const COLOURS := {
	&"flesh": Color(0.45, 0.08, 0.07), &"muscle": Color(0.5, 0.1, 0.09), &"bone": Color(0.86, 0.8, 0.66),
	&"artery": Color(0.62, 0.06, 0.05), &"vein": Color(0.22, 0.1, 0.24), &"nerve": Color(0.85, 0.78, 0.55),
	&"brain": Color(0.78, 0.6, 0.6), &"heart": Color(0.42, 0.06, 0.06), &"lung": Color(0.82, 0.5, 0.52),
	&"liver": Color(0.36, 0.1, 0.07), &"spleen": Color(0.35, 0.08, 0.14), &"kidney": Color(0.45, 0.14, 0.1),
	&"gut": Color(0.8, 0.52, 0.48), &"airway": Color(0.8, 0.66, 0.62), &"gullet": Color(0.72, 0.42, 0.4),
	&"eye": Color(0.92, 0.9, 0.86),
}

static var _mats := {}
## What's still to paint ahead (`warm_up`), one a frame.
static var _warm_queue: Array[Callable] = []
static var _warming := false
static var _warm_call: Callable


## The skin/clothing shader in place of a body part's plain material: same pixel texture, same
## colour, but it can be torn open. One per mesh (each keeps its own openings).
static func skin_material(base: StandardMaterial3D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SKIN_SHADER
	m.set_shader_parameter(&"albedo_tex", base.albedo_texture)
	m.set_shader_parameter(&"tint", base.albedo_color)
	m.set_shader_parameter(&"uv_scale", base.uv1_scale.x)
	m.set_shader_parameter(&"roughness_value", base.roughness)
	m.set_shader_parameter(&"reduced_gore", Settings.reduced_gore)
	return m


## The plain pixel-textured material for a kind of tissue (fragments, loose bits).
static func material(key: StringName) -> StandardMaterial3D:
	return _tex_material(key, 93 if key == &"bone" else 91 if key == &"flesh" else 95 + COLOURS.keys().find(key))


static func _tex_material(key: StringName, seed: int) -> StandardMaterial3D:
	if not _mats.has(key):
		var colour: Color = COLOURS.get(key, Color(0.5, 0.1, 0.1))
		var m := GunParts.material("inside:" + key, PixelArt.skin("inside:" + key, colour, seed), 0.0, 0.35 if key != &"bone" else 0.7)
		_mats[key] = m
	return _mats[key]


## Paint ahead what a first wound would paint on the spot: the insides' textures and the wound
## decals are painted in script the first time each is needed (~5 ms each: the first chest to
## open took ~90 ms on its frame, the first belly ~40). One a frame, once per run, from when the
## first person comes into the world; the seeds are the ones `build()` and `_paint_wound` use.
static func warm_up(tree: SceneTree) -> void:
	if _warming or tree == null:
		return
	_warming = true
	var keys := COLOURS.keys()
	for k: StringName in keys:
		var seed := 91 if k == &"flesh" else (93 if k == &"bone" else 95 + keys.find(k))
		_warm_queue.append(_tex_material.bind(k, seed))
	_warm_queue.append(PixelArt.blood.bind("furrow", 17, true, 16))
	_warm_queue.append(PixelArt.blood.bind("wound_entry", 5, true, 16))
	_warm_queue.append(PixelArt.blood.bind("wound_exit", 9, true, 16))
	for i in 4:
		_warm_queue.append(PixelArt.blood.bind("stain%d" % i, i, false, 32))
	_warm_call = _warm_step.bind(tree)
	tree.process_frame.connect(_warm_call)


static func _warm_step(tree: SceneTree) -> void:
	if _warm_queue.is_empty():
		tree.process_frame.disconnect(_warm_call)
		return
	_warm_queue.pop_front().call()


## A shell that can be opened: the flesh wall (seen from inside) or a hollow bone (from outside).
static func _openable(key: StringName, seed: int, inside: bool) -> ShaderMaterial:
	var base := _tex_material(key, seed)
	if inside:
		var m := ShaderMaterial.new()
		m.shader = INSIDE_SHADER
		m.set_shader_parameter(&"albedo_tex", base.albedo_texture)
		m.set_shader_parameter(&"uv_scale", base.uv1_scale.x)
		m.set_shader_parameter(&"reduced_gore", Settings.reduced_gore)
		return m
	return skin_material(base)


## Build the inside of one segment under its visual node. `center` is the segment's rest centre
## (anatomy space), since the visual node's space is the segment's centred rest space.
static func build(segment: StringName, vis: Node3D, anatomy: Anatomy) -> Node3D:
	var root := Node3D.new()
	root.name = "Inside"
	vis.add_child(root)
	var center := anatomy.segment_center(segment)
	# The flesh wall, a few millimetres in from the skin, seen from inside.
	for c: Array in anatomy.segments[segment].capsules:
		var r: float = float(c[2]) - 0.004
		_capsule(root, "Wall", c[0], c[1], r, center, _openable(&"flesh", 91, true))
	for st: Dictionary in anatomy.by_segment.get(segment, []):
		var kind: StringName = st.kind
		if kind == &"finger":
			continue
		var shell: float = st.get(&"shell", 0.0)
		if kind == &"bone" and shell > 0.0:
			if st.get(&"cage", 0.0) > 0.0:
				_ribs(root, st, center, anatomy, segment)
			else:
				# Skull: a bone shell that opens with the wound, showing what's inside.
				_capsule(root, String(st.id), st.a, st.b, st.radius, center, _openable(&"bone", 93, false))
			continue
		var key: StringName = kind
		if kind == &"organ":
			key = StringName(st.get(&"organ", "gut"))
			if st.id == &"heart":
				key = &"heart"
			elif st.id == &"liver" or st.id == &"spleen":
				key = st.id
		var mat := _tex_material(key, 95 + COLOURS.keys().find(key))
		# The skin is low-poly: its flat faces sit up to a centimetre inside the true curve, so
		# anything close under it is drawn a little deeper, or it would show through.
		var pa := _pull_in(anatomy, segment, st.a, st.radius)
		var pb := _pull_in(anatomy, segment, st.b, st.radius)
		_capsule(root, String(st.id), pa, pb, st.radius, center, mat)
	return root


## Points through a bone (anatomy space): over the surface of a hollow one (skull, ribcage),
## along the axis of a solid one. What a destroyed region smashes is what these fall inside.
static func bone_points(st: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a: Vector3 = st.a
	var b: Vector3 = st.b
	var r: float = st.radius
	var length := (b - a).length()
	if st.get(&"shell", 0.0) > 0.0:
		if length < 0.001:
			for i in 48:
				var y := 1.0 - 2.0 * (i + 0.5) / 48.0
				var ring := sqrt(1.0 - y * y)
				var ang := i * 2.39996
				out.append(a + Vector3(cos(ang) * ring, y, sin(ang) * ring) * r)
			return out
		var basis := HumanBody._along(b - a)
		var n := int(length / 0.026)
		for i in n + 1:
			var c := a.lerp(b, float(i) / maxf(n, 1))
			for k in 16:
				var ang := TAU * k / 16.0
				out.append(c + (basis.x * cos(ang) + basis.z * sin(ang)) * r)
		return out
	var steps := maxi(1, int(length / 0.02))
	for i in steps + 1:
		out.append(a.lerp(b, float(i) / steps))
	return out


## Ribs: bars round the cage, a couple of centimetres apart, not a solid wall.
static func _ribs(root: Node3D, st: Dictionary, center: Vector3, anatomy: Anatomy, segment: StringName) -> void:
	var a: Vector3 = st.a
	var b: Vector3 = st.b
	var axis := (b - a).normalized()
	var basis := HumanBody._along(axis)
	var n := int((b - a).length() / 0.026)
	var mat := _openable(&"bone", 93, false)
	for i in n + 1:
		var c := a.lerp(b, float(i) / maxf(n, 1))
		# Each rib as big as the cage, but never out through the skin (the shoulders slope in).
		var r: float = st.radius
		while r > 0.03 and not _ring_inside(anatomy, segment, c, basis, r + 0.006):
			r -= 0.005
		if r <= 0.03:
			continue
		var ring := MeshInstance3D.new()
		ring.name = "Rib%d" % i
		var torus := TorusMesh.new()
		torus.outer_radius = r
		torus.inner_radius = r - 0.011
		torus.rings = 12
		torus.ring_segments = 4
		ring.mesh = torus
		ring.material_override = mat.duplicate()
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.layers = Layers.VIS_INSIDE
		ring.basis = basis
		ring.position = c - center
		root.add_child(ring)


const SKIN_FACET := 0.013


static func _pull_in(anatomy: Anatomy, segment: StringName, p: Vector3, r: float) -> Vector3:
	var best_out := -INF
	var inward := Vector3.ZERO
	for cap: Array in anatomy.segments[segment].capsules:
		var ca: Vector3 = cap[0]
		var ab: Vector3 = (cap[1] as Vector3) - ca
		var t := clampf((p - ca).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var on_axis := ca + ab * t
		var depth: float = float(cap[2]) - p.distance_to(on_axis)
		if depth > best_out:
			best_out = depth
			inward = (on_axis - p).normalized() if p.distance_to(on_axis) > 1e-5 else Vector3.ZERO
	var need := r + SKIN_FACET - best_out
	return p + inward * need if need > 0.0 else p


## Whether a ring (centre, its plane from `basis`, radius) sits wholly inside a segment's skin.
static func _ring_inside(anatomy: Anatomy, segment: StringName, c: Vector3, basis: Basis, r: float) -> bool:
	for k in 16:
		var ang := TAU * k / 16.0
		var p := c + (basis.x * cos(ang) + basis.z * sin(ang)) * r
		var inside := false
		for cap: Array in anatomy.segments[segment].capsules:
			var ca: Vector3 = cap[0]
			var ab: Vector3 = (cap[1] as Vector3) - ca
			var t := clampf((p - ca).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			if p.distance_to(ca + ab * t) <= float(cap[2]):
				inside = true
				break
		if not inside:
			return false
	return true


static func _capsule(root: Node3D, n: String, a: Vector3, b: Vector3, r: float, center: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var length := (b - a).length()
	if length < 0.001:
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 10
		sm.rings = 5
		mi.mesh = sm
	else:
		var cm := CapsuleMesh.new()
		cm.radius = r
		cm.height = length + r * 2.0
		cm.radial_segments = 10
		cm.rings = 2
		mi.mesh = cm
		mi.basis = HumanBody._along(b - a)
	mi.position = (a + b) * 0.5 - center
	# Openable shells need their own copy (each keeps its own openings).
	mi.material_override = mat.duplicate() if mat is ShaderMaterial else mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Layers.VIS_INSIDE
	root.add_child(mi)
	return mi


## Hand the openings (segment-centred space: Vector4(x, y, z, radius)) to every openable mesh under
## `vis`, each in its own local space.
static func apply(vis: Node3D, openings: Array[Vector4], reduced_gore: bool) -> void:
	for mi: MeshInstance3D in vis.find_children("*", "MeshInstance3D", true, false):
		var m := mi.material_override as ShaderMaterial
		if m == null or not (m.shader == SKIN_SHADER or m.shader == INSIDE_SHADER):
			continue
		var to_mesh := (vis.global_transform.affine_inverse() * mi.global_transform).affine_inverse()
		var arr := PackedVector4Array()
		for o in openings:
			var p := to_mesh * Vector3(o.x, o.y, o.z)
			arr.append(Vector4(p.x, p.y, p.z, o.w))
		while arr.size() < MAX_OPENINGS:
			arr.append(Vector4.ZERO)
		m.set_shader_parameter(&"wound_count", mini(openings.size(), MAX_OPENINGS))
		m.set_shader_parameter(&"wounds", arr)
		m.set_shader_parameter(&"reduced_gore", reduced_gore)
