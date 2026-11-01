extends SceneTree
## The deer fidelity lab's D check (issue #524; README.md beside this file): a version of the deer
## (deer_variants.gd) wired into the kit's own deer_head (its parts and material in PropKit's and
## PropModels' caches; the kit file, members, nails, fire and breaking all the game's), then put
## through the game's own deer tests and the lab's: it hangs on its two nails, falls when its board
## goes and lands, splits, burns, takes shots. The same run for the game's deer is the yardstick.
##
##   godot --headless --fixed-fps 60 -s res://experiments/prop_lab/deer_fidelity/d_checks.gd -- \
##       --versions=game,C7 --out=DIR [--dir=VARIANTS]
##
## DIR/d_checks.json: each version's test results and its numbers.

## The game's tests that are the deer's (tests/<file>.gd: methods).
## (The work is in d_checks_body.gd, loaded at run time: an -s script compiles before the autoloads
## the kit and the tests name exist.)

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var opts := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			opts[kv[0]] = kv[1] if kv.size() > 1 else "true"
	var body: Node = load("res://experiments/prop_lab/deer_fidelity/d_checks_body.gd").new()
	root.add_child(body)
	await body.run(opts)
	quit()
