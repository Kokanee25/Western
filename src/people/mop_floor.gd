class_name MopFloor
extends RefCounted
## The barkeep mops his floor (docs/briefs/mopping.md): a chore in his mind (CivilianBrain.chores),
## not a script. Every `look_every` s, free and at his post with nobody near, he looks at the floor
## round him (FloorMarks: tracked dirt, spilt drink; Blood's marks); past `mess_to_start` he fetches
## his mop and bucket from their corner, sets the bucket down by the dirtiest stretch, wets the mop
## and presses it out, and mops the stretch in side-to-side strokes, working back toward himself,
## the mop's foot dragging its strands over the boards. A dry or dirty mop goes back in the bucket;
## work out of the bucket's reach and he moves it along; its water too murky and he empties it
## outside and fills it at the trough. Done (or out of time), he rinses the mop and puts them back.
## Trouble: he lets go of the mop and sets the bucket down where he is; calm again, he picks them up.
## His hands go on the handle by HumanBody.reach_to; strokes, lean and twist are dials (MopTuning,
## config/mop.tres); his eyes on the mop's foot (FaceLife.attend_to).

enum Step { IDLE, FETCH, CARRY, DIP, PRESS, MOP, MOVE_BUCKET, CHANGE_WATER, PUT_BACK }

var body: HumanBody
var mop: MopProp
var bucket: MopBucket
var tuning: MopTuning
## His post (where he looks from), where the mop and bucket live, the street outside his door, and
## the town's places to walk by (straight if none).
var post := Vector3.INF
var home := Vector3.INF
var home_lean := Vector3(0.12, 1.0, 0.0)
var outside := Vector3.INF
var places: Waypoints
var step := Step.IDLE
var watching := Vector3.INF
## Why the last go ended: &"done", &"trouble", &"time" (&"" none yet); goes, stretches, waters changed.
var stopped := &""
var goes := 0
var stretches := 0
var changes := 0

var _t := 0.0
var _look := 0.0
var _rest := 0.0
var _phase := 0
var _route: Array[Vector3] = []
var _walk_t := 0.0
var _go_t := 0.0
var _target := Vector3.INF  # the middle of the stretch he's on (on the floor)
var _fwd := Vector3.FORWARD  # from him toward the stretch
var _progress := 0.0
var _then := Step.MOP
var _foot := Vector3.INF  # where the mop's foot is going
var _carrying := false
var _marks: FloorMarks
var _life: FaceLife
var _offsets := false
var _rng := RandomNumberGenerator.new()
var _mop_at := Vector3.INF
var _mop_lean := Vector3.UP
var _dt := 1.0 / 60.0
## How fast his hands move the mop's foot from where it is to where it's wanted (m/s).
const MOP_SPEED := 2.0
## Carried upright, he has it this far up the handle (m): its head clear of the ground.
const CARRY_GRIP := 0.6


func _init(who: HumanBody, the_mop: MopProp, the_bucket: MopBucket, at_post: Vector3, mop_home: Vector3) -> void:
	body = who
	mop = the_mop
	bucket = the_bucket
	post = at_post
	home = mop_home
	tuning = load("res://config/mop.tres")
	_rng.seed = who.rng_seed * 37 + 3
	_look = _rng.randf_range(0.0, 2.0)


func busy() -> bool:
	return step != Step.IDLE


## Each tick from his brain while no other chore has him: true while this one does.
func step_chore(delta: float, free: bool) -> bool:
	if _marks == null or not is_instance_valid(_marks):
		_marks = FloorMarks.find(body.get_tree())
	if _life == null:
		_life = body.get_node_or_null(^"FaceLife") as FaceLife
	if not is_instance_valid(mop) or not is_instance_valid(bucket) or body.limp or body.prone:
		if step != Step.IDLE:
			_end(&"trouble")
		return false
	if not free or body.grab_side() != "":
		if step != Step.IDLE:
			trouble()
		_lean_to(0.0, 0.0, delta)
		return false
	_t += delta
	_go_t += delta
	_dt = delta
	match step:
		Step.IDLE:
			return _idle_step(delta)
		Step.FETCH:
			_fetch_step(delta)
		Step.CARRY:
			_carry_step(delta)
		Step.DIP:
			_dip_step(delta)
		Step.PRESS:
			_press_step(delta)
		Step.MOP:
			_mop_step(delta)
		Step.MOVE_BUCKET:
			_move_bucket_step(delta)
		Step.CHANGE_WATER:
			_change_water_step(delta)
		Step.PUT_BACK:
			_put_back_step(delta)
	if watching != Vector3.INF and _life != null and is_instance_valid(_life) and _life.has_face():
		_life.attend_to(watching)
	return true


## Trouble: he lets go of the mop and puts the bucket down where he is.
func trouble() -> void:
	if mop.holder == body:
		mop.let_go()
	if bucket.carrier == body:
		bucket.set_down(body.global_position + body.global_basis.x * -0.35)
	_carrying = false
	_end(&"trouble")


# --- When ------------------------------------------------------------------------------------------

func _idle_step(delta: float) -> bool:
	_lean_to(0.0, 0.0, delta)
	_rest -= delta
	_look -= delta
	if _look > 0.0 or _rest > 0.0 or _marks == null:
		return false
	_look = tuning.look_every
	# Calm again with his mop or bucket left out (trouble came while he mopped): he picks them up
	# wherever he is and sees to the floor or puts them back.
	var left_out := mop.state != MopProp.State.STANDING or bucket.global_position.distance_to(home) > 1.0
	if _anyone_near(tuning.quiet) or (not left_out and body.global_position.distance_to(post) > 0.6):
		return false
	if _score(_marks.mess(post, tuning.area)) < tuning.mess_to_start and not left_out:
		return false
	goes += 1
	_go_t = 0.0
	stopped = &""
	_go(Step.FETCH)
	return true


## Plain water left on the boards isn't mess: it's his mop's own film and dries (dirty water counts by
## the dirt in it).
func _score(m: Dictionary) -> float:
	var spilt := float(m.liquid) - float(m.get("water", 0.0))
	return float(m.dirt) * tuning.per_dirt + spilt * tuning.per_liquid + float(m.blood) * tuning.per_blood


func _anyone_near(r: float) -> bool:
	var tree := body.get_tree()
	for n: Node in tree.get_nodes_in_group(&"people") + tree.get_nodes_in_group(&"player"):
		if n == body or not n is Node3D:
			continue
		if n is HumanBody and ((n as HumanBody).limp or not (n as HumanBody).physiology.is_conscious()):
			continue
		if (n as Node3D).global_position.distance_to(body.global_position) < r:
			return true
	return false


## The next stretch to mop: the dirtiest place on the floor round his post (cells, or blood).
func _next_stretch() -> bool:
	var best := Vector3.INF
	var best_score := tuning.clean_enough
	for e: Array in _marks.dirty_cells(post, tuning.area, 1.0).slice(0, 40):
		var p := _marks.centre(e[0])
		var s := _score(_marks.mess(p, tuning.stroke_width * 0.5))
		if s > best_score:
			best_score = s
			best = p
	for d in Blood.marks_near(post, tuning.area):
		var s := float(Blood._ml_of(d)) * tuning.per_blood
		if s > best_score:
			best_score = s
			best = d.global_position
	if best == Vector3.INF:
		return false
	var under := _marks.surface_at(best, 0.3)
	if under.is_empty():
		return false
	_target = under.at
	var from := body.global_position - _target
	from.y = 0.0
	_fwd = (-from).normalized() if from.length() > 0.2 else -body.global_basis.z
	_progress = 0.0
	return true


# --- The steps -------------------------------------------------------------------------------------

## To the corner, the bucket up in his left hand, the mop in his right.
func _fetch_step(delta: float) -> void:
	var at := bucket.global_position
	if _walk(at - (at - body.global_position).normalized() * 0.45 * Vector3(1, 0, 1), delta):
		body.face(Vector3(at.x, body.global_position.y + 1.4, at.z))
		if _t > 0.4:
			bucket.carry(body, "l")
			mop.take(body)
			_mop_at = Vector3.INF
			_carrying = true
			if _next_stretch():
				_go(Step.CARRY)
			else:
				_go(Step.PUT_BACK)
	watching = at


## Carrying the mop upright beside him.
func _hold_upright() -> void:
	var hand := body.global_transform * Vector3(0.28, 0.95, -0.12)
	_place_mop(hand - Vector3.UP * CARRY_GRIP, Vector3(0.0, 1.0, -0.05))
	body.reach_to("r", mop.grip(CARRY_GRIP), body.global_basis.x, 1.0)


## The mop moved toward where it's wanted no faster than a hand moves it (a jump drags its strands
## through things), its lean turning as fast.
func _place_mop(at: Vector3, lean: Vector3) -> void:
	if _mop_at == Vector3.INF:
		_mop_at = mop.foot()
		_mop_lean = mop.up()
	_mop_at = _mop_at.move_toward(at, MOP_SPEED * _dt)
	_mop_lean = _mop_lean.slerp(lean.normalized(), clampf(_dt * 8.0, 0.0, 1.0)).normalized()
	mop.hold_at(_mop_at, _mop_lean)


## Over to the stretch; the bucket down beside where he'll work.
func _carry_step(delta: float) -> void:
	_hold_upright()
	var stand := _stand_point()
	if _walk(stand, delta):
		body.face(_target + Vector3.UP * 1.4)
		var side := _fwd.cross(Vector3.UP).normalized()
		bucket.set_down(stand - side * 0.45 + _fwd * 0.2)
		_carrying = false
		_go(Step.DIP)
	watching = stand + _fwd


func _stand_point() -> Vector3:
	var p := _target - _fwd * tuning.stand_back
	p.y = body.global_position.y
	return p


## The mop's foot in the bucket's water, both hands on the handle.
func _dip_step(_delta: float) -> void:
	var into := bucket.global_position + Vector3.UP * maxf(bucket.surface_y() - bucket.global_position.y - 0.12, 0.05)
	_two_hands(_from_foot().lerp(into, smoothstep(0.0, 0.6, _t)))
	watching = bucket.global_position
	if _t >= tuning.dip_seconds:
		_go(Step.PRESS)


## Lifted over the bucket and pressed out.
func _press_step(delta: float) -> void:
	var over := bucket.global_position + Vector3.UP * (bucket.surface_y() - bucket.global_position.y + 0.36)
	_two_hands(_from_foot().lerp(over, smoothstep(0.0, 0.4, _t)))
	watching = bucket.global_position
	if _t > 0.4:
		mop.press(bucket, delta)
	if _t >= tuning.press_seconds:
		_go(_then)


## Side to side over the stretch, working back toward himself.
func _mop_step(delta: float) -> void:
	var side := _fwd.cross(Vector3.UP).normalized()
	_progress = minf(_progress + tuning.work_back * delta, tuning.stretch_depth)
	var a := sin(TAU * tuning.stroke_hz * _t)
	var centre := _target + _fwd * (tuning.stretch_depth * 0.5 - _progress)
	var at := centre + side * a * tuning.stroke_width * 0.5
	var under := _marks.surface_at(at, 0.3) if _marks else {}
	at.y = ((under.at as Vector3).y if not under.is_empty() else _target.y) + tuning.foot_above
	if _t < 0.4:
		at = _from_foot().lerp(at, smoothstep(0.0, 0.4, _t))
	# He steps back with the work.
	var stand := centre - _fwd * tuning.stand_back
	stand.y = body.global_position.y
	if body.global_position.distance_to(stand) > 0.08:
		body.walk_to(stand, tuning.step_speed, delta, false)
	body.face(Vector3(centre.x, body.global_position.y + 1.4, centre.z))
	_two_hands(at)
	_lean_to(tuning.lean, a * tuning.twist, delta)
	watching = at
	var dry := mop.water_ml < mop.wrung_ml() * tuning.dip_when_dry
	var dirty := mop.dirt / maxf(mop.water_ml, 50.0) > tuning.dip_when_dirty
	if dry or dirty:
		_then = Step.MOP
		_t = 0.0
		if bucket.murk() > tuning.change_water:
			_go(Step.CHANGE_WATER)
		elif bucket.global_position.distance_to(body.global_position) > tuning.bucket_reach:
			_go(Step.MOVE_BUCKET)
		else:
			_go(Step.DIP)
		return
	if _progress >= tuning.stretch_depth:
		stretches += 1
		if _go_t > tuning.most_seconds:
			_finish(&"time")
		elif _next_stretch():
			_then = Step.MOP
			if bucket.global_position.distance_to(_stand_point()) > tuning.bucket_reach:
				_go(Step.MOVE_BUCKET)
			else:
				_go(Step.MOP)
		else:
			_finish(&"done")


func _finish(why: StringName) -> void:
	stopped = why
	_then = Step.PUT_BACK
	_go(Step.DIP)


## The bucket picked up and set down again by where he's working.
func _move_bucket_step(delta: float) -> void:
	if _phase == 0:
		var at := bucket.global_position
		_hold_upright()
		if _walk(at - (at - body.global_position).normalized() * 0.45 * Vector3(1, 0, 1), delta):
			bucket.carry(body, "l")
			_carrying = true
			_phase = 1
			_route.clear()
		return
	_hold_upright()
	if _walk(_stand_point(), delta):
		var side := _fwd.cross(Vector3.UP).normalized()
		bucket.set_down(_stand_point() - side * 0.45 + _fwd * 0.2)
		_carrying = false
		_go(Step.DIP)


## Out the door with it, thrown out on the street, filled at the trough, back.
func _change_water_step(delta: float) -> void:
	_hold_upright()
	if _phase == 0:
		if not _carrying:
			var at := bucket.global_position
			if _walk(at - (at - body.global_position).normalized() * 0.45 * Vector3(1, 0, 1), delta):
				bucket.carry(body, "l")
				_carrying = true
				_route.clear()
			return
		var out := outside if outside != Vector3.INF else post + _fwd * 3.0
		if _walk(out, delta):
			bucket.empty_out(out + (out - post).normalized() * 1.2 * Vector3(1, 0, 1))
			_phase = 1
			_route.clear()
		return
	if _phase == 1:
		var water := _nearest_water()
		if water == null:
			bucket.fill()  # (no trough in reach: a pump in the back, as far as anyone can tell)
			_phase = 2
			return
		var at := CivilianBrain.water_side(water, body.global_position)
		if _walk(at, delta):
			bucket.fill()
			changes += 1
			_phase = 2
			_route.clear()
		return
	if _walk(_stand_point(), delta):
		var side := _fwd.cross(Vector3.UP).normalized()
		bucket.set_down(_stand_point() - side * 0.45 + _fwd * 0.2)
		_carrying = false
		_go(Step.DIP)


func _nearest_water() -> Node3D:
	var best: Node3D = null
	var best_d := 60.0
	for t: Node in body.get_tree().get_nodes_in_group(&"water_source"):
		var d := (t as Node3D).global_position.distance_to(body.global_position)
		if d < best_d:
			best_d = d
			best = t as Node3D
	return best


## Back to their corner: the bucket down, the mop stood against the wall.
func _put_back_step(delta: float) -> void:
	if _phase == 0 and not _carrying:
		var at := bucket.global_position
		_hold_upright()
		if _walk(at - (at - body.global_position).normalized() * 0.45 * Vector3(1, 0, 1), delta):
			bucket.carry(body, "l")
			_carrying = true
			_route.clear()
		return
	if _phase == 0:
		_hold_upright()
	var dir := home - body.global_position
	dir.y = 0.0
	var at := home - dir.normalized() * 0.55 if dir.length() > 0.6 else body.global_position
	if _phase == 0 and _walk(at, delta):
		bucket.set_down(home)
		_carrying = false
		_phase = 1
	if _phase == 1:
		# The mop let down into its corner, then stood there.
		var corner := home + Vector3(0.18, 0.0, 0.18) + Vector3.UP * (tuning.foot_above + 0.01)
		_place_mop(corner, home_lean)
		body.reach_to("r", mop.grip(0.9), body.global_basis.x, 1.0)
		if mop.foot().distance_to(corner) < 0.01:
			mop.stand_at(corner, _mop_lean)
			if stopped == &"":
				stopped = &"done"
			_end(stopped)


# --- Hands, walking, lean --------------------------------------------------------------------------

## The mop's foot at `at`, its handle up to his top hand, both his hands on it.
func _two_hands(at: Vector3) -> void:
	var top := body.global_transform * tuning.top_hand
	var lean := (top - at).normalized()
	_place_mop(at, lean)
	var t_top := minf(top.distance_to(mop.foot()), mop.length() - 0.05)
	_foot = at
	# Round the handle from either side: the left palm toward his right, the right toward his left.
	var right := body.global_basis.x
	body.reach_to("l", mop.grip(t_top), -right, 1.0)
	body.reach_to("r", mop.grip(maxf(t_top - tuning.hands_apart, 0.25)), right, 1.0)
	body.curl_hand("l", 0.75)
	body.curl_hand("r", 0.75)


func _from_foot() -> Vector3:
	return mop.foot()


## Walking somewhere by the town's places (straight if there are none); true there.
func _walk(to: Vector3, delta: float) -> bool:
	if _route.is_empty():
		if places != null:
			_route = FireFlight.route(places, body, to)
		else:
			_route = [to]
		_walk_t = 0.0
	_walk_t += delta
	body.set_pose(&"stand")
	if body.walk_to(_route[0], tuning.walk_speed, delta):
		_route.pop_front()
		if _route.is_empty():
			return true
	if _walk_t > tuning.give_up:
		_route.clear()
		return true  # as near as he can get
	return false


func _lean_to(forward: float, turn: float, delta: float) -> void:
	var on := absf(forward) > 0.05 or absf(turn) > 0.05 or _offsets
	if not on:
		return
	var k := clampf(delta * 5.0, 0.0, 1.0)
	var ab: Vector3 = body.pose_offsets.get(&"abdomen", Vector3.ZERO)
	var ch: Vector3 = body.pose_offsets.get(&"chest", Vector3.ZERO)
	ab = ab.lerp(Vector3(-forward * 0.5, turn * 0.4, 0.0), k)
	ch = ch.lerp(Vector3(-forward * 0.5, turn * 0.6, 0.0), k)
	if ab.length() < 0.05 and ch.length() < 0.05 and forward == 0.0 and turn == 0.0:
		body.pose_offsets.erase(&"abdomen")
		body.pose_offsets.erase(&"chest")
		_offsets = false
		return
	body.pose_offsets[&"abdomen"] = ab
	body.pose_offsets[&"chest"] = ch
	_offsets = true


func _go(s: Step) -> void:
	step = s
	_t = 0.0
	_phase = 0
	_route.clear()


func _end(why: StringName) -> void:
	stopped = why
	step = Step.IDLE
	_t = 0.0
	_phase = 0
	_route.clear()
	watching = Vector3.INF
	if why == &"done" or why == &"time":
		_rest = _rng.randf_range(tuning.rest_between.x, tuning.rest_between.y)
	elif why == &"trouble":
		_rest = 0.0
