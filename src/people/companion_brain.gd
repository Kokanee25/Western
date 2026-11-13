class_name CompanionBrain
extends OutlawBrain
## A man on your side: Joe, the only full companion (DESIGN.md; No Justice step 1, #843). The gang's
## own brain, variant D with the trial's fixes (the gunfight lab's "D+"), turned round:
## - he walks with you at a sensible distance, behind and to one side, and waits when told (G with
##   him in the middle of your view: `told`), or comes;
## - your fights are his: whoever shoots at you, draws on you, or you shoot at, he fights; and the men
##   who fight you fight him (OutlawBrain `_start_fight`'s `allies_of`);
## - he takes cover and fights as they do, but never gives up or runs: past his nerve he goes to ground;
## - he calls what he sees (a man you can't see, one loading, one going round, one down), in short
##   lines in his own voice (`config/companion_joe.json`), subtitled;
## - he doesn't take your man: not the one in your sights, nor one you've just hit, unless that man's
##   on him; and he steps out of your line of fire;
## - he can't die of an ordinary wound (`Physiology.spared`): a killing wound puts him down, out
##   cold while the fight's on, and he comes to and gets up after it. The rope turns `spared` off.
## Your deeds are never against him: a gun on him, a shout, a stray ball are a friend's.

const DATA := "res://config/companion_joe.json"
## The men who fight you take on your companions this near them (m).
const ALLY_REACH := 60.0
## A fight is on while a man this near (m) is fighting.
const FIGHT_NEAR := 80.0
## "D+": variant D and the trial fixes (experiments/gunfight_lab/play.gd TRIAL).
const PLUS := [&"pain_fight", &"floor_fight", &"odds", &"flinch"]

## Who he follows and fights for (the player).
var leader: Node3D
## Told to wait: where he waits (INF: following).
var wait_at := Vector3.INF
var data := {}
var tune := {}
## What a lab reads (the gunfight lab's `joe=1`): seconds in your line of fire, how often he held fire
## on your man, his calls, how often he stepped out of your line.
var stats := {"line_s": 0.0, "held_fire": 0, "calls": 0, "line_steps": 0, "downs": 0, "out_cold_s": 0.0}

var _side := 1.0  # which side of you he walks (+1 right)
var _line_t := 0.0
var _line_step := 0.0
var _line_to := Vector3.INF
var _called := {}  # kind -> {who: time}
var _call_at := -99.0
var _fight_seen := false  # there's been a fight since he was last calm
var _fight_check := 0.0
var _fight_on := false
var _calm_t := 0.0
var _down_hard := false  # out cold from a wound that would have killed him
var _spared_seen := 0
var _spared_set := false
var _yours_hit := {}  # man -> when you last hit him
var _yours_shot := {}  # man -> when you last shot at him
var _line_fails := 0  # steps aside that left him still in your line
var _tend_t := 0.0  # this bout of tending his wound (s)
var _tend_end := -99.0
var _brain_said := {}  # the gang brain's moments: kind -> when he last said it
var _prone_up := 0.0  # getting up off his belly after the fight (s left kneeling)
var _said_cant_stand := false
var _said_up := true  # (set false when he goes down)
var _stuck_t := 0.0
var _go_last := Vector3.INF
var _way: Array[Vector3] = []
## Held by a scene (No Justice's camp, `NoJusticeCamp`): while it's quiet the scene walks him and
## turns him, not his following; in a fight he's his own man again.
var held := false
## In the cowboy's hat and neckerchief (S12, No Justice step 2; his look is the Studio's).
var costume := false


static var _shared := {}


static func load_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))


func _init() -> void:
	data = load_data()
	tune = (data.tuning as Dictionary).duplicate()
	_lab_tune(tune)
	variant = Variant.D
	nerve = float(tune.nerve)
	temper = float(tune.temper)
	seconds_between_shots = float(tune.seconds_between_shots)


func _ready() -> void:
	super._ready()
	body.add_to_group(&"companions")
	if leader:
		relations.friend_nodes = [leader]
	_side = 1.0 if _rng.randf() < 0.5 else -1.0
	body.hit.connect(_on_my_hit)
	Events.person_fell.connect(func(who: Node, _c: bool) -> void: _enemy_out(who, &"down"))
	Events.person_died.connect(func(who: Node, _c: StringName) -> void: _enemy_out(who, &"down"))
	Events.person_surrendered.connect(func(who: Node) -> void: _enemy_out(who, &"quit"))
	Events.bullet_hit.connect(_on_any_hit)


## Follow this man and fight for him.
func follow_man(who: Node3D) -> void:
	leader = who
	if relations:
		relations.friend_nodes = [who]


# --- Bringing him in ---------------------------------------------------------------------------

## The stand-in's body until the Studio makes Joe (his own clothes and the cowboy costume, #843).
const STAND_IN := &"miner_s4_talking"


## `-- --joe`: Joe beside you from the start (the town or the valley), to walk and fight with.
static func maybe_start(main_node: Node) -> void:
	if not "--joe" in OS.get_cmdline_user_args():
		return
	_start_when_ready.call_deferred(main_node)


static func _start_when_ready(main_node: Node) -> void:
	var tree := main_node.get_tree()
	for i in 600:
		var p := tree.get_first_node_in_group(&"player") as Player
		if p != null and p.is_inside_tree() and p.get_parent() != null:
			for j in 30:
				await tree.physics_frame  # the world settles under you first
			spawn_beside(p)
			return
		await tree.physics_frame


## Joe brought in beside you (2.2 m to your right, a pace back), following you. Returns him.
static func spawn_beside(p: Player, model := STAND_IN) -> HumanBody:
	var town := p.get_parent().get_node_or_null(^"TownLife") as TownLife
	var at := p.global_position + p.global_transform.basis * Vector3(2.2, 0.0, 0.8)
	return make_joe(p.get_parent(), at, p.rotation.y, p, town.places if town else null, model)


## Joe into `parent` at `at` facing `yaw`, following `leader` (a scene's: `held` to hold him there).
static func make_joe(parent: Node, at: Vector3, yaw: float, leader: Node3D, ways: Waypoints = null,
		model := STAND_IN, hold_him := false) -> HumanBody:
	var man := HumanBody.new()
	man.name = "Joe"
	man.person_id = &"joe"
	man.body_model = model
	man.shirt_color = Color(0.55, 0.5, 0.4)
	var b := CompanionBrain.new()
	b.name = "Brain"
	b.follow_man(leader)
	b.held = hold_him
	if ways != null:
		b.places = ways
	man.add_child(b)
	man.enter(parent, at, yaw)
	return man


## The gunfight lab's trials (#859): `-- --joe-tune=key:value+key:value` sets his tuning's numbers
## for this game (a fight's run: `run.py --game-args=--joe-tune=yours_after_shot:3`).
static func _lab_tune(into: Dictionary) -> void:
	for a: String in OS.get_cmdline_user_args():
		if not a.begins_with("--joe-tune="):
			continue
		for kv: String in a.get_slice("=", 1).split("+", false):
			if kv.contains(":"):
				into[kv.get_slice(":", 0)] = float(kv.get_slice(":", 1))


# --- Who's with whom --------------------------------------------------------------------------

## The man's companions, or a companion's man and the others with him: whoever is in a fight with
## `who` is in it with them too.
static func allies_of(who: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if who == null or not is_instance_valid(who) or not who.is_inside_tree():
		return out
	var lead: Node = who
	var mine := who.get_node_or_null(^"Brain") as CompanionBrain if who is HumanBody else null
	if mine != null:
		lead = mine.leader
		if lead != null and is_instance_valid(lead):
			out.append(lead as Node3D)
	if lead == null or not is_instance_valid(lead):
		return out
	for n: Node in who.get_tree().get_nodes_in_group(&"companions"):
		var b := n.get_node_or_null(^"Brain") as CompanionBrain
		if n != who and b != null and b.leader == lead and (n as HumanBody).physiology.alive:
			out.append(n as Node3D)
	return out


## The companion in the middle of your view (within reach), nearer than anyone else there: who a
## word from you is for. Null if none.
static func in_view(player: Player, reach := -1.0, deg := -1.0) -> CompanionBrain:
	if player == null or not player.is_inside_tree():
		return null
	if _shared.is_empty():
		_shared = load_data()
	reach = float(_shared.tuning.order_reach) if reach < 0.0 else reach
	deg = float(_shared.tuning.order_deg) if deg < 0.0 else deg
	var cam := player.camera
	var fwd := -cam.global_transform.basis.z
	var best: CompanionBrain = null
	var best_d := INF
	for n: Node in player.get_tree().get_nodes_in_group(&"people"):
		var h := n as HumanBody
		if h == null or not h.physiology.is_conscious():
			continue
		var to := h.global_position + Vector3.UP * 1.2 - cam.global_position
		var d := to.length()
		if d > reach or rad_to_deg(fwd.angle_to(to)) > deg or d >= best_d:
			continue
		best_d = d
		best = h.get_node_or_null(^"Brain") as CompanionBrain
	return best


## A word from you (the shout key with him in view): wait here, or come on. Returns what you said.
func told(by: Node3D) -> String:
	if by != leader or held:
		return ""
	if wait_at == Vector3.INF:
		wait_at = body.global_position
		_say_line(&"wait", true)
		return "\"Wait here.\""
	wait_at = Vector3.INF
	_say_line(&"come", true)
	return "\"Come on.\""


# --- Never against you ------------------------------------------------------------------------

func _provoked(by: Node) -> void:
	if by == leader:
		return
	super._provoked(by)


func _on_deed(actor: Node, kind: StringName, deed_target: Node, at: Vector3) -> void:
	if actor == leader:
		if kind == &"shoot_at" and deed_target is Node and deed_target != body:
			_yours_shot[deed_target] = _now
		if kind in [&"shoot_at", &"hit", &"kill"] and deed_target is HumanBody and deed_target != body \
				and _armed_man(deed_target) and body.physiology.is_conscious():
			relations.side_with(deed_target)  # you started it: it's his fight
			senses.note(deed_target, (deed_target as Node3D).global_position, 1.0)
		elif kind == &"aim_at" and deed_target == body and _now - _call_at > 8.0 and mood == Mood.CALM:
			_say_line(&"not_me")
		return
	super._on_deed(actor, kind, deed_target, at)
	if deed_target == leader and kind in [&"shoot_at", &"hit", &"kill"] and _armed_man(actor):
		relations.side_with(actor)  # whoever shoots at you, he fights


func _on_spotted(who: Node3D) -> void:
	if who == leader:
		return
	super._on_spotted(who)


func _on_shouted(speaker: Node, kind: StringName) -> void:
	if speaker == leader:
		return  # "Drop it!" is to them, not to him
	super._on_shouted(speaker, kind)


func _update_aimed_at(_delta: float) -> void:
	_aimed_at = 0.0  # your gun on him frightens him not at all


## A man with a fighting brain and a gun (not a townsman your stray ball went near, not one of yours).
func _armed_man(who: Node) -> bool:
	if not _enemy_kind(who) or who == body:
		return false
	var b := Crew.brain_of(who)
	return b != null and (who as HumanBody).held_gun != null and (who as HumanBody).physiology.is_conscious()


## Someone the player's in a fight with (not another companion, not the player).
func _enemy_kind(who: Node) -> bool:
	if who == null or not is_instance_valid(who) or who == leader or not who is HumanBody:
		return false
	return not ((who as Node).get_node_or_null(^"Brain") is CompanionBrain)


# --- How he fights ----------------------------------------------------------------------------

func _has(fix: StringName) -> bool:
	return fix in OutlawBrain.D_FIXES or fix in PLUS


## Never gives up, never runs: past his nerve he goes to ground where he is, takes stock and is back
## in it (the gang's `odds`, held).
func _surrender() -> void:
	_go_to_ground("past his nerve: down behind something, not giving up")


func _start_fleeing() -> void:
	_go_to_ground("past his nerve: not running off and leaving you")


func _go_to_ground(why: String) -> void:
	_decide("go to ground", why)
	fear = minf(fear, nerve * 0.6)
	fright = 0.0
	_hold_break = 6.0
	if not body.prone and not body.limp:
		body.set_pose(&"crouch")
		tactic = Tactic.OPEN
		_cover_search = 0.0


## His wound: not on his knees in the open while it's on, unless it's pumping, and then a bout at
## most `TEND_FIGHT` s (the playtest: three minutes tending in the open with Brody shooting).
const TEND_FIGHT := 12.0
const TEND_AGAIN := 20.0
const TEND_FAST := 3.0


func _wants_to_tend() -> bool:
	if _now - _tend_end < TEND_AGAIN:
		return false
	if _fight_on and body.physiology.total_bleed_rate() < float(tune.get("tend_fast", TEND_FAST)):
		return false
	return super._wants_to_tend()


func _tend(delta: float) -> void:
	_tend_t += delta
	if _fight_on and _tend_t > TEND_FIGHT:
		_release_pressure()
		_tend_end = _now
		_tend_t = 0.0
		_set_mood(Mood.FIGHTING)
		tactic = Tactic.OPEN
		_cover_search = 0.0
		_decide("back in it", "tended %.0f s; it'll hold" % TEND_FIGHT)
		return
	super._tend(delta)
	if mood != Mood.TENDING:
		_tend_end = _now
		_tend_t = 0.0


func _after_fight() -> void:
	_stand_and_fight = false
	duel_with = null
	_stop_rescue()
	covering = 0.0
	rage = 0.0
	agenda.clear()


func _can_go_about() -> bool:
	return false


## Who he fights: the one pressing him hardest, the one on him first, never the man in your sights or
## the one you've just hit unless that man is on him.
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
	var best_p := -INF
	for who in relations.entries.keys():
		if not is_instance_valid(who) or who == leader or relations.stance(who) != Relations.Stance.FIGHT or _done_with(who):
			continue
		if not _armed_man(who) and not _on_me(who):
			continue  # (a man with no gun and no fight in him isn't his to shoot)
		var p: float = relations.entries[who].pressure + (1.0 if senses.sees(who) else 0.0) + (1.0 if who == t else 0.0) \
				+ (1.5 if _on_me(who) else 0.0) - (3.0 if yours(who) and not _on_me(who) else 1.0 if in_your_sights(who) else 0.0)
		if p > best_p:
			best = who
			best_p = p
	if best != null:
		_start_fight(best)
	elif t == null and mood != Mood.CALM:
		_set_mood(Mood.CALM)
		tactic = Tactic.OPEN
		_after_fight()


## His shot draws that man's eye: the man he shoots at minds him more (so they take him on too:
## "outlaws shoot at him too", not only at you).
func _fire_at(point: Vector3, t: Node3D) -> void:
	super._fire_at(point, t)
	var b := Crew.brain_of(t)
	if b != null and not b is CompanionBrain:
		var e := b.relations.entry(body)
		e.pressure = minf(float(e.pressure) + float(tune.get("draw_eye", DRAW_EYE)), float(tune.get("draw_eye_max", DRAW_EYE_MAX)))


## How much more a man minds Joe for each shot Joe puts at him, and at most (Relations' pressure: a
## fight is 1.0 up; the man who shot at him first stands at 1.5).
const DRAW_EYE := 0.5
const DRAW_EYE_MAX := 3.0


func _can_shoot_at(t: Node3D) -> bool:
	if yours(t) and not _on_me(t):
		stats.held_fire += 1
		return false
	return super._can_shoot_at(t)


## That man is yours to finish: you've hit him in the last few seconds, or he's hurt and in your
## sights. (A whole man in your sights Joe will still shoot at: keeping his head down is help, not
## taking him from you; he'd rather another, `_pick_fight`.)
func yours(who: Node) -> bool:
	if who == null or not is_instance_valid(who) or not who is Node3D:
		return false
	if _now - float(_yours_hit.get(who, -INF)) < float(tune.yours_after_hit) \
			or _now - float(_yours_shot.get(who, -INF)) < float(tune.yours_after_shot):
		return true  # the man you're firing at, or have just hit
	var h := who as HumanBody
	return h != null and (h.physiology.wounds > 0 or h.limp or h.prone) and in_your_sights(who)


## In your sights: your gun out and pointed within `yours_aim_deg` of him.
func in_your_sights(who: Node) -> bool:
	if who == null or not is_instance_valid(who) or not who is Node3D:
		return false
	var p := leader as Player
	if p == null or not _gun_out(p):
		return false
	var cam := p.camera
	var to := (who as Node3D).global_position + Vector3.UP * 1.2 - cam.global_position
	return rad_to_deg((-cam.global_transform.basis.z).angle_to(to)) < float(tune.yours_aim_deg)


func _on_me(who: Node) -> bool:
	var b := Crew.brain_of(who)
	return b != null and b.target == body


static func _gun_out(p: Player) -> bool:
	var w := p.weapon
	return w != null and w.armed and w.selected and w.drawn


func _on_any_hit(info: Dictionary) -> void:
	var person: Variant = info.get("person")
	var shooter: Variant = info.get("shooter")
	if shooter == leader and person != null and person != body and person is Node:
		_yours_hit[person] = _now
	elif person is PlayerWounds and (person as PlayerWounds).player == leader and shooter != null \
			and shooter != body and senses and senses.sees(leader):
		_call(&"you_hit", null, 10.0)
	elif person == body and shooter == leader and body.physiology.is_conscious():
		_call(&"your_shot", null, 6.0)


func _on_my_hit(info: Dictionary) -> void:
	if info.get("shooter") != leader and info.get("kind", &"bullet") in [&"bullet", &"graze", &"pellet"]:
		var leg := String(info.get("segment", "")).contains("thigh") or String(info.get("segment", "")).contains("shin")
		_call(&"down_leg" if leg and not body.physiology.can_stand() else &"hit", null, 5.0)


# --- His tick ---------------------------------------------------------------------------------

func _physics_step(delta: float) -> void:
	var p := body.physiology
	if not _spared_set:
		_spared_set = true
		p.spared = true  # (his body makes its physiology after the brain's ready)
	_fight_check -= delta
	if _fight_check <= 0.0:
		_fight_check = 0.5
		_fight_on = _a_fight_on()
	if p.spared_times > _spared_seen:
		_spared_seen = p.spared_times
		_down_hard = true
		_said_up = false
		stats.downs += 1
		_decide("down", "a wound that would have killed him (%s): out cold while it's on" % p.spared_cause)
	if _down_hard:
		stats.out_cold_s += delta
		if _fight_on:
			p.concussion = maxf(p.concussion, 1.0)  # he lies there till it's over
		elif p.is_conscious():
			_down_hard = false
			_say_line(&"come_to", true)
	if _fight_on:
		_fight_seen = true
		_calm_t = 0.0
	else:
		_calm_t += delta
	if mood != Mood.TENDING:
		_tend_t = 0.0
	_watch_line(delta)
	if p.is_conscious():
		_watch_fight()
	if p.alive and p.is_conscious() and not _fight_on and _calm_t > 2.0 and (body.limp or body.prone):
		_get_back_up(delta)
		return
	if _line_step > 0.0 and not body.limp and not body.prone and p.is_conscious() and body.stumbling <= 0.0:
		_step_out_of_line(delta)
		return
	super._physics_step(delta)


## Is there a fight on near him: a man (not one of yours) fighting, with a gun out?
func _a_fight_on() -> bool:
	for n: Node in get_tree().get_nodes_in_group(&"people"):
		var b := n.get_node_or_null(^"Brain") as OutlawBrain
		if b == null or b is CompanionBrain or not (n as HumanBody).physiology.is_conscious():
			continue
		if b.mood in [Mood.FIGHTING, Mood.RELOADING] and (n as Node3D).global_position.distance_to(body.global_position) < FIGHT_NEAR:
			return true
	return false


## Up after it's over: off the ground if his legs will have him; else he says so.
func _get_back_up(delta: float) -> void:
	if body.limp:
		if body.physiology.can_stand():
			if not body.rising and not _said_up:
				_said_up = true
				_say_line(&"up", true)
			body.get_up()
		elif not _said_cant_stand:
			_said_cant_stand = true
			_say_line(&"cant_stand", true)
		return
	# On his belly (fought from the floor): to a knee, then up.
	if not body.physiology.can_stand():
		if not _said_cant_stand:
			_said_cant_stand = true
			_say_line(&"cant_stand", true)
		return
	if _prone_up <= 0.0:
		_prone_up = 1.2
		body.set_pose(&"kneel")
		return
	_prone_up -= delta
	if _prone_up <= 0.0:
		body.prone = false
		body.set_pose(&"stand")


# --- Your line of fire ------------------------------------------------------------------------

## His cover is never in front of your gun: the search turns down spots in your line (the gang's
## `inside`, Cover.search's spot filter, which a house's holders use for "only inside").
func _seek_cover(eye: Vector3, bias_from: Vector3, max_travel := 11.0, new_angle := 3.0, why := "") -> void:
	var had := _search
	super._seek_cover(eye, bias_from, max_travel, new_angle, why)
	if _search != null and _search != had and hold.is_empty():
		_search._ctx["inside"] = func(at: Vector3) -> bool: return not _spot_in_your_line(at)


## Would a man standing there be in your line of fire, as you look now (or along the way you face
## with your gun away: you'll draw where you look)?
func _spot_in_your_line(at: Vector3) -> bool:
	var p := leader as Player
	if p == null or not is_instance_valid(p):
		return false
	var cam := p.camera
	var fwd := -cam.global_transform.basis.z
	var v := at + Vector3.UP * 1.2 - cam.global_position
	var along := v.dot(fwd)
	if along < 0.5 or along > float(tune.line_reach):
		return false
	return (v - fwd * along).length() < float(tune.line_width) * 1.5

## How far off your line of fire his chest is, signed (+ your right), or INF if he isn't in front of
## your gun (or it's away).
func line_offset() -> float:
	var p := leader as Player
	if p == null or not _gun_out(p) or not body.parts.has(&"chest"):
		return INF
	var cam := p.camera
	var fwd := -cam.global_transform.basis.z
	var v := (body.parts[&"chest"] as Node3D).global_position - cam.global_position
	var along := v.dot(fwd)
	if along < 0.5 or along > float(tune.line_reach):
		return INF
	var off := v - fwd * along
	var right := cam.global_transform.basis.x
	var lateral := off.length()
	if lateral > float(tune.line_width) * 2.0:
		return INF
	return lateral * (1.0 if off.dot(right) >= 0.0 else -1.0)


func in_your_line() -> bool:
	var o := line_offset()
	return o != INF and absf(o) < float(tune.line_width)


func _watch_line(delta: float) -> void:
	if not body.physiology.is_conscious() or body.limp:
		_line_t = 0.0
		return
	if in_your_line():
		_line_t += delta
		stats.line_s += delta
		if _line_t > float(tune.line_grace) and _line_step <= 0.0 and not body.prone:
			# Out of it, sideways, the way he's already off it.
			var p := leader as Player
			var right := p.camera.global_transform.basis.x
			right.y = 0.0
			var o := line_offset()
			var side := signf(o) if absf(o) > 0.05 else _side
			if _line_fails >= 1 and float(tune.get("line_run", 1.0)) > 0.0:
				# Stepping aside didn't do it (a wall, or you keep turning his way): to your side,
				# where your gun never points.
				_line_to = p.global_position + right.normalized() * side * 2.0 + p.global_transform.basis.z * 0.5
			else:
				_line_to = body.global_position + right.normalized() * side * float(tune.line_step)
			_line_step = 1.5 if _line_fails == 0 else 4.0
			stats.line_steps += 1
			_decide("out of your line", "in front of your gun %.1f s" % _line_t)
	else:
		_line_t = 0.0


func _step_out_of_line(delta: float) -> void:
	_line_step -= delta
	if not in_your_line() and (body.global_position.distance_to(_line_to) < 0.6 or _line_fails == 0):
		_line_step = 0.0
		_line_fails = 0
		return
	var arrived := body.walk_to(_line_to, run_speed, delta, false)
	var t := _find_target()
	if t != null:
		body.face(_eye_of(t))
	if arrived or _line_step <= 0.0:
		_line_fails = _line_fails + 1 if in_your_line() else 0
		_line_step = 0.0
		if tactic in [Tactic.HIDDEN, Tactic.PEEKING, Tactic.MOVING]:
			tactic = Tactic.OPEN
			_cover_search = 0.0


# --- With you when it's quiet -------------------------------------------------------------------

## Calm: if something's on the ladder (a man drawing on you), he squares up to it as any man would;
## otherwise he walks with you, or waits where he was told.
func _social(delta: float) -> void:
	var who := relations.focus()
	if who != null and who != leader and relations.stance(who) >= Relations.Stance.WARY:
		super._social(delta)
		return
	if held:
		return  # the scene has him
	_reload_quietly(delta)
	if _fight_seen and _calm_t > float(tune.after_fight):
		_fight_seen = false
		_say_line(&"over")
	if not body.gun_holstered and _calm_t > float(tune.holster_after) and body.held_gun != null:
		body.holster_gun()
	if leader == null or not is_instance_valid(leader):
		body.set_pose(&"stand")
		return
	if wait_at != Vector3.INF:
		if body.global_position.distance_to(wait_at) > 1.0:
			_go(wait_at, walk_speed, delta)
		else:
			body.set_pose(&"stand")
			body.face(leader.global_position + Vector3.UP * 1.5)
		return
	var d := _flat(body.global_position, leader.global_position)
	var spot := follow_spot()
	if d > float(tune.follow_far) or (_way.size() > 0 and d > float(tune.follow_near)):
		var speed := run_speed if d > float(tune.run_beyond) else walk_speed * 1.25
		_go(spot, speed, delta)
	else:
		_way.clear()
		_stuck_t = 0.0
		body.set_pose(&"stand")
		var look := leader.global_position - leader.global_transform.basis.z * 10.0
		body.face(look + Vector3.UP * 1.5)


## Where he walks: behind you and to his side of you.
func follow_spot() -> Vector3:
	var back := leader.global_transform.basis.z
	back.y = 0.0
	back = back.normalized() if back.length() > 0.01 else Vector3.BACK
	var right := Vector3.UP.cross(back).normalized()  # (+X when he faces -Z: your right)
	return leader.global_position + back * float(tune.follow_back) + right * _side * float(tune.follow_side)


func _go(to: Vector3, speed: float, delta: float) -> void:
	body.set_pose(&"stand")
	if _go_last != Vector3.INF and _flat(body.global_position, _go_last) < speed * delta * 0.2:
		_stuck_t += delta
	else:
		_stuck_t = maxf(_stuck_t - delta, 0.0)
	_go_last = body.global_position
	if _stuck_t > 1.5 and places != null and _way.is_empty():
		# Something in the way: round it by the town's ways.
		_way = places.route_to_point(World.space(body), body.global_position, to, _exclude())
		_stuck_t = 0.0
	if not _way.is_empty():
		if body.walk_to(_way[0], speed, delta):
			_way.pop_front()
		return
	body.walk_to(to, speed, delta)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- What he calls ----------------------------------------------------------------------------

## In a fight, what he sees that you might not: a man you aren't looking at, one loading.
func _watch_fight() -> void:
	if not _fight_on or leader == null or not is_instance_valid(leader) or body.limp:
		return
	for who in relations.entries.keys():
		if not is_instance_valid(who) or who == leader or relations.stance(who) != Relations.Stance.FIGHT or _done_with(who):
			continue
		if not senses.sees(who):
			continue
		var b := Crew.brain_of(who)
		if b != null and b.mood == Mood.RELOADING:
			_call(&"reloading", who, 12.0)
		var where := _where(who as Node3D)
		if where != &"" and where != &"ahead":
			_call(StringName("spotted_" + String(where)), who, 15.0)


## Which way a man is from you, as you look: &"ahead", &"left", &"right", &"behind", &"high".
func _where(who: Node3D) -> StringName:
	var p := leader as Player
	if p == null:
		return &""
	var cam := p.camera
	var to := who.global_position + Vector3.UP * 1.2 - cam.global_position
	if to.y > 3.0 and to.length() < 40.0:
		return &"high"
	var fwd := -cam.global_transform.basis.z
	fwd.y = 0.0
	var flat := Vector3(to.x, 0.0, to.z)
	var ang := rad_to_deg(fwd.signed_angle_to(flat, Vector3.UP))
	if absf(ang) < 35.0:
		return &"ahead"
	if absf(ang) > 120.0:
		return &"behind"
	return &"left" if ang > 0.0 else &"right"


func _on_callout(speaker: Node, kind: StringName, about: Node, at: Vector3) -> void:
	super._on_callout(speaker, kind, about, at)
	# One of them shouting he's going round: Joe knows what that means.
	if kind == &"flank" and _enemy_kind(speaker) and relations.stance(speaker) == Relations.Stance.FIGHT \
			and body.physiology.is_conscious() and (speaker as Node3D).global_position.distance_to(body.global_position) < Crew.EARSHOT:
		var w := _where(speaker as Node3D)
		if w in [&"left", &"right", &"behind"]:
			_call(&"flanking", speaker, 15.0, {"side": "to the left" if w == &"left" else "to the right" if w == &"right" else "behind us"})


func _enemy_out(who: Node, how: StringName) -> void:
	if who == body or not _enemy_kind(who) or relations.stance(who) != Relations.Stance.FIGHT \
			or not body.physiology.is_conscious() or not senses.sees(who):
		return
	_call(how, who, 600.0)


## A call: each kind about each man once in `every` s, and nothing on top of his last word.
func _call(kind: StringName, about: Node, every: float, fmt := {}) -> void:
	var by: Dictionary = _called.get(kind, {})
	if _now - float(by.get(about, -INF)) < every or _now - _call_at < float(tune.call_gap):
		return
	by[about] = _now
	_called[kind] = by
	if _say_line(kind, false, fmt):
		stats.calls += 1


func _say_line(kind: StringName, force := false, fmt := {}) -> bool:
	var lines: Array = (data.lines as Dictionary).get(String(kind), [])
	var p := body.physiology
	if lines.is_empty() or not p.can_speak():
		return false
	if not force and _now - _call_at < float(tune.call_gap):
		return false
	_call_at = _now
	_said_at = _now
	Events.spoke.emit(body, String(lines[_rng.randi() % lines.size()]).format(fmt))
	return true


## A moment of the gang brain's he's said is let pass this long before he says it again (s).
const BRAIN_AGAIN := 25.0


## The gang brain's own moments (`say`), his way: only the few in `brain_lines`.
func say(kind: StringName, _about_name := "", force := false) -> void:
	var lines: Array = (data.brain_lines as Dictionary).get(String(kind), [])
	if lines.is_empty() or not body.physiology.can_speak():
		return
	if not force and (not can_say() or _now - _call_at < float(tune.call_gap)):
		return
	if _now - float(_brain_said.get(kind, -INF)) < BRAIN_AGAIN:
		return  # (the playtest: "Where did he go?" every 5 s)
	_brain_said[kind] = _now
	_call_at = _now
	_said_at = _now
	Events.spoke.emit(body, String(lines[_rng.randi() % lines.size()]))
