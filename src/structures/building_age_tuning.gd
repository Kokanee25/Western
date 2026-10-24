class_name BuildingAgeTuning
extends Resource
## How years of weather and use show on a building (config/building_age.tres; BuildingAge). Every
## amount is at full wear: a building `full_years` old or more. Younger ones get a share of it
## (`BuildingAge.wear`: `Structure.age_years` / `full_years`, to `wear_curve`), and chances scale
## the same way.

## The age at which a building shows all of it (the livery).
@export var full_years := 30.0
## How fast the first years show: wear is (age / full_years) to this power (under 1: a building
## fifteen years old shows more than half of it; the first coat of grey comes quickest).
@export var wear_curve := 0.7

@export_group("Porch")
## How far a porch roof drops between two posts at the middle of the span (m), and the share of
## spans that have dropped (at least one does). Sean, 2026-10-24: 0.15 on every span was "too wavy".
@export var porch_sag := 0.06
@export var porch_span_sag_chance := 0.35
## The whole porch racked along the street, its tops shifted over its feet (degrees).
@export var porch_rack_degrees := 2.2
## A post kicked out at the foot, hanging from the beam (degrees off plumb), and how many do.
@export var post_lean_degrees := 4.5
@export var post_lean_chance := 0.7
## Porch roof boards gone (light through the roof: a few, or the patches of sun under it read
## as a lighting fault, the blind critic found).
@export var porch_board_missing_chance := 0.04

@export_group("Roof and front")
## The ridge's swayback at the middle of the building, to nothing at the gable ends (m).
@export var ridge_sag := 0.35
## The false front's top pulled forward over the street, from the roofline up (degrees).
@export var front_lean_degrees := 2.2
## The sign off level, either way (degrees).
@export var sign_tilt_degrees := 3.5

@export_group("Boards")
## The rough siding's boards: how much their widths differ (share of a board's width, either way).
@export var board_width_spread := 0.28
## A board's top or foot pulled off its nails, out from the wall (m), and how many are.
@export var board_kick := 0.06
@export var board_kick_chance := 0.35
## A lap board on the front with one end let go and dropped (degrees), and how many.
@export var lap_droop_degrees := 1.4
@export var lap_droop_chance := 0.18
## Siding boards gone, and broken short at the foot (rot where the rain splashes).
@export var board_missing_chance := 0.05
@export var board_broken_chance := 0.08
## A stretch of a wall patched in newer wood: each side wall's chance, and how many boards wide.
@export var patch_chance := 0.6
@export var patch_boards := Vector2i(2, 5)
@export var patch_wood: StringName = &"framing"

@export_group("Shutters")
## Shutters on the side and back windows of a building at least this old, hanging ajar.
@export var shutter_years := 6.0
@export var shutter_chance := 0.75
## How far open a shutter hangs (degrees from shut).
@export var shutter_open_degrees := Vector2(12.0, 75.0)

@export_group("Walks and steps")
## A step's tread worn hollow in the middle (m at full wear) and one step in a walk cracked.
@export var step_wear := 0.03
@export var cracked_step_chance := 0.9
## The walk's planks no longer level: each a little up, down or rocked (m at its edge).
@export var plank_warp := 0.008
## A plank replaced in newer wood.
@export var plank_new_chance := 0.05
