class_name SightTuning
extends Resource
## How far a man can make another out by the light falling on him (`SightLight`; the perception
## lab's problem 3, 2026-10-22: lamps lit nobody). Edit config/sight.tres, not code.
##
## The light is counted in lux (lamps add to the sky) and his reach goes with its logarithm: the eye
## takes light by ratios (Weber-Fechner), so a room at a few percent of the day outside is still
## bright to him, while the same few percent of a night sky is black.

## How far he picks a man out (m) in full daylight in the open, and under a clear night sky.
@export var range_day := 60.0
@export var range_night := 14.0
## The light those two ranges are reached at (lux): a clear day's (overcast to sun: 1e3-1e5), and
## a clear night's starlight with some moon (starlight ~0.001, a quarter moon ~0.01-0.03, full
## ~0.1-0.3). Between and below them his reach goes with log(lux): at about 0.0004 lux it's nothing.
@export var day_lux := 10000.0
@export var night_lux := 0.02

@export_group("Sky")
## Open sky over him (a ray straight up, `sky_ray_m` long, meets nothing): the sky's whole light,
## what `range_day` and `range_night` are. Under a roof the sky reaches him sideways, through a
## porch's open front or a door: the share of `sky_rays` rays round him, `sky_elevation_deg` up,
## that meet nothing; and never less than `room_sky`, a shut room by its windows and cracks (a
## daylight factor of a few percent, as lighting guides put it).
@export var sky_ray_m := 40.0
@export var sky_rays := 8
@export var sky_elevation_deg := 15.0
@export var room_sky := 0.03
## The lines from a man to the sky and to the lamps are looked along again once he's moved this far
## (m), or after this many physics frames (a roof can burn, a wall be blown in).
@export var lines_moved_m := 0.5
@export var lines_frames := 60

@export_group("Lamps")
## Lux at 1 m per unit of an OilLamp's energy: a period kerosene lamp of about ten candlepower
## (~10 cd, so ~10 lux at a metre) is energy 1.0-1.4. A lamp's light then falls off as it's drawn
## (its range and attenuation, as Godot's omni lights do), and only along a clear line.
@export var lux_per_energy := 10.0
## Nearer than this to the flame he's counted at this distance (m): a chest by a lamp isn't in it.
@export var lamp_near_m := 0.3
## The light on a man is worked out at most once in this many physics frames (Senses' tick, 0.12 s),
## shared by everyone looking at him.
@export var refresh_frames := 7
