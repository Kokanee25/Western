class_name PlayerShove
extends Node
## Your shove and kick (issue #479; Sean, 2026-10-28: "put bad men over and through furniture,
## over rails and down stairs"). One key (E; the right stick's click): tapped, a two-handed shove,
## quick and at arm's length; held and let go, a front kick, slower and harder, and a moment off
## balance after. Both with a gun in hand: with the revolver up the shove is your left hand alone.
##
## Nothing canned: what it gives is worked out as a knock between the part of you behind it and
## what it lands on (ShoveTuning), and the rest is theirs: a man takes it by HumanBody.take_push
## (over if it's more than he can catch with a step, else a stagger back that goes over whatever's
## behind him), a kit prop by KitProp.take_blow (it breaks, slides or holds), a loose thing by its
## own, a wall or a post holds and your foot takes the stop. A miss is a miss. A hurt leg kicks
## weakly or not at all; a kick on a stair may cost you your footing. Laying hands on a man is a
## deed (Events.deed: `shove`, `kick`, and kicking a man who's down, `kick_down`).

## Each one's outcome, as it lands (the lab, the tests): {move, what (&"man", &"prop", &"wall",
## &"thing", &"miss", &"slip", &"cant"), result, momentum, speed, at, ...}.
signal landed(info: Dictionary)

var player: Player
var tuning: ShoveTuning
## The move under way (&"shove", &"kick"), and how far into it (s); &"" when you're free.
var move := &""
var t := 0.0
## How long the key's been held (s; -1 not held): long enough, it's a kick when let go.
var holding := -1.0
## The last one's outcome (`landed`).
var last := {}
## The lab and the bridge: start this move next tick as if the key had done it.
var wants := &""

var _struck := false
var _one_hand := false
var _with_held := false  ## the shove's with the shotgun (or the bucket) in both hands
var _speed := 0.0  ## the boot's or hands' own speed this move (a hurt leg's less)
var _recover := 0.0  ## s off balance left after a kick
var _slipped := 0.0  ## s down on a stair after losing your footing
var _rng := RandomNumberGenerator.new()
var _arms: Node3D
var _hands: Array[HeldHand] = []

## Your hands as they go out (camera space): from low and close to out at arm's length.
const HAND_FROM := Vector3(0.17, -0.42, -0.2)
const HAND_TO := Vector3(0.16, -0.17, -0.6)
## ... and the gun in both hands pushed out this far (m).
const HELD_OUT := 0.3


func _ready() -> void:
	if tuning == null:
		tuning = ShoveTuning.t()
	_rng.seed = 479


## How fast you can move now (a share of your pace): off balance after a kick, down after a slip.
func pace() -> float:
	if _slipped > 0.0:
		return 0.2
	if move == &"kick" or _recover > 0.0:
		return tuning.kick_pace
	return 1.0


## Down on the tread after losing your footing.
func slipped() -> bool:
	return _slipped > 0.0


## The view dipped as you kick (degrees, down): you look down your leg at him as it comes up, so
## you see it go in.
const KICK_LOOK := 10.0


func view_pitch() -> float:
	var l := leg()
	return -KICK_LOOK * maxf(l.x, l.y)


## Your kicking leg (PlayerBody): drawn up (x, 0-1) as you hold the key, out straight (y, 0-1) as
## it lands, and back down.
func leg() -> Vector2:
	var tu := tuning
	if move == &"kick":
		var out := clampf(t / maxf(tu.kick_hit_at, 0.01), 0.0, 1.0)
		var back := clampf((t - tu.kick_hit_at - 0.08) / maxf(tu.kick_time - tu.kick_hit_at - 0.08, 0.01), 0.0, 1.0)
		return Vector2(1.0 - back, out * (1.0 - back))
	if holding >= 0.0 and holding >= tu.hold_for_kick * 0.5:
		return Vector2(clampf((holding - tu.hold_for_kick * 0.5) / (tu.hold_for_kick * 0.8), 0.0, 1.0), 0.0)
	return Vector2.ZERO


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_slipped = maxf(_slipped - delta, 0.0)
	_recover = maxf(_recover - delta, 0.0)
	if move == &"" and _slipped <= 0.0:
		if wants != &"":
			_start(wants)
			wants = &""
		elif player.input_enabled:
			if Input.is_action_just_pressed(&"shove"):
				# A stick in hand by a wall: E sets it there (DynamiteViewmodel, #506).
				holding = -1.0 if _planting() else 0.0
			elif holding >= 0.0:
				if Input.is_action_pressed(&"shove"):
					holding += delta
				else:
					_start(&"kick" if holding >= tuning.hold_for_kick else &"shove")
					holding = -1.0
	if move != &"":
		t += delta
		var hit_at := tuning.kick_hit_at if move == &"kick" else tuning.shove_hit_at
		if not _struck and t >= hit_at:
			_struck = true
			_strike()
		if t >= (tuning.kick_time if move == &"kick" else tuning.shove_time):
			if move == &"kick":
				_recover = tuning.kick_recover
			move = &""
	_show_hands()


func _planting() -> bool:
	var w := player.weapon
	return w is DynamiteViewmodel and (w as DynamiteViewmodel).claims_use()


func _start(kind: StringName) -> void:
	var p := player.wounds.physiology if player.wounds else null
	_one_hand = false
	_with_held = false
	if kind == &"kick":
		# The leg you kick with and the one you stand on.
		if p and (not p.leg_ok("r") or not p.leg_ok("l") or p.legs_paralysed()):
			_tell({"move": kind, "what": &"cant"}, "Your leg won't take a kick.")
			return
		_speed = tuning.kick_speed * (p.muscle_strength("leg", "r") if p else 1.0)
		if _on_stair() and _rng.randf() < tuning.stair_slip:
			_slipped = tuning.slip_time
			player.motion.thump(tuning.thump_max)
			_tell({"move": kind, "what": &"slip"}, "Your boot goes out from under you on the stair.")
			return
	else:
		var w := player.weapon
		var held := w != null and w.selected and w.drawn and not w.is_put_away()
		_one_hand = held and (w is RevolverViewmodel or w is DynamiteViewmodel)
		# The shotgun or a bucket in both hands: you shove with it held across you.
		_with_held = held and not _one_hand
		var arms := 0.0
		if p:
			var left := p.muscle_strength("arm", "l") if p.can_hold("l") else 0.0
			var right := p.muscle_strength("arm", "r") if p.can_hold("r") else 0.0
			# One hand free (the other on the gun): the free one, or the gun hand if that's all you
			# have; both, their mean.
			arms = (left if left > 0.05 else right) if _one_hand else (left + right) * 0.5
		else:
			arms = 1.0
		if arms <= 0.05:
			_tell({"move": kind, "what": &"cant"}, "You've no arm to shove with.")
			return
		_speed = tuning.shove_speed * arms
	move = kind
	t = 0.0
	_struck = false


func _tell(info: Dictionary, words := "") -> void:
	last = info
	if words != "" and player.wounds:
		player.wounds.say(words, 2.0)
	landed.emit(info)


## On a stair's walking ramp (Layers.WALK, under its treads).
func _on_stair() -> bool:
	var q := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.3, player.global_position + Vector3.DOWN * 0.3, Layers.WALK)
	return not World.space(player).intersect_ray(q).is_empty()


## The moment it lands: what's there, and what it does.
func _strike() -> void:
	var tu := tuning
	var kick := move == &"kick"
	var cam := player.camera
	var fwd := -cam.global_basis.z
	var flat := Vector3(fwd.x, 0.0, fwd.z)
	flat = flat.normalized() if flat.length() > 0.01 else player.get_forward()
	var reach := tu.kick_reach if kick else tu.shove_reach
	var share := (tu.kick_mass_share if kick else tu.shove_mass_share) * (tu.shove_one_hand if _one_hand else 1.0)
	var m_e := tu.mass * share
	# Your own way along it adds to the hands' or boot's speed (a shove on the run is harder).
	var v := _speed + maxf(player.velocity.dot(flat), 0.0)
	var hit := _find(cam.global_position, fwd, reach)
	var info := {"move": move, "speed": v, "mass": m_e, "one_hand": _one_hand}
	if hit.is_empty():
		info.what = &"miss"
		GameAudio.play(player, &"whoosh", cam.global_position + flat * 0.5, {"volume_db": -10.0, "delay": false})
		if kick:
			player.motion.thump(0.15)
		_tell(info)
		return
	var c: Object = hit.collider
	var at: Vector3 = hit.point
	info.at = at
	var man: Variant = c.get_meta(&"human_body") if c and c.has_meta(&"human_body") else null
	if man is HumanBody:
		_on_man(man as HumanBody, c, at, flat, kick, m_e, v, info)
	elif c is StructureMember:
		_on_member(c as StructureMember, at, flat, kick, m_e, v, info)
	elif c and ((c.has_meta(&"glass_prop") and c.get_meta(&"glass_prop") is GlassProp) or c is RigidBody3D):
		var gp: Variant = c.get_meta(&"glass_prop") if c.has_meta(&"glass_prop") else null
		if gp is LooseProp:
			info.result = (gp as LooseProp).take_blow(at, flat * m_e * v, m_e)
		elif gp is GlassProp:
			# A bottle, a lamp: next to the boot or the hands it weighs nothing, and goes on at their
			# speed, or breaks if that's past what its glass takes.
			var g := gp as GlassProp
			if v >= float(g.definition.get("breaks_at", 3.0)):
				g.shatter(at, flat)
				info.result = &"broke"
			else:
				g.wake(flat * v)
				info.result = &"moved"
		else:
			var rb := c as RigidBody3D
			var mu := m_e * rb.mass / (m_e + rb.mass)
			rb.apply_impulse(flat * mu * v, at - rb.global_position)
			info.result = &"moved"
		info.what = &"thing"
		info.momentum = m_e * v
		GameAudio.play(player, &"impact_wood", at, {"volume_db": -6.0})
		player.motion.thump(0.15)
		_tell(info)
	else:
		info.what = &"wall"
		_held_fast(at, kick, v, info)


## What `m_e` kg of you at `v` m/s gives something of `big_m` kg it meets and moves on with (an
## inelastic knock): its momentum (N*s), and for a kick the energy that is to the part it lands on
## (a shove's is a push and harms nothing). The lab works out its pushes here too.
static func knock(m_e: float, v: float, big_m: float, kick: bool) -> Dictionary:
	var p := m_e * big_m / (m_e + big_m) * v
	return {"momentum": p, "joules": 0.5 * p * p / big_m if kick else 0.0}


## The first thing a sphere a hand's width sent out along your look meets, within reach of your
## middle: {collider, point}, or {}.
func _find(from: Vector3, dir: Vector3, reach: float) -> Dictionary:
	var space := World.space(player)
	var shape := SphereShape3D.new()
	shape.radius = 0.12
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.transform = Transform3D(Basis.IDENTITY, from)
	# From the eyes: they're a little ahead of your middle, and the reach is measured from it.
	var length := reach + 0.45
	q.motion = dir * length
	q.collision_mask = Layers.WORLD | Layers.BODY_PARTS
	q.exclude = [player.get_rid()]
	var frac := space.cast_motion(q)
	if OS.has_environment("SHOVE_DEBUG"):
		print("shove cast from %s dir %s len %.2f -> %s" % [from, dir, length, frac])
	if frac[1] >= 1.0:
		return {}
	q.transform = Transform3D(Basis.IDENTITY, from + dir * length * frac[1])
	q.motion = Vector3.ZERO
	var rest := space.get_rest_info(q)
	if rest.is_empty():
		return {}
	var point: Vector3 = rest.point
	var mid := player.global_position
	if Vector2(point.x - mid.x, point.z - mid.z).length() > reach + 0.15:
		return {}
	return {"collider": instance_from_id(rest.collider_id), "point": point}


func _on_man(man: HumanBody, part: Object, at: Vector3, flat: Vector3, kick: bool, m_e: float, v: float, info: Dictionary) -> void:
	var tu := tuning
	var dir := flat
	var big_m: float
	if man.limp:
		# On the floor: the boot goes in forward and down, into the part it meets.
		dir = (flat + Vector3.DOWN * 0.4).normalized()
		big_m = float((part as Node).get_meta(&"mass", 10.0)) if part is Node else 10.0
	else:
		# Standing: the hands land on his chest, the boot in his belly, on the skin toward you.
		var seg := &"abdomen" if kick else &"chest"
		var p3 := man.parts.get(seg) as Node3D
		if p3:
			var y := man.global_position.y + (tu.kick_height if kick else tu.shove_height)
			at = Vector3(p3.global_position.x, minf(maxf(y, man.global_position.y + 0.8), p3.global_position.y + 0.15), p3.global_position.z) - flat * 0.12
		big_m = man._body_mass()
	var k := knock(m_e, v, big_m, kick)
	var p: float = k.momentum
	var joules: float = k.joules
	var was_down := man.limp
	var result := man.take_push(at, dir, p, joules, player)
	info.merge({"what": &"man", "who": man.person_id, "result": result, "momentum": p, "joules": joules,
			"his_speed": p / big_m, "catch": man.catch_speed() if not was_down else 0.0, "down_before": was_down,
			"at": at}, true)
	Events.deed.emit(player, (&"kick_down" if was_down else &"kick") if kick else &"shove", man, at)
	Events.noise.emit(at, 8.0, &"scuffle", player)
	GameAudio.play(player, &"thump", at, {"volume_db": -2.0 if kick else -8.0})
	player.motion.thump(minf(p * tu.thump_per_ns, tu.thump_max))
	_tell(info)


func _on_member(m: StructureMember, at: Vector3, flat: Vector3, kick: bool, m_e: float, v: float, info: Dictionary) -> void:
	var s := m.get_parent()
	info.member = String(m.member_id)
	if s is KitProp:
		info.what = &"prop"
		info.momentum = m_e * v
		info.result = (s as KitProp).take_blow(m, at, flat * m_e * v, m_e)
		GameAudio.play(player, &"impact_wood", at, {"volume_db": -4.0})
		Events.noise.emit(at, 10.0, &"crash", player)
		player.motion.thump(minf(m_e * v * tuning.thump_per_ns * 0.5, tuning.thump_max))
		_tell(info)
		return
	info.what = &"wall"
	var e := 0.5 * m_e * v * v
	if s is Structure and m.kind == &"glass":
		(s as Structure).break_member(m, flat * v)
		info.result = &"broke"
		_tell(info)
		return
	if kick and s is Structure and e > BodyImpacts.capacity(s as Structure, m):
		# More than it can take: a boot through a rail or a board.
		(s as Structure).break_member(m, flat * v * 0.3)
		info.result = &"broke"
		info.joules = e
		GameAudio.play(player, &"timber_crack", at, {"volume_db": -4.0})
		Events.noise.emit(at, 14.0, &"crash", player)
		player.motion.thump(0.3)
		_tell(info)
		return
	_held_fast(at, kick, v, info)


## It didn't give (a wall, a post, the bar): the boot stops dead on it, and your foot takes the
## stop (the rest of your leg gives at the knee and hip); hands just meet it.
func _held_fast(at: Vector3, kick: bool, v: float, info: Dictionary) -> void:
	info.result = &"held"
	GameAudio.play(player, &"impact_wood", at, {"volume_db": -6.0 if kick else -14.0})
	if kick:
		var j := 0.5 * tuning.foot_mass * v * v
		info.joules = j
		var harm := player.wounds.physiology.blow(&"foot_r", j, _rng) if player.wounds else PackedStringArray()
		info.harm = harm
		player.motion.thump(tuning.thump_max)
		if player.wounds:
			player.wounds.say("It doesn't give. Your foot does%s." % (": " + ", ".join(harm) if not harm.is_empty() else ""), 2.5)
	else:
		player.motion.thump(0.1)
	_tell(info)


## Your hands going out for a shove (a Studio man's own, as on the guns: HeldHand), the left alone
## when the revolver's up; with the shotgun in both hands, the gun goes out instead.
func _show_hands() -> void:
	var out := 0.0
	if move == &"shove":
		var tu := tuning
		out = clampf(t / maxf(tu.shove_hit_at, 0.01), 0.0, 1.0) if t < tu.shove_hit_at \
				else clampf(1.0 - (t - tu.shove_hit_at) / maxf(tu.shove_time - tu.shove_hit_at, 0.01), 0.0, 1.0)
	player.motion.push_out = HELD_OUT * out if _with_held else 0.0
	if out <= 0.0 or _with_held:
		if _arms:
			_arms.visible = false
		return
	if _arms == null:
		_build_hands()
	_arms.visible = true
	var k := out * out * (3.0 - 2.0 * out)
	for h in _hands:
		var side := 1.0 if h.right else -1.0
		h.visible = not (_one_hand and h.right)
		h.position = Vector3(HAND_FROM.x * side, HAND_FROM.y, HAND_FROM.z).lerp(Vector3(HAND_TO.x * side, HAND_TO.y, HAND_TO.z), k)


func _build_hands() -> void:
	_arms = Node3D.new()
	_arms.name = "ShoveHands"
	player.camera.add_child(_arms)
	for right in [true, false]:
		var h := HeldHand.new(right)
		h.name = "Right" if right else "Left"
		# Palm out ahead of you, fingers up, thumbs in (hand space: palm -X for the right hand, +X
		# for the left; fingers -Z).
		h.basis = Basis(Vector3(0, 0, 1 if right else -1), Vector3(-1 if right else 1, 0, 0), Vector3(0, -1, 0))
		_arms.add_child(h)
		h.shoulder = ShotgunViewmodel.SHOULDER_R if right else ShotgunViewmodel.SHOULDER_L
		h.elbow_pole = ShotgunViewmodel.ELBOW_POLE_R if right else ShotgunViewmodel.ELBOW_POLE_L
		for f: String in HeldHand.FINGERS:
			h.grasp(f, 0.1, 0.2)
		_hands.append(h)
	for mi in _arms.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).layers |= Layers.VIS_HELD
