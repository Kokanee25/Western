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

var _near := {}  # member -> [[other, weight], ...]
var _near_age := {}
var _grid := {}  # Vector3i -> Array[StructureMember]
var _grid_age := INF
var _accum := 0.0
var _settle_accum := 0.0
var _fx_accum := 0.0
# A tick spread over the frames until the next one: the members still to visit, and those to drop.
var _tick_keys: Array = []
var _tick_at := 0
var _tick_gone: Array[StructureMember] = []
var _tick_dt := 0.0
# Burning buildings waiting to check their loads, one a frame.
var _to_settle: Array[Structure] = []
# Members whose grid cells are fixed (standing in a structure that doesn't move).
var _placed := {}
var _moving_cells: Array[Vector3i] = []  # where rubble was put last time
var _fx := {}  # member -> FireFX
var _lights: Array[OmniLight3D] = []
var _light_time := 0.0

const CELL := 2.0


func _ready() -> void:
	add_to_group(&"fire_system")
	if tuning == null:
		tuning = load("res://config/fire.tres")


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


## A lamp smashes: burning oil splashes round `at` and heats whatever's there for a while.
func spill(at: Vector3) -> void:
	var fx := FireFX.spill_flames(self, at, tuning.spill_radius)
	spills.append({"position": at, "radius": tuning.spill_radius, "left": tuning.spill_seconds, "fx": fx})
	_grid_age = INF


func burning_members() -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	for m: StructureMember in active:
		if is_instance_valid(m) and m.burning:
			out.append(m)
	return out


## In play a tick's work is spread over the frames until the next one (a burning town is ~80 ms
## a tick on one core; all at once it was a hitch four times a second), in the same order as
## `step()`, so it comes out the same. The buildings check their loads one a frame.
func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"fire", t)


func _physics_step(delta: float) -> void:
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
		_begin(tuning.tick)
		_tick_dt = tuning.tick
		_tick_keys = active.keys()
		_tick_at = 0
		_tick_gone = []
		if _tick_keys.is_empty() or _accum >= tuning.tick:
			_visit(_tick_keys, 0, _tick_keys.size(), _tick_dt, _tick_gone)
			_tick_keys = []
			_finish(_tick_dt, _tick_gone, true)
	if not _to_settle.is_empty():
		var s: Structure = _to_settle.pop_front()
		if is_instance_valid(s):
			s.settle()
	_fx_accum += delta
	if _fx_accum >= 0.5:
		_fx_accum = 0.0
		_update_fx()
	_flicker(delta)


## Run the fire forward by `dt` seconds, all at once.
func step(dt: float) -> void:
	_begin(dt)
	var gone: Array[StructureMember] = []
	var keys := active.keys()
	_visit(keys, 0, keys.size(), dt, gone)
	_finish(dt, gone, false)


## A tick's start: the grid kept up to date, spilt oil.
func _begin(dt: float) -> void:
	_grid_age += dt
	if _grid_age > 2.0:
		_rebuild_grid()
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
				_heat(m, tuning.spill_heating * dt)


## Members `keys[from..to)` heat, burn, cool; what's done with goes on `gone`.
func _visit(keys: Array, from: int, to: int, dt: float, gone: Array[StructureMember]) -> void:
	for i in range(from, to):
		var m: StructureMember = keys[i]
		if not is_instance_valid(m) or m.consumed:
			gone.append(m)
			continue
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
			if flammable(m) and m.temperature >= tuning.ignition_temperature:
				m.burning = true
				m.burn_time = 0.0
			elif m.wood == &"glass" and m.temperature >= tuning.glass_cracks_at and not m.broken:
				m.shatter(m.global_position, Vector3.DOWN)
			elif m.temperature < tuning.ambient_temperature + 5.0:
				gone.append(m)


## A tick's end: drop what's done with, scorch people, and now and then have the burning
## buildings check their loads (`spread`: one a frame from here, not all now).
func _finish(dt: float, gone: Array[StructureMember], spread: bool) -> void:
	for m in gone:
		active.erase(m)
		_near.erase(m)
		_near_age.erase(m)
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
		for s: Structure in structures:
			if not spread:
				s.settle()
			elif not s in _to_settle:
				_to_settle.append(s)


## Anyone standing in or right next to the flames gets burnt.
func _scorch_people(dt: float) -> void:
	var burning := burning_members()
	if burning.is_empty() and spills.is_empty():
		return
	var people := get_tree().get_nodes_in_group(&"people") + get_tree().get_nodes_in_group(&"player")
	# Each burning member's box once, not once per person.
	var boxes: Array[AABB] = []
	for m in burning:
		boxes.append(m.world_aabb())
	for p: Node in people:
		if not p is Node3D:
			continue
		var body := AABB((p as Node3D).global_position + Vector3(-0.25, 0.0, -0.25), Vector3(0.5, 1.8, 0.5))
		var reach := body.grow(tuning.scorch_reach)
		var heat := 0.0
		for i in burning.size():
			if not reach.intersects(boxes[i]):
				continue  # further than scorch_reach on some axis
			var gap := _gap(body, boxes[i])
			if gap < tuning.scorch_reach:
				heat += (1.0 - gap / tuning.scorch_reach) * clampf(burning[i].burn_time / tuning.growth_seconds, 0.2, 1.0)
		for sp in spills:
			var gap := _gap(body, AABB(sp.position - Vector3(sp.radius, 0.0, sp.radius), Vector3(sp.radius * 2.0, 0.5, sp.radius * 2.0)))
			if gap < tuning.scorch_reach:
				heat += 1.0 - gap / tuning.scorch_reach
		if heat > 0.0:
			Events.scorched.emit(p, minf(heat, 4.0) * tuning.scorch_rate * dt)


## Heat soaks into a member in proportion to how thin it is: `amount` is °C for a 1 cm member.
func _heat(m: StructureMember, amount: float) -> void:
	var cm := maxf(m.thickness() * 100.0, 0.5)
	m.temperature += amount / cm
	active[m] = true


## Burnt away: nothing left of it.
func _consume(m: StructureMember) -> void:
	if m.get_parent() is Structure:
		(m.get_parent() as Structure).unbatch(m)
	m.consumed = true
	m.burning = false
	var was_standing := not m.broken
	m.broken = true
	var fx: FireFX = _fx.get(m)
	if fx and is_instance_valid(fx):
		fx.queue_free()
	_fx.erase(m)
	for p: Array in m.pieces:
		for n: Node in p:
			if n != null and is_instance_valid(n):
				var body := n.get_parent()
				n.queue_free()
				if body is RigidBody3D and body.get_child_count() <= 2:
					body.queue_free.call_deferred()
	m.pieces.clear()
	Events.member_broken.emit(m.member_id)
	if was_standing and m.get_parent() is Structure:
		(m.get_parent() as Structure).settle_soon()


# --- Who's near whom ----------------------------------------------------------------------------

## Standing members don't move: they're placed once and stay until they break or burn away.
## Rubble moves, so it's placed afresh each time.
func _rebuild_grid() -> void:
	_grid_age = 0.0
	for m: StructureMember in _placed.keys():
		if is_instance_valid(m) and not m.consumed and not m.broken:
			continue
		for c: Vector3i in _placed[m]:
			var list: Array = _grid.get(c, [])
			list.erase(m)
			if list.is_empty():
				_grid.erase(c)
		_placed.erase(m)
	for c: Vector3i in _moving_cells:
		var list: Array = _grid.get(c, [])
		list.assign(list.filter(func(o: Object) -> bool: return _placed.has(o)))
		if list.is_empty():
			_grid.erase(c)
	_moving_cells.clear()
	for s in get_tree().get_nodes_in_group(&"structures"):
		for m: StructureMember in (s as Structure).get_members():
			if m.consumed or _placed.has(m):
				continue
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
				_moving_cells.append_array(cells)
			else:
				_placed[m] = cells


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
## distance; up full, sideways less, down least. Cached, and refreshed while it moves.
func _neighbours(m: StructureMember) -> Array:
	if _near.has(m) and _near_age.get(m, 0.0) < (2.0 if m.broken else 30.0):
		return _near[m]
	var a := m.world_aabb()
	var out: Array = []
	for o in _query(a.grow(tuning.reach)):
		if o == m or o.consumed:
			continue
		var b := o.world_aabb()
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
	return out


static func _gap(a: AABB, b: AABB) -> float:
	var d := Vector3.ZERO
	for i in 3:
		d[i] = maxf(0.0, maxf(b.position[i] - a.end[i], a.position[i] - b.end[i]))
	return d.length()


# --- Drawing it -----------------------------------------------------------------------------------

func _update_fx() -> void:
	var burning := burning_members()
	burning.sort_custom(func(a: StructureMember, b: StructureMember) -> bool: return a.burn_time > b.burn_time)
	var flames := 0
	for m: StructureMember in active:
		if not is_instance_valid(m):
			continue
		var fx: FireFX = _fx.get(m)
		if (m.temperature > 120.0 or m.char_depth > 0.0) and fx == null:
			# Heated or charred, it's drawn on its own (the char overlay), not with its structure's batch.
			if m.get_parent() is Structure:
				(m.get_parent() as Structure).unbatch(m)
			fx = FireFX.new()
			fx.member = m
			add_child(fx)
			_fx[m] = fx
		if fx:
			var show := m.burning and flames < tuning.max_flames
			if show:
				flames += 1
			fx.refresh(show, tuning)
	_place_lights(burning)


## A handful of lights where the fire is biggest, not one per burning board.
func _place_lights(burning: Array[StructureMember]) -> void:
	var spots: Array[Vector3] = []
	var sizes: Array[int] = []
	for m in burning:
		var c := m.world_aabb().get_center()
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
	while _lights.size() < spots.size():
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.22)
		l.omni_attenuation = 1.4
		l.shadow_enabled = _lights.is_empty()
		add_child(l)
		var crackle := AudioStreamPlayer3D.new()
		crackle.stream = SynthSounds.get_sound(&"fire")
		crackle.unit_size = 6.0
		crackle.autoplay = true
		l.add_child(crackle)
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
				crackle.play()
			if crackle:
				crackle.volume_db = linear_to_db(clampf(0.3 + sizes[i] * 0.08, 0.3, 1.6))
		elif crackle:
			crackle.stop()


func _flicker(delta: float) -> void:
	_light_time += delta
	for i in _lights.size():
		var l := _lights[i]
		if l.visible:
			var e: float = l.get_meta(&"energy", 1.0)
			l.light_energy = e * (0.8 + 0.2 * sin(_light_time * 11.0 + i * 1.7) + 0.1 * sin(_light_time * 23.0 + i))
