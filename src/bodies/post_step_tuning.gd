class_name PostStepTuning
extends Resource
## Stepping out from a post to aim (variant D's `step_out`, issue #566): a man bladed behind a post
## (PostPose) either points his gun round it (quick, wild: the point-fired rule) or steps out past
## its gun-side edge, squares up, takes an aimed shot and steps back in (slow, accurate, and seen
## while he's out). Which, by range, his nerve and your fire; how far, how quick and how long out,
## his own numbers drawn from his seed (`dials`), as the post pose's are. Edit config/post_step.tres,
## not code.
##
## The range rule follows point shooting's (PostPose's header: Fairbairn and Sykes; the quick-kill
## courses): pointed fire holds a man's chest to about 7 m and falls off past 10-15 m, so near he
## points, far he aims.

@export_group("Which: point or step out")
## At or inside `near_m` he steps out `chance_near` of his shots; at or past `far_m`, `chance_far`;
## straight between them.
@export var near_m := 6.0
@export var far_m := 12.0
@export var chance_near := 0.15
@export var chance_far := 0.85
## You outside where his forearm can point (PostPose.POINT_ARC): stepping out is his only shot
## short of turning on the post first.
@export var chance_off_arc := 0.9
## His nerve: the chance falls by this share of how near his fear is to breaking him
## (dread / nerve, 0..1).
@export var fear_weight := 0.8
## A hothead steps out more, a cool man less: the chance moves by this times (temper - 0.5).
@export var temper_weight := 0.3
## Your fire: rounds cracking past lately (his `rattled`, 0..1) cut it by this share; while they're
## still keeping his head down (`suppressed`) he doesn't step out at all.
@export var rattled_weight := 0.5
## Hurting: the chance falls by this share of his felt pain (0..1).
@export var pain_weight := 1.0
## Shooting at where you were (he can't see you): the chance times this.
@export var unseen_factor := 0.4

@export_group("His own numbers (drawn per man)")
## How far past the post's edge the middle of his trunk comes when he's out (m): 0 is a lean (his
## right eye and gun arm past the edge, half of him still behind it), 0.25 all of him out.
@export var clear_min := 0.0
@export var clear_max := 0.25
## How long the step out takes (s), and the step back in as a share of it.
@export var out_time_min := 0.3
@export var out_time_max := 0.55
@export var back_share := 0.8
## The longest he stays out (s) before he steps back in, shot or not.
@export var hold_min := 1.2
@export var hold_max := 2.6
## His own lean to stepping out (added to the chance): -eager_range..eager_range.
@export var eager_range := 0.15

@export_group("Room")
## Nothing solid in the way across at these heights (m) from his trunk to the out spot and this far
## beyond it (his shoulder's room); the floor there within `floor_step` of where he stands.
@export var room_heights := PackedFloat32Array([0.4, 1.0, 1.45])
@export var room_beyond := 0.2
@export var floor_step := 0.2


## A man's own numbers for stepping out, from his seed (a stream of its own: his post pose's dials
## are unchanged by these).
func dials(seed: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed, "post_step"])
	return {
		"clear": r.randf_range(clear_min, clear_max),
		"out_time": r.randf_range(out_time_min, out_time_max),
		"hold": r.randf_range(hold_min, hold_max),
		"eager": r.randf_range(-eager_range, eager_range),
	}


## The chance he steps out for this shot (0..1): `range_m` to his man, `in_arc` whether his forearm
## can point at him, `dread_share` his dread over his nerve, his `temper`, `rattled`, felt `pain`,
## whether he `sees` the man, his own `eager`.
func chance(range_m: float, in_arc: bool, dread_share: float, temper: float, rattled: float, pain: float, sees: bool,
		eager: float) -> float:
	var k := clampf((range_m - near_m) / maxf(far_m - near_m, 0.01), 0.0, 1.0)
	var c := lerpf(chance_near, chance_far, k) if in_arc else chance_off_arc
	c += temper_weight * (temper - 0.5) + eager
	c *= 1.0 - fear_weight * clampf(dread_share, 0.0, 1.0)
	c *= 1.0 - rattled_weight * clampf(rattled, 0.0, 1.0)
	c *= 1.0 - pain_weight * clampf(pain, 0.0, 1.0)
	if not sees:
		c *= unseen_factor
	return clampf(c, 0.0, 1.0)
