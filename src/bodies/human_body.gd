class_name HumanBody
extends Node3D
## A person's body in the world: segments built from the anatomy (config/anatomy.json), each a
## hitbox with its own low-poly, pixel-textured mesh, hands finger by finger (three bones each),
## layered clothes, and the Physiology underneath. Bullets trace through the hidden anatomy
## (`take_bullet`); wounds are painted where they went in and out and the blood spreads as he
## bleeds. When he can't stand he goes limp into a physics ragdoll; fingers and dropped guns
## fall as their own rigid bodies.
## Rest pose: facing -Z, feet at the origin, his right is +X. Keep the node unscaled.

signal hit(info: Dictionary)
signal fell(conscious: bool)
signal died(cause: StringName)

## Joint rotations per pose (degrees). A hanging limb swings forward with +X; the trunk and head
## lean back with +X (forward with -X). The rig drops so the lower foot stays on the ground.
const POSES := {
	&"stand": {&"upper_arm_r": Vector3(0, 0, 7), &"upper_arm_l": Vector3(0, 0, -7),
			&"forearm_r": Vector3(12, 0, 0), &"forearm_l": Vector3(12, 0, 0)},
	&"aim": {&"upper_arm_r": Vector3(84, 10, 0), &"forearm_r": Vector3(4, 0, 0),
			&"upper_arm_l": Vector3(0, 0, -7), &"forearm_l": Vector3(12, 0, 0), &"chest": Vector3(0, 8, 0)},
	&"hands_up": {&"upper_arm_r": Vector3(0, 0, 150), &"forearm_r": Vector3(0, 0, 25),
			&"upper_arm_l": Vector3(0, 0, -150), &"forearm_l": Vector3(0, 0, -25), &"head": Vector3(8, 0, 0)},
	&"clutch": {&"upper_arm_r": Vector3(18, 0, -16), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(18, 0, 16), &"forearm_l": Vector3(100, 0, 0),
			&"chest": Vector3(-18, 0, 0), &"head": Vector3(-10, 0, 0)},
	# Watching someone: square on, gun hand hanging by the holster.
	&"wary": {&"upper_arm_r": Vector3(-4, 0, 14), &"forearm_r": Vector3(18, 0, 0),
			&"upper_arm_l": Vector3(0, 0, -9), &"forearm_l": Vector3(14, 0, 0), &"chest": Vector3(0, -6, 0)},
	# Down on his heels behind something low, gun held ready.
	&"crouch": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"abdomen": Vector3(-10, 0, 0), &"chest": Vector3(-15, 0, 0), &"head": Vector3(15, 0, 0),
			&"upper_arm_r": Vector3(30, 0, 4), &"forearm_r": Vector3(60, 0, 0),
			&"upper_arm_l": Vector3(22, 0, 14), &"forearm_l": Vector3(95, 0, 0)},
	# Crouched and shooting over it.
	&"crouch_aim": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"chest": Vector3(-4, 8, 0), &"head": Vector3(4, 0, 0),
			&"upper_arm_r": Vector3(84, 10, 0), &"forearm_r": Vector3(4, 0, 0),
			&"upper_arm_l": Vector3(20, 0, 12), &"forearm_l": Vector3(95, 0, 0)},
	# Hunched right down, head in: rounds cracking over.
	&"duck": {&"thigh_r": Vector3(105, 0, 10), &"thigh_l": Vector3(105, 0, -10), &"shin_r": Vector3(-140, 0, 0),
			&"shin_l": Vector3(-140, 0, 0), &"foot_r": Vector3(35, 0, 0), &"foot_l": Vector3(35, 0, 0),
			&"abdomen": Vector3(-20, 0, 0), &"chest": Vector3(-30, 0, 0), &"head": Vector3(-5, 0, 0),
			&"upper_arm_r": Vector3(35, 0, -10), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(35, 0, 14), &"forearm_l": Vector3(105, 0, 0)},
	# Crouched, pressing on a wound.
	&"tend": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-25, 0, 0), &"head": Vector3(-15, 0, 0),
			&"upper_arm_r": Vector3(30, 0, -18), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(30, 0, 18), &"forearm_l": Vector3(100, 0, 0)},
	# Cowering: hunched, arms over his head.
	&"cower": {&"thigh_r": Vector3(40, 0, 6), &"thigh_l": Vector3(40, 0, -6), &"shin_r": Vector3(-70, 0, 0),
			&"shin_l": Vector3(-70, 0, 0), &"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-25, 0, 0),
			&"head": Vector3(-20, 0, 0), &"upper_arm_r": Vector3(140, 0, -30), &"forearm_r": Vector3(110, 0, 0),
			&"upper_arm_l": Vector3(140, 0, 30), &"forearm_l": Vector3(110, 0, 0)},
	# Sat at a table: knees bent square, leaning in on his forearms (the rig drops till his feet
	# are on the floor, so the chair takes his weight).
	&"sit": {&"thigh_r": Vector3(88, 0, 6), &"thigh_l": Vector3(84, 0, -8), &"shin_r": Vector3(-82, 0, 0),
			&"shin_l": Vector3(-92, 0, 0), &"foot_r": Vector3(-4, 0, 0), &"foot_l": Vector3(2, 0, 0),
			&"abdomen": Vector3(-8, 0, 0), &"chest": Vector3(-12, 0, 0), &"head": Vector3(6, 0, 0),
			&"upper_arm_r": Vector3(40, 0, -4), &"forearm_r": Vector3(80, 0, 0),
			&"upper_arm_l": Vector3(34, -20, 16), &"forearm_l": Vector3(88, 0, 0)},
	# Arms out at someone: a shove, a grab at his collar.
	&"shove": {&"upper_arm_r": Vector3(80, 0, -6), &"forearm_r": Vector3(10, 0, 0),
			&"upper_arm_l": Vector3(80, 0, 6), &"forearm_l": Vector3(10, 0, 0), &"chest": Vector3(-8, 0, 0)},
	# On his belly (the rig is laid flat): arms forward, head up.
	&"prone": {&"upper_arm_r": Vector3(150, 0, 12), &"forearm_r": Vector3(25, 0, 0),
			&"upper_arm_l": Vector3(150, 0, -12), &"forearm_l": Vector3(25, 0, 0), &"head": Vector3(55, 0, 0)},
	&"lie": {&"upper_arm_r": Vector3(165, 0, 20), &"forearm_r": Vector3(60, 0, 0),
			&"upper_arm_l": Vector3(165, 0, -20), &"forearm_l": Vector3(60, 0, 0), &"head": Vector3(20, 0, 0)},
	&"prone_aim": {&"upper_arm_r": Vector3(172, 0, 4), &"forearm_r": Vector3(0, 0, 0),
			&"upper_arm_l": Vector3(140, 0, -25), &"forearm_l": Vector3(45, 0, 0), &"head": Vector3(60, 0, 0)},
}
## Poses lying down (the rig is turned face-down). "lie" is lying flat by choice (behind something
## low), and he can get up again; "prone" is down because his legs have gone.
const PRONE_POSES := [&"prone", &"prone_aim"]

## Cone-twist limits at each segment's joint to its parent: [swing, twist] degrees.
const JOINT_LIMITS := {
	&"abdomen": [20, 12], &"chest": [22, 12], &"neck": [30, 25], &"head": [35, 30],
	&"upper_arm": [80, 40], &"forearm": [70, 10], &"hand": [55, 20],
	&"thigh": [60, 20], &"shin": [70, 5], &"foot": [30, 5],
}
const FINGERS := ["thumb", "index", "middle", "ring", "little"]

@export var person_id := &"outlaw"
@export var rng_seed := 1
@export var skin_tone := Color(0.72, 0.52, 0.4)
@export var shirt_color := Color(0.66, 0.6, 0.5)
## Alpha 0 = no vest / no coat.
@export var vest_color := Color(0.22, 0.17, 0.13)
@export var coat_color := Color(0.4, 0.33, 0.25, 0.0)
@export var trousers_color := Color(0.3, 0.27, 0.23)
## Alpha 0: no hat.
@export var hat_color := Color(0.18, 0.14, 0.11)
## Alpha 0 = no bandana.
@export var bandana_color := Color(0.55, 0.12, 0.1)
## Face and hair: see PeopleArt.face (tone comes from skin_tone).
@export var look := {"hair": Color(0.22, 0.15, 0.09), "moustache": &"walrus", "beard": &"stubble", "age": 0.4, "brows": 0.7}
@export var has_gun := true
## Which generated body he has (assets/people/<id>.glb, from tools/blender/make_people.py); empty
## or missing = the code-lofted BodyMesh.
@export var body_model := &"outlaw"
## Starts with it in the holster (a man minding his own business); the brain draws it.
@export var start_holstered := true
@export var total_mass := 80.0

var anatomy: Anatomy
var physiology: Physiology
var parts := {}  ## segment -> the physics body carrying it (AnimatableBody3D, RigidBody3D when limp)
var pivots := {}  ## segment -> joint pivot (while standing)
var visuals := {}  ## segment -> Node3D holding its meshes and decals
var fingers := {}  ## finger id -> knuckle pivot
var finger_bones := {}  ## finger id -> Array[Node3D], knuckle to tip
## Garments, outer to inner: {id, covers: Array[StringName], resistance (J), color, holes: []}.
var garments: Array[Dictionary] = []
## {segment, entry, exit (segment-local or null), lodged, hits, bleeds, garments, stain (Decal)}
var wounds: Array[Dictionary] = []
var limp := false
var pose := &"stand"
var aim_pitch := 0.0
var held_gun: Node3D
var gun_holstered := false
const DRAW_TIME := 0.5
var _draw_left := 0.0
var time_scale := 1.0

var _rig: Node3D
var _blocker: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _flinch := {}  ## segment -> [offset degrees, velocity]
var _pose_now := {}  ## segment -> current pose rotation (degrees), blending to the target
var _breath := 0.0
var _was_alive := true
var _was_conscious := true
var _cough_in := 3.0
## Wound openings per segment: [{at (segment-centred), energy (J), radius (m)}].
var openings := {}
var xray := false
## Moving: how fast (m/s) and how (&"walk", &"run", &"limp", &"crawl"; &"" standing still).
var move_speed := 0.0
var gait := &""
## Down on the ground but still moving (legs gone, not knocked out): posed, not a ragdoll.
var prone := false
var _gait_phase := 0.0
var _rest_foot_y := 0.0
var _moved_this_tick := false
var _pool: Decal
var _pool_ml := 0.0
var _day_cycle: Node
## The generated body (BodyMesh): one skeleton, a bone per segment, following the hitboxes.
var skeleton: Skeleton3D
var skin_meshes := {}  ## "shape/segment" ("skin/chest", "shirt/upper_arm_r", "hat/head"...) -> MeshInstance3D
var segment_pieces := {}  ## segment -> Array of its generated MeshInstance3Ds (skin and clothes)
var _rigid_meshes := {}  ## MeshInstance3D -> the piece's rigid mesh (swapped in when a limb comes off)
var _bone_parts: Array[StringName] = []


func _ready() -> void:
	add_to_group(&"people")
	_rng.seed = rng_seed
	anatomy = Anatomy.shared()
	physiology = Physiology.new(null, anatomy)
	_dress()
	_build()
	if has_gun:
		_give_gun()
	_use_wound_materials()
	Settings.changed.connect(_on_settings_changed)
	_apply_pose(0.0, true)
	Events.scorched.connect(func(who: Node, amount: float) -> void: if who == self: physiology.burn(amount))
	if xray_all:
		set_xray(true)


func _dress() -> void:
	var torso: Array[StringName] = [&"chest", &"abdomen"]
	var arms: Array[StringName] = [&"upper_arm_r", &"upper_arm_l", &"forearm_r", &"forearm_l"]
	var legs: Array[StringName] = [&"thigh_r", &"thigh_l", &"shin_r", &"shin_l"]
	if coat_color.a > 0.0:
		garments.append({"id": &"coat", "covers": torso + arms + [&"pelvis", &"thigh_r", &"thigh_l"] as Array[StringName], "resistance": 6.0, "color": coat_color, "holes": []})
	if vest_color.a > 0.0:
		garments.append({"id": &"vest", "covers": torso, "resistance": 3.0, "color": vest_color, "holes": []})
	garments.append({"id": &"shirt", "covers": torso + arms, "resistance": 1.0, "color": shirt_color, "holes": []})
	garments.append({"id": &"boots", "covers": [&"foot_r", &"foot_l"] as Array[StringName], "resistance": 15.0, "color": Color(0.2, 0.13, 0.08), "holes": []})
	garments.append({"id": &"trousers", "covers": [&"pelvis"] + legs as Array[StringName], "resistance": 2.0, "color": trousers_color, "holes": []})
	garments.append({"id": &"long_johns", "covers": torso + arms + legs + [&"pelvis"] as Array[StringName], "resistance": 0.5, "color": Color(0.8, 0.74, 0.64), "holes": []})


## The outermost garment on a segment, or {} for bare skin.
func outer_garment(segment: StringName) -> Dictionary:
	for g in garments:
		if g.covers.has(segment):
			return g
	return {}


func _material_for(segment: StringName) -> StandardMaterial3D:
	var g := outer_garment(segment)
	if g.is_empty():
		return _skin()
	return GunParts.cloth("%s:%s" % [person_id, g.id], g.color)


func _skin() -> StandardMaterial3D:
	return GunParts.material("skin:%s" % person_id, PixelArt.skin("skin:%s" % person_id, skin_tone, 81 + rng_seed), 0.0, 0.7)


# --- Building ----------------------------------------------------------------------------------

func _build() -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	var volumes := {}
	var total := 0.0
	for sid: StringName in anatomy.segments:
		var v := 0.0
		for c: Array in anatomy.segments[sid].capsules:
			var r: float = c[2]
			v += PI * r * r * (((c[1] as Vector3) - (c[0] as Vector3)).length() + 4.0 / 3.0 * r)
		volumes[sid] = v
		total += v
	for sid: StringName in anatomy.segment_order():
		var s: Dictionary = anatomy.segments[sid]
		var parent: StringName = s.parent
		var pivot := Node3D.new()
		pivot.name = String(sid)
		var rest := _pivot_rest(sid)
		if parent == &"":
			_rig.add_child(pivot)
			pivot.position = rest
		else:
			(pivots[parent] as Node3D).add_child(pivot)
			pivot.position = rest - _pivot_rest(parent)
		pivots[sid] = pivot
		var part := AnimatableBody3D.new()
		part.name = "Part"
		part.sync_to_physics = false
		part.collision_layer = Layers.BODY_PARTS
		part.collision_mask = 0
		part.set_meta(&"human_body", self)
		part.set_meta(&"segment", sid)
		part.set_meta(&"mass", total_mass * volumes[sid] / total)
		pivot.add_child(part)
		part.position = anatomy.segment_center(sid) - rest
		var center := anatomy.segment_center(sid)
		for i in s.capsules.size():
			var c: Array = s.capsules[i]
			var shape := CollisionShape3D.new()
			shape.name = "Shape%d" % i
			var cap := CapsuleShape3D.new()
			cap.radius = c[2]
			cap.height = ((c[1] as Vector3) - (c[0] as Vector3)).length() + 2.0 * float(c[2])
			shape.shape = cap
			shape.basis = _along((c[1] as Vector3) - (c[0] as Vector3))
			shape.position = ((c[0] as Vector3) + (c[1] as Vector3)) * 0.5 - center
			part.add_child(shape)
		parts[sid] = part
		var vis := Node3D.new()
		vis.name = "Visual"
		part.add_child(vis)
		visuals[sid] = vis
		_build_visual(sid, vis)
	_build_skin()
	_blocker = StaticBody3D.new()
	_blocker.name = "Blocker"
	_blocker.set_meta(&"human_body", self)
	_blocker.collision_layer = Layers.PEOPLE
	_blocker.collision_mask = 0
	var bs := CollisionShape3D.new()
	var bc := CapsuleShape3D.new()
	bc.radius = 0.28
	bc.height = anatomy.height
	bs.shape = bc
	bs.position.y = anatomy.height * 0.5
	_blocker.add_child(bs)
	add_child(_blocker)


## Where a segment turns about, in the rest pose: the joint with its parent.
func _pivot_rest(sid: StringName) -> Vector3:
	var s: Dictionary = anatomy.segments[sid]
	if s.parent == &"":
		return anatomy.segment_center(sid)
	if String(sid).begins_with("foot"):
		return anatomy.segments[s.parent].b
	return s.a


## A basis whose Y axis points along `axis`.
static func _along(axis: Vector3) -> Basis:
	var y := axis.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _build_visual(sid: StringName, vis: Node3D) -> void:
	if String(sid).begins_with("hand"):
		_build_hand(sid, vis, anatomy.segment_center(sid))


## The skin and clothes (the generated body if there is one, else BodyMesh) skinned to a skeleton whose bones follow the parts.
func _build_skin() -> void:
	var outfit := {"shirt": true, "vest": vest_color.a > 0.0, "coat": coat_color.a > 0.0, "trousers": true,
			"boots": true, "gun_belt": has_gun, "bandana": bandana_color.a > 0.0, "hat": hat_color.a > 0.0}
	var data := PeopleBodies.build(anatomy, outfit, body_model)
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	var skin := Skin.new()
	var rests: Array[Transform3D] = data.rests
	for i in data.bones.size():
		var sid: StringName = data.bones[i]
		skeleton.add_bone(String(sid))
		skeleton.set_bone_rest(i, rests[i])
		skin.add_bind(i, rests[i].affine_inverse())
		_bone_parts.append(sid)
	skeleton.reset_bone_poses()
	var f := look.duplicate()
	f["tone"] = skin_tone
	f["seed"] = rng_seed
	var skin_mat := PeopleArt.material("skin:%s" % person_id, PeopleArt.skin(person_id, skin_tone, 81 + rng_seed), 0.7)
	var mats := {
		"skin": skin_mat,
		"head": PeopleArt.face_material("face:%s" % person_id, PeopleArt.face(person_id, f)),
		"shirt": _cloth("shirt", shirt_color, &"plain"),
		"vest": _cloth("vest", vest_color, &"wool", false),
		"coat": _cloth("coat", coat_color, &"wool", false),
		"trousers": _cloth("trousers", trousers_color, &"wool", false),
		"boots": _cloth("boots", Color(0.2, 0.13, 0.08), &"leather"),
		"gun_belt": PeopleArt.material("gunbelt:%s" % person_id, PeopleArt.cartridge_belt(person_id, Color(0.34, 0.21, 0.11), rng_seed), 0.7, false),
		"belt": _cloth("belt", Color(0.16, 0.1, 0.06), &"leather", false),
		"holster": _cloth("holster", Color(0.38, 0.24, 0.12), &"leather"),
		"bandana": _cloth("bandana", bandana_color, &"plain", false),
		"hat": _cloth("hat", hat_color, &"felt"),
		"hat_brim": _cloth("hat", hat_color, &"felt", false),
		"hat_band": _cloth("hatband", hat_color.darkened(0.55), &"leather", false),
	}
	const DOUBLE_SIDED := ["vest", "coat", "trousers", "gun_belt", "belt", "bandana", "hat_brim", "hat_band"]
	for shape: String in data.shapes:
		var base: StandardMaterial3D = mats.get(shape, skin_mat)
		var pieces: Dictionary = data.shapes[shape]
		for b: int in pieces:
			var sid: StringName = data.bones[b]
			var mi := MeshInstance3D.new()
			mi.name = "%s_%s" % [shape.to_pascal_case(), sid]
			mi.mesh = pieces[b][0]
			_rigid_meshes[mi] = pieces[b][1]
			mi.material_override = _piece_material(base, DOUBLE_SIDED.has(shape))
			mi.layers = Layers.VIS_BODY
			mi.custom_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 5, 6))
			skeleton.add_child(mi)
			mi.skin = skin
			mi.skeleton = NodePath("..")
			skin_meshes["%s/%s" % [shape, sid]] = mi
			(segment_pieces.get_or_add(sid, []) as Array).append(mi)
	_update_skeleton()


## The wound shader for a generated piece: textured by its UVs, opened by rest positions (CUSTOM0).
func _piece_material(base: StandardMaterial3D, double_sided: bool) -> ShaderMaterial:
	var m := BodyInterior.skin_material(base)
	if double_sided:
		m.shader = BodyInterior.SKIN_DOUBLE_SHADER
	m.set_shader_parameter(&"use_uv", true)
	m.set_shader_parameter(&"use_custom_pos", true)
	m.set_shader_parameter(&"uv_scale", base.uv1_scale.x)
	return m


## Every mesh showing a body part: the generated skin and clothes pieces, and whatever hangs on
## its visual node (fingers, the gun, the inside once it's opened).
func body_meshes(segment: StringName) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mi in segment_pieces.get(segment, []):
		out.append(mi)
	var vis: Node3D = visuals.get(segment)
	if vis:
		for mi in vis.find_children("*", "MeshInstance3D", true, false):
			out.append(mi as MeshInstance3D)
	return out


## After an amputation nothing may stretch across a joint: every piece follows its own part only.
func _stop_skinning_across_joints() -> void:
	for mi: MeshInstance3D in _rigid_meshes:
		if is_instance_valid(mi):
			mi.mesh = _rigid_meshes[mi]


func _cloth(what: String, colour: Color, style: StringName, cull_back := true) -> StandardMaterial3D:
	var key := "%s:%s" % [person_id, what]
	return PeopleArt.material(key, PeopleArt.cloth(key, colour, rng_seed * 7 + what.length(), style), 0.95, cull_back)


## Bones follow the parts (hitboxes while standing, ragdoll pieces when limp).
func _update_skeleton() -> void:
	if skeleton == null:
		return
	var inv := skeleton.global_transform.affine_inverse()
	for i in _bone_parts.size():
		var part: Node3D = parts.get(_bone_parts[i])
		if part != null and is_instance_valid(part) and part.is_inside_tree():
			skeleton.set_bone_pose(i, inv * part.global_transform)


func _process(_delta: float) -> void:
	_update_skeleton()


## The hand: palm, then each finger as three bones from its knuckle, following the anatomy.
func _build_hand(sid: StringName, vis: Node3D, center: Vector3) -> void:
	var side := String(sid).right(1)
	var skin := PeopleArt.material("skin:%s" % person_id, PeopleArt.skin(person_id, skin_tone, 81 + rng_seed), 0.7)
	for f: String in FINGERS:
		var fid := StringName("%s_%s" % [f, side])
		var st := anatomy.structure(fid)
		if st.is_empty():
			continue
		var knuckle := Node3D.new()
		knuckle.name = f.capitalize()
		knuckle.position = st.a - center
		knuckle.basis = _along(st.a - st.b)  # +Y back up the finger, so bones hang along -Y
		vis.add_child(knuckle)
		var length: float = (st.b - st.a).length()
		var bones: Array[Node3D] = []
		var parent: Node3D = knuckle
		var lengths := [0.42, 0.33, 0.25]
		for i in 3:
			var bone := Node3D.new()
			bone.name = "Bone%d" % i
			if i > 0:
				bone.position = Vector3(0, -length * lengths[i - 1], 0)
			parent.add_child(bone)
			var l: float = length * lengths[i]
			var w := 0.017 if f != "thumb" else 0.019
			var mi := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.height = l + w * 0.4  # overlap into the next bone so bent knuckles stay closed
			bm.top_radius = w * 0.5 * (1.0 - 0.1 * i)
			bm.bottom_radius = w * 0.5 * (0.9 - 0.1 * i) * (0.85 if i == 2 else 1.0)
			bm.radial_segments = 6
			bm.rings = 1
			mi.mesh = bm
			mi.material_override = skin
			mi.layers = Layers.VIS_BODY
			mi.position = Vector3(0, -l * 0.5, 0)
			bone.add_child(mi)
			bones.append(bone)
			parent = bone
		fingers[fid] = knuckle
		finger_bones[fid] = bones


## Curl a hand's fingers (0 open, 1 fist) about the palm side.
func curl_hand(side: String, amount: float) -> void:
	var sx := -1.0 if side == "r" else 1.0
	for f: String in FINGERS:
		var fid := StringName("%s_%s" % [f, side])
		if not finger_bones.has(fid):
			continue
		var bones: Array = finger_bones[fid]
		var k := 0.6 if f == "thumb" else 1.0
		for i in bones.size():
			(bones[i] as Node3D).rotation_degrees.z = sx * amount * k * [55.0, 80.0, 60.0][i]


func _give_gun() -> void:
	var gun := RevolverModel.new()
	gun.name = "Revolver"
	var vis: Node3D = visuals[&"hand_r"]
	vis.add_child(gun)
	gun.position = Vector3(0.232, 0.765, -0.05) - anatomy.segment_center(&"hand_r")
	gun.rotation_degrees = Vector3(-90, 0, 0)
	held_gun = gun
	curl_hand("r", 0.85)
	if start_holstered:
		holster_gun(true)


## Put the gun in its holster on his right hip (or, `now`, without the half second it takes).
func holster_gun(now := false) -> void:
	if held_gun == null or gun_holstered:
		return
	gun_holstered = true
	_draw_left = 0.0 if now else DRAW_TIME
	var vis: Node3D = visuals[&"pelvis"]
	held_gun.reparent(vis, false)
	held_gun.position = Vector3(0.2, 0.9, 0.02) - anatomy.segment_center(&"pelvis")
	held_gun.rotation_degrees = Vector3(-96, 0, 0)
	curl_hand("r", 0.25)


## Draw it: in his hand, ready to fire in half a second.
func draw_gun() -> void:
	if held_gun == null or not gun_holstered or not physiology.can_hold("r"):
		return
	gun_holstered = false
	_draw_left = DRAW_TIME
	var vis: Node3D = visuals[&"hand_r"]
	held_gun.reparent(vis, false)
	held_gun.position = Vector3(0.232, 0.765, -0.05) - anatomy.segment_center(&"hand_r")
	held_gun.rotation_degrees = Vector3(-90, 0, 0)
	curl_hand("r", 0.85)


## Gun out and up, able to shoot.
func gun_ready() -> bool:
	return held_gun != null and not gun_holstered and _draw_left <= 0.0


func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := GunParts.box(parent, n, size, pos, GunParts.cloth("%s:%s" % [person_id, n.to_lower()], color))
	mi.layers = Layers.VIS_BODY
	return mi


func _cylinder(parent: Node3D, n: String, radius: float, h: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := GunParts.tube(parent, n, radius, h, pos, GunParts.cloth("%s:%s" % [person_id, n.to_lower()], color), 10, Vector3.ZERO)
	mi.layers = Layers.VIS_BODY
	return mi


# --- Living ------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _day_cycle == null and is_inside_tree():
		_day_cycle = get_tree().get_first_node_in_group(&"day_cycle")
	var scale_now: float = _day_cycle.time_scale if _day_cycle != null else time_scale
	physiology.step(delta * scale_now)
	_update_stains()
	if not limp:
		_apply_pose(delta)
		if not physiology.can_stand() and not prone:
			if _can_crawl():
				go_prone()
			else:
				go_limp()
		elif prone and not _can_crawl():
			go_limp()
	if not _moved_this_tick:
		move_speed = move_toward(move_speed, 0.0, delta * 6.0)
		if move_speed < 0.05:
			gait = &""
	_moved_this_tick = false
	_draw_left = maxf(_draw_left - delta, 0.0)
	if held_gun != null and not gun_holstered and not physiology.can_hold("r"):
		drop_gun()
	if limp:
		_update_pool()
	_cough(delta)
	var conscious := physiology.is_conscious()
	if _was_alive and not physiology.alive:
		_was_alive = false
		died.emit(physiology.cause_of_death)
		Events.person_died.emit(self, physiology.cause_of_death)
	_was_conscious = conscious


func set_pose(p: StringName) -> void:
	if not POSES.has(p):
		return
	if prone and not p in PRONE_POSES:
		p = &"prone_aim" if p == &"aim" or p == &"crouch_aim" else &"prone"
	pose = p


## Legs gone but still with it: down on his belly, able to crawl and shoot.
func _can_crawl() -> bool:
	var p := physiology
	return p.is_conscious() and p.shock() < 0.8 and (p.can_hold("r") or p.can_hold("l")) and not p.arms_paralysed()


func go_prone() -> void:
	if prone or limp:
		return
	prone = true
	set_pose(&"prone")
	fell.emit(true)
	Events.person_fell.emit(self, true)


## Walk (or run, or crawl) towards a point on the ground, this tick. Stops short of walls and
## people; slides along them; climbs a step up to a boardwalk. Returns true on arrival.
func walk_to(target: Vector3, speed: float, delta: float, facing := true) -> bool:
	if limp:
		return false
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.1:
		return true
	var p := physiology
	var how := &"run" if speed > 2.4 else &"walk"
	# Hurt legs slow him and make him limp.
	var legs := minf(p.muscle_strength("leg", "r"), p.muscle_strength("leg", "l"))
	speed *= lerpf(0.4, 1.0, legs) * (1.0 - p.shock() * 0.5)
	if legs < 0.75 and not prone:
		how = &"limp"
		speed = minf(speed, 1.3)
	if prone:
		how = &"crawl"
		speed = minf(speed, 0.35)
	var dir := to / dist
	var step := minf(speed * delta, dist)
	var moved := _slide(dir * step)
	if facing and moved.length() > 0.001:
		var look := global_position + (moved if not prone else dir)
		var fwd := look - global_position
		global_rotation.y = atan2(-fwd.x, -fwd.z)
	_snap_to_ground()
	gait = how
	move_speed = moved.length() / maxf(delta, 1e-4)
	_moved_this_tick = true
	var left := target - global_position
	left.y = 0.0
	return left.length() < 0.1 or (dist < 0.4 and moved.length() < 0.001)


## Move by `motion` (flat), stopping at and sliding along whatever's in the way.
func _slide(motion: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 0.26
	var exclude: Array[RID] = []
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	var total := Vector3.ZERO
	var left := motion
	for attempt in 3:
		if left.length() < 0.0005:
			break
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, global_position + total + Vector3.UP * (0.35 if prone else 0.75))
		q.motion = left
		q.collision_mask = Layers.WORLD | Layers.PEOPLE
		q.exclude = exclude
		var frac := space.cast_motion(q)
		var safe := left * frac[0]
		total += safe
		if frac[0] >= 1.0:
			break
		# Blocked: slide along it.
		q.transform = Transform3D(Basis.IDENTITY, global_position + total + Vector3.UP * (0.35 if prone else 0.75) + left.normalized() * 0.02)
		q.motion = Vector3.ZERO
		var rest := space.get_rest_info(q)
		if rest.is_empty():
			break
		var n: Vector3 = rest.normal
		n.y = 0.0
		if n.length() < 0.01:
			break
		n = n.normalized()
		left = (left - safe)
		left -= n * left.dot(n)
	global_position += total
	return total


## Keep his feet on whatever's under him (a boardwalk step up, a slope).
func _snap_to_ground() -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.5, global_position + Vector3.DOWN * 1.0, Layers.WORLD)
	if _blocker and is_instance_valid(_blocker):
		q.exclude = [_blocker.get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		global_position.y = hit.position.y


## Turn to face a point and, in the aim pose, raise the gun arm to it.
func face(point: Vector3) -> void:
	if limp:
		return
	var to := point - global_position
	to.y = 0.0
	if to.length() > 0.01:
		global_rotation.y = atan2(-to.x, -to.z)
	var shoulder := (pivots[&"upper_arm_r"] as Node3D).global_position
	var d := point - shoulder
	aim_pitch = rad_to_deg(atan2(d.y, Vector2(d.x, d.z).length()))


func _apply_pose(delta: float, snap := false) -> void:
	_breath += delta
	var target: Dictionary = POSES[pose]
	var blend := 1.0 if snap else clampf(delta * 6.0, 0.0, 1.0)
	var overlay := _gait_overlay(delta)
	for sid: StringName in pivots:
		var goal: Vector3 = target.get(sid, Vector3.ZERO) + overlay.get(sid, Vector3.ZERO)
		if sid == &"upper_arm_r" and (pose == &"aim" or pose == &"crouch_aim"):
			goal.x += aim_pitch
		var now: Vector3 = _pose_now.get(sid, goal)
		now = now.lerp(goal, blend)
		_pose_now[sid] = now
		var f: Array = _flinch.get(sid, [Vector3.ZERO, Vector3.ZERO])
		if delta > 0.0:
			# A damped spring pulls the flinch back to the pose.
			f[1] += (-f[0] * 220.0 - f[1] * 18.0) * delta
			f[0] += f[1] * delta
			_flinch[sid] = f
		var rot: Vector3 = now + f[0]
		if sid == &"chest":
			rot.x += sin(_breath * 1.6) * 1.2 * (1.0 + physiology.shock() * 2.0)
		(pivots[sid] as Node3D).rotation_degrees = rot
	_place_rig(delta, snap)
	if held_gun != null and not gun_holstered:
		curl_hand("r", 0.85)


## Swinging legs and arms while he moves: a walk, a run, a limp favouring the bad leg, a crawl.
func _gait_overlay(delta: float) -> Dictionary:
	var out := {}
	if gait == &"" or move_speed < 0.05:
		return out
	var stride: float = {&"walk": 1.3, &"run": 2.2, &"limp": 0.9, &"crawl": 0.5}.get(gait, 1.3)
	_gait_phase = fmod(_gait_phase + delta * move_speed / stride * TAU, TAU)
	var s := sin(_gait_phase)
	var c := cos(_gait_phase)
	var aiming := pose == &"aim" or pose == &"crouch_aim" or pose == &"prone_aim"
	match gait:
		&"crawl":
			out[&"upper_arm_r"] = Vector3(s * 25.0, 0, 0)
			out[&"upper_arm_l"] = Vector3(-s * 25.0, 0, 0)
			out[&"thigh_r"] = Vector3(-maxf(s, 0.0) * 20.0, 0, 10)
			out[&"thigh_l"] = Vector3(-maxf(-s, 0.0) * 20.0, 0, -10)
			out[&"shin_r"] = Vector3(-maxf(s, 0.0) * 50.0, 0, 0)
			out[&"shin_l"] = Vector3(-maxf(-s, 0.0) * 50.0, 0, 0)
		_:
			var run := gait == &"run"
			var amp_t := 40.0 if run else 22.0
			var amp_s := 75.0 if run else 38.0
			var amp_a := 32.0 if run else 14.0
			var bad_r := gait == &"limp" and physiology.muscle_strength("leg", "r") <= physiology.muscle_strength("leg", "l")
			var k_r := 0.35 if gait == &"limp" and bad_r else 1.0
			var k_l := 0.35 if gait == &"limp" and not bad_r else 1.0
			out[&"thigh_r"] = Vector3(s * amp_t * k_r, 0, 0)
			out[&"thigh_l"] = Vector3(-s * amp_t * k_l, 0, 0)
			out[&"shin_r"] = Vector3(-maxf(c, 0.0) * amp_s * k_r, 0, 0)
			out[&"shin_l"] = Vector3(-maxf(-c, 0.0) * amp_s * k_l, 0, 0)
			if not aiming:
				out[&"upper_arm_r"] = Vector3(-s * amp_a, 0, 0)
				out[&"upper_arm_l"] = Vector3(s * amp_a, 0, 0)
			if run:
				out[&"chest"] = Vector3(-12.0, 0, 0)
			if gait == &"limp":
				out[&"chest"] = Vector3(-6.0, 0, 8.0 * (1.0 if bad_r else -1.0) * absf(s))
	return out


## The rig's height and tilt: lowered so the lower foot is on the ground, or laid face-down.
func _place_rig(delta: float, snap: bool) -> void:
	var k := 1.0 if snap else clampf(delta * 8.0, 0.0, 1.0)
	if prone or pose == &"lie":
		_rig.rotation.x = lerp_angle(_rig.rotation.x, deg_to_rad(-90.0), clampf(delta * 3.0, 0.0, 1.0) if not snap else 1.0)
		_rig.position.y = lerpf(_rig.position.y, 0.16, k)
		_set_blocker(true)
		return
	_rig.rotation.x = 0.0
	if _rest_foot_y == 0.0:
		_rest_foot_y = _foot_height()
	var drop := _rest_foot_y - _foot_height() + _rig.position.y
	_rig.position.y = lerpf(_rig.position.y, drop, k)
	_set_blocker(false)


func _foot_height() -> float:
	var lowest := INF
	for sid: StringName in [&"foot_r", &"foot_l"]:
		var pv := pivots.get(sid) as Node3D
		if pv:
			lowest = minf(lowest, to_local(pv.global_position).y)
	return lowest if lowest < INF else 0.0


## The capsule that stops the player walking through him: upright, or lying along him.
func _set_blocker(lying: bool) -> void:
	if _blocker == null or not is_instance_valid(_blocker):
		return
	var bs := _blocker.get_child(0) as CollisionShape3D
	if lying:
		bs.position = Vector3(0, 0.18, -0.85)
		bs.rotation_degrees = Vector3(90, 0, 0)
	else:
		var h := clampf(anatomy.height + _rig.position.y, 0.9, anatomy.height)
		bs.position = Vector3(0, h * 0.5, 0)
		bs.rotation_degrees = Vector3.ZERO


## Blood in the windpipe or a holed lung: he coughs it up, now and then.
func _cough(delta: float) -> void:
	var p := physiology
	if not p.alive or not (p.airway_blood or not p.lung_damage.is_empty()):
		return
	_cough_in -= delta
	if _cough_in > 0.0:
		return
	_cough_in = _rng.randf_range(2.5, 6.0) if p.airway_blood else _rng.randf_range(5.0, 11.0)
	var head: Node3D = parts[&"head"]
	var mouth := head.global_transform * (Vector3(0, 1.58, -0.1) - anatomy.segment_center(&"head"))
	var fwd := -head.global_basis.z
	ImpactEffects.burst(get_parent(), mouth, fwd + Vector3.UP * 0.2, Blood.ARTERIAL, 10, 1.6, 0.012)
	Blood.throw(get_parent() as Node3D, mouth, fwd * 1.6, 3.0)
	_flinch_from(&"chest", mouth, -fwd, 0.02)


## Throw the hit segment and the ones above it back from the bullet.
func _flinch_from(segment: StringName, at: Vector3, dir: Vector3, momentum: float) -> void:
	var sid := segment
	var k := 900.0 * momentum
	while sid != &"" and pivots.has(sid):
		var pivot: Node3D = pivots[sid]
		var axis_world := (at - pivot.global_position).cross(dir)
		var axis := pivot.global_basis.inverse() * axis_world
		var f: Array = _flinch.get(sid, [Vector3.ZERO, Vector3.ZERO])
		f[1] += Vector3(axis.x, axis.y, axis.z) * k
		_flinch[sid] = f
		k *= 0.6
		sid = anatomy.segments[sid].parent


# --- Being shot --------------------------------------------------------------------------------

## A bullet reached a body part's hitbox. Traces it through the anatomy under the clothes; returns
## {segment, exit (world Vector3 or null), energy_out, hits, wound}. `blast` is the muzzle blast it
## brings (joules; Ballistics works it out from the range, or it's a revolver's from `travelled`).
## Anything lighter than 6 g is a buckshot pellet.
func take_bullet(collider: Node3D, pos: Vector3, dir: Vector3, energy: float, bullet_radius: float, mass := 0.0165, travelled := 99.0, blast := -1.0, projectile := &"") -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment")
	var xf := collider.global_transform
	var center := anatomy.segment_center(seg)
	var inv := xf.affine_inverse()
	var d := (inv.basis * dir).normalized()
	var o := inv * pos + center - d * 0.01
	var holed: Array[StringName] = []
	for g in garments:
		if g.covers.has(seg):
			energy -= g.resistance
			g.holes.append({"segment": seg, "at": o - center})
			holed.append(g.id)
	energy = maxf(energy, 0.0)
	var tr := anatomy.trace(seg, o, d, energy, bullet_radius, _rng)
	var bleeds := physiology.apply_trace(tr)
	var wound := {"segment": seg, "entry": tr.entry - center,
			"exit": (tr.exit - center) if tr.exit != null else null, "lodged": tr.exit == null,
			"hits": tr.hits.map(func(h: Dictionary) -> Dictionary: return {"id": h.id, "effect": h.effect}),
			"stop": (tr.stop - center) if tr.stop != null else null,
			"bleeds": bleeds, "garments": holed, "stain": null,
			"kind": &"graze" if tr.graze else (projectile if projectile != &"" else (&"pellet" if mass < PELLET_MASS else &"bullet")), "dir": d}
	wounds.append(wound)
	_paint_wound(wound)
	for h: Dictionary in tr.hits:
		if h.effect == &"severed":
			sever_finger(h.id, dir)
	var deposited := maxf(energy - tr.energy_out, 0.0)
	# Where it tore: a little at the way in (a lot more with the muzzle's blast right on him), most
	# at the way out.
	var at_entry := deposited * (0.25 if tr.exit != null else 0.6)
	if blast < 0.0:
		blast = 300.0 if travelled < 0.3 else 120.0 * maxf(1.5 - travelled, 0.0)
	at_entry += blast
	if not tr.graze:
		open_wound(seg, tr.entry - center, at_entry, dir)
		if tr.exit != null:
			open_wound(seg, tr.exit - center, deposited * 0.75, dir)
	var severe := false
	for h: Dictionary in tr.hits:
		if h.effect == &"broken" or (h.kind == &"organ") or (h.kind == &"artery"):
			severe = true
	var speed := sqrt(2.0 * deposited / maxf(mass, 0.001))
	var knocked := not limp and _knocked_down(seg, deposited, severe, _small_wound(wound.kind))
	if knocked:
		go_limp(dir * 1.2)
	elif limp and collider is RigidBody3D:
		(collider as RigidBody3D).apply_impulse(dir * mass * speed * 2.0, pos - collider.global_position)
	else:
		_flinch_from(seg, pos, dir, mass * speed)
	var exit_world: Variant = xf * (tr.exit - center) if tr.exit != null else null
	if exit_world != null and get_parent() is Node3D:
		# The spray out of the exit wound spatters whatever's behind him.
		var big := seg == &"head"
		Blood.spray(get_parent() as Node3D, exit_world, dir, 40.0 if big else 12.0, 9 if big else 4, _rng)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": wound.hits,
			"position": pos, "direction": dir, "exit": exit_world, "lodged": wound.lodged,
			"deposited": deposited, "severe": severe, "knocked_down": knocked, "kind": wound.kind}
	hit.emit(info)
	Events.body_hit.emit(info)
	if xray:
		set_xray(true)
	return {"segment": seg, "exit": exit_world, "energy_out": tr.energy_out, "hits": tr.hits, "wound": wound}


## Does the hit itself put him down? A heavy ball dumping its energy in the trunk often does.
func _knocked_down(seg: StringName, deposited: float, severe: bool, pellet := false) -> bool:
	var s := String(seg)
	if not (seg in [&"chest", &"abdomen", &"pelvis", &"head", &"neck"] or s.begins_with("thigh")):
		return false
	var t := physiology.tuning
	var chance := maxf(deposited - t.knockdown_energy, 0.0) / 100.0 * t.knockdown_per_100j
	if severe:
		chance += t.knockdown_severe
	if pellet:
		# One pellet of a charge: each gets its own roll, so each counts for a share.
		chance *= t.knockdown_pellet_share
	return _rng.randf() < minf(chance, t.knockdown_max)


## A glass cut: a shard flying at `pos` along `dir` slices `depth` metres into whatever part it
## hits; `embedded` leaves the shard in the wound for the doctor.
func take_cut(collider: Node3D, pos: Vector3, dir: Vector3, depth: float, embedded := false) -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment", &"")
	if seg == &"":
		seg = segment_at(pos)
		collider = parts[seg]
	var xf := collider.global_transform
	var center := anatomy.segment_center(seg)
	var inv := xf.affine_inverse()
	var d := (inv.basis * dir).normalized()
	var o := inv * pos + center - d * 0.02
	var tr := anatomy.trace(seg, o, d, depth * 100.0 * anatomy.flesh_resistance, 0.002, _rng)
	tr.cut = true
	var bleeds := physiology.apply_trace(tr)
	var wound := {"segment": seg, "entry": tr.entry - center, "exit": null, "lodged": embedded,
			"stop": (tr.stop - center) if tr.stop != null else tr.entry - center,
			"hits": tr.hits.map(func(h: Dictionary) -> Dictionary: return {"id": h.id, "effect": h.effect}),
			"bleeds": bleeds, "garments": [], "stain": null, "kind": &"cut", "dir": d, "embedded": embedded}
	wounds.append(wound)
	_paint_wound(wound)
	_flinch_from(seg, pos, dir, 0.3)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": wound.hits,
			"position": pos, "direction": dir, "exit": null, "lodged": embedded, "kind": &"cut"}
	hit.emit(info)
	Events.body_hit.emit(info)
	return wound


## Hit by something heavy (falling timber, a fall): bruises, broken bones, a burst spleen or a
## cracked skull by the energy of it. A standing man hit hard enough goes down.
func take_blow(collider: Node3D, joules: float, point: Vector3, dir := Vector3.DOWN) -> PackedStringArray:
	var seg: StringName = collider.get_meta(&"segment", &"") if collider else &""
	if seg == &"":
		seg = segment_at(point)
	var harm := physiology.blow(seg, joules, _rng)
	var part: Node3D = parts.get(seg)
	if part and joules > 20.0:
		var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(seg)
		var s: Dictionary = anatomy.segments[seg]
		# The bruise comes up on the skin nearest the blow.
		var c := anatomy.segment_center(seg)
		var axis_pt: Vector3 = s.a.lerp(s.b, clampf((local - s.a).dot(s.b - s.a) / maxf((s.b - s.a).length_squared(), 1e-6), 0.0, 1.0))
		var skin := axis_pt + (local - axis_pt).normalized() * float(s.radius) if (local - axis_pt).length() > 0.001 else axis_pt
		var bruise := _decal(visuals[seg], seg, skin - c, clampf(joules / 1500.0, 0.05, 0.18), PixelArt.blood("bruise", 29, false, 16))
		bruise.modulate = Color(0.35, 0.22, 0.4)
	if not limp and joules > 160.0:
		go_limp(dir * clampf(joules / 300.0, 0.5, 3.0))
	elif not limp:
		_flinch_from(seg, point, dir, joules * 0.002)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": [], "position": point,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blow", "harm": harm, "joules": joules}
	hit.emit(info)
	Events.body_hit.emit(info)
	return harm


## Which part of him is at a world point (for a standing man, by height and side).
func segment_at(point: Vector3) -> StringName:
	var best := &"chest"
	var best_d := INF
	for sid: StringName in parts:
		var part := parts[sid] as Node3D
		if part == null or not is_instance_valid(part):
			continue
		var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(sid)
		for c: Array in anatomy.segments[sid].capsules:
			var a: Vector3 = c[0]
			var ab: Vector3 = (c[1] as Vector3) - a
			var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var dist := local.distance_to(a + ab * t) - float(c[2])
			if dist < best_d:
				best_d = dist
				best = sid
	return best


## The normal of a segment's skin at a point (segment-local): from the capsule whose surface
## the point is on (the one it's least inside of).
func _skin_normal(seg: StringName, local: Vector3) -> Vector3:
	var center := anatomy.segment_center(seg)
	var best := -INF
	var normal := Vector3.UP
	for c: Array in anatomy.segments[seg].capsules:
		var a: Vector3 = (c[0] as Vector3) - center
		var ab: Vector3 = (c[1] as Vector3) - (c[0] as Vector3)
		var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		var n := local - (a + ab * t)
		var out: float = n.length() - float(c[2])
		if out > best and n.length() > 1e-5:
			best = out
			normal = n.normalized()
	return normal


func _paint_wound(w: Dictionary) -> void:
	var vis: Node3D = visuals[w.segment]
	var seed := wounds.size() * 13 + rng_seed
	if w.kind == &"graze" or w.kind == &"cut":
		# A furrow or a slice: a bloody line along the way it went, no hole.
		var a: Vector3 = w.entry
		var b: Vector3 = w.exit if w.exit != null else (w.stop if w.stop != null else a)
		var length := maxf(a.distance_to(b), 0.03 if w.kind == &"cut" else 0.05)
		var mid := (a + b) * 0.5
		var along: Vector3 = w.dir
		var line := _decal(vis, w.segment, mid, 0.02 if w.kind == &"graze" else 0.01, PixelArt.blood("furrow", 17, true, 16))
		var n := line.basis.y
		var z := (along - n * along.dot(n)).normalized()
		if z.length() > 0.1:
			line.basis = Basis(n.cross(z), n, z)
		line.size = Vector3(0.022 if w.kind == &"graze" else 0.009, 0.06, length)
		w.stain = _decal(vis, w.segment, mid, 0.03, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
		_add_jet(vis, w, mid, 1.0)
		return
	var pellet := _small_wound(w.kind)
	_decal(vis, w.segment, w.entry, 0.022 if pellet else 0.035, PixelArt.blood("wound_entry", 5, true, 16))
	w.stain = _decal(vis, w.segment, w.entry, 0.03 if pellet else 0.04, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
	if w.exit != null:
		_decal(vis, w.segment, w.exit, 0.035 if pellet else 0.06, PixelArt.blood("wound_exit", 9, true, 16))
	var through: bool = w.exit != null
	_add_jet(vis, w, w.entry, 0.5 if through else 1.0)
	if through:
		_add_jet(vis, w, w.exit, 0.5)


## Buckshot and blast splinters: many small holes at once.
static func _small_wound(kind: StringName) -> bool:
	return kind == &"pellet" or kind == &"splinter" or kind == &"gravel"


func _add_jet(vis: Node3D, w: Dictionary, local: Vector3, share: float) -> void:
	if w.bleeds.is_empty():
		return
	if _small_wound(w.kind):
		# Buckshot holes close together bleed as one: a pellet's bleeding joins a nearby pellet
		# wound's stream rather than starting its own (nine jets from one shot is a fountain).
		for other: Node in vis.get_children():
			if other is BloodJet and other.has_meta(&"pellets") and (other as Node3D).position.distance_to(local) < PELLET_JET_MERGE:
				var j := other as BloodJet
				for id: int in w.bleeds:
					if not j.bleed_ids.has(id):
						j.bleed_ids.append(id)
				w.get_or_add("jets", []).append(j)
				return
	var jet := BloodJet.new()
	if _small_wound(w.kind):
		jet.set_meta(&"pellets", true)
		jet.bleed_ids = (w.bleeds as Array).duplicate()
	jet.name = "BloodJet"
	jet.body = self
	if not jet.has_meta(&"pellets"):
		jet.bleed_ids = w.bleeds
	jet.share = share
	jet.position = local
	jet.basis = _along(_skin_normal(w.segment, local))
	vis.add_child(jet)
	w.get_or_add("jets", []).append(jet)


func _decal(parent: Node3D, seg: StringName, local: Vector3, size: float, tex: Texture2D) -> Decal:
	var d := Decal.new()
	d.texture_albedo = tex
	d.cull_mask = Layers.VIS_BODY
	d.size = Vector3(size, 0.08, size)
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	var n := _skin_normal(seg, local)
	d.basis = _along(n)
	d.position = local
	parent.add_child(d)
	return d


## Blood soaks outward from each wound as it bleeds.
func _update_stains() -> void:
	for w in wounds:
		var stain: Decal = w.stain
		if stain == null or not is_instance_valid(stain):
			continue
		var ml := physiology.blood_lost_from(w.bleeds)
		var s := clampf(0.04 + sqrt(ml) * 0.013, 0.04, 0.38)
		stain.size = Vector3(s, 0.08 + s * 0.3, s * 1.25)


## A pool spreads on the ground under him while he lies bleeding.
func _update_pool() -> void:
	if not physiology.alive and physiology.total_bleed_rate() < 0.01:
		return
	var rate := physiology.total_bleed_rate()
	if rate <= 0.05 and _pool == null:
		return
	_pool_ml += rate * get_physics_process_delta_time() * (_day_cycle.time_scale if _day_cycle else time_scale)
	var chest: Node3D = parts[&"abdomen"]
	if _pool == null:
		_pool = Decal.new()
		_pool.name = "BloodPool"
		_pool.texture_albedo = PixelArt.blood("pool", 21, false, 32)
		_pool.cull_mask = Layers.WORLD
		_pool.modulate = Color(0.75, 0.7, 0.7)
		_pool.top_level = true
		add_child(_pool)
	var r := clampf(sqrt(_pool_ml * 1e-6 / 0.002 / PI), 0.05, 1.1)
	_pool.global_position = Vector3(chest.global_position.x, chest.global_position.y, chest.global_position.z)
	_pool.global_rotation = Vector3.ZERO
	_pool.size = Vector3(r * 2.0, 1.0, r * 2.0)


func sever_finger(fid: StringName, dir: Vector3) -> void:
	var knuckle: Node3D = fingers.get(fid)
	if knuckle == null:
		return
	fingers.erase(fid)
	var rb := RigidBody3D.new()
	rb.name = "Finger_%s" % fid
	rb.mass = 0.02
	rb.collision_layer = Layers.BODY_PARTS
	rb.collision_mask = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.018, 0.07, 0.018)
	shape.shape = box
	shape.position = Vector3(0, -0.035, 0)
	var world := get_parent()
	world.add_child(rb)
	rb.global_transform = knuckle.global_transform
	rb.add_child(shape)
	knuckle.reparent(rb, true)
	rb.add_to_group(&"severed_parts")
	rb.apply_impulse(dir * 0.08 + Vector3(0, 0.05, 0))
	# The stump bleeds.
	_decal(visuals[&"hand_" + String(fid).right(1)], StringName("hand_" + String(fid).right(1)),
			knuckle.position, 0.03, PixelArt.blood("wound_entry", 5, true, 16))


func drop_gun() -> void:
	if held_gun == null:
		return
	var gun := held_gun
	held_gun = null
	var rb := RigidBody3D.new()
	rb.name = "DroppedGun"
	rb.mass = 1.1
	rb.collision_layer = Layers.DEBRIS
	rb.collision_mask = Layers.DEBRIS_MASK
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.04, 0.13, 0.3)
	shape.shape = box
	shape.position = Vector3(0, 0.0, -0.1)
	get_parent().add_child(rb)
	rb.global_transform = gun.global_transform
	rb.add_child(shape)
	gun.reparent(rb, true)
	rb.add_to_group(&"dropped_guns")
	curl_hand("r", 0.2)


# --- Falling -----------------------------------------------------------------------------------

## Let go: every segment becomes a rigid body joined to its parent, and physics takes over.
func go_limp(push := Vector3.ZERO) -> void:
	if limp:
		return
	limp = true
	var conscious := physiology.is_conscious()
	var joint_at := {}
	for sid: StringName in pivots:
		joint_at[sid] = (pivots[sid] as Node3D).global_position
	var bodies := {}
	for sid: StringName in anatomy.segments:
		var part: Node3D = parts[sid]
		var rb := RigidBody3D.new()
		rb.name = "Rag_%s" % sid
		rb.collision_layer = Layers.BODY_PARTS
		rb.collision_mask = Layers.WORLD
		rb.mass = part.get_meta(&"mass", 5.0)
		rb.linear_damp = 0.2
		rb.angular_damp = 2.0
		rb.set_meta(&"human_body", self)
		rb.set_meta(&"segment", sid)
		rb.set_meta(&"mass", rb.mass)
		var pm := PhysicsMaterial.new()
		pm.friction = 0.9
		pm.bounce = 0.0
		rb.physics_material_override = pm
		add_child(rb)
		rb.global_transform = part.global_transform
		for c in part.get_children():
			c.reparent(rb, true)
		bodies[sid] = rb
		parts[sid] = rb
	for sid: StringName in anatomy.segments:
		var parent: StringName = anatomy.segments[sid].parent
		if parent == &"":
			continue
		var key0 := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		if key0 == &"shin" or key0 == &"forearm":
			_hinge(sid, parent, bodies, joint_at[sid])
			continue
		var j := ConeTwistJoint3D.new()
		j.name = "Joint_%s" % sid
		add_child(j)
		var child_dir: Vector3 = (bodies[sid] as Node3D).global_position - joint_at[sid]
		var basis := _along(child_dir)
		j.global_transform = Transform3D(Basis(basis.y, basis.z, basis.x), joint_at[sid])
		j.node_a = j.get_path_to(bodies[parent])
		j.node_b = j.get_path_to(bodies[sid])
		var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		var lim: Array = JOINT_LIMITS.get(key, [30, 10])
		j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(lim[0]))
		j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(lim[1]))
	for sid: StringName in bodies:
		var rb: RigidBody3D = bodies[sid]
		rb.linear_velocity = push
	(bodies[&"chest"] as RigidBody3D).apply_central_impulse(push * 4.0 + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3)))
	_rig.queue_free()
	pivots.clear()
	_blocker.queue_free()
	fell.emit(conscious)
	Events.person_fell.emit(self, conscious)


# --- Blasts ------------------------------------------------------------------------------------

const LIMBS := [["hand", "forearm", "upper_arm"], ["foot", "shin", "thigh"]]


## Caught by a charge of `kg` TNT going off at `at`: the pressure at each part of him (less behind
## a wall), then ears, lungs and head, burns in the fireball, parts torn open, limbs torn off at
## the joint, and thrown down by the blast wind.
func take_blast(at: Vector3, kg: float, _held := false) -> Dictionary:
	var bt := Blast.t()
	var kpa := {}
	var exclude: Array[RID] = []
	for sid: StringName in parts:
		exclude.append((parts[sid] as CollisionObject3D).get_rid())
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	var chest: Vector3 = (parts[&"chest"] as Node3D).global_position
	var shield := Blast.shielding(get_parent() as Node3D, at, chest, exclude)
	for sid: StringName in parts:
		var part := parts[sid] as Node3D
		if part == null or not is_instance_valid(part) or physiology.severed_segments.has(sid):
			continue
		kpa[sid] = Blast.overpressure_kpa(kg, _distance_to_part(sid, at)) * shield
	var harm := physiology.blast_injury(kpa.get(&"head", 0.0), kpa.get(&"chest", 0.0), kpa.get(&"head", 0.0), bt, _rng)
	if chest.distance_to(at) < Blast.fireball_radius(kg):
		physiology.burn(bt.burn_in_fireball)
		harm.append("burnt")
	# Torn open where the pressure was worst.
	for sid: StringName in kpa:
		var p: float = kpa[sid]
		if p > bt.open_kpa:
			var part := parts[sid] as Node3D
			var local := part.global_transform.affine_inverse() * at
			var toward := local.normalized() if local.length() > 0.001 else Vector3.FORWARD
			var skin := toward * float(anatomy.segments[sid].radius)
			open_wound(sid, skin, minf((p - bt.open_kpa) * bt.open_joules_per_kpa, 3000.0), (part.global_position - at).normalized())
	# Limbs: the most of each arm and leg the blast can take.
	var torn_off: Array[StringName] = []
	for side in ["r", "l"]:
		for chain: Array in LIMBS:
			var take := &""
			for kind: String in chain:
				var sid := StringName(kind + "_" + side)
				if kpa.get(sid, 0.0) > float(bt.sever_kpa.get(kind, INF)):
					take = sid
			if take != &"":
				torn_off.append(take)
	var dir := (chest - at).normalized()
	var r := maxf(chest.distance_to(at), 0.05)
	var speed := Blast.impulse(kg, r) * shield * 0.7 * bt.throw_factor / maxf(_body_mass(), 1.0)
	var push := (dir + Vector3.UP * 0.35).normalized() * minf(speed, bt.max_throw)
	var down: bool = kpa.get(&"chest", 0.0) > bt.knockdown_kpa or speed > bt.knockdown_speed or not torn_off.is_empty()
	if down:
		harm.append("thrown off his feet")
	if down and not limp:
		go_limp(push)
	elif limp:
		for sid: StringName in parts:
			var rb := parts[sid] as RigidBody3D
			if rb:
				rb.linear_velocity += push * clampf(kpa.get(sid, 0.0) / maxf(kpa.get(&"chest", 1.0), 1.0), 0.3, 3.0)
	else:
		_flinch_from(&"chest", chest, dir, speed * 2.0)
	for sid in torn_off:
		sever_limb(sid, push * 2.0 + dir * 3.0)
		harm.append("%s torn off" % _place(sid))
	var w := {"segment": &"chest", "entry": Vector3.ZERO, "exit": null, "lodged": false, "hits": [],
			"bleeds": [], "garments": [], "stain": null, "kind": &"blast", "dir": dir, "harm": harm,
			"kpa": kpa.get(&"chest", 0.0)}
	wounds.append(w)
	var info := {"person": self, "person_id": person_id, "segment": &"chest", "hits": [], "position": chest,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blast", "harm": harm,
			"kpa": kpa.get(&"chest", 0.0), "knocked_down": down}
	hit.emit(info)
	Events.body_hit.emit(info)
	return info


func _body_mass() -> float:
	var m := 0.0
	for sid: StringName in parts:
		m += float((parts[sid] as Node).get_meta(&"mass", 5.0))
	return m


## Distance from a point to a body part's skin (nearest capsule surface).
func _distance_to_part(sid: StringName, point: Vector3) -> float:
	var part := parts[sid] as Node3D
	var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(sid)
	var best := INF
	for c: Array in anatomy.segments[sid].capsules:
		var a: Vector3 = c[0]
		var ab: Vector3 = (c[1] as Vector3) - a
		var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, local.distance_to(a + ab * t) - float(c[2]))
	return maxf(best, 0.02)


## Tear a limb off at the joint above `segment` (it and everything below it go): he goes down, the
## joint lets go, the stump opens and bleeds hard, and the limb flies.
func sever_limb(segment: StringName, push := Vector3.ZERO) -> void:
	if physiology.severed_segments.has(segment):
		return
	if not limp:
		go_limp(push * 0.3)
	var parent: StringName = anatomy.segments[segment].parent
	var joint := get_node_or_null(NodePath("Joint_%s" % segment)) as Node3D
	var at: Vector3 = joint.global_position if joint else (parts[segment] as Node3D).global_position
	var first := physiology.bleeds.size()
	physiology.sever(segment)
	_stop_skinning_across_joints()
	if joint:
		joint.queue_free()
	for sid in anatomy.segments_below(segment):
		var rb := parts.get(sid) as RigidBody3D
		if rb:
			rb.linear_velocity += push
			rb.angular_velocity += Vector3(_rng.randf_range(-8, 8), _rng.randf_range(-8, 8), _rng.randf_range(-8, 8))
	# The stump and the torn end of the limb.
	var parent_part := parts[parent] as Node3D
	open_wound(parent, parent_part.global_transform.affine_inverse() * at, 2200.0)
	var limb_part := parts[segment] as Node3D
	open_wound(segment, limb_part.global_transform.affine_inverse() * at, 2200.0)
	var w := {"segment": parent, "part": segment, "entry": parent_part.global_transform.affine_inverse() * at,
			"exit": null, "lodged": false, "hits": [], "bleeds": range(first, physiology.bleeds.size()),
			"garments": [], "stain": null, "kind": &"severed", "dir": push.normalized()}
	wounds.append(w)
	_add_jet(visuals[parent], w, w.entry, 1.0)
	if get_parent() is Node3D:
		ImpactEffects.burst(get_parent(), at, push.normalized(), Blood.ARTERIAL, 16, 3.0, 0.02)
		Blood.spray(get_parent() as Node3D, at, push.normalized(), 60.0, 8, _rng)
	if segment.begins_with("hand") or segment.begins_with("forearm") or segment.begins_with("upper_arm"):
		if held_gun and String(segment).ends_with("_r"):
			drop_gun()


## Knees and elbows are hinges: a knee only bends back, an elbow only forward, however he falls.
## The limits are measured from how bent the joint is as he goes limp.
const KNEE_BEND := 150.0
const ELBOW_BEND := 150.0


func _hinge(sid: StringName, parent: StringName, bodies: Dictionary, at: Vector3) -> void:
	var j := HingeJoint3D.new()
	j.name = "Joint_%s" % sid
	add_child(j)
	# The hinge turns about its Z: lay that along his right (the parent's X), Y down the limb.
	var right := (bodies[parent] as Node3D).global_basis.x.normalized()
	var down := ((bodies[sid] as Node3D).global_position - at).normalized()
	down = (down - right * down.dot(right)).normalized()
	j.global_transform = Transform3D(Basis(down.cross(right), down, right), at)
	j.node_a = j.get_path_to(bodies[parent])
	j.node_b = j.get_path_to(bodies[sid])
	var now: float = (_pose_now.get(sid, Vector3.ZERO) as Vector3).x
	var lower := 0.0
	var upper := 0.0
	# The hinge's angle runs opposite to the poses' X (measured from where the joint is now).
	if String(sid).begins_with("shin"):
		# A knee bends with -X in the poses: from straight to fully bent.
		lower = now
		upper = KNEE_BEND + now
	else:
		lower = now - ELBOW_BEND
		upper = now
	j.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	j.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(lower))
	j.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper))


# --- Openings: bad wounds show what's inside --------------------------------------------------

## A torn opening this big shows at the first; energy piles up where hits land close together.
const OPEN_MIN_RADIUS := 0.018
const OPEN_PER_SQRT_JOULE := 0.0013
const OPEN_MERGE := 0.06
## An opening with this much energy in it has destroyed the region: the bone in it is smashed and
## thrown out as fragments (point-blank buckshot, a blast; a single ball never gets there).
const DESTROY_ENERGY := 1000.0
const MAX_FRAGMENTS := 40
## Below this, buckshot is a pellet (the ball of a .45 is 16.5 g).
const PELLET_MASS := 0.006
## Pellet wounds this close share one blood stream.
const PELLET_JET_MERGE := 0.07

var _fragments := 0


func _use_wound_materials() -> void:
	for sid: StringName in visuals:
		for mi: MeshInstance3D in (visuals[sid] as Node3D).find_children("*", "MeshInstance3D", true, false):
			if mi.layers == Layers.VIS_BODY and mi.material_override is StandardMaterial3D:
				mi.material_override = BodyInterior.skin_material(mi.material_override as StandardMaterial3D)


func _on_settings_changed() -> void:
	for sid: StringName in openings:
		_apply_openings(sid)


## Tear the body open at a point (segment-centred rest space) with `energy` joules of damage:
## bullets dumping their energy, a blast, point-blank buckshot. Close hits add up; past
## DESTROY_ENERGY the region is destroyed and the bone in it flies out along `dir` (world).
func open_wound(segment: StringName, at: Vector3, energy: float, dir := Vector3.ZERO) -> Dictionary:
	var list: Array = openings.get_or_add(segment, [])
	var o: Dictionary = {}
	for existing: Dictionary in list:
		if (existing.at as Vector3).distance_to(at) < OPEN_MERGE:
			o = existing
			break
	if o.is_empty():
		o = {"at": at, "energy": 0.0, "radius": 0.0}
		list.append(o)
	var old_at: Vector3 = o.at
	var old_radius: float = o.radius if o.get("destroyed", false) else 0.0
	var total: float = o.energy + energy
	o.at = (o.at as Vector3).lerp(at, energy / maxf(total, 0.001))
	o.energy = total
	var cap: float = float(anatomy.segments[segment].radius) * 1.2
	o.radius = minf(OPEN_PER_SQRT_JOULE * sqrt(total), cap)
	if o.radius >= OPEN_MIN_RADIUS:
		_apply_openings(segment)
	if total >= DESTROY_ENERGY:
		o.destroyed = true
		_smash_bone(segment, o.at, o.radius, old_at, old_radius, dir)
	return o


## The bone that was inside a destroyed opening and isn't now: broken in the anatomy, and thrown
## out as fragments (rigid pieces that stay where they land).
func _smash_bone(segment: StringName, at: Vector3, radius: float, old_at: Vector3, old_radius: float, dir: Vector3) -> void:
	var center := anatomy.segment_center(segment)
	var gone: Array[Vector3] = []
	for st: Dictionary in anatomy.by_segment.get(segment, []):
		if st.kind != &"bone":
			continue
		var pts := BodyInterior.bone_points(st)
		var hit := false
		for p: Vector3 in pts:
			var local := p - center
			if local.distance_to(at) < radius:
				hit = true
				if old_radius <= 0.0 or local.distance_to(old_at) >= old_radius:
					gone.append(local)
		if hit and not physiology.broken.has(st.id):
			physiology.break_bone(st.id)
	var part: Node3D = parts.get(segment)
	var world := get_parent() as Node3D
	if part == null or world == null or gone.is_empty():
		return
	var fly := dir.normalized() if dir.length() > 0.01 else -part.global_basis.z
	var every := maxi(1, gone.size() / 8)
	for i in range(0, gone.size(), every):
		if _fragments >= MAX_FRAGMENTS:
			break
		_fragments += 1
		var from: Vector3 = part.global_transform * gone[i]
		var out := (from - part.global_transform * at).normalized()
		var v := fly * _rng.randf_range(1.5, 5.0) + out * _rng.randf_range(0.5, 2.5) + Vector3.UP * _rng.randf_range(0.0, 1.5)
		ImpactEffects.bone_fragment(world, from, v, _rng)


## The same, from a world point on one of the body's parts.
func open_wound_at(collider: Node3D, point: Vector3, energy: float) -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment", &"") if collider else &""
	if seg == &"":
		seg = segment_at(point)
	var part: Node3D = parts[seg]
	return open_wound(seg, part.global_transform.affine_inverse() * point, energy)


func is_open(segment: StringName) -> bool:
	for o: Dictionary in openings.get(segment, []):
		if o.radius >= OPEN_MIN_RADIUS:
			return true
	return false


func _apply_openings(segment: StringName) -> void:
	var vis: Node3D = visuals.get(segment)
	if vis == null:
		return
	var list: Array[Vector4] = []
	for o: Dictionary in openings.get(segment, []):
		if o.radius >= OPEN_MIN_RADIUS:
			var at: Vector3 = o.at
			list.append(Vector4(at.x, at.y, at.z, o.radius))
	if list.is_empty():
		return
	if vis.get_node_or_null(^"Inside") == null:
		BodyInterior.build(segment, vis, anatomy)
	BodyInterior.apply(vis, list, Settings.reduced_gore)
	# The generated skin and clothes: openings are already in the part's rest space.
	var arr := PackedVector4Array(list)
	while arr.size() < BodyInterior.MAX_OPENINGS:
		arr.append(Vector4.ZERO)
	for mi: MeshInstance3D in segment_pieces.get(segment, []):
		var m := mi.material_override as ShaderMaterial
		m.set_shader_parameter(&"wound_count", mini(list.size(), BodyInterior.MAX_OPENINGS))
		m.set_shader_parameter(&"wounds", arr)
		m.set_shader_parameter(&"reduced_gore", Settings.reduced_gore)


# --- X-ray (debug, F10) -------------------------------------------------------------------------

const XRAY_COLOURS := {
	&"bone": Color(0.95, 0.92, 0.8, 0.95), &"finger": Color(0.95, 0.92, 0.8, 0.95),
	&"artery": Color(0.95, 0.12, 0.1, 0.95), &"vein": Color(0.25, 0.38, 0.95, 0.95),
	&"organ": Color(0.9, 0.5, 0.6, 0.75), &"muscle": Color(0.7, 0.25, 0.22, 0.2),
	&"nerve": Color(1.0, 0.9, 0.25, 0.95),
}
const XRAY_ORDER := {&"muscle": 0, &"organ": 1, &"bone": 2, &"finger": 2, &"vein": 3, &"artery": 3, &"nerve": 4}

## Everyone new comes in with X-ray on if it's on.
static var xray_all := false
static var _xray_mats := {}


## See through the skin and clothes to the anatomy: bones, arteries (red), veins (blue), organs,
## muscles (faint), nerves (yellow). Anything damaged shows orange; each ball's track is a line.
func set_xray(on: bool) -> void:
	xray = on
	for mi: MeshInstance3D in skin_meshes.values():
		mi.transparency = 0.88 if on else 0.0
	for sid: StringName in visuals:
		var vis: Node3D = visuals[sid]
		var old := vis.get_node_or_null(^"XRay")
		if old:
			old.free()
		for mi in vis.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).transparency = 0.88 if on else 0.0
		if held_gun:
			for mi in held_gun.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).transparency = 0.0
		if not on:
			continue
		var root := Node3D.new()
		root.name = "XRay"
		vis.add_child(root)
		var center := anatomy.segment_center(sid)
		for st: Dictionary in anatomy.by_segment.get(sid, []):
			if st.kind == &"finger" and physiology.lost_fingers.has(st.id):
				continue
			var damaged: bool = physiology.broken.has(st.id) or physiology.cut.has(st.id) \
					or physiology.torn.has(st.id) or physiology.muscle_damage.has(st.id)
			var shell: bool = st.get(&"shell", 0.0) > 0.0
			var colour: Color = XRAY_COLOURS.get(st.kind, Color.WHITE)
			if shell:
				colour.a = 0.22
			if damaged:
				colour = Color(1.0, 0.6, 0.05, 0.3 if shell else 0.95)
			var mi := MeshInstance3D.new()
			var length: float = ((st.b as Vector3) - (st.a as Vector3)).length()
			if length < 0.001:
				var sm := SphereMesh.new()
				sm.radius = st.radius
				sm.height = st.radius * 2.0
				sm.radial_segments = 10
				sm.rings = 5
				mi.mesh = sm
			else:
				var cm := CapsuleMesh.new()
				cm.radius = st.radius
				cm.height = length + st.radius * 2.0
				cm.radial_segments = 8
				cm.rings = 1
				mi.mesh = cm
				mi.basis = _along((st.b as Vector3) - (st.a as Vector3))
			mi.position = ((st.a as Vector3) + (st.b as Vector3)) * 0.5 - center
			mi.material_override = _xray_material(colour, int(XRAY_ORDER.get(st.kind, 1)) + (5 if damaged else 0))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
		for w in wounds:
			if w.segment != sid:
				continue
			var end: Variant = w.exit if w.exit != null else w.stop
			if end == null:
				continue
			var a: Vector3 = w.entry
			var b: Vector3 = end
			var line := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.003
			cyl.bottom_radius = 0.003
			cyl.height = maxf(a.distance_to(b), 0.005)
			cyl.radial_segments = 4
			line.mesh = cyl
			line.basis = _along(b - a)
			line.position = (a + b) * 0.5
			line.material_override = _xray_material(Color(1.0, 1.0, 0.4, 1.0), 12)
			root.add_child(line)


static func _xray_material(colour: Color, order: int) -> StandardMaterial3D:
	var key := "%s/%d" % [colour.to_html(), order]
	if not _xray_mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = colour
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.render_priority = order
		_xray_mats[key] = m
	return _xray_mats[key]


# --- Saving and describing ---------------------------------------------------------------------

func describe_wounds() -> PackedStringArray:
	var out: PackedStringArray = []
	var groups := {}  # [kind, segment] -> [wounds]
	for w in wounds:
		var kind: StringName = w.get("kind", &"bullet")
		if _small_wound(kind):
			groups.get_or_add([kind, w.segment], []).append(w)
			continue
		if kind == &"severed":
			out.append("%s: torn off at the joint, the stump bleeding" % _place(w.get("part", w.segment)))
			continue
		if kind == &"blast":
			if not (w.harm as PackedStringArray).is_empty():
				out.append("blast: %s" % ", ".join(w.harm))
			continue
		out.append("%s: %s" % [_place(w.segment), _describe_one(w)])
	# Buckshot and splinters: one line per part, however many.
	for key: Array in groups:
		var list: Array = groups[key]
		var seg: StringName = key[1]
		var lodged := list.filter(func(w: Dictionary) -> bool: return w.lodged).size()
		var what: PackedStringArray = []
		for w: Dictionary in list:
			for x in _hit_words(w):
				if not what.has(x):
					what.append(x)
		var how := ""
		if key[0] == &"pellet":
			how = "buckshot, %d pellet%s" % [list.size(), "s" if list.size() > 1 else ""]
		elif key[0] == &"gravel":
			how = "gravel and grit from a blast, %d" % list.size()
		else:
			how = "blast splinters, %d" % list.size()
		if lodged > 0:
			how += ", %d still in" % lodged
		out.append("%s: %s%s" % [_place(seg), how, (" — " + ", ".join(what)) if not what.is_empty() else ""])
	for seg: StringName in openings:
		for o: Dictionary in openings[seg]:
			if o.get("destroyed", false):
				out.append("%s: torn wide open, the bone smashed" % _place(seg))
				break
	return out


func _place(seg: StringName) -> String:
	return String(seg).replace("_r", " (right)").replace("_l", " (left)").replace("_", " ")


func _describe_one(w: Dictionary) -> String:
	var what := _hit_words(w)
	var how := "through and through" if not w.lodged else "no exit, ball still in"
	match w.get("kind", &"bullet"):
		&"graze":
			how = "a graze, a bloody furrow"
		&"cut":
			how = "glass cut" + (", a shard still in it" if w.get("embedded", false) else "")
	return "%s%s" % [how, (" — " + ", ".join(what)) if not what.is_empty() else ""]


func _hit_words(w: Dictionary) -> PackedStringArray:
	var what: PackedStringArray = []
	for h: Dictionary in w.hits:
		match h.effect:
			&"broken":
				what.append("%s broken" % String(h.id).get_slice("_", 0))
			&"stopped":
				what.append("ball lodged against the %s" % String(h.id).get_slice("_", 0))
			&"cut":
				what.append("%s artery cut" % String(h.id).get_slice("_", 0))
			&"torn":
				what.append("%s torn" % String(h.id).get_slice("_", 0))
			&"severed":
				what.append("%s finger off" % String(h.id).get_slice("_", 0))
	return what


func to_dict() -> Dictionary:
	var ws := []
	for w in wounds:
		ws.append({"segment": w.segment, "entry": w.entry, "exit": w.exit, "lodged": w.lodged,
				"hits": w.hits, "bleeds": w.bleeds, "garments": w.garments,
				"kind": w.get("kind", &"bullet"), "embedded": w.get("embedded", false),
				"part": w.get("part", &""), "harm": w.get("harm", PackedStringArray())})
	var gs := {}
	for g in garments:
		gs[g.id] = g.holes.duplicate(true)
	var ops := {}
	for sid: StringName in openings:
		ops[String(sid)] = (openings[sid] as Array).map(func(o: Dictionary) -> Dictionary:
			return {"at": [o.at.x, o.at.y, o.at.z], "energy": o.energy, "radius": o.radius})
	return {"person_id": person_id, "physiology": physiology.to_dict(), "wounds": ws, "openings": ops,
			"garment_holes": gs, "limp": limp, "gun_dropped": has_gun and held_gun == null}
