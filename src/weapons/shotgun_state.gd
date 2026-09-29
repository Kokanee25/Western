class_name ShotgunState
extends RefCounted
## The mechanism of a double-barrelled hammer shotgun, as rules: no animation, no graphics, testable.
##
## Two barrels, each with its own hammer and trigger: thumb back a hammer to cock that barrel,
## the trigger drops it. Right barrel first (the front trigger), then the left. To load, the lever
## breaks the gun open (it lets both hammers down), the extractor lifts the shells, you pull out
## each empty and thumb in a fresh one, and close it. Barrel 0 is the right, 1 the left.

enum Barrel { EMPTY, LOADED, SPENT, DUD }
enum Shot { NONE, FIRED, CLICK, MISFIRE }

signal cocked(barrel: int)
signal fired(barrel: int)
signal clicked(barrel: int)
signal misfired(barrel: int)
signal opened(open: bool)
signal extracted(barrel: int, barrel_state: int)
signal loaded(barrel: int)

var tuning: ShotgunTuning
var barrels: Array[int] = [Barrel.LOADED, Barrel.LOADED]
var cocked_hammers: Array[bool] = [false, false]
var open := false
var pocket := 0
## Seconds until the hands are free for the next action.
var busy := 0.0
## The barrel the last trigger pull dropped a hammer on (-1: none).
var last_barrel := -1

var _rng := RandomNumberGenerator.new()


func _init(t: ShotgunTuning = null, seed := 1882) -> void:
	tuning = t if t else ShotgunTuning.new()
	_rng.seed = seed
	pocket = mini(tuning.start_pocket, tuning.pocket_capacity)


func tick(delta: float) -> void:
	busy = maxf(0.0, busy - delta)


func ready() -> bool:
	return busy <= 0.0


func shells_loaded() -> int:
	return barrels.count(Barrel.LOADED)


## Thumb back the next hammer: the right, then the left.
func cock() -> int:
	if not ready() or open:
		return -1
	for i in 2:
		if not cocked_hammers[i]:
			cocked_hammers[i] = true
			busy = tuning.cock_time
			cocked.emit(i)
			return i
	return -1


## Pull the trigger for the next cocked barrel (the right one's first, a loaded one before an empty). Returns what happened;
## `last_barrel` says which.
func pull_trigger() -> Shot:
	last_barrel = -1
	if not ready() or open:
		return Shot.NONE
	# You pick the trigger: the barrel still loaded, if one of the cocked ones is.
	for i in 2:
		if cocked_hammers[i] and barrels[i] == Barrel.LOADED:
			return _drop(i)
	for i in 2:
		if cocked_hammers[i]:
			return _drop(i)
	return Shot.NONE


## Both triggers at once (both hammers must be back): both barrels go together.
func pull_both() -> Array[Shot]:
	var out: Array[Shot] = []
	if not ready() or open:
		return out
	for i in 2:
		if cocked_hammers[i]:
			busy = 0.0
			out.append(_drop(i))
	return out


func _drop(i: int) -> Shot:
	last_barrel = i
	cocked_hammers[i] = false
	busy = tuning.fire_recovery
	match barrels[i]:
		Barrel.LOADED:
			if _rng.randf() < tuning.misfire_chance:
				barrels[i] = Barrel.DUD
				misfired.emit(i)
				return Shot.MISFIRE
			barrels[i] = Barrel.SPENT
			fired.emit(i)
			return Shot.FIRED
		_:
			clicked.emit(i)
			return Shot.CLICK


## Break it open. Opening lets both hammers down.
func open_action() -> bool:
	if not ready() or open:
		return false
	open = true
	cocked_hammers = [false, false]
	busy = tuning.open_time
	opened.emit(true)
	return true


func close_action() -> bool:
	if not ready() or not open:
		return false
	open = false
	busy = tuning.close_time
	opened.emit(false)
	return true


## Pull out the first empty or dud shell.
func extract() -> bool:
	if not ready() or not open:
		return false
	for i in 2:
		var b := barrels[i]
		if b == Barrel.SPENT or b == Barrel.DUD:
			barrels[i] = Barrel.EMPTY
			busy = tuning.extract_time
			extracted.emit(i, b)
			return true
	return false


func load_shell() -> bool:
	if not ready() or not open or pocket <= 0:
		return false
	for i in 2:
		if barrels[i] == Barrel.EMPTY:
			barrels[i] = Barrel.LOADED
			pocket -= 1
			busy = tuning.load_time
			loaded.emit(i)
			return true
	return false


## One press of the reload key: break it open, pull the empties, thumb in fresh shells, close.
## Returns false when there's nothing left to do (the caller closes it).
func reload_step() -> bool:
	if not ready():
		return true
	if not open:
		return open_action()
	if extract():
		return true
	if load_shell():
		return true
	return false


func to_dict() -> Dictionary:
	return {"barrels": barrels.duplicate(), "cocked": cocked_hammers.duplicate(), "open": open, "pocket": pocket}


func from_dict(d: Dictionary) -> void:
	barrels.assign(d.get("barrels", barrels))
	cocked_hammers.assign(d.get("cocked", cocked_hammers))
	open = d.get("open", open)
	pocket = d.get("pocket", pocket)
