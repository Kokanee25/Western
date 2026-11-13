extends RefCounted
## The first-person rig posed per gun from data (#896): a pose file (poses/<gun>.json) names, per
## pose, the gun's state (driven through the gun lab's own rig: saa_rig.gd, win73_rig.gd), where the
## gun hangs under the camera, and where each hand holds it (fp_arms.gd, or today's HeldHand for the
## side-by-side). The gun's rig drives the hands: a hand `in` a moving part (the Winchester's lever)
## rides that part, and the poses change with the gun's state. Recoil stays procedural: the game's
## GunKick spring on the held node (`fire()`, `step()`), as the viewmodels do.
## A lab's: nothing in the game uses it. Untyped where it touches game classes.

var data: Dictionary
var gun: Node3D
var rig            # the gun lab's rig (saa_rig.gd / win73_rig.gd)
var held: Node3D   # under the camera: the gun hangs from it
var cam: Camera3D
var arms           # fp_arms.gd (new) or null
var held_hands := {}   # "r"/"l" -> HeldHand (the baseline), when `arms` is null
var kick
var pose_name := ""
var _held_base := Transform3D.IDENTITY
var _round: MeshInstance3D


func _init(pose_path: String, camera: Camera3D, fp_arms) -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(pose_path))
	cam = camera
	held = Node3D.new()
	held.name = "Held"
	cam.add_child(held)
	gun = (load(data["gun"]) as PackedScene).instantiate()
	held.add_child(gun)
	rig = load(data["rig"]).new(gun, data["rig_json"])
	arms = fp_arms
	kick = load("res://src/weapons/gun_kick.gd").new()
	var k: Dictionary = data.get("kick", {})
	kick.rise = float(k.get("rise", 0.07))
	kick.damping = float(k.get("damping", 0.6))
	# A cartridge for the reloads (a brass case and its lead), held in the right hand's fingers.
	_round = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0057
	cyl.bottom_radius = 0.0057
	cyl.height = 0.033
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.72, 0.55, 0.28)
	brass.metallic = 0.85
	brass.roughness = 0.35
	cyl.material = brass
	_round.mesh = cyl
	_round.visible = false
	held.add_child(_round)


func poses() -> Array:
	return (data["poses"] as Dictionary).keys()


func marker(n: String) -> Vector3:
	var p: Array = rig.rig["markers"][n]
	return Vector3(p[0], p[1], p[2])


## Sets everything for pose `n`: the gun's state, where it hangs, both hands.
func set_pose(n: String) -> void:
	pose_name = n
	var p: Dictionary = data["poses"][n]
	_gun_state(p.get("gun", {}))
	cam.fov = float(p.get("fov", 75.0))
	_hang(p["held"])
	held.transform = _held_base
	_round.visible = false
	for s in ["r", "l"]:
		_hand(s, hand_data(p, s))


## A pose's hand: a named hand from `hands`, or one built on a named hand (`base`) with its own changes.
func hand_data(p: Dictionary, s: String):
	var h = p.get(s)
	if h is String:
		return data["hands"][h]
	if h is Dictionary and h.has("base"):
		var merged: Dictionary = (data["hands"][h["base"]] as Dictionary).duplicate(true)
		for key in h:
			if key != "base":
				merged[key] = h[key]
		return merged
	return h


func _gun_state(g: Dictionary) -> void:
	# Back to rest first, then what's asked (the order matters: the lever cocks the hammer).
	if rig.has_method("lever"):
		rig.lever(0.0)
		rig.cover(0.0)
		rig.gate(0.0)
		rig.carrier_round("empty")
		rig.chamber("empty")
	else:
		rig.gate(0.0)
		rig.ejector(0.0)
		rig.cylinder(0.0)
		for k in 6:
			rig.chamber(k, "loaded")
	rig.hammer("rest")
	for key in g:
		var v = g[key]
		match key:
			"hammer":
				rig.hammer(v if v is String else float(v))
			"lever":
				rig.lever(float(v))
			"gate":
				rig.gate(float(v))
			"ejector":
				rig.ejector(float(v))
			"to_gate":
				rig.to_gate(int(v))
			"chamber0":
				rig.chamber(0, v)
			"chamber":
				rig.chamber(v)
			"carrier_round":
				rig.carrier_round(v)
			"cover":
				rig.cover(float(v))


## Where the gun hangs under the camera: down the sights (`sights`: the eye that far behind the
## rear sight on the line of sight), or a gun point (`marker` or `point`) at `at` turned by `rot`.
func _hang(h: Dictionary) -> void:
	if h.has("sights"):
		var rear := marker("SightRear")
		var front := marker("SightFront")
		var los := (front - rear).normalized()
		var b := Basis.looking_at(los, Vector3.UP).inverse()
		_held_base = Transform3D(b, -(b * rear) + Vector3(0.0, 0.0, -float(h["sights"])))
		return
	var r: Array = h.get("rot", [0, 0, 0])
	var b := Basis.from_euler(Vector3(deg_to_rad(r[0]), deg_to_rad(r[1]), deg_to_rad(r[2])))
	var pt := marker(h["marker"]) if h.has("marker") else _v(h.get("point", [0, 0, 0]))
	_held_base = Transform3D(b, _v(h["at"]) - b * pt)


func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


## A hand from data, placed in the gun's space (or a moving part's: `in`), aimed at its elbow.
func _hand(s: String, h) -> void:
	if arms:
		arms.reset(s)
	elif held_hands.has(s):
		(held_hands[s] as Node3D).visible = h != null
	if h == null:
		return
	var space: Node3D = gun
	if h.has("in"):
		space = gun.find_child(h["in"], true, false)
	var g := space.global_transform
	var at: Vector3 = g * _v(h["at"])
	var along: Vector3 = g.basis * _v(h["along"])
	var palm: Vector3 = g.basis * _v(h["palm"])
	var elbow: Vector3 = cam.global_transform * _v(h.get("elbow", [0.25 if s == "r" else -0.25, -0.45, 0.0]))
	if arms:
		arms.place(s, at, along, palm)
		arms.aim_elbow(s, elbow)
		arms.fingers_from(s, h)
		arms.apply()
	else:
		_held_hand(s, h, at, along, palm, elbow)
	if h.get("round", false):
		# The round between the thumb and index, its nose ahead of the fingertips.
		_round.visible = true
		var f = arms.frame(s) if arms else null
		var base: Vector3 = (f as Transform3D).origin if f != null else at
		var ahead := -along.normalized()
		_round.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, ahead)), base + ahead * 0.035)


## Today's hand (HeldHand: the Studio man's painted arm) at the same place with the same finger
## numbers, for the side-by-side. Its fingers' rest differs from the MetaHuman's, so the same degrees
## close it a little differently: said so on the sheet.
func _held_hand(s: String, h: Dictionary, at: Vector3, along: Vector3, palm: Vector3, elbow: Vector3) -> void:
	var hh: Node3D = held_hands.get(s)
	if hh == null:
		hh = load("res://src/weapons/held_hand.gd").new(s == "r")
		cam.get_parent().add_child(hh)
		hh.build()
		held_hands[s] = hh
	hh.visible = true
	var z := along.normalized()
	var x := (palm - z * palm.dot(z)).normalized() * (-1.0 if s == "r" else 1.0)
	hh.global_transform = Transform3D(Basis(x, z.cross(x), z), at)
	for f in ["index", "middle", "ring", "little", "thumb"]:
		hh.curl(f, [0.0, 0.0, 0.0])
	for f in h.get("fingers", {}):
		var v = h["fingers"][f]
		if v is Array:
			hh.curl(f, v)
		else:
			hh.grasp(f, float(v))
	if h.has("thumb"):
		var r: Array = h["thumb"].get("root", [0, 0, 0])
		var bend: Array = h["thumb"].get("bend", [0, 0])
		hh.thumb_pose(Vector3(r[0], r[1], r[2]), float(bend[0]), float(bend[1]))
	hh.aim_forearm(elbow - at)


## A shot: the gun's kick (GunKick) shoved by the pose file's peaks; `step` plays it out.
func fire() -> void:
	var k: Dictionary = data.get("kick", {})
	kick.fire(float(k.get("pitch", 6.0)), float(k.get("yaw", 0.0)), float(k.get("roll", 0.0)), float(k.get("back", 0.02)))


## Advances the kick and re-poses: the gun and hands ride the held node, turned about the grip.
func step(delta: float) -> void:
	kick.step(delta)
	var pivot := _held_base * (marker("GripWeb") if (rig.rig["markers"] as Dictionary).has("GripWeb") else marker("Wrist"))
	var turn := Basis.from_euler(Vector3(deg_to_rad(kick.pitch), deg_to_rad(-kick.yaw), deg_to_rad(kick.roll)))
	held.transform = Transform3D(Basis.IDENTITY, pivot + Vector3(0, 0, kick.back)) * Transform3D(turn, Vector3.ZERO) \
			* Transform3D(Basis.IDENTITY, -pivot) * _held_base
	set_pose_hands_only()


func set_pose_hands_only() -> void:
	var p: Dictionary = data["poses"][pose_name]
	for s in ["r", "l"]:
		_hand(s, hand_data(p, s))
