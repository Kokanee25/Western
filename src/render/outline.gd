class_name Outline
extends MeshInstance3D
## The concept painting's line work (outline.gdshader): a full-screen quad a camera carries, drawing
## a dark line round every form's silhouette and along hard creases. Forward+ only (it reads the
## normal buffer); on the Compatibility renderer it draws silhouettes from depth alone.
## `Outline.attach(camera)` adds one; `Settings.outlines` turns them on and off.

const SHADER := preload("res://src/render/outline.gdshader")


static func attach(camera: Camera3D) -> Outline:
	var existing := camera.get_node_or_null(^"Outline") as Outline
	if existing:
		return existing
	var o := Outline.new()
	o.name = "Outline"
	camera.add_child(o)
	return o


func _ready() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	mesh = quad
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"use_normals", RenderingServer.get_current_rendering_method() == "forward_plus")
	material_override = m
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Drawn after everything else that's see-through too, so lines sit on top of smoke and glass.
	sorting_offset = -1000.0
