class_name TrainSoundTuning
extends Resource
## The train's sound dials (train step 4, issue #571; TrainSound). Every number here is PROPOSED
## until Sean has listened (the film in the waiting-on-Sean issue). Values: config/train_sound.tres.
##
## Levels are Godot's inverse distance: a sound is at `*_db` within `*_unit` metres and falls 6 dB a
## doubling past it, never louder than its `*_max_db`. So `unit` says how far a sound carries:
## the exhaust and the whistle far, the rail joints and the brakes near.

@export_group("The exhaust (a chuff a beat, four a wheel turn)")
@export var chuff_unit := 14.0
@export var chuff_db := 2.0
@export var chuff_max_db := 6.0
## The chuff's level is the steam in the cylinders: at the least steam that puffs (3 %) it's this
## share of full.
@export var chuff_floor := 0.25
## At full speed the beats are shorter (the cutoff notched up) and a little softer, dB.
@export var chuff_speed_db := -4.0
@export var full_speed := 12.0  ## m/s (43 km/h, the top speed)
## Which chuff by the beats a second: long (a start: slow and heavy) below the first, short (a
## blur) above the second, mid between.
@export var long_below := 3.0
@export var short_above := 8.0
## The shorter beats carry less (each is made to the same peak): this much more for the mid and
## short ones, so the exhaust at speed is as strong as at a start, quicker, not fainter.
@export var mid_db := 3.0
@export var short_db := 6.0
## The four beats of a wheel turn aren't the same (two cylinders, front and back strokes): each
## its own level (dB) and pitch, so the rhythm limps a little as a real engine's does.
@export var beat_db: Array[float] = [0.0, -2.5, -0.8, -3.2]
@export var beat_pitch: Array[float] = [1.0, 0.96, 1.03, 0.985]

@export_group("The cylinder cocks (open at a start)")
## A burst out of each cock on every beat while they're open (EngineModel.COCKS_BELOW), and their
## hiss between, by the steam.
@export var cocks_unit := 6.0
@export var cocks_db := -1.0
@export var cocks_loop_db := -9.0

@export_group("The rail joints (a clack an axle a joint)")
@export var clack_unit := 4.0
@export var clack_db := -2.0
@export var clack_max_db := 4.0
## By speed: (v / full_speed) ^ clack_power of full; none below clack_from (m/s).
@export var clack_power := 0.8
@export var clack_from := 0.25
## The engine's drivers are heavier than the cars' wheels: this much louder and lower.
@export var driver_db := 2.5
@export var driver_pitch := 0.82

@export_group("The couplers (the slack running out and bunching)")
@export var bang_unit := 9.0
@export var bang_db := 3.0
@export var bang_max_db := 8.0
## A bang this fast (closing m/s) is full; slower is quieter (a soft one is the `bump`).
@export var bang_full := 0.6
@export var bump_db := -5.0

@export_group("The brakes")
## The shoes squeal as they grip near a stand: by the brake on the cars there, loudest below
## `squeal_top` m/s and gone above `squeal_gone`, and gone below `squeal_stop` (the wheels stopped).
@export var squeal_unit := 10.0
@export var squeal_db := -3.0
@export var squeal_top := 2.5
@export var squeal_gone := 6.0
@export var squeal_stop := 0.08
## And grind at speed (the shoes on the treads), by brake x speed.
@export var grind_db := -10.0

@export_group("Rolling")
## The wheels on the rails between the joints, by speed (the engine's and the train's middle's).
@export var rumble_unit := 14.0
@export var rumble_db := -5.0

@export_group("Steam standing")
## The engine simmering (the fire, the blower, a little steam): always, quiet.
@export var simmer_unit := 6.0
@export var simmer_db := -14.0
## The safety valve lifts when it stands with the regulator shut this long (s; the fire still up
## and no steam drawn), blows for `valve_blow` s, then seats again.
@export var valve_after := 30.0
@export var valve_blow := 8.0
@export var valve_unit := 14.0
@export var valve_db := 2.0

@export_group("The bell and the whistle")
@export var bell_unit := 12.0
@export var bell_db := -1.0
## A strike every this many seconds while it's rung (the bell swung, the clapper either side).
@export var bell_period := 0.8
@export var whistle_unit := 40.0
@export var whistle_db := 4.0
@export var whistle_max_db := 8.0
## The steam reaching the whistle: up in `whistle_attack` s, away in `whistle_release`; its pitch
## rises from `whistle_low` of true as it comes and falls back as it goes.
@export var whistle_attack := 0.12
@export var whistle_release := 0.45
@export var whistle_low := 0.9
## The crossing pattern's long and short blasts, and the gap between, s.
@export var whistle_long := 1.6
@export var whistle_short := 0.5
@export var whistle_gap := 0.35

@export_group("How many")
## A one-shot quieter than this at the ears isn't played (dB).
@export var cull_db := -48.0
## Voices the train keeps for its one-shots, by kind (past it the oldest gives way).
@export var exhaust_voices := 8
@export var clack_voices := 16
@export var clank_voices := 6
@export var bell_voices := 3
