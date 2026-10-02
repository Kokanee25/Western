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
## Tilt of the moon's arc (a full moon, opposite the sun's hour): it rises in the east, sets in the
## west and crosses the sky this far from straight overhead, over the +Z side (the street, seen from
## the saloon's door). Low, as the saloon painting's moon is in its doorway.
@export var moon_tilt_degrees := 35.0

@export_group("Light")
@export var sun_max_energy := 1.6
@export var moon_max_energy := 0.45
@export var moon_color := Color(0.55, 0.65, 1.0)
@export var sun_color: Gradient
@export var sky_top: Gradient
@export var sky_horizon: Gradient
@export var ambient_energy_day := 1.0
@export var ambient_energy_night := 2.5
## When the sun is low (golden hour): the ambient light is cut to this share of the day's, so the
## shadows go deep, and only this share of it comes from the sky (the rest is the horizon's warm
## colour), so they're warm brown rather than blue-violet.
@export var ambient_low_sun := 0.3
@export var ambient_sky_low_sun := 0.5
## How bright that warm colour is beside the horizon's (the shadows' bounce light).
@export var ambient_warm_level := 0.45
## How bright the haze's gold is with the sun low (beside the horizon's colour): bright haze turned
## the far hills cream.
@export var fog_low_sun_level := 0.6
## Exposure with the sun low (1 at noon), and at night (the painting's saloon is a dark room with
## bright lamps: median L* 12).
@export var exposure_low_sun := 0.85
@export var exposure_night := 0.8
## Ambient light inside buildings (their interior probes), which the open sky doesn't reach.
@export var interior_ambient_day := 0.45
@export var interior_ambient_night := 0.04

@export_group("Air")
@export var fog_density := 0.0035
@export var volumetric_fog_density := 0.012
@export var star_strength := 1.2
