class_name Horse
extends Node3D
## A horse: the town's only animals (DESIGN.md §11 "Horses as creatures"), in the world as
## creatures and never as targets (§5, "No shooting animals": nothing here is for hunting).
##
## Made in Blender by script (tools/blender/horse.py, re-runnable, no paid calls) to Sean's
## pictures of him (docs/concept/horse/): a 15-hand bay sculpted to his outline and meshed, cut to
## ~2,900 triangles with a ~480-triangle far coat, painted by projecting the pictures onto him, a
## 39-bone rig and a 12-second idle (weight shifts between
## resting hinds, tail swishes, ear flicks, a head dip; the standing hooves planted). He's drawn
## in the men's own painted-skin shader (HeldHand's way), so he takes light as they do.
##
## His tack is separate meshes on the same skeleton (saddle, blanket, bridle, reins, saddlebags):
## `take_off` drops one as a loose body, `put_on` puts it back. His collision is a capsule per part
## following his bones (barrel, quarters, neck, head, each leg; horse.json's), not one box: cover later. Tied at a
## rail (`tie_to`) his ridden reins are hidden and two reins run from the bit to the rail instead.
## Model space: his head at -X, his right side -Z, the ground at y = 0 under his barrel's middle.

const DIR := "res://assets/creatures/horse/"
const MODEL := DIR + "horse.glb"
const INFO := DIR + "horse.json"
const COAT := DIR + "horse_coat.png"
const COAT_FAR := DIR + "horse_coat_lod.png"
const TACK_TEXTURE := DIR + "horse_tack.png"
const TACK: Array[StringName] = [&"saddle", &"blanket", &"bridle", &"reins", &"saddlebags"]
## Past this (m from the camera) the far coat and tack draw instead of the near ones.
const FAR := 26.0
## Each tied rein's length (m): how far it sags between the bit and the rail.
const REIN_LENGTH := 1.0
const REIN_COLOUR := Color(0.2, 0.11, 0.06)
## How often the collision follows the bones (s); the idle is slow.
const SHAPE_STEP := 0.1
## How often the idle is posed (s): its keys are 15 a second, so posing him every frame bought
## nothing (four horses so cost ~3.5 ms a frame headless on this workspace's core). Far off,
## less often.
const POSE_STEP := 1.0 / 15.0
const POSE_STEP_FAR := 0.2
var skeleton: Skeleton3D
var animation: AnimationPlayer
## His collision: on the world's layer, as the box horse's was (bullets stop in him, people walk
## round him); each shape follows its bone.
var body: StaticBody3D
## name -> MeshInstance3D: "coat", "coat_lod", "tack_lod" and each of TACK.
var parts := {}
var tied := false
## Where his reins are tied (global).
var tie_point := Vector3.ZERO

var _shapes: Array[CollisionShape3D] = []
var _shape_bones: Array[int] = []
var _shape_rest: Array[Transform3D] = []
var _sk_xf := Transform3D.IDENTITY  # the skeleton's place in the horse's space
var _shape_clock := 0.0
var _pose_clock := 0.0
var _reins: MeshInstance3D
var _rein_mesh: ImmediateMesh
var _bits: Array[Vector3] = []  # the bit's rings at rest, model space
var _head_bone := -1

static var _materials := {}
static var _info := {}


## True when the model has been built (tools/blender/horse.py); else the street keeps
## PropModels' code horse.
static func available() -> bool:
	return ResourceLoader.exists(MODEL)


static func info() -> Dictionary:
	if _info.is_empty() and FileAccess.file_exists(INFO):
		_info = JSON.parse_string(FileAccess.get_file_as_string(INFO))
	return _info


## The men's painted-skin material on one of his textures (HeldHand._material's way).
static func material(path: String) -> ShaderMaterial:
	if not _materials.has(path):
		var base := StandardMaterial3D.new()
		base.albedo_texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
		base.roughness = 0.9
		base.uv1_scale = Vector3.ONE
		var m := BodyInterior.skin_material(base)
		m.set_shader_parameter(&"use_uv", true)
		m.set_shader_parameter(&"uv_scale", 1.0)
		m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)
		_materials[path] = m
	return _materials[path]


func _init() -> void:
	name = "Horse"
	set_meta(&"model_name", "Horse")


func _ready() -> void:
	if skeleton == null:
		_build()


func _build() -> void:
	var model := (load(MODEL) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	animation = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var key := StringName(mi.name.to_lower())
		parts[key] = mi
		var far := key == &"coat_lod" or key == &"tack_lod"
		mi.material_override = material(COAT_FAR if key == &"coat_lod" else COAT if key == &"coat" else TACK_TEXTURE)
		if far:
			mi.visibility_range_begin = FAR
		else:
			mi.visibility_range_end = FAR
	_sk_xf = _relative(skeleton)
	_head_bone = skeleton.find_bone("head")
	var bit: Dictionary = info().get("bit", {})
	for side in ["L", "R"]:
		var b: Array = bit.get(side, [-1.45, 1.5, 0.0])
		_bits.append(Vector3(b[0], b[1], b[2]))
	_build_body()
	_start_idle()


## A node's transform in this horse's space (the model's own nodes may carry one).
func _relative(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var at: Node = n
	while at != null and at != self:
		t = (at as Node3D).transform * t
		at = at.get_parent()
	return t


func _build_body() -> void:
	body = StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	body.set_meta(&"horse", self)
	add_child(body)
	# A capsule per part, on the bone that carries it (horse.json's, from horse_shape.capsules):
	# [bone, from, to, radius], model space.
	for s: Array in info().get("capsules", []):
		var a := Vector3(s[1][0], s[1][1], s[1][2])
		var b := Vector3(s[2][0], s[2][1], s[2][2])
		var r: float = s[3]
		var cap := CapsuleShape3D.new()
		cap.radius = r
		cap.height = a.distance_to(b) + 2.0 * r
		var shape := CollisionShape3D.new()
		shape.name = String(s[0]).replace(".", "_")
		shape.shape = cap
		var y := (b - a).normalized()
		var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
		var rest := Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5)
		shape.transform = rest
		body.add_child(shape)
		_shapes.append(shape)
		_shape_bones.append(skeleton.find_bone(String(s[0])))
		_shape_rest.append(rest)


## The idle loop, each horse at its own place in it and its own pace (from where he stands, so
## the same street gives the same picture).
func _start_idle() -> void:
	if animation == null or not animation.has_animation(&"idle"):
		return
	var idle := animation.get_animation(&"idle")
	idle.loop_mode = Animation.LOOP_LINEAR
	var h := absi(hash(Vector2i(roundi(global_position.x * 10.0), roundi(global_position.z * 10.0))))
	# Posed by hand at the idle's own rate (_process), not every frame.
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	animation.play(&"idle")
	animation.seek(float(h % 1000) / 1000.0 * idle.length, true)
	animation.speed_scale = 0.9 + 0.2 * float((h / 1000) % 100) / 100.0
	# Each horse posed on its own frames (not all four on one).
	_pose_clock = float(h % 97) / 97.0 * POSE_STEP
	follow_bones()


## A bone's move from its rest, in the horse's space.
func bone_move(bone: int) -> Transform3D:
	var m := skeleton.get_bone_global_pose(bone) * skeleton.get_bone_global_rest(bone).affine_inverse()
	return _sk_xf * m * _sk_xf.affine_inverse()


## Each collision shape onto its bone as it is now.
func follow_bones() -> void:
	for i in _shapes.size():
		if _shape_bones[i] >= 0:
			_shapes[i].transform = bone_move(_shape_bones[i]) * _shape_rest[i]
	if body:
		Sight.shapes_moved(body)


func _physics_process(delta: float) -> void:
	_shape_clock += delta
	if _shape_clock >= SHAPE_STEP:
		var t := Prof.start()
		_shape_clock = 0.0
		follow_bones()
		Prof.stop(&"horses", t)


## The idle posed at its keys' rate (less often far off), and the tied reins redrawn when he's
## moved.
func _process(delta: float) -> void:
	if animation == null:
		return
	_pose_clock += delta
	var step := POSE_STEP
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null and cam.global_position.distance_squared_to(global_position) > FAR * FAR:
		step = POSE_STEP_FAR
	if _pose_clock < step:
		return
	var t := Prof.start()
	animation.advance(_pose_clock)
	_pose_clock = 0.0
	if tied and _reins != null:
		_draw_reins()
	Prof.stop(&"horses", t)


## Tie him to a rail: his reins from the bit to `point` (global).
func tie_to(point: Vector3) -> void:
	tied = true
	tie_point = point
	if parts.has(&"reins"):
		(parts[&"reins"] as MeshInstance3D).visible = false
	if _reins == null:
		_rein_mesh = ImmediateMesh.new()
		_reins = MeshInstance3D.new()
		_reins.name = "TiedReins"
		_reins.mesh = _rein_mesh
		var m := StandardMaterial3D.new()
		m.albedo_color = REIN_COLOUR
		m.roughness = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_reins.material_override = m
		_reins.visibility_range_end = FAR * 1.5
		add_child(_reins)
	_draw_reins()


## Where the bit's rings are now (global): the ends of his reins.
func bits() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var mv := bone_move(_head_bone) if _head_bone >= 0 else Transform3D.IDENTITY
	for b in _bits:
		out.append(global_transform * (mv * b))
	return out


## Two reins sagging from the bit to the tie: each a parabola as long as a rein, drawn as a cross
## of two thin strips so it reads from any side.
func _draw_reins() -> void:
	_rein_mesh.clear_surfaces()
	_rein_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var inv := global_transform.affine_inverse()
	var tie := inv * tie_point
	for b in bits():
		var a := inv * b
		var span := a.distance_to(tie)
		# A parabola's sag for a chord `span` and length REIN_LENGTH: L ≈ s + 8d²/(3s).
		var sag := sqrt(maxf(0.0, (REIN_LENGTH - span) * 3.0 * span / 8.0))
		var pts: Array[Vector3] = []
		for i in 11:
			var u := i / 10.0
			pts.append(a.lerp(tie, u) + Vector3.DOWN * sag * 4.0 * u * (1.0 - u))
		for i in 10:
			var d := (pts[i + 1] - pts[i]).normalized()
			for side: Vector3 in [d.cross(Vector3.UP), d.cross(d.cross(Vector3.UP))]:
				var w := side.normalized() * 0.009
				_quad(pts[i] - w, pts[i] + w, pts[i + 1] + w, pts[i + 1] - w)
	_rein_mesh.surface_end()


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for p in [a, b, c, a, c, d]:
		_rein_mesh.surface_add_vertex(p)


func has_tack(part: StringName) -> bool:
	return parts.has(part) and (parts[part] as MeshInstance3D).visible


## Take a piece of tack off: it's hidden on him and dropped beside him as a loose body (its rest
## shape), which is returned. Null if he isn't wearing it.
func take_off(part: StringName) -> RigidBody3D:
	if not has_tack(part):
		return null
	var mi: MeshInstance3D = parts[part]
	mi.visible = false
	if part in [&"saddle", &"blanket", &"saddlebags"] and parts.has(&"tack_lod") \
			and not (has_tack(&"saddle") or has_tack(&"blanket") or has_tack(&"saddlebags")):
		(parts[&"tack_lod"] as MeshInstance3D).visible = false
	if part == &"reins" and _reins != null:
		_reins.visible = false
	var drop := RigidBody3D.new()
	drop.name = String(part).to_pascal_case()
	drop.collision_layer = Layers.DEBRIS
	drop.collision_mask = Layers.DEBRIS_MASK
	drop.mass = {&"saddle": 14.0, &"blanket": 2.0, &"bridle": 1.0, &"reins": 0.5, &"saddlebags": 5.0}.get(part, 2.0)
	var m := MeshInstance3D.new()
	m.mesh = mi.mesh
	m.material_override = mi.material_override
	drop.add_child(m)
	var shape := CollisionShape3D.new()
	shape.shape = mi.mesh.create_convex_shape(true, true)
	drop.add_child(shape)
	var where := get_parent() if get_parent() != null else self
	where.add_child(drop)
	drop.global_transform = global_transform * _sk_xf
	return drop


## Put a piece of tack back on him.
func put_on(part: StringName) -> void:
	if not parts.has(part):
		return
	(parts[part] as MeshInstance3D).visible = true
	if parts.has(&"tack_lod") and part in [&"saddle", &"blanket", &"saddlebags"]:
		(parts[&"tack_lod"] as MeshInstance3D).visible = true
	if part == &"reins" and tied:
		(parts[part] as MeshInstance3D).visible = false
		if _reins != null:
			_reins.visible = true
