class_name HostageBrain
extends Node
## The hostage's mind (issue #520: the farmhouse; a townsman, the rancher, held in his own house).
## Tied to a chair (sat back in a kit chair, his hands behind him round its back) he can't move;
## shots and blasts make him flinch and duck his head; he calls for help when he hears you near.
## Cut loose (`free_by`: you, E held by him, FarmhouseMission) he gets up and follows you, crouched,
## keeping behind you from the nearest man fighting, and gets down when they're shooting near him.
## A child of his HumanBody named "Brain", ticked after his body (PeopleTick), as the others.

signal freed

const LINES := {
	&"help": ["Help! In here! They've got me tied!", "Señor! In here! Help me!", "In the back room! Help!"],
	&"quiet": ["Quiet... the one by the door's watching.", "Careful, señor. There's more of them."],
	&"freed": ["Gracias. Get me out of here.", "God bless you. Go, I'm behind you."],
	&"flinch": ["¡Dios!", "Ay—!"],
	&"stay": ["Wait— wait for me!", "Don't leave me here!"],
	&"safe": ["Thank God. Thank God.", "I owe you my life, señor."],
}

## The arms of a man sat back in his chair turned to where `hands_bound` has them (behind him), as
## offsets on `sit_back` (HumanBody.POSES): tied round the chair's back.
const TIED_ARMS := {&"upper_arm_r": Vector3(-59, 0, 6), &"upper_arm_l": Vector3(-59, 0, -6),
		&"forearm_r": Vector3(-22, 40, 0), &"forearm_l": Vector3(-22, -40, 0)}
## Ducking his head while he's tied (shots near).
const DUCKED := {&"chest": Vector3(-18, 0, 0), &"neck": Vector3(-10, 0, 0), &"head": Vector3(-18, 0, 0)}

var body: HumanBody
var senses: Senses
var tuning: FarmhouseTuning
var tied := true
var chair: KitProp
## Who he follows once he's free (the player).
var follow: Node3D
## The men holding him (their brains), to keep out of their line of fire.
var captors: Array[OutlawBrain] = []
## Where to go once he's safe (out of the house; FarmhouseMission ends it).
var safe := false
var fear := 0.0

var _rng := RandomNumberGenerator.new()
var _duck := 0.0
var _call_again := 0.0
var _flinch_said := 0.0
var _route: Array[Vector3] = []
var _route_t := 0.0
var _crouched := false


func _ready() -> void:
	set_physics_process(true)
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 31 + 7
	if tuning == null:
		tuning = load("res://config/farmhouse.tres")
	senses = Senses.new()
	senses.name = "Senses"
	body.add_child.call_deferred(senses)
	Events.shot_fired.connect(_on_shot)
	Events.exploded.connect(_on_exploded)
	Events.noise.connect(_on_noise)


func _enter_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.add_ticker(self)


func _exit_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.remove_ticker(self)


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	if lines.is_empty() or not body.physiology.is_conscious() or not body.physiology.can_speak():
		return
	Events.spoke.emit(body, lines[_rng.randi() % lines.size()])


## Never slower (a hostage is always someone's business), and in trouble while he's held.
func can_slow() -> bool:
	return false


func in_trouble() -> bool:
	return true


## Tied into `c` where he sits now.
func tie_to(c: KitProp) -> void:
	chair = c
	tied = true
	body.set_pose(&"sit_back")
	body.pose_offsets = TIED_ARMS.duplicate()


## Cut loose by `who`: up out of the chair and after him.
func free_by(who: Node3D) -> void:
	if not tied:
		return
	tied = false
	follow = who
	body.pose_offsets = {}
	Seating.stand_up(body, chair)
	body.set_pose(&"stand")
	say(&"freed")
	freed.emit()


func tick(delta: float) -> void:
	var t := Prof.start()
	_step(delta)
	Prof.stop(&"hostage_brain", t)


func _step(delta: float) -> void:
	var p := body.physiology
	if not p.alive or not p.is_conscious() or body.limp:
		return
	_duck -= delta
	_call_again -= delta
	_flinch_said -= delta
	fear = maxf(fear - delta * 0.05, 0.0)
	if tied:
		_tied(delta)
	elif follow != null and is_instance_valid(follow):
		_follow(delta)


## In the chair: still but for his head, ducked while it's loud near him.
func _tied(_delta: float) -> void:
	if chair == null or not is_instance_valid(chair) or chair.loose or chair.seated != body:
		# The chair's gone from under him (a blast, a ball): he's on the floor, still tied.
		return
	var off := TIED_ARMS.duplicate()
	if _duck > 0.0:
		off.merge(DUCKED, true)
	body.pose_offsets = off
	body.set_pose(&"sit_back")


## After you, crouched, a pace or two behind, on your side away from the nearest man fighting.
func _follow(delta: float) -> void:
	var lead := follow.global_position
	var threat := _nearest_threat()
	var want := lead
	var away := Vector3.ZERO
	if threat != null:
		away = lead - threat.global_position
		away.y = 0.0
	if away.length() < 0.1:
		away = body.global_position - lead
		away.y = 0.0
	if away.length() > 0.01:
		want = lead + away.normalized() * tuning.follow_gap
	var to := want - body.global_position
	to.y = 0.0
	var shooting := _duck > 0.0
	if to.length() < 0.5:
		# Where he wants to be: down low while they're shooting, else crouched, watching you.
		body.set_pose(&"duck" if shooting else &"crouch")
		body.face(threat.global_position + Vector3.UP * 1.4 if threat else lead + Vector3.UP * 1.4)
		_route.clear()
		return
	# Going: by the town's ways if a straight walk won't do (round a wall, through a door).
	_route_t -= delta
	if _route.is_empty() or _route_t <= 0.0:
		_route_t = 1.0
		_route.clear()
		var places := _places()
		if places != null:
			_route = places.route_to_point(World.space(body), body.global_position, want, _exclude())
		if _route.is_empty():
			_route = [want]
	var far := body.global_position.distance_to(lead) > tuning.follow_hurry
	# Crouched and quick at a run when he's fallen behind, at a crouched walk otherwise.
	body.set_pose(&"stand" if far else &"crouch")
	if body.walk_to(_route[0], 3.6 if far else 1.6, delta):
		_route.pop_front()


## The nearest of the men holding him still fighting.
func _nearest_threat() -> Node3D:
	var best: Node3D = null
	var best_d := 40.0
	for b in captors:
		if not is_instance_valid(b) or b.body == null or not is_instance_valid(b.body):
			continue
		if not b.body.physiology.alive or b.mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.DOWN, OutlawBrain.Mood.DEAD, OutlawBrain.Mood.FLEEING]:
			continue
		var d := b.body.global_position.distance_to(body.global_position)
		if d < best_d:
			best = b.body
			best_d = d
	return best


func _on_shot(origin: Vector3, _dir: Vector3, _shooter: Node) -> void:
	if not is_instance_valid(body):
		return
	var d := origin.distance_to(body.global_position)
	if d > 30.0:
		return
	_duck = maxf(_duck, lerpf(3.0, 1.0, d / 30.0))
	fear = minf(fear + 0.1, 1.0)
	if d < 8.0 and _flinch_said <= 0.0 and _rng.randf() < 0.4:
		_flinch_said = 6.0
		say(&"flinch")


func _on_exploded(at: Vector3, _kg: float) -> void:
	if is_instance_valid(body) and at.distance_to(body.global_position) < 40.0:
		_duck = maxf(_duck, 4.0)
		fear = minf(fear + 0.3, 1.0)
		if _flinch_said <= 0.0:
			_flinch_said = 6.0
			say(&"flinch")


## Someone moving about outside (or in), not one of them: you, he hopes. Help!
func _on_noise(at: Vector3, loudness: float, kind: StringName, source: Node) -> void:
	if not tied or not is_instance_valid(body) or not source is Player or _call_again > 0.0:
		return
	var d := at.distance_to(body.global_position)
	if d > minf(loudness, tuning.call_hear):
		return
	_call_again = tuning.call_every
	say(&"help" if kind != &"gunshot" else &"flinch")


func _places() -> Waypoints:
	for b in captors:
		if is_instance_valid(b) and b.places != null:
			return b.places
	return null


func _exclude() -> Array[RID]:
	var out: Array[RID] = []
	for sid: StringName in body.parts:
		out.append((body.parts[sid] as CollisionObject3D).get_rid())
	return out
