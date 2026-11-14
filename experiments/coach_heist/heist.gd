extends SceneTree
## The coach heist lab (issue #770; README.md beside this):
##   godot --headless --fixed-fps 60 -s res://experiments/coach_heist/heist.gd -- --mode=roll|tip|heist --out=DIR
##       roll:  [--drops=2,4,6,8]
##       tip:   [--radii=0.25,0.3,0.35] [--speeds=2,3,...]
##       heist: [--seeds=5] [--seconds=9] [--guards=4] [--roll_s=2.6]
## Untyped on purpose: -s scripts compile before autoloads exist.

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_run.call_deferred()


func _run() -> void:
	var script: GDScript = load("res://experiments/coach_heist/heist_runner.gd")
	if script == null or not script.can_instantiate():
		push_error("coach heist lab: heist_runner.gd doesn't load")
		quit(1)
		return
	var runner = script.new()
	runner.args = args
	root.add_child(runner)
