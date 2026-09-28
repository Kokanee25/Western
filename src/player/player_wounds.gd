class_name PlayerWounds
extends Node
## The player's own hidden anatomy and physiology: bullets that reach the player's capsule are
## traced through a standing (or crouched) body, and the wounds act on you: red flash and a kick
## when hit, the edges greying with blood loss, no running with a holed lung, down on the ground
## with a broken leg, the gun gone from a broken arm, blackout. Hold B (D-pad down) to press on your
## wounds; keep holding and you cinch a belt round a bleeding limb. Knocked out, you come round
## later (at the doctor's once there is one; for now back in the store).
## Sits under the Player; registers itself as the thing bullets hit (meta "human_body").

signal knocked_out

const OVERLAY_SHADER := preload("res://src/player/wound_overlay.gdshader")
const CLOTHES_RESISTANCE := 3.0
const TEND_TOURNIQUET_SECONDS := 4.0

var physiology: Physiology
var anatomy: Anatomy
var player: Player
## {segments: [...], lodged, hits: [{id, effect}]}
var wounds: Array[Dictionary] = []
var tending := 0.0
var out_cold := 0.0

var _rng := RandomNumberGenerator.new()
var _flash := 0.0
var _drip_ml := 0.0
var _overlay: ColorRect
var _message: Label
var _message_time := 0.0
var _day_cycle: Node


func _ready() -> void:
	player = get_parent() as Player
	player.set_meta(&"human_body", self)
	_rng.seed = 1882
	anatomy = Anatomy.shared()
	physiology = Physiology.new(null, anatomy)
	var layer := CanvasLayer.new()
	layer.name = "WoundOverlay"
	layer.layer = 4
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = OVERLAY_SHADER
	_overlay.material = mat
	layer.add_child(_overlay)
	_message = Label.new()
	_message.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_message.position.y -= 60
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.add_theme_color_override(&"font_color", Color(0.95, 0.9, 0.8))
	_message.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_message.add_theme_constant_override(&"outline_size", 4)
	layer.add_child(_message)
	Events.spoke.connect(_on_spoke)


## Subtitles for anyone talking within earshot.
func _on_spoke(speaker: Node, text: String) -> void:
	if speaker is Node3D and (speaker as Node3D).global_position.distance_to(player.global_position) < 45.0:
		var who := String((speaker as HumanBody).person_id).capitalize() if speaker is HumanBody else "Someone"
		say("%s: \"%s\"" % [who, text], 3.0)


func say(text: String, seconds := 3.0) -> void:
	_message.text = text
	_message_time = seconds


## Ballistics reached the player's capsule. Traces the rest of the path through the body inside.
func take_bullet(_collider: Node3D, pos: Vector3, dir: Vector3, energy: float, bullet_radius: float, _mass := 0.0165) -> Dictionary:
	var xf := player.global_transform
	var inv := xf.affine_inverse()
	# Crouched, the body is squashed into the shorter capsule: stretch back to standing.
	var squash := player.tuning.crouch_height / player.tuning.stand_height if player.is_crouching else 1.0
	var o := inv * pos
	var d := inv.basis * dir
	o.y /= squash
	d.y /= squash
	d = d.normalized()
	o -= d * 0.6
	var res := anatomy.trace_through(o, d, maxf(energy - CLOTHES_RESISTANCE, 0.0), bullet_radius, _rng)
	if res.traces.is_empty():
		return {"segment": &"", "exit": null, "energy_out": energy}
	var hits: Array = []
	var segs: Array = []
	for tr: Dictionary in res.traces:
		physiology.apply_trace(tr)
		segs.append(tr.segment)
		for h: Dictionary in tr.hits:
			hits.append({"id": h.id, "effect": h.effect})
	wounds.append({"segments": segs, "lodged": res.exit == null, "hits": hits})
	_flash = 1.0
	player.add_look(Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-2.0, 5.0)))
	var exit_world: Variant = null
	if res.exit != null:
		var e: Vector3 = res.exit
		e.y *= squash
		exit_world = xf * e
	var first: Dictionary = res.traces[0]
	var entry_local: Vector3 = first.entry
	entry_local.y *= squash
	var info := {"person": player, "person_id": &"player", "segment": first.segment, "hits": hits,
			"position": xf * entry_local, "direction": dir, "exit": exit_world, "lodged": res.exit == null}
	Events.body_hit.emit(info)
	say(_hit_words(segs, hits), 3.5)
	return {"segment": first.segment, "exit": exit_world, "energy_out": res.energy_out, "hits": hits}


func _hit_words(segs: Array, hits: Array) -> String:
	var where := String(segs[0]).replace("_r", "").replace("_l", "").replace("_", " ")
	for h: Dictionary in hits:
		if h.effect == &"broken":
			return "Hit in the %s. Something broke." % where
		if h.effect == &"cut":
			return "Hit in the %s. It's pumping." % where
		if h.effect == &"severed":
			return "Your %s finger's gone." % String(h.id).get_slice("_", 0)
	return "Hit in the %s." % where


func _physics_process(delta: float) -> void:
	if _day_cycle == null and is_inside_tree():
		_day_cycle = get_tree().get_first_node_in_group(&"day_cycle")
	var scale: float = _day_cycle.time_scale if _day_cycle != null else 1.0
	if player.input_enabled and Input.is_action_just_pressed(&"shout") and physiology.can_speak():
		say("\"Drop it! Hands where I can see 'em!\"", 2.5)
		Events.shouted.emit(player, &"drop_it")
	_tend(delta)
	physiology.step(delta * scale)
	_drip(delta * scale)
	var gun := player.get_node_or_null(^"Head/Camera3D/Gun") as RevolverViewmodel
	var p := physiology
	var legs := p.leg_ok("r") and p.leg_ok("l") and not p.legs_paralysed() and not p.broken.has(&"pelvis_bone")
	player.force_crouch = not legs or p.shock() > 0.85
	player.move_factor = (1.0 - p.shock() * 0.5) * (lerpf(0.45, 1.0, p.leg_strength()) if legs else 0.35)
	player.can_sprint = p.can_run()
	player.can_jump = legs and p.shock() < 0.5
	if gun:
		gun.hands_busy = tending > 0.0
		gun.arm_disabled = not p.can_hold("r")
		gun.extra_spread = p.felt_pain() * 1.5 + p.shock() * 3.0 + (1.0 - p.arm_steadiness("r")) * 4.0
	if not p.is_conscious():
		out_cold += delta
		if out_cold > 4.0:
			_come_round()
	else:
		out_cold = 0.0
	_flash = maxf(_flash - delta * 2.5, 0.0)
	var mat := _overlay.material as ShaderMaterial
	mat.set_shader_parameter(&"flash", _flash)
	mat.set_shader_parameter(&"shock", p.shock())
	mat.set_shader_parameter(&"pain", clampf(p.felt_pain(), 0.0, 1.0))
	mat.set_shader_parameter(&"black", clampf(out_cold / 1.5, 0.0, 1.0) if out_cold > 0.0 else clampf((p.shock() - 0.8) * 2.0, 0.0, 0.6))
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message.text = ""


## You leave a trail: drops of your blood on the ground where you go.
func _drip(dt: float) -> void:
	_drip_ml += physiology.total_bleed_rate() * dt
	if _drip_ml < 4.0 or not player.is_inside_tree():
		return
	var exclude: Array[RID] = [player.get_rid()]
	var from := player.global_position + Vector3(_rng.randf_range(-0.2, 0.2), 0.9, _rng.randf_range(-0.2, 0.2))
	Blood.throw(player.get_parent() as Node3D, from, Vector3.DOWN * 0.5, _drip_ml, exclude)
	_drip_ml = 0.0


## Hold the tend button: press on the worst bleeding; hold on and a belt goes round a limb.
func _tend(delta: float) -> void:
	var held := player.input_enabled and Input.is_action_pressed(&"tend_wounds")
	if not held or physiology.bleeds.is_empty():
		if tending > 0.0:
			for b in physiology.bleeds:
				if not b.get(&"bandaged", false):
					b.pressure = false
		tending = 0.0
		return
	var worst: Dictionary = {}
	for b in physiology.bleeds:
		if not b.tourniquet and not b.get(&"bandaged", false) and (worst.is_empty() or physiology.bleed_rate(b) > physiology.bleed_rate(worst)):
			worst = b
	if worst.is_empty():
		if tending == 0.0:
			say("Nothing more you can do here.", 2.0)
		tending += delta
		return
	if tending == 0.0:
		say("Pressing on the wound...", 2.0)
	tending += delta
	physiology.apply_pressure(worst.segment)
	if tending >= TEND_TOURNIQUET_SECONDS:
		var seg: StringName = worst.segment
		var limb := String(seg).contains("arm") or String(seg).contains("thigh") or String(seg).contains("shin") or String(seg).contains("hand") or String(seg).contains("foot")
		if limb and worst.rate > physiology.tuning.clot_max_rate:
			var top := _limb_top(seg)
			physiology.apply_tourniquet(top)
			say("Belt cinched tight above the wound.", 3.0)
		else:
			for b in physiology.bleeds:
				if b.segment == seg:
					b.bandaged = true
					b.pressure = true
			say("Packed and bound it with your bandana.", 3.0)
		tending = 0.01


## A tourniquet goes high on the limb: the thigh or the upper arm.
func _limb_top(seg: StringName) -> StringName:
	var s := String(seg)
	var side := s.right(1)
	if s.begins_with("forearm") or s.begins_with("hand") or s.begins_with("upper_arm"):
		return StringName("upper_arm_" + side)
	return StringName("thigh_" + side)


## Out cold: for now you come round in the store, patched up. (The doctor arrives in M5.)
func _come_round() -> void:
	knocked_out.emit()
	physiology = Physiology.new(null, anatomy)
	wounds.clear()
	out_cold = 0.0
	var marker := get_tree().current_scene.find_child("StoreInside", true, false) if get_tree().current_scene else null
	if marker == null:
		marker = get_tree().root.find_child("StoreInside", true, false)
	if marker is Node3D:
		player.global_position = (marker as Node3D).global_position
		player.velocity = Vector3.ZERO
	say("You come round on the store floor, bandaged. (The doctor comes later.)", 5.0)


func describe() -> String:
	return "You: blood %d%%, bleeding %.1f ml/s, pain %.2f, adrenaline %.2f, breath %.2f. %s" % [
			roundi((1.0 - physiology.blood_loss()) * 100.0), physiology.total_bleed_rate(),
			physiology.felt_pain(), physiology.adrenaline, physiology.breath_capacity(), physiology.describe()]
