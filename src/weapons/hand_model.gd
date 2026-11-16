class_name HandModel
extends Node3D
## Your right hand gripping a revolver (RevolverModel's local space): a HeldHand (a Studio man's
## painted, skinned hand), its palm on the right grip panel, the middle, ring and little fingers wrapped round the front strap to the left
## panel, the index finger along the frame and onto the trigger, the thumb up by the hammer; the
## wrist straight behind the grip and the forearm back, a little down and out to the right.
## Finger by finger, so a finger can later be shot away and seen to be gone.

## The hand in the gun's space: its index knuckle by the top of the front strap, turned with the
## grip's rake (RevolverModel's Grip: 22 degrees).
const HAND_POS := Vector3(0.027, -0.009, 0.0)
const HAND_ROT := Vector3(-22.0, 0.0, 0.0)
## The forearm from the wrist, in the gun's space: back, a little down and out to the right, nearly
## in line with the hand (a one-handed hold keeps the wrist straight behind the grip).
const FOREARM := Vector3(0.25, -0.2, 0.95)
## The grip fingers closed round the walnut and the trigger finger on the trigger, at rest and
## squeezed (HeldHand.grasp: each finger's joints bend together; the gun lab's `views.gd --fit`
## closes each until it touches).
const GRIP := {"middle": 64.0, "ring": 62.0, "little": 58.0}
const TRIGGER_REST := 25.0
const TRIGGER_PULL := 38.0
## The thumb (its root's turn, then its two bends): resting high on the left of the frame behind
## the cylinder, and on top of the hammer's spur to cock it (`views.gd --fit`, clear of the steel).
const THUMB_REST := [Vector3(-24.0, -36.0, 24.0), 45.0, 40.0]
const THUMB_COCK := [Vector3(48.0, 36.0, 60.0), 45.0, 40.0]
## The trigger finger off the trigger, laid straight along the frame's right side above the guard
## (its root's turn, then its two bends, as the thumb's): where it sits until you aim or fire.
const INDEX_OFF := [Vector3(0.0, 0.0, 0.0), 0.0, 0.0]

var held: HeldHand
var index: Array[Node3D] = []
var thumb: Array[Node3D] = []
var fingers := {}  # name -> Array[Node3D] segments

var _trigger := 0.0
var _off := 0.0
var _thumb_reach := 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	held = HeldHand.new(true)
	held.name = "Held"
	var place: Array = HeldHand.hold("colt.hand", [HAND_POS, HAND_ROT])
	held.position = place[0]
	held.rotation_degrees = place[1]
	add_child(held)
	held.build()
	held.aim_forearm(FOREARM)
	# The arm bends at the elbow from your right shoulder (HeldHand.shoulder).
	held.shoulder = ShotgunViewmodel.SHOULDER_R
	held.elbow_pole = ShotgunViewmodel.ELBOW_POLE_R
	var grip: Dictionary = HeldHand.hold("colt.grip", GRIP)
	for f: String in grip:
		held.grasp(f, grip[f])
	for f: String in held.fingers:
		var bones: Array[Node3D] = []
		bones.assign(held.fingers[f])
		fingers[f] = bones
	index = fingers["index"]
	thumb = fingers["thumb"]
	set_trigger(0.0)
	set_thumb(0.0)


## 0 = finger resting on the trigger, 1 = squeezed. `off` 1 lays it along the frame instead.
func set_trigger(amount: float, off := 0.0) -> void:
	_trigger = amount
	_off = off
	if held == null:
		return
	var on := lerpf(HeldHand.hold("colt.trigger_rest", TRIGGER_REST), HeldHand.hold("colt.trigger_pull", TRIGGER_PULL), amount)
	if off <= 0.0:
		held.grasp("index", on)
		return
	# Off the trigger: the knuckle's turn and the bends blended from the trigger's curl (a grasp's
	# bends, HeldHand.GRASP) to the finger laid along the frame.
	var o: Array = HeldHand.hold("colt.index_off", INDEX_OFF)
	var g: Array = HeldHand.GRASP
	held.pose_finger("index", (o[0] as Vector3) * off + Vector3(0.0, 0.0, -on * float(g[0])) * (1.0 - off),
			lerpf(on * float(g[1]), float(o[1]), off), lerpf(on * float(g[2]), float(o[2]), off))


## 0 = thumb resting on the frame, 1 = thumb on the hammer spur, pulling.
func set_thumb(amount: float) -> void:
	_thumb_reach = amount
	if held:
		var r: Array = HeldHand.hold("colt.thumb_rest", THUMB_REST)
		var c: Array = HeldHand.hold("colt.thumb_cock", THUMB_COCK)
		held.thumb_pose((r[0] as Vector3).lerp(c[0], amount), lerpf(r[1], c[1], amount), lerpf(r[2], c[2], amount))
