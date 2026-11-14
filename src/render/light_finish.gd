class_name LightFinish
extends MeshInstance3D
## The light pass's finish (issue #318): vignette, film grain and heat shimmer
## (light_finish.gdshader), a full-screen quad the game camera carries, as DepthMosaic is. Its dials
## are LookPreset's `finish.<dial>` (the light looks set them, config/looks/light_*.json); with
## all of vignette, grain and shimmer at 0 the camera carries none (nothing drawn, nothing paid).

const SHADER := preload("res://src/render/light_finish.gdshader")

const DEFAULTS := {
	"vignette": 0.0,
	"vignette_from": 0.45,
	"grain": 0.0,
	"grain_fps": 24.0,
	"shimmer": 0.0,
	"shimmer_from": 40.0,
	"shimmer_full": 160.0,
	"shimmer_top": 0.35,
}

static var dials := DEFAULTS.duplicate()


static func set_dial(tree: SceneTree, name: String, value: Variant) -> bool:
	if not DEFAULTS.has(name):
		return false
	dials[name] = float(value)
	apply(tree)
	return true


static func active() -> bool:
	return dials.vignette > 0.0 or dials.grain > 0.0 or dials.shimmer > 0.0


## The player's camera gets one (or loses it) by the dials.
static func apply(tree: SceneTree) -> void:
	var player := tree.get_first_node_in_group(&"player") if tree else null
	var cam: Camera3D = player.get(&"camera") if player else null
	if cam == null:
		return
	var f := cam.get_node_or_null(^"LightFinish") as LightFinish
	if not active():
		if f:
			f.queue_free()
		return
	if f == null:
		f = LightFinish.new()
		f.name = "LightFinish"
		cam.add_child(f)
	f.retune()


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


func retune() -> void:
	var mat := material_override as ShaderMaterial
	for k: String in dials:
		mat.set_shader_parameter(StringName(k), dials[k])


## The shimmer is the day's: none at night, all of it with the sun high.
func _process(_delta: float) -> void:
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock:
		var y := clock.get_sun_direction().y
		(material_override as ShaderMaterial).set_shader_parameter(&"day", smoothstep(0.3, 0.8, y))
