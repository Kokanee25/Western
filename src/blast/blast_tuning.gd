class_name BlastTuning
extends Resource
## Dynamite and what a blast does. Edit config/blast.tres, not code.
## Pressure and impulse come from the Kinney-Graham fits for a free-air TNT burst (Kinney & Graham,
## "Explosive Shocks in Air", 1985); the injury thresholds from the usual blast-injury curves
## (eardrum rupture from ~35 kPa, lung injury from a few hundred kPa for a short pulse).

@export_group("The stick")
## An 8" stick of dynamite weighs about half a pound (0.2–0.23 kg) and hits about as hard as its
## weight of TNT.
@export var tnt_per_stick := 0.2
## Sticks carried, and how long the cut fuse burns (seconds).
@export var sticks_carried := 6
@export var fuse_seconds := 5.0
## A thrown stick leaves the hand at this speed (a quick lob .. a full throw, by how long you
## wind up), plus this much upward.
@export var throw_speed_min := 6.0
@export var throw_speed_max := 15.0
@export var throw_windup := 0.7
@export var throw_lift := 2.5
## Chance a bullet through a stick sets it off (usually it just tears the paper).
@export var bullet_detonation_chance := 0.25
## Other sticks this close go off with it.
@export var sympathetic_kpa := 2000.0

@export_group("Structures")
## Pressure on a face turned to the blast is reflected, and this much higher.
@export var reflection := 2.0
## Timber breaks when the kick the blast gives it (impulse² / 2m) passes the energy it can soak
## up bending: this share of f²/2E over its volume.
@export var absorb_factor := 0.2
## The length of a member (m) that can break on its own where a close charge hits it.
@export var local_span := 0.3
## Panes crack at this pressure (kPa).
@export var glass_kpa := 3.5
## The fastest a broken piece is thrown (m/s).
@export var max_throw := 25.0
## Splinters thrown off each board it breaks, flown as projectiles: mass (kg), size (m), and
## their speed as a multiple of the piece's own.
@export var splinters_per_member := 4
@export var splinter_mass := 0.002
@export var splinter_diameter := 0.006
@export var splinter_speed_factor := 6.0
@export var max_splinters := 40
## On the ground it throws gravel and grit, low and fast: what hurts most people near a blast
## who aren't right on it. Count, mass (kg), size (m), speed (m/s) and the highest they go
## (degrees above the ground).
@export var ejecta_count := 80
@export var ejecta_mass := 0.003
@export var ejecta_diameter := 0.006
@export var ejecta_speed := Vector2(90.0, 220.0)
@export var ejecta_elevation := 35.0
## How far the blast is reckoned (m): nothing beyond this notices (panes a bit further than this
## still crack at 3.5 kPa with more than one stick).
@export var reach_per_cbrt_kg := 25.0

@export_group("Fire")
## The fireball: this radius per cube root of kg TNT; dry wood inside it may catch, people in it
## are burnt.
@export var fireball_per_cbrt_kg := 1.4
## The flash is over in a moment: only now and then does a board in it catch.
@export var ignite_chance := 0.12
@export var burn_in_fireball := 1.2

@export_group("People")
## Eardrums: none burst below the first, all by the second (kPa).
@export var eardrum_kpa := 35.0
@export var eardrum_all_kpa := 140.0
## Ringing ears: seconds per kPa at the ear, most.
@export var ringing_per_kpa := 0.5
@export var ringing_max := 40.0
## Blast lung: bruised from the first, both holed and bleeding from the second.
@export var lung_kpa := 250.0
@export var lung_severe_kpa := 700.0
## Knocked senseless from this pressure at the head.
@export var concussion_kpa := 150.0
## Knocked off his feet by this much pressure, or by being pushed faster than this (m/s).
@export var knockdown_kpa := 35.0
@export var knockdown_speed := 0.8
## The blast wind pushes a body with this share of impulse × its frontal area (0.7 m²).
@export var throw_factor := 2.5
## A body part torn open: past this pressure at the part, this many joules per kPa more.
@export var open_kpa := 800.0
@export var open_joules_per_kpa := 1.2
## Limbs torn off at the joint above: kPa at the part's centre.
@export var sever_kpa := {
	"hand": 1500.0, "foot": 1500.0, "forearm": 2600.0, "shin": 2600.0, "upper_arm": 4500.0, "thigh": 4500.0,
}
