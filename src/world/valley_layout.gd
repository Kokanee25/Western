class_name ValleyLayout
extends RefCounted
## The new valley's plan as data, from `config/valley.json` (docs/briefs/valley-plan.md; the
## migration's G1): a pure reader with getters, as TownLayout is for config/town.json, for the
## valley scene and the steps after it (G2's ground, G3's railway, G4's places). It builds
## nothing and holds nothing but the file. Positions on the map are Vector2(x, z) in metres, x east,
## z south (north is -Z); the crossroads (Main Street x North-South Street) is the origin. A place,
## road, bridge or lot is the file's own Dictionary (its `status`, `_doc` and the rest as written),
## or {} when the file has none by that id. `ValleyLayout.main()` is the game's file, read once;
## `ValleyLayout.new(dict)` reads any other (the tests).

const PATH := "res://config/valley.json"
## The format this reader knows (the file's `format`).
const FORMAT := 1

static var _main: ValleyLayout

var data: Dictionary = {}


func _init(d: Dictionary = {}) -> void:
	data = d


## The game's valley (config/valley.json), read on first use.
static func main() -> ValleyLayout:
	if _main == null:
		_main = load_file(PATH)
	return _main


## A valley from a file; an empty one (and an error) if it can't be read.
static func load_file(path: String) -> ValleyLayout:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("ValleyLayout: can't read %s" % path)
		return ValleyLayout.new()
	if int((parsed as Dictionary).get("format", 0)) != FORMAT:
		push_warning("ValleyLayout: %s is format %s, this reader knows %d" % [path, (parsed as Dictionary).get("format"), FORMAT])
	return ValleyLayout.new(parsed)


## [x, z] from the file as a map point.
static func xz(a: Variant) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO


## A polyline from the file ([[x, z, ...], ...]) as map points; extra numbers per point (the
## creek's bed level, width, depth) are left for `line_rows`.
static func xz_line(a: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	if a is Array:
		for p: Variant in a:
			out.append(xz(p))
	return out


# --- The frame and the envelope ---

## The crossroads, the valley's origin (Y 0 is its ground).
func crossroads() -> Vector3:
	return Vector3.ZERO


## Main Street's heading in compass degrees (0 north, 90 east): due west, so the setting sun
## shines straight down it (the frame's DECIDED axis).
func main_street_heading() -> float:
	return 270.0


## The playable area on the map: x -2000..2400, z -1400..2200 as planned. Rect2's x is world x,
## its y world z.
func envelope() -> Rect2:
	var p: Dictionary = (data.get("envelope", {}) as Dictionary).get("playable", {})
	var x: Array = p.get("x", [0, 0])
	var z: Array = p.get("z", [0, 0])
	return Rect2(float(x[0]), float(z[0]), float(x[1]) - float(x[0]), float(z[1]) - float(z[0]))


## Each side's boundary rule ({side, how}).
func boundaries() -> Array:
	return (data.get("envelope", {}) as Dictionary).get("boundaries", [])


func speeds() -> Dictionary:
	return data.get("speeds", {})


# --- Places, viewpoints, missions ---

func places() -> Array:
	return data.get("places", [])


func place_ids() -> PackedStringArray:
	return _ids(places())


## A place by id; an unknown one is an error (not the map's origin without a word: review A8, #864).
func place(id: String) -> Dictionary:
	var p := _by_id(places(), id)
	if p.is_empty():
		push_error("ValleyLayout: no place '%s' in valley.json's places" % id)
	return p


func has_place(id: String) -> bool:
	return not _by_id(places(), id).is_empty()


## Where a place stands on the map (its `at`).
func place_at(id: String) -> Vector2:
	return xz(place(id).get("at"))


## A place's level pad ({w, d, y}), or {} if it has none.
func place_pad(id: String) -> Dictionary:
	return place(id).get("pad", {})


func viewpoints() -> Array:
	return data.get("viewpoints", [])


func viewpoint(id: String) -> Dictionary:
	return _by_id(viewpoints(), id)


func missions() -> Array:
	return data.get("missions", [])


func mission(id: String) -> Dictionary:
	return _by_id(missions(), id)


## The places with height (#736 B): each with its `why`, `above`, `below`, its `landform` (in the
## bake), `block` (the greybox), `high` (where the shooter stands) and `targets`.
func heights() -> Array:
	return data.get("heights", [])


func height(id: String) -> Dictionary:
	return _by_id(heights(), id)


## A place, bridge, viewpoint or place with height by id (what a mission's `places` name), or {}.
func entry(id: String) -> Dictionary:
	for list: Array in [places(), bridges(), viewpoints(), heights()]:
		var e := _by_id(list, id)
		if not e.is_empty():
			return e
	return {}


# --- Roads and bridges ---

func roads() -> Array:
	return data.get("roads", [])


func road_ids() -> PackedStringArray:
	return _ids(roads())


func road(id: String) -> Dictionary:
	return _by_id(roads(), id)


## A road's middle line on the map.
func road_line(id: String) -> PackedVector2Array:
	return xz_line(road(id).get("line"))


## A road's length along its line, in metres.
func road_length(id: String) -> float:
	return line_length(road_line(id))


func bridges() -> Array:
	return data.get("bridges", [])


func bridge(id: String) -> Dictionary:
	return _by_id(bridges(), id)


# --- Water ---

## The creek, the canyon, the arroyo, the ditch by their key in `water` (creek, canyon, arroyo,
## ditch), or by their id (salt_creek, great_canyon, dry_arroyo, town_ditch).
func water(key: String) -> Dictionary:
	var w: Dictionary = data.get("water", {})
	if w.get(key) is Dictionary:
		return w[key]
	for k: String in w:
		if w[k] is Dictionary and (w[k] as Dictionary).get("id", "") == key:
			return w[k]
	return {}


## A water course's line on the map (the creek's, the arroyo's, the ditch's).
func water_line(key: String) -> PackedVector2Array:
	return xz_line(water(key).get("line"))


## A water course's rows as written: [x, z, then the course's own numbers] (the creek's bed
## level, width, depth and roughness), for the bake (G2).
func water_rows(key: String) -> Array:
	return water(key).get("line", [])


func springs() -> Array:
	return (data.get("water", {}) as Dictionary).get("springs", [])


# --- The railway ---

func railway() -> Dictionary:
	return data.get("railway", {})


## The main line in TrainRoute's own format (laid in G3).
func route_dict() -> Dictionary:
	return railway().get("route", {})


## The main line as a TrainRoute, as the train lab's routes are.
func route() -> TrainRoute:
	return TrainRoute.from_dict(route_dict())


## A named mark along the line (metres from its east end), or -1.
func route_mark(id: String) -> float:
	return float((route_dict().get("marks", {}) as Dictionary).get(id, -1.0))


func tracks() -> Array:
	return railway().get("tracks", [])


func stops() -> Array:
	return railway().get("stops", [])


# --- The town ---

func town() -> Dictionary:
	return data.get("town", {})


## Main Street's ends in x (it runs along z 0).
func main_street_x() -> Vector2:
	var x: Array = (town().get("main_street", {}) as Dictionary).get("x", [0, 0])
	return Vector2(float(x[0]), float(x[1]))


## The town's lots on one side of Main Street, west to east: "north" or "south".
func lots(side: String) -> Array:
	return town().get(side, [])


## A lot (either side) or one of the town's extras (the second saloon...), by id.
func lot(id: String) -> Dictionary:
	for side in ["north", "south", "extras"]:
		var l := _by_id(town().get(side, []), id)
		if not l.is_empty():
			return l
	return {}


## The town's buildings (lots of kind "building", both sides).
func town_buildings() -> Array:
	var out: Array = []
	for side in ["north", "south"]:
		for l: Dictionary in lots(side):
			if l.get("kind", "") == "building":
				out.append(l)
	return out


# --- Helpers ---

static func line_length(line: PackedVector2Array) -> float:
	var d := 0.0
	for i in range(1, line.size()):
		d += line[i - 1].distance_to(line[i])
	return d


static func _ids(list: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for e: Variant in list:
		if e is Dictionary and (e as Dictionary).has("id"):
			out.append(String(e["id"]))
	return out


static func _by_id(list: Array, id: String) -> Dictionary:
	for e: Variant in list:
		if e is Dictionary and (e as Dictionary).get("id", "") == id:
			return e
	return {}
