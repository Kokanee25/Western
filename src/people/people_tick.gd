class_name PeopleTick
extends Node
## The people's tick from one place (docs/briefs/more-cores.md, "The design" B; step 4). Every
## person (`HumanBody`) gets a `tick_index` the first time he enters the world, in the order men
## enter it, kept for good (and saved with him); his own `_physics_process` is off, and this node
## ticks the people once a physics frame in that order. Each man's tick is his body's, then his own
## nodes' (his brain, his face, his senses: `HumanBody.add_ticker`), in the order the tree had them.
##
## It stands in the tree where the last man to come in stands (`_move_to`): the men of a fight,
## who come last, tick after what they did before (the player, the room), and what came after the
## people (the balls in flight, a stick's fuse) still comes after.
##
## A man's switch is still his and his nodes' own `set_physics_process` and `process_mode`: the
## nodes keep physics processing on (they have no `_physics_process` for the engine to call), and
## this ticks only those that have it on and can process.

## The one in the tree (an internal child of the last man to come into the world).
static var _node: PeopleTick
## Everyone in the world, by tick_index.
static var _people: Array[HumanBody] = []
static var _next_index := 0


## He's in the world (his `_enter_tree`): his index (the next, the first time), and his place in
## the order. The last man in takes the node.
static func join(man: HumanBody) -> void:
	if man.tick_index < 0:
		man.tick_index = _next_index
		_next_index += 1
	if not _people.has(man):
		var i := _people.size()
		while i > 0 and _people[i - 1].tick_index > man.tick_index:
			i -= 1
		_people.insert(i, man)
	var host := _host()
	if host == null or host.tick_index < man.tick_index:
		_move_to(man)


## He's leaving it (his `_exit_tree`): if he holds the node, the last man left in the world takes
## it, there and then.
static func leave(man: HumanBody) -> void:
	_people.erase(man)
	if _host() != man:
		return
	for i in range(_people.size() - 1, -1, -1):
		var other := _people[i]
		if is_instance_valid(other) and other.is_inside_tree() and not other.is_queued_for_deletion():
			_move_to(other)
			return
	var n := _node
	_node = null
	man.remove_child(n)
	n.queue_free()


## Everyone ticked, in order (a copy: who comes or goes mid-tick does so from the next).
static func people() -> Array[HumanBody]:
	return _people.duplicate()


static func _host() -> HumanBody:
	if _node == null or not is_instance_valid(_node):
		return null
	return _node.get_parent() as HumanBody


## The node, as an internal child at the front of `man`. It ticks where he stands in the tree (the
## engine ticks a priority in tree order, a node's internal front children before the rest of
## them), so the people tick at the last of them, all at once: whatever ticked between the first
## man and the last (the player, between the street's townsfolk and the fight's men; a building's
## props) now ticks before them all, and what the fight's men had before them they still have.
## Moved in his `_enter_tree`, before his children enter: a man added before the frame's ticks
## ticks in it.
static func _move_to(man: HumanBody) -> void:
	var n := _node
	if n == null or not is_instance_valid(n):
		n = PeopleTick.new()
		n.name = "PeopleTick"
		n.process_mode = Node.PROCESS_MODE_PAUSABLE  # not his: a man switched off doesn't stop the rest
		_node = n
	elif n.get_parent() != null:
		n.get_parent().remove_child(n)
	man.add_child(n, false, Node.INTERNAL_MODE_FRONT)


## The tick in phases ("The design" B):
## 1. on the main thread, each man that ticks says what his first half needs from the scene
##    (`HumanBody.begin_prepare`);
## 2. their first halves, pure (`HumanBody.prepare`: physiology, favouring, the pose's maths), on
##    the worker pool when `Settings.people_threads` is on, else here one after another: each man
##    writes only his own data, so the two are the same game;
## 3. each man's tick in order (`people_tick`): his tick applies the first half (the joints set,
##    the rig, the skeleton, the signs), then his brain, face and senses.
## Phase 2's wall time (`people_prep`) and the sum of its men's (`people_prep_sum`) go to Prof.
func _physics_process(delta: float) -> void:
	if _node != self:
		return
	var men := _people.duplicate()
	_batch.clear()
	for man: HumanBody in men:
		if is_instance_valid(man) and man.is_inside_tree() and man.is_physics_processing() and man.can_process() \
				and man.begin_prepare():
			_batch.append(man)
	_prep_phase(delta)
	for man: HumanBody in men:
		if is_instance_valid(man) and man.is_inside_tree():
			man.people_tick(delta)


## The men whose first half runs this tick, and the tick's delta, for the workers.
var _batch: Array[HumanBody] = []
var _dt := 0.0
var _timed := false


func _prep_phase(delta: float) -> void:
	if _batch.is_empty():
		return
	_timed = Prof.on
	var t0 := Time.get_ticks_usec() if _timed else 0
	_dt = delta
	if Settings.people_threads and _batch.size() > 1:
		# High priority: a low-priority pool task can hang the game at quit (issue #392).
		var id := WorkerThreadPool.add_group_task(_prep_one, _batch.size(), -1, true, "people: prepare")
		WorkerThreadPool.wait_for_group_task_completion(id)
	else:
		for i in _batch.size():
			_prep_one(i)
	if _timed:
		Prof.add(&"people_prep", Time.get_ticks_usec() - t0)
		var sum := 0
		for man in _batch:
			sum += man.prep_us
		Prof.add(&"people_prep_sum", sum)


func _prep_one(i: int) -> void:
	_batch[i].prepare(_dt, _timed)
