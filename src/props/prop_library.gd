class_name PropLibrary
## Loose props (bottles, chairs, lamps...) described in assets/props/manifest.json. A prop uses
## assets/props/<id>.glb when that model exists (made in Meshy or anywhere else), scaled to the
## manifest's real-world size; else a model built in code (PropModels); else a coloured placeholder
## box of that size. Either way it gets a collision box, so the room plays the same before and after
## the art arrives.

const MANIFEST_PATH := "res://assets/props/manifest.json"
const MODEL_PATH := "res://assets/props/%s.glb"

static var _manifest := {}
## Build props with PropModels' code models where there's no .glb (off: the coloured boxes, as
## before, for tests and comparisons).
static var use_models := true
## How many of each prop have been made: the next one's variant (bottles' glass and labels...).
static var _made := {}


static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var text := FileAccess.get_file_as_string(MANIFEST_PATH)
		var parsed: Variant = JSON.parse_string(text)
		_manifest = parsed if parsed is Dictionary else {"props": {}}
	return _manifest


static func ids() -> Array:
	return manifest().get("props", {}).keys()


static func definition(id: StringName) -> Dictionary:
	return manifest().get("props", {}).get(String(id), {})


static func size_of(id: StringName) -> Vector3:
	var s: Array = definition(id).get("size", [0.3, 0.3, 0.3])
	return Vector3(s[0], s[1], s[2])


static func has_model(id: StringName) -> bool:
	return ResourceLoader.exists(MODEL_PATH % id)


## Make a prop. Its origin is the bottom centre ("floor" props) or the back centre ("wall" props,
## which face +Z away from the wall), so a slot transform puts it straight in place. `model`
## overrides the .glb lookup (tests use it).
static func spawn(id: StringName, model: Node3D = null) -> StaticBody3D:
	var def := definition(id)
	assert(not def.is_empty(), "Unknown prop %s" % id)
	var target := size_of(id)
	var body := StaticBody3D.new()
	body.name = String(id).to_pascal_case()
	body.set_meta(&"prop_id", id)
	var visual: Node3D
	var bounds: AABB
	if model == null and has_model(id):
		model = (load(MODEL_PATH % id) as PackedScene).instantiate()
	elif model == null and use_models and PropModels.has_model(id):
		var n: int = _made.get(id, 0)
		_made[id] = n + 1
		model = PropModels.build(id, n)
	if model:
		visual = model
		var raw := _model_bounds(visual)
		var s := target.y / maxf(raw.size.y, 0.0001)
		visual.scale = Vector3.ONE * s
		bounds = AABB(raw.position * s, raw.size * s)
		body.set_meta(&"placeholder", false)
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = target
		mi.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(def.get("color", "#808080"))
		mat.roughness = 0.8
		mi.material_override = mat
		visual = mi
		bounds = AABB(-target * 0.5, target)
		body.set_meta(&"placeholder", true)
	# Move the model so its anchor point sits at the body's origin.
	var anchor := Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z)
	if def.get("anchor", "floor") == "wall":
		anchor = Vector3(bounds.get_center().x, bounds.get_center().y, bounds.position.z)
	visual.position -= anchor
	body.add_child(visual)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = bounds.size
	shape.shape = box_shape
	shape.position = bounds.get_center() - anchor
	body.add_child(shape)
	body.set_meta(&"bounds", AABB(bounds.position - anchor, bounds.size))
	return body


## The size the prop actually ended up (after scaling), in its own space.
static func bounds_of(prop: Node3D) -> AABB:
	return prop.get_meta(&"bounds", AABB())


## Bounds of every mesh under `root`, in root's space (root not yet in the tree).
static func _model_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != root and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var box := xf * mi.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result
