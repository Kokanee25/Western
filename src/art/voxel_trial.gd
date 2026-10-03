class_name VoxelTrial
## The voxel trial (docs/screenshots/voxel_trial/, 2026-10-03): do blocky outlines get us closer
## to the concept paintings? Behind flags, nothing changes by default.
##   A, `props`: the saloon shot's mug, lamp (foot, collar, prongs; the glass chimney stays
##      smooth), bottle and ashtray, and the seated man's hat, swapped for cube-built copies
##      (tools/voxel_export.gd, tools/blender/voxelise.py: assets/props/voxel/<prop>_<cubes>.glb,
##      assets/people/voxel/<id>_hat_<cubes>.glb + .png). Each part keeps its own material, mapped
##      by position (triplanar), so every cube face shows the texel under it and is lit tile by
##      tile like everything else: only the shape changes.
##   B, `eyes`: smooth eyeballs in his sockets (white, a dark iris looking at you, wet so the
##      table lamp glints), the head texture's lids and brows drawn over their edges.
## tools/screenshots.gd --voxel=props,hat,eyes|all [--cubes=64].

static var props := false
static var hat := false
static var eyes := false
static var cubes := 128

const PROP_PATH := "res://assets/props/voxel/%s_%d.glb"
const HAT_PATH := "res://assets/people/voxel/%s_hat_%d.glb"
const HAT_TEXTURE := "res://assets/people/voxel/%s_hat_%d.png"
## The hat: the head above the brim's underside (tools/blender/voxelise.py HAT_FROM, body space).
const HAT_FROM := 1.778
## The eyeball: radius, how far its centre sits behind the skin, and the iris.
const EYE_RADIUS := 0.0125
const EYE_SUNK := 0.0065
const IRIS_RADIUS := 0.0058
## Where a model's painted irises are on his face (body space x and y, right then left; the
## skin's depth there is read off the mesh). Measured on the head texture: the dark of the iris
## on the front of the mesh (tools/blender/voxelise.py's load_glb and a profile by height). A
## model not here takes the anatomy's eyes. The stranger's eyes sit 9 cm above the anatomy's eye
## line (his head is Tripo's, at its own proportions) and his face a little to his left.
const EYES := {
	&"stranger": [Vector2(0.059, 1.747), Vector2(-0.021, 1.747)],
}


## The shot's props swapped for their cube-built copies: the node holding each prop (its parts in
## build order) and the glb's parts in the same order.
static func replace_props(root: Node3D, lamp_model: Node3D, man: HumanBody = null) -> void:
	_swap_parts(root.get_node_or_null(^"Cup"), "cup")
	_swap_parts(root.get_node_or_null(^"Bottle"), "bottle")
	_swap_parts(lamp_model, "lamp")
	# The cup in his hand (ShotMatch._cup_in_hand: HeldCup holds the model).
	if man != null and man.parts.has(&"hand_r"):
		var held := (man.parts[&"hand_r"] as Node3D).get_node_or_null(^"HeldCup")
		if held != null and held.get_child_count() > 0:
			_swap_parts(held.get_child(0) as Node3D, "cup")
	var ash := root.get_node_or_null(^"Ashtray") as MeshInstance3D
	if ash:
		var holder := Node3D.new()
		holder.name = "AshtrayVoxel"
		ash.add_child(holder)
		var mi := MeshInstance3D.new()
		mi.name = "Ashtray"
		mi.material_override = ash.material_override
		holder.add_child(mi)
		_swap_parts(holder, "ashtray")
		# The voxel ashtray is in the prop's own space (the cylinder's centre 12 mm up).
		holder.position = Vector3(0, -0.012, 0)
		ash.mesh = null


static func _swap_parts(prop: Node3D, name: String) -> void:
	if prop == null:
		return
	var meshes := _voxel_meshes(PROP_PATH % [name, cubes])
	if meshes.is_empty():
		push_warning("VoxelTrial: no %s" % (PROP_PATH % [name, cubes]))
		return
	var k := 0
	for mi: MeshInstance3D in prop.find_children("*", "MeshInstance3D", true, false):
		if mi.name == "Chimney":
			continue
		# A part the cutter left empty (a flat disc has no volume: the bottle's base, the mug's
		# bottom, both hidden inside) keeps its smooth mesh.
		if meshes.has(k):
			# The cubes are in the prop's space already (the part's transform was applied on export).
			mi.mesh = meshes[k]
			mi.transform = Transform3D.IDENTITY
			mi.material_override = triplanar(mi.material_override)
		k += 1


## The glb's meshes by part number (their names: p00_Foot, p01_Collar, ...).
static func _voxel_meshes(path: String) -> Dictionary:
	var out := {}
	if not ResourceLoader.exists(path):
		return out
	var scene := load(path) as PackedScene
	if scene == null:
		return out
	var inst := scene.instantiate()
	for mi: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		var name := String(mi.name)
		if name.begins_with("p") and name.length() > 3 and name.substr(1, 2).is_valid_int():
			out[name.substr(1, 2).to_int()] = mi.mesh
		else:
			out[out.size()] = mi.mesh
	inst.free()
	return out


## The same grid material, mapped by position (the cubes have no UVs).
static func triplanar(m: Material) -> Material:
	if m is ShaderMaterial and (m as ShaderMaterial).get_shader_parameter(&"mapping") != null:
		var t := (m as ShaderMaterial).duplicate() as ShaderMaterial
		t.set_shader_parameter(&"mapping", PixelArt.Mapping.TRIPLANAR)
		t.set_shader_parameter(&"cube_faces", true)
		PixelArt.track(t)
		return t
	return m


## The seated man's hat as cubes: the head piece loses its hat triangles (above HAT_FROM) and the
## cube-built hat, with its own texture, hangs on the head part lit as his head is.
static func replace_hat(man: HumanBody) -> void:
	var head_piece := man.skin_meshes.get("head/head") as MeshInstance3D
	var head: Node3D = man.parts.get(&"head")
	if head_piece == null or head == null:
		push_warning("VoxelTrial: no head piece on %s (%s)" % [man.body_model, man.skin_meshes.keys()])
		return
	var path := HAT_PATH % [man.body_model, cubes]
	var meshes := _voxel_meshes(path)
	if meshes.is_empty():
		push_warning("VoxelTrial: no " + path)
		return
	var centre := man.anatomy.segment_center(&"head")
	# The head piece without its hat.
	var arrays := head_piece.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var off := _vertex_offset(arrays, centre)
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var kept := PackedInt32Array()
	for i in range(0, idx.size(), 3):
		var hat := true
		for j in 3:
			if verts[idx[i + j]].y + off.y <= HAT_FROM:
				hat = false
		if not hat:
			kept.append(idx[i])
			kept.append(idx[i + 1])
			kept.append(idx[i + 2])
	arrays[Mesh.ARRAY_INDEX] = kept
	var trimmed := ArrayMesh.new()
	# Only the custom channels' format can be handed back (the rest is inferred from the arrays).
	var custom: int = head_piece.mesh.surface_get_format(0) & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	trimmed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, custom)
	head_piece.mesh = trimmed
	var mi := MeshInstance3D.new()
	mi.name = "HatVoxel"
	mi.mesh = meshes[meshes.keys()[0]]
	mi.layers = Layers.VIS_BODY
	var base := StandardMaterial3D.new()
	base.albedo_texture = load(HAT_TEXTURE % [man.body_model, cubes])
	base.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	base.roughness = 0.95
	mi.material_override = man._piece_material(base, false)
	# The glb is in body space; the head part draws its skinned pieces from the bone's rest.
	mi.transform = _rest_inverse(man, &"head")
	head.add_child(mi)
	print("VoxelTrial: hat %s, head piece %d -> %d indices" % [path, idx.size(), kept.size()])


## Body space -> a part's space: the inverse of its bone's rest (what the skin is drawn through).
static func _rest_inverse(man: HumanBody, sid: StringName) -> Transform3D:
	if man.skeleton == null:
		return Transform3D(Basis.IDENTITY, -man.anatomy.segment_center(sid))
	var bone := man.skeleton.find_bone(String(sid))
	if bone < 0:
		return Transform3D(Basis.IDENTITY, -man.anatomy.segment_center(sid))
	return man.skeleton.get_bone_rest(bone).affine_inverse()


## Where a piece's vertices are: a skinned piece (the generated bodies: bone weights) keeps them
## in body space, a rigid one in its segment's centred space. Vertex + this = body space.
static func _vertex_offset(arrays: Array, centre: Vector3) -> Vector3:
	var bones: Variant = arrays[Mesh.ARRAY_BONES]
	if bones != null and bones.size() > 0:
		return Vector3.ZERO
	return centre


## Smooth eyeballs in his sockets, looking at `look_at` (the camera): the sphere's front pokes
## through the skin by EYE_RADIUS - EYE_SUNK, the lids round it are the head texture's.
static func add_eyes(man: HumanBody, look_at: Vector3) -> void:
	var head: Node3D = man.parts.get(&"head")
	var head_piece := man.skin_meshes.get("head/head") as MeshInstance3D
	if head == null or head_piece == null:
		push_warning("VoxelTrial: no head piece on %s (%s)" % [man.body_model, man.skin_meshes.keys()])
		return
	var centre := man.anatomy.segment_center(&"head")
	var arrays := head_piece.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var off := _vertex_offset(arrays, centre)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.88, 0.84, 0.78)
	white.roughness = 0.12
	white.metallic = 0.0
	white.metallic_specular = 0.6
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.05, 0.03)
	dark.roughness = 0.15
	dark.metallic_specular = 0.6
	var painted: Array = EYES.get(man.body_model, [])
	for n in 2:
		var sid: StringName = [&"eye_r", &"eye_l"][n]
		var eye: Dictionary = man.anatomy.structure(sid)
		if eye.is_empty():
			continue
		# The skin in front of the eye: the foremost vertex near its (x, y), in the piece's
		# vertex space.
		var at: Vector3 = (eye.a as Vector3) - off
		if painted.size() == 2:
			at = Vector3((painted[n] as Vector2).x, (painted[n] as Vector2).y, 0.0) - off
		var front := INF
		for v in verts:
			if absf(v.x - at.x) < 0.012 and absf(v.y - at.y) < 0.012 and v.z < front:
				front = v.z
		if front == INF:
			front = (eye.a as Vector3).z - off.z - (eye.radius as float)
		var skin := Vector3(at.x, at.y, front) + off
		# The ball's centre in the head part's space (its skinned pieces are drawn from the bone's
		# rest, so a point on his skin is body space through the rest's inverse).
		var c := _rest_inverse(man, &"head") * (skin + Vector3(0.0, 0.0, EYE_SUNK))
		print("VoxelTrial: %s skin at %s, ball at %s" % [sid, skin, c])
		var ball := MeshInstance3D.new()
		ball.name = "Eyeball_" + String(sid)
		var sphere := SphereMesh.new()
		sphere.radius = EYE_RADIUS
		sphere.height = EYE_RADIUS * 2.0
		sphere.radial_segments = 24
		sphere.rings = 12
		ball.mesh = sphere
		ball.material_override = white
		ball.layers = Layers.VIS_BODY
		ball.position = c
		head.add_child(ball)
		# The iris: a flattened dark sphere on the ball's front, turned to the viewer.
		var iris := MeshInstance3D.new()
		iris.name = "Iris"
		var disc := SphereMesh.new()
		disc.radius = IRIS_RADIUS
		disc.height = IRIS_RADIUS * 0.6
		disc.radial_segments = 16
		disc.rings = 8
		iris.mesh = disc
		iris.material_override = dark
		iris.layers = Layers.VIS_BODY
		ball.add_child(iris)
		var to_viewer := (head.global_transform.affine_inverse() * look_at - c).normalized()
		iris.position = to_viewer * (EYE_RADIUS - IRIS_RADIUS * 0.3 + 0.0005)
		iris.look_at_from_position(iris.position, iris.position + to_viewer, Vector3.UP)
		iris.rotate_object_local(Vector3.RIGHT, PI * 0.5)
