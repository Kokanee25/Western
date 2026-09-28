class_name OutlawBrain
extends Node
## The test outlaw's mind, M2 edition: fear and nerve, not a health bar. He stands easy until
## someone shoots at him (a hit, or a ball cracking past), then turns and fights: cock, aim, fire,
## five rounds, a slow reload. Everything frightening adds fear — near misses, hits, pain, shock,
## losing his gun, being aimed at and told to drop it — and when fear passes his nerve he gives
## up: drops the gun, hands up. Most fights end when nerve breaks, not bodies.
## Child of a HumanBody.

signal mood_changed(mood: Mood)

enum Mood { CALM, FIGHTING, RELOADING, SURRENDERED, DOWN, DEAD }

const LINES := {
	&"provoked": ["You damn fool!", "Your funeral, friend.", "That's how it is? Fine!"],
	&"hit": ["Agh—!", "Son of a—!", "I'm hit, damn it!"],
	&"gut": ["Oh God, not the belly..."],
	&"surrender": ["Alright! Alright! I'm done!", "Don't shoot! I quit, I quit!", "Enough! It's yours!"],
	&"down": ["My leg... damn you...", "Can't... get up..."],
	&"shot_while_surrendered": ["I give up, you bastard!", "I'm unarmed!"],
	&"reloading": ["Hold still..."],
}

## How much fear he can carry before he breaks. A hired gun; a family man would be lower.
@export var nerve := 0.75
## Spread of his shots in degrees when calm and unhurt.
@export var spread_degrees := 2.4
@export var rounds_per_load := 5
@export var reload_seconds := 12.0
@export var seconds_between_shots := 1.4

var body: HumanBody
var mood := Mood.CALM
var fear := 0.0
var rounds := 5
var target: Node3D

var _rng := RandomNumberGenerator.new()
var _next_shot := 1.0
var _reload_left := 0.0
var _aimed_at := 0.0
var _gun_sound: AudioStreamPlayer3D
var _said_gut := false


func _ready() -> void:
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 31 + 7
	rounds = rounds_per_load
	body.hit.connect(_on_hit)
	body.fell.connect(_on_fell)
	Events.near_miss.connect(_on_near_miss)
	Events.shouted.connect(_on_shouted)
	_gun_sound = AudioStreamPlayer3D.new()
	_gun_sound.stream = SynthSounds.get_sound(&"gunshot")
	_gun_sound.unit_size = 25.0
	_gun_sound.max_db = 6.0
	body.add_child.call_deferred(_gun_sound)


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	if lines.is_empty() or not body.physiology.is_conscious():
		return
	Events.spoke.emit(body, lines[_rng.randi() % lines.size()])


func _set_mood(m: Mood) -> void:
	if mood != m:
		mood = m
		mood_changed.emit(m)


func _find_target() -> Node3D:
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(&"player") as Node3D
	return target


# --- What frightens him ------------------------------------------------------------------------

func _provoked(by: Node) -> void:
	if mood == Mood.CALM and by != null and by == _find_target():
		say(&"provoked")
		_set_mood(Mood.FIGHTING)
		_next_shot = _rng.randf_range(0.6, 1.1)


func _on_near_miss(person: Node, shooter: Node, distance: float) -> void:
	if person != body:
		return
	fear += 0.06 * clampf(2.5 - distance, 0.5, 2.5)
	if mood == Mood.SURRENDERED:
		fear += 0.05
		return
	_provoked(shooter)


func _on_hit(info: Dictionary) -> void:
	fear += 0.22
	if mood == Mood.SURRENDERED:
		say(&"shot_while_surrendered")
		return
	if mood == Mood.CALM:
		_provoked(_find_target())
	else:
		say(&"hit")
	if not _said_gut and body.physiology.gut_seconds >= 0.0:
		_said_gut = true
		say(&"gut")
	for h: Dictionary in info.hits:
		if h.effect == &"broken":
			fear += 0.1


func _on_fell(conscious: bool) -> void:
	if conscious:
		say(&"down")


## "Drop it!" from someone aiming at him: frightening in proportion to how things are going.
func _on_shouted(speaker: Node, kind: StringName) -> void:
	if kind != &"drop_it" or not speaker is Node3D or mood >= Mood.SURRENDERED:
		return
	var d := (speaker as Node3D).global_position.distance_to(body.global_position)
	if d > 30.0:
		return
	fear += 0.08 + (0.22 if _aimed_at > 0.3 else 0.0) + body.physiology.wounds * 0.08
	if mood == Mood.CALM:
		fear += 0.1  # caught cold with a gun on him


# --- Living ------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var p := body.physiology
	if not p.alive:
		_set_mood(Mood.DEAD)
		return
	if body.limp:
		_set_mood(Mood.DOWN)
		return
	_update_aimed_at(delta)
	# Fear settles slowly, but pain, shock and an empty hand keep it up.
	var floor_fear := p.felt_pain() * 0.3 + p.shock() * 0.6 + (0.25 if body.held_gun == null else 0.0)
	fear = maxf(move_toward(fear, floor_fear, 0.01 * delta), floor_fear * 0.9)
	if mood == Mood.SURRENDERED:
		return
	if body.held_gun == null and mood != Mood.CALM:
		fear += 0.3 * delta
	if fear > nerve:
		_surrender()
		return
	match mood:
		Mood.CALM:
			body.set_pose(&"stand")
		Mood.FIGHTING:
			_fight(delta)
		Mood.RELOADING:
			var t := _find_target()
			if t:
				body.face(t.global_position)
			body.set_pose(&"stand")
			_reload_left -= delta
			if _reload_left <= 0.0:
				rounds = rounds_per_load
				_set_mood(Mood.FIGHTING)
				_next_shot = 0.8


## How long the player has been aiming his way (seconds, decays).
func _update_aimed_at(delta: float) -> void:
	var t := _find_target()
	var gun := t.get_node_or_null(^"Head/Camera3D/Gun") if t else null
	var aiming := false
	if gun is RevolverViewmodel and (gun as RevolverViewmodel).drawn:
		var cam := (gun as Node3D).get_parent() as Node3D
		var to := body.global_position + Vector3.UP * 1.2 - cam.global_position
		var fwd := -cam.global_transform.basis.z
		aiming = fwd.angle_to(to) < deg_to_rad(8.0)
	_aimed_at = clampf(_aimed_at + (delta if aiming else -delta * 0.5), 0.0, 3.0)


func _fight(delta: float) -> void:
	var t := _find_target()
	if t == null:
		return
	var aim_point := _aim_point(t)
	body.face(aim_point)
	body.set_pose(&"aim")
	if body.held_gun == null or not body.physiology.can_hold("r"):
		return
	_next_shot -= delta
	if _next_shot > 0.0:
		return
	if rounds <= 0:
		say(&"reloading")
		_reload_left = reload_seconds
		_set_mood(Mood.RELOADING)
		return
	_fire_at(aim_point, t)
	var p := body.physiology
	_next_shot = seconds_between_shots * _rng.randf_range(0.75, 1.3) + p.shock() * 1.5 + p.felt_pain() * 0.5


func _aim_point(t: Node3D) -> Vector3:
	var chest := 1.3
	if t is Player and (t as Player).is_crouching:
		chest = 0.75
	return t.global_position + Vector3.UP * chest


func _fire_at(point: Vector3, t: Node3D) -> void:
	var gun := body.held_gun as RevolverModel
	var origin := gun.muzzle.global_position
	var p := body.physiology
	var spread := spread_degrees + p.felt_pain() * 3.0 + p.shock() * 6.0 + fear * 2.0
	if t is CharacterBody3D:
		spread += Vector2((t as CharacterBody3D).velocity.x, (t as CharacterBody3D).velocity.z).length() * 0.7
	if body.physiology.trigger_finger("r") != &"index_r":
		spread += 2.0
	var dir := _cone((point - origin).normalized(), deg_to_rad(spread))
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics == null:
		return
	var exclude: Array[RID] = []
	for sid: StringName in body.parts:
		exclude.append((body.parts[sid] as CollisionObject3D).get_rid())
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	var bullet := ballistics.fire(origin, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter, exclude)
	bullet.shooter = body
	rounds -= 1
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir)
	ImpactEffects.muzzle_flash(world, origin)
	_gun_sound.play()
	Events.shot_fired.emit(origin, dir, body)


func _cone(dir: Vector3, radians: float) -> Vector3:
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var r := sqrt(_rng.randf()) * tan(radians)
	var a := _rng.randf() * TAU
	return (dir + side * cos(a) * r + up * sin(a) * r).normalized()


func _surrender() -> void:
	_set_mood(Mood.SURRENDERED)
	say(&"surrender")
	body.drop_gun()
	body.set_pose(&"hands_up")
	Events.person_surrendered.emit(body)


func describe() -> String:
	return "%s: %s, fear %.2f / nerve %.2f, %d rounds. %s" % [String(body.person_id).capitalize(),
			Mood.keys()[mood].to_lower(), fear, nerve, rounds, body.physiology.describe()]
