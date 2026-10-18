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
## A Colt Single Action Army, 7½" barrel, the .45 Colt service load of 1874–: 40 grains of black
## powder behind a 255-grain lead bullet, about 900 ft/s (Frankford Arsenal's figures).
@export var muzzle_velocity := 274.0  ## m/s
@export var bullet_mass := 0.0165  ## kg (255 grain lead)
@export var bullet_diameter := 0.0114  ## m
## Its blunt round-nosed bullet against the G1 standard projectile (ballistic coefficient ~0.14:
## sectional density 0.178 ÷ 0.14): keeps about nine tenths of its speed over 100 m.
@export var form_factor := 1.27
## The range its fixed sights are regulated for (25 yards): the ball rises a little above your
## line of sight, crosses it here, and falls away below it beyond (hold high at long range).
@export var zero_distance := 22.9
## Accuracy: random cone half-angle in degrees.
@export var spread_hip_degrees := 1.6
@export var spread_aim_degrees := 0.35

@export_group("Feel")
## The kick (GunKick): how far the muzzle climbs from the hip (degrees), reached `kick_rise`
## seconds after the shot, brought back by the hand like a spring (`kick_damping`: lower dips
## further past where it was). A .45 black-powder load is a heavy, slow shove (Sean: "should push,
## not flip"). Held out at arm's length on the sights the wrist is locked: `kick_aimed` of it.
@export var kick_degrees := 17.0
@export var kick_aimed := 0.7
@export var kick_rise := 0.085
@export var kick_damping := 0.6
## Shot to shot it's never quite the same: spread of the climb (a fraction), a little to one side
## (degrees), the gun twisting in the hand (degrees, to the right) and coming back at you (metres).
@export var kick_variation := 0.12
@export var kick_side_degrees := 1.5
@export var kick_roll_degrees := 5.0
@export var kick_back := 0.035
## Your view goes with it, less and a moment later (the shove reaching your shoulder and head), and
## doesn't quite all come back: `view_climb_degrees` stays (pull it down yourself).
@export var view_kick_degrees := 2.6
@export var view_kick_rise := 0.09
@export var view_kick_back := 0.0
@export var view_climb_degrees := 0.9
@export var aim_fov := 58.0
