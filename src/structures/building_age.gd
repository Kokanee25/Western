class_name BuildingAge
extends RefCounted
## Years of weather and use on a building made of members (Sean, 2026-10-23: the street looked "too
## perfect"; docs/briefs/lived-in.md). `Structure.age_years` is the dial (the bank a few years, the
## livery sixty), config/building_age.tres the amounts at full wear (BuildingAgeTuning). Seeded by
## the structure (its id and build seed), so every load builds the same old building: there's
## nothing to save, and the player's damage is saved on top of it as before.
##
## Two passes, both in Structure.rebuild:
## - `alter` (after the build, before the support graph): what really changed in the timber. Boards
##   gone, or broken short at the foot where the rain splashes; a stretch of wall patched in newer
##   boards; shutters hung ajar; a plank replaced; a cracked step, in two. The graph is worked out
##   from these as from any member, so what's broken is broken.
## - `settle_in` (after the graph): how it has settled. Porch roofs sag between their posts and the
##   porch racks along the street; a post hangs kicked out at the foot; the ridge sways; the false
##   front leans out over the street; boards pull off their nails; a lap board droops; the framed
##   sign hangs off level; treads wear hollow and planks rock. A member is moved whole (its body and
##   collision too: a ball meets it where it's drawn) onto the chord between where the ageing puts
##   its ends, and drawn bent where the ageing bends it (a sagging beam: MemberMesh.warped). The
##   graph was worked out first, so a sag is a look, not a fault: nothing is weaker for it.
## Interiors are left as built (the brief's lived-in marks are theirs).

## Off with `-- --young-town` (the before shots: every building as new).
static var enabled := not OS.get_cmdline_user_args().has("--young-town")
## A bent member is drawn in pieces this long along its length.
const BEND_STEP := 0.6
## Bends smaller than this (m) aren't worth a mesh of their own (a few millimetres is under a
## pixel from the street, and every bent member costs its batch vertices).
const BEND_MIN := 0.008
## A porch's members bend from less: the eave, its beam and its boards sag together, no seam.
const PORCH_BEND_MIN := 0.002

static var _tuning: BuildingAgeTuning


static func tuning() -> BuildingAgeTuning:
	if _tuning == null:
		_tuning = load("res://config/building_age.tres")
	return _tuning


## How worn it is: 0 as built, 1 at `full_years` and past (`wear_curve`: the first years show most).
static func wear(s: Structure) -> float:
	if not enabled or s.age_years <= 0.0:
		return 0.0
	return pow(clampf(s.age_years / tuning().full_years, 0.0, 1.0), tuning().wear_curve)


static func alter(s: Structure) -> void:
	var w := wear(s)
	if w <= 0.0:
		return
	if s is FalseFrontBuilding:
		_alter_building(s, w, _rng(s, "alter"))
	elif s is Boardwalk:
		_alter_walk(s, w, _rng(s, "alter"))


static func settle_in(s: Structure) -> void:
	var w := wear(s)
	if w <= 0.0:
		return
	if s is FalseFrontBuilding:
		_settle_building(s, w, _rng(s, "settle"))
	elif s is Boardwalk:
		_settle_walk(s, w, _rng(s, "settle"))


static func _rng(s: Structure, pass_name: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d:%s" % [s.structure_id, s.build_seed, pass_name])
	return rng


## A member's id inside its structure ("left/siding/c03_0").
static func path_of(s: Structure, m: StructureMember) -> String:
	return String(m.member_id).substr(String(s.structure_id).length() + 1)


# --- The building: what changed ---------------------------------------------------------------

## The walls' rough boards: [origin, along, out] in the building's space (FalseFrontBuilding._wall).
static func _side_walls(b: FalseFrontBuilding) -> Dictionary:
	return {
		"left": [Vector3.ZERO, Vector3.BACK, Vector3.LEFT],
		"right": [Vector3(b.width, 0, 0), Vector3.BACK, Vector3.RIGHT],
		"back": [Vector3(0, 0, b.depth), Vector3.RIGHT, Vector3.BACK],
	}


## "left" for "left/siding/c03_0", "" for anything not a side wall's rough board.
static func _side_wall_of(path: String) -> String:
	for wall in ["left", "right", "back"]:
		if path.begins_with(wall + "/siding/c"):
			return wall
	return ""


static func _alter_building(b: FalseFrontBuilding, w: float, rng: RandomNumberGenerator) -> void:
	var t := tuning()
	var by_wall := {"left": [], "right": [], "back": []}
	var porch_boards: Array[StructureMember] = []
	for m in b.get_members():
		var p := path_of(b, m)
		var wall := _side_wall_of(p)
		if not wall.is_empty() and m.kind == &"board":
			(by_wall[wall] as Array).append(m)
		elif m.kind == &"roof_board" and p.begins_with("porch/board/"):
			porch_boards.append(m)
	# Stretches of wall patched in newer boards, side by side (whole boards, as a carpenter would
	# put them in): each wall its own chance.
	var patched := {}
	for wall: String in ["left", "right", "back"]:
		if rng.randf() >= t.patch_chance * w:
			continue
		var columns := {}
		for m: StructureMember in by_wall[wall]:
			columns[_column(path_of(b, m))] = true
		var keys := columns.keys()
		keys.sort()
		var n := mini(rng.randi_range(t.patch_boards.x, t.patch_boards.y), keys.size())
		if n > 0:
			var first := rng.randi_range(0, keys.size() - n)
			var chosen := keys.slice(first, first + n)
			for m: StructureMember in by_wall[wall]:
				if _column(path_of(b, m)) in chosen:
					newer(m, t.patch_wood)
					patched[m] = true
	# Boards gone, or broken off short at the foot: never one a window's trim is nailed to, and a
	# short one only where it's still nailed to something under it.
	var held: Array[AABB] = []
	var below: Array[StructureMember] = []
	for m in b.get_members():
		if m.kind in [&"trim", &"glass", &"door"]:
			held.append(m.structure_aabb().grow(0.03))
		elif StructureMember.tier_of(m.kind) < StructureMember.tier_of(&"board"):
			below.append(m)
	var gone: Array[StructureMember] = []
	for wall: String in by_wall:
		for m: StructureMember in by_wall[wall]:
			if patched.has(m):
				continue
			var r := rng.randf()
			if r >= (t.board_missing_chance + t.board_broken_chance) * w:
				continue
			var box := m.structure_aabb()
			if held.any(func(h: AABB) -> bool: return h.intersects(box)):
				continue
			if r < t.board_missing_chance * w:
				gone.append(m)
			else:
				_break_short(b, m, rng, below)
	# Porch roof boards gone: never the edges, never two side by side.
	var last := -2
	for i in range(1, porch_boards.size() - 1):
		if i - last > 1 and rng.randf() < t.porch_board_missing_chance * w:
			gone.append(porch_boards[i])
			last = i
	for m in gone:
		b.remove_built(m)
	if b.age_years >= t.shutter_years:
		_shutters(b, w, rng)


static func _column(path: String) -> int:
	return path.get_slice("/", 2).substr(1).get_slice("_", 0).to_int()


## Rotted off at the foot: the bottom of a rough board gone, up to well short of the window sills.
static func _break_short(b: Structure, m: StructureMember, rng: RandomNumberGenerator, below: Array[StructureMember]) -> void:
	var cut := minf(rng.randf_range(0.15, 0.6), m.size.y - 0.5)
	if cut < 0.1:
		return
	var short := AABB(m.structure_aabb().position + Vector3.UP * cut, m.size - Vector3.UP * cut)
	var grown := short.grow(Structure.CONTACT_EPSILON)
	if not below.any(func(o: StructureMember) -> bool: return grown.intersects(o.structure_aabb())):
		return  # it hung on the sill alone: it would have fallen, not rotted
	m.size.y -= cut
	m.position.y += cut * 0.5
	_reshape_box(b, m)


static func _reshape_box(s: Structure, m: StructureMember) -> void:
	var piece: Array = m.pieces[0]
	(piece[0] as MeshInstance3D).mesh = s._box_mesh(m.size)
	(piece[1] as CollisionShape3D).shape = s._box_shape(m.size)


## Drawn as newer wood than its neighbours (put in years after them), the same timber.
static func newer(m: StructureMember, wood: StringName) -> void:
	m.wood = wood
	m.set_meta(&"newer", true)
	(m.pieces[0][0] as MeshInstance3D).material_override = WoodMaterials.newer(wood, hash(m.member_id))


## Shutters on the side and back windows, each leaf hung from the wall beside the window's trim
## (it rests on the siding there) and standing open as far as the wind and the last hand left it;
## now and then a leaf long gone.
static func _shutters(b: FalseFrontBuilding, w: float, rng: RandomNumberGenerator) -> void:
	var t := tuning()
	var walls := _side_walls(b)
	var wood: StringName = b.front_wood if String(b.front_wood).begins_with("painted") else &"dark_trim"
	var trim := FalseFrontBuilding.TRIM_W
	var thick := 0.025
	for m: StructureMember in b.get_members().duplicate():
		var p := path_of(b, m)
		if m.kind != &"glass" or not walls.has(p.get_slice("/", 0)) or rng.randf() >= t.shutter_chance:
			continue
		var wall: Array = walls[p.get_slice("/", 0)]
		var origin: Vector3 = wall[0]
		var along: Vector3 = wall[1]
		var out: Vector3 = wall[2]
		var half := absf(m.size.dot(along)) * 0.5
		var mid := (m.position - origin).dot(along)
		var leaf := Vector3(half + trim, m.size.y + trim * 1.5, thick)
		var wide := rng.randf() < 0.5
		for side: float in [-1.0, 1.0]:
			if rng.randf() < 0.25 * w:
				continue  # this one's gone
			var open := rng.randf_range(t.shutter_open_degrees.x, t.shutter_open_degrees.y)
			if wide and side > 0.0:
				open = rng.randf_range(150.0, 172.0)
			var phi := deg_to_rad(open)
			var hinge := origin + along * (mid + side * (half + trim + 0.01)) \
					+ out * (FalseFrontBuilding.BOARD_T + thick * 0.5 + 0.002)
			hinge.y = m.position.y
			var dir := (along * -side) * cos(phi) + out * sin(phi)
			var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
			b.add_member("%s/shutter%d" % [p, 0 if side < 0.0 else 1], &"trim", wood, leaf,
					hinge + dir * (leaf.x * 0.5), basis)


# --- The building: how it settled ---------------------------------------------------------------

static func _settle_building(b: FalseFrontBuilding, w: float, rng: RandomNumberGenerator) -> void:
	var t := tuning()
	var members := b.get_members()
	# The porch: its posts in order along the front, a sag for each span between them.
	var posts: Array[StructureMember] = []
	for m in members:
		if m.kind == &"post" and "porch/post" in path_of(b, m):
			posts.append(m)
	posts.sort_custom(func(a: StructureMember, c: StructureMember) -> bool: return a.position.x < c.position.x)
	var xs := PackedFloat32Array()
	var sags := PackedFloat32Array()
	for m in posts:
		xs.append(m.position.x)
		sags.append(t.porch_sag * w * rng.randf_range(0.45, 1.0))
	var rack := tan(deg_to_rad(t.porch_rack_degrees) * w * rng.randf_range(0.4, 1.0)) * (1.0 if rng.randf() < 0.5 else -1.0)
	var zb := -b.porch_depth
	var roof_from := b.porch_height - 0.05
	var porch := func(p: Vector3) -> Vector3:
		var reach := clampf(p.z / zb, 0.0, 1.3)  # 0 at the wall, 1 at the beam, more out at the eave
		var off := Vector3(rack * maxf(p.y, 0.0) * minf(reach, 1.0), 0.0, 0.0)
		if p.y > roof_from:
			off.y = -_span_sag(p.x, xs, sags) * reach
		return off
	# The roof's swayback: most at the ridge in the middle, none at the gable ends or the eaves.
	var pitch := deg_to_rad(b.roof_pitch_degrees)
	var ridge_y := b.wall_height + b.width * 0.5 * tan(pitch)
	var sway := t.ridge_sag * w * rng.randf_range(0.6, 1.0)
	var roof := func(p: Vector3) -> Vector3:
		var up := clampf((p.y - b.wall_height) / maxf(ridge_y - b.wall_height, 0.1), 0.0, 1.0)
		return Vector3(0.0, -sway * sin(PI * clampf(p.z / b.depth, 0.0, 1.0)) * up, 0.0)
	var fronts: Array[StructureMember] = []
	for m in members:
		var p := path_of(b, m)
		if p.begins_with("porch/") or p.begins_with("facade/porch/"):
			reshape(m, porch, PORCH_BEND_MIN)
		elif p.begins_with("roof/"):
			reshape(m, roof)
		elif (p.begins_with("front/") or p.begins_with("facade/")) and m.position.z < 0.5:
			fronts.append(m)
	if not b.gable_front:
		_lean_front(b, fronts, deg_to_rad(t.front_lean_degrees) * w * rng.randf_range(0.5, 1.0))
	# A post kicked out at the foot, hanging from the beam (not one a railing's nailed to).
	for m in posts:
		if rng.randf() >= t.post_lean_chance * w or _touches(m, "rail"):
			continue
		var top := m.transform * Vector3(0.0, m.size.y * 0.5, 0.0)
		var a := rng.randf() * TAU
		pivot(m, top, Vector3(cos(a), 0.0, sin(a)), deg_to_rad(t.post_lean_degrees) * w * rng.randf_range(0.4, 1.0))
	# Rough boards pulled off their nails at the top or the foot (not the newer ones).
	var walls := _side_walls(b)
	for m in members:
		var wall := _side_wall_of(path_of(b, m))
		if wall.is_empty() or m.kind != &"board" or m.has_meta(&"newer") or rng.randf() >= t.board_kick_chance * w:
			continue
		var along: Vector3 = walls[wall][1]
		var out: Vector3 = walls[wall][2]
		var half := m.size.y * 0.5
		var foot := rng.randf() < 0.4
		var fixed := m.position + Vector3.UP * (half if foot else -half)
		var kick := t.board_kick * w * rng.randf_range(0.4, 1.0)
		var angle := kick / maxf(m.size.y, 0.3)
		# Whichever way round takes the free end out from the wall.
		var free_end := m.position * 2.0 - fixed
		var turned := fixed + Basis(along, angle) * (free_end - fixed)
		pivot(m, fixed, along, angle if (turned - free_end).dot(out) > 0.0 else -angle)
	# A lap board on the front let go at one end: it hangs out over the one below (not one with
	# letters painted on it: they'd be under it).
	var painted := _painted(fronts).map(func(box: AABB) -> AABB: return box.grow(0.1))  # past the 7 cm a droop drops
	for m in members:
		var p := path_of(b, m)
		if not p.begins_with("front/siding/r") or rng.randf() >= t.lap_droop_chance * w:
			continue
		var box := m.structure_aabb()
		if painted.any(func(q: AABB) -> bool: return q.intersects(box)):
			continue
		var right := rng.randf() < 0.5
		var fixed := m.position + Vector3.RIGHT * (m.size.x * (-0.5 if right else 0.5))
		# Never more than a third of a board's height at its free end (it's still lapped).
		var angle := minf(deg_to_rad(t.lap_droop_degrees) * w * rng.randf_range(0.5, 1.0), 0.07 / m.size.x)
		pivot(m, fixed, Vector3.BACK, -angle if right else angle)
		m.position.z -= 0.004
	_tilt_signs(b, w, rng)


## The false front pulled forward over the street (its braces given), hinged at the roofline, or
## lower where letters are painted on its boards (a quad on the sign member: FacadeArt), so they
## go with the boards: what's wholly above the hinge turns about it, what crosses it bends.
static func _lean_front(b: FalseFrontBuilding, fronts: Array[StructureMember], lean: float) -> void:
	var hinge := b.wall_height
	for box in _painted(fronts):
		hinge = minf(hinge, box.position.y)
	# Down to the foot of the lap board it would cross: every row turns whole.
	for m in fronts:
		var box := m.structure_aabb()
		if m.kind == &"board" and box.position.y < hinge and box.end.y > hinge:
			hinge = box.position.y
	var slope := tan(lean)
	var field := func(p: Vector3) -> Vector3: return Vector3(0.0, 0.0, -slope * maxf(p.y - hinge, 0.0))
	for m in fronts:
		if m.structure_aabb().position.y >= hinge - 0.001:
			pivot(m, Vector3(0.0, hinge, 0.0), Vector3.RIGHT, -lean)
		else:
			reshape(m, field)


## Where things are painted or hung on the front's members (letters, a painted board: drawn
## children past the member's own mesh), with the member that carries them, in the building's space.
static func _painted(fronts: Array[StructureMember]) -> Array[AABB]:
	var out: Array[AABB] = []
	for m in fronts:
		for c in m.get_children():
			if c is MeshInstance3D and c != m.pieces[0][0]:
				var mi := c as MeshInstance3D
				out.append((m.transform * mi.transform * mi.get_aabb()).merge(m.structure_aabb()))
	return out


## How far the porch roof has dropped at `x`: each span between posts its own sag.
static func _span_sag(x: float, xs: PackedFloat32Array, sags: PackedFloat32Array) -> float:
	for i in xs.size() - 1:
		if x >= xs[i] and x <= xs[i + 1]:
			var span := xs[i + 1] - xs[i]
			# Level where each post holds it, easing into the span (sin squared): a load's sag,
			# not a hinge at the post.
			return sags[i] * pow(sin(PI * (x - xs[i]) / span), 2.0) if span > 0.5 else 0.0
	return 0.0


static func _touches(m: StructureMember, part: String) -> bool:
	for id in m.touching:
		if part in String(id):
			return true
	return false


## A hung sign off level: the framed one with its frame and crest (FacadeArt's), and the gable's
## board. Letters painted on the front's own boards stay with the boards.
static func _tilt_signs(b: FalseFrontBuilding, w: float, rng: RandomNumberGenerator) -> void:
	var angle := deg_to_rad(tuning().sign_tilt_degrees) * w * rng.randf_range(0.35, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0)
	var group: Array[StructureMember] = []
	for m in b.get_members():
		var p := path_of(b, m)
		if p.begins_with("facade/sign") or p.begins_with("facade/crest"):
			group.append(m)
	if group.is_empty():
		var plain := b.get_member(StringName("%s/front/sign" % b.structure_id))
		if plain and plain.get_node_or_null(^"SignBoard"):
			group.append(plain)
	var box := AABB()
	for i in group.size():
		box = group[i].structure_aabb() if i == 0 else box.merge(group[i].structure_aabb())
	for m in group:
		pivot(m, box.get_center(), Vector3.BACK, angle)
	var gable := b.get_node_or_null(^"GableSign") as Node3D
	if gable:
		gable.transform = Transform3D(Basis(Vector3.BACK, angle) * gable.transform.basis, gable.transform.origin)


# --- Walks and steps -----------------------------------------------------------------------------

static func _alter_walk(walk: Boardwalk, w: float, rng: RandomNumberGenerator) -> void:
	var t := tuning()
	var steps: Array[StructureMember] = []
	for m in walk.get_members():
		var p := path_of(walk, m)
		if p.begins_with("plank/") and rng.randf() < t.plank_new_chance * w:
			newer(m, m.wood)
		elif p.begins_with("step/") or p.begins_with("end_step/"):
			steps.append(m)
	# One step cracked across, in two.
	if steps.is_empty() or rng.randf() >= t.cracked_step_chance * w:
		return
	var m := steps[rng.randi() % steps.size()]
	var ai := m.axis_index()
	var along := m.transform.basis[ai].normalized()
	var length := m.size[ai]
	var at := rng.randf_range(0.3, 0.7) * length
	var gap := 0.008
	var path := path_of(walk, m)
	var ends := [Vector2(0.0, at - gap * 0.5), Vector2(at + gap * 0.5, length)]
	var was := m.transform
	var whole := m.size
	var kind := m.kind
	var wood := m.wood
	walk.remove_built(m)
	for i in 2:
		var span: Vector2 = ends[i]
		var size := whole
		size[ai] = span.y - span.x
		var c := was.origin + along * ((span.x + span.y) * 0.5 - length * 0.5)
		var piece := walk.add_member("%s/%s" % [path, "ab"[i]], kind, wood, size, c, was.basis)
		piece.set_meta(&"cracked", i)


static func _settle_walk(walk: Boardwalk, w: float, rng: RandomNumberGenerator) -> void:
	var t := tuning()
	for m in walk.get_members():
		var p := path_of(walk, m)
		if p.begins_with("plank/"):
			# Cupped and rocked: an edge up or down a few millimetres, the plank a little sunk.
			var edge := t.plank_warp * w * rng.randf_range(-1.0, 1.0)
			var roll := atan2(edge, m.size.x * 0.5)
			m.transform = Transform3D(Basis(Vector3.BACK, roll) * m.transform.basis,
					m.position + Vector3.UP * t.plank_warp * w * rng.randf_range(-1.0, 0.25))
		elif p.begins_with("step/") or p.begins_with("end_step/"):
			_wear_tread(m, t.step_wear * w * rng.randf_range(0.6, 1.0))
			if m.get_meta(&"cracked", -1) == 1:
				# The loose half sunk at its far end, hinged on the crack.
				var ai := m.axis_index()
				var along := m.transform.basis[ai].normalized()
				var crack := m.position - along * (m.size[ai] * 0.5) + Vector3.UP * (m.size.y * 0.5)
				var axis := along.cross(Vector3.UP).normalized()
				pivot(m, crack, axis, -atan2(0.025 * w, m.size[ai]))


## A tread worn hollow along its middle, most at the middle of the flight: the top face dished.
static func _wear_tread(m: StructureMember, depth: float) -> void:
	var inv := m.transform.affine_inverse()
	var ai := m.axis_index()
	var size := m.size
	var cracked := int(m.get_meta(&"cracked", -1))
	reshape(m, func(p: Vector3) -> Vector3:
		var local := inv * p
		var top := clampf((local.y + size.y * 0.5) / size.y, 0.0, 1.0)
		var t := local[ai] / size[ai] + 0.5
		if cracked >= 0:
			t = t * 0.5 + 0.5 * cracked  # the halves are one tread worn as one
		return Vector3(0.0, -depth * sin(PI * clampf(t, 0.0, 1.0)) * top * top * top, 0.0))


# --- Moving members ------------------------------------------------------------------------------

## Turn a member about `point` (the building's space) on `axis` by `angle`: body, collision, drawing.
static func pivot(m: StructureMember, point: Vector3, axis: Vector3, angle: float) -> void:
	var r := Basis(axis.normalized(), angle)
	m.transform = Transform3D(r * m.transform.basis, point + r * (m.transform.origin - point))


## Move a member by a field (`field(p)`: the offset of point p, the building's space). Moved whole
## onto the chord between where its two ends go (its body and collision), and drawn bent where
## the field bends it more than `min_bend`.
static func reshape(m: StructureMember, field: Callable, min_bend := BEND_MIN) -> void:
	var was := m.transform
	var ai := m.axis_index()
	var half := was.basis[ai].normalized() * (m.size[ai] * 0.5)
	var p0 := was.origin - half
	var p1 := was.origin + half
	var q0: Vector3 = p0 + field.call(p0)
	var q1: Vector3 = p1 + field.call(p1)
	var turn := Basis(Quaternion((p1 - p0).normalized(), (q1 - q0).normalized()))
	var moved := Transform3D(turn * was.basis, (q0 + q1) * 0.5)
	var inv := moved.affine_inverse()
	var warp := func(v: Vector3) -> Vector3:
		var p := was * v
		return inv * (p + field.call(p))
	# How bent: the box's four long edges, sampled along it.
	var segments := clampi(ceili(m.size[ai] / BEND_STEP), 1, 32)
	var bend := 0.0
	for corner in 4:
		for i in segments + 1:
			var v := m.size * 0.5
			v[ai] = m.size[ai] * (float(i) / segments - 0.5)
			var others := [(ai + 1) % 3, (ai + 2) % 3]
			if corner & 1:
				v[others[0]] = -v[others[0]]
			if corner & 2:
				v[others[1]] = -v[others[1]]
			bend = maxf(bend, (warp.call(v) - v).length())
	m.transform = moved
	if bend > min_bend:
		var mi := m.pieces[0][0] as MeshInstance3D
		mi.mesh = MemberMesh.warped(m.size, segments, warp)
		m.set_meta(&"bent", bend)
