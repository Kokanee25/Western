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
	if _people.is_empty() and _host() == null:
		# A new world (no one in it, no node yet): the counters start again, as a game's do, so the
		# ticks a far man falls on don't depend on what ran before (a test suite; #413, #430).
		_next_index = 0
		_ticks = 0
	if man.tick_index < 0:
		man.tick_index = _next_index
		_next_index += 1
	_next_index = maxi(_next_index, man.tick_index + 1)  # one coming back with his own: no one shares it
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
## 0. who ticks this tick (`_bands`, step 4b): a man far off ticks every 2nd or 4th tick, with the
##    time he missed; the rest of the time he's left alone (all three phases);
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
	_ticks += 1
	var men := _people.duplicate()
	var t := Prof.start()
	var due := _bands(men, delta)
	Prof.stop(&"people_bands", t)
	_batch.clear()
	for man: HumanBody in due:
		if man.is_physics_processing() and man.can_process() and man.begin_prepare():
			_batch.append(man)
	_prep_phase()
	if time_by_why and Prof.on:
		_tick_by_why(due)
		return
	for man: HumanBody in due:
		if is_instance_valid(man) and man.is_inside_tree():
			man.people_tick(man.tick_dt)


## A lab's switch (tools/people_after_blast.gd, #495): each man's tick timed and summed by why he
## can't slow (`t_<reason>`, `t_calm` when he can; his first half's `prep_us` in it) with how many
## ticks (`c_<reason>`). The same ticks, in the same order.
static var time_by_why := false


func _tick_by_why(due: Array[HumanBody]) -> void:
	for man: HumanBody in due:
		if not is_instance_valid(man) or not man.is_inside_tree():
			continue
		var r := man.slow_reason()
		if r == &"":
			r = &"calm"
		var t0 := Time.get_ticks_usec()
		man.people_tick(man.tick_dt)
		var us := Time.get_ticks_usec() - t0 + (man.prep_us if _batch.has(man) else 0)
		Prof.add(StringName("t_" + String(r)), us)
		Prof.count(StringName("c_" + String(r)))


# --- The bands (more-cores step 4b) ------------------------------------------------------------

## Physics ticks since the game started: a band's men tick when it and their index line up, so a
## band's ticks are spread over its men (not all of them on one tick in four).
static var _ticks := 0
static var _tuning: PeopleTickTuning
static var _player: Node3D


## The men that tick this tick, in order, each with his `tick_dt` (this tick's delta and whatever
## he was owed); the others are owed this one. A man's band is his distance to the player and to
## everyone in trouble (`HumanBody.in_trouble`: a fight, running, hands up), with a margin
## each way (`HumanBody.tick_band`); in the camera's view one band nearer, in the middle of it none.
## No player in the world (a lab, a test) or `Settings.people_bands` off: everyone, every tick.
func _bands(men: Array, delta: float) -> Array[HumanBody]:
	var due: Array[HumanBody] = []
	var player := _find_player() if Settings.people_bands else null
	if player == null:
		for man: HumanBody in men:
			if is_instance_valid(man) and man.is_inside_tree():
				man.tick_dt = man.tick_owed + delta
				man.tick_owed = 0.0
				man.tick_band = 0
				man.tick_every = 1
				due.append(man)
		return due
	if _tuning == null:
		_tuning = load("res://config/people_tick.tres")
	var tn := _tuning
	var live: Array[HumanBody] = []
	var calm: Array[bool] = []
	var hot: PackedVector3Array = [player.global_position]
	for man: HumanBody in men:
		if not is_instance_valid(man) or not man.is_inside_tree():
			continue
		live.append(man)
		var c := man.can_slow()
		calm.append(c)
		if not c and man.in_trouble():
			hot.append(man.global_position)  # near trouble is near (a man at a chore or a corpse isn't trouble)
	var cam := (player as Player).camera if player is Player else null
	if cam != null and not cam.is_inside_tree():
		cam = null
	var cam_at := cam.global_position if cam else Vector3.ZERO
	var cam_fwd := -cam.global_basis.z if cam else Vector3.ZERO
	var cone := cos(deg_to_rad(tn.aim_cone_deg))
	var edges := [tn.near_m, tn.far_m]
	var every := [1, tn.middle_every, tn.far_every]
	for i in live.size():
		var man := live[i]
		var at := man.global_position
		var d2 := INF
		var near_hot := 0  # (which: the player is 0)
		for h in hot.size():
			var e := at.distance_squared_to(hot[h])
			if e < d2:
				d2 = e
				near_hot = h
		var d := sqrt(d2)
		var b := man.tick_band
		while b < 2 and d > edges[b] + tn.margin_m:
			b += 1
		while b > 0 and d < edges[b - 1] - tn.margin_m:
			b -= 1
		man.tick_band = b
		var run := b if calm[i] and not man.woken else 0
		var why := &""
		if run > 0 and cam != null:
			var chest := at + Vector3.UP * 1.3
			var to := chest - cam_at
			if to.length_squared() > 1e-6 and cam_fwd.dot(to.normalized()) > cone:
				run = 0  # where he's looking, where the gun points
				why = &"n_full_aimed"
			elif tn.seen_nearer and cam.is_position_in_frustum(chest):
				run -= 1
				why = &"n_full_seen"
		if Prof.on:
			_count_why(man, run, calm[i], b, near_hot, why)
		man.woken = false
		var n: int = every[run]
		man.tick_every = n
		if n <= 1 or (_ticks + man.tick_index) % n == 0:
			man.tick_dt = man.tick_owed + delta
			man.tick_owed = 0.0
			due.append(man)
		elif man.is_physics_processing() and man.can_process():
			man.tick_owed += delta
	if Prof.on:
		Prof.count(&"n_people_ticked", due.size())
		Prof.count(&"n_people_owed", live.size() - due.size())
		Prof.count(&"n_people_trouble", hot.size() - 1)
	return due


## Each man's band in the counts (#495): `n_slow` (a band slower than every tick), else why he
## ticks every tick: `n_full_<reason>` (his `HumanBody.slow_reason`: down, stumbling, fleeing, fear,
## route...), `n_full_woken`, `n_full_near_player`/`n_full_near_trouble` (inside the near band of
## the player or of someone in trouble), `n_full_aimed`/`n_full_seen` (the camera).
func _count_why(man: HumanBody, run: int, calm: bool, band: int, near_hot: int, why: StringName) -> void:
	if run > 0:
		Prof.count(&"n_slow")
		return
	if not calm:
		var r := man.slow_reason()
		if not _why_names.has(r):
			_why_names[r] = StringName("n_full_" + String(r))
		Prof.count(_why_names[r])
	elif man.woken:
		Prof.count(&"n_full_woken")
	elif band == 0:
		Prof.count(&"n_full_near_player" if near_hot == 0 else &"n_full_near_trouble")
	else:
		Prof.count(why if why != &"" else &"n_full_other")


static var _why_names := {}


static func _find_player() -> Node3D:
	if _player != null and is_instance_valid(_player) and _player.is_inside_tree():
		return _player
	_player = null
	if _node != null and is_instance_valid(_node) and _node.is_inside_tree():
		_player = _node.get_tree().get_first_node_in_group(&"player") as Node3D
	return _player


## The men whose first half runs this tick, for the workers (each with his own `tick_dt`).
var _batch: Array[HumanBody] = []
var _timed := false


func _prep_phase() -> void:
	if _batch.is_empty():
		return
	_timed = Prof.on
	var t0 := Time.get_ticks_usec() if _timed else 0
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
	_batch[i].prepare(_batch[i].tick_dt, _timed)
