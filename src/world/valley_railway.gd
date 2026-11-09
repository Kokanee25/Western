class_name ValleyRailway
extends Node3D
## The valley's main line (G3, #716; docs/briefs/valley-plan.md §4, §5, §11, §12; train step 6, #542
## "into the world"): `config/valley.json`'s `railway.route` laid as it stands with the train's own
## code (TrainRoute, TrackLine, TrackChunk), on G2's baked ground, with the daily train on it.
##
##   - **The line** (`line`, a TrackLine at the route's origin): the rail top is the route's (the
##     origin is the rail top at the east entrance: `"height": 0`), so it's where valley_plan.py laid
##     it; its fill and the trestle's bents reach down to the bake (`ground_y` is ValleyTerrain's,
##     which is the ground as Jolt and `Ground.height_at` have it). The bake already holds the line's
##     formation (rail top less 1 m, eased out over its cuts and fills), so the fill under the
##     ballast is that metre's last ~0.5 m; `ground_check()` says where the two disagree.
##   - **The great trestle** (`great_trestle`, the route's crossing): the trestle lab's Trestle, its
##     bents footed on the bake's canyon (not a gorge cut to fit).
##   - **Bridge B** (`overpass`, a RoadBridge): the East Road over the overpass cutting (the bake's),
##     its deck `overpass_deck_over_rail` over the rail, its bents parallel to the track.
##   - **The west portal** (`portal`, a TunnelPortal) at the `west_portal` mark, and its dark mouth.
##   - **The daily train** (`train`, `engineer`): config/valley_timetable.json, the engineer in the
##     cab driving it (TrainEngineer: his hands on the levers, the lookout watching the line). It
##     leaves `east_start` as the game's clock passes `start_hour` each day; at load it's put where
##     the timetable has it by the clock (standing at a stop, or running between two at the planned
##     run's place and speed). Its run is in real seconds: about fifteen game hours of the 45
##     minute day. A lab can take it over (`driving` false).
##
## Built by ValleyWorld after the ground. Nothing in the old town uses it.

const TIMETABLE := "res://config/valley_timetable.json"

var layout: ValleyLayout
var terrain: ValleyTerrain
var tuning: TrainTuning
var line: TrackLine
var overpass: RoadBridge
var portal: TunnelPortal
var train: Train
var engineer: TrainEngineer
var engineer_body: HumanBody
var timetable: TrainTimetable
## Put a train on the line (off: the line alone, for tests of the track; `-- --no-valley-train`, the
## bench's line-alone).
var with_train := train_default
static var train_default := not "--no-valley-train" in OS.get_cmdline_user_args()
## Its engineer drives (false while a lab drives the train).
var driving := true
## The hour the day's train leaves east_start (the timetable's `start_hour`).
var start_hour := 8.0
## The game day whose run the train is on.
var run_day := -1
## What building took, ms: {line, overpass, portal, train}.
var build_ms := {}


func _init() -> void:
	name = "Railway"
	process_physics_priority = -60  # the engineer's hands before the train's tick (-50)


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	if terrain == null:
		terrain = ValleyTerrain.main()
	tuning = load("res://config/train.tres")
	var u := Time.get_ticks_usec()
	line = make_line(layout, tuning, terrain)
	add_child(line)
	line.build()
	build_ms["line"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	_build_overpass()
	build_ms["overpass"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	_build_portal()
	build_ms["portal"] = (Time.get_ticks_usec() - u) / 1000.0
	# The sight world takes new bodies in at its first look after they're added (the trestle lab's
	# trap: ~300 ms on the engineer's first look): taken now, at the build.
	var mid := line.to_global(line.point_at(line.mark_s("trestle_mid")))
	Sight.see(line, mid + Vector3.UP * 3.0, mid + Vector3.UP * 4.0)
	if with_train:
		u = Time.get_ticks_usec()
		_make_train()
		build_ms["train"] = (Time.get_ticks_usec() - u) / 1000.0
	Events.hour_changed.connect(_on_hour)


## The line built again (its trestle and track as new) with a new train on it: the trestle lab's
## fresh viaduct (its collapse runs free the line they broke).
func rebuild() -> void:
	if _fill_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_fill_task)  # (it reads the line)
		_fill_task = -1
	if line and is_instance_valid(line):
		line.free()
	engineer = null
	engineer_body = null
	train = null
	line = make_line(layout, tuning, terrain)
	add_child(line)
	line.build()
	var mid := line.to_global(line.point_at(line.mark_s("trestle_mid")))
	Sight.see(line, mid + Vector3.UP * 3.0, mid + Vector3.UP * 4.0)
	if with_train:
		_make_train()


## The route laid out (not built) in the valley: the TrackLine at the route's origin, turned to its
## heading, the rail top the route's own (valley_plan.py's), the ground under it the bake's.
static func make_line(l: ValleyLayout, t: TrainTuning, ter: ValleyTerrain) -> TrackLine:
	var d := l.route_dict().duplicate(true)
	d["height"] = 0.0  # the origin is the rail top (valley_plan.py lay_route)
	var r := TrainRoute.from_dict(d)
	var tl := r.make_line(t)
	tl.name = "MainLine"
	tl.position = r.origin()
	tl.rotation_degrees.y = 360.0 - r.heading()
	var xf := tl.transform
	tl.ground_y = func(x: float, z: float) -> float:
		var g := xf * Vector3(x, 0.0, z)
		return ter.height(g.x, g.z) - xf.origin.y
	return tl


## A mark's place in the world (the rail top's middle), or NAN in x.
func mark_point(mark: String) -> Vector3:
	var s := line.mark_s(mark)
	if is_nan(s):
		return Vector3(NAN, NAN, NAN)
	return line.to_global(line.point_at(s))


## The line against the ground every `step` m: where the bake's formation (rail top less 1 m) and
## the ground under the line's middle disagree by more than `tol`, as runs {from, to (s), worst (m,
## + the ground over the formation), kind}. The trestle's span and past the west portal are left
## out: the bake leaves them natural (the canyon, the hill over the tunnel).
func ground_check(step := 5.0, tol := 0.1) -> Dictionary:
	var runs := []
	var cur := {}
	var worst := 0.0
	var n := 0
	var portal_s := line.mark_s("west_portal")
	var s := 0.0
	while s <= line.length:
		var skip := line.on_crossing(s) or s > portal_s
		for c: Dictionary in line.crossings:
			skip = skip or (s > float(c.from_s) - 3.0 and s < float(c.to_s) + 3.0)
		if not skip:
			var p := line.to_global(line.point_at(s))
			var diff := terrain.height(p.x, p.z) - (p.y - 1.0)
			worst = maxf(worst, absf(diff))
			n += 1
			if absf(diff) > tol:
				if cur.is_empty():
					cur = {"from": s, "to": s, "worst": diff}
				cur.to = s
				if absf(diff) > absf(float(cur.worst)):
					cur.worst = diff
			elif not cur.is_empty():
				runs.append(cur)
				cur = {}
		elif not cur.is_empty():
			runs.append(cur)
			cur = {}
		s += step
	if not cur.is_empty():
		runs.append(cur)
	return {"points": n, "worst": worst, "runs": runs}


# --- Bridge B, the overpass ------------------------------------------------------------------------

## The East Road over the cutting at the `overpass` mark: the deck level at the rail plus the plan's
## clearance, out along the road each way to where the ground meets its underside; the main span's
## two bents `span` apart about the track, approach bents no further apart than `approach`.
func _build_overpass(span := 14.0, approach := 7.0) -> void:
	var b: Dictionary = layout.bridge("bridge_b")
	var road := layout.road_line(str(b.get("road", "east_road")))
	var s := line.mark_s(str(b.get("route_mark", "overpass")))
	if is_nan(s) or road.size() < 2:
		return
	var rail := line.to_global(line.point_at(s))
	var cl: Dictionary = layout.railway().get("clearance", {})
	var deck_top := rail.y + float(cl.get("overpass_deck_over_rail", 5.45))
	var depth := float(cl.get("deck_structure", 0.5))
	# The road's direction where it crosses: the segment of its line nearest the rail.
	var p2 := Vector2(rail.x, rail.z)
	var best := INF
	var dir := Vector2.RIGHT
	for i in road.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p2, road[i], road[i + 1])
		if q.distance_to(p2) < best:
			best = q.distance_to(p2)
			dir = (road[i + 1] - road[i]).normalized()
	var ter := terrain
	var br := RoadBridge.spanning(rail, Vector3(dir.x, 0.0, dir.y), deck_top,
			func(x: float, zz: float) -> float: return ter.height(x, zz), span, approach, depth)
	var f := line.global_transform * line.transform_at(s)
	br.name = "BridgeB"
	br.structure_id = &"bridge_b"
	br.width = 5.0
	br.bent_dir = -f.basis.z
	add_child(br)
	overpass = br


# --- The west portal ---------------------------------------------------------------------------

func _build_portal() -> void:
	var s := line.mark_s("west_portal")
	if is_nan(s):
		return
	var tp := TunnelPortal.new()
	tp.name = "WestPortal"
	tp.structure_id = &"west_portal"
	tp.frame = line.global_transform * line.transform_at(s)
	var ter := terrain
	tp.ground = func(x: float, z: float) -> float: return ter.height(x, z)
	add_child(tp)
	add_child(tp.make_mouth())
	portal = tp


# --- The daily train ---------------------------------------------------------------------------

## The timetable's times are worked out from the line by driving each leg once (TrainTimetable.fill:
## ~4 s here for the valley's three legs), on a worker: the valley loads without waiting for it, the
## train stands at east_start, and it's put where the clock has it when they're ready (`timed`).
var timed := false
var _fill_task := -1


func _make_train() -> void:
	timetable = TrainTimetable.load_file(TIMETABLE)
	start_hour = float(timetable.data.get("start_hour", 8.0))
	timed = false
	train = Train.new()
	train.name = "Train"
	line.add_child(train)
	train.setup(line, tuning)
	train.rider = get_parent().get_node_or_null(^"Player") as CharacterBody3D if get_parent() else null
	train.place(line.mark_s("east_start"))
	train.sim.brake_lever = 1.0
	var tt := timetable
	var tl := line
	var tu := tuning
	var ms := build_ms
	_fill_task = WorkerThreadPool.add_task(func() -> void:
		var u := Time.get_ticks_usec()
		tt.fill(tl, tu)
		ms["timetable"] = (Time.get_ticks_usec() - u) / 1000.0, true, "valley timetable")


## The timetable's fill finished: the train put where the clock has it. True once it's timed.
func _take_timetable() -> bool:
	if timed:
		return true
	if _fill_task < 0 or not WorkerThreadPool.is_task_completed(_fill_task):
		return false
	WorkerThreadPool.wait_for_task_completion(_fill_task)
	_fill_task = -1
	timed = true
	if driving:
		sync_to_clock()
	return true


func _notification(what: int) -> void:
	# (Every task of ours waited for before it's freed: issue #392.)
	if what == NOTIFICATION_PREDELETE and _fill_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_fill_task)
		_fill_task = -1


## Real seconds in a game hour (the day cycle's day is 45 minutes: 112.5).
func seconds_per_hour() -> float:
	var dc := _day_cycle()
	if dc and dc.config:
		return float(dc.config.day_length_seconds) / 24.0
	return 2700.0 / 24.0


func _day_cycle() -> DayCycle:
	var p := get_parent()
	return p.get_node_or_null(^"DayCycle") as DayCycle if p else null


## The train where the timetable has it by the game's clock now (its run started at start_hour).
func sync_to_clock() -> void:
	var dc := _day_cycle()
	var hour := dc.time_of_day if dc else 12.0
	var day := dc.day if dc else 1
	start_run((hour - start_hour) * seconds_per_hour(), day)


## The day's run, `elapsed` real seconds since it left east_start (- before it leaves): the train put
## where the timetable has it then, standing at a stop (the engineer leaves when the timetable says)
## or running between two at the planned run's place and speed (he drives on from there).
func start_run(elapsed: float, day := -1) -> void:
	if train == null or not timed:
		return
	run_day = day
	var k := 0
	for i in timetable.stops.size():
		if i > 0 and elapsed >= float(timetable.stops[i].get("arrive", INF)):
			k = i
	if train.wreck:
		return  # (a wreck stays where it lies; the railroad's crew is TrackRepair's)
	var leg := _on_leg(elapsed, k)
	train.place(float(timetable.stops[k].s) + float(leg.get("distance", 0.0)))
	train.sim.time = elapsed
	engineer = TrainEngineer.new(train.sim, line)
	engineer.lookout = train.lookout
	if leg.is_empty():
		engineer.run(timetable, 0.0, k)
	else:
		train.sim.set_speed(float(leg.speed))
		train.sim.brake_lever = 0.0
		engineer.join(timetable, k)
	_put_engineer_in_cab()
	engineer.body = engineer_body


## Where the timetable has the train `elapsed` s into the run if it's between stop k and the next:
## {distance (m on from stop k), speed (m/s)} from the leg's planned run stretched to the time
## allowed; empty if it's standing at stop k.
func _on_leg(elapsed: float, k: int) -> Dictionary:
	if k >= timetable.stops.size() - 1 or k >= timetable.legs.size():
		return {}
	var dep := float(timetable.stops[k].get("depart", INF))
	if elapsed <= dep:
		return {}
	var leg: Dictionary = timetable.legs[k]
	var stretch := float(leg.time) / maxf(float(leg.allowed), 1e-6)
	var t_in := (elapsed - dep) * stretch
	var prof: Array = leg.profile
	for i in range(1, prof.size()):
		var p0: Array = prof[i - 1]
		var p1: Array = prof[i]
		if float(p1[1]) >= t_in:
			var dt := maxf(float(p1[1]) - float(p0[1]), 1e-6)
			var f := clampf((t_in - float(p0[1])) / dt, 0.0, 1.0)
			var d := lerpf(float(p0[0]), float(p1[0]), f)
			if d > float(leg.distance) - 2.0:
				return {}  # (as good as there: stood on the next stop's side of it, he creeps on)
			return {"distance": d, "speed": (float(p1[0]) - float(p0[0])) / dt * stretch}
	return {}


func _put_engineer_in_cab() -> void:
	if engineer_body and is_instance_valid(engineer_body):
		engineer_body.queue_free()
	engineer_body = null
	if train.view.solids.is_empty():
		return
	var engine: AnimatableBody3D = train.view.solids[0]
	var c: Dictionary = train.sim.cars[0]
	var mid: float = (c.trucks.x + c.trucks.y) * 0.5
	var at := Vector3(0.55, TrainCars.DECK, float(c.length) - mid - 1.1)  # on the right, at the brake stand
	var man := HumanBody.new()
	man.person_id = &"engineer"
	man.name = "Engineer"
	man.rng_seed = 716
	man.has_gun = false
	man.set_meta(&"train_rides", true)
	man.enter(engine, engine.global_transform * at, engine.global_rotation.y)
	engineer_body = man
	if train.far:
		man.process_mode = Node.PROCESS_MODE_DISABLED


func _on_hour(hour: int) -> void:
	if train == null or not driving or not timed:
		return
	var dc := _day_cycle()
	if dc == null or hour != int(floor(start_hour)) or dc.day == run_day:
		return
	if engineer and engineer.state != TrainEngineer.DONE:
		return  # (yesterday's still running: a clock pushed on hard)
	start_run((dc.time_of_day - start_hour) * seconds_per_hour(), dc.day)


func _physics_process(delta: float) -> void:
	if train and not timed and _take_timetable():
		return
	if driving and engineer and train and not train.wreck:
		engineer.drive(delta)
	_check_far()


## The train far from the eye (the camera, else the player): past `far_m` its cars aren't drawn or
## heard and its engineer's body stands still (Train.far); back inside `far_m - 50` it's all as ever.
## The fog hides anything past ~500 m.
var far_m := 800.0


func _check_far() -> void:
	if train == null or train.wreck:
		return
	var eye: Node3D = get_viewport().get_camera_3d() if is_inside_tree() else null
	if eye == null:
		eye = get_parent().get_node_or_null(^"Player") as Node3D if get_parent() else null
	if eye == null:
		return
	var sim := train.sim
	var mid := line.to_global(line.point_at(sim.s - sim.length * 0.5))
	var d := mid.distance_to(eye.global_position) - sim.length * 0.5
	var far := d > far_m if not train.far else d > far_m - 50.0
	if far != train.far:
		train.far = far
		if engineer_body and is_instance_valid(engineer_body):
			engineer_body.process_mode = Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT


## Where the train is and what the engineer's doing.
func report() -> Dictionary:
	if train == null:
		return {"train": false}
	var near := ""
	var best := INF
	for m in line.marks:
		var dd := absf(float(line.marks[m]) - train.sim.s)
		if dd < best:
			best = dd
			near = String(m)
	var at := line.to_global(line.point_at(train.sim.s))
	return {"s": snappedf(train.sim.s, 0.01), "kmh": snappedf(train.sim.v * 3.6, 0.1), "time": snappedf(train.sim.time, 0.1),
		"near": near, "from_mark": snappedf(train.sim.s - float(line.marks.get(near, 0.0)), 0.1),
		"at": [snappedf(at.x, 0.1), snappedf(at.y, 0.01), snappedf(at.z, 0.1)],
		"state": ["wait", "run", "done"][engineer.state] if engineer else "none",
		"stop": engineer.stop if engineer else -1, "delay": snappedf(engineer.delay(), 0.1) if engineer else 0.0,
		"day": run_day, "derail": train.derail, "driving": driving, "build_ms": build_ms}
