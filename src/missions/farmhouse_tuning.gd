class_name FarmhouseTuning
extends Resource
## The farmhouse hostage rescue's dials (issue #520; config/farmhouse.tres): how hard it is. Sean
## tunes these; FarmhouseMission and HostageBrain read them.

@export_group("The guard and the hostage")
## Once the alarm's been raised and you're in the house, how long (s) before the guard has had
## enough and kills the hostage (after his threat). When he's the last man standing, at once.
@export var shoot_after_alarm := 20.0
## His threat: gun on the hostage, a shout; this long (s) before he fires, the pause you can use.
@export var threat_seconds := 5.0
## The fight's going badly for them (he threatens) once this many of the others are down, dead,
## given up or run.
@export var bad_fight_down := 2
## His shots into the hostage (a second if the first doesn't drop him).
@export var execute_shots := 2

@export_group("The hostage")
## He calls for help when he hears you this near (m), and not more often than every (s).
@export var call_hear := 14.0
@export var call_every := 9.0
## Cutting him loose: E held this long (s), within this reach (m) of him.
@export var free_hold := 1.6
@export var free_reach := 1.5
## Following you: how far behind he keeps (m); past this he hurries (m).
@export var follow_gap := 1.8
@export var follow_hurry := 5.0
## Out and safe: this far (m) from the house's walls.
@export var safe_from_house := 4.0
## Or this far (m) from it, whoever's still in the house.
@export var safe_away := 40.0

@export_group("The outlaws")
## Seen with your gun put away further off than `warn_close` (m from the house), they warn you off
## first; coming on after it for `warn_seconds` (s), drawing, or closer than `warn_close` is the
## alarm; past `warn_far` (m) they stand down.
@export var warn_close := 14.0
@export var warn_seconds := 8.0
@export var warn_far := 55.0
## A blast this near the house (m) is a breach: the alarm, and they turn to it.
@export var breach_reach := 18.0
## A blast at the house before any alarm (a stick set unheard: the surprise assault, issue #537):
## the men are dazed this long (s, each 0.8-1.2 of it) and don't know where you are.
@export var caught_cold := 4.0
## How far (m) off a man hearing a shot or a blast places you (his guess, not your spot).
@export var heard_error := 3.0
## The house's men hold a hostage with nowhere to run (issue #565, Sean: "the guards give up too
## easily"): this much more nerve than their own (`men`), and past it they hold on rather than
## run or give up while they're armed and not covered close (OutlawBrain._cornered_break).
@export var house_nerve := 0.25
## ... and shot down but still with it, they fight on from the floor (the gunfight lab's D+
## `floor_fight`, for them alone): the hardest of it (the scripted runs, issue #565).
@export var house_floor_fight := true
## The men, each {id, model, post (a farmhouse use point), hold ("house" or "bedroom"), nerve,
## temper, proud, leads, masked, alarm_post (where he goes on the alarm, a use point; "" stays)}.
@export var men: Array[Dictionary] = []

@export_group("The rovers")
## Men outside walking a beat before the alarm (issue #565, Sean: "it needs roving guards
## outside"): each {id, model, masked, nerve, temper, beat (a name in `beats`), start (the beat's
## stop he starts at)}. They see you and call it in (the alarm, or the warning as the house's men
## give it); a fuse they hear only within its 3 m, as anyone.
@export var rovers: Array[Dictionary] = []
## The beats: name -> its stops in order, walked round and round: each {at (a farm place:
## Farmhouse.add_places), pause (s), look [x, z] (the house's own space: what he stands watching),
## quiet (the sides of the house, as HouseDefence.place_of names them, that his beat leaves
## unwatched a while from this stop on: what a player who's watched him waits for, as the scripted
## player does)}.
@export var beats: Dictionary = {}
## On the alarm a rover falls back into the house (and fights from it with the rest) if he's
## nearer its door than this share of his distance from you; else he takes cover outside, in the
## yard (`yard_reach` m of the house), and falls back once you're in the house or he's hit.
@export var rover_fall_back := 0.7
@export var yard_reach := 30.0
