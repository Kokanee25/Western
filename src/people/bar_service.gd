class_name BarService
extends Node
## The barkeep's side of a drink (#1292; config/drink.json's `_bar`, its prices and pours). ValleyFolk has
## one for saloon B's bar (its set's `bar`, the man `barkeep` at his `counter`); in the group `bars`, where
## PlayerDrink finds what you can order at (`at_bar`, `order`). Stepped by ValleyFolk (in its saloon_room
## timer, so it's in the people budget).
##
## - **An order** (`order(player, kind)`: whiskey, beer, the bottle, a round): he answers at once in the
##   town's script's words (`bar.*`, docs/scripts/town.json "saloon"). A gun out in your hand and he won't;
##   past `cut_off` he won't; short of the money he won't (and says so). Else he takes the coin from your
##   purse (PlayerPurse) and pours: his hand to a real bottle of the kit on his side of the bar (the nearest
##   of the drink's `bottle`s: its level goes down by the pour) and over a real kit glass he sets on the bar
##   in front of you (`glass_off` in from its edge; meta `served_to` you: PlayerDrink picks it up). Beer comes
##   from his tap (the work board's: no bottle needed). The bottle: that bottle itself set before you.
## - **Empties**: a glass of his on the bar with nothing in it, nobody holding it, `collect_s`: he takes it
##   away (his `glass` reach, then it's gone). A glass of his broken on the floor: a word.
## - **The answers** (DESIGN §2 pillar 6): a round bought (the room lifts its glasses, a man thanks you,
##   regard warms, TownNews `bar` round told later); a man drinking alone at his bar (`alone_s` with nobody
##   within `alone_m`: a word, once a night); the deputy served (StoryState `nolaw.deputy`: a word at once,
##   regard, news); you drunk (PlayerDrink.drunk: a word from him or a man near, regard of all who see it,
##   news). `log` every order and answer, for the bench and the tests.

const BARKEEP := &"barkeep"

var folk: ValleyFolk
var d: Dictionary = {}
## Every order: {t, kind, ok, why, cents, line}; and every answer: {t, what, by, line}.
var log: Array = []
## What he's set out on the bar ([GlassProp]) and since when it's stood empty (vessel -> s).
var served: Array = []
var _empty_for := {}
var _pour := {}  # the pour going on: {glass, bottle, kind, t, done}
var _clock := 0.0
var _orders := 0
var _alone_t := 0.0
var _alone_day := -1
var _drunk_told := false
var _you_drank_at := -INF
var _sips_seen := 0


func _init(f: ValleyFolk = null) -> void:
	folk = f
	d = PlayerPurse.data()
	name = "Bar"


func _ready() -> void:
	add_to_group(&"bars")


func _n(k: String, dflt: float) -> float:
	return float(d.get(k, dflt))


func barkeep() -> HumanBody:
	return folk.folk_man(BARKEEP) if folk != null else null


func _brain() -> CivilianBrain:
	var man := barkeep()
	return man.get_node_or_null(^"Brain") as CivilianBrain if man != null else null


func _bar() -> Node3D:
	return folk.props.get("bar") as Node3D if folk != null else null


## He's at his counter behind the bar, on his feet and himself.
func serving() -> bool:
	var man := barkeep()
	var b := _brain()
	if man == null or b == null or _bar() == null or not man.physiology.alive or not man.physiology.is_conscious() or man.limp:
		return false
	if folk.room != null and folk.room.doing_of(BARKEEP) != "counter":
		return false
	return man.global_position.distance_to(_bar().global_position) < 4.0


## You're at his bar, within `serve_m` of him (not behind it with him).
func at_bar(p: Node3D) -> bool:
	if p == null or not serving():
		return false
	var man := barkeep()
	var to := p.global_position - man.global_position
	if absf(to.y) > 1.2:
		return false
	to.y = 0.0
	if to.length() > _n("serve_m", 2.6):
		return false
	# On the customers' side: the bar's middle between you and him.
	var c: Vector3 = _box().centre
	var side_you := (p.global_position - c).dot(_out())
	var side_him := (man.global_position - c).dot(_out())
	return side_you > 0.0 and side_him < side_you


## The way out from the bar to its customers (world, flat): from his side to yours.
func _out() -> Vector3:
	var bar := _bar()
	var man := barkeep()
	var z := bar.global_basis.z
	z.y = 0.0
	z = z.normalized()
	if man != null and (man.global_position - bar.global_position).dot(z) > 0.0:
		z = -z
	return z


## The bar section's box ({centre (world), half depth, top (world y)}): saloon B's bar is three kit sections,
## and he may stand by any of them; across the bar is the same everywhere along it.
func _box() -> Dictionary:
	var bar := _bar()
	var kp := bar as KitProp
	var b := PropKit.bounds(kp.definition) if kp else AABB(Vector3(-1, 0, -0.3), Vector3(2, 1.1, 0.6))
	return {"centre": bar.global_transform * b.get_center(), "half": b.size.z * 0.5, "top": (bar.global_transform * Vector3(0.0, b.end.y, 0.0)).y}


## Where a customer stands before him, and the point he faces ([at, faces], [] with nobody serving):
## for the bridge (`drink bar`) and the tests.
func customer_spot() -> Array:
	if not serving():
		return []
	var man := barkeep()
	var o := _out()
	var bx := _box()
	var at := man.global_position + o * (((bx.centre as Vector3) - man.global_position).dot(o) + float(bx.half) + 0.38)
	at.y = man.global_position.y
	return [at + Vector3.UP * 0.05, man.global_position + Vector3.UP * 1.5]


## The top of the bar between `p` and him (world), `glass_off` in from its customers' edge, in line with you.
func spot_before(p: Node3D) -> Vector3:
	var man := barkeep()
	var o := _out()
	var bx := _box()
	var to := p.global_position - man.global_position
	var side := to - o * to.dot(o)
	side.y = 0.0
	var at := man.global_position + side + o * (((bx.centre as Vector3) - man.global_position).dot(o) + float(bx.half) - _n("glass_off", 0.16))
	at.y = float(bx.top)
	return at


# --- An order -----------------------------------------------------------------------------------------

## `p` asks for `kind`: {ok, why, cents, line} (why: gun, drunk, money, busy, held, away).
func order(p: Player, kind: StringName) -> Dictionary:
	var out := {"ok": false, "kind": String(kind), "why": "", "cents": 0, "line": ""}
	var man := barkeep()
	var b := _brain()
	if not at_bar(p):
		out.why = "away"
	elif b.held or folk._story_on():
		out.why = "held"  # a story's scene has him (No Law's night: SceneHold)
	elif not _pour.is_empty():
		out.why = "busy"
	elif p.drink != null and p.drink.gun_out():
		out.why = "gun"
		out.line = _say(man, "bar.gun", p)
	elif p.drink != null and p.drink.units >= _n("cut_off", 7.0):
		out.why = "drunk"
		out.line = _say(man, "bar.cut_off", p)
	else:
		var drinks: Dictionary = d.get("drinks", {})
		var dk: Dictionary = drinks.get("whiskey" if kind == &"round" else String(kind), {})
		var men := _room_men()
		var cents := int(dk.get("cents", 0)) if kind != &"round" else int(d.get("round_cents", 10)) * (men.size() + 1)
		out.cents = cents
		if dk.is_empty():
			out.why = "unknown"
		elif p.purse == null or not p.purse.pay(cents, StringName("bar_" + String(kind))):
			out.why = "money"
			out.line = _say(man, "bar.no_money", p)
		else:
			out.ok = true
			p.purse.say_paid(cents, "A round for the house" if kind == &"round" else ("The bottle" if kind == &"bottle" else String(kind).capitalize()))
			out.line = _say(man, "bar.round" if kind == &"round" else "bar.serve." + ("whiskey" if kind == &"round" else String(kind)), p)
			_start_pour(p, &"whiskey" if kind == &"round" else kind)
			_answers_to_order(p, kind, men)
	if out.why != "" and out.why in ["away", "held", "busy", "unknown"] and p.wounds:
		p.wounds.say({"away": "Nobody's serving", "held": "He's busy", "busy": "He's pouring", "unknown": "He doesn't have that"}[out.why], 1.5)
	out["t"] = snappedf(_clock, 0.01)
	log.append(out)
	_orders += 1
	return out


## The men in the room with you (not him), for a round.
func _room_men() -> Array:
	var out: Array = []
	if folk.room == null:
		return out
	for id: StringName in folk.room.ins:
		var m := folk.folk_man(id)
		if id != BARKEEP and m != null and m.physiology.is_conscious():
			out.append(m)
	return out


## His transactional word (said every time it's so, in a wording by the order: TownScript straight, not the
## day's barks' once-a-day): the line said ("" if none).
func _say(man: HumanBody, id: String, _p: Node3D) -> String:
	if man == null:
		return ""
	var text := TownScript.pick([id], TownScript.seed_of(String(man.person_id), "%s:%d" % [id, _orders]), {})
	if text == "":
		return ""
	var b := man.get_node_or_null(^"Brain") as CivilianBrain
	if b != null:
		b.say_line(text)
	return text


func _start_pour(p: Player, kind: StringName) -> void:
	var dk: Dictionary = (d.get("drinks", {}) as Dictionary).get(String(kind), {})
	var at := spot_before(p)
	var bottle := _bottle_for(dk)
	var glass: GlassProp = null
	if String(dk.get("glass", "")) != "":
		glass = PropKit.make(StringName(dk.glass)) as GlassProp
		if glass != null:
			folk.add_child(glass)
			glass.global_transform = Transform3D(Basis(Vector3.UP, p.rotation.y), at + Vector3.UP * 0.003)
			glass.set_litres(0.0)
			_serve(glass, p)
	_pour = {"glass": glass, "bottle": bottle, "kind": kind, "t": 0.0, "done": false, "at": at, "p": p,
			"from": bottle.global_position if bottle != null else barkeep().global_transform * Vector3(0.3, 1.05, -0.3)}
	var b := _brain()
	if b != null:
		b.start_bit({"what": &"pour", "for": _n("pour_s", 2.4), "at": at, "bottle": _pour.from, "look": p,
				"mark_t": 1.2, "mark": _poured, "by": String(BARKEEP)})


## A vessel of his set before `p`: his (collected when it's empty), yours to pick up; broken, a word.
func _serve(g: GlassProp, p: Node3D) -> void:
	g.set_meta(&"served_to", p)
	served.append(g)
	g.shattered.connect(func(_at: Vector3, _dir: Vector3) -> void: broke(g))


## A glass of whiskey set before `p` unasked (SaloonRoom's glass on the house, #1157): poured, yours.
func give_glass(at: Vector3, p: Node3D) -> GlassProp:
	var dk: Dictionary = (d.get("drinks", {}) as Dictionary).get("whiskey", {})
	var g := PropKit.make(StringName(dk.get("glass", "shot_glass"))) as GlassProp
	if g == null:
		return null
	folk.add_child(g)
	g.global_transform = Transform3D(Basis(Vector3.UP, p.rotation.y if p else 0.0), at + Vector3.UP * 0.003)
	g.set_litres(float(dk.get("pour_l", 0.044)))
	_serve(g, p)
	return g


## The nearest real bottle of the drink's on his side of the bar, with enough in it (null: none, or the tap's).
func _bottle_for(dk: Dictionary) -> GlassProp:
	if bool(dk.get("from_tap", false)):
		return null
	var kinds: Array = dk.get("bottle", [])
	var man := barkeep()
	var best: GlassProp = null
	var best_d := 3.0
	for n in folk.get_tree().get_nodes_in_group(&"glass_props"):
		var g := n as GlassProp
		if g == null or g.broken or g.held or g.loose or not String(g.kit_id) in kinds or g.has_meta(&"served_to"):
			continue
		if g.litres_in() < float(dk.get("pour_l", 0.0)) + 0.001 and not bool(dk.get("whole", false)):
			continue
		var dd := g.global_position.distance_to(man.global_position)
		if dd < best_d:
			best_d = dd
			best = g
	return best


## The pour's mark: the glass filled from the bottle, or the bottle set before you.
func _poured() -> void:
	if _pour.is_empty() or _pour.done:
		return
	_pour.done = true
	var dk: Dictionary = (d.get("drinks", {}) as Dictionary).get(String(_pour.kind), {})
	var bottle: GlassProp = _pour.bottle
	var glass: GlassProp = _pour.glass
	var p: Player = _pour.p
	if bool(dk.get("whole", false)):
		var at: Vector3 = _pour.at
		var xf := Transform3D(Basis(Vector3.UP, p.rotation.y if p else 0.0), at + Vector3.UP * 0.003)
		if bottle != null and is_instance_valid(bottle) and not bottle.broken:
			bottle.take_up(folk, Transform3D(Basis.IDENTITY, at))
			bottle.put_down(folk, xf)
		else:
			# No bottle of it on his side: one from under the bar.
			bottle = PropKit.make(StringName((dk.get("bottle", ["liquor_quart"]) as Array)[0])) as GlassProp
			folk.add_child(bottle)
			bottle.global_transform = xf
		_serve(bottle, p)
	elif glass != null and is_instance_valid(glass) and not glass.broken:
		var l := float(dk.get("pour_l", glass.full_litres()))
		glass.set_litres(l)
		if bottle != null and is_instance_valid(bottle) and not bottle.broken:
			bottle.set_litres(bottle.litres_in() - l)
	log.append({"t": snappedf(_clock, 0.01), "what": "poured", "kind": String(_pour.kind),
			"bottle": String(bottle.kit_id) if bottle != null and is_instance_valid(bottle) else ("tap" if bool(dk.get("from_tap", false)) else "")})
	_pour = {}


# --- Each frame ----------------------------------------------------------------------------------------

func step(delta: float) -> void:
	_clock += delta
	if not _pour.is_empty():
		_pour.t = float(_pour.t) + delta
		# His pour cut short (trouble, a look round): he finishes it all the same, a beat late.
		if float(_pour.t) > _n("pour_s", 2.4) + 1.0:
			_poured()
	_collect(delta)
	var p := folk.get_tree().get_first_node_in_group(&"player") as Player if folk.is_inside_tree() else null
	if p == null or p.drink == null:
		return
	_drunk_step(p)
	_alone_step(p, delta)


func _collect(delta: float) -> void:
	for i in range(served.size() - 1, -1, -1):
		var g: GlassProp = served[i]
		if g == null or not is_instance_valid(g):
			served.remove_at(i)
			continue
		if g.broken:
			served.remove_at(i)
			_empty_for.erase(g)
			continue
		if g.held or g.loose or g.litres_in() > 0.002:
			_empty_for.erase(g)
			continue
		_empty_for[g] = float(_empty_for.get(g, 0.0)) + delta
		if float(_empty_for[g]) < _n("collect_s", 20.0) or not serving() or g.global_position.distance_to(barkeep().global_position) > 2.4:
			continue
		var b := _brain()
		if b == null or not b.bit.is_empty() or not _pour.is_empty():
			continue
		served.remove_at(i)
		_empty_for.erase(g)
		b.start_bit({"what": &"glass", "for": 2.6, "at": g.global_position, "mark_t": 1.2, "mark": _take_away.bind(g), "by": String(BARKEEP)})
		log.append({"t": snappedf(_clock, 0.01), "what": "collect", "kit": String(g.kit_id)})
		return


func _take_away(g: GlassProp) -> void:
	if is_instance_valid(g) and not g.held and not g.broken:
		g.queue_free()


## The glass you dropped broke: a word from him if he's there.
func broke(g: GlassProp) -> void:
	if serving() and g.global_position.distance_to(barkeep().global_position) < 8.0:
		var line := _say(barkeep(), "bar.broke", null)
		log.append({"t": snappedf(_clock, 0.01), "what": "broke", "by": String(BARKEEP), "line": line})


# --- The answers (DESIGN §2 pillar 6) ------------------------------------------------------------------

func _answers_to_order(p: Player, kind: StringName, men: Array) -> void:
	var man := barkeep()
	var at := spot_before(p)
	if folk.regard != null:
		folk.regard.saw_harlan("bought", at, p, man, [], true)
	if kind == &"round":
		if folk.regard != null:
			folk.regard.saw_harlan("round", at, p, null, men)
		if folk.news != null:
			folk.news.bar(&"round", men + [man], at)
		# The room lifts its glasses; the first two by distance thank you.
		var near := men.duplicate()
		near.sort_custom(func(a: HumanBody, b: HumanBody) -> bool: return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
		var thanked := 0
		for m: HumanBody in near:
			var b := m.get_node_or_null(^"Brain") as CivilianBrain
			if b == null or not SaloonRoom.is_calm(b):
				continue
			var bit := {"what": &"toast", "for": 2.4, "look": p, "by": String(m.person_id)}
			if thanked < 2:
				var l := folk.room_line(m.person_id, "bar.round.thanks")
				if not l.is_empty():
					bit["say"] = String(l[1])
					bit["line"] = String(l[0])
					bit["say_at"] = 0.6 + 0.9 * thanked
					thanked += 1
					log.append({"t": snappedf(_clock, 0.01), "what": "thanks", "by": String(m.person_id), "line": String(l[1])})
			b.start_bit(bit)
	if StoryState.get_fact("nolaw.deputy", false) == true:
		# The deputy drinking: a word from him (once a day), regard, and news.
		var l := folk.room_line(BARKEEP, "bar.deputy")
		if not l.is_empty():
			folk.say_soon(man, String(l[1]))
			log.append({"t": snappedf(_clock, 0.01), "what": "deputy", "by": String(BARKEEP), "line": String(l[1])})
		if folk.regard != null:
			folk.regard.saw_harlan("deputy_drinking", at, p, null, [man])
		if folk.news != null:
			folk.news.bar(&"deputy", [man], at)


## You drunk (PlayerDrink.drunk): the barkeep says so if you're at his bar, else a man near who sees it;
## each who sees it keeps it, and it's news. Again only once you've sobered a good way.
func _drunk_step(p: Player) -> void:
	if p.drink.units < _n("drunk_at", 4.0) - 1.0:
		_drunk_told = false
		return
	if _drunk_told or not p.drink.drunk():
		return
	var at := p.global_position
	var who := barkeep() if at_bar(p) else null
	if who == null and folk.room != null:
		var best := 6.0
		for id: StringName in folk.room.ins:
			var m := folk.folk_man(id)
			var b := m.get_node_or_null(^"Brain") as CivilianBrain if m else null
			if b == null or b.senses == null or not b.senses.sees(p) or not b.may_speak():
				continue
			var dd := m.global_position.distance_to(at)
			if dd < best:
				best = dd
				who = m
	if who == null:
		return
	_drunk_told = true
	var l := folk.room_line(who.person_id, "bar.drunk")
	if not l.is_empty():
		folk.say_soon(who, String(l[1]))
		log.append({"t": snappedf(_clock, 0.01), "what": "drunk", "by": String(who.person_id), "line": String(l[1])})
	if folk.regard != null:
		folk.regard.saw_harlan("drunk", at, p, null, [who])
	if folk.news != null:
		folk.news.bar(&"drunk", [who], at)


## A man drinking alone at his bar: he's drunk something here and nobody's within `alone_m` for `alone_s`.
func _alone_step(p: Player, delta: float) -> void:
	if p.drink.sips != _sips_seen:
		_sips_seen = p.drink.sips
		_you_drank_at = _clock
	if not at_bar(p) or _clock - _you_drank_at > 120.0 or _alone_day == folk.town_day():
		_alone_t = 0.0
		return
	for id: StringName in (folk.room.ins if folk.room != null else []):
		var m := folk.folk_man(id)
		if id != BARKEEP and m != null and m.global_position.distance_to(p.global_position) < _n("alone_m", 2.5):
			_alone_t = 0.0
			return
	_alone_t += delta
	if _alone_t < _n("alone_s", 45.0):
		return
	var b := _brain()
	if b == null or not SaloonRoom.is_calm(b) or not b.may_speak():
		return
	_alone_day = folk.town_day()
	var l := folk.room_line(BARKEEP, "bar.alone")
	if not l.is_empty():
		folk.say_soon(barkeep(), String(l[1]))
		log.append({"t": snappedf(_clock, 0.01), "what": "alone", "by": String(BARKEEP), "line": String(l[1])})


func report() -> Dictionary:
	return {"serving": serving(), "orders": _orders, "served": served.size(), "pouring": not _pour.is_empty(),
			"log": log.slice(-12)}
