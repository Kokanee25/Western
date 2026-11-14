class_name PlayChore
extends RefCounted
## A chore that has a townsman play his part in the band (Band, #799; CivilianBrain.chores): the
## fiddler stood at his post with the fiddle under his chin, the pianist sat at the piano (his
## chair's SitChore inside this one). Free and at it, he's `ready` and the band sounds his part;
## trouble (not free: a shot, a fire, a gun on him), down or dead, he stops, and so does his part.
##
## His hands follow the same note data as the sound (Band.bow_at, Band.hand_at): the bow hand draws
## each stroke the way the fiddle part bows it, its angle crossing to the stroke's string; the left
## hand holds the neck. At the piano, each hand over the keys it's striking, lifting between them
## (the left hand's oom-pah: bass low, chord in the middle). Laid by HumanBody.reach_to each tick.
##
## The fiddle and its bow in his hands are the prop lab's model (assets/props/models/fiddle.glb,
## the `fiddle` and `fiddle_bow` kit props' parts) drawn here as meshes, not the kit props: held,
## they're his; put down or dropped they're hidden (a later step: the kit's fiddle dropped where
## he lets go of it).

## Near his post (m): the chore has him (else his brain walks him back to it).
const AT_POST := 0.32
## The fiddle's grips in its own space (fiddle.json's `grips`), the bow's frog (fiddle_bow.json's).
const CHIN := Vector3(-0.1495, 0.092, -0.05)
const NECK := Vector3(0.278, 0.0552, 0.0)
const FROG := Vector3(0.03, 0.011, 0.0)
## Where the bow crosses the strings, in the fiddle's space (between the bridge and the fingerboard).
const CONTACT := Vector3(0.02, 0.1, 0.0)
## The piano's keys in its own space (upright_piano.json: the keybed's top, keys toward +Z).
const KEYS_Y := 0.815
const KEYS_Z := 0.2
const KEYS_HALF := 0.62

var man: HumanBody
var band: Band
var part: StringName
## The pianist's seat (null for a man who stands to play).
var sit: SitChore
## The piano he plays (the pianist's).
var piano: Node3D
var _ready_frame := -100
var _at_it := false
var _fiddle: MeshInstance3D
var _bow: MeshInstance3D
var _angle := 0.0
var _hands := {0: 64.0, 1: 72.0}


func _init(m: HumanBody, b: Band, p: StringName, s: SitChore = null, instrument: Node3D = null) -> void:
	man = m
	band = b
	part = p
	sit = s
	piano = instrument
	if band:
		band.seat(part, self)


## At his instrument and free this tick (or the last few: a brain far off ticks slower).
func is_ready() -> bool:
	return _at_it and is_instance_valid(man) and Engine.get_physics_frames() - _ready_frame < 45


func at_it() -> bool:
	return is_ready()


func busy() -> bool:
	return _at_it or (sit != null and sit.busy())


## His hands are moving: he ticks every tick near you.
func lets_slow() -> bool:
	return false


func step_chore(delta: float, free: bool) -> bool:
	if not is_instance_valid(man):
		return false
	if not free or man.limp or man.prone or not man.physiology.is_conscious():
		_stop()
		if sit:
			sit.step_chore(delta, false)
		return false
	if sit:
		if not sit.step_chore(delta, true):
			_stop()
			return false
	else:
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain
		if brain == null or brain.post == Vector3.INF:
			return false
		var flat := man.global_position - brain.post
		flat.y = 0.0
		if flat.length() > AT_POST:
			_stop()
			return false
		man.set_pose(&"stand")
		if brain.faces != Vector3.INF:
			man.face(brain.faces)
	_at_it = true
	_ready_frame = Engine.get_physics_frames()
	if part == &"fiddle":
		_fiddle_step(delta)
	elif part == &"piano" and piano != null and is_instance_valid(piano):
		_piano_step()
	return true


func _stop() -> void:
	_at_it = false
	if _fiddle:
		_fiddle.visible = false
		_bow.visible = false


## Where his part is heard from: the fiddle's body, the piano's keyboard.
func sound_at() -> Vector3:
	if part == &"fiddle" and _fiddle and _fiddle.visible:
		return _fiddle.global_transform * Vector3(0.05, 0.06, 0.0)
	if part == &"piano" and piano != null and is_instance_valid(piano):
		return piano.global_transform * Vector3(0.0, 1.0, 0.35)
	return man.global_position + Vector3.UP * 1.3


# --- The fiddle --------------------------------------------------------------------------------

func _frame() -> Dictionary:
	var sl := (man.pivots[&"upper_arm_l"] as Node3D).global_position
	var sr := (man.pivots[&"upper_arm_r"] as Node3D).global_position
	var right := sr - sl
	right.y = 0.0
	right = right.normalized() if right.length() > 1e-4 else man.global_basis.x
	var up := Vector3.UP
	return {"mid": (sl + sr) * 0.5, "right": right, "up": up, "fwd": up.cross(right)}


func _make_fiddle() -> void:
	var look := PropKit.material("pbr:fiddle", 0)
	_fiddle = MeshInstance3D.new()
	_fiddle.name = "HeldFiddle"
	_fiddle.mesh = _parts(["Body", "Neck", "Fittings", "Strings"])
	_bow = MeshInstance3D.new()
	_bow.name = "HeldBow"
	_bow.mesh = _parts(["Bow", "BowHair"])
	for mi: MeshInstance3D in [_fiddle, _bow]:
		mi.top_level = true
		mi.material_override = look
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		man.add_child(mi)


static func _parts(names: Array) -> Mesh:
	var st := SurfaceTool.new()
	var any := false
	for n: String in names:
		var m := PropKit.model_part("fiddle", n)
		if m:
			for s in m.get_surface_count():
				st.append_from(m, s, Transform3D.IDENTITY)
			any = true
	if not any:
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.06, 0.2)
		return box
	return st.commit()


## The fiddle under his chin on his left collarbone, its scroll out to his left front; the left
## hand under its neck; the bow hand where the bow plan has the frog, the hair across the strings.
func _fiddle_step(delta: float) -> void:
	if _fiddle == null:
		_make_fiddle()
	var f := _frame()
	var mid: Vector3 = f.mid
	var right: Vector3 = f.right
	var fwd: Vector3 = f.fwd
	var up: Vector3 = f.up
	var left := -right
	var chin := mid + up * 0.07 + left * 0.1 + fwd * 0.1
	var x := (fwd * 0.8 + left * 0.55 + up * 0.1).normalized()
	var top := (up * 0.85 + right * 0.5)
	top = (top - x * top.dot(x)).normalized()
	var fb := Basis(x, top, x.cross(top))
	var fx := Transform3D(fb, chin - fb * CHIN)
	_fiddle.global_transform = fx
	_fiddle.visible = true
	man.reach_to("l", fx * NECK - top * 0.035, -top, 1.0)
	# The bow: the frog `s` from the strings along `out` (to his right, the bow's line across the
	# strings), turned about the strings by the string it's on.
	var t := band.clock if band else 0.0
	var b := band.bow_at(t) if band and band.sounding(part) else Vector2(0.3, _angle)
	_angle = lerpf(_angle, b.y, clampf(delta * 18.0, 0.0, 1.0))
	# Across the strings in the plane of the fiddle's top (it leans to his right, so the bow slopes
	# down to his right), turned about the strings by the string it's on.
	var out := top.cross(x).normalized()
	if out.dot(right) < 0.0:
		out = -out
	out = out.rotated(x, _angle)
	var contact := fx * CONTACT
	var frog := contact + out * b.x
	var bx := -out
	var by := (top - bx * top.dot(bx)).normalized()
	var bb := Basis(bx, by, bx.cross(by))
	_bow.global_transform = Transform3D(bb, frog - bb * FROG)
	_bow.visible = true
	man.reach_to("r", frog - by * 0.02, by, 1.0)


# --- The piano ---------------------------------------------------------------------------------

## Each hand over the keys it's striking (the midi's place along the keyboard), lifting between.
func _piano_step() -> void:
	var t := band.clock if band else 0.0
	var px := piano.global_transform
	var sides := {0: "l", 1: "r"}
	for hand: int in [0, 1]:
		var at := Vector2(_hands[hand], 1.0)
		if band and band.sounding(part):
			at = band.hand_at(hand, t)
		else:
			at.x = 50.0 if hand == 0 else 72.0
		_hands[hand] = at.x
		var kx := clampf((at.x - 64.5) / 44.0 * KEYS_HALF, -KEYS_HALF, KEYS_HALF)
		var p := px * Vector3(kx, KEYS_Y + 0.015 + 0.035 * at.y, KEYS_Z)
		man.reach_to(String(sides[hand]), p, Vector3.UP, 1.0)
