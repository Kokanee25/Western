class_name FireSystem
extends Node3D
## Fire, across every structure in the world. Each member has a temperature; a burning member heats
## what it touches and, less, what's near it (most above, flames climb; little below), and across
## the gap to the next building. Heat soaks into a member according to its thickness, so dry boards
## catch in seconds and heavy timbers take a long time; hot things cool back towards the air.
## Past the ignition point wood burns; stone and glass never do (glass cracks and falls out).
## Burning timber chars from every face: it gets lighter and loses strength (StructureMember
## counts only the sound wood), so the building's loads, checked every second, bring it down;
## boards burn away to nothing. Rubble keeps burning where it falls.
## The rules run on a fixed tick (config/fire.tres) and are tested headless; FireFX draws them.

@export var tuning: FireTuning

## StructureMember -> true: everything hot or burning (the only ones the rules need to visit).
var active := {}
## Burning spilt lamp oil: {position, radius, left, fx}.
var spills: Array[Dictionary] = []
## Wood a blast scorched, catching when its seconds are up: member -> seconds left.
var smouldering := {}

var _near := {}  # member -> [[other, weight], ...]
var _near_age := {}
var _grid := {}  # Vector3i -> Array[StructureMember]
var _grid_age := INF
var _grid_frame := -1  # the physics frame it was last brought up to date
var _accum := 0.0
var _settle_accum := 0.0
var _fx_accum := 0.0
# A tick spread over the frames until the next one: the members still to visit, and those to drop.
var _tick_keys: Array = []
var _tick_at := 0
var _tick_gone: Array[StructureMember] = []
var _tick_dt := 0.0
# Burning buildings waiting to check their loads, one a frame.
var _to_settle: Array = []
## The building whose loads are being checked, a slice of members a frame, and its analysis.
var _checking: Structure
var _check: StructuralAnalysis
## Members a frame for that check (~60 µs each here, ~100 near a blast's damage, where the joists
## and their loads are: the blast-freeze lab's `bf_analyse`, 2026-10-27): a burning town's
## buildings each get looked at every second or two without any one frame taking more than a few
## milliseconds of it (it was 120, ~15 ms a frame here).
const CHECK_MEMBERS := 40
## And while it's coming down (a round for each thing that snaps or falls): a slice between looks
## at the frame's budget (a joist carrying forty boards is ~0.2 ms; a round near a blast is a few
## hundred members). It was 150, one slice ~20 ms here and so always past the budget.
const SETTLE_MEMBERS := 50
## While it's coming down, slices and rounds go on until this much of the frame (ms, this
## workspace's clock; x0.65 at Sean's) is spent: a collapse of 64 rounds unfolds over a few seconds
## (an analysis carried over costs the members near the damage a round, StructuralAnalysis.begin_update).
## Under World.deterministic, Structure.MEMBERS_A_MS members a millisecond of it instead.
const SETTLE_FRAME_MS := 8.0
## Every so many routine checks of a building, one from the top (anything a carried-over analysis
## missed, a member changed without saying so, is caught there; its setting-up alone is ~70 ms for
## the spec saloon, so rarely).
const FULL_CHECK_EVERY := 30
var _rounds := 0
var _urgent := {}  # structure -> true: asked to settle (not just a check): worked out faster
var _checks := {}  # structure -> routine checks so far (for FULL_CHECK_EVERY)
# Members whose grid cells are fixed (standing in a structure that doesn't move).
var _placed := {}
## The grid kept up to date by what changed (`_rebuild_grid`): each structure's members walked so
## far, each member's structure (its place in the group) and index, members by id, and the ids of
## those broken or burnt away since the last rebuild.
var _walked := {}
var _where := {}
var _by_id := {}
var _gone: Array[StringName] = []
## Standing members' world boxes, from when they were placed (they don't move while standing).
var _box := {}
## In play, a burnt-away board's building goes on `_to_settle` (checked a slice a frame) rather
## than settling at the end of every frame a board goes.
var _spreading := false
var _rubble := {}  # broken member -> the cells it was put in last time
var _fx := {}  # member -> FireFX
var _flaming := {}  # member -> true: those showing flames (up to tuning.max_flames)
var _fx_keys: Array = []  # this half second's members to bring up to date, and how far through
var _fx_at := 0
const FX_EVERY := 0.5
var _lights: Array[OmniLight3D] = []
## The smoke round each burning building (SmokeField), and each building's box.
var _smoke: Array[SmokeField] = []
var _building_box := {}
var _light_time := 0.0

const CELL := 2.0

## Far from the player the fire's rules run coarser (more-cores step 5; PeopleTick's bands for
## people, step 4b): a member of a structure within `tuning.near_m` of him is visited every tick,
## to `far_m` every `middle_every`th, further every `far_every`th, each on its own phase (its id)
## and given the time since its last visit, so it burns, chars and heats what's near it at the same
## rate, in bigger steps; a far burning building checks its loads as seldom. Chosen by distance
## only (the structure's box from the player), and only in play: `step()` (tests, tools) and a
## world with no player run everything every tick. `-- --fire-bands=off` is the before.
static var bands := not "--fire-bands=off" in OS.get_cmdline_user_args()
var _ticks := 0
var _settles := 0
var _eye := Vector3.INF  # the player at this tick's start (INF: everything near)
var _last := {}  # member -> the tick it was last visited (banded)
var _band_of := {}  # structure -> its band this tick (1, middle_every or far_every)
var _band_tick := -1


func _ready() -> void:
	add_to_group(&"fire_system")
	if tuning == null:
		tuning = load("res://config/fire.tres")
	Events.member_broken.connect(_on_member_broken)


static func find(tree: SceneTree) -> FireSystem:
	return tree.get_first_node_in_group(&"fire_system") as FireSystem if tree else null


func flammable(m: StructureMember) -> bool:
	return not m.wood in tuning.fireproof


## Set a member alight (a match, a torch, the debug key).
func ignite(m: StructureMember) -> void:
	if m == null or m.consumed:
		return
	m.temperature = maxf(m.temperature, tuning.ignition_temperature + 80.0)
	active[m] = true
	if flammable(m) and not m.burning:
		m.burning = true
		m.burn_time = 0.0
		_picture_frame = -1


## Set a member alight `seconds` from now: a blast's flash scorches dry wood and it catches a moment
## later, out of the dust, not in the flash (dynamite makes no fireball).
func ignite_after(m: StructureMember, seconds: float) -> void:
	if m == null or m.consumed or m.burning:
		return
	smouldering[m] = minf(smouldering.get(m, INF), seconds)


## A lamp smashes: burning oil splashes round `at` and heats whatever's there for a while.
func spill(at: Vector3) -> void:
	var fx := FireFX.spill_flames(self, at, tuning.spill_radius)
	spills.append({"position": at, "radius": tuning.spill_radius, "left": tuning.spill_seconds, "fx": fx})
	_grid_age = INF


## Something small and loose alight (a rag): a burning patch like spilt oil's, `heating` times as
## hot, that whoever owns it moves with it (set the entry's "position"; its "fx" follows) and ends
## (`end_small_fire`) when it's burnt away or put out. It heats what's round it, scorches people
## and counts in fire_near like a spill.
func small_fire(at: Vector3, radius: float, seconds: float, heating := 1.0) -> Dictionary:
	var fx := FireFX.spill_flames(self, at, radius)
	# Flames its own size: a rag's are a hand or two high, not a spill's.
	var k := clampf(radius / tuning.spill_radius * 1.5, 0.15, 1.0)
	var pm := fx.process_material as ParticleProcessMaterial
	pm.initial_velocity_min *= k
	pm.initial_velocity_max *= k
	pm.gravity *= k
	fx.amount = maxi(8, int(fx.amount * k * 2.0))
	((fx.draw_pass_1 as QuadMesh)).size *= lerpf(0.5, 1.0, k)
	var entry := {"position": at, "radius": radius, "left": seconds, "fx": fx, "heating": heating, "small": true}
	spills.append(entry)
	_grid_age = INF
	return entry


## Moves a small fire's flames to where it is now.
func move_small_fire(entry: Dictionary, at: Vector3) -> void:
	entry.position = at
	if is_instance_valid(entry.get("fx")):
		(entry.fx as Node3D).global_position = at


func end_small_fire(entry: Dictionary) -> void:
	if is_instance_valid(entry.get("fx")):
		(entry.fx as Node).queue_free()
	spills.erase(entry)


func burning_members() -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	for m: StructureMember in active:
		if is_instance_valid(m) and m.burning:
			out.append(m)
	return out


## What's burning within `radius` of `at`, for people deciding to get clear: {count, at (the
## nearest burning point, Vector3.INF if none), distance}. From the fire's picture (what's burning
## and where, made once a frame), so it's cheap enough for every townsman a couple of times a
## second however far he looks: a look 30 m round through the grid's cells was every member of
## the saloon, ~3 ms a look (more-cores step 5).
func fire_near(at: Vector3, radius: float) -> Dictionary:
	var out := {"count": 0, "at": Vector3.INF, "distance": INF}
	if active.is_empty() and spills.is_empty():
		return out
	var t := Prof.start()
	_take_picture()
	for i in _picture.size():
		var m: Variant = _picture[i]
		if not is_instance_valid(m) or not (m as StructureMember).burning or (m as StructureMember).consumed:
			continue  # put out or burnt away since the picture
		var box: AABB = _picture_boxes[i]
		var p := at.clamp(box.position, box.end)
		var d := p.distance_to(at)
		if d > radius:
			continue
		out.count += 1
		if d < out.distance:
			out.distance = d
			out.at = p
	for sp in spills:
		var d: float = maxf((sp.position as Vector3).distance_to(at) - sp.radius, 0.0)
		if d <= radius:
			out.count += 1
			if d < out.distance:
				out.distance = d
				out.at = sp.position
	Prof.stop(&"fire_near", t)
	return out


## The fire's picture: the burning members and their boxes, taken at most once a physics frame
## (again after anything catches), for `fire_near`. Everything in `active` that's burning, rubble
## anywhere included (the grid has rubble where it lay at its last rebuild).
var _picture: Array = []
var _picture_boxes: Array[AABB] = []
var _picture_frame := -1


func _take_picture() -> void:
	var frame := Engine.get_physics_frames()
	if frame == _picture_frame:
		return
	_picture_frame = frame
	_picture.clear()
	_picture_boxes.clear()
	for m: Variant in active:
		if is_instance_valid(m) and (m as StructureMember).burning and not (m as StructureMember).consumed:
			_picture.append(m)
			_picture_boxes.append(_aabb(m))


## Where it's burning, seen from above: the `MAP_CELL` m squares (Vector2i) any burning member or
## spill covers, at any height. Made at most every `MAP_EVERY` s and shared, for everyone working
## out a way clear of it at once (FireFlight).
const MAP_CELL := 2.0
const MAP_EVERY := 0.5
var _map := {}
var _map_at := -INF


func burning_map() -> Dictionary:
	var now := float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second  # game time
	if now - _map_at < MAP_EVERY and now >= _map_at:
		return _map
	_map_at = now
	_map = {}
	for m: StructureMember in active:
		if not is_instance_valid(m) or not m.burning or m.consumed:
			continue
		var box := _aabb(m)
		var lo := Vector2i(floori(box.position.x / MAP_CELL), floori(box.position.z / MAP_CELL))
		var hi := Vector2i(floori(box.end.x / MAP_CELL), floori(box.end.z / MAP_CELL))
		for x in range(lo.x, hi.x + 1):
			for z in range(lo.y, hi.y + 1):
				_map[Vector2i(x, z)] = true
	for sp in spills:
		var c: Vector3 = sp.position
		_map[Vector2i(floori(c.x / MAP_CELL), floori(c.z / MAP_CELL))] = true
	return _map


## In play a tick's work is spread over the frames until the next one (a burning town is ~80 ms
## a tick on one core; all at once it was a hitch four times a second), in the same order as
## `step()`, so it comes out the same. The buildings check their loads one a frame.
func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"fire", t)


func _physics_step(delta: float) -> void:
	var t_tick := Prof.start()
	_spreading = true
	_accum += delta
	var frames := maxi(1, roundi(tuning.tick / maxf(delta, 0.001)))
	if _tick_at < _tick_keys.size():
		# Behind (a long frame): finish this tick now; else this frame's share.
		var share := _tick_keys.size() - _tick_at if _accum >= tuning.tick else ceili(float(_tick_keys.size()) / frames)
		_visit(_tick_keys, _tick_at, mini(_tick_at + share, _tick_keys.size()), _tick_dt, _tick_gone)
		_tick_at += share
		if _tick_at >= _tick_keys.size():
			_tick_keys = []
			_finish(_tick_dt, _tick_gone, true)
	while _accum >= tuning.tick and _tick_keys.is_empty():
		_accum -= tuning.tick
		_eye = _player_at()
		_begin(tuning.tick)
		_tick_dt = tuning.tick
		_tick_keys = active.keys()
		_tick_at = 0
		_tick_gone = []
		if _tick_keys.is_empty() or _accum >= tuning.tick:
			_visit(_tick_keys, 0, _tick_keys.size(), _tick_dt, _tick_gone)
			_tick_keys = []
			_finish(_tick_dt, _tick_gone, true)
	_spreading = false
	Prof.stop(&"fire_tick", t_tick)
	var t_loads := Prof.start()
	_check_loads()
	Prof.stop(&"fire_loads", t_loads)
	var t_fx := Prof.start()
	_fx_accum += delta
	if _fx_accum >= FX_EVERY:
		_fx_accum = 0.0
		_update_fx()
	_refresh_fx(maxi(1, roundi(FX_EVERY / maxf(delta, 0.001))))
	_flicker(delta)
	Prof.stop(&"fire_fx", t_fx)


## Run the fire forward by `dt` seconds, all at once.
func step(dt: float) -> void:
	_eye = Vector3.INF
	_begin(dt)
	var gone: Array[StructureMember] = []
	var keys := active.keys()
	_visit(keys, 0, keys.size(), dt, gone)
	_finish(dt, gone, false)


## A tick's start: the grid kept up to date, spilt oil.
func _begin(dt: float) -> void:
	_ticks += 1
	_grid_age += dt
	for m: StructureMember in smouldering.keys():
		smouldering[m] -= dt
		if not is_instance_valid(m):
			smouldering.erase(m)
		elif smouldering[m] <= 0.0:
			smouldering.erase(m)
			ignite(m)
	# Only while there's something for it to find round (nothing heated or burning, no spill: a
	# gunfight's town is ~0.2 ms a frame of placing every member every 2 s, for nothing). The first
	# tick with something to do places them all, up to date.
	if _grid_age > 2.0 and not (active.is_empty() and spills.is_empty()):
		var t_grid := Prof.start()
		_rebuild_grid()
		Prof.stop(&"fire_grid", t_grid)
	# Spilt oil heats what's round it.
	for sp in spills.duplicate():
		sp.left -= dt
		if sp.left <= 0.0:
			if is_instance_valid(sp.fx):
				(sp.fx as Node).queue_free()
			spills.erase(sp)
			continue
		var at: Vector3 = sp.position
		var r: float = sp.radius
		for m in _query(AABB(at - Vector3.ONE * r, Vector3.ONE * r * 2.0)):
			var gap := _gap(AABB(at - Vector3(r, 0.05, r), Vector3(r * 2.0, 0.6, r * 2.0)), m.world_aabb())
			if gap <= 0.05:
				_heat(m, tuning.spill_heating * float(sp.get("heating", 1.0)) * dt)


## Members `keys[from..to)` heat, burn, cool; what's done with goes on `gone`.
func _visit(keys: Array, from: int, to: int, tick_dt: float, gone: Array[StructureMember]) -> void:
	for i in range(from, to):
		var m: StructureMember = keys[i]
		if not is_instance_valid(m) or m.consumed:
			gone.append(m)
			continue
		var dt := tick_dt
		if _eye != Vector3.INF:
			var b := _band(m)
			if b > 1 and posmod(_ticks + hash(m.member_id), b) != 0:
				continue  # far off: not its tick
			dt = tick_dt * clampi(_ticks - int(_last.get(m, _ticks - 1)), 1, tuning.far_every)
			_last[m] = _ticks
		if m.burning:
			m.burn_time += dt
			var intensity := clampf(m.burn_time / tuning.growth_seconds, 0.15, 1.0)
			m.temperature = maxf(m.temperature, 650.0)
			m.char_depth += tuning.char_rate * dt
			var near := _neighbours(m)
			var dropped := false
			for pair: Array in near:
				var o: StructureMember = pair[0]
				# Burning or burnt away, heat makes no more difference to it (and neither ever goes
				# back): left out from here on, as most of a burning building's neighbours are.
				if not is_instance_valid(o) or o.consumed or o.burning:
					dropped = true
					continue
				_heat(o, float(pair[1]) * intensity * dt)
			if dropped:
				_near[m] = near.filter(func(pair: Array) -> bool:
						var o: StructureMember = pair[0]
						return is_instance_valid(o) and not o.consumed and not o.burning)
			if m.thickness() <= tuning.ash_thickness:
				_consume(m)
				gone.append(m)
		else:
			m.temperature += (tuning.ambient_temperature - m.temperature) * tuning.cooling * dt
			if m.wet > 0.0:
				m.wet = maxf(m.wet - tuning.evaporation * dt, 0.0)
			if flammable(m) and m.temperature >= tuning.ignition_temperature:
				m.burning = true
				m.burn_time = 0.0
				_picture_frame = -1
			elif m.wood == &"glass" and m.temperature >= tuning.glass_cracks_at and not m.broken:
				m.shatter(m.global_position, Vector3.DOWN)
			elif m.temperature < tuning.ambient_temperature + 5.0 and m.wet <= 0.0:
				gone.append(m)


## A tick's end: drop what's done with, scorch people, and now and then have the burning
## buildings check their loads (`spread`: one a frame from here, not all now).
func _finish(dt: float, gone: Array[StructureMember], spread: bool) -> void:
	for m in gone:
		active.erase(m)
		_near.erase(m)
		_near_age.erase(m)
		_last.erase(m)
	for m: StructureMember in _near_age:
		_near_age[m] += dt
	_scorch_people(dt)
	_settle_accum += dt
	if _settle_accum >= tuning.settle_every:
		_settle_accum = 0.0
		var structures := {}
		for m: StructureMember in active:
			if is_instance_valid(m) and m.burning and not m.broken and m.get_parent() is Structure:
				structures[m.get_parent()] = true
				(m.get_parent() as Structure).mark_dirty(m.member_id)  # charred: lighter and weaker
		_settles += 1
		for s: Structure in structures:
			if _eye != Vector3.INF and _settles % _band_of_structure(s) != 0:
				continue  # far off: it looks at its loads every so many times (its charring waits, marked)
			if not spread:
				s.settle()
			elif not s in _to_settle:
				_to_settle.append(s)


## The player, if there's one and the bands are on (else INF: everything ticks as near).
func _player_at() -> Vector3:
	if not bands or not is_inside_tree():
		return Vector3.INF
	var p := get_tree().get_first_node_in_group(&"player") as Node3D
	return p.global_position if p else Vector3.INF


## A member's band this tick: its structure's (anything else, near).
func _band(m: StructureMember) -> int:
	var s := m.get_parent() as Structure
	return _band_of_structure(s) if s else 1


func _band_of_structure(s: Structure) -> int:
	if _band_tick != _ticks:
		_band_tick = _ticks
		_band_of.clear()
	var b: Variant = _band_of.get(s)
	if b == null:
		var box := _box_of(s)
		var d := _eye.distance_to(_eye.clamp(box.position, box.end))
		b = 1 if d <= tuning.near_m else (tuning.middle_every if d <= tuning.far_m else tuning.far_every)
		_band_of[s] = b
	return b


## A building to look at when there's time (a slice a frame, nothing urgent): a big one just built.
func queue_check(s: Structure) -> void:
	if is_inside_tree() and s != _checking and not s in _to_settle:
		_to_settle.append(s)


## A building that's had something happen to it (a board burnt away, a hole, a timber landing
## on it): its loads are worked out as soon as what's ahead of it in the queue is done.
func queue_settle(s: Structure) -> bool:
	if not is_inside_tree() or not is_physics_processing():
		return false
	if s != _checking and not s in _to_settle:
		_to_settle.push_front(s)
	_urgent[s] = true
	return true


## Burning buildings' loads, one at a time, an analysis spread over frames: most of the time
## nothing's wrong and that's that; if something's overloaded or has lost its support, it snaps or
## falls (`Structure.apply_round`, the rule `settle()` follows) and the building is analysed again,
## faster, until it stands: a big collapse unfolds over a second or so rather than one long frame.
func _check_loads() -> void:
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
					_check = _checking.start_analysis(full)
			if _check == null:
				return
		if not is_instance_valid(_checking) or not _checking.is_inside_tree():
			_check = null
			_checking = null
			return
		var t_a := Prof.start()
		if _rounds == 0 and not _urgent.has(_checking):
			# The routine look at a burning building: a slice a frame, never more.
			var done := _check.advance(CHECK_MEMBERS)
			Prof.stop(&"fire_analyse", t_a)
			if not done:
				return
		elif not _check.advance(SETTLE_MEMBERS):
			# Something's given way: on with it while the frame's budget lasts.
			Prof.stop(&"fire_analyse", t_a)
			budget.spend(SETTLE_MEMBERS)
			if budget.over():
				return
			continue
		else:
			Prof.stop(&"fire_analyse", t_a)
		_rounds += 1
		var t_r := Prof.start()
		var more := _checking.apply_round(_check)
		Prof.stop(&"fire_apply", t_r)
		if more and _rounds < 64:
			var t_b := Prof.start()
			_check = _checking.start_analysis()
			Prof.stop(&"fire_analyse", t_b)
		else:
			_urgent.erase(_checking)
			_check = null
			_checking = null
		budget.spend(SETTLE_MEMBERS)
		if budget.over():
			return


## Anyone standing in or right next to the flames gets burnt.
func _scorch_people(dt: float) -> void:
	var burning := burning_members()
	if burning.is_empty() and spills.is_empty():
		return
	var people := get_tree().get_nodes_in_group(&"people") + get_tree().get_nodes_in_group(&"player")
	for p: Node in people:
		if not p is Node3D:
			continue
		var body := AABB((p as Node3D).global_position + Vector3(-0.25, 0.0, -0.25), Vector3(0.5, 1.8, 0.5))
		var reach := body.grow(tuning.scorch_reach)
		var heat := 0.0
		# What's burning near him, from the grid (a burning town is thousands of members; rubble is
		# placed in the grid where it lay at the last rebuild, at most 2 s ago).
		for m in _query(reach):
			if not m.burning:
				continue
			var box := _aabb(m)
			if not reach.intersects(box):
				continue  # further than scorch_reach on some axis
			var gap := _gap(body, box)
			if gap < tuning.scorch_reach:
				heat += (1.0 - gap / tuning.scorch_reach) * clampf(m.burn_time / tuning.growth_seconds, 0.2, 1.0)
		for sp in spills:
			var gap := _gap(body, AABB(sp.position - Vector3(sp.radius, 0.0, sp.radius), Vector3(sp.radius * 2.0, 0.5, sp.radius * 2.0)))
			if gap < tuning.scorch_reach:
				heat += 1.0 - gap / tuning.scorch_reach
		if heat > 0.0:
			Events.scorched.emit(p, minf(heat, 4.0) * tuning.scorch_rate * dt)


## Heat soaks into a member in proportion to how thin it is: `amount` is °C for a 1 cm member.
func _heat(m: StructureMember, amount: float) -> void:
	var cm := maxf(m.thickness() * 100.0, 0.5)
	var rise := amount / cm
	active[m] = true
	if m.wet > 0.0:
		# Wet: the heat goes into drying it, and it gets no hotter than boiling till it's dry.
		var dries := amount * tuning.water_per_degree
		if dries < m.wet:
			m.wet -= dries
			m.temperature = minf(m.temperature + rise, 100.0)
			return
		rise *= 1.0 - m.wet / dries
		m.wet = 0.0
		m.temperature = minf(m.temperature, 100.0)
	m.temperature += rise


## Water thrown at `at` (a bucket's worth comes down as a few splashes): shared among the members
## within `radius` by how near each is. A burning one with enough (`quench_litres` a square metre of
## its broadest face) goes out, steaming, and keeps what's left over as wet; with less, its fire is
## knocked back (it burns as if just lit). Others are cooled to boiling at most and soak it up. Burning
## lamp oil isn't put out by water (it floats, and goes on burning). Returns how many it put out.
func douse(at: Vector3, radius: float, litres: float) -> int:
	# Up to date for water thrown now (once a frame: a bucket comes down as many splashes).
	if _grid_frame != Engine.get_physics_frames():
		_rebuild_grid()
	var hit: Array[StructureMember] = []
	var weights: Array[float] = []
	var total := 0.0
	var point := AABB(at, Vector3.ZERO)
	for m in _query(AABB(at - Vector3.ONE * radius, Vector3.ONE * radius * 2.0)):
		if m.consumed:
			continue
		var gap := _gap(point, _aabb(m))
		if gap > radius:
			continue
		var w := maxf(1.0 - gap / radius, 0.2)
		hit.append(m)
		weights.append(w)
		total += w
	var put_out := 0
	for i in hit.size():
		var m := hit[i]
		var water := litres * weights[i] / total
		active[m] = true
		if m.burning:
			var need := tuning.quench_litres * _broadest_face(m)
			if water >= need:
				m.burning = false
				m.burn_time = 0.0
				m.temperature = minf(m.temperature, 100.0)
				m.wet += water - need
				put_out += 1
			else:
				m.burn_time *= 1.0 - water / need
		else:
			m.temperature = minf(m.temperature, 100.0)
			m.wet += water
	if put_out > 0:
		FireFX.steam(self, at, put_out)
		_fx_accum = FX_EVERY  # the flames go at once, not at the next half second
	Events.doused.emit(at, litres, put_out)
	return put_out


static func _broadest_face(m: StructureMember) -> float:
	var s := [m.size.x, m.size.y, m.size.z]
	s.sort()
	return s[1] * s[2]


## Burnt away: nothing left of it.
func _consume(m: StructureMember) -> void:
	if m.get_parent() is Structure:
		(m.get_parent() as Structure).unbatch(m, true)
	m.consumed = true
	m.burning = false
	var was_standing := not m.broken
	m.broken = true
	if m.get_parent() is Structure:
		(m.get_parent() as Structure).mark_dirty(m.member_id)
	var fx: Variant = _fx.get(m)
	if is_instance_valid(fx):
		(fx as Node).queue_free()
	_fx.erase(m)
	for p: Array in m.pieces:
		for o: Variant in p:
			# A piece may be gone already (freed with its rubble): check before it's typed.
			if is_instance_valid(o):
				var n := o as Node
				var body := n.get_parent()
				n.queue_free()
				# Rubble with nothing solid left goes too (it'd fall through the ground), whatever
				# else hangs on it.
				if body is RigidBody3D and not Structure.has_solid_shape(body):
					body.queue_free.call_deferred()
	m.pieces.clear()
	Events.member_broken.emit(m.member_id)
	if was_standing and m.get_parent() is Structure:
		var s := m.get_parent() as Structure
		if not _spreading:
			s.settle_soon()
		elif not s in _to_settle and s != _checking:
			_to_settle.append(s)


# --- Who's near whom ----------------------------------------------------------------------------

## Standing members don't move: they're placed once and stay until they break or burn away.
## Rubble moves, so it's placed afresh each time. Kept up to date by what changed, not by walking
## every member (the spec saloon's 5,150 were ~30 ms every 2 s, more-cores step 5): a structure's
## members are only ever added at its end (`_walked`), and whatever breaks or burns away says so
## (`Events.member_broken`, `_gone`). What's placed goes in the order the full walk placed it (the
## structures in the group's order, each one's members in its order), so the cells list the same
## members in the same order and the fire comes out as it did.
func _rebuild_grid() -> void:
	_grid_age = 0.0
	_grid_frame = Engine.get_physics_frames()
	var todo := {}  # member -> true: to place (again) this time
	# Standing members that broke or burnt away since: out of their cells (broken ones go back in as
	# rubble, where they are now).
	for id: StringName in _gone:
		var m: Variant = _by_id.get(id)
		if m == null or not _placed.has(m):
			continue
		if is_instance_valid(m) and not (m as StructureMember).consumed and not (m as StructureMember).broken:
			continue
		_unplace(m, _placed[m])
		_box.erase(m)
		_placed.erase(m)
		if is_instance_valid(m) and not (m as StructureMember).consumed:
			todo[m] = true
	_gone.clear()
	# Rubble lying still keeps its place; what's moved (or burnt away) is placed again.
	for m: Variant in _rubble.keys():
		if is_instance_valid(m) and not (m as StructureMember).consumed and _lying_still(m):
			continue
		_unplace(m, _rubble[m])
		_rubble.erase(m)
		if is_instance_valid(m) and not (m as StructureMember).consumed:
			todo[m] = true
	# What's been added to each structure since (a new building, the pieces a cut board leaves).
	var order := {}  # structure -> its place in the group, for the walk's order
	var structures := get_tree().get_nodes_in_group(&"structures")
	for si in structures.size():
		var st := structures[si] as Structure
		if st == null:
			continue
		order[st] = si
		var all := st.get_members()
		for i in range(int(_walked.get(st, 0)), all.size()):
			var m := all[i]
			_where[m] = Vector2i(si, i)
			_by_id[m.member_id] = m
			if not m.consumed:
				todo[m] = true
		_walked[st] = all.size()
	var place: Array = []
	for m: StructureMember in todo:
		if not m.get_parent() in order:
			continue  # its structure's gone from the world: the walk wouldn't have found it
		var w: Vector2i = _where[m]
		place.append([int(order[m.get_parent()]), w.y, m])
	place.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for e: Array in place:
		var m: StructureMember = e[2]
		var b := m.world_aabb()
		var lo := (b.position / CELL).floor()
		var hi := (b.end / CELL).floor()
		var cells: Array[Vector3i] = []
		for x in range(int(lo.x), int(hi.x) + 1):
			for y in range(int(lo.y), int(hi.y) + 1):
				for z in range(int(lo.z), int(hi.z) + 1):
					var c := Vector3i(x, y, z)
					_grid.get_or_add(c, []).append(m)
					cells.append(c)
		if m.broken:
			_rubble[m] = cells
		else:
			_placed[m] = cells
			_box[m] = b


func _unplace(m: Variant, cells: Array) -> void:
	for c: Vector3i in cells:
		var list: Array = _grid.get(c, [])
		list.erase(m)
		if list.is_empty():
			_grid.erase(c)


func _on_member_broken(id: StringName) -> void:
	if _by_id.has(id):
		_gone.append(id)


## Every piece of it at rest (asleep, frozen, or not loose at all).
static func _lying_still(m: StructureMember) -> bool:
	for p: Array in m.pieces:
		if not is_instance_valid(p[0]):
			continue
		var body: Variant = (p[0] as Node).get_parent()
		if body is RigidBody3D and not ((body as RigidBody3D).sleeping or (body as RigidBody3D).freeze):
			return false
	return true


func _query(box: AABB) -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	var seen := {}
	var lo := (box.position / CELL).floor()
	var hi := (box.end / CELL).floor()
	for x in range(int(lo.x), int(hi.x) + 1):
		for y in range(int(lo.y), int(hi.y) + 1):
			for z in range(int(lo.z), int(hi.z) + 1):
				for m: StructureMember in _grid.get(Vector3i(x, y, z), []):
					if not seen.has(m) and is_instance_valid(m):
						seen[m] = true
						out.append(m)
	return out


## What a burning member heats, and how hard: touching at full strength, near things less with
## distance; up full, sideways less, down least. Cached, and refreshed while it moves (every 2 s)
## or now and then if it stands (every 30 s); each member a little later than the last by its id,
## so those that caught together don't all look again on one tick (more-cores step 5).
func _neighbours(m: StructureMember) -> Array:
	if _near.has(m):
		var spread := float(posmod(hash(m.member_id), 16)) / 16.0
		if _near_age.get(m, 0.0) < (2.0 + spread * 0.5 if m.broken else 30.0 + spread * 4.0):
			return _near[m]
	var t := Prof.start()
	var a := _aabb(m)
	var out: Array = []
	for o in _query(a.grow(tuning.reach)):
		if o == m or o.consumed:
			continue
		var b := _aabb(o)
		var gap := _gap(a, b)
		if gap > tuning.reach:
			continue
		var w := tuning.contact_heating if gap < 0.03 else tuning.radiant_heating * (1.0 - gap / tuning.reach)
		var dy := b.get_center().y - a.get_center().y
		var above := b.position.y >= a.position.y + 0.05 or dy > 0.15
		var below := b.end.y <= a.position.y + 0.05 or dy < -0.3
		w *= 1.0 if above and not below else (tuning.downward if below else tuning.sideways)
		# Straight over the flames: the flames themselves reach it.
		var overlaps := b.position.x < a.end.x and b.end.x > a.position.x and b.position.z < a.end.z and b.end.z > a.position.z
		var rise := b.position.y - a.end.y
		if overlaps and rise >= -0.03 and rise < tuning.flame_height:
			w = maxf(w, tuning.contact_heating * (1.0 - 0.5 * maxf(rise, 0.0) / tuning.flame_height))
		out.append([o, w])
	_near[m] = out
	_near_age[m] = 0.0
	Prof.stop(&"fire_neigh", t)
	return out


## Where a member is: kept for standing ones, worked out for rubble.
func _aabb(m: StructureMember) -> AABB:
	return _box[m] if not m.broken and _box.has(m) else m.world_aabb()


static func _gap(a: AABB, b: AABB) -> float:
	var d := Vector3.ZERO
	for i in 3:
		d[i] = maxf(0.0, maxf(b.position[i] - a.end[i], a.position[i] - b.end[i]))
	return d.length()


# --- Drawing it -----------------------------------------------------------------------------------

## Metres nearer a member over an opening or in a roof counts, choosing which show flames.
const FLAME_FIRST := 6.0
const ROOF_KINDS := [&"rafter", &"roof_board", &"ridge"]


static func _flames_first(m: StructureMember) -> bool:
	var id := String(m.member_id)
	return m.kind in ROOF_KINDS or id.ends_with("/head") or id.ends_with("/header")


## Every half second: which burning members show flames (those that had them keep them while
## they burn, so flames don't hop about a burning town; free ones go to the burning members nearest
## you, the roof's and the openings' first), and where the fire's lights go. The members' looks are then brought up to date a slice a
## frame over the half second (`_refresh_fx`), not all on one frame.
func _update_fx() -> void:
	var burning := _longest_burning()
	var still := {}
	for m: Variant in _flaming:
		if is_instance_valid(m) and (m as StructureMember).burning and still.size() < tuning.max_flames:
			still[m] = true
	_flaming = still
	if _flaming.size() < tuning.max_flames:
		var cam := get_viewport().get_camera_3d() if get_viewport() else null
		var eye := cam.global_position if cam else Vector3.ZERO
		var by_distance := PackedVector2Array()  # (distance, index): sorted natively
		for i in burning.size():
			if not _flaming.has(burning[i]):
				var d := burning[i].global_position.distance_to(eye) if cam else float(i)
				# The roof and what's over a door or window first: fire through the roof and out of
				# the openings, not one more board up a wall (the art session, with Sean's OK).
				d -= FLAME_FIRST if _flames_first(burning[i]) else 0.0
				by_distance.append(Vector2(d, i))
		by_distance.sort()
		for v in by_distance:
			if _flaming.size() >= tuning.max_flames:
				break
			_flaming[burning[int(v.y)]] = true
	# Only the members showing flames have a FireFX (#434): the rest's go (their char stays, drawn
	# by their structure).
	for m: Variant in _fx.keys():
		if not _flaming.has(m):
			var fx: Variant = _fx[m]
			if is_instance_valid(fx):
				(fx as FireFX).queue_free()
			_fx.erase(m)
	_fx_keys = active.keys()
	_fx_at = 0
	_place_lights(burning)
	_place_smoke(burning)


## The burning members, longest-burning first (sorted natively: a burning town is thousands).
func _longest_burning() -> Array[StructureMember]:
	var all := burning_members()
	var keys := PackedVector2Array()
	keys.resize(all.size())
	for i in all.size():
		keys[i] = Vector2(-all[i].burn_time, i)
	keys.sort()
	var out: Array[StructureMember] = []
	out.resize(all.size())
	for i in keys.size():
		out[i] = all[int(keys[i].y)]
	return out


## A share of the members' looks (char, glow, flames) each frame. Char and glow are drawn by the
## member's structure (in its batch while it stands: #434); a FireFX only for those showing flames.
func _refresh_fx(frames: int) -> void:
	var to := mini(_fx_at + ceili(float(_fx_keys.size()) / maxi(frames, 1)), _fx_keys.size())
	for i in range(_fx_at, to):
		var o: Variant = _fx_keys[i]
		if not is_instance_valid(o):
			continue
		var m := o as StructureMember
		_show_char(m)
		var flames := _flaming.has(m)
		var fx: Variant = _fx.get(m)
		if not is_instance_valid(fx):
			fx = null
		if flames and fx == null:
			fx = FireFX.new()
			fx.member = m
			add_child(fx)
			_fx[m] = fx
		if fx != null:
			(fx as FireFX).refresh(flames, tuning, not smoked(m))
	_fx_at = to


## Its scorch and char, and the glow of its burning front, to its structure to draw.
func _show_char(m: StructureMember) -> void:
	var s := m.get_parent() as Structure
	if s == null or not (m.temperature > 120.0 or m.char_depth > 0.0 or s.has_fire_look(m)):
		return
	var half := maxf(minf(m.size.x, minf(m.size.y, m.size.z)) * 0.5, 0.001)
	var scorch := clampf((m.temperature - 120.0) / 400.0, 0.0, 0.25)
	var glow := clampf(m.burn_time / tuning.growth_seconds, 0.2, 1.0) if m.burning else 0.0
	s.show_fire(m, clampf(maxf(m.char_depth / half, scorch), 0.0, 1.0), glow)


## Smoke that knows the buildings (SmokeField, docs/briefs/smoke.md): a field round each building
## that's burning, up to `smoke_fields`; members outside one (rubble in the street, a building
## past the limit, no native plugin) keep their particle smoke.
func _place_smoke(burning: Array[StructureMember]) -> void:
	_smoke = _smoke.filter(func(f: Variant) -> bool: return is_instance_valid(f) and not f.is_queued_for_deletion())
	if not SmokeField.available():
		return
	for m in burning:
		if _smoke.size() >= tuning.smoke_fields:
			return
		var s := m.get_parent() as Structure
		if s == null or m.broken or smoked(m):
			continue
		_smoke.append(SmokeField.around(self, _box_of(s), s))


## Is this member's smoke drawn by a field?
func smoked(m: StructureMember) -> bool:
	for f in _smoke:
		if is_instance_valid(f) and f.covers(m.global_position):
			return true
	return false


## The smoke at a point (0 clear, 1 thick), from whichever field holds it.
func smoke_at(at: Vector3) -> float:
	var most := 0.0
	for f in _smoke:
		if is_instance_valid(f) and f.covers(at):
			most = maxf(most, f.density_at(at))
	return most


func _box_of(s: Structure) -> AABB:
	if _building_box.has(s):
		return _building_box[s]
	var b := AABB()
	var first := true
	for m: StructureMember in s.get_members():
		if m.broken or m.consumed:
			continue
		var a := m.world_aabb()
		b = a if first else b.merge(a)
		first = false
	_building_box[s] = b
	return b


## A handful of lights where the fire is biggest, not one per burning board.
func _place_lights(burning: Array[StructureMember]) -> void:
	var spots: Array[Vector3] = []
	var sizes: Array[int] = []
	for m in burning:
		var c := _aabb(m).get_center()
		var joined := false
		for i in spots.size():
			if spots[i].distance_to(c) < 3.5:
				sizes[i] += 1
				joined = true
				break
		if not joined and spots.size() < tuning.max_lights:
			spots.append(c)
			sizes.append(1)
	for sp in spills:
		if spots.size() < tuning.max_lights:
			spots.append(sp.position + Vector3.UP * 0.4)
			sizes.append(3)
	# Each light keeps to its own fire: a lit light takes the new spot nearest where it was (within
	# a cluster's reach); only lights whose fire has gone move, so they don't jump about the town.
	var placed_spots: Array[Vector3] = []
	var placed_sizes: Array[int] = []
	placed_spots.resize(spots.size())
	placed_sizes.resize(spots.size())
	var taken := {}
	var slot_of := {}  # spot index -> light index
	for i in mini(_lights.size(), spots.size()):
		var l := _lights[i]
		if not l.visible:
			continue
		var best := -1
		var best_d := 3.5
		for j in spots.size():
			if taken.has(j):
				continue
			var d := (spots[j] + Vector3.UP * 0.5).distance_to(l.global_position)
			if d < best_d:
				best_d = d
				best = j
		if best >= 0:
			taken[best] = true
			slot_of[i] = best
	var free_spots: Array[int] = []
	for j in spots.size():
		if not taken.has(j):
			free_spots.append(j)
	for i in spots.size():
		var j: int = slot_of[i] if slot_of.has(i) else free_spots.pop_front()
		placed_spots[i] = spots[j]
		placed_sizes[i] = sizes[j]
	spots = placed_spots
	sizes = placed_sizes
	while _lights.size() < spots.size():
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.22)
		l.omni_attenuation = 1.4
		l.shadow_enabled = _lights.is_empty()
		add_child(l)
		var crackle := AudioStreamPlayer3D.new()
		crackle.stream = SynthSounds.get_sound(&"fire_crackle" if GameAudio.enabled() else &"fire")
		crackle.unit_size = 6.0
		crackle.autoplay = true
		l.add_child(crackle)
		if GameAudio.enabled():
			# The sound lab: no two fires in step (pitch and where in the loop they start), and a big
			# one roars under its crackle.
			crackle.pitch_scale = 0.9 + 0.2 * fmod(_lights.size() * 0.618, 1.0)
			var roar := AudioStreamPlayer3D.new()
			roar.name = "Roar"
			roar.stream = SynthSounds.get_sound(&"fire_roar")
			roar.unit_size = 10.0
			roar.pitch_scale = 0.95 + 0.1 * fmod(_lights.size() * 0.382, 1.0)
			l.add_child(roar)
		_lights.append(l)
	for i in _lights.size():
		var l := _lights[i]
		l.visible = i < spots.size()
		var crackle := l.get_child(0) as AudioStreamPlayer3D
		if i < spots.size():
			l.global_position = spots[i] + Vector3.UP * 0.5
			l.omni_range = clampf(4.0 + sizes[i] * 0.6, 4.0, 14.0)
			l.set_meta(&"energy", clampf(1.0 + sizes[i] * 0.25, 1.0, 5.0))
			if crackle and not crackle.playing:
				crackle.play(fmod(i * 2.3, 7.0) if GameAudio.enabled() else 0.0)
			if crackle:
				crackle.volume_db = linear_to_db(clampf(0.3 + sizes[i] * 0.08, 0.3, 1.6))
				GameAudio.replace_loop(crackle)
			var roar := l.get_node_or_null(^"Roar") as AudioStreamPlayer3D
			if roar:
				# Past a few members alight it roars, louder the more.
				var loud := clampf((sizes[i] - 3.0) * 0.08, 0.0, 1.4)
				if loud > 0.0:
					roar.volume_db = linear_to_db(loud)
					if not roar.playing:
						roar.play(fmod(i * 1.7, 5.0))
					GameAudio.replace_loop(roar)
				elif roar.playing:
					roar.stop()
		elif crackle:
			crackle.stop()
			var roar := l.get_node_or_null(^"Roar") as AudioStreamPlayer3D
			if roar:
				roar.stop()


func _flicker(delta: float) -> void:
	_light_time += delta
	for i in _lights.size():
		var l := _lights[i]
		if l.visible:
			var e: float = l.get_meta(&"energy", 1.0)
			l.light_energy = e * (0.8 + 0.2 * sin(_light_time * 11.0 + i * 1.7) + 0.1 * sin(_light_time * 23.0 + i))
