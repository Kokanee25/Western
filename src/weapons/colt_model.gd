class_name ColtModel
extends Node3D
## The Colt Single Action Army (7½" barrel) in your hand: the gun lab's approved script-built gun
## (#693 step 1, experiments/gun_lab/saa/: saa_blender.py from the Met's 1874 gun, painted from noise
## and FLUX surfaces by saa_paint.py) promoted to the game (#1014), as the Winchester was (#792):
## `assets/weapons/colt_saa.glb`, every moving part its own node on its pivot, and
## `colt_saa_rig.json` (pivots, axes, travel, markers). The blued steel, case colours and walnut are
## the bake's albedo and ORM (metal, roughness, occlusion), not flat colour.
## Only the player's viewmodel carries it (72k triangles): the men in town keep `RevolverModel`.
## Local space: barrel along -Z, up +Y, right +X, the origin where RevolverModel's is (where the
## grip meets the frame, the bore 4 cm above it), so the hand's numbers read alike on both:
## the rig's own frame is shifted by `OFFSET`.

const SCENE := "res://assets/weapons/colt_saa.glb"
const RIG := "res://assets/weapons/colt_saa_rig.json"
## The rig's frame in this node's: the bore (rig y 5.4 cm) to 4.2 cm, the trigger's face near
## RevolverModel's trigger.
const OFFSET := Vector3(0.0, -0.012, -0.006)
## Parts that never move are joined into one mesh (one draw call a material, not two dozen).
const STATIC := ["Frame", "Barrel", "EjectorHousing", "BasePin", "Backstrap", "TriggerGuard", "Grip"]

var rig: Dictionary
var parts := {}
## The rig's markers (Muzzle, SightRear, SightFront, GripWeb, TriggerFace, GatePoint, BoreBreech) as
## Marker3Ds in this node's space; `HammerSpur` rides the hammer.
var markers := {}
var muzzle: Marker3D
var gate_point: Marker3D
var spur: Node3D
var hammer_deg := 0.0
## In your hand: the in-hand albedo (GunParts.held_albedo). Set before it enters the tree.
var held := false
const HELD_ALBEDO := {"res://assets/weapons/colt_saa_saa_albedo.jpg": "res://assets/weapons/colt_saa_held_albedo.jpg",
		"res://assets/weapons/colt_saa_saa_orm.jpg": "res://assets/weapons/colt_saa_held_orm.jpg"}

var _gun: Node3D
var _cases: Array[Node3D] = []
var _bullets: Array[Node3D] = []


func _ready() -> void:
	_build()


func _build() -> void:
	rig = JSON.parse_string(FileAccess.get_file_as_string(RIG))
	var scene := load(SCENE) as PackedScene
	_gun = scene.instantiate() if scene else Node3D.new()
	_gun.name = "ColtSAA"
	_gun.position = OFFSET
	add_child(_gun)
	for n: String in rig["parts"]:
		parts[n] = _gun.find_child(n, true, false)
	for k in 6:
		_cases.append(_gun.find_child("Case%d" % k, true, false) as Node3D)
		_bullets.append(_gun.find_child("Bullet%d" % k, true, false) as Node3D)
	for n: String in rig["markers"]:
		var p: Array = rig["markers"][n]
		var m := Marker3D.new()
		m.name = "M_" + n
		m.position = Vector3(p[0], p[1], p[2]) + OFFSET
		add_child(m)
		markers[n] = m
	muzzle = markers["Muzzle"]
	gate_point = markers["GatePoint"]
	spur = _gun.find_child("HammerSpur", true, false) as Node3D
	_join_static()
	if held:
		GunParts.held_albedo(_gun, HELD_ALBEDO)
	hammer(0.0)


## The fixed parts and screws as one mesh in the gun's frame (the moving ones keep their nodes).
func _join_static() -> void:
	var by_mat := {}
	for mi: MeshInstance3D in _gun.find_children("*", "MeshInstance3D", true, false):
		var owner_part := _part_of(mi)
		if owner_part == "" or not (owner_part in STATIC or owner_part.begins_with("Screw_")):
			continue
		var xf := _gun.global_transform.affine_inverse() * mi.global_transform if mi.is_inside_tree() \
				else _rel(mi)
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(s)
			if not by_mat.has(mat):
				var st := SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				by_mat[mat] = st
			(by_mat[mat] as SurfaceTool).append_from(mi.mesh, s, xf)
		mi.visible = false
		mi.set_meta(&"joined", true)
	if by_mat.is_empty():
		return
	var mesh := ArrayMesh.new()
	for mat: Material in by_mat:
		var st: SurfaceTool = by_mat[mat]
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
	var joined := MeshInstance3D.new()
	joined.name = "Fixed"
	joined.mesh = mesh
	_gun.add_child(joined)
	for mi: MeshInstance3D in _gun.find_children("*", "MeshInstance3D", true, false):
		if mi.has_meta(&"joined"):
			mi.queue_free()


## Which rig part a mesh belongs to (its nearest ancestor named in the rig).
func _part_of(n: Node) -> String:
	while n != null and n != _gun:
		if String(n.name) in rig["parts"]:
			return String(n.name)
		n = n.get_parent()
	return ""


## A node's transform relative to the gun's root, outside the tree.
func _rel(n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != _gun:
		t = (c as Node3D).transform * t
		c = c.get_parent()
	return t


func marker(n: String) -> Vector3:
	var m: Marker3D = markers.get(n)
	return m.position if m else Vector3.ZERO


func _m(part: String) -> Dictionary:
	return rig["moving"][part]


func _turn(part: String, deg: float) -> void:
	var p: Node3D = parts.get(part)
	if p == null:
		return
	var a: Array = _m(part)["axis"]
	p.basis = Basis(Vector3(a[0], a[1], a[2]).normalized(), deg_to_rad(deg))


func notch(n: String) -> float:
	return float(_m("Hammer")["notches_deg"][n])


## The hammer back `deg` (0 rest, `notch("half")`, `notch("full")`). The bolt drops as it leaves rest
## and rises into the next notch at full cock, and the trigger comes back with it, as the lockwork
## does (the lab's saa_rig.gd).
func hammer(deg: float, pull := 0.0) -> void:
	hammer_deg = deg
	_turn("Hammer", deg)
	var t := clampf(deg / notch("full"), 0.0, 1.0)
	_turn("Bolt", float(_m("Bolt")["down_deg"]) * (0.0 if t >= 0.98 or t <= 0.02 else 1.0))
	trigger(pull)


## The trigger: 0 where the hammer holds it, 1 squeezed.
func trigger(pull: float) -> void:
	var t := clampf(hammer_deg / notch("full"), 0.0, 1.0)
	var cocked: float = float(_m("Trigger")["cocked_deg"]) * t
	_turn("Trigger", lerpf(cocked, float(_m("Trigger")["pull_deg"]), clampf(pull, 0.0, 1.0)))


## The cylinder turned `deg` about its axis (+60 brings the next chamber up under the hammer,
## clockwise seen from behind).
func cylinder(deg: float) -> void:
	_turn("Cylinder", deg)


## The cylinder's turn that sets chamber `k` behind the loading gate.
func gate_turn(k: int) -> float:
	return float(_m("Cylinder")["gate_chamber_deg"]) - 60.0 * k


## The loading gate: 0 shut, 1 open.
func gate(open: float) -> void:
	_turn("Gate", float(_m("Gate")["open_deg"]) * open)


## The ejector rod: 0 home, 1 its whole stroke back.
func ejector(push: float) -> void:
	var p: Node3D = parts.get("Ejector")
	if p == null:
		return
	var m := _m("Ejector")
	var r: Array = m["pivot"]
	var a: Array = m["axis"]
	p.position = Vector3(r[0], r[1], r[2]) + Vector3(a[0], a[1], a[2]) * float(m["stroke_m"]) * push


## What's in each chamber: loaded (case and bullet), spent (the case), empty (nothing).
func show_chambers(chambers: Array[int]) -> void:
	for i in _cases.size():
		var c: int = chambers[i] if i < chambers.size() else RevolverState.Chamber.EMPTY
		if _cases[i]:
			_cases[i].visible = c != RevolverState.Chamber.EMPTY
		if _bullets[i]:
			_bullets[i].visible = c == RevolverState.Chamber.LOADED or c == RevolverState.Chamber.DUD


## World position of a chamber's rear (where a case comes out of the gate).
func chamber_rear(i: int) -> Vector3:
	return _cases[i].global_position if i < _cases.size() and _cases[i] else gate_point.global_position
