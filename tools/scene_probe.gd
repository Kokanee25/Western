extends SceneTree
## The scene data the visual checks need (tools/visual_checks.py; docs/briefs/review-tools.md,
## the art session's visual checks): what the pixels can't say. Loads the main scene, lets the
## street settle with its people and the gang in, then (phase "saloon") stages the saloon shot
## with its seated man and extras, and writes, for each phase:
##
##   <out>/scene_probe.json
##     "bones": the skeleton's bone names (a vertex's segment is an index into it)
##     "people": [{name, phase, pose, limp, prone, model, shapes {shape: [first, count]},
##                 feet {foot_r|foot_l: {low, ground, x, z}}, mesh: "people/<phase>_<name>.bin"}]
##     "props": [{name, kind, prop_id, anchor, origin, ground}]  (floor-standing things only)
##     "materials": [{node, shader, missing}]  (grid materials drawn with no texture)
##   <out>/people/<phase>_<name>.bin
##     float32 rows of 7: the posed vertex (x, y, z), its normal (x, y, z), its segment index;
##     every shape he wears, in "shapes" order.
##
##   godot --headless --fixed-fps 60 -s res://tools/scene_probe.gd -- --out=DIR [--phases=street,saloon] [--hour=15]
##
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

var out := "user://scene_probe"
var phases := ["street", "saloon"]
var hour := 15.0
var data := {"bones": [], "people": [], "props": [], "materials": []}
## How far below a prop's foot a surface counts as what it stands on (further: nothing under it,
## e.g. a bottle on a shelf with no collision).
const REACH := 0.6


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
		elif arg.begins_with("--phases="):
			phases = Array(arg.substr(9).split(","))
		elif arg.begins_with("--hour="):
			hour = float(arg.substr(7))
	DirAccess.make_dir_recursive_absolute(out.path_join("people"))
	var settings = root.get_node(^"Settings")
	settings.autosave = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var street: Node3D = main.find_child("TestStreet", true, false)
	var clock = street.get_node(^"DayCycle")
	var player = street.get_node(^"Player")
	clock.set_time(hour)
	clock.set_physics_process(false)
	player.input_enabled = false
	var town = main.find_child("TownLife", true, false)
	if "street" in phases:
		if town:
			town.bring_gang()
		for i in 240:
			await physics_frame
		_probe(street, "street", [])
	if "saloon" in phases:
		var before: Array = _people(street)
		if town:
			town.gang_arrives = 1e9
		var sm = load("res://src/art/shot_match.gd")
		sm.stage(street)
		for i in 60:
			await physics_frame
		_probe(street, "saloon", before)
	_materials(street)
	var f := FileAccess.open(out.path_join("scene_probe.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(data, " "))
	f.close()
	print("scene probe: %d people, %d props, %d grid materials without a texture -> %s"
			% [data.people.size(), data.props.size(), data.materials.size(), out])
	quit()


func _people(street: Node) -> Array:
	var found: Array = []
	for n in street.find_children("*", "Node3D", true, false):
		if n.get_script() and String(n.get_script().resource_path).ends_with("human_body.gd") and n.is_inside_tree():
			found.append(n)
	return found


func _probe(street: Node3D, phase: String, skip: Array) -> void:
	var space := street.get_world_3d().direct_space_state
	for man in _people(street):
		if man in skip or man.skeleton == null:
			continue
		_person(man, phase, space)
	if phase == "street":
		_props(street, space)


## One man: every shape he wears posed by his skeleton (CPU skinning, the same sum the GPU does),
## and where his soles are against what's under them.
func _person(man, phase: String, space: PhysicsDirectSpaceState3D) -> void:
	var sk: Skeleton3D = man.skeleton
	if data.bones.is_empty():
		for b in sk.get_bone_count():
			data.bones.append(sk.get_bone_name(b))
	var mats: Array[Transform3D] = []
	for b in sk.get_bone_count():
		mats.append(sk.global_transform * sk.get_bone_pose(b) * sk.get_bone_rest(b).affine_inverse())
	var by_shape := {}
	for key: String in man.skin_meshes:
		(by_shape.get_or_add(key.get_slice("/", 0), []) as Array).append(man.skin_meshes[key])
	var rows := PackedFloat32Array()
	var shapes := {}
	var low := {"foot_r": INF, "foot_l": INF}
	var low_at := {"foot_r": Vector3.ZERO, "foot_l": Vector3.ZERO}
	var foot_r := sk.find_bone("foot_r")
	var foot_l := sk.find_bone("foot_l")
	for shape: String in by_shape:
		if not _worn(man, shape, by_shape[shape]):
			continue
		var first := rows.size() / 7
		for mi: MeshInstance3D in by_shape[shape]:
			var mesh := mi.mesh as ArrayMesh
			if mesh == null:
				continue
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES] if arr[Mesh.ARRAY_BONES] != null else PackedInt32Array()
				var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS] if arr[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
				var per := bones.size() / maxi(verts.size(), 1) if bones.size() > 0 else 0
				for i in verts.size():
					var p := Vector3.ZERO
					var n := Vector3.ZERO
					var best_w := -1.0
					var best_b := 0
					if per > 0:
						for k in per:
							var w := weights[i * per + k]
							if w <= 0.0:
								continue
							var b := bones[i * per + k]
							p += mats[b] * verts[i] * w
							if norms.size() > i:
								n += (mats[b].basis * norms[i]) * w
							if w > best_w:
								best_w = w
								best_b = b
					else:
						p = mi.global_transform * verts[i]
						if norms.size() > i:
							n = mi.global_transform.basis * norms[i]
					n = n.normalized()
					rows.append_array([p.x, p.y, p.z, n.x, n.y, n.z, float(best_b)])
					if (shape == "boots" or shape == "skin") and (best_b == foot_r or best_b == foot_l):
						var side := "foot_r" if best_b == foot_r else "foot_l"
						if p.y < low[side]:
							low[side] = p.y
							low_at[side] = p
		shapes[shape] = [first, rows.size() / 7 - first]
	var name := String(man.name).to_snake_case()
	var file := "people/%s_%s.bin" % [phase, name]
	var f := FileAccess.open(out.path_join(file), FileAccess.WRITE)
	f.store_buffer(rows.to_byte_array())
	f.close()
	var feet := {}
	var exclude: Array[RID] = []
	for part in man.parts.values():
		if part is CollisionObject3D:
			exclude.append((part as CollisionObject3D).get_rid())
	for side: String in low:
		if low[side] == INF:
			continue
		var at: Vector3 = low_at[side]
		var q := PhysicsRayQueryParameters3D.create(Vector3(at.x, at.y + 0.6, at.z), Vector3(at.x, at.y - 1.5, at.z), 1)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		feet[side] = {"low": low[side], "ground": hit.position.y if hit else null, "x": at.x, "z": at.z}
	data.people.append({"name": name, "phase": phase, "pose": String(man.pose), "limp": man.limp, "prone": man.prone,
			"model": String(man.body_model), "shapes": shapes, "feet": feet, "mesh": file})


## A shape counts if any of its meshes is drawn (the whole-man mesh or its pieces); a knocked-off
## hat's worn pieces are hidden.
func _worn(man, shape: String, pieces: Array) -> bool:
	if man._merged.has(shape):
		return (man._merged[shape] as MeshInstance3D).visible
	for mi: MeshInstance3D in pieces:
		if mi.visible:
			return true
	return false


## Floor-standing things: PropLibrary props anchored to the floor (their origin is their foot) and
## the street's dressing models (StreetDressing._model: origin at the ground). Each with the
## height of whatever is under its foot, found by a ray that ignores the thing itself.
func _props(street: Node3D, space: PhysicsDirectSpaceState3D) -> void:
	for body in street.find_children("*", "StaticBody3D", true, false):
		var kind := ""
		var anchor := "floor"
		var id := ""
		if body.has_meta(&"prop_id"):
			id = String(body.get_meta(&"prop_id"))
			var def: Dictionary = load("res://src/props/prop_library.gd").definition(StringName(id))
			anchor = def.get("anchor", "floor")
			kind = "prop"
		elif body.get_parent() and body.get_parent().get_script() \
				and String(body.get_parent().get_script().resource_path).ends_with("street_dressing.gd") \
				and body.get_node_or_null(^"Model") != null:
			kind = "dressing"
		if kind == "" or anchor != "floor" or not body.is_visible_in_tree():
			continue
		var o: Vector3 = body.global_position
		# Five rays across its footprint (the middle and four points inside its box), the highest
		# surface wins: one ray down the middle falls through the gap between two boards, or
		# between the two bales a third is stacked across.
		var size := Vector3(0.2, 0.2, 0.2)
		for c in body.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
				size = ((c as CollisionShape3D).shape as BoxShape3D).size
				break
		var ground: Variant = null
		for off in [Vector2.ZERO, Vector2(0.3, 0.3), Vector2(-0.3, 0.3), Vector2(0.3, -0.3), Vector2(-0.3, -0.3)]:
			var at: Vector3 = o + body.global_basis * Vector3(off.x * size.x, 0.0, off.y * size.z)
			var q := PhysicsRayQueryParameters3D.create(at + Vector3(0, 0.3, 0), at + Vector3(0, -REACH, 0), 1)
			q.exclude = [body.get_rid()]
			var hit := space.intersect_ray(q)
			if hit and (ground == null or hit.position.y > ground):
				ground = hit.position.y
		var name := "%s %s at (%.1f, %.1f, %.1f)" % [kind, id if id != "" else String(body.name).rstrip("0123456789@").trim_prefix("@StaticBody3D"), o.x, o.y, o.z]
		if id == "" and body.get_node_or_null(^"Model") and body.get_node(^"Model").get_child_count() > 0:
			name = "%s %s at (%.1f, %.1f, %.1f)" % [kind, body.get_meta(&"model_name", "model"), o.x, o.y, o.z]
		data.props.append({"name": name, "kind": kind, "prop_id": id, "anchor": anchor, "origin": [o.x, o.y, o.z], "ground": ground})


## Grid materials drawn with no texture (a lost factory texture shows as plain white).
func _materials(street: Node3D) -> void:
	for mi in street.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).is_visible_in_tree():
			continue
		var mats: Array = [(mi as MeshInstance3D).material_override]
		if (mi as MeshInstance3D).mesh:
			for s in (mi as MeshInstance3D).mesh.get_surface_count():
				mats.append((mi as MeshInstance3D).get_active_material(s))
		for m in mats:
			var sm := m as ShaderMaterial
			if sm == null or sm.shader == null:
				continue
			var path := sm.shader.resource_path
			if not (path.ends_with("texel_grid.gdshader") or path.ends_with("member_holes.gdshader")):
				continue
			if sm.get_shader_parameter(&"albedo_tex") == null:
				data.materials.append({"node": String(mi.get_path()).get_slice("TestStreet/", 1), "shader": path.get_file(), "missing": "albedo_tex"})
				break
