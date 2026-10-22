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
## His painted textures (tools/paint_bake.gd + tools/paint/finish.py, or
## rodin_portrait_build.write_painted): per shape, the texture <id>_paint_<shape>.png and the rect
## of the shape's UVs it covers; and his own `look` (the painted mode's values), if he has one.
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
	var whole := _is_whole(model)
	if whole:
		shapes.clear()
	# A man with his own tie doesn't also wear the old lofted bandana (it floats off his neck).
	if generated.has("cravat"):
		shapes.erase("bandana")
	var textures := {}
	for k: String in generated:
		if k == "fingers":
			continue
		# His bandanas (tools/faces/bandana.py): the one over his face when he's masked, else the one
		# at his neck if he wears a bandana; never both.
		if k == "bandana_mask" and not outfit.get("mask", false):
			continue
		if k == "bandana" and (outfit.get("mask", false) or not outfit.get("bandana", false)):
			continue
		# His own hat's brim and band go with his hat: a man not wearing one wears neither.
		if k in ["hat_brim", "hat_band"] and not shapes.has("hat") and not whole:
			continue
		# His own skin and head always; a garment only if this outfit has it (a man without a coat
		# on doesn't get the model's coat), and anything BodyMesh doesn't make (the tie). A whole
		# man wears every piece his model came with (his own coat and hat, fitted as pieces).
		if k in ["skin", "head"] or shapes.has(k) or not k in OUTFIT_KEYS or whole:
			shapes[k] = generated[k]
			var png := TEXTURE_PATH % [_textures_of(model, k), k]
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
	var out := {"bones": data.bones, "rests": data.rests, "shapes": shapes, "model": model, "textures": textures,
			"whole": whole}
	# His own fingers, a mesh a finger bone (HumanBody._own_fingers), if he was fitted with them.
	if generated.has("fingers"):
		out["fingers"] = generated.fingers
	# Painted from the painting: per shape, a texture, the UV rect it covers and how many texels a
	# side make one of its squares (the face: three, so its eyes can be drawn finer).
	var paint := {}
	var paint_squares := {}
	if FileAccess.file_exists(PAINT_PATH % model):
		var p: Variant = JSON.parse_string(FileAccess.get_file_as_string(PAINT_PATH % model))
		if p is Dictionary:
			# His own painted look (the painted mode's values), over HumanBody.paint_look's.
			var own := {}
			for k: String in ((p as Dictionary).get("look", {}) as Dictionary):
				own[StringName(k)] = float(p.look[k])
			out["paint_look"] = own
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
	var info := report(model)
	# His skinned hands' finger bones (tools/blender/fit_tripo.py skinned_hands): each one's rest.
	if info.has("finger_bones"):
		out["finger_bones"] = info.finger_bones
		out["finger_bone_names"] = finger_bone_names()
	if info.has("skin_tone"):
		var t: Array = info.skin_tone
		out["skin_tone"] = Color(t[0], t[1], t[2])
	return out


## Whose texture a shape wears: his own, or (a copy made by tools/faces/talking_face.py, whose
## report says "textures_from") the man he was copied from, for what the copy didn't change.
static func _textures_of(model: StringName, shape: String) -> StringName:
	if ResourceLoader.exists(TEXTURE_PATH % [model, shape]):
		return model
	return StringName(report(model).get("textures_from", model))


## Whether the model comes dressed (his report says "whole": clothes, hat and all in his skin).
static func _is_whole(model: StringName) -> bool:
	return bool(report(model).get("whole", false))


## The model's report (assets/people/<model>.json: "whole", "eyes", "eye_gain", ...), or {}.
static func report(model: StringName) -> Dictionary:
	var path := REPORT_PATH % model
	if not FileAccess.file_exists(path):
		return {}
	var info: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return info if info is Dictionary else {}


## The generated shapes ("skin", "head"), cut into pieces per bone. Cached per model and bone
## order (an anatomy not loaded, `Anatomy.new()`, has none: its pieces all land on bone 0, and
## cached by model alone they were every later man's: his head skinned to his pelvis).
static func _load(anatomy: Anatomy, model: StringName) -> Dictionary:
	var order := anatomy.segment_order()
	var key := "%s|%d" % [model, hash(order)]
	if _cache.has(key):
		return _cache[key]
	var scene := load(PATH % model) as PackedScene
	var out := {}
	if scene == null:
		_cache[key] = out
		return out
	var root := scene.instantiate()
	var index := {}
	for i in order.size():
		index[order[i]] = i
	# A skinned hand's finger bones come after the anatomy's (HumanBody adds them to its skeleton
	# in this order) and are cut into their hand's piece.
	var piece_of := {}
	var names := finger_bone_names()
	for k in names.size():
		index[StringName(names[k])] = order.size() + k
		piece_of[order.size() + k] = index.get(StringName("hand_" + String(names[k]).split("_")[2]), 0)
	var centres := {}
	for i in order.size():
		centres[i] = anatomy.segment_center(order[i])
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var shape := String(mi.name).to_lower().trim_prefix("body_").trim_prefix("cloth_")
		if mi.mesh == null:
			continue
		if shape.begins_with("finger_"):
			_own_finger(out, shape, mi)
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
		# His face's expressions (tools/faces/talking_face.py), carried into his pieces: each the
		# whole mesh's vertices in that expression.
		var blends := {}
		var am := mi.mesh as ArrayMesh
		if am != null and am.get_blend_shape_count() > 0:
			var bs := am.surface_get_blend_shape_arrays(0)
			for k in am.get_blend_shape_count():
				var bv: PackedVector3Array = (bs[k] as Array)[Mesh.ARRAY_VERTEX]
				for i in bv.size():
					bv[i] = xf * bv[i]
				blends[am.get_blend_shape_name(k)] = bv
		out[shape] = BodyMesh.split_pieces(verts, normals, uvs, bones, weights, tris, centres, piece_of, blends)
		if shape == "head":
			_hat_fits[model] = hat_fit(verts)
	root.free()
	_cache[key] = out
	return out


## A skinned hand's finger bones, in the order the skeleton has them after the anatomy's: right
## hand then left, thumb to little finger, knuckle out (tools/blender/mh_hand.py finger_bone_names).
static func finger_bone_names() -> Array:
	var out := []
	for side in ["r", "l"]:
		for f in ["thumb", "index", "middle", "ring", "little"]:
			for b in 3:
				out.append("finger_%s_%s_%d" % [f, side, b])
	return out


## One bone's piece of his own finger (tools/blender/fit_tripo.py own_fingers: a plain mesh in the
## rest pose named finger_<finger>_<side>_<bone>), into out.fingers[finger id][bone] for
## HumanBody to hang on that finger bone.
static func _own_finger(out: Dictionary, shape: String, mi: MeshInstance3D) -> void:
	var parts := shape.trim_prefix("finger_").rsplit("_", true, 1)
	if parts.size() != 2 or not parts[1].is_valid_int():
		return
	var xf := mi.global_transform if mi.is_inside_tree() else _to_root(mi)
	var src := mi.mesh.surface_get_arrays(0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] = xf * verts[i]
	var normals: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	for i in normals.size():
		normals[i] = (xf.basis * normals[i]).normalized()
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = src[Mesh.ARRAY_TEX_UV]
	arrays[Mesh.ARRAY_INDEX] = src[Mesh.ARRAY_INDEX]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var fingers: Dictionary = out.get_or_add("fingers", {})
	var bones: Array = fingers.get_or_add(parts[0], [null, null, null])
	var b := int(parts[1])
	if b >= 0 and b < bones.size():
		bones[b] = mesh


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
