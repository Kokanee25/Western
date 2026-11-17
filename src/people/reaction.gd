class_name Reaction
extends RefCounted
## A townsman's reaction to trouble, in four stages (townsfolk step 5, #982; docs/briefs/townsfolk.md
## §4 "Reactions that read as real"): one small state machine, the same for every stimulus (a shot
## heard or seen, a blast, a gun drawn near him, a man down), owned by his CivilianBrain.
##
## 1. **Start**: once the thing reaches him (a sound's travel, GameAudio.SPEED_OF_SOUND) and a beat
##    more by his nerve and how far off it was: hands stop, he goes wary, his eyes go to it. Each
##    man's start has a physics frame of its own (`_claim`), so a street reacts as a wave out from
##    the shot, never all on one frame.
## 2. **Look** (0.5-2 s): he turns to where he *thinks* it was (Senses' guess, wrong through walls)
##    and reads it: is the shooter in sight now, is there a man down?
## 3. **Decide**, by his dials (ValleyFolk.dials_of: nerve, nosy, duty) against the fear of it:
##    flee (to a door on his ways: `CivilianBrain.refuges`), hide (cower where he is), gawk (to a
##    ring at a distance, the gawk ring round a man down), watch (where he stands), help (to the man
##    down, down beside him), back away (a gun drawn), or carry on (work stops for a breath).
## 4. **Come back**: once nothing new has reached him for a calm time (20-90 s, longer with low
##    nerve) he stands, looks round, and goes back to his spot, where its chore takes him again
##    (SpotChore). He stays **shaken** an hour of the clock: he starts sooner at the next one and
##    it frightens him more.
##
## He acts only on what he sensed: the brain hands in Senses' `heard` (the guess, the maker only if
## seen) and what he saw done, never a noise's true place.

enum Stage { NONE, START, LOOK, ACT, BACK }

## The stimuli: how frightening up close (`fear`), falling to 15% of that at `reach` m and beyond.
const STIMULI := {
	&"shot": {"fear": 1.0, "reach": 40.0},  # heard, the shooter unseen
	&"shot_seen": {"fear": 1.3, "reach": 60.0},  # the shooter seen as he fired
	&"at_me": {"fear": 2.0, "reach": 1000.0},  # a shot at him, a ball past his ear
	&"blast": {"fear": 1.5, "reach": 90.0},
	&"gun": {"fear": 0.7, "reach": 9.0},  # a gun drawn near him, not fired (CivilianBrain.GUN_SEEN)
	&"down": {"fear": 0.6, "reach": 20.0},  # a man fallen in his sight
}
## Start: this long after it reached him (s): 0.15 for the jumpiest, +0.15 by nerve, +0.2 by how
## far off it was (full at `START_FAR` m). Shaken, the nerve part is shorter.
const START_SOONEST := 0.15
const START_NERVE := 0.15
const START_DISTANCE := 0.2
const START_FAR := 60.0
const SHAKEN_START := 0.5
## Look: this long (s), shorter when it's frightening.
const LOOK_FOR := Vector2(0.5, 2.0)
## The calm time before he comes back (s): `CALM_HIDE` + `CALM_HIDE_NERVE` x (1 - nerve) after a
## fright, `CALM_WATCH` + `CALM_WATCH_NOSY` x nosy after watching.
const CALM_HIDE := 20.0
const CALM_HIDE_NERVE := 70.0
const CALM_WATCH := 20.0
const CALM_WATCH_NOSY := 40.0
## A gun drawn and put away (or out of his sight): this long and it's over.
const CALM_GUN := 6.0
## Carrying on: work stops for this breath (s).
const BREATH := Vector2(1.5, 3.0)
## Coming back: the look round first (s).
const LOOK_ROUND := Vector2(2.0, 3.5)
## Shaken this long, in hours of the town's clock (or `SHAKEN_SECONDS` with no clock).
const SHAKEN_HOURS := 1.0
const SHAKEN_SECONDS := 112.5
const SHAKEN_FEAR := 0.15
## Where they stand to watch: from a shot, at least this far (m); the gawk ring round a man down.
const WATCH_SHOT := 15.0
const GAWK_RING := Vector2(5.0, 8.0)
## A sound unseen: the nosy and the dutiful walk at most this far toward it (to a door, a corner).
const TOWARD_AT_MOST := 14.0
## A blast: the nosy come only after this long (s).
const BLAST_NOSY_AFTER := 60.0
## Fleeing: to a refuge no further than this (m); backing away from a drawn gun: this far.
const REFUGE_REACH := 45.0
const BACK_AWAY := 5.0
const RUN := 3.4
const WALK := 1.2
const HURRY := 2.6
## Sent somewhere this lately (s, CivilianBrain.go_to: an act's errand, his day's next spot) and not
## there yet: he may hide or run, but doesn't walk off to look or help.
const ERRAND := 60.0
## Help: only if no shot's been heard this long (s): the shooter has gone.
const SHOOTER_GONE := 3.0

var brain: CivilianBrain
var body: HumanBody
var stage := Stage.NONE
## What he's reacting to (a STIMULI key), where he thinks it was, and who (only if he saw him).
var kind := &""
var at := Vector3.INF
var who: Node3D
## How far it was when it reached him (m), and its fear for him.
var distance := 0.0
var fear := 0.0
## What he decided (&"flee", &"hide", &"gawk", &"watch", &"help", &"back_away", &"carry_on").
var choice := &""
## The frames: when it reached him (heard) and when his start came (for the reactions row).
var sensed_frame := -1
var start_frame := -1
## Seconds since anything new reached him.
var quiet := 0.0
## A man down he saw (for the gawk ring and help), and when (his senses' clock).
var down: Node3D
## The town's clock hour he came back at (shaken for SHAKEN_HOURS after), or -1.
var shaken_since := -1.0
var _shaken_s := 0.0

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _look_for := 0.0
var _calm_need := 0.0
var _target := Vector3.INF
var _route: Array[Vector3] = []
var _speed := WALK
var _stuck := 0.0
var _last := Vector3.INF
var _arrived := false
var _wait := 0.0
var _said := false
var _day: Node

## Every man's start frame claimed (frame -> true), so no two start on the same one.
static var _claimed := {}
static var _claimed_low := 0


func _init(b: CivilianBrain) -> void:
	brain = b
	body = b.body
	_rng.seed = (body.rng_seed if body else 0) * 31 + 7


func active() -> bool:
	return stage != Stage.NONE


func moving() -> bool:
	return stage == Stage.ACT and not _arrived and _target != Vector3.INF


func shaken() -> bool:
	if shaken_since < 0.0:
		return false
	var day := _clock()
	if day != null:
		var h := fposmod(float(day.get(&"time_of_day")) - shaken_since, 24.0)
		if h < SHAKEN_HOURS:
			return true
	elif _shaken_s > 0.0:
		return true
	shaken_since = -1.0
	return false


## Something reached him: `k` (a STIMULI key) at `where` (his guess), by `by` (only if he saw him).
func sense(k: StringName, where: Vector3, by: Node3D = null) -> void:
	if not STIMULI.has(k) or where == Vector3.INF or not body.physiology.is_conscious():
		return
	var d := body.global_position.distance_to(where)
	var f := _fear_of(k, d)
	if k == &"down" and by != null:
		down = by
	if stage != Stage.NONE:
		quiet = 0.0
		if f <= fear and not (k == &"shot_seen" and kind == &"shot"):
			return  # no worse than what he's at: it keeps him at it longer
		var was_scared := fear > _nerve()
		kind = k
		at = where
		who = by if by != null else who
		distance = d
		fear = f
		if stage == Stage.ACT and not was_scared and fear > _nerve():
			# Worse than he took it for: he looks again, quickly, and decides again.
			_enter(Stage.LOOK)
			_look_for = LOOK_FOR.x
		return
	kind = k
	at = where
	who = by
	distance = d
	fear = f
	choice = &""
	quiet = 0.0
	_said = false
	sensed_frame = Engine.get_physics_frames()
	# It reaches him after the sound's travel (heard: the guess is near enough the truth; seen, the
	# same, light being quicker but the start no slower), then his own start.
	var after := d / GameAudio.SPEED_OF_SOUND + start_after(_nerve(), d, shaken())
	start_frame = _claim(sensed_frame + maxi(1, ceili(after * Engine.physics_ticks_per_second)))
	stage = Stage.START
	_t = 0.0
	brain.mood = CivilianBrain.Mood.ALARMED
	body.wake()


## His start's delay after it reached him (s): by nerve, by distance, sooner shaken.
static func start_after(nerve: float, d: float, is_shaken := false) -> float:
	var n := START_NERVE * clampf(nerve, 0.0, 1.0) * (SHAKEN_START if is_shaken else 1.0)
	return START_SOONEST + n + START_DISTANCE * clampf(d / START_FAR, 0.0, 1.0)


## The first free frame from `frame` on.
static func _claim(frame: int) -> int:
	var now := Engine.get_physics_frames()
	if now - _claimed_low > 600:
		for f: int in _claimed.keys():
			if f < now:
				_claimed.erase(f)
		_claimed_low = now
	while _claimed.has(frame):
		frame += 1
	_claimed[frame] = true
	return frame


func _fear_of(k: StringName, d: float) -> float:
	var s: Dictionary = STIMULI[k]
	var fall := 0.15 + 0.85 * clampf(1.0 - d / float(s.reach), 0.0, 1.0)
	return float(s.fear) * fall + (SHAKEN_FEAR if shaken() else 0.0)


func _nerve() -> float:
	return float(brain.dials.get("nerve", 0.5))


func _nosy() -> float:
	return float(brain.dials.get("nosy", 0.5))


func _duty() -> float:
	return float(brain.dials.get("duty", 0.5))


## Over in a moment (hours went by; he's been sent elsewhere): no come-back walk, shaken if it got
## that far.
func drop(keep_shaken := true) -> void:
	if stage == Stage.NONE:
		return
	if keep_shaken and stage in [Stage.ACT, Stage.BACK]:
		_mark_shaken()
	stage = Stage.NONE
	_route.clear()
	_target = Vector3.INF
	if brain.mood in [CivilianBrain.Mood.ALARMED, CivilianBrain.Mood.WATCHING, CivilianBrain.Mood.RUNNING, CivilianBrain.Mood.COWERING]:
		brain.mood = CivilianBrain.Mood.SHAKEN


func forget() -> void:
	drop(false)
	shaken_since = -1.0
	_shaken_s = 0.0


## His tick: true while the reaction has him (his chore stopped, his feet and pose its).
func step(delta: float) -> bool:
	if _shaken_s > 0.0:
		_shaken_s -= delta
	if stage == Stage.NONE:
		return false
	_t += delta
	quiet += delta
	match stage:
		Stage.START:
			if Engine.get_physics_frames() < start_frame:
				return true  # it hasn't reached him (or he hasn't taken it in): as he was, but held
			if _t < 0.0:
				return true
			_enter(Stage.LOOK)
			_look_for = lerpf(LOOK_FOR.x, LOOK_FOR.y, _rng.randf()) * (0.5 if fear > 1.0 else 1.0)
			body.set_pose(&"wary")
			_attend(at)
		Stage.LOOK:
			body.set_pose(&"wary")
			body.face(_look_point())
			_attend(_look_point())
			if _t >= _look_for:
				_read()
				_decide()
				_enter(Stage.ACT)
		Stage.ACT:
			_act(delta)
			if quiet >= _calm_need and choice == &"carry_on":
				_end()  # a breath, and back to it
				brain.mood = CivilianBrain.Mood.CALM
				return false
			if quiet >= _calm_need:
				_enter(Stage.BACK)
				_wait = lerpf(LOOK_ROUND.x, LOOK_ROUND.y, _rng.randf())
		Stage.BACK:
			brain.mood = CivilianBrain.Mood.SHAKEN
			body.set_pose(&"stand")
			# A look round first: toward it, then away.
			var p := _look_point()
			var y := deg_to_rad(50.0 * sin(_t * 1.7))
			body.face(body.global_position + (p - body.global_position).rotated(Vector3.UP, y))
			if _t >= _wait:
				if choice in [&"hide", &"flee"]:
					brain.say_relief()
				_end()
				return false
	return true


func _end() -> void:
	_mark_shaken()
	if choice in [&"flee", &"gawk", &"help", &"back_away"] and brain.post != Vector3.INF \
			and body.global_position.distance_to(brain.post) > 0.5:
		brain.returning = true
	stage = Stage.NONE
	_route.clear()
	_target = Vector3.INF


func _enter(s: Stage) -> void:
	stage = s
	_t = 0.0


func _look_point() -> Vector3:
	if who != null and is_instance_valid(who) and brain.senses != null and brain.senses.sees(who):
		return who.global_position + Vector3.UP * 1.3
	return at + Vector3.UP * 0.5 if at.y < body.global_position.y + 0.5 else at


func _attend(p: Vector3) -> void:
	var life := body.get_node_or_null(^"FaceLife") as FaceLife
	if life:
		life.attend_to(p)


## The look: what can he make out now? The shooter in sight; a man down he saw.
func _read() -> void:
	if brain.senses == null:
		return
	if kind == &"shot" and who != null and is_instance_valid(who) and brain.senses.sees(who):
		kind = &"shot_seen"
		fear = maxf(fear, _fear_of(kind, distance))
	if down != null and (not is_instance_valid(down) or body.global_position.distance_to(down.global_position) > float(STIMULI[&"down"].reach) * 1.5):
		down = null


## The choice, by his dials against the fear (the brief's table, §4).
func _decide() -> void:
	var nerve := _nerve()
	var nosy := _nosy()
	var duty := _duty()
	var scared := fear > nerve
	var shots_lately := brain.senses != null and not brain.senses.last_sound([&"gunshot"], SHOOTER_GONE).is_empty()
	_target = Vector3.INF
	_route.clear()
	_arrived = false
	_wait = 0.0
	_speed = WALK
	_calm_need = CALM_WATCH + CALM_WATCH_NOSY * nosy
	if kind == &"gun":
		choice = &"back_away" if scared else &"watch"
		_calm_need = CALM_GUN
		if scared:
			var away := body.global_position - at
			away.y = 0.0
			_go(body.global_position + (away.normalized() if away.length() > 0.1 else -body.global_basis.z) * BACK_AWAY, WALK)
	elif scared:
		_calm_need = CALM_HIDE + CALM_HIDE_NERVE * (1.0 - nerve)
		var refuge := _refuge()
		if refuge != Vector3.INF and body.physiology.can_run() and kind != &"down":
			choice = &"flee"
			_go(refuge, RUN)
			if kind == &"blast":
				_wait = 2.5  # flat first, then runs from it
		elif kind == &"down":
			choice = &"carry_on"  # stops, turns away
			_calm_need = lerpf(BREATH.x, BREATH.y, _rng.randf()) * 2.0
		else:
			choice = &"hide"
		if choice in [&"flee", &"hide"]:
			brain.say(&"cower")
	elif down != null and duty >= 0.6 and duty >= nosy and not shots_lately and body.physiology.can_run():
		choice = &"help"
		var from := body.global_position - down.global_position
		from.y = 0.0
		_go(down.global_position + (from.normalized() if from.length() > 0.1 else Vector3.FORWARD) * 0.9, HURRY)
		brain.say(&"help")
	elif down != null and nosy >= 0.5:
		choice = &"gawk"
		_go(_ring(down.global_position, GAWK_RING.x, GAWK_RING.y), WALK)
	elif kind != &"down" and (nosy >= 0.5 or duty >= 0.7):
		choice = &"gawk"
		var near := WATCH_SHOT if kind in [&"shot_seen", &"blast", &"at_me"] else 8.0
		if kind == &"blast" and duty < 0.7:
			_wait = BLAST_NOSY_AFTER
			_calm_need = maxf(_calm_need, BLAST_NOSY_AFTER + CALM_WATCH)
		if kind == &"blast" and duty >= 0.7:
			near = 8.0
			_speed = HURRY
		var d := body.global_position.distance_to(at)
		if d > near:
			# Toward it, but only so far (to a door, a corner): never all the way.
			var r := maxf(near, d - TOWARD_AT_MOST)
			_go(_ring(at, r, r + 1.5), WALK * (0.8 if duty > nosy else 1.0) if _speed == WALK else _speed)
		else:
			choice = &"watch"
			if kind in [&"shot_seen", &"at_me"] and d < near:
				_go(_ring(at, near, near + 2.0), WALK)  # back off to watch from a distance
	else:
		choice = &"carry_on"
		_calm_need = lerpf(BREATH.x, BREATH.y, _rng.randf())
	if choice == &"gawk" and _target == Vector3.INF:
		choice = &"watch"
	if choice in [&"gawk", &"help", &"back_away"] and _on_errand():
		choice = &"watch"
		_target = Vector3.INF
		_route.clear()


## Where he'd run: the nearest of his refuges (his door, the store, the saloon) that isn't toward
## it, within REFUGE_REACH.
func _refuge() -> Vector3:
	var me := body.global_position
	var threat := at
	if who != null and is_instance_valid(who) and brain.senses != null and brain.senses.sees(who):
		threat = who.global_position
	var best := Vector3.INF
	var best_d := REFUGE_REACH
	for r: Vector3 in brain.refuges:
		var d := me.distance_to(r)
		if d >= best_d:
			continue
		# Not by way of it: the way there passes no nearer the threat than most of his distance now.
		var a := Vector2(me.x, me.z)
		var b := Vector2(r.x, r.z)
		var c := Vector2(threat.x, threat.z)
		var on := Geometry2D.get_closest_point_to_segment(c, a, b)
		if on.distance_to(c) < a.distance_to(c) * 0.6:
			continue
		best_d = d
		best = r
	return best


## A point on a ring of `lo`..`hi` m round `c`, on his side of it, a little to one side.
func _ring(c: Vector3, lo: float, hi: float) -> Vector3:
	var from := body.global_position - c
	from.y = 0.0
	if from.length() < 0.1:
		from = Vector3.FORWARD
	var dir := from.normalized().rotated(Vector3.UP, deg_to_rad(_rng.randf_range(-25.0, 25.0)))
	var p := c + dir * _rng.randf_range(lo, hi)
	p.y = body.global_position.y
	return p


func _on_errand() -> bool:
	var since := float(Engine.get_physics_frames() - brain.sent_frame) / Engine.physics_ticks_per_second
	return since < ERRAND and brain.post != Vector3.INF and body.global_position.distance_to(brain.post) > 1.0


func _go(point: Vector3, speed: float) -> void:
	_target = point
	_speed = speed
	_route.clear()
	if brain.places != null and body.global_position.distance_to(point) > 1.5:
		_route = FireFlight.route(brain.places, body, point)
	else:
		_route.append(point)
	_stuck = 0.0
	_last = body.global_position
	_arrived = false


func _act(delta: float) -> void:
	var p := _look_point()
	if _wait > 0.0:
		_wait -= delta
		if choice == &"flee":
			brain.mood = CivilianBrain.Mood.COWERING
			body.set_pose(&"cower")
		else:
			brain.mood = CivilianBrain.Mood.WATCHING
			body.set_pose(&"stand")
			body.face(p)
		return
	if not _arrived and _target != Vector3.INF:
		if not body.physiology.can_stand():
			_arrived = true
		else:
			brain.mood = CivilianBrain.Mood.RUNNING if _speed > 2.4 else CivilianBrain.Mood.WATCHING
			body.set_pose(&"stand")
			var there := body.walk_to(_route[0], _speed, delta)
			if body.global_position.distance_to(_last) < 0.01 * 60.0 * delta:
				_stuck += delta
			else:
				_stuck = maxf(_stuck - delta, 0.0)
			_last = body.global_position
			if there or _stuck > 2.0:
				_route.pop_front()
				_stuck = 0.0
				if _route.is_empty():
					_arrived = true
			if choice == &"back_away":
				body.face(p)  # backs off, his eyes on the gun
			return
	match choice:
		&"flee", &"hide":
			brain.mood = CivilianBrain.Mood.COWERING
			body.set_pose(&"cower")
		&"help":
			brain.mood = CivilianBrain.Mood.WATCHING
			if down != null and is_instance_valid(down):
				body.face(down.global_position)
			body.set_pose(&"tend")
		&"carry_on":
			brain.mood = CivilianBrain.Mood.WATCHING
			body.set_pose(&"stand")
			if kind == &"down":
				body.face(body.global_position * 2.0 - p)  # turns away from it
			else:
				body.face(p)
		_:
			brain.mood = CivilianBrain.Mood.WATCHING
			body.set_pose(&"stand")
			body.face(down.global_position + Vector3.UP * 0.3 if down != null and is_instance_valid(down) else p)
			if choice == &"gawk" and not _said and _arrived:
				_said = true
				brain.say(&"gawk")


func _mark_shaken() -> void:
	var day := _clock()
	shaken_since = float(day.get(&"time_of_day")) if day != null else 0.0
	_shaken_s = SHAKEN_SECONDS


func _clock() -> Node:
	if _day == null or not is_instance_valid(_day):
		_day = body.get_tree().get_first_node_in_group(&"day_cycle") if body.is_inside_tree() else null
	return _day


func describe() -> String:
	if stage == Stage.NONE:
		return "shaken" if shaken() else ""
	return "%s %s at %.0f m (fear %.2f)%s" % [String(Stage.keys()[stage]).to_lower(), kind, distance, fear,
			(": " + String(choice)) if choice != &"" else ""]
