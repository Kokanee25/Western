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

var _scale_index := 0


func _ready() -> void:
	add_to_group(&"day_cycle")
	if config == null:
		config = DayCycleConfig.new()
	time_of_day = fposmod(config.start_hour, 24.0)
	time_scale = config.debug_time_scales[0] if not config.debug_time_scales.is_empty() else 1.0
	apply_visuals()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"debug_time_scale"):
		cycle_time_scale()


func _physics_process(delta: float) -> void:
	advance(delta)
	apply_visuals()


## Move the clock on by some real seconds (scaled by the debug multiplier).
func advance(real_seconds: float) -> void:
	var hours := real_seconds * time_scale * 24.0 / config.day_length_seconds
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


func set_time_scale(scale: float) -> void:
	time_scale = scale
	Events.time_scale_changed.emit(scale)


func cycle_time_scale() -> void:
	var scales := config.debug_time_scales
	if scales.is_empty():
		return
	_scale_index = (_scale_index + 1) % scales.size()
	set_time_scale(scales[_scale_index])


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
	return v.rotated(Vector3.RIGHT, -deg_to_rad(config.sun_tilt_degrees))


## A full moon opposite the sun's hour, on its own arc (`moon_tilt_degrees`; the sun's tilt puts it
## exactly opposite the sun, as it was).
func get_moon_direction(hour: float = time_of_day) -> Vector3:
	var h := (hour / 24.0 - 0.5) * TAU
	var v := Vector3(sin(h), -(cos(h) + config.day_bias), 0.0).normalized()
	return v.rotated(Vector3.RIGHT, deg_to_rad(config.moon_tilt_degrees))


func is_daytime(hour: float = time_of_day) -> bool:
	return get_sun_direction(hour).y > 0.0


## 0 at night, 1 in full day; smooth through dawn and dusk.
func get_daylight(hour: float = time_of_day) -> float:
	return smoothstep(-0.05, 0.2, get_sun_direction(hour).y)


func apply_visuals() -> void:
	var t := time_of_day / 24.0
	var sun_dir := get_sun_direction()
	var moon_dir := get_moon_direction()
	var daylight := get_daylight()
	var horizon: Color = config.sky_horizon.sample(t) if config.sky_horizon else Color(0.7, 0.75, 0.8)
	var top: Color = config.sky_top.sample(t) if config.sky_top else Color(0.3, 0.5, 0.8)
	var sun_color: Color = config.sun_color.sample(t) if config.sun_color else Color.WHITE

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

	if world_environment and world_environment.environment:
		var env := world_environment.environment
		# Golden hour: 1 with the sun low over the horizon, 0 with it high (and at night).
		var golden := (1.0 - smoothstep(0.1, 0.6, sun_dir.y)) * daylight
		var warm := horizon.lerp(sun_color, 0.4)
		# The haze down the street takes the low sun's gold, not the blue overhead.
		env.fog_light_color = horizon.lerp(top, 0.3).lerp(warm * config.fog_low_sun_level, golden)
		env.fog_density = config.fog_density
		env.volumetric_fog_density = config.volumetric_fog_density
		env.ambient_light_energy = lerpf(config.ambient_energy_night, config.ambient_energy_day, daylight) \
				* lerpf(1.0, config.ambient_low_sun, golden)
		env.ambient_light_color = warm * config.ambient_warm_level
		env.ambient_light_sky_contribution = lerpf(1.0, config.ambient_sky_low_sun, golden)
		# The painting's golden hour is a dark picture with a bright road and sky: the eye's
		# exposure comes down with the sun.
		env.tonemap_exposure = lerpf(1.0, config.exposure_low_sun, golden)
		for probe in get_tree().get_nodes_in_group(&"interior_ambient"):
			var night: float = probe.get_meta(&"night_ambient", config.interior_ambient_night)
			(probe as ReflectionProbe).ambient_color_energy = lerpf(night, config.interior_ambient_day, daylight)
		var sky_mat: ShaderMaterial = env.sky.sky_material as ShaderMaterial if env.sky else null
		if sky_mat:
			sky_mat.set_shader_parameter(&"top_color", top)
			sky_mat.set_shader_parameter(&"horizon_color", horizon)
			sky_mat.set_shader_parameter(&"sun_color", sun_color)
			sky_mat.set_shader_parameter(&"sun_dir", sun_dir)
			sky_mat.set_shader_parameter(&"moon_dir", moon_dir)
			sky_mat.set_shader_parameter(&"star_strength", config.star_strength * (1.0 - daylight))


## Point a directional light so it shines from `toward_light` down onto the ground.
static func _aim(light: DirectionalLight3D, toward_light: Vector3) -> void:
	var up := Vector3.UP if absf(toward_light.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
	light.basis = Basis.looking_at(-toward_light, up)
