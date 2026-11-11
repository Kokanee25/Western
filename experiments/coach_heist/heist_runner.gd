extends Node3D
## The coach heist lab's runner (issue #770; heist.gd starts it). Modes (--mode=):
##   roll  the log let go at the top of a bare 1:1.5 bank `--drops` high (no step, no coach): its
##         speed at the foot against the lossless roll, sqrt(4/3 g h) (#784's table)
##   tip   the coach standing, a log `--radii` thrown sideways into its low plates' middle (1.39 m
##         up) at `--speeds`: over or not, the lean; the threshold against #784's 4,100 N.s
##   swing the ram (#794) let go from `--drops` (its middle held that high over the bottom of its
##         swing): its speed at the bottom against sqrt(2 g h), the time, the ropes' pull; and the
##         standing coach struck by it at the bottom: over or not, the lean, the dents
##   cut   the coach cut in the valley (#794: CoachCut on the bake's ground round it), `--seeds`
##         times: the coach driven up the South Road, the pin let go a swing's time short of the ram
##         (each seed a little earlier or later); over or not, the dents, every frame timed
##   heist the whole of it, `--seeds` times: the striker (`--striker=ram`, the default, or `roll`)
##         let go as the driven coach comes up (each seed a little earlier or later), into its side;
##         the speeds, the lean, the traces, the dents, the guards, the men on the box and the
##         strongbox; every physics frame timed (#492's gate: none over 100 ms at Sean's, x0.65 of here)
## Writes <out>/<mode>.json and <out>/<mode>.md.

var args := {}
var out := ""
var mode := "heist"
var rows: Array = []
var _cases: Array = []
var _case := -1
var _site: Node3D
var _tick := 0
var _ticks := 0
var _frame_us: Array[float] = []
var _last_us := 0
var _case_frames: Array[float] = []
const SITE := "res://experiments/coach_heist/heist_site.gd"
const CUT_SITE := "res://experiments/coach_heist/cut_site.gd"


func _ready() -> void:
	mode = String(args.get("mode", "heist"))
	out = String(args.get("out", "build/coach_heist/" + mode))
	if not out.is_absolute_path():
		out = ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(out)
	match mode:
		"roll":
			for d in _floats("drops", "2,4,6,8"):
				_cases.append({"drop": d, "step": 0.0, "with_coach": false, "seconds": 6.0})
		"swing":
			for d in _floats("drops", "2,2.5,3,3.3,3.6,4"):
				for with_coach in [false, true]:
					_cases.append({"pull_up": d, "with_coach": with_coach, "drive": false, "guards": 4 if with_coach else 0,
							"coach_x": 0.0, "seconds": 6.0})
		"cut":
			for s in int(args.get("seeds", 8)):
				_cases.append({"seed": s, "seconds": float(args.get("seconds", 36.0)), "guards": int(args.get("guards", 4)),
						"lead_shift": (float(s) - (float(args.get("seeds", 8)) - 1.0) * 0.5) * float(args.get("spread", 0.06))})
		"tip":
			for r in _floats("radii", "0.25,0.3,0.35"):
				for v in _floats("speeds", "2,3,3.5,4,4.5,5,5.5,6,7,8"):
					_cases.append({"log_r": r, "v": v, "with_log": false, "drive": false, "guards": 0, "seconds": 5.0})
		_:
			var ram := String(args.get("striker", "ram")) == "ram"
			for s in int(args.get("seeds", 8)):
				var c := {"seed": s, "striker": "ram" if ram else "roll", "log_r": float(args.get("log_r", 0.3)),
						"seconds": float(args.get("seconds", 10.0 if ram else 12.0)), "guards": int(args.get("guards", 4)),
						"lead_shift": (float(s) - (float(args.get("seeds", 8)) - 1.0) * 0.5) * float(args.get("spread", 0.06 if ram else 0.12))}
				for k in ["pull_up", "bottom_y", "rope", "coach_z", "speed"]:
					if args.has(k):
						c[k] = float(args[k])
				if not ram:
					c["ledge"] = float(args.get("ledge", 0.6))
					c["step"] = float(args.get("step", 2.5))
				_cases.append(c)
	if args.has("only"):
		var keep := []
		for i in String(args.only).split(","):
			keep.append(_cases[int(i)])
		_cases = keep
	_next()


func _floats(key: String, dflt: String) -> Array[float]:
	var o: Array[float] = []
	for v in String(args.get(key, dflt)).split(","):
		o.append(float(v))
	return o


func _next() -> void:
	if _site:
		rows[-1]["frames"] = _frame_summary(_case_frames)
		_site.queue_free()
		_site = null
	_case += 1
	if _case >= _cases.size():
		_write()
		get_tree().quit(0)
		return
	var c: Dictionary = _cases[_case].duplicate()
	_site = load(CUT_SITE if mode == "cut" else SITE).new()
	_site.name = "Site%d" % _case
	add_child(_site)
	var o := c.duplicate()
	if mode == "cut":
		o["release_lead"] = 1.4 * (float(args.get("swing_s", 1.28)) + float(c.lead_shift))
	elif mode == "heist" and c.striker == "ram":
		# Let go when the coach's middle is a swing's time short of the ram's line (the swing
		# mode's ~1.2 s to the bottom), plus the seed's shift: it meets the coach's middle.
		var v := float(c.get("speed", 1.4))
		o["release_at_x"] = v * (float(args.get("swing_s", 1.28)) + float(c.lead_shift))
		o["coach_x"] = float(o.release_at_x) + 6.0
	elif mode == "heist":
		# The coach starts far enough back that the log, let go when the coach reaches the mark, meets
		# its middle: the roll's measured time (~2.6 s from the deck to the coach's side).
		o["coach_z"] = float(args.get("coach_z", 0.6))
		o["release_at_x"] = 1.4 * (float(args.get("roll_s", 2.6)) + float(c.lead_shift))
		o["coach_x"] = float(o.release_at_x) + 6.0
	_site.build(o)
	_site.watch.debug = args.has("debug")
	_tick = 0
	_ticks = int(float(c.seconds) * 60.0)
	_case_frames.clear()
	rows.append({"case": c})


func _physics_process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_us > 0 and _site and _tick > 10:  # (not the site being built)
		_case_frames.append((now - _last_us) / 1000.0)
		if args.has("spikes") and (now - _last_us) > 40000:
			var ho := -1.0
			for e: Dictionary in _site.drive.events if _site.drive else []:
				if e.what == "handed_off":
					ho = e.t
			print("spike %.0f ms at t %.3f (hand-off %.3f) dents %d" % [(now - _last_us) / 1000.0, _site.t, ho, _site.watch.made.size()])
	_last_us = now
	if _site == null:
		return
	_tick += 1
	var c: Dictionary = _cases[_case]
	if _tick == 5:
		_start(c)
	if args.has("debug") and _site.drive and _site.drive.loose and not _site.has_meta(&"told"):
		_site.set_meta(&"told", true)
		var b: RigidBody3D = _site.drive.main_body()
		print("body mass %.0f com %s (world %s) inertia %s mode %d" % [b.mass, b.center_of_mass, b.global_transform * b.center_of_mass, b.inertia, b.center_of_mass_mode])
		if args.has("spin"):
			b.angular_velocity = Vector3(float(args.spin), 0, 0)
		if args.has("slide"):
			b.linear_velocity = Vector3(0, 0, float(args.slide))
	if args.has("ropes") and _site.get(&"ram") and not _site.ram.is_held():
		var tn: Array[float] = _site.ram.tension
		if tn[0] + tn[1] > 5000.0:
			print("t%d ropes %.1f %.1f kN" % [_tick, tn[0] / 1000.0, tn[1] / 1000.0])
	if args.has("debug") and _tick % 6 == 0 and _site.get(&"log_body"):
		var mb: RigidBody3D = _site.drive.main_body() if _site.drive else null
		print("t%d log %s v %s | coach %s v %s w %s lean %.1f frz %s" % [_tick, _site.log_body.global_position, _site.log_body.linear_velocity,
				mb.global_position if mb else Vector3.ZERO, mb.linear_velocity if mb else Vector3.ZERO, mb.angular_velocity if mb else Vector3.ZERO,
				_site.drive.lean() if _site.drive else 0.0, mb.freeze if mb else false])
	if _tick >= _ticks:
		var r: Dictionary = _site.result()
		r.merge(rows[-1], true)
		r["line"] = _line(r)
		rows[-1] = r
		print("%s %d/%d %s" % [mode, _case + 1, _cases.size(), r.line])
		_next()


func _start(c: Dictionary) -> void:
	match mode:
		"roll", "swing":
			_site.release_log()
		"tip":
			# A log beside the standing coach, its middle at the low plates' middle, thrown at it.
			var r := float(c.log_r)
			var lg := RollingLog.new()
			lg.radius = r
			lg.length = 6.0
			_site.add_child(lg)
			lg.global_position = Vector3(0.0, float(args.get("hit_y", 1.39)), -0.71 - r - 0.08)
			lg.linear_velocity = Vector3(0.0, 0.0, float(c.v))
			_site.log_body = lg
			_site.drive.strikers.append(lg)


func _line(r: Dictionary) -> String:
	match mode:
		"cut":
			return "seed %d: swing %.2f s, hit %s, lean %.0f %s, dents %d, deepest %.1f cm, traces left %d, strongbox loose %s, ropes' most %.1f kN" % [
					r.case.seed, r.hit_at - r.released_at, r.hit, r.max_lean, "OVER" if r.over else "stood", r.dents, r.deepest_cm, r.traces_on,
					r.get("strongbox_loose", false), float(r.ram.get("most_tension_n", 0.0)) / 1000.0]
		"roll":
			return "drop %.1f: at the foot %.2f m/s (lossless %.2f)" % [r.drop, float(r.log_at_foot.get("speed", -1.0)), r.lossless_at_foot]
		"swing":
			var b: Dictionary = r.get("ram_at_bottom", {})
			var line := "drop %.1f: at the bottom %.2f m/s (lossless %.2f) in %.2f s, ropes' most pull %.1f kN" % [
					r.case.pull_up, float(b.get("speed", -1.0)), float(r.ram.lossless), float(b.get("t", -1.0)), float(b.get("tension_n", 0.0)) / 1000.0]
			if r.case.with_coach:
				line += " | the coach: lean %.0f %s, dents %d, deepest %.1f cm" % [r.max_lean, "OVER" if r.over else "stood", (r.dents as Array).size(), _deepest(r) * 100.0]
			return line
		"tip":
			var j: float = _site.log_body.mass * float(r.case.v)
			return "r %.2f (%.0f kg) v %.1f (%.0f N.s carried): lean %.0f %s" % [r.case.log_r, _site.log_body.mass, r.case.v, j, r.max_lean, "OVER" if r.over else "back"]
	if r.case.get("striker", "roll") == "ram":
		var off := 0
		var on_box := 0
		for g: Dictionary in r.guards:
			if g.who in ["driver", "messenger"]:
				on_box += 1
				if g.get("y", 9.0) < 1.2:
					off += 1
		return "seed %d: swing %.2f s, hit %.2f m/s (vz %.2f vy %.2f at y %.2f, %.2f m along), lean %.0f %s, traces left %d, dents %d, deepest %.1f cm, heads %d, box men down %d/%d, strongbox %s" % [
				r.case.seed, float(r.log_at_hit.get("after_release", -1.0)), float(r.log_at_hit.get("speed", -1.0)),
				float(r.log_at_hit.get("vz", -1.0)), float(r.log_at_hit.get("vy", 0.0)), float(r.log_at_hit.get("y", -1.0)), float(r.log_at_hit.get("x", 0.0)),
				r.max_lean, "OVER" if r.over else "stood", r.traces_on, (r.dents as Array).size(), _deepest(r) * 100.0,
				(r.head_blows as Array).size(), off, on_box, "in" if r.get("strongbox", {}).get("in_coach", false) else "out"]
	return "seed %d: roll %.2f s, foot %.2f, hit %.2f (vz %.2f vy %.2f at y %.2f), lean %.0f %s, traces left %d, dents %d, deepest %.1f cm, heads %d" % [
		r.case.seed, float(r.log_at_hit.get("after_release", -1.0)), float(r.log_at_foot.get("speed", -1.0)), float(r.log_at_hit.get("speed", -1.0)),
		float(r.log_at_hit.get("vz", -1.0)), float(r.log_at_hit.get("vy", 0.0)), float(r.log_at_hit.get("y", -1.0)), r.max_lean, "OVER" if r.over else "stood",
		r.traces_on, (r.dents as Array).size(), _deepest(r) * 100.0, (r.head_blows as Array).size()]


static func _deepest(r: Dictionary) -> float:
	var d := 0.0
	for e: Dictionary in r.dents:
		d = maxf(d, float(e.depth))
	return d


static func _frame_summary(f: Array[float]) -> Dictionary:
	if f.is_empty():
		return {}
	var s := f.duplicate()
	s.sort()
	return {"max_ms": s[-1], "p99_ms": s[int(s.size() * 0.99)], "mean_ms": s.reduce(func(a, b): return a + b, 0.0) / s.size(),
			"max_at_seans": s[-1] * 0.65, "over_100_at_seans": s.filter(func(x): return x * 0.65 > 100.0).size()}


func _write() -> void:
	var f := FileAccess.open(out.path_join(mode + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  "))
	f.close()
	var md := FileAccess.open(out.path_join(mode + ".md"), FileAccess.WRITE)
	md.store_line("# Coach heist lab: %s\n" % mode)
	for r: Dictionary in rows:
		md.store_line("- " + String(r.get("line", "")) + "  (frames max %.0f ms here, %.0f at Sean's)" % [float(r.get("frames", {}).get("max_ms", 0.0)), float(r.get("frames", {}).get("max_at_seans", 0.0))])
	md.close()
