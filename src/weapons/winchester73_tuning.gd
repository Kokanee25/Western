class_name Winchester73Tuning
extends Resource
## Every number about the Winchester 1873 rifle (24" octagon barrel, 15-round tube, .44-40).
## Edit config/winchester73.tres, not code. All PROPOSED (#734 step 2, 2026-11-10): set from the
## real gun where a figure was reachable, the rest estimated from the mechanism and the coach gun's
## feel, until Sean plays it (#777).

@export_group("Handling (seconds)")
## The lever's stroke, out and back. A practised hand works an 1873's lever in about a third of a
## second each way (est.: period exhibition shooters fired 15 in well under 10 s, aimed).
@export var lever_open_time := 0.2
@export var lever_close_time := 0.18
## The lever held open for at least this long, when Q is only tapped (the whole stroke in one go).
@export var lever_min_open := 0.08
## After a shot, the hand off the trigger and back into the loop.
@export var fire_recovery := 0.1
## Thumbing the hammer back to full cock, or easing it down to half cock (both hands on it).
@export var hammer_time := 0.3
@export var half_cock_time := 0.45
## One round into the tube through the gate: picked from the belt, turned, its nose pressed against
## the gate, thumbed in (est.: ~1.5 s a round for an unhurried hand, under 1 s practised).
@export var gate_load_time := 1.1
## Bringing the rifle round from its sling to the hands, and back.
@export var draw_time := 0.75
## Raising it from the low ready to the shoulder, cheek on the comb, the front blade into the
## notch (the pose follows over this; the sights aren't settled before it).
@export var shoulder_time := 0.32

@export_group("Ammunition")
## The tube under the barrel (published: 15 on the 24" rifle) plus one in the chamber.
@export var tube_capacity := 15
## How it's carried: the tube full, the chamber empty, the hammer down (the safe way to carry a
## lever gun; work the lever to chamber one).
@export var start_tube := 15
@export var start_chambered := false
## Chance a cartridge fails to fire (black powder, old primers): the revolver's.
@export var misfire_chance := 0.01

@export_group("Ballistics")
## .44-40 (.44 WCF), the 1873's own: 40 grains of black powder behind a 200-grain lead bullet. From
## a 24" rifle barrel about 1,300 ft/s (#734: ~400 m/s), against the Colt's ~1,000 ft/s from 7.5".
@export var muzzle_velocity := 400.0  ## m/s
@export var bullet_mass := 0.013  ## kg (200 grain)
@export var bullet_diameter := 0.0109  ## m (.429")
## A flat-nosed lead bullet against the G1 standard (ballistic coefficient ~0.13: sectional density
## 0.155 / 0.13): drag between the Colt's round-nose .45 and a ball.
@export var form_factor := 1.2
## The range the buckhorn is set for (100 yards: the rifle's usual zero). Closer in the ball is a
## little high on your line of sight, a few centimetres at 30-60 m (a rope is vertical: it doesn't
## matter there; a man's head does).
@export var zero_distance := 91.4
## Accuracy: random cone half-angle in degrees on top of the sway. A rifle's own group (about 3
## minutes of angle across with iron sights and black powder: 0.025 degrees each way) shouldered;
## from the hip the hands hold it nowhere near your line of sight.
@export var spread_aim_degrees := 0.025
@export var spread_hip_degrees := 2.6
## How much it wanders against a revolver at arm's length (WeaponViewmodel.sway_factor): shouldered,
## cheek on the comb, the long sight radius steadies it; from the hip it's a long heavy gun held
## out by your hands alone (more than the coach gun's 0.75).
@export var sway_aimed := 0.45
@export var sway_hip := 1.25
## How much of the hand's fine shake reaches the muzzle shouldered (WeaponViewmodel.shake_factor):
## the stock in the shoulder and the cheek on the comb damp it (est.).
@export var shake_aimed := 0.35
## The muzzle blast's joules into the first thing it touches, gone by `blast_reach` m (the Colt's 300).
@export var blast_joules := 420.0
@export var blast_reach := 1.8

@export_group("Feel")
## The kick (GunKick; see RevolverTuning). A 9 lb rifle and a .44-40: a firm, slow shove into the
## shoulder, far less than the coach gun. From the hip it rides up in your hands; shouldered the
## barrel stays with your eye (`kick_aimed`) and your view takes it.
@export var kick_degrees := 11.0
@export var kick_aimed := 0.4
@export var kick_rise := 0.09
@export var kick_damping := 0.65
@export var kick_variation := 0.1
@export var kick_side_degrees := 1.2
@export var kick_roll_degrees := 1.5
@export var kick_back := 0.04
@export var view_kick_degrees := 2.2
@export var view_kick_shouldered := 4.0
@export var view_kick_rise := 0.1
@export var view_kick_back := 0.025
@export var view_climb_degrees := 0.8
@export var aim_fov := 60.0
