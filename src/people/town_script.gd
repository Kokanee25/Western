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
static var _meta: Dictionary = {}
static var _loaded := false


## Every line id -> its wordings (texts), read once.
static func lines() -> Dictionary:
	if not _loaded:
		_loaded = true
		_lines = {}
		_meta = {}
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				for s: Dictionary in (d as Dictionary).get("scenes", []):
					for l: Dictionary in s.get("lines", []):
						var ws: Array[String] = []
						for w: Dictionary in l.get("words", []):
							ws.append(String(w.get("text", "")))
						_lines[String(l.id)] = ws
						# Step 9's barks (TownBarks): who says it and its `if` (the `when` as data).
						_meta[String(l.id)] = {"speaker": String(l.get("speaker", "")), "if": l.get("if", {}),
								"scene": String(s.get("id", ""))}
	return _lines


## Every line id -> {speaker, if, scene} (the `if` empty where the script gives none).
static func meta() -> Dictionary:
	lines()
	return _meta


## The wordings of `id` (empty if the script hasn't it).
static func words(id: String) -> Array:
	return lines().get(id, [])


## The first of `ids` that has words, one wording by `seed`, its slots filled from `slots`; "" if none.
static func pick(ids: Array, seed: int, slots: Dictionary = {}) -> String:
	for id: String in ids:
		var ws := words(id)
		if ws.is_empty():
			continue
		return fill(String(ws[posmod(seed, ws.size())]), slots)
	return ""


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
		if up and c != " ":
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
