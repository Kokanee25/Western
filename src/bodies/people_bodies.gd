class_name PeopleBodies
## The bodies made from MakeHuman by tools/blender/make_people.py (assets/people/<id>.glb): a real
## man's skin and head, fitted to our skeleton and the body envelope, skinned to our 17 bones.
## `build()` gives HumanBody the same thing BodyMesh.build() does — {bones, rests, shapes} with
## every shape cut into a piece per body part — with the generated skin, head and clothes (shirt,
## trousers, vest, draped coat, tie) in place of the lofted ones, plus `textures`: each generated
## garment's baked pixel texture (assets/people/<id>_<garment>.png). What the model doesn't have
## (boots, belts, hat) still comes from BodyMesh, fitted to the same envelope. With no generated
## body (or `model` empty), it's BodyMesh as before.

const PATH := "res://assets/people/%s.glb"
## Each generated garment's baked pixel texture.
const TEXTURE_PATH := "res://assets/people/%s_%s.png"
## The "quantise once" set: a whole man's <id>_skin_smooth.png / <id>_head_smooth.png
## (tools/blender/fit_tripo.py --smooth: no squares, no palette) where they exist. Off by default.
static var smooth_paint := false
## What make_people.py did for him (and what it measured, like his skin tone).
const REPORT_PATH := "res://assets/people/%s.json"
## His painted textures (tools/paint_bake.gd + tools/paint/finish.py): per shape, the texture
## <id>_paint_<shape>.png and the rect of the shape's UVs it covers.
const PAINT_PATH := "res://assets/people/%s_paint.json"
## Garments an outfit turns on or off (the rest of a generated body is always worn).
const OUTFIT_KEYS := ["shirt", "vest", "coat", "trousers", "boots", "bandana", "hat"]

static var _cache := {}
## Each generated head's hat fit (BodyMesh.build's `hat_fit`), measured when it's loaded.
static var _hat_fits := {}
## Where the hat's band sits: this far above his eyes (the eyes are where the face painter puts
## them, EYE_HEIGHT), low on the brow so the brim shades them, as in the painting.
const BAND_ABOVE_EYES := 0.045
const EYE_HEIGHT := 1.655


static func has_model(model: StringName) -> bool:
	return model != &"" and ResourceLoader.exists(PATH % model)


static func build(anatomy: Anatomy, outfit: Dictionary, model: StringName) -> Dictionary:
	if not has_model(model):
		return BodyMesh.build(anatomy, outfit)
	var generated := _load(anatomy, model)
	if generated.is_empty():
		return BodyMesh.build(anatomy, outfit)
	# Boots, belts and the hat are still BodyMesh's; the hat is fitted to this man's own head.
	# A model that comes dressed ("whole" in his report: a Tripo man, tools/blender/fit_tripo.py)
	# wears nothing of BodyMesh's.
	var data := BodyMesh.build(anatomy, outfit, _hat_fits.get(model, {}))
	var shapes: Dictionary = (data.shapes as Dictionary).duplicate()
	if _is_whole(model):
		shapes.clear()
	# A man with his own tie doesn't also wear the old lofted bandana (it floats off his neck).
	if generated.has("cravat"):
		shapes.erase("bandana")
	var textures := {}
	for k: String in generated:
		# His own skin and head always; a garment only if this outfit has it (a man without a coat
		# on doesn't get the model's coat), and anything BodyMesh doesn't make (the tie).
		if k in ["skin", "head"] or shapes.has(k) or not k in OUTFIT_KEYS:
			shapes[k] = generated[k]
			var png := TEXTURE_PATH % [model, k]
			if smooth_paint and ResourceLoader.exists(TEXTURE_PATH % [model, k + "_smooth"]):
				png = TEXTURE_PATH % [model, k + "_smooth"]
			if ResourceLoader.exists(png):
				textures[k] = load(png)
	var face := TEXTURE_PATH % [model, "face"]
	if ResourceLoader.exists(face):
		textures["face"] = load(face)
	var ao := TEXTURE_PATH % [model, "head_ao"]
	if ResourceLoader.exists(ao):
		textures["head_ao"] = load(ao)
	var out := {"bones": data.bones, "rests": data.rests, "shapes": shapes, "model": model, "textures": textures}
	# Painted from the painting: per shape, a texture, the UV rect it covers and how many texels a
	# side make one of its squares (the face: three, so its eyes can be drawn finer).
	var paint := {}
	var paint_squares := {}
	if FileAccess.file_exists(PAINT_PATH % model):
		var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(PAINT_PATH % model))
		if p is Dictionary:
			for shape: String in ((p as Dictionary).get("shapes", {}) as Dictionary):
				var png := TEXTURE_PATH % [model, "paint_" + shape]
				if shapes.has(shape) and ResourceLoader.exists(png):
					textures["paint_" + shape] = load(png)
					var r: Array = p.shapes[shape].uv_rect
					paint[shape] = Vector4(r[0], r[1], r[2], r[3])
					paint_squares[shape] = float(p.shapes[shape].get("texels_per_square", 1))
	out["paint"] = paint
	out["paint_squares"] = paint_squares
	# His skin tone, measured from his painted face, so body and painted sides match it.
	var report := REPORT_PATH % model
	if FileAccess.file_exists(report):
		var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(report))
		if info is Dictionary and (info as Dictionary).has("skin_tone"):
			var t: Array = info.skin_tone
			out["skin_tone"] = Color(t[0], t[1], t[2])
	return out


## Whether the model comes dressed (his report says "whole": clothes, hat and all in his skin).
static func _is_whole(model: StringName) -> bool:
	var report := REPORT_PATH % model
	if not FileAccess.file_exists(report):
		return false
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(report))
	return info is Dictionary and bool((info as Dictionary).get("whole", false))


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
		var shape := String(mi.name).to_lower().trim_prefix("body_").trim_prefix("cloth_")
		if mi.mesh == null:
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
		if shape == "head":
			_hat_fits[model] = hat_fit(verts)
	root.free()
	_cache[model] = out
	return out


## Where a hat's band goes round this head: the middle of the head a little above the brow, and how
## wide and deep the head is there and anywhere above it (the crown has to clear it all).
static func hat_fit(head: PackedVector3Array) -> Dictionary:
	var band_y := EYE_HEIGHT + BAND_ABOVE_EYES
	var lo := Vector3(INF, 0.0, INF)
	var hi := Vector3(-INF, 0.0, -INF)
	for p in head:
		if p.y >= band_y - 0.005:
			lo = Vector3(minf(lo.x, p.x), 0.0, minf(lo.z, p.z))
			hi = Vector3(maxf(hi.x, p.x), 0.0, maxf(hi.z, p.z))
	if lo.x == INF:
		return {}
	return {"band": Vector3((lo.x + hi.x) * 0.5, band_y, (lo.z + hi.z) * 0.5),
			"half_width": (hi.x - lo.x) * 0.5, "half_depth": (hi.z - lo.z) * 0.5}


## A node's transform relative to the scene root, before it's in a tree.
static func _to_root(n: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent()
	while p is Node3D and p.get_parent() != null:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t
