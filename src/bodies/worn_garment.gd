class_name WornGarment
extends RefCounted
## A garment made from a man's own skin (#917, promoted from the garment handoff's lab, #895,
## experiments/garment_handoff/glove.gd): his skin's triangles on the part of him it covers (by
## their bones' weights, cut at a cuff), welded at the mesh's seams, simplified (meshoptimizer,
## SurfaceTool.generate_lod) to a few hundred points and pushed out along their normals. It fits as
## his skin does, fingers and all. Each point keeps the bones and weights of the skin under it, so
## worn it's part of his skinned mesh (`wear`: a MeshInstance3D under his Skeleton3D with his
## skin's binds and his culling box). GarmentHandoff turns it into cloth as it's taken off.
##
## In src/bodies/ beside the body it's made from (his Skin_whole, Skeleton3D and binds); it's
## gameplay's (not body_mesh.gd or people_bodies.gd, which are characters').
##
## Only the long glove is built so far (`glove`); a stocking is the same with the leg's bones.

## The arm's bones by side (the cuff cut is along the upper arm).
const ARM := ["upper_arm_%s", "upper_arm_twist_%s_0", "upper_arm_twist_%s_1", "forearm_%s",
		"forearm_twist_%s_0", "forearm_twist_%s_1", "hand_%s"]
const FINGERS := ["thumb", "index", "middle", "ring", "little"]

var side := "l"
## How far down the upper arm the cuff comes, shoulder 0, elbow 1 (an opera glove: above the elbow).
var cuff_t := 0.42
## Pushed out from the skin (m): close on the fingers, a little looser up the forearm.
var gap_fingers := 0.002
var gap_arm := 0.004
## Simplified to about this many triangles.
var target_tris := 700

# Out:
var verts := PackedVector3Array()   # in his skin's mesh space (bind), pushed out
var normals := PackedVector3Array()
var uvs := PackedVector2Array()
var indices := PackedInt32Array()
var bones := PackedInt32Array()     # 4 a point, his skin's bind indices
var weights := PackedFloat32Array()
## Each point's bone (skeleton index) that carries most of it, and its finger ("" if none).
var main_bone := PackedInt32Array()
var finger_of := PackedStringArray()
## The points at his fingertips (the last 12 mm of each finger's end bone, out along it; not the
## thumb's: a pinch takes the fingers' ends, and the thumb comes off with the glove).
var tips: Array[int] = []
## How far each point is from his fingertips along his arm (m, at bind: fingertip, knuckles, wrist,
## elbow, cuff): the order a pull lets them go.
var along := PackedFloat32Array()
var skin: Skin
var skin_mi: MeshInstance3D
var skeleton: Skeleton3D
var report := {}

# Skinning on the CPU (as the GPU does it), only through the binds it uses: a MetaHuman has hundreds
# of binds, the garment a couple of dozen.
var _used_binds := PackedInt32Array()   # bind index of each slot
var _used_bones := PackedInt32Array()   # its skeleton bone
var _slot := PackedInt32Array()         # 4 a point: slot in _used_binds (-1 none)
var _w := PackedFloat32Array()          # 4 a point


## A long glove on `man`'s arm on `on_side` (his Skin_whole), or null if he has none.
static func glove(man: HumanBody, on_side := "l", cuff := 0.42, tris := 700) -> WornGarment:
	var g := WornGarment.new()
	g.cuff_t = cuff
	g.target_tris = tris
	return g if g.build(man, on_side) else null


## Built from `man`'s Skin_whole. False if he has none (or nothing of it is on that arm).
func build(man: Node, on_side := "l") -> bool:
	side = on_side
	skeleton = man.skeleton
	if skeleton == null:
		return false
	skin_mi = skeleton.get_node_or_null(^"Skin_whole") as MeshInstance3D
	if skin_mi == null or skin_mi.skin == null:
		return false
	skin = skin_mi.skin
	var arrays := skin_mi.mesh.surface_get_arrays(0)
	var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var sn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var sb: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var sw: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var si: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var per := sb.size() / sv.size()
	var arm_bones := _arm_bones()
	var bind_bone := _bind_bones()
	# The cuff: along his upper arm in the skin's space (the bone's rest there = inverse bind).
	var sh := _rest_at("upper_arm_" + side)
	var el := _rest_at("forearm_" + side)
	var axis := el - sh
	var keep := PackedByteArray()
	keep.resize(sv.size())
	for i in sv.size():
		var w_arm := 0.0
		for k in per:
			if arm_bones.has(bind_bone[sb[i * per + k]]):
				w_arm += sw[i * per + k]
		var t := (sv[i] - sh).dot(axis) / axis.length_squared()
		keep[i] = 1 if (w_arm >= 0.5 and t >= cuff_t) else 0
	# Welded by position (the mesh is split at its UV seams and hard edges).
	var weld := {}
	var welded := PackedInt32Array()
	welded.resize(sv.size())
	welded.fill(-1)
	var wv := PackedVector3Array()
	var wn := PackedVector3Array()
	var src := PackedInt32Array()
	for i in sv.size():
		if keep[i] == 0:
			continue
		var key := Vector3i((sv[i] * 10000.0).round())
		if weld.has(key):
			welded[i] = weld[key]
			wn[weld[key]] += sn[i]
		else:
			weld[key] = wv.size()
			welded[i] = wv.size()
			wv.append(sv[i])
			wn.append(sn[i])
			src.append(i)
	var tri := PackedInt32Array()
	for t in range(0, si.size(), 3):
		var a := welded[si[t]]
		var b := welded[si[t + 1]]
		var c := welded[si[t + 2]]
		if a >= 0 and b >= 0 and c >= 0 and a != b and b != c and a != c:
			tri.append_array([a, b, c])
	if tri.is_empty():
		return false
	for i in wn.size():
		wn[i] = wn[i].normalized()
	report.skin_points = wv.size()
	report.skin_tris = tri.size() / 3
	# Simplified (meshoptimizer through SurfaceTool), then only the points still used.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in wv.size():
		st.set_normal(wn[i])
		st.add_vertex(wv[i])
	for x in tri:
		st.add_index(x)
	var lod := st.generate_lod(1.0, target_tris * 3)
	if lod.is_empty():
		lod = tri
	var remap := {}
	for x in lod:
		if not remap.has(x):
			remap[x] = remap.size()
	var order := []
	order.resize(remap.size())
	for x in remap:
		order[remap[x]] = x
	for x in lod:
		indices.append(remap[x])
	_drop_degenerate()
	for j in order.size():
		var o: int = order[j]
		var i := src[o]
		var bw := []
		for k in per:
			bw.append([sw[i * per + k], sb[i * per + k]])
		bw.sort_custom(func(p: Array, q: Array) -> bool: return p[0] > q[0])
		var total := 0.0
		for k in mini(4, per):
			total += float(bw[k][0])
		for k in 4:
			var has := k < per
			bones.append(int(bw[k][1]) if has else 0)
			weights.append(float(bw[k][0]) / maxf(total, 1e-6) if has else 0.0)
		var mb := bind_bone[int(bw[0][1])]
		main_bone.append(mb)
		var bn := skeleton.get_bone_name(mb)
		var fing := ""
		if bn.begins_with("finger_"):
			fing = bn.get_slice("_", 1)
		finger_of.append(fing)
		var gap := gap_fingers if (fing != "" or bn.begins_with("hand")) else gap_arm
		verts.append(wv[o] + wn[o] * gap)
		normals.append(wn[o])
	_smooth_normals()
	_uvs(sh, el)
	_tips()
	_along()
	_skinning_setup(bind_bone)
	_relief()
	report.points = verts.size()
	report.tris = indices.size() / 3
	report.tips = tips.size()
	return true


func _arm_bones() -> Dictionary:
	var out := {}
	for n: String in ARM:
		out[skeleton.find_bone(n % side)] = true
	for f: String in FINGERS:
		for k in 3:
			out[skeleton.find_bone("finger_%s_%s_%d" % [f, side, k])] = true
	out.erase(-1)
	return out


## Bind index -> skeleton bone.
func _bind_bones() -> PackedInt32Array:
	var out := PackedInt32Array()
	for b in skin.get_bind_count():
		var bi := skin.get_bind_bone(b)
		if bi < 0:
			bi = skeleton.find_bone(skin.get_bind_name(b))
		out.append(bi)
	return out


## Where a bone's head is in his skin's mesh space at bind (the inverse of its bind pose).
func _rest_at(bone_name: String) -> Vector3:
	var bi := skeleton.find_bone(bone_name)
	for b in skin.get_bind_count():
		if skin.get_bind_bone(b) == bi or skin.get_bind_name(b) == bone_name:
			return skin.get_bind_pose(b).affine_inverse().origin
	return skeleton.get_bone_global_rest(bi).origin


func _drop_degenerate() -> void:
	var out := PackedInt32Array()
	for t in range(0, indices.size(), 3):
		var a := indices[t]
		var b := indices[t + 1]
		var c := indices[t + 2]
		if a != b and b != c and a != c:
			out.append_array([a, b, c])
	indices = out


## Normals from the simplified triangles (the skin's own are too fine for the fewer points).
func _smooth_normals() -> void:
	var acc := PackedVector3Array()
	acc.resize(verts.size())
	for t in range(0, indices.size(), 3):
		var a := verts[indices[t]]
		var b := verts[indices[t + 1]]
		var c := verts[indices[t + 2]]
		var n := (b - a).cross(c - a)
		for k in 3:
			acc[indices[t + k]] += n
	for i in verts.size():
		var n := acc[i].normalized()
		normals[i] = n if n.dot(normals[i]) > -0.2 else normals[i]


## UVs in metres: along the arm, and round it (for the leather's grain).
func _uvs(sh: Vector3, el: Vector3) -> void:
	var axis := (el - sh).normalized()
	var ref := axis.cross(Vector3.UP).normalized()
	if ref.length() < 0.5:
		ref = axis.cross(Vector3.FORWARD).normalized()
	var ref2 := axis.cross(ref)
	for v in verts:
		var d := v - sh
		var a := d.dot(axis)
		var radial := d - axis * a
		var ang := atan2(radial.dot(ref2), radial.dot(ref))
		uvs.append(Vector2(ang * 0.04, a))


## The fingertip points: on each finger's end bone, the last 12 mm out along it.
func _tips() -> void:
	for f: String in ["index", "middle", "ring", "little"]:
		var b2 := skeleton.find_bone("finger_%s_%s_2" % [f, side])
		var b1 := skeleton.find_bone("finger_%s_%s_1" % [f, side])
		if b2 < 0 or b1 < 0:
			continue
		var p2 := _rest_at(skeleton.get_bone_name(b2))
		var p1 := _rest_at(skeleton.get_bone_name(b1))
		var dir := (p2 - p1).normalized()
		var far := -INF
		var on: Array[int] = []
		for i in verts.size():
			if main_bone[i] == b2:
				on.append(i)
				far = maxf(far, (verts[i] - p2).dot(dir))
		for i in on:
			if (verts[i] - p2).dot(dir) >= far - 0.012:
				tips.append(i)


func _along() -> void:
	var tip := _rest_at("finger_middle_%s_2" % side)
	tip += (tip - _rest_at("finger_middle_%s_1" % side)) * 0.9
	var sh := _rest_at("upper_arm_" + side)
	var el := _rest_at("forearm_" + side)
	var line := [tip, _rest_at("finger_middle_%s_0" % side), _rest_at("hand_" + side), el, sh.lerp(el, cuff_t)]
	for v in verts:
		var best := INF
		var at := 0.0
		var run := 0.0
		for k in line.size() - 1:
			var a: Vector3 = line[k]
			var b: Vector3 = line[k + 1]
			var t := clampf((v - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
			var d := v.distance_to(a.lerp(b, t))
			if d < best:
				best = d
				at = run + t * a.distance_to(b)
			run += a.distance_to(b)
		along.append(at)


## How far his skin stands above each point's own skin level (m; under the garment as worn by
## RELIEF_KEEP at least): between the simplified garment's points his skin bulges (a round limb
## under a chord; the Studio men's shirt sleeves have their folds modelled, 3-10 mm), and cloth
## resting on a shape through the points alone would lie under it there. SkinCollider lifts each of
## its points by this.
var relief := PackedFloat32Array()
## The relief lifts SkinCollider's shape to at most this under the garment as worn (m).
const RELIEF_KEEP := 0.0005


func _relief() -> void:
	if _arm_skin.is_empty():
		_skin_setup()
	var cell := 0.02
	var grid := {}
	for k in _arm_skin.size():
		(grid.get_or_add(Vector3i((_sv[_arm_skin[k]] / cell).floor()), []) as Array).append(_arm_skin[k])
	# Each point's reach: half its longest edge (the chord its neighbours make with it).
	var reach := PackedFloat32Array()
	reach.resize(verts.size())
	for t in range(0, indices.size(), 3):
		for e in 3:
			var a := indices[t + e]
			var b := indices[t + (e + 1) % 3]
			var l := verts[a].distance_to(verts[b]) * 0.5
			reach[a] = maxf(reach[a], l)
			reach[b] = maxf(reach[b], l)
	relief.resize(verts.size())
	for i in verts.size():
		var bn := skeleton.get_bone_name(main_bone[i])
		var gap := gap_fingers if (finger_of[i] != "" or bn.begins_with("hand")) else gap_arm
		var n := normals[i]
		var level := verts[i] - n * gap
		var r := minf(reach[i], 0.03)
		var c := Vector3i((level / cell).floor())
		var span := int(ceil(r / cell))
		var top := 0.0
		for dx in range(-span, span + 1):
			for dy in range(-span, span + 1):
				for dz in range(-span, span + 1):
					for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
						var d := _sv[j] - level
						var h := d.dot(n)
						if h > top and (d - n * h).length() < r and absf(h) < gap * 3.0:
							top = h
		relief[i] = clampf(top, 0.0, maxf(gap - RELIEF_KEEP, 0.0))


## Only the binds its points use, each point's weights by slot (weights under 1% dropped).
func _skinning_setup(bind_bone: PackedInt32Array) -> void:
	var slot_of := {}
	_slot.resize(verts.size() * 4)
	_w.resize(verts.size() * 4)
	for i in verts.size():
		for k in 4:
			var w := weights[i * 4 + k]
			if w < 0.01:
				_slot[i * 4 + k] = -1
				_w[i * 4 + k] = 0.0
				continue
			var b := bones[i * 4 + k]
			if not slot_of.has(b):
				slot_of[b] = _used_binds.size()
				_used_binds.append(b)
				_used_bones.append(bind_bone[b])
			_slot[i * 4 + k] = slot_of[b]
			_w[i * 4 + k] = w
	report.binds = _used_binds.size()


## The garment as a skinned mesh under his Skeleton3D, with his skin's binds and culling box.
func wear(material: Material) -> MeshInstance3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = indices
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "Glove_" + side
	mi.mesh = m
	mi.skin = skin
	mi.material_override = material
	mi.layers = skin_mi.layers
	mi.transform = skin_mi.transform
	mi.custom_aabb = skin_mi.custom_aabb  # (his: the bind pose's box would cull it once the arm moves)
	skeleton.add_child(mi)
	mi.skeleton = mi.get_path_to(skeleton)
	return mi


## Each point where it's drawn now (world), skinned on the CPU as the GPU does it.
func posed() -> PackedVector3Array:
	return posed_points(verts, PackedByteArray(), skin_mi.transform)


## The bones' skinning matrices now (a slot each), and the skeleton's to-world.
func _mats() -> Array[Transform3D]:
	var mats: Array[Transform3D] = []
	mats.resize(_used_binds.size())
	for s in _used_binds.size():
		mats[s] = skeleton.get_bone_global_pose(_used_bones[s]) * skin.get_bind_pose(_used_binds[s])
	return mats


## `local` (one a garment point, in his skin's mesh space) skinned by the garment's weights (world);
## only those marked in `only` if it's given (the rest left at ZERO).
func posed_points(local: PackedVector3Array, only := PackedByteArray(), xf := Transform3D.IDENTITY) -> PackedVector3Array:
	var mats := _mats()
	var to_world := skeleton.global_transform
	var out := PackedVector3Array()
	out.resize(local.size())
	var plain := xf == Transform3D.IDENTITY
	var slot := _slot
	var w := _w
	var some := not only.is_empty()
	for i in local.size():
		if some and only[i] == 0:
			continue
		var v := local[i] if plain else xf * local[i]
		var q := i * 4
		var p := (mats[slot[q]] * v) * w[q]
		var s1 := slot[q + 1]
		if s1 >= 0:
			p += (mats[s1] * v) * w[q + 1]
			var s2 := slot[q + 2]
			if s2 >= 0:
				p += (mats[s2] * v) * w[q + 2]
				var s3 := slot[q + 3]
				if s3 >= 0:
					p += (mats[s3] * v) * w[q + 3]
		out[i] = to_world * p
	return out


# --- His arm's skin as drawn now (for counting cloth through it) ---------------------------------

var _arm_skin := PackedInt32Array()  # Skin_whole's vertices on this arm (the glove's region, wider)
var _sv := PackedVector3Array()
var _sn := PackedVector3Array()
var _sb := PackedInt32Array()
var _sw := PackedFloat32Array()
var _per := 4
## The points of the last count more than `depth` under his skin, and how deep each was (m).
var last_under: Array[int] = []
var last_depths: Array[float] = []


func _skin_setup() -> void:
	var arrays := skin_mi.mesh.surface_get_arrays(0)
	_sv = arrays[Mesh.ARRAY_VERTEX]
	_sn = arrays[Mesh.ARRAY_NORMAL]
	_sb = arrays[Mesh.ARRAY_BONES]
	_sw = arrays[Mesh.ARRAY_WEIGHTS]
	_per = _sb.size() / _sv.size()
	var arm := _arm_bones()
	var bind_bone := _bind_bones()
	for i in _sv.size():
		var w := 0.0
		for k in _per:
			if arm.has(bind_bone[_sb[i * _per + k]]):
				w += _sw[i * _per + k]
		if w >= 0.5:
			_arm_skin.append(i)


## How many of `pts` (world) are under his arm's skin as drawn now: more than `depth` (m) behind
## the nearest skin vertex within 3 cm, along its normal. (A measure: it skins his whole arm on the
## CPU, ~10 ms; the tests and the bench, never the game.)
func under_skin(pts: PackedVector3Array, depth := 0.002) -> int:
	last_under.clear()
	last_depths.clear()
	if _arm_skin.is_empty():
		_skin_setup()
	var bind_bone := _bind_bones()
	var mats: Array[Transform3D] = []
	for b in skin.get_bind_count():
		mats.append(skeleton.get_bone_global_pose(bind_bone[b]) * skin.get_bind_pose(b))
	var to_world := skeleton.global_transform * skin_mi.transform
	var cell := 0.015
	var grid := {}
	var wp := PackedVector3Array()
	var wn := PackedVector3Array()
	wp.resize(_arm_skin.size())
	wn.resize(_arm_skin.size())
	for k in _arm_skin.size():
		var i := _arm_skin[k]
		var p := Vector3.ZERO
		var n := Vector3.ZERO
		for j in _per:
			var w := _sw[i * _per + j]
			if w > 0.0:
				var m := mats[_sb[i * _per + j]]
				p += (m * _sv[i]) * w
				n += (m.basis * _sn[i]) * w
		wp[k] = to_world * p
		wn[k] = (to_world.basis * n).normalized()
		var key := Vector3i((wp[k] / cell).floor())
		(grid.get_or_add(key, []) as Array).append(k)
	var count := 0
	for qi in pts.size():
		var q := pts[qi]
		var c := Vector3i((q / cell).floor())
		var best := 0.03 * 0.03
		var bk := -1
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				for dz in range(-2, 3):
					for k: int in grid.get(c + Vector3i(dx, dy, dz), []):
						var d := wp[k].distance_squared_to(q)
						if d < best:
							best = d
							bk = k
		if bk >= 0 and (q - wp[bk]).dot(wn[bk]) < -depth:
			count += 1
			last_under.append(qi)
			last_depths.append(-(q - wp[bk]).dot(wn[bk]))
	return count


## The glove's look: black kid, a soft sheen at its edges (cloth's rim), its grain a fine noise.
static func kid_leather() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.035, 0.03, 0.032)
	m.roughness = 0.48
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var n := NoiseTexture2D.new()
	n.width = 256
	n.height = 256
	n.seamless = true
	n.as_normal_map = true
	n.bump_strength = 1.2
	var fn := FastNoiseLite.new()
	fn.frequency = 0.09
	fn.seed = 895
	n.noise = fn
	m.normal_enabled = true
	m.normal_texture = n
	m.normal_scale = 0.35
	m.uv1_scale = Vector3(60, 60, 1)  # UVs in metres: grain every ~1.7 cm
	return m
