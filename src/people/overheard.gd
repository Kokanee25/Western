class_name Overheard
extends RefCounted
## Things to listen to (#1293; Sean, 2026-11-26: "people just at the bar chatting and talking,
## things to listen to"). Two or three of the valley's men who stand by each other hold an
## **exchange**: 2 to 8 lines back and forth, each answering the last, written for those very men
## from their cards (docs/story/people.json) in the town's script (docs/scripts/town.json, scenes
## `heard.*`: a line's `ex` its exchange, `who` says it `to` whom, at `place`, with a `delivery`).
##
## - **Who and where:** an exchange is cast by person (friends talk, enemies needle: that is in the
##   writing) and tagged with a place of people.json's `places` (`saloon.bar`, `saloon.table`,
##   `store`, `street`, `livery`, `hotel`...): it starts only with its whole cast in play, calm, free
##   to speak, at spots that carry that tag (`tags_of`: data `tags`) and within `talk_m` of each other.
## - **When and what the town knows:** the exchange's `if` (its first line's; TownBarks' keys, asked
##   of the man who opens: `hour`, `day` the day kind (payday, sunday, uneasy), `fact` StoryState
##   facts (the sheriff dead, the deputy sworn), `regard`, `view` his own news of Harlan, `once`).
## - **Heard:** only with you near (`start_m`): talk nobody hears isn't spent. Each line goes out as
##   `Events.overheard` (his mouth, FaceSpeech; the subtitle, PlayerWounds), with a `clarity` 0 to 1:
##   whole within `clear_m`, thinning to nothing at `hear_m`, a wall between (Sight) leaving `wall`
##   of it. Under `full_at` words drop out of the subtitle (`garbled`); under `min_clarity` nothing shows.
## - **Not twice a night:** an exchange you heard (`heard_at`) isn't held again that town day, and
##   the ones you've never heard come first, then the longest unheard (`heard_day`, kept in the save).
## - **Interrupted:** a shot (`shot_m`), a man of it no longer calm (a fight, a fright, a scene taking
##   him), one of them saying something else (a bark at you, the barkeep serving), your shout, or
##   one walking off: it stops there, mid-exchange. Stand close (`notice.m`) for `notice.s` and one of
##   them may turn to you instead (`heard.you`, by his regard: pillar 6, people start things).
## - **The card table** talks between hands, not over them: CardGame asks `table_break` at each
##   hand's end; it starts a `saloon.table` exchange of the men sat there and answers how long to wait.
## - **The budget:** `step` every frame is a couple of compares; a start is looked for once `try_s`.
## Old one-line `chat` (ValleyFolk._chat_step) goes out the same way (`murmur`), so it fades too.

## Defaults; ValleyFolk's data `overheard` may set them.
const DIALS := {
	"hear_m": 10.0, "clear_m": 3.5, "wall": 0.35, "full_at": 0.8, "min_clarity": 0.12, "heard_at": 0.3,
	"start_m": 11.0, "talk_m": 6.5, "try_s": 2.0, "stagger_s": 8.0, "rest_s": [50.0, 90.0],
	"first_s": [4.0, 14.0], "pause_s": [0.3, 1.0], "max_at_once": 2, "unheard_again_s": 240.0,
	"table_gap_s": 60.0, "table_hold_s": 26.0, "shot_m": 40.0, "shout_m": 12.0, "before_murder": true,
	"notice": {"m": 2.0, "s": 7.0, "chance": 0.5, "again_s": 150.0},
}

var folk: ValleyFolk
var d: Dictionary = DIALS.duplicate(true)

## Exchange id -> the town day you last heard it (saved); -1 never.
var heard_day := {}
## The exchanges going on: [{ex, i, at, men {pid: HumanBody}, best, near_s, said}].
var running: Array = []
## What ended and why: [ex id, why (done, shot, shout, spoke, gone, calm, story, noticed), lines said].
var ended: Array = []
## What was said: [ex id, line id, pid, text, clarity, when].
var log: Array = []

var _rest := {}
var _try_at := 0.0
var _left := {}
var _table_at := -INF
var _noticed_at := -INF
var _out: Array = []


func _init(f: ValleyFolk, dials: Dictionary = {}) -> void:
	folk = f
	for k: String in dials:
		if not k.begins_with("_"):
			d[k] = dials[k]


func _r(key: String, pid: String, what: String) -> float:
	var v: Variant = d.get(key)
	if v is Array:
		return lerpf(float(v[0]), float(v[1]), folk._jit(StringName(pid), what))
	return float(v)


# --- Where a man is, as the cards and the board say it -------------------------------------------

## His place tags now (people.json's `places`), the nearest first: a spot's own (`tags.spots`), a
## bar's customer or its barman (`saloon.bar`), his spot's lot (`tags.lots`), else the street.
func tags_of(pid: StringName, _man: HumanBody = null) -> Array:
	var p := folk._person(pid)
	if not p.has("day"):
		return []
	var b := folk.block_now(p, folk.hour())
	var t: Dictionary = d.get("tags", {})
	var name := String(b.get("at", "")) if b.get("at") is String else ""
	var spots: Dictionary = t.get("spots", {})
	if spots.has(name):
		return spots[name]
	var sp := folk.spot(b.at) if b.has("at") else {}
	if sp.has("chair"):
		return t.get("chair", ["saloon.table"])
	if sp.has("behind") or sp.has("at_bar") or String(sp.get("use", "")).begins_with("drinker") or String(sp.get("use", "")).begins_with("barman"):
		return ["saloon.bar"]
	if sp.has("hall"):
		return (t.get("halls", {}) as Dictionary).get(String(sp.hall), ["saloon.room"])
	if sp.has("lot"):
		return (t.get("lots", {}) as Dictionary).get(String(sp.lot), ["street"])
	return []


## May he take part now? In play at his spot, awake, calm, free to speak, not held by a scene.
func free_man(pid: StringName, now: float, table := false) -> HumanBody:
	var pd := folk._person(pid)
	if pd.is_empty() or pd.has("act") or not pd.has("day") or folk.state.get(pid) != &"in":
		return null
	var man := folk.folk_man(pid)
	if man == null or not man.is_inside_tree() or busy(pid) or now < float(_rest.get(pid, -INF)):
		return null
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	if brain == null or not brain.may_speak() or not TownNews._calm(brain):
		return null
	var doing := String(folk.block_now(pd, folk.hour()).get("do", ""))
	if doing == "sleep":
		return null
	if doing == "play":
		# The card players talk between hands (`table`); the band between tunes.
		if tags_of(pid).has("saloon.room"):
			if table or folk.band == null or folk.band.state != &"between":
				return null
		elif not table:
			return null
	elif table:
		return null
	if now - float(folk._spoke_at.get(pid, -INF)) < 4.0:
		return null  # he's just said something to you
	return man


## Is he in an exchange now?
func busy(pid: StringName) -> bool:
	for r: Dictionary in running:
		if (r.men as Dictionary).has(pid):
			return true
	return false


# --- Picking -------------------------------------------------------------------------------------

## The exchanges that could start now among the free men near you, the best first: never heard
## before the longest unheard, the more particular `if` first, then by the day's own shuffle.
func fitting(now: float, table := false) -> Array:
	var p := _player()
	if p == null:
		return []
	var day := folk.town_day()
	var free := {}
	var tags := {}
	var found: Array = []
	for id: String in TownScript.exchanges():
		var ex: Dictionary = TownScript.exchanges()[id]
		var c: Dictionary = ex["if"]
		if String(c.get("on", "")) != "heard" or (String(ex.place) == "saloon.table" and _at_cards(ex)) != table:
			continue
		var last := int(heard_day.get(id, -1))
		if last == day or (String(c.get("once", "")) == "ever" and last >= 0):
			continue
		if now - float(_left.get(id, -INF)) < float(d.unheard_again_s):
			continue
		var ok := true
		var men := {}
		for who: String in ex.cast:
			var pid := StringName(who)
			if not free.has(pid):
				free[pid] = free_man(pid, now, table)
				tags[pid] = tags_of(pid) if free[pid] != null else []
			if free[pid] == null or not (tags[pid] as Array).has(String(ex.place)):
				ok = false
				break
			men[pid] = free[pid]
		if not ok or not _together(men, p.global_position):
			continue
		var opener := StringName(String(ex.lines[0].who))
		if not TownBarks.holds(c, folk.bark_ctx(opener, men[opener])):
			continue
		found.append([0 if last < 0 else 1, last, -(TownBarks.specificity(c) + (ex.cast as Array).size()),
				TownScript.seed_of(id, "%d:%d" % [day, folk.run_seed]) % 9973, id, men])
	found.sort_custom(func(x: Array, y: Array) -> bool:
		for i in 5:
			if x[i] != y[i]:
				return x[i] < y[i]
		return false)
	return found


## A table exchange is the card table's own (started between hands) if its cast sit at the cards.
func _at_cards(ex: Dictionary) -> bool:
	for who: String in ex.cast:
		var pd := folk._person(StringName(who))
		if pd.is_empty() or not pd.has("day") or String(folk.block_now(pd, folk.hour()).get("do", "")) != "play" \
				or not tags_of(StringName(who)).has("saloon.table"):
			return false
	return true


func _together(men: Dictionary, you: Vector3) -> bool:
	var ids := men.keys()
	var near := false
	for i in ids.size():
		var a: HumanBody = men[ids[i]]
		near = near or a.global_position.distance_to(you) <= float(d.start_m)
		for j in range(i + 1, ids.size()):
			if a.global_position.distance_to((men[ids[j]] as HumanBody).global_position) > float(d.talk_m):
				return false
	return near


func _player() -> Node3D:
	return folk.get_tree().get_first_node_in_group(&"player") as Node3D if folk.is_inside_tree() else null


# --- Running -------------------------------------------------------------------------------------

func step(now: float) -> void:
	if not running.is_empty():
		_advance(now)
	if now < _try_at:
		return
	_try_at = now + float(d.try_s)
	if running.size() >= int(d.max_at_once) or _story(now):
		return
	var f := fitting(now)
	if not f.is_empty():
		_begin(f[0][4], f[0][5], now, _r("first_s", String(f[0][4]), "first") if log.is_empty() else 0.4)
		_try_at = now + float(d.stagger_s)


func _begin(id: String, men: Dictionary, now: float, wait: float) -> void:
	running.append({"ex": TownScript.exchanges()[id], "i": 0, "at": now + wait, "men": men, "best": 0.0, "near_s": 0.0, "said": 0, "t": now})
	for pid: StringName in men:
		folk._chat_at[pid] = now  # the one-line chat keeps off them


## A story's scene has the town (ValleyFolk._story_on), but for No Law's first evening before the
## murder begins, if `before_murder`: the room talks till the scene starts.
func _story(_now: float) -> bool:
	for m: Moment in [folk.murder, folk.funeral]:
		if m != null and is_instance_valid(m) and not m.done:
			return true
	if folk.state.values().has(&"act"):
		return true
	return not bool(d.before_murder) and folk._story_on()


func _advance(now: float) -> void:
	var p := _player()
	for r: Dictionary in running.duplicate():
		var why := _broken(r)
		if why == "" and _story(now):
			why = "story"
		if why != "":
			_end(r, why, now)
			continue
		if p != null and _notice(r, p, now):
			continue
		if now < float(r.at):
			continue
		var ex: Dictionary = r.ex
		var l: Dictionary = ex.lines[int(r.i)]
		var man: HumanBody = r.men[StringName(String(l.who))]
		var to: HumanBody = r.men.get(StringName(String(l.to)))
		if to == null:
			for pid: StringName in r.men:
				if r.men[pid] != man:
					to = r.men[pid]
					break
		var text := TownScript.pick([String(l.id)], 0)
		if text != "":
			if to != null:
				man.face(to.global_position + Vector3.UP * 1.5)
				to.face(man.global_position + Vector3.UP * 1.5)
			_out.append([man, text, {"exchange": String(ex.id), "line": String(l.id), "delivery": String(l.delivery),
					"to": to, "place": String(ex.place), "r": r}])
			r.said = int(r.said) + 1
			folk.heard.append([String(l.who), String(l.id), text])
		r.i = int(r.i) + 1
		if int(r.i) >= (ex.lines as Array).size():
			_end(r, "done", now)
		else:
			r.at = now + FaceSpeech.subtitle_seconds(text) + _r("pause_s", String(l.id), "pause:%d" % folk.run_seed)


## Why an exchange can't go on ("" if it can): a man of it gone, down, frightened, held or walked off.
func _broken(r: Dictionary) -> String:
	var men: Dictionary = r.men
	var ids := men.keys()
	for i in ids.size():
		var man: HumanBody = men[ids[i]]
		if man == null or not is_instance_valid(man) or not man.is_inside_tree() or folk.state.get(ids[i]) != &"in":
			return "gone"
		var brain := man.get_node_or_null(^"Brain") as CivilianBrain
		if brain == null or not brain.may_speak() or not TownNews._calm(brain):
			return "calm"
		for j in range(i + 1, ids.size()):
			if man.global_position.distance_to((men[ids[j]] as HumanBody).global_position) > float(d.talk_m) + 2.0:
				return "gone"
	return ""


## You've stood right by them a while: one of them turns to you (a `heard.you` line of his own, by
## his regard) and the exchange stops there. Not every time (`notice.chance`), not twice in `again_s`.
func _notice(r: Dictionary, p: Node3D, now: float) -> bool:
	var n: Dictionary = d.notice
	var nearest: StringName = &""
	var best := float(n.m)
	for pid: StringName in r.men:
		var dist := (r.men[pid] as HumanBody).global_position.distance_to(p.global_position)
		if dist < best:
			best = dist
			nearest = pid
	if nearest == &"":
		r.near_s = 0.0
		return false
	r.near_s = float(r.near_s) + folk.get_process_delta_time()
	if float(r.near_s) < float(n.s) or r.has("passed") or now - _noticed_at < float(n.again_s) or int(r.said) < 1:
		return false
	if float(TownScript.seed_of(String(r.ex.id), "notice:%d:%d" % [folk.town_day(), folk.run_seed]) % 1000) / 1000.0 >= float(n.chance):
		r["passed"] = true  # they let you listen
		return false
	var man: HumanBody = r.men[nearest]
	var l: Array = folk.barks.pick("heard.you", folk.bark_ctx(nearest, man), folk.town_day(), now) if folk.barks else []
	if l.is_empty():
		r["passed"] = true
		return false
	_noticed_at = now
	_end(r, "noticed", now)
	man.face(p.global_position + Vector3.UP * 1.5)
	folk._spoke_at[nearest] = now
	folk.heard.append([String(nearest), String(l[0]), String(l[1])])
	folk.say_soon(man, String(l[1]))
	return true


func _end(r: Dictionary, why: String, now: float) -> void:
	running.erase(r)
	var id := String(r.ex.id)
	ended.append([id, why, int(r.said)])
	# Heard or not is settled once its last line is out (`flush`: how clearly, the physics frame's).
	r["why"] = why
	_over.append(r)
	for pid: StringName in r.men:
		_rest[pid] = now + _r("rest_s", String(pid), "rest:%d:%d" % [int(now), folk.run_seed])


## Stop every exchange within `m` of `at` (a shot, your shout): [] none.
func stop_near(at: Vector3, m: float, why: String, now: float) -> void:
	for r: Dictionary in running.duplicate():
		for pid: StringName in r.men:
			var man: HumanBody = r.men[pid]
			if is_instance_valid(man) and man.global_position.distance_to(at) <= m:
				_end(r, why, now)
				break


## A man said something that isn't the exchange's (a bark at you, the barkeep's price, a fright):
## the exchange he was in stops.
func spoke(man: Node, now: float) -> void:
	for r: Dictionary in running.duplicate():
		if (r.men as Dictionary).values().has(man):
			_end(r, "spoke", now)


## The card table's hand is over (CardGame, `between`): an exchange of the men sat there, if one
## fits and the table hasn't talked within `table_gap_s`. Answers the seconds the deal should wait.
func table_break(now: float) -> float:
	if now - _table_at < float(d.table_gap_s) or running.size() >= int(d.max_at_once) or _story(now):
		return 0.0
	var f := fitting(now, true)
	if f.is_empty():
		return 0.0
	_table_at = now
	_begin(f[0][4], f[0][5], now, 0.6)
	var s := 0.6
	for l: Dictionary in TownScript.exchanges()[f[0][4]].lines:
		s += FaceSpeech.subtitle_seconds(TownScript.pick([String(l.id)], 0)) + 0.7
	return minf(s, float(d.table_hold_s))


func table_talking() -> bool:
	for r: Dictionary in running:
		if String(r.ex.place) == "saloon.table" and _at_cards(r.ex):
			return true
	return false


# --- Heard ----------------------------------------------------------------------------------------

## A line between two men, not at you (the one-line `chat` too): out on the physics frame, by `flush`.
func murmur(man: HumanBody, text: String, to: HumanBody = null, info: Dictionary = {}) -> void:
	var i := info.duplicate()
	i["to"] = to
	_out.append([man, text, i])


## On the physics frame (the wall's ray is Sight's): each line due goes out with how clearly you hear it.
func flush(now: float) -> void:
	if _out.is_empty():
		if not _over.is_empty():
			_settle(now)
		return
	var list := _out
	_out = []
	var p := _player()
	for x: Array in list:
		var man: HumanBody = x[0]
		if not is_instance_valid(man) or not man.is_inside_tree():
			continue
		var info: Dictionary = x[2]
		var r: Variant = info.get("r")
		info.erase("r")
		var c := clarity_at(p, man) if p != null else 0.0
		info["clarity"] = c
		if r is Dictionary:
			r.best = maxf(float(r.best), c)
			log.append([String(info.get("exchange", "")), String(info.get("line", "")), String(man.person_id), String(x[1]), c, now])
		Events.overheard.emit(man, String(x[1]), info)
	_settle(now)


## Exchanges ended, their last line out: heard tonight if it ran out or most of it had, and you
## caught any of it (`heard_at`). Else it's left for later tonight (`unheard_again_s`).
func _settle(now: float) -> void:
	for r: Dictionary in _over:
		var id := String(r.ex.id)
		var n := (r.ex.lines as Array).size()
		if int(r.said) > 0 and float(r.best) >= float(d.heard_at) and (String(r.why) == "done" or int(r.said) * 2 >= n):
			heard_day[id] = folk.town_day()
		else:
			_left[id] = now
	_over.clear()


var _over: Array = []


## How clearly `listener` hears `man` talking: 1 within `clear_m`, 0 at `hear_m`, times `wall` with
## something solid between their heads. On a physics frame only (Sight).
func clarity_at(listener: Node3D, man: Node3D) -> float:
	var ear := listener.global_position + Vector3.UP * 1.6
	if listener is Player and (listener as Player).camera != null:
		ear = (listener as Player).camera.global_position
	var mouth := man.global_position + Vector3.UP * 1.6
	var c := clarity_of(ear.distance_to(mouth), float(d.clear_m), float(d.hear_m))
	if c > 0.0 and not Sight.clear(listener, ear, mouth):
		c *= float(d.wall)
	return c


static func clarity_of(dist: float, clear_m: float, hear_m: float) -> float:
	return clampf((hear_m - dist) / maxf(hear_m - clear_m, 0.01), 0.0, 1.0)


## The line as you catch it at `clarity`: whole from `full_at`, words dropping out below it (the
## same words each time for one line: `seed`), runs of lost words one "…".
static func garbled(text: String, clarity: float, full_at: float, seed: int) -> String:
	if clarity >= full_at:
		return text
	var keep := clampf(clarity / maxf(full_at, 0.01), 0.0, 1.0)
	var out := PackedStringArray()
	var gap := false
	var words := text.split(" ", false)
	for i in words.size():
		if float(absi(hash("%d:%d" % [seed, i])) % 1000) / 1000.0 < keep:
			out.append(words[i])
			gap = false
		elif not gap:
			out.append("…")
			gap = true
	return " ".join(out)


func save_dict() -> Dictionary:
	return {"heard_day": heard_day.duplicate()}


func load_dict(s: Dictionary) -> void:
	heard_day = (s.get("heard_day", {}) as Dictionary).duplicate()
	for k: String in heard_day:
		heard_day[k] = int(heard_day[k])
