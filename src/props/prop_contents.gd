class_name PropContents
extends Node3D
## What a kit prop holds (docs/briefs/prop-lab.md; its kit file's "holds" and "contents"): a
## barrel of whiskey, water or lamp oil. A KitProp with contents makes one of these (KitProp.build)
## and counts its weight as its own (KitProp.mass): a full barrel is ~200 kg, so a kick hardly
## moves it and a blast throws it far less than an empty one.
##
## - **Its level:** the litres in it stand as high as the inside's shape makes them ("holds": from
##   the bottom head's top to the top head's underside, its radius at the heads and at the bulge,
##   a parabola between, as a cask's staves are bent).
## - **Leaks:** a ball through a stave or a head (a through-hole in the member's `holes`) below the
##   level lets the liquid out there: Torricelli's law, the speed sqrt(2 g h) from the head h of
##   liquid above the hole, the flow Cd x A x that speed (A the hole's area, Cd a sharp-edged
##   orifice's 0.61: the jet narrows past the hole, the vena contracta; any fluid mechanics text,
##   e.g. White's Fluid Mechanics on orifice flow). The level falls by what runs out, and the head
##   and the jet with it. A hole above the level doesn't leak (till it's under it: the barrel
##   tipped). A stave broken or burnt out is a slot down the barrel's side: the same law
##   integrated over the slot's height (Q = 2/3 Cd w sqrt(2g) (H1^1.5 - H2^1.5), a slot's or a
##   sharp weir's), so it gushes and slows as the level falls.
## - **What runs out** goes where the jet lands (a parabola off the hole at that speed) and out on
##   the bus every SPILL_EVERY (`Events.liquid_spilled`: the floor's marks take it up). Lamp oil
##   landing in flames catches (FireSystem.spill).
## - **Blown apart** (gone loose in more than one piece, or with a side gone): the lot at once.
##   Gone loose whole (thrown, tipped), the cask is shut: the liquid goes with it, its weight in
##   the body, and the holes leak from where they are now.

const G := 9.81
## A sharp-edged orifice's discharge coefficient (see above).
const DISCHARGE := 0.61
## How often what's run out goes out on the bus (s).
const SPILL_EVERY := 0.5
## The jets are redrawn every few physics frames.
const DRAW_EVERY := 3
## Under this much head (m) a hole only dribbles down the wood: no jet drawn off it.
const DRIBBLE := 0.004
## kg a litre: water; whiskey at 40% alcohol (~0.95); lamp oil (kerosene, 0.78-0.81).
const DENSITY := {&"water": 1.0, &"whiskey": 0.95, &"lamp_oil": 0.8}
## How each looks running (and its alpha).
const COLOURS := {&"water": Color(0.62, 0.68, 0.7, 0.55), &"whiskey": Color(0.62, 0.36, 0.1, 0.8),
		&"lamp_oil": Color(0.78, 0.7, 0.42, 0.7)}

var prop: KitProp
var liquid: StringName = &"water"
var litres := 0.0
var capacity := 0.0
var flammable := false
var colour := Color(0.62, 0.68, 0.7, 0.55)
## Every opening below which it runs: {member, at (prop space), out (prop space, the jet's way),
## area (m²)} for a hole, or {member, slot: [y0, y1], width} for a side gone. Kept while dry.
var leaks: Array[Dictionary] = []
## All it's let go, litres (on the bus and at once).
var spilled := 0.0
## It's gone at once (blown apart).
var released := false

var _from := 0.05
var _to := 0.85
var _r_end := 0.232
var _r_mid := 0.272
var _below := PackedFloat32Array()  # litres under each step of the inside's height
const STEPS := 64
var _seen := {}  # StructureMember -> how many of its holes have been looked at
var _body: RigidBody3D  # gone loose whole: the body it's in
var _body_from := Transform3D.IDENTITY  # the prop's space -> the body's, when it went
var _body_kg := 0.0  # the body's own mass, without what's in it
var _in_body := false
var _pieces := 0  # how many bodies the prop was in when it went loose whole
var _acc: Array[float] = []  # litres run out of each leak since it last went on the bus
var _land: Array[Vector3] = []  # where each leak's jet lands (world)
var _spill_t := 0.0
var _frames := 0
var _jets: MeshInstance3D
var _rid_cache: Array[RID] = []


## A prop's contents from its kit file ("holds", "contents"), or null when it holds nothing.
static func make(p: KitProp) -> PropContents:
	var holds: Dictionary = p.definition.get("holds", {})
	var c: Dictionary = p.definition.get("contents", {})
	if holds.is_empty() or c.is_empty():
		return null
	var pc := PropContents.new()
	pc.name = "Contents"
	pc.prop = p
	pc._from = float(holds.get("from", 0.05))
	pc._to = float(holds.get("to", 0.85))
	var r: Array = holds.get("radius", [0.232, 0.272])
	pc._r_end = float(r[0])
	pc._r_mid = float(r[1] if r.size() > 1 else r[0])
	pc._tabulate()
	pc.liquid = StringName(c.get("liquid", "water"))
	pc.litres = pc.capacity if c.get("full", false) else minf(float(c.get("litres", 0.0)), pc.capacity)
	pc.flammable = bool(c.get("flammable", pc.liquid == &"lamp_oil"))
	pc.colour = COLOURS.get(pc.liquid, pc.colour)
	var col: Array = c.get("colour", [])
	if col.size() >= 3:
		pc.colour = Color(float(col[0]), float(col[1]), float(col[2]), float(col[3]) if col.size() > 3 else pc.colour.a)
	return pc


func _ready() -> void:
	set_physics_process(false)  # nothing to do till it leaks
	for m in prop.get_members():
		m.damaged.connect(_on_damaged.bind(m))
	Events.member_broken.connect(_on_member_broken)


# --- Its level -----------------------------------------------------------------------------------

## The inside's radius at `y` (prop space): the heads' at either end, the bulge's in the middle.
func radius_at(y: float) -> float:
	var half := (_to - _from) * 0.5
	var u := clampf((y - (_from + half)) / maxf(half, 1e-4), -1.0, 1.0)
	return _r_mid - (_r_mid - _r_end) * u * u


func _tabulate() -> void:
	_below.resize(STEPS + 1)
	_below[0] = 0.0
	var dy := (_to - _from) / STEPS
	for i in STEPS:
		var r := radius_at(_from + (i + 0.5) * dy)
		_below[i + 1] = _below[i] + PI * r * r * dy * 1000.0
	capacity = _below[STEPS]


## How high `l` litres stand in it (prop space, upright).
func level_of(l: float) -> float:
	if l <= 0.0:
		return _from
	if l >= capacity:
		return _to
	var dy := (_to - _from) / STEPS
	for i in STEPS:
		if _below[i + 1] >= l:
			return _from + (i + (l - _below[i]) / maxf(_below[i + 1] - _below[i], 1e-6)) * dy
	return _to


## The level now (prop space, as it stands).
func level() -> float:
	return level_of(litres)


## What it weighs (kg).
func kg() -> float:
	return litres * float(DENSITY.get(liquid, 1.0))


## Where its weight comes down (prop space): half way up what's in it.
func centre() -> Vector3:
	return Vector3(0.0, (_from + level()) * 0.5, 0.0)


# --- Openings ------------------------------------------------------------------------------------

func _on_damaged(m: StructureMember) -> void:
	if released or not is_instance_valid(m):
		return
	var n: int = _seen.get(m, 0)
	_seen[m] = m.holes.size()
	var t := StructureMember.voxel_damage_tuning()
	var scale := t.channel_scale if t else 1.0
	for i in range(n, m.holes.size()):
		var h: Dictionary = m.holes[i]
		if not h.get("through", false):
			continue  # a ball stopped in the wood (the far stave, from inside): no way out
		var a: Vector3 = m.transform * (h.entry as Vector3)
		var b: Vector3 = m.transform * (h.exit as Vector3)
		var mid := Vector3(0.0, (_from + _to) * 0.5, 0.0)
		var outer := a if a.distance_to(mid) > b.distance_to(mid) else b
		var inner := b if outer == a else a
		var out := (outer - inner).normalized()
		if absf(m.axis().y) > 0.7:
			out = Vector3(outer.x, 0.0, outer.z).normalized()  # a stave: square off its face
		var r := float(h.get("radius", 0.005)) * scale
		_add_leak({"member": m, "at": outer, "out": out, "area": PI * r * r})


func _on_member_broken(id: StringName) -> void:
	# (Going loose, every member's dropped as rubble: that's on_loose's to judge, not a side gone.)
	if released or prop == null or prop.loose or not prop.members.has(id):
		return
	_side_gone(prop.get_member(id))


## A member broken or burnt out of it: a stave a slot down the side, a head board an opening as big.
func _side_gone(m: StructureMember) -> void:
	if m == null or leaks.any(func(l: Dictionary) -> bool: return l.member == m and l.has("slot")):
		return
	var box := m.structure_aabb()
	if absf(m.axis().y) > 0.7:
		var c := box.get_center()
		_add_leak({"member": m, "slot": [maxf(box.position.y, _from), minf(box.end.y, _to)], "width": m.size.x,
				"at": Vector3(c.x, _from, c.z), "out": Vector3(c.x, 0.0, c.z).normalized()})
	else:
		var y := clampf(box.get_center().y, _from, _to)
		_add_leak({"member": m, "at": Vector3(box.get_center().x, y, box.get_center().z), "out": Vector3.DOWN if y < 0.5 * (_from + _to) else Vector3.UP,
				"area": m.size.x * m.size.z, "slot_area": true})


func _add_leak(l: Dictionary) -> void:
	leaks.append(l)
	_acc.append(0.0)
	_land.append(Vector3.INF)
	set_physics_process(true)


# --- Running out ---------------------------------------------------------------------------------

## litres a second out of `l` now.
func flow(l: Dictionary) -> float:
	if litres <= 0.0:
		return 0.0
	if l.has("slot"):
		var s := _surface_prop()
		var y0: float = l.slot[0]
		var y1: float = l.slot[1]
		if s <= y0:
			return 0.0
		var top := pow(s - y0, 1.5) - pow(maxf(s - y1, 0.0), 1.5)
		return 2.0 / 3.0 * DISCHARGE * float(l.width) * sqrt(2.0 * G) * top * 1000.0
	var h := head(l)
	if h <= 0.0:
		return 0.0
	return DISCHARGE * float(l.area) * sqrt(2.0 * G * h) * 1000.0


## The head of liquid over a leak's opening (m), wherever it is now.
func head(l: Dictionary) -> float:
	if not _in_body:
		return level() - float((l.at as Vector3).y)
	return _surface_world() - (_to_world(l.at) as Vector3).y


## The jet's speed off a leak (m/s).
func jet_speed(l: Dictionary) -> float:
	if l.has("slot"):
		return sqrt(2.0 * G * maxf(_surface_prop() - float(l.slot[0]), 0.0) * 0.5)  # the slot's mean
	return sqrt(2.0 * G * maxf(head(l), 0.0))


func _surface_prop() -> float:
	return level() if not _in_body else (prop.global_transform.affine_inverse() * Vector3(0.0, _surface_world(), 0.0)).y


## The liquid's top (world y) in the cask gone loose: its inside taken as a cylinder of the mean
## radius, filled to its share of the height it stands across now (exact upright, near enough on
## its side).
func _surface_world() -> float:
	var t := _transform()
	var half := (_to - _from) * 0.5
	var c := t * Vector3(0.0, _from + half, 0.0)
	var a := t.basis.y.normalized()
	var r := (_r_end + _r_mid) * 0.5
	var e := half * absf(a.y) + r * sqrt(maxf(1.0 - a.y * a.y, 0.0))
	return c.y - e + 2.0 * e * clampf(litres / maxf(capacity, 1e-6), 0.0, 1.0)


## The prop's space to the world, standing or gone loose in its body.
func _transform() -> Transform3D:
	if _in_body and is_instance_valid(_body):
		return _body.global_transform * _body_from
	return prop.global_transform


func _to_world(p: Vector3) -> Vector3:
	return _transform() * p


func _physics_process(delta: float) -> void:
	if released or litres <= 0.0:
		if _jets:
			_jets.visible = false
		set_physics_process(false)
		_flush()
		return
	if prop.loose and not _in_body:
		release()
		return
	if _in_body and (not is_instance_valid(_body) or _burst()):
		release()
		return
	var out := 0.0
	for i in leaks.size():
		var q := flow(leaks[i]) * delta
		_acc[i] += q
		out += q
	if out > litres:
		var k := litres / out
		for i in leaks.size():
			_acc[i] *= k
		out = litres
	litres -= out
	spilled += out
	if _in_body:
		_body.mass = maxf(_body_kg + kg(), 0.1)
	_spill_t -= delta
	if _spill_t <= 0.0:
		_spill_t = SPILL_EVERY
		_flush()
	_frames += 1
	if _frames % DRAW_EVERY == 0:
		_draw_jets()


## Where a leak's jet comes down (world): off the opening at its speed, falling to what's under it.
func landing(l: Dictionary) -> Vector3:
	var t := _transform()
	var p := t * (l.at as Vector3)
	var dir := (t.basis * (l.out as Vector3)).normalized()
	var v := dir * jet_speed(l)
	var floor_y := _floor_under(p)
	var drop := maxf(p.y - floor_y, 0.0)
	var time := (v.y + sqrt(v.y * v.y + 2.0 * G * drop)) / G
	var at := p + Vector3(v.x, 0.0, v.z) * time
	at.y = _floor_under(at + Vector3.UP * 0.3) if drop > 0.0 else p.y
	return at


func _floor_under(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.01, p + Vector3.DOWN * 4.0, Layers.WORLD, _own())
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return (hit.position as Vector3).y if not hit.is_empty() else p.y - 1.0


func _own() -> Array[RID]:
	if _rid_cache.is_empty():
		for m in prop.get_members():
			if not m.broken:
				_rid_cache.append(m.get_rid())
		if _in_body and is_instance_valid(_body):
			_rid_cache.append(_body.get_rid())
	return _rid_cache


## What's run out of each leak since the last time, on the bus where it landed.
func _flush() -> void:
	for i in leaks.size():
		if _acc[i] <= 0.0005:
			continue
		var at := landing(leaks[i])
		if _land[i] == Vector3.INF:
			Events.noise.emit(at, 0.3, &"splash", prop)
		_land[i] = at
		Events.liquid_spilled.emit(at, liquid, _acc[i], prop)
		_acc[i] = 0.0
		_into_flames(at)


## Lamp oil landing in flames catches (as a lamp's does), once at a place while it burns there.
func _into_flames(at: Vector3) -> void:
	if not flammable:
		return
	var fire := FireSystem.find(get_tree())
	if fire == null or int(fire.fire_near(at, 0.6).count) == 0:
		return
	for s: Dictionary in fire.spills:
		if (s.position as Vector3).distance_to(at) < float(s.radius):
			return
	fire.spill(at)


## Blown apart: the lot at once, round where it stood.
func release() -> void:
	if released:
		return
	released = true
	set_physics_process(false)
	if _in_body and is_instance_valid(_body):
		_body.mass = maxf(_body_kg, 0.1)  # (what's left of the cask, empty)
	if _jets:
		_jets.visible = false
	_flush()
	if litres <= 0.0:
		return
	var at := _transform() * Vector3(0.0, _from, 0.0)
	var floor_at := Vector3(at.x, _floor_under(at + Vector3.UP * 0.2), at.z)
	ImpactEffects.burst(get_parent() if get_parent() else self, floor_at + Vector3.UP * 0.1, Vector3.UP, Color(colour, 1.0), 40, 2.6, 0.04)
	Events.noise.emit(floor_at, 20.0, &"splash", prop)
	# Round where it stood (a barrel's worth runs a couple of metres across the boards).
	var ring := [Vector3.ZERO, Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, -0.5)]
	for d: Vector3 in ring:
		Events.liquid_spilled.emit(floor_at + d, liquid, litres / ring.size(), prop)
	_into_flames(floor_at)
	spilled += litres
	litres = 0.0


## The prop's gone loose: in one piece with its sides whole, the cask's shut and goes with it (its
## weight in that body); else it's blown apart and the lot goes.
func on_loose(bodies: Array[RigidBody3D]) -> void:
	_rid_cache.clear()
	if released or litres <= 0.0:
		return
	var sides_gone := leaks.any(func(l: Dictionary) -> bool: return l.has("slot") or l.has("slot_area"))
	var whole := bodies.filter(func(b: RigidBody3D) -> bool: return is_instance_valid(b) and b.mass > 1.0)
	if sides_gone or whole.size() != 1:
		release()
		return
	_body = whole[0]
	_in_body = true
	_body_from = _body.global_transform.affine_inverse() * prop.global_transform
	_body_kg = _body.mass
	_body.mass = _body_kg + kg()
	_pieces = _bodies()
	set_physics_process(true)  # (watching it land: it may come apart)


## The cask's come apart as it landed (its rubble broken up into more bodies): it's open.
func _burst() -> bool:
	return _bodies() > _pieces


func _bodies() -> int:
	return prop.rubble.filter(func(rb: Variant) -> bool: return is_instance_valid(rb) and (rb as RigidBody3D).mass > 1.0).size()


# --- The jets ------------------------------------------------------------------------------------

func _draw_jets() -> void:
	if _jets == null:
		_jets = MeshInstance3D.new()
		_jets.name = "Jets"
		_jets.top_level = true
		_jets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_jets.mesh = ImmediateMesh.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colour
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if colour.a < 0.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.2
		_jets.material_override = mat
		add_child(_jets)
		_jets.global_transform = Transform3D.IDENTITY
	var im := _jets.mesh as ImmediateMesh
	im.clear_surfaces()
	var any := false
	var t := _transform()
	for l in leaks:
		if flow(l) <= 0.0 or head_or_slot(l) < DRIBBLE:
			continue
		var p := t * (l.at as Vector3)
		var dir := (t.basis * (l.out as Vector3)).normalized()
		var v := dir * jet_speed(l)
		var land := landing(l)
		var drop := maxf(p.y - land.y, 0.0)
		var time := (v.y + sqrt(v.y * v.y + 2.0 * G * drop)) / G
		var w := float(l.width) if l.has("slot") else maxf(sqrt(float(l.area)) * 1.1, 0.012)
		if not any:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			any = true
		_ribbon(im, p, v, time, w, dir)
	if any:
		im.surface_end()
	_jets.visible = any


func head_or_slot(l: Dictionary) -> float:
	return _surface_prop() - float(l.slot[0]) if l.has("slot") else head(l)


## A falling stream as two crossed strips along its arc (seen from any side), `w` across.
func _ribbon(im: ImmediateMesh, p: Vector3, v: Vector3, time: float, w: float, dir: Vector3) -> void:
	const N := 8
	var side := dir.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	var pts: Array[Vector3] = []
	for i in N + 1:
		var s := time * i / N
		pts.append(p + v * s + Vector3.DOWN * 0.5 * G * s * s)
	for i in N:
		var a := pts[i]
		var b := pts[i + 1]
		var along := (b - a).normalized()
		var up := along.cross(side).normalized()
		# Wider as it falls and breaks up.
		var wa := w * (1.0 + 0.6 * i / N) * 0.5
		var wb := w * (1.0 + 0.6 * (i + 1) / N) * 0.5
		for off: Vector3 in [side, up]:
			im.surface_add_vertex(a - off * wa)
			im.surface_add_vertex(a + off * wa)
			im.surface_add_vertex(b + off * wb)
			im.surface_add_vertex(a - off * wa)
			im.surface_add_vertex(b + off * wb)
			im.surface_add_vertex(b - off * wb)
