extends TestCase
## Harlan buys a drink and drinks it (#1292; PlayerPurse, PlayerDrink, BarService, config/drink.json):
## - the purse: dollars and cents, paid and refused, saved; the card table's stake bought with it and
##   cashed back to it;
## - the bar: the barkeep answers an order at once, pours from a real kit bottle (its level down by the
##   pour) into a real kit glass on the bar before you, takes the coin; no money, a gun out or too drunk,
##   he won't, and says so; beer from his tap; the empty glass he collects;
## - the glass: picked up into your hand (on the held layer, its body off), a shot down in one, set down on
##   the bar, dropped (it breaks) and a gun drawn drops it;
## - the dial: into the blood over the absorb time, out by the clock; the nerve a little steadier round one
##   drink; the gun's sway and settle worse with more; past body_from the walk weaves;
## - the answers (DESIGN §2 pillar 6): a round bought (thanks, regard, news), the deputy drinking (a word,
##   news), Harlan drunk (a word, regard, news).

var holder: Node
var valley: ValleyWorld
var said: Array = []


func before_each() -> void:
	said = []
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	ValleyFolk.murder_auto = true
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([who, text])


func _valley() -> void:
	ValleyFolk.murder_auto = false
	StoryState.clear()
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	# An ordinary evening (not No Law's night: its scene holds the bar), everyone at his spot.
	var c := valley.get_node(^"DayCycle") as DayCycle
	c.day = 2
	c.set_time(20.6)
	await physics_frames(1)
	valley.folk._look = 0.0
	await physics_frames(60 * 4)


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _bar() -> BarService:
	return valley.folk.service


## Stood at the bar before the barkeep, facing him.
func _at_bar() -> bool:
	var p := _player()
	var at := _bar().customer_spot()
	if at.is_empty():
		return false
	p.global_position = at[0]
	p.velocity = Vector3.ZERO
	var to: Vector3 = (at[1] as Vector3) - (at[0] as Vector3)
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(3)
	return p.drink.bar_here() != null


## Said since `from` by `who` (or anyone), one of the script line `id`'s wordings.
func _said_line(id: String, from := 0, who: Node = null) -> bool:
	var words := TownScript.words(id)
	for i in range(from, said.size()):
		if (who == null or said[i][0] == who) and String(said[i][1]) in words:
			return true
	return false


## Looking at `g`, near enough to take it.
func _look_at(g: Node3D) -> void:
	var p := _player()
	var to := g.global_position + Vector3.UP * 0.04 - p.camera.global_position
	var pitch := rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
	p.add_look(Vector2(0.0, pitch - p.get_pitch_degrees()), false)
	await physics_frames(2)


func _wait_pour() -> GlassProp:
	var bar := _bar()
	await wait_until(func() -> bool: return not bar.report().pouring, 60 * 6)
	return bar.served[-1] if not bar.served.is_empty() else null


func test_the_purse_and_the_dial_by_their_rules() -> void:
	var purse := PlayerPurse.new()
	check_eq(purse.cents, int(PlayerPurse.data().purse), "a new game's money from the data")
	check_eq(PlayerPurse.money(15), "15 cents", "cents as cents")
	check_eq(PlayerPurse.money(340), "$3.40", "dollars and cents")
	check(purse.pay(15, &"whiskey"), "a whiskey paid")
	check_eq(purse.cents, 325, "fifteen cents gone")
	check(not purse.pay(1000, &"bottle"), "ten dollars he hasn't got: refused")
	check_eq(purse.cents, 325, "and nothing taken")
	purse.take(100, &"chips")
	var saved := purse.save_dict()
	var again := PlayerPurse.new()
	again.load_dict(saved)
	check_eq(again.cents, 425, "the purse comes back from a save")
	purse.free()
	again.free()
	# The dial, by the hour.
	var dr := PlayerDrink.new()
	dr.d = PlayerPurse.data()
	var d := dr.d
	dr.gut = 1.0
	dr.pass_hours(float(d.absorb_h))
	check_near(dr.units + dr.gut, 1.0 - float(d.burn_per_h) * float(d.absorb_h), 0.01, "half in by the absorb time, less what's burnt")
	check_near(dr.gut, 0.5, 0.01, "half still to come")
	dr.gut = 0.0
	dr.units = 1.0
	check(dr.nerve_scale() < 0.99, "one drink: the nerve steadier (%.2f)" % dr.nerve_scale())
	var sway_one := dr.sway_scale()
	var settle_one := dr.settle_scale()
	check(sway_one > 1.0 and sway_one < 1.15, "one drink: a little sway (%.3f)" % sway_one)
	check(settle_one > 1.0, "and a slower settle (%.3f)" % settle_one)
	check_eq(dr.weave(Vector3.FORWARD), Vector3.FORWARD, "no weave in the walk at one")
	dr.units = 5.0
	check(dr.sway_scale() > sway_one + 0.3, "more with more (%.3f)" % dr.sway_scale())
	check_near(dr.nerve_scale(), 1.0, 0.001, "the courage gone by five")
	check(dr.drunk(), "five is drunk")
	dr._t = 1.3
	check(dr.weave(Vector3.FORWARD).angle_to(Vector3.FORWARD) > 0.001, "the walk weaves past body_from")
	dr.pass_hours(3.0)
	check_near(dr.units, 2.0, 0.01, "a drink an hour off by the clock")
	dr._on_hours_passed(8.0, &"sleep")
	check_eq(dr.units, 0.0, "slept off")
	dr.free()


func test_a_whiskey_bought_poured_drunk_set_down_and_collected() -> void:
	await _valley()
	var p := _player()
	var bar := _bar()
	check(bar != null, "saloon B's bar has its service")
	check(await _at_bar(), "at the bar, before the barkeep (%s)" % bar.report())
	var cents := p.purse.cents
	var from := said.size()
	var o := p.drink.order(&"whiskey")
	check(o.ok, "a whiskey ordered (%s)" % o)
	check_eq(p.purse.cents, cents - 15, "fifteen cents taken")
	check(_said_line("bar.serve.whiskey", from, bar.barkeep()), "he answers at once in his words (%s)" % [said.slice(from)])
	var glass := await _wait_pour()
	check(glass != null and glass.kit_id == &"shot_glass", "a real shot glass set out (%s)" % bar.report())
	if glass == null:
		return
	check_near(glass.litres_in(), 0.044, 0.001, "a shot poured into it")
	var poured: Array = bar.log.filter(func(e: Dictionary) -> bool: return e.get("what", "") == "poured")
	var from_bottle := "" if poured.is_empty() else String(poured[-1].bottle)
	check(from_bottle.begins_with("liquor") or from_bottle == "whiskey_bottle", "poured from a real bottle of the kit (%s)" % [poured])
	var to_bar := glass.global_position - bar.barkeep().global_position
	var kp := bar._bar() as KitProp
	check(Vector2(to_bar.x, to_bar.z).length() < 1.6 and absf(glass.global_position.y - p.global_position.y) < 1.4, "on the bar between you (glass %s, you %s, him %s, bar %s %s)" % [glass.global_position, p.global_position, bar.barkeep().global_position, kp.global_transform, PropKit.bounds(kp.definition)])
	check(valley.folk.regard.deeds.get(&"barkeep", {}).has("bought"), "the barkeep keeps a paying man")
	# Picked up, a shot down in one.
	await _look_at(glass)
	check(p.drink.vessel_here() == glass, "the glass is yours to pick up")
	check(p.drink.take(glass), "taken up")
	check(glass.held and glass.get_parent().get_parent() == p.camera, "in your hand under the camera")
	check(glass.body.collision_layer == 0, "its body off while held")
	check(p.drink.sip(), "raised to drink")
	await wait_until(func() -> bool: return p.drink._sip_t < 0.0, 120)
	check_near(glass.litres_in(), 0.0, 0.0001, "a shot down in one")
	check(p.drink.gut > 0.9, "a drink's worth in you (%.2f)" % p.drink.gut)
	# Set down on the bar, and collected once it's stood empty.
	p.rotation.y = atan2(-(glass.global_position - p.global_position).x, -(glass.global_position - p.global_position).z)
	check(p.drink.set_down(), "set down on the bar (%s)" % p.drink.report())
	check(not glass.held and glass.body.collision_layer != 0, "out of your hand, a body again")
	await physics_frames(20)
	check(not glass.loose and not glass.broken, "standing on the bar")
	bar.d["collect_s"] = 1.0
	var gone: WeakRef = weakref(glass)
	glass = null
	await wait_until(func() -> bool: return gone.get_ref() == null, 60 * 8)
	check(gone.get_ref() == null, "the barkeep collects the empty glass (%s)" % bar.report())


func test_no_money_a_gun_out_too_drunk_and_drunk_answered() -> void:
	await _valley()
	var p := _player()
	var bar := _bar()
	check(await _at_bar(), "at the bar")
	p.purse.cents = 3
	var from := said.size()
	var o := p.drink.order(&"whiskey")
	check(not o.ok and o.why == "money", "three cents won't buy a whiskey (%s)" % o)
	check(_said_line("bar.no_money", from, bar.barkeep()), "and he says so (%s)" % [said.slice(from)])
	check(bar.served.is_empty(), "nothing poured")
	p.purse.cents = 500
	p.give(&"revolver")
	p.select_weapon(p.revolver())
	await wait_until(func() -> bool: return p.drink.gun_out(), 120)
	from = said.size()
	o = p.drink.order(&"whiskey")
	check(not o.ok and o.why == "gun", "no drink for a man with a gun out (%s)" % o)
	check(_said_line("bar.gun", from, bar.barkeep()), "put it away, he says (%s)" % [said.slice(from)])
	p.revolver().put_away()
	await physics_frames(30)
	await _wait_pour()
	p.drink.units = 8.0
	from = said.size()
	o = p.drink.order(&"whiskey")
	check(not o.ok and o.why == "drunk", "not another drop past the cut-off (%s)" % o)
	check(_said_line("bar.cut_off", from, bar.barkeep()), "sleep it off (%s)" % [said.slice(from)])
	# Drunk (and stood at his bar): his word, his regard, and news.
	p.drink.units = 4.5
	from = said.size()
	await physics_frames(20)
	var drunk_logged := bar.log.any(func(e: Dictionary) -> bool: return e.get("what", "") == "drunk")
	check(drunk_logged, "drunk at the bar is answered (%s)" % bar.report())
	check(valley.folk.regard.deeds.get(&"barkeep", {}).has("drunk"), "the barkeep keeps it")
	var news := valley.folk.news
	var held := news.versions.get(&"barkeep", {}) as Dictionary
	check(held.values().any(func(v: Dictionary) -> bool: return v.get("bar", &"") == &"drunk"), "and it's news he holds")


func test_a_round_for_the_house_the_deputy_and_a_beer() -> void:
	await _valley()
	var p := _player()
	var bar := _bar()
	check(await _at_bar(), "at the bar")
	StoryState.set_fact("nolaw.deputy", true)
	var men := bar._room_men()
	check(men.size() >= 3, "men in the room (%d)" % men.size())
	var cents := p.purse.cents
	var from := said.size()
	var o := p.drink.order(&"round")
	check(o.ok, "a round stood (%s)" % o)
	check_eq(p.purse.cents, cents - int(PlayerPurse.data().round_cents) * (men.size() + 1), "a whiskey a man in the room, and yours")
	check(_said_line("bar.round", from, bar.barkeep()), "the barkeep calls it (%s)" % [said.slice(from)])
	await physics_frames(60 * 3)
	var thanked := bar.log.filter(func(e: Dictionary) -> bool: return e.get("what", "") == "thanks")
	check(not thanked.is_empty(), "a man thanks you (%s)" % bar.report())
	check(_said_line("bar.round.thanks", from), "in the script's words (%s)" % [said.slice(from)])
	var warm := 0
	for m: HumanBody in men:
		if valley.folk.regard.deeds.get(m.person_id, {}).has("round"):
			warm += 1
	check_eq(warm, men.size(), "every man in the room keeps the round")
	var told := 0
	for m: HumanBody in men:
		if (valley.folk.news.versions.get(m.person_id, {}) as Dictionary).values().any(func(v: Dictionary) -> bool: return v.get("bar", &"") == &"round"):
			told += 1
	check(told >= men.size() - 1, "a round is news the room holds (%d of %d)" % [told, men.size()])
	check(bar.log.any(func(e: Dictionary) -> bool: return e.get("what", "") == "deputy"), "the deputy drinking gets a word (%s)" % bar.report())
	check_eq(TownNews.kind_of({"dead": false, "down": false, "shots": 0, "bar": &"round", "rough": true}), &"bar", "the bar's own kind of news")
	# A beer: held E's order, from the tap into a schooner.
	await _wait_pour()
	var g: GlassProp = bar.served[-1]
	check(g.kit_id == &"shot_glass", "your own whiskey of the round")
	o = p.drink.order(&"beer")
	check(o.ok and o.cents == 5, "a beer, a nickel (%s)" % o)
	var beer := await _wait_pour()
	check(beer != null and beer.kit_id == &"schooner" and beer.litres_in() > 0.3, "a schooner drawn (%s)" % bar.report())
	check(String((bar.log.filter(func(e: Dictionary) -> bool: return e.get("what", "") == "poured"))[-1].bottle) == "tap", "from his tap")


func test_dropped_it_breaks_and_a_gun_drawn_drops_it() -> void:
	await _valley()
	var p := _player()
	var bar := _bar()
	check(await _at_bar(), "at the bar")
	p.drink.order(&"whiskey")
	var glass := await _wait_pour()
	await _look_at(glass)
	check(p.drink.take(glass), "taken up")
	var from := said.size()
	p.drink.drop()
	check(not glass.held and glass.loose, "let go of: falling")
	await wait_until(func() -> bool: return glass.broken, 120)
	check(glass.broken, "it breaks on the floor (from %.2f m)" % (p.camera.global_position.y - p.global_position.y))
	await physics_frames(5)
	check(_said_line("bar.broke", from, bar.barkeep()), "and the barkeep has a word (%s)" % [said.slice(from)])
	# Another, and the gun drawn drops it.
	p.drink.order(&"whiskey")
	var g2 := await _wait_pour()
	await _look_at(g2)
	check(p.drink.take(g2), "another taken up")
	p.give(&"revolver")
	p.select_weapon(p.revolver())
	await wait_until(func() -> bool: return not p.drink.holding(), 120)
	check(not p.drink.holding() and p.drink.last == &"dropped", "the gun drawn: the glass dropped (%s)" % p.drink.report())


func test_the_card_table_stake_comes_from_the_purse() -> void:
	await _valley()
	var p := _player()
	var g := valley.folk.cards
	var cents := p.purse.cents
	var ch := valley.folk.props["chair_s"] as KitProp
	p.global_position = Seating.spot(ch) - ch.global_basis.z * 0.5
	p.velocity = Vector3.ZERO
	var to := ch.global_basis.z
	p.rotation.y = atan2(-to.x, -to.z)
	await physics_frames(2)
	p.seat.use()
	await physics_frames(30)
	check(p.seat.seated(), "sat at the table")
	var chip := int(PlayerPurse.data().chip_cents)
	check_eq(int(g.stacks.get(CardGame.YOU, 0)), 20, "twenty chips")
	check_eq(p.purse.cents, cents - 20 * chip, "bought with your money")
	g.stacks[CardGame.YOU] = 31  # won some
	p.seat.use()
	await physics_frames(10)
	check(not p.seat.seated(), "up")
	check_eq(p.purse.cents, cents - 20 * chip + 31 * chip, "cashed out to your purse")
	check_eq(int(g.stacks.get(CardGame.YOU, 0)), 0, "no chips left at the table")
