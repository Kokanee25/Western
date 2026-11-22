class_name FetchHelp
extends RefCounted
## Running for help (townsfolk step 6, #1040; docs/briefs/townsfolk.md §4 "Who runs, and to whom").
##
## A man down in their sight, the townsfolk's Reactions ask here before one of them runs:
## - **One runner an event** (an event is the man down): the first calm, dutiful man who isn't the
##   doctor claims it (`claim`), unless one of more duty who saw it is still taking it in (he'll
##   go); a second who'd go sees the first gone and stays (helps or watches).
## - **To whom:** a man down alive, the **doctor**, wherever his day has him (ValleyFolk's book: a
##   doctor indoors is at his door; out on his walk, the man himself). A man dead is for the
##   **law**: none on night 1 (No Law's built line, "Ain't nobody left to fetch": nobody runs);
##   from the badge on (`nolaw.deputy`), **Harlan** if anyone saw him within the hour (where he was
##   seen, then the man himself once in sight), else the doctor, the acting law.
## - **He carries only what he sensed:** "shot" only if he heard or saw a shot, "breathing" only if
##   the man was when he left, the place as the nearest door he knows (`place_name`). He says it on
##   arrival (`react.runner`, `react.runner_you`).
## - **The doctor comes:** told, a beat for his bag (`BAG_BEAT`), out of his door (`left_frame`:
##   the brief's runner row measures from the shot to here), at a fast walk (`DOC_WALK`) with his
##   bag (the prop lab's `doctors_bag` model, #823, carried as drawn; set down beside him), to the man
##   down; he tends him (`tend`) for `TEND_FOR`, then goes back to his day.
##
## ValleyFolk owns one (`folk.fetch`) and hands it to every man it brings (`CivilianBrain.fetch`);
## a lab or test can make one with a `doctor` man and no folk. Nothing here runs per frame but the
## calls (a doctor walking) and a half-second look for Harlan.

## The doctor's day id (ValleyFolk's people): one man, the acts' too (#1095: there was a `doc`).
const DOCTOR := &"doctor"
const DOCTORS: Array[StringName] = [&"doctor"]
## A knock at his door with a hurt man by it (#1095, `at_door`): in, he's at the door this long after
## (s); then out to him, and he's taken in this long after the doctor's by him (s).
const ANSWER_S := 4.0
const TAKE_IN_S := 3.0
## A runner: calm (fear under nerve) and this dutiful at least (the most dutiful who saw it goes).
const RUNNER_DUTY := 0.4
## Told, the doctor takes his bag (s), then comes at this pace (m/s: a fast walk, Reaction.WALK 1.2).
const BAG_BEAT := 2.0
const DOC_WALK := 1.9
## He tends the man down this long (s), then back to his day.
const TEND_FOR := 240.0
## Arrived: this near the door or the man he's after (m).
const ARRIVE := 2.2
## Harlan seen by anyone within this many hours of the clock (SHAKEN_SECONDS a clock hour with none).
const HARLAN_HOURS := 1.0
## Looked for every (s).
const LOOK_EVERY := 0.5
## The built lines, only a fallback now: the runner's words are the town's script's (TownScript, scene
## `runner` of docs/scripts/town.json; ids run_doc, run_law, runner[.shot], runner_dead[.shot], runner_you[.shot]).
const LINES := {
	&"run_doc": ["I'll get Doc! Don't move him.", "I'll go. Don't move him.", "Somebody fetch Doc... I'll go!"],
	&"run_law": ["I'll get the deputy!", "Somebody get the law... I'll go!"],
	&"runner": ["Doc! Man %s, out front of %s. %s", "Doc, come quick! Man %s by %s. %s"],
	&"runner_dead": ["Doc! There's a man dead by %s. %s", "Doc, a man's been killed, out by %s."],
	&"runner_you": ["Deputy! You'd best come. There's trouble at %s.", "Deputy! Down at %s, quick! A man's %s."],
}
## Names for the doors a runner knows (else the lot's id, spaced).
const PLACE_NAMES := {
	"general_store": "the store", "doctor": "Doc's", "saloon": "the saloon", "saloon_annex": "the saloon",
	"hotel": "the hotel", "livery": "the livery", "undertaker": "the undertaker's", "jail": "the jail",
	"bank": "the bank", "blacksmith": "the smithy", "church": "the church", "barber": "the barber's",
}

var folk: ValleyFolk
## Without folk (a lab, a test): the doctor man, and where he is when he isn't standing there.
var doctor: HumanBody
var doctor_door := Vector3.INF
## Without folk: brings the doctor out of his door when he's called (returns his body).
var bring: Callable
## Is there law to run for (the badge given)? Null: StoryState's `nolaw.deputy`.
var law: Variant = null
## Every event: the man down's instance id -> {runner (CivilianBrain), to (&"doctor"/&"harlan"),
## dead, shot_frame, ran_frame, told_frame, left_frame, route_m, told}.
var events := {}
## The doctor's calls under way: {down, man, brain, t, stage (&"beat", &"walk", &"tend"), bag}.
var calls: Array[Dictionary] = []
## Where and when (absolute clock hours, or seconds with no clock) Harlan was last seen by anyone.
var harlan_at := Vector3.INF
var harlan_when := -INF
## What happened, in order (the bridge's `events`-like trail, the tests'): [frame, what, who].
var trail: Array = []

var _look := 0.0
var _clock_s := 0.0
var _rng := RandomNumberGenerator.new()
var _tree: SceneTree


func _init(f: ValleyFolk = null) -> void:
	folk = f
	_rng.seed = 1040


# --- Asked by a Reaction ---------------------------------------------------------------------------

## Is this man the doctor (he doesn't run for himself)?
static func is_doctor(man: HumanBody) -> bool:
	return man != null and DOCTORS.has(man.person_id)


## Where a runner for this man down would go, and to whom: {to: &"doctor"/&"harlan", at, man (the
## doctor's or Harlan's body if he's out in the world, else null)}, or {} (nobody to run to).
func errand_for(down: HumanBody) -> Dictionary:
	var dead := down == null or not down.physiology.alive
	if dead:
		if not _law_now():
			return {}  # night 1: ain't nobody left to fetch
		if _harlan_known():
			var you := _player()
			if you != null and you.global_position.distance_to(down.global_position) < 15.0:
				return {}  # he's there already
			return {"to": &"harlan", "at": harlan_at, "man": you}
	var doc := doctor_errand()
	if doc.is_empty():
		return {}
	doc["to"] = &"doctor"
	return doc


## A Reaction's man would run for this man down: is he the one? True and it's his (one runner an
## event); false if another's already gone (he sees him go and stays), or one with more duty who saw
## it is still taking it in (he'll go), or the doctor saw it himself (he's coming).
func claim(down: HumanBody, brain: CivilianBrain) -> bool:
	if down == null or brain == null:
		return false
	var key := down.get_instance_id()
	var e: Dictionary = events.get(key, {})
	if not e.is_empty() and e.runner != null and is_instance_valid(e.runner) and e.runner != brain:
		return false
	var my_duty := float(brain.dials.get("duty", 0.5))
	for other: CivilianBrain in _brains(brain):
		if other == brain or other.reaction == null or not other.reaction.saw_down(down):
			continue
		var r := other.reaction
		if is_doctor(other.body) and r.stage != Reaction.Stage.NONE:
			return false  # he saw it: he's coming himself
		if r.stage in [Reaction.Stage.START, Reaction.Stage.LOOK] and other.body.physiology.can_run() \
				and float(other.dials.get("duty", 0.5)) > my_duty and r.fear <= float(other.dials.get("nerve", 0.5)):
			return false  # a better man for it is about to go
	events[key] = {"runner": brain, "to": &"", "dead": not down.physiology.alive, "shot_frame": brain.reaction.sensed_frame,
			"ran_frame": Engine.get_physics_frames(), "told_frame": -1, "left_frame": -1, "route_m": 0.0, "told": false}
	_tree = brain.get_tree()
	_note("runs", brain.body.person_id)
	return true


## The runner's errand settled (where he's going and how far the way is), for the runner's row.
func running(down: HumanBody, to: StringName, route_m: float) -> void:
	var e: Dictionary = events.get(down.get_instance_id(), {})
	if not e.is_empty():
		e.to = to
		e.route_m = route_m


## The runner's dropped it (hurt, sent off, the man gone): the event's free for another.
func gave_up(down: HumanBody, brain: CivilianBrain) -> void:
	if down == null:
		return
	var e: Dictionary = events.get(down.get_instance_id(), {})
	if not e.is_empty() and e.runner == brain and not e.told:
		events.erase(down.get_instance_id())


## He's there: he tells it (what he sensed: `shot`, the man `breathing` when he left, where), and the
## doctor comes (or Harlan's been told).
func arrived(down: HumanBody, brain: CivilianBrain, to: StringName, shot: bool, breathing: bool) -> void:
	var key := down.get_instance_id() if down != null and is_instance_valid(down) else 0
	var e: Dictionary = events.get(key, {})
	if e.is_empty() or e.told:
		return
	e.told = true
	e.told_frame = Engine.get_physics_frames()
	var where := place_name(down.global_position) if key != 0 else "the street"
	var base := &"runner_you" if to == &"harlan" else (&"runner_dead" if not breathing else &"runner")
	var ids: Array = [String(base) + ".shot", String(base)] if shot else [String(base)]
	var line := TownScript.pick(ids, TownScript.seed_of(String(brain.body.person_id), "%s:%d" % [ids[0], key]), {"where": where})
	if line == "":
		line = _built_arrival(base, where, shot, breathing)
	brain.say_line(line.strip_edges())
	_note("told " + String(to), brain.body.person_id)
	# The news goes with him (TownNews): the doctor now holds the runner's version.
	if brain.news != null:
		brain.news.hand_over(brain.body.person_id, DOCTOR if to == &"doctor" else TownNews.HARLAN, down if key != 0 else null)
	if to == &"doctor" and key != 0:
		_call_doctor(down)


# --- The doctor's call -------------------------------------------------------------------------------

func _call_doctor(down: HumanBody) -> void:
	for c: Dictionary in calls:
		if c.down == down:
			return
	calls.append({"down": down, "man": null, "brain": null, "t": 0.0, "stage": &"beat", "bag": null})


## Each frame (ValleyFolk's _process, or a lab's): the calls, and every half second who's seen Harlan.
func step(delta: float) -> void:
	_clock_s += delta
	_look -= delta
	if _look <= 0.0:
		_look = LOOK_EVERY
		_look_for_harlan()
	for c: Dictionary in calls.duplicate():
		_call_step(c, delta)


## A knock at the doctor's door with `down` by it (ValleyFolk.knock, #1095): the doctor answers for
## any hurt man, not only an act's. In, he comes out to him; out on a call to this same man (the
## runner sent him to where he fell), he comes back for him; dead, gone or an act's, nobody comes.
## He takes him in (ValleyFolk.take_in): treating him by his wounds is #1093. What the player's told.
func at_door(down: HumanBody, door: Vector3, inside: bool) -> String:
	if down == null or not is_instance_valid(down):
		return ""
	for c: Dictionary in calls:
		if c.down == down and c.get("door", false):
			return ""  # he's coming for him already
	var doc := doctor_errand()
	if doc.is_empty():
		_note("knock: no doctor", &"")
		return "Nobody answers."
	var man: HumanBody = doc.get("man")
	var bag: Node3D = null
	for c: Dictionary in calls.duplicate():
		if c.man != null and is_instance_valid(c.man) and c.man == man and c.down != down:
			_note("knock: the doctor's on another call", &"")
			return "Nobody answers. The doctor's out on a call."
		if c.down == down:
			bag = c.bag  # on his way to where the man fell: back he comes, bag and all
			calls.erase(c)
	calls.append({"down": down, "man": null, "brain": null, "t": 0.0, "stage": &"door", "bag": bag,
			"door": true, "door_at": door, "inside": inside})
	_note("knock: the doctor answers", &"")
	return "Steps inside: the doctor's coming." if inside else "Nobody answers. The doctor's out."


## Calls this man was on, dropped (an act's taken him: ValleyFolk.seize). His bag goes.
func drop_calls(man: HumanBody) -> void:
	for c: Dictionary in calls.duplicate():
		if c.man == man:
			if c.bag != null and is_instance_valid(c.bag):
				(c.bag as Node).queue_free()
			calls.erase(c)


func _call_step(c: Dictionary, delta: float) -> void:
	c.t += delta
	var down: HumanBody = c.down if is_instance_valid(c.down) else null
	match c.stage:
		&"door":
			if down == null:
				calls.erase(c)
				return
			if c.inside and c.t < ANSWER_S:
				return
			c.stage = &"beat"
			c.t = BAG_BEAT
			_call_step(c, 0.0)
		&"in":
			var man: HumanBody = c.man if is_instance_valid(c.man) else null
			if down == null or man == null or not man.physiology.alive:
				_end_call(c)
				return
			if c.t >= TAKE_IN_S:
				if folk != null:
					folk.take_in(down)
				_note("doctor takes him in", man.person_id)
				_end_call(c)
		&"beat":
			if c.t < BAG_BEAT:
				return
			var man := _bring_doctor()
			if man == null:
				calls.erase(c)
				_note("no doctor", &"")
				return
			var brain := man.get_node_or_null(^"Brain") as CivilianBrain
			c.man = man
			c.brain = brain
			c.stage = &"walk"
			c.t = 0.0
			if c.bag == null or not is_instance_valid(c.bag):
				c.bag = _bag(man)
			var e: Dictionary = events.get(down.get_instance_id(), {}) if down else {}
			if not e.is_empty():
				e.left_frame = Engine.get_physics_frames()
			_note("doctor leaves", man.person_id)
			if brain != null and down != null:
				brain.reaction.forget()
				brain.chores = []
				brain.chore = null
				brain.walk_speed = DOC_WALK
				var from := man.global_position - down.global_position
				from.y = 0.0
				brain.go_to(down.global_position + (from.normalized() if from.length() > 0.1 else Vector3.FORWARD) * 0.85,
						down.global_position)
				brain.rest_pose = &"tend"
		&"walk", &"tend":
			var man: HumanBody = c.man if is_instance_valid(c.man) else null
			if man == null or not man.physiology.alive:
				_end_call(c)
				return
			var brain: CivilianBrain = c.brain
			var down_at := ValleyFolk._body_at(down) if down != null else Vector3.ZERO
			if c.get("door", false) and brain != null and down != null and down_at.distance_to(brain.post) > 2.0:
				# (at the door: you've moved him, or let him down off your shoulder) to him where he is now
				var from := man.global_position - down_at
				from.y = 0.0
				brain.go_to(down_at + (from.normalized() if from.length() > 0.1 else Vector3.FORWARD) * 0.85, down_at)
			var there := brain != null and man.global_position.distance_to(brain.post) < 0.5
			if c.stage == &"walk" and c.get("door", false) and there:
				c.stage = &"in"
				c.t = 0.0
				_set_down(c.bag, man)
				man.face(down_at)
				return
			if c.stage == &"walk":
				_carry(c.bag, man)
				if there:
					c.stage = &"tend"
					c.t = 0.0
					_set_down(c.bag, man)
					_note("doctor tends", man.person_id)
			elif not there:
				_carry(c.bag, man)  # a fright moved him: picked up again
			elif c.t >= TEND_FOR or down == null:
				_end_call(c)


func _end_call(c: Dictionary) -> void:
	calls.erase(c)
	var man: HumanBody = c.man if is_instance_valid(c.man) else null
	if c.bag != null and is_instance_valid(c.bag):
		(c.bag as Node).queue_free()
	if man == null:
		return
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if brain:
		brain.walk_speed = CivilianBrain.WALK
		brain.rest_pose = &"stand"
	if folk != null:
		folk.call_over(man.person_id)
	_note("doctor done", man.person_id)


## The doctor's bag: the prop lab's model (#823) as drawn, carried; a box if it isn't there.
func _bag(man: HumanBody) -> Node3D:
	var bag: Node3D
	var scene := load("res://assets/props/models/doctors_bag.glb") as PackedScene if ResourceLoader.exists("res://assets/props/models/doctors_bag.glb") else null
	if scene != null:
		bag = scene.instantiate() as Node3D
	else:
		var m := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.4, 0.23, 0.2)
		m.mesh = b
		bag = m
	bag.name = "DoctorsBag"
	man.get_parent().add_child(bag)
	_carry(bag, man)
	return bag


## In his right hand, at his side.
func _carry(bag: Node3D, man: HumanBody) -> void:
	if bag == null or not is_instance_valid(bag):
		return
	bag.global_transform = Transform3D(man.global_basis, man.global_transform * Vector3(0.3, 0.5, 0.02))
	man.curl_hand("r", 0.8)


## Set down beside him, on the ground at his right.
func _set_down(bag: Node3D, man: HumanBody) -> void:
	if bag == null or not is_instance_valid(bag):
		return
	var at := man.global_transform * Vector3(0.45, 0.0, 0.15)
	at.y = man.global_position.y
	bag.global_transform = Transform3D(man.global_basis.rotated(Vector3.UP, 0.4), at)


# --- Where everyone is ------------------------------------------------------------------------------

## The doctor: {at (where a runner goes: his door if he's indoors, else where he stands), man (his
## body, if he's out in the world)}, or {} (no doctor: out of town, dead, an act has him).
func doctor_errand() -> Dictionary:
	if folk == null:
		if doctor != null and is_instance_valid(doctor) and doctor.physiology.alive:
			return {"at": doctor.global_position if doctor.is_inside_tree() else doctor_door, "man": doctor if doctor.is_inside_tree() else null}
		return {"at": doctor_door, "man": null} if doctor_door != Vector3.INF else {}
	return folk.doctor_where()


## Out of his door (or already out): his body, or null.
func _bring_doctor() -> HumanBody:
	if folk == null:
		if (doctor == null or not is_instance_valid(doctor) or not doctor.is_inside_tree()) and bring.is_valid():
			doctor = bring.call()
		return doctor if doctor != null and is_instance_valid(doctor) and doctor.is_inside_tree() else null
	return folk.call_out(DOCTOR)


func _law_now() -> bool:
	if law != null:
		return bool(law)
	return bool(StoryState.get_fact("nolaw.deputy", false))


func _harlan_known() -> bool:
	if harlan_at == Vector3.INF:
		return false
	return _now() - harlan_when <= HARLAN_HOURS * (1.0 if _hours() else Reaction.SHAKEN_SECONDS)


func _look_for_harlan() -> void:
	var you := _player()
	if you == null:
		return
	for b: CivilianBrain in _brains(null):
		if b.senses != null and b.senses.sees(you):
			harlan_at = you.global_position
			harlan_when = _now()
			return


## The clock in hours (day x 24 + hour), or seconds with no clock.
func _now() -> float:
	var day := _day_cycle()
	if day != null:
		return float(day.get(&"day")) * 24.0 + float(day.get(&"time_of_day"))
	return _clock_s


func _hours() -> bool:
	return _day_cycle() != null


func _day_cycle() -> Node:
	var t := _scene_tree()
	return t.get_first_node_in_group(&"day_cycle") if t else null


func _player() -> Node3D:
	var t := _scene_tree()
	return t.get_first_node_in_group(&"player") as Node3D if t else null


func _scene_tree() -> SceneTree:
	if folk != null and folk.is_inside_tree():
		return folk.get_tree()
	return _tree


## The townsmen who might see (ValleyFolk's in the world; else every CivilianBrain under the tree).
func _brains(near: CivilianBrain) -> Array[CivilianBrain]:
	var out: Array[CivilianBrain] = []
	if folk != null:
		for m: HumanBody in folk.people.values():
			if is_instance_valid(m):
				var b := m.get_node_or_null(^"Brain") as CivilianBrain
				if b:
					out.append(b)
		return out
	if near != null:
		_tree = near.get_tree()
	var t := _scene_tree()
	if t:
		for n in t.get_nodes_in_group(&"civilians"):
			out.append(n as CivilianBrain)
	return out


## The nearest door a runner knows to `at`, as he'd say it ("the store", "Doc's"); "the street".
func place_name(at: Vector3) -> String:
	if folk == null or folk.places == null or folk.town == null:
		return "the street"
	var best := ""
	var best_d := 30.0
	for w: Dictionary in folk.town.walks:
		var id := String(w.id)
		if not folk.places.has(StringName(id)):
			continue
		var d := Vector2(at.x, at.z).distance_to(Vector2(folk.places.at(StringName(id)).x, folk.places.at(StringName(id)).z))
		if d < best_d:
			best_d = d
			best = id
	if best == "":
		return "the street"
	return PLACE_NAMES.get(best, "the " + best.replace("_", " "))


var _pick_n := 0


func _pick(kind: StringName) -> String:
	var lines: Array = LINES[kind]
	_pick_n = _rng.randi() % lines.size()
	return lines[_pick_n]


## The built line on arrival (no script).
func _built_arrival(base: StringName, where: String, shot: bool, breathing: bool) -> String:
	match base:
		&"runner_you":
			return _pick(base) % ([where] if _pick_n == 0 else [where, "shot" if shot else "down"])
		&"runner_dead":
			return _pick(base) % ([where, "Shot." if shot else ""] if _pick_n == 0 else [where])
	return _pick(base) % ["shot" if shot else "down", where, "He's breathing." if breathing else ""]


## A runner's start line (he's off): the script's, by `who` (his person id), else a built one.
func off_line(to: StringName, who := "") -> String:
	var id := "run_law" if to == &"harlan" else "run_doc"
	var line := TownScript.pick([id], TownScript.seed_of(who, id) if who != "" else _rng.randi())
	return line if line != "" else _pick(StringName(id))


func _note(what: String, who: StringName) -> void:
	trail.append([Engine.get_physics_frames(), what, who])
	if trail.size() > 60:
		trail.pop_front()


## For the bridge (`read fetch`) and the tests.
func report() -> Dictionary:
	var ev := []
	for k: int in events:
		var e: Dictionary = events[k]
		ev.append({"runner": String(e.runner.body.person_id) if e.runner != null and is_instance_valid(e.runner) else "",
				"to": String(e.to), "dead": e.dead, "shot_frame": e.shot_frame, "ran_frame": e.ran_frame,
				"told_frame": e.told_frame, "left_frame": e.left_frame, "route_m": snappedf(e.route_m, 0.1)})
	return {"events": ev, "calls": calls.map(func(c: Dictionary) -> String: return String(c.stage)),
			"harlan_seen": harlan_at != Vector3.INF and _harlan_known(), "log": trail.slice(-12)}
