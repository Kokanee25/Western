class_name ShoveTuning
extends Resource
## The player's shove and kick (PlayerShove; issue #479): one key, a tap a two-handed shove, held
## and let go a front kick. What each gives a man is an inelastic knock (the two meet and move on
## together, as KitProp.take_blow has it): the part of you behind the hands or the boot (its
## effective mass, a share of you) at its speed, into him; p = m M / (m + M) * v, his speed after
## p / M, and HumanBody.take_push decides from that (down past what he can catch with a step).
## Nothing is scaled up for the look of it.
##
## Sources (numbers from abstracts; the papers' hosts are outside the cloud session's network):
## - A front kick's foot at up to 10.4 +/- 0.8 m/s (taekwon-do athletes, front snap kick); a push
##   kick drives the hips through and lands slower and longer (Vagner et al. 2021, Arch Budo 17:
##   impulse and impact time grow with core training).
## - Effective mass of a kick: turning kick ~20% of the body's mass, side kick ~73% (Applied
##   Sciences, 2024); the push kick, hips driven in behind a straight leg, sits between: 0.35.
## - Against a fixed force plate a soldier's front kick is 154 N*s (cadets, Sports 2024, 12:205)
##   to 360 N*s (boots vs barefoot, 2018); a free man moves off the boot, so he gets less: ~145.
## - Pushing: CCOHS (after Eastman Kodak's tables) puts a standing whole-body push at 225 N to
##   keep up; a shove is a short hard one, ~280 N over ~0.2 s by these numbers (55 N*s).

## Held longer than this (s), it's a kick when you let go; shorter, a shove.
@export var hold_for_kick := 0.22
## Your weight (kg), with the gun belt and boots.
@export var mass := 80.0

@export_group("Shove")
## How far the hands reach from your middle (m), and how high they land (above your feet).
@export var shove_reach := 0.75
@export var shove_height := 1.3
## The hands' speed at him (m/s: arms thrown out and a lean into it) and the share of you behind
## them; one hand (the other on a gun) puts this share of two behind it.
@export var shove_speed := 3.0
@export var shove_mass_share := 0.3
@export var shove_one_hand := 0.6
## The move: the hands land this far into it (s), and it's over at the end.
@export var shove_hit_at := 0.12
@export var shove_time := 0.35

@export_group("Kick")
## How far the boot reaches from your middle (m), and how high it lands on a standing man.
@export var kick_reach := 1.0
@export var kick_height := 1.0
## The boot's speed at him (m/s) and the share of you behind it.
@export var kick_speed := 7.0
@export var kick_mass_share := 0.35
## Let go, the boot lands this far into it (s); the leg's back down at kick_time; then you're off
## balance a moment (s), moving at kick_pace of your speed.
@export var kick_hit_at := 0.12
@export var kick_time := 0.5
@export var kick_recover := 0.5
@export var kick_pace := 0.3
## Kicking on a stair, this chance you lose your footing (and the kick goes nowhere), down on the
## tread for slip_time (s).
@export var stair_slip := 0.35
@export var slip_time := 1.0
## Kicking something that doesn't give (a wall, a post): your foot stops dead on it and takes its
## own energy (the boot and foot, kg; your knee and hip give for the rest of the leg).
@export var foot_mass := 1.2

@export_group("Feel")
## The eyes' jolt as it lands (m/s of the head's dip spring, per N*s given) and the most.
@export var thump_per_ns := 0.004
@export var thump_max := 0.6

static var _t: ShoveTuning


static func t() -> ShoveTuning:
	if _t == null:
		_t = load("res://config/shove.tres") as ShoveTuning
		if _t == null:
			_t = ShoveTuning.new()
	return _t
