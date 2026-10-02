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


func _physics_process(delta: float) -> void:
	_accum += delta
	while _accum >= tuning.tick:
		_accum -= tuning.tick
		step(tuning.tick)
	_fx_accum += delta
	if _fx_accum >= 0.5:
		_fx_accum = 0.0
		_update_fx()
	_flicker(delta)


## Run the fire forward by `dt` seconds.
func step(dt: float) -> void:
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
	var gone: Array[StructureMember] = []
	for m: StructureMember in active.keys():
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
			s.settle()


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
		(m.get_parent() as Structure).settle.call_deferred()


# --- Who's near whom ----------------------------------------------------------------------------

func _rebuild_grid() -> void:
	_grid.clear()
	_grid_age = 0.0
	for s in get_tree().get_nodes_in_group(&"structures"):
		for m: StructureMember in (s as Structure).get_members():
			if m.consumed:
				continue
			var b := m.world_aabb()
			var lo := (b.position / CELL).floor()
			var hi := (b.end / CELL).floor()
			for x in range(int(lo.x), int(hi.x) + 1):
				for y in range(int(lo.y), int(hi.y) + 1):
					for z in range(int(lo.z), int(hi.z) + 1):
						_grid.get_or_add(Vector3i(x, y, z), []).append(m)


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
