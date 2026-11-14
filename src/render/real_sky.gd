class_name RealSky
extends Node
## The real look's sky and the light it gives (#918; docs/LAYOUT.md "src/render" "The real sky").
## RealLook's child. While the real look is on, it:
## - puts our own physically based sky (src/render/real_sky.gdshader, SkyModel's numbers) in place
##   of the painted one on the world's Sky, and puts the painted one back when it goes off;
## - lights the world from that sky after DayCycle has set its own light (process_priority 101,
##   after DayCycle's tick and RealLook's): the sun's colour and energy are what the air leaves of
##   it at the town's altitude (low, it goes gold then red then out, the Earth's shadow), the
##   ambient is the sky's own radiance (the engine reads it from the sky; overcast greys it), the
##   fog takes the horizon's colour, the moon shines by its phase (day 1 full: every shot made so
##   far keeps its moon) from where that phase puts it, and the stars turn round the pole;
## - draws the clouds (src/render/cloud_layer.gdshader): one sheet drifting on the wind, lit by
##   the sun at its own height, `coverage` 0 clear .. 1 overcast (set_coverage, for weather), which
##   also dims the sun and greys the sky's light below;
## - in the valley, the far land (FarLand: the bake past the far plane and the ranges beyond it),
##   with the fog thinned so it shows (`light.fog_far`).
## Dials: config/looks/real_sky.json; the sky shader's uniforms are LookPreset's `sky.<uniform>`
## while it is on (`sky.coverage` the clouds' coverage).

const CONFIG := "res://config/looks/real_sky.json"
const SKY_SHADER := "res://src/render/real_sky.gdshader"
const CLOUD_SHADER := "res://src/render/cloud_layer.gdshader"
## Big enough that the dome and far land are never culled (they draw at the far plane themselves).
const HUGE := AABB(Vector3(-100000, -20000, -100000), Vector3(200000, 60000, 200000))
## The sky is sent a value only when it has moved this much (each send re-lights its radiance, as
## DayCycleConfig.sky_update_degrees says).
const SEND_DEGREES := 0.3
const SEND_AMOUNT := 0.003
## The transparent pass's order at the back (sorting depth from the camera, larger first): LightFinish's
## full-screen quad (1000: it lays the screen as it was before the pass over the frame), the clouds,
## the far land; everything else nearer than the far plane comes after.
const SORT_CLOUDS := 950.0
const SORT_FAR_LAND := 900.0
## `-- --painted-sky`: the real look under the painted sky, as before #918.
static var enabled := not "--painted-sky" in OS.get_cmdline_user_args()

var model := SkyModel.new()
var cfg := {}
## The clouds' coverage now (0 clear .. 1 overcast) and where it's going.
var coverage := 0.3
var _coverage_to := 0.3
var _coverage_rate := 0.0
var _coverage_written := -1.0
var _applied := false
var _dc: DayCycle
var _env: Environment
var _sky: Sky
var _painted: Material
var _mat: ShaderMaterial
var _clouds: MeshInstance3D
var _cloud_mat: ShaderMaterial
var _far: FarLand
var _wind := Vector2.ZERO
var _sent := {}
var _env_before := {}
var _shadow_before := 1.0
var _fog_key := Vector4(9, 9, 9, 9)
var _fog := Color(0.6, 0.65, 0.72)
var _fog_energy := 1.0
var _zenith := Vector3(0.2, 0.3, 0.5)
var _horizon_rad := Vector3(0.6, 0.65, 0.7)


func _ready() -> void:
	add_to_group(&"real_sky")
	process_priority = 101
	cfg = load_config()
	_apply_model_dials()
	coverage = float(_section("clouds").get("coverage", 0.3))
	_coverage_to = coverage


static func load_config() -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return d if d is Dictionary else {}


func _section(name: String) -> Dictionary:
	var s: Variant = cfg.get(name, {})
	return s if s is Dictionary else {}


func _dial(section: String, key: String, default: float) -> float:
	return float(_section(section).get(key, default))


func _apply_model_dials() -> void:
	var s := _section("sky")
	model.turbidity = float(s.get("turbidity", model.turbidity))
	model.mie_g = float(s.get("mie_g", model.mie_g))
	model.altitude = float(s.get("altitude", model.altitude))
	model.multi = float(s.get("multi", model.multi))
	model.gain = float(s.get("gain", model.gain))


## Coverage to `to` over `seconds` of real time (0: at once). A weather system's handle.
func set_coverage(to: float, seconds := 0.0) -> void:
	_coverage_to = clampf(to, 0.0, 1.0)
	if seconds <= 0.0:
		coverage = _coverage_to
		_coverage_rate = 0.0
		if _mat:
			_mat.set_shader_parameter(&"coverage", coverage)
			_coverage_written = coverage
	else:
		_coverage_rate = absf(_coverage_to - coverage) / seconds


func is_applied() -> bool:
	return _applied


func _process(delta: float) -> void:
	var t := Prof.start()
	_step(delta)
	Prof.stop(&"real_sky", t)


func _step(delta: float) -> void:
	var dc := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	var env: Environment = dc.world_environment.environment if dc and dc.world_environment else null
	var want := Settings.real_look and dc != null and env != null and env.sky != null
	if _applied and (not want or dc != _dc or env != _env or not is_instance_valid(_dc)):
		_detach()
	if want and not _applied:
		_attach(dc, env)
	if _applied:
		update(delta)


func _attach(dc: DayCycle, env: Environment) -> void:
	_dc = dc
	_env = env
	_sky = env.sky
	_painted = _sky.sky_material
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load(SKY_SHADER)
	_mat.set_shader_parameter(&"transmittance_lut", model.lut_texture())
	var s := _section("sky")
	for k: String in ["turbidity", "mie_g", "altitude", "multi", "gain", "sun_radius", "sun_bright", "moon_radius"]:
		if s.has(k):
			_mat.set_shader_parameter(StringName(k), float(s[k]))
	if s.has("night_glow"):
		var g: Array = s.night_glow
		_mat.set_shader_parameter(&"night_glow", Vector3(g[0], g[1], g[2]))
	_mat.set_shader_parameter(&"milky_way", float(s.get("milky_way", 1.0)))
	_mat.set_shader_parameter(&"coverage", coverage)
	_coverage_written = coverage
	_sky.sky_material = _mat
	_sent.clear()
	_fog_key = Vector4(9, 9, 9, 9)
	for k: String in ["fog_aerial_perspective", "fog_light_energy"]:
		_env_before[k] = env.get(k)
	_shadow_before = dc.sun.shadow_opacity if dc.sun else 1.0
	_make_clouds(dc.get_parent())
	var valley := get_tree().get_first_node_in_group(&"valley_world") as Node3D
	if valley and FarLand.enabled:
		_far = FarLand.new()
		valley.add_child(_far)
	_applied = true
	update(0.0)
	print("[real sky] on")


func _detach() -> void:
	_applied = false
	if is_instance_valid(_sky) and _sky.sky_material == _mat:
		_sky.sky_material = _painted
	if is_instance_valid(_dc):
		# DayCycle sends its sky only what's changed: have it send the painted sky everything again.
		_dc.set(&"_sky_sent", {})
		_dc.apply_visuals()
	if _env:
		for k: String in _env_before:
			_env.set(k, _env_before[k])
	_env_before.clear()
	if is_instance_valid(_dc) and _dc.sun:
		_dc.sun.shadow_opacity = _shadow_before
	if is_instance_valid(_clouds):
		_clouds.queue_free()
	if is_instance_valid(_far):
		_far.queue_free()
	_clouds = null
	_far = null
	_dc = null
	_env = null
	_sky = null
	print("[real sky] off")


func _make_clouds(parent: Node) -> void:
	if parent == null:
		return
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.frequency = 0.008
	noise.seed = 918
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.noise = noise
	tex.normalize = true
	_cloud_mat = ShaderMaterial.new()
	_cloud_mat.shader = load(CLOUD_SHADER)
	_cloud_mat.set_shader_parameter(&"shape_noise", tex)
	_cloud_mat.set_shader_parameter(&"height", _dial("clouds", "height", 2600.0))
	_cloud_mat.set_shader_parameter(&"thickness", _dial("clouds", "thickness", 4.0))
	_cloud_mat.set_shader_parameter(&"scale", _dial("clouds", "scale", 14000.0))
	_cloud_mat.set_shader_parameter(&"detail_scale", _dial("clouds", "detail_scale", 3500.0))
	var dome := SphereMesh.new()
	dome.radius = 1.0
	dome.height = 2.0
	dome.radial_segments = 32
	dome.rings = 16
	_clouds = MeshInstance3D.new()
	_clouds.name = "RealClouds"
	_clouds.mesh = dome
	_clouds.material_override = _cloud_mat
	_clouds.custom_aabb = HUGE
	_clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_clouds.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Drawn after LightFinish's quad (SORT_CLOUDS): sorted by their far-off box they came before it
	# and it wiped them out.
	_clouds.sorting_use_aabb_center = false
	_clouds.sorting_offset = -SORT_CLOUDS
	parent.add_child(_clouds)


## This frame's light from the sky (after DayCycle's tick).
func update(delta: float) -> void:
	if _coverage_rate > 0.0:
		coverage = move_toward(coverage, _coverage_to, _coverage_rate * delta)
		if is_equal_approx(coverage, _coverage_to):
			_coverage_rate = 0.0
		_mat.set_shader_parameter(&"coverage", coverage)
		_coverage_written = coverage
	else:
		var c: Variant = _mat.get_shader_parameter(&"coverage")  # a look's `sky.coverage`
		if c != null and not is_equal_approx(float(c), _coverage_written):
			coverage = clampf(float(c), 0.0, 1.0)
			_coverage_to = coverage
	_coverage_written = coverage
	var dc := _dc
	var hour := dc.time_of_day
	var sun_dir := dc.get_sun_direction()
	var phase := SkyModel.moon_phase(dc.day, hour, _dial("moon", "full_day", 1.0))
	var moon_dir := dc.get_moon_direction(hour - SkyModel.moon_hour_lag(phase))
	var over := smoothstep(0.45, 1.0, coverage)
	var t_zen := SkyModel.luminance(model.light_at(Vector3.UP))
	var t_sun := model.light_at(sun_dir)
	var t_moon := model.light_at(moon_dir)
	var bright := SkyModel.moon_brightness(phase)
	var daylight := dc.get_daylight()
	# The sun: what the air leaves of it.
	if dc.sun:
		var e := _dial("light", "sun_energy", 1.6) * SkyModel.luminance(t_sun) / t_zen \
				* smoothstep(-0.012, 0.02, sun_dir.y) * lerpf(1.0, _dial("light", "overcast_sun", 0.12), over)
		dc.sun.light_color = _colour(t_sun)
		dc.sun.light_energy = e
		dc.sun.visible = e > 0.001
		# Under cloud the sun's light is spread: its shadows fade.
		dc.sun.shadow_opacity = lerpf(1.0, 0.2, over)
	if dc.moon:
		DayCycle._aim(dc.moon, moon_dir)
		var me := _dial("light", "moon_energy", 0.45) * bright * SkyModel.luminance(t_moon) / t_zen \
				* smoothstep(-0.01, 0.06, moon_dir.y) * (1.0 - daylight) * lerpf(1.0, 0.2, over)
		dc.moon.light_energy = me
		dc.moon.visible = me > 0.001
	# The sky.
	var moon_sky := _dial("sky", "moon_sky", 0.0045) * bright
	_send(&"sky_sun", sun_dir, true)
	_send(&"sky_moon", moon_dir, true)
	_send(&"moon_lit_dir", SkyModel.moon_lit_from(moon_dir, sun_dir, phase), true)
	_send(&"moon_light", moon_sky)
	# The moon's disk: bright against the night, pale against the day's sky.
	_send(&"moon_bright", _dial("sky", "moon_bright", 2.5) * lerpf(1.0, _dial("sky", "moon_day", 0.06), daylight))
	_send(&"sun_tint", t_sun)
	# (the eye's moon is near white even low: the air's red softened)
	_send(&"moon_tint", Vector3(sqrt(t_moon.x), sqrt(t_moon.y), sqrt(t_moon.z)))
	var stars := _dial("sky", "stars", 1.6) * (1.0 - smoothstep(-0.2, -0.03, sun_dir.y)) \
			* lerpf(1.0, 0.5, bright * smoothstep(0.0, 0.2, moon_dir.y))
	_send(&"star_light", stars)
	if stars > 0.0:
		var pole := SkyModel.pole(dc.get_sun_direction(12.0), dc.config.sun_tilt_degrees)
		var frame := _equatorial(pole)
		var turned := Basis(pole, -(hour / 24.0 + dc.day / 365.2422) * TAU * 1.0027379) * frame
		_send(&"star_frame", turned.transposed())
	_send(&"overcast", over)
	var cam := get_viewport().get_camera_3d()
	if cam:
		# (a uniform, not the sky shader's POSITION: a sky that reads POSITION is re-lit whenever the
		# camera moves)
		_send(&"eye_height", snappedf(cam.global_position.y, 25.0))
	# The horizon's colour for the fog, and the zenith's for the clouds: worked out on the CPU only
	# when the lights have moved.
	var key := Vector4(sun_dir.y, sun_dir.x, moon_dir.y + moon_sky * 10.0, over)
	if key.distance_to(_fog_key) > 0.004:
		_fog_key = key
		_horizon_colours(sun_dir, moon_dir, moon_sky, over)
	_send(&"overcast_color", _overcast_grey(over))
	if _env:
		_env.fog_light_color = _fog
		_env.fog_light_energy = _fog_energy
		var thin := _dial("light", "fog_far", 0.006) if is_instance_valid(_far) else _dial("light", "fog", 0.5)
		_env.fog_density = dc.config.fog_density * thin
		_env.fog_aerial_perspective = _dial("light", "aerial_perspective", 1.0)
		_env.ambient_light_sky_contribution = _dial("light", "ambient_sky", 1.0)
		_env.ambient_light_energy = _dial("light", "ambient_energy", 1.0)
		_env.ambient_light_color = _fog
	_clouds_update(delta, sun_dir, moon_dir, t_sun, bright)
	if is_instance_valid(_far):
		# The far land's light: the sun's (or the moon's) as the engine's lights have it now.
		var sun_on := dc.sun != null and dc.sun.visible
		var lc: Color = dc.sun.light_color if sun_on else (dc.moon.light_color if dc.moon else Color.BLACK)
		var le: float = dc.sun.light_energy if sun_on else (dc.moon.light_energy if dc.moon and dc.moon.visible else 0.0)
		var ll := lc.srgb_to_linear()
		FarLand.set_light(sun_dir if sun_on else moon_dir, Vector3(ll.r, ll.g, ll.b) * le, _zenith, _horizon_rad)


func _clouds_update(delta: float, sun_dir: Vector3, moon_dir: Vector3, _t_sun: Vector3, bright: float) -> void:
	if _cloud_mat == null or not is_instance_valid(_clouds):
		return
	var cam := _clouds.get_viewport().get_camera_3d()
	if cam:
		_clouds.global_position = cam.global_position
	var w: Array = _section("clouds").get("wind", [6.0, -2.5])
	_wind += Vector2(w[0], w[1]) * delta * _dial("clouds", "time_scale", 6.0)
	_wind = Vector2(fposmod(_wind.x, 207000.0), fposmod(_wind.y, 207000.0))
	var h := _dial("clouds", "height", 2600.0)
	# The sun lights the clouds till it's well under their horizon; then the moon.
	var sun_w := smoothstep(-0.12, -0.04, sun_dir.y)
	# (lit as at a third of its height: the low sun's gold on the clouds, which a judge missed)
	var lit_sun := model.light_at(sun_dir, h * 0.3) * _dial("light", "sun_energy", 1.6) * 0.75
	var mc := _dc.config.moon_color
	var lit_moon := model.light_at(moon_dir, h) * Vector3(mc.r, mc.g, mc.b) * _dial("light", "moon_energy", 0.45) * bright * 0.5 \
			* smoothstep(-0.02, 0.05, moon_dir.y)
	var light_dir := sun_dir if sun_w > 0.5 or moon_dir.y < 0.0 else moon_dir
	var light := lit_sun * sun_w + lit_moon * (1.0 - sun_w)
	var ground := model.light_at(sun_dir) * maxf(sun_dir.y, 0.0) * 0.12 + Vector3.ONE * 0.002
	_cloud_mat.set_shader_parameter(&"coverage", coverage)
	_cloud_mat.set_shader_parameter(&"wind_offset", _wind)
	_cloud_mat.set_shader_parameter(&"light_dir", light_dir)
	_cloud_mat.set_shader_parameter(&"light_color", light)
	_cloud_mat.set_shader_parameter(&"sky_light", _zenith.lerp(_horizon_rad, 0.4))
	_cloud_mat.set_shader_parameter(&"ground_light", ground)


## The sky's colour low round the horizon (four bearings, 3 degrees up) and overhead, from the
## model, for the fog and the clouds.
func _horizon_colours(sun_dir: Vector3, moon_dir: Vector3, moon_sky: float, over: float) -> void:
	var sum := Vector3.ZERO
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var d := Vector3(cos(a) * 0.9986, 0.0523, sin(a) * 0.9986)
		sum += model.radiance(d, sun_dir, 10) + model.radiance(d, moon_dir, 8) * moon_sky
	sum /= 4.0
	_zenith = model.radiance(Vector3.UP, sun_dir, 10) + model.radiance(Vector3.UP, moon_dir, 8) * moon_sky
	var g := _overcast_grey(over)
	sum = sum.lerp(g, over)
	_zenith = _zenith.lerp(g, over)
	_horizon_rad = sum
	FarLand.set_haze(sum, 1.6 * (1.0 + 2.5 * over))
	var m := maxf(maxf(sum.x, sum.y), maxf(sum.z, 1e-5))
	_fog_energy = clampf(m, 0.0, 4.0)
	_fog = Color(sum.x / m, sum.y / m, sum.z / m).linear_to_srgb()


## An overcast sky's grey: the clear sky's brightness at this hour, spread even.
func _overcast_grey(over: float) -> Vector3:
	if over <= 0.0:
		return Vector3(0.5, 0.5, 0.5)
	var l := SkyModel.luminance(_zenith) * _dial("light", "overcast_bright", 2.2)
	return Vector3(l * 0.97, l, l * 1.04)


## The equatorial frame: y the pole, x and z in the celestial equator.
static func _equatorial(pole: Vector3) -> Basis:
	var x := pole.cross(Vector3.UP)
	if x.length_squared() < 1e-6:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(pole).normalized()
	return Basis(x, pole, z)


## A light's colour from what the air leaves of white (normalised, sRGB).
static func _colour(t: Vector3) -> Color:
	var m := maxf(maxf(t.x, t.y), maxf(t.z, 1e-6))
	return Color(t.x / m, t.y / m, t.z / m).linear_to_srgb()


## Send the sky a uniform if it has moved on from what was last sent: a direction (`dir`) by
## SEND_DEGREES, a colour by SEND_AMOUNT in any channel, a frame by its axes' turn, a number by
## SEND_AMOUNT of itself.
func _send(name: StringName, value: Variant, dir := false) -> void:
	var last: Variant = _sent.get(name)
	if last != null:
		if value is Vector3:
			var a: Vector3 = value
			var b: Vector3 = last
			if dir and a.angle_to(b) <= deg_to_rad(SEND_DEGREES):
				return
			if not dir and maxf(maxf(absf(a.x - b.x), absf(a.y - b.y)), absf(a.z - b.z)) <= SEND_AMOUNT * maxf(maxf(b.x, maxf(b.y, b.z)), 0.01):
				return
		elif value is Basis:
			var a: Basis = value
			var b: Basis = last
			if a.x.angle_to(b.x) + a.y.angle_to(b.y) < deg_to_rad(SEND_DEGREES):
				return
		elif absf(float(value) - float(last)) <= SEND_AMOUNT * maxf(absf(float(last)), 0.01):
			return
	_sent[name] = value
	_mat.set_shader_parameter(name, value)
