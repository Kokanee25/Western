class_name GoldenFill
extends SpotLight3D
## A soft warm light on a front the low sun only rakes past, at golden hour only: the street
## painting lights its JAIL's front gold where the sun can't reach it in ours (an art direction
## choice, as the porches' end panels are, FacadeArt). Faded out as the sun climbs or sets, off at
## night; no shadows, no specular glints, nothing in the haze. Its energy follows DayCycle's sun a
## few times a second (no clock of its own).

@export var peak_energy := 1.2

var _day: DayCycle
var _wait := 0.0


func _ready() -> void:
	light_color = Color(1.0, 0.74, 0.46)
	shadow_enabled = false
	light_specular = 0.0
	light_volumetric_fog_energy = 0.0
	_day = get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	_update()


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = 0.25
		_update()


func _update() -> void:
	if _day == null:
		light_energy = 0.0
		return
	var y := _day.get_sun_direction().y
	var golden := smoothstep(-0.02, 0.06, y) * (1.0 - smoothstep(0.18, 0.45, y))
	light_energy = peak_energy * golden
	visible = light_energy > 0.001
