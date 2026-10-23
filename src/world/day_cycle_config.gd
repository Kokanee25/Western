class_name DayCycleConfig
extends Resource
## Tunable numbers and colours for the day. Colour gradients are keyed by time of day:
## offset 0 is midnight, 0.25 is 6am, 0.5 is noon, 0.75 is 6pm.

## Real seconds per in-game day (45 minutes).
@export var day_length_seconds := 2700.0
@export var start_hour := 12.0
## The clock stands still from the start (Sean, 2026-10-23: "daytime stays daytime"); T lets it
## run. A dial so a mission can start with the clock running. Held, the clock doesn't move but
## time_scale stays as it was: bleeding and the body's clocks run on time_scale, not the hour.
@export var hold_clock := true
## T cycles through these multipliers, then back to held (when hold_clock), then round again.
@export var debug_time_scales: Array[float] = [1.0, 30.0, 180.0]
## The hour key's stops (DayCycle.next_hour_stop): noon, afternoon, golden hour, night, to
## compare the light looks at each.
@export var hour_stops: Array[float] = [12.0, 15.5, 17.6, 21.5]

@export_group("Sun path")
## Tilt of the sun's arc away from straight overhead (roughly the latitude).
@export var sun_tilt_degrees := 35.0
## Lifts the arc so days run longer than nights. 0 = sunrise 6:00, sunset 18:00.
@export var day_bias := 0.1
## Turns the whole arc round the vertical (degrees; positive swings the setting sun south of
## west): the street painting's sun sets a little left of the street's axis, so the north side's
## porches and boardwalks are sunlit at golden hour (docs/ART_REVIEW.md §3.1, with Sean).
@export var sun_azimuth_degrees := 0.0
## The sky is re-lit (its radiance: the ambient and reflections of everything under it) only when
## what's sent to it has changed this much: the sun or moon by this many degrees, a colour by this
## much in any channel. Sending it every tick swapped the radiance between two states frame to
## frame and flickered every sky-lit surface (interiors at their probes' edges, the saloon mirror).
@export var sky_update_degrees := 0.5
@export var sky_update_colour := 0.004
## The clouds' drift (sky units a real second).
@export var cloud_drift_speed := 0.002
## Tilt of the moon's arc (a full moon, opposite the sun's hour): it rises in the east, sets in the
## west and crosses the sky this far from straight overhead, over the +Z side when positive, -Z
## when negative (since Main Street the saloon faces -Z: the street seen from its door). Low, as
## the saloon painting's moon is in its doorway.
@export var moon_tilt_degrees := 35.0
## Turns the moon's arc round the vertical, as `sun_azimuth_degrees` does the sun's (positive swings
## it from -Z toward -X): from the saloon painting's seat (23:40) the moon stands in the doorway.
@export var moon_azimuth_degrees := 0.0

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

@export_group("High sun")
## The light pass (issue #318, Sean: "the day time outside looks the worst"): what changes as the
## sun climbs, by `high` (0 with the sun under ~18 degrees, 1 from ~48 up: noon is ~55). Each is
## as it was at its default; the light looks (config/looks/light_*.json) set them.
## Exposure with the sun high (the ground was white at 1).
@export var exposure_day := 1.0
## The ambient's share from the sky at noon (the rest the horizon's warm colour, ambient_warm_level).
@export var ambient_sky_day := 1.0
## The sky overhead with the sun high: its colour's saturation (a hot desert sky is paler than the
## cartoon blue), and how far it goes toward the horizon's colour.
@export var sky_high_saturation := 1.0
@export var sky_high_pale := 0.0
## The horizon with the sun high goes toward `sky_high_haze` (near white-hot) by this much.
@export var sky_high_white := 0.0
@export var sky_high_haze := Color(0.96, 0.93, 0.86)
## The haze down the street and the volumetric haze with the sun high, as shares of fog_density
## and volumetric_fog_density (distance haze at noon).
@export var fog_high_sun := 1.0
@export var volumetric_high_sun := 1.0
## Ambient light inside buildings (their interior probes), which the open sky doesn't reach.
@export var interior_ambient_day := 0.45
@export var interior_ambient_night := 0.04

@export_group("Air")
@export var fog_density := 0.0035
@export var volumetric_fog_density := 0.012
## With the sun low, the haze down the street and the volumetric haze are these shares of the day's
## (the street painting's golden hour is clear and deep in its shadows, its far end crisp under a
## glow round the sun that the sky and backdrop draw; 1 = as by day).
@export var fog_low_sun := 1.0
@export var volumetric_low_sun := 1.0
@export var star_strength := 1.2
