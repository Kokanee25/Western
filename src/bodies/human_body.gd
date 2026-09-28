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

const POSES := {
	&"stand": {&"upper_arm_r": Vector3(0, 0, 7), &"upper_arm_l": Vector3(0, 0, -7),
			&"forearm_r": Vector3(12, 0, 0), &"forearm_l": Vector3(12, 0, 0)},
	&"aim": {&"upper_arm_r": Vector3(84, 10, 0), &"forearm_r": Vector3(4, 0, 0),
			&"upper_arm_l": Vector3(0, 0, -7), &"forearm_l": Vector3(12, 0, 0), &"chest": Vector3(0, 8, 0)},
	&"hands_up": {&"upper_arm_r": Vector3(0, 0, 150), &"forearm_r": Vector3(0, 0, 25),
			&"upper_arm_l": Vector3(0, 0, -150), &"forearm_l": Vector3(0, 0, -25), &"head": Vector3(8, 0, 0)},
	&"clutch": {&"upper_arm_r": Vector3(30, 0, 12), &"forearm_r": Vector3(75, -30, 0),
			&"upper_arm_l": Vector3(30, 0, -12), &"forearm_l": Vector3(75, 30, 0),
			&"chest": Vector3(18, 0, 0), &"head": Vector3(15, 0, 0)},
}
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
@export var hat_color := Color(0.18, 0.14, 0.11)
@export var has_gun := true
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
var xray := false
var _pool: Decal
var _pool_ml := 0.0
var _day_cycle: Node


func _ready() -> void:
	add_to_group(&"people")
	_rng.seed = rng_seed
	anatomy = Anatomy.shared()
	physiology = Physiology.new(null, anatomy)
	_dress()
	_build()
	if has_gun:
		_give_gun()
	_apply_pose(0.0, true)
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
	_blocker = StaticBody3D.new()
	_blocker.name = "Blocker"
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
	var s: Dictionary = anatomy.segments[sid]
	var center := anatomy.segment_center(sid)
	var name_s := String(sid)
	if name_s.begins_with("hand"):
		_build_hand(sid, vis, center)
		return
	var mat := _material_for(sid)
	if name_s.begins_with("foot"):
		var boot := _box(vis, "Boot", Vector3(0.1, 0.1, 0.27), Vector3(0, 0, -0.02), outer_garment(sid).get("color", Color.BROWN))
		boot.material_override = _material_for(sid)
		return
	for i in s.capsules.size():
		var c: Array = s.capsules[i]
		var mesh := CapsuleMesh.new()
		mesh.radius = c[2]
		mesh.height = ((c[1] as Vector3) - (c[0] as Vector3)).length() + 2.0 * float(c[2])
		mesh.radial_segments = 8
		mesh.rings = 2
		var mi := MeshInstance3D.new()
		mi.name = "Mesh%d" % i
		mi.mesh = mesh
		mi.material_override = mat
		mi.basis = _along((c[1] as Vector3) - (c[0] as Vector3))
		mi.position = ((c[0] as Vector3) + (c[1] as Vector3)) * 0.5 - center
		mi.layers = Layers.VIS_BODY
		vis.add_child(mi)
	if name_s.begins_with("shin"):
		# Boot tops over the lower leg.
		var top := _cylinder(vis, "BootTop", s.radius + 0.008, 0.2, Vector3(0, -0.1, 0), Color(0.2, 0.13, 0.08))
		top.material_override = GunParts.cloth("%s:boots" % person_id, Color(0.2, 0.13, 0.08))
	match sid:
		&"head":
			_build_face(vis, center)
		&"pelvis":
			var belt := _cylinder(vis, "GunBelt", 0.165, 0.05, Vector3(0, 0.02, 0), Color(0.32, 0.2, 0.1))
			belt.scale = Vector3(1.28, 1, 1)
			_box(vis, "Holster", Vector3(0.05, 0.2, 0.08), Vector3(0.2, -0.08, 0.0), Color(0.36, 0.23, 0.12))
		&"neck":
			_cylinder(vis, "Bandana", 0.07, 0.06, Vector3(0, -0.01, 0), Color(0.55, 0.12, 0.1))


func _build_face(vis: Node3D, center: Vector3) -> void:
	var o := -center
	var dark := Color(0.08, 0.06, 0.05)
	var hair := Color(0.25, 0.17, 0.1)
	for side in [-1.0, 1.0]:
		_box(vis, "Eye", Vector3(0.02, 0.01, 0.01), o + Vector3(0.036 * side, 1.655, -0.092), dark)
		_box(vis, "Brow", Vector3(0.03, 0.009, 0.012), o + Vector3(0.036 * side, 1.672, -0.093), hair)
	_box(vis, "Nose", Vector3(0.02, 0.04, 0.03), o + Vector3(0, 1.632, -0.1), skin_tone.darkened(0.08))
	_box(vis, "Moustache", Vector3(0.075, 0.018, 0.02), o + Vector3(0, 1.604, -0.095), hair)
	_box(vis, "Stubble", Vector3(0.12, 0.05, 0.05), o + Vector3(0, 1.57, -0.07), skin_tone.darkened(0.25))
	_box(vis, "Hair", Vector3(0.19, 0.06, 0.16), o + Vector3(0, 1.69, 0.03), hair)
	var brim := _cylinder(vis, "HatBrim", 0.17, 0.012, o + Vector3(0, 1.745, 0.0), hat_color)
	brim.scale = Vector3(1.0, 1.0, 1.12)
	_cylinder(vis, "HatCrown", 0.095, 0.11, o + Vector3(0, 1.8, 0.0), hat_color)
	_cylinder(vis, "HatBand", 0.097, 0.018, o + Vector3(0, 1.758, 0.0), hat_color.darkened(0.5))


## The hand: palm, then each finger as three bones from its knuckle, following the anatomy.
func _build_hand(sid: StringName, vis: Node3D, center: Vector3) -> void:
	var side := String(sid).right(1)
	var skin := _skin()
	var palm := MeshInstance3D.new()
	palm.name = "Palm"
	var pm := BoxMesh.new()
	pm.size = Vector3(0.032, 0.085, 0.085)
	palm.mesh = pm
	palm.material_override = skin
	palm.layers = Layers.VIS_BODY
	var sx := 1.0 if side == "r" else -1.0
	palm.position = Vector3(0.24 * sx, 0.815, -0.012) - center
	vis.add_child(palm)
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
			var bm := BoxMesh.new()
			bm.size = Vector3(w, l, w)
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
		if not physiology.can_stand():
			go_limp()
	if held_gun != null and not physiology.can_hold("r"):
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
	if POSES.has(p):
		pose = p


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
	for sid: StringName in pivots:
		var goal: Vector3 = target.get(sid, Vector3.ZERO)
		if sid == &"upper_arm_r" and pose == &"aim":
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
	if held_gun != null:
		curl_hand("r", 0.85)


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
## {segment, exit (world Vector3 or null), energy_out, hits, wound}.
func take_bullet(collider: Node3D, pos: Vector3, dir: Vector3, energy: float, bullet_radius: float, mass := 0.0165) -> Dictionary:
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
			"bleeds": bleeds, "garments": holed, "stain": null}
	wounds.append(wound)
	_paint_wound(wound)
	for h: Dictionary in tr.hits:
		if h.effect == &"severed":
			sever_finger(h.id, dir)
	var deposited := maxf(energy - tr.energy_out, 0.0)
	var severe := false
	for h: Dictionary in tr.hits:
		if h.effect == &"broken" or (h.kind == &"organ") or (h.kind == &"artery"):
			severe = true
	var speed := sqrt(2.0 * deposited / maxf(mass, 0.001))
	var knocked := not limp and _knocked_down(seg, deposited, severe)
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
			"deposited": deposited, "severe": severe, "knocked_down": knocked}
	hit.emit(info)
	Events.body_hit.emit(info)
	if xray:
		set_xray(true)
	return {"segment": seg, "exit": exit_world, "energy_out": tr.energy_out, "hits": tr.hits, "wound": wound}


## Does the hit itself put him down? A heavy ball dumping its energy in the trunk often does.
func _knocked_down(seg: StringName, deposited: float, severe: bool) -> bool:
	var s := String(seg)
	if not (seg in [&"chest", &"abdomen", &"pelvis", &"head", &"neck"] or s.begins_with("thigh")):
		return false
	var t := physiology.tuning
	var chance := maxf(deposited - t.knockdown_energy, 0.0) / 100.0 * t.knockdown_per_100j
	if severe:
		chance += t.knockdown_severe
	return _rng.randf() < minf(chance, t.knockdown_max)


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
	_decal(vis, w.segment, w.entry, 0.035, PixelArt.blood("wound_entry", 5, true, 16))
	w.stain = _decal(vis, w.segment, w.entry, 0.04, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
	if w.exit != null:
		_decal(vis, w.segment, w.exit, 0.06, PixelArt.blood("wound_exit", 9, true, 16))
	var through: bool = w.exit != null
	_add_jet(vis, w, w.entry, 0.5 if through else 1.0)
	if through:
		_add_jet(vis, w, w.exit, 0.5)


func _add_jet(vis: Node3D, w: Dictionary, local: Vector3, share: float) -> void:
	if w.bleeds.is_empty():
		return
	var jet := BloodJet.new()
	jet.name = "BloodJet"
	jet.body = self
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
	rb.collision_layer = Layers.WORLD
	rb.collision_mask = Layers.WORLD
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
	for w in wounds:
		var place := String(w.segment).replace("_r", " (right)").replace("_l", " (left)").replace("_", " ")
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
		var how := "through and through" if not w.lodged else "no exit, ball still in"
		out.append("%s: %s%s" % [place, how, (" — " + ", ".join(what)) if not what.is_empty() else ""])
	return out


func to_dict() -> Dictionary:
	var ws := []
	for w in wounds:
		ws.append({"segment": w.segment, "entry": w.entry, "exit": w.exit, "lodged": w.lodged,
				"hits": w.hits, "bleeds": w.bleeds, "garments": w.garments})
	var gs := {}
	for g in garments:
		gs[g.id] = g.holes.duplicate(true)
	return {"person_id": person_id, "physiology": physiology.to_dict(), "wounds": ws,
			"garment_holes": gs, "limp": limp, "gun_dropped": has_gun and held_gun == null}
