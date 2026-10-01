class_name StreetDressing
extends Node3D
## The test street dressed as the street painting has it (docs/concept/street-golden-hour.png):
## painted signs on the false fronts down the street (LIVERY and JAIL across from the store, GENERAL
## STORE next to it), carriage lanterns by the doors, barrels, crates and hay along the boardwalks,
## a horse saddled at a rail, a covered wagon down the street, telegraph poles and a water tower
## over the roofs. Models from PropModels on the texel grid; the big ones have a box to bump into.
## Everything keeps off the road's middle (the gang rides in along z -9) and the store's porch.
##
## The blockout lots (their fronts) are StreetScenery's: [x0, x1, front z, faces +Z, wall height,
## front height]; kept in step by hand.

const LOTS := [
	[-7.8, -0.6, 0.0, false, 3.4, 5.4],
	[-15.5, -8.6, 0.0, false, 3.8, 6.6],
	[-10.5, -3.0, -16.8, true, 3.4, 5.6],
	[-19.5, -11.5, -16.8, true, 3.0, 4.6],
	[-28.0, -20.5, -16.8, true, 4.0, 6.2],
]
## Which painted board goes on which lot (LOTS index), and how high on its front the board may go
## (from, to, metres above the ground).
const SIGNS := [[0, &"sign_general_store", 3.6, 5.2], [2, &"sign_livery", 2.65, 5.35], [3, &"sign_jail", 3.15, 4.45]]


func _ready() -> void:
	_signs()
	_lanterns()
	_loose()
	_far()


## Where a lot's front face is, and which way it looks (+1: toward +Z).
static func _front(lot: Array) -> Array:
	var faces := 1.0 if lot[3] else -1.0
	return [(lot[2] as float) + faces * 0.125, faces]


func _signs() -> void:
	for s in SIGNS:
		var lot: Array = LOTS[s[0]]
		var painted := SignArt.board_size(s[1])
		if painted == Vector2.ZERO:
			continue
		var room := Vector2((lot[1] as float) - (lot[0] as float) - 1.0, (s[3] as float) - (s[2] as float))
		var size := painted * minf(room.x / painted.x, room.y / painted.y)
		var board := SignArt.board(s[1], size)
		var f := _front(lot)
		var x: float = ((lot[0] as float) + (lot[1] as float)) * 0.5
		if s[1] == &"sign_livery":
			x += 1.8  # beside the door, not over it
		add_child(board)
		board.global_transform = Transform3D(Basis(Vector3.UP, 0.0 if f[1] > 0.0 else PI), Vector3(x, ((s[2] as float) + (s[3] as float)) * 0.5, f[0] + f[1] * 0.02))


## A carriage lantern either side of each lot's door, lit from dusk.
func _lanterns() -> void:
	for lot: Array in LOTS:
		var f := _front(lot)
		var cx: float = ((lot[0] as float) + (lot[1] as float)) * 0.5
		for side in [-1.0, 1.0]:
			_lantern(Vector3(cx + side * 0.95, 2.25, f[0]), f[1])


func _lantern(at: Vector3, faces: float) -> void:
	var root := Node3D.new()
	root.name = "Lantern"
	PropModels.lantern(root)
	add_child(root)
	root.global_transform = Transform3D(Basis(Vector3.UP, 0.0 if faces > 0.0 else PI), at)
	var lamp := OilLamp.new()
	lamp.show_mesh = false
	lamp.energy = 0.9
	lamp.light_range = 6.0
	lamp.haze = 1.6
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
	for p in [Vector3(-3.4, 0.0, -15.9), Vector3(-4.6, 0.0, -16.0), Vector3(-4.0, 0.45, -15.95), Vector3(-12.2, 0.0, -15.9)]:
		_model("Hay", PropModels.hay_bale, p, 0.0, Vector3(0.9, 0.45, 0.5))
	for p in [Vector3(-11.0, 0.0, -16.1), Vector3(-19.0, 0.0, -16.1)]:
		_prop(&"barrel", p, 0.0)
	_model("Crate", PropModels.crate, Vector3(-20.1, 0.0, -16.0), 20.0, Vector3(0.6, 0.6, 0.6))
	# The rail before the livery, and a bay horse tied to it.
	var rail := Node3D.new()
	rail.name = "LiveryRail"
	add_child(rail)
	var wood := PropModels.dark_wood()
	for x in [-10.2, -7.4]:
		PropModels._box(rail, "Post", Vector3(0.12, 1.1, 0.12), Vector3(x, 0.55, -14.2), wood)
	PropModels._box(rail, "Bar", Vector3(3.0, 0.1, 0.1), Vector3(-8.8, 1.0, -14.2), wood)
	_model("Horse", PropModels.horse, Vector3(-8.6, 0.0, -14.75), 0.0, Vector3(2.4, 1.8, 0.6))


## Down the street and over the roofs: a covered wagon, telegraph poles with their wire, the water
## tower.
func _far() -> void:
	_model("Wagon", PropModels.wagon, Vector3(-36.0, 0.0, -12.6), 0.0, Vector3(3.4, 2.2, 1.8))
	var poles := [Vector3(-2.0, 0.0, -15.3), Vector3(-27.0, 0.0, -15.3), Vector3(-52.0, 0.0, -15.3), Vector3(-77.0, 0.0, -15.3)]
	for p in poles:
		_model("Pole", PropModels.telegraph_pole, p, 0.0, Vector3(0.25, 7.0, 0.25))
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
	_model("WaterTower", PropModels.water_tower, Vector3(-34.0, 0.0, -27.5), 20.0, Vector3(3.8, 11.5, 3.8))


func _prop(id: StringName, at: Vector3, yaw: float) -> void:
	var p := PropLibrary.spawn(id)
	add_child(p)
	p.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)


## A PropModels model at `at`, turned `yaw` degrees, with a box of `size` (bottom at its feet)
## to bump into and to stop a bullet.
func _model(n: String, build: Callable, at: Vector3, yaw: float, size: Vector3) -> Node3D:
	var body := StaticBody3D.new()
	body.name = n
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	body.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), at)
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
