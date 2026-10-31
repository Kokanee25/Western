class_name HumanBody
extends Node3D
## A person's body in the world: segments built from the anatomy (config/anatomy.json), each a
## hitbox with its own low-poly, pixel-textured mesh, hands finger by finger (three bones each),
## layered clothes, and the Physiology underneath. Bullets trace through the hidden anatomy
## (`take_bullet`); wounds are painted where they went in and out and the blood spreads as he
## bleeds. When he can't stand he goes limp into a physics ragdoll; fingers and dropped guns
## fall as their own rigid bodies.
## Rest pose: facing -Z, feet at the origin, his right is +X. Keep the node unscaled.

signal hit(info: Dictionary)
signal fell(conscious: bool)
signal died(cause: StringName)

## Joint rotations per pose (degrees). A hanging limb swings forward with +X; the trunk and head
## lean back with +X (forward with -X). The rig drops so the lower foot stays on the ground.
const POSES := {
	&"stand": {&"upper_arm_r": Vector3(0, 0, 7), &"upper_arm_l": Vector3(0, 0, -7),
			&"forearm_r": Vector3(12, 0, 0), &"forearm_l": Vector3(12, 0, 0)},
	&"aim": {&"upper_arm_r": Vector3(84, 10, 0), &"forearm_r": Vector3(4, 0, 0),
			&"upper_arm_l": Vector3(0, 0, -7), &"forearm_l": Vector3(12, 0, 0), &"chest": Vector3(0, 8, 0)},
	&"hands_up": {&"upper_arm_r": Vector3(0, 0, 150), &"forearm_r": Vector3(0, 0, 25),
			&"upper_arm_l": Vector3(0, 0, -150), &"forearm_l": Vector3(0, 0, -25), &"head": Vector3(8, 0, 0)},
	# Under arrest: hands bound behind his back, head down a little.
	&"hands_bound": {&"upper_arm_r": Vector3(-35, 0, 0), &"forearm_r": Vector3(40, 40, 0),
			&"upper_arm_l": Vector3(-35, 0, 0), &"forearm_l": Vector3(40, -40, 0), &"head": Vector3(-6, 0, 0)},
	&"clutch": {&"upper_arm_r": Vector3(18, 0, -16), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(18, 0, 16), &"forearm_l": Vector3(100, 0, 0),
			&"chest": Vector3(-18, 0, 0), &"head": Vector3(-10, 0, 0)},
	# Watching someone: square on, gun hand hanging by the holster.
	&"wary": {&"upper_arm_r": Vector3(-4, 0, 14), &"forearm_r": Vector3(18, 0, 0),
			&"upper_arm_l": Vector3(0, 0, -9), &"forearm_l": Vector3(14, 0, 0), &"chest": Vector3(0, -6, 0)},
	# Down on his heels behind something low, gun held ready.
	&"crouch": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"abdomen": Vector3(-10, 0, 0), &"chest": Vector3(-15, 0, 0), &"head": Vector3(15, 0, 0),
			&"upper_arm_r": Vector3(30, 0, 4), &"forearm_r": Vector3(60, 0, 0),
			&"upper_arm_l": Vector3(22, 0, 14), &"forearm_l": Vector3(95, 0, 0)},
	# Crouched and shooting over it.
	&"crouch_aim": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"chest": Vector3(-4, 8, 0), &"head": Vector3(4, 0, 0),
			&"upper_arm_r": Vector3(84, 10, 0), &"forearm_r": Vector3(4, 0, 0),
			&"upper_arm_l": Vector3(20, 0, 12), &"forearm_l": Vector3(95, 0, 0)},
	# Hunched right down, head in: rounds cracking over.
	&"duck": {&"thigh_r": Vector3(105, 0, 10), &"thigh_l": Vector3(105, 0, -10), &"shin_r": Vector3(-140, 0, 0),
			&"shin_l": Vector3(-140, 0, 0), &"foot_r": Vector3(35, 0, 0), &"foot_l": Vector3(35, 0, 0),
			&"abdomen": Vector3(-20, 0, 0), &"chest": Vector3(-30, 0, 0), &"head": Vector3(-5, 0, 0),
			&"upper_arm_r": Vector3(35, 0, -10), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(35, 0, 14), &"forearm_l": Vector3(105, 0, 0)},
	# Hit and still up (OutlawBrain's wince): hunched over it, head down to it, the gun arm let down.
	&"wince": {&"abdomen": Vector3(-10, 0, 0), &"chest": Vector3(-16, 0, 0), &"head": Vector3(-22, 0, 0),
			&"upper_arm_r": Vector3(16, 0, -6), &"forearm_r": Vector3(45, 0, 0),
			&"upper_arm_l": Vector3(12, 0, 10), &"forearm_l": Vector3(70, 0, 0)},
	# Crouched, pressing on a wound.
	&"tend": {&"thigh_r": Vector3(95, 0, 8), &"thigh_l": Vector3(95, 0, -8), &"shin_r": Vector3(-125, 0, 0),
			&"shin_l": Vector3(-125, 0, 0), &"foot_r": Vector3(30, 0, 0), &"foot_l": Vector3(30, 0, 0),
			&"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-25, 0, 0), &"head": Vector3(-15, 0, 0),
			&"upper_arm_r": Vector3(30, 0, -18), &"forearm_r": Vector3(100, 0, 0),
			&"upper_arm_l": Vector3(30, 0, 18), &"forearm_l": Vector3(100, 0, 0)},
	# Cowering: hunched, arms over his head.
	&"cower": {&"thigh_r": Vector3(40, 0, 6), &"thigh_l": Vector3(40, 0, -6), &"shin_r": Vector3(-70, 0, 0),
			&"shin_l": Vector3(-70, 0, 0), &"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-25, 0, 0),
			&"head": Vector3(-20, 0, 0), &"upper_arm_r": Vector3(140, 0, -30), &"forearm_r": Vector3(110, 0, 0),
			&"upper_arm_l": Vector3(140, 0, 30), &"forearm_l": Vector3(110, 0, 0)},
	# Sat at a table: knees bent square, leaning in on his forearms (the rig drops till his feet
	# are on the floor, so the chair takes his weight).
	&"sit": {&"thigh_r": Vector3(88, 0, 6), &"thigh_l": Vector3(84, 0, -8), &"shin_r": Vector3(-82, 0, 0),
			&"shin_l": Vector3(-92, 0, 0), &"foot_r": Vector3(-4, 0, 0), &"foot_l": Vector3(2, 0, 0),
			&"abdomen": Vector3(-8, 0, 0), &"chest": Vector3(-12, 0, 0), &"head": Vector3(6, 0, 0),
			&"upper_arm_r": Vector3(40, 0, -4), &"forearm_r": Vector3(80, 0, 0),
			&"upper_arm_l": Vector3(34, -20, 16), &"forearm_l": Vector3(88, 0, 0)},
	# A kick: his right leg swung forward and low (a chair's legs, a man on the floor), the sole first,
	# his left knee soft under him, leaning back off it, his arms out a little for his balance.
	&"kick": {&"thigh_r": Vector3(55, 0, 0), &"shin_r": Vector3(-14, 0, 0), &"foot_r": Vector3(-22, 0, 0),
			&"thigh_l": Vector3(8, 0, 0), &"shin_l": Vector3(-12, 0, 0), &"abdomen": Vector3(6, 0, 0),
			&"chest": Vector3(4, 0, 0), &"upper_arm_r": Vector3(-10, 0, 24), &"upper_arm_l": Vector3(10, 0, -28),
			&"forearm_r": Vector3(20, 0, 0), &"forearm_l": Vector3(20, 0, 0)},
	# Sat back in his chair: shoulders back against its back, head level, hands in his lap (Sean,
	# 2026-10-21: his weight over the back of the seat, so when the chair's back legs go he goes
	# over with it).
	&"sit_back": {&"thigh_r": Vector3(88, 0, 6), &"thigh_l": Vector3(84, 0, -8), &"shin_r": Vector3(-82, 0, 0),
			&"shin_l": Vector3(-92, 0, 0), &"foot_r": Vector3(-4, 0, 0), &"foot_l": Vector3(2, 0, 0),
			&"abdomen": Vector3(6, 0, 0), &"chest": Vector3(12, 0, 0), &"neck": Vector3(-6, 0, 0),
			&"head": Vector3(-8, 0, 0),
			&"upper_arm_r": Vector3(24, 0, -6), &"forearm_r": Vector3(62, 0, 0),
			&"upper_arm_l": Vector3(24, 0, 6), &"forearm_l": Vector3(62, 0, 0)},
	# Leaning in over the table on his forearms, shoulders hunched, head up to look at you (the
	# painting's man).
	&"sit_lean": {&"thigh_r": Vector3(88, 0, 6), &"thigh_l": Vector3(84, 0, -8), &"shin_r": Vector3(-82, 0, 0),
			&"shin_l": Vector3(-92, 0, 0), &"foot_r": Vector3(-4, 0, 0), &"foot_l": Vector3(2, 0, 0),
			&"abdomen": Vector3(-16, 0, 0), &"chest": Vector3(-20, 0, 0), &"neck": Vector3(10, 0, 0),
			&"head": Vector3(14, 0, 0),
			&"upper_arm_r": Vector3(88, 6, 18), &"forearm_r": Vector3(98, 86, 0), &"hand_r": Vector3(-12, 0, 12),
			&"upper_arm_l": Vector3(40, 0, -8), &"forearm_l": Vector3(60, 0, 0)},
	# Arms out at someone: a shove, a grab at his collar.
	&"shove": {&"upper_arm_r": Vector3(80, 0, -6), &"forearm_r": Vector3(10, 0, 0),
			&"upper_arm_l": Vector3(80, 0, 6), &"forearm_l": Vector3(10, 0, 0), &"chest": Vector3(-8, 0, 0)},
	# On his belly (the rig is laid flat): arms forward, head up.
	&"prone": {&"upper_arm_r": Vector3(150, 0, 12), &"forearm_r": Vector3(25, 0, 0),
			&"upper_arm_l": Vector3(150, 0, -12), &"forearm_l": Vector3(25, 0, 0), &"head": Vector3(55, 0, 0)},
	&"lie": {&"upper_arm_r": Vector3(165, 0, 20), &"forearm_r": Vector3(60, 0, 0),
			&"upper_arm_l": Vector3(165, 0, -20), &"forearm_l": Vector3(60, 0, 0), &"head": Vector3(20, 0, 0)},
	# Bent over, walking backwards, both hands down on a man's collar, dragging him.
	&"drag": {&"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-30, 0, 0), &"head": Vector3(20, 0, 0),
			&"upper_arm_r": Vector3(60, 0, 8), &"forearm_r": Vector3(10, 0, 0),
			&"upper_arm_l": Vector3(60, 0, -8), &"forearm_l": Vector3(10, 0, 0),
			&"thigh_r": Vector3(25, 0, 4), &"thigh_l": Vector3(25, 0, -4), &"shin_r": Vector3(-35, 0, 0),
			&"shin_l": Vector3(-35, 0, 0)},
	&"prone_aim": {&"upper_arm_r": Vector3(172, 0, 4), &"forearm_r": Vector3(0, 0, 0),
			&"upper_arm_l": Vector3(140, 0, -25), &"forearm_l": Vector3(45, 0, 0), &"head": Vector3(60, 0, 0)},
	# Getting up (`get_up`; the rig is turned as each stage has it). On his back, arms by his sides:
	&"lie_back": {&"upper_arm_r": Vector3(0, 0, 14), &"upper_arm_l": Vector3(0, 0, -14),
			&"forearm_r": Vector3(10, 0, 0), &"forearm_l": Vector3(10, 0, 0)},
	# ... sat up on the ground, legs out and knees up a little, leaning on his hands behind him:
	&"sit_ground": {&"thigh_r": Vector3(80, 0, 6), &"thigh_l": Vector3(80, 0, -6), &"shin_r": Vector3(-35, 0, 0),
			&"shin_l": Vector3(-25, 0, 0), &"abdomen": Vector3(-8, 0, 0), &"chest": Vector3(-6, 0, 0),
			&"upper_arm_r": Vector3(-42, 0, 14), &"upper_arm_l": Vector3(-42, 0, -14),
			&"forearm_r": Vector3(0, 0, 0), &"forearm_l": Vector3(0, 0, 0)},
	# ... or face down, pushed up onto his hands and knees (the rig face-down: the thighs and arms
	# hang straight down from him, the shins lie back along the ground, his head comes up):
	# ... still sitting, his left leg drawn in under him and the right knee up, a hand behind him:
	&"sit_tuck": {&"thigh_r": Vector3(85, 0, 10), &"thigh_l": Vector3(70, 0, -25), &"shin_r": Vector3(-110, 0, 0),
			&"shin_l": Vector3(-145, 0, 0), &"foot_r": Vector3(25, 0, 0), &"foot_l": Vector3(-30, 0, 0),
			&"abdomen": Vector3(-14, 0, 0), &"chest": Vector3(-10, 0, 0),
			&"upper_arm_r": Vector3(-30, 0, 20), &"upper_arm_l": Vector3(20, 0, -20),
			&"forearm_r": Vector3(0, 0, 0), &"forearm_l": Vector3(20, 0, 0)},
	# ... up on his knees (thighs upright, shins back along the ground), a hand out on the ground:
	&"kneel": {&"thigh_r": Vector3(5, 0, 12), &"thigh_l": Vector3(5, 0, -12), &"shin_r": Vector3(-95, 0, 0),
			&"shin_l": Vector3(-95, 0, 0), &"foot_r": Vector3(-50, 0, 0), &"foot_l": Vector3(-50, 0, 0),
			&"abdomen": Vector3(-15, 0, 0), &"chest": Vector3(-10, 0, 0), &"head": Vector3(10, 0, 0),
			&"upper_arm_r": Vector3(40, 0, 12), &"upper_arm_l": Vector3(30, 0, -10),
			&"forearm_r": Vector3(10, 0, 0), &"forearm_l": Vector3(20, 0, 0)},
	# ... his right foot brought up under him, the left knee still down, his hand on his knee:
	&"kneel_up": {&"thigh_r": Vector3(80, 0, 8), &"thigh_l": Vector3(0, 0, -6), &"shin_r": Vector3(-85, 0, 0),
			&"shin_l": Vector3(-95, 0, 0), &"foot_r": Vector3(5, 0, 0), &"foot_l": Vector3(-50, 0, 0),
			&"abdomen": Vector3(-18, 0, 0), &"chest": Vector3(-12, 0, 0), &"head": Vector3(12, 0, 0),
			&"upper_arm_r": Vector3(40, 0, 6), &"upper_arm_l": Vector3(20, 0, -10),
			&"forearm_r": Vector3(30, 0, 0), &"forearm_l": Vector3(20, 0, 0)},
	# ... then up off his heels, bent over with his hands on his knees, before he straightens:
	&"hands_knees": {&"thigh_r": Vector3(50, 0, 6), &"thigh_l": Vector3(50, 0, -6), &"shin_r": Vector3(-55, 0, 0),
			&"shin_l": Vector3(-55, 0, 0), &"foot_r": Vector3(8, 0, 0), &"foot_l": Vector3(8, 0, 0),
			&"abdomen": Vector3(-25, 0, 0), &"chest": Vector3(-20, 0, 0), &"head": Vector3(25, 0, 0),
			&"upper_arm_r": Vector3(45, 0, 10), &"upper_arm_l": Vector3(45, 0, -10),
			&"forearm_r": Vector3(15, 0, 0), &"forearm_l": Vector3(15, 0, 0)},
	&"all_fours": {&"thigh_r": Vector3(90, 0, 12), &"thigh_l": Vector3(90, 0, -12), &"shin_r": Vector3(-90, 0, 0),
			&"shin_l": Vector3(-90, 0, 0), &"foot_r": Vector3(-40, 0, 0), &"foot_l": Vector3(-40, 0, 0),
			&"upper_arm_r": Vector3(90, 0, 6), &"upper_arm_l": Vector3(90, 0, -6),
			&"forearm_r": Vector3(5, 0, 0), &"forearm_l": Vector3(5, 0, 0), &"neck": Vector3(20, 0, 0),
			&"head": Vector3(15, 0, 0)},
}
## Poses lying down (the rig is turned face-down). "lie" is lying flat by choice (behind something
## low), and he can get up again; "prone" is down because his legs have gone.
const PRONE_POSES := [&"prone", &"prone_aim"]

## Cone-twist limits at each segment's joint to its parent: [swing, twist] degrees.
const JOINT_LIMITS := {
	&"abdomen": [20, 12], &"chest": [22, 12], &"neck": [30, 25], &"head": [35, 30],
	&"upper_arm": [80, 40], &"forearm": [70, 10], &"hand": [55, 20],
	&"thigh": [60, 20], &"shin": [70, 5], &"foot": [30, 5],
}
## Cones centred on the joint's anatomical middle rather than the pose he went limp in, [the middle
## as the poses' x (degrees from standing: + is forward for the hip, back for the spine), span]: the
## hip flexes to 120 and extends to 20, the low back bends 38 forward and 14 back, the chest 34 and
## 18 (normal ranges: American Academy of Orthopaedic Surgeons). Centred on his standing pose, his
## hip went 60 back and his spine 42 with it: pushed over backwards on planted feet he arched into
## a bridge on his head and heels (experiments/physics_lab, N_blow_beam_chest, 2026-10-21).
const CONE_CENTRE := {&"thigh": [50.0, 70.0], &"abdomen": [-12.0, 26.0], &"chest": [-8.0, 26.0]}
## segment -> {"centre": the child's direction at the cone's middle, in the parent's frame, "span",
## "turn": the child's turn in the parent there, "axis": its own axis in its frame} (for the lab)
var cone_frames := {}
const FINGERS := ["thumb", "index", "middle", "ring", "little"]
## Each part's share of the body's mass, after the cadaver measurements in D. A. Winter,
## "Biomechanics and Motor Control of Human Movement" (table 4.1, from Dempster 1955); head and neck
## split as de Leva (1996). Weighing the parts by their capsules' volume made the trunk 70% of him
## and a foot 0.8% (real: 50% and 1.45%), and Jolt couldn't hold a 25 kg chest to a third of a
## kilo of hand or a man to a 0.7 kg foot: the feet and head overran their joints on landing.
const MASS_SHARE := {
	&"pelvis": 0.142, &"abdomen": 0.139, &"chest": 0.216, &"neck": 0.012, &"head": 0.069,
	&"upper_arm": 0.028, &"forearm": 0.016, &"hand": 0.006,
	&"thigh": 0.100, &"shin": 0.0465, &"foot": 0.0145,
}

@export var person_id := &"outlaw"
@export var rng_seed := 1
@export var skin_tone := Color(0.72, 0.52, 0.4)
@export var shirt_color := Color(0.66, 0.6, 0.5)
## Alpha 0 = no vest / no coat.
@export var vest_color := Color(0.22, 0.17, 0.13)
@export var coat_color := Color(0.4, 0.33, 0.25, 0.0)
@export var trousers_color := Color(0.3, 0.27, 0.23)
## Alpha 0: no hat.
@export var hat_color := Color(0.18, 0.14, 0.11)
## Alpha 0 = no bandana.
@export var bandana_color := Color(0.55, 0.12, 0.1)
## His bandana pulled up over his nose and mouth (a Studio man's `cloth_bandana_mask`,
## tools/faces/bandana.py), in place of the one at his neck.
@export var masked := false
## A talking face (his model's report has a "facerig") comes alive: FaceLife, his look and his
## expressions. Off where something else drives his face (the face lab's sheets and takes).
@export var face_life := true
## Face and hair: see PeopleArt.face (tone comes from skin_tone).
@export var look := {"hair": Color(0.22, 0.15, 0.09), "moustache": &"walrus", "beard": &"stubble", "age": 0.4, "brows": 0.7}
@export var has_gun := true
## Which generated body he has (assets/people/<id>.glb, from tools/blender/make_people.py); empty
## or missing = the code-lofted BodyMesh.
@export var body_model := &"outlaw"
## Wear the model's painted and baked textures (the painting's man). Off, he wears the code-painted
## cloth in his own colours and his own painted face on the same body: the townsfolk, who are not
## all the one man (docs/ART_REVIEW.md §6).
@export var use_paint := true
## Starts with it in the holster (a man minding his own business); the brain draws it.
@export var start_holstered := true
@export var total_mass := 80.0

var anatomy: Anatomy
var physiology: Physiology
## His place in the people's order (PeopleTick): given the first time he enters the world, kept.
var tick_index := -1
## His own nodes PeopleTick ticks after him, in tree order (his brain, face, senses: add_ticker).
var _tickers: Array[Node] = []
var _tickers_sorted := true
## Those of them that say whether he may tick slowly, and whether he's in trouble (PeopleTick's bands).
var _slow_says: Array[Node] = []
var _trouble_says: Array[Node] = []
## His tick band (PeopleTick, step 4b): 0 near (every tick), 1 middle, 2 far, by his distance with
## a margin each way; what he's owed of the ticks he was left out of (s), and this tick's delta
## (the tick's own and what he was owed). Woken (`wake`): he ticks next tick whatever his band.
var tick_band := 0
## How often he ticks now (1 every tick, 2, 4: his band, nearer if seen; Senses looks as often).
var tick_every := 1
var tick_owed := 0.0
var tick_dt := 0.0
var woken := false
var parts := {}  ## segment -> the physics body carrying it (AnimatableBody3D, RigidBody3D when limp)
var pivots := {}  ## segment -> joint pivot (while standing)
var visuals := {}  ## segment -> Node3D holding its meshes and decals
var fingers := {}  ## finger id -> knuckle pivot
var finger_bones := {}  ## finger id -> Array[Node3D], knuckle to tip
## Garments, outer to inner: {id, covers: Array[StringName], resistance (J), color, holes: []}.
var garments: Array[Dictionary] = []
## {segment, entry, exit (segment-local or null), lodged, hits, bleeds, garments, stain (Decal)}
var wounds: Array[Dictionary] = []
var limp := false
## A drop under his feet further than this (m) and he falls rather than steps down: further than
## the snap to the ground ever followed.
const DROP_FALLS := 1.0
## Ground steeper than this (the up of its face: ~50 degrees) he can't walk down, and going on down
## it more than STEEP_DROP (m) below where he last stood level he falls.
const STEEP_UP := 0.64
const STEEP_DROP := 0.5
var _stood := false  # the last snap found ground under him
var _level_y := 0.0  # where he last stood on ground he could walk
## Limp: what he breaks being thrown into timber (a railing).
var _impacts: BodyImpacts
## Seconds left on his feet after a ball that drops him caught him on the move (_knocked): his
## stride carries him on, slowing, as he folds round it, then he goes down. Brains leave him be.
var stumbling := 0.0
var pose := &"stand"
## Staged scenes' touch on top of whatever pose he's in: segment -> extra rotation (degrees, same
## axes as POSES), e.g. {&"head": Vector3(0, 12, -10)} to turn his head to you and tip it.
var pose_offsets := {}
var aim_pitch := 0.0
var held_gun: Node3D
var gun_holstered := false
const DRAW_TIME := 0.5
## Shapes drawn from both sides: single sheets (open garments, the brim, the band, the hair shell,
## whose faces point inward).
const DOUBLE_SIDED := ["vest", "coat", "trousers", "gun_belt", "belt", "bandana", "bandana_mask", "hat_brim", "hat_band", "cravat", "shirt", "hair", "apron"]
## How a painted texture (tools/paint_bake.gd) is shown (body_skin.gdshaderinc): self_lit of it glows
## as painted, light and all; the rest is lit by the scene's lamps × paint_gain (so he still darkens
## in shadow and warms by a fire), wrapped round him (paint_wrap) as the shading is painted in, no
## light making him more than paint_limit × painted (light_steps: how many steps the light takes
## across him, 0 smooth). Tuned in the character lab so he matches the painting under its light.
## A static so the lab can try others.
## The hybrid finish (docs/ART_REVIEW.md §6, tools/paint/finish.py HYBRID): his textures are the
## model's flat-lit painting of him and the scene's light does the shading: nothing self-lit, no
## steps, ambient on, the light not eased off till well past painted. (The old look, tuned to the
## painting's own pixels: self_lit 0.35, paint_gain 4.0, paint_wrap 0.9, paint_limit 1.3,
## light_steps 4, paint_ambient 0.)
static var paint_look := {&"self_lit": 0.0, &"paint_gain": 2.2, &"paint_wrap": 0.3, &"paint_limit": 4.0,
		&"light_steps": 0.0, &"paint_ambient": 1.0}
var _draw_left := 0.0
var time_scale := 1.0

var _rig: Node3D
var _blocker: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _flinch := {}  ## segment -> [offset degrees, velocity]
var _stumble := {}  ## the ball that's taking him down: segment, where on it, direction, momentum
var _stumble_lean := {}  ## segment -> degrees he's folded by as he stumbles (on top of the pose)
var _legs_gone := false  ## the stumble ended because his legs gave: no column, his knees go first
var _favour := {}  ## region ("leg_r", "arm_l", "body"...) -> [how much he favours it 0..1, its rate]
var _favour_lean := {}  ## segment -> degrees the wounds' consequence bends him by (on top of the pose)
var _pose_now := {}  ## segment -> current pose rotation (degrees), blending to the target
var _breath := 0.0
## What his wounds show round him as time goes (blood from his ears, mouth, nose, drips, prints).
var signs: WoundSigns
var _velocity_now := Vector3.ZERO
var _chest_was := Vector3.INF
var _rids: Array[RID] = []
var _face_mats: Array[ShaderMaterial] = []
var _pallor_in := 0.0
var _bands: Array[Dictionary] = []  ## the dressings on him: {mi, segment}
var _was_alive := true
## How each part was moving the last tick he stood (m/s and rad/s, from its script-driven pose and
## his walking): what he carries into the fall when he goes limp (go_limp), so a running man
## pitches on along his run instead of stopping dead (experiments/physics_lab, fault 2). Worked
## out only then (_carry_velocities), from his parts' transforms the last two ticks he stood.
var _carry_last := {}  ## segment -> its global transform the tick before _carry_new's
var _carry_new := {}  ## segment -> its global transform at the end of the last tick he stood
var _carry_dt := 0.0  ## that tick's length
## Faster than this in one tick is a teleport (placed, spawned, snapped), not movement.
const CARRY_MAX_SPEED := 12.0
const CARRY_MAX_SPIN := 25.0
var _was_conscious := true
var _cough_in := 3.0
## Wound openings per segment: [{at (segment-centred), energy (J), radius (m)}].
var openings := {}
var xray := false
## Moving: how fast (m/s) and how (&"walk", &"run", &"limp", &"crawl"; &"" standing still).
var move_speed := 0.0
var gait := &""
## Down on the ground but still moving (legs gone, not knocked out): posed, not a ragdoll.
var prone := false
## Someone has him by the collar and is dragging him (a friend getting him out of the line of fire).
var dragged_by: Node3D
var _gait_phase := 0.0
## Experiment (Sean, 2026-10-17: "let's just experiment with it"): walking and running by motion
## capture (experiments/mocap_walk/: a CMU walk and run retargeted onto this rig) in place of the
## swinging sines of _gait_overlay. Off unless something turns it on (the lab's --mocap, the dev
## bridge's "mocap on").
static var mocap_gait := false
static var _mocap_clips := {}  ## gait -> {stride (m), frames: [{segment: Quaternion}]}, loaded once
var _mocap_w := 0.0  ## how far the clip has him: eases in as he sets off, out as he stops
var _mocap_last := {}  ## the clip he was last on (to ease out of)
var _mocap_hips := -1.0  ## his hip joints' height above the ground in the clip now, in leg lengths (-1: none)
## A clip of motion he's playing (MotionClip; play_clip): its targets lead his pose while it
## plays, on top of whatever physics and his wounds do to him.
signal clip_done(clip_name: StringName)
signal clip_event(clip_name: StringName, event: String)
signal clip_struck(member: Node, result: StringName, speed: float)  ## a swung part met a kit prop's member at speed (m/s): broke, moved or held
var _clip: MotionClip
var _clip_t := 0.0
var _clip_w := 0.0  ## how far the clip has him (eases in and out, as the gait clip does)
var _clip_speed := 1.0
var _clip_loop := false
var _clip_last := {}  ## its last frame (to ease out of)
var _clip_hips := -1.0
var _clip_hold := 0.0  ## s the clip stands where it is: his boot stopped on something that held
var _clip_opts := {}  ## "travel": false (he stays put; whoever plays it moves him)
var _clip_struck := {}  ## StructureMember -> true: struck once this clip
var _clip_part_was := {}  ## striking part -> its global transform last tick
const CLIP_BLOW_MASS := 8.0  ## kg behind a kicking boot (the chair lab's: a leg's share of him)
## His own way of walking (WalkStyles, config/walks.json): a clip played looped while he walks,
## its rate following his speed, his walking doing the moving. Empty: the swinging gait.
var walk_clip := &""
var _walk_clip_on := false
const CLIP_STRIKE_SPEED := 1.5  ## m/s: slower than this a boot strikes nothing
var _rest_foot_y := 0.0
var _moved_this_tick := false
## Whole ticks of walking left over when a slowed tick (PeopleTick's bands) got him to his point
## early: the next tick's `walk_to` walks them, as he'd have walked on at every tick. Always none
## at one tick a tick; dropped if he doesn't walk on the next tick.
var _walk_spare := 0.0
var _pool: Decal
var _pool_ml := 0.0
var _day_cycle: Node
## The generated body (BodyMesh): one skeleton, a bone per segment, following the hitboxes.
var skeleton: Skeleton3D
## The hat he's wearing, as its own thin hitbox on his head (`Layers.HATS`, meta `hat_of`): a ball
## through it takes it off (`take_hat_shot`), and it lands as a thing of its own (group `hats`).
## Null with no hat, or once it's off.
var hat_body: AnimatableBody3D
var hat_off := false
## The hat's shapes (BodyMesh's or the generated body's) and what a felt hat stops of a ball (J).
const HAT_SHAPES := ["hat", "hat_brim", "hat_band"]
const HAT_RESISTANCE := 6.0
var skin_meshes := {}  ## "shape/segment" ("skin/chest", "shirt/upper_arm_r", "hat/head"...) -> MeshInstance3D
var segment_pieces := {}  ## segment -> Array of its generated MeshInstance3Ds (skin and clothes)
var _rigid_meshes := {}  ## MeshInstance3D -> the piece's rigid mesh (swapped in when a limb comes off)
## shape -> one MeshInstance3D drawing all its pieces while he's whole (one draw, not one a
## segment); the pieces stay, hidden, and come back for good at his first opening or lost limb.
var _merged := {}
var _bone_parts: Array[StringName] = []


func _enter_tree() -> void:
	PeopleTick.join(self)


func _exit_tree() -> void:
	PeopleTick.leave(self)


## One of his nodes with a tick of its own (`tick(delta)`), ticked after him by PeopleTick.
func add_ticker(n: Node) -> void:
	if not _tickers.has(n):
		_tickers.append(n)
		_tickers_sorted = false
		if n.has_method(&"can_slow"):
			_slow_says.append(n)
		if n.has_method(&"in_trouble"):
			_trouble_says.append(n)


func remove_ticker(n: Node) -> void:
	_tickers.erase(n)
	_slow_says.erase(n)
	_trouble_says.erase(n)


## Something to react to (a noise he heard, a deed done to him): he ticks next tick, whatever his
## band (PeopleTick, step 4b).
func wake() -> void:
	woken = true


## May PeopleTick tick him less often while he's far off (step 4b)? Only on his feet and going
## about his business: never down (the ragdoll, crawling), stumbling, getting up, dragged, on a
## clip other than his walk; and only while each of his nodes that says (`can_slow`: his brain
## when he's in trouble, fighting, fleeing, tending, rescuing, at a chore) agrees.
func can_slow() -> bool:
	if limp or prone or rising or stumbling > 0.0 or dragged_by != null:
		return false
	if _clip != null and _clip.name != walk_clip:
		return false
	for n: Node in _slow_says:
		if not n.call(&"can_slow"):
			return false
	return true


## Is he in trouble (a fight, running, hands up, getting down: his brain's `in_trouble`)? Then
## whoever's near him ticks every tick too (PeopleTick's bands: near a fight is near).
func in_trouble() -> bool:
	for n: Node in _trouble_says:
		if n.call(&"in_trouble"):
			return true
	return false


func _ready() -> void:
	set_physics_process(true)  # his switch: PeopleTick ticks him while it's on (people_tick)
	if walk_clip == &"":
		walk_clip = WalkStyles.clip_for(person_id, body_model)
	add_to_group(&"people")
	Events.ground_changed.connect(_on_ground_changed)
	_rng.seed = rng_seed
	anatomy = Anatomy.shared()
	physiology = Physiology.new(null, anatomy)
	physiology.roll_rng.seed = hash(["physiology", rng_seed])  # people's seeds run 501, 502...: their first draws would agree
	physiology.treated.connect(_bind_wound)
	physiology.warm()  # its shared lists filled here, not by the workers (PeopleTick)
	_dress()
	_build()
	if face_life and PeopleBodies.report(body_model).has("facerig"):
		var life := FaceLife.new()
		life.name = "FaceLife"
		add_child(life)
	if PeopleBodies.report(body_model).has("facerig"):
		var speech := FaceSpeech.new()   # his mouth saying his lines (Events.spoke)
		speech.name = "FaceSpeech"
		add_child(speech)
	if has_gun:
		_give_gun()
	_use_wound_materials()
	BodyInterior.warm_up(get_tree())
	Settings.changed.connect(_on_settings_changed)
	_apply_pose(0.0, true)
	set_process(false)  # (his bones follow on his tick while he stands; _process only when limp)
	Events.scorched.connect(func(who: Node, amount: float) -> void:
		if who == self:
			physiology.burn(amount)
			burn_marks(amount))
	if xray_all:
		set_xray(true)


func _dress() -> void:
	var torso: Array[StringName] = [&"chest", &"abdomen"]
	var arms: Array[StringName] = [&"upper_arm_r", &"upper_arm_l", &"forearm_r", &"forearm_l"]
	var legs: Array[StringName] = [&"thigh_r", &"thigh_l", &"shin_r", &"shin_l"]
	if coat_color.a > 0.0:
		garments.append({"id": &"coat", "covers": torso + arms + [&"pelvis", &"thigh_r", &"thigh_l"] as Array[StringName], "resistance": 6.0, "color": coat_color, "holes": []})
	if vest_color.a > 0.0:
		garments.append({"id": &"vest", "covers": torso, "resistance": 3.0, "color": vest_color, "holes": []})
	garments.append({"id": &"shirt", "covers": torso + arms, "resistance": 1.0, "color": shirt_color, "holes": []})
	garments.append({"id": &"boots", "covers": [&"foot_r", &"foot_l"] as Array[StringName], "resistance": 15.0, "color": Color(0.2, 0.13, 0.08), "holes": []})
	garments.append({"id": &"trousers", "covers": [&"pelvis"] + legs as Array[StringName], "resistance": 2.0, "color": trousers_color, "holes": []})
	garments.append({"id": &"long_johns", "covers": torso + arms + legs + [&"pelvis"] as Array[StringName], "resistance": 0.5, "color": Color(0.8, 0.74, 0.64), "holes": []})


## The outermost garment on a segment, or {} for bare skin.
func outer_garment(segment: StringName) -> Dictionary:
	for g in garments:
		if g.covers.has(segment):
			return g
	return {}


func _material_for(segment: StringName) -> StandardMaterial3D:
	var g := outer_garment(segment)
	if g.is_empty():
		return _skin()
	return GunParts.cloth("%s:%s" % [person_id, g.id], g.color)


func _skin() -> StandardMaterial3D:
	return GunParts.material("skin:%s" % person_id, PixelArt.skin("skin:%s" % person_id, skin_tone, 81 + rng_seed), 0.0, 0.7)


# --- Building ----------------------------------------------------------------------------------

func _build() -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	# Each part's share of him: the published segment masses (MASS_SHARE), or for a part not in
	# the table its capsules' volume at the body's mean density.
	var volumes := {}
	var total_v := 0.0
	for sid: StringName in anatomy.segments:
		var v := 0.0
		for c: Array in anatomy.segments[sid].capsules:
			var r: float = c[2]
			v += PI * r * r * (((c[1] as Vector3) - (c[0] as Vector3)).length() + 4.0 / 3.0 * r)
		volumes[sid] = v
		total_v += v
	var shares := {}
	var total := 0.0
	for sid: StringName in anatomy.segments:
		var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		shares[sid] = MASS_SHARE.get(key, volumes[sid] / total_v)
		total += shares[sid]
	for sid: StringName in anatomy.segment_order():
		var s: Dictionary = anatomy.segments[sid]
		var parent: StringName = s.parent
		var pivot := Node3D.new()
		pivot.name = String(sid)
		var rest := _pivot_rest(sid)
		if parent == &"":
			_rig.add_child(pivot)
			pivot.position = rest
		else:
			(pivots[parent] as Node3D).add_child(pivot)
			pivot.position = rest - _pivot_rest(parent)
		pivots[sid] = pivot
		var part := _new_part(sid, pivot, rest, total_mass * shares[sid] / total)
		var center := anatomy.segment_center(sid)
		for i in s.capsules.size():
			var c: Array = s.capsules[i]
			var shape := CollisionShape3D.new()
			shape.name = "Shape%d" % i
			var cap := CapsuleShape3D.new()
			cap.radius = c[2]
			cap.height = ((c[1] as Vector3) - (c[0] as Vector3)).length() + 2.0 * float(c[2])
			shape.shape = cap
			shape.basis = _along((c[1] as Vector3) - (c[0] as Vector3))
			shape.position = ((c[0] as Vector3) + (c[1] as Vector3)) * 0.5 - center
			part.add_child(shape)
		parts[sid] = part
		var vis := Node3D.new()
		vis.name = "Visual"
		part.add_child(vis)
		visuals[sid] = vis
		_build_visual(sid, vis)
	_build_skin()
	_build_hat_box()
	_new_blocker()


## A standing part: the animated body carrying segment `sid` under its pivot.
func _new_part(sid: StringName, pivot: Node3D, rest: Vector3, mass: float) -> AnimatableBody3D:
	var part := AnimatableBody3D.new()
	part.name = "Part"
	part.sync_to_physics = false
	part.collision_layer = Layers.BODY_PARTS
	part.collision_mask = 0
	part.set_meta(&"human_body", self)
	part.set_meta(&"segment", sid)
	part.set_meta(&"mass", mass)
	pivot.add_child(part)
	part.position = anatomy.segment_center(sid) - rest
	return part


## The capsule that keeps the player out of him (see _set_blocker).
func _new_blocker() -> void:
	_blocker = StaticBody3D.new()
	_blocker.name = "Blocker"
	_blocker.set_meta(&"human_body", self)
	_blocker.collision_layer = Layers.PEOPLE
	_blocker.collision_mask = 0
	var bs := CollisionShape3D.new()
	var bc := CapsuleShape3D.new()
	bc.radius = 0.28
	bc.height = anatomy.height
	bs.shape = bc
	bs.position.y = anatomy.height * 0.5
	_blocker.add_child(bs)
	add_child(_blocker)


## The worn hat's hitbox, fitted to its meshes: a flat disc for the brim and a cylinder for the
## crown, on his head part (so it follows every pose and the ragdoll).
func _build_hat_box() -> void:
	var box := _hat_box()
	if box.size == Vector3.ZERO:
		return
	hat_body = AnimatableBody3D.new()
	hat_body.name = "Hat"
	hat_body.sync_to_physics = false
	hat_body.collision_layer = Layers.HATS
	hat_body.collision_mask = 0
	hat_body.set_meta(&"hat_of", self)
	(parts[&"head"] as Node3D).add_child(hat_body)
	hat_body.position = box.get_center()
	var brim := CollisionShape3D.new()
	brim.name = "Brim"
	var bc := CylinderShape3D.new()
	bc.radius = maxf(box.size.x, box.size.z) * 0.5
	bc.height = 0.02
	brim.shape = bc
	brim.position.y = -box.size.y * 0.5 + 0.02
	hat_body.add_child(brim)
	var crown := CollisionShape3D.new()
	crown.name = "Crown"
	var cc := CylinderShape3D.new()
	cc.radius = minf(box.size.x, box.size.z) * 0.36
	cc.height = maxf(box.size.y - 0.02, 0.04)
	crown.shape = cc
	crown.position.y = 0.01
	hat_body.add_child(crown)


## The worn hat's pieces (rest space, as skinned to his head).
func _hat_pieces() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for key: String in skin_meshes:
		if key.get_slice("/", 0) in HAT_SHAPES:
			out.append(skin_meshes[key])
	return out


## The worn hat's bounds in his head part's space (zero if he has none).
func _hat_box() -> AABB:
	var pieces := _hat_pieces()
	if pieces.is_empty() or skeleton == null or skeleton.find_bone("head") < 0:
		return AABB()
	var to_head := skeleton.get_bone_rest(skeleton.find_bone("head")).affine_inverse()
	var box := AABB()
	var first := true
	for mi in pieces:
		var b := to_head * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## A ball through his hat (world `at`, along `dir`, carrying `energy` J, fired by `shooter`): the
## hat's off, flying with the ball's push, and he knows it. Returns the energy the ball keeps.
func take_hat_shot(at: Vector3, dir: Vector3, energy: float, shooter: Node, mass := 0.0165) -> float:
	if hat_off or hat_body == null:
		return energy
	var speed := sqrt(2.0 * energy / maxf(mass, 0.001))
	# A felt hat weighs ~120 g; the ball gives it a share of its momentum and it flips off.
	var push := clampf(mass * speed * 0.15 / 0.12, 1.5, 6.0)
	knock_hat_off(dir.normalized() * push + Vector3.UP * 1.2, at)
	Events.hat_shot.emit(self, shooter, at)
	if shooter:
		Events.deed.emit(shooter, &"shoot_at", self, at)
	return maxf(energy - HAT_RESISTANCE, 0.0)


## Down and his hat meets the ground (or anything solid): it's pushed off his head and goes its own
## way with what his head was doing. Kept on as part of his head, its brim went 7-11 cm into the
## floor as he lay (experiments/physics_lab, the Studio's men, 2026-10-21).
func _hat_meets_ground() -> void:
	var head := parts.get(&"head") as RigidBody3D
	if head == null or head.sleeping:
		return
	var space := World.space(self)
	for c in hat_body.get_children():
		if not c is CollisionShape3D:
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = (c as CollisionShape3D).shape
		q.transform = (c as CollisionShape3D).global_transform
		q.collision_mask = Layers.WORLD
		Prof.count(&"q_body")
		if not space.intersect_shape(q, 1).is_empty():
			var hat := knock_hat_off(head.linear_velocity)
			if hat:
				hat.angular_velocity = head.angular_velocity
			return


## Take the hat off his head and let it fall (or fly) as a thing of its own, holed where `at` is.
func knock_hat_off(velocity := Vector3.ZERO, at := Vector3.INF) -> RigidBody3D:
	if hat_off or hat_body == null:
		return null
	hat_off = true
	var head := parts[&"head"] as Node3D
	var box := _hat_box()
	var rest_to_world := head.global_transform * skeleton.get_bone_rest(skeleton.find_bone("head")).affine_inverse()
	var hat := RigidBody3D.new()
	hat.name = "HatOf_%s" % name
	hat.add_to_group(&"hats")
	hat.set_meta(&"hat_of", self)
	hat.collision_layer = Layers.DEBRIS
	hat.collision_mask = Layers.DEBRIS_MASK
	hat.mass = 0.12
	hat.linear_damp = 0.6
	hat.angular_damp = 1.5
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(box.size.x, maxf(box.size.y * 0.6, 0.04), box.size.z)
	cs.shape = shape
	hat.add_child(cs)
	var host := get_parent() if get_parent() else self
	host.add_child(hat)
	hat.global_transform = Transform3D(head.global_basis, head.global_transform * box.get_center())
	for mi in _hat_pieces():
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.material_override = mi.material_override
		hat.add_child(copy)
		copy.global_transform = rest_to_world
		mi.visible = false
	# Hidden for good: nothing shows the worn hat again (the merged shapes are its pieces' too).
	for key: String in skin_meshes.keys():
		if key.get_slice("/", 0) in HAT_SHAPES:
			skin_meshes.erase(key)
	for shape_name: String in _merged.keys():
		if shape_name in HAT_SHAPES:
			(_merged[shape_name] as MeshInstance3D).visible = false
	if at != Vector3.INF:
		hat.set_meta(&"hole", hat.to_local(at))
	hat.linear_velocity = velocity
	hat.angular_velocity = Vector3(velocity.z, 0.0, -velocity.x) * 2.0 + Vector3.UP * 4.0
	hat_body.queue_free()
	hat_body = null
	return hat


## Where a segment turns about, in the rest pose: the joint with its parent.
func _pivot_rest(sid: StringName) -> Vector3:
	var s: Dictionary = anatomy.segments[sid]
	if s.parent == &"":
		return anatomy.segment_center(sid)
	if String(sid).begins_with("foot"):
		return anatomy.segments[s.parent].b
	return s.a


## A basis whose Y axis points along `axis`.
static func _along(axis: Vector3) -> Basis:
	var y := axis.normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


func _build_visual(sid: StringName, vis: Node3D) -> void:
	if String(sid).begins_with("hand"):
		_build_hand(sid, vis, anatomy.segment_center(sid))


## The skin and clothes (the generated body if there is one, else BodyMesh) skinned to a skeleton whose bones follow the parts.
func _build_skin() -> void:
	var outfit := {"shirt": true, "vest": vest_color.a > 0.0, "coat": coat_color.a > 0.0, "trousers": true,
			"boots": true, "gun_belt": has_gun, "bandana": bandana_color.a > 0.0, "hat": hat_color.a > 0.0,
			"hair": look.get("hair_long", false), "mask": masked}
	var data := PeopleBodies.build(anatomy, outfit, body_model)
	if data.has("skin_tone"):
		skin_tone = data.skin_tone
	skeleton = Skeleton3D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	var skin := Skin.new()
	var rests: Array[Transform3D] = data.rests
	for i in data.bones.size():
		var sid: StringName = data.bones[i]
		skeleton.add_bone(String(sid))
		skeleton.set_bone_rest(i, rests[i])
		skin.add_bind(i, rests[i].affine_inverse())
		_bone_parts.append(sid)
	_add_finger_bones(data, skin, rests)
	_shoulders = PeopleBodies.add_shoulders(skeleton, skin, data, _bone_parts)
	skeleton.reset_bone_poses()
	var f := look.duplicate()
	f["tone"] = skin_tone
	f["seed"] = rng_seed
	if data.get("textures", {}).has("head_ao"):
		f["ao"] = (data.textures.head_ao as Texture2D).get_image()
	if data.get("textures", {}).has("face") and use_paint:
		f["portrait"] = (data.textures.face as Texture2D).get_image()
	var skin_mat := PeopleArt.material("skin:%s" % person_id, PeopleArt.skin(person_id, skin_tone, 81 + rng_seed), 0.7)
	var mats := {
		"skin": skin_mat,
		"head": PeopleArt.face_material("face:%s" % person_id, PeopleArt.face(person_id, f)),
		"shirt": _cloth("shirt", shirt_color, &"plain"),
		"vest": _cloth("vest", vest_color, &"wool", false),
		"coat": _cloth("coat", coat_color, &"wool", false),
		"trousers": _cloth("trousers", trousers_color, &"wool", false),
		"cravat": _cloth("cravat", Color(0.08, 0.06, 0.05), &"plain", false),
		"boots": _cloth("boots", Color(0.2, 0.13, 0.08), &"leather"),
		"gun_belt": PeopleArt.material("gunbelt:%s" % person_id, PeopleArt.cartridge_belt(person_id, Color(0.34, 0.21, 0.11), rng_seed), 0.7, false),
		"belt": _cloth("belt", Color(0.16, 0.1, 0.06), &"leather", false),
		"holster": _cloth("holster", Color(0.38, 0.24, 0.12), &"leather"),
		"bandana": _cloth("bandana", bandana_color, &"plain", false),
		"hat": _cloth("hat", hat_color, &"felt"),
		"hat_brim": _cloth("hat", hat_color, &"felt", false),
		"hat_band": _cloth("hatband", hat_color.darkened(0.55), &"leather", false),
		"hair": _cloth("hair", look.get("hair", Color(0.22, 0.15, 0.09)), &"felt", false),
	}
	var baked: Dictionary = data.get("textures", {}) if use_paint else {}
	var paint: Dictionary = data.get("paint", {}) if use_paint else {}
	var talking := PeopleBodies.report(body_model).has("facerig")
	for shape: String in data.shapes:
		var base: StandardMaterial3D = mats.get(shape, skin_mat)
		if baked.has(shape):
			base = _baked_cloth(shape, baked[shape])
		if paint.has(shape):
			base = _baked_cloth("paint_" + shape, baked["paint_" + shape])
		var pieces: Dictionary = data.shapes[shape]
		for b: int in pieces:
			var sid: StringName = data.bones[b]
			var mi := MeshInstance3D.new()
			mi.name = "%s_%s" % [shape.to_pascal_case(), sid]
			mi.mesh = pieces[b][0]
			_rigid_meshes[mi] = pieces[b][1]
			# A talking head (tools/faces/talking_face.py) is drawn from both sides: its new face's
			# stitch has slivers that turn edge-on as his head turns (FaceLife), and would show gaps.
			mi.material_override = _piece_material(base, DOUBLE_SIDED.has(shape) or (shape == "head" and talking))
			if baked.has(shape):
				# His own painted texture (the Studio's Rodin men) carries its own shading: the light
				# smooth on it, not cut into the old look's four flat steps, which carved their faces
				# into hard patches in the sun (Sean, 2026-10-25), as paint_look already does.
				(mi.material_override as ShaderMaterial).set_shader_parameter(&"light_steps", 0.0)
			if paint.has(shape):
				(mi.material_override as ShaderMaterial).set_shader_parameter(&"uv_rect", paint[shape])
				(mi.material_override as ShaderMaterial).set_shader_parameter(&"square_texels",
						float(data.get("paint_squares", {}).get(shape, 1.0)))
				var own_look: Dictionary = data.get("paint_look", {})
				for k: StringName in paint_look:
					(mi.material_override as ShaderMaterial).set_shader_parameter(k, own_look.get(k, paint_look[k]))
				for k: StringName in own_look:
					if not paint_look.has(k):
						(mi.material_override as ShaderMaterial).set_shader_parameter(k, own_look[k])
			if shape == "head" and sid == &"head":
				_wet_eyes(mi.material_override as ShaderMaterial)
			mi.layers = Layers.VIS_BODY
			mi.custom_aabb = AABB(Vector3(-3, -2, -3), Vector3(6, 5, 6))
			skeleton.add_child(mi)
			mi.skin = skin
			mi.skeleton = NodePath("..")
			skin_meshes["%s/%s" % [shape, sid]] = mi
			(segment_pieces.get_or_add(sid, []) as Array).append(mi)
	_own_fingers(data)
	if not _finger_rig.is_empty() or (bool(data.get("whole", false)) and not data.has("fingers")):
		# His skinned hands draw his fingers; the drawn ones only fly when one is shot off. A whole
		# man's own hands are in his skin (the Character Studio's men): the drawn fingers would be
		# a second hand on his, so they're hidden too (until the Studio skins his fingers).
		for fid: StringName in finger_bones:
			for bone: Node3D in finger_bones[fid]:
				for c in bone.get_children():
					if c is MeshInstance3D:
						(c as MeshInstance3D).visible = false
	_merge_pieces(skin)
	_update_skeleton()


## Each shape drawn as one mesh while he's whole: the same triangles, skin and material as its
## pieces, so he looks the same. Not the head (the wet eyes are placed in the head piece's own
## space, which its other pieces don't share).
func _merge_pieces(skin: Skin) -> void:
	var by_shape := {}
	for key: String in skin_meshes:
		(by_shape.get_or_add(key.get_slice("/", 0), []) as Array).append(skin_meshes[key])
	for shape: String in by_shape:
		var pieces: Array = by_shape[shape]
		if shape == "head" or pieces.size() < 2:
			continue
		var mesh := _joined(pieces)
		if mesh == null:
			continue
		var first := pieces[0] as MeshInstance3D
		var mi := MeshInstance3D.new()
		mi.name = "%s_whole" % shape.to_pascal_case()
		mi.mesh = mesh
		mi.material_override = first.material_override
		mi.layers = first.layers
		mi.custom_aabb = first.custom_aabb
		skeleton.add_child(mi)
		mi.skin = skin
		mi.skeleton = NodePath("..")
		for p: MeshInstance3D in pieces:
			p.visible = false
		_merged[shape] = mi


## The pieces' single surfaces as one (they share a format: BodyMesh.split_pieces cut them from
## one mesh); null if they don't.
static func _joined(pieces: Array) -> ArrayMesh:
	var fmt := -1
	var out: Array = []
	var count := 0
	for mi: MeshInstance3D in pieces:
		var mesh := mi.mesh as ArrayMesh
		if mesh == null or mesh.get_surface_count() != 1:
			return null
		if fmt == -1:
			fmt = mesh.surface_get_format(0)
		elif mesh.surface_get_format(0) != fmt:
			return null
		var a := mesh.surface_get_arrays(0)
		var n: int = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if out.is_empty():
			out = a
		else:
			for i in Mesh.ARRAY_MAX:
				if a[i] == null:
					continue
				if i == Mesh.ARRAY_INDEX:
					var idx: PackedInt32Array = a[i]
					for k in idx.size():
						idx[k] += count
					a[i] = idx
				out[i].append_array(a[i])
		count += n
	var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
	for shift in [Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT, Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT]:
		flags |= Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift
	var joined := ArrayMesh.new()
	joined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {}, fmt & flags)
	return joined


## From here on each piece draws for itself (an opening is in one segment's own space; a lost
## limb's pieces stop skinning across the joint).
func _unmerge() -> void:
	if _merged.is_empty():
		return
	for mi: MeshInstance3D in _merged.values():
		mi.queue_free()
	_merged.clear()
	for mi: MeshInstance3D in skin_meshes.values():
		mi.visible = true


## The wound shader for a generated piece: textured by its UVs, opened by rest positions (CUSTOM0).
func _piece_material(base: StandardMaterial3D, double_sided: bool) -> ShaderMaterial:
	var m := BodyInterior.skin_material(base)
	if double_sided:
		m.shader = BodyInterior.SKIN_DOUBLE_SHADER
	m.set_shader_parameter(&"use_uv", true)
	m.set_shader_parameter(&"use_custom_pos", true)
	m.set_shader_parameter(&"uv_scale", base.uv1_scale.x)
	m.set_shader_parameter(&"shade_tint", PixelArt.SHADE_TINT)  # the surface-blocks look (art)
	return m


## Glossy eyeballs on the head piece (the shader's rest positions are head-centred).
func _wet_eyes(m: ShaderMaterial) -> void:
	_face_mats.append(m)
	var centre := anatomy.segment_center(&"head")
	var r := anatomy.structure(&"eye_r")
	var l := anatomy.structure(&"eye_l")
	if r.is_empty() or l.is_empty():
		return
	m.set_shader_parameter(&"eye_r_pos", (r.a as Vector3) - centre)
	m.set_shader_parameter(&"eye_l_pos", (l.a as Vector3) - centre)
	# The eyeball and a hair of the lids round it.
	m.set_shader_parameter(&"eye_radius", float(r.radius) + 0.002)
	# His painted whites brightened as his model's report asks (the characters session's men).
	m.set_shader_parameter(&"eye_gain", float(PeopleBodies.report(body_model).get("eye_gain", 1.0)))
	# His face weathered and stern as his model's report asks (body_skin.gdshaderinc face_*; the
	# art session's, 2026-10-13).
	var face: Variant = PeopleBodies.report(body_model).get("weathered", {})
	if not face is Dictionary:
		face = {}
	var skin: Array = face.get("skin", [1.0, 1.0, 1.0])
	m.set_shader_parameter(&"face_skin", Vector3(skin[0], skin[1], skin[2]))
	for k in ["brows", "frown", "sockets", "whites"]:
		m.set_shader_parameter(StringName("face_" + k), float(face.get(k, 0.0)))


## Every mesh showing a body part: the generated skin and clothes pieces, and whatever hangs on
## its visual node (fingers, the gun, the inside once it's opened).
func body_meshes(segment: StringName) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for mi in segment_pieces.get(segment, []):
		out.append(mi)
	var vis: Node3D = visuals.get(segment)
	if vis:
		for mi in vis.find_children("*", "MeshInstance3D", true, false):
			out.append(mi as MeshInstance3D)
	return out


## After an amputation nothing may stretch across the lost joint: the lost limb's pieces and the
## stump's follow their own parts only. The rest of him goes on skinned across his joints (all of
## him going rigid opened every seam as he lay: a flap of shoulder by his head, a gap at the neck;
## experiments/body_lab, the check's stumps). With no segment, every piece.
func _stop_skinning_across_joints(segment := &"") -> void:
	_unmerge()
	var which: Array[StringName] = []
	if segment != &"":
		which = anatomy.segments_below(segment)
		which.append(anatomy.segments[segment].parent)
	for sid: StringName in segment_pieces:
		if segment != &"" and not which.has(sid):
			continue
		for mi: MeshInstance3D in segment_pieces[sid]:
			if is_instance_valid(mi) and _rigid_meshes.has(mi):
				mi.mesh = _rigid_meshes[mi]


## A generated garment's own baked pixel texture (UVs 0..1 over it, not metres).
func _baked_cloth(what: String, tex: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = "%s:%s:baked" % [body_model, what]
	m.albedo_texture = tex
	m.texture_filter = PixelArt.texture_filter()
	m.roughness = 0.95
	m.uv1_scale = Vector3.ONE
	return m


func _cloth(what: String, colour: Color, style: StringName, cull_back := true) -> StandardMaterial3D:
	var key := "%s:%s" % [person_id, what]
	return PeopleArt.material(key, PeopleArt.cloth(key, colour, rng_seed * 7 + what.length(), style), 0.95, cull_back)


## Bones follow the parts (hitboxes while standing, ragdoll pieces when limp). `placed`: the
## parts' global transforms already read this tick (segment -> Transform3D; _track_carry's).
func _update_skeleton(placed := {}) -> void:
	if skeleton == null:
		return
	var inv := skeleton.global_transform.affine_inverse()
	for i in _bone_parts.size():
		var sid := _bone_parts[i]
		if placed.has(sid):
			skeleton.set_bone_pose(i, inv * (placed[sid] as Transform3D))
			continue
		var part: Node3D = parts.get(sid)
		if part != null and is_instance_valid(part) and part.is_inside_tree():
			skeleton.set_bone_pose(i, inv * part.global_transform)
	PeopleBodies.pose_shoulders(skeleton, _shoulders)
	_pose_fingers()


## A skinned hand's finger bones (the characters session's skinned hands,
## docs/briefs/skinned-hands.md): after the anatomy's, each resting at his model's own finger
## joint (its report's finger_bones); the finger nodes still curl, grip and come off, and each
## bone takes its node's bend about its own joint (_pose_fingers). Each hangs from the bone before
## it in the skeleton (the knuckle from the hand), so it's set only when its finger bends. None
## for other models.
var _finger_rig: Array[FingerBone] = []
## A Studio man's shoulder helpers (PeopleBodies.shoulder_share), posed after his bones.
var _shoulders: Array[PeopleBodies.ShoulderBone] = []


## One skinned finger bone: what it follows and the numbers its bend takes, worked out once (a
## string test and a Dictionary walk a bone a frame were ~1 ms of the people's frame; more-cores
## step 2); set only when the finger node's angle changes.
class FingerBone:
	var bone: int
	var parent: int
	var local: Transform3D  ## its rest on its parent bone's
	var fid: StringName
	var k: int
	var thumb: bool
	var sx: float  ## the side's sign
	var rest: float  ## the relaxed bend (radians)
	var gain: float  ## the fist's gain on the node's angle
	var z := NAN  ## the finger node's angle it was last set for (INF: shot off)


func _add_finger_bones(data: Dictionary, skin: Skin, rests: Array[Transform3D]) -> void:
	var fb: Dictionary = data.get("finger_bones", {})
	if fb.is_empty():
		return
	var last := {}
	var rest_of := {}  ## bone -> its rest in the skeleton's space
	for name: String in data.get("finger_bone_names", []):
		if not fb.has(name):
			return
		var r: Dictionary = fb[name]
		var o: Array = r.origin
		var b: Array = r.basis
		var rest := Transform3D(Basis(Vector3(b[0][0], b[0][1], b[0][2]), Vector3(b[1][0], b[1][1], b[1][2]),
				Vector3(b[2][0], b[2][1], b[2][2])), Vector3(o[0], o[1], o[2]))
		var i := skeleton.get_bone_count()
		skeleton.add_bone(name)
		skin.add_bind(i, rest.affine_inverse())
		var bits := name.split("_")   # finger, <finger>, <side>, <bone>
		var fid := StringName("%s_%s" % [bits[1], bits[2]])
		var k := int(bits[3])
		var parent := _bone_parts.find(StringName("hand_" + bits[2])) if k == 0 else int(last[fid])
		var parent_rest: Transform3D = rests[parent] if k == 0 else rest_of[parent]
		rest_of[i] = rest
		var e := FingerBone.new()
		e.bone = i
		e.parent = parent
		e.local = parent_rest.affine_inverse() * rest
		skeleton.set_bone_parent(i, parent)
		skeleton.set_bone_rest(i, e.local)
		e.fid = fid
		e.k = k
		e.thumb = bits[1] == "thumb"
		e.sx = -1.0 if bits[2] == "r" else 1.0
		e.rest = deg_to_rad((RELAXED_THUMB if e.thumb else RELAXED_BEND)[k])
		e.gain = (FIST_GAIN_THUMB if e.thumb else FIST_GAIN)[k]
		_finger_rig.append(e)
		last[fid] = i


## A skinned hand at rest is a little curled, as a hand hangs (the drawn fingers hung dead straight;
## his paintings' hands curl): each joint bent at least this much (degrees, knuckle out); the
## game's own curl takes over past it.
const RELAXED_BEND := [28.0, 38.0, 24.0]
const RELAXED_THUMB := [10.0, 20.0, 14.0]
## A skinned hand's joints bend this many times the finger node's angle (curl_hand's full curl,
## 55/80/60 degrees, is a loose claw on a whole hand; a fist is ~90/100/65).
const FIST_GAIN := [1.6, 1.25, 1.1]
const FIST_GAIN_THUMB := [1.7, 1.5, 1.2]
## A skinned thumb folds across the fist, not only towards the palm: its bend leans this far
## (degrees) from the fingers' axis onto the bone's X, that way (THUMB_ACROSS_SIGN).
const THUMB_ACROSS := 45.0
const THUMB_ACROSS_SIGN := -1.0


func _pose_fingers() -> void:
	for e: FingerBone in _finger_rig:
		var gone := not fingers.has(e.fid)
		var z: float = INF if gone else (finger_bones[e.fid][e.k] as Node3D).rotation.z
		if z == e.z:
			continue
		e.z = z
		var pose: Transform3D = e.local
		if gone:
			pose = pose.scaled_local(Vector3.ONE * 0.001)   # shot off: shrunk to nothing at the knuckle
		else:
			pose = pose * Transform3D(_finger_bend(e, z), Vector3.ZERO)
		skeleton.set_bone_pose(e.bone, pose)


## A finger bone's bend for its node's angle `z`: the fist's gain, at least the relaxed curl, a
## thumb's leaning across the fist.
static func _finger_bend(e: FingerBone, z: float) -> Basis:
	var angle := z * e.gain
	if absf(angle) < e.rest:
		angle = e.sx * e.rest
	if e.thumb:
		var lean := deg_to_rad(THUMB_ACROSS)
		return Basis(Vector3(0, 0, 1), angle * cos(lean)) * Basis(Vector3(1, 0, 0), THUMB_ACROSS_SIGN * absf(angle) * sin(lean))
	return Basis(Vector3(0, 0, 1), angle)


## Only while he's limp (go_limp turns it on): the ragdoll moves in the physics step, after the
## ticks, so his bones follow it here. Standing, they follow the pose on his tick (people_tick).
func _process(delta: float) -> void:
	var t := Prof.start()
	_process_step(delta)
	Prof.stop(&"people_skeleton", t)


func _process_step(_delta: float) -> void:
	if limp:
		_update_skeleton()


## The hand: palm, then each finger as three bones from its knuckle, following the anatomy.
func _build_hand(sid: StringName, vis: Node3D, center: Vector3) -> void:
	var side := String(sid).right(1)
	var skin := PeopleArt.material("skin:%s" % person_id, PeopleArt.skin(person_id, skin_tone, 81 + rng_seed), 0.7)
	for f: String in FINGERS:
		var fid := StringName("%s_%s" % [f, side])
		var st := anatomy.structure(fid)
		if st.is_empty():
			continue
		var knuckle := Node3D.new()
		knuckle.name = f.capitalize()
		knuckle.position = st.a - center
		knuckle.basis = _along(st.a - st.b)  # +Y back up the finger, so bones hang along -Y
		vis.add_child(knuckle)
		var length: float = (st.b - st.a).length()
		var bones: Array[Node3D] = []
		var parent: Node3D = knuckle
		var lengths := [0.42, 0.33, 0.25]
		for i in 3:
			var bone := Node3D.new()
			bone.name = "Bone%d" % i
			if i > 0:
				bone.position = Vector3(0, -length * lengths[i - 1], 0)
			parent.add_child(bone)
			var l: float = length * lengths[i]
			var w := 0.017 if f != "thumb" else 0.019
			var mi := MeshInstance3D.new()
			var bm := CylinderMesh.new()
			bm.height = l + w * 0.4  # overlap into the next bone so bent knuckles stay closed
			bm.top_radius = w * 0.5 * (1.0 - 0.1 * i)
			bm.bottom_radius = w * 0.5 * (0.9 - 0.1 * i) * (0.85 if i == 2 else 1.0)
			bm.radial_segments = 6
			bm.rings = 1
			mi.mesh = bm
			mi.material_override = skin
			mi.layers = Layers.VIS_BODY
			# A finger's shadow is a pixel or two; thirty of them a man were the most of his
			# shadow draw calls, in every lamp's six faces and the sun's cascades.
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position = Vector3(0, -l * 0.5, 0)
			bone.add_child(mi)
			bones.append(bone)
			parent = bone
		fingers[fid] = knuckle
		finger_bones[fid] = bones


## His own fingers in place of the drawn ones, if his model has them (PeopleBodies: the
## characters session's fit_tripo own_fingers): each bone's piece of his hand, made in the rest
## pose, hung on that bone in his skin's material. They curl, take wounds and come off as the drawn
## ones did (the same bones and nodes).
func _own_fingers(data: Dictionary) -> void:
	var own: Dictionary = data.get("fingers", {})
	if own.is_empty():
		return
	var mat: ShaderMaterial = null
	for key: String in skin_meshes:
		if key.begins_with("skin/"):
			mat = ((skin_meshes[key] as MeshInstance3D).material_override as ShaderMaterial).duplicate() as ShaderMaterial
			break
	if mat == null:
		return
	mat.set_shader_parameter(&"use_custom_pos", false)
	for fid: StringName in finger_bones:
		var meshes: Array = own.get(String(fid), [])
		if meshes.size() != 3 or meshes.has(null):
			continue
		var center := anatomy.segment_center(StringName("hand_" + String(fid).right(1)))
		var rest: Transform3D = (fingers[fid] as Node3D).transform
		var bones: Array = finger_bones[fid]
		for i in 3:
			var bone := bones[i] as Node3D
			rest = rest * Transform3D(Basis.IDENTITY, bone.position)  # the bone at rest, uncurled
			var mi := bone.get_child(0) as MeshInstance3D
			mi.mesh = meshes[i]
			mi.transform = rest.affine_inverse() * Transform3D(Basis.IDENTITY, -center)
			mi.material_override = mat


## Curl a hand's fingers (0 open, 1 fist) about the palm side.
func curl_hand(side: String, amount: float) -> void:
	var sx := -1.0 if side == "r" else 1.0
	for f: String in FINGERS:
		var fid := StringName("%s_%s" % [f, side])
		if not finger_bones.has(fid):
			continue
		var bones: Array = finger_bones[fid]
		var k := 0.6 if f == "thumb" else 1.0
		for i in bones.size():
			(bones[i] as Node3D).rotation_degrees.z = sx * amount * k * [55.0, 80.0, 60.0][i]


func _give_gun() -> void:
	var gun := RevolverModel.new()
	gun.name = "Revolver"
	var vis: Node3D = visuals[&"hand_r"]
	vis.add_child(gun)
	gun.position = Vector3(0.232, 0.765, -0.05) - anatomy.segment_center(&"hand_r")
	gun.rotation_degrees = Vector3(-90, 0, 0)
	held_gun = gun
	curl_hand("r", 0.85)
	if start_holstered:
		holster_gun(true)


## Put the gun in its holster on his right hip (or, `now`, without the half second it takes).
func holster_gun(now := false) -> void:
	if held_gun == null or gun_holstered:
		return
	gun_holstered = true
	_draw_left = 0.0 if now else DRAW_TIME
	var vis: Node3D = visuals[&"pelvis"]
	held_gun.reparent(vis, false)
	held_gun.position = Vector3(0.2, 0.9, 0.02) - anatomy.segment_center(&"pelvis")
	held_gun.rotation_degrees = Vector3(-96, 0, 0)
	_gun_shadow(false)
	curl_hand("r", 0.25)


## A holstered revolver (45 parts) casts no shadow of its own: it's inside his.
func _gun_shadow(on: bool) -> void:
	if held_gun == null:
		return
	var mode := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for g in held_gun.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = mode


## Draw it: in his hand, ready to fire in half a second.
func draw_gun() -> void:
	if held_gun == null or not gun_holstered or not physiology.can_hold("r"):
		return
	gun_holstered = false
	_draw_left = DRAW_TIME
	var vis: Node3D = visuals[&"hand_r"]
	held_gun.reparent(vis, false)
	held_gun.position = Vector3(0.232, 0.765, -0.05) - anatomy.segment_center(&"hand_r")
	held_gun.rotation_degrees = Vector3(-90, 0, 0)
	_gun_shadow(true)
	curl_hand("r", 0.85)


## Gun out and up, able to shoot.
func gun_ready() -> bool:
	return held_gun != null and not gun_holstered and _draw_left <= 0.0


func _box(parent: Node3D, n: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := GunParts.box(parent, n, size, pos, GunParts.cloth("%s:%s" % [person_id, n.to_lower()], color))
	mi.layers = Layers.VIS_BODY
	return mi


func _cylinder(parent: Node3D, n: String, radius: float, h: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := GunParts.tube(parent, n, radius, h, pos, GunParts.cloth("%s:%s" % [person_id, n.to_lower()], color), 10, Vector3.ZERO)
	mi.layers = Layers.VIS_BODY
	return mi


# --- Living ------------------------------------------------------------------------------------

## His tick and then his nodes', from PeopleTick, in the order the tree had them: each only while
## its physics processing is on and it can process (paused, disabled), as the engine asked.
func people_tick(delta: float) -> void:
	if not _tickers_sorted:
		_tickers.sort_custom(func(a: Node, b: Node) -> bool: return b.is_greater_than(a))
		_tickers_sorted = true
	if is_physics_processing() and can_process():
		_tick(delta)
	for n: Node in _tickers.duplicate():
		if is_instance_valid(n) and n.is_inside_tree() and n.is_physics_processing() and n.can_process():
			n.call(&"tick", delta)


func _tick(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"people_body", t)
	if not limp:
		# His bones after his pose, from the parts' places _track_carry has just read.
		t = Prof.start()
		_update_skeleton(_carry_new if delta > 0.0 else {})
		Prof.stop(&"people_skeleton", t)


func _physics_step(delta: float) -> void:
	# The first half done ahead this tick (PeopleTick: `prepare`), taken once.
	var ahead := _prepared
	var pose_ahead := ahead and _prep_pose
	_prepared = false
	_prep_pose = false
	var scale_now := _prep_scale if ahead else _time_scale_now()
	if not ahead:
		physiology.step(delta * scale_now)
	_update_stains(delta * scale_now)
	signs_now().step(delta * scale_now)
	_after_step(delta, delta * scale_now)
	var chest_now := (parts[&"chest"] as Node3D).global_position if parts.has(&"chest") else global_position
	_velocity_now = (chest_now - _chest_was) / maxf(delta, 1e-4) if _chest_was != Vector3.INF else Vector3.ZERO
	_chest_was = chest_now
	if stumbling > 0.0 and not limp:
		_stumble_on(delta)
	if not limp:
		if not pose_ahead:
			_favour_step(delta)
		_apply_pose(delta, false, pose_ahead)
		if stumbling > 0.0:
			pass  # he's going down already
		elif not physiology.can_stand() and not prone and not rising:
			if _can_crawl():
				go_prone()
			else:
				go_limp()
		elif prone and not _can_crawl():
			go_limp()
	if not _moved_this_tick:
		_walk_spare = 0.0
		move_speed = move_toward(move_speed, 0.0, delta * 6.0)
		if move_speed < 0.05:
			gait = &""
		if _walk_clip_on and move_speed < 0.3:
			_walk_clip_on = false  # he's stopping: off the walk, back to his pose
			if _clip != null and _clip.name == walk_clip:
				stop_clip()
	_moved_this_tick = false
	if not limp:
		_track_carry(delta)
	_draw_left = maxf(_draw_left - delta, 0.0)
	if held_gun != null and not gun_holstered and not physiology.can_hold("r"):
		drop_gun()
	if limp:
		if hat_body != null:
			_hat_meets_ground()
		_step_brace(delta)
		_rise_watch(delta)
		_step_tone(delta)
		_step_dying(delta)
		if _impacts:
			_impacts.step(delta)
		if not _apart.is_empty():
			_rejoin_apart()
	if limp or prone:
		_update_pool()  # down, limp or not, he bleeds into a pool under him
	_cough(delta)
	var conscious := physiology.is_conscious()
	if _was_alive and not physiology.alive:
		_was_alive = false
		died.emit(physiology.cause_of_death)
		Events.person_died.emit(self, physiology.cause_of_death)
	_was_conscious = conscious


func _time_scale_now() -> float:
	if _day_cycle == null and is_inside_tree():
		_day_cycle = get_tree().get_first_node_in_group(&"day_cycle")
	return _day_cycle.time_scale if _day_cycle != null else time_scale


# --- His tick in two halves (PeopleTick: more-cores step 4) -------------------------------------

## The tick's first half done ahead (`prepare`): his physiology stepped, and with `_prep_pose` his
## favouring and his pose's maths too; the rest of his tick (`_physics_step`) applies them.
var _prepared := false
var _prep_pose := false
var _prep_scale := 1.0
## How long his `prepare` took (us; PeopleTick sums them against the phase's wall time).
var prep_us := 0


## On the main thread before `prepare` (PeopleTick's first phase): what the half needs from the
## scene (the day's time scale), and whether his pose can be worked out ahead: standing on no clip
## or capture, not stumbling or getting up (those move him or ask the physics as the pose goes).
## False: nothing to do ahead (he's done all in his tick, as before).
func begin_prepare() -> bool:
	if _prepared:
		return false  # the last one never got its tick (switched off since): it's still to apply
	_prep_scale = _time_scale_now()
	_prep_pose = not limp and not rising and stumbling <= 0.0 and _clip == null and _clip_w <= 0.0 \
			and not mocap_gait and _mocap_w <= 0.0
	return true


## The tick's pure half, his own data only (safe on a worker: no node, no physics, no signal, no
## Prof, no shared state written): his physiology, then, standing, his favouring and his pose's
## maths. In the order his tick did them, ahead of the stains and signs, which read neither.
func prepare(delta: float, timed := false) -> void:
	var t0 := Time.get_ticks_usec() if timed else 0
	physiology.step(delta * _prep_scale)
	if _prep_pose:
		_favour_step(delta)
		_pose_maths(delta, false)
	_prepared = true
	if timed:
		prep_us = Time.get_ticks_usec() - t0


## Where each part is at the end of this tick, for its velocity should he go limp (the standing
## parts are moved by script, so the engine knows no velocity for them). Kept as transforms and
## turned into velocities only when he falls: 17 parts' sums a man a tick were most of this.
func _track_carry(delta: float) -> void:
	if delta <= 0.0:
		return
	for sid: StringName in _carry_new:
		_carry_last[sid] = _carry_new[sid]
	var now := {}
	for sid: StringName in parts:
		var n := parts[sid] as Node3D
		if n == null or not is_instance_valid(n):
			continue
		now[sid] = n.global_transform
	_carry_new = now
	_carry_dt = delta


## Each part's velocity the last tick he stood ([segment -> m/s, segment -> rad/s]), from where it
## was the tick before: both empty if any part moved faster than a man can (a teleport).
func _carry_velocities() -> Array[Dictionary]:
	var v := {}
	var w := {}
	for sid: StringName in _carry_new:
		if not _carry_last.has(sid):
			continue
		var now: Transform3D = _carry_new[sid]
		var was: Transform3D = _carry_last[sid]
		var lv: Vector3 = (now.origin - was.origin) / _carry_dt
		if lv.length() > CARRY_MAX_SPEED:
			return [{}, {}]
		var q := now.basis.orthonormalized().get_rotation_quaternion()
		var dq := q * was.basis.orthonormalized().get_rotation_quaternion().inverse()
		if dq.w < 0.0:
			dq = -dq
		var angle := dq.get_angle()
		v[sid] = lv
		w[sid] = (dq.get_axis() * angle / _carry_dt).limit_length(CARRY_MAX_SPIN) if angle > 1e-6 else Vector3.ZERO
	return [v, w]


func set_pose(p: StringName) -> void:
	if not POSES.has(p):
		return
	if rising:
		_pose_after = p
		return
	if prone and not p in PRONE_POSES:
		p = &"prone_aim" if p == &"aim" or p == &"crouch_aim" else &"prone"
	pose = p


## Legs gone but still with it: down on his belly, able to crawl and shoot.
func _can_crawl() -> bool:
	var p := physiology
	return p.is_conscious() and p.shock() < 0.8 and (p.can_hold("r") or p.can_hold("l")) and not p.arms_paralysed()


func go_prone() -> void:
	if prone or limp:
		return
	prone = true
	set_pose(&"prone")
	fell.emit(true)
	Events.person_fell.emit(self, true)


# --- Getting up -------------------------------------------------------------------------------

## Knocked off his feet and not hurt past it (a shove, his chair gone: `brace`), he lies a moment and
## gets up again (Sean, 2026-10-22). The ragdoll becomes the standing rig where it lies (each joint
## taking the angle it lies at, so nothing jumps), and he rises through the stages a man does: on his
## back he sits up; face down he pushes up onto his hands and knees; then he gets his feet under him
## and stands. Each stage blends his pose (as any pose change) and the rig's lie; his lowest point is
## kept on the ground. Not after a wound: a man shot stays down (his brain and the falls decide).
signal got_up
## He lies this long at least (s) ...
const RISE_AFTER := 1.6
## ... and still this long (every part slower than RISE_STILL_SPEED, m/s) before he starts.
const RISE_STILL := 0.6
const RISE_STILL_SPEED := 0.3
## The stages: pose, the rig's turn (degrees: +90 x on his back, -90 face down), seconds, and how
## far ahead of where his hips lay he is by the stage's end (m: he gets his feet under him, so he
## crouches over them, not where his hips were).
const RISE_BACK := [[&"lie_back", Vector3(90, 0, 0), 0.5, 0.0], [&"sit_ground", Vector3.ZERO, 1.1, 0.0],
		[&"sit_tuck", Vector3.ZERO, 0.8, 0.1], [&"kneel_up", Vector3.ZERO, 1.0, 0.45], [&"hands_knees", Vector3.ZERO, 0.7, 0.5],
		[&"stand", Vector3.ZERO, 0.9, 0.5]]
const RISE_FRONT := [[&"prone", Vector3(-90, 0, 0), 0.3, 0.0], [&"all_fours", Vector3(-90, 0, 0), 0.8, 0.0],
		[&"kneel", Vector3.ZERO, 1.0, -0.35], [&"kneel_up", Vector3.ZERO, 0.8, -0.35], [&"hands_knees", Vector3.ZERO, 0.7, -0.3],
		[&"stand", Vector3.ZERO, 0.9, -0.3]]
## Shot down and still with it, he comes to on his belly to fight from the floor (`come_to_ground`,
## OutlawBrain's `floor_fight`): face down he gathers himself where he lies; on his back he sits up
## and turns over onto his front.
const COME_TO_FRONT := [[&"prone", Vector3(-90, 0, 0), 0.6, 0.0]]
const COME_TO_BACK := [[&"lie_back", Vector3(90, 0, 0), 0.5, 0.0], [&"sit_ground", Vector3.ZERO, 1.1, 0.0],
		[&"prone", Vector3(-90, 0, 0), 0.9, 0.0]]
## He may get up (set by `brace`: an unhurt fall); cleared as he goes limp.
var rise_ok := false
var _rise_to_prone := false  ## the stages end on his belly (come_to_ground), not on his feet
## Getting up now: the rig is the stages', not _place_rig's.
var rising := false
var _down_t := 0.0
var _still_t := 0.0
var _rise_stages: Array = []
var _rise_i := 0
var _rise_t := 0.0
var _rise_from := Transform3D.IDENTITY  ## the rig (in him) as the stage began
var _rise_pose_from := {}  ## his pose as the stage began: each stage's pose moves with its lie
var _rise_k := 0.0  ## how far through the stage (0-1, eased)
var _pose_after := &"stand"  ## what he was told to do while rising


## Lying limp: is it time to get up?
func _rise_watch(delta: float) -> void:
	if not physiology.alive:
		return
	_down_t += delta
	var still := true
	for rb: Variant in parts.values():
		if rb is RigidBody3D and is_instance_valid(rb) and (rb as RigidBody3D).linear_velocity.length() > RISE_STILL_SPEED:
			still = false
			break
	_still_t = _still_t + delta if still else 0.0
	if rise_ok and _down_t >= RISE_AFTER and _still_t >= RISE_STILL and physiology.can_stand() and physiology.shock() < 0.3 \
			and physiology.severed_segments.is_empty():
		get_up()


## Get up off the ground now (limp, alive, his legs his own).
func get_up() -> void:
	if not limp or rising or not physiology.can_stand() or not physiology.severed_segments.is_empty():
		return
	_rise(RISE_BACK, RISE_FRONT, false)


## Lying limp, shot, he's come to: he can (conscious, a hand to crawl and shoot with) and he's lain
## still long enough (RISE_AFTER, RISE_STILL). He comes to on his belly, down where he is (prone),
## where his brain fights from (OutlawBrain's `floor_fight`). False if he can't yet.
func come_to_ground() -> bool:
	if not limp or rising or not physiology.alive or not _can_crawl() or not physiology.severed_segments.is_empty() \
			or _down_t < RISE_AFTER or _still_t < RISE_STILL:
		return false
	_rise(COME_TO_BACK, COME_TO_FRONT, true)
	return true


func _rise(back: Array, front: Array, to_prone: bool) -> void:
	var pelvis := parts.get(&"pelvis") as RigidBody3D
	var chest := parts.get(&"chest") as RigidBody3D
	if pelvis == null or chest == null:
		return
	var on_back := (-chest.global_basis.z).y > 0.0
	# On his back he'll sit up facing his feet; face down he comes up facing where his head is.
	var to := (((parts[&"foot_l"] as Node3D).global_position + (parts[&"foot_r"] as Node3D).global_position) * 0.5
			if on_back else (parts[&"head"] as Node3D).global_position) - pelvis.global_position
	to.y = 0.0
	if to.length() < 0.05:
		to = Vector3(0, 0, -1)
	# Each joint's angle as he lies (the poses' degrees: a ragdoll joint's rest is its pose).
	var rel := {}
	for sid: StringName in anatomy.segments:
		var parent: StringName = anatomy.segments[sid].parent
		if parent == &"" or not parts.has(parent):
			continue
		var pb := (parts[parent] as Node3D).global_basis.orthonormalized()
		rel[sid] = (pb.inverse() * (parts[sid] as Node3D).global_basis.orthonormalized()).get_euler() * (180.0 / PI)
	var lie := pelvis.global_transform.orthonormalized()
	var ground := _ground_y(pelvis.global_position)
	global_transform = Transform3D(Basis.looking_at(to.normalized(), Vector3.UP), Vector3(lie.origin.x, ground, lie.origin.z))
	_rebuild_rig()
	_spare_rubble(lie.origin)
	_pose_now = rel
	_pose_now[&"pelvis"] = Vector3.ZERO
	# The rig set so his pelvis is where the ragdoll's lay (its part sits at the segment's centre).
	_rig.global_transform = lie * Transform3D(Basis(), -anatomy.segment_center(&"pelvis"))
	rising = true
	_rise_to_prone = to_prone
	_rise_stages = back if on_back else front
	_rise_i = -1
	_next_stage()


func _next_stage() -> void:
	_rise_i += 1
	_rise_t = 0.0
	_rise_k = 0.0
	_rise_from = _rig.transform
	_rise_pose_from = _pose_now.duplicate()
	if _rise_i >= _rise_stages.size():
		rising = false
		# Where he's got to is where he stands: the rig's offset handed to him.
		var off := Vector3(_rig.position.x, 0.0, _rig.position.z)
		global_position += global_basis * off
		if _rise_to_prone:
			# On his belly: the rig stays laid face down (as _place_rig keeps it for prone).
			_rig.transform = Transform3D(Basis.from_euler(Vector3(-PI / 2.0, 0.0, 0.0)), Vector3(0.0, _rig.position.y, 0.0))
			prone = true
			pose = &"prone"
			return
		_rig.transform = Transform3D(Basis(), Vector3(0.0, _rig.position.y, 0.0))
		pose = _pose_after
		got_up.emit()
		return
	pose = _rise_stages[_rise_i][0]


## While rising, after the pose is applied: the rig turns and slides toward the stage's lie, and his
## lowest point is put on the ground.
func _rise_step(delta: float) -> void:
	var st: Array = _rise_stages[_rise_i]
	var k := _rise_k
	var goal := Basis.from_euler((st[1] as Vector3) * (PI / 180.0))
	var b := Basis(_rise_from.basis.get_rotation_quaternion().slerp(goal.get_rotation_quaternion(), k))
	var o := _rise_from.origin
	# Ahead is his -z.
	_rig.transform = Transform3D(b, Vector3(lerpf(o.x, 0.0, k), _rig.position.y, lerpf(o.z, -float(st[3]), k)))
	_rig.position.y += global_position.y - _lowest_point()
	_set_blocker(st[1] != Vector3.ZERO)
	if _rise_t >= float(st[2]):
		_next_stage()


## Loose pieces lying about him (a chair's he went over with, timber) stop colliding with his rising
## body: his animated parts are put where the ragdoll lay, among or in them, and the engine flung
## them out at him (5 kJ: Structure._on_rubble_hit broke his shin as he got up).
const SPARE_RADIUS := 2.5


func _spare_rubble(at: Vector3) -> void:
	var q := PhysicsShapeQueryParameters3D.new()
	var ball := SphereShape3D.new()
	ball.radius = SPARE_RADIUS
	q.shape = ball
	q.transform = Transform3D(Basis(), at)
	q.collision_mask = Layers.WORLD
	Prof.count(&"q_body")
	for hit: Dictionary in World.space(self).intersect_shape(q, 64):
		var rb := hit.collider as RigidBody3D
		if rb == null:
			continue
		for part: Variant in parts.values():
			rb.add_collision_exception_with(part as Node)
		rb.add_collision_exception_with(_blocker)


## The lowest point of him (world y): each capsule's lower end.
func _lowest_point() -> float:
	var low := INF
	for sid: StringName in parts:
		for c in (parts[sid] as Node).get_children():
			var cs := c as CollisionShape3D
			if cs == null or not (cs.shape is CapsuleShape3D):
				continue
			var cap := cs.shape as CapsuleShape3D
			var half := maxf(cap.height * 0.5 - cap.radius, 0.0)
			var xf := cs.global_transform
			var axis := xf.basis.y.normalized() * half
			low = minf(low, minf((xf.origin + axis).y, (xf.origin - axis).y) - cap.radius)
	return low if low < INF else global_position.y


## The ground under a point (world y): what he stands on.
func _ground_y(at: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * 3.0, Layers.STAND)
	q.exclude = _own_rids()
	Prof.count(&"q_body")
	var hit := World.space(self).intersect_ray(q)
	return (hit.position as Vector3).y if not hit.is_empty() else at.y - 0.15


## The limp body made the standing rig again where it lies (go_limp, backwards): pivots and animated
## parts, each ragdoll body's shapes, meshes and decals moved back onto its part, the joints and
## bodies freed.
func _rebuild_rig() -> void:
	var old := parts.duplicate()
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	pivots.clear()
	for sid: StringName in anatomy.segment_order():
		var parent: StringName = anatomy.segments[sid].parent
		var pivot := Node3D.new()
		pivot.name = String(sid)
		var rest := _pivot_rest(sid)
		if parent == &"":
			_rig.add_child(pivot)
			pivot.position = rest
		else:
			(pivots[parent] as Node3D).add_child(pivot)
			pivot.position = rest - _pivot_rest(parent)
		pivots[sid] = pivot
		var rb := old[sid] as Node3D
		var part := _new_part(sid, pivot, rest, float(rb.get_meta(&"mass", 5.0)))
		for c in rb.get_children():
			c.reparent(part, false)
		parts[sid] = part
	for c in get_children():
		if c is Joint3D:
			c.queue_free()
	for sid: StringName in old:
		(old[sid] as Node).queue_free()
	_impacts = null
	_tone.clear()
	_tone_when.clear()
	_end_dying()
	_apart.clear()
	cone_frames.clear()
	_brace_t = -1.0
	_new_blocker()
	limp = false
	rise_ok = false
	set_process(false)


## Walk (or run, or crawl) towards a point on the ground, this tick. Stops short of walls and
## people; slides along them; climbs a step up to a boardwalk. Returns true on arrival.
func walk_to(target: Vector3, speed: float, delta: float, facing := true) -> bool:
	if limp or rising or (stumbling > 0.0 and not _stumble.get("steering", false)):
		return false
	var to := target - global_position
	to.y = 0.0
	var dist := to.length()
	if dist < 0.1:
		return true
	var p := physiology
	var how := &"run" if speed > 2.4 else &"walk"
	# Hurt legs slow him and make him limp; a leg or a body he's favouring slows him as it comes on.
	var legs := minf(p.muscle_strength("leg", "r"), p.muscle_strength("leg", "l"))
	speed *= lerpf(0.4, 1.0, legs) * (1.0 - p.shock() * 0.5) * favour_pace()
	if (legs < 0.75 or maxf(favouring(&"leg_r"), favouring(&"leg_l")) > FAVOUR_LIMP) and not prone:
		how = &"limp"
		speed = minf(speed, 1.3)
	if prone:
		how = &"crawl"
		speed = minf(speed, 0.35)
	var dir := to / dist
	delta += _walk_spare
	_walk_spare = 0.0
	var step := minf(speed * delta, dist)
	var tick := 1.0 / Engine.physics_ticks_per_second
	if delta > tick * 1.5 and speed > 0.0:
		# A slowed tick (PeopleTick's bands: four in one): he walks the ticks' steps he'd have
		# walked one at a time, and if he'd have been there (within 0.1 m) before they're out, he
		# stops where that step put him and the ticks left over are the next point's.
		var per := speed * tick
		var ticks := roundi(delta / tick)
		var need := floori((dist - 0.1) / per) + 1
		if need < ticks:
			step = minf(need * per, dist)
			_walk_spare = (ticks - need) * tick
	var moved := _slide(dir * step)
	if facing and moved.length() > 0.001:
		var look := global_position + (moved if not prone else dir)
		var fwd := look - global_position
		global_rotation.y = atan2(-fwd.x, -fwd.z)
	_snap_to_ground()
	gait = how
	move_speed = moved.length() / maxf(delta, 1e-4)
	_moved_this_tick = true
	_walk_clip_step(how, move_speed)
	var left := target - global_position
	left.y = 0.0
	return left.length() < 0.1 or (dist < 0.4 and moved.length() < 0.001)


## His own walk clip while he walks (not limping, crawling or on another clip): started as he
## sets off, its rate his speed over the clip's, let go as he stops (the gait's sines take a
## limp; a run too, until there's a run clip).
func _walk_clip_step(how: StringName, speed_now: float) -> void:
	if walk_clip == &"" or how != &"walk":
		if _walk_clip_on and _clip != null and _clip.name == walk_clip:
			stop_clip()
		_walk_clip_on = false
		return
	if _clip != null and _clip.name != walk_clip:
		return  # busy with another clip (a kick, a draw): it has him
	var c := MotionClip.load_clip(walk_clip)
	if c == null or c.length() <= 0.0:
		return
	var travel := c.root_at(c.length()) - c.root_at(0.0)
	travel.y = 0.0
	var clip_speed := travel.length() / c.length()
	var rate := clampf(speed_now / maxf(clip_speed, 0.3), 0.6, 1.6)
	if _clip == null:
		play_clip(walk_clip, rate, true, {"travel": false})
		_walk_clip_on = true
	else:
		_clip_speed = rate


## Pulled along by the collar towards `holder` (the hands of whoever's dragging him), this tick.
## Lying posed (prone): his head follows the hands and the rest of him trails behind, sliding over
## the ground and along anything in the way. A rag doll: hauled by the chest, the rest following
## on its joints.
func drag_toward(holder: Vector3, delta: float) -> void:
	if limp:
		var chest := parts.get(&"chest") as RigidBody3D
		if chest == null:
			return
		var to := holder + Vector3.UP * 0.3 - chest.global_position
		var d := to.length()
		if d > 0.4:
			var want := to / d * clampf((d - 0.4) * 5.0, 0.0, 2.5)
			want.y = chest.linear_velocity.y if to.y < 0.0 else minf(want.y, 0.8)
			chest.linear_velocity = chest.linear_velocity.lerp(want, clampf(delta * 12.0, 0.0, 1.0))
			chest.sleeping = false
			# Hauled by the collar his whole trunk comes along and his legs trail: towing the chest
			# alone, his legs and hips (half of him, weighed as a man's) held it where it was.
			var flat := Vector3(want.x, 0.0, want.z)
			for sid: StringName in [&"abdomen", &"pelvis"]:
				var rb := parts.get(sid) as RigidBody3D
				if rb:
					var v := rb.linear_velocity
					rb.linear_velocity = v.lerp(Vector3(flat.x, v.y, flat.z), clampf(delta * 12.0, 0.0, 1.0))
					rb.sleeping = false
		return
	# Prone: he lies from his feet (here) forward to his head, ~1.75 m.
	var to := holder - global_position
	to.y = 0.0
	var d := to.length()
	if d < 0.01:
		return
	var dir := to / d
	global_rotation.y = atan2(-dir.x, -dir.z)
	var length := anatomy.height + 0.1
	if d > length:
		_slide(dir * minf(d - length, 0.1))
		_snap_to_ground()


## Move by `motion` (flat), stopping at and sliding along whatever's in the way.
func _slide(motion: Vector3) -> Vector3:
	var space := World.space(self)
	var shape := SphereShape3D.new()
	shape.radius = 0.26
	var exclude: Array[RID] = []
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	var total := Vector3.ZERO
	var left := motion
	for attempt in 3:
		if left.length() < 0.0005:
			break
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, global_position + total + Vector3.UP * (0.35 if prone else 0.75))
		q.motion = left
		q.collision_mask = Layers.STAND | Layers.PEOPLE
		q.exclude = exclude
		Prof.count(&"q_walk")
		var frac := space.cast_motion(q)
		if frac[0] <= 0.0 and frac[1] <= 0.0:
			# Started a hair inside something (a corner he was slid into): no motion can be cast
			# from there at all, so he'd stand stuck for good. Step out along its normal first.
			q.motion = Vector3.ZERO
			Prof.count(&"q_walk")
			var inside := space.get_rest_info(q)
			if inside.is_empty():
				break
			var out: Vector3 = inside.normal
			out.y = 0.0
			if out.length() < 0.01:
				break
			total += out.normalized() * 0.03
			continue
		var safe := left * frac[0]
		total += safe
		if frac[0] >= 1.0:
			break
		# Blocked: slide along it.
		q.transform = Transform3D(Basis.IDENTITY, global_position + total + Vector3.UP * (0.35 if prone else 0.75) + left.normalized() * 0.02)
		q.motion = Vector3.ZERO
		Prof.count(&"q_walk")
		var rest := space.get_rest_info(q)
		if rest.is_empty():
			break
		var n: Vector3 = rest.normal
		n.y = 0.0
		if n.length() < 0.01:
			break
		n = n.normalized()
		left = (left - safe)
		left -= n * left.dot(n)
	if total.length() < 0.0005 and motion.length() > 0.0005:
		# Caught on a corner (a trough's, a rail's end) where sliding along one face runs into the
		# other: try heading off a little to either side, the way that gets furthest.
		var best := Vector3.ZERO
		for deg in [45.0, -45.0, 90.0, -90.0]:
			var turned := motion.rotated(Vector3.UP, deg_to_rad(deg)) * cos(deg_to_rad(deg) * 0.5)
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = shape
			q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * (0.35 if prone else 0.75))
			q.motion = turned
			q.collision_mask = Layers.STAND | Layers.PEOPLE
			q.exclude = exclude
			Prof.count(&"q_walk")
			var got: Vector3 = turned * space.cast_motion(q)[0]
			if got.length() > best.length():
				best = got
		total = best
	global_position += total
	return total


## Keep his feet on whatever's under him (a boardwalk step up, a slope). A foot is wider than the
## gap between a walk's planks or a floor's boards: a ray down the middle and one a few centimetres
## off it each way, the highest wins (one ray fell through a crack, and off a raised walk he couldn't
## step back up).
func _snap_to_ground() -> void:
	var space := World.space(self)
	var best := -INF
	var best_up := 1.0
	for off: Vector3 in [Vector3.ZERO, Vector3(-0.06, 0, 0), Vector3(0.06, 0, 0), Vector3(0, 0, -0.06), Vector3(0, 0, 0.06)]:
		var hit := _ground_ray(space, global_position + off, 1.0)
		if not hit.is_empty() and (hit.position as Vector3).y > best:
			best = (hit.position as Vector3).y
			best_up = (hit.normal as Vector3).y
	if best == -INF and _stood:
		# Nothing within a metre: standing on something a moment ago, he looks further down, for a
		# hole dug under him or an edge he's walked off (the dig-able ground,
		# docs/briefs/dig-ground.md). Not yet stood (just placed, up in the air to drop onto his
		# spot), he waits as he always has.
		var hit := _ground_ray(space, global_position, DROP_FALLS + 2.5)
		if not hit.is_empty():
			best = (hit.position as Vector3).y
			best_up = (hit.normal as Vector3).y
	if best == -INF:
		return
	# The ground's gone from under him further than a step down, or he's walked on down a slope too
	# steep to walk, deeper than a step below where he last stood level (into a dug hole, not a
	# stick's shallow crater): he goes in.
	if _stood and (global_position.y - best > DROP_FALLS or (best_up < STEEP_UP and best < _level_y - STEEP_DROP)):
		_stood = false
		# Not mid-tick (it takes his parts out of the pose), and not deferred either: that runs after the
		# physics frame, where with physics on its own thread his new parts' state can't be read. The
		# next physics tick, before anyone ticks.
		get_tree().physics_frame.connect(go_limp.bind(Vector3.ZERO), CONNECT_ONE_SHOT)
		return
	global_position.y = best
	if not _stood or best_up >= STEEP_UP:
		_level_y = best
	_stood = true


func _ground_ray(space: PhysicsDirectSpaceState3D, at: Vector3, reach: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.5, at + Vector3.DOWN * reach, Layers.STAND)
	if _blocker and is_instance_valid(_blocker):
		q.exclude = [_blocker.get_rid()]
	Prof.count(&"q_walk")
	return space.intersect_ray(q)


## The ground near him was dug or laid on (Ground): a man standing there finds it again, and goes
## in if it's gone from under him.
func _on_ground_changed(area: Rect2) -> void:
	if limp or not _stood or not is_inside_tree():
		return
	if area.grow(0.3).has_point(Vector2(global_position.x, global_position.z)):
		_snap_to_ground()


## Into the scene where he's to stand (`at`, world space), facing `yaw`: placed before he's
## added, because his limbs are kinematic bodies, and moved there after they'd sweep from the
## parent's origin in one step and fling what lay in the way (a stud in the street went off at
## 500 m/s when the gang rode in: the nightly soak, 2026-10-13).
func enter(parent: Node, at: Vector3, yaw := 0.0) -> void:
	var where := Transform3D(Basis(Vector3.UP, yaw), at)
	if parent is Node3D and parent.is_inside_tree():
		where = (parent as Node3D).global_transform.affine_inverse() * where
	transform = where
	parent.add_child(self)


## The yaw that faces from `from` towards `point` (as face() turns him).
static func yaw_toward(from: Vector3, point: Vector3) -> float:
	var to := point - from
	return atan2(-to.x, -to.z) if Vector2(to.x, to.z).length() > 0.01 else 0.0


## Turn to face a point and, in the aim pose, raise the gun arm to it.
func face(point: Vector3) -> void:
	if rising:
		return
	if limp:
		return
	var to := point - global_position
	to.y = 0.0
	if to.length() > 0.01:
		global_rotation.y = atan2(-to.x, -to.z)
	var shoulder := (pivots[&"upper_arm_r"] as Node3D).global_position
	var d := point - shoulder
	aim_pitch = rad_to_deg(atan2(d.y, Vector2(d.x, d.z).length()))


## `ahead`: its maths done already this tick (`prepare`).
func _apply_pose(delta: float, snap := false, ahead := false) -> void:
	if not ahead:
		_pose_maths(delta, snap)
	_pose_writes(delta, snap)


## His pose's maths for this tick, his own data only (no node, no physics, no signal while he's on
## no clip; PeopleTick runs it on a worker then, `prepare`): each joint's goal, the blends, the
## flinch springs, his breath, into `_rots` (degrees, in `pivots`' order). A clip's turns go to
## `_pose_clip` / `_pose_played` for the writes.
func _pose_maths(delta: float, snap: bool) -> void:
	_breath += delta * breath_rate()
	var target: Dictionary = POSES[pose]
	var blend := 1.0 if snap else clampf(delta * 6.0, 0.0, 1.0)
	if rising:
		_rise_t += delta
		_rise_k = smoothstep(0.0, 1.0, clampf(_rise_t / float(_rise_stages[_rise_i][2]), 0.0, 1.0))
	_pose_clip = _mocap_now(delta)
	_pose_played = _clip_now(delta)
	var overlay := _gait_overlay(delta) if _pose_clip.is_empty() and _mocap_w <= 0.0 and _clip_w <= 0.0 else {}
	_injury_targets()
	# (Asked of every joint every tick: only the lists with something in them.)
	var injured := not _injury_now.is_empty() or not _injury_w.is_empty()
	var leans := not overlay.is_empty() or not pose_offsets.is_empty() or not _stumble_lean.is_empty() or not _favour_lean.is_empty()
	_rots.resize(pivots.size())
	var i := 0
	for sid: StringName in pivots:
		var goal: Vector3 = target.get(sid, Vector3.ZERO)
		if leans:
			goal += overlay.get(sid, Vector3.ZERO) + pose_offsets.get(sid, Vector3.ZERO) \
					+ _stumble_lean.get(sid, Vector3.ZERO) + _favour_lean.get(sid, Vector3.ZERO)
		if injured:
			goal = _injured(sid, goal, delta)
		if sid == &"upper_arm_r" and (pose == &"aim" or pose == &"crouch_aim"):
			goal.x += aim_pitch
		var now: Vector3 = _pose_now.get(sid, goal)
		now = now.lerp(goal, blend) if not rising else (_rise_pose_from.get(sid, now) as Vector3).lerp(goal, _rise_k)
		_pose_now[sid] = now
		var f: Array = _flinch.get(sid, [Vector3.ZERO, Vector3.ZERO])
		if delta > 0.0:
			# A damped spring pulls the flinch back to the pose.
			f[1] += (-f[0] * 220.0 - f[1] * 18.0) * delta
			f[0] += f[1] * delta
			_flinch[sid] = f
		var rot: Vector3 = now + f[0]
		if sid == &"chest":
			var shock := physiology.shock()
			var gasp := 2.5 if shock > AGONAL_SHOCK else 1.0
			rot.x += sin(_breath * 1.6) * 1.2 * gasp * (1.0 + shock * 2.0 + (1.0 - physiology.breath_capacity()) * 1.5)
		_rots[i] = rot
		i += 1


## The pose's writes, on the main thread: each joint turned to its `_rots` (or its clip's turn),
## then the rig, the hands and the rest of the tick's pose work.
func _pose_writes(delta: float, snap: bool) -> void:
	var clip := _pose_clip
	var played := _pose_played
	# The clip has his legs and hips always; the rest of him only standing easy (aiming, his hands
	# up or bound, clutching a wound, the pose has his arms and back).
	var all_of_him := pose == &"stand"
	var writes := 0
	var i := 0
	for sid: StringName in pivots:
		var rot := _rots[i]
		i += 1
		var pv := pivots[sid] as Node3D
		var mocap_here := _mocap_w > 0.0 and clip.has(sid) and (all_of_him or _MOCAP_ALWAYS.has(String(sid).trim_suffix("_r").trim_suffix("_l")))
		var clip_here := _clip_w > 0.0 and played.has(sid)
		# Set only if it moved: each set is a transform change down the joint's subtree into its
		# parts' physics state, and a man standing easy moves little but his chest once his pose
		# has settled. Exactly as last set, and nothing else (a hand to a wound, a clip) has turned
		# the joint since: setting it again would change nothing. (Within a hundredth of a degree
		# was tried: 19 of the physics lab's 151 falls went another way.)
		var was: Array = _pose_set.get(sid, _NOT_SET)
		if mocap_here or clip_here or was[0] != rot or was[1] != pv.transform:
			pv.rotation_degrees = rot
			writes += 1
			_pose_set[sid] = [rot, pv.transform] if not (mocap_here or clip_here) else _NOT_SET
		if mocap_here or clip_here:
			# The clip's turn, with what's on top of any pose (a flinch, a staged touch, his fold
			# as he stumbles, the lean his wounds give him) on top of it. The played clip leads
			# every joint it has.
			var flinch: Vector3 = (_flinch.get(sid, _NO_FLINCH) as Array)[0]
			var extra: Vector3 = (flinch + pose_offsets.get(sid, Vector3.ZERO) + _stumble_lean.get(sid, Vector3.ZERO)
					+ _favour_lean.get(sid, Vector3.ZERO)) * (PI / 180.0)
			if mocap_here:
				pv.quaternion = pv.quaternion.slerp((clip[sid] as Quaternion) * Quaternion.from_euler(extra), _mocap_w)
				writes += 1
			if clip_here:
				pv.quaternion = pv.quaternion.slerp((played[sid] as Quaternion) * Quaternion.from_euler(extra), _clip_w)
				writes += 1
	Prof.count(&"q_writes", writes)
	_place_rig(delta, snap)
	if _clip_w > 0.0:
		_clip_strikes(delta)
	_reach_step()
	_grab_step(delta)
	_sling_step(delta)
	if gait == &"crawl" or _crawl_w > 0.0:
		_crawl_hands(delta)
	if held_gun != null and not gun_holstered:
		curl_hand("r", 0.85)


const _MOCAP_ALWAYS := ["pelvis", "thigh", "shin", "foot"]
## Each pivot as _apply_pose last set it: [its rotation (degrees), its transform after].
var _pose_set := {}
const _NOT_SET := [Vector3.INF, Transform3D()]
const _NO_FLINCH := [Vector3.ZERO, Vector3.ZERO]
## The tick's pose from _pose_maths, for _pose_writes: each joint's turn (degrees, `pivots`' order)
## and a clip's turns.
var _rots := PackedVector3Array()
var _pose_clip := {}
var _pose_played := {}


## This tick's frame of the walk or run clip (segment -> Quaternion, blended between the clip's
## samples by where he is in his stride), or {} when there's none (not walking or running, the
## experiment off). Its phase goes with the ground he covers, a stride per the clip's stride
## (scaled to his legs), so his planted foot stays planted whatever his speed.
func _mocap_now(delta: float) -> Dictionary:
	var c := {}
	if mocap_gait and (gait == &"walk" or gait == &"run") and move_speed >= 0.05:
		c = _mocap_clip(gait)
	if not c.is_empty():
		_mocap_last = c
		_mocap_w = move_toward(_mocap_w, 1.0, delta * 5.0)
		_gait_phase = fmod(_gait_phase + delta * move_speed / float(c.stride) * TAU, TAU)
	else:
		_mocap_w = move_toward(_mocap_w, 0.0, delta * 5.0)
		c = _mocap_last if _mocap_w > 0.0 else {}
	if c.is_empty():
		return {}
	var frames: Array = c.frames
	var at := _gait_phase / TAU * frames.size()
	var i0 := int(at) % frames.size()
	var i1 := (i0 + 1) % frames.size()
	var k := at - floorf(at)
	var out := {}
	for sid: StringName in frames[i0]:
		out[sid] = (frames[i0][sid] as Quaternion).slerp(frames[i1][sid], k)
	var hh: Array = c.hip_height
	_mocap_hips = lerpf(hh[i0], hh[i1], k) if hh.size() == frames.size() else -1.0
	return out


static func _mocap_clip(g: StringName) -> Dictionary:
	if not _mocap_clips.has(g):
		var clip := {}
		var path := "res://experiments/mocap_walk/clips/%s.json" % g
		if FileAccess.file_exists(path):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			var frames := []
			for fr: Dictionary in d.frames:
				var q := {}
				for key: String in fr:
					var a: Array = fr[key]
					q[StringName(key)] = Quaternion(a[0], a[1], a[2], a[3]).normalized()
				frames.append(q)
			clip = {"stride": float(d.stride_m), "frames": frames, "hip_height": d.get("hip_height", [])}
		_mocap_clips[g] = clip
	return _mocap_clips[g]


## Play a clip of motion (assets/animations/<name>.json, MotionClip) as the targets his pose
## follows: its turns lead every joint it has, its travel moves him through the same sliding and
## grounding as walking, and physics wins where they fight (a wall stops the travel, a chair leg
## his boot meets takes the blow, a ball that drops him ends the clip). Returns its length in
## seconds (0: no such clip). `clip_done` when it ends (not looping); `clip_event` at its marks.
func play_clip(clip_name: StringName, speed := 1.0, loop := false, opts := {}) -> float:
	var c := MotionClip.load_clip(clip_name)
	if c == null or limp:
		return 0.0
	_clip = c
	_clip_opts = opts
	_clip_t = 0.0
	_clip_speed = maxf(speed, 0.01)
	_clip_loop = loop
	_clip_hold = 0.0
	_clip_struck.clear()
	_clip_part_was.clear()
	_clip_hips = -1.0
	return c.length()


## Let the clip go (he eases back to his pose over a fifth of a second).
func stop_clip() -> void:
	_clip = null
	_clip_hold = 0.0


func clip_playing() -> bool:
	return _clip != null


func clip_name() -> StringName:
	return _clip.name if _clip != null else &""


## How far into the clip he is (s).
func clip_time() -> float:
	return _clip_t if _clip != null else 0.0


## This tick's frame of the played clip (segment -> Quaternion), its time advanced and its travel
## walked, or {} when there's none and he's eased off the last one.
func _clip_now(delta: float) -> Dictionary:
	if _clip == null:
		_clip_w = move_toward(_clip_w, 0.0, delta * 5.0)
		return _clip_last if _clip_w > 0.0 else {}
	var c := _clip
	var t0 := _clip_t
	if _clip_hold > 0.0:
		_clip_hold -= delta
	else:
		_clip_t += delta * _clip_speed
	var len := c.length()
	var ended := _clip_t >= len
	if ended and _clip_loop and len > 0.0:
		_clip_t = fmod(_clip_t, len)
		ended = false
	var t1 := minf(_clip_t, len)
	_clip_w = move_toward(_clip_w, 1.0, delta * 5.0)
	# His travel this tick, in the clip's frame (the way he faced as it began: the clip plays in
	# that frame, his turning in it carried by his pelvis's turn, so the node never turns with
	# the clip), walked as a step is (stopped by walls and people; then his feet on whatever's
	# under him).
	var d := c.root_at(t1) - c.root_at(t0) if t1 >= t0 else c.root_at(t1) + (c.root_at(len) - c.root_at(t0))
	d.y = 0.0
	if not rising and not prone and not (stumbling > 0.0):
		if d.length() > 1e-5 and _clip_opts.get("travel", true):
			var moved := _slide(global_basis * d * _clip_w)
			_snap_to_ground()
			move_speed = moved.length() / maxf(delta, 1e-4)
			gait = &"walk" if move_speed >= 0.05 else gait
			_moved_this_tick = true
	_clip_hips = c.hips_at(t1)
	_clip_last = c.sample(t1)
	for ev: String in c.events_between(t0, t1):
		clip_event.emit(c.name, ev)
	if ended:
		var n := c.name
		_clip = null
		clip_done.emit(n)
	return _clip_last


## A part the clip swings (a kicking boot) meets what's in its way: a kit prop's member takes the
## blow of its speed and the leg's share of him (KitProp.take_blow: it breaks, moves or holds), once
## each. Held, the boot stops on it a moment (the clip stands) rather than passing through.
func _clip_strikes(delta: float) -> void:
	var c := _clip if _clip != null else null
	if c == null or c.strikes.is_empty() or delta <= 0.0:
		return
	var space := World.space(self)
	for sid: StringName in c.strikes:
		var part := parts.get(sid) as CollisionObject3D
		if part == null:
			continue
		var now := part.global_transform
		var was: Variant = _clip_part_was.get(sid)
		_clip_part_was[sid] = now
		if was == null:
			continue
		var v := (now.origin - (was as Transform3D).origin) / delta
		if v.length() < CLIP_STRIKE_SPEED:
			continue
		var shape := part.get_child(0) as CollisionShape3D
		if shape == null or shape.shape == null:
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape.shape
		q.collision_mask = Layers.WORLD
		q.exclude = _own_rids()
		# A boot at 7 m/s moves 12 cm a tick, more than a chair leg is thick: its sweep is tested at
		# a few points between where it was and where it is.
		var hits: Array[Dictionary] = []
		var local := part.global_transform.affine_inverse() * shape.global_transform
		for k in range(1, 5):
			q.transform = (was as Transform3D).interpolate_with(now, k / 4.0) * local
			Prof.count(&"q_body")
			for hit: Dictionary in space.intersect_shape(q, 4):
				hits.append(hit)
			if not hits.is_empty():
				break
		for hit: Dictionary in hits:
			var m := hit.get("collider") as StructureMember
			if m == null or m.broken or _clip_struck.has(m):
				continue
			var s := m.get_parent()
			if s == null or not s.has_method(&"take_blow"):
				continue
			_clip_struck[m] = true
			var at := m.global_transform.origin
			Prof.count(&"q_body")
			var pairs := space.collide_shape(q, 1)
			if pairs.size() >= 2:
				at = pairs[1]
			var result: StringName = s.call(&"take_blow", m, at, v * CLIP_BLOW_MASS, CLIP_BLOW_MASS)
			clip_struck.emit(m, result, v.length())
			# The boot's energy went into what it met, and the clip's follow-through is off: a part
			# moved by script would plough on through the chair and the man in it, throwing him as
			# a wall would. Held, the boot stands on the wood a moment; broke or moved, he eases
			# back off the kick (the chair and the man are physics' from here).
			if result == &"held":
				_clip_hold = maxf(_clip_hold, 0.15)
			else:
				stop_clip()
				return


## Swinging legs and arms while he moves: a walk, a run, a limp favouring the bad leg, a crawl.
func _gait_overlay(delta: float) -> Dictionary:
	var out := {}
	if gait == &"" or move_speed < 0.05:
		return out
	var stride: float = {&"walk": 1.3, &"run": 2.2, &"limp": 0.9, &"crawl": 0.5}.get(gait, 1.3)
	_gait_phase = fmod(_gait_phase + delta * move_speed / stride * TAU, TAU)
	var s := sin(_gait_phase)
	var c := cos(_gait_phase)
	var aiming := pose == &"aim" or pose == &"crouch_aim" or pose == &"prone_aim"
	match gait:
		&"crawl":
			# (His arms: _crawl_hands puts them down on the floor. Swung, they went through it.)
			out[&"thigh_r"] = Vector3(-maxf(s, 0.0) * 20.0, 0, 10)
			out[&"thigh_l"] = Vector3(-maxf(-s, 0.0) * 20.0, 0, -10)
			out[&"shin_r"] = Vector3(-maxf(s, 0.0) * 50.0, 0, 0)
			out[&"shin_l"] = Vector3(-maxf(-s, 0.0) * 50.0, 0, 0)
		_:
			var run := gait == &"run"
			var amp_t := 40.0 if run else 22.0
			var amp_s := 75.0 if run else 38.0
			var amp_a := 32.0 if run else 14.0
			var bad_r := gait == &"limp" and physiology.muscle_strength("leg", "r") - favouring(&"leg_r") \
					<= physiology.muscle_strength("leg", "l") - favouring(&"leg_l")
			# A leg he favours takes a shorter stride as it comes on; limping, the bad one a third.
			var k_r := 0.35 if gait == &"limp" and bad_r else lerpf(1.0, 0.5, favouring(&"leg_r"))
			var k_l := 0.35 if gait == &"limp" and not bad_r else lerpf(1.0, 0.5, favouring(&"leg_l"))
			out[&"thigh_r"] = Vector3(s * amp_t * k_r, 0, 0)
			out[&"thigh_l"] = Vector3(-s * amp_t * k_l, 0, 0)
			out[&"shin_r"] = Vector3(-maxf(c, 0.0) * amp_s * k_r, 0, 0)
			out[&"shin_l"] = Vector3(-maxf(-c, 0.0) * amp_s * k_l, 0, 0)
			if not aiming and pose != &"hands_bound":
				# A hurt arm is held, not swung.
				out[&"upper_arm_r"] = Vector3(-s * amp_a * (1.0 - favouring(&"arm_r")), 0, 0)
				out[&"upper_arm_l"] = Vector3(s * amp_a * (1.0 - favouring(&"arm_l")), 0, 0)
			if run:
				out[&"chest"] = Vector3(-12.0, 0, 0)
			if gait == &"limp":
				out[&"chest"] = Vector3(-6.0, 0, 8.0 * (1.0 if bad_r else -1.0) * absf(s))
	return out


## The rig's height and tilt: lowered so the lower foot is on the ground, or laid face-down.
func _place_rig(delta: float, snap: bool) -> void:
	if rising:
		_rise_step(delta)
		return
	var k := 1.0 if snap else clampf(delta * 8.0, 0.0, 1.0)
	if prone or pose == &"lie":
		_rig.rotation.x = lerp_angle(_rig.rotation.x, deg_to_rad(-90.0), clampf(delta * 3.0, 0.0, 1.0) if not snap else 1.0)
		_rig.position.y = lerpf(_rig.position.y, 0.16, k)
		_set_blocker(true)
		return
	_rig.rotation.x = 0.0
	if _rest_foot_y == 0.0:
		_rest_foot_y = _foot_height()
	var drop := _rest_foot_y - _foot_height() + _rig.position.y
	if _mocap_w > 0.0 and _mocap_hips >= 0.0:
		# On the clip his hips ride as the capture's did (a run leaves the ground: grounding his
		# lower foot dragged it along through the flight). Standing straight that's a leg length
		# above his ankles' rest: the rig where it stands.
		var hip_rest := _pivot_rest(&"thigh_l").y
		var ankle_rest := _pivot_rest(&"foot_l").y
		drop = lerpf(drop, _mocap_hips * _leg_length() + ankle_rest - hip_rest, _mocap_w)
	if _clip_w > 0.0 and _clip_hips >= 0.0:
		var hip_rest := _pivot_rest(&"thigh_l").y
		var ankle_rest := _pivot_rest(&"foot_l").y
		drop = lerpf(drop, _clip_hips * _leg_length() + ankle_rest - hip_rest, _clip_w)
	_rig.position.y = lerpf(_rig.position.y, drop, k)
	_set_blocker(false)


func _leg_length() -> float:
	var t: Dictionary = anatomy.segments[&"thigh_l"]
	var s: Dictionary = anatomy.segments[&"shin_l"]
	return ((t.b as Vector3) - (t.a as Vector3)).length() + ((s.b as Vector3) - (s.a as Vector3)).length()


func _foot_height() -> float:
	var lowest := INF
	for sid: StringName in [&"foot_r", &"foot_l"]:
		var pv := pivots.get(sid) as Node3D
		if pv:
			lowest = minf(lowest, to_local(pv.global_position).y)
	return lowest if lowest < INF else 0.0


## The capsule that stops the player walking through him: upright, or lying along him.
func _set_blocker(lying: bool) -> void:
	if _blocker == null or not is_instance_valid(_blocker):
		return
	var bs := _blocker.get_child(0) as CollisionShape3D
	if lying:
		bs.position = Vector3(0, 0.18, -0.85)
		bs.rotation_degrees = Vector3(90, 0, 0)
	else:
		var h := clampf(anatomy.height + _rig.position.y, 0.9, anatomy.height)
		bs.position = Vector3(0, h * 0.5, 0)
		bs.rotation_degrees = Vector3.ZERO


## How fast he breathes against a man at rest (about 15 a minute): faster short of breath (a lung
## holed or collapsing) and in shock (ATLS: 20-30 a minute in class II, over 35 in class IV).
func breath_rate() -> float:
	var p := physiology
	if not p.alive:
		return 0.0
	if p.shock() > AGONAL_SHOCK:
		return 0.35  # the last of it: slow, deep gasps
	return 1.0 + (1.0 - p.breath_capacity()) * 1.2 + p.shock() * 1.0


## Seconds a breath takes now.
func breath_period() -> float:
	return TAU / 1.6 / maxf(breath_rate(), 0.1)


## His WoundSigns, made the first time it's wanted.
func signs_now() -> WoundSigns:
	if signs == null:
		signs = WoundSigns.new()
		signs.name = "WoundSigns"
		signs.body = self
		signs._rng.seed = hash(["signs", rng_seed])
		add_child(signs)
	return signs


## How fast he's going (his chest's speed, m/s, world).
func velocity_now() -> Vector3:
	return _velocity_now


## His own parts' bodies (for rays that mustn't stop on him).
func _own_rids() -> Array[RID]:
	if _rids.size() != parts.size():
		_rids.clear()
		for sid: StringName in parts:
			_rids.append((parts[sid] as CollisionObject3D).get_rid())
	return _rids


## What a wound does to how he holds himself, on top of the pose (the gore lab, Gray's Anatomy):
## the radial nerve cut, the wrist drops (he can't lift his hand); a broken forearm bone, the
## forearm and the arm hang; a broken kneecap, the knee won't bend (he walks stiff-legged on
## it); the gut torn, he walks hunched over it (on top of the falls' favouring).
const WRIST_DROP := 55.0
const GUT_HUNCH := {&"abdomen": Vector3(-12, 0, 0), &"chest": Vector3(-6, 0, 0), &"neck": Vector3(-4, 0, 0)}


## Each comes on as the hurt does, over a second or two (the falls' FAVOUR_RATE), not as a jerk.
const INJURY_ONSET := 1.5
var _injury_w := {}  ## segment -> how far its injury's hold has come on (0..1)


func _injured(sid: StringName, goal: Vector3, delta: float) -> Vector3:
	var t: Variant = _injury_now.get(sid)
	if t == null:
		if not _injury_w.is_empty():
			_injury_w.erase(sid)
		return goal
	var want: Vector3 = (Vector3.ZERO if t[0] else goal) + (t[1] as Vector3)
	if want == goal:
		_injury_w.erase(sid)
		return goal
	var w: float = minf(float(_injury_w.get(sid, 0.0)) + delta / INJURY_ONSET, 1.0)
	_injury_w[sid] = w
	return goal.lerp(want, smoothstep(0.0, 1.0, w))


## What his injuries do to each joint this tick, worked out once for all of them (_injured is
## asked for every joint every tick): segment -> [the pose replaced (it hangs, it won't bend),
## what's added to it]. Empty for a man with nothing wrong (most men, most of the time).
var _injury_now := {}


func _injury_targets() -> void:
	_injury_now.clear()
	var p := physiology
	if limp or (p.cut.is_empty() and p.broken.is_empty() and p.torn.is_empty()):
		return
	for side: String in ["r", "l"]:
		if p.cut.has(StringName("radial_nerve_" + side)):
			_injury_now[StringName("hand_" + side)] = [false, Vector3(0, 0, -WRIST_DROP if side == "r" else WRIST_DROP)]
		if (p.broken.has(StringName("radius_" + side)) or p.broken.has(StringName("ulna_" + side)) \
				or p.broken.has(StringName("humerus_" + side))) and (_grab.is_empty() or _grab.side != side) and not slung.has(side):
			# It hangs at his side.
			_injury_now[StringName("forearm_" + side)] = [true, Vector3.ZERO]
			_injury_now[StringName("upper_arm_" + side)] = [true, Vector3.ZERO]
		if p.broken.has(StringName("patella_" + side)):
			_injury_now[StringName("shin_" + side)] = [true, Vector3.ZERO]  # the knee won't bend
	if p.torn.has(&"stomach") or p.torn.has(&"small_intestine") or p.torn.has(&"large_intestine"):
		for sid: StringName in GUT_HUNCH:
			var t: Array = _injury_now.get(sid, [false, Vector3.ZERO])
			_injury_now[sid] = [t[0], (t[1] as Vector3) + (GUT_HUNCH[sid] as Vector3)]


## Near the end, in deep shock, his breathing turns to slow gasps (agonal breathing).
const AGONAL_SHOCK := 0.92


# --- After the wound: dressings, the limb off, healing (the gore lab, part E) -----------------

## A wound bound up (Physiology.treated): a bandage round the limb or the body at the wound, red
## through where it still bleeds; a belt above for a tourniquet; a broken arm in a sling across
## him; a broken leg splinted with two sticks.
func _bind_wound(how: StringName, seg: StringName) -> void:
	var vis: Node3D = visuals.get(seg)
	if vis == null or anatomy.segments[seg].capsules.is_empty():
		return
	var cap: Array = anatomy.segments[seg].capsules[0]
	var center := anatomy.segment_center(seg)
	var a: Vector3 = (cap[0] as Vector3) - center
	var b: Vector3 = (cap[1] as Vector3) - center
	var r := _limb_radius(seg, b - a, float(cap[2]))
	var at := (a + b) * 0.5
	if how == &"pressure":
		for w: Dictionary in wounds:
			if w.segment == seg and w.entry != null:
				var t := clampf(((w.entry as Vector3) - a).dot(b - a) / maxf((b - a).length_squared(), 1e-6), 0.0, 1.0)
				at = a.lerp(b, t)
	else:
		at = a.lerp(b, 0.2)  # high up the limb, toward the body
	var mi := MeshInstance3D.new()
	mi.name = "Bandage" if how == &"pressure" else "Tourniquet"
	var band := CylinderMesh.new()
	band.top_radius = r * 1.06
	band.bottom_radius = r * 1.06
	band.height = 0.08 if how == &"pressure" else 0.035
	band.radial_segments = 12
	band.rings = 1
	mi.mesh = band
	var m := StandardMaterial3D.new()
	m.albedo_texture = PixelArt.blood("bandage" if how == &"pressure" else "sling", 83, false, 32)
	m.roughness = 0.95
	mi.material_override = m
	mi.layers = Layers.VIS_BODY
	mi.basis = _along(b - a)
	mi.position = at
	vis.add_child(mi)
	_bands.append({"mi": mi, "segment": seg})
	var s := String(seg)
	var side := s.right(1)
	if (s.begins_with("forearm") or s.begins_with("upper_arm")) and (physiology.broken.has(StringName("humerus_" + side)) \
			or physiology.broken.has(StringName("radius_" + side)) or physiology.broken.has(StringName("ulna_" + side))):
		slung[side] = true
	if (s.begins_with("thigh") or s.begins_with("shin")) and (physiology.broken.has(StringName("femur_" + side)) \
			or physiology.broken.has(StringName("tibia_" + side))):
		for k in 2:
			var stick := MeshInstance3D.new()
			stick.name = "Splint"
			var box := BoxMesh.new()
			box.size = Vector3(0.025, (b - a).length() * 1.1, 0.012)
			stick.mesh = box
			var wood := StandardMaterial3D.new()
			wood.albedo_color = Color(0.5, 0.38, 0.25)
			stick.material_override = wood
			stick.layers = Layers.VIS_BODY
			var basis := _along(b - a)
			stick.basis = basis
			stick.position = (a + b) * 0.5 + basis.x * (r * 1.2) * (1.0 if k == 0 else -1.0)
			vis.add_child(stick)


## How thick a limb is round its middle: his own clothed mesh's (a Studio man's thigh in his
## trousers is wider than the anatomy's), else the anatomy's capsule.
func _limb_radius(seg: StringName, axis: Vector3, fallback: float) -> float:
	var best := 0.0
	for mi: MeshInstance3D in segment_pieces.get(seg, []):
		var m: Mesh = _rigid_meshes.get(mi, null)
		if m == null:
			continue
		var box := m.get_aabb()
		var ax := axis.normalized()
		# Half its width across the limb (the box's extent off the axis, averaged).
		var w := 0.0
		var n := 0
		for k in 3:
			var e := Vector3.ZERO
			e[k] = 1.0
			if absf(e.dot(ax)) < 0.7:
				w += box.size[k] * 0.5
				n += 1
		if n > 0:
			best = maxf(best, w / n)
	return best if best > fallback * 0.8 and best < fallback * 3.0 else fallback


## Which arms ("r"/"l") are in a sling: held across him, not hanging.
var slung := {}
## Where a slung hand rests: across the front of him, under the other breast (his own space).
const SLING_HAND := Vector3(0.07, 1.13, -0.2)


## Where his palm is as drawn: a Studio man's skinned hand (its skeleton's `hand_r`/`hand_l`
## bone, a few centimetres on toward the fingers) sits apart from the physics hand while he stands.
func drawn_hand(side: String) -> Vector3:
	if skeleton != null and is_instance_valid(skeleton):
		var i := skeleton.find_bone("hand_" + side)
		if i >= 0:
			var t := skeleton.global_transform * skeleton.get_bone_global_pose(i)
			return t.origin + t.basis.y.normalized() * 0.04
	return (parts[StringName("hand_" + side)] as Node3D).global_position


## Crawling, each hand goes down flat on the floor ahead of his shoulder and stays where it's put
## while he pulls himself up to it, then comes up and reaches on (half his stride down, half
## reaching, the hands in turn). Where it goes down is where its print is (WoundSigns).
const CRAWL_REACH := 0.32  ## m ahead of his shoulder a hand goes down
const CRAWL_WIDE := 0.06  ## m outside it
const CRAWL_LIFT := 0.06  ## m a reaching hand comes up off the floor
const CRAWL_EASE := 0.3  ## s for his arms to come to it, or off it when he stops
var _crawl_plant := {}  ## side -> where that hand went down last (world)
var _crawl_down := {}  ## side -> whether it's down now
var _crawl_w := 0.0


func _crawl_hands(delta: float) -> void:
	var crawling := gait == &"crawl" and prone and not limp and not rising and move_speed >= 0.05 and pose != &"prone_aim"
	_crawl_w = move_toward(_crawl_w, 1.0 if crawling else 0.0, delta / CRAWL_EASE)
	if _crawl_w <= 0.0:
		_crawl_plant.clear()
		_crawl_down.clear()
		return
	var fwd := -global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 1e-4 else Vector3.FORWARD
	var right := fwd.cross(Vector3.UP)
	var k := smoothstep(0.0, 1.0, _crawl_w)
	for side: String in ["r", "l"]:
		if not _hand_free(side) and not (side == "r" and held_gun != null):
			continue
		var up := pivots.get(StringName("upper_arm_" + side)) as Node3D
		if up == null:
			continue
		var sx := 1.0 if side == "r" else -1.0
		var u := fmod(_gait_phase / TAU + (0.0 if side == "r" else 0.5), 1.0)
		var ahead := up.global_position + fwd * CRAWL_REACH + right * sx * CRAWL_WIDE
		ahead.y = global_position.y
		var down := u < 0.5
		if down and not _crawl_down.get(side, false) or not _crawl_plant.has(side):
			_crawl_plant[side] = ahead  # it goes down
		_crawl_down[side] = down
		var at: Vector3 = _crawl_plant[side]
		if not down:
			var t := (u - 0.5) * 2.0
			at = at.lerp(ahead, smoothstep(0.0, 1.0, t)) + Vector3.UP * sin(t * PI) * CRAWL_LIFT
		# Elbows out and up, not down through the floor.
		var pole := right * sx * 0.7 + Vector3.UP * 0.5 - fwd * 0.3
		_arm_to(side, at, Vector3.UP, k, &"", pole)


func _sling_step(delta: float) -> void:
	for side: String in slung:
		_sling_cloth(side)
		if limp or (not _grab.is_empty() and _grab.side == side):
			continue
		var key := StringName("sling_" + side)
		var w: float = minf(float(_injury_w.get(key, 0.0)) + delta / INJURY_ONSET, 1.0)
		_injury_w[key] = w
		var sx := 1.0 if side == "r" else -1.0
		_arm_to(side, global_transform * Vector3(-sx * SLING_HAND.x, SLING_HAND.y, SLING_HAND.z), Vector3.UP, smoothstep(0.0, 1.0, w), _grab.get("seg", &""))


## The sling itself (a folded kerchief, the Medical and Surgical History's "triangular bandage"):
## a cradle round the forearm and a strap from it up over the other side of his neck, drawn where
## the arm is each tick.
var _sling_parts := {}  ## side -> {"cradle", "strap"}
const SLING_STRAP_W := 0.07


func _sling_cloth(side: String) -> void:
	var fa_sid := StringName("forearm_" + side)
	var fa_vis: Node3D = visuals.get(fa_sid)
	var chest_vis: Node3D = visuals.get(&"chest")
	var parts_now: Dictionary = _sling_parts.get(side, {})
	if fa_vis == null or chest_vis == null or physiology.severed_segments.has(fa_sid):
		var gone: Variant = parts_now.get("strap")
		if gone != null and is_instance_valid(gone):
			(gone as Node3D).visible = false
		return
	if parts_now.is_empty():
		var m := StandardMaterial3D.new()
		m.albedo_texture = PixelArt.blood("sling", 83, false, 32)
		m.roughness = 0.95
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cap: Array = anatomy.segments[fa_sid].capsules[0] if not anatomy.segments[fa_sid].capsules.is_empty() else []
		var c := anatomy.segment_center(fa_sid)
		var a: Vector3 = (cap[0] as Vector3) - c if cap.size() > 0 else Vector3.ZERO
		var b: Vector3 = (cap[1] as Vector3) - c if cap.size() > 0 else Vector3.DOWN * 0.25
		var cradle := MeshInstance3D.new()
		cradle.name = "Sling"
		var cyl := CylinderMesh.new()
		var r := _limb_radius(fa_sid, b - a, float(cap[2]) if cap.size() > 2 else 0.04)
		cyl.top_radius = r * 1.15
		cyl.bottom_radius = r * 1.25
		cyl.height = (b - a).length() * 0.7
		cyl.radial_segments = 12
		cyl.rings = 1
		cradle.mesh = cyl
		cradle.material_override = m
		cradle.layers = Layers.VIS_BODY
		cradle.basis = _along(b - a)
		cradle.position = (a + b) * 0.5
		fa_vis.add_child(cradle)
		var strap := MeshInstance3D.new()
		strap.name = "SlingStrap"
		var box := BoxMesh.new()
		box.size = Vector3(SLING_STRAP_W, 1.0, 0.006)
		strap.mesh = box
		strap.material_override = m
		strap.layers = Layers.VIS_BODY
		chest_vis.add_child(strap)
		parts_now = {"cradle": cradle, "strap": strap}
		_sling_parts[side] = parts_now
	var cradle_mi := parts_now.cradle as MeshInstance3D
	var strap_mi := parts_now.strap as MeshInstance3D
	if not is_instance_valid(cradle_mi) or not is_instance_valid(strap_mi):
		return
	# From the cradle's top edge (his side of it, toward the elbow's far end) up to the other side
	# of his neck, at the root of it, where a sling's knot sits.
	var sx := 1.0 if side == "r" else -1.0
	# (On his front at the root of the neck: forward is -z in the anatomy's rest space.)
	var neck_rest := anatomy.segment_center(&"neck") + Vector3(-sx * 0.06, -0.05, -0.08)
	var top := chest_vis.global_transform * (neck_rest - anatomy.segment_center(&"chest"))
	var low := cradle_mi.global_position
	var span := top - low
	if span.length() < 0.05:
		return
	var y := span.normalized()
	# Flat against his front: the strap's face toward where he faces.
	var fwd := -chest_vis.global_basis.z
	var x := y.cross(fwd)
	if x.length() < 0.1:
		x = chest_vis.global_basis.x
	x = x.normalized()
	var z := x.cross(y).normalized()
	# (Out in front of his chest by the cloth's thickness, so it lies over his shirt.)
	strap_mi.global_transform = Transform3D(Basis(x, y * span.length(), z), (top + low) * 0.5 + z * 0.06)


## The doctor takes a limb off above where it's gone bad (or smashed): a flap closed over the
## bone with stitches (the Medical and Surgical History's flap operation), the vessels tied, the
## limb gone with what festered in it.
func amputate(segment: StringName) -> void:
	if physiology.severed_segments.has(segment):
		return
	var parent: StringName = anatomy.segments[segment].parent
	var joint := get_node_or_null(NodePath("Joint_%s" % segment)) as Node3D
	# (Standing, he has no joint bodies: the joint's rest place in his parent part.)
	var at: Vector3 = joint.global_position if joint else \
			(parts[parent] as Node3D).global_transform * (_pivot_rest(segment) - anatomy.segment_center(parent))
	var limb := parts[segment] as Node3D
	var down := limb.global_position - at
	var first := physiology.bleeds.size()
	physiology.sever(segment)
	# Tied off: the stump oozes, no more.
	for i in range(first, physiology.bleeds.size()):
		physiology.bleeds[i].rate = 0.05
		physiology.bleeds[i].kind = &"ooze"
	for sid in anatomy.segments_below(segment) + [segment]:
		physiology.infections.erase(sid)
	if physiology.fever() <= 0.0:
		physiology.gangrene_hours = 0.0
	_stop_skinning_across_joints(segment)
	if joint:
		joint.queue_free()
	for sid in anatomy.segments_below(segment):
		var rb := parts.get(sid) as Node3D
		if rb:
			rb.visible = false
			if rb is CollisionObject3D:
				(rb as CollisionObject3D).collision_layer = 0
				(rb as CollisionObject3D).collision_mask = 0
			for mi in segment_pieces.get(sid, []):
				(mi as MeshInstance3D).visible = false
	_stump_face(parent, at, down, float(anatomy.segments[segment].radius) * 1.2, &"stump_sewn")
	wounds.append({"segment": parent, "part": segment, "entry": parts[parent].global_transform.affine_inverse() * at,
			"exit": null, "lodged": false, "hits": [], "bleeds": range(first, physiology.bleeds.size()),
			"garments": [], "stain": null, "kind": &"amputated", "dir": down.normalized()})
	if segment.begins_with("hand") or segment.begins_with("forearm") or segment.begins_with("upper_arm"):
		if held_gun and String(segment).ends_with("_r"):
			drop_gun()


## A wound heals over days when it hasn't gone bad: it stops bleeding and closes to a scar, which
## he keeps (Wound.healed, in to_dict). What it did to him under the skin (a muscle torn, a bone
## that set crooked) stays: he favours an old leg wound for good.
const HEAL_GAME_DAYS := 12.0


func _heal(game_dt: float) -> void:
	var day := 24.0 * physiology.tuning.game_hour_seconds
	for w: Dictionary in wounds:
		if w.get("healed", false) or w.kind in [&"blast", &"severed", &"amputated"]:
			continue
		w.age = float(w.get("age", 0.0)) + game_dt
		if float(w.age) < HEAL_GAME_DAYS * day or physiology.infection(w.segment) > 0.0:
			continue
		w.healed = true
		for i: int in w.get("bleeds", []):
			if i < physiology.bleeds.size():
				physiology.bleeds[i].rate = 0.0
		for d: Variant in w.get("marks", []):
			if is_instance_valid(d):
				(d as Node).queue_free()
		w.marks = []
		w.stain = null
		var vis: Node3D = visuals.get(w.segment)
		if vis == null:
			continue
		for hole: Variant in [w.entry, w.exit]:
			if hole != null:
				var line: bool = w.kind == &"slash" or w.kind == &"cut" or w.kind == &"graze"
				var scar := _decal(vis, w.segment, hole, 0.035, PixelArt.blood("scar_line" if line else "scar", 87, false, 32))
				scar.name = "Scar"
				if line and w.get("stop") != null:
					var a: Vector3 = hole
					var b: Vector3 = w.stop
					var n := scar.basis.y
					var z := (b - a) - n * (b - a).dot(n)
					if z.length() > 0.005:
						z = z.normalized()
						scar.basis = Basis(n.cross(z), n, z)
						scar.position = (a + b) * 0.5
						scar.size = Vector3(0.02, 0.06, maxf(a.distance_to(b), 0.04) * 1.1)


func _after_step(real_dt: float, game_dt: float) -> void:
	if not physiology.alive and _face_mats.is_empty():
		return
	_heal(game_dt)
	_pallor_in -= real_dt
	if _pallor_in <= 0.0:
		_pallor_in = 0.5
		# Grey and waxy in shock, and the more so dead (ATLS: pale, cool, clammy skin).
		var p := physiology
		var pallor := clampf(p.shock() * 0.8 + (0.0 if p.alive else 0.5), 0.0, 1.0)
		for m in _face_mats:
			m.set_shader_parameter(&"pallor", pallor)
		# A bandage that's still bleeding through shows it.
		for band: Dictionary in _bands:
			var mi := band.mi as MeshInstance3D
			if not is_instance_valid(mi) or mi.name != "Bandage":
				continue
			var wet := false
			for b: Dictionary in p.bleeds:
				if b.segment == band.segment and p.bleed_rate(b) > 0.15:
					wet = true
			(mi.material_override as StandardMaterial3D).albedo_texture = PixelArt.blood("bandage_soaked" if wet else "bandage", 83, false, 32)


## Blood in the windpipe or a holed lung: he coughs it up, now and then.
func _cough(delta: float) -> void:
	var p := physiology
	if not p.alive or not (p.airway_blood or not p.lung_damage.is_empty()):
		return
	_cough_in -= delta
	if _cough_in > 0.0:
		return
	_cough_in = _rng.randf_range(2.5, 6.0) if p.airway_blood else _rng.randf_range(5.0, 11.0)
	var head: Node3D = parts[&"head"]
	var mouth := head.global_transform * (Vector3(0, 1.58, -0.1) - anatomy.segment_center(&"head"))
	var fwd := -head.global_basis.z
	# From a holed lung it comes up frothy and bright, pink with air (ATLS).
	Blood.burst(get_parent(), mouth, fwd + Vector3.UP * 0.2, 10, 1.6, WoundSigns.FROTH if not p.lung_damage.is_empty() else Blood.ARTERIAL)
	Blood.throw(get_parent() as Node3D, mouth, fwd * 1.6, 3.0)
	_flinch_from(&"chest", mouth, -fwd, 0.02)


## Throw the hit segment and the ones above it back from the bullet.
## Hit and still on his feet: no flinch or wince (Sean, 2026-10-18), but you see what the wound does
## to him, coming on as a hurt would (Sean, 2026-10-21: "make it the wound's consequence, at a
## believable speed"; a reaction "tooooo fast" before). How much he favours each part of him: the
## muscle the ball tore there (at once) and that part's share of his pain (which arrives over
## seconds: Physiology.pain_onset). A leg: he takes his weight off it and walks short on it; an
## arm: his gun hand sags out of his aim, the other arm's held in; the body: he guards it, bent
## a little round it, and goes slower. Degrees at full (the poses' axes: + x is forward for a limb
## and back for the spine; + z moves a right limb out and bends the spine to his left).
const FAVOUR_LEG := {&"thigh": Vector3(12, 0, 0), &"shin": Vector3(-26, 0, 0), &"foot": Vector3(10, 0, 0)}
## ... and his trunk leans this far toward the good leg (z, sign by the side).
const FAVOUR_LEG_LEAN := {&"abdomen": 5.0, &"chest": 4.0}
const FAVOUR_GUN_ARM_SAG := Vector3(-20, 0, 0)  ## upper_arm_r when aiming
const FAVOUR_ARM_HELD := {&"upper_arm": Vector3(10, 0, -5), &"forearm": Vector3(40, 0, 0)}
const FAVOUR_BODY := {&"abdomen": Vector3(-7, 0, 4), &"chest": Vector3(-6, 0, 3), &"neck": Vector3(-3, 0, 0)}
## How it comes on: a critically damped spring this many radians a second (90% in ~1.2 s, a gentle
## start, no snap).
const FAVOUR_RATE := 3.2
## How much it slows him at full: a leg he favours, a body hit.
const FAVOUR_PACE_LEG := 0.35
const FAVOUR_PACE_BODY := 0.3
## Favouring a leg this much, he limps.
const FAVOUR_LIMP := 0.6
## Per unit of a muscle torn there (Physiology.muscle_damage; a ball through one tears ~0.5).
const FAVOUR_PER_TEAR := 1.4
## A part's share of his pain at which he favours it fully (pain in Physiology's units: a ball
## through a muscle is ~0.4, pain_disabling 0.9).
const FAVOUR_FULL_PAIN := 0.6


func favouring(region: StringName) -> float:
	return float((_favour.get(region, [0.0, 0.0]) as Array)[0])


## How fast he can go for what he's favouring (1 = as he was).
func favour_pace() -> float:
	return (1.0 - FAVOUR_PACE_LEG * maxf(favouring(&"leg_r"), favouring(&"leg_l"))) \
			* (1.0 - FAVOUR_PACE_BODY * favouring(&"body"))


func _favour_region(seg: StringName) -> StringName:
	var s := String(seg)
	for limb in ["thigh", "shin", "foot"]:
		if s.begins_with(limb):
			return StringName("leg" + s.right(2))
	for limb in ["upper_arm", "forearm", "hand"]:
		if s.begins_with(limb):
			return StringName("arm" + s.right(2))
	if seg in [&"chest", &"abdomen", &"pelvis"]:
		return &"body"
	return &""


func _favour_step(delta: float) -> void:
	if wounds.is_empty() and _favour.is_empty():
		return
	# Each region's share of his wounds (a graze or a pellet counts for less).
	var share := {}
	var total := 0.0
	for w: Dictionary in wounds:
		var r := _favour_region(w.get("segment", &""))
		if r == &"":
			continue
		var k := 0.35 if w.get("kind", &"") in [&"graze", &"pellet"] else 1.0
		share[r] = float(share.get(r, 0.0)) + k
		total += k
	var felt := physiology.felt_pain()
	for r: StringName in [&"leg_r", &"leg_l", &"arm_r", &"arm_l", &"body"]:
		var target := 0.0
		var hurts := 0.0
		if total > 0.0 and share.has(r):
			hurts = felt * float(share[r]) / total / FAVOUR_FULL_PAIN
		# The worst torn muscle there: a torn thigh won't take his weight from the first step.
		var side := String(r).right(1)
		var groups: Array = ["leg"] if String(r).begins_with("leg") else (["arm", "grip"] if String(r).begins_with("arm") else [])
		for g: String in groups:
			for id: StringName in physiology._muscles(g, side):
				target = maxf(target, float(physiology.muscle_damage.get(id, 0.0)) * FAVOUR_PER_TEAR)
		target = clampf(target + hurts, 0.0, 1.0)
		var f: Array = _favour.get(r, [0.0, 0.0])
		if target <= 0.0 and f[0] <= 0.001 and absf(f[1]) < 0.001:
			_favour.erase(r)
			continue
		f[1] += (FAVOUR_RATE * FAVOUR_RATE * (target - f[0]) - 2.0 * FAVOUR_RATE * f[1]) * delta
		f[0] = clampf(f[0] + f[1] * delta, 0.0, 1.0)
		_favour[r] = f
	_favour_lean.clear()
	var aiming := pose == &"aim" or pose == &"crouch_aim"
	var standing := gait == &"" or move_speed < 0.3
	for side in ["r", "l"]:
		var sign_z := 1.0 if side == "r" else -1.0
		var leg := favouring(StringName("leg_" + side))
		if leg > 0.0 and standing and not pose in [&"crouch", &"crouch_aim", &"sit", &"sit_back", &"sit_lean", &"duck", &"tend", &"cower"]:
			# Standing: the knee eases off and the weight goes on the other leg.
			for key: StringName in FAVOUR_LEG:
				_add_favour(StringName(String(key) + "_" + side), FAVOUR_LEG[key] * leg)
			for key: StringName in FAVOUR_LEG_LEAN:
				# + z bends him to his left: off a right leg is toward his left.
				_add_favour(key, Vector3(0, 0, FAVOUR_LEG_LEAN[key] * sign_z * leg))
		var arm := favouring(StringName("arm_" + side))
		if arm > 0.0:
			if side == "r" and aiming:
				_add_favour(&"upper_arm_r", FAVOUR_GUN_ARM_SAG * arm)
			elif pose in [&"stand", &"wary", &"aim", &"crouch", &"crouch_aim"]:
				for key: StringName in FAVOUR_ARM_HELD:
					var d: Vector3 = FAVOUR_ARM_HELD[key]
					_add_favour(StringName(String(key) + "_" + side), Vector3(d.x, d.y, d.z * sign_z) * arm)
	var body := favouring(&"body")
	if body > 0.0:
		# Bent toward the side the wounds are on (the poses' + z is his left).
		var lean := 0.0
		for w: Dictionary in wounds:
			if _favour_region(w.get("segment", &"")) == &"body" and w.get("entry") is Vector3:
				lean -= signf((w.entry as Vector3).x)
		lean = clampf(lean, -1.0, 1.0)
		for key: StringName in FAVOUR_BODY:
			var d: Vector3 = FAVOUR_BODY[key]
			_add_favour(key, Vector3(d.x, d.y, d.z * lean) * body)


func _add_favour(sid: StringName, d: Vector3) -> void:
	_favour_lean[sid] = (_favour_lean.get(sid, Vector3.ZERO) as Vector3) + d


func _flinch_from(segment: StringName, at: Vector3, dir: Vector3, momentum: float) -> void:
	var sid := segment
	var k := 900.0 * momentum
	while sid != &"" and pivots.has(sid):
		var pivot: Node3D = pivots[sid]
		var axis_world := (at - pivot.global_position).cross(dir)
		var axis := pivot.global_basis.inverse() * axis_world
		var f: Array = _flinch.get(sid, [Vector3.ZERO, Vector3.ZERO])
		f[1] += Vector3(axis.x, axis.y, axis.z) * k
		_flinch[sid] = f
		k *= 0.6
		sid = anatomy.segments[sid].parent


# --- A hand to the wound -----------------------------------------------------------------------

## Hit and still on his feet, he puts a free hand over the hole: the throat, a side, his belly, a
## thigh, the other arm. Not a flinch (Sean, 2026-10-18: no flinch or wince for a ball that doesn't
## drop him) but after a beat, as a man does who has just found he's hit, and held while it bleeds or
## hurts. Procedural, by two-bone IK on the arm after the pose: the hole is wherever the ball went,
## which no clip can know (Sean, 2026-10-21). Measured in experiments/body_lab (`grab`).
const GRAB_DELAY := 0.3  ## s before he reaches: he's only just found it
const GRAB_REACH := 0.55  ## s to get his hand there
const GRAB_LET_GO := 1.2  ## s to let it fall away
const GRAB_HOLD_BLEED := 0.15  ## ml/s still coming from it: he holds on
const GRAB_HOLD_PAIN := 0.3  ## felt pain: he holds on
const GRAB_PALM := 0.075  ## m from the wrist to the middle of the palm, laid over the hole
const GRAB_OFF_SKIN := 0.03  ## m the palm's middle stands off the skin (the hand's own thickness)
## Poses in which a hand can go to a wound (not his hands up or bound, not lying, not dragging).
const GRAB_POSES := [&"stand", &"aim", &"wary", &"crouch", &"crouch_aim", &"duck", &"clutch", &"tend", &"shove", &"wince"]
var _grab := {}  ## {wound, seg, at (part-local), side, t, w}
## Off: no hand goes to a wound (the body lab's A/B, `--no-grab`).
static var hand_to_wound := true


## A new wound: if it's bleeding worse than the one he's holding (or he holds none), it's the one
## his hand goes to, by the side it's on, or the hand that's free.
func _reach_for(w: Dictionary) -> void:
	# Not for a graze: it stings, he doesn't hold it (Sean, 2026-10-21: "no grab on a graze").
	if not hand_to_wound or limp or prone or w.kind in [&"blast", &"severed", &"graze"]:
		return
	if not _grab.is_empty() and _wound_bleed(_grab.wound) >= _wound_bleed(w):
		return
	var seg: StringName = w.segment
	var at: Vector3 = w.entry
	# The way out, if that's the hole on his front (a ball from behind).
	if w.exit != null and _skin_normal(seg, w.exit).z < _skin_normal(seg, at).z:
		at = w.exit
	var side := _grab_hand(seg, at)
	if side == "":
		return
	var keep: float = _grab.get("w", 0.0) if _grab.get("side", "") == side else 0.0
	if not _grab.is_empty():
		_hand_press(_grab.wound, false)
	_grab = {"wound": w, "seg": seg, "at": at, "side": side, "t": 0.0, "w": keep}


## Which hand ("r"/"l", or "" if neither): not the arm that's hit, not the gun hand, not a broken
## or lost one; the one on the wound's side first.
func _grab_hand(seg: StringName, at: Vector3) -> String:
	var s := String(seg)
	var on_arm := s.begins_with("upper_arm") or s.begins_with("forearm") or s.begins_with("hand")
	var first := "r" if (anatomy.segment_center(seg) + at).x > 0.0 else "l"
	if on_arm:
		first = "l" if s.ends_with("_r") else "r"
	for side in [first, "l" if first == "r" else "r"]:
		if on_arm and s.ends_with("_" + side):
			continue
		if _hand_free(side):
			return side
	return ""


func _hand_free(side: String) -> bool:
	var p := physiology
	if p.arms_paralysed():
		return false
	if side == "r" and held_gun != null and not gun_holstered:
		return false
	for part in [&"upper_arm_", &"forearm_", &"hand_"]:
		if p.severed_segments.has(StringName(part + side)):
			return false
	for bone in [&"humerus_", &"radius_", &"ulna_", &"clavicle_"]:
		if p.broken.has(StringName(bone + side)):
			return false
	return true


## How much a hand is pressed over this point (world): 0 none, 1 his palm right on it (the
## blood wells out between his fingers rather than spurting: BloodJet).
func hand_over(point: Vector3) -> float:
	if _grab.is_empty() or limp:
		return 0.0
	var palm := (parts[StringName("hand_" + _grab.side)] as Node3D).global_position
	return float(_grab.w) * clampf(1.0 - (palm.distance_to(point) - 0.05) / 0.05, 0.0, 1.0)


## What a wound bleeds now, as if no hand were on it (so holding it doesn't make him let go).
func _wound_bleed(w: Dictionary) -> float:
	var r := 0.0
	for i: int in w.get("bleeds", []):
		if i < physiology.bleeds.size():
			var b: Dictionary = physiology.bleeds[i]
			var rate := physiology.bleed_rate(b)
			if b.get("hand", false) and not b.pressure and not b.tourniquet:
				rate /= physiology.tuning.pressure_factor
			r += rate
	return r


## His palm clamped over a wound holds its bleeding back (the outside ones: not what bleeds inside
## him) while it's there; lifted, it spurts again.
const GRAB_PRESSES := 0.9  ## the hand's this far there (its weight) before it presses


func _hand_press(w: Dictionary, on: bool) -> void:
	for i: int in w.get("bleeds", []):
		if i < physiology.bleeds.size() and physiology.bleeds[i].kind != &"internal":
			physiology.bleeds[i].hand = on


func _grab_step(delta: float) -> void:
	if _grab.is_empty():
		return
	var g := _grab
	g.t += delta
	var side: String = g.side
	var holding: bool = physiology.is_conscious() and pose in GRAB_POSES and stumbling <= 0.0 and _hand_free(side) \
			and parts.has(g.seg) and (_wound_bleed(g.wound) > GRAB_HOLD_BLEED or physiology.felt_pain() > GRAB_HOLD_PAIN)
	var goal := 1.0 if holding and g.t >= GRAB_DELAY else 0.0
	g.w = move_toward(g.w, goal, delta / (GRAB_REACH if goal > g.w else GRAB_LET_GO))
	_hand_press(g.wound, g.w >= GRAB_PRESSES)
	if g.w <= 0.0 and goal == 0.0 and g.t >= GRAB_DELAY:
		_grab.clear()
		return
	var k := smoothstep(0.0, 1.0, g.w)
	# A shot hand or forearm: he brings it in to the front of his belly and holds it with the other.
	var hurt := ""
	if String(g.seg).begins_with("hand") or String(g.seg).begins_with("forearm"):
		hurt = String(g.seg).right(1)
		var hx := 1.0 if hurt == "r" else -1.0
		_arm_to(hurt, global_transform * Vector3(hx * 0.05, 1.02, -0.24), Vector3.UP, k, g.seg)
	var part := parts[g.seg] as Node3D
	var at: Vector3 = part.global_transform * (g.at as Vector3)
	if not g.has("n"):
		g.n = _skin_normal(g.seg, g.at)  # (the same each tick: worked out once)
	var n := (part.global_basis * (g.n as Vector3)).normalized()
	if not _arm_to(side, at, n, k, g.seg) and hurt == "":
		_hand_press(g.wound, false)
		_grab.clear()  # out of his reach (a shin, standing): he leaves it
		return
	if side == "r" and held_gun != null and not gun_holstered:
		return
	var curl := lerpf(0.15, 0.4, k)
	if absf(curl - float(g.get("curl", -1.0))) > 0.02:
		g.curl = curl
		curl_hand(side, curl)


## Where a deed has put his hands this tick (WipeBar: on the bar top, at his shoulder, round a
## glass): side -> {at, n, k, frame}. Laid by the same IK as a hand to a wound (`_arm_to`), after
## the pose and before the wound's (a hand going to a wound wins, from wherever this put it); a
## reach nobody renewed since the last tick lets the arm go back to the pose.
var _reach := {}


## Put his hand on `side` at `at` (world: the middle of the palm), palm toward `-n` (a bar top's
## normal: palm down on it), `k` of the way from the pose (0..1; ease it). Call it every tick he's
## to keep it there. False if it's out of his reach (the arm goes as far as it can).
func reach_to(side: String, at: Vector3, n := Vector3.UP, k := 1.0) -> bool:
	_reach[side] = {"at": at, "n": n.normalized(), "k": clampf(k, 0.0, 1.0), "frame": Engine.get_physics_frames()}
	return can_reach(side, at)


## Whether the middle of his palm on `side` could be put at `at` from where he stands.
func can_reach(side: String, at: Vector3) -> bool:
	var up := pivots.get(StringName("upper_arm_" + side)) as Node3D
	if up == null or limp:
		return false
	return up.global_position.distance_to(at) <= _arm_length(side) + GRAB_PALM


## Shoulder to wrist (m).
func _arm_length(side: String) -> float:
	return (_pivot_rest(StringName("forearm_" + side)) - _pivot_rest(StringName("upper_arm_" + side))).length() \
			+ (_pivot_rest(StringName("hand_" + side)) - _pivot_rest(StringName("forearm_" + side))).length()


## The middle of his palm on `side` (world), where he holds things.
func palm(side: String) -> Vector3:
	var hand := parts.get(StringName("hand_" + side)) as Node3D
	return hand.global_position if hand else global_position


## The hand on `side` is pressed on a wound (his own): the blood coming out under it now (ml/s,
## held back as it is by the press), by how far the hand is there. 0 if it's on none.
func wound_under_hand(side: String) -> float:
	if _grab.is_empty() or _grab.side != side or limp:
		return 0.0
	var r := 0.0
	for i: int in _grab.wound.get("bleeds", []):
		if i < physiology.bleeds.size() and physiology.bleeds[i].kind != &"internal":
			r += physiology.bleed_rate(physiology.bleeds[i])
	return r * float(_grab.w)


## The hand going to (or holding) a wound, "r"/"l", or "" if neither.
func grab_side() -> String:
	return "" if _grab.is_empty() else String(_grab.side)


func _reach_step() -> void:
	if _reach.is_empty():
		return
	var now := Engine.get_physics_frames()
	for side: String in _reach.keys():
		var r: Dictionary = _reach[side]
		if now - int(r.frame) > 1 or prone or not _hand_free(side):
			_reach.erase(side)
			continue
		# (A hand going to a wound of his takes it on from here: _grab_step blends from where this
		# leaves the arm, so it doesn't drop to the pose first.)
		var at: Vector3 = r.at
		# Out of reach, as far toward it as the arm goes (not the pose for a tick, then back).
		var sh := (pivots[StringName("upper_arm_" + side)] as Node3D).global_position
		var most := _arm_length(side) + GRAB_PALM - 0.02
		if sh.distance_to(at) > most:
			at = sh + (at - sh).normalized() * most
		# `at` is the palm's middle; _arm_to lays the palm's middle GRAB_OFF_SKIN off the point.
		_arm_to(side, at - (r.n as Vector3) * GRAB_OFF_SKIN, r.n, r.k)


## Lay the hand on `side` over the point `at` (world, skin normal `n`), by `k` of the way from the
## pose: two-bone IK on the shoulder and elbow, the elbow out and down, then the hand turned to lie
## across the hole palm in. False if it's out of his reach. `on_seg`: the part of him it's on, if any
## (his neck and trunk take the hand more level).
func _arm_to(side: String, at: Vector3, n: Vector3, k: float, on_seg := &"", pole_hint := Vector3.ZERO) -> bool:
	var up := pivots.get(StringName("upper_arm_" + side)) as Node3D
	var fa := pivots.get(StringName("forearm_" + side)) as Node3D
	var hd := pivots.get(StringName("hand_" + side)) as Node3D
	if up == null or fa == null or hd == null:
		return false
	var hand_sid := StringName("hand_" + side)
	var l1 := (_pivot_rest(StringName("forearm_" + side)) - _pivot_rest(StringName("upper_arm_" + side))).length()
	var l2 := (_pivot_rest(hand_sid) - _pivot_rest(StringName("forearm_" + side))).length()
	var sh := up.global_position
	# The hand lies across the hole the way the arm comes to it, along the skin; on his neck and
	# trunk more level than that (fingers round the side of the neck, not up over his chin).
	var along := at - sh
	var high: bool = on_seg in [&"neck", &"head"]
	if high:
		# Up from in front, his fingers round the side of his neck toward the back, elbow down.
		along = global_basis * Vector3(0, 0.3, 1)
	elif on_seg in [&"chest", &"abdomen", &"pelvis"]:
		along = global_basis.inverse() * along
		along.y *= 0.25
		along = global_basis * along
	along = (along - n * along.dot(n))
	along = along.normalized() if along.length() > 1e-4 else Vector3.DOWN
	var wrist := at + n * GRAB_OFF_SKIN - along * GRAB_PALM
	var to := wrist - sh
	if to.length() > l1 + l2 + 0.1:
		return false
	var d := clampf(to.length(), absf(l1 - l2) + 0.01, l1 + l2 - 0.005)
	var dir := to.normalized()
	var sx := 1.0 if side == "r" else -1.0
	var pole := global_basis.x * sx * 0.6 + Vector3.DOWN * 0.4 + global_basis.z * 0.3
	if high:
		pole = -global_basis.z * 0.5 + Vector3.DOWN * 0.6 + global_basis.x * sx * 0.2
	if pole_hint != Vector3.ZERO:
		pole = pole_hint
	pole = (pole - dir * pole.dot(dir)).normalized()
	var a := (l1 * l1 + d * d - l2 * l2) / (2.0 * d)
	var elbow := sh + dir * a + pole * sqrt(maxf(l1 * l1 - a * a, 0.0))
	var wrist_at := sh + dir * d
	# Worked out on the joints' world frames, then each set once (setting them as it goes made the
	# engine work out every part under them each time).
	var b_up := up.global_basis
	var b_fa := fa.global_basis
	var b_hd := hd.global_basis
	var e0 := fa.global_position
	var w0 := hd.global_position
	var q1 := Quaternion((e0 - sh).normalized(), (elbow - sh).normalized())
	var e1 := sh + q1 * (e0 - sh)
	var w1 := e1 + q1 * (w0 - e0)
	var q2 := Quaternion((w1 - e1).normalized(), (wrist_at - e1).normalized())
	var up_ik := Basis(q1) * b_up
	var fa_ik := Basis(q2 * q1) * b_fa
	var hd_ik := Basis(q2 * q1) * b_hd
	var seg: Dictionary = anatomy.segments[hand_sid]
	var axis := ((seg.b as Vector3) - (seg.a as Vector3)).normalized()
	hd_ik = Basis(Quaternion((hd_ik * axis).normalized(), along)) * hd_ik
	# Palm in, onto him (at rest the palms face in: -x on the right hand, +x on the left).
	var palm := hd_ik * Vector3(-sx, 0, 0)
	var want := -n - along * (-n).dot(along)
	var have := palm - along * palm.dot(along)
	if want.length() > 1e-4 and have.length() > 1e-4:
		hd_ik = Basis(along, have.normalized().signed_angle_to(want.normalized(), along)) * hd_ik
	up.global_basis = Basis(b_up.get_rotation_quaternion().slerp(up_ik.get_rotation_quaternion(), k))
	fa.global_basis = Basis(b_fa.get_rotation_quaternion().slerp(fa_ik.get_rotation_quaternion(), k))
	hd.global_basis = Basis(b_hd.get_rotation_quaternion().slerp(hd_ik.get_rotation_quaternion(), k))
	return true


# --- Being shot --------------------------------------------------------------------------------

## A bullet reached a body part's hitbox. Traces it through the anatomy under the clothes; returns
## {segment, exit (world Vector3 or null), energy_out, hits, wound}. `blast` is the muzzle blast it
## brings (joules; Ballistics works it out from the range, or it's a revolver's from `travelled`).
## Anything lighter than 6 g is a buckshot pellet.
func take_bullet(collider: Node3D, pos: Vector3, dir: Vector3, energy: float, bullet_radius: float, mass := 0.0165, travelled := 99.0, blast := -1.0, projectile := &"") -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment")
	var xf := collider.global_transform
	var center := anatomy.segment_center(seg)
	var inv := xf.affine_inverse()
	var d := (inv.basis * dir).normalized()
	var o := inv * pos + center - d * 0.01
	var holed: Array[StringName] = []
	for g in garments:
		if g.covers.has(seg):
			energy -= g.resistance
			g.holes.append({"segment": seg, "at": o - center})
			holed.append(g.id)
	energy = maxf(energy, 0.0)
	var tr := anatomy.trace(seg, o, d, energy, bullet_radius, _rng)
	var bleeds := physiology.apply_trace(tr)
	var wound := {"segment": seg, "entry": tr.entry - center,
			"exit": (tr.exit - center) if tr.exit != null else null, "lodged": tr.exit == null,
			"hits": tr.hits.map(func(h: Dictionary) -> Dictionary: return {"id": h.id, "effect": h.effect}),
			"stop": (tr.stop - center) if tr.stop != null else null,
			"bleeds": bleeds, "garments": holed, "stain": null,
			"kind": &"graze" if tr.graze else (projectile if projectile != &"" else (&"pellet" if mass < PELLET_MASS else &"bullet")), "dir": d,
			"exits": (tr.exits as Array).map(func(e: Vector3) -> Vector3: return e - center),
			"flattened": tr.flattened, "split": tr.split, "skipped": tr.skipped,
			"radius": bullet_radius, "contact": travelled < CONTACT_RANGE}
	# A ball through his clothes carries a plug of them in with it (the Medical and Surgical History:
	# cloth was the commonest thing taken out of a wound); one that stays in him keeps it.
	if not holed.is_empty() and not tr.graze and _chance(tr.entry, 7) < (CLOTH_IN_LODGED if wound.lodged else CLOTH_IN_THROUGH):
		wound.cloth = holed[0]
	# A wound with cloth in it festers; a clean one sometimes does (Physiology.contaminate).
	if not tr.graze and (wound.has("cloth") or _chance(tr.entry, 17) < FESTER_CLEAN_CHANCE):
		physiology.contaminate(seg, wound.has("cloth"))
	# Fired within about a metre: burnt powder and soot round the hole (`powder`, how far off).
	if travelled < POWDER_RANGE and mass >= PELLET_MASS and not tr.graze:
		wound.powder = maxf(travelled, 0.001)
	wounds.append(wound)
	_paint_wound(wound)
	# A scalp wound above the eyes bleeds freely and runs into the eye on that side.
	if seg == &"head" and tr.graze and (tr.entry as Vector3).y > 1.65:
		physiology.blood_in_eye[&"r" if (tr.entry as Vector3).x > 0.0 else &"l"] = Physiology.SCALP_BLIND_SECONDS
	for h: Dictionary in tr.hits:
		if h.effect == &"severed":
			if h.kind == &"appendage":
				shoot_off(h.id, dir)
			else:
				sever_finger(h.id, dir)
	var deposited := maxf(energy - tr.energy_out, 0.0)
	# A heavy ball or close buckshot that breaks the lower jaw can carry it away.
	if seg == &"head" and not physiology.jaw_gone and tr.hits.any(func(h: Dictionary) -> bool: return h.id == &"jaw" and h.effect == &"broken") \
			and (deposited + maxf(blast, 0.0)) >= JAW_AWAY_J:
		jaw_away(dir)
	# Where it tore the skin open. A single ball doesn't: its way in is a neat hole its own width,
	# its way out a slit or star little bigger (DiMaio, Gunshot Wounds; the marks show them, sized by
	# the ball in _paint_wound_marks). Buckshot does, its pellets' holes running into one ragged
	# hole within a metre or two, and so does a blast (Blast's own openings).
	var pellet := mass < PELLET_MASS
	var at_entry := deposited * (0.25 if tr.exit != null else 0.6) if pellet else 0.0
	if blast < 0.0:
		blast = 300.0 if travelled < 0.3 else 120.0 * maxf(1.5 - travelled, 0.0)
	# (A pistol's gas on him shows as the contact wound's star and soot, not a torn crater.)
	at_entry += blast if pellet else 0.0
	if not tr.graze and at_entry > 0.0:
		open_wound(seg, tr.entry - center, at_entry, dir, &"gore_exit" if travelled < CONTACT_RANGE else &"gore_crater")
	if not tr.graze:
		if tr.exit != null and pellet:
			open_wound(seg, tr.exit - center, deposited * 0.75 * (1.6 if tr.flattened else 1.0), dir, &"gore_exit")
	var severe := false
	for h: Dictionary in tr.hits:
		if h.effect == &"broken" or (h.kind == &"organ") or (h.kind == &"artery"):
			severe = true
	# The momentum the ball leaves in him: what it came in with less what it went on with
	# (a .45 ball stopped in him is 4.5 N*s: a man's speed changes by 6 cm/s, it doesn't throw him).
	var given := maxf(mass, 0.001) * (sqrt(2.0 * energy / maxf(mass, 0.001)) - sqrt(2.0 * tr.energy_out / maxf(mass, 0.001)))
	var knocked := not limp and _knocked_down(seg, deposited, severe, _small_wound(wound.kind))
	if not knocked:
		_reach_for(wound)
	if knocked:
		_knocked(seg, pos, dir, given)
	elif limp and parts.get(seg) is RigidBody3D:
		# (The part hit may be the standing one he left this tick: the push goes to his body.)
		var rb := parts[seg] as RigidBody3D
		rb.apply_impulse(dir * given, pos - rb.global_position)
	elif stumbling > 0.0:
		# Hit again as he stumbles: that's him down now.
		_fall_now()
	# Hit and still on his feet: nothing from the ball itself (its push moves a man a few
	# centimetres). The flinch kicked him 50 degrees back in a twentieth of a second, and a wince
	# in its place still read as a twitch (Sean: "just get rid of these winces"); what the wound
	# does to him is his pain, his blood and his brain's.
	var exit_world: Variant = xf * (tr.exit - center) if tr.exit != null else null
	if exit_world != null and get_parent() is Node3D:
		# The spray out of the exit wound spatters whatever's behind him.
		var big := seg == &"head"
		Blood.spray(get_parent() as Node3D, exit_world, dir, 40.0 if big else 12.0, 9 if big else 4, _rng)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": wound.hits,
			"position": pos, "direction": dir, "exit": exit_world, "lodged": wound.lodged,
			"deposited": deposited, "severe": severe, "knocked_down": knocked, "kind": wound.kind}
	hit.emit(info)
	Events.body_hit.emit(info)
	if xray:
		set_xray(true)
	# A ball that skipped off a bone or split leaves on its own line.
	var dir_out: Variant = (xf.basis * (tr.out_dir as Vector3)).normalized() if tr.has("out_dir") else null
	return {"segment": seg, "exit": exit_world, "energy_out": tr.energy_out, "hits": tr.hits, "wound": wound, "dir_out": dir_out}


## Does the hit itself put him down? A heavy ball dumping its energy in the trunk often does.
## A ball that drops him. Standing, he goes down where he is, curling round it (_hunch). On the
## move and still with it, he doesn't drop dead in his tracks: his stride carries him on a step or
## so, slowing, as he flinches and folds round it, and then his legs go (Sean, 2026-10-16: the
## walking stumble). A leg wound gives under him sooner; the head or neck, no stumble. `given` is
## the ball's momentum (N*s) on the part it hit.
const STUMBLE_FROM := 0.8  ## m/s: slower than this he drops where he is
## How he folds round a ball in his front as he stumbles, reached in STUMBLE_FOLD_IN (degrees, the
## poses' axes; z toward the wound's side).
const STUMBLE_FOLD := {&"abdomen": Vector3(-20, 0, 8), &"chest": Vector3(-16, 0, 6), &"neck": Vector3(-6, 0, 0),
		&"head": Vector3(-10, 0, 0)}
const STUMBLE_FOLD_IN := 0.2
## Issue #446 (Sean, 2026-10-28: "if a guy is running and gets killed his body keeps moving"),
## on in the game since #471 (Sean on the films, #468: "Love em"): the stumble keeps his speed (it
## braked him to 0.6), and when something solid stands in his way within a step (a chair, a table,
## a rail, a banister, a wall) his legs go there and then, so he goes into it with all he had rather
## than being steered along it by `_slide` and dropping beside it. Nothing's added to him: the
## ragdoll keeps what he carried.
const KEEP_STRIDE_GAME := true
static var keep_stride := KEEP_STRIDE_GAME
## What's "in his way" (`_way_blocked`): a sphere this big at these heights over his feet (the
## seat of a chair or a table's top; a rail, a banister or a chair's back; low steps and the floor
## under neither), cast along his heading this far past his walking sphere: half a step at his
## speed, within these bounds (m). A whole step out (0.9 m at a run) his legs went under him short of
## a card table and he knelt into its foot with nothing left (Sean, 2026-10-28: "that table doesn't
## move or flip"); half a step, his trunk is still going when it meets it and the table goes over.
const STRIDE_PROBE_R := 0.2
const STRIDE_PROBE_UP := [0.6, 1.0]
const STRIDE_STEP_S := 0.12
const STRIDE_STEP_MIN := 0.2
const STRIDE_STEP_MAX := 0.45


func _knocked(seg: StringName, pos: Vector3, dir: Vector3, given: float) -> void:
	var s := String(seg)
	var leg := s.begins_with("thigh") or s.begins_with("shin")
	if move_speed > STUMBLE_FROM and gait in [&"walk", &"run"] and physiology.is_conscious() \
			and not seg in [&"head", &"neck"] and parts.has(seg):
		# About a step: a walk's ~0.6 s, a run's ~0.35 (cadence rises with speed); a shot leg
		# takes no more weight than it must.
		var t := (0.25 if leg else 0.7 / sqrt(move_speed)) * _rng.randf_range(0.8, 1.2)
		stumbling = t
		var chest := parts[&"chest"] as Node3D
		_stumble = {"seg": seg, "at": (parts[seg] as Node3D).global_transform.affine_inverse() * pos,
				"dir": dir, "given": given, "speed": move_speed, "time": t, "heading": -global_basis.z,
				"front": dir.dot(-global_basis.z) < 0.3 and not leg,
				"left": -signf((pos - chest.global_position).dot(chest.global_basis.x))}
		# No flinch back from the ball: his reaction is folding round it (STUMBLE_FOLD). The
		# standing man's flinch threw his chest back 45 degrees in a twentieth of a second (Sean:
		# "too quickly pushed back before falling"); even an eighth of it, 4 degrees, jumped his
		# head back in a single tick ("still too much of a super fast backwards jerk").
		return
	go_limp()
	var rb := parts.get(seg) as RigidBody3D
	if rb:
		rb.apply_impulse(dir * given, pos - rb.global_position)
	_hunch(seg, pos, dir)


func _stumble_on(delta: float) -> void:
	if _stumble.get("stagger", false):
		_stagger_on(delta)
		return
	stumbling -= delta
	var k := clampf(1.0 - stumbling / float(_stumble.time), 0.0, 1.0)
	# Folding round a wound in his front as he goes (at once: it's a flinch that stays); his stride
	# dying under him.
	if _stumble.front:
		var fold := clampf((float(_stumble.time) - stumbling) / STUMBLE_FOLD_IN, 0.0, 1.0)
		for sid: StringName in STUMBLE_FOLD:
			var d: Vector3 = STUMBLE_FOLD[sid]
			_stumble_lean[sid] = Vector3(d.x, 0.0, d.z * float(_stumble.left)) * fold
	var heading: Vector3 = _stumble.heading
	if keep_stride and _way_blocked(heading, float(_stumble.speed)):
		_fall_now()
		return
	_stumble.steering = true
	walk_to(global_position + heading * 2.0, float(_stumble.speed) * (1.0 if keep_stride else lerpf(1.0, 0.6, k)), delta)
	_stumble.steering = false
	if stumbling <= 0.0:
		_fall_now()


## Something solid ahead within a step (`keep_stride`): a chair, table, rail, banister or wall,
## not a man (he'd bowl into him standing) nor the walkers' ramps (Layers.WALK).
func _way_blocked(heading: Vector3, speed: float) -> bool:
	var dir := Vector3(heading.x, 0.0, heading.z)
	if dir.length() < 0.01:
		return false
	dir = dir.normalized()
	var reach := 0.26 - STRIDE_PROBE_R + clampf(speed * STRIDE_STEP_S, STRIDE_STEP_MIN, STRIDE_STEP_MAX)
	var space := World.space(self)
	var shape := SphereShape3D.new()
	shape.radius = STRIDE_PROBE_R
	var exclude: Array[RID] = []
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	for up: float in STRIDE_PROBE_UP:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * up)
		q.motion = dir * reach
		q.collision_mask = Layers.WORLD
		q.exclude = exclude
		Prof.count(&"q_walk")
		if space.cast_motion(q)[1] < 1.0:
			return true
	return false


func _fall_now() -> void:
	stumbling = 0.0
	_stumble_lean.clear()
	if limp or _stumble.is_empty():
		return
	var seg: StringName = _stumble.seg
	_legs_gone = true
	go_limp()
	var rb := parts.get(seg) as RigidBody3D
	if rb:
		var at := rb.global_transform * (_stumble.at as Vector3)
		rb.apply_impulse((_stumble.dir as Vector3) * float(_stumble.given), at - rb.global_position)
		_hunch(seg, at, _stumble.dir)
	_stumble.clear()


func _knocked_down(seg: StringName, deposited: float, severe: bool, pellet := false) -> bool:
	var s := String(seg)
	if not (seg in [&"chest", &"abdomen", &"pelvis", &"head", &"neck"] or s.begins_with("thigh")):
		return false
	var t := physiology.tuning
	var chance := maxf(deposited - t.knockdown_energy, 0.0) / 100.0 * t.knockdown_per_100j
	if severe:
		chance += t.knockdown_severe
	if pellet:
		# One pellet of a charge: each gets its own roll, so each counts for a share.
		chance *= t.knockdown_pellet_share
	return _rng.randf() < minf(chance, t.knockdown_max)


## A glass cut: a shard flying at `pos` along `dir` slices `depth` metres into whatever part it
## hits; `embedded` leaves the shard in the wound for the doctor.
func take_cut(collider: Node3D, pos: Vector3, dir: Vector3, depth: float, embedded := false) -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment", &"")
	if seg == &"":
		seg = segment_at(pos)
		collider = parts[seg]
	var xf := collider.global_transform
	var center := anatomy.segment_center(seg)
	var inv := xf.affine_inverse()
	var d := (inv.basis * dir).normalized()
	var o := inv * pos + center - d * 0.02
	var tr := anatomy.trace(seg, o, d, depth * 100.0 * anatomy.flesh_resistance, 0.002, _rng)
	tr.cut = true
	var bleeds := physiology.apply_trace(tr)
	var wound := {"segment": seg, "entry": tr.entry - center, "exit": null, "lodged": embedded,
			"stop": (tr.stop - center) if tr.stop != null else tr.entry - center,
			"hits": tr.hits.map(func(h: Dictionary) -> Dictionary: return {"id": h.id, "effect": h.effect}),
			"bleeds": bleeds, "garments": [], "stain": null, "kind": &"cut", "dir": d, "embedded": embedded}
	wounds.append(wound)
	_paint_wound(wound)
	_flinch_from(seg, pos, dir, 0.3)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": wound.hits,
			"position": pos, "direction": dir, "exit": null, "lodged": embedded, "kind": &"cut"}
	hit.emit(info)
	Events.body_hit.emit(info)
	return wound


## A knife (the gore lab; DiMaio's sharp-force wounds): a stab goes in narrow and deep along `dir`
## (`depth` metres of blade), cutting what it reaches but stopped by bone; a slash is drawn across
## him from `pos` along `along` for `length` metres, `depth` deep, and gapes, the skin and muscle
## pulled apart across its line. Returns the wound.
func take_knife(collider: Node3D, pos: Vector3, dir: Vector3, stab := true, depth := 0.1, along := Vector3.ZERO, length := 0.12) -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment", &"")
	if seg == &"":
		seg = segment_at(pos)
		collider = parts[seg]
	var xf := collider.global_transform
	var center := anatomy.segment_center(seg)
	var inv := xf.affine_inverse()
	var d := (inv.basis * dir).normalized()
	var per_m := 100.0 * anatomy.flesh_resistance
	var tr: Dictionary
	if stab:
		tr = anatomy.trace(seg, inv * pos + center - d * 0.02, d, depth * per_m, 0.004, _rng)
	else:
		# Down the line of the cut, a few blade-depths in from the skin.
		var a := (inv.basis * along).normalized()
		var start := inv * pos + center
		tr = {}
		for i in 5:
			var at: Vector3 = start + a * length * (float(i) / 4.0)
			var one := anatomy.trace(seg, at - d * 0.02, d, depth * per_m, 0.002, _rng)
			if tr.is_empty():
				tr = one
			else:
				for h: Dictionary in one.hits:
					if not tr.hits.any(func(x: Dictionary) -> bool: return x.id == h.id):
						tr.hits.append(h)
				tr.stop = one.entry
		tr.cut = true
		tr.track_cm = length * 100.0
	var bleeds := physiology.apply_trace(tr)
	var wound := {"segment": seg, "entry": tr.entry - center, "exit": null, "lodged": false,
			"stop": (tr.stop - center) if tr.stop != null else tr.entry - center,
			"hits": tr.hits.map(func(h: Dictionary) -> Dictionary: return {"id": h.id, "effect": h.effect}),
			"bleeds": bleeds, "garments": [], "stain": null, "kind": &"stab" if stab else &"slash", "dir": d}
	wounds.append(wound)
	_paint_wound(wound)
	if stab:
		open_wound(seg, tr.entry - center, 150.0, dir, &"")
	if not _knocked_down(seg, 0.0, false, false):
		_reach_for(wound)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": wound.hits,
			"position": pos, "direction": dir, "exit": null, "lodged": false, "kind": wound.kind}
	hit.emit(info)
	Events.body_hit.emit(info)
	return wound


## Something left standing in a wound: a shard of window glass, a splinter of wood off a blast,
## sticking out of him along the way it went in.
func _stuck_in(w: Dictionary, glass: bool) -> void:
	var vis: Node3D = visuals.get(w.segment)
	if vis == null:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Shard" if glass else "Splinter"
	var box := BoxMesh.new()
	var length := 0.03 + _chance(w.entry, 11) * 0.04
	box.size = Vector3(0.03, 0.004, length * 1.3) if glass else Vector3(0.006, 0.006, length * 1.6)
	mi.mesh = box
	var m := StandardMaterial3D.new()
	if glass:
		# Window glass seen edge-on is green; it catches the light.
		m.albedo_color = Color(0.72, 0.86, 0.8, 0.75)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.metallic_specular = 1.0
		m.rim_enabled = true
		m.rim = 0.6
	else:
		m.albedo_color = Color(0.55, 0.4, 0.26)
		m.roughness = 0.9
	mi.material_override = m
	mi.layers = Layers.VIS_BODY
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Half in him, half out, back along the way it came.
	var out := -(w.dir as Vector3).normalized()
	var b := _along(out)
	mi.basis = Basis(b.x, b.z, b.y) * Basis(Vector3.BACK, _spin(w.entry))
	mi.position = (w.entry as Vector3) + out * box.size.z * 0.3
	vis.add_child(mi)


## Burns on him (fire, a blast's flash): the bare skin facing it reddens, blisters and chars, and
## his clothes there scorch and burn onto him. `amount` as Physiology.burn takes it; `from` is
## where the heat came from (Vector3.INF: all round, a fire he's in).
const BURN_MARKS_MAX := 10
var _burn_marks := 0


func burn_marks(amount: float, from := Vector3.INF) -> void:
	if amount <= 0.0 or _burn_marks >= BURN_MARKS_MAX:
		return
	var n := clampi(int(ceil(amount * 3.0)), 1, BURN_MARKS_MAX - _burn_marks)
	var bare := [&"hand_r", &"hand_l", &"head", &"forearm_r", &"forearm_l", &"neck"]
	var clothed := [&"chest", &"abdomen", &"upper_arm_r", &"upper_arm_l", &"thigh_r", &"thigh_l"]
	for i in n:
		var pool: Array = bare if i % 2 == 0 else clothed
		var sid: StringName = pool[(_burn_marks + i * 3) % pool.size()]
		var part := parts.get(sid) as Node3D
		var vis: Node3D = visuals.get(sid)
		if part == null or vis == null:
			continue
		var toward := Vector3.FORWARD
		if from != Vector3.INF:
			toward = (part.global_basis.inverse() * (from - part.global_position)).normalized()
		var r := float(anatomy.segments[sid].radius)
		var local := toward * r + Vector3(0, (_chance(Vector3(i, 0, 0) + part.global_position, 13) - 0.5) * r, 0)
		var key := "burn" if pool == bare else "charred"
		var d := _decal(vis, sid, local, 0.07 if key == "burn" else 0.1, PixelArt.blood(key, 81, false, 32))
		d.name = "Burn"
		d.basis = d.basis * Basis(Vector3.UP, _spin(local + part.global_position))
	_burn_marks += n
	# Hair singes before skin burns (a flash scorches the hair, brows and lashes on the side toward
	# it: the burns literature's "singed nasal hair and eyebrows"): his hair at the temple facing it.
	if amount >= SINGE_AT and not _singed:
		var head := parts.get(&"head") as Node3D
		var vis: Node3D = visuals.get(&"head")
		if head and vis:
			_singed = true
			var toward := Vector3.FORWARD
			if from != Vector3.INF:
				toward = head.global_basis.inverse() * (from - head.global_position)
			toward.y = 0.0
			toward = toward.normalized() if toward.length() > 0.01 else Vector3.FORWARD
			var r := float(anatomy.segments[&"head"].radius)
			var d := _decal(vis, &"head", toward * r * 0.9 + Vector3(0, r * 0.45, 0), 0.11, PixelArt.blood("charred", 81, false, 32))
			d.name = "Singed"
			d.modulate = Color(0.55, 0.45, 0.4)

const SINGE_AT := 0.5
var _singed := false


## Hit by something heavy (falling timber, a fall): bruises, broken bones, a burst spleen or a
## cracked skull by the energy of it. A standing man hit hard enough goes down.
func take_blow(collider: Node3D, joules: float, point: Vector3, dir := Vector3.DOWN, momentum := -1.0) -> PackedStringArray:
	var seg: StringName = collider.get_meta(&"segment", &"") if collider else &""
	if seg == &"":
		seg = segment_at(point)
	var harm := physiology.blow(seg, joules, _rng)
	var part: Node3D = parts.get(seg)
	if part and joules > 20.0:
		var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(seg)
		var s: Dictionary = anatomy.segments[seg]
		# The bruise comes up on the skin nearest the blow.
		var c := anatomy.segment_center(seg)
		var axis_pt: Vector3 = s.a.lerp(s.b, clampf((local - s.a).dot(s.b - s.a) / maxf((s.b - s.a).length_squared(), 1e-6), 0.0, 1.0))
		var skin := axis_pt + (local - axis_pt).normalized() * float(s.radius) if (local - axis_pt).length() > 0.001 else axis_pt
		var bruise := _decal(visuals[seg], seg, skin - c, clampf(joules / 1500.0, 0.05, 0.18), PixelArt.blood("bruise", 29, false, 16))
		bruise.modulate = Color(0.35, 0.22, 0.4)
	# What the blow can give him: the momentum a piece of that weight leaves in a man of his when
	# they meet and move on together (p * M / (m + M), m from its energy and momentum: m = p^2/2E),
	# never more than it had. Unknown, as from a 20 kg piece with that energy.
	var p := momentum if momentum >= 0.0 else sqrt(2.0 * 20.0 * joules)
	var m := p * p / (2.0 * maxf(joules, 1e-3))
	var body := _body_mass()
	var given := p * body / (m + body)
	# It puts him down if it shoves him faster than a man can catch with a step (as a blast does:
	# BlastTuning.knockdown_speed); anything less, what it does to him (a knock on the head, a leg
	# broken) decides, as his physiology would (Sean, 2026-10-21: a fall comes from the injury).
	if not limp and given / body > Blast.t().knockdown_speed:
		go_limp()
		var rb := parts.get(seg) as RigidBody3D
		if rb:
			rb.apply_impulse(dir * given, point - rb.global_position)
		# Knocked off his feet, not hurt past knowing it: he throws out his arms (`brace`).
		brace()
	elif not limp:
		_flinch_from(seg, point, dir, joules * 0.002)
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": [], "position": point,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blow", "harm": harm, "joules": joules}
	hit.emit(info)
	Events.body_hit.emit(info)
	return harm


# --- Pushed: a shove, a kick ------------------------------------------------------------------

## Pushed by hands or a boot (PlayerShove; issue #479): `momentum` N*s given him at `point` along
## `dir` (the pusher works out how much: his arms' or leg's mass and speed), `joules` what the blow
## itself does to the part it lands on. More than he can catch with a step (`catch_speed`: the
## blast's knockdown speed, less on a hurt leg or in shock) and he goes over where he stands, turning
## about his feet (`_tip`). Less, and he staggers back with it, braking as his steps take it out
## (`_stagger_on`); whatever stops him on the way (a rail at his hip, a chair's seat behind his knees,
## a table, the top of a stair) he goes over, carrying what he had left. Already down, it moves the
## part it lands on. Returns &"down", &"stagger" or &"moved".
## The stagger's braking (m/s²): a shove's 0.7 m/s is taken out over about a step back, ~0.25 m in
## ~0.7 s (a man's backward recovery steps; numbers to try in experiments/kick_shove).
const STAGGER_BRAKE := 1.0
## ... below this (m/s) he's caught it.
const STAGGER_DONE := 0.05
## ... his feet dropping this far below where it began (m: under a stair's riser) and he's gone off
## the edge backwards: a man can't catch himself stepping back off a step he can't see.
const STAGGER_DROP := 0.12
## ... and his trunk rocked by it (degrees at his catch speed; the poses' axes: + x is back).
const STAGGER_LEAN := 14.0
## The least he can catch with a step however hurt (a share of the knockdown speed), and how much
## shock takes off it.
const CATCH_HURT_MIN := 0.3
const CATCH_SHOCK := 0.5


## How fast a push can move him and still be caught with a step (m/s).
func catch_speed() -> float:
	var p := physiology
	var legs := 1.0
	for side in ["r", "l"]:
		legs = minf(legs, p.muscle_strength("leg", side) * (1.0 - favouring(StringName("leg_" + side))))
	if not p.can_stand():
		legs = 0.0
	return Blast.t().knockdown_speed * lerpf(CATCH_HURT_MIN, 1.0, clampf(legs, 0.0, 1.0)) * (1.0 - CATCH_SHOCK * p.shock())


func take_push(point: Vector3, dir: Vector3, momentum: float, joules := 0.0, by: Node = null) -> StringName:
	var flat := Vector3(dir.x, 0.0, dir.z)
	dir = dir.normalized()
	var seg := segment_at(point)
	var harm := physiology.blow(seg, joules, _rng) if joules > 0.0 else PackedStringArray()
	if by != null:
		set_meta(&"last_hit_by", by)
	var result := &"moved"
	if limp:
		var rb := parts.get(seg) as RigidBody3D
		if rb:
			rb.apply_impulse(dir * momentum, point - rb.global_position)
			rb.sleeping = false
	else:
		var speed := momentum / _body_mass()
		var sat := String(pose).begins_with("sit")
		if speed > catch_speed() or prone or rising or flat.length() < 0.2:
			go_limp()
			_tip(dir, momentum, point)
			brace()
			result = &"down"
		elif sat:
			_flinch_from(seg, point, dir, momentum * 0.002)
		else:
			# A stagger is a stumble that ends on his feet (`_stagger_on`): brains leave him be the same.
			flat = flat.normalized()
			var local := global_basis.inverse() * flat
			stumbling = 10.0
			_stumble = {"stagger": true, "seg": seg, "at": (parts[seg] as Node3D).global_transform.affine_inverse() * point,
					"dir": flat, "given": 0.0, "speed": speed, "from_y": global_position.y,
					"lean": Vector3(local.z, 0.0, -local.x) * STAGGER_LEAN}
			result = &"stagger"
	var info := {"person": self, "person_id": person_id, "segment": seg, "hits": [], "position": point,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blow", "harm": harm, "joules": joules,
			"pushed": result, "momentum": momentum, "shooter": by}
	hit.emit(info)
	Events.body_hit.emit(info)
	return result


## Gone over from a push: he turns about his feet as a body does given `momentum` at `point` (the
## angular impulse about his feet over his moment of inertia there, each part by its own mass and
## height), on top of whatever he was doing. His feet stay where they are; the higher it lands, the
## more of it turns him and the less moves him.
func _tip(dir: Vector3, momentum: float, point: Vector3) -> void:
	var feet := global_position
	var axis := Vector3.UP.cross(Vector3(dir.x, 0.0, dir.z))
	var lever := maxf(point.y - feet.y, 0.1)
	var inertia := 0.0
	for rb: Variant in parts.values():
		if rb is RigidBody3D:
			var h := maxf((rb as RigidBody3D).global_position.y - feet.y, 0.0)
			inertia += (rb as RigidBody3D).mass * h * h
	if inertia < 1e-3 or axis.length() < 1e-3:
		var any := parts.get(&"chest") as RigidBody3D
		if any:
			any.apply_impulse(dir * momentum)
		return
	axis = axis.normalized()
	var w := momentum * lever / inertia
	for rb: Variant in parts.values():
		if rb is RigidBody3D:
			var body := rb as RigidBody3D
			var h := maxf(body.global_position.y - feet.y, 0.0)
			# v = w x r, r straight up from his feet: along the push, by height.
			body.linear_velocity += Vector3(dir.x, 0.0, dir.z).normalized() * w * h
			body.angular_velocity += axis * w
			body.sleeping = false


## Staggering back from a push (`take_push`): his feet carry him along it, slowing; something in
## his way or the ground gone from under his heels and he's over.
func _stagger_on(delta: float) -> void:
	var v := float(_stumble.speed)
	var dir: Vector3 = _stumble.dir
	var k := clampf(v / maxf(catch_speed(), 0.1), 0.0, 1.0)
	for sid: StringName in [&"abdomen", &"chest"]:
		_stumble_lean[sid] = (_stumble.lean as Vector3) * k * (0.4 if sid == &"abdomen" else 0.6)
	var way := _stagger_way(dir, v)
	if way == &"over" or float(_stumble.from_y) - global_position.y > STAGGER_DROP:
		_stagger_down()
		return
	var want := dir * v * delta if way == &"clear" else Vector3.ZERO
	var moved := _slide(want)
	_snap_to_ground()
	if way == &"stop" or (want.length() > 1e-4 and moved.length() < want.length() * 0.5):
		# Against something fixed at his hips or above (a rail, the bar, a wall): it stops him there,
		# on his feet.
		_stumble.speed = 0.0
	gait = &"walk"
	move_speed = moved.length() / maxf(delta, 1e-4)
	_moved_this_tick = true
	_stumble.speed = v - STAGGER_BRAKE * delta
	if float(_stumble.speed) <= STAGGER_DONE or limp:
		stumbling = 0.0
		_stumble.clear()
		_stumble_lean.clear()


## What's at his back as he staggers (within the step he's taking, as `_way_blocked` looks):
## &"clear"; &"over" if it'll take him over (low, under his hips: a chair's seat behind his knees, a
## stool, a step up behind his heels; or light enough to go with him, a kit prop under
## STAGGER_CARRIES of his weight: a chair, a card table); &"stop" if it's fixed at his hips or above
## (a rail, the bar, a wall, a heavy prop), which holds him up.
## A kit prop this many times his weight or more holds him; lighter, it goes with him.
const STAGGER_CARRIES := 3.0
## Over his feet (m): what's in his way at or above this is at his hips.
const STAGGER_HIPS := 0.85


func _stagger_way(heading: Vector3, speed: float) -> StringName:
	var dir := Vector3(heading.x, 0.0, heading.z).normalized()
	var reach := 0.26 - STRIDE_PROBE_R + clampf(speed * STRIDE_STEP_S, STRIDE_STEP_MIN, STRIDE_STEP_MAX)
	var space := World.space(self)
	var shape := SphereShape3D.new()
	shape.radius = STRIDE_PROBE_R
	var exclude: Array[RID] = []
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	var low := false
	for up: float in STRIDE_PROBE_UP:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = shape
		q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * up)
		q.motion = dir * reach
		q.collision_mask = Layers.WORLD
		q.exclude = exclude
		Prof.count(&"q_walk")
		var frac := space.cast_motion(q)
		if frac[1] >= 1.0:
			continue
		q.transform.origin += q.motion * frac[1]
		q.motion = Vector3.ZERO
		Prof.count(&"q_walk")
		var rest := space.get_rest_info(q)
		if rest.is_empty():
			continue
		var c := instance_from_id(rest.collider_id)
		var kit := (c as Node).get_parent() as KitProp if c is StructureMember else null
		if c is RigidBody3D or (kit != null and kit.mass() < STAGGER_CARRIES * _body_mass()):
			return &"over"
		if (rest.point as Vector3).y - global_position.y >= STAGGER_HIPS:
			return &"stop"
		low = true
	return &"over" if low else &"clear"


func _stagger_down() -> void:
	stumbling = 0.0
	_stumble.clear()
	_stumble_lean.clear()
	go_limp()
	brace()


## Which part of him is at a world point (for a standing man, by height and side).
func segment_at(point: Vector3) -> StringName:
	var best := &"chest"
	var best_d := INF
	for sid: StringName in parts:
		var part := parts[sid] as Node3D
		if part == null or not is_instance_valid(part):
			continue
		var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(sid)
		for c: Array in anatomy.segments[sid].capsules:
			var a: Vector3 = c[0]
			var ab: Vector3 = (c[1] as Vector3) - a
			var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var dist := local.distance_to(a + ab * t) - float(c[2])
			if dist < best_d:
				best_d = dist
				best = sid
	return best


## The normal of a segment's skin at a point (segment-local): from the capsule whose surface
## the point is on (the one it's least inside of).
func _skin_normal(seg: StringName, local: Vector3) -> Vector3:
	var center := anatomy.segment_center(seg)
	var best := -INF
	var normal := Vector3.UP
	for c: Array in anatomy.segments[seg].capsules:
		var a: Vector3 = (c[0] as Vector3) - center
		var ab: Vector3 = (c[1] as Vector3) - (c[0] as Vector3)
		var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		var n := local - (a + ab * t)
		var out: float = n.length() - float(c[2])
		if out > best and n.length() > 1e-5:
			best = out
			normal = n.normalized()
	return normal


func _paint_wound(w: Dictionary) -> void:
	var vis: Node3D = visuals[w.segment]
	var had := vis.get_child_count()
	_paint_wound_marks(w, vis)
	# What was laid on him for it, so it can go when it heals.
	var marks := []
	for i in range(had, vis.get_child_count()):
		if vis.get_child(i) is Decal:
			marks.append(vis.get_child(i))
	w.marks = marks


func _paint_wound_marks(w: Dictionary, vis: Node3D) -> void:
	var seed := wounds.size() * 13 + rng_seed
	if w.kind == &"graze" or w.kind == &"cut":
		# A furrow or a slice: a bloody line along the way it went, no hole.
		var a: Vector3 = w.entry
		var b: Vector3 = w.exit if w.exit != null else (w.stop if w.stop != null else a)
		var length := maxf(a.distance_to(b), 0.03 if w.kind == &"cut" else 0.05)
		var mid := (a + b) * 0.5
		var along: Vector3 = w.dir
		var line := _decal(vis, w.segment, mid, 0.02 if w.kind == &"graze" else 0.01, PixelArt.blood("furrow", 17, true, 16))
		var n := line.basis.y
		var z := (along - n * along.dot(n)).normalized()
		if z.length() > 0.1:
			line.basis = Basis(n.cross(z), n, z)
		line.size = Vector3(0.022 if w.kind == &"graze" else 0.009, 0.06, length)
		w.stain = _decal(vis, w.segment, mid, 0.03, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
		_add_jet(vis, w, mid, 1.0)
		if w.get("embedded", false):
			_stuck_in(w, true)
		return
	if w.kind == &"slash":
		# The knife's cut gapes along its line (the painted gash, laid lengthwise).
		var a: Vector3 = w.entry
		var b: Vector3 = w.stop
		var gash := _decal(vis, w.segment, (a + b) * 0.5, 0.03, PixelArt.blood("gore_gash" if not Settings.reduced_gore else "furrow", 19, true, 16))
		var n := gash.basis.y
		var z := (b - a) - n * (b - a).dot(n)
		if z.length() > 0.005:
			z = z.normalized()
			gash.basis = Basis(n.cross(z), n, z)
		gash.size = Vector3(0.035, 0.06, maxf(a.distance_to(b), 0.04) * 1.15)
		w.stain = _decal(vis, w.segment, (a + b) * 0.5, 0.04, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
		(w.stain as Node).add_to_group(&"blood_drying")
		_add_jet(vis, w, (a + b) * 0.5, 1.0)
		return
	var pellet := _small_wound(w.kind)
	if w.kind == &"stab":
		_decal(vis, w.segment, w.entry, 0.014, PixelArt.blood("furrow", 5, true, 16))
	else:
		_hole_mark(w, vis, w.entry, "wound_contact" if w.get("contact", false) else "wound_entry")
	if w.kind == &"splinter" and w.lodged:
		_stuck_in(w, false)
	elif pellet and w.lodged:
		# A pellet from further off lodges just under the skin: a dark lump round its hole.
		_decal(vis, w.segment, w.entry, 0.03, PixelArt.blood("bruise", 23, false, 16))
	if w.get("powder", 0.0) > 0.0:
		# Fired close: soot and burnt powder tattooed round the hole, wider and fainter the further
		# off (black powder's reaches about a metre: DiMaio).
		var spread: float = 0.04 + float(w.powder) * 0.16
		var soot := _decal(vis, w.segment, w.entry, spread, PixelArt.blood("powder", 29, false, 32))
		soot.modulate.a = clampf(1.0 - float(w.powder) / POWDER_RANGE * 0.7, 0.3, 1.0)
		if float(w.powder) < SCORCH_RANGE and not (w.get("garments", []) as Array).is_empty():
			# Closer still, the flash scorches the cloth round the hole.
			_decal(vis, w.segment, w.entry, 0.05, PixelArt.blood("scorched", 31, false, 32))
	w.stain = _decal(vis, w.segment, w.entry, 0.03 if pellet else 0.04, PixelArt.blood("stain%d" % (seed % 4), seed % 4, false, 32))
	(w.stain as Node).add_to_group(&"blood_drying")
	if w.exit != null:
		# A ball that flattened on bone tears a bigger hole out.
		_hole_mark(w, vis, w.exit, "wound_exit_torn" if w.get("flattened", false) else "wound_exit")
	# A split ball's other way out: half of it, a smaller hole.
	for i in range(1, (w.get("exits", []) as Array).size()):
		_hole_mark(w, vis, w.exits[i], "wound_exit", 0.7)
	var through: bool = w.exit != null
	_add_jet(vis, w, w.entry, 0.5 if through else 1.0)
	if through:
		_add_jet(vis, w, w.exit, 0.5)


## Buckshot and blast splinters: many small holes at once.
static func _small_wound(kind: StringName) -> bool:
	return kind == &"pellet" or kind == &"splinter" or kind == &"gravel"


func _add_jet(vis: Node3D, w: Dictionary, local: Vector3, share: float) -> void:
	if w.bleeds.is_empty():
		return
	if _small_wound(w.kind):
		# Buckshot holes close together bleed as one: a pellet's bleeding joins a nearby pellet
		# wound's stream rather than starting its own (nine jets from one shot is a fountain).
		for other: Node in vis.get_children():
			if other is BloodJet and other.has_meta(&"pellets") and (other as Node3D).position.distance_to(local) < PELLET_JET_MERGE:
				var j := other as BloodJet
				for id: int in w.bleeds:
					if not j.bleed_ids.has(id):
						j.bleed_ids.append(id)
				w.get_or_add("jets", []).append(j)
				return
	var jet := BloodJet.new()
	if _small_wound(w.kind):
		jet.set_meta(&"pellets", true)
		jet.bleed_ids = (w.bleeds as Array).duplicate()
	jet.name = "BloodJet"
	jet.body = self
	if not jet.has_meta(&"pellets"):
		jet.bleed_ids = w.bleeds
	jet.share = share
	jet.position = local
	jet.basis = _along(_skin_normal(w.segment, local))
	vis.add_child(jet)
	w.get_or_add("jets", []).append(jet)


## A bullet hole's painted mark (paint_blood.py "wounds3"), drawn so its hole is as wide as the
## forensic texts give it against the ball's own width (DiMaio, Gunshot Wounds; Knight's Forensic
## Pathology): an entry from a distance a little under it (the skin stretches and closes back,
## its thin scraped collar round that), a slow ball's exit a little over, one that flattened on
## bone about twice, a contact shot's star of tears two and a half times.
const HOLE_TO_BALL := {"wound_entry": 0.9, "wound_exit": 1.3, "wound_exit_torn": 2.2, "wound_contact": 2.5}
## How wide the hole is in each painted patch (its share of the patch, measured on run 112's cut
## textures: the dark hole of an entry or a contact wound, the torn region of an exit).
const HOLE_SHARE := {"wound_entry": 0.32, "wound_exit": 0.58, "wound_exit_torn": 0.69, "wound_contact": 0.45}
## A ball's radius when a wound doesn't say (the .45's, 11.4 mm across).
const BALL_RADIUS := 0.0057


func _hole_mark(w: Dictionary, vis: Node3D, at: Vector3, key: String, k := 1.0) -> Decal:
	var ball: float = 2.0 * float(w.get("radius", BALL_RADIUS))
	var size: float = ball * float(HOLE_TO_BALL[key]) * k / float(HOLE_SHARE[key])
	var d := _decal(vis, w.segment, at, size, PixelArt.blood(key, 9, true, 16))
	if key != "wound_entry" and key != "wound_contact":
		# (Exits aren't round: turned about the hole by where it is, never from his dice.)
		d.basis = d.basis * Basis(Vector3.UP, _spin(at))
	return d


func _decal(parent: Node3D, seg: StringName, local: Vector3, size: float, tex: Texture2D) -> Decal:
	var d := Decal.new()
	d.texture_albedo = tex
	d.cull_mask = Layers.VIS_BODY
	d.size = Vector3(size, 0.08, size)
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	var n := _skin_normal(seg, local)
	d.basis = _along(n)
	d.position = local
	parent.add_child(d)
	return d


## Blood soaks outward from each wound as it bleeds.
## Blood soaks out through cloth along the threads for minutes after it gets there (blood on cotton
## spread for 2-5 minutes, NIJ grant report 248671): the patch creeps out to what's bled, this many
## seconds to get most of the way.
const STAIN_WICK := 40.0
## What a wound's stain covers: the share of what it bleeds that soaks into his clothes (the rest
## runs off, drips and pools), spread at what shirting and wool hold, ~0.05 ml a cm2 (0.5 l a m2,
## as a film this deep; cotton takes up a few times its own weight: ~150 g/m2 shirting), and the
## widest it gets (his front, side to side: a big one runs onto his sleeves and trousers).
const STAIN_SOAK := 0.5
const STAIN_FILM := 0.0005
const STAIN_MAX := 0.75


func _update_stains(dt: float) -> void:
	var k := 1.0 - exp(-dt / STAIN_WICK)
	for w in wounds:
		var was: Variant = w.stain
		if was == null or not is_instance_valid(was):
			continue
		var stain := was as Decal
		var ml := physiology.blood_lost_from(w.bleeds)
		# Across the cloth it soaks into: its share of what's come out over the patch that holds it.
		var target := clampf(2.0 * sqrt(ml * STAIN_SOAK * 1e-6 / STAIN_FILM / PI), 0.04, STAIN_MAX)
		var s: float = w.get("stain_size", 0.04)
		s += (target - s) * k
		w.stain_size = s
		if not w.has("stain_at"):
			_stain_runs_down(w, stain)
		# Drawn out and set lower as it grows: blood runs down the cloth from the hole, it doesn't
		# climb (a neck wound's soaks the shirt front, not his jaw).
		stain.size = Vector3(s, 0.08 + s * 0.3, s * 1.25)
		stain.position = w.stain_at + stain.basis.z.normalized() * s * STAIN_RUN


## How far a stain's middle sits below its hole, in stain widths.
const STAIN_RUN := 0.4


## Turns a new stain so its long side runs down him as he stands when it starts (it keeps that way
## after: a soak doesn't move on the cloth when he falls).
func _stain_runs_down(w: Dictionary, stain: Decal) -> void:
	w.stain_at = stain.position
	var parent := stain.get_parent() as Node3D
	if parent == null or not parent.is_inside_tree():
		return
	var n := stain.basis.y.normalized()
	var down := parent.global_basis.inverse() * Vector3.DOWN
	var z := down - n * down.dot(n)
	if z.length() < 0.2:
		return  # the cloth lies flat: it spreads round the hole
	z = z.normalized()
	stain.basis = Basis(n.cross(z), n, z)


## A pool spreads on the ground under him while he lies bleeding.
## A mop over the pool under him: `share` of it taken up (it grows again while he bleeds).
func mop_pool(share: float) -> void:
	_pool_ml *= clampf(1.0 - share, 0.0, 1.0)
	if _pool == null:
		return
	if _pool_ml < 1.0:
		_pool.queue_free()
		_pool = null
		_pool_ml = 0.0
		return
	var r := clampf(sqrt(_pool_ml * 1e-6 / 0.002 / PI), 0.05, 1.1)
	_pool.size = Vector3(r * 2.0, 1.0, r * 2.0)


func _update_pool() -> void:
	if not physiology.alive and physiology.total_bleed_rate() < 0.01:
		return
	var rate := physiology.total_bleed_rate()
	if rate <= 0.05 and _pool == null:
		return
	_pool_ml += rate * get_physics_process_delta_time() * (_day_cycle.time_scale if _day_cycle else time_scale)
	var chest: Node3D = parts[&"abdomen"]
	if _pool == null:
		_pool = Decal.new()
		_pool.name = "BloodPool"
		_pool.texture_albedo = PixelArt.blood("pool", 21, false, 32)
		_pool.cull_mask = Layers.WORLD
		_pool.modulate = Color(0.75, 0.7, 0.7)
		_pool.top_level = true
		_pool.add_to_group(&"blood_drying")
		add_child(_pool)
	var r := clampf(sqrt(_pool_ml * 1e-6 / 0.002 / PI), 0.05, 1.1)
	_pool.global_position = Vector3(chest.global_position.x, chest.global_position.y, chest.global_position.z)
	_pool.global_rotation = Vector3.ZERO
	_pool.size = Vector3(r * 2.0, 1.0, r * 2.0)
	_soak_in_pool(r, get_physics_process_delta_time())


## Lying in his blood, his clothes take it up from below: each part of him resting in the pool gets
## a soak on its underside, growing with the pool, and it stays on the cloth if he's moved.
const POOL_SOAK_PARTS: Array[StringName] = [&"chest", &"abdomen", &"pelvis", &"neck", &"head",
		&"upper_arm_r", &"forearm_r", &"upper_arm_l", &"forearm_l", &"thigh_r", &"shin_r", &"thigh_l", &"shin_l"]
const POOL_SOAK_EVERY := 0.5  ## s between looks
const POOL_SOAK_REACH := 0.06  ## m: a part this close to the floor past its own radius lies in it
const POOL_SOAK_TRUNK_WIDE := 1.6  ## his trunk's half-width side to side, in its middle capsule's radii
const POOL_SOAK_LIMB_UP := 2.2  ## how high up a limb's cloth it reaches, in its radii (right round)
const POOL_SOAK_TRUNK_UP := 1.0  ## and up his trunk and head (to about the middle: a man on his back keeps a clean front and face)
var _pool_soaks := {}  ## segment -> its soak (Decal)
var _pool_soak_in := 0.0


func _soak_in_pool(r: float, dt: float) -> void:
	_pool_soak_in -= dt
	if _pool_soak_in > 0.0 or not (limp or prone) or _pool == null:
		return
	_pool_soak_in = POOL_SOAK_EVERY
	var centre := _pool.global_position
	var q := PhysicsRayQueryParameters3D.create(centre, centre + Vector3.DOWN * 0.6, Layers.WORLD)
	q.exclude = _own_rids()
	Prof.count(&"q_pool")
	var hit := World.space(self).intersect_ray(q)
	if hit.is_empty():
		return
	var floor_y: float = hit.position.y
	for sid in POOL_SOAK_PARTS:
		var part := parts.get(sid) as Node3D
		var vis := visuals.get(sid) as Node3D
		if part == null or vis == null or not anatomy.segments.has(sid):
			continue
		var rad := float(anatomy.segments[sid].radius)
		var p := part.global_position
		var flat := Vector2(p.x - centre.x, p.z - centre.z).length()
		var trunk := sid in [&"chest", &"abdomen", &"pelvis"]
		# The trunk is wider than its middle capsule (side to side): on his side it sits that much higher.
		if flat > r or p.y - floor_y > rad * (POOL_SOAK_TRUNK_WIDE if trunk else 1.0) + POOL_SOAK_REACH:
			continue
		# Wider the further into the pool it lies, up to its whole length; up its sides as cloth
		# wicks (a limb's sleeve or leg right round, the trunk to about its middle).
		var seg: Dictionary = anatomy.segments[sid]
		var length := ((seg.a as Vector3) - (seg.b as Vector3)).length() + rad * 2.0
		var size := clampf((r - flat) * 2.0 + rad, rad * 2.0, maxf(length, rad * 2.0))
		var up := rad * (POOL_SOAK_TRUNK_UP if trunk or sid in [&"neck", &"head"] else POOL_SOAK_LIMB_UP) + POOL_SOAK_REACH
		var d: Decal = _pool_soaks.get(sid)
		if d == null or not is_instance_valid(d):
			d = _decal(vis, sid, vis.to_local(Vector3(p.x, floor_y, p.z)), size, PixelArt.blood("pool1", 23, false, 32))
			d.modulate = Color(0.75, 0.68, 0.68)
			d.add_to_group(&"blood_drying")
			_pool_soaks[sid] = d
		# Only ever grows: the cloth stays soaked.
		d.size = Vector3(maxf(size, d.size.x), maxf(up * 2.0, d.size.y), maxf(size, d.size.z))


func sever_finger(fid: StringName, dir: Vector3) -> void:
	var knuckle: Node3D = fingers.get(fid)
	if knuckle == null:
		return
	fingers.erase(fid)
	var rb := RigidBody3D.new()
	rb.name = "Finger_%s" % fid
	rb.mass = 0.02
	rb.collision_layer = Layers.BODY_PARTS
	rb.collision_mask = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.018, 0.07, 0.018)
	shape.shape = box
	shape.position = Vector3(0, -0.035, 0)
	var world := get_parent()
	world.add_child(rb)
	rb.global_transform = knuckle.global_transform
	rb.add_child(shape)
	knuckle.reparent(rb, true)
	# A skinned hand hid the drawn finger: it's the one that flies.
	for mi in knuckle.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).visible = true
	rb.add_to_group(&"severed_parts")
	rb.apply_impulse(dir * 0.08 + Vector3(0, 0.05, 0))
	# The stump bleeds.
	_decal(visuals[&"hand_" + String(fid).right(1)], StringName("hand_" + String(fid).right(1)),
			knuckle.position, 0.03, PixelArt.blood("wound_entry", 5, true, 16))


## An ear or the nose shot off (the gore lab): the skin cut away where it was (the wound shader's
## opening, raw underneath), and the piece thrown off along the ball's way.
const PART_HOLE := {&"ear_r": 0.024, &"ear_l": 0.024, &"nose": 0.021}


func shoot_off(id: StringName, dir: Vector3) -> void:
	var st := anatomy.structure(id)
	if st.is_empty() or (_shot_off as Dictionary).has(id):
		return
	_shot_off[id] = true
	var center := anatomy.segment_center(&"head")
	var at: Vector3 = ((st.a as Vector3) + (st.b as Vector3)) * 0.5 - center
	# A hole of the part's size (open_wound's radius goes with the square root of its energy).
	var r: float = PART_HOLE.get(id, 0.02)
	# The torn root it leaves (tools/textures/paint_blood.py "face", by Gemini).
	var ear := String(id).begins_with("ear")
	open_wound(&"head", at, pow(r / OPEN_PER_SQRT_JOULE, 2.0) + 1.0, dir, &"ear_torn" if ear else &"nose_gone")
	var head := parts[&"head"] as Node3D
	var world := get_parent() as Node3D
	if world == null:
		return
	var rb := RigidBody3D.new()
	rb.name = "Ear" if ear else "Nose"
	rb.mass = 0.02
	rb.collision_layer = 0
	rb.collision_mask = Layers.WORLD
	var box := BoxShape3D.new()
	box.size = Vector3(0.012, 0.06, 0.035) if rb.name == "Ear" else Vector3(0.03, 0.04, 0.025)
	var shape := CollisionShape3D.new()
	shape.shape = box
	rb.add_child(shape)
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.5, 0.42)
	m.albedo_texture = PixelArt.blood("ear_piece" if ear else "wound_exit", 9, true, 16)
	if ear:
		m.albedo_color = Color.WHITE
	mi.material_override = m
	rb.add_child(mi)
	rb.add_to_group(&"severed_parts")
	world.add_child(rb)
	rb.global_position = head.global_transform * at
	rb.linear_velocity = dir.normalized() * 3.0 + Vector3.UP * 0.8
	rb.angular_velocity = Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-9, 9), _rng.randf_range(-9, 9))
	Blood.burst(world, rb.global_position, dir, 10, 2.0)
	Blood.throw(world, rb.global_position, dir * 2.0, 0.6, _own_rids())

var _shot_off := {}


## The lower jaw carried away (a heavy ball or buckshot close: what deposits this much in it). The
## Medical and Surgical History's "shot away" jaws: the chin and the jaw torn off, the bone thrown,
## no speech, blood running back into his throat, the face's arteries open.
const JAW_AWAY_J := 300.0


func jaw_away(dir: Vector3) -> void:
	if physiology.jaw_gone:
		return
	physiology.jaw_gone = true
	physiology.jaw_broken = true
	physiology.broken[&"jaw"] = true
	physiology.airway_blood = true
	physiology._add_bleed(&"facial_artery", &"head", 4.0, &"artery")
	var st := anatomy.structure(&"jaw")
	var center := anatomy.segment_center(&"head")
	var chin: Vector3 = ((st.a as Vector3) + (st.b as Vector3)) * 0.5 - center + Vector3(0, -0.012, -0.02)
	# Past DESTROY_ENERGY: the region torn away and the bone in it thrown out (_smash_bone).
	var o := open_wound(&"head", chin, DESTROY_ENERGY + 400.0, dir, &"jaw_gone")
	# The torn edge on what's left of his chin and cheeks, not up over his eyes.
	var edge: Variant = o.get("gore")
	if edge != null and is_instance_valid(edge):
		(edge as Decal).size *= 0.6
		(edge as Decal).position += Vector3(0, -0.02, 0)


func drop_gun() -> void:
	if held_gun == null:
		return
	_gun_shadow(true)
	var gun := held_gun
	held_gun = null
	var rb := RigidBody3D.new()
	rb.name = "DroppedGun"
	rb.mass = 1.1
	rb.collision_layer = Layers.DEBRIS
	rb.collision_mask = Layers.DEBRIS_MASK
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.04, 0.13, 0.3)
	shape.shape = box
	shape.position = Vector3(0, 0.0, -0.1)
	get_parent().add_child(rb)
	rb.global_transform = gun.global_transform
	rb.add_child(shape)
	gun.reparent(rb, true)
	rb.add_to_group(&"dropped_guns")
	curl_hand("r", 0.2)


# --- Falling -----------------------------------------------------------------------------------

## Let go: every segment becomes a rigid body joined to its parent, and physics takes over. Each
## part keeps the velocity it had (a running man falls on along his run); `push` is added to all
## of them (a blast's wind). A hit's own push goes on the part it hit, after (take_bullet).
func go_limp(push := Vector3.ZERO) -> void:
	if limp:
		return
	limp = true
	set_process(true)
	rising = false
	rise_ok = false
	_clip = null  # the ragdoll has him now: whatever he was playing, physics won
	_clip_w = 0.0
	_down_t = 0.0
	_still_t = 0.0
	var holding := {}
	if not _grab.is_empty():
		if tone_style == &"dying" and float(_grab.w) >= GRAB_PRESSES:
			holding = _grab.duplicate()  # he keeps it there as he goes (`_start_dying`)
		else:
			_hand_press(_grab.wound, false)  # his hand falls away from it as he goes
		_grab.clear()
	_impacts = BodyImpacts.new()
	var conscious := physiology.is_conscious()
	var joint_at := {}
	for sid: StringName in pivots:
		joint_at[sid] = (pivots[sid] as Node3D).global_position
	var bodies := {}
	for sid: StringName in anatomy.segments:
		var part: Node3D = parts[sid]
		var rb := RigidBody3D.new()
		rb.name = "Rag_%s" % sid
		# His parts collide with each other (Layers.RAGDOLL), his hands too: with the parts weighed
		# as a man's (MASS_SHARE) a hand resting on him settles; left out, it lay inside his thigh.
		rb.collision_layer = Layers.BODY_PARTS | Layers.RAGDOLL
		rb.collision_mask = Layers.WORLD | Layers.RAGDOLL
		rb.mass = part.get_meta(&"mass", 5.0)
		# The head and hands are small and land fast (he topples whole now): swept, so they stop
		# on the ground rather than in it.
		rb.continuous_cd = sid == &"head" or sid == &"hand_l" or sid == &"hand_r"
		rb.linear_damp = 0.2
		# Wrists and ankles: light ends on a joint that soft tissue damps; at 2 a hand or foot lying
		# still on the ground kept turning (~2 rad/s) and he never came to rest.
		rb.angular_damp = 6.0 if String(sid).begins_with("hand") or String(sid).begins_with("foot") else 2.0
		rb.set_meta(&"human_body", self)
		rb.set_meta(&"segment", sid)
		rb.set_meta(&"mass", rb.mass)
		var pm := PhysicsMaterial.new()
		pm.friction = 0.9
		pm.bounce = 0.0
		rb.physics_material_override = pm
		add_child(rb)
		# What he's thrown into (BodyImpacts): a railing breaks under him as under falling timber.
		_impacts.watch(rb)
		rb.global_transform = part.global_transform
		for c in part.get_children():
			# The new body isn't in the space until the physics server next steps: a ball flown this
			# tick (a blast's gravel, the rest of a charge) would pass through him. The standing part
			# keeps a copy of its shapes until it's freed with the rig (experiments/body_lab, same_tick).
			if c is CollisionShape3D:
				part.add_child(c.duplicate())
			c.reparent(rb, true)
		bodies[sid] = rb
		parts[sid] = rb
	_scale_inertia(bodies)
	for sid: StringName in anatomy.segments:
		var parent: StringName = anatomy.segments[sid].parent
		if parent == &"":
			continue
		var key0 := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		if key0 == &"shin" or key0 == &"forearm":
			_hinge(sid, parent, bodies, joint_at[sid])
			continue
		var j := ConeTwistJoint3D.new()
		j.name = "Joint_%s" % sid
		add_child(j)
		var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		var lim: Array = JOINT_LIMITS.get(key, [30, 10])
		var child := bodies[sid] as RigidBody3D
		var now := child.global_transform
		var span := float(lim[0])
		if CONE_CENTRE.has(key):
			# Centred on the joint's anatomical middle, not the pose he went limp in: the child is
			# set there about the pivot for the moment the joint is made (Godot takes both frames
			# from where the bodies are), and put back. The span takes in his pose if it's outside.
			var c: Array = CONE_CENTRE[key]
			var pb := (bodies[parent] as Node3D).global_basis.orthonormalized()
			var centre := pb * Basis(Vector3.RIGHT, deg_to_rad(float(c[0])))
			var pivot: Vector3 = joint_at[sid]
			var local: Vector3 = now.basis.orthonormalized().inverse() * (now.origin - pivot)
			var dir_now: Vector3 = now.origin - pivot
			var dir_centre: Vector3 = centre * local
			span = maxf(float(c[1]), rad_to_deg(dir_now.angle_to(dir_centre)) + 3.0)
			cone_frames[sid] = {"centre": pb.inverse() * dir_centre.normalized(), "span": span,
					"turn": Quaternion(Vector3.RIGHT, deg_to_rad(float(c[0]))), "axis": local.normalized()}
			child.global_transform = Transform3D(centre, pivot + dir_centre)
		var child_dir: Vector3 = child.global_position - joint_at[sid]
		var basis := _along(child_dir)
		j.global_transform = Transform3D(Basis(basis.y, basis.z, basis.x), joint_at[sid])
		j.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(span))
		j.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(lim[1]))
		j.node_a = j.get_path_to(bodies[parent])
		j.node_b = j.get_path_to(child)
		child.global_transform = now
	_keep_apart(bodies)
	_start_tone(bodies, conscious, joint_at)
	_start_dying(holding, joint_at)
	# Each part goes on as it was moving (walking, running, flinching), plus `push`: a blast's
	# wind, the same on all of him. Nothing scripted on top (there was a shove of the chest and a
	# random kick: experiments/physics_lab/README.md, baseline).
	# His legs go on at his hips' speed and the foot he stands on stays put: the procedural gait's
	# swing isn't a real stride (it floats the stance foot and skates the other along the ground
	# at 5-7 m/s), and handed to the fall it threw his legs out ahead and sat him down. A real
	# stance foot is still, and that leg turns about it. What the ground takes is the stance leg's
	# share and the gait's swing: a runner at 3.5 m/s keeps 93% (279 -> 260 N*s), and the rest of
	# him all of his. Real strides will come with mocap.
	var space := World.space(self)
	var carry := _carry_velocities()
	var carry_v: Dictionary = carry[0]
	var carry_w: Dictionary = carry[1]
	var hips: Vector3 = carry_v.get(&"pelvis", Vector3.ZERO)
	var side := _stance_side(bodies)
	var foot: RigidBody3D = bodies.get(StringName("foot" + side))
	var planted := foot != null and _on_ground(space, foot)
	var hip_y: float = (bodies[&"pelvis"] as Node3D).global_position.y if bodies.has(&"pelvis") else 1.0
	# The stance leg turns as one about its ankle, carrying the hips at their speed: v = w x r with
	# r straight up from the ankle, so w = up x v / height.
	var leg_h := maxf(hip_y - foot.global_position.y, 0.1) if planted else 1.0
	var hips_flat := Vector3(hips.x, 0.0, hips.z)
	var leg_w := Vector3.UP.cross(hips_flat) / leg_h
	for sid: StringName in bodies:
		var rb: RigidBody3D = bodies[sid]
		var v: Vector3 = (carry_v.get(sid, Vector3.ZERO) as Vector3)
		var w: Vector3 = carry_w.get(sid, Vector3.ZERO)
		var leg := String(sid).begins_with("thigh") or String(sid).begins_with("shin") or String(sid).begins_with("foot")
		if leg:
			v = hips
			w = Vector3.ZERO
			if planted and String(sid).ends_with(side):
				var up := clampf((rb.global_position.y - foot.global_position.y) / leg_h, 0.0, 1.0)
				v = hips_flat * up + Vector3(0.0, minf(hips.y, 0.0), 0.0)
				w = leg_w
		rb.linear_velocity = v + push
		rb.angular_velocity = w
	_rig.queue_free()
	pivots.clear()
	_blocker.queue_free()
	fell.emit(conscious)
	Events.person_fell.emit(self, conscious)


## The light links' inertia, scaled up this many times (their mass is left as it is): a third-of-a-
## kilo hand, a 1 kg neck between a 17 kg chest and a 5.5 kg head and a 1.2 kg foot are too light for
## Jolt to hold on their joints as the heavy parts land: the head and neck swung 15-19 deg past
## their limits, the feet 17 (experiments/physics_lab, 2026-10-21). A common ragdoll practice
## (raising small bodies' inertia for joint stability, as PhysX's articulation guidance has it); it
## slows their own turning a little, not his fall.
const INERTIA_SCALE := {&"neck": 4.0, &"hand": 3.0, &"foot": 3.0}


func _scale_inertia(bodies: Dictionary) -> void:
	for sid: StringName in bodies:
		var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		if not INERTIA_SCALE.has(key):
			continue
		var rb: RigidBody3D = bodies[sid]
		var st := PhysicsServer3D.body_get_direct_state(rb.get_rid())
		if st == null:
			continue
		var inv := st.inverse_inertia
		rb.inertia = Vector3(1.0 / maxf(inv.x, 1e-9), 1.0 / maxf(inv.y, 1e-9), 1.0 / maxf(inv.z, 1e-9)) * float(INERTIA_SCALE[key])


## His own parts collide (Layers.RAGDOLL), but not a part and its parent, two parts on one
## joint, or any pair already touching as he goes limp (a crouch's chest on his thighs): Jolt
## would throw those apart.
## A pair only resting on each other (a hand on his thigh, a forearm against his chest) collides as
## any other: left out, sat at a table his forearm went on into his chest as he went down
## (experiments/physics_lab, M_seated_ball, 2026-10-21). One sunk deeper into the other than Jolt
## can ease apart (a crouch's chest on his thighs) is left out until they've come apart.
func _keep_apart(bodies: Dictionary) -> void:
	_apart.clear()
	var ids: Array = bodies.keys()
	for i in ids.size():
		for k in range(i + 1, ids.size()):
			var a: StringName = ids[i]
			var b: StringName = ids[k]
			var pa: StringName = anatomy.segments[a].parent
			var pb: StringName = anatomy.segments[b].parent
			if pa == b or pb == a or (pa != &"" and pa == pb):
				(bodies[a] as RigidBody3D).add_collision_exception_with(bodies[b])
			else:
				var deep := _overlap_depth(bodies[a], bodies[b])
				if deep > TOUCH_DEEP:
					(bodies[a] as RigidBody3D).add_collision_exception_with(bodies[b])
					_apart.append([bodies[a], bodies[b], deep])


var _apart: Array = []  ## [RigidBody3D, RigidBody3D, depth as he went]: left out for now


## A pair left out collides again once it's come apart, or as soon as it sinks further into itself
## than it began (by TOUCH_SINK: Jolt eases that much back out gently).
func _rejoin_apart() -> void:
	for i in range(_apart.size() - 1, -1, -1):
		var a := _apart[i][0] as RigidBody3D
		var b := _apart[i][1] as RigidBody3D
		if not is_instance_valid(a) or not is_instance_valid(b):
			_apart.remove_at(i)
			continue
		var deep := _overlap_depth(a, b)
		if deep < -TOUCH_SLACK or deep > float(_apart[i][2]) + TOUCH_SINK:
			a.remove_collision_exception_with(b)
			_apart.remove_at(i)


## How deep two parts' capsules are in each other (m; negative: the gap between them).
func _overlap_depth(a: RigidBody3D, b: RigidBody3D) -> float:
	var best := -INF
	for ca in a.get_children():
		if not (ca is CollisionShape3D and (ca as CollisionShape3D).shape is CapsuleShape3D):
			continue
		for cb in b.get_children():
			if not (cb is CollisionShape3D and (cb as CollisionShape3D).shape is CapsuleShape3D):
				continue
			var sa := (ca as CollisionShape3D).shape as CapsuleShape3D
			var sb := (cb as CollisionShape3D).shape as CapsuleShape3D
			var xa := a.global_transform * (ca as CollisionShape3D).transform
			var xb := b.global_transform * (cb as CollisionShape3D).transform
			var ha := sa.height * 0.5 - sa.radius
			var hb := sb.height * 0.5 - sb.radius
			var pts := Geometry3D.get_closest_points_between_segments(xa * Vector3(0, -ha, 0), xa * Vector3(0, ha, 0),
					xb * Vector3(0, -hb, 0), xb * Vector3(0, hb, 0))
			best = maxf(best, sa.radius + sb.radius - pts[0].distance_to(pts[1]))
	return best


## Muscle tone as he goes: each joint is held toward the pose he went limp in, the hold fading
## away over TONE_FADE seconds, so he crumples and topples rather than folding flat at the knees
## like a puppet with its strings cut (experiments/physics_lab, fault 1). Stiffness per joint in
## N*m/rad at full tone, about what holds that joint's share of him up; a man still conscious
## keeps more of it a little longer. Tunable in TONE.
const TONE := {
	&"abdomen": 130.0, &"chest": 110.0, &"neck": 60.0, &"head": 30.0,
	&"upper_arm": 30.0, &"forearm": 15.0, &"hand": 3.0,
	&"thigh": 160.0, &"shin": 100.0, &"foot": 60.0,
}
const TONE_START := 0.55
const TONE_START_CONSCIOUS := 0.7
const TONE_FADE := 0.35
const TONE_FADE_CONSCIOUS := 0.6
## Killed outright (a ball through the brain): his tone goes in this long.
const TONE_FADE_DEAD := 0.15
## ... and for that moment the leg he stands on holds this many times harder: a man's weight on a
## near-straight leg is carried down the bones, not by the muscle, so the planted leg props him up
## for an instant and a runner pitches forward over it. Without it, killed running, his knees
## folded on the first tick: he dropped into a kneel and slid on it (experiments/physics_lab,
## group J, 2026-10-16).
const TONE_STANCE := 6.0
## A foot this much higher than the other is off the ground: he's on one leg (a walk's swing foot
## clears it by 2-3 cm).
const SINGLE_SUPPORT := 0.015
## His knees' share of their tone when a stumble ends in his legs going (they buckle first).
const LEGS_GONE := 0.3
const TONE_UNTIL := 1.5
## Damping: seconds' worth of the stiffness, on the joint's relative spin.
const TONE_DAMP := 0.06
const TOUCH_SLACK := 0.01
## Sunk this far into each other as he goes, a pair is left out (Jolt would throw them apart) ...
const TOUCH_DEEP := 0.015
## ... until it's sunk this much further.
const TOUCH_SINK := 0.02
## The most of a part's inertia a step's tone may act on (explicit springs go unstable past ~1).
const TONE_STEP_SHARE := 0.25


## How hard the pair is to turn against each other about `axis` through the joint at `joint`
## (kg*m^2): each part's inertia about that axis through the joint (its own about its centre, plus
## its mass times its centre's distance from the axis squared), the two in series. 0 until the
## physics knows them (or with no axis). Taken about each part's own centre, as it once was, a
## thigh read an eighth of what swinging it at the hip is: the cap held the hips to a fifth of
## their tone and, with the parts weighed as a man's, he folded double.
func _tone_inertia(a: RigidBody3D, b: RigidBody3D, axis: Vector3, joint: Vector3) -> float:
	if axis.length_squared() < 0.5:
		return 0.0
	var inv := 0.0
	for rb in [a, b]:
		var st := PhysicsServer3D.body_get_direct_state((rb as RigidBody3D).get_rid())
		if st == null or st.inverse_mass <= 0.0:
			return 0.0
		var i_com := 1.0 / maxf(axis.dot(st.inverse_inertia_tensor * axis), 1e-9)
		var arm := (st.transform.origin + st.center_of_mass - joint).cross(axis)
		inv += 1.0 / (i_com + arm.length_squared() / st.inverse_mass)
	return 1.0 / inv if inv > 0.0 else 0.0

var _tone: Array = []  ## [child, parent, rest rotation (child in parent), stiffness, joint (in child)]
var _tone_t := 0.0
var _tone_start := 0.0
var _tone_fade := 1.0

## How his tone lets go (experiments/physics_lab `tone`, issue #442; Sean, 2026-10-27: "I don't want
## people flying around but I don't want every death to be a drop dead rag doll"). "": all of him at
## once, TONE_FADE (the game's). &"fade": a region at a time, each holding a moment and then going
## over its own time, in a dying man's order: his legs first (he buckles and goes down onto a knee),
## his trunk and neck after (he folds as he goes), his arms last. No more force than before: the
## same stiffness for longer, toward the pose he went in. &"dying": the fade, and what he still does
## as he goes (`_start_dying`). The game's was `dying` for a build (2668) and is "" again (Sean,
## 2026-10-28, on the videos: "I like the before more - the bodies tended to move a bit more and fall
## into shit and down stairs": the fade folds him where he stands). The lab's `--tone=` tries them.
const TONE_GAME := &""
static var tone_style := TONE_GAME
## Each region's [hold from, hold to, fade from, fade to] (s): drawn per man (his own seed), the
## hold at full TONE_START, then a smooth fall to nothing over the fade.
const TONE_REGIONS := {
	&"legs": [0.02, 0.08, 0.3, 0.5],
	&"trunk": [0.15, 0.3, 0.6, 1.0],
	&"neck": [0.2, 0.35, 0.7, 1.1],
	&"arms": [0.3, 0.5, 0.9, 1.4],
}
## One leg gives before the other by this much (s, drawn): he goes onto one knee and over that
## side, not down into an even squat (experiments/physics_lab/results/2026-10-21_faint: the judges'
## shared fault was "every joint at once, both legs alike").
const TONE_LEG_LAG := [0.15, 0.35]
## ... and the first one buckles: its knee and hip pulled this far into a bend (degrees, the poses'
## axes, as FAVOUR_LEG) as it goes, the other's this share of it. A standing man's knees are near
## straight and carry him on the bone: let go evenly, he stood like a post for half a second and
## then sank into a squat (the faint's judges: "a controlled crouch, not legs giving way").
const TONE_BUCKLE := {&"thigh": Vector3(18, 0, 0), &"shin": Vector3(-40, 0, 0)}
const TONE_BUCKLE_OTHER := 0.35
## Now and then (this share of men) his trunk goes before his legs: he folds at the waist first.
const TONE_TRUNK_FIRST := 0.2
## Each man's stiffness, this much either side of TONE's.
const TONE_SPREAD := 0.15
## Killed outright, every region's times are this share (he still doesn't drop like a sack); awake,
## this many times longer (he fights it).
const TONE_DEAD_SCALE := 0.45
const TONE_CONSCIOUS_SCALE := 1.3
## The leg he stands on as a post (TONE_STANCE): only for this instant, smoothly, whatever the style.
const TONE_POST_FADE := 0.35
var _tone_when: Array = []  ## per _tone entry: Vector2(hold, fade) (s) under &"fade"
var _tone_index := {}  ## segment -> its _tone entry
var _tone_buckle := {}  ## _tone entry -> the buckle laid on its target (TONE_BUCKLE)
var _tone_until := TONE_UNTIL


func _start_tone(bodies: Dictionary, conscious: bool, joint_at: Dictionary) -> void:
	_tone.clear()
	_tone_t = 0.0
	var dead := not physiology.alive
	# Killed outright he keeps his tone for an instant too (muscle doesn't go slack the moment the
	# brain does). Dead, or alive on one foot, the leg he stands on holds like a post for it:
	# TONE_STANCE (see there).
	_tone_start = TONE_START if dead else (TONE_START_CONSCIOUS if conscious else TONE_START)
	_tone_fade = TONE_FADE_DEAD if dead else (TONE_FADE_CONSCIOUS if conscious else TONE_FADE)
	if _tone_start <= 0.0:
		return
	var stance := _stance_side(bodies)
	# The column: dead, or on one foot (walking, running: the other's lifted, even a couple of
	# centimetres; standing, both legs share him).
	var column := dead
	if bodies.has(&"foot_l") and bodies.has(&"foot_r"):
		column = column or absf((bodies[&"foot_l"] as Node3D).global_position.y - (bodies[&"foot_r"] as Node3D).global_position.y) > SINGLE_SUPPORT
	# At the end of a stumble his legs are what gave: they fold first.
	column = column and not _legs_gone
	_tone_when.clear()
	_tone_index.clear()
	_tone_buckle.clear()
	_tone_until = TONE_UNTIL
	var when := _tone_regions(dead, conscious) if tone_style in [&"fade", &"dying"] else {}
	for sid: StringName in bodies:
		var parent: StringName = anatomy.segments[sid].parent
		if parent == &"":
			continue
		var child := bodies[sid] as RigidBody3D
		var up := bodies[parent] as RigidBody3D
		var rest := (up.global_basis.orthonormalized().inverse() * child.global_basis.orthonormalized()).get_rotation_quaternion()
		var key := StringName(String(sid).trim_suffix("_r").trim_suffix("_l"))
		var k := float(TONE.get(key, 30.0))
		var post := column and String(sid).ends_with(stance) and (key == &"shin" or key == &"thigh")
		if post:
			k *= TONE_STANCE
		elif _legs_gone and key == &"shin":
			k *= LEGS_GONE
		_tone_index[sid] = _tone.size()
		_tone.append([child, up, rest, k * float(when.get(&"stiff", 1.0)), child.global_transform.affine_inverse() * (joint_at[sid] as Vector3)])
		if not when.is_empty():
			if not post and not column and not _legs_gone and TONE_BUCKLE.has(key):
				var d: Vector3 = TONE_BUCKLE[key] * (1.0 if String(sid).ends_with(String(when[&"first"])) else TONE_BUCKLE_OTHER)
				var last: Array = _tone[-1]
				var q := Basis.from_euler(d * (PI / 180.0)).get_rotation_quaternion()
				last[2] = q * (last[2] as Quaternion)
				_tone_buckle[_tone.size() - 1] = q
			var w: Vector2 = Vector2(0.0, TONE_POST_FADE) if post else when.get(sid, when.get(_tone_region(key), Vector2(0.0, TONE_FADE)))
			_tone_when.append(w)
			_tone_until = maxf(_tone_until, w.x + w.y)


static func _tone_region(key: StringName) -> StringName:
	match key:
		&"thigh", &"shin", &"foot":
			return &"legs"
		&"abdomen", &"chest":
			return &"trunk"
		&"neck", &"head":
			return &"neck"
	return &"arms"


## This man's way of letting go (&"fade"): each region's Vector2(hold, fade) drawn from his own seed
## (the same man goes the same way every time; nothing else's draws move), each leg its own, and
## "stiff" his share of TONE.
func _tone_regions(dead: bool, conscious: bool) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash(["tone", rng_seed])
	var scale := TONE_DEAD_SCALE if dead else (TONE_CONSCIOUS_SCALE if conscious else 1.0)
	var out := {&"stiff": r.randf_range(1.0 - TONE_SPREAD, 1.0 + TONE_SPREAD)}
	for region: StringName in TONE_REGIONS:
		var t: Array = TONE_REGIONS[region]
		out[region] = Vector2(r.randf_range(t[0], t[1]), r.randf_range(t[2], t[3])) * scale
	if r.randf() < TONE_TRUNK_FIRST:
		var legs: Vector2 = out[&"legs"]
		out[&"legs"] = out[&"trunk"]
		out[&"trunk"] = legs
	# One leg first: which, and by how much.
	var first := "_r" if r.randf() < 0.5 else "_l"
	out[&"first"] = first
	var lag := r.randf_range(TONE_LEG_LAG[0], TONE_LEG_LAG[1]) * scale
	var legs_now: Vector2 = out[&"legs"]
	if _legs_gone:
		# At the end of a stumble his legs are what gave: both go now, at once.
		legs_now = Vector2(0.0, legs_now.y / scale)
		lag = 0.0
	for side in ["_r", "_l"]:
		var w := legs_now if side == first else legs_now + Vector2(lag, 0.0)
		for part in ["thigh", "shin", "foot"]:
			out[StringName(part + side)] = w
	return out


## Hit and going down alive: his muscles pull him round the wound for the moment they still hold
## (the tone's target, not a push: they're his own forces, so he's no faster for it). A ball in the
## belly or chest doubles him over and bends him toward it; one in the back arches him away from
## it; a leg hit gives way under him. Dead, he does none of it. Degrees from the pose he went down
## in (the poses' sign: forward is -x, his left +z).
const HUNCH := {&"abdomen": Vector3(-22, 0, 10), &"chest": Vector3(-18, 0, 8), &"neck": Vector3(-10, 0, 0),
		&"head": Vector3(-8, 0, 0)}
const HUNCH_BACK := {&"abdomen": Vector3(6, 0, 8), &"chest": Vector3(5, 0, 6), &"neck": Vector3(4, 0, 0),
		&"head": Vector3(6, 0, 0)}


func _hunch(seg: StringName, at: Vector3, dir: Vector3) -> void:
	if _tone.is_empty() or not physiology.alive:
		return
	_dying_wound(seg, at)
	var s := String(seg)
	if s.begins_with("thigh") or s.begins_with("shin"):
		var side := s.right(2)
		for j: Array in _tone:
			var sid := String((j[0] as Node).get_meta(&"segment", &""))
			if sid == "thigh" + side or sid == "shin" + side:
				j[3] = 0.0
		_shot_leg_first(side)
		return
	if not seg in [&"chest", &"abdomen", &"pelvis"]:
		return
	# Toward the wound's side: + bends him to his left (the sign of the poses' z).
	var chest := parts[&"chest"] as Node3D
	var left := -signf((at - chest.global_position).dot(chest.global_basis.x))
	# From behind: the ball going the way he faces (his front is -z).
	var shape: Dictionary = HUNCH_BACK if dir.dot(-chest.global_basis.z) > 0.3 else HUNCH
	for j: Array in _tone:
		var sid: StringName = (j[0] as Node).get_meta(&"segment", &"")
		if not shape.has(sid):
			continue
		var d: Vector3 = shape[sid]
		var bend := Basis.from_euler(Vector3(deg_to_rad(d.x), 0.0, deg_to_rad(d.z * left)))
		j[2] = bend.get_rotation_quaternion() * (j[2] as Quaternion)


## The fade's legs (`_start_tone`), when a leg is shot: that one is the leg that goes, so the other
## loses its buckle and holds the longer of the two legs' times.
func _shot_leg_first(side: String) -> void:
	if _tone_when.size() != _tone.size():
		return
	var other := "_l" if side == "_r" else "_r"
	var later := Vector2.ZERO
	for part in ["thigh", "shin", "foot"]:
		for sd in [side, other]:
			var i: int = _tone_index.get(StringName(part + sd), -1)
			if i >= 0:
				var w: Vector2 = _tone_when[i]
				if w.x + w.y > later.x + later.y:
					later = w
	for part in ["thigh", "shin", "foot"]:
		var i: int = _tone_index.get(StringName(part + other), -1)
		if i < 0:
			continue
		if _tone_buckle.has(i):
			var j: Array = _tone[i]
			j[2] = (_tone_buckle[i] as Quaternion).inverse() * (j[2] as Quaternion)
			_tone_buckle.erase(i)
		_tone_when[i] = later


## Awake and going over with nothing hurting him (his chair gone from under him, a shove): his arms
## go out and his chin tucks in, for the moment his muscles still answer him (Sean, 2026-10-22; the
## chair's blind critic: "a man taken by surprise would flail, grab the seat, tuck his chin"). The
## protective reactions of a fall: thrown backwards, the arms fling forward and out (the
## counterbalance) and the chin tucks to spare the back of the head; pitched forward, the arms reach
## ahead to take the ground and the head comes up. Tone targets, as `_hunch`: the pose his joints
## are pulled toward, held BRACE_TONE times harder and fading over BRACE_FADE, not a push. Degrees
## as the poses' (forward is -x for the trunk and neck, +x for an arm; + z takes his right arm out).
const BRACE_BACK := {&"upper_arm": Vector3(55, 0, 60), &"forearm": Vector3(25, 0, 0),
		&"neck": Vector3(-25, 0, 0), &"head": Vector3(-15, 0, 0)}
const BRACE_FRONT := {&"upper_arm": Vector3(80, 0, 18), &"forearm": Vector3(15, 0, 0),
		&"neck": Vector3(15, 0, 0), &"head": Vector3(10, 0, 0)}
## ... and his trunk curls a little toward his knees as he goes back (degrees added to its pose).
const BRACE_CURL := {&"abdomen": Vector3(-8, 0, 0), &"chest": Vector3(-8, 0, 0)}
const BRACE_TONE := 2.5
const BRACE_FADE := 0.9
## He reads which way he's going this soon after he loses his footing (s), or as soon after that
## as his chest is moving this fast (m/s), giving up after BRACE_WAIT.
const BRACE_AFTER := 0.05
const BRACE_SPEED := 0.15
const BRACE_WAIT := 0.4
var _brace_t := -1.0


## Brace for the fall he's starting (call as or after he goes limp; asleep, dead or already down,
## nothing).
func brace() -> void:
	if not limp or not physiology.alive or not physiology.is_conscious() or _tone.is_empty():
		return
	_brace_t = 0.0
	# Not hurt past knowing it: he'll get up again once he's still (`get_up`).
	rise_ok = true


func _step_brace(delta: float) -> void:
	if _brace_t < 0.0:
		return
	_brace_t += delta
	var chest := parts.get(&"chest") as RigidBody3D
	if chest == null or not is_instance_valid(chest) or _tone.is_empty():
		_brace_t = -1.0
		return
	var v := chest.linear_velocity
	v.y = 0.0
	if _brace_t < BRACE_AFTER or (v.length() < BRACE_SPEED and _brace_t < BRACE_WAIT):
		return
	_brace_t = -1.0
	# Which way he's going, against the way his chest faces (its front is -z).
	var front := -chest.global_basis.z
	front.y = 0.0
	var back := v.length() < BRACE_SPEED or v.dot(front) <= 0.0
	var shape: Dictionary = BRACE_BACK if back else BRACE_FRONT
	for j: Array in _tone:
		var sid := String((j[0] as Node).get_meta(&"segment", &""))
		var key := StringName(sid.trim_suffix("_r").trim_suffix("_l"))
		var d: Vector3
		if shape.has(key):
			d = shape[key]
			if sid.ends_with("_l"):
				d.z = -d.z
			var q := Basis.from_euler(d * (PI / 180.0)).get_rotation_quaternion()
			if key == &"upper_arm":
				# The arm swung to where those angles point it, by the shortest turn from hanging
				# down: two Euler angles together also twist it about its own length (51 degrees on
				# the left, past its 40: the lab's twist_past_limit).
				q = Quaternion(Vector3.DOWN, q * Vector3.DOWN)
			j[2] = q
		elif back and BRACE_CURL.has(key):
			d = BRACE_CURL[key]
			j[2] = Basis.from_euler(d * (PI / 180.0)).get_rotation_quaternion() * (j[2] as Quaternion)
		else:
			continue
		j[3] = float(j[3]) * BRACE_TONE
		if j.size() < 6:
			j.append(BRACE_FADE)


# --- Going down (tone_style &"dying") -----------------------------------------------------------

## What a man still does while his tone goes (issue #442): the hand he held a wound with stays on
## it (or a free one goes to a fresh hole in his trunk), a free hand goes out to a rail, table, bar
## or wall within his reach, and his arms come up in front of him before his chest or face meets
## the ground. Small, not a performance, and his own: the hand drawn toward its place with the same
## pull back on him (nothing from outside), as strong as that arm's tone still is and none once
## it's gone. Dead, none of it; out cold, only the arms, weaker.
const DYING_REACH := 0.75  ## m from his shoulder: a rail, table or wall this near he puts a hand to
const DYING_ABOVE := 0.45  ## m over his feet: lower than this it's the floor, nothing to hold
const DYING_HAND_K := 80.0  ## N/m: the hand's pull toward its place
const DYING_HAND_MAX := 20.0  ## N: the most an arm pulls with as he goes
const DYING_HAND_DAMP := 10.0  ## N per m/s of the hand's speed against the place
const DYING_FIND := 0.2  ## s before a hand goes to a fresh wound (he's only just found it)
const DYING_GRAB_AT := 0.1  ## s before a hand goes out to something beside him
const DYING_LET_GO := 0.05  ## m past his arm's length from it, he lets it go
const DYING_ARM_HOLD := 1.4  ## an arm on a wound or a rail goes this many times slower
## His arms come up in front of him (BRACE_FRONT's arms) as he pitches forward: his chest facing at
## least this far down, coming down this fast (m/s), this near the ground (m); held again at this
## many times their tone for DYING_ARMS_FOR s, then fading over DYING_ARMS_FADE.
const DYING_FACE_DOWN := 0.3
const DYING_FALL_SPEED := 0.6
const DYING_ARMS_NEAR := 0.9
const DYING_ARMS_TONE := 1.2
const DYING_ARMS_OUT_COLD := 0.6  ## ... this share of it, unconscious
const DYING_ARMS_FOR := 0.15
const DYING_ARMS_FADE := 0.35
var _dying := {}  ## side -> {seg (&"" for the world), at (in the part, or world), n, from, wound, pressed}
var _dying_on := false  ## he's going down under &"fade", alive
var _dying_arms := true  ## his arms have come forward this fall (or won't)
var _dying_t := 0.0


func _start_dying(holding: Dictionary, joint_at: Dictionary) -> void:
	_end_dying()
	_dying_t = 0.0
	if tone_style != &"dying" or _tone_when.size() != _tone.size() or _tone.is_empty() or not physiology.alive:
		return
	_dying_on = true
	_dying_arms = false
	if not holding.is_empty() and parts.has(holding.seg):
		_dying_hand(String(holding.side), holding.seg, holding.at, 0.0, holding.wound)
	if not physiology.is_conscious():
		return
	# Something beside him to put a hand to: the nearest of the world, not the floor, to a shoulder.
	var space := World.space(self)
	if space == null:
		return
	var feet := INF
	for f in [&"foot_l", &"foot_r"]:
		if parts.has(f):
			feet = minf(feet, (parts[f] as Node3D).global_position.y)
	var ball := SphereShape3D.new()
	ball.radius = DYING_REACH
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = ball
	q.collision_mask = Layers.WORLD
	var best := INF
	var pick := ""
	var at := Vector3.ZERO
	for side in ["r", "l"]:
		var sh := StringName("upper_arm_" + side)
		if _dying.has(side) or not joint_at.has(sh) or not _hand_free(side):
			continue
		var shoulder: Vector3 = joint_at[sh]
		q.transform = Transform3D(Basis.IDENTITY, shoulder)
		Prof.count(&"q_body")
		var info := space.get_rest_info(q)
		if info.is_empty():
			continue
		var p: Vector3 = info.point
		var d := p.distance_to(shoulder)
		if p.y - feet < DYING_ABOVE or d >= best:
			continue
		best = d
		pick = side
		at = p + (shoulder - p).normalized() * 0.05  # the palm's own thickness off it
	if pick != "":
		_dying_hand(pick, &"", at, DYING_GRAB_AT, {})


## A ball in his trunk as he goes down (`_hunch`): a free hand finds the hole.
func _dying_wound(seg: StringName, at: Vector3) -> void:
	if not _dying_on or not physiology.is_conscious():
		return
	if not seg in [&"chest", &"abdomen", &"pelvis", &"neck"] or not parts.has(seg):
		return
	for side: String in _dying:
		if not (_dying[side].wound as Dictionary).is_empty():
			return  # he's holding one already
	var local := (parts[seg] as Node3D).global_transform.affine_inverse() * at
	if _skin_normal(seg, local).z > 0.3:
		return  # in his back: out of his reach
	var side := _grab_hand(seg, local)
	if _dying.has(side):
		var other := "l" if side == "r" else "r"
		side = other if not _dying.has(other) and _hand_free(other) else ""
	if side == "":
		return
	var w: Dictionary = wounds.back() if not wounds.is_empty() and wounds.back().segment == seg else {}
	_dying_hand(side, seg, local, DYING_FIND, w)


func _dying_hand(side: String, seg: StringName, at: Vector3, from: float, wound: Dictionary) -> void:
	_drop_dying(side)
	var n := _skin_normal(seg, at) if seg != &"" else Vector3.ZERO
	_dying[side] = {"seg": seg, "at": at, "n": n, "from": from, "wound": wound, "pressed": false}
	# That arm holds on longer than the other.
	for part in ["upper_arm_", "forearm_", "hand_"]:
		var i: int = _tone_index.get(StringName(part + side), -1)
		if i >= 0:
			var w: Vector2 = _tone_when[i]
			_tone_when[i] = Vector2(w.x, w.y * DYING_ARM_HOLD)
			_tone_until = maxf(_tone_until, w.x + w.y * DYING_ARM_HOLD)


func _drop_dying(side: String) -> void:
	if not _dying.has(side):
		return
	var d: Dictionary = _dying[side]
	if d.pressed:
		_hand_press(d.wound, false)
	_dying.erase(side)


func _end_dying() -> void:
	for side: String in _dying.keys():
		_drop_dying(side)
	_dying_arms = true
	_dying_on = false


## How much of its tone the joint above `sid` has left (0..1 of what it started with).
func _tone_left(sid: StringName) -> float:
	var i: int = _tone_index.get(sid, -1)
	if i < 0 or i >= _tone_when.size() or _tone.is_empty():
		return 0.0
	var w: Vector2 = _tone_when[i]
	return 1.0 - smoothstep(w.x, w.x + w.y, _tone_t)


func _step_dying(delta: float) -> void:
	if not _dying_on:
		return
	if _tone.is_empty():
		_end_dying()
		return
	_dying_t += delta
	for side: String in _dying.keys():
		var d: Dictionary = _dying[side]
		var hand := parts.get(StringName("hand_" + side)) as RigidBody3D
		var left := _tone_left(StringName("upper_arm_" + side))
		var on := parts.get(d.seg if d.seg != &"" else &"chest") as RigidBody3D
		if hand == null or on == null or not is_instance_valid(hand) or not is_instance_valid(on) or left <= 0.0 \
				or physiology.severed_segments.has(StringName("hand_" + side)):
			_drop_dying(side)
			continue
		if _dying_t < float(d.from):
			continue
		var target: Vector3 = d.at
		var back_at := (parts.get(StringName("upper_arm_" + side), on) as Node3D).global_position
		if d.seg == &"" and back_at.distance_to(target) > _arm_length(side) + DYING_LET_GO:
			# He's gone past it: the hand comes away rather than hold his arm up after it (the blind
			# judge: "both arms raised straight like a mannequin, one stays sticking up").
			_drop_dying(side)
			continue
		var v_rel := hand.linear_velocity
		if d.seg != &"":
			target = on.global_transform * ((d.at as Vector3) + (d.n as Vector3) * GRAB_OFF_SKIN)
			back_at = target
			v_rel -= on.linear_velocity + on.angular_velocity.cross(target - on.global_position)
		var f := ((target - hand.global_position) * DYING_HAND_K - v_rel * DYING_HAND_DAMP).limit_length(DYING_HAND_MAX) * left
		hand.apply_central_force(f)
		on.apply_force(-f, back_at - on.global_position)
		var there := hand.global_position.distance_to(target) < 0.1
		if not (d.wound as Dictionary).is_empty() and there != bool(d.pressed):
			d.pressed = there
			_hand_press(d.wound, there)
	if _dying_arms or _dying_t < 0.1 or not physiology.alive:
		_dying_arms = _dying_arms or not physiology.alive
		return
	var chest := parts.get(&"chest") as RigidBody3D
	if chest == null or not is_instance_valid(chest) or chest.linear_velocity.y > -DYING_FALL_SPEED \
			or (-chest.global_basis.z).y > -DYING_FACE_DOWN:
		return
	if chest.global_position.y - _ground_y(chest.global_position) > DYING_ARMS_NEAR:
		return
	_dying_arms = true
	# His arms up in front of him to take it: BRACE_FRONT's arms, held again for a moment.
	var mult := DYING_ARMS_TONE if physiology.is_conscious() else DYING_ARMS_TONE * DYING_ARMS_OUT_COLD
	for side in ["_r", "_l"]:
		if _dying.has(side.right(1)):
			continue  # that hand's busy
		for key: StringName in [&"upper_arm", &"forearm"]:
			var i: int = _tone_index.get(StringName(String(key) + side), -1)
			if i < 0:
				continue
			var j: Array = _tone[i]
			var e: Vector3 = BRACE_FRONT[key]
			if side == "_l":
				e.z = -e.z
			var q := Basis.from_euler(e * (PI / 180.0)).get_rotation_quaternion()
			if key == &"upper_arm":
				q = Quaternion(Vector3.DOWN, q * Vector3.DOWN)  # (as `_step_brace`: no twist)
			j[2] = q
			j[3] = float(j[3]) * mult
			_tone_when[i] = Vector2(_tone_t + DYING_ARMS_FOR, DYING_ARMS_FADE)
			_tone_until = maxf(_tone_until, _tone_t + DYING_ARMS_FOR + DYING_ARMS_FADE)


func _step_tone(delta: float) -> void:
	if _tone.is_empty():
		return
	_tone_t += delta
	if _tone_t > _tone_until:
		_tone.clear()
		_tone_when.clear()
		return
	var share := _tone_start * exp(-_tone_t / _tone_fade)
	var regions := _tone_when.size() == _tone.size()
	for i in _tone.size():
		var j: Array = _tone[i]
		# A braced joint (`brace`) holds on longer than the rest of him.
		var held := share
		if j.size() >= 6:
			held = _tone_start * exp(-_tone_t / float(j[5]))
		elif regions:
			var w: Vector2 = _tone_when[i]
			held = _tone_start * (1.0 - smoothstep(w.x, w.x + w.y, _tone_t))
			if held <= 0.0:
				continue  # this joint's let go: no spring left on it
		var child := j[0] as RigidBody3D
		var up := j[1] as RigidBody3D
		if not is_instance_valid(child) or not is_instance_valid(up) 				or physiology.severed_segments.has(child.get_meta(&"segment", &"")):
			continue
		var pb := up.global_basis.orthonormalized()
		var now := (pb.inverse() * child.global_basis.orthonormalized()).get_rotation_quaternion()
		var err := (j[2] as Quaternion) * now.inverse()
		if err.w < 0.0:
			err = -err
		var angle := err.get_angle()
		var axis := pb * err.get_axis() if angle > 1e-5 else Vector3.ZERO
		# Stiffness and damping held under what one physics step can take for the lighter of the two
		# parts (a hand's or the neck's inertia is tiny: uncapped, they spun 45 degrees a tick).
		var rel_w := child.angular_velocity - up.angular_velocity
		var at: Vector3 = child.global_transform * (j[4] as Vector3)
		var k := minf(j[3] * held, TONE_STEP_SHARE * _tone_inertia(child, up, axis, at) / (delta * delta))
		var c := minf(k * TONE_DAMP, TONE_STEP_SHARE * _tone_inertia(child, up, rel_w.normalized(), at) / delta)
		if is_nan(k) or is_nan(c):
			continue
		var torque := axis * angle * k - rel_w * c
		child.apply_torque(torque)
		up.apply_torque(-torque)


# --- Blasts ------------------------------------------------------------------------------------

const LIMBS := [["hand", "forearm", "upper_arm"], ["foot", "shin", "thigh"]]


## Caught by a charge of `kg` TNT going off at `at`: the pressure at each part of him (reflected
## off the side turned to it, less behind a wall), then ears, lungs and head, burns in the fireball, parts torn open, limbs torn off at
## the joint, and thrown down by the blast wind.
func take_blast(at: Vector3, kg: float, _held := false) -> Dictionary:
	var bt := Blast.t()
	var kpa := {}
	var exclude: Array[RID] = []
	for sid: StringName in parts:
		exclude.append((parts[sid] as CollisionObject3D).get_rid())
	if _blocker and is_instance_valid(_blocker):
		exclude.append(_blocker.get_rid())
	var chest: Vector3 = (parts[&"chest"] as Node3D).global_position
	var shield := Blast.shielding(get_parent() as Node3D, at, chest, exclude)
	for sid: StringName in parts:
		var part := parts[sid] as Node3D
		if part == null or not is_instance_valid(part) or physiology.severed_segments.has(sid):
			continue
		# The side of the part turned to it takes the reflected pressure (#220).
		kpa[sid] = Blast.reflected_kpa(Blast.overpressure_kpa(kg, _distance_to_part(sid, at)) * shield)
	var wind := Blast.overpressure_kpa(kg, _distance_to_part(&"chest", at)) * shield
	var harm := physiology.blast_injury(kpa.get(&"head", 0.0), kpa.get(&"chest", 0.0), kpa.get(&"head", 0.0), bt, _rng)
	if chest.distance_to(at) < Blast.fireball_radius(kg):
		physiology.burn(bt.burn_in_fireball)
		burn_marks(bt.burn_in_fireball, at)
		harm.append("burnt")
	# Torn open where the pressure was worst.
	for sid: StringName in kpa:
		var p: float = kpa[sid]
		if p > bt.open_kpa:
			var part := parts[sid] as Node3D
			var local := part.global_transform.affine_inverse() * at
			var toward := local.normalized() if local.length() > 0.001 else Vector3.FORWARD
			var skin := toward * float(anatomy.segments[sid].radius)
			open_wound(sid, skin, minf((p - bt.open_kpa) * bt.open_joules_per_kpa, 3000.0), (part.global_position - at).normalized(), &"gore_blast")
	# Limbs: the most of each arm and leg the blast can take.
	var torn_off: Array[StringName] = []
	for side in ["r", "l"]:
		for chain: Array in LIMBS:
			var take := &""
			for kind: String in chain:
				var sid := StringName(kind + "_" + side)
				if kpa.get(sid, 0.0) > float(bt.sever_kpa.get(kind, INF)):
					take = sid
			if take != &"":
				torn_off.append(take)
	var dir := (chest - at).normalized()
	var r := maxf(chest.distance_to(at), 0.05)
	var speed := Blast.impulse(kg, r) * shield * 0.7 * bt.throw_factor / maxf(_body_mass(), 1.0)
	# Along the blast's own way out from the charge: no lift added (near the ground the reflected
	# wave runs along it, and a charge lower than his chest already pushes him up and away).
	var push := dir * minf(speed, bt.max_throw)
	var down: bool = wind > bt.knockdown_kpa or speed > bt.knockdown_speed or not torn_off.is_empty()
	if down:
		harm.append("thrown off his feet")
		# The blast that throws a man takes his hat: a light thing with a wide brim, it goes faster
		# than he does (experiments/body_lab: it stayed on every man thrown down).
		knock_hat_off(push * 1.5 + Vector3.UP * 1.5)
	if down and not limp:
		go_limp(push)
	elif limp:
		for sid: StringName in parts:
			var rb := parts[sid] as RigidBody3D
			if rb:
				rb.linear_velocity += push * clampf(kpa.get(sid, 0.0) / maxf(kpa.get(&"chest", 1.0), 1.0), 0.3, 3.0)
	else:
		_flinch_from(&"chest", chest, dir, speed * 2.0)
	for sid in torn_off:
		sever_limb(sid, _limb_throw(sid, at, kg, shield, bt) - push)
		harm.append("%s torn off" % _place(sid))
	var info := {"person": self, "person_id": person_id, "segment": &"chest", "hits": [], "position": chest,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blast", "harm": harm,
			"kpa": kpa.get(&"chest", 0.0), "knocked_down": down}
	# Only what it did to him is a wound and a hit: a blast that only rattles him (everyone in its
	# reach, ~18 m for a stick on the ground) leaves none, and his fright is OutlawBrain's own
	# (Events.exploded). Each was logged "hit (chest)" for every townsperson in the street (#488).
	if harm.is_empty():
		return info
	var w := {"segment": &"chest", "entry": Vector3.ZERO, "exit": null, "lodged": false, "hits": [],
			"bleeds": [], "garments": [], "stain": null, "kind": &"blast", "dir": dir, "harm": harm,
			"kpa": kpa.get(&"chest", 0.0)}
	wounds.append(w)
	hit.emit(info)
	Events.body_hit.emit(info)
	return info


## A limb torn off by the blast: the push its own face takes for its weight (a forearm has far more
## face to its weight than a man has), in place of the whole man's push. As take_blast's for him:
## impulse per area x the face turned to it x throw_factor, over the limb's mass.
func _limb_throw(segment: StringName, at: Vector3, kg: float, shield: float, bt: BlastTuning) -> Vector3:
	var area := 0.0
	var mass := 0.0
	var centre := Vector3.ZERO
	for sid: StringName in anatomy.segments_below(segment):
		var part := parts.get(sid) as Node3D
		if part == null:
			continue
		mass += float(part.get_meta(&"mass", 1.0))
		centre += part.global_position * float(part.get_meta(&"mass", 1.0))
		for c: Array in anatomy.segments[sid].capsules:
			var r: float = c[2]
			area += 2.0 * r * (((c[1] as Vector3) - (c[0] as Vector3)).length() + 2.0 * r)
	if mass <= 0.0:
		return Vector3.ZERO
	centre /= mass
	var r := maxf(centre.distance_to(at), 0.05)
	var speed := Blast.impulse(kg, r) * shield * area * bt.throw_factor / mass
	return (centre - at).normalized() * minf(speed, bt.max_throw)


func _body_mass() -> float:
	var m := 0.0
	for sid: StringName in parts:
		m += float((parts[sid] as Node).get_meta(&"mass", 5.0))
	return m


## Distance from a point to a body part's skin (nearest capsule surface).
func _distance_to_part(sid: StringName, point: Vector3) -> float:
	var part := parts[sid] as Node3D
	var local := part.global_transform.affine_inverse() * point + anatomy.segment_center(sid)
	var best := INF
	for c: Array in anatomy.segments[sid].capsules:
		var a: Vector3 = c[0]
		var ab: Vector3 = (c[1] as Vector3) - a
		var t := clampf((local - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, local.distance_to(a + ab * t) - float(c[2]))
	return maxf(best, 0.02)


## Tear a limb off at the joint above `segment` (it and everything below it go): he goes down, the
## joint lets go, the stump opens and bleeds hard, and the limb goes on with `push` (m/s, over
## what the rest of him has: what tore it off gives it).
func sever_limb(segment: StringName, push := Vector3.ZERO) -> void:
	if physiology.severed_segments.has(segment):
		return
	if not limp:
		go_limp()
	var parent: StringName = anatomy.segments[segment].parent
	var joint := get_node_or_null(NodePath("Joint_%s" % segment)) as Node3D
	var at: Vector3 = joint.global_position if joint else (parts[segment] as Node3D).global_position
	var first := physiology.bleeds.size()
	physiology.sever(segment)
	_stop_skinning_across_joints(segment)
	if joint:
		joint.queue_free()
	for sid in anatomy.segments_below(segment):
		var rb := parts.get(sid) as RigidBody3D
		if rb:
			# Its own push and no more: no spin thrown in (it turns as the joint lets go of it).
			rb.linear_velocity += push
	# The stump and the torn end of the limb.
	var parent_part := parts[parent] as Node3D
	var limb_part := parts[segment] as Node3D
	var stump := open_wound(parent, parent_part.global_transform.affine_inverse() * at, 2200.0, Vector3.ZERO, &"")
	var end := open_wound(segment, limb_part.global_transform.affine_inverse() * at, 2200.0, Vector3.ZERO, &"")
	# The cut faces, across the stump and the torn end of the limb.
	var down := limb_part.global_position - at
	_stump_face(parent, at, down, stump.radius, _stump_look(parent, segment))
	_stump_face(segment, at, -down, end.radius, &"stump_torn" if _spin(Vector3(0.3, 0.0, 0.0) + at) < PI else _stump_look(segment, segment))
	var w := {"segment": parent, "part": segment, "entry": parent_part.global_transform.affine_inverse() * at,
			"exit": null, "lodged": false, "hits": [], "bleeds": range(first, physiology.bleeds.size()),
			"garments": [], "stain": null, "kind": &"severed", "dir": push.normalized()}
	wounds.append(w)
	_add_jet(visuals[parent], w, w.entry, 1.0)
	if get_parent() is Node3D:
		Blood.burst(get_parent(), at, push.normalized(), 16, 3.0)
		Blood.spray(get_parent() as Node3D, at, push.normalized(), 60.0, 8, _rng)
	if segment.begins_with("hand") or segment.begins_with("forearm") or segment.begins_with("upper_arm"):
		if held_gun and String(segment).ends_with("_r"):
			drop_gun()


## Knees and elbows are hinges: a knee only bends back, an elbow only forward, however he falls.
## The limits are measured from how bent the joint is as he goes limp.
const KNEE_BEND := 150.0
const ELBOW_BEND := 150.0


## A foot whose middle is this near the ground under it is down on it (standing, ~5 cm).
const PLANTED_WITHIN := 0.12


func _on_ground(space: PhysicsDirectSpaceState3D, rb: RigidBody3D) -> bool:
	var at := rb.global_position
	Prof.count(&"q_body")
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * PLANTED_WITHIN, Layers.STAND))
	return not hit.is_empty()


## The side he's standing on ("_l" or "_r"): his lower foot.
static func _stance_side(bodies: Dictionary) -> String:
	if not bodies.has(&"foot_l") or not bodies.has(&"foot_r"):
		return "_l"
	return "_r" if (bodies[&"foot_r"] as Node3D).global_position.y < (bodies[&"foot_l"] as Node3D).global_position.y else "_l"


func _hinge(sid: StringName, parent: StringName, bodies: Dictionary, at: Vector3) -> void:
	var j := HingeJoint3D.new()
	j.name = "Joint_%s" % sid
	add_child(j)
	# The hinge turns about its Z: lay that along his right (the parent's X), Y down the limb.
	var right := (bodies[parent] as Node3D).global_basis.x.normalized()
	var down := ((bodies[sid] as Node3D).global_position - at).normalized()
	down = (down - right * down.dot(right)).normalized()
	j.global_transform = Transform3D(Basis(down.cross(right), down, right), at)
	j.node_a = j.get_path_to(bodies[parent])
	j.node_b = j.get_path_to(bodies[sid])
	var now: float = (_pose_now.get(sid, Vector3.ZERO) as Vector3).x
	var lower := 0.0
	var upper := 0.0
	# The hinge's angle runs opposite to the poses' X (measured from where the joint is now).
	if String(sid).begins_with("shin"):
		# A knee bends with -X in the poses: from straight to fully bent.
		lower = now
		upper = KNEE_BEND + now
	else:
		lower = now - ELBOW_BEND
		upper = now
	j.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	j.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(lower))
	j.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper))


# --- Openings: bad wounds show what's inside --------------------------------------------------

## A torn opening this big shows at the first; energy piles up where hits land close together.
const OPEN_MIN_RADIUS := 0.018
const OPEN_PER_SQRT_JOULE := 0.0013
const OPEN_MERGE := 0.06
## An opening with this much energy in it has destroyed the region: the bone in it is smashed and
## thrown out as fragments (point-blank buckshot, a blast; a single ball never gets there).
const DESTROY_ENERGY := 1000.0
const MAX_FRAGMENTS := 40
## Below this, buckshot is a pellet (the ball of a .45 is 16.5 g).
const PELLET_MASS := 0.006
## Pellet wounds this close share one blood stream.
const PELLET_JET_MERGE := 0.07

var _fragments := 0


func _use_wound_materials() -> void:
	for sid: StringName in visuals:
		for mi: MeshInstance3D in (visuals[sid] as Node3D).find_children("*", "MeshInstance3D", true, false):
			if mi.layers == Layers.VIS_BODY and mi.material_override is StandardMaterial3D:
				mi.material_override = BodyInterior.skin_material(mi.material_override as StandardMaterial3D)


func _on_settings_changed() -> void:
	for sid: StringName in openings:
		_apply_openings(sid)


## Tear the body open at a point (segment-centred rest space) with `energy` joules of damage:
## bullets dumping their energy, a blast, point-blank buckshot. Close hits add up; past
## DESTROY_ENERGY the region is destroyed and the bone in it flies out along `dir` (world).
## `look` is the painted torn edge laid round it once it opens (`_gore_edge`), none for a stump's.
func open_wound(segment: StringName, at: Vector3, energy: float, dir := Vector3.ZERO, look := &"gore_crater") -> Dictionary:
	var list: Array = openings.get_or_add(segment, [])
	var o: Dictionary = {}
	for existing: Dictionary in list:
		if (existing.at as Vector3).distance_to(at) < OPEN_MERGE:
			o = existing
			break
	if o.is_empty():
		o = {"at": at, "energy": 0.0, "radius": 0.0}
		list.append(o)
	var old_at: Vector3 = o.at
	var old_radius: float = o.radius if o.get("destroyed", false) else 0.0
	var total: float = o.energy + energy
	o.at = (o.at as Vector3).lerp(at, energy / maxf(total, 0.001))
	o.energy = total
	var cap: float = float(anatomy.segments[segment].radius) * 1.2
	o.radius = minf(OPEN_PER_SQRT_JOULE * sqrt(total), cap)
	if o.radius >= OPEN_MIN_RADIUS:
		_apply_openings(segment)
		_gore_edge(segment, o, look)
	if total >= DESTROY_ENERGY:
		o.destroyed = true
		_smash_bone(segment, o.at, o.radius, old_at, old_radius, dir)
	return o


## The bone that was inside a destroyed opening and isn't now: broken in the anatomy, and thrown
## out as fragments (rigid pieces that stay where they land).
func _smash_bone(segment: StringName, at: Vector3, radius: float, old_at: Vector3, old_radius: float, dir: Vector3) -> void:
	var center := anatomy.segment_center(segment)
	var gone: Array[Vector3] = []
	for st: Dictionary in anatomy.by_segment.get(segment, []):
		if st.kind != &"bone":
			continue
		var pts := BodyInterior.bone_points(st)
		var hit := false
		for p: Vector3 in pts:
			var local := p - center
			if local.distance_to(at) < radius:
				hit = true
				if old_radius <= 0.0 or local.distance_to(old_at) >= old_radius:
					gone.append(local)
		if hit and not physiology.broken.has(st.id):
			physiology.break_bone(st.id)
	var part: Node3D = parts.get(segment)
	var world := get_parent() as Node3D
	if part == null or world == null or gone.is_empty():
		return
	var fly := dir.normalized() if dir.length() > 0.01 else -part.global_basis.z
	var every := maxi(1, gone.size() / 8)
	for i in range(0, gone.size(), every):
		if _fragments >= MAX_FRAGMENTS:
			break
		_fragments += 1
		var from: Vector3 = part.global_transform * gone[i]
		var out := (from - part.global_transform * at).normalized()
		var v := fly * _rng.randf_range(1.5, 5.0) + out * _rng.randf_range(0.5, 2.5) + Vector3.UP * _rng.randf_range(0.0, 1.5)
		ImpactEffects.bone_fragment(world, from, v, _rng)


## The same, from a world point on one of the body's parts.
func open_wound_at(collider: Node3D, point: Vector3, energy: float) -> Dictionary:
	var seg: StringName = collider.get_meta(&"segment", &"") if collider else &""
	if seg == &"":
		seg = segment_at(point)
	var part: Node3D = parts[seg]
	return open_wound(seg, part.global_transform.affine_inverse() * point, energy)


## The painted torn edge round an opening (tools/textures/paint_blood.py "gore", by Gemini): a
## shotgun's crater, a burst exit, a blast's peppering. Laid on the skin and clothes round the hole
## (the insides show in the hole itself) and grown with it. None with reduced gore.
const UPRIGHT_LOOKS := [&"ear_torn", &"nose_gone", &"jaw_gone"]


func _gore_edge(segment: StringName, o: Dictionary, look: StringName) -> void:
	if look == &"" or Settings.reduced_gore:
		return
	var vis: Node3D = visuals.get(segment)
	if vis == null:
		return
	var d: Decal = o.get("gore")
	if d == null or not is_instance_valid(d):
		d = _decal(vis, segment, o.at, 0.05, PixelArt.blood(String(look), 61, true, 32))
		d.name = "Gore"
		o.gore = d
		if UPRIGHT_LOOKS.has(look):
			# A face's wound painted the right way up: its top toward the top of his head.
			var n := d.basis.y.normalized()
			var z := Vector3.DOWN - n * Vector3.DOWN.dot(n)
			if z.length() > 0.2:
				z = z.normalized()
				d.basis = Basis(n.cross(z), n, z)
		else:
			# Turned about the hole by where it is, so two of the same look don't match (not from
			# his dice: a look mustn't change how a fight goes).
			d.basis = d.basis * Basis(Vector3.UP, _spin(o.at))
	d.position = o.at
	var side: float = o.radius * GORE_EDGE
	d.size = Vector3(side, 0.08, side)


## How often a ball carries cloth into him: staying in him, and going through (the way out takes
## some of it with it).
## How close a shot leaves burnt powder round its hole (m), and how close is a contact shot whose
## gas tears the hole open in a star (DiMaio).
const POWDER_RANGE := 0.9
const CONTACT_RANGE := 0.05
const SCORCH_RANGE := 0.3
const FESTER_CLEAN_CHANCE := 0.3
const CLOTH_IN_LODGED := 0.7
const CLOTH_IN_THROUGH := 0.35


## A roll (0..1) from where a wound is and what it's for (`salt`): the same wound, the same roll,
## and not from his dice (a wound's look and what it carried mustn't change how a fight goes).
func _chance(p: Vector3, salt: int) -> float:
	return float(posmod(hash([p.snapped(Vector3.ONE * 0.0005), salt, rng_seed]), 10007)) / 10007.0


## An angle (0..TAU) from a point, for turning a painted mark: the same point, the same turn.
static func _spin(p: Vector3) -> float:
	return float(posmod(hash(p.snapped(Vector3.ONE * 0.001)), 10007)) / 10007.0 * TAU


## How wide a wound's painted edge is, in opening radii (the painted wound's own hole is about a
## third of its picture: it falls in the opening, where there's no skin to take it).
const GORE_EDGE := 3.0


## Which painted section a limb shows where it's cut through (the bones in it: Gray's Anatomy).
static func _stump_look(sid: StringName, severed: StringName) -> StringName:
	var s := String(sid)
	if s.begins_with("forearm") or s.begins_with("shin") or s.begins_with("hand") or s.begins_with("foot"):
		return &"stump_pair"
	if s.begins_with("thigh"):
		return &"stump_leg"
	if s.begins_with("upper_arm"):
		return &"stump_arm"
	# The trunk's side of a whole arm or leg off: the limb's top in section.
	return &"stump_leg" if String(severed).begins_with("thigh") else &"stump_arm"


## A painted cut face across a limb where it was torn through (tools/textures/paint_blood.py
## "stumps", by Gemini): a disc at the plane where the opening leaves the skin, as wide as the limb
## there, facing out along `out` (world). The bone and muscle that stand proud of it are the insides
## (BodyInterior). With reduced gore, the plain opening.
func _stump_face(segment: StringName, at: Vector3, out: Vector3, opening: float, look: StringName) -> void:
	if Settings.reduced_gore or out.length() < 0.001:
		return
	var vis: Node3D = visuals.get(segment)
	var part := parts.get(segment) as Node3D
	if vis == null or part == null:
		return
	var local := part.global_transform.affine_inverse() * at
	var axis := (part.global_basis.inverse() * out).normalized()
	# The limb's radius at the cut: the nearest of its capsules.
	var r := 0.04
	var best := INF
	var p := local + anatomy.segment_center(segment)
	for c: Array in anatomy.segments[segment].capsules:
		var a: Vector3 = c[0]
		var ab: Vector3 = (c[1] as Vector3) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		var off := p.distance_to(a + ab * t) - float(c[2])
		if off < best:
			best = off
			r = float(c[2])
	var mi := MeshInstance3D.new()
	mi.name = "StumpFace"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * r * 2.0 * STUMP_FACE_FILL
	mi.mesh = quad
	var m := StandardMaterial3D.new()
	m.albedo_texture = PixelArt.blood(String(look), 67, true, 32)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.3  # wet
	mi.material_override = m
	mi.layers = Layers.VIS_BODY
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The quad faces its +Z: along the limb, out of the cut; turned at random about it.
	var b := _along(axis)
	mi.basis = Basis(b.z, b.x, b.y) * Basis(Vector3.BACK, _spin(local))
	var back := sqrt(maxf(opening * opening - r * r, 0.0))
	mi.position = local - axis * back
	vis.add_child(mi)


## How much of its square a painted section fills (its picture is cropped with a little margin).
const STUMP_FACE_FILL := 1.0


func is_open(segment: StringName) -> bool:
	for o: Dictionary in openings.get(segment, []):
		if o.radius >= OPEN_MIN_RADIUS:
			return true
	return false


func _apply_openings(segment: StringName) -> void:
	var vis: Node3D = visuals.get(segment)
	if vis == null:
		return
	var list: Array[Vector4] = []
	for o: Dictionary in openings.get(segment, []):
		if o.radius >= OPEN_MIN_RADIUS:
			var at: Vector3 = o.at
			list.append(Vector4(at.x, at.y, at.z, o.radius))
	if list.is_empty():
		return
	if vis.get_node_or_null(^"Inside") == null:
		BodyInterior.build(segment, vis, anatomy)
	BodyInterior.apply(vis, list, Settings.reduced_gore)
	# The generated skin and clothes: openings are already in the part's rest space.
	_unmerge()
	var arr := PackedVector4Array(list)
	while arr.size() < BodyInterior.MAX_OPENINGS:
		arr.append(Vector4.ZERO)
	for mi: MeshInstance3D in segment_pieces.get(segment, []):
		var m := mi.material_override as ShaderMaterial
		m.set_shader_parameter(&"wound_count", mini(list.size(), BodyInterior.MAX_OPENINGS))
		m.set_shader_parameter(&"wounds", arr)
		m.set_shader_parameter(&"reduced_gore", Settings.reduced_gore)


# --- X-ray (debug, F10) -------------------------------------------------------------------------

const XRAY_COLOURS := {
	&"bone": Color(0.95, 0.92, 0.8, 0.95), &"finger": Color(0.95, 0.92, 0.8, 0.95),
	&"artery": Color(0.95, 0.12, 0.1, 0.95), &"vein": Color(0.25, 0.38, 0.95, 0.95),
	&"organ": Color(0.9, 0.5, 0.6, 0.75), &"muscle": Color(0.7, 0.25, 0.22, 0.2),
	&"nerve": Color(1.0, 0.9, 0.25, 0.95),
}
const XRAY_ORDER := {&"muscle": 0, &"organ": 1, &"bone": 2, &"finger": 2, &"vein": 3, &"artery": 3, &"nerve": 4}

## Everyone new comes in with X-ray on if it's on.
static var xray_all := false
static var _xray_mats := {}


## See through the skin and clothes to the anatomy: bones, arteries (red), veins (blue), organs,
## muscles (faint), nerves (yellow). Anything damaged shows orange; each ball's track is a line.
func set_xray(on: bool) -> void:
	xray = on
	for mi: MeshInstance3D in skin_meshes.values() + _merged.values():
		mi.transparency = 0.88 if on else 0.0
	for sid: StringName in visuals:
		var vis: Node3D = visuals[sid]
		var old := vis.get_node_or_null(^"XRay")
		if old:
			old.free()
		for mi in vis.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).transparency = 0.88 if on else 0.0
		if held_gun:
			for mi in held_gun.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).transparency = 0.0
		if not on:
			continue
		var root := Node3D.new()
		root.name = "XRay"
		vis.add_child(root)
		var center := anatomy.segment_center(sid)
		for st: Dictionary in anatomy.by_segment.get(sid, []):
			if st.kind == &"finger" and physiology.lost_fingers.has(st.id):
				continue
			var damaged: bool = physiology.broken.has(st.id) or physiology.cut.has(st.id) \
					or physiology.torn.has(st.id) or physiology.muscle_damage.has(st.id)
			var shell: bool = st.get(&"shell", 0.0) > 0.0
			var colour: Color = XRAY_COLOURS.get(st.kind, Color.WHITE)
			if shell:
				colour.a = 0.22
			if damaged:
				colour = Color(1.0, 0.6, 0.05, 0.3 if shell else 0.95)
			var mi := MeshInstance3D.new()
			var length: float = ((st.b as Vector3) - (st.a as Vector3)).length()
			if length < 0.001:
				var sm := SphereMesh.new()
				sm.radius = st.radius
				sm.height = st.radius * 2.0
				sm.radial_segments = 10
				sm.rings = 5
				mi.mesh = sm
			else:
				var cm := CapsuleMesh.new()
				cm.radius = st.radius
				cm.height = length + st.radius * 2.0
				cm.radial_segments = 8
				cm.rings = 1
				mi.mesh = cm
				mi.basis = _along((st.b as Vector3) - (st.a as Vector3))
			mi.position = ((st.a as Vector3) + (st.b as Vector3)) * 0.5 - center
			mi.material_override = _xray_material(colour, int(XRAY_ORDER.get(st.kind, 1)) + (5 if damaged else 0))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(mi)
		for w in wounds:
			if w.segment != sid:
				continue
			var end: Variant = w.exit if w.exit != null else w.stop
			if end == null:
				continue
			var a: Vector3 = w.entry
			var b: Vector3 = end
			var line := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.003
			cyl.bottom_radius = 0.003
			cyl.height = maxf(a.distance_to(b), 0.005)
			cyl.radial_segments = 4
			line.mesh = cyl
			line.basis = _along(b - a)
			line.position = (a + b) * 0.5
			line.material_override = _xray_material(Color(1.0, 1.0, 0.4, 1.0), 12)
			root.add_child(line)


static func _xray_material(colour: Color, order: int) -> StandardMaterial3D:
	var key := "%s/%d" % [colour.to_html(), order]
	if not _xray_mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = colour
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.render_priority = order
		_xray_mats[key] = m
	return _xray_mats[key]


# --- Saving and describing ---------------------------------------------------------------------

func describe_wounds() -> PackedStringArray:
	var out: PackedStringArray = []
	var groups := {}  # [kind, segment] -> [wounds]
	for w in wounds:
		var kind: StringName = w.get("kind", &"bullet")
		if _small_wound(kind):
			groups.get_or_add([kind, w.segment], []).append(w)
			continue
		if kind == &"severed":
			out.append("%s: torn off at the joint, the stump bleeding" % _place(w.get("part", w.segment)))
			continue
		if kind == &"blast":
			if not (w.harm as PackedStringArray).is_empty():
				out.append("blast: %s" % ", ".join(w.harm))
			continue
		out.append("%s: %s" % [_place(w.segment), _describe_one(w)])
	# Buckshot and splinters: one line per part, however many.
	for key: Array in groups:
		var list: Array = groups[key]
		var seg: StringName = key[1]
		var lodged := list.filter(func(w: Dictionary) -> bool: return w.lodged).size()
		var what: PackedStringArray = []
		for w: Dictionary in list:
			for x in _hit_words(w):
				if not what.has(x):
					what.append(x)
		var how := ""
		if key[0] == &"pellet":
			how = "buckshot, %d pellet%s" % [list.size(), "s" if list.size() > 1 else ""]
		elif key[0] == &"gravel":
			how = "gravel and grit from a blast, %d" % list.size()
		else:
			how = "blast splinters, %d" % list.size()
		if lodged > 0:
			how += ", %d still in" % lodged
		out.append("%s: %s%s" % [_place(seg), how, (" — " + ", ".join(what)) if not what.is_empty() else ""])
	for seg: StringName in openings:
		for o: Dictionary in openings[seg]:
			if o.get("destroyed", false):
				out.append("%s: torn wide open, the bone smashed" % _place(seg))
				break
	return out


func _place(seg: StringName) -> String:
	return String(seg).replace("_r", " (right)").replace("_l", " (left)").replace("_", " ")


func _describe_one(w: Dictionary) -> String:
	var what := _hit_words(w)
	var how := "through and through" if not w.lodged else "no exit, ball still in"
	match w.get("kind", &"bullet"):
		&"graze":
			how = "a graze, a bloody furrow"
		&"cut":
			how = "glass cut" + (", a shard still in it" if w.get("embedded", false) else "")
		&"stab":
			how = "a stab wound, narrow and deep"
		&"slash":
			how = "a knife cut, gaping"
		&"splinter":
			how = "a splinter" + (", still in him" if w.lodged else "")
		&"amputated":
			how = "the %s taken off by the doctor, the stump sewn" % _place(w.get("part", w.segment))
	if w.get("powder", false):
		how += ", powder-burnt (fired close)"
	return "%s%s" % [how, (" — " + ", ".join(what)) if not what.is_empty() else ""]


func _hit_words(w: Dictionary) -> PackedStringArray:
	var what: PackedStringArray = []
	for h: Dictionary in w.hits:
		match h.effect:
			&"broken":
				what.append("%s broken" % String(h.id).get_slice("_", 0))
			&"stopped":
				what.append("ball lodged against the %s" % String(h.id).get_slice("_", 0))
			&"cut":
				what.append("%s artery cut" % String(h.id).get_slice("_", 0))
			&"torn":
				what.append("%s torn" % String(h.id).get_slice("_", 0))
			&"severed":
				var part := String(h.id).get_slice("_", 0)
				what.append(("%s off" if part in ["ear", "nose"] else "%s finger off") % part)
	if w.get("cloth", &"") != &"":
		what.append("a plug of his %s carried in" % String(w.cloth))
	return what


func to_dict() -> Dictionary:
	var ws := []
	for w in wounds:
		ws.append({"segment": w.segment, "entry": w.entry, "exit": w.exit, "lodged": w.lodged,
				"hits": w.hits, "bleeds": w.bleeds, "garments": w.garments,
				"kind": w.get("kind", &"bullet"), "embedded": w.get("embedded", false),
				"part": w.get("part", &""), "harm": w.get("harm", PackedStringArray()),
				"cloth": w.get("cloth", &""), "flattened": w.get("flattened", false),
				"healed": w.get("healed", false), "age": w.get("age", 0.0)})
	var gs := {}
	for g in garments:
		gs[g.id] = g.holes.duplicate(true)
	var ops := {}
	for sid: StringName in openings:
		ops[String(sid)] = (openings[sid] as Array).map(func(o: Dictionary) -> Dictionary:
			return {"at": [o.at.x, o.at.y, o.at.z], "energy": o.energy, "radius": o.radius})
	return {"person_id": person_id, "tick_index": tick_index, "physiology": physiology.to_dict(), "wounds": ws, "openings": ops,
			"garment_holes": gs, "limp": limp, "gun_dropped": has_gun and held_gun == null}
