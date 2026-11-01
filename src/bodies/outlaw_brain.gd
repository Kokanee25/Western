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
	&"hat": ["My hat!", "That was a good hat, you son of a—", "Close. Real damn close."],
	&"hit": ["Agh—!", "Son of a—!", "I'm hit, damn it!"],
	&"menace": ["Back off! Back off or he's dead!", "One more step and I kill him, I swear to God!", "You hear me? He's dead if you come in here!"],
	&"blasted": ["My ears— I can't hear!", "God, my head...", "Christ! Christ almighty!"],
	&"gut": ["Oh God, not the belly..."],
	&"cornered": ["Come on, then! Come on!", "You'll have to kill me!", "Not like this. Not to you."],
	&"back_off": ["I'm getting out of here...", "Easy... easy... I'm going.", "Not worth dying for."],
	&"hit_light": ["Just a scratch.", "Ain't nothing. Ain't nothing.", "Hell. That all you got?"],
	&"hit_bad": ["Oh God, it's bad...", "I'm bleeding bad!", "Lord, look at that..."],
	&"hit_arm": ["My arm! Can't hold the damn thing!", "Can't hold it... can't hold it..."],
	&"surrender": ["Alright! Alright! I'm done!", "Don't shoot! I quit, I quit!", "Enough! It's yours!"],
	&"shaken": ["Hell. Hell, hell, hell...", "Stay down... stay down...", "Lord, get me out of this one."],
	&"rally": ["Alright. Alright, you son of a—", "Still here, mister!", "That all you got?"],
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
	&"arrested": ["Alright, alright. Easy with that.", "You got me. Don't make 'em tight.", "Go on, then."],
	&"tend": ["Damn, damn...", "Hold it together..."],
	&"drink": ["Whiskey. Leave the bottle.", "Another.", "This the best you got?"],
	&"fire": ["Place is going up!", "Fire! Let's git!", "Hell, she's burning!", "Out! Get out!"],
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
	&"call_press": ["He's empty! Get him!", "He's hit! Go, go!", "Now! Rush him!"],
	&"call_shaken": ["He's got me pinned!", "I can't get my head up!"],
	&"call_hold": ["Hold, damn it! Stay in it!", "{name}! Stay in it, you hear?", "Nobody runs! Hold!"],
	&"call_give_up": ["That's it, boys. Throw 'em down.", "Enough! We're done. Drop 'em."],
	&"scorn": ["Get up, you yellow dog!", "{name}! Pick up that gun!"],
	&"rage": ["You'll pay for that!", "You son of a bitch! Come on!"],
	&"watch_it": ["Watch where you're shooting!", "Hey! That was me!"],
}

## How much fear he can carry before he breaks. A hired gun; a family man would be lower.
@export var nerve := 0.75
@export var rounds_per_load := 5
@export var reload_seconds := 12.0
@export var seconds_between_shots := 1.4
## Fear from being hit at all, and more if it broke bone or tore something vital.
@export var fear_per_hit := 0.25
@export var fear_per_severe_hit := 0.14
@export var fear_pellet_share := 0.4
## A ball through his hat: the nearest a near miss gets (on top of the near miss itself).
@export var fear_hat_shot := 0.3
## When his nerve goes and he can run, the chance he runs rather than gives up.
@export var flee_chance := 0.55
## Past his nerve behind cover he goes to ground rather than quit on the spot (shaken): this long
## at most (s) for it to pass; and it doesn't hold him once he's this far past his nerve.
@export var shaken_seconds := 6.0
@export var shaken_margin := 0.5
## Behind cover with nothing cracking past him, his fear settles this fast (a second; it settles
## 0.01 a second anywhere else). A gun kept on his spot frightens him 0.045 a second (`aim_at`).
@export var fear_settle_in_cover := 0.08
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

## How he fights, the gunfight lab's four (`experiments/gunfight_lab/`; Y/X/Z play them):
## A as before the lab (shots in a random cone round his aim, cover found within a step of his
## own height); B aims by his hand (`GunHand`), takes a moment to react and finds the town's cover
## (doorways, round the bar, up or down a step); C is B and shaken before he breaks. D is C and
## fights that commit, the game's since 2026-10-23 (`default_variant`; it was A) (Sean's first play,
## issue #257: "the bad guys just kept quitting"): noise and near misses pin a man but don't break
## him (`fright`, fading in seconds, counts for at most a share of his nerve); a gun held on him in a
## fight is just the fight; a hothead never quits early; the man who leads them holds the rest while
## he's in it; and a green man's quitting barely shakes the others. `D_FIXES` names each, so the lab
## can try one at a time.
enum Variant { A, B, C, D }
static var default_variant := Variant.D
var variant: Variant = default_variant
## D's fixes, each on unless the lab leaves it out (`experiments/gunfight_lab/`, `fixes=`):
## aim_fight (aimed at frightens before a fight, not in one), noise (near misses, a shot nearby and a
## hat shot are fright, not dread), hothead (a man of temper holds his first half minute), leader
## (the man who leads holds the rest, and calls a shaken one back), green (a man of little nerve
## quitting barely shakes the rest), cover_way (a longer way round to real cover: the bar's end),
## steady (the thump of a ball frightens a steady man less: `_thump`), floored (knocked off his
## feet but not beaten, he gets up rather than give up to the man standing over him), hunt_way
## (looking for you, he goes by the town's ways, out of the door and round the bar, not into a wall),
## rescue_way (a friend down he goes for only if he can get to him by the town's ways, and goes by
## them), stay_in (he doesn't stand down while a friend in earshot's still on the man), go_low (in
## the open under fire he fights from a knee), press (the man's reloading or just hit: he comes at
## him, and calls the others on), hold_cover (#294: behind cover he holds it against the idea of
## the man he chose it by, moved only by what he's sure of, not by a guess at a sound). On trial, not yet in D_FIXES (the lab's `fixes=all+wince`): wince
## (hit and still up, he winces and gets out of sight a moment to see how bad it is); pain_fight
## (pain past disabling comes in bouts, not as a wall); floor_fight (shot down and still with it, he
## fights from the floor); flinch (spec 3A: a ball past him spoils his shot, FLINCH_*); odds (spec 1C: past his nerve he weighs it, ODDS_*); way_cost (Experiment B: cover scored by the way he'd run to it, not the
## straight line).
const D_FIXES := [&"aim_fight", &"noise", &"hothead", &"leader", &"green", &"cover_way", &"steady", &"floored", &"hunt_way",
		&"rescue_way", &"stay_in", &"go_low", &"press", &"hold_cover"]
static var d_fixes: Array = D_FIXES.duplicate()
## Fright (variant D's `noise`): fades this fast (a second), and counts toward breaking him for at
## most this share of his nerve: noise alone can pin a man, never break him.
const FRIGHT_FADE := 0.12
const FRIGHT_SHARE := 0.4
const RATTLED_FADE := 0.02
## A hothead (temper this high or more) holds this long into a fight (s) on this much more nerve
## (a share of his temper): he's too angry to quit early.
const HOT_TEMPER := 0.7
const HOT_EARLY := 30.0
const HOT_NERVE := 0.5
## The man who leads them, up and in it within earshot: this much more nerve for each of the rest
## (times the man's own: Lyle +0.18, the Kid +0.08);
## and his "Hold!" takes this much off a shaken man's fear.
const LEADER_NERVE := 0.25
const LEADER_HOLD := 0.15

## Where he can go in this town (set by whoever brought him in: TownLife), and his place at the bar.
var places: Waypoints
var bar_spot := &""
## What he means to do, in order. Steps: {do: &"go", to: <place>}, {do: &"drink", seconds, face},
## {do: &"harass", who, seconds, rough}, {do: &"call_out", who}, {do: &"duel", who},
## {do: &"wait", seconds}, {do: &"leave"}, {do: &"post"} (holding a house: at his post, `hold`). He gets
## on with it while nobody's troubling him.
var agenda: Array[Dictionary] = []
## Holding a house he's been told to hold (the farmhouse, issue #520: #477's "stay in cover", for a
## house alone, not the town's fights), set by whoever posts him (FarmhouseMission): "inside"
## (Callable(Vector3) -> bool: the house, or for the guard his room), "post" (where he stands
## watching before it starts, and goes back to when he's lost you), "look" (what he watches from
## it). With it he takes cover only inside, hunts you only inside, never presses or rages out after
## you, and after the fight he goes back to his post (he doesn't leave town). Empty: the town's man.
var hold := {}
## Seconds left dazed by a blast that hurt him (deafened, his head ringing: `_blasted`).
var stunned := 0.0
## A man he's holding (the hostage, issue #520): set, he goes to him and puts his gun on him (his
## threat: `menace_fire` false); with `menace_fire`, he shoots him (FarmhouseMission's guard).
var menace: HumanBody = null
var menace_fire := false
## How many balls he puts into him (FarmhouseTuning.execute_shots).
var menace_shots := 2
var _menace_said := false
var _menace_shots := 0
var _post_way: Array[Vector3] = []
var _fled_said := -99.0
## A spot he's been told to hold (HouseDefence, the farmhouse: a window, a door to cover, a hole):
## {id, at, look (what he watches from it), low (cover he crouches behind, up to shoot), window
## (stand to shoot, below the sill under fire), why}. Empty: he picks his own (Cover).
var order := {}
var _order_way: Array[Vector3] = []
var _order_stuck := 0.0
var _tend_said := -99.0
var _post_glance := 0.0
var _post_look := Vector3.INF

var body: HumanBody
var mood := Mood.CALM
var fear := 0.0
## Where his fear came from (`_scare`): why -> how much, all told.
var fear_from := {}
## Variant D: the fright of noise (near misses, shots nearby, a hat shot), apart from his fear.
var fright := 0.0
## ... and how rattled it's left his hand (fades at RATTLED_FADE: as slowly as fear settles).
var rattled := 0.0
var _fight_from := -1.0  # when this fight started (his clock), -1 not in one
var _leader_t := 0.0
var _leader_near := false
var _hunt_way: Array[Vector3] = []  # variant D's hunt_way: his way to where he last knew you
var _hunt_to := Vector3.INF
var _hunt_t := 0.0
var _press := 0.0  # variant D's press: seconds left coming at him
## Variant D's wince: seconds left looking at his wound, where it is (segment, part-local), how bad
## it was when it hit, and the fear it gave him.
var _wince := 0.0
var _wince_seg := &""
var _wince_at := Vector3.ZERO
var _wince_severe := false
var _wince_fear := 0.0
## Variant D's pain_fight: seconds left of a bout of pain, and whether it was past disabling last tick.
var _pain_bout := 0.0
## Variant D's odds: seconds left he won't break (taking stock after a hit, fighting it out
## cornered, gone to ground to weigh it), and whether he's already gone to ground once this time.
var _hold_break := 0.0
## Variant D's flinch: degrees his aim is off from a ball just past him (fading), and seconds left
## he's firing through it, hurried.
var _flinch_spread := 0.0
var _hurry := 0.0
var _hid_once := false
var _pain_over := false
var _you_hit_at := -INF  # when he last saw the man he's fighting hit
var rounds := 5
var target: Node3D

var _rng := RandomNumberGenerator.new()
## Separate from his aim, so choosing where to hide doesn't change how he shoots.
var _think := RandomNumberGenerator.new()
## His judgement of range (separate again, so it doesn't shift his aim's sequence).
var _range_rng := RandomNumberGenerator.new()
## Spread of his shots in degrees when calm and unhurt (variant A's cone).
@export var spread_degrees := 2.4
## How far off he judges the range this shot (a share; drawn again after each).
var _range_err := 1.0
## Where his barrel really points (GunHand: the player's sway with his own sizes), and its dials.
var hand: GunHand
static var _hand_tuning: GunHandTuning
## The moment before he moves, when it comes to a fight he didn't start.
var _react := 0.0
## Seconds he's held on his man waiting for his sights, the frame he last did, and the squeeze
## (trigger lag left; < 0 not squeezing).
var _on_sights := 0.0
var _sights_frame := -1
var _squeeze := -1.0
## Whether he's aiming at your head (all he can see of you over cover), worked out once a tick.
var _aim_head := false
var _aim_frame := -1
## The poses he aims in, and the low ones (steadier).
const AIM_POSES := [&"aim", &"crouch_aim"]
const LOW_POSES := [&"crouch_aim", &"crouch", &"duck", &"lie", &"prone"]
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
var _search_eye := Vector3.INF  # where he took your eyes to be when he started that search (the spot keeps it: cover.eye)
var _sure := false  # variant D's hold_cover: something he's sure of told him where you are since his last look (`_held_eye`)
## Keeping his head down: seconds left (rounds cracking past).
var suppressed := 0.0
## How long he's been shaken (gone to ground past his nerve), or -1 when he isn't.
var _shaken := -1.0
## What he last decided in a fight and why, from what's happened to him ("to cover: in the open",
## "look for him: lost sight 4 s"): shown on F3, logged by the gunfight lab. Never read by him.
var decision := ""
var decision_at := 0.0
var _search_why := ""
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
## Getting clear of a fire while he's going about his day: the way out, and when he next looks.
var _fire_way: Array[Vector3] = []
var _fire_look := 0.0
var _fire_fled := -INF
const FIRE_REACH := 8.0
const FIRE_CLEAR := 15.0
const FIRE_RUN := 3.6
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
## Who's arrested him (null: nobody has). Hands bound, he goes along where he's taken.
var arrested_by: Node3D = null
## Arrested and told to come along (false: told to wait where he is).
var follow := true
## Down on the ground with his legs gone, how soon he looks again for a gun coming at him.
var _give_up_look := 0.0
## An unplaced shot: where he heard it, and how much longer he looks that way (s).
var _startled_at := Vector3.INF
var _startled := 0.0


func _ready() -> void:
	set_physics_process(true)  # its switch (PeopleTick ticks it while on)
	body = get_parent() as HumanBody
	_rng.seed = body.rng_seed * 31 + 7
	_think.seed = body.rng_seed * 17 + 3
	_range_rng.seed = body.rng_seed * 23 + 11
	hand = GunHand.new(hand_tuning(), body.rng_seed * 41 + 13)
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
	senses.heard.connect(_on_heard)
	Events.deed.connect(_on_deed)
	body.hit.connect(_on_hit)
	body.fell.connect(_on_fell)
	Events.near_miss.connect(_on_near_miss)
	Events.hat_shot.connect(_on_hat_shot)
	Events.shouted.connect(_on_shouted)
	Events.exploded.connect(_on_exploded)
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, who: Node) -> void: if who == _find_target(): _quiet = 0.0)
	Events.scorched.connect(func(who: Node, amount: float) -> void: if who == body: _scare(amount * 0.6, &"fire"))
	Events.hours_passed.connect(_on_hours_passed)
	Events.bullet_hit.connect(func(info: Dictionary) -> void:
		var who: Variant = info.get("person")
		if who is PlayerWounds:
			who = (who as PlayerWounds).player
		if who != null and who == _find_target() and senses and senses.sees(who as Node):
			_you_hit_at = _now)
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
## A shot's deed (shoot_at, hit, kill) goes with a shot he heard this recently (s).
const SHOT_HEARD_WITHIN := 1.5
## The sounds a man makes, that a man hunting him takes for his.
const MAN_SOUNDS := [&"footsteps", &"gunshot", &"shout", &"speech", &"scuffle"]
## How high over a man's feet each of his sounds is made (m): a gun held up, his mouth, the man he
## kicked or shoved (`PlayerShove`'s scuffle, at the other's body).
const SOUND_HEIGHT := {&"gunshot": 1.4, &"shout": 1.6, &"speech": 1.6, &"scuffle": 1.0}
## How far he reckons a man he's lost can have got (m a second, from where he last knew him, on
## top of a few metres' slack): a brisk walk. A man who runs gets further, and away.
const MAN_SPEED := 2.0
## An unplaced shot when all's calm: how much it unsettles him, and how long he looks its way (s).
const STARTLE_FEAR := 0.04
const STARTLE_LOOK := 2.5
## A lit fuse he hears (every half second it burns): how much each hiss frightens him.
const FUSE_FEAR := 0.04


## Could that man be where a sound came from: near where he last knew him, or as far off as a man
## walks in the time since?
func _could_be(who: Node, at: Vector3) -> bool:
	var lk := senses.last_known(who)
	if lk == Vector3.INF:
		return false
	var reach := 3.0 + MAN_SPEED * minf(senses.since_known(who), 15.0)
	return Vector2(at.x - lk.x, at.z - lk.z).length() <= reach


## A sound he couldn't put a face to. Hunting a man he can't see, a man's sound (steps, a shot, a
## voice) where that man could have got to he takes for him, unless one of his friends is right
## there (he knows where his own are): so he can be fooled. Otherwise a shot is a shot over there:
## it unsettles him and turns his head.
func _on_heard(at: Vector3, kind: StringName, who: Node) -> void:
	if who != null or not body.physiology.is_conscious() or mood in [Mood.DEAD, Mood.SURRENDERED]:
		return
	var t := _find_target()
	if t != null and not senses.sees(t) and kind in MAN_SOUNDS and _could_be(t, at) \
			and not crew.standing(_now).any(func(m: HumanBody) -> bool: return m.global_position.distance_to(at) < 3.0):
		# Where the man stands, not where the noise was made: a shot's at his gun, a shout at his
		# mouth (variant D's `hold_cover`; else his eyes were taken to be 1.6 m over his gun).
		senses.note(t, at + Vector3.DOWN * float(SOUND_HEIGHT.get(kind, 0.0)) if _has(&"hold_cover") else at, 0.0)
		return
	if kind == &"fuse":
		# A lit fuse hissing near him (a planted stick, #506): it frightens him a little more each
		# time he hears it, and turns his head. Getting clear of it isn't built: that's his fear's.
		_scare(FUSE_FEAR, &"a fuse hissing")
		_startled_at = at
		_startled = STARTLE_LOOK
		return
	if kind == &"gunshot" and mood == Mood.CALM:
		_scare(STARTLE_FEAR, &"a shot nearby")
		_startled_at = at
		_startled = STARTLE_LOOK


static func _armed(who: Node) -> bool:
	if who is Player:
		var w := (who as Player).weapon
		return w != null and w.armed and w.selected and w.drawn
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
	if to_me:
		body.wake()  # done to him: he takes it in next tick, far off or not (PeopleTick's bands)
	# Words shouted at him he hears whether he can see who it is or not.
	var shouted := kind in [&"shout", &"call_out"] and to_me
	if not loud and not shouted and not senses.sees(actor) and not (to_me and senses.aware_of(actor) > 0.6):
		return
	if shouted and not senses.sees(actor) and actor is Node3D:
		senses.note(actor, (actor as Node3D).global_position, 1.5)
	if loud and not to_me and not senses.sees(actor):
		# A shot somewhere he didn't see: he knows someone's shooting, not who, unless it came from
		# where he knew that man to be (Senses.sounds; the perception lab, 2026-10-22: a shot in the
		# saloon set a man at the far end of the street against the shooter he'd never seen).
		var shot := senses.last_sound([&"gunshot"], SHOT_HEARD_WITHIN)
		if shot.is_empty() or not _could_be(actor, shot.at):
			return
		senses.note(actor, shot.at, 0.0)
	elif loud and actor is Node3D and not senses.sees(actor):
		# At him: the ball tells him which way it came from, roughly.
		senses.note(actor, (actor as Node3D).global_position, 0.1 * body.global_position.distance_to((actor as Node3D).global_position))
	var dt := PlayerDeeds.EVERY if kind in [&"aim_at", &"crowd", &"stare"] else 1.0
	if kind in [&"draw", &"holster"] and deed_target == null and actor is Node3D \
			and (actor as Node3D).global_position.distance_to(body.global_position) < NEAR:
		deed_target = body  # a gun drawn a few yards off is about him
	relations.perceive(actor, kind, deed_target, dt)
	if to_me and kind == &"aim_at" and not relations.entry(actor).cowed and not (_has(&"aim_fight") and mood != Mood.CALM):
		_scare(0.045 * dt * (1.5 if _facing_shotgun else 1.0), &"aimed at")
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


## `his_idea`: he started it (the duel's draw), so there's no moment of taking it in.
func _start_fight(with_who: Node, his_idea := false) -> void:
	if with_who == null or not is_instance_valid(with_who):
		return
	if mood == Mood.CALM:
		say(&"provoked")
		_set_mood(Mood.FIGHTING)
		_fight_from = _now
		_next_shot = _rng.randf_range(0.6, 1.1)
		tactic = Tactic.OPEN
		_cover_search = 0.0
		if not his_idea and variant != Variant.A:
			_react = _reaction()
	target = with_who as Node3D
	if not senses.knows(with_who):
		# It's come to a fight with him: he knows which way he is, at least.
		senses.note(with_who, (with_who as Node3D).global_position, 1.0)
	if body.gun_holstered and _react <= 0.0:
		body.draw_gun()


## The moment it takes him to take in that it's come to shooting and move: a hothead's quicker
## than a cool man, a man of no nerve slower.
func _reaction() -> float:
	var t := hand_tuning()
	return lerpf(t.react_cool, t.react_hot, clampf(temper, 0.0, 1.0)) + (1.0 - clampf(nerve, 0.0, 1.0)) * t.react_timid \
			+ _think.randf() * t.react_spread


static func hand_tuning() -> GunHandTuning:
	if _hand_tuning == null:
		_hand_tuning = load("res://config/gun_hand.tres")
	return _hand_tuning


## His hat shot off his head: a fright like no other near miss, heads down, and he says so.
func _on_hat_shot(person: Node, shooter: Node, _at: Vector3) -> void:
	if person != body:
		return
	_scare(fear_hat_shot, &"hat shot")
	suppressed = maxf(suppressed, 3.0)
	if tactic == Tactic.PEEKING:
		_duck_back()
	say(&"hat")
	if mood != Mood.SURRENDERED:
		_provoked(shooter)


func _on_near_miss(person: Node, shooter: Node, distance: float, _at: Vector3, _speed: float, _tumbling: bool) -> void:
	if person != body:
		return
	_scare(0.06 * clampf(2.5 - distance, 0.5, 2.5), &"near miss")
	var close := clampf(1.0 - distance / 2.5, 0.0, 1.0)
	hand.jerk(hand_tuning().near_miss_jerk * clampf(2.5 - distance, 0.3, 2.5) / 2.5 * (1.0 + FLINCH_JERK * close if _has(&"flinch") else 1.0))
	if _has(&"flinch") and mood in [Mood.FIGHTING, Mood.RELOADING]:
		_flinch_spread = maxf(_flinch_spread, FLINCH_SPREAD * close) + (FLINCH_SQUEEZE * close if _squeeze >= 0.0 else 0.0)
		if temper >= HOT_TEMPER or dread() > nerve_now() * FLINCH_SCARED:
			_hurry = FLINCH_HURRY
		else:
			_next_shot = maxf(_next_shot, FLINCH_HOLD.x + FLINCH_HOLD.y * close)
			_on_sights = 0.0
	_react = minf(_react, 0.15)  # rounds cracking past get a man moving
	_sure = true
	if shooter is Node3D and senses and not senses.sees(shooter):
		senses.note(shooter, (shooter as Node3D).global_position, 0.1 * body.global_position.distance_to((shooter as Node3D).global_position))
	# Heads down.
	suppressed = maxf(suppressed, 1.0 + clampf(2.5 - distance, 0.0, 2.5) * 0.5)
	if tactic == Tactic.PEEKING:
		_duck_back()
	if mood == Mood.SURRENDERED:
		_scare(0.05, &"near miss")
		return
	_provoked(shooter)


func _on_hit(info: Dictionary) -> void:
	match info.get("kind", &"bullet"):
		&"cut":
			_scare(0.04, &"hit")
			return
		&"blast":
			_blasted(info)
			return
		&"blow":
			_scare(clampf(float(info.get("joules", 0.0)) / 600.0, 0.05, 0.5), &"hit")
			return
		&"graze":
			var before := fear
			_scare(fear_per_hit * 0.5, &"hit")
			if info.get("shooter") != null:
				_provoked(info.shooter)
			_start_wince(info, fear - before)
			return
	# Bad wounds frighten more than grazes; so does the thump of a ball stopping inside him.
	# Each buckshot pellet counts for a share: a charge lands several at once.
	var share := fear_pellet_share if info.get("kind", &"bullet") in [&"pellet", &"splinter", &"gravel"] else 1.0
	var fear_before := fear
	_scare((fear_per_hit + (fear_per_severe_hit if info.get("severe", false) else 0.0) \
			+ float(info.get("deposited", 0.0)) / 2000.0) * share * _thump(), &"hit")
	_stagger = maxf(_stagger, 0.45 + float(info.get("deposited", 0.0)) / 700.0)
	hand.jerk(hand_tuning().hit_jerk * share)
	_react = minf(_react, 0.15)
	_sure = true
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
			_scare(0.1 * _thump(), &"hit")
	_start_wince(info, fear - fear_before)
	if _has(&"odds") and mood in [Mood.FIGHTING, Mood.RELOADING]:
		_hold_break = maxf(_hold_break, lerpf(ODDS_STOCK.x, ODDS_STOCK.y, clampf(nerve, 0.0, 1.0)))


## A blast that hurt him (HumanBody.take_blast's hit, its `harm`: thrown down, burst eardrums, a
## limb), not a ball (#488's gap: it was taken as one, "I'm hit!", a stagger and a turn on the
## shooter). He's dazed by how hard it hit him (deafened, his head ringing: he does nothing for a
## moment, longer the nearer he was), frightened by what it did to him on top of its fright
## (`_on_exploded`); there's no shooter to turn on, and he doesn't call out "hit".
func _blasted(info: Dictionary) -> void:
	var kpa := float(info.get("kpa", 0.0))
	stunned = maxf(stunned, clampf(kpa / 20.0, 1.0, 6.0) * _think.randf_range(0.8, 1.2))
	_scare(0.1 * (info.get("harm", []) as Array).size() * _thump(), &"blast")
	_react = minf(_react, 0.15)
	if mood == Mood.SURRENDERED:
		return
	say(&"blasted")
	if not _said_gut and body.physiology.gut_seconds >= 0.0:
		_said_gut = true
		say(&"gut")


## Variant D's `wince`: hit and still on his feet and in it, he winces and gets out of sight to see
## how bad it is (`_wince_step`). Not as he goes down, not dragging a friend, not in a rage.
func _start_wince(info: Dictionary, scared: float) -> void:
	if not _has(&"wince") or not mood in [Mood.FIGHTING, Mood.RELOADING] or body.prone or body.limp \
			or body.stumbling > 0.0 or info.get("knocked_down", false) or rage > 0.0 or tactic == Tactic.RESCUING:
		return
	var seg: StringName = info.get("segment", &"")
	if not body.parts.has(seg):
		return
	var t := WINCE_TIME * lerpf(WINCE_GREEN, 1.0, clampf(nerve, 0.0, 1.0)) * (1.0 - WINCE_HOT * clampf(temper, 0.0, 1.0))
	var severe: bool = info.get("severe", false)
	if severe:
		t *= WINCE_SEVERE
	if info.get("kind", &"bullet") == &"graze":
		t *= WINCE_GRAZE
	t *= _think.randf_range(0.8, 1.2)
	_wince_severe = severe or (_wince > 0.0 and _wince_severe)
	_wince_fear = scared + (_wince_fear if _wince > 0.0 else 0.0)
	_wince = maxf(_wince, t)
	_wince_seg = seg
	_wince_at = (body.parts[seg] as Node3D).global_transform.affine_inverse() * (info.get("position", body.global_position) as Vector3)
	_press = 0.0
	_stand_and_fight = false
	match tactic:
		Tactic.PEEKING:
			_duck_back()
		Tactic.HIDDEN, Tactic.MOVING:
			pass
		_:
			tactic = Tactic.OPEN
			_search = null
			_seek_cover(_eye_of(_find_target()) if _find_target() else body.global_position, Vector3.INF, WINCE_TRAVEL, 3.0,
					"hit, getting out of your sight")
	_decide("wince, get out of sight", "hit in the %s: seeing how bad (%.1f s)" % [seg, t])


## Wincing: no shooting; behind his cover, down low (or hunched over it standing behind a wall); in
## the open, low where he is till he's somewhere to go. His eyes on the wound. Running for cover he
## goes on running (false: the rest of `_combat` has him), and the time he takes over it starts once
## he's there. Then he's seen it: `_seen_wound`.
func _wince_step(delta: float, t: Node3D) -> bool:
	if tactic == Tactic.MOVING:
		return false  # (his look at it starts once he's there)
	_wince -= delta
	if _wince <= 0.0:
		_seen_wound()
		return false
	var seg_node := body.parts.get(_wince_seg) as Node3D
	if seg_node != null:
		var life := body.get_node_or_null(^"FaceLife") as FaceLife
		if life != null:
			life.attend_to(seg_node.global_transform * _wince_at, true)
	if tactic == Tactic.HIDDEN and not cover.is_empty():
		body.face(_eye_of(t))
		body.set_pose(&"duck" if cover.low else &"wince")
		return true
	tactic = Tactic.OPEN
	_step_search()
	if tactic == Tactic.OPEN:
		body.set_pose(&"duck")
	return tactic != Tactic.MOVING


## He's looked at it. A light one (it isn't bleeding past clotting, his gun hand holds; how much it
## hurts is his body's: a ball through the arm hurts past disabling for a while whatever it is): it
## frightens him less than it did, and he's back up soon. A bad one he says
## so, and what he does about it is his fear's and his blood's (tending, breaking).
func _seen_wound() -> void:
	_wince = 0.0
	var p := body.physiology
	var arm := not p.can_hold("r")
	var bad := _wince_severe or arm or p.total_bleed_rate() > p.tuning.clot_max_rate
	if bad:
		say(&"hit_arm" if arm else &"hit_bad")
		_decide("seen his wound: bad", "bleeding %.1f ml/s, pain %.2f%s" % [p.total_bleed_rate(), p.felt_pain(), ", his gun arm" if arm else ""])
	else:
		var relief := minf(_wince_fear * WINCE_RELIEF, fear)
		fear -= relief
		fear_from[&"hit"] = maxf(float(fear_from.get(&"hit", 0.0)) - relief, 0.0)
		say(&"hit_light")
		_decide("seen his wound: light", "bleeding %.1f ml/s; %.2f less afraid" % [p.total_bleed_rate(), relief])
		if tactic == Tactic.HIDDEN:
			_tactic_time = _think.randf_range(0.3, 0.8)
	_wince_fear = 0.0


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
	_scare(clampf(kpa / 25.0, 0.05, 1.5), &"blast")


## "Drop it!" from someone aiming at him: frightening in proportion to how things are going.
func _on_shouted(speaker: Node, kind: StringName) -> void:
	if kind != &"drop_it" or not speaker is Node3D or mood in [Mood.SURRENDERED, Mood.DOWN, Mood.DEAD]:
		return
	var d := (speaker as Node3D).global_position.distance_to(body.global_position)
	if d > 30.0:
		return
	_drop_it_heard = 0.0
	_scare(0.08 + (0.22 if _aimed_at > 0.3 else 0.0) + body.physiology.wounds * 0.08, &"told to drop it")
	if _facing_shotgun and _aimed_at > 0.3:
		_scare(0.12, &"told to drop it")
	if mood == Mood.CALM:
		_scare(0.1, &"told to drop it")  # caught cold with a gun on him


# --- Living ------------------------------------------------------------------------------------

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
	Prof.stop(&"outlaw_brain", t)


## Far off, may he tick less often (PeopleTick, step 4b)? Only calm, with nobody he's wary of or
## worse, nobody to fight, rescue or break from: a man fighting, fleeing, tending or rescuing ticks
## every tick.
func can_slow() -> bool:
	if mood != Mood.CALM or target != null or rescuing != null or _pending_break != &"" or not _fire_way.is_empty():
		return false
	for who: Variant in relations.entries.keys():  # a copy (Senses: a freed key can loop the walk)
		if relations.entries[who].stance >= Relations.Stance.WARY:
			return false
	return true


## In a fight, running or tending (PeopleTick: whoever's near him ticks every tick too).
func in_trouble() -> bool:
	return mood in [Mood.FIGHTING, Mood.RELOADING, Mood.FLEEING, Mood.TENDING] or target != null or rescuing != null


func _physics_step(delta: float) -> void:
	var p := body.physiology
	if not p.alive:
		_set_mood(Mood.DEAD)
		return
	if body.limp:
		_chair = null  # the chair's gone from under him, or he's down off it (KitProp clears the seat)
		if mood != Mood.SURRENDERED:
			_set_mood(Mood.DOWN)
			_down_but_awake(delta)
		return
	if mood == Mood.DOWN:
		# Back on his feet (HumanBody.get_up: knocked down, not hurt): back to it.
		_set_mood(Mood.FIGHTING if target != null else Mood.CALM)
	if _chair != null and mood != Mood.CALM:
		# Trouble: he's up out of it.
		_get_up_from_chair()
	if body.stumbling > 0.0:
		return  # going down: his last steps are his body's, not his
	_now += delta
	if body.dragged_by != null:
		var helper := Crew.brain_of(body.dragged_by)
		if helper != null and helper.rescuing == body and helper.body.physiology.is_conscious():
			# A friend's got him by the collar: he holds on and lets himself be pulled.
			body.set_pose(&"prone")
			return
		body.dragged_by = null
	_update_aimed_at(delta)
	if variant != Variant.A:
		_step_hand(delta)
	_quiet += delta
	_drop_it_heard += delta
	_startled = maxf(_startled - delta, 0.0)
	suppressed = maxf(suppressed - delta, 0.0)
	_pain_step(delta)
	# Fear settles slowly, but pain, shock and an empty hand keep it up.
	var floor_fear := p.felt_pain() * 0.3 + p.shock() * 0.6 + (0.25 if not _armed_still() else 0.0) \
			+ clampf(p.total_bleed_rate() / 15.0, 0.0, 0.3)  # the sight of his own blood
	var settle := fear_settle_in_cover if variant >= Variant.C and tactic == Tactic.HIDDEN and suppressed <= 0.0 else 0.01
	var was_fear := fear
	fear = maxf(move_toward(fear, floor_fear, settle * delta), floor_fear * 0.9)
	if fear > was_fear:
		fear_from[&"pain, shock, bleeding"] = float(fear_from.get(&"pain, shock, bleeding", 0.0)) + fear - was_fear
	if mood == Mood.SURRENDERED:
		if arrested_by != null:
			_go_along(delta)
		return
	if mood == Mood.FLEEING:
		_flee(delta)
		return
	if mood == Mood.TENDING:
		_tend(delta)
		return
	if not _armed_still() and mood != Mood.CALM:
		_scare(0.3 * delta, &"no gun")
	if _pending_break != &"":
		_pending_in -= delta
		if _pending_in <= 0.0 or dread() > nerve_now():
			var how := _pending_break
			_pending_break = &""
			_decide("give up" if how == &"surrender" else "run", "his friends' word (%s)" % ("give up" if how == &"surrender" else "fall back"))
			if how == &"surrender":
				_surrender()
				return
			if body.physiology.can_run() and not body.prone:
				_start_fleeing()
				return
	if variant == Variant.D:
		fright = move_toward(fright, 0.0, FRIGHT_FADE * delta)
		rattled = move_toward(rattled, 0.0, RATTLED_FADE * delta)
		_watch_leader(delta)
	_hold_break = maxf(_hold_break - delta, 0.0)
	_flinch_spread = move_toward(_flinch_spread, 0.0, FLINCH_FADE * delta)
	_hurry = maxf(_hurry - delta, 0.0)
	if dread() > nerve_now() and _hold_break > 0.0 and dread() <= nerve_now() + shaken_margin * 2.0:
		pass  # (odds) taking stock, fighting it out, or gone to ground to weigh it
	elif dread() > nerve_now() and not (variant >= Variant.C and _shaken_holds(delta)):
		_break()
		return
	if _shaken >= 0.0 and dread() <= nerve_now():
		_shaken = -1.0
		_hid_once = false
		if mood in [Mood.FIGHTING, Mood.RELOADING]:
			say(&"rally")
			_decide("back in it", "his fear's settled (%.2f / %.2f)" % [dread(), nerve_now()])
	if menace != null and _menacing(delta):
		return
	relations.tick(delta)
	_pick_fight(delta)
	match mood:
		Mood.CALM:
			if _mind_fire(delta):
				return
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
	for who in relations.entries.keys():  # a copy: a freed key can loop the walk (Senses)
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
			if _startled > 0.0:
				body.face(_startled_at + Vector3.UP * 1.4)
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
	# On his way out of town he keeps an eye on a man he's wary of, and keeps going.
	var holds := Relations.Stance.WARNING if agenda[0].do == &"leave" else Relations.Stance.WARY
	for who in relations.entries.keys():  # a copy (see above)
		var e: Dictionary = relations.entries[who]
		if is_instance_valid(who) and e.stance >= holds and not e.cowed:
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
			done = _drink(step, delta)
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
		&"post":
			_keep_post(delta)
		&"duel":
			done = _duel(step)
		_:
			done = true
	if done and not agenda.is_empty() and agenda[0] == step:
		_next_step()


func _next_step() -> void:
	agenda.pop_front()
	_step_started = false
	_get_up_from_chair()


## The kit chair he's taken for a drink (Seating), or null.
var _chair: KitProp


func _get_up_from_chair() -> void:
	if _chair != null:
		Seating.stand_up(body, _chair)
		_chair = null


## Starting on a step: work out the way there.
func _begin_step(step: Dictionary) -> void:
	_step_started = true
	_step_time = 0.0
	_route = []
	_stuck = 0.0
	_last_pos = body.global_position
	var space := World.space(body)
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


## At the bar: leaning on it, a word to the barkeep now and then. Or (`sit`) sat back in a kit chair
## near it, at a card table (Seating; Sean, 2026-10-22: men sitting in the chairs in town).
func _drink(step: Dictionary, delta: float) -> bool:
	if step.get("sit", false):
		if _chair == null or not is_instance_valid(_chair) or _chair.loose or (_chair.seated != null and _chair.seated != body):
			_chair = Seating.free_chair_near(body.get_tree(), body.global_position)
		if _chair != null:
			Seating.sit_step(body, _chair, delta)
	else:
		body.set_pose(&"stand")
	if _chair == null and step.has("face"):
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
	if not step.get("begun", false):
		# Something to say soon after he's there (a drink's long quiet doesn't carry over).
		step.begun = true
		_say_again = minf(_say_again, _think.randf_range(0.5, 2.5))
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
		var space := World.space(body)
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
	var side := signf(body.global_position.x - p.x)
	if side == 0.0:
		side = 1.0
	var x := p.x + side * 12.0
	# Main Street between Market Street and Freight Street (config/town.json).
	if x > 16.0 or x < -34.0:
		x = p.x - side * 12.0
	return TownLayout.street_point(clampf(x, -34.0, 16.0), -0.6 + _think.randf_range(-1.0, 1.0))


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
		_start_fight(who, true)
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
		plan.append({"do": &"drink", "seconds": sulk_seconds, "face": places.at(bar_spot) + TownLayout.facing_toward(&"Saloon", Vector3(2.0, 0.0, 0.0)) + Vector3.UP * 1.2})
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


## Fire near him while he's going about his day: a word, out of there by a way clear of it, and
## the day's spoiled: what's left of it is riding out. (In a fight he's got other things on his
## mind.) True while he's on his way out of it.
func _mind_fire(delta: float) -> bool:
	_fire_look -= delta
	if _fire_look <= 0.0:
		_fire_look = 0.5
		var fire := get_tree().get_first_node_in_group(&"fire_system") as FireSystem
		if fire != null and _now - _fire_fled > 4.0:
			var near := fire.fire_near(body.global_position, FIRE_REACH)
			if near.count > 0:
				if _fire_way.is_empty() and _now - _fire_fled > 20.0:
					say(&"fire")
				_fire_fled = _now
				_fire_way = FireFlight.way_out(fire, places, body, FIRE_CLEAR)
				if places:
					agenda = [{"do": &"leave"}]
					_step_started = false
	if _fire_way.is_empty() or not body.physiology.can_stand():
		_fire_way.clear()
		return false
	body.set_pose(&"stand")
	var arrived := body.walk_to(_fire_way[0], FIRE_RUN, delta)
	_watch_stuck(delta)
	if arrived or _stuck > 2.0:
		_fire_way.pop_front()
		_stuck = 0.0
	return true


## Hours went by while you were out cold: whatever fight there was is over. A town man (one with
## a day's plan) who can still walk and hasn't given himself up has had his day and gone; the
## rest stand down where they are.
func _on_hours_passed(_hours: float, _why: StringName) -> void:
	if not body.physiology.alive:
		return
	for who in relations.entries.keys():
		if is_instance_valid(who) and relations.stance(who) == Relations.Stance.FIGHT:
			relations.stand_down(who)
	if mood in [Mood.SURRENDERED, Mood.DOWN, Mood.DEAD]:
		return
	target = null
	tactic = Tactic.OPEN
	fear = 0.0
	_set_mood(Mood.CALM)
	_after_fight()
	if places and hold.is_empty() and body.physiology.can_stand() and not body.limp and not body.prone:
		agenda.clear()
		left_town.emit()
		body.queue_free()


## A fight's over and he's still standing: he's done with this town for today.
func _after_fight() -> void:
	_stand_and_fight = false
	_stop_rescue()
	covering = 0.0
	rage = 0.0
	if not hold.is_empty():
		# Holding a house: back to his post, not out of town.
		agenda = [{"do": &"post"}]
		_step_started = false
	elif places:
		agenda = [{"do": &"leave"}]
		_step_started = false


## His gun on the man he's holding (`menace`): to him, a pace off, gun on his head, the threat
## shouted once; with `menace_fire`, he fires (FarmhouseMission.execute_shots in all). True while he
## does (nothing else this tick); false when he can't (down, stunned, given up, no gun).
func _menacing(delta: float) -> bool:
	if not is_instance_valid(menace) or not menace.physiology.alive:
		menace = null
		return false
	if mood in [Mood.SURRENDERED, Mood.FLEEING, Mood.DOWN, Mood.DEAD, Mood.TENDING] or body.prone or stunned > 0.0 \
			or body.held_gun == null or not body.physiology.can_hold("r"):
		return false
	var head: Vector3 = (menace.parts[&"head"] as Node3D).global_position if menace.parts.has(&"head") else menace.global_position + Vector3.UP * 1.2
	var from := body.global_position - menace.global_position
	from.y = 0.0
	if from.length() > 1.5:
		body.set_pose(&"stand")
		var stand := menace.global_position + (from.normalized() if from.length() > 0.01 else Vector3.BACK) * 1.0
		body.walk_to(stand, run_speed, delta, false)
		body.face(head)
		return true
	body.face(head)
	body.set_pose(&"aim")
	if body.gun_holstered:
		body.draw_gun()
		return true
	if not _menace_said:
		_menace_said = true
		say(&"menace")
	if not menace_fire or not body.gun_ready():
		return true
	if rounds <= 0:
		_start_reload()
		return true
	_next_shot -= delta
	if _next_shot > 0.0:
		return true
	_fire_at(head, menace)
	_menace_shots += 1
	_next_shot = 0.7
	if _menace_shots >= menace_shots:
		menace_fire = false
	return true


## Told to hold a spot (HouseDefence): `o` empty lets him be. The same spot again changes nothing.
func give_order(o: Dictionary) -> void:
	if o.is_empty():
		if not order.is_empty():
			order = {}
			_order_way.clear()
			tactic = Tactic.OPEN
			_cover_search = 0.0
		return
	if order.get("id", "") == o.id:
		order.look = o.look
		return
	order = o
	_order_way.clear()
	_order_stuck = 0.0
	_search = null
	_decide("to %s" % o.id.replace("_", " "), String(o.get("why", "")))


## His spot: there by the house's ways (fighting you where he meets you, if you're close and in
## sight); there, watching what it covers: low behind low cover or below a window's sill while
## rounds come in, up to shoot when he has you (or a friend wants you kept down), topping up his
## gun while it's quiet.
func _follow_order(delta: float, t: Node3D) -> void:
	var at: Vector3 = order.at
	var flat := at - body.global_position
	flat.y = 0.0
	var sees := senses.sees(t)
	if flat.length() > 0.45:
		if sees and body.global_position.distance_to(t.global_position) < 5.0:
			tactic = Tactic.OPEN
			_fight(delta)
			return
		if _order_way.is_empty():
			if places:
				_order_way = places.route_to_point(World.space(body), body.global_position, at, _exclude(t))
			if _order_way.is_empty():
				_order_way = [at]
		tactic = Tactic.MOVING
		body.set_pose(&"stand")
		if body.walk_to(_order_way[0], run_speed, delta):
			_order_way.pop_front()
			if _order_way.is_empty():
				_order_way = [at]
		if body.global_position.distance_to(_last_pos) < 0.02 * 60.0 * delta:
			_order_stuck += delta
		else:
			_order_stuck = maxf(_order_stuck - delta, 0.0)
		_last_pos = body.global_position
		if _order_stuck > 2.5:
			# Can't get there (a body, the wreck of a wall): his own cover instead.
			_decide("give up on %s" % String(order.id).replace("_", " "), "stuck on the way")
			order = {}
			_order_way.clear()
			tactic = Tactic.OPEN
			_cover_search = 0.0
		return
	_order_way.clear()
	tactic = Tactic.HIDDEN
	if sees or (covering > 0.0 and senses.since_known(t) < 20.0):
		_fight(delta)
		return
	body.face(order.look)
	var down: bool = order.get("low", false) or (order.get("window", false) and (suppressed > 0.0 or _shaken >= 0.0))
	body.set_pose(&"crouch" if down else &"stand")
	if rounds < rounds_per_load and mood == Mood.FIGHTING and senses.since_seen(t) > 2.5 and suppressed <= 0.0:
		_start_reload()


## Holding a house: is `p` in it (anywhere, if he holds none; nowhere he knows of, if unknown)?
func _inside(p: Vector3) -> bool:
	if hold.is_empty():
		return true
	if p == Vector3.INF:
		return false
	return (hold.inside as Callable).call(p)


## His post in the house he holds, before it starts and after: there by the house's ways, then
## standing watching what he's set to watch, glancing about now and then (a man bored at a window).
func _keep_post(delta: float) -> void:
	if hold.is_empty():
		return
	var post: Vector3 = hold.post
	if body.global_position.distance_to(post) > 0.6:
		if _post_way.is_empty():
			if places:
				_post_way = places.route_to_point(World.space(body), body.global_position, post, _exclude(null))
			if _post_way.is_empty():
				_post_way = [post]
		body.set_pose(&"stand")
		if body.walk_to(_post_way[0], walk_speed, delta):
			_post_way.pop_front()
			if _post_way.is_empty():
				_post_way = [post]
		return
	_post_way.clear()
	body.set_pose(&"stand")
	_post_glance -= delta
	if _post_glance <= 0.0:
		_post_glance = _think.randf_range(3.0, 8.0)
		var look: Vector3 = hold.look
		if _think.randf() < 0.35:
			# A look round: to one side of what he watches.
			var to := look - post
			look = post + to.rotated(Vector3.UP, deg_to_rad(_think.randf_range(-55.0, 55.0)))
		_post_look = look
	body.face(_post_look if _post_look != Vector3.INF else hold.look)


## A look at something he heard at his post (holding a house): he turns to it for a while.
func glance(at: Vector3, seconds := 3.0) -> void:
	_post_look = at
	_post_glance = seconds


## Into cover against `point` now (a breach in the house he holds: a man to cover the hole).
func cover_against(point: Vector3, why := "the breach") -> void:
	_search = null
	_seek_cover(point + Vector3.UP * 1.0, Vector3.INF, 11.0, 3.0, why)


## Holding a house and lost you outside it: back to his post by the house's ways, to watch for you.
func _to_post(t: Node3D) -> void:
	var post: Vector3 = hold.post
	var way: Array[Vector3] = []
	if places:
		way = places.route_to_point(World.space(body), body.global_position, post, _exclude(t))
	if way.is_empty():
		way = [post]
	cover = {"at": post, "route": way, "low": false, "peek": post, "eye": _eye_of(t)}
	tactic = Tactic.MOVING
	_move_time = 0.0
	_stuck = 0.0
	_last_pos = body.global_position
	_decide("back to his post", "lost you outside the house")


# --- Fighting ----------------------------------------------------------------------------------

func _combat(delta: float) -> void:
	var t := _find_target()
	if t == null:
		return
	if stunned > 0.0:
		# Dazed by a blast: on his feet (or where it threw him), doing nothing till his head clears.
		stunned -= delta
		if not body.prone and not body.limp:
			body.set_pose(&"wince")
		return
	if _react > 0.0:
		# Taking it in: he looks at the man, his hand not yet moving.
		_react -= delta
		body.face(_eye_of(t))
		if _react <= 0.0 and body.gun_holstered:
			body.draw_gun()
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
	if _wince > 0.0 and not body.prone and _wince_step(delta, t):
		return
	if rage > 0.0 and not body.prone and _inside(senses.last_known(t)):
		_rage_fight(delta, t)
		return
	_press = maxf(_press - delta, 0.0)
	if _press > 0.0 and not body.prone and _inside(senses.last_known(t)):
		_press_fight(delta, t)
		return
	if not order.is_empty() and not body.prone:
		_follow_order(delta, t)
		return
	var eye := _eye_of(t)
	# Holding a house and he's lost you outside it: back to his post (a window), to watch for you.
	if not hold.is_empty() and not senses.sees(t) and senses.since_known(t) > 6.0 and tactic == Tactic.OPEN \
			and not body.prone and body.global_position.distance_to(hold.post) > 0.8 and not _inside(senses.last_known(t)):
		_to_post(t)
	# Lost sight of him for a while: go and look where he was (in the house he holds, only inside it).
	if not senses.sees(t) and senses.since_known(t) > 4.0 and tactic in [Tactic.OPEN, Tactic.HIDDEN] and not body.prone \
			and _shaken < 0.0 and _inside(senses.last_known(t)):
		tactic = Tactic.SEARCHING
		_search_time = 0.0
		_look_round = 0.0
		say(&"search")
		_decide("look for you", "lost sight of you %.0f s ago, going to where you were" % senses.since_known(t))
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
				_seek_cover(eye, Vector3.INF, 11.0, 3.0, "in the open")
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
				_decide("behind cover", "got there")
				tactic = Tactic.HIDDEN
				_tactic_time = _think.randf_range(0.6, 1.6)
				_in_cover = 0.0
				_peeks = 0
				_flank_after = _think.randf_range(10.0, 18.0)
			elif _move_time > 7.0 or _stuck > 1.2:
				_decide("give that cover up", "stuck on the way" if _stuck > 1.2 else "too long getting there")
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
		_decide("fight", "sees you again")
		tactic = Tactic.OPEN
		_cover_search = 0.0
		return
	var spot := senses.last_known(t)
	if _has(&"stay_in") and (_search_time > 25.0 or spot == Vector3.INF or senses.since_known(t) > HUNT_GIVE_UP):
		# A friend in earshot still in it with the man, and knowing where he is: his word keeps
		# this one in it too (he takes the man to be where his friend last had him).
		var mate := _mate_on(t)
		if mate != null:
			senses.note(t, mate.senses.last_known(t), 2.0)
			spot = senses.last_known(t)
			_search_time = 0.0
			_decide("keep looking", "%s's still on you" % Crew.name_of(mate.body))
	if _search_time > 25.0 or spot == Vector3.INF or senses.since_known(t) > HUNT_GIVE_UP:
		say(&"lost")
		_decide("stand down", "lost you for good")
		relations.stand_down(t)
		target = null
		_set_mood(Mood.CALM)
		tactic = Tactic.OPEN
		_after_fight()
		return
	var flat := Vector3(spot.x, body.global_position.y, spot.z)
	body.set_pose(&"aim")
	if _has(&"hunt_way") and _town() != null and body.global_position.distance_to(flat) > 1.5:
		# By the town's ways (out of the door and along the walk, round the bar), not into the wall
		# between: the way's worked out again when the spot he's after moves, or every 2 s.
		_hunt_t -= delta
		if _hunt_t <= 0.0 or _hunt_to.distance_to(spot) > 1.0 or _hunt_way.is_empty():
			_hunt_t = 2.0
			_hunt_to = spot
			_hunt_way = _town().route_to_point(World.space(body), body.global_position, spot, _exclude(t))
		if not _hunt_way.is_empty() and body.walk_to(_hunt_way[0], walk_speed * 1.3, delta) and _hunt_way.size() > 1:
			_hunt_way.pop_front()
	elif body.global_position.distance_to(flat) > 1.5:
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
func _seek_cover(eye: Vector3, bias_from: Vector3, max_travel := 11.0, new_angle := 3.0, why := "") -> void:
	if _search != null:
		return
	_search_why = why
	_search = Cover.search(body.get_parent() as Node3D, body.global_position, eye, _exclude(_find_target()), _think, bias_from,
			max_travel, new_angle, _town())
	if _has(&"cover_way"):
		_search._ctx["way_extra"] = Cover.WAY_EXTRA_FAR
	if _has(&"way_cost"):
		_search._ctx["by_way"] = true
	if not hold.is_empty():
		_search._ctx["inside"] = hold.inside
	_search_bias = bias_from
	_search_eye = eye


## A few more candidate spots this tick; when the hunt's done, go if it found somewhere.
func _step_search() -> void:
	if _search == null or not _search.step(40):
		return
	var spot := _search.result
	_search = null
	if spot.is_empty():
		if tactic == Tactic.OPEN:
			_decide("fight from where he is", "no cover he can reach (%s)" % _search_why)
		return
	if _search_bias != Vector3.INF and (spot.at as Vector3).distance_to(_search_bias) < 1.5:
		return
	if tactic == Tactic.PEEKING or tactic == Tactic.RESCUING:
		_flanking = false
		return  # he'll go next time he's down
	var going_round := _flanking
	if _flanking:
		_flanking = false
		if crew.someone_flanking(_now):
			return
		callout(&"flank", _find_target(), spot.at)
	spot.eye = _search_eye
	cover = spot
	_decide("go round on you" if going_round else "run for cover", "%s, %.0f m" % [_search_why, (spot.at as Vector3).distance_to(body.global_position)])
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
	var down_low: bool = cover.low and (suppressed > 0.0 or _shaken >= 0.0 or not cover.get("crouch_ok", false))
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
		var space := World.space(body)
		var h := Cover.LIE_HEAD if cover.get("lie", false) else (Cover.HIDE_HEAD if cover.low else Cover.STAND_HEAD)
		if not Cover.hidden_at(space, cover.at, _held_eye(eye), h, _exclude(_find_target()), _town() != null):
			# He's come round it: this cover's no good now.
			_decide("leave his cover", "you can see him there now")
			tactic = Tactic.OPEN
			_cover_search = 0.0
			return
	if _wants_to_tend():
		_start_tending(Mood.FIGHTING)
		return
	if _shaken >= 0.0:
		return  # head down till it passes
	if _in_cover > _flank_after or _peeks >= 4:
		var stale := "%d peeks from here" % _peeks if _peeks >= 4 else "%.0f s in this cover" % _in_cover
		_in_cover = 0.0
		_peeks = 0
		_flank_after = _think.randf_range(10.0, 18.0)
		if crew.someone_flanking(_now):
			pass  # a friend's going round: he stays and keeps the man busy
		else:
			# With friends there to keep the man's head down, he goes right round on him.
			_flanking = crew.any_in_earshot(_now) and mood == Mood.FIGHTING
			_seek_cover(eye, cover.at, FLANK_TRAVEL if _flanking else 11.0, FLANK_ANGLE if _flanking else 3.0,
					stale + (", friends to keep your head down" if _flanking else ""))
	if covering > 0.0 and suppressed <= 0.0:
		_tactic_time = minf(_tactic_time, 0.25)
	if _tactic_time <= 0.0 and mood == Mood.FIGHTING and body.held_gun != null and body.physiology.can_hold("r"):
		tactic = Tactic.PEEKING
		_peek_time = 0.0
		_peek_shots = 0
		_next_shot = _think.randf_range(0.35, 0.7)
		var space := World.space(body)
		# Over low cover he shoots crouched if he can see over it that low, else he stands.
		_peek_pose = &"crouch_aim" if cover.low and Cover._sees(space, cover.at + Vector3.UP * Cover.CROUCH_GUN, eye, _exclude(_find_target())) else &"aim"


## Where he holds his cover against the man's eyes (variant D's `hold_cover`, #294): where they are
## when he sees him; else the idea of him he chose this spot by, moved only by what he's sure of
## (a ball into him or past him, a friend's word of where he is), not by a guess at a sound (his
## last-known spot moves with every noise he takes for the man's). Without the fix, his guess.
func _held_eye(eye: Vector3) -> Vector3:
	if not _has(&"hold_cover"):
		return eye
	var t := _find_target()
	if t == null or senses.sees(t) or _sure or cover.get("eye", Vector3.INF) == Vector3.INF:
		cover.eye = eye
		_sure = false
	return cover.eye


## Up (or out) and shooting: a shot or two, then back down.
func _peek(delta: float, t: Node3D, eye: Vector3) -> void:
	_peek_time += delta
	if not cover.low and body.global_position.distance_to(cover.peek) > 0.2:
		body.walk_to(cover.peek, walk_speed * 1.6, delta, false)
	var aim_point := _aim_point(t)
	body.face(aim_point)
	_stagger -= delta
	if _pain_locked() or _stagger > 0.0:
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
		if variant != Variant.A and not _sights_on(delta, t):
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
	if _pain_locked():
		body.set_pose(&"clutch")  # doubled over, holding it
		_scare(0.05 * delta, &"pain")
		return
	if _stagger > 0.0:
		body.set_pose(&"stand")
		_next_shot = maxf(_next_shot, 0.3)
		return
	# In the open with the man shooting at him (variant D's `go_low`): down on a knee, a smaller mark.
	var low := _has(&"go_low") and tactic == Tactic.OPEN and not body.prone and _quiet < GO_LOW_QUIET
	body.set_pose(&"crouch_aim" if low else &"aim")
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
	if variant != Variant.A and not _sights_on(delta, t):
		return
	_fire_at(aim_point, t)
	var p := body.physiology
	_next_shot = seconds_between_shots * _rng.randf_range(0.75, 1.3) + p.shock() * 1.5 + p.felt_pain() * 0.5


func _aim_point(t: Node3D) -> Vector3:
	if t != null and t == menace and menace.parts.has(&"head"):
		return (menace.parts[&"head"] as Node3D).global_position  # a man he means to kill, at a pace
	if t is HumanBody and (t as HumanBody).parts.has(&"chest"):
		if senses.sees(t):
			return ((t as HumanBody).parts[&"chest"] as Node3D).global_position
		var lk := senses.last_known(t)
		return (lk if lk != Vector3.INF else t.global_position) + Vector3.UP * 1.25
	var chest := 1.3
	if t is Player and (t as Player).is_crouching:
		chest = 0.75
	var base := t.global_position if senses.sees(t) or senses.last_known(t) == Vector3.INF else senses.last_known(t)
	if t is Player and senses.sees(t) and variant != Variant.A:
		# A man shoots at what he can see: only your head over the trough, he aims at your head.
		var frame := Engine.get_physics_frames()
		if _aim_frame != frame:
			_aim_frame = frame
			var eye := senses.eye()
			var head := (t as Player).camera.global_position + Vector3.DOWN * 0.08
			_aim_head = not _clear(eye, base + Vector3.UP * chest, t) and _clear(eye, head, t)
		if _aim_head:
			return (t as Player).camera.global_position + Vector3.DOWN * 0.08
	return base + Vector3.UP * chest


## Nothing solid between `from` and `to` (the man there aside).
func _clear(from: Vector3, to: Vector3, t: Node3D) -> bool:
	Prof.count(&"q_brain")
	return Sight.clear(body, from, to, _exclude(t))


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
	if gun == null or (crew.ids.is_empty() and not hold.has("spare")):
		return false
	var q := PhysicsRayQueryParameters3D.create(gun.muzzle.global_position, point, Layers.BODY_PARTS)
	q.exclude = _exclude()
	Prof.count(&"q_brain")
	var hit := World.space(body).intersect_ray(q)
	if hit.is_empty():
		return false
	var who: Variant = (hit.collider as Object).get_meta(&"human_body", null)
	# Holding a house with a man in it he means to keep (the hostage, `hold.spare`): not through him.
	return crew.is_mate(who) or (hold.has("spare") and who != null and who in hold.spare)


func _fire_at(point: Vector3, t: Node3D) -> void:
	var gun := body.held_gun as RevolverModel
	var origin := gun.muzzle.global_position
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if ballistics == null:
		return
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	# Along the barrel, where his hand has it: the wander, the lag onto a moving man, the kick of
	# his last shot, a jolt. No dice (GunHand). Variant A: in a cone round his aim.
	var dir := hand.barrel() if variant != Variant.A else _cone_shot(ballistics, origin, point, t)
	var exclude: Array[RID] = []
	for sid: StringName in body.parts:
		exclude.append((body.parts[sid] as CollisionObject3D).get_rid())
	var bullet := ballistics.fire(origin, dir, t_rev.muzzle_velocity, t_rev.bullet_mass, t_rev.bullet_diameter, exclude)
	bullet.form = t_rev.form_factor
	bullet.shooter = body
	rounds -= 1
	if variant != Variant.A:
		hand.fired(t_rev)
		_on_sights = 0.0
		_squeeze = -1.0
		_judge_range()
	var world := ballistics.get_parent()
	GunSmoke.spawn(world, origin, dir)
	ImpactEffects.muzzle_flash(world, origin)
	if GameAudio.enabled():
		GameAudio.gunshot(body, origin)
	else:
		_gun_sound.play()
	Events.shot_fired.emit(origin, dir, body)


## Variant A's shot: held over for the range he judges, then anywhere in a cone that widens with
## pain, shock, fear, a shaky arm, a bad eye, a moving target, the wrong finger and not seeing him.
func _cone_shot(ballistics: Ballistics, origin: Vector3, point: Vector3, t: Node3D) -> Vector3:
	var p := body.physiology
	var spread := spread_degrees + p.felt_pain() * 3.0 + p.shock() * 6.0 + fear * 2.0 \
			+ (1.0 - p.arm_steadiness("r")) * 6.0 + (2.5 if p.blind.has(&"eye_r") else 0.0) \
			+ (1.5 if p.blood_in_eye.has(&"r") else 0.0)
	if t is CharacterBody3D:
		spread += Vector2((t as CharacterBody3D).velocity.x, (t as CharacterBody3D).velocity.z).length() * 0.7
	if body.physiology.trigger_finger("r") != &"index_r":
		spread += 2.0
	if not senses.sees(t):
		spread += 3.0  # at where he was, not at him
	spread += _flinch_spread
	_judge_range()
	return _cone(_held_over(ballistics, origin, point), deg_to_rad(spread))


func _cone(dir: Vector3, radians: float) -> Vector3:
	var side := dir.cross(Vector3.UP)
	if side.length() < 0.01:
		side = dir.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(dir).normalized()
	var r := sqrt(_rng.randf()) * tan(radians)
	var a := _rng.randf() * TAU
	return (dir + side * cos(a) * r + up * sin(a) * r).normalized()


## The town's places for his cover search (B and C), else none (A: cover within a step of him).
func _town() -> Waypoints:
	return places if variant != Variant.A else null


## The range by eye, for the next shot: off by `range_judgement` (a share, one standard deviation).
func _judge_range() -> void:
	_range_err = maxf(1.0 + _range_rng.randfn(0.0, range_judgement), 0.3)


## He knows his gun: aimed from `origin` at `point`, held over for the drop at the range he judges
## it to be (off by `range_judgement`, judged again each shot).
func _held_over(ballistics: Ballistics, origin: Vector3, point: Vector3) -> Vector3:
	var t_rev: RevolverTuning = load("res://config/revolver.tres")
	var judged := origin.distance_to(point) * _range_err
	var base := (point - origin).normalized()
	var axis := base.cross(Vector3.UP)
	if axis.length() < 1e-4:
		return base
	return base.rotated(axis.normalized(), ballistics.holdover(judged, t_rev.muzzle_velocity, t_rev.bullet_mass,
			t_rev.bullet_diameter, t_rev.form_factor))


## Where he wants his barrel: on his man, held over (up in an aim pose with his man in mind), or
## held low before him.
func _want_dir(origin: Vector3, t: Node3D) -> Vector3:
	var ballistics := get_tree().get_first_node_in_group(&"ballistics") as Ballistics
	if t != null and ballistics != null:
		return _held_over(ballistics, origin, _aim_point(t))
	var fwd := -body.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	return fwd.rotated(fwd.cross(Vector3.UP).normalized(), deg_to_rad(-35.0))


## His hand this tick: up on his man in an aim pose, else low; shaken by fear, pain, shock, rounds
## cracking past and a hurt arm.
func _step_hand(delta: float) -> void:
	var gun := body.held_gun as RevolverModel
	if gun == null or gun.muzzle == null:
		return
	var t := _find_target()
	if menace != null and is_instance_valid(menace) and body.pose in AIM_POSES:
		t = menace  # his gun on the man he's holding
	var aimed := t != null and body.gun_ready() and body.pose in AIM_POSES
	var p := body.physiology
	var tune := hand_tuning()
	# Rounds cracking past (variant D's noise) leave his hand rattled long after the fright has
	# gone (`rattled`, fading as slowly as fear does): they spoil his aim, they don't break him.
	var stress := 1.0 + (fear + (rattled if _has(&"noise") else 0.0)) * tune.fear_sway + p.felt_pain() * tune.pain_sway + p.shock() * tune.shock_sway \
			+ (tune.rattled_sway if suppressed > 0.0 else 0.0)
	hand.step(delta, _want_dir(gun.muzzle.global_position, t if aimed else null), aimed, body.pose in LOW_POSES, body.move_speed,
			stress, (1.0 - p.arm_steadiness("r")) * tune.arm_tremor, tune.wrong_eye if p.blind.has(&"eye_r") \
			else (lerpf(1.0, tune.wrong_eye, 0.6) if p.blood_in_eye.has(&"r") else 1.0))


## Holding on his man till his sights settle on him (or he can't hold any longer), then the
## squeeze: true when the shot breaks. A hothead's sooner and less sure, a cool man waits for it;
## fear rushes him; shooting at where a man was, or keeping his head down for a friend, he doesn't
## wait for a sight.
func _sights_on(delta: float, t: Node3D) -> bool:
	var frame := Engine.get_physics_frames()
	if _sights_frame != frame - 1:
		_on_sights = 0.0
		_squeeze = -1.0
	_sights_frame = frame
	var tune := hand_tuning()
	if _squeeze >= 0.0:
		_squeeze -= delta
		return _squeeze < 0.0
	_on_sights += delta
	var origin := (body.held_gun as RevolverModel).muzzle.global_position
	var want := _want_dir(origin, t)
	var half := tune.head_half_width if _aim_head else tune.target_half_width
	var window := rad_to_deg(atan2(half, maxf(origin.distance_to(_aim_point(t)), 0.5)))
	var hot := clampf(temper, 0.0, 1.0)
	var patience := lerpf(tune.patience_cool, tune.patience_hot, hot) * (1.0 + fear)
	var hold := lerpf(tune.hold_cool, tune.hold_hot, hot)
	if covering > 0.0 or not senses.sees(t):
		patience *= 3.0
		hold = minf(hold, 0.4)
	if _hurry > 0.0:
		patience *= 2.0
		hold *= 0.4
	if hand.error_to(want) <= window * patience or _on_sights >= hold:
		_squeeze = tune.trigger_lag
		hand.jerk(tune.squeeze_jerk * (1.0 + hot + fear))
		if body.physiology.trigger_finger("r") != &"index_r":
			hand.jerk(tune.wrong_finger_jerk)  # the wrong finger snatches it
	return false


# --- With his friends ----------------------------------------------------------------------------

## How far he'll go round on a man when friends are keeping him busy (m), and how far he'll go to
## get a friend who's down in the open (m).
const FLANK_TRAVEL := 16.0
## How much a flanker wants a new angle on the man (Cover.search `new_angle`; 3 moving on his own).
const FLANK_ANGLE := 9.0
const RESCUE_REACH := 18.0
## Variant D's `rescue_way`: this long at most (s) getting to him before he gives it up.
const RESCUE_RUN := 8.0
## Variant D's `go_low`: in the open, the man he's fighting has fired within this long (s): he
## fights from a knee.
const GO_LOW_QUIET := 3.0
## Variant D's `press`: with fight in him (under this share of his nerve) and the man he's fighting
## reloading within earshot of the gate (m) or just seen hit (s ago), he comes at him for this long
## (s), shooting, to this near (m); not from further than PRESS_REACH.
const PRESS_DREAD := 0.5
const PRESS_HEARS_RELOAD := 15.0
const PRESS_AFTER_HIT := 2.0
const PRESS_SECONDS := 3.5
const PRESS_NEAR := 4.0
const PRESS_REACH := 16.0
## Whether being seen hit sets a man on too, and whether his friends go with him (or cover him).
const PRESS_ON_HIT := false
const PRESS_TOGETHER := false
## Variant D's `wince` (Sean, 2026-10-23: "If ai shot give them a wince and a temp hide to evaluate
## their wound"): hit and still on his feet, he hunches over it, gets out of the man's sight and
## looks at it for this long (s), times WINCE_GREEN for a green man (nerve 0; 1 for a steady one),
## less WINCE_HOT of it for a hothead (temper 1), WINCE_SEVERE for a bad wound, WINCE_GRAZE for a
## graze. In the open he looks for cover this near (m); with none, he goes down low where he is.
## Seen to be a light one, it frightens him WINCE_RELIEF less than it did when it hit.
const WINCE_TIME := 2.0
const WINCE_GREEN := 1.6
const WINCE_HOT := 0.45
const WINCE_SEVERE := 1.5
const WINCE_GRAZE := 0.5
const WINCE_TRAVEL := 6.0
const WINCE_RELIEF := 0.5
## Variant D's `pain_fight` (Experiment A, 2026-10-23): pain past disabling is no longer a wall he
## can't fight through. It comes in bouts: when it first passes disabling he's taken by it for
## PAIN_BOUT_FIRST s (times PAIN_BOUT_GREEN for a green man, 1 for a steady one), and while it stays
## past, a bout of PAIN_BOUT s comes on at PAIN_BOUT_RATE a second for each disabling's worth he's
## past it. Between bouts he fights hurt (his pain already spoils his aim and slows his shots).
const PAIN_BOUT_FIRST := Vector2(1.0, 2.0)
const PAIN_BOUT_GREEN := 1.6
const PAIN_BOUT := Vector2(0.6, 1.2)
const PAIN_BOUT_RATE := 0.6
## Variant D's `floor_fight` (Experiment A): shot off his feet and still with it, his gun in a hand
## that holds it and his fear under this share of his nerve, he comes to on his belly and fights
## from the floor (HumanBody.come_to_ground) rather than lie there till you come and take him.
const FLOOR_FIGHTS := 1.0
## Variant D's `odds` (spec 1C, 2026-10-24): past his nerve isn't a white flag. A fresh hit gives him
## ODDS_STOCK s (green to steady) before fear can break him, unless he's far past it. "Covered
## close" is a gun on him within ODDS_CAUGHT m (it was 12: everyone, in a saloon). When it does
## break him, he weighs it: covered close or no gun, he gives up; a hothead cornered (covered, or
## can't get away) fights it out for ODDS_CORNERED s; a man who can stand gets away, at a run or
## (hurt past running) backing off at a walk, ODDS_FLEE of the time (the Kid's nerve makes it
## more); one who stays, or is down with his gun and not covered, goes to ground for ODDS_HIDE s
## more before he looks at it again. A leader's surrender takes a man ODDS_FOLLOW past his nerve.
const ODDS_STOCK := Vector2(2.0, 0.8)
const ODDS_CAUGHT := 6.0
const ODDS_CORNERED := 8.0
const ODDS_FLEE := Vector2(0.85, 0.5)
const ODDS_HIDE := 5.0
const ODDS_FOLLOW := 0.6
## Variant D's `flinch` (spec 3A, 2026-10-24): a ball cracking past spoils his shot. The jerk grows
## with how close it came (up to 1 + FLINCH_JERK times, past his ear); his aim is off by up to
## FLINCH_SPREAD degrees more, fading at FLINCH_FADE a second; a ball past him as he squeezes throws
## that shot FLINCH_SQUEEZE more. A hothead or a frightened man (FLINCH_SCARED of his nerve) fires
## through it, hurried, for FLINCH_HURRY s (patience times 2, holding times 0.4); anyone else holds
## his next shot FLINCH_HOLD (s, + per closeness) and aims again.
const FLINCH_JERK := 2.0
const FLINCH_SPREAD := 4.0
const FLINCH_FADE := 4.0
const FLINCH_SQUEEZE := 3.0
const FLINCH_SCARED := 0.6
const FLINCH_HURRY := 1.0
const FLINCH_HOLD := Vector2(0.3, 0.7)
## Seconds since he last saw or heard the man he was fighting before he gives up looking (going
## after a friend in between doesn't start the count again).
const HUNT_GIVE_UP := 30.0
## He only goes for a friend down in the open while the man who put him there is about: seen or
## heard this recently.
const RESCUE_WHILE_KNOWN := 8.0
## Down with his legs gone: he gives himself up to a man he's against who comes this near.
const GIVE_UP_NEAR := 8.0
## ... or this near, seen or not (he hears him come).
const GIVE_UP_HEARD := 4.0
## Walking backwards with a man by the collar (m/s).
const DRAG_SPEED := 1.1
## The least time between two shouts of one kind (s); the rest every time.
const CALL_EVERY := {&"hit": 3.0, &"spotted": 5.0, &"covering": 4.0, &"help": 6.0, &"shaken": 6.0, &"hold": 5.0, &"press": 6.0}
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
	Prof.count(&"q_brain")
	var hit := World.space(body).intersect_ray(q)
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
				_sure = true
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
		&"press":
			# A friend's going at him: so does he, if he's the fight in him (else he covers him).
			_join(about, speaker)
			if PRESS_TOGETHER and _press_why_mate() != "":
				_press = PRESS_SECONDS
				_decide("come at you", "%s's going at you" % Crew.name_of(speaker))
			else:
				_cover_mate(PRESS_SECONDS)
		&"shaken":
			# One of them's gone to ground: the man who leads them calls him back into it.
			if leads and _has(&"leader") and mood in [Mood.FIGHTING, Mood.RELOADING] and _shaken < 0.0:
				callout(&"hold", speaker)
		&"hold":
			if about == body and _shaken >= 0.0:
				fear = maxf(fear - LEADER_HOLD, 0.0)
				fright = 0.0
				_decide("hold on", "%s told him to stay in it" % Crew.name_of(speaker))


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
	var why := _press_why(t)
	if why != "":
		_press = PRESS_SECONDS
		_decide("come at you", why)
		if crew.any_in_earshot(_now):
			callout(&"press", t)
		return
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
			or suppressed > 0.0 or body.held_gun == null or senses.since_known(t) > RESCUE_WHILE_KNOWN:
		return null
	var eye := _eye_of(t)
	var space := World.space(body)
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
		if _has(&"rescue_way") and _town() != null and d < best_d:
			# Only a friend he can get to (down the stair, round the bar), and not too far round.
			var way := _town().route_to_point(space, body.global_position, Vector3(at.x, m.global_position.y, at.z), _exclude(t))
			d = _way_length(way)
			if way.is_empty() or absf((way[-1] as Vector3).y - m.global_position.y) > 0.6:
				continue
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
	_decide("drag %s to cover" % Crew.name_of(m), "he's down in the open")
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
			if _has(&"rescue_way") and _town() != null:
				_route = _town().route_to_point(World.space(body), body.global_position, head, _exclude(t))
			else:
				_route = Cover.route(World.space(body), body.global_position, head, _exclude(t))
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
		elif _stuck > 2.0 or (_has(&"rescue_way") and _rescue_time > RESCUE_RUN):
			_stop_rescue()  # can't get to him (or it's taking too long under the gun)
		return
	# Dragging: walking backwards, facing him, him sliding along behind by the collar.
	var space := World.space(body)
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
	var space := World.space(body)
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
	var weight := 1.6 if Crew.leads(m) else 1.0
	if _has(&"green") and how in [&"quit", &"fled"] and Crew.brain_of(m) != null:
		weight *= clampf(Crew.brain_of(m).nerve, 0.25, 1.0)  # the Kid running surprises nobody
	_scare(float(FEAR_MATE_OUT.get(how, 0.1)) * weight, StringName("a friend " + String(how)))
	if how in [&"down", &"dead"] and m.has_meta(&"last_hit_by"):
		_join(m.get_meta(&"last_hit_by"), m)  # whoever shot him down
	var fighting := mood in [Mood.FIGHTING, Mood.RELOADING]
	if saw and how != &"fled" and crew.any_in_earshot(_now):
		callout(how, m, (m as Node3D).global_position)
	if how in [&"down", &"dead"] and temper >= 0.7 and fighting and dread() <= nerve_now():
		rage = 8.0
		fear = maxf(fear - 0.2, 0.0)
		say(&"rage")
		_decide("go for you", "%s %s (a hothead's rage)" % [Crew.name_of(m), how])
	elif how == &"quit" and proud and fighting:
		say(&"scorn", Crew.name_of(m))
	if not crew.thinned and crew.out_share() >= 0.5:
		crew.thinned = true
		_scare(0.15, &"half of them out")


## Pressing on a friend's word: the same as pressing on his own, but the reason's his friend's.
func _press_why_mate() -> String:
	var t := _find_target()
	if t == null or not _has(&"press") or rage > 0.0 or _press > 0.0 or _shaken >= 0.0 or body.prone or rounds < 2 \
			or mood != Mood.FIGHTING or tactic == Tactic.RESCUING or not _armed_still() or dread() > nerve_now() * PRESS_DREAD:
		return ""
	return "a friend's going at you" if t.global_position.distance_to(body.global_position) < PRESS_REACH else ""


## Variant D's `press`: why he'd come at the man now ("" if not): he's reloading and near enough
## to hear it, or just seen hit; and this one's got the fight in him and rounds to do it with.
func _press_why(t: Node3D) -> String:
	if not _has(&"press") or rage > 0.0 or _press > 0.0 or _shaken >= 0.0 or body.prone or rounds < 2 \
			or mood != Mood.FIGHTING or tactic == Tactic.RESCUING or tactic == Tactic.SEARCHING or not _armed_still() \
			or dread() > nerve_now() * PRESS_DREAD or not senses.knows(t) or senses.since_known(t) > 3.0:
		return ""
	var d := t.global_position.distance_to(body.global_position)
	if d > PRESS_REACH or d < PRESS_NEAR + 1.0:
		return ""
	if crew.since(&"press", _now) < PRESS_SECONDS + 1.0:
		return ""  # one goes at him at a time; the rest keep his head down
	if t is Player and _reloading(t as Player) and d < PRESS_HEARS_RELOAD:
		return "you're reloading"
	if PRESS_ON_HIT and _now - _you_hit_at < PRESS_AFTER_HIT:
		return "you're hit"
	return ""


static func _reloading(p: Player) -> bool:
	var w := p.weapon
	if w is RevolverViewmodel:
		return (w as RevolverViewmodel).state.gate_open
	if w is ShotgunViewmodel:
		return (w as ShotgunViewmodel).state.open
	return false


## Coming at him: out from behind his cover, walking at him, shooting, to a few metres off.
func _press_fight(delta: float, t: Node3D) -> void:
	if tactic != Tactic.OPEN:
		tactic = Tactic.OPEN
		_search = null
		cover = {}
	if mood == Mood.RELOADING:
		_press = 0.0
		return
	var to := t.global_position - body.global_position
	to.y = 0.0
	if to.length() > PRESS_NEAR and _town() != null:
		if _hunt_way.is_empty() or _hunt_t <= 0.0:
			_hunt_t = 1.0
			_hunt_way = _town().route_to_point(World.space(body), body.global_position, t.global_position, _exclude(t))
		_hunt_t -= delta
		if not _hunt_way.is_empty() and body.walk_to(_hunt_way[0], walk_speed * 1.4, delta, false) and _hunt_way.size() > 1:
			_hunt_way.pop_front()
	_fight(delta)
	if _press <= delta:
		_cover_search = 0.0  # done: cover from here


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
	var share := 0.3 if Crew.leads(mate) else 0.6
	if _has(&"green") and not Crew.leads(mate) and Crew.brain_of(mate) != null and Crew.brain_of(mate).nerve < nerve:
		share = 0.9  # a greener man's "fall back!" takes a man near breaking anyway
	if dread() > nerve_now() * share and body.physiology.can_run():
		_pending_break = &"flee"
		_pending_in = _think.randf_range(0.3, 1.0)


## The man who leads them has thrown his gun down: unless he's still got his nerve, so does he.
func _heard_give_up(mate: Node) -> void:
	_mate_out(mate, &"quit", false)
	if not mood in [Mood.FIGHTING, Mood.RELOADING, Mood.TENDING] or _pending_break != &"":
		return
	if dread() > nerve_now() * (ODDS_FOLLOW if _has(&"odds") else 0.3):
		_pending_break = &"surrender"
		_pending_in = _think.randf_range(0.6, 1.6)


# --- Breaking, running, tending --------------------------------------------------------------------

## Past his nerve, behind cover or on his way to it (or looking for new cover, his own come round
## on) with his gun in his hand, he goes to ground (head down, not shooting, not going looking for
## you) rather than quit on the spot, and gets his breath back there if he's let be. He breaks if
## it hasn't passed in a few seconds, or once he's well past his nerve; in the open, down, or with
## no gun, at once.
func _shaken_holds(delta: float) -> bool:
	var behind := tactic in [Tactic.HIDDEN, Tactic.PEEKING, Tactic.MOVING] \
			or (tactic == Tactic.OPEN and (_search != null or _cover_search <= 0.0) and not _stand_and_fight)
	if not mood in [Mood.FIGHTING, Mood.RELOADING] or body.prone or body.held_gun == null or cover.is_empty() \
			or not behind or dread() > nerve_now() + shaken_margin:
		return false
	if _shaken < 0.0:
		_shaken = 0.0
		say(&"shaken")
		_decide("go to ground", "past his nerve (fear %.2f / %.2f), behind cover" % [dread(), nerve_now()])
		if _has(&"leader") and crew.any_in_earshot(_now):
			callout(&"shaken", _find_target())
	_shaken += delta
	_flanking = false
	if tactic == Tactic.PEEKING:
		_duck_back()
	return _shaken < shaken_seconds


## Something frightening, and what (`fear_from`: the gunfight lab's ledger of a fight's fear).
## Variant D: noise is fright (fades; a hothead takes little of it), the rest fear.
func _scare(amount: float, why: StringName) -> void:
	if _has(&"noise") and why in NOISE:
		amount *= 1.0 - 0.7 * clampf(temper, 0.0, 1.0)
		fright += amount
		rattled += amount
		why = StringName(String(why) + " (fright)")
	else:
		fear += amount
	fear_from[why] = float(fear_from.get(why, 0.0)) + amount


const NOISE := [&"near miss", &"a shot nearby", &"hat shot"]


## He's a gun he can use: in his hand, and (variant D's `steady`, where a ball alone no longer
## breaks a man whose gun arm it's broken) a hand that can hold it.
func _armed_still() -> bool:
	return body.held_gun != null and (not _has(&"steady") or body.physiology.can_hold("r"))


## Pain he can't do anything but hold the wound through: past disabling (as it was), or with variant
## D's `pain_fight` only in a bout of it.
func _pain_locked() -> bool:
	if _has(&"pain_fight"):
		return _pain_bout > 0.0
	return body.physiology.felt_pain() > body.physiology.tuning.pain_disabling


func _pain_step(delta: float) -> void:
	_pain_bout = maxf(_pain_bout - delta, 0.0)
	if not _has(&"pain_fight"):
		return
	var p := body.physiology
	var over := p.felt_pain() - p.tuning.pain_disabling
	if over > 0.0 and not _pain_over:
		_pain_bout = maxf(_pain_bout, _rng.randf_range(PAIN_BOUT_FIRST.x, PAIN_BOUT_FIRST.y) * lerpf(PAIN_BOUT_GREEN, 1.0, clampf(nerve, 0.0, 1.0)))
	elif over > 0.0 and _pain_bout <= 0.0 and _rng.randf() < PAIN_BOUT_RATE * over / p.tuning.pain_disabling * delta:
		_pain_bout = _rng.randf_range(PAIN_BOUT.x, PAIN_BOUT.y)
	_pain_over = over > 0.0


## How much the shock of being hit frightens him (variant D's `steady`): a steady man takes the
## thump of a ball far better than a green one (what the wound does to him, the pain, the shock,
## the bleeding, counts in full either way: `floor_fear`).
func _thump() -> float:
	return lerpf(1.0, STEADY_THUMP, clampf(nerve, 0.0, 1.0)) if _has(&"steady") else 1.0


const STEADY_THUMP := 0.45
## Variant D's `floored`: knocked down with his gun in his hand, he gives himself up to a man near
## him only once he's this much of the way to breaking; short of it he gets back up.
const FLOORED_HOLDS := 0.6


## A friend within earshot still fighting that man and knowing (within a few seconds) where he is.
func _mate_on(t: Node3D) -> OutlawBrain:
	for m in crew.standing(_now):
		var b := Crew.brain_of(m)
		if b != null and b.mood in [Mood.FIGHTING, Mood.RELOADING] and b._find_target() == t \
				and b.senses.knows(t) and b.senses.since_known(t) < 3.0 and _hears(m):
			return b
	return null


## How far it is along a way of points from where he stands (m, on the flat).
func _way_length(way: Array) -> float:
	var length := 0.0
	var at := body.global_position
	for w: Vector3 in way:
		length += Vector2(w.x - at.x, w.z - at.z).length()
		at = w
	return length


## One of variant D's fixes is on for him.
func _has(fix: StringName) -> bool:
	return variant == Variant.D and fix in d_fixes


## How frightened he is, as far as breaking goes: his fear, and his fright up to a share of his nerve.
func dread() -> float:
	return fear + (minf(fright, FRIGHT_SHARE * nerve) if variant == Variant.D else 0.0)


## How much he can take now: his nerve, and in D more while he's a hothead early in it, or the man
## who leads them is in it beside him.
func nerve_now() -> float:
	var n := nerve
	if variant != Variant.D or _fight_from < 0.0:
		return n
	if _has(&"hothead") and temper >= HOT_TEMPER and _now - _fight_from < HOT_EARLY:
		n += HOT_NERVE * temper
	if _has(&"leader") and not leads and _leader_near:
		n += LEADER_NERVE * clampf(nerve, 0.0, 1.0)  # he steadies a steady man; a green one hardly
	return n


## Is the man who leads them up, in it and in earshot (looked at twice a second)?
func _watch_leader(delta: float) -> void:
	_leader_t -= delta
	if _leader_t > 0.0:
		return
	_leader_t = 0.5
	_leader_near = false
	for m in crew.standing(_now):
		var b := Crew.brain_of(m)
		if b != null and b.leads and b.mood in [Mood.FIGHTING, Mood.RELOADING] and _hears(m):
			_leader_near = true


## What he's decided and why (F3, the gunfight lab's log).
func _decide(what: String, why: String) -> void:
	var line := what + (": " + why if why != "" else "")
	if line != decision:
		decision = line
		decision_at = _now


## Nerve's gone: run for it if he can, else give up.
func _break() -> void:
	var shaken_for := _shaken
	_shaken = -1.0
	var t: Node3D = _find_target()
	if t == null:
		t = relations.focus() as Node3D
	if t == null:
		t = _player()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	var caught := _aimed_at > 0.8 and d < (ODDS_CAUGHT if _has(&"odds") else 12.0)
	if mood == Mood.CALM and t != null and relations.stance(t) >= Relations.Stance.WARY \
			and not (caught and _drop_it_heard < 4.0):
		# Not a fight yet: he backs down (told to drop it with a gun on him, he gives up instead).
		_back_down(t)
		return
	var why := ("past his nerve (fear %.2f / %.2f)" % [dread(), nerve_now()]) if shaken_for < 0.0 \
			else ("still shaken after %.0f s" % shaken_for if dread() <= nerve_now() + shaken_margin else "far past his nerve (fear %.2f / %.2f)" % [dread(), nerve_now()])
	if _has(&"odds") and _break_odds(t, d, caught, why):
		return
	if body.physiology.can_run() and not body.prone and d > 5.0 and not caught and _think.randf() < flee_chance:
		_decide("run", why)
		_start_fleeing()
	else:
		_decide("give up", why + (", covered close" if caught else ", can't run" if not body.physiology.can_run() or body.prone else ""))
		_surrender()


## Variant D's odds: what a man past his nerve does, weighed (true if he's done something other than
## give up; false: he gives up, as before). See ODDS_*.
func _break_odds(t: Node3D, d: float, caught: bool, why: String) -> bool:
	var p := body.physiology
	var armed := _armed_still()
	var can_go := p.can_stand() and not body.prone
	if not armed or (caught and not (temper >= HOT_TEMPER)):
		return false
	if temper >= HOT_TEMPER and (caught or not can_go):
		rage = ODDS_CORNERED
		_hold_break = ODDS_CORNERED
		say(&"cornered")
		_decide("fight it out", why + (", covered close" if caught else ", can't get away"))
		return true
	var far_past := dread() > nerve_now() + shaken_margin
	if can_go and (far_past or _hid_once or _think.randf() < lerpf(ODDS_FLEE.x, ODDS_FLEE.y, clampf(nerve, 0.0, 1.0))):
		_decide("get away" if p.can_run() else "back off", why + ("" if p.can_run() else ", hurt past running"))
		if not p.can_run():
			say(&"back_off")
		_start_fleeing()
		return true
	if not _hid_once and not far_past:
		# He stays: down where he is (behind what he's got, or on the floor), weighing it.
		_hid_once = true
		_hold_break = ODDS_HIDE
		_shaken = 0.0
		say(&"shaken")
		_decide("lie low", why + ", weighing it")
		if tactic == Tactic.PEEKING:
			_duck_back()
		return true
	return false


func _start_fleeing() -> void:
	_stop_rescue()
	if crew.any_in_earshot(_now) and crew.since(&"fall_back", _now) > 3.0 and crew.may_say(&"fall_back", _now, 30.0):
		callout(&"fall_back", _find_target())
	elif _now - _fled_said > 6.0:
		_fled_said = _now
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
	var space := World.space(body)
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
	var walking := _has(&"odds") and not body.physiology.can_run() and body.physiology.can_stand() and not body.prone
	if not body.physiology.can_run() and not walking:
		# Can't run any more: done.
		_surrender()
		return
	body.set_pose(&"stand")
	var arrived := body.walk_to(_flee_to, walk_speed if walking else run_speed * 1.1, delta)
	_watch_stuck(delta)
	if _stuck > 0.8:
		_pick_flight()
	var d := t.global_position.distance_to(body.global_position) if t else 99.0
	# Far enough: get his breath back, see to his wounds. (Not on the tick he set off: a man who
	# stopped to tend, was shot at and ran again went back and forth between the two every tick,
	# saying so each time, #520's farmhouse.)
	if _flee_time > 1.5 and (arrived or d > 38.0 or _flee_time > 14.0):
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
	_decide("tend his wound", "bleeding %.1f ml/s, %.0f s since your last shot" % [body.physiology.total_bleed_rate(), minf(_quiet, 99.0)])
	_after_tend = after
	_set_mood(Mood.TENDING)
	_tend_time = 0.0
	_tend_bleed = _worst_bleed()
	if not _tend_bleed.is_empty() and _now - _tend_said > 6.0:
		_tend_said = _now
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
			if _after_tend == Mood.FIGHTING and dread() <= nerve_now():
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


## Down with his legs gone but awake: when a man he's against comes near with him lying there, he
## gives himself up (and can be arrested) rather than lie there for ever.
func _down_but_awake(delta: float) -> void:
	_give_up_look -= delta
	if _give_up_look > 0.0 or not body.physiology.is_conscious():
		return
	_give_up_look = 0.5
	if _has(&"floor_fight") and not body.rise_ok and dread() < nerve_now() * FLOOR_FIGHTS and body.held_gun != null \
			and body.physiology.can_hold("r") and body.come_to_ground():
		_decide("fight from the floor", "shot down, not beat (fear %.2f / %.2f)" % [dread(), nerve_now()])
		return
	if _has(&"floored") and dread() < nerve_now() * FLOORED_HOLDS and body.held_gun != null and body.physiology.can_hold("r"):
		_decide("get back up", "knocked down, not beat (fear %.2f / %.2f)" % [dread(), nerve_now()])
		return  # knocked off his feet, not beaten: he's getting up (or fighting from the floor)
	for who in relations.entries.keys():  # a copy (see _pick_fight)
		if not is_instance_valid(who) or not who is Node3D or relations.stance(who) < Relations.Stance.WARY:
			continue
		# Lying there he may be looking at the sky: a man walking up to him he hears.
		var d := (who as Node3D).global_position.distance_to(body.global_position)
		if d < GIVE_UP_HEARD or (senses.sees(who) and d < GIVE_UP_NEAR):
			_surrender()
			return


## He's given himself up and that man's binding his hands: from now on he goes where he's taken
## (or waits where he's told). A second word from the same man says which. False if he hasn't
## given up (or can't hear it).
func arrest(by: Node3D) -> bool:
	if mood != Mood.SURRENDERED or not body.physiology.is_conscious():
		return false
	if arrested_by == by:
		follow = not follow
		return true
	arrested_by = by
	follow = true
	target = null
	say(&"arrested")
	if not body.limp:
		body.set_pose(&"hands_bound")
	Events.person_arrested.emit(body, by)
	return true


## Arrested: hands behind him; he keeps a few steps behind the man who took him, at a walk.
func _go_along(delta: float) -> void:
	if not is_instance_valid(arrested_by):
		arrested_by = null
		return
	if body.prone or not body.physiology.can_stand():
		return
	body.set_pose(&"hands_bound")
	var by := arrested_by.global_position
	var flat := Vector3(by.x, body.global_position.y, by.z)
	var d := flat.distance_to(body.global_position)
	if follow and d > 2.6:
		body.walk_to(flat + (body.global_position - flat).normalized() * 1.8, walk_speed, delta)
	else:
		body.face(by + Vector3.UP * 1.4)


func describe() -> String:
	var how: String = String(Mood.keys()[mood]).to_lower()
	if mood == Mood.FIGHTING or mood == Mood.RELOADING:
		how += " (%s%s%s%s%s)" % [String(Tactic.keys()[tactic]).to_lower(), ", pinned down" if suppressed > 0.0 else "",
				", shaken" if _shaken >= 0.0 else "",
				", covering" if covering > 0.0 else "", ", in a rage" if rage > 0.0 else ""]
	elif mood == Mood.CALM and relations:
		var who := relations.focus()
		if who:
			how += " (%s of %s)" % [String(Relations.Stance.keys()[relations.stance(who)]).to_lower(),
					"you" if who is Player else String((who as HumanBody).person_id) if who is HumanBody else str(who.name)]
	return "%s: %s, fear %.2f / nerve %.2f, %d rounds%s. %s" % [String(body.person_id).capitalize(),
			how, fear, nerve, rounds, (". %s (%.0f s ago)" % [decision, _now - decision_at]) if decision != "" else "",
			body.physiology.describe()]
