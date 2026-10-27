class_name PeopleTickTuning
extends Resource
## The people's tick bands (PeopleTick, more-cores step 4b; docs/briefs/more-cores.md): a man far
## from the player and from anyone in trouble ticks less often, each tick with the time he missed,
## so he walks, bleeds and looks round at the right rate. Edit config/people_tick.tres, not code.
##
## The band is chosen by distance and the camera (game state), never by frame time: a seeded fight
## is the same fight. What never slows is HumanBody.can_slow's (and his nodes'): a man in trouble,
## on the ground, getting up, on a clip, dragged; and anyone the player looks straight at.

## Past this far (m) from the player and from everyone who can't slow: the middle band ...
@export var near_m := 25.0
## ... and past this, the far band.
@export var far_m := 60.0
## A band is left only this far (m) past its edge, and come back to only this far inside it, so a
## man walking along an edge doesn't flicker between two.
@export var margin_m := 3.0
## How often each band ticks: every Nth physics tick (near: every one).
@export var middle_every := 2
@export var far_every := 4
## A man in the camera's view ticks one band nearer than his distance says.
@export var seen_nearer := true
## Within this angle (degrees) of the middle of the view (where the gun points): every tick, at any
## distance.
@export var aim_cone_deg := 8.0
