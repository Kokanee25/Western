extends TestCase
## The slowdown after dynamite and fire (#1117): the catch-up limit follows what a tick costs
## (CatchUp: a frame never runs 40 ticks it can't afford, the chaos playtest's 2 fps), and a tap of
## E down and up inside one slow frame isn't lost (PlayerCarry).


class TapCarry:
	extends PlayerCarry
	var used := 0

	func use() -> StringName:
		used += 1
		return &""


var _most := 0


func before_each() -> void:
	_most = Engine.max_physics_steps_per_frame
	CatchUp.tick_ms = 0.0


func after_each() -> void:
	Engine.max_physics_steps_per_frame = _most
	CatchUp.tick_ms = 0.0
	Input.action_release(&"shove")


func test_cheap_ticks_may_catch_up_and_dear_ones_may_not() -> void:
	check_eq(CatchUp.limit_for(0.0), CatchUp.most, "no tick measured yet: the most")
	check_eq(CatchUp.limit_for(5.0), CatchUp.most, "a 5 ms tick: the most (40)")
	check_eq(CatchUp.limit_for(12.5), 32, "a 12.5 ms tick: as many as fit in 400 ms")
	check_eq(CatchUp.limit_for(16.0), CatchUp.least, "a tick near its own 1/60 s: the floor")
	check_eq(CatchUp.limit_for(35.0), CatchUp.least, "the blast's 35 ms ticks: the floor")


func test_a_frame_of_dear_ticks_drops_the_limit_and_cheap_ones_raise_it() -> void:
	# The chaos round's frame after the blast: 40 ticks in 1400 ms.
	check_eq(CatchUp.after_frame(1400.0, 40), CatchUp.least, "after 40 ticks of 35 ms")
	check_eq(Engine.max_physics_steps_per_frame, CatchUp.least, "set on the engine")
	for i in 20:
		CatchUp.after_frame(8.0, 1)
	check_eq(Engine.max_physics_steps_per_frame, CatchUp.most, "back to the most once ticks are cheap (%.1f ms)" % CatchUp.tick_ms)


func test_a_tap_down_and_up_between_two_ticks_is_a_tap() -> void:
	var p := Player.new()
	p.tuning = PlayerTuning.new()
	var c := TapCarry.new()
	c.player = p
	c._look_t = 99.0  # (not looking round for a man: there's no world)
	add_child(c)
	await physics_frames(2)
	# Down and up in one go, as both come in one slow frame.
	var down := InputEventAction.new()
	down.action = &"shove"
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = &"shove"
	up.pressed = false
	Input.parse_input_event(up)
	await physics_frames(3)
	check_eq(c.used, 1, "the tap taken (never seen held)")
	# A plain tap over a few ticks still is one; a long hold isn't.
	Input.action_press(&"shove")
	await physics_frames(3)
	Input.action_release(&"shove")
	await physics_frames(2)
	check_eq(c.used, 2, "a tap over three ticks")
	Input.action_press(&"shove")
	await physics_frames(int(p.tuning.carry_tap_s * 60.0) + 10)
	Input.action_release(&"shove")
	await physics_frames(2)
	check_eq(c.used, 2, "a hold isn't a tap")
	c.queue_free()
	p.free()
