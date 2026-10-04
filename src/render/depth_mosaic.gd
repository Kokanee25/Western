class_name DepthMosaic
extends MeshInstance3D
## The painting's mosaic in screen space (depth_mosaic.gdshader): the lit frame in blocks that
## shrink with distance, one colour each, the light in steps. A full-screen quad a camera carries:
## `DepthMosaic.attach(camera, block_k, steps)` adds or retunes one (block_k: block pixels × metres,
## ~5 for the saloon painting at 1280 wide; steps: tones of light, 0 = smooth).

const SHADER := preload("res://src/render/depth_mosaic.gdshader")
## The shader knobs `tuning` may set, with the shader's own defaults (kept here too: headless, the
## renderer can't be asked for them); any `tuning` leaves out goes back to its default when a
## mosaic is attached again (the look switched off). block_k and steps are attach()'s arguments.
const KNOB_DEFAULTS := {
	"depth_power": 1.0, "soft": 0.0, "average": 0.0, "dark_weight": 0.0, "sat_steps": 0.0,
	"hue_steps": 0.0, "min_block": 2.0, "max_block": 4.0, "block_k": 5.0, "steps": 14.0,
}
## How far up a roof counts as a roof (block_in), in metres.
const ROOF_REACH := 30.0
## Seconds between roof checks, and how fast the block size eases between the two.
const ROOF_CHECK := 0.25
const BLOCK_EASE := 4.0

## Extra shader knobs laid on every mosaic attached (the quantise-once look, Settings.QUANTISE_TUNING:
## KNOBS above, plus `block_in` / `block_out`, the block size in render pixels under a roof and in
## the open, which the mosaic picks between itself by a ray up from the camera). Empty = the
## shader's defaults, the game's look.
static var tuning := {}

## Picking block_in / block_out by the roof check (off when a tool sets block_k itself).
var scene_blocks := false
var _block_in := 4.0
var _block_out := 6.0
var _block := 0.0
var _since_check := 0.0
var _under_roof := false


## The game's switch (Settings.mosaic): on, the camera gets one; off, it loses it. Left out on
## the Compatibility renderer (web): no depth texture there.
static func apply(camera: Camera3D, on: bool, block_k: float, steps: float) -> void:
	if camera == null:
		return
	if on and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		attach(camera, block_k, steps)
	else:
		var m := camera.get_node_or_null(^"DepthMosaic")
		if m != null:
			m.queue_free()


static func attach(camera: Camera3D, block_k: float, steps := 14.0) -> DepthMosaic:
	var m := camera.get_node_or_null(^"DepthMosaic") as DepthMosaic
	if m == null:
		m = DepthMosaic.new()
		m.name = "DepthMosaic"
		camera.add_child(m)
	var mat := m.material_override as ShaderMaterial
	mat.set_shader_parameter(&"block_k", block_k)
	mat.set_shader_parameter(&"steps", steps)
	for k: String in KNOB_DEFAULTS:
		if k != "block_k" and k != "steps":
			mat.set_shader_parameter(StringName(k), tuning[k] if tuning.has(k) else KNOB_DEFAULTS[k])
	m.scene_blocks = tuning.has("block_in") and tuning.has("block_out")
	if m.scene_blocks:
		m._block_in = tuning["block_in"]
		m._block_out = tuning["block_out"]
		m._block = 0.0
		m._since_check = ROOF_CHECK
	return m


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


## Under a roof the blocks are block_in render pixels, in the open block_out, easing between the
## two over about a quarter of a second (the shader rounds, so it steps a pixel at a time).
func _physics_process(delta: float) -> void:
	if not scene_blocks:
		return
	_since_check += delta
	if _since_check >= ROOF_CHECK:
		_since_check = 0.0
		var space := get_world_3d().direct_space_state if get_world_3d() != null else null
		if space != null:
			var from := global_position
			var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * ROOF_REACH, Layers.WORLD)
			_under_roof = not space.intersect_ray(q).is_empty()
	var want := _block_in if _under_roof else _block_out
	_block = want if _block == 0.0 else lerpf(_block, want, minf(1.0, delta * BLOCK_EASE))
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter(&"block_k", _block)
	mat.set_shader_parameter(&"max_block", _block)
	mat.set_shader_parameter(&"min_block", minf(_block, 2.0))
