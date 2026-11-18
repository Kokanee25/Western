class_name PlayerKnock
extends Node
## Banging on a door (#1057, No Law: Harlan bangs on the doctor's door with Earl at his feet). E at a
## building's door (its door point within PlayerTuning.knock_reach, in front of you) bangs on it: three
## blows of a fist on the boards (the sound where the door is, heard as any sound is: GameAudio),
## a deed (`Events.deed`, kind &"knock") and the door's owner told (`knock(place, by, at)`), who
## tells whoever's inside: ValleyFolk's `knocked` signal carries who's in that place on the book, so
## an act (or later, the folk's own brains) answers it. Works with a man by the collar (one hand's
## enough to bang with): PlayerCarry leaves E to this at a door.
## The doors: any node in the group `knock_doors` with `door_near(at, fwd, reach) -> {place, at}`
## and `knock(place, by, at) -> Array` (who heard it). In the group `claims_use` at a door.

signal knocked(place: StringName, heard: Array)

var player: Player
## Banged on: {place, at, heard (ids), t (msec)} of the last one; how many all told.
var last := {}
var count := 0
var _cool := 0.0
var _told_for := &""
## No oftener than this (s): one bang is three blows.
const GAP := 0.9
const LOOK_EVERY := 0.25
var _look_t := 0.0


func _ready() -> void:
	add_to_group(&"claims_use")


## The door you're at (its owner's {place, at, by}), or {}.
func door_here() -> Dictionary:
	if player == null or not player.is_inside_tree() or player.is_crawling or player.ladder != null:
		return {}
	if player.seat != null and player.seat.seated():
		return {}
	var fwd := player.get_forward()
	fwd.y = 0.0
	for n: Node in player.get_tree().get_nodes_in_group(&"knock_doors"):
		var d: Dictionary = n.call(&"door_near", player.global_position, fwd.normalized(), player.tuning.knock_reach)
		if not d.is_empty():
			d["by"] = n
			return d
	return {}


func claims_use(p: Player) -> bool:
	return p == player and not door_here().is_empty()


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_cool = maxf(_cool - delta, 0.0)
	var pressed := player.input_enabled and Input.is_action_just_pressed(&"shove")
	# Looked for a few times a second (and on E), not every tick: the doors are a search.
	_look_t -= delta
	if _look_t > 0.0 and not pressed:
		return
	_look_t = LOOK_EVERY
	var d := door_here()
	var place: StringName = d.get("place", &"")
	if place != _told_for:
		_told_for = place
		if place != &"" and player.wounds:
			player.wounds.say("E: bang on the door", 1.5)
	if not d.is_empty() and pressed:
		bang(d)


## Bang on the door `d` (door_here's): the blows, the deed, the inside told. Who heard it.
func bang(d := {}) -> Array:
	if d.is_empty():
		d = door_here()
	if d.is_empty() or _cool > 0.0:
		return []
	_cool = GAP
	var at: Vector3 = d.at + Vector3.UP * 1.3
	if GameAudio.enabled():
		for i in 3:
			GameAudio.play(player, &"thump", at, {"after": 0.22 * i, "volume_db": 2.0, "pitch": 0.8 + 0.05 * i})
	Events.deed.emit(player, &"knock", null, at)
	var heard: Array = (d.by as Node).call(&"knock", d.place, player, at) if d.has("by") else []
	count += 1
	last = {"place": String(d.place), "at": d.at, "heard": heard, "t": Time.get_ticks_msec()}
	knocked.emit(d.place, heard)
	return heard


func report() -> Dictionary:
	var d := door_here()
	return {"at_door": String(d.get("place", "")), "count": count,
			"last": String(last.get("place", "")), "heard": (last.get("heard", []) as Array).map(func(i: Variant) -> String: return String(i))}
