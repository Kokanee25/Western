extends RefCounted
## More townsfolk for the bench (more-cores step 4b, `perf_bench --folk=N`): the street's
## townsfolk `times` over, the copies (each a man like one of them: the same Studio model, colours,
## pose, a civilian's mind) standing at their posts two streets off, in rows behind the north fronts
## (out of the bench's view and 75 m or more from where it stands), so PeopleTick's bands find them
## far. Each copy's post is the ground under it.
##
##   var made: Array = FolkCopies.lay(street, 2)
## Untyped where it meets the game's classes: perf_bench (an -s script) loads it before autoloads.

## The rows' z (the street's middle is -8.4) and how far apart men stand in a row (m).
const ROWS := [-90.0, -96.0, -102.0, -108.0]
const FROM_X := 20.0
const GAP := 2.5


static func lay(street: Node3D, times := 2) -> Array:
	var sources := []
	for b in street.find_children("Brain", "", true, false):
		if b is CivilianBrain and b.get_parent() is HumanBody:
			sources.append(b.get_parent())
	sources.sort_custom(func(a, b) -> bool: return String(a.person_id) < String(b.person_id))
	var space: PhysicsDirectSpaceState3D = World.space(street)
	var made := []
	var n := 0
	for k in times - 1:
		for src in sources:
			var row: float = ROWS[(n / 24) % ROWS.size()]
			var at := Vector3(FROM_X - GAP * (n % 24), 0.0, row)
			var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 60.0, at + Vector3.DOWN * 60.0, Layers.STAND)
			var hit := space.intersect_ray(q)
			if not hit.is_empty():
				at.y = (hit.position as Vector3).y
			var brain_src := src.get_node(^"Brain") as CivilianBrain
			var man := HumanBody.new()
			man.name = "%sCopy%d" % [src.name, k + 1]
			man.person_id = StringName("%s_copy%d" % [src.person_id, k + 1])
			man.rng_seed = int(src.rng_seed) + 1000 * (k + 1)
			man.has_gun = false
			man.body_model = src.body_model
			man.shirt_color = src.shirt_color
			man.vest_color = src.vest_color
			man.coat_color = src.coat_color
			man.hat_color = src.hat_color
			man.bandana_color = src.bandana_color
			man.look = src.look
			var brain := CivilianBrain.new()
			brain.name = "Brain"
			brain.post = at
			brain.faces = at + Vector3(0.0, 1.5, 6.0)  # facing the town
			brain.rest_pose = brain_src.rest_pose if brain_src.rest_pose != &"sit" else &"stand"
			man.add_child(brain)
			man.enter(street, at, HumanBody.yaw_toward(at, brain.faces))
			man.set_pose(brain.rest_pose)
			made.append(man)
			n += 1
	return made
