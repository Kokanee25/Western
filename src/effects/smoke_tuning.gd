class_name SmokeTuning
extends Resource
## How black-powder smoke behaves. Edit config/smoke.tres.

## Breeze outdoors, metres per second (drifts the whole cloud).
@export var wind := Vector3(0.7, 0.0, 0.3)
## Indoors (a roof overhead) the wind drops to this fraction.
@export var indoor_wind := 0.05
## How fast the warm cloud rises, m/s.
@export var rise := 0.12
@export var lifetime := 14.0
@export var puffs := 36
## Keep at most this many clouds (the oldest go first); fog volumes are the costly part.
@export var max_clouds := 8
@export var max_fog_volumes := 4
@export var fog_density := 0.9
## Swirl inside the cloud.
@export var turbulence := 0.35

## The player's own shot (#1048): its first puff sat in the held flash's light (MuzzleFlash's and
## ImpactEffects') and read as a big cream square at 50 ms. Seen from behind your own gun the cloud
## waits out the flash (`own_delay` s: the world's flash light lives 0.07 s), fills in over `own_fade_in` s, and starts `own_offset` m
## further down the barrel's line.
@export var own_delay := 0.07
@export var own_fade_in := 0.08
@export var own_offset := 0.25
## Its puffs start this big (a fraction of their full size; others' start at 0.25) and this dirty white (the
## cream of others' first puffs read as flash-lit from behind the gun), so the cloud is plain to see
## 100-200 ms in.
@export var own_start_size := 1.0
@export var own_start_colour := Color(0.82, 0.8, 0.76, 0.85)
