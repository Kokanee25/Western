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
## Seconds of ringing ears left, and how hard the view is shaking (from a blast).
var ringing := 0.0
var shake := 0.0
var _ear_filter: AudioEffectLowPassFilter
var _ring: AudioStreamPlayer


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
	Events.scorched.connect(_on_scorched)


func _on_scorched(who: Node, amount: float) -> void:
	if who != player:
		return
	physiology.burn(amount)
	_flash = maxf(_flash, 0.5)
	if _message_time <= 0.0:
		say("You're burning!", 1.5)


## Subtitles for anyone talking within earshot.
func _on_spoke(speaker: Node, text: String) -> void:
	if speaker is Node3D and (speaker as Node3D).global_position.distance_to(player.global_position) < 45.0:
		var who := String((speaker as HumanBody).person_id).capitalize() if speaker is HumanBody else "Someone"
		say("%s: \"%s\"" % [who, text], 3.0)


func say(text: String, seconds := 3.0) -> void:
	_message.text = text
	_message_time = seconds


## Ballistics reached the player's capsule. Traces the rest of the path through the body inside.
func take_bullet(_collider: Node3D, pos: Vector3, dir: Vector3, energy: float, bullet_radius: float, _mass := 0.0165, _travelled := 99.0, _blast := -1.0, _projectile := &"") -> Dictionary:
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


## Flying glass: a shallow slice where it hits (see HumanBody.take_cut).
func take_cut(_collider: Node3D, pos: Vector3, dir: Vector3, depth: float, embedded := false) -> Dictionary:
	var seg := _segment_at(pos)
	var xf := player.global_transform
	var squash := player.tuning.crouch_height / player.tuning.stand_height if player.is_crouching else 1.0
	var o := xf.affine_inverse() * pos
	o.y /= squash
	var d := (xf.affine_inverse().basis * dir).normalized()
	var tr := anatomy.trace(seg, o - d * 0.3, d, depth * 100.0 * anatomy.flesh_resistance, 0.002, _rng)
	tr.cut = true
	physiology.apply_trace(tr)
	wounds.append({"segments": [seg], "lodged": embedded, "hits": [], "kind": &"cut"})
	_flash = maxf(_flash, 0.4)
	say("Glass cut your %s%s." % [_place(seg), ", and a shard's still in it" if embedded else ""], 2.5)
	Events.body_hit.emit({"person": player, "person_id": &"player", "segment": seg, "hits": [], "position": pos,
			"direction": dir, "exit": null, "lodged": embedded, "kind": &"cut"})
	return {}


## Something heavy fell on you.
func take_blow(_collider: Node3D, joules: float, point: Vector3, dir := Vector3.DOWN) -> PackedStringArray:
	var seg := _segment_at(point)
	var harm := physiology.blow(seg, joules, _rng)
	_flash = 1.0
	player.add_look(Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-6.0, 2.0)))
	say("Something heavy caught your %s: %s." % [_place(seg), ", ".join(harm)], 3.0)
	Events.body_hit.emit({"person": player, "person_id": &"player", "segment": seg, "hits": [], "position": point,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blow", "harm": harm, "joules": joules})
	return harm


## Caught by a charge going off at `at` (`held`: it went off in your own right hand). The same
## rules as anyone: ears, lungs, head, burns, a hand or more torn off; and you hear nothing but
## ringing for a while (for good, muffled, if an eardrum went).
func take_blast(at: Vector3, kg: float, held := false) -> Dictionary:
	var bt := Blast.t()
	var xf := player.global_transform
	var squash := player.tuning.crouch_height / player.tuning.stand_height if player.is_crouching else 1.0
	var kpa := {}
	var chest := xf * Vector3(0, 1.3 * squash, 0)
	var head := player.camera.global_position
	var shield := 1.0 if held else Blast.shielding(player.get_parent() as Node3D, at, chest, [player.get_rid()])
	for sid: StringName in anatomy.segments:
		if physiology.severed_segments.has(sid):
			continue
		var c := anatomy.segment_center(sid)
		c.y *= squash
		var d := (xf * c).distance_to(at) - float(anatomy.segments[sid].radius)
		if held:
			# The stick in your right hand, out in front of you.
			d = {&"hand_r": 0.03, &"forearm_r": 0.18, &"upper_arm_r": 0.42, &"head": 0.5, &"neck": 0.5,
					&"chest": 0.45}.get(sid, maxf(d, 0.6))
		kpa[sid] = Blast.overpressure_kpa(kg, maxf(d, 0.02)) * shield
	var ear_kpa: float = kpa.get(&"head", Blast.overpressure_kpa(kg, head.distance_to(at)) * shield)
	var harm := physiology.blast_injury(ear_kpa, kpa.get(&"chest", 0.0), ear_kpa, bt, _rng)
	if chest.distance_to(at) < Blast.fireball_radius(kg) or held:
		physiology.burn(bt.burn_in_fireball)
		harm.append("burnt")
	for side in ["r", "l"]:
		for chain: Array in HumanBody.LIMBS:
			var take := &""
			for kind: String in chain:
				var sid := StringName(kind + "_" + side)
				if kpa.get(sid, 0.0) > float(bt.sever_kpa.get(kind, INF)):
					take = sid
			if take != &"":
				physiology.sever(take)
				harm.append("your %s is gone" % _place(take))
	ringing = clampf(maxf(ringing, ear_kpa * bt.ringing_per_kpa), 0.0, bt.ringing_max)
	var dir := (chest - at).normalized()
	var speed := minf(Blast.impulse(kg, maxf(chest.distance_to(at), 0.05)) * shield * 0.7 * bt.throw_factor / 80.0, bt.max_throw)
	player.velocity += (dir + Vector3.UP * 0.3).normalized() * speed * 1.5
	_flash = 1.0
	shake = maxf(shake, clampf(ear_kpa / 40.0, 0.2, 3.0))
	if not harm.is_empty():
		say("The blast: %s." % ", ".join(harm), 5.0)
	wounds.append({"segments": [&"chest"], "lodged": false, "hits": [], "kind": &"blast", "harm": harm})
	var info := {"person": player, "person_id": &"player", "segment": &"chest", "hits": [], "position": chest,
			"direction": dir, "exit": null, "lodged": false, "kind": &"blast", "harm": harm, "kpa": kpa.get(&"chest", 0.0)}
	Events.body_hit.emit(info)
	return info


## Ears: after a blast you hear the world through a pillow under a high whine, fading; a burst
## eardrum keeps it muffled for good (until the doctor, one day).
func _update_ears(delta: float) -> void:
	ringing = maxf(ringing - delta, 0.0)
	var muffle := clampf(ringing / 12.0, 0.0, 1.0)
	var deaf := physiology.deaf_ears() * 0.3
	var cutoff := lerpf(20000.0, 500.0, maxf(muffle, deaf))
	if _ear_filter == null:
		var master := AudioServer.get_bus_index(&"Master")
		for i in AudioServer.get_bus_effect_count(master):
			if AudioServer.get_bus_effect(master, i) is AudioEffectLowPassFilter:
				_ear_filter = AudioServer.get_bus_effect(master, i)
		if _ear_filter == null:
			_ear_filter = AudioEffectLowPassFilter.new()
			AudioServer.add_bus_effect(master, _ear_filter, 0)
	_ear_filter.cutoff_hz = cutoff
	if _ring == null:
		_ring = AudioStreamPlayer.new()
		_ring.stream = SynthSounds.get_sound(&"ringing")
		add_child(_ring)
	if ringing > 0.05:
		_ring.volume_db = linear_to_db(clampf(ringing / 20.0, 0.02, 0.5))
		if not _ring.playing:
			_ring.play()
	elif _ring.playing:
		_ring.stop()


## Which part of you is at a world point (standing, or crouched and squashed down).
func _segment_at(point: Vector3) -> StringName:
	var xf := player.global_transform
	var squash := player.tuning.crouch_height / player.tuning.stand_height if player.is_crouching else 1.0
	var p := xf.affine_inverse() * point
	p.y /= squash
	var best := &"chest"
	var best_d := INF
	for sid: StringName in anatomy.segments:
		for c: Array in anatomy.segments[sid].capsules:
			var a: Vector3 = c[0]
			var ab: Vector3 = (c[1] as Vector3) - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			var dist := p.distance_to(a + ab * t) - float(c[2])
			if dist < best_d:
				best_d = dist
				best = sid
	return best


func _place(seg: StringName) -> String:
	return String(seg).replace("_r", "").replace("_l", "").replace("_", " ")


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
		var w := player.weapon
		if w != null and w.selected and w.drawn:
			say("\"Drop it! Hands where I can see 'em!\"", 2.5)
			Events.shouted.emit(player, &"drop_it")
		else:
			# Gun in its holster: calling the man you're facing out.
			say("\"You! Step out here and face me!\"", 2.5)
			Events.shouted.emit(player, &"call_out")
	_tend(delta)
	_update_ears(delta)
	if shake > 0.0:
		player.add_look(Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * shake)
		shake = maxf(shake - delta * 4.0, 0.0)
	physiology.step(delta * scale)
	_drip(delta * scale)
	var p := physiology
	var legs := p.leg_ok("r") and p.leg_ok("l") and not p.legs_paralysed() and not p.broken.has(&"pelvis_bone")
	player.force_crouch = not legs or p.shock() > 0.85
	player.move_factor = (1.0 - p.shock() * 0.5) * (lerpf(0.45, 1.0, p.leg_strength()) if legs else 0.35)
	player.can_sprint = p.can_run()
	player.can_jump = legs and p.shock() < 0.5
	for gun in player.weapons:
		gun.hands_busy = tending > 0.0
		# The shotgun takes both hands; the revolver only the right.
		gun.arm_disabled = not p.can_hold("r") or (gun is ShotgunViewmodel and not p.can_hold("l"))
		var steadiness := p.arm_steadiness("r") if gun is RevolverViewmodel else minf(p.arm_steadiness("r"), p.arm_steadiness("l"))
		gun.extra_spread = p.felt_pain() * 1.5 + p.shock() * 3.0 + (1.0 - steadiness) * 4.0
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
		if not b.tourniquet and not b.get(&"bandaged", false) and b.get("kind", &"ooze") != &"internal" and (worst.is_empty() or physiology.bleed_rate(b) > physiology.bleed_rate(worst)):
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
