class_name DayCycle
extends Node
## The town clock and the sky. A day lasts DayCycleConfig.day_length_seconds of real time
## (45 minutes). The clock runs on the physics tick so it is testable without rendering; the
## visuals (sun, moon, sky colours, fog) follow from the time alone.

@export var config: DayCycleConfig
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment

## Hours since midnight, 0 <= time_of_day < 24.
var time_of_day := 0.0
var day := 1
var time_scale := 1.0
## The clock stands still (DayCycleConfig.hold_clock): `advance` doesn't move it. time_scale is
## kept, since bleeding and the body's clocks run on it.
var held := false

var _scale_index := 0
var _stop_index := -1
var _sky_sent := {}  # sky uniform -> the value last sent (see _send_sky)
var _drift_seconds := 0.0  # real seconds of cloud drift


func _ready() -> void:
	add_to_group(&"day_cycle")
	# The buildings' far-lamp shadow meshes aren't the sun's or the moon's (Layers.VIS_WALLS).
	for l: DirectionalLight3D in [sun, moon]:
		if l:
			l.shadow_caster_mask = Layers.ALL_BUT_WALLS
	if config == null:
		config = DayCycleConfig.new()
	time_of_day = fposmod(config.start_hour, 24.0)
	time_scale = config.debug_time_scales[0] if not config.debug_time_scales.is_empty() else 1.0
	held = config.hold_clock
	apply_visuals()


func _process(delta: float) -> void:
	var t := Prof.start()
	_process_step(delta)
	Prof.stop(&"day_cycle", t)


func _process_step(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_time_scale"):
		cycle_time_scale()
	if Input.is_action_just_pressed(&"debug_hour"):
		next_hour_stop()


func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"day_cycle", t)


func _physics_step(delta: float) -> void:
	_drift_seconds += delta
	advance(delta)
	apply_visuals()


## Move the clock on by some real seconds (scaled by the debug multiplier).
func advance(real_seconds: float) -> void:
	if held:
		return
	pass_hours(real_seconds * time_scale * 24.0 / config.day_length_seconds)


## Move the clock on by game hours, announcing each hour and day it crosses.
func pass_hours(hours: float) -> void:
	Blood.dry(hours)
	for fm: Node in get_tree().get_nodes_in_group(&"floor_marks"):
		(fm as FloorMarks).age(hours)  # spills dry and soak in
	var before := int(floor(time_of_day))
	var t := time_of_day + hours
	var crossed := int(floor(t)) - before
	for i in range(1, crossed + 1):
		var hour := (before + i) % 24
		if hour == 0:
			day += 1
			Events.day_started.emit(day)
		Events.hour_changed.emit(hour)
	time_of_day = fposmod(t, 24.0)


## Jump the clock (debug, tests, waking up). Announces the hour so lamps and the like catch up.
func set_time(hour: float) -> void:
	time_of_day = fposmod(hour, 24.0)
	apply_visuals()
	Events.hour_changed.emit(get_hour())


## Run the clock at this speed (lets a held clock go: the soak, the labs and the bridge set a speed
## to have time pass).
func set_time_scale(scale: float) -> void:
	time_scale = scale
	held = false
	Events.time_scale_changed.emit(scale)


## T: held -> x1 -> x30 -> x180 -> held (with hold_clock; without it, round the speeds).
func cycle_time_scale() -> void:
	var scales := config.debug_time_scales
	if scales.is_empty():
		return
	if held:
		_scale_index = 0
	else:
		_scale_index += 1
		if _scale_index >= scales.size():
			_scale_index = 0
			if config.hold_clock:
				time_scale = scales[0]
				set_held(true)
				return
	set_time_scale(scales[_scale_index])


## Hold the clock or let it run (Events.time_scale_changed tells the overlay).
func set_held(on: bool) -> void:
	held = on
	Events.time_scale_changed.emit(time_scale)


## The hour key: the next of config.hour_stops (noon, afternoon, golden hour, night).
func next_hour_stop() -> void:
	var stops := config.hour_stops
	if stops.is_empty():
		return
	_stop_index = (_stop_index + 1) % stops.size()
	set_time(stops[_stop_index])
	Events.time_scale_changed.emit(time_scale)


## "Time held at 12:00" / "Time x30": the overlay's toast.
func describe_speed() -> String:
	if held:
		return "Time held at %s (T to let it run)" % get_clock_text()
	return "Time running x%s at %s (T: %s)" % [str(time_scale), get_clock_text(),
			"faster" if _scale_index < config.debug_time_scales.size() - 1 else ("hold" if config.hold_clock else "x1")]


func get_hour() -> int:
	return int(floor(time_of_day))


## "17:05" style clock text.
func get_clock_text() -> String:
	var minutes := int(floor(time_of_day * 60.0)) % (24 * 60)
	return "%02d:%02d" % [minutes / 60, minutes % 60]


## Unit vector from the ground toward the sun. Rises in the east (+X), sets in the west (-X),
## and arcs toward the south (-Z, across the street, so the storefronts get the sun) by the tilt.
func get_sun_direction(hour: float = time_of_day) -> Vector3:
	var h := (hour / 24.0 - 0.5) * TAU
	var v := Vector3(-sin(h), cos(h) + config.day_bias, 0.0).normalized()
	return v.rotated(Vector3.RIGHT, -deg_to_rad(config.sun_tilt_degrees)).rotated(Vector3.UP, deg_to_rad(config.sun_azimuth_degrees))


## A full moon opposite the sun's hour, on its own arc (`moon_tilt_degrees`; the sun's tilt puts it
## exactly opposite the sun, as it was).
func get_moon_direction(hour: float = time_of_day) -> Vector3:
	var h := (hour / 24.0 - 0.5) * TAU
	var v := Vector3(sin(h), -(cos(h) + config.day_bias), 0.0).normalized()
	return v.rotated(Vector3.RIGHT, deg_to_rad(config.moon_tilt_degrees)).rotated(Vector3.UP, deg_to_rad(config.moon_azimuth_degrees))


func is_daytime(hour: float = time_of_day) -> bool:
	return get_sun_direction(hour).y > 0.0


## 0 at night, 1 in full day; smooth through dawn and dusk.
func get_daylight(hour: float = time_of_day) -> float:
	return smoothstep(-0.05, 0.2, get_sun_direction(hour).y)


## 0 with the sun under ~18 degrees, 1 from ~48 up (noon is ~55): the high sun's dials.
func get_high_sun(hour: float = time_of_day) -> float:
	return smoothstep(0.3, 0.75, get_sun_direction(hour).y)


## The stars' share: none while the sun is up, all of them once it's ~6 degrees down (they had
## followed daylight, and showed over the golden-hour street with the sun 6 degrees up).
func get_starlight(hour: float = time_of_day) -> float:
	return 1.0 - smoothstep(-0.1, 0.0, get_sun_direction(hour).y)


func apply_visuals() -> void:
	var t := time_of_day / 24.0
	var sun_dir := get_sun_direction()
	var moon_dir := get_moon_direction()
	var daylight := get_daylight()
	var horizon: Color = config.sky_horizon.sample(t) if config.sky_horizon else Color(0.7, 0.75, 0.8)
	var top: Color = config.sky_top.sample(t) if config.sky_top else Color(0.3, 0.5, 0.8)
	var sun_color: Color = config.sun_color.sample(t) if config.sun_color else Color.WHITE
	# The high sun's own sky (DayCycleConfig "High sun"): paler, the horizon white-hot.
	var high := get_high_sun()
	if high > 0.0:
		var grey := Color(top.get_luminance(), top.get_luminance(), top.get_luminance())
		top = grey.lerp(top, lerpf(1.0, config.sky_high_saturation, high))
		top = top.lerp(horizon, config.sky_high_pale * high)
		horizon = horizon.lerp(config.sky_high_haze, config.sky_high_white * high)

	if sun:
		_aim(sun, sun_dir)
		sun.light_color = sun_color
		sun.light_energy = config.sun_max_energy * smoothstep(-0.02, 0.15, sun_dir.y)
		sun.visible = sun.light_energy > 0.001
	if moon:
		_aim(moon, moon_dir)
		moon.light_color = config.moon_color
		moon.light_energy = config.moon_max_energy * smoothstep(0.0, 0.2, moon_dir.y) * (1.0 - daylight)
		moon.visible = moon.light_energy > 0.001
		if is_inside_tree():
			MoonWindows.apply(get_tree(), config, moon.light_energy / maxf(config.moon_max_energy, 0.001))

	if world_environment and world_environment.environment:
		var env := world_environment.environment
		# Golden hour: 1 with the sun low over the horizon, 0 with it high (and at night).
		var golden := (1.0 - smoothstep(0.1, 0.6, sun_dir.y)) * daylight
		var warm := horizon.lerp(sun_color, 0.4)
		# The haze down the street takes the low sun's gold, not the blue overhead.
		env.fog_light_color = horizon.lerp(top, 0.3).lerp(warm * config.fog_low_sun_level, golden)
		# The haze's own low sun: all of it from just over the horizon to ~6 degrees (golden, scaled
		# by daylight, is only ~0.6 there), none at night.
		var low_sun := (1.0 - smoothstep(0.1, 0.6, sun_dir.y)) * smoothstep(-0.05, 0.05, sun_dir.y)
		env.fog_density = config.fog_density * lerpf(1.0, config.fog_low_sun, low_sun) * lerpf(1.0, config.fog_high_sun, high)
		env.volumetric_fog_density = config.volumetric_fog_density * lerpf(1.0, config.volumetric_low_sun, low_sun) \
				* lerpf(1.0, config.volumetric_high_sun, high)
		env.ambient_light_energy = lerpf(config.ambient_energy_night, config.ambient_energy_day, daylight) \
				* lerpf(1.0, config.ambient_low_sun, golden)
		env.ambient_light_color = (warm * config.ambient_warm_level).lerp(config.ambient_day_colour * config.ambient_warm_level * 2.0,
				config.ambient_day_cool * high)
		env.ambient_light_sky_contribution = lerpf(config.ambient_sky_day, config.ambient_sky_low_sun, golden)
		# The painting's golden hour is a dark picture with a bright road and sky: the eye's
		# exposure comes down with the sun.
		env.tonemap_exposure = lerpf(config.exposure_night, lerpf(config.exposure_day, config.exposure_low_sun, golden), daylight)
		for probe in get_tree().get_nodes_in_group(&"interior_ambient"):
			var night: float = probe.get_meta(&"night_ambient", config.interior_ambient_night)
			(probe as ReflectionProbe).ambient_color_energy = lerpf(night, config.interior_ambient_day, daylight)
		var sky_mat: ShaderMaterial = env.sky.sky_material as ShaderMaterial if env.sky else null
		if sky_mat:
			# Only what's changed visibly (see DayCycleConfig.sky_update_degrees): each send re-lights
			# the sky's radiance.
			var col := config.sky_update_colour
			_send_sky(sky_mat, &"top_color", top, col)
			_send_sky(sky_mat, &"horizon_color", horizon, col)
			_send_sky(sky_mat, &"sun_color", sun_color, col)
			_send_sky(sky_mat, &"sun_dir", sun_dir, deg_to_rad(config.sky_update_degrees))
			_send_sky(sky_mat, &"moon_dir", moon_dir, deg_to_rad(config.sky_update_degrees))
			_send_sky(sky_mat, &"star_strength", config.star_strength * get_starlight(), col)
			_send_sky(sky_mat, &"cloud_drift", _drift_seconds * config.cloud_drift_speed, col)


## Set a sky uniform if it's moved on from what was last sent by more than `by` (a colour: in
## any channel; a direction: the angle in radians; a number: the difference).
func _send_sky(m: ShaderMaterial, name: StringName, value: Variant, by: float) -> void:
	var last: Variant = _sky_sent.get(name)
	if last != null:
		var moved := 0.0
		if value is Color:
			var a: Color = value
			var b: Color = last
			moved = maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b))
		elif value is Vector3:
			moved = (value as Vector3).angle_to(last as Vector3)
		else:
			moved = absf(float(value) - float(last))
		if moved <= by:
			return
	_sky_sent[name] = value
	m.set_shader_parameter(name, value)


## Point a directional light so it shines from `toward_light` down onto the ground.
static func _aim(light: DirectionalLight3D, toward_light: Vector3) -> void:
	var up := Vector3.UP if absf(toward_light.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	light.basis = Basis.looking_at(-toward_light, up)
