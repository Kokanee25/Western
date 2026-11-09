extends RefCounted
## Drives the SAA's moving parts from its rig file (saa_blender.py writes saa_<barrel>_rig.json):
## the hammer to a notch or any angle, the trigger, the bolt, the cylinder by chamber index (it
## turns clockwise seen from behind), the loading gate, the ejector rod, and what each chamber holds.
## The lab's (#693 step 1); the game's RevolverModel will take the gun over in a later step.

var gun: Node3D
var rig: Dictionary
var parts := {}


func _init(gun_root: Node3D, rig_path: String) -> void:
	gun = gun_root
	rig = JSON.parse_string(FileAccess.get_file_as_string(rig_path))
	for n in rig["parts"]:
		parts[n] = gun.find_child(n, true, false)
	for k in 6:
		parts["Case%d" % k] = gun.find_child("Case%d" % k, true, false)
		parts["Bullet%d" % k] = gun.find_child("Bullet%d" % k, true, false)


func _turn(part: String, deg: float) -> void:
	var m: Dictionary = rig["moving"][part]
	var a: Array = m["axis"]
	var n: Node3D = parts[part]
	n.basis = Basis(Vector3(a[0], a[1], a[2]).normalized(), deg_to_rad(deg))


## The hammer: "rest", "safety", "half", "full" or degrees. The trigger and bolt follow it as the
## lockwork does: the bolt drops as the hammer leaves rest and rises again at full cock.
func hammer(notch: Variant) -> void:
	var deg: float = notch if notch is float else float(rig["moving"]["Hammer"]["notches_deg"][notch])
	_turn("Hammer", deg)
	var full: float = rig["moving"]["Hammer"]["notches_deg"]["full"]
	var t := clampf(deg / full, 0.0, 1.0)
	_turn("Trigger", rig["moving"]["Trigger"]["cocked_deg"] * t)
	_turn("Bolt", rig["moving"]["Bolt"]["down_deg"] * (0.0 if t >= 0.98 or t <= 0.02 else 1.0))


func trigger(pull: float) -> void:
	_turn("Trigger", lerpf(rig["moving"]["Trigger"]["cocked_deg"], rig["moving"]["Trigger"]["pull_deg"], pull))


## The cylinder turned `steps` indexes from rest (fractions turn it partway), clockwise seen from
## behind as cocking turns it: chamber (6 - steps) % 6 is then under the hammer.
func cylinder(steps: float) -> void:
	_turn("Cylinder", float(rig["moving"]["Cylinder"]["index_deg"]) * steps)


## The cylinder turned so chamber `k` sits behind the loading gate.
func to_gate(k: int) -> void:
	var at: float = rig["moving"]["Cylinder"]["gate_chamber_deg"]
	_turn("Cylinder", at - 60.0 * k)


func gate(open: float) -> void:
	_turn("Gate", float(rig["moving"]["Gate"]["open_deg"]) * open)


func ejector(push: float) -> void:
	var m: Dictionary = rig["moving"]["Ejector"]
	var p: Array = m["pivot"]
	var a: Array = m["axis"]
	(parts["Ejector"] as Node3D).position = Vector3(p[0], p[1], p[2]) + Vector3(a[0], a[1], a[2]) * float(m["stroke_m"]) * push


## "loaded", "spent" (the case, no bullet) or "empty".
func chamber(k: int, state: String) -> void:
	(parts["Case%d" % k] as Node3D).visible = state != "empty"
	(parts["Bullet%d" % k] as Node3D).visible = state == "loaded"
