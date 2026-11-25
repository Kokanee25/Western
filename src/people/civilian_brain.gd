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
## Trouble that isn't on him (a shot heard or seen, a blast, a gun drawn near him, a man down) he
## takes in stages, by his dials (`Reaction`, townsfolk step 5): a start a beat after it reaches
## him, a look toward where he thinks it was, then flee, hide, gawk, watch, help or carry on, and
## back to his spot after a calm while, shaken.
## Child of a HumanBody (with no gun).

## (ALARMED, WATCHING, RUNNING: a Reaction's stages: starting and looking; watching, gawking or
## helping; running for a door.)
enum Mood { CALM, SHAKEN, HANDS_UP, COWERING, DOWN, DEAD, FLEEING, ALARMED, WATCHING, RUNNING }
## "...They gone?" only after this long without a shot heard (s).
const RELIEF_QUIET := 8.0

const LINES := {
	&"shoved": ["Hey—! There's no call for that.", "Please, I don't want any trouble.", "Easy! Easy..."],
	&"beg": ["Take it! Take whatever you want!", "Don't shoot! I got a family!", "Please, mister..."],
	&"cower": ["Lord almighty!", "Get down! Everybody down!"],
	&"hat": ["My hat! Lord, my hat!", "He shot my hat clean off!"],
	# Widened (#1184: after one shot four men each said "...They gone?" and four "Lord, lord").
	&"relief": ["...They gone?", "Lord. Lord, lord.", "Is it over?", "Anybody hurt?", "I'm too old for this.",
			"Somebody tell me that's the end of it.", "My heart's going like a hammer.", "Who was it? Anybody see?",
			"Well. That's my supper ruined.", "Damn fool, whoever it was."],
	# The relief of a man who saw who fired (#1194: the rancher, 4 m off, asked "Who was it?").
	# To the face of the man who fired, right there (#1213).
	&"relief_you": ["You done? Lord.", "Put that thing away, mister. Please.", "What'd you go and do that for?",
			"Easy. Easy, now. Nobody's hurt."],
	&"relief_saw": ["Lord. Is he done?", "I'm too old for this.", "My heart's going like a hammer.",
			"Damn fool, firing off like that.", "Somebody take that iron off him.", "Is it over?",
			"Well. That's my supper ruined.", "Anybody hurt?"],
	&"buckets": ["Buckets! Get the buckets!", "Water! From the trough, quick!", "Bring water, damn it!"],
	&"lost": ["Let it go, she's gone!", "Too late. Let it burn.", "Nothing to be done now."],
	&"out": ["That's got it!", "It's out. Lord.", "Keep an eye on it, it'll catch again."],
	&"fire": ["Fire! FIRE!", "Fire! Get out, get out!", "Lord, it's burning!", "Fire! Somebody get water!",
			"It's going up! Clear out!"],
	&"thanks": ["Obliged to you, mister. Truly.", "Thank God you came along.", "I owe you one, friend."],
	&"damage": ["Hey! What the hell was that?", "That's somebody's property, mister.", "Easy, now. Who's paying for that?"],
	&"damage_mine": ["My glass! You'll pay for that, mister.", "Hey! That's my window! What in God's name—",
			"That's come all the way from St. Louis, that glass!", "You break it, you bought it. That's the rule here."],
	&"gun_out": ["Whoa, now. Easy with that iron.", "Put that away, mister.", "Hey now. There's no call for that."],
	&"chair": ["What the hell?!", "Who kicked my damn chair?", "Son of a...!"],
	&"help": ["Somebody get the doc!", "Easy, friend. Easy. Lie still.", "He's hit! Get the doctor!"],
	&"gawk": ["Lord. Is he dead?", "What in the hell was that?", "Stand back, give him air."],
	# Gawking at a shot with nobody down (the town gate, #1167: a shot in the air drew "Is he dead?"
	# and "give him air" from men who'd seen no one hurt).
	&"gawk_shot": ["What in the hell was that?", "Who's shooting?", "Where'd that come from?"],
	&"hurt": ["I'm hit! Lord, I'm hit!", "He shot me! Oh God, he shot me!"],
	# By what hit him (#1125: a piece of the store from a blast 10 m off had him cry "He shot me!",
	# and a man hit in the chest cried "My arm!"): a ball in the arm, and anything a blast threw.
	&"hurt_arm": ["Ah—! My arm! My arm!", "I'm hit! Lord, I'm hit!"],
	&"hurt_blast": ["Ah! What hit me?", "Something hit me! Lord!", "I'm hurt! God, I'm hurt!"],
	&"hurt_down": ["Help me! Somebody help me!", "Get the doc! For God's sake, get the doc!", "I'm shot... help..."],
}
## A man's lines come no closer than this (s) (#773, the cards playtest: the drifter's hiding and
## pleading lines two a second for 20 s), but for these, which come once and matter.
const SAY_GAP := 2.5
const SAY_ALWAYS := [&"fire", &"thanks", &"chair", &"hurt", &"hurt_arm", &"hurt_blast"]
## What a blast throws at a man (the body's hit kinds), not a gun's ball (#1125).
const BLAST_KINDS := [&"blow", &"splinter", &"gravel", &"blast", &"burn"]
## Another man's cower line this recently (ms): he's likelier to keep quiet, and never says the same.
const CROWD_MS := 900
const SAME_LINE_MS := 4000
## Kinds whose lines nobody repeats in the town for longer than SAME_LINE_MS (ms; #1184: the relief
## after a shot went round the room, the same two lines by four men each). All said: he keeps quiet.
const SAME_LINE_LONG_MS := {&"relief": 300000, &"relief_saw": 300000, &"relief_you": 300000, &"gawk_shot": 60000}
## Something broken by a man (`damage`, #1213): seen within DAMAGE_SEEN, or heard within DAMAGE_HEARD, he
## looks round.
const DAMAGE_SEEN := 15.0
const DAMAGE_HEARD := 10.0
var _mine_frame := -1


func _damage_say(frame: int) -> void:
	if _mine_frame != frame and is_instance_valid(body):
		say(&"damage")
## Seen drawing within this (m), a gun makes him uneasy (not on him: `aim_at` is that).
const GUN_SEEN := 9.0

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
## His dials, each 0 to 1 (ValleyFolk.dials_of): nerve, nosy, duty; the middle if nobody set them.
var dials := {"nerve": 0.5, "nosy": 0.5, "duty": 0.5}
## Held by a scene (SceneHold, #1050): it walks and turns him, not his day or his fright; his senses
## still take things in, and his own brain has him again from where he stands when it lets go.
var held := false
## Doors he'd run to from trouble (his own, the store, the saloon: ValleyFolk's); none, he hides
## where he is.
var refuges: Array[Vector3] = []
## Running for help (FetchHelp, townsfolk step 6): who to run to for a man down; null, nobody runs.
var fetch: FetchHelp
## The town's news (TownNews, townsfolk step 7): what he senses of trouble goes in as his version.
var news: TownNews
## His pace walking back to his post (m/s): the doctor called to a man down walks fast.
const WALK := 1.2
var walk_speed := WALK
## A bark for a moment of his (townsfolk step 9, TownBarks): ValleyFolk's `bark_for(brain, on,
## extra)`, which says it if a line fits; unset (a lab's man), he has none.
var bark: Callable
## What he's showing Harlan as he passes, by his regard (TownRegard.SHOWS): {what, who, t, aside}.
var showing := {}
## A bit the room's director gave him (SaloonRoom, townsfolk step 10; `start_bit`), {} when none.
var bit := {}
var _bit_ticked := false
var _bit_segs := {}
## Seconds his idle talk's kept shut (the room's talk dropping as Harlan comes in: SpotChore's mouth).
var quiet := 0.0
## The last he showed (for the tests and the bridge): &"nod", &"look_away", &"turn", &"clear".
var last_shown := &""

## His reaction to trouble that isn't on him, in stages (townsfolk step 5).
var reaction: Reaction
## The physics frame he was last sent somewhere (`go_to`): on an errand (an act's), a reaction
## doesn't walk him off it (Reaction.ERRAND).
var sent_frame := -100000
## Coming back from where a reaction took him (a door, the gawk ring): to his post first, by the
## town's places, before any chore has him (a card chair's straight walk would go through the table).
var returning := false
const RETURNED := 0.8
var _home_stuck := 0.0
var _home_detours := 0
var _home_detour := Vector3.INF
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
## Quiet for an act's beat (s left; `hush`): he says nothing of his own.
var _hush := 0.0
## Since his last line (s).
var _since_said := INF
## A drawn gun he's keeping an eye on, and for how long (s).
var _gun_seen: Node3D
## Hurt (#1116, the chaos playtest: men shot at arm's length stayed hands-up on their bench; a man
## with an arm wound lay `down` for minutes): a ball in him and a gun on him no longer holds him;
## he runs (walks, if he can't run) for a door; down and awake, once he's lain still `UP_AFTER` and
## isn't bleeding hard (`UP_BLEED`), he gets up if his legs will have him, else calls for help.
var hurt := false
var _wounds_seen := 0
## Hurt before hours went by in a moment (#1125): the fright of it's spent; up again he doesn't cry
## out and run from a shot hours old (the widow's "Get down!" four seconds after you came round).
var _hurt_spent := false
## The last hit on him (HumanBody.hit's kind and segment): what he cries out.
var _hit_kind := &""
var _hit_seg := &""
var _down_s := 0.0
var _call_down := 0.0
const UP_AFTER := 5.0
const UP_BLEED := 4.0  # ml/s from his body (not a limb): worse, he stays down (Earl's collarbone, a belly)
const UP_SHOCK := 0.3
const CALL_DOWN_EVERY := Vector2(10.0, 18.0)
var _gun_watch := 0.0
## Every man's lines, when last said (ms of game ticks): two men don't say the same thing in the same breath.
static var _said_at := {}
static var _cower_at := -100000

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
	reaction = Reaction.new(self)
	add_to_group(&"civilians")
	# What he hears is Senses' (its guess at where, muffled through walls, the maker only if seen),
	# never the noise's own place.
	senses.heard.connect(_on_heard)
	Events.deed.connect(_on_deed)
	Events.person_fell.connect(func(p: Node, _c: bool) -> void: _on_down(p))
	Events.person_died.connect(func(p: Node, _c: StringName) -> void: _on_down(p))
	Events.hat_shot.connect(_on_hat_shot)
	Events.hours_passed.connect(_on_hours_passed)
	body.hit.connect(func(info: Dictionary) -> void:
		_hit_kind = StringName(info.get("kind", &""))
		_hit_seg = StringName(info.get("segment", &"")))
	Events.scorched.connect(func(who: Node, amount: float) -> void:
		if who == body:
			_scorched += amount
			_fire_look = minf(_fire_look, 0.05))
	_fire_look = _rng.randf_range(0.0, FIRE_LOOK)  # not everyone looking on the same tick


## A new post (and the point he faces there): he walks to it by the town's places, a route on his
## way to the old one dropped (ValleyFolk sends its people out of town by it).
func go_to(point: Vector3, facing := Vector3.INF) -> void:
	post = point
	faces = facing
	_home_route.clear()
	sent_frame = Engine.get_physics_frames()
	if reaction != null:
		reaction.drop()  # sent: off he goes (an act's, his day's), shaken if it had got that far


func say(kind: StringName) -> void:
	var lines: Array = LINES.get(kind, [])
	if lines.is_empty() or not body.physiology.is_conscious() or not body.physiology.can_speak() or _hush > 0.0:
		return
	if _since_said < SAY_GAP and not kind in SAY_ALWAYS:
		return
	# Game time, not the wall's (the labs' runs the same twice: same_fight.py).
	var now := Engine.get_physics_frames() * 1000 / Engine.physics_ticks_per_second
	if kind == &"cower":
		if now - _cower_at < CROWD_MS and _rng.randf() < 0.6:
			return  # someone's just cried out: he keeps it to himself
		_cower_at = now
	# Not a line another man's just said.
	var gap := int(SAME_LINE_LONG_MS.get(kind, SAME_LINE_MS))
	var fresh := lines.filter(func(l: String) -> bool: return not _said_at.has(l) or now - int(_said_at[l]) > gap)
	if fresh.is_empty():
		if not kind in SAY_ALWAYS:
			return  # all of them just said by others: he's no need to say it again
		fresh = lines
	var pick: String = fresh[_rng.randi() % fresh.size()]
	_said_at[pick] = now
	_since_said = 0.0
	Events.spoke.emit(body, pick)


## A line of his own (a runner's news, FetchHelp: made from what he sensed), said now if he can speak.
func say_line(text: String) -> void:
	if text == "" or not body.physiology.is_conscious() or not body.physiology.can_speak() or _hush > 0.0:
		return
	_since_said = 0.0
	Events.spoke.emit(body, text)


## May he say anything now (awake, able, not hushed by a scene)?
func may_speak() -> bool:
	return body.physiology.is_conscious() and body.physiology.can_speak() and _hush <= 0.0


## Quiet for `seconds` from now (0: not; an act's beat: No Law's room going quiet after the shot,
## #773): he does as he would, but says nothing; a cry still to come is dropped.
func hush(seconds: float) -> void:
	_hush = seconds


## "...They gone?", once it's gone quiet (#607: not with shots still flying).
func say_relief() -> void:
	if not _still_over_me() and senses.last_sound([&"gunshot"], RELIEF_QUIET).is_empty():
		var by := saw_shooter()
		if by != null and _to_his_face(by):
			say(&"relief_you")
		else:
			say(&"relief_saw" if by != null else &"relief")


## Who he saw fire in the trouble he's coming back from (#1213: men who watched the player fire said
## "Damn fool, whoever it was"): his reaction's man, else the shooter his own news has him seeing
## (TownNews: a version he saw, of the latest shots); null if he saw nobody.
func saw_shooter() -> Node3D:
	if reaction != null and reaction.who != null and is_instance_valid(reaction.who) \
			and (reaction.who is Player or reaction.who is HumanBody):
		return reaction.who
	if news != null:
		var who := news.saw_fire(body.person_id)
		if who == TownNews.HARLAN:
			return get_tree().get_first_node_in_group(&"player") as Node3D if is_inside_tree() else null
		if who != &"" and news.folk != null:
			return news.folk.folk_man(who)
	return null


## `who` near and in his sight: said to him, not of him.
func _to_his_face(who: Node3D) -> bool:
	return who is Player and who.global_position.distance_to(body.global_position) < FACE_M and senses != null and senses.sees(who)
const FACE_M := 6.0


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
		if kind in ASSAULTS and actor is Node3D and senses.sees(actor) \
				and (actor as Node3D).global_position.distance_to(body.global_position) < ASSAULT_SEEN:
			# A man kicked in front of him: it's turned ugly.
			fear += 0.1 if kind == &"kick" else 0.2
			_flinch = 1.0
		elif kind == &"draw" and actor is Node3D and actor != _gun_seen \
				and (actor as Node3D).global_position.distance_to(body.global_position) < GUN_SEEN and senses.sees(actor):
			# A gun out near him (the playtest's, #773: drawn 3 m from the table and nobody minded):
			# uneasy, an eye on the man, and he says so.
			fear += 0.1
			_gun_seen = actor
			_gun_watch = 6.0
			say(&"gun_out")
			reaction.sense(&"gun", (actor as Node3D).global_position, actor as Node3D)
		elif kind == &"damage" and actor is Node3D and _at.distance_to(body.global_position) < DAMAGE_SEEN \
				and (senses.sees(actor) or _at.distance_to(body.global_position) < DAMAGE_HEARD):
			# Something broken near him (#1213: the store's glass, and nobody turned): he looks at it and
			# at who did it, and says so (its owner has his own say: `damaged_mine`).
			fear += 0.05
			show_look(_at, actor as Node3D, 4.0)
			_damage_say.call_deferred(Engine.get_physics_frames())  # (after the owner's had his, if it's his)
		elif kind == &"holster" and actor == _gun_seen:
			_gun_watch = 0.0
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
			if hurt:
				return  # (hurt, a gun on him doesn't hold him: he's going)
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
			# At him: it's on him (as near as it gets), the shooter's place his guess unless seen.
			# (The shot's own sound came first: unseen, his guess at it is where it came from.)
			var by := actor as Node3D if actor is Node3D and senses.sees(actor) else null
			var guess := senses.last_known(actor) if actor != null else Vector3.INF
			if guess == Vector3.INF:
				guess = senses.last_sound([&"gunshot"], 1.0).get("at", Vector3.INF)
			reaction.sense(&"at_me", by.global_position if by else (guess if guess != Vector3.INF else body.global_position), by)
			fear += 0.3
			_troubled(actor)


## A ball in him: no gun on him holds him now; he cries out and goes (Reaction, `at_me`: a hurt man
## runs for a door, or walks to it if he can't run).
func _on_hurt() -> void:
	hurt = true
	_hurt_spent = false
	_aimed = 0.0
	_cower = 0.0
	_flinch = 0.0
	_call_down = 0.0
	if mood == Mood.HANDS_UP:
		mood = Mood.ALARMED
	say(hurt_line())
	if not body.limp:
		_go_hurt()


## What he cries when he's hurt, by what hit him: a blast's piece (or a blast heard just now with no
## ball in him), a ball in the arm, else a ball.
func hurt_line() -> StringName:
	var blasted := _hit_kind in BLAST_KINDS or (_hit_kind == &"" and senses != null and not senses.last_sound([&"blast", &"explosion"], 2.0).is_empty())
	if blasted:
		return &"hurt_blast"
	var s := String(_hit_seg)
	if s.contains("arm") or s.begins_with("hand"):
		return &"hurt_arm"
	return &"hurt"


## Hurt and on his feet: off to a door (a reaction already starting on the shot decides as hurt).
func _go_hurt() -> void:
	if reaction == null or reaction.kind == &"at_me" and reaction.stage in [Reaction.Stage.START, Reaction.Stage.LOOK]:
		return
	var from := _aimed_by.global_position if _aimed_by != null and is_instance_valid(_aimed_by) else body.global_position
	reaction.drop(true)
	reaction.sense(&"at_me", from, _aimed_by if _aimed_by != null and is_instance_valid(_aimed_by) else null)


## Down and awake: up once he's lain still and isn't bleeding hard, if his legs will have him; else,
## hurt, he calls for help now and then.
func _lying(delta: float) -> void:
	var p := body.physiology
	_since_said += delta  # (his tick's own count stops while he's down)
	if not p.is_conscious() or body.rising or body.dragged_by != null:
		_down_s = 0.0
		return
	_down_s += delta
	# (Only hurt: a man knocked down whole gets up by his body's own rule, `rise_ok`, which a scene
	# may stop: Earl kicked over at the table, #1057.)
	if hurt and not body.keep_down and _down_s > UP_AFTER and p.can_stand() and p.shock() < UP_SHOCK and _body_bleed() < UP_BLEED:
		body.get_up()
		return
	if hurt and _down_s > SAY_GAP + 0.5:
		_call_down -= delta
		if _call_down <= 0.0:
			_call_down = _rng.randf_range(CALL_DOWN_EVERY.x, CALL_DOWN_EVERY.y)
			say(&"hurt_down")


## What he's losing from his head, neck and body (ml/s): an arm or a leg bleeding doesn't keep him down.
func _body_bleed() -> float:
	var p := body.physiology
	var r := 0.0
	for b: Dictionary in p.bleeds:
		var seg := String(b.get("segment", ""))
		if not (seg.contains("arm") or seg.contains("hand") or seg.contains("thigh") or seg.contains("shin") or seg.contains("foot")):
			r += p.bleed_rate(b)
	return r


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


## A shot or a blast he heard (Senses: `at` is his guess; `maker` only if he saw him make it).
func _on_heard(at: Vector3, kind: StringName, maker: Node) -> void:
	if not body.physiology.is_conscious():
		return
	if kind == &"gunshot":
		reaction.sense(&"shot_seen" if maker != null else &"shot", at, maker as Node3D)
		if news:
			news.heard(self, at, maker)
		fear += 0.3 * clampf(1.0 - body.global_position.distance_to(at) / 40.0, 0.0, 1.0)
	elif kind == &"blast":
		reaction.sense(&"blast", at)
		fear += 0.3


## A man fallen or dead: a man down, if he saw it.
func _on_down(p: Node) -> void:
	if p == body or not p is HumanBody or senses == null or not body.physiology.is_conscious():
		return
	var man := p as HumanBody
	var reach: float = Reaction.STIMULI[&"down"].reach
	var d := man.global_position.distance_to(body.global_position)
	if d > Reaction.DOWN_FAR:
		return
	if d > reach:
		# Further off: seen hit and fall, he knows a man's down (for running for help), no more.
		if senses.sees(man):
			reaction.far_down = man
			if news:
				news.saw_down(self, man)
		return
	if senses.sees(man) or senses._in_view(man, senses.eye()):
		reaction.sense(&"down", man.global_position, man)
		if news:
			news.saw_down(self, man)


## His hat shot off his head: down on the boards, and he says so.
func _on_hat_shot(person: Node, _shooter: Node, _at: Vector3) -> void:
	if person != body or not body.physiology.is_conscious():
		return
	say(&"hat")
	_cower = maxf(_cower, 10.0)
	fear += 0.5


## Hours went by in a moment: whatever scared him is long over.
func _on_hours_passed(hours: float, _why: StringName) -> void:
	# His wounds ran on through the hours (#1125): stopped bleeding, or bled out (townsfolk keep
	# theirs: Sean, #1093).
	var p := body.physiology
	if p.alive:
		p.pass_time(hours * p.tuning.game_hour_seconds)
	_wounds_seen = p.injuries()
	_hurt_spent = hurt
	_stop_bucket()
	fear = 0.0
	_aimed = 0.0
	_cower = 0.0
	_flinch = 0.0
	if reaction:
		reaction.forget()
	_gun_watch = 0.0
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
	reaction.drop()
	_flinch = 0.0
	_route = FireFlight.way_out(_fire, _places(), body, FIRE_CLEAR)


func _places() -> Waypoints:
	if places == null:
		var town := get_tree().get_first_node_in_group(&"town_life")
		if town:
			places = town.get(&"places")
	return places


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
	_bit_ticked = false
	_physics_step(delta)
	quiet = maxf(quiet - delta, 0.0)
	if not bit.is_empty() and not _bit_ticked:
		cut_bit()  # anything but calm at his chore this tick: the laugh stops in mid-laugh
	elif bit.is_empty() and not _bit_segs.is_empty():
		_bit_tidy()
	Prof.stop(&"civilian_brain", t)


## Far off, may he tick less often (PeopleTick, step 4b)? Going about his day, or cowering or
## shaken where he stands from a shot or a blast he heard (#495: after a stick the whole street
## cowers for 7 s and stays frightened for ~8 more; far from you and from any fight, the bands' own
## rule, he can tick slowly through it). Not with your gun on him or his hands up, flinching from a
## deed, running from a fire or in a bucket line, about to shout, or at a chore that has his hands
## (the bar cloth, the mop: they move what the physics holds).
func can_slow() -> bool:
	return slow_reason() == &""


const MOOD_NAMES: Array[StringName] = [&"calm", &"shaken", &"hands_up", &"cowering", &"down", &"dead", &"fleeing",
		&"alarmed", &"watching", &"running"]


## Why he can't slow (the first of `can_slow`'s rules he fails; &"" when he can): for PeopleTick's
## counts (#495).
func slow_reason() -> StringName:
	if mood not in [Mood.CALM, Mood.SHAKEN, Mood.COWERING, Mood.WATCHING]:
		return MOOD_NAMES[mood]
	if reaction != null and reaction.moving():
		return &"route"
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
	if chore != null and chore.call(&"busy") and not (chore.has_method(&"lets_slow") and chore.call(&"lets_slow")):
		return &"chore"
	if not bit.is_empty() or not _bit_segs.is_empty():
		return &"bit"
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
	# (A bruise, a fall off a kicked chair, isn't a wound he's hurt by: #1248.)
	if p.injuries() > _wounds_seen:
		_wounds_seen = p.injuries()
		if p.is_conscious() and not held:
			_on_hurt()
	if body.limp:
		mood = Mood.DOWN
		if not held:
			_lying(delta)
		return
	_down_s = 0.0
	if mood == Mood.DOWN:
		# Back on his feet (HumanBody.get_up): shaken by it; hurt, he makes for a door.
		if body.rising:
			return  # (on his way up)
		mood = Mood.SHAKEN
		if hurt and not held and not _hurt_spent:
			_go_hurt()
	if held:
		return  # the scene has him
	_since_said += delta
	_hush = maxf(_hush - delta, 0.0)
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
	if _aimed > 0.0 and _aimed_by and is_instance_valid(_aimed_by) and not hurt:
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
	if reaction.step(delta):
		_chore(delta, false)
		_calm_for = 0.0
		return
	if _flinch > 0.0:
		_chore(delta, false)
		body.set_pose(&"hands_up" if _flinch > 0.5 else &"stand")
		return
	if _show_step(delta) and not _seated():
		_chore(delta, false)
		return  # (sat down, he shows it with his head only and stays in his chair: his chore goes on)
	_gun_watch -= delta
	if _gun_watch <= 0.0 or _gun_seen == null or not is_instance_valid(_gun_seen):
		_gun_seen = null
	if mood in [Mood.HANDS_UP, Mood.COWERING]:
		mood = Mood.SHAKEN
		say_relief()
	elif mood in [Mood.ALARMED, Mood.WATCHING, Mood.RUNNING]:
		mood = Mood.SHAKEN
	_calm_for += delta
	if mood == Mood.SHAKEN and _calm_for > 6.0 and fear < 0.2:
		mood = Mood.CALM
	# (Near enough his chore's own last steps take him: a chair's post is in the chair itself.)
	if returning and (post == Vector3.INF or body.global_position.distance_to(post) < RETURNED):
		returning = false
	if _chore(delta, mood == Mood.CALM and fear < 0.05 and not (helped_by and not thanked) and not returning):
		_bit_step(delta)
		return
	if post != Vector3.INF and body.global_position.distance_to(post) > 0.3:
		body.set_pose(&"stand")
		# Far off (a chore, a fright took him across the room): back by the town's places, round
		# whatever's between (a bar); near, straight there.
		var was := body.global_position
		if _home_detour != Vector3.INF:
			if body.walk_to(_home_detour, walk_speed, delta):
				_home_detour = Vector3.INF
		elif _far_from_post() and _places() != null:
			if _home_route.is_empty():
				_home_route = _route_home()
			if body.walk_to(_home_route[0], walk_speed, delta) and _home_route.size() > 1:
				_home_route.pop_front()
		else:
			_home_route.clear()
			body.walk_to(post, walk_speed, delta)
		# Caught on something (a table's corner, a rail, a porch's edge): a sidestep round it, one
		# way then the other (as running from a fire); then on past that point of the way, or, the
		# last of it, as near as he'll get (his chore takes him from there).
		# (His day's walks too since #1194: the loudmouth walked into the saloon yard's wall for minutes.)
		_home_stuck = _home_stuck + delta if body.global_position.distance_to(was) < 0.2 * delta else 0.0
		if _home_stuck > 1.0:
			_home_stuck = 0.0
			var goal := _home_route[0] if not _home_route.is_empty() and _far_from_post() else post
			var to := goal - body.global_position
			to.y = 0.0
			if _home_detour != Vector3.INF:
				_home_detour = Vector3.INF
			elif _home_detours < 4 and to.length() > 0.05:
				var side := Vector3(-to.z, 0.0, to.x).normalized() * (1.0 if _home_detours % 2 == 0 else -1.0)
				_home_detour = body.global_position + side * 1.2 * (1.0 + floorf(_home_detours / 2.0)) + to.normalized() * 0.3
				_home_detours += 1
			elif _home_route.size() > 1:
				_home_route.pop_front()
			elif returning:
				returning = false
			else:
				reroute()  # his day's walk, still caught: a fresh route from here, the sidesteps again
		return
	_home_stuck = 0.0
	_home_detours = 0
	_home_detour = Vector3.INF
	_home_route.clear()
	body.set_pose(rest_pose)
	_thank(delta)
	if _gun_seen != null:
		body.face(_gun_seen.global_position + Vector3.UP * 1.4)
	elif faces != Vector3.INF and not (helped_by and not thanked):
		body.face(faces)


## Far enough from his post to walk there by the town's places: over 1.5 m across, or a step up or down
## he can't just take (#1194: the townsman stood under the store porch's bench, 0.1 m across and 1.1 m
## below it, walking straight at the porch's side for minutes).
func _far_from_post() -> bool:
	var to := post - body.global_position
	return Vector2(to.x, to.z).length() > 1.5 or absf(to.y) > 0.5


## The way to his post by the town's places. A post up a step that no place has a straight walk to
## (#1194: the store porch's bench, the bench itself in the sweep's way) and he'd walk straight at the
## porch's side: by the nearest place at the post's own height (the store's door on its porch), then on.
func _route_home() -> Array[Vector3]:
	var r := FireFlight.route(_places(), body, post)
	if r.size() > 1 or absf(post.y - body.global_position.y) <= 0.5:
		return r
	var pl := _places()
	var best := &""
	var best_d := 8.0
	for n: StringName in pl.points:
		var at: Vector3 = pl.points[n]
		var d := Vector2(at.x - post.x, at.z - post.z).length()
		if absf(at.y - post.y) < 0.4 and d < best_d:
			best_d = d
			best = n
	if best == &"":
		return r
	var via := pl.route(World.space(body), body.global_position, best, FireFlight.exclude(body))
	if via.is_empty():
		return r
	via.append(post)
	return via


## His walk to his post started again from where he stands (a fresh route, the sidesteps again):
## ValleyFolk's stuck walks (#1194).
func reroute() -> void:
	_home_route.clear()
	_home_detour = Vector3.INF
	_home_detours = 0
	_home_stuck = 0.0


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


# --- The room's bits (townsfolk step 10, SaloonRoom): a small thing he does at his chore --------------

## The room's director gave him a bit: {what, for (s), look (whom he looks at), say + say_at (a
## line, said from his own mouth), mark + mark_t (a Callable at that moment), at (a point)}. He does
## it on top of his chore while he's calm at it; anything else and it's cut (`cut_bit`).
## what: laugh (head back, shoulders, mouth open, eyes creased), grin, toast (glass up), lift (glass
## half up), cough, stretch (sat, leant back), hail and wave (a hand up), nod, glass (the barkeep
## sets one down at `at`).
func start_bit(b: Dictionary) -> void:
	if not bit.is_empty():
		cut_bit()
	b["t"] = 0.0
	bit = b
	_bit_ticked = true
	body.wake()


## Stopped where it is (trouble, a look round, sent off): his mouth shut, its sound stopped.
func cut_bit() -> void:
	_end_bit(true)


func _end_bit(cut: bool) -> void:
	if bit.is_empty():
		return
	bit["cut"] = cut
	bit["ended"] = true
	if cut:
		var p: Variant = bit.get("player")
		if p != null and is_instance_valid(p):
			(p as AudioStreamPlayer3D).stop()
			(p as AudioStreamPlayer3D).queue_free()
		var sp := body.get_node_or_null(^"FaceSpeech") as FaceSpeech
		if sp != null and sp.speaking() and bit.what == &"laugh":
			sp.hush()
	bit.erase("player")
	bit.erase("mark")
	_head_tip(Vector3.ZERO)
	if chore is SpotChore:
		(chore as SpotChore).glass_up = 0.0
	bit = {}


## A lean of his chest or belly for a bit, eased (and eased off after: `_bit_tidy`).
func _bit_lean(seg: StringName, v: Vector3) -> void:
	_bit_segs[seg] = true
	body.pose_offsets[seg] = (body.pose_offsets.get(seg, Vector3.ZERO) as Vector3).lerp(v, 0.2)


func _bit_tidy() -> void:
	for seg: StringName in _bit_segs.keys():
		var v: Vector3 = (body.pose_offsets.get(seg, Vector3.ZERO) as Vector3).lerp(Vector3.ZERO, 0.15)
		if v.length() < 0.2:
			body.pose_offsets.erase(seg)
			_bit_segs.erase(seg)
		else:
			body.pose_offsets[seg] = v


func _bit_step(delta: float) -> void:
	if bit.is_empty():
		return
	_bit_ticked = true
	bit.t += delta
	var t: float = bit.t
	var span := float(bit.get("for", 2.0))
	if t >= span:
		_end_bit(false)
		return
	var k := clampf(t / 0.3, 0.0, 1.0) * clampf((span - t) / 0.4, 0.0, 1.0)
	var lk: Variant = bit.get("look")
	if lk != null and is_instance_valid(lk):
		_attend((lk as Node3D).global_position + Vector3.UP * 1.55)
	if bit.has("say") and not bit.get("said", false) and t >= float(bit.get("say_at", 0.0)):
		bit["said"] = true
		say_line(String(bit.say))
	if bit.has("mark") and not bit.get("marked", false) and t >= float(bit.get("mark_t", 0.0)):
		bit["marked"] = true
		(bit.mark as Callable).call()
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	var fwd := -body.global_basis.z
	match bit.what:
		&"laugh":
			if not bit.get("mouthed", false):
				bit["mouthed"] = true
				var sp := body.get_node_or_null(^"FaceSpeech") as FaceSpeech
				if sp != null:
					sp.say("ha ha ha ha ha ha ha")
			_head_tip(Vector3(13.0 * k * (0.7 + 0.3 * sin(t * 14.0)), 0, 0))
			_bit_lean(&"chest", Vector3(5.0 * k + 2.0 * k * sin(t * 19.0), 0, 0))
			if life != null:
				life.mirth = k
		&"grin":
			_head_tip(Vector3(3.0 * k, 0, 0))
			if life != null:
				life.mirth = 0.7 * k
		&"toast", &"lift":
			if chore is SpotChore:
				(chore as SpotChore).glass_up = k * (1.0 if bit.what == &"toast" else 0.45)
			if bit.what == &"toast":
				_bit_lean(&"chest", Vector3(4.0 * k, 0, 0))
		&"cough":
			_head_tip(Vector3(-12.0 * k, 0, 0))
			_bit_lean(&"chest", Vector3(-9.0 * k * absf(sin(t * 9.0)), 0, 0))
			body.reach_to("l", body.global_transform * Vector3(-0.02, 1.5, -0.2), fwd, k)
		&"stretch":
			_bit_lean(&"chest", Vector3(9.0 * k, 0, 0))
			_bit_lean(&"abdomen", Vector3(5.0 * k, 0, 0))
			_head_tip(Vector3(6.0 * k, 0, 0))
		&"hail", &"wave":
			var high := 1.8 if bit.what == &"hail" else 1.62
			body.reach_to("l", body.global_transform * Vector3(-0.3, high + 0.04 * sin(t * 7.0), -0.24), fwd, k)
			_head_tip(Vector3(4.0 * k, 0, 0))
		&"nod":
			_head_tip(Vector3(-10.0 * sin(clampf((t - 0.2) / 0.8, 0.0, 1.0) * PI), 0, 0))
		&"glass":
			var kk := smoothstep(0.4, 1.2, t) * (1.0 - smoothstep(1.6, 2.4, t))
			var at: Vector3 = bit.get("at", body.global_position)
			body.reach_to("r", at + Vector3.UP * 0.07, Vector3.UP, kk)
			_bit_lean(&"chest", Vector3(-8.0 * kk, 0, 0))


# --- Regard (townsfolk step 9): what he shows Harlan before anyone speaks ----------------------------

## Calm at his post, nothing on him: he may show Harlan what he thinks of him.
func can_show() -> bool:
	return not held and mood == Mood.CALM and fear < 0.1 and not reaction.active() and not returning \
			and _bucket == &"" and showing.is_empty() and body.physiology.is_conscious() and not body.limp


## Show `who` his regard: &"nod" (a nod, a touch of the head), &"look_away" (a look that slides off),
## &"turn" (a turned shoulder), &"clear" (out of his way: a step aside, eyes down).
func show_regard(what: StringName, who: Node3D) -> void:
	showing = {"what": what, "who": who, "t": 0.0, "aside": Vector3.INF}
	last_shown = what
	if what == &"clear":
		var to := body.global_position - who.global_position
		to.y = 0.0
		var side := Vector3(-to.z, 0.0, to.x).normalized() if to.length() > 0.1 else body.global_basis.x
		# The side away from where Harlan's headed (his facing), and back from him a little.
		var heading := -who.global_basis.z
		if side.dot(heading) > 0.0:
			side = -side
		showing.aside = body.global_position + side * 1.6 + to.normalized() * 0.4


## How long each show lasts (s); `clear` till he's off or this long.
const SHOW_FOR := {&"nod": 1.6, &"look_away": 1.8, &"turn": 3.0, &"clear": 6.0, &"look": 4.0}


## The room's gone quiet and he looks round to see why (SaloonRoom's hush, townsfolk step 10): at
## `who` (or the point `at`) for `seconds`; on his feet he turns to it, his chore stopped; sat, his
## head and eyes only. Not his regard: nothing's kept of it.
## His own place's glass or boards broken (ValleyFolk._on_damage, #1213): he turns to it and whoever did
## it, and has his say, the owner's, not a bystander's.
func damaged_mine(at: Vector3, who: Node3D) -> void:
	if not body.physiology.is_conscious():
		return
	fear += 0.05
	show_look(at, who, 5.0)
	_since_said = SAY_GAP  # his own glass: he speaks up, whatever he was saying
	say(&"damage_mine")
	_mine_frame = Engine.get_physics_frames()


func show_look(at: Vector3, who: Node3D = null, seconds := 4.0) -> void:
	showing = {"what": &"look", "who": who, "at": at, "for": seconds, "t": 0.0, "aside": Vector3.INF}


func _show_step(delta: float) -> bool:
	if showing.is_empty():
		return false
	var who_v: Variant = showing.who
	var who: Node3D = who_v as Node3D if who_v != null and is_instance_valid(who_v) else null
	showing.t += delta
	var t: float = showing.t
	var what: StringName = showing.what
	if what == &"look":
		if t >= float(showing.get("for", SHOW_FOR[what])):
			showing = {}
			return false
		var point: Vector3 = who.global_position + Vector3.UP * 1.4 if who != null else showing.at
		_attend(point)
		if not _seated():
			body.set_pose(&"stand")
			_turn_to(point, delta)
		return true
	if who == null or t >= float(SHOW_FOR[what]) \
			or what == &"clear" and t > 1.0 and who.global_position.distance_to(body.global_position) > 5.0:
		_head_tip(Vector3.ZERO)
		showing = {}
		if what == &"clear" and post != Vector3.INF and body.global_position.distance_to(post) > RETURNED:
			returning = true  # back to his place once Harlan's by
		return false
	var at := who.global_position + Vector3.UP * 1.5
	if _seated():
		# In his chair: his head and eyes only (a man at the cards doesn't get up to nod at you).
		match what:
			&"nod":
				_attend(at)
				_head_tip(Vector3(-11.0 * sin(clampf((t - 0.3) / 0.9, 0.0, 1.0) * PI), 0, 0))
			&"look_away", &"turn":
				if t < 0.5 and what == &"look_away":
					_attend(at)
				else:
					var off := body.global_position + (at - body.global_position).rotated(Vector3.UP, deg_to_rad(-80.0))
					_attend(Vector3(off.x, body.global_position.y + 0.9, off.z))
			&"clear":
				_head_tip(Vector3(-14.0, 0, 0))
		return true
	body.set_pose(&"stand")
	match what:
		&"nod":
			_turn_to(at, delta)
			_attend(at)
			var k := clampf((t - 0.3) / 0.9, 0.0, 1.0)
			_head_tip(Vector3(-11.0 * sin(k * PI), 0, 0))
		&"look_away":
			if t < 0.6:
				_turn_to(at, delta)
				_attend(at)
			else:
				# Eyes off: down and to the side away from him.
				var off := body.global_position + (at - body.global_position).rotated(Vector3.UP, deg_to_rad(-70.0))
				_attend(Vector3(off.x, body.global_position.y + 0.6, off.z))
				_head_tip(Vector3(-6.0, -30.0, 0))
		&"turn":
			# His shoulder to Harlan: square side-on and a little away.
			var away := body.global_position + (body.global_position - who.global_position).rotated(Vector3.UP, deg_to_rad(70.0))
			_turn_to(away, delta)
		&"clear":
			_head_tip(Vector3(-14.0, 0, 0))  # nobody meets his eye
			if showing.aside != Vector3.INF and body.walk_to(showing.aside, walk_speed * 1.2, delta):
				showing.aside = Vector3.INF
				_turn_to(at, delta)
	return true


## Sat in a chair (a SitChore has him).
func _seated() -> bool:
	for c: RefCounted in chores:
		if c is SitChore and (c as SitChore).busy():
			return true
	return false


## His head tipped (degrees, pose_offsets' axes): through his face's gaze, which owns his head's
## offset each frame (FaceGaze.nod), or straight onto his pose if he has no face.
func _head_tip(v: Vector3) -> void:
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	if life != null and life.gaze != null:
		life.gaze.tip = v
	elif v == Vector3.ZERO:
		body.pose_offsets.erase(&"head")
	else:
		body.pose_offsets[&"head"] = v


func _attend(point: Vector3) -> void:
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	if life != null:
		life.attend_to(point)


## Turned toward `point` at a man's pace (not snapped round).
func _turn_to(point: Vector3, delta: float) -> void:
	var want := HumanBody.yaw_toward(body.global_position, point)
	body.global_rotation.y = rotate_toward(body.global_rotation.y, want, 5.0 * delta)


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
	var r: String = reaction.describe() if reaction else ""
	return "%s: %s%s, fear %.2f. %s" % [String(body.person_id).capitalize(), how, (" (" + r + ")") if r != "" else "",
			fear, body.physiology.describe()]
