class_name ValleyWorld
extends Node3D
## The new valley's scene (scenes/valley.tscn; docs/briefs/valley-plan.md §12, G1), loaded instead
## of the old town's street when `Settings.world` is `valley` (main.gd makes the swap). For now it's
## empty: the sky, the sun and moon on the town's day (config/day_cycle.tres: the sun sets due west,
## straight down Main Street, heading 270), the valley's ground (G2: a Ground over the bake of
## config/valley.json, ValleyTerrain, drawn and collided by ValleyGround), the shot's systems
## (ballistics, impacts, traces), the main line with its bridges and the daily train (G3:
## ValleyRailway), the greybox markers (G4: every place's pad, road, ford and bed drawn on the ground,
## ValleyMarks; blocks, posts, Bridge A and the town bridge, the places by name, ValleyMarkers) and
## the player at the crossroads looking down Main Street. No TownLife, gang, farmhouse or labs: they
## need the old town.

## The ground's colour where a tile's been dug (the greybox's dirt; the undug ground's colours are
## config/valley_terrain.tres's).
const DUG_COLOUR := Color(0.62, 0.52, 0.40)

var layout: ValleyLayout
var railway: ValleyRailway
var markers: ValleyMarkers
## The main line and its train (G3); `-- --no-railway`: the valley without them (the bench's before).
static var railway_default := not "--no-railway" in OS.get_cmdline_user_args()
## The greybox markers (G4); `-- --no-markers`: the valley without them (the bench's before).
static var markers_default := not "--no-markers" in OS.get_cmdline_user_args()


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	_make_ground()
	if railway_default:
		railway = ValleyRailway.new()
		railway.layout = layout
		add_child(railway)
	if markers_default:
		markers = ValleyMarkers.new()
		markers.layout = layout
		markers.railway = railway
		add_child(markers)
	var player := get_node_or_null(^"Player") as Node3D
	if player:
		player.transform = start_transform(layout)


## Where the player starts: on the crossroads' ground, facing down Main Street (west).
static func start_transform(l: ValleyLayout) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw_of(l.main_street_heading())), l.crossroads())


## A compass heading (0 north, -Z; 90 east, +X) as a turn round +Y from facing -Z.
static func yaw_of(heading_deg: float) -> float:
	return -deg_to_rad(heading_deg)


## The ground, from the bake (ValleyTerrain, config/valley_ground/): a Ground over it, so a crater,
## a dug hole and a save work as in the town; ValleyGround's chunks collide and draw it.
func _make_ground() -> void:
	var g := Ground.new()
	g.name = "Ground"
	g.tuning = load("res://config/ground_valley.tres")
	g.terrain = ValleyTerrain.main()
	var dug := StandardMaterial3D.new()
	dug.albedo_color = DUG_COLOUR
	dug.roughness = 1.0
	g.material = dug
	var drawn := StandardMaterial3D.new()
	drawn.vertex_color_use_as_albedo = true
	drawn.roughness = 1.0
	g.valley_material = drawn
	g.valley_marks = ValleyMarks.main() if markers_default else null
	add_child(g)


## The valley's places by name (ValleyMarkers.places: every place, bridge, viewpoint and town lot),
## for the dev bridge's goto and look.
func places() -> Waypoints:
	return markers.places if markers else Waypoints.new()
