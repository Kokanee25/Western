class_name ValleyGroundArtTuning
extends Resource
## The valley's ground drawn real (#891; ValleyGroundArt, src/art/valley_ground.gdshader): which scans,
## and the street's dials. Edit config/valley_ground_art.tres, not code. Each dial below is the
## shader uniform of the same name (the shader says what it does).

## The scans (assets/textures/scans/<id>/), by the shader's layer.
@export var scans := {
	"dirt": "dirt", "dry": "dry_ground_rocks", "grass": "withered_grass",
	"trail": "rocky_trail", "mud": "mud_cracked_dry_riverbed_002", "rock": "cliff_side",
}
## Metres a tile, where a scan's meta.json gives none (Poly Haven's do).
@export var default_metres := 2.0

@export_group("Land")
@export var rock_from := 30.0
@export var rock_full := 44.0
@export var water_near := 25.0
@export var grade := Vector3(1.0, 0.89, 0.76)
@export var grade_sat := 1.08
@export var street_tint := Vector3(1.08, 0.95, 0.82)
@export var trail_tint := Vector3(0.86, 0.8, 0.72)

@export_group("Streets and roads")
@export var packed_dark := 0.8
@export var rut_dark := 0.84
@export var rut_depth := 0.07
@export var rut_half := 0.13
@export var gauge := 1.55
@export var street_lane := 2.4
@export var lane_wander := 0.45
@export var walk_edge := 7.65
@export var hoof_density := 0.9
@export var hoof_depth := 0.018
@export var manure_density := 3.0
@export var straw_density := 12.0
@export var puddle_cover := 0.18
@export var detail_far := 40.0

## The dials the shader takes, by name.
const DIALS := ["rock_from", "rock_full", "water_near", "grade", "grade_sat", "street_tint", "trail_tint", "packed_dark", "rut_dark",
	"rut_depth", "rut_half", "gauge", "street_lane", "lane_wander", "walk_edge", "hoof_density",
	"hoof_depth", "manure_density", "straw_density", "puddle_cover", "detail_far"]
