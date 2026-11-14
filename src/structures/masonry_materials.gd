class_name MasonryMaterials
extends RefCounted
## The masonry lab's numbers, read from config/destruction/materials.json (the engine-neutral data:
## docs/destruction/destruction-spec.md sections 3, 5 and 6; brief docs/briefs/masonry-lab.md). No
## masonry number lives in GDScript: everything a rule reads comes through here.
##
## A masonry member's `wood` is its material id (`rubble_stone`, `adobe`, `cut_stone`,
## `fired_brick`). `is_masonry` is the one test the game asks ("does it ring like stone, never burn,
## carve as stone, throw stone dust?"), counting the older `stone` (the trestle's piers, the well's
## ring, footings) as masonry too.

const PATH := "res://config/destruction/materials.json"
## The game's own stone (TimberTuning's `stone`), masonry before the lab had materials.
const OLD_STONE := &"stone"

static var _data: Dictionary = {}
static var _masonry := {}  # material id (StringName) -> true


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {"materials": {}, "mortars": {}, "solver": {}}
		_masonry.clear()
		for id: String in (_data.get("materials", {}) as Dictionary):
			var m: Dictionary = _data.materials[id]
			# Timber in masonry is the game's timber (its rules are TimberTuning's), not a unit.
			if m.has("unit") and not bool(m.get("burns", false)):
				_masonry[StringName(id)] = true
	return _data


## Is `wood` masonry (a material of materials.json's, or the game's older `stone`)?
static func is_masonry(wood: StringName) -> bool:
	if wood == OLD_STONE:
		return true
	data()
	return _masonry.has(wood)


## A material's entry ({} if it isn't one).
static func material(id: StringName) -> Dictionary:
	return data().get("materials", {}).get(String(id), {})


## A material's mortar's entry.
static func mortar_of(id: StringName) -> Dictionary:
	var m := material(id)
	return data().get("mortars", {}).get(String(m.get("mortar", "")), {})


static func mortar(id: String) -> Dictionary:
	return data().get("mortars", {}).get(id, {})


## The solver's dials (the same for every material).
static func solver() -> Dictionary:
	return data().get("solver", {})


static func dial(key: String, default := 0.0) -> float:
	return float(solver().get(key, default))


## kg/m³ of a masonry material's units (the older `stone`: TimberTuning's, as before).
static func density(wood: StringName, fallback := 2300.0) -> float:
	var m := material(wood)
	return float(m.unit.density) if m.has("unit") else fallback


## J to carve out a cm³ by a ball (small hits, spec section 4), or `fallback`.
static func carve_j_per_cm3(wood: StringName, fallback: float) -> float:
	var m := material(wood)
	return float(m.small_hit.j_per_cm3) if m.has("small_hit") else fallback


## The colour of the dust it throws up, or `fallback`.
static func dust_colour(wood: StringName, fallback: Color) -> Color:
	var m := material(wood)
	if not m.has("dust_colour"):
		return fallback
	var c: Array = m.dust_colour
	return Color(float(c[0]), float(c[1]), float(c[2]))
