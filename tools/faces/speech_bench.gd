extends SceneTree
## What FaceSpeech costs: planning every line the brains say (once per line, when he says it), and
## stepping N talking men who all talk without a break (every frame), headless.
##   godot --headless -s res://tools/faces/speech_bench.gd -- [--men=10] [--seconds=10]
## Wall-clock on this machine; the frame budget's numbers are Sean's core (×0.65, FrameBudget's clock_scale).
## Untyped where it touches game classes: -s scripts compile before the autoloads exist.

const MEN := ["hothead_lyle_s2_talking", "barkeep_s2_talking", "doctor_s2_talking", "widow_s2_talking",
	"colter_rider_s2_talking", "sean_s3_talking", "old_rancher_s3_talking", "young_drifter_s3_talking",
	"bold_cowboy_s3_talking", "bold_cowboy_talking"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var n := 10
	var seconds := 10.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--men="):
			n = int(a.substr(6))
		elif a.begins_with("--seconds="):
			seconds = float(a.substr(10))
	var fs = load("res://src/bodies/face_speech.gd")
	var lines := []
	for path: String in ["res://src/bodies/outlaw_brain.gd", "res://src/people/civilian_brain.gd"]:
		var table: Dictionary = load(path).LINES
		for k: StringName in table:
			for l: String in table[k]:
				lines.append(l.format({"name": "Brody"}))
	var worst := 0
	fs.plan("Warm up.")   # (its tuning loaded, its pattern compiled: once a game)
	var t0 := Time.get_ticks_usec()
	for l: String in lines:
		var t1 := Time.get_ticks_usec()
		fs.plan(l)
		worst = maxi(worst, Time.get_ticks_usec() - t1)
	var plan_ms := (Time.get_ticks_usec() - t0) / 1000.0 / lines.size()
	var men := []
	for i in n:
		var m = load("res://src/bodies/human_body.gd").new()
		m.body_model = StringName(MEN[i % MEN.size()])
		m.person_id = StringName("bench_%d" % i)
		root.add_child(m)
		m.global_position = Vector3(i * 1.5, 0, 0)
		men.append(m)
	for f in 4:
		await physics_frame
	var speech := []
	for m in men:
		var s = m.get_node(^"FaceSpeech")
		s.auto = false
		speech.append(s)
	var dt := 1.0 / 60.0
	var k := 0
	var spent := 0
	var frames := int(seconds / dt)
	for f in frames:
		for s in speech:
			if not s.speaking():
				s.say(lines[k % lines.size()])
				k += 1
		var t1 := Time.get_ticks_usec()
		for s in speech:
			s.step(dt)
		spent += Time.get_ticks_usec() - t1
	var per_frame := spent / 1000.0 / frames
	print("speech_bench: plan %.3f ms a line (worst %.3f ms, %d lines); %d men talking: %.3f ms a frame (%.1f µs a man), "
			% [plan_ms, worst / 1000.0, lines.size(), n, per_frame, per_frame * 1000.0 / n]
			+ "at Sean's ×0.65: %.3f ms a frame against People's 4.0" % (per_frame * 0.65))
	quit()
