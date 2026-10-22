extends RefCounted
## The spec saloon set down in the game's street, out in the desert west of town, for walking it
## in a build (F5's last stop, `DebugSpawns/SpecSaloon`, builds it the first time it's reached) and
## for the lab's renders. Lab-only: the town's own saloon is still SaloonBuilding (roadmap 4.3).
## The game's ground is one plane, so the cellar is closed under it (README, "What the format needs").
##
##   load("res://experiments/building_lab/play.gd").build(street)   # -> the building

## Where it stands, in the street's space (the boardwalk along its front, the door at x +7.62).
const ORIGIN := Vector3(-72.0, 0.0, 26.0)


static func build(street: Node3D) -> Node3D:
	var building = load("res://experiments/building_lab/spec_building.gd").new()
	building.name = "SpecSaloon"
	building.position = ORIGIN
	street.add_child(building)
	var walk = load("res://src/structures/boardwalk.gd").new()
	walk.structure_id = &"spec_walk"
	walk.length = 16.44
	walk.top = 0.78
	walk.steps = [Vector2(7.62, 1.83)]
	walk.position = ORIGIN
	street.add_child(walk)
	# Its lamps and fittings held up by what they stand on, as the town's are.
	var fittings := street.get_node_or_null(^"Fittings")
	if fittings:
		fittings.call_deferred(&"collect")
	return building
