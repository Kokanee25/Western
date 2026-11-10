class_name StoryState
extends RefCounted
## The story so far: the facts one mission sets and later ones read (docs/missions/DECISIONS.md's
## keys, e.g. `sheriff.care` = good / poor / left him). The first cut (issue #746, the sheriff on
## the road): kept in memory for the run, read and cleared over the dev bridge (`story`). Saving it
## to disk, when you sleep in a bed with the rest of the save, is later (BUILD_ORDER.md's 0.2).

static var facts := {}
## When each fact was set (the clock's day and hour, [day, hour]), for the record.
static var when := {}


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
