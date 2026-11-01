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
## The men, each {id, model, post (a farmhouse use point), hold ("house" or "bedroom"), nerve,
## temper, proud, leads, masked, alarm_post (where he goes on the alarm, a use point; "" stays)}.
@export var men: Array[Dictionary] = []
