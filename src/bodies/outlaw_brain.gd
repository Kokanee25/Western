class_name OutlawBrain
extends Node
## The test outlaw's mind: fear and nerve, not a health bar. He stands easy until someone shoots
## at him (a hit, or a ball cracking past), then fights like a man who wants to live: he runs for
## cover (Cover finds it: anything solid between him and you), keeps his head down while rounds
## crack past, rises or leans out to shoot a shot or two, ducks back, reloads behind it, and now
## and then moves to a new angle on you. Everything frightening adds fear — near misses, hits,
## pain, shock, losing his gun, being aimed at and told to drop it — and when fear passes his
## nerve he breaks: runs for it if his legs will carry him and you're not right on him, else
## drops the gun and puts his hands up. Hurt and not being shot at, he presses on the wound or
## cinches a belt round the limb. Legs gone, he's down on his belly (HumanBody.prone), crawling
## and still shooting. Most fights end when nerve breaks, not bodies.
## Child of a HumanBody.

signal mood_changed(mood: Mood)

enum Mood { CALM, FIGHTING, RELOADING, SURRENDERED, DOWN, DEAD, FLEEING, TENDING }
## In a fight: in the open, on his way to cover, hidden behind it, up and shooting from it.
enum Tactic { OPEN, MOVING, HIDDEN, PEEKING }

const LINES := {
	&"provoked": ["You damn fool!", "Your funeral, friend.", "That's how it is? Fine!"],
	&"hit": ["Agh—!", "Son of a—!", "I'm hit, damn it!"],
	&"gut": ["Oh God, not the belly..."],
	&"surrender": ["Alright! Alright! I'm done!", "Don't shoot! I quit, I quit!", "Enough! It's yours!"],
	&"down": ["My leg... damn you...", "Can't... get up..."],
	&"shot_while_surrendered": ["I give up, you bastard!", "I'm unarmed!"],
	&"reloading": ["Hold still..."],
	&"flee": ["To hell with this!", "I ain't dying for this!", "I'm gone!"],
	&"tend": ["Damn, damn...", "Hold it together..."],
}

## How much fear he can carry before he breaks. A hired gun; a family man would be lower.
@export var nerve := 0.75
## Spread of his shots in degrees when calm and unhurt.
@export var spread_degrees := 2.4
@export var rounds_per_load := 5
@export var reload_seconds := 12.0
@export var seconds_between_shots := 1.4
## Fear from being hit at all, and more if it broke bone or tore something vital.
@export var fear_per_hit := 0.25
@export var fear_per_severe_hit := 0.14
@export var fear_pellet_share := 0.4
## When his nerve goes and he can run, the chance he runs rather than gives up.
@export var flee_chance := 0.55
## Running and walking speeds (m/s), before wounds.
@export var run_speed := 3.8
@export var walk_speed := 1.4
## Bleeding this hard (ml/s) and not being shot at for this long (s), he stops to tend it.
@export var tend_bleed := 0.8
@export var tend_quiet := 3.0

var body: HumanBody
var mood := Mood.CALM
var fear := 0.0
var rounds := 5
var target: Node3D

var _rng := RandomNumberGenerator.new()
## Separate from his aim, so choosing where to hide doesn't change how he shoots.
var _think := RandomNumberGenerator.new()
var _next_shot := 1.0
var _reload_left := 0.0
var _aimed_at := 0.0
## Looking down the barrels of a scattergun: nobody argues with one of those for long.
var _facing_shotgun := false
var _gun_sound: AudioStreamPlayer3D
var _said_gut := false
## Seconds knocked off balance by a hit: no shooting until he recovers.
var _stagger := 0.0
var tactic := Tactic.OPEN
## The spot he's using: {at, low, peek}; {} in the open.
var cover := {}
var _cover_search := 0.0
var _tactic_time := 0.0
var _peek_time := 0.0
var _peek_shots := 0
var _peek_pose := &"aim"
var _peeks := 0
var _in_cover := 0.0
var _flank_after := 12.0
var _move_time := 0.0
var _check := 0.0
var _search: Cover.Search
var _search_bias := Vector3.INF
## Keeping his head down: seconds left (rounds cracking past).
var suppressed := 0.0
## Seconds since the one he's fighting last fired.
var _quiet := 99.0
var _flee_to := Vector3.INF
var _flee_time := 0.0
var _stuck := 0.0
var _last_pos := Vector3.ZERO
var _tend_time := 0.0
var _tend_bleed: Dictionary = {}
var _after_tend := Mood.FIGHTING


func _ready() -> void:
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 31 + 7
	_think.seed = body.rng_seed * 17 + 3
	rounds = rounds_per_load
	body.hit.connect(_on_hit)
	body.fell.connect(_on_fell)
	Events.near_miss.connect(_on_near_miss)
	Events.shouted.connect(_on_shouted)
	Events.exploded.connect(_on_exploded)
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, who: Node) -> void: if who == _find_target(): _quiet = 0.0)
	Events.scorched.connect(func(who: Node, amount: float) -> void: if who == body: fear += amount * 0.6)
	_gun_sound = AudioStreamPlayer3D.new()
	_gun_sound.stream = SynthSounds.get_sound(&"gunshot")
	_gun_sound.unit_size = 25.0
	_gun_sound.max_db = 6.0
	body.add_child.call_deferred(_gun_sound)


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	var p := body.physiology
	if lines.is_empty() or not p.is_conscious():
		return
	if p.airway_blood:
		Events.spoke.emit(body, "Hhhk— hhk—")  # blood in his windpipe: no words left
	elif p.jaw_broken:
		Events.spoke.emit(body, "Nnngh! Nnnh!")
	else:
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
	# Heads down.
	suppressed = maxf(suppressed, 1.0 + clampf(2.5 - distance, 0.0, 2.5) * 0.5)
	if tactic == Tactic.PEEKING:
		_duck_back()
	if mood == Mood.SURRENDERED:
		fear += 0.05
		return
	_provoked(shooter)


func _on_hit(info: Dictionary) -> void:
	match info.get("kind", &"bullet"):
		&"cut":
			fear += 0.04
			return
		&"blow":
			fear += clampf(float(info.get("joules", 0.0)) / 600.0, 0.05, 0.5)
			return
		&"graze":
			fear += fear_per_hit * 0.5
			if mood == Mood.CALM:
				_provoked(_find_target())
			return
	# Bad wounds frighten more than grazes; so does the thump of a ball stopping inside him.
	# Each buckshot pellet counts for a share: a charge lands several at once.
	var share := fear_pellet_share if info.get("kind", &"bullet") in [&"pellet", &"splinter", &"gravel"] else 1.0
	fear += (fear_per_hit + (fear_per_severe_hit if info.get("severe", false) else 0.0) \
			+ float(info.get("deposited", 0.0)) / 2000.0) * share
	_stagger = maxf(_stagger, 0.45 + float(info.get("deposited", 0.0)) / 700.0)
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


## Dynamite going off near him: frightening by how hard it hit him, and it starts the fight.
func _on_exploded(at: Vector3, kg: float) -> void:
	if mood == Mood.DEAD or not is_instance_valid(body):
		return
	var d := body.global_position.distance_to(at)
	if d > 60.0:
		return
	var kpa := Blast.overpressure_kpa(kg, d)
	fear += clampf(kpa / 25.0, 0.05, 1.5)
	if mood == Mood.CALM and d < 25.0:
		_provoked(_find_target())


## "Drop it!" from someone aiming at him: frightening in proportion to how things are going.
func _on_shouted(speaker: Node, kind: StringName) -> void:
	if kind != &"drop_it" or not speaker is Node3D or mood in [Mood.SURRENDERED, Mood.DOWN, Mood.DEAD]:
		return
	var d := (speaker as Node3D).global_position.distance_to(body.global_position)
	if d > 30.0:
		return
	fear += 0.08 + (0.22 if _aimed_at > 0.3 else 0.0) + body.physiology.wounds * 0.08
	if _facing_shotgun and _aimed_at > 0.3:
		fear += 0.12
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
	_quiet += delta
	suppressed = maxf(suppressed - delta, 0.0)
	# Fear settles slowly, but pain, shock and an empty hand keep it up.
	var floor_fear := p.felt_pain() * 0.3 + p.shock() * 0.6 + (0.25 if body.held_gun == null else 0.0) \
			+ clampf(p.total_bleed_rate() / 15.0, 0.0, 0.3)  # the sight of his own blood
	fear = maxf(move_toward(fear, floor_fear, 0.01 * delta), floor_fear * 0.9)
	if mood == Mood.SURRENDERED:
		return
	if mood == Mood.FLEEING:
		_flee(delta)
		return
	if mood == Mood.TENDING:
		_tend(delta)
		return
	if body.held_gun == null and mood != Mood.CALM:
		fear += 0.3 * delta
	if fear > nerve:
		_break()
		return
	match mood:
		Mood.CALM:
			body.set_pose(&"stand")
		Mood.FIGHTING, Mood.RELOADING:
			_combat(delta)


## How long the player has been aiming his way (seconds, decays).
func _update_aimed_at(delta: float) -> void:
	var t := _find_target()
	var gun: Variant = (t as Player).weapon if t is Player else null
	var aiming := false
	if gun is WeaponViewmodel and (gun as WeaponViewmodel).drawn:
		var cam := (gun as Node3D).get_parent() as Node3D
		var to := body.global_position + Vector3.UP * 1.2 - cam.global_position
		var fwd := -cam.global_transform.basis.z
		aiming = fwd.angle_to(to) < deg_to_rad(8.0)
	_aimed_at = clampf(_aimed_at + (delta if aiming else -delta * 0.5), 0.0, 3.0)
	_facing_shotgun = aiming and gun is ShotgunViewmodel


# --- Fighting ----------------------------------------------------------------------------------

func _combat(delta: float) -> void:
	var t := _find_target()
	if t == null:
		return
	if mood == Mood.RELOADING:
		_reload_left -= delta
		if _reload_left <= 0.0:
			rounds = rounds_per_load
			_set_mood(Mood.FIGHTING)
			_next_shot = 0.8
	var eye := _eye_of(t)
	_cover_search -= delta
	if not body.prone:
		_step_search()
	if body.prone:
		# Down on his belly: no running for cover; shoot from where he lies, tend when it's quiet.
		tactic = Tactic.OPEN
		if _wants_to_tend():
			_start_tending(Mood.FIGHTING)
			return
		_fight(delta)
		return
	match tactic:
		Tactic.OPEN:
			if _cover_search <= 0.0:
				_cover_search = 1.5
				_seek_cover(eye, Vector3.INF)
			if tactic == Tactic.OPEN:
				if mood == Mood.RELOADING:
					body.face(eye)
					body.set_pose(&"stand")
				else:
					_fight(delta)
		Tactic.MOVING:
			_move_time += delta
			body.set_pose(&"stand")
			var way: Array = cover.get("route", [cover.at])
			var arrived := body.walk_to(way[0], run_speed, delta)
			if arrived and way.size() > 1:
				way.pop_front()
				arrived = false
			_watch_stuck(delta)
			if arrived:
				tactic = Tactic.HIDDEN
				_tactic_time = _think.randf_range(0.6, 1.6)
				_in_cover = 0.0
				_peeks = 0
				_flank_after = _think.randf_range(10.0, 18.0)
			elif _move_time > 7.0 or _stuck > 1.2:
				tactic = Tactic.OPEN
				_cover_search = 0.0
		Tactic.HIDDEN:
			_hide(delta, eye)
		Tactic.PEEKING:
			_peek(delta, t, eye)


func _eye_of(t: Node3D) -> Vector3:
	if t is Player:
		return (t as Player).camera.global_position
	return t.global_position + Vector3.UP * 1.6


func _exclude(t: Node3D = null) -> Array[RID]:
	var out: Array[RID] = []
	for sid: StringName in body.parts:
		out.append((body.parts[sid] as CollisionObject3D).get_rid())
	if t is CollisionObject3D:
		out.append((t as CollisionObject3D).get_rid())
	return out


## Start looking for somewhere to fight from (spread over a few ticks); `bias_from` a spot he's
## leaving, for a new angle on you.
func _seek_cover(eye: Vector3, bias_from: Vector3) -> void:
	if _search != null:
		return
	_search = Cover.search(body.get_parent() as Node3D, body.global_position, eye, _exclude(_find_target()), _think, bias_from)
	_search_bias = bias_from


## A few more candidate spots this tick; when the hunt's done, go if it found somewhere.
func _step_search() -> void:
	if _search == null or not _search.step(40):
		return
	var spot := _search.result
	_search = null
	if spot.is_empty():
		return
	if _search_bias != Vector3.INF and (spot.at as Vector3).distance_to(_search_bias) < 1.5:
		return
	if tactic == Tactic.PEEKING:
		return  # he'll go next time he's down
	cover = spot
	tactic = Tactic.MOVING
	_move_time = 0.0
	_stuck = 0.0
	_last_pos = body.global_position


func _watch_stuck(delta: float) -> void:
	if body.global_position.distance_to(_last_pos) < 0.02 * 60.0 * delta:
		_stuck += delta
	else:
		_stuck = maxf(_stuck - delta, 0.0)
	_last_pos = body.global_position


## Behind it: head down (lower still while rounds crack past), reloading, waiting his moment.
func _hide(delta: float, eye: Vector3) -> void:
	body.face(eye)
	var down_low: bool = cover.low and (suppressed > 0.0 or not cover.get("crouch_ok", false))
	if cover.get("lie", false):
		body.set_pose(&"lie")
	else:
		body.set_pose(&"duck" if down_low else (&"crouch" if cover.low else &"stand"))
	_in_cover += delta
	if suppressed <= 0.0:
		_tactic_time -= delta
	_check -= delta
	if _check <= 0.0:
		_check = 0.5
		var space := body.get_world_3d().direct_space_state
		var h := Cover.LIE_HEAD if cover.get("lie", false) else (Cover.HIDE_HEAD if cover.low else Cover.STAND_HEAD)
		if not Cover.hidden_at(space, cover.at, eye, h, _exclude(_find_target())):
			# He's come round it: this cover's no good now.
			tactic = Tactic.OPEN
			_cover_search = 0.0
			return
	if _wants_to_tend():
		_start_tending(Mood.FIGHTING)
		return
	if _in_cover > _flank_after or _peeks >= 4:
		_in_cover = 0.0
		_peeks = 0
		_flank_after = _think.randf_range(10.0, 18.0)
		_seek_cover(eye, cover.at)
	if _tactic_time <= 0.0 and mood == Mood.FIGHTING and body.held_gun != null and body.physiology.can_hold("r"):
		tactic = Tactic.PEEKING
		_peek_time = 0.0
		_peek_shots = 0
		_next_shot = _think.randf_range(0.35, 0.7)
		var space := body.get_world_3d().direct_space_state
		# Over low cover he shoots crouched if he can see over it that low, else he stands.
		_peek_pose = &"crouch_aim" if cover.low and Cover._sees(space, cover.at + Vector3.UP * Cover.CROUCH_GUN, eye, _exclude(_find_target())) else &"aim"


## Up (or out) and shooting: a shot or two, then back down.
func _peek(delta: float, t: Node3D, eye: Vector3) -> void:
	_peek_time += delta
	if not cover.low and body.global_position.distance_to(cover.peek) > 0.2:
		body.walk_to(cover.peek, walk_speed * 1.6, delta, false)
	var aim_point := _aim_point(t)
	body.face(aim_point)
	_stagger -= delta
	if body.physiology.felt_pain() > body.physiology.tuning.pain_disabling or _stagger > 0.0:
		_duck_back()
		return
	body.set_pose(_peek_pose)
	_next_shot -= delta
	if _next_shot <= 0.0:
		if rounds <= 0:
			say(&"reloading")
			_reload_left = reload_seconds
			_set_mood(Mood.RELOADING)
			_duck_back()
			return
		_fire_at(aim_point, t)
		_peek_shots += 1
		var p := body.physiology
		_next_shot = seconds_between_shots * _rng.randf_range(0.6, 1.0) + p.shock() + p.felt_pain() * 0.4
	if _peek_shots >= 1 + (_think.randi() % 2) and _next_shot > 0.3 or _peek_time > 3.0:
		_duck_back()


func _duck_back() -> void:
	if tactic != Tactic.PEEKING:
		return
	tactic = Tactic.HIDDEN
	_peeks += 1
	_tactic_time = _think.randf_range(1.2, 3.0)
	if not cover.low:
		# Back in behind the wall.
		body.global_position = body.global_position.lerp(cover.at, 0.5)


## In the open, standing and trading shots (or down, from the ground).
func _fight(delta: float) -> void:
	var t := _find_target()
	if t == null:
		return
	var aim_point := _aim_point(t)
	body.face(aim_point)
	_stagger -= delta
	if body.physiology.felt_pain() > body.physiology.tuning.pain_disabling:
		body.set_pose(&"clutch")  # doubled over, holding it
		fear += 0.05 * delta
		return
	if _stagger > 0.0:
		body.set_pose(&"stand")
		_next_shot = maxf(_next_shot, 0.3)
		return
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
	var spread := spread_degrees + p.felt_pain() * 3.0 + p.shock() * 6.0 + fear * 2.0 \
			+ (1.0 - p.arm_steadiness("r")) * 6.0 + (2.5 if p.blind.has(&"eye_r") else 0.0)
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


# --- Breaking, running, tending --------------------------------------------------------------------

## Nerve's gone: run for it if he can, else give up.
func _break() -> void:
	var t := _find_target()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	var caught := _aimed_at > 0.8 and d < 12.0
	if body.physiology.can_run() and not body.prone and d > 5.0 and not caught and _think.randf() < flee_chance:
		_start_fleeing()
	else:
		_surrender()


func _start_fleeing() -> void:
	say(&"flee")
	_set_mood(Mood.FLEEING)
	tactic = Tactic.OPEN
	_flee_time = 0.0
	_pick_flight()


## Somewhere well away from the gun that he can run to in a straight line.
func _pick_flight() -> void:
	var t := _find_target()
	var away := body.global_position - (t.global_position if t else body.global_position + Vector3.FORWARD)
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	var space := body.get_world_3d().direct_space_state
	for ang in [0.0, 25.0, -25.0, 50.0, -50.0, 80.0, -80.0, 110.0, -110.0]:
		var dir := away.rotated(Vector3.UP, deg_to_rad(ang + _think.randf_range(-8.0, 8.0)))
		var probe := body.global_position + dir * 8.0
		if Cover.path_clear(space, body.global_position, probe, _exclude(t)):
			_flee_to = body.global_position + dir * 30.0
			_stuck = 0.0
			_last_pos = body.global_position
			return
	_flee_to = body.global_position + away * 30.0


func _flee(delta: float) -> void:
	_flee_time += delta
	var t := _find_target()
	if not body.physiology.can_run():
		# Can't run any more: done.
		_surrender()
		return
	body.set_pose(&"stand")
	var arrived := body.walk_to(_flee_to, run_speed * 1.1, delta)
	_watch_stuck(delta)
	if _stuck > 0.8:
		_pick_flight()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	if arrived or d > 38.0 or _flee_time > 14.0:
		# Far enough: get his breath back, see to his wounds.
		_start_tending(Mood.FLEEING)


func _wants_to_tend() -> bool:
	return _quiet > tend_quiet and body.physiology.total_bleed_rate() > tend_bleed and not _worst_bleed().is_empty()


func _worst_bleed() -> Dictionary:
	var p := body.physiology
	var worst: Dictionary = {}
	for b: Dictionary in p.bleeds:
		if b.tourniquet or b.get(&"bandaged", false) or b.get("kind", &"ooze") == &"internal":
			continue
		if worst.is_empty() or p.bleed_rate(b) > p.bleed_rate(worst):
			worst = b
	return worst


func _start_tending(after: Mood) -> void:
	_after_tend = after
	_set_mood(Mood.TENDING)
	_tend_time = 0.0
	_tend_bleed = _worst_bleed()
	if not _tend_bleed.is_empty():
		say(&"tend")


## Pressing on the worst of it; after a few seconds a belt round the limb above it (if it's a limb
## and it's pumping), or it's packed and bound. Then the next. Shot at, he stops.
func _tend(delta: float) -> void:
	var p := body.physiology
	body.set_pose(&"prone" if body.prone else &"tend")
	var t := _find_target()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	if _quiet < 0.5 or (_after_tend == Mood.FLEEING and d < 10.0):
		_release_pressure()
		if _after_tend == Mood.FLEEING:
			_surrender() if d < 10.0 else _start_fleeing()
		else:
			_set_mood(Mood.FIGHTING)
			tactic = Tactic.HIDDEN if not cover.is_empty() else Tactic.OPEN
		return
	if _tend_bleed.is_empty() or not p.bleeds.has(_tend_bleed):
		_tend_bleed = _worst_bleed()
		_tend_time = 0.0
		if _tend_bleed.is_empty():
			# Nothing more he can do for it.
			if _after_tend == Mood.FIGHTING and fear <= nerve:
				_set_mood(Mood.FIGHTING)
			return
	_tend_time += delta
	var seg: StringName = _tend_bleed.segment
	p.apply_pressure(seg)
	if _tend_time >= 4.0:
		var s := String(seg)
		var limb := s.contains("arm") or s.contains("thigh") or s.contains("shin") or s.contains("hand") or s.contains("foot")
		if limb and float(_tend_bleed.rate) > p.tuning.clot_max_rate:
			var side := s.right(1)
			p.apply_tourniquet(StringName(("upper_arm_" if s.contains("arm") or s.contains("hand") else "thigh_") + side))
		else:
			for b: Dictionary in p.bleeds:
				if b.segment == seg:
					b.bandaged = true
					b.pressure = true
		_tend_bleed = {}
		_tend_time = 0.0


func _release_pressure() -> void:
	for b: Dictionary in body.physiology.bleeds:
		if not b.get(&"bandaged", false):
			b.pressure = false


func _surrender() -> void:
	_set_mood(Mood.SURRENDERED)
	say(&"surrender")
	body.drop_gun()
	if mood == Mood.TENDING:
		_release_pressure()
	body.set_pose(&"prone" if body.prone else &"hands_up")
	Events.person_surrendered.emit(body)


func describe() -> String:
	var how: String = String(Mood.keys()[mood]).to_lower()
	if mood == Mood.FIGHTING or mood == Mood.RELOADING:
		how += " (%s%s)" % [String(Tactic.keys()[tactic]).to_lower(), ", pinned down" if suppressed > 0.0 else ""]
	return "%s: %s, fear %.2f / nerve %.2f, %d rounds. %s" % [String(body.person_id).capitalize(),
			how, fear, nerve, rounds, body.physiology.describe()]
