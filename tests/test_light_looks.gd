extends TestCase
## The light pass's looks (issue #318): the grade's lookup leaves colours alone at strength 0, pulls
## oranges toward grey more than blues, cools the shadows and warms the light; each look file sets
## only addresses LookPreset knows; 8 cycles today / A / B / C and today puts back what it read.


func test_the_grade() -> void:
	var off := LightGrade.DEFAULTS.duplicate()
	var c := Color(0.8, 0.45, 0.2)
	check(LightGrade.grade(c, off).is_equal_approx(c), "strength 0 leaves a colour alone")
	var d := LightGrade.DEFAULTS.duplicate()
	d.strength = 1.0
	d.orange_pull = 0.5
	var orange := LightGrade.grade(Color(0.8, 0.45, 0.2), d)
	var blue := LightGrade.grade(Color(0.2, 0.4, 0.8), d)
	check(orange.s < 0.75 * Color(0.8, 0.45, 0.2).s, "an orange pulled toward grey (%.2f)" % orange.s)
	check(blue.s > 0.95 * Color(0.2, 0.4, 0.8).s, "a blue left (%.2f)" % blue.s)
	d.orange_pull = 0.0
	d.shadow_amount = 1.0
	d.highlight_amount = 1.0
	var shade := LightGrade.grade(Color(0.12, 0.12, 0.12), d)
	var light := LightGrade.grade(Color(0.9, 0.9, 0.9), d)
	check(shade.b > shade.r, "the shadows cool")
	check(light.r > light.b, "the light warm")
	var lut := LightGrade.build(d)
	check_eq(lut.get_width(), LightGrade.SIZE, "a %d-cube lookup" % LightGrade.SIZE)


func test_each_look_sets_known_addresses() -> void:
	var groups := ["day", "sky", "ground", "env", "grade", "finish", "lamps", "building"]
	for f: String in LightLooks.FILES:
		var preset := LookPreset.load_file(f)
		check(not preset.is_empty(), "%s reads" % f)
		for a: String in preset.get("values", {}):
			check(a.get_slice(".", 0) in groups, "%s: %s is a look address" % [f, a])
			var key := a.get_slice(".", 1)
			if a.begins_with("grade."):
				check(LightGrade.DEFAULTS.has(key), "%s: grade.%s is a dial" % [f, key])
			elif a.begins_with("finish."):
				check(LightFinish.DEFAULTS.has(key), "%s: finish.%s is a dial" % [f, key])
			elif a.begins_with("day."):
				check(key in DayCycleConfig.new(), "%s: day.%s is in DayCycleConfig" % [f, key])


func test_the_key_cycles_and_today_puts_back() -> void:
	check(InputMap.has_action(&"light_look"), "8 is bound")
	LookPreset.defaults.clear()
	var street: Node3D = load("res://scenes/test_street.tscn").instantiate()
	street.get_node(^"TownLife").set(&"gang_arrives", 99999.0)
	add_child(street)
	await physics_frames(3)
	var before: float = LookPreset.get_value(get_tree(), "day.exposure_day")
	LightLooks.pick(get_tree(), 3)
	var b := LookPreset.load_file(LightLooks.FILES[1])
	check_near(LookPreset.get_value(get_tree(), "day.exposure_day"), b.values["day.exposure_day"], 0.001, "B's noon exposure")
	check_near(LightGrade.dials.strength, b.values["grade.strength"], 0.001, "B's grade")
	check(LookPreset.environment(get_tree()).adjustment_enabled, "the grade on the environment")
	LightLooks.pick(get_tree(), 1)
	check_near(LookPreset.get_value(get_tree(), "day.exposure_day"), before, 0.001, "today's exposure back")
	check_eq(LightGrade.dials.strength, 0.0, "no grade")
	check(not LookPreset.environment(get_tree()).adjustment_enabled, "the environment's adjustment off again")
	# The game's light (Sean, #321): B by day, C at night, blended as the sun goes down.
	var c := LookPreset.load_file(LightLooks.FILES[2])
	var clock := street.get_node(^"DayCycle") as DayCycle
	clock.set_time(12.0)
	LightLooks.pick(get_tree(), 0)
	check_eq(LightLooks.night_share(get_tree()), 0.0, "noon is all day")
	check_near(LookPreset.get_value(get_tree(), "lamps.saloon_hanging.energy"), b.values["lamps.saloon_hanging.energy"], 0.001, "noon: B's dials")
	clock.set_time(21.5)
	check_eq(LightLooks.night_share(get_tree()), 1.0, "21:30 is all night")
	LightLooks.blend(get_tree(), LightLooks.night_share(get_tree()))
	check_near(LookPreset.get_value(get_tree(), "lamps.saloon_hanging.energy"), c.values["lamps.saloon_hanging.energy"], 0.001, "night: C's")
	check_near(LookPreset.get_value(get_tree(), "grade.contrast"), c.values["grade.contrast"], 0.001, "and C's grade")
	var mid: float = LightLooks.mix(b.values["day.exposure_day"], c.values["day.exposure_day"], 0.5)
	LightLooks.blend(get_tree(), 0.5)
	check_near(LookPreset.get_value(get_tree(), "day.exposure_day"), mid, 0.001, "half way down, half each")
	check_eq(LookPreset.get_value(get_tree(), "sky.cloud_scale"), b.values["sky.cloud_scale"], "the sky's dials stay day's")
	LightLooks.pick(get_tree(), 1)
	LightLooks.current = 0
	street.free()
	LookPreset.defaults.clear()
	await process_frames(1)
