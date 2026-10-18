class_name ShotgunTuning
extends Resource
## Every number about the double-barrelled coach gun. Edit config/shotgun.tres, not code.
## Defaults are a 12-bore side-by-side hammer gun with 20" cylinder-bored barrels, loaded with
## black-powder buckshot in brass shells (the stagecoach guard's gun).

@export_group("Handling (seconds)")
@export var cock_time := 0.28
@export var fire_recovery := 0.12
@export var open_time := 0.45
@export var close_time := 0.35
@export var extract_time := 0.35
@export var load_time := 0.55
@export var draw_time := 0.6

@export_group("Ammunition")
## Shells carried in the coat pockets, and how many you start with.
@export var pocket_capacity := 16
@export var start_pocket := 12
## Chance a shell fails to fire.
@export var misfire_chance := 0.01

@export_group("Ballistics")
## One shell: nine 00 buckshot pellets (8.4 mm, 3.5 g each) at about 400 m/s with black powder,
## ~280 J each and ~2,500 J the lot.
@export var pellets := 9
@export var pellet_mass := 0.0035  ## kg
@export var pellet_diameter := 0.0084  ## m
## A 12-bore paper shell of the day: 3 drams of black powder behind nine 00 balls, about
## 1,200 ft/s from a coach gun's 20" barrels. Round balls just over the speed of sound: they shed
## speed fast (their drag peaks there).
@export var muzzle_velocity := 365.0  ## m/s
## The range its bead is regulated for (both barrels shoot to the bead at 40 yards).
@export var zero_distance := 36.6
## The pattern: each pellet leaves this many degrees off the line at one standard deviation,
## capped at 2.5 deviations. A worn cylinder bore throws buckshot into well over a metre at
## 25 m (only a few pellets find a man), a hand or two across a room, one ragged hole at arm's
## length.
@export var pattern_degrees := 0.85
## Aim wobble added to the whole charge: shouldered, and from the hip.
@export var spread_aim_degrees := 0.3
@export var spread_hip_degrees := 2.2
## Up close the charge hasn't opened yet: the pellets arrive as one mass with the wad and the
## muzzle blast behind them and tear one big hole. Joules into the first thing it touches at
## contact, fading to nothing by `blast_reach` metres; split between the pellets.
@export var blast_joules := 1600.0
@export var blast_reach := 2.5

@export_group("Feel")
## The kick (GunKick; see RevolverTuning). From the hip the gun rides up in your hands; shouldered
## it shoves you, so the barrels stay with your eye (`kick_aimed`) and your view takes it
## (`view_kick_shouldered`, and your head shoved back `view_kick_back` metres).
@export var kick_degrees := 15.0
@export var kick_aimed := 0.35
@export var kick_rise := 0.085
@export var kick_damping := 0.6
@export var kick_variation := 0.1
@export var kick_side_degrees := 2.0
@export var kick_roll_degrees := 2.0
@export var kick_back := 0.06
@export var view_kick_degrees := 3.5
@export var view_kick_shouldered := 7.0
@export var view_kick_rise := 0.1
@export var view_kick_back := 0.045
@export var view_climb_degrees := 1.4
@export var aim_fov := 62.0
