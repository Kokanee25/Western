extends Node
## One fight in the gunfight lab (README.md): sets the arena up, turns the gang on you, plays you
## with the scripted player (player_bot.gd) or lets you play it (style "human", play.gd), watches
## everything that happens through the game's own events and the men's brains (read, never
## changed), and writes it down when it's over.
## Changes nothing about how the game plays: the men are the game's (TownLife.GANG's tempers),
## only where they stand, what they wear and the hour are the lab's.

const Bot := preload("res://experiments/gunfight_lab/player_bot.gd")
const SCENARIOS := "res://experiments/gunfight_lab/scenarios.json"
## Prof's timers that are people (CLAUDE.md's frame budget table, "People").
const PEOPLE := [&"people_body", &"people_skeleton", &"senses", &"outlaw_brain", &"civilian_brain", &"player", &"town_life", &"blood"]
## How long with nobody firing before a fight's called a lull (both sides lost each other).
const LULL := 45.0
## A ball into the ground this near a man's line of sight to another (m) throws dust across it.
const DUST_LINE := 1.0
## ... or this near a man still in it (m): dirt kicked up round him.
const DUST_NEAR := 1.2
## A member broken this near a man's cover (m) is his cover shot away.
const COVER_NEAR := 2.5
## Frames drawn before a capture is taken (the haze and the light settle after drawing was off).
const DRAW_SETTLE := 4
## A man with no clear line to you for longer than this (s) who fires at you or calls he's spotted
## you knows where you are by something other than his eyes (Senses looks a few times a second).
const NO_LINE := 0.5

var lab  # bridge.gd (a BridgeLab) or play.gd: street, player, seconds(), physics_frames()
var street: Node3D
var player: Player
var opts := {}
var scen := {}
var gang: Array = []  # HumanBody (freed once a man rides out of town: never typed in a loop)
var gang_ids: Array[String] = []
var brains := {}  # id -> OutlawBrain
var bot: RefCounted
var t := 0.0
var started := false
var done := false
var record := {}

var _men := {}  # id -> his record
var _prev := {}  # id -> {tactic, mood, suppressed}
var _timeline: Array = []
var _track: Array = []
var _track_t := 0.0
var _shots: Array = []  # fight times of every shot
var _lamps: Array = []  # [OilLamp, was broken]
var _members := {}  # member_id -> [StructureMember]
var _fire_max := 0
var _fire_check := 0.0
var _hit_frames := {}  # "shooter@frame" -> true (a charge's pellets count once)
var _you := {}
var _sit := {}
var _first := {}
var _hooks: Array = []
var _prof_last := {}
var _prof_fight := {}
var _prof_calm := {}
var _people_frames: Array = []  # people ms each frame of the fight
var _frame_us: Array = []
var _last_us := 0
var _calm_frames := 0
var _fight_frames := 0
var _shoot_dir := ""
var _shot_every := 0.0
var _next_shot_t := 0.0
var _overview: Camera3D
## You playing (style "human"): no bot; they turn on you when you go for your gun, or when the
## count runs out.
var human := false
var _count := -1.0
var _you_at := Vector3.INF  # where you last stood still
var _you_still := 0.0
var _turned := false  # they've turned on you, and when
var _turned_at := 0.0
const _FRIGHTS := ["hit", "near miss", "a friend down or quit", "a friend's shout"]
var _fear_why := {}  # id -> [what just frightened him, the frame]
## Captures still being taken (the bridge waits for them before it answers).
var capturing := 0


func _init(owner_lab: Node, options: Dictionary) -> void:
	lab = owner_lab
	opts = options
	name = "GunfightFight"


# -- Setting up -----------------------------------------------------------------------------------

## Everything before the fight starts (awaits game time). Returns "" or what went wrong.
func setup() -> String:
	street = lab.street
	player = lab.player
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIOS))
	if not (data.scenarios as Dictionary).has(opts.scenario):
		return "no scenario %s (%s)" % [opts.scenario, ", ".join((data.scenarios as Dictionary).keys())]
	scen = data.scenarios[opts.scenario]
	var hours: Dictionary = data.hours
	var hour: float = float(hours.get(opts.hour, opts.hour)) if (hours.has(opts.hour) or String(opts.hour).is_valid_float()) else 17.6
	var models: Dictionary = (data.gang_models as Dictionary).get(opts.bodies, {})
	if opts.bodies == "game":
		# Whatever the game's own gang wears today (TownLife.GANG's models).
		for g: Dictionary in TownLife.GANG:
			models[String(g.id)] = String(g.get("model", "outlaw"))
	if models.is_empty():
		return "no bodies %s (%s)" % [opts.bodies, ", ".join((data.gang_models as Dictionary).keys())]
	seed(int(opts.seed) * 104729 + 7)
	var clock := street.find_child("DayCycle", true, false) as DayCycle
	# The clock runs as it does in the game (scale 1, 45 minutes a day): bodies bleed and heal on
	# its time (PlayerWounds, HumanBody: physiology.step(delta * time_scale)), so a stopped clock
	# would stop every wound. A long fight at golden hour runs on toward 18:00, when the lamps light.
	clock.set_time(hour)
	clock.set_time_scale(1.0)
	var town := street.get_node_or_null(^"TownLife") as TownLife
	town._arrived = true  # the gang's day doesn't start on its own: they're the lab's
	for g in town.gang:
		if is_instance_valid(g):
			g.queue_free()
	town.gang.clear()
	Prof.on = true
	_prof_last = Prof._sum.duplicate()
	# You: where the scenario puts you, your gun out (or away, walking into an ambush).
	var p: Dictionary = scen.player
	var at := _v(p.at)
	player.global_position = at
	player.velocity = Vector3.ZERO
	var gang_mid := Vector3.ZERO
	for id: String in scen.gang:
		gang_mid += _v(scen.gang[id].at) / float((scen.gang as Dictionary).size())
	var facing: Variant = p.get("facing", "gang")
	var yaw := HumanBody.yaw_toward(at, gang_mid) if facing is String else deg_to_rad(-float(facing))
	player.rotation.y = yaw
	var gun: WeaponViewmodel = player.revolver() if opts.weapon == "revolver" else player.shotgun()
	human = opts.style == "human"
	if scen.start != "ambush" and not human:
		player.select_weapon(gun)
		var until := Engine.get_physics_frames() + 240
		while Engine.get_physics_frames() < until and not (player.weapon == gun and gun.drawn):
			await get_tree().physics_frame
	await lab.seconds(1.0)  # a second of the street as it is, for the frame's calm share
	_prof_calm = _prof_delta()
	_calm_frames = 60
	# The three, the game's own men in the lab's bodies.
	var by_id := {}
	for g: Dictionary in TownLife.GANG:
		by_id[String(g.id)] = g
	var i := 0
	var space := player.get_world_3d().direct_space_state
	var eye := at + Vector3.UP * player.tuning.stand_eye_height
	for id: String in scen.gang:
		var g: Dictionary = by_id[id]
		var s: Dictionary = scen.gang[id]
		var man := HumanBody.new()
		man.name = id.capitalize()
		man.person_id = StringName(id)
		man.rng_seed = 200 + i + 10 * int(opts.seed)
		man.shirt_color = g.shirt
		man.coat_color = g.coat
		man.hat_color = g.hat
		man.body_model = StringName(models.get(id, "outlaw"))
		var brain := OutlawBrain.new()
		brain.name = "Brain"
		brain.temper = g.temper
		brain.nerve = g.nerve
		brain.proud = g.proud
		var friends: Array[StringName] = []
		for other: String in scen.gang:
			if other != id:
				friends.append(StringName(other))
		brain.friends = friends
		brain.places = town.places
		brain.variant = OutlawBrain.Variant.get(String(opts.get("variant", "C")), OutlawBrain.Variant.C)
		man.add_child(brain)
		var pos := _v(s.at)
		var cover := {}
		if s.get("cover", false):
			cover = _cover_near(space, pos, eye, man)
			if not cover.is_empty():
				pos = cover.at
		man.enter(street, pos, HumanBody.yaw_toward(pos, at))
		if s.get("cover", false):
			man.set_pose(&"crouch")
		gang.append(man)
		gang_ids.append(id)
		brains[id] = brain
		town.gang.append(man)
		_men[id] = {"id": id, "model": String(man.body_model), "temper": g.temper, "nerve": g.nerve, "start": _arr(pos),
			"cover_found": (_arr(cover.at) if not cover.is_empty() else false) if s.get("cover", false) else null,
			"cover_kind": ("lie" if cover.get("lie", false) else "low" if cover.get("low", false) else "wall") if not cover.is_empty() else "", "shots": 0, "hits_on_you": 0,
			"hits_taken": 0, "friendly_hits": 0, "cover_changes": 0, "peeks": 0, "flanks": 0, "suppressing_shots": 0,
			"pinned": 0, "reloads": 0, "callouts": {}, "near_misses_on_him": 0, "outcome": "standing", "out_at": -1.0,
			"moods": [], "_cover": cover}
		i += 1
	await lab.physics_frames(3)
	_check_bodies()
	# Lamps the scenario wants lit, and every lamp near enough to be part of it, to watch.
	var lit_in: String = (scen.get("lamps", {}) as Dictionary).get("lit", "")
	for n in street.find_children("*", "OilLamp", true, false):
		var lamp := n as OilLamp
		if lit_in != "" and street.get_node_or_null(NodePath(lit_in)) and street.get_node(NodePath(lit_in)).is_ancestor_of(lamp):
			lamp.set_lit(true)
		if lamp.global_position.distance_to(at) < 30.0:
			_lamps.append([lamp, lamp.broken])
	for n in street.find_children("*", "StructureMember", true, false):
		var m := n as StructureMember
		if m.global_position.distance_to(at) < 40.0:
			if not _members.has(m.member_id):
				_members[m.member_id] = []
			_members[m.member_id].append(m)
	# The scripted player.
	if not human:
		bot = Bot.new()
		bot.setup(player, gang, opts.style, int(opts.seed), opts.weapon, float(opts.get("aim", 1.0)))
	if scen.start == "ambush" and not human:
		bot.walking = true
		bot.walk_dir = _v(p.get("walk", [1, 0, 0])).normalized()
	_hook_events()
	await lab.seconds(1.0)  # they look about them (and see you) before it starts
	for man: HumanBody in _live():
		_prev[_mid(man)] = {"tactic": -1, "mood": -1, "suppressed": 0.0}
	record["hour_at_start"] = snappedf(clock.time_of_day, 0.01)
	if human:
		# Yours to start: your gun away; they go for theirs when you go for yours, or when the
		# count's out.
		var until := Engine.get_physics_frames() + 240
		player.select_weapon(gun)
		while Engine.get_physics_frames() < until and player.weapon != gun:
			await get_tree().physics_frame
		gun.put_away()
		_count = float(opts.get("count", 3.0))
		_you_at = player.global_position
		_note("start", "you're in (%s, %s, variant %s, seed %d): draw when you're ready" % [opts.scenario, opts.hour, opts.get("variant", "C"), int(opts.seed)])
		_prof_last = Prof._sum.duplicate()
		_last_us = Time.get_ticks_usec()
		started = true
		return ""
	_turn()
	if scen.start != "ambush":
		bot.know_all()
	await lab.physics_frames(2)
	if scen.start == "ambush":
		# Down in their cover, waiting their moment (as a man who's got there does: OutlawBrain's
		# arrival at cover), not standing in the open.
		for man: HumanBody in _live():
			var c: Dictionary = _men[_mid(man)]._cover
			var b := brains[_mid(man)] as OutlawBrain
			if not c.is_empty():
				b.cover = c
				b.tactic = OutlawBrain.Tactic.HIDDEN
				b._tactic_time = b._think.randf_range(0.2, 1.2)
				b._in_cover = 0.0
				b._peeks = 0
	_note("start", "the gang turns on you (%s, %s, %s, %s, variant %s, seed %d)" % [opts.scenario, opts.hour, opts.weapon, opts.style, opts.get("variant", "C"), int(opts.seed)])
	_prof_last = Prof._sum.duplicate()
	_last_us = Time.get_ticks_usec()
	_shoot_dir = String(opts.get("shots", ""))
	_shot_every = float(opts.get("every", 4.0))
	if _shoot_dir != "" and DisplayServer.get_name() != "headless":
		# Drawn only round each capture (lavapipe draws the street at a frame every few seconds);
		# the game's logic runs on regardless, so the fight is the headless one.
		RenderingServer.render_loop_enabled = false
	started = true
	return ""


## It starts: they turn on you, as if you'd shot at them (the bridge's `fight`).
func _turn() -> void:
	_turned = true
	_turned_at = t
	for man: HumanBody in _live():
		(brains[_mid(man)] as OutlawBrain).relations.provoke(player)
		if scen.start == "ambush":
			(brains[_mid(man)] as OutlawBrain).senses.note(player, player.global_position, 0.5)


## The nearest spot (within 1.5 m of `p`) that hides a man from `eye`, by the gang's own test.
func _cover_near(space: PhysicsDirectSpaceState3D, p: Vector3, eye: Vector3, _man: HumanBody) -> Dictionary:
	var ex: Array[RID] = [player.get_rid()]
	var best := {}
	var best_d := INF
	for dx in [0.0, 0.3, -0.3, 0.6, -0.6, 0.9, -0.9, 1.2, -1.2, 1.5, -1.5]:
		for dz in [0.0, 0.3, -0.3, 0.6, -0.6, 0.9, -0.9, 1.2, -1.2, 1.5, -1.5]:
			var q := p + Vector3(dx, 0.3, dz)
			var c := Cover.evaluate(space, q, eye, ex)
			if c.is_empty():
				continue
			var d := Vector2(dx, dz).length()
			if d < best_d:
				best_d = d
				best = c
	return best


## Whatever about the new men doesn't work as the old ones do: noted, not fixed.
func _check_bodies() -> void:
	var notes: Array = []
	for man: HumanBody in _live():
		var m: Dictionary = _men[_mid(man)]
		var missing: Array = []
		for sid in [&"head", &"chest", &"pelvis"]:
			if not man.parts.has(sid):
				missing.append(String(sid))
		if not missing.is_empty():
			notes.append("%s: no %s hitbox" % [m.id, ", ".join(missing)])
		if man.held_gun == null and not man.gun_holstered:
			notes.append("%s: no gun" % m.id)
		var hat := false
		for n in man.find_children("*", "", true, false):
			if n.has_meta(&"hat_of"):
				hat = true
				break
		m["hat_can_be_shot"] = hat
		m["whole_model"] = PeopleBodies._is_whole(man.body_model) if PeopleBodies.has_model(man.body_model) else false
		m["model_loaded"] = PeopleBodies.has_model(man.body_model)
	record["body_notes"] = notes


# -- Each tick ------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not started or done:
		return
	var now_us := Time.get_ticks_usec()
	_frame_us.append(now_us - _last_us)
	_last_us = now_us
	var d := _prof_delta()
	var people := 0.0
	for k in PEOPLE:
		people += float(d.get(k, 0.0))
	_people_frames.append(people)
	for k: StringName in d:
		_prof_fight[k] = float(_prof_fight.get(k, 0.0)) + float(d[k])
	_fight_frames += 1
	t += delta
	if bot:
		bot.tick(delta, t)
	else:
		_watch_you(delta)
	_watch_men(delta)
	_watch_world(delta)
	_track_t -= delta
	if _track_t <= 0.0:
		_track_t = 0.5
		_sample()
	if _shoot_dir != "" and t >= _next_shot_t:
		_next_shot_t += _shot_every
		_capture.call_deferred("t%05.1f" % t)
	_check_end()


## You playing: they turn when your gun comes out (or the count's done); and each time you move
## somewhere new (2 m from where you'd stood still a second or more), a relocation.
func _watch_you(delta: float) -> void:
	if _count >= 0.0:
		var gun := player.weapon
		_count -= delta
		if (gun != null and gun.drawn) or _count < 0.0:
			_note("turn", "they go for their guns (%s)" % ("you drew" if gun != null and gun.drawn else "the count's out"))
			_count = -1.0
			_turn()
	var moved := player.global_position.distance_to(_you_at) if _you_at != Vector3.INF else 0.0
	if moved > 2.0:
		_you.relocations = int(_you.get("relocations", 0)) + 1
		_note("you", "you move (%.0f m)" % moved)
		_you_at = Vector3.INF
	if player.velocity.length() < 0.3:
		_you_still += delta
		if _you_still > 1.0 and _you_at == Vector3.INF:
			_you_at = player.global_position
	else:
		_you_still = 0.0
	if player.is_crouching:
		_you.crouched_s = float(_you.get("crouched_s", 0.0)) + delta


func _watch_men(_delta: float) -> void:
	for i in gang.size():
		var m: Dictionary = _men[gang_ids[i]]
		if not is_instance_valid(gang[i]):
			if m.out_at < 0.0:
				_out_id(gang_ids[i], "fled", "rode out of town")
			continue
		var man := gang[i] as HumanBody
		var b := brains[_mid(man)] as OutlawBrain
		var pv: Dictionary = _prev[_mid(man)]
		if b.tactic != pv.tactic:
			if b.tactic == OutlawBrain.Tactic.MOVING:
				m.cover_changes += 1
				_note("cover", "%s runs for new cover (%.0f m)" % [m.id, man.global_position.distance_to(b.cover.get("at", man.global_position))])
			elif b.tactic == OutlawBrain.Tactic.PEEKING:
				m.peeks += 1
			pv.tactic = b.tactic
		if b.mood != pv.mood:
			var mood_name: String = OutlawBrain.Mood.keys()[b.mood].to_lower()
			m.moods.append([snappedf(t, 0.1), mood_name])
			if b.mood == OutlawBrain.Mood.RELOADING:
				m.reloads += 1
			if b.mood == OutlawBrain.Mood.FLEEING and not m.has("ran"):
				m["ran"] = snappedf(t, 0.1)
				_sit_add("flights", "%s runs for it" % m.id)
			if pv.mood != -1 or b.mood != OutlawBrain.Mood.FIGHTING:
				_note("mood", "%s: %s" % [m.id, mood_name])
			pv.mood = b.mood
		if b.suppressed > 0.0 and float(pv.suppressed) <= 0.0:
			m.pinned += 1
		pv.suppressed = b.suppressed
		# Shaken: gone to ground past his nerve (fix 3); and whether he got it back.
		var shaken: float = b.get("_shaken") if b.get("_shaken") != null else -1.0
		if shaken >= 0.0 and float(pv.get("shaken", -1.0)) < 0.0:
			m.shaken = int(m.get("shaken", 0)) + 1
			_sit_add("shaken", "%s goes to ground, shaken" % m.id)
		elif shaken < 0.0 and float(pv.get("shaken", -1.0)) >= 0.0 and b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING]:
			m.rallied = int(m.get("rallied", 0)) + 1
			_sit_add("rallied", "%s gets his nerve back" % m.id)
		pv.shaken = shaken
		# His decisions and why (OutlawBrain.decision): the timeline, and how his flanks and his
		# looking for you came out.
		var dec: String = b.get("decision") if b.get("decision") != null else ""
		var was_dec: String = pv.get("decision", "")
		if dec != was_dec:
			var decs: Array = m.get_or_add("decisions", [])
			decs.append([snappedf(t, 0.01), dec])
			_note("decision", "%s: %s" % [m.id, dec])
			if was_dec.begins_with("go round on you"):
				var ok := dec.begins_with("behind cover")
				m[("flanks_made" if ok else "flanks_failed")] = int(m.get("flanks_made" if ok else "flanks_failed", 0)) + 1
			if was_dec.begins_with("look for you"):
				var found := dec.begins_with("fight: sees you")
				m[("searches_found" if found else "searches_failed")] = int(m.get("searches_found" if found else "searches_failed", 0)) + 1
			pv.decision = dec
		# His line to you, ten times a second (for the unfair check).
		if Engine.get_physics_frames() % 6 == gang_ids.find(m.id) and _in_sight(b, player):
			m._line_t = t
		if b.tactic == OutlawBrain.Tactic.MOVING and b._stuck > 0.3:
			m.stuck_s = snappedf(float(m.get("stuck_s", 0.0)) + _delta, 0.001)
		# Where his fear came from: each rise put down to what happened to him this tick or the
		# last (a ball into him, one past him, a friend out of it, a friend's shout), else his
		# pain, shock and bleeding (his fear's floor) and the like.
		var df: float = b.fear - float(pv.get("fear", b.fear))
		if df > 0.0005:
			var why: String = _fear_why.get(m.id, ["", -9])[0] if Engine.get_physics_frames() - int(_fear_why.get(m.id, ["", -9])[1]) <= 1 else "pain, shock, bleeding"
			var ledger: Dictionary = m.get_or_add("fear_from", {})
			ledger[why] = snappedf(float(ledger.get(why, 0.0)) + df, 0.001)
		pv.fear = b.fear
		if b._pending_break != &"" and not pv.has("pending"):
			pv.pending = String(b._pending_break)
		if b.mood in [OutlawBrain.Mood.SURRENDERED, OutlawBrain.Mood.FLEEING] and not m.has("quit"):
			m.quit = {"t": snappedf(t, 0.01), "how": "surrendered" if b.mood == OutlawBrain.Mood.SURRENDERED else "fled",
				"following": pv.get("pending", ""), "fear": snappedf(b.fear, 0.01), "nerve": b.nerve, "hits": m.hits_taken,
				"fear_from": (m.get("fear_from", {}) as Dictionary).duplicate(), "was": pv.get("was", {})}
		pv.was = {"tactic": String(OutlawBrain.Tactic.keys()[b.tactic]).to_lower(), "searching": b._search != null,
			"cover": not b.cover.is_empty(), "prone": man.prone, "gun": man.held_gun != null, "shaken": shaken}
		# Why he's in the open while fighting: looking for cover, found none, or neither (seconds).
		if b.tactic == OutlawBrain.Tactic.OPEN and b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING] and not man.limp:
			var why := "open_searching" if b._search != null else ("open_prone" if man.prone else "open_waiting")
			m[why] = snappedf(float(m.get(why, 0.0)) + _delta, 0.001)
		if pv.get("searching", false) and b._search == null and b.tactic == OutlawBrain.Tactic.OPEN:
			m["searches_empty"] = int(m.get("searches_empty", 0)) + 1
		pv["searching"] = b._search != null
		if m.out_at < 0.0:
			if not man.physiology.alive:
				_out(man, "dead", "dead")
			elif man.limp:
				_out(man, "down", "down")
			elif b.mood == OutlawBrain.Mood.SURRENDERED:
				_out(man, "surrendered", "gave up")
			elif b.mood == OutlawBrain.Mood.FLEEING and (man.global_position.distance_to(player.global_position) > 25.0 or _since_mood(m) > 4.0):
				_out(man, "fled", "fled")
			elif b.mood == OutlawBrain.Mood.CALM and _since_mood(m) > 3.0 and _turned and t - _turned_at > 3.0:
				_out(man, "broke_off", "lost you and gave it up")
		elif m.outcome in ["down", "fled", "broke_off"]:
			# Down but he came round, or back after running: still a man to watch, so it's not over.
			if man.physiology.alive and not man.limp and b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING]:
				m.outcome = "standing"
				m.out_at = -1.0
				_note("back", "%s is back in it" % m.id)
			elif m.outcome == "down" and not man.physiology.alive:
				m.outcome = "dead"
			elif m.outcome == "down" and b.mood == OutlawBrain.Mood.SURRENDERED:
				m.outcome = "surrendered"


func _since_mood(m: Dictionary) -> float:
	return t - float((m.moods as Array)[-1][0]) if not (m.moods as Array).is_empty() else t


func _out(man: HumanBody, outcome: String, words: String) -> void:
	_out_id(_mid(man), outcome, words)


func _out_id(id: String, outcome: String, words: String) -> void:
	var m: Dictionary = _men[id]
	m.outcome = outcome
	m.out_at = snappedf(t, 0.01)
	_note("out", "%s is out of it: %s" % [m.id, words])


func _watch_world(delta: float) -> void:
	for l: Array in _lamps:
		var lamp := l[0] as OilLamp
		if is_instance_valid(lamp) and lamp.broken and not l[1]:
			l[1] = true
			_sit_add("lamps_hit", "a lamp smashed (%s)" % String(lamp.name))
	_fire_check -= delta
	if _fire_check <= 0.0:
		_fire_check = 0.5
		var fire := FireSystem.find(get_tree())
		var n := fire.burning_members().size() if fire else 0
		if n > 0 and _fire_max == 0:
			_sit_add("fires_started", "fire: %d pieces of timber alight" % n)
		_fire_max = maxi(_fire_max, n)


func _sample() -> void:
	var row := {"t": snappedf(t, 0.1), "you": [snappedf(player.global_position.x, 0.01), snappedf(player.global_position.z, 0.01), player.is_crouching]}
	var men := {}
	for man: HumanBody in _live():
		if is_instance_valid(man):
			var b := brains[_mid(man)] as OutlawBrain
			men[_men[_mid(man)].id] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.z, 0.01),
				OutlawBrain.Tactic.keys()[b.tactic].to_lower(), OutlawBrain.Mood.keys()[b.mood].to_lower(), man.pose]
	row["men"] = men
	_track.append(row)


func _check_end() -> void:
	var ph := player.wounds.physiology
	var why := ""
	if not ph.is_conscious():
		why = "you_dead" if not ph.alive else "you_down"
	elif gang_ids.all(func(id: String) -> bool: return float(_men[id].out_at) >= 0.0):
		why = "gang_out"
	elif t - (float(_shots[-1]) if not _shots.is_empty() else 0.0) > LULL:
		why = "lull"
	elif t >= float(opts.max):
		why = "timeout"
	if why != "":
		_finish(why)


# -- What happened (the game's own events) --------------------------------------------------------

func _hook_events() -> void:
	_hook(Events.shot_fired, _on_shot)
	_hook(Events.bullet_hit, _on_bullet_hit)
	_hook(Events.near_miss, _on_near_miss)
	_hook(Events.callout, _on_callout)
	_hook(Events.member_broken, _on_member_broken)
	_hook(Events.hat_shot, func(p: Node, s: Node, _at: Vector3) -> void: _sit_add("hats_shot", "%s shot %s's hat off" % [_who(s), _who(p)]))
	for sig: Signal in [Events.person_fell, Events.person_surrendered]:
		_hook(sig, func(p: Node, _x: Variant = null) -> void: _friend_out(p))
	_hook(Events.person_died, func(p: Node, _c: StringName) -> void: _friend_out(p))
	_hook(Events.person_surrendered, func(p: Node) -> void:
		if p in gang:
			_sit_add("surrenders", "%s gives up" % _who(p)))
	_hook(Events.person_died, func(p: Node, cause: StringName) -> void: _note("died", "%s died (%s)" % [_who(p), cause]))
	_hook(Events.person_fell, func(p: Node, conscious: bool) -> void: _note("fell", "%s went down%s" % [_who(p), "" if conscious else ", out cold"]))
	_hook(Events.spoke, func(p: Node, text: String) -> void:
		if p in gang:
			_note("said", "%s: \"%s\"" % [_who(p), text]))


func _hook(sig: Signal, f: Callable) -> void:
	sig.connect(f)
	_hooks.append([sig, f])


func _unhook() -> void:
	for h: Array in _hooks:
		if (h[0] as Signal).is_connected(h[1]):
			(h[0] as Signal).disconnect(h[1])
	_hooks.clear()


func _on_shot(_origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	if not started or done:
		return
	_shots.append(t)
	var who := _who(shooter)
	if _first.is_empty():
		_first["shot_by"] = who
		_first["shot_at"] = snappedf(t, 0.01)
	if shooter == player:
		_you.shots = int(_you.get("shots", 0)) + 1
	elif shooter in gang:
		var m: Dictionary = _men[_mid(shooter)]
		m.shots += 1
		var b := brains[_mid(shooter)] as OutlawBrain
		if b.covering > 0.0 or not b.senses.sees(player):
			m.suppressing_shots += 1
		elif t - float(m.get("_line_t", 0.0)) > NO_LINE:
			# He "sees" you, and fires, with no clear line from his eyes to any of you: unfair.
			_unfair(m, "%s fired at you with no line to you for %.1f s" % [m.id, t - float(m.get("_line_t", 0.0))])
		# How far off his barrel was from where he meant it (degrees), at what range, at your head
		# or your chest: why he hit or missed.
		if b.hand != null and b._find_target() != null:
			var want: Vector3 = b._want_dir(_origin, b._find_target())
			if not m.has("shot_errors"):
				m["shot_errors"] = []
			(m.shot_errors as Array).append([snappedf(t, 0.01), snappedf(rad_to_deg(_dir.angle_to(want)), 0.01),
				snappedf(_origin.distance_to(player.global_position), 0.1), b._aim_head, snappedf(b.fear, 0.01)])
	_note("shot", "%s fired" % who)


func _on_bullet_hit(info: Dictionary) -> void:
	if not started or done:
		return
	var person: Variant = info.get("person")
	var shooter: Variant = info.get("shooter")
	if person != null and info.get("hat", false):
		return
	if person != null:
		var victim: Node = (person as PlayerWounds).player if person is PlayerWounds else person
		var key := "%s@%d" % [_who(shooter), Engine.get_physics_frames()]
		var first_of_charge := not _hit_frames.has(key)
		_hit_frames[key] = true
		if victim == player:
			if first_of_charge:
				_you.hits_taken = int(_you.get("hits_taken", 0)) + 1
				if not _you.has("first_hit_at"):
					_you.first_hit_at = snappedf(t, 0.01)
				if shooter in gang:
					_men[_mid(shooter)].hits_on_you += 1
				_first_hit("gang")
			_note("hit", "you hit in the %s by %s" % [info.get("segment", "?"), _who(shooter)])
		elif victim in gang:
			_men[_mid(victim)].hits_taken += 1
			_fright(victim, "hit")
			if shooter == player:
				_you.pellet_hits = int(_you.get("pellet_hits", 0)) + 1
				if first_of_charge:
					_you.hits = int(_you.get("hits", 0)) + 1
					_first_hit("you")
			elif shooter in gang:
				_men[_mid(victim)].friendly_hits += 1
			_note("hit", "%s hit in the %s by %s" % [_who(victim), info.get("segment", "?"), _who(shooter)])
		else:
			_sit_add("townsfolk_hit", "%s hit by %s" % [_who(victim), _who(shooter)])
		return
	# (Ballistics names the shooter only on a hit on a man: anything else is everyone's.)
	if info.get("collider") is StructureMember or info.get("collider") is CharacterBody3D:
		return
	# Into the ground (or anything that isn't timber or a man): dust where it struck.
	var at: Vector3 = info.position
	_sit["ground_hits"] = int(_sit.get("ground_hits", 0)) + 1
	for man: HumanBody in _live():
		if float(_men[_mid(man)].out_at) < 0.0 and Vector2(at.x - man.global_position.x, at.z - man.global_position.z).length() < DUST_NEAR:
			_sit_add("dust_by_man", "dust kicked up round %s" % _who(man))
			break
	var eye := player.camera.global_position
	for man: HumanBody in _live():
		if not is_instance_valid(man) or float(_men[_mid(man)].out_at) >= 0.0:
			continue
		var chest := (man.parts[&"chest"] as Node3D).global_position
		var seg := chest - eye
		var u := clampf((at - eye).dot(seg) / seg.length_squared(), 0.0, 1.0)
		if u > 0.1 and u < 0.97 and (eye + seg * u).distance_to(at) < DUST_LINE:
			_sit_add("dust_on_line", "dust thrown up between you and %s" % _who(man))
			break


func _on_near_miss(person: Node, shooter: Node, dist: float, _at: Vector3, _speed: float, _tumbling: bool) -> void:
	if not started or done:
		return
	if person == player:
		_you.near_misses = int(_you.get("near_misses", 0)) + 1
		_note("near_miss", "a round from %s passed %.1f m from you" % [_who(shooter), dist])
	elif person in gang:
		_men[_mid(person)].near_misses_on_him += 1
		_fright(person, "near miss")


## A clear line from his eyes to your head, chest or hips (the scenery only, nobody's body).
func _in_sight(b: OutlawBrain, who: Player) -> bool:
	var space := who.get_world_3d().direct_space_state
	var eye: Vector3 = b.senses.eye()
	for to in [who.camera.global_position, who.global_position + Vector3.UP * 1.2, who.global_position + Vector3.UP * 0.6]:
		var q := PhysicsRayQueryParameters3D.create(eye, to, Layers.WORLD)
		q.exclude = [who.get_rid()]
		var hit := space.intersect_ray(q)
		if hit.is_empty() or (hit.position as Vector3).distance_to(to) < 0.2:
			return true
	return false


func _unfair(m: Dictionary, text: String) -> void:
	var list: Array = record.get_or_add("unfair", [])
	list.append([snappedf(t, 0.01), text])
	m.unfair = int(m.get("unfair", 0)) + 1
	_note("unfair", text)


## Something that frightens him (for the fear ledger). Several in one tick: the strongest is
## named (a ball into him over one past him over a friend out of it over a friend's shout).
func _fright(man: Node, why: String) -> void:
	if not man in gang:
		return
	var frame := Engine.get_physics_frames()
	var was: Array = _fear_why.get(_mid(man), ["", -9])
	if int(was[1]) == frame and _FRIGHTS.find(String(was[0]).get_slice(" (", 0)) <= _FRIGHTS.find(why.get_slice(" (", 0)):
		return
	_fear_why[_mid(man)] = [why, frame]


## A friend out of it: it frightens the rest.
func _friend_out(p: Node) -> void:
	if p in gang:
		for other in _live():
			if other != p:
				_fright(other, "a friend down or quit")


func _about_you(n: Node) -> bool:
	return n == player


func _on_callout(speaker: Node, kind: StringName, _about: Node, _at: Vector3) -> void:
	if not started or done or not speaker in gang:
		return
	if kind in [&"fall_back", &"give_up", &"quit", &"down", &"dead"]:
		for other in _live():
			if other != speaker:
				_fright(other, "a friend's shout (%s)" % kind)
	var m: Dictionary = _men[_mid(speaker)]
	m.callouts[String(kind)] = int(m.callouts.get(String(kind), 0)) + 1
	if kind == &"spotted" and _about_you(_about) and t - float(m.get("_line_t", 0.0)) > NO_LINE:
		_unfair(m, "%s called he'd spotted you with no line to you for %.1f s" % [m.id, t - float(m.get("_line_t", 0.0))])
	if kind == &"flank":
		m.flanks += 1
	_note("callout", "%s called %s" % [m.id, kind])


func _on_member_broken(id: StringName) -> void:
	if not started or done or not _members.has(id):
		return
	var at := Vector3.INF
	for m: StructureMember in _members[id]:
		if is_instance_valid(m):
			at = m.world_aabb().get_center()
	if at == Vector3.INF:
		return
	_sit["members_broken"] = int(_sit.get("members_broken", 0)) + 1
	for man: HumanBody in _live():
		if not is_instance_valid(man):
			continue
		var b := brains[_mid(man)] as OutlawBrain
		if b.tactic in [OutlawBrain.Tactic.HIDDEN, OutlawBrain.Tactic.PEEKING] and b.cover.has("at") \
				and Vector2(at.x - b.cover.at.x, at.z - b.cover.at.z).length() < COVER_NEAR:
			_sit_add("cover_shot_away", "%s's cover broken (%s)" % [_men[_mid(man)].id, id], 1.0)
			return
	if Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length() < COVER_NEAR:
		_sit_add("cover_shot_away", "your cover broken (%s)" % id, 1.0)


func _first_hit(side: String) -> void:
	if not _first.has("hit_by"):
		_first["hit_by"] = side
		_first["hit_at"] = snappedf(t, 0.01)


## A situation change, counted once per `apart` seconds of its kind (a burst of splinters is one).
func _sit_add(kind: String, text: String, apart := 0.0) -> void:
	var list: Array = _sit.get(kind, [])
	if apart > 0.0 and not list.is_empty() and t - float(list[-1]) < apart:
		return
	list.append(snappedf(t, 0.1))
	_sit[kind] = list
	_note("situation", text)


func _note(kind: String, text: String) -> void:
	_timeline.append([snappedf(t, 0.01), kind, text])


func _who(n: Variant) -> String:
	if n == null or not is_instance_valid(n):
		return "someone"
	if n == player or n is PlayerWounds:
		return "you"
	if n is HumanBody:
		return String((n as HumanBody).person_id)
	return String((n as Node).name)


# -- The end --------------------------------------------------------------------------------------

func _finish(why: String) -> void:
	done = true
	if bot:
		bot.teardown()
	_unhook()
	var ph := player.wounds.physiology
	var clock := street.find_child("DayCycle", true, false) as DayCycle
	record["hour_at_end"] = snappedf(clock.time_of_day, 0.01)
	var outcomes := {}
	for id in gang_ids:
		var m: Dictionary = _men[id]
		m.erase("_cover")
		m.erase("_line_t")
		outcomes[m.outcome] = int(outcomes.get(m.outcome, 0)) + 1
	var ending := why
	if why == "gang_out":
		# How the last of them went.
		var last: Dictionary = {}
		for id in gang_ids:
			if last.is_empty() or float(_men[id].out_at) > float(last.out_at):
				last = _men[id]
		ending = "all_dead" if outcomes.get("dead", 0) == gang.size() else String(last.outcome)
	var shots: Array = [0.0] + _shots + [t]
	var quiet := 0.0
	var quiet_from := 0.0
	for i in range(1, shots.size()):
		if float(shots[i]) - float(shots[i - 1]) > quiet:
			quiet = float(shots[i]) - float(shots[i - 1])
			quiet_from = float(shots[i - 1])
	var gang_shots := 0
	var gang_hits := 0
	for id in gang_ids:
		gang_shots += int(_men[id].shots)
		gang_hits += int(_men[id].hits_on_you)
	var minutes := maxf(t / 60.0, 1.0 / 60.0)
	var you := {"down": not ph.is_conscious(), "dead": not ph.alive, "blood_ml": int(ph.blood_ml), "wounds": ph.wounds,
		"shots": int(_you.get("shots", 0)), "hits": int(_you.get("hits", 0)), "pellet_hits": int(_you.get("pellet_hits", 0)),
		"hits_taken": int(_you.get("hits_taken", 0)), "first_hit_at": _you.get("first_hit_at", -1.0),
		"near_misses": int(_you.get("near_misses", 0)), "near_misses_per_min": snappedf(float(_you.get("near_misses", 0)) / minutes, 0.1)}
	if bot:
		you.merge(bot.stats)
	else:
		you.merge({"relocations": int(_you.get("relocations", 0)), "crouched_s": snappedf(float(_you.get("crouched_s", 0.0)), 0.1)})
	var sit := {}
	for k: String in ["cover_shot_away", "lamps_hit", "fires_started", "dust_on_line", "dust_by_man", "surrenders", "flights", "hats_shot", "townsfolk_hit", "shaken", "rallied"]:
		sit[k] = (_sit.get(k, []) as Array).size()
	sit["members_broken"] = int(_sit.get("members_broken", 0))
	sit["ground_hits"] = int(_sit.get("ground_hits", 0))
	sit["most_timber_alight"] = _fire_max
	sit["times"] = {}
	for k: String in _sit:
		if _sit[k] is Array:
			sit.times[k] = _sit[k]
	var men := {}
	for id in gang_ids:
		men[id] = _men[id]
	record.merge({
		"variant": String(opts.get("variant", "C")), "scenario": opts.scenario, "hour": opts.hour, "weapon": opts.weapon, "style": opts.style, "bodies": opts.bodies,
		"seed": int(opts.seed), "aim_sd": float(opts.get("aim", 1.0)), "length_s": snappedf(t, 0.01), "end": why, "ending": ending, "outcomes": outcomes,
		"first_shot_by": _first.get("shot_by", "none"), "first_shot_at": _first.get("shot_at", -1.0),
		"first_hit_by": _first.get("hit_by", "none"), "first_hit_at": _first.get("hit_at", -1.0),
		"you": you, "gang": {"shots": gang_shots, "hits_on_you": gang_hits}, "men": men, "situations": sit,
		"longest_quiet_s": snappedf(quiet, 0.01), "longest_quiet_from": snappedf(quiet_from, 0.01),
		"perf": _perf(), "timeline": _timeline, "track": _track})
	Prof.on = false
	if _shoot_dir != "":
		_capture.call_deferred("t%05.1f" % t)
	if not human:  # (you playing: they carry on as they were)
		for man: HumanBody in _live():
			(brains[_mid(man)] as OutlawBrain).set_physics_process(false)


func _prof_delta() -> Dictionary:
	var now: Dictionary = Prof._sum
	var out := {}
	for k: StringName in now:
		var v := int(now[k])
		var was := int(_prof_last.get(k, 0))
		out[k] = float(v - was if v >= was else v) / 1000.0
	_prof_last = now.duplicate()
	return out


## What the frame cost: each Prof timer a frame in the fight, the people's share against the second
## before the gang came (two townsfolk and you), and the whole physics frame's wall time (headless:
## no drawing; this workspace's core, x0.65 for Sean's, CLAUDE.md).
func _perf() -> Dictionary:
	var n := maxf(_fight_frames, 1)
	var per := {}
	var people := 0.0
	var calm := 0.0
	for k: StringName in _prof_fight:
		per[String(k)] = snappedf(float(_prof_fight[k]) / n, 0.001)
		if k in PEOPLE:
			people += float(_prof_fight[k]) / n
	for k: StringName in _prof_calm:
		if k in PEOPLE:
			calm += float(_prof_calm[k]) / maxf(_calm_frames, 1)
	var pf := _people_frames.duplicate()
	pf.sort()
	var fu := _frame_us.duplicate()
	fu.sort()
	return {"frames": _fight_frames, "per_system_ms": per, "people_ms": snappedf(people, 0.001), "people_calm_ms": snappedf(calm, 0.001),
		"three_men_ms": snappedf(people - calm, 0.001), "people_p95_ms": snappedf(float(pf[int(pf.size() * 0.95)]) if not pf.is_empty() else 0.0, 0.001),
		"frame_ms": snappedf(_mean(fu) / 1000.0, 0.01), "frame_p95_ms": snappedf(float(fu[int(fu.size() * 0.95)]) / 1000.0 if not fu.is_empty() else 0.0, 0.01)}


func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(a.size(), 1)


# -- Pictures (drawn runs only) -------------------------------------------------------------------

## Two frames now: your eyes and the scenario's overview camera, into the shots folder.
func _capture(tag: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	capturing += 1
	DirAccess.make_dir_recursive_absolute(_shoot_dir)
	RenderingServer.render_loop_enabled = true
	for i in DRAW_SETTLE:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shoot_dir.path_join("%s_you.png" % tag))
	if _overview == null:
		_overview = Camera3D.new()
		_overview.name = "GunfightOverview"
		street.add_child(_overview)
		_overview.attributes = player.camera.attributes
		_overview.cull_mask = player.camera.cull_mask
		_overview.far = player.camera.far
		_overview.global_position = _v(scen.camera.at)
		_overview.look_at(_v(scen.camera.look))
		_overview.fov = 60.0
	_overview.make_current()
	for i in DRAW_SETTLE:
		await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_shoot_dir.path_join("%s_over.png" % tag))
	# Where each man and you are in the overview (fractions of the frame), for the sheet's labels.
	var marks := {}
	var vp := _overview.get_viewport().get_visible_rect().size
	var heads := {"you": player.camera.global_position}
	for man: HumanBody in _live():
		heads[_mid(man)] = (man.parts[&"head"] as Node3D).global_position if man.parts.has(&"head") else man.global_position + Vector3.UP * 1.7
	for k: String in heads:
		var w: Vector3 = heads[k] + Vector3.UP * 0.35
		if not _overview.is_position_behind(w):
			var sp := _overview.unproject_position(w)
			marks[k] = [snappedf(sp.x / vp.x, 0.001), snappedf(sp.y / vp.y, 0.001)]
	var f := FileAccess.open(_shoot_dir.path_join("%s_marks.json" % tag), FileAccess.WRITE)
	f.store_string(JSON.stringify(marks))
	f.close()
	player.camera.make_current()
	if not done:
		RenderingServer.render_loop_enabled = false
	capturing -= 1


## The men still in the world (a man who rode out of town is freed).
func _live() -> Array:
	return gang.filter(func(n: Variant) -> bool: return is_instance_valid(n))


## A man's id from his node (freed or not), "" if he isn't one of them.
func _mid(n: Variant) -> String:
	var i := gang.find(n)
	return gang_ids[i] if i >= 0 else ""


func _v(a: Array) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))


func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]
