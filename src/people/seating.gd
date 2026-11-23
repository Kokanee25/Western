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


## The nearest kit chair to `at` with a seat nobody's in, standing (not loose), or null. For `who` (a
## man), a chair a scene holds (SceneHold) isn't free unless he's in its cast.
static func free_chair_near(tree: SceneTree, at: Vector3, radius := NEAR, who: Node = null) -> KitProp:
	var best: KitProp = null
	var best_d := radius
	for s: Node in tree.get_nodes_in_group(&"structures"):
		var kp := s as KitProp
		if kp == null or kp.loose or kp.seated != null or not kp.definition.has("seat") or not kp.is_inside_tree():
			continue
		if who != null and not SceneHold.live.is_empty() and SceneHold.chair_held(kp, who):
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
	if chair.seated != null or (not SceneHold.live.is_empty() and SceneHold.chair_held(chair, man)):
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
		if not man.limp:
			man.global_position = _step_clear(man, chair)
	if not man.limp:
		man.set_pose(&"stand")


## How far he steps out of a chair as he stands (m), and to its side when the front's taken.
const STEP_OUT := 0.3
const STEP_ASIDE := 0.55
## Floor this much above the chair's is something he'd stand up onto, not the floor (m).
const RAISED := 0.2


## Where he stands up to: a step out of the chair (he faces its +z), unless something's there, then a
## step to either side of it, else where he is. A chair drawn up to a table faces into it: the Drifter
## stood up from the card table's east chair onto its top (the step put him over it, and his feet
## stood on it), sat back down at its height, and the table, knocked loose under his animated feet,
## was flung across the yard by them as he turned (Earl's legs broken, #1077).
static func _step_clear(man: HumanBody, chair: KitProp) -> Vector3:
	var at := man.global_position
	var out := chair.global_basis.z
	out.y = 0.0
	out = out.normalized()
	# (Only looked in the physics frame: called outside it, as before, the plain step.)
	var space := World.space(man) if Engine.is_in_physics_frame() and man.is_inside_tree() else null
	if space == null:
		return at + out * STEP_OUT
	var skip: Array[RID] = []
	for m in chair.get_members():
		skip.append(m.get_rid())
	var floor_y := chair.global_position.y
	var side := Vector3.UP.cross(out)
	for c: Vector3 in [at + out * STEP_OUT, at + side * STEP_ASIDE, at - side * STEP_ASIDE]:
		if _room_at(space, at, c, floor_y, skip):
			return c
	return at


## Floor at `c` no higher than the chair's (not a table's top), and nothing between there and `at`
## at a man's hips (a wall, the next chair).
static func _room_at(space: PhysicsDirectSpaceState3D, at: Vector3, c: Vector3, floor_y: float, skip: Array[RID]) -> bool:
	var down := PhysicsRayQueryParameters3D.create(Vector3(c.x, floor_y + 1.2, c.z), Vector3(c.x, floor_y - 0.3, c.z), Layers.WORLD)
	down.exclude = skip
	var hit := space.intersect_ray(down)
	if not hit.is_empty() and (hit.position as Vector3).y > floor_y + RAISED:
		return false
	var hips := floor_y + 0.9
	var across := PhysicsRayQueryParameters3D.create(Vector3(at.x, hips, at.z), Vector3(c.x, hips, c.z), Layers.WORLD)
	across.exclude = skip
	return space.intersect_ray(across).is_empty()
