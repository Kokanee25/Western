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
