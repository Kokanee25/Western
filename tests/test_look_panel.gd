extends TestCase
## The live look panel (LookPanel) and the presets it makes (LookPreset): every setting on the art
## session's list is reachable in the street, a slider moves the game's value, and a preset saved,
## changed and loaded comes back the same.

var holder: Node
var street: Node3D
var panel: LookPanel


func before_each() -> void:
	Settings.autosave = false
	holder = Node.new()
	add_child(holder)
	street = load("res://scenes/test_street.tscn").instantiate()
	holder.add_child(street)
	panel = LookPanel.new()
	holder.add_child(panel)
	await process_frames(3)


func after_each() -> void:
	LookPreset.reset(get_tree())
	LookPreset.defaults.clear()
	holder.queue_free()
	await process_frames(2)


func test_every_setting_on_the_list_is_in_the_street() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LookPanel.LAYOUT))
	var missing: Array[String] = []
	var count := 0
	for g: Dictionary in layout.groups:
		for item: Dictionary in g.items:
			count += 1
			if LookPreset.get_value(get_tree(), item.key) == null:
				missing.append(item.key)
	check(count > 80, "the art session's list is laid out (%d settings)" % count)
	check(missing.is_empty(), "every one is reachable: missing %s" % [missing])


func test_a_slider_sets_the_game_and_reset_puts_it_back() -> void:
	var env := LookPreset.environment(get_tree())
	var was := env.adjustment_contrast
	panel.open()
	var slider := panel._rows["env.adjustment_contrast"].control as HSlider
	check(is_equal_approx(slider.value, was), "the slider opens at the game's value")
	slider.value = 1.4
	check(is_equal_approx(env.adjustment_contrast, 1.4), "dragging it sets the contrast")
	(panel._rows["lamps.all.energy"].control as HSlider).value = 2.0
	var lamp := street.find_children("*", "OilLamp", true, false)[0] as OilLamp
	check(is_equal_approx(lamp.energy, float(lamp.get_meta(&"base_energy")) * 2.0), "the lamps' light is doubled")
	panel._on_reset()
	check(is_equal_approx(env.adjustment_contrast, was), "Reset puts the contrast back")
	check(is_equal_approx(lamp.energy, float(lamp.get_meta(&"base_energy"))), "and the lamps")
	panel.close()


func test_a_preset_saved_and_loaded_comes_back() -> void:
	var day := street.find_child("DayCycle", true, false) as DayCycle
	LookPreset.set_value(get_tree(), "day.exposure_night", 0.55)
	LookPreset.set_value(get_tree(), "sky.cloud_cover", 0.7)
	LookPreset.set_value(get_tree(), "day.moon_color", Color(0.9, 0.8, 0.6))
	var text := LookPreset.to_json(panel.preset())
	var p: Dictionary = JSON.parse_string(text)
	check(p.values.has("sky.cloud_cover") and p.has("hour"), "the preset is JSON with every value and the hour")
	LookPreset.reset(get_tree())
	check(not is_equal_approx(day.config.exposure_night, 0.55), "reset")
	var missed := LookPreset.apply(get_tree(), p)
	check(missed.is_empty(), "everything in it applies (%s)" % [missed])
	check(is_equal_approx(day.config.exposure_night, 0.55), "the night exposure comes back")
	check(is_equal_approx(float(LookPreset.get_value(get_tree(), "sky.cloud_cover")), 0.7), "and the clouds")
	check(day.config.moon_color.is_equal_approx(Color(0.9, 0.8, 0.6)), "and the moon's colour, from [r, g, b, a]")
	check_eq(Array(LookPreset.apply(get_tree(), {"values": {"env.no_such": 1}})), ["env.no_such"], "a name that isn't there is reported")
