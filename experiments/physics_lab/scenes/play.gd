extends SceneTree
## Plays one of the lab's scripted scenes and saves its frames (a -s script can't name game classes,
## so it loads the scene's node, as lab.gd does the runner).
##   xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 \
##       -s res://experiments/physics_lab/scenes/play.gd -- --scene=chair_kick_shot --out=DIR
## then ffmpeg -framerate 30 -i DIR/%04d.png ... (the frames are every other tick: game speed).


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var script: GDScript = load("res://experiments/physics_lab/scenes/%s.gd" % args.get("scene", "chair_kick_shot"))
	if script == null or not script.can_instantiate():
		push_error("play: no scene %s" % args.get("scene", ""))
		quit(2)
		return
	var node: Node = script.new()
	node.set(&"out_dir", args.get("out", "build/scene"))
	root.add_child(node)
