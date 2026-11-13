class_name StoveFire
extends Node3D
## A kit prop's firebox (its kit file's "stove", #866: the saloon's box stove): lit by the hour as the
## lamps are (`lit_from`..`lit_until`), it glows at its draught (a small light, no shadow); knocked
## over (the prop goes loose: a blast, a man thrown into it, its sand box burnt out from under it)
## while it's lit, its coals spill round its door and burn on what's there (FireSystem.small_fire:
## `radius`, `seconds`, `heating` times a spill's heat), the room's fire source. Made by KitProp for a
## file with "stove"; idle (no process) until it spills.
##
## "stove": {"member": the firebox's member id, "door": [x, y, z] where the coals come out, "glow_at",
## "radius", "seconds", "heating", "lit_from", "lit_until", "glow" (the light's energy)}.

## The coals land a moment after it starts over (it's falling), where its door is then.
const SPILL_AFTER := 0.6

var spec: Dictionary
var lit := false
var spilled := false
var coals: Dictionary = {}
var _prop: Node3D
var _glow: OmniLight3D


func _ready() -> void:
	_prop = get_parent() as Node3D
	spec = (_prop.get(&"definition") as Dictionary).get("stove", {})
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = Color(1.0, 0.45, 0.16)
	_glow.omni_range = 2.2
	_glow.shadow_enabled = false
	_glow.position = PropKit.vec(spec.get("glow_at", [0.0, 0.4, 0.0]))
	add_child(_glow)
	if _prop.has_signal(&"went_loose"):
		_prop.connect(&"went_loose", _on_loose)
	Events.hour_changed.connect(_on_hour)
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	set_lit(true if clock == null else should_be_lit(clock.get_hour()))


func should_be_lit(hour: int) -> bool:
	var a := int(spec.get("lit_from", 17))
	var b := int(spec.get("lit_until", 7))
	if a > b:
		return hour >= a or hour < b
	return hour >= a and hour < b


func set_lit(on: bool) -> void:
	lit = on and not spilled
	if _glow:
		_glow.visible = lit
		_glow.light_energy = float(spec.get("glow", 0.7)) if lit else 0.0


func _on_hour(hour: int) -> void:
	if not spilled:
		set_lit(should_be_lit(hour))


## Where its coals come out now (world): its door's place on its firebox, wherever the firebox is.
func door_now() -> Vector3:
	var door := PropKit.vec(spec.get("door", [0.0, 0.2, 0.0]))
	var m: Node3D = null
	if _prop.has_method(&"get_member"):
		m = _prop.call(&"get_member", StringName("%s/%s" % [_prop.get(&"structure_id"), spec.get("member", "body")])) as Node3D
	if m and is_instance_valid(m) and m.is_inside_tree():
		var at := PropKit.vec(_member_at(String(spec.get("member", "body"))))
		return m.global_transform * (door - at)
	return _prop.global_transform * door


func _member_at(id: String) -> Array:
	for s: Dictionary in PropKit.expand(_prop.get(&"definition")):
		if String(s.id) == id:
			return s.at
	return [0.0, 0.0, 0.0]


func _on_loose() -> void:
	if spilled or not lit:
		return
	spilled = true
	await get_tree().create_timer(SPILL_AFTER, false, true).timeout
	spill()


## Its coals out on the floor by its door, burning (FireSystem.small_fire); its glow out.
func spill() -> void:
	spilled = true
	set_lit(false)
	var fire := FireSystem.find(get_tree())
	if fire == null or not is_inside_tree():
		return
	var at := door_now()
	# On what's under the door (the boards), not in the air where the door is.
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at + Vector3.DOWN * 2.0, Layers.WORLD)
	var hit := World.space(self).intersect_ray(q)
	if not hit.is_empty():
		at = hit.position + Vector3.UP * 0.02
	coals = fire.small_fire(at, float(spec.get("radius", 0.45)), float(spec.get("seconds", 300.0)), float(spec.get("heating", 1.4)))
