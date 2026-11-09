extends BridgeLab
## The valley's dev bridge commands (docs/briefs/valley-plan.md §12; G3 #716: the main line and its
## train). Only in the valley world (`--world=valley` or the bridge's `world valley`).
##
##   valley_train                        where the train is, the engineer's state, the day
##   valley_train run [S]                the day's run from S real seconds after it leaves east_start
##                                       (no S: where the clock has it), the engineer driving
##   valley_train at MARK [KMH]          stood (or running at KMH, held) with its engine's front on a
##                                       mark, nobody driving (pictures, the labs)
##   valley_view VP|MARK [LOOK]          you at a viewpoint (vp_*) or beside a mark, looking at the
##                                       mark LOOK (a route mark or a viewpoint; default trestle_mid)
##   valley_walk PLACE [run]             walk (or run) from where you stand to a place by the roads
##                                       (ValleyRoads' shortest way, as the plan's travel tables go):
##                                       the game seconds it took, against the plan's time at the
##                                       game's walk (2.8 m/s); where you stuck, if you did (G4)

const HELP := {
	"valley_train": "valley_train [run [S] | at MARK [KMH] | sync] -> the valley's daily train: where it is, the engineer's state; run: the day's run from S s after it leaves (no S: by the clock); at: stood with its front on MARK (or held at KMH), nobody driving",
	"valley_view": "valley_view VP|MARK [LOOK] -> you at a valley viewpoint (vp_*) or beside a route mark, looking at LOOK (a mark or viewpoint; trestle_mid)",
	"valley_walk": "valley_walk PLACE [run] -> walk (or run) by the roads from where you stand to a valley place, bridge or viewpoint: the game seconds it took and the plan's time for that way at the game's walk; where you stuck",
}

var _hold_kmh := -1.0


func _railway() -> ValleyRailway:
	return street.get_node_or_null(^"Railway") as ValleyRailway if street else null


func _cmd_valley_train(a: Array) -> Dictionary:
	var rw := _railway()
	if rw == null:
		return {"ok": false, "error": "no valley railway (world valley)"}
	var what: String = a[0] if a.size() > 0 else ""
	match what:
		"run":
			_hold_kmh = -1.0
			rw.driving = true
			if a.size() > 1:
				rw.start_run(float(a[1]), rw.run_day)
			else:
				rw.sync_to_clock()
			await physics_frames(2)
		"sync":
			_hold_kmh = -1.0
			rw.driving = true
			rw.sync_to_clock()
			await physics_frames(2)
		"at":
			if a.size() < 2 or is_nan(rw.line.mark_s(str(a[1]))):
				return {"ok": false, "error": "no mark %s" % (a[1] if a.size() > 1 else "")}
			rw.driving = false
			rw.train.place(rw.line.mark_s(str(a[1])))
			rw.train.sim.brake_lever = 1.0
			rw.train.sim.throttle = 0.0
			_hold_kmh = float(a[2]) if a.size() > 2 else -1.0
			if _hold_kmh > 0.0:
				rw.train.sim.brake_lever = 0.0
				rw.train.sim.set_speed(_hold_kmh / 3.6)
			await physics_frames(2)
	return rw.report()


func _physics_process(_delta: float) -> void:
	if _hold_kmh <= 0.0:
		return
	var rw := _railway()
	if rw == null or rw.driving or rw.train == null:
		_hold_kmh = -1.0
		return
	# Held at the speed asked (as the trestle lab's `hold` driver): steam to keep it, no brake.
	var sim := rw.train.sim
	var kph := sim.v * 3.6
	sim.reverser = 1
	sim.throttle = 1.0 if kph < _hold_kmh - 1.0 else (0.4 if kph < _hold_kmh else 0.0)
	sim.brake_lever = 0.3 if kph > _hold_kmh + 2.0 else 0.0


## A viewpoint's or mark's place: [eye, its own height over the ground].
func _place(rw: ValleyRailway, id: String) -> Variant:
	var lay := ValleyLayout.main()
	var vp := lay.viewpoint(id)
	var ter := ValleyTerrain.main()
	if not vp.is_empty():
		var at: Array = vp.at
		# Where the valley's places stand it (G4: out of any block it falls in), at the eye.
		if street is ValleyWorld and (street as ValleyWorld).places().has(StringName(id)):
			var p := (street as ValleyWorld).places().at(StringName(id))
			return Vector3(p.x, ter.height(p.x, p.z) + float(vp.get("eye", 1.7)), p.z)
		return Vector3(float(at[0]), ter.height(float(at[0]), float(at[1])) + float(vp.get("eye", 1.7)), float(at[1]))
	if rw and not is_nan(rw.line.mark_s(id)):
		return rw.mark_point(id)
	return null


func _cmd_valley_view(a: Array) -> Dictionary:
	var rw := _railway()
	if a.is_empty():
		return {"ok": false, "error": "valley_view VP|MARK [LOOK]"}
	var eye: Variant = _place(rw, str(a[0]))
	var look: Variant = _place(rw, str(a[1]) if a.size() > 1 else "trestle_mid")
	if eye == null or look == null:
		return {"ok": false, "error": "no viewpoint or mark %s" % a}
	var e: Vector3 = eye
	if not str(a[0]).begins_with("vp_"):
		# Beside a mark: 12 m off the line's right side, at a man's eye over the ground there.
		var f := rw.line.global_transform * rw.line.transform_at(rw.line.mark_s(str(a[0])))
		e = f.origin + f.basis.x * 12.0
		e.y = ValleyTerrain.main().height(e.x, e.z) + 1.7
	var l: Vector3 = look
	player.velocity = Vector3.ZERO
	player.global_position = e - Vector3.UP * 1.6
	await physics_frames(2)
	bridge._face(l)
	await physics_frames(1)
	return {"eye": arr(e), "look": arr(l), "distance": snappedf(e.distance_to(l), 0.1), "pitch_deg": snappedf(player.get_pitch_degrees(), 0.1)}


var _roads: ValleyRoads


## Where the plan's travel tables end a journey: a place's or viewpoint's `at`, a bridge's middle.
func _journey_end(id: String) -> Variant:
	var e := ValleyLayout.main().entry(id)
	if e.has("at"):
		return ValleyLayout.xz(e.at)
	if street is ValleyWorld and (street as ValleyWorld).places().has(StringName(id)):
		var p := (street as ValleyWorld).places().at(StringName(id))
		return Vector2(p.x, p.z)
	return null


func _cmd_valley_walk(a: Array) -> Dictionary:
	if a.is_empty() or not street is ValleyWorld:
		return {"ok": false, "error": "valley_walk PLACE [run] (world valley)"}
	var id := str(a[0])
	var end: Variant = _journey_end(id)
	if end == null:
		return {"ok": false, "error": "no place %s" % id}
	if _roads == null:
		_roads = ValleyRoads.make(ValleyLayout.main())
	var from := Vector2(player.global_position.x, player.global_position.z)
	var j := _roads.journey(from, end)
	if j.is_empty():
		return {"ok": false, "error": "no way there by road"}
	var pts: PackedVector2Array = j.points
	var stand := (street as ValleyWorld).places().at(StringName(id)) if (street as ValleyWorld).places().has(StringName(id)) else Vector3(end.x, 0.0, end.y)
	pts.append(Vector2(stand.x, stand.z))
	var run := "run" in a
	var speed := float(ValleyLayout.main().speeds().get("player_run" if run else "player_walk", 2.8))
	if run:
		bridge._act(true, &"run")
	var t0 := bridge._game_seconds()
	var walked := 0.0
	var last := player.global_position
	var progress_at := t0
	var progress_pos := last
	var k := 0
	var arrived := false
	var stuck := false
	var side := 1.0
	var side_until := -1.0
	var climb := 0.0
	var drop := 0.0
	var plan_s := float(j.length) / speed
	var limit := t0 + plan_s * 2.0 + 60.0  # (never past twice the plan's time and a minute)
	var trace := []
	var trace_at := t0
	while true:
		var here := Vector2(player.global_position.x, player.global_position.z)
		while k < pts.size() - 1 and (here.distance_to(pts[k]) < 3.0 or here.distance_to(pts[k + 1]) < here.distance_to(pts[k]) and k + 1 < pts.size() - 1):
			k += 1
		if k == pts.size() - 1 and here.distance_to(pts[k]) < 0.8:
			arrived = true
			break
		var now := bridge._game_seconds()
		if now - progress_at > 20.0 or now > limit:
			stuck = true
			break
		if now - trace_at >= 10.0:
			trace_at = now
			trace.append([snappedf(now - t0, 1.0), k, roundi(player.global_position.x), roundi(player.global_position.z)])
		if now - progress_at > 2.0 and side_until < now:
			side_until = now + 0.7
			side = -side
		var to := pts[k] - here
		var yaw := atan2(-to.x, -to.y) + (deg_to_rad(70.0) * side if now < side_until else 0.0)
		bridge._set_view(yaw, 0.0)
		bridge._act(true, &"move_forward")
		await get_tree().physics_frame
		var p := player.global_position
		walked += Vector2(p.x - last.x, p.z - last.z).length()
		if p.y > last.y:
			climb += p.y - last.y
		else:
			drop += last.y - p.y
		last = p
		if p.distance_to(progress_pos) > 1.0:
			progress_pos = p
			progress_at = bridge._game_seconds()
	bridge._act(false, &"move_forward")
	bridge._act(false, &"run")
	var secs := bridge._game_seconds() - t0
	return {"trace": trace if stuck else [], "points": pts.size(), "k": k, "to": id, "arrived": arrived, "stuck_at": arr(player.global_position) if stuck else [], "seconds": snappedf(secs, 0.1),
		"time": "%d:%02d" % [int(secs) / 60, int(secs) % 60], "plan_seconds": snappedf(plan_s, 0.1),
		"plan_time": "%d:%02d" % [int(plan_s) / 60, int(plan_s) % 60], "road_m": snappedf(float(j.length), 1.0),
		"walked_m": snappedf(walked, 1.0), "climb_m": snappedf(climb, 1.0), "descent_m": snappedf(drop, 1.0), "roads": j.roads}
