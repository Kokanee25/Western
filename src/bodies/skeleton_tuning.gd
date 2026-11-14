class_name SkeletonTuning
extends Resource
## The fuller skeleton's dials (issue #696; `DeformRig`): how far the clavicles follow the arms,
## how the twist bones share a limb's roll, how the skin is shared out to them when a man's model
## has no weights of its own for them, and how far a man's own proportions may move his joints
## (`Anatomy.fitted`). config/skeleton.tres.

@export_group("Clavicle")
## The arm's raise (degrees from hanging, in his chest's frame) where his collarbone starts to rise:
## standing easy (the upper arm 7 degrees out) it doesn't move.
@export var clav_raise_from := 20.0
## Degrees of collarbone rise a degree of the arm's raise past that: the shoulder girdle takes about
## a third of a raised arm's turn, a third of that the clavicle's own rise (Ludewig et al. 2009,
## J Bone Joint Surg 91: ~11 degrees of rise over 120 of humerothoracic elevation; Inman 1944 more).
@export var clav_rise_per_deg := 0.15
## Its rise and drop at most (degrees).
@export var clav_rise_max := 26.0
@export var clav_drop_max := 6.0
## Degrees it comes forward (protraction) as the arm points forward (a unit of the arm's forward
## reach in his chest's frame), back (retraction) as it goes behind him.
@export var clav_forward_per_reach := 15.0
## A raised arm draws the clavicle back a little too (Ludewig: retraction rises with elevation):
## degrees a degree of raise past `clav_raise_from`.
@export var clav_back_per_deg := 0.05
@export var clav_forward_max := 18.0
@export var clav_back_max := 14.0
## How fast a pose's own extra lift (POSES' clavicle keys) comes on: a share a second, as poses blend.
@export var clav_blend := 6.0

@export_group("Twist")
## The share of the upper arm's roll (about its own length, from his chest) each upper arm twist
## bone takes: [_0 at the shoulder, _1 halfway]; the upper arm's own bone has all of it at the
## elbow. The shoulder's skin hardly turns with the arm's roll (it's held by the trunk).
@export var upper_twist_shares := Vector2(0.15, 0.55)
## The share of the hand's roll (pronation and supination, about the forearm) each forearm twist
## bone takes: [_0 halfway, _1 at the wrist]; the forearm's own bone has none of it at the elbow
## (the radius turns over the ulna along the whole forearm).
@export var fore_twist_shares := Vector2(0.5, 1.0)

@export_group("Auto weights")
## A model without its own clavicle weights (BodyMesh's men, MakeHuman's and the Studio's Rodin men)
## gets them from his chest's: at most this share of a vertex's chest weight, over the clavicle's
## outer part (from `clav_from` to `clav_full` of the way from the sternum to the shoulder), above
## his armpit (`clav_below` m under the shoulder's top, fading over `clav_fade`), within
## `clav_depth` m of the clavicle front or back (fading over `clav_fade`).
@export var clav_weight := 0.85
@export var clav_from := 0.1
@export var clav_full := 0.75
@export var clav_below := 0.12
@export var clav_depth := 0.1
@export var clav_fade := 0.05

@export_group("Proportions")
## How far a man's own proportions (his report's `proportions`, Anatomy.fitted) may take a segment
## from the shared anatomy's: its length (ratio), its ends (m) and its direction (degrees).
@export var length_min := 0.82
@export var length_max := 1.22
@export var end_shift_max := 0.08
@export var turn_max := 15.0


static var _shared: SkeletonTuning


static func shared() -> SkeletonTuning:
	if _shared == null:
		_shared = load("res://config/skeleton.tres") as SkeletonTuning
		if _shared == null:
			_shared = SkeletonTuning.new()
	return _shared
