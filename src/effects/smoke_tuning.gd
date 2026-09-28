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
