class_name CoachFightTuning
extends Resource
## The coach heist after the hit (#815; config/coach_fight.tres): how the Baron's guards come out of
## the wreck and how hard they fight, and the strongbox. CoachFight reads them; Sean tunes them.

@export_group("Dazed")
## Thrown about inside, each man lies dazed this long (s) at least, plus up to `daze_spread` more
## (seeded), plus each hard knock on his head (OutlawBrain.head_stun_seconds), at most `daze_max`.
@export var daze_min := 4.0
@export var daze_spread := 5.0
@export var daze_max := 25.0
## The two thrown off the box onto the road (a shorter fall, in the open): this much of it.
@export var box_daze_share := 0.6

@export_group("Hurt by the hit")
## Each man's chance (the hit's seed) of something worse than bruises: a blow to a limb as the box
## throws him (HumanBody.take_blow), this hard (J). How many are hurt goes by the seed.
@export var hurt_chance := 0.2
@export var hurt_joules_min := 60.0
@export var hurt_joules_max := 140.0

@export_group("Nerve")
## A guard's nerve (hired men, paid to stand: OutlawBrain's 0.75 a hired gun), seeded in this range,
## less this much for each hard knock on the head and for being hurt in the hit.
@export var nerve_min := 0.62
@export var nerve_max := 0.85
@export var nerve_per_knock := 0.06
@export var nerve_hurt := 0.1
## The express messenger leads them (his "Hold!" holds the rest: OutlawBrain.leads).
@export var messenger_leads := true

@export_group("Out of the wreck")
## The man in the upturned door stands on the bench's end, this high over the lower side (m):
## his shoulders over the edge to shoot, below it crouched.
@export var hatch_step := 0.28
## Climbing out through it and down the far side (s).
@export var climb_seconds := 2.2
## Where they fight: within this of the cut's middle (m), and not up the ram's bank.
@export var fight_reach := 34.0

@export_group("The strongbox")
## E held this long (s) at the coach's door to haul the box out; within this reach (m) of the door.
@export var haul_hold := 2.5
@export var haul_reach := 2.4
## E held by the box (s): open the lid and take the papers, or shoulder the locked box.
@export var open_hold := 1.0
@export var shoulder_hold := 1.5
@export var box_reach := 1.6
## Carrying the box (44 kg) you walk at this share of your pace.
@export var box_pace := 0.35

@export_group("The way out")
## Won: the papers or the box, and you this far up the rimrock trail from the South Road (m),
## within `trail_wide` of it.
@export var trail_along := 15.0
@export var trail_wide := 20.0
## Lost: gone this far from the cut (m) without them (you left it).
@export var left_it := 140.0
## Lost: the coach driven this far past the ram's line, not struck (m).
@export var got_by := 50.0
