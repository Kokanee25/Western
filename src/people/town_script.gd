class_name TownScript
extends RefCounted
## The town's lines from its script (townsfolk step 8, #1144): `config/town_script.json`, the game's
## copy of `docs/scripts/town.json` (docs/ is hidden from Godot; tests/test_town_script.gd holds the
## two the same, so the script leads and the game follows, as docs/scripts/README.md says).
##
## A line is an id with a few wordings; a wording may hold slots in braces ({who}, {whom}, {where},
## {shots}, {teller}). `pick` takes ids most specific first and uses the first that has words, the
## wording by the speaker's seed (so three men with the same news say it three ways: the 2026-11-21
## playtest). A sentence that starts with a slot gets its capital. With no script (or no such line)
## the caller's own built string is the fallback.

const PATH := "res://config/town_script.json"

static var _lines: Dictionary = {}
## #1316: each line's tag ([tag, strength]) and, where a wording marks its beat (`*`), the wordings as
## written (the mark in); `_lines` holds them clean, as said.
static var _tags: Dictionary = {}
static var _marked: Dictionary = {}
static var _meta: Dictionary = {}
static var _exchanges: Dictionary = {}
static var _loaded := false


## Every line id -> its wordings (texts), read once.
static func lines() -> Dictionary:
	if not _loaded:
		_loaded = true
		_lines = {}
		_meta = {}
		_exchanges = {}
		_tags = {}
		_marked = {}
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				for s: Dictionary in (d as Dictionary).get("scenes", []):
					for l: Dictionary in s.get("lines", []):
						var ws: Array[String] = []
						var marked := []
						for w: Dictionary in l.get("words", []):
							var tx := String(w.get("text", ""))
							marked.append(tx)
							ws.append(tx.replace("*", ""))
						_lines[String(l.id)] = ws
						if l.has("tag") or ws != Array(marked):
							_tags[String(l.id)] = [Delivery.tag_named(String(l.get("tag", "calm"))), float(l.get("strength", 1.0))]
						if ws != Array(marked):
							_marked[String(l.id)] = marked
						# Step 9's barks (TownBarks): who says it and its `if` (the `when` as data).
						_meta[String(l.id)] = {"speaker": String(l.get("speaker", "")), "if": l.get("if", {}),
								"scene": String(s.get("id", ""))}
						# #1293's overheard talk (Overheard): a line with `ex` is one turn of an exchange, in
						# the file's order; `who` says it to `to`, at `place`, its `delivery` for the gestures.
						if l.has("ex"):
							var ex := String(l.ex)
							if not _exchanges.has(ex):
								_exchanges[ex] = {"id": ex, "place": String(l.get("place", "")), "if": l.get("if", {}),
										"story": bool(l.get("story", false)), "lines": [], "cast": []}
							var who := String(l.get("who", ""))
							(_exchanges[ex].lines as Array).append({"id": String(l.id), "who": who, "to": String(l.get("to", "")),
									"delivery": String(l.get("delivery", ""))})
							# Its cast: everyone who speaks in it or is spoken to (a third man may only listen).
							for c: String in [who, String(l.get("to", ""))]:
								if c != "" and not (_exchanges[ex].cast as Array).has(c):
									(_exchanges[ex].cast as Array).append(c)
	return _lines


## Every line id -> {speaker, if, scene} (the `if` empty where the script gives none).
static func meta() -> Dictionary:
	lines()
	return _meta


## #1293's exchanges: id -> {id, place (a people.json place tag), if (its first line's: `on` "heard"),
## story (waits on Sean's OK), cast [person ids], lines [{id, who, to, delivery}] in order}.
static func exchanges() -> Dictionary:
	lines()
	return _exchanges


## The wordings of `id` (empty if the script hasn't it).
static func words(id: String) -> Array:
	return lines().get(id, [])


## The first of `ids` that has words, one wording by `seed`, its slots filled from `slots`; "" if none.
## A tagged line is remembered as said (Delivery.remember: its tag and beat, for LineGesture).
static func pick(ids: Array, seed: int, slots: Dictionary = {}) -> String:
	for id: String in ids:
		var ws := words(id)
		if ws.is_empty():
			continue
		var i := posmod(seed, ws.size())
		if not _tags.has(id):
			return fill(String(ws[i]), slots)
		var t: Array = _tags[id]
		var m: Array = _marked.get(id, ws)
		return Delivery.remember(fill(String(m[i]), slots), t[0], float(t[1]))
	return ""


## A line's tag and strength ([tag, strength]; calm if it has none).
static func tag_of(id: String) -> Array:
	lines()
	return _tags.get(id, [&"calm", 1.0])


## A wording's slots filled, each sentence's first letter a capital.
static func fill(text: String, slots: Dictionary) -> String:
	for k: String in slots:
		text = text.replace("{%s}" % k, String(slots[k]))
	return capitalise(text)


static func capitalise(text: String) -> String:
	var out := ""
	var up := true
	for i in text.length():
		var c := text[i]
		if up and c != " " and c != "*":
			out += c.to_upper()
			up = false
		else:
			out += c
		if c in [".", "!", "?"]:
			up = true
	return out


## A seed for one speaker and one thing he says (his id, the record, the line), the same each time.
static func seed_of(who: String, what: String) -> int:
	return absi(hash(who + ":" + what))
