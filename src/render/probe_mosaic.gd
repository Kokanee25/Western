class_name ProbeMosaic
extends MeshInstance3D
## The probe mosaic (probe_mosaic.gdshader; a trial, off by default: Settings.probe_mosaic, V):
## the frame in blocks fixed to the world, by direction from an origin snapped to a grid of
## `cell` metres, so they stay put when you turn and while you walk within a cell (texel
## splatting's idea, Ebert 2026, done as one pass over the frame). A full-screen quad the camera
## carries, like DepthMosaic, which it replaces while it's on.

const SHADER := preload("res://src/render/probe_mosaic.gdshader")
## Seconds the blocks take to cross to a new origin when you're slow; moving fast they cross as
## fast as you cross cells (the paper's rate: the larger of the two).
const FADE_SECONDS := 0.33
## How quickly the measured speed follows the camera (seconds).
const SPEED_SMOOTHING := 0.05

## Metres between the grid points the origin snaps to.
var cell := 0.5
var _origin := Vector3.INF
var _prev := Vector3.ZERO
var _fade := 1.0
var _speed := 0.0
var _last := Vector3.INF


## The game's switch: on, the camera carries one (and no DepthMosaic); off, it loses it. Left out
## on the Compatibility renderer (web): no depth texture there.
static func apply(camera: Camera3D, on: bool, texels: float, cell_m: float, bands: float) -> void:
	if camera == null:
		return
	if on and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		var old := camera.get_node_or_null(^"DepthMosaic")
		if old != null:
			old.queue_free()
		attach(camera, texels, cell_m, bands)
	else:
		var m := camera.get_node_or_null(^"ProbeMosaic")
		if m != null:
			m.queue_free()


static func attach(camera: Camera3D, texels: float, cell_m: float, bands: float) -> ProbeMosaic:
	var m := camera.get_node_or_null(^"ProbeMosaic") as ProbeMosaic
	if m == null:
		m = ProbeMosaic.new()
		m.name = "ProbeMosaic"
		camera.add_child(m)
	if not is_equal_approx(m.cell, cell_m):
		m.cell = cell_m
		m._origin = Vector3.INF
	var mat := m.material_override as ShaderMaterial
	mat.set_shader_parameter(&"texels", texels)
	mat.set_shader_parameter(&"bands", bands)
	return m


## The grid point nearest `at` (the cube's origin while the camera is within half a cell of it).
static func snap(at: Vector3, cell_m: float) -> Vector3:
	return (at / cell_m).round() * cell_m


func _init() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	material_override = mat
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_offset = -1000.0


func _process(delta: float) -> void:
	step(get_parent().global_position if get_parent() is Node3D else global_position, delta)


## Follow the camera at `at`: snap the origin, and when it moves to the next grid point, cross
## the blocks from the old cube to the new over FADE_SECONDS (or as fast as cells go by). While a
## crossing is under way the origin waits for it (as the paper's probes do).
func step(at: Vector3, delta: float) -> void:
	if _last != Vector3.INF and delta > 0.0:
		var a := 1.0 - exp(-delta / SPEED_SMOOTHING)
		_speed = lerpf(_speed, at.distance_to(_last) / delta, a)
	_last = at
	var to := snap(at, cell)
	if _origin == Vector3.INF:
		_origin = to
		_prev = to
		_fade = 1.0
	elif _fade < 1.0:
		_fade = minf(1.0, _fade + maxf(1.0 / FADE_SECONDS, _speed / cell) * delta)
	elif not to.is_equal_approx(_origin):
		_prev = _origin
		_origin = to
		_fade = 0.0
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter(&"probe_origin", _origin)
	mat.set_shader_parameter(&"prev_origin", _prev)
	mat.set_shader_parameter(&"fade", _fade)


func origin() -> Vector3:
	return _origin


func fading() -> float:
	return _fade
