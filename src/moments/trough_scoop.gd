class_name TroughScoop
extends Moment
## A man at a water trough scoops water in both hands and splashes his face (Sean, 2026-10-24):
## the clip `scoop_water` (the Studio's Uthana takes) played once at the trough's side; at its
## `splash` mark (his hands at their highest) a little of the trough's water is spilt at his hands
## (Events.liquid_spilled: the ground's wet patch, the sound). Data: config/moments/trough_scoop.json.

var man: HumanBody
var trough: Node3D
var splashed := false


func begin() -> void:
	set_hour()
	var near := point("", "table", data)
	var best := INF
	for n: Node in get_tree().get_nodes_in_group(&"water_source"):
		if n is WaterTrough and (n as Node3D).global_position.distance_to(near) < best:
			best = (n as Node3D).global_position.distance_to(near)
			trough = n
	if trough == null:
		_finish(&"no_trough")
		return
	var length := float(trough.get(&"length"))
	var width := float(trough.get(&"trough_width"))
	var mid := trough.global_transform * Vector3(length * 0.5, 0.0, 0.0)
	# He stands at the side of it away from the nearest building wall: the side the street's on.
	var side := trough.global_basis.z.normalized()
	var a := mid + side * (width * 0.5 + float(data.get("stand_off_m", 0.45)))
	var b := mid - side * (width * 0.5 + float(data.get("stand_off_m", 0.45)))
	var at := a if _open_around(a) >= _open_around(b) else b
	at.y = trough.global_position.y
	man = _man(data.man, at, mid + Vector3.UP * 0.5)
	man.clip_event.connect(func(_c: StringName, ev: String) -> void:
		if ev == "splash":
			_splash())
	man.clip_done.connect(func(_c: StringName) -> void: state = &"after")
	state = &"to_play"


func _man(d: Dictionary, at: Vector3, faces: Vector3) -> HumanBody:
	var m := HumanBody.new()
	m.body_model = StringName(d.get("model", "outlaw"))
	m.person_id = StringName(d.get("id", "man"))
	m.name = String(d.get("name", String(m.person_id)))
	m.rng_seed = int(d.get("seed", 1))
	m.has_gun = false
	m.enter(street, at, HumanBody.yaw_toward(at, faces))
	return m


## How far the nearest wall is from a point (a ray each way, level): the open side of the trough.
func _open_around(p: Vector3) -> float:
	var space := street.get_world_3d().direct_space_state
	var least := 10.0
	for d: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 1.2, p + Vector3.UP * 1.2 + d * 10.0, Layers.WORLD)
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			least = minf(least, (hit.position as Vector3).distance_to(p + Vector3.UP * 1.2))
	return least


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	match state:
		&"to_play":
			if t > 0.5:
				if man.play_clip(StringName(data.get("clip", "scoop_water")), 1.0, false, {"travel": false}) <= 0.0:
					_finish(&"no_clip")
					return
				state = &"scooping"
		&"scooping":
			if not man.clip_playing() and not splashed:
				_splash()  # a clip with no mark: as he straightens
		&"after":
			if not splashed:
				_splash()
			if t > float(data.get("hold_after_s", 2.0)) + 6.0:
				_finish(&"done")
	if t > float(data.get("beat_timeout_s", 20.0)):
		_finish(&"stalled_" + state)


func _splash() -> void:
	if splashed or man == null or not is_instance_valid(man):
		return
	splashed = true
	var hands := (man.palm("l") + man.palm("r")) * 0.5
	Events.liquid_spilled.emit(hands, &"water", float(data.get("splash_litres", 0.3)), trough)


func result() -> Dictionary:
	var r := super()
	r["trough"] = trough != null
	r["splashed"] = splashed
	return r


func reset() -> void:
	if man != null and is_instance_valid(man):
		man.queue_free()
	queue_free()
