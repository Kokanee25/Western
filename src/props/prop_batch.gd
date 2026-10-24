class_name PropBatch
extends Node3D
## Kit props at rest drawn together (docs/briefs/props-scale.md): each KitProp draws its untouched
## members as one mesh a material (Structure's batches), its dress and a far-lamp shadow, so three
## draws a prop, each again in every shadow pass; a cluttered street is hundreds. Here the resting
## props in each patch of town (CELL) are one mesh a material and one shadow, joined from their own
## batches. The moment anything happens to a prop (a member unbatched: a hole, heat, breaking,
## going loose; it's moved, hidden or freed) it `leave`s: its stretch of the cell's mesh is zeroed
## in place (non-indexed, so its triangles collapse to a point: no rebuild, no hitch) and its own
## batches show again. A cell is built again only when a prop joins it.
##
## Only materials that look the same in any mesh's space are joined: the texel grid's UV and world
## mappings, the weathering layer only where the mesh doesn't carry it (CUSTOM0/1, read in the
## mesh's space); anything else stays the prop's own. The Compatibility renderer picks each object's lights from a short list,
## so a cell spanning a room would be lit differently: there it isn't used (as StaticBatch).

## Patches of town (m): each cell's meshes are culled as one.
const CELL := 20.0
const TEXEL_SHADERS := ["res://src/render/texel_grid.gdshader", "res://src/render/texel_grid_blocks.gdshader"]

## Vector3i -> {key -> MeshInstance3D}
var _cells := {}
## KitProp -> {"cell": Vector3i, "parts": [[key, Mesh (non-indexed), Transform3D, its own MeshInstance3D]], "gone"}
var _props := {}
## Vector3i -> {key -> [KitProp, first vertex, count] in mesh order}
var _ranges := {}
var _dirty := {}
var _in_cell := {}  # Vector3i -> how many props in it
var _queued := false
## key -> [material or null (the shadow), cast_shadow, layers]
var _keys := {}

## Off (`-- --no-prop-batch`: the bench's before): every prop draws its own.
static var enabled := not "--no-prop-batch" in OS.get_cmdline_user_args()


## The batch for `prop`'s world: a child of the topmost Node3D above it (the street), made the
## first time. Null where it isn't used.
static func for_prop(prop: Node3D) -> PropBatch:
	if not enabled or RenderingServer.get_current_rendering_method() == "gl_compatibility":
		return null
	var top: Node3D = null
	var n := prop.get_parent()
	while n is Node3D:
		top = n
		n = n.get_parent()
	if top == null:
		return null
	var b := top.get_node_or_null(^"PropBatch") as PropBatch
	if b == null:
		b = PropBatch.new()
		b.name = "PropBatch"
		top.add_child(b)
	return b


## Join a prop at rest: its own batches hidden, its meshes in its cell's (built at the end of the
## frame, with every other prop joining).
func join(prop: KitProp) -> void:
	if _props.has(prop) or not prop.is_inside_tree():
		return
	var parts := []
	var inv := global_transform.affine_inverse()
	for mi: MeshInstance3D in prop.batch_nodes():
		if not mi.mesh is ArrayMesh or not mi.visible or mi.mesh.get_surface_count() == 0:
			continue
		var shadow := mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		var mat := mi.material_override
		if not shadow and not joins(mat, mi.mesh):
			continue
		var key := "%d|%d|%d" % [0 if shadow else mat.get_instance_id(), mi.cast_shadow, mi.layers]
		if not _keys.has(key):
			_keys[key] = [null if shadow else mat, mi.cast_shadow, mi.layers]
		parts.append([key, _flat(mi.mesh), inv * mi.global_transform, mi])
	if parts.is_empty():
		return
	for p: Array in parts:
		(p[3] as MeshInstance3D).visible = false
	var cell := Vector3i((prop.global_position / CELL).floor())
	var gone := leave.bind(prop)
	_props[prop] = {"cell": cell, "parts": parts, "gone": gone}
	_in_cell[cell] = int(_in_cell.get(cell, 0)) + 1
	prop.tree_exiting.connect(gone, CONNECT_ONE_SHOT)
	_dirty[cell] = true
	if not _queued:
		_queued = true
		_rebuild.call_deferred()


## The prop's own batches again, and its stretch of its cell's meshes gone (now).
func leave(prop: KitProp) -> void:
	var e: Dictionary = _props.get(prop, {})
	if e.is_empty():
		return
	_props.erase(prop)
	if prop.tree_exiting.is_connected(e.gone):
		prop.tree_exiting.disconnect(e.gone)
	for p: Array in e.parts:
		if is_instance_valid(p[3]):
			(p[3] as MeshInstance3D).visible = true
	var cell: Vector3i = e.cell
	_in_cell[cell] = int(_in_cell.get(cell, 1)) - 1
	if _in_cell[cell] <= 0:
		_in_cell.erase(cell)
	if _dirty.has(cell):
		return  # not built yet: it's built without it
	if not _in_cell.has(cell):
		# The last of the cell's: nothing left to draw there.
		for mi: Variant in (_cells.get(cell, {}) as Dictionary).values():
			if is_instance_valid(mi):
				(mi as Node).queue_free()
		_cells.erase(cell)
		_ranges.erase(cell)
		return
	var ranges: Dictionary = _ranges.get(cell, {})
	for key: String in ranges:
		var mi: MeshInstance3D = (_cells.get(cell, {}) as Dictionary).get(key)
		var mesh := mi.mesh as ArrayMesh if mi else null
		if mesh == null:
			continue
		var stride := RenderingServer.mesh_surface_get_format_vertex_stride(mesh.surface_get_format(0), mesh.surface_get_array_len(0))
		for r: Array in ranges[key]:
			if r[0] == prop:
				var zeros := PackedByteArray()
				zeros.resize(int(r[2]) * stride)
				RenderingServer.mesh_surface_update_vertex_region(mesh.get_rid(), 0, int(r[1]) * stride, zeros)


func has(prop: KitProp) -> bool:
	return _props.has(prop)


func prop_count() -> int:
	return _props.size()


## How many meshes it draws (tests, the bench).
func mesh_count() -> int:
	var n := 0
	for cell: Vector3i in _cells:
		n += (_cells[cell] as Dictionary).size()
	return n


## Joined in a cell's mesh: the texel grid's UV and world mappings (weathered only where the mesh
## carries no CUSTOM0: the stains are laid in the mesh's space), or a plain opaque material not
## mapped in its mesh's space.
static func joins(mat: Material, mesh: ArrayMesh) -> bool:
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		if sm.shader == null or not sm.shader.resource_path in TEXEL_SHADERS:
			return false
		if sm.get_shader_parameter(&"use_weather") == true and mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_CUSTOM0:
			return false
		return sm.get_shader_parameter(&"mapping") != PixelArt.Mapping.TRIPLANAR
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		return bm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not (bm.uv1_triplanar and not bm.uv1_world_triplanar)
	return false


## The mesh's first surface without its index (each triangle its own three vertices), so a prop's
## stretch of a cell's mesh is contiguous and can be zeroed.
static func _flat(mesh: ArrayMesh) -> ArrayMesh:
	if mesh.surface_get_array_index_len(0) <= 0:
		return mesh
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.deindex()
	return st.commit()


func _rebuild() -> void:
	_queued = false
	for cell: Vector3i in _dirty:
		_build(cell)
	_dirty.clear()


func _build(cell: Vector3i) -> void:
	var tools := {}  # key -> SurfaceTool
	var ranges := {}
	var counts := {}
	for prop: Variant in _props:
		var e: Dictionary = _props[prop]
		if e.cell != cell or not is_instance_valid(prop):
			continue
		for p: Array in e.parts:
			var key: String = p[0]
			var mesh: ArrayMesh = p[1]
			var st: SurfaceTool = tools.get(key)
			if st == null:
				st = SurfaceTool.new()
				tools[key] = st
			var n := mesh.surface_get_array_len(0)
			st.append_from(mesh, 0, p[2])
			ranges.get_or_add(key, []).append([prop, int(counts.get(key, 0)), n])
			counts[key] = int(counts.get(key, 0)) + n
	var old: Dictionary = _cells.get(cell, {})
	for key: String in old:
		if not tools.has(key) and is_instance_valid(old[key]):
			(old[key] as Node).queue_free()
	var now := {}
	for key: String in tools:
		var mi: MeshInstance3D = old.get(key)
		if mi == null or not is_instance_valid(mi):
			mi = MeshInstance3D.new()
			mi.name = "Cell"
			var k: Array = _keys[key]
			mi.material_override = k[0]
			mi.cast_shadow = k[1]
			mi.layers = k[2]
			add_child(mi)
		mi.mesh = (tools[key] as SurfaceTool).commit()
		now[key] = mi
	if now.is_empty():
		_cells.erase(cell)
		_ranges.erase(cell)
	else:
		_cells[cell] = now
		_ranges[cell] = ranges
