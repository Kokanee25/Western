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

const HELP := {
	"valley_train": "valley_train [run [S] | at MARK [KMH] | sync] -> the valley's daily train: where it is, the engineer's state; run: the day's run from S s after it leaves (no S: by the clock); at: stood with its front on MARK (or held at KMH), nobody driving",
	"valley_view": "valley_view VP|MARK [LOOK] -> you at a valley viewpoint (vp_*) or beside a route mark, looking at LOOK (a mark or viewpoint; trestle_mid)",
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
