class_name PlayerPurse
extends Node
## The money in Harlan's pocket (#1292): dollars and cents at 1882's prices (config/drink.json: what he
## has at a new game, what a chip at the card table is worth). The barkeep takes his coin from it
## (BarService); the card table's stake is bought with it and cashed back to it (CardGame). Saved with
## the game (SaveGame's player section: `cents`). Shown when it matters: paying, buying in, cashing out
## (`say_paid`, through PlayerWounds' word at the bottom of the screen).

const DATA := "res://config/drink.json"

var player: Player
## What he has (cents).
var cents := 0
## Every change: [cents (+ in, - out), why]; the last few, for the bridge and the tests.
var log: Array = []

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(DATA):
		_data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	return _data


func _init() -> void:
	cents = int(data().get("purse", 0))


## As money is written: "$3.40", "15 cents".
static func money(c: int) -> String:
	if absi(c) < 100:
		return "%d cent%s" % [c, "" if absi(c) == 1 else "s"]
	return "$%d.%02d" % [floori(c / 100.0), absi(c) % 100]


## Can he pay `c`?
func has(c: int) -> bool:
	return cents >= c


## Pay `c` out (for `why`): false (nothing paid) if he hasn't got it.
func pay(c: int, why: StringName) -> bool:
	if c < 0 or cents < c:
		return false
	cents -= c
	_note(-c, why)
	return true


## `c` into his pocket (winnings cashed, change).
func take(c: int, why: StringName) -> void:
	if c <= 0:
		return
	cents += c
	_note(c, why)


func _note(c: int, why: StringName) -> void:
	log.append([c, String(why)])
	if log.size() > 40:
		log.pop_front()


## Tell him what it cost and what's left (at the bottom of the screen).
func say_paid(c: int, what: String) -> void:
	if player != null and player.wounds != null:
		player.wounds.say("%s: %s (%s left)" % [what, money(c), money(cents)], 2.5)


func save_dict() -> Dictionary:
	return {"cents": cents}


func load_dict(d: Dictionary) -> void:
	cents = int(d.get("cents", cents))
