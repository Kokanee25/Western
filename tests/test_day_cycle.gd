extends TestCase
## The day lasts 45 real minutes, the sun rises in the east and sets in the west, hours and days
## are announced on the event bus, the debug key speeds time up, and lamps light at dusk.

var clock: DayCycle
var hours: Array[int] = []
var days: Array[int] = []


func before_each() -> void:
	clock = DayCycle.new()
	clock.config = load("res://config/day_cycle.tres")
	add_child(clock)
	clock.set_physics_process(false)
	hours.clear()
	days.clear()
	Events.hour_changed.connect(_on_hour)
	Events.day_started.connect(_on_day)


func after_each() -> void:
	Events.hour_changed.disconnect(_on_hour)
	Events.day_started.disconnect(_on_day)
	clock.queue_free()
	await process_frames(1)


func _on_hour(h: int) -> void:
	hours.append(h)


func _on_day(d: int) -> void:
	days.append(d)


func test_day_is_45_minutes() -> void:
	check_near(clock.config.day_length_seconds, 45.0 * 60.0, 0.001, "config says 45 minutes")
	clock.set_time(12.0)
	hours.clear()
	for i in 2700:
		clock.advance(1.0)
	check_near(clock.time_of_day, 12.0, 0.0001, "back to noon after 2700 real seconds")
	check_eq(clock.day, 2, "one day passed")
	check_eq(hours.size(), 24, "24 hours announced")
	check_eq(days, [2] as Array[int], "day 2 announced once")


func test_an_hour_is_112_and_a_half_seconds() -> void:
	clock.set_time(9.0)
	check_eq(hours, [9] as Array[int], "jumping the clock announces the hour")
	hours.clear()
	clock.advance(112.5)
	check_near(clock.time_of_day, 10.0, 0.0001, "one in-game hour")
	check_eq(hours, [10] as Array[int], "hour 10 announced")
	check_eq(clock.get_clock_text(), "10:00", "clock text")


func test_runs_on_the_physics_tick() -> void:
	clock.set_time(8.0)
	clock.set_physics_process(true)
	await physics_frames(60)
	clock.set_physics_process(false)
	var expected := 8.0 + 60.0 / Engine.physics_ticks_per_second * 24.0 / 2700.0
	check_near(clock.time_of_day, expected, 24.0 / 2700.0 / 30.0, "one real second of clock time")


func test_debug_time_scale() -> void:
	check_eq(clock.time_scale, 1.0, "starts at normal speed")
	clock.cycle_time_scale()
	check(clock.time_scale > 1.0, "debug key speeds time up")
	var start := clock.time_of_day
	clock.advance(clock.config.day_length_seconds / clock.time_scale)
	check_near(clock.time_of_day, start, 0.0001, "a whole day passes %sx faster" % clock.time_scale)
	for i in clock.config.debug_time_scales.size() - 1:
		clock.cycle_time_scale()
	check_eq(clock.time_scale, 1.0, "cycles back to normal")


func test_debug_key_cycles_speed() -> void:
	clock.set_process(true)
	Input.action_press(&"debug_time_scale")
	await process_frames(2)
	Input.action_release(&"debug_time_scale")
	check(clock.time_scale > 1.0, "T speeds time up")


func test_sun_path() -> void:
	check(clock.get_sun_direction(12.0).y > 0.7, "sun high at noon")
	check(clock.get_sun_direction(0.0).y < -0.5, "sun below the horizon at midnight")
	check(clock.get_sun_direction(6.5).x > 0.5 and clock.is_daytime(6.5), "morning sun in the east (+X)")
	check(clock.get_sun_direction(18.0).x < -0.5 and clock.is_daytime(18.0), "evening sun in the west (-X)")
	check(not clock.is_daytime(4.0) and not clock.is_daytime(21.0), "dark before dawn and after dusk")
	check(clock.get_sun_direction(12.0).z < -0.3, "noon sun leans south (-Z), onto the storefronts")
	check(clock.get_moon_direction(0.0).y > 0.5, "moon up at midnight")


func test_lights_follow_the_sun() -> void:
	var sun := DirectionalLight3D.new()
	var moon := DirectionalLight3D.new()
	add_child(sun)
	add_child(moon)
	clock.sun = sun
	clock.moon = moon
	clock.set_time(12.0)
	check_near(sun.light_energy, clock.config.sun_max_energy, 0.01, "full sun at noon")
	check(sun.visible and not moon.visible, "sun on, moon off at noon")
	check(-sun.global_transform.basis.z.y < -0.7, "sunlight shines downward")
	clock.set_time(0.0)
	check(not sun.visible and moon.visible, "moon on, sun off at midnight")
	sun.queue_free()
	moon.queue_free()


func test_lamps_light_at_dusk() -> void:
	clock.set_time(17.9)
	var lamp := OilLamp.new()
	add_child(lamp)
	check(not lamp.lit, "lamp out in the afternoon")
	clock.advance(0.2 / 24.0 * 2700.0)
	check(lamp.lit, "lamp lit after 18:00")
	check(lamp.should_be_lit(23) and lamp.should_be_lit(3), "lit through the night")
	check(not lamp.should_be_lit(7) and not lamp.should_be_lit(12), "out in the day")
	clock.set_time(12.0)
	check(not lamp.lit, "jumping to noon puts it out")
	clock.set_time(22.5)
	check(lamp.lit, "jumping to night lights it")
	lamp.queue_free()
