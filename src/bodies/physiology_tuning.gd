class_name PhysiologyTuning
extends Resource
## The numbers behind bleeding, shock, pain, breathing and adrenaline (config/physiology.tres).
## Time is in real seconds at normal game speed (a game day is 45 real minutes, so one game hour is
## 112.5 s). Bleed rates for arteries and organs live with the anatomy in config/anatomy.json.

@export var blood_ml := 5000.0
## Share of blood lost at which he's pale and weak / passes out / dies.
@export var shock_at_loss := 0.2
@export var unconscious_at_loss := 0.4
@export var death_at_loss := 0.5
## Healthy body slowly makes blood back (ml per second).
@export var blood_regen := 0.004

## Bleeding from the wound track itself (muscle, small vessels), ml/s per cm of track.
@export var flesh_bleed_per_cm := 0.035
## Bleeds up to this rate clot on their own; arteries bigger than this keep pumping.
@export var clot_max_rate := 4.0
## Seconds for a clotting bleed to slow to about a third.
@export var clot_time := 150.0
## Direct pressure keeps this share of the bleed going.
@export var pressure_factor := 0.25
## A tight tourniquet stops arterial bleeding below it completely.
@export var tourniquet_factor := 0.0

## Pain: each wound adds some; it arrives over a few seconds and adrenaline hides most of it.
@export var pain_bone := 0.55
@export var pain_organ := 0.35
## A holed gut hurts more than anything (on top of pain_organ).
@export var pain_gut := 0.6
@export var pain_finger := 0.3
## Grazes and cuts sting more than their depth deserves; grazes bleed a bit less than a hole.
@export var pain_graze := 0.18
@export var graze_bleed := 0.7

## Blunt blows (falling timber, falls, kicks), in joules on the part hit: what it takes to do each
## kind of harm. Past the threshold the chance rises with the energy.
@export var blunt := {
	"concussion": 45.0, "skull": 220.0, "ribs": 90.0, "lung": 260.0, "belly_organ": 160.0,
	"pelvis": 380.0, "thigh": 300.0, "shin": 190.0, "upper_arm": 150.0, "forearm": 110.0,
	"hand": 70.0, "foot": 90.0,
}
## Seconds out cold per 10 J over the concussion threshold (with at least a few).
@export var concussion_seconds_per_10j := 1.5
## A burst spleen or liver bleeds inside at this share of the organ's full rate: pale, cold, and
## nothing to see.
@export var internal_bleed_share := 0.6

## Burns: pain per unit of burn, and how much burn kills.
@export var pain_burn := 0.5
@export var burns_fatal := 7.0
@export var pain_per_cm := 0.012
@export var pain_onset := 3.0
## Adrenaline: rises when hurt or in a fight, fades over a couple of minutes, masks pain.
@export var adrenaline_per_wound := 0.6
@export var adrenaline_fade := 150.0
@export var adrenaline_masks := 0.45
## Felt pain above this and he can't do anything but hold the wound; far above and he faints.
@export var pain_disabling := 0.9
@export var pain_faint := 1.8

## A ball through a muscle tears about this much of it (1 = useless).
@export var muscle_tear := 0.55
@export var pain_muscle := 0.15
@export var pain_nerve := 0.45
## Bleeding slows as blood pressure falls: at no pressure it's this share of the full rate.
@export var bleed_at_no_pressure := 0.5
## Heart rate at rest, and how far fear and blood loss drive it up (beats per minute).
@export var resting_heart_rate := 72.0
@export var adrenaline_heart_rate := 45.0
@export var shock_heart_rate := 85.0
## Blood in a holed windpipe takes this much of the breath.
@export var airway_capacity_lost := 0.3

## Knocked off his feet by the hit itself: no chance below `knockdown_energy` joules left in the
## body, rising by `knockdown_per_100j` per 100 J above it, plus `knockdown_severe` if it broke
## bone or tore something vital; never more than `knockdown_max`. Torso, hips, thighs and head only.
@export var knockdown_energy := 180.0
@export var knockdown_per_100j := 0.12
@export var knockdown_severe := 0.15
@export var knockdown_max := 0.45
## A buckshot pellet rolls for its own knockdown at this share of a ball's chance (a charge
## lands several at once, so without it buckshot at range would drop nearly everyone).
@export var knockdown_pellet_share := 0.3

## Breathing: a holed lung collapses over this long and takes this share of the breath with it.
@export var lung_collapse_time := 35.0
@export var lung_capacity_lost := 0.55
## Oxygen falls when breath capacity is below what the body needs, recovers above.
@export var oxygen_need := 0.5
@export var oxygen_rate := 0.02
## Can't run with breath below this; passes out with oxygen below this.
@export var run_breath := 0.7
@export var faint_oxygen := 0.3
## Breaking the neck stops the breathing: out at once, dead in this long.
@export var neck_death_time := 120.0

## Gut shot: the bowel leaks and the belly poisons over game hours if no doctor.
@export var gut_death_game_hours := 30.0
@export var game_hour_seconds := 112.5
