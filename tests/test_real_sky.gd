extends TestCase
## The real sky (#918): SkyModel's atmosphere gives a sun white at noon, gold low and gone under the
## horizon, a blue sky overhead and a dark one at night; the moon's phase by date; RealSky puts our
## sky in under the real look and the painted one back off, lights the world from it, and draws
## its clouds; the valley's far land.

var model: SkyModel


func before_each() -> void:
	model = SkyModel.new()


func test_the_table_matches_the_march() -> void:
	for mu: float in [1.0, 0.5, 0.1, 0.02]:
		var r := model.radius_at()
		var exact := model.transmittance_exact(r, mu)
		var read := model.transmittance(r, mu)
		check((exact - read).length() < 0.03 + exact.length() * 0.05,
				"mu %.2f: the table %s near the march %s" % [mu, read, exact])


func test_the_sun_is_white_high_gold_low_and_out_below() -> void:
	var noon := model.light_at(Vector3(0.0, 0.85, -0.53).normalized())
	var low := model.light_at(Vector3(-0.99, 0.06, 0.0).normalized())
	var under := model.light_at(Vector3(-0.99, -0.05, 0.0).normalized())
	check(noon.z / noon.x > 0.75, "noon's sun near white (blue/red %.2f)" % (noon.z / noon.x))
	check(low.z / low.x < 0.45 and low.y / low.x < 0.8, "a low sun gold to orange (%s)" % low)
	check(SkyModel.luminance(low) < SkyModel.luminance(noon) * 0.6, "and dimmer")
	check(under.length() < 1e-4, "none once the sun is under the horizon (%s)" % under)


func test_the_sky_is_blue_overhead_by_day_and_dark_at_night() -> void:
	var sun := Vector3(0.0, 0.8, -0.6).normalized()
	var zen := model.radiance(Vector3.UP, sun)
	check(zen.z > zen.x * 1.6 and zen.z > zen.y, "the zenith blue at noon (%s)" % zen)
	var hor := model.radiance(Vector3(0.0, 0.03, 1.0).normalized(), sun)
	check(SkyModel.luminance(hor) > SkyModel.luminance(zen), "the horizon paler and brighter than the zenith")
	var night := model.radiance(Vector3.UP, Vector3(0.0, -0.5, 0.86).normalized())
	check(SkyModel.luminance(night) < SkyModel.luminance(zen) * 0.002, "the night sky near black without the moon")
	# The blue hour: with the sun 4 degrees down the zenith is still blue (ozone), not grey or red.
	var dusk := model.radiance(Vector3.UP, Vector3(-0.997, -0.07, 0.0).normalized())
	check(dusk.z > dusk.x, "the zenith blue at twilight (%s)" % dusk)


func test_the_moon_by_date() -> void:
	check(absf(SkyModel.moon_phase(1, 12.0) - 0.5) < 0.001, "day 1 at noon is the full moon (every shot so far)")
	check(absf(SkyModel.moon_hour_lag(SkyModel.moon_phase(1, 12.0))) < 0.05, "and it rides where it always did")
	var quarter := SkyModel.moon_phase(1 + 7, 12.0)
	check(quarter > 0.7 and quarter < 0.8, "a week on, the last quarter (%.2f)" % quarter)
	check(SkyModel.moon_brightness(0.5) > 0.99, "full is full")
	var q := SkyModel.moon_brightness(0.75)
	check(q > 0.06 and q < 0.15, "a quarter moon gives about a tenth of full's light (Allen: %.3f)" % q)
	check(SkyModel.moon_brightness(0.0) < 0.001, "new gives none")
	var md := Vector3(0.0, 0.5, 0.86).normalized()
	var sd := Vector3(0.3, -0.6, -0.7).normalized()
	check(SkyModel.moon_lit_from(md, sd, 0.5).dot(-md) > 0.999, "full: lit from behind the eye")
	var lit := SkyModel.moon_lit_from(md, sd, 0.75)
	check(absf(lit.dot(md)) < 0.05, "a quarter: lit from the side")


func test_the_stars_turn_round_the_pole() -> void:
	var pole := SkyModel.pole(Vector3(0.0, 0.8, -0.6), 35.0)
	check(pole.z > 0.0 and absf(pole.y - sin(deg_to_rad(35.0))) < 1e-4, "the pole away from the noon sun, the latitude up")
	var b := SkyModel.star_basis(pole, 1, 0.0) * Vector3.RIGHT
	var c := SkyModel.star_basis(pole, 1, 6.0) * Vector3.RIGHT
	check(absf(b.angle_to(c) - deg_to_rad(90.0)) < deg_to_rad(15.0), "a quarter turn in six hours")


func test_real_sky_swaps_the_sky_and_lights_the_world() -> void:
	Settings.autosave = false
	var was := Settings.real_look
	Settings.real_look = false
	RealLook.swap_shaders(false)
	var holder := Node.new()
	add_child(holder)
	var street: Node = load("res://scenes/test_street.tscn").instantiate()
	holder.add_child(street)
	var sky := RealSky.new()
	holder.add_child(sky)
	await process_frames(3)
	var dc := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	var env := dc.world_environment.environment
	var painted := env.sky.sky_material
	check(not sky.is_applied(), "off under the painted look")
	Settings.real_look = true
	await process_frames(3)
	check(sky.is_applied(), "on under the real look")
	check((env.sky.sky_material as ShaderMaterial).shader.resource_path == RealSky.SKY_SHADER, "our sky in place")
	check(street.find_child("RealClouds", true, false) != null, "the clouds drawn")
	# (each frame DayCycle's physics tick sets its own light and RealSky's _process then sets the
	# sky's over it, before the frame is drawn; a test awaiting a frame wakes between the two)
	dc.set_time(12.0)
	await process_frames(2)
	sky.update(0.0)
	var noon_e := dc.sun.light_energy
	var noon_c := dc.sun.light_color
	dc.set_time(18.2)
	await process_frames(2)
	sky.update(0.0)
	var low_c := dc.sun.light_color
	check(low_c.b / low_c.r < noon_c.b / noon_c.r - 0.2, "the sun's colour from the air: warmer low (%s, noon %s)" % [low_c, noon_c])
	check(dc.sun.light_energy < noon_e, "and fainter")
	dc.set_time(12.0)
	sky.set_coverage(1.0)
	await process_frames(2)
	sky.update(0.0)
	check(dc.sun.light_energy < noon_e * 0.3, "overcast dims the sun (%.2f of %.2f)" % [dc.sun.light_energy, noon_e])
	sky.set_coverage(0.3)
	Settings.real_look = false
	await process_frames(3)
	check(not sky.is_applied() and env.sky.sky_material == painted, "the painted sky back off")
	check(street.find_child("RealClouds", true, false) == null or not is_instance_valid(street.find_child("RealClouds", true, false))
			or street.find_child("RealClouds", true, false).is_queued_for_deletion(), "the clouds gone")
	holder.queue_free()
	await process_frames(2)
	Settings.real_look = was


func test_far_land_rises_to_the_ranges() -> void:
	var t := ValleyTerrain.main()
	if not t.is_loaded():
		check(false, "the valley's bake loads")
		return
	var fl := FarLand.new()
	fl._noises()
	var west := fl.land_height(t, -22000.0, -6000.0)  # bearing ~285, 23 km: the La Plata
	var notch := fl.land_height(t, -22000.0, 0.0)  # due west down Main Street
	var south := fl.land_height(t, 0.0, 9000.0)
	check(west > 700.0, "the La Plata stand high to the west-north-west (%.0f m)" % west)
	check(notch < west * 0.7, "the sunset notch lower due west (%.0f m)" % notch)
	check(south < 600.0, "the mesa country south stays low (%.0f m)" % south)
	check(fl.land_height(t, 0.0, 0.0) < t.height(0.0, 0.0) - 10.0, "inside the bake the ranges' mesh lies under the bake's")
	check(FarLand.bearing_window(270.0, 266.0, 274.0, 4.0) > 0.99 and FarLand.bearing_window(90.0, 266.0, 274.0, 4.0) < 0.01,
			"bearing windows wrap")
	check(FarLand.bearing_window(10.0, 335.0, 60.0, 5.0) > 0.99, "across north too")
	fl.free()


func test_far_land_paints_the_bake_back_to_front() -> void:
	var t := ValleyTerrain.main()
	if not t.is_loaded():
		return
	var fl := FarLand.new()
	fl._bake_arrays = FarLand.bake_arrays(t)
	var r := t.rect()
	fl._bake_nx = int(r.size.x / FarLand.BAKE_STEP) + 1
	fl._bake_nz = int(r.size.y / FarLand.BAKE_STEP) + 1
	fl._bake_mesh = ArrayMesh.new()
	var at := Vector3(1120.0, 0.0, 180.0)
	fl._sort_bake(at)
	var arrays := fl._bake_mesh.surface_get_arrays(0)
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var first := Vector2(v[idx[0]].x - at.x, v[idx[0]].z - at.z).length()
	var last := Vector2(v[idx[idx.size() - 6]].x - at.x, v[idx[idx.size() - 6]].z - at.z).length()
	check(first > 2000.0 and last < 60.0, "the far quads first (%.0f m), the nearest last (%.0f m)" % [first, last])
	check(fl.sort_ms < 400.0, "sorted in %.0f ms" % fl.sort_ms)
	fl.free()


func test_far_land_is_coloured_below_the_snow() -> void:
	var t := ValleyTerrain.main()
	if not t.is_loaded():
		return
	var fl := FarLand.new()
	var mesh := fl.ring_mesh(t)
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var c: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var low := Color(0, 0, 0)
	var n := 0
	var white := 0
	for k in range(0, v.size(), 37):
		if v[k].y < 600.0:
			low += c[k]
			n += 1
			if c[k].r > 0.85 and c[k].g > 0.85:
				white += 1
	low /= maxf(n, 1)
	print("far land low colour %s over %d, white %d" % [low, n, white])
	check(low.r < 0.7 and white < n / 20, "below the snow line it's desert and timber (mean %s, %d of %d white)" % [low, white, n])
	fl.free()
