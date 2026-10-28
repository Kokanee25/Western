class_name FireCoreScript
extends RefCounted
## The fire's member tick in GDScript: the native plugin's `FireCore` (addons/saltcreek_native,
## fire.rs) rule for rule, for where the plugin isn't (the web build) and for the test that holds
## the two the same (`tests/test_fire_core.gd`). Every member the fire has met has a slot here: its
## temperature, water, char and burn time (StructureMember's own properties read and write them
## through), its size, what it's made of, what it heats and how hard, its box in the core's grid
## (2 m cells, in FireSystem's order). `visit` runs a slice of a tick (a burning member's list of
## what it heats made again there when it's due) and hands back what the scene must do, as events
## (pairs: event, index in the slice, or the slot for EV_ACTIVATE), in the order they happened;
## FireSystem does them.

const F_BURNING := 1
const F_CONSUMED := 2
const F_ACTIVE := 4
const F_VALID := 8
const F_FLAMMABLE := 16
const F_GLASS := 32
const F_HAS_NEAR := 64
const F_BROKEN := 128
const NONE := -9223372036854775807 - 1

const EV_GONE := 0
const EV_CONSUME := 1
const EV_IGNITE := 2
const EV_GLASS := 3
const EV_ACTIVATE := 4

var ignition := 290.0
var ambient := 20.0
var cracks := 240.0
var cooling := 0.0055
var growth := 32.0
var char_rate := 0.0000625
var ash := 0.004
var water_per_degree := 0.0007
var evaporation := 0.002
var far_every := 4
var reach := 1.3
var contact := 30.0
var radiant := 4.5
var downward := 0.12
var sideways := 0.45
var flame_height := 0.6
const CELL := 2.0

var _temp := PackedFloat64Array()
var _wet := PackedFloat64Array()
var _burn := PackedFloat64Array()
var _char := PackedFloat64Array()
var _size := PackedVector3Array()
var _flags := PackedInt32Array()
var _hash := PackedInt64Array()
var _last := PackedInt64Array()
var _structure := PackedInt32Array()
var _near: Array = []  # slot -> [PackedInt32Array others, PackedFloat64Array weights]
var _near_age := PackedFloat64Array()
var _box: Array[AABB] = []
var _grid := {}  # Vector3i -> [slot, ...], in the order placed
var _cells: Array = []  # slot -> its cells


func tune(name: String, value: float) -> bool:
	match name:
		"ignition_temperature": ignition = value
		"ambient_temperature": ambient = value
		"glass_cracks_at": cracks = value
		"cooling": cooling = value
		"growth_seconds": growth = value
		"char_rate": char_rate = value
		"ash_thickness": ash = value
		"water_per_degree": water_per_degree = value
		"evaporation": evaporation = value
		"far_every": far_every = int(value)
		"reach": reach = value
		"contact_heating": contact = value
		"radiant_heating": radiant = value
		"downward": downward = value
		"sideways": sideways = value
		"flame_height": flame_height = value
		_: return false
	return true


func add(temperature: float, wet: float, char_depth: float, burn_time: float, flags: int, size: Vector3, id_hash: int, structure: int) -> int:
	_temp.append(temperature)
	_wet.append(wet)
	_char.append(char_depth)
	_burn.append(burn_time)
	_size.append(size)
	_flags.append(flags | F_VALID)
	_hash.append(id_hash)
	_last.append(NONE)
	_structure.append(structure)
	_near.append(null)
	_near_age.append(0.0)
	_box.append(AABB())
	_cells.append([])
	return _temp.size() - 1


func release(s: int) -> void:
	_flags[s] &= ~F_VALID
	forget(s)
	unplace(s)


func size() -> int:
	return _flags.size()


func temperature(s: int) -> float:
	return _temp[s]


func set_temperature(s: int, v: float) -> void:
	_temp[s] = v


func wet(s: int) -> float:
	return _wet[s]


func set_wet(s: int, v: float) -> void:
	_wet[s] = v


func char_depth(s: int) -> float:
	return _char[s]


func set_char_depth(s: int, v: float) -> void:
	_char[s] = v


func burn_time(s: int) -> float:
	return _burn[s]


func set_burn_time(s: int, v: float) -> void:
	_burn[s] = v


func set_flag(s: int, flag: int, on: bool) -> void:
	_flags[s] = (_flags[s] | flag) if on else (_flags[s] & ~flag)


func flag(s: int, f: int) -> bool:
	return _flags[s] & f != 0


func thickness(s: int) -> float:
	var t := INF
	var sz := _size[s]
	for i in 3:
		t = minf(t, sz[i] - _char[s] * 2.0)
	return maxf(t, 0.0)


func heat(s: int, amount: float) -> bool:
	var cm := maxf(thickness(s) * 100.0, 0.5)
	var rise := amount / cm
	var newly := _flags[s] & F_ACTIVE == 0
	_flags[s] |= F_ACTIVE
	if _wet[s] > 0.0:
		var dries := amount * water_per_degree
		if dries < _wet[s]:
			_wet[s] -= dries
			_temp[s] = minf(_temp[s] + rise, 100.0)
			return newly
		rise *= 1.0 - _wet[s] / dries
		_wet[s] = 0.0
		_temp[s] = minf(_temp[s], 100.0)
	_temp[s] += rise
	return newly


func place(s: int, b: AABB) -> void:
	_box[s] = b
	var lo := (b.position / CELL).floor()
	var hi := (b.end / CELL).floor()
	var mine: Array[Vector3i] = []
	for x in range(int(lo.x), int(hi.x) + 1):
		for y in range(int(lo.y), int(hi.y) + 1):
			for z in range(int(lo.z), int(hi.z) + 1):
				var c := Vector3i(x, y, z)
				(_grid.get_or_add(c, []) as Array).append(s)
				mine.append(c)
	_cells[s] = mine


func unplace(s: int) -> void:
	for c: Vector3i in _cells[s]:
		var list: Array = _grid.get(c, [])
		list.erase(s)
		if list.is_empty():
			_grid.erase(c)
	_cells[s] = []


func near_of(s: int) -> Array:
	var near: Variant = _near[s]
	return near if near != null else [PackedInt32Array(), PackedFloat64Array()]


## What `s` heats, and how hard (fire.rs make_near, rule for rule).
func make_near(s: int) -> void:
	var a := _box[s]
	var q := a.grow(reach)
	var lo := (q.position / CELL).floor()
	var hi := (q.end / CELL).floor()
	var seen := {}
	var others := PackedInt32Array()
	var weights := PackedFloat64Array()
	for x in range(int(lo.x), int(hi.x) + 1):
		for y in range(int(lo.y), int(hi.y) + 1):
			for z in range(int(lo.z), int(hi.z) + 1):
				for o: int in _grid.get(Vector3i(x, y, z), []):
					if seen.has(o) or not _flags[o] & F_VALID:
						continue
					seen[o] = true
					if o == s or _flags[o] & F_CONSUMED:
						continue
					var b := _box[o]
					var gap := _gap(a, b)
					if gap > reach:
						continue
					var w := contact if gap < 0.03 else radiant * (1.0 - gap / reach)
					var dy := b.get_center().y - a.get_center().y
					var above := b.position.y >= a.position.y + 0.05 or dy > 0.15
					var below := b.end.y <= a.position.y + 0.05 or dy < -0.3
					w *= 1.0 if above and not below else (downward if below else sideways)
					var overlaps := b.position.x < a.end.x and b.end.x > a.position.x and b.position.z < a.end.z and b.end.z > a.position.z
					var rise := b.position.y - a.end.y
					if overlaps and rise >= -0.03 and rise < flame_height:
						w = maxf(w, contact * (1.0 - 0.5 * maxf(rise, 0.0) / flame_height))
					others.append(o)
					weights.append(w)
	_near[s] = [others, weights]
	_near_age[s] = 0.0
	_flags[s] |= F_HAS_NEAR


static func _gap(a: AABB, b: AABB) -> float:
	var d := Vector3.ZERO
	for i in 3:
		d[i] = maxf(0.0, maxf(b.position[i] - a.end[i], a.position[i] - b.end[i]))
	return d.length()


func age_near(dt: float) -> void:
	for s in _flags.size():
		if _flags[s] & F_HAS_NEAR:
			_near_age[s] += dt


func forget(s: int) -> void:
	_flags[s] &= ~(F_ACTIVE | F_HAS_NEAR)
	_near[s] = null
	_near_age[s] = 0.0
	_last[s] = NONE


func _band(s: int, bands: PackedInt32Array) -> int:
	var st := _structure[s]
	return bands[st] if st >= 0 and st < bands.size() else 1


func _skipped(s: int, banded: bool, ticks: int, bands: PackedInt32Array) -> bool:
	if not banded:
		return false
	var b := _band(s, bands)
	return b > 1 and posmod(ticks + _hash[s], b) != 0


func _live(s: int) -> bool:
	return s >= 0 and s < _flags.size() and _flags[s] & F_VALID and not _flags[s] & F_CONSUMED


func _near_is_due(s: int) -> bool:
	if not _flags[s] & F_HAS_NEAR:
		return true
	var spread := float(posmod(_hash[s], 16)) / 16.0
	var keep := 2.0 + spread * 0.5 if _flags[s] & F_BROKEN else 30.0 + spread * 4.0
	return _near_age[s] >= keep


func visit(slots: PackedInt32Array, tick_dt: float, banded: bool, ticks: int, bands: PackedInt32Array) -> PackedInt32Array:
	var ev := PackedInt32Array()
	var far := maxi(far_every, 1)
	for i in slots.size():
		var s := slots[i]
		if not _live(s):
			ev.append_array([EV_GONE, i])
			continue
		var dt := tick_dt
		if banded:
			if _skipped(s, banded, ticks, bands):
				continue  # far off: not its tick
			var last := ticks - 1 if _last[s] == NONE else _last[s]
			dt = tick_dt * clampi(ticks - last, 1, far)
			_last[s] = ticks
		if _flags[s] & F_BURNING:
			_burn[s] += dt
			var intensity := clampf(_burn[s] / growth, 0.15, 1.0)
			_temp[s] = maxf(_temp[s], 650.0)
			_char[s] += char_rate * dt
			if _near_is_due(s):
				make_near(s)
			var near: Variant = _near[s]
			if near != null:
				var others: PackedInt32Array = near[0]
				var weights: PackedFloat64Array = near[1]
				var dropped := false
				for k in others.size():
					var o := others[k]
					# Burning or burnt away, heat makes no more difference to it: left out from here on.
					if not _flags[o] & F_VALID or _flags[o] & (F_CONSUMED | F_BURNING):
						dropped = true
						continue
					if heat(o, weights[k] * intensity * dt):
						ev.append_array([EV_ACTIVATE, o])
				if dropped:
					var keep_o := PackedInt32Array()
					var keep_w := PackedFloat64Array()
					for k in others.size():
						var o := others[k]
						if _flags[o] & F_VALID and not _flags[o] & (F_CONSUMED | F_BURNING):
							keep_o.append(o)
							keep_w.append(weights[k])
					_near[s] = [keep_o, keep_w]
			if thickness(s) <= ash:
				_flags[s] = (_flags[s] | F_CONSUMED) & ~F_BURNING
				ev.append_array([EV_CONSUME, i])
		else:
			_temp[s] += (ambient - _temp[s]) * cooling * dt
			if _wet[s] > 0.0:
				_wet[s] = maxf(_wet[s] - evaporation * dt, 0.0)
			if _flags[s] & F_FLAMMABLE and _temp[s] >= ignition:
				_flags[s] |= F_BURNING
				_burn[s] = 0.0
				ev.append_array([EV_IGNITE, i])
			elif _flags[s] & F_GLASS and _temp[s] >= cracks:
				if not _flags[s] & F_BROKEN:
					ev.append_array([EV_GLASS, i])
			elif _temp[s] < ambient + 5.0 and _wet[s] <= 0.0:
				ev.append_array([EV_GONE, i])
	return ev


func set_box(s: int, b: AABB) -> void:
	_box[s] = b


func burning_near(at: Vector3, radius: float) -> Array:
	var count := 0
	var best := Vector3.INF
	var best_d := INF
	for s in _flags.size():
		var f := _flags[s]
		if f & (F_VALID | F_BURNING) != (F_VALID | F_BURNING) or f & F_CONSUMED:
			continue
		var b := _box[s]
		var p := at.clamp(b.position, b.end)
		var d := p.distance_to(at)
		if d > radius:
			continue
		count += 1
		if d < best_d:
			best_d = d
			best = p
	return [count, best, best_d]


func burning_count() -> int:
	var n := 0
	for f in _flags:
		if f & (F_VALID | F_BURNING) == (F_VALID | F_BURNING) and not f & F_CONSUMED:
			n += 1
	return n


func burn_times(slots: PackedInt32Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(slots.size())
	for i in slots.size():
		out[i] = _burn[slots[i]] if slots[i] >= 0 and slots[i] < _burn.size() else 0.0
	return out
