extends SceneTree
## The crowd bench (#1286; Sean on #1097: "a bench of 40 people in the saloon at night and the floor dropping,
## so the numbers are known first"). The Silver Spike from its spec in the building lab, 40 men upstairs (the
## middle reel set on its points, the rest dancing round them, on the benches and in the band) and 15 below
## (at the bar, behind it, at the tables, standing), their weight on the boards under them (a man's 75 kg at
## 1.8x for a reel stamping in step), then Payday Night's cut (SpecBuilding.saw_girder) and 8 s of the fall.
## Per seed: how long the bay takes to come down and how much of it; who went down with it, who was struck
## below, the bones broken and who is dead ten minutes later (the physiology decides, nothing placed); the
## frame's cost with 55 men in it before the cut and during the fall, the bodies in the physics server and
## memory. Writes DIR/crowd.json and a line a seed.
##
##   godot --headless --fixed-fps 60 -s res://experiments/building_lab/railroad_saloon/crowd_bench.gd -- \
##       --out=build/railroad_saloon_crowd [--seeds=10] [--seconds=8]
##
## A standing HumanBody doesn't fall when the floor goes from under him (nothing in the game drops him yet:
## Payday Night needs that rule, gameplay's): here a man whose feet find no sound floor goes limp, with the
## floor's own speed. The jam at the door isn't measured: the men here don't walk (townsfolk's AI, gameplay's).
## Untyped where it names game classes: -s scripts compile before autoloads.

var args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_run.call_deferred()


func _run() -> void:
	var script: GDScript = load("res://experiments/building_lab/railroad_saloon/crowd_runner.gd")
	if script == null or not script.can_instantiate():
		push_error("crowd bench: crowd_runner.gd doesn't load")
		quit(1)
		return
	var runner = script.new()
	runner.args = args
	root.add_child(runner)
