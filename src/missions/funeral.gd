class_name Funeral
extends Act
## No Law, beat 6: the sheriff's funeral (#868; data config/moments/funeral.json, its _doc has the
## whole scene; the lines are docs/scripts/no_law.json's scene `funeral`). Quiet, not a set piece:
## the town gathered at the grave on the cemetery hill, heads bowed, the preacher's words, the box
## lowered, the Baron's offer to the widow and her refusal, his word to you, her thanks, and the
## town walking back to work. It plays whether you're there or not: nolaw.funeral = attended,
## distance or missed, by where you stood while it was said.
##
## Every mourner is a townsman in his own right (a CivilianBrain at a post by the grave, `mourn`
## his pose there), so a shot or a fire is his to mind as anywhere, and walking back to work is his
## brain's. They're ValleyFolk's men: the day folk sent up from their posts (`day`), the night's men
## borrowed while they're out of town (`borrow`), the scene's own (`take`: built with the folk);
## none is built in play. The box, the grave and the headboards are plain blocks (stand-ins).

const ATTENDED := "attended"
const DISTANCE := "distance"
const MISSED := "missed"

var folk: ValleyFolk
var grave: Vector3
## id -> HumanBody, how he came (take, borrow, day) and, for the day folk, the post he left.
var men := {}
var how := {}
var _old_post := {}
var _leaving := {}  # id -> seconds since he turned to go
var _go_at := {}  # id -> when he turns to go (one by one)
var _stays := {}
var coffin: Node3D
var boards: Array[Node3D] = []
var open_grave: Node3D
var earth: Node3D
var filled: Node3D
var _made: Array[Node] = []
var near_s := 0.0
var far_s := 0.0
var outcome := ""
var broken := false
var offer_heard := false
var heard: Array = []  # the beats you heard
var state_t := 0.0
var _beats: Array = []
var _beat := 0
var _next_t := 0.0
var _counting := false
var _lower := -1.0
var _walk: Array = []  # [id, to, give up at]
var _foreman_look := 0.0
var _stay_t := 0.0
var _called := false


func begin() -> void:
	folk = street.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if street else null
	if folk == null:
		_note("no folk")
		_finish(&"no_town")
		return
	folk.funeral = self
	if opts.get("set_up", false):
		_set_up()
	# The doctor's sick room cleared: his body's in the box now.
	var last := folk.sheriff_scene as SheriffDies
	if last != null and is_instance_valid(last):
		last.hand_over()
	var g: Array = data.get("grave", [-104.0, -197.0])
	grave = Vector3(float(g[0]), 0.0, float(g[1]))
	grave.y = folk.ground(grave.x, grave.z)
	_add_ways()
	_make_place()
	if opts.get("over", false):
		# The clock went past it unseen: buried without you.
		_fill()
		outcome = MISSED
		fact("nolaw.funeral", MISSED)
		_finish(&"done")
		return
	Events.shot_fired.connect(_on_shot)
	_gather()
	_go(&"gather")


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0
	_note("-> %s" % s)


func _pace() -> float:
	return clampf(float(opts.get("pace", 1.0)), 0.05, 4.0)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## A spot [east, south] of the grave's middle, on the ground (`up` over it).
func spot(xz: Array, up := 0.0) -> Vector3:
	var x := grave.x + float(xz[0])
	var z := grave.z + float(xz[1])
	return Vector3(x, folk.ground(x, z) + up, z)


# --- Setting it up ------------------------------------------------------------------------------

## `-- --mission=funeral` / the bridge's set_up: the sheriff died yesterday, you his deputy with his
## revolver, the clock at the funeral's hour, you on Church Lane below the church.
func _set_up() -> void:
	var c := clock()
	if c:
		c.day = maxi(c.day, 2)
		c.set_time(float(opts.get("hour", data.get("hour", 10.0))))
	var before := {"nolaw.murder": "done", "nolaw.morning": true, "nolaw.earl": "undertaker", "nolaw.accepted": "nod",
			"nolaw.deputy": true, "nolaw.revolver": "given", "nolaw.sheriff": "dead", "nolaw.acting": "doctor"}
	for k: String in before:
		if not StoryState.has_fact(k):
			StoryState.set_fact(k, before[k], (c.day - 1) if c else 1, 9.0)
	var p := player()
	if p:
		var s: Array = (data.get("you_start", {}) as Dictionary).get("at", [-64.0, -131.0])
		var at := Vector3(float(s[0]), folk.ground(float(s[0]), float(s[1])) + 0.1, float(s[1]))
		var g: Array = data.get("grave", [-104.0, -197.0])
		p.global_position = at
		p.velocity = Vector3.ZERO
		p.rotation.y = atan2(-(float(g[0]) - at.x), -(float(g[1]) - at.z))


## Church Lane and the graveside in the folk's places, once: the town's way up and back.
func _add_ways() -> void:
	var places := folk.places
	if places == null or places.has(&"funeral_lane_0"):
		return
	var town_names := places.points.keys()
	var prev := &""
	var i := 0
	for xz: Array in (data.get("lane", {}) as Dictionary).get("line", []):
		var at := Vector3(float(xz[0]), folk.ground(float(xz[0]), float(xz[1])) + 0.05, float(xz[1]))
		var n := StringName("funeral_lane_%d" % i)
		var links: Array = []
		if prev != &"":
			links.append(prev)
		else:
			var best := &""
			var best_d := INF
			for t: StringName in town_names:
				var d := (places.at(t) as Vector3).distance_to(at)
				if d < best_d:
					best_d = d
					best = t
			if best != &"":
				links.append(best)
		places.add(n, at, links)
		prev = n
		i += 1
	if prev != &"":
		places.add(&"funeral_grave", spot([0.0, 5.0], 0.05), [prev])


## Where a man leaving goes: down the lane to its foot behind town (the lane's `out` point).
func _way_out() -> Vector3:
	var n := StringName("funeral_lane_%d" % int((data.get("lane", {}) as Dictionary).get("out", 0)))
	return folk.places.at(n) if folk.places and folk.places.has(n) else spot([2.0, 30.0])


# --- The place: plain blocks (stand-ins) -----------------------------------------------------------

func _block(n: String, size: Vector3, at: Vector3, colour: Color, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = n
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 1.0
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
	street.add_child(body)
	body.global_position = at + Vector3.UP * size.y * 0.5
	_made.append(body)
	return body


func _make_place() -> void:
	var wood := Color(0.74, 0.62, 0.42)
	var old_wood := Color(0.42, 0.38, 0.33)
	var dirt := Color(0.33, 0.25, 0.18)
	# The graves already here: a low mound and a headboard each.
	var i := 0
	for xz: Array in data.get("old_graves", []):
		_block("OldGrave%d" % i, Vector3(1.9, 0.18, 0.75), spot(xz), dirt.lightened(0.08), false)
		_block("OldHeadboard%d" % i, Vector3(0.05, 0.75 + 0.1 * float(i % 3), 0.42), spot([float(xz[0]) - 1.1, float(xz[1])]), old_wood)
		i += 1
	# His: the hole (a dark patch: the ground isn't dug), the earth from it at its head, the box on
	# two boards across it.
	open_grave = _block("OpenGrave", Vector3(2.3, 0.02, 0.95), spot([0.0, 0.0]), Color(0.05, 0.04, 0.035), false)
	earth = _block("GraveEarth", Vector3(1.5, 0.28, 2.3), spot([-2.3, -0.1]), dirt)
	var heap := [[Vector3(1.0, 0.5, 1.6), Vector3(-0.1, 0.0, 0.2), 14.0], [Vector3(0.6, 0.72, 0.9), Vector3(0.05, 0.0, -0.3), -22.0], [Vector3(0.5, 0.4, 0.7), Vector3(-0.3, 0.0, 0.85), 31.0]]
	for h: Array in heap:
		var lump := _block("EarthLump", h[0], earth.global_position + (h[1] as Vector3) - Vector3.UP * 0.14, dirt.darkened(0.12 * float(heap.find(h))), false)
		lump.rotation.y = deg_to_rad(float(h[2]))
		lump.reparent(earth)
	# The gravedigger's spade stood in it.
	var spade := _block("Spade", Vector3(0.035, 1.25, 0.035), earth.global_position + Vector3(0.45, 0.0, 0.5), old_wood, false)
	spade.rotation.z = deg_to_rad(-9.0)
	spade.reparent(earth)
	for bx: float in [-0.7, 0.7]:
		boards.append(_block("GraveBoard", Vector3(0.18, 0.04, 1.5), spot([bx, 0.0], 0.02), old_wood, false))
	coffin = _block("PineBox", Vector3(1.95, 0.4, 0.6), spot([0.0, 0.0], 0.06), wood)
	# After: the earth back over him and a new board.
	filled = Node3D.new()
	filled.name = "SheriffsGrave"
	street.add_child(filled)
	_made.append(filled)
	var mound := _block("Mound", Vector3(2.2, 0.3, 0.95), spot([0.0, 0.0]), dirt, false)
	var board := _block("Headboard", Vector3(0.05, 0.95, 0.48), spot([-1.3, 0.0]), wood)
	for n: Node3D in [mound, board]:
		n.reparent(filled)
	filled.visible = false
	(board as StaticBody3D).process_mode = Node.PROCESS_MODE_DISABLED


## Buried: the box and the hole gone, the mound and his headboard.
func _fill() -> void:
	var gone: Array = [coffin, open_grave, earth]
	gone.append_array(boards)
	for n: Node3D in gone:
		if n != null and is_instance_valid(n):
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
	if filled and is_instance_valid(filled):
		filled.visible = true
		for c: Node in filled.get_children():
			c.process_mode = Node.PROCESS_MODE_INHERIT
	_note("the grave's filled")


# --- The mourners ---------------------------------------------------------------------------------

func _gather() -> void:
	var look := grave + Vector3.UP * 0.3
	for m: Dictionary in data.get("mourners", []):
		var id := StringName(m.id)
		var at := spot(m.spot, 0.05)
		var kind := String(m.get("how", "take"))
		var man: HumanBody = null
		var brain: CivilianBrain = null
		if kind == "day":
			man = folk.folk_man(id)
			if man == null or not man.physiology.is_conscious() or not folk.state.get(id) in [&"in", &"coming"]:
				continue
			brain = man.get_node_or_null(^"Brain") as CivilianBrain
			if brain == null:
				continue
			_old_post[id] = [brain.post, brain.faces]
			folk.state[id] = &"act"
			if folk._you_see(man.global_position, 80.0):
				# You'd see him vanish: he walks up, with a word as he goes.
				if not _called:
					_called = true
					_say(man, line("its_time"), 8.0)
			else:
				man.global_position = at
		else:
			man = folk.folk_man(id)
			if man == null:
				man = folk.take(id, at, look) if kind == "take" else folk.borrow(id, at, look)
			elif folk.state.get(id) == &"act":
				man.global_position = at  # the last scene's (his wife, the doctor): here now
			else:
				continue  # in town on his own hours: left be
			if man == null:
				_note("no %s" % id)
				continue
			man.set_pose(&"stand")
			brain = man.get_node_or_null(^"Brain") as CivilianBrain
			if brain == null:
				brain = CivilianBrain.new()
				brain.name = "Brain"
				brain.places = folk.places
				brain.fights_fire = false
				man.add_child(brain)
				man.move_child(brain, 0)
		brain.go_to(at, look)
		brain.rest_pose = StringName(m.get("pose", "mourn"))
		_hat(man, false)
		men[id] = man
		how[id] = kind
		if m.get("stays", false):
			_stays[id] = true
	_note("gathered: %d" % men.size())


## His hat off at the grave (hidden: there's no hat in the hand yet), and on again as he goes.
static func _hat(m: HumanBody, on: bool) -> void:
	for piece: MeshInstance3D in m._hat_pieces():
		piece.visible = on


func man(id: StringName) -> HumanBody:
	var m: HumanBody = men.get(id)
	return m if m != null and is_instance_valid(m) else null


func _brain(id: StringName) -> CivilianBrain:
	var m := man(id)
	return m.get_node_or_null(^"Brain") as CivilianBrain if m else null


## He turns for home: the day folk back to their posts, the rest down the lane and out.
func _leave(id: StringName) -> void:
	if _leaving.has(id):
		return
	var brain := _brain(id)
	if brain == null:
		return
	brain.rest_pose = &"stand"
	_hat(man(id), true)
	if how.get(id) == "day":
		var old: Array = _old_post.get(id, [])
		if old.size() == 2:
			brain.go_to(old[0], old[1])
		if folk.state.get(id) == &"act":
			folk.state[id] = &"coming"
		men.erase(id)
		return
	brain.go_to(_way_out())
	_leaving[id] = 0.0


## Out of the world, back to wait with the folk (not freed: his own hours come round again).
func _put_away(id: StringName) -> void:
	var m := man(id)
	men.erase(id)
	_leaving.erase(id)
	if m == null or how.get(id) == "day":
		return
	_hat(m, true)
	if folk.state.get(id) == &"act":
		folk.give_back(id)


# --- The tick -------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	state_t += delta
	card_step(delta)
	var p := player()
	_leaving_step(p, delta)
	if _lower >= 0.0:
		_lower_step(delta)
	if done:
		_stay_step(p, delta)
		_fill_step(p)
		return
	if p == null:
		return
	if _counting:
		_count(p, delta)
	_foreman_step(delta)
	match state:
		&"gather":
			var near := _flat(p.global_position, grave) < float(data.get("start_m", 16.0))
			if state_t > float(data.get("gather_min_s", 6.0)) * _pace() and (near or state_t > float(data.get("gather_s", 150.0)) * _pace()):
				_beats = [["say", "prayer"], ["do", "lower"], ["say", "commit"], ["do", "lowered"], ["say", "amen"], ["say", "town_1"], ["say", "town_2"], ["walk", "baron"],
						["say", "offer"], ["say", "refuse"], ["do", "tally"], ["do", "baron_out"], ["say", "baron_you"],
						["do", "baron_gone"], ["say", "you_came"], ["do", "to_grave"], ["do", "end"]]
				_beat = 0
				_next_t = t + 1.5 * _pace()
				_counting = true
				_go(&"service")
		&"service":
			_service_step(p)
		&"broken":
			if state_t > 5.0:
				_tally()
				_end()


## Where you stood while it was said: near the grave, or off where they could see you.
func _count(p: Player, delta: float) -> void:
	var d := _flat(p.global_position, grave)
	if d < float(data.get("attend_m", 12.0)):
		near_s += delta
	elif d < float(data.get("seen_m", 90.0)) and _in_sight(p.global_position):
		far_s += delta


## The hill isn't between you and the grave (the ground's heights along the line; not buildings).
func _in_sight(from: Vector3) -> bool:
	var a := from + Vector3.UP * 1.6
	var b := grave + Vector3.UP * 1.6
	for i in range(1, 12):
		var q := a.lerp(b, float(i) / 12.0)
		if folk.ground(q.x, q.z) > q.y:
			return false
	return true


func _service_step(p: Player) -> void:
	if not _walk.is_empty():
		var w := man(_walk[0])
		if w != null and _flat(w.global_position, _walk[1]) > 0.8 and t < float(_walk[2]):
			return
		_walk.clear()
		_next_t = t + 0.8
	if t < _next_t or _beat >= _beats.size():
		return
	var b: Array = _beats[_beat]
	_beat += 1
	var what := String(b[1])
	match String(b[0]):
		"say":
			var who := man(StringName((data.get("speakers", {}) as Dictionary).get(what, "")))
			if what in ["baron_you", "you_came"] and (outcome != ATTENDED or who == null or _flat(p.global_position, who.global_position) > float(data.get("prayer_m", 25.0))):
				return  # for the one who came
			if who == null or not who.physiology.is_conscious():
				return
			var text := line(what)
			if what in ["baron_you", "you_came"]:
				var br := who.get_node_or_null(^"Brain") as CivilianBrain
				if br:
					br.faces = p.global_position + Vector3.UP * 1.5
					br.rest_pose = &"stand"
			var did := _say(who, text, float(data.get("prayer_m" if what in ["prayer", "commit", "amen"] else "hear_m", 12.0)))
			if did:
				heard.append(what)
			if what == "offer":
				offer_heard = did
			if what == "baron_you" and did:
				fact("baron.met", true)
			_next_t = t + maxf(float(data.get("gap_min_s", 3.0)), float(text.length()) / float(data.get("cps", 13.0)) + 1.0) * _pace()
		"walk":
			var id := StringName(what)
			var br := _brain(id)
			var w := man(StringName((data.get("speakers", {}) as Dictionary).get("refuse", "wife")))
			if br:
				var to := spot(data.get("baron_to", [1.5, -2.9]), 0.05)
				br.rest_pose = &"stand"
				br.go_to(to, (w.global_position + Vector3.UP * 1.5) if w else grave)
				_walk = [id, to, t + float(data.get("walk_wait_s", 25.0))]
		"do":
			_do(what, p)


func _do(what: String, p: Player) -> void:
	match what:
		"lower":
			for bd: Node3D in boards:
				bd.visible = false
			_lower = 0.0
			_next_t = t + 1.5 * _pace()
		"lowered":
			# (The words are said as it goes down; on when it's down.)
			_next_t = maxf(_next_t, t + maxf(float(data.get("lower_s", 8.0)) * _pace() - _lower, 0.0) + 1.0 * _pace()) if _lower >= 0.0 else _next_t
		"to_grave":
			# Her thanks said, she turns back to him.
			for id: StringName in _stays.keys():
				var sb := _brain(id)
				if sb:
					sb.faces = grave + Vector3.UP * 0.3
					sb.rest_pose = &"mourn" if id != &"preacher" else &"stand"
		"tally":
			_tally()
		"baron_out":
			# He goes; by you if you came, close enough for his word.
			var br := _brain(&"baron")
			var b := man(&"baron")
			if br == null or b == null:
				return
			if outcome == ATTENDED and _flat(p.global_position, b.global_position) < float(data.get("prayer_m", 25.0)):
				var to := p.global_position + (b.global_position - p.global_position).normalized() * 2.0
				to.y = folk.ground(to.x, to.z) + 0.05
				br.go_to(to, p.global_position + Vector3.UP * 1.5)
				_walk = [&"baron", to, t + 12.0]
			else:
				_leave(&"baron")
				_leave(&"foreman")
		"baron_gone":
			_leave(&"baron")
			_leave(&"foreman")
		"end":
			_end()


## The fact, once: by where you stood.
func _tally() -> void:
	if outcome != "":
		return
	_counting = false
	var need := float(data.get("attend_s", 5.0)) * _pace()
	outcome = ATTENDED if near_s >= need else (DISTANCE if near_s + far_s >= need else MISSED)
	fact("nolaw.funeral", outcome)
	fact("nolaw.offer_heard", offer_heard)
	if broken:
		fact("nolaw.funeral_broken", true)


## Over: the town walks back to work; the widow, the doctor and the preacher stay by the grave.
func _end() -> void:
	var k := 0
	for id: StringName in men.keys():
		if not _stays.has(id) and not _leaving.has(id):
			# One by one, not as a body.
			_go_at[id] = t + float(k) * float(data.get("leave_gap_s", 1.6)) * (0.6 + 0.8 * fposmod(float(k) * 0.618, 1.0))
			k += 1
	if Events.shot_fired.is_connected(_on_shot):
		Events.shot_fired.disconnect(_on_shot)
	_finish(&"done")


## The box down into the hole.
func _lower_step(delta: float) -> void:
	var over := float(data.get("lower_s", 8.0)) * _pace()
	_lower += delta
	if coffin and is_instance_valid(coffin):
		coffin.global_position.y -= 0.75 * delta / over
		if _lower >= over:
			coffin.visible = false
			coffin.process_mode = Node.PROCESS_MODE_DISABLED
	if _lower >= over:
		_lower = -1.0


## The foreman keeps a step behind the Baron, and says nothing.
func _foreman_step(delta: float) -> void:
	_foreman_look -= delta
	if _foreman_look > 0.0 or _leaving.has(&"foreman"):
		return
	_foreman_look = 0.5
	var b := man(&"baron")
	var fb := _brain(&"foreman")
	if b == null or fb == null:
		return
	if _leaving.has(&"baron"):
		_leave(&"foreman")
		return
	var back := (b.global_position - grave)
	back.y = 0.0
	var to := b.global_position + back.normalized() * 1.4 + Vector3(0.6, 0.0, 0.0)
	if _flat(to, fb.post) > 0.6:
		to.y = folk.ground(to.x, to.z) + 0.05
		fb.go_to(to, b.global_position + Vector3.UP * 1.5)


## Men on their way out: gone once they're off where you can't see them (or at the lane's foot, in
## town, or in time: never from under your eyes on the hill).
func _leaving_step(p: Player, delta: float) -> void:
	for id: StringName in _go_at.keys():
		if t >= float(_go_at[id]):
			_go_at.erase(id)
			_leave(id)
	if _leaving.is_empty():
		return
	var out := _way_out()
	for id: StringName in _leaving.keys():
		_leaving[id] += delta
		var m := man(id)
		if m == null:
			_leaving.erase(id)
			continue
		var unseen := p == null or not folk._you_see(m.global_position, 200.0)
		var far := unseen and (p == null or _flat(p.global_position, m.global_position) > float(data.get("gone_m", 45.0)))
		if (far and _leaving[id] > 3.0) or (_flat(m.global_position, out) < 2.0 and unseen) or _leaving[id] > float(data.get("gone_s", 240.0)):
			_put_away(id)


## After: those who stayed by the grave go once you've gone (or in time), and it's filled.
func _stay_step(p: Player, delta: float) -> void:
	if _stays.is_empty():
		return
	_stay_t += delta
	var away := p == null or _flat(p.global_position, grave) > float(data.get("stay_m", 40.0))
	if not away and _stay_t < float(data.get("stay_s", 180.0)) * _pace():
		return
	for id: StringName in _stays.keys():
		_leave(id)
	_stays.clear()
	_fill_when_unseen = true


var _fill_when_unseen := false


## Filled once they've gone and you're off the hill, not looking (nobody's seen shovelling: there's
## no sexton yet; stay and it stays open).
func _fill_step(p: Player) -> void:
	if not _fill_when_unseen or not _leaving.is_empty() or not _go_at.is_empty():
		return
	if p == null or (_flat(p.global_position, grave) > float(data.get("stay_m", 40.0)) and not folk._you_see(grave, 400.0)):
		_fill_when_unseen = false
		_fill()


## A shot by the grave: it's over; they scatter as townsfolk do, then go.
func _on_shot(origin: Vector3, _dir: Vector3, _shooter: Node) -> void:
	if done or broken or _flat(origin, grave) > float(data.get("break_m", 150.0)):
		return
	broken = true
	_walk.clear()
	_note("a shot: the funeral breaks up")
	_go(&"broken")


## Said, if you're near enough to hear it (`within` m of him); true if you heard.
func _say(who: HumanBody, text: String, within := 12.0) -> bool:
	if text == "" or who == null or not is_instance_valid(who):
		return false
	var p := player()
	var hears := p != null and p.global_position.distance_to(who.global_position) <= within
	if hears:
		speak(who, text)
	_note("%s%s: %s" % [who.person_id, "" if hears else " (unheard)", text])
	return hears


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"outcome": outcome, "near_s": snappedf(near_s, 0.1), "far_s": snappedf(far_s, 0.1), "broken": broken,
			"heard": heard, "beat": _beat, "mourners": men.size(), "leaving": _leaving.size(),
			"grave": [snappedf(grave.x, 0.1), snappedf(grave.y, 0.1), snappedf(grave.z, 0.1)],
			"filled": filled != null and is_instance_valid(filled) and filled.visible}
	var p := player()
	if p:
		r["you_to_grave_m"] = snappedf(_flat(p.global_position, grave), 0.1)
		r["in_sight"] = _in_sight(p.global_position)
	var at := {}
	for id: StringName in men:
		var m := man(id)
		if m:
			at[String(id)] = [snappedf(m.global_position.x - grave.x, 0.1), snappedf(m.global_position.z - grave.z, 0.1), String(m.pose)]
	r["men"] = at
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-16)
	return r


## Take back its men and blocks (the bridge, the tests).
func reset() -> void:
	if Events.shot_fired.is_connected(_on_shot):
		Events.shot_fired.disconnect(_on_shot)
	if folk and is_instance_valid(folk):
		for id: StringName in men.keys():
			if how.get(id) == "day":
				_leave(id)
			else:
				_put_away(id)
		if folk.funeral == self:
			folk.funeral = null
	for n: Node in _made:
		if is_instance_valid(n):
			n.queue_free()
	queue_free()
