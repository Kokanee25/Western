class_name Winchester73Tuning
extends Resource
## Every number about the Winchester Model 1873 rifle (24" octagon barrel, 15-round tube, .44-40).
## Edit config/winchester73.tres, not code. Every number here is **proposed** (#777, 2026-11-10):
## set from period figures and the gun lab's rig where there are any, estimated where not, until
## Sean has played it. The lever's travel and the parts' moves are the rig's (assets/weapons/
## win73_24_rig.json); these are the times and the ballistics.

@export_group("Handling (seconds)")
## The lever thrown open (the bolt back, the case out, the hammer cocked, the carrier up) and
## brought home again (the round into the chamber). A practised hand works it in about a third of
## a second; the shot leaves the gun `fire_recovery` before the hand can start the next stroke.
@export var lever_open_time := 0.18
@export var lever_close_time := 0.16
@export var fire_recovery := 0.15
## The hammer thumbed from half cock to full (no lever: the round stays).
@export var thumb_cock_time := 0.25
## The hammer eased down to half cock: thumb on the spur, the trigger squeezed, let down slowly.
@export var half_cock_time := 0.6
## One round from the belt pushed through the loading gate into the tube; and the gun brought round
## first so the gate's to you (once, at the start of a loading).
@export var gate_round_time := 0.75
@export var turn_to_load_time := 0.35
## Off the sling and into both hands (and back onto it).
@export var draw_time := 0.9
## From the hip to the shoulder with your eye down the sights (`aiming` counts once it's up).
@export var shoulder_time := 0.4
## Holding the lever key this long with a round chambered and the hammer back eases it down to half
## cock instead of working the lever.
@export var half_cock_hold := 0.4

@export_group("Ammunition")
## The tube under the barrel (a 24" rifle's: 15), and how many are in it when you're given it. The
## chamber starts empty: work the lever to load one (how it was carried in a scabbard or on a sling).
@export var magazine := 15
@export var start_tube := 15
## Chance a cartridge fails to fire (black powder, old primers).
@export var misfire_chance := 0.01

@export_group("Ballistics")
## .44-40 (.44 WCF): 40 grains of black powder behind a 200-grain lead flat-nosed bullet, about
## 1,300 ft/s from a 24" barrel (#734: ~400 m/s); the same cartridge as the Colt.
@export var muzzle_velocity := 400.0  ## m/s
@export var bullet_mass := 0.01296  ## kg (200 grain lead)
@export var bullet_diameter := 0.0109  ## m (.429")
## Against the G1 standard projectile: sectional density 0.155 / a ballistic coefficient of ~0.15
## for the blunt flat nose.
@export var form_factor := 1.03
## The range the buckhorn is regulated for (50 yards): a touch high nearer, a little low beyond.
@export var zero_distance := 45.7
## The rifle itself (rifled, a good barrel, black powder): a cone of this half-angle round where it
## points, about 2.4 MOA across (an 1873 with good ammunition shot 2-3" at 100 yards). From the hip, not looking down the sights, far wider.
@export var spread_aim_degrees := 0.02
@export var spread_hip_degrees := 2.5

@export_group("Steadiness")
## How much it wanders against a revolver held out at arm's length (WeaponViewmodel.sway_factor):
## shouldered, two hands and your cheek on the comb, the weight out front; from the hip, nine pounds
## held out in front of you and no sights.
@export var sway_aimed := 0.3
@export var sway_hip := 1.5
## The fine shake, against the revolver's (the stock against your shoulder and cheek damps it).
@export var tremor_aimed := 0.3

@export_group("Feel")
## The kick (GunKick; the names RevolverTuning's). A .44-40 in a nine-pound rifle: ~6 J of recoil, a
## push, about a quarter of the coach gun's. Shouldered, your view takes it.
@export var kick_degrees := 9.0
@export var kick_aimed := 0.35
@export var kick_rise := 0.09
@export var kick_damping := 0.6
@export var kick_variation := 0.1
@export var kick_side_degrees := 0.8
@export var kick_roll_degrees := 1.0
@export var kick_back := 0.035
@export var view_kick_degrees := 1.6
@export var view_kick_shouldered := 3.2
@export var view_kick_rise := 0.1
@export var view_kick_back := 0.02
@export var view_climb_degrees := 0.5
@export var aim_fov := 55.0
