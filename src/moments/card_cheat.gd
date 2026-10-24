class_name CardCheat
extends Moment
## The card cheat (docs/briefs/showcase-moments.md; Sean's favourite): Earl sits back at the
## saloon's card table; Cody, cheated the day before, walks in angry (clip `walk_angry`), comes up
## with his back to Earl's chair and kicks its back legs out behind him (clip `kick_back`: his
## boot meets the real legs, KitProp.take_blow decides), Earl goes over backwards with it (the
## chair's balance and the ragdoll), Cody draws (clip `draw`) and stands over him with the gun in
## his face (clip `stand_over`), shouting. It holds a few seconds and times out: no one dies yet.
##
## The clips lead the men's poses while physics has the last word (HumanBody.play_clip). With no
## clips (none made yet, or `animated=0`), the same beat plays pose to pose: the `kick` pose as
## #204's scene, the blow given by script at its landing.
##
## Data: config/moments/card_cheat.json (who, where, the hour, the clips, the lines, the timings).
## Bridge: `moment card_cheat [animated=0] [hour=H]`, `moment_result [wait]`.

const KICK_POSE_LANDS := 0.23  ## s into the kick pose the boot lands (#204's scene: 14 ticks)
const KICK_POSE_IMPULSE := 48.0  ## N·s a kicking leg gives (the chair lab's)
const WALK_ARRIVE := 0.3  ## m
const STEER_RATE := 6.0  ## /s, turning as he walks on a clip

var chair: KitProp
var cheater: HumanBody
var victim: HumanBody
var animated := true
var clips := {}  ## beat -> clip name, only those that exist
var state_t := 0.0
var events := []  ## [[t, what]]
var strikes := []  ## the boot's results
var chair_was: Transform3D
var chair_parent: Node
var _target := Vector3.ZERO
var _back := Vector3.FORWARD  ## the way the chair's back faces (out of the back posts)
var _head_spot := Vector3.ZERO
var _said := 0
var _fell_t := -1.0
var _loose_t := -1.0
var _kick_t := -1.0
var _kicked_pose := false


func begin() -> void:
	animated = bool(int(opts.get("animated", 1 if data.get("animated", true) else 0)))
	for beat: String in data.get("clips", {}):
		var n := StringName(data.clips[beat])
		if animated and MotionClip.load_clip(n) != null:
			clips[beat] = n
	set_hour()
	var table: Array = data.get("table", [7.6, 0.78, 4.2])
	var table_at := Vector3(table[0], table[1], table[2])
	var enter := point("enters_at", "enters_at_point", data.victim)
	# `seed=N` (the runs): the men's own randomness and a hand's width on where Cody comes in, so
	# twenty runs are twenty (the simulation is otherwise the same every time).
	var seed_n := int(opts.get("seed", 0))
	if seed_n > 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_n
		enter += Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.08, 0.08))
	chair = _pick_chair(table_at, enter)
	if chair == null:
		_note("no free chair at the table")
		_finish(&"no_chair")
		return
	chair_was = chair.global_transform
	chair_parent = chair.get_parent()
	_back = -chair.global_basis.z
	_back.y = 0.0
	_back = _back.normalized()
	chair.went_loose.connect(func() -> void: _loose_t = t; _note("the chair went loose"))
	# Earl, already in his chair as the beat begins (he's been at the table a while): posed sitting
	# back first, his weight on the seat half a second on, as the chair lab sat its men (sat down
	# standing-posed, his weight settles on the seat wrong and the fall goes forward).
	var spot := Seating.spot(chair)
	cheater = _man(data.cheater, spot, Seating.faces(chair), false)
	cheater.set_pose(&"sit_back")
	cheater.fell.connect(func(_c: bool) -> void: _fell_t = t; _note("Earl fell"))
	# Cody at the door.
	victim = _man(data.victim, enter, spot, true)
	victim.clip_struck.connect(func(m: Node, r: StringName, speed: float) -> void:
		strikes.append(String(r))
		_note("Cody's boot %s %s at %.1f m/s" % [{&"broke": "broke", &"moved": "shifted", &"held": "stopped on"}.get(r, "met"), m.name, speed]))
	victim.clip_event.connect(func(_c: StringName, ev: String) -> void:
		if ev == "draw":
			victim.draw_gun())
	state = &"sitting"


func _man(d: Dictionary, at: Vector3, faces: Vector3, armed: bool) -> HumanBody:
	var m := HumanBody.new()
	m.body_model = StringName(d.get("model", "outlaw"))
	m.person_id = StringName(d.get("id", "man"))
	m.name = String(d.get("name", String(m.person_id)))
	m.rng_seed = int(d.get("seed", 1)) + int(opts.get("seed", 0)) * 7
	m.has_gun = armed
	m.start_holstered = true
	m.enter(street, at, HumanBody.yaw_toward(at, faces))
	return m


## The free kit chair at the table whose back faces the way Cody comes from.
func _pick_chair(table_at: Vector3, from: Vector3) -> KitProp:
	var best: KitProp = null
	var best_k := -INF
	for s: Node in get_tree().get_nodes_in_group(&"structures"):
		var kp := s as KitProp
		if kp == null or kp.kit_id != &"chair" or kp.loose or kp.seated != null or not kp.is_inside_tree():
			continue
		var seat := kp.seat_position()
		if Vector2(seat.x - table_at.x, seat.z - table_at.z).length() > 1.6:
			continue
		var back := -kp.global_basis.z
		var to := from - seat
		to.y = 0.0
		var k := back.normalized().dot(to.normalized())
		if k > best_k:
			best_k = k
			best = kp
	return best


func _physics_process(delta: float) -> void:
	if done:
		return
	t += delta
	state_t += delta
	if state_t > float(data.get("beat_timeout_s", 12.0)):
		_note("stalled in %s" % state)
		_end(&"stalled_" + state)
		return
	# Down with a man standing over him, Earl stays down (a conscious man gets up again on his
	# own, HumanBody.get_up; a gun in his face is reason not to).
	if cheater.limp and _fell_t >= 0.0:
		cheater.rise_ok = false
	match state:
		&"sitting":
			if state_t > 0.6:
				if not chair.sit(cheater):
					_note("Earl couldn't sit (the chair's taken or loose)")
					_end(&"no_seat")
					return
				_note("Earl's sat back")
				_target = _kick_spot()
				_go(&"walk")
		&"walk":
			if _walk(delta, _target, float(data.get("walk_speed", 1.7))):
				victim.stop_clip()
				_go(&"turn")
		&"turn":
			# The last step onto his mark and round to his kicking line (a kick's line is a hand's
			# width: within a stride of it isn't on it).
			var k := clampf(delta * 8.0, 0.0, 1.0)
			var p := victim.global_position.lerp(Vector3(_target.x, victim.global_position.y, _target.z), k)
			victim.global_position = p
			if clips.has("kick"):
				victim.global_rotation.y = lerp_angle(victim.global_rotation.y, _kick_yaw(), k)
			else:
				victim.face(_legs())
			if state_t > 0.3:
				# On the mark and the line exactly (the eased turn leaves a few degrees, which at the
				# boot's reach is a hand's width: off the post).
				victim.global_position = Vector3(_target.x, victim.global_position.y, _target.z)
				if clips.has("kick"):
					victim.global_rotation.y = _kick_yaw()
				_go(&"kick")
		&"kick":
			if state_t == delta:
				if clips.has("kick"):
					if victim.play_clip(clips.kick) <= 0.0:
						clips.erase("kick")
				if not clips.has("kick"):
					victim.set_pose(&"kick")
				_kick_t = t
			if not clips.has("kick") and not _kicked_pose and state_t >= KICK_POSE_LANDS:
				_kicked_pose = true
				_pose_kick_lands()
			var swung := (clips.has("kick") and not victim.clip_playing()) or (not clips.has("kick") and state_t > 0.6)
			if swung:
				victim.set_pose(&"stand")
				_go(&"after_kick")
		&"after_kick":
			# He steps clear as the chair comes back at him (a man kicked over from behind comes
			# down at the kicker's feet; physics puts Earl wherever the chair and Cody's legs let it).
			victim.walk_to(_aside_spot(), 1.4, delta)
			if state_t > 0.9:
				_go(&"draw")
		&"draw":
			if state_t == delta:
				if clips.has("draw"):
					if victim.play_clip(clips.draw) <= 0.0:
						clips.erase("draw")
				if not clips.has("draw"):
					victim.draw_gun()
			if clips.has("draw") and victim.gun_holstered and victim.clip_time() > 0.45 * MotionClip.load_clip(clips.draw).length():
				victim.draw_gun()  # no "draw" mark in the clip: his hand's at the hip by now
			if (clips.has("draw") and not victim.clip_playing()) or (not clips.has("draw") and state_t > 0.6):
				if victim.gun_holstered:
					victim.draw_gun()
				_target = _over_spot()
				_go(&"approach")
		&"approach":
			_target = _over_spot()
			# Over him within a long step, or from wherever the chair's pieces and the table let
			# him get to in three seconds: he aims down at the face from there.
			var flat := _target - victim.global_position
			flat.y = 0.0
			if _walk(delta, _target, 1.2) or flat.length() < 0.6 or state_t > 3.0:
				victim.stop_clip()
				_go(&"stand_over")
		&"stand_over":
			var head := (cheater.parts[&"head"] as Node3D).global_position
			if state_t == delta:
				victim.face(head)
				if clips.has("stand_over"):
					if victim.play_clip(clips.stand_over, 1.0, true, {"travel": false}) <= 0.0:
						clips.erase("stand_over")
				if not clips.has("stand_over"):
					victim.set_pose(&"aim")
			if not clips.has("stand_over"):
				victim.face(head)
			var lines: Array = data.get("lines", [])
			if _said < lines.size() and state_t > 0.3 + 2.3 * _said:
				Events.spoke.emit(victim, String(lines[_said]))
				_said += 1
			if state_t > float(data.get("hold_s", 4.0)):
				_note("it times out: no one dies yet")
				victim.stop_clip()
				victim.set_pose(&"stand")
				victim.holster_gun()
				_end(&"timed_out")


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0


func _end(s: StringName) -> void:
	_finish(s)


func _note(what: String) -> void:
	events.append([snappedf(t, 0.01), what])


## The back legs' line at the floor (between the two back posts).
func _legs() -> Vector3:
	return Seating.spot(chair) + _back * 0.175


## Where Cody stands to kick: on a clip, his back to the legs at the boot's reach; pose to pose,
## facing them a long step back (#204's scene).
func _kick_spot() -> Vector3:
	if clips.has("kick"):
		var c := MotionClip.load_clip(clips.kick)
		if c != null and c.events.has("reach_x"):
			# From the clip's marks: where his hips are at the strike and the boot from them, in the
			# clip's frame. He stands so that, turned to his kicking line (_kick_yaw: the boot's
			# line into the chair from behind it), the boot's mid-swing point (reach_k of its reach
			# from his hips: at speed, and it goes on through) is the right back post.
			var post := _legs() + _right() * 0.19
			var hips := Vector3(float(c.events.strike_hips_x), 0.0, float(c.events.strike_hips_z))
			var reach := Vector3(float(c.events.reach_x), 0.0, float(c.events.reach_z)) * float(opts.get("reach_k", 0.65))
			var turned := Basis(Vector3.UP, _kick_yaw())
			var p := post - turned * (hips + reach)
			p.y = _legs().y
			return p
		return _legs() + _back * 0.5
	# Pose to pose he kicks from behind and to the side (#204's scene), out of the way of the fall.
	return _legs() + _back * 0.72 + _right() * 0.6


## The yaw that sends the kick clip's boot from behind the chair into its back legs.
func _kick_yaw() -> float:
	var c := MotionClip.load_clip(clips.kick) if clips.has("kick") else null
	if c == null or not c.events.has("reach_x"):
		return HumanBody.yaw_toward(victim.global_position, _legs())
	var reach := Vector3(float(c.events.reach_x), 0.0, float(c.events.reach_z))
	var clip_yaw := atan2(-reach.x, -reach.z)  # the boot's line in the clip (0: straight ahead, -z)
	var want := atan2(_back.x, _back.z)  # the line into the chair: -_back, as a facing (yaw of -(-back))
	return want - clip_yaw


## Cody's right when his back is to the chair (the chair's own +x: its right back post's side).
func _right() -> Vector3:
	return _back.cross(Vector3.UP).normalized()


## A step clear of the chair's fall: on the clip he's facing away from it, so straight on; pose to
## pose, further out to his side.
func _aside_spot() -> Vector3:
	if clips.has("kick"):
		var away := victim.global_position - _legs()
		away.y = 0.0
		away = away.normalized() if away.length() > 0.05 else _back
		return _legs() + away * 1.6 + away.cross(Vector3.UP) * 0.5
	return _legs() + _back * 0.8 + _right() * 1.3


## Where he stands over Earl: a step off his head, the side nearest Cody.
func _over_spot() -> Vector3:
	var head := (cheater.parts[&"head"] as Node3D).global_position
	var pelvis := (cheater.parts[&"pelvis"] as Node3D).global_position
	var axis := head - pelvis
	axis.y = 0.0
	if axis.length() < 0.05:
		axis = _back
	axis = axis.normalized()
	var side := axis.cross(Vector3.UP)
	var best := head + axis * 0.75
	for cand: Vector3 in [head + side * 0.7, head - side * 0.7, head + axis * 0.75]:
		if cand.distance_to(victim.global_position) < best.distance_to(victim.global_position):
			best = cand
	best.y = victim.global_position.y
	return best


## Cody walks to `target` this tick: on the walk clip (its travel, steered), else by walk_to.
## True when he's there.
func _walk(delta: float, target: Vector3, speed: float) -> bool:
	var flat := target - victim.global_position
	flat.y = 0.0
	if flat.length() < WALK_ARRIVE:
		return true
	if clips.has("walk"):
		if not victim.clip_playing() or victim.clip_name() != clips.walk:
			var c := MotionClip.load_clip(clips.walk)
			var travel := c.root_at(c.length()) - c.root_at(0.0)
			travel.y = 0.0
			var clip_speed := travel.length() / maxf(c.length(), 0.1)
			var rate := clampf(speed / maxf(clip_speed, 0.3), 0.7, 1.5)
			if victim.play_clip(clips.walk, rate, true) <= 0.0:
				clips.erase("walk")
				return false
		var want := HumanBody.yaw_toward(victim.global_position, target)
		victim.global_rotation.y = lerp_angle(victim.global_rotation.y, want, clampf(delta * STEER_RATE, 0.0, 1.0))
		# Stuck against something (the clip's travel stopped by a wall or a man): walk_to's
		# sliding gets him round it.
		if victim.move_speed < 0.2 and state_t > 1.0:
			victim.walk_to(target, speed, delta)
		return false
	return victim.walk_to(target, speed, delta)


## Pose to pose: the blow the kick pose would give, to both back posts, as the chair lab did.
func _pose_kick_lands() -> void:
	var dir := -_back  # into the chair
	var results := []
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken:
			var at := m.global_position
			at.y = chair.global_position.y + 0.12
			results.append(String(chair.take_blow(m, at, dir * KICK_POSE_IMPULSE, 8.0)))
	strikes.append_array(results)
	_note("the kick pose lands: %s" % ", ".join(results))


func result() -> Dictionary:
	var r := super()
	r["animated"] = animated
	r["clips"] = clips.duplicate()
	r["strikes"] = strikes.duplicate()
	r["chair_loose"] = chair != null and is_instance_valid(chair) and chair.loose
	r["cheater_down"] = cheater != null and is_instance_valid(cheater) and cheater.limp
	r["cheater_fell"] = _fell_t >= 0.0
	r["kick_t"] = snappedf(_kick_t, 0.01)
	r["loose_t"] = snappedf(_loose_t, 0.01)
	r["fell_t"] = snappedf(_fell_t, 0.01)
	r["victim_drew"] = victim != null and is_instance_valid(victim) and victim.held_gun != null and not victim.gun_holstered or state == &"timed_out"
	if cheater != null and is_instance_valid(cheater) and cheater.parts.has(&"chest"):
		var chest := cheater.parts[&"chest"] as Node3D
		var front_up := (-chest.global_basis.z).y
		r["chest_front_up"] = snappedf(front_up, 0.01)
		r["on_back"] = cheater.limp and front_up > 0.5
		var seat := Seating.spot(chair) if chair != null and is_instance_valid(chair) else chair_was.origin
		r["behind_m"] = snappedf((chest.global_position - seat).dot(_back), 0.01)
	r["events"] = events.duplicate()
	return r


## Take the men and the chair's pieces out and put a whole chair back where it stood.
func reset() -> void:
	for m: Node in [cheater, victim]:
		if m != null and is_instance_valid(m):
			m.queue_free()
	if chair != null and is_instance_valid(chair):
		for rb in chair.rubble:
			if is_instance_valid(rb):
				rb.queue_free()
		chair.queue_free()
	for rb: Node in get_tree().get_nodes_in_group(&"rubble"):
		if rb is Node3D and (rb as Node3D).global_position.distance_to(chair_was.origin) < 3.0:
			rb.queue_free()
	if chair_parent != null and is_instance_valid(chair_parent):
		# A whole chair where it stood, once the pieces are gone (put down the same tick, it
		# settled onto rubble that then vanished, and went loose: runs 7-10 of the first tally).
		var parent_ref: WeakRef = weakref(chair_parent)  # a lambda holding a freed node is an error when it fires
		var where := chair_was
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			var parent := parent_ref.get_ref() as Node
			if parent == null or not parent.is_inside_tree():
				return
			var fresh := PropLibrary.spawn(&"chair") as KitProp
			parent.add_child(fresh)
			fresh.global_transform = where)
	queue_free()
