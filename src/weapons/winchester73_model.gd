class_name Winchester73Model
extends Node3D
## The Winchester Model 1873 rifle (24" octagon barrel), the gun lab's Blender model
## (experiments/gun_lab/win73/, #734; Sean OK'd the shape on #767 and the surfaces on #776):
## assets/weapons/win73_24.glb, every moving part its own node on its pivot, and its rig file
## (win73_24_rig.json: pivots, axes, travel, markers) that this drives. The lab's win73_rig.gd,
## made the game's: the lever's throw with the bolt back, the hammer cocked and the carrier up; the
## hammer to any angle; the trigger; the dust cover; the loading gate; the rounds in the chamber, on
## the carrier and at the tube's mouth. And a sling (a leather strap between two swivels, hanging).
##
## Local space (the rig's): barrel along -Z, up +Y, right +X; the origin under the trigger (design
## f -4.4", u -2.1": `design()`).

const GLB := "res://assets/weapons/win73_24.glb"
const RIG := "res://assets/weapons/win73_24_rig.json"
## The sling: 1 1/4" oiled leather, its front swivel on the magazine band, the rear on the butt's
## belly (design inches f, u), hanging this far below the straight line between them (m).
const SLING_FRONT := Vector3(22.25, -1.12, 0.0)
const SLING_REAR := Vector3(-12.0, -4.15, 0.0)
const SLING_WIDTH := 0.032
const SLING_SAG := 0.13

var rig: Dictionary = {}
## Part name -> its node (Receiver, Lever, Hammer...; CaseChamber, BulletCarrier...).
var parts := {}
## Marker name -> a Marker3D in this space (Muzzle, SightRear, SightFront, Wrist, TriggerFace,
## Forend, GatePoint, Port, Butt, BoreBreech).
var markers := {}
var sling: MeshInstance3D
## The lever's pivot (the right hand rides it while the lever's worked).
var lever_pivot := Vector3.ZERO
var hammer_full := 34.0
var hammer_half := 13.0

var _hammer_deg := 0.0


func _ready() -> void:
	if parts.is_empty():
		build()


func build() -> void:
	if not parts.is_empty():
		return
	rig = JSON.parse_string(FileAccess.get_file_as_string(RIG))
	var scene := load(GLB) as PackedScene
	var gun := scene.instantiate() as Node3D
	gun.name = "Win73"
	add_child(gun)
	for n in rig["parts"]:
		parts[n] = gun.find_child(n, true, false)
	for k in ["Chamber", "Carrier", "Tube"]:
		parts["Case" + k] = gun.find_child("Case" + k, true, false)
		parts["Bullet" + k] = gun.find_child("Bullet" + k, true, false)
	for n: String in rig["markers"]:
		var p: Array = rig["markers"][n]
		var m := Marker3D.new()
		m.name = n
		m.position = Vector3(p[0], p[1], p[2])
		add_child(m)
		markers[n] = m
	var lv: Array = _m("Lever")["pivot"]
	lever_pivot = Vector3(lv[0], lv[1], lv[2])
	hammer_full = float(_m("Hammer")["notches_deg"]["full"])
	hammer_half = float(_m("Hammer")["notches_deg"]["half"])
	_build_sling()
	set_hammer(0.0)
	show_rounds(Winchester73State.Round.EMPTY, Winchester73State.Round.EMPTY, true)


## A design point (f along the bore from the breech, u up from the bore, l to the right; inches) in
## this space.
static func design(f: float, u: float, l := 0.0) -> Vector3:
	return Vector3(l, u + 2.1, -(f + 4.4)) * 0.0254


func marker(n: String) -> Vector3:
	return (markers[n] as Marker3D).position


func _m(part: String) -> Dictionary:
	return rig["moving"][part]


func _turn(part: String, deg: float) -> void:
	var node := parts.get(part) as Node3D
	if node:
		var a: Array = _m(part)["axis"]
		node.basis = Basis(Vector3(a[0], a[1], a[2]).normalized(), deg_to_rad(deg))


func _slide(part: String, key: String, travel: float) -> void:
	var node := parts.get(part) as Node3D
	if node:
		var m := _m(part)
		var p: Array = m["rest"]
		var a: Array = m["axis"]
		node.position = Vector3(p[0], p[1], p[2]) + Vector3(a[0], a[1], a[2]) * float(m[key]) * travel


## The lever thrown `t` of the way (0 home, 1 fully open), and what it drives: the toggle links take
## the bolt back (fastest mid-stroke); opening, the carrier lifts in the last 30%; closing, it drops
## in the last 15% (`closing`: on the way home). The hammer is the caller's (`set_hammer`): the bolt
## cocks it in the first 45% of the throw (`cocked_by(t)`).
func lever(t: float, closing := false) -> void:
	t = clampf(t, 0.0, 1.0)
	_turn("Lever", lever_deg(t))
	_slide("Bolt", "stroke_m", (1.0 - cos(PI * t)) * 0.5)
	_slide("Carrier", "lift_m", smoothstep(0.0, 0.15, t) if closing else smoothstep(0.7, 1.0, t))


func lever_deg(t: float) -> float:
	return float(_m("Lever")["throw_deg"]) * t


## How far back the bolt has pushed the hammer at `t` of the lever's throw (degrees).
func cocked_by(t: float) -> float:
	return hammer_full * smoothstep(0.0, 0.45, t)


func set_hammer(deg: float) -> void:
	_hammer_deg = deg
	_turn("Hammer", deg)


func hammer_deg() -> float:
	return _hammer_deg


func trigger(pull: float) -> void:
	_turn("Trigger", float(_m("Trigger")["pull_deg"]) * pull)


func cover(open: float) -> void:
	_slide("DustCover", "stroke_m", open)


## The loading gate pressed in by a round going into the tube (0 shut, 1 fully in).
func gate(push: float) -> void:
	_turn("Gate", float(_m("Gate")["push_deg"]) * push)


## What the chamber and the carrier hold (Winchester73State.Round), and whether a round shows at
## the tube's mouth.
func show_rounds(chamber: int, carrier: int, tube_has: bool) -> void:
	_show("Chamber", chamber)
	_show("Carrier", carrier)
	_show("Tube", Winchester73State.Round.LOADED if tube_has else Winchester73State.Round.EMPTY)


func _show(k: String, state: int) -> void:
	var case_node := parts.get("Case" + k) as Node3D
	var bullet := parts.get("Bullet" + k) as Node3D
	if case_node:
		case_node.visible = state != Winchester73State.Round.EMPTY
	if bullet:
		bullet.visible = state == Winchester73State.Round.LOADED or state == Winchester73State.Round.DUD


## The sling: a strap swept along a hanging curve between the swivels, with a swivel loop at each
## end. Placeholder leather (no painted surface yet).
func _build_sling() -> void:
	var a := design(SLING_FRONT.x, SLING_FRONT.y, SLING_FRONT.z)
	var b := design(SLING_REAR.x, SLING_REAR.y, SLING_REAR.z)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 24
	var pts: Array[Vector3] = []
	for i in n + 1:
		var s := float(i) / n
		# A hanging chain's sag, near enough a parabola for a strap this taut.
		pts.append(a.lerp(b, s) + Vector3.DOWN * SLING_SAG * 4.0 * s * (1.0 - s))
	var half := SLING_WIDTH * 0.5
	var thick := 0.0035
	for i in n:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var along := (p1 - p0).normalized()
		var side := Vector3.RIGHT * half
		var up := along.cross(Vector3.RIGHT).normalized() * thick * 0.5
		var quads := [[p0 - side + up, p0 + side + up, p1 + side + up, p1 - side + up, up.normalized()],
				[p0 + side - up, p0 - side - up, p1 - side - up, p1 + side - up, -up.normalized()],
				[p0 + side + up, p0 + side - up, p1 + side - up, p1 + side + up, Vector3.RIGHT],
				[p0 - side - up, p0 - side + up, p1 - side + up, p1 - side - up, Vector3.LEFT]]
		for q: Array in quads:
			st.set_normal(q[4])
			for v in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				st.add_vertex(v)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.16, 0.09)
	mat.roughness = 0.75
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sling = MeshInstance3D.new()
	sling.name = "Sling"
	sling.mesh = st.commit()
	sling.material_override = mat
	add_child(sling)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.14, 0.14, 0.14)
	steel.metallic = 1.0
	steel.roughness = 0.45
	for at in [a, b]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.006
		torus.outer_radius = 0.0085
		torus.rings = 12
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = steel
		ring.position = at + Vector3.UP * 0.004
		ring.rotation_degrees = Vector3(0.0, 0.0, 90.0)
		ring.name = "SlingSwivel"
		add_child(ring)
