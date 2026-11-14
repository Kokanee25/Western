class_name TrackRepair
extends Node
## The railroad's repair crew (train step 5, #616): when the line's damaged (TrackState: broken,
## bent or blocked), the railroad sends men the next day (`repair_delay_h` game hours later, a
## proposed dial). They come along the line from the depot's side, and then, in order:
##
##   1. clear the line: whatever lies on the track at the damage (the wreck's cars and sections,
##      rubble, a crate, a body) is dragged off it to the side of the bed, a pair of men at each,
##      for as long as its weight takes (`clear_s_per_t` a tonne); the wreck stays beside the line;
##   2. mend it: each chunk with damage has its ties and rails laid again as new members
##      (`tie_s`, `rail_s` of work each, the crew sharing them), its fallen rubble moved aside;
##   3. walk off; the line is whole (`mended` is emitted) and the timetable can run again.
##
## Its men are HumanBodies walking and crouching at the work; nothing's scripted about what breaks
## or what's in the way: the work is what TrackState and the line's bodies say it is. A child of the
## TrackLine.

signal mended
signal arrived

enum { IDLE, WAITING, COMING, CLEARING, MENDING, LEAVING }

var line: TrackLine
var tuning: TrainTuning
var state := IDLE
## The game hour (days x 24 + hour) the crew's due, while WAITING.
var due := INF
## The stretch it's come for: from_s..to_s on the line.
var from_s := 0.0
var to_s := 0.0
var men: Array[HumanBody] = []
## What's to be cleared ([body, work left s]) and the chunks to mend ([chunk, work left s]).
var to_clear: Array = []
var to_mend: Array = []
## What it did, in order: {t (s since it started), what, ...}.
var log: Array[Dictionary] = []
var _t := 0.0
var _clock: DayCycle
var _look := 0.0


func setup(on_line: TrackLine) -> void:
	line = on_line
	tuning = on_line.tuning
	name = "Repair"
	process_physics_priority = 10


func _hours() -> float:
	if _clock == null or not is_instance_valid(_clock):
		_clock = get_tree().root.find_child("DayCycle", true, false) as DayCycle if is_inside_tree() else null
	if _clock == null:
		return _t / 3600.0
	return float(_clock.day) * 24.0 + _clock.time_of_day


## Send the crew now (as if the next day had come).
func call_now() -> void:
	if state in [IDLE, WAITING]:
		_damage_span()
		if to_s > from_s:
			_come()


func _physics_process(delta: float) -> void:
	_t += delta
	match state:
		IDLE:
			_look -= delta
			if _look <= 0.0:
				_look = 1.0
				if line.state and not line.state.damage().is_empty() and _damage_span():
					due = _hours() + tuning.repair_delay_h
					state = WAITING
					log.append({"t": _t, "what": "sent for", "due_h": due, "from": from_s, "to": to_s})
		WAITING:
			if _hours() >= due:
				_damage_span()
				_come()
		COMING:
			var all_there := true
			for i in men.size():
				var m := men[i]
				if not is_instance_valid(m) or m.limp:
					continue
				if not m.walk_to(_work_point(i), 1.4, delta):
					all_there = false
			if all_there:
				state = CLEARING
				_list_clearing()
				arrived.emit()
				log.append({"t": _t, "what": "arrived", "to_clear": to_clear.size()})
		CLEARING:
			if _work(to_clear, delta, _clear_one):
				state = MENDING
				_list_mending()
				log.append({"t": _t, "what": "cleared", "to_mend": to_mend.size()})
		MENDING:
			if _work(to_mend, delta, _mend_one):
				state = LEAVING
				log.append({"t": _t, "what": "mended"})
				mended.emit()
		LEAVING:
			var gone := true
			for m in men:
				if is_instance_valid(m) and not m.limp and not m.walk_to(_point(from_s - 60.0, 3.0), 1.4, delta):
					gone = false
			if gone or _t > 600.0:
				for m in men:
					# The dead and the down stay where they lie (#562: they were freed with the crew).
					if is_instance_valid(m) and not m.limp:
						m.queue_free()
				men.clear()
				state = IDLE
				log.append({"t": _t, "what": "gone"})


## The stretch with damage (all of it on the line, with room either side), false if none.
func _damage_span() -> bool:
	var d := line.state.damage() if line.state else []
	if d.is_empty():
		return false
	from_s = INF
	to_s = -INF
	for st: Dictionary in d:
		from_s = minf(from_s, float(st.from_s))
		to_s = maxf(to_s, float(st.to_s))
	# The wreck lies past the break: what's on the line beyond it is found when they get there.
	from_s = maxf(0.0, from_s - 10.0)
	to_s = minf(line.length, to_s + 10.0)
	return true


func _point(s: float, off: float) -> Vector3:
	var f := line.global_transform * line.transform_at(clampf(s, 0.0, line.length))
	return f * Vector3(off, -tuning.rail_size.y - tuning.tie_size.y * 0.5, 0.0)


## Where man i works: along the stretch, beside the track.
func _work_point(i: int) -> Vector3:
	var u := (float(i) + 0.5) / maxf(men.size(), 1)
	return _point(lerpf(from_s, minf(to_s, from_s + 40.0), u), 1.6 if i % 2 == 0 else -1.6)


func _come() -> void:
	state = COMING
	for i in tuning.crew_size:
		var m := HumanBody.new()
		m.person_id = StringName("track_man%d" % i)
		m.name = "TrackMan%d" % i
		m.rng_seed = 6160 + i
		m.has_gun = false
		var host := line.get_parent() if line.get_parent() else line
		m.enter(host, _point(from_s - 40.0 - i * 2.0, 1.8 if i % 2 == 0 else -1.8), 0.0)
		men.append(m)
	log.append({"t": _t, "what": "coming", "men": men.size()})


## Everything lying on the track over the stretch, and on past it as far as the wreck went.
func _list_clearing() -> void:
	to_clear.clear()
	var seen := {}
	var lo := from_s
	var hi := to_s
	for n: Node in get_tree().get_nodes_in_group(&"rubble"):
		var rb := n as RigidBody3D
		if rb == null or not is_instance_valid(rb) or seen.has(rb):
			continue
		var local := line.global_transform.affine_inverse() * rb.global_position
		var s := line.curve.get_closest_offset(local)
		if s < lo - 5.0 or s > hi + 150.0:
			continue
		var off := local.distance_to(line.point_at(s))
		if off > tuning.car_width * 0.5 + 1.2 or rb.mass < 5.0:
			continue
		seen[rb] = true
		to_clear.append([rb, maxf(5.0, rb.mass / 1000.0 * tuning.clear_s_per_t)])
		hi = maxf(hi, s)
	to_s = minf(line.length, maxf(to_s, hi + 5.0))


func _list_mending() -> void:
	to_mend.clear()
	for c: TrackChunk in line.chunks:
		if c.to_s < from_s or c.from_s > to_s:
			continue
		var d := c.damage()
		var n_ties: int = d.ties.size()
		var n_rails: int = d.rails.size() + d.bent.size()
		if n_ties + n_rails > 0:
			to_mend.append([c, n_ties * tuning.tie_s + n_rails * tuning.rail_s])


## Work down a list with the men on it (their crouching the work): true once it's done.
func _work(list: Array, delta: float, finish: Callable) -> bool:
	if list.is_empty():
		return true
	var working := 0
	for m in men:
		if is_instance_valid(m) and not m.limp:
			working += 1
			m.set_pose(&"crouch")
	if working == 0:
		return false
	var job: Array = list[0]
	job[1] = float(job[1]) - delta * working
	if float(job[1]) <= 0.0:
		finish.call(job[0])
		list.pop_front()
		for m in men:
			if is_instance_valid(m) and not m.limp:
				m.set_pose(&"stand")
	return list.is_empty()


## Dragged off the track to the side it's nearer, laid down there and left (frozen, as rubble lies).
func _clear_one(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb):
		return
	var local := line.global_transform.affine_inverse() * rb.global_position
	var s := line.curve.get_closest_offset(local)
	var f := line.transform_at(s)
	var side := signf((local - f.origin).dot(f.basis.x))
	if side == 0.0:
		side = 1.0
	var aside := f.origin + f.basis.x * side * (tuning.ballast_top * 0.5 + tuning.car_width * 0.5 + 1.0)
	aside.y = local.y
	RubbleRest.let_go(rb)
	rb.freeze = false
	rb.global_position = line.global_transform * aside
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	log.append({"t": _t, "what": "cleared", "body": String(rb.name), "kg": rb.mass})


## A chunk laid again: its ties and rails new members, what had fallen of it left beside the line.
func _mend_one(c: TrackChunk) -> void:
	if not is_instance_valid(c):
		return
	var old: Array[RigidBody3D] = c.rubble.duplicate()
	c.rubble.clear()
	for rb in old:
		if is_instance_valid(rb):
			_clear_one(rb)
	c.rebuild()
	line.state.line_built()
	log.append({"t": _t, "what": "relaid", "chunk": String(c.name)})
