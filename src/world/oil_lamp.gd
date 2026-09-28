class_name OilLamp
extends Node3D
## A kerosene lamp: warm light with a lazy flicker, lit in the evening and put out in the morning.
## Placeholder mesh until real props.

@export var lit_from_hour := 18
@export var lit_until_hour := 7
@export var energy := 1.4
@export var light_range := 7.0
@export var hanging := false

var lit := true

var _light: OmniLight3D
var _flame: MeshInstance3D
var _flame_material: StandardMaterial3D
var _time := 0.0


func _ready() -> void:
	_build()
	Events.hour_changed.connect(_on_hour_changed)
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	set_lit(true if clock == null else should_be_lit(clock.get_hour()))


func should_be_lit(hour: int) -> bool:
	if lit_from_hour > lit_until_hour:
		return hour >= lit_from_hour or hour < lit_until_hour
	return hour >= lit_from_hour and hour < lit_until_hour


func set_lit(on: bool) -> void:
	lit = on
	_light.visible = on
	_flame_material.emission_enabled = on
	_flame_material.albedo_color = Color(1.0, 0.75, 0.4, 0.8) if on else Color(0.5, 0.55, 0.55, 0.4)


func _process(delta: float) -> void:
	if not lit:
		return
	_time += delta
	var flicker := 1.0 + sin(_time * 7.3) * 0.04 + sin(_time * 13.1 + 1.7) * 0.03
	_light.light_energy = energy * flicker


func _on_hour_changed(hour: int) -> void:
	set_lit(should_be_lit(hour))


func _build() -> void:
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.2, 0.18, 0.16)
	metal.metallic = 0.5
	metal.roughness = 0.6
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.05
	base_mesh.bottom_radius = 0.07
	base_mesh.height = 0.08
	base_mesh.radial_segments = 10
	base.mesh = base_mesh
	base.material_override = metal
	base.position.y = 0.04
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(base)

	_flame_material = StandardMaterial3D.new()
	_flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_material.emission = Color(1.0, 0.6, 0.25)
	_flame_material.emission_energy_multiplier = 4.0
	_flame = MeshInstance3D.new()
	var glass := CylinderMesh.new()
	glass.top_radius = 0.035
	glass.bottom_radius = 0.045
	glass.height = 0.14
	glass.radial_segments = 10
	_flame.mesh = glass
	_flame.material_override = _flame_material
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.position.y = 0.15
	add_child(_flame)

	if hanging:
		var bail := MeshInstance3D.new()
		var bail_mesh := BoxMesh.new()
		bail_mesh.size = Vector3(0.01, 0.2, 0.01)
		bail.mesh = bail_mesh
		bail.material_override = metal
		bail.position.y = 0.32
		add_child(bail)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.62, 0.3)
	_light.light_energy = energy
	_light.omni_range = light_range
	_light.omni_attenuation = 1.2
	_light.shadow_enabled = true
	_light.shadow_bias = 0.05
	_light.position.y = 0.16
	add_child(_light)
