extends Node
## The gun lab's bench (README.md beside this file): the guns as the game has them, measured and
## drawn, changing nothing. Three jobs, each one game:
##   fp      the player's revolver or coach gun in first person: at rest, aiming, walking,
##           running, cocked, the shot, put away, and every step of the reload.
##   men     each man's gun in his hands: holstered, drawing, aiming, firing, reloading, dropped,
##           seen from 1, 5 and 10 m; with how far the grip is from his palm and the holstered
##           gun from his hip (a gun "floating").
##   handling the numbers: draw to first shot, cocking, the fastest rhythm, reload one round and
##           a full load, sight recovery after a shot, accuracy steady, rushed, from the hip,
##           walking and wounded; and the outlaw's own figures beside them.
## Everything it measures goes in OUT/<job>.json; frames in OUT/<job>/*.png.

const MEN: Array[StringName] = [&"bold_cowboy_s0", &"old_rancher_s1", &"young_drifter_s1", &"sean_s2"]
## The close view (0.6 m, narrow, on the gun), then 1, 5 and 10 m at the player's own view's width.
const DISTANCES := [0.6, 1.0, 5.0, 10.0]
const PLAYER_FOV := 75.0
## Middle of Main Street (fronts at z 0 and -16.8), west of the saloon: open both ways.
const SPOT := Vector3(-6.0, 0.0, -8.4)
## The player faces east (+X) down the street: the afternoon sun behind him, on the gun.
const PLAYER_YAW := 90.0
const PLAYER_AWAY := Vector3(-6.0, 0.0, 60.0)
## Afternoon light: low enough to model the guns, high enough not to be golden-hour orange.
const HOUR := 16.0
## A grip this far from the nearest point of his hand is floating (mm).
const FLOAT_MM := 15.0

var lab: Node  # the BridgeLab
var out_dir := ""
var hour := HOUR
var _street: Node3D


func _ready() -> void:
	_street = lab.street


# --- Setup ---------------------------------------------------------------------------------------

## Everyone out of the street (they'd walk through the shots), the clock set and stopped.
func quiet_town(stop_clock := true) -> void:
	for tl in get_tree().get_nodes_in_group(&"town_life"):
		(tl as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for spawner in _street.find_children("*", "OutlawSpawner", true, false):
		(spawner as Node).process_mode = Node.PROCESS_MODE_DISABLED
	for p in get_tree().get_nodes_in_group(&"people"):
		if p is HumanBody:
			(p as Node).queue_free()
	var clock := _street.find_child("DayCycle", true, false) as DayCycle
	if clock:
		clock.set_time(hour)
		if stop_clock:
			clock.set_time_scale(0.0)
	await lab.physics_frames(4)


func _dir(sub: String) -> String:
	var d := out_dir.path_join(sub)
	DirAccess.make_dir_recursive_absolute(d)
	return d


func _shot(path: String) -> void:
	await lab.bridge._cmd_screenshot([path])


func _act(down: bool, action: StringName) -> void:
	lab.bridge._act(down, action)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## One drawn frame, returning the game seconds it took (the bridge may run unfixed).
func _tick() -> float:
	await get_tree().process_frame
	return get_process_delta_time()


func _place_player(yaw := PLAYER_YAW) -> void:
	var p: Player = lab.player
	p.global_position = SPOT
	p.velocity = Vector3.ZERO
	lab.bridge._set_view(deg_to_rad(-yaw), 0.0)
	await lab.physics_frames(3)


func _gun(which: String) -> WeaponViewmodel:
	var p: Player = lab.player
	var w: WeaponViewmodel = p.revolver() if which == "revolver" else p.shotgun()
	w.needs_captured_mouse = false
	p.select_weapon(w)
	w.take_out()
	var t := 0
	while not w.is_ready_in_hand() and t < 400:
		await get_tree().process_frame
		t += 1
	return w


static func _write(path: String, data: Variant) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))


# --- First person --------------------------------------------------------------------------------

## The gun in first person, a frame a state. Returns the list of frames with what each shows.
func fp(which: String) -> Dictionary:
	await quiet_town()
	await _place_player()
	var w := await _gun(which)
	var dir := _dir("fp_" + which)
	var frames: Array = []
	var take := func(name: String, note: String) -> void:
		var path := dir.path_join("%02d_%s.png" % [frames.size(), name])
		await _shot(path)
		frames.append({"name": name, "file": path.get_file(), "note": note, "weapon": lab.bridge._weapon_line()})

	await lab.seconds(1.0)
	await take.call("rest", "standing still, from the hip")
	_act(true, &"aim")
	await lab.seconds(1.0)
	await take.call("aim", "aiming, settled a second")
	_act(false, &"aim")
	await lab.seconds(0.6)
	_act(true, &"move_forward")
	await lab.seconds(1.0)
	await take.call("walk", "walking a second")
	_act(true, &"run")
	await lab.seconds(1.2)
	await take.call("run", "running")
	_act(false, &"run")
	_act(false, &"move_forward")
	await _place_player()
	await lab.seconds(1.0)
	# Cocked: the thumb on the hammer, just after it comes back.
	if which == "revolver":
		(w as RevolverViewmodel).cock_press()
	else:
		(w as ShotgunViewmodel).cock_press()
	await _frames(6)
	await take.call("cocking", "a tenth of a second into cocking")
	await lab.seconds(0.5)
	await take.call("cocked", "cocked, ready")
	# The reload, a frame a step, a moment into each (where its part moves).
	if which == "revolver":
		var r := w as RevolverViewmodel
		r.state.chambers.fill(RevolverState.Chamber.SPENT)
		var steps := 0
		while steps < 30:
			var before := r.state.to_dict()
			var more := r.state.reload_step()
			var what := _revolver_step(before, r.state.to_dict())
			if not more:
				r.state.close_gate()
				what = "close gate"
			await _frames(8)
			await take.call("reload_%02d" % steps, what)
			while not r.state.ready():
				await get_tree().process_frame
			steps += 1
			if what == "close gate":
				break
	else:
		var s := w as ShotgunViewmodel
		s.state.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.SPENT])
		var steps := 0
		while steps < 10:
			var before := s.state.to_dict()
			var more := s.state.reload_step()
			var what := _shotgun_step(before, s.state.to_dict())
			if not more:
				s.state.close_action()
				what = "close"
			await _frames(8)
			await take.call("reload_%02d" % steps, what)
			while not s.state.ready():
				await get_tree().process_frame
			steps += 1
			if what == "close":
				break
	await lab.seconds(0.6)
	# The shot last: its smoke would hang over everything after it.
	if which == "revolver":
		(w as RevolverViewmodel).cock_press()
	else:
		(w as ShotgunViewmodel).cock_press()
	_act(true, &"aim")
	await lab.seconds(0.8)
	if which == "revolver":
		(w as RevolverViewmodel).pull_trigger()
	else:
		(w as ShotgunViewmodel).pull_trigger()
	await _frames(5)
	await take.call("shot", "aimed shot, 80 ms after (the kick's top)")
	_act(false, &"aim")
	await lab.seconds(1.0)
	w.put_away()
	await lab.seconds(1.2)
	lab.bridge._set_view(deg_to_rad(-PLAYER_YAW), -60.0)
	await lab.physics_frames(3)
	await take.call("put_away", "put away, looking down at the hip")
	lab.bridge._set_view(deg_to_rad(-PLAYER_YAW), 0.0)
	var out := {"gun": which, "frames": frames, "hour": hour}
	_write(out_dir.path_join("fp_%s.json" % which), out)
	return out


static func _revolver_step(a: Dictionary, b: Dictionary) -> String:
	if not a.gate_open and b.gate_open:
		return "half-cock, open gate"
	var i: int = b.under_hammer
	if a.under_hammer != b.under_hammer:
		return "turn cylinder to %d" % i
	if a.chambers[i] != b.chambers[i]:
		return "eject case %d" % i if b.chambers[i] == RevolverState.Chamber.EMPTY else "load round %d" % i
	return "nothing"


static func _shotgun_step(a: Dictionary, b: Dictionary) -> String:
	if not a.open and b.open:
		return "break open"
	for i in 2:
		if a.barrels[i] != b.barrels[i]:
			return ("pull shell %d" % i) if b.barrels[i] == ShotgunState.Barrel.EMPTY else ("load shell %d" % i)
	return "nothing"


# --- A man's gun ---------------------------------------------------------------------------------

## One man with his gun, every state from 1, 5 and 10 m, and how well the gun sits in his hand.
func men(body: StringName) -> Dictionary:
	await quiet_town()
	var p: Player = lab.player
	p.global_position = PLAYER_AWAY
	p.velocity = Vector3.ZERO
	var dir := _dir("men_" + String(body))
	var man := HumanBody.new()
	man.name = "GunLab_man"
	man.has_gun = true
	man.start_holstered = true
	man.body_model = body
	man.rng_seed = 7
	man.person_id = StringName("gunlab_" + String(body))
	_street.add_child(man)
	# Facing west down the street, as the player stood.
	man.global_transform = Transform3D(Basis.from_euler(Vector3(0, deg_to_rad(90.0), 0)), SPOT)
	man.set_pose(&"stand")
	await lab.seconds(1.5)
	var target := SPOT + Vector3(-6.0, 1.3, 0.0)  # what he aims at: a man 6 m west
	var states: Array = []
	var take := func(state: String, note: String, settle_s: float) -> void:
		await lab.seconds(settle_s)
		var gap := grip_gap(man)
		var shots := {}
		for d: float in DISTANCES:
			var cam := _camera_for(man, d, state)
			lab.bridge._cmd_camera([cam[0].x, cam[0].y, cam[0].z, cam[1].x, cam[1].y, cam[1].z, 35.0 if d < 1.0 else PLAYER_FOV])
			await _frames(2)
			var key := "close" if d < 1.0 else str(int(d))
			var path := dir.path_join("%s_%s.png" % [state, key])
			await _shot(path)
			shots[key] = path.get_file()
		states.append({"state": state, "note": note, "gap": gap, "frames": shots})

	await take.call("holstered", "standing, gun in its holster", 0.0)
	# X-ray: the same close view with his body hidden, to show where the holstered gun really is.
	var hidden: Array = []
	for mi in man.skeleton.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).visible:
			(mi as MeshInstance3D).visible = false
			hidden.append(mi)
	var cam_x := _camera_for(man, 0.6, "holstered")
	lab.bridge._cmd_camera([cam_x[0].x, cam_x[0].y, cam_x[0].z, cam_x[1].x, cam_x[1].y, cam_x[1].z, 35.0])
	await _frames(2)
	await _shot(dir.path_join("holstered_xray.png"))
	(states[-1].frames as Dictionary)["xray"] = "holstered_xray.png"
	for mi: MeshInstance3D in hidden:
		mi.visible = true
	man.draw_gun()
	man.set_pose(&"aim")
	man.face(target)
	await take.call("drawing", "0.15 s into the draw (draw_gun + the aim pose)", 0.15)
	man.face(target)
	await take.call("aiming", "aiming at a man 6 m off", 1.2)
	# Firing: what OutlawBrain._fire_at does to the world (smoke, flash), nothing more.
	var gun := man.held_gun as RevolverModel
	if gun:
		var world := _street
		var origin := gun.muzzle.global_position
		var dir_shot := (target - origin).normalized()
		GunSmoke.spawn(world, origin, dir_shot)
		ImpactEffects.muzzle_flash(world, origin)
	await take.call("firing", "a frame after the shot (smoke and flash as OutlawBrain fires)", 0.03)
	await lab.seconds(1.5)
	# Reloading: OutlawBrain counts 12 s down in the RELOADING mood, crouched behind cover; nothing moves.
	man.set_pose(&"crouch")
	await take.call("reloading", "reloading as OutlawBrain does it: crouched, a 12 s timer", 1.0)
	man.set_pose(&"stand")
	await lab.seconds(1.0)
	man.drop_gun()
	await take.call("dropped", "dropped (drop_gun), 2 s later", 2.0)
	var dropped := _dropped_rest()
	var out := {"body": String(body), "has_model": PeopleBodies.has_model(body),
			"whole": PeopleBodies.report(body).get("whole", false), "states": states, "dropped": dropped}
	man.queue_free()
	_write(out_dir.path_join("men_%s.json" % body), out)
	return out


## The camera for a state at `d` m: from his front right (his gun side), level with his gun hand
## up close, his chest further off.
func _camera_for(man: HumanBody, d: float, state: String) -> Array:
	var fwd := -man.global_basis.z
	var right := man.global_basis.x
	var aim_at: Vector3
	if d <= 1.5:
		if state == "dropped":
			aim_at = _dropped_point()
		elif man.held_gun:
			aim_at = man.held_gun.global_position
		else:
			aim_at = (man.visuals[&"hand_r"] as Node3D).global_position
	else:
		aim_at = man.global_position + Vector3.UP * 1.1
	# Mostly in front (the street is 17 m wide: a long sideways step meets the porches).
	var side := 0.3
	if state == "holstered" and d <= 1.5:
		side = 2.0  # the holster's on his right hip: from his right
	var from := aim_at + (fwd + right * side).normalized() * d
	from.y = aim_at.y + (0.1 if d <= 1.5 else 0.25)
	return [from, aim_at]


func _dropped_point() -> Vector3:
	for g in get_tree().get_nodes_in_group(&"dropped_guns"):
		return (g as Node3D).global_position
	return SPOT


## Where the dropped gun came to rest: its lowest point above the ground under it (mm), still or not.
func _dropped_rest() -> Dictionary:
	for g in get_tree().get_nodes_in_group(&"dropped_guns"):
		var rb := g as RigidBody3D
		var low := INF
		for mi in rb.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			var box := m.get_aabb()
			for i in 8:
				low = minf(low, (m.global_transform * box.get_endpoint(i)).y)
		var q := PhysicsRayQueryParameters3D.create(rb.global_position + Vector3.UP, rb.global_position + Vector3.DOWN * 3.0, Layers.WORLD)
		q.exclude = [rb.get_rid()]
		var hit := rb.get_world_3d().direct_space_state.intersect_ray(q)
		var ground: float = hit.position.y if not hit.is_empty() else 0.0
		return {"lowest_above_ground_mm": roundf((low - ground) * 1000.0), "asleep": rb.sleeping,
				"speed": snappedf(rb.linear_velocity.length(), 0.01), "at": lab.arr(rb.global_position)}
	return {}


## How well the gun sits in his hand (or the holster on his hip): the gun's grip against his
## skinned hand's vertices (posed by his skeleton). nearest_mm 0 = touching or inside; how many of
## his hand's points are inside the grip (the gun cut through his hand); how far his palm's middle
## is from the grip's. Holstered, the gun's frame against his hip and thigh instead.
func grip_gap(man: HumanBody) -> Dictionary:
	var gun := man.held_gun as RevolverModel
	if gun == null:
		return {"gun": "none"}
	var holstered := man.gun_holstered
	var part_name := "Frame" if holstered else "Grip/Panels"
	var box_mi := gun.get_node_or_null(part_name) as MeshInstance3D
	if box_mi == null:
		return {"error": "no %s" % part_name}
	var size: Vector3 = (box_mi.mesh as BoxMesh).size
	var inv := box_mi.global_transform.affine_inverse()
	var segs: Array[StringName] = []
	segs.assign([&"pelvis", &"thigh_r"] if holstered else [&"hand_r"])
	var pts := _skin_points(man, segs)
	if pts.is_empty():
		return {"error": "no skinned points for %s" % str(segs)}
	var nearest := INF
	var inside := 0
	var centroid := Vector3.ZERO
	for v: Vector3 in pts:
		var l := inv * v
		var q := (l.abs() - size * 0.5)
		var outside := Vector3(maxf(q.x, 0.0), maxf(q.y, 0.0), maxf(q.z, 0.0)).length()
		if outside <= 0.0:
			inside += 1
		nearest = minf(nearest, outside)
		centroid += v
	centroid /= pts.size()
	var out := {"where": "holster" if holstered else "hand", "points": pts.size(), "nearest_mm": roundf(nearest * 1000.0),
			"inside": inside, "inside_share": snappedf(float(inside) / pts.size(), 0.001),
			"centre_to_grip_mm": roundf(centroid.distance_to(box_mi.global_position) * 1000.0)}
	out["floating"] = nearest * 1000.0 > FLOAT_MM
	if holstered:
		# Buried: how far inside the outside of his hip the gun's frame sits (his points at the
		# frame's height and depth, their furthest out to his right, against the frame's middle;
		# positive = inside him, the frame's own half width 13 mm).
		var to_man := man.global_transform.affine_inverse()
		var c := to_man * box_mi.global_position
		var side := -INF
		for v: Vector3 in pts:
			var l := to_man * v
			if absf(l.y - c.y) < 0.04 and absf(l.z - c.z) < 0.08:
				side = maxf(side, l.x)
		if side > -INF:
			out["buried_mm"] = roundf((side - c.x) * 1000.0)
			out["hidden"] = side - c.x > size.x * 0.5
	return out


## His skin's (and clothes') vertices on these bones, where his skeleton has them now.
static func _skin_points(man: HumanBody, segs: Array[StringName]) -> PackedVector3Array:
	var out := PackedVector3Array()
	var skel := man.skeleton
	if skel == null:
		return out
	for key: String in man.skin_meshes:
		var sid := StringName(key.get_slice("/", 1))
		if not segs.has(sid):
			continue
		var mi := man.skin_meshes[key] as MeshInstance3D
		var bi := skel.find_bone(String(sid))
		if bi < 0 or mi.mesh == null:
			continue
		var xf := skel.global_transform * skel.get_bone_global_pose(bi) * skel.get_bone_rest(bi).affine_inverse()
		# A bone's rest here is its global rest (HumanBody sets rests in the skeleton's space).
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var step := maxi(1, verts.size() / 600)
		for i in range(0, verts.size(), step):
			out.append(xf * verts[i])
	return out


# --- Handling ------------------------------------------------------------------------------------

## The handling numbers for both guns, and the outlaw's beside them.
func handling() -> Dictionary:
	# The clock runs: wounds hurt on its time (PlayerWounds steps the body at its scale).
	await quiet_town(false)
	await _place_player()
	var out := {"revolver": {}, "shotgun": {}, "outlaw": {}}
	for which in ["revolver", "shotgun"]:
		var w := await _gun(which)
		w.steady_hands = false
		out[which]["draw_to_first_shot_s"] = await _draw_to_shot(w)
		out[which]["cock_s"] = await _cock_time(w)
		out[which]["cadence_s"] = await _cadence(w)
		out[which].merge(await _reloads(w))
		out[which]["recovery"] = await _recovery(w)
		out[which]["accuracy"] = await _accuracy(w)
		_reset_gun(w)
	out["revolver"]["accuracy"]["wounded_aimed"] = await _wounded_accuracy()
	var ob := OutlawBrain.new()
	out["outlaw"] = {"draw_s": HumanBody.DRAW_TIME, "reload_s": ob.reload_seconds, "rounds_per_load": ob.rounds_per_load,
			"spread_degrees_calm": ob.spread_degrees, "seconds_between_shots": ob.get(&"seconds_between_shots")}
	ob.free()
	var rt: RevolverTuning = load("res://config/revolver.tres")
	var st: ShotgunTuning = load("res://config/shotgun.tres")
	out["tuning"] = {"revolver": {"draw": rt.draw_time, "cock": rt.cock_time, "gate": rt.gate_time, "turn": rt.turn_time,
			"eject": rt.eject_time, "insert": rt.insert_time, "spread_hip": rt.spread_hip_degrees, "spread_aim": rt.spread_aim_degrees},
			"shotgun": {"draw": st.draw_time, "cock": st.cock_time, "open": st.open_time, "close": st.close_time,
			"extract": st.extract_time, "load": st.load_time, "spread_hip": st.spread_hip_degrees, "spread_aim": st.spread_aim_degrees}}
	_write(out_dir.path_join("handling.json"), out)
	return out


func _reset_gun(w: WeaponViewmodel) -> void:
	if w is RevolverViewmodel:
		var r := (w as RevolverViewmodel).state
		r.gate_open = false
		r.hammer = RevolverState.Hammer.DOWN
		r.chambers.fill(RevolverState.Chamber.LOADED)
		r.belt = 24
		r.busy = 0.0
	else:
		var s := (w as ShotgunViewmodel).state
		s.open = false
		s.barrels.assign([ShotgunState.Barrel.LOADED, ShotgunState.Barrel.LOADED])
		s.cocked_hammers.assign([false, false])
		s.pocket = 12
		s.busy = 0.0
	w.extra_spread = 0.0


func _cocked(w: WeaponViewmodel) -> bool:
	return lab.bridge._cocked(w)


func _fired_signal(w: WeaponViewmodel) -> Signal:
	return (w as RevolverViewmodel).state.fired if w is RevolverViewmodel else (w as ShotgunViewmodel).state.fired


## As fast as the controls allow: from the holster key to the ball leaving, pressing cock and fire
## the first frame each can take.
func _draw_to_shot(w: WeaponViewmodel) -> float:
	_reset_gun(w)
	w.put_away()
	while not w.is_put_away():
		await get_tree().process_frame
	await _frames(10)
	var box := {"fired": false}
	var on_fire := func(_a = null) -> void: box.fired = true
	var sig := _fired_signal(w)
	sig.connect(on_fire)
	w.take_out()
	var t := 0.0
	while not box.fired and t < 10.0:
		if w.is_ready_in_hand():
			if not _cocked(w):
				w.call(&"cock_press")
			else:
				w.call(&"pull_trigger")
		t += await _tick()
	sig.disconnect(on_fire)
	await _frames(40)
	return snappedf(t, 0.001)


func _cock_time(w: WeaponViewmodel) -> float:
	_reset_gun(w)
	await _frames(30)
	w.call(&"cock_press")
	var t := 0.0
	var st: Object = w.get(&"state")
	while not (st.call(&"ready") and _cocked(w)) and t < 5.0:
		t += await _tick()
	w.call(&"pull_trigger")  # let it down: fire it off
	await _frames(40)
	return snappedf(t, 0.001)


## Fastest shot to shot: cock, fire the moment it's cocked, five shots.
func _cadence(w: WeaponViewmodel) -> float:
	_reset_gun(w)
	await _frames(30)
	var times: Array[float] = []
	var clock := {"t": 0.0}
	var on_fire := func(_a = null) -> void: times.append(clock.t)
	var sig := _fired_signal(w)
	sig.connect(on_fire)
	var want := 5 if w is RevolverViewmodel else 2
	while times.size() < want and clock.t < 15.0:
		if not _cocked(w):
			w.call(&"cock_press")
		else:
			w.call(&"pull_trigger")
		clock.t += await _tick()
	sig.disconnect(on_fire)
	if times.size() < 2:
		return -1.0
	return snappedf((times[-1] - times[0]) / (times.size() - 1), 0.001)


## Reload times, one key press the moment the hand's free: one round (one spent), a full load.
func _reloads(w: WeaponViewmodel) -> Dictionary:
	var out := {}
	if w is RevolverViewmodel:
		var r := (w as RevolverViewmodel).state
		_reset_gun(w)
		r.chambers[(r.under_hammer + 1) % 6] = RevolverState.Chamber.SPENT
		out["reload_one_round_s"] = await _reload_run(w)
		_reset_gun(w)
		r.chambers.fill(RevolverState.Chamber.SPENT)
		out["reload_six_s"] = await _reload_run(w)
	else:
		var s := (w as ShotgunViewmodel).state
		_reset_gun(w)
		s.barrels[0] = ShotgunState.Barrel.SPENT
		out["reload_one_shell_s"] = await _reload_run(w)
		_reset_gun(w)
		s.barrels.assign([ShotgunState.Barrel.SPENT, ShotgunState.Barrel.SPENT])
		out["reload_two_s"] = await _reload_run(w)
	return out


func _reload_run(w: WeaponViewmodel) -> float:
	await _frames(20)
	var st: Object = w.get(&"state")
	var t := 0.0
	var closing := false
	while t < 60.0:
		if st.call(&"ready"):
			if closing:
				break
			w.call(&"reload_press")
			var open: bool = st.get(&"gate_open") if w is RevolverViewmodel else st.get(&"open")
			if not open:
				closing = true
		t += await _tick()
	return snappedf(t, 0.001)


## Where a shot would go now: your line of sight turned by the sway and the kick (as _shot_line).
static func _barrel_dir(w: WeaponViewmodel, cam: Camera3D) -> Vector3:
	var off := w.sway + Vector2(w.kick.yaw, w.kick.pitch)
	return cam.global_transform.basis * (Basis.from_euler(Vector3(deg_to_rad(off.y), deg_to_rad(-off.x), 0.0)) * Vector3.FORWARD)


## After an aimed shot, held still (no sway, no hand on the mouse): how long till the barrel's
## line is back within 1° of where you aimed, its worst, and what's left at 1.5 s.
func _recovery(w: WeaponViewmodel) -> Dictionary:
	_reset_gun(w)
	var p: Player = lab.player
	await _place_player()
	w.steady_hands = true
	_act(true, &"aim")
	await lab.seconds(1.0)
	w.call(&"cock_press")
	await lab.seconds(0.5)
	var aim := -p.camera.global_transform.basis.z
	w.call(&"pull_trigger")
	var worst := 0.0
	var curve: Array = []  # [seconds, the barrel's line against where you aimed (deg), the line]
	var t := 0.0
	while t < 1.5:
		t += await _tick()
		var d := _barrel_dir(w, p.camera)
		var ang := rad_to_deg(d.angle_to(aim))
		worst = maxf(worst, ang)
		curve.append([t, ang, d])
	_act(false, &"aim")
	w.steady_hands = false
	await lab.seconds(0.5)
	# Settled: from when the line stays within a quarter of a degree of where it ends (the climb
	# that stays is yours to pull down).
	var end: Vector3 = curve[-1][2]
	var settled := 0.0
	for i in range(curve.size() - 1, -1, -1):
		if rad_to_deg((curve[i][2] as Vector3).angle_to(end)) > 0.25:
			settled = curve[mini(i + 1, curve.size() - 1)][0]
			break
	return {"worst_deg": snappedf(worst, 0.01), "settled_s": snappedf(settled, 0.001), "left_deg": snappedf(curve[-1][1], 0.01)}


## Spread of shots at a man-sized target 10 m off (a torso 45 x 75 cm): the angle between each
## ball's way and your line of sight, how wide half the shots fall (R50, cm at 10 m) and the share
## inside the torso. Rushed: fired 0.25 s after raising the sights; steady: after 2 s held.
func _accuracy(w: WeaponViewmodel) -> Dictionary:
	var out := {}
	for cond in ["steady_aimed", "rushed_aimed", "hip", "walking_hip"]:
		out[cond] = await _spread(w, cond, 16)
	return out


func _spread(w: WeaponViewmodel, cond: String, n: int) -> Dictionary:
	var offs: Array = []
	for i in n:
		_reset_gun(w)
		await _place_player()
		# Cocked first, then (rushed) the shot a quarter second after the sights come up.
		w.call(&"cock_press")
		await _until_ready(w)
		if cond == "walking_hip":
			_act(true, &"move_forward")
			await lab.seconds(0.8)
		if cond.ends_with("aimed"):
			_act(true, &"aim")
			await lab.seconds(2.0 if cond == "steady_aimed" else 0.25)
		else:
			await lab.seconds(0.6)
		var o: Variant = await _one_shot(w)
		if o != null:
			offs.append(o)
		await lab.seconds(0.4)
	return _spread_summary(offs)


func _until_ready(w: WeaponViewmodel) -> void:
	var st: Object = w.get(&"state")
	var t := 0
	while not (_cocked(w) and st.call(&"ready")) and t < 240:
		await get_tree().process_frame
		t += 1


## Pull the trigger and say where the ball crosses the plane 10 m out along your line of sight:
## its offset (cm: right, up) from where you were looking, or null if nothing went off. The drop
## at 10 m is under a centimetre: left in.
func _one_shot(w: WeaponViewmodel) -> Variant:
	var p: Player = lab.player
	var box := {"got": false}
	var on_shot := func(origin: Vector3, dir: Vector3, shooter: Node) -> void:
		if shooter == p and not box.got:
			box.origin = origin
			box.dir = dir
			box.got = true
	Events.shot_fired.connect(on_shot)
	var eye := p.camera.global_position
	var basis := p.camera.global_transform.basis
	var sight := -basis.z
	w.call(&"pull_trigger")
	var t := 0
	while not box.got and t < 30:
		await get_tree().process_frame
		t += 1
	Events.shot_fired.disconnect(on_shot)
	_act(false, &"aim")
	_act(false, &"move_forward")
	if not box.got:
		return null
	var d: Vector3 = box.dir
	var o: Vector3 = box.origin
	var denom := d.dot(sight)
	if denom <= 0.01:
		return null
	var s := (eye + sight * 10.0 - o).dot(sight) / denom
	var at := o + d * s - (eye + sight * 10.0)
	return Vector2(at.dot(basis.x), at.dot(basis.y)) * 100.0


static func _spread_summary(offs: Array) -> Dictionary:
	if offs.is_empty():
		return {"shots": 0}
	var mean := Vector2.ZERO
	for o: Vector2 in offs:
		mean += o
	mean /= offs.size()
	var radii: Array[float] = []
	var inside := 0
	for o: Vector2 in offs:
		radii.append(o.length())
		if absf(o.x) <= 22.5 and absf(o.y) <= 37.5:
			inside += 1
	radii.sort()
	return {"shots": offs.size(), "mean_off_cm": [snappedf(mean.x, 0.1), snappedf(mean.y, 0.1)],
			"r50_cm_at_10m": snappedf(radii[radii.size() / 2], 0.1), "r90_cm_at_10m": snappedf(radii[int(radii.size() * 0.9)], 0.1),
			"torso_hits_at_10m": snappedf(float(inside) / offs.size(), 0.01)}


## Wounded: a revolver ball through the left upper arm (the gun hand still holds), aimed shots 3 s
## after (adrenaline masking the pain) and 45 s after; then one through the right forearm, the
## gun arm, on top of it.
func _wounded_accuracy() -> Dictionary:
	var p: Player = lab.player
	var w := await _gun("revolver")
	_reset_gun(w)
	await _place_player()
	var out := {}
	await _wound(Vector3(-0.2, 1.32, 0.0))
	await lab.seconds(3.0)
	out["left_arm_3s"] = await _wounded_spread(w)
	await lab.seconds(45.0)
	out["left_arm_45s"] = await _wounded_spread(w)
	await _wound(Vector3(0.22, 1.0, 0.0))
	await lab.seconds(3.0)
	out["and_gun_forearm_3s"] = await _wounded_spread(w)
	return out


## A revolver ball from in front, through the point `local` (the player's own space: x right, y up,
## -z forward), front to back: through that limb alone.
func _wound(local: Vector3) -> String:
	var p: Player = lab.player
	var rt: RevolverTuning = load("res://config/revolver.tres")
	var energy := 0.5 * rt.bullet_mass * rt.muzzle_velocity * rt.muzzle_velocity
	var hit: Dictionary = p.wounds.take_bullet(null, p.global_transform * local, p.global_basis.z, energy, rt.bullet_diameter * 0.5)
	lab.log_event("gun_lab", "wounded: %s" % str(hit.get("segment", "")))
	return str(hit.get("segment", ""))


func _wounded_spread(w: WeaponViewmodel) -> Dictionary:
	var p: Player = lab.player
	var ph: Physiology = p.wounds.physiology
	var segs: Array = []
	for wd: Dictionary in p.wounds.wounds:
		segs.append(str(wd.get("segments", [])))
	var before := {"hit": segs, "extra_spread_deg": snappedf(w.extra_spread, 0.01), "pain": snappedf(ph.pain, 0.01),
			"adrenaline": snappedf(ph.adrenaline, 0.01), "felt_pain": snappedf(ph.felt_pain(), 0.01),
			"steadiness_r": snappedf(ph.arm_steadiness("r"), 0.01), "can_hold_r": ph.can_hold("r")}
	var offs: Array = []
	for i in 12:
		if not w.is_ready_in_hand():
			break
		var r := (w as RevolverViewmodel).state
		r.chambers.fill(RevolverState.Chamber.LOADED)
		r.gate_open = false
		r.hammer = RevolverState.Hammer.DOWN
		w.call(&"cock_press")
		await _until_ready(w)
		_act(true, &"aim")
		await lab.seconds(2.0)
		var o: Variant = await _one_shot(w)
		if o != null:
			offs.append(o)
		await lab.seconds(0.4)
	var out := _spread_summary(offs)
	out.merge(before)
	return out
