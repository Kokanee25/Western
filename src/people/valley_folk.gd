class_name ValleyFolk
extends Node3D
## The valley town's people (#756, No Law step 1; docs/missions/BUILD_ORDER.md 0.3): the valley has
## no TownLife (it needs the old town's buildings and places), so its townsfolk come from
## config/valley_folk.json: who's in town when, where each stands or sits, the props they need.
##
## Sean's B on #755 (the saloon waits for #695's week): the saloon is a grey block, so tonight's set
## is in its yard (saloon_annex): a kit bar with the barkeep behind it and two men drinking at it, a
## card table with two men sat at it and two chairs free, lit oil lamps on the bar and the table.
##
## Each man is a CivilianBrain at a post (unarmed townsfolk: hands up, cower, thanks, the fire), the
## card players held in their chairs by a SitChore. They find their way by the folk's own places
## (`places`: the town's ways, ValleyTown.add_ways, and the set's few): a route over the valley's
## thousand places would search them all (FarmhouseMission keeps its own for the same reason).
## In town for their `hours`: with the clock running into them, a man walks in from his `from`
## place; set past it (a jump, starting at night) he's at his post already. Past the end of his
## hours he walks back to his `from` and is gone. Built while the valley loads and kept out of the
## world till they're wanted (TownLife's riders, #488: a Studio man built in play is a long frame).

const DATA := "res://config/valley_folk.json"
## `-- --no-folk`: the valley without them (the bench's before).
static var folk_default := not "--no-folk" in OS.get_cmdline_user_args()
## How often the clock is read (s).
const LOOK_EVERY := 0.5
## This near his way out (m), a man leaving is gone.
const GONE_AT := 1.6
## A man sent off who hasn't got out in this long (s) is taken out anyway (stuck on something).
const GONE_ANYWAY := 240.0

var layout: ValleyLayout
var town: ValleyTown
var data: Dictionary
## The folk's own places: the town's ways and the set's (nolaw_*).
var places: Waypoints
## In the world, by id.
var people := {}
## The set's props: "bar", "table", "chair_<n|e|s|w>", "lamp_<i>", "cup_<i>".
var props := {}
## The card game at the set's table (CardGame, #766).
var cards: CardGame
## Built and out of the world till wanted (id -> HumanBody).
var _waiting := {}
## id -> &"out", &"coming", &"in", &"going".
var state := {}
var _going_for := {}
var _last_hour := NAN
var _look := 0.0
var _clock: DayCycle
var build_ms := {}


func _init() -> void:
	name = "Folk"


func _ready() -> void:
	add_to_group(&"valley_folk")
	if layout == null:
		layout = ValleyLayout.main()
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var u := Time.get_ticks_usec()
	places = Waypoints.new()
	if town:
		town.add_ways(places)
	_add_set_places()
	build_ms["places"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	_build_set()
	build_ms["set"] = (Time.get_ticks_usec() - u) / 1000.0
	for p: Dictionary in data.people:
		state[StringName(p.id)] = &"out"
	_prebuild.call_deferred()


func _notification(what: int) -> void:
	# Men still waiting are nobody's children: they go with the valley.
	if what == NOTIFICATION_PREDELETE:
		for man: HumanBody in _waiting.values():
			if is_instance_valid(man) and not man.is_inside_tree():
				man.free()
		_waiting.clear()


# --- Where things are ---------------------------------------------------------------------------

## A point of a lot: `a` m east of its west side, `b` m back from the street front, on the ground
## (`up` over it).
func lot_point(lot_id: String, a: float, b: float, up := 0.0) -> Vector3:
	var lot := layout.lot(lot_id)
	var north := layout.lots("north").any(func(l: Dictionary) -> bool: return String(l.id) == lot_id)
	var front := float((layout.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	var x := float(lot.get("x0", 0.0)) + a
	var z := (-1.0 if north else 1.0) * (front + b)
	return Vector3(x, ground(x, z) + up, z)


## What a man stands on there: the town's walks, else the ground.
func ground(x: float, z: float) -> float:
	if town:
		return town.surface(x, z)
	return ValleyTerrain.main().height(x, z)


func _set_point(at: Array, up := 0.0) -> Vector3:
	return lot_point(String(data.set.lot), float(at[0]), float(at[1]), up)


## The set's own places, each linked as the data says (and to the nearest of the town's).
func _add_set_places() -> void:
	var own: Dictionary = data.get("places", {})
	var town_names := places.points.keys()
	for n: String in own:
		if n.begins_with("_"):
			continue
		var d: Dictionary = own[n]
		var at := _set_point(d.at, 0.05)
		var links: Array = []
		for l: String in d.get("links", []):
			if places.has(StringName(l)):
				links.append(StringName(l))
		if d.get("nearest", false):
			var best := &""
			var best_d := INF
			for t: StringName in town_names:
				var dd := (places.at(t) as Vector3).distance_to(at)
				if dd < best_d:
					best_d = dd
					best = t
			if best != &"" and not links.has(best):
				links.append(best)
		places.add(StringName(n), at, links)


# --- The set: the bar, the card table, the lamps -----------------------------------------------

func _build_set() -> void:
	var s: Dictionary = data.set
	var bar := PropKit.make(&"bar")
	bar.name = "FolkBar"
	bar.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(s.bar.get("yaw", 90.0)))), _set_point(s.bar.at))
	add_child(bar)
	props["bar"] = bar
	var table := PropKit.make(&"card_table")
	table.name = "FolkCardTable"
	var tc := _set_point(s.table.at)
	table.transform = Transform3D(Basis(), tc)
	add_child(table)
	props["table"] = table
	var dirs := {"n": Vector3(0, 0, -1), "e": Vector3(1, 0, 0), "s": Vector3(0, 0, 1), "w": Vector3(-1, 0, 0)}
	for c: String in s.get("chairs", []):
		var d: Vector3 = dirs[c]
		var at := tc + d * float(s.get("chair_out", 0.78))
		at.y = ground(at.x, at.z)
		var chair := PropKit.make(&"chair")
		chair.name = "FolkChair_%s" % c
		# A chair faces +Z (you sit looking +Z): to the table.
		chair.transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.z)), at)
		add_child(chair)
		props["chair_" + c] = chair
	# The card game at the table (#766): whoever's sat in its chairs, the player dealt in.
	cards = CardGame.new()
	cards.table = table
	for c: String in s.get("chairs", []):
		cards.chairs.append(props["chair_" + c])
	cards.rng.seed = int(s.get("cards_seed", 766))
	add_child(cards)
	var i := 0
	for l: Dictionary in s.get("lamps", []):
		var lamp := OilLamp.new()
		lamp.name = "FolkLamp%d" % i
		lamp.lit_from_hour = 17
		lamp.lit_until_hour = 4
		lamp.energy = 1.2
		lamp.light_range = 7.0
		lamp.position = top_point(String(l.on), float(l.get("along", 0.0)), l.get("off", [0.0, 0.0]))
		add_child(lamp)
		props["lamp_%d" % i] = lamp
		i += 1
	i = 0
	for c: Dictionary in s.get("cups", []):
		var cup := PropKit.make(&"tin_cup")
		cup.name = "FolkCup%d" % i
		cup.transform = Transform3D(Basis(Vector3.UP, float(i) * 1.3), top_point(String(c.on), float(c.get("along", 0.0)), c.get("off", [0.0, 0.0])) + Vector3.UP * 0.005)
		add_child(cup)
		props["cup_%d" % i] = cup
		i += 1


## The kit prop's box (its own space).
static func _bounds(prop: Node3D) -> AABB:
	var kp := prop as KitProp
	return PropKit.bounds(kp.definition) if kp else AABB()


## A point on the top of the bar (`along` its length, + to the north) or the table (`off` [x, z]).
func top_point(on: String, along: float, off: Array) -> Vector3:
	var prop: Node3D = props[on]
	var b := _bounds(prop)
	var t := prop.transform
	if on == "bar":
		# The top's middle across its depth, a hand in from the customers' edge.
		return t * Vector3(along * -1.0 if t.basis.x.z > 0.0 else along, b.end.y, b.get_center().z + 0.05)
	return t * Vector3(float(off[0]), b.end.y, float(off[1]))


## Where a man stands or sits (`post` in the data), and the point he faces there.
func post_of(p: Dictionary) -> Array:
	var post: Dictionary = p.post
	if post.has("chair"):
		var chair := props.get("chair_" + String(post.chair)) as KitProp
		return [Seating.spot(chair), Seating.faces(chair)]
	var bar: Node3D = props[String(post.get("behind", post.get("at_bar", "bar")))]
	var b := _bounds(bar)
	var t := bar.transform
	# The bar's length is its own x; along + runs north (as top_point).
	var along := float(post.get("along", 0.0)) * (-1.0 if t.basis.x.z > 0.0 else 1.0)
	var behind := post.has("behind")
	var z := (b.position.z - 0.45) if behind else (b.end.z + 0.42)
	var at := t * Vector3(along, 0.0, z)
	at.y = ground(at.x, at.z) + 0.05
	var look := t * Vector3(along, 0.0, z + (2.0 if behind else -2.0))
	look.y = at.y + (1.4 if behind else 1.1)
	return [at, look]


# --- The people ------------------------------------------------------------------------------

func _person(id: StringName) -> Dictionary:
	for p: Dictionary in data.people:
		if StringName(p.id) == id:
			return p
	return {}


static func _colour(a: Array) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)


func _make(p: Dictionary) -> HumanBody:
	var man := HumanBody.new()
	man.body_model = StringName(p.get("model", "outlaw"))
	man.person_id = StringName(p.id)
	man.name = String(p.get("name", p.id))
	man.rng_seed = int(p.get("seed", 1))
	man.has_gun = false
	man.shirt_color = _colour(p.get("shirt", [0.8, 0.78, 0.7]))
	man.vest_color = _colour(p.get("vest", [0, 0, 0, 0]))
	man.hat_color = Color(0, 0, 0, 0)
	man.bandana_color = Color(0, 0, 0, 0)
	return man


## Where he comes in from and goes back out to.
func way_out(p: Dictionary) -> Vector3:
	var n := StringName(String(p.get("from", "")))
	return places.at(n) if places.has(n) else post_of(p)[0]


## Everyone built while the valley loads, put in the world and straight out again (no frame
## passes with them in it), to wait for their hours.
func _prebuild() -> void:
	if not is_inside_tree():
		return
	var u := Time.get_ticks_usec()
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		if people.has(id) or _waiting.has(id):
			continue
		var man := _make(p)
		var at := way_out(p)
		man.enter(get_parent(), at, 0.0)
		get_parent().remove_child(man)
		_waiting[id] = man
	build_ms["men"] = (Time.get_ticks_usec() - u) / 1000.0
	_look = 0.0
	_step(0.0)


## Into the world: at his post, or (`walk`) at his way in, walking to it.
func _bring(p: Dictionary, walk: bool) -> HumanBody:
	var id := StringName(p.id)
	var man: HumanBody = _waiting.get(id)
	_waiting.erase(id)
	if man != null and not is_instance_valid(man):
		man = null
	if man == null:
		man = _make(p)
	var pf := post_of(p)
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = pf[0]
	brain.faces = pf[1]
	brain.places = places
	var chair: KitProp = props.get("chair_" + String((p.post as Dictionary).get("chair", "")))
	if chair != null:
		brain.chores = [SitChore.new(man, chair)]
	man.add_child(brain)
	man.move_child(brain, 0)
	var at: Vector3 = way_out(p) if walk else pf[0]
	man.enter(get_parent(), at, HumanBody.yaw_toward(at, pf[0] if walk else pf[1]))
	people[id] = man
	state[id] = &"coming" if walk else &"in"
	return man


## Out of town: up from his chair and back the way he came (`walk`), or gone at once.
func _send_off(id: StringName, walk: bool) -> void:
	var man: HumanBody = people.get(id)
	if man == null or not is_instance_valid(man):
		people.erase(id)
		state[id] = &"out"
		return
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if not walk or brain == null or not man.physiology.alive or man.limp:
		_gone(id)
		return
	for c: RefCounted in brain.chores:
		if c is SitChore:
			(c as SitChore).wanted = false
	brain.go_to(way_out(_person(id)))
	state[id] = &"going"
	_going_for[id] = 0.0


func _gone(id: StringName) -> void:
	var man: HumanBody = people.get(id)
	people.erase(id)
	state[id] = &"out"
	_going_for.erase(id)
	if man != null and is_instance_valid(man):
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain
		if brain:
			for c: RefCounted in brain.chores:
				if c is SitChore and (c as SitChore).chair and is_instance_valid((c as SitChore).chair):
					Seating.stand_up(man, (c as SitChore).chair)
		man.queue_free()


# --- The clock ---------------------------------------------------------------------------------

## In [from, to) on the clock (past midnight when to < from).
static func in_hours(h: float, hours: Array) -> bool:
	var a := float(hours[0])
	var b := float(hours[1])
	return (h >= a and h < b) if a <= b else (h >= a or h < b)


## Hours since `a` on a 24-hour clock (0 to 24).
static func since(h: float, a: float) -> float:
	return fposmod(h - a, 24.0)


func hour() -> float:
	if _clock == null or not is_instance_valid(_clock):
		_clock = get_parent().find_child("DayCycle", false, false) as DayCycle if get_parent() else null
	return _clock.time_of_day if _clock else 12.0


func _process(delta: float) -> void:
	var t := Prof.start()
	_step(delta)
	Prof.stop(&"valley_folk", t)


func _step(delta: float) -> void:
	for id: StringName in _going_for.keys():
		_going_for[id] += delta
		var man: HumanBody = people.get(id)
		if man == null or not is_instance_valid(man) or _going_for[id] > GONE_ANYWAY:
			_gone(id)
			continue
		var out := way_out(_person(id))
		if Vector2(man.global_position.x - out.x, man.global_position.z - out.z).length() < GONE_AT:
			_gone(id)
	_look -= delta
	if _look > 0.0 or _waiting.is_empty() and people.is_empty() and not _ready_once():
		return
	_look = LOOK_EVERY
	var h := hour()
	var walk_h := float(data.get("walk_in_h", 0.5))
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		var hours: Array = p.hours
		var want := in_hours(h, hours)
		var was := not is_nan(_last_hour) and in_hours(_last_hour, hours)
		var st: StringName = state.get(id, &"out")
		if want and st == &"out":
			# The clock ran into his hours while we watched: he walks in. Else he's there.
			_bring(p, not is_nan(_last_hour) and not was and since(h, float(hours[0])) <= walk_h)
		elif not want and st in [&"coming", &"in"]:
			_send_off(id, was and since(h, float(hours[1])) <= walk_h)
		elif st == &"going" and (want or since(h, float(hours[1])) > walk_h):
			_gone(id)  # the clock jumped on while he was on his way out: gone (back in, he's brought again)
		elif st == &"coming":
			var man: HumanBody = people.get(id)
			if man != null and is_instance_valid(man) and man.global_position.distance_to(post_of(p)[0]) < 1.0:
				state[id] = &"in"
	_last_hour = h


func _ready_once() -> bool:
	return build_ms.has("men")


## Who's where, for the bridge and the tests: {id: {state, at, seated, pose}}.
func report() -> Dictionary:
	var out := {}
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		var man: HumanBody = people.get(id)
		var d := {"state": String(state.get(id, &"out"))}
		if man != null and is_instance_valid(man):
			var post: Vector3 = post_of(p)[0]
			d["at"] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.y, 0.01), snappedf(man.global_position.z, 0.01)]
			d["from_post"] = snappedf(Vector2(man.global_position.x - post.x, man.global_position.z - post.z).length(), 0.01)
			var chair: KitProp = props.get("chair_" + String((p.post as Dictionary).get("chair", "")))
			d["seated"] = chair != null and chair.seated == man
		out[String(id)] = d
	return out
