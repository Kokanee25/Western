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
## A nail's reach into the wall behind a hung prop (m): through the panelling into a stud, or
## where the panels leave a gap (the saloon's, either side of its door), the siding behind.
const WALL_REACH := 0.15
## Put down, it settles onto what's under it up to SET_DOWN below its feet (or SET_LIFT into it).
const SET_DOWN := 0.2
const SET_LIFT := 0.08
## A foot's floor counts as gone once it's moved this far (m), as Fittings has it.
const MOVED := 0.05
## Slower than this after a blow or a blast it hardly moves (it'd slide under 2 cm on the floor,
## sqrt(2 x FLOOR_FRICTION x g x 0.02)): it stays where it stands, a fixed thing (m/s).
const LOOSE_FROM := 0.4
## Wood on a wooden floor (dry, sliding): what a seated man's chair slides against.
const FLOOR_FRICTION := 0.4

var kit_id: StringName
## Which of its kind it is (PropKit.spawn's count): picks a painting's picture, as the drawn ones.
var variant := 0
var definition: Dictionary
## Gone loose (tipped, knocked, its floor gone): what's left of it is rubble, moving on its own.
var loose := false
## It's gone loose (tipped, knocked, its floor gone): what stands on it goes with it (GlassProp).
signal went_loose
## The man sitting on it (a HumanBody), or null.
var seated: Node3D = null
## What it holds (its kit file's "holds" and "contents": a barrel's whiskey), or null.
var contents: PropContents

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
	if contents == null:
		contents = PropContents.make(self)
		if contents:
			add_child(contents)
	# One listener for every prop's breaks (#538: ~110 props each hearing each of a stick's ~600
	# breaks was ~0.15 ms a break): by the structure id the member's id starts with.
	var mine: Array = _by_structure.get_or_add(structure_id, [])
	if not mine.has(self):
		mine.append(self)
	if not Events.member_broken.is_connected(_any_member_broken):
		Events.member_broken.connect(_any_member_broken)
	if not Events.exploded.is_connected(_on_exploded):
		Events.exploded.connect(_on_exploded)


## Every kit prop by its structure id (KitProp ids have no "/": "chair_3").
static var _by_structure := {}


static func _any_member_broken(id: StringName) -> void:
	var props: Variant = _by_structure.get(StringName(String(id).get_slice("/", 0)))
	if props == null:
		return
	for p: Variant in (props as Array).duplicate():
		if is_instance_valid(p):
			(p as KitProp)._on_member_broken(id)
		else:
			(props as Array).erase(p)


func build() -> void:
	_feet.clear()
	_footed = false
	loose = false
	for spec: Dictionary in PropKit.expand(definition):
		var m := add_member(spec.id, StringName(spec.kind), StringName(spec.get("wood", definition.get("wood", "oak"))),
				PropKit.vec(spec.size), PropKit.vec(spec.at), PropKit.basis_of(spec))
		m.set_meta(&"kit", spec)
		var mi := m.get_child(0) as MeshInstance3D
		var own_look: String = spec.get("look", definition.get("look", ""))
		PropKit.dress_member(m, spec.get("draw", {}), own_look)
		if own_look == "prop:picture":
			mi.material_override = PropModels.picture(variant)
		# Its dress, one layer a look (a barrel stave's four hoops are one mesh), each its own name
		# (two "Dress" children: Godot renames the second, unreadably).
		var looks := {}
		for d: Dictionary in spec.get("dress", []):
			looks.get_or_add(String(d.get("look", "")), []).append(PropKit.draw_mesh(d.draw, m))
		for look: String in looks:
			var layer := MeshInstance3D.new()
			layer.name = "Dress%d" % mi.get_child_count()
			var st := SurfaceTool.new()
			for mesh: Mesh in looks[look]:
				st.append_from(mesh, 0, Transform3D.IDENTITY)
			layer.mesh = st.commit()
			# A "wood:" look's first strip for every layer, as dress_member gives members: one batch a look.
			layer.material_override = PropKit.material(look, 0 if look.begins_with("wood:") else hash(m.member_id))
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
			if _footed and not loose:
				_join_batch()
		return
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	if seated and (not is_instance_valid(seated) or seated.get(&"limp")):
		_clear_seat()
	# Hung: it holds while any nail's still in something (its board burnt through, shot out or
	# carried off with the wall, the last nail lets go).
	if hung():
		if not _feet.keys().any(func(m: StructureMember) -> bool: return not m.broken and _has_footing(m)):
			go_loose()
		return
	# A foot with nothing under it (its board gone, or over a boardwalk's edge or a gap between its
	# boards as it was put down) isn't a foot: it stands if its weight's over the feet that are left.
	for m: StructureMember in _feet:
		if not m.broken and not _has_footing(m):
			_check_balance()
			return


# --- Joints: what each member is fixed to at either end -----------------------------------------

var _ends := {}  # StructureMember -> [ids joined at its one end, ids at its other]
var _put_down := false  # settled onto its floor (_set_down), once
var _nailed := {}  # StructureMember -> [nail points through it (prop space)]: a hung prop's


func infer_supports() -> void:
	super.infer_supports()
	# Hung on nails (a picture, a mount): what the nails go through is held as if it stood on the
	# ground, and everything else hangs from it.
	_nailed.clear()
	for nail: Variant in definition.get("hangs", {}).get("nails", []):
		var p := PropKit.vec(nail)
		for m in get_members():
			if m.structure_aabb().grow(0.01).has_point(p):
				m.grounded = true
				_nailed.get_or_add(m, []).append(p)
	_ends.clear()
	for m in get_members():
		var a: Array[StringName] = []
		var b: Array[StringName] = []
		var half := m.length() * 0.5
		for id in m.touching:
			var o := get_member(id)
			# Which end: where the other's middle lies along this one (a stretcher's legs, a rail's
			# posts, a spindle's seat and crest).
			var t := (o.transform.origin - m.transform.origin).dot(m.axis())
			if t < -half * 0.5:
				a.append(id)
			elif t > half * 0.5:
				b.append(id)
		if not a.is_empty() and not b.is_empty():
			_ends[m] = [a, b]


## Members fixed at both ends that have lost what held one of them: they hang from the other.
func _hanging() -> Array[StructureMember]:
	var out: Array[StructureMember] = []
	for m: StructureMember in _ends:
		if m.broken or m.grounded:
			continue
		var gone := func(ids: Array) -> bool: return ids.all(func(id: StringName) -> bool: return get_member(id).broken)
		var e: Array = _ends[m]
		if gone.call(e[0]) != gone.call(e[1]):
			out.append(m)
	return out


## Going over, the prop comes down on the free ends of what hangs (a stretcher whose leg's gone,
## a skid under it): each is held only at its joint, which takes BodyImpacts.nailed_moment before it
## tears out; the weight on its free end (half the prop's, and the seated man's) over its length is
## far more for a chair's rails. Those tear out and fall on their own.
func _tear_hanging() -> void:
	var w := mass() * 9.81 + (_seat_member.extra_load if _seat_member and seated else 0.0)
	for m in _hanging():
		if 0.5 * w * m.length() > BodyImpacts.nailed_moment(tuning, m):
			var one: Array[StringName] = [m.member_id]
			_drop(one)


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
		if not is_instance_valid(m) or (m.get_child_count() == 0 and not m.resting()):
			continue
		var mi := m.drawn_node()
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


## Its own batch meshes (members, dress, the far-lamps' shadow): what PropBatch joins.
func batch_nodes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for d: Dictionary in [_batches, _dress]:
		for mi: Variant in d.values():
			if is_instance_valid(mi):
				out.append(mi)
	if _shadow and is_instance_valid(_shadow):
		out.append(_shadow)
	return out


# --- Drawn with its neighbours at rest (PropBatch) -----------------------------------------------

var _prop_batch: PropBatch


func _join_batch() -> void:
	if _prop_batch == null or not is_instance_valid(_prop_batch):
		_prop_batch = PropBatch.for_prop(self)
	if _prop_batch:
		_prop_batch.join(self)
		set_notify_transform(true)


func _leave_batch() -> void:
	if _prop_batch and is_instance_valid(_prop_batch) and _prop_batch.has(self):
		_prop_batch.leave(self)


## In a PropBatch: anything happening to a member, or to it (moved, hidden), and it draws itself.
func unbatch(m: StructureMember, soon := false) -> void:
	_leave_batch()
	super.unbatch(m, soon)


## Heated or charred: drawn by its own batches, which carry the char (Structure.show_fire).
func show_fire(m: StructureMember, char_amount: float, glow: float) -> void:
	_leave_batch()
	super.show_fire(m, char_amount, glow)


func rebuild() -> void:
	_leave_batch()
	super.rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_VISIBILITY_CHANGED:
		_leave_batch()


# --- What it stands on ---------------------------------------------------------------------------

## Each foot's floor: what's in a thin box just under it (the room's members, the ground).
func _find_footing() -> void:
	var space := World.space(self)
	var own: Array[RID] = []
	for m in get_members():
		own.append(m.get_rid())
	if hung():
		_find_nails(space, own)
		return
	# Settled onto its floor once, as it was put down (looking again after the ground's dug, it
	# doesn't sink into the hole: a foot over it has lost its footing).
	if not _put_down:
		if not _set_down(space, own):
			return  # what it stands on is a kit prop still settling itself: next frame
		_put_down = true
	_footed = true
	_feet.clear()
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


## Hung on nails (its file's "hangs"), not stood on feet.
func hung() -> bool:
	return definition.has("hangs")


## What each nail goes into behind it (the wall's boards and studs, up to WALL_REACH back): its
## "feet". Nothing behind any nail: it was hung on air, and falls.
func _find_nails(space: PhysicsDirectSpaceState3D, own: Array[RID]) -> void:
	_footed = true
	_feet.clear()
	for m: StructureMember in _nailed:
		var into := []
		for p: Vector3 in _nailed[m]:
			var q := PhysicsShapeQueryParameters3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(0.03, 0.03, WALL_REACH)
			q.shape = box
			q.transform = Transform3D(global_basis, global_transform * Vector3(p.x, p.y, -WALL_REACH * 0.5 + 0.005))
			q.collision_mask = Layers.WORLD
			q.exclude = own
			for hit in space.intersect_shape(q, 8):
				var c: Object = hit.collider
				if c is StructureMember:
					into.append([c, (c as StructureMember).global_position])
				elif c is StaticBody3D and not c.has_meta(&"oil_lamp"):
					into.append([null, Vector3.ZERO])
		_feet[m] = into
	if _feet.values().all(func(u: Array) -> bool: return u.is_empty()):
		go_loose()


## Down onto what's under its feet, or up out of it, as it would settle (a placement is a few
## centimetres out: a boardwalk's top, a crate stacked on another), up to SET_DOWN. False while
## what it would stand on is another kit prop that hasn't settled yet (a stack settles bottom up).
func _set_down(space: PhysicsDirectSpaceState3D, own: Array[RID]) -> bool:
	var drop := INF
	for m in get_members():
		if not m.grounded or m.broken:
			continue
		var c := Vector3.ZERO
		for p in _bottom_corners(m):
			c += p * 0.25
		var from := global_transform * (c + Vector3(0, SET_LIFT, 0))
		var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -SET_LIFT - SET_DOWN, 0), Layers.WORLD, own)
		var hit := space.intersect_ray(q)
		if hit.is_empty() or hit.collider.has_meta(&"oil_lamp"):
			continue
		if hit.collider is StructureMember:
			var under := (hit.collider as Node).get_parent()
			if under is KitProp and under != self and not (under as KitProp)._footed and not (under as KitProp).loose:
				return false
		drop = minf(drop, from.y - SET_LIFT - (hit.position as Vector3).y)
	if drop != INF and absf(drop) > 0.002:
		global_position.y -= drop
		Sight.changed(self, true)  # its members moved with it (the server has them next frame)
	return true


## The ground near it was dug (Ground): its feet look again for what's under them (a foot left over
## a hole has lost its footing, and it goes loose). Its own rule in place of a building's.
func _on_ground_changed(area: Rect2) -> void:
	if loose or not _footed or not is_inside_tree():
		return
	if area.grow(0.5).has_point(Vector2(global_position.x, global_position.z)):
		_footed = false
		_frames = SETTLE_FRAMES - 1


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
	# (Every prop hears every break: the cheap test first.)
	if loose or not members.has(id) or not String(id).begins_with(String(structure_id) + "/"):
		return
	if _seat_member and id == _seat_member.member_id:
		_unseat()
	if not _balance_queued:
		_balance_queued = true
		_check_balance.call_deferred()


## Mass of what's left standing and what's in it (kg).
func mass() -> float:
	var kg := contents.kg() if contents else 0.0
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
	if contents and not contents.released:
		sum += contents.centre() * contents.kg() * 9.81
		w += contents.kg() * 9.81
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
	var t := Prof.start()
	_balance_now()
	Prof.stop(&"kit_balance", t)


func _balance_now() -> void:
	var left := get_members().filter(func(m: StructureMember) -> bool: return not m.broken)
	if left.is_empty():
		loose = true
		_unseat()
		if contents:
			contents.release()
		return
	if hung():
		return  # it hangs from its nails (whatever's left on them: _physics_step)
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
	_tear_hanging()
	loose = true
	var ids: Array[StringName] = []
	for m in get_members():
		if not m.broken:
			ids.append(m.member_id)
	var before := rubble.size()
	if not ids.is_empty():
		_drop(ids)
	for i in range(before, rubble.size()):
		if is_instance_valid(rubble[i]):
			made.append(rubble[i])
	# What it holds goes into its body first (its weight with it), so a blow moves the two of them;
	# let go instead (a side out), the blow, reckoned with it in, moves only what's left.
	if contents:
		var with_it := mass()
		contents.on_loose(made)
		if contents.released and impulse != Vector3.ZERO:
			impulse *= _mass_of(made) / maxf(with_it, 0.1)
	for rb in made:
		rb.linear_velocity = velocity
		if impulse != Vector3.ZERO:
			var point := at if at != Vector3.INF else rb.global_position
			rb.apply_impulse(impulse, point - rb.global_position)
	went_loose.emit()
	_drop_fittings(made)
	_unseat()
	return made


static func _mass_of(bodies: Array[RigidBody3D]) -> float:
	var kg := 0.0
	for rb in bodies:
		if is_instance_valid(rb):
			kg += rb.mass
	return kg


## What stood on it alone (a lamp, a bottle: Fittings' items) comes down with it now, not at
## Fittings' next look: left there a moment, it's a fixed thing the table rises into.
func _drop_fittings(bodies: Array[RigidBody3D]) -> void:
	var f := get_tree().get_first_node_in_group(&"fittings") as Fittings
	if f == null:
		return
	# Only what its own members hold (Fittings' index, in its order) can be all its.
	for item: Dictionary in f.items_on_any(get_members()):
		if item.down or (item.members as Array).is_empty():
			continue
		var mine := (item.members as Array).all(func(e: Array) -> bool:
				return is_instance_valid(e[0]) and members.has((e[0] as StructureMember).member_id))
		if mine and (item.on as Array).all(func(o: Dictionary) -> bool: return o.down):
			f.call(&"drop", item)
			# A lamp's hitbox stays a fixed body inside its fallen lamp (Fittings): what's left of the
			# prop mustn't meet it as an immovable box.
			for b: Variant in item.get("bodies", []):
				# (Valid first: `is` on a freed body is an error, and a smashed lamp's may be gone.)
				if is_instance_valid(b) and b is StaticBody3D:
					for rb in bodies:
						if is_instance_valid(rb):
							rb.add_collision_exception_with(b)


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

## What the wood of `m` takes before it breaks under a blow (J): its toughness over the stretch of
## it that bends, its kit spec's `blow_span` (a leg's length below the seat: the back posts run up
## past the seat, and the back above it doesn't take a kick at the foot), else all of it.
func toughness_of(m: StructureMember) -> float:
	var spec: Dictionary = m.get_meta(&"kit", {})
	var span := minf(float(spec.get("blow_span", m.length())), m.length())
	var cs := m.cross_section()
	return float(tuning.wood(m.wood).get("toughness", tuning.impact_toughness)) * cs.x * cs.y * span


## A blow (a kick, a stamp, a shove) of `impulse` (N·s, the momentum it brings) at `at` (world) on
## `m`, from something of `blow_mass` kg moving at impulse/blow_mass (a kicking leg, ~8 kg). The
## two meet and move on together (an inelastic knock): the energy lost in it goes into the boot and
## the wood (`blow_wood_share` of it, the kit file's, to the wood); more than the member can take
## and it breaks, and the boot goes on into the next member in its way with what's left; else what
## it struck moves with what's left of the momentum. Returns &"broke",
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
		# The boot goes on through with what breaking it didn't take (the wood's toughness, its share
		# of the energy lost), into the next member in its way (a sweep along a chair's back legs).
		var left_j := 0.5 * blow_mass * v_in * v_in - toughness_of(m) / maxf(float(definition.get("blow_wood_share", 0.5)), 0.05)
		var next := _next_in_line(at, impulse.normalized(), m)
		if left_j > 0.0 and next.size() == 2:
			take_blow(next[0], next[1], impulse.normalized() * sqrt(2.0 * left_j / blow_mass) * blow_mass, blow_mass)
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


## The next of its standing members a blow going `dir` from `at` meets (within its size), and where:
## [member, point], or [] (what it broke is rubble now, and left out).
func _next_in_line(at: Vector3, dir: Vector3, after: StructureMember) -> Array:
	var space := World.space(self)
	var reach := PropKit.bounds(definition).size.length()
	var q := PhysicsRayQueryParameters3D.create(at, at + dir * reach, Layers.WORLD)
	var skip: Array[RID] = [after.get_rid()]
	for rb in rubble:
		if is_instance_valid(rb):
			skip.append((rb as RigidBody3D).get_rid())
	for i in 4:
		q.exclude = skip
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return []
		var c: Object = hit.collider
		if c is StructureMember and members.has((c as StructureMember).member_id) and not (c as StructureMember).broken:
			return [c, hit.position]
		if not (c is CollisionObject3D):
			return []
		skip.append((c as CollisionObject3D).get_rid())
	return []


## A blast that didn't break it throws what's left: each member pushed by the blast on the face it
## turns to the charge (Blast.face_impulse: the reflected impulse over that face, as Blast breaks
## members by), at that member, away from the charge, less what the prop's own members in between
## take (Blast.shielding). A table's top catches it underneath and goes over; a chair goes flying.
func _on_exploded(at: Vector3, kg: float) -> void:
	if loose or not is_inside_tree():
		return
	await get_tree().physics_frame  # after the blast's own breaking has settled
	# (Every prop in the town hears every blast: out of reach, done. This runs as `physics_frame`
	# is emitted, before any system's tick, so it's timed here: `kit_blast`.)
	if loose or not is_inside_tree() or global_position.distance_to(at) > Blast.reach(kg) + 2.0:
		return
	var t := Prof.start()
	# (Not a SpawnQueue job: thrown a few ticks late, behind a stick's shards, props flew into a
	# changed building and three sticks brought down 450 members, not main's 240: #538.)
	_blast_push(at, kg)
	Prof.stop(&"kit_blast", t)


func _blast_push(at: Vector3, kg: float) -> void:
	if loose or not is_inside_tree():
		return
	var left: Array[StructureMember] = []
	for m in get_members():
		if not m.broken:
			left.append(m)
	if left.is_empty():
		return
	# The most it could be pushed (every face as near and square as its nearest point, nothing in
	# between) short of moving it: it doesn't, and its faces needn't be walked (#538: a prop's
	# faces and rays were ~0.2 ms a member, for the dozens a stick reaches and doesn't move).
	var kgs := mass()
	var most := 0.0
	for m in left:
		most += Blast.most_face_impulse(m, at, kg)
	if most / maxf(kgs, 0.1) < LOOSE_FROM:
		return
	var pushes := {}  # member -> its push (N·s)
	var total := Vector3.ZERO
	for m in left:
		var j := Blast.face_impulse(m, at, kg)
		if j <= 0.0:
			continue
		var push := (m.global_position - at).normalized() * j * Blast.shielding(self, at, m.global_position, [m.get_rid()])
		if hung():
			push = _off_the_wall(push)
		pushes[m] = push
		total += push
	if total.length() / maxf(kgs, 0.1) < LOOSE_FROM:
		return
	# No faster than Blast throws anything.
	var scale := minf(1.0, Blast.t().max_throw * kgs / total.length())
	var at_m := {}
	for m: StructureMember in pushes:
		at_m[m.member_id] = m.global_position
	var bodies := go_loose()
	SpawnQueue.spent(self, bodies.size())  # (the shards and pieces waiting make way, #538)
	# What actually moves: what it held may have run out as it went (a full barrel blown open).
	if contents and contents.released:
		scale = minf(1.0, Blast.t().max_throw * maxf(_mass_of(bodies), 0.1) / total.length())
	set_meta(&"blast_push", total * scale)
	# Pushed once the new body is in the physics world (given in the frame it's made, half of it
	# was lost).
	await get_tree().physics_frame
	for rb in bodies:
		if not is_instance_valid(rb):
			continue
		for id: StringName in rb.get_meta(&"members", []):
			var m := get_member(id)
			if pushes.has(m):
				rb.apply_impulse(pushes[m] * scale, at_m[id] - rb.global_position)


## What of a push can take a hung prop off its nails: out from the wall and up (the wall takes
## what drives it in, the nails what drives it down).
func _off_the_wall(push: Vector3) -> Vector3:
	var local := global_basis.inverse() * push
	local.z = maxf(local.z, 0.0)
	local.y = maxf(local.y, 0.0)
	return global_basis * local


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
	mark_dirty(_seat_member.member_id)
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
		mark_dirty(_seat_member.member_id)


## The chair's gone from under him: he goes down with it (limp, as any man who loses his footing;
## conscious, his muscles still hold him a moment).
func _unseat() -> void:
	var man := seated
	_clear_seat()
	if man and is_instance_valid(man) and not man.get(&"limp") and man.has_method(&"go_limp"):
		man.call(&"go_limp")
		# Awake, he throws out his arms as he goes (HumanBody.brace; gameplay's).
		if man.has_method(&"brace"):
			man.call(&"brace")

