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
## Planting (issue #506): how far off a wall can be (m from your eye) for E held to set a stick at
## its foot, how long setting it down takes (s), and the fuse it gets when you let go (s: time to
## get round a corner).
@export var plant_reach := 2.2
@export var plant_time := 0.6
@export var plant_fuse_seconds := 5.0
## How far a burning planted stick's hiss carries (m, halved through a wall): men that near hear it
## (Senses, `fuse`).
@export var fuse_heard := 9.0
## Chance a bullet through a stick sets it off (usually it just tears the paper).
@export var bullet_detonation_chance := 0.25
## Other sticks this close go off with it.
@export var sympathetic_kpa := 2000.0

## On (or just over) the ground a charge hits as this many times its TNT (Blast.effective_kg: a
## hemisphere, not a sphere; 2 for a perfect reflector, ~1.8 for earth), fading to 1 by this
## height (m per cube root of kg: 35 cm for a stick).
@export var ground_factor := 1.8
@export var ground_height := 0.6

@export_group("Structures")
## A shock reflected off a face square to it hits 2x as hard when weak, rising toward this when
## strong (8 for an ideal gas; Blast.reflection()).
@export var reflection_strong := 8.0
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
## How far timber can break (m per cube root of kg): the members inside this are each worked
## through the breaking rule, found by a query of their own so none near the charge is ever left
## out; beyond it only glass, people and loose things are looked at. A stick's rule breaks nothing
## past ~2 m anywhere on Main Street (the breakage lab, 2026-10-21); this is 3.5 m for one stick.
@export var break_reach_per_cbrt_kg := 6.0

@export_group("Craters")
## A charge on the dirt digs a crater D = crater_k x cbrt(kg) across (m; kg TNT): Kinney and
## Graham's regression over ~200 surface explosions ("Explosive Shocks in Air", 1985; spread about
## +-30%), as Ambrosini, Luccioni, Danesi, Riera and Rocha (Shock Waves 12, 2002) checked it for
## charges at ground level (quoted, the papers not read: docs/briefs/dig-ground.md). A stick: 0.47 m.
@export var crater_k := 0.8
## Its depth, of its diameter (0.25-0.30 for small surface charges, as later papers quote it).
@export var crater_depth_ratio := 0.27
## Gone off above the dirt it digs less (charges above the ground make smaller craters: Ambrosini
## et al.), none from this high (m per cbrt kg: 18 cm for a stick). A stand-in, straight down to none.
@export var crater_height := 0.3
## Of the earth it takes, the share packed into the crater's floor and walls rather than thrown.
@export var crater_packed := 0.3
## The lip: loose earth in a ring from the crater's edge, highest at lip_peak x its radius, out to
## lip_out x it (the published crater profiles' shape, scaled).
@export var lip_peak := 1.25
@export var lip_out := 2.0
## Of the earth thrown, the share that flies as clods (the rest lies in the lip), in this many, at
## these speeds (m/s); each turns back into loose earth where it comes to rest on the dirt.
@export var clod_share := 0.25
@export var clods := 16
@export var clod_speed := Vector2(3.0, 8.0)
## Dry earth as dug (kg/m³, packed): a clod's weight.
@export var earth_density := 1600.0

@export_group("Fire")
## The fireball: this radius per cube root of kg TNT; people in it are burnt (and wood in it
## catches at `ignite_chance`).
@export var fireball_per_cbrt_kg := 1.4
## The flash is over in a moment: the chance a board in it catches. 0 since 2026-10-28 (Sean: a
## blast lights nothing itself; a fire after one comes from a lit lamp it smashed or knocked down,
## OilLamp.smash). Was 0.12: every stick in the saloon lit its floor.
@export var ignite_chance := 0.0
## Wood it lights catches this many seconds after the flash (seeded within the range), out of the dust.
@export var ignite_delay := Vector2(1.0, 4.0)
@export var burn_in_fireball := 1.2

@export_group("People")
## Eardrums: none burst below the first, all by the second (kPa).
@export var eardrum_kpa := 35.0
@export var eardrum_all_kpa := 140.0
## Ringing ears: seconds per kPa at the ear, most.
@export var ringing_per_kpa := 0.5
@export var ringing_max := 40.0
## Blast lung: bruised from the first, both holed and bleeding from the second, by the reflected
## pressure at his chest (since 2026-10-28, issue #220; was 250 / 700 against the side-on). Bowen,
## Fletcher and Richmond's curves for a 70 kg man ("Estimate of Man's Tolerance to the Direct
## Effects of Air Blast", DASA-2113, 1968), which take the reflected pressure for a man facing the
## blast, at a stick's ~1 ms pulse: the threshold of lung injury ~400 kPa, half killed ~1,000 (the
## short-pulse end of the curves, where it takes several times the long-pulse 100 / 350; Bass,
## Rafaels and Salzar, "Pulmonary injury risk assessment for short-duration blasts", J Trauma 65,
## 2008, refit them the same way). Quoted from memory: the papers' hosts are blocked here (#227).
@export var lung_kpa := 400.0
@export var lung_severe_kpa := 1000.0
## Knocked senseless from this pressure at the head.
@export var concussion_kpa := 150.0
## Knocked off his feet by this much side-on pressure at his chest (the blast wind, not its
## reflection), or by being pushed faster than this (m/s).
@export var knockdown_kpa := 35.0
@export var knockdown_speed := 0.8
## The blast wind pushes a body with this share of impulse × its frontal area (0.7 m²).
@export var throw_factor := 2.5
## A body part torn open: past this (reflected) pressure at the part, this many joules per kPa more.
@export var open_kpa := 800.0
@export var open_joules_per_kpa := 1.2
## Limbs torn off at the joint above: reflected kPa at the part's skin (Sean's pick, #220: with
## the ground, a foot or shin off within about a metre of a stick).
@export var sever_kpa := {
	"hand": 1500.0, "foot": 1500.0, "forearm": 2600.0, "shin": 2600.0, "upper_arm": 4500.0, "thigh": 4500.0,
}
