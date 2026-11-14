extends SceneTree
## The falls lab (issue #759): men dropped from heights, feet first, flat on the back and head
## first, `--men` at a time per cell, and what the landing did to each (README.md beside this).
##
##   godot --headless --fixed-fps 60 -s res://experiments/falls_lab/falls.gd -- --out=build/falls_lab/run
##       [--heights=1,2,3,4.5,6,9,12,15,22] [--poses=feet,back,head] [--men=20] [--seed=1] [--seconds=4]
##       [--onto=roof|porch|floor [--body-stop=M]]   (each man onto a bay of the game's members)
##   ... -- --saloon --out=DIR [--cases=gallery,balcony,roof,roof_edge] [--seeds=6]   (the spec saloon)
## Untyped on purpose: -s scripts compile before autoloads exist.

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_run.call_deferred()


func _run() -> void:
	# --saloon: the building lab's saloon (saloon_runner.gd: --cases=gallery,balcony,roof,roof_edge --seeds=N)
	var script: GDScript = load("res://experiments/falls_lab/saloon_runner.gd" if args.has("saloon") else "res://experiments/falls_lab/falls_runner.gd")
	if script == null or not script.can_instantiate():
		push_error("falls lab: falls_runner.gd doesn't load")
		quit(1)
		return
	var runner = script.new()
	runner.args = args
	root.add_child(runner)
