class_name PlayerTuning
extends Resource
## Every number that decides how the player moves. Edit config/player_tuning.tres, not code.

@export_group("Body")
@export var radius := 0.3
@export var stand_height := 1.78
@export var crouch_height := 1.3
@export var stand_eye_height := 1.64
@export var crouch_eye_height := 1.15
## How fast the eyes move between standing and crouched (m/s).
@export var crouch_transition_speed := 3.5

@export_group("Speed (m/s)")
@export var walk_speed := 2.8
@export var run_speed := 6.0
@export var crouch_speed := 1.4
@export var ground_accel := 30.0
@export var ground_decel := 22.0
@export var air_accel := 2.5
@export var jump_velocity := 3.6
@export var gravity := 9.8

@export_group("Look")
@export var max_pitch_degrees := 88.0

@export_group("Head bob")
## Up-down bobs per metre travelled (two per stride).
@export var bob_cycles_per_meter := 0.7
@export var bob_amplitude := 0.022

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
