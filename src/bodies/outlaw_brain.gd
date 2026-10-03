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
## With friends (a gang) they fight together, by shouting to each other (Events.callout) and what
## each one sees (Crew): "Reloading! Cover me!" and a friend comes up shooting at where you were;
## one keeps you busy while another goes round; a friend down in the open gets dragged to cover;
## and when one goes down or quits, it goes through the rest of them (a hothead's rage, a green
## one's nerve going, "Fall back!", the leader throwing his gun down and the rest following).
## Child of a HumanBody.

signal mood_changed(mood: Mood)
## He's walked out of town (and is about to be gone).
signal left_town

enum Mood { CALM, FIGHTING, RELOADING, SURRENDERED, DOWN, DEAD, FLEEING, TENDING }
## In a fight: in the open, on his way to cover, hidden behind it, up and shooting from it.
enum Tactic { OPEN, MOVING, HIDDEN, PEEKING, SEARCHING, RESCUING }

const LINES := {
	&"provoked": ["You damn fool!", "Your funeral, friend.", "That's how it is? Fine!"],
	&"hit": ["Agh—!", "Son of a—!", "I'm hit, damn it!"],
	&"gut": ["Oh God, not the belly..."],
	&"surrender": ["Alright! Alright! I'm done!", "Don't shoot! I quit, I quit!", "Enough! It's yours!"],
	&"down": ["My leg... damn you...", "Can't... get up..."],
	&"shot_while_surrendered": ["I give up, you bastard!", "I'm unarmed!"],
	&"reloading": ["Hold still..."],
	&"flee": ["To hell with this!", "I ain't dying for this!", "I'm gone!"],
	&"wary": ["Easy, friend.", "Something I can do for you?", "Help you?"],
	&"warning": ["Keep that iron where it is.", "That's close enough.", "Walk on, mister.", "Don't make it a problem."],
	&"threat": ["Don't you do it.", "Put it down, or I put you down.", "One more move..."],
	&"stand_down": ["That's better.", "Smart.", "Go on, then."],
	&"search": ["Where'd he go?", "Come on out!", "I know you're there."],
	&"lost": ["...Gone.", "Damn it. Lost him."],
	&"tend": ["Damn, damn...", "Hold it together..."],
	&"drink": ["Whiskey. Leave the bottle.", "Another.", "This the best you got?"],
	&"taunt": ["Hurry it up, old man.", "What's the matter, Pop? Hands shaking?",
			"Nice store. Shame if something happened to it.", "You got a problem with my money?",
			"Put it on my tab. What tab? That's a good one."],
	&"rob": ["Open the drawer. Slow.", "The cash box, Pop. Now."],
	&"done_harass": ["Pleasure doing business.", "We'll be back, Pop."],
	&"back_down": ["Alright. Alright. It ain't worth it.", "Another time, mister.", "You win. For now."],
	&"call_out": ["You! Step out into the street!", "I'm calling you out, mister! Out here!"],
	&"coward": ["Coward! Whole town seen it!", "Yellow. Figured as much."],
	&"duel": ["Whenever you're ready.", "Go on. Make your play."],
	&"accept": ["Suits me.", "Alright. Right here, then."],
	&"refuse": ["Not today.", "I got no quarrel with you. Yet."],
	# Shouted to his friends in a fight ({name}: the friend it's about).
	&"call_reloading": ["Reloading! Cover me!", "I'm empty! Cover me!"],
	&"call_hit": ["I'm hit! I'm hit!", "He got me!"],
	&"call_spotted": ["There he is!", "Over there!", "I see him!"],
	&"call_flank": ["Keep him busy, I'm going round!", "Cover me, I'll get round him!"],
	&"call_covering": ["Go! I got him!", "Covering!", "Go on, I got you!"],
	&"call_help": ["I can't walk! Help me!", "My leg! Get me out of here!"],
	&"call_drag": ["Hold on, I got you!", "Easy, I got you. Come on!"],
	&"call_down": ["{name}'s down!", "They got {name}!"],
	&"call_dead": ["{name}'s dead!", "Oh God, {name}..."],
	&"call_quit": ["{name}'s quit on us!", "{name}'s giving up!"],
	&"call_fall_back": ["Get out! Fall back!", "That's it, we're done here! Run!"],
	&"call_give_up": ["That's it, boys. Throw 'em down.", "Enough! We're done. Drop 'em."],
	&"scorn": ["Get up, you yellow dog!", "{name}! Pick up that gun!"],
	&"rage": ["You'll pay for that!", "You son of a bitch! Come on!"],
	&"watch_it": ["Watch where you're shooting!", "Hey! That was me!"],
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
## How little it takes to rile him (0 a cool professional .. 1 a hothead): the small things,
## a stare, crowding him, a drawn gun near him.
@export var temper := 0.5
## Men whose troubles are his troubles (person ids).
@export var friends: Array[StringName] = []
## How far off he judges a range (one standard deviation, a share of it): he holds over for the
## drop at the range he thinks it is.
@export var range_judgement := 0.12
## Running and walking speeds (m/s), before wounds.
@export var run_speed := 3.8
@export var walk_speed := 1.4
## Bleeding this hard (ml/s) and not being shot at for this long (s), he stops to tend it.
@export var tend_bleed := 0.8
@export var tend_quiet := 3.0
## Faced down, he backs off now and calls the man out later.
@export var proud := false
## How long he sulks over a drink before he comes looking for the man who faced him down (s).
@export var sulk_seconds := 60.0
## He runs the gang: his "Fall back!" and his giving up carry the others with him.
@export var leads := false

## Where he can go in this town (set by whoever brought him in: TownLife), and his place at the bar.
var places: Waypoints
var bar_spot := &""
## What he means to do, in order. Steps: {do: &"go", to: <place>}, {do: &"drink", seconds, face},
## {do: &"harass", who, seconds, rough}, {do: &"call_out", who}, {do: &"duel", who},
## {do: &"wait", seconds}, {do: &"leave"}. He gets on with it while nobody's troubling him.
var agenda: Array[Dictionary] = []

var body: HumanBody
var mood := Mood.CALM
var fear := 0.0
var rounds := 5
var target: Node3D

var _rng := RandomNumberGenerator.new()
## Separate from his aim, so choosing where to hide doesn't change how he shoots.
var _think := RandomNumberGenerator.new()
## His judgement of range (separate again, so it doesn't shift his aim's sequence).
var _range_rng := RandomNumberGenerator.new()
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
var senses: Senses
var relations: Relations
## The rung he's on with the man he's watching, last tick (to speak when it changes).
var _social_stance := Relations.Stance.IGNORE
var _social_who: Node
var _say_again := 0.0
var _aim_deed := 0.0
var _search_time := 0.0
var _look_round := 0.0
var _retarget := 0.0
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
var _route: Array[Vector3] = []
var _step_time := 0.0
var _step_started := false
var _pose_until := 0.0
var _step_deed := 0.0
## A duel: he stands and shoots it out, no ducking behind things.
var _stand_and_fight := false
## Seconds since someone told him to drop it.
var _drop_it_heard := 99.0
## His friends in a fight, as he knows them.
var crew: Crew
## His own clock (s), for what he heard when.
var _now := 0.0
## Covering a friend: seconds left keeping the man busy (up and shooting where he was, seen or not).
var covering := 0.0
## Going round on the man (a flank) with friends covering him: called once the spot's found.
var _flanking := false
## Where he last shouted the man was, and how soon he'll shout it again.
var _called_at := Vector3.INF
var _spot_call := 0.0
## Seconds of fury (a friend shot down in front of him): he stands and shoots it out.
var rage := 0.0
## Something he heard that'll break him in a moment: &"flee" or &"surrender".
var _pending_break := &""
var _pending_in := 0.0
## Getting a friend out of the line of fire: who, where to, and how it's going (0 going to him,
## 1 dragging him).
var rescuing: HumanBody
var _rescue_to := Vector3.INF
var _rescue_phase := 0
var _rescue_time := 0.0
var _rescue_goal := Vector3.INF
## Friends he went for and couldn't get to (or get out): when.
var _tried_rescue := {}
var _rescue_best := INF
var _gang_check := 0.0


func _ready() -> void:
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 31 + 7
	_think.seed = body.rng_seed * 17 + 3
	_range_rng.seed = body.rng_seed * 23 + 11
	rounds = rounds_per_load
	senses = Senses.new()
	senses.name = "Senses"
	body.add_child.call_deferred(senses)
	relations = Relations.new(body, temper)
	relations.friends = friends
	crew = Crew.new(body, friends)
	Events.callout.connect(_on_callout)
	Events.person_fell.connect(_on_person_fell)
	Events.person_died.connect(func(who: Node, _c: StringName) -> void: _saw_mate_out(who, &"dead"))
	Events.person_surrendered.connect(func(who: Node) -> void: _saw_mate_out(who, &"quit"))
	senses.spotted.connect(_on_spotted)
	Events.deed.connect(_on_deed)
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


func say(kind: StringName, about_name := "") -> void:
	var lines: Array = LINES.get(kind, [])
	var p := body.physiology
	if lines.is_empty() or not p.is_conscious():
		return
	if p.airway_blood:
		Events.spoke.emit(body, "Hhhk— hhk—")  # blood in his windpipe: no words left
	elif p.jaw_broken:
		Events.spoke.emit(body, "Nnngh! Nnnh!")
	else:
		Events.spoke.emit(body, String(lines[_rng.randi() % lines.size()]).format({"name": about_name}))


func _set_mood(m: Mood) -> void:
	if mood != m:
		mood = m
		mood_changed.emit(m)


## Who he's fighting (null when he isn't).
func _find_target() -> Node3D:
	if target != null and not is_instance_valid(target):
		target = null
	return target


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


# --- What he makes of people ------------------------------------------------------------------

## He's just picked someone out: if the man's got a gun in his hand, that's the first thing he sees.
func _on_spotted(who: Node3D) -> void:
	if _armed(who) and not relations.entry(who).armed:
		var close := who.global_position.distance_to(body.global_position) < NEAR
		relations.perceive(who, &"draw", body if close else null)


## Near enough that a drawn gun is his business.
const NEAR := 12.0


static func _armed(who: Node) -> bool:
	if who is Player:
		var w := (who as Player).weapon
		return w != null and w.selected and w.drawn
	if who is HumanBody:
		var h := who as HumanBody
		return h.held_gun != null and not h.gun_holstered
	return false


## Someone did something. He only judges it if he perceived it: saw them do it, or it was loud
## (a shot, a hit), or it was done to him and he knows they're there.
func _on_deed(actor: Node, kind: StringName, deed_target: Node, _at: Vector3) -> void:
	if actor == null or actor == body or senses == null or not body.physiology.is_conscious():
		return
	var loud := kind in [&"shoot_at", &"hit", &"kill"]
	var to_me := deed_target == body
	# Words shouted at him he hears whether he can see who it is or not.
	var shouted := kind in [&"shout", &"call_out"] and to_me
	if not loud and not shouted and not senses.sees(actor) and not (to_me and senses.aware_of(actor) > 0.6):
		return
	if shouted and not senses.sees(actor) and actor is Node3D:
		senses.note(actor, (actor as Node3D).global_position, 1.5)
	if loud and not to_me and not senses.sees(actor) and not senses.knows(actor):
		# A shot somewhere: he knows someone's shooting, not who, unless he's seen them.
		if kind != &"hit":
			return
	if loud and actor is Node3D and not senses.sees(actor):
		# He knows which way it came from, roughly.
		senses.note(actor, (actor as Node3D).global_position, 0.1 * body.global_position.distance_to((actor as Node3D).global_position))
	var dt := PlayerDeeds.EVERY if kind in [&"aim_at", &"crowd", &"stare"] else 1.0
	if kind in [&"draw", &"holster"] and deed_target == null and actor is Node3D \
			and (actor as Node3D).global_position.distance_to(body.global_position) < NEAR:
		deed_target = body  # a gun drawn a few yards off is about him
	relations.perceive(actor, kind, deed_target, dt)
	if to_me and kind == &"aim_at" and not relations.entry(actor).cowed:
		fear += 0.045 * dt * (1.5 if _facing_shotgun else 1.0)
	if to_me and kind == &"call_out":
		_answer_call_out(actor)


# --- What frightens him ------------------------------------------------------------------------

func _provoked(by: Node) -> void:
	if by == null or by == body or not (by is Player or by is HumanBody):
		return
	if crew.is_mate(by):
		# A friend's stray round: he cusses him, he doesn't fight him.
		if crew.may_say(&"watch_it", _now, 6.0):
			say(&"watch_it")
		return
	relations.provoke(by)
	_start_fight(by)


func _start_fight(with_who: Node) -> void:
	if with_who == null or not is_instance_valid(with_who):
		return
	if mood == Mood.CALM:
		say(&"provoked")
		_set_mood(Mood.FIGHTING)
		_next_shot = _rng.randf_range(0.6, 1.1)
		tactic = Tactic.OPEN
		_cover_search = 0.0
	target = with_who as Node3D
	if not senses.knows(with_who):
		# It's come to a fight with him: he knows which way he is, at least.
		senses.note(with_who, (with_who as Node3D).global_position, 1.0)
	if body.gun_holstered:
		body.draw_gun()


func _on_near_miss(person: Node, shooter: Node, distance: float, _at: Vector3, _speed: float, _tumbling: bool) -> void:
	if person != body:
		return
	fear += 0.06 * clampf(2.5 - distance, 0.5, 2.5)
	if shooter is Node3D and senses and not senses.sees(shooter):
		senses.note(shooter, (shooter as Node3D).global_position, 0.1 * body.global_position.distance_to((shooter as Node3D).global_position))
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
			if info.get("shooter") != null:
				_provoked(info.shooter)
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
	if info.get("shooter") != null:
		_provoked(info.shooter)
	if mood in [Mood.FIGHTING, Mood.RELOADING] and crew.any_in_earshot(_now) and not crew.is_mate(info.get("shooter")):
		callout(&"hit", _find_target())
	elif mood != Mood.CALM:
		say(&"hit")
	if not _said_gut and body.physiology.gut_seconds >= 0.0:
		_said_gut = true
		say(&"gut")
	for h: Dictionary in info.hits:
		if h.effect == &"broken":
			fear += 0.1


func _on_fell(conscious: bool) -> void:
	if conscious and body.prone and mood in [Mood.FIGHTING, Mood.RELOADING] and crew.any_in_earshot(_now):
		callout(&"help", _find_target())
	elif conscious:
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


## "Drop it!" from someone aiming at him: frightening in proportion to how things are going.
func _on_shouted(speaker: Node, kind: StringName) -> void:
	if kind != &"drop_it" or not speaker is Node3D or mood in [Mood.SURRENDERED, Mood.DOWN, Mood.DEAD]:
		return
	var d := (speaker as Node3D).global_position.distance_to(body.global_position)
	if d > 30.0:
		return
	_drop_it_heard = 0.0
	fear += 0.08 + (0.22 if _aimed_at > 0.3 else 0.0) + body.physiology.wounds * 0.08
	if _facing_shotgun and _aimed_at > 0.3:
		fear += 0.12
	if mood == Mood.CALM:
		fear += 0.1  # caught cold with a gun on him


# --- Living ------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"outlaw_brain", t)


func _physics_step(delta: float) -> void:
	var p := body.physiology
	if not p.alive:
		_set_mood(Mood.DEAD)
		return
	if body.limp:
		_set_mood(Mood.DOWN)
		return
	_now += delta
	if body.dragged_by != null:
		var helper := Crew.brain_of(body.dragged_by)
		if helper != null and helper.rescuing == body and helper.body.physiology.is_conscious():
			# A friend's got him by the collar: he holds on and lets himself be pulled.
			body.set_pose(&"prone")
			return
		body.dragged_by = null
	_update_aimed_at(delta)
	_quiet += delta
	_drop_it_heard += delta
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
	if _pending_break != &"":
		_pending_in -= delta
		if _pending_in <= 0.0 or fear > nerve:
			var how := _pending_break
			_pending_break = &""
			if how == &"surrender":
				_surrender()
				return
			if body.physiology.can_run() and not body.prone:
				_start_fleeing()
				return
	if fear > nerve:
		_break()
		return
	relations.tick(delta)
	_pick_fight(delta)
	match mood:
		Mood.CALM:
			if _can_go_about():
				_go_about(delta)
			else:
				_social(delta)
		Mood.FIGHTING, Mood.RELOADING:
			_combat(delta)


## Who (if anyone) he's fighting: whoever it's come to that with. Keeps to the man in front of him
## unless another one he can see is the bigger danger; stops when his man is down, dead, has given
## up, or is gone.
func _pick_fight(delta: float) -> void:
	_retarget -= delta
	var t := _find_target()
	if t != null and _done_with(t):
		relations.stand_down(t)
		target = null
		t = null
	if t != null and _retarget > 0.0:
		return
	_retarget = 1.0
	var best: Node = null
	var best_p := -1.0
	for who in relations.entries:
		if not is_instance_valid(who) or relations.stance(who) != Relations.Stance.FIGHT or _done_with(who):
			continue
		var p: float = relations.entries[who].pressure + (1.0 if senses.sees(who) else 0.0) + (0.5 if who == t else 0.0)
		if p > best_p:
			best = who
			best_p = p
	if best != null:
		_start_fight(best)
	elif t == null and mood != Mood.CALM:
		_set_mood(Mood.CALM)
		tactic = Tactic.OPEN
		_after_fight()


## Is that man out of it (dead, down and out, or given up)?
func _done_with(who: Node) -> bool:
	if who == null or not is_instance_valid(who):
		return true
	if who is Player:
		return not (who as Player).wounds.physiology.is_conscious()
	if who is HumanBody:
		var h := who as HumanBody
		if not h.physiology.is_conscious() or not h.physiology.alive:
			return true
		var b := h.get_node_or_null(^"Brain") as OutlawBrain
		return b != null and b.mood == Mood.SURRENDERED
	return false


## Not fighting: the ladder with whoever he's watching. He looks at a man who's caught his eye;
## wary, he squares up with his hand by the holster; he warns; he draws and covers him; he steps
## back down when the man does.
func _social(delta: float) -> void:
	_reload_quietly(delta)
	var who := relations.focus()
	var st := relations.stance(who) if who else Relations.Stance.IGNORE
	if who != _social_who or st != _social_stance:
		_on_rung(_social_stance, st)
		_social_who = who
		_social_stance = st
	_say_again -= delta
	var point := senses.last_known(who) if who else Vector3.INF
	match st:
		Relations.Stance.IGNORE:
			body.set_pose(&"stand")
			_ease_off(delta)
		Relations.Stance.NOTICE:
			if point != Vector3.INF:
				body.face(point + Vector3.UP * 1.4)
			body.set_pose(&"stand")
			_ease_off(delta)
		Relations.Stance.WARY, Relations.Stance.WARNING:
			if point != Vector3.INF:
				body.face(point + Vector3.UP * 1.4)
			body.set_pose(&"wary")
			if st == Relations.Stance.WARNING and _say_again <= 0.0:
				say(&"warning")
				_say_again = 7.0
			_ease_off(delta)
		Relations.Stance.THREAT:
			# Covering him: gun out and on him, not firing unless it comes to it.
			if body.gun_holstered:
				body.draw_gun()
				Events.deed.emit(body, &"draw", who, body.global_position)
			var aim := _aim_point(who as Node3D)
			body.face(aim)
			body.set_pose(&"aim")
			_aim_deed -= delta
			if _aim_deed <= 0.0:
				_aim_deed = PlayerDeeds.EVERY
				Events.deed.emit(body, &"aim_at", who, senses.eye())
			if _say_again <= 0.0:
				say(&"threat")
				_say_again = 6.0


## An empty gun gets reloaded while it's quiet.
func _reload_quietly(delta: float) -> void:
	if rounds < rounds_per_load:
		if _reload_left <= 0.0:
			_reload_left = reload_seconds
		_reload_left -= delta
		if _reload_left <= 0.0:
			rounds = rounds_per_load


## Stepping onto a new rung: say so.
func _on_rung(from: Relations.Stance, to: Relations.Stance) -> void:
	if to > from:
		match to:
			Relations.Stance.WARY:
				say(&"wary")
			Relations.Stance.WARNING:
				say(&"warning")
				_say_again = 7.0
			Relations.Stance.THREAT:
				say(&"threat")
				_say_again = 6.0
	elif from >= Relations.Stance.WARNING and to < from:
		say(&"stand_down")
		_say_again = 5.0


var _calm_for := 0.0


## Calm again for a while: the gun goes back in the holster.
func _ease_off(delta: float) -> void:
	if body.gun_holstered:
		_calm_for = 0.0
		return
	_calm_for += delta
	if _calm_for > 3.0:
		body.holster_gun()
		Events.deed.emit(body, &"holster", null, body.global_position)
		_calm_for = 0.0


## How long the player has been aiming his way (seconds, decays).
func _update_aimed_at(delta: float) -> void:
	var t := _player()
	var gun: Variant = (t as Player).weapon if t is Player else null
	var aiming := false
	if gun is WeaponViewmodel and (gun as WeaponViewmodel).drawn:
		var cam := (gun as Node3D).get_parent() as Node3D
		var to := body.global_position + Vector3.UP * 1.2 - cam.global_position
		var fwd := -cam.global_transform.basis.z
		aiming = fwd.angle_to(to) < deg_to_rad(8.0)
	_aimed_at = clampf(_aimed_at + (delta if aiming else -delta * 0.5), 0.0, 3.0)
	_facing_shotgun = aiming and gun is ShotgunViewmodel


# --- Going about his day -------------------------------------------------------------------------

## Nobody's troubling him (nobody he's squared up to, bar a man he's already backed down from),
## or he's in the middle of calling someone out: he gets on with what he came to do.
func _can_go_about() -> bool:
	if agenda.is_empty():
		return false
	if agenda[0].do in [&"call_out", &"duel"]:
		return true
	for who in relations.entries:
		var e: Dictionary = relations.entries[who]
		if is_instance_valid(who) and e.stance >= Relations.Stance.WARY and not e.cowed:
			return false
	return true


func _go_about(delta: float) -> void:
	_reload_quietly(delta)
	var step: Dictionary = agenda[0]
	if not _step_started:
		_begin_step(step)
	_step_time += delta
	_say_again -= delta
	var done := false
	match step.do:
		&"go":
			done = _walk_route(delta, walk_speed)
			_ease_off(delta)
		&"wait":
			body.set_pose(&"stand")
			if step.has("face"):
				body.face(step.face)
			done = _step_time >= float(step.get("seconds", 5.0))
			_ease_off(delta)
		&"drink":
			done = _drink(step)
			_ease_off(delta)
		&"harass":
			done = _harass(delta, step)
		&"leave":
			if _walk_route(delta, walk_speed):
				left_town.emit()
				body.queue_free()
				agenda.clear()
				return
			_ease_off(delta)
		&"call_out":
			done = _call_out(delta, step)
		&"duel":
			done = _duel(step)
		_:
			done = true
	if done and not agenda.is_empty() and agenda[0] == step:
		_next_step()


func _next_step() -> void:
	agenda.pop_front()
	_step_started = false


## Starting on a step: work out the way there.
func _begin_step(step: Dictionary) -> void:
	_step_started = true
	_step_time = 0.0
	_route = []
	_stuck = 0.0
	_last_pos = body.global_position
	var space := body.get_world_3d().direct_space_state
	match step.do:
		&"go":
			if places and places.has(step.to):
				_route = places.route(space, body.global_position, step.to, _exclude())
		&"leave":
			if places:
				_route = places.route(space, body.global_position, &"west_edge", _exclude())
		&"drink":
			if step.get("first", true):
				_say_again = _think.randf_range(1.0, 4.0)


## Along the way he worked out; true when he's there. Stuck on something, he tries the next point.
func _walk_route(delta: float, speed: float) -> bool:
	if _route.is_empty():
		return true
	body.set_pose(&"stand")
	var arrived := body.walk_to(_route[0], speed, delta)
	_watch_stuck(delta)
	if arrived or _stuck > 2.0:
		_route.pop_front()
		_stuck = 0.0
	return _route.is_empty()


## At the bar: leaning on it, a word to the barkeep now and then.
func _drink(step: Dictionary) -> bool:
	body.set_pose(&"stand")
	if step.has("face"):
		body.face(step.face)
	if _say_again <= 0.0:
		say(&"drink")
		_say_again = _think.randf_range(20.0, 40.0)
	return _step_time >= float(step.get("seconds", 30.0))


## Leaning on a man who can't answer back: taunts, a shove across the counter, and a rough one
## draws on him and has him open the cash box. Anyone who objects gets the ladder (above).
func _harass(delta: float, step: Dictionary) -> bool:
	var who := step.get("who") as HumanBody
	if who == null or not is_instance_valid(who) or not who.physiology.is_conscious():
		return true
	var chest := (who.parts[&"chest"] as Node3D).global_position if who.parts.has(&"chest") else who.global_position + Vector3.UP * 1.2
	body.face(chest)
	var now := _step_time
	if _say_again <= 0.0:
		say(&"taunt")
		_say_again = _think.randf_range(6.0, 9.0)
	if not step.get("shoved", false) and now > 4.0:
		step.shoved = true
		_pose_until = now + 0.7
		Events.deed.emit(body, &"shove", who, body.global_position)
	var rough: bool = step.get("rough", false) and now > float(step.get("draw_after", 14.0))
	if rough and body.held_gun != null:
		if body.gun_holstered:
			body.draw_gun()
			Events.deed.emit(body, &"draw", who, body.global_position)
			say(&"rob")
			_say_again = 8.0
		body.set_pose(&"aim")
		_step_deed -= delta
		if _step_deed <= 0.0:
			_step_deed = PlayerDeeds.EVERY
			Events.deed.emit(body, &"aim_at", who, senses.eye())
	else:
		body.set_pose(&"shove" if now < _pose_until else &"stand")
	if now >= float(step.get("seconds", 45.0)):
		say(&"done_harass")
		_say_again = 6.0
		if not body.gun_holstered:
			body.holster_gun()
			Events.deed.emit(body, &"holster", null, body.global_position)
		return true
	return false


## Out into the street, down it from wherever the man is, and shout for him. When he comes out
## where they can see each other, it's a duel; if he doesn't come, the whole town hears why.
func _call_out(delta: float, step: Dictionary) -> bool:
	var who := step.get("who") as Node3D
	if who == null or not is_instance_valid(who) or _done_with(who):
		return true
	if not step.has("spot"):
		var p := senses.last_known(who)
		if p == Vector3.INF:
			p = who.global_position  # he asks round town; somebody tells him
		step.spot = _street_spot(p)
		var space := body.get_world_3d().direct_space_state
		_route = []
		if places:
			_route = places.route_to_point(space, body.global_position, step.spot, _exclude())
		if _route.is_empty():
			_route.append(step.spot)
		relations.uncow(who)
	if not _route.is_empty():
		_walk_route(delta, walk_speed)
		return false
	var lk := senses.last_known(who)
	body.face((lk if lk != Vector3.INF else who.global_position) + Vector3.UP * 1.5)
	body.set_pose(&"wary")
	step.waited = float(step.get("waited", 0.0)) + delta
	if _say_again <= 0.0:
		say(&"call_out")
		Events.shouted.emit(body, &"call_out")
		Events.deed.emit(body, &"call_out", who, body.global_position)
		_say_again = 12.0
	if senses.sees(who) and body.global_position.distance_to(who.global_position) < 30.0:
		agenda.insert(1, {"do": &"duel", "who": who})
		return true
	if float(step.waited) > float(step.get("patience", 60.0)):
		say(&"coward")
		return true
	return false


## A spot out in the street, down it from `p` (a dozen paces, toward where he is now).
func _street_spot(p: Vector3) -> Vector3:
	var street_z := -9.0
	var side := signf(body.global_position.x - p.x)
	if side == 0.0:
		side = 1.0
	var x := p.x + side * 12.0
	if x > 14.0 or x < -30.0:
		x = p.x - side * 12.0
	return Vector3(clampf(x, -30.0, 14.0), 0.0, street_z + _think.randf_range(-1.0, 1.0))


## Face to face in the open, hand by the holster. He goes for his gun when you go for yours, or
## when he's tired of waiting; then it's a straight fight, standing up.
func _duel(step: Dictionary) -> bool:
	var who := step.get("who") as Node3D
	if who == null or not is_instance_valid(who) or _done_with(who):
		return true
	if not step.has("draw_at"):
		step.draw_at = _think.randf_range(2.5, 5.0)
		if not senses.knows(who):
			senses.note(who, who.global_position, 1.0)  # he's squaring up to him: he knows where he is
		say(&"duel")
		_say_again = 99.0
	body.face(_eye_of(who))
	body.set_pose(&"wary")
	if _armed(who) or _step_time >= float(step.draw_at):
		_stand_and_fight = true
		relations.provoke(who)
		_start_fight(who)
		return true
	if body.global_position.distance_to(who.global_position) > 45.0 or senses.since_known(who) > 10.0:
		say(&"coward")
		return true
	return false


## Faced down before it came to shooting: holsters, lets it go for now, and gives up whatever he
## was about. A proud man drinks on it and then comes looking for you.
func _back_down(by: Node) -> void:
	say(&"back_down")
	relations.back_down(by)
	fear = minf(fear, nerve * 0.6)
	if body.held_gun != null and not body.gun_holstered:
		body.holster_gun()
		Events.deed.emit(body, &"holster", by, body.global_position)
	Events.deed.emit(body, &"back_down", by, body.global_position)
	var plan: Array[Dictionary] = []
	if places and bar_spot != &"":
		plan.append({"do": &"go", "to": bar_spot})
		plan.append({"do": &"drink", "seconds": sulk_seconds, "face": places.at(bar_spot) + Vector3(-2.0, 1.2, 0.0)})
	elif proud:
		plan.append({"do": &"wait", "seconds": sulk_seconds})
	if proud:
		plan.append({"do": &"call_out", "who": by})
	if places:
		plan.append({"do": &"leave"})
	agenda = plan
	_step_started = false


## Someone's called him out. A man with any temper, or a grudge against the caller, accepts.
func _answer_call_out(caller: Node) -> void:
	if mood != Mood.CALM or not caller is Node3D:
		return
	if not agenda.is_empty() and agenda[0].do in [&"duel", &"call_out"]:
		return
	var e := relations.entry(caller)
	if temper >= 0.4 or e.grudge > 0.2 or proud:
		say(&"accept")
		relations.uncow(caller)
		agenda.push_front({"do": &"duel", "who": caller})
		_step_started = false
	else:
		say(&"refuse")


## A fight's over and he's still standing: he's done with this town for today.
func _after_fight() -> void:
	_stand_and_fight = false
	_stop_rescue()
	covering = 0.0
	rage = 0.0
	if places:
		agenda = [{"do": &"leave"}]
		_step_started = false


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
	covering = maxf(covering - delta, 0.0)
	rage = maxf(rage - delta, 0.0)
	_gang(delta, t)
	if tactic == Tactic.RESCUING:
		_rescue(delta, t)
		return
	if rage > 0.0 and not body.prone:
		_rage_fight(delta, t)
		return
	var eye := _eye_of(t)
	# Lost sight of him for a while: go and look where he was.
	if not senses.sees(t) and senses.since_known(t) > 4.0 and tactic in [Tactic.OPEN, Tactic.HIDDEN] and not body.prone:
		tactic = Tactic.SEARCHING
		_search_time = 0.0
		_look_round = 0.0
		say(&"search")
	if tactic == Tactic.SEARCHING:
		_hunt(delta, t)
		return
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
			if _cover_search <= 0.0 and not _stand_and_fight:
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


## Where he thinks the man's eyes are: where they are if he can see him, else where he last knew.
func _eye_of(t: Node3D) -> Vector3:
	if not senses.sees(t):
		var p := senses.last_known(t)
		if p != Vector3.INF:
			return p + Vector3.UP * 1.6
	if t is Player:
		return (t as Player).camera.global_position
	if t is HumanBody and (t as HumanBody).parts.has(&"head"):
		return ((t as HumanBody).parts[&"head"] as Node3D).global_position
	return t.global_position + Vector3.UP * 1.6


## Looking for a man he's lost: to where he last saw him, then a look round; in the end he gives
## it up and stays wary.
func _hunt(delta: float, t: Node3D) -> void:
	_search_time += delta
	if senses.sees(t):
		tactic = Tactic.OPEN
		_cover_search = 0.0
		return
	var spot := senses.last_known(t)
	if _search_time > 25.0 or spot == Vector3.INF:
		say(&"lost")
		relations.stand_down(t)
		target = null
		_set_mood(Mood.CALM)
		tactic = Tactic.OPEN
		_after_fight()
		return
	var flat := Vector3(spot.x, body.global_position.y, spot.z)
	body.set_pose(&"aim")
	if body.global_position.distance_to(flat) > 1.5:
		body.walk_to(flat, walk_speed * 1.3, delta)
	else:
		# There: turn about, looking.
		_look_round += delta
		body.global_rotation.y += delta * 1.2
		body.aim_pitch = 0.0


func _exclude(t: Node3D = null) -> Array[RID]:
	var out: Array[RID] = []
	for sid: StringName in body.parts:
		out.append((body.parts[sid] as CollisionObject3D).get_rid())
	if t is CollisionObject3D:
		out.append((t as CollisionObject3D).get_rid())
	return out


## Start looking for somewhere to fight from (spread over a few ticks); `bias_from` a spot he's
## leaving, for a new angle on you.
func _seek_cover(eye: Vector3, bias_from: Vector3, max_travel := 11.0, new_angle := 3.0) -> void:
	if _search != null:
		return
	_search = Cover.search(body.get_parent() as Node3D, body.global_position, eye, _exclude(_find_target()), _think, bias_from,
			max_travel, new_angle)
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
	if tactic == Tactic.PEEKING or tactic == Tactic.RESCUING:
		_flanking = false
		return  # he'll go next time he's down
	if _flanking:
		_flanking = false
		if crew.someone_flanking(_now):
			return
		callout(&"flank", _find_target(), spot.at)
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
		if crew.someone_flanking(_now):
			pass  # a friend's going round: he stays and keeps the man busy
		else:
			# With friends there to keep the man's head down, he goes right round on him.
			_flanking = crew.any_in_earshot(_now) and mood == Mood.FIGHTING
			_seek_cover(eye, cover.at, FLANK_TRAVEL if _flanking else 11.0, FLANK_ANGLE if _flanking else 3.0)
	if covering > 0.0 and suppressed <= 0.0:
		_tactic_time = minf(_tactic_time, 0.25)
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
			_start_reload()
			_duck_back()
			return
		if not _can_shoot_at(t):
			_next_shot = 0.2
			return
		_fire_at(aim_point, t)
		_peek_shots += 1
		var p := body.physiology
		_next_shot = seconds_between_shots * _rng.randf_range(0.6, 1.0) + p.shock() + p.felt_pain() * 0.4
	if covering > 0.0:
		# Keeping the man busy for a friend: up longer, more rounds.
		if _peek_shots >= 3 and _next_shot > 0.3 or _peek_time > 4.5 or rounds <= 1:
			_duck_back()
	elif _peek_shots >= 1 + (_think.randi() % 2) and _next_shot > 0.3 or _peek_time > 3.0:
		_duck_back()


func _duck_back() -> void:
	if tactic != Tactic.PEEKING:
		return
	tactic = Tactic.HIDDEN
	_peeks += 1
	_tactic_time = _think.randf_range(0.3, 0.8) if covering > 0.0 else _think.randf_range(1.2, 3.0)
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
		_start_reload()
		return
	if not _can_shoot_at(t):
		_next_shot = 0.2
		return
	_fire_at(aim_point, t)
	var p := body.physiology
	_next_shot = seconds_between_shots * _rng.randf_range(0.75, 1.3) + p.shock() * 1.5 + p.felt_pain() * 0.5


func _aim_point(t: Node3D) -> Vector3:
	if t is HumanBody and (t as HumanBody).parts.has(&"chest"):
		if senses.sees(t):
			return ((t as HumanBody).parts[&"chest"] as Node3D).global_position
		var lk := senses.last_known(t)
		return (lk if lk != Vector3.INF else t.global_position) + Vector3.UP * 1.25
	var chest := 1.3
	if t is Player and (t as Player).is_crouching:
		chest = 0.75
	var base := t.global_position if senses.sees(t) or senses.last_known(t) == Vector3.INF else senses.last_known(t)
	return base + Vector3.UP * chest


## Gun out and ready, and he can see the man (or only just lost him); covering a friend, he'll
## put rounds where the man was. Never through a friend.
func _can_shoot_at(t: Node3D) -> bool:
	if body.gun_holstered:
		body.draw_gun()
		return false
	if not body.gun_ready():
		return false
	if senses.since_seen(t) >= 0.8 and not (covering > 0.0 and senses.since_known(t) < 20.0):
		return false
	return not _friend_in_the_way(_aim_point(t))


## A friend between his muzzle and where he's shooting.
func _friend_in_the_way(point: Vector3) -> bool:
	var gun := body.held_gun as RevolverModel
	if gun == null or crew.ids.is_empty():
		return false
	var q := PhysicsRayQueryParameters3D.create(gun.muzzle.global_position, point, Layers.BODY_PARTS)
	q.exclude = _exclude()
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	return not hit.is_empty() and crew.is_mate((hit.collider as Object).get_meta(&"human_body", null))


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
	if not senses.sees(t):
		spread += 3.0  # at where he was, not at him
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics == null:
		return
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	var dir := _cone(_held_over(ballistics, origin, point), deg_to_rad(spread))
	var exclude: Array[RID] = []
	for sid: StringName in body.parts:
		exclude.append((body.parts[sid] as CollisionObject3D).get_rid())
	var bullet := ballistics.fire(origin, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter, exclude)
	bullet.form = t_rev.form_factor
	bullet.shooter = body
	rounds -= 1
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir)
	ImpactEffects.muzzle_flash(world, origin)
	_gun_sound.play()
	Events.shot_fired.emit(origin, dir, body)


## He knows his gun: aimed from `origin` at `point`, held over for the drop at the range he judges
## it to be (off by `range_judgement`).
func _held_over(ballistics: Ballistics, origin: Vector3, point: Vector3) -> Vector3:
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	var judged := origin.distance_to(point) * maxf(1.0 + _range_rng.randfn(0.0, range_judgement), 0.3)
	var base := (point - origin).normalized()
	var axis := base.cross(Vector3.UP)
	if axis.length() < 1e-4:
		return base
	return base.rotated(axis.normalized(), ballistics.holdover(judged, t_rev.muzzle_velocity, t_rev.bullet_mass,
			t_rev.bullet_diameter, t_rev.form_factor))


func _cone(dir: Vector3, radians: float) -> Vector3:
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var r := sqrt(_rng.randf()) * tan(radians)
	var a := _rng.randf() * TAU
	return (dir + side * cos(a) * r + up * sin(a) * r).normalized()


# --- With his friends ----------------------------------------------------------------------------

## How far he'll go round on a man when friends are keeping him busy (m), and how far he'll go to
## get a friend who's down in the open (m).
const FLANK_TRAVEL := 16.0
## How much a flanker wants a new angle on the man (Cover.search `new_angle`; 3 moving on his own).
const FLANK_ANGLE := 9.0
const RESCUE_REACH := 18.0
## Walking backwards with a man by the collar (m/s).
const DRAG_SPEED := 1.1
## The least time between two shouts of one kind (s); the rest every time.
const CALL_EVERY := {&"hit": 3.0, &"spotted": 5.0, &"covering": 4.0, &"help": 6.0}
## Fear at seeing a friend go down, killed, give up, run (more if it's the man who leads them).
const FEAR_MATE_OUT := {&"down": 0.12, &"dead": 0.15, &"quit": 0.1, &"fled": 0.08}


## Shout to his friends: `about` the man they're fighting or the friend it concerns, `at` where.
## Everyone in earshot hears the words; his friends act on them.
func callout(kind: StringName, about: Node = null, at := Vector3.INF) -> void:
	var p := body.physiology
	if not p.is_conscious():
		return
	if CALL_EVERY.has(kind) and not crew.may_say(kind, _now, CALL_EVERY[kind]):
		return
	say(StringName("call_" + String(kind)), Crew.name_of(about))
	if p.jaw_broken or p.airway_blood:
		return  # nobody can make out what he's trying to say
	Events.callout.emit(body, kind, about, at)


## Would he hear a friend shouting from there? (Halved through a wall, less with burst eardrums.)
func _hears(speaker: Node3D) -> bool:
	var from := senses.eye()
	var at := speaker.global_position + Vector3.UP * 1.6
	var reach := Crew.EARSHOT
	var q := PhysicsRayQueryParameters3D.create(from, at, Layers.WORLD)
	var hit := body.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and (hit.position as Vector3).distance_to(at) > 0.6:
		reach *= 0.5
	reach *= 1.0 - 0.35 * body.physiology.deaf_ears()
	return from.distance_to(at) <= reach


func _on_callout(speaker: Node, kind: StringName, about: Node, at: Vector3) -> void:
	if speaker == body or not crew.is_mate(speaker) or mood in [Mood.DEAD, Mood.SURRENDERED] \
			or not body.physiology.is_conscious() or not _hears(speaker as Node3D):
		return
	crew.note(kind, speaker, _now)
	match kind:
		&"spotted":
			if about is Node3D and at != Vector3.INF and not senses.sees(about):
				senses.note(about, at, 0.8)
			_join(about, speaker)
		&"reloading":
			_join(about, speaker)
			_cover_mate(5.0)
		&"hit":
			_join(about, speaker)
			_cover_mate(3.5)
		&"flank":
			_join(about, speaker)
			_cover_mate(7.0)
		&"drag":
			crew.helper[about] = speaker
			_cover_mate(6.0)
		&"help":
			_join(about, speaker)
			_mate_out(speaker, &"down", false)
			_gang_check = 0.0
		&"down", &"dead", &"quit":
			_mate_out(about, kind, false)
		&"fall_back":
			_heard_fall_back(speaker)
		&"give_up":
			_heard_give_up(speaker)


## A friend's in a fight with that man and shouting about it: so is he.
func _join(about: Node, mate: Node) -> void:
	if about == null or not is_instance_valid(about) or about == body or crew.is_mate(about) \
			or not (about is Player or about is HumanBody) or mood == Mood.SURRENDERED:
		return
	if relations.stance(about) < Relations.Stance.FIGHT:
		relations.side_with(about)
	if not senses.knows(about):
		senses.note(about, (about as Node3D).global_position, 3.0)


## Keep the man busy for a friend (reloading, hit, going round, dragging someone).
func _cover_mate(seconds: float) -> void:
	if mood != Mood.FIGHTING or _find_target() == null or rescuing != null or body.held_gun == null:
		return
	covering = maxf(covering, seconds)
	if tactic == Tactic.HIDDEN:
		_tactic_time = minf(_tactic_time, 0.25)
	callout(&"covering", _find_target())


func _start_reload() -> void:
	_reload_left = reload_seconds
	_set_mood(Mood.RELOADING)
	if crew.any_in_earshot(_now):
		callout(&"reloading", _find_target())
	else:
		say(&"reloading")


## Each tick of a fight: shout where the man is when he's moved, and look out for a friend down
## in the open.
func _gang(delta: float, t: Node3D) -> void:
	_spot_call -= delta
	if _spot_call <= 0.0 and senses.sees(t) and crew.any_in_earshot(_now):
		var p := t.global_position
		if _called_at == Vector3.INF or p.distance_to(_called_at) > 4.0:
			callout(&"spotted", t, p)
			_called_at = p
			_spot_call = 5.0
	_gang_check -= delta
	if _gang_check > 0.0:
		return
	_gang_check = 0.5
	if tactic != Tactic.RESCUING and mood == Mood.FIGHTING and rage <= 0.0:
		var w := _wounded_mate(t)
		if w != null:
			_start_rescue(w)


## Where a man lying down is (his chest, on the ground).
static func _lying_at(m: HumanBody) -> Vector3:
	var c := (m.parts[&"chest"] as Node3D).global_position
	return Vector3(c.x, c.y - 0.15 if m.limp else m.global_position.y, c.z)


## A friend he knows is down, alive, in the open (the man can see him lying there), near enough,
## and nobody else getting him: the nearest such. Not if he's in no state to go himself.
func _wounded_mate(t: Node3D) -> HumanBody:
	if body.prone or not body.physiology.can_run() or fear > nerve * 0.8 or _stand_and_fight \
			or suppressed > 0.0 or body.held_gun == null:
		return null
	var eye := _eye_of(t)
	var space := body.get_world_3d().direct_space_state
	var best: HumanBody = null
	var best_d := RESCUE_REACH
	for m in crew.mates(_now):
		if not (m.prone or m.limp) or not m.physiology.alive or m.dragged_by != null:
			continue
		if crew.out.get(m, &"") != &"down":
			continue  # he doesn't know he's down (or he's quit, or dead)
		if _now - float(_tried_rescue.get(m, -INF)) < 12.0:
			continue  # he tried and couldn't, just now
		var mb := Crew.brain_of(m)
		if mb != null and mb.mood == Mood.SURRENDERED:
			continue
		var h: Variant = crew.helper.get(m)
		if h != null and is_instance_valid(h) and h != body and (h as HumanBody).physiology.is_conscious() \
				and not (h as HumanBody).prone and crew.since(&"drag", _now, h) < 20.0:
			continue
		var at := _lying_at(m)
		if Cover.hidden_at(space, at, eye, Cover.LIE_HEAD, _exclude(t)):
			continue  # out of the line of fire already
		var d := at.distance_to(body.global_position)
		if d < best_d:
			best = m
			best_d = d
	return best


func _start_rescue(m: HumanBody) -> void:
	rescuing = m
	_rescue_phase = 0
	_rescue_time = 0.0
	_rescue_to = Vector3.INF
	_search = null
	_flanking = false
	tactic = Tactic.RESCUING
	crew.helper[m] = body
	_stuck = 0.0
	_last_pos = body.global_position
	callout(&"drag", m, _lying_at(m))


## Getting a friend out of it: run to him, take him by the collar and walk backwards, dragging
## him, to the nearest thing that'll hide a man lying down; then find himself cover.
func _rescue(delta: float, t: Node3D) -> void:
	_rescue_time += delta
	var m := rescuing
	var mb := Crew.brain_of(m)
	if m == null or not is_instance_valid(m) or not m.physiology.alive or body.prone or _rescue_time > 25.0 \
			or (mb != null and mb.mood == Mood.SURRENDERED) or not (m.prone or m.limp):
		_stop_rescue()
		return
	var at := _lying_at(m)
	if _rescue_phase == 0:
		# Running to him, to his head (round whatever's in the way).
		var head := _collar(m)
		var to := head - body.global_position
		to.y = 0.0
		body.set_pose(&"stand")
		if _route.is_empty() or (_route[-1] as Vector3).distance_to(head) > 0.8:
			_route = Cover.route(body.get_world_3d().direct_space_state, body.global_position, head, _exclude(t))
			if _route.is_empty():
				_route = [head]
		if body.walk_to(_route[0], run_speed, delta) and _route.size() > 1:
			_route.pop_front()
		_watch_stuck(delta)
		if to.length() < 0.9 or (to.length() < 1.4 and _stuck > 0.5):
			_route = []
			_rescue_phase = 1
			m.dragged_by = body
			_rescue_to = _drag_spot(m, t)
			_rescue_goal = Vector3.INF
			_last_pos = body.global_position
			_stuck = 0.0
		elif _stuck > 2.0:
			_stop_rescue()
		return
	# Dragging: walking backwards, facing him, him sliding along behind by the collar.
	var space := body.get_world_3d().direct_space_state
	if _rescue_goal == Vector3.INF:
		_rescue_goal = _drag_goal(at, _eye_of(t), t)
		_rescue_best = INF
		_stuck = 0.0
	body.set_pose(&"drag")
	var arrived := body.walk_to(_rescue_goal, DRAG_SPEED, delta, false)
	body.face(at + Vector3.UP * 0.3)
	var to_him := at - body.global_position
	to_him.y = 0.0
	m.drag_toward(body.global_position + to_him.normalized() * 0.45, delta)
	# Not getting any nearer (up against something): as far as he can take him.
	var left := body.global_position.distance_to(_rescue_goal)
	if left < _rescue_best - 0.05:
		_rescue_best = left
		_stuck = 0.0
	else:
		_stuck += delta
	var safe := _rescue_time > 1.0 and Cover.hidden_at(space, _lying_at(m), _eye_of(t), Cover.LIE_HEAD, _exclude(t)) \
			and Cover.hidden_at(space, _lying_at(m), _eye_of(t), Cover.LIE_CHEST, _exclude(t))
	if safe or arrived or _stuck > 1.5:
		_stop_rescue()


## Where to walk to, dragging him, so that he ends up lying on the spot (his chest a metre behind
## the dragger's feet): past it, the way they're going, or straight back from the man's gun, or
## between the two; whichever there's room to walk to.
func _drag_goal(at: Vector3, eye: Vector3, t: Node3D) -> Vector3:
	var space := body.get_world_3d().direct_space_state
	var travel := _rescue_to - at
	travel.y = 0.0
	var away := _rescue_to - eye
	away.y = 0.0
	var ways: Array[Vector3] = []
	if travel.length() > 0.05:
		ways.append(travel.normalized())
		ways.append((travel.normalized() + away.normalized()).normalized())
	ways.append(away.normalized())
	for way in ways:
		var goal := _rescue_to + way * 1.1
		if Cover.path_clear(space, _rescue_to, goal, _exclude(t), 0.32):
			return goal
	return _rescue_to


## Where he takes hold of a man lying down: his collar (the top of his chest).
static func _collar(m: HumanBody) -> Vector3:
	var c := (m.parts[&"chest"] as Node3D).global_position
	var n := (m.parts[&"neck"] as Node3D).global_position if m.parts.has(&"neck") else c
	var p := n.lerp(c, 0.3)
	return Vector3(p.x, m.global_position.y if not m.limp else p.y, p.z)


## Somewhere to drag him: the best cover near him from the man's gun, else away from it.
func _drag_spot(m: HumanBody, t: Node3D) -> Vector3:
	var from := _lying_at(m)
	from.y = body.global_position.y
	var eye := _eye_of(t)
	var ex := _exclude(t)
	for sid: StringName in m.parts:
		ex.append((m.parts[sid] as CollisionObject3D).get_rid())
	var spot := Cover.find(body.get_parent() as Node3D, from, eye, ex, _think, Vector3.INF, 9.0)
	if not spot.is_empty():
		return spot.at
	var away := from - eye
	away.y = 0.0
	return from + away.normalized() * 6.0


## Let go of whoever he was dragging (there, or it's gone wrong) and see to himself.
func _stop_rescue() -> void:
	if rescuing != null and is_instance_valid(rescuing):
		_tried_rescue[rescuing] = _now
		if rescuing.dragged_by == body:
			rescuing.dragged_by = null
		crew.helper.erase(rescuing)
	rescuing = null
	if tactic == Tactic.RESCUING:
		tactic = Tactic.OPEN
		_cover_search = 0.0


## Someone fell: if it's a friend and he saw it (or was near enough to hear it), it goes through him.
func _on_person_fell(who: Node, _conscious: bool) -> void:
	_saw_mate_out(who, &"down")


func _saw_mate_out(who: Node, how: StringName) -> void:
	if who == body or not crew.is_mate(who) or not (senses and (senses.sees(who) \
			or (who as Node3D).global_position.distance_to(body.global_position) < 15.0)):
		return
	_mate_out(who, how, true)


## A friend's out of it (down, dead, given up, run): fear, more if it's the man who leads them;
## the first to see it shouts it; a hothead goes for the man who did it, a proud one curses a
## friend who quits; and once half of them are out of it, it's going badly and they all know it.
func _mate_out(m: Node, how: StringName, saw: bool) -> void:
	if not crew.is_mate(m) or mood in [Mood.DEAD, Mood.SURRENDERED] or not body.physiology.is_conscious():
		return
	crew.mates(_now)
	if not crew.mark_out(m, how):
		return
	fear += float(FEAR_MATE_OUT.get(how, 0.1)) * (1.6 if Crew.leads(m) else 1.0)
	if how in [&"down", &"dead"] and m.has_meta(&"last_hit_by"):
		_join(m.get_meta(&"last_hit_by"), m)  # whoever shot him down
	var fighting := mood in [Mood.FIGHTING, Mood.RELOADING]
	if saw and how != &"fled" and crew.any_in_earshot(_now):
		callout(how, m, (m as Node3D).global_position)
	if how in [&"down", &"dead"] and temper >= 0.7 and fighting and fear <= nerve:
		rage = 8.0
		fear = maxf(fear - 0.2, 0.0)
		say(&"rage")
	elif how == &"quit" and proud and fighting:
		say(&"scorn", Crew.name_of(m))
	if not crew.thinned and crew.out_share() >= 0.5:
		crew.thinned = true
		fear += 0.15


## Fury: out from behind whatever he was behind, at the man, shooting.
func _rage_fight(delta: float, t: Node3D) -> void:
	if tactic != Tactic.OPEN:
		tactic = Tactic.OPEN
		_search = null
	if mood == Mood.RELOADING:
		body.face(_eye_of(t))
		body.set_pose(&"stand")
		return
	var to := t.global_position - body.global_position
	to.y = 0.0
	if to.length() > 9.0:
		body.walk_to(body.global_position + to.normalized(), walk_speed, delta, false)
	_fight(delta)


## "Fall back!": a friend's running. If he's had enough himself (and it's the man who leads them
## saying so, it takes less), he goes too.
func _heard_fall_back(mate: Node) -> void:
	_mate_out(mate, &"fled", false)
	if not mood in [Mood.FIGHTING, Mood.RELOADING] or body.prone or _pending_break != &"":
		return
	if fear > nerve * (0.3 if Crew.leads(mate) else 0.6) and body.physiology.can_run():
		_pending_break = &"flee"
		_pending_in = _think.randf_range(0.3, 1.0)


## The man who leads them has thrown his gun down: unless he's still got his nerve, so does he.
func _heard_give_up(mate: Node) -> void:
	_mate_out(mate, &"quit", false)
	if not mood in [Mood.FIGHTING, Mood.RELOADING, Mood.TENDING] or _pending_break != &"":
		return
	if fear > nerve * 0.3:
		_pending_break = &"surrender"
		_pending_in = _think.randf_range(0.6, 1.6)


# --- Breaking, running, tending --------------------------------------------------------------------

## Nerve's gone: run for it if he can, else give up.
func _break() -> void:
	var t: Node3D = _find_target()
	if t == null:
		t = relations.focus() as Node3D
	if t == null:
		t = _player()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	var caught := _aimed_at > 0.8 and d < 12.0
	if mood == Mood.CALM and t != null and relations.stance(t) >= Relations.Stance.WARY \
			and not (caught and _drop_it_heard < 4.0):
		# Not a fight yet: he backs down (told to drop it with a gun on him, he gives up instead).
		_back_down(t)
		return
	if body.physiology.can_run() and not body.prone and d > 5.0 and not caught and _think.randf() < flee_chance:
		_start_fleeing()
	else:
		_surrender()


func _start_fleeing() -> void:
	_stop_rescue()
	if crew.any_in_earshot(_now) and crew.since(&"fall_back", _now) > 3.0 and crew.may_say(&"fall_back", _now, 30.0):
		callout(&"fall_back", _find_target())
	else:
		say(&"flee")
	_set_mood(Mood.FLEEING)
	tactic = Tactic.OPEN
	_flee_time = 0.0
	_pick_flight()


## Somewhere well away from the gun that he can run to in a straight line.
func _pick_flight() -> void:
	var t: Node3D = _find_target()
	if t == null:
		t = _player()
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
	var t: Node3D = _find_target()
	if t == null:
		t = _player()
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
	_stop_rescue()
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
	_stop_rescue()
	_set_mood(Mood.SURRENDERED)
	if leads and crew.any_in_earshot(_now):
		callout(&"give_up", _find_target())
	else:
		say(&"surrender")
	body.drop_gun()
	if mood == Mood.TENDING:
		_release_pressure()
	body.set_pose(&"prone" if body.prone else &"hands_up")
	Events.person_surrendered.emit(body)


func describe() -> String:
	var how: String = String(Mood.keys()[mood]).to_lower()
	if mood == Mood.FIGHTING or mood == Mood.RELOADING:
		how += " (%s%s%s%s)" % [String(Tactic.keys()[tactic]).to_lower(), ", pinned down" if suppressed > 0.0 else "",
				", covering" if covering > 0.0 else "", ", in a rage" if rage > 0.0 else ""]
	elif mood == Mood.CALM and relations:
		var who := relations.focus()
		if who:
			how += " (%s of %s)" % [String(Relations.Stance.keys()[relations.stance(who)]).to_lower(),
					"you" if who is Player else String((who as HumanBody).person_id) if who is HumanBody else str(who.name)]
	return "%s: %s, fear %.2f / nerve %.2f, %d rounds. %s" % [String(body.person_id).capitalize(),
			how, fear, nerve, rounds, body.physiology.describe()]
