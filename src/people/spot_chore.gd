class_name SpotChore
extends RefCounted
## Something to do where he stands (townsfolk brief §3 "Spots", #957): the chore a day's block names
## with its `do` (ValleyFolk._chores_for), in CivilianBrain.chores like WipeBar: it has him while he's
## free and at his spot, and stops the moment he isn't (trouble, sent off).
##
## Every kind is a loop with small breaks (Sean, #276: "hammer, pause, inspect, rub a shoulder, hammer
## again"): its main doing for a while, then one of its three breaks, picked by his seed, never the same
## break twice running, then the main again; nothing held longer than KINDS' longest span (the brief's
## spots row: no pose held 20 s). What each looks like is built from what bodies have: poses, pose
## offsets (a lean, a turn of the head), `reach_to` (a hand to a point), `curl_hand`, his FaceSpeech's
## mouth; new clips wait for the motion library (#810) and the prop lab's broom and sack (stand-ins
## here: plain drawn shapes, no body, left lying where he was when trouble came).
##
## - `stand`: weight from foot to foot; breaks: a look up and down the street, a hitch of his belt, his
##   hat pushed back.
## - `lean`: his back to the wall behind his spot (a ray finds it; none, a hip-shot stand), a boot up on
##   it, arms folded; breaks: a look about, a stretch, the other boot.
## - `sit`: in the spot's seat (SitChore on the kit prop ValleyFolk puts there); breaks: elbows on his
##   knees, a look about, a turn to whoever's sat beside him.
## - `counter`: behind a bar or counter, his hands on its top, facing whoever's at it (WipeBar's
##   customer rule: the nearest man across it); breaks: writing in the book, a look round the room,
##   arms folded.
## - `sweep`: a broom (stand-in) worked along the walk in strokes, a step on every few; breaks: leant
##   on the broom, a look up the street, the broom knocked on the boards. With `tool: rug` in the spot:
##   a rug shaken over the rail instead.
## - `carry`: sacks (stand-ins) from his spot's pile to its `to`, lifted, shouldered, set down, back for
##   the next; the pile all moved, back the other way; breaks: a hand to his back, his brow wiped.
## - `talk`: facing the others talking near him (a `talk` chore within TALK_NEAR), his mouth going
##   when it's his turn (his FaceSpeech, no line heard: the walla is sound's), a hand moving as he
##   talks; breaks: a laugh, a nod, a look away. With nobody near, he waits looking about (`alone_s`).
## - `drink`: a glass (stand-in) on the bar before him, up to his mouth, down; breaks: a look round,
##   both forearms on the bar, the glass turned in his fingers.
## - `work`: at the spot's `tool` (`anvil` the smith's hammer, `bench` the undertaker's plane: drawn
##   stand-ins); breaks: inspecting it close, rubbing his shoulder, his brow wiped.

## Each kind's main doing, how long it runs (s, by seed), its breaks.
const KINDS := {
	&"stand": {"main": &"idle", "for": Vector2(6.0, 13.0), "breaks": [&"look_about", &"hitch_belt", &"hat_back"]},
	&"lean": {"main": &"lean", "for": Vector2(7.0, 14.0), "breaks": [&"look_about", &"stretch", &"other_boot"]},
	&"sit": {"main": &"sit", "for": Vector2(7.0, 14.0), "breaks": [&"elbows", &"look_about", &"turn_to"]},
	&"counter": {"main": &"hands_on", "for": Vector2(6.0, 12.0), "breaks": [&"write", &"look_about", &"arms_folded"]},
	&"sweep": {"main": &"sweep", "for": Vector2(8.0, 14.0), "breaks": [&"lean_broom", &"look_about", &"knock"]},
	&"carry": {"main": &"carry", "for": Vector2(9.0, 15.0), "breaks": [&"rub_back", &"wipe_brow", &"look_about"]},
	&"talk": {"main": &"talk", "for": Vector2(6.0, 12.0), "breaks": [&"laugh", &"nod", &"look_away"]},
	&"drink": {"main": &"drink", "for": Vector2(6.0, 12.0), "breaks": [&"look_about", &"forearms", &"turn_glass"]},
	&"work": {"main": &"work", "for": Vector2(7.0, 13.0), "breaks": [&"inspect", &"rub_shoulder", &"wipe_brow"]},
}
## How long a break runs (s, by seed).
const BREAK_FOR := Vector2(2.2, 4.5)
## The longest any doing may hold him (s): the brief's spots row is under 20.
const LONGEST := 15.0
## Near his spot (m): from here the chore has him (his brain walks him there: it stops at 0.3).
const REACH := 0.35
## Others talking this near (m) are his company.
const TALK_NEAR := 3.5
## A customer across the counter this near (m).
const CUSTOMER_NEAR := 2.5
## A wall behind him this near (m), he leans on it.
const WALL_NEAR := 0.7
## The pile he carries (sacks).
const SACKS := 3
const CARRY_SPEED := 0.9

var man: HumanBody
var kind := &"stand"
var post := Vector3.INF
var faces := Vector3.INF
## The spot's data (`to` for carry, `tool` for sweep and work), with any points ValleyFolk worked out
## (`top`: a bar or counter top under his hands, a world point; `to_at`: carry's far end).
var spot := {}
## The seat's chore, for `sit`.
var sit: SitChore
## False: he's to go (ValleyFolk sending him off): stands up, puts things down, lets him go.
var wanted := true

## What he's at now (the main doing or a break), and the count of changes and the longest he held
## one (s), for the spots measure.
var doing := &""
var changes := 0
var longest := 0.0
## Breaks taken, by name (the tests: more than one kind of break).
var taken := {}
## Strokes, lifts, sips (each kind's count of its main work).
var strokes := 0

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _left := 0.0
var _last_break := &""
var _on := false
## Seconds a `talk` has had nobody near to talk with (0 while he has company).
var alone_s := 0.0
var _hands := false
var _keys := {}
var _life: FaceLife
var _brain: CivilianBrain
## In a room with a director (SaloonRoom): his talk's own laugh is the director's to give.
var directed := false
## His glass raised by a bit (0-1: a toast's, the bar's lift), over his own drinking.
var glass_up := 0.0
var _speech: FaceSpeech
var _looked := false
var _wall := Vector3.INF
var _look_yaw := 0.0
var _say_in := 0.0
## Stand-ins: drawn shapes, no bodies (the prop lab's to make).
var _tool: MeshInstance3D
var _sacks: Array[MeshInstance3D] = []
## Carry: which end the pile's at (0 his spot, 1 `to`), the sack in his arms (-1 none), what he's
## doing with it.
var _pile_at := 0
var _held := -1
var _carry_step := &"to_pile"
var _carry_t := 0.0
## Sweep: how far along the walk he's got (m), which way he's going.
var _along := 0.0
var _dir := 1.0
var _stroke_was := 0.0


func _init(m: HumanBody, k: StringName, at_post: Vector3, facing: Vector3, data := {}, seed_value := -1) -> void:
	man = m
	kind = k if KINDS.has(k) else &"stand"
	post = at_post
	faces = facing
	spot = data
	_rng.seed = hash([m.rng_seed if m != null else seed_value, String(kind), "spot"])
	_t = 0.0
	_left = _rng.randf_range(0.0, (KINDS[kind].for as Vector2).x)  # (not all in step from the start)
	doing = KINDS[kind].main


func busy() -> bool:
	return _on or (sit != null and sit.busy())


## His hands at nothing that needs them every tick: he may tick slowly far from you (PeopleTick's
## bands). A reach lapses unless renewed each tick, so while his hands are on something he can't.
func lets_slow() -> bool:
	return not _hands


## The plan of his doings from now for `seconds`, as [name, span] (the same seed gives the same):
## for the tests' spots measure, without running a body for ten minutes.
static func plan(seed_value: int, k: StringName, seconds: float) -> Array:
	var c := SpotChore.new(null, k, Vector3.ZERO, Vector3.FORWARD, {}, seed_value)
	c.doing = KINDS[c.kind].main
	c._left = c._span(c.doing)
	var out := []
	var t := 0.0
	while t < seconds:
		out.append([c.doing, c._left])
		t += c._left
		c._next()
	return out


func step_chore(delta: float, free: bool) -> bool:
	if not is_instance_valid(man):
		return false
	if not _looked:
		_looked = true
		_life = man.get_node_or_null(^"FaceLife") as FaceLife
		_speech = man.get_node_or_null(^"FaceSpeech") as FaceSpeech
		_brain = man.get_node_or_null(^"Brain") as CivilianBrain
	if not free or not wanted or man.limp or man.prone or not man.physiology.is_conscious() or man.grab_side() != "" \
			or _sent_elsewhere():
		stop()
		return false
	if kind == &"sit":
		# Only from beside the seat and level with it: from the street below a raised walk SitChore's
		# straight walk would take him under its boards (the playtest's loudmouth); his brain's route
		# brings him up first.
		var to := man.global_position - post
		var sat := sit != null and sit.busy()
		if not sat and (Vector2(to.x, to.z).length() > 0.9 or absf(to.y) > 0.4):
			_on = false
			return false
		if sit == null or not sit.step_chore(delta, true):
			_on = false
			return false
	elif not _on:
		var flat := man.global_position - post
		flat.y = 0.0
		if flat.length() > REACH:
			return false
	if not _on:
		_on = true
		_start()
	_hands = false
	_t += delta
	_left -= delta
	if _left <= 0.0 and _may_break():
		_next()
	_do(delta)
	_tidy()
	return true


## His brain's been given another post (an act's: the funeral's grave, the morning's errand): this
## spot's chore lets him go there.
func _sent_elsewhere() -> bool:
	var br := man.get_node_or_null(^"Brain") as CivilianBrain
	if br == null or br.post == Vector3.INF or post == Vector3.INF:
		return false
	return Vector2(br.post.x - post.x, br.post.z - post.z).length() > 0.5


## Trouble or sent off: up from his seat, the tool and sack set down where he is, his body his own.
func stop() -> void:
	if sit != null:
		sit.wanted = wanted
		sit.step_chore(0.0, false)
	if not _on:
		return
	_on = false
	_drop()
	for k: StringName in _keys:
		man.pose_offsets.erase(k)
	_keys.clear()
	if _speech and _speech.speaking():
		_speech.hush()


## Going for good (ValleyFolk sends him off, or he's gone in): as stop, and the stand-ins go.
func leave() -> void:
	wanted = false
	stop()
	if _tool and is_instance_valid(_tool):
		_tool.queue_free()
	for s in _sacks:
		if is_instance_valid(s):
			s.queue_free()
	_sacks.clear()


# --- The loop ------------------------------------------------------------------------------------

func _span(what: StringName) -> float:
	var r: Vector2 = KINDS[kind].for if what == KINDS[kind].main else BREAK_FOR
	return minf(_rng.randf_range(r.x, r.y), LONGEST)


## The main doing again after a break; after the main, a break (not the last one).
func _next() -> void:
	var main: StringName = KINDS[kind].main
	var was := doing
	if doing != main:
		doing = main
	else:
		var breaks: Array = (KINDS[kind].breaks as Array).filter(func(b: StringName) -> bool: return b != _last_break)
		doing = breaks[_rng.randi() % breaks.size()]
		if directed and doing == &"laugh":
			doing = &"nod"  # (a laugh in the room has a sound and a source: the director's)
		_last_break = doing
		taken[doing] = int(taken.get(doing, 0)) + 1
	longest = maxf(longest, _t)
	if doing != was:
		changes += 1
	_t = 0.0
	_left = _span(doing)


## Some mains finish what they're at before a break (a sack isn't dropped mid-step).
func _may_break() -> bool:
	if kind == &"carry" and doing == &"carry":
		return _held < 0 and _carry_step == &"to_pile" and _t > 1.0 or _t > LONGEST + 5.0
	return true


func _start() -> void:
	_wall = Vector3.INF
	if kind == &"lean":
		_wall = _find_wall()
	if kind in [&"sweep", &"work", &"drink"] and _tool == null:
		_tool = _make_tool()
	if kind == &"carry" and _sacks.is_empty():
		for i in SACKS:
			_sacks.append(_sack())
		_lay_pile()


# --- What he does ---------------------------------------------------------------------------------

func _do(delta: float) -> void:
	match kind:
		&"stand":
			_stand(delta)
		&"lean":
			_lean(delta)
		&"sit":
			_sit(delta)
		&"counter":
			_counter(delta)
		&"sweep":
			_sweep(delta)
		&"carry":
			_carry(delta)
		&"talk":
			_talk(delta)
		&"drink":
			_drink(delta)
		&"work":
			_work(delta)


func _stand(_delta: float) -> void:
	man.set_pose(&"stand")
	_face(faces)
	match doing:
		&"idle":
			# His weight from foot to foot, slow.
			var s := sin(_t * 0.7 + float(man.rng_seed))
			_offset(&"abdomen", Vector3(0, 0, 2.5 * s))
			_offset(&"chest", Vector3(0, 3.0 * sin(_t * 0.31), -1.5 * s))
		&"look_about":
			_look_about(1.0)
		&"hitch_belt":
			var k := _ease()
			_two_hands(Vector3(-0.13, 0.98 + 0.03 * sin(_t * 5.0) * k, -0.16), Vector3(0.13, 0.98 + 0.03 * sin(_t * 5.0) * k, -0.16), Vector3.DOWN, k, 0.8)
			_offset(&"head", Vector3(-8.0 * k, 0, 0))
		&"hat_back":
			var k := _ease()
			_hand("r", Vector3(0.02, 1.72, -0.13), Vector3.FORWARD, k, 0.6)
			_offset(&"head", Vector3(6.0 * k, 0, 0))
		_:
			_look_about(0.5)


func _lean(_delta: float) -> void:
	man.set_pose(&"stand")
	_face(faces)
	var wall := _wall != Vector3.INF
	var boot := &"thigh_l" if doing == &"other_boot" else &"thigh_r"
	var shin := &"shin_l" if doing == &"other_boot" else &"shin_r"
	var k := minf(_t / 0.8, 1.0)
	if wall:
		_offset(&"chest", Vector3(5.0, 0, 0) * k)
		_offset(&"abdomen", Vector3(3.0, 0, 0) * k)
		_offset(boot, Vector3(28.0, 0, 0) * k)
		_offset(shin, Vector3(-80.0, 0, 0) * k)
		_offset(&"thigh_r" if boot == &"thigh_l" else &"thigh_l", Vector3.ZERO)
		_offset(&"shin_r" if shin == &"shin_l" else &"shin_l", Vector3.ZERO)
	else:
		# No wall: a hip-shot stand, his weight on one leg.
		_offset(&"abdomen", Vector3(0, 0, 5.0) * k)
		_offset(&"chest", Vector3(0, 0, -4.0) * k)
	match doing:
		&"stretch":
			var s := _ease()
			_two_hands(Vector3(-0.15, 1.95, 0.0), Vector3(0.15, 1.95, 0.0), Vector3.UP, s, 0.3)
			_offset(&"chest", Vector3(8.0 * s, 0, 0))
		&"look_about":
			_folded()
			_look_about(1.0)
		_:
			_folded()
			_offset(&"head", Vector3(0, 6.0 * sin(_t * 0.2), 0))


func _sit(_delta: float) -> void:
	match doing:
		&"elbows":
			man.set_pose(&"sit_lean")
		&"look_about":
			_look_about(0.8)
		&"turn_to":
			var who := _nearest_doing([&"sit", &"talk"], 2.0)
			if who != null:
				_turn_head_to(who.global_position + Vector3.UP * 1.1)
				_mouth(0.5)
		_:
			_offset(&"head", Vector3(-3.0, 8.0 * sin(_t * 0.25), 0))


func _counter(_delta: float) -> void:
	man.set_pose(&"stand")
	var top: Vector3 = spot.get("top", man.global_transform * Vector3(0, 1.08, -0.55))
	var who := _customer()
	_face(who.global_position + Vector3.UP * 1.4 if who != null else faces)
	var fwd := _forward()
	var right := _right()
	var at := Vector3(man.global_position.x, top.y, man.global_position.z) + fwd * 0.42
	match doing:
		&"write":
			# One hand on the book, the other writing: small moves along a line, his head down.
			_hand_w("l", at - right * 0.14 + Vector3.UP * 0.02, Vector3.UP, 1.0)
			var w := at + right * (0.05 + 0.12 * fposmod(_t * 0.35, 1.0)) + fwd * (0.03 * sin(_t * 9.0)) + Vector3.UP * 0.03
			_hand_w("r", w, Vector3.UP, 1.0)
			man.curl_hand("r", 0.7)
			_offset(&"chest", Vector3(-12.0, 0, 0))
			_offset(&"head", Vector3(-20.0, 0, 0))
			_watch(w)
		&"arms_folded":
			_folded()
			_offset(&"chest", Vector3(3.0, 0, 0))
		&"look_about":
			_hand_w("l", at - right * 0.22, Vector3.UP, 1.0)
			_look_about(1.0)
		_:
			# Both hands spread on the top, leant on.
			_hand_w("l", at - right * 0.24, Vector3.UP, 1.0)
			_hand_w("r", at + right * 0.24, Vector3.UP, 1.0)
			_offset(&"chest", Vector3(-6.0, 0, 0))
			if who != null:
				_watch(who.global_position + Vector3.UP * 1.6)


func _sweep(delta: float) -> void:
	man.set_pose(&"stand")
	var rug := String(spot.get("tool", "")) == "rug"
	match doing:
		&"sweep":
			if rug:
				_shake_rug()
				return
			# Strokes across in front of him, a step along every few.
			var s := sin(_t * 3.4)
			if _stroke_was < 0.0 and s >= 0.0:
				strokes += 1
				if strokes % 3 == 0:
					_along += 0.35 * _dir
					if absf(_along) > float(spot.get("reach", 1.6)):
						_dir = -_dir
			_stroke_was = s
			var to := post + _street_side() * _along
			if Vector2(man.global_position.x - to.x, man.global_position.z - to.z).length() > 0.08:
				man.walk_to(to, 0.5, delta, false)
			_face(faces)
			var foot := man.global_transform * Vector3(0.35 * s, 0.03, -0.75)
			_hold_broom(foot)
			_offset(&"chest", Vector3(-14.0, 18.0 * s, 0))
			_offset(&"abdomen", Vector3(-6.0, 8.0 * s, 0))
			_watch(foot)
		&"lean_broom":
			_face(faces)
			var foot := man.global_transform * Vector3(0.0, 0.02, -0.35)
			_broom_upright(foot)
			_offset(&"head", Vector3(0, 10.0 * sin(_t * 0.6), 0))
		&"knock":
			_face(faces)
			var up := absf(sin(_t * 6.0))
			var foot := man.global_transform * Vector3(0.0, 0.02 + 0.12 * up, -0.4)
			_broom_upright(foot)
			_watch(foot)
		_:
			_face(faces)
			_broom_upright(man.global_transform * Vector3(0.0, 0.02, -0.35))
			_look_about(1.0)


func _carry(delta: float) -> void:
	var ends := [post, _to_at()]
	if doing != &"carry":
		man.set_pose(&"stand")
		if _held >= 0:
			_on_shoulder()
		match doing:
			&"rub_back":
				var k := _ease()
				_hand("r", Vector3(0.08, 1.0, 0.16), Vector3.BACK, k, 0.5)
				_offset(&"chest", Vector3(9.0 * k, 0, 0))
			&"wipe_brow":
				_wipe_brow()
			_:
				_look_about(1.0)
		return
	_carry_t += delta
	var pile: Vector3 = ends[_pile_at]
	var drop: Vector3 = ends[1 - _pile_at]
	match _carry_step:
		&"to_pile":
			man.set_pose(&"stand")
			if _walk(pile, delta):
				_carry_step = &"lift"
				_carry_t = 0.0
		&"lift":
			man.set_pose(&"crouch" if _carry_t < 0.9 else &"stand")
			_face(_pile_point(_pile_at, 0))
			var top := _top_sack()
			if top < 0:
				_pile_at = 1 - _pile_at  # the pile's all moved: back the other way
				_carry_step = &"to_pile"
				return
			var s := _sacks[top]
			if _carry_t < 0.9:
				_two_hands_on(s.global_position + Vector3.UP * 0.12, 1.0)
			else:
				_held = top
				_on_shoulder()
				_carry_step = &"carrying"
				_carry_t = 0.0
		&"carrying":
			man.set_pose(&"stand")
			_on_shoulder()
			if _walk(drop, delta):
				_carry_step = &"set_down"
				_carry_t = 0.0
		&"set_down":
			man.set_pose(&"crouch" if _carry_t < 0.9 else &"stand")
			_face(_pile_point(1 - _pile_at, 0))
			if _carry_t < 0.9:
				var at := _pile_point(1 - _pile_at, _count_at(1 - _pile_at))
				_sacks[_held].global_transform = Transform3D(Basis(Vector3.UP, float(_held) * 0.7), at)
				_two_hands_on(at + Vector3.UP * 0.12, 1.0)
			else:
				_held = -1
				strokes += 1
				_carry_step = &"to_pile"


func _talk(delta: float) -> void:
	man.set_pose(&"stand")
	var company := _company()
	# Nobody to talk with (#1230, #1213's fault: the other gone in, or not come yet): he waits and looks
	# about, no mouth going, no laugh at nobody; `alone_s` says how long (ValleyFolk moves a round on).
	if company.is_empty():
		alone_s += delta
		if _speech != null and _speech.speaking():
			_speech.hush()
		_face(faces)
		_look_about(0.8)
		return
	alone_s = 0.0
	var mid := faces
	if not company.is_empty():
		mid = Vector3.ZERO
		for c: HumanBody in company:
			mid += c.global_position
		mid /= company.size()
		mid.y = man.global_position.y + 1.5
	_face(mid)
	match doing:
		&"laugh":
			var k := _ease()
			_offset(&"head", Vector3(14.0 * k * (0.7 + 0.3 * sin(_t * 14.0)), 0, 0))
			_offset(&"chest", Vector3(5.0 * k, 0, 0))
			_mouth(0.0, "ha ha ha ha")
		&"nod":
			_offset(&"head", Vector3(-9.0 * absf(sin(_t * 3.0)), 0, 0))
		&"look_away":
			_look_about(1.0)
		_:
			var who: HumanBody = company[int(_t / 5.0) % company.size()] if not company.is_empty() else null
			if who != null:
				_turn_head_to(who.global_position + Vector3.UP * 1.6)
				_watch(who.global_position + Vector3.UP * 1.62)
			if _mouth(3.0) and fposmod(_t, 4.0) < 2.2:
				# A hand moving as he talks.
				var g := sin(_t * 2.3)
				_hand("r", Vector3(0.18 + 0.05 * g, 1.12 + 0.06 * sin(_t * 3.1), -0.32), Vector3.LEFT, 0.85, 0.4)
				_hands = true


func _drink(_delta: float) -> void:
	man.set_pose(&"stand")
	_face(faces)
	var top: Vector3 = spot.get("top", man.global_transform * Vector3(0, 1.08, -0.5))
	var fwd := _forward()
	var right := _right()
	var rest := Vector3(man.global_position.x, top.y, man.global_position.z) + fwd * 0.38 + right * 0.12
	if glass_up > 0.0:
		# A toast (the room's bit): the glass up before him, the other hand on the bar.
		var high := man.global_transform * Vector3(0.24, 1.84, -0.3)
		var at := rest.lerp(high, glass_up)
		_glass(at)
		_hand_w("r", at + Vector3.UP * 0.03, right, 1.0)
		man.curl_hand("r", 0.8)
		_hand_w("l", rest - right * 0.32, Vector3.UP, 1.0)
		return
	match doing:
		&"drink":
			# Up, a sip, down; a while between.
			var c := fposmod(_t, 5.5)
			var up := smoothstep(0.0, 0.9, c) * (1.0 - smoothstep(2.2, 3.1, c))
			if _stroke_was < 2.2 and c >= 2.2:
				strokes += 1
			_stroke_was = c
			var mouth := man.global_transform * Vector3(0.0, 1.55, -0.16)
			var at := rest.lerp(mouth, up)
			_glass(at)
			_hand_w("r", at + Vector3.UP * 0.03, right, 1.0)
			man.curl_hand("r", 0.8)
			_hand_w("l", rest - right * 0.32, Vector3.UP, 1.0)
			_offset(&"head", Vector3(14.0 * smoothstep(1.4, 2.0, c) * (1.0 - smoothstep(2.0, 2.6, c)), 0, 0))
			_watch(rest if up < 0.3 else Vector3.INF)
		&"forearms":
			_glass(rest)
			var k := minf(_t / 0.6, 1.0)
			_hand_w("l", rest - right * 0.3 - fwd * 0.08, Vector3.UP, k)
			_hand_w("r", rest + Vector3.UP * 0.03, right, k)
			_offset(&"chest", Vector3(-16.0 * k, 0, 0))
			_offset(&"abdomen", Vector3(-6.0 * k, 0, 0))
		&"turn_glass":
			var at := rest + Vector3.UP * 0.01
			_glass(at, _t * 1.5)
			_hand_w("r", at + Vector3.UP * 0.03, right, 1.0)
			man.curl_hand("r", 0.6 + 0.2 * sin(_t * 2.0))
			_watch(at)
		_:
			_glass(rest)
			_look_about(1.0)


func _work(_delta: float) -> void:
	man.set_pose(&"stand")
	_face(faces)
	var bench := String(spot.get("tool", "anvil")) == "bench"
	var fwd := _forward()
	var right := _right()
	var top := Vector3(man.global_position.x, man.global_position.y + (0.82 if bench else 0.62), man.global_position.z) + fwd * 0.55
	_place_tool_block(top, bench)
	match doing:
		&"work":
			if bench:
				# The plane pushed along the board and drawn back.
				var s := sin(_t * 1.9)
				var at := top + fwd * (0.12 * s) + Vector3.UP * 0.06
				_hand_w("r", at + right * 0.05, Vector3.UP, 1.0)
				_hand_w("l", at + fwd * 0.12 - right * 0.05, Vector3.UP, 1.0)
				_offset(&"chest", Vector3(-16.0 - 6.0 * s, 0, 0))
				if _stroke_was < 0.0 and s >= 0.0:
					strokes += 1
				_stroke_was = s
				_watch(at)
			else:
				# Hammer up, down on the iron; the tongs in his left on the anvil.
				var c := fposmod(_t * 1.4, 1.0)
				var lift := sin(c * PI) if c < 0.8 else 0.0
				var at := top + Vector3.UP * (0.05 + 0.5 * lift) + right * 0.08 - fwd * (0.15 * lift)
				_hand_w("r", at, Vector3.DOWN, 1.0)
				man.curl_hand("r", 0.85)
				_hand_w("l", top - right * 0.2 + Vector3.UP * 0.04, Vector3.UP, 1.0)
				man.curl_hand("l", 0.7)
				_offset(&"chest", Vector3(-10.0 + 6.0 * lift, 0, 0))
				if _stroke_was > 0.0 and lift == 0.0:
					strokes += 1
				_stroke_was = lift
				_watch(top)
		&"inspect":
			var k := _ease()
			_hand_w("l", top + Vector3.UP * (0.2 * k) - fwd * (0.2 * k), Vector3.RIGHT, 1.0)
			_offset(&"chest", Vector3(-18.0 * k, 0, 0))
			_offset(&"head", Vector3(-14.0 * k, 0, 0))
			_watch(top + Vector3.UP * 0.2 - fwd * 0.2)
		&"rub_shoulder":
			var k := _ease()
			var sh := man.global_transform * Vector3(0.17, 1.42 + 0.02 * sin(_t * 7.0), -0.02)
			_hand_w("l", sh, -right, k)
			_offset(&"head", Vector3(0, -12.0 * k, 8.0 * k))
		_:
			_wipe_brow()


# --- Bits of motion ---------------------------------------------------------------------------------

## A look up and down the street (or the room): his head (and his eyes, if he has a face) slowly round.
func _look_about(amount: float) -> void:
	var y := 38.0 * amount * sin(_t * 0.9 + float(man.rng_seed % 7))
	_offset(&"head", Vector3(-2.0, y, 0))
	if _life:
		var b := man.global_basis
		var look := man.global_position + Vector3.UP * 1.6 + (-b.z).rotated(Vector3.UP, deg_to_rad(y * 1.3)) * 6.0
		_life.attend_to(look)


func _turn_head_to(point: Vector3) -> void:
	var to := man.global_transform.affine_inverse() * point
	var y := rad_to_deg(atan2(-to.x, -to.z))
	_offset(&"head", Vector3(0, clampf(y, -60.0, 60.0), 0))


func _folded() -> void:
	var k := minf(_t / 0.7, 1.0) if doing != KINDS[kind].main else 1.0
	_two_hands(Vector3(-0.1, 1.13, -0.2), Vector3(0.1, 1.15, -0.21), Vector3.BACK, k, 0.0)


func _wipe_brow() -> void:
	var k := _ease()
	var at := Vector3(0.1 - 0.16 * fposmod(_t * 0.8, 1.0), 1.7, -0.14)
	_hand("r", at, Vector3.FORWARD, k, 0.4)
	_offset(&"head", Vector3(-6.0 * k, 0, 0))


## His mouth going, low (no words heard: the walla is sound's), every `gap` s or so; true while it is.
func _mouth(gap: float, text := "") -> bool:
	if _speech == null:
		return false
	if _brain != null and _brain.quiet > 0.0:
		if _speech.speaking():
			_speech.hush()  # the room's talk has dropped
		return false
	if not _speech.speaking() and (_t > _say_in or gap == 0.0):
		var lines := ["well I told him he could keep it", "that's what she said to me", "no sir not this year",
				"you know how it is with him", "come the spring we'll see", "I never heard the like"]
		_speech.say(text if text != "" else lines[_rng.randi() % lines.size()])
		_say_in = _t + gap * _rng.randf_range(0.8, 1.6)
	return _speech.speaking()


func _shake_rug() -> void:
	_face(faces)
	var fwd := _forward()
	var right := _right()
	var s := sin(_t * 11.0) * (0.5 + 0.5 * sin(_t * 0.8))
	if _stroke_was < 0.0 and s >= 0.0:
		strokes += 1
	_stroke_was = s
	var at := man.global_position + Vector3.UP * (1.2 + 0.09 * s) + fwd * 0.5
	_hand_w("l", at - right * 0.28, -fwd, 1.0)
	_hand_w("r", at + right * 0.28, -fwd, 1.0)
	man.curl_hand("l", 0.8)
	man.curl_hand("r", 0.8)
	_offset(&"chest", Vector3(-6.0, 0, 0))
	if _tool == null:
		_tool = _make_tool()
	var b := Basis.looking_at(Vector3.DOWN.lerp(fwd, 0.35 + 0.1 * s).normalized(), fwd)
	_tool.global_transform = Transform3D(b, at + Vector3.DOWN * 0.42 + fwd * 0.08)
	_tool.visible = true


# --- Hands --------------------------------------------------------------------------------------

## A hand to a point local to him (x right, y up, -z ahead), its palm toward -`n` (his), `k` of the
## way, eased in over `ease_in` s of the doing (0: at once).
func _hand(side: String, at: Vector3, n: Vector3, k := 1.0, ease_in := 0.0) -> void:
	_hand_w(side, man.global_transform * at, man.global_basis * n, k, ease_in)


## A hand to a world point.
func _hand_w(side: String, at: Vector3, n: Vector3, k := 1.0, ease_in := 0.0) -> void:
	if ease_in > 0.0:
		k *= minf(_t / ease_in, 1.0)
	if k <= 0.01:
		return
	man.reach_to(side, at, n, k)
	_hands = true


func _two_hands(l: Vector3, r: Vector3, n: Vector3, k := 1.0, ease_in := 0.0) -> void:
	_hand("l", l, n, k, ease_in)
	_hand("r", r, n, k, ease_in)


func _two_hands_on(at: Vector3, k: float) -> void:
	var right := _right()
	_hand_w("l", at - right * 0.2, Vector3.UP, k)
	_hand_w("r", at + right * 0.2, Vector3.UP, k)


func _watch(point: Vector3) -> void:
	if _life and point != Vector3.INF:
		_life.attend_to(point)


## In over the first half second of a doing, out over its last.
func _ease() -> float:
	return minf(_t / 0.5, 1.0) * clampf(_left / 0.5, 0.0, 1.0)


## Pose offsets he's given this tick; the ones not given ease off (and go when they're gone).
func _offset(seg: StringName, v: Vector3) -> void:
	_keys[seg] = Engine.get_physics_frames()
	var was: Vector3 = man.pose_offsets.get(seg, Vector3.ZERO)
	man.pose_offsets[seg] = was.lerp(v, 0.12)


func _tidy() -> void:
	var now := Engine.get_physics_frames()
	for k: StringName in _keys.keys():
		if int(_keys[k]) == now:
			continue
		var v: Vector3 = man.pose_offsets.get(k, Vector3.ZERO)
		v = v.lerp(Vector3.ZERO, 0.12)
		if v.length() < 0.2:
			man.pose_offsets.erase(k)
			_keys.erase(k)
		else:
			man.pose_offsets[k] = v


func _face(point: Vector3) -> void:
	if point != Vector3.INF:
		man.face(point)


func _forward() -> Vector3:
	var f := -man.global_basis.z
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func _right() -> Vector3:
	var r := man.global_basis.x
	r.y = 0.0
	return r.normalized() if r.length() > 0.01 else Vector3.RIGHT


## Along the walk (across his facing, flat).
func _street_side() -> Vector3:
	var f := faces - post if faces != Vector3.INF else -man.global_basis.z
	f.y = 0.0
	if f.length() < 0.01:
		return Vector3.RIGHT
	f = f.normalized()
	return Vector3(-f.z, 0.0, f.x)


func _walk(to: Vector3, delta: float) -> bool:
	var flat := Vector2(man.global_position.x - to.x, man.global_position.z - to.z)
	if flat.length() < 0.35:
		return true
	man.walk_to(to, CARRY_SPEED, delta)
	return false


# --- The world round him --------------------------------------------------------------------------

## The wall behind his spot (the side away from what he faces), or INF.
func _find_wall() -> Vector3:
	if not man.is_inside_tree():
		return Vector3.INF
	var back := post - faces
	back.y = 0.0
	if back.length() < 0.01:
		return Vector3.INF
	back = back.normalized()
	var from := post + Vector3.UP * 1.2
	var q := PhysicsRayQueryParameters3D.create(from, from + back * WALL_NEAR)
	q.collision_mask = Layers.WORLD
	var space := man.get_world_3d().direct_space_state
	var hit := space.intersect_ray(q) if space else {}
	return hit.position if not hit.is_empty() else Vector3.INF


## The nearest man across the counter from him (WipeBar's customer rule), or null.
func _customer() -> HumanBody:
	var best: HumanBody = null
	var best_d := CUSTOMER_NEAR
	var fwd := _forward()
	for n: Node in man.get_tree().get_nodes_in_group(&"people"):
		var h := n as HumanBody
		if h == null or h == man or not h.is_inside_tree() or h.limp:
			continue
		var to := h.global_position - man.global_position
		to.y = 0.0
		if to.dot(fwd) < 0.4:
			continue
		var d := to.length()
		if d < best_d:
			best = h
			best_d = d
	return best


## The others near him whose spot chore is `talk` (his company).
func _company() -> Array:
	var out := []
	for n: Node in man.get_tree().get_nodes_in_group(&"people"):
		var h := n as HumanBody
		if h == null or h == man or not h.is_inside_tree() or h.global_position.distance_to(man.global_position) > TALK_NEAR:
			continue
		var c := _chore_of(h)
		if c != null and c.kind == &"talk" and c._on:
			out.append(h)
	return out


func _nearest_doing(kinds: Array, within: float) -> HumanBody:
	for n: Node in man.get_tree().get_nodes_in_group(&"people"):
		var h := n as HumanBody
		if h == null or h == man or not h.is_inside_tree() or h.global_position.distance_to(man.global_position) > within:
			continue
		var c := _chore_of(h)
		if c != null and c.kind in kinds:
			return h
	return null


static func _chore_of(h: HumanBody) -> SpotChore:
	var b := h.get_node_or_null(^"Brain") as CivilianBrain
	if b == null:
		return null
	for c: RefCounted in b.chores:
		if c is SpotChore:
			return c
	return null


# --- Stand-ins (the prop lab's broom, sack, glass, anvil and bench to come) -----------------------

func _mesh(m: Mesh, colour: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	mi.material_override = mat
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	man.add_child(mi)
	return mi


func _make_tool() -> MeshInstance3D:
	match kind:
		&"sweep":
			if String(spot.get("tool", "")) == "rug":
				var r := BoxMesh.new()
				r.size = Vector3(0.7, 0.9, 0.01)
				return _mesh(r, Color(0.45, 0.2, 0.15))
			var b := CylinderMesh.new()
			b.top_radius = 0.014
			b.bottom_radius = 0.014
			b.height = 1.3
			var broom := _mesh(b, Color(0.55, 0.45, 0.3))
			var head := MeshInstance3D.new()
			var hb := BoxMesh.new()
			hb.size = Vector3(0.28, 0.24, 0.06)
			head.mesh = hb
			head.position = Vector3(0, -0.72, 0)
			var hm := StandardMaterial3D.new()
			hm.albedo_color = Color(0.72, 0.62, 0.38)
			head.material_override = hm
			broom.add_child(head)
			return broom
		&"drink":
			var g := CylinderMesh.new()
			g.top_radius = 0.03
			g.bottom_radius = 0.026
			g.height = 0.08
			return _mesh(g, Color(0.7, 0.62, 0.45, 1.0))
		_:
			var w := BoxMesh.new()
			if String(spot.get("tool", "anvil")) == "bench":
				w.size = Vector3(0.5, 0.82, 1.6)
				return _mesh(w, Color(0.5, 0.38, 0.25))
			w.size = Vector3(0.3, 0.62, 0.5)
			return _mesh(w, Color(0.18, 0.18, 0.2))


func _sack() -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = Vector3(0.42, 0.22, 0.62)
	return _mesh(b, Color(0.62, 0.55, 0.4))


## The broom's foot at `foot`, its handle up to his hands, his hands on it.
func _hold_broom(foot: Vector3) -> void:
	if _tool == null:
		return
	var top := man.global_transform * Vector3(-0.06, 1.1, -0.28)
	var along := (top - foot).normalized()
	var mid := foot + along * 0.72
	_tool.global_transform = Transform3D(_basis_up(along), mid)
	_tool.visible = true
	_hand_w("l", foot + along * 1.2, _right(), 1.0)
	_hand_w("r", foot + along * 0.8, -_right(), 1.0)
	man.curl_hand("l", 0.75)
	man.curl_hand("r", 0.75)


## Stood up before him, both hands on the top of the handle.
func _broom_upright(foot: Vector3) -> void:
	if _tool == null:
		return
	var along := Vector3.UP.lerp(-_forward(), -0.1).normalized()
	_tool.global_transform = Transform3D(_basis_up(along), foot + along * 0.72)
	_tool.visible = true
	_two_hands_on(foot + along * 1.32 - Vector3.UP * 0.2, 1.0)
	man.curl_hand("l", 0.7)
	man.curl_hand("r", 0.7)


func _basis_up(up: Vector3) -> Basis:
	var x := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	return Basis(x, up, x.cross(up))


func _glass(at: Vector3, turn := 0.0) -> void:
	if _tool == null:
		return
	_tool.global_transform = Transform3D(Basis(Vector3.UP, turn), at + Vector3.UP * 0.04)
	_tool.visible = true


func _place_tool_block(top: Vector3, bench: bool) -> void:
	if _tool == null:
		return
	if _tool.has_meta(&"placed"):
		return
	_tool.set_meta(&"placed", true)
	var h := 0.82 if bench else 0.62
	_tool.global_transform = Transform3D(Basis.looking_at(_forward()), Vector3(top.x, top.y - h * 0.5, top.z) + _forward() * (0.25 if bench else 0.1))


func _on_shoulder() -> void:
	if _held < 0:
		return
	var at := man.global_transform * Vector3(0.12, 1.62, 0.02)
	_sacks[_held].global_transform = Transform3D(man.global_basis, at)
	_hand("r", Vector3(0.17, 1.62, -0.12), Vector3.DOWN, 1.0)
	_hand("l", Vector3(0.02, 1.58, -0.18), Vector3.DOWN, 1.0)


func _to_at() -> Vector3:
	return spot.get("to_at", post + _street_side() * 3.0)


func _pile_point(end: int, i: int) -> Vector3:
	var base: Vector3 = (post if end == 0 else _to_at()) + _street_side() * 0.5 - _forward_of_spot() * 0.25
	return base + Vector3.UP * (0.11 + 0.22 * i)


func _forward_of_spot() -> Vector3:
	var f := faces - post
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3.FORWARD


func _lay_pile() -> void:
	for i in _sacks.size():
		_sacks[i].global_transform = Transform3D(Basis(Vector3.UP, float(i) * 0.7), _pile_point(0, i))
		_sacks[i].set_meta(&"end", 0)
	_pile_at = 0


func _count_at(end: int) -> int:
	var n := 0
	for s in _sacks:
		var p := _pile_point(end, 0)
		if Vector2(s.global_position.x - p.x, s.global_position.z - p.z).length() < 0.3 and (_held < 0 or s != _sacks[_held]):
			n += 1
	return n


func _top_sack() -> int:
	var best := -1
	var best_y := -INF
	var p := _pile_point(_pile_at, 0)
	for i in _sacks.size():
		var s := _sacks[i]
		if Vector2(s.global_position.x - p.x, s.global_position.z - p.z).length() < 0.3 and s.global_position.y > best_y:
			best = i
			best_y = s.global_position.y
	return best


## Trouble: what's in his hands goes down where he is (the broom on the boards, the sack at his feet).
func _drop() -> void:
	if _held >= 0 and _held < _sacks.size():
		_sacks[_held].global_transform = Transform3D(man.global_basis, man.global_position + _forward() * 0.45 + Vector3.UP * 0.11)
	_held = -1
	_carry_step = &"to_pile"
	if _tool != null and is_instance_valid(_tool) and kind == &"sweep":
		# The broom (or rug) on the boards before him.
		var along := _forward()
		_tool.global_transform = Transform3D(_basis_up(along), man.global_position + along * 0.7 + Vector3.UP * 0.05)
