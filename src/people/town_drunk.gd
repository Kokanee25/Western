class_name TownDrunk
extends RefCounted
## The town drunk (#1312; his card: docs/story/people.json `town_drunk`, Ephraim "Sarge" Tolliver, a
## broken first sergeant): every time he sees the deputy he calls out at him, and the street hears it.
##
## - **A meeting, a jibe.** Harlan within `call_m` and in his sight, the drunk calm and in the world:
##   one jibe (TownBarks `on: jibe`, his pool `town_drunk`), once a meeting. A meeting ends once Harlan's
##   been further than `gone_m` for `gone_s`; standing by him `again_s` is another. Never before the
##   badge (every jibe's `fact` nolaw.deputy); his first is the one that says what a brevet is
##   (`on: jibe.first`, `once: ever`). Never the same line twice in a game day (TownBarks' once a day a
##   person), and the most specific that fits wins: what he can see on Harlan now and what the town
##   knows he did today (`you`, `you_tags`), the story's facts, the hour, his own band, sober or not.
## - **What he knows of you** (`you` tags): now, drunk, glass, gun_out, running, carrying, hurt,
##   bloody; today (the town's gossip: `deeds`, a deed a day), shot_near, fled (ran within `fled_s` of a
##   shot near), fired, hit_man, shoved, fell, won_cards, lost_cards, bluffed, arrested, round, blast,
##   carried, noted (read one of his notes), jailed_him (walked him to the jail, today or last night).
## - **Answers** (DESIGN §2 pillar 6): within `answer_s` of a jibe and `answer_m` of him, a nod or a
##   shake (HeadGesture) gets `jibe.nod` / `jibe.shake`; a shove or kick at him any time `jibe.shove`;
##   a drink stood him (the glass in your hand given him with E, or a round with him in the room)
##   `jibe.drink`: the first few times a sober line, once each for good, then `jibe.drink.again`; G at
##   him (the badge on, no gun out) walks him to the jail (`jibe.lead`), off again if you go `lead_lost_m`
##   off (`jibe.let_go`); at the jail's door he goes in to sleep it off (`jibe.jail`) till `jail_until_h`.
## - **The street hears it.** One townsman within `hear_m` answers the jibe by his own band (`jibe.heard`:
##   the cold laugh, the wary wince, the warm tell him to hush); those who heard keep it (TownRegard
##   deed `mocked`, the answers `took_it`, `stood_sarge`, `jailed_sarge`), and the news carries it once a
##   day (TownNews.bar `jibe`: "Sarge had a go at the deputy again").

const ID := &"town_drunk"

var folk: ValleyFolk
var d: Dictionary = {}
## Harlan's deeds the town knows of today: kind -> [town day, folk seconds].
var deeds := {}
## Notes read (DrunkNotes): their ids.
var noted := {}
var met := false
var _away := 0.0
var _met_s := 0.0
var last_jibe_s := -INF
var gesture := HeadGesture.new()
var led := false
var _lead_t := 0.0
## Out of the world in the jail till this many hours (the folk's _abs_hours), -1 not.
var jailed_until := -1.0
var _news_day := -1
var _ran_t := -INF
var _near_shot_t := -INF
## What he said and why: [on, line id, text, folk seconds].
var log: Array = []


func _init(f: ValleyFolk, data: Dictionary) -> void:
	folk = f
	d = data
	Events.deed.connect(_on_deed)
	Events.shot_fired.connect(_on_shot)
	Events.near_miss.connect(_on_near_miss)
	Events.exploded.connect(_on_exploded)
	Events.shouted.connect(_on_shouted)
	if f != null and f.cards != null:
		f.cards.you_did.connect(_on_table)


## The town's still there (a lab's town freed with this still on the Events bus: nothing to do).
func live() -> bool:
	return folk != null and is_instance_valid(folk) and folk.is_inside_tree()


func _on_near_miss(person: Node, _s: Node, _dist: float, _at: Vector3, _sp: float, _t: bool) -> void:
	if person is Player and live():
		_near_shot()


func _on_exploded(at: Vector3, _kg: float) -> void:
	var p := _player()
	if p != null and p.global_position.distance_to(at) < _n("blast_m", 40.0):
		did(&"blast")


func _n(k: String, dflt: float) -> float:
	return float(d.get(k, dflt))


func _player() -> Player:
	if not live():
		return null
	return folk.get_tree().get_first_node_in_group(&"player") as Player


func man() -> HumanBody:
	return folk.folk_man(ID) if folk != null else null


func brain() -> CivilianBrain:
	var m := man()
	return m.get_node_or_null(^"Brain") as CivilianBrain if m != null else null


# --- What the town knows Harlan did today -------------------------------------------------------------

## Harlan did `kind` (the town hears of it today).
func did(kind: StringName) -> void:
	deeds[String(kind)] = [folk.town_day() if folk else 0, folk._ran if folk else 0.0]
	if folk != null and folk.notes != null:
		folk.notes.deed(String(kind))


func did_today(kind: String) -> bool:
	var e: Array = deeds.get(kind, [])
	return not e.is_empty() and int(e[0]) == (folk.town_day() if folk else 0)


func _near_shot() -> void:
	did(&"shot_near")
	_near_shot_t = folk._ran if folk else 0.0


func _on_shot(origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	var p := _player()  # (null once the town's gone)
	if p == null:
		return
	if shooter == p:
		did(&"fired")
	elif p.global_position.distance_to(origin) < _n("shot_near_m", 15.0):
		_near_shot()


func _on_deed(actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
	if not actor is Player or not live():
		return
	if target != null and target == man():
		if kind in [&"shove", &"kick", &"kick_down"]:
			answer(&"shove")
		return
	match kind:
		&"shove", &"kick", &"kick_down":
			did(&"shoved")
		&"hit":
			did(&"hit_man")
		&"arrest":
			did(&"arrested")
		&"carry":
			did(&"carried")


func _on_table(verb: StringName, _info: Dictionary) -> void:
	if not live():
		return
	match verb:
		&"won_pot":
			did(&"won_cards")
		&"lost_pot":
			did(&"lost_cards")
		&"bluff_called":
			did(&"bluffed")
			did(&"lost_cards")


## Harlan stood the house a round (BarService): the town hears of it; with him in the room, a drink stood him.
func round_bought(men: Array) -> void:
	did(&"round")
	if men.has(man()):
		answer(&"drink")


## A note of his read (DrunkNotes).
func read_note(id: String) -> void:
	noted[id] = folk.town_day() if folk else 0
	did(&"noted")


## Harlan's state as the jibes' `you` tags: what he can see on him now, and what the town knows of today.
func you_tags(p: Player) -> Array:
	var out: Array = []
	if p == null:
		return out
	if p.drink != null:
		if p.drink.drunk():
			out.append("drunk")
		if p.drink.holding():
			out.append("glass")
		if p.drink.gun_out():
			out.append("gun_out")
	if p.get_horizontal_speed() > _n("run_mps", 4.2):
		out.append("running")
	if p.carry != null and p.carry.carrying():
		out.append("carrying")
	var hurt := p.wounds != null and not p.wounds.wounds.is_empty()
	if hurt:
		out.append("hurt")
	if hurt or did_today("carried") or did_today("hit_man"):
		out.append("bloody")
	for k: String in ["shot_near", "fired", "hit_man", "shoved", "fell", "won_cards", "lost_cards", "bluffed",
			"arrested", "round", "blast", "carried", "noted", "fled"]:
		if did_today(k):
			out.append(k)
	var j: Array = deeds.get("jailed_him", [])
	if not j.is_empty() and int(j[0]) >= (folk.town_day() if folk else 0) - 1:
		out.append("jailed_him")
	return out


## Sober: before ten in the morning (he wakes about nine; the heel-taps at ten), or the morning after a
## night in the jail till noon.
func sober() -> bool:
	var h := folk.hour()
	if h >= 5.0 and h < _n("sober_until_h", 10.0):
		return true
	var j: Array = deeds.get("jailed_him", [])
	return not j.is_empty() and int(j[0]) == folk.town_day() - 1 and h >= 5.0 and h < 12.0


## His ctx for the picker: ValleyFolk's own, Harlan's tags, sober or not.
func ctx(p: Player) -> Dictionary:
	var c := folk.bark_ctx(ID, man())
	c["you"] = you_tags(p)
	c["sober"] = sober()
	return c


# --- The step -----------------------------------------------------------------------------------------

func step(delta: float) -> void:
	var m := man()
	var p := _player()
	if jailed_until >= 0.0:
		if folk._abs_hours() < jailed_until:
			var pd := folk._person(ID)
			var b := folk.block_now(pd, folk.hour())
			if not b.is_empty():
				folk.kept_out[ID] = ValleyFolk.block_key(b)  # sleeping it off: his day waits
		else:
			jailed_until = -1.0
	if m == null or p == null or folk.state.get(ID) not in [&"in", &"called"]:
		return
	if p.wounds != null and (p.wounds.out_cold > 0.0) or p.shove != null and p.shove.slipped():
		did(&"fell")
	if p.drink != null and p.drink.drunk() and not did_today("drunk"):
		did(&"drunk")  # seen drunk (a note's deed; the `drunk` tag is what he sees now)
	if p.get_horizontal_speed() > _n("run_mps", 4.2):
		_ran_t = folk._ran
		if folk._ran - _near_shot_t < _n("fled_s", 20.0):
			did(&"fled")
	if led:
		_lead_step(m, p, delta)
		return
	var dist := m.global_position.distance_to(p.global_position)
	if dist > _n("gone_m", 25.0):
		_away += delta
		if _away > _n("gone_s", 45.0):
			met = false
	else:
		_away = 0.0
	if met:
		_met_s += delta
		if _met_s > _n("again_s", 240.0) and dist < _n("call_m", 7.0):
			met = false  # stood by him a good while: he's thought of another
	if folk._ran - last_jibe_s < _n("answer_s", 12.0) and dist < _n("answer_m", 5.0):
		var g := gesture.feed(rad_to_deg(p.rotation.y), p.get_pitch_degrees(), delta)
		if g != &"":
			answer(g)
	if met or dist > _n("call_m", 7.0):
		return
	var b := brain()
	if not TownNews._calm(b) or b.senses == null or not b.senses.sees(p) or folk._story_on():
		return
	jibe(m, p)


## Call out at Harlan: his first jibe till it's said, then the most specific that fits. True if said.
func jibe(m: HumanBody, p: Player) -> bool:
	var day := folk.town_day()
	var c := ctx(p)
	var l := folk.barks.pick("jibe.first", c, day, folk._ran)
	if l.is_empty():
		l = folk.barks.pick("jibe", c, day, folk._ran)
	met = true
	_met_s = 0.0
	if l.is_empty():
		return false
	last_jibe_s = folk._ran
	gesture = HeadGesture.new()
	_say(m, l, "jibe")
	m.face(p.global_position + Vector3.UP * 1.5)
	_heard(m, p, "mocked")
	return true


func _say(m: HumanBody, l: Array, on: String) -> void:
	folk.say_soon(m, String(l[1]))
	folk.heard.append([String(ID), String(l[0]), String(l[1])])
	log.append([on, String(l[0]), String(l[1]), folk._ran])


## Harlan answered him (`kind`: nod, shake, shove, drink, lead, let_go, jail): his line for it, and the
## street's.
func answer(kind: StringName) -> bool:
	var m := man()
	var p := _player()
	if m == null or folk == null or folk.barks == null:
		return false
	var b := brain()
	if b != null and not b.may_speak():
		return false
	var c := ctx(p)
	var l: Array = []
	if kind == &"drink":
		did(&"stood")
		l = folk.barks.pick("jibe.drink", c, folk.town_day(), folk._ran)
		if l.is_empty():
			l = folk.barks.pick("jibe.drink.again", c, folk.town_day(), folk._ran)
		if folk.regard != null and p != null:
			folk.regard.saw_harlan("stood_sarge", m.global_position, p, m, _hearers(m, p))
	else:
		l = folk.barks.pick("jibe." + String(kind), c, folk.town_day(), folk._ran)
		if folk.regard != null and p != null and kind == &"nod":
			folk.regard.saw_harlan("took_it", m.global_position, p, m, _hearers(m, p))
	last_jibe_s = -INF  # answered: the window's shut
	if l.is_empty():
		return false
	_say(m, l, "jibe." + String(kind))
	if kind != &"drink" and p != null:
		m.face(p.global_position + Vector3.UP * 1.5)
	return true


## The townsfolk within `hear_m` of him who can hear it (calm, conscious, not him).
func _hearers(m: HumanBody, _p: Player) -> Array:
	var out: Array = []
	for pid: StringName in folk.people:
		var h: HumanBody = folk.people[pid]
		if pid == ID or h == null or not is_instance_valid(h) or not h.physiology.is_conscious():
			continue
		if folk.state.get(pid) != &"in" or h.global_position.distance_to(m.global_position) > _n("hear_m", 12.0):
			continue
		out.append(h)
	return out


## The street heard a jibe: one man answers it by his band, those who heard keep it (regard), and the
## news carries it once a day.
func _heard(m: HumanBody, p: Player, deed: String) -> void:
	var men := _hearers(m, p)
	if men.is_empty():
		return
	if folk.regard != null:
		folk.regard.saw_harlan(deed, m.global_position, p, null, men, false, m)
	if folk.news != null and _news_day != folk.town_day():
		_news_day = folk.town_day()
		folk.news.bar(&"jibe", men, m.global_position)
	men.sort_custom(func(a: HumanBody, b: HumanBody) -> bool:
		return a.global_position.distance_to(m.global_position) < b.global_position.distance_to(m.global_position))
	for h: HumanBody in men:
		var hb := h.get_node_or_null(^"Brain") as CivilianBrain
		if not TownNews._calm(hb) or folk._person(h.person_id).has("act"):
			continue
		var l := folk.barks.pick("jibe.heard", folk.bark_ctx(h.person_id, h), folk.town_day(), folk._ran)
		if l.is_empty():
			continue
		folk._later.append([folk._ran + _n("heard_s", 2.5), h, String(l[1])])
		folk.heard.append([String(h.person_id), String(l[0]), String(l[1])])
		log.append(["jibe.heard", String(l[0]), String(l[1]), folk._ran])
		return


# --- Walking him to the jail ----------------------------------------------------------------------------

func _on_shouted(speaker: Node, _kind: StringName) -> void:
	var p := speaker as Player
	if p == null or not live():
		return
	var m := man()
	if m == null or folk.state.get(ID) not in [&"in", &"called"]:
		return
	if led:
		_let_go()
		return
	if not StoryState.has_fact("nolaw.deputy") or (p.drink != null and p.drink.gun_out()):
		return
	var to := m.global_position + Vector3.UP * 1.3 - p.camera.global_position
	if to.length() > _n("lead_m", 4.0) or rad_to_deg((-p.camera.global_basis.z).angle_to(to)) > 25.0:
		return
	led = true
	_lead_t = 0.0
	folk.state[ID] = &"called"  # his day waits while you walk him
	answer(&"lead")


## Where you walk him: the jail's door (its place, else the walk in front of it).
func jail_door() -> Vector3:
	if folk.places != null and folk.places.has(&"jail"):
		return folk.places.at(&"jail")
	return folk.spot_point(folk.spot("jail_walk"))[0]


func _lead_step(m: HumanBody, p: Player, delta: float) -> void:
	_lead_t -= delta
	var dist := m.global_position.distance_to(p.global_position)
	if dist > _n("lead_lost_m", 10.0) or not m.physiology.is_conscious():
		_let_go()
		return
	var door := jail_door()
	if Vector2(m.global_position.x - door.x, m.global_position.z - door.z).length() < _n("jail_in_m", 2.5):
		_in_jail(m, p)
		return
	if _lead_t > 0.0:
		return
	_lead_t = 0.5
	var b := brain()
	if b == null:
		return
	var back := (m.global_position - p.global_position)
	back.y = 0.0
	if back.length() < 0.01:
		back = -p.global_basis.z
	# A pace behind you on your way; the last of it, the door itself.
	var to := p.global_position + back.normalized() * 1.2 if p.global_position.distance_to(door) > 3.0 else door
	b.go_to(to, door + Vector3.UP * 1.5)


func _let_go() -> void:
	led = false
	folk.state[ID] = &"in"
	folk._due[ID] = true  # back to his day, walking
	answer(&"let_go")


func _in_jail(m: HumanBody, p: Player) -> void:
	led = false
	answer(&"jail")
	did(&"jailed_him")
	if folk.regard != null:
		folk.regard.saw_harlan("jailed_sarge", m.global_position, p, m, _hearers(m, p))
	if folk.news != null:
		folk.news.bar(&"jailed_sarge", _hearers(m, p) + [m], m.global_position)
	# In at the jail's door to sleep it off till morning (`jail_until_h` the next day's hour).
	var until_h := _n("jail_until_h", 9.0)
	var now := folk._abs_hours()
	var day_start := floorf(now / 24.0) * 24.0
	jailed_until = day_start + until_h + (24.0 if fmod(now, 24.0) >= until_h - 3.0 else 0.0)
	folk.state[ID] = &"in"
	folk._going_to[ID] = [&"jail", &"sleep"]
	folk._gone(ID)


## Hand him the glass in your hand (PlayerDrink, E with a glass by him): true if he took it.
func takes_glass(p: Player) -> bool:
	var m := man()
	if m == null or p == null or folk.state.get(ID) != &"in":
		return false
	var to := m.global_position + Vector3.UP * 1.3 - p.camera.global_position
	return to.length() < _n("give_m", 1.8) and rad_to_deg((-p.camera.global_basis.z).angle_to(to)) < 30.0


func to_dict() -> Dictionary:
	var ever: Dictionary = folk.barks.said_ever.get(String(ID), {}) if folk != null and folk.barks != null else {}
	return {"deeds": deeds.duplicate(true), "noted": noted.duplicate(), "jailed_until": jailed_until, "said_ever": ever.duplicate()}


func from_dict(s: Dictionary) -> void:
	deeds = (s.get("deeds", {}) as Dictionary).duplicate(true)
	noted = (s.get("noted", {}) as Dictionary).duplicate()
	jailed_until = float(s.get("jailed_until", -1.0))
	if folk != null and folk.barks != null and not (s.get("said_ever", {}) as Dictionary).is_empty():
		folk.barks.said_ever[String(ID)] = (s.said_ever as Dictionary).duplicate()  # the brevet line, the sober ones: once for good
	met = false
	led = false
