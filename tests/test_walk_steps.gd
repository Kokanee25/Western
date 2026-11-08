extends TestCase
## Walking is even (#643, Sean: "takes like 3–4 steps then it's like it jerks forward for a step
## and goes further than a normal step"): the game's street, a scripted walk of 30 steps down the
## middle of Main Street, every step's length (the eyes' travel between footfalls, PlayerMotion's)
## logged to user://walk_steps.csv (a .csv under res:// imports as a translation) and summed up
## in the test's output; none more than 15% longer than the median, and no tick's travel
## more than 15% over the walk's own.
##
## What this catches is the walk itself (a step up out of nothing, a push, a speed that surges).
## A frame-time hitch is the renderer's and isn't drawn headless: tools/walk_frames.gd walks the
## same street drawn and times every frame (the hitch #643 found was SDFGI's cascades scrolling).

const STEPS := 30
const LONGEST := 1.15  # times the median step

var main: Node


func after_each() -> void:
	Input.action_release(&"move_forward")
	if is_instance_valid(main):
		main.queue_free()
	await physics_frames(3)


func test_thirty_even_steps_down_the_street() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await physics_frames(30)
	var player: Player = get_tree().get_first_node_in_group(&"player")
	# Down the street's middle to the west, from the store end (flat, nothing in the way for 70 m).
	var x0 := 30.0
	player.global_position = Vector3(x0, 0.5, TownLayout.street_z(x0))
	player.rotation = Vector3(0.0, PI / 2.0, 0.0)
	await physics_frames(30)
	var cam: Camera3D = player.get_node(^"Head/Camera3D")
	var log := FileAccess.open("user://walk_steps.csv", FileAccess.WRITE)
	if log:
		log.store_line("step,tick,length_m,x,z")
	var steps: Array[float] = []
	var ticks: Array[float] = []
	var last := _flat(cam.global_position)
	var at_step := last
	var counted := -2  # the first two footfalls are the walk getting up to speed
	Input.action_press(&"move_forward")
	for tick in 60 * 20:
		await get_tree().physics_frame
		var p := _flat(cam.global_position)
		if counted >= 0:
			ticks.append(p.distance_to(last))
		last = p
		if player.motion.footfall:
			if counted >= 0:
				var length := p.distance_to(at_step)
				steps.append(length)
				if log:
					log.store_line("%d,%d,%.4f,%.3f,%.3f" % [counted, tick, length, p.x, p.y])
			counted += 1
			at_step = p
			if steps.size() >= STEPS:
				break
	Input.action_release(&"move_forward")
	if log:
		log.close()
	check_eq(steps.size(), STEPS, "walked %d steps" % STEPS)
	if steps.size() < 3:
		return
	var med := _median(steps)
	var longest := steps.max() as float
	check(longest <= med * LONGEST, "every step within %d%% of the median %.3f m (longest %.3f m: %s)"
			% [roundi((LONGEST - 1.0) * 100.0), med, longest, steps])
	check(med > 0.7 and med < 1.3, "a walking step is about a metre (median %.3f m)" % med)
	print("  walk: %d steps, median %.3f m, longest %.3f m, shortest %.3f m (%s)" % [steps.size(), med, longest,
			steps.min(), ProjectSettings.globalize_path("user://walk_steps.csv")])
	var tick_med := _median(ticks)
	var tick_max := ticks.max() as float
	check(tick_max <= tick_med * LONGEST, "no tick's travel jumps (median %.4f m, most %.4f m)" % [tick_med, tick_max])


static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)


static func _median(a: Array[float]) -> float:
	var s := a.duplicate()
	s.sort()
	return s[s.size() / 2]
