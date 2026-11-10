class_name Winchester73State
extends RefCounted
## The mechanism of a Winchester Model 1873, as rules: no animation, no graphics, testable.
##
## A tube magazine under the barrel (15) feeds a carrier; the lever works the action in one stroke:
## thrown open, the toggle links take the bolt back, the extractor pulls whatever's in the chamber
## and it's thrown out of the top, the bolt's back cocks the hammer, the dust cover rides back with
## it, and the carrier lifts the tube's first round to the bore; brought home, the bolt pushes the
## round into the chamber and the carrier drops for the next. The trigger only drops a hammer at
## full cock, and only with the lever home (the 1873's lever safety). Half cock is the safety
## notch: the trigger can't move the hammer off it. Thumbed back from half (or down) the hammer
## goes to full without the lever. Loading is a round at a time through the gate in the right side
## plate, into the tube, any time the lever's home: top it up between shots.
##
## Its cartridges are .44-40, the same as the revolver's: `shared` (the revolver's state, with its
## `belt`) is the one box both draw from; with none, it keeps its own `pouch`.

enum Round { EMPTY, LOADED, SPENT, DUD }
enum Hammer { DOWN, HALF_COCK, FULL_COCK }
enum Shot { NONE, FIRED, CLICK, MISFIRE, SAFE }

signal lever_opened
signal lever_closed
signal ejected(round_state: int)
signal chambered
signal hammer_changed(hammer: int)
signal fired
signal clicked
signal misfired
signal gate_loaded
signal cover_changed(open: bool)

var tuning: Winchester73Tuning
## Live rounds in the tube.
var tube := 0
var chamber := Round.EMPTY
## The round on the carrier (lifted out of the tube while the lever's open).
var carrier := Round.EMPTY
var hammer := Hammer.DOWN
var lever_open := false
## The dust cover over the port: the bolt carries it back when the lever's worked; shut by hand.
var cover_open := false
## Turned so the gate is to you, a round at a time going in (the first costs the turn).
var loading := false
## Seconds until the hands are free for the next action.
var busy := 0.0
## The lever's stroke in hand: thrown open, it comes home by itself once `busy` runs out.
var _closing_due := false
## Its own cartridges when nothing's shared.
var pouch := 0
var shared: Object

var _rng := RandomNumberGenerator.new()


func _init(t: Winchester73Tuning = null, seed := 1873) -> void:
	tuning = t if t else Winchester73Tuning.new()
	_rng.seed = seed
	tube = mini(tuning.start_tube, tuning.magazine)


func tick(delta: float) -> void:
	busy = maxf(0.0, busy - delta)
	if _closing_due and busy <= 0.0:
		_closing_due = false
		close_lever()


func ready() -> bool:
	return busy <= 0.0 and not _closing_due


## Cartridges in the belt (or the gun's own pouch).
func cartridges() -> int:
	return int(shared.get(&"belt")) if shared else pouch


func _take_cartridge() -> bool:
	if cartridges() <= 0:
		return false
	if shared:
		shared.set(&"belt", int(shared.get(&"belt")) - 1)
	else:
		pouch -= 1
	return true


## Live rounds in the gun (the tube, the carrier and the chamber).
func rounds_loaded() -> int:
	return tube + int(chamber == Round.LOADED) + int(carrier == Round.LOADED)


## Ready to go off at a pull: full cock, a live round chambered, the lever home.
func ready_to_fire() -> bool:
	return hammer == Hammer.FULL_COCK and chamber == Round.LOADED and not lever_open


## Throw the lever open: out with what's in the chamber, the hammer cocked, the cover back, the
## carrier up with the tube's next round.
func open_lever() -> bool:
	if not ready() or lever_open:
		return false
	loading = false
	lever_open = true
	if chamber != Round.EMPTY:
		var was := chamber
		chamber = Round.EMPTY
		ejected.emit(was)
	if hammer != Hammer.FULL_COCK:
		hammer = Hammer.FULL_COCK
		hammer_changed.emit(hammer)
	if not cover_open:
		cover_open = true
		cover_changed.emit(true)
	if tube > 0 and carrier == Round.EMPTY:
		tube -= 1
		carrier = Round.LOADED
	busy = tuning.lever_open_time
	lever_opened.emit()
	return true


## Bring the lever home: the carrier's round into the chamber.
func close_lever() -> bool:
	if busy > 0.0 or not lever_open:
		return false
	lever_open = false
	_closing_due = false
	if carrier != Round.EMPTY:
		chamber = carrier
		carrier = Round.EMPTY
		chambered.emit()
	busy = tuning.lever_close_time
	lever_closed.emit()
	return true


## The whole stroke: open, and home again once it's open.
func work_lever() -> bool:
	if not open_lever():
		return false
	_closing_due = true
	return true


## Thumb the hammer back to full cock (from half, or down), no lever.
func thumb_cock() -> bool:
	if not ready() or lever_open or hammer == Hammer.FULL_COCK:
		return false
	loading = false
	hammer = Hammer.FULL_COCK
	busy = tuning.thumb_cock_time
	hammer_changed.emit(hammer)
	return true


## Ease the hammer down onto the half-cock notch (from full; from down it's thumbed up to it).
func half_cock() -> bool:
	if not ready() or lever_open or hammer == Hammer.HALF_COCK:
		return false
	busy = tuning.half_cock_time if hammer == Hammer.FULL_COCK else tuning.thumb_cock_time
	hammer = Hammer.HALF_COCK
	hammer_changed.emit(hammer)
	return true


## Squeeze the trigger. Only a hammer at full cock with the lever home falls; at half cock the
## notch holds it (SAFE).
func pull_trigger() -> Shot:
	if not ready() or lever_open:
		return Shot.NONE
	if hammer == Hammer.HALF_COCK:
		return Shot.SAFE
	if hammer != Hammer.FULL_COCK:
		return Shot.NONE
	loading = false
	hammer = Hammer.DOWN
	hammer_changed.emit(hammer)
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


## One round through the gate into the tube (the lever must be home: the carrier's down then).
func load_round() -> bool:
	if not ready() or lever_open or tube >= tuning.magazine or not _take_cartridge():
		return false
	busy = tuning.gate_round_time + (0.0 if loading else tuning.turn_to_load_time)
	loading = true
	tube += 1
	gate_loaded.emit()
	return true


## Done loading: the gun back round to the front.
func stop_loading() -> void:
	loading = false


func can_load() -> bool:
	return not lever_open and tube < tuning.magazine and cartridges() > 0


func set_cover(open: bool) -> void:
	if cover_open == open or lever_open:
		return
	cover_open = open
	cover_changed.emit(open)


func to_dict() -> Dictionary:
	return {"tube": tube, "chamber": chamber, "carrier": carrier, "hammer": hammer, "lever_open": lever_open,
			"cover_open": cover_open, "pouch": pouch}


func from_dict(d: Dictionary) -> void:
	tube = d.get("tube", tube)
	chamber = d.get("chamber", chamber)
	carrier = d.get("carrier", carrier)
	hammer = d.get("hammer", hammer)
	lever_open = d.get("lever_open", lever_open)
	cover_open = d.get("cover_open", cover_open)
	pouch = d.get("pouch", pouch)
