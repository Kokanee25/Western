class_name BallisticsTuning
extends Resource
## How hard materials are to shoot through: energy a bullet loses per centimetre of material.
## A .45 Colt black-powder round carries ~475 J and goes through roughly 10–12 cm of pine.

## wood id -> joules per cm
@export var resistance_by_wood := {
	&"weathered_pine": 42.0, &"painted_ochre": 42.0, &"painted_rust": 42.0, &"sign": 42.0,
	&"floor": 48.0, &"framing": 55.0, &"dark_trim": 70.0, &"glass": 8.0,
}
@export var default_resistance := 120.0
## Bullets slower than this are spent and drop.
@export var min_speed := 40.0
@export var max_age := 3.0
@export var gravity := 9.8
## Share of the bullet's momentum pushed into loose objects it hits.
@export var impulse_transfer := 0.6
