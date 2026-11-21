class_name NoJusticeCabin
extends Act
## No Justice, step 4 (#843's plan, #966; data config/moments/no_justice_cabin.json, its _doc has the
## whole scene; lines from docs/scripts/no_justice.json's cabin). From the hideout's end (step 3,
## NoJusticeHideout, handed over as `opts.hideout`): Kett barred in the line shack. You force the
## door (kicks that add up against the bar, a ball through it, or a way in through the wall's
## members); he gives himself up in the corner; Joe comes in behind you, draws his knife and asks
## "Are you going to stop me?". Your head answers (HeadGesture): a nod, the arrest; a shake, the
## revenge, on the wound system (HumanBody.take_knife), the camera never moving in; a small or slow
## nod, "Is that a yes?". Doing answers too: stepping between them or drawing on either of them
## stops him, walking out lets him. Shooting the man who's given up is the murder. Endings in
## StoryState `nojustice.ending`: arrest / revenge / murder / outside (killed in the fight).
##
## Kett is the hideout's: a HumanBody with no gun, run by this act till he's to be taken in, when
## he gets an OutlawBrain that's given up (so G arrests him and he walks bound behind you). Joe is
## the hideout's CompanionBrain, held while the scene walks him (SceneHold, #1050: `hold`, breaking on
## nothing: everything you do in here is an answer, so the cabin lets him go itself).

const ARREST := "arrest"
const REVENGE := "revenge"
const MURDER := "murder"
const OUTSIDE := "outside"

var hideout: NoJusticeHideout
var joe: HumanBody
var joe_brain: CompanionBrain
## Joe held by the scene from Kett's surrender to the answer's end (SceneHold; no breaks of its own).
var hold: SceneHold
var kett: HumanBody
var kett_brain: OutlawBrain
var shack: FalseFrontBuilding
var knife: Node3D
var ending := ""
var answer := ""
var forced_by := ""  # "kick", "shot", "wall", "down" (he lay outside: no door)
var kicked_j := 0.0
var kicked := 0.0  # sound standing kicks' worth (kick_share)
var kicks := 0
var shot_him := false  # your ball in him after he gave up
var joe_saw := false
var stabs := 0
var state_t := 0.0
var gesture := HeadGesture.new()
var loose := HeadGesture.new()
var _made: Array[Node] = []
var _spoken := {}
var _next_t := 0.0
var _loose_t := -1.0
var _between_t := 0.0
var _drawn_on := ""
var _drawn_t := 0.0
var _stab_t := 0.0
var _done_t := -1.0
var _ride_s := 0.0
var _jail: Node3D
var _surrendered := false
var _was_clear := false
var _clear_at := Vector2.INF
## Joe down at the hideout (#1116, Sean's): your first aid gets him up, a held E by his wound
## (`aid_s` of it, as the sheriff's on the road); he limps in himself, and the knife and the ask
## wait till he's there. No carry, no arm round him.
var aided := false
var aid_s := 0.0
var _aid_told_t := -INF
var _joe_way_t := 0.0


func begin() -> void:
	if opts.get("set_up", false):
		_set_up()
	hideout = opts.get("hideout") as NoJusticeHideout if opts.get("hideout") is NoJusticeHideout else hideout
	if hideout == null or not is_instance_valid(hideout) or hideout.kett == null:
		_finish(&"no_hideout")
		return
	joe = hideout.joe
	joe_brain = hideout.joe_brain
	if joe != null and is_instance_valid(joe) and joe_brain != null:
		JoeLost.watch(self, joe, joe_brain)
	kett = hideout.kett
	shack = hideout.shack
	Events.deed.connect(_on_deed)
	add_to_group(&"takes_kicks")
	add_to_group(&"claims_use")  # (E held by Joe down is your hands on his wound, not a kick)
	var p := player()
	if p == null or joe == null or not is_instance_valid(joe):
		_finish(&"no_player")
		return
	if p.shove:
		p.shove.landed.connect(_on_kick)
	var ks := String(StoryState.get_fact("nojustice.kett")) if StoryState.has_fact("nojustice.kett") else hideout.kett_state
	_note("from the hideout: Kett %s" % ks)
	if not kett.physiology.alive or ks in [NoJusticeHideout.DEAD_OUTSIDE, NoJusticeHideout.DEAD_INSIDE]:
		_end(OUTSIDE, hideout.kett_killer == p)
		return
	if ks == NoJusticeHideout.DOWN_OUTSIDE or not hideout.in_shack(kett.global_position):
		forced_by = "down"
		prompt(String(_prompts().get("down", "")), 6.0)
		_go(&"down")
		return
	prompt(String(_prompts().get("door", "")), 8.0)
	_go(&"barred")


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0
	_joe_way_t = 0.0
	_note("-> %s" % s)


## `-- --mission=no_justice_cabin` / the bridge's set_up: steps 1-3 done, the hideout set up and over
## (its crew dead about their fire), Kett barred in the shack (`kett=down_outside`: alive in the dirt
## by it), you and Joe 9 m off its door.
func _set_up() -> void:
	var h := Moment.start_named(&"no_justice_hideout", street, null,
			{"set_up": true, "arrive": true, "no_next": true, "pace": _pace(), "hour": float(opts.get("hour", 12.6))}) as NoJusticeHideout
	if h == null or h.shack == null:
		return
	hideout = h
	_made.append(h)
	h.alarm_t = 0.0  # (no alarm called: it's over)
	for g: Dictionary in h.crew:
		var man := g.man as HumanBody
		if is_instance_valid(man) and man.physiology.alive:
			man.physiology._die(&"heart")
	var down := String(opts.get("kett", "")) == NoJusticeHideout.DOWN_OUTSIDE or "--down" in OS.get_cmdline_user_args()
	if down:
		h.kett.global_position = h._shack_door(5.0) + Vector3(1.5, 0.05, 0.0)
		h.kett.take_push(h.kett.global_position + Vector3.UP * 1.0, Vector3.BACK, 120.0, 0.0, null)
		h.kett_state = NoJusticeHideout.DOWN_OUTSIDE
		fact("nojustice.kett", NoJusticeHideout.DOWN_OUTSIDE)
	else:
		var sd: Dictionary = h.data.get("shack", {})
		var inn: Array = sd.get("in", [0.0, 1.6])
		h.kett.global_position = h.shack.global_transform * Vector3(h.shack.width * 0.5 + float(inn[0]), h.shack.floor_top + 0.05, float(inn[1]) + 0.6)
		h._holed_up()
	fact("nojustice.started", "opened")
	fact("nojustice.crew", {"dead": h.crew.size(), "down": 0, "quit": 0, "fled": 0})
	fact("nojustice.seen", false)
	fact("nojustice.joe", "up")
	fact("nojustice.hideout", "fought")
	h._finish(StringName(h.kett_state))
	var p := player()
	if p:
		var at := h._shack_door(9.0)
		at.y = NoJusticeHideout._ground(at.x, at.z) + 0.1
		p.global_position = at
		p.velocity = Vector3.ZERO
		var to := h._shack_door(0.0) - at
		p.rotation.y = atan2(-to.x, -to.z)
		var jat := h._shack_door(10.0) + h.shack.global_basis.x * 1.6
		jat.y = NoJusticeHideout._ground(jat.x, jat.z) + 0.05
		h.joe.global_position = jat
		h.joe.rotation.y = HumanBody.yaw_toward(jat, h._shack_door(0.0))


# --- Where --------------------------------------------------------------------------------------

## A point of the shack's floor [x, z] (its own space).
func _local(xz: Array, up := 0.0) -> Vector3:
	return shack.global_transform * Vector3(float(xz[0]), shack.floor_top + up, float(xz[1]))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _prompts() -> Dictionary:
	return data.get("prompts", {})


func _door_member(which: String) -> StructureMember:
	if shack == null or not is_instance_valid(shack):
		return null
	var m := shack.get_member(StringName("%s/front/%s" % [shack.structure_id, which]))
	return m if m != null and not m.broken else null


## The way in's open: the door's leaf gone (kicked in, shot to pieces), or you're inside anyway.
func door_open() -> bool:
	return _door_member("door_shut") == null


func barred() -> bool:
	return _door_member("door_bar") != null


# --- The tick -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	state_t += delta
	card_step(delta)
	if done:
		return
	var p := player()
	if p == null or joe == null or not is_instance_valid(joe) or kett == null or not is_instance_valid(kett):
		return
	joe.wake()
	kett.wake()
	if _kett_died():
		return
	if answer == "" and state in [&"barred", &"down", &"in", &"knife"]:
		_aid_step(p, delta)
	match state:
		&"barred":
			_barred_step(p)
		&"down":
			if _flat(p.global_position, kett.global_position) < float(data.get("down_near_m", 4.0)):
				_surrender()
		&"in", &"knife", &"ask":
			_scene_step(p, delta)
		&"stop":
			_stop_step(p, delta)
		&"revenge":
			_revenge_step(p, delta)
		&"ride":
			if not card_up():
				p.input_enabled = true
				_at_jail()
		&"jail":
			_jail_step(p)
		&"after":
			# The revenge's end once he's gone (he bleeds out from it: #966's playtest had "it's over"
			# up while he lived).
			if ending == REVENGE and kett.physiology.alive and state_t < float(data.get("dies_within_s", 120.0)):
				return
			if ending == REVENGE and not _spoken.has("over"):
				_spoken["over"] = t
				prompt(String(_prompts().get(REVENGE, "")), 6.0)
				state_t = 0.0
			if state_t > float(data.get("after_s", 8.0)) * _pace():
				_release_joe()
				_finish(StringName(ending))


## At the barred door: his bluff as you come up, the kicks adding up (`_on_kick`), in when it's open.
func _barred_step(p: Player) -> void:
	if not _spoken.has("barred") and _flat(p.global_position, hideout._shack_door(0.0)) < float(data.get("barred_m", 7.0)):
		_say_once(kett, "barred")
	var in_by_door := door_open() and _flat(p.global_position, hideout._shack_door(-0.3)) < float(data.get("in_m", 1.0))
	if hideout.in_shack(p.global_position) or in_by_door:
		if forced_by == "":
			forced_by = "wall" if not door_open() else "shot"
		_note("in (%s)" % forced_by)
		_surrender()


## A kick lands: on the door, it counts against the bar (a barred door takes `bar_kicks` sound
## standing kicks, an unbarred one `door_kicks`) and gives all at once, bar and leaf inward; his second
## bluff at the first. Each kick counts by its speed against a sound standing kick's, squared (its
## energy), up to `kick_most` for one on the run: a leg already hurt counts less, always by the same
## amount, and the door takes the kick, not your foot (`takes_kick`: the count is the door's, not luck,
## #1111). A kick on the shack's wall instead says where the door is.
func _on_kick(info: Dictionary) -> void:
	if done:
		return
	# Hands (or a boot) on Joe while he has the knife: you're stopping him.
	if String(info.get("what", "")) == "man" and StringName(info.get("who", &"")) == joe.person_id and answer == "" \
			and state in [&"in", &"knife", &"ask"]:
		_answered("shoved_joe")
		return
	if state != &"barred" or String(info.get("move", "")) != "kick":
		return
	if not info.has("at") or not String(info.get("what", "")) in ["wall", "thing", "prop"]:
		return
	var at: Vector3 = info.at
	if not _in_doorway(at):
		_wrong_wall(at)
		return
	var e := 0.5 * float(info.get("mass", 0.0)) * pow(float(info.get("speed", 0.0)), 2.0)
	var share := kick_share(float(info.get("speed", 0.0)))
	kicked_j += e
	kicked += share
	kicks += 1
	var need := float(data.get("bar_kicks", 3.0)) if barred() else float(data.get("door_kicks", 1.0))
	_note("kick %d on the door: %.2f of a sound kick, %.0f J (%.2f of %.1f)" % [kicks, share, e, kicked, need])
	if kicks == 1:
		_say_again(kett, "barred")
	if kicked < need - 0.001:
		if kicks == 2:
			prompt(String(_prompts().get("holds", "")), 2.5)
		return
	var p := player()
	var inward := shack.global_basis.z
	for which: String in ["door_bar", "door_shut"]:
		var m := _door_member(which)
		if m != null:
			shack.break_member(m, inward * float(data.get("door_falls_mps", 0.8)))  # (falls in: the bridge's run had it flying into both men's legs)
	forced_by = "kick"
	prompt(String(_prompts().get("gives", "")), 3.0)  # (over the kick's own "it holds")
	GameAudio.play(p, &"timber_crack", hideout._shack_door(0.0) + Vector3.UP * 1.0, {"volume_db": 0.0})
	Events.noise.emit(hideout._shack_door(0.0), 30.0, &"crash", p)
	_note("the door gives")


## A kick at `speed` m/s as a share of a sound standing kick (the shove's own kick_speed): its
## energy's share, squared speed, up to `kick_most` (a running kick).
func kick_share(speed: float) -> float:
	var p := player()
	var sound := p.shove.tuning.kick_speed if p and p.shove and p.shove.tuning else 7.0
	return clampf(pow(speed / maxf(sound, 0.1), 2.0), 0.0, float(data.get("kick_most", 1.5)))


## On the door, or anything in its doorway (its jamb, its trim, a broken piece lying against it: the
## bridge's playtest kicked the jamb, then the loose trim, and never the leaf).
func _in_doorway(at: Vector3) -> bool:
	if shack == null or not is_instance_valid(shack):
		return false
	var l := shack.global_transform.affine_inverse() * at
	var dc := shack.door_rect.get_center().x
	return absf(l.x - dc) <= shack.door_rect.size.x * 0.5 + float(data.get("doorway_m", 0.45)) and l.z <= 0.6 and l.z >= -1.2 \
			and l.y <= shack.door_rect.end.y + 0.3


## The shack's door takes a kick (PlayerShove's `takes_kicks`): it gives a little each time while
## it's barred and shut, so your foot isn't hurt on it (the hurt foot made the count luck, #1111).
func takes_kick(_p: Player, at: Vector3, _info: Dictionary) -> bool:
	return not done and state == &"barred" and not door_open() and _in_doorway(at)


## A kick on the shack that isn't the door (playtest run 3 kicked its side wall nine times, told
## nothing): which way the door is from you.
func _wrong_wall(at: Vector3) -> void:
	var l := shack.global_transform.affine_inverse() * at
	if l.x < -0.4 or l.x > shack.width + 0.4 or l.z < -0.6 or l.z > shack.depth + 0.4 or l.y > 3.5:
		return  # (not the shack)
	var p := player()
	var words := String(_prompts().get("wall_round", "That's the wall. The door's round the front."))
	if l.z <= 0.6 and p != null:
		var to := hideout._shack_door(0.0) - p.global_position
		var right := p.camera.global_basis.x if p.camera else p.global_basis.x
		words = String(_prompts().get("wall_right" if to.dot(right) > 0.0 else "wall_left", words))
	prompt(words, 2.5)
	_note("kick on the shack's wall, not the door: " + words)


## In: hands up, backing into the corner, begging (cabin.surrender); Joe held and brought in behind
## you; his gun put up.
func _surrender() -> void:
	_surrendered = true
	_say_once(kett, "surrender")
	kett.face(player().camera.global_position)
	_next_t = t + _gap(line_preview("surrender"))
	_hold_joe()
	if joe.held_gun != null and not joe.gun_holstered:
		joe.holster_gun()
	_give_up_kett()  # (given up from now: G by him binds him, and that answers Joe too: #966's playtest)
	gesture = HeadGesture.new()
	_go(&"in")


## In, the knife and the ask: Kett backs to the corner, Joe in behind you, the knife, the bargain,
## then the question; meanwhile anything you do may answer.
func _scene_step(p: Player, delta: float) -> void:
	_kett_cornered(p, delta)
	if state in [&"in", &"knife"] and joe_down():
		return  # (Kett waits cornered; Joe's to be got up: `_aid_step`)
	if not joe.limp and not joe.prone and not joe.rising and (hideout.in_shack(joe.global_position) \
			or _flat(joe.global_position, kett.global_position) < float(data.get("joe_near_m", 7.0))):
		_joe_way_t += delta
	match state:
		&"in":
			var at := _joe_in_spot()
			if _joe_go(at, float(data.get("joe_walk", 1.1)) * 1.3, delta) \
					or _flat(joe.global_position, at) < 0.6 or _joe_stuck(at, delta):
				joe.face(kett.global_position + Vector3.UP * 1.3)
				if t >= _next_t and not _spoken.has("not_only"):
					_say_once(kett, "not_only")
					_next_t = t + _gap(line_preview("not_only"))
				elif _spoken.has("not_only") and t >= _next_t:
					_draw_knife()
					_say_once(joe, "knife")
					_next_t = t + _gap(line_preview("knife"))
					_joe_best = INF
					_joe_still = 0.0
					_go(&"knife")
		&"knife":
			var to := _joe_at_kett()
			# Held up on his way (the door's wreck, a body: the tests' order put a piece in his way, #1050)
			# he asks from where he stands, as walking in does: the scene never waits on him for good.
			var there := _joe_go(to, float(data.get("joe_walk", 1.1)), delta) or _joe_stuck(to, delta)
			joe.face(kett.global_position + Vector3.UP * 1.3)
			if t >= _next_t and not _spoken.has("bargain"):
				_say_once(kett, "bargain")
				_next_t = t + _gap(line_preview("bargain"))
			elif _spoken.has("bargain") and t >= _next_t and (_flat(joe.global_position, to) < 0.5 or there):
				joe.face(p.camera.global_position)
				_say_once(joe, "ask")
				prompt(String(_prompts().get("answer", "")), 10.0)
				gesture = HeadGesture.new()
				loose = _loose_gesture()
				_loose_t = -1.0
				_go(&"ask")
		&"ask":
			joe.face(p.camera.global_position)
			_read_head(p, delta)
			if ending == "" and answer == "" and state_t > float(data.get("answer_s", 25.0)) * _pace():
				_answered("none")
	if answer == "" and state in [&"in", &"knife", &"ask"]:
		_read_doing(p, delta)


func _loose_gesture() -> HeadGesture:
	var g := HeadGesture.new()
	var ld: Dictionary = data.get("loose", {})
	g.swing_deg = float(ld.get("swing_deg", 2.5))
	g.window_s = float(ld.get("window_s", 3.0))
	return g


## Your head: a plain nod or shake answers; a nod read only loosely (small, or slow) waits a moment
## for the plain one, then "Is that a yes?" and he waits again.
func _read_head(p: Player, delta: float) -> void:
	var yaw := rad_to_deg(p.rotation.y)
	var pitch := p.get_pitch_degrees()
	var g := gesture.feed(yaw, pitch, delta)
	var lg := loose.feed(yaw, pitch, delta)
	if g != &"":
		_answered(String(g))
		return
	if lg == &"nod" and _loose_t < 0.0:
		_loose_t = t
	if _loose_t >= 0.0 and t - _loose_t > float(data.get("unclear_wait_s", 0.5)):
		_loose_t = -1.0
		_say_again(joe, "unclear")
		state_t = 0.0  # (he waits again)
		gesture = HeadGesture.new()
		loose = _loose_gesture()


## What you do answers too: between them, or your gun on him or on Kett (a nod); out of the shack (a
## shake).
func _read_doing(p: Player, delta: float) -> void:
	# Between them: on the line from Joe to Kett, not off its ends.
	var me := Vector2(p.global_position.x, p.global_position.z)
	var between := _between(me)
	if not between and state != &"in":
		_was_clear = true  # (a step: standing there when the knife came out isn't one)
		_clear_at = me
	# You stepped into his way, not he round you: where you last stood clear of them must still be
	# clear of the line as it is now (run 3: Joe walked to Kett past a player standing still, and that
	# read as "between", a nod, #1111).
	if state != &"in" and between and _was_clear and not _between(_clear_at):
		_between_t += delta
		if _between_t > float(data.get("between_s", 0.5)):
			_answered("between")
			return
	else:
		_between_t = 0.0
	# Kett bound (G by him): you're taking him.
	if kett_brain != null and kett_brain.arrested_by == p:
		_answered("tied")
		return
	# Your gun on one of them (anywhere on him, from his hips to his head: a man a metre off is a
	# big target, #966's playtest drew on Joe close and it didn't count).
	var on := ""
	if CompanionBrain._gun_out(p):
		# The nearer of them in your sights (Kett stands behind Joe: it's Joe you're pointing at).
		var near := INF
		for who: HumanBody in [joe, kett]:
			var d := who.global_position.distance_to(p.global_position)
			if d < near and _sights_on(p, who):
				near = d
				on = "drew_on_joe" if who == joe else "drew_on_kett"
	if on != "" and on == _drawn_on:
		_drawn_t += delta
		if _drawn_t > float(data.get("drawn_s", 0.6)):
			_answered(on)
			return
	else:
		_drawn_on = on
		_drawn_t = 0.0
	# Out of the shack and off from its door (from him where he lies outside).
	var gone := _flat(p.global_position, kett.global_position) > float(data.get("walked_off_m", 9.0)) if forced_by == "down" \
			else not hideout.in_shack(p.global_position) and _flat(p.global_position, hideout._shack_door(0.0)) > float(data.get("walked_out_m", 4.0))
	if gone and state != &"in":
		_answered("walked_out")


## `at` (flat) on the line from Joe to Kett, not off its ends.
func _between(at: Vector2) -> bool:
	var a := Vector2(joe.global_position.x, joe.global_position.z)
	var b := Vector2(kett.global_position.x, kett.global_position.z)
	var ab := b - a
	var k := (at - a).dot(ab) / maxf(ab.length_squared(), 0.01)
	var off := (a + ab * clampf(k, 0.0, 1.0)).distance_to(at)
	return k > 0.1 and k < 0.9 and off < float(data.get("between_off_m", 0.45)) and ab.length() > 0.6


## Your look's line passes within `drawn_m` of him between his hips and his head (and he's near).
func _sights_on(p: Player, who: HumanBody) -> bool:
	var from := p.camera.global_position
	var dir := -p.camera.global_transform.basis.z
	var a := who.global_position + Vector3.UP * 0.6
	var b := who.global_position + Vector3.UP * 1.8
	if who.limp or who.prone:
		a = who.global_position + Vector3.UP * 0.1
		b = a + Vector3.UP * 0.4
	if from.distance_to(a) > 15.0:
		return false
	var best := INF
	for i in 9:
		var q := a.lerp(b, i / 8.0)
		var along := (q - from).dot(dir)
		if along <= 0.0:
			continue
		best = minf(best, (from + dir * along).distance_to(q))
	return best < float(data.get("drawn_m", 0.3))


## Your answer: a nod (or stopping him) the arrest's way; a shake (walking out, saying nothing) the
## revenge's.
func _answered(how: String) -> void:
	if answer != "":
		return
	answer = how
	_note("answer: " + how)
	fact("nojustice.answer", how)
	if how in ["nod", "between", "drew_on_joe", "drew_on_kett", "shoved_joe", "tied"]:
		_say_once(joe, "nod")
		_next_t = t + _gap(line_preview("nod"))
		_put_knife_away()
		_go(&"stop")
	else:
		_stab_t = 0.4 * _pace()
		_go(&"revenge")


## Stopped: he steps back to the door with the knife put away; Kett's relief; then you take him (G).
func _stop_step(p: Player, delta: float) -> void:
	if forced_by != "down":
		_walk(joe, _local(data.get("joe_back", [2.9, 0.8])), float(data.get("joe_walk", 1.1)), delta)
	_kett_cornered(p, delta)
	if not _spoken.has("thanks") and t >= _next_t:
		_say_once(kett, "thanks")
		_next_t = t + _gap(line_preview("thanks"))
		if kett_brain == null or kett_brain.arrested_by != p:
			prompt(String(_prompts().get("take", "")), 8.0)
	if kett_brain != null and kett_brain.arrested_by == p and _spoken.has("thanks") and t >= _next_t:
		_end(ARREST)
		_ride_back()


## Kett, given up: an OutlawBrain SURRENDERED (with nothing to say but the script's), so G binds him
## and he walks behind you.
func _give_up_kett() -> void:
	if kett_brain != null:
		return
	var b := OutlawBrain.new()
	b.name = "Brain"
	b.nerve = 0.1
	b.temper = 0.1
	for k: StringName in OutlawBrain.LINES:
		b.own_lines[k] = []
	if hideout.folk:
		b.places = hideout.folk.places
	kett.add_child(b)
	kett.move_child(b, 0)
	kett_brain = b
	(func() -> void:
		if is_instance_valid(b) and b.mood != OutlawBrain.Mood.SURRENDERED:
			b._surrender()).call_deferred()


## The shake: Joe's knife, on the wound system (stabs to the chest and belly, then across the neck),
## from where you are (nothing moves your view); then "It is done." and the long quiet.
func _revenge_step(p: Player, delta: float) -> void:
	var sd: Dictionary = data.get("stab", {})
	if _done_t >= 0.0:
		joe.set_pose(&"stand")
		if not _spoken.has("done") and t - _done_t > float(data.get("done_wait_s", 3.0)) * _pace():
			_put_knife_away()
			_say_once(joe, "done")
			_end(REVENGE)
		return
	var to := _joe_at_kett(0.6)
	_joe_go(to, float(data.get("joe_walk", 1.1)) * 1.2, delta)
	joe.face(kett.global_position + Vector3.UP * 1.2)
	if _flat(joe.global_position, kett.global_position) > 0.95:
		_over_the_pieces(to, delta)
		return
	_stab_t -= delta
	if _stab_t > float(sd.get("every_s", 0.9)) * 0.45 * _pace():
		joe.set_pose(&"aim")  # (the arm out with the blade: a stand-in for a stab's motion)
	else:
		joe.set_pose(&"stand")
	if _stab_t > 0.0:
		return
	var down := kett.limp or not kett.physiology.is_conscious() or not kett.physiology.alive
	if down or stabs >= int(sd.get("most", 7)):
		_done_t = t
		_note("Kett down after %d cuts (%s)" % [stabs, kett.physiology.describe()])
		return
	_stab_t = float(sd.get("every_s", 0.9)) * _pace()
	_cut(sd)


func _cut(sd: Dictionary) -> void:
	var segs: Array = sd.get("segments", ["abdomen", "chest"])
	var slash := stabs >= int(sd.get("slash_after", 3)) and stabs % 2 == 1
	var seg := StringName("neck" if slash else String(segs[stabs % segs.size()]))
	if not kett.parts.has(seg):
		seg = &"chest"
	var part := kett.parts[seg] as Node3D
	var from := joe.global_position + Vector3.UP * 1.2
	var dir := part.global_position - from
	dir = dir.normalized() if dir.length() > 0.01 else -kett.global_basis.z
	var r := float((kett.anatomy.segments[seg] as Dictionary).get("radius", 0.1)) if kett.anatomy.segments.has(seg) else 0.1
	var skin := part.global_position - dir * (r + 0.01)
	kett.set_meta(&"last_hit_by", joe)
	if slash:
		var across := dir.cross(Vector3.UP).normalized()
		kett.take_knife(part, skin - across * float(sd.get("slash_m", 0.09)) * 0.5, dir, false, 0.03, across, float(sd.get("slash_m", 0.09)))
	else:
		kett.take_knife(part, skin, dir, true, float(sd.get("depth", 0.13)))
	stabs += 1
	_note("Joe's knife: %s %s" % ["slash" if slash else "stab", seg])
	GameAudio.play(joe, &"thump", skin, {"volume_db": -14.0})


## Kett till he's given up to the law: hands up, backing into the corner, facing you (on the floor
## where he lay, if he lay outside).
func _kett_cornered(p: Player, delta: float) -> void:
	if kett_brain != null and kett_brain.arrested_by != null:
		return  # (bound: he goes where he's taken)
	if forced_by == "down" or kett.rising or kett.prone or not kett.physiology.can_stand():
		return
	if kett.limp:
		if kett.physiology.is_conscious():
			kett.get_up()  # (knocked over in there: back up, hands up)
		return
	kett.set_pose(&"hands_up")
	var c := _local(data.get("corner", [0.75, 4.3]))
	if _flat(kett.global_position, c) > 0.25:
		kett.walk_to(c, float(data.get("kett_walk", 0.9)), delta, false)
	kett.face(p.camera.global_position)


## Joe's come in as far as he'll get: stopped short of you (or anything) for `stuck_s` once he's in
## the shack (or by Kett outside), or `in_most_s` on the way at all (he speaks from where he is).
func _joe_stuck(at: Vector3, delta: float) -> bool:
	var d := _flat(joe.global_position, at)
	if d < _joe_best - 0.05:
		_joe_best = d
		_joe_still = 0.0
	else:
		_joe_still += delta
	var in_it := hideout.in_shack(joe.global_position) or forced_by == "down" and _flat(joe.global_position, kett.global_position) < 3.0
	# (`in_most_s` counts only while he's up and near: limping in from far off on a splinted leg takes
	# as long as it takes, #1116; held up anywhere else, `far_stuck_s` without getting nearer.)
	return in_it and _joe_still > float(data.get("stuck_s", 1.5)) or _joe_way_t > float(data.get("in_most_s", 14.0)) \
			or _joe_still > float(data.get("far_stuck_s", 8.0))


var _joe_best := INF
var _joe_way: Array[Vector3] = []
var _joe_still := 0.0


## Joe's spot inside the door (or, Kett outside, by you toward him).
func _joe_in_spot() -> Vector3:
	if forced_by == "down":
		return _joe_at_kett(1.8)
	# Inside the door to one side, the side you're not.
	var xz: Array = data.get("joe_in", [3.3, 1.5])
	var a := _local(xz)
	var b := _local([shack.width - float(xz[0]), xz[1]])
	var p := player()
	return a if _flat(a, p.global_position) >= _flat(b, p.global_position) else b


## Joe's spot at Kett: `off_m` short of him, on the side he comes from.
func _joe_at_kett(off_m := -1.0) -> Vector3:
	var off := off_m if off_m > 0.0 else float(data.get("joe_off_kett_m", 0.8))
	var from := joe.global_position - kett.global_position
	from.y = 0.0
	from = from.normalized() if from.length() > 0.05 else -kett.global_basis.z
	return kett.global_position + from * off


## Joe toward `to`, by the doorway while he's outside and Kett's in (walk_to finds no doors): out
## front of it, through it, then on. True there.
func _joe_go(to: Vector3, speed: float, delta: float) -> bool:
	if forced_by != "down" and not hideout.in_shack(joe.global_position) and _joe_way.is_empty():
		_joe_way = [hideout._shack_door(1.2), hideout._shack_door(-0.5)]
	while not _joe_way.is_empty() and (_flat(joe.global_position, _joe_way[0]) < 0.35 \
			or _joe_way.size() == 2 and hideout.in_shack(joe.global_position)):
		_joe_way.pop_front()
	if not _joe_way.is_empty():
		_walk(joe, _joe_way[0], speed, delta)
		_over_the_wreck(delta)
		return false
	return _walk(joe, to, speed, delta)


## The broken door lies in the doorway in pieces, and a man's walk_to stops short of them (you push
## through; he won't): held up on the sill `wreck_s`, he steps over it.
func _over_the_wreck(delta: float) -> void:
	var l := shack.global_transform.affine_inverse() * joe.global_position
	var on_sill := absf(l.z) < 0.6 and absf(l.x - shack.width * 0.5) < 0.8
	var moved := joe.global_position.distance_to(_sill_at)
	if not on_sill or moved > 0.08:
		_sill_at = joe.global_position
		_sill_t = 0.0
		return
	_sill_t += delta
	if _sill_t > float(data.get("wreck_s", 1.5)):
		_sill_t = 0.0
		var over := shack.global_transform * Vector3(shack.width * 0.5, shack.floor_top + 0.05, 0.7)
		joe.global_position = over
		_joe_way.clear()
		_note("Joe over the broken door")


var _sill_at := Vector3.INF
var _sill_t := 0.0


## Inside, the door's pieces (or a body) between him and Kett: his walk stops short of them as on the
## sill (#1092: on CI he stood 2.2 m off with the knife out and never reached him). No nearer for
## `wreck_s`, he steps over them to Kett.
func _over_the_pieces(to: Vector3, delta: float) -> void:
	var d := _flat(joe.global_position, to)
	if d < _over_best - 0.05 or not hideout.in_shack(joe.global_position):
		_over_best = d
		_over_t = 0.0
		return
	_over_t += delta
	if _over_t > float(data.get("wreck_s", 1.5)):
		_over_t = 0.0
		_over_best = INF
		joe.global_position = Vector3(to.x, joe.global_position.y, to.z)
		_joe_way.clear()
		_note("Joe over the pieces to Kett")


var _over_best := INF
var _over_t := 0.0


## Walk a man toward `to` (true there).
func _walk(man: HumanBody, to: Vector3, speed: float, delta: float) -> bool:
	if _flat(man.global_position, to) < 0.3 or man.limp:
		return true
	man.set_pose(&"stand")
	return man.walk_to(to, speed, delta)


# --- Joe down: your first aid (#1116) -------------------------------------------------------------

## Joe alive and off his feet (limp or on his belly, not getting up): the scene waits for him.
func joe_down() -> bool:
	return joe.physiology.alive and (joe.limp or joe.prone) and not joe.rising


## E is your hands on Joe's wound while he's down and you're by it (PlayerShove: no kick on letting go).
func claims_use(p: Player) -> bool:
	return not done and answer == "" and joe != null and is_instance_valid(joe) and joe_down() and _by_joe(p)


func _by_joe(p: Player) -> bool:
	var at := _joe_wound_at()
	return _flat(p.global_position, at) <= float(data.get("aid_reach_m", 2.0)) and absf(p.global_position.y - at.y) < 2.0


## Where he's hurt: his worst outside bleed's part, else a broken leg's thigh, else his middle.
func _joe_wound_at() -> Vector3:
	var seg := _joe_wound()
	var n := joe.parts.get(seg) as Node3D if seg != &"" else null
	return n.global_position if n != null else OutlawBrain._lying_at(joe)


func _joe_wound() -> StringName:
	var ph := joe.physiology
	var worst: Dictionary = {}
	for b: Dictionary in ph.bleeds:
		if b.get("kind", &"ooze") != &"internal" and not b.get(&"bandaged", false) \
				and (worst.is_empty() or ph.bleed_rate(b) > ph.bleed_rate(worst)):
			worst = b
	if not worst.is_empty():
		return StringName(worst.segment)
	for side: String in ["r", "l"]:
		if not ph.leg_ok(side):
			return StringName("thigh_" + side)
	return &""


## Joe down: once you're near, the game says what to do; a held E by his wound (past a tap, which is
## the carry's) for `aid_s` packs and binds every wound and splints a leg that won't hold him
## (Physiology.bind_up). CompanionBrain gets him up then (`_get_back_up`: "I can walk").
func _aid_step(p: Player, delta: float) -> void:
	if not joe_down():
		aid_s = 0.0
		return
	var near := _flat(p.global_position, joe.global_position) < float(data.get("aid_told_m", 8.0))
	if near and not aided and t - _aid_told_t > float(data.get("aid_told_every_s", 12.0)):
		_aid_told_t = t
		prompt(String(_prompts().get("joe_down", "Joe's down. Kneel by his wound and hold E.")), 4.0)
	var tap_s := p.tuning.carry_tap_s if p.tuning else 0.35
	var holding := p.input_enabled and Input.is_action_pressed(&"shove") and _by_joe(p) \
			and (p.carry == null or not p.carry.carrying())
	_aid_e = _aid_e + delta if holding else 0.0
	if _aid_e <= tap_s:
		return
	var seg := _joe_wound()
	if seg != &"":
		joe.physiology.apply_pressure(seg)
	aid_s += delta
	if aid_s >= float(data.get("aid_s", 5.0)):
		aid_s = 0.0
		_bind_joe()


var _aid_e := 0.0


func _bind_joe() -> void:
	var ph := joe.physiology
	var segs := {}
	for b: Dictionary in ph.bleeds:
		if b.get("kind", &"ooze") != &"internal":
			segs[StringName(b.segment)] = true
	for side: String in ["r", "l"]:
		if not ph.leg_ok(side):
			segs[StringName("thigh_" + side)] = true
	for seg: StringName in segs:
		ph.bind_up(seg)
	aided = true
	_joe_still = 0.0
	_joe_best = INF
	_joe_way_t = 0.0
	if not ph.can_stand():
		prompt(String(_prompts().get("joe_bound", "Bound up. He can't stand yet.")), 3.0)
	_note("Joe's wounds bound (%s); can stand: %s" % [", ".join(segs.keys().map(func(k: StringName) -> String: return String(k))), ph.can_stand()])


# --- The knife ----------------------------------------------------------------------------------

## Joe's knife: in his right hand only (his gun holstered). A stand-in: a blade and a grip.
func _draw_knife() -> void:
	if knife != null or not joe.visuals.has(&"hand_r"):
		return
	if joe.held_gun != null and not joe.gun_holstered:
		joe.holster_gun(true)
	var vis := joe.visuals[&"hand_r"] as Node3D
	knife = Node3D.new()
	knife.name = "Knife"
	vis.add_child(knife)
	knife.position = joe.anatomy.rest_point(&"hand_r", Vector3(0.232, 0.765, -0.05)) - joe.anatomy.segment_center(&"hand_r")
	knife.rotation_degrees = Vector3(-90, 0, 0)
	var blade := GunParts.box(knife, "Blade", Vector3(0.006, 0.03, 0.2), Vector3(0.0, 0.0, -0.15), GunParts.blued())
	var grip := GunParts.box(knife, "Grip", Vector3(0.022, 0.03, 0.11), Vector3(0.0, 0.0, -0.0), GunParts.walnut())
	for mi: MeshInstance3D in [blade, grip]:
		mi.layers = Layers.VIS_BODY
	joe.curl_hand("r", 0.85)
	_note("Joe's knife out")


func _put_knife_away() -> void:
	if knife != null and is_instance_valid(knife):
		knife.queue_free()
	knife = null
	if joe and is_instance_valid(joe):
		joe.curl_hand("r", 0.25)


# --- Shot, dead ---------------------------------------------------------------------------------

## A ball in him: yours, after he gave up, is the murder (Joe's line if he saw it). (Ballistics' hit
## deed carries the shooter; the body's hit signal doesn't.)
func _on_deed(actor: Node, kind: StringName, deed_target: Node, _at: Vector3) -> void:
	if done or not _surrendered or ending != "" or kind != &"hit" or deed_target != kett or actor != player():
		return
	shot_him = true
	joe_saw = joe.physiology.is_conscious() and _flat(joe.global_position, kett.global_position) < 12.0
	_note("you shot the man who'd given up (Joe %s)" % ("saw" if joe_saw else "didn't see"))
	if joe_saw and not _spoken.has("murder"):
		_put_knife_away()
		joe.face(player().camera.global_position)
		_say_once(joe, "murder")


## Kett dead: the murder if your ball's in him since he gave up, Joe's revenge if it's his knife,
## else killed in the fight (outside). True once it's ended.
func _kett_died() -> bool:
	if ending != "" or kett.physiology.alive:
		return false
	var by: Variant = kett.get_meta(&"last_hit_by") if kett.has_meta(&"last_hit_by") else null
	if shot_him and by == player():
		_end(MURDER)
	elif state == &"revenge" or by == joe:
		_put_knife_away()
		_say_once(joe, "done")
		_end(REVENGE)
	else:
		_end(OUTSIDE, by == player())
	return true


## The ending: its facts (and what it leaves Joe and the camp), then the quiet and the act's end.
func _end(how: String, yours := false) -> void:
	if ending != "":
		return
	ending = how
	fact("nojustice.ending", how)
	var tr: Dictionary = (data.get("trust", {}) as Dictionary).get("outside_yours" if how == OUTSIDE and yours else how, {})
	fact("nojustice.joe_trust", String(tr.get("joe", "")))
	fact("nojustice.camp_trust", String(tr.get("camp", "")))
	if how == MURDER:
		fact("nojustice.joe_saw", joe_saw)
	if how in [REVENGE, MURDER]:
		fact("nojustice.bodies", "left")
	if how == OUTSIDE and yours and joe.physiology.is_conscious() and not hideout._spoken.has("mine"):
		_say_once(joe, "mine")
	if how != REVENGE:
		prompt(String(_prompts().get(how, "")), 6.0)
	if how != ARREST:
		if state in [&"barred", &"down", &"setup"] and how == OUTSIDE:
			_release_joe()
			_finish(StringName(how))
			return
		_go(&"after")


func _release_joe() -> void:
	_put_knife_away()
	_let_joe_go()


## The shared hold (SceneHold, #1050) on Joe in the shack: its quiet zone the shack and the yard by its
## door. It breaks on nothing: a gun drawn, a shove, a ball, all are your answer here (`_answered`).
func _hold_joe() -> void:
	if hold != null and hold.on:
		return
	hold = SceneHold.claim(self, {"label": &"no_justice_cabin", "cast": [joe], "follow": shack,
			"radius": float(data.get("hold_m", 6.0)), "breaks": [], "make_way": false, "keep_armed": false})


func _let_joe_go() -> void:
	if hold != null and is_instance_valid(hold):
		hold.release()
	if joe_brain and is_instance_valid(joe_brain):
		joe_brain.held = false


# --- The arrest's way back ----------------------------------------------------------------------

## The ride back's a card (riding isn't built, #478): the shack to the jail at a walk, the clock on.
func _ride_back() -> void:
	var jd: Dictionary = data.get("jail", {})
	var bs: Variant = street.get(&"buildings") if street else null
	_jail = (bs as Dictionary).get(String(jd.get("building", "jail"))) if bs is Dictionary else null
	if _jail == null:
		_note("no jail building: the arrest ends at the shack")
		_go(&"after")
		return
	var metres := _flat(shack.global_position, _jail.global_position)
	_ride_s = metres / float(jd.get("mps", 1.8))
	card(String((data.get("cards", {}) as Dictionary).get("back", "You ride back to Salt Creek.")).replace("%d", str(roundi(_ride_s / 60.0))), float(data.get("card_s", 8.0)) * _pace())
	var c := clock()
	if c:
		c.set_time(c.time_of_day + _ride_s / 3600.0)
	player().input_enabled = false
	_go(&"ride")


func _jail_local(xz: Array) -> Vector3:
	var at := _jail.global_transform * Vector3(float(xz[0]), 0.0, float(xz[1]))
	at.y = (hideout.folk.ground(at.x, at.z) if hideout.folk else NoJusticeHideout._ground(at.x, at.z))
	return at


## On Main Street before the jail: you, Kett bound behind you, Joe by you; walk him to its door.
func _at_jail() -> void:
	var jd: Dictionary = data.get("jail", {})
	var p := player()
	var door := _jail_local(jd.get("door", [5.49, -0.6]))
	var at := _jail_local(jd.get("you", [5.49, -7.0]))
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO
	var to := door - at
	p.rotation.y = atan2(-to.x, -to.z)
	var ka := _jail_local(jd.get("kett", [6.6, -8.4]))
	if kett.limp:
		kett.get_up()
	kett.global_position = ka + Vector3.UP * 0.05
	var ja := _jail_local(jd.get("joe", [4.1, -8.2]))
	joe.global_position = ja + Vector3.UP * 0.05
	joe.rotation.y = HumanBody.yaw_toward(ja, door)
	_let_joe_go()
	prompt(String(_prompts().get("jail", "")), 6.0)
	_go(&"jail")


func _jail_step(p: Player) -> void:
	var jd: Dictionary = data.get("jail", {})
	if not _spoken.has("back_kett") and state_t > float(jd.get("kett_says_s", 4.0)) * _pace():
		_say_once(kett, "back_kett")
	if not _spoken.has("back_joe_kett") and state_t > float(jd.get("joe_says_s", 11.0)) * _pace():
		_say_once(joe, "back_joe_kett")
	var door := _jail_local(jd.get("door", [5.49, -0.6]))
	var near := float(jd.get("near_m", 3.0))
	var kett_there := _flat(kett.global_position, door) < float(jd.get("kett_near_m", 4.5)) or not kett.physiology.can_stand()
	if _flat(p.global_position, door) < near and kett_there:
		card(String((data.get("cards", {}) as Dictionary).get("jailed", "You lock Kett in a cell.")), 4.0 * _pace())
		fact("nojustice.jail", "in")
		prompt(String(_prompts().get("jailed", "")), 8.0)
		kett.visible = false  # (in his cell: the stand-in)
		kett.global_position = _jail_local([8.9, 16.0]) + Vector3.UP * 0.7
		_go(&"after")


# --- Lines --------------------------------------------------------------------------------------

func line_preview(beat: String) -> String:
	var by: Variant = (data.get("lines", {}) as Dictionary).get(beat, {})
	var l: Variant = (by as Dictionary).get("any", "") if by is Dictionary else by
	return String(l[0]) if l is Array and not (l as Array).is_empty() else String(l)


func _say_once(man: HumanBody, beat: String) -> void:
	if _spoken.has(beat):
		return
	_say_again(man, beat)


## Said again (the beat's next line, the last kept).
func _say_again(man: HumanBody, beat: String) -> void:
	_spoken[beat] = t
	var text := line(beat)
	if text == "" or man == null or not is_instance_valid(man) or not man.physiology.is_conscious():
		return
	speak(man, text)
	_note("%s: %s" % [man.person_id, text])


func _gap(text: String) -> float:
	return maxf(float(data.get("gap_min_s", 2.2)), float(text.length()) / float(data.get("cps", 13.0)) + 0.8) * _pace()


func _pace() -> float:
	return clampf(float(opts.get("pace", 1.0)), 0.05, 4.0)


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"ending": ending, "answer": answer, "forced_by": forced_by, "kicks": kicks, "kicked": snappedf(kicked, 0.01), "kicked_j": snappedf(kicked_j, 1.0),
			"door_open": door_open() if shack else false, "barred": barred() if shack else false, "stabs": stabs,
			"shot_him": shot_him, "joe_saw": joe_saw, "knife": knife != null}
	var p := player()
	if p and kett and is_instance_valid(kett):
		r["kett"] = {"alive": kett.physiology.alive, "conscious": kett.physiology.is_conscious(), "limp": kett.limp,
				"pose": String(kett.pose), "in_shack": hideout.in_shack(kett.global_position) if hideout else false,
				"brain": "" if kett_brain == null else String(OutlawBrain.Mood.keys()[kett_brain.mood]),
				"to_you_m": snappedf(_flat(kett.global_position, p.global_position), 0.1)}
	if p and joe and is_instance_valid(joe):
		r["joe"] = {"held": joe_brain.held, "to_kett_m": snappedf(_flat(joe.global_position, kett.global_position), 0.1) if kett else -1.0,
				"to_you_m": snappedf(_flat(joe.global_position, p.global_position), 0.1)}
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-16)
	return r


## Take back what it made, and the hideout it set up (the bridge, the tests).
func reset() -> void:
	_put_knife_away()
	if kett_brain and is_instance_valid(kett_brain):
		kett_brain.queue_free()
	if hideout and is_instance_valid(hideout) and (_made.has(hideout) or opts.get("hideout") == hideout):
		hideout.reset()
	for n: Node in _made:
		if is_instance_valid(n) and n != hideout:
			n.queue_free()
	var p := player()
	if p:
		p.input_enabled = true
	queue_free()
