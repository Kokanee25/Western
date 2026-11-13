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
## A boardwalk down the side street (the spec's `lot.side_walk`: saloon B's).
var side_walk: Boardwalk
var ground: StaticBody3D
## The spec the next lab builds (the saloon's unless set: the doctor's test sets it, #765).
static var spec_path := ""


func _ready() -> void:
	var path := spec_path if spec_path != "" else SpecBuilding.SPEC
	spec = SpecBuilding.load_spec(path)
	_ground()
	fire = FireSystem.new()
	fire.name = "FireSystem"
	add_child(fire)
	ballistics = Ballistics.new()
	ballistics.name = "Ballistics"
	add_child(ballistics)
	building = SpecBuilding.new()
	building.name = "Saloon" if path == SpecBuilding.SPEC else String(spec.id).capitalize()
	if path != SpecBuilding.SPEC:
		building.spec_path = path
		building.structure_id = StringName(String(spec.id) + "_spec")
	add_child(building)
	boardwalk = Boardwalk.new()
	boardwalk.name = "SouthBoardwalk"
	boardwalk.structure_id = &"saloon_walk"
	boardwalk.length = float(spec.lot.width) + 1.2
	boardwalk.top = float(spec.levels.ground.top)
	boardwalk.steps = [Vector2(7.62, 1.83)]
	if path != SpecBuilding.SPEC:
		# The walk across its front, steps at its street door.
		boardwalk.structure_id = StringName(String(spec.id) + "_walk")
		boardwalk.length = float(spec.lot.width)
		for w: Dictionary in spec.walls:
			if w.id == "front":
				for o: Dictionary in w.openings:
					if o.type == "door":
						boardwalk.steps = [Vector2(float(o.at), 1.83)]
	if spec.has("corner"):
		# Saloon B: the flight before the corner door, the walk on past the corner to the side street's.
		boardwalk.steps = [Vector2(float(spec.lot.width) - 1.3, 1.83)]
	var sw: Dictionary = spec.lot.get("side_walk", {})
	if not sw.is_empty():
		boardwalk.length = float(spec.lot.width) + float(sw.depth)
		side_walk = Boardwalk.new()
		side_walk.name = "SideWalk"
		side_walk.structure_id = StringName(String(spec.id) + "_side_walk")
		side_walk.length = float(sw.length)
		side_walk.walk_depth = float(sw.depth)
		side_walk.top = float(spec.levels.ground.top)
		side_walk.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(sw.get("turn", -90.0)))), Vector3(float(sw.at[0]), 0.0, float(sw.at[1])))
		var flights := []
		for st: Array in sw.get("steps", []):
			flights.append(Vector2(float(st[0]), float(st[1])))
		side_walk.steps = flights
		side_walk.end_steps = [Vector2(1, 0.0)]
		add_child(side_walk)
	add_child(boardwalk)
	fittings = Fittings.new()
	fittings.name = "Fittings"
	add_child(fittings)


## The ground at y 0, open over the cellar down to its floor (a building without one: flat).
func _ground() -> void:
	ground = StaticBody3D.new()
	ground.name = "Ground"
	ground.collision_layer = Layers.WORLD
	ground.add_to_group(&"ground")
	add_child(ground)
	if not spec.has("cellar"):
		var cs0 := CollisionShape3D.new()
		var box0 := BoxShape3D.new()
		box0.size = Vector3(120.0, 1.0, 120.0)
		cs0.shape = box0
		cs0.position = Vector3(0.0, -0.5, 0.0)
		# A lot whose ground falls (the jail's, #780: `lot.ground.plane`, [y at the origin, dy/dx, dy/dz]):
		# the slab tilted to it, as the valley's bake has it.
		var pl: Array = (spec.lot.get("ground", {}) as Dictionary).get("plane", [])
		if not pl.is_empty():
			var n := Vector3(-float(pl[1]), 1.0, -float(pl[2])).normalized()
			var basis := Basis(Quaternion(Vector3.UP, n))
			cs0.transform = Transform3D(basis, Vector3(0.0, float(pl[0]), 0.0) + basis * Vector3(0.0, -0.5, 0.0))
		ground.add_child(cs0)
		return
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
