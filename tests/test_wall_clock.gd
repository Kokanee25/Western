extends TestCase
## The wall clock (#789, #1030; src/props/wall_clock.gd, assets/props/kit/wall_clock.json): hung on its
## nails, its hands show the town's time (DayCycle's), its pendulum swings by its length, and a ball
## through its works stops it at that minute (a clue), as does its fall off the wall.

var world: Node3D
var day: DayCycle


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	day = DayCycle.new()
	world.add_child(day)
	day.held = true
	var wall := Structure.new()
	wall.structure_id = &"clock_wall"
	world.add_child(wall)
	for x in [-0.6, 0.0, 0.6]:
		wall.add_member("stud%d" % int(x * 10 + 10), &"stud", &"framing", Vector3(0.05, 3.0, 0.1), Vector3(x, 1.5, -0.07))
	for i in 20:
		wall.add_member("board%d" % i, &"board", &"framing", Vector3(1.6, 0.15, 0.02), Vector3(0, 0.075 + 0.15 * i, -0.01))
	wall.infer_supports()


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _hang() -> KitProp:
	var p := PropKit.spawn(&"wall_clock") as KitProp
	p.position = Vector3(0, 1.2, 0)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	return p


func _clock(p: KitProp) -> WallClock:
	return p.get_node(^"WallClock") as WallClock


func test_its_hands_read_the_towns_time() -> void:
	var p := await _hang()
	check(p.hung() and not p.loose, "it hangs on its nails")
	var c := _clock(p)
	check(c != null, "the kit file's clock makes a WallClock")
	for case: Array in [[15.25, 97.5, 90.0], [9.0, 270.0, 0.0], [0.5, 15.0, 180.0], [21.75, 292.5, 270.0], [12.0, 0.0, 0.0]]:
		day.set_time(float(case[0]))
		c.update_now()
		var a := c.shown_angles()
		check_near(fposmod(a.x, 360.0), float(case[1]), 0.05, "%.2f h: the hour hand at %.1f deg (%.2f)" % [case[0], case[1], a.x])
		check_near(fposmod(a.y, 360.0), float(case[2]), 0.05, "%.2f h: the minute hand at %.1f deg (%.2f)" % [case[0], case[2], a.y])
	# Clockwise as you face it: a quarter past is the minute hand turned toward the clock's right (+x).
	day.set_time(3.25)
	c.update_now()
	var tip := (c.get_node(^"Minute") as Node3D).transform.basis * Vector3.UP
	check(tip.x > 0.99, "a quarter past points right as you face it (%s)" % tip)


func test_its_pendulum_swings_a_beat_each_half_period() -> void:
	var p := await _hang()
	var c := _clock(p)
	var period := float(c.spec.period)
	# 2 pi sqrt(L/g) for its length: a regulator's short drop, ~85 beats a minute.
	check(period > 1.2 and period < 1.7, "its period from its length (%.3f s)" % period)
	c.swing_time = period * 0.25
	check_near(c.pendulum_angle(), float(c.spec.swing), 0.01, "a quarter period: out at its arc")
	c.swing_time = period * 0.5
	check_near(c.pendulum_angle(), 0.0, 0.01, "half a period: through the middle")


func test_a_ball_through_its_works_stops_it_at_that_minute() -> void:
	var p := await _hang()
	var c := _clock(p)
	day.set_time(14.6)
	# A ball through the glass into the case beside the dial (not its works): it goes on.
	Events.bullet_hit.emit({"position": p.to_global(Vector3(0.0, 0.3, 0.12)), "collider": null})
	check(not c.is_stopped, "a ball through the lower glass doesn't stop it")
	var works: Dictionary = c.spec.works
	Events.bullet_hit.emit({"position": p.to_global(PropKit.vec(works.at)), "collider": null})
	check(c.is_stopped, "a ball through its works stops it")
	check_near(c.stopped_hour, 14.6, 0.001, "at the time it was shot")
	day.set_time(18.0)
	c.update_now()
	var a := c.shown_angles()
	check_near(fposmod(a.y, 360.0), 216.0, 0.1, "the minute hand stays at 14:36 (%.1f)" % a.y)
	check_near(c.pendulum_angle(), 0.0, 0.001, "its pendulum hangs still")


func test_off_the_wall_it_stops() -> void:
	var p := await _hang()
	var c := _clock(p)
	day.set_time(8.0)
	p.go_loose()
	await physics_frames(3)
	check(c.is_stopped, "fallen, it stops")
	check_near(c.stopped_hour, 8.0, 0.01, "at the time it fell")


func test_the_rifle_hangs_on_its_pegs() -> void:
	var p := PropKit.spawn(&"rifle_pegs") as KitProp
	p.position = Vector3(0, 1.6, 0)
	world.add_child(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	check(p.hung() and not p.loose, "the rifle hangs on its pegs")
	check(p.member_count() == 3, "two pegs and the gun (%d)" % p.member_count())
	check(p.settle().is_empty(), "nothing falls")
