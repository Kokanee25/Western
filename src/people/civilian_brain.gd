class_name CivilianBrain
extends Node
## A townsman with no gun and no wish for a fight: the storekeeper, the barkeep. He minds his
## post, facing the counter. Trouble brought to him, he does what a sensible man does: a shove
## and he protests, a gun on him and his hands go up and he begs, shooting near him and he gets
## down and covers his head. When it's over he goes back to his post, and if you're the one who
## ran them off, he says so. He knows only what he's seen and heard (Senses), like anyone.
## Fire near him and he shouts it and gets clear, out to the street, and watches it burn; once his
## post has been clear of it a while he goes back. Clear of it, with water near the fire (a trough,
## the well), he joins the bucket line for that water (BucketLine: a man at the water filling,
## buckets handed up to a man at the fire who throws them, the empties handed back) till it's out,
## unless it's grown past saving.
## All quiet, he may have a chore to see to (`chore`: the barkeep wipes his bar, WipeBar): it has
## him while he's free, and stops the moment he isn't.
## Child of a HumanBody (with no gun).

enum Mood { CALM, SHAKEN, HANDS_UP, COWERING, DOWN, DEAD, FLEEING }

const LINES := {
	&"shoved": ["Hey—! There's no call for that.", "Please, I don't want any trouble.", "Easy! Easy..."],
	&"beg": ["Take it! Take whatever you want!", "Don't shoot! I got a family!", "Please, mister..."],
	&"cower": ["Lord almighty!", "Get down! Everybody down!"],
	&"hat": ["My hat! Lord, my hat!", "He shot my hat clean off!"],
	&"relief": ["...They gone?", "Lord. Lord, lord."],
	&"buckets": ["Buckets! Get the buckets!", "Water! From the trough, quick!", "Bring water, damn it!"],
	&"lost": ["Let it go, she's gone!", "Too late. Let it burn.", "Nothing to be done now."],
	&"out": ["That's got it!", "It's out. Lord.", "Keep an eye on it, it'll catch again."],
	&"fire": ["Fire! FIRE!", "Fire! Get out, get out!", "Lord, it's burning!", "Fire! Somebody get water!",
			"It's going up! Clear out!"],
	&"thanks": ["Obliged to you, mister. Truly.", "Thank God you came along.", "I owe you one, friend."],
}

## Where he stands, and the point he faces there (set by whoever put him there).
var post := Vector3.INF
var faces := Vector3.INF
## How he takes his ease at his post when all's calm (`sit` on a porch bench, or `stand`).
var rest_pose := &"stand"
## What he does with himself when all's quiet (MopFloor, WipeBar), most wanted first; one at a time:
## the one at it keeps him till it's done.
var chores: Array = []
## The chore that has him (or had him last), or null. (Setting it alone gives him that one.)
var chore: RefCounted
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

## Seen kicking a man (PlayerShove's deeds), within this (m), it frightens him.
const ASSAULTS := [&"kick", &"kick_down"]
const ASSAULT_SEEN := 15.0
## Fire within `FIRE_REACH` m of him sends him off to somewhere `FIRE_CLEAR` m from any; he goes
## back once his post has had none within `FIRE_CLEAR` for `FIRE_OVER` s. Looked for every
## `FIRE_LOOK` s.
const FIRE_REACH := 8.0
const FIRE_CLEAR := 15.0
const FIRE_OVER := 20.0
const FIRE_LOOK := 0.5
const FIRE_RUN := 3.4
## Fighting it: water this near the fire (m); a fire with more than this many members burning
## near it is past saving. The line itself is BucketLine's.
const WATER_REACH := 40.0
## A fire this near (m) that isn't on him: he comes to fight it.
const FIRE_SEEN := 30.0
const PAST_SAVING := 40
## Will carry water (false for anyone who should just get clear).
var fights_fire := true
## The town's named places, to find his way out of a building and back (TownLife's if not given).
var places: Waypoints
var _fire: FireSystem
var _fire_look := 0.0
var _fire_at := Vector3.INF
var _fire_out := 0.0
var _shout_in := -1.0
var _route: Array[Vector3] = []
var _stuck := 0.0
var _last_pos := Vector3.INF
var _detours := 0
var _scorched := 0.0
## Fighting it: &"line" while he's in a bucket line (&"" when not), the water it's from, and how
## long before he tries again after giving up.
var _bucket := &""
## The bucket line he's in (&"line" above), or null.
var _line: BucketLine = null
var _trough: Node3D
var _bucket_rest := 0.0
var _said_lost := false
var _home_route: Array[Vector3] = []


func _ready() -> void:
	set_physics_process(true)  # its switch (PeopleTick ticks it while on)
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 23 + 11
	senses = Senses.new()
	senses.name = "Senses"
	body.add_child.call_deferred(senses)
	Events.deed.connect(_on_deed)
	Events.noise.connect(_on_noise)
	Events.hat_shot.connect(_on_hat_shot)
	Events.hours_passed.connect(_on_hours_passed)
	Events.scorched.connect(func(who: Node, amount: float) -> void:
		if who == body:
			_scorched += amount
			_fire_look = minf(_fire_look, 0.05))
	_fire_look = _rng.randf_range(0.0, FIRE_LOOK)  # not everyone looking on the same tick


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	if lines.is_empty() or not body.physiology.is_conscious() or not body.physiology.can_speak():
		return
	Events.spoke.emit(body, lines[_rng.randi() % lines.size()])


func _on_deed(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
	if actor == body or senses == null or not body.physiology.is_conscious():
		return
	var to_me := target == body
	if to_me:
		body.wake()  # done to him: he takes it in next tick, far off or not (PeopleTick's bands)
	var loud := kind in [&"shoot_at", &"hit", &"kill"]
	# The men who troubled him being run off, taken or shot: whoever did it did him a turn, if he
	# saw it.
	if troubled_by.has(actor) and kind in [&"back_down", &"surrender"] and (target is Player or kind == &"surrender") \
			and senses.sees(actor):
		if target is Player:
			helped_by = target
		elif _against_player(actor):
			helped_by = _player()
	if actor is Player and troubled_by.has(target) and kind in [&"hit", &"kill"] and senses.sees(actor):
		helped_by = actor
	if not to_me:
		if loud and actor is Node3D and (actor as Node3D).global_position.distance_to(body.global_position) < 25.0:
			_scared_by_shooting()
		elif kind in ASSAULTS and actor is Node3D and senses.sees(actor) \
				and (actor as Node3D).global_position.distance_to(body.global_position) < ASSAULT_SEEN:
			# A man kicked in front of him: it's turned ugly.
			fear += 0.1 if kind == &"kick" else 0.2
			_flinch = 1.0
		return
	if not loud and not senses.sees(actor) and senses.aware_of(actor) < 0.4:
		return  # done behind his back and he never knew
	match kind:
		&"shove", &"kick", &"kick_down":
			fear += 0.25 if kind == &"shove" else 0.5
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


## His hat shot off his head: down on the boards, and he says so.
func _on_hat_shot(person: Node, _shooter: Node, _at: Vector3) -> void:
	if person != body or not body.physiology.is_conscious():
		return
	say(&"hat")
	_cower = maxf(_cower, 10.0)
	fear += 0.5


## Hours went by in a moment: whatever scared him is long over.
func _on_hours_passed(_hours: float, _why: StringName) -> void:
	_stop_bucket()
	fear = 0.0
	_aimed = 0.0
	_cower = 0.0
	_flinch = 0.0
	troubled_by.clear()
	if mood in [Mood.HANDS_UP, Mood.COWERING, Mood.SHAKEN]:
		mood = Mood.CALM


# --- Fire ------------------------------------------------------------------------------------

## Fire: shout it, get clear, watch it burn, and go back when it's out. True while that's what
## he's doing (nothing else this tick).
func _mind_fire(delta: float) -> bool:
	_fire_look -= delta
	if _fire_look <= 0.0:
		_fire_look = FIRE_LOOK
		var t := Prof.start()
		_look_for_fire()
		Prof.stop(&"civ_fire_look", t)
	if mood != Mood.FLEEING and _route.is_empty():
		return false
	if _shout_in > 0.0:
		_shout_in -= delta
		if _shout_in <= 0.0:
			say(&"fire")
	if not body.physiology.can_stand():
		_route.clear()
		return false
	if not _route.is_empty():
		body.set_pose(&"stand")
		var arrived := body.walk_to(_route[0], FIRE_RUN if mood == Mood.FLEEING else 1.2, delta)
		if body.global_position.distance_to(_last_pos) < 0.01 * 60.0 * delta:
			_stuck += delta
		else:
			_stuck = maxf(_stuck - delta, 0.0)
		_last_pos = body.global_position
		if not arrived and _stuck > 1.0 and _detours < 3:
			# Caught on something low (a trough, a rail): a sidestep round it, one way then the other.
			var to := _route[0] - body.global_position
			to.y = 0.0
			var side := Vector3(-to.z, 0.0, to.x).normalized() * (1.0 if _detours % 2 == 0 else -1.0)
			_route.push_front(body.global_position + side * 1.2 + to.normalized() * 0.3)
			_detours += 1
			_stuck = 0.0
		elif arrived or _stuck > 2.0:
			_route.pop_front()
			_stuck = 0.0
			if arrived:
				_detours = 0
		return true
	if _bucket != &"":
		_bucket_step(delta)
		return true
	if mood == Mood.FLEEING:
		# Clear of it: he stands and watches it burn.
		body.set_pose(&"stand")
		if _fire_at != Vector3.INF:
			body.face(_fire_at + Vector3.UP * 1.0)
		return true
	return false


func _look_for_fire() -> void:
	if _fire == null or not is_instance_valid(_fire):
		_fire = get_tree().get_first_node_in_group(&"fire_system") as FireSystem
	if _fire == null or not body.physiology.is_conscious():
		return
	var here := _fire.fire_near(body.global_position, FIRE_REACH)
	if mood != Mood.FLEEING:
		if here.count > 0:
			_flee(here.at)
			return
		# A fire he can see down the street: he goes to fight it (the bucket line), though it's
		# not on him.
		if fights_fire and mood == Mood.CALM and body.physiology.can_run():
			var seen := _fire.fire_near(body.global_position, FIRE_SEEN)
			if seen.count > 0 and _fire.fire_near(seen.at, 8.0).count <= PAST_SAVING:
				mood = Mood.FLEEING
				_fire_at = seen.at
				_fire_out = 0.0
				_shout_in = _rng.randf_range(0.15, 1.6)
				_start_bucket()
		return
	if _scorched > 0.0:
		_scorched = 0.0
		if here.count > 0:
			_stop_bucket()
			_flee(here.at)  # it's on him: off again, whatever the way he was taking
			return
	if _bucket != &"":
		return  # carrying water: going near it is the point
	if here.count > 0 and _route.is_empty():
		_flee(here.at)  # it's come to him where he stopped: further
		return
	_bucket_rest -= FIRE_LOOK
	if _route.is_empty() and _bucket_rest <= 0.0:
		_start_bucket()
	var home := post if post != Vector3.INF else body.global_position
	var there := _fire.fire_near(home, FIRE_CLEAR)
	if there.count > 0:
		_fire_out = 0.0
		_fire_at = there.at
		return
	_fire_out += FIRE_LOOK
	if _fire_out >= FIRE_OVER:
		mood = Mood.SHAKEN
		_calm_for = 0.0
		if post != Vector3.INF:
			_route = FireFlight.route(_places(), body, post)


# --- Carrying water --------------------------------------------------------------------------

## Clear of it and standing: if there's a trough near the fire and not too many at it already, and
## it's not past saving, he goes for water.
func _start_bucket() -> void:
	if not fights_fire or not body.physiology.can_run():
		return
	var runners := get_tree().get_nodes_in_group(&"bucket_runners").size()
	var fire_at := _fire_at
	if fire_at == Vector3.INF or _fire.fire_near(fire_at, FIRE_CLEAR).count == 0:
		return  # it's out
	var trough := _nearest_trough(fire_at)
	if trough == null:
		return
	if _fire.fire_near(fire_at, 8.0).count > PAST_SAVING:
		if not _said_lost:
			_said_lost = true
			say(&"lost")
		_bucket_rest = 20.0
		return
	for l: Node in get_tree().get_nodes_in_group(&"bucket_lines"):
		if (l as BucketLine).water == trough and not (l as BucketLine).has_room():
			return  # as many as can stand in it
	_trough = trough
	add_to_group(&"bucket_runners")
	if runners == 0:
		say(&"buckets")
	_route.clear()
	_bucket = &"line"
	_line = BucketLine.join(self, trough, _fire, fire_at)


func _stop_bucket() -> void:
	if _line != null and is_instance_valid(_line):
		var line := _line
		_line = null
		line.leave(self)
	_bucket = &""
	_trough = null
	if is_in_group(&"bucket_runners"):
		remove_from_group(&"bucket_runners")


## The line's done with him (it's out, it broke up, or he couldn't get to his place in it): he
## stands and watches, as before, `rest` seconds before he'd try again.
func left_line(rest := 10.0) -> void:
	_line = null
	_bucket = &""
	_trough = null
	_bucket_rest = rest
	if is_in_group(&"bucket_runners"):
		remove_from_group(&"bucket_runners")
	body.set_pose(&"stand")


## In a bucket line, the line moves him: nothing for him to do but keep an eye on it.
func _bucket_step(_delta: float) -> void:
	if _bucket == &"line" and (_line == null or not is_instance_valid(_line)):
		left_line()


func _nearest_trough(near: Vector3) -> Node3D:
	var best: Node3D = null
	var best_d := WATER_REACH
	for t: Node in get_tree().get_nodes_in_group(&"water_source"):
		var d := (t as Node3D).global_position.distance_to(near)
		if d < best_d:
			best_d = d
			best = t as Node3D
	return best


## Beside the trough's water, on the side toward the fire.
static func water_side(trough: Node3D, fire_at: Vector3) -> Vector3:
	var w := trough.get_node_or_null(^"Water") as Node3D
	var centre := w.global_position if w else trough.global_position
	var across := trough.global_basis.z.normalized()
	var side := 1.0 if (fire_at - centre).dot(across) >= 0.0 else -1.0
	var half := float(trough.get(&"trough_width")) * 0.5 if trough.get(&"trough_width") != null else 0.35
	var spot := centre + across * side * (half + 0.45)
	spot.y = trough.global_position.y
	return spot


## Off, away from the fire at `from`, to the nearest place clear of any.
func _flee(from: Vector3) -> void:
	if mood != Mood.FLEEING:
		_shout_in = _rng.randf_range(0.15, 1.6)  # a few men don't all shout in the same breath
	mood = Mood.FLEEING
	_fire_at = from
	_fire_out = 0.0
	_cower = 0.0
	_aimed = 0.0
	_flinch = 0.0
	_route = FireFlight.way_out(_fire, _places(), body, FIRE_CLEAR)


func _places() -> Waypoints:
	if places == null:
		var town := get_tree().get_first_node_in_group(&"town_life")
		if town:
			places = town.get(&"places")
	return places


func _on_noise(at: Vector3, _loudness: float, kind: StringName, _source: Node) -> void:
	if kind in [&"gunshot", &"blast"] and at.distance_to(body.global_position) < (25.0 if kind == &"gunshot" else 60.0):
		if body.physiology.is_conscious():
			_scared_by_shooting()


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


## Ticked by PeopleTick after his body, in his order (HumanBody.add_ticker); the engine calls no
## _physics_process here, and physics processing on is its switch, as before.
func _enter_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.add_ticker(self)


func _exit_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.remove_ticker(self)


func tick(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"civilian_brain", t)


## Far off, may he tick less often (PeopleTick, step 4b)? Going about his day, or cowering or
## shaken where he stands from a shot or a blast he heard (#495: after a stick the whole street
## cowers for 7 s and stays frightened for ~8 more; far from you and from any fight, the bands' own
## rule, he can tick slowly through it). Not with your gun on him or his hands up, flinching from a
## deed, running from a fire or in a bucket line, about to shout, or at a chore that has his hands
## (the bar cloth, the mop: they move what the physics holds).
func can_slow() -> bool:
	return slow_reason() == &""


const MOOD_NAMES: Array[StringName] = [&"calm", &"shaken", &"hands_up", &"cowering", &"down", &"dead", &"fleeing"]


## Why he can't slow (the first of `can_slow`'s rules he fails; &"" when he can): for PeopleTick's
## counts (#495).
func slow_reason() -> StringName:
	if mood not in [Mood.CALM, Mood.SHAKEN, Mood.COWERING]:
		return MOOD_NAMES[mood]
	if _aimed > 0.0:
		return &"aimed"
	if _flinch > 0.0:
		return &"flinch"
	if not _route.is_empty():
		return &"route"
	if _bucket != &"":
		return &"bucket"
	if _shout_in > 0.0:
		return &"shout"
	if chore != null and chore.call(&"busy"):
		return &"chore"
	return &""


## Hands up or aimed at, running from a fire or fighting it (PeopleTick: whoever's near him ticks
## every tick too). Cowering isn't trouble of his own (#495): it's from a shot or a blast, and the
## shooting's own men are the trouble.
func in_trouble() -> bool:
	return mood in [Mood.HANDS_UP, Mood.FLEEING] or _aimed > 0.0 or _bucket != &""


func _physics_step(delta: float) -> void:
	var p := body.physiology
	if not p.alive:
		mood = Mood.DEAD
		return
	if body.limp:
		mood = Mood.DOWN
		return
	if mood == Mood.DOWN:
		# Back on his feet (HumanBody.get_up): shaken by it.
		mood = Mood.SHAKEN
	if body.stumbling > 0.0:
		return  # going down: his last steps are his body's, not his
	if _mind_fire(delta):
		_chore(delta, false)
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
		_chore(delta, false)
		mood = Mood.HANDS_UP
		_calm_for = 0.0
		body.face(_aimed_by.global_position + Vector3.UP * 1.5)
		body.set_pose(&"hands_up")
		if _say_again <= 0.0:
			say(&"beg")
			_say_again = _rng.randf_range(5.0, 8.0)
		return
	if _cower > 0.0:
		_chore(delta, false)
		mood = Mood.COWERING
		_calm_for = 0.0
		body.set_pose(&"cower")
		return
	if _flinch > 0.0:
		_chore(delta, false)
		body.set_pose(&"hands_up" if _flinch > 0.5 else &"stand")
		return
	if mood in [Mood.HANDS_UP, Mood.COWERING]:
		mood = Mood.SHAKEN
		if not _still_over_me():
			say(&"relief")
	_calm_for += delta
	if mood == Mood.SHAKEN and _calm_for > 6.0 and fear < 0.2:
		mood = Mood.CALM
	if _chore(delta, mood == Mood.CALM and fear < 0.05 and not (helped_by and not thanked)):
		return
	if post != Vector3.INF and body.global_position.distance_to(post) > 0.3:
		body.set_pose(&"stand")
		# Far off (a chore, a fright took him across the room): back by the town's places, round
		# whatever's between (a bar); near, straight there.
		if body.global_position.distance_to(post) > 1.5 and _places() != null:
			if _home_route.is_empty():
				_home_route = FireFlight.route(_places(), body, post)
			if body.walk_to(_home_route[0], 1.2, delta) and _home_route.size() > 1:
				_home_route.pop_front()
		else:
			_home_route.clear()
			body.walk_to(post, 1.2, delta)
		return
	_home_route.clear()
	body.set_pose(rest_pose)
	_thank(delta)
	if faces != Vector3.INF and not (helped_by and not thanked):
		body.face(faces)


## His chores: the one at it has him while it's busy; else each in turn may start (the first that
## does has him). Not `free`, every one stops. True while one has him this tick.
func _chore(delta: float, free: bool) -> bool:
	if chore != null and not chores.has(chore):
		chores.append(chore)
	for c: RefCounted in chores:
		if c.call(&"busy"):
			chore = c
			return c.call(&"step_chore", delta, free)
	for c: RefCounted in chores:
		if c.call(&"step_chore", delta, free):
			chore = c
			return true
	return false


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
