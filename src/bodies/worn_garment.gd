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
## His skin under it for SkinCollider, simplified less than the garment (about this many
## triangles; 0: the garment's own points): the cloth's points rest on it, and a coarser skin's
## chords lie under his sleeve's folds between them.
var collider_tris := 0
## That skin (a WornGarment of the same cut, `collider_tris` triangles), or null.
var under: WornGarment
## His skin finer than the garment (about this many triangles over the cut; 0: none), whose hand's
## vertices our cloth keeps under its triangles (#1008: his fingers poke out between the garment's
## few points round each). `fine`: that skin, or null.
var fine_tris := 0
var fine: WornGarment

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
## His skin's vertices the garment covers (1 a vertex of his Skin_whole): while it's worn, the
## triangles all of whose corners are covered aren't drawn (`cover_skin`), as games hide the skin
## under clothes: a Studio man's modelled sleeve folds stand 3-10 mm above his skin, through a
## garment a few mm off it.
var covered := PackedByteArray()
var skeleton: Skeleton3D
var report := {}

# Skinning on the CPU (as the GPU does it), only through the binds it uses: a MetaHuman has hundreds
# of binds, the garment a couple of dozen.
var _used_binds := PackedInt32Array()   # bind index of each slot
var _used_bones := PackedInt32Array()   # its skeleton bone
var _slot := PackedInt32Array()         # 4 a point: slot in _used_binds (-1 none)
var _w := PackedFloat32Array()          # 4 a point


## A long glove on `man`'s arm on `on_side` (his Skin_whole), or null if he has none.
static func glove(man: HumanBody, on_side := "l", cuff := 0.42, tris := 700, under_tris := 0,
		fine_skin_tris := 0) -> WornGarment:
	var g := WornGarment.new()
	g.cuff_t = cuff
	g.target_tris = tris
	g.collider_tris = under_tris
	g.fine_tris = fine_skin_tris
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
	covered = keep
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
	if collider_tris > target_tris:
		under = WornGarment.new()
		under.cuff_t = cuff_t
		under.target_tris = collider_tris
		under.gap_fingers = gap_fingers
		under.gap_arm = gap_arm
		if under.build(man, side):
			report.collider_tris = under.indices.size() / 3
		else:
			under = null
	if fine_tris > target_tris:
		fine = WornGarment.new()
		fine.cuff_t = cuff_t
		fine.target_tris = fine_tris
		fine.gap_fingers = gap_fingers
		fine.gap_arm = gap_arm
		if fine.build(man, side):
			report.fine_tris = fine.indices.size() / 3
		else:
			fine = null
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
	_line = _along_line()
	for v in verts:
		along.append(_along_at(v))


var _line := []


## The line from his fingertips up his arm to the cuff (his skin's mesh space at bind).
func _along_line() -> Array:
	var tip := _rest_at("finger_middle_%s_2" % side)
	tip += (tip - _rest_at("finger_middle_%s_1" % side)) * 0.9
	var sh := _rest_at("upper_arm_" + side)
	var el := _rest_at("forearm_" + side)
	return [tip, _rest_at("finger_middle_%s_0" % side), _rest_at("hand_" + side), el, sh.lerp(el, cuff_t)]


## How far along `_line` (from the fingertips) the point nearest `v` is (m).
func _along_at(v: Vector3) -> float:
	var best := INF
	var at := 0.0
	var run := 0.0
	for k in _line.size() - 1:
		var a: Vector3 = _line[k]
		var b: Vector3 = _line[k + 1]
		var t := clampf((v - a).dot(b - a) / maxf((b - a).length_squared(), 1e-9), 0.0, 1.0)
		var d := v.distance_to(a.lerp(b, t))
		if d < best:
			best = d
			at = run + t * a.distance_to(b)
		run += a.distance_to(b)
	return at


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


## His skin under it hidden while it's worn (`on`), or drawn whole again (once it's off his arm). A
## copy of his Skin_whole's mesh with the covered triangles left out (the same vertices, so
## everything that reads his skin by vertex still does), swapped in and out; while it's drawn off,
## the covered skin is shown by `uncover` as the pull lets the garment go of it. False if his skin
## isn't the merged mesh any more (a wound splits him into pieces: they draw).
func cover_skin(on: bool) -> bool:
	if on:
		if skin_mi == null or not is_instance_valid(skin_mi) or not skin_mi.is_inside_tree():
			return false
		if _skin_full == null:
			_skin_full = skin_mi.mesh
		if _skin_cut == null:
			_skin_cut = _cut_mesh(_skin_full as ArrayMesh)
		if _skin_cut == null:
			return false
		skin_mi.mesh = _skin_cut
		return true
	if _under_mi != null and is_instance_valid(_under_mi):
		_under_mi.queue_free()
	_under_mi = null
	_shown_bytes = PackedByteArray()
	_tri_shown.fill(0)
	if skin_mi == null or not is_instance_valid(skin_mi):
		return false
	if _skin_full != null and skin_mi.mesh == _skin_cut:
		skin_mi.mesh = _skin_full
	return true


## Whether his skin under it is hidden now (some of it, while it's drawn off).
func skin_covered() -> bool:
	return _skin_cut != null and skin_mi != null and is_instance_valid(skin_mi) and skin_mi.mesh == _skin_cut


## While it's drawn off: his covered skin shown under the garment's points `ids` (the cloth there
## has moved off where it was worn; GarmentHandoff says when): every covered triangle with a corner
## nearest one of them. The rest stays hidden under the cloth still lying as worn. A small mesh (the
## covered skin alone), its triangles added as they're shown and rebuilt only when some are.
func uncover(ids: Array[int]) -> void:
	if not skin_covered() or _under_surface.is_empty() or ids.is_empty():
		return
	var added := 0
	for i in ids:
		if i < 0 or i >= _tris_of_point.size():
			continue
		for t: int in _tris_of_point[i]:
			if _tri_shown[t] == 1:
				continue
			_tri_shown[t] = 1
			_add_index(t)
			added += 1
	if added == 0:
		return
	if _under_mi == null:
		_under_mi = MeshInstance3D.new()
		_under_mi.name = skin_mi.name + "_under_" + side
		_under_mi.material_override = skin_mi.material_override
		_under_mi.layers = skin_mi.layers
		_under_mi.custom_aabb = skin_mi.custom_aabb
		_under_mi.transform = skin_mi.transform
		_under_mi.mesh = ArrayMesh.new()
		skeleton.add_child(_under_mi)
		_under_mi.skin = skin
		_under_mi.skeleton = _under_mi.get_path_to(skeleton)
	# Only its index buffer is new: the surface's vertices were encoded once (`_under_surface`), so
	# showing more of it is a copy, not the 0.85 ms add_surface_from_arrays took.
	var rid := _under_mi.mesh.get_rid()
	RenderingServer.mesh_clear(rid)
	var d := _under_surface.duplicate()
	d["index_data"] = _shown_bytes
	d["index_count"] = _shown_bytes.size() / _index_size
	d["lods"] = []
	RenderingServer.mesh_add_surface(rid, d)


func _add_index(t: int) -> void:
	var at := _shown_bytes.size()
	_shown_bytes.resize(at + 3 * _index_size)
	for e in 3:
		var v := _under_idx[t * 3 + e]
		if _index_size == 2:
			_shown_bytes.encode_u16(at + e * 2, v)
		else:
			_shown_bytes.encode_u32(at + e * 4, v)


## How many of its covered skin's triangles are shown now (of `under_tris`).
func shown_tris() -> int:
	return _shown_bytes.size() / (3 * _index_size)


var _skin_full: Mesh
var _skin_cut: ArrayMesh
var _under_mi: MeshInstance3D
var _under_arrays := []                  # (while it's made) the covered skin's own vertices
var _under_idx := PackedInt32Array()     # its triangles
var _tris_of_point: Array = []           # each garment point's covered triangles (PackedInt32Array)
var _tri_shown := PackedByteArray()
var _shown_bytes := PackedByteArray()    # the shown triangles' indices, as the surface keeps them
var _under_surface := {}                 # the covered skin's surface, encoded (all its triangles)
var _index_size := 4                     # bytes an index in it


## `full` without the triangles all of whose corners are covered (each surface, blend shapes kept).
func _cut_mesh(full: ArrayMesh) -> ArrayMesh:
	if full == null:
		return null
	var out := ArrayMesh.new()
	out.blend_shape_mode = full.blend_shape_mode
	for b in full.get_blend_shape_count():
		out.add_blend_shape(full.get_blend_shape_name(b))
	var cut := 0
	for s in full.get_surface_count():
		var a := full.surface_get_arrays(s)
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var n: int = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var ours := s == 0 and n == covered.size() and idx.size() > 0
		var kept := PackedInt32Array()
		if ours:
			kept.resize(idx.size())
			var k := 0
			for t in range(0, idx.size(), 3):
				if covered[idx[t]] == 1 and covered[idx[t + 1]] == 1 and covered[idx[t + 2]] == 1:
					cut += 1
					continue
				kept[k] = idx[t]
				kept[k + 1] = idx[t + 1]
				kept[k + 2] = idx[t + 2]
				k += 3
			kept.resize(k)
		var fmt := full.surface_get_format(s)
		var flags := fmt & (Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS | Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
		for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
			flags |= fmt & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift)
		if ours:
			_under_mesh(a, idx, n, flags)
			a[Mesh.ARRAY_INDEX] = kept
		out.add_surface_from_arrays(full.surface_get_primitive_type(s), a, full.surface_get_blend_shape_arrays(s), {}, flags)
		out.surface_set_material(s, full.surface_get_material(s))
		out.surface_set_name(s, full.surface_get_name(s))
	out.custom_aabb = full.custom_aabb
	report.skin_tris_hidden = cut
	return out


## The covered skin as a mesh of its own (`uncover`): its vertices (every array of his skin's, only
## those), its triangles sorted by where along him they start.
func _under_mesh(a: Array, idx: PackedInt32Array, n: int, flags: int) -> void:
	var new_of := PackedInt32Array()
	new_of.resize(n)
	new_of.fill(-1)
	var olds := PackedInt32Array()
	for i in n:
		if covered[i] == 1:
			new_of[i] = olds.size()
			olds.append(i)
	_under_arrays = []
	_under_arrays.resize(Mesh.ARRAY_MAX)
	for k in Mesh.ARRAY_MAX:
		if k == Mesh.ARRAY_INDEX or a[k] == null:
			continue
		var src = a[k]
		var per: int = src.size() / n
		var out = src.slice(0, 0)
		out.resize(olds.size() * per)
		for j in olds.size():
			var o := olds[j] * per
			for e in per:
				out[j * per + e] = src[o + e]
		_under_arrays[k] = out
	# Each covered skin vertex's nearest garment point (at bind; the garment's points stand a few mm
	# off the skin they were made from).
	var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var cell := 0.02
	var grid := {}
	for j in verts.size():
		(grid.get_or_add(Vector3i((verts[j] / cell).floor()), []) as Array).append(j)
	var point_of := {}
	for i in olds:
		var c := Vector3i((sv[i] / cell).floor())
		var best := INF
		var bj := 0
		for r in 3:
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					for dz in range(-r, r + 1):
						if maxi(absi(dx), maxi(absi(dy), absi(dz))) != r:
							continue
						for j: int in grid.get(c + Vector3i(dx, dy, dz), []):
							var d := verts[j].distance_squared_to(sv[i])
							if d < best:
								best = d
								bj = j
			if best < INF and r >= 1:
				break
		point_of[i] = bj
	_tris_of_point = []
	_tris_of_point.resize(verts.size())
	for j in verts.size():
		_tris_of_point[j] = PackedInt32Array()
	_under_idx = PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if covered[idx[t]] == 1 and covered[idx[t + 1]] == 1 and covered[idx[t + 2]] == 1:
			var tri := _under_idx.size() / 3
			_under_idx.append_array([new_of[idx[t]], new_of[idx[t + 1]], new_of[idx[t + 2]]])
			var owners := {}
			for e in 3:
				owners[point_of[idx[t + e]]] = true
			for j: int in owners:
				var l: PackedInt32Array = _tris_of_point[j]
				l.append(tri)
				_tris_of_point[j] = l
	_tri_shown = PackedByteArray()
	_tri_shown.resize(_under_idx.size() / 3)
	report.under_tris = _under_idx.size() / 3
	_under_arrays[Mesh.ARRAY_INDEX] = _under_idx
	var once := ArrayMesh.new()
	once.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _under_arrays, [], {}, flags)
	_under_surface = RenderingServer.mesh_get_surface(once.get_rid(), 0)
	_index_size = (_under_surface["index_data"] as PackedByteArray).size() / maxi(int(_under_surface["index_count"]), 1)
	_under_arrays = []  # (encoded: not needed again)


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
var _arm_tris := PackedInt32Array()  # its triangles (3 a triangle, places in _arm_skin)
var _vtris: Array = []               # each of _arm_skin's triangles (PackedInt32Array)
## The measure's depth: under the nearest point on his skin's triangles, by the skin's normal
## there (false: under the nearest skin vertex along its normal, as #917 measured; at his sleeve's
## modelled folds the nearest vertex is often on a fold's flank, its normal sideways).
static var by_surface := true
var _sv := PackedVector3Array()
var _sn := PackedVector3Array()
var _sb := PackedInt32Array()
var _sw := PackedFloat32Array()
var _per := 4
## The points of the last count more than `depth` under his skin, and how deep each was (m).
var last_under: Array[int] = []
## His hand's skin vertices through the cloth at the last `skin_out` (places in _arm_skin).
var last_out: Array[int] = []
var last_out_h: Array[float] = []
var _hand_k := PackedInt32Array()    # his hand's covered skin vertices (places in _arm_skin)
var _fore_k := PackedInt32Array()    # his forearm's (skin_out's `forearm`)
var _ptris: Array = []               # each garment point's triangles
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
	# His arm's triangles, each vertex's (by its place in _arm_skin): the measure's surface.
	var at := {}
	for k in _arm_skin.size():
		at[_arm_skin[k]] = k
	var idx: PackedInt32Array = skin_mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] if _skin_full == null \
			else _skin_full.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var lists: Array = []
	lists.resize(_arm_skin.size())
	for k in lists.size():
		lists[k] = PackedInt32Array()
	for t in range(0, idx.size(), 3):
		if at.has(idx[t]) and at.has(idx[t + 1]) and at.has(idx[t + 2]):
			var tri := _arm_tris.size() / 3
			for e in 3:
				var k: int = at[idx[t + e]]
				_arm_tris.append(k)
				var l: PackedInt32Array = lists[k]
				l.append(tri)
				lists[k] = l
	_vtris = lists


## How many of `pts` (world) are under his arm's skin as drawn now: more than `depth` (m) behind
## the nearest point on his skin's triangles near it (within 3 cm), by his skin's normal there
## (`by_surface`; or behind the nearest skin vertex along its normal). (A measure: it skins his whole arm on the
## CPU, ~10 ms; the tests and the bench, never the game.)
func under_skin(pts: PackedVector3Array, depth := 0.002) -> int:
	last_under.clear()
	last_depths.clear()
	if _arm_skin.is_empty():
		_skin_setup()
	var cell := 0.015
	var grid := {}
	var wp := PackedVector3Array()
	var wn := PackedVector3Array()
	_pose_arm(wp, wn)
	for k in _arm_skin.size():
		var key := Vector3i((wp[k] / cell).floor())
		(grid.get_or_add(key, []) as Array).append(k)
	var count := 0
	var near: Array[int] = []
	for qi in pts.size():
		var q := pts[qi]
		var c := Vector3i((q / cell).floor())
		var best := 0.03 * 0.03
		var bk := -1
		near.clear()
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				for dz in range(-2, 3):
					for k: int in grid.get(c + Vector3i(dx, dy, dz), []):
						var d := wp[k].distance_squared_to(q)
						if d < best:
							best = d
							bk = k
						if d < 0.012 * 0.012:
							near.append(k)
		if bk < 0:
			continue
		var h := (q - wp[bk]).dot(wn[bk])
		if by_surface:
			h = _surface_height(q, bk, near, wp, wn)
		if h < -depth:
			count += 1
			last_under.append(qi)
			last_depths.append(-h)
	return count


## His arm's skin vertices as drawn now (world), and their normals, by place in _arm_skin.
func _pose_arm(wp: PackedVector3Array, wn: PackedVector3Array) -> void:
	var bind_bone := _bind_bones()
	var mats: Array[Transform3D] = []
	for b in skin.get_bind_count():
		mats.append(skeleton.get_bone_global_pose(bind_bone[b]) * skin.get_bind_pose(b))
	var to_world := skeleton.global_transform * skin_mi.transform
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


## How many of his hand's skin vertices (hand and fingers, the ones it covers as worn) are through
## the cloth now (#1008): more than `depth` (m) in front of the nearest of the cloth's triangles
## (`pts` world, the garment's own `indices`) within 15 mm, his skin there facing the same way as
## that triangle (a bare finger lying on the cloth faces it: not counted). The cloth's points can
## all be on his skin's front while his finer fingers poke out between them: this counts what the
## eye sees. (A measure, ~5 ms; the bench, never the game.)
func skin_out(pts: PackedVector3Array, depth := 0.001, forearm := false) -> int:
	if _arm_skin.is_empty():
		_skin_setup()
	if _hand_k.is_empty():
		var bind_bone := _bind_bones()
		for k in _arm_skin.size():
			var i := _arm_skin[k]
			if covered.size() > i and covered[i] == 0:
				continue
			var best := 0.0
			var bb := -1
			for j in _per:
				if _sw[i * _per + j] > best:
					best = _sw[i * _per + j]
					bb = bind_bone[_sb[i * _per + j]]
			var bn := skeleton.get_bone_name(bb) if bb >= 0 else ""
			if bn.begins_with("hand_" + side) or (bn.begins_with("finger_") and bn.contains("_%s_" % side)):
				_hand_k.append(k)
			elif bn.begins_with("forearm_" + side):
				_fore_k.append(k)
		var lists: Array = []
		lists.resize(verts.size())
		for i in lists.size():
			lists[i] = PackedInt32Array()
		for t in indices.size() / 3:
			for e in 3:
				var l: PackedInt32Array = lists[indices[t * 3 + e]]
				l.append(t)
				lists[indices[t * 3 + e]] = l
		_ptris = lists
	var wp := PackedVector3Array()
	var wn := PackedVector3Array()
	_pose_arm(wp, wn)
	var cell := 0.015
	var grid := {}
	for i in pts.size():
		(grid.get_or_add(Vector3i((pts[i] / cell).floor()), []) as Array).append(i)
	last_out.clear()
	last_out_h.clear()
	var count := 0
	for k in (_fore_k if forearm else _hand_k):
		var v := wp[k]
		var c := Vector3i((v / cell).floor())
		var seen := {}
		var best := 0.015 * 0.015
		var h := 0.0
		var facing := 0.0
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					for i: int in grid.get(c + Vector3i(dx, dy, dz), []):
						for t: int in _ptris[i]:
							if seen.has(t):
								continue
							seen[t] = true
							var a := pts[indices[t * 3]]
							var b := pts[indices[t * 3 + 1]]
							var cc := pts[indices[t * 3 + 2]]
							var bc := _closest_on_tri(v, a, b, cc)
							var q := a * bc.x + b * bc.y + cc * bc.z
							var d := v.distance_squared_to(q)
							if d < best:
								var n := (cc - a).cross(b - a).normalized()  # (Godot: a front face is clockwise)
								best = d
								h = (v - q).dot(n)
								facing = n.dot(wn[k])
		if h > depth and facing > 0.3:
			count += 1
			last_out.append(k)
			last_out_h.append(h)
	return count


## Height of `q` over his skin (m, negative under it): to the nearest point on the triangles of the
## skin vertices near it (`near`, within 12 mm, and the nearest, `bk`), signed by the skin's own
## (smooth) normal there, interpolated across the triangle.
func _surface_height(q: Vector3, bk: int, near: Array[int], wp: PackedVector3Array, wn: PackedVector3Array) -> float:
	if not near.has(bk):
		near.append(bk)
	var best := INF
	var h := 0.0
	var seen := {}
	for k in near:
		for t: int in _vtris[k]:
			if seen.has(t):
				continue
			seen[t] = true
			var ia := _arm_tris[t * 3]
			var ib := _arm_tris[t * 3 + 1]
			var ic := _arm_tris[t * 3 + 2]
			var bc := _closest_on_tri(q, wp[ia], wp[ib], wp[ic])
			var p := wp[ia] * bc.x + wp[ib] * bc.y + wp[ic] * bc.z
			var d := q.distance_squared_to(p)
			if d < best:
				best = d
				var n := (wn[ia] * bc.x + wn[ib] * bc.y + wn[ic] * bc.z).normalized()
				h = signf((q - p).dot(n)) * sqrt(d)
	return h


## Barycentric weights of the point on triangle a, b, c nearest `p` (Ericson, Real-Time Collision
## Detection, 5.1.5).
static func _closest_on_tri(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return Vector3(1, 0, 0)
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return Vector3(0, 1, 0)
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		var v := d1 / (d1 - d3)
		return Vector3(1.0 - v, v, 0)
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return Vector3(0, 0, 1)
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		var w := d2 / (d2 - d6)
		return Vector3(1.0 - w, 0, w)
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		var w := (d4 - d3) / ((d4 - d3) + (d5 - d6))
		return Vector3(0, 1.0 - w, w)
	var denom := 1.0 / (va + vb + vc)
	var v := vb * denom
	var w := vc * denom
	return Vector3(1.0 - v - w, v, w)


## A glove's inside: the leather's flesh side, undyed (a dull dark brown suede: not so light it reads as a hole onto the floor), drawn from inside only
## (its back faces) at its points, a few mm under the outside (the outside is drawn proud of them):
## the cuff's opening shows the leather's thickness, and where the bunched glove folds through
## itself (the cloth doesn't meet itself) it's a fold's inside, not a black hole.
static func lining() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.17, 0.12, 0.09)
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	return m


## The glove's look: black kid, a soft sheen at its edges (cloth's rim), its grain a fine noise.
static func kid_leather() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.035, 0.03, 0.032)
	m.roughness = 0.48
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.4
	# Its outside (black kid) and its inside (`lining`: undyed, the leather's flesh side), each drawn
	# only from its own side: the glove's triangles face out, as the skin they were made from does.
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.next_pass = lining()
	# Drawn 4 mm proud of its points (the physics' cloth is where its points are): between them its
	# flat triangles would dip into his skin's finer shape where the cloth lies on him.
	m.grow = true
	m.grow_amount = 0.004
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
