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


func _init(f: ValleyFolk = null, d: Dictionary = {}) -> void:
	folk = f
	dials = d


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
		if shown.has(pid) or d > near or folk.state.get(pid) != &"in" or folk._person(pid).has("act"):
			continue
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
