class_name FallTuning
extends Resource
## Falls from height (issue #759; Sean's table on #762, "yes to all"): what a landing does to a man
## and to the player. Edit config/falls.tres, not code.
##
## The landing's energy is his whole body's: his weight times the speed his middle (the pelvis)
## was coming down as it began, less what he still has once it's over (going on through a roof he
## keeps most of it). A share of that hurts him (`injury_share`; the rest goes into his own give,
## the bend of his joints and the ground's). It's shared over the parts that stop: the first down
## (`lead_share`, by how hard each stops) and the rest by theirs. From the parts that land first,
## the load goes on along the spine: feet first into the low back (`spine_share`), head first into
## the neck (`neck_share`). Each blow goes through HumanBody.take_blow (Physiology.blow and its
## thresholds, PhysiologyTuning.blunt), the axial loads through Physiology.axial.
##
## References for the table these were tuned to (the ragdoll lab's group FH, 20 drops a cell;
## experiments/physics_lab/results/2026-11-10_falls/): Lapostolle et al., Crit Care Med 2005;33:1239
## (height and the part that lands first both predict death); Atanasijevic et al., J Forensic Sci
## 2005;50:608 (head injuries characteristic of fatal falls under ~7 m); Warner & Demling, Ann Emerg
## Med 1986;15:1088 (two storeys or less mostly bones, three or more inside injuries, six onto a hard
## surface nearly all die); Smith et al., Trauma 2017 (half die from ~14.8 m); CDC field triage,
## MMWR 2012;61(RR-1) (a fall over 20 ft is a trauma-centre fall).

@export_group("When a fall counts")
## His middle coming down at least this fast (m/s) as he lands: about 1.5 m of fall (Sean's line on
## #762). A man shot where he stands falls over at less, and takes nothing new from it.
@export var min_speed := 5.4
## The landing's speed is the height he came down from (his middle's, from where he was last
## slow: `_step_fall`), as gravity alone would give it, or the speed he had if that's more: his
## ragdoll's damping (HumanBody's linear_damp, part of how he falls) takes ~20% off by 22 m that
## the air wouldn't.
## A part that stops this much faster than gravity would in a tick (m/s) has landed.
@export var land_dv := 3.0
## The landing lasts this long from its first touch (s): the parts that stop in it share it.
@export var window := 0.3

@export_group("What it does to him")
## The share of the landing's energy that hurts him.
@export var injury_share := 0.2
## Of that, the share taken by the parts that land first (those touching the ground as it begins:
## they carry the body behind them); the rest goes to the parts that land after. Each share is
## split by how hard each part stops.
@export var lead_share := 0.75
## Feet first his legs give (ankles, knees, hips bend under him): the parts that land first take
## this share instead. Flat, nothing is stacked over the first parts: each part takes its own stop.
@export var feet_lead_share := 0.5
## Feet first: this share of the landing's hurt goes on up his legs, a blow to his pelvis and the
## load on his low back (Physiology.axial &"spine").
@export var spine_share := 0.65
## Head first: this share of what his head takes goes into his neck.
@export var neck_share := 0.8
## Feet first, the whole body's stop is spread over his legs' give: the landing's hurt, and the
## aorta's load (Physiology.axial), are this share of it.
@export var feet_soften := 0.75
## Below this (J) a part's blow is nothing (a bump).
@export var least_blow := 20.0

@export_group("The player")
## You always land on your feet: your weight (kg), and how a feet-first landing shares itself past
## your feet (the falls lab's feet-first drops from 3 m up, measured 2026-11-10, head and arms left
## out: you stay on your feet): segment region -> share of the rest.
@export var player_mass := 80.0
@export var player_rest := {"thigh": 0.26, "chest": 0.22, "pelvis": 0.19, "abdomen": 0.16, "shin": 0.14}
