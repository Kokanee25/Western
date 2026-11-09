class_name Farmhouse
extends Node3D
## The farmhouse out east of town (issue #520: the hostage rescue), on its knoll in the hills north
## of the road (config/town.json `Farmhouse`, ground.hills). Built from its building spec
## (experiments/building_lab/farmhouse.json, by the building lab's builder: every board of it a
## member, its furniture the prop kit's), its porch's deck a Boardwalk, its ways in and about joined
## into the town's places (Waypoints.test_street adds them), so a man can walk it.
##
##   Farmhouse.at(Vector3(2.8, 0.56, 0.5))   # its own space (FORMAT.md) -> the world's
##   Farmhouse.of(get_tree())                # the one in the street, or null
##
## In the valley (G6, #731; `Settings.world` valley) the same house stands on the widow's pad
## (config/valley.json's `widow_homestead`: its `farmhouse` and the hills carried from the old town),
## built by ValleyWorld with `layout` and `terrain` given: then its static helpers (origin, at,
## on_ground, use_point, ground_at) answer for it there, and its places join the valley's
## (`add_valley_places`). The old town's is unchanged.

const SPEC := "res://experiments/building_lab/farmhouse.json"
const SpecBuilding := preload("res://experiments/building_lab/spec_building.gd")
## Its floor's top, its loft's (the spec's levels).
const FLOOR := 0.56
const LOFT := 3.11
## Its footprint with the lean-to (x, z), for its footing on the knoll.
const WIDTH := 9.0
const DEPTH := 7.6
## How many years it has stood (BuildingAge; the spec's identity: built 1868).
const AGE := 14.0

var building: FalseFrontBuilding
var porch: Boardwalk
## The valley's (G6): its plan and ground, given before it's in the tree; null in the old town.
var layout: ValleyLayout
var terrain: ValleyTerrain
## Where it stands (the valley's: worked out once from the plan).
var _site := Transform3D()

## The valley's place it stands on (config/valley.json).
const VALLEY_PLACE := "widow_homestead"
## Its middle in its own space (with the lean-to): put on the valley place's `at`.
const MIDDLE := Vector3(4.5, 0.0, 3.8)
## Where a try starts (FarmhouseMission's Enter, `--mission=farmhouse`) and the way out to below it,
## by world: the old town's road; in the valley the old start carried to the widow's (the same
## ground before the house as in town: the farm bot's runs hold it to that), and the lane's foot.
const TOWN_START := &"road_east"
const TOWN_BELOW := &"road_farm"
const VALLEY_START := &"farm_start"
const VALLEY_BELOW := &"farm_road"

## The farmhouse standing in the valley, if one is: the static helpers answer for it.
static var _valley: Farmhouse


static func of(tree: SceneTree) -> Farmhouse:
	return tree.get_first_node_in_group(&"farmhouse") as Farmhouse


## Where it stands: config/town.json's place, on the ground under its low corner (its uphill side
## set into the knoll by less than its floor's height, as the town's buildings are; the town layout
## test holds its y to TownLayout.footing).
static func origin() -> Transform3D:
	if is_instance_valid(_valley):
		return _valley._site
	return TownLayout.transform_of(&"Farmhouse")


## Whether the farmhouse in play is the valley's (G6).
static func in_valley() -> bool:
	return is_instance_valid(_valley)


## The authored ground's height where it stands (the old town's hills, or the valley's bake).
static func ground_at(x: float, z: float) -> float:
	if is_instance_valid(_valley):
		return _valley.terrain.height(x, z)
	return TownLayout.ground_height(x, z)


## A point of the old town's ground round its farmhouse (x, z there), carried to where the house
## stands now (as its hills were: the same place relative to it), on the ground: the farm bot's
## ways round the house, its start. In the old town the point itself.
static func carried(x: float, z: float) -> Vector3:
	var p := Vector3(x, 0.0, z)
	if is_instance_valid(_valley):
		p = _valley._site * (TownLayout.transform_of(&"Farmhouse").affine_inverse() * p)
	p.y = ground_at(p.x, p.z)
	return p


## The place a try starts from and the one below the house the way out ends at.
static func start_place() -> StringName:
	return VALLEY_START if in_valley() else TOWN_START


static func below_place() -> StringName:
	return VALLEY_BELOW if in_valley() else TOWN_BELOW


## Where it stands on the valley's place: its middle on the place's `at`, turned by its `facing`, on
## the ground under its low corner (TownLayout.footing's corners: its porch's edge in front, its
## back corners), as the old town's.
static func valley_site(l: ValleyLayout, t: ValleyTerrain) -> Transform3D:
	var p := l.place(VALLEY_PLACE)
	var at := ValleyLayout.xz(p.at)
	var b := Basis(Vector3.UP, deg_to_rad(float((p.get("farmhouse", {}) as Dictionary).get("facing", 180.0))))
	var o := Vector3(at.x, 0.0, at.y) - b * MIDDLE
	var low := INF
	for c: Vector3 in [Vector3(0, 0, -2.4), Vector3(WIDTH, 0, -2.4), Vector3(0, 0, DEPTH), Vector3(WIDTH, 0, DEPTH)]:
		var q := o + b * c
		low = minf(low, t.height(q.x, q.z))
	o.y = low
	return Transform3D(b, o)


## Its own space to the world's.
static func at(local: Vector3) -> Vector3:
	return origin() * local


## A point in its own space (x, z) on the ground outside it (the hills' height there), in the world.
static func on_ground(x: float, z: float) -> Vector3:
	var p := origin() * Vector3(x, 0.0, z)
	p.y = ground_at(p.x, p.z)
	return p


func _enter_tree() -> void:
	if layout != null:
		if terrain == null:
			terrain = ValleyTerrain.main()
		_site = valley_site(layout, terrain)
		_valley = self


func _exit_tree() -> void:
	if _valley == self:
		_valley = null


func _ready() -> void:
	add_to_group(&"farmhouse")
	transform = origin()
	building = SpecBuilding.new()
	building.name = "House"
	building.spec_path = SPEC
	building.structure_id = &"farmhouse"
	building.age_years = AGE
	add_child(building)
	porch = Boardwalk.new()
	porch.name = "Porch"
	porch.structure_id = &"farmhouse_porch"
	porch.length = WIDTH
	porch.walk_depth = 1.8
	porch.top = FLOOR
	porch.steps = [Vector2(2.8, 1.4)]
	porch.age_years = AGE
	add_child(porch)
	# Its lamps and fittings are the street's Fittings' (it collects after the street's built).


## The building's use point `id` (the spec's use_points: where the hostage sits, the guard stands,
## a man watches from), as [world position, the world point it looks at]; [] if there's none.
static func use_point(id: String) -> Array:
	for u: Dictionary in SpecBuilding.load_spec(SPEC).get("use_points", []):
		if u.id == id:
			var p := at(Vector3(u.at[0], u.at[1], u.at[2]))
			if float(u.at[1]) < 0.05:
				p.y = ground_at(p.x, p.z)
			var lk: Array = u.get("look", [u.at[0], u.at[2] - 1.0])
			var look := at(Vector3(lk[0], u.at[1], lk[1]))
			return [p, look]
	return []


## Its places, joined as a man walks between them and to the road back to town: up the lane to
## the porch and in at the door; the front room, the kitchen through its door in the back wall and
## out the back door; the bedroom through its door; up the stair to the loft and its window; round
## the house outside, front to back either side, to the outhouse.
static func add_places(w: Waypoints) -> void:
	# The road east out of town to below the farm, and the lane up the knoll.
	var road := func(x: float) -> Vector3: return TownLayout.street_point(x, 3.0)
	w.add(TOWN_START, road.call(40.0), [&"street_east"] if w.has(&"street_east") else [])
	w.add(TOWN_BELOW, road.call(98.0), [TOWN_START])
	add_house_places(w, TOWN_BELOW)


## In the valley (G6): the house's places, its lane's foot joined to `lane_end` (the valley's
## widow's lane's end, a place in `w`); the try's start and the place below the house the way out
## ends at (the old town's, carried: the same ground before the house), joined by `join` (a, b: the
## valley's, through places between where the ground slopes; none: linked straight).
static func add_valley_places(w: Waypoints, lane_end: StringName, join: Callable) -> void:
	w.add(VALLEY_BELOW, carried(98.0, TownLayout.street_z(98.0) + 3.0))
	w.add(VALLEY_START, carried(40.0, TownLayout.street_z(40.0) + 3.0))
	add_house_places(w, &"")
	if w.has(lane_end):
		w.link(&"farm_lane", lane_end)
	for pair: Array in [[&"farm_lane", VALLEY_BELOW], [VALLEY_BELOW, VALLEY_START]]:
		if join.is_valid():
			join.call(pair[0], pair[1])
		else:
			w.link(pair[0], pair[1])


## The house's own places (its lane's foot joined to `below`).
static func add_house_places(w: Waypoints, below: StringName) -> void:
	var g := FLOOR
	var u := LOFT
	var p := func(x: float, y: float, z: float) -> Vector3: return at(Vector3(x, y, z))
	var o := func(x: float, z: float) -> Vector3: return on_ground(x, z)
	w.add(&"farm_lane", o.call(2.8, -9.0), [below] if below != &"" else [])
	w.add(&"farm_steps", o.call(2.8, -2.5), [&"farm_lane"])
	w.add(&"farm_porch", p.call(2.8, g, -0.9), [&"farm_steps"])
	w.add(&"farm_porch_e", p.call(7.2, g, -0.9), [&"farm_porch"])
	w.add(&"farm_door", p.call(2.8, g, 0.45), [&"farm_porch"])
	# The front room: round the table (x 1.3..2.7, z 2.0..2.85) and its chairs.
	w.add(&"farm_room", p.call(3.3, g, 1.4), [&"farm_door"])
	w.add(&"farm_room_w", p.call(0.8, g, 1.4), [&"farm_room"])
	w.add(&"farm_room_stove", p.call(4.0, g, 1.5), [&"farm_room"])  # clear of the bedroom door's leaf (open into this room)
	w.add(&"farm_room_e", p.call(4.75, g, 3.35), [&"farm_room", &"farm_room_stove"])
	w.add(&"farm_room_back", p.call(1.0, g, 3.9))  # round the table by its back, not past its west chair
	w.add(&"farm_room_back_e", p.call(3.0, g, 3.75), [&"farm_room_back", &"farm_room_e"])
	# The kitchen through its door in the back wall (x 1.0), out the back door (x 4.4).
	w.add(&"farm_kitchen_door", p.call(1.0, g, 5.2), [&"farm_room_back"])
	# Square to the door before it (a slant from the kitchen's middle catches its jamb), clear of
	# its leaf (open into the kitchen along x 0.6).
	w.add(&"farm_kitchen_in", p.call(1.05, g, 5.8), [&"farm_kitchen_door"])
	w.add(&"farm_kitchen", p.call(1.6, g, 6.35), [&"farm_kitchen_in"])
	w.add(&"farm_kitchen_e", p.call(4.3, g, 6.35), [&"farm_kitchen"])  # between the table and the back door's leaf (open into the room)
	w.add(&"farm_back_door", p.call(4.4, g, 7.35), [&"farm_kitchen_e"])
	w.add(&"farm_back_steps", o.call(4.4, 8.7), [&"farm_back_door"])
	# The bedroom through its door in its wall (x 5.6, z 3.1).
	w.add(&"farm_bedroom_door_w", p.call(5.05, g, 3.1), [&"farm_room_e"])
	w.add(&"farm_bedroom_door", p.call(5.6, g, 3.1), [&"farm_bedroom_door_w"])
	w.add(&"farm_bedroom", p.call(6.3, g, 3.3), [&"farm_bedroom_door"])
	# Round the end of the door's leaf (open into the room along z 2.7 from the wall).
	w.add(&"farm_bedroom_mid", p.call(6.8, g, 3.0), [&"farm_bedroom"])
	w.add(&"farm_bedroom_s", p.call(6.8, g, 1.6), [&"farm_bedroom_mid"])
	w.add(&"farm_bedroom_e", p.call(8.3, g, 1.95), [&"farm_bedroom_s"])  # off a seam between boards
	# Up the stair (its foot at x 4.47, climbing west along the back wall to its head at x 2.1; its
	# newel at the foot and its rail up its room side are passed wide).
	w.add(&"farm_stair_foot", p.call(5.05, g, 4.65), [&"farm_room_e"])
	w.add(&"farm_stair_head", p.call(1.7, u, 4.65), [&"farm_stair_foot"])
	w.mark_stair(&"farm_stair_foot", &"farm_stair_head")
	w.add(&"farm_loft", p.call(1.2, u, 3.0), [&"farm_stair_head"])
	w.add(&"farm_loft_window", p.call(4.5, u, 0.8), [&"farm_loft"])
	w.add(&"farm_loft_e", p.call(7.0, u, 2.6), [&"farm_loft"])
	# Round the house outside: the yard each side of the porch, along the sides, the back.
	w.add(&"farm_yard_w", o.call(-2.0, -2.6), [&"farm_steps", &"farm_lane"])
	w.add(&"farm_yard_e", o.call(10.8, -2.6), [&"farm_steps", &"farm_lane"])
	w.add(&"farm_side_w", o.call(-2.2, 3.2), [&"farm_yard_w"])
	w.add(&"farm_side_e", o.call(11.0, 2.6), [&"farm_yard_e"])
	w.add(&"farm_back_w", o.call(-2.2, 9.2), [&"farm_side_w"])
	w.add(&"farm_back_e", o.call(11.0, 9.0), [&"farm_side_e"])
	w.add(&"farm_back", o.call(4.4, 9.6), [&"farm_back_w", &"farm_back_e", &"farm_back_steps"])
	w.add(&"farm_outhouse", o.call(7.6, 14.3), [&"farm_back"])
