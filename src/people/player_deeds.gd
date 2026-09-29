class_name PlayerDeeds
extends Node
## What the player does with a gun and his body that other people judge him by, sent as deeds:
## drawing and holstering, pointing a gun at someone (the aim line on him), shouting "Drop it!" at
## the man he's covering, standing too close, staring someone in the face. Whether anyone notices
## is up to them (their Senses). Child of the Player.

const EVERY := 0.25
## Aimed "at" someone: the line of the gun within this of his chest, this far.
const AIM_DEGREES := 6.0
const AIM_RANGE := 45.0
const CROWD := 1.3
const STARE_DEGREES := 5.0
const STARE_RANGE := 6.0

var player: Player
var _t := 0.0
var _was_drawn := false


func _ready() -> void:
	player = get_parent() as Player
	Events.shouted.connect(_on_shouted)


func _physics_process(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or player == null:
		return
	_t = EVERY
	var w := player.weapon
	var drawn := w != null and w.selected and w.drawn and w.is_ready_in_hand()
	if drawn != _was_drawn:
		_was_drawn = drawn
		Events.deed.emit(player, &"draw" if drawn else &"holster", null, player.global_position)
	var cam := player.camera
	var from := cam.global_position
	var fwd := -cam.global_transform.basis.z
	for p: Node in get_tree().get_nodes_in_group(&"people"):
		var h := p as HumanBody
		if h == null or h.limp and not h.physiology.alive:
			continue
		var chest := (h.parts[&"chest"] as Node3D).global_position if h.parts.has(&"chest") else h.global_position + Vector3.UP * 1.2
		var head := (h.parts[&"head"] as Node3D).global_position if h.parts.has(&"head") else chest + Vector3.UP * 0.4
		var d := from.distance_to(chest)
		var aimed := false
		if drawn and d < AIM_RANGE and rad_to_deg(fwd.angle_to(chest - from)) < AIM_DEGREES + 20.0 / maxf(d, 1.0):
			if _clear(from, chest):
				Events.deed.emit(player, &"aim_at", h, from)
				aimed = true
		if player.global_position.distance_to(h.global_position) < CROWD:
			Events.deed.emit(player, &"crowd", h, player.global_position)
		if not aimed and d < STARE_RANGE and rad_to_deg(fwd.angle_to(head - from)) < STARE_DEGREES:
			Events.deed.emit(player, &"stare", h, from)


func _clear(from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
	q.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## "Drop it!" is a deed against whoever you're covering (or anyone in front of you); calling a man
## out (with your gun in its holster) is against the one you're facing.
func _on_shouted(speaker: Node, kind: StringName) -> void:
	if speaker != player:
		return
	var cam := player.camera
	var fwd := -cam.global_transform.basis.z
	var best: HumanBody = null
	var best_ang := 20.0
	for p: Node in get_tree().get_nodes_in_group(&"people"):
		var h := p as HumanBody
		if h and h.global_position.distance_to(player.global_position) < 30.0:
			var to := h.global_position + Vector3.UP * 1.2 - cam.global_position
			var ang := rad_to_deg(fwd.angle_to(to))
			if kind != &"call_out" and ang < 25.0:
				Events.deed.emit(player, &"shout", h, cam.global_position)
			elif kind == &"call_out" and ang < best_ang and h.has_gun and h.physiology.is_conscious():
				best = h
				best_ang = ang
	if best:
		Events.deed.emit(player, &"call_out", best, cam.global_position)
