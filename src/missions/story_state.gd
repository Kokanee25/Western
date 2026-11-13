class_name StoryState
extends RefCounted
## The story so far: the facts one mission sets and later ones read (docs/missions/DECISIONS.md's
## keys, e.g. `sheriff.care` = good / poor / left him). The first cut (issue #746, the sheriff on
## the road): kept in memory for the run, read and cleared over the dev bridge (`story`). Saving it
## to disk, when you sleep in a bed with the rest of the save, is later (BUILD_ORDER.md's 0.2).
##
## Three ways a game starts (GameReset; review A5, #864): a fresh start (Backspace, a look's reload,
## the bridge's world) has no story at all (`wipe`); a mission's retry has the story as it stood when
## that mission began (`checkpoint`, put back by `restore`); a save's load, after the slice, will
## put back the story it saved the same way (`restore(save.story)`), never `wipe`.

static var facts := {}
## When each fact was set (the clock's day and hour, [day, hour]), for the record.
static var when := {}
## The story as it stood when the running mission began (`mark_checkpoint`): what its retry starts
## from. Empty: no mission begun since the fresh start.
static var checkpoint := {}


static func set_fact(key: String, value: Variant, day := 1, hour := -1.0) -> void:
	facts[key] = value
	when[key] = [day, snappedf(hour, 0.01)]


static func get_fact(key: String, default: Variant = null) -> Variant:
	return facts.get(key, default)


static func has_fact(key: String) -> bool:
	return facts.has(key)


static func clear(prefix := "") -> void:
	if prefix == "":
		facts.clear()
		when.clear()
		return
	for k: String in facts.keys():
		if k.begins_with(prefix):
			facts.erase(k)
			when.erase(k)


static func to_dict() -> Dictionary:
	return {"facts": facts.duplicate(true), "when": when.duplicate(true)}


## A fresh game: no facts, no checkpoint.
static func wipe() -> void:
	facts.clear()
	when.clear()
	checkpoint = {}


## The story put back as `d` had it (`to_dict`'s shape; {}: none), the checkpoint kept.
static func restore(d: Dictionary) -> void:
	facts = (d.get("facts", {}) as Dictionary).duplicate(true)
	when = (d.get("when", {}) as Dictionary).duplicate(true)


## A mission begins: its retry will start from the story as it is now.
static func mark_checkpoint() -> void:
	checkpoint = to_dict()
