class_name PeopleTickTuning
extends Resource
## The people's tick bands (PeopleTick, more-cores step 4b; docs/briefs/more-cores.md): a man far
## from the player and from anyone in trouble ticks less often, each tick with the time he missed,
## so he walks, bleeds and looks round at the right rate. Edit config/people_tick.tres, not code.
##
## The band is chosen by distance and the camera (game state), never by frame time: a seeded fight
## is the same fight. What never slows is HumanBody.can_slow's (and his nodes'): a man in trouble,
## on the ground, getting up, on a clip, dragged; and anyone the player aims straight at.

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
## A man in the camera's view ticks one band nearer than his distance says ...
@export var seen_nearer := true
## ... the far band's too (false: a far man in view still ticks far). Past 60 m a man is ~15 of the
## 720 lines tall, and a walk's step between two far ticks (every 4th: 15 a second) is under one
## of them: nothing to see, and it was most of what a far man cost (#881: the street's far men are
## in view down it, so they ticked every 2nd, half a near man, not a quarter).
@export var seen_nearer_far := false
## Within this angle (degrees) of the middle of the view (where the gun points): every tick, at any
## distance ...
@export var aim_cone_deg := 8.0
## ... while you aim down the sights (true), or whenever (false). Not aiming, a man in the cone is
## only in view (`seen_nearer`): with the revolver drawn as you walk, the far men down the street
## sat in the cone and ticked every tick (#881).
@export var aim_needs_sights := true
## A calm man (`HumanBody.tick_calm`) looks at another calm man only every this many of his looks
## (Senses), with the time between: their awareness of each other builds as fast, only noticed up
## to a look (0.12 s) later. The player and anyone in or near trouble are looked at every look.
## The street's 25 townsfolk looking at each other were most of the senses' time (#881). 1: off.
@export var calm_look_every := 2
