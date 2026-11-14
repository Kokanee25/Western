class_name Winchester73Model
extends Node3D
## The Winchester 1873 rifle (24" octagon barrel), the gun lab's model (#734 step 1,
## experiments/gun_lab/win73/: built by win73_blender.py from the real gun's dimensions, painted by
## win73_paint.py) promoted to the game: `assets/weapons/winchester73.glb`, every moving part its own
## node on its pivot, and `winchester73_rig.json` (pivots, axes, travel, markers). This drives the
## parts from the rig: the lever's throw with the bolt back, the carrier up and the hammer cocked;
## the hammer to a notch or any angle; the trigger; the dust cover; the loading gate; what the
## chamber, the carrier and the tube's mouth show. A leather sling hangs under it.
## Local space (the rig's): barrel along -Z, up +Y, right +X, origin under the trigger (design
## f -4.4, u -2.1 inches: `design()` converts).

const SCENE := "res://assets/weapons/winchester73.glb"
const RIG := "res://assets/weapons/winchester73_rig.json"

var rig: Dictionary
var parts := {}
## The rig's fixed markers (Muzzle, SightRear, SightFront, Wrist, TriggerFace, Forend, GatePoint, Port,
## Butt, ...) as Marker3Ds in this node's space; `spur` and `loop` ride the hammer and the lever.
var markers := {}
var muzzle: Marker3D
var spur: Node3D
var loop: Node3D
var sling: MeshInstance3D
var hammer_deg := 0.0

var _gun: Node3D


func _ready() -> void:
	_build()


func _build() -> void:
	rig = JSON.parse_string(FileAccess.get_file_as_string(RIG))
	var scene := load(SCENE) as PackedScene
	_gun = scene.instantiate() if scene else Node3D.new()
	_gun.name = "Win73"
	add_child(_gun)
	for n: String in rig["parts"]:
		parts[n] = _gun.find_child(n, true, false)
	for k in ["Chamber", "Carrier", "Tube"]:
		parts["Case" + k] = _gun.find_child("Case" + k, true, false)
		parts["Bullet" + k] = _gun.find_child("Bullet" + k, true, false)
	for n: String in rig["markers"]:
		var p: Array = rig["markers"][n]
		var m := Marker3D.new()
		m.name = "M_" + n
		m.position = Vector3(p[0], p[1], p[2])
		add_child(m)
		markers[n] = m
	muzzle = markers["Muzzle"]
	spur = _gun.find_child("HammerSpur", true, false) as Node3D
	loop = _gun.find_child("LeverLoop", true, false) as Node3D
	_build_sling()
	chamber("empty")
	carrier_round("empty")
	tube_round("loaded")


## A point given in the lab's design inches (f along the bore from the breech face, u up from the
## bore's axis, l to the right) in this model's space.
static func design(f: float, u: float, l := 0.0) -> Vector3:
	return Vector3(l, u + 2.1, -(f + 4.4)) * 0.0254


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


func _slide(part: String, key: String, travel: float) -> void:
	var p: Node3D = parts.get(part)
	if p == null:
		return
	var m := _m(part)
	var r: Array = m["rest"]
	var a: Array = m["axis"]
	p.position = Vector3(r[0], r[1], r[2]) + Vector3(a[0], a[1], a[2]) * float(m[key]) * travel


func notch(n: String) -> float:
	return float(_m("Hammer")["notches_deg"][n])


## The lever thrown `t` of the way (0 closed, 1 fully open): the toggle links take the bolt back
## (fastest mid-stroke); the bolt cocks the hammer in the first 45% of the throw (the sear holds it
## after); opening, the carrier lifts the round in the last 30%; closing, the carrier drops in the
## last 15% (the round already pushed into the chamber). The rig's travel numbers are estimates.
func lever(t: float, closing := false) -> void:
	t = clampf(t, 0.0, 1.0)
	_turn("Lever", float(_m("Lever")["throw_deg"]) * t)
	_slide("Bolt", "stroke_m", (1.0 - cos(PI * t)) * 0.5)
	carrier(smoothstep(0.0, 0.15, t) if closing else smoothstep(0.7, 1.0, t))


## The bolt's own push on the hammer at `t` of the lever's throw (degrees it's held back at least).
func bolt_hammer(t: float) -> float:
	return notch("full") * smoothstep(0.0, 0.45, clampf(t, 0.0, 1.0))


func carrier(up: float) -> void:
	_slide("Carrier", "lift_m", up)


func hammer(deg: float) -> void:
	hammer_deg = deg
	_turn("Hammer", deg)


func trigger(pull: float) -> void:
	_turn("Trigger", float(_m("Trigger")["pull_deg"]) * pull)


func cover(open: float) -> void:
	_slide("DustCover", "stroke_m", open)


## The loading gate pressed in by a round going into the tube (0 shut, 1 fully in).
func gate(push: float) -> void:
	_turn("Gate", float(_m("Gate")["push_deg"]) * push)


func _show(k: String, state: String) -> void:
	var c: Node3D = parts.get("Case" + k)
	var b: Node3D = parts.get("Bullet" + k)
	if c:
		c.visible = state != "empty"
	if b:
		b.visible = state == "loaded"


## What the chamber holds: "loaded", "spent" (the case, no bullet) or "empty".
func chamber(state: String) -> void:
	_show("Chamber", state)


func carrier_round(state: String) -> void:
	_show("Carrier", state)


func tube_round(state: String) -> void:
	_show("Tube", state)


## The round state's name for `chamber()` and the like.
static func shown(round_state: int) -> String:
	match round_state:
		Winchester73State.Round.LOADED:
			return "loaded"
		Winchester73State.Round.SPENT, Winchester73State.Round.DUD:
			return "spent"
	return "empty"


## The sling: a 1 1/4" oiled leather strap from a swivel under the magazine band to one in the
## butt's belly, hanging slack below the gun (est.: a period sling ~44" on these swivels).
## Rifles were sold without swivels; a man who slung his had a gunsmith fit them.
const SLING_WIDTH := 0.032
const SLING_THICK := 0.003
const SLING_SAG := 0.13


func _build_sling() -> void:
	var front := design(22.0, -1.2)
	var back := design(-12.8, -4.5)
	var pts := PackedVector3Array()
	var steps := 18
	for i in steps + 1:
		var s := float(i) / steps
		var p := front.lerp(back, s)
		p.y -= SLING_SAG * 4.0 * s * (1.0 - s)  # a hanging strap's curve, near enough a parabola
		pts.append(p)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := SLING_WIDTH * 0.5
	for i in steps:
		var a := pts[i]
		var b := pts[i + 1]
		var along := (b - a).normalized()
		var side := Vector3.RIGHT
		var up := along.cross(side).normalized()
		var c := [a - side * hw, a + side * hw, b + side * hw, b - side * hw]
		var lift := up * SLING_THICK
		for face: Array in [[c[0], c[1], c[2], c[3], -up], [c[3] + lift, c[2] + lift, c[1] + lift, c[0] + lift, up]]:
			st.set_normal(face[4])
			for v: Vector3 in [face[0], face[1], face[2], face[0], face[2], face[3]]:
				st.add_vertex(v)
	sling = MeshInstance3D.new()
	sling.name = "Sling"
	sling.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.29, 0.17, 0.09)
	mat.roughness = 0.72
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sling.material_override = mat
	add_child(sling)
	for at in [front, back]:
		var swivel := GunParts.tube(self, "Swivel", 0.006, 0.004, at + Vector3(0, 0.004, 0), GunParts.blued(), 8, Vector3(0, 0, 90))
		swivel.set_meta(&"own_paint", true)
