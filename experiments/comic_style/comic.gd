extends MeshInstance3D
## The comic-book trial (the characters session, Sean: "do any art style you want", 2026-10-12;
## off everywhere): the finished frame drawn as a Western comic page, after Moebius's Blueberry:
## ink lines on every edge, flat colour in a few tones, ink hatching in the shade, fixed to the
## world so it doesn't crawl as you move. One pass for everything (men, buildings, fire, night),
## so nothing in the game has to be painted for it. Forward+ only (it reads the normal buffer).
##   load("res://experiments/comic_style/comic.gd").attach(camera, {"tones": 3.0})
## tools/screenshots.gd takes --comic[=name:value,...] (the shader's uniforms).

const SHADER := "res://experiments/comic_style/comic.gdshader"


static func attach(camera: Camera3D, values := {}) -> MeshInstance3D:
	var existing := camera.get_node_or_null(^"Comic") as MeshInstance3D
	if existing == null:
		existing = load("res://experiments/comic_style/comic.gd").new()
		existing.name = "Comic"
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
