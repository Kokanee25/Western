class_name ValleyWorld
extends Node3D
## The new valley's scene (scenes/valley.tscn; docs/briefs/valley-plan.md §12, G1), loaded instead
## of the old town's street when `Settings.world` is `valley` (main.gd makes the swap). For now it's
## empty: the sky, the sun and moon on the town's day (config/day_cycle.tres: the sun sets due west,
## straight down Main Street, heading 270), the valley's ground (G2: a Ground over the bake of
## config/valley.json, ValleyTerrain, drawn and collided by ValleyGround), the shot's systems
## (ballistics, impacts, traces), the main line with its bridges and the daily train (G3:
## ValleyRailway), the greybox markers (G4: every place's pad, road, ford and bed drawn on the ground,
## ValleyMarks; blocks, posts, Bridge A and the town bridge, the places by name, ValleyMarkers), the
## town's greybox (G5: boardwalks, the lanes and alleys open to the back, the town's ways, ValleyTown),
## the farmhouse on the widow's pad and its hostage rescue (G6: Farmhouse, FarmhouseMission; its places
## joined to the valley's by the East Road and the widow's lane), the sheriff on the road (the first
## story mission, #746: SheriffOnRoad, `-- --mission=sheriff` or the bridge's `moment the_sheriff`)
## the valley town's people (#756: ValleyFolk from config/valley_folk.json, the saloon yard's bar and
## card table at night) and the player at the crossroads looking down Main Street. No TownLife, gang
## or labs: they need the old town.

## The ground's colour where a tile's been dug (the greybox's dirt; the undug ground's colours are
## config/valley_terrain.tres's).
const DUG_COLOUR := Color(0.62, 0.52, 0.40)

var layout: ValleyLayout
var railway: ValleyRailway
var markers: ValleyMarkers
var farmhouse: Farmhouse
var mission: FarmhouseMission
var folk: ValleyFolk
## The town's buildings built from their specs (#765: the doctor's first), by lot id.
var buildings := {}
## The main line and its train (G3); `-- --no-railway`: the valley without them (the bench's before).
static var railway_default := not "--no-railway" in OS.get_cmdline_user_args()
## The greybox markers (G4); `-- --no-markers`: the valley without them (the bench's before).
static var markers_default := not "--no-markers" in OS.get_cmdline_user_args()
## The farmhouse and its mission on the widow's pad (G6); `-- --no-farmhouse`: without (the bench's before).
static var farmhouse_default := not "--no-farmhouse" in OS.get_cmdline_user_args()
## `-- --no-farm-mission`: the house without its mission (the bench's split of the two).
static var farm_mission_default := not "--no-farm-mission" in OS.get_cmdline_user_args()
## `-- --mission=sheriff`: the first story mission from dawn at Harlan's place (#746).
const SHERIFF_ARG := "--mission=sheriff"
## `-- --mission=sheriff_dies [--care=good|poor|left]`: No Law's sheriff's last day alone (#796:
## SheriffDies, the morning after set up, you on Main Street).
const SHERIFF_DIES_ARG := "--mission=sheriff_dies"
## The coach heist in the coach cut (#794: CoachCut, `-- --mission=coach`).
var coach_cut: CoachCut


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	_make_ground()
	if railway_default:
		railway = ValleyRailway.new()
		railway.layout = layout
		add_child(railway)
	if farmhouse_default:
		_make_farmhouse()
	if markers_default:
		markers = ValleyMarkers.new()
		markers.layout = layout
		markers.railway = railway
		add_child(markers)
		if farmhouse:
			Farmhouse.add_valley_places(markers.places, markers.way_end("widow_lane"), markers.join)
		_make_buildings()
		if markers.town and ValleyFolk.folk_default:
			folk = ValleyFolk.new()
			folk.layout = layout
			folk.town = markers.town
			add_child(folk)
	var player := get_node_or_null(^"Player") as Node3D
	if player:
		player.transform = start_transform(layout)
	if SHERIFF_ARG in OS.get_cmdline_user_args():
		_start_sheriff.call_deferred()
	if SHERIFF_DIES_ARG in OS.get_cmdline_user_args():
		_start_sheriff_dies.call_deferred()
	if CoachCut.START_ARG in OS.get_cmdline_user_args() or CoachCut.start_on_load:
		CoachCut.start_on_load = false
		_start_coach_cut.call_deferred()


## The sheriff on the road (#746), once the valley's in (its places, the ground under you). The
## story's Harlan has no revolver till the dying sheriff gives him his (No Law, #796).
func _start_sheriff() -> void:
	for i in 5:
		await get_tree().physics_frame
	_unarmed()
	Moment.start_named(&"the_sheriff", self, null)


## No Law's sheriff's last day alone (#796), once the folk are built.
func _start_sheriff_dies() -> void:
	for i in 5:
		await get_tree().physics_frame
	var care := "good"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--care="):
			care = a.get_slice("=", 1)
	if folk:
		folk.start_sheriff_dies({"set_up": true, "care": care})


func _unarmed() -> void:
	var p := get_node_or_null(^"Player") as Player
	if p and not StoryState.has_fact("nolaw.revolver"):
		p.lack(&"revolver")


## The coach heist in the coach cut (#794), once the valley's ground is in: the ram held, the coach
## coming up the grade, you at the high spot. Made again by the coach heist lab's `ch_cut`.
func start_coach_cut(lead := -1.0, back := 40.0, fight_seed := 815) -> CoachCut:
	if coach_cut and is_instance_valid(coach_cut):
		coach_cut.queue_free()
	coach_cut = CoachCut.new()
	coach_cut.layout = layout
	coach_cut.release_lead = lead
	coach_cut.start_back = back
	coach_cut.fight_seed = fight_seed
	add_child(coach_cut)
	coach_cut.begin()
	return coach_cut


func _start_coach_cut() -> void:
	for i in 5:
		await get_tree().physics_frame
	start_coach_cut()
	coach_cut.place_player(get_node_or_null(^"Player") as Node3D)


## Where the player starts: on the crossroads' ground, facing down Main Street (west).
static func start_transform(l: ValleyLayout) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw_of(l.main_street_heading())), l.crossroads())


## A compass heading (0 north, -Z; 90 east, +X) as a turn round +Y from facing -Z.
static func yaw_of(heading_deg: float) -> float:
	return -deg_to_rad(heading_deg)


## The farmhouse on the widow's pad (G6, #731: Farmhouse with the valley's plan and ground), what's
## fixed in it coming down with its walls (Fittings, as in the street) and its hostage rescue
## (FarmhouseMission: started by `farm_start`, `-- --mission=farmhouse`, Enter after a lost try, or
## walking up to the widow's place: FarmhouseMission's valley start).
func _make_farmhouse() -> void:
	farmhouse = Farmhouse.new()
	farmhouse.name = "Farmhouse"
	farmhouse.layout = layout
	add_child(farmhouse)
	var fittings := Fittings.new()
	fittings.name = "Fittings"
	fittings.only = farmhouse
	fittings.ground_relative = true
	add_child(fittings)
	if farm_mission_default:
		mission = FarmhouseMission.new()
		mission.name = "FarmhouseMission"
		add_child(mission)


## Every town lot with its building's spec (valley.json's `spec`: the building lab's builder, #765)
## built on it in place of its block: set on its lot's `at` and `facing`, its floor at its walk's top
## (ValleyTown's: the lot's `walk.h` over the street's edge), on the pad the bake dug for it.
func _make_buildings() -> void:
	if markers == null or markers.town == null:
		return
	var tops := {}
	for w: Dictionary in markers.town.walks:
		tops[String(w.id)] = float(w.top)
	for side: String in ["north", "south"]:
		for l: Dictionary in layout.lots(side):
			if not l.has("spec"):
				continue
			var b: Node3D = load("res://experiments/building_lab/spec_building.gd").new()
			var sp: Dictionary = b.load_spec(String(l.spec))
			b.set(&"spec_path", String(l.spec))
			b.set(&"structure_id", StringName("valley_" + String(l.id)))
			b.name = "Building_" + String(l.id)
			var at: Array = (sp.lot as Dictionary).at
			var floor_top := float(sp.levels.ground.top)
			var y: float = tops.get(String(l.id), float(at[1]) + floor_top) - floor_top
			b.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(sp.lot.get("facing", 0.0)))), Vector3(float(at[0]), y, float(at[2])))
			add_child(b)
			buildings[String(l.id)] = b
			var sw: Dictionary = (sp.lot as Dictionary).get("side_walk", {})
			if not sw.is_empty():
				_side_walk(String(l.id), b, sw, floor_top)


## A boardwalk down a building's side street (its spec's `lot.side_walk`: saloon B's, under its
## wrapping balcony, #848; art's, Sean's answer 8 on #772): from `at` [x, z] in the building's space,
## turned `turn` degrees there (a Boardwalk runs along its +X, the street on its -Z), `length` by
## `depth`, its top the building's floor, on posts over the street's own ground, a flight to the
## street at each of `steps` [centre, width] and steps down at its far end. Its near end meets the
## lot's walk on Main Street (`walk.span` carries that one past the corner).
func _side_walk(id: String, b: Node3D, sw: Dictionary, floor_top: float) -> void:
	var town := markers.town
	var bw := Boardwalk.new()
	bw.name = "SideWalk_" + id
	bw.structure_id = StringName("valley_side_walk_" + id)
	bw.build_seed = hash(id + "_side") & 0xffff
	bw.length = float(sw.length)
	bw.walk_depth = float(sw.depth)
	bw.top = floor_top
	bw.riser = town.riser_max
	bw.max_riser = true
	bw.on_posts = true
	var xf: Transform3D = b.transform * Transform3D(Basis(Vector3.UP, deg_to_rad(float(sw.get("turn", -90.0)))), Vector3(float(sw.at[0]), 0.0, float(sw.at[1])))
	bw.transform = xf
	var y := xf.origin.y
	bw.ground_at = func(lx: float, lz: float) -> float:
		var p := xf * Vector3(lx, 0.0, lz)
		return town.ground(p.x, p.z) - y
	var flights := []
	var below := 0.0
	for st: Array in sw.get("steps", []):
		flights.append(Vector2(float(st[0]), float(st[1])))
		var foot := xf * Vector3(float(st[0]), 0.0, -bw.walk_depth - 1.0)
		below = maxf(below, y - town.ground(foot.x, foot.z))
	bw.steps = flights
	bw.street_below = below
	var far := xf * Vector3(bw.length, 0.0, -bw.walk_depth * 0.5)
	bw.end_steps = [Vector2(1, town.ground(far.x, far.z) - y)]
	add_child(bw)


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
