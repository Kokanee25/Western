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
## A man with an `act` (No Law's red shirt and the stranger, #773) has no hours: he's built with the
## rest and waits till that act `take`s him. A dead man stays where he lies (state &"dead"), and a
## man sent off by an act (`send_off`) stays gone for the rest of his hours.
##
## No Law's murder (NoLawMurder, config/moments/no_law_murder.json) is started from here: on the
## first night (no `nolaw.murder` in StoryState) at its `hour`, or sooner once you've played its
## `after_hands` hands at the table; `-- --no-murder` (or `murder_auto` false: the card game's tests)
## leaves it out, and No Law's morning after with it.
##
## The morning after (#796; the data's `morning`): the murder done and the clock come round to the
## day, `nolaw.morning`; Earl's body taken to the undertaker's once you're off it (a recorded death:
## nolaw.earl = undertaker, death.earl, gone from the world for good); the day folk at their posts
## on the walks (`post.lot`) say the town's version of it when you pass (`talk`: lines by the story's
## facts); from `sheriff_from` the dying sheriff's scene (SheriffDies) starts, once.

const DATA := "res://config/valley_folk.json"
## `-- --no-folk`: the valley without them (the bench's before).
static var folk_default := not "--no-folk" in OS.get_cmdline_user_args()
## The band in the yard (#799; `-- --no-band`: not).
static var band_default := not "--no-band" in OS.get_cmdline_user_args()
## No Law's murder started by the clock and the card game (`-- --no-murder`: not).
static var murder_auto := not "--no-murder" in OS.get_cmdline_user_args()
const MURDER := &"no_law_murder"
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
## The set's props: "bar", "table", "chair_<n|e|s|w>", "lamp_<i>", "cup_<i>", "piano", "chair_piano".
var props := {}
## The band (Band, #799), when it plays on the set's lot.
var band: Band
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
## Sent off by an act for the rest of his hours (id -> true): not brought back till they're over.
var kept_out := {}
## No Law's murder, once started (NoLawMurder), and the hands you've played at the table.
var murder: Moment
var _murder_data := {}
## A murder over before it played (no Cody): not tried again before this physics frame.
var _murder_again := 0
var _your_hands := 0
## Gone for good (Earl to the undertaker's): never brought back (id -> true).
var gone_for_good := {}
## The dying sheriff's scene, once started (SheriffDies).
var sheriff_scene: Moment
## What the day folk have said (`talk`): [id, line id, text], and when each last spoke.
var heard: Array = []
var _spoke_at := {}
var _said_n := {}


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
	_build_band()
	cards.hand_done.connect(func(_w: String, _p: int, _h: String) -> void:
		if cards.report().get("seats", []).any(func(x: Dictionary) -> bool: return String(x.get("id", "")) == CardGame.YOU):
			_your_hands += 1)
	var mpath := "res://config/moments/%s.json" % MURDER
	if FileAccess.file_exists(mpath):
		_murder_data = JSON.parse_string(FileAccess.get_file_as_string(mpath))
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
	return point_of_lot(layout, town, lot_id, a, b, up)


## `lot_point` for any valley town (ValleyWorld's wake spots too); `b` under 0 is out on its walk.
static func point_of_lot(l: ValleyLayout, t: ValleyTown, lot_id: String, a: float, b: float, up := 0.0) -> Vector3:
	var lot := l.lot(lot_id)
	var north := l.lots("north").any(func(x: Dictionary) -> bool: return String(x.id) == lot_id)
	var front := float((l.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	var x := float(lot.get("x0", 0.0)) + a
	var z := (-1.0 if north else 1.0) * (front + b)
	return Vector3(x, surface_of(t, x, z) + up, z)


## What a man stands on there: the town's walks, else the ground.
func ground(x: float, z: float) -> float:
	return surface_of(town, x, z)


static func surface_of(t: ValleyTown, x: float, z: float) -> float:
	if t:
		return t.surface(x, z)
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
	# The band's piano (#799; config/band.json): the kit's upright against the saloon's east wall,
	# its keys to the yard, a chair before it for the pianist ("chair_piano").
	var pd: Dictionary = s.get("piano", {})
	if not pd.is_empty() and PropKit.has(&"upright_piano"):
		var piano := PropKit.make(&"upright_piano")
		piano.name = "FolkPiano"
		var pc := _set_point(pd.at)
		var pb := Basis(Vector3.UP, deg_to_rad(float(pd.get("yaw", 90.0))))
		piano.transform = Transform3D(pb, pc)
		add_child(piano)
		props["piano"] = piano
		var d := pb.z
		var at := pc + d * float(pd.get("chair_out", 0.75))
		at.y = ground(at.x, at.z)
		var stool := PropKit.make(&"chair")
		stool.name = "FolkChair_piano"
		stool.transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.z)), at)
		add_child(stool)
		props["chair_piano"] = stool
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


## The band (#799, config/band.json) when it plays on this set's lot: its players' men are folk
## with a `plays` (PlayChore), its other parts placed sound only.
func _build_band() -> void:
	if not band_default or not FileAccess.file_exists(Band.DATA):
		return
	var bd: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Band.DATA))
	if String(bd.get("lot", "")) != String(data.set.get("lot", "")):
		return
	band = Band.new()
	band.data = bd
	band.folk = self
	add_child(band)


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
	if post.has("lot"):
		# Stood on a lot's walk or ground ([a, b] as lot_point's), facing `faces` (else the street).
		var at_a: Array = post.at
		var lot_id := String(post.lot)
		var at := lot_point(lot_id, float(at_a[0]), float(at_a[1]), 0.05)
		var fa: Array = post.get("faces", [float(at_a[0]), float(at_a[1]) - 6.0])
		var look := lot_point(lot_id, float(fa[0]), float(fa[1]))
		look.y = at.y + 1.5
		return [at, look]
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
	man.has_gun = bool(p.get("gun", false))
	man.start_holstered = true
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
	var sit: SitChore = SitChore.new(man, chair) if chair != null else null
	if p.has("plays") and band != null:
		# A player in the band (#799): at his instrument, his part sounds; his hands follow it.
		brain.chores = [PlayChore.new(man, band, StringName(p.plays), sit, props.get(String(p.get("instrument", ""))))]
	elif sit != null:
		brain.chores = [sit]
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
	if not man.physiology.alive:
		state[id] = &"dead"  # his body stays where it lies (No Law: Earl's, #773)
		return
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if not walk or brain == null or man.limp:
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
	_ran += delta
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
		if p.has("act") or gone_for_good.has(id):
			continue
		var hours: Array = p.hours
		var want := in_hours(h, hours)
		if kept_out.has(id):
			if want:
				continue
			kept_out.erase(id)
		var here: HumanBody = people.get(id)
		if here != null and is_instance_valid(here) and not here.physiology.alive and state.get(id) in [&"coming", &"in", &"going"]:
			state[id] = &"dead"
			_going_for.erase(id)
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
	_maybe_murder(h)
	_morning_step(h)
	_talk_step()


func _ready_once() -> bool:
	return build_ms.has("men")


# --- The acts' men and No Law's murder -----------------------------------------------------------

## An act's man (`act` in the data, no hours) into the world at `at`, facing `faces`: no brain, the
## act moves him. Null if he isn't one or he's out already.
func take(id: StringName, at: Vector3, faces: Vector3) -> HumanBody:
	var p := _person(id)
	if p.is_empty() or not p.has("act") or (people.has(id) and is_instance_valid(people[id])):
		return null
	var man: HumanBody = _waiting.get(id)
	_waiting.erase(id)
	if man == null or not is_instance_valid(man):
		man = _make(p)
	man.enter(get_parent(), at, HumanBody.yaw_toward(at, faces))
	people[id] = man
	state[id] = &"act"
	return man


## An act's man out of the world (he's walked off).
func release(id: StringName) -> void:
	var man: HumanBody = people.get(id)
	people.erase(id)
	state[id] = &"out"
	if man != null and is_instance_valid(man):
		man.queue_free()


## Up and away for the rest of his hours (an act's: No Law's drifter and miner after the shot): he
## walks back out the way he came and isn't brought back till his hours are over.
func send_off(id: StringName) -> void:
	if not state.get(id, &"out") in [&"coming", &"in"]:
		return
	kept_out[id] = true
	_send_off(id, true)


## The folk man by id in the world, or null.
func folk_man(id: StringName) -> HumanBody:
	var m: HumanBody = people.get(id)
	return m if m != null and is_instance_valid(m) else null


## Is it time for No Law's murder? The first night (StoryState has no nolaw.murder), Earl sat at the
## table, and the clock at its `hour` (to its `until`), or from `earliest` once you've played its
## `after_hands` hands there.
func _maybe_murder(h: float) -> void:
	if not murder_auto or _murder_data.is_empty() or StoryState.has_fact("nolaw.murder"):
		return
	if murder != null and is_instance_valid(murder):
		if not murder.done:
			return
		# Over before Cody came in (it wrote nothing): freed, and tried again a minute on (#864).
		murder.reset()
		murder = null
		_murder_again = Engine.get_physics_frames() + 60 * Engine.physics_ticks_per_second
	if Engine.get_physics_frames() < _murder_again:
		return
	var d := _murder_data
	var until := float(d.get("until", 2.0))
	var at_hour := in_hours(h, [float(d.get("hour", 22.0)), until])
	var played := _your_hands >= int(d.get("after_hands", 1)) and in_hours(h, [float(d.get("earliest", 20.0)), until])
	if not at_hour and not played:
		return
	var earl := folk_man(StringName(d.get("cheater", "earl")))
	var chair := props.get("chair_" + String(d.get("chair", "w"))) as KitProp
	if earl == null or chair == null or chair.seated != earl or state.get(StringName(d.get("cheater", "earl"))) != &"in":
		return
	start_murder()


## No Law's murder now (the clock, the card game, or the bridge's `moment no_law_murder`).
func start_murder(options := {}) -> Moment:
	murder = Moment.start_named(MURDER, get_parent() as Node3D, null, options)
	return murder


# --- No Law's morning after (#796) --------------------------------------------------------------

## The murder done and the clock round to the day: the morning; Earl to the undertaker's once
## you're off him; the dying sheriff's scene from its hour.
func _morning_step(h: float) -> void:
	var md: Dictionary = data.get("morning", {})
	if md.is_empty() or not murder_auto:
		return
	if not StoryState.has_fact("nolaw.morning"):
		if StoryState.get_fact("nolaw.murder") != "done" or not in_hours(h, md.get("hours", [5.0, 19.5])):
			return
		_story("nolaw.morning", true)
	if state.get(&"earl") == &"dead" and not gone_for_good.has(&"earl"):
		var earl := folk_man(&"earl")
		if earl == null or not _you_see(_body_at(earl), float(md.get("unseen_m", 30.0))):
			to_undertaker(&"earl")
	if (sheriff_scene == null or not is_instance_valid(sheriff_scene)) and not StoryState.has_fact("nolaw.sheriff") \
			and in_hours(h, [float(md.get("sheriff_from", 7.5)), float((md.get("hours", [5.0, 19.5]) as Array)[1])]):
		start_sheriff_dies()


## Earl's body (any of the dead) taken from where he lies to the undertaker's: out of the world
## for good, and a recorded death (StoryState death.<id>; nolaw.earl = undertaker).
func to_undertaker(id: StringName) -> void:
	gone_for_good[id] = true
	var man := folk_man(id)
	people.erase(id)
	state[id] = &"buried"
	if man != null:
		man.queue_free()
	if id == &"earl":
		_story("nolaw.earl", "undertaker")
		_story("death.earl", String((data.get("morning", {}) as Dictionary).get("earl_death", "Earl, shot.")))


## The dying sheriff's scene now (the clock, or the bridge's `moment sheriff_dies`).
func start_sheriff_dies(options := {}) -> Moment:
	sheriff_scene = Moment.start_named(&"sheriff_dies", get_parent() as Node3D, null, options)
	return sheriff_scene


func _story(key: String, value: Variant) -> void:
	var c := _clock if _clock and is_instance_valid(_clock) else null
	StoryState.set_fact(key, value, c.day if c else 1, hour())


## A dead man's body's middle (his pelvis, limp).
static func _body_at(man: HumanBody) -> Vector3:
	var pelvis := man.parts.get(&"pelvis") as Node3D
	return pelvis.global_position if pelvis else man.global_position


## You're within `m` of `at` with it in front of you.
func _you_see(at: Vector3, m: float) -> bool:
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return false
	var to := at - p.global_position
	if to.length() > m:
		return false
	var fwd := p.get_forward()
	fwd.y = 0.0
	to.y = 0.0
	return to.length() < 2.0 or fwd.normalized().dot(to.normalized()) > 0.0


# --- What the day folk say when you pass (`talk`) -------------------------------------------------

## Does the story hold `cond` ({fact: value | [values] | "*"; "!fact": anything = not set})?
static func story_holds(cond: Dictionary) -> bool:
	for k: String in cond:
		if k.begins_with("_"):
			continue
		if k.begins_with("!"):
			if StoryState.has_fact(k.substr(1)):
				return false
			continue
		if not StoryState.has_fact(k):
			return false
		var want: Variant = cond[k]
		var have: Variant = StoryState.get_fact(k)
		if want is String and want == "*":
			continue
		if want is Array:
			if not (want as Array).has(have):
				return false
		elif typeof(want) != typeof(have) or want != have:
			return false
	return true


## The line the set `set_id` has for now ([entry id, text]), the words in turn; [] if none.
func line_for(set_id: String) -> Array:
	var talk: Dictionary = data.get("talk", {})
	for e: Dictionary in (talk.get("sets", {}) as Dictionary).get(set_id, []):
		if not story_holds(e.get("if", {})):
			continue
		var eid := String(e.id)
		var n := int(_said_n.get(eid, 0))
		var words: Array = e.get("words", [])
		if words.is_empty() or (e.get("once", false) and n > 0):
			continue
		return [eid, String(words[n % words.size()])]
	return []


func _talk_step() -> void:
	var talk: Dictionary = data.get("talk", {})
	if talk.is_empty():
		return
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p == null:
		return
	for pd: Dictionary in data.people:
		if not pd.has("says"):
			continue
		var id := StringName(pd.id)
		var man := folk_man(id)
		if man == null or state.get(id) != &"in" or not man.physiology.is_conscious():
			continue
		if man.global_position.distance_to(p.global_position) > float(talk.get("near_m", 4.0)):
			continue
		if _spoke_at.has(id) and _talk_clock() - float(_spoke_at[id]) < float(talk.get("gap_s", 20.0)):
			continue
		var l := line_for(String(pd.says))
		if l.is_empty():
			continue
		_said_n[l[0]] = int(_said_n.get(l[0], 0)) + 1
		_spoke_at[id] = _talk_clock()
		man.face(p.global_position + Vector3.UP * 1.5)
		Events.spoke.emit(man, String(l[1]))
		heard.append([String(id), String(l[0]), String(l[1])])


## Game seconds the folk have run (their talk's gaps).
var _ran := 0.0


func _talk_clock() -> float:
	return _ran


## Who's where, for the bridge and the tests: {id: {state, at, seated, pose}}.
func report() -> Dictionary:
	var out := {}
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		var man: HumanBody = people.get(id)
		var d := {"state": String(state.get(id, &"out"))}
		if man != null and is_instance_valid(man) and p.has("act"):
			d["at"] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.y, 0.01), snappedf(man.global_position.z, 0.01)]
			d["alive"] = man.physiology.alive
		elif man != null and is_instance_valid(man):
			var post: Vector3 = post_of(p)[0]
			d["at"] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.y, 0.01), snappedf(man.global_position.z, 0.01)]
			d["from_post"] = snappedf(Vector2(man.global_position.x - post.x, man.global_position.z - post.z).length(), 0.01)
			var chair: KitProp = props.get("chair_" + String((p.post as Dictionary).get("chair", "")))
			d["seated"] = chair != null and chair.seated == man
			d["alive"] = man.physiology.alive
		out[String(id)] = d
	return out
