class_name Train
extends Node3D
## A train on a TrackLine (docs/briefs/train.md, step 1): the 1D simulation (`TrainSim`) on the
## physics tick, the cars drawn (`TrainView`) between ticks at the interpolated distance, so they
## move smoothly at any frame rate. A child of the TrackLine.
##
## `record` keeps a row a tick (time, s, v, forces, levers) for the lab's graphs.

var tuning: TrainTuning
var track: TrackLine
var sim: TrainSim
var view: TrainView
var record := false
var rows: Array = []
## The last drawn distance (the view's s), for checks.
var drawn_s := 0.0
## What it costs: microseconds summed over ticks and drawn frames since `cost_reset()`.
var cost := {}


func setup(on_track: TrackLine, t: TrainTuning) -> void:
	track = on_track
	tuning = t
	sim = TrainSim.new(t, track)
	if view == null:
		view = TrainView.new()
		view.name = "Cars"
		add_child(view)
	view.setup(track, sim)


func place(s: float) -> void:
	sim.place(s)
	drawn_s = s
	view.place(s)


func _physics_process(delta: float) -> void:
	if sim == null:
		return
	var t0 := Prof.start()
	var u := Time.get_ticks_usec()
	sim.step(delta)
	if record:
		rows.append(row())
	cost.tick_us = cost.get("tick_us", 0) + Time.get_ticks_usec() - u
	cost.ticks = cost.get("ticks", 0) + 1
	Prof.stop(&"train", t0)


func _process(_delta: float) -> void:
	if sim == null:
		return
	var t0 := Prof.start()
	var u := Time.get_ticks_usec()
	drawn_s = lerpf(sim.s_before, sim.s, Engine.get_physics_interpolation_fraction())
	view.place(drawn_s)
	cost.draw_us = cost.get("draw_us", 0) + Time.get_ticks_usec() - u
	cost.draws = cost.get("draws", 0) + 1
	Prof.stop(&"train_view", t0)


func cost_reset() -> void:
	cost = {}


func row() -> Dictionary:
	return {"t": sim.time, "s": sim.s, "v": sim.v, "throttle": sim.throttle, "regulator": sim.regulator,
		"steam": sim.steam, "brake_lever": sim.brake_lever, "brake": sim.brake, "f_tractive": sim.f_tractive,
		"f_resist": sim.f_resist, "f_grade": sim.f_grade, "f_brake": sim.f_brake,
		"grade": track.grade_at(sim.s - sim.length * 0.5) if track else 0.0, "limit": String(sim.limit)}
