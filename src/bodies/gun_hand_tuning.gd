class_name GunHandTuning
extends Resource
## A gang member's hand on his gun (GunHand, OutlawBrain): the player's sway model (Sway,
## PlayerTuning's names) with a man's own sizes, how fast he swings onto a target, and how long he
## takes to react and to settle before he squeezes. config/gun_hand.tres. Degrees and seconds.

@export_group("Sway (as PlayerTuning)")
## The barrel's wander held up and aimed, and held low (drawing, coming up, lowered).
@export var sway_aim := 1.0
@export var sway_hip := 3.0
## Breathing: how far the muzzle rises and falls, and breaths a second.
@export var breath := 0.3
@export var breath_rate := 0.25
@export var tremor := 0.08
## Right after the gun comes up, he turns, moves or fires the wander is this many times bigger,
## settling over `settle_time` of holding still.
@export var unsettled := 2.5
@export var settle_time := 1.0
## Crouched (or down): steadier. Moving: worse, per m/s.
@export var crouch_sway := 0.75
@export var move_sway := 1.2
## After running he's winded (breathing deeper and faster, as yours), for this long.
@export var winded_seconds := 4.0

@export_group("Swinging onto a man")
## The hand's lag (a time constant) and its top speed (degrees a second).
@export var hand_lag := 0.1
@export var turn_rate := 240.0
## Swinging this many degrees undoes most of his settle (it decays by e for each).
@export var turn_unsettle := 15.0

@export_group("What shakes him")
## The wander grows by these, times his fear, his pain, his shock, and while rounds crack past him.
@export var fear_sway := 1.5
@export var pain_sway := 1.0
@export var shock_sway := 2.0
@export var rattled_sway := 0.8
## A hurt arm's shake (degrees, at no steadiness left).
@export var arm_tremor := 0.6
## Aiming with his left eye (his right one gone): the wander this many times.
@export var wrong_eye := 1.5
## Jerks: a near miss (at its closest), a ball into him, and squeezing with the wrong finger.
@export var near_miss_jerk := 1.2
@export var hit_jerk := 4.0
@export var wrong_finger_jerk := 1.5

@export_group("The trigger")
## From the squeeze to the shot (the sway goes on meanwhile).
@export var trigger_lag := 0.1
## The squeeze itself pulls the gun off (degrees): a jerk, times (1 + his temper + his fear): the
## brief's "rushed trigger inputs disturb the weapon's alignment".
@export var squeeze_jerk := 1.2
## He squeezes when his sights are on: the barrel within this many times the half-width of what
## he's shooting at; cool (temper 0) to hothead (temper 1). Frightened, he squeezes sooner.
@export var patience_cool := 0.8
@export var patience_hot := 2.2
## ... or after holding on him this long, whatever the sights are doing.
@export var hold_cool := 2.0
@export var hold_hot := 0.7
## What he aims at, as wide as a man's chest (m, half), or his head when that's all that shows.
@export var target_half_width := 0.22
@export var head_half_width := 0.1

@export_group("Reacting")
## When it comes to a fight he didn't start: the moment before he moves, cool to hothead, and
## longer by this for a man of no nerve (nerve 0), plus up to `react_spread` more.
@export var react_cool := 0.6
@export var react_hot := 0.3
@export var react_timid := 0.45
@export var react_spread := 0.25
