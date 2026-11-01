class_name FarmhouseMission
extends Node
## The farmhouse hostage rescue (issue #520): the gang holds the rancher in his own house out east
## of town (Farmhouse); you get in and get him out.
##
## How it starts, without debug commands: the blacksmith by the livery (where you start) tells you
## when you walk up to him, if the gang hasn't ridden into town yet; or after a try that failed,
## Enter starts it again from the edge of town (`start_on_load`, GameReset). Dev ways in: the
## bridge's `farm_start`, `-- --mission=farmhouse`.
##
## Started, the gang's riders (TownLife.take_riders: they don't ride into town) and two more are
## at their posts in the house (OutlawBrain.hold: they keep to it), the rancher tied to a chair in
## the bedroom (HostageBrain). The alarm (a man sees you, hears a shot or glass or timber go, a
## blast, a ball into one of them) starts the fight; a blast near the house is a breach: they turn
## to it and one goes to cover it. The guard puts his gun on the rancher when it goes badly, and
## kills him if you're in the house and he's had enough (the dials: config/farmhouse.tres). E held
## by the rancher cuts him loose; he follows you. Won: he's out and safe and nobody's still
## fighting. Lost: he's dead, or you're down. Either way a line on screen; lost, Enter tries again.

enum State {IDLE, TELLING, ON, WON, LOST}

const START_ARG := "--mission=farmhouse"
## A failed try's Enter: the game started again (GameReset) with the mission on from the edge of town.
static var start_on_load := false

var tuning: FarmhouseTuning
var state := State.IDLE
## Seconds since it started; the alarm's, the threat's and the rescue's times on it (-1: not yet).
var t := 0.0
var alarm_t := -1.0
var threat_t := -1.0
var execute_t := -1.0
## When the guard gave you his last word (you in the house, him out of patience); -1 if not now.
var ultimatum_t := -1.0
var freed_t := -1.0
var breach_t := -1.0
var end_t := -1.0
var outcome := &""
var why := ""
## What happened, in order: [t, what] (the scripted runs read it).
var timeline: Array = []

var men: Array[HumanBody] = []
var brains: Array[OutlawBrain] = []
## Each man's spec (FarmhouseTuning.men) by his person_id.
var specs := {}
var guard: OutlawBrain
## The men fought as one (their spots by where you are: HouseDefence).
var defence: HouseDefence
var hostage: HumanBody
var hostage_brain: HostageBrain

## Before the alarm, now and then one of them says something (they're bored; it carries).
const IDLE := {
	&"brody": ["Keep your eyes on that road.", "Nobody comes in here. Nobody.", "Quit your fidgeting, old man."],
	&"lyle": ["How long we sitting here, Brody?", "I could use a drink.", "Somebody's coming, I'd say. Somebody always comes."],
	&"dutch": ["Quiet out there.", "Wind's getting up.", "Dust on the road. No, nothing."],
	&"kid": ["Hot as hell on this porch.", "You reckon they'll send the law?", "Ain't nobody out there."],
	&"hollis": ["Coffee's cold.", "Smells like horse in here.", "Back's clear."],
}
var _idle_in := 12.0
var _rng := RandomNumberGenerator.new()
var _tell_t := 0.0
var _hailed := false
var _hiss_said := -99.0
var _holding := false
var _idle_t := 0.0
## Who fired last, and when (a ball into the rancher: whose it likely was).
var _last_shooter: Node = null
var _last_shot_t := -9.0
var _free_hold := 0.0
var _prompt := 0.0
var _player: Player


func _ready() -> void:
	add_to_group(&"farmhouse_mission")
	add_to_group(&"claims_use")
	if tuning == null:
		tuning = load("res://config/farmhouse.tres")
	Events.exploded.connect(_on_exploded)
	Events.shot_fired.connect(func(_o: Vector3, _d: Vector3, shooter: Node) -> void:
		_last_shooter = shooter
		_last_shot_t = t)
	if start_on_load or START_ARG in OS.get_cmdline_user_args():
		start_on_load = false
		_begin_when_ready.call_deferred(true)
	else:
		_hold_the_gang.call_deferred()


## In the game itself (not the dev bridge's, the tests' or the tools'): the gang waits out at the
## farm while the blacksmith's word is to be had (they'd ride into town at 45 s, and with them in
## town the mission's gone): till you've heard him, or ten minutes.
func _hold_the_gang() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != "res://scenes/main.tscn" or "--dev-bridge" in OS.get_cmdline_user_args():
		return
	var town := _town()
	if town:
		town.hold_gang = true
		_holding = true


static func of(tree: SceneTree) -> FarmhouseMission:
	return tree.get_first_node_in_group(&"farmhouse_mission") as FarmhouseMission


## Once the street's people are in (TownLife spawns them deferred), start it.
func _begin_when_ready(place_player: bool) -> void:
	for i in 10:
		await get_tree().physics_frame
	begin(place_player)


func _town() -> TownLife:
	return get_tree().get_first_node_in_group(&"town_life") as TownLife


func player() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


# --- Starting it ---------------------------------------------------------------------------------

## The men to their posts, the rancher into his chair; with `place_player`, you at the edge of town
## on the road east, looking out to the farm.
func begin(place_player := false) -> void:
	if state in [State.ON, State.WON, State.LOST]:
		return
	var house := Farmhouse.of(get_tree())
	var town := _town()
	if house == null or town == null:
		push_warning("FarmhouseMission: no farmhouse or no town")
		return
	state = State.ON
	t = 0.0
	_rng.seed = 520
	_note("started")
	var street := house.get_parent()
	# The range's man stands by the road east, between the town and the farm: he'd have it out with
	# you on the way (a man walking by with his gun out). Not while the gang's at the farm.
	var range_spawn := street.get_node_or_null(^"OutlawSpawn") as OutlawSpawner
	if range_spawn and range_spawn.outlaw and is_instance_valid(range_spawn.outlaw):
		range_spawn.outlaw.queue_free()
	var riders := town.take_riders()
	var ids: Array[StringName] = []
	for m: Dictionary in tuning.men:
		ids.append(StringName(m.id))
	for i in tuning.men.size():
		var m: Dictionary = tuning.men[i]
		var id := StringName(m.id)
		specs[id] = m
		var man: HumanBody = riders.get(id)
		riders.erase(id)
		if man == null or not is_instance_valid(man):
			man = HumanBody.new()
			man.name = String(id).capitalize()
			man.person_id = id
			man.rng_seed = 520 + i
			man.body_model = StringName(m.get("model", "outlaw"))
		man.masked = bool(m.get("masked", false))
		var brain := OutlawBrain.new()
		brain.name = "Brain"
		brain.temper = float(m.get("temper", 0.5))
		brain.nerve = float(m.get("nerve", 0.6))
		brain.proud = bool(m.get("proud", false))
		brain.leads = bool(m.get("leads", false))
		var friends: Array[StringName] = []
		for other in ids:
			if other != id:
				friends.append(other)
		brain.friends = friends
		brain.places = town.places
		var post := Farmhouse.use_point(String(m.post))
		var room := String(m.get("hold", "house"))
		brain.hold = {"inside": inside_bedroom if room == "bedroom" else inside, "post": post[0], "look": post[1]}
		brain.agenda = [{"do": &"post"}]
		man.add_child(brain)
		man.move_child(brain, 0)
		man.enter(street, post[0], HumanBody.yaw_toward(post[0], post[1]))
		men.append(man)
		brains.append(brain)
		if room == "bedroom":
			guard = brain
		_watch(man, brain)
	for left: HumanBody in riders.values():
		if is_instance_valid(left) and not left.is_inside_tree():
			left.free()
	_hostage(street, town)
	for b in brains:
		b.hold.spare = [hostage]
	defence = HouseDefence.new()
	defence.name = "HouseDefence"
	add_child(defence)
	defence.setup(load("res://experiments/building_lab/spec_building.gd").load_spec(Farmhouse.SPEC), brains, guard, player())
	if place_player:
		var p := player()
		if p:
			var at := town.places.at(&"road_east")
			p.global_position = at + Vector3.UP * 0.05
			var to := Farmhouse.at(Vector3(4.5, 0.0, 2.6)) - at
			p.rotation.y = atan2(-to.x, -to.z)
	_say(tuning_line("intro"), 10.0, true)


func tuning_line(kind: String) -> String:
	match kind:
		"intro":
			return "The gang's holding the rancher at his place, east along the road. Five of them. Get him out alive."
		"won":
			return "The rancher's out, and alive."
		"lost_hostage":
			return "The rancher's dead."
		"lost_you":
			return "You went down. The rancher's still out there with them."
	return ""


## The rancher (the town's, taken from in front of the livery) tied into the bedroom's chair.
func _hostage(street: Node, town: TownLife) -> void:
	if town.rancher != null and is_instance_valid(town.rancher):
		town.rancher.queue_free()
	var seat := Farmhouse.use_point("hostage")
	var chair := Seating.free_chair_near(get_tree(), seat[0], 1.2)
	hostage = HumanBody.new()
	hostage.name = "Rancher"
	hostage.person_id = &"rancher"
	hostage.rng_seed = 109
	hostage.body_model = &"mexican_rancher_s1_talking"
	hostage.has_gun = false
	hostage_brain = HostageBrain.new()
	hostage_brain.name = "Brain"
	hostage_brain.tuning = tuning
	hostage_brain.captors = brains
	hostage.add_child(hostage_brain)
	var at: Vector3 = Seating.spot(chair) if chair else seat[0]
	var faces: Vector3 = Seating.faces(chair) if chair else seat[1]
	hostage.enter(street, at, HumanBody.yaw_toward(at, faces))
	hostage.set_pose(&"sit_back")
	hostage.died.connect(func(cause: StringName) -> void:
		_note("the rancher dead (%s)" % cause)
		_hostage_died())
	hostage.hit.connect(func(info: Dictionary) -> void:
		var by: Variant = info.get("shooter", _last_shooter if t - _last_shot_t < 0.6 else null)
		_note("the rancher hit (%s, %s)" % [info.get("kind", &"bullet"), ("by " + (by as Node).name) if by is Node and is_instance_valid(by) else "?"]))
	hostage_brain.freed.connect(func() -> void:
		freed_t = t
		_note("the rancher cut loose")
		_say("He's loose. Get him out of the house and well away from it.", 6.0)
		# Loose and gone from his chair: the guard's back to the fight (he can't hold a running man).
		if guard != null and is_instance_valid(guard):
			guard.menace = null
			guard.menace_fire = false)
	if chair:
		# Posed sitting first, his weight on the seat a moment on (as the chair lab sits its men).
		_tie.call_deferred(chair)


func _tie(chair: KitProp) -> void:
	for i in 20:
		await get_tree().physics_frame
	if is_instance_valid(hostage) and is_instance_valid(chair):
		chair.sit(hostage)
		hostage_brain.tie_to(chair)


## What each man sees, hears and takes raises the alarm.
func _watch(man: HumanBody, brain: OutlawBrain) -> void:
	man.hit.connect(func(info: Dictionary) -> void:
		var at: Vector3 = info.get("position", man.global_position)
		var p := player()
		_alarm(brain, p.global_position if p and info.get("shooter") == p else at, "%s hit" % man.name))
	man.died.connect(func(_c: StringName) -> void: _note("%s dead" % man.name))
	man.fell.connect(func(conscious: bool) -> void: _note("%s down%s" % [man.name, "" if conscious else ", out"]))
	# The senses are made in the brain's _ready.
	(func() -> void:
		if not is_instance_valid(brain) or brain.senses == null:
			return
		brain.senses.spotted.connect(func(who: Node3D) -> void:
			if who is Player:
				_seen(brain, who as Player))
		brain.senses.heard.connect(func(at: Vector3, kind: StringName, who: Node) -> void:
			_heard(brain, at, kind, who))).call_deferred()


const LOUD := [&"gunshot", &"blast", &"glass", &"timber", &"crash", &"scuffle"]


func _heard(brain: OutlawBrain, at: Vector3, kind: StringName, _who: Node) -> void:
	if state != State.ON:
		return
	if kind in LOUD:
		_alarm(brain, at, "%s heard %s" % [brain.body.name, kind])
	elif kind == &"fuse" and alarm_t < 0.0:
		# A hiss he can't place: he turns to it and wonders (the blast is the alarm).
		brain.glance(at + Vector3.UP * 0.5, 5.0)
		if t - _hiss_said > 6.0:
			_hiss_said = t
			Events.spoke.emit(brain.body, ["What's that hissing?", "You hear that? Something's hissing.", "Hey— what's that?"][_rng.randi() % 3])
	elif alarm_t < 0.0:
		# A step, a voice: he turns to it (and may see you); the nearest of them goes to the window on
		# that side for a look.
		brain.glance(at + Vector3.UP * 1.0, 4.0)
		if kind != &"speech":
			_look_out(at)


## Seen. A man walking up with his gun put away, a way off, gets a warning first (they take their
## windows, guns on him); one with his gun out, or close, or coming on after it, is the alarm.
var warned_t := -1.0
var _warn_from := INF


func _seen(by: OutlawBrain, p: Player) -> void:
	if state != State.ON or alarm_t >= 0.0:
		return
	var d := p.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8)))
	var armed := p.weapon != null and p.weapon.drawn and not p.weapon is DynamiteViewmodel
	if armed or d < tuning.warn_close or FarmhouseMission.inside(p.global_position):
		_alarm(by, p.global_position, "%s saw you" % by.body.name)
		return
	if warned_t < 0.0:
		warned_t = t
		_warn_from = d
		_note("%s warns you off" % by.body.name)
		Events.spoke.emit(by.body, ["That's far enough, mister! Turn around!", "Hold it right there! Walk away, friend!", "You're on private land. Keep walking!"][_rng.randi() % 3])
		# To the windows on your side, watching you (not shooting: not yet).
		if defence:
			var side := HouseDefence.place_of(p.global_position)
			var given := 0
			for id in defence.plans.get(side, []):
				var sp: Dictionary = defence.spots.get(id, {})
				if sp.is_empty() or not sp.get("window", false):
					continue
				var best: OutlawBrain = null
				var best_d := INF
				for b in brains:
					if b == guard or not _able(b) or b.mood != OutlawBrain.Mood.CALM or b.hold.get("warned", false):
						continue
					var bd := b.body.global_position.distance_to(sp.world)
					if bd < best_d:
						best = b
						best_d = bd
				if best:
					best.hold.warned = true
					best.hold.post_was = best.hold.post
					best.hold.look_was = best.hold.look
					best.hold.post = sp.world
					best.hold.look = p.global_position + Vector3.UP * 1.0
					given += 1
				if given >= 2:
					break


## While you've been warned off: coming on, drawing, or hanging about it's the alarm; gone far
## enough off, they stand down.
func _warning_step() -> void:
	if warned_t < 0.0 or alarm_t >= 0.0:
		return
	var p := player()
	if p == null:
		return
	var d := p.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8)))
	var armed := p.weapon != null and p.weapon.drawn and not p.weapon is DynamiteViewmodel
	var seen := brains.any(func(b: OutlawBrain) -> bool: return _able_calm(b) and b.senses.sees(p))
	if seen and (armed or d < tuning.warn_close or (t - warned_t > tuning.warn_seconds and d < _warn_from + 5.0)):
		var by: OutlawBrain = null
		for b in brains:
			if _able_calm(b) and b.senses.sees(p):
				by = b
				break
		_alarm(by, p.global_position, "you came on after the warning" if not armed else "you drew on them")
		return
	if d > tuning.warn_far:
		warned_t = -1.0
		_note("you walked off; they stand down")
		for b in brains:
			if b.hold.get("warned", false):
				b.hold.post = b.hold.post_was
				b.hold.look = b.hold.look_was
				b.hold.erase("warned")


func _able_calm(b: OutlawBrain) -> bool:
	return is_instance_valid(b) and is_instance_valid(b.body) and b.body.physiology.alive and b.body.physiology.is_conscious() and not b.body.limp


## Something heard outside before the alarm: the nearest calm man to a window on that side goes
## and looks out of it a while (says so), then back to his post. Not more often than every 8 s.
var _look_out_t := -99.0
var _looking: OutlawBrain = null
var _looking_post := {}


func _look_out(at: Vector3) -> void:
	if t - _look_out_t < 8.0 or defence == null:
		return
	var side := HouseDefence.place_of(at)
	var window := ""
	for id in defence.plans.get(side, []):
		if (defence.spots.get(id, {}) as Dictionary).get("window", false):
			window = id
			break
	if window == "":
		return
	var sp: Dictionary = defence.spots[window]
	var best: OutlawBrain = null
	var best_d := INF
	for b in brains:
		if b == guard or not _able(b) or b.mood != OutlawBrain.Mood.CALM or b == _looking:
			continue
		var d := b.body.global_position.distance_to(sp.world)
		if d < best_d:
			best = b
			best_d = d
	if best == null or best_d > 9.0:
		return
	_look_out_t = t
	_back_to_post()
	_looking = best
	_looking_post = {"post": best.hold.post, "look": best.hold.look, "until": t + 9.0}
	best.hold.post = sp.world
	best.hold.look = at + Vector3.UP * 1.0
	Events.spoke.emit(best.body, ["Heard something.", "Hold on. Something out there.", "You hear that?"][_rng.randi() % 3])
	_note("%s goes to the %s to look" % [best.body.name, window.replace("_", " ")])


func _back_to_post() -> void:
	if _looking != null and is_instance_valid(_looking) and not _looking_post.is_empty():
		_looking.hold.post = _looking_post.post
		_looking.hold.look = _looking_post.look
	_looking = null
	_looking_post = {}


## The alarm: everyone in it, told where (as near as the one who raised it knows).
func _alarm(by: OutlawBrain, at: Vector3, what: String) -> void:
	if state != State.ON or alarm_t >= 0.0:
		return
	alarm_t = t
	_note("the alarm: " + what)
	for b in brains:
		if is_instance_valid(b):
			b.hold.erase("warned")
	var p := player()
	if p == null:
		return
	if by != null and is_instance_valid(by):
		by.callout(&"spotted", p, at)
	for b in brains:
		if not is_instance_valid(b) or not b.body.physiology.alive:
			continue
		b.senses.note(p, at, 0.5 if b == by else tuning.heard_error)
		b.quiet_start = b != by  # one of them says it; the rest just go to it
		b.relations.provoke(p)
		var m: Dictionary = specs.get(b.body.person_id, {})
		var alarm_post := String(m.get("alarm_post", ""))
		if alarm_post != "":
			# The man outside: in, to his place at a window.
			var pt := Farmhouse.use_point(alarm_post)
			if not pt.is_empty():
				b.hold.post = pt[0]
				b.hold.look = pt[1]


func _on_exploded(at: Vector3, _kg: float) -> void:
	if state != State.ON:
		return
	var house := Farmhouse.of(get_tree())
	var centre := Farmhouse.at(Vector3(4.5, 1.0, 3.8))
	if house == null or at.distance_to(centre) > tuning.breach_reach:
		return
	breach_t = t
	_note("a blast at the house")
	_alarm(null, at, "the blast")
	# They turn to it, and a man goes to a spot with a line on the hole (HouseDefence).
	var p := player()
	for b in brains:
		if _able(b) and p:
			b.senses.note(p, at, 1.0)
	if defence:
		defence.breach(at)


func _able(b: OutlawBrain) -> bool:
	return is_instance_valid(b) and is_instance_valid(b.body) and b.body.physiology.alive and b.body.physiology.is_conscious() \
			and not b.body.limp and not b.mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.FLEEING, OutlawBrain.Mood.DOWN, OutlawBrain.Mood.DEAD]


## Out of it: dead, down, given up, run off or gone.
func _out(b: OutlawBrain) -> bool:
	if not is_instance_valid(b) or not is_instance_valid(b.body) or not b.body.is_inside_tree():
		return true
	if not _able(b):
		return true
	return b.body.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8))) > 40.0


func men_out() -> int:
	return brains.filter(func(b: OutlawBrain) -> bool: return _out(b)).size()


# --- The house ----------------------------------------------------------------------------------

## In the house (its rooms, the lean-to's kitchen, the loft), in the world.
static func inside(p: Vector3) -> bool:
	var l := Farmhouse.origin().affine_inverse() * p
	if l.y < -0.5 or l.y > 8.0:
		return false
	return (l.x > 0.05 and l.x < 8.95 and l.z > 0.05 and l.z < 5.15) or (l.x > 0.05 and l.x < 5.55 and l.z > 5.15 and l.z < 7.55)


## In the bedroom (the guard's room).
static func inside_bedroom(p: Vector3) -> bool:
	var l := Farmhouse.origin().affine_inverse() * p
	return l.y > -0.5 and l.y < 3.0 and l.x > 5.65 and l.x < 8.95 and l.z > 0.1 and l.z < 5.1


## Clear of the house by `m` (its walls, the lean-to's).
static func clear_of_house(p: Vector3, m: float) -> bool:
	var l := Farmhouse.origin().affine_inverse() * p
	var main := l.x < -m or l.x > 9.0 + m or l.z < -m or l.z > 5.2 + m
	var lean := l.x < -m or l.x > 5.6 + m or l.z < 5.2 - m or l.z > 7.6 + m
	return main and lean


# --- Each tick -------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_offer(delta)
			_idle_t += delta
			if _holding and _idle_t > 600.0:
				_holding = false
				var town := _town()
				if town:
					town.hold_gang = false
		State.TELLING:
			_telling(delta)
		State.ON:
			t += delta
			_idle_talk(delta)
			_warning_step()
			_rancher_calls(delta)
			if _looking != null and t > float(_looking_post.get("until", INF)):
				_back_to_post()
			_guard_step()
			_rescue_step(delta)
			_check_end()
		State.LOST:
			if Input.is_action_just_pressed(&"ui_accept"):
				retry()


func _guard_step() -> void:
	if guard == null or not _able(guard) or hostage == null or not is_instance_valid(hostage) or not hostage.physiology.alive:
		return
	if alarm_t < 0.0:
		return
	var others := brains.filter(func(b: OutlawBrain) -> bool: return b != guard)
	var down := others.filter(func(b: OutlawBrain) -> bool: return _out(b)).size()
	var last := down >= others.size()
	var p := player()
	var player_in := p != null and inside(p.global_position)
	var had_enough := last or t - alarm_t >= tuning.shoot_after_alarm
	if threat_t < 0.0 and (last or down >= tuning.bad_fight_down or (player_in and had_enough)):
		threat_t = t
		guard.menace = hostage
		_note("the guard puts his gun on the rancher" + (" (the last man)" if last else ""))
	# His last word: once you're in the house and he's had enough, he tells you (again) and gives you
	# `threat_seconds` from then, not from when he first drew on him (the blast that took two of
	# his friends): back out of the house and the count starts over.
	if threat_t >= 0.0 and execute_t < 0.0:
		if player_in and had_enough:
			if ultimatum_t < 0.0:
				ultimatum_t = t
				if t - threat_t > 0.5:
					guard.warn_again()
				_note("the guard's last word")
		elif ultimatum_t >= 0.0:
			ultimatum_t = -1.0
			_note("you backed off")
	if ultimatum_t >= 0.0 and execute_t < 0.0 and t - ultimatum_t >= tuning.threat_seconds:
		execute_t = t
		guard.menace_shots = tuning.execute_shots
		guard.menace_fire = true
		_note("the guard shoots the rancher")


## Before the alarm: a word now and then from a man at his post.
func _idle_talk(delta: float) -> void:
	if alarm_t >= 0.0 or brains.is_empty():
		return
	_idle_in -= delta
	if _idle_in > 0.0:
		return
	_idle_in = _rng.randf_range(18.0, 40.0)
	var b: OutlawBrain = brains[_rng.randi() % brains.size()]
	if not _able(b) or b.mood != OutlawBrain.Mood.CALM:
		return
	var said: Array = IDLE.get(b.body.person_id, [])
	if not said.is_empty():
		Events.spoke.emit(b.body, said[_rng.randi() % said.size()])  # heard as speech (DeedWatch)


## You in the house and him still tied and awake: he calls out where he is now and then (a
## blast's dust, the fight: you'd not know otherwise).
var _call_t := 0.0


func _rancher_calls(delta: float) -> void:
	_call_t -= delta
	if _call_t > 0.0 or hostage_brain == null or not is_instance_valid(hostage) or not hostage_brain.tied:
		return
	if not hostage.physiology.alive or not hostage.physiology.is_conscious():
		return
	var p := player()
	if p and inside(p.global_position):
		_call_t = 7.0
		hostage_brain.say(&"help")


## Where the rancher is (his chest: knocked down, out cold, his body's root can be a way off).
func hostage_at() -> Vector3:
	var chest := hostage.parts.get(&"chest") as Node3D if hostage.parts else null
	return chest.global_position if chest else hostage.global_position


## E is for the rancher by him: held, it cuts him loose; out cold and loose, held, you drag him
## by the collar.
func claims_use(p: Player) -> bool:
	if state != State.ON or hostage_brain == null or not is_instance_valid(hostage) or not hostage.physiology.alive:
		return false
	if not (hostage_brain.tied or hostage.limp):
		return false
	var at := hostage_at()
	return Vector2(p.global_position.x - at.x, p.global_position.z - at.z).length() <= tuning.free_reach \
			and absf(p.global_position.y - at.y) < 1.6


func _rescue_step(delta: float) -> void:
	var p := player()
	if p == null or not claims_use(p):
		_free_hold = 0.0
		if hostage != null and is_instance_valid(hostage) and hostage.dragged_by == p:
			hostage.dragged_by = null
		return
	_prompt -= delta
	if not hostage_brain.tied:
		# Loose and out cold: by the collar while E's held, backing out with him.
		if Input.is_action_pressed(&"shove"):
			hostage.dragged_by = p
			var back := p.global_basis.z
			back.y = 0.0
			hostage.drag_toward(p.global_position + back.normalized() * 0.2 + Vector3.UP * 0.4, delta)
			if _prompt <= 0.0:
				_prompt = 0.5
				_say("Dragging him...", 0.6)
		else:
			hostage.dragged_by = null
			if _prompt <= 0.0:
				_prompt = 0.5
				_say("He's out cold. Hold E to drag him", 0.6)
		return
	if Input.is_action_pressed(&"shove"):
		_free_hold += delta
		if _prompt <= 0.0:
			_prompt = 0.5
			_say("Cutting the ropes...", 0.6)
		if _free_hold >= tuning.free_hold:
			_free_hold = 0.0
			hostage_brain.free_by(p)
	else:
		_free_hold = 0.0
		if _prompt <= 0.0:
			_prompt = 0.5
			_say("Hold E to cut him loose", 0.6)


func _check_end() -> void:
	var p := player()
	if p and not p.wounds.physiology.is_conscious():
		_lose(&"you_down", tuning_line("lost_you"))
		return
	if hostage == null or not is_instance_valid(hostage):
		return
	if hostage_brain.tied or not hostage.physiology.alive:
		return
	if not clear_of_house(hostage.global_position, tuning.safe_from_house):
		return
	# Nobody still fighting: no man still in it who knows where you are (one holed up in the house
	# who's lost you this long isn't: you've got the rancher clear of him). Or he's well away (out of
	# their reach: whoever's left in the house can have it).
	var away := hostage.global_position.distance_to(Farmhouse.at(Vector3(4.5, 0.0, 3.8))) > tuning.safe_away
	for b in brains:
		if not away and not _out(b) and b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING] and b.senses.since_known(p) < 10.0:
			return
	state = State.WON
	end_t = t
	outcome = &"won"
	_note("won")
	hostage_brain.safe = true
	hostage_brain.say(&"safe")
	_say(tuning_line("won"), 10.0, true)


func _hostage_died() -> void:
	if state == State.ON:
		_lose(&"hostage_dead", tuning_line("lost_hostage"))


func _lose(what: StringName, line: String) -> void:
	state = State.LOST
	end_t = t
	outcome = what
	why = line
	_note("lost: %s" % what)
	_say(line + "  (Enter: try again)", 12.0, true)
	_hold_line.call_deferred(line)


## The line stays up (over the doctor's waking words) till you take it.
func _hold_line(line: String) -> void:
	for i in 40:
		await get_tree().create_timer(1.0).timeout
		if state != State.LOST:
			return
		_say(line + "  (Enter: try again)", 1.5, true)


## Again from the start: the game started over (GameReset), the mission on from the edge of town.
func retry() -> void:
	start_on_load = true
	GameReset.reset(get_tree())


# --- The blacksmith tells you -------------------------------------------------------------------

## Walk up to the blacksmith by the livery before the gang's come into town, and he tells you.
func _offer(_delta: float) -> void:
	if Engine.get_physics_frames() % 15 != 0:
		return
	var town := _town()
	var p := player()
	if town == null or p == null or town.blacksmith == null or not is_instance_valid(town.blacksmith):
		return
	var b := town.blacksmith
	if not b.physiology.alive or not b.physiology.is_conscious() or town.gang_came():
		return
	var d := p.global_position.distance_to(b.global_position)
	if d < 14.0 and not _hailed:
		# He's been watching for someone: he calls you over.
		_hailed = true
		Events.spoke.emit(b, "You there! A word, mister. Over here.")
	if d > 3.0:
		return
	state = State.TELLING
	_tell_t = 0.0
	Events.spoke.emit(b, "You're the one with the spring claim? Listen. They've got the rancher out at his place, east along the road.")


func _telling(delta: float) -> void:
	var town := _town()
	var b: HumanBody = town.blacksmith if town else null
	_tell_t += delta
	if b and is_instance_valid(b):
		var p := player()
		if p:
			b.face(p.global_position + Vector3.UP * 1.5)
	if _tell_t >= 5.0 and _tell_t - delta < 5.0 and b and is_instance_valid(b):
		Events.spoke.emit(b, "Brody's bunch. Sheriff's in no shape to go. If you're going, go now, before they do for him.")
	if _tell_t >= 10.0:
		state = State.IDLE
		begin(false)


# --- Telling ------------------------------------------------------------------------------------

func _say(text: String, seconds: float, hold := false) -> void:
	var p := player()
	if p and p.wounds and text != "":
		p.wounds.say(text, seconds, hold)


func _note(what: String) -> void:
	timeline.append([snappedf(t, 0.01), what])


## What it came to (the scripted runs, the bridge's `farm_state`).
func result() -> Dictionary:
	var out := {"state": State.keys()[state], "outcome": String(outcome), "t": snappedf(t, 0.01),
			"alarm": snappedf(alarm_t, 0.01), "breach": snappedf(breach_t, 0.01), "threat": snappedf(threat_t, 0.01),
			"executed": snappedf(execute_t, 0.01), "freed": snappedf(freed_t, 0.01), "end": snappedf(end_t, 0.01),
			"men_out": men_out(), "men": brains.size(), "timeline": timeline}
	out.hostage_alive = hostage != null and is_instance_valid(hostage) and hostage.physiology.alive
	var p := player()
	out.player_down = p != null and not p.wounds.physiology.is_conscious()
	if p:
		out.player_how = p.wounds.physiology.describe()
	var ms := []
	for b in brains:
		if not is_instance_valid(b) or not is_instance_valid(b.body):
			ms.append({"gone": true})
			continue
		ms.append({"id": String(b.body.person_id), "mood": OutlawBrain.Mood.keys()[b.mood], "alive": b.body.physiology.alive,
				"tactic": OutlawBrain.Tactic.keys()[b.tactic], "inside": inside(b.body.global_position),
				"order": String(b.order.get("id", "")), "at": HouseDefence.place_of(b.body.global_position)})
	out.where = defence.where if defence else ""
	out.men_state = ms
	return out
