class_name SpawnQueue
extends Node
## What a break throws, made a few a tick (issue #538). A stick in the spec saloon breaks ~70
## members on one tick, and making what they throw all on that tick (~500 glass shards, ~100 pieces
## of the boards it holed, ~150 bodies of the props it blows over, each a body, a mesh and a shape,
## then all of them new to the physics engine at once) was ~250 ms of a ~300 ms frame, then ~120
## on the next. What breaks is still decided, and shown, on the tick it breaks (the pane gone, the
## hole in the board, the settle); only the making of the loose bodies waits here, and is done in
## the order asked, at most PER_TICK bodies a physics tick. A job that fits what's left of this
## tick's allowance, with nothing waiting before it, runs at once: a pane a ball breaks still
## shatters on the tick it's hit, as before.
##
## Counted in bodies, never in time, so the same breaks make the same bodies on the same ticks
## (World.deterministic). Two queues: SOON (a holed board's pieces: the big things you see fly)
## before LATER (glass shards).

## Bodies made a tick at most (a job is never split: the last one in a tick may go over).
const PER_TICK := 120
## Its tick's place: after the systems' (0), before PhysicsWindow's end (1,000,000).
const TICK_PRIORITY := 1000
const SOON := 0
const LATER := 1

var _jobs: Array = [[], []]  # per queue: [Callable, cost]
var _tick := -1
var _spent := 0


## The queue of `n`'s tree (made the first time it's asked); null out of the tree.
static func for_node(n: Node) -> SpawnQueue:
	if n == null or not n.is_inside_tree():
		return null
	var tree := n.get_tree()
	var q := tree.get_first_node_in_group(&"spawn_queue") as SpawnQueue
	if q == null:
		q = SpawnQueue.new()
		q.name = "SpawnQueue"
		q.add_to_group(&"spawn_queue")
		# After every system's tick, whatever came into the tree before or after it (a second
		# world in the same run ticked in another order and broke other boards).
		q.process_physics_priority = TICK_PRIORITY
		(tree.current_scene if tree.current_scene else tree.root).add_child(q)
	return q


## Make what `job` makes (about `cost` bodies) now if this tick has room for it and nothing's
## waiting before it, else as soon as there's room. Out of the tree, or no queue: now.
static func run(n: Node, job: Callable, cost: int, queue := SOON) -> void:
	var q := for_node(n)
	if q == null:
		job.call()
		return
	q._run(job, cost, queue)


## `cost` bodies made elsewhere this tick (a kit prop blown loose, which can't wait: its push is
## the tick after it goes loose): they use up this tick's room, so the queue's own wait a tick.
static func spent(n: Node, cost: int) -> void:
	var q := for_node(n)
	if q:
		q._new_tick()
		q._spent += cost


## Jobs waiting in `n`'s tree (all queues).
static func waiting(n: Node) -> int:
	var q := n.get_tree().get_first_node_in_group(&"spawn_queue") as SpawnQueue if n and n.is_inside_tree() else null
	return q.pending() if q else 0


func pending() -> int:
	return (_jobs[SOON] as Array).size() + (_jobs[LATER] as Array).size()


func _run(job: Callable, cost: int, queue: int) -> void:
	_new_tick()
	var ahead := (_jobs[SOON] as Array).size() + ((_jobs[LATER] as Array).size() if queue == LATER else 0)
	if ahead == 0 and _spent + cost <= PER_TICK:
		_spent += cost
		job.call()
		return
	(_jobs[queue] as Array).append([job, cost])


func _new_tick() -> void:
	var tick := Engine.get_physics_frames()
	if tick != _tick:
		_tick = tick
		_spent = 0


func _physics_process(_delta: float) -> void:
	if pending() == 0:
		return
	var t := Prof.start()
	_new_tick()
	for queue in [SOON, LATER]:
		var jobs: Array = _jobs[queue]
		while not jobs.is_empty() and _spent < PER_TICK:
			var e: Array = jobs.pop_front()
			var job: Callable = e[0]
			if job.is_valid():
				_spent += int(e[1])
				job.call()
	Prof.stop(&"spawn_queue", t)
