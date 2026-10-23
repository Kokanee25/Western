class_name PlayerTuning
extends Resource
## Every number that decides how the player moves. Edit config/player_tuning.tres, not code.
## The movement presets (config/movement/light|middle|heavy.tres) set the groups in
## MOVEMENT_GROUPS; the gun's hold and being under fire stay the game's.

const MOVEMENT_GROUPS := ["Body", "Speed (m/s)", "Steps", "Head bob", "Lean (degrees)", "The gun with the body"]

@export_group("Body")
@export var radius := 0.3
@export var stand_height := 1.78
@export var crouch_height := 1.3
@export var stand_eye_height := 1.64
@export var crouch_eye_height := 1.15
## Crouching and standing are a spring: how quick (Hz) and how much it overshoots (damping: 1 =
## not at all, lower sinks past and comes back).
@export var crouch_hz := 2.0
@export var crouch_damping := 0.75

@export_group("Speed (m/s)")
@export var walk_speed := 2.8
@export var run_speed := 6.0
@export var crouch_speed := 1.4
## Momentum (m/s²): getting going up to walking pace, building from a walk to a full run, slowing
## when you let go, and when you push against the way you're going (turning back, a hard strafe).
@export var ground_accel := 9.0
@export var run_build := 4.5
@export var ground_decel := 9.0
@export var reverse_decel := 14.0
## Across the way you want to go (a turn at speed), how fast your boots take the speed off (m/s²).
@export var turn_grip := 16.0
## Running winds you (PlayerComposure.winded); past half winded the run sags, by this share of its
## speed when you're blown.
@export var winded_slow := 0.18
@export var air_accel := 2.5
@export var jump_velocity := 3.6
@export var gravity := 9.8
## The tallest step you walk up without jumping (m): a stair's riser, a porch step.
@export var step_height := 0.3

@export_group("Look")
@export var max_pitch_degrees := 88.0

@export_group("Steps")
## How far a step carries you (m): walking, at a full run, crouched. Each step is a footfall: the
## footstep sound and noise land on it, and so does the head's low.
@export var step_walk := 1.0
@export var step_run := 1.7
@export var step_crouch := 0.55

@export_group("Head bob")
## How far the head rises and falls over a step (m, half the travel): walking, at a full run, and
## the share of the walk's crouched.
@export var bob_walk := 0.018
@export var bob_run := 0.03
@export var bob_crouch := 0.6
## 0: a smooth rise and fall; 1: the low on each footfall a sharp jolt, the top rounded.
@export var bob_sharpness := 0.6
## Side to side over the planted foot, once a stride (m), and the roll that goes with it (degrees).
@export var bob_side := 0.012
@export var bob_roll := 0.35
## The weight coming down on each foot: how fast it drops the head (m/s) on top of the bob.
@export var step_thud := 0.08
## The spring the footfalls and landings drop the head on: how quick (Hz), how bouncy (damping).
@export var head_hz := 4.0
@export var head_damping := 0.45
## Up a step, the eyes catch up with the body at this rate (1/s: higher is quicker).
@export var step_ease := 14.0
## A landing: metres of dip per m/s you were falling, and the most it dips.
@export var land_dip := 0.035
@export var land_dip_max := 0.14
## Winded, his breath heaves the view (m at fully winded).
@export var breath_heave := 0.01

@export_group("Lean (degrees)")
## Roll into a strafe (per m/s sideways) and into a turn (turning 180°/s at a full run).
@export var strafe_lean := 0.5
@export var turn_lean := 1.0
## Pitch into a push off and back against a stop (per m/s²), and the most.
@export var accel_tilt := 0.12
@export var tilt_max := 1.5
## The lean's spring: how quick (Hz), how much it overshoots (damping).
@export var lean_hz := 2.2
@export var lean_damping := 0.7

@export_group("The gun with the body")
## The gun lags the view: degrees off per 100°/s of turn, and the most.
@export var hand_lag := 2.0
@export var hand_lag_max := 4.0
## It rides the steps: metres of travel per metre of head bob, and degrees of turn per centimetre.
@export var hand_bob := 0.5
@export var hand_bob_turn := 0.3
## It swings back as you push off (m per m/s²).
@export var hand_push := 0.004
## Its spring: how quick (Hz), how bouncy (damping).
@export var hand_hz := 3.5
@export var hand_damping := 0.5
## On the sights, the body's motion moves the view and the gun this share as much.
@export var aim_motion := 0.35

@export_group("Holding a gun (degrees)")
## How far the gun wanders off where you're looking: from the hip, and on the sights once you've
## held them still a moment. The shot goes where the barrel points.
@export var sway_hip := 1.1
@export var sway_aim := 0.28
## Breathing: how far the muzzle rises and falls, and breaths a second (faster when winded).
@export var breath := 0.2
@export var breath_rate := 0.25
## A fine shake on top (more with a hurt arm, more when rattled).
@export var tremor := 0.04
## Sights just raised, just fired, or just stopped moving: it wanders this many times as much,
## settling over `settle_time` seconds of holding still.
@export var unsettled := 2.0
@export var settle_time := 0.9
## Crouched it wanders this fraction as much; moving, this much more per m/s.
@export var crouch_sway := 0.6
@export var move_sway := 0.3
## Winded from running: up to this many times as much, after `winded_build` seconds of running,
## gone again over `winded_recovery` seconds.
@export var winded_sway := 2.2
@export var winded_build := 6.0
@export var winded_recovery := 10.0

@export_group("Under fire")
## A ball past your ear (or into the wall by your head): the jolt to your view and the jerk of the
## gun (degrees), the extra spread while you flinch, and how long a flinch lasts (s).
@export var flinch_jolt := 1.2
@export var flinch_jerk := 1.6
@export var flinch_spread := 2.5
@export var flinch_seconds := 0.9
## Rounds coming in: how much each one rattles you (0..1), how many times as much the gun wanders
## fully rattled, how far a round smacking into something can be from your head and still count
## (m), and how long it takes to steady once nothing's come in for `rattle_hold` seconds.
@export var rattle_per_round := 0.2
@export var rattled_sway := 2.5
@export var rattle_reach := 1.5
@export var rattle_hold := 1.5
@export var rattle_recovery := 8.0


## Take every movement dial (the groups in MOVEMENT_GROUPS) from a preset.
func take_movement(from: PlayerTuning) -> void:
	for p in movement_dials():
		set(p, from.get(p))


## The names of the movement dials.
func movement_dials() -> PackedStringArray:
	var names: PackedStringArray = []
	var group := ""
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_GROUP:
			group = p.name
		elif p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and group in MOVEMENT_GROUPS:
			names.append(p.name)
	return names
