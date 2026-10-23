extends Node3D
## The building lab's set: one building from its spec on its own ground, the boardwalk in front of
## it, and the game's own systems round it (Fittings, the fire, ballistics), as the street has them.
## Nothing here is the game's: it measures the spec before the spec is used for real.
##
## The ground is boxes round the cellar's pit (the game's ground is one plane: a cellar needs a hole
## in it, FORMAT.md "What using it for real needs").

const SpecBuilding := preload("res://experiments/building_lab/spec_building.gd")

var building: FalseFrontBuilding
var spec: Dictionary
var fittings: Fittings
var fire: FireSystem
var ballistics: Ballistics
var boardwalk: Boardwalk
var ground: StaticBody3D


func _ready() -> void:
	spec = SpecBuilding.load_spec(SpecBuilding.SPEC)
	_ground()
	fire = FireSystem.new()
	fire.name = "FireSystem"
	add_child(fire)
	ballistics = Ballistics.new()
	ballistics.name = "Ballistics"
	add_child(ballistics)
	building = SpecBuilding.new()
	building.name = "Saloon"
	add_child(building)
	boardwalk = Boardwalk.new()
	boardwalk.name = "SouthBoardwalk"
	boardwalk.structure_id = &"saloon_walk"
	boardwalk.length = float(spec.lot.width) + 1.2
	boardwalk.top = float(spec.levels.ground.top)
	boardwalk.steps = [Vector2(7.62, 1.83)]
	add_child(boardwalk)
	fittings = Fittings.new()
	fittings.name = "Fittings"
	add_child(fittings)


## The ground at y 0, open over the cellar down to its floor.
func _ground() -> void:
	ground = StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = Layers.WORLD
	ground.add_to_group(&"ground")
	add_child(ground)
	var c: Array = spec.cellar.rect
	var x0 := float(c[0])
	var z0 := float(c[1])
	var x1 := float(c[2])
	var z1 := float(c[3])
	var big := 60.0
	var floor: float = float(spec.levels.cellar.floor)
	# Four slabs round the pit, and the pit's floor.
	var slabs := [
		[Vector3(-big, -1.0, -big), Vector3(x0, 0.0, big)],
		[Vector3(x1, -1.0, -big), Vector3(big, 0.0, big)],
		[Vector3(x0, -1.0, -big), Vector3(x1, 0.0, z0)],
		[Vector3(x0, -1.0, z1), Vector3(x1, 0.0, big)],
		[Vector3(x0, floor - 1.0, z0), Vector3(x1, floor, z1)],
	]
	for s: Array in slabs:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = b - a
		cs.shape = box
		cs.position = (a + b) * 0.5
		ground.add_child(cs)
