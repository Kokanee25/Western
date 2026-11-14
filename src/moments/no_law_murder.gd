class_name NoLawMurder
extends CardCheat
## No Law, beat 3 (docs/missions/no-law.md; issue #773; data config/moments/no_law_murder.json): at
## night in the saloon's yard, the card game going. A stranger walks in and sits in the free chair
## you're not in ("Evening. Mind if I sit in a while?"). A minute on, Cody (one of the Baron's hired
## guns; not the red shirt, who shot the sheriff: Sean, #796) comes in off the street already
## shouting at Earl ("Earl, you cheating son of a bitch!", Sean's note 2026-11-12: as he walks into
## the yard, not at the table); as he comes up the game stops and holds (CardGame.interrupt(&"cody",
## true)), the stranger tells you not to move, and sat at the table you're held there
## (PlayerSeat.hold: E says why). Earl's "Now, Cody, I never...", the kick of his chair out from under
## him from behind (the card cheat's walk, kick, draw and approach: CardCheat's beats on the valley's
## own Earl and chair), stands over him and shoots him in the head where he lies (a second shot if
## the first didn't kill him), says there's no law to save him now, holsters and walks out the way
## he came. The room's quiet the while (the folk hushed: CivilianBrain.hush) till the barman: "Jesus,
## Cody, my chair!". After: the stranger has his word, you're let go, he goes; the drifter and the
## miner leave (ValleyFolk.send_off); Earl's body stays (ValleyFolk keeps the dead). StoryState:
## nolaw.murder, nolaw.witnessed, nolaw.seen_from (table, yard, heard, away), nolaw.earl.
##
## Not sat at the table it happens all the same (you hear the shot). Cody shot down before he's done
## (you, from the yard): it ends there (`cody_down`), everyone let go. Started by ValleyFolk (its
## `_maybe_murder`: the hour, or your hands played) or the bridge's `moment no_law_murder`.
## The men, Cody and the stranger, are ValleyFolk's (`act` in config/valley_folk.json): built with
## the rest while the valley loads (a Studio man built in play is a long frame) and taken here.

## CardCheat's beats, played by it on our men.
const KICK_BEATS: Array[StringName] = [&"turn", &"kick", &"after_kick", &"draw", &"approach"]
## Close enough to a point on his way (m).
const ARRIVE := 0.35

var folk: ValleyFolk
var game: CardGame
var stranger: HumanBody
var stranger_chair: KitProp
var barkeep: HumanBody
## You were held in your seat (sat at the table as Cody came up).
var you_held := false
var seen_from := ""
var shots := 0
## Why it ended (&"done", &"cody_down", &"stalled_..."): the after beats play out either way.
var end_reason := &""
## Cody's come in: from here it's the story's (`nolaw.murder` set). Over before that (no Earl, no
## Cody), nothing's written and the folk try it again a while on (review A5, #864).
var played := false
var _cody: Dictionary
var _str: Dictionary
var _route: Array[Vector3] = []
var _str_route: Array[Vector3] = []
var _str_state := &"out"
var _str_t := 0.0
var _stopped := false
var _accused := false
var _accuse_t := -100.0
var _warned := false
var _drew := false
var _shot_t := -1.0
## Since Cody went out of the yard (s; -1 before).
var _out_t := -1.0
var _barkeep_t := -1.0
var _barkeep_more := false
var _sent := {}
var _let_go := false
var _hushed := false
## Walking off down the street after (s since; -1 not).
var _cody_going := -1.0
## The stranger's way to his chair (walked back the other way when he goes).
var _str_approach: Array[Vector3] = []
var _str_said_at := -100.0
## The barkeep over by Earl: since he was sent (s; -1 not), and back at his bar.
var _barkeep_go := -1.0
var _barkeep_back := false


func begin() -> void:
	folk = get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk
	if folk == null:
		_note("no valley folk")
		_finish(&"no_folk")
		return
	game = folk.cards
	_cody = data.get("cody", {})
	_str = data.get("stranger", {})
	_load_clips()
	cheater = folk.folk_man(StringName(data.get("cheater", "earl")))
	var c := folk.props.get("chair_" + String(data.get("chair", "w"))) as KitProp
	if cheater == null or not cheater.physiology.alive or c == null or c.loose:
		_note("Earl isn't at the table")
		_finish(&"no_earl")
		return
	_take_chair(c)
	barkeep = folk.folk_man(StringName(data.get("barkeep", "barkeep")))
	folk.murder = self
	_start_stranger()
	state = &"stranger"


# --- Where --------------------------------------------------------------------------------------

## The folk's places named, as points; a name that isn't one is an error (#864), left out.
func _points(names: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n: String in names:
		if folk.places.has(StringName(n)):
			out.append(folk.places.at(StringName(n)))
		else:
			push_error("NoLawMurder: no place '%s' among the valley folk's" % n)
	return out


## A point of the set's lot ([a, b] as config/valley_folk.json's), on the ground.
func _lot(ab: Array) -> Vector3:
	return folk.lot_point(String(folk.data.set.lot), float(ab[0]), float(ab[1]))


## Behind a chair (its back), on the way in to sit in it.
func _behind(c: KitProp) -> Vector3:
	var p := Seating.spot(c) - c.global_basis.z * 0.75
	p.y = folk.ground(p.x, p.z)
	return p


## You're sat at the card table (one of its chairs).
func _you_at_table() -> bool:
	var p := player()
	return p != null and p.seat != null and p.seat.seated() and game != null and game.chairs.has(p.seat.chair)


# --- The stranger ---------------------------------------------------------------------------------

## The free chair he takes (the first of his `chairs` nobody's in), or null.
func _stranger_chair() -> KitProp:
	for k: String in _str.get("chairs", ["s", "n"]):
		var c := folk.props.get("chair_" + k) as KitProp
		if c != null and not c.loose and c.seated == null:
			return c
	return null


func _start_stranger() -> void:
	stranger_chair = _stranger_chair()
	var way := _points(_str.get("in", []))
	_str_approach.clear()
	if stranger_chair:
		var k := String(stranger_chair.name).get_slice("_", 1)
		for ab: Array in (_str.get("approach", {}) as Dictionary).get(k, []):
			_str_approach.append(_lot(ab))
	way.append_array(_str_approach)
	var end := _behind(stranger_chair) if stranger_chair else _lot([5.6, 3.6])
	way.append(end)
	Events.deed.connect(_on_deed)
	stranger = folk.take(StringName(_str.get("id", "stranger")), way[0], way[1] if way.size() > 1 else end)
	if stranger == null:
		_note("no stranger")
		_str_state = &"gone"
		return
	way.pop_front()
	_str_route = way
	_str_state = &"walk"
	_note("the stranger comes in")


func _stranger_step(delta: float) -> void:
	if stranger == null or not is_instance_valid(stranger) or _str_state == &"gone":
		return
	stranger.wake()
	_str_t += delta
	match _str_state:
		&"walk":
			if _walk_way(stranger, _str_route, float(_str.get("walk_speed", 1.2)), delta):
				_str_state = &"sit"
				_str_t = 0.0
		&"sit":
			if stranger_chair == null or not is_instance_valid(stranger_chair) or stranger_chair.loose \
					or (stranger_chair.seated != null and stranger_chair.seated != stranger):
				stranger_chair = _stranger_chair()
			if stranger_chair != null and Seating.sit_step(stranger, stranger_chair, delta):
				_str_state = &"sat"
				_str_t = 0.0
				_note("the stranger sits in %s" % stranger_chair.name)
				if state == &"stranger":
					speak(stranger, line("stranger_sit"))  # (not once Cody's in: the playtest heard it after his warning)
			elif stranger_chair == null or _str_t > float(_str.get("sit_timeout_s", 20.0)):
				# No chair to be had: he stands by the table.
				_str_state = &"sat"
				_str_t = 0.0
				stranger.set_pose(&"stand")
				_note("the stranger stands by")
		&"sat":
			if stranger_chair != null and is_instance_valid(stranger_chair) and stranger_chair.seated == stranger:
				Seating.sit_step(stranger, stranger_chair, delta)
			elif not stranger.limp:
				stranger.set_pose(&"stand")
				if game:
					stranger.face(game.centre() + Vector3.UP * 0.6)
		&"leave":
			if _walk_off(stranger, _str_route, float(_str.get("walk_speed", 1.2)), delta, _str_t):
				folk.release(StringName(_str.get("id", "stranger")))
				stranger = null
				_str_state = &"gone"
				_note("the stranger's gone")


## Cody's way out: his `out` places, then `off` on from the last (down Main Street).
func _way_out() -> Array[Vector3]:
	var way := _points(_cody.get("out", []))
	var off: Array = _cody.get("off", [0.0, 0.0])
	if not way.is_empty():
		var end := way[way.size() - 1] + Vector3(float(off[0]), 0.0, float(off[1]))
		end.y = folk.ground(end.x, end.z)
		way.append(end)
	return way


## Up and out the way Cody went.
func _stranger_leaves() -> void:
	if stranger == null or not is_instance_valid(stranger) or _str_state in [&"leave", &"gone"]:
		return
	if stranger_chair != null and is_instance_valid(stranger_chair) and stranger_chair.seated == stranger:
		Seating.stand_up(stranger, stranger_chair)
	stranger.set_pose(&"stand")
	_str_route.clear()
	for i in range(_str_approach.size() - 1, -1, -1):
		_str_route.append(_str_approach[i])
	_str_route.append_array(_way_out())
	_str_state = &"leave"
	_str_t = 0.0
	_note("the stranger gets up and goes")


## Out of the yard by `way`, then on away from the table: true once he can go (well clear and out of
## your sight, or far off, or a minute on: then he's taken out of the world).
func _walk_off(man: HumanBody, way: Array[Vector3], speed: float, delta: float, walking_s: float) -> bool:
	var p := player()
	var from_you := man.global_position.distance_to(p.global_position) if p else INF
	if (from_you > float(_cody.get("gone_m", 30.0)) and not _in_your_sight(man.global_position)) or walking_s > 240.0:
		return true
	if _walk_way(man, way, speed, delta):
		# His way walked and you still on him (following): on down the street the same way. You
		# saw which way he went (S10: at the camp you'll know it already, No Justice step 2).
		if man == victim and not StoryState.has_fact("nolaw.followed"):
			fact("nolaw.followed", true)
		var off: Array = _cody.get("off", [1.0, 0.0])
		var on := Vector3(float(off[0]), 0.0, float(off[1])).normalized()
		man.set_pose(&"stand")
		man.walk_to(man.global_position + on * 4.0, speed, delta)
	return false


## In front of you and near enough to see (a man going out of sight is let go).
func _in_your_sight(at: Vector3) -> bool:
	var p := player()
	if p == null:
		return false
	var to := at - p.global_position
	var fwd := p.get_forward()
	return to.length() < 60.0 and fwd.dot(to.normalized()) > 0.2


## A gun drawn on the stranger or "Drop it!" at him: he has his word (#773's playtest: silence).
func _on_deed(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
	if stranger == null or not is_instance_valid(stranger) or actor == stranger or not actor is Player:
		return
	if kind not in [&"aim_at", &"shout", &"draw"] or (target != stranger and kind != &"draw"):
		return
	if kind == &"draw" and (actor as Node3D).global_position.distance_to(stranger.global_position) > 6.0:
		return
	if t - _str_said_at < 4.0 or not stranger.physiology.is_conscious():
		return
	_str_said_at = t
	stranger.face((actor as Node3D).global_position + Vector3.UP * 1.5)
	speak(stranger, line("stranger_aimed"))


## The barkeep comes round to Earl's body, says his piece there, gathers the cards; back to his bar
## a while on (#773's playtest: nobody went to the body, the dead game stayed on the felt).
func _barkeep_step(delta: float) -> void:
	if _barkeep_go < 0.0 or _barkeep_back or barkeep == null or not is_instance_valid(barkeep) or cheater == null or not is_instance_valid(cheater):
		return
	_barkeep_go += delta
	var brain := barkeep.get_node_or_null(^"Brain") as CivilianBrain
	if brain == null:
		return
	var after: Dictionary = data.get("after", {})
	var body := (cheater.parts[&"pelvis"] as Node3D).global_position
	if not _barkeep_more:
		var flat := barkeep.global_position - body
		flat.y = 0.0
		if flat.length() < 1.6 or _barkeep_go > float(after.get("barkeep_more_s", 20.0)):
			_barkeep_more = true
			barkeep.face(body)
			if barkeep.physiology.is_conscious():
				speak(barkeep, line("barkeep_more"))
			if game:
				game._clear_table()  # he gathers up the cards
			_note("the barkeep by Earl")
	elif _barkeep_go > float(after.get("barkeep_more_s", 20.0)) + float(after.get("watch_s", 30.0)):
		_barkeep_back = true
		var p := folk._person(&"barkeep")
		if not p.is_empty():
			var pf := folk.post_of(p)
			brain.go_to(pf[0], pf[1])
		_note("the barkeep back to his bar")


## Send the barkeep over to Earl.
func _barkeep_to_body() -> void:
	if _barkeep_go >= 0.0 or _barkeep_more:
		return
	var brain := barkeep.get_node_or_null(^"Brain") as CivilianBrain if barkeep != null and is_instance_valid(barkeep) else null
	if brain == null or not barkeep.physiology.is_conscious() or cheater == null or not is_instance_valid(cheater):
		_barkeep_more = true  # no barkeep to go (shot, gone): nothing waits on him
		return
	var body := (cheater.parts[&"pelvis"] as Node3D).global_position
	var from := barkeep.global_position - body
	from.y = 0.0
	var spot := body + from.normalized() * 1.0
	spot.y = folk.ground(spot.x, spot.z) + 0.05
	brain.go_to(spot, body)
	_barkeep_go = 0.0
	_note("the barkeep goes to Earl")


## Walk `man` along `way` (popping each point as he gets to it): true once he's at the end.
func _walk_way(man: HumanBody, way: Array[Vector3], speed: float, delta: float) -> bool:
	while not way.is_empty():
		var flat := way[0] - man.global_position
		flat.y = 0.0
		if flat.length() > ARRIVE:
			break
		way.pop_front()
	if way.is_empty():
		return true
	man.set_pose(&"stand")
	man.walk_to(way[0], speed, delta)
	return false


# --- The beats -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if done:
		# Over (the facts set): Cody and the stranger still walking off till they're gone.
		t += delta
		_stranger_step(delta)
		_cody_walks(delta)
		_barkeep_step(delta)
		return
	for m: HumanBody in [cheater, victim, stranger]:
		if m != null and is_instance_valid(m):
			m.wake()  # full ticks while it plays, however far off you are (PeopleTick's bands)
	_stranger_step(delta)
	card_step(delta)
	if _stopped and not _warned and state != &"after" and t - _accuse_t > float(_cody.get("warn_after_s", 1.8)):
		_warn()
	if state == &"after":
		t += delta
		state_t += delta
		_after_step(delta)
		return
	if victim != null and is_instance_valid(victim) and (victim.limp or not victim.physiology.alive):
		_note("Cody's down")
		_end(&"cody_down")
		return
	if state in KICK_BEATS:
		if not _drew and victim.held_gun != null and not victim.gun_holstered:
			_drew = true
			Events.deed.emit(victim, &"draw", null, victim.global_position)
		super(delta)
		return
	t += delta
	state_t += delta
	if cheater != null and is_instance_valid(cheater) and cheater.limp and _fell_t >= 0.0:
		cheater.rise_ok = false
	match state:
		&"stranger":
			if _str_state in [&"sat", &"gone"] and (_str_t > float(_cody.get("after_s", 3.0)) or _str_state == &"gone"):
				_cody_in()
			elif state_t > 60.0:
				_cody_in()
		&"come":
			_come(delta)
		&"stand_over":
			_stand_over()
		&"shot":
			if cheater.physiology.alive and shots < 3 and state_t > float(_cody.get("second_shot_s", 0.7)):
				_shoot_head()
				state_t = 0.0
			elif state_t > float(_cody.get("gloat_s", 0.9)):
				speak(victim, line("gloat"))
				_note("Cody: no law")
				_go(&"gloat")
		&"gloat":
			if state_t > float(_cody.get("leave_s", 1.6)):
				victim.stop_clip()
				victim.set_pose(&"stand")
				victim.holster_gun()
				_route = _way_out()
				_note("Cody walks out")
				_go(&"leave")
		&"leave":
			_leave(delta)


## Cody in off the street, by his way in.
func _cody_in() -> void:
	var way := _points(_cody.get("in", []))
	if way.is_empty():
		way.append(_lot([5.2, -2.0]))
	victim = folk.take(StringName(_cody.get("id", "cody")), way[0], cheater.global_position)
	if victim == null:
		_note("no Cody")
		_end(&"no_cody")
		return
	way.pop_front()
	_route = way
	_watch_men()
	played = true
	fact("nolaw.murder", "begun")
	_note("Cody comes in")
	# Shouting at Earl as he comes into the yard (Sean, 2026-11-12), not once he's at the table.
	_accused = true
	_accuse_t = t
	speak(victim, line("accuse"))
	_note("Cody accuses Earl")
	_go(&"come")


func _come(delta: float) -> void:
	var to_table := victim.global_position.distance_to(game.centre()) if game else INF
	if not _stopped and to_table < float(_cody.get("stop_m", 6.0)):
		_stop_all()
	if not _route.is_empty():
		if _walk(delta, _route[0], float(data.get("walk_speed", 1.6))):
			_route.pop_front()
		return
	# Earl out of his chair already (the game broke up, a shot of yours): no kick, straight to it.
	if chair.seated != cheater or cheater.limp:
		_stop_all()
		victim.stop_clip()
		_go(&"draw")
		return
	_target = _kick_spot()
	if _walk(delta, _target, float(data.get("walk_speed", 1.6))) or state_t > 20.0:
		victim.stop_clip()
		if not _stopped:
			_stop_all()
		speak(cheater, line("earl_reply"))
		_go(&"turn")


## The game held, you held in your seat, the stranger's warning, the room quiet.
func _stop_all() -> void:
	if _stopped:
		return
	_stopped = true
	if game:
		game.interrupt(&"cody", true)
	if _you_at_table():
		player().seat.hold(&"cody", String(data.get("hold_why", "Sit still.")))
		you_held = true
	if t - _accuse_t > float(_cody.get("warn_after_s", 1.8)):
		_warn()  # (else in a moment: his shout's still in the air)
	_hush(120.0)
	_hushed = true
	_note("the game stops; you're held: %s" % you_held)


## The stranger's hand on your arm: "Don't move, friend." (once).
func _warn() -> void:
	if _warned:
		return
	_warned = true
	if stranger != null and is_instance_valid(stranger):
		speak(stranger, line("stranger_warn"))


## Every folk man quiet for `s` (CivilianBrain.hush).
func _hush(s: float) -> void:
	for m: Variant in folk.people.values():
		if m is HumanBody and is_instance_valid(m):
			var b := (m as HumanBody).get_node_or_null(^"Brain") as CivilianBrain
			if b:
				b.hush(s)


func _stand_over() -> void:
	var head := (cheater.parts[&"head"] as Node3D).global_position
	victim.face(head)
	victim.set_pose(&"aim")
	if state_t > float(_cody.get("aim_s", 0.6)):
		_shoot_head()
		seen_from = _seen_from()
		fact("nolaw.murder", "earl")
		fact("nolaw.seen_from", seen_from)
		fact("nolaw.witnessed", seen_from in ["table", "yard"])
		_go(&"shot")


## Cody's ball from his muzzle into Earl's head (a real shot: Ballistics, the sound, the smoke, the
## flash, Events.shot_fired), as OutlawBrain fires his.
func _shoot_head() -> void:
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var gun := victim.held_gun as RevolverModel
	if ballistics == null or gun == null:
		_note("no gun or no ballistics")
		return
	var head := (cheater.parts[&"head"] as Node3D).global_position
	var origin := gun.muzzle.global_position
	var exclude: Array[RID] = []
	for sid: StringName in victim.parts:
		exclude.append((victim.parts[sid] as CollisionObject3D).get_rid())
	if victim.hat_body != null:
		exclude.append(victim.hat_body.get_rid())
	var dir := (head - origin).normalized()
	_clear_to_head(origin, head, exclude)
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	var bullet := ballistics.fire(origin, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter, exclude)
	bullet.form = t_rev.form_factor
	bullet.shooter = victim
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir)
	ImpactEffects.muzzle_flash(world, origin)
	if GameAudio.enabled():
		GameAudio.gunshot(victim, origin)
	Events.shot_fired.emit(origin, dir, victim)
	Events.deed.emit(victim, &"shoot_at", cheater, origin)
	shots += 1
	_shot_t = t
	_note("Cody shoots Earl in the head (%d)" % shots)


## What lies on the ball's line from his muzzle short of Earl's head is let through (`exclude`): the
## pieces of the chair Earl went over with, and Earl's own neck, arm or shoulder when Cody stands
## at his feet. He's stood over a man on the floor with the muzzle a pace from his head: the beat
## is that he doesn't miss, and how Earl's ragdoll came to lie mustn't decide the story. Measured
## (#925, 16 murders in fresh valleys): 2 left Earl alive after all three shots, one with every
## ball in a chair leg lying over his face, one with every ball in his neck. A wall or the table
## in the way isn't let through (it's left in, and the shot is what it is).
func _clear_to_head(origin: Vector3, head: Vector3, exclude: Array[RID]) -> void:
	var space := World.space(cheater)
	if space == null:
		return
	var head_part := cheater.parts[&"head"] as CollisionObject3D
	var own: Array = cheater.parts.values()
	for i in 24:
		var q := PhysicsRayQueryParameters3D.create(origin, head, Layers.BULLETS)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit.collider == head_part:
			return
		var c := hit.collider as CollisionObject3D
		if c == null or not (c is RigidBody3D or own.has(c)):
			return  # (something standing: a loose piece at rest is still a RigidBody3D, frozen)
		exclude.append(c.get_rid())


## Where you were for it: sat at the table, in the yard with it in front of you, in earshot, away.
func _seen_from() -> String:
	if _you_at_table():
		return "table"
	var p := player()
	if p == null:
		return "away"
	var seen: Dictionary = data.get("seen", {})
	var at := (cheater.parts[&"head"] as Node3D).global_position
	var d := p.global_position.distance_to(at)
	var to := at - p.global_position
	to.y = 0.0
	var fwd := p.get_forward()
	fwd.y = 0.0
	if d < float(seen.get("saw_m", 25.0)) and fwd.normalized().dot(to.normalized()) > 0.0:
		return "yard"
	if d < float(seen.get("heard_m", 400.0)):
		return "heard"
	return "away"


func _leave(delta: float) -> void:
	if _barkeep_t < 0.0 and state_t > 1.6:
		_barkeep_t = t
		if barkeep != null and is_instance_valid(barkeep) and barkeep.physiology.is_conscious():
			speak(barkeep, line("barkeep"))
			_note("the barkeep: my chair")
		_hush(float(data.get("hush_s", 3.0)))
	# Out of the yard (his way out walked): the after beats start, he walks on till he's gone.
	if _walk_way(victim, _route, float(data.get("walk_speed", 1.6)), delta) or _route.size() <= 2 or state_t > 30.0:
		_cody_going = 0.0
		_note("Cody's out of the yard")
		_end(&"done")


## Ends the beats (CardCheat's stalls too): the after beats play out from here.
func _end(s: StringName) -> void:
	end_reason = s
	_note("ends: %s" % s)
	if s != &"done":
		# Cut short (Cody shot down, a stall): nobody's held any longer.
		_release_you()
		if _hushed:
			_hush(0.0)
		if victim != null and is_instance_valid(victim) and victim.physiology.alive and not victim.limp:
			victim.set_pose(&"stand")
	_out_t = 0.0
	_go(&"after")


## Cody off down the street once he's out of the yard, till he's gone.
func _cody_walks(delta: float) -> void:
	if _cody_going < 0.0 or victim == null or not is_instance_valid(victim):
		return
	victim.wake()
	_cody_going += delta
	if victim.limp or not victim.physiology.alive:
		_cody_going = -1.0  # shot down on his way: he lies there
	elif _walk_off(victim, _route, float(data.get("walk_speed", 1.6)), delta, _cody_going):
		folk.release(StringName(_cody.get("id", "cody")))
		victim = null
		_cody_going = -1.0
		_note("Cody's gone")


func _release_you() -> void:
	if _let_go:
		return
	_let_go = true
	var p := player()
	if p != null and p.seat != null:
		p.seat.let_go(&"cody")
		if p.seat.seated():
			prompt("E: stand up", 2.0)


## After Cody's out: the stranger's word and his going, you let go, the drifter and miner off, the
## barkeep again; then it's done (the facts set).
func _after_step(delta: float) -> void:
	if victim != null and is_instance_valid(victim) and end_reason != &"done" and victim.physiology.alive and not victim.limp:
		victim.set_pose(&"stand")
	_cody_walks(delta)
	if _barkeep_t >= 0.0 and t - _barkeep_t > float((data.get("after", {}) as Dictionary).get("to_body_s", 3.0)):
		_barkeep_to_body()
	_barkeep_step(delta)
	var leave_s := float(_str.get("leave_s", 4.0))
	if state_t > leave_s and _str_state in [&"sat", &"walk", &"sit"]:
		if stranger != null and is_instance_valid(stranger) and end_reason == &"done":
			speak(stranger, line("stranger_word"))
		_release_you()
		_stranger_leaves()
	if end_reason == &"done":
		for id: String in (data.get("after", {}) as Dictionary).get("leave", {}):
			if not _sent.has(id) and state_t > float(data.after.leave[id]):
				_sent[id] = true
				folk.send_off(StringName(id))
				_note("%s leaves" % id)
	var left_all := end_reason != &"done" or _sent.size() >= ((data.get("after", {}) as Dictionary).get("leave", {}) as Dictionary).size()
	if _str_state in [&"leave", &"gone"] and left_all and (_barkeep_more or _barkeep_t < 0.0):
		_release_you()
		if played:
			fact("nolaw.murder", "done" if end_reason == &"done" else String(end_reason))
			fact("nolaw.earl", "dead" if cheater != null and is_instance_valid(cheater) and not cheater.physiology.alive else "alive")
		_finish(end_reason)


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"end": String(end_reason), "shots": shots, "you_held": you_held, "seen_from": seen_from,
			"stranger": String(_str_state), "stranger_chair": String(stranger_chair.name) if stranger_chair and is_instance_valid(stranger_chair) else "",
			"played": played, "chair_loose": chair != null and is_instance_valid(chair) and chair.loose, "strikes": strikes.duplicate(),
			"earl_fell": _fell_t >= 0.0, "earl_dead": cheater != null and is_instance_valid(cheater) and not cheater.physiology.alive,
			"game": String(game.state) if game else "", "events": events.duplicate()}
	if cheater != null and is_instance_valid(cheater):
		r["earl"] = cheater.physiology.describe()
	return r


## Take back what it put in the world (its men), and let everyone go; Earl, if dead, stays dead.
func reset() -> void:
	if Events.deed.is_connected(_on_deed):
		Events.deed.disconnect(_on_deed)
	_release_you()
	if game:
		game.let_go(&"cody")
	if folk != null and is_instance_valid(folk):
		for id: StringName in [StringName(_cody.get("id", "cody")), StringName(_str.get("id", "stranger"))]:
			if folk.state.get(id) == &"act":
				folk.release(id)
		if folk.murder == self:
			folk.murder = null
	queue_free()
