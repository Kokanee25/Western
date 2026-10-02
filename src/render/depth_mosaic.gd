class_name DepthMosaic
extends MeshInstance3D
## A trial of keeping far squares chunky in screen space (depth_mosaic.gdshader): a full-screen
## quad a camera carries. `DepthMosaic.attach(camera, min_px)` adds one.

const SHADER := preload("res://src/render/depth_mosaic.gdshader")


static func attach(camera: Camera3D, min_px: float) -> DepthMosaic:
	var m := camera.get_node_or_null(^"DepthMosaic") as DepthMosaic
	if m == null:
		m = DepthMosaic.new()
		m.name = "DepthMosaic"
		camera.add_child(m)
	(m.material_override as ShaderMaterial).set_shader_parameter(&"min_px", min_px)
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


func _process(_delta: float) -> void:
	var cam := get_parent() as Camera3D
	if cam == null:
		return
	var h := float(cam.get_viewport().get_visible_rect().size.y)
	(material_override as ShaderMaterial).set_shader_parameter(&"focal", h * 0.5 / tan(deg_to_rad(cam.fov * 0.5)))
