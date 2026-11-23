class_name SettleQueue
extends Node
## Buildings' loads worked out a slice a frame: a blast's collapse unfolds over a few frames, not
## one long one (Structure.settle hands the rest here once its frame's budget is spent), and a
## burning building's routine look at its loads costs a millisecond or two a frame. It was the
## FireSystem's own queue (#374, #538); taken out into this node (#1128) so a world with no fire
## (the valley) slices a settle the same way. A FireSystem holds one and runs it at its own place
## in its tick (`driver`); on its own it runs on its physics frame.
##
## Most of the time nothing's wrong and that's that; if something's overloaded or has lost its
## support, it snaps or falls (`Structure.apply_round`, the rule `settle()` follows) and the
## building is analysed again until it stands. Each analysis is begun here (what changed and what
## its loads reach: StructuralAnalysis.begin_update), its members' records copied a slice a frame,
## and the rest worked out on a worker (more-cores step 8), its results applied on a tick fixed by
## how many members it has (`WORKER_MEMBERS_A_TICK`), never on whatever frame it's done: a seeded
## run is the same with the worker and without (`-- --analysis-worker=off` does the same work on
## the main thread on the same ticks). Anything else that analyses the building meanwhile (a
## blast's settle: Structure.analysis_epoch), or asks it to settle, and the worker's results are of
## how it stood before: thrown away, and begun again.

## Members a frame for a routine check: their records copied (~10 µs each here; working them out is
## the worker's, ~60 µs each, ~100 near a blast's damage: the blast-freeze lab's `bf_analyse`,
## 2026-10-27): a burning town's buildings each get looked at every second or two without any one
## frame taking more than a millisecond or two of it.
const CHECK_MEMBERS := 120
## The worker's results come this many members of analysis a physics tick after it's handed them
## (one tick at least): a fixed count, so the tick they arrive on is the same every run, and about
## what a worker gets through in a tick here (~60 µs a member).
const WORKER_MEMBERS_A_TICK := 200
## A record copied costs about a sixth of a member worked out (the budget's unit under
## World.deterministic), and a round applied about fifty.
const RECORDS_AN_ANALYSIS := 6
const ROUND_COST := 50
## While it's coming down (a round for each thing that snaps or falls): records a slice, slices
## at the frame's budget (a round near a blast is a few hundred members).
const SETTLE_MEMBERS := 150
## While it's coming down, slices and rounds go on until this much of the frame (ms, this
## workspace's clock; x0.65 at Sean's) is spent: a collapse of 64 rounds unfolds over a few seconds
## (an analysis carried over costs the members near the damage a round, StructuralAnalysis.begin_update).
## Under World.deterministic, Structure.MEMBERS_A_MS members a millisecond of it instead.
const SETTLE_FRAME_MS := 8.0
## Every so many routine checks of a building, one from the top (anything a carried-over analysis
## missed, a member changed without saying so, is caught there; its setting-up alone is ~70 ms for
## the spec saloon, so rarely).
const FULL_CHECK_EVERY := 30
## The analyses on a worker (`-- --analysis-worker=off`: on the main thread, on the same ticks).
static var analysis_worker := not "--analysis-worker=off" in OS.get_cmdline_user_args()

## The node that runs it (`check_loads` from its own tick: the FireSystem), or null: it runs on
## its own physics frame.
var driver: Node
## Buildings waiting to check their loads, one at a time.
var _to_settle: Array = []
## The building whose loads are being checked, a slice of members a frame, and its analysis.
var _checking: Structure
var _check: StructuralAnalysis
## Something happened to `_checking` since its analysis began (a blast while its first look was
## under way): the analysis is of how it stood before, so it begins again.
var _stale := false
var _due := -1  # the physics frame the worker's results are applied on (-1: none on it)
## Physics frames the load checks sit out (`sit_out`: a blast's), tick -> true.
var _sit_out := {}
var _epoch := -1  # `_checking.analysis_epoch` when its analysis was begun
var _rounds := 0
var _urgent := {}  # structure -> true: asked to settle (not just a check): worked out faster
var _checks := {}  # structure -> routine checks so far (for FULL_CHECK_EVERY)


func _ready() -> void:
	add_to_group(&"settle_queue")
	set_physics_process(driver == null)


## The world's queue (a FireSystem's, or the valley's own), or null (tests, the labs' stands: a
## settle runs to the end on its frame).
static func find(tree: SceneTree) -> SettleQueue:
	return tree.get_first_node_in_group(&"settle_queue") as SettleQueue if tree else null


func _physics_process(_delta: float) -> void:
	var t := Prof.start()
	check_loads()
	Prof.stop(&"settle_queue", t)


## Running: its frames are its own, or its driver's.
func running_frames() -> bool:
	var d := driver if driver else self
	return is_inside_tree() and d.is_physics_processing()


## The check on a worker, not finished (GameQuit waits for it).
func check_running() -> bool:
	return _check != null and _check.running()


## Nothing waiting and nothing being worked out.
func idle() -> bool:
	return _to_settle.is_empty() and _check == null


## A building to look at when there's time (a slice a frame, nothing urgent): a big one just built.
func queue_check(s: Structure) -> void:
	if is_inside_tree() and s != _checking and not s in _to_settle:
		_to_settle.append(s)


## A building to look at again once what's ahead of it is done, even the one being checked (that
## check began before whatever's changed, #454's rule): the fire's charring and burnt-away boards.
func queue_again(s: Structure) -> void:
	if not s in _to_settle:
		_to_settle.append(s)


## Asked to settle and not done yet: being worked out a slice a frame, or waiting its turn.
func settling(s: Structure) -> bool:
	return _urgent.has(s) and (s == _checking or s in _to_settle)


## A building that's had something happen to it (a board burnt away, a hole, a timber landing
## on it, a blast's collapse): its loads are worked out as soon as what's ahead of it in the queue
## is done. False if the queue isn't running (the caller settles it itself).
func queue_settle(s: Structure) -> bool:
	if not running_frames():
		return false
	if s == _checking:
		_stale = true
	elif not s in _to_settle:
		_to_settle.push_front(s)
	_urgent[s] = true
	return true


## The load checks skip physics frame `tick` (this one by default): a blast's frame is long
## enough without a slice of them (the street's third stick: a building's first analysis begun and
## 150 records copied, ~36 ms here, on the stick's own frame, #538). A lit stick asks for the tick
## its fuse runs out on, a tick ahead (the queue may run before it does); a blast for its own, and
## what it queues (its settles) starts on the next.
func sit_out(tick := -1) -> void:
	_sit_out[Engine.get_physics_frames() if tick < 0 else tick] = true


## This frame's share: one building at a time, a slice of it.
func check_loads() -> void:
	if not _sit_out.is_empty():
		var now := Engine.get_physics_frames()
		for k: int in _sit_out.keys():
			if k < now:
				_sit_out.erase(k)
		if _sit_out.has(now):
			return
	var budget := WorkBudget.new(SETTLE_FRAME_MS, int(SETTLE_FRAME_MS * Structure.MEMBERS_A_MS))
	while true:
		if _check == null:
			while not _to_settle.is_empty() and _check == null:
				var next: Variant = _to_settle.pop_front()
				if is_instance_valid(next) and (next as Structure).collapses and (next as Structure).is_inside_tree():
					_checking = next
					_rounds = 0
					var full := false
					if not _urgent.has(_checking):
						_checks[_checking] = int(_checks.get(_checking, 0)) + 1
						full = int(_checks[_checking]) % FULL_CHECK_EVERY == 0
					_begin_check(full)
			if _check == null:
				return
		if not is_instance_valid(_checking) or not _checking.is_inside_tree():
			if _check:
				_check.wait()
			_check = null
			_checking = null
			_due = -1
			return
		if _due >= 0:
			# On the worker: its results on their tick.
			if Engine.get_physics_frames() < _due:
				return
			_due = -1
			var t_w := Prof.start()
			_check.wait()
			Prof.stop(&"fire_wait", t_w)
			if _stale or _epoch != _checking.analysis_epoch:
				_begin_check()
				continue
		else:
			if _stale or _epoch != _checking.analysis_epoch:
				_begin_check()
			var routine := _rounds == 0 and not _urgent.has(_checking)
			var t_a := Prof.start()
			var n := mini(CHECK_MEMBERS if routine else SETTLE_MEMBERS, _check.unprepared())
			var ready := _check.prepare(n)
			Prof.stop(&"fire_analyse", t_a)
			budget.spend(ceili(float(n) / RECORDS_AN_ANALYSIS))
			if not ready:
				# A routine look: a slice a frame, never more; while it's coming down, on while
				# the frame's budget lasts.
				if routine or budget.over():
					return
				continue
			if _check.left() > 0:
				_due = Engine.get_physics_frames() + 1 + _check.left() / WORKER_MEMBERS_A_TICK
				if analysis_worker:
					_check.run_async()
				else:
					var t_m := Prof.start()
					_check.advance(_check.left())
					Prof.stop(&"fire_analyse", t_m)
				return
		_rounds += 1
		var t_r := Prof.start()
		var more := _checking.apply_round(_check)
		Prof.stop(&"fire_apply", t_r)
		if more and _rounds < 64:
			var t_b := Prof.start()
			_begin_check()  # (its own round's changes are in this one)
			Prof.stop(&"fire_analyse", t_b)
		else:
			_urgent.erase(_checking)
			_check = null
			_checking = null
		budget.spend(ROUND_COST)
		if budget.over():
			return


## `_checking`'s analysis begun (again): what's changed since its last, or `full`, from the top.
func _begin_check(full := false) -> void:
	_check = _checking.start_analysis(full)
	_epoch = _checking.analysis_epoch
	_stale = false
	_due = -1
