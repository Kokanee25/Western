class_name BridgeLab
extends Node
## A lab's own dev bridge commands (docs/briefs/labs.md). Each lab under experiments/ that wants
## commands puts a `bridge.gd` in its folder extending this; the bridge finds it when it starts, adds
## it as a child and sends it the commands it names. The lab's commands stay in the lab's folder, so
## the labs never edit src/debug/dev_bridge.gd or each other.
##
##   extends BridgeLab
##   const HELP := {"duel": "duel [N] -> N fights at the trough, their numbers"}
##   func _cmd_duel(a: Array) -> Dictionary:
##       await seconds(2.0)
##       return {"fights": 1}
##
## A command answers a Dictionary (with "ok": false and "error" when it can't); it may await game
## time. A name the bridge or another lab already has is refused at start (the log says so).

var bridge: DevBridge


## The commands this lab adds: name -> one line of help, as the bridge's own HELP.
func commands() -> Dictionary:
	var help: Variant = (get_script() as Script).get_script_constant_map().get("HELP")
	return help if help is Dictionary else {}


# What a command usually needs, from the bridge.
var main: Node:
	get: return bridge.main
var street: Node:
	get: return bridge.street
var player: Player:
	get: return bridge.player


## Let game time pass (as `wait`).
func seconds(s: float) -> void:
	await bridge._seconds(s)


func physics_frames(n: int) -> void:
	await bridge._physics_frames(n)


## A person by their id (brody, outlaw3...), as `look PERSON` finds them (null if there's none).
func person(id: String) -> HumanBody:
	return bridge._person(id)


## A line in the bridge's event log (`events`).
func log_event(kind: String, text: String) -> void:
	bridge._log(kind, text)


## Words from a command line: X Y Z from index i, and a vector back as JSON.
func vec(a: Array, i: int) -> Vector3:
	return bridge._vec(a, i)


func arr(v: Vector3) -> Array:
	return bridge._arr(v)
