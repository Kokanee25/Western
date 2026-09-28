class_name HandModel
extends Node3D
## A right hand gripping a revolver, finger by finger: three bones per finger, two for the thumb,
## so a finger can later be shot away and seen to be gone. Posed in code; the index finger
## squeezes the trigger and the thumb reaches for the hammer.
## Built around RevolverModel's grip (same local space as the gun).

var index: Array[Node3D] = []
var thumb: Array[Node3D] = []
var fingers := {}  # name -> Array[Node3D] segments

var _trigger := 0.0
var _thumb_reach := 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.cloth("shirt", Color(0.74, 0.67, 0.54))
	var cuff := GunParts.cloth("cuff", Color(0.68, 0.61, 0.49))
	# Back of the hand, on the right side of the grip, and the wrist.
	var hand := GunParts.pivot(self, "Palm", Vector3(0.024, -0.035, 0.03))
	hand.rotation_degrees = Vector3(22, 0, 0)
	GunParts.box(hand, "Back", Vector3(0.022, 0.08, 0.075), Vector3(0, -0.01, -0.005), skin)
	GunParts.box(hand, "Heel", Vector3(0.03, 0.03, 0.04), Vector3(-0.012, -0.045, 0.02), skin)
	var wrist := GunParts.pivot(self, "Wrist", Vector3(0.03, -0.06, 0.07))
	# The forearm runs back, down and out to the right, towards the shoulder, out of the sight line.
	wrist.rotation_degrees = Vector3(32, 22, 0)
	GunParts.box(wrist, "Wrist", Vector3(0.05, 0.05, 0.06), Vector3(0, 0, 0.02), skin)
	GunParts.box(wrist, "Cuff", Vector3(0.068, 0.066, 0.04), Vector3(0, 0, 0.07), cuff)
	GunParts.box(wrist, "Sleeve", Vector3(0.074, 0.072, 0.24), Vector3(0.004, 0, 0.21), sleeve)

	# Middle, ring and little fingers wrap round the front strap to the left side.
	var names := ["middle", "ring", "little"]
	for i in 3:
		var y := -0.03 - i * 0.021
		var length: float = [0.03, 0.028, 0.022][i]
		fingers[names[i]] = _finger(names[i], Vector3(0.02, y, -0.012 - i * 0.002), length, [0.0, 85.0, 85.0], skin)
	# Index finger lies along the frame and curls onto the trigger.
	index = _finger("index", Vector3(0.019, -0.004, -0.01), 0.03, [0.0, 55.0, 60.0], skin)
	index[0].rotation_degrees.x = 18.0
	fingers["index"] = index
	# Thumb over the top of the grip, up by the hammer.
	thumb = _finger("thumb", Vector3(0.018, 0.012, 0.03), 0.026, [0.0, 25.0], skin, 0.02)
	thumb[0].rotation_degrees = Vector3(-55, 25, 0)
	fingers["thumb"] = thumb


## A chain of segments: each is a pivot at a knuckle with a box running forward (-Z) from it,
## turned about Y (curling leftwards round the grip) by `curl` degrees.
func _finger(n: String, base: Vector3, seg_len: float, curl: Array, mat: Material, width := 0.017) -> Array[Node3D]:
	var segs: Array[Node3D] = []
	var parent: Node3D = self
	var pos := base
	for i in curl.size():
		var k := GunParts.pivot(parent, "%s%d" % [n.capitalize(), i], pos)
		k.rotation_degrees.y = curl[i]
		var l: float = seg_len * (1.0 - i * 0.18)
		GunParts.box(k, "Bone", Vector3(width, width, l), Vector3(0, 0, -l * 0.5), mat)
		segs.append(k)
		parent = k
		pos = Vector3(0, 0, -l)
	return segs


## 0 = finger resting on the trigger, 1 = squeezed.
func set_trigger(amount: float) -> void:
	_trigger = amount
	if index.size() == 3:
		index[1].rotation_degrees.y = 55.0 + amount * 12.0
		index[2].rotation_degrees.y = 60.0 + amount * 18.0


## 0 = thumb resting on the grip, 1 = thumb on the hammer spur, pulling.
func set_thumb(amount: float) -> void:
	_thumb_reach = amount
	if thumb.size() == 2:
		thumb[0].rotation_degrees = Vector3(-55.0 + amount * 30.0, 25.0 - amount * 18.0, 0.0)
		thumb[1].rotation_degrees.y = 25.0 + amount * 20.0
