class_name StaticBatch
extends Node3D
## Draws the town's fixed dressing (props, furniture, the street's barrels and crates...) with one
## draw call per mesh and material in each patch of town, not one per part: a chair is a dozen
## parts, the saloon alone ~850, each drawn again for every shadow cascade. Each kind of mesh goes
## into a MultiMesh at its own place, so it renders exactly as before (each instance keeps its own
## model matrix: textures mapped in mesh space stay put). The originals stay, hidden, with their
## collision.
##
## Only what never changes once built is taken: meshes under the dressing and props (no script on
## the way up but the buildings' and dressing's own, no physics body but a static one), opaque,
## not skinned. Not the buildings' members or their batches (they break and burn), lamps (they're
## shot out), people, guns or anything loose. A batched mesh that leaves the tree (freed, as the
## shot match clears the table) stops being drawn; anything that's going to move or hide dressing
## calls `release()` on it first.

## Scripts that may be on the way up from a batched mesh (they build fixed things and leave them).
const OWNERS := [&"StreetDressing", &"StreetScenery", &"SaloonBuilding", &"FalseFrontBuilding",
		&"SaloonDressing", &"Structure"]
## Shaders known to be opaque and to read nothing per node but the model matrix.
const SHADERS := ["res://src/render/texel_grid.gdshader", "res://src/render/texel_grid_blocks.gdshader"]
## Patches of town (m): each batch covers one, so what's off screen is still culled.
const CELL := 40.0

## The root batched (the parent, by default).
@export var target: NodePath = ^".."
## MultiMeshInstance3D -> [the MeshInstance3Ds it draws, in instance order]
var batches := {}
var _of := {}  # MeshInstance3D -> [MultiMeshInstance3D, index]


func _ready() -> void:
	# The Compatibility renderer (the web build) picks each object's lights from a short list (8),
	# so a batch spanning a room is lit by different lamps than its parts were: left as it was.
	# Forward+ lights by clusters, so there it draws the same.
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return
	# After the dressing has built itself (some of it in its own _ready, some deferred).
	await get_tree().process_frame
	await get_tree().process_frame
	var root := get_node_or_null(target) as Node3D
	if root:
		build(root)


## Batch what can be batched under `root`. Returns how many meshes were taken.
func build(root: Node3D) -> int:
	var groups := {}  # key -> [mesh, material, cast_shadow, layers, [MeshInstance3D...]]
	var by_content := {}  # content -> Mesh (the same mesh built twice is one kind)
	var content_of := {}  # Mesh -> content
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if _of.has(mi) or not _takes(mi, root):
			continue
		var h: String = content_of.get(mi.mesh, "")
		if h == "":
			h = _content(mi.mesh)
			content_of[mi.mesh] = h
		var mesh: Mesh = by_content.get_or_add(h, mi.mesh)
		var at := mi.global_position
		var cell := Vector3i((at / CELL).floor())
		var key := "%s|%d|%d|%d|%s" % [h, mi.material_override.get_instance_id() if mi.material_override else 0,
				mi.cast_shadow, mi.layers, cell]
		var g: Array = groups.get_or_add(key, [mesh, mi.material_override, mi.cast_shadow, mi.layers, []])
		(g[4] as Array).append(mi)
	var taken := 0
	var inv := global_transform.affine_inverse()
	for key: String in groups:
		var g: Array = groups[key]
		var list: Array = g[4]
		if list.size() < 2:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = g[0]
		mm.instance_count = list.size()
		for i in list.size():
			mm.set_instance_transform(i, inv * (list[i] as MeshInstance3D).global_transform)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Batch%d" % batches.size()
		mmi.multimesh = mm
		mmi.material_override = g[1]
		mmi.cast_shadow = g[2]
		mmi.layers = g[3]
		add_child(mmi)
		batches[mmi] = list
		for i in list.size():
			var mi: MeshInstance3D = list[i]
			mi.visible = false
			_of[mi] = [mmi, i]
			mi.tree_exiting.connect(_gone.bind(mi), CONNECT_ONE_SHOT)
		taken += list.size()
	return taken


## Everything under `node` drawn by itself again (before moving or hiding it).
func release(node: Node) -> void:
	for mi: MeshInstance3D in _of.keys():
		if mi == node or node.is_ancestor_of(mi):
			if mi.tree_exiting.is_connected(_gone):
				mi.tree_exiting.disconnect(_gone)
			_hide_instance(mi)
			mi.visible = true


## The batches anywhere in `tree` (there's one, in the test street).
static func release_in(tree: SceneTree, node: Node) -> void:
	for b in tree.get_nodes_in_group(&"static_batch"):
		(b as StaticBatch).release(node)


func _enter_tree() -> void:
	add_to_group(&"static_batch")


func _gone(mi: MeshInstance3D) -> void:
	_hide_instance(mi)


func _hide_instance(mi: MeshInstance3D) -> void:
	var where: Array = _of.get(mi, [])
	_of.erase(mi)
	if where.is_empty() or not is_instance_valid(where[0]):
		return
	var mmi: MultiMeshInstance3D = where[0]
	mmi.multimesh.set_instance_transform(where[1], Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))


func _takes(mi: MeshInstance3D, root: Node3D) -> bool:
	if mi.mesh == null or not mi.is_visible_in_tree() or mi.get_script() != null or mi.skin != null \
			or mi.transparency > 0.0 or mi.material_overlay != null or mi.visibility_range_end > 0.0 \
			or mi.visibility_range_begin > 0.0:
		return false
	for s in mi.get_surface_override_material_count():
		if mi.get_surface_override_material(s) != null:
			return false
	var mat := mi.material_override
	if mat == null:
		return false
	if mat is ShaderMaterial:
		var sh := (mat as ShaderMaterial).shader
		if sh == null or not sh.resource_path in SHADERS:
			return false
	elif mat is BaseMaterial3D:
		if (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return false
	else:
		return false
	var parent := mi.get_parent()
	if parent is Structure or parent is StructureMember:
		return false  # a building's batches and signs: they change as it breaks
	var n := parent
	while n != null and n != root:
		if n is PhysicsBody3D and not n is StaticBody3D:
			return false
		var s: Script = n.get_script()
		if s != null and not s.get_global_name() in OWNERS:
			return false
		n = n.get_parent()
	return n == root


## The same mesh built twice (each chair builds its own legs) counts as one kind.
static func _content(mesh: Mesh) -> String:
	if not mesh is ArrayMesh:
		return "%s:%d" % [mesh.get_class(), hash(var_to_str(mesh))]
	var bytes := PackedByteArray()
	var verts := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		verts += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		bytes.append_array(var_to_bytes(a))
		var m := mesh.surface_get_material(s)
		bytes.append_array(var_to_bytes(m.get_instance_id() if m else 0))
	return "%d:%d:%d:%s" % [hash(bytes), bytes.size(), verts, mesh.get_aabb()]
