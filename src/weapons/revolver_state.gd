class_name RevolverState
extends RefCounted
## The mechanism of a single-action revolver, as rules: no animation, no graphics, testable.
##
## Single action: the trigger only drops a hammer that is already at full cock. Cocking turns the
## cylinder one chamber. Loading is one chamber at a time through the gate: half-cock, open the
## gate, turn the cylinder, knock out each spent case with the ejector, press in a fresh round,
## close the gate. The chamber lined up with the barrel is `under_hammer`; with the gate open,
## that's also the chamber at the gate.

enum Chamber { EMPTY, LOADED, SPENT, DUD }
enum Hammer { DOWN, HALF_COCK, FULL_COCK }
enum Shot { NONE, FIRED, CLICK, MISFIRE }

signal cocked
signal fired
signal clicked
signal misfired
signal gate_changed(open: bool)
signal cylinder_turned
signal ejected(chamber_state: int)
signal inserted

var tuning: RevolverTuning
var chambers: Array[int] = []
var under_hammer := 0
var hammer := Hammer.DOWN
var gate_open := false
var belt := 0
## Seconds until the hand is free for the next action.
var busy := 0.0

var _rng := RandomNumberGenerator.new()


func _init(t: RevolverTuning = null, seed := 1882) -> void:
	tuning = t if t else RevolverTuning.new()
	_rng.seed = seed
	chambers.resize(tuning.cylinder_size)
	chambers.fill(Chamber.EMPTY)
	# Load all but the chamber under the hammer.
	for i in mini(tuning.start_loaded, tuning.cylinder_size):
		chambers[(i + 1) % tuning.cylinder_size] = Chamber.LOADED
	belt = mini(tuning.start_belt, tuning.belt_capacity)


func tick(delta: float) -> void:
	busy = maxf(0.0, busy - delta)


func ready() -> bool:
	return busy <= 0.0


func rounds_loaded() -> int:
	return chambers.count(Chamber.LOADED)


## Thumb the hammer back to full cock. Turns the cylinder to the next chamber.
func cock() -> bool:
	if not ready() or gate_open or hammer == Hammer.FULL_COCK:
		return false
	under_hammer = (under_hammer + 1) % chambers.size()
	hammer = Hammer.FULL_COCK
	busy = tuning.cock_time
	cocked.emit()
	cylinder_turned.emit()
	return true


## Squeeze the trigger. Only does anything at full cock.
func pull_trigger() -> Shot:
	if not ready() or gate_open or hammer != Hammer.FULL_COCK:
		return Shot.NONE
	hammer = Hammer.DOWN
	busy = tuning.fire_recovery
	match chambers[under_hammer]:
		Chamber.LOADED:
			if _rng.randf() < tuning.misfire_chance:
				chambers[under_hammer] = Chamber.DUD
				misfired.emit()
				return Shot.MISFIRE
			chambers[under_hammer] = Chamber.SPENT
			fired.emit()
			return Shot.FIRED
		_:
			clicked.emit()
			return Shot.CLICK


func open_gate() -> bool:
	if not ready() or gate_open:
		return false
	hammer = Hammer.HALF_COCK
	gate_open = true
	busy = tuning.gate_time
	gate_changed.emit(true)
	return true


func close_gate() -> bool:
	if not ready() or not gate_open:
		return false
	gate_open = false
	hammer = Hammer.DOWN
	busy = tuning.gate_time * 0.6
	gate_changed.emit(false)
	return true


## At half-cock the cylinder turns freely: bring the next chamber to the gate.
func turn_cylinder() -> bool:
	if not ready() or not gate_open:
		return false
	under_hammer = (under_hammer + 1) % chambers.size()
	busy = tuning.turn_time
	cylinder_turned.emit()
	return true


func eject() -> bool:
	if not ready() or not gate_open:
		return false
	var c := chambers[under_hammer]
	if c != Chamber.SPENT and c != Chamber.DUD:
		return false
	chambers[under_hammer] = Chamber.EMPTY
	busy = tuning.eject_time
	ejected.emit(c)
	return true


func insert() -> bool:
	if not ready() or not gate_open or belt <= 0 or chambers[under_hammer] != Chamber.EMPTY:
		return false
	chambers[under_hammer] = Chamber.LOADED
	belt -= 1
	busy = tuning.insert_time
	inserted.emit()
	return true


## One press of the reload key: open the gate, then work round the cylinder chamber by chamber
## (eject spent, insert fresh, turn). Returns false when there's nothing left to do.
func reload_step() -> bool:
	if not ready():
		return true
	if not gate_open:
		return open_gate()
	if eject():
		return true
	if insert():
		return true
	if _work_left():
		return turn_cylinder()
	return false


func _work_left() -> bool:
	for c in chambers:
		if c == Chamber.SPENT or c == Chamber.DUD:
			return true
		if c == Chamber.EMPTY and belt > 0:
			return true
	return false


func to_dict() -> Dictionary:
	return {"chambers": chambers.duplicate(), "under_hammer": under_hammer, "hammer": hammer,
			"gate_open": gate_open, "belt": belt}


func from_dict(d: Dictionary) -> void:
	chambers.assign(d.get("chambers", chambers))
	under_hammer = d.get("under_hammer", under_hammer)
	hammer = d.get("hammer", hammer)
	gate_open = d.get("gate_open", gate_open)
	belt = d.get("belt", belt)
