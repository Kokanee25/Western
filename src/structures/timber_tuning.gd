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
	# Wrought and cast iron (a safe, a stove, a windpump's wheel): far past anything a ball, a
	# charge or a fall here could break (USDA Wood Handbook's figures for the woods; iron's from
	# period engineering tables, rounded).
	&"iron": {"density": 7600.0, "bending": 250e6, "compression": 250e6, "stiffness": 190e9},
	# Clear white oak, dressed (the prop kit's chairs and tables): the Wood Handbook's clear-wood
	# figures at 12% moisture, not cut down (furniture stock is picked clear); `toughness`, its work
	# to maximum load in bending (J/m³), is what a blow must put into it to break it (KitProp).
	&"oak": {"density": 750.0, "bending": 105e6, "compression": 51e6, "stiffness": 12.3e9, "toughness": 101e3},
	# Cotton duck, a covered wagon's cover (the prop factory's): as a member a centimetre thick, the
	# weight of heavy duck (~0.5 kg/m²); nothing it carries, so its strengths are nominal.
	&"canvas": {"density": 50.0, "bending": 2e6, "compression": 0.5e6, "stiffness": 0.2e9, "toughness": 20e3},
	# Pressed hay, loose straw, a sack of grain, dry horse dung (the prop factory's, as one member
	# each): their weights in their boxes (a two-string bale ~27 kg, a 100 lb sack); soft.
	&"hay": {"density": 140.0, "bending": 0.3e6, "compression": 0.2e6, "stiffness": 0.01e9, "toughness": 5e3},
	&"straw": {"density": 40.0, "bending": 0.1e6, "compression": 0.05e6, "stiffness": 0.005e9, "toughness": 2e3},
	&"grain_sack": {"density": 560.0, "bending": 0.5e6, "compression": 1.0e6, "stiffness": 0.02e9, "toughness": 10e3},
	&"dung": {"density": 300.0, "bending": 0.1e6, "compression": 0.1e6, "stiffness": 0.005e9, "toughness": 2e3},
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
