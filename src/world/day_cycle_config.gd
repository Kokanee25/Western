class_name DayCycleConfig
extends Resource
## Tunable numbers and colours for the day. Colour gradients are keyed by time of day:
## offset 0 is midnight, 0.25 is 6am, 0.5 is noon, 0.75 is 6pm.

## Real seconds per in-game day (45 minutes).
@export var day_length_seconds := 2700.0
@export var start_hour := 17.0
## T (or Y on a controller) cycles through these multipliers.
@export var debug_time_scales: Array[float] = [1.0, 30.0, 180.0]

@export_group("Sun path")
## Tilt of the sun's arc away from straight overhead (roughly the latitude).
@export var sun_tilt_degrees := 35.0
## Lifts the arc so days run longer than nights. 0 = sunrise 6:00, sunset 18:00.
@export var day_bias := 0.1

@export_group("Light")
@export var sun_max_energy := 1.6
@export var moon_max_energy := 0.22
@export var moon_color := Color(0.55, 0.65, 1.0)
@export var sun_color: Gradient
@export var sky_top: Gradient
@export var sky_horizon: Gradient
@export var ambient_energy_day := 1.0
@export var ambient_energy_night := 1.6

@export_group("Air")
@export var fog_density := 0.0035
@export var volumetric_fog_density := 0.012
@export var star_strength := 1.2
