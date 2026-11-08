class_name ValleyGroundTuning
extends Resource
## How the valley's baked ground is chunked and drawn (ValleyGround; docs/briefs/valley-plan.md
## §12 G2). Edit config/valley_terrain.tres, not code.

## Height-field cells a chunk's side: its collision is one Jolt height field of (cells + 1)² points
## (65: Jolt's own height field, a power of two and one; 128 m at the bake's 2 m). The bake is made
## in whole chunks (valley_plan.py's BAKE_ALIGN).
@export var chunk_cells := 64
## Levels of detail: level 0 is a chunk drawn at the bake's 2 m; each level up a block twice the
## side drawn at half the points (64 quads a side at every level), so level 4 is 2,048 m at 32 m.
@export var levels := 5
## A block is drawn as its four children (closer, finer) when the camera is nearer its middle than
## `split` x its side: at 1.5 a quad at the nearest edge of a block just split is about a degree
## across (~20 px at 1280 wide), at every level.
@export var split := 1.5
## Its children are built (on a frame budget) once the camera is within (split + `prepare`) x its
## side, and freed once it's past (split + `evict`) x its side.
@export var prepare := 0.5
@export var evict := 1.0
## The switch's hysteresis, as a share of a block's side (Godot's visibility range margin).
@export var margin := 0.05
## Blocks built a frame at most (and their budget in ms; counted under World.deterministic).
@export var build_ms := 3.0
@export var build_units := 2
## How far each block's skirt hangs below its edge past the most it differs there from the bake
## (m): the skirts hide the cracks between blocks drawn at different levels.
@export var skirt_extra := 0.5
## The solid earth under a chunk's height field (a height field has no thickness): a box a square of
## `column_cells` cells, its top 1 cm under the lowest of the ground over it, `column_depth` m deep.
## None under a square holding a dug tile (the tile has its own). 0: no boxes.
@export var column_cells := 8
@export var column_depth := 10.0

@export_group("Colour")
## The greybox ground's colours, by slope: dirt where it's flat, rock where it's steep.
@export var dirt := Color(0.62, 0.52, 0.40)
@export var rock := Color(0.50, 0.46, 0.42)
## Slope (degrees) where the rock starts, and where it's all rock.
@export var rock_from := 28.0
@export var rock_full := 42.0
## Below this height (m, the crossroads 0) the bottomland: a touch darker and greener.
@export var bottom := Color(0.52, 0.48, 0.36)
@export var bottom_below := -8.0
