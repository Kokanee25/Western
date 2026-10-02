class_name CivilianBrain
extends Node
## A townsman with no gun and no wish for a fight: the storekeeper, the barkeep. He minds his
## post, facing the counter. Trouble brought to him, he does what a sensible man does: a shove
## and he protests, a gun on him and his hands go up and he begs, shooting near him and he gets
## down and covers his head. When it's over he goes back to his post, and if you're the one who
## ran them off, he says so. He knows only what he's seen and heard (Senses), like anyone.
## Child of a HumanBody (with no gun).

enum Mood { CALM, SHAKEN, HANDS_UP, COWERING, DOWN, DEAD }

const LINES := {
	&"shoved": ["Hey—! There's no call for that.", "Please, I don't want any trouble.", "Easy! Easy..."],
	&"beg": ["Take it! Take whatever you want!", "Don't shoot! I got a family!", "Please, mister..."],
	&"cower": ["Lord almighty!", "Get down! Everybody down!"],
	&"relief": ["...They gone?", "Lord. Lord, lord."],
	&"thanks": ["Obliged to you, mister. Truly.", "Thank God you came along.", "I owe you one, friend."],
}

## Where he stands, and the point he faces there (set by whoever put him there).
var post := Vector3.INF
var faces := Vector3.INF
## How he takes his ease at his post when all's calm (`sit` on a porch bench, or `stand`).
var rest_pose := &"stand"
var mood := Mood.CALM
var fear := 0.0
var senses: Senses
var body: HumanBody
## Men who've troubled him today.
var troubled_by: Array = []
## Someone ran them off (the player): he'll thank him once it's calm.
var helped_by: Node
var thanked := false

var _aimed := 0.0
var _aimed_by: Node3D
var _cower := 0.0
var _flinch := 0.0
var _say_again := 0.0
var _calm_for := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 23 + 11
	senses = Senses.new()
	senses.name = "Senses"
	body.add_child.call_deferred(senses)
	Events.deed.connect(_on_deed)
	Events.noise.connect(_on_noise)


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	if lines.is_empty() or not body.physiology.is_conscious() or not body.physiology.can_speak():
		return
	Events.spoke.emit(body, lines[_rng.randi() % lines.size()])


func _on_deed(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
	if actor == body or senses == null or not body.physiology.is_conscious():
		return
	var to_me := target == body
	var loud := kind in [&"shoot_at", &"hit", &"kill"]
	# The men who troubled him being run off, taken or shot: whoever did it did him a turn.
	if troubled_by.has(actor) and kind in [&"back_down", &"surrender"] and (target is Player or kind == &"surrender"):
		if target is Player:
			helped_by = target
		elif _against_player(actor):
			helped_by = _player()
	if actor is Player and troubled_by.has(target) and kind in [&"hit", &"kill"]:
		helped_by = actor
	if not to_me:
		if loud and actor is Node3D and (actor as Node3D).global_position.distance_to(body.global_position) < 25.0:
			_scared_by_shooting()
		return
	if not loud and not senses.sees(actor) and senses.aware_of(actor) < 0.4:
		return  # done behind his back and he never knew
	match kind:
		&"shove":
			fear += 0.25
			_flinch = 1.0
			_troubled(actor)
			say(&"shoved")
			_say_again = 4.0
		&"aim_at":
			fear += 0.05
			_aimed = 0.8
			_aimed_by = actor as Node3D
			_troubled(actor)
			if mood != Mood.HANDS_UP:
				mood = Mood.HANDS_UP
				say(&"beg")
				_say_again = 5.0
		&"draw":
			fear += 0.1
			_troubled(actor)
		&"shoot_at", &"hit":
			_scared_by_shooting()
			_troubled(actor)


## Did the player stand up to that man (face him down, draw on him)?
func _against_player(man: Node) -> bool:
	var b := man.get_node_or_null(^"Brain") as OutlawBrain if man else null
	var p := _player()
	if b == null or p == null or not b.relations.entries.has(p):
		return false
	var e: Dictionary = b.relations.entries[p]
	return e.cowed or e.grudge > 0.0 or e.stance >= Relations.Stance.WARY


func _troubled(who: Node) -> void:
	if who is Player:
		return
	if not troubled_by.has(who):
		troubled_by.append(who)
		thanked = false


func _scared_by_shooting() -> void:
	if _cower <= 0.0:
		say(&"cower")
	_cower = maxf(_cower, 7.0)
	fear += 0.3


func _on_noise(at: Vector3, _loudness: float, kind: StringName, _source: Node) -> void:
	if kind in [&"gunshot", &"blast"] and at.distance_to(body.global_position) < (25.0 if kind == &"gunshot" else 60.0):
		if body.physiology.is_conscious():
			_scared_by_shooting()


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _physics_process(delta: float) -> void:
	var p := body.physiology
	if not p.alive:
		mood = Mood.DEAD
		return
	if body.limp:
		mood = Mood.DOWN
		return
	_aimed -= delta
	_cower -= delta
	_flinch -= delta
	_say_again -= delta
	fear = maxf(fear - 0.03 * delta, 0.0)
	for who in troubled_by.duplicate():
		if not is_instance_valid(who):
			troubled_by.erase(who)
	if _aimed > 0.0 and _aimed_by and is_instance_valid(_aimed_by):
		mood = Mood.HANDS_UP
		_calm_for = 0.0
		body.face(_aimed_by.global_position + Vector3.UP * 1.5)
		body.set_pose(&"hands_up")
		if _say_again <= 0.0:
			say(&"beg")
			_say_again = _rng.randf_range(5.0, 8.0)
		return
	if _cower > 0.0:
		mood = Mood.COWERING
		_calm_for = 0.0
		body.set_pose(&"cower")
		return
	if _flinch > 0.0:
		body.set_pose(&"hands_up" if _flinch > 0.5 else &"stand")
		return
	if mood in [Mood.HANDS_UP, Mood.COWERING]:
		mood = Mood.SHAKEN
		if not _still_over_me():
			say(&"relief")
	_calm_for += delta
	if mood == Mood.SHAKEN and _calm_for > 6.0 and fear < 0.2:
		mood = Mood.CALM
	if post != Vector3.INF and body.global_position.distance_to(post) > 0.3:
		body.set_pose(&"stand")
		body.walk_to(post, 1.2, delta)
		return
	body.set_pose(rest_pose)
	_thank(delta)
	if faces != Vector3.INF and not (helped_by and not thanked):
		body.face(faces)


## Once it's quiet and the man who ran them off is near enough to hear it.
func _thank(_delta: float) -> void:
	if helped_by == null or thanked or not is_instance_valid(helped_by) or _calm_for < 2.5:
		return
	var h := helped_by as Node3D
	if _still_over_me():
		return  # not while they're still stood over him
	if h.global_position.distance_to(body.global_position) > 12.0 or not senses.sees(h):
		return
	body.face(h.global_position + Vector3.UP * 1.5)
	say(&"thanks")
	thanked = true
	troubled_by.clear()
	Events.deed.emit(body, &"thank", helped_by, body.global_position)


## One of them still stood over him, not run off.
func _still_over_me() -> bool:
	for t in troubled_by:
		if not is_instance_valid(t) or (t as Node3D).global_position.distance_to(body.global_position) > 6.0:
			continue
		var b := t.get_node_or_null(^"Brain") as OutlawBrain
		var cowed: bool = helped_by != null and b != null and b.relations.entries.has(helped_by) and b.relations.entries[helped_by].cowed
		if b and b.mood == OutlawBrain.Mood.CALM and not cowed:
			return true
	return false


func describe() -> String:
	var how: String = String(Mood.keys()[mood]).to_lower()
	return "%s: %s, fear %.2f. %s" % [String(body.person_id).capitalize(), how, fear, body.physiology.describe()]
