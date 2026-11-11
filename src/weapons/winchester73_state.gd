class_name Winchester73State
extends RefCounted
## The mechanism of the Winchester 1873, as rules: no animation, no graphics, testable.
##
## A tube of `tube_capacity` rounds under the barrel feeds one chamber. Throwing the lever open takes
## the bolt back (its extractor pulls whatever is in the chamber, fired or not, and the ejector flips
## it out of the port), the bolt's travel cocks the hammer and pushes the dust cover back, and at the
## end of the stroke the carrier lifts the next round from the tube up to the bore's line. Closing it
## the bolt drives that round into the chamber and the carrier drops for the next. The trigger only
## drops a hammer at full cock and only with the lever shut. Half cock is the safety: the trigger does
## nothing there; thumb it back to full to fire, or work the lever. Rounds go in one at a time through
## the spring gate on the right of the receiver, nose first, into the tube, any time the lever's shut
## (topping up between shots). The rounds are .44-40, the Colt's: they come off the same belt.

enum Round { EMPTY, LOADED, SPENT, DUD }
enum Hammer { DOWN, HALF_COCK, FULL_COCK }
enum Shot { NONE, FIRED, CLICK, MISFIRE }

signal lever_moved(open: bool)
## What the extractor pulled out of the chamber (a Round): it flies out of the port.
signal ejected(round_state: int)
## The carrier lifted a round from the tube (the lever's end).
signal lifted
## The bolt drove the carrier's round home (the lever closing).
signal chambered
signal hammer_moved(hammer_state: int)
signal fired
signal clicked
signal misfired
## A round thumbed in through the gate.
signal gate_loaded
signal cover_moved(open: bool)

var tuning: Winchester73Tuning
var tube := 0
var chamber := Round.EMPTY
## The carrier's round (LOADED) or none (EMPTY).
var carrier := Round.EMPTY
var hammer := Hammer.DOWN
var lever_open := false
var cover_open := false
## Seconds until the hands are free for the next action.
var busy := 0.0
## The ammunition this gun shares (any object with an int `belt`: the Colt's RevolverState, the
## one .44-40 belt). Unset, the gun keeps its own count in `own_belt`.
var shares: Object = null
var own_belt := 0

var _rng := RandomNumberGenerator.new()


func _init(t: Winchester73Tuning = null, seed := 1873) -> void:
	tuning = t if t else Winchester73Tuning.new()
	_rng.seed = seed
	tube = clampi(tuning.start_tube, 0, tuning.tube_capacity)
	if tuning.start_chambered:
		chamber = Round.LOADED


func tick(delta: float) -> void:
	busy = maxf(0.0, busy - delta)


func ready() -> bool:
	return busy <= 0.0


## Cartridges on the belt (shared with the Colt).
func belt() -> int:
	return int(shares.get(&"belt")) if shares else own_belt


func _take_from_belt() -> bool:
	if belt() <= 0:
		return false
	if shares:
		shares.set(&"belt", belt() - 1)
	else:
		own_belt -= 1
	return true


## Rounds ready to fire without loading: the tube's and the chamber's.
func rounds_ready() -> int:
	return tube + (1 if chamber == Round.LOADED else 0) + (1 if carrier == Round.LOADED else 0)


## Throw the lever open: out with what's in the chamber, the hammer cocked, the cover back, the
## next round lifted from the tube.
func open_lever() -> bool:
	if not ready() or lever_open:
		return false
	lever_open = true
	busy = tuning.lever_open_time
	lever_moved.emit(true)
	if not cover_open:
		cover_open = true
		cover_moved.emit(true)
	if chamber != Round.EMPTY:
		var out := chamber
		chamber = Round.EMPTY
		ejected.emit(out)
	if hammer != Hammer.FULL_COCK:
		hammer = Hammer.FULL_COCK
		hammer_moved.emit(hammer)
	if carrier == Round.EMPTY and tube > 0:
		tube -= 1
		carrier = Round.LOADED
		lifted.emit()
	return true


## Close it: the bolt drives the lifted round into the chamber.
func close_lever() -> bool:
	if not ready() or not lever_open:
		return false
	lever_open = false
	busy = tuning.lever_close_time
	if carrier == Round.LOADED and chamber == Round.EMPTY:
		carrier = Round.EMPTY
		chamber = Round.LOADED
		chambered.emit()
	lever_moved.emit(false)
	return true


## Squeeze the trigger: only at full cock with the lever shut (half cock blocks it).
func pull_trigger() -> Shot:
	if not ready() or lever_open or hammer != Hammer.FULL_COCK:
		return Shot.NONE
	hammer = Hammer.DOWN
	hammer_moved.emit(hammer)
	busy = tuning.fire_recovery
	match chamber:
		Round.LOADED:
			if _rng.randf() < tuning.misfire_chance:
				chamber = Round.DUD
				misfired.emit()
				return Shot.MISFIRE
			chamber = Round.SPENT
			fired.emit()
			return Shot.FIRED
		_:
			clicked.emit()
			return Shot.CLICK


## The thumb on the hammer: at full cock it's eased down to half cock (the safety); at half cock or
## down it's drawn back to full. Not with the lever open (the bolt holds it back).
func hammer_press() -> bool:
	if not ready() or lever_open:
		return false
	if hammer == Hammer.FULL_COCK:
		hammer = Hammer.HALF_COCK
		busy = tuning.half_cock_time
	else:
		hammer = Hammer.FULL_COCK
		busy = tuning.hammer_time
	hammer_moved.emit(hammer)
	return true


## One round through the gate into the tube. Only with the lever shut (open, the carrier's up across
## the gate's way), the tube not full and a round on the belt.
func load_gate() -> bool:
	if not ready() or lever_open or tube >= tuning.tube_capacity:
		return false
	if not _take_from_belt():
		return false
	tube += 1
	busy = tuning.gate_load_time
	gate_loaded.emit()
	return true


## One press of the reload key: the lever shut first if it's open, then a round through the gate.
## False when there's nothing to do (tube full or the belt empty).
func reload_step() -> bool:
	if not ready():
		return true
	if lever_open:
		return close_lever()
	return load_gate()


## Slide the dust cover shut over the port (the hand does it when the gun's slung; the bolt pushes
## it back again on the next stroke).
func close_cover() -> bool:
	if not cover_open or lever_open:
		return false
	cover_open = false
	cover_moved.emit(false)
	return true


func to_dict() -> Dictionary:
	return {"tube": tube, "chamber": chamber, "carrier": carrier, "hammer": hammer, "lever_open": lever_open,
			"cover_open": cover_open, "own_belt": own_belt}


func from_dict(d: Dictionary) -> void:
	tube = d.get("tube", tube)
	chamber = d.get("chamber", chamber)
	carrier = d.get("carrier", carrier)
	hammer = d.get("hammer", hammer)
	lever_open = d.get("lever_open", lever_open)
	cover_open = d.get("cover_open", cover_open)
	own_belt = d.get("own_belt", own_belt)
