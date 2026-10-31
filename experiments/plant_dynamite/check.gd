extends SceneTree
## Issue #506's check: one stick planted by hand (E held at the wall, the player's own code:
## DynamiteViewmodel.plant_spot/plant, lit on letting go) at 8 spots 0.5 m apart along the store's
## side wall, as #484 did with a stick set by script. For each: where it lay, the hole's clear
## height (a 0.4 x 0.5 m box from just over the floor, 0.6 .. 1.9 m tall, slid along 0.5 m either
## side), and the blast frame (its wall clock and Prof's top systems, F3's numbers).
##
##   godot --headless --fixed-fps 60 -s res://experiments/plant_dynamite/check.gd -- [--side=inside|outside] [--out=FILE.json]
##
## Inside: on the floor between the studs (the hostage's room, #484's test). Outside: on the
## ground against the sill (the farmhouse breach from the yard).

func _initialize() -> void:
	_go.call_deferred()


func _go() -> void:
	var r = load("res://experiments/plant_dynamite/check_runner.gd").new()
	r.done.connect(func() -> void: quit(0))
	root.add_child(r)
