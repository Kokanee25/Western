class_name Delivery
extends RefCounted
## How a line is said (#1316, Sean 2026-11-27: "Can lines be arranged to go with animation, such as
## angry gestures, or looks like they're laughing during a line?"): a small fixed set of tags every
## line can carry, and the beat a gesture lands on. Data, not code: `config/delivery.json` holds what
## each tag does to the face and the body (LineGesture plays it) and how a script's free-text
## `delivery` note reads as a tag (`tools/delivery_tags.py` writes the tag onto the town script's
## lines from it; a line with no tag is calm).
##
## The beat: a wording may mark the word its gesture lands on with `*` before it ("You *never paid
## me."); TownScript keeps the mark out of the words said and shown, and `remember`s the line as said
## (its tag, its beat word) under its final text, which LineGesture asks for (`of`) when the man says
## it. Without a mark the gesture lands where the tag's data says (`beat`: the line's stress, its end,
## its start).

const PATH := "res://config/delivery.json"
const TAGS := [&"calm", &"angry", &"laughing", &"mocking", &"scared", &"sly", &"sad", &"low", &"proud", &"pleading"]
## Lines remembered as said (their final text -> {tag, strength, beat}); the oldest let go past this.
const KEEP := 256

static var _data: Dictionary = {}
static var _loaded := false
static var _said: Dictionary = {}
static var _words_re: RegEx


## config/delivery.json, read once.
static func data() -> Dictionary:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open(PATH, FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_data = d
	return _data


## A tag's entry (face, beat, gestures, listen); calm's for an unknown one.
static func entry(tag: StringName) -> Dictionary:
	var t: Dictionary = data().get("tags", {})
	return t.get(String(tag), t.get("calm", {}))


## One gesture's dials (keys, osc, hand, look, walk).
static func gesture(name: String) -> Dictionary:
	return (data().get("gestures", {}) as Dictionary).get(name, {})


## A script's free-text note (`delivery`: "Low, to his neighbour...", "grumbling", "Telling it as a
## joke.") as [tag, strength]: the data's `notes`, the first phrase found in it; calm if none.
static func tag_of_note(note: String) -> Array:
	var low := note.to_lower()
	if low.strip_edges() != "":
		for n: Array in data().get("notes", []):
			if _has_phrase(low, String(n[0])):
				return [StringName(n[1]), float(n[2]) if n.size() > 2 else 1.0]
	return [&"calm", 1.0]


## `phrase` in `low` at the start of a word ("low" is in "low, close" but not in "slow").
static func _has_phrase(low: String, phrase: String) -> bool:
	var at := low.find(phrase)
	while at >= 0:
		if at == 0 or not low.unicode_at(at - 1) in range(97, 123):
			return true
		at = low.find(phrase, at + 1)
	return false


## `text` with its beat mark taken out, and which word (0-based, words as FaceSpeech counts them:
## runs of letters and apostrophes) it was before; -1 if none. [clean text, word index].
static func strip_beat(text: String) -> Array:
	var at := text.find("*")
	if at < 0:
		return [text, -1]
	if _words_re == null:
		_words_re = RegEx.create_from_string("[A-Za-z']+")
	var before := text.substr(0, at)
	var n := _words_re.search_all(before).size()
	return [text.replace("*", ""), n]


## A line about to be said: remembered under its clean text (`of`) with its tag and beat. Returns the
## clean text (the mark out).
static func remember(marked: String, tag: StringName, strength := 1.0) -> String:
	var sb := strip_beat(marked)
	var clean: String = sb[0]
	if tag == &"calm" and int(sb[1]) < 0:
		return clean
	if _said.size() >= KEEP:
		_said.erase(_said.keys()[0])
	_said[clean] = {"tag": tag, "strength": strength, "beat": int(sb[1])}
	return clean


## How `text` is said, if a script line said it ({tag, strength, beat}); calm with no beat if not.
static func of(text: String) -> Dictionary:
	return _said.get(text, {"tag": &"calm", "strength": 1.0, "beat": -1})


## A tag given in data (a line's `tag`): one of TAGS, else calm.
static func tag_named(s: String) -> StringName:
	var t := StringName(s.strip_edges().to_lower())
	return t if TAGS.has(t) else &"calm"
