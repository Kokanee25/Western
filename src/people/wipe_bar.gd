class_name WipeBar
extends RefCounted
## The barkeep's chore (docs/briefs/barkeep-rag.md): a deed in his mind, not a script. His brain
## (CivilianBrain.chore) asks it each tick, saying whether he's free (calm, nothing over him); it
## looks at the world and does the next thing. Free a while with nobody at the bar, he takes his
## cloth off his shoulder, lays it on the bar in front of him and wipes a stretch, in circles then
## long strokes, his flat hand riding the bar top (a ray finds it under the hand); moves along and
## wipes the next; now and then picks up a cup within reach and turns the cloth in it; then puts the
## cloth back over his shoulder and rests a while. Someone comes to the bar: he stops and the cloth
## goes back over his shoulder. Trouble (the brain says he isn't free): it's tossed down where he
## is. A cloth he's lost (knocked off, dropped) he goes and gets once it's calm.
## His arms are put where the deed wants them by HumanBody.reach_to (the IK his hand to a wound
## uses), every size and speed a dial in WipeTuning (config/wipe.tres); his fingers close round the
## cloth (curl_hand), the cloth pinned under his palm (ClothProp.hold).
## His eyes: `watching` is what he's looking at (the cloth under his hand, the cup): his FaceLife
## watches it while he works (`FaceLife.attend_to`: eyes first, his head after); a man without a
## talking face turns his head to it.

enum Step { IDLE, TAKE, LAY, WIPE, MOVE, GLASS, PUT_BACK, FETCH }

## Calm this long (s) with his rag lying about, he goes and gets it.
const FETCH_AFTER := 1.5

## Cups he'll pick up and wipe (PropLibrary's ids).
const CUPS := [&"tin_cup"]

var body: HumanBody
var cloth: ClothProp
var tuning: WipeTuning
## His post behind the bar, and a point across it he faces (his brain's).
var post := Vector3.INF
var faces := Vector3.INF
## The town's places, to walk to a cloth he's lost (straight there if none).
var places: Waypoints
var hand := "r"
var shoulder := "l"
var step := Step.IDLE
## What he's watching (Vector3.INF: nothing in particular).
var watching := Vector3.INF
## Why the last go ended: &"done", &"customer", &"trouble", &"lost" (&"" none yet).
var stopped := &""
## Goes started, stretches wiped, cups wiped (for the lab and the tests).
var cycles := 0
var wiped := 0
var cups := 0

var _t := 0.0
var _idle := 0.0
var _rest := 0.0
var _left := 0
var _along := 0.0
var _next_along := 0.0
var _dir := 1.0
var _bar := {}
var _from := Vector3.INF
var _hand_at := Vector3.INF
var _hand_n := Vector3.UP
var _out := 0.0
var _phase := 0
var _wipe_for := 0.0
var _carry_local := Vector3.ZERO
var _cup: Node3D
var _cup_found: Node3D
var _cup_parent: Node
var _cup_home := Transform3D()
var _cup_layer := 0
var _cup_h := 0.1
var _cup_at := Vector3.INF
var _cup_goal := Vector3.INF
var _cup_n := Vector3.UP
var _out_l := 0.0
var _route: Array[Vector3] = []
var _then_why := &""
var _lean := 0.0
var _head := Vector2.ZERO
var _offsets := false
var _customer_t := 0.0
var _customer_seen := false
var _life: FaceLife
var _gaze_looked := false
var _fetch_t := 0.0
var _reached := -1
var _across := false
var _reached_l := -1
var _rng := RandomNumberGenerator.new()


func _init(who: HumanBody, rag: ClothProp, at_post: Vector3, facing: Vector3) -> void:
	body = who
	cloth = rag
	post = at_post
	faces = facing
	tuning = load("res://config/wipe.tres")
	_rng.seed = who.rng_seed * 31 + 5
	_rest = _rng.randf_range(0.0, tuning.idle_before)


func busy() -> bool:
	return step != Step.IDLE


## Each tick from his brain. `free`: calm, nothing over him, nothing he'd sooner be doing. True
## while the chore has his body this tick (the brain leaves him be).
func step_chore(delta: float, free: bool) -> bool:
	if not _gaze_looked:
		_find_gaze()
	if cloth == null or not is_instance_valid(cloth) or cloth.burnt or body.limp or body.prone:
		if step != Step.IDLE:
			_end(&"lost")
		return false
	if not free or body.grab_side() != "":
		# Trouble, or a wound of his he's holding: it stops (and his arms ease back, not snap).
		if step != Step.IDLE:
			trouble()
		_ease_out(delta)
		_look(Vector3.INF, delta)  # his lean and his head's turn let go too, under whatever he's doing now
		_lean_to(delta)
		return false
	_t += delta
	_customer_t -= delta
	if _customer_t <= 0.0:
		_customer_t = 0.2
		_customer_seen = _customer()
	if step in [Step.WIPE, Step.MOVE, Step.GLASS] and not _holding():
		# Knocked out of his hand (a shot, a blast, a man): he goes and gets it.
		_put_cup_back()
		_end(&"dropped")
		return false
	if _customer_seen and step in [Step.TAKE, Step.LAY, Step.WIPE, Step.MOVE, Step.GLASS]:
		_begin_put_back(&"customer")
	match step:
		Step.IDLE:
			return _idle_step(delta)
		Step.TAKE:
			_take_step()
		Step.LAY:
			_lay_step()
		Step.WIPE:
			_wipe_step(delta)
		Step.MOVE:
			_move_step(delta)
		Step.GLASS:
			_glass_step()
		Step.PUT_BACK:
			_put_back_step()
		Step.FETCH:
			_fetch_step(delta)
	# A step that ended this tick without placing the hand (the next one starts next tick): it
	# stays where it was, not dropped to his side for a tick.
	var now := Engine.get_physics_frames()
	if step != Step.IDLE and _reached != now and _hand_at != Vector3.INF:
		body.reach_to(hand, _hand_at, _hand_n, 1.0)
	if _cup != null and _reached_l != now and _cup_at != Vector3.INF:
		body.reach_to("l" if hand == "r" else "r", _cup_at, _cup_n, 1.0)
	_look(watching, delta)
	_lean_to(delta)
	return true


## Trouble: whatever he's doing stops; the cloth in his hand is tossed down where he is (unless
## that hand's gone to a wound of his: then it's pressed on it, cloth and all).
func trouble() -> void:
	if cloth != null and is_instance_valid(cloth) and cloth.holder == body and cloth.held == ClothProp.Held.HAND:
		if body.grab_side() != cloth.side:
			cloth.let_go(_forward() * tuning.toss_speed + Vector3.UP * 0.4)
	_put_cup_back()
	_end(&"trouble")


# --- The steps -------------------------------------------------------------------------------------

func _idle_step(delta: float) -> bool:
	_ease_out(delta)
	_look(Vector3.INF, delta)
	_lean_to(delta)
	_rest -= delta
	if cloth.held == ClothProp.Held.FREE:
		# His rag lying about: he gets it once he's been calm a moment, rest or no rest.
		_idle += delta
		if _idle >= FETCH_AFTER and cloth.centre().distance_to(post) <= tuning.fetch_reach:
			_go(Step.FETCH)
			_route.clear()
			return true
		return false
	if cloth.holder != body or _customer_seen:
		_idle = 0.0
		return false
	if _rest > 0.0 or body.global_position.distance_to(post) > 0.35:
		return false
	_idle += delta
	if _idle < tuning.idle_before:
		return false
	_along = _offset_along()
	_bar = _find_bar(_along)
	if not _bar.is_empty() and _cluttered(_centre()):
		_bar = {}
	if _bar.is_empty():
		_idle = 0.0
		_rest = tuning.rest_between.x
		return false
	cycles += 1
	_left = _rng.randi_range(tuning.stretches.x, tuning.stretches.y)
	_go(Step.TAKE if cloth.held == ClothProp.Held.SHOULDER else Step.LAY)
	return true


## His hand to his shoulder; he takes the cloth.
func _take_step() -> void:
	_stand()
	var top := ClothProp.shoulder_top(body, shoulder) + Vector3.UP * 0.015
	_reach_eased(top, Vector3.UP)
	watching = top + _forward() * 0.1
	if _t >= tuning.reach_seconds + 0.1:
		cloth.hold(body, hand)
		body.curl_hand(hand, tuning.grip_carry)
		_go(Step.LAY)


## Over to the stretch, down onto the bar; let go so it lies flat, then his hand flat on it.
func _lay_step() -> void:
	_stand()
	var centre := _centre()
	var lift := tuning.carry_above + 0.05
	var over := centre + Vector3.UP * lift
	if _phase == 0:
		_reach_eased(over, Vector3.UP, tuning.reach_seconds * 1.4)
		watching = centre
		if _t >= tuning.reach_seconds * 1.4:
			_next_phase()
	elif _phase == 1:
		_reach_eased(centre + Vector3.UP * (tuning.palm_above + 0.015), _bar.n, 0.35)
		if _t >= 0.35:
			cloth.let_go()
			_next_phase()
	elif _phase == 2:
		_reach(centre + Vector3.UP * (tuning.palm_above + 0.015), _bar.n)
		if _t >= 0.25:
			cloth.hold(body, hand)
			body.curl_hand(hand, tuning.grip_wipe)
			_wipe_for = _rng.randf_range(tuning.wipe_seconds.x, tuning.wipe_seconds.y)
			_go(Step.WIPE)


## The clip of a man wiping a bar (assets/animations/wipe_bar.json, from the Studio's Uthana
## takes, 2026-10-24) plays looped under the wiping for his body: his lean, his weight going
## stroke to stroke, his free hand on the counter. His working arm stays the deed's: reach_to runs
## after the clip and keeps his palm and the cloth on the real bar top. None: the pose as before.
const CLIP := &"wipe_bar"


## Circles drifting across the stretch, then long strokes along it, the hand on the bar top.
func _wipe_step(_delta: float) -> void:
	_stand()
	if not body.clip_playing() and MotionClip.load_clip(CLIP) != null:
		body.play_clip(CLIP, 1.0, true, {"travel": false})
	var centre := _centre()
	var side: Vector3 = _bar.side
	var fwd: Vector3 = _bar.fwd
	var circles := _wipe_for * (1.0 - tuning.stroke_share)
	var p := centre
	if _t < circles:
		var a := TAU * tuning.circle_hz * _t
		var drift := lerpf(-0.5, 0.5, _t / maxf(circles, 0.01)) * tuning.circle_drift
		p += side * (drift + cos(a) * tuning.circle_radius) + fwd * sin(a) * tuning.circle_radius
	else:
		var s := _t - circles
		p += side * sin(TAU * tuning.stroke_hz * s) * tuning.stroke_length * 0.5
		p += fwd * sin(TAU * tuning.stroke_hz * s * 0.5) * tuning.circle_radius * 0.6
	var top := _surface(p)
	if top.is_empty():
		top = {"at": Vector3(p.x, (_bar.near as Vector3).y, p.z), "n": _bar.n}
	var at: Vector3 = top.at + (top.n as Vector3) * tuning.palm_above
	if _t < 0.3:
		at = _from.lerp(at, smoothstep(0.0, 0.3, _t))
	_reach(at, top.n)
	watching = top.at
	if _t >= _wipe_for:
		wiped += 1
		_left -= 1
		var cup := _find_cup()
		if cup != null and _rng.randf() < tuning.glass_chance:
			_go(Step.GLASS)
			_cup_found = cup
		elif _left > 0:
			_start_move()
		else:
			_begin_put_back(&"done")


func _start_move() -> void:
	# The next clear stretch along the bar this way, else back the other way.
	var next := INF
	for turn in 2:
		for k in range(1, 4):
			var at := _along + _dir * tuning.stretch * k
			if absf(at) > tuning.span + 0.01:
				break
			var bar := _find_bar(at)
			if not bar.is_empty() and not _cluttered((bar.near as Vector3) + (bar.fwd as Vector3) * tuning.reach_out * 0.5):
				next = at
				break
		if next != INF:
			break
		_dir = -_dir
	if next == INF:
		_begin_put_back(&"done")
		return
	_next_along = next
	var lifted := body.palm(hand) + Vector3.UP * tuning.carry_above
	_carry_local = body.global_transform.affine_inverse() * lifted
	body.curl_hand(hand, tuning.grip_carry)
	_go(Step.MOVE)


## Along the bar a step or two, the cloth lifted in his hand.
func _move_step(delta: float) -> void:
	var fwd := _forward()
	var side := _side()
	var goal := post + side * _next_along
	var arrived := body.walk_to(goal, tuning.step_speed, delta, false)
	body.set_pose(&"stand")
	body.face(body.global_position + fwd * 2.0 + Vector3.UP * 1.4)
	var at := body.global_transform * _carry_local
	_reach(_from.lerp(at, smoothstep(0.0, 0.25, _t)) if _t < 0.25 else at, Vector3.UP)
	watching = at + fwd * 0.15
	if arrived or _t > 4.0:
		_along = _next_along
		_bar = _find_bar(_along)
		if _bar.is_empty():
			_begin_put_back(&"done")
			return
		body.curl_hand(hand, tuning.grip_wipe)
		_wipe_for = _rng.randf_range(tuning.wipe_seconds.x, tuning.wipe_seconds.y)
		_go(Step.WIPE)


## A cup: his other hand takes it, holds it up, the cloth turns in it; put back where it was.
func _glass_step() -> void:
	_stand()
	var other := "l" if hand == "r" else "r"
	var rest := body.palm(hand)
	if _phase == 0:
		if _cup == null:
			_cup = _cup_found if _cup_found != null and is_instance_valid(_cup_found) else _find_cup()
			_cup_found = null
			if _cup == null:
				_after_glass()
				return
			_cup_h = PropLibrary.bounds_of(_cup).size.y if _cup.has_meta(&"bounds") else 0.1
			var to_me := body.global_position - _cup.global_position
			to_me.y = 0.0
			_cup_n = to_me.normalized()
			_cup_goal = _cup.global_position + Vector3.UP * _cup_h * 0.5 + _cup_n * 0.05
			_hand_at_l(body.palm(other))
		_reach_l(_cup_goal, _cup_n, _t / tuning.reach_seconds)
		_reach(rest, Vector3.UP)
		watching = _cup.global_position
		if _t >= tuning.reach_seconds + 0.05:
			if body.palm(other).distance_to(_cup_goal) > 0.08:
				_cup = null  # his hand didn't get there: leave it
				_out_l = tuning.reach_seconds
				_after_glass()
				return
			_take_cup(other)
			_wipe_for = _rng.randf_range(tuning.glass_seconds.x, tuning.glass_seconds.y)
			_next_phase()
	elif _phase == 1:
		var held := body.global_transform * tuning.glass_held
		var palm_n := -body.global_basis.x if other == "l" else body.global_basis.x
		_reach_l(_cup_goal.lerp(held, smoothstep(0.0, 0.4, _t)) if _t < 0.4 else held, palm_n, 1.0)
		var mouth := _cup.global_position + _cup.global_basis.y * (_cup_h - 0.02)
		var a := TAU * tuning.glass_hz * _t
		var in_cup := mouth + Vector3(cos(a), 0.0, sin(a)) * tuning.glass_radius + Vector3.UP * tuning.palm_above
		var k := smoothstep(0.3, 0.8, _t)
		_reach(rest.lerp(in_cup, k), Vector3.UP)
		body.curl_hand(hand, lerpf(tuning.grip_wipe, tuning.grip_carry, k))
		watching = mouth
		if _t >= _wipe_for:
			_from = body.palm(hand)
			_next_phase()
	elif _phase == 2:
		var home := _cup_home.origin + Vector3.UP * _cup_h * 0.5 + _cup_n * 0.05
		if _t <= 1.0 / 60.0 + 1e-4:
			_hand_at_l(body.palm(other))
		_reach_l(home, _cup_n, _t / tuning.reach_seconds)
		var down := _centre() + Vector3.UP * tuning.carry_above
		_reach(_from.lerp(down, smoothstep(0.0, tuning.reach_seconds, _t)), Vector3.UP)
		watching = _cup_home.origin
		if _t >= tuning.reach_seconds + 0.05:
			_put_cup_back()
			cups += 1
			_after_glass()


func _after_glass() -> void:
	body.curl_hand(hand, tuning.grip_carry)
	if _left > 0:
		_from = body.palm(hand)
		_start_move()
	else:
		_begin_put_back(&"done")


## Back over his shoulder (picked up off the bar first if it's lying there).
func _begin_put_back(why: StringName) -> void:
	_then_why = why
	_put_cup_back()
	_go(Step.PUT_BACK)
	_phase = 0 if cloth.holder == body and cloth.held == ClothProp.Held.HAND else -1


func _put_back_step() -> void:
	if _then_why == &"fetched":
		body.set_pose(&"stand")
	else:
		_stand()
	if _phase == -1:
		if cloth.held == ClothProp.Held.SHOULDER and cloth.holder == body:
			_end(_then_why)
			return
		var mid := cloth.point(cloth.middle_point()) + Vector3.UP * 0.02
		if not body.can_reach(hand, mid):
			_end(_then_why)  # it's out of reach (he'll fetch it when it's calm)
			return
		_reach_eased(mid, Vector3.UP)
		watching = mid
		if _t >= tuning.reach_seconds:
			cloth.hold(body, hand)
			body.curl_hand(hand, tuning.grip_carry)
			_from = body.palm(hand)
			_t = 0.0
			_phase = 0
		return
	var top := ClothProp.shoulder_top(body, shoulder) + Vector3.UP * 0.03
	_reach_eased(top, Vector3.UP, tuning.reach_seconds * 1.2)
	watching = Vector3.INF
	if _t >= tuning.reach_seconds * 1.2 + 0.1:
		cloth.hang_on(body, shoulder)
		body.curl_hand(hand, 0.15)
		_end(_then_why)


## A cloth he's lost: over to it (round by the places), down for it if it's on the floor, and back
## over his shoulder.
func _fetch_step(delta: float) -> void:
	_fetch_t += delta
	if cloth.held != ClothProp.Held.FREE:
		_end(&"done" if cloth.holder == body else &"lost")
		return
	if _fetch_t > tuning.fetch_give_up:
		_rest = tuning.rest_between.y
		_end(&"lost")
		return
	var where := cloth.centre()
	var grab := cloth.point(cloth.nearest_point(body.palm(hand))) + Vector3.UP * 0.02
	var flat := Vector3(grab.x, body.global_position.y, grab.z)
	# On his bar: along behind it to where it lies, and across the top for it, leaning in.
	var along := clampf((where - post).dot(_side()), -tuning.span - 0.5, tuning.span + 0.5)
	if _phase == 0 and where.y > post.y + tuning.bar_height.x - 0.05 and not _find_bar(along).is_empty():
		var spot := post + _side() * along
		if body.global_position.distance_to(spot) > 0.1:
			body.set_pose(&"stand")
			body.walk_to(spot, tuning.step_speed * 1.5, delta, false)
			body.face(body.global_position + _forward() * 2.0 + Vector3.UP * 1.4)
			watching = where
			return
		_next_phase()
		_across = true
	if _phase == 1 and _across:
		_stand()
		_reach_eased(grab, Vector3.UP, tuning.reach_seconds * 1.5)
		watching = grab
		if body.palm(hand).distance_to(grab) < 0.07:
			cloth.hold(body, hand)
			body.curl_hand(hand, tuning.grip_carry)
			_begin_put_back(&"fetched")
		elif _t > tuning.reach_seconds * 4.0:
			_rest = tuning.rest_between.x  # across the bar, past his reach: it waits for a customer to hand it back
			_end(&"lost")
		return
	if _phase == 1 or (body.global_position.distance_to(flat) < 0.75 and _route.size() <= 1):
		# There: down for it if it's low, and take it.
		if _phase == 0:
			_next_phase()
		var low := grab.y < body.global_position.y + 0.7
		body.set_pose(&"crouch" if low else &"stand")
		body.face(Vector3(grab.x, body.global_position.y + 1.4, grab.z))
		_reach_eased(grab, Vector3.UP, tuning.reach_seconds * 1.5)
		watching = grab
		if body.palm(hand).distance_to(grab) < 0.07 or _t > tuning.reach_seconds * 3.0:
			cloth.hold(body, hand)
			body.curl_hand(hand, tuning.grip_carry)
			_begin_put_back(&"fetched")
		return
	body.set_pose(&"stand")
	var to := where - body.global_position
	to.y = 0.0
	var stand_at := where - to.normalized() * 0.45
	if _route.is_empty():
		if places != null:
			_route = FireFlight.route(places, body, stand_at)
		else:
			_route = [stand_at]
		if _route.is_empty():
			_route = [stand_at]
	watching = where
	if body.walk_to(_route[0], 1.1, delta) and _route.size() > 1:
		_route.pop_front()


func _end(why: StringName) -> void:
	stopped = why
	if step != Step.IDLE:
		_out = tuning.reach_seconds
	step = Step.IDLE
	_t = 0.0
	_phase = 0
	_idle = 0.0
	_route.clear()
	_fetch_t = 0.0
	_across = false
	watching = Vector3.INF
	if why == &"done":
		_rest = _rng.randf_range(tuning.rest_between.x, tuning.rest_between.y)
	elif why in [&"customer", &"fetched"]:
		_rest = 0.0
	elif why == &"dropped":
		_rest = 0.6


func _holding() -> bool:
	return cloth.holder == body and cloth.held == ClothProp.Held.HAND


func _go(s: Step) -> void:
	if body.clip_playing() and body.clip_name() == CLIP:
		body.stop_clip()
	step = s
	_t = 0.0
	_phase = 0
	_from = body.palm(hand)


func _next_phase() -> void:
	_phase += 1
	_t = 0.0
	_from = body.palm(hand)


# --- Hands, head, lean ------------------------------------------------------------------------------

func _stand() -> void:
	body.set_pose(&"stand")
	body.face(body.global_position + _forward() * 2.0 + Vector3.UP * 1.4)


func _reach(at: Vector3, n: Vector3) -> void:
	_hand_at = at
	_hand_n = n
	_reached = Engine.get_physics_frames()
	body.reach_to(hand, at, n, 1.0)


## From where the hand was when the step began to `at`, eased over `seconds`.
func _reach_eased(at: Vector3, n: Vector3, seconds := -1.0) -> void:
	var s := seconds if seconds > 0.0 else tuning.reach_seconds
	var from := _from if _from != Vector3.INF else body.palm(hand)
	_reach(from.lerp(at, smoothstep(0.0, 1.0, clampf(_t / s, 0.0, 1.0))), n)


## The arms let back to his pose over a moment, not snapped.
func _ease_out(delta: float) -> void:
	if _out > 0.0 and _hand_at != Vector3.INF:
		_out = maxf(_out - delta, 0.0)
		body.reach_to(hand, _hand_at, _hand_n, smoothstep(0.0, 1.0, _out / tuning.reach_seconds))
	if _out_l > 0.0 and _cup_at != Vector3.INF:
		_out_l = maxf(_out_l - delta, 0.0)
		body.reach_to("l" if hand == "r" else "r", _cup_at, _cup_n, smoothstep(0.0, 1.0, _out_l / tuning.reach_seconds))


var _l_from := Vector3.INF


func _hand_at_l(at: Vector3) -> void:
	_l_from = at


func _reach_l(at: Vector3, n: Vector3, k: float) -> void:
	var other := "l" if hand == "r" else "r"
	var target := _l_from.lerp(at, smoothstep(0.0, 1.0, clampf(k, 0.0, 1.0))) if _l_from != Vector3.INF else at
	_cup_at = target
	_cup_n = n
	_reached_l = Engine.get_physics_frames()
	body.reach_to(other, target, n, 1.0)


## His head to what he's watching (a FaceGaze does it with his eyes leading, if he has one).
func _look(at: Vector3, delta: float) -> void:
	if _life != null and is_instance_valid(_life) and _life.has_face():
		if at != Vector3.INF:
			_life.attend_to(at)
		_head = Vector2.ZERO
		_set_offsets()
		return
	var goal := Vector2.ZERO
	if at != Vector3.INF:
		var head := (body.pivots[&"head"] as Node3D).global_position
		var local := body.global_basis.inverse() * (at - head)
		var yaw := rad_to_deg(atan2(-local.x, -local.z))
		var pitch := rad_to_deg(atan2(local.y, Vector2(local.x, local.z).length()))
		goal = Vector2(clampf(pitch, -50.0, 20.0), clampf(yaw, -60.0, 60.0)) * tuning.head_share
	_head = _head.lerp(goal, clampf(delta * tuning.head_rate, 0.0, 1.0))
	_set_offsets()


## Leaning in for the far side of a stretch (or stooping for the floor).
func _lean_to(delta: float) -> void:
	var goal := 0.0
	if step in [Step.WIPE, Step.LAY] and _hand_at != Vector3.INF:
		var sh := (body.pivots[StringName("upper_arm_" + hand)] as Node3D).global_position
		var d := Vector2(_hand_at.x - sh.x, _hand_at.z - sh.z).length()
		goal = -clampf((d - tuning.lean_from) * tuning.lean_per_m, 0.0, tuning.lean_max)
	elif step == Step.FETCH and body.pose == &"crouch":
		goal = tuning.stoop.x
	elif step == Step.FETCH and _across and _hand_at != Vector3.INF:
		# Across the bar for it: as far over as it takes.
		var sh := (body.pivots[StringName("upper_arm_" + hand)] as Node3D).global_position
		var d := Vector2(_hand_at.x - sh.x, _hand_at.z - sh.z).length()
		goal = -clampf((d - tuning.lean_from) * tuning.lean_per_m * 2.0, 0.0, tuning.lean_across)
	_lean = lerpf(_lean, goal, clampf(delta * 4.0, 0.0, 1.0))
	_set_offsets()


func _set_offsets() -> void:
	var on := absf(_lean) > 0.05 or _head.length() > 0.05
	if not on and not _offsets:
		return
	_offsets = on
	# His head's his FaceLife's (its gaze turns it) if he has one; only his trunk is ours then.
	var own_head := _life == null or not is_instance_valid(_life) or not _life.has_face()
	if not on:
		for k in ([&"head", &"neck", &"abdomen", &"chest"] if own_head else [&"abdomen", &"chest"]):
			body.pose_offsets.erase(k)
		return
	var stoop := step == Step.FETCH
	body.pose_offsets[&"abdomen"] = Vector3(_lean * 0.5 if not stoop else tuning.stoop.x * absf(_lean / tuning.stoop.x), 0, 0)
	body.pose_offsets[&"chest"] = Vector3(_lean * 0.5 if not stoop else tuning.stoop.y * absf(_lean / tuning.stoop.x), 0, 0)
	if own_head:
		body.pose_offsets[&"neck"] = Vector3(_head.x * 0.4, _head.y * 0.4, 0)
		body.pose_offsets[&"head"] = Vector3(_head.x * 0.6, _head.y * 0.6, 0)


func _find_gaze() -> void:
	_gaze_looked = true
	_life = body.get_node_or_null(^"FaceLife") as FaceLife


# --- The world --------------------------------------------------------------------------------------

func _forward() -> Vector3:
	var f := (faces - post) if faces != Vector3.INF and post != Vector3.INF else -body.global_basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func _side() -> Vector3:
	return _forward().cross(Vector3.UP).normalized()


## How far along the bar from his post he is now.
func _offset_along() -> float:
	return clampf((body.global_position - post).dot(_side()), -tuning.span, tuning.span)


## The bar top in front of the spot `along` from his post: {near (on the top, just in from its near
## edge), n, fwd, side}; empty if there's no bar there.
func _find_bar(along: float) -> Dictionary:
	var fwd := _forward()
	var side := _side()
	var base := post + side * along
	var space := World.space(body)
	var d := tuning.bar_ahead.x
	while d <= tuning.bar_ahead.y:
		var p := base + fwd * d
		var hit := _ray_down(space, p + Vector3.UP * (tuning.bar_height.y + 0.05), p + Vector3.UP * tuning.bar_height.x)
		if not hit.is_empty():
			return {"near": hit.position + fwd * 0.04, "n": hit.normal, "fwd": fwd, "side": side}
		d += 0.04
	return {}


## The top under `p` (near the stretch's height): {at, n}, or empty.
func _surface(p: Vector3) -> Dictionary:
	var y: float = (_bar.near as Vector3).y
	var hit := _ray_down(World.space(body), Vector3(p.x, y + 0.2, p.z), Vector3(p.x, y - 0.15, p.z))
	if hit.is_empty():
		return {}
	return {"at": hit.position, "n": hit.normal}


## Straight down onto the world, past props (a cup isn't the bar top).
func _ray_down(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	var exclude: Array[RID] = []
	for i in 3:
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return {}
		var c: Object = hit.collider
		if c is Node and ((c as Node).has_meta(&"prop_id") or (c as Node).has_meta(&"glass_prop")):
			exclude.append((c as CollisionObject3D).get_rid())
			continue
		return hit
	return {}


## Something standing on the bar round `centre` (a bottle, a lamp; not a cup, which he picks up):
## he leaves that stretch alone.
func _cluttered(centre: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = tuning.circle_radius + tuning.stroke_length * 0.5
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, centre + Vector3.UP * 0.12)
	q.collision_mask = Layers.WORLD | Layers.DEBRIS
	for hit in World.space(body).intersect_shape(q, 8):
		var c: Object = hit.collider
		if c is Node and ((c as Node).has_meta(&"glass_prop") or ((c as Node).has_meta(&"prop_id") and not (c as Node).get_meta(&"prop_id") in CUPS)):
			return true
	return false


## The middle of the stretch he's wiping (on the bar top).
func _centre() -> Vector3:
	return (_bar.near as Vector3) + (_bar.fwd as Vector3) * tuning.reach_out * 0.5


## Someone at the bar: near him and across it.
func _customer() -> bool:
	var me := body.global_position
	var fwd := _forward()
	var tree := body.get_tree()
	for n: Node in tree.get_nodes_in_group(&"people") + tree.get_nodes_in_group(&"player"):
		if n == body or not n is Node3D:
			continue
		if n is HumanBody and ((n as HumanBody).limp or not (n as HumanBody).physiology.is_conscious()):
			continue
		var d := (n as Node3D).global_position - me
		d.y = 0.0
		if d.length() < tuning.customer_near and d.dot(fwd) > tuning.customer_ahead:
			return true
	return false


## A cup on the bar within his other hand's reach.
func _find_cup() -> Node3D:
	var other := "l" if hand == "r" else "r"
	var sh := (body.pivots[StringName("upper_arm_" + other)] as Node3D).global_position
	var q := PhysicsShapeQueryParameters3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	q.shape = s
	q.transform = Transform3D(Basis.IDENTITY, sh)
	q.collision_mask = Layers.WORLD
	# Its own side or in front of him (not across his body), well inside his reach.
	var own_side := _side() * (1.0 if other == "r" else -1.0)
	var arm := body.palm(other).distance_to(sh) + 0.05
	for hit in World.space(body).intersect_shape(q, 16):
		var c: Object = hit.collider
		if c is Node3D and (c as Node).get_meta(&"prop_id", &"") in CUPS:
			var top := (c as Node3D).global_position + Vector3.UP * 0.05
			if (top - body.global_position).dot(own_side) > -0.08 and top.distance_to(sh) < minf(arm, 0.62):
				return c as Node3D
	return null


func _take_cup(other: String) -> void:
	if _cup == null or not is_instance_valid(_cup):
		return
	StaticBatch.release_in(body.get_tree(), _cup)
	_cup_parent = _cup.get_parent()
	_cup_home = _cup.global_transform
	if _cup is CollisionObject3D:
		_cup_layer = (_cup as CollisionObject3D).collision_layer
		(_cup as CollisionObject3D).collision_layer = 0
	# Into his palm: its side against it, as he takes it.
	var palm := body.palm(other)
	var off := _cup.global_position + Vector3.UP * _cup_h * 0.5 - palm
	off.y = 0.0
	_cup.global_position -= off.limit_length(0.12) - off.normalized() * 0.045 if off.length() > 0.045 else Vector3.ZERO
	_cup.reparent(body.parts[StringName("hand_" + other)], true)
	body.curl_hand(other, tuning.grip_cup)


func _put_cup_back() -> void:
	if _cup == null:
		return
	var other := "l" if hand == "r" else "r"
	if is_instance_valid(_cup) and _cup_parent != null and is_instance_valid(_cup_parent) and _cup.get_parent() != _cup_parent:
		_cup.reparent(_cup_parent, true)
		_cup.global_transform = _cup_home
		if _cup is CollisionObject3D:
			(_cup as CollisionObject3D).collision_layer = _cup_layer
	_cup = null
	_cup_parent = null
	body.curl_hand(other, 0.15)
	_out_l = tuning.reach_seconds
