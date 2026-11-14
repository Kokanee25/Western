extends SceneTree
## Can the player climb the saloons' stairs? Puts him at a stair's foot facing up it, holds
## forward (and run) for four seconds, and prints how high he got: the street saloon's for each
## preset and the old movement's numbers, then every stair in the new saloon (middle).
##   godot --headless --fixed-fps 60 -s res://experiments/movement_feel/stair_check.gd


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: Node = load("res://scenes/test_street.tscn").instantiate()
	root.add_child(scene)
	for i in 30:
		await physics_frame
	var player = scene.get_tree().get_first_node_in_group(&"player")
	var ramp := scene.find_child("StairRamp", true, false) as Node3D
	var up := ramp.global_basis.x.normalized()
	var half := ((ramp.get_child(0) as CollisionShape3D).shape as BoxShape3D).size.x * 0.5
	var foot := ramp.global_position - up * half
	var flat := Vector3(up.x, 0.0, up.z).normalized()
	print("stair foot %s, up %s, top %.2f m" % [foot, up, (ramp.global_position + up * half).y])
	var old = load("res://src/player/player_tuning.gd").new()
	old.ground_accel = 30.0
	old.ground_decel = 22.0
	old.run_build = 30.0
	old.reverse_decel = 30.0
	old.turn_grip = 30.0
	for preset in ["old", "light", "middle", "heavy"]:
		for run in [false, true]:
			if preset == "old":
				player.tuning.take_movement(old)
			else:
				player.set_movement(StringName(preset))
			player.global_position = Vector3(foot.x, foot.y, foot.z) - flat * 0.8
			player.velocity = Vector3.ZERO
			player.rotation.y = atan2(-flat.x, -flat.z)
			for i in 20:
				await physics_frame
			var y0: float = player.global_position.y
			Input.action_press(&"move_forward")
			if run:
				Input.action_press(&"run")
			var top: float = y0
			for i in 240:
				await physics_frame
				top = maxf(top, player.global_position.y)
			Input.action_release(&"move_forward")
			Input.action_release(&"run")
			print("%-6s %-4s climbed %.2f m (at %s)" % [preset, "run" if run else "walk", top - y0, player.global_position])
			print("        in the way: %s" % _blocker(player, flat))
	# The new saloon out in the desert (F5's eighth stop), and every stair in it.
	load("res://experiments/building_lab/play.gd").build(scene)
	for i in 30:
		await physics_frame
	player.set_movement(&"middle")
	for r in scene.find_children("Ramp_*", "StaticBody3D", true, false):
		var rb := r as Node3D
		var u := rb.global_basis.x.normalized()
		if u.y < 0.0:
			u = -u
		var h := ((rb.get_child(0) as CollisionShape3D).shape as BoxShape3D).size.x * 0.5
		var f := rb.global_position - u * h
		var fl := Vector3(u.x, 0.0, u.z).normalized()
		player.global_position = f - fl * 0.8 + Vector3.UP * 0.05
		player.velocity = Vector3.ZERO
		player.rotation.y = atan2(-fl.x, -fl.z)
		for i in 30:
			await physics_frame
		var y0: float = player.global_position.y
		Input.action_press(&"move_forward")
		var top: float = y0
		for i in 360:
			await physics_frame
			top = maxf(top, player.global_position.y)
		Input.action_release(&"move_forward")
		print("%s: climbed %.2f m of %.2f; in the way: %s" % [rb.name, top - y0, (rb.global_position + u * h).y - f.y, _blocker(player, fl)])
	quit(0)


## What stops him going on: what a short move ahead (along the slope and level) runs into.
func _blocker(player: CharacterBody3D, ahead: Vector3) -> String:
	var out: PackedStringArray = []
	for dir in [ahead * 0.1, (ahead + Vector3.UP * 0.9).normalized() * 0.1, Vector3.UP * 0.1]:
		var c := KinematicCollision3D.new()
		if player.test_move(player.global_transform, dir, c):
			out.append("%s (%s, normal %s)" % [c.get_collider().name, c.get_collider().get_parent().name if c.get_collider().get_parent() else "", c.get_normal().snapped(Vector3.ONE * 0.01)])
		else:
			out.append("-")
	return " | ".join(out)
