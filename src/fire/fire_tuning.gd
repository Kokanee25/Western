class_name FireTuning
extends Resource
## How fire behaves (config/fire.tres). Time is real seconds at normal game speed; fire runs much
## faster than real timber burns (about 0.7 mm a minute) so a building goes up in minutes, not an
## afternoon.

## Degrees C. Wood catches around here (dry pine lights at 250–300 °C with a flame near).
@export var ignition_temperature := 290.0
@export var ambient_temperature := 20.0
## Materials that never burn (they still get hot, and glass cracks).
@export var fireproof := [&"stone", &"glass"]
## Glass cracks and falls out of its frame this hot.
@export var glass_cracks_at := 240.0

## Heat from a burning member into what it touches, and what's near it (radiant, fading to nothing
## at `reach` metres), in °C per second for a 1 cm thick member (thicker ones heat slower).
@export var contact_heating := 120.0
@export var radiant_heating := 18.0
@export var reach := 1.3
## Flames lick up this far above a burning member: what's straight over it, within this, is
## heated as if touching the flames.
@export var flame_height := 0.6
## Flames climb: heat going up is at full strength, sideways at this much, downward at this much.
@export var sideways := 0.45
@export var downward := 0.12
## Hot things lose heat to the air: this share of the difference from ambient per second.
@export var cooling := 0.022
## A fire takes this long to get going on a member before it's at full heat.
@export var growth_seconds := 8.0

## How fast burning timber turns to char, metres per second, from each face.
@export var char_rate := 0.00025
## Burnt down to less than this (m) and a board is gone to ash.
@export var ash_thickness := 0.004

## How often the fire's rules run (s), and how often burning buildings recheck their loads.
@export var tick := 0.25
@export var settle_every := 1.0
## Limits on what gets drawn: members with flames, and fire lights.
@export var max_flames := 40
@export var max_lights := 6
## People within this of flames get burnt, at this rate (burn severity per second, per flame).
@export var scorch_reach := 0.5
@export var scorch_rate := 0.35
## A lamp's spilt oil: burns this long, heating what's within `spill_radius`.
@export var spill_seconds := 25.0
@export var spill_radius := 0.9
@export var spill_heating := 90.0
