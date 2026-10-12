extends MeshInstance3D
## The painterly trial (the characters session, Sean: "Let's try painterly", 2026-10-12; off
## everywhere): the finished frame given a warm filmic grade and, if asked, a light brush (a small
## Kuwahara filter: flat dabs with sharp edges, the look of paint, not squares). One pass over the
## whole frame. tools/screenshots.gd takes --grade[=name:value,...] (this shader's uniforms).
##   load("res://experiments/painterly/grade.gd").attach(camera, {"brush_px": 2.0})

const SHADER := "res://experiments/painterly/grade.gdshader"


static func attach(camera: Camera3D, values := {}) -> MeshInstance3D:
	var existing := camera.get_node_or_null(^"PainterlyGrade") as MeshInstance3D
	if existing == null:
		existing = load("res://experiments/painterly/grade.gd").new()
		existing.name = "PainterlyGrade"
		camera.add_child(existing)
	var m := existing.material_override as ShaderMaterial
	for k: String in values:
		m.set_shader_parameter(StringName(k), values[k])
	return existing


func _init() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	mesh = quad
	var m := ShaderMaterial.new()
	m.shader = load(SHADER)
	material_override = m
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sorting_offset = -1000.0
