class_name TownRegard
extends RefCounted
## How the town treats Harlan (townsfolk step 9, #1152; docs/briefs/townsfolk.md §5 "How the town
## treats Harlan"). Each townsman's opinions of him, DESIGN §9's four numbers (trust, fear, liking,
## respect), come from what *he* holds: his own TownNews versions of what Harlan did (his view:
## stopped_a_killer / shot_a_man, and a little more fear for each further man he has Harlan shooting)
## and the story's facts (the brief's facts table), nudged by the dials in ValleyFolk's data
## `regard`. Worked out afresh when asked, so nothing new to save: the news and StoryState are.
## His band: afraid (fear at `afraid_at`), else by his warmth (trust, liking and respect averaged):
## warm, wary, cold. The town's regard is the plain average of its people's opinions.
## What he shows as Harlan passes (CivilianBrain.show_regard): warm a nod; wary a look that slides
## off; cold a turned shoulder; afraid the walk clears (he steps aside).

const NAMES: Array[String] = ["trust", "fear", "liking", "respect"]
## What he saw Harlan do himself (fault 1 of the town gate, #1167: a shot, a shove, a won pot moved
## nothing, since only killings and the story's facts counted). Deeds are Events.deed's with the
## player the actor, and `won_pot` (the card table); each `deeds` dial is what one such deed seen
## adds, double (`to_him`) for the man it was done to; the nth of a kind adds `each_more`^(n-1) of
## it. And `fired`: each of his news versions with Harlan firing and nobody down (seen or told).
## What each band shows as Harlan passes.
const SHOWS := {&"warm": &"nod", &"wary": &"look_away", &"cold": &"turn", &"afraid": &"clear"}

var folk: ValleyFolk
var dials: Dictionary = {}
## Who's shown him this pass (pid -> true), till Harlan's `show_m` + `show_clear_m` off.
var shown := {}
## What was shown: [pid, band, show].
var log: Array = []
var _look := 0.0
## For tests without the folk: pid -> his view, and pid -> how many men he has Harlan shooting.
var view_of := {}
var shots_of := {}
## pid -> {kind: weight}: what he saw Harlan do (saved with the town: save_dict / load_dict).
var deeds := {}


func _init(f: ValleyFolk = null, d: Dictionary = {}) -> void:
	folk = f
	dials = d
	if f != null:
		Events.deed.connect(_on_deed)


func _d(k: String, dflt: float) -> float:
	return float(dials.get(k, dflt))


## His view of Harlan from his own news ("" if he holds none).
func view(pid: StringName) -> StringName:
	if view_of.has(pid):
		return StringName(String(view_of[pid]))
	if folk != null and folk.news != null:
		return folk.news.view_of_harlan(pid)
	return &""


## How many men he has Harlan shooting (his versions with Harlan firing and a man down).
func _harlan_shot(pid: StringName) -> int:
	if shots_of.has(pid):
		return int(shots_of[pid])
	if folk == null or folk.news == null:
		return 1 if view(pid) != &"" else 0
	var n := 0
	for rid: int in (folk.news.versions.get(pid, {}) as Dictionary):
		var v := folk.news.version_of(pid, rid)
		if v.who == TownNews.HARLAN and v.whom != &"" and v.down:
			n += 1
	return n


## His four numbers: trust, liking, respect in -1..1, fear 0..1.
func opinions(pid: StringName) -> Dictionary:
	var o := {"trust": 0.0, "fear": 0.0, "liking": 0.0, "respect": 0.0}
	var v := view(pid)
	if v != &"":
		_add(o, (dials.get("view", {}) as Dictionary).get(String(v), {}))
		o.fear += _d("fear_each_more", 0.12) * maxi(_harlan_shot(pid) - 1, 0)
	var dd: Dictionary = dials.get("deeds", {})
	var mine: Dictionary = deeds.get(pid, {})
	for k: String in mine:
		_add_scaled(o, dd.get(k, {}), float(mine[k]))
	var fired := _harlan_fired(pid)
	if fired > 0:
		_add_scaled(o, dd.get("fired", {}), _ladder(fired))
	for f: Dictionary in dials.get("facts", []):
		if not ValleyFolk.story_holds(f.get("if", {})):
			continue
		_add(o, f.get("all", {}))
		_add(o, (f.get("who", {}) as Dictionary).get(String(pid), {}))
		var split: Array = f.get("split", [])
		if not split.is_empty():
			_add(o, split[TownScript.seed_of(String(pid), "split:" + str(f.get("if", {}))) % split.size()])
	for k: String in ["trust", "liking", "respect"]:
		o[k] = clampf(o[k], -1.0, 1.0)
	o.fear = clampf(o.fear, 0.0, 1.0)
	return o


static func _add_scaled(o: Dictionary, n: Dictionary, by: float) -> void:
	for k: String in n:
		if o.has(k):
			o[k] += float(n[k]) * by


## n of a kind, each worth `each_more` of the last: 1, 1.5, 1.75 ... at 0.5.
func _ladder(n: float) -> float:
	var r := _d("each_more", 0.5)
	var whole := int(n)
	var sum := (1.0 - pow(r, whole)) / (1.0 - r) if r < 1.0 else float(whole)
	return sum + (n - whole) * pow(r, whole)


## His versions with Harlan firing and nobody down by it (a shot in the air, shots at a man missed).
func _harlan_fired(pid: StringName) -> int:
	if folk == null or folk.news == null:
		return 0
	var n := 0
	for rid: int in (folk.news.versions.get(pid, {}) as Dictionary):
		var v := folk.news.version_of(pid, rid)
		if v.who == TownNews.HARLAN and not v.down and not v.get("rough", false):
			n += 1
	return n


## Harlan did `kind` (to `target`, at `at`): every day-folk man there who saw it keeps it.
func _on_deed(actor: Node, kind: StringName, target: Node, at: Vector3) -> void:
	if not actor is Player or not (dials.get("deeds", {}) as Dictionary).has(String(kind)):
		return
	saw_harlan(String(kind), at, actor as Node3D, target)


## The men who see Harlan within `see_m` of `at` (or are `target`) keep `kind`. Returns who did.
func saw_harlan(kind: String, at: Vector3, harlan: Node3D, target: Node = null) -> Array[StringName]:
	var out: Array[StringName] = []
	if folk == null:
		return out
	var ps := people()
	for pid: StringName in folk.people:
		var man: HumanBody = folk.people[pid]
		if man == null or not is_instance_valid(man) or not ps.has(pid) or not man.physiology.alive:
			continue
		var him := man == target
		if not him:
			if man.global_position.distance_to(at) > _d("see_m", 20.0):
				continue
			var b := man.get_node_or_null(^"Brain") as CivilianBrain
			if b == null or b.senses == null or harlan == null or not b.senses.sees(harlan):
				continue
		var mine: Dictionary = deeds.get(pid, {})
		deeds[pid] = mine
		var n := float(mine.get("_n_" + kind, 0.0)) + (_d("to_him", 2.0) if him else 1.0)
		mine["_n_" + kind] = n
		mine[kind] = _ladder(n)
		out.append(pid)
	return out


func save_dict() -> Dictionary:
	return {"deeds": deeds.duplicate(true)}


func load_dict(d: Dictionary) -> void:
	deeds = {}
	for pid: Variant in d.get("deeds", {}):
		deeds[StringName(String(pid))] = (d.deeds[pid] as Dictionary).duplicate()


static func _add(o: Dictionary, n: Dictionary) -> void:
	for k: String in n:
		if o.has(k):
			o[k] += float(n[k])


## Trust, liking and respect averaged.
static func warmth(o: Dictionary) -> float:
	return (float(o.trust) + float(o.liking) + float(o.respect)) / 3.0


func band_of(o: Dictionary) -> StringName:
	if float(o.fear) >= _d("afraid_at", 0.55):
		return &"afraid"
	var w := warmth(o)
	if w >= _d("warm_at", 0.2):
		return &"warm"
	if w <= _d("cold_at", -0.2):
		return &"cold"
	return &"wary"


## His band.
func band(pid: StringName) -> StringName:
	return band_of(opinions(pid))


## The town's people (the day folk): everyone a regard is kept for.
func people() -> Array[StringName]:
	var out: Array[StringName] = []
	if folk != null:
		for p: Dictionary in folk.data.get("people", []):
			if p.has("day") and not p.has("act"):
				out.append(StringName(p.id))
	for pid: Variant in view_of:
		if not out.has(StringName(String(pid))):
			out.append(StringName(String(pid)))
	return out


## The town's opinions, the plain average of its people's.
func town() -> Dictionary:
	var sum := {"trust": 0.0, "fear": 0.0, "liking": 0.0, "respect": 0.0}
	var ps := people()
	for pid: StringName in ps:
		_add(sum, opinions(pid))
	for k: String in sum:
		sum[k] = sum[k] / maxf(ps.size(), 1.0)
	return sum


func town_band() -> StringName:
	return band_of(town())


## Each look (`look_s`): a man at his post, calm, who sees Harlan within `show_m` and hasn't this
## pass shows him his band. Harlan `show_clear_m` further off and he may again next time.
func step(delta: float, harlan: Node3D) -> void:
	_look -= delta
	if _look > 0.0 or folk == null or harlan == null:
		return
	_look = _d("look_s", 0.25)
	var near := _d("show_m", 7.0)
	for pid: StringName in folk.people:
		var man: HumanBody = folk.people[pid]
		if man == null or not is_instance_valid(man):
			continue
		var d := Vector2(man.global_position.x - harlan.global_position.x, man.global_position.z - harlan.global_position.z).length()
		if d > near + _d("show_clear_m", 5.0):
			shown.erase(pid)
			continue
		if shown.has(pid) or d > near or folk.state.get(pid) != &"in" or folk._person(pid).has("act") \
				or not folk._person(pid).has("day"):
			continue  # (the day folk only: No Law's set men keep to their cards)
		var b := man.get_node_or_null(^"Brain") as CivilianBrain
		if b == null or not b.can_show():
			continue
		if b.senses != null and not b.senses.sees(harlan):
			continue
		var bd := band(pid)
		shown[pid] = true
		var what: StringName = SHOWS[bd]
		b.show_regard(what, harlan)
		log.append([String(pid), String(bd), String(what)])


## For the bridge's `read regard`: each man's band and numbers, and the town's.
func report() -> Dictionary:
	var out := {}
	for pid: StringName in people():
		var o := opinions(pid)
		var r := {"band": String(band_of(o)), "view": String(view(pid))}
		for k: String in o:
			r[k] = snappedf(o[k], 0.01)
		out[String(pid)] = r
	out["_town"] = {"band": String(town_band())}
	out["_shown"] = log.slice(-20)
	return out
