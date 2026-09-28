class_name TimberTuning
extends Resource
## What the timber can take (config/timber.tres): weight and strength per wood, and how members
## joined with nails behave. These are failure strengths (what breaks it), not the cautious design
## values a carpenter would size by. Rough-sawn, air-dried, 1880s western softwood.
## Reference: the USDA Wood Handbook (clear-wood strengths, cut down for rough, knotty, weathered
## stock) and period carpentry practice for how members were nailed.

## wood id -> {density kg/m³, bending Pa (modulus of rupture), compression Pa (along the grain),
## stiffness Pa (modulus of elasticity)}
@export var woods := {
	&"framing": {"density": 500.0, "bending": 45e6, "compression": 34e6, "stiffness": 11e9},
	&"floor": {"density": 520.0, "bending": 45e6, "compression": 34e6, "stiffness": 11e9},
	&"weathered_pine": {"density": 420.0, "bending": 32e6, "compression": 26e6, "stiffness": 8.5e9},
	&"painted_ochre": {"density": 450.0, "bending": 38e6, "compression": 30e6, "stiffness": 9.5e9},
	&"painted_rust": {"density": 450.0, "bending": 38e6, "compression": 30e6, "stiffness": 9.5e9},
	&"dark_trim": {"density": 520.0, "bending": 42e6, "compression": 32e6, "stiffness": 10e9},
	&"sign": {"density": 450.0, "bending": 38e6, "compression": 30e6, "stiffness": 9.5e9},
	&"glass": {"density": 2500.0, "bending": 40e6, "compression": 100e6, "stiffness": 70e9},
	# Rubble-stone laid in lime mortar: heavy and strong in compression, weak in bending.
	&"stone": {"density": 2300.0, "bending": 1.5e6, "compression": 12e6, "stiffness": 15e9},
}
@export var default_wood := {"density": 480.0, "bending": 40e6, "compression": 30e6, "stiffness": 10e9}

## A member hanging off a single support is held only by its nails: this is the bending moment
## (N·m) a nailed joint takes before it tears out.
@export var joint_moment := 120.0
## And the pull (N) a nailed joint holds before the nails draw out: what stops an overhang tipping
## a member up off its next support.
@export var joint_uplift := 600.0
## Each bullet hole weakens the section by this many hole-widths of timber (the splintering
## round a hole takes more than the hole itself).
@export var hole_weakening := 1.6
## Effective length factor for buckling: sheathed studs are braced by the boards nailed to them,
## free posts aren't.
@export var braced_buckling_factor := 0.5
@export var free_buckling_factor := 1.0

## Falling timber: joules per cubic metre of a member it lands on before that member breaks.
@export var impact_toughness := 30000.0
## A falling piece of building (several members still nailed together) breaks up into separate
## members when it lands faster than this (m/s).
@export var break_up_speed := 2.5
## Falls slower than this don't damage what they land on.
@export var harmless_speed := 1.5


func wood(id: StringName) -> Dictionary:
	return woods.get(id, default_wood)
