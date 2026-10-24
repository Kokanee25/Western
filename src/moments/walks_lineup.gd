class_name WalksLineup
extends Moment
## Five people walking their own way, in a row across the street (Sean, 2026-10-24: five ways of
## walking, all real). Each is spawned at `from_x` on his own line in z and walks to `to_x` by
## HumanBody.walk_to, his walk clip (named here, else config/walks.json's) playing under it; done
## when the last arrives, or a man can't (stalled). Data: config/moments/walks_lineup.json.

var men: Array[HumanBody] = []
var goals: Array[Vector3] = []
var arrived := {}


func begin() -> void:
	set_hour()
	var z := float(data.get("z_first", -3.0))
	for w: Dictionary in data.get("walkers", []):
		var at := Vector3(float(data.get("from_x", -14.0)), 0.0, z)
		var goal := Vector3(float(data.get("to_x", 10.0)), 0.0, z)
		var m := HumanBody.new()
		m.body_model = StringName(w.get("model", "outlaw"))
		m.person_id = StringName(w.get("id", "walker"))
		m.name = String(w.get("name", String(m.person_id)))
		m.rng_seed = int(w.get("seed", 1))
		m.has_gun = false
		if w.has("walk"):
			m.walk_clip = StringName(w.walk)
		m.enter(street, at, HumanBody.yaw_toward(at, goal))
		men.append(m)
		goals.append(goal)
		z += float(data.get("z_step", -1.3))
	state = &"walking"


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	var all_in := true
	for i in men.size():
		var m := men[i]
		if not is_instance_valid(m) or arrived.has(i):
			continue
		if m.walk_to(goals[i], float(data.get("speed", 1.2)), delta):
			arrived[i] = t
		else:
			all_in = false
	if all_in:
		_finish(&"arrived")
	elif t > float(data.get("beat_timeout_s", 40.0)):
		_finish(&"stalled")


func result() -> Dictionary:
	var r := super()
	var walks := {}
	for i in men.size():
		if is_instance_valid(men[i]):
			walks[String(men[i].person_id)] = {"clip": String(men[i].walk_clip), "arrived_t": arrived.get(i, -1.0),
					"x": snappedf(men[i].global_position.x, 0.01)}
	r["walkers"] = walks
	return r


func reset() -> void:
	for m in men:
		if is_instance_valid(m):
			m.queue_free()
	queue_free()
