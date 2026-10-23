class_name Seating
extends RefCounted
## Sitting down in the prop kit's chairs (KitProp with a "seat": the saloon's, the doctor's, the
## bank's). A man walks to a chair's seat point, turns to face out of it, and sits back in it
## (pose `sit_back`); KitProp.sit puts his weight on the seat, and a chair that goes from under him
## takes him down with it. Sean, 2026-10-22: men sitting in the kit chairs in town, so a saloon
## fight can knock them over.

## How near a chair must be to be his (m).
const NEAR := 8.0
## Close enough to the seat point to sit (m): the seat point is inside the chair's frame, and his
## walk stops short of solid things (walk_to), so the last step is the sitting down.
const ARRIVE := 0.9


## The nearest kit chair to `at` with a seat nobody's in, standing (not loose), or null.
static func free_chair_near(tree: SceneTree, at: Vector3, radius := NEAR) -> KitProp:
	var best: KitProp = null
	var best_d := radius
	for s: Node in tree.get_nodes_in_group(&"structures"):
		var kp := s as KitProp
		if kp == null or kp.loose or kp.seated != null or not kp.definition.has("seat") or not kp.is_inside_tree():
			continue
		var d := kp.seat_position().distance_to(at)
		if d < best_d:
			best = kp
			best_d = d
	return best


## Where he stands to sit (the seat point on the floor under it).
static func spot(chair: KitProp) -> Vector3:
	var p := chair.seat_position()
	return Vector3(p.x, chair.global_position.y, p.z)


## A point out ahead of him as he sits in it (he faces out of the chair: its +z).
static func faces(chair: KitProp) -> Vector3:
	var out := chair.global_basis.z
	out.y = 0.0
	return spot(chair) + out.normalized() * 2.0 + Vector3.UP * 1.0


## Walk him to the chair and sit him in it, a tick at a time; true once he's sitting.
static func sit_step(man: HumanBody, chair: KitProp, delta: float) -> bool:
	if chair == null or not is_instance_valid(chair) or chair.loose:
		return false
	if chair.seated == man:
		man.set_pose(&"sit_back")
		return true
	if chair.seated != null:
		return false
	var at := spot(chair)
	var flat := man.global_position - at
	flat.y = 0.0
	if flat.length() > ARRIVE:
		man.set_pose(&"stand")
		man.walk_to(at, 1.0, delta)
		return false
	man.global_position = Vector3(at.x, man.global_position.y, at.z)
	man.face(faces(chair))
	man.set_pose(&"sit_back")
	return chair.sit(man)


## Up out of it (his weight off the seat), standing a step clear of it.
static func stand_up(man: HumanBody, chair: KitProp) -> void:
	if chair != null and is_instance_valid(chair) and chair.seated == man:
		chair.leave()
		var out := chair.global_basis.z
		out.y = 0.0
		if not man.limp:
			man.global_position += out.normalized() * 0.3
	if not man.limp:
		man.set_pose(&"stand")
