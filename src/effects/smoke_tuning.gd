class_name SmokeTuning
extends Resource
## How black-powder smoke behaves. Edit config/smoke.tres.

## Breeze outdoors, metres per second (drifts the whole cloud).
@export var wind := Vector3(0.7, 0.0, 0.3)
## Indoors (a roof overhead) the wind drops to this fraction.
@export var indoor_wind := 0.05
## How fast the warm cloud rises, m/s.
@export var rise := 0.12
## Seconds a cloud lasts under a roof, and out in the open air.
@export var lifetime := 14.0
@export var outdoor_lifetime := 7.0
## Keep at most this many clouds (the oldest go first); fog volumes are the costly part.
@export var max_clouds := 8
@export var max_fog_volumes := 4
## The haze a cloud leaves hanging in a room (indoors only: out of doors the breeze takes it).
@export var fog_density := 0.15
## Swirl inside the cloud (m/s of wander).
@export var turbulence := 0.35

@export_group("The discharge")
## Puffs a .45 Colt load throws out of the muzzle (a 12-bore shell, `amount` 1.8, more).
@export var jet_puffs := 14
## How fast they leave (m/s) and how quickly the air stops them (per second): they come to rest
## between `jet_speed.x / jet_drag` and `jet_speed.y / jet_drag` metres out.
@export var jet_speed := Vector2(3.0, 11.0)
@export var jet_drag := 7.0
## How far off the bore the puffs leave (radians, least and most): an opening cone, not a line.
@export var jet_cone := Vector2(0.3, 0.6)
## Each puff is a fixed amount of smoke (m²: looking through its middle the smoke's optical depth is
## this over its radius squared), so it's dense the moment it leaves the muzzle and thins as it
## spreads, as real smoke does.
@export var puff_mass := 0.02
## A puff's radius as it leaves (m), what it spreads to in its first moments and how quickly
## (seconds), and how much it grows after that (m/s).
@export var start_radius := 0.05
@export var spread_radius := 0.28
@export var spread_time := 0.25
@export var growth := 0.14
## The smoke thinning into the air (seconds for its mass to fall to a third): quickly in a breeze,
## slowly in a still room.
@export var thin_outdoors := 6.0
@export var thin_indoors := 9.0
## Hot gas rises: an upward pull (m/s²) that fades over its first second.
@export var buoyancy := 2.0
## Smoke is grey, not white: lit by the sun it shouldn't glow.
@export var colour := Color(0.72, 0.71, 0.69)
## The little puff out of a revolver's cylinder gap, either side (a share of a muzzle puff).
@export var gap_share := 0.35
