class_name PlayerComposure
extends Node
## How steady your hands are. Running leaves you winded; a ball cracking past your ear, or
## smacking into the wall by your head, makes you flinch (the view jolts, the gun jerks, and for a
## moment your shot goes wide); rounds coming in one after another leave you rattled, and the gun
## wanders more until it's been quiet a while. The guns ask `sway_scale()` and `extra_spread()`.
## The same thing the outlaws feel when you keep their heads down. Child of the Player; numbers in
## config/player_tuning.tres ("Holding a gun", "Under fire").

var player: Player
## 0..1: a fresh flinch, fading over `flinch_seconds`.
var flinch := 0.0
## 0..1: how rattled by rounds coming in.
var rattled := 0.0
## 0..1: how winded from running.
var winded := 0.0
var _since_incoming := 99.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	player = get_parent() as Player
	_rng.seed = 71
	Events.near_miss.connect(_on_near_miss)
	Events.bullet_hit.connect(_on_bullet_hit)
	Events.body_hit.connect(func(info: Dictionary) -> void: if info.get("person") == player: incoming(1.0))


func _on_near_miss(person: Node, _shooter: Node, distance: float, _at: Vector3, _speed: float, _tumbling: bool) -> void:
	if person == player:
		incoming(1.0 - clampf(distance / 2.5, 0.0, 1.0) * 0.6)


## A round smacking into something near your head, coming your way (not your own going out).
func _on_bullet_hit(info: Dictionary) -> void:
	if player == null or info.has("person"):
		return
	var eye := player.camera.global_position
	var at: Vector3 = info.position
	var d := at.distance_to(eye)
	if d > player.tuning.rattle_reach or (info.direction as Vector3).dot(eye - at) <= 0.0:
		return
	incoming(0.8 * (1.0 - d / player.tuning.rattle_reach) + 0.2)


## Something came in at you (0..1, how close it was): flinch, and it adds up.
func incoming(strength: float) -> void:
	if player == null:
		return
	var t := player.tuning
	flinch = clampf(flinch + strength, 0.0, 1.0)
	rattled = clampf(rattled + t.rattle_per_round * strength, 0.0, 1.0)
	_since_incoming = 0.0
	player.add_look(Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-0.4, 1.0)) * t.flinch_jolt * strength)
	if player.weapon != null:
		player.weapon.jerk(t.flinch_jerk * strength, _rng)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var t := player.tuning
	flinch = move_toward(flinch, 0.0, delta / maxf(t.flinch_seconds, 0.01))
	_since_incoming += delta
	if _since_incoming > t.rattle_hold:
		rattled = move_toward(rattled, 0.0, delta / maxf(t.rattle_recovery, 0.01))
	if player.is_running:
		winded = move_toward(winded, 1.0, delta / maxf(t.winded_build, 0.01))
	else:
		winded = move_toward(winded, 0.0, delta / maxf(t.winded_recovery, 0.01))


## How many times as much the gun wanders now (winded, rattled).
func sway_scale() -> float:
	var t := player.tuning
	return lerpf(1.0, t.winded_sway, winded) * lerpf(1.0, t.rattled_sway, rattled)


## Extra spread while flinching (degrees).
func extra_spread() -> float:
	return flinch * player.tuning.flinch_spread


func describe() -> String:
	return "steady" if flinch < 0.05 and rattled < 0.05 and winded < 0.05 else \
			"flinch %.2f, rattled %.2f, winded %.2f" % [flinch, rattled, winded]
