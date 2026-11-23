class_name TownBarks
extends RefCounted
## The town's barks (townsfolk step 9, #1152; docs/briefs/townsfolk.md §5 "What they say"): the line
## picker over the town's script (TownScript, `config/town_script.json`). A line is picked only if the
## script gives it an `if` (its `when` as data); `on` says which moment asks for it:
##   `pass` (Harlan within the folk's talk reach, ValleyFolk._talk_step), `chat` and `chat.reply` (two
##   men by each other, in your hearing, ValleyFolk._chat_step: one says, the other answers), `knock`
##   and `knock.wait` (a shopkeeper at his door, and again if you stand there), `react.<x>` (Reaction's
##   stages: shot_far, flee, ring, doc, gun, back), `undertaker` (at a body, ValleyFolk._dead_step),
##   `room.<x>` (the saloon's bits, SaloonRoom by ValleyFolk.room_line: toast, hail, leave, answer, glass).
## The rest of `if`, all of which must hold (each counts toward how specific the line is):
##   `regard` the speaker's own band (TownRegard) or a list; `view` his own view of Harlan
##   (TownNews.view_of_harlan, "*" any: he holds news of him); `fact` StoryState facts
##   (ValleyFolk.story_holds' shape, each key counts); `day` the day kind; `hour` [from, to) (to past
##   24 runs over midnight); `spot` what he's doing there (his block's `do`); `at` a tag of where he
##   is (`saloon`, `store`, his block's place or spot); `whom` his version has the man down's name
##   (true) or not (false); `who_you` his version has Harlan firing; `shaken`; `opinion` {name: at
##   least}; `once` "ever" (said once in the game, not once a day).
## The rules: the most specific line that fits wins (`specificity`, his own pool's one more; then a
## line of his own pool before a shared one); a person says a given line once a day; nobody says a line another said in
## the last `same_line_s`; the speaker must hold the news (view, whom, who_you are his own
## version's). One bark per group as Harlan passes is ValleyFolk's (`blocked`, `block`), by place.
## The wording by the speaker's seed (TownScript.pick).

## Defaults; ValleyFolk's data `barks` may set them.
var same_line_s := 60.0
var group_m := 4.0
var group_clear_m := 10.0
## A group you stand by speaks again after this long (s; #1184: one line, then a group you stood
## beside for minutes kept quiet till you'd walked 10 m off and back).
var group_again_s := 45.0

## pid -> {line id: the town day he last said it}; and those said once for good.
var said := {}
var said_ever := {}
## line id -> when anyone last said it (the folk's seconds).
var last_said := {}
## Where a group was barked at as Harlan passed: [Vector3], cleared once he's off; and when (the
## folk's seconds, -1 for good till he's off).
var blocks: Array[Vector3] = []
var block_t: Array[float] = []
## What was said: [pid, line id, text, on, when].
var log: Array = []


func _init(dials: Dictionary = {}) -> void:
	same_line_s = float(dials.get("same_line_s", same_line_s))
	group_m = float(dials.get("group_m", group_m))
	group_clear_m = float(dials.get("group_clear_m", group_clear_m))
	group_again_s = float(dials.get("group_again_s", group_again_s))


## The lines `on` asks for that fit `ctx`, most specific first: [line id].
## ctx: pid, pools (his first), band, view, hour, day_kind, at (tags), spot, whom, who_you, shaken,
## opinion. A key the caller leaves out fails any line that asks about it.
static func fitting(on: String, ctx: Dictionary) -> Array:
	var found: Array = []
	var pools: Array = ctx.get("pools", [])
	var meta := TownScript.meta()
	for id: String in meta:
		var m: Dictionary = meta[id]
		var c: Dictionary = m.get("if", {})
		if c.is_empty() or String(c.get("on", "")) != on:
			continue
		var pool_at := pools.find(String(m.speaker))
		if pool_at < 0:
			continue
		if not holds(c, ctx):
			continue
		# His own pool's lines (a man with a trade's: the smith's, not the town's) count one more
		# (#1184: the town's shared "Morning." and weather came from three men in ten minutes, over their own).
		var own := 1 if pool_at == 0 and pools.size() > 1 else 0
		found.append([-(specificity(c) + own), pool_at, id])
	found.sort()
	return found.map(func(x: Array) -> String: return String(x[2]))


## How specific a line's `if` is, not counting `on`: what he holds himself of the news counts
## most (`view` 4, `whom` and `who_you` 3 each), a story fact 2 each, anything else 1 (so a man's own
## news of Harlan comes before the badge's word, and that before the hour's greeting; `once` 1).
const WEIGHT := {"view": 4, "whom": 3, "who_you": 3}


static func specificity(c: Dictionary) -> int:
	var n := 0
	for k: String in c:
		if k == "on":
			continue
		if k == "once":
			n += 1  # a moment once for good (the badge first seen) before the day's ordinary line
		elif k == "fact":
			n += 2 * (c[k] as Dictionary).size()
		elif k == "opinion":
			n += (c[k] as Dictionary).size()
		else:
			n += int(WEIGHT.get(k, 1))
	return n


## Does `ctx` meet every condition of `c`?
static func holds(c: Dictionary, ctx: Dictionary) -> bool:
	for k: String in c:
		var want: Variant = c[k]
		match k:
			"on", "once":
				pass
			"regard":
				if not _is_in(String(ctx.get("band", "")), want):
					return false
			"view":
				var v := String(ctx.get("view", ""))
				if v == "" or (String(want) != "*" and v != String(want)):
					return false  # he must hold news of Harlan himself
			"fact":
				if not ValleyFolk.story_holds(want):
					return false
			"day":
				if not _is_in(String(ctx.get("day_kind", "")), want):
					return false
			"hour":
				if not ctx.has("hour") or not in_hours(float(ctx.hour), float(want[0]), float(want[1])):
					return false
			"spot":
				if not _is_in(String(ctx.get("spot", "")), want):
					return false
			"at":
				var tags: Array = ctx.get("at", [])
				var any := false
				for w: Variant in (want if want is Array else [want]):
					any = any or tags.has(String(w))
				if not any:
					return false
			"whom", "who_you", "shaken":
				if not ctx.has(k) or bool(ctx[k]) != bool(want):
					return false
			"opinion":
				var o: Dictionary = ctx.get("opinion", {})
				for n: String in want:
					if float(o.get(n, -INF)) < float(want[n]):
						return false
			_:
				return false  # a condition this picker doesn't know: never guess
	return true


static func _is_in(have: String, want: Variant) -> bool:
	if have == "":
		return false
	if want is Array:
		return (want as Array).has(have)
	return have == String(want)


## Is `h` in [from, to)? `to` past 24 runs over midnight (20 to 26: eight in the evening to two).
static func in_hours(h: float, from: float, to: float) -> bool:
	return (h >= from and h < to) or (to > 24.0 and h + 24.0 >= from and h + 24.0 < to)


## May `pid` say `id` now (`day` the town's day, `now` the folk's seconds)?
func allowed(pid: String, id: String, day: int, now: float) -> bool:
	if int((said.get(pid, {}) as Dictionary).get(id, -1)) == day:
		return false  # once a day a person
	if (said_ever.get(pid, {}) as Dictionary).has(id):
		return false
	if last_said.has(id) and now - float(last_said[id]) < same_line_s:
		return false  # another said it within the minute
	return true


## The line for `on` that fits `ctx` and the limits allow, said: [id, text] (the wording by his seed,
## `slots` filled), or [] if none. Counts it as said.
func pick(on: String, ctx: Dictionary, day: int, now: float, slots: Dictionary = {}) -> Array:
	var pid := String(ctx.get("pid", ""))
	for id: String in fitting(on, ctx):
		if not allowed(pid, id, day, now):
			continue
		var text := TownScript.pick([id], TownScript.seed_of(pid, id), slots)
		if text == "":
			continue
		mark(pid, id, day, now)
		log.append([pid, id, text, on, now])
		return [id, text]
	return []


## Count `id` as said by `pid` (a line said another way still keeps the limits).
func mark(pid: String, id: String, day: int, now: float) -> void:
	if not said.has(pid):
		said[pid] = {}
	said[pid][id] = day
	var c: Dictionary = (TownScript.meta().get(id, {}) as Dictionary).get("if", {})
	if String(c.get("once", "")) == "ever":
		if not said_ever.has(pid):
			said_ever[pid] = {}
		said_ever[pid][id] = true
	last_said[id] = now


## Has `pid` said `id` today (any line he's been counted for)?
func said_today(pid: String, id: String, day: int) -> bool:
	return int((said.get(pid, {}) as Dictionary).get(id, -1)) == day


## One bark at Harlan a group as he passes: a man within `group_m` of a group already barked at.
## `now` (the folk's seconds) given: a block older than `group_again_s` has lapsed.
func blocked(at: Vector3, now := -1.0) -> bool:
	for i in blocks.size():
		var b := blocks[i]
		if now >= 0.0 and block_t[i] >= 0.0 and now - block_t[i] > group_again_s:
			continue
		if Vector2(b.x - at.x, b.z - at.z).length() < group_m:
			return true
	return false


func block(at: Vector3, now := -1.0) -> void:
	blocks.append(at)
	block_t.append(now)


## Harlan's moved on: the groups he's left behind may greet him again next time.
func clear_far(harlan: Vector3) -> void:
	var keep: Array[Vector3] = []
	var keep_t: Array[float] = []
	for i in blocks.size():
		var b := blocks[i]
		if Vector2(b.x - harlan.x, b.z - harlan.z).length() < group_clear_m:
			keep.append(b)
			keep_t.append(block_t[i])
	blocks = keep
	block_t = keep_t


func to_dict() -> Dictionary:
	return {"said": said.duplicate(true), "said_ever": said_ever.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	said = (d.get("said", {}) as Dictionary).duplicate(true)
	said_ever = (d.get("said_ever", {}) as Dictionary).duplicate(true)
