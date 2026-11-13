class_name ValleyScatterTuning
extends Resource
## What grows and lies on the valley's land, and how far it's drawn (#891; ValleyScatter). Edit
## config/valley_scatter.tres, not code.
##
## Each species: `meshes` (near pieces: a scan's `<dir><piece>_near.res`, its `_far.res` beyond
## `near_m`; or `tree` a ValleyTrees kind), `cell` (m: a cell's side, one MultiMesh a piece a cell),
## `per_100m2` (candidates a hundred square metres, before the rules), `range` (m: drawn to),
## `near_m` (m: the near pieces to), `scale` [min, max], `sink` (share of its height in the ground),
## `plant` (a scanned plant drawn by src/art/scatter_plant.gdshader: {saturation, brightness, vary}),
## `tilt` (how far it leans with the slope, 0..1), `shadows`, `collide` (a body: "sphere", "trunk" or
## none), `fade` (m: dithered out over the last metres; StandardMaterial3D's distance fade), `tint`
## (multiplied into the scan's albedo), and its rule's numbers (ValleyScatter._chance says how they
## are used): `slope` [from, to] degrees it grows on, `wet` (more near water: 1 doubles at the bank),
## `dry` (fewer near water), `high` [from, to] metres over the crossroads it favours, `clear` (m off a
## road's edge), `town` (m from the town's lots and streets it starts), `patch` (0 even .. 1 in
## clumps), `patch_m` (the clumps' size, m).

@export var species: Array[Dictionary] = [
	{"name": "grass", "dir": "res://assets/props/scans/grass_medium_02/",
	 "meshes": ["grass_medium_02_c", "grass_medium_02_d", "grass_medium_02_e"],
	 "cell": 32.0, "per_100m2": 90.0, "range": 75.0, "near_m": 28.0, "fade": 20.0, "scale": [1.6, 2.8],
	 "sink": 0.05, "tilt": 0.6, "shadows": false, "tint": [1.32, 1.08, 0.62],
	 "plant": {"saturation": 0.45, "brightness": 1.15, "vary": 0.22},
	 "slope": [0.0, 30.0], "wet": 0.8, "dry": 0.0, "high": [-40.0, 60.0], "clear": 0.4, "town": 6.0,
	 "patch": 0.6, "patch_m": 9.0},
	{"name": "stones", "dir": "res://assets/props/scans/namaqualand_stones_01/",
	 "meshes": ["namaqualand_stones_01_b", "namaqualand_stones_01_c", "namaqualand_stones_01_e"],
	 "cell": 32.0, "per_100m2": 4.0, "range": 55.0, "near_m": 55.0, "fade": 10.0, "scale": [1.5, 4.0],
	 "sink": 0.35, "tilt": 1.0, "shadows": false, "tint": [1.0, 0.92, 0.82],
	 "slope": [2.0, 45.0], "wet": 0.0, "dry": 0.0, "high": [-40.0, 200.0], "clear": 0.0, "town": 0.0,
	 "patch": 0.7, "patch_m": 14.0},
	{"name": "sage", "dir": "res://assets/props/scans/wild_rooibos_bush/",
	 "meshes": ["wild_rooibos_bush_b", "wild_rooibos_bush_c", "wild_rooibos_bush_d"],
	 "cell": 96.0, "per_100m2": 5.0, "range": 320.0, "near_m": 60.0, "fade": 40.0, "scale": [1.2, 2.2],
	 "sink": 0.08, "tilt": 0.3, "shadows": true, "tint": [0.86, 0.95, 0.80],
	 "plant": {"saturation": 0.3, "brightness": 1.5, "vary": 0.12},
	 "slope": [0.0, 24.0], "wet": 0.0, "dry": 1.0, "high": [-20.0, 70.0], "clear": 1.5, "town": 25.0,
	 "patch": 0.75, "patch_m": 40.0},
	{"name": "rocks", "dir": "res://assets/props/scans/namaqualand_rocks_01/",
	 "meshes": ["namaqualand_rocks_02_a", "namaqualand_rocks_02_c", "namaqualand_rocks_02_d"],
	 "cell": 64.0, "per_100m2": 0.8, "range": 160.0, "near_m": 45.0, "fade": 25.0, "scale": [2.5, 6.0],
	 "sink": 0.3, "tilt": 1.0, "shadows": true, "tint": [1.0, 0.94, 0.86],
	 "slope": [6.0, 50.0], "wet": 0.0, "dry": 0.0, "high": [-40.0, 200.0], "clear": 1.0, "town": 12.0,
	 "patch": 0.8, "patch_m": 30.0},
	{"name": "boulders", "dir": "res://assets/props/scans/",
	 "meshes": ["namaqualand_boulder_03/boulder_03_lod0", "namaqualand_boulder_05/namaqualand_boulder_05", "rock_07/rock_07"],
	 "piece_scale": [1.0, 2.2, 9.0],
	 "cell": 128.0, "per_100m2": 0.06, "range": 600.0, "near_m": 90.0, "fade": 60.0, "scale": [0.6, 1.6],
	 "sink": 0.3, "tilt": 0.8, "shadows": true, "collide": "sphere", "tint": [1.0, 0.95, 0.88],
	 "slope": [10.0, 55.0], "wet": 0.0, "dry": 0.0, "high": [-40.0, 200.0], "clear": 3.0, "town": 40.0,
	 "patch": 0.85, "patch_m": 60.0},
	{"name": "logs", "dir": "res://assets/props/scans/dead_tree_trunk_02/", "meshes": ["dead_tree_trunk_02"],
	 "cell": 128.0, "per_100m2": 0.01, "range": 200.0, "near_m": 60.0, "fade": 30.0, "scale": [0.8, 1.3],
	 "sink": 0.15, "tilt": 1.0, "shadows": true, "collide": "", "tint": [0.9, 0.88, 0.85],
	 "slope": [0.0, 25.0], "wet": 0.6, "dry": 0.0, "high": [20.0, 200.0], "clear": 3.0, "town": 60.0,
	 "patch": 0.9, "patch_m": 80.0},
	{"name": "pines", "tree": "pine",
	 "cell": 192.0, "per_100m2": 0.12, "range": 1400.0, "near_m": 140.0, "fade": 0.0, "scale": [0.65, 1.2],
	 "sink": 0.0, "tilt": 0.0, "shadows": true, "collide": "trunk",
	 "slope": [0.0, 40.0], "wet": 0.0, "dry": 0.0, "high": [28.0, 200.0], "clear": 4.0, "town": 120.0,
	 "patch": 0.8, "patch_m": 90.0},
	{"name": "cottonwoods", "tree": "cottonwood",
	 "cell": 192.0, "per_100m2": 0.35, "range": 1400.0, "near_m": 140.0, "fade": 0.0, "scale": [0.75, 1.25],
	 "sink": 0.0, "tilt": 0.0, "shadows": true, "collide": "trunk", "water_within": 14.0,
	 "slope": [0.0, 20.0], "wet": 3.0, "dry": 0.0, "high": [-40.0, 40.0], "clear": 4.0, "town": 15.0,
	 "patch": 0.6, "patch_m": 50.0},
]

## The town's lots and streets (x0, z0, x1, z1 in the valley's metres): `town` counts from its edge.
@export var town_rect := Rect2(-175.0, -125.0, 365.0, 275.0)
## Cells built a frame at most (ms; the first build round the camera, and after a jump of more than
## `jump_m`, is done at once).
@export var build_ms := 2.0
@export var jump_m := 80.0
## Frames between looking at which cells should be built or freed.
@export var look_every := 6
## Cells are freed this far (m) past their species' range.
@export var evict_m := 60.0
