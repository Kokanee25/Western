class_name GroundTuning
extends Resource
## The ground that can be dug (docs/briefs/dig-ground.md). Edit config/ground.tres, not code.

## A cell's side (m): the height field's spacing. At 5 cm a stick's crater is about nine cells
## across and a shovel's blade five; each cell is two of the ground's paint squares (40 a metre).
@export var cell := 0.05
## Cells along a tile's side (a tile's height field has one more point a side, shared with the next
## tile's). Jolt rebuilds a 65x65 field in ~0.4 ms here (2026-10-22; 81x81 0.6, 161x161 2.0).
@export var tile_cells := 64
## How deep the earth goes below the authored ground before hardpan (m): enough to dig up a coffin
## (Sean, 2026-10-22).
@export var earth_depth := 2.0
## Half the drawn ground's side (m): the street's plane was 600 m.
@export var drawn_half := 300.0
## Half the side the ground collides over (m), on past its drawn edge as the endless plane did.
@export var reach_half := 2000.0
## How thick the flat ground's slabs, and the hardpan under a dug tile, are (m): deep, so nothing
## fast goes through.
@export var slab_depth := 10.0

@export_group("Earth")
## Loose earth takes this much more room than the packed earth it was dug from (earthmoving's
## swell: about a quarter for common earth).
@export var swell := 1.25
## Loose earth's angle of repose (degrees): steeper than this it slides. Dry loose earth ~35;
## packed earth stands as it's cut (a grave's walls).
@export var repose_degrees := 35.0
## At most this many passes of sliding after an edit, and over this much ground round it (m).
@export var slump_passes := 400
@export var slump_margin := 0.3
## A thing standing on the ground (a post, a sill, a prop's foot, a barrel) has lost it once the
## earth under it is this far below its bottom (m).
@export var undercut := 0.05


func tile_size() -> float:
	return cell * tile_cells
