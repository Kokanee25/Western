class_name StreetDressing
extends Node3D
## The test street dressed as the street painting has it (docs/concept/street-golden-hour.png):
## member-built false fronts down the street (the SALOON with its big painted board, the GENERAL
## STORE with DRY GOODS on its side, a barber and a hotel on the north side; the LIVERY barn, the
## JAIL and an assay office across), boardwalks before them, carriage lanterns by the doors,
## barrels, crates and hay along the boardwalks, a horse saddled at a rail, a covered wagon down
## the street, telegraph poles and a water tower over the roofs, townsfolk on the porches and in
## the street (FOLK), dry grass along the road's edges (DryGrass), and the red-rock country on the
## skyline (Backdrop: a painted backdrop on three rings). Models from PropModels on the texel grid;
## the big ones have a box to bump into. Everything keeps off the road's middle (the gang rides in along z -9) and the store's
## porch.
##
## Where it all stands is the town's layout (config/town.json, TownLayout: Sean's map). The tables
## below are where things stood on the old test street; each building is built where the layout
## puts it, and what was laid out round it (its rails, horses, barrels, hung boards, folk) is
## carried with it (TownLayout.carry), so it travels with its building till it's laid out again.
## A building the layout doesn't have (the façade saloon and store, now the real ones; the eating
## house, not on the map) isn't built, and whatever would stand on a flight of steps is left out.

## The buildings: [name, x0, x1, faces +Z (south side), {FalseFrontBuilding settings}]. The north
## side's fronts stand on z = 0 (the store's line), the south side's on z = -16.8 (the saloon's).
const NORTH_Z := 0.0
const SOUTH_Z := -16.8
const BUILDINGS := [
	["StreetSaloon", -10.8, -1.2, false, {"depth": 12.0, "wall_height": 4.6, "front_height": 8.4, "sign_text": "SALOON",
			"sign_from": 3.75, "door_size": Vector2(1.4, 2.3), "batwings": true, "front_wood": &"weathered_pine"}],
	["GeneralStore", -20.4, -11.8, false, {"depth": 11.0, "wall_height": 5.4, "front_height": 7.8,
			"sign_text": "GENERAL STORE", "sign_from": 3.75, "door_size": Vector2(1.3, 2.3), "front_wood": &"weathered_pine"}],
	["Barber", -27.4, -21.4, false, {"depth": 8.0, "wall_height": 3.4, "front_height": 5.6, "sign_text": "BARBER",
			"front_wood": &"painted_rust"}],
	["Hotel", -35.6, -28.4, false, {"depth": 10.0, "wall_height": 5.2, "front_height": 7.0, "sign_text": "HOTEL"}],
	["Livery", -17.0, -7.0, true, {"depth": 14.0, "wall_height": 4.4, "roof_pitch_degrees": 38.0, "gable_front": true,
			"door_size": Vector2(3.0, 3.0), "front_windows": false, "loft_door": Rect2(4.15, 4.6, 1.7, 1.5),
			"sign_text": "LIVERY", "gable_sign": Rect2(0.45, 1.6, 2.7, 3.6), "porch": false, "front_wood": &"weathered_pine"}],
	["Jail", -24.6, -18.2, true, {"depth": 8.0, "wall_height": 3.3, "front_height": 4.9, "sign_text": "JAIL",
			"window_bars": true, "front_wood": &"weathered_pine"}],
	["Assay", -32.0, -25.4, true, {"depth": 9.0, "wall_height": 3.6, "front_height": 5.8, "sign_text": "ASSAY OFFICE",
			"front_wood": &"painted_ochre"}],
	# Across from the saloon's door, low enough for the moon over its false front, its lamp lit
	# late: what you see through the door at night, as the painting does.
	["EatingHouse", 6.8, 13.2, false, {"depth": 9.0, "wall_height": 3.6, "front_height": 5.2, "sign_text": "EATING HOUSE",
			"furnished": true, "porch_lantern": true, "front_wood": &"painted_rust"}],
]
## Townsfolk where the painting has them (stand-ins: CivilianBrain at a post, so they get down
## when there's shooting): [name, feet, the point he faces, rest pose, shirt, vest, coat, hat,
## look]. A man on the saloon's porch, two on its bench, one at the store and one at the jail, and
## a few in the street, all off the gang's way in along z -9.
const FOLK := [
	["PorchLoafer", Vector3(-2.7, 0.38, -1.25), Vector3(1.0, 1.5, -7.0), &"stand", Color(0.78, 0.72, 0.6), Color(0.46, 0.13, 0.1),
			Color(0.3, 0.21, 0.14, 1.0), Color(0.14, 0.11, 0.09), {"hair": Color(0.14, 0.1, 0.07), "moustache": &"walrus", "beard": &"stubble", "age": 0.5}],
	["BenchManA", Vector3(-5.25, 0.38, -0.62), Vector3(-5.25, 1.0, -6.0), &"sit", Color(0.84, 0.82, 0.74), Color(0.2, 0.16, 0.12),
			Color(0, 0, 0, 0), Color(0.22, 0.17, 0.12), {"hair": Color(0.3, 0.2, 0.1), "moustache": &"handlebar", "beard": &"none", "age": 0.6}],
	["BenchManB", Vector3(-6.1, 0.38, -0.62), Vector3(-6.1, 1.0, -6.0), &"sit", Color(0.6, 0.48, 0.34), Color(0.14, 0.12, 0.1),
			Color(0, 0, 0, 0), Color(0.12, 0.1, 0.08), {"hair": Color(0.1, 0.08, 0.06), "moustache": &"trim", "beard": &"full", "age": 0.45}],
	["StoreMan", Vector3(-15.6, 0.38, -1.3), Vector3(-14.0, 1.5, -7.0), &"stand", Color(0.86, 0.84, 0.78), Color(0.3, 0.3, 0.32),
			Color(0, 0, 0, 0), Color(0, 0, 0, 0), {"hair": Color(0.2, 0.14, 0.09), "moustache": &"trim", "beard": &"none", "age": 0.55}],
	["StreetWalker", Vector3(-19.0, 0.0, -6.5), Vector3(-45.0, 1.5, -7.5), &"stand", Color(0.7, 0.64, 0.52), Color(0.2, 0.15, 0.1),
			Color(0.36, 0.26, 0.17, 1.0), Color(0.16, 0.12, 0.1), {"hair": Color(0.12, 0.09, 0.07), "moustache": &"walrus", "beard": &"stubble", "age": 0.4}],
	["FarManA", Vector3(-31.0, 0.0, -6.0), Vector3(-31.0, 1.5, -12.0), &"stand", Color(0.55, 0.5, 0.42), Color(0.18, 0.14, 0.1),
			Color(0, 0, 0, 0), Color(0.2, 0.15, 0.1), {"hair": Color(0.18, 0.12, 0.08), "moustache": &"walrus", "beard": &"none", "age": 0.5}],
	["FarManB", Vector3(-36.5, 0.0, -11.4), Vector3(-20.0, 1.5, -10.0), &"stand", Color(0.8, 0.76, 0.66), Color(0.26, 0.18, 0.12),
			Color(0.24, 0.2, 0.16, 1.0), Color(0.18, 0.14, 0.1), {"hair": Color(0.25, 0.18, 0.1), "moustache": &"handlebar", "beard": &"stubble", "age": 0.65}],
	["JailMan", Vector3(-21.4, 0.38, -15.55), Vector3(-21.4, 1.5, -8.0), &"stand", Color(0.7, 0.66, 0.58), Color(0.12, 0.1, 0.09),
			Color(0, 0, 0, 0), Color(0.1, 0.09, 0.08), {"hair": Color(0.1, 0.08, 0.06), "moustache": &"walrus", "beard": &"stubble", "age": 0.55}],
]


func _ready() -> void:
	_buildings()
	_lanterns()
	_loose()
	_far()
	_folk()
	var backdrop := Backdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	var grass := DryGrass.new()
	grass.name = "DryGrass"
	add_child(grass)


func _buildings() -> void:
	for i in BUILDINGS.size():
		var b: Array = BUILDINGS[i]
		var path := StringName("StreetDressing/%s" % b[0])
		var placed := TownLayout.entry(path)
		if placed.is_empty():
			continue
		var building := FalseFrontBuilding.new()
		building.name = b[0]
		building.structure_id = StringName((b[0] as String).to_snake_case())
		building.build_seed = 40 + i
		building.width = float(placed.get("width", (b[2] as float) - (b[1] as float)))
		# Down the street, nobody's inside yet: no counter or lamp, and the store's lantern stays
		# the only one hung under a porch (carriage lanterns by the doors instead).
		building.furnished = false
		building.porch_lantern = false
		var settings: Dictionary = b[4]
		for k in settings:
			building.set(k, settings[k])
		building.transform = TownLayout.transform_of(path)
		add_child(building)
		# Its boardwalk, up on steps, when the layout gives it steps.
		if placed.has("steps"):
			var walk := Boardwalk.new()
			walk.name = "%sWalk" % b[0]
			walk.structure_id = StringName("%s_walk" % (b[0] as String).to_snake_case())
			walk.length = building.width
			walk.steps = TownLayout.value("steps", placed["steps"])
			walk.transform = building.transform
			add_child(walk)
	# The painting's DRY GOODS board on the general store's side (the real one, the street's).
	var store := get_parent().get_node_or_null(^"Store") as FalseFrontBuilding
	if store:
		_side_board(store, &"sign_dry_goods")


## Where whatever stood at `at` on the old street stands now, turned `yaw` degrees: carried with
## the building it stood by (TownLayout.carry), or left where it was out in the street.
static func carried(at: Vector3, yaw := 0.0) -> Transform3D:
	return TownLayout.carry(at) * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)


## True where a thing `radius` round would stand on a flight of steps or in the way up them, or
## in front of a door (people come and go by the steps and the doors).
static func on_steps(at: Vector3, radius := 0.6) -> bool:
	return _on_flight(at, radius) or in_doorway(at, radius)


## True where a thing `radius` round would stand in a doorway or just before it on the walk: the
## store's, the saloon's and the street's buildings' (their doors in the middle of their fronts).
static func in_doorway(at: Vector3, radius := 0.4) -> bool:
	return out_of_doorway(at, radius) != at


## `at` moved along the walk to the nearer side of a doorway it stands in (unchanged if none).
static func out_of_doorway(at: Vector3, radius := 0.4) -> Vector3:
	for path: String in TownLayout.nodes():
		var e: Dictionary = TownLayout.nodes()[path]
		var w := float(e.get("width", (e.get("set", {}) as Dictionary).get("width", 0.0)))
		if path == "Saloon":
			w = 10.0
		if w <= 0.0 or not (path in ["Store", "Saloon"] or path.begins_with("StreetDressing/")) or path.ends_with("WaterTower"):
			continue
		var t := TownLayout.transform_of(StringName(path))
		var local := t.affine_inverse() * at
		var half := 0.75 + 0.6 + radius
		var off := local.x - w * 0.5
		if absf(off) < half and local.z < 0.3 + radius and local.z > -2.0 - radius:
			local.x = w * 0.5 + (half + 0.05) * (1.0 if off >= 0.0 else -1.0)
			local.z = maxf(local.z, -0.75)  # against the wall, out of the way along the walk
			return t * local
	return at


static func _on_flight(at: Vector3, radius := 0.6) -> bool:
	for path: String in TownLayout.nodes():
		var e: Dictionary = TownLayout.nodes()[path]
		var steps: Array = e.get("steps", (e.get("set", {}) as Dictionary).get("steps", []))
		if steps.is_empty():
			continue
		var local := TownLayout.transform_of(StringName(path)).affine_inverse() * at
		for st: Array in steps:
			var half := float(st[1]) * 0.5 + 0.4 + radius
			if absf(local.x - float(st[0])) < half and local.z < -1.6 + radius and local.z > -4.6 - radius:
				return true
	return false


## The painting's DRY GOODS / TOOLS / HARDWARE / PROVISIONS board, high on the store's side wall
## toward the street end (seen past the saloon's roof).
func _side_board(building: FalseFrontBuilding, id: StringName) -> void:
	var painted := SignArt.board_size(id)
	if painted == Vector2.ZERO:
		return
	var size := painted * minf(2.8 / painted.x, 1.6 / painted.y)
	var board := SignArt.board(id, size)
	board.name = "SideBoard"
	building.add_child(board)
	# The right-hand wall (local +X: the street's east) faces +X; the board's front faces +Z.
	board.transform = Transform3D(Basis(Vector3.UP, PI * 0.5),
			Vector3(building.width + 0.04, building.wall_height - 0.2 - size.y * 0.5, 0.5 + size.x * 0.5))


## A carriage lantern either side of each door, lit from dusk.
func _lanterns() -> void:
	for b: Array in BUILDINGS:
		var path := StringName("StreetDressing/%s" % b[0])
		var placed := TownLayout.entry(path)
		if placed.is_empty():
			continue
		var t := TownLayout.transform_of(path)
		var faces := -1.0 if float(placed.get("facing", 0.0)) == 0.0 else 1.0
		var settings: Dictionary = b[4]
		if settings.get("gable_front", false):
			# The livery's, by its big door.
			_lantern(t * Vector3(3.35, 2.6, -0.05), faces)
			continue
		var w := float(placed.get("width", (b[2] as float) - (b[1] as float)))
		var door: Vector2 = settings.get("door_size", Vector2(1.1, 2.2))
		for side in [-1.0, 1.0]:
			# In the building's own space: the front faces -Z.
			var local := Vector3(w * 0.5 + side * (door.x * 0.5 + 0.4), 2.25, -0.05)
			_lantern(t * local, faces)


func _lantern(at: Vector3, faces: float) -> void:
	var root := Node3D.new()
	root.name = "Lantern"
	PropModels.lantern(root)
	add_child(root)
	root.global_transform = Transform3D(Basis(Vector3.UP, 0.0 if faces > 0.0 else PI), at)
	var lamp := OilLamp.new()
	lamp.set_meta(&"lamp_group", &"lantern")
	lamp.show_mesh = false
	lamp.energy = 0.9
	lamp.light_range = 6.0
	lamp.haze = 1.6
	lamp.casts_shadows = false
	lamp.lit_from_hour = 17  # lit before the sun's down, as the painting has them
	lamp.lit_until_hour = 6
	root.add_child(lamp)
	lamp.position = Vector3(0, -0.08, 0.2)


## Barrels, crates and hay along the fronts; a horse at a rail before the livery.
func _loose() -> void:
	# On the north boardwalk (its top 0.38 m up).
	for p in [Vector3(-1.9, 0.38, -0.75), Vector3(-6.9, 0.38, -0.7)]:
		_prop(&"barrel", p, 0.0)
	for c in [[Vector3(-2.7, 0.38, -0.8), 10.0], [Vector3(-2.75, 0.98, -0.8), 35.0], [Vector3(-7.8, 0.38, -0.8), -15.0]]:
		_model("Crate", PropModels.crate, c[0], c[1], Vector3(0.6, 0.6, 0.6))
	for p in [Vector3(-7.8, 0.0, -15.9), Vector3(-9.0, 0.0, -16.0), Vector3(-8.4, 0.45, -15.95), Vector3(-16.6, 0.0, -15.9)]:
		_model("Hay", PropModels.hay_bale, p, 0.0, Vector3(0.9, 0.45, 0.5))
	_prop(&"barrel", Vector3(-15.4, 0.0, -16.1), 0.0)
	# On the jail's boardwalk.
	_prop(&"barrel", Vector3(-19.4, 0.38, -15.9), 0.0)
	_model("Crate", PropModels.crate, Vector3(-24.3, 0.38, -15.8), 20.0, Vector3(0.6, 0.6, 0.6))
	# The rail before the livery, and a bay horse tied to it.
	_rail("LiveryRail", -14.6, -11.8, -14.2)
	_model("Horse", PropModels.horse, Vector3(-13.0, 0.0, -14.75), 0.0, Vector3(2.4, 1.8, 0.6))
	# The street crowded as the painting's is: rails with horses nosed in before the saloon and the
	# store, more barrels and crates along both boardwalks, a buckboard by the jail, boards hung
	# under the porches. All kept off the road's middle and the gang's way in (z -9).
	_rail("SaloonRail", -8.2, -4.6, -2.9)
	for h in [[Vector3(-7.4, 0.0, -4.1), 90.0], [Vector3(-5.4, 0.0, -4.0), 84.0]]:
		_model("Horse", PropModels.horse, h[0], h[1], Vector3(2.4, 1.8, 0.6))
	_rail("StoreRail", -18.6, -15.8, -2.9)
	_model("Horse", PropModels.horse, Vector3(-17.2, 0.0, -4.05), 95.0, Vector3(2.4, 1.8, 0.6))
	_rail("JailRail", -23.8, -21.0, -14.0)
	_model("Horse", PropModels.horse, Vector3(-22.6, 0.0, -12.85), -88.0, Vector3(2.4, 1.8, 0.6))
	for p in [Vector3(-9.6, 0.38, -0.7), Vector3(-10.25, 0.38, -0.75), Vector3(-19.9, 0.38, -0.7), Vector3(-26.2, 0.38, -0.75),
			Vector3(-26.9, 0.38, -0.7), Vector3(-25.6, 0.38, -15.95), Vector3(-30.9, 0.38, -16.0)]:
		_prop(&"barrel", p, 0.0)
	for c in [[Vector3(-11.0, 0.38, -0.8), 5.0], [Vector3(-11.1, 0.98, -0.8), -20.0], [Vector3(-20.7, 0.38, -0.85), 12.0],
			[Vector3(-27.8, 0.38, -0.8), -8.0], [Vector3(-27.85, 0.98, -0.75), 25.0], [Vector3(-26.4, 0.38, -15.9), 30.0],
			[Vector3(-31.8, 0.38, -15.85), -12.0], [Vector3(-31.75, 0.98, -15.9), 8.0]]:
		_model("Crate", PropModels.crate, c[0], c[1], Vector3(0.6, 0.6, 0.6))
	_model("Buckboard", PropModels.wagon, Vector3(-27.5, 0.0, -13.0), 0.0, Vector3(3.4, 2.2, 1.8), false)
	# Boards hung under the porches, end on to the street so you read them looking down it.
	for b in [["MEALS", Vector3(-12.2, 2.45, -1.95)], ["BATHS", Vector3(-21.9, 2.45, -1.95)], ["ROOMS", Vector3(-28.6, 2.45, -1.95)],
			["GUNSMITH", Vector3(-34.2, 2.45, -1.95)], ["SHERIFF", Vector3(-19.0, 2.45, -14.85)], ["ASSAYS", Vector3(-26.0, 2.45, -14.85)]]:
		_hung_board(b[0], b[1])


## Down the street and over the roofs: a covered wagon, telegraph poles with their wire, the water
## tower.
func _far() -> void:
	_model("Wagon", PropModels.wagon, Vector3(-36.0, 0.0, -12.6), 0.0, Vector3(3.4, 2.2, 1.8), false)
	# Half a metre into the street from the south boardwalks' edge (at -13.9 the jail's pole stood
	# through the boardwalk: tools/visual_checks.py's floating/sunk check).
	var poles := [Vector3(-2.0, 0.0, -13.4), Vector3(-27.0, 0.0, -13.4), Vector3(-52.0, 0.0, -13.4), Vector3(-77.0, 0.0, -13.4)]
	for p in poles:
		_model("Pole", PropModels.telegraph_pole, p, 0.0, Vector3(0.25, 7.0, 0.25), false)
	var wire := PropModels.iron()
	for i in poles.size() - 1:
		for x in [-0.55, 0.55]:
			var a: Vector3 = poles[i] + Vector3(0, 6.78, x)
			var b: Vector3 = poles[i + 1] + Vector3(0, 6.78, x)
			# Two straight runs sagging to a low point in the middle.
			var mid := (a + b) * 0.5 + Vector3.DOWN * 0.45
			for seg in [[a, mid], [mid, b]]:
				var d: Vector3 = seg[1] - seg[0]
				PropModels._box(self, "Wire", Vector3(0.012, 0.012, d.length()), (seg[0] + seg[1]) * 0.5, wire,
						Basis.looking_at(d, Vector3.UP))
	# In the yard behind the jail, as the map has it (over the roofs on the right, down the street).
	var tower := TownLayout.entry(&"StreetDressing/WaterTower")
	var at: Array = tower.get("at", [-34.0, 0.0, -24.0])
	_model("WaterTower", PropModels.water_tower, Vector3(at[0], at[1], at[2]), float(tower.get("facing", 20.0)), Vector3(3.8, 11.5, 3.8), false)


## A hitching rail: two posts and a bar from x0 to x1 at z (on the old street; carried).
func _rail(n: String, x0: float, x1: float, z: float) -> void:
	var t := carried(Vector3((x0 + x1) * 0.5, 0.0, z))
	if on_steps(t.origin, (x1 - x0) * 0.5):
		return
	var rail := Node3D.new()
	rail.name = n
	add_child(rail)
	rail.transform = t
	var wood := PropModels.dark_wood()
	var half := (x1 - x0) * 0.5
	for x in [-half, half]:
		PropModels._box(rail, "Post", Vector3(0.12, 1.1, 0.12), Vector3(x, 0.55, 0.0), wood)
	PropModels._box(rail, "Bar", Vector3(x1 - x0 + 0.2, 0.1, 0.1), Vector3(0.0, 1.0, 0.0), wood)


## A small lettered board hung from a porch on two chains, its faces toward either end of the
## street (painted letters, both sides).
func _hung_board(text: String, at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "HungBoard"
	add_child(root)
	root.transform = carried(at)
	var w := 0.25 + 0.17 * text.length()
	PropModels._box(root, "Board", Vector3(0.04, 0.42, w), Vector3.ZERO, PropModels.weathered())
	for z in [-w * 0.4, w * 0.4]:
		PropModels._box(root, "Chain", Vector3(0.015, 0.4, 0.015), Vector3(0, 0.41, z), PropModels.iron())
	for side in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = text
		label.font_size = 18
		label.pixel_size = 0.016
		label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		label.outline_size = 0
		label.modulate = Color(0.16, 0.1, 0.07)
		label.shaded = true
		label.double_sided = false
		label.position = Vector3(side * 0.022, 0.0, 0.0)
		label.rotation.y = PI * 0.5 * side
		root.add_child(label)


## The townsfolk (FOLK), and the saloon porch's bench under the two sitting there.
func _folk() -> void:
	_model("Bench", _bench, Vector3(-5.68, 0.38, -0.5), 0.0, Vector3(1.9, 0.45, 0.42))
	for i in FOLK.size():
		var f: Array = FOLK[i]
		var man := HumanBody.new()
		man.name = f[0]
		man.person_id = StringName(String(f[0]).to_snake_case())
		man.rng_seed = 201 + i
		man.has_gun = false
		man.use_paint = false
		man.shirt_color = f[4]
		man.vest_color = f[5]
		man.coat_color = f[6]
		man.hat_color = f[7]
		man.bandana_color = Color(0, 0, 0, 0)
		man.look = f[8]
		var brain := CivilianBrain.new()
		brain.name = "Brain"
		brain.post = post_of(f)
		brain.faces = TownLayout.carry(f[1]) * (f[2] as Vector3)
		# Moved out of a doorway, a man who sat on the bench there stands (the bench is left out).
		brain.rest_pose = f[3] if brain.post.is_equal_approx(TownLayout.carry(f[1]) * (f[1] as Vector3)) else &"stand"
		man.add_child(brain)
		add_child(man)
		man.global_position = brain.post
		man.face(brain.faces)
		man.set_pose(brain.rest_pose)


## Where a townsman of FOLK stands on the street as it is now (his post, carried with his building).
static func post_of(f: Array) -> Vector3:
	return out_of_doorway(TownLayout.carry(f[1]) * (f[1] as Vector3), 0.3)


## A plain porch bench: a plank seat on two legs each end, 0.45 m high.
static func _bench(root: Node3D) -> void:
	var wood := PropModels.dark_wood()
	PropModels._box(root, "Seat", Vector3(1.9, 0.05, 0.4), Vector3(0, 0.425, 0), wood)
	for x in [-0.82, 0.82]:
		PropModels._box(root, "Leg", Vector3(0.06, 0.4, 0.34), Vector3(x, 0.2, 0), wood)
	PropModels._box(root, "Rail", Vector3(1.64, 0.06, 0.04), Vector3(0, 0.12, 0), wood)


func _prop(id: StringName, at: Vector3, yaw: float) -> void:
	var t := carried(at, yaw)
	if on_steps(t.origin, 0.35):
		return
	var p := PropLibrary.spawn(id)
	add_child(p)
	p.global_transform = t


## A PropModels model at `at`, turned `yaw` degrees, with a box of `size` (bottom at its feet)
## to bump into and to stop a bullet; `carry`: at is on the old street, carried with its building
## (and left out if it would stand on a flight of steps).
func _model(n: String, build: Callable, at: Vector3, yaw: float, size: Vector3, carry := true) -> Node3D:
	var t := carried(at, yaw) if carry else Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
	if carry and on_steps(t.origin, maxf(size.x, size.z) * 0.5):
		return null
	var body := StaticBody3D.new()
	body.name = n
	body.set_meta(&"model_name", n)
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	body.global_transform = t
	var model := Node3D.new()
	model.name = "Model"
	body.add_child(model)
	build.call(model)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(shape)
	return body
