class_name OilLamp
extends Node3D
## A kerosene lamp: warm light with a lazy flicker, lit in the evening and put out in the morning.
## Its model is PropModels.lamp().

@export var lit_from_hour := 18
@export var lit_until_hour := 7
@export var energy := 1.4
@export var light_range := 7.0
@export var hanging := false
## Off when a modelled lamp prop provides the look and this node only provides the light.
@export var show_mesh := true
## How much its light shows in the air (smoke, haze): the halo round a lamp in a smoky room.
@export var haze := 1.2

var lit := true
## Shot or knocked to pieces: no light, and if it was lit, burning oil where it landed.
var broken := false

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
	# The lamp itself (PropModels.lamp: brass foot and font on the texel grid, a glass chimney);
	# the flame burns inside the chimney.
	var metal := PropModels.brass()
	var model := Node3D.new()
	model.name = "Model"
	PropModels.lamp(model)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(model)
	_flame_material = StandardMaterial3D.new()
	_flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame_material.emission = Color(1.0, 0.68, 0.3)
	_flame_material.emission_energy_multiplier = 5.0
	_flame = MeshInstance3D.new()
	var tongue := CylinderMesh.new()
	tongue.top_radius = 0.002
	tongue.bottom_radius = 0.011
	tongue.height = 0.045
	tongue.radial_segments = 6
	_flame.mesh = tongue
	_flame.material_override = _flame_material
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.position.y = 0.205
	add_child(_flame)

	if hanging:
		var bail := MeshInstance3D.new()
		var bail_mesh := BoxMesh.new()
		bail_mesh.size = Vector3(0.01, 0.2, 0.01)
		bail.mesh = bail_mesh
		bail.material_override = metal
		bail.position.y = 0.47
		add_child(bail)

	if not show_mesh:
		model.visible = false
		_flame.visible = false
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.74, 0.48)
	_light.light_volumetric_fog_energy = haze
	_light.light_energy = energy
	_light.omni_range = light_range
	_light.omni_attenuation = 1.2
	_light.shadow_enabled = true
	_light.shadow_bias = 0.05
	_light.position.y = 0.22
	add_child(_light)
	# Something for a bullet to hit.
	var hitbox := StaticBody3D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = Layers.WORLD
	hitbox.collision_mask = 0
	hitbox.set_meta(&"oil_lamp", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.14, 0.38, 0.14)
	shape.shape = box
	shape.position.y = 0.19
	hitbox.add_child(shape)
	add_child(hitbox)


## A bullet (or a fall) breaks it: glass everywhere, and a lit lamp throws its burning oil down
## on whatever's below.
func smash(direction := Vector3.DOWN) -> void:
	if broken:
		return
	broken = true
	var was_lit := lit
	set_lit(false)
	for c in get_children():
		if c is MeshInstance3D or c.name == &"Model":
			(c as Node3D).visible = false
	var hitbox := get_node_or_null(^"Hitbox") as StaticBody3D
	var snd := AudioStreamPlayer3D.new()
	snd.stream = SynthSounds.get_sound(&"glass")
	snd.unit_size = 5.0
	add_child(snd)
	snd.play()
	ImpactEffects.burst(get_parent(), global_position + Vector3.UP * 0.12, -direction, Color(0.8, 0.85, 0.8), 10, 1.5, 0.02)
	if not was_lit:
		return
	# Where the oil lands: straight down from the lamp, onto the counter, the floor, the boardwalk.
	var at := global_position
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.05, global_position + Vector3.DOWN * 4.0, Layers.WORLD)
	if hitbox:
		q.exclude = [hitbox.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():
		at = hit.position
	if hitbox:
		hitbox.queue_free()
	var fire := FireSystem.find(get_tree())
	if fire:
		fire.spill(at)
