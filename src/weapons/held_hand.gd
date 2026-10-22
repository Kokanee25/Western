class_name HeldHand
extends Node3D
## A hand holding something, for the guns in your hands (and later a man's): a palm, four fingers
## of three bones and a thumb of three, rounded and tapered, on a wrist that runs into your forearm
## and shirt sleeve (your body's own: PlayerBody's shirt and skin). Every bone is a pivot, so a
## finger can curl round a grip, squeeze a trigger, or later be shot away and seen to be gone.
##
## Hand space (a right hand; a left hand is its mirror in X): the palm faces -X (towards what it
## holds) and the back of the hand +X; the fingers point -Z from their knuckles, which run down
## -Y from the index (at the origin) to the little finger; the thumb is on the +Y side, its root in
## the palm by the wrist; the wrist is at WRIST and the forearm runs back (+Z) from it. A finger's
## curl turns each bone about Y towards the palm (degrees, positive = closing).
## Sizes are a man's hand: palm 9 cm knuckles to wrist, middle finger 9.6 cm.

const FINGERS := ["index", "middle", "ring", "little"]
## Each finger's knuckle (y), its bones' lengths and its thickness (radius at its root).
const KNUCKLE_Y := {"index": 0.0, "middle": -0.021, "ring": -0.041, "little": -0.059}
const KNUCKLE_Z := {"index": 0.0, "middle": -0.003, "ring": -0.001, "little": 0.006}
const BONES := {"index": [0.042, 0.025, 0.02], "middle": [0.046, 0.028, 0.021],
		"ring": [0.043, 0.026, 0.02], "little": [0.034, 0.02, 0.018]}
const RADIUS := {"index": 0.0088, "middle": 0.009, "ring": 0.0085, "little": 0.0075}
const THUMB_BONES := [0.042, 0.032, 0.026]
const THUMB_ROOT := Vector3(-0.012, 0.004, 0.062)
const WRIST := Vector3(0.003, -0.034, 0.092)

var right := true
## name -> Array[Node3D]: a pivot a bone, root first ("index", ..., "thumb").
var fingers := {}
## The forearm's pivot at the wrist: turn it to aim the forearm back towards the shoulder.
var wrist: Node3D
## How long the forearm and sleeve run back from the wrist (m) before they leave the view.
var forearm_length := 0.42


func _init(is_right := true) -> void:
	right = is_right


func _ready() -> void:
	build()


## Builds it once (it's built when it enters the tree, or by calling this first to pose it sooner).
func build() -> void:
	if not fingers.is_empty():
		return
	var skin := GunParts.skin()
	var sx := 1.0 if right else -1.0
	# The palm: its back towards +X, thicker at the knuckles' little-finger side and the heel.
	GunParts.lump(self, "Palm", Vector3(0.03, 0.082, 0.1), Vector3(0.003 * sx, -0.03, 0.045), skin)
	GunParts.lump(self, "Heel", Vector3(0.028, 0.04, 0.05), Vector3(-0.004 * sx, -0.052, 0.07), skin)
	GunParts.lump(self, "ThumbPad", Vector3(0.026, 0.036, 0.05), Vector3(-0.008 * sx, -0.002, 0.056), skin)
	for f: String in FINGERS:
		fingers[f] = _chain(f, Vector3(0.0, KNUCKLE_Y[f], KNUCKLE_Z[f]), BONES[f], RADIUS[f], skin)
	fingers["thumb"] = _chain("thumb", Vector3(THUMB_ROOT.x * sx, THUMB_ROOT.y, THUMB_ROOT.z), THUMB_BONES, 0.0105, skin)
	# The wrist and forearm, then the shirt's cuff and sleeve.
	wrist = GunParts.pivot(self, "Wrist", Vector3(WRIST.x * sx, WRIST.y, WRIST.z))
	GunParts.taper(wrist, "Forearm", 0.025, 0.033, 0.09, Vector3(0, 0, 0.035), skin)
	GunParts.taper(wrist, "Cuff", 0.036, 0.038, 0.045, Vector3(0, 0, 0.085), GunParts.cuff())
	var sleeve_len := maxf(forearm_length - 0.105, 0.05)
	GunParts.taper(wrist, "Sleeve", 0.04, 0.048, sleeve_len, Vector3(0, 0, 0.105 + sleeve_len * 0.5), GunParts.sleeve())


func _chain(n: String, root: Vector3, lengths: Array, radius: float, mat: Material) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var parent: Node3D = self
	var at := root
	for i in lengths.size():
		var k := GunParts.pivot(parent, "%s%d" % [n.capitalize(), i], at)
		var l: float = lengths[i]
		var r := radius * (1.0 - 0.09 * i)
		GunParts.capsule(k, "Bone", r, l + r, Vector3(0, 0, -l * 0.5), mat)
		out.append(k)
		parent = k
		at = Vector3(0, 0, -l)
	return out


## Curl a finger: degrees a bone, root first, positive towards the palm.
func curl(finger: String, angles: Array) -> void:
	var bones: Array = fingers.get(finger, [])
	var sx := 1.0 if right else -1.0
	for i in mini(bones.size(), angles.size()):
		(bones[i] as Node3D).rotation_degrees.y = float(angles[i]) * sx


## Curl a finger so it wraps a round grip `radius` m from the bone's middle line: each bone turns by
## the arc its length covers round it (`extra` degrees added to the root, for where it starts).
func wrap(finger: String, radius: float, extra := 0.0) -> void:
	var lengths: Array = BONES.get(finger, THUMB_BONES)
	var angles: Array = []
	for i in lengths.size():
		angles.append(rad_to_deg(float(lengths[i]) / maxf(radius, 0.005)) * (0.5 if i == 0 else 1.0) + (extra if i == 0 else 0.0))
	curl(finger, angles)


## The thumb: its root turned (euler degrees, mirrored for a left hand) and its two joints bent.
func thumb_pose(root_deg: Vector3, bend1: float, bend2: float) -> void:
	var t: Array = fingers.get("thumb", [])
	if t.size() < 3:
		return
	var sx := 1.0 if right else -1.0
	(t[0] as Node3D).rotation_degrees = Vector3(root_deg.x, root_deg.y * sx, root_deg.z * sx)
	(t[1] as Node3D).rotation_degrees.y = bend1 * sx
	(t[2] as Node3D).rotation_degrees.y = bend2 * sx


## Every bone's end point (fingertips and knuckles) in this hand's parent's space: for measuring
## how close the fingers come to what they hold.
func bone_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for f: String in fingers:
		var lengths: Array = BONES.get(f, THUMB_BONES)
		var bones: Array = fingers[f]
		for i in bones.size():
			var b := bones[i] as Node3D
			out.append(b.global_position)
			out.append(b.global_transform * Vector3(0, 0, -float(lengths[i])))
	return out
