class_name ClimbTuning
extends Resource
## Going up for height (variant D's `climb`, issue #572): a man whose cover's gone stale, with you
## on a floor below one he can get to (the saloon's galleries round the hall, a balcony), may take
## the stair up and fight from the rail: from up there the floor's edge and the rail hide him and
## he shoots down over them. Whether he goes, by his temper, his nerve, a friend keeping your head
## down and his hurts; where, by a cover search over the upper floor's places (Cover.climb_search),
## the way there by the town's places, up the stair (Waypoints). Edit config/climb.tres, not code.

@export_group("Whether he goes up")
## When his cover's gone stale (OutlawBrain's `_flank_after`, or four peeks from it), he goes up
## this share of the time, if there's a floor above you he can get to.
@export var chance := 0.35
## A friend in earshot still in it (keeping your head down while he runs for the stair): this more.
@export var friend_bonus := 0.25
## A hothead goes more, a cool man less: the chance moves by this times (temper - 0.5).
@export var temper_weight := 0.3
## His nerve: the chance falls by this share of how near his fear is to breaking him (dread / nerve).
@export var fear_weight := 0.8
## Hurting: the chance falls by this share of his felt pain; with a leg this weak (muscle strength,
## 0..1) or worse he doesn't climb at all.
@export var pain_weight := 1.0
@export var legs_min := 0.75
## Your fire: no climb while it keeps his head down (`suppressed`); lately cracking past
## (`rattled`, 0..1) it cuts the chance by this share.
@export var rattled_weight := 0.5
## Only while he knows where you are: he's seen or heard you within this (s). Lost you longer and
## he'd climb to watch an empty floor (and go straight back down to look for you).
@export var known_within := 6.0
## Once he's gone up, or looked for a way up and found none, not again for this long (s).
@export var again_after := 25.0

@export_group("Where: the floor above")
## A spot is up when it's this much (m) above where he stands and above your feet.
@export var rise := 2.0
## Behind a balustrade up there (Cover._screen_spot): cover enough when at least this share of the
## lines to him ducked are stopped close to him (a gallery's balusters alone stop about a quarter
## square on, more seen slantwise; the floor's edge takes his lower half from below). 0: off.
@export var screen := 0.4
## The upper floor's places (Waypoints) he'll look round: within this (m, flat) of him.
@export var reach := 14.0
## Spots along the upper floor's walks between its places, this far apart (m), and across them by
## these (m, either side: out to the rail and back to the wall).
@export var spacing := 1.0
@export var across := PackedFloat32Array([0.0, 0.6, -0.6, 1.0, -1.0])
## Not within this (m) of where a friend is or is going.
@export var apart := 1.2
## The longest way he'll run (m), by the town's places, up the stair; each metre of it costs a spot
## this much of its score (Cover._score's straight metre is 0.35).
@export var max_way := 32.0
@export var way_cost := 0.05
## The way mustn't pass this near you (m, flat, on your floor): not up the stair past your gun.
@export var way_clear := 3.0

@export_group("Up there")
## Up at the rail he watches the floor below this long (s) before he'll go and look for you,
## however long the run up took (OutlawBrain._lost_you: else he'd be straight back down the stair).
@export var watch_up := 12.0

@export_group("The run")
## How long he gives the run there before he gives that cover up: the way at his run, plus this (s).
@export var time_spare := 4.0


## The chance he goes up now: his `temper`, his dread over his nerve, a `friend` keeping you busy,
## your fire on him lately (`rattled`), his felt `pain`.
func chance_now(temper: float, dread_share: float, friend: bool, rattled: float, pain: float) -> float:
	var c := chance + (friend_bonus if friend else 0.0) + temper_weight * (temper - 0.5)
	c *= 1.0 - fear_weight * clampf(dread_share, 0.0, 1.0)
	c *= 1.0 - rattled_weight * clampf(rattled, 0.0, 1.0)
	c *= 1.0 - pain_weight * clampf(pain, 0.0, 1.0)
	return clampf(c, 0.0, 1.0)
