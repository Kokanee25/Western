class_name TownBook
extends RefCounted
## The book (townsfolk step 2, #870; docs/briefs/townsfolk.md §3 "Three ways of being present"): the
## townsfolk who aren't bodies in the world. A man indoors behind a front, asleep, at supper or out of
## town is a row here (where, doing what), and costs nothing: no body in the tree, no tick. ValleyFolk
## writes the rows as its people go in at a door and takes them out as they come out of one.
##
## The street shows the book: a building with someone in it at a `lamp` doing (home, at work, at
## supper) has a lit window after dark, one with someone at a `smoke` doing (breakfast, dinner,
## supper) chimney smoke (BookLights draws them). Data: config/valley_folk.json's `book`.

## id -> {"in": StringName (the place: a building's lot id, or a way out of town), "do": StringName}.
var rows := {}
## What each doing shows: do -> {"lamp": bool, "smoke": bool}.
var doings := {}
## The clock's hours a lamp shows in ([from, to), past midnight when to < from).
var dark: Array = [18.0, 6.0]


static func from_data(d: Dictionary) -> TownBook:
	var b := TownBook.new()
	b.doings = d.get("doings", {})
	b.dark = d.get("dark", [18.0, 6.0])
	return b


## He's in at `place`, doing `doing`.
func put(id: StringName, place: StringName, doing: StringName) -> void:
	rows[id] = {"in": place, "do": doing}


## Out of the book (he's come out, or he's dead).
func take(id: StringName) -> void:
	rows.erase(id)


func has(id: StringName) -> bool:
	return rows.has(id)


## His row ({} if he's not on the book).
func row(id: StringName) -> Dictionary:
	return rows.get(id, {})


## Who's in at `place`.
func inside(place: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in rows:
		if StringName(rows[id].in) == place:
			out.append(id)
	return out


func _shows(place: StringName, what: String) -> bool:
	for id: StringName in rows:
		var r: Dictionary = rows[id]
		if StringName(r.in) == place and bool((doings.get(String(r.do), {}) as Dictionary).get(what, false)):
			return true
	return false


## A lamp lit in its window: someone in at a lamp's doing, and dark.
func lit(place: StringName, hour: float) -> bool:
	return ValleyFolk.in_hours(hour, dark) and _shows(place, "lamp")


## Smoke from its chimney: someone in at a fire's doing (cooking).
func smoke(place: StringName) -> bool:
	return _shows(place, "smoke")


## Every place anyone's in.
func places() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in rows:
		var p := StringName(rows[id].in)
		if not out.has(p):
			out.append(p)
	return out


func report() -> Dictionary:
	var out := {}
	for id: StringName in rows:
		out[String(id)] = "%s: %s" % [rows[id].in, rows[id].do]
	return out
