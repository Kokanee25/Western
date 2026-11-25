extends TestCase
## No Law's night after the murder (#1057; PlayerCarry, PlayerKnock, NoLawCarry,
## config/moments/no_law_carry.json): a man down taken by the collar and dragged the length of Main
## Street and let go; his wound bleeding the while; a bang on the doctor's door heard by the doctor
## inside; Cody's ball leaving Earl down and breathing, the barkeep sending you to Doc's with him, the
## doctor at his door, Earl laid in the front room and there in the morning when you go in to the
## sheriff, then the undertaker's.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [speaker id, text]


func before_each() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear("nolaw.")
	StoryState.clear("sheriff.")
	StoryState.clear("death.")
	if holder != null:
		holder.queue_free()
		await physics_frames(3)
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)
	await physics_frames(5)


func after_each() -> void:
	ValleyFolk.murder_auto = true
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	for a: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"shove"]:
		Input.action_release(a)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])


func _folk() -> ValleyFolk:
	return valley.folk


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _at(h: float) -> void:
	(valley.get_node(^"DayCycle") as DayCycle).set_time(h)
	await physics_frames(1)
	_folk()._look = 0.0
	await physics_frames(60)


## Your capsule at `at` overlaps something you'd collide with (a table's top, a broken chair's loose
## pieces: #1084's CI pinned you on one).
func _overlaps(p: Player, at: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = p.collision.shape
	q.transform = Transform3D(Basis(), at) * p.collision.transform
	q.collision_mask = p.collision_mask
	q.exclude = [p.get_rid()]
	return not World.space(p).intersect_shape(q, 1).is_empty()


## You by `man`'s collar, looking at it: on a side of him where you can stand (not in the card
## table he fell by: placed in its top you couldn't move, CI #1081).
func _by(man: HumanBody) -> void:
	var p := _player()
	var c := PlayerCarry.collar(man)
	var off := Vector3(0.9, 0.0, 0.0)
	for k in 8:
		var o := Vector3(0.9, 0.0, 0.0).rotated(Vector3.UP, TAU * k / 8.0)
		var try := c + o
		try.y = _folk().floor_under(try.x, try.z, c.y - 0.3) + 0.05  # (#1230: saloon B's floor, not the ground under it)
		if not _overlaps(p, try):
			off = o
			break
	var at := c + off
	at.y = _folk().floor_under(at.x, at.z, c.y - 0.3) + 0.05
	p.global_position = at
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(off.x, off.z)  # facing back along -off: at his collar
	await physics_frames(2)


## Where the last walk went (every 10 s) and what held it: in the failure's message (#1230: CI's walk
## from saloon B stopped short at 153.7 m where no local run did).
var _trail: Array[String] = []


static func _r(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]


## Saloon B's card table and chairs gone loose (kicked or knocked over), by name.
func _loose_set() -> Array:
	var out := []
	for k: String in _folk().props:
		var kp := _folk().props[k] as KitProp
		if kp != null and is_instance_valid(kp) and kp.loose:
			out.append(k)
	return out


## Walk (the forward key, steered) by `way` to its end: false if it took over `max_s`.
func _walk(way: Array[Vector3], max_s: float) -> bool:
	var p := _player()
	var frames := int(max_s * 60.0)
	print("      walk: time_scale %.2f move_factor %.2f burden %.2f shove %.2f carry %.2f crouching %s winded %.2f" % [Engine.time_scale, p.move_factor, p.burden, p.shove.pace() if p.shove else 1.0, p.carry.pace(), p.is_crouching, p.composure.winded if p.composure else 0.0])
	var stuck := 0
	var last := p.global_position
	_trail.clear()
	for i in frames:
		if i % 600 == 0:
			_trail.append("%d s %s" % [i / 60, _r(p.global_position)])
		while not way.is_empty() and Vector2(p.global_position.x - way[0].x, p.global_position.z - way[0].z).length() < 0.6:
			way.pop_front()
		if way.is_empty():
			Input.action_release(&"move_forward")
			return true
		var to := way[0] - p.global_position
		p.rotation.y = atan2(-to.x, -to.z)
		Input.action_press(&"move_forward")
		await physics_frames(1)
		if OS.has_environment("CARRY_DEBUG") and i % 20 == 0 and p.carry.him != null:
			var h := p.carry.him
			if i == 100:
				for sid: StringName in [&"foot_l", &"foot_r", &"shin_l", &"shin_r", &"thigh_l", &"hand_l", &"hand_r", &"forearm_l", &"forearm_r"]:
					var rb := h.parts[sid] as RigidBody3D
					var q := PhysicsShapeQueryParameters3D.new()
					var sph := SphereShape3D.new()
					sph.radius = 0.15
					q.shape = sph
					q.transform = Transform3D(Basis(), rb.global_position)
					q.collision_mask = Layers.WORLD
					q.exclude = [rb.get_rid()]
					var hits := World.space(p).intersect_shape(q, 8)
					print("        %s %s v %s touches %s" % [sid, rb.global_position, rb.linear_velocity, hits.map(func(x: Dictionary) -> String: return "%s/%s" % [(x.collider as Node).get_parent().name if x.collider else "?", (x.collider as Node).name if x.collider else "?"])])
			print("      walk %d you %s collar %s d %.2f pelvis %s feet %s" % [i, p.global_position, PlayerCarry.collar(h), PlayerCarry.collar(h).distance_to(p.global_position + Vector3.UP * 0.45), ValleyFolk._body_at(h), (h.parts[&"foot_l"] as Node3D).global_position])
		if i % 60 == 59:
			stuck = stuck + 1 if p.global_position.distance_to(last) < 0.2 else 0
			last = p.global_position
			if stuck == 2:
				var cols := []
				for k in p.get_slide_collision_count():
					var col := p.get_slide_collision(k).get_collider() as Node
					cols.append(str(col.get_path()) if col else "?")
				print("      held at %s: touching %s" % [p.global_position, cols])
				_trail.append("held at %s by %s" % [_r(p.global_position), cols])
			# Held (the card table's edge where Earl fell, the barkeep by it: where he fell decides
			# whether the way out goes through them), you'd step back and round it with him, as a player
			# would.
			if stuck >= 1 and p.carry.carrying():
				Input.action_release(&"move_forward")
				Input.action_press(&"move_back")
				await physics_frames(20)
				Input.action_release(&"move_back")
				var right := posmod(stuck, 2) == 1
				Input.action_press(&"move_right" if right else &"move_left")
				await physics_frames(50)
				Input.action_release(&"move_right" if right else &"move_left")
			if stuck >= 10:
				break
	Input.action_release(&"move_forward")
	return false


func _route_to(place: StringName) -> Array[Vector3]:
	var p := _player()
	return _folk().places.route(World.space(p), p.global_position, place)


## E, as the key's tap.
func _tap_e() -> void:
	Input.action_press(&"shove")
	await physics_frames(1)
	Input.action_release(&"shove")
	await physics_frames(2)


## Earl's wound as the test needs it whatever the ball did (#1079): a ball under the collarbone, one
## bleed that doesn't clot (KNOWN_ML_S), his breath and head clear, so he talks while you carry him
## (out at unconscious_at_loss about two minutes on, slower as his pressure falls) and dies of it.
const KNOWN_ML_S := 14.0
const KNOWN_LOST_ML := 300.0


func _known_wound(man: HumanBody) -> void:
	var p := man.physiology
	p.bleeds.clear()
	p.cut.clear()
	p.torn.clear()
	p.lung_damage.clear()
	p.airway_blood = false
	p.brain_dead = false
	p.concussion = 0.0
	p.oxygen = 1.0
	p.bleeds.append({"id": 0, "source": &"subclavian_r", "kind": &"artery", "segment": &"chest",
			"rate": KNOWN_ML_S, "clots": false, "clot": 1.0, "pressure": false, "tourniquet": false,
			"lost": 0.0, "limit": 99999.0})
	p.blood_ml = p.tuning.blood_ml - KNOWN_LOST_ML
	p.wound_pain = 0.8
	p.pain = 0.8
	p.alive = true
	for w: Dictionary in man.wounds:
		if w.has("bleeds"):
			w.bleeds = [0]


## A man knocked down, alive (the ragdoll), out on Main Street west of the doctor's.
func _downed(id: StringName) -> HumanBody:
	var f := _folk()
	var man := f.folk_man(id)
	if man == null:
		return null
	# Main Street's middle in front of the saloon (the main@x point nearest the saloon's door).
	var door := f.places.at(&"saloon")
	var start := door
	var best := INF
	for k: StringName in f.places.points:
		if String(k).begins_with("main@"):
			var at: Vector3 = f.places.points[k]
			if absf(at.x - door.x) < best:
				best = absf(at.x - door.x)
				start = at
	man.go_limp()
	man.rise_ok = false
	await physics_frames(5)
	ValleyFolk.move_body(man, start + Vector3.UP * 0.1)
	await physics_frames(60)
	return man


func test_a_man_down_taken_by_the_collar_up_main_street_and_let_go() -> void:
	await _at(21.0)
	var earl := await _downed(&"earl")
	check(earl != null and earl.limp, "Earl down (the ragdoll)")
	if earl == null:
		return
	var p := _player()
	await _by(earl)
	check(p.carry.man_here() == earl, "E would take him (%s)" % p.carry.report())
	check(p.carry.claims_use(p), "E is the carry's here (not a shove)")
	await _tap_e()
	check(p.carry.carrying(earl) and earl.dragged_by == p, "taken by the collar (%s)" % p.carry.report())
	check(p.revolver().hands_busy if p.revolver() else true, "no gun with him in hand")
	var from := p.global_position
	var way := _route_to(&"doctor")
	var t0 := Time.get_ticks_msec()
	var f0 := Engine.get_physics_frames()
	var there := await _walk(way, 160.0)
	var secs := float(Engine.get_physics_frames() - f0) / 60.0
	var m := Vector2(p.global_position.x - from.x, p.global_position.z - from.z).length()
	check(there, "up Main Street to the doctor's door with him (%.0f m in %.0f s; %s)" % [m, secs, p.carry.report()])
	check(m > 40.0, "the length of the street (%.0f m)" % m)
	check(p.carry.carrying(earl), "still has him (%s)" % p.carry.report())
	check(m / secs < p.tuning.carry_speed + 0.15, "at a walk with him (%.2f m/s)" % (m / secs))
	check(PlayerCarry.collar(earl).distance_to(p.global_position) < p.tuning.carry_tear_m + 0.3, "he came with you")
	print("    carried %.0f m in %.0f s, %d ms wall" % [m, secs, Time.get_ticks_msec() - t0])
	await _tap_e()
	await physics_frames(2)
	# (At the door E bangs: let go a step off it.)
	if p.carry.carrying():
		p.carry.drop()
	check(not p.carry.carrying() and earl.dragged_by == null, "let go (%s)" % p.carry.report())


## A man down beside a free chair: a tap of E takes him up, it doesn't sit you down, even before the
## carry's look (a few times a second) has seen him (CI, #1081: by the card table, you sat with
## Earl over your shoulder and never moved).
func test_by_a_chair_e_takes_the_man_not_the_seat() -> void:
	await _at(21.0)
	var earl := await _downed(&"earl")
	check(earl != null, "Earl down")
	if earl == null:
		return
	var p := _player()
	await _by(earl)
	var chair := Seating.free_chair_near(get_tree(), earl.global_position, 6.0)
	check(chair != null, "a free chair in the room by him")
	if chair == null:
		return
	# The chair at your elbow, in view, and the carry's look not yet round to him.
	var fwd := p.get_forward()
	fwd.y = 0.0
	var side := fwd.normalized().cross(Vector3.UP) * 0.5
	chair.global_position += (p.global_position + fwd.normalized() * 0.6 + side) - chair.seat_position() + Vector3.UP * (chair.global_position.y - chair.seat_position().y + 0.47)
	await physics_frames(2)
	check(p.seat.chair_here() != null or p.carry.near_man() != null, "by a chair you could sit in (%s)" % p.carry.report())
	p.carry._near = null
	p.carry._look_t = 99.0
	await _tap_e()
	await physics_frames(10)
	check(p.carry.carrying(earl), "E took him up (%s)" % p.carry.report())
	check(not p.seat.seated(), "and didn't sit you down")


## A man down who could get up (not hurt past standing) doesn't get up off your shoulder while you
## stand still with him (#1081: CI, held at a step with Earl still on your shoulder, he rose, you
## lost him and he walked home).
func test_he_doesnt_get_up_off_your_shoulder() -> void:
	await _at(21.0)
	var earl := await _downed(&"earl")
	check(earl != null and earl.limp, "Earl down")
	if earl == null:
		return
	earl.rise_ok = true
	check(earl.physiology.can_stand(), "he could stand (%s)" % earl.physiology.describe())
	var p := _player()
	await _by(earl)
	await _tap_e()
	check(p.carry.carrying(earl), "taken up (%s)" % p.carry.report())
	await physics_frames(60 * 4)  # past HumanBody's RISE_AFTER + RISE_STILL, standing still
	check(p.carry.carrying(earl) and earl.limp and not earl.rising, "still over your shoulder (%s; limp %s rising %s)" % [p.carry.report(), earl.limp, earl.rising])


func test_his_wound_bleeds_while_hes_dragged() -> void:
	await _at(21.0)
	var earl := await _downed(&"earl")
	if earl == null:
		check(false, "no Earl")
		return
	# A real ball through his collarbone, from above (as Cody's).
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	var chest := earl.parts[&"chest"] as Node3D
	var aim := chest.global_position + Vector3.UP * 0.12
	var from := aim + Vector3(0.3, 1.2, 0.2)
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	ballistics.fire(from, (aim - from).normalized(), t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter)
	await physics_frames(5)
	check(not earl.wounds.is_empty() and earl.physiology.total_bleed_rate() > 0.5, "shot and bleeding (%s)" % earl.physiology.describe())
	var p := _player()
	await _by(earl)
	await _tap_e()
	check(p.carry.carrying(earl), "taken")
	var ml0 := earl.physiology.blood_ml
	await _walk(_route_to(&"doctor"), 20.0)
	check(p.carry.carrying(earl), "still has him")
	check(earl.physiology.blood_ml < ml0 - 50.0 or not earl.physiology.alive, "he bled the while (%.0f -> %.0f ml)" % [ml0, earl.physiology.blood_ml])
	check(p.carry.blood_on_you > 0.0, "his blood on your hands (%s)" % p.carry.report())


func test_a_bang_on_the_doctors_door_is_heard_by_the_doctor() -> void:
	await _at(22.5)
	var f := _folk()
	check(f.book.inside(&"doctor").has(&"doctor"), "the doctor's in (on the book: %s)" % [f.book.inside(&"doctor")])
	var p := _player()
	var door := f.places.at(&"doctor")
	var bldg := (valley.buildings as Dictionary).get("doctor") as Node3D
	var front := bldg.global_basis.z  # (into the building: its +z back from the front)
	front.y = 0.0
	var at := door - front.normalized() * 0.9
	at.y = door.y + 0.05
	p.global_position = at
	p.rotation.y = atan2(-front.x, -front.z)
	await physics_frames(3)
	check(p.knock.door_here().get("place", &"") == &"doctor", "at the doctor's door (%s)" % p.knock.report())
	check(p.knock.claims_use(p), "E is the door's here")
	var heard := []
	f.knocked.connect(func(place: StringName, inside: Array, _by: Node, _at: Vector3) -> void: heard.append([place, inside]))
	await _tap_e()
	check(heard.size() == 1 and heard[0][0] == &"doctor" and (heard[0][1] as Array).has(&"doctor"), "the doctor inside heard it (%s)" % [heard])
	check(p.knock.count == 1, "one bang (%s)" % p.knock.report())


## The night whole: Cody's ball leaves Earl breathing; the barkeep sends you; you drag him to the
## doctor's, bang, the doctor opens and says it; Earl laid in the front room; in the morning he's
## there when you go in to the sheriff, and the doctor says his word by him.
func test_the_night_earl_carried_to_the_doctors_and_there_in_the_morning() -> void:
	ValleyFolk.murder_auto = true
	await _at(21.0)
	var f := _folk()
	var p := _player()
	StoryState.set_fact("sheriff.care", "good")
	# You at the bar's end, away from the table (it happens all the same).
	f.start_murder()
	var m := f.murder as NoLawMurder
	check(m != null, "the murder starts")
	if m == null:
		return
	var shot := await wait_until(func() -> bool: return m.shots > 0, 60 * 120)
	check(shot, "Cody fires (%s)" % [m.events])
	await physics_frames(30)
	var earl := m.cheater
	check(earl.physiology.alive and earl.limp, "Earl down and breathing after it (%s)" % earl.physiology.describe())
	check(earl.physiology.total_bleed_rate() > 1.0, "bleeding (%.1f ml/s)" % earl.physiology.total_bleed_rate())
	check_eq(m.shots, 1, "one ball")
	# Where Cody's ball lands rides on how Earl fell, and a few more bodies anywhere in the valley
	# change that (#1079): his wound set to a known one from here, so the night plays the same.
	_known_wound(earl)
	var started := await wait_until(func() -> bool: return f.carry_act != null, 60 * 60)
	check(started, "the carry starts once the barkeep's said there's nobody to fetch (%s)" % [m.result().get("events")])
	if not started:
		return
	var c := f.carry_act as NoLawCarry
	var asked := await wait_until(func() -> bool: return c.said.any(func(s: Array) -> bool: return s[2] == "after.help"), 60 * 10)
	check(asked, "the barkeep: get him up to Doc's (%s)" % [c.said])
	if not earl.physiology.alive:
		check(false, "Earl died before you got to him (%s)" % earl.physiology.describe())
		return
	await _by(earl)
	print("    by Earl: you %s, Earl %s" % [p.global_position, ValleyFolk._body_at(earl)])
	await _tap_e()
	check(p.carry.carrying(earl), "you have him (%s)" % p.carry.report())
	# Whatever takes his body out of the world while you have him says so (#1081: on CI he was freed
	# off your shoulder).
	earl.tree_exiting.connect(func() -> void:
		if earl.dragged_by != null:
			print("    Earl freed while carried (state %s):" % f.state.get(&"earl"))
			print_stack())
	await physics_frames(5)
	check_eq(StoryState.get_fact("nolaw.carried_earl"), "yes", "nolaw.carried_earl")
	# Up the street with him; if he comes loose on something (a snag), back to him and take him up
	# again, as you would: at most twice.
	var there := false
	var retakes := 0
	for attempt in 3:
		there = await _walk(_route_to(&"doctor"), 200.0)
		if not is_instance_valid(earl):
			check(false, "Earl's body taken out of the world on the way (state %s; the carry: %s)" % [f.state.get(&"earl"), p.carry.report()])
			return
		if p.carry.carrying(earl):
			break
		print("    lost him (%s) at %s: back for him; hurt %s" % [p.carry.report(), p.global_position, p.wounds.last_hurt])
		retakes += 1
		await _by(earl)
		await _tap_e()
	check(there and p.carry.carrying(earl), "to the doctor's door with him (%s; taken up again %d; loose %s; the walk %s)" % [p.carry.report(), retakes, _loose_set(), _trail])
	check(retakes <= 2, "lost him at most twice (%d)" % retakes)
	check(c.said.any(func(s: Array) -> bool: return s[2] == "carry.earl"), "Earl talks on the way (%s)" % [c.said])
	print("    at the door: you %s, Earl %s, door_point %s, the doctor's place %s, %s" % [p.global_position, ValleyFolk._body_at(earl), c.door_point(), f.places.at(&"doctor"), p.carry.report()])
	# Bang (E at the door, Earl by it).
	await _tap_e()
	check(c.knocked_n == 1 and c.state in [&"knocked", &"door"], "the bang's the beat (%s; %s)" % [c.result().get("events"), _player().knock.report()])
	# Two right outcomes (Sean, #1168): the doctor in, a voice through the door; or the town's
	# runner (#1095, fetch help) has already called him out to Earl, so nobody's inside to answer
	# and he comes from the street instead. Which wins is a race the valley's makeup can tip.
	var voice: bool = c.said.any(func(s: Array) -> bool: return s[2] == "carry.door_wait")
	var already_out: bool = f.state.get(&"doctor") == &"called"
	if already_out and not voice:
		print("    the doctor already out to Earl (the town fetched him): no voice through the door")
	check(voice or already_out, "a voice through the door, or the doctor already out (the knocks %s; the doctor: state %s, book %s, body %s; the act's last %s)" % [
			f.knocks, f.state.get(&"doctor"), f.book.row(&"doctor"),
			ValleyFolk._body_at(f.people[&"doctor"]) if f.people.has(&"doctor") else "none", c.timeline.slice(-6)])
	var opened := await wait_until(func() -> bool: return c.state in [&"lay", &"laid"] or c.done, 60 * 60)
	check(opened, "the doctor opens and says it (%s)" % c.result())
	var ids: Array = c.said.map(func(s: Array) -> String: return s[2])
	check(ids.has("carry.door") and ids.has("carry.two") and ids.has("carry.lay"), "his lines: %s" % [ids])
	check(c.doctor != null and is_instance_valid(c.doctor), "the doctor out of his door")
	# Let go on the step and home: the doctor has him in once he's dead and you've gone.
	if p.carry.carrying():
		p.carry.drop()
	var dead := await wait_until(func() -> bool: return not earl.physiology.alive, 60 * 240)
	check(dead, "Earl dies by his wound (%s)" % earl.physiology.describe())
	var away := c.door_point() + Vector3(-22.0, 0.0, -4.0)
	p.global_position = away
	p.global_position.y = f.ground(away.x, away.z) + 0.1
	p.rotation.y = atan2(1.0, 0.0)  # facing west, away
	var laid := await wait_until(func() -> bool: return c.done, 60 * 120)
	check(laid and c.state == &"laid", "laid (%s)" % c.result())
	check_eq(StoryState.get_fact("nolaw.earl"), "doctor's", "nolaw.earl")
	check(f.laid.has(&"earl"), "laid out under a sheet")
	check(c.in_front_room(ValleyFolk._body_at(earl)), "in the front room")
	# The morning: still there; the sheriff's scene; the doctor's word by him; then the undertaker's.
	StoryState.set_fact("nolaw.murder", "done")
	p.global_position = c.door_point() + Vector3(-14.0, 0.0, -5.0)
	p.global_position.y = f.ground(p.global_position.x, p.global_position.z) + 0.1
	await _at(7.0)
	await _at(7.6)
	check(StoryState.has_fact("nolaw.morning"), "the morning")
	check(f.folk_man(&"earl") == earl and f.laid.has(&"earl"), "Earl's body still in the front room (%s)" % f.state.get(&"earl"))
	var sd := await wait_until(func() -> bool: return f.sheriff_scene != null, 60 * 10)
	check(sd, "the sheriff's scene starts")
	if not sd:
		return
	var s := f.sheriff_scene as SheriffDies
	# In at the doctor's door, past Earl, behind the doctor.
	p.global_position = c.door_point() + Vector3.UP * 0.05
	await physics_frames(10)
	await _walk([c._local([4.71, 0.6]), c._local([4.62, 2.0])], 15.0)
	var word := await wait_until(func() -> bool: return said.any(func(x: Array) -> bool: return x[1].begins_with("He was dead when you knocked")), 60 * 10)
	check(word, "the doctor's word by the body (%s)" % [s.timeline])


## #1248 (the blind playtest, 2026-11-25): you didn't carry Earl, he bled out on the floor, and two
## seconds after he died the liveryman and the barkeep called "Somebody fetch Doc!" / "He's hit! Get
## the doctor!", the barkeep's "Ain't nobody left to fetch" said. While the carry holds the room's
## answer to him, nobody calls for the doctor or runs; dead, he's no man to call the doctor to.
func test_earl_left_to_die_nobody_calls_the_doctor_over_the_carry_or_to_the_dead() -> void:
	ValleyFolk.murder_auto = true
	await _at(21.0)
	var f := _folk()
	f.start_murder()
	var m := f.murder as NoLawMurder
	check(m != null, "the murder starts")
	if m == null:
		return
	var shot := await wait_until(func() -> bool: return m.shots > 0, 60 * 120)
	check(shot, "Cody fires (%s)" % [m.events])
	await physics_frames(30)
	var earl := m.cheater
	_known_wound(earl)
	var started := await wait_until(func() -> bool: return f.carry_act != null, 60 * 60)
	check(started, "the carry starts (%s)" % [m.result().get("events")])
	if not started:
		return
	var c := f.carry_act as NoLawCarry
	check(f.fetch.answered(earl), "the carry has the room's answer to him")
	check(not f.fetch.wants_help(earl), "so he's no man for the town to call the doctor to")
	# He bleeds faster (the playtest's death, sooner): you stay where you are.
	earl.physiology.bleeds[0].rate = 60.0
	var trail_from := f.fetch.trail.size()
	var doc_lines: Array = CivilianBrain.LINES[&"help"] + ["Somebody fetch Doc!"] + FetchHelp.LINES[&"run_doc"]
	var from := said.size()
	var died := await wait_until(func() -> bool: return not earl.physiology.alive, 60 * 120)
	check(died, "Earl dies where he lies (%s)" % earl.physiology.describe())
	await physics_frames(60 * 8)
	var calls := said.slice(from).filter(func(s: Array) -> bool: return s[1] in doc_lines)
	check(calls.is_empty(), "nobody calls for the doctor, before he dies or after (%s)" % [calls])
	for man: Node in f.people.values():
		var cb := man.get_node_or_null(^"Brain") as CivilianBrain if is_instance_valid(man) else null
		if cb != null and cb.reaction != null and cb.reaction.down == earl:
			check(cb.reaction.choice != &"help" and cb.reaction.choice != &"run",
					"%s doesn't go to help him or run (%s)" % [cb.body.person_id, cb.reaction.describe()])
	var ran := f.fetch.trail.slice(trail_from).filter(func(e: Array) -> bool: return e[1] == "runs")
	check(ran.is_empty(), "nobody runs for him (%s)" % [ran])
