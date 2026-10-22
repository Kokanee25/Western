class_name FloorMarksTuning
extends Resource
## What lands on the boards and how it goes (FloorMarks; config/floor_marks.tres). Grams, millilitres,
## metres, game hours.

@export_group("Boots")
## Dirt a boot picks up a metre walked on the street (g), and the most it carries.
@export var boot_pickup := 0.6
@export var boot_max := 6.0
## How far onto boards it takes to shed most of it (m: e-fold; entrance-matting studies put ~80% of
## it in the first 3-5 m indoors).
@export var shed_metres := 2.5
## The street wet (0 dry dust .. 1 mud): mud is picked up faster and shows darker.
@export var street_wet := 0.0
@export var mud_pickup := 4.0

@export_group("Liquid")
## A spill lies as a film this thick on boards (mm), and spreads no wider than this (m).
@export var film_mm := 1.5
@export var spread_max := 0.8
## Off a still indoor floor, a film dries this many mm a game hour (by kind), and this share of what's
## there a game hour soaks into bare wood as a stain (water leaves none).
@export var evaporate := {&"water": 0.25, &"whiskey": 0.45, &"beer": 0.25, &"lamp_oil": 0.03, &"blood": 0.15}
@export var soak := {&"water": 0.0, &"whiskey": 0.2, &"beer": 0.12, &"lamp_oil": 0.35, &"blood": 0.3}

@export_group("How it looks")
## Dirt reads fully at this many g/m² (an e-fold), a stain at this many ml a cell.
@export var dirt_full := 25.0
@export var stain_full := 2.0
@export var dust := Color(0.5, 0.41, 0.3)
@export var mud := Color(0.27, 0.2, 0.13)
## Wet boards: darker by this much at a full film.
@export var wet_dark := 0.45
@export var stain := {&"whiskey": Color(0.32, 0.19, 0.09), &"beer": Color(0.36, 0.26, 0.13),
		&"lamp_oil": Color(0.2, 0.16, 0.11), &"blood": Color(0.33, 0.12, 0.08)}
