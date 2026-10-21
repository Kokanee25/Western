class_name KitProp
extends Structure
## A prop from the prop kit (docs/briefs/prop-lab.md): built from its kit file
## (assets/props/kit/<id>.json, read by PropKit) out of members, as the buildings are, so its legs,
## top and rails break, burn and are carved as a building's timber is, by the same code. Being a
## thing that stands on a floor rather than part of a building, it adds four rules of its own:
##
## - **Its footing:** each foot (a grounded member: a leg, a pedestal's foot) stands on whatever is
##   under it when it's placed (the room's floor boards, the ground). When that's broken, burnt or
##   moved from under a foot, the prop falls with it.
## - **Its balance:** it stands while its weight, and a seated man's, is over its feet (the hull of
##   what's left of them). A leg shot or kicked out of a chair with a man on it puts his weight
##   outside the three that are left, and the chair tips: everything left of it goes loose as one
##   body (the structure's own rubble) and falls, with him on it.
## - **Splitting:** a slender member holed past `splits_below` of its section splits (a ball through
##   a 35 mm chair leg takes a third of it; the wood either side of the hole splits along the grain).
##   The rule reads the shared section measure (StructureMember.section_left).
## - **Blows:** a kick, or a blast that doesn't break it, moves it: loose, it slides or tips as the
##   physics has it; held down by a seated man, it holds unless the blow would slide it out from
##   under him; and the member the blow lands on breaks if its share of the blow is more than the
##   wood can take (TimberTuning: the wood's `toughness`, else `impact_toughness`, by its volume).
##
## A seated man: `sit(man)` puts his weight on the seat member (`extra_load`: the shared load
## checks see him), and he loses his seat (goes limp, falling with what's left of the chair) when
## the chair goes loose, its seat goes, or it's knocked out from under him.

## How often its feet look at what's under them (s); the first look waits for the world to settle.
const CHECK_EVERY := 0.25
const SETTLE_FRAMES := 4
## Below the bottom of a foot, how far down it looks for what it stands on (m).
const FOOT_REACH := 0.03
## A foot's floor counts as gone once it's moved this far (m), as Fittings has it.
const MOVED := 0.05
## A loose prop slower than this after a blow isn't worth making loose (m/s).
const LOOSE_FROM := 0.15
## Wood on a wooden floor (dry, sliding): what a seated man's chair slides against.
const FLOOR_FRICTION := 0.4

var kit_id: StringName
var definition: Dictionary
## Gone loose (tipped, knocked, its floor gone): what's left of it is rubble, moving on its own.
var loose := false
## The man sitting on it (a HumanBody), or null.
var seated: Node3D = null

var _feet := {}  # grounded StructureMember -> [[floor member or null for solid ground, its position]]
var _footed := false
var _frames := 0
var _check_t := 0.0
var _balance_queued := false
var _seat_member: StructureMember
var _seat_point := Vector3.ZERO
var _seat_mass := 0.0


func _ready() -> void:
	if definition.is_empty() and kit_id != &"":
		definition = PropKit.definition(kit_id)
	super._ready()
	if not Events.member_broken.is_connected(_on_member_broken):
		Events.member_broken.connect(_on_member_broken)
		Events.exploded.connect(_on_exploded)


func build() -> void:
	_feet.clear()
	_footed = false
	loose = false
	for spec: Dictionary in PropKit.expand(definition):
		var m := add_member(spec.id, StringName(spec.kind), StringName(spec.get("wood", definition.get("wood", "oak"))),
				PropKit.vec(spec.size), PropKit.vec(spec.at), PropKit.basis_of(spec))
		m.set_meta(&"kit", spec)
		var mi := m.get_child(0) as MeshInstance3D
		var look: String = spec.get("look", definition.get("look", ""))
		if look != "":
			mi.material_override = PropKit.material(look, hash(m.member_id))
		if spec.has("draw"):
			mi.mesh = PropKit.draw_mesh(spec.draw, m)
		for d: Dictionary in spec.get("dress", []):
			var layer := MeshInstance3D.new()
			layer.name = "Dress"
			layer.mesh = PropKit.draw_mesh(d.draw, m)
			layer.material_override = PropKit.material(String(d.get("look", "")), hash(m.member_id))
			mi.add_child(layer)
		m.damaged.connect(_check_split.bind(m))
	var seat: Dictionary = definition.get("seat", {})
	_seat_member = members.get(StringName("%s/%s" % [structure_id, seat.get("member", "")]))
	_seat_point = PropKit.vec(seat.get("at", [0, 0, 0]))


func _physics_step(delta: float) -> void:
	super._physics_step(delta)
	if loose:
		return
	if not _footed:
		_frames += 1
		if _frames >= SETTLE_FRAMES:
			_find_footing()
		return
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	if seated and (not is_instance_valid(seated) or seated.get(&"limp")):
		_clear_seat()
	for m: StructureMember in _feet:
		if not m.broken and not _has_footing(m):
			go_loose()
			return


# --- Drawing: its members' dress layers batched with them ----------------------------------------

var _dress := {}  # Material -> MeshInstance3D drawing the dress layers of the batched members


func _batch_all() -> void:
	super._batch_all()
	_batch_dress()


func _rebuild_dirty_batches() -> void:
	super._rebuild_dirty_batches()
	_batch_dress()


## The dress layers of every member still in a batch, one mesh per material (a batched member's
## own mesh is hidden, its layers with it); a member drawn on its own draws its own.
func _batch_dress() -> void:
	var groups := {}
	for m: StructureMember in _batched:
		if not is_instance_valid(m) or m.get_child_count() == 0:
			continue
		var mi := m.get_child(0) as MeshInstance3D
		for c in mi.get_children():
			if c is MeshInstance3D and c.name.begins_with("Dress"):
				var layer := c as MeshInstance3D
				groups.get_or_add(layer.material_override, []).append([layer.mesh, m.transform * mi.transform * layer.transform])
	for mat: Variant in _dress.keys():
		if not groups.has(mat) and is_instance_valid(_dress[mat]):
			(_dress[mat] as Node).queue_free()
			_dress.erase(mat)
	for mat: Variant in groups:
		var st := SurfaceTool.new()
		for e: Array in groups[mat]:
			st.append_from(e[0], 0, e[1])
		var batch: MeshInstance3D = _dress.get(mat)
		if batch == null or not is_instance_valid(batch):
			batch = MeshInstance3D.new()
			batch.name = "DressBatch"
			batch.material_override = mat
			add_child(batch, false, Node.INTERNAL_MODE_BACK)
			_dress[mat] = batch
		batch.mesh = st.commit()


## How many draw calls its untouched members and their dress take.
func batch_count() -> int:
	return super.batch_count() + _dress.size()


# --- What it stands on ---------------------------------------------------------------------------

## Each foot's floor: what's in a thin box just under it (the room's members, the ground).
func _find_footing() -> void:
	_footed = true
	_feet.clear()
	var space := get_world_3d().direct_space_state
	var own: Array[RID] = []
	for m in get_members():
		own.append(m.get_rid())
	for m in get_members():
		if not m.grounded or m.broken:
			continue
		var bottom := _bottom_corners(m)
		var lo := Vector3(INF, INF, INF)
		var hi := -lo
		for c in bottom:
			lo = lo.min(c)
			hi = hi.max(c)
		var q := PhysicsShapeQueryParameters3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(maxf(hi.x - lo.x, 0.01), FOOT_REACH, maxf(hi.z - lo.z, 0.01))
		q.shape = box
		q.transform = Transform3D(global_basis, global_transform * Vector3((lo.x + hi.x) * 0.5, -FOOT_REACH * 0.5 + 0.002, (lo.z + hi.z) * 0.5))
		q.collision_mask = Layers.WORLD
		q.exclude = own
		var under := []
		for hit in space.intersect_shape(q, 16):
			var c: Object = hit.collider
			if c is StructureMember:
				under.append([c, (c as StructureMember).global_position])
			elif c is StaticBody3D and not c.has_meta(&"oil_lamp"):
				under.append([null, Vector3.ZERO])  # the ground, a fixed floor: never goes
		_feet[m] = under
	# Nothing at all under any foot: it was put down in the air.
	if not _feet.is_empty() and _feet.values().all(func(u: Array) -> bool: return u.is_empty()):
		go_loose()


func _has_footing(m: StructureMember) -> bool:
	var under: Array = _feet.get(m, [])
	if under.is_empty():
		return false
	for e: Array in under:
		var f: Variant = e[0]
		if f == null:
			return true
		if is_instance_valid(f) and not (f as StructureMember).broken and not (f as StructureMember).consumed \
				and (f as StructureMember).global_position.distance_to(e[1]) < MOVED:
			return true
	return false


## The four lowest corners of a member (structure space): its footprint.
static func _bottom_corners(m: StructureMember) -> Array[Vector3]:
	var all: Array[Vector3] = []
	var h := m.size * 0.5
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				all.append(m.transform * Vector3(h.x * sx, h.y * sy, h.z * sz))
	all.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	return all.slice(0, 4)


# --- Balance -------------------------------------------------------------------------------------

func _on_member_broken(id: StringName) -> void:
	if loose or not String(id).begins_with(String(structure_id) + "/") or not members.has(id):
		return
	if _seat_member and id == _seat_member.member_id:
		_unseat()
	if not _balance_queued:
		_balance_queued = true
		_check_balance.call_deferred()


## Mass of what's left standing (kg).
func mass() -> float:
	var kg := 0.0
	for m in get_members():
		if not m.broken:
			kg += m.weight(tuning) / 9.81
	return kg


## Where its weight (and his) comes down (structure space), and how much (N).
func centre_of_weight() -> Vector4:
	var sum := Vector3.ZERO
	var w := 0.0
	for m in get_members():
		if m.broken:
			continue
		var mw := m.weight(tuning)
		sum += m.transform.origin * mw
		w += mw
	if seated and _seat_member and not _seat_member.broken:
		sum += _seat_point * _seat_member.extra_load
		w += _seat_member.extra_load
	return Vector4(sum.x / maxf(w, 1e-6), sum.y / maxf(w, 1e-6), sum.z / maxf(w, 1e-6), w)


## The hull of what's left of its feet (structure space, x and z), anticlockwise.
func footprint() -> PackedVector2Array:
	var pts: Array[Vector2] = []
	for m in get_members():
		if m.grounded and not m.broken and (not _footed or _has_footing(m)):
			for c in _bottom_corners(m):
				pts.append(Vector2(c.x, c.z))
	return PropKit.hull(pts)


## Over its feet, or falling. The structure has already settled (what lost its load path fell).
func _check_balance() -> void:
	_balance_queued = false
	if loose or not is_inside_tree():
		return
	var left := get_members().filter(func(m: StructureMember) -> bool: return not m.broken)
	if left.is_empty():
		loose = true
		_unseat()
		return
	var hull := footprint()
	var c := centre_of_weight()
	# A seated man sways (a few centimetres: breathing, reaching, flinching at the shot): a balance
	# closer to the edge than that doesn't hold him. Wood alone doesn't sway.
	var sway := float(definition.get("seat", {}).get("sway", 0.0)) if seated else 0.0
	if hull.size() < 3 or not PropKit.inside(hull, Vector2(c.x, c.z), sway):
		go_loose()


# --- Going loose ---------------------------------------------------------------------------------

## Everything left of it becomes one moving body (or as many as aren't touching), with
## `velocity`; `impulse` at `at` (world) given on top, as a blow would. A seated man loses his seat.
func go_loose(velocity := Vector3.ZERO, impulse := Vector3.ZERO, at := Vector3.INF) -> Array[RigidBody3D]:
	var made: Array[RigidBody3D] = []
	if loose:
		return made
	loose = true
	var ids: Array[StringName] = []
	for m in get_members():
		if not m.broken:
			ids.append(m.member_id)
	var before := rubble.size()
	if not ids.is_empty():
		_drop(ids)
	for i in range(before, rubble.size()):
		var rb := rubble[i]
		if not is_instance_valid(rb):
			continue
		rb.linear_velocity = velocity
		if impulse != Vector3.ZERO:
			var point := at if at != Vector3.INF else rb.global_position
			rb.apply_impulse(impulse, point - rb.global_position)
			rb.set_meta(&"start_v", velocity + impulse / maxf(rb.mass, 0.1))
		made.append(rb)
	_unseat()
	return made


# --- Splitting -----------------------------------------------------------------------------------

## A slender member holed past its `splits_below` splits where it's weakest.
func _check_split(m: StructureMember) -> void:
	if m.broken or not collapses:
		return
	var spec: Dictionary = m.get_meta(&"kit", {})
	var below := float(spec.get("splits_below", definition.get("splits_below", 0.0)))
	if below <= 0.0:
		return
	if m.section_left(tuning) < below:
		break_member.call_deferred(m)


# --- Blows ---------------------------------------------------------------------------------------

## What the wood of `m` takes before it breaks under a blow (J).
func toughness_of(m: StructureMember) -> float:
	return float(tuning.wood(m.wood).get("toughness", tuning.impact_toughness)) * m.volume()


## A blow (a kick, a stamp, a shove) of `impulse` (N·s, the momentum it brings) at `at` (world) on
## `m`, from something of `blow_mass` kg moving at impulse/blow_mass (a kicking leg, ~8 kg). The
## two meet and move on together (an inelastic knock): the energy lost in it goes into the boot and
## the wood (`blow_wood_share` of it, the kit file's, to the wood); more than the member can take
## and it breaks; else what it struck moves with what's left of the momentum. Returns &"broke",
## &"moved" or &"held".
func take_blow(m: StructureMember, at: Vector3, impulse: Vector3, blow_mass := 8.0) -> StringName:
	if m == null or m.broken or impulse.length() < 1e-4:
		return &"held"
	var load_kg := _seat_mass if seated else 0.0
	var big_m := mass() + load_kg
	var v_in := impulse.length() / blow_mass
	var reduced := blow_mass * big_m / (blow_mass + big_m)
	var lost := 0.5 * reduced * v_in * v_in
	var to_wood := lost * float(definition.get("blow_wood_share", 0.5))
	var result := &"moved"
	if to_wood > toughness_of(m):
		# It breaks; the broken piece goes off at the boot's speed, and the rest of the blow's
		# momentum still goes into what's left (and him on it).
		break_member(m, impulse.normalized() * minf(v_in, 8.0))
		result = &"broke"
		if loose:
			return result
		big_m = mass() + load_kg
	var v := impulse / (blow_mass + big_m)
	if seated:
		# His weight holds it to the floor: does it slide far enough to leave him?
		var slide := v.length() * v.length() / (2.0 * FLOOR_FRICTION * 9.81)
		if slide < float(definition.get("seat", {}).get("hold", 0.05)):
			return result if result == &"broke" else &"held"
	elif v.length() < LOOSE_FROM:
		return result if result == &"broke" else &"held"
	go_loose(Vector3.ZERO, v * mass(), at)
	return result


## A blast that didn't break it pushes it as Blast pushes anything loose (Blast.detonate's rule for
## a rigid body: the impulse at that distance on an area from its mass, through what shields it).
func _on_exploded(at: Vector3, kg: float) -> void:
	if loose or not is_inside_tree():
		return
	await get_tree().physics_frame  # after the blast's own breaking has settled
	if loose or not is_inside_tree():
		return
	var left := get_members().filter(func(m: StructureMember) -> bool: return not m.broken)
	if left.is_empty():
		return
	var centre := global_transform * Vector3(centre_of_weight().x, centre_of_weight().y, centre_of_weight().z)
	var r := maxf(centre.distance_to(at), 0.05)
	if r > Blast.reach(kg):
		return
	var kgs := mass()
	var own: Array[RID] = []
	for m in left:
		own.append((m as StructureMember).get_rid())
	var area := pow(maxf(kgs / 500.0, 1e-5), 2.0 / 3.0)
	var dir := (centre - at).normalized()
	var push := (dir + Vector3.UP * 0.3).normalized() * Blast.impulse(kg, r) * area * Blast.shielding(self, at, centre, own)
	var v := push / maxf(kgs, 0.1)
	if v.length() > Blast.t().max_throw:
		v = v.normalized() * Blast.t().max_throw
	if v.length() < LOOSE_FROM:
		return
	go_loose(v)


# --- A seated man --------------------------------------------------------------------------------

## Sit `man` (a HumanBody) on its seat: his weight (all but what his feet take: the seat's `share`)
## goes on the seat member, where the load checks and its balance see it. False if it has no seat
## or it's taken, loose or broken.
func sit(man: Node3D) -> bool:
	if loose or _seat_member == null or _seat_member.broken or (seated and seated != man):
		return false
	seated = man
	var kg := float(man.get(&"total_mass")) if man.get(&"total_mass") != null else 0.0
	var parts: Variant = man.get(&"parts")
	if kg <= 0.0 and parts is Dictionary:
		for sid: StringName in parts:
			kg += float((parts[sid] as Node).get_meta(&"mass", 0.0))
	if kg <= 0.0:
		kg = 80.0
	_seat_mass = kg * float(definition.get("seat", {}).get("share", 0.75))
	_seat_member.extra_load = _seat_mass * 9.81
	if man.has_signal(&"fell") and not man.is_connected(&"fell", _on_seated_fell):
		man.connect(&"fell", _on_seated_fell)
	settle_soon()
	_check_balance.call_deferred()
	return true


## He gets up (his brain's doing): his weight comes off.
func leave() -> void:
	_clear_seat()


## The seat point in the world (where his weight sits).
func seat_position() -> Vector3:
	return global_transform * _seat_point


func _on_seated_fell(_conscious: bool) -> void:
	_clear_seat()


func _clear_seat() -> void:
	if seated and is_instance_valid(seated) and seated.is_connected(&"fell", _on_seated_fell):
		seated.disconnect(&"fell", _on_seated_fell)
	seated = null
	_seat_mass = 0.0
	if _seat_member and is_instance_valid(_seat_member):
		_seat_member.extra_load = 0.0


## The chair's gone from under him: he goes down with it (limp, as any man who loses his footing;
## conscious, his muscles still hold him a moment).
func _unseat() -> void:
	var man := seated
	_clear_seat()
	if man and is_instance_valid(man) and not man.get(&"limp") and man.has_method(&"go_limp"):
		man.call(&"go_limp")
