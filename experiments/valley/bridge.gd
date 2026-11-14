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
##   valley_sight HEIGHT                  you on a place with height's high spot (#736 B), each of its
##                                       targets measured: distance, how far below, the line from your
##                                       eye to a man's chest there clear over the ground (the bake,
##                                       every metre) and through the world (blocks, buildings: a ray)
##   valley_climb HEIGHT                  you at its ladder's foot walking into it: on top, and how long

const HELP := {
	"valley_train": "valley_train [run [S] | at MARK [KMH] | sync] -> the valley's daily train: where it is, the engineer's state; run: the day's run from S s after it leaves (no S: by the clock); at: stood with its front on MARK (or held at KMH), nobody driving",
	"valley_view": "valley_view VP|MARK [LOOK] -> you at a valley viewpoint (vp_*) or beside a route mark, looking at LOOK (a mark or viewpoint; trestle_mid)",
	"valley_sight": "valley_sight HEIGHT -> you on a valley height's high spot (#736 B); each target: distance, drop, the line to a man's chest there clear over the ground and through the blocks",
	"valley_climb": "valley_climb HEIGHT -> you at a valley height's ladder foot, walking into it: whether you got on top and how long it took",
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
	# A place with height (#736 B): where a man goes to it (its ladder's foot, its high spot), not
	# its middle (a building's).
	if not ValleyLayout.main().height(id).is_empty() and street is ValleyWorld and (street as ValleyWorld).places().has(StringName(id)):
		var q := (street as ValleyWorld).places().at(StringName(id))
		return Vector2(q.x, q.z)
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


## The valley's markers (ValleyMarkers), or null.
func _markers() -> ValleyMarkers:
	return (street as ValleyWorld).markers if street is ValleyWorld else null


## How a man's eye over his feet, and what's aimed at over a target's ground (valley_plan.py's).
const SIGHT_EYE := 1.6
const SIGHT_CHEST := 1.2
## How far in from a roof's or platform's edge a man stands to shoot over it (m).
const SIGHT_LIP := 0.4


func _cmd_valley_sight(a: Array) -> Dictionary:
	var mk := _markers()
	if a.is_empty() or mk == null:
		return {"ok": false, "error": "valley_sight HEIGHT (world valley)"}
	var hp := ValleyLayout.main().height(str(a[0]))
	if hp.is_empty():
		return {"ok": false, "error": "no height %s" % a[0]}
	var feet := mk.high_spot(str(a[0]))
	player.velocity = Vector3.ZERO
	player.global_position = feet + Vector3.UP * 0.05
	await physics_frames(3)
	var ter := ValleyTerrain.main()
	var out := []
	var all_clear := true
	var on_block := mk.block_at(Vector2(feet.x, feet.z))
	for t: Dictionary in hp.targets:
		var c := ValleyLayout.xz(t.at)
		# A man on a roof or a platform steps to its edge toward what he shoots at (SIGHT_LIP in).
		var at := feet
		var f2 := Vector2(feet.x, feet.z)
		if not on_block.is_empty():
			var d2 := (c - f2).normalized()
			var e := ValleyMarkers.block_exit(on_block, f2, d2)
			f2 += d2 * maxf(e - SIGHT_LIP, 0.0)
			at = Vector3(f2.x, feet.y, f2.y)
		var eye := at + Vector3.UP * SIGHT_EYE
		# A target in a building is the man at its side toward the shooter; on a rock (a block that
		# names a place on its top) the man on top.
		var aim_y := mk.surface(c.x, c.y)
		var tb := mk.block_at(c)
		if not tb.is_empty():
			if String(tb.get("stand", "")) != "":
				aim_y = (tb.centre as Vector3).y + (tb.size as Vector3).y
			else:
				var back := (f2 - c).normalized()
				c += back * (ValleyMarkers.block_exit(tb, c, back) + 1.5)
				aim_y = mk.surface(c.x, c.y)
		var aim := Vector3(c.x, aim_y + SIGHT_CHEST, c.y)
		var dist := Vector2(c.x - at.x, c.y - at.z).length()
		# Over the ground: every metre, past the first and last 3 m (the men's own footing).
		var gap := INF
		var n := maxi(int(dist), 2)
		for k in range(1, n):
			var f := float(k) / n
			if f * dist < 3.0 or (1.0 - f) * dist < 3.0:
				continue
			var q := eye.lerp(aim, f)
			gap = minf(gap, q.y - ter.height(q.x, q.z))
		# Through the world: a ray from 0.5 m out to 0.5 m short (blocks, the town, structures).
		await get_tree().physics_frame
		var dir := (aim - eye).normalized()
		var q := PhysicsRayQueryParameters3D.create(eye + dir * 0.5, aim - dir * 0.5, Layers.WORLD)
		q.exclude = [player.get_rid()]
		var hit := World.space(player).intersect_ray(q)
		var hit_what := ""
		if not hit.is_empty():
			var p: Vector3 = hit.position
			# The ground's own hit within the footing allowance isn't a block in the way.
			if Vector2(p.x - at.x, p.z - at.z).length() > 3.0 and Vector2(p.x - c.x, p.z - c.y).length() > 3.0:
				hit_what = "%s at %s" % [(hit.collider as Node).name if hit.collider is Node else "?", arr(p)]
		var ok := gap > 0.3 and hit_what == ""
		all_clear = all_clear and ok
		out.append({"name": t.name, "distance": snappedf(dist, 1.0), "below": snappedf(eye.y - aim.y, 0.1), "clear": ok,
			"ground_gap": snappedf(gap, 0.1), "hit": hit_what})
	return {"height": str(a[0]), "feet": arr(feet), "all_clear": all_clear, "targets": out}


func _cmd_valley_climb(a: Array) -> Dictionary:
	var mk := _markers()
	if a.is_empty() or mk == null:
		return {"ok": false, "error": "valley_climb HEIGHT (world valley)"}
	var lad := {}
	for l: Dictionary in mk.ladders:
		if l.id == str(a[0]):
			lad = l
	if lad.is_empty():
		return {"ok": false, "error": "no ladder at %s" % a[0]}
	var ladder: Ladder = lad.ladder
	player.velocity = Vector3.ZERO
	player.global_position = lad.foot
	await physics_frames(3)
	bridge._face(ladder.global_position + Vector3.UP * 1.5)
	await physics_frames(1)
	var t0 := bridge._game_seconds()
	var top: Vector3 = lad.top
	var got_on := false
	var on_top := false
	while bridge._game_seconds() - t0 < 10.0 + ladder.height / ladder.climb_speed * 2.0:
		bridge._act(true, &"move_forward")
		await get_tree().physics_frame
		got_on = got_on or player.ladder != null
		if player.ladder == null and player.global_position.y > top.y - 0.3:
			on_top = true
			break
	bridge._act(false, &"move_forward")
	await physics_frames(10)
	var p := player.global_position
	return {"height": str(a[0]), "ladder_m": snappedf(ladder.height, 0.1), "got_on": got_on, "on_top": on_top and p.y > top.y - 0.3,
		"seconds": snappedf(bridge._game_seconds() - t0, 0.1), "at": arr(p), "top": arr(top)}
