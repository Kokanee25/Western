class_name CoachFight
extends Node
## The coach heist after the hit (#815): the Baron's guards come out of the wreck fighting, and the
## strongbox is taken. Made by CoachCut with the coach; it starts when the ram's blow hands the coach
## to physics (CoachDrive.handed_off).
##
## - **Dazed:** each man thrown about lies dazed (CoachFightTuning: a seeded few seconds, longer for
##   each hard knock on his head, OutlawBrain.head_stun_seconds), some of them hurt worse by the
##   throw (a seeded blow to a limb, HumanBody.take_blow). Their nerve is seeded from the same
##   hit: less for each knock and for being hurt.
## - **Out of the wreck:** once it's settled, the door on top (it lies on its side: the one facing
##   the sky; still standing, the one away from the ram) is swung open. One man at a time gets up
##   inside under it (his limp body moved under the door first, out of sight, then HumanBody.get_up).
##   The first up stands on the bench's end in the open door, his shoulders over the edge (an
##   OutlawBrain order, a window: up to shoot, down under fire); the others climb out through it and
##   down the far side (a scripted climb: crouched up, over, down), then fight from their own cover.
## - **The box's two** (the driver and the messenger, thrown onto the road) get up where they lie;
##   the messenger makes for the outcrop opposite and fights from it, the driver from his own cover.
## - Each is an OutlawBrain holding the cut (`hold`: cover and hunting only within `fight_reach` of
##   the cut's middle and off the ram's bank), in the fight from the start, dazed a moment
##   (`caught_cold`).
## - **The strongbox** lies loose inside: E held at the door hauls it out onto the road, standing
##   (a fresh kit prop: the loose one's members are rubble). The padlock breaks to a ball (the kit's
##   `shot_breaks`); unlocked, E held opens the lid and takes the papers; locked, E held shoulders
##   the box (44 kg: you walk at `box_pace`; E again sets it down).
## - **Won:** the papers or the box, and you up the rimrock trail (it leaves the South Road 40 m on).
##   **Lost:** you're down, the coach got by (not struck), or you left without them. Either way a
##   line on screen; Enter tries again from the high spot (`CoachCut.start_on_load`, GameReset).
##   StoryState: `coach.outcome`, `coach.took`, `coach.guards_alive`, `coach.dead`, `coach.driver`,
##   `coach.messenger`.

enum State {WAITING, ON, WON, LOST}

var tuning: CoachFightTuning
var cut: CoachCut
var state := State.WAITING
var t := 0.0
var hit_t := -1.0
var settled_t := -1.0
var end_t := -1.0
var outcome := &""
var why := ""
var timeline: Array = []
## The hit's seed: the daze, the nerve and who's hurt.
var seed_value := 815
## Each man: {man, role (&"inside" / &"box"), id, knocks [J], hurt, daze, wake_at, nerve, temper,
## leads, phase (&"seated", &"dazed", &"rising", &"climbing", &"hatch", &"fighting", &"out"), brain}.
var men: Array[Dictionary] = []
## The coach as it lies: its heaviest body, and the coach's own space in it (`at_coach`).
var body: RigidBody3D
var _rel := Transform3D.IDENTITY
var over := false
## The door they come out by ("door_l" / "door_r"), its side (-1 l, +1 r: the coach's z), where its
## opening's middle is (world), the floor under it inside, the far side's ground (the lee).
var door := ""
var door_side := 1.0
var hatch_top := Vector3.INF
var floor_y := 0.0
var lee_dir := Vector3.ZERO
var hatch_man: Dictionary = {}
var _climbing := false
var _settle_still := 0.0
var _step: StaticBody3D

## The strongbox: &"in" (loose in the coach), &"out" (standing by it, shut), &"open" (its lid up,
## the papers in it), &"taken" (the papers yours), &"carried" (on your shoulder).
var box_state := &"in"
var box: KitProp
var took := ""
var _hold := 0.0
var _was_held := false
var _prompt := 0.0
var _retry_hold := 0.0
var _player: Player
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "CoachFight"


func _ready() -> void:
	if tuning == null:
		tuning = load("res://config/coach_fight.tres")
	add_to_group(&"claims_use")
	add_to_group(&"coach_fight")
	process_physics_priority = 50  # after the brains and the bodies: the climb's place is the last word
	Events.shot_fired.connect(_count_shot)


## Shots fired after the hit: by the guards, by you.
var shots_men := 0
var shots_you := 0


func _count_shot(_o: Vector3, _d: Vector3, shooter: Node) -> void:
	if state != State.ON:
		return
	if shooter is Player:
		shots_you += 1
	elif men.any(func(g: Dictionary) -> bool: return g.man == shooter):
		shots_men += 1


static func of(tree: SceneTree) -> CoachFight:
	return tree.get_first_node_in_group(&"coach_fight") as CoachFight


func player() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


## The coach's riders, as CoachCut seats them: their head knocks are counted from now.
func add_man(man: HumanBody, role: StringName) -> void:
	var g := {"man": man, "role": role, "id": String(man.person_id), "knocks": [], "hurt": "", "daze": 0.0,
			"wake_at": INF, "nerve": 0.75, "temper": 0.4, "leads": false, "phase": &"seated", "brain": null}
	men.append(g)
	man.hit.connect(func(info: Dictionary) -> void:
		if hit_t >= 0.0 and info.get("kind") == &"blow" and info.get("segment") == &"head":
			var s := OutlawBrain.head_stun_seconds(info)
			if s > 0.0:
				(g.knocks as Array).append(snappedf(float(info.get("joules", 0.0)), 0.1)))
	man.died.connect(func(c: StringName) -> void: _note("%s dead (%s)" % [g.id, c]))


## The ram's blow: the coach is physics now, its men thrown. Their daze and nerve from the seed.
func on_hit(bodies: Array) -> void:
	if hit_t >= 0.0:
		return
	hit_t = t
	state = State.ON
	_rng.seed = seed_value * 7919 + 13
	body = null
	for rb: Variant in bodies:
		if rb is RigidBody3D and is_instance_valid(rb) and (body == null or (rb as RigidBody3D).mass > body.mass):
			body = rb
	if body:
		_rel = body.global_transform.affine_inverse() * cut.coach.global_transform
	for g in men:
		var box_man: bool = g.role == &"box"
		var d := tuning.daze_min + _rng.randf() * tuning.daze_spread
		g.daze = d * (tuning.box_daze_share if box_man else 1.0)
		g.nerve = lerpf(tuning.nerve_min, tuning.nerve_max, _rng.randf())
		g.temper = _rng.randf_range(0.25, 0.65)
		g.leads = tuning.messenger_leads and g.id == "messenger"
		g.phase = &"dazed"
		if _rng.randf() < tuning.hurt_chance:
			var parts := [&"forearm_l", &"thigh_r", &"shin_l", &"upper_arm_r", &"chest"]
			g.hurt = String(parts[_rng.randi() % parts.size()])
			g.hurt_j = lerpf(tuning.hurt_joules_min, tuning.hurt_joules_max, _rng.randf())
	_note("hit")
	_hurt_soon.call_deferred()


## A tick on (each has gone limp by then, CoachDrive's queue): the worse knocks the seed gave.
func _hurt_soon() -> void:
	for i in 30:
		await get_tree().physics_frame
	for g in men:
		var man := g.man as HumanBody
		if g.hurt == "" or not is_instance_valid(man) or man.parts == null:
			continue
		var part := man.parts.get(StringName(g.hurt)) as Node3D
		if part == null:
			continue
		var res := man.take_blow(part, float(g.hurt_j), part.global_position, Vector3.DOWN)
		g.hurt_what = Array(res)
		_note("%s hurt: %s %.0f J %s" % [g.id, g.hurt, g.hurt_j, res])


## A point in the coach's own space (its kit file's) where it is now.
func at_coach(local: Vector3) -> Vector3:
	if body == null or not is_instance_valid(body):
		return cut.coach.global_transform * local
	return body.global_transform * _rel * local


func coach_basis() -> Basis:
	if body == null or not is_instance_valid(body):
		return cut.coach.global_basis
	return (body.global_basis * _rel.basis).orthonormalized()


## Is `p` (world) inside the coach's box as it lies?
func in_coach(p: Vector3) -> bool:
	var l := (body.global_transform * _rel).affine_inverse() * p if body and is_instance_valid(body) else cut.coach.to_local(p)
	return absf(l.x) < 1.32 and l.y > 1.0 and l.y < 2.5 and absf(l.z) < 0.72


func _physics_process(delta: float) -> void:
	t += delta
	if cut == null:
		return
	if t <= delta * 1.5 and cut.is_inside_tree():
		# Sight takes what's new in the world at its next question (the whole valley, if nobody's
		# asked one yet: ~80 ms here): asked now, at the start, not on the first guard's look.
		Sight.ray(cut, cut.middle + Vector3.UP * 30.0, cut.middle + Vector3.UP * 30.1, Layers.WORLD)
	if state == State.WAITING:
		_got_by()
		return
	if settled_t < 0.0:
		_settle_watch(delta)
	else:
		for g in men:
			_man_step(g, delta)
	if state == State.ON:
		_use_step(delta)
		_check_end()
	_retry_step(delta)


## The coach driven on past the ram, not struck: it got by.
func _got_by() -> void:
	var p := player()
	if cut.drive and cut.drive.driving and cut.coach and is_instance_valid(cut.coach):
		var past := (cut.coach.global_position - cut.middle).dot(cut.road_dir)
		if past > tuning.got_by:
			state = State.ON
			_lose(&"got_by", "The coach got by. The Baron's papers are on their way to his ranch.")
	elif p and p.wounds and not p.wounds.physiology.is_conscious():
		state = State.ON
		_lose(&"you_down", "You're down.")


# --- The wreck settles -----------------------------------------------------------------------------

func _settle_watch(delta: float) -> void:
	if body == null or not is_instance_valid(body):
		return
	var still := body.linear_velocity.length() < 0.25 and body.angular_velocity.length() < 0.35
	_settle_still = _settle_still + delta if still else 0.0
	if _settle_still >= 0.5 or t - hit_t > 8.0:
		settled_t = t
		_take_the_lie()


## How it lies: over (a door to the sky) or standing; the door they come out by, opened.
func _take_the_lie() -> void:
	var b := coach_basis()
	var up_l := (b * Vector3(0, 0, -1)).y
	over = absf(up_l) > 0.6
	var hi := _high_spot()
	var mid := at_coach(Vector3(0, 1.75, 0))
	lee_dir = mid - hi
	lee_dir.y = 0.0
	lee_dir = lee_dir.normalized()
	if over:
		door_side = -1.0 if up_l > 0.0 else 1.0
	else:
		# Standing: the door away from the ram.
		door_side = -1.0 if (b * Vector3(0, 0, -1)).dot(lee_dir) > 0.0 else 1.0
	door = "door_l" if door_side < 0.0 else "door_r"
	hatch_top = at_coach(Vector3(0, 1.75, 0.708 * door_side))
	_open_door()
	if over:
		var q := PhysicsRayQueryParameters3D.create(mid + Vector3.UP * 0.05, mid + Vector3.DOWN * 1.5, Layers.WORLD)
		var hit := World.space(cut).intersect_ray(q)
		floor_y = (hit.position as Vector3).y if not hit.is_empty() else mid.y - 0.7
	else:
		floor_y = at_coach(Vector3(0, 1.105, 0)).y
	# Sight takes the wreck's ~180 shapes at its next question: ask one now, while all's quiet,
	# not on the first guard's first look (a 70 ms tick here).
	Sight.ray(cut, mid + Vector3.UP * 3.0, mid + Vector3.UP * 3.1, Layers.WORLD)
	_note("settled: %s, %s up, lean %.0f" % ["over" if over else "standing", door, cut.drive.lean() if cut.drive else 0.0])


## The coach's high spot (where you shoot the pin from), or the ram's bank over the road.
func _high_spot() -> Vector3:
	var hi: Array = cut.layout.height(CoachCut.CUT).get("high", {}).get("at", []) if cut.layout else []
	if hi.size() >= 2:
		var at := Vector3(float(hi[0]), 0.0, float(hi[1]))
		at.y = float(cut.height_at.call(at.x, at.z)) + 1.6
		return at
	return cut.middle + cut.side * 12.0 + Vector3.UP * 8.0


## Swing the door open on the wreck: its members' shapes and meshes turned about its hinge in the
## body (KitProp.open_hinge won't: it's rubble now).
func _open_door() -> void:
	var h: Dictionary = cut.coach.definition.get("hinges", {}).get(door, {})
	if h.is_empty() or body == null:
		return
	var a := _rel * PropKit.vec(h.axis[0])
	var bb := _rel * PropKit.vec(h.axis[1])
	var deg := float(h.get("open", 90.0))
	var about := Transform3D(Basis(), a) * Transform3D(Basis((bb - a).normalized(), deg_to_rad(deg)), Vector3.ZERO) \
			* Transform3D(Basis(), -a)
	var ids := {}
	for id: String in h.get("members", []):
		ids[StringName("%s/%s" % [cut.coach.structure_id, id])] = true
	for c in body.get_children():
		if c is Node3D and ids.has(c.get_meta(&"member", &"")):
			(c as Node3D).transform = about * (c as Node3D).transform
	Sight.shapes_moved(body)


# --- The men ---------------------------------------------------------------------------------------

func _man_step(g: Dictionary, delta: float) -> void:
	var man := g.man as HumanBody
	if not is_instance_valid(man):
		g.phase = &"out"
		return
	if not man.physiology.alive and g.phase != &"out":
		g.phase = &"out"
		_note("%s out (dead)" % g.id)
		if hatch_man == g:
			hatch_man = {}
		return
	match g.phase:
		&"dazed":
			if t - hit_t < float(g.daze) + _knock_daze(g) or not man.limp:
				return
			if not man.physiology.is_conscious() or not man.physiology.can_stand():
				return  # (out cold, or his legs won't: he lies where he is)
			if g.role == &"inside" and in_coach(_pelvis(man)):
				if _climbing or (not hatch_man.is_empty() and hatch_man.phase == &"rising"):
					return  # one at a time under the door
				var to := _hatch_floor(not hatch_man.is_empty() or not over or not man.physiology.can_hold("r"))
				_shift_ragdoll(man, to)
			man.get_up()
			if man.rising:
				g.phase = &"rising"
				g.rise_t = t
				if g.role == &"inside" and hatch_man.is_empty() and over and in_coach(_pelvis(man)) and man.physiology.can_hold("r"):
					hatch_man = g
				elif g.role == &"inside":
					_climbing = true
				_note("%s getting up" % g.id)
		&"rising":
			if man.limp and not man.rising:
				g.phase = &"dazed"  # down again (shot as he rose)
				if hatch_man == g:
					hatch_man = {}
				_climbing = false
				return
			if man.rising:
				return
			if g.role == &"inside" and in_coach(man.global_position + Vector3.UP * 0.5):
				if hatch_man == g:
					_into_hatch(g)
				else:
					_start_climb(g)
			else:
				_arm(g, _box_order(g))
				g.phase = &"fighting"
		&"climbing":
			_climb(g, delta)
		&"hatch", &"fighting":
			if g.brain != null and is_instance_valid(g.brain):
				_brain_step(g)
	if g.has("cold_in"):
		g.cold_in = int(g.cold_in) - 1
		if g.cold_in <= 0:
			g.erase("cold_in")
			var b := g.brain as OutlawBrain
			var p := player()
			if b and is_instance_valid(b) and p:
				b.caught_cold(p, 0.3)
				if g.has("order"):
					b.give_order(g.order)


func _knock_daze(g: Dictionary) -> float:
	var s := 0.0
	for j: float in g.knocks:
		s += OutlawBrain.head_stun_seconds({"segment": &"head", "joules": j})
	return minf(s, tuning.daze_max)


static func _pelvis(man: HumanBody) -> Vector3:
	var p := man.parts.get(&"pelvis") as Node3D if man.parts else null
	return p.global_position if p else man.global_position


## Under the door, on the floor inside (world): the hatch man's spot a hand forward, a climber's a
## hand back.
func _hatch_floor(climber: bool) -> Vector3:
	var at := at_coach(Vector3(-0.15 if climber else 0.12, 1.75 if over else 1.4, 0.0))
	at.y = floor_y
	return at


## His limp body slid (out of sight, inside) so his pelvis lies at `to` across the floor.
func _shift_ragdoll(man: HumanBody, to: Vector3) -> void:
	var off := to - _pelvis(man)
	off.y = 0.0
	for rb: Variant in man.parts.values():
		if rb is RigidBody3D and is_instance_valid(rb):
			(rb as RigidBody3D).global_position += off
			(rb as RigidBody3D).linear_velocity = Vector3.ZERO
			(rb as RigidBody3D).angular_velocity = Vector3.ZERO


## Up on the bench's end in the open door, facing the high spot: the step a walk-only box (his feet
## find it, the coach's body doesn't).
func _into_hatch(g: Dictionary) -> void:
	var man := g.man as HumanBody
	var at := _hatch_floor(false)
	at.y = floor_y + tuning.hatch_step
	_step = StaticBody3D.new()
	_step.name = "HatchStep"
	_step.collision_layer = Layers.STAND & ~Layers.WORLD
	_step.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(0.5, 0.1, 0.5)
	cs.shape = bx
	_step.add_child(cs)
	cut.add_child(_step)
	_step.global_position = at + Vector3.DOWN * 0.05
	man.global_position = at
	man.face(_high_spot())
	g.phase = &"hatch"
	_arm(g, {"id": "coach_door", "at": at, "look": _high_spot(), "window": true, "why": "the door on top"})
	_note("%s in the door" % g.id)


## Out through the door: up, over the edge and down the far side, crouched (s: climb_seconds).
func _start_climb(g: Dictionary) -> void:
	var man := g.man as HumanBody
	var k := men.filter(func(o: Dictionary) -> bool: return o.role == &"inside" and o.phase in [&"fighting", &"climbing"]).size()
	var along := coach_basis() * Vector3.RIGHT
	along.y = 0.0
	along = along.normalized()
	var offs := [-1.0, 1.0, -1.9, 1.9]
	var mid := at_coach(Vector3(0, 1.75, 0))
	var land := mid + lee_dir * 2.0 + along * float(offs[k % offs.size()])
	land.y = _ground_at(land)
	var p0 := man.global_position
	var p1 := (hatch_top if over else at_coach(Vector3(0.0, 1.1, 0.95 * door_side)))
	if over:
		p1.y = hatch_top.y + 0.05
	g.path = [p0, p1, land]
	g.climb_t = 0.0
	g.phase = &"climbing"
	_climbing = true
	_note("%s climbing out" % g.id)


func _climb(g: Dictionary, delta: float) -> void:
	var man := g.man as HumanBody
	if man.limp:
		g.phase = &"dazed"
		_climbing = false
		return
	g.climb_t = float(g.climb_t) + delta
	var k := clampf(float(g.climb_t) / tuning.climb_seconds, 0.0, 1.0)
	var path: Array = g.path
	var at: Vector3
	if k < 0.45:
		at = (path[0] as Vector3).lerp(path[1], k / 0.45)
	else:
		var u := (k - 0.45) / 0.55
		at = (path[1] as Vector3).lerp(path[2], u)
		at.y += sin(u * PI) * 0.3
	man.global_position = at
	man.face(at + lee_dir)
	man.set_pose(&"crouch")
	if k >= 1.0:
		_climbing = false
		_arm(g, {})
		g.phase = &"fighting"
		_note("%s out of the coach" % g.id)


## The driver from his own cover; the messenger for the outcrop opposite first.
func _box_order(g: Dictionary) -> Dictionary:
	if g.id != "messenger":
		return {}
	var o := _outcrop()
	if o == Vector3.INF:
		return {}
	var hi := _high_spot()
	var away := o - hi
	away.y = 0.0
	away = away.normalized()
	# Its flank nearer him, a little behind its middle from the high spot (straight there from the
	# road, not through the rock); there, the rocks are his own cover (`_brain_step`).
	var across := away.cross(Vector3.UP)
	var man := g.man as HumanBody
	if (man.global_position - o).dot(across) < 0.0:
		across = -across
	var at := o + across * 4.2 + away * 1.5
	at.y = _ground_at(at)
	return {"id": "outcrop", "at": at, "look": hi, "window": true, "why": "the rocks across the cut"}


## The outcrop opposite (valley.json: the cut's `targets` "the outcrop opposite"), or INF.
func _outcrop() -> Vector3:
	if cut.layout == null:
		return Vector3.INF
	for tg: Dictionary in cut.layout.height(CoachCut.CUT).get("targets", []):
		if String(tg.get("name", "")).contains("outcrop"):
			var a: Array = tg.at
			var p := Vector3(float(a[0]), 0.0, float(a[1]))
			p.y = float(cut.height_at.call(p.x, p.z))
			return p
	return Vector3.INF


func _ground_at(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 4.0, p.z), Vector3(p.x, p.y - 8.0, p.z), Layers.STAND)
	if body and is_instance_valid(body):
		q.exclude = [body.get_rid()]
	var hit := World.space(cut).intersect_ray(q)
	return (hit.position as Vector3).y if not hit.is_empty() else float(cut.height_at.call(p.x, p.z))


## His brain, holding the cut, in the fight from the next ticks (`cold_in`), his order if any.
func _arm(g: Dictionary, order: Dictionary) -> void:
	var man := g.man as HumanBody
	if g.brain != null and is_instance_valid(g.brain):
		return
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.nerve = float(g.nerve) - tuning.nerve_per_knock * (g.knocks as Array).size() - (tuning.nerve_hurt if g.hurt != "" else 0.0)
	b.temper = float(g.temper)
	b.leads = bool(g.leads)
	var friends: Array[StringName] = []
	for o in men:
		if o != g:
			friends.append(StringName(o.id))
	b.friends = friends
	b.hold = {"inside": in_reach, "post": man.global_position, "look": _high_spot(), "cornered": true}
	b.agenda = [{"do": &"post"}]
	man.add_child(b)
	man.move_child(b, 0)
	g.brain = b
	g.cold_in = 3
	if not order.is_empty():
		g.order = order
	b.mood_changed.connect(func(mood: OutlawBrain.Mood) -> void:
		if mood == OutlawBrain.Mood.SURRENDERED:
			_note("%s gives up" % g.id)
		elif mood == OutlawBrain.Mood.FLEEING:
			_note("%s runs" % g.id))


## Where they fight: near the cut's middle, off the ram's bank (OutlawBrain.hold's `inside`).
func in_reach(p: Vector3) -> bool:
	if p == Vector3.INF:
		return false
	var d := p - cut.middle
	d.y = 0.0
	return d.length() < tuning.fight_reach and d.dot(cut.side) < cut.road_to + 4.0


func _brain_step(g: Dictionary) -> void:
	var b := g.brain as OutlawBrain
	if g.id == "messenger" and b.order.get("id", "") == "outcrop":
		var at: Vector3 = b.order.at
		if Vector2(at.x - b.body.global_position.x, at.z - b.body.global_position.z).length() < 0.8:
			b.give_order({})  # there: the rocks his cover now (his own Cover)
	if g.phase == &"hatch" and (b.body.limp or b.mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.FLEEING]):
		g.phase = &"fighting"
		if hatch_man == g:
			hatch_man = {}


## Out of it: dead, out cold, given up, run off (gone from the cut) or down for good.
func is_out(g: Dictionary) -> bool:
	var man := g.man as HumanBody
	if not is_instance_valid(man) or not man.physiology.alive or not man.physiology.is_conscious():
		return true
	var b := g.brain as OutlawBrain
	if b == null or not is_instance_valid(b):
		return g.phase == &"dazed" and t - hit_t > 120.0
	return b.mood in [OutlawBrain.Mood.SURRENDERED] or (b.mood == OutlawBrain.Mood.FLEEING and not in_reach(man.global_position)) \
			or (man.limp and not man.physiology.can_stand() and b.mood == OutlawBrain.Mood.DOWN)


func men_out() -> int:
	return men.filter(func(g: Dictionary) -> bool: return is_out(g)).size()


# --- The strongbox -----------------------------------------------------------------------------------

## E is the box's here: by the door with it inside, by it standing, or carrying it.
func claims_use(p: Player) -> bool:
	if state != State.ON or settled_t < 0.0 or p == null:
		return false
	match box_state:
		&"in":
			return _flat(p.global_position, hatch_top) <= tuning.haul_reach
		&"out", &"open":
			return box != null and is_instance_valid(box) and _flat(p.global_position, box.global_position) <= tuning.box_reach
		&"carried":
			return true
	return false


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _use_step(delta: float) -> void:
	var p := player()
	_prompt -= delta
	if p == null or not claims_use(p):
		_hold = 0.0
		return
	var held := Input.is_action_pressed(&"shove")
	_hold = _hold + delta if held else 0.0
	match box_state:
		&"in":
			_tell("Hauling the strongbox out..." if held else "Hold E to haul the strongbox out through the door")
			if _hold >= tuning.haul_hold:
				_hold = 0.0
				haul_out()
		&"out":
			if box.is_locked("lid"):
				_tell("Shouldering it..." if held else "Padlocked. Shoot it off, or hold E to shoulder the box (44 kg)")
				if _hold >= tuning.shoulder_hold:
					_hold = -INF
					shoulder()
			else:
				_tell("Opening it..." if held else "The lock's gone. Hold E to open it")
				if _hold >= tuning.open_hold:
					_hold = -INF
					open_box()
		&"open":
			_tell("Hold E to take the papers")
			if _hold >= tuning.open_hold:
				_hold = -INF
				take_papers()
		&"carried":
			if held and not _was_held:
				set_down()
	_was_held = held


func _tell(text: String) -> void:
	if _prompt <= 0.0:
		_prompt = 0.5
		_say(text, 0.6)


## The box out of the wreck, standing on the road by you (the loose one's pieces gone with it).
func haul_out() -> void:
	var old := cut.coach.carried("strongbox") if cut.coach else null
	if old:
		for rb in old.rubble:
			if is_instance_valid(rb):
				rb.queue_free()
		old.queue_free()
	var p := player()
	var from := p.global_position if p else hatch_top
	# Set down on the road by you, on the side away from the wreck (on its body it'd be on nothing
	# that holds still, and go loose).
	var away := from - hatch_top
	away.y = 0.0
	away = away.normalized() if away.length() > 0.05 else -lee_dir
	var at := from + away.rotated(Vector3.UP, 0.9) * 0.9
	_place_box(at, at + away * 2.0)  # (its padlock away from the wreck: room to stand and shoot it)
	box_state = &"out"
	_note("box hauled out")
	_say("The Baron's strongbox: iron, padlocked.", 3.0)


func _place_box(at: Vector3, face: Vector3) -> void:
	box = PropKit.spawn(&"strongbox", &"baron_strongbox")
	cut.add_child(box)
	at.y = _ground_at(at)
	var to := face - at
	to.y = 0.0
	# Its padlock (on its +z) toward you.
	var yaw := atan2(to.x, to.z) if to.length() > 0.01 else 0.0
	# Just over the ground (a foot a hair under a height field's surface finds nothing, #794, and
	# kept footed it has no feet to balance on once its padlock's shot off): it finds the ground.
	box.global_transform = Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * 0.01)


func shoulder() -> void:
	if box and is_instance_valid(box):
		box.queue_free()
	box = null
	box_state = &"carried"
	var p := player()
	if p:
		p.burden = tuning.box_pace
	_note("box shouldered")
	_say("The box on your shoulder: slow going. E sets it down. Get clear: %s" % way_out(), 8.0)


func set_down() -> void:
	var p := player()
	if p == null:
		return
	p.burden = 1.0
	var fwd := -p.global_basis.z
	fwd.y = 0.0
	_place_box(p.global_position + fwd.normalized() * 0.9, p.global_position)
	box_state = &"out"
	_note("box set down")


func open_box() -> void:
	if box and box.open_hinge("lid"):
		box_state = &"open"
		_note("box opened")


func take_papers() -> void:
	var m := box.get_member(StringName("%s/papers" % box.structure_id)) if box else null
	if m:
		box.unbatch(m)
		m.visible = false
		for c in m.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).set_deferred(&"disabled", true)
	box_state = &"taken"
	took = "papers"
	_note("papers taken")
	_say("The Baron's papers: deeds, a ledger, letters. Now get clear: %s" % way_out(), 8.0)


# --- Won and lost ------------------------------------------------------------------------------------

func _check_end() -> void:
	var p := player()
	if p == null:
		return
	if p.wounds and not p.wounds.physiology.is_conscious():
		_lose(&"you_down", "You're down.")
		return
	var have := took == "papers" or box_state == &"carried"
	if have and on_trail(p.global_position):
		took = "box" if box_state == &"carried" else took
		_win()
		return
	if not have and _flat(p.global_position, cut.middle) > tuning.left_it:
		_lose(&"left_it", "You rode off and left it.")


## Where the way out is from you, in words (the playtest, #815: nobody could find it).
func way_out() -> String:
	var line := cut.layout.road_line("rimrock_trail") if cut.layout else PackedVector2Array()
	var p := player()
	if line.size() < 2 or p == null:
		return "the rimrock trail."
	var a := line[0] + (line[1] - line[0]).normalized() * 10.0
	var to := a - Vector2(p.global_position.x, p.global_position.z)
	var deg := fposmod(rad_to_deg(atan2(to.x, -to.y)), 360.0)
	var names := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
	return "the rimrock trail, %d m off to the %s (it leaves the road past the cut and climbs south)." % [
			roundi(to.length() / 5.0) * 5, names[roundi(deg / 45.0) % 8]]


## Far enough up the rimrock trail (from where it leaves the South Road) and on it.
func on_trail(p: Vector3) -> bool:
	if cut.layout == null:
		return false
	var line := cut.layout.road_line("rimrock_trail")
	if line.size() < 2:
		return false
	var a := line[0]
	var u := (line[1] - a).normalized()
	var q := Vector2(p.x, p.z) - a
	var along := q.dot(u)
	return along >= tuning.trail_along and absf(q.cross(u)) <= tuning.trail_wide


func _win() -> void:
	state = State.WON
	end_t = t
	outcome = &"won"
	_note("won")
	_facts()
	var what := "the Baron's papers" if took == "papers" else "the Baron's strongbox"
	_say("You're away up the rimrock trail with %s. (Enter: again)" % what, 12.0, true)


func _lose(what: StringName, line: String) -> void:
	if state in [State.WON, State.LOST]:
		return
	state = State.LOST
	end_t = t
	outcome = what
	why = line
	_note("lost: %s" % what)
	_facts()
	_say(line + "  (Enter: try again)", 12.0, true)


## What it came to, for the story (StoryState: the next missions read it).
func _facts() -> void:
	StoryState.set_fact("coach.outcome", String(outcome))
	StoryState.set_fact("coach.took", took)
	var alive := 0
	var dead: Array = []
	for g in men:
		var man := g.man as HumanBody
		var lives := is_instance_valid(man) and man.physiology.alive
		if lives:
			alive += 1
		else:
			dead.append(g.id)
		if g.id in ["driver", "messenger"]:
			StoryState.set_fact("coach.%s" % g.id, "alive" if lives else "dead")
	StoryState.set_fact("coach.guards_alive", alive)
	StoryState.set_fact("coach.dead", dead)


## Enter once it's over (or held 1.5 s any time): again from the high spot (the game reloaded).
func _retry_step(delta: float) -> void:
	if not InputMap.has_action(&"mission_retry") or not cut.is_inside_tree():
		return
	if Input.is_action_pressed(&"mission_retry") and get_tree().current_scene and get_tree().current_scene.scene_file_path == "res://scenes/main.tscn":
		_retry_hold += delta
		if (state in [State.WON, State.LOST] and t - end_t > 1.0) or _retry_hold >= 1.5:
			_retry_hold = -INF
			retry()
	else:
		_retry_hold = 0.0


func retry() -> void:
	CoachCut.start_on_load = true
	var p := player()
	if p:
		p.burden = 1.0
	GameReset.reset(get_tree())


func _say(text: String, seconds: float, hold := false) -> void:
	var p := player()
	if p and p.wounds and text != "":
		p.wounds.say(text, seconds, hold)


func _note(what: String) -> void:
	timeline.append([snappedf(t, 0.01), what])


func result() -> Dictionary:
	var out := {"state": State.keys()[state], "outcome": String(outcome), "t": snappedf(t, 0.01),
			"hit": snappedf(hit_t, 0.01), "settled": snappedf(settled_t, 0.01), "end": snappedf(end_t, 0.01),
			"over": over, "door": door, "hatch_top": [snappedf(hatch_top.x, 0.01), snappedf(hatch_top.y, 0.01), snappedf(hatch_top.z, 0.01)] if hatch_top != Vector3.INF else [],
			"floor_y": snappedf(floor_y, 0.01), "box": String(box_state), "took": took, "shots_men": shots_men, "shots_you": shots_you,
			"box_loose": box.loose if box and is_instance_valid(box) else null,
			"box_locked": box.is_locked("lid") if box and is_instance_valid(box) else null, "men_out": men_out(),
			"timeline": timeline}
	var ms := []
	var p := player()
	for g in men:
		var man := g.man as HumanBody
		var d := {"id": g.id, "phase": String(g.phase), "knocks": g.knocks, "hurt": g.hurt, "daze": snappedf(float(g.daze), 0.1),
				"out": is_out(g)}
		if is_instance_valid(man):
			d.alive = man.physiology.alive
			d.limp = man.limp
			d.gun = "none" if man.held_gun == null else ("holstered" if man.gun_holstered else "drawn")
			d.can_hold = man.physiology.can_hold("r")
			d.can_run = man.physiology.can_run()
			d.pain = snappedf(man.physiology.felt_pain(), 0.01)
			d.shock = snappedf(man.physiology.shock(), 0.01)
			d.broken = man.physiology.broken.keys().map(func(k: Variant) -> String: return String(k))
			if not man.last_fall.is_empty():
				d.fall = {"kind": String(man.last_fall.get("kind", "")), "speed": man.last_fall.get("speed"),
						"joules": snappedf(float(man.last_fall.get("joules", 0.0)), 1.0), "harm": man.last_fall.get("harm")}
			d.at = [snappedf(man.global_position.x, 0.1), snappedf(man.global_position.y, 0.1), snappedf(man.global_position.z, 0.1)]
		var b := g.brain as OutlawBrain
		if b and is_instance_valid(b):
			d.mood = OutlawBrain.Mood.keys()[b.mood]
			d.tactic = OutlawBrain.Tactic.keys()[b.tactic]
			d.order = String(b.order.get("id", ""))
			d.decision = b.decision
			d.nerve = snappedf(b.nerve, 0.01)
			d.fear = snappedf(b.dread(), 0.01)
			var ff := {}
			for k: StringName in b.fear_from:
				ff[String(k)] = snappedf(float(b.fear_from[k]), 0.01)
			d.fear_from = ff
			if p and b.senses:
				d.knows = snappedf(minf(b.senses.since_known(p), 999.0), 0.1)
		ms.append(d)
	out.men = ms
	return out
