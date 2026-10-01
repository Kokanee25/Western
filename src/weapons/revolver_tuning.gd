class_name RevolverTuning
extends Resource
## Every number about the single-action revolver. Edit config/revolver.tres, not code.
## Defaults are a Colt Single Action Army in .45 Colt with a black-powder load.

@export_group("Handling (seconds)")
@export var cock_time := 0.22
@export var fire_recovery := 0.2
@export var gate_time := 0.35
@export var turn_time := 0.14
@export var eject_time := 0.4
@export var insert_time := 0.5
@export var draw_time := 0.4

@export_group("Ammunition")
@export var cylinder_size := 6
## Rounds you start with in the cylinder. Five, with the hammer down on the empty sixth, is how
## it was carried: a knock on the hammer can't set one off.
@export var start_loaded := 5
@export var belt_capacity := 24
@export var start_belt := 24
## Chance a cartridge fails to fire (black powder, old primers).
@export var misfire_chance := 0.01

@export_group("Ballistics")
@export var muzzle_velocity := 240.0  ## m/s
@export var bullet_mass := 0.0165  ## kg (255 grain lead)
@export var bullet_diameter := 0.0114  ## m
## Drag of its blunt round-nosed conical bullet (a round ball would be 0.47): keeps ~95% of its
## speed at 50 m, ~90% at 100 m (published .45 Colt lead loads keep about nine tenths at 100 yd).
@export var drag_coefficient := 0.28
## The range its fixed sights are regulated for (25 yards): the ball rises a little above your
## line of sight, crosses it here, and falls away below it beyond (hold high at long range).
@export var zero_distance := 22.9
## Accuracy: random cone half-angle in degrees.
@export var spread_hip_degrees := 1.6
@export var spread_aim_degrees := 0.35

@export_group("Feel")
@export var recoil_degrees := 4.5
@export var recoil_recovery := 0.7  ## fraction of the kick the view settles back
@export var aim_fov := 58.0
