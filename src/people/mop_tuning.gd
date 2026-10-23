class_name MopTuning
extends Resource
## The barkeep's mopping's dials (MopFloor; config/mop.tres): when, where and how he mops, in numbers,
## not keyframes (CLAUDE.md "Motion"). Seconds, metres, hertz, grams, millilitres.

@export_group("When")
## He looks at the floor this often (s), this far round his post (m).
@export var look_every := 2.0
@export var area := 7.0
## He mops when it holds this much (a score: dirt g x `per_dirt` + spilt ml x `per_liquid` + blood ml x
## `per_blood`), and only with nobody within `quiet` m of him.
@export var mess_to_start := 1.0
@export var per_dirt := 0.25
@export var per_liquid := 0.01
@export var per_blood := 0.2
@export var quiet := 4.0
## A stretch is done when what's left in it scores under this; the go when the whole floor does, or
## after `most_seconds`.
@export var clean_enough := 0.08
@export var most_seconds := 240.0
## After a go, this long (a range) before he looks again.
@export var rest_between := Vector2(120.0, 300.0)

@export_group("Mopping")
## A stretch: this wide side to side (m) and this deep (m), worked back toward him.
@export var stroke_width := 0.9
@export var stretch_depth := 0.9
## Side-to-side strokes a second, and how fast he works back along a stretch (m/s).
@export var stroke_hz := 0.55
@export var work_back := 0.12
## The mop's foot over the boards (m): low enough that its strands drag.
@export var foot_above := 0.05
## He stands this far behind the mop's foot (m), his top hand here (his space: right, up, back).
@export var stand_back := 0.85
@export var top_hand := Vector3(-0.06, 1.12, -0.26)
## His lower hand this far down the handle from the top one (m).
@export var hands_apart := 0.38
## His trunk turns into each stroke (degrees) and leans over the work (degrees).
@export var twist := 14.0
@export var lean := 10.0

@export_group("The bucket")
## Back to the bucket when the mop's this dry (a share of wrung) or this dirty (g of dirt a ml).
@export var dip_when_dry := 0.6
@export var dip_when_dirty := 0.02
## In its water (s), then pressed out over it (s).
@export var dip_seconds := 1.6
@export var press_seconds := 1.4
## The bucket's moved along when the work's further than this from it (m).
@export var bucket_reach := 1.6
## Its water this murky (0..1) and he empties it outside and fills it at the trough.
@export var change_water := 0.75

@export_group("Moving")
@export var walk_speed := 1.1
@export var step_speed := 0.5
## Each way's give-up (s): somewhere he can't get to.
@export var give_up := 20.0
