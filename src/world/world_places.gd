class_name WorldPlaces
## Where things are in whichever world is loaded, the old town's test street or the valley (review
## A8, #864): the code that needs a place asks here, not the old town's markers or numbers, so the
## valley answers with its own. For now: where you come round knocked out, and a spot out in Main
## Street (the outlaws' call-out).


## The valley, if it's the world loaded (ValleyWorld's group), else null.
static func valley(tree: SceneTree) -> ValleyWorld:
	return tree.get_first_node_in_group(&"valley_world") as ValleyWorld if tree else null


## Where a man knocked out is carried, best first: [{at: Vector3, yaw: float, where: "at the
## doctor's"}]. The valley's (ValleyWorld.wake_spots: the doctor's sick room, else the general
## store's walk); the old town's DoctorInside and StoreInside. Empty: nowhere (you stay where you fell).
static func wake_spots(tree: SceneTree) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var v := valley(tree)
	if v != null:
		out.assign(v.wake_spots())
		return out
	var root: Node = tree.current_scene if tree.current_scene else tree.root
	for spot: Array in [["DoctorInside", "at the doctor's"], ["StoreInside", "on the store floor"]]:
		var marker := root.find_child(spot[0], true, false) as Node3D
		if marker == null:
			marker = tree.root.find_child(spot[0], true, false) as Node3D
		if marker != null:
			out.append({"at": marker.global_position, "yaw": marker.global_rotation.y, "where": spot[1]})
	return out


## A spot out in Main Street `along` m east (-: west) of `from`, `across` m off its middle, on the
## ground: kept on the town's stretch of the street (turned back the other way past its end).
static func street_spot(tree: SceneTree, from: Vector3, along: float, across := 0.0) -> Vector3:
	var v := valley(tree)
	if v != null:
		return v.street_spot(from, along, across)
	# The old town: Main Street between Market Street and Freight Street (config/town.json).
	var x := from.x + along
	if x > 16.0 or x < -34.0:
		x = from.x - along
	return TownLayout.street_point(clampf(x, -34.0, 16.0), -0.6 + across)
