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
## Each man lives by a `day` (townsfolk step 2, #870; docs/briefs/townsfolk.md §3): blocks by the
## hour, each at a named spot (`spots`) or in a place, which puts him on the book (TownBook: indoors,
## asleep, out of town; a row, no body), a list a day kind (`calendar`: Sunday, payday; the story's by
## its facts). With the clock running into a block he walks there by the ways: out of his door, to his
## spot or in at the next door; set past it (a jump, starting at night) he's there already. Nobody
## comes out of a door or goes in at one where you can see it (`seen`). The book shows from the street
## (BookLights: lit windows after dark, chimney smoke at meals). Built while the valley loads and kept
## out of the world till they're wanted (TownLife's riders, #488: a Studio man built in play is a long
## frame). A new person is one entry in the data.
## A man with an `act` (No Law's Cody and the stranger, #773) has no day: he's built with the
## rest and waits till that act `take`s him. A dead man stays where he lies (state &"dead"), and a
## man sent off by an act (`send_off`) stays home for the rest of his block.
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
##
## The funeral (#868; config/moments/funeral.json): the day after the sheriff dies, in its `hours`,
## Funeral starts, once; before it the day folk say when it is (`nolaw.funeral_due`: tomorrow,
## today); the clock past its hours without it, it's missed (started `over`: the grave filled).
## Its mourners are the folk's own: the day folk, its act men, and the night's men borrowed while
## they wait out of town (`borrow`, `give_back`).

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
## The valley's spec buildings by lot id (ValleyWorld.buildings): a place, a spot or a prop can be
## in one (`hall` + `local` [x, y, z] in its own space, or `use`: its spec's use point), #938.
var halls := {}
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
## Going in at a place's door: id -> [place, what he'll do there].
var _going_to := {}
## The book (TownBook): who's indoors, asleep or out of town, not bodies; and the street's show of
## it (BookLights: lit windows, chimney smoke).
var book: TownBook
var lights: BookLights
## The block each man's on (block_key), and who's due to move on to his (his door in your view).
var _key := {}
var _due := {}
## Every body in or out by the day, and whether you could see it ([hour, id, in|out, seen, cut]).
var view_log: Array = []
var _last_hour := NAN
var _look := 0.0
var _clock: DayCycle
var build_ms := {}
## Sent off by an act for the rest of his block (id -> his block_key): not brought back till it changes.
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
## The funeral, once started (Funeral), and its data.
var funeral: Moment
var _funeral_data := {}
## What the day folk have said (`talk`): [id, line id, text], and when each last spoke.
var heard: Array = []
## Running for help (townsfolk step 6, FetchHelp): who runs for the doctor or the law, the doctor's
## calls; every man brought gets it (`CivilianBrain.fetch`).
var fetch: FetchHelp
var _spoke_at := {}
var _said_n := {}
## A door banged on (PlayerKnock, #1057): the place, who's in it on the book (heard it), who banged
## and where. An act answers it (No Law's carry: the doctor); `knocks` keeps them [frame, place, ids].
signal knocked(place: StringName, inside: Array, by: Node, at: Vector3)
var knocks: Array = []
## Set by an act that answers the knock it's just been told of (`claim_knock`, in its `knocked`
## handler): else the town answers it itself (the doctor's door: FetchHelp.at_door, #1095).
var knock_claimed := false
## The dead laid out where they were left for the night (No Law: Earl in the doctor's front room,
## #1057): id -> {place, at, sheet}. The undertaker takes them from there (`to_undertaker`).
var laid := {}
## No Law's carry (NoLawCarry, #1057): Earl alive after the murder, his body to the doctor's.
var carry_act: Moment
const CARRY := &"no_law_carry"


func _init() -> void:
	name = "Folk"


func _ready() -> void:
	add_to_group(&"valley_folk")
	add_to_group(&"knock_doors")  # its places' doors (PlayerKnock)
	fetch = FetchHelp.new(self)
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
	_build_seats()
	build_ms["set"] = (Time.get_ticks_usec() - u) / 1000.0
	_build_band()
	cards.hand_done.connect(func(_w: String, _p: int, _h: String) -> void:
		if cards.report().get("seats", []).any(func(x: Dictionary) -> bool: return String(x.get("id", "")) == CardGame.YOU):
			_your_hands += 1)
	var mpath := "res://config/moments/%s.json" % MURDER
	if FileAccess.file_exists(mpath):
		_murder_data = JSON.parse_string(FileAccess.get_file_as_string(mpath))
	var fpath := "res://config/moments/funeral.json"
	if FileAccess.file_exists(fpath):
		_funeral_data = JSON.parse_string(FileAccess.get_file_as_string(fpath))
	for p: Dictionary in data.people:
		state[StringName(p.id)] = &"out"
	book = TownBook.from_data(data.get("book", {}))
	lights = BookLights.new()
	lights.folk = self
	add_child(lights)
	lights.build(buildings())
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
		# A place in another lot (`lot`: a lot with no walk has no door of its own), else in the set's.
		var at: Vector3
		if d.has("hall"):
			# In a spec building (#938: saloon B's stair, hall, wing and stage): none, no place.
			if not halls.has(String(d.hall)):
				continue
			at = hall_point(String(d.hall), d.local, 0.05)
		elif d.has("lot"):
			at = lot_point(String(d.lot), float(d.at[0]), float(d.at[1]), 0.05)
		else:
			at = _set_point(d.at, 0.05)
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
		# Up a stair to these (its ramp carries him; a level sweep would meet its treads).
		for l: String in d.get("stair_to", []):
			if places.has(StringName(l)):
				places.link(StringName(n), StringName(l))
				places.mark_stair(StringName(n), StringName(l))


## A point in a spec building's own space (`local` [x, y, z]: x, the floor's height y, z as its
## spec's), `up` over it; a `local` y under 0.05 is the ground's there (outside, in its yard).
func hall_point(lot_id: String, local: Array, up := 0.0) -> Vector3:
	var b: Node3D = halls.get(lot_id)
	if b == null or not is_instance_valid(b):
		return Vector3.INF
	var p := b.global_transform * Vector3(float(local[0]), float(local[1]), float(local[2]))
	if float(local[1]) < 0.05:
		p.y = ground(p.x, p.z)
	return p + Vector3.UP * up


## A spec building's use point (its spec's `use_points` by id): [where, the point it faces (2 m
## along its `facing`, +Z at 0 as a chair's), its local spot]; [] if there's none.
func hall_use(lot_id: String, id: String) -> Array:
	var b: Node3D = halls.get(lot_id)
	if b == null or not is_instance_valid(b):
		return []
	for u: Dictionary in (b.get(&"spec") as Dictionary).get("use_points", []):
		if String(u.get("id", "")) == id and u.has("at"):
			var f := deg_to_rad(float(u.get("facing", 0.0)))
			var at: Array = u.at
			var ahead := [float(at[0]) + sin(f) * 2.0, float(at[1]), float(at[2]) + cos(f) * 2.0]
			return [hall_point(lot_id, at), hall_point(lot_id, ahead), at]
	return []


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
	# Payday Night's second upright on saloon B's stage (#938, Sean on #938: the dance hall keeps its
	# own piano), `hall` + `local` in the building's space, `yaw` its own.
	for key: String in ["piano", "stage_piano"]:
		_build_piano(key, s.get(key, {}))
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


## A piano (the kit's upright) and its player's chair `chair_out` before its keys: on the set's lot
## (`at` [a, b], `yaw` in the world) or in a spec building (`hall`, `local`, `yaw` in its space).
## props `key` and "chair_" + key.
func _build_piano(key: String, pd: Dictionary) -> void:
	if pd.is_empty() or not PropKit.has(&"upright_piano"):
		return
	var pc: Vector3
	var pb := Basis(Vector3.UP, deg_to_rad(float(pd.get("yaw", 90.0))))
	if pd.has("hall"):
		var b: Node3D = halls.get(String(pd.hall))
		if b == null or not is_instance_valid(b):
			return
		pc = hall_point(String(pd.hall), pd.local)
		pb = b.global_basis.orthonormalized() * pb
	else:
		pc = _set_point(pd.at)
	var piano := PropKit.make(&"upright_piano")
	piano.name = "Folk_" + key
	piano.transform = Transform3D(pb, pc)
	add_child(piano)
	props[key] = piano
	var d := pb.z
	var at := pc + d * float(pd.get("chair_out", 0.75))
	if not pd.has("hall"):
		at.y = ground(at.x, at.z)
	var stool := PropKit.make(&"chair")
	stool.name = "FolkChair_" + key
	stool.transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.z)), at)
	add_child(stool)
	props["chair_" + key] = stool


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


## Where a man stands or sits at a spot (`spots` in the data, or one given inline), and the point
## he faces there.
func spot_point(post: Dictionary) -> Array:
	if post.has("hall"):
		# In a spec building (#938): its use point (`use`), or `local` facing `faces` (local [x, z]).
		var lot_id := String(post.hall)
		if post.has("use"):
			var u := hall_use(lot_id, String(post.use))
			if not u.is_empty():
				# `shift` [x, z] in its space off the use point (a way round what's been put by it).
				var sh: Array = post.get("shift", [0.0, 0.0])
				var b: Node3D = halls[lot_id]
				var d := b.global_basis * Vector3(float(sh[0]), 0.0, float(sh[1]))
				return [(u[0] as Vector3) + d + Vector3.UP * 0.05, (u[1] as Vector3) + d + Vector3.UP * 1.5]
		var l: Array = post.get("local", [0.0, 0.0, 0.0])
		var fa: Array = post.get("faces", [float(l[0]), float(l[2]) - 2.0])
		var at := hall_point(lot_id, l, 0.05)
		return [at, hall_point(lot_id, [fa[0], l[1], fa[1]], 1.5)]
	if post.has("chair"):
		var chair := props.get("chair_" + String(post.chair)) as KitProp
		return [Seating.spot(chair), Seating.faces(chair)]
	if post.get("_seat") is KitProp and is_instance_valid(post._seat):
		var seat: KitProp = post._seat
		return [Seating.spot(seat), Seating.faces(seat)]
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


## A spot by name (`spots`), or the block's own inline one.
func spot(at: Variant) -> Dictionary:
	if at is Dictionary:
		return at
	return (data.get("spots", {}) as Dictionary).get(String(at), {})


## His spot now: his block's, else the first spot in his day (where he'd be when he's out).
func spot_of(p: Dictionary) -> Dictionary:
	if p.has("post"):
		return p.post
	var b := block_now(p, hour())
	if b.has("at"):
		return spot(b.at)
	for x: Dictionary in blocks_of(p, day_kind(town_day())):
		if x.has("at"):
			return spot(x.at)
	return {}


## Where he stands or sits now (his spot's point), and the point he faces there.
func post_of(p: Dictionary) -> Array:
	return spot_point(spot_of(p))


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
	# Played by a private man when he's laid in (#933, config/private_cast.json), re-dressed.
	man.body_model = PeopleBodies.cast_model(man.person_id, man.body_model)
	PeopleBodies.cast_dress(man, man.person_id)
	return man


## A place's door: where a man goes in at it and comes out of it (his own spot, if there's no such
## place).
func door(place: StringName, p := {}) -> Vector3:
	if places.has(place):
		return places.at(place)
	return post_of(p)[0] if not p.is_empty() else Vector3.ZERO


## His home (`home`, else the act men's `from`): where he's built and goes when nothing says.
static func home_of(p: Dictionary) -> StringName:
	return StringName(String(p.get("home", p.get("from", ""))))


## His dials, each 0 to 1 (townsfolk brief section 2): `nerve` (stays when frightened), `nosy` (comes to
## look), `duty` (helps, fetches, tells): his CivilianBrain's Reaction decides by them (townsfolk step
## 5); a man with none gets the middle.
static func dials_of(p: Dictionary) -> Dictionary:
	var d: Dictionary = p.get("dials", {})
	return {"nerve": float(d.get("nerve", 0.5)), "nosy": float(d.get("nosy", 0.5)), "duty": float(d.get("duty", 0.5))}


## Where he'd run from trouble (Reaction's flee): his own door, then the town's open doors, the
## store, the saloon and the hotel (the brief §4, "Doors").
const REFUGES: Array[StringName] = [&"general_store", &"saloon", &"hotel"]


func refuges_of(p: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for place: StringName in [home_of(p)] + REFUGES:
		if places != null and places.has(place):
			var d := places.at(place)
			if not out.has(d):
				out.append(d)
	return out


## The door he's on his way in at (going), else his block's, else his home's.
func way_out(p: Dictionary) -> Vector3:
	return door(_going_place(p), p)


func _going_place(p: Dictionary) -> StringName:
	var id := StringName(p.id)
	if _going_to.has(id):
		return StringName(_going_to[id][0])
	if p.has("day"):
		var b := block_now(p, hour())
		if b.has("in"):
			return StringName(String(b.in))
	return home_of(p)


## Where he comes out from: his row on the book, else his home.
func _book_place(p: Dictionary) -> StringName:
	var r := book.row(StringName(p.id))
	return StringName(r.in) if not r.is_empty() else home_of(p)


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
		var at := door(home_of(p), p)
		man.enter(get_parent(), at, 0.0)
		get_parent().remove_child(man)
		_waiting[id] = man
	build_ms["men"] = (Time.get_ticks_usec() - u) / 1000.0
	_look = 0.0
	_step(0.0)


## Into the world: at his spot, or (`walk`) out of `from_place`'s door, walking to it. Off the book.
func _bring(p: Dictionary, walk: bool, from_place := &"") -> HumanBody:
	var id := StringName(p.id)
	var man: HumanBody = _waiting.get(id)
	_waiting.erase(id)
	if man != null and not is_instance_valid(man):
		man = null
	if man == null:
		man = _make(p)
	var sp := spot_of(p)
	var pf := spot_point(sp) if not sp.is_empty() else [door(home_of(p)), door(home_of(p)) + Vector3.FORWARD]
	var brain := CivilianBrain.new()
	brain.name = "Brain"
	brain.post = pf[0]
	brain.faces = pf[1]
	brain.places = places
	brain.dials = dials_of(p)
	brain.refuges = refuges_of(p)
	brain.fetch = fetch
	brain.chores = _chores_for(man, p, sp)
	man.add_child(brain)
	man.move_child(brain, 0)
	var from := door(from_place if from_place != &"" else _book_place(p), p)
	var at: Vector3 = from if walk else pf[0]
	man.enter(get_parent(), at, HumanBody.yaw_toward(at, pf[0] if walk else pf[1]))
	people[id] = man
	state[id] = &"coming" if walk else &"in"
	book.take(id)
	_log_view(id, "in", at, not walk)
	return man


## What he does at a spot: sat in its chair (SitChore), a player in the band (#799) at his
## instrument, his part sounding, his hands following it (PlayChore); else his block's `do` there
## (SpotChore's kinds: lean, sit, counter, sweep, carry, talk, drink, work; `stand` and anything
## else, a stand with its breaks), townsfolk step 4 (#957).
func _chores_for(man: HumanBody, p: Dictionary, sp: Dictionary, doing := &"") -> Array:
	var chair: KitProp = props.get("chair_" + String(sp.get("chair", "")))
	var sit: SitChore = SitChore.new(man, chair) if chair != null else null
	if p.has("plays") and band != null:
		# The instrument the spot names (#938: the stage's piano on Payday), else his own.
		var inst := String(sp.get("instrument", p.get("instrument", "")))
		return [PlayChore.new(man, band, StringName(p.plays), sit, props.get(inst))]
	if sit != null:
		return [sit]
	if sp.is_empty():
		return []
	if doing == &"":
		doing = _doing_now(p)
	var pf := spot_point(sp)
	var extra := spot_extras(sp)
	var c := SpotChore.new(man, doing if SpotChore.KINDS.has(doing) else &"stand", pf[0], pf[1], extra)
	if c.kind == &"sit":
		var seat: KitProp = sp.get("_seat")
		if seat == null or not is_instance_valid(seat):
			c = SpotChore.new(man, &"stand", pf[0], pf[1], extra)
		else:
			c.sit = SitChore.new(man, seat)
	return [c]


## His block's `do` now, at a spot (else `stand`).
func _doing_now(p: Dictionary) -> StringName:
	if p.has("post"):
		return StringName(String(p.get("do", "stand")))
	var b := block_now(p, hour())
	return StringName(String(b.get("do", "stand"))) if b.has("at") else &"stand"


## A spot's data for its chore, with its points worked out: `top` (the bar's top before a man behind
## it or at it), `to_at` (where a carry's pile goes: `to` [a, b] on the spot's lot).
func spot_extras(sp: Dictionary) -> Dictionary:
	var out := sp.duplicate()
	out.erase("_seat")
	if (sp.has("behind") or sp.has("at_bar")) and props.has(String(sp.get("behind", sp.get("at_bar", "bar")))):
		out["top"] = top_point(String(sp.get("behind", sp.get("at_bar", "bar"))), float(sp.get("along", 0.0)), [0.0, 0.0])
	if sp.has("lot") and sp.has("to"):
		var to: Array = sp.to
		out["to_at"] = lot_point(String(sp.lot), float(to[0]), float(to[1]), 0.05)
	return out


## The seats the street's `sit` spots name (`seat`: a kit prop, the chair), stood on the spot
## facing its `faces` (townsfolk step 4). Kept on the spot (`_seat`) for its sitter.
func _build_seats() -> void:
	for k: String in data.get("spots", {}):
		if not data.spots[k] is Dictionary:
			continue
		var sp: Dictionary = data.spots[k]
		if not sp.has("seat") or not sp.has("lot") or not PropKit.has(StringName(String(sp.seat))):
			continue
		var at_a: Array = sp.at
		var at := lot_point(String(sp.lot), float(at_a[0]), float(at_a[1]))
		var fa: Array = sp.get("faces", [float(at_a[0]), float(at_a[1]) - 6.0])
		var f := lot_point(String(sp.lot), float(fa[0]), float(fa[1])) - at
		var seat := PropKit.make(StringName(String(sp.seat)))
		seat.name = "FolkSeat_%s" % k
		seat.transform = Transform3D(Basis(Vector3.UP, atan2(f.x, f.z)), at)
		add_child(seat)
		props["seat_" + k] = seat
		sp["_seat"] = seat


## Out of town or indoors: up from his chair and off to his door (`walk`), or gone at once (onto the
## book there).
func _send_off(id: StringName, walk: bool) -> void:
	var man: HumanBody = people.get(id)
	if man == null or not is_instance_valid(man):
		people.erase(id)
		state[id] = &"out"
		return
	if not man.physiology.alive:
		state[id] = &"dead"  # his body stays where it lies (No Law: Earl's, #773)
		return
	if man.dragged_by != null:
		return  # carried or dragged (PlayerCarry, #1081): with whoever has him, not off home
	var p := _person(id)
	if not _going_to.has(id):
		_going_to[id] = [_going_place(p), _doing_at(p, _going_place(p))]
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if not walk or brain == null or man.limp:
		_gone(id, true)
		return
	_stand_up(brain)
	brain.go_to(way_out(p))
	state[id] = &"going"
	_going_for[id] = 0.0


## The same spot, another block: if it does something else there (stand, then lean), the new chore.
func _new_doing(man: HumanBody, brain: CivilianBrain, p: Dictionary, b: Dictionary) -> void:
	var doing := StringName(String(b.get("do", "stand")))
	for c: RefCounted in brain.chores:
		if c is SpotChore and (c as SpotChore).kind == (doing if SpotChore.KINDS.has(doing) else &"stand"):
			return
		if not c is SpotChore:
			return  # (a chair's or a player's: as it was)
	_stand_up(brain)
	brain.chores = _chores_for(man, p, spot_of(p), doing)
	brain.chore = null


func _stand_up(brain: CivilianBrain) -> void:
	for c: RefCounted in brain.chores:
		if c is SitChore:
			(c as SitChore).wanted = false
		elif c is SpotChore:
			(c as SpotChore).leave()


## What he does in at `place` by his day: the next block there's, else home.
func _doing_at(p: Dictionary, place: StringName) -> StringName:
	if p.has("day"):
		var b := block_now(p, hour())
		if b.has("in") and StringName(String(b.in)) == place:
			return StringName(String(b.get("do", "home")))
	return &"home"


## Out of the world: in at the door he was going to (onto the book), or (an act's man, the dead)
## just gone. `cut`: the clock jumped (he's not watched going).
func _gone(id: StringName, cut := false) -> void:
	var man: HumanBody = people.get(id)
	if man != null and is_instance_valid(man) and man.dragged_by != null:
		return  # carried or dragged (PlayerCarry, #1081): he stays with whoever has him, seen or not
	people.erase(id)
	state[id] = &"out"
	_going_for.erase(id)
	var to: Array = _going_to.get(id, [])
	_going_to.erase(id)
	var p := _person(id)
	if p.has("day") and (man == null or not is_instance_valid(man) or man.physiology.alive):
		var place: StringName = StringName(to[0]) if not to.is_empty() else _going_place(p)
		book.put(id, place, StringName(to[1]) if not to.is_empty() else _doing_at(p, place))
	if man != null and is_instance_valid(man):
		_log_view(id, "out", man.global_position, cut)
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain
		if brain:
			for c: RefCounted in brain.chores:
				if c is SitChore and (c as SitChore).chair and is_instance_valid((c as SitChore).chair):
					Seating.stand_up(man, (c as SitChore).chair)
				elif c is SpotChore:
					(c as SpotChore).leave()
					var sc: SitChore = (c as SpotChore).sit
					if sc and sc.chair and is_instance_valid(sc.chair):
						Seating.stand_up(man, sc.chair)
		man.queue_free()


# --- Seen from where you stand (nothing appears or vanishes in view) ---------------------------

## Could you see this point now: in the camera's view, nearer than the book's `seen_m`, nothing of
## the world between? No camera (a lab): never.
func seen(at: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return false
	var eye := cam.global_position
	var d := eye.distance_to(at)
	if d > float((data.get("book", {}) as Dictionary).get("seen_m", 120.0)):
		return false
	if d < 1.0:
		return true
	if not cam.is_position_in_frustum(at):
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, at, Layers.WORLD)
	var pl := get_tree().get_first_node_in_group(&"player") as CollisionObject3D
	if pl:
		q.exclude = [pl.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


## A man (his feet, his head) or a door (where he'd stand in it) seen.
func seen_man_at(at: Vector3) -> bool:
	return seen(at + Vector3.UP * 0.4) or seen(at + Vector3.UP * 1.6)


## Every body put in the world or taken out of it by the day: [hour, id, "in"|"out", seen, cut]
## (cut: the clock jumped, a load or a sleep: not watched). The nothing-in-view check reads it.
func _log_view(id: StringName, what: String, at: Vector3, cut: bool) -> void:
	view_log.append([snappedf(hour(), 0.01), String(id), what, seen_man_at(at), cut])
	if view_log.size() > 400:
		view_log.pop_front()


# --- The day ----------------------------------------------------------------------------------

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


## The town's day: the clock's, but a night past midnight (before the calendar's `starts_h`) still
## the day before's.
func town_day() -> int:
	hour()
	var d := _clock.day if _clock else 1
	return d - 1 if hour() < float((data.get("calendar", {}) as Dictionary).get("starts_h", 5.0)) else d


## The kind of day the town has (`calendar.kinds`, the first that holds; else ordinary).
func day_kind(d: int) -> StringName:
	if d < 1:
		return &"ordinary"  # before the game's first day (its first night set back past midnight)
	for k: Dictionary in (data.get("calendar", {}) as Dictionary).get("kinds", []):
		if k.has("week_day") and posmod(d, 7) != int(k.week_day):
			continue
		if k.has("every") and posmod(d - int(k.get("first", 0)), int(k.every)) != 0:
			continue
		if k.has("if") and not story_holds(k.get("if")):
			continue
		return StringName(String(k.id))
	return &"ordinary"


## His blocks on a kind of day (every kind's, if his day is one list), in order of their hours.
static func blocks_of(p: Dictionary, kind: StringName) -> Array:
	var d: Variant = p.get("day", [])
	if d is Dictionary:
		d = (d as Dictionary).get(String(kind), (d as Dictionary).get("ordinary", []))
	return d


## The block he's in at `h` (the town's kind of day now, unless `kind`): the last to start at or
## before it, else (before the first) the day's last, run round. With `key`: what makes it this one.
func block_now(p: Dictionary, h: float, kind := &"") -> Dictionary:
	var bl := blocks_of(p, kind if kind != &"" else day_kind(town_day()))
	if bl.is_empty():
		return {}
	var best: Dictionary = bl[bl.size() - 1]
	for b: Dictionary in bl:
		if float(b.from) <= h:
			best = b
	return best


static func block_key(b: Dictionary) -> String:
	return "%s|%s|%s" % [String(b.get("in", "")), str(b.get("at", "")), String(b.get("do", ""))]


func _process(delta: float) -> void:
	var t := Prof.start()
	_step(delta)
	Prof.stop(&"valley_folk", t)


func _step(delta: float) -> void:
	_ran += delta
	if fetch:
		fetch.step(delta)
	for id: StringName in _going_for.keys():
		_going_for[id] += delta
		var man: HumanBody = people.get(id)
		if man == null or not is_instance_valid(man):
			_gone(id)
			continue
		var out := way_out(_person(id))
		var there := Vector2(man.global_position.x - out.x, man.global_position.z - out.z).length() < GONE_AT
		# In at his door (or, stuck on the way, off where he stands) once you can't see him go.
		if (there or _going_for[id] > GONE_ANYWAY) and not seen_man_at(man.global_position):
			_gone(id)
	_look -= delta
	if _look > 0.0 or _waiting.is_empty() and people.is_empty() and not _ready_once():
		return
	_look = LOOK_EVERY
	var h := hour()
	var walk_h := float(data.get("walk_in_h", 0.5))
	# The clock set on further than a walk's window (a load, a sleep, the bridge's `time`), or back:
	# a cut, everyone where his day says, but a man whose block began within the window, who walks
	# (as the clock running into it while you watched).
	var jumped := is_nan(_last_hour) or since(h, _last_hour) > walk_h
	var kind := day_kind(town_day())
	# One truth (#1095): the story has Earl at the undertaker's (a mission started past No Law's night
	# sets it), so his day never brings him back to the cards.
	if not gone_for_good.has(&"earl") and StoryState.get_fact("nolaw.earl", "") == "undertaker" and not _person(&"earl").is_empty():
		to_undertaker(&"earl")
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		if p.has("act") or gone_for_good.has(id) or not p.has("day"):
			continue
		var b := block_now(p, h, kind)
		if b.is_empty():
			continue
		var here: HumanBody = people.get(id)
		if here != null and is_instance_valid(here) and not here.physiology.alive and state.get(id) in [&"coming", &"in", &"going", &"called"]:
			state[id] = &"dead"
			_going_for.erase(id)
			_going_to.erase(id)
			book.take(id)
		if state.get(id) == &"dead":
			continue
		if state.get(id) == &"act":
			book.take(id)  # an act has him (the funeral's mourners): his day waits till it gives him back
			continue
		if state.get(id) == &"called":
			continue  # called out (the doctor to a man down, FetchHelp): his day waits till he's done
		var key := block_key(b)
		if kept_out.has(id):
			if kept_out[id] == key:
				continue
			kept_out.erase(id)
		var changed: bool = _key.get(id, "") != key
		var first := not _key.has(id)
		_key[id] = key
		# He walks on to a new block if the clock ran into it, or jumped to just past its start while
		# he was settled (not already on his way somewhere).
		var walk_now: bool = changed and (not jumped or (since(h, float(b.from)) <= walk_h
				and not state.get(id) in [&"coming", &"going"]))
		if first or (jumped and not walk_now):
			_due.erase(id)
			_place(p, b)
		elif walk_now or _due.has(id):
			if _move(p, b):
				_due.erase(id)
			else:
				_due[id] = true  # his door's in your view: he waits behind it
		elif b.has("in") and state.get(id) == &"out":
			# On the book: his doing by the hour (asleep, at supper), or his row again once an act's
			# given him back.
			book.put(id, StringName(String(b.in)), StringName(String(b.get("do", "home"))))
		if state.get(id) == &"coming":
			var man: HumanBody = people.get(id)
			if man != null and is_instance_valid(man) and man.global_position.distance_to(post_of(p)[0]) < 1.0:
				state[id] = &"in"
	_last_hour = h
	if lights:
		lights.show_book(book, h)
	_maybe_murder(h)
	_carry_step()
	_morning_step(h)
	_funeral_step(h)
	_talk_step()


## Where his block puts him, at once (the clock jumped: nobody's watching it happen).
func _place(p: Dictionary, b: Dictionary) -> void:
	var id := StringName(p.id)
	var st: StringName = state.get(id, &"out")
	var held: HumanBody = people.get(id)
	if held != null and is_instance_valid(held) and held.dragged_by != null:
		return  # carried or dragged (#1081): he stays with whoever has him
	if b.has("in"):
		var place := StringName(String(b.in))
		if st in [&"coming", &"in", &"going"]:
			_going_to[id] = [place, StringName(String(b.get("do", "home")))]
			_gone(id, true)
		else:
			book.put(id, place, StringName(String(b.get("do", "home"))))
		return
	if st == &"going":
		_gone(id, true)  # (back in his block's spot: brought again)
		st = &"out"
	if st == &"out":
		_bring(p, false)
	elif st in [&"coming", &"in"]:
		var man: HumanBody = people.get(id)
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain if man else null
		var pf := post_of(p)
		if brain != null and brain.post.distance_to(pf[0]) > 0.3:
			_gone(id, true)  # another spot: there at once
			_bring(p, false)
		elif brain != null:
			_new_doing(man, brain, p, b)


## On to his block by walking (the clock ran into it while you watched): out of a door, to a spot or
## in at another door. False while the door he'd come out of is in your view (he waits).
func _move(p: Dictionary, b: Dictionary) -> bool:
	var id := StringName(p.id)
	var st: StringName = state.get(id, &"out")
	if b.has("in"):
		var place := StringName(String(b.in))
		var doing := StringName(String(b.get("do", "home")))
		if st in [&"coming", &"in", &"going"]:
			_going_to[id] = [place, doing]
			if st == &"going":
				var brain := (people[id] as HumanBody).get_node_or_null(^"Brain") as CivilianBrain
				if brain:
					brain.go_to(door(place, p))
			else:
				_send_off(id, true)
			return true
		var at := _book_place(p)
		if at == place:
			book.put(id, place, doing)
			return true
		# From one door to another across the street: out of this one when it's not seen.
		if seen_man_at(door(at, p)):
			return false
		_bring(p, true, at)
		_going_to[id] = [place, doing]
		_send_off(id, true)
		return true
	var pf := post_of(p)
	if st in [&"coming", &"in", &"going"]:
		var man: HumanBody = people[id]
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain
		_going_to.erase(id)
		_going_for.erase(id)
		if brain and brain.post.distance_to(pf[0]) > 0.3:
			_stand_up(brain)
			brain.go_to(pf[0], pf[1])
			brain.chores = _chores_for(man, p, spot_of(p), StringName(String(b.get("do", "stand"))))
			brain.chore = null  # (else the old one, still set, joins the new list)
			state[id] = &"coming"
		else:
			if st == &"going":
				state[id] = &"coming"
			if brain:
				_new_doing(man, brain, p, b)
		return true
	var from := _book_place(p)
	if seen_man_at(door(from, p)):
		return false
	_bring(p, true, from)
	return true


## Every place anyone's day takes him in at (homes too).
func buildings() -> Array:
	var out := []
	for p: Dictionary in data.people:
		if not p.has("day"):
			continue
		var all: Array = [home_of(p)]
		var d: Variant = p.day
		for bl: Array in ((d as Dictionary).values() if d is Dictionary else [d]):
			for b: Dictionary in bl:
				if b.has("in"):
					all.append(StringName(String(b.in)))
		for x: StringName in all:
			if not out.has(x):
				out.append(x)
	return out


func _ready_once() -> bool:
	return build_ms.has("men")


# --- The acts' men and No Law's murder -----------------------------------------------------------

## An act's man (`act` in the data, no hours) into the world at `at`, facing `faces`: no brain, the
## act moves him. Null if he isn't one or he's out already. A day man (the doctor, #1095: one man,
## in by the town's book, in every scene) is taken off his day the same way (`seize`).
func take(id: StringName, at: Vector3, faces: Vector3) -> HumanBody:
	var p := _person(id)
	if not p.is_empty() and not p.has("act"):
		return seize(id, at, faces)
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


## A day man taken off his day for an act (#1095: the doctor in SheriffDies, No Justice's office, the
## funeral): from the book (borrowed) or, out in the world already, his brain taken off him and moved
## to `at`. Null if he's dead, gone or an act has him.
func seize(id: StringName, at: Vector3, faces: Vector3) -> HumanBody:
	var p := _person(id)
	if p.is_empty() or p.has("act") or gone_for_good.has(id) or state.get(id) in [&"dead", &"act"]:
		return null
	var man := folk_man(id)
	if man == null:
		man = borrow(id, at, faces)
		if man == null and not _waiting.has(id) and state.get(id, &"out") == &"out":
			man = _make(p)
			man.enter(get_parent(), at, HumanBody.yaw_toward(at, faces))
			people[id] = man
			state[id] = &"act"
		if man != null:
			book.take(id)
		return man
	if not man.physiology.alive or man.limp:
		return null
	_going_for.erase(id)
	_going_to.erase(id)
	_due.erase(id)
	kept_out.erase(id)
	if fetch:
		fetch.drop_calls(man)
	_strip_brain(man)
	man.set_pose(&"stand")
	man.global_position = at
	man.rotation.y = HumanBody.yaw_toward(at, faces)
	state[id] = &"act"
	book.take(id)
	return man


static func _strip_brain(man: HumanBody) -> void:
	for n: String in ["Brain", "Senses"]:
		var c := man.get_node_or_null(NodePath(n))
		if c:
			man.remove_child(c)
			c.free()


## An act's man out of the world (he's walked off). A day man goes back to his day (`give_back`).
func release(id: StringName) -> void:
	var man: HumanBody = people.get(id)
	if man != null and is_instance_valid(man) and man.dragged_by != null:
		return  # carried or dragged (#1081): not out of the world off someone's shoulder
	var p := _person(id)
	if not p.is_empty() and not p.has("act"):
		give_back(id)
		return
	people.erase(id)
	state[id] = &"out"
	if man != null and is_instance_valid(man):
		man.queue_free()


## A day man who's on the book now (the night's barkeep, by day), for an act: into the world
## at `at` as `take` does (no brain). Null if he's in town, dead or gone.
func borrow(id: StringName, at: Vector3, faces: Vector3) -> HumanBody:
	var p := _person(id)
	var man: HumanBody = _waiting.get(id)
	if p.is_empty() or p.has("act") or gone_for_good.has(id) or state.get(id, &"out") != &"out" \
			or man == null or not is_instance_valid(man):
		return null
	_waiting.erase(id)
	man.enter(get_parent(), at, HumanBody.yaw_toward(at, faces))
	people[id] = man
	state[id] = &"act"
	return man


## An act's man (taken or borrowed) out of the world and back to wait, as he was built (not freed:
## his hours, or the next act, bring him in with no long frame). The act's brain goes; a dead man
## stays where he lies.
func give_back(id: StringName) -> void:
	lends.erase(id)
	var man: HumanBody = people.get(id)
	if man == null or not is_instance_valid(man):
		people.erase(id)
		state[id] = &"out"
		return
	if not man.physiology.alive or man.limp:
		state[id] = &"dead"
		return
	people.erase(id)
	state[id] = &"out"
	_strip_brain(man)
	man.set_pose(&"stand")
	if man.get_parent():
		man.get_parent().remove_child(man)
	_waiting[id] = man
	if not _person(id).has("act"):
		_key[id] = ""  # a day man: his block anew, so a block out in town brings him out again


## Up and away for the rest of his block (an act's: No Law's drifter and miner after the shot): he
## walks home and isn't brought back till his day moves on to another block.
func send_off(id: StringName) -> void:
	if not state.get(id, &"out") in [&"coming", &"in"]:
		return
	kept_out[id] = _key.get(id, "")
	_send_off(id, true)


## The men an act holds but lends back to the town for its need (#1106: the doctor to a hurt man at
## his door): id -> the act's Callable, called (with the id) as he's lent, to let him go from its scene.
var lends := {}


## Lend an act's man back to the town (#1106): off the act's set and on the book in his own rooms
## (`home`), as a day man indoors, the act told (`lends`); from there the town has him (the doctor
## answers his door and comes out of it, as any day). True if he was the act's to lend.
func lend(id: StringName) -> bool:
	var man := folk_man(id)
	var p := _person(id)
	if man == null or p.is_empty() or p.has("act") or state.get(id) != &"act" or not man.physiology.alive or man.limp:
		return false
	var told: Callable = lends.get(id, Callable())
	lends.erase(id)
	if told.is_valid():
		told.call(id)
	give_back(id)
	book.put(id, home_of(p), _doing_at(p, home_of(p)))
	return true


## Where a runner finds the doctor (FetchHelp): his body if he's out in the world, else his door if
## the book has him indoors in town; {} if there's no doctor to fetch (dead, gone, an act has him,
## the dying sheriff's scene has the doctor's house).
func doctor_where() -> Dictionary:
	var id := FetchHelp.DOCTOR
	var p := _person(id)
	if p.is_empty() or gone_for_good.has(id) or state.get(id) in [&"dead", &"act"]:
		return {}
	if sheriff_scene != null and is_instance_valid(sheriff_scene) and not sheriff_scene.done:
		return {}
	var man := folk_man(id)
	if man != null and man.physiology.alive:
		return {"at": man.global_position, "man": man}
	if man != null:
		return {}
	var r := book.row(id)
	if r.is_empty() or not places.has(StringName(r.in)):
		return {}
	return {"at": door(StringName(r.in), p), "man": null}


## Called out of his day (the doctor to a man down): out of his door if he's in (seen or not: he's
## needed), his day held (`called`) till `call_over`. His body, or null.
func call_out(id: StringName) -> HumanBody:
	var p := _person(id)
	if p.is_empty() or state.get(id) in [&"dead", &"act"] or gone_for_good.has(id):
		return null
	var man := folk_man(id)
	if man == null:
		man = _bring(p, true, _book_place(p))
	_going_for.erase(id)
	_going_to.erase(id)
	kept_out.erase(id)
	state[id] = &"called"
	return man


## Done with what he was called for: back to his day (to wherever its block has him, walking).
func call_over(id: StringName) -> void:
	if state.get(id) != &"called":
		return
	state[id] = &"in"
	_key[id] = ""  # his block anew: he walks to it


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


## `-- --mission=no_law` (#1125): the first night set up, the clock at `hour` (before the murder's),
## you in the yard by the bar (`nolaw_yard_mid`) facing the card table: off the act's ways (on
## its front, the stranger's way in, the scene's hold broke on its first frame). The murder then comes by
## the clock or your hands at the table, as on any first night.
func set_up_no_law(hour: float) -> void:
	if _clock == null and get_parent():
		_clock = get_parent().find_child("DayCycle", false, false) as DayCycle
	if _clock:
		_clock.set_time(hour)
	var p := get_tree().get_first_node_in_group(&"player") as Player
	var table := props.get("table") as Node3D
	if p == null or table == null or not places.has(&"nolaw_yard_mid"):
		return
	var at := places.at(&"nolaw_yard_mid")
	at.y = ground(at.x, at.z) + 0.1
	p.global_position = at
	p.velocity = Vector3.ZERO
	var to := table.global_position - at
	p.rotation.y = atan2(-to.x, -to.z)


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
		# Laid out in the doctor's front room (#1057): there under his sheet till the sheriff's scene is
		# over (you pass him on the way in), then the undertaker's.
		var kept: bool = laid.has(&"earl") and StoryState.get_fact("nolaw.sheriff") != "dead"
		# Not off your shoulder (PlayerCarry, #1081): carried or dragged, he's with whoever has him,
		# seen or not (over your shoulder he's beside you, out of your view).
		kept = kept or (earl != null and earl.dragged_by != null)
		if not kept and (earl == null or not _you_see(_body_at(earl), float(md.get("unseen_m", 30.0)))):
			to_undertaker(&"earl")
	if (sheriff_scene == null or not is_instance_valid(sheriff_scene)) and not StoryState.has_fact("nolaw.sheriff") \
			and in_hours(h, [float(md.get("sheriff_from", 7.5)), float((md.get("hours", [5.0, 19.5]) as Array)[1])]):
		start_sheriff_dies()


## Earl's body (any of the dead) taken from where he lies to the undertaker's: out of the world
## for good, and a recorded death (StoryState death.<id>; nolaw.earl = undertaker).
func to_undertaker(id: StringName) -> void:
	gone_for_good[id] = true
	var lay: Dictionary = laid.get(id, {})
	laid.erase(id)
	if lay.get("sheet") != null and is_instance_valid(lay.sheet):
		(lay.sheet as Node).queue_free()
	var man := folk_man(id)
	people.erase(id)
	state[id] = &"buried"
	if man != null:
		man.queue_free()
	if id == &"earl":
		_story("nolaw.earl", "undertaker")
		var md: Dictionary = data.get("morning", {})
		_story("death.earl", String(md.get("earl_death_doctor" if lay.get("place", "") == "doctor" else "earl_death", md.get("earl_death", "Earl, shot."))))


# --- The funeral (#868) ---------------------------------------------------------------------------

## The sheriff dead: the day after (`days_after`), in its `hours`, the funeral; before then the
## folk know when (nolaw.funeral_due: tomorrow, today); past it unseen, it's missed.
func _funeral_step(h: float) -> void:
	var fd := _funeral_data
	if fd.is_empty() or not murder_auto or StoryState.has_fact("nolaw.funeral") or StoryState.get_fact("nolaw.sheriff") != "dead":
		return
	if funeral != null and is_instance_valid(funeral):
		return
	var died := int((StoryState.when.get("nolaw.sheriff", [1, 0.0]) as Array)[0])
	var due := died + int(fd.get("days_after", 1))
	var day := _clock.day if _clock and is_instance_valid(_clock) else 1
	var hours: Array = fd.get("hours", [10.0, 11.5])
	if day < due or (day == due and h < float(hours[0])):
		var when := "today" if day == due else ("tomorrow" if day == due - 1 else "later")
		if StoryState.get_fact("nolaw.funeral_due") != when:
			_story("nolaw.funeral_due", when)
	elif day == due and in_hours(h, hours):
		start_funeral()
	else:
		start_funeral({"over": true})


## The funeral now (the clock, or `-- --mission=funeral`; the bridge's `moment funeral` starts its own).
func start_funeral(options := {}) -> Moment:
	funeral = Moment.start_named(&"funeral", get_parent() as Node3D, null, options)
	return funeral


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


## Who's where, for the bridge and the tests: {id: {state, at, seated, from_post, block, book}}, and
## the town's day (`_day`: its number, kind, the lit windows and smoke).
func report() -> Dictionary:
	var out := {}
	for p: Dictionary in data.people:
		var id := StringName(p.id)
		var man: HumanBody = people.get(id)
		var d := {"state": String(state.get(id, &"out"))}
		if p.has("day"):
			var b := block_now(p, hour())
			d["block"] = "%s %s %s" % [b.get("from", ""), "at " + str(b.at) if b.has("at") else "in " + String(b.get("in", "")), b.get("do", "")]
			if book.has(id):
				d["book"] = book.report()[String(id)]
		if man != null and is_instance_valid(man) and p.has("act"):
			d["at"] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.y, 0.01), snappedf(man.global_position.z, 0.01)]
			d["alive"] = man.physiology.alive
		elif man != null and is_instance_valid(man):
			var post: Vector3 = post_of(p)[0]
			d["at"] = [snappedf(man.global_position.x, 0.01), snappedf(man.global_position.y, 0.01), snappedf(man.global_position.z, 0.01)]
			d["from_post"] = snappedf(Vector2(man.global_position.x - post.x, man.global_position.z - post.z).length(), 0.01)
			var chair: KitProp = props.get("chair_" + String(spot_of(p).get("chair", "")))
			d["seated"] = chair != null and chair.seated == man
			d["alive"] = man.physiology.alive
		out[String(id)] = d
	out["_day"] = {"day": town_day(), "kind": String(day_kind(town_day())), "shows": lights.report() if lights else {}}
	return out


# --- Doors banged on (PlayerKnock, #1057) -----------------------------------------------------------

## Every place someone lives or goes in at (homes and their day's `in`), with a door point.
func door_places() -> Array[StringName]:
	if not _door_places.is_empty():
		return _door_places
	var out: Array[StringName] = []
	for p: Dictionary in data.people:
		var names: Array = [String(p.get("home", ""))]
		for k: String in ["day", "sunday"]:
			for b: Variant in p.get(k, []):
				if b is Dictionary and (b as Dictionary).has("in"):
					names.append(String(b["in"]))
		for n: String in names:
			var pn := StringName(n)
			if n != "" and places.has(pn) and not out.has(pn):
				out.append(pn)
	_door_places = out
	return out
var _door_places: Array[StringName] = []


## The door you're at (PlayerKnock): the nearest door point within `reach` (flat, a storey's height)
## in front of you; {} if none.
func door_near(at: Vector3, fwd: Vector3, reach: float) -> Dictionary:
	var best := {}
	var best_d := reach
	for pn: StringName in door_places():
		if no_knock(pn):
			continue
		var d_at := places.at(pn)
		var to := d_at - at
		if absf(to.y) > 1.6:
			continue
		to.y = 0.0
		var d := to.length()
		if d > best_d:
			continue
		if d > 0.6 and fwd.length() > 0.01 and rad_to_deg(fwd.angle_to(to / d)) > 75.0:
			continue
		if past_door(pn, at):
			continue  # in at it already (#1095: the prompt showed in the doorway)
		best = {"place": pn, "at": d_at}
		best_d = d
	if not best.is_empty():
		# Worth banging on (#1095): someone in on the book, or a hurt man by it to bring in.
		best["heard"] = not book.inside(best.place).is_empty()
		best["hurt"] = not best.heard and hurt_by_door(best.place, null) != null
	return best


## A place with no door to bang on (#1095: the saloon's set is its open yard): `no_knock` in the data.
func no_knock(place: StringName) -> bool:
	return (data.get("no_knock", []) as Array).has(String(place))


## In past `place`'s door point (its building's way in, +z in the valley's spec buildings) by more
## than `PAST_DOOR` m: in the doorway or the room, not at the door.
func past_door(place: StringName, at: Vector3) -> bool:
	var bs: Variant = get_parent().get(&"buildings") if get_parent() else null
	var b: Node3D = (bs as Dictionary).get(String(place)) if bs is Dictionary else null
	if b == null or not is_instance_valid(b):
		return false
	var into := b.global_basis.z
	into.y = 0.0
	var off := at - places.at(place)
	off.y = 0.0
	return into.length() > 0.01 and off.dot(into.normalized()) > PAST_DOOR
const PAST_DOOR := 0.9


## A bang on `place`'s door: whoever the book has inside hears it (their ids), and it's told
## (`knocked`) for an act to answer. None does: at the doctor's, the town answers it (FetchHelp:
## the doctor out to any hurt man by his door, #1095).
func knock(place: StringName, by: Node, at: Vector3) -> Array:
	var inside: Array = []
	for id: StringName in book.inside(place):
		inside.append(id)
	knocks.append([Engine.get_physics_frames(), place, inside.duplicate()])
	knock_claimed = false
	knocked.emit(place, inside, by, at)
	if not knock_claimed and place == home_of(_person(FetchHelp.DOCTOR)) and fetch != null:
		if state.get(FetchHelp.DOCTOR) == &"act" and lends.has(FetchHelp.DOCTOR) and hurt_by_door(place, by) != null:
			lend(FetchHelp.DOCTOR)  # (#1106) the scene that has him lets him go to the man
		var hurt := hurt_by_door(place, by)
		if hurt != null:
			var said := fetch.at_door(hurt, places.at(place), inside.has(FetchHelp.DOCTOR) or book.inside(place).has(FetchHelp.DOCTOR))
			if said != "" and by is Player and (by as Player).wounds:
				(by as Player).wounds.say(said, 4.0)
	knock_claimed = false
	return inside


## An act answering the knock it's being told of (in its `knocked` handler): the town leaves it be.
func claim_knock() -> void:
	knock_claimed = true


## The hurt man by `place`'s door (#1095): the one you've got hold of, else the nearest man
## within `DOOR_BODY_M` who's bleeding, down or hurt, alive. Null if none.
func hurt_by_door(place: StringName, by: Node) -> HumanBody:
	var door_at := places.at(place)
	var held: HumanBody = null
	if by is Player and (by as Player).carry != null:
		held = (by as Player).carry.him
	if held != null and is_instance_valid(held) and _hurt(held) \
			and Vector2(_body_at(held).x - door_at.x, _body_at(held).z - door_at.z).length() < DOOR_BODY_M:
		return held
	var best: HumanBody = null
	var best_d := DOOR_BODY_M
	for n: Node in get_tree().get_nodes_in_group(&"people"):
		var m := n as HumanBody
		if m == null or m == by or not _hurt(m):
			continue
		var at := _body_at(m)
		var d := Vector2(at.x - door_at.x, at.z - door_at.z).length()
		if d < best_d:
			best_d = d
			best = m
	return best
const DOOR_BODY_M := 4.5


## Alive and hurt: bleeding, blood lost, out cold or a wound on him.
static func _hurt(m: HumanBody) -> bool:
	if m == null or not is_instance_valid(m) or m.physiology == null or not m.physiology.alive:
		return false
	var ph := m.physiology
	return not ph.bleeds.is_empty() or ph.blood_loss() > 0.02 or not ph.is_conscious()


# --- No Law's carry (#1057) --------------------------------------------------------------------------

## The murder's shot fired and Earl still breathing: the carry (NoLawCarry: the barkeep sends you to
## Doc's with him), once, from when the barkeep's said there's nobody to fetch (or it's over).
func _carry_step() -> void:
	if not murder_auto or carry_act != null or StoryState.has_fact("nolaw.carried_earl") \
			or not StoryState.get_fact("nolaw.murder") in ["earl", "done"]:
		return
	if not FileAccess.file_exists("res://config/moments/%s.json" % CARRY):
		return
	var earl := folk_man(&"earl")
	if earl == null or not earl.physiology.alive:
		return
	var m := murder as NoLawMurder
	if m != null and is_instance_valid(m) and not m.done and not m.fetch_said():
		return
	start_carry()


func start_carry(options := {}) -> Moment:
	carry_act = Moment.start_named(CARRY, get_parent() as Node3D, null, options)
	return carry_act


## Taken in at the doctor's (FetchHelp.at_door, #1095): a hurt man let go of off your shoulder and
## laid in the doctor's front room (`doctor_room`, the doctor's building's own space), alive; a day
## man's day waits (an act's, as it were: the doctor has him). Treating him by his wounds is #1093.
## `taken_in`: id (or the body's name) -> {at, t}.
var taken_in := {}
func take_in(man: HumanBody) -> void:
	if man == null or not is_instance_valid(man):
		return
	var you := get_tree().get_first_node_in_group(&"player") as Player
	if you != null and you.carry != null and you.carry.carrying(man):
		you.carry.drop(&"laid")
	if man.dragged_by != null:
		man.dragged_by = null
	var bs: Variant = get_parent().get(&"buildings") if get_parent() else null
	var b: Node3D = (bs as Dictionary).get(home_of(_person(FetchHelp.DOCTOR))) if bs is Dictionary else null
	var room: Array = data.get("doctor_room", [6.7, 0.95, 2.6])
	var to := b.global_transform * Vector3(float(room[0]), float(room[1]), float(room[2])) if b else _body_at(man)
	var id := man.person_id
	if people.get(id) == man:
		_strip_brain(man)
		_going_for.erase(id)
		_going_to.erase(id)
		state[id] = &"act"
		book.take(id)
	if man.limp:
		move_body(man, to)
	else:
		man.global_position = to
		man.set_pose(&"on_back")
	taken_in[String(id) if id != &"" else String(man.name)] = {"at": to, "t": Time.get_ticks_msec()}
	if you != null and you.wounds:
		you.wounds.say("The doctor takes him in.", 4.0)


## Lay a dead man out where he is for the night (a body under a sheet: `sheet` a drawn stand-in, a
## pale box over him, no collision), moved first to `to` if it's given and you can't see him go.
func lay_out(id: StringName, place: StringName, to := Vector3.INF) -> Node3D:
	var man := folk_man(id)
	if man == null:
		return null
	if to != Vector3.INF:
		move_body(man, to)
	var old: Dictionary = laid.get(id, {})
	if old.get("sheet") != null and is_instance_valid(old.sheet):
		(old.sheet as Node).queue_free()
	var sheet := MeshInstance3D.new()
	sheet.name = "Sheet_%s" % id
	var box := BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.84, 0.78)
	mat.roughness = 0.95
	box.material = mat
	sheet.mesh = box
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	get_parent().add_child(sheet)
	_fit_sheet(man, sheet)
	laid[id] = {"place": String(place), "at": _body_at(man), "sheet": sheet}
	return sheet


## The sheet over his parts as they lie (a box round them, a hand's breadth over).
func _fit_sheet(man: HumanBody, sheet: MeshInstance3D) -> void:
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for n: Variant in man.parts.values():
		var at := (n as Node3D).global_position
		lo = lo.min(at)
		hi = hi.max(at)
	var mid := (lo + hi) * 0.5
	var floor_y := lo.y - 0.1
	var size := Vector3(maxf(hi.x - lo.x, 0.3) + 0.35, maxf(hi.y - floor_y, 0.2) + 0.1, maxf(hi.z - lo.z, 0.3) + 0.35)
	(sheet.mesh as BoxMesh).size = size
	sheet.global_position = Vector3(mid.x, floor_y + size.y * 0.5, mid.z)


## A limp body moved whole (every part by the same step) so his pelvis is over `to` and his lowest
## part a little above its height, to settle: done only where nobody sees it (the undertaker's men,
## the doctor overnight). (His ragdoll's parts are his children: each is set, the root left be.)
static func move_body(man: HumanBody, to: Vector3) -> void:
	var from := _body_at(man)
	var low := INF
	for n: Variant in man.parts.values():
		low = minf(low, (n as Node3D).global_position.y)
	var step := Vector3(to.x - from.x, to.y + 0.12 - low, to.z - from.z)
	var xfs := {}
	for sid: Variant in man.parts:
		xfs[sid] = (man.parts[sid] as Node3D).global_transform.translated(step)
	for sid: Variant in man.parts:
		var rb := man.parts[sid] as Node3D
		rb.global_transform = xfs[sid]
		if rb is RigidBody3D:
			(rb as RigidBody3D).linear_velocity = Vector3.ZERO
			(rb as RigidBody3D).angular_velocity = Vector3.ZERO
			(rb as RigidBody3D).sleeping = false


# --- Saved (SaveGame, #1138) -------------------------------------------------------------------

## What a save keeps of the town's day: who's a body in the world and who's a row on the book, the
## dead and the buried, who's laid out where, who an act sent off, the hands you've played. (The
## acts themselves aren't kept: nobody sleeps in the middle of one; a man an act had goes back to
## his day.)
func save_dict() -> Dictionary:
	var lay := {}
	for id: StringName in laid:
		lay[id] = {"place": String(laid[id].place), "at": laid[id].at}
	var here: Array[StringName] = []
	for id: StringName in people:
		if folk_man(id) != null:
			here.append(id)
	return {"state": state.duplicate(), "here": here, "book": book.rows.duplicate(true), "laid": lay,
			"gone_for_good": gone_for_good.duplicate(), "kept_out": kept_out.duplicate(), "hands": _your_hands}


## A save's town day put back on a fresh town, before its people's bodies are (`SaveGame.apply`):
## the same men in the world (each at his spot: the body's own place follows) and on the book.
func load_dict(d: Dictionary) -> void:
	if not _ready_once():
		_prebuild()
	gone_for_good = (d.gone_for_good as Dictionary).duplicate()
	kept_out = (d.kept_out as Dictionary).duplicate()
	_your_hands = int(d.hands)
	_last_hour = NAN
	_look = 0.0
	_step(0.0)
	var here: Array = d.here
	for id: StringName in people.keys():
		if not here.has(id):
			_gone(id, true)
	for id: StringName in here:
		if folk_man(id) == null and not _person(id).is_empty():
			if _person(id).has("act"):
				take(id, door(home_of(_person(id))), Vector3.FORWARD)
			else:
				_bring(_person(id), false)
	for id: StringName in gone_for_good:
		var man := folk_man(id)
		people.erase(id)
		if man:
			man.queue_free()
	for id: StringName in d.state:
		var st: StringName = d.state[id]
		if st in [&"act", &"called"]:
			st = &"in" if here.has(id) else &"out"
		state[id] = st
	book.rows = (d.book as Dictionary).duplicate(true)


## The save's dead laid out again under their sheets, once their bodies lie as saved.
func load_laid(d: Dictionary) -> void:
	for id: StringName in d.laid:
		if folk_man(id) != null:
			lay_out(id, StringName(String(d.laid[id].place)))
