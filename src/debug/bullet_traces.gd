extends MeshInstance3D
## F8: draws the paths of the last bullets fired (debug "hit traces"): where they went, where they
## went through things and where they stopped.

const KEEP := 24

var _paths: Array[PackedVector3Array] = []
var _mesh := ImmediateMesh.new()
var _hooked := false


func _ready() -> void:
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.25, 0.15)
	m.no_depth_test = true
	material_override = m
	visible = false


func _process(_delta: float) -> void:
	if not _hooked:
		var b := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
		if b:
			b.bullet_finished.connect(_on_finished)
			_hooked = true
	if Input.is_action_just_pressed(&"debug_traces"):
		visible = not visible


func _on_finished(bullet: Ballistics.Bullet) -> void:
	_paths.append(bullet.path)
	while _paths.size() > KEEP:
		_paths.pop_front()
	_mesh.clear_surfaces()
	for p in _paths:
		if p.size() < 2:
			continue
		_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for v in p:
			_mesh.surface_add_vertex(v)
		_mesh.surface_end()
