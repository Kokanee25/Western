class_name DepthMosaic
extends MeshInstance3D
## The painting's mosaic in screen space (depth_mosaic.gdshader): the lit frame in blocks that
## shrink with distance, one colour each, the light in steps. A full-screen quad a camera carries:
## `DepthMosaic.attach(camera, block_k, steps)` adds or retunes one (block_k: block pixels × metres,
## ~5 for the saloon painting at 1280 wide; steps: tones of light, 0 = smooth).

const SHADER := preload("res://src/render/depth_mosaic.gdshader")

## Extra shader knobs laid on every mosaic attached (the quantise-once trial: depth_power, soft,
## sat_steps, hue_steps, min_block, max_block). Empty = the shader's defaults, the game's look.
static var tuning := {}


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
	for k: String in tuning:
		mat.set_shader_parameter(StringName(k), tuning[k])
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
