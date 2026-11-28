class_name TownNews
extends RefCounted
## The town's news (townsfolk step 7, #1051; docs/briefs/townsfolk.md §5 "The town's news"; DESIGN
## §9's memory: an event stored once, each person storing how he knows it).
##
## - **One record an event** (`records`): what (shots, a shooting, a killing, a man down), who did
##   it, to whom, who fired first, where, when, how many shots, how big. The record is the truth,
##   from Events (a gunshot's noise and its maker, `deed` hit and kill, a man falling or dying near
##   it). Nobody reads it: it's what the versions are versions *of*, and what the tests hold them to.
## - **Each person holds a version** (`versions`: person id -> record id -> version), and how he got
##   it: `saw`, `heard` (it happen) or `told` (by whom). A version is the record's slots as *he* has
##   them: who (only if he saw him fire), whom (only if he saw the man down, or was told), first (the
##   first shot he *saw* fired, by whom), shots (the ones he heard), down, dead, where (the nearest
##   door to his guess, FetchHelp.place_name). Only his CivilianBrain fills them, from Senses
##   (`heard`, `saw_down`): what he didn't sense stays empty. This is where the perception lab's leaks
##   are shut out.
## - **Telling** (`step`): two calm men within `TALK_M` of each other, one with news the other
##   lacks, pass the biggest piece: they turn to each other, it takes 6-10 s, and the hearer's version
##   is the teller's with, by seed, one chance in three of one slot dropped or swapped for a likely
##   wrong one ("Earl drew first"; "three shots, or two"). Two on the book in the same house (the
##   storekeeper and his wife at supper) tell each other once a clock hour, no bodies. The runner
##   hands his over on arrival (FetchHelp.arrived -> `hand_over`).
## - **Overnight** (`overnight`, at the town's day turn): anything a holder has at size 0.5 or more
##   reaches everyone in town as `told` (by one who held it, the same chance of a slot gone wrong);
##   what's smaller and only told fades. What nobody sensed stays unknown.
## - **The next day** from it: StoryState `news.yesterday` (the biggest thing the town holds of the
##   day before: "killing", "shooting"), which the calendar's `uneasy` kind reads (ValleyFolk.day_kind);
##   `news.harlan`, what the town makes of him if he did it, by the versions ("stopped_a_killer",
##   "shot_a_man", "split"), for the regard of step 9; `news.dead.<id>`, who the town says did it.
## - **Story events** (an act's man fired: No Law's murder) travel the same way but are the
##   script's to speak (`morning.versions`) and don't set the day's kind: the news never contradicts
##   the story's own lines.
##
## ValleyFolk owns one (`folk.news`) and gives it to every man it brings (`CivilianBrain.news`); a
## test can make one with no folk (`town` the ids in town).

## A shot this long (s) and this near (m) after the record's last one is the same event.
const SAME_S := 15.0
const SAME_M := 30.0
## A heard shot is matched to a record shot within this long before (s): the sound's travel, Senses'.
const HEARD_S := 5.0
## Telling: this near (m), it takes this long (s), one chance in this of a slot gone wrong.
const TALK_M := 3.0
const TALK_S := Vector2(6.0, 10.0)
const WRONG := 1.0 / 3.0
## A man lying where he fell is found by a townsman this near who sees him (m).
const FOUND_M := 25.0
## Looked over for talk every (s).
const LOOK_EVERY := 1.0
## Overnight, this big and more reaches everyone; less, and only told, it fades.
const OVERNIGHT := 0.5
## The size of a version by what it holds.
const SIZES := {&"killing": 1.0, &"shooting": 0.7, &"down": 0.4, &"cheat": 0.35, &"shots": 0.3, &"rough": 0.2, &"cards": 0.15, &"bar": 0.15}
## The bar (#1292, BarService): a round Harlan stood the house, Harlan drunk, the deputy drinking on duty; a
## record of its own like the table's (`rough` true, never merged with shots, told after `ROUGH_TELL_S`),
## `bar` the verb. Held by the men the bar names and those who saw it.
const BAR_NEWS := [&"round", &"drunk", &"deputy", &"jibe", &"stood_sarge", &"jailed_sarge"]
## The card table (#1279, CardGame.you_did by ValleyFolk): what's news of it, a record of its own like a
## shove's (`rough` true, so never merged with shots, and not told till `ROUGH_TELL_S` after), `cards` the
## verb: a pot Harlan took, his bluff shown up (small, `cards`), a cheat he called true or false (`cheat`:
## `whom` the man called). Held by the table's men and those who saw it.
const TABLE_NEWS := [&"won_pot", &"bluff_called", &"cheat_true", &"cheat_false"]
## Rough handling (#1272, DESIGN §2 pillar 6: every verb leaves a mark): a shove or a kick by Harlan is a
## record of its own (`what` rough, `rough` true), held by the man it was done to and those who saw it
## (their Senses, within `ROUGH_SEEN_M`); small news, told on and said to his face, faded overnight when
## only told. Never merged with shots (`_record_near`, `_record_heard`, `_record_of` skip it).
const ROUGH := [&"shove", &"kick", &"kick_down"]
const ROUGH_SEEN_M := 20.0
## Not told on, nor said to his face, till this long after (s): at once, every man who saw it told the man
## beside him in the same breath, with Harlan stood there (#1272's bench). The look and the word at it are
## CivilianBrain's; the talk is for after.
const ROUGH_TELL_S := 30.0
## The player in the records.
const HARLAN := &"harlan"

var folk: ValleyFolk
## Without folk: the ids of everyone in town (who the overnight news reaches), and the story's men.
var town: Array[StringName] = []
var story_men: Array[StringName] = []
## Every record: {id, what, who, whom, first, at, where, day, hour, frame, last_frame, shots, story}.
var records: Array[Dictionary] = []
## person id -> {record id -> {how, by, who, whom, first, shots, down, dead, where, frame, wrong}}.
var versions := {}
## The talks under way: {a (teller brain), b (hearer brain), rec, t}.
var talks: Array[Dictionary] = []
## What happened, in order (the tests', the bridge's): [frame, what, who, record id].
var trail: Array = []
## The town's brains (joined as they're brought).
var brains: Array[CivilianBrain] = []

var _rng := RandomNumberGenerator.new()
var _look := 0.0
var _hour_told := -1
var _said := {}
var _heard: Array = []


func _init(f: ValleyFolk = null) -> void:
	folk = f
	_rng.seed = 1051
	Events.noise.connect(_on_noise)
	Events.deed.connect(_on_deed)
	Events.person_died.connect(_on_died)
	Events.person_fell.connect(func(p: Node, _c: bool) -> void: _on_fell(p))


## A man brought into the world: his brain hands in what he senses.
func join(brain: CivilianBrain) -> void:
	if not brains.has(brain):
		brains.append(brain)
	brain.news = self


static func id_of(n: Node) -> StringName:
	if n is Player:
		return HARLAN
	if n is HumanBody:
		return (n as HumanBody).person_id
	return &""


# --- The truth (records) ---------------------------------------------------------------------------

func _on_noise(at: Vector3, _loud: float, kind: StringName, source: Node) -> void:
	if kind != &"gunshot":
		return
	var r := _record_near(at, SAME_S)
	var who := id_of(source) if source != null and is_instance_valid(source) else &""
	if r.is_empty():
		r = _new_record(&"shots", at)
		r.first = who
	r.shots += 1
	r.last_frame = Engine.get_physics_frames()
	if r.who == &"" and who != &"":
		r.who = who
	if who != &"" and _is_story(who):
		r.story = true


func _on_deed(actor: Node, kind: StringName, target: Node, at: Vector3) -> void:
	if kind in ROUGH and actor is Player and target is HumanBody:
		_rough(actor as Node3D, target as HumanBody, at)
		return
	if not kind in [&"hit", &"kill"] or not target is HumanBody:
		return
	var whom := id_of(target)
	var r := _record_of(whom)
	if r.is_empty():
		r = _record_near(at, SAME_S)
	if r.is_empty():
		r = _new_record(&"shooting", at)
	if r.whom == &"":
		r.whom = whom
		r.body = target
	var who := id_of(actor) if actor != null and is_instance_valid(actor) else &""
	if r.who == &"" or (kind == &"kill" and who != &""):
		r.who = who if who != &"" else r.who
	if r.first == &"":
		r.first = r.who
	if who != &"" and _is_story(who):
		r.story = true
	if kind == &"kill":
		r.what = &"killing"
	elif r.what in [&"shots", &"down"]:
		r.what = &"shooting"


## Harlan did `verb` at the card table (#1279): a record if it's news (TABLE_NEWS), a version for each
## man at the table (`info.men`) and each townsman who saw him do it.
func table(verb: StringName, info: Dictionary, at: Vector3) -> void:
	if not verb in TABLE_NEWS:
		return
	var accused := info.get("accused") as HumanBody
	var r := _new_record(&"rough", at)
	r["rough"] = true
	r["cards"] = verb
	r.who = HARLAN
	r.whom = id_of(accused) if accused != null else &""
	var men: Array = info.get("men", [])
	var harlan: Node3D = null
	if folk != null and folk.is_inside_tree():
		harlan = folk.get_tree().get_first_node_in_group(&"player") as Node3D
	for b: CivilianBrain in brains:
		if not is_instance_valid(b) or b.body == null or not b.body.physiology.is_conscious():
			continue
		if not men.has(b.body) and (harlan == null or b.body.global_position.distance_to(at) > ROUGH_SEEN_M \
				or b.senses == null or not b.senses.sees(harlan)):
			continue
		var v := _version(b.body.person_id, r, &"saw")
		v["rough"] = true
		v["cards"] = verb
		v.who = HARLAN
		v.whom = r.whom
		if v.where == "":
			v.where = _place(at)


## The bar's news (#1292): `men` hold it, and every man who sees Harlan within `ROUGH_SEEN_M`.
func bar(verb: StringName, men: Array, at: Vector3) -> void:
	if not verb in BAR_NEWS:
		return
	var r := _new_record(&"rough", at)
	r["rough"] = true
	r["bar"] = verb
	r.who = HARLAN
	var harlan: Node3D = null
	if folk != null and folk.is_inside_tree():
		harlan = folk.get_tree().get_first_node_in_group(&"player") as Node3D
	for b: CivilianBrain in brains:
		if not is_instance_valid(b) or b.body == null or not b.body.physiology.is_conscious():
			continue
		if not men.has(b.body) and (harlan == null or b.body.global_position.distance_to(at) > ROUGH_SEEN_M \
				or b.senses == null or not b.senses.sees(harlan)):
			continue
		var v := _version(b.body.person_id, r, &"saw")
		v["rough"] = true
		v["bar"] = verb
		v.who = HARLAN
		if v.where == "":
			v.where = _place(at)


## Harlan shoved or kicked `man`: one record (again within `SAME_S`, the same one), a version for him
## and for each townsman who saw Harlan do it.
func _rough(harlan: Node3D, man: HumanBody, at: Vector3) -> void:
	var whom := id_of(man)
	var r := {}
	var now := Engine.get_physics_frames()
	for i in range(records.size() - 1, -1, -1):
		var x: Dictionary = records[i]
		if x.get("rough", false) and x.whom == whom and float(now - int(x.last_frame)) / Engine.physics_ticks_per_second < SAME_S:
			r = x
			break
	if r.is_empty():
		r = _new_record(&"rough", at)
		r["rough"] = true
		r.who = HARLAN
		r.whom = whom
	r.last_frame = now
	for b: CivilianBrain in brains:
		if not is_instance_valid(b) or b.body == null or not b.body.physiology.is_conscious():
			continue
		var him := b.body == man
		if not him and (b.body.global_position.distance_to(at) > ROUGH_SEEN_M or b.senses == null or not b.senses.sees(harlan)):
			continue
		var v := _version(b.body.person_id, r, &"saw")
		v.how = &"saw"
		v["rough"] = true
		v.who = HARLAN
		v.whom = whom
		if v.where == "":
			v.where = _place(at)


func _on_died(p: Node, _cause: StringName) -> void:
	if not p is HumanBody:
		return
	versions.erase(id_of(p))  # dead men tell no tales
	var r := _record_of(id_of(p))
	if r.is_empty():
		r = _record_near((p as Node3D).global_position, SAME_S)
		if r.is_empty() or r.whom != &"":
			return  # died of nothing anyone did here (bled out of old wounds elsewhere): no news
		r.whom = id_of(p)
		r.body = p
	r.what = &"killing"


func _on_fell(p: Node) -> void:
	if not p is HumanBody:
		return
	var whom := id_of(p)
	if not _record_of(whom).is_empty():
		return
	var r := _record_near((p as Node3D).global_position, SAME_S)
	if r.is_empty():
		r = _new_record(&"down", (p as Node3D).global_position)
	if r.whom == &"":
		r.whom = whom
		r.body = p
		if r.what == &"shots":
			r.what = &"shooting"


func _new_record(what: StringName, at: Vector3) -> Dictionary:
	var r := {"id": records.size() + 1, "what": what, "who": &"", "whom": &"", "first": &"", "at": at,
			"where": _place(at), "day": _day(), "hour": _hour(), "frame": Engine.get_physics_frames(),
			"last_frame": Engine.get_physics_frames(), "shots": 0, "story": false, "body": null}
	records.append(r)
	_note("record " + String(what), &"", r.id)
	return r


## The latest record whose last shot was within `s` seconds and `SAME_M` of `at`.
func _record_near(at: Vector3, s: float) -> Dictionary:
	var now := Engine.get_physics_frames()
	for i in range(records.size() - 1, -1, -1):
		var r: Dictionary = records[i]
		if r.get("rough", false) or float(now - int(r.last_frame)) / Engine.physics_ticks_per_second > s:
			continue
		if (r.at as Vector3).distance_to(at) <= SAME_M:
			return r
	return {}


func _record_of(whom: StringName) -> Dictionary:
	if whom == &"":
		return {}
	for i in range(records.size() - 1, -1, -1):
		if records[i].whom == whom and not records[i].get("rough", false):
			return records[i]
	return {}


func record(id: int) -> Dictionary:
	return records[id - 1] if id >= 1 and id <= records.size() else {}


func _is_story(id: StringName) -> bool:
	if story_men.has(id):
		return true
	return folk != null and folk._person(id).has("act")


# --- What a man sensed (his CivilianBrain, from Senses) ---------------------------------------------

## A shot he heard: `at` his guess, `maker` only if he saw him fire. Taken in on the next step (his
## Senses hear it inside the same noise signal the record's made from, maybe before it).
func heard(brain: CivilianBrain, at: Vector3, maker: Node) -> void:
	_heard.append([brain, at, maker, Engine.get_physics_frames()])


func _take_heard() -> void:
	var list := _heard
	_heard = []
	for h: Array in list:
		var b: CivilianBrain = h[0] if is_instance_valid(h[0]) else null
		if b != null:
			_heard_now(b, h[1], h[2] if is_instance_valid(h[2]) else null, int(h[3]))


func _heard_now(brain: CivilianBrain, at: Vector3, maker: Node, frame: int) -> void:
	if brain.body == null or not brain.body.physiology.alive:
		return  # he died since: dead men tell no tales
	var r := _record_heard(at, frame)
	if r.is_empty():
		return
	var v := _version(brain.body.person_id, r, &"saw" if maker != null else &"heard")
	v.shots = int(v.shots) + 1
	var by := id_of(maker) if maker != null and is_instance_valid(maker) else &""
	if by != &"":
		v.how = &"saw"
		if v.who == &"" or v.who == v.whom:
			v.who = by
		if int(v.shots) == 1:
			v.first = by  # the first shot he heard, and he saw who fired it
	if v.where == "":
		v.where = _place(at)


## A man he saw fall, or saw lying dead.
func saw_down(brain: CivilianBrain, man: HumanBody) -> void:
	if man == null or not is_instance_valid(man) or not brain.body.physiology.alive:
		return
	var whom := id_of(man)
	var r := _record_of(whom)
	if r.is_empty():
		_on_fell(man)
		r = _record_of(whom)
	if r.is_empty():
		return
	var v := _version(brain.body.person_id, r, &"saw")
	v.how = &"saw"
	v.whom = whom
	v.down = true
	v.dead = v.dead or not man.physiology.alive
	if v.where == "":
		v.where = _place(man.global_position)


## `pid` came on `whom` lying there (the undertaker come for him; no body of his own needed): he has
## him down, dead if `dead`.
func found(pid: StringName, whom: StringName, dead: bool, at: Vector3) -> void:
	var r := _record_of(whom)
	if r.is_empty():
		r = _new_record(&"killing" if dead else &"down", at)
		r.whom = whom
	var v := _version(pid, r, &"saw")
	v.how = &"saw"
	v.whom = whom
	v.down = true
	v.dead = v.dead or dead
	if v.where == "":
		v.where = _place(at)


## The record a heard shot belongs to: one with a shot just now, the nearest to his guess.
func _record_heard(at: Vector3, now: int) -> Dictionary:
	var best := {}
	var best_d := INF
	for r: Dictionary in records:
		if r.get("rough", false) or absf(float(now - int(r.last_frame))) / Engine.physics_ticks_per_second > HEARD_S or int(r.frame) > now:
			continue
		var d := (r.at as Vector3).distance_to(at)
		if d < best_d:
			best_d = d
			best = r
	return best


func _version(pid: StringName, r: Dictionary, how: StringName) -> Dictionary:
	var mine: Dictionary = versions.get(pid, {})
	versions[pid] = mine
	if not mine.has(r.id):
		mine[r.id] = {"how": how, "by": &"", "who": &"", "whom": &"", "first": &"", "shots": 0, "down": false,
				"dead": false, "where": "", "frame": Engine.get_physics_frames(), "wrong": ""}
		_note(String(how), pid, r.id)
	return mine[r.id]


## Who he saw fire the latest shots he has a version of (within `SAW_FIRE_S`), or &"" (#1213).
func saw_fire(pid: StringName) -> StringName:
	var mine: Dictionary = versions.get(pid, {})
	var best := -1
	for rid: Variant in mine:
		if not (mine[rid] as Dictionary).get("rough", false):
			best = maxi(best, int(rid))
	if best < 0:
		return &""
	var v: Dictionary = mine[best]
	var r := record(best)
	if r.is_empty() or Engine.get_physics_frames() - int(r.get("last_frame", 0)) > SAW_FIRE_S * Engine.physics_ticks_per_second:
		return &""
	return v.who if v.how == &"saw" else &""
const SAW_FIRE_S := 600.0


## His version of record `rid`, or {}.
func version_of(pid: StringName, rid: int) -> Dictionary:
	return (versions.get(pid, {}) as Dictionary).get(rid, {})


## What a version holds (killing, shooting, down, shots) and how big it is.
static func kind_of(v: Dictionary) -> StringName:
	if v.is_empty():
		return &""
	if v.dead:
		return &"killing"
	if v.down and int(v.shots) > 0:
		return &"shooting"
	if v.down:
		return &"down"
	if v.get("cards", &"") != &"":
		return &"cheat" if String(v.cards).begins_with("cheat") else &"cards"
	if v.get("bar", &"") != &"":
		return &"bar"
	if v.get("rough", false):
		return &"rough"
	return &"shots" if int(v.shots) > 0 else &""


static func size_of(v: Dictionary) -> float:
	return float(SIZES.get(kind_of(v), 0.0))


# --- Telling ----------------------------------------------------------------------------------------

## The hearer's version from the teller's: told, by him, and one slot in three gone wrong.
func _told(teller: StringName, hearer: StringName, rid: int, how := &"told") -> bool:
	var tv := version_of(teller, rid)
	if tv.is_empty() or teller == hearer:
		return false
	var hv := version_of(hearer, rid)
	if not hv.is_empty() and (hv.how != &"told" or size_of(hv) >= size_of(tv)):
		return false  # he has it as well already (or saw it himself)
	var v := tv.duplicate()
	v.how = how
	v.by = teller
	v.frame = Engine.get_physics_frames()
	v.wrong = ""
	if _rng.randf() < WRONG:
		_go_wrong(v)
	var mine: Dictionary = versions.get(hearer, {})
	versions[hearer] = mine
	mine[rid] = v
	_note("told", hearer, rid)
	return true


## One slot dropped, or swapped for a likely wrong one.
func _go_wrong(v: Dictionary) -> void:
	var can: Array[String] = []
	if v.first != &"" and v.whom != &"" and v.who != &"" and v.who != v.whom:
		can.append("first")  # "Earl drew first, I heard" (or the other way about)
	if int(v.shots) > 0:
		can.append("shots")  # "three shots, or two"
	if v.who != &"":
		can.append("who")  # "somebody shot him; I don't know who"
	if v.where != "":
		can.append("where")
	if can.is_empty():
		return
	var slot: String = can[_rng.randi() % can.size()]
	match slot:
		"first":
			v.first = v.whom if v.first == v.who else v.who
		"shots":
			v.shots = maxi(1, int(v.shots) + (1 if _rng.randf() < 0.6 else -1))
		"who":
			v.who = &""
		"where":
			v.where = ""
	v.wrong = slot


## The runner's hand-over: he tells the man he ran to (the doctor; Harlan's own isn't kept).
func hand_over(runner: StringName, to: StringName, down: HumanBody) -> void:
	if to == HARLAN or to == &"":
		return
	var r := _record_of(id_of(down)) if down != null and is_instance_valid(down) else {}
	if r.is_empty():
		return
	_told(runner, to, int(r.id), &"told")


## The biggest piece `a` holds that `b` lacks (or holds smaller, told), or 0.
func _piece(a: StringName, b: StringName) -> int:
	var best := 0
	var best_s := 0.0
	for rid: int in (versions.get(a, {}) as Dictionary):
		if _too_soon(rid):
			continue
		var av := version_of(a, rid)
		var bv := version_of(b, rid)
		if not bv.is_empty() and (bv.how != &"told" or size_of(bv) >= size_of(av)):
			continue
		if size_of(av) > best_s:
			best_s = size_of(av)
			best = rid
	return best


## Each frame (ValleyFolk's, or a test's): the talks under way, and every second who's met whom.
func step(delta: float) -> void:
	if not _heard.is_empty():
		_take_heard()
	for t: Dictionary in talks.duplicate():
		t.t -= delta
		# Checked before typing them: a typed var can't take a freed brain (a man sent off mid-talk).
		if not is_instance_valid(t.a) or not is_instance_valid(t.b):
			talks.erase(t)
			continue
		var a: CivilianBrain = t.a
		var b: CivilianBrain = t.b
		if not _calm(a) or not _calm(b):
			talks.erase(t)  # broken off: trouble, or one of them sent off
			continue
		if a.body.global_position.distance_to(b.body.global_position) > TALK_M + 1.5:
			talks.erase(t)
			continue
		if t.t <= 0.0:
			_told(a.body.person_id, b.body.person_id, int(t.rec))
			talks.erase(t)
	_look -= delta
	if _look > 0.0:
		return
	_look = LOOK_EVERY
	var alive: Array[CivilianBrain] = []
	for x: CivilianBrain in brains:
		if is_instance_valid(x):
			alive.append(x)
	brains = alive
	_found_step()
	for i in brains.size():
		var a := brains[i]
		if not _calm(a) or _talking(a):
			continue
		for j in range(i + 1, brains.size()):
			var b := brains[j]
			if not _calm(b) or _talking(b) or a.body.global_position.distance_to(b.body.global_position) > TALK_M:
				continue
			var ida := a.body.person_id
			var idb := b.body.person_id
			var rid := _piece(ida, idb)
			var teller := a
			var hearer := b
			if rid == 0:
				rid = _piece(idb, ida)
				teller = b
				hearer = a
			if rid == 0:
				continue
			_start_talk(teller, hearer, rid)
			break
	_book_step()


## A man lying where he fell is found (#1051: a body found later is something sensed): any townsman
## who sees him (Senses, within `FOUND_M`) has him down, dead if he is.
func _found_step() -> void:
	for r: Dictionary in records:
		var man: HumanBody = r.body as HumanBody if r.get("body") != null and is_instance_valid(r.body) else null
		if man == null or not man.is_inside_tree() or not (man.limp or not man.physiology.alive):
			continue
		for b: CivilianBrain in brains:
			if b.body == man or b.senses == null or not b.body.physiology.is_conscious():
				continue
			if b.body.global_position.distance_to(man.global_position) > FOUND_M:
				continue
			var v := version_of(b.body.person_id, int(r.id))
			if not v.is_empty() and v.how != &"told" and v.down and (v.dead or man.physiology.alive):
				continue
			if b.senses.sees(man):
				saw_down(b, man)


func _start_talk(a: CivilianBrain, b: CivilianBrain, rid: int) -> void:
	talks.append({"a": a, "b": b, "rec": rid, "t": _rng.randf_range(TALK_S.x, TALK_S.y)})
	a.body.face(b.body.global_position + Vector3.UP * 1.5)
	b.body.face(a.body.global_position + Vector3.UP * 1.5)
	_note("talk", a.body.person_id, rid)
	var r := record(rid)
	if not r.story:
		var you := _player()
		if you != null and you.global_position.distance_to(a.body.global_position) < 12.0:
			var text := line_of(a.body.person_id, rid, b.body.person_id)
			if folk != null:
				folk.say_soon(a.body, text)  # (the folk step in _process: said on the physics frame)
			else:
				a.say_line(text)


func _talking(b: CivilianBrain) -> bool:
	for t: Dictionary in talks:
		if t.a == b or t.b == b:
			return true
	return false


static func _calm(b: CivilianBrain) -> bool:
	if b == null or not is_instance_valid(b) or b.body == null or b.held:
		return false
	var p := b.body.physiology
	if not p.is_conscious() or not p.can_speak():
		return false
	return (b.reaction == null or not b.reaction.active()) and b.mood == CivilianBrain.Mood.CALM


## Two on the book in the same house tell each other, once a clock hour.
func _book_step() -> void:
	if folk == null or folk.book == null:
		return
	var h := int(floor(_hour())) + 24 * _day()
	if h == _hour_told:
		return
	_hour_told = h
	var houses := {}
	for id: StringName in folk.book.rows:
		var r: Dictionary = folk.book.row(id)
		if String(r.get("do", "")) == "sleep":
			continue
		var place := StringName(String(r.get("in", "")))
		if place == &"" or String(place).contains("@"):
			continue  # out of town (a way out), not a house
		if not houses.has(place):
			houses[place] = []
		houses[place].append(id)
	for place: StringName in houses:
		var ids: Array = houses[place]
		for a: StringName in ids:
			for b: StringName in ids:
				var rid := _piece(a, b)
				if rid != 0:
					_told(a, b, rid)


# --- Overnight, and the next day ---------------------------------------------------------------------

## The town's day turned: the big news reaches everyone; small, told news fades; the facts the next
## day reads (`news.yesterday`, `news.harlan`, `news.dead.<id>`).
func overnight() -> void:
	_take_heard()
	var everyone := _town()
	var biggest := &""
	var biggest_s := 0.0
	for r: Dictionary in records:
		var rid := int(r.id)
		var holders: Array[StringName] = []
		var best_s := 0.0
		for pid: StringName in versions:
			var v := version_of(pid, rid)
			if v.is_empty():
				continue
			holders.append(pid)
			best_s = maxf(best_s, size_of(v))
		if holders.is_empty():
			continue  # nobody sensed it: it stays unknown
		if best_s >= OVERNIGHT:
			# Those who saw it are believed first.
			var saw := holders.filter(func(p: StringName) -> bool: return version_of(p, rid).how == &"saw")
			var from: Array = saw if not saw.is_empty() else holders
			for pid: StringName in everyone:
				if version_of(pid, rid).is_empty():
					_told(StringName(from[_rng.randi() % from.size()]), pid, rid)
			if not r.story and best_s > biggest_s and int(r.day) >= _day() - 1:
				biggest_s = best_s
				biggest = &"killing" if best_s >= 1.0 else &"shooting"
		else:
			for pid: StringName in holders:
				if version_of(pid, rid).how == &"told":
					(versions[pid] as Dictionary).erase(rid)
	StoryState.clear("news.yesterday")
	if biggest != &"":
		_fact("news.yesterday", String(biggest))
	var view := town_view_of_harlan()
	StoryState.clear("news.harlan")
	if view != &"":
		_fact("news.harlan", String(view))
	for r: Dictionary in records:
		if r.what == &"killing" and r.whom != &"" and not r.story:
			var said := said_did_it(r.whom)
			if said != &"":
				_fact("news.dead." + String(r.whom), String(said))
	_note("overnight", &"", 0)


## What this man makes of Harlan, by his versions of what Harlan did: "stopped_a_killer" (the man
## he shot fired first, or had shot someone, as he has it), "shot_a_man", or "" (nothing of him).
func view_of_harlan(pid: StringName) -> StringName:
	var view := &""
	for rid: int in (versions.get(pid, {}) as Dictionary):
		var v := version_of(pid, rid)
		if v.who != HARLAN or v.whom == &"" or not v.down:
			continue
		var killer: bool = v.first == v.whom
		if not killer:
			for rid2: int in (versions.get(pid, {}) as Dictionary):
				var w := version_of(pid, rid2)
				if rid2 != rid and w.who == v.whom and w.down:
					killer = true
		if killer:
			view = &"stopped_a_killer"
		elif view == &"":
			view = &"shot_a_man"
	return view


## The town's: the most say it; "split" when it's near even.
func town_view_of_harlan() -> StringName:
	var n := {&"stopped_a_killer": 0, &"shot_a_man": 0}
	for pid: StringName in versions:
		var v := view_of_harlan(pid)
		if n.has(v):
			n[v] += 1
	var a: int = n[&"stopped_a_killer"]
	var b: int = n[&"shot_a_man"]
	if a + b == 0:
		return &""
	if absf(a - b) <= 0.2 * (a + b):
		return &"split"
	return &"stopped_a_killer" if a > b else &"shot_a_man"


## Who the town says killed `whom` (most versions), or "".
func said_did_it(whom: StringName) -> StringName:
	var r := _record_of(whom)
	if r.is_empty():
		return &""
	var n := {}
	for pid: StringName in versions:
		var v := version_of(pid, int(r.id))
		if not v.is_empty() and v.who != &"":
			n[v.who] = int(n.get(v.who, 0)) + 1
	var best := &""
	for w: StringName in n:
		if best == &"" or n[w] > n[best]:
			best = w
	return best


## Does anyone in town know `whom` is dead (or down: his body's been seen)?
func known_down(whom: StringName) -> bool:
	var r := _record_of(whom)
	if r.is_empty():
		return false
	for pid: StringName in versions:
		var v := version_of(pid, int(r.id))
		if not v.is_empty() and v.down:
			return true
	return false


# --- What he says of it -----------------------------------------------------------------------------

## Proper names the town uses (the rest by what they do: "the storekeeper").
const PROPER := {&"earl": "Earl", &"cody": "Cody", &"doctor": "Doc"}


func name_of(id: StringName) -> String:
	if id == HARLAN:
		return "the deputy" if StoryState.get_fact("nolaw.deputy", false) == true else "the new man"
	if PROPER.has(id):
		return String(PROPER[id])
	var n := String(id).replace("_", " ")
	if folk != null and not folk._person(id).is_empty():
		n = String(folk._person(id).get("name", n))
	return "the " + n.to_lower()


## His version of record `rid` in his own words: the town's script's (TownScript, scene `news` of
## docs/scripts/town.json; PROPOSED, voiced after Sean's Script OK), the wordings by his seed; the built
## words below only where the script hasn't the line.
func line_of(pid: StringName, rid: int, to := &"") -> String:
	var v := version_of(pid, rid)
	if v.is_empty():
		return ""
	var here := _here(pid, rid)
	var slots := {"who": "you" if v.who == HARLAN and to == HARLAN else name_of(v.who), "whom": "me" if v.whom == pid else _whom(v),
			"where": v.where if v.where != "" else "the street", "shots": _count(int(v.shots)).to_lower(),
			"teller": name_of(v.by) if v.by != &"" else "somebody",
			"at": "right here" if here else "by " + (v.where if v.where != "" else "the street"),
			"Who": _cap(name_of(v.who))}
	var parts: Array[String] = []
	var k := kind_of(v)
	var head: Array = []
	if k == &"killing" or k == &"shooting":
		var base := "news." + String(k)
		head = [base + ".you"] if v.who == HARLAN and to == HARLAN else ([base] if v.who != &"" else [base + ".nobody"])
	elif k == &"down":
		head = ["news.down"]
	elif k == &"cards" or k == &"cheat":
		# The card table (#1279): news.cards.<verb>, ".you" to his face (the man called a cheat: "me").
		var base := "news.cards." + String(v.cards)
		head = [base + ".you"] if v.who == HARLAN and to == HARLAN else ([base] if v.who != &"" else [base + ".nobody"])
	elif k == &"bar":
		# The bar (#1292): news.bar.<verb>, ".you" to his face.
		var base := "news.bar." + String(v.bar)
		head = [base + ".you"] if v.who == HARLAN and to == HARLAN else [base]
	elif k == &"rough":
		# A shove (#1272): to his face, "you"; the man it was done to says "me".
		head = ["news.rough.you"] if v.who == HARLAN and to == HARLAN else (["news.rough"] if v.who != &"" else ["news.rough.nobody"])
	elif k == &"shots":
		# Who fired, if he saw it (#1213: the liveryman, in the room, said "Damn fool, whoever it was"; the
		# barkeep told "Shooting, down by the saloon" from inside it): "you" to his face; "right here" at it.
		if v.who == HARLAN and to == HARLAN:
			head = ["news.shots.you"]
		elif v.who != &"":
			head = ["news.shots.who"]
		else:
			head = ["news.shots.here"] if here else ["news.shots"]
	if not head.is_empty():
		parts.append(_worded(pid, rid, head, slots, _built_head(v, to, here)))
	if v.first != &"" and v.first == v.whom and v.who != &"":
		var how := "saw" if v.how == &"saw" else ("told" if v.how == &"told" else "heard")
		parts.append(_worded(pid, rid, ["news.first." + how, "news.first.heard"], slots,
				"%s drew first, %s." % [_cap(_whom(v)), "I saw it" if v.how == &"saw" else "I heard"]))
	elif int(v.shots) > 1 and k != &"shots":
		parts.append(_worded(pid, rid, ["news.count.told"] if v.how == &"told" else ["news.count"], slots,
				_count(int(v.shots)) + ", " + ("I counted." if v.how != &"told" else "they say.")))
	if v.how == &"told" and v.by != &"":
		parts.append(_worded(pid, rid, ["news.told_by"], slots, "%s told me." % _cap(name_of(v.by))))
	return " ".join(parts)


## One part of his line: the script's wording by his seed, else `built`.
func _worded(pid: StringName, rid: int, ids: Array, slots: Dictionary, built: String) -> String:
	var t := TownScript.pick(ids, TownScript.seed_of(String(pid), "%d:%s" % [rid, ids[0]]), slots)
	return t if t != "" else built


## The built head line (no script).
func _built_head(v: Dictionary, to: StringName, here := false) -> String:
	var where: String = v.where if v.where != "" else "the street"
	var at := "right here" if here else "by " + where
	match kind_of(v):
		&"killing":
			if v.who != &"":
				return "%s shot %s dead, out by %s." % [_doer(v, to), _whom(v), where]
			return "Somebody's killed %s, by %s." % [_whom(v), where]
		&"shooting":
			if v.who != &"":
				return "%s shot %s by %s." % [_doer(v, to), _whom(v), where]
			return "%s's been shot, by %s." % [_cap(_whom(v)), where]
		&"down":
			return "There's a man down by %s." % where
		&"cards", &"cheat":
			var doer := _doer(v, to) if v.who != &"" else "Somebody"
			match StringName(v.cards):
				&"won_pot":
					return "%s took a pot off the table at cards, %s." % [doer, at]
				&"bluff_called":
					return "%s tried a bluff at cards, %s, and got caught at it." % [doer, at]
				&"cheat_true":
					return "%s caught %s dealing off the bottom, %s." % [doer, _whom(v), at]
			return "%s called %s a cheat at cards, %s." % [doer, _whom(v), at]
		&"bar":
			match StringName(v.bar):
				&"round":
					return "%s stood the house a round, %s." % [_doer(v, to), at]
				&"drunk":
					return "%s got good and drunk, %s." % [_doer(v, to), at]
				&"jibe":
					return "Sarge had a go at %s again, %s." % ["you" if v.who == HARLAN and to == HARLAN else name_of(v.who), at]
				&"stood_sarge":
					return "%s stood Sarge a drink, %s." % [_doer(v, to), at]
				&"jailed_sarge":
					return "%s walked Sarge to the jail to sleep it off, %s." % [_doer(v, to), at]
			return "%s took a drink on duty, %s." % [_doer(v, to), at]
		&"rough":
			if v.who != &"":
				return "%s shoved %s about, %s." % [_doer(v, to), _whom(v), at]
			return "Somebody shoved %s about, %s." % [_whom(v), at]
	if v.who == HARLAN and to == HARLAN:
		return "You let that iron off %s. %s." % [at, _count(int(v.shots))]
	if v.who != &"":
		return "%s let off his iron %s. %s." % [_cap(name_of(v.who)), at, _count(int(v.shots))]
	if here:
		return "Shooting, right here. %s." % _count(int(v.shots))
	return "Shooting, down by %s. %s." % [where, _count(int(v.shots))]


## The teller's where it happened (within `HERE_M` of record `rid`'s place): "right here", not "by the
## saloon" (#1213).
func _here(pid: StringName, rid: int) -> bool:
	var r := record(rid)
	var man := folk.folk_man(pid) if folk != null else null
	return not r.is_empty() and man != null and man.global_position.distance_to(r.at as Vector3) < HERE_M
const HERE_M := 15.0


## Who did it, said to `to` ("You" to Harlan's face).
func _doer(v: Dictionary, to: StringName) -> String:
	return "You" if v.who == HARLAN and to == HARLAN else _cap(name_of(v.who))


func _whom(v: Dictionary) -> String:
	return name_of(v.whom) if v.whom != &"" else "a man"


static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


static func _count(n: int) -> String:
	return ["No shots", "One shot", "Two shots", "Three shots", "Four shots", "Five shots"][clampi(n, 0, 5)] if n <= 5 else "A lot of shots"


## The biggest news he holds that isn't the story's (for the folk's talk when you pass), once each: its
## record id, or 0.
func to_say(pid: StringName) -> int:
	var best := 0
	var best_s := 0.0
	for rid: int in (versions.get(pid, {}) as Dictionary):
		var r := record(rid)
		if r.is_empty() or r.story or _said.has("%s:%d" % [pid, rid]) or _too_soon(rid):
			continue
		var s := size_of(version_of(pid, rid))
		if s > best_s:
			best_s = s
			best = rid
	return best


## A shove's news still fresh (`ROUGH_TELL_S`): not talked of yet.
func _too_soon(rid: int) -> bool:
	var r := record(rid)
	return not r.is_empty() and r.get("rough", false) \
			and float(Engine.get_physics_frames() - int(r.last_frame)) / Engine.physics_ticks_per_second < ROUGH_TELL_S


func said(pid: StringName, rid: int) -> void:
	_said["%s:%d" % [pid, rid]] = true


# --- Helpers ----------------------------------------------------------------------------------------

func _town() -> Array[StringName]:
	if folk == null:
		return town
	var out: Array[StringName] = []
	for p: Dictionary in folk.data.get("people", []):
		var id := StringName(p.id)
		if p.has("day") and not p.has("act") and not folk.gone_for_good.has(id) and folk.state.get(id) != &"dead":
			out.append(id)
	return out


func _place(at: Vector3) -> String:
	return folk.fetch.place_name(at) if folk != null and folk.fetch != null else "the street"


func _day() -> int:
	return folk.town_day() if folk != null else 1


func _hour() -> float:
	return folk.hour() if folk != null else 12.0


func _fact(key: String, value: Variant) -> void:
	StoryState.set_fact(key, value, _day(), _hour())


func _player() -> Node3D:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(&"player") as Node3D if tree else null


func _note(what: String, who: StringName, rid: int) -> void:
	trail.append([Engine.get_physics_frames(), what, String(who), rid])
	if trail.size() > 400:
		trail.pop_front()


## For the bridge's `read news` and the tests: the records (the truth) and every version.
func report() -> Dictionary:
	var recs := []
	for r: Dictionary in records:
		recs.append({"id": r.id, "what": String(r.what), "who": String(r.who), "whom": String(r.whom), "first": String(r.first),
				"where": r.where, "day": r.day, "hour": snappedf(float(r.hour), 0.01), "shots": r.shots, "story": r.story})
	var vs := {}
	for pid: StringName in versions:
		var mine := {}
		for rid: int in (versions[pid] as Dictionary):
			var v := version_of(pid, rid)
			mine[str(rid)] = {"how": String(v.how), "by": String(v.by), "who": String(v.who), "whom": String(v.whom),
					"first": String(v.first), "shots": v.shots, "down": v.down, "dead": v.dead, "where": v.where, "wrong": v.wrong,
					"kind": String(kind_of(v))}
		vs[String(pid)] = mine
	return {"records": recs, "versions": vs, "talks": talks.size(), "yesterday": StoryState.get_fact("news.yesterday", ""),
			"harlan": StoryState.get_fact("news.harlan", "")}


# --- Saved (SaveGame, #1138) -------------------------------------------------------------------

## What a save keeps of the news: every record, everyone's version of each, what's been said. (The
## talks under way aren't: nobody's mid-sentence when you sleep.) Frames are kept as how long ago.
func save_dict() -> Dictionary:
	return {"records": HumanBody.plain(records), "versions": versions.duplicate(true), "said": HumanBody.plain(_said),
			"hour_told": _hour_told, "frame": Engine.get_physics_frames()}


func load_dict(d: Dictionary) -> void:
	var shift := Engine.get_physics_frames() - int(d.frame)
	records.clear()
	for saved: Dictionary in d.records:
		var r := saved.duplicate(true)
		r["frame"] = int(r.frame) + shift
		r["last_frame"] = int(r.last_frame) + shift
		r["body"] = null
		records.append(r)
	versions = (d.versions as Dictionary).duplicate(true)
	for pid: StringName in versions:
		for rid: Variant in versions[pid]:
			versions[pid][rid]["frame"] = int(versions[pid][rid].frame) + shift
	_said = (d.said as Dictionary).duplicate(true)
	_hour_told = int(d.hour_told)
	talks.clear()
