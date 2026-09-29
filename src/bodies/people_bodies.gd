class_name PeopleBodies
## The bodies made from MakeHuman by tools/blender/make_people.py (assets/people/<id>.glb): a real
## man's skin and head, fitted to our skeleton and the body envelope, skinned to our 17 bones.
## `build()` gives HumanBody the same thing BodyMesh.build() does — {bones, rests, shapes} with
## every shape cut into a piece per body part — with the generated skin and head in place of the
## lofted ones; the clothes still come from BodyMesh (they're fitted to the same envelope). With
## no generated body (or `model` empty), it's BodyMesh as before.

const PATH := "res://assets/people/%s.glb"

static var _cache := {}


static func has_model(model: StringName) -> bool:
	return model != &"" and ResourceLoader.exists(PATH % model)


static func build(anatomy: Anatomy, outfit: Dictionary, model: StringName) -> Dictionary:
	var data := BodyMesh.build(anatomy, outfit)
	if not has_model(model):
		return data
	var generated := _load(anatomy, model)
	if generated.is_empty():
		return data
	var shapes: Dictionary = (data.shapes as Dictionary).duplicate()
	for k: String in generated:
		shapes[k] = generated[k]
	return {"bones": data.bones, "rests": data.rests, "shapes": shapes, "model": model}


## The generated shapes ("skin", "head"), cut into pieces per bone. Cached per model.
static func _load(anatomy: Anatomy, model: StringName) -> Dictionary:
	if _cache.has(model):
		return _cache[model]
	var scene := load(PATH % model) as PackedScene
	var out := {}
	if scene == null:
		_cache[model] = out
		return out
	var root := scene.instantiate()
	var order := anatomy.segment_order()
	var index := {}
	for i in order.size():
		index[order[i]] = i
	var centres := {}
	for i in order.size():
		centres[i] = anatomy.segment_center(order[i])
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var shape := String(mi.name).to_lower().trim_prefix("body_")
		if not shape in ["skin", "head"] or mi.mesh == null:
			continue
		# The mesh's bone numbers are the skin's binds; ours are the anatomy's segment order.
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D
		var remap := PackedInt32Array()
		if mi.skin:
			for b in mi.skin.get_bind_count():
				var name := mi.skin.get_bind_name(b)
				if name == &"" and skel:
					name = skel.get_bone_name(mi.skin.get_bind_bone(b))
				remap.append(index.get(StringName(name), 0))
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var xf := mi.global_transform if mi.is_inside_tree() else _to_root(mi)
		for i in verts.size():
			verts[i] = xf * verts[i]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in normals.size():
			normals[i] = (xf.basis * normals[i]).normalized()
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		if uvs.size() != verts.size():
			uvs.resize(verts.size())
		var src_bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var src_weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := src_bones.size() / maxi(verts.size(), 1)
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(verts.size() * 4)
		weights.resize(verts.size() * 4)
		for v in verts.size():
			# Keep the four strongest, renormalised (the pieces take four).
			var pairs := []
			for k in per:
				var w := src_weights[v * per + k]
				if w > 0.0:
					var b := src_bones[v * per + k]
					pairs.append([remap[b] if b < remap.size() else b, w])
			pairs.sort_custom(func(a: Array, c: Array) -> bool: return a[1] > c[1])
			var total := 0.0
			for k in mini(4, pairs.size()):
				total += float(pairs[k][1])
			for k in 4:
				if k < pairs.size() and total > 0.0:
					bones[v * 4 + k] = pairs[k][0]
					weights[v * 4 + k] = float(pairs[k][1]) / total
		var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		out[shape] = BodyMesh.split_pieces(verts, normals, uvs, bones, weights, tris, centres)
	root.free()
	_cache[model] = out
	return out


## A node's transform relative to the scene root, before it's in a tree.
static func _to_root(n: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent()
	while p is Node3D and p.get_parent() != null:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t
