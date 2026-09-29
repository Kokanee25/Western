extends SceneTree
func _initialize() -> void:
	_go.call_deferred()
func _go() -> void:
	var m := HumanBody.new()
	m.person_id = &"stranger"
	root.add_child(m)
	await process_frame
	var mi: MeshInstance3D = m.skin_meshes["head/head"]
	var mat = mi.material_override
	var tex: Texture2D = mat.get_shader_parameter(&"albedo_tex") if mat is ShaderMaterial else null
	for p in mat.get_property_list():
		pass
	print("PARAMS ", (mat as ShaderMaterial).shader.get_shader_uniform_list().map(func(u): return u.name))
	var img: Image
	for u in (mat as ShaderMaterial).shader.get_shader_uniform_list():
		var v = mat.get_shader_parameter(u.name)
		if v is Texture2D:
			print("TEX ", u.name, " ", v.get_size())
			img = v.get_image()
			img.resize(img.get_width() * 6, img.get_height() * 6, Image.INTERPOLATE_NEAREST)
			img.save_png("/tmp/claude-0/shots/face_tex_%s.png" % u.name)
	quit()
