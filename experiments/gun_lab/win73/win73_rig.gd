extends RefCounted
## Drives the Winchester 1873's moving parts from its rig file (win73_blender.py writes
## win73_<barrel>_rig.json): the lever's throw with the bolt back, the carrier up and the hammer
## cocked; the hammer to a notch (rest, half, full) or any angle; the trigger; the dust cover; the
## loading gate; and what the chamber, the carrier and the tube's first place hold.
## The lab's (#734 step 1); nothing in the game uses it yet. The Colt's saa_rig.gd is the pattern.

var gun: Node3D
var rig: Dictionary
var parts := {}
var _hammer_deg := 0.0


func _init(gun_root: Node3D, rig_path: String) -> void:
	gun = gun_root
	rig = JSON.parse_string(FileAccess.get_file_as_string(rig_path))
	for n in rig["parts"]:
		parts[n] = gun.find_child(n, true, false)
	for k in ["Chamber", "Carrier", "Tube"]:
		parts["Case" + k] = gun.find_child("Case" + k, true, false)
		parts["Bullet" + k] = gun.find_child("Bullet" + k, true, false)
	chamber("empty")
	carrier_round("empty")
	tube_round("loaded")


func _m(part: String) -> Dictionary:
	return rig["moving"][part]


func _turn(part: String, deg: float) -> void:
	var a: Array = _m(part)["axis"]
	(parts[part] as Node3D).basis = Basis(Vector3(a[0], a[1], a[2]).normalized(), deg_to_rad(deg))


func _slide(part: String, key: String, travel: float) -> void:
	var m := _m(part)
	var p: Array = m["rest"]
	var a: Array = m["axis"]
	(parts[part] as Node3D).position = Vector3(p[0], p[1], p[2]) + Vector3(a[0], a[1], a[2]) * float(m[key]) * travel


## The lever thrown `t` of the way (0 closed, 1 fully open). The toggle links take the bolt back
## (fastest mid-stroke); the bolt's back cocks the hammer in the first 45% of the throw (and it stays
## cocked: the sear holds it on the way back); opening, the carrier lifts the round in the last 30%;
## closing, the bolt pushes it into the chamber and the carrier drops in the last 15%.
func lever(t: float, closing := false) -> void:
	t = clampf(t, 0.0, 1.0)
	_turn("Lever", float(_m("Lever")["throw_deg"]) * t)
	_slide("Bolt", "stroke_m", (1.0 - cos(PI * t)) * 0.5)
	var full: float = _m("Hammer")["notches_deg"]["full"]
	hammer(maxf(_hammer_deg, full * smoothstep(0.0, 0.45, t)))
	carrier(smoothstep(0.0, 0.15, t) if closing else smoothstep(0.7, 1.0, t))


## The carrier from the tube's line (0) to the bore's (1).
func carrier(up: float) -> void:
	_slide("Carrier", "lift_m", up)


## The hammer: "rest", "half", "full" or degrees.
func hammer(notch: Variant) -> void:
	_hammer_deg = notch if notch is float else float(_m("Hammer")["notches_deg"][notch])
	_turn("Hammer", _hammer_deg)


func trigger(pull: float) -> void:
	_turn("Trigger", float(_m("Trigger")["pull_deg"]) * pull)


## The trigger pulled at full cock: the hammer falls.
func fire() -> void:
	trigger(1.0)
	hammer("rest")


func cover(open: float) -> void:
	_slide("DustCover", "stroke_m", open)


## The loading gate pressed in by a round going into the tube (0 shut, 1 fully in).
func gate(push: float) -> void:
	_turn("Gate", float(_m("Gate")["push_deg"]) * push)


func _show(k: String, state: String) -> void:
	(parts["Case" + k] as Node3D).visible = state != "empty"
	(parts["Bullet" + k] as Node3D).visible = state == "loaded"


## What the chamber holds: "loaded", "spent" (the case, no bullet) or "empty".
func chamber(state: String) -> void:
	_show("Chamber", state)


func carrier_round(state: String) -> void:
	_show("Carrier", state)


func tube_round(state: String) -> void:
	_show("Tube", state)
