class_name HandModel
extends Node3D
## Your right hand gripping a revolver (RevolverModel's local space): a HeldHand (a Studio man's
## painted, skinned hand), its palm on the right grip panel, the middle, ring and little fingers wrapped round the front strap to the left
## panel, the index finger along the frame and onto the trigger, the thumb up by the hammer; the
## forearm runs back, down and out to the right towards the shoulder, out of the sight line.
## Finger by finger, so a finger can later be shot away and seen to be gone.

## The hand in the gun's space: its index knuckle by the top of the front strap, turned with the
## grip's rake (RevolverModel's Grip: 22 degrees).
const HAND_POS := Vector3(0.027, -0.009, 0.0)
const HAND_ROT := Vector3(-22.0, 0.0, 0.0)
## The forearm from the wrist: down and out to the right.
const WRIST_ROT := Vector3(45.0, 24.0, 0.0)
## The grip fingers' curl (knuckle, middle, tip; degrees towards the palm) and the trigger
## finger's at rest and squeezed: each joint closed until the finger past it touches the walnut
## (the gun lab's `views.gd --fit`: every bone 0-2 mm off the grip, the index's pad on the trigger).
const GRIP_CURL := {"middle": [74.0, 30.0, 101.0], "ring": [54.0, 56.0, 43.0], "little": [14.0, 83.0, 0.0]}
const TRIGGER_REST := [14.0, 34.0, 91.0]
const TRIGGER_PULL := [18.0, 46.0, 100.0]
## The thumb (its root's turn, then its two bends): resting high on the left of the frame behind
## the cylinder, and on top of the hammer's spur to cock it (`views.gd --fit`, clear of the steel).
const THUMB_REST := [Vector3(-24.0, -36.0, 24.0), 45.0, 40.0]
const THUMB_COCK := [Vector3(48.0, 36.0, 60.0), 45.0, 40.0]

var held: HeldHand
var index: Array[Node3D] = []
var thumb: Array[Node3D] = []
var fingers := {}  # name -> Array[Node3D] segments

var _trigger := 0.0
var _thumb_reach := 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	held = HeldHand.new(true)
	held.name = "Held"
	held.position = HAND_POS
	held.rotation_degrees = HAND_ROT
	add_child(held)
	held.build()
	held.wrist.rotation_degrees = WRIST_ROT
	for f: String in GRIP_CURL:
		held.curl(f, GRIP_CURL[f])
	for f: String in held.fingers:
		var bones: Array[Node3D] = []
		bones.assign(held.fingers[f])
		fingers[f] = bones
	index = fingers["index"]
	thumb = fingers["thumb"]
	set_trigger(0.0)
	set_thumb(0.0)


## 0 = finger resting on the trigger, 1 = squeezed.
func set_trigger(amount: float) -> void:
	_trigger = amount
	if held:
		var a: Array = []
		for i in 3:
			a.append(lerpf(TRIGGER_REST[i], TRIGGER_PULL[i], amount))
		held.curl("index", a)


## 0 = thumb resting on the frame, 1 = thumb on the hammer spur, pulling.
func set_thumb(amount: float) -> void:
	_thumb_reach = amount
	if held:
		held.thumb_pose((THUMB_REST[0] as Vector3).lerp(THUMB_COCK[0], amount),
				lerpf(THUMB_REST[1], THUMB_COCK[1], amount), lerpf(THUMB_REST[2], THUMB_COCK[2], amount))
