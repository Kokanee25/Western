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
## How far a burning planted stick's hiss carries (m): men that near on its side of the wall hear
## it (Senses, `fuse`: a wall stops it). Sean, issue #537: only really close, so a stick set on a
## wall is a surprise to the men inside.
@export var fuse_heard := 3.0
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
## A loose body the blast would move slower than this (m/s) isn't moved or woken: a piece of rubble
## 17 m off gets ~0.07 m/s, and a third stick woke ~1,200 of them for the physics (#538).
@export var min_throw := 0.15
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
## The bang comes through before your ears give (#596: the crack was lost under the muffle): the
## world stays clear this long after a blast reaches you, then dulls over `ear_ease_s`; the
## ringing starts with the dulling.
@export var ear_hold_s := 0.3
@export var ear_ease_s := 0.5
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

@export_group("On you")
## What a blast does to you that isn't a wound (#596 step 2), each by the pressure at your ear
## (reflected kPa), on a log scale: nothing at `*_from_kpa`, all of it at `*_full_kpa` (150: both
## eardrums burst, knocked senseless, 2.5 m from a stick on the ground). A stick on the ground
## gives ~150 kPa at 2 m, ~34 at 5 m, ~11 at 12 m, ~4 at 30 m. PROPOSED: Sean sets them by ear and
## eye from the films. Noise-induced temporary threshold shift (the dull world) and tinnitus (the
## whine) after impulse noise last seconds to hours in life; these are a game's few seconds.
##
## The world dulled (a low-pass on what you hear): the cutoff falls to `muffle_floor_hz` at full,
## less far off (20 kHz x (floor / 20 kHz)^share), held, then given back over the last
## `muffle_recover` of `muffle_s` x share seconds.
@export var muffle_from_kpa := 3.0
@export var muffle_full_kpa := 150.0
@export var muffle_s := 9.0
@export var muffle_floor_hz := 300.0
@export var muffle_recover := 0.6
## Ringing ears: `ringing_max` x share seconds of a high whine, its top `ring_level` (linear) x
## share², fading as the square of the time left. On its own bus, past the ears' filter: it's in
## your head.
@export var ring_from_kpa := 3.0
@export var ring_full_kpa := 150.0
@export var ringing_max := 24.0
@export var ring_level := 0.35
## The view shaken (the camera only: your aim stays where it was): `shake_deg` x share^1.5 at its
## start, a kick away from the blast of `shake_jolt_deg` x share^1.5 springing back, over
## `shake_s` x (0.35 + 0.65 share) seconds, its wobble at `shake_hz`. Felt out to
## `felt_reach_x` x the blast's reach (a stick's 17.8 m: x2.5 is ~45 m), past where it touches you.
@export var shake_from_kpa := 2.0
@export var shake_full_kpa := 150.0
@export var shake_deg := 3.0
@export var shake_jolt_deg := 4.0
@export var shake_s := 1.6
@export var shake_hz := 11.0
@export var felt_reach_x := 2.5
## Dirt and grit on the screen up close (an overlay: specks and smudges, more on the blast's side,
## a brown wash of dust over it), cleared speck by speck over `grit_clear_s` x (0.5 + 0.5 share).
@export var grit_from_kpa := 25.0
@export var grit_full_kpa := 150.0
@export var grit_clear_s := 4.0
@export var dust_wash := 0.6

@export_group("Thrown through the air")
## Men close to a stick thrown up and back in an arc (issue #596 step 3b, Sean 2026-11-03: his
## taste for fun physics over the real push, which only knocks a man over). 0 is the real blast
## alone (the game before 3b); 1 the proposed targets: from a stick on the floor 1 m off he's
## thrown 3-6 m with the arc's top 1-2 m up, 3 m off he's off his feet a metre or two, 6 m off he's
## knocked down as before. PROPOSED: Sean picks the setting by eye from the films.
@export var blast_lift := 0.0
## The lift's speed (m/s) at blast_lift 1 right by the charge, before it falls away with distance.
@export var lift_speed := 7.5
## ... halved at this scaled distance (m per cube root of kg: a stick on the ground, 0.36 kg as it
## hits, at ~2.4 m from his chest), and falling away as the scaled distance to this power (steep:
## close in it's nearly all of it, two or three times out nearly none).
@export var lift_reach := 3.4
@export var lift_falloff := 4.0
## Degrees above level he's thrown at, from a charge well below his chest (one at his chest
## throws him level; one over him, no lift up).
@export var lift_angle := 55.0
## His turn in the air (rad/s at the full lift): head back and feet up (the tumble), with this much
## either side drawn by his seed, and a little twist about the up axis. Half a turn or so over the
## flight, not a pinwheel.
@export var lift_tumble := 2.4
@export var lift_tumble_spread := 0.3
@export var lift_twist := 0.8
## The landing hurts: a part that stops this much faster than gravity would (m/s in a tick) takes a
## blow (HumanBody.take_blow, the bruises and broken bones of a fall) of this share of its own
## kinetic energy, watched for this long (s) after he's thrown, once a part.
@export var land_dv := 3.0
@export var land_share := 0.5
@export var land_watch := 3.0
## A body part torn open: past this (reflected) pressure at the part, this many joules per kPa more.
@export var open_kpa := 800.0
@export var open_joules_per_kpa := 1.2
## Limbs torn off at the joint above: reflected kPa at the part's skin (Sean's pick, #220: with
## the ground, a foot or shin off within about a metre of a stick).
@export var sever_kpa := {
	"hand": 1500.0, "foot": 1500.0, "forearm": 2600.0, "shin": 2600.0, "upper_arm": 4500.0, "thigh": 4500.0,
}
